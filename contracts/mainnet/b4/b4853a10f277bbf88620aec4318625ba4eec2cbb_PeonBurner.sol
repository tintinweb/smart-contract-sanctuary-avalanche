// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {Ownable2Step} from "openzeppelin/access/Ownable2Step.sol";
import {Pausable} from "openzeppelin/security/Pausable.sol";

import {IPeonToken} from "./interfaces/IPeonToken.sol";
import {IPeonBurner} from "./interfaces/IPeonBurner.sol";

/**
 * @title PeonBurner
 * @dev Contract used to burn Peon V1 and mint Peon Tokens
 */
contract PeonBurner is Ownable2Step, Pausable, IPeonBurner {
    //* Public variables */
    /**
     * @dev PeonToken contract
     */
    IPeonToken public immutable peonToken;

    /**
     * @dev Peon V1 contract
     */
    IERC721 public immutable peonsV1;

    /**
     * @dev Upgrade start time
     */
    uint256 public immutable upgradeStartTime;

    //* Private variables */
    /**
     * @dev Address where the burned tokens are sent
     */
    address private constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    /**
     * @dev price for upgrading a single token
     */
    uint256 private constant PRICE_SINGLE = 1.5 ether;

    /**
     * @dev price for upgrading a bundle of 5 tokens
     */
    uint256 private constant PRICE_BUNDLE = 5 ether;

    /**
     * @dev time, when the upgrade price is reduced
     */
    uint256 private constant DISCOUNTED_UPGRADE_PERIOD = 7 days;

    /**
     * @dev period after upgrade start time when dev minting is allowed
     */
    uint256 private constant DEV_MINT_DELAY = 180 days;

    /**
     * @dev mapping used to prevent double minting by owner
     */
    mapping(uint256 => bool) peonUsedToMintByOwner;

    /**
     * @dev Packed data about Peon V1 Types
     * Every byte stores data about 4 Peons
     */
    bytes private constant _peonv1Types =
        "\x00\x04\x00\x40\x10\x00\x00\x14\x00\x00\x00\x00\x10\x04\x00\x00\x10\x00\x00\x10\x00\x00\x10\x00\x00\x41\x00\x40\x00\x04\x00\x00\x00\x00\x40\x00\x00\x00\x00\x04\x54\x00\x01\x00\x40\x00\x01\x01\x00\x00\x00\x00\x00\x01\x60\x00\x00\x10\x04\x01\x00\x00\x04\x51\x00\x00\x01\x00\x50\x00\x14\x00\x00\x00\x10\x10\x00\x40\x00\x40\x00\x00\x00\x00\x01\x10\x01\x00\x00\x00\x05\x00\x00\x00\x44\x01\x40\x00\x40\x10\x04\x40\x00\x00\x00\x10\x00\x40\x04\x00\x11\x04\x00\x80\x40\x00\x15\x10\x00\x00\x10\x40\x00\x00\x00\x00\x40\x00\x00\x00\x01\x00\x10\x00\x00\x00\x00\x00\x44\x15\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x01\x01\x40\x00\x00\x10\x00\x00\x00\x40\x10\x04\x40\x40\x00\x01\x50\x00\x00\x01\x00\x00\x04\x00\x00\x00\x00\x04\x00\x04\x00\x00\x00\x10\x00\x00\x10\x00\x00\x00\x05\x01\x10\x10\x00\x00\x40\x05\x00\x00\x80\x01\x00\x10\x00\x00\x00\x00\x04\x00\x00\x50\x00\x14\x00\x01\x04\x00\x00\x00\x40\x50\x01\x45\x00\x00\x00\x40\x00\x04\x04\x00\x10\x10\x00\x00\x40\x00\x00\x00\x00\x40\x40\x00\x01\x00\x00\x00\x00\x00\x00\x05\x10\x40\x00\x00\x00\x00\x04\x00\x40\x00\x00\x41\x00\x14\x00\x00\x00\x10\x04\x40\x10\x04\x00\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x00\x00\x10\x00\x41\x00\x40\x00\x00\x40\x01\x10\x00\x00\x00\x44\x00\x40\x40\x00\x00\x00\x44\x00\x40\x00\x00\x00\x00\x00\x04\x00\x00\x00\x40\x10\x01\x00\x04\x40\x01\x04\x00\x10\x01\x00\x04\x00\x04\x00\x00\x10\x01\x00\x14\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x14\x08\x00\x05\x00\x00\x00\x00\x00\x05\x00\x00\x00\x00\x00\x00\x10\x00\x00\x40\x00\x00\x00\x00\x00\x41\x00\x00\x01\x40\x00\x00\x00\x00\x00\x40\x00\x04\x40\x44\x00\x00\x00\x00\x00\x00\x00\x40\x00\x05\x14\x00\x04\x00\x00\x00\x00\x04\x40\x10\x41\x04\x00\x40\x00\x00\x00\x40\x00\x00\x00\x04\x00\x00\x00\x00\x00\x00\x00\x00\x04\x01\x00\x00\x00\x01\x00\x10\x00\x00\x10\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x04\x00\x40\x04\x00\x00\x00\x00\x15\x00\x10\x40\x40\x00\x00\x00\x00\x40\x04\x00\x10\x00\x00\x01\x00\x00\x00\x00\x00\x40\x00\x00\x40\x00\x00\x00\x10\x00\x00\x40\x00\x01\x01\x00\x10\x14\x00\x00\x10\x00\x40\x00\x00\x00\x00\x01\x00\x00\x00\x40\x00\x01\x00\x11\x00\x01\x00\x10\x00\x00\x10\x01\x00\x00\x00\x00\x00\x00\x00\x05\x00\x40\x00\x00\x10\x00\x01\x00\x40\x00\x00\x41\x00\x00\x04\x00\x00\x00\x01\x00\x00\x00\x00\x10\x00\x00\x00\x04\x40\x00\x10\x04\x01\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x00\x01\x00\x00\x10\x00\x11\x04\x00\x00\x00\x04\x00\x00\x00\x01\x14\x00\x00\x10\x04\x01\x00\x00\x41\x00\x00\x10\x01\x00\x04\x04\x40\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x01\x00\x40\x00\x00\x00\x00\x40\x00\x00\x10\x00\x01\x01\x00\x40\x00\x00\x00\x41\x00\x10\x10\x00\x00\x05\x40\x04\x00\x00\x04\x01\x00\x04\x00\x00\x44\x04\x01\x00\x00\x00\x00\x40\x04\x40\x40\x00\x10\x01\x04\x00\x10\x01\x00\x04\x00\x00\x05\x00\x04\x00\x40\x00\x04\x00\x00\x51\x10\x00\x00\x00\x00\x00\x40\x00\x01\x00\x00\x00\x00\x00\x00\x00\x04\x00\x40\x00\x00\x01\x10\x10\x10\x40\x00\x00\x40\x00\x00\x00\x00\x00\x00\x00\x01\x11\x00\x00\x04\x00\x00\x00\x10\x00\x40\x00\x00\x00\x10\x00\x40\x40\x00\x00\x00\x00\x10\x00\x01\x10\x01\x00\x40\x01\x00\x00\x00\x04\x05\x00\x00\x00\x00\x40\x00\x00\x10\x00\x04\x14\x00\x00\x01\x01\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x80\x00\x00\x05\x40\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x01\x10\x00\x00\x01\x10\x04\x00\x40\x00\x00\x00\x00\x01\x00\x00\x00\x00\x40\x00\x08\x00\x00\x00\x00\x41\x00\x00\x00\x01\x40\x00\x10\x04\x00\x00\x41\x10\x00\x01\x54\x10\x00\x44\x00\x00\x00\x00\x00\x01\x00\x04\x04\x00\x00\x01\x00\x00\x00\x00\x01\x20\x00\x00\x00\x00\x04\x00\x01\x40\x00\x04\x44\x00\x00\x11\x00\x40\x40\x00\x44\x10\x04\x40\x40\x01\x00\x40\x01\x01\x40\x00\x00\x40\x00\x00\x00\x01\x10\x04\x01\x00\x40\x04\x00\x50\x00\x04\x01\x04\x05\x00\x10\x00\x00\x00\x00\x40\x14\x00\x00\x04\x00\x00\x00\x00\x00\x01\x40\x00\x04\x10\x10\x14\x00\x00\x01\x00\x00\x00\x00\x10\x10\x00\x41\x00\x00\x10\x11\x40\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x10\x00\x00\x00\x00\x04\x00\x00\x00\x04\x00\x00\x10\x00\x00\x00\x00\x04\x40\x10\x11\x04\x04\x00\x00\x00\x00\x40\x00\x00\x00\x00\x00\x00\x01\x01\x04\x00\x00\x00\x00\x00\x00\x00\x00\x10\x04\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x10\x00\x10\x01\x00\x10\x11\x00\x10\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x40\x40\x00\x00\x00\x00\x00\x00\x04\x00\x00\x40\x10\x00\x00\x11\x00\x41\x00\x00\x00\x00\x10\x00\x00\x10\x01\x00\x04\x01\x00\x00\x04\x00\x00\x00\x00\x00\x00\x05\x00\x40\x01\x40\x00\x00\x10\x00\x00\x00\x40\x01\x00\x04\x41\x01\x00\x00\x01\x00\x44\x04\x00\x11\x44\x10\x00\x00\x00\x40\x00\x01\x00\x01\x00\x40\x00\x01\x40\x01\x00\x00\x00\x00\x00\x10\x00\x10\x00\x00\x00\x04\x00\x04\x40\x01\x01\x00\x01\x00\x00\x00\x04\x00\x10\x10\x10\x00\x00\x00\x00\x00\x00\x04\x00\x00\x00\x00\x00\x04\x00\x00\x11\x00\x00\x00\x00\x00\x00\x04\x00\x00\x01\x41\x00\x04\x00\x10\x00\x40\x00\x14\x00\x10\x01\x54\x00\x00\x00\x00\x10\x00\x10\x50\x50\x40\x00\x00\x10\x01\x00";

    //* Modifiers */

    /**
     * Checks if upgrade is allowed
     */
    modifier isUpgradeAllowed() {
        if (block.timestamp < upgradeStartTime) {
            revert PeonBurner__UpgradePeriodNotStarted();
        }
        _;
    }

    //* Constructor */

    /**
     * @notice Constructor
     * @param _peonToken The address of the PeonToken contract
     * @param _peonsV1 The address of the PeonsV1 contract
     * @param _upgradeStartTime The time when the upgrade starts
     */
    constructor(address _peonToken, address _peonsV1, uint256 _upgradeStartTime) {
        if (_peonToken == address(0) || _peonsV1 == address(0)) {
            revert PeonBurner__ZeroAddress();
        }
        if (_upgradeStartTime == 0) {
            revert PeonBurner__InvalidUpgradeTime();
        }
        peonToken = IPeonToken(_peonToken);
        peonsV1 = IERC721(_peonsV1);
        upgradeStartTime = _upgradeStartTime;
    }

    //* External functions */

    /**
     * @notice Mints a PeonToken
     * @param peonv1TokenId The PeonV1 token ID to burn
     */
    function mintPeonToken(uint256 peonv1TokenId) external payable whenNotPaused isUpgradeAllowed {
        _checkPricePaid(1);
        PeonTokenType peonTokenType = _checkPeonType(peonv1TokenId);
        _verifyOwnership(peonv1TokenId);
        _checkIfNotDevMinted(peonv1TokenId);
        _burnPeonV1(peonv1TokenId);
        _mintPeonToken(peonTokenType, 1);
    }

    /**
     * @notice Mints multiple PeonTokens
     * @param peonv1TokenIds The PeonV1 token IDs to burn
     */
    function mintManyPeonTokens(uint256[] calldata peonv1TokenIds) external payable whenNotPaused isUpgradeAllowed {
        uint256 amount = peonv1TokenIds.length;
        _checkPricePaid(amount);

        (uint256 amountRegular, uint256 amountGolden, uint256 amountDiamond) = _getTokenTypesAmounts(peonv1TokenIds);

        for (uint256 i = 0; i < amount; i++) {
            _checkIfNotDevMinted(peonv1TokenIds[i]);
            _verifyOwnership(peonv1TokenIds[i]);
            _burnPeonV1(peonv1TokenIds[i]);
        }

        if (amountRegular > 0) {
            _mintPeonToken(PeonTokenType.REGULAR, amountRegular);
        }
        if (amountGolden > 0) {
            _mintPeonToken(PeonTokenType.GOLDEN, amountGolden);
        }
        if (amountDiamond > 0) {
            _mintPeonToken(PeonTokenType.DIAMOND, amountDiamond);
        }
    }

    //* External onlyOwner functions */

    /**
     * @notice Withdraws AVAX from the contract
     * @param to The address to withdraw to
     * @param amount The amount to withdraw
     */
    function withdrawAvax(address to, uint256 amount) external onlyOwner {
        if (amount == 0) {
            amount = address(this).balance;
        }

        (bool success,) = to.call{value: amount}("");
        if (!success) {
            revert PeonBurner__TransferFailed();
        }

        emit AvaxWithdrawn(to, amount);
    }

    /**
     * @notice Allows contract owner to mint remaining Peon Tokens after burning is finished
     * @dev Allows to mint only the same type of tokens in single function call
     * @param peonv1TokenIds Peons V1 to use
     */
    function devMint(uint256[] calldata peonv1TokenIds) external onlyOwner {
        if (block.timestamp < upgradeStartTime + DEV_MINT_DELAY) revert PeonBurner__DevMintNotYetAllowed();
        uint256 amount = peonv1TokenIds.length;
        address peonV1Owner;
        PeonTokenType firstPeonTokenType = _checkPeonType(peonv1TokenIds[0]);
        for (uint256 i = 0; i < amount; i++) {
            if (firstPeonTokenType != _checkPeonType(peonv1TokenIds[i])) {
                revert PeonBurner__DifferentTokenTypes();
            }
            peonV1Owner = peonsV1.ownerOf(peonv1TokenIds[i]);
            if (peonUsedToMintByOwner[peonv1TokenIds[i]] || peonV1Owner == BURN_ADDRESS || peonV1Owner == address(0)) {
                revert PeonBurner__TokenAlreadyUsed();
            }
            peonUsedToMintByOwner[peonv1TokenIds[i]] = true;
        }
        _mintPeonToken(firstPeonTokenType, amount);
    }

    /**
     * @notice Pause the contract. This will pause Peon burning
     * @dev Can only be called when the contract is not paused
     * @dev Can only be called by the owner
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice unpause the contract. This will unpause Peon burning
     * @dev Can only be called when the contract is paused
     * @dev Can only be called by the owner
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    //* Internal view functions */

    /**
     * @dev Verify that the correct amount of AVAX was paid
     * @param amount The amount of token of this type to upgrade
     */
    function _checkPricePaid(uint256 amount) internal view {
        uint256 price = (amount % 5) * PRICE_SINGLE + (amount / 5) * PRICE_BUNDLE;
        if (block.timestamp < upgradeStartTime + DISCOUNTED_UPGRADE_PERIOD) {
            price = price / 2;
        }
        if (msg.value != price) {
            revert PeonBurner__WrongPricePaid();
        }
    }

    //* Internal functions */

    /**
     * @notice Check PeonTokenType for given Peon V1 ID
     * @param peonv1TokenId PeonToken ID to check
     * @return peonTokenType PeonTokenType
     */
    function _checkPeonType(uint256 peonv1TokenId) public pure returns (PeonTokenType peonTokenType) {
        if (peonv1TokenId >= 5000) {
            revert PeonBurner__WrongToken();
        }
        uint256 bytePos = peonv1TokenId / 4;
        uint256 bitPos = (peonv1TokenId % 4);
        uint8 byteValue = uint8(_peonv1Types[bytePos]);
        peonTokenType = PeonTokenType((byteValue >> (2 * bitPos)) & 0x03);

        return peonTokenType;
    }

    /**
     * @dev Verify that the caller owns the token that is meant to be burnt
     * @param tokenId The token ID to check ownership for
     */
    function _verifyOwnership(uint256 tokenId) internal view {
        if (peonsV1.ownerOf(tokenId) != msg.sender) {
            revert PeonBurner__TokenOwnershipRequired();
        }
    }

    /**
     * @dev Burns a PeonV1 by sending it to `address(dead)`
     * @param tokenId The token ID of PeonV1 to burn
     */
    function _burnPeonV1(uint256 tokenId) internal {
        peonsV1.transferFrom(msg.sender, BURN_ADDRESS, tokenId);
    }

    /**
     * @dev Checks if the token has not been used to mint PeonToken yet
     * @param tokenId The token ID to check
     */
    function _checkIfNotDevMinted(uint256 tokenId) internal {
        if (peonUsedToMintByOwner[tokenId]) {
            revert PeonBurner__TokenAlreadyUsed();
        }
    }

    function _getTokenTypesAmounts(uint256[] calldata _peonv1TokenIds)
        internal
        returns (uint256 amountRegular, uint256 amountGolden, uint256 amountDiamond)
    {
        uint256 amount = _peonv1TokenIds.length;
        PeonTokenType peonTokenType;

        for (uint256 i = 0; i < amount; i++) {
            peonTokenType = _checkPeonType(_peonv1TokenIds[i]);
            if (peonTokenType == PeonTokenType.REGULAR) {
                amountRegular++;
            } else if (peonTokenType == PeonTokenType.GOLDEN) {
                amountGolden++;
            } else if (peonTokenType == PeonTokenType.DIAMOND) {
                amountDiamond++;
            }
        }
    }
    //* Private functions */

    /**
     * @dev Mints a PeonToken
     * @param peonTokenType The type of PeonToken to mint
     * @param amount The amount of tokens to mint
     */
    function _mintPeonToken(PeonTokenType peonTokenType, uint256 amount) private {
        if (peonTokenType == PeonTokenType.DIAMOND) {
            peonToken.mintDiamond(msg.sender, amount);
        } else if (peonTokenType == PeonTokenType.GOLDEN) {
            peonToken.mintGolden(msg.sender, amount);
        } else if (peonTokenType == PeonTokenType.REGULAR) {
            peonToken.mintRegular(msg.sender, amount);
        } else {
            revert PeonBurner__WrongToken();
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() external {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

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
pragma solidity ^0.8.0;

import {IOperatorFilterRegistry} from "operator-filter-registry/src/IOperatorFilterRegistry.sol";
import {IERC721Upgradeable} from "openzeppelin-upgradeable/interfaces/IERC721Upgradeable.sol";

interface IPeonToken is IERC721Upgradeable {
    error PeonToken__InvalidRoyaltyInfo();
    error PeonToken__ZeroAddress();
    error PeonToken__InvalidTokenId();
    error PeonToken__CanNotMintThisMany();
    error PeonToken__OnlyPeonBurner();
    error OperatorNotAllowed(address operator);

    enum PeonTokenType {
        REGULAR,
        GOLDEN,
        DIAMOND
    }

    /**
     * @dev Emitted on setRoyaltyInfo()
     * @param receiver Royalty fee collector
     * @param feePercent Royalty fee percent in basis point
     */
    event DefaultRoyaltySet(address indexed receiver, uint256 feePercent);

    /**
     * @dev Emitted on updateOperatorFilterRegistryAddress()
     * @param operatorFilterRegistry New operator filter registry
     */
    event OperatorFilterRegistryUpdated(IOperatorFilterRegistry indexed operatorFilterRegistry);

    /**
     * @dev Emitted on setPeonBurner()
     * @param peonBurner New peon burner
     */
    event PeonBurnerSet(address peonBurner);

    /**
     * @dev Emitted on setBaseURI()
     * @param baseURI The new base URI
     */
    event BaseURISet(string baseURI);

    function baseURI() external view returns (string memory);

    function collectionSize() external view returns (uint256);

    function maxMintedRegularId() external view returns (uint256);

    function setRoyaltyInfo(address _receiver, uint96 _feePercent) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function totalSupply() external view returns (uint256);

    function updateOperatorFilterRegistryAddress(IOperatorFilterRegistry _newRegistry) external;

    function mintDiamond(address minter, uint256 amount) external;

    function mintGolden(address minter, uint256 amount) external;

    function mintRegular(address minter, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

interface IPeonBurner {
    error PeonBurner__WrongPricePaid();
    error PeonBurner__TokenOwnershipRequired();
    error PeonBurner__TokenAlreadyUsed();
    error PeonBurner__BurnNotInitialized();
    error PeonBurner__UpgradePeriodEnded();
    error PeonBurner__UpgradePeriodNotEnded();
    error PeonBurner__UpgradePeriodNotStarted();
    error PeonBurner__DifferentTokenTypes();
    error PeonBurner__WrongToken();
    error PeonBurner__ZeroAddress();
    error PeonBurner__InvalidUpgradeTime();
    error PeonBurner__TransferFailed();
    error PeonBurner__DevMintNotYetAllowed();

    event AvaxWithdrawn(address indexed to, uint256 amount);

    enum PeonTokenType {
        REGULAR,
        GOLDEN,
        DIAMOND
    }

    function mintPeonToken(uint256 peonv1TokenId) external payable;

    function mintManyPeonTokens(uint256[] calldata peonv1TokenIds) external payable;

    function withdrawAvax(address to, uint256 amount) external;

    function devMint(uint256[] calldata peonv1TokenIds) external;
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    /**
     * @notice Returns true if operator is not filtered for a given token, either by address or codeHash. Also returns
     *         true if supplied registrant address is not registered.
     */
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);

    /**
     * @notice Registers an address with the registry. May be called by address itself or by EIP-173 owner.
     */
    function register(address registrant) external;

    /**
     * @notice Registers an address with the registry and "subscribes" to another address's filtered operators and codeHashes.
     */
    function registerAndSubscribe(address registrant, address subscription) external;

    /**
     * @notice Registers an address with the registry and copies the filtered operators and codeHashes from another
     *         address without subscribing.
     */
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;

    /**
     * @notice Unregisters an address with the registry and removes its subscription. May be called by address itself or by EIP-173 owner.
     *         Note that this does not remove any filtered addresses or codeHashes.
     *         Also note that any subscriptions to this registrant will still be active and follow the existing filtered addresses and codehashes.
     */
    function unregister(address addr) external;

    /**
     * @notice Update an operator address for a registered address - when filtered is true, the operator is filtered.
     */
    function updateOperator(address registrant, address operator, bool filtered) external;

    /**
     * @notice Update multiple operators for a registered address - when filtered is true, the operators will be filtered. Reverts on duplicates.
     */
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;

    /**
     * @notice Update a codeHash for a registered address - when filtered is true, the codeHash is filtered.
     */
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;

    /**
     * @notice Update multiple codeHashes for a registered address - when filtered is true, the codeHashes will be filtered. Reverts on duplicates.
     */
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;

    /**
     * @notice Subscribe an address to another registrant's filtered operators and codeHashes. Will remove previous
     *         subscription if present.
     *         Note that accounts with subscriptions may go on to subscribe to other accounts - in this case,
     *         subscriptions will not be forwarded. Instead the former subscription's existing entries will still be
     *         used.
     */
    function subscribe(address registrant, address registrantToSubscribe) external;

    /**
     * @notice Unsubscribe an address from its current subscribed registrant, and optionally copy its filtered operators and codeHashes.
     */
    function unsubscribe(address registrant, bool copyExistingEntries) external;

    /**
     * @notice Get the subscription address of a given registrant, if any.
     */
    function subscriptionOf(address addr) external returns (address registrant);

    /**
     * @notice Get the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscribers(address registrant) external returns (address[] memory);

    /**
     * @notice Get the subscriber at a given index in the set of addresses subscribed to a given registrant.
     *         Note that order is not guaranteed as updates are made.
     */
    function subscriberAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Copy filtered operators and codeHashes from a different registrantToCopy to addr.
     */
    function copyEntriesOf(address registrant, address registrantToCopy) external;

    /**
     * @notice Returns true if operator is filtered by a given address or its subscription.
     */
    function isOperatorFiltered(address registrant, address operator) external returns (bool);

    /**
     * @notice Returns true if the hash of an address's code is filtered by a given address or its subscription.
     */
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);

    /**
     * @notice Returns true if a codeHash is filtered by a given address or its subscription.
     */
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);

    /**
     * @notice Returns a list of filtered operators for a given address or its subscription.
     */
    function filteredOperators(address addr) external returns (address[] memory);

    /**
     * @notice Returns the set of filtered codeHashes for a given address or its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);

    /**
     * @notice Returns the filtered operator at the given index of the set of filtered operators for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);

    /**
     * @notice Returns the filtered codeHash at the given index of the list of filtered codeHashes for a given address or
     *         its subscription.
     *         Note that order is not guaranteed as updates are made.
     */
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);

    /**
     * @notice Returns true if an address has registered
     */
    function isRegistered(address addr) external returns (bool);

    /**
     * @dev Convenience method to compute the code hash of an arbitrary contract
     */
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
interface IERC165Upgradeable {
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