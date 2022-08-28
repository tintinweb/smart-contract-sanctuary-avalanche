//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
// Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
//These functions can be used to verify that a message was signed by the holder of the private keys of a given address.
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
// is a standard for hashing and signing of typed structured data.
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "../PaymentManager/IPaymentManager.sol";
import "./LibBlindAuction.sol";
import "../libs/LibShareholder.sol";

/**
* @title BlindAuctionMarketplace
* @notice allows the users to create, withdraw, settle nft blind auctions and make bids to nft blind auctions.
* The offers cannot be revealed. Offers are kept off-chain.
* The winner will be the first highest bidder.
* At the end of the auction specified winner can settle the auction using the signature and offer object that is provided by the allowed signer.
* The allowed signer is owner of BlindAuctionMarketplace.
*/
contract BlindAuctionMarketplace is Initializable, EIP712Upgradeable, ERC721HolderUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {

    string private constant SIGNING_DOMAIN = "SalvorBlindAuction";
    string private constant SIGNATURE_VERSION = "1";
    using ECDSAUpgradeable for bytes32;


    // contains information about an auction
    struct BlindAuction {
        uint64 endTime; // the auction ending time
        uint64 startTime; // the auction starting time
        uint128 minPrice; // allowance for minimum bid
        uint128 buyNowPrice; // if a buyer would like to buy immediately without waiting auction progress should pay buyNowPrice
        address seller; // nft owner
        bool isWithdrawable; // flag to allow withdraw the auction
        mapping(uint256 => LibShareholder.Shareholder) shareholders; // When the nft is sold then the price will be split to the shareholders.
        uint256 shareholderSize;  // there is a restriction about removing arrays defined in a struct. This value helps to iterate and remove every shareholder value.
    }

    /**
    * @notice The mapping keeps the minimum price of the blind auction for each bidder.
    * In the case of settlement, the winner can pay the rest of the commitment amount.
    * In the case of losing the auction, the bidder can withdraw their own bid that was specified by the nft owner in the blind auction as the minimum price.
    */
    mapping(address => mapping(uint256 => mapping(address => uint256))) public offerBalance;


    /**
    * @notice contains information about redeemed offers.
    * prevent users from using the same offer on the functions.
    */
    mapping(bytes32 => bool) public fills;


    /**
    * @notice manages payouts for each contract.
    */
    address public paymentManager;


    /**
    * @notice offers cannot be revealed and are kept off-chain.
    * At the end of the auction specified winner can settle the auction using the signature and offer object that is provided by the allowed signer.
    * The allowed signer is owner of BlindAuctionMarketplace.
    */
    address public salvorSigner;

    /**
    * @notice failed transfer amounts for each account are accumulated in this mapping.
    * e.g failedTransferBalance[bidder_address] = failed_balance;
    */
    mapping(address => uint256) public failedTransferBalance;

    /**
    * @notice contains information about auctions
    * e.g auctions[contract_address][token_id] = BlindAuction auction;
    */
    mapping(address => mapping(uint256 => BlindAuction)) public blindAuctions;


    /**
    * @notice a control variable to check the buyNowPrice of the auction is higher than minimumPrice of the auction.
    */
    uint32 public maximumMinPricePercentage;

    /**
    * @notice a control variable to check the end time of the auction is in the correct range.
    */
    uint32 public maximumDurationPeriod;

    /**
    * @notice In the case of the winner not settling the auction, nft seller can terminate the auction in designated time.
    * (default 48 hours) After termination of the auction winners’ bids (the minimum price of the nft auction) will be transferred to nft owner and then nft transferred to the existing owner back.
    */
    uint32 public minimumRequiredPeriodToTerminate;

    /**
    * @notice a control variable to check the minimum price of the auction is in the correct range.
    */
    uint256 public minimumPriceLimit;

    // events  
    event BlindAuctionSettled(address indexed collection, uint256 indexed tokenId, string salt, uint256 bid, bool isBuyNow);
    event BlindAuctionWithdrawn(address indexed collection, uint256 indexed tokenId);
    event BlindAuctionTerminated(
        address indexed collection,
        uint256 indexed tokenId,
        string salt,
        address maker,
        uint256 amount
    );
    event BlindAuctionClaimed(
        address indexed collection,
        uint256 indexed tokenId,
        string salt,
        uint256 amount
    );
    event BidMade(address indexed collection, uint256 indexed tokenId, uint256 bid);
    event BlindAuctionCreated(
        address indexed collection,
        uint256 indexed tokenId,
        uint256 minPrice,
        uint256 buyNowPrice,
        uint64 endTime,
        uint64 startTime,
        LibShareholder.Shareholder[] shareholders
    );
    event FailedTransfer(address indexed receiver, uint256 amount);
    event WithdrawnFailedBalance(uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _paymentManager, address _salvorSigner) public initializer {
        __EIP712_init_unchained(SIGNING_DOMAIN, SIGNATURE_VERSION);
        __ERC721Holder_init_unchained();
        __Ownable_init_unchained();
        __Pausable_init_unchained();
        __ReentrancyGuard_init_unchained();
        paymentManager = _paymentManager;
        salvorSigner = _salvorSigner;
        maximumMinPricePercentage = 500; // 5%
        maximumDurationPeriod = 864000; // 10 days
        minimumRequiredPeriodToTerminate = 172800; // 48 hours
        minimumPriceLimit = 10000000000000000; // 0.01 ether
        salvorSigner = owner();
    }

    /**
    * @notice allows owner to set paymentManager contract address.
    * @param _paymentManager PaymentManager contract address.
    */
    function setPaymentManager(address _paymentManager) external onlyOwner {
        paymentManager = _paymentManager;
    }

    /**
    * @notice allows the owner to set salvorSigner.
    * Offer and signatures are generated from salvorSigner to allow users to settle, terminate or claim.
    * @param _salvorSigner address that managed by Salvor
    */
    function setSalvorSigner(address _salvorSigner) external onlyOwner {
        salvorSigner = _salvorSigner;
    }

    /**
    * @notice allows the owner to set a minimumPriceLimit that is used as a control variable
    * to check the minimum price of the auction is in the correct range.
    * @param _minimumPriceLimit amount of ether
    */
    function setMinimumPriceLimit(uint32 _minimumPriceLimit) external onlyOwner {
        minimumPriceLimit = _minimumPriceLimit;
    }

    /**
    * @notice allows the owner to set a _minimumRequiredPeriodToTerminate
    * that is used on termination auction to allow the seller to claim the minimum price of the winning offer if the winner doesn't settle the auction.
    * @param _minimumRequiredPeriodToTerminate timestamp value
    */
    function setMinimumRequiredPeriodToTerminate(uint32 _minimumRequiredPeriodToTerminate) external onlyOwner {
        minimumRequiredPeriodToTerminate = _minimumRequiredPeriodToTerminate;
    }

    /**
    * @notice Allows the owner to set a maximumMinPricePercentage
    * that is used as a control variable to check the buyNowPrice of the auction is higher than minimumPrice of the auction.
    * @param _maximumMinPricePercentage price in ethers
    */
    function setMaximumMinPricePercentage(uint32 _maximumMinPricePercentage) external onlyOwner {
        maximumMinPricePercentage = _maximumMinPricePercentage;
    }

    /**
    * @notice allows the owner to set a maximumDurationPeriod that is used as a control variable
    * to check the end time of the auction is in the correct range.
    * @param _maximumDurationPeriod timestamp value e.g 864000 (10 days)
    */
    function setMaximumDurationPeriod(uint32 _maximumDurationPeriod) external onlyOwner {
        maximumDurationPeriod = _maximumDurationPeriod;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function getChainId() external view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    function balance() external view returns (uint) {
        return address(this).balance;
    }

    /**
    * @notice failed transfers are stored in `failedTransferBalance`. In the case of failure, users can withdraw failed balances.
    */
    function withdrawFailedCredits() external whenNotPaused nonReentrant {
        uint256 amount = failedTransferBalance[msg.sender];

        require(amount > 0, "no credits to withdraw");

        failedTransferBalance[msg.sender] = 0;
        (bool successfulWithdraw, ) = msg.sender.call{ value: amount, gas: 20000}("");
        require(successfulWithdraw, "withdraw failed");
        emit WithdrawnFailedBalance(amount);
    }

    /**
    * @notice Allows the nft owner to create an auction. Nft owner can set shareholders to share the sales amount.
    * Nft owner transfers the nft to BlindAuctionMarketplace contract.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    * @param _minPrice minimum price of the auction
    * @param _buyNowPrice buy now price of the auction
    * @param _auctionEnd ending time of the auction
    * @param _auctionStart starting time of the auction
    * @param _shareholders revenue share list
    */
    function createBlindAuction(address _nftContractAddress, uint256 _tokenId, uint128 _minPrice, uint128 _buyNowPrice, uint64 _auctionEnd, uint64 _auctionStart, LibShareholder.Shareholder[] memory _shareholders)
        external
        whenNotPaused
        isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
        minPriceDoesNotExceedLimit(_buyNowPrice, _minPrice)
        priceGreaterThanMinimumPriceLimit(_minPrice)
    {
        _configureAuction(_nftContractAddress, _tokenId, _minPrice, _buyNowPrice, _auctionEnd, _auctionStart, _shareholders);
    }

    /**
    * @notice If there are no bids only nft owner can withdraw an auction.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function withdrawAuction(address _nftContractAddress, uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
        onlyNftSeller(_nftContractAddress, _tokenId)
        isWithdrawable(_nftContractAddress, _tokenId)
    {
        _resetAuction(_nftContractAddress, _tokenId);
        IERC721Upgradeable(_nftContractAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
        require(IERC721Upgradeable(_nftContractAddress).ownerOf(_tokenId) == msg.sender, "nft should be transferred to owner");
        emit BlindAuctionWithdrawn(_nftContractAddress, _tokenId);
    }

    /**
    * @notice If the bid amount meets requirements and the auction is ongoing then a user can make a bid.
    * In the case the buyer has a remaining not claimed bid on the previous auctions,
    * this amount will be refunded when she/he makes a new offer.
    * Only the minimum amount(minPrice) determined in the auction is charged for each bid.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function makeBid(address _nftContractAddress, uint256 _tokenId)
        external
        payable
        whenNotPaused
        nonReentrant
        auctionOngoing(_nftContractAddress, _tokenId)
        bidAmountMeetsBidRequirements(_nftContractAddress, _tokenId)
    {
        require(msg.sender != blindAuctions[_nftContractAddress][_tokenId].seller, "Owner cannot bid on own NFT");
        uint256 refundableAmount = offerBalance[_nftContractAddress][_tokenId][msg.sender];

        if (_isBuyNowPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftAndPaySeller(_nftContractAddress, _tokenId, msg.value);
            offerBalance[_nftContractAddress][_tokenId][msg.sender] = 0;
            emit BlindAuctionSettled(_nftContractAddress, _tokenId, "", msg.value, true);
        } else {
            blindAuctions[_nftContractAddress][_tokenId].isWithdrawable = false;
            offerBalance[_nftContractAddress][_tokenId][msg.sender] = blindAuctions[_nftContractAddress][_tokenId].minPrice;
            if (msg.value > blindAuctions[_nftContractAddress][_tokenId].minPrice) {
                refundableAmount += (msg.value - blindAuctions[_nftContractAddress][_tokenId].minPrice);
            }
            emit BidMade(_nftContractAddress, _tokenId, blindAuctions[_nftContractAddress][_tokenId].minPrice);
        }
        if (refundableAmount > 0) {
            transferBidSafely(msg.sender, refundableAmount);
        }
    }

    /**
    * @notice A signature is created by salvorSigner when the auction has a winner.
    * Signature and offer is shared by salvor to the winning user.
    * In this way only the winner can settle the auction and the winner must pay the rest of the bid.
    * @param offer is generated by salvorSigner as an offer coupon that contains offer details
    * @param signature is generated by salvorSigner to validate offer
    */
    function settleAuction(LibBlindAuction.Offer calldata offer, bytes memory signature)
        external
        payable
        whenNotPaused
        nonReentrant
        isAuctionNotReset(offer.nftContractAddress, offer.tokenId)
        isAuctionOver(offer.nftContractAddress, offer.tokenId)
        isSalvorSigner(offer, signature)
        isNotRedeemed(LibBlindAuction.hashKey(offer))
    {
        require(offer.isWinner, "Only winner coupon can be redeemed");
        require(offer.maker == msg.sender, "Signature doesn't belongs to msg.sender");
        bytes32 orderKeyHash = LibBlindAuction.hashKey(offer);
        fills[orderKeyHash] = true;
        uint256 existingAmount = offerBalance[offer.nftContractAddress][offer.tokenId][msg.sender];
        offerBalance[offer.nftContractAddress][offer.tokenId][msg.sender] = 0;
        require(existingAmount == blindAuctions[offer.nftContractAddress][offer.tokenId].minPrice, "must bid minimum price");
        require(msg.value >= (offer.amount - existingAmount), "insufficient payment");

        _transferNftAndPaySeller(offer.nftContractAddress, offer.tokenId, msg.value);
        emit BlindAuctionSettled(offer.nftContractAddress, offer.tokenId, offer.salt, msg.value, false);
    }

    /**
    * @notice when the auction has ended. Signature and offer is shared by salvorSigner to the bidders that lose the auction.
    * @param offer is generated by salvorSigner as an offer coupon that contains offer details
    * @param signature is generated by salvorSigner to validate offer
    */
    function claimAuction(LibBlindAuction.Offer calldata offer, bytes memory signature)
        external
        whenNotPaused
        nonReentrant
        isAuctionOver(offer.nftContractAddress, offer.tokenId)
        isSalvorSigner(offer, signature)
        isNotRedeemed(LibBlindAuction.hashKey(offer))
    {
        require(offer.isWinner == false, "Only nonwinner coupon can be redeemed");
        require(offer.maker == msg.sender, "Signature doesn't belongs to msg.sender");
        bytes32 orderKeyHash = LibBlindAuction.hashKey(offer);
        fills[orderKeyHash] = true;
        uint256 refundableAmount = offerBalance[offer.nftContractAddress][offer.tokenId][msg.sender];
        offerBalance[offer.nftContractAddress][offer.tokenId][msg.sender] = 0;
        require(refundableAmount > 0, "there is no refundable amount");
        if (refundableAmount > 0) {
            transferBidSafely(msg.sender, refundableAmount);
        }
        emit BlindAuctionClaimed(offer.nftContractAddress, offer.tokenId, offer.salt, refundableAmount);
    }

    /**
    * @notice allows the seller to claim the minimum price of the winning offer.
    * In the case of the winner not settling the auction, nft seller can terminate the auction in designated time. (default 48 hours)
    * After termination of the auction winners’ bids (the minimum price of the nft auction) will be transferred to nft owner and then nft transferred to the existing owner back.
    * @param offer is generated by salvorSigner as an offer coupon that contains offer details
    * @param signature is generated by salvorSigner to validate offer
    */
    function terminateAuction(LibBlindAuction.Offer calldata offer, bytes memory signature)
        external
        whenNotPaused
        nonReentrant
        onlyNftSeller(offer.nftContractAddress, offer.tokenId)
        isRequiredPeriodIsPassedOverTheExpirationDate(offer.nftContractAddress, offer.tokenId)
        isSalvorSigner(offer, signature)
        isNotRedeemed(LibBlindAuction.hashKey(offer))
    {
        require(offer.isWinner, "invalid signature");
        bytes32 orderKeyHash = LibBlindAuction.hashKey(offer);
        fills[orderKeyHash] = true;
        _resetAuction(offer.nftContractAddress, offer.tokenId);
        IERC721Upgradeable(offer.nftContractAddress).safeTransferFrom(address(this), msg.sender, offer.tokenId);
        require(IERC721Upgradeable(offer.nftContractAddress).ownerOf(offer.tokenId) == msg.sender, "nft should be transferred to owner");

        uint256 amount = offerBalance[offer.nftContractAddress][offer.tokenId][offer.maker];
        offerBalance[offer.nftContractAddress][offer.tokenId][offer.maker] = 0;
        _payout(payable(msg.sender), offer.nftContractAddress, offer.tokenId, amount);
        _emitBlindAuctionTerminated(offer, amount);
    }

    function _emitBlindAuctionTerminated(LibBlindAuction.Offer calldata offer, uint256 minPrice) internal {
        emit BlindAuctionTerminated(
            offer.nftContractAddress,
            offer.tokenId,
            offer.salt,
            offer.maker,
            minPrice
        );
    }

    function _configureAuction(address _nftContractAddress, uint256 _tokenId, uint128 _minPrice, uint128 _buyNowPrice, uint64 _auctionEnd, uint64 _auctionStart, LibShareholder.Shareholder[] memory _shareholders) internal {
        uint64 auctionStart = _auctionStart > uint64(block.timestamp) ? _auctionStart : uint64(block.timestamp);
        require((_auctionEnd > auctionStart) && (_auctionEnd <= (auctionStart + maximumDurationPeriod)), "Ending time of the auction isn't within the allowable range");
        _setShareholders(_nftContractAddress, _tokenId, _shareholders);
        blindAuctions[_nftContractAddress][_tokenId].endTime = _auctionEnd;
        blindAuctions[_nftContractAddress][_tokenId].startTime = auctionStart;
        blindAuctions[_nftContractAddress][_tokenId].buyNowPrice = _buyNowPrice;
        blindAuctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        blindAuctions[_nftContractAddress][_tokenId].seller = msg.sender;
        blindAuctions[_nftContractAddress][_tokenId].isWithdrawable = true;
        _transferNftToAuctionContract(_nftContractAddress, _tokenId);
        LibShareholder.Shareholder[] memory shareholders = _getShareholders(_nftContractAddress, _tokenId);
        emit BlindAuctionCreated(
            _nftContractAddress,
            _tokenId,
            _minPrice,
            _buyNowPrice,
            _auctionEnd,
            auctionStart,
            shareholders
        );
    }

    function _setShareholders(address _nftContractAddress, uint256 _tokenId, LibShareholder.Shareholder[] memory _shareholders) internal {
        // makes sure shareholders does not exceed the limits defined in PaymentManager contract
        require(_shareholders.length <= IPaymentManager(paymentManager).getMaximumShareholdersLimit(), "reached maximum shareholder count");
        uint256 j = 0;
        for (uint256 i = 0; i < _shareholders.length; i++) {
            if (_shareholders[i].account != address(0x0) && _shareholders[i].value > 0) {
                blindAuctions[_nftContractAddress][_tokenId].shareholders[j].account = _shareholders[i].account;
                blindAuctions[_nftContractAddress][_tokenId].shareholders[j].value = _shareholders[i].value;
                j += 1;
            }
        }
        blindAuctions[_nftContractAddress][_tokenId].shareholderSize = j;
    }

    function _getShareholders(address _nftContractAddress, uint256 _tokenId) internal view returns (LibShareholder.Shareholder[] memory) {
        uint256 shareholderSize = blindAuctions[_nftContractAddress][_tokenId].shareholderSize;
        LibShareholder.Shareholder[] memory shareholders = new LibShareholder.Shareholder[](shareholderSize);
        for (uint256 i = 0; i < shareholderSize; i++) {
            shareholders[i].account = blindAuctions[_nftContractAddress][_tokenId].shareholders[i].account;
            shareholders[i].value = blindAuctions[_nftContractAddress][_tokenId].shareholders[i].value;
        }
        return shareholders;
    }

    /**
    * @notice validates offer and signature are matched
    * @param offer is generated by salvorSigner as an offer coupon that contains order details
    * @param signature is generated by salvorSigner to validate order
    */
    function _validate(LibBlindAuction.Offer memory offer, bytes memory signature) internal view returns (address) {
        bytes32 hash = LibBlindAuction.hash(offer);
        return _hashTypedDataV4(hash).recover(signature);
    }


    /**
    * @notice Process the payment for the allowed requests.
    * Process is completed in 3 steps;commission transfer, royalty transfers and revenue share transfers.
    * @param _seller receiver address
    * @param _nftContractAddress nft contract address is used for process royalty amounts
    * @param _tokenId nft tokenId  is used for process royalty amounts
    * @param _price sent amount
    */
    function _payout(address payable _seller, address _nftContractAddress, uint256 _tokenId, uint256 _price) internal {
        LibShareholder.Shareholder[] memory shareholders = _getShareholders(_nftContractAddress, _tokenId);

        IPaymentManager(paymentManager).payout{ value: _price }(_seller, _nftContractAddress, _tokenId, _price, shareholders);
    }


    /**
    * @notice in the case of isBuyNowPrice is set then checks the sent amount is met with buyNowPrice
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _isBuyNowPriceMet(address _nftContractAddress, uint256 _tokenId) internal view returns (bool) {
        uint128 buyNowPrice = blindAuctions[_nftContractAddress][_tokenId].buyNowPrice;
        return buyNowPrice > 0 && msg.value >= buyNowPrice;
    }

    function transferBidSafely(address _recipient, uint256 _amount) internal {
        (bool success, ) = payable(_recipient).call{value: _amount, gas: 20000}("");
        // if it fails, it updates their credit balance so they can withdraw later
        if (!success) {
            failedTransferBalance[_recipient] += _amount;
            emit FailedTransfer(_recipient, _amount);
        }
    }

    /**
    * @notice transfers nft to current contract (BlindAuctionMarketplace)
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _transferNftToAuctionContract(address _nftContractAddress, uint256 _tokenId) internal {
        address _nftSeller = blindAuctions[_nftContractAddress][_tokenId].seller;
        IERC721Upgradeable(_nftContractAddress).safeTransferFrom(_nftSeller, address(this), _tokenId);
        require(IERC721Upgradeable(_nftContractAddress).ownerOf(_tokenId) == address(this), "nft transfer failed");
    }

    /**
    * @notice transfers nft to the highest bidder and pay the highest bid to the nft seller
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _transferNftAndPaySeller(address _nftContractAddress, uint256 _tokenId, uint256 _bid) internal {
        address _nftSeller = blindAuctions[_nftContractAddress][_tokenId].seller;

        _payout(payable(_nftSeller), _nftContractAddress, _tokenId, _bid);

        IERC721Upgradeable(_nftContractAddress).safeTransferFrom(address(this), msg.sender, _tokenId);
        require(IERC721Upgradeable(_nftContractAddress).ownerOf(_tokenId) == msg.sender, "nft should be transferred to buyer");

        _resetAuction(_nftContractAddress, _tokenId);
    }

    /**
    * @notice resets auction parameters
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _resetAuction(address _nftContractAddress, uint256 _tokenId) internal {
        blindAuctions[_nftContractAddress][_tokenId].minPrice = 0;
        blindAuctions[_nftContractAddress][_tokenId].buyNowPrice = 0;
        blindAuctions[_nftContractAddress][_tokenId].startTime = 0;
        blindAuctions[_nftContractAddress][_tokenId].endTime = 0;
        blindAuctions[_nftContractAddress][_tokenId].seller = address(0);
        blindAuctions[_nftContractAddress][_tokenId].isWithdrawable = false;
        for (uint8 i = 0; i < blindAuctions[_nftContractAddress][_tokenId].shareholderSize; i++) {
            delete blindAuctions[_nftContractAddress][_tokenId].shareholders[i];
        }
        blindAuctions[_nftContractAddress][_tokenId].shareholderSize = 0;
    }

    /**
    * @notice makes sure if buyNowPrice set then it checks buyNowPrice greater than or equal to %maximumMinPricePercentage percent greater than minimumPrice.
    * @param _buyNowPrice a limit that allows bidders to buy directly
    * @param _minPrice a restriction for the bidders must pay minimum x amount.
    */
    modifier minPriceDoesNotExceedLimit(uint128 _buyNowPrice, uint128 _minPrice) {
        require(_buyNowPrice == 0 || (_buyNowPrice * (10000 + maximumMinPricePercentage) / 10000) >=_minPrice, "buyNowPrice must be greater than or equal to %maximumMinPricePercentage percent greater than minimumPrice");
        _;
    }

    /**
    * @notice makes sure auction has not started yet and the given nft is belongs to the msg.sender
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier isAuctionNotStartedByOwner(address _nftContractAddress, uint256 _tokenId) {
        require(msg.sender != blindAuctions[_nftContractAddress][_tokenId].seller, "Auction has been already started");
        require(msg.sender == IERC721Upgradeable(_nftContractAddress).ownerOf(_tokenId), "Sender doesn't own NFT");
        _;
    }

    /**
    * @notice checks the given value is greater than `minimumPriceLimit`
    */
    modifier priceGreaterThanMinimumPriceLimit(uint256 _price) {
        require(_price >= minimumPriceLimit, "Price must be higher than minimum limit");
        _;
    }

    /**
    * @notice makes sure sent ethers is greater than or equal to auction.minPrice
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier bidAmountMeetsBidRequirements(address _nftContractAddress, uint256 _tokenId) {
        require(msg.value >= blindAuctions[_nftContractAddress][_tokenId].minPrice, "Not enough funds to bid on NFT");
        _;
    }

    /**
    * @notice makes sure auction is ongoing in the range of between startTime and endTime
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier auctionOngoing(address _nftContractAddress, uint256 _tokenId) {
        uint64 endTime = blindAuctions[_nftContractAddress][_tokenId].endTime;
        uint64 startTime = blindAuctions[_nftContractAddress][_tokenId].startTime;

        require((block.timestamp >= startTime) && (block.timestamp < endTime), "Auction is not going on");
        _;
    }

    /**
    * @notice makes sure auction is over
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier isAuctionOver(address _nftContractAddress, uint256 _tokenId) {
        require(block.timestamp >= blindAuctions[_nftContractAddress][_tokenId].endTime, "Auction is not over yet");
        _;
    }

    /**
    * @notice makes sure offer is signed by salvorSigner
    * @param offer is generated by salvorSigner as an offer coupon that contains order details
    * @param signature is generated by salvorSigner to validate order
    */
    modifier isSalvorSigner(LibBlindAuction.Offer calldata offer, bytes memory signature) {
        require(salvorSigner == _validate(offer, signature), "invalid signature");
        _;
    }

    /**
    * @notice makes sure the auction is not reset
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier isAuctionNotReset(address _nftContractAddress, uint256 _tokenId) {
        require(blindAuctions[_nftContractAddress][_tokenId].seller != address(0x0), "Auction has already completed");
        _;
    }

    /**
    * @notice makes sure required period is passed over the expiration date
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier isRequiredPeriodIsPassedOverTheExpirationDate(address _nftContractAddress, uint256 _tokenId) {
        uint64 endTime = blindAuctions[_nftContractAddress][_tokenId].endTime;
        require(block.timestamp >= (endTime + minimumRequiredPeriodToTerminate), "Auction is not over yet");
        _;
    }

    /**
    * @notice makes sure the auction is withdrawable
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier isWithdrawable(address _nftContractAddress, uint256 _tokenId) {
        require(blindAuctions[_nftContractAddress][_tokenId].isWithdrawable, "The auction has a valid bid made");
        _;
    }

    /**
    * @notice makes sure msg.sender is nft owner  of the given contract address and tokenId.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier onlyNftSeller(address _nftContractAddress, uint256 _tokenId) {
        address seller = blindAuctions[_nftContractAddress][_tokenId].seller;
        require(msg.sender == seller, "Only nft seller");
        _;
    }

    /**
    * @notice makes sure offer has not redeemed before
    * @param _offerKeyHash hash of an offer
    */
    modifier isNotRedeemed(bytes32 _offerKeyHash) {
        require(fills[_offerKeyHash] != true, "offer has already redeemed");
        _;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// contains information about revenue share on each sale
library LibShareholder {
    struct Shareholder {
        address account; // receiver wallet address
        uint96 value; // percentage of share
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../libs/LibShareholder.sol";

interface IPaymentManager {
    function payout(address payable _seller, address _nftContractAddress, uint256 _tokenId, uint256 _price, LibShareholder.Shareholder[] memory _shareholders) external payable;
    function getMaximumShareholdersLimit() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library LibBlindAuction {

    bytes constant offerTypeString = abi.encodePacked(
        "Offer(",
        "address nftContractAddress,",
        "uint256 tokenId,",
        "address maker,"
        "string salt,",
        "uint256 amount,",
        "bool isWinner"
        ")"
    );

    bytes32 constant OFFER_TYPEHASH = keccak256(offerTypeString);

    struct Offer {
        address nftContractAddress; // nft contract address
        uint tokenId; // nft tokenId
        address maker; // bidder address
        string salt; // uuid to provide uniquness
        uint amount; // bid
        bool isWinner; // boolean flag
    }

    function hash(Offer memory offer) internal pure returns (bytes32) {
        return keccak256(abi.encode(
                OFFER_TYPEHASH,
                offer.nftContractAddress,
                offer.tokenId,
                offer.maker,
                keccak256(bytes(offer.salt)),
                offer.amount,
                offer.isWinner
            ));
    }

    function hashKey(Offer memory offer) internal pure returns (bytes32) {
        return keccak256(abi.encode(offer.nftContractAddress, offer.tokenId, offer.maker, keccak256(bytes(offer.salt))));
    }
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721ReceiverUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC721ReceiverUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}