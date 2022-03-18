/**
 *Submitted for verification at snowtrace.io on 2022-03-17
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-23
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-09
*/

// SPDX-License-Identifier: MIT
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
 
interface IERC721Receiver { 
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
interface IERC721Metadata is IERC721 { 
    function name() external view returns (string memory); 
    function symbol() external view returns (string memory); 
    function tokenURI(uint256 tokenId) external view returns (string memory);
} 
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex = 0;

  uint256 internal immutable collectionSize;
  uint256 internal immutable maxBatchSize; 
  string private _name; 
  string private _symbol; 
  mapping(uint256 => TokenOwnership) private _ownerships; 
  mapping(address => AddressData) private _addressData; 
  mapping(uint256 => address) private _tokenApprovals; 
  mapping(address => mapping(address => bool)) private _operatorApprovals; 
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) {
    require(
      collectionSize_ > 0,
      "ERC721A: collection must have a nonzero supply"
    );
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
  } 
  function totalSupply() public view override returns (uint256) {
    return currentIndex;
  } 
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  } 
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  } 
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  } 
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    require(_exists(tokenId), "ERC721A: owner query for nonexistent token");

    uint256 lowestTokenToCheck;
    if (tokenId >= maxBatchSize) {
      lowestTokenToCheck = tokenId - maxBatchSize + 1;
    }

    for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
      TokenOwnership memory ownership = _ownerships[curr];
      if (ownership.addr != address(0)) {
        return ownership;
      }
    }

    revert("ERC721A: unable to determine the owner of token");
  } 
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
  } 
  function name() public view virtual override returns (string memory) {
    return _name;
  } 
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  } 
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString(),_getUriExtension()))
        : "";
  } 
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  function _getUriExtension() internal view virtual returns (string memory) {
    return "";
  }
 
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  } 
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  } 
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }
 
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }
 
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  } 
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    safeTransferFrom(from, to, tokenId, "");
  } 
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  } 
  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity) internal {
    _safeMint(to, quantity, "");
  } 
  function _safeMint(
    address to,
    uint256 quantity,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address"); 
    require(!_exists(startTokenId), "ERC721A: token already minted");
    require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + uint128(quantity)
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  } 
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1); 
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp)); 
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  } 
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0; 
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    } 
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
  } 
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
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
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {} 
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}

contract GnomeNodes is Ownable, ERC721A, ReentrancyGuard {
    using Strings for uint256;


  uint256 public MAX_PER_Transtion = 3; // maximam amount that user can mint
//   uint256 public MAX_PER_Address = 5; // maximam amount that user can mint

  uint256 public  PRICE = 1 ether;

  uint256 private constant TotalCollectionSize_ = 6666; // total number of nfts
  uint256 private constant MaxMintPerBatch_ = 20; //max mint per traction

  bool public _revelNFT = true;
  string private _baseTokenURI;
  string private _uriBeforeRevel;

  uint public status = 0; //0-pause 1-whitelist 2-public

  mapping(address => bool) private whitelistedAddresses;

  constructor() ERC721A("Gnome Nodes","GNFT", MaxMintPerBatch_, TotalCollectionSize_) {
    _uriBeforeRevel = "https://gateway.pinata.cloud/ipfs/QmPxUD4ztRB8usVei3h4YkfdbRG2E9RFyQZ4SYt5DUHDfN";
    
    whitelistedAddresses[0xCd76aB24A72181dA527885ff56Db2A23d820dF2e] = true;
    whitelistedAddresses[0xb61e1Bdf53f6E29C7743bE86a792A93B831Af25D] = true;
    whitelistedAddresses[0x00a7A0ca317eA028de85F17a26053A56da22f431] = true;
    whitelistedAddresses[0xE396051F56BB91f7FFd789395B8a08E1D25b1887] = true;
    whitelistedAddresses[0x71DFAaAc37114220d59EB33059bb082bf96EF356] = true;
    whitelistedAddresses[0xa9C8a1F54d8Df6089c22Bc267B070ECA8b06f0b5] = true;
    whitelistedAddresses[0x3f23bb455ea87b21D828B4aEE25eeFb1eb6fFA0C] = true;
    whitelistedAddresses[0xDECb8c3737Dc9d119eC22eE80584D6f3B8e9A46d] = true;
    whitelistedAddresses[0xf7988D267E4634c282b2d90946FFBb9968B311C4] = true;
    whitelistedAddresses[0xF754BFB09978C3E47512209A7c90fC517b51a8cB] = true;
    whitelistedAddresses[0x030622256B525a2d0AB0Ff7D4250eb6aD1051AeE] = true;
    whitelistedAddresses[0xfF0A5AB94a698C0C1D2Ee60bE0ba1dF18872BD3D] = true;
    whitelistedAddresses[0x4Aa90d4ccdD949887AB4EDED02919Eb98cC5E246] = true;
    whitelistedAddresses[0x109f00BABA4dbAc0dAc465C7C7A395b0cA08F2b1] = true;
    whitelistedAddresses[0x1bce5BFE8b7562Ff1675a6C480b668D955c43622] = true;
    whitelistedAddresses[0xcFae097e995b460E5E48962D808E4886F199cBBd] = true;
    whitelistedAddresses[0xacF9CA6400Db21f38053Dc0bd1D564D0F528aa90] = true;
    whitelistedAddresses[0xB8545d529234eB2848C85c0CcC0a5Ce9B30a3C0b] = true;
    whitelistedAddresses[0x35584001aCa864F556c433dE0663280947B476A0] = true;
    whitelistedAddresses[0x3419c49ca692c3113F0656Ba94364160b3e6cf4e] = true;
    whitelistedAddresses[0x5Df74e062b676B208020889C67fB11d9b5F39C35] = true;
    whitelistedAddresses[0x9D56bD6DCF09F04c6A2cfBe041f2fdDC262C76dc] = true;
    whitelistedAddresses[0x0ff3A49f52B1325a5269aD2112Fe9Dad4F060DC5] = true;
    whitelistedAddresses[0x566668cdFAAFC6F01f42DbF7612806Bf00073EEf] = true;
    whitelistedAddresses[0xC25cea4227fA68348F025A8C09768378D338F8d6] = true;
    whitelistedAddresses[0xe9Fe57596bC83bf2dbB7966f5ba2F062090F281c] = true;
    whitelistedAddresses[0x0E01800b3Edf3933657d08aa39FE2152FC325E97] = true;
    whitelistedAddresses[0x6dE10a858C99E624f8D95E5E45499963E7DaC205] = true;
    whitelistedAddresses[0xF754BFB09978C3E47512209A7c90fC517b51a8cB] = true;
    whitelistedAddresses[0xC88519FEd31aEc98E8981BEF94D22756e734301F] = true;
    whitelistedAddresses[0x3fE14177e9b5F616F68aE9cdC78eE52F83B0655c] = true;
    whitelistedAddresses[0xc61C0E198A11c0476F931f93731A5D87E4569ad1] = true;
    whitelistedAddresses[0x4F70383C9C873c8eD112A96106Cffc3B4d17d796] = true;
    whitelistedAddresses[0x3d6eacC05d241A5ac22aABA01F10f76FF2bEe1d7] = true;
    whitelistedAddresses[0xABE78B6F3e01204eBe940496E71cEed3043B676E] = true;
    whitelistedAddresses[0x4Aa90d4ccdD949887AB4EDED02919Eb98cC5E246] = true;
    whitelistedAddresses[0xC0B120aB342D7C89cef722a51b5cCfCE8Ca3773D] = true;
  }

  modifier callerIsUser() {
    require(tx.origin == msg.sender, "The caller is another contract");
    _;
  }
 
  function mint(uint256 quantity) external payable callerIsUser {
    require(status == 1 && whitelistedAddresses[msg.sender] || status == 2 , "Sale is not Active");
    require(totalSupply() + quantity <= collectionSize, "reached max supply");
    require(  quantity <= MAX_PER_Transtion,"can not mint this many");
    require(msg.value >= PRICE * quantity, "Need to send more AVAX.");
    _safeMint(msg.sender, quantity);   
  }

   function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
    require(_exists(tokenId),"ERC721Metadata: URI query for nonexistent token");
    if(_revelNFT){
    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
    } else{
      return _uriBeforeRevel;
    }
  }

  function isWhitelisted(address _user) public view returns (bool) {
    return whitelistedAddresses[_user];
  }

  
  function addNewWhitelistUsers(address[] calldata _users) public onlyOwner {
    // ["","",""]
    for(uint i=0;i<_users.length;i++)
        whitelistedAddresses[_users[i]] = true;
  }

  function setURIbeforeRevel(string memory URI) external onlyOwner {
    _uriBeforeRevel = URI;
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _baseTokenURI = baseURI;
  }
  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }
  function numberMinted(address owner) public view returns (uint256) {
    return _numberMinted(owner);
  }
  function getOwnershipData(uint256 tokenId)
    external
    view
    returns (TokenOwnership memory)
  {
    return ownershipOf(tokenId);
  }
  function withdrawMoney() external onlyOwner nonReentrant {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
  }
  function changeRevelStatus() external onlyOwner {
    _revelNFT = !_revelNFT;
  }
  function changeMintPrice(uint256 _newPrice) external onlyOwner
  {
      PRICE = _newPrice;
  }
  function changeMAX_PER_Transtion(uint256 q) external onlyOwner
  {
      MAX_PER_Transtion = q;
  }
//   function changeMAX_PER_Address(uint256 q) external onlyOwner
//   {
//       MAX_PER_Address = q;
//   }
  function setStatus(uint256 s)external onlyOwner{
      status = s;
  }
  function getStatus()public view returns(uint){
      return status;
  }
  function getPrice()public view returns(uint){
      return PRICE;
  }
  function giveaway(address a, uint q)public onlyOwner{
    _safeMint(a, q);
  }
}