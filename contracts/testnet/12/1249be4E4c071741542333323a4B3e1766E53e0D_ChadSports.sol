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

// Chainlink
import "./VRFCoordinatorV2Interface.sol";
import "./VRFConsumerBaseV2.sol";

import "./Utils.sol";

contract ChadSports is ERC1155, ERC1155Supply, IERC2981, VRFConsumerBaseV2, Ownable {
    using Strings for uint256;

    function setUniqueCollectionContract(address _addrDiscount) external onlyOwner {
        uniqueCollection = _addrDiscount;
    }

    constructor() ERC1155("")
        VRFConsumerBaseV2(0x2eD832Ba664535e5886b75D64C46EB9a228C2610)
        {
        name = "TestChad";
        symbol = "TSTCHAD";
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

        s_subscriptionId = 430;

        uniqueCollection = 0xC4FA8Ef3914b2b09714Ebe35D1Fb101F98aAd13b;
    }

    string public name;
    string public symbol;
    string public _uriBase;

    function setUriBase(string memory _newUriBase) external onlyOwner {
        _uriBase = _newUriBase;
    }

    /** @dev URI override for OpenSea traits compatibility. */

    function uri(uint256 tokenId) override public view returns (string memory) {
        return string(abi.encodePacked(_uriBase, tokenId.toString(), ".json"));
    }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }

    // D I S C O U N T

    address public uniqueCollection;

    struct discountState {
        bool isAuthorized;
        bool hasMint;
    }
    mapping(address => discountState) public chadlist;

    address[] public nftPartners;

    function addNftPartner(address _addrCollection) external onlyOwner {
        nftPartners.push(_addrCollection);
    }

    mapping(address => bool) public discountlist;

    mapping(address=> mapping(uint => address)) public nftOwner;

    function setNFTOwner(address _nftContract, uint _tokenID) public discountType(_nftContract) {
        //require(Utils.indexOfAddresses(nftPartners, _nftContract) > -1);
        require(nftOwner[_nftContract][_tokenID] == address(0), "This token ID has already an owner");
        require(IERC721(_nftContract).ownerOf(_tokenID) == msg.sender, "You are not the owner of this token ID");
        nftOwner[_nftContract][_tokenID] = msg.sender;
    }

    event DiscountLog(string _msg);

    modifier discountType(address _nftContract) {
        _;
        if(Utils.indexOfAddresses(nftPartners, _nftContract) > -1){
            discountlist[msg.sender] = true;
        } else if (_nftContract == uniqueCollection){
            chadlist[msg.sender].isAuthorized = true;
        } else {
            revert("No Discount");
        }
    }

    function mint(uint[] memory _ids) public payable
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
    }

    // V R F
    /** @dev Minting funtions. */

    function changeSubscription(uint64 _sub) external onlyOwner {
        s_subscriptionId = _sub;
    }


    function withdrawEth(address _receiver) public payable onlyOwner {
        payable(_receiver).transfer(address(this).balance);
    }

    /** @dev VRF Implementation. */

    event RequestSent(uint256 requestId, uint32 numWords);
    event RequestFulfilled(uint256 requestId, uint256[] randomWords);

    struct RequestStatus {
        address sender; // msg.sender of the request
        bool fulfilled; // whether the request has been successfully fulfilled
        bool exists; // whether a requestId exists
    }
    mapping(uint256 => RequestStatus) public s_requests; /* requestId --> requestStatus */
    // VRFCoordinatorV2Interface COORDINATOR;

    // Your subscription ID.
    uint64 s_subscriptionId;

    // past requests Id.
    uint256[] public requestIds;
    uint256 public lastRequestId;

    // The gas lane to use, which specifies the maximum gas price to bump to.
    // For a list of available gas lanes on each network,
    // see https://docs.chain.link/docs/vrf/v2/subscription/supported-networks/#configurations
    bytes32 keyHash = 0x354d2f95da55398f44b7cff77da56283d9c6c829a4bdf1bbcaf2ad6a4d081f61;

    // Depends on the number of requested values that you want sent to the
    // fulfillRandomWords() function. Storing each word costs about 20,000 gas,
    // so 100,000 is a safe default for this example contract. Test and adjust
    // this limit based on the network that you select, the size of the request,
    // and the processing of the callback request in the fulfillRandomWords()
    // function.
    uint32 callbackGasLimit = 500000;

    // The default is 3, but you can set this higher.
    uint16 requestConfirmations = 3;

    // For this example, retrieve 2 random values in one request.
    // Cannot exceed VRFCoordinatorV2.MAX_NUM_WORDS.
    uint32 numWordsSingle = 1;
    uint32 numWordsBatch = 4;

    // Assumes the subscription is funded sufficiently.
    function mintRandom(uint _numberOfNFTs) external payable payableRandomMint(_numberOfNFTs) returns (uint256 requestId) {
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
        return requestId;
    }

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
        emit RequestFulfilled(_requestId, _randomWords);

    }


    // R O Y A L T I E S
    /** @dev Royalties implementation. */

    address _recipient;

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

    // M O D I F I E R S

    uint internal mintPrice;
    uint internal discountMintPrice;

    uint internal mintBatchPrice;
    uint internal discountMintBatchPrice;

    uint internal mintRandomPrice;
    uint internal discountMintRandomPrice;

    uint internal mintBatchRandomPrice;
    uint discountMintBatchRandomPrice;

    modifier payableMint(uint[] memory _ids) {
        require(block.timestamp <= 1668952800);
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

    modifier payableRandomMint(uint _number) {
        require(block.timestamp <= 1668952800);
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
        _;
    }
}