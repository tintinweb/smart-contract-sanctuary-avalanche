// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
                                      
import {Ownable            } from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard    } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20  } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ICurrencyManager   } from "./interfaces/ICurrencyManager.sol";
import {IStrategyManager   } from "./interfaces/IStrategyManager.sol";
import {IExecutionStrategy } from "./interfaces/IExecutionStrategy.sol";
import {IRoyaltyFeeManager } from "./interfaces/IRoyaltyFeeManager.sol";
import {IExchange          } from "./interfaces/IExchange.sol";
import {ITransferManagerNFT} from "./interfaces/ITransferManagerNFT.sol";
import {ITransferSelector  } from "./interfaces/ITransferSelector.sol";
import {IWAVAX             } from "./interfaces/IWAVAX.sol";
import {OrderTypes         } from "./libraries/OrderTypes.sol";
import {SignatureChecker   } from "./libraries/SignatureChecker.sol";


contract AvaSeaExchange is IExchange, ReentrancyGuard, Ownable {

    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA

    using SafeERC20    for              IERC20                ;
    using OrderTypes   for              OrderTypes.MakerOrder ;
    using OrderTypes   for              OrderTypes.TakerOrder ;
    ICurrencyManager   public           currencyManager       ;
    IStrategyManager   public           strategyManager       ;
    IRoyaltyFeeManager public           royaltyFeeManager     ;
    ITransferSelector  public           transferSelector      ;
    address            public           feeRecipient          ;
    bool               public           paused                ;
    address            public immutable WAVAX                 ;
    bytes32            public immutable DOMAIN_SEPARATOR      ;

    mapping(address => uint256)                  public userMinOrderNonce;
    mapping(address => mapping(uint256 => bool)) private _isUserOrderNonceExecutedOrCancelled;

    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA

    event CurrencyManagerUpdate   (address indexed currencyManager);
    event StrategyManagerUpdate   (address indexed strategyManager);
    event RoyaltyFeeManagerUpdate (address indexed royaltyFeeManager);
    event CancelOrdersBelowNonce  (address indexed user, uint256 newMinNonce);
    event TransferSelectorUpdate  (address indexed transferSelectorNFT);
    event FeeRecipientUpdate      (address indexed protocolFeeRecipient);
    event CancelMultipleOrders    (address indexed user, uint256[] orderNonces);
    event RoyaltyFeeTransfer      (address indexed collection, uint256 indexed tokenId, address indexed royaltyRecipient, address currency, uint256 amount);

    event TakerAsk                (bytes32 orderHash, uint256 orderNonce, address indexed taker, address indexed maker, address indexed strategy,
                                   address currency, address collection, uint256 tokenId, uint256 amount, uint256 price);

    event TakerBid                (bytes32 orderHash, uint256 orderNonce, address indexed taker, address indexed maker, address indexed strategy,
                                   address currency, address collection, uint256 tokenId, uint256 amount, uint256 price);

    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA

    constructor(
        address _currencyManager,
        address _strategyManager,
        address _royaltyFeeManager,
        address _WAVAX,
        address _feeRecipient
    ) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
                0x51ad4688d60759b766bf485a3a7bbdd63f5e5c9085a9cca8a05a996b205c96ac, // keccak256("AvaSeaExchange")
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6, // keccak256(bytes("1")) for versionId = 1
                block.chainid, // chain ID
                address(this) // this contract address
            )
        );

        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        currencyManager   = ICurrencyManager(_currencyManager);
        strategyManager   = IStrategyManager(_strategyManager);
        feeRecipient      = _feeRecipient;
        WAVAX             = _WAVAX;
        paused            = false;
    }

    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // EXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHANGECOREEXCHAN

    /**
     *
     * @param nonce uint256 nonce 
     * @notice sets all orders below the nonce to be invalid
     */
    function cancelOrdersBelowNonce(uint256 nonce) external {
        require(nonce > userMinOrderNonce[msg.sender], "Exchange: {cancelOrdersBelowNonce} nonce lower than sender current nonce");
        require(nonce < userMinOrderNonce[msg.sender] + 999999, "Exchange: {cancelOrdersBelowNonce} too many orders " );
        userMinOrderNonce[msg.sender] = nonce;
        emit CancelOrdersBelowNonce(msg.sender, nonce);
    }

    /**
     *
     * @param nonces uint256[] multiple nonces to cancel
     * @notice sets multiple off chain order to be invalid
     */
    function cancelMultipleOffChainOrders(uint256[] calldata nonces) external {
        require(nonces.length > 0, "Exchange: {cancelMultipleOffChainOrders} No nonces provided");
        for (uint256 i = 0; i < nonces.length; i++) {
            require(nonces[i] >= userMinOrderNonce[msg.sender], "Exchange: {cancelMultipleOffChainOrders} one of the nonces is lower than sender current nonce");
            _isUserOrderNonceExecutedOrCancelled[msg.sender][nonces[i]] = true;
        }
        emit CancelMultipleOrders(msg.sender, nonces);
    }

    /**
     *
     * @param takerBid TakerOrder On chain Buy Order from taker
     * @param makerAsk MakerOrder off chain Sell Order from maker
     * @notice taker buys the off chain order using AVAX, the avax gets wrapped and transfered to the maker
     */
    function matchAskWithTakerBidUsingAVAXAndWAVAX(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk) external payable override nonReentrant{
        require(!paused, "Exchange: Activity is paused");
        require((makerAsk.isAsk) && (!takerBid.isAsk), "Exchange: No match found between orders");
        require(makerAsk.currency == WAVAX, "Exchange: NFT Sell Order currency must be in WAVAX");
        require(takerBid.taker == msg.sender, "Exchange: Buyer must be sender");

        if (takerBid.price > msg.value) {
            IERC20(WAVAX).safeTransferFrom(msg.sender, address(this), (takerBid.price - msg.value));
        }
        else{
            require(takerBid.price == msg.value, "Exchange: Buyer sent extra AVAX");
        }
        IWAVAX(WAVAX).deposit{value: msg.value}();

        bytes32 askHash = makerAsk.hash(); 
        _validateOrder(makerAsk, askHash);

        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerAsk.strategy).canExecuteTakerBid(takerBid, makerAsk);

        require(isExecutionValid,"Exchange: Strategy is not valid");

        _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;

        _transferFeesAndFundsWithWAVAX(
            makerAsk.strategy,
            makerAsk.collection,
            tokenId,
            makerAsk.signer,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        _transferNonFungibleToken(makerAsk.collection, makerAsk.signer, takerBid.taker, tokenId, amount);

        emit TakerBid(
            askHash,
            makerAsk.nonce,
            takerBid.taker,
            makerAsk.signer,
            makerAsk.strategy,
            makerAsk.currency,
            makerAsk.collection,
            tokenId,
            amount,
            takerBid.price
        );
    }

    /**
     *
     * @param takerBid TakerOrder On chain Buy Order from taker
     * @param makerAsk MakerOrder off chain Sell Order from maker
     * @notice taker buys the off chain order using using any ERC20 whitelisted currency then transfered to the maker
     */
    function matchAskWithTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk) external override nonReentrant {
        require(!paused, "Exchange: Activity is paused");
        require((makerAsk.isAsk) && (!takerBid.isAsk), "Exchange: No match found between orders");
        require(takerBid.taker == msg.sender, "Exchange: Buyer must be sender");

         bytes32 askHash = makerAsk.hash(); 
        _validateOrder(makerAsk, askHash);

        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerAsk.strategy).canExecuteTakerBid(takerBid, makerAsk);

        require(isExecutionValid,"Exchange: Trade can not be executed");

        _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;
        
         _transferFeesAndFunds(
            makerAsk.strategy,
            makerAsk.collection,
            tokenId,
            makerAsk.currency,
            msg.sender,
            makerAsk.signer,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        // Execution part 2/2
        _transferNonFungibleToken(makerAsk.collection, makerAsk.signer, takerBid.taker, tokenId, amount);

        emit TakerBid(
            askHash,
            makerAsk.nonce,
            takerBid.taker,
            makerAsk.signer,
            makerAsk.strategy,
            makerAsk.currency,
            makerAsk.collection,
            tokenId,
            amount,
            takerBid.price
        );
    }

    /**
     *
     * @param takerAsk TakerOrder On chain Sell order (ex. sell NFT to bidder) from taker
     * @param makerBid MakerOrder off chain Buy order from maker in most cases is an Auction Bid or Offer 
     * @notice taker sells the asset to the off chain bid order 
     */
    function matchBidWithTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid) external override nonReentrant {
        require(!paused, "Exchange: Activity is paused");
        require((!makerBid.isAsk) && (takerAsk.isAsk), "Exchange: No match found between orders");
        require(takerAsk.taker == msg.sender, "Exchange: Seller must be sender");

        bytes32 bidHash = makerBid.hash(); 
        _validateOrder(makerBid, bidHash);

        (bool isExecutionValid, uint256 tokenId, uint256 amount) = IExecutionStrategy(makerBid.strategy).canExecuteTakerAsk(takerAsk, makerBid);

        require(isExecutionValid, "Exchange: Trade can not be executed");

        _isUserOrderNonceExecutedOrCancelled[makerBid.signer][makerBid.nonce] = true;

        _transferNonFungibleToken(makerBid.collection, takerAsk.taker, makerBid.signer, tokenId, amount);


        _transferFeesAndFunds(makerBid.strategy, makerBid.collection, tokenId, makerBid.currency, makerBid.signer, takerAsk.taker, takerAsk.price, takerAsk.minPercentageToAsk);

        emit TakerAsk(
            bidHash,
            makerBid.nonce,
            takerAsk.taker,
            makerBid.signer,
            makerBid.strategy,
            makerBid.currency,
            makerBid.collection,
            tokenId,
            amount,
            takerAsk.price
        );

    }

    /**
     *
     * @param collection address NFT collection
     * @param from address NFT owner 
     * @param to address NFT Buyer
     * @param tokenId uint256 tokenId
     * @param amount uint256 amount of tokens (for ERC1155)
     * @notice transfer the asset using a whitelisted transfer manager for ERC721 - ERC115 - specific managers for special cases 
     */ 
    function _transferNonFungibleToken(address collection, address from, address to, uint256 tokenId, uint256 amount) internal {
        address _transferManager = transferSelector.checkTransferManagerForToken(collection);
        require(_transferManager != address(0), "Exchange: {_transferNonFungibleToken} No transfer manager found for this collection");
        ITransferManagerNFT(_transferManager).transferToken(collection, from, to, tokenId, amount);
    }

    /**
     *
     * @param strategy address to calculate strategy protocol fee
     * @param collection address to calculate collection royalty fee
     * @param tokenId address to calculate collection royalty fee for a specific tokenId(if exists)
     * @param currency address whitelisted ERC20 currency to pay all parties with
     * @param from address NFT buyer or bidder
     * @param to address NFT Owner or seller
     * @param amount uint256 sale price to transfer
     * @param minPercentageToAsk uint256 protection against sudden changes in royalty fee
     * @notice transfer the Funds using a whitelisted Currency to all parties (protocol - royalty - seller)
     */ 
    function _transferFeesAndFunds(address strategy, address collection, uint256 tokenId, address currency, address from, address to, uint256 amount, uint256 minPercentageToAsk) internal {
        // transfer protocol fee
        uint _finalAmount = amount;
        uint256 _protocolFee = (IExecutionStrategy(strategy).viewProtocolFee() * amount) / 10000 ;
        if ((feeRecipient != address(0)) && (_protocolFee != 0)) {
            IERC20(currency).safeTransferFrom(from, feeRecipient, _protocolFee);
            _finalAmount = _finalAmount - _protocolFee;
        }
        // transfer royalty fee
         (address _royaltyReceipent, uint256 _royaltyFee)= royaltyFeeManager.calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);
         if ((_royaltyReceipent != address(0)) && (_royaltyFee != 0)) {
            IERC20(currency).safeTransferFrom(from, _royaltyReceipent, _royaltyFee);
            _finalAmount = _finalAmount - _royaltyFee;

            emit RoyaltyFeeTransfer(collection, tokenId, _royaltyReceipent, currency, _royaltyFee);
         }
        //transfer fund to seller
        require((_finalAmount * 10000) >= (amount * minPercentageToAsk), "Exchange, Amount sent is below the threshold" );
        IERC20(currency).safeTransferFrom(from, to, _finalAmount);

    }

    /**
     *
     * @param strategy address to calculate strategy protocol fee
     * @param collection address to calculate collection royalty fee
     * @param tokenId address to calculate collection royalty fee for a specific tokenId(if exists)
     * @param to address NFT Owner or seller
     * @param amount uint256 sale price to transfer
     * @param minPercentageToAsk uint256 protection against sudden changes in royalty fee
     * @notice transfer the Funds using a whitelisted Currency to all parties (protocol - royalty - seller)
     */ 
    function _transferFeesAndFundsWithWAVAX(address strategy, address collection, uint256 tokenId, address to, uint256 amount, uint256 minPercentageToAsk) internal {
        uint256 _finalAmount = amount;
        uint256 _protocolFee = (IExecutionStrategy(strategy).viewProtocolFee() * amount) / 10000;        
        if ((feeRecipient != address(0)) && (_protocolFee != 0)) {
            IERC20(WAVAX).safeTransfer(feeRecipient, _protocolFee);
            _finalAmount = _finalAmount - _protocolFee;
        }

        (address _royaltyReceipent, uint256 _royaltyFee)= royaltyFeeManager.calculateRoyaltyFeeAndGetRecipient(collection, tokenId, amount);
        if ((_royaltyReceipent != address(0)) && (_royaltyFee != 0)) {
            IERC20(WAVAX).safeTransfer(_royaltyReceipent, _royaltyFee);
            _finalAmount = _finalAmount - _royaltyFee;

            emit RoyaltyFeeTransfer(collection, tokenId, _royaltyReceipent, WAVAX, _royaltyFee);
        }
        require((_finalAmount * 10000) >= (amount * minPercentageToAsk), "Exchange, Amount sent is below the minPercentageToAsk threshold" );
        IERC20(WAVAX).safeTransfer(to, _finalAmount);

    }

    /**
     *
     * @param makerOrder MakerOrder off chain bid or ask order 
     * @param orderHash bytes32 off chain order hash
     * @notice checks if the order nonce is not canceled , amount > 0 , signer exists , signature is valid , currency is listed , strategy is listed
     */ 
    function _validateOrder(OrderTypes.MakerOrder calldata makerOrder, bytes32 orderHash) internal view {
        require(
            (!_isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.nonce]) &&
                (makerOrder.nonce >= userMinOrderNonce[makerOrder.signer]),
            "Exchange: {_validateOrder} Order cancelled"
        );

        require(makerOrder.signer != address(0), "Exchange: {_validateOrder} Invalid signer address");
        require(makerOrder.amount > 0, "Exchange: {_validateOrder} sale price must be more than 0");
        require(
            SignatureChecker.verify(
                orderHash,
                makerOrder.signer,
                makerOrder.v,
                makerOrder.r,
                makerOrder.s,
                DOMAIN_SEPARATOR
            ),
            "Exchange: {_validateOrder} Signature is Invalid"
        );

        require(currencyManager.isCurrencyListed(makerOrder.currency), "Exchange: {_validateOrder} currnecy is not listed");
        require(strategyManager.isStrategyListed(makerOrder.strategy), "Exchange: {_validateOrder} strategy is not listed");
    }



    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    // AVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEAAVASEA
    
    /**
     *
     * @notice pauses trading for matchBidWithTakerAsk, matchAskWithTakerBid and matchAskWithTakerBidUsingAVAXAndWAVAX
     */
    function pauseActivity() external onlyOwner {
        require(!paused, "Exchange: Already paused");
        paused = true;
    }

    /**
     *
     * @notice unPauses trading for matchBidWithTakerAsk, matchAskWithTakerBid and matchAskWithTakerBidUsingAVAXAndWAVAX
     */
    function unPauseActivity() external onlyOwner {
        require(paused, "Exchange: Already working");
        paused = false;
    }

    /**
     *
     * @param _strategyManager address new contract address
     * @notice updates the strategyManager, only allowed by contract owner
     */
    function updateStrategyManager(address _strategyManager) external onlyOwner {
        require(_strategyManager != address(0), "Exchange: {updateExecutionManager} new strategyManager Cannot be null address");
        strategyManager = IStrategyManager(_strategyManager);
        emit StrategyManagerUpdate(_strategyManager);
    }

    /**
     *
     * @param _transferSelectorNFT address new contract address
     * @notice updates the transferSelectorNFT, only allowed by contract owner
     */
    function updateTransferSelectorNFT(address _transferSelectorNFT) external onlyOwner {
        require(_transferSelectorNFT != address(0), "Exchange: {updateTransferSelectorNFT} new transferSelectorNFT Cannot be null address");
        transferSelector = ITransferSelector(_transferSelectorNFT);
        emit TransferSelectorUpdate(_transferSelectorNFT);
    }

    /**
     *
     * @param _currencyManager address new contract address
     * @notice updates the currencyManager, only allowed by contract owner
     */
    function updateCurrencyManager(address _currencyManager) external onlyOwner {
        require(_currencyManager != address(0), "Exchange: {updateCurrencyManager} new currencyManager Cannot be null address");
        currencyManager = ICurrencyManager(_currencyManager);
        emit CurrencyManagerUpdate(_currencyManager);
    }

    /**
     *
     * @param _royaltyFeeManager address new contract address
     * @notice updates the royaltyFeeManager, only allowed by contract owner
     */
    function updateRoyaltyFeeManager(address _royaltyFeeManager) external onlyOwner {
        require(_royaltyFeeManager != address(0), "Exchange: {updateRoyaltyFeeManager} new royaltyFeeManager Cannot be null address");
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        emit RoyaltyFeeManagerUpdate(_royaltyFeeManager);
    }

    /**
     *
     * @param _feeRecipient address new contract address
     * @notice updates the feeRecipient, only allowed by contract owner
     */
    function updateProtocolFeeRecipient(address _feeRecipient) external onlyOwner {
        feeRecipient = _feeRecipient;
        emit FeeRecipientUpdate(_feeRecipient);
    }

    /**
     *
     * @param user wallet of the user
     * @param orderNonce nonce of the order
     * @notice Check whether user order nonce is executed or cancelled
     */
    function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool) {
        return _isUserOrderNonceExecutedOrCancelled[user][orderNonce];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurrencyManager {

    function listCurrency(address currency) external;

    function delistCurrency(address currency) external;

    function isCurrencyListed(address currency) external view returns (bool);

    function getListedCurrencies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function getListedCurrenciesCount() external view returns (uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStrategyManager {

    function listStrategy(address strategy) external;

    function delistStrategy(address strategy) external;

    function isStrategyListed(address strategy) external view returns (bool);

    function getListedStrategies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function getListedStrategiesCount() external view returns (uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IExecutionStrategy {
    function canExecuteTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function viewProtocolFee() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeManager {

    function calculateRoyaltyFeeAndGetRecipient(address collection, uint256 tokenId, uint256 salePrice) external view returns (address, uint256);
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IExchange {

    function matchAskWithTakerBidUsingAVAXAndWAVAX(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk) external payable;

    function matchAskWithTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)external;

    function matchBidWithTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferManagerNFT {
    function transferToken(address collection, address from, address to, uint256 tokenId, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITransferSelector {
    function checkTransferManagerForToken(address collection) external view returns (address);
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IWAVAX {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library OrderTypes {
    
    bytes32 internal constant MAKER_ORDER_HASH = 0x337e87154a3b7bbf1daf798d210b85bb02a39cebcfa98778f9f74bde68350ed2;
    
    struct MakerOrder {
        bool isAsk;
        address signer;
        address collection;
        uint256 price;
        uint256 tokenId;
        uint256 amount;
        address strategy;
        address currency;
        uint256 nonce;
        uint256 startTime;
        uint256 endTime;
        uint256 minPercentageToAsk;
        bytes params;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct TakerOrder {
        bool isAsk;
        address taker;
        uint256 price;
        uint256 tokenId;
        uint256 minPercentageToAsk;
        bytes params;
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isAsk,
                    makerOrder.signer,
                    makerOrder.collection,
                    makerOrder.price,
                    makerOrder.tokenId,
                    makerOrder.amount,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk,
                    keccak256(makerOrder.params)
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

// https://eips.ethereum.org/EIPS/eip-712#specification

library SignatureChecker {

    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "SignatureChecker: Invalid s parameter"
        );

        require(v == 27 || v == 28, "SignatureChecker: Invalid v parameter");
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "SignatureChecker: Invalid signer");
        return signer;
    }


    function verify(bytes32 hash, address signer, uint8 v, bytes32 r, bytes32 s, bytes32 domainSeparator) internal view returns (bool){
        bytes32 _hash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));
        if (Address.isContract(signer)) {
            return IERC1271(signer).isValidSignature(_hash, abi.encodePacked(r, s, v)) == 0x1626ba7e;//MUST return the bytes4 magic value 0x1626ba7e
        }
        return recover(_hash, v, r, s) == signer;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}