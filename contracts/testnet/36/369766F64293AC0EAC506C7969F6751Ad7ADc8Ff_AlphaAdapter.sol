// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../common/Basic.sol";
import "../base/AdapterBase.sol";
import {ISafeBox} from "../../interfaces/alpha/ISafeBox.sol";
import {ISafeBoxAVAX} from "../../interfaces/alpha/ISafeBoxAVAX.sol";
import {IWAVAX} from "../../interfaces/IWAVAX.sol";
import {IHomoraBank} from "../../interfaces/alpha/IHomoraBank.sol";
import {IUnilikeSpell} from "../../interfaces/alpha/IUnilikeSpell.sol";

contract AlphaAdapter is AdapterBase, Basic, Ownable {
    using SafeERC20 for IERC20;

    address public constant homoraBankAddr =
        0x376d16C7dE138B01455a51dA79AD65806E9cd694;
    mapping(address => address) public trustIbTokenAddr;

    uint256 positionIdNext;

    struct Position {
        address owner; // The account of this position.
        uint256 homoraBankId; // The positionId in homoraBank contract.
    }

    mapping(uint256 => Position) public PositionInfo;
    mapping(address => uint256[]) public adapterPositionIds;

    event AlphaExecute(
        address account,
        uint256 adapterPositionId,
        uint256 homoraBankId
    );

    constructor(address _adapterManager) AdapterBase(_adapterManager, "Alpha") {
        positionIdNext = 10;
    }

    function initialize(
        address[] calldata tokenAddr,
        address[] calldata ibTokenAddr
    ) external onlyOwner {
        require(
            tokenAddr.length > 0 && tokenAddr.length == ibTokenAddr.length,
            "Set length mismatch."
        );
        for (uint256 i = 0; i < tokenAddr.length; i++) {
            if (tokenAddr[i] == avaxAddr || tokenAddr[i] == wavaxAddr) {
                require(
                    ISafeBoxAVAX(ibTokenAddr[i]).weth() == wavaxAddr,
                    "Address mismatch."
                );
            } else {
                require(
                    ISafeBox(ibTokenAddr[i]).uToken() == tokenAddr[i],
                    "Address mismatch."
                );
            }
            trustIbTokenAddr[tokenAddr[i]] = ibTokenAddr[i];
        }
    }

    function deposit(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        (address tokenAddr, uint256 amount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        require(trustIbTokenAddr[tokenAddr] != address(0), "Token invalid.");
        IERC20 ibToken = IERC20(trustIbTokenAddr[tokenAddr]);
        uint256 tokenBefore = ibToken.balanceOf(address(this));
        if (tokenAddr == avaxAddr) {
            require(
                ISafeBoxAVAX(trustIbTokenAddr[tokenAddr]).weth() == wavaxAddr,
                "Not AVAX."
            );
            ISafeBoxAVAX(trustIbTokenAddr[tokenAddr]).deposit{
                value: msg.value
            }();
        } else if (tokenAddr == wavaxAddr) {
            require(
                ISafeBoxAVAX(trustIbTokenAddr[tokenAddr]).weth() == wavaxAddr,
                "Not WAVAX."
            );
            pullAndApprove(
                tokenAddr,
                account,
                trustIbTokenAddr[tokenAddr],
                amount
            );
            IWAVAX(wavaxAddr).withdraw(amount);
            ISafeBoxAVAX(trustIbTokenAddr[tokenAddr]).deposit{value: amount}();
        } else {
            require(
                ISafeBox(trustIbTokenAddr[tokenAddr]).uToken() == tokenAddr,
                "Not token."
            );
            pullAndApprove(
                tokenAddr,
                account,
                trustIbTokenAddr[tokenAddr],
                amount
            );
            ISafeBox(trustIbTokenAddr[tokenAddr]).deposit(amount);
        }
        uint256 tokenDiff = ibToken.balanceOf(address(this)) - tokenBefore;
        ibToken.safeTransfer(account, tokenDiff);
    }

    function withdraw(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        (address tokenAddr, uint256 amount) = abi.decode(
            encodedData,
            (address, uint256)
        );
        require(trustIbTokenAddr[tokenAddr] != address(0), "Token invalid.");

        if (tokenAddr == avaxAddr || tokenAddr == wavaxAddr) {
            require(
                ISafeBoxAVAX(trustIbTokenAddr[tokenAddr]).weth() == wavaxAddr,
                "Not AVAX."
            );
            pullAndApprove(
                trustIbTokenAddr[tokenAddr],
                account,
                trustIbTokenAddr[tokenAddr],
                amount
            );
            uint256 amountBefore = address(this).balance;
            ISafeBoxAVAX(trustIbTokenAddr[tokenAddr]).withdraw(amount);
            uint256 amountDiff = address(this).balance - amountBefore;
            require(amountDiff > 0, "amount error");
            if (tokenAddr == avaxAddr) {
                safeTransferAVAX(account, amountDiff);
            } else {
                IWAVAX(wavaxAddr).deposit{value: amountDiff}();
                IWAVAX(wavaxAddr).transfer(account, amountDiff);
            }
        } else {
            require(
                ISafeBox(trustIbTokenAddr[tokenAddr]).uToken() == tokenAddr,
                "Not token."
            );
            pullAndApprove(
                trustIbTokenAddr[tokenAddr],
                account,
                trustIbTokenAddr[tokenAddr],
                amount
            );
            IERC20 token = IERC20(tokenAddr);
            uint256 tokenBefore = token.balanceOf(address(this));
            ISafeBox(trustIbTokenAddr[tokenAddr]).withdraw(amount);
            uint256 tokenDiff = token.balanceOf(address(this)) - tokenBefore;
            token.safeTransfer(account, tokenDiff);
        }
    }

    function executeCallHomoraBank(
        address account,
        HomoraBankData memory data,
        address[3] memory tokenAddresses,
        uint256[3] memory tokenAmountConsumption
    ) internal returns (uint256 returnId) {
        IERC20 tokenA = IERC20(tokenAddresses[0]);
        uint256 tokenABefore = tokenA.balanceOf(address(this)) -
            tokenAmountConsumption[0];

        IERC20 tokenB = IERC20(tokenAddresses[1]);
        uint256 tokenBBefore = tokenB.balanceOf(address(this)) -
            tokenAmountConsumption[1];

        IERC20 lpToken = IERC20(tokenAddresses[2]);
        uint256 lpTokenBefore = lpToken.balanceOf(address(this)) -
            tokenAmountConsumption[2];

        bytes memory spellBytes = abi.encodePacked(
            data.spellSelector,
            data.spellArgs
        );

        uint256 valueBefore = address(this).balance - msg.value;
        returnId = IHomoraBank(homoraBankAddr).execute{value: msg.value}(
            data.homoraBankId,
            data.spellAddr,
            spellBytes
        );
        safeTransferAVAX(account, address(this).balance - valueBefore);
        tokenA.safeTransfer(
            account,
            tokenA.balanceOf(address(this)) - tokenABefore
        );
        tokenB.safeTransfer(
            account,
            tokenB.balanceOf(address(this)) - tokenBBefore
        );
        lpToken.safeTransfer(
            account,
            lpToken.balanceOf(address(this)) - lpTokenBefore
        );
    }

    struct Amounts {
        uint256 amtAUser; // Supplied tokenA amount
        uint256 amtBUser; // Supplied tokenB amount
        uint256 amtLPUser; // Supplied LP token amount
        uint256 amtABorrow; // Borrow tokenA amount
        uint256 amtBBorrow; // Borrow tokenB amount
        uint256 amtLPBorrow; // Borrow LP token amount
        uint256 amtAMin; // Desired tokenA amount (slippage control)
        uint256 amtBMin; // Desired tokenB amount (slippage control)
    }

    function addLiquidityInternal(address account, HomoraBankData memory data)
        internal
        returns (uint256 returnId)
    {
        (address tokenA, address tokenB, Amounts memory amounts, ) = abi.decode(
            data.spellArgs,
            (address, address, Amounts, uint256)
        );

        pullAndApprove(tokenA, account, homoraBankAddr, amounts.amtAUser);
        pullAndApprove(tokenB, account, homoraBankAddr, amounts.amtBUser);
        address lpToken = IUnilikeSpell(data.spellAddr).getAndApprovePair(
            tokenA,
            tokenB
        );
        pullAndApprove(lpToken, account, homoraBankAddr, amounts.amtLPUser);

        address[3] memory tokenAddresses = [tokenA, tokenB, lpToken];

        uint256[3] memory tokenAmountConsumption = [
            amounts.amtAUser,
            amounts.amtBUser,
            amounts.amtLPUser
        ];

        returnId = executeCallHomoraBank(
            account,
            data,
            tokenAddresses,
            tokenAmountConsumption
        );
    }

    struct RepayAmounts {
        uint256 amtLPTake; // Take out LP token amount (from Homora)
        uint256 amtLPWithdraw; // Withdraw LP token amount (back to caller)
        uint256 amtARepay; // Repay tokenA amount
        uint256 amtBRepay; // Repay tokenB amount
        uint256 amtLPRepay; // Repay LP token amount
        uint256 amtAMin; // Desired tokenA amount
        uint256 amtBMin; // Desired tokenB amount
    }

    function removeLiquidityInternal(
        address account,
        HomoraBankData memory data
    ) internal returns (uint256 returnId) {
        (address tokenA, address tokenB, ) = abi.decode(
            data.spellArgs,
            (address, address, RepayAmounts)
        );

        address lpTokenAddr = IUnilikeSpell(data.spellAddr).getAndApprovePair(
            tokenA,
            tokenB
        );

        address[3] memory tokenAddresses = [tokenA, tokenB, lpTokenAddr];

        uint256[3] memory tokenAmountConsumption = [
            uint256(0),
            uint256(0),
            uint256(0)
        ];

        returnId = executeCallHomoraBank(
            account,
            data,
            tokenAddresses,
            tokenAmountConsumption
        );
    }

    struct HomoraBankData {
        address spellAddr;
        bytes4 spellSelector;
        bytes spellArgs;
        uint256 homoraBankId;
    }

    function execute(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        (
            bool isAdd,
            uint256 adapterPositionId,
            address spellAddr,
            bytes4 spellSelector,
            bytes memory spellArgs
        ) = abi.decode(encodedData, (bool, uint256, address, bytes4, bytes));
        if (adapterPositionId == 0) {
            adapterPositionId = positionIdNext++;
            PositionInfo[adapterPositionId].owner = account;
        } else {
            require(
                adapterPositionId < positionIdNext,
                "position id not exists"
            );
            require(
                account == PositionInfo[adapterPositionId].owner,
                "not position account"
            );
        }
        uint256 homoraBankId = PositionInfo[adapterPositionId].homoraBankId;
        HomoraBankData memory data = HomoraBankData(
            spellAddr,
            spellSelector,
            spellArgs,
            homoraBankId
        );
        if (isAdd) {
            uint256 returnId = addLiquidityInternal(account, data);
            if (homoraBankId == 0) {
                PositionInfo[adapterPositionId].homoraBankId = returnId;
                adapterPositionIds[account].push(adapterPositionId);
            }
        } else {
            require(homoraBankId != 0, "position id not exists");
            removeLiquidityInternal(account, data);
        }
        emit AlphaExecute(account, adapterPositionId, homoraBankId);
    }

    function getAdapterPositionInfo(uint256 adapterPositionId)
        external
        view
        returns (
            uint256 homoraBankId,
            address account,
            address collToken,
            uint256 collId,
            uint256 collateralSize
        )
    {
        homoraBankId = PositionInfo[adapterPositionId].homoraBankId;
        (, collToken, collId, collateralSize) = IHomoraBank(homoraBankAddr)
            .getPositionInfo(homoraBankId);
        account = PositionInfo[adapterPositionId].owner;
    }

    function getAdapterPositionIds(address account)
        external
        view
        returns (uint256[] memory)
    {
        return adapterPositionIds[account];
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

interface ISafeBox {
    function acceptGovernor() external;

    function adminClaim(uint256 amount) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function cToken() external view returns (address);

    function claim(uint256 totalAmount, bytes32[] calldata proof) external;

    function claimAndWithdraw(
        uint256 totalAmount,
        bytes32[] calldata proof,
        uint256 withdrawAmount
    ) external;

    function claimed(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function deposit(uint256 amount) external;

    function governor() external view returns (address);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function name() external view returns (string memory);

    function pendingGovernor() external view returns (address);

    function relayer() external view returns (address);

    function root() external view returns (bytes32);

    function setPendingGovernor(address _pendingGovernor) external;

    function setRelayer(address _relayer) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function uToken() external view returns (address);

    function updateRoot(bytes32 _root) external;

    function withdraw(uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface ISafeBoxAVAX {
    function acceptGovernor() external;

    function adminClaim(uint256 amount) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function cToken() external view returns (address);

    function claim(uint256 totalAmount, bytes32[] calldata proof) external;

    function claimAndWithdraw(
        uint256 totalAmount,
        bytes32[] calldata proof,
        uint256 withdrawAmount
    ) external;

    function claimed(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function deposit() external payable;

    function governor() external view returns (address);

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function name() external view returns (string memory);

    function pendingGovernor() external view returns (address);

    function relayer() external view returns (address);

    function root() external view returns (bytes32);

    function setPendingGovernor(address _pendingGovernor) external;

    function setRelayer(address _relayer) external;

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function updateRoot(bytes32 _root) external;

    function weth() external view returns (address);

    function withdraw(uint256 amount) external;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IHomoraBank {
    function setWhitelistUsers(
        address[] calldata users,
        bool[] calldata statuses
    ) external;

    struct CreditLimit {
        address user;
        address token;
        uint256 limit;
    }

    function setCreditLimits(CreditLimit[] calldata _creditLimits) external;

    function EXECUTOR() external view returns (address);

    function POSITION_ID() external view returns (uint256);

    function SPELL() external view returns (address);

    function _GENERAL_LOCK() external view returns (uint256);

    function _IN_EXEC_LOCK() external view returns (uint256);

    function acceptGovernor() external;

    function accrue(address token) external;

    function accrueAll(address[] memory tokens) external;

    function addBank(address token, address cToken) external;

    function allBanks(uint256) external view returns (address);

    function allowBorrowStatus() external view returns (bool);

    function allowContractCalls() external view returns (bool);

    function allowRepayStatus() external view returns (bool);

    function bankStatus() external view returns (uint256);

    function banks(address)
        external
        view
        returns (
            bool isListed,
            uint8 index,
            address cToken,
            uint256 reserve,
            uint256 totalDebt,
            uint256 totalShare
        );

    function borrow(address token, uint256 amount) external;

    function borrowBalanceCurrent(uint256 positionId, address token)
        external
        returns (uint256);

    function borrowBalanceStored(uint256 positionId, address token)
        external
        view
        returns (uint256);

    function cTokenInBank(address) external view returns (bool);

    function caster() external view returns (address);

    function everWhitelistedUsers(address) external view returns (bool);

    function execute(
        uint256 positionId,
        address spell,
        bytes memory data
    ) external payable returns (uint256);

    function feeBps() external view returns (uint256);

    function getBankInfo(address token)
        external
        view
        returns (
            bool isListed,
            address cToken,
            uint256 reserve,
            uint256 totalDebt,
            uint256 totalShare
        );

    function getBorrowETHValue(uint256 positionId)
        external
        view
        returns (uint256);

    function getCollateralETHValue(uint256 positionId)
        external
        view
        returns (uint256);

    function getCurrentPositionInfo()
        external
        view
        returns (
            address owner,
            address collToken,
            uint256 collId,
            uint256 collateralSize
        );

    function getPositionDebtShareOf(uint256 positionId, address token)
        external
        view
        returns (uint256);

    function getPositionDebts(uint256 positionId)
        external
        view
        returns (address[] memory tokens, uint256[] memory debts);

    function getPositionInfo(uint256 positionId)
        external
        view
        returns (
            address owner,
            address collToken,
            uint256 collId,
            uint256 collateralSize
        );

    function governor() external view returns (address);

    function initialize(address _oracle, uint256 _feeBps) external;

    function liquidate(
        uint256 positionId,
        address debtToken,
        uint256 amountCall
    ) external;

    function nextPositionId() external view returns (uint256);

    function oracle() external view returns (address);

    function pendingGovernor() external view returns (address);

    function positions(uint256)
        external
        view
        returns (
            address owner,
            address collToken,
            uint256 collId,
            uint256 collateralSize,
            uint256 debtMap
        );

    function putCollateral(
        address collToken,
        uint256 collId,
        uint256 amountCall
    ) external;

    function repay(address token, uint256 amountCall) external;

    function support(address token) external view returns (bool);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function takeCollateral(
        address collToken,
        uint256 collId,
        uint256 amount
    ) external;

    function transmit(address token, uint256 amount) external;

    function whitelistedSpells(address) external view returns (bool);

    function whitelistedTokens(address) external view returns (bool);

    function whitelistedUserBorrowShares(address, address)
        external
        view
        returns (uint256);

    function whitelistedUserCreditLimits(address, address)
        external
        view
        returns (uint256);

    function whitelistedUsers(address) external view returns (bool);

    function withdrawReserve(address token, uint256 amount) external;

    function worker() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IUnilikeSpell {
    function acceptGovernor() external;

    struct Amounts {
        uint256 amtAUser; // Supplied tokenA amount
        uint256 amtBUser; // Supplied tokenB amount
        uint256 amtLPUser; // Supplied LP token amount
        uint256 amtABorrow; // Borrow tokenA amount
        uint256 amtBBorrow; // Borrow tokenB amount
        uint256 amtLPBorrow; // Borrow LP token amount
        uint256 amtAMin; // Desired tokenA amount (slippage control)
        uint256 amtBMin; // Desired tokenB amount (slippage control)
    }

    function addLiquidityWERC20(
        address tokenA,
        address tokenB,
        Amounts memory amt
    ) external;

    function addLiquidityWMasterChef(
        address tokenA,
        address tokenB,
        Amounts memory amt,
        uint256 pid
    ) external;

    function approved(address, address) external view returns (bool);

    function bank() external view returns (address);

    function factory() external view returns (address);

    function getAndApprovePair(address tokenA, address tokenB)
        external
        returns (address);

    function governor() external view returns (address);

    function harvestWMasterChef() external;

    function joe() external view returns (address);

    function pairs(address, address) external view returns (address);

    function pendingGovernor() external view returns (address);

    struct RepayAmounts {
        uint256 amtLPTake; // Take out LP token amount (from Homora)
        uint256 amtLPWithdraw; // Withdraw LP token amount (back to caller)
        uint256 amtARepay; // Repay tokenA amount
        uint256 amtBRepay; // Repay tokenB amount
        uint256 amtLPRepay; // Repay LP token amount
        uint256 amtAMin; // Desired tokenA amount
        uint256 amtBMin; // Desired tokenB amount
    }

    function removeLiquidityWERC20(
        address tokenA,
        address tokenB,
        RepayAmounts memory amt
    ) external;

    function removeLiquidityWMasterChef(
        address tokenA,
        address tokenB,
        RepayAmounts memory amt
    ) external;

    function router() external view returns (address);

    function setPendingGovernor(address _pendingGovernor) external;

    function setWhitelistLPTokens(
        address[] memory lpTokens,
        bool[] memory statuses
    ) external;

    function setWhitelistRewarders(
        address[] memory rewarders,
        bool[] memory statuses
    ) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function werc20() external view returns (address);

    function weth() external view returns (address);

    function whitelistedLpTokens(address) external view returns (bool);

    function whitelistedRewarders(address) external view returns (bool);

    function wmasterchef() external view returns (address);
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