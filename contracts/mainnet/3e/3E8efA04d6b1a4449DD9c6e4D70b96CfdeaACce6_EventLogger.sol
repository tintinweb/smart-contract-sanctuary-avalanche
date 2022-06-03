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

interface IEventLogger {
    function report721(address from, address to, uint256 tokenId) external;
    function report1155(address from, address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external;
    function reportChestOrdered(address buyer, uint256 orderIdx, uint256 amount) external;
    function reportCraftStarted(address account, uint256 craftId) external;
    function reportCraftClaimed(address account, uint256 craftId) external;
    function reportMarketplaceListingCreated(uint256 listingId) external;
    function reportMarketplaceListingClosed(uint256 listingId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "/OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
import "../interfaces/IEventLogger.sol";

contract EventLogger is Ownable, IEventLogger {
    mapping (address => bool) public isReporter;

    event IsReporterChanged(address indexed addr, bool value);
    event Transfer721(address indexed token, address indexed from, address indexed to, uint256 tokenId);
    event Transfer1155(address indexed token, address indexed from, address indexed to, uint256[] tokenIds, uint256[] amounts);
    event ChestOrdered(address indexed chest, address indexed buyer, uint256 orderIdx, uint256 amount);
    event CraftStarted(address indexed token, address indexed account, uint256 craftId);
    event CraftClaimed(address indexed token, address indexed account, uint256 craftId);
    event MarketplaceListingCreated(uint256 indexed listingId);
    event MarketplaceListingClosed(uint256 indexed listingId);

    function setIsReporter(address addr, bool value) external onlyOwner {
        isReporter[addr] = value;
        emit IsReporterChanged(addr, value);
    }

    function report721(address from, address to, uint256 tokenId) external {
        require(isReporter[msg.sender], "not a reporter");
        emit Transfer721(msg.sender, from, to, tokenId);
    }

    function report1155(address from, address to, uint256[] calldata tokenIds, uint256[] calldata amounts) external {
        require(isReporter[msg.sender], "not a reporter");
        emit Transfer1155(msg.sender, from, to, tokenIds, amounts);
    }

    function reportChestOrdered(address buyer, uint256 orderIdx, uint256 amount) external {
        require(isReporter[msg.sender], "not a reporter");
        emit ChestOrdered(msg.sender, buyer, orderIdx, amount);
    }

    function reportCraftStarted(address account, uint256 craftId) external {
        require(isReporter[msg.sender], "not a reporter");
        emit CraftStarted(msg.sender, account, craftId);
    }

    function reportCraftClaimed(address account, uint256 craftId) external {
        require(isReporter[msg.sender], "not a reporter");
        emit CraftClaimed(msg.sender, account, craftId);
    }

    function reportMarketplaceListingCreated(uint256 listingId) external {
        require(isReporter[msg.sender], "not a reporter");
        emit MarketplaceListingCreated(listingId);
    }

    function reportMarketplaceListingClosed(uint256 listingId) external {
        require(isReporter[msg.sender], "not a reporter");
        emit MarketplaceListingClosed(listingId);
    }
}