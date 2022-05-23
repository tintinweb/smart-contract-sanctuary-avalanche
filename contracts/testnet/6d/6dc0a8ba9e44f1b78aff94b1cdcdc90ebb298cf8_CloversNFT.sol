// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";
import "./ReentrancyGuard.sol";
import "./MerkleProof.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";


contract CloversNFT is ERC721ABurnable, ERC721AQueryable, Ownable, ReentrancyGuard {

    uint256 public maxMintAmountForTX = 5;
    uint256 public MintCap = 5;
    uint256 public MintCapPlatinumMember = 2;
    bool public paused = false;
    bool public onlyWhitelisted = false;
    bool public onlyPlatinumMember = false;
    bool public MintCapState = false;
    bool public TransferActive = true;
    address[] public addressofAddressMintedBalance;
    bytes32 public PlatinumMerkleRoot;
    bytes32[] public PlatinumMerkleProof;
    bytes32 public WhitelistMerkleRoot;
    bytes32[] public WhitelistMerkleProof;
    bytes32 public BlacklistMerkleRoot;
    bytes32[] public BlacklistMerkleProof;
    
    address public Treasury;
    
    struct TokenUri{
        string TokenUri;
    }

    struct ClovesInfo {
        string rarity;
        uint256 maxsupply;
        uint256 price;
        uint256 bonus;
        uint256 supply;
    }
    
    struct TokenInfo {
        IERC20 Address;
        string Token;
    }

    TokenInfo[] public AllowedCrypto;

    mapping (string => TokenUri) public ClovTokenUri;
    mapping(uint256 => string) public typeofbaseuri;
    mapping(string => ClovesInfo) public ClovesType;
    mapping(address => uint256) public addressMintedBalance;
  

    constructor()
            ERC721A("Lucky Leo Clovers", "LLC")
       
    {}

    // public
    /**
     * Mint Of a Clover
     * @param _mintAmount how many Clovers to mint
     * @param _ClovesType the type Clovers to mint
     * @param _pid the currency to pay for the mint
     */
    function mint(uint256 _mintAmount, string memory _ClovesType, uint256 _pid)
        external nonReentrant()
        
    {
        TokenInfo memory tokens = AllowedCrypto[_pid];
        ClovesInfo storage cloves = ClovesType[_ClovesType];
        uint256 ownerMintedCount = addressMintedBalance[_msgSender()];
        uint256 price = cloves.price * _mintAmount * 1 ether ;
        uint256 clovseSupply = cloves.supply;
        uint256 clovesMaxsupply = cloves.maxsupply;
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        IERC20 paytoken;
        paytoken = tokens.Address;
        require(!paused, "the Minting is paused");
        require(_mintAmount > 0, "need to mint at least 1 NFT");
        require(paytoken.balanceOf(_msgSender()) >= (price), "insufficient funds");
        require(_mintAmount <= maxMintAmountForTX,"max mint amount per transaction exceeded");
        require(clovseSupply + _mintAmount <= clovesMaxsupply,"max NFT limit exceeded");
        
        if(MintCapState != false) {
            require( ownerMintedCount + _mintAmount <= MintCap,"max NFT per address exceeded");
        }
        
        
        if (onlyPlatinumMember != false) {
            require(MerkleProof.verify(PlatinumMerkleProof, PlatinumMerkleRoot, leaf), "user is not a Platinum Member");
            require( ownerMintedCount + _mintAmount <= MintCapPlatinumMember,"max NFT per address exceeded");

        }
        
        if (onlyWhitelisted != false) {
            require(MerkleProof.verify(WhitelistMerkleProof, WhitelistMerkleRoot, leaf), "user is not whitelisted"); 
        }

        if(paytoken.allowance(_msgSender(), address(this)) <= price){
            uint256 approveAmount = price ;
            paytoken.approve(address(this), approveAmount );
        }

        paytoken.transferFrom(_msgSender(), Treasury, price);
        addressofAddressMintedBalance.push(_msgSender());
        
        uint256 StratingID = _nextTokenId();
        uint256 EndingID = StratingID + _mintAmount;

        for (uint256 i = StratingID; i <= EndingID; i++) {
            
            typeofbaseuri[(i)] = _ClovesType;
        }

        cloves.supply += _mintAmount;
        addressMintedBalance[_msgSender()] += _mintAmount;
        _safeMint(_msgSender(), _mintAmount);

    }

    /**
     * Gets all the TokenURi of an existing TokenID
     * @param tokenId the TokenID to get the TokenURi
     */
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
        string memory _clovestype = typeofbaseuri[tokenId];
        TokenUri memory _TokenUri = ClovTokenUri[_clovestype];
        return _TokenUri.TokenUri;
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
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(TransferActive = true, "Transfer of the token is not active");
        require(MerkleProof.verify(BlacklistMerkleProof, BlacklistMerkleRoot, leaf) != true, "You are BlackListed");
        _transfer(from, to, tokenId);
        
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(TransferActive = true, "Transfer of the token is not active");
        require(MerkleProof.verify(BlacklistMerkleProof, BlacklistMerkleRoot, leaf) != true, "You are BlackListed");
        safeTransferFrom(from, to, tokenId, "");
        
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
        require(TransferActive = true, "Transfer of the token is not active");
        require(MerkleProof.verify(BlacklistMerkleProof, BlacklistMerkleRoot, leaf) != true, "You are BlackListed");
        _transfer(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }
    

     
    /**
     * Gets the Bonus vlaue of an existing TokenID
     * @param tokenId the TokenID to get the Bonus Value
     */
    function getBonusvalue(uint256 tokenId)
        external
        view
        returns (uint256 bonus)
    {
        string memory _clovestype = typeofbaseuri[tokenId];
        ClovesInfo memory cloves = ClovesType[_clovestype];
        return cloves.bonus;
    }

    /**
     * Gets the Rarity type of an existing TokenID
     * @param tokenId the TokenID to get the Rarity type
     */
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
    /**
     * Adds a new currency to the patments system
     * @param _paytoken the Token address to recive as Payament
     * @param _Token the Tick of the Token to recive as Payament
     */
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

    // Reset all the currency in the payement system
    function resetCurrency () public onlyOwner {
        for (uint256 i=0; i<AllowedCrypto.length; i++) {
            delete AllowedCrypto[i];
        }
    }

    /**
     * Set the TokenUri of the Clove Rarity type
     * @param _ClovesType the Rarity Cloves type to set the TokenUri
     * @param _tokenuri the TokenUri to set
     */
    function setClovTokenUri(string memory _ClovesType, string memory _tokenuri) public onlyOwner{
        TokenUri storage _TokenUri = ClovTokenUri[_ClovesType];
        _TokenUri.TokenUri = _tokenuri;
    }
   
    /**
     * Set the Info of the given Clove Rarity type
     * @param _Cloves the Rarity Cloves type to set 
     * @param _maxsupply the Max Supply mintable to set
     * @param _price the price of mint to set
     * @param _bonus the bonus value to set
     * @param _supply the initial supply to set (0)
     */
    function setClovesInfo(
        string memory _Cloves,
        uint256 _maxsupply,
        uint256 _price,
        uint256 _bonus,
        uint256 _supply
    ) public onlyOwner {
        ClovesInfo storage cloves = ClovesType[_Cloves];
        ClovesType[_Cloves] = ClovesInfo({
            rarity: _Cloves,
            maxsupply: _maxsupply,
            price: _price,
            bonus: _bonus,
            supply: cloves.supply + _supply
        });
    }

    /**
     * Change the Price to mint of the Clove Rarity type
     * @param _Cloves the Rarity Cloves type to set the new Price
     * @param _newPrice the New Price to set
     */
    function changeClovPrice(string memory _Cloves, uint256 _newPrice) public onlyOwner {
        ClovesInfo storage cloves = ClovesType[_Cloves];
        cloves.price = _newPrice;
    }
    
    /**
     * Change the Max Supply of the Clove Rarity type
     * @param _Cloves the Rarity Cloves type to set the new Price
     * @param _newMaxSupply the New Max Supply to set
     */
    function changeClovMaxSuppli(string memory _Cloves, uint256 _newMaxSupply) public onlyOwner {
        ClovesInfo storage cloves = ClovesType[_Cloves];
        cloves.maxsupply = _newMaxSupply;
    }
    
    /**
     * Set the Treasury wallet that will recive all the funds
     * @param _Treasury the wallet to set as Treasury
     */
    function setTreasury(address _Treasury) public onlyOwner {
        Treasury = _Treasury;
    }

    /**
     * Set the Max NFT that a Platinum Member can Mint 
     * @param _MintCapPlatinumMember the Max Number of NFT mintable
     */
    function setMintCapPlatinumMember(uint256 _MintCapPlatinumMember)
        public
        onlyOwner
    {
       MintCapPlatinumMember = _MintCapPlatinumMember;
    }

    /**
     * Set the Max NFT Mintable for wallet
     * @param _MintCap the Max Number of NFT mintable for wallet
     */
    function setMintCap(uint256 _MintCap)
        public
        onlyOwner
    {
       MintCap = _MintCap;
    }

    /**
     * Set the Max NFT Mintable for Transaction
     * @param _newmaxMintAmountForTX the Max Number of NFT mintable for Transaction
     */
    function setmaxMintAmountForTX(uint256 _newmaxMintAmountForTX) public onlyOwner {
        maxMintAmountForTX = _newmaxMintAmountForTX;
    }

    /**
     * Set the Contrata Pause state
     * @param _state the State to set
     */
    function pause(bool _state) public onlyOwner {
        paused = _state;
    }

    /**
     * Set the Contract Whitelist state
     * @param _state the State to set
     */
    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    /**
     * Set the Contract Platinum Member state
     * @param _state the State to set
     */
    function setonlyPlatinumMember(bool _state) public onlyOwner {
        onlyPlatinumMember = _state;
    }

    /**
     * Set the Transfer of NFT state
     * @param _state the State to set
     */
    function setTransferActive(bool _state) public onlyOwner {
        TransferActive = _state;
    }

    /**
     * Set the Contract Mint Cap state
     * @param _state the State to set
     */
    function setStateMintCap(bool _state) public onlyOwner {
        MintCapState = _state;
    }
    
    // Reset the count of mint for wallet
    function RestMintCap() public onlyOwner {
        for (uint256 i = 0; i < addressofAddressMintedBalance.length; i++) {
            delete addressMintedBalance[addressofAddressMintedBalance[i]];
        }
    }

    /**
     * Set the root hash for the Platinum list
     * @param _PlantinumMerkleRoot the Root Hash to Set
     */
    function SetPlatinumMerkleRoot(bytes32 _PlantinumMerkleRoot) public onlyOwner {
        PlatinumMerkleRoot = _PlantinumMerkleRoot;
    }

    /**
     * Set the root hash for the Platinum list
     * @param _PlantinumMerkleProof the Root Hash to Set
     */
    function SetPlatinumMerkleProof(bytes32[] calldata _PlantinumMerkleProof) public onlyOwner {
        PlatinumMerkleProof = _PlantinumMerkleProof;
    }
    
    /**
     * Set the root hash for the Whitelist list
     * @param _WhitlelistMerkleRoot the Root Hash to Set
     */
    function SetWhitelistMerkleRoot(bytes32 _WhitlelistMerkleRoot) public onlyOwner {
        WhitelistMerkleRoot = _WhitlelistMerkleRoot;
    }

    /**
     * Set the root hash for the Whitelist list
     * @param _WhitlelistMerkleProof the Root Hash to Set
     */
    function SetWhitelistMerkleProof(bytes32[] calldata _WhitlelistMerkleProof) public onlyOwner {
        WhitelistMerkleProof = _WhitlelistMerkleProof;
    }


    /**
     * Set the root hash for the Whitelist list
     * @param _BlacklistMerkleRoot the Root Hash to Set
     */
    function SetBlacklistMerkleRoot(bytes32 _BlacklistMerkleRoot) public onlyOwner {
        BlacklistMerkleRoot = _BlacklistMerkleRoot;
    }

    /**
     * Set the root hash for the Whitelist list
     * @param _BlacklistMerkleProof the Root Hash to Set
     */
    function SetBlacklistMerkleProof(bytes32[] calldata _BlacklistMerkleProof) public onlyOwner {
        BlacklistMerkleProof = _BlacklistMerkleProof;
    }


}