/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-05
*/

// File: pfp.sol


// Created by The Spot GOATd Devs

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

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

interface ITRAIT {
    function burnSpotDrop(uint256 typeId, address burnTokenAddress) external;

    function balanceOf(address owner, uint256 typeId) external view returns (uint256);
}

contract GOATd is ERC721URIStorage, ReentrancyGuard, Ownable {
	using Counters for Counters.Counter;
	using Strings for uint256;

	bool public paused = true;

	uint256 public cost = 1 ether;

	uint256 public royalties = 100;

	mapping(bytes => uint8) public availableDNA;
	mapping(uint256 => uint8) public notBurnable;

	address private treasuryAddress = 0x32bD2811Fb91BC46756232A0B8c6b2902D7d8763;
	address private traitsAddress = 0xD1cebaDdf3a76CD1E628e8Ce541fC700c64Afe47;

    ITRAIT traitsContract = ITRAIT(traitsAddress);

	Counters.Counter private supply;

	uint256 private constant PERCENTAGE_MULTIPLIER = 10000;

	event GoatMinted(
        uint256 indexed tokenId,
        address indexed minter,
        uint256[6] traitIDs
    );

	constructor() ERC721("GOATd PFP", "GOATd") {

	}

	function supportsInterface(bytes4 interfaceID) public view override returns(bool) {
		return interfaceID == type(IERC2981Royalties).interfaceId || super.supportsInterface(interfaceID);
	}

	function mint(uint256 bg, uint256 body, uint256 head, uint256 eyes, uint256 mouth, uint256 headwear, string calldata uri) public payable nonReentrant {
		require(((bg > 0 && bg < 100) || notBurnable[bg] == 1) && 
                ((body >= 100 && body < 200) || notBurnable[body] == 1) &&
                ((head >= 200 && head < 300) || notBurnable[head] == 1) &&
                ((eyes >= 300 && eyes < 400) || notBurnable[eyes] == 1) &&
                ((mouth >= 400 && mouth < 500) || notBurnable[mouth] == 1) &&
                (headwear >= 600 || notBurnable[headwear] == 1), "GOATd: At least one trait specified is invalid!");
        
		if (notBurnable[bg] == 0){
        	require(traitsContract.balanceOf(_msgSender(), bg) > 0, "GOATd: You don't own that background!");
		}
		
		if (notBurnable[body] == 0){
			require(traitsContract.balanceOf(_msgSender(), body) > 0, "GOATd: You don't own that body!");
		}
		
		if (notBurnable[head] == 0){
			require(traitsContract.balanceOf(_msgSender(), head) > 0, "GOATd: You don't own that head!");
		}
		
		if (notBurnable[eyes] == 0){
			require(traitsContract.balanceOf(_msgSender(), eyes) > 0, "GOATd: You don't own that eyes!");
		}
		
		if (notBurnable[mouth] == 0){
			require(traitsContract.balanceOf(_msgSender(), mouth) > 0, "GOATd: You don't own that mouth!");
		}

		if (notBurnable[headwear] == 0){
        	require(traitsContract.balanceOf(_msgSender(), headwear) > 0, "GOATd: You don't own that headwear!");
		}

        bytes memory DNA = abi.encodePacked(Strings.toString(bg), Strings.toString(body), Strings.toString(head), 
                                             Strings.toString(eyes), Strings.toString(mouth), Strings.toString(headwear));

        require(availableDNA[DNA] == 0, "GOATd: Combination specified already exists!");
		require(!paused, "Minting is paused");
		require(msg.value >= cost, "Insufficient funds");

		_mintLoop(_msgSender(), bg, body, head, eyes, mouth, headwear, uri);

        availableDNA[DNA] = 1;

		emit GoatMinted(supply.current(), _msgSender(), [bg, body, head, eyes, mouth, headwear]);
	}

    function _mintLoop(address to, uint256 bg, uint256 body, uint256 head, uint256 eyes, uint256 mouth, uint256 headwear, string memory uri) internal {
        if (notBurnable[bg] == 0){
			traitsContract.burnSpotDrop(bg, to);
		}
		
		if (notBurnable[body] == 0){
			traitsContract.burnSpotDrop(body, to);
		}

		if (notBurnable[head] == 0){
			traitsContract.burnSpotDrop(head, to);
		}
		
		if (notBurnable[eyes] == 0){
			traitsContract.burnSpotDrop(eyes, to);
		}
		
		if (notBurnable[mouth] == 0){
			traitsContract.burnSpotDrop(mouth, to);
		}

		if (notBurnable[headwear] == 0){
        	traitsContract.burnSpotDrop(headwear, to);
		}

		supply.increment();

		_safeMint(to, supply.current());

		_setTokenURI(supply.current(), uri);
		
	}

	function flipPausedState() public onlyOwner {
		paused = !paused;
	}

	function withdraw() public onlyOwner {
		(bool success, ) = payable(treasuryAddress).call{ value: address(this).balance}("");
		require(success, "AVAX Transaction: Failed to transfer funds to the owner wallet!");
	}

	function royaltyInfo(uint256, uint256 value) external view returns(address, uint256) {
		return (treasuryAddress, value * royalties / PERCENTAGE_MULTIPLIER);
	}

	function totalSupply() public view returns(uint256) {
		return supply.current();
	}

    function checkDNA(string calldata DNA) public view returns(uint8) {
        return availableDNA[abi.encodePacked(DNA)];
    }

	function walletOfOwner(address _address) public view returns(uint256[] memory) {
		uint256 ownerTokenCount = balanceOf(_address);

		uint256[] memory ownedTokenIDs = new uint256[](ownerTokenCount);

		uint256 tokenIndex = 1;
		uint256 ownedTokenIndex = 0;

		while (ownedTokenIndex < ownerTokenCount && tokenIndex <= totalSupply()) {
			address owner = ownerOf(tokenIndex);

			if (owner == _address) {
				ownedTokenIDs[ownedTokenIndex] = tokenIndex;

				ownedTokenIndex++;
			}

			tokenIndex++;
		}

		return ownedTokenIDs;
	}

	function setCost(uint256 newCost) public onlyOwner {
		cost = newCost;
	}

	function setRoyalties(uint256 newValue) public onlyOwner {
		royalties = newValue;
	}

	function setTreasuryAddress(address newTreasuryAddress) public onlyOwner {
		treasuryAddress = newTreasuryAddress;
	}

    function setTraitsAddress(address newTraitsAddress) public onlyOwner {
		traitsAddress = newTraitsAddress;
        traitsContract = ITRAIT(traitsAddress);
	}

	function addNotBurnable (uint256[] calldata _traits) public onlyOwner {
		for (uint256 i = 0; i < _traits.length; i++) {
			notBurnable[_traits[i]] = 1;
		}
	}

	function changeURI (uint256 tokenID, string calldata uri) public onlyOwner {
		_setTokenURI(tokenID, uri);
	}

	// Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}

	function withdrawERC20(address _tokenAddress) public payable onlyOwner {
        IERC20 token = IERC20(_tokenAddress);

        uint256 balance = token.balanceOf(address(this));
		
		token.transfer(payable(owner()), balance);
    }

    function withdrawERC721(address _nftAddress, uint _tokenID) public payable onlyOwner {
        IERC721 token = IERC721(_nftAddress);

		token.safeTransferFrom(address(this), owner(), _tokenID);
    }
}