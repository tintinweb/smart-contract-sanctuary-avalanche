/**
 *Submitted for verification at snowtrace.io on 2022-10-26
*/

// File: contracts/Gravedigger.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

//GRAVEDIGGER BROUGHT TO YOU BY THE SPOT! Thespot.art is the spot on avax.
//Engrave and utilize your NFTombstones at gravedigger.app

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

interface ITombstone {
    function setTokenURI(uint256 tokenId, string memory _tokenURI) external;
    function transferOwnership(address newOwner) external;
	function ownerOf(uint256 tokenId) external;

}

contract Gravedigger is IERC721Receiver, ReentrancyGuard, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  address public treasuryWallet; 

  Counters.Counter private _tokenIds;

  string private uriSuffix = ".json";

  uint256 public engraveCost = 0 ether;
  uint256 public rezCost = 0.1 ether;
  uint256 public payableAmount = 0.00001 ether;
  uint public balanceReceived;

  mapping(uint => uint8) public hasBeenEngraved;
  mapping(address => uint) public addressToTombstone;
  mapping(address => uint8) public payableContracts;
  mapping(uint => uint) public dedCount;
  
  address public ADMIN_WALLET = 0x32bD2811Fb91BC46756232A0B8c6b2902D7d8763;  
  address private nfTombstoneContractAddress = 0xe3525413c2a15daec57C92234361934f510356b8; 
  address private spotAddress = 0x0C6945E825fc3c80F0a1eA1d3E24d6854F7460d8; 

  	IERC721 spot = IERC721(spotAddress);
  	IERC721 tombstoneNFT = IERC721(nfTombstoneContractAddress);

  constructor() Ownable() {
  }

    function addHasBeenEngraved(uint _id) private {
    hasBeenEngraved[_id] = 1;
    }
  
    function setTokenURI(uint256 tokenId, string memory _tokenURI) public onlyOwner {
        ITombstone c = ITombstone(nfTombstoneContractAddress);
        c.setTokenURI(tokenId, _tokenURI);
    } 

    function engraveTombstone(uint _tokenID, string memory newTokenUri) public payable {
        ITombstone c = ITombstone(nfTombstoneContractAddress);
        require(msg.sender == tombstoneNFT.ownerOf(_tokenID), "You don't own this NFTombstone!");
        require(msg.value >= engraveCost, "Insufficient funds");
        require(hasBeenEngraved[_tokenID] == 0, "NFTombstone has already been Engraved");
        c.setTokenURI(_tokenID, newTokenUri);
        addHasBeenEngraved(_tokenID);
        // set tombstone to address when engraved
        addressToTombstone[msg.sender] = _tokenID;     
        (bool success, ) = payable(treasuryWallet).call{ value: msg.value }("");
        require(success, "AVAX Transaction: Failed to transfer funds to treasury wallet!");
    } 

    function changeActiveTombstone(uint _newTombstone) public {
        require(hasBeenEngraved[_newTombstone] == 1, "NFTombstone needs to be engraved!");
        require(msg.sender == tombstoneNFT.ownerOf(_newTombstone), "That's not your NFTombstone!");
        addressToTombstone[msg.sender] = _newTombstone;
    }  

    function setEngraveCost(uint256 newEngraveCost) public onlyOwner {
        engraveCost = newEngraveCost;
    }

        function setRezCost(uint256 newRezCost) public onlyOwner {
        rezCost = newRezCost;
    }

    function setPayableAmount(uint256 newPayableCost) public onlyOwner {
        payableAmount = newPayableCost;
    }

    function addPayableContracts(address[] calldata contracts) public onlyOwner {
        for(uint i = 0; i < contracts.length; i++) {
            payableContracts[contracts[i]] = 1;
        }
    }

    function raiseTheDed(address _contract, uint _tokenId) public payable nonReentrant {
        require(msg.value == rezCost, "Insufficient funds!");
        require(spot.balanceOf(msg.sender) >= 1, "You don't own a spot");
        IERC721 nft = IERC721(_contract);
        nft.safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function dedOne(address _contract, uint _tokenId) public nonReentrant {
        IERC721 nft = IERC721(_contract);
        nft.safeTransferFrom(msg.sender, address(this), _tokenId);
        // if from address has an active tombstone, add to dedCount
        if (addressToTombstone[msg.sender] > 0) {
            dedCount[addressToTombstone[msg.sender]] += 1;
        }   

        // if valid contract and there is enough available, pay sender for NFT
        if (payableContracts[_contract] == 1 && address(this).balance >= payableAmount) {
            (bool success, ) = payable(msg.sender).call{ value: payableAmount }("");
            require(success, "AVAX Transaction: Failed to purchase ded NFT!");
        }  
    }

    function dedMany(address[] calldata _contracts, uint[][] calldata _ids) public nonReentrant {
        for (uint i = 0; i < _contracts.length; i++) {
            IERC721 nft = IERC721(_contracts[i]);
            for (uint j = 0; j < _ids.length; j++) {
                nft.safeTransferFrom(msg.sender, address(this), _ids[i][j]);
                // if from address has an active tombstone, add to dedCount
                if (addressToTombstone[msg.sender] > 0) {
                    dedCount[addressToTombstone[msg.sender]] += 1;
                }   

                // if valid contract and there is enough available, pay sender for NFT
                if (payableContracts[_contracts[i]] == 1 && address(this).balance >= payableAmount) {
                    (bool success, ) = payable(msg.sender).call{ value: payableAmount }("");
                    require(success, "AVAX Transaction: Failed to purchase ded NFT!");
                }
            }
        }
    }

  function receiver(uint256 _deposit) public payable {
     require(msg.value >= _deposit, "Insufficient funds");
    }

  function getBalance() public view returns(uint) {
        return address(this).balance;
    }

  function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Gravedigger: Nothing to withdraw");
        require(payable(msg.sender).send(address(this).balance));
    }
  
    function setTreasuryWalletAddress(address _treasuryWallet) external onlyOwner{
        treasuryWallet = _treasuryWallet;
    }

    function transferNfTombstoneOwnership(address _contract, address _newOwner) public onlyOwner {
        ITombstone c = ITombstone(_contract);
        c.transferOwnership(_newOwner);
    }
  
   function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    } 

}