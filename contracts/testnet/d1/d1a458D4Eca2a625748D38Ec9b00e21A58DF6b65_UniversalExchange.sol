// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;
/**
 * @title StableCoin Interface
 * @dev StableCoin logic
 */
interface IStableCoin{
     /**
     * @dev Transfer the specified _amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _account   Receiver address.
     * @param _amount    Amount of tokens that will be transferred.
     * @param _data      Transaction metadata.
     */
    function transferWithData(address _account,uint256 _amount, bytes calldata _data ) external returns (bool success) ;
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn't contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _account    Receiver address.
     * @param _amount     Amount of tokens that will be transferred.
     */
    function transfer(address _account, uint256 _amount) external returns (bool success);
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 _amount) external;
    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address _account, uint256 _amount) external;
    /**
     * @dev mint the specified amount of tokens mint to the specified address.
     * @param _account    Receiver address.
     * @param _amount     Amount of tokens that will be transferred.
     */
    function mint(address _account, uint256 _amount) external returns (bool);
    /**
     * @dev check balance
     * @param who new Address of property owners
     * @return balance of owner
     */
    function balanceOf(address who) external view returns (uint256);
     /**
     * @dev allowance
     * @param owner  Address of property owners
     * @param spender  Address of spender 
     * @return balance of allowance
     */
    function allowance(address owner, address spender) external view returns (uint256);
     /**
     * @dev transferFrom
     * @param from  Address of property owners
     * @param to  Address of spender 
     * @param value token's value
     * @return success
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMarginLoan {
    /**
     * LoanStatus : it will have only follwoing three values.
     */
    enum LoanStatus {NOTFOUND, PENDING, ACTIVE, COMPLETE, REJECT, CANCEL, PLEDGE}
    /**
     * MarginLoan: This struct will Provide the required field of Loan record
     */
    struct MarginLoan {
        address user;
        address bank;
        uint256 loanAmount;
        uint256 interestRate;
        LoanStatus status;
        address tokenAddress;
        uint256 createdAt;
        uint256 installmentAmount;
        uint256 loanLimit;      //maximum loan limit a user can avail against tokens
        uint256 loanPercentage;
        uint256 noOfTokens;
    }

    /**
     * LoanRequest: This event will triggered when ever their is request for loan
     */
    event LoanRequest(
        address user,
        address bank,
        uint256 loanAmount,
        uint256 interestRate,
        LoanStatus status,
        address tokenAddress,
        uint256 createdAt,
        uint256 installmentAmount,
        uint256 id,
        uint256 loanPercentage,
        uint256 noOfTokens
    );
    event UpdateLoan(address user, uint256 id, LoanStatus status);
    event PledgeToken(address user, address _token,uint256 noOfToekns,  LoanStatus status);

    /**
     * called when user request loan from bank
     *
     */
    function requestLoan(
        address _bank,
        uint256 _loanAmount,
        uint256 _interestRate,
        address _tokenAddress,
        uint256 createdAt,
        uint256 installmentAmount,
        uint256 _loanPercentage,
        uint256 noOfTokens
    ) external;

    /**
     * this function would return user margin with erc1400 address
     */
    function getLoan(address _user, address tokenAddress)
        external
        view
        returns (uint256,uint256);
    function getPledgedLoan(address _user, address tokenAddress, address _bank)
        external
        view
        returns (uint256,uint256, uint256,  uint256);

    /**
     * only user with a rule of bank can approve loan
     */
     function completeLoan(address _user, uint256 _id)
        external
        returns (bool);
     function pledgeLoanToken(address _user,address _tokenAddress, address _bank)
        external
        returns (bool);

    /**
     *getLoanStatus: thsi function return loan status of address provided
     */
    function getLoanStatus(address _user, uint256 _id)
        external
        view
        returns (uint256);

    /**
     * only user with a rule of bank can reject loan
     */
    function cancelLoan(uint256 _id) external returns (bool);

    /**
     * get t0tal of margin loan array of address
     */
    function getTotalLoans(address _user) external view returns (uint256);

    /**
     * get total number of  loan on a signle erc1400 token
     */

    function getTotalLoanOfToken(address _user, address _token)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );
    
    function getTotalLoanOfPledgedToken(address _user, address _token, address _bank)
        external 
        view
          returns (
            address[] memory banks,
            uint256[] memory loanAmounts,
            uint256[] memory interestRates
          
        );

   function getTotalNoOfTokens(address _user, address _token)
        external
        view
        returns (uint256[] memory,uint256[] memory);

  function getTotalNoOfPledgeTokens(address _user, address _token, address _bank)
        external
        view
        returns (uint256[] memory ids, uint256[] memory loans, uint256[] memory interest);
        
    function updateLoan(
        address user,
        uint256 id,
        uint256 AmountPayed,
        uint256 caller
    ) external;

    function updatePledgeLoan(
        address user,
        uint256 id,
        uint256 AmountPayed,
        uint256 tokensSold,
        uint256 caller
    ) external;
    
    

   function getLoanLimit(address _user, address _tokenAddress, uint256 _loanPercentage) view external returns (uint256) ;
   function getRemainingLoanLimit( address _user,address _tokenAddress, uint256 _loanPercentage) view external returns ( uint256);

    function addBlockedUser(address _user) external ;
    
    function removeBlockedUser(address _user) external;

    function isBlockedUser(address _user) external view  returns(bool);

    function payPledgeLoan(address _user,address _tokenAddress, address _bank)
        external
        returns (bool);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;


interface ERC1820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
    function setManager(address _addr, address _newManager) external;
    function getManager(address _addr) external view returns (address);
}


/// Base client to interact with the registry.
contract ERC1820Client {
    ERC1820Registry constant ERC1820REGISTRY = ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/**
 * @title ERC1400RawERC20
 * @dev ERC1400Raw with ERC20 retrocompatibility
 *  @author AKRU's Dev team
 */
interface IERC1400RawERC20  { 
  function name() external view returns (string memory); // 1/13
  function symbol() external view returns (string memory); // 2/13
  function totalSupply() external view returns (uint256); // 3/13
  function balanceOf(address owner) external view returns (uint256); // 4/13
  function granularity() external view returns (uint256); // 5/13

  function controllers() external view returns (address[] memory); // 6/13
  function authorizeOperator(address operator) external; // 7/13
  function revokeOperator(address operator) external; // 8/13
  function isOperator(address operator, address tokenHolder) external view returns (bool); // 9/13

  function transferWithData(address to, uint256 value, bytes calldata data) external; // 10/13
  function transferFromWithData(address from, 
                                address to, 
                                uint256 value, 
                                bytes calldata data, 
                                bytes calldata operatorData) external; // 11/13

  function redeem(uint256 value, bytes calldata data) external; // 12/13
  function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 13/13
   // Added Latter
   function cap(uint256 propertyCap) external;
  function basicCap() external view returns (uint256);
  function getStoredAllData(address adminAddress) external view returns (address[] memory, uint256[] memory);

    // function distributeDividends(address _token, uint256 _dividends) external;
  event TransferWithData(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 value,
    bytes data,
    bytes operatorData
  );
  event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
  event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);

function issue(address to, uint256 value, bytes calldata data) external  returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 value) external returns (bool);
function transfer(address to, uint256 value) external  returns (bool);
function transferFrom(address from, address to, uint256 value)external returns (bool);
function migrate(address newContractAddress, bool definitive)external;
function closeERC1400() external;
function addFromExchange(address _investor , uint256 _balance) external returns(bool);
function updateFromExchange(address investor , uint256 balance) external returns (bool);
function transferOwnership(address payable newOwner) external; 
function propertyOwners() external view returns (address[] memory);
function shares() external view returns (uint256[] memory);
function isPropertyOwnerExist(address _addr) external view returns(bool isOwnerExist);
function toggleCertificateController(bool _isActive) external;
function bulkMint(address[] calldata to,uint256[] calldata amount,bytes calldata cert) external;
function addPropertyOwnersShares(uint256[] calldata _share,address[] calldata _owners) external;

//function devToken() external view returns (uint256) ;
//function setDevTokens() external ;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../token/ERC20/IERC1400RawERC20.sol";
import "../whitelist/ITokenismWhitelist.sol";
import "../MarginLoan/IMarginLoan.sol";
import "../IStableCoin.sol";

interface IUniversalExchange {
    /**
     *  E1: Only admin is allowed to send
     *  E2: Only admin or user is allowed to send
     *  E3: Only admin or seller is allowed to send
     *  E4: Only admin or buyer is allowed to send
     *  E5: Only admin or seller or buyer
     *  E6: Invalid Security Token address
     *  E7: Price is zero
     *  E8: Quantity is zero
     *  E9: Insufficient Security Token
     *  E10: Approve Security Tokens
     *  E11: Invalid id
     *  E12: Seller cannot buy token
     *  E13: Buy quantity must be greater than zero
     *  E14: Quantity must be greater than Remaining Quantity
     *  E15: Insufficient AKUSD balance
     *  E16: Buyer should allow contract to spend
     *  E17: Seller cannot Offer
     *  E18: Price set by Buyer must be less than seller price
     *  E19: Buyer already offered
     *  E20: Approve AKUSD
     *  E21: Wait for buyer counter
     *  E22: No offers found
     *  E23: Offer expired
     *  E24: Price must be greater than buyer offer price
     *  E25: Price must be smaller than listing price
     *  E26: Price must be lesser than previous offer price
     *  E27: Seller counter exceeded
     *  E28: Remaing Quantity is must be greater or equal to offering quantity
     *  E29: Wait for seller counter
     *  E30: Price must be smaller than seller offer price
     *  E31: Price must be greater than previous offer price
     *  E32: Buyer counter exceeded
     *  E33: Zero Address
     *  E34: Incorrect Nonce
     *  E35: Buyer cannot reject his counter
     *  E36: Seller cannot reject his counter
     *  E37: Unauthorized
     *  E38: Buyer can't accept their own offer
     *  E39: Seller can't accept their own offer
     */

    enum Status {
        Default, // default value
        Listed, //for listings
        UnListed, //for listings
        Sold, // for offers and listings
        Created, // for offers
        Countered, // for offers
        Canceled, // for offers
        Rejected, //for offers
        Null // for offers
    }

    struct Offers {
        uint128 buyerPrice;
        uint128 sellerPrice;
        uint128 quantity;
        uint256 expiryTime;
        uint8 buyerCount;
        uint8 sellerCount;
        bool isOffered;
        bool isCallable;
        Status status;
    }

    struct ListTokens {
        uint128 price;
        uint128 quantity;
        uint128 remainingQty;
        uint128 tokenInHold;
        address seller;
        IERC1400RawERC20 token;
        Status status;
    }

    event TokensListed(
        uint256 indexed id,
        address indexed seller,
        IERC1400RawERC20 indexed token,
        uint128 price,
        uint128 quantity
    );

    event TokensPurchased(
        uint256 indexed id,
        address indexed buyer,
        address indexed seller,
        IERC1400RawERC20 token,
        uint128 quantity,
        uint128 price
    );

    event OfferPlaced(
        uint256 indexed id,
        address indexed buyer,
        uint128 quantity,
        uint128 price
    );

    event Counter(
        uint256 indexed id,
        address indexed wallet, //buyer or seller
        uint128 quantity,
        uint128 price
    );

    event ListingCanceled(
        uint256 indexed id,
        address indexed seller,
        IERC1400RawERC20 indexed token,
        uint128 price,
        uint128 quantity
    );

    event RejectCounter(
        uint256 indexed id,
        address indexed wallet, //buyer or seller
        uint128 quantity,
        uint128 price
    );

    event BuyerOfferCanceled(
        IERC1400RawERC20 token,
        address buyerWallet,
        uint128 quantity,
        uint128 price
    );

    event SellerOfferCanceled(
        IERC1400RawERC20 token,
        address seller,
        address buyerWallet,
        uint128 quantity,
        uint128 price
    );

    event LoanPayed(
        IERC1400RawERC20 token,
        address seller,
        address backAddress,
        uint256 totalAmount
    );

    function sellTokens(
        uint128 price,
        uint128 quantity,
        address seller,
        IERC1400RawERC20 token
    ) external;

    function buyTokens(uint256 id, uint128 quantity, address buyer) external;

    function buyerOffer(
        uint256 id,
        uint128 quantity,
        uint128 price,
        address buyer
    ) external;

    function setFeeAddress(address newFeeAddress) external;

    function setFeePercentage(uint128 newFeePercentage) external;

    function counterSeller(uint256 id, uint128 price, address buyer) external;

    function counterBuyer(uint256 id, uint128 price, address seller) external;

    function cancelListing(uint256 id) external;

    function rejectCounter(
        uint256 id,
        address buyer,
        bytes calldata signature,
        uint256 nonce
    ) external;

    function getListings(
        uint256 id
    )
        external
        view
        returns (
            uint256 price,
            uint256 quantity,
            uint256 remainingQty,
            uint256 tokenInHold,
            IERC1400RawERC20 token,
            address seller,
            Status status
        );

    function acceptCounter(
        uint256 id,
        address buyer,
        bytes calldata signature,
        uint256 nonce
    ) external;

    function cancelBuyer(uint256 id, address buyer) external;

    function cancelSeller(uint256 id, address buyer) external;

    function updateWhiteListing(ITokenismWhitelist newWhitelist) external;

    function updateStableCoin(IStableCoin newStableCoin) external;

    function updateMarginLoan(IMarginLoan newMarginLoan) external;

    function updateInterfaceHash(string calldata interfaceHash) external;

    function toggleMarginLoan() external;

    function toggleFee() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IUniversalExchange.sol";
import "../token/ERC1820/ERC1820Client.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "hardhat/console.sol";

/**
 * @title Universal Exchange
 * @author Umer Mubeen & Asadullah Khan
 * @notice Singleton Exchange Instance
 * @dev AKRU Exchange Smart Contract for Secondary Market
 */
contract UniversalExchange is
    IUniversalExchange,
    Ownable,
    ERC1820Client,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    ///@dev Listing counter
    Counters.Counter private count;
    IStableCoin public stableCoin;
    ITokenismWhitelist public whitelist;
    IMarginLoan public marginLoan;
    string public erc1400InterfaceId = "ERC20Token";
    address public feeAddress;
    uint256 public feePercentage; // in wei
    bool public marginLoanStatus = false;
    bool public feeStatus = false;
    
    ///@dev listing id to listing detail
    mapping(uint256 => ListTokens) private listedTokens;

    ///@dev offeror address to listing id to offer detail
    mapping(address => mapping(uint256 => Offers)) public listingOffers;

    ///@dev listing id to array of offeror address
    mapping(uint256 => address[]) public counterAddresses;

    ///@dev address to replay nonce
    mapping(address => uint256) public replayNonce;

    constructor(
        IStableCoin stableCoinAddress,
        ITokenismWhitelist whitelistingAddress,
        IMarginLoan marginLoanAddress
    ) {
        stableCoin = stableCoinAddress;
        whitelist = whitelistingAddress;
        marginLoan = marginLoanAddress;
    }

    modifier onlyTokenismAdmin() {
        require(whitelist.isAdmin(_msgSender()), "E1");
        _;
    }

    modifier onlyTokenismAdminAndUser() {
        require(
            whitelist.isAdmin(_msgSender()) ||
                whitelist.isWhitelistedUser(_msgSender()) == 200,
            "E2"
        );
        _;
    }
    modifier onlyTokenismAdminAndSeller(uint256 id) {
        ListTokens memory listing = listedTokens[id];

        require(
            whitelist.isAdmin(_msgSender()) || _msgSender() == listing.seller,
            "E3"
        );
        _;
    }
    modifier onlyTokenismAdminAndBuyer(uint256 id) {
        Offers memory listingOffer = listingOffers[_msgSender()][id];

        require(
            whitelist.isAdmin(_msgSender()) ||
                (listingOffer.status == Status.Created ||
                    listingOffer.status == Status.Countered),
            "E4"
        );
        _;
    }

    function _onlyTokenismAdminAndSellerAndBuyer(uint256 id) private view {
        ListTokens memory listing = listedTokens[id];

        Offers memory listingOffer = listingOffers[_msgSender()][id];

        require(
            whitelist.isAdmin(_msgSender()) ||
                _msgSender() == listing.seller ||
                (listingOffer.status == Status.Created ||
                    listingOffer.status == Status.Countered),
            "E5"
        );
    }

    modifier onlyTokenismAdminAndSellerAndBuyer(uint256 id) {
        _onlyTokenismAdminAndSellerAndBuyer(id);
        _;
    }

    /**
     * @dev List Token of any Property on Exchange for Sell
     * @param price Price of Token that want on sell
     * @param quantity Quantity of token that want to sell
     * @param seller address of token that want to sell token
     * @param token Address of ERC1400/Security token
     */

    function sellTokens(
        uint128 price,
        uint128 quantity,
        address seller,
        IERC1400RawERC20 token
    ) external override onlyTokenismAdminAndUser {
        require(
            interfaceAddr(address(token), erc1400InterfaceId) != address(0),
            "E6"
        );

        require(price > 0, "E7");

        require(quantity > 0, "E8");
        require(quantity <= token.balanceOf(seller), "E9");

        require(quantity <= token.allowance(seller, address(this)), "E10");

        uint256 currentCount = count.current();

        listedTokens[currentCount] = ListTokens({
            seller: seller,
            token: token,
            price: price,
            quantity: quantity,
            remainingQty: quantity,
            tokenInHold: 0,
            status: Status.Listed
        });

        count.increment();

        token.transferFrom(seller, address(this), quantity);

        token.addFromExchange(seller, quantity);

        emit TokensListed(currentCount, seller, token, price, quantity);
    }

    /**
     * @dev Buyer Direct Buy Token on that price.
     * @param quantity : number of tokens.
     * @param buyer:  buyer wallet address.
     * @param id:  listed tokens id.
     */

    function buyTokens(
        uint256 id,
        uint128 quantity,
        address buyer
    ) external override onlyTokenismAdminAndUser nonReentrant {
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");
        require(listing.seller != buyer, "E12");
        require(quantity > 0, "E13");
        require(quantity <= listing.remainingQty, "E14");

        uint256 totalAmount = quantity * listing.price;

        require(stableCoin.balanceOf(buyer) >= totalAmount, "E15");

        require(
            stableCoin.allowance(buyer, address(this)) >= totalAmount,
            "E16"
        );

        listing.remainingQty -= quantity;

        IERC1400RawERC20 token = listing.token;
        address seller = listing.seller;
        uint128 price = listing.price;

        if (listing.remainingQty < 1 && listing.tokenInHold < 1) {
            listing.status = Status.Sold;
        }
        stableCoin.transferFrom(buyer, address(this), totalAmount);
        if (marginLoanStatus) {
            uint256 payToSeller = adjustLoan(
                address(listing.token),
                listing.seller,
                totalAmount
            );
            totalAmount = payToSeller;
        }
        if (totalAmount != 0) {
            if (!feeStatus) {
                stableCoin.transfer(listing.seller, totalAmount);
            } else {
                uint256 finalAmount = (totalAmount * feePercentage) / 100 ether;
                stableCoin.transfer(listing.seller, finalAmount);
            }
        }

        token.transfer(buyer, quantity);

        token.updateFromExchange(seller, quantity);

        ///@dev null all offers made on this listing.
        nullOffer(id);

        emit TokensPurchased(id, buyer, seller, token, quantity, price);
    }

    /**
     * @dev Send Offer for Purchase Token
     * @param id listing id or order id of that token
     * @param quantity Quantity of token that want to purchase
     * @param price price that want to offer
     * @param buyer Address of buyer whose want to buy token
     */

    function buyerOffer(
        uint256 id,
        uint128 quantity,
        uint128 price,
        address buyer
    ) external override onlyTokenismAdminAndUser {
        require(quantity > 0, "E8");
        ListTokens memory listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");
        require(listing.seller != buyer, "E17");

        require(price < listing.price, "E18");

        require(!listingOffers[buyer][id].isOffered, "E19");

        require(quantity <= listing.remainingQty, "E14");

        uint256 totalAmount = quantity * price;

        require(
            totalAmount <= stableCoin.allowance(buyer, address(this)),
            "E20"
        );
        require(stableCoin.balanceOf(buyer) >= totalAmount, "E15");

        listingOffers[buyer][id] = Offers({
            buyerPrice: price,
            sellerPrice: listing.price,
            quantity: quantity,
            expiryTime: block.timestamp + 2 days,
            isOffered: true,
            buyerCount: 1,
            sellerCount: 0,
            isCallable: true,
            status: Status.Created
        });

        counterAddresses[id].push(buyer);

        stableCoin.transferFrom(buyer, address(this), totalAmount);

        emit OfferPlaced(id, buyer, quantity, price);
    }

    /**
     * @dev Counter on buyer offer by seller
     * @param id listing id or order id of that token
     * @param price price that want to offer
     * @param buyer Address of buyer whose want to buy token
     */

    function counterSeller(
        uint256 id,
        uint128 price,
        address buyer
    ) external override onlyTokenismAdminAndSeller(id) {
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");

        Offers storage listingOffer = listingOffers[buyer][id];

        require(listingOffer.isCallable, "E21");

        require(
            listingOffer.status == Status.Created ||
                listingOffer.status == Status.Countered,
            "E22"
        );

        require(block.timestamp < listingOffer.expiryTime, "E23");
        require(price > listingOffer.buyerPrice, "E24");
        require(price < listing.price, "E25");
        require(price < listingOffer.sellerPrice, "E26");
        require(listingOffer.sellerCount < 2, "E27");

        if (listingOffer.sellerCount < 1) {
            require(listingOffer.quantity <= listing.remainingQty, "E28");
            listing.remainingQty -= listingOffer.quantity;
            listing.tokenInHold += listingOffer.quantity;
        }
        listingOffer.status = Status.Countered;
        listingOffer.sellerPrice = price;
        listingOffer.sellerCount++;
        listingOffer.isCallable = false;
        listingOffer.expiryTime = block.timestamp + 2 days;

        emit Counter(id, listing.seller, listingOffer.quantity, price);
    }

    /**
     * @dev Counter on buyer offer by seller
     * @param id listing id or order id of that token
     * @param price price that want to offer
     * @param buyer Address of buyer whose want to buy token
     */

    function counterBuyer(
        uint256 id,
        uint128 price,
        address buyer
    ) external override onlyTokenismAdminAndBuyer(id) {
        ListTokens memory listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");

        Offers storage listingOffer = listingOffers[buyer][id];
        require(block.timestamp < listingOffer.expiryTime, "E23");
        require(!listingOffer.isCallable, "E29");

        require(
            listingOffer.status == Status.Created ||
                listingOffer.status == Status.Countered,
            "E22"
        );

        require(price < listing.price, "E25");
        require(price < listingOffer.sellerPrice, "E30");
        require(price > listingOffer.buyerPrice, "E31");
        require(listingOffer.buyerCount < 2, "E32");

        uint256 priceDiff = price - listingOffer.buyerPrice;
        priceDiff *= listingOffer.quantity;
        require(stableCoin.allowance(buyer, address(this)) >= priceDiff, "E20");
        listingOffer.buyerPrice = price;
        listingOffer.buyerCount++;
        listingOffer.isCallable = true;
        listingOffer.expiryTime = block.timestamp + 2 days;

        stableCoin.transferFrom(buyer, address(this), priceDiff);

        emit Counter(id, buyer, listingOffer.quantity, price);
    }

    /**
     * @dev Cancel the listing on exchange and return tokens to owner account.
     * @param id: it is the listing tokens id.
     * @dev id : it is astruct is of listing.
     */

    function cancelListing(
        uint256 id
    ) external override onlyTokenismAdminAndSeller(id) nonReentrant {
        ListTokens storage listing = listedTokens[id];
        require(listing.status == Status.Listed, "E11");

        address seller = listing.seller;
        IERC1400RawERC20 token = listing.token;
        uint128 quantity = listing.remainingQty;
        uint128 price = listing.price;

        listing.status = Status.UnListed;

        token.transfer(seller, quantity);
        token.updateFromExchange(seller, quantity);

        ///@dev null all offers made on this listing.
        nullOffer(id);

        emit ListingCanceled(id, seller, token, price, quantity);
    }

    /**
     * @dev null all the open offers and return the akusd to owners.
     * @param id: it is the listing tokens id.
     */

    function nullOffer(uint256 id) private {
        uint256 len = counterAddresses[id].length;
        for (uint256 i = 0; i < len; ) {
            Offers storage counteroffers = listingOffers[
                counterAddresses[id][i]
            ][id];

            ListTokens memory listing = listedTokens[id];

            if (
                counteroffers.quantity > listing.remainingQty &&
                counteroffers.sellerCount < 1
            ) {
                address buyer = counterAddresses[id][i];

                uint256 price = counteroffers.buyerPrice;
                uint256 quantity = counteroffers.quantity;

                uint256 totalAmount = (quantity * price);

                counteroffers.status = Status.Null;

                delete counterAddresses[id][i];

                stableCoin.transfer(buyer, totalAmount);
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev get single listing
     * @param id: listing id
     * @return price ,quantity,remainingQty,tokenInHold,token,seller,status
     */

    function getListings(
        uint256 id
    )
        external
        view
        override
        returns (
            uint256 price,
            uint256 quantity,
            uint256 remainingQty,
            uint256 tokenInHold,
            IERC1400RawERC20 token,
            address seller,
            Status status
        )
    {
        return (
            listedTokens[id].price,
            listedTokens[id].quantity,
            listedTokens[id].remainingQty,
            listedTokens[id].tokenInHold,
            listedTokens[id].token,
            listedTokens[id].seller,
            listedTokens[id].status
        );
    }

    /**
     * @dev Reject Counter By Seller or Buyer.
     * @param buyer: address of buyer of tokens.
     * @param id: offers id of struct maping.
     */

    function rejectCounter(
        uint256 id,
        address buyer,
        bytes calldata signature,
        uint256 nonce
    ) external override onlyTokenismAdminAndSellerAndBuyer(id) {
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");

        Offers storage listingOffer = listingOffers[buyer][id];

        require(
            listingOffer.status == Status.Created ||
                listingOffer.status == Status.Countered,
            "E22"
        );

        bytes32 metaHash = makeHash("rejectCounter", nonce);
        address signer = getSigner(metaHash, signature);
        ///@dev Make sure signer doesn't come back as 0x0. ??
        require(signer != address(0), "E33");

        require(nonce == replayNonce[signer], "E34");

        if (signer == buyer) {
            require(!listingOffer.isCallable, "E35");
        } else if (signer == listing.seller) {
            require(listingOffer.isCallable, "E36");
        } else {
            revert("E37");
        }

        address buyerWallet = buyer;

        uint128 price = listingOffer.buyerPrice;
        uint128 quantity = listingOffer.quantity;
        uint128 totalAmount = (quantity * (price));

        listing.remainingQty += listingOffer.quantity;

        replayNonce[signer]++;

        if (listingOffer.sellerCount >= 1) {
            listing.tokenInHold -= quantity;
            listing.remainingQty += quantity;
        }

        listingOffer.status = Status.Rejected;

        stableCoin.transfer(buyerWallet, totalAmount);

        emit RejectCounter(id, buyerWallet, quantity, price);
    }

    /**
     * @dev Buyer or Seller Accept Counter
     * @param id: listing id or order id of that token
     * @param signature: Address of buyer whose want to buy token
     * @param nonce: Address of buyer whose want to buy token
     */

    function acceptCounter(
        uint256 id,
        address buyer,
        bytes calldata signature,
        uint256 nonce
    ) external override onlyTokenismAdminAndSellerAndBuyer(id) nonReentrant {
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");

        Offers storage listingOffer = listingOffers[buyer][id];

        require(
            listingOffer.status == Status.Created ||
                listingOffer.status == Status.Countered,
            "E22"
        );

        bytes32 metaHash = makeHash("acceptCounter", nonce);
        address signer = getSigner(metaHash, signature);
        ///@dev Make sure signer doesn't come back as 0x0. ??
        require(signer != address(0), "E33");
        require(nonce == replayNonce[signer], "E34");

        uint128 price;
        uint128 quantity = listingOffer.quantity;
        if (signer == buyer) {
            require(!listingOffer.isCallable, "E38");
            uint128 priceDiff = listingOffer.sellerPrice -
                listingOffer.buyerPrice;
            priceDiff *= quantity;

            require(
                stableCoin.allowance(buyer, address(this)) >= priceDiff,
                "E20"
            );

            price = listingOffer.sellerPrice;

            stableCoin.transferFrom(buyer, address(this), priceDiff);
        } else if (signer == listing.seller) {
            require(listingOffer.isCallable, "E39");
            price = listingOffer.buyerPrice;

            if (listingOffer.sellerCount < 1) {
                listing.remainingQty -= quantity;
            }
        } else {
            revert("E37");
        }

        if (listingOffer.sellerCount >= 1) {
            listing.tokenInHold -= quantity;
        }

        uint256 totalAmount = quantity * price;
        replayNonce[signer]++;

        listingOffer.status = Status.Sold;

        if (listing.remainingQty < 1 && listing.tokenInHold < 1) {
            listing.status = Status.Sold;
        }
        if (marginLoanStatus) {
            uint256 payToSeller = adjustLoan(
                address(listing.token),
                listing.seller,
                totalAmount
            );
            totalAmount = payToSeller;
        }
        if (totalAmount != 0) {
            if (!feeStatus) {
                stableCoin.transfer(listing.seller, totalAmount);
            } else {
                uint256 finalAmount = (totalAmount * feePercentage) / 100 ether;
                stableCoin.transfer(listing.seller, finalAmount);
            }
        }
        listing.token.transfer(buyer, quantity);
        listing.token.updateFromExchange(listing.seller, quantity);

        ///@dev null all offers made on this listing.
        nullOffer(id);

        emit TokensPurchased(
            id,
            buyer,
            listing.seller,
            listing.token,
            quantity,
            price
        );
    }

    /**
     * @dev buyer cancel the given offer
     * @param id: id of offers mapping
     * @param buyer: buyer address
     */

    function cancelBuyer(
        uint256 id,
        address buyer
    ) public override onlyTokenismAdminAndBuyer(id) {
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");

        Offers storage listingOffer = listingOffers[buyer][id];

        require(
            listingOffer.status != Status.Default &&
                listingOffer.status != Status.Canceled,
            "E22"
        );

        uint128 price = listingOffer.buyerPrice;
        address buyerWallet = buyer;
        uint128 quantity = listingOffer.quantity;

        uint128 totalAmount = quantity * price;

        if (listingOffer.sellerCount >= 1) {
            listing.tokenInHold -= quantity;
            listing.remainingQty += quantity;
        }

        listingOffer.status = Status.Canceled;

        stableCoin.transfer(buyerWallet, totalAmount);

        emit BuyerOfferCanceled(listing.token, buyerWallet, quantity, price);
    }

    /**
     * @dev seller: cancel the given offer
     * @param id: id of offers mapping
     * @param buyer: buyer address
     */

    function cancelSeller(
        uint256 id,
        address buyer
    ) public override onlyTokenismAdminAndSeller(id) {
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");

        Offers storage listingOffer = listingOffers[buyer][id];

        require(
            listingOffer.status != Status.Default &&
                listingOffer.status != Status.Canceled,
            "E22"
        );

        ///dev Calculate Amount to send Buyer
        uint128 price = listingOffer.buyerPrice;
        address buyerWallet = buyer;
        uint128 quantity = listingOffer.quantity;
        uint128 totalAmount = quantity * price;

        if (listingOffer.sellerCount >= 1) {
            listing.tokenInHold -= quantity;
            listing.remainingQty += quantity;
        }

        listingOffer.status = Status.Canceled;

        stableCoin.transfer(buyerWallet, totalAmount);

        emit SellerOfferCanceled(
            listing.token,
            listing.seller,
            buyerWallet,
            quantity,
            price
        );
    }

    /**
     * @dev generate hash
     * @param message: information to hash
     * @param nonce: current nonce
     * @return hash
     */

    function makeHash(
        string memory message,
        uint256 nonce
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), message, nonce));
    }

    /**
     * @dev compute signer
     * @param _hash: hash
     * @param _signature: signed hash
     * @return signer address
     */

    function getSigner(
        bytes32 _hash,
        bytes memory _signature
    ) private pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (_signature.length != 65) {
            return address(0);
        }
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            return
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            _hash
                        )
                    ),
                    v,
                    r,
                    s
                );
        }
    }

    /**
     * @dev pay back the loan of seller if any
     * @param token: address or security token
     * @param seller: seller of token (borrower)
     * @param totalAmount: total selling amount of tokens
     * @return remaining akusd amount to be payed to seller after loan payment
     */

    function adjustLoan(
        address token,
        address seller,
        uint256 totalAmount
    ) private returns (uint256) {
        (address[] memory banks, uint256[] memory loanAmounts, , ) = marginLoan
            .getTotalLoanOfToken(seller, token);

        (uint256[] memory ids, uint256[] memory loans) = marginLoan
            .getTotalNoOfTokens(seller, token);

        uint256 len = banks.length;
        if (len > 0) {
            for (uint128 i = 0; i < len; ) {
                if (totalAmount == 0) {
                    break;
                }
                if (loans[i] <= totalAmount) {
                    uint256 remainingAmount = totalAmount - loanAmounts[i];

                    totalAmount = remainingAmount;

                    stableCoin.transfer(banks[i], loanAmounts[i]);
                    marginLoan.updateLoan(seller, ids[i], 0, 1);

                    emit LoanPayed(
                        IERC1400RawERC20(token),
                        seller,
                        banks[i],
                        loanAmounts[i]
                    );
                } else if (loans[i] > totalAmount) {
                    uint256 remainingLoan = loanAmounts[i] - totalAmount;
                    uint256 payableLoan = totalAmount;
                    totalAmount = 0;

                    stableCoin.transfer(banks[i], payableLoan);
                    marginLoan.updateLoan(seller, ids[i], remainingLoan, 2);

                    emit LoanPayed(
                        IERC1400RawERC20(token),
                        seller,
                        banks[i],
                        payableLoan
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }

        return totalAmount;
    }

    /**
     * @dev updateWhiteListing
     * @param newWhitelist: address or security token
     */

    function updateWhiteListing(
        ITokenismWhitelist newWhitelist
    ) external override onlyTokenismAdmin {
        whitelist = newWhitelist;
    }

    /**
     * @dev updateStableCoin
     * @param newStableCoin: address or security token
     */

    function updateStableCoin(
        IStableCoin newStableCoin
    ) external override onlyTokenismAdmin {
        stableCoin = newStableCoin;
    }

    /**
     * @dev updateMarginLoan
     * @param newMarginLoan: address or security token
     */

    function updateMarginLoan(
        IMarginLoan newMarginLoan
    ) external override onlyTokenismAdmin {
        marginLoan = newMarginLoan;
    }

    /**
     * @dev updateInterfaceHash
     * @param interfaceHash: address or security token
     */

    function updateInterfaceHash(
        string calldata interfaceHash
    ) external override onlyTokenismAdmin {
        erc1400InterfaceId = interfaceHash;
    }

    /**
     * @dev setFeeAddress
     * @param newFeeAddress: set fee address
     */

    function setFeeAddress(
        address newFeeAddress
    ) external override onlyTokenismAdmin {
        require(newFeeAddress != address(0), "E33");
        feeAddress = newFeeAddress;
    }

    /**
     * @dev setFeeAmount
     * @param newFeePercentage: set fee percentage
     */

    function setFeePercentage(
        uint128 newFeePercentage
    ) external override onlyTokenismAdmin {
        feePercentage = newFeePercentage;
    }

    /**
     * @dev toggleMarginLoan
     */

    function toggleMarginLoan() external override onlyTokenismAdmin {
        marginLoanStatus = !marginLoanStatus;
    }

    /**
     * @dev toggleFee
     */

    function toggleFee() external override onlyTokenismAdmin {
        // in wei
        feeStatus = !feeStatus;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/**
 * @title ITokenismWhitelist
 * @dev TokenismWhitelist interface
 */
interface ITokenismWhitelist {
    function addWhitelistedUser(
      address _wallet,
      bool _kycVerified,
      bool _accredationVerified,
      uint256 _accredationExpiry
        ) external;
    function getWhitelistedUser(address _wallet) external view returns (address, bool, bool, uint256, uint256);
    function updateKycWhitelistedUser(address _wallet, bool _kycVerified) external;
    function updateAccredationWhitelistedUser(address _wallet, uint256 _accredationExpiry) external;
    function updateTaxWhitelistedUser(address _wallet, uint256 _taxWithholding) external;
    function suspendUser(address _wallet) external;

    function activeUser(address _wallet) external;

    function updateUserType(address _wallet, string calldata _userType) external;
    function isWhitelistedUser(address wallet) external view returns (uint);
    function removeWhitelistedUser(address _wallet) external;
    function isWhitelistedManager(address _wallet) external view returns (bool);

 function removeSymbols(string calldata _symbols) external returns(bool);
 function closeTokenismWhitelist() external;
 function addSymbols(string calldata _symbols)external returns(bool);

  function isAdmin(address _admin) external view returns(bool);
  function isOwner(address _owner) external view returns (bool);
  function isBank(address _bank) external view returns(bool);
  function isSuperAdmin(address _calle) external view returns(bool);
  function isSubSuperAdmin(address _calle) external view returns(bool);
  function getFeeStatus() external returns(uint8);
  function getFeePercent() external view returns(uint8);
  function getFeeAddress()external returns(address);
  function addAdmin(address _newAdmin, string memory _role) external;
  function isManager(address _calle)external returns(bool);
  function userType(address _caller) external view returns(bool);

}