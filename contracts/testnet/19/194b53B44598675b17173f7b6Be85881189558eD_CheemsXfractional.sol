// contracts/NFT.sol
// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

library Address {
    function isContract(address account) internal view returns (bool) { 
        uint256 size; assembly { size := extcodesize(account) } return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");(bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
        
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
        
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) { return returndata; } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {revert(errorMessage);}
        }
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {this; return msg.data;}
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
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
}

abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }   
    
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }


   function getTime() public view returns (uint256) {
        return block.timestamp;
    }

}

contract CheemsXfractional is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    uint[11] public max_Regular_tier;
    uint public maxTier0 = 10_000_000;
    uint[11] public price;
    uint[11] public maxWalletLimit;
    string[11] public defaultURI;
    address public currencyToken; // default 0 means avax
    address treasureWallet = 0xf827c3E5fD68e78aa092245D442398E12988901C;
    address XYZToken = 0xb0b598FCd066058a83FEa073d56522b5BaE0522B;
    uint priceDivisor = 1000;
    bool upgradable = false;

    mapping(uint=>uint) public tBalance;

    uint8 mintOption = 0;

    mapping(address => bool) public whiteList;
    struct UserInfo {
        mapping(uint => uint[]) amount;
        uint tier0; 
    }
    mapping(address => UserInfo) public userInfo;
    mapping(uint => uint) public tierInfo;
    mapping(address => bool) public examptMaxAmountUser;

    event UodateURI(address indexed user, bool success);
    event UpgradeNFTByAvax(address indexed user, uint amount, uint cal);
    
    constructor() ERC721("CheemsXfractional NFT", "CXN") {
        max_Regular_tier[0] = 10000;
        max_Regular_tier[1] = 5000;
        max_Regular_tier[2] = 2500;
        max_Regular_tier[3] = 1600;
        max_Regular_tier[4] = 500;
        max_Regular_tier[5] = 400;
        max_Regular_tier[6] = 200;
        max_Regular_tier[7] = 100;
        max_Regular_tier[8] = 20;
        max_Regular_tier[9] = 10;
        max_Regular_tier[10] = 10000000;

        price[0] = 5 * 1000;
        price[1] = 10 * 1000;
        price[2] = 20 * 1000;
        price[3] = 30 * 1000;
        price[4] = 40 * 1000;
        price[5] = 50 * 1000;
        price[6] = 80 * 1000;
        price[7] = 100 * 1000;
        price[8] = 500 * 1000;
        price[9] = 1000 * 1000;
        price[10] = 5;

        maxWalletLimit[0] = 100;
        maxWalletLimit[1] = 50;
        maxWalletLimit[2] = 25;
        maxWalletLimit[3] = 16;
        maxWalletLimit[4] = 5;
        maxWalletLimit[5] = 4;
        maxWalletLimit[6] = 2;
        maxWalletLimit[7] = 1;
        maxWalletLimit[8] = 1;
        maxWalletLimit[9] = 1;
        maxWalletLimit[10] = 0;

        defaultURI[0] = "https://gateway.pinata.cloud/ipfs/QmaFxL15oSodfwnpJ5exy3sHN6zb6v8wiCxhdL99Lj75Ak";
        defaultURI[1] = "https://gateway.pinata.cloud/ipfs/QmXZYdzV8tvwqcCoxaLbUWaGtpaFqZ5SMyLATb7gJQvNqW";
        defaultURI[2] = "https://gateway.pinata.cloud/ipfs/QmZxJJaE52r81oWskh66tayeuzArtEeL3bC1Y9mtFKRmZd";
        defaultURI[3] = "https://gateway.pinata.cloud/ipfs/QmQdK9a64aK7yuEnMuivHywmwS9EbSQT2o8TxNxwyPQFtP";
        defaultURI[4] = "https://gateway.pinata.cloud/ipfs/QmaFxL15oSodfwnpJ5exy3sHN6zb6v8wiCxhdL99Lj75Ak";
        defaultURI[5] = "https://gateway.pinata.cloud/ipfs/QmaFxL15oSodfwnpJ5exy3sHN6zb6v8wiCxhdL99Lj75Ak";
        defaultURI[6] = "https://gateway.pinata.cloud/ipfs/QmaFxL15oSodfwnpJ5exy3sHN6zb6v8wiCxhdL99Lj75Ak";
        defaultURI[7] = "https://gateway.pinata.cloud/ipfs/QmaFxL15oSodfwnpJ5exy3sHN6zb6v8wiCxhdL99Lj75Ak";
        defaultURI[8] = "https://gateway.pinata.cloud/ipfs/QmaFxL15oSodfwnpJ5exy3sHN6zb6v8wiCxhdL99Lj75Ak";
        defaultURI[9] = "https://gateway.pinata.cloud/ipfs/QmaFxL15oSodfwnpJ5exy3sHN6zb6v8wiCxhdL99Lj75Ak";
        defaultURI[10] = "https://gateway.pinata.cloud/ipfs/QmaFxL15oSodfwnpJ5exy3sHN6zb6v8wiCxhdL99Lj75Ak";

        examptMaxAmountUser[address(this)] = true;

        tierInfo[0] = 10;  // tire0 hard coded
        whiteList[address(this)] = true;
        whiteList[_msgSender()] = true;
    }

    function setMintOption( uint8 option ) public onlyOwner {
        require(option < 3, "invalid option");
        mintOption = option;
    }

    function setXYZtoken(address token) public onlyOwner {
        XYZToken = token;
    }

    function setWhiteList(address[] memory users, bool flag) public onlyOwner {
        for(uint i = 0; i < users.length; i++) {
            whiteList[users[i]] = flag;
        }
    }

    function updateDefaultURI(uint tier, string memory uri) public onlyOwner {
        require(tier < 10, "invalid tier");
        defaultURI[tier] = uri;
    }

    function updateURI(uint tokenId, string memory uri) public returns(bool) {
        if((owner() == msg.sender && mintOption == 0) ||
           (whiteList[msg.sender] && mintOption == 1) || 
           (mintOption == 2) ) {
            _setTokenURI(tokenId, uri);
            emit UodateURI(_msgSender(), true);
            return true;
        }
        emit UodateURI(_msgSender(), false);
        return false;
        
    }

    function setNFTmintCurrency(address token) public onlyOwner {
        currencyToken = token;
    }

    function setTreasureWallet(address wallet) public onlyOwner {
        treasureWallet = wallet;
    }

    function sendAllBalance(address token) public onlyOwner {
        IERC20(token).transfer(treasureWallet, IERC20(token).balanceOf(address(this)));
    }

    function sendAllAvaxToTreasure() public onlyOwner {
        payable(treasureWallet).transfer(address(this).balance);
    }

    function setExamptMaxAmountUser(address user, bool flag) public onlyOwner {
        examptMaxAmountUser[user] = flag;
    }

    receive() external payable { }
    function mintNFTWithAvax(address wallet, uint tie, string memory uri) public payable { 
        require(currencyToken == address(0), "invalid Currency0");
        require(tie < 11, "invalid tie");
        uint amount = price[tie];
        require(msg.value == amount * 10 ** 18 / priceDivisor, "not eq value");
        mintNFT(wallet, tie, uri);
    }

    function mintNFTWithToken(address wallet, uint tie, string memory uri) public {
        require(currencyToken != address(0), "invalid Currency1");
        require(tie < 11, "invalid tie");
        uint amount = price[tie];
        IERC20(currencyToken).transferFrom(_msgSender(), address(this), amount * 10 ** IERC20Metadata(currencyToken).decimals() / priceDivisor);
        mintNFT(wallet, tie, uri);
    }
    
    function mintNFT(address wallet, uint tier, string memory uri) private {
        if((owner() == msg.sender && mintOption == 0) ||
           (whiteList[msg.sender] && mintOption == 1) || 
           (mintOption == 2) ) {
            uint tokenId;
            if(tier == 10) {
                require(canMint(tier, 1), "limit mint");
                userInfo[address(this)].tier0 ++;
                _tier0transferFrom(address(this), wallet, 1);
                return;
            }
            uint[] storage nftList = userInfo[address(this)].amount[tier];
            if(nftList.length > 0) {
                tokenId = nftList[nftList.length - 1];
            } else {
                require(canMint(tier, 1), "limit mint");
                _tokenIds.increment();
                tokenId = _tokenIds.current();
                _safeMint(address(this), tokenId);
                tierInfo[tokenId] = tier;
                nftList.push(tokenId);
            }
            IERC721Metadata(address(this)).approve(wallet, tokenId);
            transferFrom(address(this), wallet, tokenId);
            _setTokenURI(tokenId, uri);
            
        } else {
            require(false, "invalid Option");
        }
    }

    function canMint(uint tier, uint amount) public view returns(bool) {
        if(tier < 10 && (tBalance[tier] + amount) <= max_Regular_tier[tier] && getMintedTotalAmount() + maxTier0 / max_Regular_tier[tier] * amount <= maxTier0 * 10) return true;
        else if(tier == 10 && getMintedTotalAmount() + amount <= maxTier0 * 10) return true;
        return false;
    }

    function getUserTotalAmount(address wallet) private view returns(uint) {
        uint amount = 0;
        for(uint i = 0; i < 10; i++) {
            uint[] storage nftList = userInfo[wallet].amount[i];
            amount += maxTier0 / max_Regular_tier[i] * nftList.length;
        }
        return amount + userInfo[wallet].tier0;
    }

    function getMintedTotalAmount() private view returns(uint) {
        uint amount = 0;
        for(uint i = 0; i <= 10; i++) {
            uint nftList = tBalance[i];
            amount += maxTier0 / max_Regular_tier[i] * nftList;
        }
        return amount;
    }

    function getMaxUserAmount() private view returns(uint) {
        uint amount = 0;
        for(uint i = 0; i <= 10; i++) {
            amount += maxWalletLimit[i] * maxTier0 / max_Regular_tier[i];
        }
        return amount;
    }

    function tier0transfer(address to, uint amount) public {
        require(_msgSender() != to, "Invalid to");
        _tier0transferFrom(_msgSender(), to, amount);
    }

    function _tier0transferFrom(address from, address to, uint amount) private {
        require(userInfo[from].tier0 >= amount, "insufficeint balance");
        require(canTransfer(to, 0, amount), "exceed max amount2");
        userInfo[from].tier0 -= amount;
        userInfo[to].tier0 += amount;
        if(from == address(this)) {
            tBalance[tierInfo[0]] += amount;
        }
        if( to == address(this) ) {
            tBalance[tierInfo[0]] -= amount;
        }
    }

    function transferFrom (address from, address to, uint tokenId) public override {
        transferNFT(from, to, tokenId);
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom (address from, address to, uint tokenId) public override {
        transferNFT(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom (address from, address to, uint256 tokenId, bytes memory _data) public override {
        transferNFT(from, to, tokenId);
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function canTransfer(address to, uint tokenId, uint amount) public view returns(bool) {
        uint tier = tierInfo[tokenId];
        
        if(examptMaxAmountUser[to] == true) return true;
        if(examptMaxAmountUser[to] == false && tier == 10 && getUserTotalAmount(to) + amount  <= getMaxUserAmount() ) return true;
        else if(tier == 10) return false;
        uint normalTierLen = userInfo[to].amount[tier].length;
        if(examptMaxAmountUser[to] == false && 
            tier < 10 && (normalTierLen + amount) <= maxWalletLimit[tier] && 
            getUserTotalAmount(to) + maxTier0 / max_Regular_tier[tier]  <= getMaxUserAmount() ) return true;
        
        return false;
    }

    function transferNFT(address from, address to, uint tokenId) private {
        uint[] storage fromTokenList = userInfo[from].amount[tierInfo[tokenId]];
        uint[] storage toTokenList = userInfo[to].amount[tierInfo[tokenId]];
        require(canTransfer(to, tokenId, 1), "exceed max amount1");

        bool flag = false;
        for(uint i = 0; i < fromTokenList.length; i++) {
            if(tokenId == fromTokenList[i]) {
                fromTokenList[i] = fromTokenList[fromTokenList.length - 1];
                fromTokenList.pop();
                flag = true;
                break;
            }
        }
        require(flag, "from has no tokenId");
        toTokenList.push(tokenId);
        if(from == address(this)) {
            tBalance[tierInfo[tokenId]]++;
        }
        if( to == address(this) ) {
            tBalance[tierInfo[tokenId]]--;
        }
    }

    function downgradeNFT(uint nftId, uint tierGroup) public {
        require(upgradable, "no permission");
        uint tier = tierInfo[nftId];
        require(tier < 10 && tierGroup < 10 && tierGroup < tier, "invalid tier");
        uint tier0From = maxTier0 / max_Regular_tier[tier];
        uint tier0To = maxTier0 / max_Regular_tier[tierGroup];
        transferFrom(_msgSender(), address(this), nftId);
        mintNFT(_msgSender(), tierGroup, defaultURI[tierGroup]);
        if(userInfo[address(this)].tier0 < tier0From - tier0To) {
            require(canMint(10, tier0From - tier0To), "limit mint");
            userInfo[address(this)].tier0 = tier0From - tier0To;
        }
        _tier0transferFrom(address(this), _msgSender(), tier0From - tier0To);
    }

    function upgradeNFTByAvax(uint nftId, uint tierGroup) public payable {
        require(upgradable, "no permission");
        require(currencyToken == address(0), "invalid Currency0");
        uint tier = tierInfo[nftId];
        uint amount = price[tierGroup] - price[tier];
        emit UpgradeNFTByAvax(msg.sender, msg.value, amount * 10 ** 18 / priceDivisor);
        require(msg.value == amount * 10 ** 18 / priceDivisor, "not eq value");
        
        require(tier < 10 && tierGroup < 10 && tierGroup > tier, "invalid tier");
        transferFrom(_msgSender(), address(this), nftId);
        mintNFT(_msgSender(), tierGroup, defaultURI[tierGroup]);
    }

    function upgradeNFT(uint nftId, uint tierGroup) public {
        require(upgradable, "no permission");
        require(currencyToken != address(0), "invalid Currency0");
        uint tier = tierInfo[nftId];
        uint amount = price[tier];
        IERC20(currencyToken).transferFrom(_msgSender(), address(this), amount * 10 ** IERC20Metadata(currencyToken).decimals() / priceDivisor / (maxTier0 / max_Regular_tier[tier]));
        
        require(tier < 10 && tierGroup < 10 && tierGroup > tier, "invalid tier");
        transferFrom(_msgSender(), address(this), nftId);
        mintNFT(_msgSender(), tierGroup, defaultURI[tierGroup]);
    }

    function setUpgradable(bool flag) public onlyOwner {
        upgradable = flag;
    }

    function aggregation(uint amount, uint tierGroup) public {
        require(userInfo[_msgSender()].tier0 >= amount, "Insufficient amount");
        require(amount >= maxTier0 / max_Regular_tier[tierGroup], "too small");
        require(tierGroup < 10, "Invalid tier");
        uint _amount = amount / (maxTier0 / max_Regular_tier[tierGroup]) * (maxTier0 / max_Regular_tier[tierGroup]);
        _tier0transferFrom(_msgSender(), address(this), _amount);

        for (uint i = 0; i < amount / (maxTier0 / max_Regular_tier[tierGroup]); i++) {
            mintNFT(_msgSender(), tierGroup, defaultURI[tierGroup]);
        }
    }

    function fractionalize(uint tokenId) public {
        uint tier = tierInfo[tokenId];
        uint amount = maxTier0 / max_Regular_tier[tier];
        transferFrom(_msgSender(), address(this), tokenId);
        if(userInfo[address(this)].tier0 < amount) {
            require(canMint(10, amount), "limit mint");
            userInfo[address(this)].tier0 = amount;
        }
        _tier0transferFrom(address(this), _msgSender(), amount);
    }

    function exchangeXYZAndTiero(uint amount, bool buyTier0) public {
        if(buyTier0) {
            if(userInfo[address(this)].tier0 < amount) {
                require(canMint(10, amount), "limit mint");
                userInfo[address(this)].tier0 = amount;
            }
            IERC20(XYZToken).transferFrom(_msgSender(), address(this), amount * 10 ** IERC20Metadata(XYZToken).decimals());
            _tier0transferFrom(address(this), _msgSender(), amount);
        } else {
            _tier0transferFrom(_msgSender(),address(this), amount);
            IERC20(XYZToken).transfer(_msgSender(), amount * 10 ** IERC20Metadata(XYZToken).decimals());
        }
        
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }


    // function getAmount(address user) public view returns(uint) {  // for test
    //     return user.balance;
    // }

    // function getLen(address user, uint tire) public view returns(uint) { // for test
    //     if(tire == 10) return userInfo[user].tier0;
    //     return userInfo[user].amount[tire].length;
    // }

    // function getInfo(address user, uint tier) public view returns(uint[] memory res) {
    //     res = userInfo[user].amount[tier];
    //     return res;
    // }
}