// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**

  ________              __   _____                  __      
  / ____/ /_  ____ _____/ /  / ___/____  ____  _____/ /______
 / /   / __ \/ __ `/ __  /   \__ \/ __ \/ __ \/ ___/ __/ ___/
/ /___/ / / / /_/ / /_/ /   ___/ / /_/ / /_/ / /  / /_(__  ) 
\____/_/ /_/\__,_/\__,_/   /____/ .___/\____/_/   \__/____/  
                               /_/                           


*/

// OpenZeppelin
import "./ERC1155.sol";
import "./ERC1155Supply.sol";
import "./IERC721.sol";
import "./IERC2981.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

// Chainlink
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

// Raffle
import "./IRaffle.sol";

// Utils functions
import "./Utils.sol";

/// @title Chad Sports Minting.
/// @author Memepanze
/** @notice ERC1155 Minting contract for Chad Sports.
* - Minting: The contract allows to mint specific Teams (1 or 4 ERC1155 tokenId(s)) or to mint randomly Teams (1 or 4 ERC1155 tokenId(s))
* - The randomness is powered by Chainlink VRF.
* There is no maximum supply, however the minting period is 24h.
* - Discount: There are two types of Discount Price: normal discount and Chad discount.
* -- Normal Discount: For that feature we will allow the holders addresses of collection that we partner with + addresses that participate to the whitelisting process on social media and website.
* -- Normal Discount benefits: a discount price to mint Teams during the minting period.
* -- Chad Discount: Only the 32 hodlers of the unique Chad collection (1:1) can be part of the ChadList
* -- Chad Discount Benefits: The 32 hodlers can freemint 4 teams of their choice only one time.
*/

contract ChadSports is ERC1155, ERC1155Supply, IERC2981, ReentrancyGuard, VRFConsumerBaseV2, Ownable {
    using Strings for uint256;

    /// @notice The Name of collection 
    string public name;
    /// @notice The Symbol of collection 
    string public symbol;
    /// @notice The URI Base for the metadata of the collection 
    string public _uriBase;

    /// @notice The start date for the minting
    /// @dev for the 2022 world cup 1668877200
    uint public startDate;

    /// @notice The end date for the minting
    /// @dev for the 2022 world cup 1668952800
    uint public endDate;

    /// @notice The address of the Raffle contract 
    address public raffle;

    /// @notice The struct used for the 1:1 hodlers 
    struct chadState {
        bool isAuthorized;
        bool hasMint;
    }

    /// @notice The minting state of each 1:1 hodler 
    mapping(address => chadState) public chadlist;
    
    /// @notice The authorization to mint with discount price for each address
    mapping(address => bool) public discountlist;

    /// @notice The struct used for the VRF requests
    struct RequestStatus {
        address sender; // msg.sender of the request
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
    }

    /// @notice The request status for each request ID (Chainlink VRF)
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    // VRFCoordinatorV2Interface COORDINATOR;

    /// @notice The subscription ID (Chainlink VRF)
    uint64 s_subscriptionId;

    /// @notice The past resquests Id (Chainlink VRF)
    uint256[] public requestIds;
    /// @notice The last resquest Id (Chainlink VRF)
    uint256 public lastRequestId;

    /** @notice The gas lane to use, which specifies the maximum gas price to bump to.
      * For a list of available gas lanes on each network,
      * see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
      */
    bytes32 keyHash = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;

    /** @notice Depends on the number of requested values that you want sent to the
      * fulfillRandomWords() function. Storing each word costs about 20,000 gas,
      * so 100,000 is a safe default for this example contract. Test and adjust
      * this limit based on the network that you select, the size of the request,
      * and the processing of the callback request in the fulfillRandomWords()
      * function.
      */
    uint32 callbackGasLimit = 500000;

    /// @notice The number of block confirmation, the default is 3, but it can be set this higher.
    uint16 requestConfirmations = 3;

    /// @notice The number of random numbers to request. 
    /// @dev Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWordsSingle = 1;
    uint32 numWordsBatch = 4;

    /// @notice royalties recipient address
    address _recipient;

    /// @notice The standard mint price for single specific mint
    uint internal mintPrice;
    /// @notice The discount mint price for single specific mint
    uint internal discountMintPrice;

    /// @notice The standard mint price for batch specific mint
    uint internal mintBatchPrice;
    /// @notice The discount mint price for batch specific mint
    uint internal discountMintBatchPrice;

    /// @notice The standard mint price for single random mint
    uint internal mintRandomPrice;
    /// @notice The discount mint price for single random mint
    uint internal discountMintRandomPrice;

    /// @notice The standard mint price for batch random mint
    uint internal mintBatchRandomPrice;
    /// @notice The discount mint price for batch random mint
    uint internal discountMintBatchRandomPrice;

    /// @notice Emitted on mintRandom()
    /// @param requestId The request id for the VRF request
    /// @param numWords number of random numbers requested
    event RequestSent(uint256 requestId, uint32 numWords);
    /// @notice Emitted on fulfillRandomWords()
    /// @param requestId The request id for the VRF fulfilled request
    /// @param randomWords number of random numbers requested
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    event BalanceWithdraw(address to, uint amount);

    // E R R O R S

    error Chad__Unauthorized();

    error Chad__NotInTheMitingPeriod();

    error Chad__TransferFailed();

    // M O D I F I E R S
    
    /// @notice Check if the minter is an externally owned account
    modifier isEOA() {
        if (tx.origin != msg.sender) {
            revert Chad__Unauthorized();
        }
        _;
    }

    /**
    * @dev Modifier to set the minting price for the specific mint functions
    * @param _ids The NFT ids to mint
    */
    modifier payableMint(uint[] memory _ids) {
        require(block.timestamp >= startDate && block.timestamp <= endDate);
        if(_ids.length > 1){
            if(discountlist[msg.sender]){
                require(msg.value >= discountMintBatchPrice/100);
            } else if(chadlist[msg.sender].isAuthorized) {
                require(!chadlist[msg.sender].hasMint);
                chadlist[msg.sender].hasMint = true;
            } else{
                require(msg.value >= mintBatchPrice/100);
            }
        } else {
            if(discountlist[msg.sender]){
                require(msg.value >= discountMintPrice/100);
            } else {
                require(msg.value >= mintPrice/100);
            }
        }
        _;
    }

    /**
    * @dev Modifier to set the minting price for the random mint functions
    * @param _number The number of NFTs to mint
    */
    modifier payableRandomMint(uint _number) {
        if(block.timestamp >= startDate && block.timestamp <= endDate){
            if(_number == 1){
                if(discountlist[msg.sender]){
                    require(msg.value >= discountMintRandomPrice/100);
                } else {
                    require(msg.value >= mintRandomPrice/100);
                }
            } else {
                if(discountlist[msg.sender]){
                    require(msg.value >= discountMintBatchRandomPrice/100);
                } else{
                    require(msg.value >= mintBatchRandomPrice/100);
                }
            }
        } else {
            revert Chad__NotInTheMitingPeriod();
        }
        _;
    }

    constructor(uint64 _vrfSubId) ERC1155("")
        VRFConsumerBaseV2(0x2eD832Ba664535e5886b75D64C46EB9a228C2610)
        {
        name = "ChadSports";
        symbol = "CHAD";
        _uriBase = "ipfs://QmQyoRPzJpceXmv3uApjam8hLYXwRgThvg8vQ4wdWX9p4M/"; // IPFS base for ChadSports collection

        mintPrice = 2 ether;
        // 20000000000000000
        discountMintPrice = 1 ether;
        // 10000000000000000

        mintBatchPrice = 8 ether;
        // 80000000000000000
        discountMintBatchPrice = 6 ether;
        // 60000000000000000

        mintRandomPrice = 1 ether;
        // 10000000000000000
        discountMintRandomPrice = 0.5 ether;
        // 5000000000000000

        mintBatchRandomPrice = 4 ether;
        // 40000000000000000
        discountMintBatchRandomPrice = 2 ether;
        // 20000000000000000

        s_subscriptionId = _vrfSubId;
    }

    /// @notice Set the start date (timestamp) for the minting.
    function setStartDate(uint _date) external onlyOwner {
        startDate = _date;
    }

    /// @notice Set the end date (timestamp) for the minting.
    function setEndDate(uint _date) external onlyOwner {
        endDate = _date;
    }

    /// @notice Set the new base URI for the collection.
    function setUriBase(string memory _newUriBase) external onlyOwner {
        _uriBase = _newUriBase;
    }

    /// @notice URI override for OpenSea traits compatibility.
    function uri(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_uriBase, tokenId.toString(), ".json"));
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    /// @notice Admin function to change the VRF subscription ID
    function changeSubscription(uint64 _sub) external onlyOwner {
        s_subscriptionId = _sub;
    }

    /// @notice Set the Raffle contract address.
    function setRaffleContract(address _addr) external onlyOwner {
        raffle = _addr;
    }

    // D I S C O U N T

    /// @notice Set the authorization for discount price for each address.
    /// @param _addresses An array of addresses to set authorization.
    function addDiscountlist(address[] calldata _addresses) external onlyOwner {
        for(uint i; i < _addresses.length; i++){
            discountlist[_addresses[i]] = true;
        }
    }

    /// @notice Set the authorization for freemint for each 1:1 Holders.
    /// @param _addresses An array of addresses to set authorization.
    function addChadlist(address[] calldata _addresses) external onlyOwner {
        for(uint i; i < _addresses.length; i++){
            chadlist[_addresses[i]].isAuthorized = true;
        }
    }

    // M I N T

    /// @notice Mint specific tokenIDs.
    /// @param _ids An array of the tokenIDs to mint.
    /// @dev the array must contain 1 or 4 values
    function mint(uint[] memory _ids) public payable nonReentrant isEOA
        payableMint(_ids) {
        if(_ids.length > 1){
            require(_ids.length == 4);

            uint[] memory amount = new uint[](4);
            amount[0] = 1;
            amount[1] = 1;
            amount[2] = 1;
            amount[3] = 1;

            _mintBatch(msg.sender, _ids, amount, "");
        } else {
            _mint(msg.sender, _ids[0], 1, "");
        }
        IRaffle(raffle).incrementMinters(msg.sender);
    }

    mapping (uint => address) randomMinters;

    /// @notice Function to request random numbers.
    /// @param _numberOfNFTs The number of NFTs to mint.
    /// @dev Call Chainlink VRF to request random numbers and callback fulfillRandomWords.
    /// @dev Assumes the subscription is funded sufficiently.
    /// @return requestId
    function mintRandom(uint _numberOfNFTs) external payable nonReentrant isEOA 
        payableRandomMint(_numberOfNFTs) returns (uint256 requestId) {
        // Will revert if subscription is not set and funded.
        requestId = VRFCoordinatorV2Interface(0x2eD832Ba664535e5886b75D64C46EB9a228C2610).requestRandomWords(
            keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            _numberOfNFTs == 1 ? numWordsSingle : numWordsBatch
        );
        s_requests[requestId] = RequestStatus({exists: true, fulfilled: false, sender: msg.sender});
        requestIds.push(requestId);
        lastRequestId = requestId;
        if(_numberOfNFTs == 1){
            emit RequestSent(requestId, numWordsSingle);
        } else {
            emit RequestSent(requestId, numWordsBatch);
        }
        randomMinters[requestId] = msg.sender;
        return requestId;
    }

    /**
    * @notice Callback function called by the Chainlink Oracle with the array 
    * containing the random numbers to mint the ERC1155 tokens.
    * @dev if the number of random numbers is higher than 1, the myRandNum array 
    * must contain unique numbers to prevent the minting of similar tokenIDs 
    * for the user.
    */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(s_requests[_requestId].exists);

        uint[] memory myRandNum = new uint[](4);

        if(_randomWords.length>1){
            for(uint i=0; i<_randomWords.length; i++){
                uint j;
                uint randnum = _randomWords[i] % 32;
                if(randnum < 30){
                    while(Utils.indexOf(myRandNum, ((randnum) + 2*j)) > -1){
                        j++;
                    }
                    myRandNum[i] = (randnum) + 2*j;
                } else {
                    while(Utils.indexOf(myRandNum, ((randnum) - 2*j)) > -1){
                        j++;
                    }
                    myRandNum[i] = (randnum) - 2*j;
                }
            }

            uint[] memory ids = new uint[](4);
            ids[0] = myRandNum[0];
            ids[1] = myRandNum[1];
            ids[2] = myRandNum[2];
            ids[3] = myRandNum[3];
            
            uint[] memory amounts = new uint[](4);
            amounts[0] = 1;
            amounts[1] = 1;
            amounts[2] = 1;
            amounts[3] = 1;

            _mintBatch(s_requests[_requestId].sender, ids, amounts, "");
        } else {
            uint r = Utils.randomNum(101);
            if(r>=20){
                myRandNum[0] = _randomWords[0] % 20;
            } else if (r<20 && r>=5){
                myRandNum[0] = (_randomWords[0] % 10) + 20;
            } else {
                myRandNum[0] = (_randomWords[0] % 2) + 30;
            }
            _mint(s_requests[_requestId].sender, myRandNum[0], 1, "");
        }
        // Push the address of the minter in the Raffle Index
        IRaffle(raffle).incrementMinters(randomMinters[_requestId]);

        emit RequestFulfilled(_requestId, _randomWords);

    }

    /// @notice Withdraw the contract balance to the contract owner
    /// @param _to Recipient of the withdrawal
    function withdrawBalance(address _to) external onlyOwner nonReentrant {
        uint amount = address(this).balance;
        bool sent;

        (sent, ) = _to.call{value: amount}("");
        if (!sent) {
            revert Chad__TransferFailed();
        }

        emit BalanceWithdraw(_to, amount);
    }

    // R O Y A L T I E S

    /// @dev Royalties implementation.

    /**
     * @dev EIP2981 royalties implementation: set the recepient of the royalties fee to 'newRecepient'
     * Maintain flexibility to modify royalties recipient (could also add basis points).
     *
     * Requirements:
     *
     * - `newRecepient` cannot be the zero address.
     */

    function _setRoyalties(address newRecipient) internal {
        require(newRecipient != address(0));
        _recipient = newRecipient;
    }

    function setRoyalties(address newRecipient) external onlyOwner {
        _setRoyalties(newRecipient);
    }

    // EIP2981 standard royalties return.
    function royaltyInfo(uint256 _salePrice) external view override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (_recipient, (_salePrice * 6) / 100);
    }

    // EIP2981 standard Interface return. Adds to ERC1155 and ERC165 Interface returns.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC1155, IERC165)
        returns (bool)
    {
        return (
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId)
        );
    }
}