// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./AccessControl.sol";
import "./Subscriptions.sol";

// Uncomment this line to use console.log
// import "hardhat/console.sol";

/// @title NodeID NFT contract that manage NodeID unicity and property
contract NodeIdNFT is ERC721EnumerableUpgradeable, RoleBasedAccessControlled {
    event NewPremintedNFT(uint256 _tokenId, string _nodeId);
    event NewMintedNFT(uint256 _tokenId, address _owner, string _nodeId);
    event BurnNFT(uint256 _tokenId);

    struct Deposit {
        bool isUsed;
        uint256 value;
    }

    /// @notice Each NFT as its own NodeID
    mapping(uint256 => string) public nodeIds;

    /// @notice To prevent a single user from recovering all the nft generated, the user must submit a deposit.
    mapping(address => Deposit[]) private depositedCaution;

    /// @notice The node identifier (NodeID) must remain unique among all NFTs
    mapping(bytes32 => uint256) private hashedNodeIds;

    /// @notice Preminted NFT
    uint256[] public preMintedTokenId;

    /// @notice Preminted blank NFT used to import a staker.key/staker.crt
    uint256[] public preMintedBlankTokenId;

    /// @notice Subscriptions contract address
    address private subscriptions;

    /// @notice Deposit price in avax
    uint256 public cautionPrice;

    /// @notice Public initializer with published default settings
    /// @param _accessControl The c-chain address of access control contract
    function initialize(address _accessControl) public initializer {
        RoleBasedAccessControlled.__RBAC_init(_accessControl);
        ERC721Upgradeable.__ERC721_init("NodeIdNFT", "NID");
        ERC721EnumerableUpgradeable.__ERC721Enumerable_init();

        cautionPrice = 2 * 10 ** 18; // Set deposit price to 2 avax
    }

    /// @notice To deposit caution before calling mint or mintblank function
    function deposit() public payable {
        require(msg.value == cautionPrice, "NodeIdNFT: You must deposit the exact caution price (see getCautionPrice)");

        Deposit memory _deposit = Deposit(false, msg.value);
        depositedCaution[_msgSender()].push(_deposit);
    }

    /// @notice Set subcriptions contract address
    /// @param _subscriptions subscription contract address
    function setSubscriptions(address _subscriptions) public onlyAdmin {
        subscriptions = _subscriptions;
    }

    /// @notice Premint an nft with a nodeid
    /// @dev Only addresses with the role MINTER_ROLE can use this function
    /// @param tokenId token / nft identifier
    /// @param nodeId avalanche NodeID (without "NodeID-")
    function preMint(uint256 tokenId, string memory nodeId) public onlyMinter {
        require(tokenId != 0, "NodeIdNFT: tokendId 0 is reserved"); // otherwise, _existNodeId won't work
        require(_existNodeId(nodeId) == false, "NodeIdNFT: NodeID is already registered");

        _safeMint(_msgSender(), tokenId, "");

        nodeIds[tokenId] = nodeId;
        preMintedTokenId.push(tokenId);
        hashedNodeIds[keccak256(abi.encodePacked(nodeId))] = tokenId;

        emit NewPremintedNFT(tokenId, nodeId);
    }

    /// @notice Premint a blank NFT
    /// @dev NFT blanks are used to let users import their keys.
    /// @param tokenId token / nft identifier
    function preMint(uint256 tokenId) public onlyMinter {
        require(tokenId != 0, "NodeIdNFT: tokendId 0 is reserved"); // otherwise, _existNodeId won't work

        _safeMint(_msgSender(), tokenId, "");
        preMintedBlankTokenId.push(tokenId);

        emit NewPremintedNFT(tokenId, "");
    }

    /// @notice This function defines the nodeid of a blank token. Must be called by our backend after it has received the staker.key and fully secured it.
    /// @param tokenId token / nft identifier
    /// @param nodeId avalanche NodeID (without "NodeID-")
    function setNodeID(uint256 tokenId, string memory nodeId) public onlyMinter {
        // NFT has to be minted and NodeID not set
        _requireMinted(tokenId);
        require(
            keccak256(abi.encodePacked(nodeIds[tokenId])) == keccak256(abi.encodePacked("")),
            "NodeIdNFT: NodeID is already field, can't edit it!"
        );
        require(_existNodeId(nodeId) == false, "NodeIdNFT: NodeID is already registered");

        nodeIds[tokenId] = nodeId;
        hashedNodeIds[keccak256(abi.encodePacked(nodeId))] = tokenId;

        emit NewMintedNFT(tokenId, ownerOf(tokenId), nodeId);
    }

    /// @notice Deposit price could be raised or lowered
    /// @dev The deposit is used as protection against attacks. The aim is to prevent a malicious actor from collecting all NFTs that have no commercial value.
    /// @param _caution new deposit price (example: 2000000000000000000 equals 2 avax)
    function setCautionPrice(uint256 _caution) public onlyBilling {
        cautionPrice = _caution;
    }

    /// @notice Refund one deposit after a user completes its subscription
    /// @dev Public function as we allow billing to refund one user off the actual process
    /// @param user user's address
    function refund(address payable user) public {
        require(
            _msgSender() == subscriptions || isRefunder(_msgSender()),
            "NodeIdNFT: caller is not a refunder user nor subscription contrat"
        );

        require(depositedCaution[user].length > 0, "NodeIdNFT: No caution left to refund");

        uint256 _index = 0;
        uint256 __refund = 0;

        for (uint256 i = 0; i < depositedCaution[user].length; i++) {
            if (depositedCaution[user][i].isUsed == true) {
                _index = i;
                break;
            }
        }

        __refund = depositedCaution[user][_index].value;

        depositedCaution[user][_index] = depositedCaution[user][depositedCaution[user].length - 1];
        depositedCaution[user].pop();

        user.transfer(__refund);
    }

    /// @notice Burn specified tokenId
    /// @dev Only owner / approved account or address with role BURNER_ROLE can use this function
    /// @param tokenId token / nft identifier
    function burn(uint256 tokenId) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId) || isBurner(_msgSender()),
            "NodeIdNFT: caller is not token owner nor approved nor a burner"
        );
        Subscriptions _subscription = Subscriptions(subscriptions);
        require(_subscription.hasNodeIdCurrentSubscription(tokenId) == false, "NodeIdNFT: Can't burn an active NodeID");

        if (_subscription.customerExists(_msgSender())) {
            require(
                _subscription.hasPendingRefund(_msgSender(), tokenId) == false,
                "NodeIdNFT: there is a pending refund, can't burn the token"
            );
        }

        _burn(tokenId);

        emit BurnNFT(tokenId);
    }

    /// @notice Allows users to mint a nodeid nft
    function mint() public {
        uint256 _tokenId;
        require(preMintedTokenId.length > 0, "NodeIdNFT: No premint token available");
        require(
            getFreeDepositOf(_msgSender()) > 0,
            "NodeIdNFT: No deposit! You must deposit a caution prior minting a node ID"
        );

        require(consumeDepositOf(_msgSender()), "NodeIdNFT: Can't consume a caution prior minting you NFT");
        _tokenId = preMintedTokenId[preMintedTokenId.length - 1];
        address owner = ownerOf(_tokenId);
        _transfer(owner, _msgSender(), _tokenId);
        preMintedTokenId.pop();

        emit NewMintedNFT(_tokenId, _msgSender(), nodeIds[_tokenId]);
    }

    /// @notice Allows users to mint a blank nft (used only to import an existing staker.key)
    function mintBlank() public {
        uint256 _tokenId;
        require(preMintedBlankTokenId.length > 0, "NodeIdNFT: No premint token available");
        require(
            getFreeDepositOf(_msgSender()) > 0,
            "NodeIdNFT: No deposit! You must deposit a caution prior minting a node ID"
        );

        require(consumeDepositOf(_msgSender()), "NodeIdNFT: Can't consume a caution prior minting you NFT");
        _tokenId = preMintedBlankTokenId[preMintedBlankTokenId.length - 1];
        address owner = ownerOf(_tokenId);
        _transfer(owner, _msgSender(), _tokenId);
        preMintedBlankTokenId.pop();

        emit NewMintedNFT(_tokenId, _msgSender(), "");
    }

    /// @notice Get how many preminted tokens are availables
    /// @return count The number of preminted tokens
    function getAvailablePreMint() public view returns (uint256) {
        return preMintedTokenId.length;
    }

    /// @notice Get how many preminted blank tokens are availables
    /// @return Count The number of preminted blank tokens
    function getAvailablePreMintBlank() public view returns (uint256) {
        return preMintedBlankTokenId.length;
    }

    /// @notice Get how much a user has deposit (avax)
    /// @param user User's address
    /// @return balance The number of avax a user has deposited
    function getDepositBalanceOf(address user) public view returns (uint256) {
        require(user != address(0), "NodeIdNFT: address zero is not a valid owner");
        uint256 _balance = 0;

        for (uint256 i = 0; i < depositedCaution[user].length; i++) {
            _balance += depositedCaution[user][i].value;
        }

        return _balance;
    }

    /// @notice Get how much a user can claim (avax)
    /// @param user User's address
    /// @return balance The number of avax a user can claim
    function getClaimableBalanceOf(address user) public view returns (uint256) {
        require(user != address(0), "NodeIdNFT: address zero is not a valid owner");
        uint256 _balance = 0;

        for (uint256 i = 0; i < depositedCaution[user].length; i++) {
            if (depositedCaution[user][i].isUsed == true) {
                _balance += depositedCaution[user][i].value;
            }
        }

        return _balance;
    }

    /// @notice Get how many caution(s) a user has deposit and not used
    /// @param user User's address
    /// @return nbDeposit The number of available deposits. In other words, the number of nft a user can request.
    /// @dev Variable nbDeposit is the deposit price multiplier. getFreeDepositOf(user) * cautionPrice = getDepositBalanceOf(user) - getClaimableBalanceOf(user)
    function getFreeDepositOf(address user) public view returns (uint256) {
        require(user != address(0), "NodeIdNFT: address zero is not a valid owner");
        if (depositedCaution[user].length > 0) {
            uint256 _nbDeposit = 0;
            for (uint256 i = 0; i < depositedCaution[user].length; i++) {
                if (depositedCaution[user][i].isUsed == false) {
                    _nbDeposit++;
                }
            }
            return _nbDeposit;
        }
        return 0;
    }

    /// @notice Consumes one user deposit
    /// @param user User's address
    /// @return boolean Returns true if a deposit was used, otherwise false
    function consumeDepositOf(address user) internal returns (bool) {
        if (depositedCaution[user].length > 0) {
            for (uint256 i = 0; i < depositedCaution[user].length; i++) {
                if (depositedCaution[user][i].isUsed == false) {
                    depositedCaution[user][i].isUsed = true;
                    return true;
                }
            }
            return false;
        }
        return false;
    }

    /// @notice Returns baseURI
    /// @return uri Returns baseURI
    function _baseURI() internal pure override returns (string memory) {
        return "https://app.nodz.network/";
    }

    /// @notice checks if a NodeID exists
    /// @return boolean Returns true if NodeID exists, otherwise false
    /// @dev We've implemented this function to ensure that a NodeID remains unique among all NFTs
    function _existNodeId(string memory nodeId) private view returns (bool) {
        return hashedNodeIds[keccak256(abi.encodePacked(nodeId))] != 0;
    }
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

contract AccessControl is AccessControlUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");
    bytes32 public constant BILLING_ROLE = keccak256("BILLING_ROLE");
    bytes32 public constant REFUNDER_ROLE = keccak256("REFUNDER_ROLE");

    function initialize() public initializer {
        _setupRole(ADMIN_ROLE, _msgSender());
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(MINTER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BURNER_ROLE, ADMIN_ROLE);
        _setRoleAdmin(BILLING_ROLE, ADMIN_ROLE);
        _setRoleAdmin(REFUNDER_ROLE, ADMIN_ROLE);
    }
}

contract RoleBasedAccessControlled is Initializable, ContextUpgradeable {
    AccessControl private access;

    // solhint-disable-next-line func-name-mixedcase
    function __RBAC_init(address _accessControl) internal onlyInitializing {
        access = AccessControl(_accessControl);
    }

    modifier onlyAdmin() {
        require(access.hasRole(access.ADMIN_ROLE(), _msgSender()), "not an admin");
        _;
    }

    modifier onlyMinter() {
        require(access.hasRole(access.MINTER_ROLE(), _msgSender()), "not a minter");
        _;
    }

    modifier onlyBurner() {
        require(access.hasRole(access.BURNER_ROLE(), _msgSender()), "not a burner");
        _;
    }

    modifier onlyBilling() {
        require(access.hasRole(access.BILLING_ROLE(), _msgSender()), "not a billing");
        _;
    }

    modifier onlyRefunder() {
        require(access.hasRole(access.REFUNDER_ROLE(), _msgSender()), "not a refunder");
        _;
    }

    function isAdmin(address _address) internal view returns (bool) {
        return access.hasRole(access.ADMIN_ROLE(), _address);
    }

    function isMinter(address _address) internal view returns (bool) {
        return access.hasRole(access.MINTER_ROLE(), _address);
    }

    function isBurner(address _address) internal view returns (bool) {
        return access.hasRole(access.BURNER_ROLE(), _address);
    }

    function isBilling(address _address) internal view returns (bool) {
        return access.hasRole(access.BILLING_ROLE(), _address);
    }

    function isRefunder(address _address) internal view returns (bool) {
        return access.hasRole(access.REFUNDER_ROLE(), _address);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./AccessControl.sol";
import "./Billing.sol";
import "./NodeIdNFT.sol";

/// @title The subscription contract manages user subscriptions, VAT and non-authorized countries.
contract Subscriptions is Initializable, RoleBasedAccessControlled {
    event NewCustomerRegistered(address _wallet, uint16 _countryOfResidence);
    event NewSubscription(
        address _wallet,
        uint256 _tokenId,
        Billing.SubscriptionPeriod _period,
        uint8 _prepaidPeriods,
        string _currency,
        uint256 _startTs,
        uint256 _endTs,
        uint256 _usdPrice,
        uint256 _usdTaxes,
        uint256 _priceRate,
        uint256 _vatRate
    );
    event ReloadSubscription(
        address _wallet,
        uint256 _tokenId,
        Billing.SubscriptionPeriod _period,
        uint8 _addedPeriods,
        string _currency,
        uint256 _startTs,
        uint256 _endTs,
        uint256 _usdPrice,
        uint256 _usdTaxes,
        uint256 _priceRate,
        uint256 _vatRate
    );
    event StopSubscription(address _wallet, uint256 _tokenId, uint256 _startTs, uint256 _endTs, uint256 _blocktime);
    event DestinationWalletChanged(address _oldWallet, address _newWallet);
    event NewRefund(
        address _wallet,
        uint256 _tokenId,
        uint256 _startTs,
        string _currency,
        uint256 _amount,
        uint256 _refundPeriods
    );
    event RefundCompleted(address _wallet, address _payer, uint256 _tokenId, string _currency, uint256 _amount);

    Billing private billing;
    NodeIdNFT private nodeIdToken;
    address public destinationWallet;
    uint256 public validationSlots;
    uint16 public gtcVersion;

    struct Customer {
        bool registered;
        uint16 countryOfResidence;
        uint16 acceptedGtcVersion;
    }

    struct Subscription {
        uint256 startTs;
        uint256 endTs;
        Billing.SubscriptionPeriod period;
        string currencySymbol;
        uint256 priceRate;
        uint256 vatRate;
    }

    struct Refund {
        bool pending;
        string currencySymbol;
        uint256 amount;
    }

    mapping(address => Customer) public customers;

    /// @dev One customer can have multiple active subscriptions, but only for different node id
    /// @notice user's subscriptions
    // NOTE: the SC currently does NOT store history of previous subscriptions
    // NOTE: the SC currently does NOT provide a way to enumerate all subscriptions for a Customer
    mapping(address => mapping(uint256 => Subscription)) public subscriptions;

    /// @notice User's refunds
    mapping(address => mapping(uint256 => Refund)) public refunds;

    /// @notice Gives the subscription end date of a nodeid
    mapping(uint256 => uint256) private nodeidFreeAfter;

    /// @notice Public initializer with published default settings
    /// @param _accessControl The c-chain address of access control contract
    /// @param _billing The c-chain address of billing contract
    /// @param _nodeIdToken The c-chain address of NodeidNFT contract
    /// @param _destinationWallet The c-chain address of the wallet that collects user payments
    function initialize(
        address _accessControl,
        address _billing,
        address _nodeIdToken,
        address _destinationWallet
    ) public initializer {
        RoleBasedAccessControlled.__RBAC_init(_accessControl);
        billing = Billing(_billing);
        nodeIdToken = NodeIdNFT(_nodeIdToken);
        destinationWallet = _destinationWallet;
    }

    /// @notice Set GTC version number
    /// @dev users must accept the latest version
    function setGtcVersion(uint16 _version) public onlyAdmin {
        require(_version > gtcVersion, "new version must be highier than the previous one");
        gtcVersion = _version;
    }

    /// @notice Modifies the destination wallet address that collects user payments
    /// @param _newDestinationWallet The destination wallet address
    function changeDestationWallet(address _newDestinationWallet) public onlyAdmin {
        require(_newDestinationWallet != destinationWallet, "same wallet");
        address _old = destinationWallet;
        destinationWallet = _newDestinationWallet;
        emit DestinationWalletChanged(_old, _newDestinationWallet);
    }

    /// @notice Adds available validation slots
    /// @param _slots Number of slots to add
    function addValidationSlots(uint256 _slots) public onlyMinter {
        validationSlots += _slots;
    }

    /// @notice Removes available validation slots
    /// @param _slots Number of slots to remove
    function removeValidationSlots(uint256 _slots) public onlyMinter {
        validationSlots -= _slots;
    }

    /// @notice Refund user after a subscription
    /// @param _wallet The wallet address to refund
    /// @param _tokenId The NodeidNFT identifier associated to the refund
    function completeRefund(address _wallet, uint256 _tokenId) public onlyRefunder {
        // Check that customer has an active subscription for this nodeId
        require(hasPendingRefund(_wallet, _tokenId) == true, "no pending refund for this wallet & node id");

        Refund memory refund = refunds[_wallet][_tokenId];
        uint256 _amount = billing.usdToCurrency(refund.amount, refund.currencySymbol);

        // Check that Smart Contract is allowed to transfer total amount
        IERC20Upgradeable token = IERC20Upgradeable(billing.currencies(refund.currencySymbol));
        require(token.allowance(_msgSender(), address(this)) >= _amount, "not enough allowance");

        // Transfer tokens to customer
        token.transferFrom(_msgSender(), _wallet, _amount);

        // Change refund status
        refunds[_wallet][_tokenId].pending = false;

        emit RefundCompleted(_wallet, _msgSender(), _tokenId, refund.currencySymbol, refund.amount);
    }

    /// @notice Registers a user that implicitly accept GTC at the same time
    /// @param _countryOfResidence The user's country of residence, which will be used to calculate VAT
    function register(uint16 _countryOfResidence) public {
        require(customerExists(_msgSender()) == false, "Customer already exists");
        require(billing.isValidCountryCode(_countryOfResidence), "Unsupported country code");
        require(billing.isDeniedCountry(_countryOfResidence) == false, "Country is denied by our policy");

        customers[_msgSender()].countryOfResidence = _countryOfResidence;
        customers[_msgSender()].registered = true;
        customers[_msgSender()].acceptedGtcVersion = gtcVersion;

        emit NewCustomerRegistered(_msgSender(), _countryOfResidence);
    }

    /// @notice Allows a user to order a validator
    /// @param _period The subscription period (weekly, monthly, yearly)
    /// @param _tokenId The NodeidNFT identifier
    /// @param _currencySymbol The currency name used to pay the subscription
    /// @param _prepaidPeriods The number of periods a user wants to subscribe
    /// @param _withdrawalRightWaiver The user must explicitly agree to waive the 14-day right of withdrawal.
    function newSubscription(
        Billing.SubscriptionPeriod _period,
        uint256 _tokenId,
        string memory _currencySymbol,
        uint8 _prepaidPeriods, // max 255 prepaid periods
        bool _withdrawalRightWaiver
    ) public {
        // Require that customers waives its 14 days to withdraw right
        require(_withdrawalRightWaiver == true, "You must waive your 14 days withdrawal right");

        // Check that customer is already registered and has accepted latest GTC version
        require(customerExists(_msgSender()), "not a known customer");
        require(customers[_msgSender()].acceptedGtcVersion == gtcVersion, "You must accept our new GTC");

        require(
            billing.isDeniedCountry(customers[_msgSender()].countryOfResidence) == false,
            "Your country of residence is denied by our policy"
        );

        // Nb prepaid periods must be > 0
        require(_prepaidPeriods > 0, "nb of prepaid periods must be at least 1");

        require(nodeIdToken.ownerOf(_tokenId) == _msgSender(), "not owner of nodeId");

        require(
            keccak256(abi.encodePacked(nodeIdToken.nodeIds(_tokenId))) != keccak256(abi.encodePacked("")),
            "nodeId is void"
        );

        require(
            hasActiveSubscription(_msgSender(), _tokenId) == false,
            "already has an active subscription for this node id"
        );

        require(hasNodeIdCurrentSubscription(_tokenId) == false, "nodeid already has a subscription");

        // Check that currency is supported
        require(billing.isSupportedCurrency(_currencySymbol), "not a supported currency");

        require(validationSlots > 0, "no validation slot available, come back later");

        uint256 usdPriceForSubscriptionExclTax = billing.usdPriceExcludingTax(_period, _prepaidPeriods);
        uint256 usdTax = billing.taxAmount(usdPriceForSubscriptionExclTax, customers[_msgSender()].countryOfResidence);

        uint256 totalTokenAmount = billing.usdToCurrency(usdPriceForSubscriptionExclTax + usdTax, _currencySymbol);

        // Check that Smart Contract is allowed to transfer total amount
        IERC20Upgradeable token = IERC20Upgradeable(billing.currencies(_currencySymbol));
        require(token.allowance(_msgSender(), address(this)) >= totalTokenAmount, "not enough allowance");

        /*
         * => https://docs.soliditylang.org/en/v0.8.17/units-and-global-variables.html
         * The current block timestamp must be strictly larger than the timestamp of the last block,
         * but the only guarantee is that it will be somewhere between the timestamps of two consecutive blocks
         * in the canonical chain.
         */
        /* solhint-disable-next-line not-rely-on-time  */
        uint256 _startTs = block.timestamp;
        uint256 _endTs = _startTs;

        if (_period == Billing.SubscriptionPeriod.Week) {
            _endTs = _startTs + (7 days) * uint256(_prepaidPeriods);
        } else if (_period == Billing.SubscriptionPeriod.Month) {
            _endTs = _startTs + (30 days) * uint256(_prepaidPeriods);
        } else if (_period == Billing.SubscriptionPeriod.Year) {
            _endTs = _startTs + (365 days) * uint256(_prepaidPeriods);
        } else {
            revert("Invalid subscription period");
        }

        require((_endTs - _startTs) < 366 days, "subscriptions over 365 days are not allowed");

        // Transfer amount to destinationWallet
        token.transferFrom(_msgSender(), destinationWallet, totalTokenAmount);

        // Store subscription
        uint256 _priceRate = billing.priceRates(uint8(_period));
        uint256 _vatRate = billing.vatRates(customers[_msgSender()].countryOfResidence);
        subscriptions[_msgSender()][_tokenId].startTs = _startTs;
        subscriptions[_msgSender()][_tokenId].endTs = _endTs;
        subscriptions[_msgSender()][_tokenId].period = _period;
        subscriptions[_msgSender()][_tokenId].currencySymbol = _currencySymbol;
        subscriptions[_msgSender()][_tokenId].priceRate = _priceRate;
        subscriptions[_msgSender()][_tokenId].vatRate = _vatRate;

        nodeidFreeAfter[_tokenId] = _endTs;

        // Refund NFT caution
        if (nodeIdToken.getClaimableBalanceOf(_msgSender()) > 0) nodeIdToken.refund(payable(_msgSender()));

        // Remove one validation slot
        validationSlots--;

        emit NewSubscription(
            _msgSender(),
            _tokenId,
            _period,
            _prepaidPeriods,
            _currencySymbol,
            _startTs,
            _endTs,
            usdPriceForSubscriptionExclTax,
            usdTax,
            _priceRate,
            _vatRate
        );
    }

    /// @notice Allows a user to reload an existing subscription
    /// @param _tokenId The Nodeid NFT identifier
    /// @param _addedPeriods The number of added periods
    /// @dev Only allowed on the last period
    function reloadSubscription(uint256 _tokenId, uint8 _addedPeriods) public {
        // Check that customer is already registered and has accepted latest GTC version
        require(customerExists(_msgSender()), "not a known customer");
        require(customers[_msgSender()].acceptedGtcVersion == gtcVersion, "You must accept our new GTC");

        require(
            billing.isDeniedCountry(customers[_msgSender()].countryOfResidence) == false,
            "Your country of residence is denied by our policy"
        );

        // Nb prepaid periods must be > 0
        require(_addedPeriods > 0, "nb of prepaid periods must be at least 1");

        require(nodeIdToken.ownerOf(_tokenId) == _msgSender(), "not owner of nodeId");

        require(
            keccak256(abi.encodePacked(nodeIdToken.nodeIds(_tokenId))) != keccak256(abi.encodePacked("")),
            "nodeId is void"
        );

        require(hasActiveSubscription(_msgSender(), _tokenId), "no active subscription for this node id");

        require(hasNodeIdCurrentSubscription(_tokenId), "nodeid has no subscription");

        Subscription memory currentSubscription = subscriptions[_msgSender()][_tokenId];

        // Check that currency is supported
        require(billing.isSupportedCurrency(currentSubscription.currencySymbol), "not a supported currency");

        uint256 usdPriceForSubscriptionExclTax = billing.usdPriceExcludingTax(
            currentSubscription.period,
            _addedPeriods
        );
        uint256 usdTax = billing.taxAmount(usdPriceForSubscriptionExclTax, customers[_msgSender()].countryOfResidence);

        uint256 totalTokenAmount = billing.usdToCurrency(
            usdPriceForSubscriptionExclTax + usdTax,
            currentSubscription.currencySymbol
        );

        // Check that Smart Contract is allowed to transfer total amount
        IERC20Upgradeable token = IERC20Upgradeable(billing.currencies(currentSubscription.currencySymbol));
        require(token.allowance(_msgSender(), address(this)) >= totalTokenAmount, "not enough allowance");

        /* solhint-disable-next-line not-rely-on-time  */
        uint256 _startTs = currentSubscription.endTs;
        uint256 _endTs = currentSubscription.endTs;

        if (currentSubscription.period == Billing.SubscriptionPeriod.Week) {
            require(
                computeRefundPeriodsOf(_tokenId, _msgSender()) == 0,
                "a weekly subscription can only be reloaded in the last week"
            );
            _endTs = _startTs + (7 days) * uint256(_addedPeriods);
            require((_endTs - _startTs) < 366 days, "a weekly subscription reload can't exceed one year");
        } else if (currentSubscription.period == Billing.SubscriptionPeriod.Month) {
            require(
                computeRefundPeriodsOf(_tokenId, _msgSender()) == 0,
                "a monthly subscription can only be reloaded in the last month"
            );
            _endTs = _startTs + (30 days) * uint256(_addedPeriods);
            require((_endTs - _startTs) < 366 days, "a monthly subscription reload can't exceed one year");
        } else if (currentSubscription.period == Billing.SubscriptionPeriod.Year) {
            _endTs = _startTs + (365 days) * uint256(_addedPeriods);
            require(
                (_endTs - _startTs) < 396 days,
                "a yearly subscription can only be reloaded the last month and only for one more year"
            );
        } else {
            revert("Invalid subscription period");
        }

        // Transfer amount to destinationWallet
        token.transferFrom(_msgSender(), destinationWallet, totalTokenAmount);

        // Store subscription
        uint256 _priceRate = billing.priceRates(uint8(currentSubscription.period));
        uint256 _vatRate = billing.vatRates(customers[_msgSender()].countryOfResidence);

        subscriptions[_msgSender()][_tokenId].endTs = _endTs;
        subscriptions[_msgSender()][_tokenId].priceRate = _priceRate;
        subscriptions[_msgSender()][_tokenId].vatRate = _vatRate;

        nodeidFreeAfter[_tokenId] = _endTs;

        emit ReloadSubscription(
            _msgSender(),
            _tokenId,
            currentSubscription.period,
            _addedPeriods,
            currentSubscription.currencySymbol,
            currentSubscription.startTs,
            _endTs,
            usdPriceForSubscriptionExclTax,
            usdTax,
            _priceRate,
            _vatRate
        );
    }

    /// @notice Allows user to stop/terminate an existing subscription. Unused periods will be refunded
    /// @param  _tokenId The Nodeid NFT identifier
    function stopSubscription(uint256 _tokenId) public {
        // Check that customer has an active subscription for this nodeId
        require(hasActiveSubscription(_msgSender(), _tokenId) == true, "no active subscription for this node id");
        require(
            hasPendingRefund(_msgSender(), _tokenId) == false,
            "a pending refund exists for this node id, can't stop this subscription"
        );

        // Compute amount of periods to refund
        Subscription memory currentSubscription = subscriptions[_msgSender()][_tokenId];

        /* solhint-disable-next-line not-rely-on-time  */
        uint256 refundPeriods = computeRefundPeriodsOf(_tokenId, _msgSender());

        if (refundPeriods > 0) {
            uint256 refundUsdPriceExclTax = currentSubscription.priceRate * refundPeriods;
            uint256 usdTax = (refundUsdPriceExclTax * currentSubscription.vatRate) / 100;

            refunds[_msgSender()][_tokenId].pending = true;
            refunds[_msgSender()][_tokenId].currencySymbol = currentSubscription.currencySymbol;
            refunds[_msgSender()][_tokenId].amount = refundUsdPriceExclTax + usdTax;

            emit NewRefund(
                _msgSender(),
                _tokenId,
                currentSubscription.startTs,
                currentSubscription.currencySymbol,
                refunds[_msgSender()][_tokenId].amount,
                refundPeriods
            );
        }
        // else no refund if no period to refund!
        /* solhint-disable-next-line not-rely-on-time  */
        nodeidFreeAfter[_tokenId] = block.timestamp;

        // Add an available validation slot
        validationSlots++;

        emit StopSubscription(
            _msgSender(),
            _tokenId,
            subscriptions[_msgSender()][_tokenId].startTs,
            subscriptions[_msgSender()][_tokenId].endTs,
            /* solhint-disable-next-line not-rely-on-time  */
            block.timestamp
        );

        /* solhint-disable-next-line not-rely-on-time  */
        subscriptions[_msgSender()][_tokenId].endTs = block.timestamp;
    }

    /// @notice Queries if a user is registered
    /// @param _wallet Customer's wallet address
    /// @return boolean True if the user is registered, otherwise false.
    function customerExists(address _wallet) public view returns (bool) {
        return customers[_wallet].registered;
    }

    /// @notice Queries whether a nodeid is used in an active subscription
    /// @param _tokenId The Nodeid NFT identifier
    /// @return boolean True if the NodeID as an active subscription, otherwise false
    function hasNodeIdCurrentSubscription(uint256 _tokenId) public view returns (bool) {
        /* solhint-disable-next-line not-rely-on-time  */
        return nodeidFreeAfter[_tokenId] > block.timestamp;
    }

    /// @notice Queries if a user has an active subscription for the given nft identifier
    /// @param _wallet Customer's wallet address
    /// @param _tokenId The Nodeid NFT identifier
    /// @return boolean True if the NodeID as an active subscription, otherwise false
    function hasActiveSubscription(address _wallet, uint256 _tokenId) public view returns (bool) {
        require(customerExists(_wallet), "Not a known customer");
        return
            /* solhint-disable-next-line not-rely-on-time  */
            subscriptions[_wallet][_tokenId].startTs != 0 && subscriptions[_wallet][_tokenId].endTs > block.timestamp;
    }

    /// @notice Queries if a user has a pending refund for the given nft identifier
    /// @param _wallet Customer's wallet address
    /// @param _tokenId The Nodeid NFT identifier
    /// @return boolean True if the is a pending refund for the given user's nft
    function hasPendingRefund(address _wallet, uint256 _tokenId) public view returns (bool) {
        // Cannot have a pending refund if the subscription is still active
        if (hasActiveSubscription(_wallet, _tokenId) == true) return false; // TODO: remove this line!!!!
        return refunds[_wallet][_tokenId].pending == true;
    }

    /// @notice Computes how many periods must be refund for a given subscription
    /// @dev _tokenId and _user are used to query the subscription
    /// @param _tokenId The Nodeid NFT identifier
    /// @param _user Customer's wallet address
    /// @return refundPeriods Returns the number of periods to be refunded
    function computeRefundPeriodsOf(uint256 _tokenId, address _user) public view returns (uint256) {
        // Compute amount of periods to refund
        Subscription memory currentSubscription = subscriptions[_user][_tokenId];

        /* solhint-disable-next-line not-rely-on-time  */
        uint256 remainingSec = currentSubscription.endTs - block.timestamp;
        uint256 refundPeriods = 0;
        if (currentSubscription.period == Billing.SubscriptionPeriod.Week) {
            refundPeriods = remainingSec / 7 days;
        } else if (currentSubscription.period == Billing.SubscriptionPeriod.Month) {
            refundPeriods = remainingSec / 30 days;
        } else if (currentSubscription.period == Billing.SubscriptionPeriod.Year) {
            refundPeriods = remainingSec / 365 days;
        } else {
            revert("Invalid subscription period");
        }

        return refundPeriods;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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

// SPDX-License-Identifier: BSL-1.1
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./AccessControl.sol";

/// @title Billing management, including price and country authorization management
contract Billing is Initializable, RoleBasedAccessControlled {
    enum SubscriptionPeriod {
        Week, // 7 days
        Month, // 30 days
        Year // 365 days
    }

    event CurrencyChanged(string symbol, address token);
    event VatRateChanged(uint16 countryISO, uint256 rate);
    event PriceRateChanged(SubscriptionPeriod period, uint256 rate);

    /// @notice List of supported currencies (example: USDT => 0x...)
    mapping(string => address) public currencies;

    /// @notice Indexed VAT rates by country (country ISO 3166 ALPHA-2)
    mapping(uint16 => uint256) public vatRates;

    /// @notice List of unauthorized countries
    mapping(uint16 => bool) public deniedCountry;

    /// @notice List of prices indexed by subscription period
    mapping(uint8 => uint256) public priceRates;

    /// @notice Public initializer with published default settings
    /// @param _accessControl The c-chain address of access control contract
    /// @param _usdtToken The c-chain address of USDT contract
    /// @param _usdtToken The c-chain address of USDC contract
    function initialize(address _accessControl, address _usdtToken, address _usdcToken) public initializer {
        RoleBasedAccessControlled.__RBAC_init(_accessControl);

        currencies["USDT"] = _usdtToken;
        currencies["USDC"] = _usdcToken;

        vatRates[40] = 20; // AT
        vatRates[56] = 21; // BE
        vatRates[100] = 20; // BG
        vatRates[196] = 19; // CY
        vatRates[203] = 21; // CZ
        vatRates[208] = 25; // DK
        vatRates[276] = 19; // DE
        vatRates[233] = 20; // EE
        vatRates[300] = 24; // GR
        vatRates[724] = 21; // ES
        vatRates[246] = 24; // FI
        vatRates[250] = 20; // FR
        vatRates[191] = 25; // HR
        vatRates[380] = 22; // IT
        vatRates[428] = 21; // LV
        vatRates[440] = 21; // LT
        vatRates[442] = 16; // LU
        vatRates[348] = 27; // HU
        vatRates[372] = 23; // IE
        vatRates[470] = 18; // MT
        vatRates[528] = 21; // NL
        vatRates[616] = 23; // PL
        vatRates[620] = 23; // PT
        vatRates[6202] = 16; // PT-20
        vatRates[6203] = 22; // PT-30
        vatRates[642] = 19; // RO
        vatRates[705] = 22; // SI
        vatRates[703] = 20; // SK
        vatRates[752] = 25; // SE

        // Set default denied country
        deniedCountry[112] = true; // Belarus
        deniedCountry[192] = true; // Cuba
        deniedCountry[180] = true; // Democratic Republic of Congo
        deniedCountry[364] = true; // Iran
        deniedCountry[368] = true; // Iraq
        deniedCountry[408] = true; // North Korea
        deniedCountry[729] = true; // Sudan
        deniedCountry[728] = true; // South Sudan
        deniedCountry[760] = true; // Syria
        deniedCountry[716] = true; // Zimbabwe
        deniedCountry[643] = true; // Russian Federation

        priceRates[uint8(SubscriptionPeriod.Week)] = 1500; // 15.00 USD / week
        priceRates[uint8(SubscriptionPeriod.Month)] = 4000; // 40.00 USD / month
        priceRates[uint8(SubscriptionPeriod.Year)] = 40000; // 400.00 USD / year
    }

    /// @notice Adds or remove a country to the list of rejected countries
    /// @param _country The country ISO 3166 ALPHA-2
    /// @param deny If true, the country is to be denied
    function setDeniedCountry(uint16 _country, bool deny) public onlyBilling {
        deniedCountry[_country] = deny;
    }

    /// @notice Modifies a country's VAT rate
    /// @param _countryIso The country ISO 3166 ALPHA-2
    /// @param _rate VAT rate (example: 20 for 20%)
    function setVatRate(uint16 _countryIso, uint256 _rate) public onlyBilling {
        require(isValidCountryCode(_countryIso), "Billing: unsupported country code");
        vatRates[_countryIso] = _rate;
        emit VatRateChanged(_countryIso, _rate);
    }

    /// @notice Adds or remove an accepted currency
    /// @param _currencySymbol The currency name (example: USDT)
    /// @param _token The currency c-chain address
    function setCurrency(string memory _currencySymbol, address _token) public onlyBilling {
        currencies[_currencySymbol] = _token;
        emit CurrencyChanged(_currencySymbol, _token);
    }

    /// @notice Modifies the price of a period
    /// @param _period The period (see SubscriptionPeriod enum)
    /// @param _rate The new rate (example: 1200 for 12.00 / two decimal)
    function setPriceRate(SubscriptionPeriod _period, uint256 _rate) public onlyBilling {
        priceRates[uint8(_period)] = _rate;
        emit PriceRateChanged(_period, _rate);
    }

    /// @notice Modifies the price of a period
    /// @param _country The country ISO 3166 ALPHA-2
    /// @return boolean True if the country is denied
    function isDeniedCountry(uint16 _country) public view returns (bool) {
        return deniedCountry[_country];
    }

    /// @notice Checks that privided country code is valid
    /// @param _countryCode The country ISO 3166 ALPHA-2
    /// @return boolean True if country code is valid, otherwise false
    function isValidCountryCode(uint16 _countryCode) public pure returns (bool) {
        if (_countryCode > 4 && _countryCode < 975) {
            return true;
        }

        if (_countryCode == 6202 || _countryCode == 6203) {
            // Portugal - Azores or Madeira
            return true;
        }

        return false;
    }

    /// @notice Computes and returns the amount with the correct number of decimal digits
    /// @param _amount The amount with two digits (ex: for 12$ contract expects 1200)
    /// @param _symbol The currency name (ex: USDT)
    /// @return amount returns the amount with the correct number of decimal digits
    function usdToCurrency(uint256 _amount, string memory _symbol) public view returns (uint256) {
        require(isSupportedCurrency(_symbol), "Billing: unsupported currency");
        address _tokenAddress = currencies[_symbol];
        ERC20Upgradeable token = ERC20Upgradeable(_tokenAddress);

        // Warning: currently we support only USD stable coins
        // In the futur, we must convert
        return _amount * 10 ** (token.decimals() - 2);
    }

    /// @notice Returns if currency is supported
    /// @param _currencySymbol The currency name (ex: USDT)
    /// @return boolean True if supported otherwise false
    function isSupportedCurrency(string memory _currencySymbol) public view returns (bool) {
        return currencies[_currencySymbol] != address(0);
    }

    /// @notice Computes price given the period and the number of periods
    /// @param _period The period (see SubscriptionPeriod enum)
    /// @param nbPeriods the number of periods (at least 1)
    /// @return price return the price excluding VAT
    function usdPriceExcludingTax(SubscriptionPeriod _period, uint256 nbPeriods) public view returns (uint256) {
        require(nbPeriods > 0, "nbPeriods cannot be 0");

        return nbPeriods * priceRates[uint8(_period)];
    }

    /// @notice Computes the price including VAT
    /// @param _usdAmount The USD amount
    /// @param _countryOfResidence The country ISO 3166 ALPHA-2
    /// @return price return the price including VAT
    function taxAmount(uint256 _usdAmount, uint16 _countryOfResidence) public view returns (uint256) {
        uint256 rate = vatRates[_countryOfResidence];
        return (_usdAmount * rate) / 100;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[44] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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