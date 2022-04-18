/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-17
*/

/** 
 *  SourceUnit: /Users/ethan/Documents/GitHub/avalanche-smart-contract-quickstart/contracts/NFTMarket.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

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




/** 
 *  SourceUnit: /Users/ethan/Documents/GitHub/avalanche-smart-contract-quickstart/contracts/NFTMarket.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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




/** 
 *  SourceUnit: /Users/ethan/Documents/GitHub/avalanche-smart-contract-quickstart/contracts/NFTMarket.sol
*/
            
//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

////import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

//Todo: 时限拍卖  ERC20交易

interface INFTMarket {
    event AskCreated(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price,
        address indexed paymentToken
    );

    event AskUpdated(
        bytes32 indexed askID,
        uint256 price,
        address indexed paymentToken
    );

    event AskCanceled(address indexed nft, uint256 indexed tokenID);

    event AskAccepted(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price,
        address indexed paymentToken
    );

    event BidCreated(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price,
        address indexed buyer
    );

    event BidCanceled(bytes32 indexed askID, address indexed buyer);

    event BidAccepted(
        address indexed nft,
        uint256 indexed tokenID,
        uint256 price
    );

    struct Ask {
        bool exists;
        address nft;
        uint256 tokenID;
        address seller;
        uint256 price;
        address paymentToken;
        uint256 deadline;
    }

    struct Bid {
        bool exists;
        address buyer;
        uint256 price;
    }

    function createAsk(
        IERC721[] calldata nft,
        uint256[] calldata tokenID,
        uint256[] calldata price,
        address[] calldata paymentToken,
        uint256[] calldata deadline
    ) external;

    // function updateAsk(
    //     bytes32[] calldata askID,
    //     uint256[] calldata price,
    //     address[] calldata paymentToken,
    //     uint256[] calldata deadline
    // ) external;

    function getAsks() external view returns (Ask[] memory);

    function getBids(bytes32[] calldata askID)
        external
        view
        returns (Bid[] memory);

    function createBid(bytes32[] calldata askID, uint256[] calldata price)
        external
        payable;

    function cancelAsk(bytes32[] calldata askID) external;

    function cancelBid(bytes32[] calldata askID) external;

    function acceptAsk(bytes32[] calldata askID) external payable;

    function acceptBid(bytes32[] calldata askID) external;

    function withdraw() external;
}




/** 
 *  SourceUnit: /Users/ethan/Documents/GitHub/avalanche-smart-contract-quickstart/contracts/NFTMarket.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
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




/** 
 *  SourceUnit: /Users/ethan/Documents/GitHub/avalanche-smart-contract-quickstart/contracts/NFTMarket.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


/** 
 *  SourceUnit: /Users/ethan/Documents/GitHub/avalanche-smart-contract-quickstart/contracts/NFTMarket.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8.4;

////import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/utils/Counters.sol";
////import "./interfaces/INFTMarket.sol";

contract NFTMarket is INFTMarket {
    bytes32[] public askIDs;
    mapping(bytes32 => uint256) public askIDIndex;
    mapping(bytes32 => Ask) public asks;
    mapping(bytes32 => Bid) public bids;
    mapping(address => uint256) public balances;

    string constant REVERT_NOT_OWNER = "NFTMarket::not owner";
    string constant REVERT_NOT_APPROVED = "NFTMarket::not approved";
    string constant REVERT_DUPLICATED_ASK = "NFTMarket::duplicated ask";
    string constant REVERT_NOT_A_CREATOR_OF_ASK =
        "NFTMarket::not a creator of the ask";
    string constant REVERT_NOT_A_CREATOR_OF_BID =
        "NFTMarket::not a creator of the bid";
    string constant REVERT_BID_TOO_LOW = "NFTMarket::bid too low";
    string constant REVERT_ASK_DOES_NOT_EXIST = "NFTMarket::ask does not exist";
    string constant REVERT_ASK_NOT_AUCTION = "NFTMarket::ask is not auction";
    string constant REVERT_ASK_EXPIRED = "NFTMarket::ask expired";
    string constant REVERT_BID_DOES_NOT_EXIST = "NFTMarket::bid does not exist";
    string constant REVERT_CANT_ACCEPT_OWN_ASK =
        "NFTMarket::cant accept own ask";
    string constant REVERT_ASK_SELLER_NOT_OWNER =
        "NFTMarket::ask creator not owner";
    string constant REVERT_INSUFFICIENT_ETHER =
        "NFTMarket::insufficient ether sent";
    string constant REVERT_INSUFFICIENT_VALUE = "NFTMarket::insufficient value";
    string constant REVERT_ZERO_BALANCE = "NFTMarket::zero balance";
    string constant REVERT_NOT_DIRECT_SALE = "NFTMarket::not direct sale";

    // =====================================================================

    constructor() {
        // beneficiary = newBeneficiary;
        // admin = msg.sender;
    }

    function getAsks() external view override returns (Ask[] memory) {
        Ask[] memory all = new Ask[](askIDs.length);
        for (uint256 i = 0; i < askIDs.length; i++) {
            all[i] = asks[askIDs[i]];
        }
        return all;
    }

    function getBids(bytes32[] calldata askID)
        external
        view
        override
        returns (Bid[] memory)
    {
        Bid[] memory all = new Bid[](askID.length);
        for (uint256 i = 0; i < askID.length; i++) {
            all[i] = bids[askID[i]];
        }
        return all;
    }

    /// @notice Creates an ask for (`nft`, `tokenID`) tuple for `price`
    /// @dev Creating an ask requires msg.sender to have at least one qty of
    /// (`nft`, `tokenID`).
    /// @param nft     An array of ERC-721 addresses.
    /// @param tokenID Token Ids of the NFTs msg.sender wishes to sell.
    /// @param price   Prices at which the seller is willing to sell the NFTs.
    /// @param paymentToken      ERC20 token Address for payment.
    /// @param deadline      Deadline timestamp for auction, direct sale if 0.
    /// then anyone can accept.
    function createAsk(
        IERC721[] calldata nft,
        uint256[] calldata tokenID,
        uint256[] calldata price,
        address[] calldata paymentToken,
        uint256[] calldata deadline
    ) external override {
        for (uint256 i = 0; i < nft.length; i++) {
            bytes32 askID = keccak256(
                abi.encodePacked(nft[i], tokenID[i], msg.sender)
            );
            require(!asks[askID].exists, REVERT_DUPLICATED_ASK);
            require(nft[i].ownerOf(tokenID[i]) == msg.sender, REVERT_NOT_OWNER);
            require(
                nft[i].getApproved(tokenID[i]) == address(this) ||
                    nft[i].isApprovedForAll(msg.sender, address(this)),
                REVERT_NOT_APPROVED
            );
            // if feecollector extension applied, this ensures math is correct
            require(price[i] > 10_000, "price too low");
            askIDIndex[askID] = askIDs.length;
            askIDs.push(askID);
            // overwristes or creates a new one
            asks[askID] = Ask({
                exists: true,
                nft: address(nft[i]),
                tokenID: tokenID[i],
                seller: msg.sender,
                price: price[i],
                paymentToken: paymentToken[i],
                deadline: deadline[i]
            });

            emit AskCreated({
                nft: address(nft[i]),
                tokenID: tokenID[i],
                price: price[i],
                paymentToken: paymentToken[i]
            });
        }
    }

    /// @notice Creates an ask for (`nft`, `tokenID`) tuple for `price`
    /// @dev Creating an ask requires msg.sender to have at least one qty of
    /// (`nft`, `tokenID`).
    /// @param askID  askID
    /// @param price   Prices at which the seller is willing to sell the NFTs.
    /// @param paymentToken      ERC20 token Address for payment.
    /// @param deadline      Deadline timestamp for auction, direct sale if 0.
    /// then anyone can accept.
    // function updateAsk(
    //     bytes32[] calldata askID,
    //     uint256[] calldata price,
    //     address[] calldata paymentToken,
    //     uint256[] calldata deadline
    // ) external override {
    //     for (uint256 i = 0; i < askID.length; i++) {
    //         Ask memory ask = asks[askID[i]];
    //         require(ask.seller == msg.sender, REVERT_NOT_A_CREATOR_OF_ASK);
    //         // overwristes or creates a new one
    //         asks[askID[i]] = Ask({
    //             exists: true,
    //             nft: ask.nft,
    //             tokenID: ask.tokenID,
    //             seller: msg.sender,
    //             price: price[i],
    //             paymentToken: paymentToken[i],
    //             deadline: deadline[i]
    //         });

    //         emit AskUpdated({
    //             askID: askID[i],
    //             price: price[i],
    //             paymentToken: paymentToken[i]
    //         });
    //     }
    // }

    /// @notice Creates a bid on (`nft`, `tokenID`) tuple for `price`.
    /// @param askID   AskID.
    /// @param price   Prices at which the buyer is willing to buy the NFTs.
    function createBid(bytes32[] calldata askID, uint256[] calldata price)
        external
        payable
        override
    {
        // bidding on own NFTs is possible. But then again, even if we wanted to disallow it,
        // it would not be an effective mechanism, since the agent can bid from his other
        // wallets
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < askID.length; i++) {
            Ask memory ask = asks[askID[i]];
            require(ask.exists, REVERT_ASK_DOES_NOT_EXIST);
            require(ask.deadline > 0, REVERT_ASK_NOT_AUCTION);
            require(block.timestamp < ask.deadline, REVERT_ASK_EXPIRED);
            Bid memory bid = bids[askID[i]];
            // if bid existed, let the prev. creator withdraw their bid. new overwrites
            if (bid.exists) {
                require(price[i] > bid.price, REVERT_BID_TOO_LOW);
                if (ask.paymentToken == address(1)) {
                    balances[bid.buyer] += bid.price;
                    totalPrice += price[i];
                }
            } else {
                require(price[i] >= ask.price, REVERT_BID_TOO_LOW);
            }
            bids[askID[i]] = Bid({
                exists: true,
                buyer: msg.sender,
                price: price[i]
            });

            emit BidCreated({
                nft: ask.nft,
                tokenID: ask.tokenID,
                price: price[i],
                buyer: msg.sender
            });
        }
        require(totalPrice == msg.value, REVERT_INSUFFICIENT_VALUE);
    }

    /// @notice Cancels ask(s) that the seller previously created.
    /// @param askID askIDs
    function cancelAsk(bytes32[] calldata askID) external override {
        for (uint256 i = 0; i < askID.length; i++) {
            Ask memory ask = asks[askID[i]];
            require(ask.exists, REVERT_ASK_DOES_NOT_EXIST);
            require(ask.seller == msg.sender, REVERT_NOT_A_CREATOR_OF_ASK);
            if (ask.deadline > 0) {
                Bid memory bid = bids[askID[i]];
                if (bid.exists) {
                    if (ask.paymentToken == address(1)) {
                        balances[bid.buyer] += bid.price;
                    }
                    delete bids[askID[i]];
                }
            }
            delete asks[askID[i]];
            removeAskID(askID[i]);
            emit AskCanceled({nft: ask.nft, tokenID: ask.tokenID});
        }
    }

    /// @notice Cancels bid(s) that the msg.sender previously created.
    /// @param askID askID
    function cancelBid(bytes32[] calldata askID) external override {
        for (uint256 i = 0; i < askIDs.length; i++) {
            Bid memory bid = bids[askID[i]];
            require(bid.exists, REVERT_BID_DOES_NOT_EXIST);
            require(bid.buyer == msg.sender, REVERT_NOT_A_CREATOR_OF_BID);
            balances[msg.sender] += bid.price;
            delete bids[askID[i]];
            emit BidCanceled({askID: askID[i], buyer: msg.sender});
        }
    }

    /// @notice Seller placed ask(s), you (buyer) are fine with the terms. You accept
    /// their ask by sending the required msg.value and indicating the id of the
    /// token(s) you are purchasing.
    /// @param askID askIDs
    /// asks on.
    function acceptAsk(bytes32[] calldata askID) external payable override {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < askID.length; i++) {
            Ask memory ask = asks[askID[i]];
            require(ask.exists, REVERT_ASK_DOES_NOT_EXIST);
            require(ask.seller != msg.sender, REVERT_CANT_ACCEPT_OWN_ASK);
            require(ask.deadline == 0, REVERT_NOT_DIRECT_SALE);
            IERC721 nft = IERC721(ask.nft);
            require(
                nft.ownerOf(ask.tokenID) == ask.seller,
                REVERT_ASK_SELLER_NOT_OWNER
            );

            if (ask.paymentToken == address(1)) {
                totalPrice += ask.price;
                balances[ask.seller] += _takeFee(ask.price);
            } else {
                IERC20 token = IERC20(ask.paymentToken);
                require(token.transferFrom(msg.sender, ask.seller, ask.price));
            }

            nft.safeTransferFrom(
                ask.seller,
                msg.sender,
                ask.tokenID,
                new bytes(0)
            );

            emit AskAccepted({
                nft: ask.nft,
                tokenID: ask.tokenID,
                price: ask.price,
                paymentToken: ask.paymentToken
            });

            delete asks[askID[i]];
            removeAskID(askID[i]);
        }

        require(totalPrice == msg.value, REVERT_INSUFFICIENT_VALUE);
    }

    /// @notice You are the owner of the NFTs, someone submitted the bids on them.
    /// You accept one or more of these bids.
    /// @param askID Token Ids of the NFTs msg.sender wishes to accept the
    /// bids on.
    function acceptBid(bytes32[] calldata askID) external override {
        uint256 totalPrice = 0;
        for (uint256 i = 0; i < askID.length; i++) {
            Bid memory bid = bids[askID[i]];
            require(bid.exists, REVERT_BID_DOES_NOT_EXIST);
            Ask memory ask = asks[askID[i]];
            IERC721 nft = IERC721(ask.nft);
            require(nft.ownerOf(ask.tokenID) == msg.sender, REVERT_NOT_OWNER);
            require(
                nft.getApproved(ask.tokenID) == address(this) ||
                    nft.isApprovedForAll(msg.sender, address(this)),
                REVERT_NOT_APPROVED
            );

            if (ask.paymentToken == address(1)) {
                totalPrice += bid.price;
            } else {
                IERC20 token = IERC20(ask.paymentToken);
                require(token.transferFrom(bid.buyer, ask.seller, bid.price));
            }
            // escrow[msg.sender] += bids[nftAddress][tokenID[i]].price;
            nft.safeTransferFrom(
                ask.seller,
                bid.buyer,
                ask.tokenID,
                new bytes(0)
            );
            emit BidAccepted({
                nft: ask.nft,
                tokenID: ask.tokenID,
                price: bid.price
            });

            delete asks[askID[i]];
            delete bids[askID[i]];
            removeAskID(askID[i]);
        }

        uint256 remaining = _takeFee(totalPrice);
        balances[msg.sender] = remaining;
    }

    /// @notice Sellers can receive their payment by calling this function.
    function withdraw() external override {
        require(balances[msg.sender] > 0, REVERT_ZERO_BALANCE);
        uint256 amount = balances[msg.sender];
        balances[msg.sender] = 0;
        payable(address(msg.sender)).transfer(amount);
    }

    /// @dev Hook that is called to collect the fees in FeeCollector extension.
    /// Plain implementation of marketplace (without the FeeCollector extension)
    /// has no fees.
    /// @param totalPrice Total price payable for the trade(s).
    function _takeFee(uint256 totalPrice) internal virtual returns (uint256) {
        return totalPrice;
    }

    function removeAskID(bytes32 askID) internal {
        uint256 index = askIDIndex[askID];
        askIDs[index] = askIDs[askIDs.length - 1];
        askIDIndex[askIDs[index]] = index;
        askIDs.pop();
    }
}