// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165CheckerUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";

import "../interfaces/IERC721Mintable.sol";
import "../interfaces/IRewardManager.sol";

import "../libraries/SafeCastExtended.sol";
import "../libraries/PauseMetrics.sol";
import "./Listings.sol";
import "./Offers.sol";

/**
 * @title Marketplace
 * @author JaboiNads
 * @notice NFT Marketplace for the CryptoVikings project.
 */
contract Marketplace is OwnableUpgradeable, PausableUpgradeable, ERC721HolderUpgradeable {
    using AddressUpgradeable for address payable;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeCastExtended for uint256;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using ERC165CheckerUpgradeable for address;
    using Listings for Listings.Data;
    using Offers for Offers.Data;
    using PauseMetrics for PauseMetrics.Data;

    /**
     * @dev Marketplace configuration properties.
     */
    struct Config {
        // The address to send developer payments to.
        address developerWallet;
        // The minimum auction duration.
        uint32 minValidDuration;
        // The maximum auction duration
        uint32 maxValidDuration;
        // The rate from sales that goes to the token's minter (0.1% precision).
        uint16 minterRate;
        // The rate from sales that goes to the developers (0.1% precision).
        uint16 developerRate;
        // The reward manager instance.
        IRewardManager rewardManager;
        // How much to extend auctions by when a bid is placed with less than this much time remaining.
        uint16 bidExtensionTime;
        // The minimum percentage that a bid must increase by (0.1% precision).
        uint16 minBidIncreaseRate;
    }

    // The precision scalar for rate calculations (1000 = 0.1% precision)
    uint32 private constant PRECISION_SCALAR = 1000;

    // The configuration instance.
    Config private _config;

    // The pause metrics instance.
    PauseMetrics.Data private _pauseMetrics;

    // The set of tokens that can be traded on the marketplace.
    EnumerableSetUpgradeable.AddressSet private _whitelistedTokens;

    // The currently active listings.
    Listings.Data private _listings;

    // The currently active offers.
    Offers.Data private _offers;

    /**
     * @notice Emitted when the minter rate changes.
     * @param oldMinterRate The old minter rate (0.1% precision).
     * @param newMinterRate The new minter rate (0.1% precision).
     */
    event MinterRateChanged(
        uint16 oldMinterRate,
        uint16 newMinterRate
    );

    /**
     * @notice Emitted when the developer rate changes.
     * @param oldDeveloperRate The old developer rate (0.1% precision).
     * @param newDeveloperRate The new developer rate (0.1% precision).
     */
    event DeveloperRateChanged(
        uint16 oldDeveloperRate,
        uint16 newDeveloperRate
    );

    /**
     * @notice Emitted when the valid auction duration range changes.
     * @param oldMinimumAuctionDuration The old minimum auction duration.
     * @param oldMinimumAuctionDuration The old maximum auction duration. 
     * @param newMinimumAuctionDuration The new maximum auction duration.
     * @param newMaximumAuctionDuration The new maximum auction duration.
     */
    event ValidDurationRangeChanged(
        uint32 oldMinimumAuctionDuration,
        uint32 oldMaximumAuctionDuration,
        uint32 newMinimumAuctionDuration,
        uint32 newMaximumAuctionDuration
    );

    /**
     * @notice Emitted whenever the bid extension time changes.
     * @param oldBidExtensionTime The old bid extension time.
     * @param newBidExtensionTime The new bid extension time.
     */
    event BidExtensionTimeChanged(
        uint16 oldBidExtensionTime,
        uint16 newBidExtensionTime
    );

    /**
     * @notice Emitted when the minimum bid increase changes.
     * @param oldMinimumBidIncrease The old minimum bid increase.
     * @param newMinimumBidIncrease The new minimum bid increase.
     */
    event MinimumBidIncreaseRateChanged(
        uint16 oldMinimumBidIncrease,
        uint16 newMinimumBidIncrease
    );

    /**
     * @notice Emitted when the developer wallet changes.
     * @param oldDeveloperWallet The old developer wallet.
     * @param newDeveloperWallet The new developer wallet.
     */
    event DeveloperWalletChanged(
        address oldDeveloperWallet,
        address newDeveloperWallet
    );

    /**
     * @notice Emitted when the reward manager changes.
     * @param oldRewardManager The old reward manager.
     * @param newRewardManager The new reward manager.
     */
    event RewardManagerChanged(
        IRewardManager oldRewardManager,
        IRewardManager newRewardManager
    );

    /**
     * @notice Emitted when a token is added to the whitelist.
     * @param token The token that was added.
     */
    event AddedWhitelistedToken(
        IERC721Mintable indexed token
    );

    /**
     * @notice Emitted when a token is removed from the whitelist.
     * @param token The token that was removed.
     */
    event RemovedWhitelistedToken(
        IERC721Mintable indexed token
    );

    /**
     * @notice Emitted when a fixed price listing is created.
     * @param listingId The unique id of the listing.
     * @param token The token that was listed.
     * @param tokenId The id of the token that was listed.
     * @param seller The address that created the listing.
     * @param price The asking price.
     */
    event FixedPriceListingCreated(
        uint48 indexed listingId,
        IERC721Mintable indexed token,
        uint48 indexed tokenId,
        address seller,
        uint128 price,
        uint32 pauseDurationAtCreation
    );

    /**
     * @notice Emitted when a Dutch auction listing is created.
     * @param listingId The unique id of the listing.
     * @param token The token that was listed.
     * @param tokenId The id of the token that was listed.
     * @param seller The address that created the listing.
     * @param startingPrice The price to start the auction at.
     * @param endingPrice The price to end the auction at.
     * @param duration How long the auction will run for (in seconds).
     */
    event DutchAuctionListingCreated(
        uint48 indexed listingId,
        IERC721Mintable indexed token,
        uint48 indexed tokenId,
        address seller,
        uint128 startingPrice,
        uint128 endingPrice,
        uint32 duration,
        uint32 pauseDurationAtCreation
    );

    /**
     * @notice Emitted when an English auction listing is created.
     * @param listingId The unique id of the listing.
     * @param token The token that was listed.
     * @param tokenId The id of the token that was listed.
     * @param seller The address that created the listing.
     * @param startingPrice The price to start the auction at.
     * @param buyoutPrice The price to instantly but the token, or 0 if no buyout is available.
     * @param duration How long the auction will run for (in seconds).
     */
    event EnglishAuctionListingCreated(
        uint48 indexed listingId,
        IERC721Mintable indexed token,
        uint48 indexed tokenId,
        address seller,
        uint128 startingPrice,
        uint128 buyoutPrice,
        uint32 duration,
        uint32 pauseDurationAtCreation
    );

    /**
     * @notice Emitted when a listing is cancelled by the seller.
     * @param listingId The unique identifier for the listing.
     */
    event ListingCancelled(
        uint48 indexed listingId
    );

    /**
     * @notice Emitted when a listing has concluded successfully.
     * @param listingId The unique identifier for the listing.
     * @param buyer The address that bought the token.
     * @param price The amount that the token sold for.
     */
    event ListingSuccessful(
        uint48 indexed listingId,
        address buyer,
        uint128 price
    );

    /**
     * @notice Emitted when a new bid is created.
     * @param listingId The unique identifier for the listing.
     * @param bidder The address that placed the bid.
     * @param amount The amount that was bid.
     */
    event BidCreated(
        uint48 indexed listingId,
        address bidder,
        uint128 amount
    );

    /**
     * @notice Emitted when a bid is refunded.
     * @param listingId The unique identifier for the listing.
     * @param bidder The address that created the bid.
     */
    event BidRefunded(
        uint48 indexed listingId,
        address bidder,
        uint128 amount
    );

    /**
     * @notice Emitted when an offer is created for a token.
     * @param offerId The unique identifier for the offer.
     * @param token The token that the offer was made for.
     * @param tokenId The id of the token that the offer was made for.
     * @param offerer The address that created the offer.
     * @param amount The amount that was offered.
     */
    event OfferCreated(
        uint48 indexed offerId,
        IERC721Mintable indexed token,
        uint48 indexed tokenId,
        address offerer,
        uint128 amount
    );

    /**
     * @notice Emitted when an existing offer is updated.
     */
    event OfferUpdated(
        uint48 indexed offerId,
        uint128 newAmount
    );

    /**
     * @notice Emitted when an offer is cancelled.
     * @param offerId The unique identifier for the offer.
     */
    event OfferCancelled(
        uint48 indexed offerId
    );

    /**
     * @notice Emitted when an offer is accepted.
     * @param offerId The unique identifier for the offer.
     */
    event OfferAccepted(
        uint48 indexed offerId
    );

    /**
     * @notice Emitted when an offer is rejected.
     * @param offerId The unique identifier for the offer.
     */
    event OfferRejected(
        uint48 indexed offerId
    );

    /**
     * @notice Restricts functionality to tokens that are whitelisted.
     * @param token The token to check.
     */
    modifier onlyWhitelisted(
        IERC721Mintable token
    ) {
        require(_whitelistedTokens.contains(address(token)), "token not whitelisted");
        _;
    }
    
    /**
     * @notice Restricts functionality to tokens that are not currently listed.
     * @param token The token to check.
     * @param tokenId The id of the token to check.
     */
    modifier onlyUnlisted(
        IERC721Mintable token,
        uint48 tokenId
    ) {
        require(!_listings.exists(token, tokenId), "token already listed");
        _;
    }

    /**
     * @notice Initializes the contract when it is first deployed. This will not run when
     */
    function initialize(
        address developerWallet,
        IRewardManager rewardManager
    ) public initializer {
        __Ownable_init();
        __Pausable_init_unchained();
        __ERC721Holder_init_unchained();
        __Marketplace_init_unchained(developerWallet, rewardManager);
    }

    // solhint-disable-next-line func-name-mixedcase
    function __Marketplace_init_unchained(
        address developerWallet,
        IRewardManager rewardManager
    ) internal onlyInitializing {
        setDeveloperWallet(developerWallet);
        setRewardManager(rewardManager);
        setSalesRates(20, 30);
        setValidDurationRange(30 minutes, 14 days);
    }

    /**
     * @notice Pauses marketplace functionality.
     */
    function pause() external onlyOwner {
        _pause();
        _pauseMetrics.pause();
    }

    /**
     * @notice Unpauses marketplace functionality.
     */
    function unpause() external onlyOwner {
        _unpause();
        _pauseMetrics.unpause();
    }

    /**
     * @notice Sets the rate that minters and developers get on all sales.
     * @param minterRate The minter rate
     */
    function setSalesRates(
        uint16 minterRate,
        uint16 developerRate
    ) public onlyOwner {
        require(minterRate + developerRate <= PRECISION_SCALAR, "bad rates");

        if (minterRate != _config.minterRate) {
            emit MinterRateChanged(_config.minterRate, minterRate);
            _config.minterRate = minterRate;
        }

        if (developerRate != _config.developerRate) {
            emit DeveloperRateChanged(_config.developerRate, developerRate);
            _config.developerRate = developerRate;
        }
    }

    /**
     * @notice Sets the valid auction duration range.
     * @param minValidDuration The minimum valid auction duration (in seconds).
     * @param maxValidDuration The maximum valid auction duration (in seconds).
     */
    function setValidDurationRange(
        uint32 minValidDuration,
        uint32 maxValidDuration
    ) public onlyOwner {
        require(minValidDuration != 0 && minValidDuration < maxValidDuration, "invalid duration range");

        emit ValidDurationRangeChanged(_config.minValidDuration, _config.maxValidDuration, minValidDuration, maxValidDuration);
        _config.minValidDuration = minValidDuration;
        _config.maxValidDuration = maxValidDuration;
    }

    /**
     * @notice Sets the bid extension time.
     * @param bidExtensionTime The bid extension time (in seconds).
     */
    function setBidExtensionTime(
        uint16 bidExtensionTime
    ) public onlyOwner {
        emit BidExtensionTimeChanged(_config.bidExtensionTime, bidExtensionTime);
        _config.bidExtensionTime = bidExtensionTime;
    }

    /**
     * @notice Sets the minimum bid increase rate.
     */
    function setMinimumBidIncreaseRate(
        uint16 minBidIncreaseRate
    ) public onlyOwner {
        require (minBidIncreaseRate > 0 && minBidIncreaseRate <= PRECISION_SCALAR, "invalid rate");

        emit MinimumBidIncreaseRateChanged(_config.minBidIncreaseRate, minBidIncreaseRate);
        _config.minBidIncreaseRate = minBidIncreaseRate;
    }

    /**
     * @notice Sets the developer wallet.
     * @param developerWallet The new developer wallet.
     */
    function setDeveloperWallet(
        address developerWallet
    ) public onlyOwner {
        require(developerWallet != address(0), "bad developer address");
        require(developerWallet != _config.developerWallet, "same address");

        emit DeveloperWalletChanged(_config.developerWallet, developerWallet);
        _config.developerWallet = developerWallet;
    }

    /**
     * @notice Sets the reward manager.
     * @param rewardManager The new reward manager.
     */
    function setRewardManager(
        IRewardManager rewardManager
    ) public onlyOwner {
        require(address(rewardManager).supportsInterface(type(IRewardManager).interfaceId), "not a valid reward manager");
        require(rewardManager != _config.rewardManager, "same address");

        emit RewardManagerChanged(_config.rewardManager, rewardManager);
        _config.rewardManager = rewardManager;
    }

    /**
     * @notice Adds a token to the whitelist.
     * @param token The token to add.
     */
    function addWhitelistedToken(
        IERC721Mintable token
    ) external onlyOwner {
        require(_whitelistedTokens.add(address(token)), "token already whitelisted");
        emit AddedWhitelistedToken(token);
    }

    /**
     * @notice Removes a token from the whitelist.
     * @param token The token to remove.
     */
    function removeWhitelistedToken(
        IERC721Mintable token
    ) external onlyOwner {
        require(_whitelistedTokens.remove(address(token)), "token not whitelisted");
        emit RemovedWhitelistedToken(token);
    }

    /**
     * @notice Creates a new fixed price listing.
     * @param token The token to list.
     * @param tokenId The id of the token to list.
     * @param price The asking price.
     */
    function createFixedPriceListing(
        IERC721Mintable token,
        uint48 tokenId,
        uint128 price
    ) external
        whenNotPaused
        onlyWhitelisted(token)
    {
        require(price > 0, "no price provided");

        // Write the listing to storage. This will fail if the listing already exists.
        uint48 listingId = _listings.addFixedPriceListing(token, tokenId, _msgSender(), _pauseMetrics.totalDuration, price);

        // Transfer ownership of the token to the marketplace. The sender must own the token, and the
        // marketplace must be approved to transfer the token, otherwise this will fail.
        token.safeTransferFrom(_msgSender(), address(this), tokenId);

        // Notify the world that a new listing was created.
        emit FixedPriceListingCreated(listingId, token, tokenId, _msgSender(), price, _pauseMetrics.totalDuration);
    }

    /**
     * @notice Creates a new dutch auction listing.
     * @param token The token to list.
     * @param tokenId The id of the token to list.
     * @param startingPrice The price to start the auction at.
     * @param endingPrice The price to end the auction at.
     * @param duration The length of time to run the auction for (in seconds).
     */
    function createDutchAuctionListing(
        IERC721Mintable token,
        uint48 tokenId,
        uint128 startingPrice,
        uint128 endingPrice,
        uint32 duration
    ) external
        whenNotPaused
        onlyWhitelisted(token)
    {
        if (true) {
            revert("Auctions are not yet available.");
        }
        require(endingPrice > 0, "ending price is zero");
        require(startingPrice > endingPrice, "starting price <= ending price");
        require(duration >= _config.minValidDuration && duration <= _config.maxValidDuration, "bad auction duration");

        // Write the listing to storage. This will fail if the listing already exists.
        uint48 listingId = _listings.addDutchAuctionListing(token, tokenId, _msgSender(), _pauseMetrics.totalDuration, startingPrice, endingPrice, duration);

        // Transfer ownership of the token to the marketplace. The sender must own the token, and the
        // marketplace must be approved to transfer the token, otherwise this will fail.
        token.safeTransferFrom(_msgSender(), address(this), tokenId);

        // Notify the world that a Dutch auction was created.
        emit DutchAuctionListingCreated(listingId, token, tokenId, _msgSender(), startingPrice, endingPrice, duration, _pauseMetrics.totalDuration);
    }

    /**
     * @notice Creates a new English auction listing.
     * @param token The token to list.
     * @param tokenId The id of the token to list.
     * @param startingPrice The price to start the auction at.
     * @param buyoutPrice The price to automatically end the auction at, or 0 if not available.
     * @param duration The length of time to run the auction for (in seconds).
     */
    function createEnglishAuctionListing(
        IERC721Mintable token,
        uint48 tokenId,
        uint128 startingPrice,
        uint128 buyoutPrice,
        uint32 duration
    ) external
        whenNotPaused
        onlyWhitelisted(token)
    {
        if (true) {
            revert("Auctions are not yet available.");
        }
        require(startingPrice > 0, "starting price cannot be 0");
        require(buyoutPrice == 0 || buyoutPrice > startingPrice, "bad buyout price");
        require(duration >= _config.minValidDuration && duration <= _config.maxValidDuration, "bad auction duration");

        // Write the listing to storage. This will fail if the listing already exists.
        uint48 listingId = _listings.addEnglishAuctionListing(token, tokenId, _msgSender(), _pauseMetrics.totalDuration, startingPrice, buyoutPrice, duration);

        // Transfer ownership of the token to the marketplace. The sender must own the token, and the
        // marketplace must be approved to transfer the token, otherwise this will fail.
        token.safeTransferFrom(_msgSender(), address(this), tokenId);

        // Notify the world that an English auction was created.
        emit EnglishAuctionListingCreated(listingId, token, tokenId, _msgSender(), startingPrice, buyoutPrice, duration, _pauseMetrics.totalDuration);
    }

    /**
     * @notice Cancels a listing and returns the token to the seller.
     * @param listingId The id of the listing to cancel.
     */
    function cancelListing(
        uint48 listingId
    ) external
        whenNotPaused
    {
        Listings.Listing storage listing = _listings.get(listingId);
        require(_msgSender() == owner() || _msgSender() == listing.seller, "only owner or seller");
        require(listing.highestBidder == address(0), "cannot cancel listing with bids");

        // Transfer ownership of the token back to the seller.
        listing.token.safeTransferFrom(address(this), listing.seller, listing.tokenId);

        // Remove the listing from storage.
        _listings.removeListing(listingId);

        // Notify the world that the listing was removed.
        emit ListingCancelled(listingId);
    }

    /**
     * @notice Buys a listing from the marketplace.
     * @param listingId The id of the listing to buy.
     */
    function buy(
        uint48 listingId
    ) public payable
        whenNotPaused
    {
        Listings.Listing storage listing = _listings.get(listingId);
        require(_msgSender() != listing.seller, "seller cannot buy own listing");

        // Prevent users from buying listings that have already concluded.
        if (listing.listingType == Listings.ListingType.DutchAuction || listing.listingType == Listings.ListingType.EnglishAuction) {
            uint256 auctionEndTime = _getAuctionEndTime(listing);
            require(block.timestamp < auctionEndTime, "auction has concluded");
        }

        // Gets the buy price for the token.
        uint128 price = _listings.getBuyPrice(listingId);
        require(price != 0, "listing has no buyout price");
        require(msg.value >= price, "not enough paid");

        // Refund the highest bidder.
        _refundHighestBid(listingId, listing);

        // Transfer ownership of the token to the buyer.
        listing.token.safeTransferFrom(address(this), _msgSender(), listing.tokenId);

        // Distribute the payment to the seller, minter, and developers.
        _distributeSalePayment(listing.seller, listing.token.minterOf(listing.tokenId), price);

        // Remove the listing from storage
        _listings.removeListing(listingId);

        // Refund any excess payment back to the buyer.
        if (msg.value > price) {
            payable(_msgSender()).sendValue(msg.value - price);
        }

        // Notify the world that the listing was successful.
        emit ListingSuccessful(listingId, _msgSender(), price);
    }

    /**
     * @notice Creates a new bid on a listed item.
     * @param listingId The id of the listing to bid on.
     */
    function createBid(
        uint48 listingId
    ) external payable
        whenNotPaused
    {
        Listings.Listing storage listing = _listings.get(listingId);
        require(_msgSender() != listing.seller, "seller cannot bid on own listing");
        require(listing.listingType == Listings.ListingType.EnglishAuction, "can only bid on English auctions");

        // The bidder has paid at least the buyout price, so buy instead of bidding.
        if (listing.buyoutOrEndingPrice != 0 && msg.value >= listing.buyoutOrEndingPrice) {
            buy(listingId);
            return;
        }

        // Pausing the contract will extend the auction duration by the length of time that the contract was paused.
        uint256 auctionEndTime = _getAuctionEndTime(listing);
        require(block.timestamp < auctionEndTime, "auction has concluded");

        // Calculate the minimum required bid.
        uint128 minAcceptedBid = listing.startingPrice;
        if (listing.highestBidder != address(0)) {
            minAcceptedBid = listing.highestBid + ((listing.highestBid * _config.minBidIncreaseRate) / PRECISION_SCALAR);
        }
        require(msg.value >= minAcceptedBid, "bid is too low");

        // Refund the previous highest bidder.
        _refundHighestBid(listingId, listing);

        // Write the new bidder to storage.
        listing.highestBidder = _msgSender();
        listing.highestBid = msg.value.toUint128();

        // Notify the world that a bid was placed.
        emit BidCreated(listingId, _msgSender(), msg.value.toUint128());
    }

    /**
     * @notice Concludes an auction that has run its duration.
     * @param listingId The id of the listing to conclude.
     */
    function concludeAuction(
        uint48 listingId
    ) external
        whenNotPaused
    {
        Listings.Listing storage listing = _listings.get(listingId);
        require(listing.listingType == Listings.ListingType.EnglishAuction, "must be English auction");

        uint256 auctionEndTime = _getAuctionEndTime(listing);
        require(block.timestamp >= auctionEndTime, "auction has not concluded");

        if (listing.highestBidder == address(0)) {
            // Auction had no bidders, so return the token to the seller.
            listing.token.safeTransferFrom(address(this), listing.seller, listing.tokenId);

            // Notify the world that the auction failed.
            emit ListingCancelled(listingId);
        } else {
            // Transfer ownership of the token to the buyer.
            listing.token.safeTransferFrom(address(this), listing.highestBidder, listing.tokenId);
            
            // Distribute payment to the seller, minter, and developers.
            _distributeSalePayment(listing.seller, listing.token.minterOf(listing.tokenId), listing.highestBid);

            // Notify the world that the auction was successful.
            emit ListingSuccessful(listingId, listing.highestBidder, listing.highestBid);
        }

        // Remove the listing from storage.
        _listings.removeListing(listingId);
    }

    /**
     * @notice Creates a new offer for an item.
     * @param token The token contract.
     * @param tokenId The id of the token.
     */
    function createOffer(
        IERC721Mintable token,
        uint48 tokenId
    ) external payable
        whenNotPaused
        onlyWhitelisted(token)
    {
        // Create the offer and write it to storage.
        uint48 offerId = _offers.addOffer(token, tokenId, _msgSender(), msg.value.toUint128());

        // Notify the world that an offer was created.
        emit OfferCreated(offerId, token, tokenId, _msgSender(), msg.value.toUint128());
    }

    /**
     * @notice Cancels an existing offer.
     * @param offerId The id of the offer to cancel.
     */
    function cancelOffer(
        uint48 offerId
    ) external
        whenNotPaused
    {
        Offers.Offer storage offer = _offers.get(offerId);
        require(_msgSender() == owner() || _msgSender() == offer.offerer, "must be developer or offerer");

        // Remove the offer from storage and refund the offerer.
        address offerer = offer.offerer;
        uint128 amount = offer.amount;

        // Remove the offer from storage.
        _offers.removeOffer(offerId);

        // Refund the offerer.
        payable(offerer).sendValue(amount);

        // Notify the world that the offer was cancelled.
        emit OfferCancelled(offerId);
    }

    /**
     * @notice Accepts an existing offer.
     * @param offerId The id of the offer to accept.
     */
    function acceptOffer(
        uint48 offerId
    ) external
        whenNotPaused
    {
        Offers.Offer storage offer = _offers.get(offerId);
        require(_msgSender() == offer.token.ownerOf(offer.tokenId), "must be token owner");

        // Transfer the token to the offerer.
        offer.token.safeTransferFrom(_msgSender(), offer.offerer, offer.tokenId);

        // Distribute payment to the seller, minter, and developers.
        _distributeSalePayment(_msgSender(), offer.token.minterOf(offer.tokenId), offer.amount);

        // Remove the offer from storage.
        _offers.removeOffer(offerId);

        // Notify the world that the offer was accepted.
        emit OfferAccepted(offerId);
    }

    /**
     * @notice Accepts an existing offer.
     * @param offerId The id of the offer to accept.
     */
    function rejectOffer(
        uint48 offerId
    ) external
        whenNotPaused
    {
        Offers.Offer storage offer = _offers.get(offerId);
        require(_msgSender() == offer.token.ownerOf(offer.tokenId), "must be token owner");

        // Transfer the offer amount to the offerer's reward balance.
        _config.rewardManager.depositPersonalReward{value: offer.amount}(offer.offerer);

        // Remove the offer from storage.
        _offers.removeOffer(offerId);

        // Notify the world that the offer was rejected.
        emit OfferRejected(offerId);
    }

    /**
     * @notice Distributes payment from a sale or offer to the token's owner, minter, and the developers.
     * @param seller The address that is selling the sold token.
     * @param minter The address that minted the sold token.
     * @param price The amount that was paid for the token.
     */
    function _distributeSalePayment(
        address seller,
        address minter,
        uint128 price
    ) internal {
        // Calculate the minter cut and deposit it to the minter's reward balance.
        uint256 minterCut = (price * _config.minterRate) / PRECISION_SCALAR;
        _config.rewardManager.depositPersonalReward{value: minterCut}(minter);

        // Calculate the developer cut and deposit it to the developer wallet.
        uint256 developerCut = (price * _config.developerRate) / PRECISION_SCALAR;
        payable(_config.developerWallet).sendValue(developerCut);

        // Deposit the remainder of the payment to the seller's reward balance.
        _config.rewardManager.depositPersonalReward{value: price - minterCut - developerCut}(seller);
    }

    /**
     * @notice Refunds the highest bidder for an auction.
     * @param listingId The id of the listing.
     * @param listing The listing.
     */
    function _refundHighestBid(
        uint48 listingId,
        Listings.Listing storage listing
    ) internal {
        if (listing.highestBidder != address(0)) {
            _config.rewardManager.depositPersonalReward{value: listing.highestBid}(listing.highestBidder);
            emit BidRefunded(listingId, listing.highestBidder, listing.highestBid);
        }
    }

    /**
     * @notice Calculates the time that the auction concludes. Auctions will automatically be extended when the
     * contract is paused and unpaused.
     */
    function _getAuctionEndTime(
        Listings.Listing storage listing
    ) internal view returns (uint64) {
        return listing.createdAt + listing.duration - (_pauseMetrics.totalDuration - listing.pauseDurationAtCreation);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165CheckerUpgradeable {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165Upgradeable).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165Upgradeable.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

/**
 * @title IERC721Mintable
 * @author JaboiNads
 * @notice Adds functionality that allows for a token's minter to be retrieved.
 */
interface IERC721Mintable is IERC721Upgradeable, IERC721MetadataUpgradeable, IERC721EnumerableUpgradeable {

    /**
     * @notice Gets the address of the account that minted the token.
     * @param tokenId The id of the token.
     */
    function minterOf(uint256 tokenId) external view returns(address);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

/**
 * @title IRewardsManager
 * @author JaboiNads
 */
interface IRewardManager {

    /**
     * @notice Initializes a token with the rewards manager.
     * @param tokenId The id of the token.
     */
    function initializeToken(
        uint256 tokenId
    ) external;

    /**
     * @notice Deposits a reward that is evenly distributed to all registered holders.
     */
    function depositSharedReward() external payable;

    /**
     * @notice Deposits a reward for a specified recipient.
     * @param recipient The receiver of the reward.
     */
    function depositPersonalReward(
        address recipient
    ) external payable;

    /**
     * @notice Releases all unclaimed rewards belonging to the caller.
     * @return reward The amount of reward that was claimed.
     */
    function release() external returns (uint256 reward);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library SafeCastExtended {

    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "value doesn't fit in 248 bits");
        return uint248(value);
    }

    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "value doesn't fit in 240 bits");
        return uint240(value);
    }

    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "value doesn't fit in 232 bits");
        return uint232(value);
    }

    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "value doesn't fit in 224 bits");
        return uint224(value);
    }

    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "value doesn't fit in 216 bits");
        return uint216(value);
    }

    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "value doesn't fit in 208 bits");
        return uint208(value);
    }

    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "value doesn't fit in 200 bits");
        return uint200(value);
    }

    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "value doesn't fit in 192 bits");
        return uint192(value);
    }

    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "value doesn't fit in 184 bits");
        return uint184(value);
    }

    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "value doesn't fit in 176 bits");
        return uint176(value);
    }

    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "value doesn't fit in 168 bits");
        return uint168(value);
    }

    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "value doesn't fit in 160 bits");
        return uint160(value);
    }

    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "value doesn't fit in 152 bits");
        return uint152(value);
    }

    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "value doesn't fit in 144 bits");
        return uint144(value);
    }

    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "value doesn't fit in 136 bits");
        return uint136(value);
    }

    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "value doesn't fit in 128 bits");
        return uint128(value);
    }

    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "value doesn't fit in 120 bits");
        return uint120(value);
    }

    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "value doesn't fit in 112 bits");
        return uint112(value);
    }

    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "value doesn't fit in 104 bits");
        return uint104(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "value doesn't fit in 96 bits");
        return uint96(value);
    }

    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "value doesn't fit in 88 bits");
        return uint88(value);
    }

    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "value doesn't fit in 80 bits");
        return uint80(value);
    }

    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "value doesn't fit in 72 bits");
        return uint72(value);
    }

    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "value doesn't fit in 64 bits");
        return uint64(value);
    }

    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "value doesn't fit in 56 bits");
        return uint56(value);
    }

    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "value doesn't fit in 48 bits");
        return uint48(value);
    }

    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "value doesn't fit in 40 bits");
        return uint40(value);
    }

    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "value doesn't fit in 32 bits");
        return uint32(value);
    }

    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "value doesn't fit in 24 bits");
        return uint16(value);
    }

    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "value doesn't fit in 16 bits");
        return uint16(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "value doesn't fit in 8 bits");
        return uint8(value);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

/**
 * @title PauseMetrics
 * @author JaboiNads
 * @notice Adds functionality for tracking how long a contract has been paused.
 */
library PauseMetrics {
    using SafeCastUpgradeable for uint256;

    struct Data {
        // The unix timestamp of the time the contract was paused.
        uint64 lastPauseTimestamp;
        // The total amount of time that this contract has been paused (in seconds).
        uint32 totalDuration;
    }

    /**
     * @notice Updates the pause time.
     * @param self The data set to operate on.
     */
    function pause(
        PauseMetrics.Data storage self
    ) internal {
        require(!isPaused(self), "already paused");
        self.lastPauseTimestamp = block.timestamp.toUint32();
    }

    /**
     * @notice Updates the total pause duratio
     */
    function unpause(
        PauseMetrics.Data storage self
    ) internal {
        require(isPaused(self), "already unpaused");
        require(self.lastPauseTimestamp != 0, "already unpaused");
        self.totalDuration = (block.timestamp - self.lastPauseTimestamp).toUint32();
        self.lastPauseTimestamp = 0;
    }

    /**
     * @notice Gets whether the metrics are already paused.
     */
    function isPaused(
        PauseMetrics.Data storage self
    ) internal view returns (bool) {
        return self.lastPauseTimestamp != 0;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "../libraries/SafeCastExtended.sol";
import "../interfaces/IERC721Mintable.sol";

/**
 * @title Listings Library
 * @author JaboiNads
 * @notice Encapsulates functionality for listings on the Marketplace.
 */
library Listings {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeCastExtended for uint256;

    uint32 constant private PRECISION_SCALAR = 1000;

    /**
     * @dev The different types of listing.
     */
    enum ListingType {
        Unlisted,
        FixedPrice,
        DutchAuction,
        EnglishAuction
    }

    /**
     * @dev Data for an individual listing.
     */
    struct Listing {
        // The unique identifier of the token.
        uint48 tokenId;
        // The type of token that is listed.
        IERC721Mintable token;
        // The unix timestamp of the block the listing was created on (in seconds).
        uint64 createdAt;
        // [Auctions Only]: The duration of the listing (in seconds).
        uint32 duration;
        // [Auctions Only]: The price to begin bidding at.
        uint128 startingPrice;
        // The ending price (Dutch Auctions), or the buyout price (Fixed price, English auction) if present.
        uint128 buyoutOrEndingPrice;
        // The address that created the listing.
        address seller;
        // The address with the highest bid (English Auctions only)
        address highestBidder;
        // The current highest bid (English Auctions only)
        uint128 highestBid;
        // The type of listing.
        ListingType listingType;
        // How long the contract was paused at the time the listing was created.
        uint32 pauseDurationAtCreation;
    }

    /**
     * @dev Data for managing active listings.
     */
    struct Data {
        // The counter for generating unique listing ids.
        CountersUpgradeable.Counter idCounter;
        // Maps a token to its listing id, or zero if the listing does not exist.
        mapping(IERC721Mintable => mapping(uint48 => uint48)) indices;
        // Maps a listing ID to the listing.
        mapping(uint48 => Listing) listings;
    }

    /**
     * @notice Creates a fixed price listing and adds it to storage.
     * @param self The data set to operate on.
     * @param token The contract of the token.
     * @param tokenId The id of the token.
     * @param seller The seller of the token.
     * @param price The price to list the token at.
     */
    function addFixedPriceListing(
        Data storage self,
        IERC721Mintable token,
        uint48 tokenId,
        address seller,
        uint32 currentPauseDuration,
        uint128 price
    ) internal returns (uint48) {
        require(price > 0, "no price provided");

        return _addListing(
            self,
            ListingType.FixedPrice,
            token,
            tokenId,
            seller,
            currentPauseDuration,
            0,
            0,
            price
        );
    }

    /**
     * @notice Creates a fixed price listing and adds it to storage.
     * @param self The data set to operate on.
     * @param token The contract of the token.
     * @param tokenId The id of the token.
     * @param seller The seller of the token.
     * @param currentPauseDuration The marketplace's current pause duration.
     * @param startingPrice The price to begin the auction at.
     * @param endingPrice The price to end the auction at.
     * @param duration The length of time to run the auction for (in seconds).
     */
    function addDutchAuctionListing(
        Data storage self,
        IERC721Mintable token,
        uint48 tokenId,
        address seller,
        uint32 currentPauseDuration,
        uint128 startingPrice,
        uint128 endingPrice,
        uint32 duration
    ) internal returns (uint48) {
        require(startingPrice > endingPrice, "invalid price range");
        require(endingPrice > 0, "invalid ending price");
        require(duration > 0, "invalid duration");

        return _addListing(
            self,
            ListingType.DutchAuction,
            token,
            tokenId,
            seller,
            currentPauseDuration,
            duration,
            startingPrice,
            endingPrice
        );
    }

    /**
     * @notice Creates a English auction listing and adds it to storage.
     * @param self The data set to operate on.
     * @param token The contract of the token.
     * @param tokenId The id of the token.
     * @param seller The seller of the token.
     * @param currentPauseDuration The marketplace's current pause duration.
     * @param startingPrice The price to begin the auction at.
     * @param buyoutPrice The price to automatically buy the token at, or 0 for no buyout.
     * @param duration The length of time to run the auction for (in seconds).
     */
    function addEnglishAuctionListing(
        Data storage self,
        IERC721Mintable token,
        uint48 tokenId,
        address seller,
        uint32 currentPauseDuration,
        uint128 startingPrice,
        uint128 buyoutPrice,
        uint32 duration
    ) internal returns (uint48) {
        require(startingPrice > 0, "invalid starting price");
        require(buyoutPrice == 0 || buyoutPrice > startingPrice, "invalid buyout price");
        require(duration > 0, "invalid duration");

        return _addListing(
            self,
            ListingType.EnglishAuction,
            token,
            tokenId,
            seller,
            currentPauseDuration,
            duration,
            startingPrice,
            buyoutPrice
        );
    }

    /**
     * @notice Removes the specified listing from storage.
     * @param self The data set to operate on.
     * @param listingId The id of the listing to remove.
     * @dev This function will revert if the listing does not exist.
     */
    function removeListing(
        Data storage self,
        uint48 listingId
    ) internal {
        Listing storage listing = get(self, listingId);
        _removeListing(self, listing.token, listing.tokenId, listingId);
    }

    /**
     * @notice Removes the specified listing from storage.
     * @param self The data set to operate on.
     * @param listingId The id of the listing to remove.
     */
    function tryRemoveListing(
        Data storage self,
        uint48 listingId
    ) internal returns (bool) {
        (bool success, Listing storage listing) = tryGet(self, listingId);
        if (success) {
            _removeListing(self, listing.token, listing.tokenId, listingId);
        }
        return success;
    }

    /**
     * @notice Returns whether the specified listing exists.
     * @param self The data set to operate on.
     * @param listingId The unique id of the listing.
     */
    function exists(
        Data storage self,
        uint48 listingId
    ) internal view returns (bool) {
        return self.listings[listingId].listingType != ListingType.Unlisted;
    }

    /**
     * @notice Returns whether the specified listing exists.
     * @param self The data set to operate on.
     * @param token The contract of the token.
     * @param tokenId The id of the token.
     */
    function exists(
        Data storage self,
        IERC721Mintable token,
        uint48 tokenId
    ) internal view returns (bool) {
        return exists(self, self.indices[token][tokenId]);
    }

    /**
     * @notice Returns the listing associated with the specified id.
     * @param self The data set to operate on.
     * @param listingId The unique id of the listing.
     * @dev This function will revert if the listing does not exist.
     */
    function get(
        Data storage self,
        uint48 listingId
    ) internal view returns (Listing storage) {
        Listing storage listing = self.listings[listingId];
        require(listing.listingType != ListingType.Unlisted, "nonexistent listing");
        return listing;
    }

    /**
     * @notice Returns the listing associated with the specified token.
     * @param self The data set to operate on.
     * @param token The contract of the token.
     * @param tokenId The id of the token.
     * @dev This function will revert if the listing does not exist.
     */
    function get(
        Data storage self,
        IERC721Mintable token,
        uint48 tokenId
    ) internal view returns (Listing storage) {
        return get(self, self.indices[token][tokenId]);
    }
    
    /**
     * @notice Returns the listing associated with the specified id.
     * @param self The data set to operate on.
     * @param listingId The unique identifier of the listing.
     */
    function tryGet(
        Data storage self,
        uint48 listingId
    ) internal view returns (bool, Listing storage) {
        Listing storage listing = self.listings[listingId];
        return (listing.listingType != ListingType.Unlisted, listing);
    }

    /**
     * @notice Returns the listing associated with the specified token.
     * @param self The data set to operate on.
     * @param token The contract of the token.
     * @param tokenId The id of the token.
     */
    function tryGet(
        Data storage self,
        IERC721Mintable token,
        uint48 tokenId
    ) internal view returns (bool, Listing storage) {
        return tryGet(self, self.indices[token][tokenId]);
    }

    /**
     * @notice Gets the price to buy the specified listing.
     * @param self The data set to operate on.
     * @param listingId The id of the listing to buy.
     */
    function getBuyPrice(
        Data storage self,
        uint48 listingId
    ) internal view returns (uint128) {
        Listing storage listing = get(self, listingId);
        if (listing.listingType == ListingType.DutchAuction) {
            // Calculate the percentage of the auction that has finished so far.
            uint128 alpha = ((block.timestamp.toUint128() - listing.createdAt) * PRECISION_SCALAR) / listing.duration;
            // Linearly interpolate between the starting and ending prices, then normalize the result to get the real price. 
            return (listing.startingPrice - ((listing.startingPrice - listing.buyoutOrEndingPrice) * alpha)) / PRECISION_SCALAR;
        } else {
            return listing.buyoutOrEndingPrice;
        }
    }

    /**
     * @notice Generates a unique identifier for a listing.
     * @param self The data set to operate on.
     */
    function _generateNextId(
        Data storage self
    ) private returns (uint48) {
        self.idCounter.increment();
        return self.idCounter.current().toUint48();
    }

    /**
     * @notice Adds a listing to storage.
     * @param self The data set to operate on.
     * @param token The contract of the token to add.
     * @param tokenId The id of the token to add.
     * @param seller The address that created the listing.
     * @param duration The length of time to run the auction (in seconds).
     * @param startingPrice The starting price of the auction.
     * @param buyoutOrEndingPrice The buyout or ending price, or zero if
     */
    function _addListing(
        Data storage self,
        ListingType listingType,
        IERC721Mintable token,
        uint48 tokenId,
        address seller,
        uint32 currentPauseDuration,
        uint32 duration,
        uint128 startingPrice,
        uint128 buyoutOrEndingPrice
    ) private returns (uint48) {
        require(!exists(self, token, tokenId), "token is already listed");
        require(seller != address(0), "seller cannot be zero-address");
        require(seller == token.ownerOf(tokenId), "seller must own token");

        // Generate a unique identifier for the listing.
        uint48 listingId = _generateNextId(self);

        // Write the listing to storage.
        self.indices[token][tokenId] = listingId;
        self.listings[listingId] = Listing({
            listingType: listingType,
            token: token,
            tokenId: tokenId,
            seller: seller,
            pauseDurationAtCreation: currentPauseDuration,
            createdAt: block.timestamp.toUint64(),
            duration: duration,
            startingPrice: startingPrice,
            buyoutOrEndingPrice: buyoutOrEndingPrice,
            highestBidder: address(0),
            highestBid: 0
        });

        // Return the listing id.
        return listingId;
    }

    /**
     * @notice Deletes a listing from storage.
     * @param self The data set to operate on.
     * @param token The contract of the token to delete.
     * @param tokenId The id of the token to delete.
     * @param listingId The id of the listing to delete.
     */
    function _removeListing(
        Data storage self,
        IERC721Mintable token,
        uint48 tokenId,
        uint48 listingId
    ) private {
        delete self.indices[token][tokenId];
        delete self.listings[listingId];
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";

import "../libraries/SafeCastExtended.sol";
import "../interfaces/IERC721Mintable.sol";

/**
 * @title Offers Library
 * @author JaboiNads
 * @notice Encapsulates functionality for offers on the Marketplace.
 */
library Offers {
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using SafeCastExtended for uint256;
    
    /**
     * @dev Represents an individual offer made on a token.
     */
    struct Offer {
        // The token the offer was made on.
        IERC721Mintable token;
        // The id of the token the offer was made on.
        uint48 tokenId;
        // The address that made the offer.
        address offerer;
        // The amount that was offered.
        uint128 amount;
    }

    struct Data {
        // Generates unique identifiers for each offer.
        CountersUpgradeable.Counter idCounter;
        // Maps a token/offerer pair to the offer's id.
        mapping(IERC721Mintable => mapping(uint48 => mapping(address => uint48))) indices;
        // Maps an offer's id to the offer data.
        mapping(uint48 => Offer) offers;
    }

    /**
     * @notice Creates a new offer and adds it to storage.
     * @param self The data set to operate on.
     * @param token The token's contract address.
     * @param tokenId The id of the token.
     * @param offerer The address that created the offer.
     * @param amount The amount that was offered.
     */
    function addOffer(
        Data storage self,
        IERC721Mintable token,
        uint48 tokenId,
        address offerer,
        uint128 amount
    ) internal returns (uint48) {
        require(!exists(self, token, tokenId, offerer), "offer already exists");
        require(token.ownerOf(tokenId) != address(0), "token does not exist");
        require(offerer != address(0), "offerer cannot be zero-address");
        require(amount > 0, "no amount offered");

        // Generate a unique identifier for the listing.
        uint48 offerId = _generateNextId(self);

        // Write the offer to storage.
        self.indices[token][tokenId][offerer] = offerId;
        self.offers[offerId] = Offer({
            token: token,
            tokenId: tokenId,
            offerer: offerer,
            amount: amount
        });

        // Return the offer id.
        return offerId;
    }

    /**
     * @notice Removes the offer associated with the specified id from storage.
     * @param self The data set to operate on.
     * @param offerId The id of the offer to remove.
     * @dev This function will revert if the offer does not exist.
     */
    function removeOffer(
        Data storage self,
        uint48 offerId
    ) internal {
        Offer storage offer = get(self, offerId);
        _removeOffer(self, offerId, offer.token, offer.tokenId, offer.offerer);
    }

    /**
     * @notice Removes the offer associated with the specified id from storage.
     * @param self The data set to operate on.
     * @param offerId The id of the offer to remove.
     */
    function tryRemoveOffer(
        Data storage self,
        uint48 offerId
    ) internal returns (bool) {
        (bool success, Offer storage offer) = tryGet(self, offerId);
        if (success) {
            _removeOffer(self, offerId, offer.token, offer.tokenId, offer.offerer);
        }
        return success;
    }

    /**
     * @notice Returns whether the specified offer exists.
     * @param self The data set to operate on.
     * @param offerId The unique id of the offer.
     */
    function exists(
        Data storage self,
        uint48 offerId
    ) internal view returns (bool) {
        return self.offers[offerId].offerer != address(0);
    }

    /**
     * @notice Returns whether an offer associated with the token and offerer exists.
     * @param self The data set to operate on.
     * @param token The token's contract address.
     * @param tokenId The id of the token.
     * @param offerer The address that created the offer.
     */
    function exists(
        Data storage self,
        IERC721Mintable token,
        uint48 tokenId,
        address offerer
    ) internal view returns (bool) {
        return exists(self, self.indices[token][tokenId][offerer]);
    }

    /**
     * @notice Returns the offer associated with the specified id.
     * @param self The data set to operate on.
     * @param offerId The id of the offer to get.
     * @dev This function will revert if the listing does not exist.
     */
    function get(
        Data storage self,
        uint48 offerId
    ) internal view returns (Offer storage) {
        Offer storage offer = self.offers[offerId];
        require(offer.offerer != address(0), "nonexistent offer");
        return offer;
    }

    /**
     * @notice Returns the offer associated with the specified id.
     * @param self The data set to operate on.
     * @param token The token's contract address.
     * @param tokenId The id of the token.
     * @param offerer The address that made the offer.
     * @dev This function will revert if the listing does not exist.
     */
    function get(
        Data storage self,
        IERC721Mintable token,
        uint48 tokenId,
        address offerer
    ) internal view returns (Offer storage) {
        return get(self, self.indices[token][tokenId][offerer]);
    }

    /**
     * @notice Returns the offer associated with the specified id.
     * @param self The data set to operate on.
     * @param offerId The id of the offer to get.
     */
    function tryGet(
        Data storage self,
        uint48 offerId
    ) internal view returns (bool, Offer storage) {
        Offer storage offer = self.offers[offerId];
        return (offer.offerer != address(0), offer);
    }

    /**
     * @notice Returns the offer associated with the specified token and offerer.
     * @param token The token's contract address.
     * @param tokenId The id of the token.
     * @param offerer The address that made the offer.
     */
    function tryGet(
        Data storage self,
        IERC721Mintable token,
        uint48 tokenId,
        address offerer
    ) internal view returns (bool, Offer storage) {
        return tryGet(self, self.indices[token][tokenId][offerer]);
    }

    /**
     * @notice Generates a unique identifier for a listing.
     * @param self The data set to operate on.
     */
    function _generateNextId(
        Data storage self
    ) private returns (uint48) {
        self.idCounter.increment();
        return self.idCounter.current().toUint48();
    }

    /**
     * @notice Removes an offer from storage.
     * @param self The data set to operate on.
     * @param offerId The id of the offer.
     * @param token The token's contract address.
     * @param tokenId The id of the token.
     * @param offerer The address that made the offer.
     */
    function _removeOffer(
        Data storage self,
        uint48 offerId,
        IERC721Mintable token,
        uint48 tokenId,
        address offerer
    ) private {
        delete self.indices[token][tokenId][offerer];
        delete self.offers[offerId];
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCastUpgradeable {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}