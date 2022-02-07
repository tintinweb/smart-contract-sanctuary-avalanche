/**
 *Submitted for verification at snowtrace.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT
// Created by petdomaa100 & modified by xrpant

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


interface IERC165 {
	function supportsInterface(bytes4 interfaceID) external view returns(bool);
}

interface IERC721 is IERC165 {
	event Transfer(address indexed from, address indexed to, uint256 indexed tokenID);
	event Approval(address indexed owner, address indexed approved, uint256 indexed tokenID);
	event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

	function balanceOf(address owner) external view returns(uint256 balance);

	function ownerOf(uint256 tokenID) external view returns(address owner);

	function safeTransferFrom(address from, address to, uint256 tokenID) external;

	function transferFrom(address from, address to, uint256 tokenID) external;

	function approve(address to, uint256 tokenID) external;

	function getApproved(uint256 tokenID) external view returns(address operator);

	function setApprovalForAll(address operator, bool _approved) external;

	function isApprovedForAll(address owner, address operator) external view returns(bool);

	function safeTransferFrom(address from, address to, uint256 tokenID, bytes calldata data) external;
}

interface IERC721Metadata is IERC721 {
	function name() external view returns(string memory);

	function symbol() external view returns(string memory);

	function tokenURI(uint256 tokenID) external view returns(string memory);
}

interface IERC721Receiver {
	function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns(bytes4);
}

interface IERC2981Royalties {
	function royaltyInfo(uint256 tokenID, uint256 value) external view returns(address receiver, uint256 royaltyAmount);
}


abstract contract Context {
	function _msgSender() internal view virtual returns(address) {
		return msg.sender;
	}

	function _msgData() internal view virtual returns(bytes calldata) {
		return msg.data;
	}
}

abstract contract Ownable is Context {
	address private _owner;

	event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


	constructor() {
		_transferOwnership(_msgSender());
	}


	function owner() public view virtual returns(address) {
		return _owner;
	}

	modifier onlyOwner() {
		require(owner() == _msgSender(), "Ownable: caller is not the owner");
		_;
	}


	function transferOwnership(address newOwner) public virtual onlyOwner {
		require(newOwner != address(0), "Ownable: new owner is the zero address");

		_transferOwnership(newOwner);
	}

	function _transferOwnership(address newOwner) internal virtual {
		address oldOwner = _owner;

		_owner = newOwner;

		emit OwnershipTransferred(oldOwner, newOwner);
	}
}

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

// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}


// File @openzeppelin/contracts/token/ERC721/extensions/[email protected]


pragma solidity ^0.8.0;


/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}


contract VMGorillas is ERC721Enumerable, ReentrancyGuard, Ownable {
	using Counters for Counters.Counter;
	using Strings for uint256;

	bool public paused;
	bool public revealed;
	bool public allowListings;
	bool public collectSalesRewardsFromThirdParty;

	string private unrevealedURI;
	string private baseURI;
	string private uriSuffix;

	uint256 public cost;
	uint256 public maxSupply;
	uint256 public reservedSupply;
	uint256 public nextVMAirdrop;

	uint256 public maxMintAmountPerTX;

	uint256 public royalties;
	uint256 public dust;

	uint256 public mintRewards;
	uint256 public salesRewards;
	uint256 public totalRewardsIndex;
	uint256 public totalRewardsVault;

	mapping(uint256 => uint256) private lastCollectedRewardIndex;

	address private communityAddress;
	address private donationAddress;
	address private VMAddr; 

	struct Listing {
		uint256 tokenID;
		uint256 price;
		address seller;
		uint256 timestamp;
	}

	Listing[] private listings;

	Counters.Counter private supply;


	uint256 private constant PERCENTAGE_MULTIPLIER = 10000;


	event NewListing(uint256 indexed tokenID, address indexed seller, uint256 price);
	event WithdrawnListing(uint256 indexed tokenID);
	event TokenSold(uint256 indexed tokenID, address indexed from, address indexed to, uint256 price);
	event ClaimedRewards(address indexed wallet, uint256 amount);
	event DisbursedRewards(uint256 amount);


	constructor(string memory _initUnrevealedURI, address _initCommunityAddress, address _initDonationAddress) ERC721("VM Gorillas", "VMG") {
		paused = true;
		revealed = false;
		allowListings = true;
		collectSalesRewardsFromThirdParty = true;

		cost = 1 ether;
		maxSupply = 8888;
		reservedSupply = 4444;
		maxMintAmountPerTX = 10;

		nextVMAirdrop = 1;

		royalties = 150;
		mintRewards = 1000;
		salesRewards = 150;
		dust = 1000000000;

		totalRewardsIndex = 1;

		communityAddress = _initCommunityAddress;
		donationAddress = _initDonationAddress;
		VMAddr = 0xBbD9786f178e2AEBb4b4329c41A821921ca05339;

		setURIsuffix(".json");
		setUnrevealedURI(_initUnrevealedURI);
	}


	function supportsInterface(bytes4 interfaceID) public view override returns(bool) {
		return interfaceID == type(IERC2981Royalties).interfaceId || super.supportsInterface(interfaceID);
	}


	function mint(uint256 amount) public payable nonReentrant {
		require(amount > 0 && amount <= maxMintAmountPerTX, "Invalid mint amount");

		uint256 newSupply = supply.current() + amount;

		require(newSupply <= maxSupply, "Max token supply exceeded");
		require(newSupply <= maxSupply - reservedSupply, "Remaining tokens are reserved");

		require(!paused, "Minting is paused");
		require(msg.value >= cost * amount, "Insufficient funds");


		uint256 mintRewardValue = 0;
		uint256 tokenIndex = supply.current();

		_mintLoop(_msgSender(), amount);


		for (uint256 i = 0; i < amount; i++) {
			if (tokenIndex > 0) {
				uint256 individualMintRewardValue = msg.value * mintRewards / PERCENTAGE_MULTIPLIER / amount / tokenIndex;

				mintRewardValue += individualMintRewardValue * tokenIndex;
				totalRewardsIndex += individualMintRewardValue;
			}

			tokenIndex++;
			lastCollectedRewardIndex[tokenIndex] = totalRewardsIndex;
		}

		totalRewardsVault += mintRewardValue;
	}

	function airDrop(address[] calldata addresses, uint8[] calldata amounts) public onlyOwner {
		assert(addresses.length == amounts.length);
		assert(addresses.length > 0 && amounts.length > 0);


		uint256 totalAmount;
		for (uint256 i = 0; i < amounts.length; i++) totalAmount += amounts[i];

		require(supply.current() + totalAmount <= maxSupply, "Max token supply exceeded");


		for (uint256 i = 0; i < addresses.length; i++) {
			uint8 amount = amounts[i];

			for (uint256 j = 0; j < amount; j++) {
				supply.increment();

				uint256 tokenID = supply.current();

				_safeMint(addresses[i], tokenID);

				lastCollectedRewardIndex[tokenID] = totalRewardsIndex;
			}
		}
	}

	function airDropVMOwner(uint256 _lastToken) public onlyOwner {
		require(nextVMAirdrop <= _lastToken, "Token already airdropped!");
		require(_lastToken <= 4444, "Last token must be 4444 or less.");

		IERC721 VMContract = IERC721(VMAddr);

		for (uint256 i = nextVMAirdrop; i <= _lastToken; i++) {

			supply.increment();

			uint256 tokenID = supply.current();

			_safeMint(VMContract.ownerOf(i), tokenID);

			lastCollectedRewardIndex[tokenID] = totalRewardsIndex;

			reservedSupply -= 1;

		}

        nextVMAirdrop = _lastToken + 1;
	}


	function flipPausedState() public onlyOwner {
		paused = !paused;
	}

	function flipAllowListingsState() public onlyOwner {
		allowListings = !allowListings;
	}

	function flipCollectSalesRewardsFromThirdParty() public onlyOwner {
		collectSalesRewardsFromThirdParty = !collectSalesRewardsFromThirdParty;
	}

	function reveal(string memory _initBaseURI) public onlyOwner {
		revealed = true;

		setBaseURI(_initBaseURI);
	}

	function claimRewards() public payable nonReentrant {
		uint256 reward = getRewardsOfAddress(_msgSender());
		require(reward > 0, "You don't have any rewards");

        uint256 numTokens = balanceOf(_msgSender());

		for (uint256 i = 0; i < numTokens; i++) {
			uint256 tokenID = tokenOfOwnerByIndex(_msgSender(), i);

			lastCollectedRewardIndex[tokenID] = totalRewardsIndex;
		}

		totalRewardsVault -= reward;

		(bool success, ) = payable(_msgSender()).call{ value: reward }("");
		require(success, "AVAX Transaction: Failed to transfer funds");


		emit ClaimedRewards(_msgSender(), reward);
	}

	function claimRewardOfToken(uint256 tokenID) public payable nonReentrant {
		address owner = ownerOf(tokenID);
		require(_msgSender() == owner, "Only the owner of a token can claim rewards");

		uint256 reward = getRewardsOfToken(tokenID);
		require(reward > 0, "You don't have any rewards");


		totalRewardsVault -= reward;
		lastCollectedRewardIndex[tokenID] = totalRewardsIndex;


		(bool success, ) = payable(owner).call{ value: reward }("");
		require(success, "AVAX Transaction: Failed to transfer funds");


		emit ClaimedRewards(owner, reward);
	}

	function withdraw() public onlyOwner {
		uint256 balance_10percent = (address(this).balance - totalRewardsVault) * 10 / 100;

		(bool success1, ) = payable(communityAddress).call{ value: balance_10percent * 4 }("");
		require(success1, "AVAX Transaction: Failed to transfer funds to community wallet!");

		(bool success2, ) = payable(donationAddress).call{ value: balance_10percent }("");
		require(success2, "AVAX Transaction: Failed to transfer funds to donation wallet!");

		(bool success3, ) = payable(owner()).call{ value: address(this).balance - (totalRewardsVault + dust) }("");
		require(success3, "AVAX Transaction: Failed to transfer funds to the owner wallet!");
	}

	function emergencyWithdraw() public payable onlyOwner {
		(bool success, ) = payable(owner()).call{ value: address(this).balance }("");

		require(success, "AVAX Transaction: Failed to transfer funds");
	}

	function disburseRewards() public payable onlyOwner {
		uint256 currentSupply = supply.current();

		uint256 individualRewardValue = msg.value / currentSupply;
		uint256 rewardValue = individualRewardValue * currentSupply;

		totalRewardsIndex += individualRewardValue;
		totalRewardsVault += rewardValue;

		emit DisbursedRewards(msg.value);
	}

	function royaltyInfo(uint256, uint256 value) external view returns(address receiver, uint256 royaltyAmount) {
		receiver = address(this);

		royaltyAmount = value * (royalties + salesRewards) / PERCENTAGE_MULTIPLIER;
	}

	function createListing(uint256 tokenID, uint256 price) public nonReentrant {
		require(allowListings, "ERC721 Marketplace: Listings are currently disabled");
		require(price > 0, "ERC721 Marketplace: Invalid listing price");
		require(ownerOf(tokenID) == _msgSender(), "ERC721 Marketplace: Caller is not the owner");

		(bool isListed, ) = isTokenListed(tokenID);
		require(!isListed, "ERC721 Marketplace: Token is already listed");

		Listing memory sale = Listing(tokenID, price, _msgSender(), block.timestamp);

		listings.push(sale);

		emit NewListing(tokenID, _msgSender(), price);
	}

	function withdrawListing(uint256 tokenID) public nonReentrant {
		(bool isListed, uint256 listingIndex) = isTokenListed(tokenID);

		require(isListed, "ERC721 Marketplace: Token is not listed");
		require(listings[listingIndex].seller == _msgSender(), "ERC721 Marketplace: Caller is not the owner");

		listings[listingIndex] = listings[listings.length - 1];
		listings.pop();

		emit WithdrawnListing(tokenID);
	}

	function fulfillListing(uint256 tokenID) public payable nonReentrant {
		(bool isListed, uint256 listingIndex) = isTokenListed(tokenID);
		require(isListed, "ERC721 Marketplace: Token is not listed");

		Listing memory listing = listings[listingIndex];

		require(listing.seller != _msgSender(), "ERC721 Marketplace: Buyer and seller must be be different addresses");
		require(msg.value >= listing.price, "ERC721 Marketplace: Insufficient funds");

		uint256 royaltiesValue = msg.value * royalties / PERCENTAGE_MULTIPLIER;
		uint256 individualSalesRewardValue = msg.value * salesRewards / PERCENTAGE_MULTIPLIER / (supply.current() - 1);
		uint256 salesRewardValue = individualSalesRewardValue * (supply.current() - 1);


		listings[listingIndex] = listings[listings.length - 1];
		listings.pop();


		totalRewardsIndex += individualSalesRewardValue;
		lastCollectedRewardIndex[tokenID] += individualSalesRewardValue;

		totalRewardsVault += salesRewardValue;


		emit TokenSold(tokenID, listing.seller, _msgSender(), msg.value);


		_safeTransfer(listing.seller, _msgSender(), tokenID, "");

		(bool success, ) = payable(listing.seller).call{ value: msg.value - (royaltiesValue + salesRewardValue) }("");
		require(success, "AVAX Transaction: Failed to transfer funds");
	}

	function isTokenListed(uint256 tokenID) public view returns(bool isListed, uint256 index) {
		for (uint256 i = 0; i < listings.length; i++) {
			if (listings[i].tokenID != tokenID) continue;

			isListed = true;
			index = i;

			break;
		}
	}

	function getListings() public view returns(Listing[] memory) {
		return listings;
	}

	function getListingByTokenID(uint256 tokenID) public view returns(Listing memory) {
		(bool isListed, uint256 listingIndex) = isTokenListed(tokenID);
		require(isListed, "ERC721 Marketplace: Token is not listed");

		return listings[listingIndex];
	}

	function tokenURI(uint256 tokenID) public view override returns(string memory) {
		require(_exists(tokenID), "ERC721Metadata: URI query for nonexistent token");

		if (!revealed) return unrevealedURI;

		string memory currentBaseURI = _baseURI();

		return bytes(currentBaseURI).length > 0 ? string( abi.encodePacked(currentBaseURI, tokenID.toString(), uriSuffix) ) : "";
	}

	function getRewardsOfAddress(address _address) public view returns(uint256) {
        uint256 numTokens = balanceOf(_address);
		uint256 total = 0;

		for (uint256 i = 0; i < numTokens; i++) {
            uint256 tokenID = tokenOfOwnerByIndex(_address, i);
			total += getRewardsOfToken(tokenID);
		}

		return total;
	}

	function getRewardsOfToken(uint256 tokenID) public view returns(uint256) {
		require(supply.current() >= tokenID, "Query for nonexistent token");

		return totalRewardsIndex - lastCollectedRewardIndex[tokenID];
	}

	function setBaseURI(string memory newBaseURI) public onlyOwner {
		baseURI = newBaseURI;
	}

	function setUnrevealedURI(string memory newUnrevealedURI) public onlyOwner {
		unrevealedURI = newUnrevealedURI;
	}

	function setURIsuffix(string memory newSuffix) public onlyOwner {
		uriSuffix = newSuffix;
	}

	function setMaxSupply(uint256 newAmount) public onlyOwner {
		maxSupply = newAmount;
	}

	function setReservedSupply(uint256 newAmount) public onlyOwner {
		reservedSupply = newAmount;
	}

	function setMaxMintAmountPerTX(uint256 newAmount) public onlyOwner {
		maxMintAmountPerTX = newAmount;
	}

	function setCost(uint256 newCost) public onlyOwner {
		cost = newCost;
	}

	function setMintRewards(uint256 newValue) public onlyOwner {
		mintRewards = newValue;
	}

	function setSalesRewards(uint256 newValue) public onlyOwner {
		salesRewards = newValue;
	}

	function setRoyalties(uint256 newValue) public onlyOwner {
		royalties = newValue;
	}

	function setDust(uint256 newValue) public onlyOwner {
		dust = newValue;
	}

	function setTotalRewardsIndex(uint256 newAmount) public onlyOwner {
		totalRewardsIndex = newAmount;
	}

    function setNextVMAirDrop(uint256 newAmount) public onlyOwner {
		nextVMAirdrop = newAmount;
	}

	function setWithdrawAddresses(address newCommunityAddress, address newDonationAddress) public onlyOwner {
		communityAddress = newCommunityAddress;
		donationAddress = newDonationAddress;
	}

    function setVMAddr (address _contract) public onlyOwner {
		VMAddr = _contract;
	}


	function _baseURI() internal view override returns(string memory) {
		return baseURI;
	}

	function _beforeTokenTransfer(address from, address to, uint256 tokenID) internal override (ERC721Enumerable){
		(bool isListed, ) = isTokenListed(tokenID);
		require(!isListed, "ERC721 Marketplace: Unable to transfer a listed token");


		super._beforeTokenTransfer(from, to, tokenID);
	}

	function _mintLoop(address to, uint256 amount) internal {
		for (uint256 i = 0; i < amount; i++) {
			supply.increment();

			_safeMint(to, supply.current());
		}
	}

	receive() external payable {
		uint256 currentSupply = supply.current();

		if (collectSalesRewardsFromThirdParty == true && currentSupply > 0) {
			uint256 individualSalesRewardValue = msg.value / (salesRewards + royalties) * salesRewards / currentSupply;
			uint256 salesRewardValue = individualSalesRewardValue * currentSupply;

			totalRewardsIndex += individualSalesRewardValue;

			totalRewardsVault += salesRewardValue;
		}
	}
}