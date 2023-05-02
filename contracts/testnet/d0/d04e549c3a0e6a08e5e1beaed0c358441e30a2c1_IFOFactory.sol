// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin/access/Ownable2Step.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin/proxy/Clones.sol";

import "./JoeIFOInitializable.sol";
import "./interfaces/IJoeIFOFactory.sol";

/**
 * @title IFOFactory
 * @author Trader Joe
 * @notice Factory contract for IFO pools
 */
contract IFOFactory is IJoeIFOIFactory, Ownable2Step {
    using SafeERC20 for IERC20;

    address public ifoImplementation;

    /**
     * @notice Set a new implementation address
     * @param implementation: The address of the new implementation
     */
    function setImplementation(address implementation) external onlyOwner{
        if (implementation == address(0)) revert JoeIFOFactory__CannotBe0Address();

        ifoImplementation = implementation;

        emit NewIFOImplementation(ifoImplementation);
    }

    /**
     * @notice It creates and initializes a IFO Pool.
     * @param raisingToken: The raising token used
     * @param offeringToken: the token that is offered for the IFO
     * @param startTime: The start block for the IFO
     * @param endTime: The end block for the IFO
     * @param adminAddress: The admin address for handling tokens
     * @param fundRaiserAddress: The fund Raiser Address
     * @return The Address of the contract
     */
    function createIFO(
        address raisingToken,
        address offeringToken,
        uint256 startTime,
        uint256 endTime,
        uint256 fundRaiserLockBlock,
        address adminAddress,
        address fundRaiserAddress
    ) external onlyOwner returns (address){
        if (ifoImplementation == address(0)) revert JoeIFOFactory__ImplementationNotSet();
        if (raisingToken == offeringToken) revert JoeIFOFactory__RaisingTokenCannotBeOfferingToken();
        if (startTime >= endTime) revert JoeIFOFactory__StartTimeHigherEndTime();
        if (startTime <= block.number) revert JoeIFOFactory__StartTimeHigherThanCurrent();
        if (fundRaiserLockBlock < endTime) revert JoeIFOFactory__FundRaiserHigherThenEndTime();

        bytes32 salt = keccak256(abi.encodePacked(raisingToken, offeringToken, startTime));
        
        address clone = Clones.cloneDeterministic(ifoImplementation, salt);
        JoeIFOInitializable(clone).initialize(raisingToken, offeringToken, startTime, endTime, fundRaiserLockBlock, adminAddress, fundRaiserAddress);

        emit NewIFOPool(clone);

        return address(clone);
    }

    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param tokenAddress: The address of the token to withdraw
     * @dev This function is only callable by admin.
     */
    function recoverWrongTokens(address tokenAddress) external onlyOwner {
        uint256 balanceToRecover = IERC20(tokenAddress).balanceOf(address(this));
        if (balanceToRecover == 0) revert JoeIFOFactory__BalanceMustBePositive();
        IERC20(tokenAddress).safeTransfer(address(msg.sender), balanceToRecover);

        emit AdminTokenRecovery(tokenAddress, balanceToRecover);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "openzeppelin/security/ReentrancyGuard.sol";
import "openzeppelin/token/ERC20/IERC20.sol";
import "openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "openzeppelin-upgradeable/access/Ownable2StepUpgradeable.sol";

import "./interfaces/IJoeIFOInitializable.sol";

/**
 * @title JoeIFOInitializable
 * @author Trader Joe
 * @notice Contract used to deploy and manage IFO pools.
 */
contract JoeIFOInitializable is IJoeIFOInitializable, ReentrancyGuard, Ownable2StepUpgradeable {
    using SafeERC20 for IERC20;

    // Max time (for sanity checks)
    uint256 public constant MAX_TIME_BUFFER = 2_592_000; // 1 month long

    uint256 internal constant PRECISION = 1e12;

    // Fund receiver address
    address public fundsReceiverAddress;

    // The raising token used
    IERC20 public raisingToken;

    // The offering token
    IERC20 public offeringToken;

    // The timestamp of the start of the IFO
    uint256 public startTime;

    // The timestamp of the end of the IFO
    uint256 public endTime;
    
    // The timestamp when raised funds are transferable
    uint256 public fundsReceiverTimelock;

    // Total tokens distributed across the pools
    uint256 public totalTokensOffered;

    // Array of PoolCharacteristics
    PoolCharacteristics[] private _poolInformation;

    // It maps the address to pool id to UserInfo
    mapping(address => mapping(uint8 => UserInfo)) private _userInfo;

    /**
     * @notice It initializes the contract
     * @dev It can only be called once.
     * @param _raisingToken: The raising token used
     * @param _offeringToken: The token that is offered for the IFO
     * @param _startTime: The start time for the IFO
     * @param _endTime: The end time for the IFO
     * @param _fundsReceiverTimelock: The time until which the raised funds are blocked
     * @param _adminAddress: The admin address for handling tokens
     * @param _fundsReceiverAddress: The funds receiver address 
     */
    function initialize(
        address _raisingToken,
        address _offeringToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _fundsReceiverTimelock,
        address _adminAddress,
        address _fundsReceiverAddress
    ) public initializer {
        if (_fundsReceiverAddress == address(0)) revert JoeIFO__CannotBe0Address();
        
        __Ownable2Step_init();

        raisingToken = IERC20(_raisingToken);
        offeringToken = IERC20(_offeringToken);
        startTime = _startTime;
        endTime = _endTime;
        fundsReceiverTimelock = _fundsReceiverTimelock;
        fundsReceiverAddress = _fundsReceiverAddress;

        // Transfer ownership to admin
        transferOwnership(_adminAddress);
    }

        /**
     * @notice It returns the pool information
     * @param pid: The Pool Id
     * @return raisingAmountPool: The amount of raising tokens raised
     * @return offeringAmountPool: The amount of tokens offered for the pool (in offeringToken)
     * @return minPerUserInRaising: The min amount of raising tokens per user (if 0, it is ignored)
     * @return maxPerUserInRaising: The limit of raising tokens per user (if 0, it is ignored)
     * @return taxPercentage: The tax percentage applied on the pool
     * @return totalAmountPool: The total amount pool deposited (in raising tokens)
     */
    function getPoolInformation(uint256 pid)
        external
        view
        override
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        return (
            _poolInformation[pid].raisingAmountPool,
            _poolInformation[pid].offeringAmountPool,
            _poolInformation[pid].minPerUserInRaising,
            _poolInformation[pid].maxPerUserInRaising,
            _poolInformation[pid].taxPercentage,
            _poolInformation[pid].totalAmountPool
        );
    }

    /**
     * @notice It returns the tax overflow rate calculated for a pool
     * @dev 1e11 means 0.1 (10%) / 1 means 1e-13 (0.0000001%) / 1e12 means 1 (100%)
     * @param pid: The pool id
     * @return It returns the tax percentage
     */
    function getPoolTaxPercentage(uint256 pid) external view override returns (uint256) {
        return _poolInformation[pid].taxPercentage;
    }

    /**
     * @notice External view function to see user allocations for both pools
     * @param user: The user address
     * @param pids[]: The array of pids
     * @return The array with the allocation of the user
     */
    function getUserAllocationPools(address user, uint8[] calldata pids)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256[] memory allocationPools = new uint256[](pids.length);
        for (uint8 i = 0; i < pids.length; i++) {
            allocationPools[i] = _getUserAllocationPool(user, pids[i]);
        }
        return allocationPools;
    }

    /**
     * @notice External view function to see user information
     * @param user: The user address
     * @param pids[]: The array of pids
     * @return The array with the amounts of token provided to each pool
     * @return The array with the status of claim for each pool
     */
    function getUserInfo(address user, uint8[] calldata pids)
        external
        view
        override
        returns (uint256[] memory, bool[] memory)
    {
        uint256[] memory amountPools = new uint256[](pids.length);
        bool[] memory statusPools = new bool[](pids.length);

        for (uint8 i = 0; i < pids.length; i++) {
            amountPools[i] = _userInfo[user][i].amountPool;
            statusPools[i] = _userInfo[user][i].claimedPool;
        }
        return (amountPools, statusPools);
    }

    /**
     * @notice External view function to see user offering and refunding amounts for both pools
     * @param user: The user address
     * @param pids: The array of pids
     * @return The array with the offering and refunding amounts for each pool
     */
    function getUserOfferingAndRefundingAmountsForPools(address user, uint8[] calldata pids)
        external
        view
        override
        returns (uint256[2][] memory)
    {
        uint256[2][] memory amountPools = new uint256[2][](pids.length);

        for (uint8 i = 0; i < pids.length; i++) {
            uint256 userOfferingAmountPool;
            uint256 userRefundingAmountPool;

            if (_poolInformation[pids[i]].raisingAmountPool > 0) {
                (userOfferingAmountPool, userRefundingAmountPool) =
                    _calculateOfferingAndRefundingAmountsPool(user, pids[i]);
            }

            amountPools[i] = [userOfferingAmountPool, userRefundingAmountPool];
        }
        return amountPools;
    }

    /**
     * @notice External view function to get the Pool length
     * @return The length of the pool IFO
     */
    function getPoolLength() external view override returns (uint8){
        return uint8(_poolInformation.length);
    }

    /**
     * @notice It allows users to deposit raising tokens to pool
     * @param amount: The number of raising token used (18 decimals)
     * @param pid: The pool id
     * @dev This function can only be called from EOA.
     */
    function depositPool(uint256 amount, uint8 pid) external override nonReentrant {
        // Checks whether the pool id is valid
        if (pid >= _poolInformation.length) revert JoeIFO__PoolIDInvalid();

        // Checks if that pool was set
        if (_poolInformation[pid].offeringAmountPool == 0 && _poolInformation[pid].raisingAmountPool == 0)
            revert JoeIFO__PoolNotSet();

        // Checks whether the current timestamp is not too early
        if (block.timestamp < startTime) revert JoeIFO__IFONotStarted();

        // Checks whether the current timestamp is not too late
        if (block.timestamp > endTime) revert JoeIFO__IFOEnded();

        // Checks that the amount deposited is not inferior to 0
        if (amount <= 0) revert JoeIFO__InvalidAmount();

        // Verify tokens were deposited properly
        if (offeringToken.balanceOf(address(this)) < totalTokensOffered) revert JoeIFO__InvalidAmountOfferingToken();

        uint256 newAmountPool = _userInfo[msg.sender][pid].amountPool + amount;

        uint256 maxPerUserInRaising = _poolInformation[pid].maxPerUserInRaising;
        // Checks if the pool has max limit per user
        if (maxPerUserInRaising > 0) {
            // Checks whether the limit has been reached
            if (newAmountPool > maxPerUserInRaising) revert JoeIFO__NewAmountAboveUserLimit(maxPerUserInRaising);
        }

        uint256 minPerUserInRaising = _poolInformation[pid].minPerUserInRaising;
        // Checks if the pool has a min limit per user
        if (minPerUserInRaising > 0) {
            // Checks whether the limit has been reached
            if (newAmountPool < minPerUserInRaising) revert JoeIFO__NewAmountUnderUserLimit(minPerUserInRaising);
        }

        // Updates the user status
        _userInfo[msg.sender][pid].amountPool = newAmountPool;

        // Updates the totalAmount for pool
        _poolInformation[pid].totalAmountPool += amount;

        // Transfers funds to this contract
        raisingToken.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposit(msg.sender, amount, pid);
    }

    /**
     * @notice It allows users to withdraw raising tokens to pool before the end of the IFO
     * @param amount: The number of raising tokens to withdraw (18 decimals)
     * @param pid: The pool id
     * @dev This function can only be called from EOA.
     */
    function withdrawPool(uint256 amount, uint8 pid) external override nonReentrant {
        // Checks whether the pool id is valid
        if (pid >= _poolInformation.length) revert JoeIFO__PoolIDInvalid();

        // Checks that pool was set
        if (_poolInformation[pid].offeringAmountPool == 0 && _poolInformation[pid].raisingAmountPool == 0)
            revert JoeIFO__PoolNotSet();

        // Checks whether the current timestamp is not too early
        if (block.timestamp < startTime) revert JoeIFO__IFONotStarted();

        // Checks whether the block number is not too late
        if (block.timestamp > endTime) revert JoeIFO__IFOEnded();

        // Checks that the amount to withdraw is not inferior to 0
        if (amount <= 0) revert JoeIFO__InvalidAmount();

        uint256 userDepositAmount = _userInfo[msg.sender][pid].amountPool;

        // Checks if withdraw amount is lower to the user pool balance
        if (amount > userDepositAmount) revert JoeIFO__InvalidAmount();

        uint256 newAmountPool =  userDepositAmount - amount;

        uint256 minPerUserInRaising = _poolInformation[pid].minPerUserInRaising;
        // Checks if the pool has a min limit per user
        if (minPerUserInRaising > 0) {
            // Checks whether the limit has been reached
            if (newAmountPool < minPerUserInRaising && newAmountPool != 0) revert JoeIFO__NewAmountUnderUserLimit(minPerUserInRaising);
        }

        // Updates the user status
        _userInfo[msg.sender][pid].amountPool = newAmountPool;

        // Updates the totalAmount for pool
        _poolInformation[pid].totalAmountPool -= amount;

        // Transfers funds to msg.sender
        raisingToken.safeTransfer(msg.sender, amount);

        emit Withdraw(msg.sender, amount, pid);
    }

    /**
     * @notice It allows users to harvest from pool
     * @param pid: The pool id
     * @dev This function can only be called from EOA.
     */
    function harvestPool(uint8 pid) external override nonReentrant {
        // Checks whether it is too early to harvest
        if (block.timestamp <= endTime) revert JoeIFO__IFONotEnded();

        // Checks whether the pool id is valid
        if (pid >= _poolInformation.length) revert JoeIFO__PoolIDInvalid();

        // Checks whether the user has participated
        if (_userInfo[msg.sender][pid].amountPool <= 0) revert JoeIFO__UserNotParticipated();

        // Checks whether the user has already harvested
        if (_userInfo[msg.sender][pid].claimedPool) revert JoeIFO__AlreadyHarvested();

        // Updates the harvest status
        _userInfo[msg.sender][pid].claimedPool = true;

        // Initialize the variables for offering, refunding user amounts
        (uint256 offeringTokenAmount, uint256 refundingTokenAmount) =
            _calculateOfferingAndRefundingAmountsPool(msg.sender, pid);

        // Transfer these tokens back to the user if quantity > 0
        if (offeringTokenAmount > 0) {
            offeringToken.safeTransfer(msg.sender, offeringTokenAmount);
        }

        if (refundingTokenAmount > 0) {
            raisingToken.safeTransfer(msg.sender, refundingTokenAmount);
        }

        emit Harvest(msg.sender, offeringTokenAmount, refundingTokenAmount, pid);
    }

    /**
     * @notice It allows the funds receiver to withdraw funds and the admin to collect fees
     * @param pid: The pool id
     */
    function finalWithdraw(uint8 pid) external override nonReentrant {
        // Checks whether the pool id is valid
        if (pid >= _poolInformation.length) revert JoeIFO__PoolIDInvalid();
        // Checks wether the sender is funds raiser
        if (msg.sender != fundsReceiverAddress) revert JoeIFO__NotFundsRaiser();
        // Checks if funds are still locked
        if (block.timestamp <= fundsReceiverTimelock) revert JoeIFO__FundsAreLocked();
        // Checks if funds have been already claimed
        if (_poolInformation[pid].fundsWithdraw) revert JoeIFO__FundsAlreadyClaimed();
        
        _poolInformation[pid].fundsWithdraw = true;
        
        uint256 withdrawAmount;
        uint256 fees;
        uint256 withrawableOfferingTokens;

        uint256 totalAmountPool = _poolInformation[pid].totalAmountPool;
        uint256 raisingAmountPool = _poolInformation[pid].raisingAmountPool;
        uint256 taxPercentage = _poolInformation[pid].taxPercentage;
        

        if (totalAmountPool > raisingAmountPool) {
            fees = raisingAmountPool * taxPercentage / PRECISION;
            withdrawAmount = raisingAmountPool - fees;
            withrawableOfferingTokens = 0;

        } else{
            fees = totalAmountPool * taxPercentage / PRECISION;
            withdrawAmount = totalAmountPool - fees;

            uint256 offeringAmountPool = _poolInformation[pid].offeringAmountPool;
            // Calculates the percentage raised out of the initial raising amount
            uint256 percentageAllocation = totalAmountPool * PRECISION / raisingAmountPool;
            // Calculates the amount of offering token to harvest
            uint256 harvestableOfferingAmount = offeringAmountPool * percentageAllocation / PRECISION;
            // Calculates the withdrawable amount of offering token
            withrawableOfferingTokens = offeringAmountPool - harvestableOfferingAmount;
        }

        if (withdrawAmount > 0) {
            raisingToken.safeTransfer(msg.sender, withdrawAmount);
        }

        if (withrawableOfferingTokens > 0){
            offeringToken.safeTransfer(msg.sender, withrawableOfferingTokens);
        }

        if (fees > 0){
            raisingToken.safeTransfer(owner(), fees);
        }

        emit FundsReceiverWithdraw(pid, withdrawAmount, fees);
    }
    
    /**
     * @notice It allows the admin to recover wrong tokens sent to the contract
     * @param tokenAddress: The address of the token to recover (18 decimals)
     * @param tokenAmount: The number of token amount to recover
     * @dev This function is only callable by admin
     */
    function recoverWrongTokens(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        if (tokenAddress == address(raisingToken)) revert JoeIFO__CannotBeRaisingToken();
        if (tokenAddress == address(offeringToken)) revert JoeIFO__CannotBeOfferingToken();

        IERC20(tokenAddress).safeTransfer(msg.sender, tokenAmount);

        emit AdminTokenRecovery(tokenAddress, tokenAmount);
    }

    /**
     * @notice It adds and sets parameters for a pool
     * @param offeringAmountPool: The offering amount (in tokens)
     * @param raisingAmountPool: The raising amount (in raising tokens)
     * @param minPerUserInRaising: The min amount a user can deposit (in raising tokens)
     * @param maxPerUserInRaising: The max amount a user can deposit (in raising tokens)
     * @param taxPercentage: The percentage of tax
     * @dev This function is only callable by admin.
     */
    function addPool(
        uint256 offeringAmountPool,
        uint256 raisingAmountPool,
        uint256 minPerUserInRaising,
        uint256 maxPerUserInRaising,
        uint256 taxPercentage
    ) external override onlyOwner {
        if (block.timestamp >= startTime) revert JoeIFO__IFOStarted();
        if (minPerUserInRaising > maxPerUserInRaising) revert JoeIFO__MinHigherMaxLimits();

        PoolCharacteristics memory newPool;

        newPool.offeringAmountPool = offeringAmountPool;
        newPool.raisingAmountPool = raisingAmountPool;
        newPool.minPerUserInRaising = minPerUserInRaising;
        newPool.maxPerUserInRaising = maxPerUserInRaising;
        newPool.taxPercentage = taxPercentage;
        newPool.fundsWithdraw = false;

        _poolInformation.push(newPool);

        // Update totalTokensOffered
        totalTokensOffered += offeringAmountPool;

        emit PoolAdded(offeringAmountPool, raisingAmountPool, uint8(_poolInformation.length - 1));
    }

    /**
     * @notice It sets parameters for a pool
     * @param pid: The Pool Id to set
     * @param offeringAmountPool: The offering amount (in tokens)
     * @param raisingAmountPool: The raising amount (in raising tokens)
     * @param minPerUserInRaising: The min amount a user can deposit (in raising tokens)
     * @param maxPerUserInRaising: The max amount a user can deposit (in raising tokens)
     * @param taxPercentage: The percentage of tax
     * @dev This function is only callable by admin.
     */
    function setPool(
        uint8 pid,
        uint256 offeringAmountPool,
        uint256 raisingAmountPool,
        uint256 minPerUserInRaising,
        uint256 maxPerUserInRaising,
        uint256 taxPercentage
    ) external override onlyOwner {
        if (block.timestamp >= startTime) revert JoeIFO__IFOStarted();
        if (minPerUserInRaising > maxPerUserInRaising) revert JoeIFO__MinHigherMaxLimits();
        if (pid >= _poolInformation.length) revert JoeIFO__PoolIDInvalid();

        // Remove the previous offering amount value from totalTokensOffered
        totalTokensOffered -= _poolInformation[pid].offeringAmountPool;

        _poolInformation[pid].offeringAmountPool = offeringAmountPool;
        _poolInformation[pid].raisingAmountPool = raisingAmountPool;
        _poolInformation[pid].minPerUserInRaising = minPerUserInRaising;
        _poolInformation[pid].maxPerUserInRaising = maxPerUserInRaising;
        _poolInformation[pid].taxPercentage = taxPercentage;

        // Update the totalTokensOffered value
        totalTokensOffered += offeringAmountPool;

        emit PoolSet(offeringAmountPool, raisingAmountPool, pid);
    }

    /**
     * @notice It allows the admin to update start and end times
     * @param newStartTime: The new start time
     * @param newEndTime: The new end time
     * @dev This function is only callable by admin.
     */
    function setStartAndEndTimes(uint256 newStartTime, uint256 newEndTime) external onlyOwner {
        if (newEndTime >= (block.timestamp + MAX_TIME_BUFFER)) revert JoeIFO__EndTimeTooFar();
        if (block.timestamp >= startTime) revert JoeIFO__IFOStarted();
        if (newStartTime >= newEndTime) revert JoeIFO__StartTimeHigherEndTime();
        if (block.timestamp >= newStartTime) revert JoeIFO__NewStartTimeLowerCurrentTime();

        startTime = newStartTime;
        endTime = newEndTime;

        emit NewStartAndEndTimes(newStartTime, newEndTime);
    }

    /**
     * @notice It allows the admin to update the lock time of the funds
     * @param newFundsReceiverTimelock: The new funds receiver lock time
     * @dev This function is only callable by admin.
     */
    function setFundsReceiverTimelock(uint256 newFundsReceiverTimelock) external onlyOwner {
        if (newFundsReceiverTimelock < endTime) revert JoeIFO__TimeLockLowerEndTime();
        if (block.timestamp >= startTime) revert JoeIFO__IFOStarted();
        
        fundsReceiverTimelock = newFundsReceiverTimelock;

        emit NewFundsReceiverTimelock(newFundsReceiverTimelock);
    }

    /**
     * @notice It calculates the offering amount for a user and the number of raising tokens to transfer back.
     * @param user: The user address
     * @param pid: The pool id
     * @return {uint256, uint256} It returns the offering amount, the refunding amount (in raising tokens),
     */
    function _calculateOfferingAndRefundingAmountsPool(address user, uint8 pid)
        internal
        view
        returns (uint256, uint256)
    {
        uint256 userOfferingAmount;
        uint256 userRefundingAmount;

        uint256 totalAmountPool = _poolInformation[pid].totalAmountPool;
        uint256 raisingAmountPool = _poolInformation[pid].raisingAmountPool;
        uint256 offeringAmountPool = _poolInformation[pid].offeringAmountPool;
        uint256 userAmountPool = _userInfo[user][pid].amountPool;

        if (totalAmountPool > raisingAmountPool) {
            // Calculates allocation for the user
            uint256 allocation = _getUserAllocationPool(user, pid);

            // Calculates the offering amount for the user based on the offeringAmount for the pool
            userOfferingAmount = offeringAmountPool * allocation / PRECISION;

            // Calculates the payAmount
            uint256 payAmount = raisingAmountPool * allocation / PRECISION;

            // Calculates the refunding amount
            userRefundingAmount = userAmountPool - payAmount;

        } else {
            userRefundingAmount = 0;
            // _userInfo[user] / (raisingAmount / offeringAmount)
            userOfferingAmount = userAmountPool * offeringAmountPool / raisingAmountPool;
        }
        return (userOfferingAmount, userRefundingAmount);
    }

    /**
     * @notice It returns the user allocation for pool
     * @dev 1e11 means 0.1 (10%) / 1 means 1e-13 (0.0000001%) / 1e12 means 1 (100%)
     * @param user: The user address
     * @param pid: The pool id
     * @return It returns the user's share of pool
     */
    function _getUserAllocationPool(address user, uint8 pid) internal view returns (uint256) {
        uint256 totalAmountPool = _poolInformation[pid].totalAmountPool;
        if (totalAmountPool > 0) {
            return _userInfo[user][pid].amountPool * PRECISION / totalAmountPool;
        } else {
            return 0;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title IJoeIFOFactory.
 * @notice It is an interface for JoeIFOFactory.sol
 */
 interface IJoeIFOIFactory {
    error JoeIFOFactory__RaisingTokenCannotBeOfferingToken();
    error JoeIFOFactory__StartTimeHigherEndTime();
    error JoeIFOFactory__StartTimeHigherThanCurrent();
    error JoeIFOFactory__FundRaiserHigherThenEndTime();
    error JoeIFOFactory__BalanceMustBePositive();
    error JoeIFOFactory__CannotBe0Address();
    error JoeIFOFactory__ImplementationNotSet();

    event AdminTokenRecovery(address indexed tokenRecovered, uint256 amount);

    event NewIFOImplementation(address indexed implementation);

    event NewIFOPool(address indexed poolAddress);

    function setImplementation(address implementation) external;

    function createIFO(
        address raisingToken,
        address offeringToken,
        uint256 startTime,
        uint256 endTime,
        uint256 fundRaiserLockBlock,
        address adminAddress,
        address fundRaiserAddress
    ) external returns (address);

    function recoverWrongTokens(address tokenAddress) external;
 }

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./OwnableUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2StepUpgradeable is Initializable, OwnableUpgradeable {
    function __Ownable2Step_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable2Step_init_unchained() internal onlyInitializing {
    }
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/**
 * @title IJoeIFOInitializable.
 * @notice It is an interface for JoeIFOInitializable.sol
 */
interface IJoeIFOInitializable {
    error JoeIFO__NotFundsRaiser();
    error JoeIFO__PoolIDInvalid();
    error JoeIFO__PoolNotSet();
    error JoeIFO__IFONotStarted();
    error JoeIFO__IFOStarted();
    error JoeIFO__IFOEnded();
    error JoeIFO__IFONotEnded();
    error JoeIFO__InvalidAmount();
    error JoeIFO__InvalidAmountOfferingToken();
    error JoeIFO__NewAmountAboveUserLimit(uint256 maxPerUserInRaising);
    error JoeIFO__NewAmountUnderUserLimit(uint256 minPerUserInRaising);
    error JoeIFO__UserNotParticipated();
    error JoeIFO__AlreadyHarvested();
    error JoeIFO__FundsAreLocked();
    error JoeIFO__FundsAlreadyClaimed();
    error JoeIFO__CannotBeRaisingToken();
    error JoeIFO__CannotBeOfferingToken();
    error JoeIFO__EndTimeTooFar();
    error JoeIFO__StartTimeHigherEndTime();
    error JoeIFO__NewStartTimeLowerCurrentTime();
    error JoeIFO__TimeLockLowerEndTime();
    error JoeIFO__MinHigherMaxLimits();
    error JoeIFO__CannotBe0Address();

    /**
     * @notice Struct that contains each pool characteristics
     * - raisingAmountPool: The amount of tokens raised for the pool (in raising tokens)
     * - offeringAmountPool: The amount of tokens offered for the pool (in offeringTokens)
     * - minPerUserInRaising: The min amount a user can deposit in the pool (in raising Tokens)
     * - maxPerUserInRaising: The max amount a user can deposit in the pool (in raising Tokens)
     * - taxPercentage: The percentage of tax deducted from the raising Token.
     * - totalAmountPool: The total amount pool deposited (in raising tokens)
     */
    struct PoolCharacteristics {
        uint256 raisingAmountPool;
        uint256 offeringAmountPool;
        uint256 minPerUserInRaising;
        uint256 maxPerUserInRaising;
        uint256 taxPercentage;
        uint256 totalAmountPool;
        bool fundsWithdraw;
    }

    /**
     * @notice Struct that contains each user information for each pool
     * - amountPool: The amount of token the user has provided to the pool.
     * - claimedPool: Whether the user has claimed offering token from the pool (default: false)
     */
    struct UserInfo {
        uint256 amountPool;
        bool claimedPool;
    }

    // Fund receiver withdraw event
    event FundsReceiverWithdraw(uint8 pid, uint256 amountRaising, uint256 fees);

    // Admin recovers token event
    event AdminTokenRecovery(address tokenAddress, uint256 amountTokens);

    // Deposit event
    event Deposit(address indexed user, uint256 amount, uint8 indexed pid);

    // Withdraw event
    event Withdraw(address indexed user, uint256 amount, uint8 indexed pid);

    // Harvest event
    event Harvest(address indexed user, uint256 offeringAmount, uint256 excessAmount, uint8 indexed pid);

    // Event for new start & end time
    event NewStartAndEndTimes(uint256 startTime, uint256 endTime);

    // Event for new funds receiver time lock
    event NewFundsReceiverTimelock(uint256 fundsReceiverTimelock);

    // Event when a pool is added
    event PoolAdded(uint256 offeringAmountPool, uint256 raisingAmountPool, uint8 pid);

    // Event when a pool is set
    event PoolSet(uint256 offeringAmountPool, uint256 raisingAmountPool, uint8 pid);

    function getPoolInformation(uint256 pid)
        external
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256);

    function getPoolTaxPercentage(uint256 pid) external view returns (uint256);

    function getUserInfo(address user, uint8[] calldata pids)
        external
        view
        returns (uint256[] memory, bool[] memory);

    function getUserAllocationPools(address user, uint8[] calldata pids) external view returns (uint256[] memory);

    function getUserOfferingAndRefundingAmountsForPools(address user, uint8[] calldata pids)
        external
        view
        returns (uint256[2][] memory);
    
    function getPoolLength() external view returns (uint8);

    function addPool(
        uint256 offeringAmountPool,
        uint256 raisingAmountPool,
        uint256 minPerUserInRaising,
        uint256 maxPerUserInRaising,
        uint256 taxPercentage
    ) external;

    function setPool(
        uint8 pid,
        uint256 offeringAmountPool,
        uint256 raisingAmountPool,
        uint256 minPerUserInRaising,
        uint256 maxPerUserInRaising,
        uint256 taxPercentage
    ) external;

    function depositPool(uint256 amount, uint8 pid) external;

    function withdrawPool(uint256 amount, uint8 pid) external;

    function harvestPool(uint8 pid) external;

    function finalWithdraw(uint8 pid) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}