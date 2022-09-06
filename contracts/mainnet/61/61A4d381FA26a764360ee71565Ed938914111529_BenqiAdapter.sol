// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";
import "../../interfaces/benqi/IQiToken.sol";
import "../../interfaces/benqi/IQiAVAX.sol";
import "../../interfaces/benqi/IComptroller.sol";
import "../../interfaces/traderJoe/IJoeLens/IPriceOracle.sol";
import "../../interfaces/benqi/IMaximillion.sol";
import "../../interfaces/IWAVAX.sol";

interface IBenqiAdapter {
    function trustQiTokenAddr(address tokenAddr)
        external
        view
        returns (address);
}

contract BenqiAdapter is AdapterBase {
    using SafeERC20 for IERC20;

    address public constant unitrollerAddr =
        0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4;
    address public constant qiAvaxAddr =
        0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c;
    address public constant qiMaximillionAddr =
        0xd78DEd803b28A5A9C860c2cc7A4d84F611aA4Ef8;

    mapping(address => address) public trustQiTokenAddr;
    event BenqiInitialize(address[] tokenAddr, address[] qiTokenAddr);
    event BenqiBorrow(address qiToken, uint256 amount, address account);
    event BenqiRepay(address qiToken, uint256 amount, address account);
    event BenqiDeposit(address token, uint256 amount, address account);
    event BenqiWithdraw(address token, uint256 amount, address account);

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "Benqi")
    {}

    function initialize(
        address[] calldata tokenAddrs,
        address[] calldata qiTokenAddrs
    ) external onlyTimelock {
        require(
            tokenAddrs.length > 0 && tokenAddrs.length == qiTokenAddrs.length,
            "Set length mismatch."
        );
        for (uint256 i = 0; i < tokenAddrs.length; i++) {
            if (tokenAddrs[i] == avaxAddr || tokenAddrs[i] == wavaxAddr) {
                require(qiTokenAddrs[i] == qiAvaxAddr, "Token invalid.");
            } else {
                require(
                    IQiToken(qiTokenAddrs[i]).underlying() == tokenAddrs[i],
                    "Address mismatch."
                );
            }
            (bool isMarketListed, , ) = IComptroller(unitrollerAddr).markets(
                qiTokenAddrs[i]
            );
            require(isMarketListed, "!Invalid qitoken");
            trustQiTokenAddr[tokenAddrs[i]] = qiTokenAddrs[i];
        }

        emit BenqiInitialize(tokenAddrs, qiTokenAddrs);
    }

    function deposit(address tokenAddr, uint256 tokenAmount)
        external
        onlyDelegation
    {
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
            require(IQiToken(qiTokenAddr).mint(tokenAmount) == 0, "!mint");
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
        address qiTokenAddr = trustQiTokenAddr[tokenAddr];
        require(qiTokenAddr != address(0), "Token invalid.");
        pullAndApprove(qiTokenAddr, account, qiTokenAddr, qiTokenAmount);
        uint256 amountDiff;
        if (tokenAddr == avaxAddr) {
            uint256 amountBefore = address(this).balance;
            require(IQiAVAX(qiTokenAddr).redeem(qiTokenAmount) == 0, "!redeem");
            amountDiff = address(this).balance - amountBefore;
            require(amountDiff > 0, "amount error");
            safeTransferAVAX(account, amountDiff);
        } else {
            IERC20 token = IERC20(tokenAddr);
            if (tokenAddr == wavaxAddr) {
                uint256 amountBefore = address(this).balance;
                require(
                    IQiToken(qiTokenAddr).redeem(qiTokenAmount) == 0,
                    "!redeem"
                );
                amountDiff = address(this).balance - amountBefore;
                IWAVAX(wavaxAddr).deposit{value: amountDiff}();
            } else {
                uint256 amountBefore = token.balanceOf(address(this));
                require(
                    IQiToken(qiTokenAddr).redeem(qiTokenAmount) == 0,
                    "!redeem"
                );
                amountDiff = token.balanceOf(address(this)) - amountBefore;
            }

            require(amountDiff > 0, "amount error");
            token.safeTransfer(account, amountDiff);
        }

        emit BenqiWithdraw(tokenAddr, qiTokenAmount, account);
    }

    function enterMarkets(address[] memory qiTokenAddr)
        external
        onlyDelegation
    {
        IComptroller(unitrollerAddr).enterMarkets(qiTokenAddr);
    }

    function exitMarket(address qiTokenAddr) external onlyDelegation {
        IComptroller(unitrollerAddr).exitMarket(qiTokenAddr);
    }

    function borrow(address tokenAddr, uint256 amount) external onlyDelegation {
        address qiTokenAddr = IBenqiAdapter(ADAPTER_ADDRESS).trustQiTokenAddr(
            tokenAddr
        );
        require(qiTokenAddr != address(0), "Token invalid.");
        if (tokenAddr == avaxAddr) {
            IQiAVAX(qiTokenAddr).borrow(amount);
        } else {
            if (tokenAddr == wavaxAddr) {
                require(IQiAVAX(qiTokenAddr).borrow(amount) == 0, "!borrow");
                IWAVAX(wavaxAddr).deposit{value: amount}();
            } else {
                IQiToken(qiTokenAddr).borrow(amount);
            }
        }

        emit BenqiBorrow(qiTokenAddr, amount, address(this));
    }

    function repay(address tokenAddr, uint256 amount) external onlyDelegation {
        address qiTokenAddr = IBenqiAdapter(ADAPTER_ADDRESS).trustQiTokenAddr(
            tokenAddr
        );
        require(qiTokenAddr != address(0), "Token invalid.");
        if (tokenAddr == avaxAddr) {
            if (amount == type(uint256).max) {
                uint256 repayValue = IQiAVAX(qiTokenAddr).borrowBalanceCurrent(
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
                uint256 repayValue = IQiAVAX(qiTokenAddr).borrowBalanceCurrent(
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

    function claimRewards(uint8 rewardType) external onlyDelegation {
        IComptroller(unitrollerAddr).claimReward(rewardType, address(this));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../timelock/TimelockCallable.sol";
import "../../common/Basic.sol";

abstract contract AdapterBase is Basic, Ownable, TimelockCallable {
    using SafeERC20 for IERC20;

    address public ADAPTER_MANAGER;
    address public immutable ADAPTER_ADDRESS;
    string public ADAPTER_NAME;
    mapping(address => mapping(address => bool)) private approved;

    fallback() external payable {}

    receive() external payable {}

    modifier onlyAdapterManager() {
        require(
            ADAPTER_MANAGER == msg.sender,
            "Caller is not the adapterManager."
        );
        _;
    }

    modifier onlyDelegation() {
        require(ADAPTER_ADDRESS != address(this), "Only for delegatecall.");
        _;
    }

    constructor(
        address _adapterManager,
        address _timelock,
        string memory _name
    ) TimelockCallable(_timelock) {
        ADAPTER_MANAGER = _adapterManager;
        ADAPTER_ADDRESS = address(this);
        ADAPTER_NAME = _name;
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        require(_token != address(0) && _token != avaxAddr);
        uint256 balance = IERC20(_token).balanceOf(_from);
        uint256 currentAmount = balance < _amount ? balance : _amount;
        IERC20(_token).safeTransferFrom(_from, address(this), currentAmount);
    }

    function approveToken(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        if (!approved[_token][_spender]) {
            IERC20 token = IERC20(_token);
            token.safeApprove(_spender, 0);
            token.safeApprove(_spender, type(uint256).max);
            approved[_token][_spender] = true;
        }
    }

    /// @dev get the token from sender, and approve to the user in one step
    function pullAndApprove(
        address _token,
        address _from,
        address _spender,
        uint256 _amount
    ) internal {
        pullTokensIfNeeded(_token, _from, _amount);
        approveToken(_token, _spender, _amount);
    }

    function returnAsset(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            if (_token == avaxAddr) {
                safeTransferAVAX(_to, _amount);
            } else {
                require(_token != address(0), "Token error!");
                IERC20(_token).safeTransfer(_to, _amount);
            }
        }
    }

    function toCallback(
        address _target,
        bytes4 _selector,
        bytes memory _callData
    ) internal {
        (bool success, bytes memory returnData) = _target.call(
            abi.encodePacked(_selector, _callData)
        );
        require(success, string(returnData));
    }

    //Handle when someone else accidentally transfers assets to this contract
    function sweep(address[] memory tokens, address receiver)
        external
        onlyTimelock
    {
        require(address(this) == ADAPTER_ADDRESS, "!Invalid call");
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint256 amount = IERC20(token).balanceOf(address(this));
            if (amount > 0) {
                IERC20(token).safeTransfer(receiver, amount);
            }
        }

        uint256 balance = address(this).balance;
        if (balance > 0) {
            safeTransferAVAX(receiver, balance);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

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

pragma solidity >=0.8.0 <0.9.0;

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

pragma solidity >=0.8.0 <0.9.0;

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

pragma solidity >=0.8.0 <0.9.0;

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

pragma solidity >=0.8.0 <0.9.0;

interface IMaximillion {
    function jAvax() external view returns (address);

    function repayBehalf(address borrower) external payable;

    function repayBehalfExplicit(address borrower, address jAvax_)
        external
        payable;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

abstract contract TimelockCallable {
    address public TIMELOCK_ADDRESS;

    event SetTimeLock(address newTimelock);

    constructor(address _timelock) {
        TIMELOCK_ADDRESS = _timelock;
    }

    modifier onlyTimelock() {
        require(TIMELOCK_ADDRESS == msg.sender, "Caller is not the timelock.");
        _;
    }

    function setTimelock(address newTimelock) external onlyTimelock {
        require(newTimelock != address(0));
        TIMELOCK_ADDRESS = newTimelock;
        emit SetTimeLock(newTimelock);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

abstract contract Basic {
    /**
     * @dev Return ethereum address
     */
    address public constant avaxAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Return Wrapped AVAX address
    address public constant wavaxAddr =
        0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    function safeTransferAVAX(address to, uint256 value) internal {
        if (value != 0) {
            (bool success, ) = to.call{value: value}(new bytes(0));
            require(success, "helper::safeTransferAVAX: AVAX transfer failed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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