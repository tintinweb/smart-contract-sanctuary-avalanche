// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Affiliate is Pausable, Ownable {
    address private _owner;
    mapping(address => bool) private adminAddressList;

    constructor() {
        adminAddressList[0xCeaf7780c54bc6815A8d5c3E10fdc965d0F26762] = true;
        adminAddressList[0x9CB52e780db0Ce66B2c4d8193C3986B5E7114336] = true;
        adminAddressList[0xbDe951E26aae4F39e20628724f58293A4E6457D4] = true;
        adminAddressList[0xD797d3510e5074891546797f2Ab9105bd0e41bC3] = true;
        adminAddressList[msg.sender] = true;
        _owner = msg.sender;
    }

    struct AffiliateUser {
        address wallet;
        string code;
        uint discount;
        uint payback;
        bool isActive;
    }

    // code => struct
    mapping(string => AffiliateUser) private affiliateUsers;

    modifier onlyAdmin() {
        require(adminAddressList[msg.sender], "NFKey: caller is not admin");
        _;
    }

    function deactivateAffiliate(string memory affiliation_code) public onlyAdmin() {
        affiliateUsers[affiliation_code].isActive = false;
    }

    function deactivateAffiliates(string[] memory affilation_codes) public onlyAdmin() {
        for (uint i = 0; i < affilation_codes.length; i++) {
            deactivateAffiliate(affilation_codes[i]);
        }
    }

    function activateAffiliate(string memory affiliation_code) public onlyAdmin() {
        affiliateUsers[affiliation_code].isActive = true;
    }

    function getAffiliateDiscount(string memory affilation_code) public view returns(uint256 discount) {
        return affiliateUsers[affilation_code].discount;
    }

    function isActiveAffiliate(string memory affilation_code) public view returns(bool status) {
        return affiliateUsers[affilation_code].isActive;
    }

    function getAffiliatePayback(string memory affilation_code) public view returns(uint256 payback) {
        return affiliateUsers[affilation_code].payback;
    }

    function addAffiliations(AffiliateUser[] memory newAffiliations) public onlyAdmin() {
        for (uint i = 0; i < newAffiliations.length; i++) {
               affiliateUsers[newAffiliations[i].code] = newAffiliations[i];
        }
    }

    function changeAffiliateDiscount (string memory affilation_code, uint newDiscount) public onlyAdmin() {
        require(newDiscount > 0 && newDiscount < 100, "NFKey: wrong discount value");
        affiliateUsers[affilation_code].discount = newDiscount;
    }

    function changeAffiliatePayback (string memory affilation_code, uint newPayback) public onlyAdmin() {
        require(newPayback > 0 && newPayback < 100, "NFKey: wrong payback value");
        affiliateUsers[affilation_code].payback = newPayback;
    }

    function getAffilationWalletByCode(string memory affilation_code) public view returns(address affiliate_wallet) {
        return affiliateUsers[affilation_code].wallet;
    }

    function destroySmartContract(address payable _to) public onlyOwner {
        selfdestruct(_to);
    }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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