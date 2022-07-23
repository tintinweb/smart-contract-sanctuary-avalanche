// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom.
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _value - the sale price of the NFT asset specified by _tokenId
    /// @return _receiver - address of who should be sent the royalty payment
    /// @return _royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}


pragma solidity ^0.8.0;

import "ERC165.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

pragma solidity ^0.8.0;

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is ERC2981Base {
    RoyaltyInfo private _royalties;

    /// @dev Sets token royalties
    /// @param recipient recipient of the royalties
    /// @param value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(address recipient, uint256 value) internal {
        require(value <= 10000, 'ERC2981Royalties: Too high');
        _royalties = RoyaltyInfo(recipient, uint24(value));
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(uint256, uint256 value)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (value * royalties.amount) / 10000;
    }
}

pragma solidity >=0.8.7 <0.9.0;

import "ERC721Enumerable.sol";
import "Ownable.sol";
import "VRFCoordinatorV2Interface.sol";
import "VRFConsumerBaseV2.sol";


contract IlleooNFT is ERC721Enumerable, Ownable, VRFConsumerBaseV2, ERC2981ContractWideRoyalties {
  using Strings for uint256;

  string public baseURI;
  uint256 public cost = 0.5 ether;
  uint256 public constant maxSupply = 1200;
  uint256 public maxMintAmount = 10;
  uint256 public treasuryMintedAmount = 0;
  bool public paused = false;
  bool public revealed = false;
  string public notRevealedUri;
  address[] public artistAddresses;
  mapping(address => uint32) public royaltiesSplit;
  
  // ChainLink VRF
  VRFCoordinatorV2Interface COORDINATOR;
  uint64 s_subscriptionId;
  address vrfCoordinator = 0xd5D517aBE5cF79B7e95eC98dB0f0277788aFF634;
  bytes32 keyHash = 0x89630569c9567e43c4fe7b1633258df9f2531b62f2352fa721cf3162ee4ecb46;

  uint32 callbackGasLimit = 100000;
  uint16 requestConfirmations = 3;

  uint256 public offset;
  uint256 public s_requestId;
  address s_owner;

  constructor(
    string memory _name,
    string memory _symbol,
    string memory _initBaseURI,
    string memory _initNotRevealedUri,
    address[] memory _artistAddresses,
    uint32[] memory _royaltiesSplit,
    uint64 subscriptionId
  ) ERC721(_name, _symbol)
   VRFConsumerBaseV2(vrfCoordinator) {
    // vrf setup
    COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator);
    s_owner = msg.sender;
    s_subscriptionId = subscriptionId;
    
    // nft init
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
    
    // set royalties
    _setRoyalties(msg.sender, 1000);

    // set artist royalties
    for(uint i=0;i<_artistAddresses.length;i++){
      artistAddresses.push(_artistAddresses[i]);
      royaltiesSplit[_artistAddresses[i]] = _royaltiesSplit[i];
    }

    // pre-mint 60 NFTs for community & partner airdrops
    for (uint256 m = 1; m <= 20; m++) {
      _safeMint(msg.sender, m);
    }
    treasuryMintedAmount = 20;
    paused = true;
  }

  /// @inheritdoc	ERC165
  function supportsInterface(bytes4 interfaceId)
      public
      view
      virtual
      override(ERC721Enumerable, ERC2981Base)
      returns (bool)
  {
      return super.supportsInterface(interfaceId);
  }

  function fulfillRandomWords(
    uint256, /* requestId */
    uint256[] memory randomWords
  ) internal override {
    // set offset 
    offset = (randomWords[0] % maxSupply) + 1;
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  function _offsetId(uint256 _tokenid) internal view virtual returns (uint256) {
    return (_tokenid + offset > maxSupply) ? _tokenid + offset - maxSupply : _tokenid + offset;
  }

  // public
  function mint(address _to, uint256 _mintAmount) public payable {
    uint256 supply = totalSupply();
    require(!paused);
    require(_mintAmount > 0);
    require(_mintAmount <= maxMintAmount);
    require(supply + _mintAmount <= maxSupply);
    uint256 incrementTreasuryMintedAmount = 0;
    if (msg.sender != owner() && treasuryMintedAmount + _mintAmount <= 60 ) {
      require(msg.value >= cost * _mintAmount);
    }else{
      incrementTreasuryMintedAmount = _mintAmount;
    }

    for (uint256 i = 1; i <= _mintAmount; i++) {
      _safeMint(_to, supply + i);
    }
    if(incrementTreasuryMintedAmount > 0){
      treasuryMintedAmount += incrementTreasuryMintedAmount; 
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
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
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _offsetId(tokenId).toString(), ".json"))
        : "";
  }

  //only owner
  function reveal() public onlyOwner {
    // request random number vrf & trigger offset update
    s_requestId = COORDINATOR.requestRandomWords(
      keyHash,
      s_subscriptionId,
      requestConfirmations,
      callbackGasLimit,
      1
    );

    cost = 0.75 ether;
    revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner {
    cost = _newCost;
  }

  function setmaxMintAmount(uint256 _newmaxMintAmount) public onlyOwner {
    maxMintAmount = _newmaxMintAmount;
  }
  
  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }

  function withdraw() public payable onlyOwner {
    // Distribute royalties
    uint256 currentBalance = address(this).balance;
    for(uint i = 0; i < artistAddresses.length; i++){
      (bool hs, ) = payable(artistAddresses[i]).call{value: currentBalance * royaltiesSplit[artistAddresses[i]] / 100}("");
      require(hs);
    }
  }

  function emergencyWithdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }
  
  /// @notice Allows to set the royalties on the contract
  /// @param recipient the royalties recipient
  /// @param value royalties value (between 0 and 10000)
  function setRoyalties(address recipient, uint256 value) public onlyOwner {
      _setRoyalties(recipient, value);
  }
  
}