// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

/**
* @title HiveFiveBee Factory (Honey)
* @author 0xNekr
* @notice Implements ERC20 staking : stake Nectar to get Honey.
*/
contract Factory is Ownable, KeeperCompatibleInterface {

    // @dev Staking structure
    struct Staking {
        uint256 currentStakingBalance;
        uint256 claimableBalance;
        uint256 alreadyWithdrawn;
        uint256 stakingStartTime;
        address owner;
    }

    address private _keeper;

    uint public initialTimestamp;
    uint public totalRewardForFirstMonth = 7500000 ether;
    uint public totalRewardForNextMonths = 356250 ether;
    uint public monthInSeconds = 2628000;

    // @dev mapping to get staking structure by address
    mapping(address => Staking) public stakingByAddress;
    address[] public stakersList;

    uint public immutable interval;
    uint public lastTimeStamp;

    IERC20 public nectar;
    IERC20 public honey;

    event Staked(address indexed owner, uint256 amount);
    event UnStaked(address indexed owner, uint256 amount);
    event Claimed(address indexed owner, uint256 amount);

    /*
    * @notice Associate the addresses of the different tokens at the time of deployment
    */
    constructor(IERC20 _nectar, IERC20 _honey, uint _intervalForRewards, address _ourKeeper) {
        // @dev Chainlink Keepers var init
        interval = _intervalForRewards;
        lastTimeStamp = block.timestamp;
        _keeper = _ourKeeper;

        // @dev Contract var init
        initialTimestamp = block.timestamp;
        nectar = _nectar;
        honey = _honey;
    }

    /*
    * @notice ChainLink function that contains the logic that will be executed off-chain to see if performUpkeep should be executed.
    */
    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    /*
    * @dev Function that will be called when the checkUpkeep return is true
    * @notice This function will distribute rewards to stakeholders on a daily basis
    */
    function performUpkeep(bytes calldata /* performData */) external override {
        // require(msg.sender == _keeper, "You are not the keeper");
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;

            _setDailyRewards();
        }
    }

    /*
    * @notice Function to stake nectar
    * @param uint256 nectarAmount : Amount of nectar the user wants to stake
    */
    function stake(uint256 nectarAmount) external {
        require(nectar.balanceOf(msg.sender) >= nectarAmount, "Not enough Nectar");
        nectar.transferFrom(msg.sender, address(this), nectarAmount);
        emit Staked(msg.sender, nectarAmount);
        if (stakingByAddress[msg.sender].stakingStartTime == 0) {

            stakingByAddress[msg.sender] = Staking({
            currentStakingBalance : nectarAmount,
            claimableBalance : 0,
            alreadyWithdrawn : 0,
            stakingStartTime : uint48(block.timestamp),
            owner : msg.sender
            });

            stakersList.push(msg.sender);
        } else {
            stakingByAddress[msg.sender].currentStakingBalance += nectarAmount;
        }
    }

    /*
    * @notice Set the amount of nectar that can be claimed by user for this day
    */
    function _setDailyRewards() public {
        for (uint i = 0; i < stakersList.length; i++) {
            address currentAddress = stakersList[i];
            uint currentUserBalance = stakingByAddress[currentAddress].currentStakingBalance;
            uint currentContractBalanceOf = nectar.balanceOf(address(this));

            // @dev Define the rewards of the month according to the number of seconds elapsed since the deployment of the contract
            uint rewardForThisMonth;
            if ((block.timestamp - initialTimestamp) < monthInSeconds) {
                rewardForThisMonth = totalRewardForFirstMonth;
            } else {
                rewardForThisMonth = totalRewardForNextMonths;
            }

            // @dev Calcul of reward : reward of month / 30 * user balance / contract balance
            uint reward = rewardForThisMonth / 30 * currentUserBalance / currentContractBalanceOf;

            // @dev Add the user's reward to what they can claim
            stakingByAddress[currentAddress].claimableBalance += reward;
        }
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
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}