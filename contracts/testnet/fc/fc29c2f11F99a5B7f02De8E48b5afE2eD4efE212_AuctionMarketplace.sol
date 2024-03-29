//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "../PaymentManager/IPaymentManager.sol";
import "../libs/LibShareholder.sol";

/**
* @title AuctionMarketplace
* @notice allows the users to create, withdraw, settle and make bids to nft auctions.
*/
contract AuctionMarketplace is Initializable, ERC721HolderUpgradeable, OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable {
    // contains information about an auction
    struct Auction {
        // When the nft is sold then the price will be split to the shareholders.
        mapping(uint8 => LibShareholder.Shareholder) shareholders;
        /**
        * There is a restriction about removing arrays defined in a struct.
        * This value helps to iterate and remove every shareholder value.
        */
        uint8 shareholderSize;
        // controls the bid increment for every offer
        uint32 defaultBidIncreasePercentage;
        // incremental duration value to extend auction
        uint32 defaultAuctionBidPeriod;
        // the auction ending time
        uint64 endTime;
        // the auction starting time
        uint64 startTime;
        // commission percentage
        uint96 commissionPercentage;
        // allowance for minimum bid
        uint128 minPrice;
        // if a buyer would like to buy immediately without waiting auction progress should pay buyNowPrice
        uint128 buyNowPrice;
        // keep the highest bid for every successful make bid action
        uint128 highestBid;
        // keep the highest bidder for every successful make bid action
        address highestBidder;
        // nft owner
        address seller;
    }

    /**
    * @notice manages payouts for each contract.
    */
    address public paymentManager;

    /**
    * @notice contains information about auctions
    * e.g auctions[contract_address][token_id] = Auction auction;
    */
    mapping(address => mapping(uint256 => Auction)) public auctions;

    /**
    * @notice a control variable to check the buyNowPrice of the auction is higher than minimumPrice of the auction
    * and also check the bids to the auction is greater than previous bids.
    */
    uint32 public defaultBidIncreasePercentage;

    /**
    * @notice if a bid is placed `defaultAuctionBidPeriod` minutes before the end of the auction,
    * auction duration will be extended by defaultAuctionBidPeriod minutes.
    */
    uint32 public defaultAuctionBidPeriod;

    /**
    * @notice a control variable to check the end time of the auction is in the correct range.
    */
    uint32 public maximumDurationPeriod;

    /**
    * @notice a control variable to check the minimum price of the auction is in the correct range.
    */
    uint256 public minimumPriceLimit;

    // events
    event AuctionSettled(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed highestBidder,
        uint256 highestBid,
        bool isBuyNow
    );
    event AuctionWithdrawn(address indexed collection, uint256 indexed tokenId);
    event BidMade(address indexed collection, uint256 indexed tokenId, uint256 bid);
    event PaymentManagerSet(address indexed paymentManager);
    event DefaultBidIncreasePercentageSet(uint32 defaultBidIncreasePercentage);
    event MinimumPriceLimitSet(uint256 minimumPriceLimit);
    event MaximumDurationPeriodSet(uint32 maximumDurationPeriod);
    event DefaultAuctionBidPeriodSet(uint32 defaultAuctionBidPeriod);
    event NftAuctionCreated(
        address indexed collection,
        uint256 indexed tokenId,
        uint256 minPrice,
        uint256 buyNowPrice,
        uint64 endTime,
        uint64 startTime,
        uint96 bidIncreasePercentage,
        LibShareholder.Shareholder[] shareholders
    );
    event FailedTransfer(address indexed receiver, uint256 amount);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address _paymentManager) public initializer addressIsNotZero(_paymentManager) {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __Pausable_init_unchained();
        __ERC721Holder_init_unchained();
        paymentManager = _paymentManager;
        defaultBidIncreasePercentage = 500; // 5%
        defaultAuctionBidPeriod = 300; // 5 minutes
        maximumDurationPeriod = 864000; // 10 days
        minimumPriceLimit = 10000000000000000; // 0.01 ether
    }

    receive() external payable {}

    /**
    * @notice allows owner to set paymentManager contract address.
    * @param _paymentManager PaymentManager contract address.
    */
    function setPaymentManager(address _paymentManager) external onlyOwner addressIsNotZero(_paymentManager) {
        paymentManager = _paymentManager;
        emit PaymentManagerSet(_paymentManager);
    }

    /**
    * @notice allows the owner to set a `defaultBidIncreasePercentage` that is used as a control variable
    * to check the buyNowPrice of the auction is higher than minimumPrice of the auction
    * and also check the bids to the auction is greater than previous bids.
    * @param _defaultBidIncreasePercentage percentage value
    */
    function setDefaultBidIncreasePercentage(uint32 _defaultBidIncreasePercentage) external onlyOwner {
        defaultBidIncreasePercentage = _defaultBidIncreasePercentage;
        emit DefaultBidIncreasePercentageSet(_defaultBidIncreasePercentage);
    }

    /**
    * @notice allows the owner to set a minimumPriceLimit that is used as a control variable
    * to check the minimum price of the auction is in the correct range.
    * @param _minimumPriceLimit amount of ether
    */
    function setMinimumPriceLimit(uint256 _minimumPriceLimit) external onlyOwner {
        minimumPriceLimit = _minimumPriceLimit;
        emit MinimumPriceLimitSet(_minimumPriceLimit);
    }

    /**
    * @notice allows the owner to set a maximumDurationPeriod that is used as a control variable
    * to check the end time of the auction is in the correct range.
    * @param _maximumDurationPeriod timestamp value e.g 864000 (10 days)
    */
    function setMaximumDurationPeriod(uint32 _maximumDurationPeriod) external onlyOwner {
        maximumDurationPeriod = _maximumDurationPeriod;
        emit MaximumDurationPeriodSet(_maximumDurationPeriod);
    }

    /**
    * @notice allows the owner to set a `defaultAuctionBidPeriod` that is used as a control variable
    * to check whether the auction in the last x minutes.
    * @param _defaultAuctionBidPeriod timestamp value e.g 300 (5 minutes)
    */
    function setDefaultAuctionBidPeriod(uint32 _defaultAuctionBidPeriod) external onlyOwner {
        defaultAuctionBidPeriod = _defaultAuctionBidPeriod;
        emit DefaultAuctionBidPeriodSet(defaultAuctionBidPeriod);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    /**
    * @notice allows the nft owner to create an auction. Nft owner can set shareholders to share the sales amount.
    * Nft owner transfers the nft to AuctionMarketplace contract.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    * @param _minPrice minimum price of the auction
    * @param _buyNowPrice buy now price of the auction
    * @param _auctionEnd ending time of the auction
    * @param _auctionStart starting time of the auction
    * @param _shareholders revenue share list
    */
    function createNftAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _minPrice,
        uint128 _buyNowPrice,
        uint64 _auctionEnd,
        uint64 _auctionStart,
        LibShareholder.Shareholder[] memory _shareholders
    )
        external
        whenNotPaused
        isAuctionNotStartedByOwner(_nftContractAddress, _tokenId)
        minPriceDoesNotExceedLimit(_buyNowPrice, _minPrice)
        priceGreaterThanMinimumPriceLimit(_minPrice)
    {
        // configures auction
        _configureAuction(
            _nftContractAddress,
            _tokenId,
            _minPrice,
            _buyNowPrice,
            _auctionEnd,
            _auctionStart,
            _shareholders
        );

        // transfers nft to the AuctionMarketplace contract
        _transferNftToAuctionContract(_nftContractAddress, _tokenId);

        LibShareholder.Shareholder[] memory shareholders = _getShareholders(_nftContractAddress, _tokenId);

        emit NftAuctionCreated(
            _nftContractAddress,
            _tokenId,
            _minPrice,
            _buyNowPrice,
            _auctionEnd,
            _auctionStart,
            defaultBidIncreasePercentage,
            shareholders
        );
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
        bidNotMade(_nftContractAddress, _tokenId)
    {
        // resets the auction
        _resetAuction(_nftContractAddress, _tokenId);

        // transfer nft to the seller back
        IERC721Upgradeable(_nftContractAddress).safeTransferFrom(address(this), msg.sender, _tokenId);

        emit AuctionWithdrawn(_nftContractAddress, _tokenId);
    }

    /**
    * @notice If the bid amount meets requirements and the auction is ongoing then a user can make a bid.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function makeBid(address _nftContractAddress, uint256 _tokenId)
        external
        payable
        whenNotPaused
        nonReentrant
        paymentAccepted
        bidAmountMeetsBidRequirements(_nftContractAddress, _tokenId)
        auctionOngoing(_nftContractAddress, _tokenId)
    {
        require(msg.sender != auctions[_nftContractAddress][_tokenId].seller, "Owner cannot bid on own NFT");
        // previous highest bid refunded and set the new bid as highest
        _reversePreviousBidAndUpdateHighestBid(_nftContractAddress, _tokenId);
        /**
        * if the buyNowPrice is met then the auction is end
        * in other case if the endTime is in the last x minutes than the end time will be extended x minutes
        */
        if (_isBuyNowPriceMet(_nftContractAddress, _tokenId)) {
            _transferNftAndPaySeller(_nftContractAddress, _tokenId, true);
        } else {
            if (_isAuctionCloseToEnd(_nftContractAddress, _tokenId)) {
                _updateAuctionEnd(_nftContractAddress, _tokenId);
            }
            emit BidMade(_nftContractAddress, _tokenId, msg.value);
        }
    }

    /**
    * @notice auction can be settled by either buyer and seller if an auction ends and there is a highest bid.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function settleAuction(address _nftContractAddress, uint256 _tokenId)
        external
        whenNotPaused
        nonReentrant
        isAuctionOver(_nftContractAddress, _tokenId)
        bidMade(_nftContractAddress, _tokenId)
    {
        // ends the auction and makes the transfers
        _transferNftAndPaySeller(_nftContractAddress, _tokenId, false);
    }

    function balance() external view returns (uint) {
        return address(this).balance;
    }

    function _configureAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _minPrice,
        uint128 _buyNowPrice,
        uint64 _auctionEnd,
        uint64 _auctionStart,
        LibShareholder.Shareholder[] memory _shareholders
    ) internal {
        uint64 auctionStart = _auctionStart > uint64(block.timestamp) ? _auctionStart : uint64(block.timestamp);
        require(
            (_auctionEnd > auctionStart) && (_auctionEnd <= (auctionStart + maximumDurationPeriod)),
            "Ending time of the auction isn't within the allowable range"
        );
        _setShareholders(_nftContractAddress, _tokenId, _shareholders);
        auctions[_nftContractAddress][_tokenId].endTime = _auctionEnd;
        auctions[_nftContractAddress][_tokenId].startTime = auctionStart;
        auctions[_nftContractAddress][_tokenId].buyNowPrice = _buyNowPrice;
        auctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        auctions[_nftContractAddress][_tokenId].seller = msg.sender;
        auctions[_nftContractAddress][_tokenId].defaultBidIncreasePercentage = defaultBidIncreasePercentage;
        auctions[_nftContractAddress][_tokenId].defaultAuctionBidPeriod = defaultAuctionBidPeriod;
        uint96 commissionPercentage = IPaymentManager(paymentManager).getCommissionPercentage();
        auctions[_nftContractAddress][_tokenId].commissionPercentage = commissionPercentage;
    }

    /**
    * @notice previous highest bid refunded and set the new bid as highest.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _reversePreviousBidAndUpdateHighestBid(address _nftContractAddress, uint256 _tokenId) internal {
        address prevNftHighestBidder = auctions[_nftContractAddress][_tokenId].highestBidder;
        uint256 prevNftHighestBid = auctions[_nftContractAddress][_tokenId].highestBid;

        auctions[_nftContractAddress][_tokenId].highestBid = uint128(msg.value);
        auctions[_nftContractAddress][_tokenId].highestBidder = msg.sender;

        if (prevNftHighestBidder != address(0)) {
            _transferBidSafely(prevNftHighestBidder, prevNftHighestBid);
        }
    }

    function _setShareholders(
        address _nftContractAddress,
        uint256 _tokenId, LibShareholder.Shareholder[] memory _shareholders
    ) internal {
        // makes sure shareholders does not exceed the limits defined in PaymentManager contract
        require(
            _shareholders.length <= IPaymentManager(paymentManager).getMaximumShareholdersLimit(),
            "reached maximum shareholder count"
        );
        uint8 j = 0;
        for (uint8 i = 0; i < _shareholders.length; i++) {
            if (_shareholders[i].account != address(0) && _shareholders[i].value > 0) {
                auctions[_nftContractAddress][_tokenId].shareholders[j].account = _shareholders[i].account;
                auctions[_nftContractAddress][_tokenId].shareholders[j].value = _shareholders[i].value;
                j += 1;
            }
        }
        auctions[_nftContractAddress][_tokenId].shareholderSize = j;
    }

    function _getShareholders(address _nftContractAddress, uint256 _tokenId)
        internal
        view
        returns (LibShareholder.Shareholder[] memory)
    {
        uint256 shareholderSize = auctions[_nftContractAddress][_tokenId].shareholderSize;
        LibShareholder.Shareholder[] memory shareholders = new LibShareholder.Shareholder[](shareholderSize);
        for (uint8 i = 0; i < shareholderSize; i++) {
            shareholders[i].account = auctions[_nftContractAddress][_tokenId].shareholders[i].account;
            shareholders[i].value = auctions[_nftContractAddress][_tokenId].shareholders[i].value;
        }
        return shareholders;
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

        IPaymentManager(paymentManager).payout{ value: _price }(
            _seller,
            _nftContractAddress,
            _tokenId, shareholders,
            auctions[_nftContractAddress][_tokenId].commissionPercentage
        );
    }

    /**
    * @notice extends auction end time as specified in `defaultAuctionBidPeriod`
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _updateAuctionEnd(address _nftContractAddress, uint256 _tokenId) internal {
        auctions[_nftContractAddress][_tokenId].endTime += auctions[_nftContractAddress][_tokenId].defaultAuctionBidPeriod;
    }

    /**
    * @notice checks auction end time is in the last x minutes
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _isAuctionCloseToEnd(address _nftContractAddress, uint256 _tokenId) internal view returns (bool) {
        uint64 extendedEndTime = uint64(block.timestamp) + auctions[_nftContractAddress][_tokenId].defaultAuctionBidPeriod;
        return extendedEndTime > auctions[_nftContractAddress][_tokenId].endTime;
    }

    /**
    * @notice in the case of isBuyNowPrice is set then checks the highest bid is met with buyNowPrice
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _isBuyNowPriceMet(address _nftContractAddress, uint256 _tokenId) internal view returns (bool) {
        uint128 buyNowPrice = auctions[_nftContractAddress][_tokenId].buyNowPrice;
        return buyNowPrice > 0 && auctions[_nftContractAddress][_tokenId].highestBid >= buyNowPrice;
    }

    /**
    * @notice checks there is a bid for the auction
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _isBidMade(address _nftContractAddress, uint256 _tokenId) internal view returns (bool) {
        return auctions[_nftContractAddress][_tokenId].highestBid > 0;
    }

    /**
    * @notice in the case of `isBuyNowPrice` is set then checks the sent amount is higher than buyNowPrice
    * in other case sent amount must be higher than or equal to the `minPrice`
    * the last case is sent amount must be higher than or equal to the x percent more than previous bid
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _doesBidMeetBidRequirements(address _nftContractAddress, uint256 _tokenId) internal view returns (bool) {
        uint128 buyNowPrice = auctions[_nftContractAddress][_tokenId].buyNowPrice;
        if (buyNowPrice > 0 && msg.value >= buyNowPrice) {
            return true;
        }
        uint128 minPrice = auctions[_nftContractAddress][_tokenId].minPrice;
        if (minPrice > msg.value) {
            return false;
        }
        uint256 highestBid = auctions[_nftContractAddress][_tokenId].highestBid;
        uint32 increasePercentage = auctions[_nftContractAddress][_tokenId].defaultBidIncreasePercentage;
        uint256 bidIncreaseAmount = (highestBid * (10000 + increasePercentage)) / 10000;
        return msg.value >= bidIncreaseAmount;
    }

    function _transferBidSafely(address _recipient, uint256 _amount) internal {
        (bool success, ) = payable(_recipient).call{value: _amount, gas: 20000}("");
        // if it fails, it updates their credit balance so they can withdraw later
        if (!success) {
            IPaymentManager(paymentManager).depositFailedBalance{value: _amount}(_recipient);
            emit FailedTransfer(_recipient, _amount);
        }
    }

    /**
    * @notice transfers nft to current contract (AuctionMarketplace)
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _transferNftToAuctionContract(address _nftContractAddress, uint256 _tokenId) internal {
        address _nftSeller = auctions[_nftContractAddress][_tokenId].seller;
        IERC721Upgradeable(_nftContractAddress).safeTransferFrom(_nftSeller, address(this), _tokenId);
    }

    /**
    * @notice transfers nft to the highest bidder and pay the highest bid to the nft seller
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _transferNftAndPaySeller(address _nftContractAddress, uint256 _tokenId, bool isBuyNow) internal {
        address _nftSeller = auctions[_nftContractAddress][_tokenId].seller;
        address _nftHighestBidder = auctions[_nftContractAddress][_tokenId].highestBidder;
        uint256 _nftHighestBid = auctions[_nftContractAddress][_tokenId].highestBid;

        _resetBids(_nftContractAddress, _tokenId);

        _payout(payable(_nftSeller), _nftContractAddress, _tokenId, _nftHighestBid);

        _resetAuction(_nftContractAddress, _tokenId);

        IERC721Upgradeable(_nftContractAddress).safeTransferFrom(address(this), _nftHighestBidder, _tokenId);
        emit AuctionSettled(_nftContractAddress, _tokenId, _nftHighestBidder, _nftHighestBid, isBuyNow);
    }

    /**
    * @notice resets auction parameters
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _resetAuction(address _nftContractAddress, uint256 _tokenId) internal {
        auctions[_nftContractAddress][_tokenId].minPrice = 0;
        auctions[_nftContractAddress][_tokenId].buyNowPrice = 0;
        auctions[_nftContractAddress][_tokenId].startTime = 0;
        auctions[_nftContractAddress][_tokenId].endTime = 0;
        auctions[_nftContractAddress][_tokenId].seller = address(0);
        auctions[_nftContractAddress][_tokenId].defaultBidIncreasePercentage = 0;
        auctions[_nftContractAddress][_tokenId].defaultAuctionBidPeriod = 0;
        for (uint8 i = 0; i < auctions[_nftContractAddress][_tokenId].shareholderSize; i++) {
            delete auctions[_nftContractAddress][_tokenId].shareholders[i];
        }
        auctions[_nftContractAddress][_tokenId].shareholderSize = 0;
    }

    /**
    * @notice resets auction bids
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    function _resetBids(address _nftContractAddress, uint256 _tokenId) internal {
        auctions[_nftContractAddress][_tokenId].highestBidder = address(0);
        auctions[_nftContractAddress][_tokenId].highestBid = 0;
    }

    /**
    * @notice makes sure a bid is applicable to buy the nft. In the case of sale, the bid needs to meet the buyNowPrice.
    * In other cases the bid needs to be a % higher than the previous bid.
    * @param _buyNowPrice a limit that allows bidders to buy directly
    * @param _minPrice a restriction for the bidders must pay minimum x amount.
    */
    modifier minPriceDoesNotExceedLimit(uint128 _buyNowPrice, uint128 _minPrice) {
        require(
            _buyNowPrice == 0 ||  (_buyNowPrice * (10000 + defaultBidIncreasePercentage) / 10000) >=_minPrice,
            "buyNowPrice must be greater than or equal to %defaultBidIncreasePercentage percent more than minimumPrice"
        );
        _;
    }

    /**
    * @notice makes sure auction has not started yet and the given nft is belongs to the msg.sender
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier isAuctionNotStartedByOwner(address _nftContractAddress, uint256 _tokenId) {
        require(msg.sender != auctions[_nftContractAddress][_tokenId].seller, "Auction has been already started");
        require(msg.sender == IERC721Upgradeable(_nftContractAddress).ownerOf(_tokenId), "Sender doesn't own NFT");
        _;
    }

    /**
    * @notice checks the given value is greater than `minimumPriceLimit`
    */
    modifier priceGreaterThanMinimumPriceLimit(uint256 _price) {
        require(_price >= minimumPriceLimit, "Price must be higher than minimum price limit");
        _;
    }

    /**
    * @notice sent amount must be greater than zero
    */
    modifier paymentAccepted() {
        require(msg.value > 0, "Bid must be greater than zero");
        _;
    }

    /**
    * @notice makes sure a bid is applicable to buy the nft.
    * In the case of sale, the bid needs to meet the buyNowPrice.
    * In other cases the bid needs to be a % higher than the previous bid.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier bidAmountMeetsBidRequirements(address _nftContractAddress, uint256 _tokenId) {
        require(_doesBidMeetBidRequirements(_nftContractAddress, _tokenId), "Not enough funds to bid on NFT");
        _;
    }

    /**
    * @notice makes sure auction is ongoing in the range of between startTime and endTime
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier auctionOngoing(address _nftContractAddress, uint256 _tokenId) {
        uint64 endTime = auctions[_nftContractAddress][_tokenId].endTime;
        uint64 startTime = auctions[_nftContractAddress][_tokenId].startTime;

        require((block.timestamp >= startTime) && (block.timestamp < endTime), "Auction is not going on");
        _;
    }

    /**
    * @notice makes sure auction is over
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier isAuctionOver(address _nftContractAddress, uint256 _tokenId) {
        require(block.timestamp >= auctions[_nftContractAddress][_tokenId].endTime, "Auction has not over yet");
        _;
    }

    /**
    * @notice makes sure no bids have been submitted to the auction yet.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier bidNotMade(address _nftContractAddress, uint256 _tokenId) {
        require(!_isBidMade(_nftContractAddress, _tokenId), "The auction has a valid bid made");
        _;
    }

    /**
    * @notice makes sure bids have been received in the auction.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier bidMade(address _nftContractAddress, uint256 _tokenId) {
        require(_isBidMade(_nftContractAddress, _tokenId), "The auction has not a valid bid made");
        _;
    }

    /**
    * @notice makes sure msg.sender is nft owner  of the given contract address and tokenId.
    * @param _nftContractAddress nft contract address
    * @param _tokenId nft tokenId
    */
    modifier onlyNftSeller(address _nftContractAddress, uint256 _tokenId) {
        address seller = auctions[_nftContractAddress][_tokenId].seller;
        require(msg.sender == seller, "Only nft seller");
        _;
    }

    /**
    * @notice checks the given value is not zero address
    */
    modifier addressIsNotZero(address _address) {
        require(_address != address(0), "Given address must be a non-zero address");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// contains information about revenue share on each sale
library LibShareholder {
    struct Shareholder {
        address account; // receiver wallet address
        uint96 value; // percentage of share
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../libs/LibShareholder.sol";

interface IPaymentManager {
    function payout(address payable _seller, address _nftContractAddress, uint256 _tokenId, LibShareholder.Shareholder[] memory _shareholders, uint96 _commissionPercentage) external payable;
    function getMaximumShareholdersLimit() external view returns (uint256);
    function depositFailedBalance(address _account) external payable;
    function getCommissionPercentage() external returns (uint96);
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