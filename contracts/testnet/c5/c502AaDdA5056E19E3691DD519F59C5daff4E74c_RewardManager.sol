/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-10
*/

// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT AND UNLICENSED
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

// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File contracts/interfaces/ISparkWorldToken.sol

pragma solidity 0.8.11;

interface ISparkWorldToken is IERC20 {
    // function setLocker(address _locker) external;

    function setAllocationAddresses(
        address _SeedAddr,
        address _StrategicRoundAddr,
        address _PrivateSaleAddr,
        address _PublicSaleAddr,
        address _TeamAllocationAddr,
        address _StakingAddr,
        address _EchosystemTreasuryAddr,
        address _LiquidityAddr,
        address _AdvisorsAddr,
        address _AirdropAddr
    ) external;

    function distributeTokens() external;

    function getFeeWallet() external returns (address);

    function setFeeWallet(address _newFeeWallet) external;
}

// File contracts/Role/Roles.sol

pragma solidity ^0.8.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

// File contracts/Role/Operator.sol

pragma solidity ^0.8.0;

contract Operator is Context {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private _operators;

    constructor() {
        if (!isOperator(_msgSender())) {
            _addOperator(_msgSender());
        }
    }

    modifier onlyOperator() {
        require(
            isOperator(_msgSender()),
            "OperatorRole: caller does not have the Operator role"
        );
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return _operators.has(account);
    }

    function addOperator(address account) public onlyOperator {
        _addOperator(account);
    }

    function renounceOperator() public {
        _removeOperator(_msgSender());
    }

    function _addOperator(address account) internal {
        _operators.add(account);
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        _operators.remove(account);
        emit OperatorRemoved(account);
    }
}

// File contracts/Role/Rewarder.sol

pragma solidity ^0.8.0;

contract Rewarder is Context {
    using Roles for Roles.Role;

    event RewarderAdded(address indexed account);
    event RewarderRemoved(address indexed account);

    Roles.Role private _rewarders;

    constructor() {
        if (!isRewarder(_msgSender())) {
            _addRewarder(_msgSender());
        }
    }

    modifier onlyRewarder() {
        require(
            isRewarder(_msgSender()),
            "RewarderRole: caller does not have the Rewarder role"
        );
        _;
    }

    function isRewarder(address account) public view returns (bool) {
        return _rewarders.has(account);
    }

    function addRewarder(address account) public onlyRewarder {
        _addRewarder(account);
    }

    function renounceRewarder() public {
        _removeRewarder(_msgSender());
    }

    function _addRewarder(address account) internal {
        _rewarders.add(account);
        emit RewarderAdded(account);
    }

    function _removeRewarder(address account) internal {
        _rewarders.remove(account);
        emit RewarderRemoved(account);
    }
}

// File contracts/Token/RewardManager.sol

pragma solidity 0.8.11;

// ToDO: use access control instead
// ToDo: do totem task for this too
contract RewardManager is Context, Ownable, Operator, Rewarder {
    ISparkWorldToken sparkWorldToken;

    event SetOperator(address operator);
    event SetRewarder(address rewarder);

    constructor(ISparkWorldToken _sparkWorldToken) {
        sparkWorldToken = _sparkWorldToken;
    }

    function setOperator(address _newOperator) public onlyOwner {
        require(
            _newOperator != address(0),
            "0200 New Operator address cannot be zero."
        );

        addOperator(_newOperator);
        addRewarder(_newOperator);
        emit SetOperator(_newOperator);
    }

    function addPool(address _poolAddress) public onlyOperator {
        require(
            _poolAddress != address(0),
            "0210 Pool address cannot be zero."
        );

        addRewarder(_poolAddress);
        emit SetRewarder(_poolAddress);
    }

    function rewardUser(address _user, uint256 _amount) public onlyRewarder {
        require(_user != address(0), "0230 User address cannot be zero.");

        require(sparkWorldToken.transfer(_user, _amount));
    }
}