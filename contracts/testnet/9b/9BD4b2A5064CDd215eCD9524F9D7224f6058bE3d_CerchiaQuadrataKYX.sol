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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.5.0;

import "../storage/QuadGovernanceStore.sol";

interface IQuadGovernance {
    event AttributePriceUpdatedFixed(bytes32 _attribute, uint256 _oldPrice, uint256 _price);
    event BusinessAttributePriceUpdatedFixed(bytes32 _attribute, uint256 _oldPrice, uint256 _price);
    event EligibleAttributeUpdated(bytes32 _attribute, bool _eligibleStatus);
    event EligibleAttributeByDIDUpdated(bytes32 _attribute, bool _eligibleStatus);
    event IssuerAdded(address indexed _issuer, address indexed _newTreasury);
    event IssuerDeleted(address indexed _issuer);
    event IssuerStatusChanged(address indexed issuer, bool newStatus);
    event IssuerAttributePermission(address indexed issuer, bytes32 _attribute,  bool _permission);
    event PassportAddressUpdated(address indexed _oldAddress, address indexed _address);
    event RevenueSplitIssuerUpdated(uint256 _oldSplit, uint256 _split);
    event TreasuryUpdated(address indexed _oldAddress, address indexed _address);
    event PreapprovalUpdated(address indexed _account, bool _status);

    function setTreasury(address _treasury) external;

    function setPassportContractAddress(address _passportAddr) external;

    function updateGovernanceInPassport(address _newGovernance) external;

    function setEligibleAttribute(bytes32 _attribute, bool _eligibleStatus) external;

    function setEligibleAttributeByDID(bytes32 _attribute, bool _eligibleStatus) external;

    function setTokenURI(uint256 _tokenId, string memory _uri) external;

    function setAttributePriceFixed(bytes32 _attribute, uint256 _price) external;

    function setBusinessAttributePriceFixed(bytes32 _attribute, uint256 _price) external;

    function setRevSplitIssuer(uint256 _split) external;

    function addIssuer(address _issuer, address _treasury) external;

    function deleteIssuer(address _issuer) external;

    function setIssuerStatus(address _issuer, bool _status) external;

    function setIssuerAttributePermission(address _issuer, bytes32 _attribute, bool _permission) external;

    function getEligibleAttributesLength() external view returns(uint256);

    function issuersTreasury(address) external view returns (address);

    function eligibleAttributes(bytes32) external view returns(bool);

    function eligibleAttributesByDID(bytes32) external view returns(bool);

    function eligibleAttributesArray(uint256) external view returns(bytes32);

    function setPreapprovals(address[] calldata, bool[] calldata) external;

    function preapproval(address) external view returns(bool);

    function pricePerAttributeFixed(bytes32) external view returns(uint256);

    function pricePerBusinessAttributeFixed(bytes32) external view returns(uint256);

    function revSplitIssuer() external view returns (uint256);

    function treasury() external view returns (address);

    function getIssuersLength() external view returns (uint256);

    function getAllIssuersLength() external view returns (uint256);

    function getIssuers() external view returns (address[] memory);

    function getAllIssuers() external view returns (address[] memory);

    function issuers(uint256) external view returns(address);

    function getIssuerStatus(address _issuer) external view returns(bool);

    function getIssuerAttributePermission(address _issuer, bytes32 _attribute) external view returns(bool);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.5.0;

import "./IQuadPassportStore.sol";
import "./IQuadSoulbound.sol";

interface IQuadPassport is IQuadSoulbound {
    event GovernanceUpdated(address indexed _oldGovernance, address indexed _governance);
    event SetPendingGovernance(address indexed _pendingGovernance);
    event SetAttributeReceipt(address indexed _account, address indexed _issuer, uint256 _fee);
    event BurnPassportsIssuer(address indexed _issuer, address indexed _account);
    event WithdrawEvent(address indexed _issuer, address indexed _treasury, uint256 _fee);

    function setAttributes(
        IQuadPassportStore.AttributeSetterConfig memory _config,
        bytes calldata _sigIssuer,
        bytes calldata _sigAccount
    ) external payable;

    function setAttributesBulk(
        IQuadPassportStore.AttributeSetterConfig[] memory _configs,
        bytes[] calldata _sigIssuers,
        bytes[] calldata _sigAccounts
    ) external payable;


    function setAttributesIssuer(
        address _account,
        IQuadPassportStore.AttributeSetterConfig memory _config,
        bytes calldata _sigIssuer
    ) external payable;

    function attributeKey(
        address _account,
        bytes32 _attribute,
        address _issuer
    ) external view returns (bytes32);

    function burnPassports(uint256 _tokenId) external;

    function burnPassportsIssuer(address _account, uint256 _tokenId) external;

    function setGovernance(address _governanceContract) external;

    function acceptGovernance() external;

    function attribute(address _account, bytes32 _attribute) external view returns (IQuadPassportStore.Attribute memory);

    function attributes(address _account, bytes32 _attribute) external view returns (IQuadPassportStore.Attribute[] memory);

    function withdraw(address payable _to, uint256 _amount) external;

    function passportPaused() external view returns(bool);

    function setTokenURI(uint256 _tokenId, string memory _uri) external;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.5.0;

interface IQuadPassportStore {

    /// @dev Attribute store infomation as it relates to a single attribute
    /// `attrKeys` Array of keys defined by (wallet address/DID + data Type)
    /// `value` Attribute value
    /// `epoch` timestamp when the attribute has been verified by an Issuer
    /// `issuer` address of the issuer issuing the attribute
    struct Attribute {
        bytes32 value;
        uint256 epoch;
        address issuer;
    }

    /// @dev AttributeSetterConfig contains configuration for setting attributes for a Passport holder
    /// @notice This struct is used to abstract setAttributes function parameters
    /// `attrKeys` Array of keys defined by (wallet address/DID + data Type)
    /// `attrValues` Array of attributes values
    /// `attrTypes` Array of attributes types (ex: [keccak256("DID")]) used for validation
    /// `did` did of entity
    /// `tokenId` tokenId of the Passport
    /// `issuedAt` epoch when the passport has been issued by the Issuer
    /// `verifiedAt` epoch when the attribute has been attested by the Issuer
    /// `fee` Fee (in Native token) to pay the Issuer
    struct AttributeSetterConfig {
        bytes32[] attrKeys;
        bytes32[] attrValues;
        bytes32[] attrTypes;
        bytes32 did;
        uint256 tokenId;
        uint256 verifiedAt;
        uint256 issuedAt;
        uint256 fee;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.5.0;

import "../storage/QuadPassportStore.sol";

interface IQuadReader {
    event QueryEvent(address indexed _account, address indexed _caller, bytes32 _attribute);
    event QueryBulkEvent(address indexed _account, address indexed _caller, bytes32[] _attributes);
    event QueryFeeReceipt(address indexed _receiver, uint256 _fee);
    event WithdrawEvent(address indexed _issuer, address indexed _treasury, uint256 _fee);
    event FlashQueryEvent(address indexed _account, address indexed _caller, bytes32 _attribute, uint256 _fee);

    function queryFee(
        address _account,
        bytes32 _attribute
    ) external view returns(uint256);

    function queryFeeBulk(
        address _account,
        bytes32[] calldata _attributes
    ) external view returns(uint256);

    function getAttribute(
        address _account, bytes32 _attribute
    ) external payable returns(QuadPassportStore.Attribute memory attribute);

    function getAttributes(
        address _account, bytes32 _attribute
    ) external payable returns(QuadPassportStore.Attribute[] memory attributes);

    function getAttributesLegacy(
        address _account, bytes32 _attribute
    ) external payable returns(bytes32[] memory values, uint256[] memory epochs, address[] memory issuers);

    function getAttributesBulk(
        address _account, bytes32[] calldata _attributes
    ) external payable returns(QuadPassportStore.Attribute[] memory);

    function getAttributesBulkLegacy(
        address _account, bytes32[] calldata _attributes
    ) external payable returns(bytes32[] memory values, uint256[] memory epochs, address[] memory issuers);

    function balanceOf(address _account, bytes32 _attribute) external view returns(uint256);

    function withdraw(address payable _to, uint256 _amount) external;

    function getFlashAttributeGTE(
        address _account,
        bytes32 _attribute,
        uint256 _issuedAt,
        uint256 _threshold,
        bytes calldata _flashSig
    ) external payable returns(bool);

    function hasPassportByIssuer(address _account, bytes32 _attribute, address _issuer) external view returns(bool);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.5.0;

interface IQuadSoulbound  {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    function uri(uint256 _tokenId) external view returns (string memory);

    /**
     * @dev ERC1155 balanceOf implementation
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.0;

contract QuadConstant {
    bytes32 public constant ISSUER_ROLE = keccak256("ISSUER_ROLE");
    bytes32 public constant GOVERNANCE_ROLE = keccak256("GOVERNANCE_ROLE");
    bytes32 public constant READER_ROLE = keccak256("READER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant DIGEST_TO_SIGN = 0x37937bf5ff1ecbf00bbd389ab7ca9a190d7e8c0a084b2893ece7923be1d2ec85;
    bytes32 internal constant ATTRIBUTE_DID = 0x09deac0378109c72d82cccd3c343a90f7020f0f1af78dcd4fc949c6301aa9488;
    bytes32 internal constant ATTRIBUTE_IS_BUSINESS = 0xaf369ce728c816785c72f1ff0222ca9553b2cb93729d6a803be6af0d2369239b;
    bytes32 internal constant ATTRIBUTE_COUNTRY = 0xc4713d2897c0d675d85b414a1974570a575e5032b6f7be9545631a1f922b26ef;
    bytes32 internal constant ATTRIBUTE_AML = 0xaf192d67680c4285e52cd2a94216ce249fb4e0227d267dcc01ea88f1b020a119;

    uint256[47] private __gap;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.0;

import "../interfaces/IQuadPassport.sol";

import "./QuadConstant.sol";

contract QuadGovernanceStore is QuadConstant {
    // Attributes
    bytes32[] internal _eligibleAttributesArray;
    mapping(bytes32 => bool) internal _eligibleAttributes;
    mapping(bytes32 => bool) internal _eligibleAttributesByDID;

    // TokenId
    mapping(uint256 => bool) internal _eligibleTokenId;

    // Pricing
    mapping(bytes32 => uint256) internal _pricePerBusinessAttributeFixed;
    mapping(bytes32 => uint256) internal _pricePerAttributeFixed;

    // Issuers
    mapping(address => address) internal _issuerTreasury;
    mapping(address => bool) internal _issuerStatus;
    mapping(bytes32 => bool) internal _issuerAttributePermission;
    address[] internal _issuers;

    // Others
    uint256 internal _revSplitIssuer; // 50 means 50%;
    uint256 internal _maxEligibleTokenId;
    IQuadPassport internal _passport;
    address internal _treasury;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity >= 0.8.0;

import "../interfaces/IQuadPassportStore.sol";
import "../interfaces/IQuadGovernance.sol";

import "./QuadConstant.sol";

contract QuadPassportStore is IQuadPassportStore, QuadConstant {

    IQuadGovernance public governance;
    address public pendingGovernance;

    // SignatureHash => bool
    mapping(bytes32 => bool) internal _usedSigHashes;

    string public symbol;
    string public name;

    // Key could be:
    // 1) keccak256(userAddress, keccak256(attrType))
    // 2) keccak256(DID, keccak256(attrType))
    mapping(bytes32 => Attribute[]) internal _attributes;

    // Key could be:
    // 1) keccak256(keccak256(userAddress, keccak256(attrType)), issuer)
    // 1) keccak256(keccak256(DID, keccak256(attrType)), issuer)
    mapping(bytes32 => uint256) internal _position;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaDRTEvents } from "../interfaces/ICerchiaDRTEvents.sol";

/**
 * @title  CerchiaDRT Diamond AnyAccount Interface
 */
interface IAnyAccountOperationsFacet is ICerchiaDRTEvents {
	/**
	 * @notice     For users, to initiate Oracle flow, to get data for index + parameter configuration + timestamp
	 * @dev     Not callable directly by users, but through KYXProvider first
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 */
	function initiateIndexDataUpdate(address callerAddress, bytes32 configurationId, uint64 timestamp) external;

	/**
	 * @notice     For operators, to initiate Oracle flow, to get data for index + parameter configuration + timestamp
	 * @dev     Callable directly by operators
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 */
	function operatorInitiateIndexDataUpdate(bytes32 configurationId, uint64 timestamp) external;

	/**
	 * @param   configurationId  Id of the parameter set to query the off-chain API with, to get the index level
	 * @param   timestamp  Exact timestamp to query the off-chain API with, to get index level
	 * @param   level  The index level provided by the off-chain API
	 */
	function indexDataCallBack(bytes32 configurationId, uint64 timestamp, int128 level) external;

	/**
	 * @notice     For users, to settle a deal (expire/trigger/mature), comparing to index level for given exact timestamp
	 * @dev     Not callable directly by users, but through KYXProvider first
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   timestamp  Exact timestamp to try to settle deal for
	 * @param   dealId  Deal to settle
	 */
	function processContingentSettlement(address callerAddress, uint64 timestamp, uint256 dealId) external;

	/**
	 * @notice     For operators, to settle a deal (expire/trigger/mature), comparing to
	 *              index level for given exact timestamp
	 * @dev         Callable directly by operators
	 * @param       timestamp  Exact timestamp to try to settle deal for
	 * @param       dealId  Deal to settle
	 */
	function operatorProcessContingentSettlement(uint64 timestamp, uint256 dealId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaDRTEvents } from "../interfaces/ICerchiaDRTEvents.sol";

/**
 * @title  CerchiaDRT Diamond Create/Cancel Deal Interface
 */
interface ICerchiaDRT is ICerchiaDRTEvents {
	/**
	 * @notice  Callable by a user, to create a new BidLive deal
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   symbol  Symbol of the standard this deal is based on
	 * @param   denomination  Symbol of the token this deal is based on
	 * @param   notional  Notional of the deal (how much buyer wins if deal triggers, minus fee)
	 * @param   premium  Premium of the deal (how much seller wins if deal matures, minus fee))
	 * @param   expiryDate  Date after which this deal, if not Matched, will expire
	 */
	function userCreateNewDealAsBid(
		address callerAddress,
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external;

	/**
	 * @notice  Callable by a user, to create a new AskLive deal
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   symbol  Symbol of the standard this deal is based on
	 * @param   denomination  Symbol of the token this deal is based on
	 * @param   notional  Notional of the deal (how much buyer wins if deal triggers, minus fee)
	 * @param   premium  Premium of the deal (how much seller wins if deal matures, minus fee))
	 * @param   expiryDate  Date after which this deal, if not Matched, will expire
	 */
	function userCreateNewDealAsAsk(
		address callerAddress,
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external;

	/**
	 * @notice  Callable by a user, to cancel a BidLive/AskLive deal, if user was the initiator
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   dealId  Deal user wants to cancel
	 */
	function userUpdateDealToCancel(address callerAddress, uint256 dealId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICerchiaDRTEvents {
	event OwnerAddedNewStandard(
		address indexed owner,
		string symbol,
		bytes32 configurationId,
		int128 strike,
		uint128 feeInBps,
		uint64 startDate,
		uint64 maturityDate,
		uint8 exponentOfTenMultiplierForStrike
	);

	event OwnerAddedNewToken(address indexed owner, string symbol, address token);

	event NewBid(
		uint256 indexed dealId,
		address indexed initiator,
		string standardSymbol,
		string tokenDenomination,
		uint64 expiryDate,
		uint128 notional,
		uint128 premium
	);

	event NewAsk(
		uint256 indexed dealId,
		address indexed initiator,
		string standardSymbol,
		string tokenDenomination,
		uint64 expiryDate,
		uint128 notional,
		uint128 premium
	);

	event UserUpdateDealToCancel(uint256 indexed dealId, address indexed initiator, uint128 fundsReturned);

	event Match(uint256 indexed dealId, address indexed matcher, uint128 fundsSent);

	event AnyAccountInitiateIndexDataUpdateAlreadyAvailable(bytes32 configurationId, uint64 timestamp, int128 level);

	event IndexDataCallBackSuccess(bytes32 configurationId, uint64 timestamp, int128 level);

	event AutomaticDissolution(address indexed sender, bytes32 indexed configurationId, uint64 timestamp);

	event Claimed(uint256 indexed dealId, address claimer, uint128 fundsClaimed);

	// Emmited by AnyAccountProcessContingentSettlement
	event BidLiveDealExpired(uint256 indexed dealId, address indexed initiator, uint128 fundsReturned);
	event AskLiveDealExpired(uint256 indexed dealId, address indexed initiator, uint128 fundsReturned);
	event MatchedDealWentLive(uint256 indexed dealId);

	event LiveDealTriggered(
		uint256 indexed dealId,
		address indexed buyer,
		uint128 buyerReceived,
		address indexed feeAddress,
		uint128 feeAddressReceived
	);

	event LiveDealMatured(
		uint256 indexed dealId,
		address indexed seller,
		uint128 sellerReceived,
		address indexed feeAddress,
		uint128 feeAddressReceived
	);

	event OwnerDeletedStandard(address indexed owner, string symbol);

	event OwnerDeletedToken(address indexed owner, string symbol);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICerchiaQuadrataKYX {
	function userCreateNewDealAsBid(
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external;

	function userCreateNewDealAsAsk(
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external;

	function userUpdateDealToCancel(uint256 dealId) external;

	function userUpdateDealFromBidToMatched(uint256 dealId) external;

	function userUpdateDealFromAskToMatched(uint256 dealId) external;

	function initiateIndexDataUpdate(bytes32 configurationId, uint64 timestamp) external;

	function processContingentSettlement(uint64 timestamp, uint256 dealId) external;

	function claimBack(uint256 dealId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { ICerchiaDRTEvents } from "../interfaces/ICerchiaDRTEvents.sol";

/**
 * @title  CerchiaDRT Diamond Claimback Interface
 */
interface IClaimBackFacet is ICerchiaDRTEvents {
	/**
	 * @notice  User can claimback their side of a deal, if contract has been dissoluted
	 * @param   callerAddress Address that went through KYXProvider
	 * @param   dealId  Deal to claimback funds from
	 */
	function claimBack(address callerAddress, uint256 dealId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "../interfaces/ICerchiaDRTEvents.sol";

interface IMatchDeal is ICerchiaDRTEvents {
	function userUpdateDealFromBidToMatched(address walletAddress, uint256 dealId) external;

	function userUpdateDealFromAskToMatched(address walletAddress, uint256 dealId) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC1155 } from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import { IQuadReader, IQuadPassportStore } from "@quadrata/contracts/interfaces/IQuadReader.sol";

import { ICerchiaDRT } from "../../interfaces/ICerchiaDRT.sol";
import { IMatchDeal } from "../../interfaces/IMatchDeal.sol";
import { IClaimBackFacet } from "../../interfaces/IClaimBackFacet.sol";
import { IAnyAccountOperationsFacet } from "../../interfaces/IAnyAccountOperationsFacet.sol";
import { ICerchiaQuadrataKYX } from "../../interfaces/ICerchiaQuadrataKYX.sol";

contract CerchiaQuadrataKYX is Ownable, ICerchiaQuadrataKYX {
	IQuadReader private reader;

	address private immutable _cerchiaDiamondAddress;
	address private immutable _quadrataReaderAddress;
	address private immutable _quadrataPassportAddress;

	string public constant NEEDS_TO_PASS_KYX = "301";
	string public constant MISSING_BUSINESS_ATTRIBUTE = "302";
	string public constant IS_NOT_BUSINESS_INVESTOR = "303";
	string public constant MISSING_QUADRATA_PASSPORT = "304";

	/**
	 * @notice  Checks if the calling user holds a Quadrata Passport
	 */
	modifier holdsQuadrataPassport() {
		uint256 balance = IERC1155(_quadrataPassportAddress).balanceOf(msg.sender, 1);
		require(balance > 0, MISSING_QUADRATA_PASSPORT);

		_;
	}

	/**
	 * @notice  Checks if calling user is a business investor
	 */
	modifier isBusinessInvestor() {
		IQuadPassportStore.Attribute[] memory attributes = reader.getAttributes(msg.sender, keccak256("IS_BUSINESS"));
		require(attributes.length > 0, MISSING_BUSINESS_ATTRIBUTE);
		require(attributes[0].value == keccak256("TRUE"), IS_NOT_BUSINESS_INVESTOR);

		_;
	}

	constructor(address cerchiaDiamondAddress, address quadrataReaderAddress, address quadrataPassportAddress) {
		_cerchiaDiamondAddress = cerchiaDiamondAddress;
		_quadrataReaderAddress = quadrataReaderAddress;
		_quadrataPassportAddress = quadrataPassportAddress;

		reader = IQuadReader(_quadrataReaderAddress);
	}

	function userCreateNewDealAsBid(
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external override holdsQuadrataPassport isBusinessInvestor {
		return
			ICerchiaDRT(_cerchiaDiamondAddress).userCreateNewDealAsBid(
				msg.sender,
				symbol,
				denomination,
				notional,
				premium,
				expiryDate
			);
	}

	function userCreateNewDealAsAsk(
		string calldata symbol,
		string calldata denomination,
		uint128 notional,
		uint128 premium,
		uint64 expiryDate
	) external override holdsQuadrataPassport isBusinessInvestor {
		return
			ICerchiaDRT(_cerchiaDiamondAddress).userCreateNewDealAsAsk(
				msg.sender,
				symbol,
				denomination,
				notional,
				premium,
				expiryDate
			);
	}

	function userUpdateDealToCancel(uint256 dealId) external override holdsQuadrataPassport {
		return ICerchiaDRT(_cerchiaDiamondAddress).userUpdateDealToCancel(msg.sender, dealId);
	}

	function userUpdateDealFromBidToMatched(uint256 dealId) external override holdsQuadrataPassport isBusinessInvestor {
		return IMatchDeal(_cerchiaDiamondAddress).userUpdateDealFromBidToMatched(msg.sender, dealId);
	}

	function userUpdateDealFromAskToMatched(uint256 dealId) external override holdsQuadrataPassport isBusinessInvestor {
		return IMatchDeal(_cerchiaDiamondAddress).userUpdateDealFromAskToMatched(msg.sender, dealId);
	}

	function initiateIndexDataUpdate(
		bytes32 configurationId,
		uint64 timestamp
	) external override holdsQuadrataPassport {
		return
			IAnyAccountOperationsFacet(_cerchiaDiamondAddress).initiateIndexDataUpdate(
				msg.sender,
				configurationId,
				timestamp
			);
	}

	function processContingentSettlement(uint64 timestamp, uint256 dealId) external override holdsQuadrataPassport {
		return
			IAnyAccountOperationsFacet(_cerchiaDiamondAddress).processContingentSettlement(
				msg.sender,
				timestamp,
				dealId
			);
	}

	function claimBack(uint256 dealId) external override holdsQuadrataPassport {
		return IClaimBackFacet(_cerchiaDiamondAddress).claimBack(msg.sender, dealId);
	}
}