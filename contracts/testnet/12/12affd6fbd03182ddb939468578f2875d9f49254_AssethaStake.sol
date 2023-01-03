/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol

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

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

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
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

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

pragma solidity ^0.8.0;

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

pragma solidity ^0.8.0;

contract AssethaStake is Ownable {
    IERC721 public AST;
    IERC721 public ASTGEN;

    mapping(address => uint256[]) public stakedAST;
    mapping(address => uint256[]) public stakedASTGEN;
    mapping(address => uint256) public stakedASTAmount;
    mapping(address => uint256) public stakedASTGENAmount;
    mapping(address => uint256) public stakingPoints;
    address[] public stakersAST;
    address[] public stakersASTGEN;

    constructor() {
        AST = IERC721(0x516fEB889A544A6B1076E6d6BD43E4E6e80c0FB3);
        ASTGEN = IERC721(0xe85eef74e39AeB94D70b26F722852f897d3E5833);
    }

    function stakeAST(uint256[] memory _tokenIds) public {
        if (stakedASTAmount[msg.sender] == 0) {
            stakersAST.push(msg.sender);
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            AST.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            stakedASTAmount[msg.sender] = stakedASTAmount[msg.sender] + 1;
            stakedAST[msg.sender].push(_tokenIds[i]);
        }
    }

    function unstakeAST(uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            AST.safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
            stakedASTAmount[msg.sender] = stakedASTAmount[msg.sender] - 1;
            for (uint256 j = 0; j < stakedAST[msg.sender].length; j++) {
                if (_tokenIds[i] == stakedAST[msg.sender][j]) {
                    stakedAST[msg.sender][j] = stakedAST[msg.sender][stakedAST[msg.sender].length - 1];
                    stakedAST[msg.sender].pop();
                }
            }
        }
        if (stakedASTAmount[msg.sender] == 0) {
            for (uint256 x = 0; x < stakersAST.length; x++) {
                if (stakersAST[x] == msg.sender) {
                    stakersAST[x] = stakersAST[stakersAST.length - 1];
                    stakersAST.pop();
                }
            }            
        }
    }

    function stakeASTGEN(uint256[] memory _tokenIds) public {
        if (stakedASTGENAmount[msg.sender] == 0) {
            stakersASTGEN.push(msg.sender);
        }
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ASTGEN.safeTransferFrom(msg.sender, address(this), _tokenIds[i]);
            stakedASTGENAmount[msg.sender] = stakedASTGENAmount[msg.sender] + 1;
            stakedASTGEN[msg.sender].push(_tokenIds[i]);
        }
    }

    function unstakeASTGEN(uint256[] memory _tokenIds) public {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            ASTGEN.safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
            stakedASTGENAmount[msg.sender] = stakedASTGENAmount[msg.sender] - 1;
            for (uint256 j = 0; j < stakedASTGEN[msg.sender].length; j++) {
                if (_tokenIds[i] == stakedASTGEN[msg.sender][j]) {
                    stakedASTGEN[msg.sender][j] = stakedASTGEN[msg.sender][stakedASTGEN[msg.sender].length - 1];
                    stakedASTGEN[msg.sender].pop();
                }
            }
        }
        if (stakedASTGENAmount[msg.sender] == 0) {
            for (uint256 x = 0; x < stakersASTGEN.length; x++) {
                if (stakersASTGEN[x] == msg.sender) {
                    stakersASTGEN[x] = stakersASTGEN[stakersASTGEN.length - 1];
                    stakersASTGEN.pop();
                }
            }            
        }
    }

    function distributeStakingPoints() public {
        require (msg.sender == owner() || msg.sender == 0xf85c366E8ea902B6558E0518503093e2f5f37D5A);
        for (uint256 i = 0; i < stakersAST.length; i++) {
            stakingPoints[stakersAST[i]] = stakingPoints[stakersAST[i]] + stakedASTAmount[stakersAST[i]];
        }
        for (uint256 i = 0; i < stakersASTGEN.length; i++) {
            stakingPoints[stakersASTGEN[i]] = stakingPoints[stakersASTGEN[i]] + (stakedASTGENAmount[stakersASTGEN[i]]) * 3;
        }
    }

    function setPointsOfAddress(address _address, uint256 _points) public onlyOwner() {
        stakingPoints[_address] = _points;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external returns(bytes4) {
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    } 
}