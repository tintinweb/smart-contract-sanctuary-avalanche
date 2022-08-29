//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Referral is Ownable {
    struct Tier {
        uint256 rebate; // Percentage of the rebate in USDC. e.g. 10 is 0.1%
        uint256 referral; // Fixed amount of EMDX for each referred.
    }

    mapping(uint256 => Tier) public tiers;

    uint256 public tiersIndex = 0;

    struct Referrer {
        bytes32 code;
        address[] referrers;
        uint256 tier;
    }

    mapping(address => Referrer) public referralOwners;

    mapping(bytes32 => address) public referralCodeToOwner;

    event CreateTier(
        uint256 indexed tierIndex,
        uint256 rebate,
        uint256 referral
    );

    event SetTier(address referrer, uint256 tierIndex);

    event CreateCode(address owner, bytes32 code);

    event Register(address reffered, bytes32 code);

    function createTier(uint256 _rebate, uint256 _referral) public onlyOwner {
        Tier memory tier = Tier(_rebate, _referral);

        tiers[tiersIndex++] = tier;

        emit CreateTier(tiersIndex, _rebate, _referral);
    }

    function setTier(address _referrer, uint256 _tierIndex) public onlyOwner {
        referralOwners[_referrer].tier = _tierIndex;

        emit SetTier(_referrer, _tierIndex);
    }

    function createCode(bytes32 _code) public {
        require(_code != bytes32(0), "Invalid code.");
        require(
            referralCodeToOwner[_code] == address(0),
            "Code already exists."
        );

        referralOwners[msg.sender].code = _code;

        referralCodeToOwner[_code] = msg.sender;

        emit CreateCode(msg.sender, _code);
    }

    function registerToReferralCode(bytes32 _code) public {
        address owner = referralCodeToOwner[_code];

        if (owner == address(0)) {
            revert("Code not exists.");
        }

        Referrer storage referrer = referralOwners[owner];

        for (uint256 index = 0; index < referrer.referrers.length; index++) {
            if (referrer.referrers[index] == msg.sender) {
                revert("Address already registered.");
            }
        }

        referrer.referrers.push(msg.sender);

        referralOwners[msg.sender].code = _code;

        emit Register(msg.sender, _code);
    }

    function getReferrerData(address _owner)
        public
        view
        returns (
            bytes32,
            address[] memory,
            uint256
        )
    {
        Referrer storage referral = referralOwners[_owner];

        return (referral.code, referral.referrers, referral.tier);
    }
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