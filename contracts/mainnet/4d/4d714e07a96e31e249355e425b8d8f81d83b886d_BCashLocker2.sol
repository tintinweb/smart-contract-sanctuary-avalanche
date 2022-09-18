/**
 *Submitted for verification at snowtrace.io on 2022-09-18
*/

// SPDX-License-Identifier: MIT
// Butterfly Cash Locker by moonbags (mostly) & xrpant (smol)


// File: @openzeppelin/contracts/security/ReentrancyGuard.sol
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;

interface IBCash {
  function transfer(address to, uint256 amount) external returns (bool);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract BCashLocker2 is ReentrancyGuard {
    uint256 _releaseAmount = 500000 * 10**18; // 50k bCASH

    mapping(address => TimeLock) public addressToLocker;
    mapping(address => bool) private _accountLocked;
    address[] _lockedAccounts;

    uint256 private _totalAmountLocked;

    struct TimeLock {
        uint256 startingBalance;
        uint256 firstUnlock;
        uint256 claimedAmount;
    }

    event BCashLocked(address indexed holder, uint256 amount);
    event BCashReleased(address indexed holder, uint256 amount);

    IBCash _bc;

    constructor(address bcashAddress) {
        _bc = IBCash(bcashAddress);
    }

    function lock(uint256 _amount) public nonReentrant {

        // allow for simple input instead of wei
        uint256 weiAmount = _amount * 10**18;

        require(!_accountLocked[msg.sender], "You are already locking.");
        require(_bc.transferFrom(msg.sender, address(this), weiAmount));

        TimeLock memory _locker;

        _locker.startingBalance = weiAmount;

        _locker.firstUnlock = block.timestamp + 52 weeks;

        addressToLocker[msg.sender] = _locker;
        _lockedAccounts.push(msg.sender);
        _accountLocked[msg.sender] = true;

        _totalAmountLocked += weiAmount;

        emit BCashLocked(msg.sender, _amount);
    }

    function amountLockedFor(address _holder) public view returns (uint256) {
        return addressToLocker[_holder].startingBalance - addressToLocker[_holder].claimedAmount;
    }

    function totalAmountLocked() public view returns (uint256) {
        return _totalAmountLocked;
    }

    function totalAccountsLocked() public view returns (uint256) {
        return _lockedAccounts.length;
    }

    function timeUntilNextClaimFor(address _holder) public view returns (uint256) {
        TimeLock memory _locker = addressToLocker[_holder];
        if (_locker.firstUnlock > block.timestamp) {
            return _locker.firstUnlock - block.timestamp;
        } else {
            uint256 releasesSoFar = _locker.claimedAmount / _releaseAmount;
            uint256 nextRelease = (releasesSoFar * 4 weeks) + _locker.firstUnlock;

            if (nextRelease > block.timestamp) {
                return nextRelease - block.timestamp;
            } else {
                // this state occurs when someone has not claimed rewards yet, but is elligible.
                return 0;
            }
        }
    }

    function claim() public nonReentrant {
        uint256 _claimable = amountClaimableFor(msg.sender);
        require(_claimable > 0, "Nothing to claim!");

        TimeLock storage _locker = addressToLocker[msg.sender];

        // increment claimed amount
        _locker.claimedAmount += _claimable;
        // transfer claimable
        _bc.transfer(msg.sender, _claimable);

        // claimable should never be gt amount locked, but just in case, prevent less than 0 errors
        if (_totalAmountLocked > _claimable) {
            _totalAmountLocked -= _claimable;
        } else {
            _totalAmountLocked = 0;
        }

        if (amountLockedFor(msg.sender) == 0) {
            remove(msg.sender);
            _accountLocked[msg.sender] = false;
        }

        emit BCashReleased(msg.sender, _claimable);
    }

    function remove(address account) private {
        uint256 index;

        for (uint256 i = 0; i < _lockedAccounts.length; i++) {
            if (account == _lockedAccounts[i]) {
                index = i;
            }
        }

        for(uint256 i = index; i < (_lockedAccounts.length - 1); i++) {
            _lockedAccounts[i] = _lockedAccounts[i + 1];
        }

        _lockedAccounts.pop();
    }

    function lockedAccounts() public view returns (address[] memory) {
        return _lockedAccounts;
    }

    function amountClaimableFor(address _holder) public view returns(uint256) {
        TimeLock memory _locker = addressToLocker[_holder];
        uint256 _balance = _locker.startingBalance - _locker.claimedAmount;

        if (_balance == 0 || _locker.firstUnlock > block.timestamp) {
            return 0;
        } else {
            // first, get the time that's passed since first unlock
            // second, divide that by 4 weeks
            // last, add 1 to account for the first unlock
            uint256 unlockPeriodsCompleted = ((block.timestamp - _locker.firstUnlock) / 4 weeks) + 1;
            uint256 totalUnlocked = unlockPeriodsCompleted * _releaseAmount;
            uint256 maxClaimable = totalUnlocked - _locker.claimedAmount;

            // return max claimable or balance, whichever is greater
            if (_balance > maxClaimable) {
                return maxClaimable;
            } else {
                return _balance;
            }
        }
    }

}