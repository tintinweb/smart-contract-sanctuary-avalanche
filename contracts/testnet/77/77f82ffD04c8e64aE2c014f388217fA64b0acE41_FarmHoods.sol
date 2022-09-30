// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;

import "ERC721URIStorage.sol";
import "Counters.sol";
import "Ownable.sol";
import "IERC2981.sol"; 

/*
  _______                           ___ ___                   __        
 |   _   |.---.-..----..--------.  |   Y   |.-----..-----..--|  |.-----.
 |.  1___||  _  ||   _||        |  |.  1   ||  _  ||  _  ||  _  ||__ --|
 |.  __)  |___._||__|  |__|__|__|  |.  _   ||_____||_____||_____||_____|
 |:  |                             |:  |   |                            
 |::.|                             |::.|:. |                            
 `---'                             `--- ---'                            
                                                                        
*/

contract FarmHoods is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;

    uint256 public _maxMintable = 250;
    string private _customBaseURI;
    uint256 public _royaltyAmount = 750; //7.5%
    uint256 public _maxMintPerTx = 5;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bool public _mintActive = false;
    address public _royaltyAddress;
    address public walletFundsA;
    address public walletFundsB;
    address public FarmDawgs_NFT_Address;
    mapping(address => uint256) public mintedFreeTokensAmount;
    mapping(uint256 => address) public mintedFreeTokens;
    bool public revealed = false;
    string public _unrevealed = "https://bafybeidtjnm4q6pdgzjlsib3yllkzrljdq6cklad5c7oas7cvxljmafmx4.ipfs.w3s.link/unrevealed_farmhoods.json";

    ///////// WL /////////
    uint256 public _price = 0.3 ether; //0.3 ether;
    uint256 public _price_WL = 0.3 ether; // 0.3 ether;
    uint256 public _price_Public = 0.3 ether; //0.3 ether;
    mapping(address => bool) public whiteListed;
    bool public isWL = true;

    //mint per wallet
    bool public limitPerWallet = true;
    uint256 public maxMintPerWallet = 5; //10 for the free mint
    mapping(address => uint256) mintPerWallet;

    //free mint
    uint256 public _maxMintableFree = 500;
    bool public isFreeMint = false;

    constructor(
        address _FarmDawgs_NFT_Address,
        string memory customBaseURI,
        address _walletFundsA,
        address _walletFundsB,
        address royaltyAddr
    ) ERC721("FarmHoods", "FRHD") {
        FarmDawgs_NFT_Address = _FarmDawgs_NFT_Address;
        walletFundsA = _walletFundsA;
        walletFundsB = _walletFundsB;
        _customBaseURI = customBaseURI;
        _royaltyAddress = royaltyAddr;
        _price = _price_WL;
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

        if(!revealed){
            return _unrevealed;
        }

        string memory baseURI = _baseURI();
        require(
            bytes(baseURI).length > 0,
            "ERC721Metadata: Base URI is not set"
        );

        string memory tokenIndex = Strings.toString(tokenId);
        return string(abi.encodePacked(baseURI, tokenIndex, ".json"));
    }

    function setBaseURI(string memory customBaseURI_) public onlyOwner {
        _customBaseURI = customBaseURI_;
    }

    function setMintActive(bool status) public onlyOwner {
        _mintActive = status;
    }

    function mint(uint256 quantity) public payable {
        require(_mintActive, "Minting is not active.");
        require(isFreeMint == false, "Minting left for Free Mint Dawg NFT Holders!.");
        require(
            quantity <= _maxMintPerTx && quantity > 0,
            "Cannot mint that many at once."
        );
        if (limitPerWallet) {
            mintPerWallet[msg.sender] += quantity;
            require(
                mintPerWallet[msg.sender] <= maxMintPerWallet,
                "Cannot mint more on your wallet."
            );
        }

        _price = _price_Public;

        if (isWL) {
            require(
                whiteListed[msg.sender] == true,
                "Your wallet is not a white listed."
            );
            _price = _price_WL;
        }

        require(
            msg.value == _price * quantity,
            "Not enough AVAX sent for mint or not equal the price"
        );


        for (uint256 i = 0; i < quantity; i++) {
            _internalMint(msg.sender);
        }

        splitFunds(msg.value);
    }

    function _internalMint(address recipient) private {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        require(
            newItemId <= _maxMintable,
            "Mint is finished or mint amount is over the limit"
        );

        _mint(recipient, newItemId);
    }


    //// Free Mint ////
    function setFreeMintActive(bool status) public onlyOwner {
        isFreeMint = status;
    }

    function freeMint(uint256 quantity) public {
        require(isFreeMint, "Free Minting is not active.");
        require(
            quantity <= _maxMintPerTx && quantity > 0,
            "Cannot mint that many at once."
        );

        //check dawg takens balance
        uint256 dawgTokensAmount = getDawgNFTTokensAmount(_msgSender());
        uint256 ableToMint = 0;
        if(dawgTokensAmount > mintedFreeTokensAmount[_msgSender()] ){
            ableToMint = dawgTokensAmount -
            mintedFreeTokensAmount[_msgSender()];
        }
        require(
            quantity <= ableToMint,
            "Cannot mint you don't have enaugh NFT Dawg Tokens."
        );

            //save minted amount for minter
        mintedFreeTokensAmount[_msgSender()] += quantity;

        for (uint256 i = 0; i < quantity; i++) {
            _internalFreeMint(msg.sender);
        }
    }

    function _internalFreeMint(address recipient) private {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        require(
            newItemId <= _maxMintableFree,
            "Mint is finished or mint amount is over the limit"
        );

        mintedFreeTokens[newItemId] = recipient;
        _mint(recipient, newItemId);
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _customBaseURI;
    }

    function royaltyInfo(uint256, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_royaltyAddress, (_salePrice * _royaltyAmount) / 10000);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function setRoyaltyAddress(address royaltyAddr) external onlyOwner {
        _royaltyAddress = royaltyAddr;
    }

    function splitFunds(uint256 mintValue) private {
        uint256 amountA = (mintValue * 70) / 100;
        uint256 amountB = (mintValue * 30) / 100;
        payable(walletFundsA).transfer(amountA);
        payable(walletFundsB).transfer(amountB);
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to withdraw");
        payable(_msgSender()).transfer(address(this).balance);
    }

    //unrevealed
    function setUnrevealedURI(string memory unrevealedURI_) external onlyOwner {
        _unrevealed = unrevealedURI_;
    }

    function setRevealed(bool value) external onlyOwner {
        revealed = value;
    }

    //// set mint per wallet ////
    function setLimitPerWallet(bool _limitPerWallet) external onlyOwner {
        limitPerWallet = _limitPerWallet;
    }

    function setMintPerWallet(uint256 _maxMintPerWallet) external onlyOwner {
        maxMintPerWallet = _maxMintPerWallet;
    }

    /////// for WL ///////
    function setWLStatus(bool _isWL) external onlyOwner {
        isWL = _isWL;
    }

    function addWhiteList(address[] memory _addressList) external onlyOwner {
        require(_addressList.length > 0, "Error: list is empty");

        for (uint256 i = 0; i < _addressList.length; i++) {
            require(_addressList[i] != address(0), "Address cannot be 0.");
            whiteListed[_addressList[i]] = true;
        }
    }

    function removeWhiteList(address[] memory addressList) external onlyOwner {
        require(addressList.length > 0, "Error: list is empty");
        for (uint256 i = 0; i < addressList.length; i++)
            whiteListed[addressList[i]] = false;
    }

    //Airdrop
    function setAirdropSupply(uint256 _supply) public onlyOwner {
        _maxMintableFree = _supply;
    }

    function _mintForAirdrop(address recipient) public onlyOwner {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        require(newItemId <= _maxMintableFree, "Mint Supply Reached");

        _mint(recipient, newItemId);
    }

    function Airdrop(address[] memory recipient) public onlyOwner {
        for (uint256 i = 0; i < recipient.length; i++) {
            _mintForAirdrop(recipient[i]);
        }
    }

    //// set NFT Token Address
    function setNFTAddress(address nftAddress) public onlyOwner {
        FarmDawgs_NFT_Address = nftAddress;
    }

    function getDawgNFTTokensAmount(address _owner)
        public
        view
        returns (uint256)
    {
        return IERC721(FarmDawgs_NFT_Address).balanceOf(_owner);
    }

    //update price for any situation needed
    function updatePrice(uint256 _type,uint256 value) public onlyOwner {
        if(_type == 1){
            _price  = value;
        }else if(_type == 2){
            _price_WL  = value;
        }else if(_type == 3){
            _price_Public  = value;
        }
    }
}