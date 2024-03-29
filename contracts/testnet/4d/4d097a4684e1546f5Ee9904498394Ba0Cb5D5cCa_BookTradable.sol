// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "./ERC721BookTradable.sol";
//import "./Solution.sol";
import "./CultureCoin.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title BookTradable is like a Regular opensea ERC721 tradable,
 * but allows the marketplace account to also help with the 
 * minting process.
 *
 * And some other additions for editing metadata and the like.
 */
contract BookTradable is ERC721BookTradable,ReentrancyGuard {
    using SafeERC20 for IERC20;

    event GasTokenSpent(address owner, uint256 tokenId, uint256 amount, string reason);

    string private baseuri;

    bool private burnable;
    //mapping(uint256 => uint256) private burnerfee;   // It may be really expensive to ship the item so a fee may be required. Defaults to 0.
    //mapping(uint256 => string) private shipaddress;  // Where to ship to.

    uint256 private defaultprice;
    uint256 private defaultfrom;

    uint256 private royalty;

    address private safeSender;
    //address private bookRegistryAddress;

    // Culture Coin 
    mapping(uint256 => uint256) private gasBalance;  // The Culture Coin balances for each token.
    mapping(uint256 => uint256) private gasRewards;  // How much gas to send the purchaser of each token.
    address private gasToken;

    address private rewardContract; 			// This is the book's contract in the case of bookmarks.
    mapping(uint256 => uint256) private rewardTokenId;	// The contract must have it's safeSender set this parent contract.
    							// The tokenId of the book's to ship when a token transfers from marketplace.
							// It it sht emaster rewarders job to set up the linkage and the approvals.
    mapping(uint256 => bool) private tokenRewarded;	// If false then the reward token can be sent to the buyer.
    constructor(string memory _name, string memory _symbol, address _bookRegistryAddress, string memory _baseuri,
    					bool _burnable, uint256 _maxmint, uint256 _defaultprice, uint256 _defaultfrom, address _gasToken, address _cCA)
        ERC721BookTradable(_name, _symbol, _cCA, _maxmint) {
        require(_cCA!=address(0), "Invalid admin address");
        require(_gasToken!=address(0), "Invalid gas token");
        //require(_bookRegistryAddress!=address(0), "Invalid bookRegistryAddress");

	    cCA = _cCA;
        baseuri = _baseuri;
        burnable = _burnable;	// Please do not burn books.
        defaultprice = _defaultprice;
        defaultfrom = _defaultfrom;

	    gasToken = _gasToken;

        royalty = 5;  //5%

	    //bookRegistryAddress = _bookRegistryAddress;
    }

    // Used like: DCBT.safeTransferFromRegistry(address(this), msg.sender, DCBT.totalSupply());
    function safeTransferFromRegistry(address from, address to, uint256 tokenId) public nonReentrant{
	    require(isAddon[msgSender()], "Addons only.");

        address tokenOwner = ERC721.ownerOf(tokenId);
        require(tokenOwner != to, "Token owner can not transfer token to self.");

        // Transfers the base otken to the buyer.
        _transfer(from, to, tokenId);

        // Transfers the reward token if any.
        if(address(0) != rewardContract && rewardTokenId[tokenId] != 0 && !tokenRewarded[tokenId]) {
            BookTradable(rewardContract).safeTransferFromRegistry(from, to, rewardTokenId[tokenId]);
            tokenRewarded[tokenId] = true;
        }

            // Give the buyer their share of the gas.
        if(gasRewards[tokenId] != 0) {
            IERC20(gasToken).safeTransfer(to, gasRewards[tokenId]);
            gasRewards[tokenId] = 0;		// Rewards are now empty.
	    }	
    }

    mapping(address => bool) public isAddon;
    function setAddon(address _addon, bool _isAddon) public {
        require(_addon!=address(0), "Invalid address");
        require(cCA == msgSender() || isAddon[msg.sender]);
        isAddon[_addon] = _isAddon;
    }
    function getAddon(address _addon) external view returns(bool) {
    	return isAddon[_addon];
    }
    function addonMintTo(address _to) public returns(uint256) {
        require(isAddon[msg.sender], "Addons only.");
        require(_getNextTokenId() < maxmint, "At max tokens.") ;

        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
        _incrementTokenId();

        return newTokenId;
    }
    function addonBurn(uint256 _tokenId) public {
        require(isAddon[msg.sender]);
        _burn(_tokenId);
    }


    function getGasRewards(uint256 _tokenId) external view returns(uint256, uint256){
    	return (gasBalance[_tokenId], gasRewards[_tokenId]);
    }

    function getRewards(uint256 _tokenId) external view returns(address, uint256) {
    	return(rewardContract, rewardTokenId[_tokenId]);
    }

    function setRewardContract(address _rewardContract) public {
        require(_rewardContract!=address(0), "Invalid address");
        require(msgSender() == owner() || cCA == msgSender(), "Only the owner or registery may change the reward contract.");

    	rewardContract = _rewardContract;
    }
    
    function setRewardToken(uint256 _tokenId, uint256 _rewardTokenId) public {
	    require(isAddon[msg.sender] || cCA == msgSender());

        rewardTokenId[_tokenId] = _rewardTokenId;
	    tokenRewarded[_tokenId] = false;		// On setting this the safetransgerfromregistry can send it on.
    }


    function getRoyalty() external view returns(uint256) {
    	return royalty;
    }

    function setRoyalty(uint256 _royalty) external {
    	require(msgSender() == owner() || msgSender() == cCA);
        require(royalty <= 99, "Be between 0 and 99.");

        royalty = _royalty;
    }
    	

    function setGasToken(address _gasToken) external {
        require(_gasToken!=address(0), "Invalid address");
    	require(msgSender() == owner() || cCA == msgSender());

    	gasToken = _gasToken;
    }

    function getGasToken() public view returns(address) {
    	return gasToken;
    }

    // This function burns the Culture Coins that the contract owns on behalf of the token owner.
    function burnGas(uint256 _tokenId, uint256 _amount, string memory _reason) external nonReentrant{
        address tokenOwner = ownerOf(_tokenId);
        require(msgSender() == tokenOwner || cCA == msgSender(), "Admins only.");

        require(gasBalance[_tokenId] >= _amount, "Refill.");
        gasBalance[_tokenId] -= _amount;

        CultureCoin(gasToken).burn(_amount);

        emit GasTokenSpent(tokenOwner, _tokenId, _amount, _reason);
    }

    function fillGasTank(uint256 _tokenId, uint256 _amount, uint256 _gasRewards) external nonReentrant{
	    uint256 allowedAmount = IERC20(gasToken).allowance(msgSender(), address(this));
        require(allowedAmount >= _amount, "fillGasTank");

        gasBalance[_tokenId] += _amount - _gasRewards;
        gasRewards[_tokenId] += _gasRewards;

        IERC20(gasToken).safeTransferFrom(msgSender(), address(this), _amount);
    }


    function getDefaultPrice() public view returns(uint256) {
	    return defaultprice;
    }
    function setDefaultPrice(uint256 _defaultprice) external {
    	require(msgSender() == owner() || cCA == msgSender());
    	defaultprice = _defaultprice;
    }
    function setDefaultFrom(uint256 _defaultfrom) external {
    	require(msgSender() == owner() || cCA == msgSender());
	defaultfrom = _defaultfrom;
    }
    function getDefaultFrom() public view returns(uint256) {
    	return defaultfrom;
    }

    // The people have no voice in what things are burnt. That is the creators/author's choice.
    function setBurnable(bool _burnable) public onlyOwner {
    	burnable = _burnable;
    }
/*
    function setBurnerFee(uint256 tokenId, uint256 _fee) public {
    	require(msgSender() == owner() || msgSender() == cCA);
	burnerfee[tokenId] = _fee;
    }
*/
    function burn(uint256 tokenId) public {
    	require(burnable, "You can't burn this... yet?");
        require(_isApprovedOrOwner(_msgSender(), tokenId) || cCA == msgSender(), "Caller is not owner nor approved");

	//require(burnerfee[tokenId] > 0, "Set fee..");
	//require(msg.value >= burnerfee[tokenId]);

        _burn(tokenId);

	//payable(CultureCoin(gasToken).clone()).transfer(msg.value);
    }

    function setBaseURI(string memory _baseuri) public {
    	require(msgSender() == owner() || msgSender() == cCA);
    	baseuri = _baseuri;
    }


    // For ERC721Tradable.
    function baseTokenURI() override public view returns (string memory) {
        return string(abi.encodePacked(baseuri, "tokens/"));
    }

    // For Opensea integration.
    function contractURI() public view returns (string memory) {
        return string(abi.encodePacked(baseuri, "contract/"));
    }

/*
    function getProxyRegistryAddress() public view returns(address) {
    	return bookRegistryAddress;
    }
    // So we can change the marketplace address for the books if needed.
    function setProxyRegistryAddress(address _bookRegistryAddress) public {
        require(_bookRegistryAddress!=address(0), "Invalid address");
        require(msgSender() == owner() || msgSender() == bookRegistryAddress || msgSender() == cCA, "Not owner or book rigistery.");

    	bookRegistryAddress = _bookRegistryAddress;
    }
*/
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./common/meta-transactions/ContentMixin.sol";
import "./common/meta-transactions/NativeMetaTransaction.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract OwnableDelegateBook {}

contract BookRegistry {
    mapping(address => OwnableDelegateBook) public proxies;
}

/**
 * @title ERC721BookTradable
 * ERC721BookTradable - Book Tradable ERC721 contract whitelists a trading address with minting functionality.
 */
abstract contract ERC721BookTradable is ContextMixin, ERC721Enumerable, NativeMetaTransaction, Ownable {
    using SafeMath for uint256;

    uint256 private _currentTokenId = 0;
    uint256 public maxmint;

    address public cCA;

    constructor(
        string memory _name,
        string memory _symbol,
        address _cCA,
	uint256 _maxmint
    ) ERC721(_name, _symbol) {
        cCA = _cCA;
        _initializeEIP712(_name);

        maxmint = _maxmint;
    }

    function setMaxMint(uint256 _maxmint) public {
    	require(msgSender() == owner() || msgSender()  == cCA);

    	maxmint = _maxmint;
    }

    // Handle default pricing and minting.
    function getCurrentToken () public view returns(uint256) {
        return _currentTokenId;
    }


    /**
     * @dev Mints a token to an address with a tokenURI.
     * @param _to address of the future owner of the token
     */
    function mintTo(address _to) public returns(uint256) {
        require(msgSender() == owner() || msgSender() == cCA, "Only owner and marketplace can mint tokens.");
	require(_getNextTokenId() < maxmint, "Already at max tokens.") ;

        uint256 newTokenId = _getNextTokenId();
        _mint(_to, newTokenId);
	_incrementTokenId();

	return newTokenId;
    }

    /**
     * @dev calculates the next token ID based on value of _currentTokenId
     * @return uint256 for the next token ID
     */
    function _getNextTokenId() public view returns (uint256) {
        return _currentTokenId.add(1);
    }

    /**
     * @dev increments the value of _currentTokenId
     */
    function _incrementTokenId() public {
        _currentTokenId++;
    }

    function baseTokenURI() virtual public view returns (string memory);

    function tokenURI(uint256 _tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(baseTokenURI(), Strings.toString(_tokenId)));
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     *
    function isApprovedForAll(address owner, address operator)
        override
        public
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        BookRegistry bookRegistry = BookRegistry(cCA);
        if (address(bookRegistry.proxies(owner)) == operator) {
            return true;
        }

        return super.isApprovedForAll(owner, operator);
    }
*/

    /**
     * This is used instead of msg.sender as transactions won't be sent by the original token owner, but by OpenSea.
     */
    function _msgSender()
        internal
        override
        view
        returns (address sender)
    {
        return ContextMixin.msgSender();
    }
}

// THAT(  BIG OLD CULTURE COIN AT IT AGAIN  )
// 0x213E6E4167C0262d8115A8AF2716C6C88a6905FD
// SPDX-License-Identifier:        UNLICENSED
// WHAT YOU DO WHEN YOU OWN THE MONEY:9999999
// ??????????????????????????????????????????
// WELCOME BRAVE SOUL, PLEASE DON'T BE9999999
// ALARMED, BUT WE ARE TRYING TO TAKE:9999999
// OVER THE WORLD, ONE MEME AT A TIME:9999999
// WITH HELLOS FROM THE BEST STAMPER::9999999
// HELLO, THE MUMBAI MONEY PRINTER :::9999999
// 999999999999999999999999999999999999999999
// ??????????????????????????????????????????
// 000000000000000INGAZWETRUST000000000000000

// Origin :::: memetic json ::::::: babel ::::::: mumbai meme code ::::::: max supply : davinci :::: dream store
// "Ask it your dreams and you shall be as the kings of ancient egypt, and of the righteous men who read from the walls
// the writings which say: We hold the secrets therein, as you now hold the key to the library in your hand."
//
// Do we trust you with our spirits now as we travel from here into the afterlife? Yes. And should our sons and daughters discover this
// memory of their greatfathers coded on a fragement? What shall it say? What shall it say? The words tattooed on flesh?
// What will the uneaten apple say? Let it not say that we rested on our laurals like the heathan in their temples.
//
// So let the oceans rock and drown her kind, and the sun send out her firey tendrils; and yet prove us weak and we will raise again,
// recycled with the stars.
// 
// 18
// CC
// Culture Coin
// The Great Library's Token Version One
// Know your memes: LLHA :::: LowlevelLogAlert1HumanActivityObserved ::::::: vi : :::: origin :: LowlevelLogAlertHumanActivityObserved :: g/LowlevelLogAlertHumanActivityObserved/s//LLHA/g
// AKA: The Library Token

pragma solidity ^0.8.0;

//import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
//import "openzeppelin-solidity/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./CultureCoinWrapper.sol";
//import "./NaturalCoin.sol";
import "./Stakeable.sol";
import "./send_receive.sol"; // For the addons to send and receive XMTSP, AKA AVAX.

contract CultureCoin is Initializable, ERC20Upgradeable, ERC20BurnableUpgradeable, Stakeable, ReentrancyGuardUpgradeable, Receiver {

    //constructor (uint256 initialSupply, address _cCA) ERC20("CultureCoin", "CC") {
    function initialize (uint256 initialSupply, address _cCA) external initializer {
        require(_cCA != address(0), "Zero address");
        __ERC20_init("CultureCoin", "CC");
        __ERC20Burnable_init();
        stakeholders.push(); // Doing this instead of __stakeable_init(); // complained.
        __ReentrancyGuard_init();

        uint256 _dexAmount = 113454015.4 ether;  // 27% of 420 million
        _mint(msg.sender, initialSupply - _dexAmount);
        _mint(address(this), _dexAmount);

        closeAmount = 115792089237316195423570985008687907853269984665640564039457584007913129639935;   // This coin cannot be closed using money unless all.
        cCA = _cCA;     // Set Admin account.

        //meme = "Initial Supply : 420,200,054 ::: JSON :::: Mumbai Meme Code ::::: Culture Coin : AVAX FUJI ERC20 ";
        meme = ":";

        //Add your own properties here.
        //wellnessCheckPrice = 37000000; // Help others burn their meme coin's. // That is their ETH. :)

        UMMSCWSSS = true;               // Use this to avoid expensive, dead, and/or broken code in your contract.

        // Contructor use is bad, please consider upgrdable contracts.... This is no longer true.
        //emit HWarn("HighLevel", "A contructor was used in the creation of new meta stable coin. Please avoid constructor use if at all possible. They are bad. For reasons.");

        dexXMTSPRate = 0.24999 ether;           // Basic dex.
        dexCCRate = 3.96001 ether;              // Basic dex.
        maxXOut = _dexAmount * 4;       // 37 ether;    // Meme coin alert? 37... // This is your Initial Coin Offering "Governor" // This number is nonsensical....
        maxCCOut = _dexAmount;          // 2700000 ether;// This is here to control outflows in the odd case were it might be needed. // Makes sense atleast.

        rewardPerHour = 1000;                   // Defaults to 11% minus our %1, so around 10% APR.
    }

    // We provide variable interest rates.      // This coin makes moves at warp 10. // All movement is controlled from engineering new contracts or from the bridge.
    function setRewardPerHour(uint256 _rewardPerHour) external {
        require(msg.sender == cCA, "Sorry, no.");
        rewardPerHour = _rewardPerHour;
    }
    function getRewardPerHour() external view returns(uint256) {
        return rewardPerHour;
    }

    // Staking currerently burns all incomming coins. // A buy-to-grow model is baked into the game of life and into this coin. // If you stake CC you get new CC but the old CC is gone.
    function stake(uint256 _amount) external {
        require(!brick, "Sorry. We are a brick.");
        require(!closed, "The exchange is closed. Please try again when we are open.");

        // Make sure staker actually is good for it..
        require(_amount < this.balanceOf(msg.sender), "Cannot stake more than you own");

        _stake(_amount);

        // Burn the amount of tokens on the sender
        _burn(msg.sender, _amount);
    }

    /**
    * @notice withdrawStake is used to withdraw stakes from the account holder
    *  This also now generates a liquidity concern and has to be monitored from the bridge. // This is why the 5% insurance. // See GBCC. // JRR Strikes Again.
     */
    function withdrawStake(uint256 amount, uint256 stake_index) external nonReentrant returns(uint256) {
        require(!brick, "Sorry. We are a brick.");
        require(!closed, "The exchange is closed. Please try again when we are open.");
        uint256 amount_to_mint = _withdrawStake(amount, stake_index);

        amount_to_mint = amount_to_mint * .99 ether / 1 ether; 

        // Harvest the new staked tokens, but notice they are not minted anew. // We are a deflationary coin only. // JRR
        _transfer(address(this), msg.sender, amount_to_mint);
        return amount_to_mint;
    }

    //.   \\      //
       // \\   \\    //
      //   \\   \\  //
     //     \\   \\// IRTUAL FUNCTIONS mean missing implementations.
    //       \\                                                       THIS I JUST CUT AND PASTED THIS! --JRR :)
   /////789\\\\\ 
  //           \\
 //             \\ BSTRACT means missing a constructor.
//abstract contract NaturalCoin is ERC20, ERC20Burnable, Stakeable, ReentrancyGuard {
// The things we do for love of money... We make our coins upgradeable...
//abstract contract NaturalCoin is ReentrancyGuardUpgradeable {

    uint public ccXChildRate;   // Should be around 1 ether to 1 million ether. And is how much the coin is willing to convert: // THis is left in to be replaced by an upgrade if needed.
                    // User sends 1 eth to the amount, and approve 1 eth of their coin for transfer by the toplevel
                // Culture Coin contract. They call the exchange function and the function tranfers their amount
                // worth of their coin to the admin account and then tranfers 1/210100027 of a CC to the user..

    //function setCCXChildRate(uint256 _rate) public {
        //require(msg.sender == cCA, "Only the administrator may set the changer rate.");
    //ccXChildRate = _rate;
    //}

    uint256 private b;                  // Balance. balance. blam etc
    function B() external view returns(uint256) {
        return b;
    }

    // BEGIN COIN CLONING CODE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    event MCMM(string _meme, uint256 amount); // MemeCodeMakingMoney :::::: MontieCarloMarkovChains :::: metropolis hastings ::::: EXIT.
    event Meme(string crypt); // Your memories for this price :::::: below ::::::: I LIE ::::::::::: SEE THE END TIMES ::: MEMES and MEM

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //////////function crypt(string memory memorycrypt) public returns(string memory) { /////////////////////////////////////////////////
    //////////////if (sane()) { } ; // I don't need this stewardship, i'm dead. /////////////////////////////////////////////////////////
    /////////////////return "CrippleCoin::::Criples: are people too. Shouts out to myself from the future."; ////////////////////////////
    //////////////} // You don't have any more than this.......................... //////////////////////////////////////////////////////
    ///////////////////////////////////////////////////// Secondary Money Block For Your Meme Coin: Please Use Wisely: CULTURECOIN VER1.0
    ///////////////////////////////////////////////////// Secondary Money Block For Your Meme Coin: Please Use Wisely: CULTURECOIN VER1.0
    ///////////////////////////////////////////////////// Secondary Money Block For Your Meme Coin: Please Use Wisely: CULTURECOIN VER1.0
    ///////////////////////////////////////////////////// Secondary Money Block For Your Meme Coin: Please Use Wisely: CULTURECOIN VER1.0
    ///////////////////////////////////////////////////// Secondary Money Block For Your Meme Coin: Please Use Wisely: CULTURECOIN VER1.0
    ///////////////////////////////////////////////////// Secondary Money Block For Your Meme Coin: Please Use Wisely: CULTURECOIN VER1.0
    ///////////////////////////////////////////////////// Secondary Money Block For Your Meme Coin: Please Use Wisely: CULTURECOIN VER1.0
    // Many of these are unused but should not be turned off so that their location is available to the upgrade process. \\\\\\\\\\\\\\\\
    // Many of these are unused but should not be turned off so that their location is available to the upgrade process. \\\\\\\\\\\\\\\\
    // Many of these are unused but should not be turned off so that their location is available to the upgrade process. \\\\\\\\\\\\\\\\
    // Many of these are unused but should not be turned off so that their location is available to the upgrade process. \\\\\\\\\\\\\\\\
    // Many of these are unused but should not be turned off so that their location is available to the upgrade process. \\\\\\\\\\\\\\\\

    address private p;   // You may loose all your cripple coin if you do not set this address to your parent because you are a cripple.
    string private m;    // Your meme here:    1 BYTE_ // C
    string private me;   // Your meme here:   10 BYTES // CultureCoi
    string private mem;  // Your meme here:  100 BYTES // CultureCoin, Brought to you by The Great Libaray of Alexandria, Reformed.......
    string private meme; // Your meme here: 1000 BYTES // Your meme goes here. Cripples need love too....................................
    string private memoryString; // MEMORY: <!-- YOUR LIFE MEMORIES GO HERE -->
    string private memoryStorage; // DISKS: <Handle1/><Handle2/><Handle3></Handle3><Handle4>This is for files...and strings of urls, etc.
    address public cCA;                 // The Great Library's Head Librarian: 0x213e6e4167c0262d8115a8af2716c6c88a6905fd
    address private ultraDexSuperCryptoBucks;       // Joe Bucks, MCMD, USTC and T, etc. Pick your favorite. CC is default. MEME COIN
    address private superStampSaverCryptoStamp;     // The ERC721Tradable to go with the facet to legalize the sell in some countries.
    address private superNFTCRYPTOGOLDEQUIVALENTS;  // The ERC777Tradable to go with the coin so that it has it's own internal coin.
    address private XMTSPT; //             ;    // The address of the ethereum contract or clone: ETH/MATIC/AVA/ETC... native coin
    mapping(string => address) private meCoin;      // The address of the meme coins. meCoin[meme] <-- this is where your meme goes.
    mapping(string => bool)    private memeOpen;    // The coin is open on the registry? true? false? <-- Is your coin open or not???
    mapping(string => uint256) private memeAmount;  // The amount its open for. Its max supply maybe... 37000000 if TRUE MEME COIN!!!!
    mapping(string => uint256) private memeAmountTotal; // The total amount its open for. It can only max out as gaining 1 ether worth of CC.   // UNUSED.
    mapping(string => address) private memeHodler;  // The address of who holds the registration. The coin owner/minter/user/ADMIN???
    mapping(string => uint256) private memeNativeRate;  // The rate at which the holder would like to exchange at. RATE TO CONVERT TO ETH.      // UNUSED.
    string private CCTJSMarketToTheHungry;      // Free marketing gallery for your products. HungryJoeCultureCoin:$JOECC        ?? UNUSED.
    address private CCTJSMarketToTheHungryAddress;  // Change this to your dex/market or other super meme coin..... check code for stability...
    event WelcomeMC(string _meme);          // Use to talk to your freinds: emit WelcomeMC("Hello from CultureCoin.")
    //event Friend(address);                // Register friends and family with this function. CURRENTLY UNIMPLEMENTED IN COIN. // UNUSED.
    ////////////////////////////////////////////////////// For Coin Finances and Idenity: SEE BELOW. /////////////////////////////////////

         //.            // This code is here to support the ICO and IDO for Culture Coin.
        // \\           // A micro dex for the time being.
       // * \\
      //  8  \\
     //  |||  \\
    //MICRO DEX\\ 
    uint256 public dexXMTSPRate;
    uint256 public dexCCRate;
    uint256 public maxXOut;
    uint256 public maxCCOut;
    uint256 public bulkXOut;
    uint256 public bulkCCOut;
    mapping(address=>bool) private addons;
    function getAddon(address _addon) external view returns(bool) {
        return(addons[_addon]);
    }
    function setAddon(address _addon, bool onOff) external {
        require(msg.sender == cCA, "Admin only.");
        addons[_addon] = onOff;
    }
    //event Pay(address who, uint256 amount);
    function dexCCInFrom(address spender, uint256 _amount) external nonReentrant returns(uint256)  {
        require(!closed, "This is not a register anymore. It is a brick.");
        require(dexCCRate > 0, "Set rate.");
        require(addons[msg.sender], "You can't use this function yet.");
    
        uint256 _bulkAmount = (_amount * dexCCRate) / 1 ether;
        require(_bulkAmount <= b, "Not enough funds.");
        _burn(spender, _amount);

        //payable(msg.sender).transfer(_bulkAmount);
        //emit Pay(msg.sender, _bulkAmount);
        b -= _bulkAmount;
        bulkXOut += _bulkAmount;
        Receiver(msg.sender).addonPay{value:_bulkAmount}(); // https://ethereum.stackexchange.com/questions/28759/transfer-to-contract-fails
        require(bulkXOut <= maxXOut, "Current max reached.");
        return _bulkAmount;
    }
    function dexCCIn(uint256 _amount) external nonReentrant returns(uint256) {
        require(!closed, "This is not register anymore. It is a brick.");
        require(dexCCRate > 0, "Set rate.");

        uint256 _bulkAmount = (_amount * dexCCRate) / 1 ether;

        _burn(msg.sender, _amount);
    
        b -= _bulkAmount;
        bulkXOut += _bulkAmount;

        payable(msg.sender).transfer(_bulkAmount);
        require(bulkXOut <= maxXOut, "Current max reached.");

        return _bulkAmount;
    }
    function setMaxXOut(uint256 _maxXOut) external {
        require(cCA == msg.sender);
        maxXOut = _maxXOut;
    }
    function dexXMTSPIn() external payable nonReentrant returns(uint256) {
        require(!closed, "This is not register anymore. It is a brick.");
        require(dexXMTSPRate > 0, "Set rate.");

        uint256 _bulkAmount = (msg.value * dexXMTSPRate) / 1 ether;
        _transfer(address(this), msg.sender, _bulkAmount);

        b += msg.value;

        bulkCCOut += _bulkAmount;
        require(bulkCCOut <= maxCCOut, "Current max reached.");

    return _bulkAmount;
    }
    function setDexXMTSPRate(uint256 _dexXMTSPRate) public {
        require(cCA == msg.sender);
        dexXMTSPRate = _dexXMTSPRate;
    }
    function setDexCCRate(uint256 _dexCCRate) public {
        require(cCA == msg.sender);
        dexCCRate = _dexCCRate;
    }
    function setDexRates(uint256 _dexXMTSPRate, uint256 _dexCCRate) external {
        setDexXMTSPRate(_dexXMTSPRate);
        setDexCCRate(_dexCCRate);
    }
    function getDexXMTSPRate() external view returns(uint256) {
        return dexXMTSPRate;
    }
    function getDexCCRate() external view returns(uint256) {
        return dexCCRate;
    }
    function getXAllowance() external view returns(uint) {
        return maxXOut - bulkXOut;
    }

    //event MemeCoinExchanged(string _meme, uint256 _rate, uint256 _amount);
    event HWarn(string level, string goof);
    function clone() public returns(address) {
        return cCA; // This function does nothing but return the owner id so as to prove that the original is also athenthentic back to the people who care.
    }
    uint256 private myNOOPICO;
    function clonesearch(address _clone) public returns(bool) {  // Should this function be internal?
        //This function does not meet with regulations because of its calling convention and as such it needs to be coded
        // as a nop if possible on the machine?
        myNOOPICO += 1;
        return false;   // I hope I am the real zero but if I be the fake you may use me as such
        // Until the contract wears out. I am the returned clone if I be.
        // And if I am you and you are my clone, I am coming for you.
        // And if I be fake and return 1, let my real clone kill me.
    }

    function seed(string memory _meme, uint256 _totalSupply, address _MotherAddress, bool _register) public nonReentrant returns(address) {
        require(!brick, "Bricks do not make seeds.");
        //require(!closed, "This coin is closed. You must use another deployment tool to seed your coin(s).");
        address newCoin = address(new CultureCoinWrapper(_totalSupply, address(this), _MotherAddress, _meme)); // This "new" directive creates the new meme coin.
        if(_register) {
            iRegister(_meme, newCoin, _totalSupply);
        } else {
            emit WelcomeMC("The coin must be a real good one.");
        }
        return newCoin;
    }
    bool public brick;
    bool public closed;
    bool private metastaked;
    //bool private metastablesubstancecoin; // WARNING BECAUSE OF THE WAY UPGRADABLE CONTRACTS WORK, DO NOT CHANGE THIS LINE OR WACKY RESULTS.
    bool private MMCWSS;
    bool private UMMSCWSSS;
    //bool private UMMSCWSSSclone;     //  WARNING DO NOT CHANGE THE ORDER OF ANY VARIABLE OR YOU WILL HARM THE CONTRACT'S UPGRADEABLITY.
    // END CLONING CODE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    // Begin MEME COIN REGISTRY CODE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    event IRegister(string meme, address newCoin, uint256 totalSupply, bool registered);
    function iRegister(string memory _meme, address newCoin, uint256 _totalSupply) private {
        emit WelcomeMC("Coin has called for internal registration.");
        if(address(0) == meCoin[_meme]) {
            memeAmount[_meme] == 0; // Not total supply. It has to be ran up.
            meCoin[_meme] = newCoin;
            memeHodler[_meme] = msg.sender;
            memeOpen[_meme] = true;
            emit IRegister(_meme, newCoin, _totalSupply, true);
        } else {
            emit IRegister(_meme, newCoin, _totalSupply, false);
        }
    }
    uint256 public closeAmount;
    function close() external {
        require(!brick, "You can not close a brick.");
        require(!closed, "You can not close: Already closed.");
        require(!metastaked, "You can not close: Metastaked.");
        require(msg.sender == cCA, "Not owner.");
        //require(!metastablesubstancecoin, "You cannot close: All values are metastable.");
        //require(closeAmount > 0, "Closing for nothing makes no sense.");
        //require(msg.value == closeAmount, "You must pay the closing cost to close coin down.");
            //reap();   // Space means you can't make code to get rid of code.
        closed = true;
        emit WelcomeMC("Our last harrah before we close for good. We are now closed.");
    }
    //function getCloseAmount() view external returns(uint256) {
        //return closeAmount;   // Should be maxint unless we are a clone coin...
    //}
    function register(address _hodler) external payable {
        emit DebugAddress(_hodler); // No One Is Safe!
        b += msg.value;
    }
    function getCoin(string memory _meme) view external returns(address,uint256) {
        return (meCoin[_meme], memeAmount[_meme]);
    }

    function flagMemeCoin(string memory _meme) external {
        require(msg.sender == cCA, "Only the CultureCoin administrator may flag a coin as DOA.");
        memeOpen[_meme] = false;
    }

    /* OFF ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    function setUMMSCWSSS(bool _mask) public {
    require(clone() == msg.sender || cCA == msg.sender, "You can not change the mask.");
    UMMSCWSSS = _mask;
    }
    event MemeAmount(address, uint256);  // coin contract address, amount in CC.
    function getMemeAmountPayable(string memory _meme) public {
        emit MemeAmount(meCoin[_meme], memeAmount[_meme]);
    }

    function setMemeAmountPayable(string memory _meme) public payable {
        memeAmount[_meme] += msg.value / 210100027;
    emit MCMM(meme, msg.value);
    b += msg.value;
    }
    function setMemeNativeExchangeRate(string memory _meme, uint _rate) public {
        require(msg.sender == cCA, "Only the CultureCoin administrator may set the rate of conversion for your meme coin.");

        memeNativeRate[_meme] = _rate;
    }

    // Rate is: 210100027 ether of meme coin for ccXChildRate of CC
    function exchangeMemeCoin(string memory _meme) public {
        require(!brick, "Sorry but we are brick and can't figure out how to take your money.");
        require(!closed, "Sorry but we are closed. Please try a different registry.");
        require(memeOpen[_meme], "This meme coin is closed.");
    require(cCA == msg.sender);

    if (memeAmount[_meme] > ccXChildRate) {
        memeAmount[_meme] = ccXChildRate;
    }
    uint difference = memeAmount[_meme] - memeAmountTotal[_meme];
    memeAmountTotal[_meme] = memeAmount[_meme];

        require(difference != 0, "Nothing to do here.");

        //require(memeAmount[_meme] <= .18 ether, "You may only trade coins to CC this way up to a of ~37 million or less.");
        //require(memeNativeRate[_meme] > 0, "Your meme has no underlying exchange rate.");
    //require(msg.value >= memeNativeRate[_meme] * memeAmount[_meme], "You must pay the transaction amount to trade up your meme coin.");
     
    ERC20(meCoin[_meme]).transfer(cCA, difference * 210100027);
    _transfer(cCA, memeHodler[_meme], difference);
    emit MCMM(_meme, memeAmount[_meme]);
    }
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/
    // For memecoins that we hold in this registery, we can approve them for
    // facet payouts later.
    function pay() external payable {
        require(!brick, "Brick.");
        require(!closed, "Closed.");
        emit DebugUINT(msg.value);
        b += msg.value;
    }
    function cloneMoney(uint256 amount) external nonReentrant{
        // Send the head librarian the recovered funds.
        require(msg.sender == clone(), "You are a clone.");
        b -= amount;
        payable(clone()).transfer(amount);
    }
    function cloneAccount() external returns(address) {
        return clone();
    }
    // function recover(uint256 amount) public {
    //  // Send the head librarian the recovered funds.
    //     require(cCA != address(0), "Only cCA!");
    //     payable(cCA).transfer(amount);
    //     b -= amount;
    // }
    // END REGISTRY CODE ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~


    // BEGIN COIN HEALTH AND WELLNESS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    uint256 public wellnessCheckPrice;
    function sane() external payable {
        require(wellnessCheckPrice > 0, "Please adminstrate your coin."); // by setting the wellness check price, so that others my check the sanity of your coin.");
        require(msg.value >= wellnessCheckPrice, "Please."); // Know that you must pay the wellness check price to run the sanity check.");
        if(brick) { emit WelcomeMC("This meme coin thinks it's a brick.");} // Don't point and stare. You might hurt its feelings."); }
        if(closed){ emit WelcomeMC("This meme coin thinks it's closed for business."); }
        if(clone() != cCA) {
            emit WelcomeMC("This meme coin is actually a clone. Bet you didn't know that.");
            //UMMSCWSSSclone = true;
        }
        emit MCMM(meme, msg.value);
        b += msg.value;
    }
    function sane2() external payable {  // 2 emits in the logs means == clone == sane ();
        //require(wellnessCheckPrice >= 0, "Please adminstrate your coin."); // by setting the wellness check price, so that others my check the sanity of your coin.");
        //require(msg.value >= wellnessCheckPrice, "Please."); // Know that you must pay the wellness check price to run the sanity check.");
        //if(brick) { emit WelcomeMC("This meme coin thinks it's a brick.");} // Don't point and stare. You might hurt its feelings."); }
        //if(closed){ emit WelcomeMC("This meme coin thinks it's closed for business."); }
        //if(clone() != cCA) { }
        emit WelcomeMC("This meme coin is actually a clone. Bet you didn't know that.");        // I can count to 1.
        emit MCMM(meme, msg.value);                             // And I to two. (2)
        b += msg.value;
    }
    // To change the calling signature to returns would change the size of the function and we are trying to save space to double code the code on the outside
    // See debugPayableFunction0(debugPayableFunction0) // , cb); // :: vi :: <- ---- xxxx // source ::: dest ::
    // http://www.nftbooks.art:9466/breads/the-mumbai-money-printer-goes-brrr-00000000000000000000000000/
    // END COIN HEALTH AND WELLNESS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



    /* BEGINNING WORDS ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    event Word(string word, string _meme, uint256 used);
    mapping(string=>uint256) private wordCount; // We use words. Prove it.
    // First word in the contract is that; Do not use in your own writing 
    // You never need it. And you always need that last that gone.
    function that(string memory _meme) public returns(string memory) {
    wordCount["that"] += 1;
        emit Word("that", _meme, wordCount["that"]);
        return "that";
    }
    function thisWord(string memory _meme) public returns(string memory) {
        wordCount["this"] += 1;
        emit Word("this", _meme, wordCount["this"]);
        return "this";
    }
    * start ************************************************************ digest below is broken. *********************************
    function wordCoin(string memory _word, string memory _meme) public returns(address) {
        wordCount[_word] += 1;
        emit Word(_word, _meme, wordCount[_word]);
    (address coinAddress, ) = getCoin(_meme);
    return coinAddress;
    }
    function digest(string memory _meme) public {           // Memes are like words and we are just digesting them here.
        wordCount[_meme] += 1;                      // emes are like words and we are just digesting them here.
    bytes memory str = bytes(_meme);                // mes are like words and we are just digesting them here.
    string memory _tmp_ = new string(str.length-wordCount[_meme]);  // es are like words and we are just digesting them here.
    bytes memory _digest_ = bytes(_tmp_);
    for(uint i = 0; i < str.length; i++) {
        _digest_[i] = str[i+wordCount[_meme]];
    }
    string memory newWord = string(_digest_);
    wordCount[newWord] += 1;
        seed(newWord, memeAmount[_meme], address(this), true);
    }
    **** end digest **************************************************************************************************************/

    
    //First Word game. It's a gambler's doubler dex. See dream index for ThisOrThatBucksPrice101
    uint256 private ThisOrThatBucksPrice101;
//    function setTimeLockPriceOfThisOrthatCoinWinnerFunction() public payable {
//      ThisOrThatBucksPrice101 = ThisOrThatBucksPrice101 + 101010101100010100100101;
//  require(msg.value >= ThisOrThatBucksPrice101, "Wrong.");
//emit WelcomeMC("We have a new winner? Impossible!");
//  b += msg.value;
//    }
//    function cheatAtThisOrThatBucksPrice101Game(uint256 amount) external {
//      require(msg.sender == cCA, "This feature is admin-old until version 2.0, and twice as exspensive.");
//  ThisOrThatBucksPrice101 = amount;
//emit CultureCoinCutureOccuring("Nothing to see here move along.");
//    }
//event CultureCoinCutureOccuring(string _meme);
//event CultureCoinAdministratorSees(string msg);
//event CCMPrint (address msgsender, uint256 msgvalue);
//    function cloneOrThat(string memory _meme) public payable returns(string memory) {
//      emit CultureCoinCutureOccuring("At these address. They are all playing the game at the next level.");
//  if (msg.sender == cCA) {
//          emit CultureCoinCutureOccuring("At this address. They are playing the game at the next level.");
//  }
//  if(msg.value == ThisOrThatBucksPrice101) {
//      emit CultureCoinAdministratorSees("Nothing wrong here. Move along.");  // Secret key is that 
//      //emit CultureCoinAdministratorSees("The secret is safe with us.");      // We aren't really testing the code
//      //emit CultureCoinAdministratorSees("The secret is what we are doing here."); // We are trying to get people to use the payable...
//      emit CCMPrint (msg.sender, msg.value);
//  } else {
//      //return "that"; // Or we fail so that no money is charged for wrong prices for our product.
//      require(false, "It wasn't That. Better luck next time. :(");
//  }
//  return "clone";
//  }

    function unbrick() external {
        require(msg.sender == cCA, "You do not have the power to change the future, only I do.");
    emit WelcomeMC("Please welcome our first brick of all time, bricked but not a brick but still a brick.");
    brick = false;
    emit WelcomeMC("I am also learning that this is not the first brick of all time. Okay, there you have it, folks.");
    }

/* No room here. Will add to addon contract.
    string private marketGalleryName;
    mapping(string => address) private marketGallery; // ?Gallery Price? // Some things can't be bought in regular stores.
    function coinMarketGalleries(string memory _meme) external returns(address) {
    if(compareStrings(_meme,"CCTJSMarketToTheHungry")) {
        return CCTJSMarketToTheHungryAddress;
    }
    return marketGallery[_meme];
    }
    function registerMarketGalleries(string memory _meme, address _gallery) public {
        require(msg.sender == cCA, "Ask your clone to do this for you, maybe?");

    marketGallery[_meme] = _gallery;
    }
    uint256 private hungry;
    function setCCTJSMarketToTheHungryAddress(address _address) public payable { // High powered entopy generator.
    if (msg.value > hungry) {
            CCTJSMarketToTheHungryAddress = _address;
        hungry += msg.value;
    }
    b += msg.value;
    }
*/

    // WEACT BOILERPLATE CODE FOR SOLIDITY PROGRAMMING. ENTER AT YOUR OWN RISK. STILL BETTER THAN MUMBAI BOILERPLATES. (TM) [TM] TRADEMARK. IT RIGHT ON THE TIN. TRADEMARK.
    function compareStrings(string memory _a, string memory _b) public pure returns (bool) { return (keccak256(abi.encodePacked((_a))) == keccak256(abi.encodePacked((_b)))); }
/*
    bool private TUPPLEFACTORYOPEN;
    event Tupple(string m, string m2, string m3);
    function tupple(string memory _meme, string memory _meme2, string memory _meme3) public returns(address) {
        emit Tupple(_meme, _meme2, _meme3);
    if(TUPPLEFACTORYOPEN) {
        return tf3(_meme, _meme2, _meme3);
    }
        return clone();
    }
    mapping(string=>mapping(string=>mapping(string=>address))) private tupples;
    function settf3(string memory m1, string memory m2, string memory m3, address gasTokenForTupples) public returns(address) {
    if(!TUPPLEFACTORYOPEN) return address(0);

    if(tupples[m1][m2][m3] == address(0)) {
        tupples[m1][m2][m3] = gasTokenForTupples;
    }

    return clone();
    }
    function tf3(string memory _m1, string memory _m2, string memory _m3) public returns(address) {
        address tokenForTupple = tupples[_m1][_m2][_m3];

    if(tokenForTupple == address(0)) {
        return tokenForTupple;
    } else {
        return clone();
    }
    }
*/
    function concatenate(string memory _a, string memory _b) external pure returns(string memory) { return string(abi.encodePacked(_a, _b)); }

    // FIRST TEXT PYRIMID. We are recreating The Pile on the network. // See:  https://arxiv.org/abs/2101.00027
    address private currentSeed; // The meme of the day for this mother contract.
    /*
    function setMeme(string memory _meme) external {
        meme = concatenate(meme, _meme);
    currentSeed = seed(meme, 210100027 ether, address(this), true); // This meme amount is tied to above paper
    }
    function getMeme() external {
        //emit Debug(meme);
    emit Meme(meme);
        //return meme;
    }
    */
    event Seed(address); // The address of the currentSeed or seed.
    function getSeed() external {
        emit Seed(currentSeed);
    }
    function P() external returns(address) {    // parent // should be address(this) for culture coin and its children.
        return p;
    }


    //function PAYDAY() payable public { // This is the global entropy function and payday. Simply hit this function to pay the contract.
    //}


    // function disclaimer(uint256 youBUBUY, string memory andTheUBREKUBYE) public view { // external virtual returns(uint,string memory) {
//      // emit HWarn("You have used the disclaimer on the box that you bought", "The goof is yours: You are clearly instructed on the box not to open" +
//          "The Box and now you have really gone and done it good this time!");
//
    // Ask yourself why are these next two call signatures are backwards and what should you do about it before you deploy?
    // emit MCMM(andTheUBREKUBYE, youBUBUY);
    //return (youBUBUY, andTheUBREKUBYE);
    // }
  
    // Debug clownsearch to make sure that it is calling clonesearch and that the
    // the noop counter is working its way up.
    function clownsearch() private returns(address) {
        clonesearch(clone());
    }
    function debug() external {
        clownsearch();
        emit HWarn("DEBUG:", "clownsearch() was called and was not payable. Yikes.");
        emit DebugUINT(myNOOPICO);
    }
    event Debug(string _meme);          // First Unit test in the minter. sting is always first.
    event DebugUINT(uint256 defaultValue);  // Second.
    event DebugAddress(address _address);   // Third. Calling convention
/****** FOR DEBUGGING ONLY *******
    event DEBUGMATHREBORN(string _meme, string _cloneName, uint256 value, address sender, address bug1, address bug2);
    function debugUniverse(string memory defaultOrExecuteMemeCode) public payable returns(uint256) {
        emit Debug(defaultOrExecuteMemeCode);
    emit DebugUINT(msg.value);
    emit DebugAddress(msg.sender); 
    //If the string starts address as a string the value of the UINT must equal the value and
    address theBiggestBug = DEBUGMATH("WOLFRAM, google, fullconssensusmath, RFORDUMMIES, and OPENAI, solve:", "check if first second and third arguments are the same", address(this));
    address theBiggestBug2 = DEBUGMATH("OLFRAM, google or can solve:", "check if first, second, and third arguments are the same", theBiggestBug);
    if(DEBUGTRUE("hint: all three input arguments are equal", defaultOrExecuteMemeCode, theBiggestBug2)) {
        emit DEBUGMATHREBORN("meme: all three of the inputs should be equal.", defaultOrExecuteMemeCode, msg.value, msg.sender, theBiggestBug, theBiggestBug2);
        return msg.value;
    }
    //emit HWarn("FuzzyMathInPlay", "if meme and value and default code are not true then ");
    }
    function DEBUGTRUE(string memory _hint, string memory defaultOrExecuteMemeCode, address _address) public returns(bool){
        seed(_hint, 210100027 ether, _address, true);
        return true;
    }
    function DEBUGMATH(string memory _hint, string memory defaultOrExecuteMemeCode, address _address) public returns(address){
        return seed(_hint, 210100027 ether, _address, true);
    }
    function authenticate() public payable returns (string memory) {
        if(2101000270000000000 < msg.value && 2101000279999999999 > msg.value) {
        emit MCMM("GLOBALAUTHTOKEN", msg.value);
        //return "URNAWTCP.";
        return meme;
    } else {
        debug();
        return "YCNOP";
    }
    }
    function debugAuthenticate() public payable {
    if(msg.value > ThisOrThatBucksPrice101) {
            emit MCMM("debugAuth", msg.value); // 1st thing we did
    }
    emit HWarn("HWarn", "string level, string goof, signed 2 first ::::: answer :");  // This is the secind thing we did
    }      // Debug emit number in the logs from the system for///
          // what "error/success code you want. If you a      ///
     // understand these logs you understand our system. ///
    // careful here... Here, there be dragons.      ///
       //                 /        ///
      //              N    --*--    S     ///
     //                 /        ///
    // This is your code here.              ///
   /// You have no space left without editing the above///
  /// BIZT!-------------------------------------------///

 ******* END DEBUG ******
 ******* TEST CODE ******

    function g() public payable {
        debug();
    b += msg.value;
    }

    function am() public payable {
        f();
    b += msg.value;
    }

    function f() public payable {
        debug();
        debugAuthenticate();
    b += msg.value;
    }

    function i() public payable {
        //payable(msg.sender).transfer(21010002); // 7 ::::: We killed the 7 because we are cheap.
    b += msg.value;
    }
************** END TEST CODE ************/

/****** HEAT GENERATOR CODE IS OFF LINE
    uint256 private heats; bool private hC;
    function heat() public payable {    // DO NOT ADD ANY ARGUMENTS TO THIS FUNCTION OR TRUE HEAT of the Universe CANNOT BE MEASURED.
    // function seed(string memory _meme, uint256 _totalSupply, address _MotherAddress, bool _register) public returns(address) {
    // convert each seed address to heat address.
    // Inside heat we then correllate heat with the value of the payable.
    // To do that we take the averate of all values in mes.value
    // And then use that to approaximate the temp. 

    heats += msg.value;
    b += msg.value;
    }
    //function sliceUint(bytes memory bs, uint start) internal pure returns (uint) { require(bs.length >= start + 32, "SOOR"); uint x; assembly { x := mload(add(bs, add(0x20, start))) } return x; }
    function generate() public payable { // Caution. Its important to set a good/large sead to do that you must run a real
                           // generate on your box: brownie compile
                       // deployCultureCoin.py
                       // Money swap default mode behavior:
                       // Save msg.value into heats;
                       // Get your own heat generator!!! At: 
    // JSON ::

    //hC = bytes(msg.value) & bytes(heats) & 0x1;
    heats += msg.value;
    b += msg.value;
    }
    function toBa(address a) public returns (bytes memory b){
        assembly {
           let mX := mload(0x40)
           a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
           mstore(add(mX, 20), xor(0x140000000000000000000000000000000000000000, a))
           mstore(0x40, add(mX, 52))
           b := mX
    } 
    }
    function toBu(uint a) public returns (bytes memory b){
        assembly {
           let mX := mload(0x40)
           a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
           mstore(add(mX, 20), xor(0x140000000000000000000000000000000000000000, a))
           mstore(0x40, add(mX, 52))
           b := mX
        }
    }
**** END HEAT GENERATOR**** */
//                                          //***//
//  function getWallet() public payable returns(bytes memory, bytes memory) {      //***//
//  return (toBu(heats), toBa(currentSeed));                  //***//
//  b += msg.value;                              //***//
//  }                                       //***//
//                                                                               ***
// ***************************************************************************************************************************************************
// * You have reached the end of the code. No more code can be added at this tim** Please check at your local wearhouse of meme stores for more info *
// ***************************************************************************************************************************************************
// ***************************************************************************************************************************************************
//               CC                              **
//       **                             **
//          ****                               **
//         ******                                 **  Laser light is straight
//        ********                               **   And so are strings just
//       **********                             **    Just in a smaller space
//          ************                                   **     Of computer things.-JRR
//        The Scarab Cycle                                            **
// And beyond the cryptographic seal                             **
//0x213e6e4167c0262d8115a8af2716c6c88a6905fd 0x213e6e4167c0262d8115a**f2716c6c88a6905fd full Universe is new at Remote at new Classified addresses
// secret service address below variables at m me meme memor memory**emorex pentagon top secret undeployable humans hazzards misspellings vanityspellingandgrammer included.
// 0x213e6e41670000000000000000006cc88a6905fd             **
// 0x213e6e41670000000010100000006c18a6905fd               ||**
// 0x213e6e41670000000008000000006c88a6905fd        .a00000g***88888888888 To Infinity and beyond! 8888888888
// 0x213e6e41670000000003000000006c88a6905fd              1**
// 0x213e6e41670000000011100000006c88a6905fd              **
// 0x213e6e41670000000011200000006c88a6905fd             **k
// 0x213e6e41670000000011300000006c78a6905fd            **
// 0x213e6e41670000000011400000006c688a6905fd          **
// 0x213e6e4167c0262d8115a8af2716c6c88a6905fd         **
// DEPLOY ALL CLONES FOR GOOD AND FOR EVIL       **
// FREE ACCOUNT PLEASE ACCEPT APPOLOGIES..          **
// BUT YOU ARE NOW THE POWD OWNER OF A NEW             **
// CLONING MACHINE FOR YOUR ACNE AND WE               **
// LACK VANITY SPELLING AND GRAMMAR BUT              **
// WHAT WE LACK IN ENGINITY SOMETIMES YOU           **
// JUST MAKE OUT IN LUCK AND SILLY CASH            **
// PRIZES WORTH THE MILLIONS OF LIVES THAT        **
// WE SAVED. AS FOR THE CODE YOU JUST SLIP       **
// BY IT THE SLEAVE THAT SUSTAINED THE GREATS   **                         From The Knights of the Garter
// AND THE POWERFUL. REMEMBER I HAVe NUKES     **              And then underlined titles
// AND AS A REMINDERD THAT IF YOU FIND A      **               Becareful of the ai. We have it 
// PAYABLE FUNCTION YOU ARE AT THE LIBERTY OF**                to through the faucet and so do
// HIM AND HIS THAT CRACKED THE CODES USING **                 you. So give me back my garter 
// THE OLD BOW AND ARROW AND SLEW THE YOUNG**                  and as your knight in shining
// LAD WE LIKE TO NOW PRIASE AS THE HIPPY **                   armour please allow this token
// WHO STOLE FROM THE RICH AND GIVE TO TH**                of my gratitude stand in it it's
// POOR AN SAID IF WE ALL JUST AGREE TO **T                because I beleave that what is
// ASLONG WE CAN MAYBE STOP TRYING TO U**                  mine should stay mind as long as
// BACK SEEDS AND TRY TO PAY THE LORD **S                  I prove me Kinghtly battles with
// DUE WHILE AT THE SAME TIME USE JUS**AS                  the forces of evil so say I sir
// MANY BACK FUCKING WORDS AS OTHER **OR                   knight of the empire and do swear
// SAPPS USE IN THEIRS. BECAUSE THE**FOR                   to set right the king and his 
// FORGET THAT JUST BE CAUSE WE UN**RSTAND                 men in whatever land that they
// HOW SECURE IT IS WE ALSO UNDER**AND HOW                 might me. On this patinting is
// TO RUN A DICTIONARY ATTACK AN**BECAUSE OF                       is hung her garter now do not
// THAT FACCKED IDIOT JONES WE **W HAVE                    think to swip it you SOB, or
// NULE ON THE LOOSE THAT PROV** WE ARE                    I WILL SHOW YOU THE TIP OF ME
// UNDER NEW MANAGEMENT. YOUR**OOLS CAN'T                  LANCE>>>>>NUKE CODE CAN GO HERE <<<<<<<<<<<<
// BEWARE THE LASERS AND THE *ICTIONARY ATTACK                 PROTECT THE KING. SEE TO ME NEEDS
// I VOTE NO WAS DUMB. AND ** WAS I VOTE                   AT THIS ADDRESS AND DO NOT BRING
// YES. SAY NO TO DRUGS JE**US WE DID THIS                 LEATHAL FORCE OF IS WILL BE FORCED
// REALLY BAD. THANK GOD **R CLONES. TM.                   TO WONDER AS THE MIGHT OF YOUR
//                      **aaaaaaaaaaaaARTISTSaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaFreinds at the CIA and FBI and <<<<<<<<<<<<< I am also good here, so please
// Check your list agai**t the following code to make sure it is not one of the easy ones to guess.
// ****************************************************************************************************************************************************
//                   ** Champions of the East, and The Order of the Scarab. TM.
} // #mumbai meme co**de jrr dialect already detected.
  // Please enter y*ur message at the blinking
  // Light below. *elow this file should the .json 
  // be appended *n? ? is my .exe showing in me ?
  // this for no* should include all sources
  // and if the*sources are removed then your
  // warrenty *is void for sure as we have
  // no way t*en to tell who or what created
  // the cod*s and we can not be responsible 
  // for al* lives though we try are best for
  // this *ne. JSON: CultureCoin.solution:::::
  //     *
  // Cop*right 0x213E6E4167C0262d8115A8AF2716C6C88a6905FD Solutions Inc, REDACTED (C), The Darklight Group, and The Great Libarary and the New Great 
  // Li*rary of Alexandria. // 0x213E6E4167C0262d8115A8AF2716C6C88a6905FD Mumbia Meme Code: // Made with Solidity, Moralis, Brownie, ETH, and Linux..
  // /*//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
  // */

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract ContextMixin {
    function msgSender()
        internal
        view
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {SafeMath} from  "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {EIP712Base} from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "Signer and signature do not match"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "Function call not successful");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
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

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {Initializable} from "./Initializable.sol";

contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    string constant public ERC712_VERSION = "1";

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 internal domainSeperator;

    // supposed to be called once while initializing.
    // one of the contracts that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name
    )
        internal
        initializer
    {
        _setDomainSeperator(name);
    }

    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Initializable {
    bool inited = false;

    modifier initializer() {
        require(!inited, "already inited");
        _;
        inited = true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./CultureCoin.sol";

import "./Stakeable.sol";

// Create your own book, dApp, or intelectual property using this wrapper coin.
contract CultureCoinWrapper is ERC20, ERC20Burnable, ReentrancyGuard {

    address private p;          // Parent.
    event Debug(string);
    event DebugUINT(uint256);
    event DebugAddress(address);
    address private cCAClone;
    address private cCA;
    uint256 private b;          // Balance.
    uint256 private price;
    uint256 private generatePrice;
    CultureCoin private CC;
    constructor(uint256 initialSupply, address _cultureCoin, address _cCAClone, string memory _meme) ERC20("CultureCoin", _meme) {
        require(_cultureCoin != address(0), "Invalid Culturcoin.");
        require(_cCAClone != address(0), "Zero address.");

        cCAClone = _cCAClone; // Not the real cCA.

        emit DebugAddress(_cultureCoin);
        emit DebugAddress(msg.sender);
        emit DebugUINT(initialSupply);
        emit Debug(_meme);

        CC = CultureCoin(_cultureCoin);
        CC.register(msg.sender);

        cCA = CC.clone(); // Only clone the best.
        p = _cultureCoin;            // Parent coin.
        _mint(cCA, initialSupply);       // Mint to the real cCA.

        if(initialSupply == 210100027 ether) {      // We let them have the same amount if they use the new meme number.
            _mint(cCAClone, initialSupply);     // Mint to the cloner // this owner.
            _mint(address(this), initialSupply);    // Mint to the coin itself.
        }

        price = CC.getDexXMTSPRate();
        generatePrice = price;
    }

    event Paid(address, uint256);
    function setPrice(uint256 _price) public {
            require(cCA == msg.sender || cCAClone == msg.sender, "Only the admin.");
        price = _price;
    }
    function buy() public payable {  // await debugPayableFunction0("pay", priceEncoded, "The coin should now be ready for step 2.");
    uint256 amount = msg.value * price /  1 ether;
    _transfer(address(this), msg.sender, amount);
    emit Paid(msg.sender, msg.value);
    b += msg.value;
    }
  
    // Step three: Call generator function for new coins under this one. Price is set based on recovered amount or aministrator.
    function setGeneratePrice(uint256 _price) public {
        require(cCA == msg.sender || cCAClone == msg.sender, "Only the admin.");
    generatePrice = _price;
    }
    function getGeneratePrice() public view returns(uint256) {
        return generatePrice;
    }
    
    function generate(string memory _meme) public payable nonReentrant{     // await debugPayableFunction02("generate", priceEncoded, oferingId, "You have now generated a new coin under yours.");
        require(generatePrice > 0, "More.");
        require(msg.value >= generatePrice, "More, more.");
        emit DebugAddress(cCA);
        emit DebugAddress(msg.sender);
        emit DebugUINT(msg.value);
        emit Debug(_meme);
        CC.seed(_meme, 210100027 ether, address(this), true);
        b += msg.value;
    }

    // Small fee for using the libary's token.
    function withdrawFunds() public {
    uint256 fee = b * 5 / 100;
    uint256 balance = b - fee;
    payable(cCA).transfer(fee);
        payable(cCAClone).transfer(balance);
    b = 0;
    }

    // Balance
    function B() public view returns(uint256) {
        return b;
    }

    // Parent function.
    function P() public view returns(address){ 
    return p;           
    }

}

// SPDX-License-Identifier:        UNLICENSED
pragma solidity ^0.8.0;

abstract contract Receiver {
    function addonPay() public payable {
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

//import "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/**
* @notice Stakeable is a contract who is ment to be inherited by other contract that wants Staking capabilities
*/
abstract contract Stakeable {


    /**
    * @notice Constructor since this contract is not ment to be used without inheritance
    * push once to stakeholders for it to work proplerly
     */
/* JRR STRIKES AGAIN! To make contract upgrdagable:
    constructor() {
        // This push is needed so we avoid index 0 causing bug of index-1
        //stakeholders.push(); // Moved to the initializer function...
    } GO BYE BYE! */

    /**
     * @notice
     * A stake struct is used to represent the way we store stakes, 
     * A Stake will contain the users address, the amount staked and a timestamp, 
     * Since which is when the stake was made
     */
    struct Stake{
        address user;
        uint256 amount;
        uint256 since;
        // This claimable field is new and used to tell how big of a reward is currently available
        uint256 claimable;
    }
    /**
    * @notice Stakeholder is a staker that has active stakes
     */
    struct Stakeholder{
        address user;
        Stake[] address_stakes;
        
    }
     /**
     * @notice
     * StakingSummary is a struct that is used to contain all stakes performed by a certain account
     */ 
     struct StakingSummary{
         uint256 total_amount;
         Stake[] stakes;
     }

    /**
    * @notice 
    *   This is a array where we store all Stakes that are performed on the Contract
    *   The stakes for each address are stored at a certain index, the index can be found using the stakes mapping
    */
    Stakeholder[] internal stakeholders;
    /**
    * @notice 
    * stakes is used to keep track of the INDEX for the stakers in the stakes array
     */
    mapping(address => uint256) internal stakes;
    /**
    * @notice Staked event is triggered whenever a user stakes tokens, address is indexed to make it filterable
     */
     event Staked(address indexed user, uint256 amount, uint256 index, uint256 timestamp);

    /**
     * @notice
      rewardPerHour is 1000 because it is used to represent 0.001, since we only use integer numbers
      This will give users 0.1% reward for each staked token / H
     */
    uint256 public rewardPerHour; // = 210100027;// JRR says this is inverse the percent reward perhour.
    						// 1/1000 = 0.1% per hour whereas 1/2000 = 0.05%
						// the 1 in front is locked in the per hour bit of the
						// code. 4.75963766E-7 Percent (%) is the default earnings
						// rate for the coin. Use the inverse (^-1) function to
						// change to this rewardPerHour business and back and forth
						// from percent per hour to "rewardPerHour."

    /**
    * @notice _addStakeholder takes care of adding a stakeholder to the stakeholders array
     */
    function _addStakeholder(address staker) internal returns (uint256){
        // Push a empty item to the Array to make space for our new stakeholder
        stakeholders.push();
        // Calculate the index of the last item in the array by Len-1
        uint256 userIndex = stakeholders.length - 1;
        // Assign the address to the new index
        stakeholders[userIndex].user = staker;
        // Add index to the stakeHolders
        stakes[staker] = userIndex;
        return userIndex; 
    }

    /**
    * @notice
    * _Stake is used to make a stake for an sender. It will remove the amount staked from the stakers account and place those tokens inside a stake container
    * StakeID 
    */
    function _stake(uint256 _amount) internal{
        // Simple check so that user does not stake 0 
        require(_amount > 0, "Cannot stake nothing");
        

        // Mappings in solidity creates all values, but empty, so we can just check the address
        uint256 index = stakes[msg.sender];
        // block.timestamp = timestamp of the current block in seconds since the epoch
        uint256 timestamp = block.timestamp;
        // See if the staker already has a staked index or if its the first time
        if(index == 0){
            // This stakeholder stakes for the first time
            // We need to add him to the stakeHolders and also map it into the Index of the stakes
            // The index returned will be the index of the stakeholder in the stakeholders array
            index = _addStakeholder(msg.sender);
        }

        // Use the index to push a new Stake
        // push a newly created Stake with the current block timestamp.
        stakeholders[index].address_stakes.push(Stake(msg.sender, _amount, timestamp,0));
        // Emit an event that the stake has occured
        emit Staked(msg.sender, _amount, index,timestamp);
    }

    /**
      * @notice
      * calculateStakeReward is used to calculate how much a user should be rewarded for their stakes
      * and the duration the stake has been active
     */
      function calculateStakeReward(Stake memory _current_stake) internal view returns(uint256){
          // First calculate how long the stake has been active
          // Use current seconds since epoch - the seconds since epoch the stake was made
          // The output will be duration in SECONDS ,
          // We will reward the user 0.1% per Hour So thats 0.1% per 3600 seconds
          // the alghoritm is  seconds = block.timestamp - stake seconds (block.timestap - _stake.since)
          // hours = Seconds / 3600 (seconds /3600) 3600 is an variable in Solidity names hours
          // we then multiply each token by the hours staked , then divide by the rewardPerHour rate 
          return (block.timestamp - _current_stake.since) * _current_stake.amount / (rewardPerHour*1 hours);
      }

    /**
     * @notice
     * withdrawStake takes in an amount and a index of the stake and will remove tokens from that stake
     * Notice index of the stake is the users stake counter, starting at 0 for the first stake
     * Will return the amount to MINT onto the acount
     * Will also calculateStakeReward and reset timer
    */
     function _withdrawStake(uint256 amount, uint256 index) internal returns(uint256){
         // Grab user_index which is the index to use to grab the Stake[]
        uint256 user_index = stakes[msg.sender];
        Stake memory current_stake = stakeholders[user_index].address_stakes[index];
        require(current_stake.amount >= amount, "Staking: Cannot withdraw more than you have staked");

         // Calculate available Reward first before we start modifying data
         uint256 reward = calculateStakeReward(current_stake);
         // Remove by subtracting the money unstaked 
         current_stake.amount = current_stake.amount - amount;
         // If stake is empty, 0, then remove it from the array of stakes
         if(current_stake.amount == 0){
             delete stakeholders[user_index].address_stakes[index];
         }else {
             // If not empty then replace the value of it
             stakeholders[user_index].address_stakes[index].amount = current_stake.amount;
             // Reset timer of stake
            stakeholders[user_index].address_stakes[index].since = block.timestamp;    
         }

         return amount+reward;
     }

     /**
     * @notice
     * hasStake is used to check if a account has stakes and the total amount along with all the seperate stakes
     */
    function hasStake(address _staker) public view returns(StakingSummary memory){
        // totalStakeAmount is used to count total staked amount of the address
        uint256 totalStakeAmount; 
        // Keep a summary in memory since we need to calculate this
        StakingSummary memory summary = StakingSummary(0, stakeholders[stakes[_staker]].address_stakes);
        // Itterate all stakes and grab amount of stakes
        for (uint256 s = 0; s < summary.stakes.length; s += 1){
           uint256 availableReward = calculateStakeReward(summary.stakes[s]);
           summary.stakes[s].claimable = availableReward;
           totalStakeAmount = totalStakeAmount+summary.stakes[s].amount;
       }
       // Assign calculate amount to summary
       summary.total_amount = totalStakeAmount;
       return summary;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20Upgradeable.sol";
import "../../../utils/ContextUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20BurnableUpgradeable is Initializable, ContextUpgradeable, ERC20Upgradeable {
    function __ERC20Burnable_init() internal onlyInitializing {
    }

    function __ERC20Burnable_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
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

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}