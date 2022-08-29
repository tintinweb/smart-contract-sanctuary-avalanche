// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;


import "Address.sol";
import "Context.sol";
import "Counters.sol";
import "ERC165.sol";
import "ERC721.sol";
import "ERC721Enumerable.sol";
import "ERC721URIStorage.sol";
import "IERC165.sol";
import "IERC721.sol";
import "IERC721Enumerable.sol";
import "IERC721Metadata.sol";
import "IERC721Receiver.sol";
import "IERC2981.sol";
import "Ownable.sol";
import "Strings.sol";


/*
 _______ _________                      _________ _______  _                
(  ___  )\__   __/    |\     /||\     /|\__   __/(  ____ \| \    /\|\     /|
| (   ) |   ) (       | )   ( || )   ( |   ) (   | (    \/|  \  / /( \   / )
| (___) |   | |       | | _ | || (___) |   | |   | (_____ |  (_/ /  \ (_) / 
|  ___  |   | |       | |( )| ||  ___  |   | |   (_____  )|   _ (    \   /  
| (   ) |   | |       | || || || (   ) |   | |         ) ||  ( \ \    ) (   
| )   ( |___) (___    | () () || )   ( |___) (___/\____) ||  /  \ \   | |   
|/     \|\_______/    (_______)|/     \|\_______/\_______)|_/    \/   \_/   
                                                                            
*/

interface PlantATree {
    function getTreesSinceLastPlant(address adr)
        external
        view
        returns (uint256);
}

contract AIWhisky is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter public _tokenIds;

    uint256 public _price = 1 ether;
    uint256 public _price_Public = 1 ether;
    uint256 public _maxMintable = 100;
    string private _customBaseURI;
    string private _unrevealdURI =
        "https://smolr.mypinata.cloud/ipfs/QmRvRFUsEhgc45wVCXeAiKMd2LUGGEzVGPSzB64iCFp7a7";
    uint256 public _royaltyAmount = 1000; //10%
    uint256 public _maxMintPerTx = 1;
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bool public _mintActive = false;
    address private _royaltyAddress;
    address private walletFundsA;
    address private walletFundsB;
    ///// To Claim for Palnt A Tree /////
    mapping(address => bool) public claimedWallets;
    mapping(uint256 => bool) public revealedTokens;
    mapping(address => bool) public revealedWallets;
    mapping(address => uint256[] ) public minters;
    mapping(uint256 => address) public mintedTokens;
    uint256 private link;
    
    address PlantATree_Address = 0x827C2c9bab375b251F7acf92B6E19400268C1a7F;


    ///////// WL /////////
    uint256 public _price_WL = 1 ether;
    mapping(address => bool) public whiteListed;
    bool public isWL = true;

    constructor(
        string memory customBaseURI,
        address _walletFundsA,
        address _walletFundsB,
        address royaltyAddr,
        uint256 _link
    ) ERC721("SimpNftContract.sol", "Simp") {
        walletFundsA = _walletFundsA;
        walletFundsB = _walletFundsB;
        _customBaseURI = customBaseURI;
        _royaltyAddress = royaltyAddr;
        link = _link;
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

        if (revealedTokens[tokenId] != true) return _unrevealdURI;

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
        require(quantity <= _maxMintPerTx, "Cannot mint that many at once.");
        require(claimedWallets[msg.sender] == false, "You can't mint again with this wallet because you already claimed your minted tokens. You must mint with a different wallet");

        _price = _price_Public;

        if (isWL) {
            require(
                whiteListed[msg.sender] == true,
                "Your wallet not white listed for this NFT."
            );
            _price = _price_WL;
        }

        require(
            msg.value == _price,
            "Not enough AVAX sent for mint or not equal the price"
        );

        _internalMint(msg.sender);

        //save minters with minted tokens
        uint256 tokenId = _tokenIds.current();
        minters[msg.sender].push(tokenId);
        mintedTokens[tokenId] = msg.sender;

        splitFunds();
    }

    function totalSupply() public view returns (uint256) {
        return _tokenIds.current();
    }

    function _internalMint(address recipient) private {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        require(
            newItemId <= _maxMintable,
            "Mint is finished ot mint amount is over the limit"
        );

        _mint(recipient, newItemId);
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

    function splitFunds() private {
        uint256 amountA = (msg.value * 30) / 100;
        uint256 amountB = (msg.value * 25) / 100;
        payable(walletFundsA).transfer(amountA);
        payable(walletFundsB).transfer(amountB);
    }

    function setNFTsTransferWallets(
        address _walletFundsA,
        address _walletFundsB
    ) external onlyOwner {
        walletFundsA = _walletFundsA;
        walletFundsB = _walletFundsB;
    }

    function withdraw() external onlyOwner {
        require(address(this).balance > 0, "Nothing to withdraw");
        payable(_msgSender()).transfer(address(this).balance);
    }

    ////// Public //////
    function updatePublicSupply(uint256 supply) public onlyOwner {
        _maxMintable = supply;
    }

    function updatePublicMintPrice(uint256 price) public onlyOwner {
        _price_Public = price;
    }

    /////// WL ///////
    function setWLStatus(bool _isWL) external onlyOwner {
        isWL = _isWL;
    }

    function updateWLMintPrice(uint256 price) public onlyOwner {
        _price_WL = price;
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


    ////// Claim 
    function claim() public {
        require(claimedWallets[msg.sender] == false, "This wallet already claimed the Avax" );
        uint256 tokensAmount = minters[msg.sender].length;
        require(tokensAmount > 0, "You don't have tokens to claim" );

        claimedWallets[msg.sender] = true;
        uint256 treesAvax = (_price * 45) / 100; //45%
        uint256 avaxValue = treesAvax * tokensAmount;
        payable(msg.sender).transfer(avaxValue);
    }


    ////// Reveal the NFT
    function revealNFT(uint256 _link) public {
        require(_link == link, "Can't reveal your NFT" );
        uint256 trees = PlantATree(PlantATree_Address).getTreesSinceLastPlant(msg.sender);
        require(trees > 0 , "You have to plant trees to reveal your NFT.");
        uint256 tokensAmount = minters[msg.sender].length;
        require(tokensAmount > 0, "You don't have tokens to claim" );
        //reveal tokens
        for(uint256 i=0; i < tokensAmount; i++){
            uint256 tokenId = minters[msg.sender][i];
            revealedTokens[tokenId] = true;
        }
       revealedWallets[msg.sender] = true;
    }
    
    // get Minter Wallets Tokens Amount
    function getTokensAmount() public view returns(uint256){
        uint256 tokensAmount = minters[msg.sender].length;
        return tokensAmount;
    } 


    ////onlyOwner
    ////incase for security and safty 
    function revealAllNFTs() public onlyOwner{
        for(uint256 i=1; i <= _tokenIds.current() ; i++){
            revealedTokens[i] = true;
            revealedWallets[mintedTokens[i]] = true;
        }
    }

    //onlyOwner
    function revealOneNFT(uint256 tokenId) public onlyOwner{
        revealedTokens[tokenId] = true;
    }

    //onlyOwner
    function updateLink(uint256 _link) public onlyOwner{
        link = _link;
    }
    
}