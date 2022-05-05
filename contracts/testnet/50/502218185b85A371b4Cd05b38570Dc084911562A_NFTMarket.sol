pragma solidity ^0.8.0;
// SPDX-License-Identifier: UNLICENSED
import "./DataType.sol";

contract NFTMarket {
    uint256 private constant NOT_LISTED = 0;
    uint256 private constant LISTED = 1;
    uint256 private constant NEED_REPLACE = 2;

    address private _owner;
    bool public paused = false;
    uint256 public _auctionIdCounter;
    uint256 public marketFee = 5;
    bool public pausedAuctionFunctionality = true;

    mapping(uint256 => Auction) public auctions;
    mapping(address => ItemForSale[]) public _saleItems;

    event CreateAuction(
        address indexed creator,
        address indexed collection,
        uint256 _tokenId,
        uint256 _endTime,
        uint256 _minIncrement,
        uint256 _directBuyPrice,
        uint256 _startPrice
    );
    event ListForSale(
        address indexed seller,
        address indexed collection,
        uint256 tokenId,
        uint256 price
    );
    event UnlistForSale(
        address indexed seller,
        address indexed collection,
        uint256 tokenId
    );
    event Buy(
        address indexed buyer,
        address indexed collection,
        uint256 tokenId
    );
    event ChangePrice(
        address indexed collection,
        uint256 tokenId,
        uint256 price
    );

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    function createAuction(
        uint256 _endTime,
        uint256 _minIncrement,
        uint256 _directBuyPrice,
        uint256 _startPrice,
        address _nftAddress,
        uint256 _tokenId
    ) external returns (bool) {
        require(paused == false, "Contract Paused");
        require(
            pausedAuctionFunctionality == false,
            "Auction Functionality Paused"
        );
        require(_directBuyPrice > 0);
        require(_startPrice < _directBuyPrice);
        require(_endTime > 5 minutes);
        require(
            getIndexOfItemForSale(_nftAddress, _tokenId) == 0,
            "Item is already listed for sell"
        );

        uint256 auctionId = _auctionIdCounter;
        _auctionIdCounter++;
        Auction auction = new Auction(
            msg.sender,
            _endTime,
            _minIncrement,
            _directBuyPrice,
            _startPrice,
            _nftAddress,
            _tokenId
        );
        IERC721 _nftToken = IERC721(_nftAddress);
        _nftToken.transferFrom(msg.sender, address(auction), _tokenId);
        auctions[auctionId] = auction;

        emit CreateAuction(
            msg.sender,
            _nftAddress,
            _tokenId,
            _endTime,
            _minIncrement,
            _directBuyPrice,
            _startPrice
        );
        return true;
    }

    function getAuctions() external view returns (address[] memory _auctions) {
        _auctions = new address[](_auctionIdCounter);
        for (uint256 i = 0; i < _auctionIdCounter; i++) {
            _auctions[i] = address(auctions[i]);
        }
        return _auctions;
    }

    function getAuctionInfo(address[] calldata _auctionsList)
        external
        view
        returns (
            uint256[] memory directBuy,
            address[] memory owner,
            uint256[] memory highestBid,
            uint256[] memory tokenIds,
            uint256[] memory endTime,
            uint256[] memory startPrice,
            uint256[] memory auctionState
        )
    {
        directBuy = new uint256[](_auctionsList.length);
        owner = new address[](_auctionsList.length);
        highestBid = new uint256[](_auctionsList.length);
        tokenIds = new uint256[](_auctionsList.length);
        endTime = new uint256[](_auctionsList.length);
        startPrice = new uint256[](_auctionsList.length);
        auctionState = new uint256[](_auctionsList.length);

        for (uint256 i = 0; i < _auctionsList.length; i++) {
            directBuy[i] = Auction(auctions[i]).directBuyPrice();
            owner[i] = Auction(auctions[i]).creator();
            highestBid[i] = Auction(auctions[i]).maxBid();
            tokenIds[i] = Auction(auctions[i]).tokenId();
            endTime[i] = Auction(auctions[i]).endTime();
            startPrice[i] = Auction(auctions[i]).startPrice();
            auctionState[i] = uint256(Auction(auctions[i]).getAuctionState());
        }

        return (
            directBuy,
            owner,
            highestBid,
            tokenIds,
            endTime,
            startPrice,
            auctionState
        );
    }

    function listForSale(
        address collection,
        uint256 tokenId,
        uint256 price
    ) external returns (bool) {
        require(paused == false, "Contract Paused");
        require(
            itemListed(collection, tokenId) == NOT_LISTED ||
                itemListed(collection, tokenId) == NEED_REPLACE,
            "Item already listed!"
        );
        require(price > 0);
        require(collection != address(0));
        require(
            IERC721(collection).ownerOf(tokenId) == msg.sender,
            "not allowed to list this item for sale"
        );

        /** 
            We check if item listed is being re-listed so that it can be replaced.
            Loop through items on sale and re-order the items in order to maintain
            their listed order. Then we remove the last element in the array.
        */
        if (itemListed(collection, tokenId) == NEED_REPLACE) {
            for (uint256 i = 0; i < _saleItems[collection].length; i++) {
                if (_saleItems[collection][i].tokenId == tokenId) {
                    for (
                        uint256 j = i;
                        j < _saleItems[collection].length - 1;
                        j++
                    ) {
                        _saleItems[collection][j] = _saleItems[collection][
                            j + 1
                        ];
                    }

                    _saleItems[collection].pop();
                    break;
                }
            }
        }

        ItemForSale memory item = ItemForSale({
            collection: collection,
            tokenId: tokenId,
            price: price,
            seller: msg.sender
        });
        _saleItems[collection].push(item);

        emit ListForSale(msg.sender, collection, tokenId, price);
        return true;
    }

    function unlistForSale(address collection, uint256 tokenId)
        public
        returns (bool)
    {
        require(collection != address(0));
        require(
            (IERC721(collection).ownerOf(tokenId) == msg.sender) ||
                collection == msg.sender ||
                _owner == msg.sender,
            "not allowed to unlist this item"
        );
        _unlistForSale(collection, tokenId);

        emit UnlistForSale(msg.sender, collection, tokenId);
        return true;
    }

    function unlistForSale(
        address sender,
        address collection,
        uint256 tokenId
    ) public returns (bool) {
        require(collection != address(0));
        require(
            (IERC721(collection).ownerOf(tokenId) == sender) ||
                collection == msg.sender ||
                _owner == msg.sender,
            "not allowed to unlist this item"
        );
        _unlistForSale(collection, tokenId);

        emit UnlistForSale(msg.sender, collection, tokenId);
        return true;
    }

    function _unlistForSale(address collection, uint256 tokenId) internal {
        require(collection != address(0));
        uint256 length = _saleItems[collection].length;
        for (uint256 i = 0; i < length; i++) {
            if (_saleItems[collection][i].tokenId == tokenId) {
                _saleItems[collection][i] = _saleItems[collection][length - 1];
                _saleItems[collection].pop();
                break;
            }
        }
    }

    function getIndexOfItemForSale(address collection, uint256 tokenId)
        private
        view
        returns (uint256)
    {
        uint256 id = 0;
        for (uint256 i = 0; i < _saleItems[collection].length; i++) {
            if (_saleItems[collection][i].tokenId == tokenId) {
                id = i + 1;
                break;
            }
        }
        return id;
    }

    function itemListed(address collection, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        for (uint256 i = 0; i < _saleItems[collection].length; i++) {
            if (_saleItems[collection][i].tokenId == tokenId) {
                if (
                    IERC721(collection).ownerOf(tokenId) ==
                    _saleItems[collection][i].seller
                ) {
                    return LISTED;
                } else {
                    return NEED_REPLACE;
                }
            }
        }
        return NOT_LISTED;
    }

    function buy(address collection, uint256 tokenId)
        external
        payable
        returns (bool)
    {
        require(msg.sender != address(0), "buyer address cannot be zero");
        require(paused == false, "Contract Paused");
        require(
            IERC721(collection).ownerOf(tokenId) != msg.sender,
            "token already exists in your bag"
        );
        uint256 index = getIndexOfItemForSale(collection, tokenId);
        require(index != 0, "cannot find item for sale");
        require(
            msg.value >= _saleItems[collection][index - 1].price,
            "not enough money to buy"
        );
        require(
            IERC721(collection).ownerOf(tokenId) ==
                _saleItems[collection][index - 1].seller,
            "owner and seller don't match, purchase not allowed!"
        );
        address currentOwner = IERC721(collection).ownerOf(tokenId);
        _unlistForSale(collection, tokenId);
        IERC721(collection).transferFrom(currentOwner, msg.sender, tokenId);
        uint256 value = msg.value - calcMarketFee(msg.value);
        payable(currentOwner).transfer(value);
        emit Buy(msg.sender, collection, tokenId);
        return true;
    }

    function changePrice(
        address collection,
        uint256 tokenId,
        uint256 price
    ) external returns (bool) {
        require(msg.sender != address(0), "sender address cannot be zero");
        require(
            IERC721(collection).ownerOf(tokenId) == msg.sender,
            "You must be the owner of the token"
        );
        uint256 index = getIndexOfItemForSale(collection, tokenId);
        require(index != 0, "cannot find item for sale");
        _saleItems[collection][index - 1].price = price;

        emit ChangePrice(collection, tokenId, price);
        return true;
    }

    function calcMarketFee(uint256 value) private view returns (uint256) {
        return (value * marketFee) / 100;
    }

    function getItemsForSale(address collection)
        external
        view
        returns (ItemForSale[] memory)
    {
        require(collection != address(0));

        ItemForSale[] memory items = _saleItems[collection];
        ItemForSale[] memory ret = new ItemForSale[](
            getSaleItemCnt(collection)
        );
        uint256 k = 0;
        for (uint256 i = 0; i < items.length; i++) {
            try IERC721(collection).ownerOf(items[i].tokenId) returns (
                address tokenOwner
            ) {
                if (tokenOwner == items[i].seller) {
                    ret[k] = items[i];
                    k++;
                }
            } catch {}
        }

        return ret;
    }

    function getSaleItemCnt(address collection) private view returns (uint256) {
        require(collection != address(0));

        ItemForSale[] memory items = _saleItems[collection];
        uint256 ret = 0;
        for (uint256 i = 0; i < items.length; i++) {
            try IERC721(collection).ownerOf(items[i].tokenId) returns (
                address tokenOwner
            ) {
                if (tokenOwner == items[i].seller) {
                    ret++;
                }
            } catch {}
        }

        return ret;
    }

    // For future-use if necessary
    // We'll get single items for sale in case the "getItemsForSale" returns an array too big
    function getSingleItemForSale(address collection, uint256 index)
        external
        view
        returns (ItemForSale memory)
    {
        require(collection != address(0));
        if (
            IERC721(collection).ownerOf(index) ==
            _saleItems[collection][index].seller
        ) {
            return _saleItems[collection][index];
        } else {
            ItemForSale memory ret = ItemForSale({
                collection: address(0),
                tokenId: 0,
                price: 0,
                seller: address(0)
            });
            return ret;
        }
    }

    // For future-use if necessary (get saleitems length to aid in indexing in above function)
    function getTotalItemsForSale(address collection)
        external
        view
        returns (uint256)
    {
        return _saleItems[collection].length;
    }

    function withdraw(address _to) external onlyOwner {
        (bool success, ) = address(_to).call{value: address(this).balance}("");
        require(success == true);
    }

    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function pauseAuctionFunctionality(bool _paused) public onlyOwner {
        pausedAuctionFunctionality = _paused;
    }
}

pragma solidity ^0.8.1;
// SPDX-License-Identifier: UNLICENSED
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct ItemForSale {
    address collection;
    uint256 tokenId;
    uint256 price;
    address seller;
}

contract Auction {
    using SafeMath for uint256;
    uint256 public endTime;
    uint256 public startTime;
    uint256 public maxBid;
    address public maxBidder;
    address public creator;
    Bid[] public bids;
    uint256 public tokenId;
    bool public isCancelled;
    bool public isDirectBuy;
    uint256 public minIncrement;
    uint256 public directBuyPrice;
    uint256 public startPrice;
    address public nftAddress;
    IERC721 _nft;

    enum AuctionState {
        OPEN,
        CANCELLED,
        ENDED,
        DIRECT_BUY
    }

    struct Bid {
        // A bid on an auction
        address sender;
        uint256 bid;
    }

    // Auction constructor
    constructor(
        address _creator,
        uint256 _endTime,
        uint256 _minIncrement,
        uint256 _directBuyPrice,
        uint256 _startPrice,
        address _nftAddress,
        uint256 _tokenId
    ) {
        creator = _creator;
        endTime = block.timestamp + _endTime;
        startTime = block.timestamp;
        minIncrement = _minIncrement;
        directBuyPrice = _directBuyPrice;
        startPrice = _startPrice;
        _nft = IERC721(_nftAddress);
        nftAddress = _nftAddress;
        tokenId = _tokenId;
        maxBidder = _creator;
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

    // Place a bid on the auction
    function placeBid() external payable returns (bool) {
        require(msg.sender != creator);
        require(getAuctionState() == AuctionState.OPEN);
        require(msg.value > startPrice);
        require(msg.value > maxBid + minIncrement);

        address lastHightestBidder = maxBidder;
        uint256 lastHighestBid = maxBid;
        maxBid = msg.value;
        maxBidder = msg.sender;
        if (msg.value >= directBuyPrice) {
            isDirectBuy = true;
        }
        bids.push(Bid(msg.sender, msg.value));

        if (lastHighestBid != 0) {
            // if there is a bid
            payable(lastHightestBidder).transfer(lastHighestBid);
        }

        emit NewBid(msg.sender, msg.value);

        return true;
    }

    // Withdraw the token after the auction is over
    function withdrawToken() external {
        require(
            getAuctionState() == AuctionState.ENDED ||
                getAuctionState() == AuctionState.DIRECT_BUY
        );
        require(msg.sender == maxBidder);
        _nft.transferFrom(address(this), maxBidder, tokenId);
        emit WithdrawToken(maxBidder);
    }

    // Withdraw the funds after the auction is over
    function withdrawFunds() external {
        require(
            getAuctionState() == AuctionState.ENDED ||
                getAuctionState() == AuctionState.DIRECT_BUY
        );
        require(msg.sender == creator);
        payable(creator).transfer(maxBid);
        emit WithdrawFunds(msg.sender, maxBid);
    }

    function cancelAuction() external returns (bool) {
        // Cancel the auction
        require(msg.sender == creator);
        require(getAuctionState() == AuctionState.OPEN);
        require(maxBid == 0);
        isCancelled = true;
        _nft.transferFrom(address(this), creator, tokenId);
        emit AuctionCanceled();
        return true;
    }

    // Get the auction state
    function getAuctionState() public view returns (AuctionState) {
        if (isCancelled) return AuctionState.CANCELLED;
        if (isDirectBuy) return AuctionState.DIRECT_BUY;
        if (block.timestamp >= endTime) return AuctionState.ENDED;
        return AuctionState.OPEN;
    }

    event NewBid(address bidder, uint256 bid);
    event WithdrawToken(address withdrawer);
    event WithdrawFunds(address withdrawer, uint256 amount);
    event AuctionCanceled();
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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