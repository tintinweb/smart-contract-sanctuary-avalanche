/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-29
*/

// File: contracts/libraries/Address.sol


pragma solidity 0.8.15;

library Address {
  function isContract(address account) internal view returns (bool) {
    uint256 size;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "Address: insufficient balance");

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
  }

  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return functionCall(target, data, "Address: low-level call failed");
  }

  function functionCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    return _functionCallWithValue(target, data, 0, errorMessage);
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value
  ) internal returns (bytes memory) {
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
  }

  function functionCallWithValue(
    address target,
    bytes memory data,
    uint256 value,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _functionCallWithValue(
    address target,
    bytes memory data,
    uint256 weiValue,
    string memory errorMessage
  ) private returns (bytes memory) {
    require(isContract(target), "Address: call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: weiValue}(
      data
    );
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }

  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
  }

  function functionStaticCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal view returns (bytes memory) {
    require(isContract(target), "Address: static call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
  }

  function functionDelegateCall(
    address target,
    bytes memory data,
    string memory errorMessage
  ) internal returns (bytes memory) {
    require(isContract(target), "Address: delegate call to non-contract");

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      if (returndata.length > 0) {
        assembly {
          let returndata_size := mload(returndata)
          revert(add(32, returndata), returndata_size)
        }
      } else {
        revert(errorMessage);
      }
    }
  }

  function toBytes32(address a) internal pure returns (bytes32 b) {
    assembly {
      let m := mload(0x40)
      a := and(a, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
      mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
      mstore(0x40, add(m, 52))
      b := m
    }
  }

  function addressToString(address _address)
    internal
    pure
    returns (string memory)
  {
    bytes32 _bytes = toBytes32(_address);
    bytes memory HEX = "0123456789abcdef";
    bytes memory _addr = new bytes(42);

    _addr[0] = "0";
    _addr[1] = "x";

    for (uint256 i = 0; i < 20; i++) {
      _addr[2 + i * 2] = HEX[uint8(_bytes[i + 12] >> 4)];
      _addr[3 + i * 2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
    }

    return string(_addr);
  }
}

// File: contracts/interfaces/Call/IUserTermsKeeper.sol


pragma solidity >=0.8.15;

interface IUserTermsKeeper {
    // Info for market note
    struct UserTerms {
        int256 cryptoIntitialPrice; // reference price at opening
        int256 cryptoClosingPrice; // closing price of position
        uint256 payout; // REQ remaining to be paid
        uint48 created; // time market was created
        uint48 matured; // time of instrument maturity
        uint48 redeemed; // time notional was redeemed
        uint48 exercised; // time instrument was exercised
        uint48 marketID; // market ID of deposit. uint48 to avoid adding a slot.
    }

    function pushTerms(address to, uint256 index) external;

    function pullTerms(address from, uint256 index) external returns (uint256 newIndex_);

    function indexesFor(address _user) external view returns (uint256[] memory);

    function pendingFor(address _user, uint256 _index)
        external
        view
        returns (
            uint256 payout_,
            bool matured_,
            bool payoffClaimable_
        );
}

// File: contracts/interfaces/ITreasury.sol


pragma solidity >=0.8.15;

interface ITreasury {
    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256);

    function withdraw(uint256 _amount, address _token) external;

    function assetValue(address _token, uint256 _amount) external view returns (uint256 value_);

    function mint(address _recipient, uint256 _amount) external;

    function manage(address _token, uint256 _amount) external;

    function incurDebt(uint256 amount_, address token_) external;

    function repayDebtWithReserve(uint256 amount_, address token_) external;

    function excessReserves() external view returns (int256);

    function baseSupply() external view returns (uint256);
}

// File: contracts/interfaces/IAggragatorV3.sol


pragma solidity ^0.8.0;

interface IAggregatorV3 {
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File: contracts/libraries/types/PriceConsumer.sol


pragma solidity ^0.8.7;


contract PriceConsumer {
    /**
     * Returns the latest price
     */
    function getLatestPriceData(address _feed)
        public
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt, // relevant timestamp
            uint80 answeredInRound
        )
    {
        return IAggregatorV3(_feed).latestRoundData();
    }

    function calculatePerformance(int256 _newPrice, int256 _oldPrice) internal pure returns (int256 _pricePerformance) {
        _pricePerformance = ((_newPrice - _oldPrice) * 1e18) / _oldPrice;
    }
}

// File: contracts/interfaces/ERC20/IERC20.sol


pragma solidity 0.8.15;

interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: contracts/interfaces/Digital/ICallBondDepository.sol


pragma solidity >=0.8.15;


// solhint-disable max-line-length

interface ICallBondDepository {
    // Info about each type of market
    struct Market {
        uint256 capacity; // capacity remaining
        IERC20 asset; // token to accept as payment
        address underlying;
        bool capacityInQuote; // capacity limit is in payment token (true) or in REQ (false, default)
        uint256 totalDebt; // total debt from market
        uint256 maxPayout; // max tokens in/out (determined by capacityInQuote false/true, respectively)
        uint256 sold; // base tokens out
        uint256 purchased; // quote tokens in
    }

    // Info for creating new markets
    struct Terms {
        bool fixedTerm; // fixed term or fixed expiration
        int256 thresholdPercentage;
        uint256 payoffPercentage; // percentage that is paid on top of the notional if exercised
        uint256 controlVariable; // scaling variable for price
        uint48 vesting; // length of time from deposit to maturity if fixed-term
        uint48 exerciseDuration;
        uint48 conclusion; // timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
        uint256 maxDebt; // 18 decimal debt maximum in REQ
    }

    // Additional info about market.
    struct Metadata {
        uint48 lastTune; // last timestamp when control variable was tuned
        uint48 lastDecay; // last timestamp when market was created and debt was decayed
        uint48 length; // time from creation to conclusion. used as speed to decay debt.
        uint48 depositInterval; // target frequency of deposits
        uint48 tuneInterval; // frequency of tuning
        uint8 assetDecimals; // decimals of quote token
    }

    // Control variable adjustment data
    struct Adjustment {
        uint256 change;
        uint48 lastAdjustment;
        uint48 timeToAdjusted;
        bool active;
    }

    /**
     * @notice deposit market
     * @param _bid uint256
     * @param _amount uint256
     * @param _maxPrice uint256
     * @param _user address
     * @param _referral address
     * @return payout_ uint256
     * @return expiry_ uint256
     * @return index_ uint256
     */
    function deposit(
        uint256 _bid,
        uint256 _amount,
        uint256 _maxPrice,
        address _user,
        address _referral
    )
        external
        returns (
            uint256 payout_,
            uint256 expiry_,
            uint256 index_
        );

    function create(
        IERC20 _asset, // token used to deposit
        address _underlying,
        uint256[5] memory _market, // [capacity, initial price, buffer, threshold percentage, digital payoff]
        bool[2] memory _booleans, // [capacity in quote, fixed term]
        uint256[3] memory _terms, // [vesting, conclusion]
        uint32[2] memory _intervals // [deposit interval, tune interval]
    ) external returns (uint256 id_);

    function close(uint256 _id) external;

    function isLive(uint256 _bid) external view returns (bool);

    function liveMarkets() external view returns (uint256[] memory);

    function liveMarketsFor(address _asset) external view returns (uint256[] memory);

    // notional payout
    function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);

    // option payout
    function optionPayoutFor(
        address _user,
        uint256 _index
    ) external view returns (uint256);

    function marketPrice(uint256 _bid) external view returns (uint256);

    function currentDebt(uint256 _bid) external view returns (uint256);

    function debtRatio(uint256 _bid) external view returns (uint256);

    function debtDecay(uint256 _bid) external view returns (uint256);

    // redemtion and exercise
    function redeem(address _user, uint256[] memory _indexes) external returns (uint256);

    function redeemAll(address _user) external returns (uint256);
}

// File: contracts/libraries/SafeERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;



// solhint-disable  max-line-length

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
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
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

// File: contracts/interfaces/IAuthority.sol


pragma solidity >=0.8.15;

interface IAuthority {
    /* ========== EVENTS ========== */

    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */

    function governor() external view returns (address);

    function guardian() external view returns (address);

    function policy() external view returns (address);

    function vault() external view returns (address);
}

// File: contracts/libraries/types/AccessControlled.sol



pragma solidity >=0.8.15;


abstract contract AccessControlled {
  /* ========== EVENTS ========== */

  event AuthorityUpdated(IAuthority indexed authority);

  string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

  /* ========== STATE VARIABLES ========== */

  IAuthority public authority;

  /* ========== Constructor ========== */

  function intitalizeAuthority(IAuthority _authority) internal {
    authority = _authority;
  }

  /* ========== MODIFIERS ========== */

  modifier onlyGovernor() {
    require(msg.sender == authority.governor(), UNAUTHORIZED);
    _;
  }

  modifier onlyGuardian() {
    require(msg.sender == authority.guardian(), UNAUTHORIZED);
    _;
  }

  modifier onlyPolicy() {
    require(msg.sender == authority.policy(), UNAUTHORIZED);
    _;
  }

  modifier onlyVault() {
    require(msg.sender == authority.vault(), UNAUTHORIZED);
    _;
  }

  /* ========== GOV ONLY ========== */

  function setAuthority(IAuthority _newAuthority) external onlyGovernor {
    authority = _newAuthority;
    emit AuthorityUpdated(_newAuthority);
  }
}

// File: contracts/libraries/types/FrontEndRewarder.sol



pragma solidity ^0.8.10;



abstract contract FrontEndRewarder is AccessControlled {
  /* ========= STATE VARIABLES ========== */

  uint256 public daoReward; // % reward for dao (3 decimals: 100 = 1%)
  uint256 public refReward; // % reward for referrer (3 decimals: 100 = 1%)
  mapping(address => uint256) public rewards; // front end operator rewards
  mapping(address => bool) public whitelisted; // whitelisted status for operators

  IERC20 public immutable req; // reward token

  constructor(IAuthority _authority, IERC20 _req) {
    intitalizeAuthority(IAuthority(_authority));
    req = _req;
  }

  /* ========= EXTERNAL FUNCTIONS ========== */

  // pay reward to front end operator
  function getReward() external {
    uint256 reward = rewards[msg.sender];

    rewards[msg.sender] = 0;
    req.transfer(msg.sender, reward);
  }

  /* ========= INTERNAL ========== */

  /**
   * @notice add new market payout to user data
   */
  function _giveRewards(uint256 _payout, address _referral)
    internal
    returns (uint256)
  {
    // first we calculate rewards paid to the DAO and to the front end operator (referrer)
    uint256 toDAO = (_payout * daoReward) / 1e4;
    uint256 toRef = (_payout * refReward) / 1e4;

    // and store them in our rewards mapping
    if (whitelisted[_referral]) {
      rewards[_referral] += toRef;
      rewards[authority.guardian()] += toDAO;
    } else {
      // the DAO receives both rewards if referrer is not whitelisted
      rewards[authority.guardian()] += toDAO + toRef;
    }
    return toDAO + toRef;
  }

  /**
   * @notice set rewards for front end operators and DAO
   */
  function setRewards(uint256 _toFrontEnd, uint256 _toDAO)
    external
    onlyGovernor
  {
    refReward = _toFrontEnd;
    daoReward = _toDAO;
  }

  /**
   * @notice add or remove addresses from the reward whitelist
   */
  function whitelist(address _operator) external onlyPolicy {
    whitelisted[_operator] = !whitelisted[_operator];
  }
}

// File: contracts/libraries/types/CallUserTermsKeeper.sol



pragma solidity ^0.8.10;





// solhint-disable max-line-length

abstract contract CallUserTermsKeeper is IUserTermsKeeper, FrontEndRewarder, PriceConsumer {
    mapping(address => UserTerms[]) public userTerms; // user deposit data
    mapping(address => mapping(uint256 => address)) private noteTransfers; // change note ownership

    ITreasury internal treasury;

    constructor(IERC20 _req, address _treasury) FrontEndRewarder(IAuthority(_treasury), _req) {
        treasury = ITreasury(_treasury);
    }

    // if treasury address changes on authority, update it
    function updateTreasury() external {
        require(msg.sender == authority.governor() || msg.sender == authority.guardian() || msg.sender == authority.policy(), "Only authorized");
        treasury = ITreasury(authority.vault());
    }

    /* ========== ADD ========== */

    /**
     * @notice             adds a new Terms for a user, stores the front end & DAO rewards, and mints & stakes payout & rewards
     * @param _user        the user that owns the Terms
     * @param _payout      the amount of REQ due to the user
     * @param _expiry      the timestamp when the Terms is redeemable
     * @param _marketID    the ID of the market deposited into
     * @return index_      the index of the Terms in the user's array
     */
    function addTerms(
        address _user,
        address _underlying,
        uint256 _payout,
        uint48 _expiry,
        uint48 _marketID,
        address _referral
    ) internal returns (uint256 index_, int256 _fetchedPrice) {
        // the index of the note is the next in the user's array
        index_ = userTerms[_user].length;

        (, _fetchedPrice, , , ) = getLatestPriceData(_underlying);

        // the new note is pushed to the user's array
        userTerms[_user].push(
            UserTerms({
                payout: _payout,
                cryptoIntitialPrice: _fetchedPrice,
                cryptoClosingPrice: 0,
                created: uint48(block.timestamp),
                matured: _expiry,
                redeemed: 0,
                exercised: 0,
                marketID: _marketID
            })
        );

        // front end operators can earn rewards by referring users
        uint256 rewards = _giveRewards(_payout, _referral);

        // mint payout and rewards
        treasury.mint(address(this), _payout + rewards);
    }

    /* ========== TRANSFER ========== */

    /**
     * @notice             approve an address to transfer a note
     * @param _to          address to approve note transfer for
     * @param _index       index of note to approve transfer for
     */
    function pushTerms(address _to, uint256 _index) external override {
        require(userTerms[msg.sender][_index].created != 0, "Depository: note not found");
        noteTransfers[msg.sender][_index] = _to;
    }

    /**
     * @notice             transfer a note that has been approved by an address
     * @param _from        the address that approved the note transfer
     * @param _index       the index of the note to transfer (in the sender's array)
     */
    function pullTerms(address _from, uint256 _index) external override returns (uint256 newIndex_) {
        require(noteTransfers[_from][_index] == msg.sender, "Depository: transfer not found");
        require(userTerms[_from][_index].redeemed == 0, "Depository: note redeemed");

        newIndex_ = userTerms[msg.sender].length;
        userTerms[msg.sender].push(userTerms[_from][_index]);

        delete userTerms[_from][_index];
    }

    /* ========== VIEW ========== */

    // Terms info

    /**
     * @notice             all pending userTerms for user
     * @param _user        the user to query userTerms for
     * @return             the pending userTerms for the user
     */
    function indexesFor(address _user) public view override returns (uint256[] memory) {
        UserTerms[] memory info = userTerms[_user];

        uint256 length;
        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].redeemed == 0 && info[i].payout != 0) length++;
        }

        uint256[] memory indexes = new uint256[](length);
        uint256 position;

        for (uint256 i = 0; i < info.length; i++) {
            if (info[i].redeemed == 0 && info[i].payout != 0) {
                indexes[position] = i;
                position++;
            }
        }

        return indexes;
    }
}

// File: contracts/DigitalCallBondDepository.sol


pragma solidity ^0.8.15;




// solhint-disable  max-line-length

/// @title Digital Call Bond Depository
/// @author Achthar

contract DigitalCallBondDepository is ICallBondDepository, CallUserTermsKeeper {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;

    /* ======== EVENTS ======== */

    event CreateMarket(uint256 indexed id, address indexed baseToken, address indexed asset, uint256 initialPrice);
    event CloseMarket(uint256 indexed id);
    event Bond(uint256 indexed id, uint256 amount, uint256 price, int256 underlyingReference);
    event OptionExercise(uint256 indexed id, uint256 payout);
    event Tuned(uint256 indexed id, uint256 oldControlVariable, uint256 newControlVariable);

    /* ======== STATE VARIABLES ======== */

    // Storage
    Market[] public markets; // persistent market data
    Terms[] public terms; // deposit construction data
    Metadata[] public metadata; // extraneous market data
    mapping(uint256 => Adjustment) public adjustments; // control variable changes

    // Queries
    mapping(address => uint256[]) public marketsForQuote; // market IDs for quote token

    /* ======== CONSTRUCTOR ======== */

    constructor(IERC20 _req, address _treasury) CallUserTermsKeeper(_req, _treasury) {}

    /* ======== CREATE ======== */

    /**
     * @notice             creates a new market type
     * @dev                current price should be in 9 decimals.
     * @param _asset       token used to deposit
     * @param _underlying  oracle to povede price data for option component
     * @param _market      [capacity (in REQ or quote), initial price / REQ (18 decimals), debt buffer (3 decimals), threshold (percent), option cap (percent)]
     * @param _booleans    [capacity in quote, fixed term]
     * @param _terms       [vesting length (if fixed term) or vested timestamp, conclusion timestamp, exercise duration]
     * @param _intervals   [deposit interval (seconds), tune interval (seconds)]
     * @return id_         ID of new bond market
     */
    function create(
        IERC20 _asset,
        address _underlying,
        uint256[5] memory _market,
        bool[2] memory _booleans,
        uint256[3] memory _terms,
        uint32[2] memory _intervals
    ) external override onlyPolicy returns (uint256 id_) {
        // the length of the program, in seconds
        uint256 secondsToConclusion = _terms[1] - block.timestamp;

        // the decimal count of the quote token
        uint256 decimals = _asset.decimals();

        /*
         * initial target debt is equal to capacity (this is the amount of debt
         * that will decay over in the length of the program if price remains the same).
         * it is converted into base token terms if passed in in quote token terms.
         *
         * -> prices the capacity in quote token if desired
         */
        uint256 targetDebt = uint256(_booleans[0] ? ((treasury.assetValue(address(_asset), _market[0]) * 1e18) / _market[1]) : _market[0]);

        /*
         * max payout is the amount of capacity that should be utilized in a deposit
         * interval. for example, if capacity is 1,000 REQ, there are 10 days to conclusion,
         * and the preferred deposit interval is 1 day, max payout would be 100 REQ.
         */
        uint256 maxPayout = uint256((targetDebt * _intervals[0]) / secondsToConclusion);

        /*
         * max debt serves as a circuit breaker for the market. let's say the quote
         * token is a stablecoin, and that stablecoin depegs. without max debt, the
         * market would continue to buy until it runs out of capacity. this is
         * configurable with a 3 decimal buffer (1000 = 1% above initial price).
         * note that its likely advisable to keep this buffer wide.
         * note that the buffer is above 100%. i.e. 10% buffer = initial debt * 1.1
         */
        uint256 maxDebt = targetDebt + ((targetDebt * _market[2]) / 1e5); // 1e5 = 100,000. 10,000 / 100,000 = 10%.

        /*
         * the control variable is set so that initial price equals the desired
         * initial price. the control variable is the ultimate determinant of price,
         * so we compute this last.
         *
         * price = control variable * debt ratio
         * debt ratio = total debt / supply
         * therefore, control variable = price / debt ratio
         */
        uint256 controlVariable = (_market[1] * treasury.baseSupply()) / targetDebt;

        // depositing into, or getting info for, the created market uses this ID
        id_ = markets.length;

        markets.push(
            Market({
                asset: _asset,
                underlying: _underlying,
                capacityInQuote: _booleans[0],
                capacity: _market[0],
                totalDebt: targetDebt,
                maxPayout: maxPayout,
                purchased: 0,
                sold: 0
            })
        );

        terms.push(
            Terms({
                fixedTerm: _booleans[1],
                thresholdPercentage: int256(_market[3]),
                payoffPercentage: _market[4],
                vesting: uint48(_terms[0]),
                conclusion: uint48(_terms[1]),
                exerciseDuration: uint48(_terms[2]),
                controlVariable: controlVariable,
                maxDebt: maxDebt
            })
        );

        metadata.push(
            Metadata({
                lastTune: uint48(block.timestamp),
                lastDecay: uint48(block.timestamp),
                length: uint48(secondsToConclusion),
                depositInterval: _intervals[0],
                tuneInterval: _intervals[1],
                assetDecimals: uint8(decimals)
            })
        );

        marketsForQuote[address(_asset)].push(id_);

        emit CreateMarket(id_, address(req), address(_asset), _market[1]);
    }

    /**
     * @notice             disable existing market
     * @param _id          ID of market to close
     */
    function close(uint256 _id) external override onlyPolicy {
        terms[_id].conclusion = uint48(block.timestamp);
        markets[_id].capacity = 0;
        emit CloseMarket(_id);
    }

    /* ======== DEPOSIT ======== */

    /**
     * @notice             deposit quote tokens in exchange for a bond from a specified market
     * @param _id          the ID of the market
     * @param _amount      the amount of quote token to spend
     * @param _maxPrice    the maximum price at which to buy
     * @param _user        the recipient of the payout
     * @param _referral    the front end operator address
     * @return payout_     the amount of REQ due
     * @return expiry_     the timestamp at which payout is redeemable
     * @return index_      the user index of the Terms (used to redeem or query information)
     */
    function deposit(
        uint256 _id,
        uint256 _amount,
        uint256 _maxPrice,
        address _user,
        address _referral
    )
        external
        override
        returns (
            uint256 payout_,
            uint256 expiry_,
            uint256 index_
        )
    {
        Market storage market = markets[_id];
        Terms memory term = terms[_id];
        uint48 currentTime = uint48(block.timestamp);

        // Markets end at a defined timestamp
        // |-------------------------------------| t
        require(currentTime < term.conclusion, "Depository: market concluded");

        // Debt and the control variable decay over time
        _decay(_id, currentTime);

        expiry_ = term.fixedTerm ? term.vesting + currentTime : term.vesting;

        // use one function for multiple checks to avoid stack-to-deep issues
        (index_, payout_) = _bondAsset(_user, _maxPrice, market, _id, _amount, uint48(expiry_), _referral);

        /*
         * each market is initialized with a capacity
         *
         * this is either the number of REQ that the market can sell
         * (if capacity in quote is false),
         *
         * or the number of quote tokens that the market can buy
         * (if capacity in quote is true)
         */
        market.capacity -= market.capacityInQuote ? _amount : payout_;

        /**
         * bonds mature with a cliff at a set timestamp
         * prior to the expiry timestamp, no payout tokens are accessible to the user
         * after the expiry timestamp, the entire payout can be redeemed
         *
         * there are two types of bonds: fixed-term and fixed-expiration
         *
         * fixed-term bonds mature in a set amount of time from deposit
         * i.e. term = 1 week. when alice deposits on day 1, her bond
         * expires on day 8. when bob deposits on day 2, his bond expires day 9.
         *
         * fixed-expiration bonds mature at a set timestamp
         * i.e. expiration = day 10. when alice deposits on day 1, her term
         * is 9 days. when bob deposits on day 2, his term is 8 days.
         */

        // markets keep track of how many quote tokens have been
        // purchased, and how much REQ has been sold
        market.purchased += _amount;
        market.sold += payout_;

        // incrementing total debt raises the price of the next bond
        market.totalDebt += payout_;

        // transfer payment to treasury
        market.asset.safeTransferFrom(msg.sender, address(treasury), _amount);

        // if max debt is breached, the market is closed
        // this a circuit breaker
        if (term.maxDebt < market.totalDebt) {
            market.capacity = 0;
            emit CloseMarket(_id);
        } else {
            // if market will continue, the control variable is tuned to hit targets on time
            _tune(_id, currentTime);
        }
    }

    /* ========== REDEEM ========== */

    /**
     * @notice             redeem userTerms for user
     * @param _user        the user to redeem for
     * @param _indexes     the note indexes to redeem
     * @return payout_     sum of payout sent, in REQ
     */
    function redeem(address _user, uint256[] memory _indexes) public override returns (uint256 payout_) {
        uint48 time = uint48(block.timestamp);

        for (uint256 i = 0; i < _indexes.length; i++) {
            (uint256 pay, bool matured, bool payoffClaimable) = pendingFor(_user, _indexes[i]);
            uint256 marketId = userTerms[_user][_indexes[i]].marketID;

            // check whether notional can be claimed
            if (matured) {
                userTerms[_user][_indexes[i]].redeemed = time; // mark as claimed
                payout_ += pay;
            }

            // check whether option can be exercised
            (, int256 _fetchedPrice, , , ) = getLatestPriceData(markets[marketId].underlying);
            if (payoffClaimable) {
                bool exercisable = _calculatePayoff(
                    userTerms[_user][_indexes[i]].cryptoIntitialPrice,
                    _fetchedPrice,
                    terms[marketId].thresholdPercentage
                );
                userTerms[_user][_indexes[i]].cryptoClosingPrice = _fetchedPrice;
                if (exercisable) {
                    userTerms[_user][_indexes[i]].exercised = time; // mark as exercised
                    uint256 digitalPayoff = (terms[marketId].payoffPercentage * pay) / 1e18;
                    // add digital payoff
                    payout_ += digitalPayoff;
                    // mint option payoff
                    treasury.mint(address(this), digitalPayoff);
                    emit OptionExercise(marketId, digitalPayoff);
                }
            }
        }

        // transfer notionals and digital payoffs
        req.transfer(_user, payout_);
    }

    /**
     * @notice             redeem all redeemable markets for user
     * @dev                if possible, query indexesFor() off-chain and input in redeem() to save gas
     * @param _user        user to redeem all userTerms for
     * @return             sum of payout sent, in REQ
     */
    function redeemAll(address _user) external override returns (uint256) {
        return redeem(_user, indexesFor(_user));
    }

    /**
     * @notice             decay debt, and adjust control variable if there is an active change
     * @param _id          ID of market
     * @param _time        uint48 timestamp (saves gas when passed in)
     */
    function _decay(uint256 _id, uint48 _time) internal {
        // Debt decay

        /*
         * Debt is a time-decayed sum of tokens spent in a market
         * Debt is added when deposits occur and removed over time
         * |
         * |    debt falls with
         * |   / \  inactivity       / \
         * | /     \              /\/    \
         * |         \           /         \
         * |           \      /\/            \
         * |             \  /  and rises       \
         * |                with deposits
         * |
         * |------------------------------------| t
         */
        markets[_id].totalDebt -= debtDecay(_id);
        metadata[_id].lastDecay = _time;

        // Control variable decay

        // The bond control variable is continually tuned. When it is lowered (which
        // lowers the market price), the change is carried out smoothly over time.
        if (adjustments[_id].active) {
            Adjustment storage adjustment = adjustments[_id];

            (uint256 adjustBy, uint48 secondsSince, bool stillActive) = _controlDecay(_id);
            terms[_id].controlVariable -= adjustBy;

            if (stillActive) {
                adjustment.change -= adjustBy;
                adjustment.timeToAdjusted -= secondsSince;
                adjustment.lastAdjustment = _time;
            } else {
                adjustment.active = false;
            }
        }
    }

    /**
     * @notice             auto-adjust control variable to hit capacity/spend target
     * @param _id          ID of market
     * @param _time        uint48 timestamp (saves gas when passed in)
     */
    function _tune(uint256 _id, uint48 _time) internal {
        Metadata memory meta = metadata[_id];

        if (_time >= meta.lastTune + meta.tuneInterval) {
            Market memory market = markets[_id];

            // compute seconds remaining until market will conclude
            uint256 timeRemaining = terms[_id].conclusion - _time;
            uint256 price = _marketPrice(_id);

            // standardize capacity into an base token amount
            uint256 capacity = market.capacityInQuote
                ? (treasury.assetValue(address(market.asset), market.capacity) * 1e18) / price
                : market.capacity;

            /**
             * calculate the correct payout to complete on time assuming each bond
             * will be max size in the desired deposit interval for the remaining time
             *
             * i.e. market has 10 days remaining. deposit interval is 1 day. capacity
             * is 10,000 REQ. max payout would be 1,000 REQ (10,000 * 1 / 10).
             */
            markets[_id].maxPayout = uint256((capacity * meta.depositInterval) / timeRemaining);

            // calculate the ideal total debt to satisfy capacity in the remaining time
            uint256 targetDebt = (capacity * meta.length) / timeRemaining;

            // derive a new control variable from the target debt and current supply
            uint256 newControlVariable = uint256((price * treasury.baseSupply()) / targetDebt);

            emit Tuned(_id, terms[_id].controlVariable, newControlVariable);

            if (newControlVariable >= terms[_id].controlVariable) {
                terms[_id].controlVariable = newControlVariable;
            } else {
                // if decrease, control variable change will be carried out over the tune interval
                // this is because price will be lowered
                uint256 change = terms[_id].controlVariable - newControlVariable;
                adjustments[_id] = Adjustment(change, _time, meta.tuneInterval, true);
            }
            metadata[_id].lastTune = _time;
        }
    }

    /**
     * @notice  fetches prices from oracle and adds a new Terms for a user
     */
    function _bondAsset(
        address _user,
        uint256 _maxPrice,
        Market memory _market,
        uint256 _marketId,
        uint256 _amount,
        uint48 _expiry,
        address _referral
    ) internal returns (uint256, uint256) {
        // entering the mempool. max price is a slippage mitigation measure
        uint256 _price = _marketPrice(_marketId);
        require(_price <= _maxPrice, "Depository: more than max price");

        /**
         * payout for the deposit = value / price
         */
        uint256 _payout = (treasury.assetValue(address(_market.asset), _amount) * 1e18) / _price;

        require(_payout <= _market.maxPayout, "Depository: max size exceeded");

        // the new note is pushed to the user's array
        (uint256 _index, int256 _fetchedPrice) = addTerms(_user, _market.underlying, _payout, _expiry, uint48(_marketId), _referral);
        // mint payout and rewards
        treasury.mint(address(this), _payout);

        emit Bond(_marketId, _amount, _price, _fetchedPrice);

        return (_index, _payout);
    }

    /* ======== EXTERNAL VIEW ======== */

    /**
     * @notice             calculate amount available for claim for a single note
     * @param _user        the user that the note belongs to
     * @param _index       the index of the note in the user's array
     * @return payout_     the payout due, in gREQ
     * @return matured_    if the payout can be redeemed
     */
    function pendingFor(address _user, uint256 _index)
        public
        view
        returns (
            uint256 payout_,
            bool matured_,
            bool payoffClaimable_
        )
    {
        UserTerms memory note = userTerms[_user][_index];

        payout_ = note.payout;
        matured_ = note.redeemed == 0 && note.matured <= block.timestamp && payout_ != 0;
        // notional can already have been claimed
        payoffClaimable_ =
            note.exercised == 0 &&
            note.matured <= block.timestamp &&
            note.matured + terms[note.marketID].exerciseDuration >= block.timestamp;
    }

    /**
     * @notice             calculate current market price of quote token in base token
     * @dev                accounts for debt and control variable decay since last deposit (vs _marketPrice())
     * @param _id          ID of market
     * @return             price for market in REQ decimals
     *
     * price is derived from the equation
     *
     * p = cv * dr
     *
     * where
     * p = price
     * cv = control variable
     * dr = debt ratio
     *
     * dr = d / s
     *
     * where
     * d = debt
     * s = supply of token at market creation
     *
     * d -= ( d * (dt / l) )
     *
     * where
     * dt = change in time
     * l = length of program
     */
    function marketPrice(uint256 _id) public view override returns (uint256) {
        return (currentControlVariable(_id) * debtRatio(_id)) / (10**metadata[_id].assetDecimals);
    }

    /**
     * @notice             payout due for amount of quote tokens
     * @dev                accounts for debt and control variable decay so it is up to date
     * @param _amount      amount of quote tokens to spend
     * @param _id          ID of market
     * @return             amount of REQ to be paid in REQ decimals
     *
     * @dev we assume that the market price decimals and req decimals match (that is why we use 2 * req decimals)
     */
    function payoutFor(uint256 _amount, uint256 _id) external view override returns (uint256) {
        Market memory market = markets[_id];
        return (treasury.assetValue(address(market.asset), _amount) * 1e18) / marketPrice(_id);
    }

    /**
     * @notice             calculates the intrinsic option value for a specific userTerm
     * @param _user        user to fetch data for
     * @param _index       index of userTerm
     * @return payoff_     amount of REQ to be paid in REQ decimals if option could be exercised now
     *
     * @dev we assume that the market price decimals and req decimals match (that is why we use 2 * req decimals)
     */
    function optionPayoutFor(address _user, uint256 _index) external view override returns (uint256 payoff_) {
        UserTerms memory userTerm = userTerms[_user][_index];
        uint256 _id = userTerms[_user][_index].marketID;

        (, int256 _fetchedPrice, , , ) = getLatestPriceData(markets[_id].underlying);

        bool exercisable = _calculatePayoff(userTerm.cryptoIntitialPrice, _fetchedPrice, terms[_id].thresholdPercentage);
        if (exercisable) {
            payoff_ = (terms[_id].payoffPercentage * userTerm.payout) / 1e18;
        }
    }

    /**
     * @notice             calculate current ratio of debt to supply
     * @dev                uses current debt, which accounts for debt decay since last deposit (vs _debtRatio())
     * @param _id          ID of market
     * @return             debt ratio for market in quote decimals
     */
    function debtRatio(uint256 _id) public view override returns (uint256) {
        return (currentDebt(_id) * (10**metadata[_id].assetDecimals)) / treasury.baseSupply();
    }

    /**
     * @notice             calculate debt factoring in decay
     * @dev                accounts for debt decay since last deposit
     * @param _id          ID of market
     * @return             current debt for market in REQ decimals
     */
    function currentDebt(uint256 _id) public view override returns (uint256) {
        return markets[_id].totalDebt - debtDecay(_id);
    }

    /**
     * @notice             amount of debt to decay from total debt for market ID
     * @param _id          ID of market
     * @return             amount of debt to decay
     */
    function debtDecay(uint256 _id) public view override returns (uint256) {
        Metadata memory meta = metadata[_id];

        uint256 secondsSince = block.timestamp - meta.lastDecay;

        return (markets[_id].totalDebt * secondsSince) / meta.length;
    }

    /**
     * @notice             up to date control variable
     * @dev                accounts for control variable adjustment
     * @param _id          ID of market
     * @return             control variable for market in REQ decimals
     */
    function currentControlVariable(uint256 _id) public view returns (uint256) {
        (uint256 decay, , ) = _controlDecay(_id);
        return terms[_id].controlVariable - decay;
    }

    /**
     * @notice             is a given market accepting deposits
     * @param _id          ID of market
     */
    function isLive(uint256 _id) public view override returns (bool) {
        return (markets[_id].capacity != 0 && terms[_id].conclusion > block.timestamp);
    }

    /**
     * @notice returns an array of all active market IDs
     */
    function liveMarkets() external view override returns (uint256[] memory) {
        uint256 num;
        for (uint256 i = 0; i < markets.length; i++) {
            if (isLive(i)) num++;
        }

        uint256[] memory ids = new uint256[](num);
        uint256 nonce;
        for (uint256 i = 0; i < markets.length; i++) {
            if (isLive(i)) {
                ids[nonce] = i;
                nonce++;
            }
        }
        return ids;
    }

    /**
     * @notice             returns an array of all active market IDs for a given quote token
     * @param _token       quote token to check for
     */
    function liveMarketsFor(address _token) external view override returns (uint256[] memory) {
        uint256[] memory mkts = marketsForQuote[_token];
        uint256 num;

        for (uint256 i = 0; i < mkts.length; i++) {
            if (isLive(mkts[i])) num++;
        }

        uint256[] memory ids = new uint256[](num);
        uint256 nonce;

        for (uint256 i = 0; i < mkts.length; i++) {
            if (isLive(mkts[i])) {
                ids[nonce] = mkts[i];
                nonce++;
            }
        }
        return ids;
    }

    /* ======== INTERNAL VIEW ======== */

    function _calculatePayoff(
        int256 _initialPrice,
        int256 _priceNow,
        int256 _strike
    ) internal pure returns (bool) {
        int256 _kMinusS = _priceNow * 1e18 - (1e18 + _strike) * _initialPrice;
        return _kMinusS / 1e18 >= 0;
    }

    /**
     * @notice                  calculate current market price of quote token in base token
     * @dev                     see marketPrice() for explanation of price computation
     * @dev                     uses info from storage because data has been updated before call (vs marketPrice())
     * @param _id               market ID
     * @return                  price for market in REQ decimals
     */
    function _marketPrice(uint256 _id) internal view returns (uint256) {
        return (terms[_id].controlVariable * _debtRatio(_id)) / (10**metadata[_id].assetDecimals);
    }

    /**
     * @notice                  calculate debt factoring in decay
     * @dev                     uses info from storage because data has been updated before call (vs debtRatio())
     * @param _id               market ID
     * @return                  current debt for market in quote decimals
     */
    function _debtRatio(uint256 _id) internal view returns (uint256) {
        return (markets[_id].totalDebt * (10**metadata[_id].assetDecimals)) / treasury.baseSupply();
    }

    /**
     * @notice                  amount to decay control variable by
     * @param _id               ID of market
     * @return decay_           change in control variable
     * @return secondsSince_    seconds since last change in control variable
     * @return active_          whether or not change remains active
     */
    function _controlDecay(uint256 _id)
        internal
        view
        returns (
            uint256 decay_,
            uint48 secondsSince_,
            bool active_
        )
    {
        Adjustment memory info = adjustments[_id];
        if (!info.active) return (0, 0, false);

        secondsSince_ = uint48(block.timestamp) - info.lastAdjustment;

        active_ = secondsSince_ < info.timeToAdjusted;
        decay_ = active_ ? (info.change * secondsSince_) / info.timeToAdjusted : info.change;
    }
}