/**
 *Submitted for verification at snowtrace.io on 2022-07-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;



library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {

        if (value == 0) {
            return "0";
        }
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

library Address {
   
    function isContract(address account) internal view returns (bool) {

        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Metadata is IERC721, IERC721Enumerable {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

interface IERC2981Royalties {
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}


interface IVRFOracleOraichain {
    function randomnessRequest(uint256 _seed, bytes calldata _data) external payable returns (bytes32 reqId);

    function getFee() external returns (uint256);
}

abstract contract ERC2981 is IERC2981Royalties  {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

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


contract DSC is Ownable, ERC2981, IERC721Metadata {
    
    function supportsInterface(bytes4 interfaceId) public view override virtual returns (bool) {
        return interfaceId == type(IERC721).interfaceId || 
        interfaceId == type(IERC721Metadata).interfaceId || 
        interfaceId == type(IERC721Receiver).interfaceId || 
        interfaceId == type(IERC2981Royalties).interfaceId || 
        interfaceId == type(IVRFOracleOraichain).interfaceId || 
        interfaceId == type(IERC721Enumerable).interfaceId;
    }

    using Address for address;
    using Strings for uint256;
    using Counters for Counters.Counter;


    Counters.Counter private _IdCounter;

    string private _name;
    
    string private _symbol;
    
    uint256[] private _allTokens;

    string private baseURI_;

    
    mapping(uint256 => address) private _owners;

    
    mapping(address => uint256) private _balances;

    
    mapping(uint256 => address) private _tokenApprovals;

    
    mapping(address => mapping(address => bool)) private _operatorApprovals;


    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    
    mapping(uint256 => uint256) private _ownedTokensIndex;

    
    mapping(uint256 => uint256) private _allTokensIndex;

    //---proy---


   
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

   
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, ending[tokenId])) : "";
    }

    
    function _baseURI() internal view virtual returns (string memory) {
        return baseURI_;
    }

    
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = DSC.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

   
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

   
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = DSC.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

   
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

   
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    
    function _burn(uint256 tokenId) internal virtual {
        address owner = DSC.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(DSC.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(DSC.ownerOf(tokenId), to, tokenId);
    }

    
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    
    function __beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < DSC.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < DSC.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        __beforeTokenTransfer(from, to, tokenId);

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

    
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = DSC.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        uint256 lastTokenIndex = DSC.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; 
            _ownedTokensIndex[lastTokenId] = tokenIndex; 
        }

        
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
       

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

    
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; 
        _allTokensIndex[lastTokenId] = tokenIndex;

        
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    //---func---

    bool private _onlyWhitelist = true;

    string[] private endings;

    uint256[] private rarities;

    uint256 public sc;

    uint256 public price;

    uint256 public maxPerWallet;

    address public oracle;
    uint256 public random1;
    bytes32 public reqId;
    string public metac;

    mapping(address => bool) private whitelist; 

    mapping(uint256 => string) private ending;

    mapping(uint256 => uint256) private rarity;

    mapping(uint256 => bool) private given;


    constructor(string memory name_, string memory symbol_, uint256 iPrice, string memory bURI, string[] memory endings_, uint256[] memory rarities_, address oracle_, string memory _metac) {
        _name = name_;
        _symbol = symbol_;
        baseURI_ = bURI;
        endings = endings_;
        rarities = rarities_;
        price = iPrice;
        maxPerWallet = 2;
        oracle = oracle_;
        _setDefaultRoyalty(_msgSender(),1000);
        metac = _metac;
        require(price > 0, "Price cannot be 0");
        require(endings.length == rarities.length,"Endings length mismatch");
    }


    function whitelistState(bool state) public virtual onlyOwner returns (bool success){
        _onlyWhitelist = state;
        return true;
    }

    function onlyWhitelist() public view virtual  returns (bool) {
        return _onlyWhitelist;
    }

    function addToWhite(address member) public virtual onlyOwner returns (bool success){
        whitelist[member]=true;
        return true;
    }

    function isInWhite(address member)public view virtual  returns (bool) {
        return whitelist[member];
    }

    function setPrice(uint256 newPrice) public virtual onlyOwner returns (bool success) {
        price = newPrice;
        return true;
    }

    function setMax(uint256 newMax) public virtual onlyOwner returns (bool success) {
        maxPerWallet = newMax;
        return true;
    }

    function contractURI() public view returns (string memory) {
        return metac;
    }

    function setContractURI(string memory newURI) public virtual onlyOwner returns (bool success){
        metac = newURI;
        return true;
    }

    function setBaseURI(string calldata newBase) public virtual onlyOwner returns (bool success){
        baseURI_ = newBase;
        return true;
    }

    function tokenRarity(uint256 _tokenId) public view virtual returns (uint256 Rarity) {
        require(_exists(_tokenId), "Query for nonexistent token");
        return rarity[_tokenId];
    }

    function setOracle(address newOracle) public virtual onlyOwner returns (bool success){
        oracle = newOracle;
        return true;
    }

    function randomnessRequest(uint256 _seed) public {
        uint256 fee = IVRFOracleOraichain(oracle).getFee();
        bytes memory data = abi.encode(address(this), this.fulfillRandomness.selector);
        reqId = IVRFOracleOraichain(oracle).randomnessRequest{value: fee}(_seed, data);
    }

    function fulfillRandomness(bytes32 _reqId, uint256 oraichainRandomness) public {
        random1 = random(oraichainRandomness, endings.length);
        uint256 sw = 0;
        while (sw == 0 && sc < endings.length) {
            if (given[random1]){
                random1 = (random1+1) % endings.length;
            } else {
                sw = 1; 
            }
        }
        
    }

    function random(uint256 _oraiNumber, uint256 _weight) public returns (uint256){
        return uint256(keccak256(abi.encodePacked(_oraiNumber, block.difficulty, block.timestamp, block.coinbase, block.number, msg.sender))) % (_weight);
    }

    function setTokenRoyalty(uint256 tokenId, address receiver, uint96 feeFactor) public virtual onlyOwner returns(bool success){
        _setTokenRoyalty(tokenId,receiver,feeFactor);
        return true;
    }

    function mint() public payable virtual returns (string memory code) {
        if (_onlyWhitelist) {
            require(whitelist[_msgSender()], "Not in whitelist");
            require(balanceOf(msg.sender) < maxPerWallet, "Max NFT per wallet reached");
        }
        require(msg.value == price, "Wrong cost");
        
        randomnessRequest(0);
        fulfillRandomness(reqId,0);
        
        _IdCounter.increment();
        uint256 tokenId = _IdCounter.current();
        
        ending[tokenId] = endings[random1];
        rarity[tokenId] = rarities[random1];

        _safeMint(_msgSender(), tokenId);
        given[random1] = true;
        
        sc += 1;
        return ending[tokenId];
    }

    function withraw(address payable _to, uint256 amount) public payable onlyOwner {
        _to.transfer(amount);
    }

    function _addElement(string memory _ending, uint256 _rarity) internal virtual{
        endings.push(_ending);
        rarities.push(_rarity);
    }

    function addElement(string memory _ending, uint256 _rarity) public virtual onlyOwner returns (bool success){
        _addElement(_ending,_rarity);
        return true;
    }

    function setElement(uint256 tokenId, string memory _ending, uint256 _rarity) public virtual onlyOwner returns (bool success){
        ending[tokenId] = _ending;
        rarity[tokenId] = _rarity;
        return true;
    }

    function addBatch(string[] memory _endings, uint256[] memory _rarities) public virtual onlyOwner returns (bool success){
        require(_endings.length == _rarities.length,"Endings length mismatch");
        for (uint256 j=0; j < _endings.length; j++){
            _addElement(_endings[j],_rarities[j]);
        }
        return true;
    }

    function addWhiteBatch(address[] memory _members) public virtual onlyOwner returns (bool success){
        require(_members.length > 0,"Give me someone");
        for (uint256 j=0; j < _members.length; j++){
            addToWhite(_members[j]);
        }
        return true;
    }    
}