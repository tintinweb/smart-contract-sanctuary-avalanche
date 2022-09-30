// SPDX-License-Identifier: MIT

import "../Interfaces/IveYETI.sol";
import "../Interfaces/IERC20.sol";
import "../Dependencies/OwnableUpgradeable_8.sol";
import "../Interfaces/ICollateralGate.sol";

pragma solidity 0.8.13;


interface ITroveManager {
    function getCurrentTroveState(address _borrower) external view returns (address[] memory, uint[] memory, uint);
}

/**
 * @notice Collateral Gate is used for collaterals that have gated access.
 * Gated Collaterals can require that veYETI be burned when entering them and
 * can also require that Yeti be locked up for the duration of holding the asset.
 * Lock should be called by gated collateral tokens when they are transferred to a new user
 * And unlock should be called when a user who holds the asset gets rid of it.
 * This contract acts as a rewarder for veYETI, so it holds some amount of YETI and veYETI delegated to it 
 * by veYETI itself. It is not an updatable rewarder.
 */
contract CollateralGate is OwnableUpgradeable, ICollateralGate {

    uint256 public constant DECIMAL_PRECISION = 1e18;

    struct Gate {
        uint256 yetiLockRate; // YETI per collateral to lock, 1e18
        uint256 veYetiBurnRate; // veYETI per collateral to burn, 1e36
    }

    struct YetiLockData {
        uint256 amount; // Save previous locked YETI amount
        uint256 prevTroveAmount; // Save previous trove amount of collateral
    }

    struct UserData {
        mapping(address => YetiLockData) locks; // collateral address => amount Yeti locked
        uint256 totalLockedYeti;
    }

    mapping (address => Gate) public collateralGates;

    mapping (address => bool) public isGatedCollateral;

    address[] public gatedCollaterals;

    // user address => collateral address => lock data
    mapping (address => UserData) public users;

    // Yeti addresses
    IveYETI public veYETI;
    ITroveManager troveManager;
    address AP;
    address CSP;
    address DP;
    address SP;
    address BOps;
    bool private addressSet;

    modifier onlyGatedCollateral() {
        require(isGatedCollateral[msg.sender], "Caller is not a valid gated collateral");
        _;
    }


    // ============= OnlyOwner External Mutable Functions =============


    function setAddresses(IveYETI _veYETI, ITroveManager _troveManager, address _AP, address _CSP, address _DP, address _SP, address _BOps) external {
        require(addressSet == false, "Addresses already set");
        addressSet = true;
        _transferOwnership(msg.sender);
        veYETI = _veYETI;
        troveManager = _troveManager;
        AP = _AP;
        CSP = _CSP;
        DP = _DP;
        SP = _SP;
        BOps = _BOps;
    }

    /** 
     * @notice Sets a new gate for a particular collateral. 
     * @param _collateral address to create a new gate on
     * @param _yetiLockRate amount of YETI to lock per amount of collateral
     * @param _veYetiBurnRate amount of veYETI (1e36) to lock per amount of collateral
     */
    function setNewGate(address _collateral, uint256 _yetiLockRate, uint256 _veYetiBurnRate) external onlyOwner {
        if (!isGatedCollateral[_collateral]) {
            isGatedCollateral[_collateral] = true;
            gatedCollaterals.push(_collateral);
        }

        collateralGates[_collateral] = Gate(_yetiLockRate, _veYetiBurnRate);
    }


    // ============= OnlyCollateral External Mutable Functions =============


    /**
     * @notice Locks up Yeti based on saved gates and burns veYETI. 
     *  If transferring between pools in the Yeti protocol, then ignore this lock. 
     *  If the origin is SP or CSP, then also ignore since this won't incur new locks
     *  If the origin is AP, and the user is the one who sent it originally to close or adjust their
     *  trove, the lock should be retained. 
     *  If the origin is DP, the only possible recipient is AP, but the check is added for redundancy. 
     *  Update veYETI contract with necessary information after internal logic. 
     * @param _userAddress user to lock for
     * @param _collateralAmount amount of collateral to lock for
     * @param _origin The original sender from the gated collateral
     */
    function lock(address _userAddress, uint _collateralAmount, address _origin) external onlyGatedCollateral {
        // Check user address here for protocol addresses. If it is a protocol address that holds
        // tokens like AP, CSP, DP, and SP, then don't lock. 
        if (_userAddress == AP || _userAddress == CSP || _userAddress == DP || _userAddress == SP) {
            return;
        }

        // If origin is from SP, then let it go through since it is sending it to a depositor who has gains
        // and should not require the lock. Same with origin of CSP, where this means it is a user who 
        // had extra collateral from being redeemed and we don't need to enforce the lock. The amount is too
        // unpredictable to keep track of easily, as well as users can't force this action through themselves
        // either. If origin is DP the only action is to send collateral to the active pool, which shouldn't be
        // tracked. 
        if (_origin == SP || _origin == CSP || _origin == DP) {
            return;
        }

        address collateralAddress = msg.sender;
        UserData storage user = users[_userAddress];

        // If origin is AP, then it could be one of many actions. The only one where we want to enforce the lock
        // is if the intended action is to close or adjust your trove and therefore withdraw. Here, we can check
        // the prevTroveAmount to see if the new lock amount is equal to the new difference in the trove amount. 
        // If so, then we can let it go through. Otherwise, this should be ignoredd as it is some other action 
        // which we should ignore. 
        if (_origin == AP) {
            uint256 prevTroveAmount = user.locks[collateralAddress].prevTroveAmount;
            uint256 currentTroveAmount;
            (address[] memory colls, uint256[] memory amounts, ) = troveManager.getCurrentTroveState(_userAddress);
            for (uint i; i < colls.length; ++i) {
                if (colls[i] == collateralAddress) {
                    currentTroveAmount = amounts[i];
                    break;
                }
            }
            if (currentTroveAmount >= prevTroveAmount) {
                return;
            }
            uint256 troveAmountDiff = prevTroveAmount - currentTroveAmount;
            // Not equal, meaning the change is not some sort of withdrawal from closeTrove or adjustTrove
            if (_collateralAmount != troveAmountDiff) {
                return;
            }
        }

        _updateUserLockedYeti(_userAddress);

        uint256 yetiLockRate = collateralGates[collateralAddress].yetiLockRate;
        uint256 veYetiBurnRate = collateralGates[collateralAddress].veYetiBurnRate;

        uint256 yetiLock = _collateralAmount * yetiLockRate / DECIMAL_PRECISION;
        uint256 veYETIBurn = _collateralAmount * veYetiBurnRate / DECIMAL_PRECISION;

        user.locks[collateralAddress].amount += yetiLock;
        user.totalLockedYeti += yetiLock;

        // will revert if user has insufficient veYETI to burn or insufficient Yeti locked
        veYETI.lockBurnFromCollateralGate(_userAddress, veYETIBurn, user.totalLockedYeti);
    }


    /** 
     * @notice Unlocks the tokens for the user. If the origin is BOps, then ignore it. 
     *   Does some logic to make sure that the amount of YETI we mark as unlocked does 
     *   not underflow to. Updates the correct actual collateral address. Notify veYETI
     *   that there has been a change in lock amount, which changes the veYETI split in 
     *   that contract
     * @param _userAddress The user to unlock for
     * @param _collateralAmount The amount of the collateral
     * @param _origin The sender of the original call from the gated token. 
     */
    function unlock(address _userAddress, uint _collateralAmount, address _origin) external onlyGatedCollateral {
        // If sent from BOps, then that means it is an open trove call, which should not unlock the collateral.
        if (_origin == BOps) {
            return;
        }

        address collateralAddress = msg.sender;
        UserData storage user = users[_userAddress];

        uint256 yetiLockRate = collateralGates[collateralAddress].yetiLockRate;
        uint256 yetiUnlock = _collateralAmount * yetiLockRate / DECIMAL_PRECISION;

        if (user.locks[collateralAddress].amount > yetiUnlock) {
            user.totalLockedYeti -= yetiUnlock;
            user.locks[collateralAddress].amount -= yetiUnlock;
        } else {
            user.totalLockedYeti -= user.locks[collateralAddress].amount;
            user.locks[collateralAddress].amount = 0;
        }
        veYETI.unlockFromCollateralGate(_userAddress, user.totalLockedYeti);
    }


    // ============= Public View Functions =============

    /**
     * @notice Check locked Yeti from trove balances + wallet balances, confirmed with the minimums stored 
     *    earlier in the previous locks, based on potentially changing rates. 
     * @param _userAddress the user to check on
     * @return lockedYetiAmount the amount of locked yeti for this user
     */
    function getUserLockedYeti(address _userAddress) external view override returns (uint256) {
        uint256 requiredLockedYeti;
        UserData storage user = users[_userAddress];

        (address[] memory colls, uint256[] memory amounts, ) = troveManager.getCurrentTroveState(_userAddress);

        // add in locked Yeti from trove balance:
        for (uint256 i = 0; i < colls.length; ++i) {
            if (isGatedCollateral[colls[i]]) {
                requiredLockedYeti += collateralGates[colls[i]].yetiLockRate * amounts[i] / DECIMAL_PRECISION;
            }
        }

        // add in locked Yeti from wallet balance:
        for (uint256 i = 0; i < gatedCollaterals.length; ++i) {
            IERC20 collateral = IERC20(gatedCollaterals[i]);
            requiredLockedYeti += collateralGates[gatedCollaterals[i]].yetiLockRate * collateral.balanceOf(_userAddress) / DECIMAL_PRECISION;
        }

        // Take min of the user's locked yeti previously recorded, and the calculated locked yeti at the time of them 
        // performing the lock. If the rate has decreased, then the amount of YETI they are required to keep locked 
        // will decrease, but if the rate has increased, then they are not affected since they had used a previous lock. 
        return _min(requiredLockedYeti, user.totalLockedYeti);
    }


    // ============= Public Mutable Functions =============


    /**
     * @notice Check locked Yeti from trove balances + wallet balances, confirmed with the minimums stored 
     *    earlier in the previous locks, based on potentially changing rates. 
     *    Updates the locked YETI and stores it fot future use. Stores the prevTroveAmount as well
     * @param _userAddress the user to check on
     * @return lockedYetiAmount the amount of locked yeti for this user
     */
    function updateUserLockedYeti(address _userAddress) external override returns (uint256) {
        require(msg.sender == address(veYETI), "Only update locked YETI from veYETI");
        return _updateUserLockedYeti(_userAddress);
    }

    function _updateUserLockedYeti(address _userAddress) internal returns (uint256) {
        uint256 requiredLockedYeti;
        UserData storage user = users[_userAddress];

        (address[] memory colls, uint256[] memory amounts, ) = troveManager.getCurrentTroveState(_userAddress);

        // add in locked Yeti from trove balance, as well as save it as the prevTroveAmount
        for (uint256 i = 0; i < colls.length; ++i) {
            if (isGatedCollateral[colls[i]]) {
                user.locks[colls[i]].prevTroveAmount = amounts[i];
                requiredLockedYeti += collateralGates[colls[i]].yetiLockRate * amounts[i] / DECIMAL_PRECISION;
            }
        }

        // add in locked Yeti from wallet balance:
        for (uint256 i = 0; i < gatedCollaterals.length; ++i) {
            IERC20 collateral = IERC20(gatedCollaterals[i]);
            requiredLockedYeti += collateralGates[gatedCollaterals[i]].yetiLockRate * collateral.balanceOf(_userAddress) / DECIMAL_PRECISION;
        }

        // Take min of the user's locked yeti previously recorded, and the calculated locked yeti at the time of them 
        // performing the lock. If the rate has decreased, then the amount of YETI they are required to keep locked 
        // will decrease, but if the rate has increased, then they are not affected since they had used a previous lock. 
        uint256 computedMinLockedYeti = _min(requiredLockedYeti, user.totalLockedYeti);
        users[_userAddress].totalLockedYeti = computedMinLockedYeti;
        return computedMinLockedYeti;
    }


    // ============= Internal View Functions =============


    function _min(uint256 a, uint256 b) pure internal returns (uint256) {
        if (a > b) {
            return b;
        }
        return a;
    }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;


interface IveYETI {
    struct RewarderUpdate {
        address rewarder;
        uint256 amount;
        bool isIncrease;
    }

    function setup(address _yeti, address _yetiController, uint256 _accumulationRate) external;
    function setEmitter(address _emitter) external;
    function updateWhitelistedCallers(address _contractAddress, bool _isWhitelisted) external;

    function addUpdateableRewarder(address _rewarder) external;
    function removeUpdateableRewarder(uint _index) external;
    function getUpdateableRewarders() external returns (address[] memory);

    function notifyAllRewarders() external;
    function notifyRewarders(address[] memory rewarders) external;

    function update(RewarderUpdate[] memory _yetiAdjustments) external;
    function lockBurnFromCollateralGate(address _user, uint _veYETIBurn, uint256 _newYetiLock) external;
    function unlockFromCollateralGate(address _user, uint256 _newYetiLock) external;

    function getVeYetiOnRewarder(address _user, address _rewarder) external view returns (uint256);
    function getUserYetiOnRewarder(address _user, address _rewarder) external view returns (uint256);
    function getAccumulationRate() external view returns (uint256);
    function totalYeti() external view returns (uint256);
    function getTotalVeYeti(address _user) external view returns (uint256);
    function getTotalYeti(address _user) external view returns (uint256);
    function burnVeYeti(address _user, uint256 _veYetiBurn) external;

}

// SPDX-License-Identifier: MIT

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8;


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
abstract contract OwnableUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(owner() == msg.sender, "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT


interface ICollateralGate {

    // ============= Mutable Functions =============

    function lock(address _user, uint _collateralAmount, address _origin) external;

    function unlock(address _user, uint _collateralAmount, address _origin) external;

    function updateUserLockedYeti(address _user) external returns (uint256);

    // ============= View Functions =============

    function getUserLockedYeti(address _user) external view returns (uint256);

}