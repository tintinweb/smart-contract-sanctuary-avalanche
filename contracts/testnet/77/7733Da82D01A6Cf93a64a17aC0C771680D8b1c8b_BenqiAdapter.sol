// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../common/Basic.sol";
import "../base/AdapterBase.sol";
import {IQiToken} from "../../interfaces/benqi/IQiToken.sol";
import {IQiAVAX} from "../../interfaces/benqi/IQiAVAX.sol";
import {IComptroller} from "../../interfaces/benqi/IComptroller.sol";
import {IPriceOracle} from "../../interfaces/traderJoe/IJoeLens/IPriceOracle.sol";
import {IMaximillion} from "../../interfaces/benqi/IMaximillion.sol";
import {IWAVAX} from "../../interfaces/IWAVAX.sol";

interface IBenqiAdapter {
    function trustQiTokenAddr(address tokenAddr)
        external
        view
        returns (address);
}

contract BenqiAdapter is AdapterBase, Basic, Ownable {
    using SafeERC20 for IERC20;

    address public constant unitrollerAddr =
        0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4;
    address public constant qiAvaxAddr =
        0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c;
    address public constant qiMaximillionAddr =
        0xd78DEd803b28A5A9C860c2cc7A4d84F611aA4Ef8;

    mapping(address => address) public trustQiTokenAddr;

    event BenqiBorrow(address qiToken, uint256 amount, address account);
    event BenqiRepay(address qiToken, uint256 amount, address account);
    event BenqiDeposit(address token, uint256 amount, address account);
    event BenqiWithDraw(address token, uint256 amount, address account);

    constructor(address _adapterManager)
        AdapterBase(_adapterManager, "Benqi")
    {}

    struct QITokenSnapshot {
        uint256 balance;
        uint256 borrow;
        uint256 rate;
        uint256 price;
    }

    function initialize(
        address[] calldata tokenAddr,
        address[] calldata qiTokenAddr
    ) external onlyOwner {
        require(
            tokenAddr.length > 0 && tokenAddr.length == qiTokenAddr.length,
            "Set length mismatch."
        );
        for (uint256 i = 0; i < tokenAddr.length; i++) {
            if (tokenAddr[i] == avaxAddr || tokenAddr[i] == wavaxAddr) {
                require(qiTokenAddr[i] == qiAvaxAddr, "Token invalid.");
            } else {
                require(
                    IQiToken(qiTokenAddr[i]).underlying() == tokenAddr[i],
                    "Address mismatch."
                );
            }
            trustQiTokenAddr[tokenAddr[i]] = qiTokenAddr[i];
        }
    }

    function deposit(bytes calldata encodedData) external onlyProxy {
        (address tokenAddr, uint256 tokenAmount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        address qiTokenAddr = IBenqiAdapter(ADAPTER_ADDRESS).trustQiTokenAddr(
            tokenAddr
        );
        require(qiTokenAddr != address(0), "Token invalid.");
        if (tokenAddr == avaxAddr) {
            IQiAVAX(qiTokenAddr).mint{value: tokenAmount}();
        } else if (tokenAddr == wavaxAddr) {
            IWAVAX(wavaxAddr).withdraw(tokenAmount);
            IQiAVAX(qiTokenAddr).mint{value: tokenAmount}();
        } else {
            IQiToken(qiTokenAddr).mint(tokenAmount);
        }
        emit BenqiDeposit(tokenAddr, tokenAmount, address(this));
    }

    function withdraw(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (address tokenAddr, uint256 qiTokenAmount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        address qiTokenAddr = IBenqiAdapter(ADAPTER_ADDRESS).trustQiTokenAddr(
            tokenAddr
        );
        require(qiTokenAddr != address(0), "Token invalid.");
        pullAndApprove(qiTokenAddr, account, qiTokenAddr, qiTokenAmount);
        uint256 amountDiff;
        if (tokenAddr == avaxAddr) {
            uint256 amountBefore = address(this).balance;
            IQiAVAX(qiTokenAddr).redeem(qiTokenAmount);
            amountDiff = address(this).balance - amountBefore;
            require(amountDiff > 0, "amount error");
            safeTransferAVAX(account, amountDiff);
        } else {
            IERC20 token = IERC20(tokenAddr);
            if (tokenAddr == wavaxAddr) {
                uint256 amountBefore = address(this).balance;
                IQiToken(qiTokenAddr).redeem(qiTokenAmount);
                amountDiff = address(this).balance - amountBefore;
                IWAVAX(wavaxAddr).deposit{value: amountDiff}();
            } else {
                uint256 amountBefore = token.balanceOf(address(this));
                IQiToken(qiTokenAddr).redeem(qiTokenAmount);
                amountDiff = token.balanceOf(address(this)) - amountBefore;
            }

            require(amountDiff > 0, "amount error");
            token.safeTransfer(account, amountDiff);
        }

        emit BenqiWithDraw(tokenAddr, qiTokenAmount, account);
    }

    function enterMarkets(bytes calldata encodedData) external onlyProxy {
        address[] memory qiTokenAddr = abi.decode(encodedData, (address[]));
        uint256[] memory result = IComptroller(unitrollerAddr).enterMarkets(
            qiTokenAddr
        );
    }

    function exitMarket(bytes calldata encodedData) external onlyProxy {
        address qiTokenAddr = abi.decode(encodedData, (address));
        uint256 result = IComptroller(unitrollerAddr).exitMarket(qiTokenAddr);
    }

    function borrow(bytes calldata encodedData) external onlyProxy {
        (address tokenAddr, uint256 amount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        address qiTokenAddr = IBenqiAdapter(ADAPTER_ADDRESS).trustQiTokenAddr(
            tokenAddr
        );
        require(qiTokenAddr != address(0), "Token invalid.");
        if (tokenAddr == avaxAddr) {
            IQiAVAX(qiTokenAddr).borrow(amount);
        } else {
            if (tokenAddr == wavaxAddr) {
                uint256 result = IQiAVAX(qiTokenAddr).borrow(amount);
                IWAVAX(wavaxAddr).deposit{value: amount}();
            } else {
                uint256 result = IQiToken(qiTokenAddr).borrow(amount);
            }
        }

        emit BenqiBorrow(qiTokenAddr, amount, address(this));
    }

    function repay(bytes calldata encodedData) external onlyProxy {
        (address tokenAddr, uint256 amount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        address qiTokenAddr = IBenqiAdapter(ADAPTER_ADDRESS).trustQiTokenAddr(
            tokenAddr
        );
        require(qiTokenAddr != address(0), "Token invalid.");
        if (tokenAddr == avaxAddr) {
            if (amount == type(uint256).max) {
                uint256 repayValue = IQiAVAX(qiTokenAddr).borrowBalanceStored(
                    address(this)
                );
                IMaximillion(qiMaximillionAddr).repayBehalf{value: repayValue}(
                    address(this)
                );
            } else {
                IQiAVAX(qiTokenAddr).repayBorrow{value: amount}();
            }
        } else if (tokenAddr == wavaxAddr) {
            if (amount == type(uint256).max) {
                uint256 repayValue = IQiAVAX(qiTokenAddr).borrowBalanceStored(
                    address(this)
                );
                IWAVAX(wavaxAddr).withdraw(repayValue);
                IMaximillion(qiMaximillionAddr).repayBehalf{value: repayValue}(
                    address(this)
                );
            } else {
                IWAVAX(wavaxAddr).withdraw(amount);
                IQiAVAX(qiTokenAddr).repayBorrow{value: amount}();
            }
        } else {
            IQiToken(qiTokenAddr).repayBorrow(amount);
        }
        emit BenqiRepay(qiTokenAddr, amount, address(this));
    }

    function claimRewards(bytes calldata encodedData) external onlyProxy {
        uint8 rewardType = abi.decode(encodedData, (uint8));
        IComptroller(unitrollerAddr).claimReward(rewardType, address(this));
    }

    /// @dev Get account info for Benqi.
    function GetUserAccountData(address account)
        public
        view
        returns (
            uint256, // Err, if error occurred, this will be non zero
            uint256, // Total collateral amount, the amount of currency in the loan market
            uint256 // Total borrow amount, how much you borrow in usd
        )
    {
        IComptroller benqi = IComptroller(unitrollerAddr);
        IPriceOracle oracle = IPriceOracle(benqi.oracle());
        uint256 sumBorrow;
        uint256 sumCollateral;
        address[] memory assets = benqi.getAssetsIn(account);
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 err;
            QITokenSnapshot memory s;
            IQiToken qiToken = IQiToken(assets[i]);
            (err, s.balance, s.borrow, s.rate) = qiToken.getAccountSnapshot(
                account
            );

            // If error occurred, return error.
            if (err != 0) {
                return (err, 0, 0);
            }

            if (s.balance == 0 && s.borrow == 0) {
                continue;
            }

            s.price = oracle.getUnderlyingPrice(address(qiToken));

            if (s.price == 0) {
                return (0, 0, 0);
            }

            sumBorrow += s.borrow * s.price;
            sumCollateral += s.balance * s.rate * s.price;
        }

        // Set precision to 10^18
        return (0, sumCollateral / (10**36), sumBorrow / (10**18));
    }

    /// @notice This function calculates how much the user can borrow without liquidation.
    /// @param account User to query.
    /// @return The calaculated value.
    function GetUserLiquidateValue(address account)
        public
        view
        returns (uint256)
    {
        IComptroller benqi = IComptroller(unitrollerAddr);
        IPriceOracle oracle = IPriceOracle(benqi.oracle());
        uint256 sumCollateral;
        address[] memory assets = benqi.getAssetsIn(account);
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 err;
            QITokenSnapshot memory s;
            IQiToken qiToken = IQiToken(assets[i]);
            (err, s.balance, s.borrow, s.rate) = qiToken.getAccountSnapshot(
                account
            );

            // If error occurred, return error.
            if (err != 0) {
                return 0;
            }

            if (s.balance == 0) {
                continue;
            }

            s.price = oracle.getUnderlyingPrice(address(qiToken));

            if (s.price == 0) {
                return 0;
            }

            uint256 factor;

            (, factor, ) = benqi.markets(assets[i]);

            sumCollateral +=
                (((s.balance * s.rate * s.price) / 1e18) * factor) /
                1e36;
        }
        return sumCollateral;
    }

    //bool[] isAsCollateral
    //bool[] isBorrowing
    //address[] reservesList
    function GetUserMarketInfo(address account)
        external
        view
        returns (
            bool[] memory,
            bool[] memory,
            address[] memory
        )
    {
        IComptroller benqi = IComptroller(unitrollerAddr);
        address[] memory qiTokenAddr = benqi.getAllMarkets();
        address[] memory reservesList = new address[](qiTokenAddr.length);
        bool[] memory isAsCollateral = new bool[](qiTokenAddr.length);
        bool[] memory isBorrowing = new bool[](qiTokenAddr.length);

        for (uint256 i = 0; i < qiTokenAddr.length; i++) {
            isAsCollateral[i] = benqi.checkMembership(account, qiTokenAddr[i]);
            IQiToken qiToken = IQiToken(qiTokenAddr[i]);
            reservesList[i] = qiTokenAddr[i] == qiAvaxAddr
                ? wavaxAddr
                : qiToken.underlying();
            isBorrowing[i] = qiToken.borrowBalanceStored(account) > 0
                ? true
                : false;
        }
        return (isAsCollateral, isBorrowing, reservesList);
    }

    function GetUserDepositPosition(address account)
        external
        view
        returns (uint256)
    {
        IComptroller benqi = IComptroller(unitrollerAddr);
        address[] memory reservesList = benqi.getAllMarkets();
        uint256 assetValue;
        IPriceOracle oracle = IPriceOracle(benqi.oracle());
        for (uint256 i = 0; i < reservesList.length; i++) {
            uint256 tokenBalance = IERC20(reservesList[i]).balanceOf(account);
            if (tokenBalance > 0) {
                uint256 price = oracle.getUnderlyingPrice(reservesList[i]);
                uint256 decimals = IQiToken(reservesList[i]).decimals();
                uint256 exchangeRateStored = IQiToken(reservesList[i])
                    .exchangeRateStored();
                assetValue += ((tokenBalance * price * exchangeRateStored) /
                    ((10**decimals) * 1e36));
            }
        }
        return (assetValue);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Basic {
    using SafeERC20 for IERC20;

    uint256 constant WAD = 10**18;
    /**
     * @dev Return ethereum address
     */
    address internal constant avaxAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Return Wrapped AVAX address
    address internal constant wavaxAddr =
        0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    /// @dev Return call deadline
    uint256 internal constant TIME_INTERVAL = 3600;

    function encodeEvent(string memory eventName, bytes memory eventParam)
        internal
        pure
        returns (bytes memory)
    {
        return abi.encode(eventName, eventParam);
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal returns (uint256) {
        // handle max uint amount
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, _from);
        }

        if (
            _from != address(0) &&
            _from != address(this) &&
            _token != avaxAddr &&
            _amount != 0
        ) {
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        }

        return _amount;
    }

    function getBalance(address _tokenAddr, address _acc)
        internal
        view
        returns (uint256)
    {
        if (_tokenAddr == avaxAddr) {
            return _acc.balance;
        } else {
            return IERC20(_tokenAddr).balanceOf(_acc);
        }
    }

    function getBalances(address[] memory tokens, address owner)
        internal
        view
        returns (uint256[] memory balances)
    {
        for (uint256 l = 0; l < tokens.length; l++) {
            balances[l] = getBalance(tokens[l], owner);
        }
    }

    function safeTransferAVAX(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "helper::safeTransferAVAX: AVAX transfer failed");
    }

    /// @dev get the token from sender, and approve to the user in one step
    function pullAndApprove(
        address tokenAddress,
        address sender,
        address spender,
        uint256 amount
    ) internal {
        if (tokenAddress == avaxAddr) return;
        IERC20 token = IERC20(tokenAddress);
        // if max amount, get all the sender's balance
        if (amount == type(uint256).max) {
            amount = token.balanceOf(sender);
        }
        // receive token from sender
        token.safeTransferFrom(sender, address(this), amount);
        // approve the token to the spender
        try token.approve(spender, amount) {} catch {
            token.safeApprove(spender, 0);
            token.safeApprove(spender, amount);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../../interfaces/IAdapterManager.sol";

abstract contract AdapterBase {
    address internal immutable ADAPTER_MANAGER;
    address internal immutable ADAPTER_ADDRESS;
    string internal ADAPTER_NAME;

    fallback() external payable {}

    receive() external payable {}

    modifier onlyAdapterManager() {
        require(
            msg.sender == ADAPTER_MANAGER,
            "Only the AdapterManager can call this function"
        );
        _;
    }

    modifier onlyProxy() {
        require(
            ADAPTER_ADDRESS != address(this),
            "Only proxy wallet can delegatecall this function"
        );
        _;
    }

    constructor(address _adapterManager, string memory _name) {
        ADAPTER_MANAGER = _adapterManager;
        ADAPTER_ADDRESS = address(this);
        ADAPTER_NAME = _name;
    }

    function getAdapterManager() external view returns (address) {
        return ADAPTER_MANAGER;
    }

    function identifier() external view returns (string memory) {
        return ADAPTER_NAME;
    }

    function toCallback(
        address _target,
        string memory _callFunc,
        bytes calldata _callData
    ) internal {
        (bool success, bytes memory returnData) = _target.call(
            abi.encodeWithSignature(
                "callback(string,bytes)",
                _callFunc,
                _callData
            )
        );
        require(success, string(returnData));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IQiToken {
    function _acceptAdmin() external returns (uint256);

    function _addReserves(uint256 addAmount) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setComptroller(address newComptroller) external returns (uint256);

    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes calldata becomeImplementationData
    ) external;

    function _setInterestRateModel(address newInterestRateModel)
        external
        returns (uint256);

    function _setPendingAdmin(address newPendingAdmin)
        external
        returns (uint256);

    function _setProtocolSeizeShare(uint256 newProtocolSeizeShareMantissa)
        external
        returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa)
        external
        returns (uint256);

    function accrualBlockTimestamp() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function admin() external view returns (address);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function borrowIndex() external view returns (uint256);

    function borrowRatePerTimestamp() external view returns (uint256);

    function comptroller() external view returns (address);

    function decimals() external view returns (uint8);

    function delegateToImplementation(bytes calldata data)
        external
        returns (bytes calldata);

    function delegateToViewImplementation(bytes calldata data)
        external
        view
        returns (bytes calldata);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getCash() external view returns (uint256);

    function implementation() external view returns (address);

    function interestRateModel() external view returns (address);

    function isQiToken() external view returns (bool);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address qiTokenCollateral
    ) external returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function name() external view returns (string memory);

    function pendingAdmin() external view returns (address);

    function protocolSeizeShareMantissa() external view returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function supplyRatePerTimestamp() external view returns (uint256);

    function sweepToken(address token) external;

    function symbol() external view returns (string memory);

    function totalBorrows() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function totalReserves() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function underlying() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IQiAVAX {
    function _acceptAdmin() external returns (uint256);

    function _addReserves() external payable returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setComptroller(address newComptroller) external returns (uint256);

    function _setInterestRateModel(address newInterestRateModel)
        external
        returns (uint256);

    function _setPendingAdmin(address newPendingAdmin)
        external
        returns (uint256);

    function _setProtocolSeizeShare(uint256 newProtocolSeizeShareMantissa)
        external
        returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa)
        external
        returns (uint256);

    function accrualBlockTimestamp() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function admin() external view returns (address);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function borrowIndex() external view returns (uint256);

    function borrowRatePerTimestamp() external view returns (uint256);

    function comptroller() external view returns (address);

    function decimals() external view returns (uint8);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getCash() external view returns (uint256);

    function initialize(
        address comptroller_,
        address interestRateModel_,
        uint256 initialExchangeRateMantissa_,
        string calldata name_,
        string calldata symbol_,
        uint8 decimals_
    ) external;

    function interestRateModel() external view returns (address);

    function isQiToken() external view returns (bool);

    function liquidateBorrow(address borrower, address qiTokenCollateral)
        external
        payable;

    function mint() external payable;

    function name() external view returns (string memory);

    function pendingAdmin() external view returns (address);

    function protocolSeizeShareMantissa() external view returns (uint256);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function repayBorrow() external payable;

    function repayBorrowBehalf(address borrower) external payable;

    function reserveFactorMantissa() external view returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function supplyRatePerTimestamp() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalBorrows() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function totalReserves() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IComptroller {
    function accountAssets(address, uint256) external view returns (address);

    function admin() external view returns (address);

    function allMarkets(uint256) external view returns (address);

    function borrowAllowed(
        address qiToken,
        address borrower,
        uint256 borrowAmount
    ) external returns (uint256);

    function borrowCapGuardian() external view returns (address);

    function borrowCaps(address) external view returns (uint256);

    function borrowVerify(
        address qiToken,
        address borrower,
        uint256 borrowAmount
    ) external;

    function checkMembership(address account, address qiToken)
        external
        view
        returns (bool);

    function claimReward(uint8 rewardType, address holder) external;

    function claimReward(
        uint8 rewardType,
        address holder,
        address[] calldata qiTokens
    ) external;

    function claimReward(
        uint8 rewardType,
        address[] calldata holders,
        address[] calldata qiTokens,
        bool borrowers,
        bool suppliers
    ) external payable;

    function closeFactorMantissa() external view returns (uint256);

    function comptrollerImplementation() external view returns (address);

    function enterMarkets(address[] calldata qiTokens)
        external
        returns (uint256[] calldata);

    function exitMarket(address qiTokenAddress) external returns (uint256);

    function getAccountLiquidity(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function getAllMarkets() external view returns (address[] calldata);

    function getAssetsIn(address account)
        external
        view
        returns (address[] calldata);

    function getBlockTimestamp() external view returns (uint256);

    function getHypotheticalAccountLiquidity(
        address account,
        address qiTokenModify,
        uint256 redeemTokens,
        uint256 borrowAmount
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        );

    function initialIndexConstant() external view returns (uint224);

    function isComptroller() external view returns (bool);

    function liquidateBorrowAllowed(
        address qiTokenBorrowed,
        address qiTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function liquidateBorrowVerify(
        address qiTokenBorrowed,
        address qiTokenCollateral,
        address liquidator,
        address borrower,
        uint256 actualRepayAmount,
        uint256 seizeTokens
    ) external;

    function liquidateCalculateSeizeTokens(
        address qiTokenBorrowed,
        address qiTokenCollateral,
        uint256 actualRepayAmount
    ) external view returns (uint256, uint256);

    function liquidationIncentiveMantissa() external view returns (uint256);

    function markets(address)
        external
        view
        returns (
            bool isListed,
            uint256 collateralFactorMantissa,
            bool isQied
        );

    function maxAssets() external view returns (uint256);

    function mintAllowed(
        address qiToken,
        address minter,
        uint256 mintAmount
    ) external returns (uint256);

    function mintGuardianPaused(address) external view returns (bool);

    function mintVerify(
        address qiToken,
        address minter,
        uint256 actualMintAmount,
        uint256 mintTokens
    ) external;

    function oracle() external view returns (address);

    function pauseGuardian() external view returns (address);

    function pendingAdmin() external view returns (address);

    function pendingComptrollerImplementation() external view returns (address);

    function qiAddress() external view returns (address);

    function redeemAllowed(
        address qiToken,
        address redeemer,
        uint256 redeemTokens
    ) external returns (uint256);

    function redeemVerify(
        address qiToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external;

    function repayBorrowAllowed(
        address qiToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external returns (uint256);

    function repayBorrowVerify(
        address qiToken,
        address payer,
        address borrower,
        uint256 actualRepayAmount,
        uint256 borrowerIndex
    ) external;

    function rewardAccrued(uint8, address) external view returns (uint256);

    function rewardAvax() external view returns (uint8);

    function rewardBorrowState(uint8, address)
        external
        view
        returns (uint224 index, uint32 timestamp);

    function rewardBorrowerIndex(
        uint8,
        address,
        address
    ) external view returns (uint256);

    function rewardQi() external view returns (uint8);

    function rewardSpeeds(uint8, address) external view returns (uint256);

    function rewardSupplierIndex(
        uint8,
        address,
        address
    ) external view returns (uint256);

    function rewardSupplyState(uint8, address)
        external
        view
        returns (uint224 index, uint32 timestamp);

    function seizeAllowed(
        address qiTokenCollateral,
        address qiTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function seizeGuardianPaused() external view returns (bool);

    function seizeVerify(
        address qiTokenCollateral,
        address qiTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external;

    function setQiAddress(address newQiAddress) external;

    function transferAllowed(
        address qiToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external returns (uint256);

    function transferGuardianPaused() external view returns (bool);

    function transferVerify(
        address qiToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IPriceOracle {
    function _setAdmin(address _admin) external;

    function _setAggregators(
        address[] memory jTokenAddresses,
        address[] memory sources
    ) external;

    function _setGuardian(address _guardian) external;

    function _setUnderlyingPrice(
        address jToken,
        uint256 underlyingPriceMantissa
    ) external;

    function admin() external view returns (address);

    function aggregators(address) external view returns (address);

    function getUnderlyingPrice(address jToken) external view returns (uint256);

    function guardian() external view returns (address);

    function setDirectPrice(address asset, uint256 price) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IMaximillion {
    function jAvax() external view returns (address);

    function repayBehalf(address borrower) external payable;

    function repayBehalfExplicit(address borrower, address jAvax_)
        external
        payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IWAVAX {
    function allowance(address, address) external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function deposit() external payable;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface IAdapterManager {
    enum SpendAssetsHandleType {
        None,
        Approve,
        Transfer,
        Remove
    }

    function receiveCallFromController(
        address adapter,
        bytes4 selector,
        bytes calldata callArgs
    ) external payable returns (bytes memory);

    function adapterIsRegistered(address) external view returns (bool);
}