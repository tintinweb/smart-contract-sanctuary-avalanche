/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-03
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

/**
 * Strings Library
 *
 * In summary this is a simple library of string functions which make simple
 * string operations less tedious in solidity.
 *
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 *
 * @author James Lockhart <[email protected]>
 */
library Strings {
    /**
     * Concat (High gas cost)
     *
     * Appends two strings together and returns a new value
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory)
    {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(
            _baseBytes.length + _valueBytes.length
        );
        bytes memory _newValue = bytes(_tmpValue);

        uint256 i;
        uint256 j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int256)
    {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(
        string memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int256(i);
            }
        }

        return -1;
    }

    /**
     * Length
     *
     * Returns the length of the specified string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base) internal pure returns (uint256) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     *
     * Extracts the beginning part of a string based on the desired length
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string memory _base, int256 _length)
        internal
        pure
        returns (string memory)
    {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     *
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(
        string memory _base,
        int256 _length,
        int256 _offset
    ) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint256(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint256(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint256 j = 0;
        for (
            uint256 i = uint256(_offset);
            i < uint256(_offset + _length);
            i++
        ) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }

    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr)
    {
        bytes memory _baseBytes = bytes(_base);

        uint256 _offset = 0;
        uint256 _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) break;
            else {
                _splitsCount++;
                _offset = uint256(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int256(_baseBytes.length);
            }

            string memory _tmp = new string(uint256(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint256 j = 0;
            for (uint256 i = _offset; i < uint256(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint256(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     *
     * Compares the characters of two strings, to ensure that they have an
     * identical footprint
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool)
    {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint256 i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     *
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string memory _base, string memory _value)
        internal
        pure
        returns (bool)
    {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint256 i = 0; i < _baseBytes.length; i++) {
            if (
                _baseBytes[i] != _valueBytes[i] &&
                _upper(_baseBytes[i]) != _upper(_valueBytes[i])
            ) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     *
     * Converts all the values of a string to their corresponding upper case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string
     */
    function upper(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     *
     * Converts all the values of a string to their corresponding lower case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string
     */
    function lower(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     *
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /**
     * Lower
     *
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
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
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    using Strings for string;

    //////////////////////
    ////    Fields    ////
    //////////////////////

    ////    Standard ERC20 Fields    ////

    // name of token
    string private _name;

    // symbol of token
    string private _symbol;

    // total supply of toekn
    uint256 private _totalSupply;

    // token allowance of addresses
    mapping(address => mapping(address => uint256)) private _allowances;

    // token balance of addresses
    mapping(address => uint256) private _balances;

    ////    Commodity Token Fields    ////

    /*  ROLES   */

    // owner
    address private _owner;

    // Asset Protection
    address private _assetProtection;

    // candidate Asset Protection
    address private _candidateAssetProtection;

    // token supply manager
    address private _tokenSupplyManager;

    // whitelist manager
    address private _whitelistManager;

    // fee manager
    address private _feeManager;

    // Treasurer
    address private _treasurer;

    /*  WhiteLists Fields   */

    // global whitelist addresses status
    mapping(address => bool) private _globalWhitelistAddressesStatus;

    // global whitelist addresses
    address[] private _globalWhitelistAddresses;

    // creation/redemption whitelist addresses status
    mapping(address => bool) private _CRWhitelistAddressesStatus;

    // creation/redemption whitelist addresses
    address[] private _CRWhitelistAddresses;

    // transfer whitelist addresses Status
    mapping(address => bool) private _transferWhitelistAddressesStatus;

    // transfer whitelist addresses
    address[] private _transferWhitelistAddresses;

    /*  Freezing Transactions Fields   */

    // FreezAllTransactios
    bool private _freezAllTransactions = false;

    // freezing specific accounts transactions
    mapping(address => bool) private _freezedAccountsStatus;

    // list of account freezed
    address[] private _freezedAccounts;

    /*  Fee Fields   */

    // fee decimals
    uint256 private _feeDecimals = 18;

    // createion fee
    uint256 private _creationFee = 2500000000000000;

    // redemption fee
    uint256 private _redemptionFee = 2500000000000000;

    // transfer fee
    uint256 private _transferFee = 1000000000000000;

    // min transfer amount
    uint256 private _minTransferAmount = 1000;

    // min creation amount
    uint256 private _minCreationAmount = 4000;

    // min redemption amount
    uint256 private _minRedemptionAmount = 4000;

    /*  Holders Field  */

    // holders status
    mapping(address => bool) private _holdersStatus;

    // list of addresses holding tokens
    address[] private _holders;

    ///////////////////////////
    ////    Constructor    ////
    ///////////////////////////

    // constructor
    constructor(
        string memory name_,
        string memory symbol_,
        address assetProtection_,
        address tokenSupplyManager_,
        address whitelistManager_,
        address feeManager_,
        address treasurer_
    ) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
        _assetProtection = assetProtection_;
        _tokenSupplyManager = tokenSupplyManager_;
        _whitelistManager = whitelistManager_;
        _feeManager = feeManager_;
        _treasurer = treasurer_;
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    ////    Standard ERC20 Events    ////

    ////    Commodity Token Events    ////

    // freezing all transactions by owner
    event freezeAllTransactionsEvent(
        address indexed ownerAddress,
        uint256 indexed timestamp
    );

    // un-freeze all transactions by owner
    event unFreezeAllTransactionsEvent(
        address indexed ownerAddress,
        uint256 indexed timestamp
    );

    // freez an account event
    event freezeAccountEvent(
        address indexed AssetProtection,
        address indexed account,
        uint256 indexed timestamp
    );

    // un-freeze and account event
    event unFreezeAccountEvent(
        address indexed AssetProtection,
        address indexed account,
        uint256 indexed timestamp
    );

    // wipe freezed account event
    event wipeFreezedAccountEvent(
        address indexed AssetProtection,
        address indexed account,
        uint256 balance,
        uint256 indexed timestamp
    );

    // freeze and wipe an account event
    event freezeAndWipeAccountEvent(
        address indexed AssetProtection,
        address indexed account,
        uint256 balance,
        uint256 indexed timestamp
    );

    // withdraw tokens send to contract address
    event withdrawContractTokensEvent(
        address indexed contractAddress,
        address indexed treasurerAddress,
        uint256 amount,
        uint256 indexed timestamp
    );

    // update owner address
    event updateOwnerEvent(
        address indexed previousOwnerAddress,
        address indexed newOwnerAddress,
        uint256 indexed timestamp
    );

    // update token supply manager
    event updateTokenSupplyManagerEvent(
        address ownerAccount,
        address indexed previousTokenSupplyManagerAddress,
        address indexed newTokenSupplyManager,
        uint256 indexed timestamp
    );

    // creation basket event
    event creationBasketEvent(
        address indexed tokenSupplyManager,
        address indexed receiverAddress,
        address treasurer,
        string creationType,
        uint256 receiverAmount,
        uint256 creationFeeAmount,
        bool isWhitelisted,
        uint256 indexed timestamp
    );

    // redemption basket event
    event redemptionBasketEvent(
        address indexed tokenSupplyManager,
        address indexed senderAddress,
        address treasurer,
        uint256 amountBurned,
        uint256 redemptionFeeAmount,
        bool isWhitelisted,
        uint256 indexed timestamp
    );

    // set candidate Asset Protection
    event setCandidateAssetProtectionEvent(
        address indexed sender,
        address indexed candidateAssetProtection,
        uint256 indexed timestamp
    );

    // update Asset Protection acount
    event updateAssetProtectionEvent(
        address indexed previousAssetProtectionAddress,
        address indexed newAssetProtectionAddress,
        uint256 indexed timestamp
    );

    // update whitelist manager address
    event updateWhitelistManagerEvent(
        address ownerAccount,
        address indexed previousWhitelistManagerAddress,
        address indexed newWhitelistManager,
        uint256 indexed timestamp
    );

    // append account to global whitelist addresses
    event appendToGlobalWhitelistEvent(
        address indexed whitelistManager,
        address indexed account,
        uint256 indexed timestamp
    );

    // remove account from global whitelist addresses
    event removeFromGlobalWhitelistEvent(
        address indexed whitelistManager,
        address indexed account,
        uint256 indexed timestamp
    );

    // append account to creation/redemption whitelist addresses
    event appendToCRWhitelistEvent(
        address indexed whitelistManager,
        address account,
        uint256 indexed timestamp
    );

    // remove account from creation/redemption whitelist addresses
    event removeFromCRWhitelistEvent(
        address indexed whitelistManager,
        address account,
        uint256 indexed timestamp
    );

    // append account to transfer whitelist addresses
    event appendToTransferWhitelistEvent(
        address indexed whitelistManager,
        address account,
        uint256 indexed timestamp
    );

    // remove account from transfer whitelist addresses
    event removeFromTransferWhitelistEvent(
        address indexed whitelistManager,
        address account,
        uint256 indexed timestamp
    );

    // update fee manager
    event updateFeeManagerEvent(
        address ownerAccount,
        address indexed previousFeeManagerAddress,
        address indexed newFeeManager,
        uint256 indexed timestamp
    );

    // update Treasurer
    event updateTreasurerEvent(
        address ownerAddress,
        address indexed previousTreasurerAddress,
        address indexed newTreasurer,
        uint256 indexed timestamp
    );

    // set fee decimals
    event setFeeDecimalsEvent(
        address indexed sender,
        uint256 previousFeeDecimals,
        uint256 newFeeDecimals,
        uint256 indexed timestamp
    );

    // set creation fee
    event setCreationFeeEvent(
        address indexed sender,
        uint256 previousCreationFee,
        uint256 newCreationFee,
        uint256 indexed timestamp
    );

    // set redemption fee
    event setRedemptionFeeEvent(
        address indexed sender,
        uint256 previousRedemptionFee,
        uint256 newRedemptionFee,
        uint256 indexed timestamp
    );

    // set transfer fee
    event setTransferFeeEvent(
        address indexed sender,
        uint256 previousTransferFee,
        uint256 newTransferFee,
        uint256 indexed timestamp
    );

    // update min transfer amount
    event minTransferAmountEvent(
        address indexed FeeSuperviso,
        uint256 previousMinTransferAmount,
        uint256 newMinTransferAmount,
        uint256 indexed timestamp
    );

    // update min creation amount
    event minCreationAmountEvent(
        address indexed sender,
        uint256 previousMinCreationAmount,
        uint256 newMinCreationAmount,
        uint256 indexed timestamp
    );

    // update min redemption amount
    event minRedemptionAmountEvent(
        address indexed sender,
        uint256 previousMinRedemptionAmount,
        uint256 newMinRedemptionAmount,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    ////    Standard ERC20 Modifiers    ////

    ////    Commodity Token Modifiers    ////

    // All Transactions Not Freezed
    modifier AllTransactionsNotFreezed() {
        require(!_freezAllTransactions, "All transactions are freezed!");
        _;
    }

    // only Owner
    modifier onlyOwner() {
        require(msg.sender == _owner, "Sender is not the owner address!");
        _;
    }

    // only Token Supply Manager
    modifier onlyTokenSupplyManager() {
        require(
            msg.sender == _tokenSupplyManager,
            "Sender is not the token supply manager address!"
        );
        _;
    }

    // only Asset Protection
    modifier onlyAssetProtection() {
        require(
            msg.sender == _assetProtection,
            "Sender is not the Asset Protection address!"
        );
        _;
    }

    // only whitelist manager
    modifier onlyWhitelistManager() {
        require(
            msg.sender == _whitelistManager,
            "Sender is not the whitelist manager address!"
        );
        _;
    }

    // only fee manager
    modifier onlyFeeManager() {
        require(
            msg.sender == _feeManager,
            "Sender is not the fee manager address!"
        );
        _;
    }

    // only Treasurer
    modifier onlyTreasurer() {
        require(
            msg.sender == _treasurer,
            "Sender is not the Treasurer address!"
        );
        _;
    }

    // only one role for one address
    modifier onlyOneRole(address account_) {
        // require the account not be the owner
        require(account_ != _owner, "Account cannot be the owner!");
        _;

        // require the account not be the Asset Protection
        require(
            account_ != _assetProtection,
            "Account cannot be the Asset Protection!"
        );
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        require(account_ != address(0), "Account can not be zero address!");
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    ////    Standard ERC20    ////

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to_, uint256 amount_)
        public
        virtual
        override
        AllTransactionsNotFreezed
        returns (bool)
    {
        // require amount > 0
        require(amount_ > 0, "Amount should be greater than zero!");

        // sender account
        address owner_ = _msgSender();

        // require sender be not freezed
        _requireNotFreezed(owner_);

        // require to be not freezed
        _requireNotFreezed(to_);

        // transfer amount from sender to to address
        _transfer(owner_, to_, amount_);

        // return
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner_, address spender_)
        public
        view
        virtual
        override
        AllTransactionsNotFreezed
        returns (uint256)
    {
        // require sender be not freezed
        _requireNotFreezed(owner_);

        // require spender be not freezed
        _requireNotFreezed(spender_);

        return _allowances[owner_][spender_];
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
    function approve(address spender_, uint256 amount_)
        public
        virtual
        override
        AllTransactionsNotFreezed
        returns (bool)
    {
        // require sender be not freezed
        _requireNotFreezed(msg.sender);

        // require spender be not freezed
        _requireNotFreezed(spender_);

        address owner_ = _msgSender();
        _approve(owner_, spender_, amount_);
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
        address from_,
        address to_,
        uint256 amount_
    ) public virtual override AllTransactionsNotFreezed returns (bool) {
        address spender_ = _msgSender();

        // require sender be not freezed
        _requireNotFreezed(msg.sender);

        // require from_ be not freezed
        _requireNotFreezed(from_);

        // require to_ be not freezed
        _requireNotFreezed(to_);

        _spendAllowance(from_, spender_, amount_);
        _transfer(from_, to_, amount_);
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
    function increaseAllowance(address spender_, uint256 addedValue_)
        public
        virtual
        AllTransactionsNotFreezed
        returns (bool)
    {
        // require sender be not freezed
        _requireNotFreezed(msg.sender);

        // require spender be not freezed
        _requireNotFreezed(spender_);

        address owner_ = _msgSender();
        _approve(owner_, spender_, allowance(owner_, spender_) + addedValue_);
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
    function decreaseAllowance(address spender_, uint256 subtractedValue_)
        public
        virtual
        AllTransactionsNotFreezed
        returns (bool)
    {
        // require sender be not freezed
        _requireNotFreezed(msg.sender);

        // require spender be not freezed
        _requireNotFreezed(spender_);

        address owner_ = _msgSender();
        uint256 currentAllowance = allowance(owner_, spender_);
        require(
            currentAllowance >= subtractedValue_,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner_, spender_, currentAllowance - subtractedValue_);
        }

        return true;
    }

    /// Getters  ///

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
    function balanceOf(address account_)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account_];
    }

    //// Commodity Token Public Functions   ////

    /*   Only Owner Functions    */

    ///  Role Updating Functions

    // update Owner
    function updateOwner(address newOwner_)
        public
        onlyOwner
        notNullAddress(newOwner_)
    {
        // previous owner address
        address previousOwnerAddress = _owner;

        // update owner address to new owner address
        _owner = newOwner_;

        // emit event
        emit updateOwnerEvent(previousOwnerAddress, _owner, block.timestamp);
    }

    // set candidate Asset Protection
    function setCandidateAssetProtection(
        address candidateAssetProtectionAddress_
    )
        public
        onlyOneRole(candidateAssetProtectionAddress_)
    // notNullAddress(candidateAssetProtectionAddress_)
    {
        // require sender by either owner or current account superivsor
        require(
            msg.sender == _owner || msg.sender == _assetProtection,
            "Sender is not the owner or Asset Protection address!"
        );

        // update the candidate Asset Protection address
        _candidateAssetProtection = candidateAssetProtectionAddress_;

        // emit setting candidate Asset Protection
        emit setCandidateAssetProtectionEvent(
            msg.sender,
            _candidateAssetProtection,
            block.timestamp
        );
    }

    // update Asset Protection
    function updateAssetProtection() public onlyOwner {
        // previous Asset Protection address
        address previousAssetProtectionAddress = _assetProtection;

        // update Asset Protection address to candidate Asset Protection address
        _assetProtection = _candidateAssetProtection;

        // set candiate Asset Protection address to zero
        _candidateAssetProtection = address(0);

        // emit event
        emit updateAssetProtectionEvent(
            previousAssetProtectionAddress,
            _assetProtection,
            block.timestamp
        );
    }

    // update candidate token supply manager
    function updateTokenSupplyManager(address tokenSupplyManagerAddress_)
        public
        onlyOwner
        onlyOneRole(tokenSupplyManagerAddress_)
        notNullAddress(tokenSupplyManagerAddress_)
    {
        // previous token supply manager address
        address previousTokenSupplyManagerAddress = _tokenSupplyManager;

        // update token supply manager address
        _tokenSupplyManager = tokenSupplyManagerAddress_;

        // emit event
        emit updateTokenSupplyManagerEvent(
            msg.sender,
            previousTokenSupplyManagerAddress,
            _tokenSupplyManager,
            block.timestamp
        );
    }

    // update whitelist manager
    function updateWhitelistManager(address whitelistManagerAddress_)
        public
        onlyOwner
        onlyOneRole(whitelistManagerAddress_)
        notNullAddress(whitelistManagerAddress_)
    {
        // previous whitelist manager address
        address previousWhitelistManagerAddress = _whitelistManager;

        // update whitelist manager address
        _whitelistManager = whitelistManagerAddress_;

        // emit event
        emit updateWhitelistManagerEvent(
            msg.sender,
            previousWhitelistManagerAddress,
            _whitelistManager,
            block.timestamp
        );
    }

    // update fee manager
    function updateFeeManager(address feeManagerAddress_)
        public
        onlyOwner
        onlyOneRole(feeManagerAddress_)
        notNullAddress(feeManagerAddress_)
    {
        // previous fee manager address
        address previousFeeManagerAddress = _feeManager;

        // update fee manager
        _feeManager = feeManagerAddress_;

        // emit event
        emit updateFeeManagerEvent(
            msg.sender,
            previousFeeManagerAddress,
            _feeManager,
            block.timestamp
        );
    }

    // update Treasurer
    function updateTreasurer(address newTreasurer_)
        public
        onlyOwner
        onlyOneRole(newTreasurer_)
        notNullAddress(newTreasurer_)
    {
        // previous Treasurer address
        address previousTreasurerAddress = _treasurer;

        // update Treasurer address
        _treasurer = newTreasurer_;

        // emit event
        emit updateTreasurerEvent(
            msg.sender,
            previousTreasurerAddress,
            _treasurer,
            block.timestamp
        );
    }

    // freeze all transactions
    function freezeAllTransactions() public onlyOwner {
        // require all transactions be already unfrozen
        require(
            !_freezAllTransactions,
            "All transactions are already freezed!"
        );

        // set value for freeze all transactions
        _freezAllTransactions = true;

        // emit freezing all transactions event
        emit freezeAllTransactionsEvent(msg.sender, block.timestamp);
    }

    // un-freeze all transactions
    function unFreezeAllTransactions() public onlyOwner {
        // require all transactions be already freezed
        require(
            _freezAllTransactions,
            "All transactions are already unfreezed!"
        );

        // set value for freeze all transactions
        _freezAllTransactions = false;

        // emit un-freeze all transaction event
        emit unFreezeAllTransactionsEvent(msg.sender, block.timestamp);
    }

    /*    Only Asset Protection Functions    */

    // freeze an account
    function freezeAccount(address account_)
        public
        onlyAssetProtection
        notNullAddress(account_)
    {
        // require account not be already freezed
        _requireNotFreezed(account_);

        // add account to freezed account and update account freeze status
        _appendToFreezedAccounts(account_);

        // emit event
        emit freezeAccountEvent(msg.sender, account_, block.timestamp);
    }

    // un-freeze and account
    function unFreezeAccount(address account_)
        public
        onlyAssetProtection
        notNullAddress(account_)
    {
        // require account be already freezed
        _requireFreezed(account_);

        // remove account to freezed account and update account freeze status
        _removeFromFreezedAccounts(account_);

        // emit event
        emit unFreezeAccountEvent(msg.sender, account_, block.timestamp);
    }

    // wipe freezed account
    function wipeFreezedAccount(address account_)
        public
        onlyAssetProtection
        notNullAddress(account_)
    {
        // require account bre freezed
        _requireFreezed(account_);

        // get balance of the freezed account
        uint256 balance_ = _balances[account_];

        // burn account balance
        _burn(account_, balance_);

        // emit event for wipe freezed acount
        emit wipeFreezedAccountEvent(
            msg.sender,
            account_,
            balance_,
            block.timestamp
        );
    }

    // freeze and wipe an account
    function freezeAndWipeAccount(address account_)
        public
        onlyAssetProtection
        notNullAddress(account_)
    {
        // require account not be already freezed
        _requireNotFreezed(account_);

        // add account to freezed account and update account freeze status
        _appendToFreezedAccounts(account_);

        // get balance of the freezed account
        uint256 balance_ = _balances[account_];

        // burn account balance
        _burn(account_, balance_);

        // emit event freezing and wiping the account
        emit freezeAndWipeAccountEvent(
            msg.sender,
            account_,
            balance_,
            block.timestamp
        );
    }

    /*    Only Token Supply Manager Functions    */

    // creation basket
    function creationBasket(
        uint256 amount_,
        address receiverAddress_,
        string memory basketType_
    )
        public
        onlyTokenSupplyManager
        notNullAddress(receiverAddress_)
        returns (bool)
    {
        if (
            basketType_.upper().compareTo("CASH") ||
            (basketType_.upper().compareTo("TOKEN") &&
                _CRWhitelistAddressesStatus[receiverAddress_]) ||
            (basketType_.upper().compareTo("TOKEN") &&
                _globalWhitelistAddressesStatus[receiverAddress_])
        ) {
            _mint(receiverAddress_, amount_);
            // emit creation basket event
            emit creationBasketEvent(
                msg.sender,
                receiverAddress_,
                _treasurer,
                basketType_,
                amount_,
                0,
                _CRWhitelistAddressesStatus[receiverAddress_],
                block.timestamp
            );

            // return
            return true;
        } else if (basketType_.upper().compareTo("TOKEN")) {
            // require amount > min creation amount
            require(
                amount_ > _minCreationAmount,
                "Amount should be greater than min creation amount!"
            );

            // creation fee amount
            uint256 creationFeeAmount = (amount_ * _creationFee) /
                (10**_feeDecimals);
            // received amount
            uint256 receivedAmount = amount_ - creationFeeAmount;

            // mint received amount to receiver address (deducting CR-fee)
            _mint(receiverAddress_, receivedAmount);

            // mint cR-fee to treasurer.
            _mint(_treasurer, creationFeeAmount);

            // emit creation basket event
            emit creationBasketEvent(
                msg.sender,
                receiverAddress_,
                _treasurer,
                basketType_,
                receivedAmount,
                creationFeeAmount,
                _CRWhitelistAddressesStatus[receiverAddress_],
                block.timestamp
            );

            // return
            return true;
        } else {
            require(false, "Creation type should either be CASH or TOKEN!");

            // return false
            return false;
        }
    }

    // redemption basket
    function redemptionBasket(uint256 amount_, address senderAddress_)
        public
        onlyTokenSupplyManager
        notNullAddress(senderAddress_)
        returns (bool)
    {
        // balance of sender address
        uint256 balance = _balances[senderAddress_];

        // require sender balance be greater than amount
        require(amount_ <= balance, "Balance of the sender address is low!");

        // require amount > min redemption amount
        require(
            amount_ > _minRedemptionAmount,
            "Amount should be greater than min redemption amount!"
        );

        if (
            _CRWhitelistAddressesStatus[senderAddress_] ||
            _globalWhitelistAddressesStatus[senderAddress_]
        ) {
            // burn tokens from senderAddress
            _burn(senderAddress_, amount_);

            // emit redemption event
            emit redemptionBasketEvent(
                msg.sender,
                senderAddress_,
                _treasurer,
                amount_,
                0,
                _CRWhitelistAddressesStatus[senderAddress_],
                block.timestamp
            );

            // return
            return true;
        } else {
            // redemption fee amount
            uint256 redemptionFeeAmount = (amount_ * _redemptionFee) /
                (10**_feeDecimals);

            // transfer
            _transfer(senderAddress_, _treasurer, redemptionFeeAmount);

            // burn
            _burn(senderAddress_, amount_ - redemptionFeeAmount);

            // emit redemption event
            emit redemptionBasketEvent(
                msg.sender,
                senderAddress_,
                _treasurer,
                amount_ - redemptionFeeAmount,
                redemptionFeeAmount,
                _CRWhitelistAddressesStatus[senderAddress_],
                block.timestamp
            );

            // return
            return true;
        }
    }

    /*    Only Treasurer Functions    */

    // withdraw tokens from contract to Treasurer account
    function withdrawContractTokens() external onlyTreasurer {
        // get balanche of the VE Token Contract
        uint256 balance_ = _balances[address(this)];

        if(balance_ > 0 ){
            _transfer(address(this), _treasurer, balance_);
        }
        
        // emit WidthrawContractTokens
        emit withdrawContractTokensEvent(
            address(this),
            msg.sender,
            balance_,
            block.timestamp
        );
    }

    /*    Only Whitelist Manager Functions    */

    // add account to global whitelist
    function appendToGlobalWhitelist(address account_)
        public
        onlyWhitelistManager
        notNullAddress(account_)
    {
        // require address not be whitelisted
        require(
            !_globalWhitelistAddressesStatus[account_],
            "This address is already in the global whitelist!"
        );

        // add account to global whitelist and update the status
        _appendToGlobalWhitelistAddresses(account_);

        // emit event
        emit appendToGlobalWhitelistEvent(
            msg.sender,
            account_,
            block.timestamp
        );
    }

    // remove account from global whitelist
    function removeFromGlobalWhitelist(address account_)
        public
        onlyWhitelistManager
        notNullAddress(account_)
    {
        // require account be already whitelisted
        require(
            _globalWhitelistAddressesStatus[account_],
            "This address is not in global whitelist!"
        );

        // remove account from global whitelist and update the status
        _removeFromGlobalWhitelistAddresses(account_);

        // emit event
        emit removeFromGlobalWhitelistEvent(
            msg.sender,
            account_,
            block.timestamp
        );
    }

    // add account to creation/redemption whitelist
    function appendToCRWhitelist(address account_)
        public
        onlyWhitelistManager
        notNullAddress(account_)
    {
        // require address not be in creation/redemption whitelist
        require(
            !_CRWhitelistAddressesStatus[account_],
            "This address is already in the creation/redemption whitelist!"
        );

        // add the address to CR whitelistAddresses and update status
        _appendToCRWhitelistAddresses(account_);

        // emit event
        emit appendToCRWhitelistEvent(
            msg.sender,
            account_,
            block.timestamp
        );
    }

    // remove account from creation/redemption whitelist
    function removeFromCRWhitelist(address account_)
        public
        onlyWhitelistManager
        notNullAddress(account_)
    {
        // require account be already whitelisted
        require(
            _CRWhitelistAddressesStatus[account_],
            "This address is not in creation/redemption whitelist!"
        );

        // remove address from creation/redemption whitelist and update status
        _removeFromCRWhitelistAddresses(account_);

        // emit event
        emit removeFromCRWhitelistEvent(
            msg.sender,
            account_,
            block.timestamp
        );
    }

    // add account to transfer whitelist
    function appendToTransferWhitelist(address account_)
        public
        onlyWhitelistManager
        notNullAddress(account_)
    {
        // require address not be in transfer whitelist
        require(
            !_transferWhitelistAddressesStatus[account_],
            "This address is already in the transfer whitelist!"
        );

        // add the address to transfer whitelistAddresses and update status
        _appendToTransferWhitelistAddresses(account_);

        // emit event
        emit appendToTransferWhitelistEvent(
            msg.sender,
            account_,
            block.timestamp
        );
    }

    // remove account from transfer whitelist
    function removeFromTransferWhitelist(address account_)
        public
        onlyWhitelistManager
        notNullAddress(account_)
    {
        // require account be already whitelisted
        require(
            _transferWhitelistAddressesStatus[account_],
            "This address is not in transfer whitelist!"
        );

        // remove address from transfer whitelist and update status
        _appendToTransferWhitelistAddresses(account_);

        // emit event
        emit removeFromTransferWhitelistEvent(
            msg.sender,
            account_,
            block.timestamp
        );
    }

    /*    Only Fee Manager Functions    */

    // set fee decimals
    function setFeeDecimals(uint256 feeDecimals_) public onlyFeeManager {
        // require fee decimals be greater than zero
        require(
            feeDecimals_ >= 0,
            "Fee decimals should be greater than or equal to zero!"
        );

        // previous fee decimals
        uint256 previousFeeDecimals = _feeDecimals;

        // update fee decimals
        _feeDecimals = feeDecimals_;

        // emit event
        emit setFeeDecimalsEvent(
            msg.sender,
            previousFeeDecimals,
            _feeDecimals,
            block.timestamp
        );

        // update min transfer amount
        // _minTransferAmount = (10**_feeDecimals) / _transferFee;

        // emit event
        emit minTransferAmountEvent(
            msg.sender,
            (10**previousFeeDecimals) / _transferFee,
            (10**_feeDecimals) / _transferFee,
            block.timestamp
        );

        // update min creation amount
        // _minCreationAmount = (10**_feeDecimals) / _creationFee;

        // emit event
        emit minCreationAmountEvent(
            msg.sender,
            (10**previousFeeDecimals) / _creationFee,
            (10**_feeDecimals) / _creationFee,
            block.timestamp
        );

        // update min redemption amount
        // _minRedemptionAmount = (10**_feeDecimals) / _redemptionFee;

        // emit event
        emit minRedemptionAmountEvent(
            msg.sender,
            (10**previousFeeDecimals) / _redemptionFee,
            (10**_feeDecimals) / _redemptionFee,
            block.timestamp
        );
    }

    // set creation fee
    function setCreationFee(uint256 creationFee_) public onlyFeeManager {
        // require creation fee be greater than zero
        require(creationFee_ >= 0, "Creation fee should be greater than zero!");

        // previous creation fee
        uint256 previousCreationFee = _creationFee;

        // update creation fee
        _creationFee = creationFee_;

        // emit event
        emit setCreationFeeEvent(
            msg.sender,
            previousCreationFee,
            _creationFee,
            block.timestamp
        );

        // // update min creation amount
        // _minCreationAmount = (10**_feeDecimals) / _creationFee;

        // emit event
        emit minCreationAmountEvent(
            msg.sender,
            (10**_feeDecimals) / previousCreationFee,
            (10**_feeDecimals) / _creationFee,
            block.timestamp
        );
    }

    // set redemption fee
    function setRedemptionFee(uint256 redemptionFee_) public onlyFeeManager {
        // require redemption fee be greater than zero
        require(
            redemptionFee_ >= 0,
            "Redemption fee should be greater than zero!"
        );

        // previous redemption fee
        uint256 previousRedemptionFee = _redemptionFee;

        // update redemption fee
        _redemptionFee = redemptionFee_;

        // emit event
        emit setRedemptionFeeEvent(
            msg.sender,
            previousRedemptionFee,
            _redemptionFee,
            block.timestamp
        );

        // update min redemption amount
        // _minRedemptionAmount = (10**_feeDecimals) / _redemptionFee;

        // emit event
        emit minRedemptionAmountEvent(
            msg.sender,
            (10**_feeDecimals) / previousRedemptionFee,
            (10**_feeDecimals) / _redemptionFee,
            block.timestamp
        );
    }

    // set transfer fee
    function setTransferFee(uint256 transferFee_) public onlyFeeManager {
        // require transfer fee be greater than zero
        require(transferFee_ >= 0, "Transfer fee should be greater than zero!");

        // previous transfer fee
        uint256 previousTransferFee = _transferFee;

        // update transfer fee
        _transferFee = transferFee_;

        // emit event
        emit setTransferFeeEvent(
            msg.sender,
            previousTransferFee,
            _transferFee,
            block.timestamp
        );

        // update min transfer amount
        // _minTransferAmount = (10**_feeDecimals) / _transferFee;

        // emit event
        emit minTransferAmountEvent(
            msg.sender,
            (10**_feeDecimals) / previousTransferFee,
            (10**_feeDecimals) / _transferFee,
            block.timestamp
        );
    }

    ////   Getters    ////

    // get owner
    function getOwner() public view returns (address) {
        return _owner;
    }

    // get Asset Protection
    function getAssetProtection() public view returns (address) {
        return _assetProtection;
    }

    // get candidate Asset Protection
    function getCandidateAssetProtection() public view returns (address) {
        return _candidateAssetProtection;
    }

    // get token supply manager
    function getTokenSupplyManager() public view returns (address) {
        return _tokenSupplyManager;
    }

    // get whitelist manager
    function getWhitelistManager() public view returns (address) {
        return _whitelistManager;
    }

    // get fee manager
    function getFeeManager() public view returns (address) {
        return _feeManager;
    }

    // get Treasurer
    function getTreasurer() public view returns (address) {
        return _treasurer;
    }

    // is global whitelisted
    function isGlobalWhitelisted(address account_) public view returns (bool) {
        // return
        return _globalWhitelistAddressesStatus[account_];
    }

    // is creation/redemption whitelisted
    function isCRWhitelisted(address account_) public view returns (bool) {
        // return
        return _CRWhitelistAddressesStatus[account_];
    }

    // is transfer whitelisted
    function isTransferWhitelisted(address account_)
        public
        view
        returns (bool)
    {
        // return
        return _transferWhitelistAddressesStatus[account_];
    }

    // is freeze all transaction
    function isAllTransactionsFreezed() public view returns (bool) {
        return _freezAllTransactions;
    }

    // is acount freezed
    function isFreezed(address account_) public view returns (bool) {
        return _freezedAccountsStatus[account_];
    }

    // get list of freezed accounts
    function getFreezedAccounts() public view returns (address[] memory) {
        // return freezed accounts
        return _freezedAccounts;
    }

    // get list of accounts in global whitelist
    function getGlobalWhitelist() public view returns (address[] memory) {
        // return global whitelist addresses
        return _globalWhitelistAddresses;
    }

    // get list of accounts in creation/redemption whitelist
    function getCreationRedemptionWhitelist()
        public
        view
        returns (address[] memory)
    {
        // return CR whitelist addresses
        return _CRWhitelistAddresses;
    }

    // get list of accounts in transfer whitelist
    function getTransferWhitelist() public view returns (address[] memory) {
        // return transfer whitelist addresses
        return _transferWhitelistAddresses;
    }

    // get fee decimals
    function getFeeDecimals() public view returns (uint256) {
        return _feeDecimals;
    }

    // get creation fee
    function getCreationFee() public view returns (uint256) {
        return _creationFee;
    }

    // get redemption fee
    function getRedemptionFee() public view returns (uint256) {
        return _redemptionFee;
    }

    // get transfer fee
    function getTransferFee() public view returns (uint256) {
        return _transferFee;
    }

    // get min transfer amount
    function getMinTransferAmount() public view returns (uint256) {
        return _minTransferAmount;
    }

    // get min creation amount
    function getMinCreationAmount() public view returns (uint256) {
        return _minCreationAmount;
    }

    // get min redemption amount
    function getMinRedemptionAmount() public view returns (uint256) {
        return _minRedemptionAmount;
    }

    // get holders
    function getHolders() public view returns (address[] memory) {
        return _holders;
    }

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    ////   Standard ERC20 Functions    ////

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
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {
        require(from_ != address(0), "ERC20: transfer from the zero address");
        require(to_ != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from_, to_, amount_);

        uint256 fromBalance = _balances[from_];

        require(
            fromBalance >= amount_,
            "ERC20: transfer amount exceeds balance"
        );

        // check if from address is in transfer whitelist
        if (
            !(_transferWhitelistAddressesStatus[from_] ||
                _globalWhitelistAddressesStatus[from_])
        ) {
            // require fromBalance be greater that the min transfer amount
            require(
                fromBalance > _minTransferAmount,
                "Balance of sender should be greater than min transfer amount!"
            );

            // compute transfer fee amount
            uint256 transferFeeAmout = (amount_ * _transferFee) /
                (10**_feeDecimals);

            // udpate balances
            unchecked {
                // remove transfer amount from sender
                _balances[from_] = fromBalance - amount_;

                // add transfer fee amount to Treasurer account
                _balances[_treasurer] += transferFeeAmout;

                // add the rest amount to receiver address
                _balances[to_] += amount_ - transferFeeAmout;
            }

            // update holders
            // add treasuer as holder if not already in the list
            if(!_holdersStatus[_treasurer]){
                _appendToHolders(_treasurer);
            }

            // add to_ to holders if not already in the list
            if(!_holdersStatus[to_]){
                _appendToHolders(to_);
            }
            

            // remove from_ from holders if balance is zero.
            // _removeFromHolders(from_);
            if (_balances[from_] == 0) {
                _removeFromHolders(from_);
            }

            // emit transfer to Treasurer
            emit Transfer(from_, _treasurer, transferFeeAmout);

            // emit transfer to receiver
            emit Transfer(from_, to_, amount_ - transferFeeAmout);

            _afterTokenTransfer(from_, to_, amount_);
        } else {
            unchecked {
                _balances[from_] = fromBalance - amount_;
                // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
                // decrementing then incrementing.
                _balances[to_] += amount_;
            }

            // update holders
            // add to_ to holders if not already in the list
            if(!_holdersStatus[to_]){
                _appendToHolders(to_);
            }
            

            // remove from_ from holders if balance is zero.
            // _removeFromHolders(from_);
            if (_balances[from_] == 0) {
                _removeFromHolders(from_);
            }

            emit Transfer(from_, to_, amount_);

            _afterTokenTransfer(from_, to_, amount_);
        }
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
    function _mint(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account_, amount_);

        _totalSupply += amount_;

        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account_] += amount_;
        }

        // update holder
        if(!_holdersStatus[account_]){
            _appendToHolders(account_);
        }
        
        emit Transfer(address(0), account_, amount_);

        _afterTokenTransfer(address(0), account_, amount_);
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
    function _burn(address account_, uint256 amount_) internal virtual {
        require(account_ != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account_, address(0), amount_);

        uint256 accountBalance = _balances[account_];
        require(
            accountBalance >= amount_,
            "ERC20: burn amount exceeds balance"
        );
        unchecked {
            _balances[account_] = accountBalance - amount_;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount_;
        }

        // update holders if balance is zero.
        // _removeFromHolders(account_);
        if (_balances[account_] == 0) {
            _removeFromHolders(account_);
        }

        emit Transfer(account_, address(0), amount_);

        _afterTokenTransfer(account_, address(0), amount_);
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
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        require(owner_ != address(0), "ERC20: approve from the zero address");
        require(spender_ != address(0), "ERC20: approve to the zero address");

        _allowances[owner_][spender_] = amount_;
        emit Approval(owner_, spender_, amount_);
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
        address owner_,
        address spender_,
        uint256 amount_
    ) internal virtual {
        uint256 currentAllowance = allowance(owner_, spender_);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount_,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner_, spender_, currentAllowance - amount_);
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
        address from_,
        address to_,
        uint256 amount_
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
        address from_,
        address to_,
        uint256 amount_
    ) internal virtual {}

    ////    Commodity Token Functions    ////

    // add account to _holders if not already in the list
    function _appendToHolders(address account_) internal {
        if (!_holdersStatus[account_]) {
            // add to list
            _holders.push(account_);
            // update status
            _holdersStatus[account_] = true;
        }
    }

    // remove account from _holders if already in the list
    function _removeFromHolders(address account_) internal {
        if (_holdersStatus[account_]) {
            for (uint256 i = 0; i < _holders.length; i++) {
                if (_holders[i] == account_) {
                    _holders[i] = _holders[_holders.length - 1];
                    _holders.pop();
                    // update status
                    _holdersStatus[account_] = false;
                    break;
                }
            }
        }
    }

    // requireNotFreezed
    function _requireNotFreezed(address account_) internal view virtual {
        // require account not freezed
        require(!_freezedAccountsStatus[account_], "Account is freezed!");
    }

    // requireFreezed
    function _requireFreezed(address account_) internal view virtual {
        // require account not freezed
        require(_freezedAccountsStatus[account_], "Account is not freezed!");
    }

    // add account to freezed accounts if not already in the list
    function _appendToFreezedAccounts(address account_) internal {
        if (!_freezedAccountsStatus[account_]) {
            _freezedAccounts.push(account_);
            _freezedAccountsStatus[account_] = true;
        }
    }

    // remove account from freezed accounts if already in the list
    function _removeFromFreezedAccounts(address account_) internal {
        if (!_freezedAccountsStatus[account_]) {
            for (uint256 i = 0; i < _freezedAccounts.length; i++) {
                if (_freezedAccounts[i] == account_) {
                    _freezedAccounts[i] = _freezedAccounts[
                        _freezedAccounts.length - 1
                    ];
                    _freezedAccounts.pop();
                    // update status
                    _freezedAccountsStatus[account_] = true;
                    break;
                }
            }
        }
    }

    // add account to _globalWhitelistAddresses if not already in the list
    function _appendToGlobalWhitelistAddresses(address account_) internal {
        if (!_globalWhitelistAddressesStatus[account_]) {
            _globalWhitelistAddresses.push(account_);
            _globalWhitelistAddressesStatus[account_] = true;
        }
    }

    // remove account from _globalWhitelistAddresses if already in the list
    function _removeFromGlobalWhitelistAddresses(address account_) internal {
        if (!_globalWhitelistAddressesStatus[account_]) {
            for (uint256 i = 0; i < _globalWhitelistAddresses.length; i++) {
                if (_globalWhitelistAddresses[i] == account_) {
                    _globalWhitelistAddresses[i] = _globalWhitelistAddresses[
                        _globalWhitelistAddresses.length - 1
                    ];
                    _globalWhitelistAddresses.pop();
                    // update status
                    _globalWhitelistAddressesStatus[account_] = true;
                    break;
                }
            }
        }
    }

    // add account to _CRWhitelistAddresses if not already in the list
    function _appendToCRWhitelistAddresses(address account_) internal {
        if (!_CRWhitelistAddressesStatus[account_]) {
            _CRWhitelistAddresses.push(account_);
            _CRWhitelistAddressesStatus[account_] = true;
        }
    }

    // remove account from _CRWhitelistAddresses if already in the list
    function _removeFromCRWhitelistAddresses(address account_) internal {
        if (!_CRWhitelistAddressesStatus[account_]) {
            for (uint256 i = 0; i < _CRWhitelistAddresses.length; i++) {
                if (_CRWhitelistAddresses[i] == account_) {
                    _CRWhitelistAddresses[i] = _CRWhitelistAddresses[
                        _CRWhitelistAddresses.length - 1
                    ];
                    _CRWhitelistAddresses.pop();
                    // update status
                    _CRWhitelistAddressesStatus[account_] = true;
                    break;
                }
            }
        }
    }

    // add account to _transferWhitelistAddresses if not already in the list
    function _appendToTransferWhitelistAddresses(address account_) internal {
        if (!_transferWhitelistAddressesStatus[account_]) {
            _transferWhitelistAddresses.push(account_);
            _transferWhitelistAddressesStatus[account_] = true;
        }
    }

    // remove account from _transferWhitelistAddresses if already in the list
    function _removeFromTransferWhitelistAddresses(address account_) internal {
        if (!_transferWhitelistAddressesStatus[account_]) {
            for (uint256 i = 0; i < _transferWhitelistAddresses.length; i++) {
                if (_transferWhitelistAddresses[i] == account_) {
                    _transferWhitelistAddresses[
                        i
                    ] = _transferWhitelistAddresses[
                        _transferWhitelistAddresses.length - 1
                    ];
                    _transferWhitelistAddresses.pop();
                    // update status
                    _transferWhitelistAddressesStatus[account_] = true;
                    break;
                }
            }
        }
    }
}