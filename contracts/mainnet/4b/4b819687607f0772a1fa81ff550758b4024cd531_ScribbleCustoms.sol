/**
 *Submitted for verification at snowtrace.io on 2022-11-20
*/

// File: contracts/ScribbleCustomCards.sol


// Created by The Spot on Avax (thespot.art)

pragma solidity 0.8.11;

library Strings {
	function toString(uint256 value) internal pure returns(string memory) {
		if (value == 0) return "0";

		uint256 temp = value;
		uint256 digits;

		while (temp != 0) {
			digits++;
			temp /= 10;
		}

		bytes memory buffer = new bytes(digits);

		while (value != 0) {
			digits -= 1;
			buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
			value /= 10;
		}

		return string(buffer);
	}
}

library Address {
	function isContract(address account) internal view returns(bool) {
		return account.code.length > 0;
	}
}

library Counters {
	struct Counter {
		uint256 _value;
	}


	function current(Counter storage counter) internal view returns(uint256) {
		return counter._value;
	}

	function increment(Counter storage counter) internal {
		unchecked {
			counter._value += 1;
		}
	}

	function decrement(Counter storage counter) internal {
		uint256 value = counter._value;
		require(value > 0, "Counter: decrement overflow");

		unchecked {
			counter._value = value - 1;
		}
	}

	function reset(Counter storage counter) internal {
		counter._value = 0;
	}
}

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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

pragma solidity ^0.8.0;

abstract contract ReentrancyGuard {
	uint256 private constant _NOT_ENTERED = 1;
	uint256 private constant _ENTERED = 2;

	uint256 private _status;

	constructor() {
		_status = _NOT_ENTERED;
	}


	modifier nonReentrant() {
		require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

		_status = _ENTERED;

		_;

		_status = _NOT_ENTERED;
	}
}

abstract contract ERC165 is IERC165 {
	function supportsInterface(bytes4 interfaceID) public view virtual override returns(bool) {
		return interfaceID == type(IERC165).interfaceId;
	}
}

interface IERC721Metadata is IERC721 {
	function name() external view returns(string memory);

	function symbol() external view returns(string memory);

	function tokenURI(uint256 tokenID) external view returns(string memory);
}

pragma solidity ^0.8.0;

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
	using Address for address;
	using Strings for uint256;

	string private _name;
	string private _symbol;

	mapping(uint256 => address) private _owners;
	mapping(address => uint256) private _balances;
	mapping(uint256 => address) private _tokenApprovals;
	mapping(address => mapping(address => bool)) private _operatorApprovals;

	constructor(string memory name_, string memory symbol_) {
		_name = name_;
		_symbol = symbol_;
	}

	function supportsInterface(bytes4 interfaceID) public view virtual override(ERC165, IERC165) returns(bool) {
		return interfaceID == type(IERC721).interfaceId || interfaceID == type(IERC721Metadata).interfaceId || super.supportsInterface(interfaceID);
	}

	function balanceOf(address owner) public view virtual override returns(uint256) {
		require(owner != address(0), "ERC721: balance query for the zero address");

		return _balances[owner];
	}

	function ownerOf(uint256 tokenId) public view virtual override returns(address) {
		address owner = _owners[tokenId];

		require(owner != address(0), "ERC721: owner query for nonexistent token");

		return owner;
	}

	function name() public view virtual override returns(string memory) {
		return _name;
	}

	function symbol() public view virtual override returns(string memory) {
		return _symbol;
	}

	function tokenURI(uint256 tokenID) public view virtual override returns(string memory) {
		require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

		string memory baseURI = _baseURI();

		return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenID.toString())) : "";
	}

	function _baseURI() internal view virtual returns(string memory) {
		return "";
	}

	function approve(address to, uint256 tokenID) public virtual override {
		address owner = ERC721.ownerOf(tokenID);
		require(to != owner, "ERC721: approval to current owner");

		require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), "ERC721: approve caller is not owner nor approved for all");

		_approve(to, tokenID);
	}

	function getApproved(uint256 tokenID) public view virtual override returns(address) {
		require(_exists(tokenID), "ERC721: approved query for nonexistent token");

		return _tokenApprovals[tokenID];
	}

	function setApprovalForAll(address operator, bool approved) public virtual override {
		_setApprovalForAll(_msgSender(), operator, approved);
	}

	function isApprovedForAll(address owner, address operator) public view virtual override returns(bool) {
		return _operatorApprovals[owner][operator];
	}

	function transferFrom(address from, address to, uint256 tokenID) public virtual override {
		//solhint-disable-next-line max-line-length
		require(_isApprovedOrOwner(_msgSender(), tokenID), "ERC721: transfer caller is not owner nor approved");

		_transfer(from, to, tokenID);
	}

	function safeTransferFrom(address from, address to, uint256 tokenID) public virtual override {
		safeTransferFrom(from, to, tokenID, "");
	}

	function safeTransferFrom(address from, address to, uint256 tokenID, bytes memory _data) public virtual override {
		require(_isApprovedOrOwner(_msgSender(), tokenID), "ERC721: transfer caller is not owner nor approved");

		_safeTransfer(from, to, tokenID, _data);
	}

	function _safeTransfer(address from, address to, uint256 tokenID, bytes memory _data) internal virtual {
		_transfer(from, to, tokenID);

		require(_checkOnERC721Received(from, to, tokenID, _data), "ERC721: transfer to non ERC721Receiver implementer");
	}

	function _exists(uint256 tokenID) internal view virtual returns(bool) {
		return _owners[tokenID] != address(0);
	}

	function _isApprovedOrOwner(address spender, uint256 tokenID) internal view virtual returns(bool) {
		require(_exists(tokenID), "ERC721: operator query for nonexistent token");

		address owner = ERC721.ownerOf(tokenID);

		return (spender == owner || getApproved(tokenID) == spender || isApprovedForAll(owner, spender));
	}

	function _safeMint(address to, uint256 tokenID) internal virtual {
		_safeMint(to, tokenID, "");
	}

	function _safeMint(address to, uint256 tokenID, bytes memory _data) internal virtual {
		_mint(to, tokenID);

		require(_checkOnERC721Received(address(0), to, tokenID, _data), "ERC721: transfer to non ERC721Receiver implementer");
	}

	function _mint(address to, uint256 tokenID) internal virtual {
		require(to != address(0), "ERC721: mint to the zero address");
		require(!_exists(tokenID), "ERC721: token already minted");

		_beforeTokenTransfer(address(0), to, tokenID);

		_balances[to] += 1;
		_owners[tokenID] = to;

		emit Transfer(address(0), to, tokenID);

		_afterTokenTransfer(address(0), to, tokenID);
	}

	function _burn(uint256 tokenID) internal virtual {
		address owner = ERC721.ownerOf(tokenID);

		_beforeTokenTransfer(owner, address(0), tokenID);
		_approve(address(0), tokenID);

		_balances[owner] -= 1;
		delete _owners[tokenID];

		emit Transfer(owner, address(0), tokenID);

		_afterTokenTransfer(owner, address(0), tokenID);
	}

	function _transfer(address from, address to, uint256 tokenID) internal virtual {
		require(ERC721.ownerOf(tokenID) == from, "ERC721: transfer from incorrect owner");
		require(to != address(0), "ERC721: transfer to the zero address");

		_beforeTokenTransfer(from, to, tokenID);
		_approve(address(0), tokenID);

		_balances[from] -= 1;
		_balances[to] += 1;
		_owners[tokenID] = to;

		emit Transfer(from, to, tokenID);

		_afterTokenTransfer(from, to, tokenID);
	}

	function _approve(address to, uint256 tokenID) internal virtual {
		_tokenApprovals[tokenID] = to;

		emit Approval(ERC721.ownerOf(tokenID), to, tokenID);
	}

	function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
		require(owner != operator, "ERC721: approve to caller");

		_operatorApprovals[owner][operator] = approved;

		emit ApprovalForAll(owner, operator, approved);
	}

	function _checkOnERC721Received(address from, address to, uint256 tokenID, bytes memory _data) private returns(bool) {
		if (to.isContract()) {
			try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenID, _data) returns(bytes4 retval) {
				return retval == IERC721Receiver.onERC721Received.selector;
			} catch (bytes memory reason) {
				if (reason.length == 0) revert("ERC721: transfer to non ERC721Receiver implementer");

				else {
					assembly {
						revert(add(32, reason), mload(reason))
					}
				}
			}
		}

		else return true;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenID) internal virtual {}

	function _afterTokenTransfer(address from, address to, uint256 tokenID) internal virtual {}
}

interface IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }


    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }


    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

//Scribble Warlock Custom Cards by The Spot on Avax

contract ScribbleCustoms is ERC721URIStorage, IERC721Receiver, ReentrancyGuard, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private _tokenIds;
  Counters.Counter private supply;

  bool public paused = true;

  uint public balanceReceived;
  uint256 public claimCost = 0 ether;
  uint256 private _totalSupply;
  uint256 public _royaltyAmount;

  mapping(uint => uint8) public hasBeenClaimed1;
  mapping(uint => uint8) public hasBeenClaimed2;
  mapping(uint => uint8) public hasBeenClaimed3;
  mapping(uint => uint8) public hasBeenClaimed4;
  mapping(uint => uint8) public hasBeenClaimed5;
  mapping(uint => uint8) public hasBeenClaimed6;
  mapping(uint => uint8) public hasBeenClaimed7;
  mapping(uint => uint8) public hasBeenClaimed8;

  address public treasuryWallet = 0xcf50b23A09Fb51E0262A609a0FeE723639F705a2; 
  address public adminWallet = 0xcf50b23A09Fb51E0262A609a0FeE723639F705a2;  
  address public nftContract1Address = 0x8d17f8Ca6EFE4c85981A4C73c5927beEe2Ad1168; //PNS
  address public nftContract2Address = 0x8f1e73AA735A33e3E01573665dc7aB66DDFBa4B2; //Abstract
  address public nftContract3Address = 0xeCf0d76AF401E400CBb5C4395C76e771b358FE06; //Unfinished
  address public nftContract4Address = 0xbc54D075a3b5F10Cc3F1bA69Ee5eDA63d3fB6154; //Wasteland
  address public nftContract5Address = 0xF3544a51b156a3A24a754Cad7d48a901dDbD83d2; //Resonate
  address public nftContract6Address = 0x424F2C77341d692496544197Cc39708F214EEfc4; //Overload
  address public nftContract7Address = 0xC3C831b19B85FdC2D3E07DE348E7111BE1095Ba1; //Mind Matter
  address public nftContract8Address = 0x5DF36A4E61800e8cc7e19d6feA2623926C8EF960; //Tales
  
  	IERC721 contract1 = IERC721(nftContract1Address);
    IERC721 contract2 = IERC721(nftContract2Address);
    IERC721 contract3 = IERC721(nftContract3Address);
    IERC721 contract4 = IERC721(nftContract4Address);
    IERC721 contract5 = IERC721(nftContract5Address);
    IERC721 contract6 = IERC721(nftContract6Address);
    IERC721 contract7 = IERC721(nftContract7Address);
    IERC721 contract8 = IERC721(nftContract8Address);

  constructor() ERC721("SCRIBBLE CARDS - CUSTOMS", "SCRIBBLECC") {
       _totalSupply = 250;
       _royaltyAmount = 1000;
  }

  function setTreasuryWalletAddress(address _treasuryWallet)
        external
        onlyOwner
    {
        treasuryWallet = _treasuryWallet;
    }

  function setRoyaltyAmount(uint256 royaltyAmount_) public onlyOwner {
    _royaltyAmount = royaltyAmount_;
    }

  function addHasBeenClaimed1(uint _id) private {  
    hasBeenClaimed1[_id] = 1;
    }
  function addHasBeenClaimed2(uint _id) private {
    hasBeenClaimed2[_id] = 1;
    }
  function addHasBeenClaimed3(uint _id) private {
    hasBeenClaimed3[_id] = 1;
    }
  function addHasBeenClaimed4(uint _id) private { 
    hasBeenClaimed4[_id] = 1;
    }
  function addHasBeenClaimed5(uint _id) private {
    hasBeenClaimed5[_id] = 1;
    }
  function addHasBeenClaimed6(uint _id) private {
    hasBeenClaimed6[_id] = 1;
    }
  function addHasBeenClaimed7(uint _id) private {
    hasBeenClaimed7[_id] = 1;
    }
  function addHasBeenClaimed8(uint _id) private {
    hasBeenClaimed8[_id] = 1;
    }
  
  function mint(uint256 _tokenID, string memory uri, address _contractAddress) public payable nonReentrant {
		require(!paused, "Minting is paused");
		if (_contractAddress == nftContract1Address) {
            require(msg.sender == contract1.ownerOf(_tokenID), "You don't own this PNS Piece!");
            require(hasBeenClaimed1[_tokenID] == 0, "Custom has already been Claimed for this PNS piece");
			require(msg.value >= claimCost, "Insufficient funds");
            addHasBeenClaimed1(_tokenID);
            
		}
        else if (_contractAddress == nftContract2Address) {
            require(msg.sender == contract2.ownerOf(_tokenID), "You don't own this Abstract Piece!");
            require(hasBeenClaimed2[_tokenID] == 0, "Custom has already been Claimed for this Abstract Piece");
			require(msg.value >= claimCost, "Insufficient funds");
            addHasBeenClaimed2(_tokenID);
            
		}
        else if (_contractAddress == nftContract3Address) {
            require(msg.sender == contract3.ownerOf(_tokenID), "You don't own this Unfinished Piece!");
            require(hasBeenClaimed3[_tokenID] == 0, "Custom has already been Claimed for this Unfinished Piece");
			require(msg.value >= claimCost, "Insufficient funds");
            addHasBeenClaimed3(_tokenID);
            
		}
        else if (_contractAddress == nftContract4Address) {
            require(msg.sender == contract4.ownerOf(_tokenID), "You don't own this Wasteland Piece!");
            require(hasBeenClaimed4[_tokenID] == 0, "Custom has already been Claimed for this Wasteland piece");
			require(msg.value >= claimCost, "Insufficient funds");
            addHasBeenClaimed4(_tokenID);
            
		}
        else if (_contractAddress == nftContract5Address) {
            require(msg.sender == contract5.ownerOf(_tokenID), "You don't own this Resonate Piece!");
            require(hasBeenClaimed5[_tokenID] == 0, "Custom has already been Claimed for this Resonate Piece");
			require(msg.value >= claimCost, "Insufficient funds");
            addHasBeenClaimed5(_tokenID);
            
		}
        else if (_contractAddress == nftContract6Address) {
            require(msg.sender == contract6.ownerOf(_tokenID), "You don't own this Overload Piece!");
            require(hasBeenClaimed6[_tokenID] == 0, "Custom has already been Claimed for this Overload Piece");
			require(msg.value >= claimCost, "Insufficient funds");
            addHasBeenClaimed6(_tokenID);
            
		}
        else if (_contractAddress == nftContract7Address) {
            require(msg.sender == contract7.ownerOf(_tokenID), "You don't own this Mind Matter Piece!");
            require(hasBeenClaimed7[_tokenID] == 0, "Custom has already been Claimed for this Mind Matter Piece");
			require(msg.value >= claimCost, "Insufficient funds");
            addHasBeenClaimed7(_tokenID);
            
		}
        else if (_contractAddress == nftContract8Address) {
            require(msg.sender == contract8.ownerOf(_tokenID), "You don't own this Tales Piece!");
            require(hasBeenClaimed8[_tokenID] == 0, "Custom has already been Claimed for this Tales Piece");
			require(msg.value >= claimCost, "Insufficient funds");
            addHasBeenClaimed8(_tokenID);
            
		}
        else {
            require(msg.sender == adminWallet, "You cannot Mint a Custom Card");
            
        }

		_mintLoop(uri, _msgSender());
	}

    function _mintLoop(string memory uri, address to) internal {
        require(supply.current() + 1 <= _totalSupply, "Maximum Supply Minted");
    
        supply.increment();

		_safeMint(to, supply.current());

		_setTokenURI(supply.current(), uri);
	}

	function flipPausedState() public onlyOwner {
		paused = !paused;
	}

    function setClaimCost(uint256 newClaimCost) public onlyOwner {
        claimCost = newClaimCost;
    }

    function receiver(uint256 _deposit) public payable {
     require(msg.value >= _deposit, "Insufficient funds");
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Scribble Customs: Nothing to withdraw");
        require(payable(msg.sender).send(address(this).balance));
    }
  
    function setAdminAddress(address _adminWallet) external onlyOwner{
        adminWallet = _adminWallet;
    }

    function changeURI (uint256 tokenID, string calldata uri) public onlyOwner {
		_setTokenURI(tokenID, uri);
	}

    function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    } 

    function royaltyInfo(uint256, uint256 value) external view returns(address, uint256) {
        return (treasuryWallet, value * _royaltyAmount / 10000);
    } 

}