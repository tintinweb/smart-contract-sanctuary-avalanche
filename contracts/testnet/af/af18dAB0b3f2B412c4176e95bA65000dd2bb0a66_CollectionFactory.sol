// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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

// SPDX-License-Identifier: GPL-3.0
// Finentic Contracts (last updated v1.0)

pragma solidity ^0.8.0;

interface IControlCenter {
    function onlyOperator(address account) external view;

    function onlyTreasurer(address account) external view;

    function onlyModerator(address account) external view;

    /*
    //////////////////////
      WHITELIST FUNTIONS  
    //////////////////////
    */

    function whitelisting(address account) external view returns (bool);

    function onlyWhitelisted(address account) external view;

    function addToWhitelist(address account) external;

    function removeFromWhitelist(address account) external;

    function addMultiToWhitelist(address[] calldata accounts) external;

    function removeMultiFromWhitelist(address[] calldata accounts) external;

    /*
    //////////////////////
      BLACKLIST FUNTIONS  
    //////////////////////
    */

    function blacklisting(address account) external view returns (bool);

    function notInBlacklisted(address account) external view;

    function addToBlacklist(address account) external;

    function removeFromBlacklist(address account) external;

    function addMultiToBlacklist(address[] calldata accounts) external;

    function removeMultiFromBlacklist(address[] calldata accounts) external;
}

// SPDX-License-Identifier: GPL-3.0
// Finentic Contracts (last updated v1.0)

pragma solidity 0.8.13;

/**
 * @title Finentic Collection NFT (FC-NFT) is a collection of NFTs by a single creator.
 * @notice All NFTs from this contract are minted by the same creator.
 * @dev A Collection NFT is the implementation template used byall collection contracts created with the Collection Factory.
 */

interface ICollection {
    function initialize(
        address _creator,
        string calldata _name,
        string calldata _symbol,
        string calldata _newBaseURI
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
// Finentic Contracts (last updated v1.0)

pragma solidity 0.8.13;

import "@openzeppelin/contracts/security/Pausable.sol";
import "../interfaces/access/IControlCenter.sol";
import "../interfaces/nft/ICollection.sol";

/**
 * @title A factory to create NFT collections.
 * @notice Call this factory to create NFT collections.
 * @dev This creates and initializes an ERC-1167 minimal proxy pointing to an NFT collection contract implementation.
 */

contract CollectionFactory is Pausable {
    IControlCenter public immutable controlCenter;
    address public immutable collectionImplementation;

    /**
     * @notice Emitted when a new Collection is created from this factory.
     * @param collection The address of the new NFT collection contract.
     * @param creator The address of the creator which owns the new collection.
     * @param name The name of the collection contract created.
     * @param symbol The symbol of the collection contract created.
     */
    event CollectionCreated(
        address indexed collection,
        address indexed creator,
        string name,
        string symbol
    );

    constructor(
        IControlCenter _controlCenter,
        address _collectionImplementation
    ) {
        controlCenter = _controlCenter;
        collectionImplementation = _collectionImplementation;
    }

    /**
     * @notice Create a new collection contract.
     * @param name The collection's `name`.
     * @param symbol The collection's `symbol`.
     * @param baseURI The base URI for the collection.
     * @return collection The address of the newly created collection contract.
     */
    function createCollection(
        address creator,
        string calldata name,
        string calldata symbol,
        string calldata baseURI
    ) external whenNotPaused returns (address collection) {
        require(bytes(symbol).length != 0, "CollectionFactory: EMPTY_SYMBOL");

        // taken from https://solidity-by-example.org/app/minimal-proxy/
        bytes20 targetBytes = bytes20(collectionImplementation);
        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            collection := create(0, clone, 0x37)
        }
        ICollection(collection).initialize(creator, name, symbol, baseURI);

        emit CollectionCreated(collection, creator, name, symbol);
    }

    function pause() external {
        controlCenter.onlyModerator(_msgSender());
        _pause();
    }

    function unpause() external {
        controlCenter.onlyModerator(_msgSender());
        _unpause();
    }
}