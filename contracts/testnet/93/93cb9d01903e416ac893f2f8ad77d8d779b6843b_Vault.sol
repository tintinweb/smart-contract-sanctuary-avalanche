/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-26
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

/// @notice Safe unsigned integer casting library that reverts on overflow.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/SafeCastLib.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeCast.sol)
library SafeCastLib {
    function safeCastTo248(uint256 x) internal pure returns (uint248 y) {
        require(x <= type(uint248).max);

        y = uint248(x);
    }

    function safeCastTo224(uint256 x) internal pure returns (uint224 y) {
        require(x <= type(uint224).max);

        y = uint224(x);
    }

    function safeCastTo128(uint256 x) internal pure returns (uint128 y) {
        require(x <= type(uint128).max);

        y = uint128(x);
    }

    function safeCastTo96(uint256 x) internal pure returns (uint96 y) {
        require(x <= type(uint96).max);

        y = uint96(x);
    }

    function safeCastTo64(uint256 x) internal pure returns (uint64 y) {
        require(x <= type(uint64).max);

        y = uint64(x);
    }

    function safeCastTo32(uint256 x) internal pure returns (uint32 y) {
        require(x <= type(uint32).max);

        y = uint32(x);
    }

    function safeCastTo8(uint256 x) internal pure returns (uint8 y) {
        require(x <= type(uint8).max);

        y = uint8(x);
    }
}
/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE                        
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)



// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)



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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
}

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function mint(uint256 amt) external;

    function mint(address to, uint256 amt) external;

    function burn(uint256 amt) external;
}

/*
  PLEASE FOR THE LOVE OF GOD DON'T PUT ANY REAL MONEY IN THIS. IT'S HIGHLY INSECURE.
*/

contract Vault is ERC721TokenReceiver, Ownable {
    using SafeCastLib for uint256;
    using safeSigned for int256;

    IERC20 public usdc;
    IERC20 public lToken;
    IERC721 public nftCollection;

    uint256 public MAX_LTV;
    uint256 public FLOOR_PRICE;

    uint256 constant BASE_REWARD_RATE = 25;
    uint256 constant INTEREST_RATE = 30;
    uint256 constant PRECISION = 10**8;

    uint256 constant MIN_BID_DURATION = 1 days;

    struct LenderInfo {
        uint256 principal;
        uint256 rewardDebt;
        uint256 bidAmount;
        uint64 lastRewardTime;
    }

    mapping(address => LenderInfo) public lendersInfo;


    // TODO: Merge this into the NFTInfo struct, probably more gas efficient
    struct BidInfo {
        address user;
        uint256 bidPrice;
        uint256 bidAccepted;
    }

    mapping(uint256 => BidInfo) public highestBids; 

    struct NFTInfo {
        address depositor;
        uint256 borrowAmt;
        uint256 lastPaid;
    }

    mapping(uint256 => NFTInfo) public nftInfo;

    uint256 public totalUSDCinLoans;

    struct DefaultInfo {
        uint256 excessUSDCDue;
        uint256 outstandingLTokens;
    }

    mapping(address => DefaultInfo) public defaultInfo;

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 idCollateral, uint256 borrowedAmount);
    event Repayed(address indexed user, uint256 idCollateral, uint256 borrowedAmount);
    event Defaulted(address indexed user, uint256 idCollateral, uint256 borrowedAmount, uint256 shortFall);
    event Auctioned(address indexed buyer, uint256 id, uint256 amount);

    // TODO: temp for testing, remove
    event log(string output);
    event log_uint(uint output);
    event log_address(address output);
    event log_bytes(bytes output);

    constructor(
        address _usdc,
        address _lToken,
        address _nftCollection
        ) {
            usdc = IERC20(_usdc);
            lToken = IERC20(_lToken);
            nftCollection = IERC721(_nftCollection);
        }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _id,
        bytes calldata _data
    ) public virtual override returns (bytes4) {
        require(_operator == _from, "Vault: operator is not from");
        emit log_bytes(_data); // maybe add a safe check that requires user to input something in data
        NFTInfo storage idInfo = nftInfo[_id];
        idInfo.depositor = _from;
        

        return ERC721TokenReceiver.onERC721Received.selector;
    }

    function lenderLastUpdate() public view returns (uint256 lastUpdate) {
        return lendersInfo[msg.sender].lastRewardTime;
    }

    function lenderLastUpdate(address _user) public view returns (uint256 lastUpdate) {
        return lendersInfo[_user].lastRewardTime;
    }

    function lenderInterest(address _user) public view returns (uint256 pending) {
        LenderInfo storage user = lendersInfo[_user];

        uint256 lReward;
        if (block.timestamp > user.lastRewardTime && usdc.balanceOf(address(this)) != 0) {
            uint256 time = block.timestamp - user.lastRewardTime;
            lReward = time * BASE_REWARD_RATE;
        }
        pending = int256(((user.principal * lReward) / PRECISION) - user.rewardDebt).toUInt256();
    }

    function lenderPrincipal() public view returns (uint256 balance) {
        LenderInfo storage user = lendersInfo[msg.sender];

        return user.principal;
    }

    function lenderPrincipal(address _user) public view returns (uint256 balance) {
        LenderInfo storage user = lendersInfo[_user];

        return user.principal;
    }

    function lenderDeposit(uint256 amt) public {

        LenderInfo storage user = lendersInfo[msg.sender];

        if (user.principal > 0 || user.lastRewardTime == 0) {
            uint256 pendingLToken =  lenderInterest(msg.sender);
            user.lastRewardTime = block.timestamp.safeCastTo64();
            if(pendingLToken > 0) {
                user.rewardDebt += pendingLToken;
                //emit log_uint(pendingLToken);
                lToken.mint(msg.sender, pendingLToken);
            }
        }
        usdc.transferFrom(
            address(msg.sender),
            address(this),
            amt
        );
        user.principal += amt;
        emit Deposit(msg.sender, amt);

    }

    function lenderWithdraw(uint256 amt) public {
        LenderInfo storage user = lendersInfo[msg.sender];
        require(user.principal >= amt, "LendingVault: WITHDRAW_FAILED");

        uint256 pendingLToken =  lenderInterest(msg.sender);
        user.lastRewardTime = block.timestamp.safeCastTo64();
        if(pendingLToken > 0) {
            user.rewardDebt += pendingLToken;
            lToken.mint(msg.sender, pendingLToken);
        }

        user.principal -= amt;
        usdc.transfer(
            address(msg.sender),
            amt
        );
        emit Withdraw(msg.sender, amt);

    }

    function nftInventory(uint256 id) public view returns (address depositor, uint256 borrowed, uint256 lastPayment) {
       
        depositor = nftInfo[id].depositor;
        borrowed = nftInfo[id].borrowAmt;
        lastPayment = nftInfo[id].lastPaid;

    }

    function borrowerWithdrawLoan(address borrower, uint256 amt) internal  {
        usdc.transfer(borrower, amt);
    }

    function borrowerReturnLoan(uint256 amt) public {
        usdc.transferFrom(msg.sender, address(this), amt);
    }

    // TODO: make internal
    function lenderReducePrincipal(address _user, uint256 amt) internal {
        LenderInfo storage user = lendersInfo[_user];
        require(user.principal >= amt, "LendingVault: PRINCIPAL_REDUCE_FAILED");

        user.principal -= amt;
    }

    // Move to voting by LendingVault
    function setBorrowParameters(uint256 _newLtv, uint256 _floor) public onlyOwner {
        if( _newLtv != 0) {
            require(_newLtv > 0 && _newLtv < 50, "NFTVault: INVALID_LTV");
            MAX_LTV = _newLtv;
        }
        if( _floor != 0) {
            FLOOR_PRICE = _floor;
        }
    }

    function viewBorrowCapacity(uint256 id) public view returns (uint256) {
        NFTInfo storage idInfo = nftInfo[id];

        uint256 maxBorrow = FLOOR_PRICE * MAX_LTV / 100;

        require(idInfo.borrowAmt <= maxBorrow, "NFTVault: No borrow capacity");

        return maxBorrow - idInfo.borrowAmt;
    }

    function interestDue(uint256 id) public view returns (uint256) {
        NFTInfo storage idInfo = nftInfo[id];
        if(idInfo.borrowAmt != 0 && block.timestamp > idInfo.lastPaid) {
            uint256 time = block.timestamp - idInfo.lastPaid;
            uint256 lDue = ((time * INTEREST_RATE) * idInfo.borrowAmt) / (PRECISION*100);
            return lDue;
        }
        return 0;
    }

    function payLTokenDebt(uint256 id) public {
        NFTInfo storage idInfo = nftInfo[id];

        uint256 _lTokenOwed = interestDue(id);
        lToken.transferFrom(address(msg.sender), address(this), _lTokenOwed);
        lToken.burn(_lTokenOwed);
        
        idInfo.lastPaid = block.timestamp;
    }


    // borrowing requires that the debtor repays outstanding lToken debt
    function borrowerStartBorrowing(uint256 id, uint256 amt) public {
        require(viewBorrowCapacity(id) >= amt, "NFTVault: insufficient borrow capacity");
        NFTInfo storage idInfo = nftInfo[id];
        require(idInfo.depositor == msg.sender, "NFTVault: not NFT owner");

        payLTokenDebt(id);
        
        idInfo.borrowAmt += amt;
        borrowerWithdrawLoan(idInfo.depositor, amt);

    }

    function repayPrincipal(uint256 id, bool withdrawNFT) public {
        NFTInfo storage idInfo = nftInfo[id];
        require(idInfo.depositor == msg.sender, "NFTVault: not NFT owner");

        payLTokenDebt(id);

        //no idea if this part works
        borrowerReturnLoan(idInfo.borrowAmt);

        if(withdrawNFT) {
            nftCollection.safeTransferFrom(address(this), idInfo.depositor, id);
            // might be able to leave this to reduce gas if a new lenderDepositor takes the NFT, but this is probably safer
            idInfo.depositor = address(0);
        }
        
        idInfo.borrowAmt = 0;
    }


    // we define solvency as a loan where the lToken owed + principal does not exceed 33% of the FLOOR_PRICE.
    // For simplicity 1 lToken = 1 USDC
    function isSolvent(uint256 id) public view returns (bool) {
        NFTInfo storage idInfo = nftInfo[id];

        uint256 _lTokenOwed = interestDue(id);

        uint256 totalDebt = idInfo.borrowAmt + _lTokenOwed; // need to adjust lToken to calculate with 6 decimals

        return totalDebt > FLOOR_PRICE/3 ? false : true;
    }

    function declareDefault(uint256 id) public {
        require(!isSolvent(id), "NFTVault: Borrower is Solvent");

        // find highest bid
        BidInfo storage bestBid = highestBids[id];
        NFTInfo storage loanInfo = nftInfo[id];

        // log default against the borrower (handle if they have other outstanding)
        DefaultInfo storage debtorInfo = defaultInfo[loanInfo.depositor];

        // once a default happens we book a default event against the borrower, if there are already outstanding unpaid lToken debts, we add this to it 
        if(bestBid.bidPrice >= loanInfo.borrowAmt) {
            debtorInfo.excessUSDCDue += bestBid.bidPrice - loanInfo.borrowAmt;
            debtorInfo.outstandingLTokens += interestDue(id);
        } else {
            debtorInfo.outstandingLTokens += interestDue(id);
        }

        // check if there is a bidder, and if not retain NFT
        if (bestBid.bidPrice != 0) {
            // reduce bidder's USDC principal
            lenderReducePrincipal(bestBid.user, bestBid.bidPrice);

            // transfer NFT to highest bidder
            nftCollection.safeTransferFrom(address(this), bestBid.user, id);

            // reset the loan to zero
            nftInfo[id] = NFTInfo({
                depositor: address(0),
                borrowAmt: 0,
                lastPaid: 0
            });

            // reset the bid to zero
            highestBids[id] = BidInfo({
                user : address(0),
                bidPrice : 0,
                bidAccepted : 0
            });


        } else {
            // set the bid to the loan amount and make depositor this contract
            highestBids[id] = BidInfo({
                user : address(this),
                bidPrice : nftInfo[id].borrowAmt,
                bidAccepted : 0
            });
            
            // if no bidder active, swap the details to this contract
            nftInfo[id] = NFTInfo({
                depositor: address(this),
                borrowAmt: 0,
                lastPaid: 0
            });





        }


        

    }


    // @TODO: Need to include the logic to look at the LendingVault for the size of bid a user can place

    // If a new bid is the highest bid then we replace the existing highest bid with this bid
    function enterNewBid(uint256 id, uint256 _bidPrice) public {
        BidInfo storage idBid = highestBids[id];
        require(_bidPrice > idBid.bidPrice, "NFTVault: Not highest bid");

        // need to check the user's free USDC balance
        LenderInfo storage bidder = lendersInfo[msg.sender];
        require((bidder.principal - bidder.bidAmount) >= _bidPrice, "insufficient free bid capacity");
        
        // add this bid to their bid amount
        bidder.bidAmount += _bidPrice;

        // check if this is a defaulted NFT owned by the Vault, if so transfer to the bidder and reduce their principal
        if(idBid.user == address(this)) {
            lenderReducePrincipal(msg.sender, _bidPrice);

            // transfer NFT to bidder
            nftCollection.safeTransferFrom(address(this), msg.sender, id);

            // reset the loan to zero
            nftInfo[id] = NFTInfo({
                depositor: address(0),
                borrowAmt: 0,
                lastPaid: 0
            });

            // reset the bid to zero
            highestBids[id] = BidInfo({
                user : address(0),
                bidPrice : 0,
                bidAccepted : 0
            });

            return;
        }

        highestBids[id] = BidInfo({
            user: msg.sender,
            bidPrice: _bidPrice,
            bidAccepted: block.timestamp
        });

    }

    // If the bid has passed a minum time then we allow for the bidder to modify
    function modifyBid(uint256 id, uint256 newBidPrice) public {
        BidInfo storage idBid = highestBids[id];
        require(idBid.user == msg.sender, "NFTVault: Unauthorised bid modifier");
        require(block.timestamp > idBid.bidAccepted + MIN_BID_DURATION, "NFTVault: Cannot modify bid yet");

        // need to check the user's free USDC balance
        LenderInfo storage bidder = lendersInfo[msg.sender];

        // check if the new bid is higher or lower than the existing bid and adjust bid tracker in lender profile
        if(newBidPrice > idBid.bidPrice) {
            require((bidder.principal - bidder.bidAmount) >= newBidPrice, "insufficient free bid capacity");
        
            // add this bid to their bid amount
            bidder.bidAmount += newBidPrice;
        } else {
            bidder.bidAmount -= idBid.bidPrice-newBidPrice;
        }

        highestBids[id] = BidInfo({
            user: msg.sender,
            bidPrice: newBidPrice,
            bidAccepted: block.timestamp
        });
    }

}

library safeSigned {
    function toUInt256(int256 a) internal pure returns (uint256) {
        require(a >= 0, "Integer < 0");
        return uint256(a);
    }
}