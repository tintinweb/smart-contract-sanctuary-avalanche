// SPDX-License-Identifier: MIT AND BSD-3-Clause

pragma solidity ^0.8.13;

import "lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "./interfaces/IPeons.sol";

contract PeonsExplorer {
    IPeons public peons =
        IPeons(0xe6cc79cA731A5e406024015bB2dE5346B52eCA2F);

    function isUnique(address _owner) public view returns (bool) {
        if (peons.balanceOf(_owner) == 0) return false;

        return tokenOfOwnerByIndex(_owner, 0) < 30;
    }

    function isRich(address _owner) public view returns (bool) {
        if (peons.balanceOf(_owner) == 0) return false;

        uint256[] memory tokens = tokensOfOwner(_owner);
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] < 1687 && tokens[i] >= 20) {
                return true;
            }
        }
        return false;
    }

    function isMiddling(address _owner) public view returns (bool) {
        if (peons.balanceOf(_owner) == 0) return false;

        uint256[] memory tokens = tokensOfOwner(_owner);
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] < 3344 && tokens[i] >= 1687 || tokens[i] < 20 && tokens[i] >= 10) {
                return true;
            }
        }
        return false;
    }

    function isPoor(address _owner) public view returns (bool) {
        if (peons.balanceOf(_owner) == 0) return false;

        uint256[] memory tokens = tokensOfOwner(_owner);
        for (uint256 i; i < tokens.length; i++) {
            if (tokens[i] >= 3344 || tokens[i] < 10) {
                return true;
            }
        }
        return false;
    }

    function tokenOfOwnerByIndex(
        address _owner,
        uint256 _index
    ) public view returns (uint256) {
        return tokensOfOwner(_owner)[_index];
    }

    function tokensOfOwner(
        address _owner
    ) public view returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = peons.balanceOf(_owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            address ownership;
            for (uint256 i = 0; tokenIdsIdx != tokenIdsLength; ++i) {
                try peons.ownerOf(i) returns (address _ownership) {
                    ownership = _ownership;
                } catch {
                    continue;
                }

                if (ownership != address(0)) {
                    currOwnershipAddr = ownership;
                }
                if (currOwnershipAddr == _owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;

interface IPeons {
    error NFTBase__InvalidJoeFeeCollector();
    error NFTBase__InvalidPercent();
    error NFTBase__InvalidRoyaltyInfo();
    error NFTBase__NotEnoughAVAX(uint256 amountNeeded);
    error NFTBase__TransferFailed();
    error NFTBase__WithdrawAVAXNotAvailable();
    error OZNFTBaseUpgradeable__InvalidAddress();
    error OperatorNotAllowed(address operator);
    error PendingOwnableUpgradeable__AddressZero();
    error PendingOwnableUpgradeable__NoPendingOwner();
    error PendingOwnableUpgradeable__NotOwner();
    error PendingOwnableUpgradeable__NotPendingOwner();
    error PendingOwnableUpgradeable__PendingOwnerAlreadySet();
    error PeonsV2__InvalidTokenId();
    error PeonsV2__OnlyPeonMinter();
    error PeonsV2__TokenIdOverCollectionSize();
    error PeonsV2__ZeroAddress();
    error SafeAccessControlEnumerableUpgradeable__RoleIsDefaultAdmin();
    error SafeAccessControlEnumerableUpgradeable__SenderMissingRoleAndIsNotOwner(
        bytes32 role,
        address sender
    );
    error SafePausableUpgradeable__AlreadyPaused();
    error SafePausableUpgradeable__AlreadyUnpaused();
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event AvaxWithdraw(address indexed sender, uint256 amount, uint256 fee);
    event BaseURISet(string baseURI);
    event DefaultRoyaltySet(address indexed receiver, uint256 feePercent);
    event DescriptorSet(address indexed descriptor);
    event Initialized(uint8 version);
    event JoeFeeInitialized(uint256 feePercent, address feeCollector);
    event LZEndpointSet(address lzEndpoint);
    event MessageFailed(
        uint16 _srcChainId,
        bytes _srcAddress,
        uint64 _nonce,
        bytes _payload
    );
    event OperatorFilterRegistryUpdated(address indexed operatorFilterRegistry);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Paused(address account);
    event PendingOwnerSet(address indexed pendingOwner);
    event PeonMinterSet(address indexed peonMinter);
    event ReceiveFromChain(
        uint16 indexed _srcChainId,
        bytes indexed _srcAddress,
        address indexed _toAddress,
        uint256 _tokenId,
        uint64 _nonce
    );
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
    event SendToChain(
        address indexed _sender,
        uint16 indexed _dstChainId,
        bytes indexed _toAddress,
        uint256 _tokenId,
        uint64 _nonce
    );
    event SetMinDstGasLookup(
        uint16 _dstChainId,
        uint256 _type,
        uint256 _dstGasAmount
    );
    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);
    event SetUseCustomAdapterParams(bool _useCustomAdapterParams);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event Unpaused(address account);
    event UnrevealedURISet(string unrevealedURI);
    event WithdrawAVAXStartTimeSet(uint256 withdrawAVAXStartTime);

    function DEFAULT_ADMIN_ROLE() external view returns (bytes32);

    function FUNCTION_TYPE_SEND() external view returns (uint256);

    function NO_EXTRA_GAS() external view returns (uint256);

    function approve(address operator, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function baseURI() external view returns (string memory);

    function becomeOwner() external;

    function collectionSize() external view returns (uint256);

    function descriptor() external view returns (address);

    function estimateSendFee(
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _tokenId,
        bool _useZro,
        bytes memory _adapterParams
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    function failedMessages(
        uint16,
        bytes memory,
        uint64
    ) external view returns (bytes32);

    function forceResumeReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress
    ) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address,
        uint256 _configType
    ) external view returns (bytes memory);

    function getGasLimit(
        bytes memory _adapterParams
    ) external pure returns (uint256 gasLimit);

    function getPauserAdminRole() external pure returns (bytes32);

    function getPauserRole() external pure returns (bytes32);

    function getProjectOwnerRole() external pure returns (bytes32);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function getRoleMember(
        bytes32 role,
        uint256 index
    ) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);

    function getUnpauserAdminRole() external pure returns (bytes32);

    function getUnpauserRole() external pure returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function isTrustedRemote(
        uint16 _srcChainId,
        bytes memory _srcAddress
    ) external view returns (bool);

    function joeFeeCollector() external view returns (address);

    function joeFeePercent() external view returns (uint256);

    function lzEndpoint() external view returns (address);

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external;

    function minDstGasLookup(uint16, uint256) external view returns (uint256);

    function mint(address user, uint256 tokenId) external;

    function name() external view returns (string memory);

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external;

    function operatorFilterRegistry() external view returns (address);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function pause() external;

    function paused() external view returns (bool);

    function pendingOwner() external view returns (address);

    function peonMinter() external view returns (address);

    function renounceOwnership() external;

    function renounceRole(bytes32 role, address account) external;

    function retryMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external payable;

    function revokePendingOwner() external;

    function revokeRole(bytes32 role, address account) external;

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) external;

    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes memory _toAddress,
        uint256 _tokenId,
        address _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) external payable;

    function setApprovalForAll(address operator, bool approved) external;

    function setBaseURI(string memory _baseURI) external;

    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes memory _config
    ) external;

    function setDescriptor(address _descriptor) external;

    function setLzEndpoint(address _endpoint) external;

    function setMinDstGasLookup(
        uint16 _dstChainId,
        uint256 _type,
        uint256 _dstGasAmount
    ) external;

    function setOperatorFilterRegistryAddress(
        address newOperatorFilterRegistry
    ) external;

    function setPendingOwner(address pendingOwner_) external;

    function setPeonMinter(address _peonMinter) external;

    function setReceiveVersion(uint16 _version) external;

    function setRoyaltyInfo(address receiver, uint96 feePercent) external;

    function setSendVersion(uint16 _version) external;

    function setTrustedRemote(
        uint16 _srcChainId,
        bytes memory _srcAddress
    ) external;

    function setUnrevealedURI(string memory _unrevealedURI) external;

    function setUseCustomAdapterParams(bool _useCustomAdapterParams) external;

    function setWithdrawAVAXStartTime(
        uint256 newWithdrawAVAXStartTime
    ) external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function trustedRemoteLookup(uint16) external view returns (bytes memory);

    function unpause() external;

    function unrevealedURI() external view returns (string memory);

    function useCustomAdapterParams() external view returns (bool);

    function withdrawAVAX(address to) external;

    function withdrawAVAXStartTime() external view returns (uint256);
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