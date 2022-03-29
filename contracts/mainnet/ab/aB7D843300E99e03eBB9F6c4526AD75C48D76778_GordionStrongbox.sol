/**
 *Submitted for verification at snowtrace.io on 2022-03-28
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: Games/GordionStrongboxAvaDice_v2.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IAvaGame {
    function houseEdgeCalculator(address player) external view returns (uint houseEdge);
}

interface IERC721_2 is IERC721 {
    function exists(uint tokenId) external returns (bool);

    function reflectToOwners() external payable;
}

contract GordionStrongbox {
    /**
    Events
     */
    event DepositAVAX(address indexed sender, uint256 amount);
    event DepositToken(address indexed sender, uint256 amount);

    modifier onlyOwners() {
        require(isOwner[msg.sender], "0x03");
        _;
    }

    mapping(address => bool) public isOwner;
    mapping(address => bool) public isGame;

    address private nftAddress;
    IERC721_2 public nft;
    mapping(address => uint) userBalance;
    uint public claimableTotal;
    
    uint256 public nftHolderReward = 700;

    address public dev = address(0xe650580Ab0B22C253e13257430b1102dB8C27d1E);
    address public vl = address(0x991c2252B11d28100F0F2fa3cdFB821056D5414d);
    address public cube = address(0x1152Ff6d620aa0ED8EC3C83711E8f2f756E5B8D5);
    address public avadice = address(0x4f63428BD8AAb63bEEd04ef0CC6F49286123d2bF);

    constructor(address _nftAddress) {
        isOwner[msg.sender] = true;
        setNFTAdress(_nftAddress);
    }

    function setNFTAdress(address _nftAddress) public onlyOwners {
        nftAddress = _nftAddress;
        nft = IERC721_2(nftAddress);
    }



    function addGame(address[] calldata _games) external onlyOwners {
        for(uint i = 0; i<_games.length; i++){
            isGame[_games[i]] = true;
        }
    }

    function removeGame(address[] calldata _games) external onlyOwners {
        for(uint i = 0; i<_games.length; i++){
            isGame[_games[i]] = true;
        }
    }

    function setNFTHolderReward(uint _nftHolderReward) external onlyOwners {
        nftHolderReward = _nftHolderReward;
    }

    function addOwner(address[] calldata _owners) external onlyOwners {
        for(uint i = 0; i<_owners.length; i++){
            isOwner[_owners[i]] = true;
        }
    }

    function removeOwner(address[] calldata _owners) external onlyOwners {
        for(uint i = 0; i<_owners.length; i++){
            isOwner[_owners[i]] = false;
        }
    }

    /*--------------PAYMENT MANAGEMENT--------------*/
    function depositAVAX() external payable {
        if(isGame[msg.sender]) {
            IAvaGame game = IAvaGame(msg.sender);
            uint houseEdge = game.houseEdgeCalculator(tx.origin);
            claimableTotal += msg.value * 1000 / (houseEdge + 1000) * houseEdge / 1000;
        }
        emit DepositAVAX(msg.sender, msg.value);
    }

    function addClaimable() external payable {
        claimableTotal += msg.value;
    }

    function executePaymentAVAX(uint256 amount, address _to) external{
        require(isGame[msg.sender] || isOwner[msg.sender]);
        require((address(this).balance - amount) >= claimableTotal);
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "0x08");
    }

    function withdrawAVAX(uint256 amount, address _to) external{
        require(isOwner[msg.sender]);
        (bool sent, ) = _to.call{value: amount}("");
        require(sent, "0x08");
    }

    function splitDividend() external onlyOwners {
        require(address(this).balance > claimableTotal);

        uint claimableNFTReward = claimableTotal * nftHolderReward / 10000;
        nft.reflectToOwners{value: claimableNFTReward}();
        uint teamShare = (claimableTotal - claimableNFTReward) / 4;
        payable(dev).transfer(teamShare);
        payable(vl).transfer(teamShare);
        payable(cube).transfer(teamShare);
        payable(avadice).transfer(teamShare);
        claimableTotal = 0;
    }
}