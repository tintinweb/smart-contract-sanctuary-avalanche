/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface BERRY_Staking {
    function lockedStaking(address user, uint256 tokenId) external;
    function getTotalIds(address _user) external view returns(uint256[] memory);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface BCASH20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Receiver {

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


abstract contract ERC165 is IERC165 {

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
abstract contract Ownable is Context {

    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
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
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
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
        //solhint-disable-next-line max-line-length
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
    }
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        
        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {

    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
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

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
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
}

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
       if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract SignVerify {

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        require(sig.length == 65);

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    function recoverSigner(bytes32 hash, bytes memory signature)
        internal
        pure
        returns (address)
    {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(signature);

        return ecrecover(hash, v, r, s);
    }

    function toString(address account) public pure returns (string memory) {
        return toString(abi.encodePacked(account));
    }

    function toString(bytes memory data) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < data.length; i++) {
            str[2 + i * 2] = alphabet[uint256(uint8(data[i] >> 4))];
            str[3 + i * 2] = alphabet[uint256(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

contract AA is Ownable,SignVerify,ERC721Enumerable{

    IERC20 public Token;
    BCASH20 public BCASH;
    BERRY_Staking public BERRY;

    using Strings for uint256;
    using SafeMath for uint256;

    ////////////////////////////        VARIABLES       /////////////////////////////
    address signerAddress;
    uint256 startAT;
    uint256 startingPrice;
    uint256 discountRate ;
    uint256 initialMinting = 10;    // 100 initial Minting
    uint256 priceDecrementTime = 10 seconds;
    uint256 Dutch_Max_supply = 2000;
    uint256 public total_Dutch_Minted;
    uint256 public publicPrice = 0.5 ether;
    uint256 public total_Public_Minted;
    uint256 public genesisPrice = 20000000000000000000;
    uint256 public constant MAX_SUPPLY = 10000;

    
    uint256[100] private _firstCollection;     // freeMint array
    uint256[200] private _secondCollection;    // dutchMint array
    uint256[450] private _thirdCollection;     // publicMint array
    uint256[10] private _fourthCollection;      // ownerMint array
    uint256[40] private _fifthCollection;      // uncommon array
    uint256[200] private _sixthCollection;     // Breed array
    
    bool public freeMintStarted;
    bool public auctionStarted;
    bool public publicStarted;
    bool public genesisStarted;
    bool public lock = false;
    bool public NoSale;

    string public prefixURI =   "   no-way  ";

    
    ////////////////////////////        MAPPING         ///////////////////////////
    mapping (bytes32 => bool) public usedHash;
    mapping (address => bool) public claimedUser;
    mapping (address => uint256) public totalFreeMinted;
    mapping (address => uint256) public totalDutchMinted;
    mapping(address => bool) public isWhitelisted;
    mapping(address => uint256) public totalPublicMinted;
    mapping(address => uint256) public totalBreedMinted;
    mapping(uint256 => string) public tokenURIs;
    mapping(uint256 => Collection) public collection;
    mapping(uint256 => uint256) private freeMintingTime;
    mapping(uint256 => uint256) private dutchMintingTime;
    mapping(uint256 => uint256) private tokenIdType; // store tokenIdType

    struct Collection 
    {
        uint256 collectionSupply;
        uint256 availableTokens; 
    }

    struct mintedData
    {
        address mintedAddress;
        uint256 amount;
    }
    mintedData[] public minteddata;

    ///////////////////////////////////////////////////////////////////////////////
    //////////////////////////////  CONSTRUCTOR  /////////////////////////////////


    constructor(IERC20 BCB_token 
    // ,BCASH20 _Bcash
    ) ERC721( " BERRY CLUB ", " BCB " ) {
        Token = BCB_token ;
        // BCASH = _Bcash;
        // initMinting(initialMinting);
        setCollectionData();
    }

    ///////////////////////////////////////////////////////////////////////////////
    ////////////////////////   OWNER MINTING FUNCTION  ////////////////////////////

    function initMinting() public onlyOwner {
        // require(totalSupply() + initialMinting <= MAX_SUPPLY, "MAX_SUPPLY_REACHED");
        uint256 random_id;
        address user = msg.sender;
        // uint256 total = collection[1].collectionSupply 
        // + collection[2].collectionSupply;
        for (uint256 i = 1; i <= initialMinting; i++) {
            random_id = useRandomAvailableToken(1,1,1);
            _mint(user, random_id);
        }
        addToMintData(initialMinting);
    }

    // Owner can mint 

    function mintOwner(uint256 _count, address _account) external onlyOwner {
        require(totalSupply() + _count <= MAX_SUPPLY, "MAX_SUPPLY_REACHED");
        for (uint256 i = 1; i <= _count; i++) {
            _safeMint(_account, totalSupply() + i);
        }
        addToMintData(_count); 
    }

    /*
    *  can calaim NFT fro free
    *  this will stake directely
    *  but after some time (lockStake)
    */

    function claimNFT(uint256 _count
    // , uint256 _nonce, bytes memory signature
    ) external
    {
    //   require(freeMintStarted, "Mint Not Started");
    //   require(claimedUser[msg.sender] != true," Already Claimed ");
      address user = msg.sender;
      uint256 random_id;
      uint256 tokenId_;
    //   uint256 total = collection[1].collectionSupply;
    //   bytes32 hash = keccak256(   
    //           abi.encodePacked(   
    //             toString(address(this)),   
    //             toString(msg.sender),
    //             _nonce
    //           )
    //       );
    //   require(!usedHash[hash], "Invalid Hash");   
    //   require(recoverSigner(hash, signature) == signerAddress, "Signature Failed");   
    //   usedHash[hash] = true;
        for(uint256 i = 1; i <= _count; i++){
            random_id = useRandomAvailableToken(1,1,1);
            tokenId_ = random_id;
            _mint(address(BERRY), tokenId_);
            BERRY.lockedStaking(user, tokenId_);
            freeMintingTime[tokenId_] = block.timestamp;
            tokenIdType[tokenId_] = 1;
        }
        totalFreeMinted[user]+=_count;
        addToMintData(_count);
        claimedUser[msg.sender] = true;
    }

    /*
    *  Owner has to start the Auction before minting
    *  set All prices and time 
    */

    function StartAuction(
        // uint256 _startP, uint256 _discP,

        ) 
        public onlyOwner
    {
        // startingPrice = _startP;
        // discountRate = _discP;
        // startAT = block.timestamp;
        // auctionStarted = true ; 
    }
 

    //  get price of total no of minted Ids 
function getPrice(uint256 _count) public view returns (uint256)
    {
        require(
        auctionStarted == true
        , " AUCTION HAS NOT STARTED YET.! "
        );
        uint256 totalPrice;
        uint256 timeElapsed = (block.timestamp.sub(startAT)).div(priceDecrementTime) ;
        uint256 discount = discountRate.mul(timeElapsed);
        uint256 Price = startingPrice.sub(discount);
        totalPrice = Price.mul(_count);
        if(Price <= 500 ether){
            Price = 500 ether;
            totalPrice = (_count).mul(Price);
        }
        return totalPrice;
    }
    
    /*
    *  Dutch mint Ids
    *  directely move to lockStake
    *  Ids should be random
    */
    function mintDutch(uint256 _count) public
    {
        address user = msg.sender;
        uint256 total = collection[1].collectionSupply;
        // require(
        // totalSupply() + _count <= Dutch_Max_supply
        // ," MAX DUTUCH SUPPLY LIMIT REACHED "
        // );
        // Token.transferFrom(msg.sender,address(this),getPrice(_count));
        uint256 random_id;
        for(uint256 i = 1; i <= _count; i++){
            random_id = useRandomAvailableToken(1,1,2);
            uint256 tokenId = random_id+total;
            _mint(address(BERRY),tokenId);
            BERRY.lockedStaking(user, tokenId);
            dutchMintingTime[tokenId] = block.timestamp;
            tokenIdType[tokenId] = 2;
        }
        totalDutchMinted[msg.sender] += _count;
        addToMintData(_count);
        total_Dutch_Minted += _count;
    }

    function getIdType(uint256 tokenId) public view returns(uint256){
        return tokenIdType[tokenId];
    }

    function setMintingTime(uint256 tokenID) external {
        if(tokenIdType[tokenID] == 1){
            freeMintingTime[tokenID] = 0;
        }
        else if(tokenIdType[tokenID] == 2){
            dutchMintingTime[tokenID] = 0;
        }
    }

    function setTokenIdType(uint256 tokenId) external{
        tokenIdType[tokenId] = 0;
    }

    /*
    * any one can mint here by paying
    * sale must be started
    * random Ids must be fall in given collection
    * Ids directely mint to user's account
    */

    function mintPublic (uint256 _count) public 
    // payable
    {
        // require(publicStarted, "Mint Not Started");
        // require(msg.value >=(_count * publicPrice), "Invalid Klay Sent");
        uint256 total = collection[1].collectionSupply
        +collection[2].collectionSupply;
        // +collection[3].collectionSupply;

        uint256 random_id;
        uint256 tokenId;
        for (uint256 i = 1; i <= _count; i++) {
            random_id = useRandomAvailableToken(1,1,3);
            tokenId = random_id + total;
            _mint(msg.sender, tokenId);
            tokenIdType[tokenId] = 3;
        }
        totalPublicMinted[msg.sender]+=_count;
        addToMintData(_count);
        total_Public_Minted += _count;

    }

    //////////////////////////////////////////////////////////////////////
    //////////////////////  UNCOMMON IDs  ///////////////////////////////

    function setUncommonIds(uint256 _count) public {     // internal

        uint256 random_id ;
        uint256 total = collection[1].collectionSupply
        +collection[2].collectionSupply
        +collection[3].collectionSupply
        +collection[4].collectionSupply;
        for (uint256 i = 1; i <= _count; i++) {
            random_id = useRandomAvailableToken(1,1,5);
            _mint(msg.sender,(random_id + total));
        }
        // totalPublicMinted[msg.sender]+=_count;
        addToMintData(_count); 
        // total_Public_Minted += _count;
    }

    /*
    *  Sale must be started
    *  special Id must be generated by passing two Ids
    *  generated Id must be in given collection
    *  generated Id will be staked in lockedStake
    *  eneterd Ids should be burn
    */


    function mintBreed(uint256 _id1,uint256 _id2) public {
        require(Token.balanceOf(msg.sender) >= genesisPrice,"Don't have enough BCB");
        // require(genesisStarted,"Mint Not Started");
        Token.transferFrom(msg.sender,address(this),genesisPrice);

        // address user = msg.sender;
        uint256 tokenId;
        uint256 random_id;
        uint256 total = collection[1].collectionSupply
        +collection[2].collectionSupply
        +collection[3].collectionSupply
        +collection[4].collectionSupply
        +collection[5].collectionSupply
        ;
        ERC721._burn(_id1);
        ERC721._burn(_id2);
        random_id = useRandomAvailableToken(1,1,6);
        tokenId = random_id+total;
        _mint(msg.sender,tokenId);
        totalBreedMinted[msg.sender] += 1;
        addToMintData(1);
        tokenIdType[tokenId] = 4;
    }

    //  user can caheck minted Ids

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
        for (uint256 i; i < ownerTokenCount; i++) {
        tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokenIds;
    }

    //////////////////////////////////////////////////////////////////////////////////
    //////////////////////////// * Admin Fuctions * /////////////////////////////////


    //  Amount will directely transfer to owner Wallet
    function withDraw () onlyOwner public
    {
        payable(msg.sender).transfer(address(this).balance);
    }

    //  owner will set sale which he wants to start

    function setSale(uint256 saleNo) public {
        if(saleNo == 1){
            if(freeMintStarted == true){
                freeMintStarted=false;
            }
            else{
                freeMintStarted = true;
                auctionStarted=false;
                publicStarted=false;
                genesisStarted=false;
            }
        }
        else if(saleNo == 2){
            if(auctionStarted == true){
                auctionStarted=false;
            }
            else{
                auctionStarted = true;
                freeMintStarted=false;
                publicStarted=false;
                genesisStarted=false;
            }
        }
        else if(saleNo == 3){
            if(publicStarted == true){
                publicStarted=false;
            }
            else{
                publicStarted=true;
                freeMintStarted=false;
                auctionStarted = false;
                genesisStarted=false;
            }
        }
        else if(saleNo == 4){
            if(genesisStarted == true){
                genesisStarted=false;
            }
            else{
                genesisStarted=true;
                publicStarted=false;
                freeMintStarted=false;
                auctionStarted = false;
            }
        }

    }

    function getFreeMintingTime(uint256 tokenId) external view returns(uint256){
      return freeMintingTime[tokenId];
    }
    function getDutchMintingTime(uint256 tokenId) external view returns(uint256){
      return dutchMintingTime[tokenId];
    }


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return prefixURI;
    }

    //////////////////////////////////////////////////////////////////
    //////////////////////////  ADMIN  //////////////////////////////
    function setPrefixURI(string calldata _uri) external onlyOwner {
        require(!lock, "ALREADY_LOCKED");
        prefixURI = _uri;
    }

    function lockBaseURI() external onlyOwner {
        require(!lock, "ALREADY_LOCKED");
        lock = true;
    }

    
    // 0x64f092A447626d6CF213d3498E9F3E30562fBD10
    function addSigner(
        // address _signer,
     BERRY_Staking _stakingAddress) public onlyOwner{
        // signerAddress = _signer;                
        BERRY = _stakingAddress;
    }

    
    function setGenesisPrice(uint256 _tokenAmount) public onlyOwner{
        genesisPrice = _tokenAmount;
    }

    // function will call internally to push the Ids in array of struct

    function addToMintData(uint256 _count) internal {
    (bool _isMinted, uint256 s) = isAlreadyMinted(msg.sender);

        if(_isMinted){
        minteddata[s].amount+=_count;
        }
        else{
        minteddata.push(mintedData(msg.sender,_count));
        }
    }

    function totalMintedAddress()public view returns(uint256){
    return minteddata.length;
    }

    //  check if address is already minted or not 
    function isAlreadyMinted(address _address)
        internal
        view
        returns(bool, uint256)
    {
        for (uint256 s = 0; s < minteddata.length; s += 1){
            if (_address == minteddata[s].mintedAddress) return (true, s);
        }
        return (false, 0);
    }

    /*  
    *  this function will generate randome number
    *  this will work according to given collection given in the arguments
    *  this will automatically fetch the collection and generated the random Id
    */

    function useRandomAvailableToken(uint256 _numToFetch, uint256 _i,uint256 id) internal returns (uint256)
    {
        uint256 valAtIndex;
        uint256 lastIndex;
        uint256 randomNum = 
        uint256(
        keccak256(
        abi.encode(msg.sender,tx.gasprice,block.number,block.timestamp,blockhash(block.number - 1),_numToFetch,_i)));

        uint256 randomIndex = (randomNum % collection[id].availableTokens);
        if(id==1){
        valAtIndex = _firstCollection[randomIndex];
        lastIndex = collection[id].availableTokens - 1;
        if (randomIndex != lastIndex) {
            uint256 lastValInArray =_firstCollection[lastIndex];
            if (lastValInArray == 0) {
                _firstCollection[randomIndex] = lastIndex;
            } else {
                _firstCollection[randomIndex] = lastValInArray;
            }
        }
        }else if(id==2){
        valAtIndex = _secondCollection[randomIndex];
        lastIndex = collection[id].availableTokens - 1;
        if (randomIndex != lastIndex) {
            uint256 lastValInArray = _secondCollection[lastIndex];
            if (lastValInArray == 0) {
                _secondCollection[randomIndex] = lastIndex;
            } else {
                _secondCollection[randomIndex] = lastValInArray;
            }
        }  
        }else if(id==3){
        valAtIndex = _thirdCollection[randomIndex];
        lastIndex = collection[id].availableTokens - 1;
        uint256 lastValInArray;
        if (randomIndex != lastIndex) {
            lastValInArray = _thirdCollection[lastIndex];
            if (lastValInArray == 0) {
                _thirdCollection[randomIndex] = lastIndex;
            } else {
                _thirdCollection[randomIndex] = lastValInArray;
            }
        }  
        }else if(id==4){
        valAtIndex = _fourthCollection[randomIndex];
        lastIndex = collection[id].availableTokens - 1;
        if (randomIndex != lastIndex) {
            uint256 lastValInArray = _fourthCollection[lastIndex];
            if (lastValInArray == 0) {
                _fourthCollection[randomIndex] = lastIndex;
            } else {
                _fourthCollection[randomIndex] = lastValInArray;
            }
        }
        }

        else if(id==5){
        valAtIndex = _fifthCollection[randomIndex];
        lastIndex = collection[id].availableTokens - 1;
        if (randomIndex != lastIndex) {
            uint256 lastValInArray = _fifthCollection[lastIndex];
            if (lastValInArray == 0) {
                _fifthCollection[randomIndex] = lastIndex;
            } else {
                _fifthCollection[randomIndex] = lastValInArray;
            }
        }
        }

        else if(id==6){
        valAtIndex = _sixthCollection[randomIndex];
        lastIndex = collection[id].availableTokens - 1;
        if (randomIndex != lastIndex) {
            uint256 lastValInArray = _sixthCollection[lastIndex];
            if (lastValInArray == 0) {
                _sixthCollection[randomIndex] = lastIndex;
            } else {
                _sixthCollection[randomIndex] = lastValInArray;
            }
        }
        }

        uint256 result;
        if (valAtIndex == 0) {
            result = randomIndex;
        } else {
            result = valAtIndex;
        }
        collection[id].availableTokens--;
        return result;
    }

    //////////////////////////////////////////////////////////////////
    //////////////////////////////////////////////////////////////////

    bool randomBoxStatus = true;
    uint256 public randomTokenAmount = 1000;
    uint256 public cashOdd = 45;
    uint256 public commonOdd = 27;
    uint256 public uncommonOdd = 12;
    uint256 public rareOdd = 10;
    uint256 public epicOdd = 3;
    uint256 public legendaryOdd = 2;
    uint256 public mythicOdd = 1;
    uint256[100] randomBoxProbability = [1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
                                        ,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2
                                        ,3,3,3,3,3,3,3,3,3,3,3,3,4,4,4,4,4,4,4,4,4,4,5,5,5,6,6,7];

    function CloseRandomBox() public onlyOwner{
        if(!randomBoxStatus){
            randomBoxStatus = true;
        }
        else{
            randomBoxStatus = false;
        }
    }

    function RandomBox() public {
        require(randomBoxStatus != false, "no more availability for Random box");
        uint256 randomNo = uint256(keccak256(abi.encodePacked(msg.sender, block.timestamp, block.number, blockhash(block.number -1), randomBoxProbability.length)));
        uint256 randomId = randomNo % randomBoxProbability.length;
        // uint256 randomTokenId;
        // return randomId;

        if(randomBoxProbability[randomId] == 1){
            BCASH.transfer(msg.sender, randomTokenAmount);
        }
        else if(randomBoxProbability[randomId] == 2){
            Token.transferFrom(address(this), msg.sender, randomTokenAmount);
        }
        else if(randomBoxProbability[randomId] == 3){
            setUncommonIds(10);    //   400
        }
        else if(randomBoxProbability[randomId] == 4){
            //  NFT from opensea
        }
        else if(randomBoxProbability[randomId] == 5){
            payable(msg.sender).transfer(10 ether);   // 1000 klay
        }
        else if(randomBoxProbability[randomId] == 6){
            payable(msg.sender).transfer(20 ether);   // 2000 klay
        }
        else if(randomBoxProbability[randomId] == 7){
            // booster card
        }

    }


    //  Collections that are set according to given requirements
    function setCollectionData() internal {

        collection[1].collectionSupply = 100;
        collection[1].availableTokens = 100;   //  freeMint  1000

        collection[2].collectionSupply = 200;
        collection[2].availableTokens = 200;   //  dutchMint  2000

        collection[3].collectionSupply = 450;
        collection[3].availableTokens = 450;   //  publicMint  4500

        collection[4].collectionSupply = 10;
        collection[4].availableTokens = 10;   //  ownerMint  4500

        collection[5].collectionSupply = 40;
        collection[5].availableTokens = 40;   //  uncommon (from common collection) 400

        collection[6].collectionSupply = 200;
        collection[6].availableTokens = 200;   //  Breeding 2000
    }
}