/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-17
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.14;

// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
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
}

interface IERC20 {

    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address from) external view returns (uint balance);
}

interface IERC721 {

    function ownerOf(uint256 tokenId) external view returns (address owner);
    function transferFrom(address from,address to,uint256 tokenId ) external;
}

contract CloudMetropolisMarket is ERC721Holder {

    struct Bid {
        uint bidPrice;
        bool active;
    }

    struct Listing {
        address owner;
        bool active;
        uint256 price;

    }
    
    address public nftContract;
    address public immutable wETH;
    address public owner;
    uint256 public marketCut;
    uint256 public marketFeePercent;
    bool public isMarketOpen = false;
    bool public emergencyDelisting = false;

    mapping(uint => mapping(address => Bid)) public bids;
    mapping(uint256 => Listing) public listings;

    

    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed newOwner);
    event AddListingEv(uint256 indexed tokenId, uint256 price);
    event UpdateListingEv(uint256 indexed tokenId, uint256 price);
    event CancelListingEv(uint256 indexed tokenId);
    event FulfillListingEv(uint256 indexed tokenId, uint price);

    event UpdateBidEv(uint256 tokenId, uint256 bidPrice);
    event CancelBidEv(uint256 tokenId);
    event CreateBidEv(uint256 tokenId, uint256 bidPrice, address owner);
    event AcceptBidEv(uint256 tokenId, address buyer);

    /*///////////////////////////////////////////////////////////////
                                  ERRORS
    //////////////////////////////////////////////////////////////*/

    error Percentage0to100();
    error ClosedMarket();
    error InactiveListing();
    error InsufficientValue();
    error InvalidOwner();
    error OnlyEmergency();
    error Unauthorized();
    error BidAlreadyExist();
    error BidDoesntExist();
    error OnlyInEmergency();
    error CantPlaceBidOnOwnBlueprint();

    constructor(
        address _NFTAddress,
        address _wETH,
        uint256 _marketFee
    ) {
        if (_marketFee > 100) revert Percentage0to100();
        owner = msg.sender;
        nftContract = _NFTAddress;
        marketFeePercent = _marketFee;
        wETH = _wETH;
    
    }
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
        emit OwnerUpdated(_newOwner);
    }

    function setNFTContract(address _newNFTcontract) external onlyOwner {
        nftContract = _newNFTcontract;
        
    }

    function withdrawableBalance() public view returns (uint256 value) { 
        return marketCut;
    }

    function withdraw() external onlyOwner {
        uint balance = marketCut;
        marketCut = 0;
        IERC20(wETH).transfer(msg.sender,balance);    
    }

    /*///////////////////////////////////////////////////////////////
                      MARKET MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function openMarket() external onlyOwner {
        isMarketOpen = true;
    }

    function closeMarket() external onlyOwner {
        isMarketOpen = false;
    }

    function allowEmergencyDelisting() external onlyOwner {
        emergencyDelisting = true;
    }

    function adjustFees(uint256 newMarketFee) external onlyOwner {
        if (newMarketFee > 100) revert Percentage0to100();
        marketFeePercent = newMarketFee;
    }

    function emergencyDelist(uint256 _tokenId) external {
        if(!emergencyDelisting || isMarketOpen) revert OnlyInEmergency();
        Listing memory listing = listings[_tokenId];
        delete  listings[_tokenId];
        IERC721(nftContract).transferFrom(address(this), listing.owner, _tokenId);
        emit CancelListingEv(_tokenId);
    }

    /*///////////////////////////////////////////////////////////////
                      LISTING WRITE OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function addListing(
        uint256 _tokenId,
        uint256 _price
    ) external {
        if (!isMarketOpen) revert ClosedMarket();

        //@dev no other checks since transferFrom will fail
        listings[_tokenId] = Listing( msg.sender, true,_price);
        IERC721(nftContract).transferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
        emit AddListingEv( _tokenId, _price);
    
    }

    function updateListing(uint256 _tokenId, uint256 _price) external {
        if (!isMarketOpen) revert ClosedMarket();
        if (!listings[_tokenId].active) revert InactiveListing();
        if (listings[_tokenId].owner != msg.sender) revert InvalidOwner();
        listings[_tokenId].price = _price;
        emit UpdateListingEv(_tokenId, _price);
    }

    function cancelListing(uint256 _tokenId) external {
        if (!isMarketOpen) revert ClosedMarket();
        Listing memory listing = listings[_tokenId];
        if (!listing.active) revert InactiveListing();
        if (listing.owner != msg.sender) revert InvalidOwner();
        delete listings[_tokenId];
        IERC721(nftContract).transferFrom(
            address(this),
            listing.owner,
            _tokenId
        );
        emit CancelListingEv(_tokenId);
    }

    function cancelMultipleListings(uint256[] calldata _tokenIds) external {
        if (!isMarketOpen) revert ClosedMarket();
        for (uint256 index = 0; index < _tokenIds.length; ++index) {
            Listing memory listing = listings[_tokenIds[index]];
            if (!listing.active) revert InactiveListing();
            if (listing.owner != msg.sender) revert InvalidOwner();
            delete listings[_tokenIds[index]];
            IERC721(nftContract).transferFrom(
                address(this),
                listing.owner,
                _tokenIds[index]
            );
            emit CancelListingEv(_tokenIds[index]);
        }
    }

    function fulfillListing(uint256 _tokenId) external {
        if (!isMarketOpen) revert ClosedMarket();
        Listing memory listing = listings[_tokenId];
        if (!listing.active) revert InactiveListing();
        if (msg.sender == listing.owner) revert InvalidOwner(); // can not fulfill your own listing
        if (IERC20(wETH).balanceOf(msg.sender) < listing.price) revert InsufficientValue(); // TODO: this check might be removed since it already fails due to WEHT contract
        delete listings[_tokenId];
        marketCut += (listing.price * marketFeePercent) / 100; 
        IERC20(wETH).transferFrom(msg.sender, listing.owner, listing.price - (listing.price * marketFeePercent) / 100); 
        IERC20(wETH).transferFrom(msg.sender, address(this), (listing.price * marketFeePercent) / 100);   
      
        IERC721(nftContract).transferFrom(
            address(this),
            msg.sender,
            _tokenId
        );
        emit FulfillListingEv(_tokenId, listing.price);
    }

    function fullfillMultipleListings(uint256[] calldata _tokenIds) external {
        if (!isMarketOpen) revert ClosedMarket();
        for (uint256 index = 0; index < _tokenIds.length; ++index) {
            uint tokenId = _tokenIds[index];
            Listing memory listing = listings[tokenId];
            if (msg.sender == listing.owner) revert InvalidOwner();
            if (!listing.active) revert InactiveListing();
            delete listings[tokenId];
            marketCut += (listing.price * marketFeePercent) / 100; 
            IERC20(wETH).transferFrom(msg.sender, listing.owner, listing.price - (listing.price * marketFeePercent) / 100);
            IERC20(wETH).transferFrom(msg.sender, address(this), (listing.price * marketFeePercent) / 100);   
            IERC721(nftContract).transferFrom(address(this),msg.sender,tokenId);
            emit FulfillListingEv(tokenId,listing.price);
  
        }
    }

    /*///////////////////////////////////////////////////////////////
                      BIDDING WRITE OPERATIONS
    //////////////////////////////////////////////////////////////*/

        
    function placeBid(uint256 tokenId, uint amount) external {
        if (!isMarketOpen) revert ClosedMarket();
        address tokenOwner = getTokenOwner(tokenId); 
        if(msg.sender == tokenOwner) { revert CantPlaceBidOnOwnBlueprint();}
        if (IERC20(wETH).balanceOf(msg.sender) < amount) revert InsufficientValue(); // TODO: this check might be removed since it already fails due to WEHT contract
        if(bids[tokenId][msg.sender].active) revert BidAlreadyExist();
        IERC20(wETH).transferFrom(msg.sender, address(this), amount);             
        bids[tokenId][msg.sender]= Bid(amount, true); 
        emit CreateBidEv(tokenId,amount,tokenOwner);
    }

    function cancelBid(uint tokenId) external {
        if (!isMarketOpen) revert ClosedMarket();
        if (!bids[tokenId][msg.sender].active) revert BidDoesntExist();
        uint256 bidAmount = bids[tokenId][msg.sender].bidPrice;
        delete bids[tokenId][msg.sender];
        IERC20(wETH).transfer(msg.sender, bidAmount);
        emit CancelBidEv(tokenId); 

    }
    
    function updateBid(uint tokenId, uint newPrice) external { 
        if (!isMarketOpen) revert ClosedMarket();
        if(!bids[tokenId][msg.sender].active) revert BidDoesntExist(); // owner can never place a bid on its own bids so no need to check here again
        uint currentPrice = bids[tokenId][msg.sender].bidPrice;
        if(currentPrice > newPrice){
            uint diff = currentPrice - newPrice;
            IERC20(wETH).transfer(msg.sender, diff);
            bids[tokenId][msg.sender].bidPrice = newPrice; 
        }
        else if (newPrice > currentPrice){
            uint diff = newPrice - currentPrice;
            IERC20(wETH).transferFrom(msg.sender, address(this), diff);
            bids[tokenId][msg.sender].bidPrice = newPrice; 
        }
        emit UpdateBidEv(tokenId,newPrice);

    }

    function acceptBid(uint tokenId, address buyer) external {
        if (!isMarketOpen) revert ClosedMarket();
        address tokenOwner = getTokenOwner(tokenId);
        if(msg.sender != tokenOwner) revert InvalidOwner();
        if(!bids[tokenId][buyer].active) revert BidDoesntExist();
        uint256 bidAmount = bids[tokenId][buyer].bidPrice;
        delete bids[tokenId][buyer];
        uint256 market_cut = (bidAmount * marketFeePercent) / 100;
        uint256 seller_cut = bidAmount - market_cut;
        marketCut += market_cut; 

        if(listings[tokenId].active){
            delete listings[tokenId];
            IERC721(nftContract).transferFrom(address(this), buyer, tokenId);
            emit CancelListingEv(tokenId);
        }
        else {
            IERC721(nftContract).transferFrom(tokenOwner, buyer, tokenId);
        }

        IERC20(wETH).transfer(tokenOwner, seller_cut); //remaining is left here
        emit AcceptBidEv(tokenId,buyer); 
    }
    
    function cancelBidsOnBurnedTokenIds(address[] calldata bidders, uint tokenId) external{
        if(IERC721(nftContract).ownerOf(tokenId) == address(0)){
            for (uint256 index = 0; index < bidders.length; ++index) {
                if(bids[tokenId][bidders[index]].active){
                    uint repay = bids[tokenId][bidders[index]].bidPrice;
                    delete bids[tokenId][bidders[index]];
                    IERC20(wETH).transfer(bidders[index],repay);
                    emit CancelBidEv(tokenId);
                }
            }
        }
    }

    function multiTransfer(address to, uint[] calldata tokenIds) external {
        for (uint256 index = 0; index < tokenIds.length; ++index) {
            IERC721(nftContract).transferFrom(msg.sender, to, tokenIds[index]);
        }
    }

    

    /*///////////////////////////////////////////////////////////////
                      READ OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function getListings(uint256 from, uint256 length)
        external
        view
        returns (Listing[] memory listing)
    {
        unchecked {
            Listing[] memory _listings = new Listing[](length);
            //slither-disable-next-line uninitialized-local
            for (uint256 i; i < length; ++i) {
                _listings[i] = listings[from + i];
            }
            return _listings;
        }
    }
    function getTokenOwner(uint256 _tokenId) public view returns (address){
        if (listings[_tokenId].active){
            return listings[_tokenId].owner;
        } else {
            return IERC721(nftContract).ownerOf(_tokenId);
        }
    }
    

    /*///////////////////////////////////////////////////////////////
                    END OF TO BE REMOVED IN PRODUCTION
    //////////////////////////////////////////////////////////////*/

}