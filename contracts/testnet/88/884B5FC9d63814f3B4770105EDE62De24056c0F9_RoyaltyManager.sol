// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @author: magni
/// @sample: https://support.opensea.io/hc/en-us/articles/1500009575482-How-do-creator-earnings-work-on-OpenSea-

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IRoyaltyManager.sol";

/**
 * @dev Engine to lookup royalty configurations
 */
contract RoyaltyManager is ERC165, IRoyaltyManager {
    struct Royalty {
        address[] recipients;
        uint256[] feePercents;
    }

    mapping(address => Royalty) private collectionToRoyalty;

    /**
     * @dev See {IRoyaltyManager-hasRoyalty}
     */
    function hasRoyalty(address collectionAddress)
        public
        view
        override
        returns (bool)
    {
        Royalty memory royalty = collectionToRoyalty[collectionAddress];
        return royalty.recipients.length > 0;
    }

    /**
     * @dev See {IRoyaltyManager-getRoyalty}
     */
    function getRoyalty(address collectionAddress, uint256 value)
        public
        view
        override
        returns (address[] memory recipient, uint256[] memory amounts)
    {
        // return (_recipients, _amounts);
        Royalty memory royalty = collectionToRoyalty[collectionAddress];
        require(
            hasRoyalty(collectionAddress),
            "This collection has not any royalty"
        );
        uint256[] memory royaltyValues = new uint256[](
            royalty.recipients.length
        );

        for (uint256 i = 0; i < royalty.recipients.length; i++) {
            royaltyValues[i] = (value * royalty.feePercents[i]) / 100;
        }
        return (royalty.recipients, royaltyValues);
    }

    /**
     * @dev See {IRoyaltyManager-setRoyalty}
     */
    function setRoyalty(
        address collectionAddress,
        address[] memory recipients,
        uint256[] memory feePercents
    ) public override {
        collectionToRoyalty[collectionAddress] = Royalty(
            recipients,
            feePercents
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/// @author: magni

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @dev Lookup engine interface
 */
interface IRoyaltyManager is IERC165 {
    /**
     * Checks if a royalty exists for a given collection (address).
     *
     * @param collectionAddress - The address of the collection
     *
     */
    function hasRoyalty(address collectionAddress) external returns (bool);

    /**
     * Get the royalty for a given collection (address) and value amount.  Does not cache the bps/amounts.  Caches the spec for a given token address
     *
     * @param collectionAddress - The address of the collection
     * @param value        - The value you wish to get the royalty of
     *
     * returns Two arrays of equal length, royalty recipients and the corresponding amount each recipient should get
     */
    function getRoyalty(address collectionAddress, uint256 value)
        external
        returns (address[] memory recipients, uint256[] memory amounts);

    /**
     * Set the royalty for a given collection (address) and value amount.
     *
     * @param collectionAddress - The address of the collection
     * @param recipient    - The address of the recipient
     * @param feePercents          - The fee for recipient to receive
     *
     */
    function setRoyalty(
        address collectionAddress,
        address[] memory recipient,
        uint256[] memory feePercents
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}