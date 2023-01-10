// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    ////    VanEck Token Fields    ////

    /*  ROLES   */

    // owner
    address public _owner;

    // candidate owner
    address public _candidateOwner;

    // token supply supervisor
    address public _tokenSupplySupervisor;

    // Supervisory account
    address public _accountSupervisor;

    // candidate supervisory account
    address public _candidateAccountSupervisor;

    // whitelist supervisor
    address public _whitelistSupervisor;

    // fee supervisor
    address public _feeSupervisor;

    // fee recipient
    address public _feeRecipient;

    /*  WhiteLists   */

    // global whitelist addresses
    mapping(address => bool) _globalWhitelistAddresses;

    // creation/redemption whitelist addresses
    mapping(address => bool) _CRWhitelistAddresses;

    // transfer whitelist addresses
    mapping(address => bool) _transferWhitelistAddresses;

    /*  Freezing Fields   */

    // FreezAllTransactios
    bool public _freezAllTransactions = false;

    // freezing specific accounts transactions
    mapping(address => bool) internal _freeze;

    /*  Fee Fields   */

    // fee decimals
    uint256 public _feeDecimals = 18;

    // createion fee
    uint256 public _creationFee = 2500000000000000;

    // redemption fee
    uint256 public _redemptionFee = 2500000000000000;

    // transfer fee
    uint256 public _transferFee = 1000000000000000;

    // min transfer amount
    uint256 _minTransferAmount = 1000;

    // min creation amount
    uint256 _minCreationAmount = 4000;

    // min redemption amount
    uint256 _minRedemptionAmount = 4000;

    // constructor
    constructor(
        string memory name_,
        string memory symbol_,
        address accountSupervisor_,
        address tokenSupplySupervisor_,
        address whitelistSupervisor_,
        address feeSupervisor_,
        address feeRecipient_
    ) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
        _accountSupervisor = accountSupervisor_;
        _tokenSupplySupervisor = tokenSupplySupervisor_;
        _whitelistSupervisor = whitelistSupervisor_;
        _feeSupervisor = feeSupervisor_;
        _feeRecipient = feeRecipient_;
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    ////    Standard ERC20 Events    ////

    ////    VanEck Token Events    ////

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
        address indexed AccountSupervisor,
        address indexed account,
        uint256 indexed timestamp
    );

    // un-freeze and account event
    event unFreezeAccountEvent(
        address indexed AccountSupervisor,
        address indexed account,
        uint256 indexed timestamp
    );

    // wipe frozen account event
    event wipeFrozenAccountEvent(
        address indexed AccountSupervisor,
        address indexed account,
        uint256 balance,
        uint256 indexed timestamp
    );

    // withdraw tokens send to contract address
    event withdrawContractTokensEvent(
        address indexed contractAddress,
        address indexed feeRecipientAddress,
        uint256 amount,
        uint256 indexed timestamp
    );

    // set candiate owner
    event setCandidateOwnerEvent(
        address indexed ownerAccount,
        address indexed candidateOwner,
        uint256 indexed timestamp
    );

    // cancel candiate owner
    event cancelCandidateOwnerEvent(
        address indexed sender,
        address indexed candiateOwner,
        uint256 indexed timestamp
    );

    // update owner address
    event updateOwnerEvent(
        address indexed previousOwnerAddress,
        address indexed newOwnerAddress,
        uint256 indexed timestamp
    );

    // update token supply supervisor
    event updateTokenSupplySupervisorEvent(
        address ownerAccount,
        address indexed previousTokenSupplySupervisorAddress,
        address indexed newTokenSupplySupervisor,
        uint256 indexed timestamp
    );

    // creation basket event
    event creationBasketEvent(
        address indexed tokenSupplySupervisor,
        address indexed receiverAddress,
        address feeRecipient,
        string creationType,
        uint256 receiverAmount,
        uint256 creationFeeAmount,
        bool isWhitelisted,
        uint256 indexed timestamp
    );

    // redemption basket event
    event redemptionBasketEvent(
        address indexed tokenSupplySupervisor,
        address indexed senderAddress,
        address feeRecipient,
        uint256 amountBurned,
        uint256 redemptionFeeAmount,
        bool isWhitelisted,
        uint256 indexed timestamp
    );

    // set candidate account supervisor
    event setCandidateAccountSupervisorEvent(
        address indexed sender,
        address indexed candidateAccountSupervisor,
        uint256 indexed timestamp
    );

    // update account supervisor acount
    event updateAccountSupervisorEvent(
        address indexed previousAccountSupervisorAddress,
        address indexed newAccountSupervisorAddress,
        uint256 indexed timestamp
    );

    // update whitelist supervisor address
    event updateWhitelistSupervisorEvent(
        address ownerAccount,
        address indexed previousWhitelistSupervisorAddress,
        address indexed newWhitelistSupervisor,
        uint256 indexed timestamp
    );

    // append account to global whitelist addresses
    event appendToGlobalWhitelistEvent(
        address indexed whitelistSupervisor,
        address indexed account,
        uint256 indexed timestamp
    );

    // remove account from global whitelist addresses
    event removeFromGlobalWhitelistEvent(
        address indexed whitelistSupervisor,
        address indexed account,
        uint256 indexed timestamp
    );

    // append account to creation/redemption whitelist addresses
    event appendToCRWhitelistEvent(
        address indexed whitelistSupervisor,
        address account,
        uint256 indexed timestamp
    );

    // remove account from creation/redemption whitelist addresses
    event removeFromCRWhitelistEvent(
        address indexed whitelistSupervisor,
        address account,
        uint256 indexed timestamp
    );

    // append account to transfer whitelist addresses
    event appendToTransferWhitelistEvent(
        address indexed whitelistSupervisor,
        address account,
        uint256 indexed timestamp
    );

    // remove account from transfer whitelist addresses
    event removeFromTransferWhitelistEvent(
        address indexed whitelistSupervisor,
        address account,
        uint256 indexed timestamp
    );

    // update fee supervisor
    event updateFeeSupervisorEvent(
        address ownerAccount,
        address indexed previousFeeSupervisorAddress,
        address indexed newFeeSupervisor,
        uint256 indexed timestamp
    );

    // update fee recipient
    event updateFeeRecipientEvent(
        address ownerAddress,
        address indexed previousFeeRecipientAddress,
        address indexed newFeeRecipient,
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

    ////    VanEck Token Modifiers    ////

    // All Transactions Not Frozen
    modifier AllTransactionsNotFrozen() {
        require(!_freezAllTransactions, "All transactions are frozen!");
        _;
    }

    // only Owner
    modifier onlyOwner() {
        require(msg.sender == _owner, "Sender is not the owner address!");
        _;
    }

    // only candidate owner
    modifier onlyCandiateOwner() {
        require(
            msg.sender == _candidateOwner,
            "Sender is not candidate owner address!"
        );
        _;
    }

    // only Token Supply Supervisor
    modifier onlyTokenSupplySupervisor() {
        require(
            msg.sender == _tokenSupplySupervisor,
            "Sender is not the token supply supervisor address!"
        );
        _;
    }

    // only account supervisor
    modifier onlyAccountSupervisor() {
        require(
            msg.sender == _accountSupervisor,
            "Sender is not the account supervisor address!"
        );
        _;
    }

    // only candidate account supervisor
    modifier onlyCandiateAccountSupervisor() {
        require(
            msg.sender == _candidateAccountSupervisor,
            "Sender is not candidate account supervisor address!"
        );
        _;
    }

    // only whitelist supervisor
    modifier onlyWhitelistSupervisor() {
        require(
            msg.sender == _whitelistSupervisor,
            "Sender is not the whitelist supervisor address!"
        );
        _;
    }

    // only fee supervisor
    modifier onlyFeeSupervisor() {
        require(
            msg.sender == _feeSupervisor,
            "Sender is not the fee supervisor address!"
        );
        _;
    }

    // only fee recipient
    modifier onlyFeeRecipient() {
        require(
            msg.sender == _feeRecipient,
            "Sender is not the fee recipient address!"
        );
        _;
    }

    // only one role for one address
    modifier onlyOneRole(address account_) {
        // require the account not be the owner
        require(account_ != _owner, "Account cannot be the owner!");
        _;

        // require the account not be the account supervisor
        require(
            account_ != _accountSupervisor,
            "Account cannot be the account supervisor!"
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
        AllTransactionsNotFrozen
        returns (bool)
    {
        // require amount > 0
        require(amount_ > 0, "Amount should be greater than zero!");

        // sender account
        address owner_ = _msgSender();

        // require sender be not frozen
        _requireNotFrozen(owner_);

        // require to be not frozen
        _requireNotFrozen(to_);

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
        AllTransactionsNotFrozen
        returns (uint256)
    {
        // require sender be not frozen
        _requireNotFrozen(owner_);

        // require spender be not frozen
        _requireNotFrozen(spender_);

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
        AllTransactionsNotFrozen
        returns (bool)
    {
        // require sender be not frozen
        _requireNotFrozen(msg.sender);

        // require spender be not frozen
        _requireNotFrozen(spender_);

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
    ) public virtual override AllTransactionsNotFrozen returns (bool) {
        address spender_ = _msgSender();
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
        AllTransactionsNotFrozen
        returns (bool)
    {
        // require sender be not frozen
        _requireNotFrozen(msg.sender);

        // require spender be not frozen
        _requireNotFrozen(spender_);

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
        AllTransactionsNotFrozen
        returns (bool)
    {
        // require sender be not frozen
        _requireNotFrozen(msg.sender);

        // require spender be not frozen
        _requireNotFrozen(spender_);

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

    //// VanEck Token Public Functions   ////

    /*    Role Updating Functions    */

    // set candidate owner
    function setCandidateOwner(address candidateOwnerAddress_)
        public
        onlyOwner
        onlyOneRole(candidateOwnerAddress_)
        notNullAddress(candidateOwnerAddress_)
    {
        // require current candidate owner address be zero address (no one is candidate)
        require(
            _candidateOwner == address(0),
            "Cannot overwite the current candidate owner!"
        );

        // update the candidate owner address
        _candidateOwner = candidateOwnerAddress_;

        // emit setting candidate owner
        emit setCandidateOwnerEvent(_owner, _candidateOwner, block.timestamp);
    }

    // cancel candidate owner
    function cancelCandidateOwner() public {
        // require sender be either owner or candiate owner
        require(
            msg.sender == _candidateOwner || msg.sender == _owner,
            "Sender is not owner or candiate owner!"
        );

        // require candiate owner be already set
        require(
            _candidateOwner != address(0),
            "No address is set as candiate owner!"
        );

        // previous candiate owner address
        address candiateOwner = _candidateOwner;

        // set candiate owner address to zero address
        _candidateOwner = address(0);

        // emit event
        emit cancelCandidateOwnerEvent(
            msg.sender,
            candiateOwner,
            block.timestamp
        );
    }

    // update Owner
    function updateOwner() public onlyCandiateOwner {
        // previous owner address
        address previousOwnerAddress = _owner;

        // update owner address to candidate address
        _owner = _candidateOwner;

        // set candiate owner address to zero
        _candidateOwner = address(0);

        // emit event
        emit updateOwnerEvent(previousOwnerAddress, _owner, block.timestamp);
    }

    // update candidate token supply supervisor
    function updateTokenSupplySupervisor(address tokenSupplySupervisorAddress_)
        public
        onlyOwner
        onlyOneRole(tokenSupplySupervisorAddress_)
        notNullAddress(tokenSupplySupervisorAddress_)
    {
        // previous token supply supervisor address
        address previousTokenSupplySupervisorAddress = _tokenSupplySupervisor;

        // update token supply supervisor address
        _tokenSupplySupervisor = tokenSupplySupervisorAddress_;

        // emit event
        emit updateTokenSupplySupervisorEvent(
            msg.sender,
            previousTokenSupplySupervisorAddress,
            _tokenSupplySupervisor,
            block.timestamp
        );
    }

    // set candidate account supervisor
    function setCandidateAccountSupervisor(
        address candidateAccountSupervisorAddress_
    )
        public
        onlyOneRole(candidateAccountSupervisorAddress_)
    // notNullAddress(candidateAccountSupervisorAddress_)
    {
        // require sender by either owner or current account superivsor
        require(
            msg.sender == _owner || msg.sender == _accountSupervisor,
            "Sender is not owner or account supervisor address!"
        );

        // // require candidate account supervisor be zero (no address is current candidate)
        // require(
        //     _candidateAccountSupervisor == address(0),
        //     "Cannot overwrite the current candidate!"
        // );

        // update the candidate account supervisor address
        _candidateAccountSupervisor = candidateAccountSupervisorAddress_;

        // emit setting candidate account supervisor
        emit setCandidateAccountSupervisorEvent(
            msg.sender,
            _candidateAccountSupervisor,
            block.timestamp
        );
    }

    // update account supervisor
    function updateAccountSupervisor() public onlyCandiateAccountSupervisor {
        // previous account supervisor address
        address previousAccountSupervisorAddress = _accountSupervisor;

        // update account supervisor address to candidate account supervisor address
        _accountSupervisor = _candidateAccountSupervisor;

        // set candiate account supervisor address to zero
        _candidateAccountSupervisor = address(0);

        // emit event
        emit updateAccountSupervisorEvent(
            previousAccountSupervisorAddress,
            _accountSupervisor,
            block.timestamp
        );
    }

    // update whitelist supervisor
    function updateWhitelistSupervisor(address whitelistSupervisorAddress_)
        public
        onlyOwner
        onlyOneRole(whitelistSupervisorAddress_)
        notNullAddress(whitelistSupervisorAddress_)
    {
        // previous whitelist supervisor address
        address previousWhitelistSupervisorAddress = _whitelistSupervisor;

        // update whitelist supervisor address
        _whitelistSupervisor = whitelistSupervisorAddress_;

        // emit event
        emit updateWhitelistSupervisorEvent(
            msg.sender,
            previousWhitelistSupervisorAddress,
            _whitelistSupervisor,
            block.timestamp
        );
    }

    // update fee supervisor
    function updateFeeSupervisor(address feeSupervisorAddress_)
        public
        onlyOwner
        onlyOneRole(feeSupervisorAddress_)
        notNullAddress(feeSupervisorAddress_)
    {
        // previous fee supervisor address
        address previousFeeSupervisorAddress = _feeSupervisor;

        // update fee supervisor
        _feeSupervisor = feeSupervisorAddress_;

        // emit event
        emit updateFeeSupervisorEvent(
            msg.sender,
            previousFeeSupervisorAddress,
            _feeSupervisor,
            block.timestamp
        );
    }

    // update fee recipient
    function updateFeeRecipient(address newFeeRecipient_)
        public
        onlyOwner
        onlyOneRole(newFeeRecipient_)
        notNullAddress(newFeeRecipient_)
    {
        // previous fee recipient address
        address previousFeeRecipientAddress = _feeRecipient;

        // update fee recipient address
        _feeRecipient = newFeeRecipient_;

        // emit event
        emit updateFeeRecipientEvent(
            msg.sender,
            previousFeeRecipientAddress,
            _feeRecipient,
            block.timestamp
        );
    }

    /*   Only Owner Functions    */

    // freeze all transactions
    function freezeAllTransactions() public onlyOwner {
        // require all transactions be already unfrozen
        require(!_freezAllTransactions, "All transactions are already frozen!");

        // set value for freeze all transactions
        _freezAllTransactions = true;

        // emit freezing all transactions event
        emit freezeAllTransactionsEvent(msg.sender, block.timestamp);
    }

    // un-freeze all transactions
    function unFreezeAllTransactions() public onlyOwner {
        // require all transactions be already frozen
        require(
            _freezAllTransactions,
            "All transactions are already unfrozen!"
        );

        // set value for freeze all transactions
        _freezAllTransactions = false;

        // emit un-freeze all transaction event
        emit unFreezeAllTransactionsEvent(msg.sender, block.timestamp);
    }

    /*    Only Account Supervisor Functions    */

    // freeze an account
    function freezeAccount(address account_) public onlyAccountSupervisor {
        // require account not be already frozen
        _requireNotFrozen(account_);

        // freeze the account
        _freeze[account_] = true;

        // emit event
        emit freezeAccountEvent(msg.sender, account_, block.timestamp);
    }

    // un-freeze and account
    function unFreezeAccount(address account_) public onlyAccountSupervisor {
        // require account be already frozen
        _requireFrozen(account_);

        // freeze the account
        _freeze[account_] = false;

        // emit event
        emit unFreezeAccountEvent(msg.sender, account_, block.timestamp);
    }

    // wipe frozen account
    function wipeFrozenAccount(address account_) public onlyAccountSupervisor {
        // require account bre frozen
        _requireFrozen(account_);

        // get balance of the frozen account
        uint256 balance_ = _balances[account_];

        // set balance of the forzen account to zero
        _balances[account_] = 0;

        // update total Supply
        _totalSupply = _totalSupply - balance_;

        // emit event for wipe frozen acount
        emit wipeFrozenAccountEvent(
            msg.sender,
            account_,
            balance_,
            block.timestamp
        );
    }

    // freeze and wipe an account
    function freezeAndWipeAccount(address account_)
        public
        onlyAccountSupervisor
    {
        // require account not be already frozen
        _requireNotFrozen(account_);

        // freeze the account
        _freeze[account_] = true;

        // emit event
        emit freezeAccountEvent(msg.sender, account_, block.timestamp);

        // get balance of the frozen account
        uint256 balance_ = _balances[account_];

        // set balance of the forzen account to zero
        _balances[account_] = 0;

        // update total Supply
        _totalSupply = _totalSupply - balance_;

        // emit event for wipe frozen acount
        emit wipeFrozenAccountEvent(
            msg.sender,
            account_,
            balance_,
            block.timestamp
        );
    }

    /*    Only Token Supply Supervisor Functions    */

    // creation basket
    function creationBasket(
        uint256 amount_,
        address receiverAddress_,
        string memory basketType_
    ) public onlyTokenSupplySupervisor returns (bool) {
        if (
            basketType_.upper().compareTo("CASH") ||
            (basketType_.upper().compareTo("TOKEN") &&
                _CRWhitelistAddresses[receiverAddress_]) ||
            (basketType_.upper().compareTo("TOKEN") &&
                _globalWhitelistAddresses[receiverAddress_])
        ) {
            // increase total token supply
            _totalSupply = _totalSupply + amount_;

            // update the balance of the total token supply supervisor
            _balances[receiverAddress_] = _balances[receiverAddress_] + amount_;

            // emit creation basket event
            emit creationBasketEvent(
                msg.sender,
                receiverAddress_,
                _feeRecipient,
                basketType_,
                amount_,
                0,
                _CRWhitelistAddresses[receiverAddress_],
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

            // increase total token supply
            _totalSupply = _totalSupply + amount_;

            // creation fee amount
            uint256 creationFeeAmount = (amount_ * _creationFee) /
                (10**_feeDecimals);

            // received amount
            uint256 receivedAmount = amount_ - creationFeeAmount;

            // update the balance of receiver address
            _balances[receiverAddress_] =
                _balances[receiverAddress_] +
                receivedAmount;

            // update the balance of fee receipient
            _balances[_feeRecipient] =
                _balances[_feeRecipient] +
                creationFeeAmount;

            // emit creation basket event
            emit creationBasketEvent(
                msg.sender,
                receiverAddress_,
                _feeRecipient,
                basketType_,
                receivedAmount,
                creationFeeAmount,
                _CRWhitelistAddresses[receiverAddress_],
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
        onlyTokenSupplySupervisor
        returns (bool)
    {
        // require sender balance be greater than amount
        require(
            amount_ <= _balances[senderAddress_],
            "Balance of the sender address is low!"
        );

        if (
            _CRWhitelistAddresses[senderAddress_] ||
            _globalWhitelistAddresses[senderAddress_]
        ) {
            // decrease balance of sender
            _balances[senderAddress_] -= amount_;

            // decrease to total token supply
            _totalSupply -= amount_;

            // emit redemption event
            emit redemptionBasketEvent(
                msg.sender,
                senderAddress_,
                _feeRecipient,
                amount_,
                0,
                _CRWhitelistAddresses[senderAddress_],
                block.timestamp
            );

            // return
            return true;
        } else {
            // require amount > min redemption amount
            require(
                amount_ > _minRedemptionAmount,
                "Amount should be greater than min redemption amount!"
            );

            // redemption fee amount
            uint256 redemptionFeeAmount = (amount_ * _redemptionFee) /
                (10**_feeDecimals);

            // decrease balance of sender
            _balances[senderAddress_] -= amount_;

            // increase balance of fee receipient
            _balances[_feeRecipient] += redemptionFeeAmount;

            // decrease to total token supply
            _totalSupply -= amount_ - redemptionFeeAmount;

            // emit redemption event
            emit redemptionBasketEvent(
                msg.sender,
                senderAddress_,
                _feeRecipient,
                amount_ - redemptionFeeAmount,
                redemptionFeeAmount,
                _CRWhitelistAddresses[senderAddress_],
                block.timestamp
            );

            // return
            return true;
        }
    }

    /*    Only Fee Recipient Functions    */

    // withdraw tokens from contract to fee recipient account
    function withdrawContractTokens() external onlyFeeRecipient {
        // get balanche of the VE Token Contract
        uint256 balance_ = _balances[address(this)];

        // set balance of the contract to zero
        _balances[address(this)] = 0;

        // add the balance to fee recipient wallet
        _balances[_feeRecipient] = _balances[_feeRecipient] + balance_;

        // emit WidthrawContractTokens
        emit withdrawContractTokensEvent(
            address(this),
            msg.sender,
            balance_,
            block.timestamp
        );
    }

    /*    Only Whitelist Supervisor Functions    */

    // add account to global whitelist
    function appendToGlobalWhitelist(address account_)
        public
        onlyWhitelistSupervisor
        notNullAddress(account_)
    {
        // require address not be whitelisted
        require(
            !_globalWhitelistAddresses[account_],
            "This address is already in the global whitelist!"
        );

        // add the address to whitelistAddresses
        _globalWhitelistAddresses[account_] = true;

        // emit event
        emit appendToGlobalWhitelistEvent(
            _whitelistSupervisor,
            account_,
            block.timestamp
        );
    }

    // remove account from global whitelist
    function removeFromGlobalWhitelist(address account_)
        public
        onlyWhitelistSupervisor
        notNullAddress(account_)
    {
        // require account be already whitelisted
        require(
            _globalWhitelistAddresses[account_],
            "This address is not in global whitelist!"
        );

        // remove address from global whitelist
        _globalWhitelistAddresses[account_] = false;

        // emit event
        emit removeFromGlobalWhitelistEvent(
            _whitelistSupervisor,
            account_,
            block.timestamp
        );
    }

    // add account to creation/redemption whitelist
    function appendToCRWhitelist(address account_)
        public
        onlyWhitelistSupervisor
        notNullAddress(account_)
    {
        // require address not be in creation/redemption whitelist
        require(
            !_CRWhitelistAddresses[account_],
            "This address is already in the creation/redemption whitelist!"
        );

        // add the address to whitelistAddresses
        _CRWhitelistAddresses[account_] = true;

        // emit event
        emit appendToCRWhitelistEvent(
            _whitelistSupervisor,
            account_,
            block.timestamp
        );
    }

    // remove account from creation/redemption whitelist
    function removeFromCRWhitelist(address account_)
        public
        onlyWhitelistSupervisor
        notNullAddress(account_)
    {
        // require account be already whitelisted
        require(
            _CRWhitelistAddresses[account_],
            "This address is not in creation/redemption whitelist!"
        );

        // remove address from creation/redemption whitelist
        _CRWhitelistAddresses[account_] = false;

        // emit event
        emit removeFromCRWhitelistEvent(
            _whitelistSupervisor,
            account_,
            block.timestamp
        );
    }

    // add account to transfer whitelist
    function appendToTransferWhitelist(address account_)
        public
        onlyWhitelistSupervisor
        notNullAddress(account_)
    {
        // require address not be in transfer whitelist
        require(
            !_transferWhitelistAddresses[account_],
            "This address is already in the transfer whitelist!"
        );

        // add the address to whitelistAddresses
        _transferWhitelistAddresses[account_] = true;

        // emit event
        emit appendToTransferWhitelistEvent(
            _whitelistSupervisor,
            account_,
            block.timestamp
        );
    }

    // remove account from transfer whitelist
    function removeFromTransferWhitelist(address account_)
        public
        onlyWhitelistSupervisor
        notNullAddress(account_)
    {
        // require account be already whitelisted
        require(
            _transferWhitelistAddresses[account_],
            "This address is not in transfer whitelist!"
        );

        // remove address from transfer whitelist
        _transferWhitelistAddresses[account_] = false;

        // emit event
        emit removeFromTransferWhitelistEvent(
            _whitelistSupervisor,
            account_,
            block.timestamp
        );
    }

    /* Only Fee Supervisor Functions    */

    // set fee decimals
    function setFeeDecimals(uint256 feeDecimals_) public onlyFeeSupervisor {
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
        _minTransferAmount = (10**_feeDecimals) / _transferFee;

        // emit event
        emit minTransferAmountEvent(
            msg.sender,
            previousFeeDecimals / _transferFee,
            _minTransferAmount,
            block.timestamp
        );

        // update min creation amount
        _minCreationAmount = (10**_feeDecimals) / _creationFee;

        // emit event
        emit minCreationAmountEvent(
            msg.sender,
            previousFeeDecimals / _creationFee,
            _minCreationAmount,
            block.timestamp
        );

        // update min redemption amount
        _minRedemptionAmount = (10**_feeDecimals) / _redemptionFee;

        // emit event
        emit minRedemptionAmountEvent(
            msg.sender,
            previousFeeDecimals / _redemptionFee,
            _minRedemptionAmount,
            block.timestamp
        );
    }

    // set creation fee
    function setCreationFee(uint256 creationFee_) public onlyFeeSupervisor {
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

        // update min creation amount
        _minCreationAmount = (10**_feeDecimals) / _creationFee;

        // emit event
        emit minCreationAmountEvent(
            msg.sender,
            (10**_feeDecimals) / previousCreationFee,
            _minCreationAmount,
            block.timestamp
        );
    }

    // set redemption fee
    function setRedemptionFee(uint256 redemptionFee_) public onlyFeeSupervisor {
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
        _minRedemptionAmount = (10**_feeDecimals) / _redemptionFee;

        // emit event
        emit minRedemptionAmountEvent(
            msg.sender,
            (10**_feeDecimals) / previousRedemptionFee,
            _minRedemptionAmount,
            block.timestamp
        );
    }

    // set transfer fee
    function setTransferFee(uint256 transferFee_) public onlyFeeSupervisor {
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
        _minTransferAmount = (10**_feeDecimals) / _transferFee;

        // emit event
        emit minTransferAmountEvent(
            msg.sender,
            (10**_feeDecimals) / previousTransferFee,
            _minTransferAmount,
            block.timestamp
        );
    }

    ////   Getters    ////

    // get owner
    function getOwner() public view returns (address) {
        return _owner;
    }

    // get candidate owner
    function getCandidateOwner() public view returns (address) {
        return _candidateOwner;
    }

    // get token supply supervisor
    function getTokenSupplySupervisor() public view returns (address) {
        return _tokenSupplySupervisor;
    }

    // get account supervisor
    function getAccountSupervisor() public view returns (address) {
        return _accountSupervisor;
    }

    // get candidate account supervisor
    function getCandidateAccountSupervisor() public view returns (address) {
        return _candidateAccountSupervisor;
    }

    // get whitelist supervisor
    function getWhitelistSupervisor() public view returns (address) {
        return _whitelistSupervisor;
    }

    // get fee supervisor
    function getFeeSupervisor() public view returns (address) {
        return _feeSupervisor;
    }

    // get fee recipient
    function getFeeRecipient() public view returns (address) {
        return _feeRecipient;
    }

    // is global whitelisted
    function isGlobalWhitelisted(address account_) public view returns (bool) {
        // require non zero address
        require(account_ != address(0), "Entered address is zero address!");

        // return
        return _globalWhitelistAddresses[account_];
    }

    // is creation/redemption whitelisted
    function isCRWhitelisted(address account_) public view returns (bool) {
        // require non zero address
        require(account_ != address(0), "Entered address is zero address!");

        // return
        return _CRWhitelistAddresses[account_];
    }

    // is transfer whitelisted
    function isTransferWhitelisted(address account_)
        public
        view
        returns (bool)
    {
        // require non zero address
        require(account_ != address(0), "Entered address is zero address!");

        // return
        return _transferWhitelistAddresses[account_];
    }

    // is freeze all transaction
    function isAllTransactionsFrozen() public view returns (bool) {
        return _freezAllTransactions;
    }

    // is acount frozen
    function isFrozen(address account_) public view returns (bool) {
        return _freeze[account_];
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
            !(_transferWhitelistAddresses[from_] ||
                _globalWhitelistAddresses[from_])
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

                // add transfer fee amount to fee receipient account
                _balances[_feeRecipient] += transferFeeAmout;

                // add the rest amount to receiver address
                _balances[to_] += amount_ - transferFeeAmout;
            }

            // emit transfer to fee recipient
            emit Transfer(from_, _feeRecipient, transferFeeAmout);

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

    ////    VanEck Token Functions    ////

    // requireNotFrozen
    function _requireNotFrozen(address account_) internal view virtual {
        // require account be no zero
        require(account_ != address(0), "Entered zero address");

        // require account not frozen
        require(!_freeze[account_], "Account is frozen!");
    }

    // requireFrozen
    function _requireFrozen(address account_) internal view virtual {
        // require account be no zero
        require(account_ != address(0), "Entered zero address");

        // require account not frozen
        require(_freeze[account_], "Account is not frozen!");
    }
}