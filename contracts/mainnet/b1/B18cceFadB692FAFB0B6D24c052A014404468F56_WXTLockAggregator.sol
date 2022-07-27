// SPDX-License-Identifier: agpl-3.0

    pragma solidity 0.6.12;

    import "../interfaces/IWXTLock.sol";
    import "../interfaces/IWXTLockAggregator.sol";
    import {Ownable} from '../dependencies/openzeppelin/contracts/Ownable.sol';

    contract WXTLockAggregator is IWXTLockAggregator, Ownable {

        address[] public supportedContracts;

        function getSupportedContracts() public view override returns(address[] memory){
            return supportedContracts;
        }

        function lockedBalance(address user) public view override returns (uint256) {
            uint256 totalUserBalance;
            for (uint256 i = 0; i < supportedContracts.length; i++) {
                IWXTLock wxtLockContract = IWXTLock(supportedContracts[i]);
                totalUserBalance += wxtLockContract.lockedBalance(user);
            }
            return totalUserBalance;
        }

        function addSupportedContract(address lockContract) public override onlyOwner {
            for (uint256 i = 0; i < supportedContracts.length; i++) {
                require(supportedContracts[i] != lockContract, "Already have this address");
            }
            supportedContracts.push(lockContract);
            emit AddedSupportedContract(lockContract);
        }

        function removeSupportedContract(address lockContract) public override onlyOwner {
            for (uint256 i = 0; i < supportedContracts.length; i++) {
                if (supportedContracts[i] == lockContract) {
                    supportedContracts[i] = supportedContracts[supportedContracts.length - 1];
                    supportedContracts.pop();
                    break;
                }else if(i == supportedContracts.length - 1){
                    revert("No such address");
                }
            }
            emit RemovedSupportedContract(lockContract);
        }
    }

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import {IAaveIncentivesController} from './IAaveIncentivesController.sol';

interface IWXTLock {

    struct LockedBalance {
        uint256 amount;
        uint256 unlockTime;
    }
    /**
     * @dev Emitted after the mint action
   * @param from The address performing the mint
   * @param value The amount being
   **/
    event Mint(address indexed from, uint256 value);

    /**
     * @dev Emitted after the stake action
   * @param from The address performing the lock
   * @param value The amount being locked
   **/
    event Locked(address indexed from, uint256 value, uint256 unlockTime);

    /**
     * @dev Emitted after the unstake action
   * @param from The address performing the unlock
   * @param value The amount being unlocked
   **/
    event Unlocked(address indexed from, uint256 value);

    /**
     * @dev Emitted after aTokens are burned
   * @param from The owner of the aTokens, getting them burned
   * @param target The address that will receive the underlying
   * @param value The amount being burned
   **/
    event Burn(address indexed from, address indexed target, uint256 value);

    /**
     * @dev Locks `amount` of tokens for msg.sender
   * @param amount The amount of tokens getting minted
   */
    function lock(
        uint256 amount
    ) external;

    /**
     * @dev Burns aTokens from `msg.sender` and sends the equivalent amount of underlying to `him`
   * @param amount Amount of tokens that will be unlocked
   **/
    function unLock(
        uint256 amount
    ) external;

    /**
    * @dev Function to check amount of the locked tokens
   * @param user The address of user to check
   * @return returns total locked amount
   **/
    function lockedBalance(address user) view external returns (uint256);

    /**
    * @dev Function to check amount of the withdrawable tokens
   * @param user The address of user to check
   * @return returns total withdrawable amount
   **/
    function withdrawableBalance(address user) view external returns (uint256);

    /**
     * @dev Returns the address of the incentives controller contract
   **/
    function getIncentivesController() external view returns (IAaveIncentivesController);

    /**
     * @dev Returns the address of the underlying asset of this aToken (E.g. WETH for aWETH)
   **/
    function UNDERLYING_ASSET_ADDRESS() external view returns (address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

interface IWXTLockAggregator {
    function lockedBalance(address user) external view returns (uint256);
    function addSupportedContract(address lockContract) external;
    function removeSupportedContract(address lockContract) external;
    function getSupportedContracts() external view returns (address[] memory);

    event AddedSupportedContract(address lockContract);
    event RemovedSupportedContract(address lockContract);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import './Context.sol';

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
contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() internal {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function owner() public view returns (address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(_owner == _msgSender(), 'Ownable: caller is not the owner');
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IAaveIncentivesController {
  event RewardsAccrued(address indexed user, uint256 amount);

  event RewardsClaimed(address indexed user, address indexed to, uint256 amount);

  event RewardsClaimed(
    address indexed user,
    address indexed to,
    address indexed claimer,
    uint256 amount
  );

  event ClaimerSet(address indexed user, address indexed claimer);

  /*
   * @dev Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index, the emission per second and the last updated timestamp
   **/
  function getAssetData(address asset)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    );

  /*
   * LEGACY **************************
   * @dev Returns the configuration of the distribution for a certain asset
   * @param asset The address of the reference asset of the distribution
   * @return The asset index, the emission per second and the last updated timestamp
   **/
  function assets(address asset)
    external
    view
    returns (
      uint128,
      uint128,
      uint256
    );

  /**
   * @dev Whitelists an address to claim the rewards on behalf of another address
   * @param user The address of the user
   * @param claimer The address of the claimer
   */
  function setClaimer(address user, address claimer) external;

  /**
   * @dev Returns the whitelisted claimer for a certain address (0x0 if not set)
   * @param user The address of the user
   * @return The claimer address
   */
  function getClaimer(address user) external view returns (address);

  /**
   * @dev Configure assets for a certain rewards emission
   * @param assets The assets to incentivize
   * @param emissionsPerSecond The emission for each asset
   */
  function configureAssets(address[] calldata assets, uint256[] calldata emissionsPerSecond)
    external;

  /**
   * @dev Called by the corresponding asset on any update that affects the rewards distribution
   * @param asset The address of the user
   * @param userBalance The balance of the user of the asset in the lending pool
   * @param totalSupply The total supply of the asset in the lending pool
   **/
  function handleAction(
    address asset,
    uint256 userBalance,
    uint256 totalSupply
  ) external;

  /**
   * @dev Returns the total of rewards of an user, already accrued + not yet accrued
   * @param user The address of the user
   * @return The rewards
   **/
  function getRewardsBalance(address[] calldata assets, address user)
    external
    view
    returns (uint256);

  /**
   * @dev Claims reward for an user, on all the assets of the lending pool, accumulating the pending rewards
   * @param amount Amount of rewards to claim
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to
  ) external returns (uint256);

  /**
   * @dev Claims reward for an user on behalf, on all the assets of the lending pool, accumulating the pending rewards. The caller must
   * be whitelisted via "allowClaimOnBehalf" function by the RewardsAdmin role manager
   * @param amount Amount of rewards to claim
   * @param user Address to check and claim rewards
   * @param to Address that will be receiving the rewards
   * @return Rewards claimed
   **/
  function claimRewardsOnBehalf(
    address[] calldata assets,
    uint256 amount,
    address user,
    address to
  ) external returns (uint256);

  /**
   * @dev returns the unclaimed rewards of the user
   * @param user the address of the user
   * @return the unclaimed user rewards
   */
  function getUserUnclaimedRewards(address user) external view returns (uint256);

  /**
   * @dev returns the unclaimed rewards of the user
   * @param user the address of the user
   * @param asset The asset to incentivize
   * @return the user index for the asset
   */
  function getUserAssetData(address user, address asset) external view returns (uint256);

  /**
   * @dev for backward compatibility with previous implementation of the Incentives controller
   */
  function REWARD_TOKEN() external view returns (address);

  /**
   * @dev for backward compatibility with previous implementation of the Incentives controller
   */
  function PRECISION() external view returns (uint8);

  /**
   * @dev Gets the distribution end timestamp of the emissions
   */
  function DISTRIBUTION_END() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return msg.sender;
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}