//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../utils/Bytes32Lib.sol";

/// @title Referral and tiers contract
/// @author EMDX
contract Referral is Ownable {
    using Bytes32Lib for bytes32;

    struct Tier {
        uint256 rebate;
        uint256 discount;
    }

    mapping(uint256 => Tier) public tiers;

    uint256 public nextTiersIndex = 0;

    struct Referrer {
        bytes32 code;
        address[] referreds;
        uint256 tier;
    }

    mapping(address => Referrer) private referralOwners;

    mapping(bytes32 => address) private referralCodeToOwner;

    mapping(address => bytes32) private referredToCode;

    /// @notice Emited when a new tier is created
    event CreateTier(
        uint256 indexed tierIndex,
        uint256 rebate,
        uint256 _discount
    );

    /// @notice Emited when an existing tier is updated
    event UpdateTier(
        uint256 indexed tierIndex,
        uint256 rebate,
        uint256 _discount
    );

    /// @notice Emited when a tier is setted to an address
    event SetTier(address indexed referrer, uint256 tierIndex);

    /// @notice Emited when a new code is created
    event CreateCode(address indexed owner, bytes32 code);

    /// @notice Emited when an address is registered to a referral code
    event Register(address indexed reffered, bytes32 code);

    /// @notice Create a new tier
    /// @param _rebate rebate to referrers
    /// @param _discount discount code to traders
    function createTier(uint256 _rebate, uint256 _discount) external onlyOwner {
        require(_rebate <= 100, "REBATE_MAX_LIMIT");
        require(_discount <= 100, "DISCOUNT_MAX_LIMIT");

        uint256 tierIndex = nextTiersIndex;
        Tier memory tier;

        tier.rebate = _rebate;
        tier.discount = _discount;

        tiers[tierIndex] = tier;

        nextTiersIndex++;

        emit CreateTier(tierIndex, _rebate, _discount);
    }

    /// @notice Update an existing tier
    /// @param _rebate rebate to referrers
    /// @param _discount discount code to traders
    function updateTier(
        uint256 _index,
        uint256 _rebate,
        uint256 _discount
    ) external onlyOwner {
        require(_index < nextTiersIndex, "TIER_NOT_EXIST");

        Tier memory tier = tiers[_index];

        tier.rebate = _rebate;
        tier.discount = _discount;

        tiers[_index] = tier;

        emit UpdateTier(_index, _rebate, _discount);
    }

    /// @notice Set tier to an address
    /// @param _referrer address of a referrer
    /// @param _tierIndex an already created tier
    function setTier(address _referrer, uint256 _tierIndex) external onlyOwner {
        require(_tierIndex < nextTiersIndex, "TIER_NOT_EXIST");

        referralOwners[_referrer].tier = _tierIndex;

        emit SetTier(_referrer, _tierIndex);
    }

    /// @notice Create a referral code
    /// @param _code string as a bytes32 representing the referral code
    function createCode(bytes32 _code) external {
        require(_code != bytes32(0), "CODE_EMPTY");
        require(referralCodeToOwner[_code] == address(0), "CODE_ALREADY_EXIST");

        uint256 codeLength = _code.len();

        require(codeLength <= 10, "CODE_TOO_LARGE");
        require(codeLength >= 3, "CODE_TOO_SHORT");

        referralOwners[msg.sender].code = _code;

        referralCodeToOwner[_code] = msg.sender;

        emit CreateCode(msg.sender, _code);
    }

    /// @notice Register an address to a referral code
    /// @param _code a referral code already created
    function registerToReferralCode(bytes32 _code) external {
        address owner = referralCodeToOwner[_code];

        require(owner != address(0), "CODE_NOT_EXIST");
        require(owner != msg.sender, "CANNOT_USE_OWN_ADDRESS");
        require(referredToCode[msg.sender] == "", "ADDRESS_ALREADY_REGISTERED");

        Referrer storage referrer = referralOwners[owner];

        referrer.referreds.push(msg.sender);

        referredToCode[msg.sender] = _code;

        emit Register(msg.sender, _code);
    }

    /// @notice Get data of a referrer
    /// @param _owner address of the owner
    /// @return code the referral code of the owner
    /// @return referreds an array of the referreds
    /// @return tier tier where the owner belongs
    /// @return rebate rebate percentage
    function getReferrerData(address _owner)
        external
        view
        returns (
            bytes32,
            address[] memory,
            uint256,
            uint256
        )
    {
        Referrer memory referral = referralOwners[_owner];
        Tier memory tier = tiers[referral.tier];

        return (referral.code, referral.referreds, referral.tier, tier.rebate);
    }

    /// @notice Get data of a referred
    /// @param _referred address of the owner
    /// @return code the referral code that the referred belongs
    /// @return tier tier where the owner belongs
    /// @return discount the discount percentage acording to the tier
    function getReferredData(address _referred)
        external
        view
        returns (
            bytes32,
            uint256,
            uint256
        )
    {
        bytes32 code = referredToCode[_referred];
        address owner = referralCodeToOwner[code];
        Referrer memory referral = referralOwners[owner];
        Tier memory tier = tiers[referral.tier];

        return (code, referral.tier, tier.discount);
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

//SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @title Library to handle bytes32
/// @author EMDX
library Bytes32Lib {
    /// @param _string The string in bytes32 you would like to check length
    /// @return Length in uint256 of the string
    function len(bytes32 _string) internal pure returns (uint256) {
        bytes1 empty = bytes1("");

        uint256 nonEmptyLength;

        for (uint256 index = 0; index < _string.length; index++) {
            if (_string[index] != empty) {
                nonEmptyLength++;
            }
        }

        return nonEmptyLength;
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