// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./Ownable.sol";
import "./IERC20.sol";
import "./Counters.sol";

contract CloversNFT is ERC721, Ownable {
    using Strings for uint256;
    using Counters for Counters.Counter;

    uint256 public maxMintAmountForTX = 5;
    uint256 public MintCap = 5;
    uint256 public MintCapPlatinumMember = 2;
    bool public paused = false;
    bool public onlyWhitelisted = false;
    bool public onlyPlatinumMember = false;
    bool public MintCapState = false;
    address[] public whitelistedAddresses;
    address[] public blacklistedAddresses;
    address[] public PlatinumMemberAddresses;
    address[] public addressofAddressMintedBalance;
    address public Treasury;
    Counters.Counter private TotalSupply;
    
    struct ClovesInfo {
        string rarity;
        uint256 maxsupply;
        uint256 price;
        string BaseURI;
        uint256 bonus;
        uint256 supply;
    }
    
    struct TokenInfo {
        IERC20 Address;
        string Token;
    }

    TokenInfo[] public AllowedCrypto;

    
    mapping(uint256 => string) public typeofbaseuri;
    mapping(string => ClovesInfo) public ClovesType;
    mapping(address => uint256) public addressMintedBalance;
  

    constructor()
            ERC721("CLOVER", "CLOV")
       
    {}

    // public
    function mint(uint256 _mintAmount, string memory _ClovesType, uint256 _pid)
        public
        
    {
        TokenInfo memory tokens = AllowedCrypto[_pid];
        ClovesInfo storage cloves = ClovesType[_ClovesType];
        uint256 ownerMintedCount = addressMintedBalance[_msgSender()];
        uint256 price = cloves.price * _mintAmount * 1 ether ;
        uint256 clovseSupply = cloves.supply;
        uint256 clovesMaxsupply = cloves.maxsupply;
        IERC20 paytoken;
        paytoken = tokens.Address;
        require(!paused, "the contract is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(paytoken.balanceOf(_msgSender()) >= (price), "insufficient funds");
        require(_mintAmount <= maxMintAmountForTX,"max mint amount per session exceeded");
        require(clovseSupply + _mintAmount <= clovesMaxsupply,"max NFT limit exceeded");
        require( ownerMintedCount + _mintAmount <= MintCap,"max NFT per address exceeded");
        
        if (onlyPlatinumMember != false) {
            require(_isPlatinumMember(_msgSender()), "user is not whitelisted");
            require( ownerMintedCount + _mintAmount <= MintCapPlatinumMember,"max NFT per address exceeded");

        }
        
        if (onlyWhitelisted != false) {
            require(_isWhitelisted(_msgSender()), "user is not whitelisted"); 
        }

        if(paytoken.allowance(_msgSender(), address(this)) <= price){
            uint256 approveAmount = price ;
            paytoken.approve(address(this), approveAmount );
        }

        paytoken.transferFrom(_msgSender(), Treasury, price);
        addressofAddressMintedBalance.push(_msgSender());
        

        for (uint256 i = 1; i <= _mintAmount; i++) {
            uint256 nextToken = _nextToken();
            cloves.supply += 1;
            addressMintedBalance[_msgSender()] += 1;
            typeofbaseuri[(nextToken)] = _ClovesType;
            _safeMint(_msgSender(), nextToken);
        }
    }
    
    function _nextToken() internal  returns (uint256) {
        TotalSupply.increment() ;
        return TotalSupply.current();  
    }
    
    function _isWhitelisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function _isnotBlacklisted(address _user) public view returns (bool) {
        for (uint256 i = 0; i < blacklistedAddresses.length; i++) {
            if (blacklistedAddresses[i] == _user) {
                return false;
            }
        }
        return true;
    }

    function _isPlatinumMember(address _user) public view returns (bool) {
        for (uint256 i = 0; i < PlatinumMemberAddresses.length; i++) {
            if (PlatinumMemberAddresses[i] == _user) {
                return false;
            }
        }
        return true;
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= TotalSupply.current()) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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
        string storage _clovestype = typeofbaseuri[tokenId];
        ClovesInfo storage cloves = ClovesType[_clovestype];
        string storage BaseUri = cloves.BaseURI;

        return BaseUri;
    }

    /**ADDING BLACKLIST ON TRANSFERS
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        require(_isnotBlacklisted(_msgSender()), "You are BlackListed");
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        require(_isnotBlacklisted(_msgSender()), "You are BlackListed");
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isnotBlacklisted(_msgSender()), "You are BlackListed");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

     

    function getBonusvalue(uint256 tokenId)
        external
        view
        returns (uint256 bonus)
    {
        string memory _clovestype = typeofbaseuri[tokenId];
        ClovesInfo memory cloves = ClovesType[_clovestype];
        return cloves.bonus;
    }

    function getRarityType(uint256 tokenId)
        external
        view
        returns (string memory rarity)
    {
        string memory _clovestype = typeofbaseuri[tokenId];
        ClovesInfo memory cloves = ClovesType[_clovestype];
        return cloves.rarity;
    }

    //only owner

    function addCurrency(
        IERC20 _paytoken,
        string memory _Token
    ) public onlyOwner {
        AllowedCrypto.push(
            TokenInfo({
                Address: _paytoken,
                Token: _Token
            })
        );
    }

    function resetCurrency () public onlyOwner {
        for (uint256 i=0; i<AllowedCrypto.length; i++) {
            delete AllowedCrypto[i];
        }
    } 
   
    
    function setClovesInfo(
        string memory _Cloves,
        uint256 _maxsupply,
        uint256 _price,
        string memory _baseuri,
        uint256 _bonus,
        uint256 _supply
    ) public onlyOwner {
        ClovesInfo storage cloves = ClovesType[_Cloves];
        ClovesType[_Cloves] = ClovesInfo({
            rarity: _Cloves,
            maxsupply: _maxsupply,
            price: _price,
            BaseURI: _baseuri,
            bonus: _bonus,
            supply: cloves.supply + _supply
        });
    }

    function changeClovPrice(string memory _Cloves, uint256 _newPrice) public onlyOwner {
        ClovesInfo storage cloves = ClovesType[_Cloves];
        cloves.price = _newPrice;
    }
    
    function changeClovMaxSuppli(string memory _Cloves, uint256 _newMaxSupply) public onlyOwner {
        ClovesInfo storage cloves = ClovesType[_Cloves];
        cloves.maxsupply = _newMaxSupply;
    }

    function setTreasury(address _Treasury) public onlyOwner {
        Treasury = _Treasury;
    }

    function setMintCapPlatinumMember(uint256 _MintCapPlatinumMember)
        public
        onlyOwner
    {
       MintCapPlatinumMember = _MintCapPlatinumMember;
    }

    function setMintCap(uint256 _MintCap)
        public
        onlyOwner
    {
       MintCap = _MintCap;
    }

    function setmaxMintAmountForTX(uint256 _newmaxMintAmountForTX) public onlyOwner {
        maxMintAmountForTX = _newmaxMintAmountForTX;
    }

    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    

    function RestMintCap() public onlyOwner {
        for (uint256 i = 0; i < addressofAddressMintedBalance.length; i++) {
            delete addressMintedBalance[addressofAddressMintedBalance[i]];
        }
    }

    function setStateMintCap(bool _state) public onlyOwner {
        MintCapState = _state;
    }

    function AddPlatinummember(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            PlatinumMemberAddresses.push(_users[i]);
        }
    }

    function RemovePlatinumMember(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            for (uint256 a = 0; a < PlatinumMemberAddresses.length; a++) {
                if (PlatinumMemberAddresses[a] == _users[i]) {
                    PlatinumMemberAddresses[a] = PlatinumMemberAddresses[
                        PlatinumMemberAddresses.length - 1
                    ];
                    PlatinumMemberAddresses.pop();
                }
            }
        }
    }
    
    function AddWhiteListUsers(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            whitelistedAddresses.push(_users[i]);
        }
    }

    function RemoveWhiteListUsers(address[] calldata _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            for (uint256 a = 0; a < whitelistedAddresses.length; a++) {
                if (whitelistedAddresses[a] == _users[i]) {
                    whitelistedAddresses[a] = whitelistedAddresses[
                        whitelistedAddresses.length - 1
                    ];
                    whitelistedAddresses.pop();
                }
            }
        }
    }

    function AddBlackListUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            blacklistedAddresses.push(_users[i]);
        }
    }

    function RemoveBlackListUsers(address[] memory _users) public onlyOwner {
        for (uint256 i = 0; i < _users.length; i++) {
            for (uint256 a = blacklistedAddresses.length; a == 0; a--) {
                if (blacklistedAddresses[a] == _users[i]) {
                    blacklistedAddresses[a] = blacklistedAddresses[
                        blacklistedAddresses.length - 1
                    ];
                    blacklistedAddresses.pop();
                }
            }
        }
    }

}