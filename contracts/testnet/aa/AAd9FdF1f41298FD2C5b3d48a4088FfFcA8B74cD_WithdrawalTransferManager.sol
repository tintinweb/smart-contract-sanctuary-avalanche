// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.13;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

/// @notice Gas optimized reentrancy protection for smart contracts
/// @author Modified from KaliDAO (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    error Reentrancy();

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        //require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');
        if (_status == _ENTERED) revert Reentrancy();

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC165} from "../interfaces/IERC165.sol";

import {ReentrancyGuard} from "../utils/ReentrancyGuard.sol";

/**
 * @title WithdrawalTransferManager
 * @notice It formats the payload needed to approve or executes transfer of an asset for the ForumCrowdfund contract
 */
contract WithdrawalTransferManager is ReentrancyGuard {
    /// ----------------------------------------------------------------------------------------
    /// Withdrawl Storage
    /// ----------------------------------------------------------------------------------------

    error TransferFailed();

    // Token types
    enum TokenType {
        ERC721,
        ERC1155,
        ERC20
    }

    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    /// ----------------------------------------------------------------------------------------
    /// Withdrawl Logic
    /// ----------------------------------------------------------------------------------------

    /**
     * @notice Builds the approval to allow the Withdrawal contract (msg.sender) to transfer the asset
     * @param collection collection address
     * @param amountOrId amount of token if erc20, id of token if erc721 or erc1155
     * @return approvalPayload to allow the withdrawal contract to send tokens
     */
    function buildApprovalPayloads(address collection, uint256 amountOrId)
        external
        view
        returns (bytes memory approvalPayload)
    {
        // Check the type of collection, and build the approve payload accordingly
        TokenType tokenType = determineTokenType(collection);

        if (tokenType == TokenType.ERC721) return abi.encodeWithSelector(
            bytes4(keccak256("approve(address,uint256)")),
            address(this),
            amountOrId
        );

        if (tokenType == TokenType.ERC1155) return abi.encodeWithSelector(
            bytes4(keccak256("setApprovalForAll(address,bool)")),
            address(this),
            true
        );

        // If it is not an ERC721 or ERC1155, then assume it is an ERC20
        return abi.encodeWithSelector(
            bytes4(keccak256("approve(address,uint256)")),
            address(this),
            amountOrId
        );
    }

    /**
     * @notice Executes the transfer of the asset
     * @param collection collection address
     * @param amountOrId amount of token if erc20, id of token if erc721 or erc1155
     * @param to address to send the asset to
     */
    function executeTransferPayloads(
        address collection,
        address from,
        address to,
        uint256 amountOrId
    )
        external
        nonReentrant
    {
        // Check the type of collection, and execute the relevant transfer
        TokenType tokenType = determineTokenType(collection);

        if (tokenType == TokenType.ERC721) {
            (bool success,) = collection.call(
                abi.encodeWithSelector(
                    bytes4(keccak256("safeTransferFrom(address,address,uint256)")),
                    from,
                    to,
                    amountOrId
                )
            );

            if (!success) revert TransferFailed();
            return;
        }

        /// @dev For now only 1 ERC1155 can only be transferred at a time
        if (tokenType == TokenType.ERC1155) {
            (bool success,) = collection.call(
                abi.encodeWithSelector(
                    bytes4(keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")),
                    from,
                    to,
                    amountOrId,
                    1,
                    ""
                )
            );

            if (!success) revert TransferFailed();
            return;
        }

        // If it is not an ERC721 or ERC1155, then assume it is an ERC20
        (bool success,) = collection.call(
            abi.encodeWithSelector(
                bytes4(keccak256("transferFrom(address,address,uint256)")),
                from,
                to,
                amountOrId
            )
        );

        if (!success) revert TransferFailed();
    }

    /**
     * @notice Determines type of token
     * @param collection collection address
     * @dev Defaults to erc20 if the other interfaces do not match.
     *      This is not perfect, but since the user will be selecting an asset which
     *      they want to withdraw from the group, it is very likely that it will be an
     *      erc20 token if neither of the others. If it is not, then the call will fail
     *      and the user will be able to cancel the withdrawal without losing any funds
     */
    function determineTokenType(address collection)
        internal
        view
        returns (TokenType)
    {
        // We static call and handle the response since supportsInterface will fail for contracts not implementing it
        (bool success, bytes memory result) = collection.staticcall(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, INTERFACE_ID_ERC721)
        );

        // If successful and true, then it is an ERC721
        if (success && abi.decode(result, (bool))) {
            return TokenType.ERC721;
        }

        (success, result) = collection.staticcall(
            abi.encodeWithSelector(IERC165.supportsInterface.selector, INTERFACE_ID_ERC1155)
        );

        // If successful and true, then it is an ERC1155
        if (success && abi.decode(result, (bool))) {
            return TokenType.ERC1155;
        }

        // Defaults to ERC20
        return TokenType.ERC20;
    }
}