/**
 *Submitted for verification at snowtrace.io on 2022-08-04
*/

// File: gladiator-finance-contracts/contracts/interfaces/IBasisAsset.sol



pragma solidity ^0.8.0;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: gladiator-finance-contracts/contracts/GladVesting.sol



pragma solidity 0.8.9;



contract GladVesting is Ownable {
    /// @notice GLADSHARE token
    address public gladshare;

    /// @notice team wallet
    address public team;

    /// @notice team vesting amount
    uint256 public teamVestingAmount;

    /// @notice treasury wallet
    address public treasury;

    /// @notice treasury vesting amount
    uint256 public treasuryVestingAmount;

    /// @notice vesting start time
    uint256 public vestingStartTime;

    /// @notice vesting period
    uint256 public vestingPeriod;

    /// @notice last claim time
    uint256 public lastClaimTimestamp;

    event Claimed(uint256 teamAmount, uint256 treasuryAmount);

    constructor(
        address _gladshare,
        address _team,
        uint256 _teamVestingAmount,
        address _treasury,
        uint256 _treasuryVestingAmount,
        uint256 _vestingStartTime,
        uint256 _vestingPeriod
    ) {
        require(_gladshare != address(0), "invalid gladshare address");
        require(block.timestamp < _vestingStartTime, "late");
        gladshare = _gladshare;
        team = _team;
        teamVestingAmount = _teamVestingAmount;
        treasury = _treasury;
        treasuryVestingAmount = _treasuryVestingAmount;
        vestingStartTime = _vestingStartTime;
        lastClaimTimestamp = _vestingStartTime;
        vestingPeriod = _vestingPeriod;
    }

    function setTeam(address _team) external onlyOwner {
        team = _team;
    }

    function setTreasury(address _treasury) external onlyOwner {
        treasury = _treasury;
    }

    function claim() external {
        uint256 vestingEndTime = vestingStartTime + vestingPeriod;
        require(block.timestamp > lastClaimTimestamp, "vesting not started");
        require(lastClaimTimestamp < vestingEndTime, "vesting ended");

        uint256 timestamp = block.timestamp < vestingEndTime ? block.timestamp : vestingEndTime;
        uint256 period = timestamp - lastClaimTimestamp;
        uint256 teamPending;
        uint256 treasuryPending;
        if (period >= vestingPeriod) {
            teamPending = teamVestingAmount;
            treasuryPending = treasuryVestingAmount;
        } else {
            teamPending = (teamVestingAmount * period) / vestingPeriod;
            treasuryPending = (treasuryVestingAmount * period) / vestingPeriod;
        }

        lastClaimTimestamp = timestamp;

        IBasisAsset(gladshare).mint(team, teamPending);
        IBasisAsset(gladshare).mint(treasury, treasuryPending);

        emit Claimed(teamPending, treasuryPending);
    }
}