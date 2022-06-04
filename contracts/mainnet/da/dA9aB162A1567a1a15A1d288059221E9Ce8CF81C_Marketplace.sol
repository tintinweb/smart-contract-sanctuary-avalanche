// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/*
      ______      _____            _   _ _____   ____  _      ______ 
     |  ____/\   |  __ \     /\   | \ | |  __ \ / __ \| |    |  ____|
     | |__ /  \  | |__) |   /  \  |  \| | |  | | |  | | |    | |__   
     |  __/ /\ \ |  _  /   / /\ \ | . ` | |  | | |  | | |    |  __|  
     | | / ____ \| | \ \  / ____ \| |\  | |__| | |__| | |____| |____ 
     |_|/_/    \_\_|  \_\/_/    \_\_| \_|_____/ \____/|______|______|

*/

import "../project/SuperAccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract ERC20 {
    function transfer(address _to, uint256 _value) external virtual returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external virtual returns (bool);
}

/**
 * @title NFT Marketplace with ERC-2981 support
 * @notice Defines a marketplace to bid on and sell NFTs.
 *         Sends royalties to rightsholder on each sale if applicable.
 */
contract Marketplace is SuperAccessControl, ReentrancyGuard, Pausable {

    struct SellOffer {
        address seller;
        uint256 price;
        ERC20 currency;
    }

    struct BuyOffer {
        address buyer;
        uint256 price;
        uint256 createTime;
    }

    bytes32 public constant MARKETPLACE_MANAGER_ROLE = keccak256('MARKETPLACE_MANAGER_ROLE');
    bytes32 public constant FEE_SETTER_ROLE = keccak256('FEE_SETTER_ROLE');

    mapping(ERC20 => bool) public acceptedCurrencies; 

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    mapping(address => bool) public tokensAddresses;
    mapping( IERC721 => mapping(uint256 => SellOffer)) public activeSellOffers;
    mapping( IERC721 => mapping(uint256 => mapping(ERC20 => BuyOffer))) public activeBuyOffers;
    mapping(IERC721 => mapping(address => mapping(uint256 => mapping(ERC20 =>uint256)))) public buyOffersEscrow;

    bool public allowBuyOffers = false;
    uint public offersDuration = 180;

    address public farandoleWallet;

    uint public feePerMil;
    uint public constant MAX_FEE_PERMIL = 100;
    uint public transferMaxGas = 5000;


    event NewSellOffer(IERC721 token, uint256 tokenId, address seller, uint256 value, ERC20 currency);
    event NewBuyOffer(IERC721 token, uint256 tokenId, address buyer, uint256 value, ERC20 currency);
    event SellOfferWithdrawn(IERC721 token, uint256 tokenId, address seller);
    event BuyOfferWithdrawn(IERC721 token, uint256 tokenId, address buyer, ERC20 currency);
    event Sale(IERC721 token, uint256 tokenId, address seller, address buyer, uint256 value, ERC20 currency);
    event RoyaltiesAndFeesPaid(IERC721 token, uint256 tokenId, uint royaltyAmount, address royaltiesReceiver, uint feesAmount, address farandoleWallet);
    event OfferDurationChanged(uint newDuration);
    event TokenAdded(address tokenContract);
    event CurrencyAdded(ERC20 currency);
    event CurrencyRemoved(ERC20 currency);


    constructor(address superAdminAddressContract,
                address _farandoleWallet,
                uint16 _feePerMil,
                address[] memory _tokensAddresses,
                ERC20[] memory _acceptedCurrencies
    ) SuperAccessControl(superAdminAddressContract) {
        farandoleWallet = _farandoleWallet;
        require(_feePerMil <= MAX_FEE_PERMIL, 'unvalid fee feePerMil');
        feePerMil = _feePerMil;

        setupTokens(_tokensAddresses);
        setupAcceptedCurrencies(_acceptedCurrencies);
    }

    function setupTokens(address[] memory _tokensAddresses)
    internal {
        for(uint i=0; i<_tokensAddresses.length; i++){
            require(_checkRoyalties(_tokensAddresses[i]), 'contract is not IERC2981');
            tokensAddresses[_tokensAddresses[i]] = true;
            emit TokenAdded(_tokensAddresses[i]);
        }
    }

    function addTokens(address[] memory _tokensAddresses)
    public onlySuperRole(MARKETPLACE_MANAGER_ROLE) {
        for(uint i=0; i<_tokensAddresses.length; i++){
            require(_checkRoyalties(_tokensAddresses[i]), 'contract is not IERC2981');
            tokensAddresses[_tokensAddresses[i]] = true;
            emit TokenAdded(_tokensAddresses[i]);
        }
    }

    function setupAcceptedCurrencies(ERC20[] memory _acceptedCurrencies)
    internal {
        for(uint i=0; i<_acceptedCurrencies.length; i++){
            if(!acceptedCurrencies[_acceptedCurrencies[i]]){
              acceptedCurrencies[_acceptedCurrencies[i]] = true;
              emit CurrencyAdded(_acceptedCurrencies[i]);
            }
        }
    }

    function addAcceptedCurrencies(ERC20[] memory _acceptedCurrencies)
    public onlySuperRole(MARKETPLACE_MANAGER_ROLE) {
        for(uint i=0; i<_acceptedCurrencies.length; i++){
            if(!acceptedCurrencies[_acceptedCurrencies[i]]){
              acceptedCurrencies[_acceptedCurrencies[i]] = true;
              emit CurrencyAdded(_acceptedCurrencies[i]);
            }
        }
    }

    function removeAcceptedCurrencies(ERC20[] memory _notAcceptedCurrencies)
    public onlySuperRole(MARKETPLACE_MANAGER_ROLE) {
        for(uint i=0; i<_notAcceptedCurrencies.length; i++){
            if(acceptedCurrencies[_notAcceptedCurrencies[i]]){
              acceptedCurrencies[_notAcceptedCurrencies[i]] = false;
              emit CurrencyRemoved(_notAcceptedCurrencies[i]);
            }
        }
    }     

    function _checkRoyalties(address _contract)
    internal view returns (bool) {
        return IERC2981(_contract).supportsInterface(_INTERFACE_ID_ERC2981);
    }

    function _taxTxn(address sender, IERC721 token, uint tokenId, uint grossSaleValue, ERC20 currency)
    internal virtual returns (uint) {
        uint paidFees = _payFees(sender, grossSaleValue, currency);
        (uint paidRoyalties, address receiver) = _payRoyalties(sender, token, tokenId, grossSaleValue, currency);
        emit RoyaltiesAndFeesPaid(token, tokenId, paidRoyalties, receiver, paidFees, farandoleWallet);
        return grossSaleValue - (paidRoyalties + paidFees);
    }

    function _payFees(address sender, uint grossSaleValue, ERC20 currency)
    internal returns (uint) {
        uint feesAmount = grossSaleValue*feePerMil/1000;

        if (feesAmount > 0) {
            _processPayment(sender, farandoleWallet, feesAmount, currency);
        }

        return feesAmount;
    }

    function _payRoyalties(address sender, IERC721 token, uint256 tokenId, uint256 grossSaleValue, ERC20 currency)
    internal returns (uint, address) {
        (address royaltiesReceiver, uint256 royaltiesAmount) = IERC2981(address(token)).royaltyInfo(tokenId, grossSaleValue);
        if (royaltiesAmount > 0) {
            _processPayment(sender, royaltiesReceiver, royaltiesAmount, currency);
        }
        return (royaltiesAmount, royaltiesReceiver);
    }

    function _processPayment(address sender, address receiver, uint amount, ERC20 currency)
    internal {
        if (currency == ERC20(address(0))) {
          (bool sent, ) = payable(receiver).call{value: amount, gas: transferMaxGas}('');
          require(sent, "Could not transfer amount to receiver");
        } else {
            if (sender == address(this)) {
              require(currency.transfer(receiver, amount), "transfer failed");
            } else {
              require(currency.transferFrom(sender, receiver, amount), "transferFrom failed");
            }
        }
    }

    function makeSellOffer(IERC721 token, uint256 tokenId, uint256 price, ERC20 currency)
    external tokenOnMarketplace(token) isMarketable(token, tokenId) whenNotPaused
    tokenOwnerOnly(token, tokenId) isAcceptedCurrency(currency) nonReentrant {
        activeSellOffers[token][tokenId] = SellOffer({
            seller : _msgSender(),
            price : price,
            currency: currency
            });

        emit NewSellOffer(token, tokenId, _msgSender(), price, currency);
    }

    function withdrawSellOffer(IERC721 token, uint256 tokenId)
    external tokenOnMarketplace(token) isMarketable(token, tokenId) nonReentrant {

        SellOffer memory activeSellOffer = activeSellOffers[token][tokenId];
        require(activeSellOffer.seller != address(0), "No sale offer");

        bool isAdmin = hasSuperRole(MARKETPLACE_MANAGER_ROLE, _msgSender());

        require(activeSellOffer.seller == _msgSender() || isAdmin, "Not seller nor owner");

        if (isAdmin && activeSellOffer.seller != _msgSender()) {
            require(token.getApproved(tokenId) != address(this), "token is still approved");
        }

        delete (activeSellOffers[token][tokenId]);
        emit SellOfferWithdrawn(token, tokenId, _msgSender());
    }

    function purchase(IERC721 token, uint256 tokenId)
    external tokenOnMarketplace(token) tokenOwnerForbidden(token, tokenId) nonReentrant payable {

        SellOffer memory activeSellOffer = activeSellOffers[token][tokenId];
        ERC20 currency = activeSellOffer.currency;

        address seller = activeSellOffer.seller;
        require(seller != address(0), "No active sell offer");

        uint netSaleValue = _taxTxn(_msgSender(), token, tokenId, activeSellOffer.price, currency);

        if (currency == ERC20(address(0))) {
            require(msg.value == activeSellOffer.price, "value doesn't match offer");
            _processPayment(_msgSender(), seller, netSaleValue, currency);
        } else {
            require(msg.value == 0, "sent value would be lost");
            require(currency.transferFrom(_msgSender(), seller, netSaleValue), "transferFrom failed");
        }

        token.safeTransferFrom(seller, _msgSender(), tokenId);

        delete (activeSellOffers[token][tokenId]);
        delete (activeBuyOffers[token][tokenId][currency]);

        emit Sale(token, tokenId, seller, _msgSender(), activeSellOffer.price, currency);
    }

    function makeBuyOffer(IERC721 token, uint256 tokenId, uint value, ERC20 currency)
    external tokenOnMarketplace(token) tokenOwnerForbidden(token, tokenId)
    buyOffersAllowed isAcceptedCurrency(currency) nonReentrant whenNotPaused
    payable {
        if (activeSellOffers[token][tokenId].price != 0 && activeSellOffers[token][tokenId].currency == currency ) {
            require((value < activeSellOffers[token][tokenId].price), "Sell order at this price or lower exists");
        }

        require(activeBuyOffers[token][tokenId][currency].createTime < (block.timestamp - offersDuration*(1 days)) ||
                value > activeBuyOffers[token][tokenId][currency].price, "Previous buy offer higher or not expired");
        address previousBuyOfferOwner = activeBuyOffers[token][tokenId][currency].buyer;
        uint256 refundBuyOfferAmount = buyOffersEscrow[token][previousBuyOfferOwner][tokenId][currency];

        buyOffersEscrow[token][previousBuyOfferOwner][tokenId][currency] = 0;
        if (refundBuyOfferAmount > 0) {
            _processPayment(address(this), previousBuyOfferOwner, refundBuyOfferAmount, currency);
        }

        activeBuyOffers[token][tokenId][currency] = BuyOffer({
            buyer : _msgSender(),
            price : value,
            createTime : block.timestamp
        });

        buyOffersEscrow[token][_msgSender()][tokenId][currency] = value;

        if (currency == ERC20(address(0))) {
            require(msg.value == value, "value doesn't match offer");
        } else {
            require(msg.value == 0, "sent value would be lost");
            require(currency.transferFrom(_msgSender(), address(this), value), "transferFrom failed");
        }

        emit NewBuyOffer(token, tokenId, _msgSender(), value, currency);
    }

    function withdrawBuyOffer(IERC721 token, uint256 tokenId, ERC20 currency)
    external nonReentrant {
        address buyer = activeBuyOffers[token][tokenId][currency].buyer;

        require(buyer == _msgSender() || hasSuperRole(MARKETPLACE_MANAGER_ROLE, _msgSender()) , "Not buyer or owner");
        uint256 refundBuyOfferAmount = buyOffersEscrow[token][buyer][tokenId][currency];

        buyOffersEscrow[token][buyer][tokenId][currency] = 0;

        delete(activeBuyOffers[token][tokenId][currency]);

        if (refundBuyOfferAmount > 0) {
            _processPayment(address(this), buyer, refundBuyOfferAmount, currency);
        }

        emit BuyOfferWithdrawn(token, tokenId, _msgSender(), currency);
    }

    function acceptBuyOffer(IERC721 token, uint256 tokenId, ERC20 currency)
    external tokenOnMarketplace(token) isMarketable(token, tokenId) tokenOwnerOnly(token, tokenId) nonReentrant {
        address currentBuyer = activeBuyOffers[token][tokenId][currency].buyer;
        require(currentBuyer != address(0),"No buy offer");

        uint256 saleValue = activeBuyOffers[token][tokenId][currency].price;
        uint256 netSaleValue = _taxTxn(address(this), token, tokenId, saleValue, currency);

        delete (activeSellOffers[token][tokenId]);
        delete (activeBuyOffers[token][tokenId][currency]);

        buyOffersEscrow[token][currentBuyer][tokenId][currency] = 0;

        _processPayment(address(this), _msgSender(), netSaleValue, currency);
        token.safeTransferFrom(_msgSender(),currentBuyer,tokenId);

        emit Sale(token, tokenId, _msgSender(), currentBuyer, saleValue, currency);
    }

    function setAllowBuyOffers(bool newValue)
    external onlySuperRole(MARKETPLACE_MANAGER_ROLE) {
        allowBuyOffers = newValue;
    }

    function setOffersDuration(uint newDuration)
    external onlySuperRole(MARKETPLACE_MANAGER_ROLE) {
        require(newDuration>0, 'newDuration is null');
        offersDuration = newDuration;
        emit OfferDurationChanged(newDuration);
    }

    function setFeePerMil(uint16 _newFeePerMil)
    external onlySuperRole(FEE_SETTER_ROLE) {
        require(_newFeePerMil <= MAX_FEE_PERMIL, 'unvalid fee feePerMil');
        feePerMil = _newFeePerMil;
    }

    function setTransferMaxGas(uint16 _newTransferMaxGas)
    external onlySuperRole(MARKETPLACE_MANAGER_ROLE) {
        require(_newTransferMaxGas > 2300, 'transferMaxGas must be > 2300');
        transferMaxGas = _newTransferMaxGas;
    }

    function pause()
    external onlySuperRole(CONTRACTS_ROLE) {
        _pause();
    }    

    function unpause()
    external onlySuperRole(CONTRACTS_ROLE) {
        _unpause();
    }        

    modifier tokenOnMarketplace(IERC721 token) {
        require(tokensAddresses[address(token)], "Token is not on marketplace");
        _;
    }

    modifier isMarketable(IERC721 token, uint256 tokenId) {
        require(token.getApproved(tokenId) == address(this), "Not approved");
        _;
    }

    modifier tokenOwnerForbidden(IERC721 token, uint256 tokenId) {
        require(token.ownerOf(tokenId) != _msgSender(), "Token owner not allowed");
        _;
    }

    modifier tokenOwnerOnly(IERC721 token, uint256 tokenId) {
        require(token.ownerOf(tokenId) == _msgSender(), "Not token owner");
        _;
    }

    modifier buyOffersAllowed() {
        require(allowBuyOffers, "making new buy offer is not allowed");
        _;
    }

    modifier isAcceptedCurrency(ERC20 currency) {
        require(acceptedCurrencies[currency], "Currency is not accepted");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract ISuperAdmin{
    function checkRole(bytes32 role, address account) public view virtual;
    function paused() public view virtual returns (bool);
    function hasRole(bytes32 role, address account) public view virtual returns (bool);
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32);    
}

abstract contract ISuperAdminAddress{
    function name() external pure virtual returns (string memory);
    function getAddress() external view virtual returns (address);
}

abstract contract SuperAccessControl is Context {
    
    bytes32 public constant CONTRACTS_ROLE = keccak256('CONTRACTS_ROLE');

    ISuperAdminAddress public superAdminAddressContract;

    constructor(address _superAdminAddressContract) {
        _checkName(_superAdminAddressContract);
        superAdminAddressContract = ISuperAdminAddress(_superAdminAddressContract);
    }

    modifier whenNotSuperPaused() {
        require(!ISuperAdmin(superAdminAddressContract.getAddress()).paused(), "Pausable: paused");
        _;
    }

    modifier whenSuperPaused() {
        require(ISuperAdmin(superAdminAddressContract.getAddress()).paused(), "Pausable: not paused");
        _;
    }

    modifier onlySuperRole(bytes32 role) {
       checkSuperRole(role, _msgSender());
       _;
    }    

    function checkSuperRole(bytes32 role, address account)
    public view virtual {
        ISuperAdmin(superAdminAddressContract.getAddress()).checkRole(role, account);
    }

    function hasSuperRole(bytes32 role, address account)
    public view virtual returns (bool) {
        return ISuperAdmin(superAdminAddressContract.getAddress()).hasRole(role, account);
    }

    function getSuperRoleAdmin(bytes32 role)
    public view virtual returns (bytes32) {
        return ISuperAdmin(superAdminAddressContract.getAddress()).getRoleAdmin(role);
    }    

    /*
        This function should be used only if SuperAdminAddress needs to be redeployed
        However SuperAdminAddress is meant to allow redeploying SuperAdmin while keeping the same proxy address
        for all contracts to querry (the address of SuperAdminAddress).
        The contract SuperAdminAddress is simple enough that it should not be redeployed in practice,
        because it's address would need to be replaced in all SuperAccessControl contracts, but it's still possible here
    */
    function setSuperAdminAddressContract(address newSuperAdminAddressContract)
    external virtual onlySuperRole(CONTRACTS_ROLE) {
        _checkName(newSuperAdminAddressContract);
        superAdminAddressContract = ISuperAdminAddress(newSuperAdminAddressContract);
    }

    // for safety, check the new address is the right kind of contract
    function _checkName(address superAdminAddress)
    internal pure {
        require( keccak256(bytes(ISuperAdminAddress(superAdminAddress).name()))
                 == keccak256(bytes('Farandole SuperAdminAddress')),
                'Trying to set the wrong contract address');       
    }    

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
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