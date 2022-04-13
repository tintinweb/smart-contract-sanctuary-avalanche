/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-12
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// File: contracts/baseAuction.sol



pragma solidity ^0.8.7;



contract Auction {

    using SafeMath for uint256;

    address public manager; // The address of the owner

    uint256 public endTime; // Timestamp of the end of the auction (in seconds)

    uint256 public startTime; // The block timestamp which marks the start of the auction

    uint public maxBid; // The maximum bid

    address public maxBidder; // The address of the maximum bidder

    address public creator; // The address of the auction creator

    Bid[] public bids; // The bids made by the bidders

    uint public tokenId; // The id of the token

    bool public isCancelled; // If the the auction is cancelled

    bool public isDirectBuy; // True if the auction ended due to direct buy

    bool public reserveMet; // True if the reserve has been met

    uint public minIncrement; // The minimum increment for the bid

    uint public directBuyPrice; // The price for a direct buy

    uint public startPrice; // The starting price for the auction

    address public nftAddress;  // The address of the NFT contract

    // 2% fee for auction manager

    uint public fee = 2;

    IERC721 _nft; // The NFT token

    bool public buyNow; // True if the auction can be purchased directly



    struct Info{

        bool _buyNow;

        bool _reserveMet;

        uint256 _directBuy;

        address _creator;

        uint256 _highestBid;

        address _highestBidder;

        uint256 _tokenIds;

        uint256 _endTime;

        uint256 _startPrice;

        uint256 _minInc;

        // Auction State

        uint256 _state;

    }



    enum AuctionState { 

        OPEN,

        CANCELLED,

        ENDED,

        DIRECT_BUY

    }



    struct Bid { // A bid on an auction

        address sender;

        uint256 bid;

    }



    // Auction constructor

    constructor(address _creator,uint _endTime, bool _buyNow, uint _minIncrement,uint _directBuyPrice, uint _startPrice,address _nftAddress,uint _tokenId){

        

        creator = _creator; // The address of the auction creator

        manager = msg.sender; // The address of the manager

        buyNow = _buyNow; // True if the auction can be purchased directly

        reserveMet = false; // The auction has not met the reserve

        endTime = block.timestamp +  _endTime; // The timestamp which marks the end of the auction (now + 30 days = 30 days from now)

        startTime = block.timestamp; // The timestamp which marks the start of the auction

        minIncrement = _minIncrement; // The minimum increment for the bid

        directBuyPrice = _directBuyPrice; // The price for a direct buy

        startPrice = _startPrice; // The starting price for the auction

        _nft = IERC721(_nftAddress); // The address of the nft token

        nftAddress = _nftAddress;

        tokenId = _tokenId; // The id of the token

        maxBidder = _creator; // Setting the maxBidder to auction creator.



    }



    // Returns a list of all bids and addresses

    function allBids()

        external

        view

        returns (address[] memory, uint256[] memory)

    {

        address[] memory addrs = new address[](bids.length);

        uint256[] memory bidPrice = new uint256[](bids.length);

        for (uint256 i = 0; i < bids.length; i++) {

            addrs[i] = bids[i].sender;

            bidPrice[i] = bids[i].bid;

        }

        return (addrs, bidPrice);

    }



    // get info about the auction

    function getInfo() external view returns (Info memory) {

        Info memory info = Info(

            buyNow,

            reserveMet,

            directBuyPrice,

            creator,

            maxBid,

            maxBidder,

            tokenId,

            endTime,

            startPrice,

            minIncrement,

            uint256(getAuctionState())



        );

        return info;

    }



    // Place a bid on the auction

    function placeBid() payable external returns(bool){

        require(msg.sender != creator, "Can't bid on your own item"); // The auction creator can not place a bid

        require(getAuctionState() == AuctionState.OPEN, "Auction has closed"); // The auction must be open

        require(msg.value >= startPrice, "Bid must be at least the starting price"); // The bid must be higher than the starting price

        require(msg.value >= maxBid + minIncrement || msg.value == directBuyPrice, "Bid too low, increase increment amount or Direct Buy"); // The bid must be higher than the current max bid plus the minimum increment or the bid must be equal to the direct buy price

        address lastHightestBidder = maxBidder; // The address of the last highest bidder

        uint256 lastHighestBid = maxBid; // The last highest bid

        maxBid = msg.value; // The new highest bid

        maxBidder = msg.sender; // The address of the new highest bidder

        if (msg.value >= directBuyPrice){ // If the bid is higher than the direct buy price

            if (buyNow){ // If the auction can be purchased directly

                isDirectBuy = true; // The auction has ended

                withdrawToken(); // Withdraw the token

                withdrawFunds(); // Withdraw the funds

            }

            else{ reserveMet = true; } // The reserve price has been met.

        }

        bids.push(Bid(msg.sender,msg.value)); // Add the new bid to the list of bids



        if(lastHighestBid != 0){ // if there is a bid

            payable(lastHightestBidder).transfer(lastHighestBid); // refund the previous bid to the previous highest bidder

        }

    

        emit NewBid(msg.sender,msg.value); // emit a new bid event

        

        return true; // The bid was placed successfully

    }



    // Withdraw the token after the auction is over

    function withdrawToken() internal returns(bool){

        require(getAuctionState() == AuctionState.ENDED || getAuctionState() == AuctionState.DIRECT_BUY); // The auction must be ended by either a direct buy or timeout

        _nft.transferFrom(address(this), maxBidder, tokenId); // Transfer the token to the highest bidder

        emit WithdrawToken(maxBidder); // Emit a withdraw token event

        return true;

    }



    // Withdraw the funds after the auction is over

    function withdrawFunds() internal returns(bool){ 

        require(getAuctionState() == AuctionState.ENDED || getAuctionState() == AuctionState.DIRECT_BUY); // The auction must be ended by either a direct buy or timeout

        // get the fee percentage from the manager

        uint256 _fee = maxBid.mul(fee).div(100);

        payable(manager).transfer(_fee); // Transfer the fee to the manager

        payable(creator).transfer(maxBid - _fee); // Transfers funds to the creator

        emit WithdrawFunds(msg.sender,maxBid); // Emit a withdraw funds event

        return true;

    } 



    function cancelAuction() external returns(bool){ // Cancel the auction

        require(msg.sender == creator); // Only the auction creator can cancel the auction

        require(getAuctionState() == AuctionState.OPEN); // The auction must be open

        isCancelled = true; // The auction has been cancelled

        if(maxBid != 0){ // If there is a bid return the bid to the highest bidder

            payable(maxBidder).transfer(maxBid);

            }

        _nft.transferFrom(address(this), creator, tokenId); // Transfer the NFT token to the auction creator

        emit AuctionCanceled(); // Emit Auction Canceled event

        return true;

    } 



    // Get the auction state

    function getAuctionState() public view returns(AuctionState) {

        if(isCancelled) return AuctionState.CANCELLED; // If the auction is cancelled return CANCELLED

        if(isDirectBuy) return AuctionState.DIRECT_BUY; // If the auction is ended by a direct buy return DIRECT_BUY

        if(block.timestamp >= endTime) return AuctionState.ENDED; // The auction is over if the block timestamp is greater than the end timestamp, return ENDED

        return AuctionState.OPEN; // Otherwise return OPEN

    } 



    function endAuction() external returns(bool){ // End the auction

        require(msg.sender == manager || msg.sender == creator, "Manager or Creator only"); // Only the auction creator can end the auction

        require(getAuctionState() == AuctionState.ENDED, "Auction must be ended"); // The auction must be ended

        if (!reserveMet){ // If the reserve has not been met

            if(maxBid != 0){ // If there is a bid return the bid to the highest bidder

                payable(maxBidder).transfer(maxBid);

            }

            _nft.transferFrom(address(this), creator, tokenId); // Transfer the NFT token to the auction creator

            emit AuctionCanceled(); // Emit Auction Canceled event

        }

        else{ // If the reserve has been met

            withdrawToken(); // Withdraw the token

            withdrawFunds(); // Withdraw the funds

        }

        return true;

    }



    // lower reserve

    function lowerReserve(uint _reserve) external returns(bool)

    {



    }



    event NewBid(address bidder, uint bid); // A new bid was placed

    event WithdrawToken(address withdrawer); // The auction winner withdrawed the token

    event WithdrawFunds(address withdrawer, uint256 amount); // The auction owner withdrawed the funds

    event AuctionCanceled(); // The auction was cancelled

}
// File: contracts/baseManager.sol



pragma solidity ^0.8.7;








contract AuctionManager {

    using SafeMath for uint;

    uint _auctionIdCounter; // auction Id counter

    address private owner; // The address of the owner

    mapping(uint => Auction) private auctions; // auctions

    mapping(address => uint) private collectionSize; // auction info

    mapping (address => mapping (uint => bool) ) private knownTokens; // known tokens

    mapping (address => mapping (uint => uint) ) private tokensListed; 

    mapping (address => mapping (uint => address) ) private NFTcollections; 

    uint collectionID; // collection ID

// constructor

    constructor() {

        owner = msg.sender;

        _auctionIdCounter = 0;

    }

    // create an auction //TODO: ensure only the active item mapping can sell

    function createAuction(uint _endTime, bool _buyNow, uint _minIncrement, uint _directBuyPrice,uint _startPrice,address _nftAddress,uint _tokenId) external returns (bool){

        require(_directBuyPrice > 0); // direct buy price must be greater than 0

        require(_startPrice <= _directBuyPrice); // start price is smaller than direct buy price

        require(_endTime > 5 minutes); // end time must be greater than 5 minutes (setting it to 5 minutes for testing you can set it to 1 days or anything you would like)

        Auction auction = new Auction(msg.sender, _endTime, _buyNow, _minIncrement, _directBuyPrice, _startPrice, _nftAddress, _tokenId); // create the auction

        auctions[_auctionIdCounter] = auction; // add the auction to the mapping

        NFTcollections[_nftAddress][_tokenId] = address(auction); // add the auction to the collection

        _auctionIdCounter++; // increment the counter

        uint _collectionSize = collectionSize[_nftAddress];

        if (knownTokens[_nftAddress][_tokenId] == false) {

            knownTokens[_nftAddress][_tokenId] = true;

            _collectionSize++;

            collectionSize[_nftAddress] = _collectionSize;

            tokensListed[_nftAddress][_collectionSize] = _tokenId;

        }

        // token transfer to the auction

        IERC721 _nftToken = IERC721(_nftAddress); // get the nft token

        _nftToken.transferFrom(msg.sender, address(auction), _tokenId); // transfer the token to the auction

        return true;

    }



    // Return a list of all auctions

    function getAuctions() external view returns(address[] memory _auctions) {

        _auctions = new address[](_auctionIdCounter); // create an array of size equal to the current value of the counter

        for(uint i = 0; i < _auctionIdCounter; i++) { // for each auction

            _auctions[i] = address(auctions[i]); // add the address of the auction to the array

        }

        return _auctions; // return the array

    }

        // get collection info for token id

    function getOneNFT(address _NFT, uint _tokenId) public view returns(address _info) {

        // get auctions for token id

        return NFTcollections[_NFT][_tokenId];

    }

   // get all for sale for collection

    function collectionGetAllForSale(address _NFT) external view returns(address[] memory _info) {

        // get auctions for all token ids

        _info = new address[](collectionSize[_NFT]); // create an array of size equal to the current value of the counter         

        for (uint i = 0; i < collectionSize[_NFT]; i++) { // for each auction

            _info[i] = NFTcollections[_NFT][tokensListed[_NFT][i+1]]; // add the address of the auction to the array  

        }

        return _info; // return the array

    }



    // Return the information of each auction address

    function getAuctionInfo(address _addy)

        public

        view

        returns (

           Auction.Info memory

        )

    {

        return Auction(_addy).getInfo();

    }



    // withdraw funds to owner

    function withdrawFunds(uint _amount) external {

        require(msg.sender == owner, "You are not the Owner"); // only the owner can withdraw funds

        require(_amount >= address(this).balance, "Contract balance too low"); // the amount must be greater than the balance

        payable(owner).transfer(_amount); // transfer the funds to the owner

    }



}