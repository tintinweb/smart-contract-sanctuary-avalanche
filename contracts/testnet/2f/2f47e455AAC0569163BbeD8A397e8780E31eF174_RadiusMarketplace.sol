/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
// File: interfaces/IRadiusNFT.sol


pragma solidity ^0.8.7;

interface RadiusNft {
    function mint(
        address _owner,
        string memory _metadata,
        uint256 _count
    ) external;

    function ownerOf(uint256 _tokenId) external view returns (address);

    function exists(uint256 _tokenId) external view returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// File: interfaces/IRadius.sol


pragma solidity ^0.8.7;

interface IRadius {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function balanceOf(address _address) external view returns (uint256);

    function mint(uint256 _amount) external;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function isExcluded(address account) external view returns (bool);

    function reflectionFromToken(uint256 _amount, bool _deductFee)
        external
        view
        returns (uint256);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


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

// File: RadiusMarketplace.sol


pragma solidity ^0.8.7;





contract RadiusMarketplace is Ownable, ReentrancyGuard {
    IRadius private token;
    RadiusNft private nft;

    /// @notice basis point for percentage precision
    /// @notice 100% => 10000, 10% => 1000, 1% => 100
    uint256 private constant DENOMINATOR = 10000;

    /// @notice maximum duration for auction in days
    uint256 public maxAuctionDuration = 14;

    /// @notice minimum bid rise
    uint256 public minBidRise = 500;

    /// @notice enum for acceptable currencies
    enum Currency {
        TOKEN,
        NATIVE
    }

    /// @notice structure to store the sale record
    struct Sale {
        uint256 id;
        address originalOwner;
        uint256 price;
        Currency currency;
    }

    /// @notice structure to store the Auction record
    struct Auction {
        uint256 id;
        address originalOwner;
        uint256 startingBid;
        uint256 startingTime;
        uint256 duration;
        address highestBidder;
        uint256 highestBid;
        Currency currency;
    }

    uint256 public royalty;
    uint256 public mintFee;
    uint256 public minTokenBalance;
    uint256 public saleCounter;
    uint256 public auctionCounter;
    uint256 public tokenRoyaltyReceived;
    uint256 public nativeRoyaltyReceived;
    uint256 public mintFeeReceived;
    uint256 public auctionDurationIncrease;

    mapping(string => bool) public exists;
    mapping(uint256 => Sale) public nftSales;
    mapping(uint256 => Auction) public auctions;

    event NFTPutOnSale(
        uint256 indexed saleId,
        uint256 indexed tokenId,
        uint256 price,
        Currency currency
    );
    event NFTSalePriceUpdated(
        uint256 indexed saleId,
        uint256 tokenId,
        uint256 price,
        Currency currency
    );
    event NFTRemovedFromSale(uint256 indexed saleId, uint256 indexed tokenId);
    event NFTSold(
        uint256 indexed saleId,
        uint256 indexed tokenId,
        uint256 price,
        Currency currency
    );
    event AuctionStart(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        uint256 startingBid,
        uint256 startingTime,
        uint256 duration,
        Currency currency
    );
    event AuctionCancel(uint256 indexed auctionId, uint256 indexed tokenId);
    event PlaceBid(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        uint256 bid
    );
    event AuctionEnd(
        uint256 indexed auctionId,
        uint256 indexed tokenId,
        address highestBidder,
        uint256 highestBid
    );

    modifier isSaleOwner(uint256 _tokenId) {
        require(
            msg.sender == nftSales[_tokenId].originalOwner,
            "Only owner can call"
        );
        _;
    }

    modifier isAuctionOwner(uint256 _tokenId) {
        require(
            msg.sender == auctions[_tokenId].originalOwner,
            "Only owner can call"
        );
        _;
    }

    modifier nftExists(uint256 _tokenId) {
        require(nft.exists(_tokenId), "NFT does not exist");
        _;
    }

    modifier isOnSale(uint256 _tokenId) {
        require(
            nftSales[_tokenId].price > 0 &&
                address(this) == nft.ownerOf(_tokenId),
            "NFT is not on sale"
        );
        _;
    }

    modifier notOnSale(uint256 _tokenId) {
        require(nftSales[_tokenId].price == 0, "NFT is on sale");
        _;
    }

    modifier isOnAuction(uint256 _tokenId) {
        require(
            auctions[_tokenId].startingTime > 0 &&
                address(this) == nft.ownerOf(_tokenId),
            "NFT not being auctioned"
        );
        _;
    }

    modifier notOnAuction(uint256 _tokenId) {
        require(
            auctions[_tokenId].startingTime == 0,
            "NFT already being auctioned"
        );
        _;
    }

    constructor(
        address _nft,
        address _token,
        uint256 _mintFee,
        uint256 _minTokenBalance,
        uint256 _royalty,
        uint256 _auctionDurationIncrease
    ) {
        token = IRadius(_token);
        nft = RadiusNft(_nft);
        mintFee = _mintFee;
        minTokenBalance = _minTokenBalance;
        royalty = _royalty;
        auctionDurationIncrease = _auctionDurationIncrease;
    }

    function mint(
        string memory _imageHash,
        string memory _metadata,
        uint256 _count
    ) external payable nonReentrant {
        require(!exists[_imageHash], "Image already exists");
        require(msg.value >= mintFee * _count, "Insufficient funds received");
        require(
            token.balanceOf(msg.sender) >= minTokenBalance,
            "Not enough Radius tokens"
        );

        exists[_imageHash] = true;
        mintFeeReceived += mintFee * _count;
        payable(msg.sender).transfer(msg.value - mintFee * _count);

        nft.mint(msg.sender, _metadata, _count);
    }

    /// @notice used to put an NFT on sale by the owner of NFT
    /// @param _tokenId the id of the NFT
    /// @param _price the price of the NFT
    /// @param _currency it can be AVAX or RadiusCoin
    function putOnSale(
        uint256 _tokenId,
        uint256 _price,
        Currency _currency
    ) external nftExists(_tokenId) notOnSale(_tokenId) notOnAuction(_tokenId) {
        require(_price > 0, "Price cannot be zero");
        require(msg.sender == nft.ownerOf(_tokenId), "Only owner can call");

        nftSales[_tokenId] = Sale(++saleCounter, msg.sender, _price, _currency);

        nft.transferFrom(msg.sender, address(this), _tokenId);

        emit NFTPutOnSale(saleCounter, _tokenId, _price, _currency);
    }

    /// @notice used to update the sale price of an NFT
    /// @param _tokenId the id of the NFT
    /// @param _price the new price of the NFT
    /// @param _currency it can be AVAX or RadiusCoin
    function updateSalePrice(
        uint256 _tokenId,
        uint256 _price,
        Currency _currency
    ) external nftExists(_tokenId) isSaleOwner(_tokenId) isOnSale(_tokenId) {
        require(_price > 0, "Price cannot be zero");

        nftSales[_tokenId].price = _price;
        nftSales[_tokenId].currency = _currency;

        emit NFTSalePriceUpdated(
            nftSales[_tokenId].id,
            _tokenId,
            _price,
            _currency
        );
    }

    /// @notice used to remove the NFT from sale
    /// @param _tokenId the id of the NFT
    function removeFromSale(uint256 _tokenId)
        external
        nftExists(_tokenId)
        isSaleOwner(_tokenId)
        isOnSale(_tokenId)
    {
        uint256 saleId = nftSales[_tokenId].id;
        delete nftSales[_tokenId];

        nft.transferFrom(address(this), msg.sender, _tokenId);

        emit NFTRemovedFromSale(saleId, _tokenId);
    }

    /// @notice used to buy the NFT
    /// @param _tokenId the id of the NFT
    function buyNft(uint256 _tokenId)
        external
        payable
        nonReentrant
        nftExists(_tokenId)
        isOnSale(_tokenId)
    {
        require(
            nftSales[_tokenId].currency == Currency.TOKEN ||
                msg.value >= nftSales[_tokenId].price,
            "Insufficient funds sent"
        );

        address originalOwner = nftSales[_tokenId].originalOwner;
        uint256 price = nftSales[_tokenId].price;
        uint256 royaltyFee = (price * royalty) / DENOMINATOR;
        uint256 saleId = nftSales[_tokenId].id;
        Currency currency = nftSales[_tokenId].currency;

        delete nftSales[_tokenId];

        if (currency == Currency.NATIVE) {
            payable(originalOwner).transfer(price - royaltyFee);
            payable(msg.sender).transfer(msg.value - price);

            nativeRoyaltyReceived += royaltyFee;
        } else {
            token.transferFrom(msg.sender, originalOwner, price - royaltyFee);
            token.transferFrom(msg.sender, address(this), royaltyFee);
            payable(msg.sender).transfer(msg.value);

            tokenRoyaltyReceived += royaltyFee;
        }

        nft.transferFrom(address(this), msg.sender, _tokenId);

        emit NFTSold(saleId, _tokenId, price, currency);
    }

    /// @notice used to start the auction
    /// @param _tokenId the id of the token
    /// @param _startingBid ??
    /// @param _duration the duration of the auction in seconds
    /// @param _currency the currency AVAX or RadiusCoin
    function startAuction(
        uint256 _tokenId,
        uint256 _startingBid,
        uint256 _duration,
        Currency _currency
    ) external nftExists(_tokenId) notOnSale(_tokenId) notOnAuction(_tokenId) {
        require(msg.sender == nft.ownerOf(_tokenId), "Only owner can call");
        require(_duration <= maxAuctionDuration, "Decrease auction duration");

        auctions[_tokenId] = Auction(
            ++auctionCounter,
            msg.sender,
            _startingBid,
            block.timestamp,
            _duration * 1 days,
            address(0),
            0,
            _currency
        );

        nft.transferFrom(msg.sender, address(this), _tokenId);

        emit AuctionStart(
            auctionCounter,
            _tokenId,
            _startingBid,
            block.timestamp,
            _duration * 1 days,
            _currency
        );
    }

    /// @notice used to delete the auction of NFT
    /// @param _tokenId the id of the NFT
    function deleteAuction(uint256 _tokenId)
        external
        nftExists(_tokenId)
        isAuctionOwner(_tokenId)
        isOnAuction(_tokenId)
    {
        require(
            auctions[_tokenId].highestBid == 0,
            "Cannot delete once bid is placed"
        );

        uint256 auctionId = auctions[_tokenId].id;
        delete auctions[_tokenId];

        nft.transferFrom(address(this), msg.sender, _tokenId);

        emit AuctionCancel(auctionId, _tokenId);
    }

    /// @notice used to place the Bid for the NFT
    /// @param _tokenId the id of the NFT
    /// @param _bid the amount of bid placed for the NFT
    function placeBid(uint256 _tokenId, uint256 _bid)
        external
        payable
        nonReentrant
        nftExists(_tokenId)
        isOnAuction(_tokenId)
    {
        Auction storage item = auctions[_tokenId];

        uint256 bid = item.currency == Currency.NATIVE ? msg.value : _bid;
        uint256 auctionEndTime = item.startingTime + item.duration;

        require(bid >= nextAllowedBid(_tokenId), "Increase bid");
        require(block.timestamp <= auctionEndTime, "Auction duration ended");

        uint256 prevBid = item.highestBid;
        address prevBidder = item.highestBidder;

        item.highestBid = bid;
        item.highestBidder = msg.sender;

        if (block.timestamp >= auctionEndTime - 10 minutes) {
            item.duration += auctionDurationIncrease * 1 minutes;
        }

        if (item.currency == Currency.NATIVE) {
            payable(prevBidder).transfer(prevBid);
        } else {
            if (prevBidder != address(0)) {
                token.transfer(prevBidder, prevBid);
            }
            // check for eop limit
            token.transferFrom(msg.sender, address(this), bid);
        }

        emit PlaceBid(item.id, _tokenId, bid);
    }

    /// @notice used to claim the NFT
    /// @param _tokenId the id of the token
    function claimAuctionNft(uint256 _tokenId)
        external
        nonReentrant
        nftExists(_tokenId)
        isOnAuction(_tokenId)
    {
        Auction memory item = auctions[_tokenId];

        require(
            (msg.sender == item.highestBidder &&
                block.timestamp > item.startingTime + item.duration) ||
                msg.sender == item.originalOwner,
            "Only highest bidder or owner can call"
        );

        Currency currency = item.currency;
        address originalOwner = item.originalOwner;
        uint256 highestBid = item.highestBid;
        address highestBidder = item.highestBidder;
        uint256 royaltyFee = (highestBid * royalty) / DENOMINATOR;
        uint256 auctionId = auctions[_tokenId].id;

        delete auctions[_tokenId];

        if (currency == Currency.NATIVE) {
            payable(originalOwner).transfer(highestBid - royaltyFee);

            nativeRoyaltyReceived += royaltyFee;
        } else {
            token.transfer(originalOwner, highestBid - royaltyFee);

            tokenRoyaltyReceived += royaltyFee;
        }

        nft.transferFrom(address(this), highestBidder, _tokenId);

        emit AuctionEnd(auctionId, _tokenId, highestBidder, highestBid);
    }

    // ------------ VIEW FUNCTIONS ------------

    /// @notice used to check whether the user can claim auction or not
    /// @param _address address of the user
    /// @param _tokenId the ID of the NFT
    function canClaimAuctionNft(address _address, uint256 _tokenId)
        external
        view
        nftExists(_tokenId)
        isOnAuction(_tokenId)
        returns (bool)
    {
        Auction memory item = auctions[_tokenId];
        return (item.highestBid > 0 &&
            ((block.timestamp > item.startingTime + item.duration &&
                _address == item.highestBidder) ||
                _address == item.originalOwner));
    }

    /// @notice used to get the next bid that is allowed
    /// @param _tokenId the id of the NFT
    function nextAllowedBid(uint256 _tokenId)
        public
        view
        nftExists(_tokenId)
        isOnAuction(_tokenId)
        returns (uint256)
    {
        Auction memory item = auctions[_tokenId];
        return
            item.highestBid == 0
                ? item.startingBid
                : item.highestBid +
                    (item.highestBid * minBidRise) /
                    DENOMINATOR;
    }

    // ------------ ONLY OWNER FUNCTIONS ------------

    /// @notice used to update the mint fees only by the owner
    function updateMintFee(uint256 _mintFee) external onlyOwner {
        mintFee = _mintFee;
    }

    /// @notice used to update the royalty fees by the owner
    /// @param _royaltyFee the royalty fees
    function updateRoyaltyFee(uint256 _royaltyFee) external onlyOwner {
        require(_royaltyFee != royalty, "already set");
        royalty = _royaltyFee;
    }

    /// @notice used to update the max auction duration by the owner
    /// @param _duration the maximum duration of the auction
    function updateMaxAuctionDuration(uint256 _duration) external onlyOwner {
        require(maxAuctionDuration != _duration, "already set");
        maxAuctionDuration = _duration;
    }

    /// @notice used to update the minimum bid rise only by the owner
    /// @param _bidRise the amount of bid to rise by
    function updateMinBidRise(uint256 _bidRise) external onlyOwner {
        require(minBidRise != _bidRise, "already set");
        minBidRise = _bidRise;
    }

    /// @notice used to update the auction duration only by the owner
    /// @param _auctionDurationIncrease the duration of the auction
    function updateAuctionDurationIncrease(uint256 _auctionDurationIncrease)
        external
        onlyOwner
    {
        require(
            auctionDurationIncrease != _auctionDurationIncrease,
            "alread set"
        );
        auctionDurationIncrease = _auctionDurationIncrease;
    }

    /// @notice used to update the minimum token balance
    /// @param _minTokenBalance the minimum amount of token balance to update by
    function updateMinimumTokenBalance(uint256 _minTokenBalance)
        external
        onlyOwner
    {
        require(minTokenBalance != _minTokenBalance, "already set");
        minTokenBalance = _minTokenBalance;
    }

    /// @notice used to withdraw the royalty earned only by the owner
    /// @param _address the address to send the royalty
    function withdrawRoyalty(address payable _address) external onlyOwner {
        require(_address != address(0), "Address cannot be zero address");

        _address.transfer(nativeRoyaltyReceived);
        token.transfer(_address, tokenRoyaltyReceived);
    }

    receive() external payable {}
}