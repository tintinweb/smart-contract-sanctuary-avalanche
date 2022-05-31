// SPDX-License-Identifier: MIT

pragma solidity >=0.8.14;

import "./interfaces/IAuthority.sol";

import "./libraries/types/AccessControlled.sol";

contract Authority is IAuthority, AccessControlled {
  /* ========== STATE VARIABLES ========== */

  address public override governor;

  address public override guardian;

  address public override policy;

  address public override vault;

  address public newGovernor;

  address public newGuardian;

  address public newPolicy;

  address public newVault;

  /* ========== Constructor ========== */

  constructor(
    address _governor,
    address _guardian,
    address _policy,
    address _vault
  )  {
    intitalizeAuthority(IAuthority(address(this)));
    governor = _governor;
    emit GovernorPushed(address(0), governor, true);
    guardian = _guardian;
    emit GuardianPushed(address(0), guardian, true);
    policy = _policy;
    emit PolicyPushed(address(0), policy, true);
    vault = _vault;
    emit VaultPushed(address(0), vault, true);
  }

  /* ========== GOV ONLY ========== */

  function pushGovernor(address _newGovernor, bool _effectiveImmediately)
    external
    onlyGovernor
  {
    if (_effectiveImmediately) governor = _newGovernor;
    newGovernor = _newGovernor;
    emit GovernorPushed(governor, newGovernor, _effectiveImmediately);
  }

  function pushGuardian(address _newGuardian, bool _effectiveImmediately)
    external
    onlyGovernor
  {
    if (_effectiveImmediately) guardian = _newGuardian;
    newGuardian = _newGuardian;
    emit GuardianPushed(guardian, newGuardian, _effectiveImmediately);
  }

  function pushPolicy(address _newPolicy, bool _effectiveImmediately)
    external
    onlyGovernor
  {
    if (_effectiveImmediately) policy = _newPolicy;
    newPolicy = _newPolicy;
    emit PolicyPushed(policy, newPolicy, _effectiveImmediately);
  }

  function pushVault(address _newVault, bool _effectiveImmediately)
    external
    onlyGovernor
  {
    if (_effectiveImmediately) vault = _newVault;
    newVault = _newVault;
    emit VaultPushed(vault, newVault, _effectiveImmediately);
  }

  /* ========== PENDING ROLE ONLY ========== */

  function pullGovernor() external {
    require(msg.sender == newGovernor, "!newGovernor");
    emit GovernorPulled(governor, newGovernor);
    governor = newGovernor;
  }

  function pullGuardian() external {
    require(msg.sender == newGuardian, "!newGuard");
    emit GuardianPulled(guardian, newGuardian);
    guardian = newGuardian;
  }

  function pullPolicy() external {
    require(msg.sender == newPolicy, "!newPolicy");
    emit PolicyPulled(policy, newPolicy);
    policy = newPolicy;
  }

  function pullVault() external {
    require(msg.sender == newVault, "!newVault");
    emit VaultPulled(vault, newVault);
    vault = newVault;
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.14;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.14;

import "../../interfaces/IAuthority.sol";

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.14;

import "../interfaces/ITreasury.sol";
import "../interfaces/ERC20/IERC20Mintable.sol";
import "../Authority.sol";

contract Treasury is ITreasury, Authority {
    IERC20Mintable REQ;

    constructor(address _req) Authority(msg.sender, msg.sender, msg.sender, msg.sender) {
        REQ = IERC20Mintable(_req);
    }

    function deposit(
        uint256 _amount,
        address _token,
        uint256 _profit
    ) external returns (uint256) {}

    function withdraw(uint256 _amount, address _token) external {}

    function assetValue(address _token, uint256 _amount) external view returns (uint256 value_) {}

    function mint(address _recipient, uint256 _amount) external {
      REQ.mint(_recipient, _amount);
    }

    function manage(address _token, uint256 _amount) external {}

    function incurDebt(uint256 amount_, address token_) external {}

    function repayDebtWithReserve(uint256 amount_, address token_) external {}

    function excessReserves() external view returns (int256) {}

    function baseSupply() external view returns (uint256) {}
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.14;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20Mintable {

  function mint(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./FrontEndRewarder.sol";

import "../../interfaces/IgREQ.sol";
// import "../../interfaces/IStaking.sol";
import "../../interfaces/ITreasury.sol";
import "../../interfaces/INoteKeeper.sol";

// solhint-disable max-line-length

abstract contract NoteKeeper is INoteKeeper, FrontEndRewarder {
    // mapping(address => Note[]) public notes; // user deposit data
    // mapping(address => mapping(uint256 => address)) private noteTransfers; // change note ownership

    // IgREQ internal immutable gREQ;
    // IStaking internal immutable staking;
    // ITreasury internal treasury;

    // constructor(
    //     IAuthority _authority,
    //     IERC20 _req,
    //     IgREQ _greq,
    //     IStaking _staking,
    //     ITreasury _treasury
    // ) FrontEndRewarder(_authority, _req) {
    //     gREQ = _greq;
    //     staking = _staking;
    //     treasury = _treasury;
    // }

    // // if treasury address changes on authority, update it
    // function updateTreasury() external {
    //     require(
    //         msg.sender == authority.governor() ||
    //             msg.sender == authority.guardian() ||
    //             msg.sender == authority.policy(),
    //         "Only authorized"
    //     );
    //     treasury = ITreasury(authority.vault());
    // }

    // /* ========== ADD ========== */

    // /**
    //  * @notice             adds a new Note for a user, stores the front end & DAO rewards, and mints & stakes payout & rewards
    //  * @param _user        the user that owns the Note
    //  * @param _payout      the amount of REQ due to the user
    //  * @param _expiry      the timestamp when the Note is redeemable
    //  * @param _marketID    the ID of the market deposited into
    //  * @return index_      the index of the Note in the user's array
    //  */
    // function addNote(
    //     address _user,
    //     uint256 _payout,
    //     uint48 _expiry,
    //     uint48 _marketID,
    //     address _referral
    // ) internal returns (uint256 index_) {
    //     // the index of the note is the next in the user's array
    //     index_ = notes[_user].length;

    //     // the new note is pushed to the user's array
    //     notes[_user].push(
    //         Note({
    //             payout: gREQ.balanceTo(_payout),
    //             created: uint48(block.timestamp),
    //             matured: _expiry,
    //             redeemed: 0,
    //             marketID: _marketID
    //         })
    //     );

    //     // front end operators can earn rewards by referring users
    //     uint256 rewards = _giveRewards(_payout, _referral);

    //     // mint and stake payout
    //     treasury.mint(address(this), _payout + rewards);

    //     // note that only the payout gets staked (front end rewards are in REQ)
    //     staking.stake(address(this), _payout, false, true);
    // }

    // /* ========== REDEEM ========== */

    // /**
    //  * @notice             redeem notes for user
    //  * @param _user        the user to redeem for
    //  * @param _indexes     the note indexes to redeem
    //  * @param _sendgREQ    send payout as gREQ or sREQ
    //  * @return payout_     sum of payout sent, in gREQ
    //  */
    // function redeem(
    //     address _user,
    //     uint256[] memory _indexes,
    //     bool _sendgREQ
    // ) public override returns (uint256 payout_) {
    //     uint48 time = uint48(block.timestamp);

    //     for (uint256 i = 0; i < _indexes.length; i++) {
    //         (uint256 pay, bool matured) = pendingFor(_user, _indexes[i]);

    //         if (matured) {
    //             notes[_user][_indexes[i]].redeemed = time; // mark as redeemed
    //             payout_ += pay;
    //         }
    //     }

    //     if (_sendgREQ) {
    //         gREQ.transfer(_user, payout_); // send payout as gREQ
    //     } else {
    //         staking.unwrap(_user, payout_); // unwrap and send payout as sREQ
    //     }
    // }

    // /**
    //  * @notice             redeem all redeemable markets for user
    //  * @dev                if possible, query indexesFor() off-chain and input in redeem() to save gas
    //  * @param _user        user to redeem all notes for
    //  * @param _sendgREQ    send payout as gREQ or sREQ
    //  * @return             sum of payout sent, in gREQ
    //  */
    // function redeemAll(address _user, bool _sendgREQ) external override returns (uint256) {
    //     return redeem(_user, indexesFor(_user), _sendgREQ);
    // }

    // /* ========== TRANSFER ========== */

    // /**
    //  * @notice             approve an address to transfer a note
    //  * @param _to          address to approve note transfer for
    //  * @param _index       index of note to approve transfer for
    //  */
    // function pushNote(address _to, uint256 _index) external override {
    //     require(notes[msg.sender][_index].created != 0, "Depository: note not found");
    //     noteTransfers[msg.sender][_index] = _to;
    // }

    // /**
    //  * @notice             transfer a note that has been approved by an address
    //  * @param _from        the address that approved the note transfer
    //  * @param _index       the index of the note to transfer (in the sender's array)
    //  */
    // function pullNote(address _from, uint256 _index) external override returns (uint256 newIndex_) {
    //     require(noteTransfers[_from][_index] == msg.sender, "Depository: transfer not found");
    //     require(notes[_from][_index].redeemed == 0, "Depository: note redeemed");

    //     newIndex_ = notes[msg.sender].length;
    //     notes[msg.sender].push(notes[_from][_index]);

    //     delete notes[_from][_index];
    // }

    // /* ========== VIEW ========== */

    // // Note info

    // /**
    //  * @notice             all pending notes for user
    //  * @param _user        the user to query notes for
    //  * @return             the pending notes for the user
    //  */
    // function indexesFor(address _user) public view override returns (uint256[] memory) {
    //     Note[] memory info = notes[_user];

    //     uint256 length;
    //     for (uint256 i = 0; i < info.length; i++) {
    //         if (info[i].redeemed == 0 && info[i].payout != 0) length++;
    //     }

    //     uint256[] memory indexes = new uint256[](length);
    //     uint256 position;

    //     for (uint256 i = 0; i < info.length; i++) {
    //         if (info[i].redeemed == 0 && info[i].payout != 0) {
    //             indexes[position] = i;
    //             position++;
    //         }
    //     }

    //     return indexes;
    // }

    // /**
    //  * @notice             calculate amount available for claim for a single note
    //  * @param _user        the user that the note belongs to
    //  * @param _index       the index of the note in the user's array
    //  * @return payout_     the payout due, in gREQ
    //  * @return matured_    if the payout can be redeemed
    //  */
    // function pendingFor(address _user, uint256 _index) public view override returns (uint256 payout_, bool matured_) {
    //     Note memory note = notes[_user][_index];

    //     payout_ = note.payout;
    //     matured_ = note.redeemed == 0 && note.matured <= block.timestamp && note.payout != 0;
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./AccessControlled.sol";
import "../../interfaces/ERC20/IERC20.sol";

abstract contract FrontEndRewarder is AccessControlled {
  /* ========= STATE VARIABLES ========== */

  uint256 public daoReward; // % reward for dao (3 decimals: 100 = 1%)
  uint256 public refReward; // % reward for referrer (3 decimals: 100 = 1%)
  mapping(address => uint256) public rewards; // front end operator rewards
  mapping(address => bool) public whitelisted; // whitelisted status for operators

  IERC20 internal immutable req; // reward token

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.14;

import "./ERC20/IERC20.sol";

interface IgREQ is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function index() external view returns (uint256);

    function balanceFrom(uint256 _amount) external view returns (uint256);

    function balanceTo(uint256 _amount) external view returns (uint256);

    function migrate(address _staking, address _sREQ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

interface INoteKeeper {
    // Info for market note
    struct Note {
        uint256 payout; // gREQ remaining to be paid
        uint48 created; // time market was created
        uint48 matured; // timestamp when market is matured
        uint48 redeemed; // time market was redeemed
        uint48 marketID; // market ID of deposit. uint48 to avoid adding a slot.
    }

    function redeem(
        address _user,
        uint256[] memory _indexes,
        bool _sendgREQ
    ) external returns (uint256);

    function redeemAll(address _user, bool _sendgREQ) external returns (uint256);

    function pushNote(address to, uint256 index) external;

    function pullNote(address from, uint256 index) external returns (uint256 newIndex_);

    function indexesFor(address _user) external view returns (uint256[] memory);

    function pendingFor(address _user, uint256 _index) external view returns (uint256 payout_, bool matured_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../interfaces/IAssetPricer.sol";
import "../interfaces/ERC20/IERC20.sol";
import "../interfaces/ISwap.sol";
import "../libraries/math/FixedPoint.sol";
import "../interfaces/IStableLPToken.sol";

/**
 * Bonding calculator for stable pool
 */
contract WeightedPoolPricer is IAssetPricer {
  using FixedPoint for *;

  address public immutable QUOTE;

  constructor(address _QUOTE) {
    require(_QUOTE != address(0));
    QUOTE = _QUOTE;
  }

  // calculates the liquidity value denominated in the provided token
  // uses the 0.01% inputAmount for that calculation
  // note that we never use the actual LP as input as the swap contains the LP address
  // and is also used to extract the balances
  function getTotalValue(address _lpAddress)
    public
    view
    returns (uint256 _value)
  {
    ISwap swap = IStableLPToken(_lpAddress).swap();
    IERC20[] memory tokens = swap.getPooledTokens();
    uint256[] memory reserves = swap.getTokenBalances();
    for (uint8 i = 0; i < reserves.length; i++) {
      address tokenAddr = address(tokens[i]);
      if (tokenAddr != QUOTE) {
        _value +=
          swap.calculateSwapGivenIn(tokenAddr, QUOTE, reserves[i] / 10000) *
          10000;
      }
    }
  }

  function valuation(address _lpAddress, uint256 amount_)
    external
    view
    override
    returns (uint256 _value)
  {
    uint256 totalValue = getTotalValue(_lpAddress);
    uint256 totalSupply = IStableLPToken(_lpAddress).totalSupply();

    _value =
      (totalValue *
        FixedPoint.fraction(amount_, totalSupply).decode112with18()) /
      1e18;
  }

  function markdown(address _lpAddress) external view returns (uint256) {
    return getTotalValue(_lpAddress);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IAssetPricer {
  function valuation(address _asset, uint256 _amount)
    external
    view
    returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./ERC20/IERC20.sol";

interface ISwap {
  function calculateSwapGivenIn(
    address tokenIn,
    address tokenOut,
    uint256 amountIn
  ) external view returns (uint256);

  function getTokenBalances() external view returns (uint256[] memory);

  function getPooledTokens() external view returns (IERC20[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./FullMath.sol";

library FixedPoint {
  struct uq112x112 {
    uint224 _x;
  }

  struct uq144x112 {
    uint256 _x;
  }

  uint8 private constant RESOLUTION = 112;
  uint256 private constant Q112 = 0x10000000000000000000000000000;
  uint256 private constant Q224 =
    0x100000000000000000000000000000000000000000000000000000000;
  uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

  function decode(uq112x112 memory self) internal pure returns (uint112) {
    return uint112(self._x >> RESOLUTION);
  }

  function decode112with18(uq112x112 memory self)
    internal
    pure
    returns (uint256)
  {
    return uint256(self._x) / 5192296858534827;
  }

  function fraction(uint256 numerator, uint256 denominator)
    internal
    pure
    returns (uq112x112 memory)
  {
    require(denominator > 0, "FixedPoint::fraction: division by zero");
    if (numerator == 0) return FixedPoint.uq112x112(0);

    if (numerator <= type(uint144).max) {
      uint256 result = (numerator << RESOLUTION) / denominator;
      require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    } else {
      uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
      require(result <= type(uint224).max, "FixedPoint::fraction: overflow");
      return uq112x112(uint224(result));
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./ISwap.sol";

interface IStableLPToken {
  function swap() external view returns (ISwap);

  function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.14;

// solhint-disable no-inline-assembly, reason-string, max-line-length

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = a * b
            // Compute the product mod 2**256 and mod 2**256 - 1
            // then use the Chinese Remainder Theorem to reconstruct
            // the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2**256 + prod0
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(a, b, not(0))
                prod0 := mul(a, b)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division
            if (prod1 == 0) {
                require(denominator > 0);
                assembly {
                    result := div(prod0, denominator)
                }
                return result;
            }

            // Make sure the result is less than 2**256.
            // Also prevents denominator == 0
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0]
            // Compute remainder using mulmod
            uint256 remainder;
            assembly {
                remainder := mulmod(a, b, denominator)
            }
            // Subtract 256 bit number from 512 bit number
            assembly {
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator
            // Compute largest power of two divisor of denominator.
            // Always >= 1.
            // EDIT for 0.8 compatibility:
            // see: https://ethereum.stackexchange.com/questions/96642/unary-operator-cannot-be-applied-to-type-uint256
            uint256 twos = denominator & (~denominator + 1);

            // Divide denominator by power of two
            assembly {
                denominator := div(denominator, twos)
            }

            // Divide [prod1 prod0] by the factors of two
            assembly {
                prod0 := div(prod0, twos)
            }
            // Shift in bits from prod1 into prod0. For this we need
            // to flip `twos` such that it is 2**256 / twos.
            // If twos is zero, then it becomes one
            assembly {
                twos := add(div(sub(0, twos), twos), 1)
            }
            prod0 |= prod1 * twos;

            // Invert denominator mod 2**256
            // Now that denominator is an odd number, it has an inverse
            // modulo 2**256 such that denominator * inv = 1 mod 2**256.
            // Compute the inverse by starting with a seed that is correct
            // correct for four bits. That is, denominator * inv = 1 mod 2**4
            uint256 inv = (3 * denominator) ^ 2;
            // Now use Newton-Raphson iteration to improve the precision.
            // Thanks to Hensel's lifting lemma, this also works in modular
            // arithmetic, doubling the correct bits in each step.
            inv *= 2 - denominator * inv; // inverse mod 2**8
            inv *= 2 - denominator * inv; // inverse mod 2**16
            inv *= 2 - denominator * inv; // inverse mod 2**32
            inv *= 2 - denominator * inv; // inverse mod 2**64
            inv *= 2 - denominator * inv; // inverse mod 2**128
            inv *= 2 - denominator * inv; // inverse mod 2**256

            // Because the division is now exact we can divide by multiplying
            // with the modular inverse of denominator. This will give us the
            // correct result modulo 2**256. Since the precoditions guarantee
            // that the outcome is less than 2**256, this is the final result.
            // We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inv;
            return result;
        }
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../interfaces/IAssetPricer.sol";
import "../interfaces/ERC20/IERC20.sol";
import "../interfaces/ISwap.sol";
import "../libraries/math/FixedPoint.sol";
import "../interfaces/IStableLPToken.sol";

/**
 * Bonding calculator for stable pool
 */
contract StablePoolPricer is IAssetPricer {
  using FixedPoint for *;

  address public immutable QUOTE;

  constructor(address _QUOTE) {
    require(_QUOTE != address(0));
    QUOTE = _QUOTE;
  }

  // calculates the liquidity value denominated in the provided token
  // uses the 0.01% inputAmount for that calculation
  // note that we never use the actual LP as input as the swap contains the LP address
  // and is also used to extract the balances
  function getTotalValue(address _lpAddress)
    public
    view
    returns (uint256 _value)
  {
    ISwap swap = IStableLPToken(_lpAddress).swap();
    IERC20[] memory tokens = swap.getPooledTokens();
    uint256[] memory reserves = swap.getTokenBalances();
    for (uint8 i = 0; i < reserves.length; i++) {
      address tokenAddr = address(tokens[i]);
      if (tokenAddr != QUOTE) {
        _value +=
          swap.calculateSwapGivenIn(tokenAddr, QUOTE, reserves[i] / 10000) *
          10000;
      } else {
        _value += reserves[i];
      }
    }
  }

  function valuation(address _lpAddress, uint256 amount_)
    external
    view
    override
    returns (uint256 _value)
  {
    uint256 totalValue = getTotalValue(_lpAddress);
    uint256 totalSupply = IStableLPToken(_lpAddress).totalSupply();

    _value =
      (totalValue *
        FixedPoint.fraction(amount_, totalSupply).decode112with18()) /
      1e18;
  }

  function markdown(address _lpAddress) external view returns (uint256) {
    return getTotalValue(_lpAddress);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../interfaces/IAssetPricer.sol";
import "../interfaces/ERC20/IERC20.sol";
import "../interfaces/IWeightedPair.sol";
import "../libraries/math/FixedPoint.sol";
import "../libraries/math/SqrtMath.sol";

/**
 * Bonding calculator for weighted pairs
 */
contract WeightedPairPricer is IAssetPricer {
  using FixedPoint for *;

  // address that is used for the quote of the provided pool
  address public immutable QUOTE;

  constructor(address _QUOTE) {
    require(_QUOTE != address(0));
    QUOTE = _QUOTE;
  }

  /**
   * note for general pairs the price does not necessarily satisfy the conditon
   * that the lp value consists 50% of the one and the other token since the mid
   * price is the quotient of the reserves. That is not necessarily the case for
   * general pairs, therefore, we have to calculate the price separately and apply it
   * to the reserve amount for conversion
   * - calculates the total liquidity value denominated in the provided token
   * - uses the 1bps ouytput reserves for that calculation to avoid slippage to
   *   have a too large impact
   * - the sencond token input argument is ignored when using pools with only 2 tokens
   * @param _pair general pair that has the RequiemSwap interface implemented
   *  - the value is calculated as the geometric average of input and output
   *  - is consistent with the uniswapV2-type case
   */
  function getTotalValue(address _pair) public view returns (uint256 _value) {
    IWeightedPair.ReserveData memory pairData = IWeightedPair(_pair)
      .getReserves();
    (uint32 weight0, uint32 weight1, , ) = IWeightedPair(_pair).getParameters();

    // In case of both weights being 50, it is equivalent to
    // the UniswapV2 variant. If the weights are different, we define the valuation by
    // scaling the reserve up or down dependent on the weights and the use the product as
    // adjusted constant product. We will use the conservative estimation of the price - we upscale
    // such that the reflected equivalent pool is a uniswapV2 with the higher liquidity that pruduces
    // the same price of the Requiem token as the weighted pool.
    if (QUOTE == IWeightedPair(_pair).token0()) {
      _value =
        pairData.reserve0 +
        (pairData.vReserve0 * weight1 * pairData.reserve1) /
        (weight0 * pairData.vReserve1);
    } else {
      _value =
        pairData.reserve1 +
        (pairData.vReserve1 * weight0 * pairData.reserve0) /
        (weight1 * pairData.vReserve0);
    }
    // standardize to 18 decimals
    _value *= 10**(18 - IERC20(QUOTE).decimals());
  }

  /**
   * - calculates the value in QUOTE that backs reqt 1:1 of the input LP amount provided
   * @param _pair general pair that has the RequiemSwap interface implemented
   * @param amount_ the amount of LP to price for the backing
   *  - is consistent with the uniswapV2-type case
   */
  function valuation(address _pair, uint256 amount_)
    external
    view
    override
    returns (uint256 _value)
  {
    uint256 totalValue = getTotalValue(_pair);
    uint256 totalSupply = IWeightedPair(_pair).totalSupply();

    _value = (totalValue * amount_) / totalSupply;
  }

  // markdown function for bond valuation - no discounting fo regular pairs
  function markdown(address _pair) external view returns (uint256) {
    return getTotalValue(_pair);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

// solhint-disable func-name-mixedcase

interface IWeightedPair {
  struct ReserveData {
    uint256 reserve0;
    uint256 reserve1;
    uint256 vReserve0;
    uint256 vReserve1;
  }

  function totalSupply() external view returns (uint256);

  function token0() external view returns (address);

  function token1() external view returns (address);

  function getReserves()
    external
    view
    returns (ReserveData calldata reserveData);

  function getParameters()
    external
    view
    returns (
      uint32 _tokenWeight0,
      uint32 _tokenWeight1,
      uint32 _swapFee,
      uint32 _amp
    );
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

library SqrtMath {
  function sqrrt(uint256 a) internal pure returns (uint256 c) {
    if (a > 3) {
      c = a;
      uint256 b = a / 2 + 1;
      while (b < c) {
        c = b;
        b = ((a / b) + b) / 2;
      }
    } else if (a != 0) {
      c = 1;
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../interfaces/IAssetPricer.sol";
import "../interfaces/ERC20/IERC20.sol";
import "../interfaces/IWeightedPair.sol";
import "../interfaces/ISwap.sol";
import "../libraries/math/FixedPoint.sol";
import "../libraries/math/SqrtMath.sol";
import "../libraries/math/FullMath.sol";

/**
 * Bonding calculator for weighted pairs
 */
contract RequiemPricer is IAssetPricer {
  using FixedPoint for *;

  address public immutable REQ;

  constructor(address _REQ) {
    require(_REQ != address(0));
    REQ = _REQ;
  }

  /**
   * note for general pairs the price does not necessarily satisfy the conditon
   * that the lp value consists 50% of the one and the other token since the mid
   * price is the quotient of the reserves. That is not necessarily the case for
   * general pairs, therefore, we have to calculate the price separately and apply it
   * to the reserve amount for conversion
   * - calculates the total liquidity value denominated in the provided token
   * - uses the 1bps ouytput reserves for that calculation to avoid slippage to
   *   have a too large impact
   * - the sencond token input argument is ignored when using pools with only 2 tokens
   * @param _pair pair that includes requiem token
   *  - the value of the requiem reserve is assumed at 1 unit of quote
   *  - is consistent with the uniswapV2-type case
   */
  function getTotalValue(address _pair) public view returns (uint256 _value) {
    IWeightedPair.ReserveData memory pairData = IWeightedPair(_pair)
      .getReserves();

    uint256 quoteMultiplier = 10 **
      (18 - IERC20(IWeightedPair(_pair).token1()).decimals());

    if (REQ == IWeightedPair(_pair).token1()) {
      _value = pairData.reserve0 * quoteMultiplier + pairData.reserve1;
    } else {
      _value = pairData.reserve1 * quoteMultiplier + pairData.reserve0;
    }
  }

  /**
   * - calculates the value in reqt of the input LP amount provided
   * @param _pair general pair that has the RequiemSwap interface implemented
   * @param amount_ the amount of LP to price in REQ
   *  - is consistent with the uniswapV2-type case
   */
  function valuation(address _pair, uint256 amount_)
    external
    view
    override
    returns (uint256 _value)
  {
    uint256 totalValue = getTotalValue(_pair);
    uint256 totalSupply = IWeightedPair(_pair).totalSupply();

    _value = (totalValue * amount_) / totalSupply;
  }

  // markdown function for bond valuation
  function markdown(address _pair) external view returns (uint256) {
    IWeightedPair.ReserveData memory pairData = IWeightedPair(_pair)
      .getReserves();

    uint256 reservesOther = REQ ==
      IWeightedPair(_pair).token0()
      ? pairData.reserve1
      : pairData.reserve0;

    // adjusted markdown scaling up the reserve as the trading mechanism allows
    // for lower valuation for reqt reserve
    return
      (2 * reservesOther * (10**IERC20(REQ).decimals())) / getTotalValue(_pair);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "../interfaces/IWeightedPair.sol";
import "./ERC20.sol";

// solhint-disable func-name-mixedcase

contract TestPair is ERC20, IWeightedPair {
  ReserveData public reserveData;
  address public token0;
  address public token1;
  uint32 public weight0;
  uint32 public weight1;

  constructor(
    address _token0,
    address _token1,
    uint32 _weight0,
    uint32 _weight1
  ) ERC20("Test Pair", "TP", 18) {
    token0 = _token0;
    token1 = _token1;
    weight0 = _weight0;
    weight1 = _weight1;

    reserveData = ReserveData(0, 0, 0, 0);
  }

  function setReserves(
    uint256 _reserves0,
    uint256 _reserves1,
    uint256 _vReserves0,
    uint256 _vReserves1
  ) public {
    ReserveData memory _reserveData = ReserveData(
      _reserves0,
      _reserves1,
      _vReserves0,
      _vReserves1
    );
    reserveData = _reserveData;
  }

  function getReserves() external view returns (ReserveData memory) {
    ReserveData memory _reserveData = IWeightedPair.ReserveData(
      reserveData.reserve0,
      reserveData.reserve1,
      reserveData.vReserve0,
      reserveData.vReserve1
    );
    return _reserveData;
  }

  function getParameters()
    external
    view
    returns (
      uint32 _tokenWeight0,
      uint32 _tokenWeight1,
      uint32 _swapFee,
      uint32 _amp
    )
  {
    _tokenWeight0 = weight0;
    _tokenWeight1 = weight1;
    _swapFee = 0;
    _amp = 0;
  }

  function mint(address to, uint256 value) public virtual {
    _mint(to, value);
  }

  function totalSupply()
    public
    view
    override(ERC20, IWeightedPair)
    returns (uint256)
  {
    return _totalSupply;
  }

  function decimals() public pure override returns (uint8) {
    return 18;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./Context.sol";
import "../interfaces/ERC20/IERC20.sol";

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
contract ERC20 is IERC20, Context {
    mapping(address => uint256) internal _balances;

    mapping(address => mapping(address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
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
        return _decimals;
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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./ERC20.sol";
import "../interfaces/IREQ.sol";
import "../libraries/Ownable.sol";

contract MockREQ is ERC20, IREQ, Ownable {
  /* ========== MUTATIVE FUNCTIONS ========== */

  uint256 public MAX_TOTAL_SUPPLY;

  mapping(address => uint256) public minters; // minter's address => minter's max cap
  mapping(address => uint256) public minters_minted;

  /* ========== EVENTS ========== */
  event MinterUpdate(address indexed account, uint256 cap);
  event MaxTotalSupplyUpdated(uint256 _newCap);

  constructor(uint256 _max_supp) Ownable() ERC20("Requiem", "REQ", 18) {
    MAX_TOTAL_SUPPLY = _max_supp;
  }

  /* ========== Modifiers =============== */

  modifier onlyMinter() {
    require(minters[msg.sender] > 0, "Only minter can interact");
    _;
  }

  function _beforeTokenTransfer(
    address _from,
    address _to,
    uint256 _amount
  ) internal override {
    super._beforeTokenTransfer(_from, _to, _amount);
    if (_from == address(0)) {
      // When minting tokens
      require(
        totalSupply() + _amount <= MAX_TOTAL_SUPPLY,
        "Max total supply exceeded"
      );
    }
    if (_to == address(0)) {
      // When burning tokens
      require(
        MAX_TOTAL_SUPPLY >= _amount,
        "Burn amount exceeds max total supply"
      );
      MAX_TOTAL_SUPPLY -= _amount;
    }
  }

  function mint(address to, uint256 value) external override onlyMinter {
    _mint(to, value);
  }

  function burn(uint256 value) external override {
    _burn(_msgSender(), value);
  }

  function burnFrom(address account, uint256 amount) external override {
    uint256 currentAllowance = allowance(account, _msgSender());
    require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
    unchecked {
      _approve(account, _msgSender(), currentAllowance - amount);
    }
    _burn(account, amount);
  }

  /* ========== OWNER FUNCTIONS ========== */

  function setMinter(address _account, uint256 _minterCap) external onlyOwner {
    require(_account != address(0), "invalid address");
    require(
      minters_minted[_account] <= _minterCap,
      "Minter already minted a larger amount than new cap"
    );
    minters[_account] = _minterCap;
    emit MinterUpdate(_account, _minterCap);
  }

  function resetMaxTotalSupply(uint256 _newCap) external onlyOwner {
    require(_newCap >= totalSupply(), "_newCap is below current total supply");
    MAX_TOTAL_SUPPLY = _newCap;
    emit MaxTotalSupplyUpdated(_newCap);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.14;

import "./ERC20/IERC20.sol";

interface IREQ is IERC20 {
    function mint(address account_, uint256 amount_) external;

    function burn(uint256 amount) external;

    function burnFrom(address account_, uint256 amount_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "../interfaces/IOwnable.sol";

contract Ownable is IOwnable {
    
  address internal _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor () {
    _owner = msg.sender;
    emit OwnershipTransferred( address(0), _owner );
  }

  function owner() public view override returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require( _owner == msg.sender, "Ownable: caller is not the owner" );
    _;
  }

  function renounceOwnership() public virtual override onlyOwner() {
    emit OwnershipTransferred( _owner, address(0) );
    _owner = address(0);
  }

  function transferOwnership( address newOwner_ ) public virtual override onlyOwner() {
    require( newOwner_ != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred( _owner, newOwner_ );
    _owner = newOwner_;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IOwnable {
  function owner() external view returns (address);

  function renounceOwnership() external;
  
  function transferOwnership( address newOwner_ ) external;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import "./ERC20.sol";

contract MockERC20 is ERC20 {
  constructor(
    string memory _name,
    string memory _symbol,
    uint8 _decimals
  ) ERC20(_name, _symbol, _decimals) {}

  function mint(address to, uint256 value) public virtual {
    _mint(to, value);
  }

  function burn(address from, uint256 value) public virtual {
    _burn(from, value);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

//import {IgREQ} from "../interfaces/IgREQ.sol";
import "./MockERC20.sol";

// TODO fulfills IgREQ but is not inheriting because of dependency issues
contract MockGReq is MockERC20 {
    /* ========== CONSTRUCTOR ========== */

    uint256 public immutable index;

    constructor(uint256 _initIndex) MockERC20("Governance REQ", "gREQ", 18) {
        index = _initIndex;
    }

    function migrate(address _staking, address _sReq) external {}

    function balanceFrom(uint256 _amount) public view returns (uint256) {
        return (_amount * index) / 10**decimals();
    }

    function balanceTo(uint256 _amount) public view returns (uint256) {
        return (_amount * (10**decimals())) / index;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "../interfaces/IAssetPricer.sol";
import "../interfaces/ERC20/IERC20.sol";

/**
 * Pricer returning
 */
contract TrivialPricer is IAssetPricer {
  constructor() {}

  /**
   * note normalizes asset value to 18 decimals
   * @param _asset pair that includes requiem token
   *  - the value of the requiem reserve is assumed at 1 unit of quote
   *  - is consistent with the uniswapV2-type case
   */
  function getTotalValue(address _asset) public view returns (uint256 _value) {
    _value =
      IERC20(_asset).totalSupply() *
      10**(18 - IERC20(_asset).decimals());
  }

  /**
   * - calculates the value in reqt of the input LP amount provided
   * @param _asset general pair that has the RequiemSwap interface implemented
   * @param _amount the amount of LP to price in REQ
   *  - is consistent with the uniswapV2-type case
   */
  function valuation(address _asset, uint256 _amount)
    external
    view
    override
    returns (uint256 _value)
  {
    _value = _amount * 10**(18 - IERC20(_asset).decimals());
  }

  // markdown function for bond valuation
  function markdown(address _asset) external view returns (uint256) {
    return getTotalValue(_asset);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.5;

import "./ERC20/IERC20.sol";

interface IsREQ is IERC20 {
    function rebase(uint256 reqProfit_, uint256 epoch_) external returns (uint256);

    function circulatingSupply() external view returns (uint256);

    function gonsForBalance(uint256 amount) external view returns (uint256);

    function balanceForGons(uint256 gons) external view returns (uint256);

    function index() external view returns (uint256);

    function toG(uint256 amount) external view returns (uint256);

    function fromG(uint256 amount) external view returns (uint256);

    function changeDebt(
        uint256 amount,
        address debtor,
        bool add
    ) external;

    function debtBalances(address _address) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IERC20.sol";

interface IRewardToken is IERC20 {
    function mint(address _recipient, uint256 _amount) external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.14;

import "./ERC20/IERC20.sol";

interface IBondDepository {
  // Info about each type of market
  struct Market {
    uint256 capacity; // capacity remaining
    IERC20 quoteToken; // token to accept as payment
    bool capacityInQuote; // capacity limit is in payment token (true) or in REQ (false, default)
    uint256 totalDebt; // total debt from market
    uint256 maxPayout; // max tokens in/out (determined by capacityInQuote false/true, respectively)
    uint256 sold; // base tokens out
    uint256 purchased; // quote tokens in
  }

  // Info for creating new markets
  struct Terms {
    bool fixedTerm; // fixed term or fixed expiration
    uint256 controlVariable; // scaling variable for price
    uint48 vesting; // length of time from deposit to maturity if fixed-term
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
    uint8 quoteDecimals; // decimals of quote token
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
    IERC20 _quoteToken, // token used to deposit
    uint256[3] memory _market, // [capacity, initial price]
    bool[2] memory _booleans, // [capacity in quote, fixed term]
    uint256[2] memory _terms, // [vesting, conclusion]
    uint32[2] memory _intervals // [deposit interval, tune interval]
  ) external returns (uint256 id_);

  function close(uint256 _id) external;

  function isLive(uint256 _bid) external view returns (bool);

  function liveMarkets() external view returns (uint256[] memory);

  function liveMarketsFor(address _quoteToken)
    external
    view
    returns (uint256[] memory);

  function payoutFor(uint256 _amount, uint256 _bid)
    external
    view
    returns (uint256);

  function marketPrice(uint256 _bid) external view returns (uint256);

  function currentDebt(uint256 _bid) external view returns (uint256);

  function debtRatio(uint256 _bid) external view returns (uint256);

  function debtDecay(uint256 _bid) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.14;

import "./libraries/types/UserTermsKeeper.sol";
import "./libraries/SafeERC20.sol";
import "./interfaces/ERC20/IERC20Metadata.sol";
import "./interfaces/IBondDepository.sol";

// solhint-disable  max-line-length

/// @title Requiem Bond Depository
/// @author Requiem: Achthar; Olympus DAO: Zeus, Indigo

contract BondDepository is IBondDepository, UserTermsKeeper {
    /* ======== DEPENDENCIES ======== */

    using SafeERC20 for IERC20;

    /* ======== EVENTS ======== */

    event CreateMarket(uint256 indexed id, address indexed baseToken, address indexed quoteToken, uint256 initialPrice);
    event CloseMarket(uint256 indexed id);
    event Bond(uint256 indexed id, uint256 amount, uint256 price);
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

    constructor(
        IERC20 _req,
        address _treasury
    ) UserTermsKeeper(_req, _treasury) {}

    /* ======== DEPOSIT ======== */

    /**
     * @notice             deposit quote tokens in exchange for a bond from a specified market
     * @param _id          the ID of the market
     * @param _amount      the amount of quote token to spend
     * @param _maxPrice    the maximum price at which to buy
     * @param _user        the recipient of the payout
     * @param _referral    the front end operator address
     * @return payout_     the amount of gREQ due
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

        // Users input a maximum price, which protects them from price changes after
        // entering the mempool. max price is a slippage mitigation measure
        uint256 price = _marketPrice(_id);
        require(price <= _maxPrice, "Depository: more than max price");

        /**
         * payout for the deposit = amount / price
         *
         * where
         * payout = REQ out
         * amount = quote tokens in
         * price = quote tokens : req (i.e. 42069 DAI : REQ)
         *
         * REQ decimals is supposed to match price decimals
         */
        payout_ = ((_amount * 10**(2 * req.decimals())) / price) / (10**metadata[_id].quoteDecimals);

        // markets have a max payout amount, capping size because deposits
        // do not experience slippage. max payout is recalculated upon tuning
        require(payout_ <= market.maxPayout, "Depository: max size exceeded");

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
        expiry_ = term.fixedTerm ? term.vesting + currentTime : term.vesting;

        // markets keep track of how many quote tokens have been
        // purchased, and how much REQ has been sold
        market.purchased += _amount;
        market.sold += payout_;

        // incrementing total debt raises the price of the next bond
        market.totalDebt += payout_;

        emit Bond(_id, _amount, price);

        /**
         * user data is stored as Termss. these are isolated array entries
         * storing the amount due, the time created, the time when payout
         * is redeemable, the time when payout was redeemed, and the ID
         * of the market deposited into
         */
        index_ = addTerms(_user, payout_, uint48(expiry_), uint48(_id), _referral);

        // transfer payment to treasury
        market.quoteToken.safeTransferFrom(msg.sender, address(treasury), _amount);

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
            // req decimals + price decimals
            uint256 capacity = market.capacityInQuote
                ? ((market.capacity * (10**(2 * req.decimals()))) / price) / (10**meta.quoteDecimals)
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

    /* ======== CREATE ======== */

    /**
     * @notice             creates a new market type
     * @dev                current price should be in 9 decimals.
     * @param _quoteToken  token used to deposit
     * @param _market      [capacity (in REQ or quote), initial price / REQ (18 decimals), debt buffer (3 decimals)]
     * @param _booleans    [capacity in quote, fixed term]
     * @param _terms       [vesting length (if fixed term) or vested timestamp, conclusion timestamp]
     * @param _intervals   [deposit interval (seconds), tune interval (seconds)]
     * @return id_         ID of new bond market
     */
    function create(
        IERC20 _quoteToken,
        uint256[3] memory _market,
        bool[2] memory _booleans,
        uint256[2] memory _terms,
        uint32[2] memory _intervals
    ) external override onlyPolicy returns (uint256 id_) {
        // the length of the program, in seconds
        uint256 secondsToConclusion = _terms[1] - block.timestamp;

        // the decimal count of the quote token
        uint256 decimals = IERC20Metadata(address(_quoteToken)).decimals();

        /*
         * initial target debt is equal to capacity (this is the amount of debt
         * that will decay over in the length of the program if price remains the same).
         * it is converted into base token terms if passed in in quote token terms.
         *
         * 1e18 = req decimals (x) + initial price decimals (18)
         */
        uint256 targetDebt = uint256(_booleans[0] ? ((_market[0] * (10**(2 * req.decimals()))) / _market[1]) / 10**decimals : _market[0]);

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
                quoteToken: _quoteToken,
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
                vesting: uint48(_terms[0]),
                conclusion: uint48(_terms[1]),
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
                quoteDecimals: uint8(decimals)
            })
        );

        marketsForQuote[address(_quoteToken)].push(id_);

        emit CreateMarket(id_, address(req), address(_quoteToken), _market[1]);
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

    /* ======== EXTERNAL VIEW ======== */

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
        return (currentControlVariable(_id) * debtRatio(_id)) / (10**metadata[_id].quoteDecimals);
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
        Metadata memory meta = metadata[_id];
        return (_amount * 10**(2 * req.decimals())) / marketPrice(_id) / 10**meta.quoteDecimals;
    }

    /**
     * @notice             calculate current ratio of debt to supply
     * @dev                uses current debt, which accounts for debt decay since last deposit (vs _debtRatio())
     * @param _id          ID of market
     * @return             debt ratio for market in quote decimals
     */
    function debtRatio(uint256 _id) public view override returns (uint256) {
        return (currentDebt(_id) * (10**metadata[_id].quoteDecimals)) / treasury.baseSupply();
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

    /**
     * @notice                  calculate current market price of quote token in base token
     * @dev                     see marketPrice() for explanation of price computation
     * @dev                     uses info from storage because data has been updated before call (vs marketPrice())
     * @param _id               market ID
     * @return                  price for market in REQ decimals
     */
    function _marketPrice(uint256 _id) internal view returns (uint256) {
        return (terms[_id].controlVariable * _debtRatio(_id)) / (10**metadata[_id].quoteDecimals);
    }

    /**
     * @notice                  calculate debt factoring in decay
     * @dev                     uses info from storage because data has been updated before call (vs debtRatio())
     * @param _id               market ID
     * @return                  current debt for market in quote decimals
     */
    function _debtRatio(uint256 _id) internal view returns (uint256) {
        return (markets[_id].totalDebt * (10**metadata[_id].quoteDecimals)) / treasury.baseSupply();
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./FrontEndRewarder.sol";
import "../../interfaces/ITreasury.sol";
import "../../interfaces/IUserTermsKeeper.sol";

// solhint-disable max-line-length

abstract contract UserTermsKeeper is IUserTermsKeeper, FrontEndRewarder {
    mapping(address => UserTerms[]) public userTerms; // user deposit data
    mapping(address => mapping(uint256 => address)) private noteTransfers; // change note ownership


    ITreasury internal treasury;

    constructor(
        IERC20 _req,
        address _treasury
    ) FrontEndRewarder(IAuthority(_treasury), _req) {
        treasury = ITreasury(_treasury);
    }

    // if treasury address changes on authority, update it
    function updateTreasury() external {
        require(
            msg.sender == authority.governor() ||
                msg.sender == authority.guardian() ||
                msg.sender == authority.policy(),
            "Only authorized"
        );
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
        uint256 _payout,
        uint48 _expiry,
        uint48 _marketID,
        address _referral
    ) internal returns (uint256 index_) {
        // the index of the note is the next in the user's array
        index_ = userTerms[_user].length;

        // the new note is pushed to the user's array
        userTerms[_user].push(
            UserTerms({
                payout: _payout,
                created: uint48(block.timestamp),
                matured: _expiry,
                redeemed: 0,
                marketID: _marketID
            })
        );

        // front end operators can earn rewards by referring users
        uint256 rewards = _giveRewards(_payout, _referral);

        // mint and send to user
        treasury.mint(_user, _payout + rewards);
    }

    /* ========== REDEEM ========== */

    /**
     * @notice             redeem userTerms for user
     * @param _user        the user to redeem for
     * @param _indexes     the note indexes to redeem
     * @return payout_     sum of payout sent, in REQ
     */
    function redeem(
        address _user,
        uint256[] memory _indexes
    ) public override returns (uint256 payout_) {
        uint48 time = uint48(block.timestamp);

        for (uint256 i = 0; i < _indexes.length; i++) {
            (uint256 pay, bool matured) = pendingFor(_user, _indexes[i]);

            if (matured) {
                userTerms[_user][_indexes[i]].redeemed = time; // mark as redeemed
                payout_ += pay;
            }
        }

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

    /**
     * @notice             calculate amount available for claim for a single note
     * @param _user        the user that the note belongs to
     * @param _index       the index of the note in the user's array
     * @return payout_     the payout due, in gREQ
     * @return matured_    if the payout can be redeemed
     */
    function pendingFor(address _user, uint256 _index) public view override returns (uint256 payout_, bool matured_) {
        UserTerms memory note = userTerms[_user][_index];

        payout_ = note.payout;
        matured_ = note.redeemed == 0 && note.matured <= block.timestamp && note.payout != 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../interfaces/ERC20/IERC20.sol";
import "./Address.sol";

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./IERC20.sol";

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.14;

interface IUserTermsKeeper {
    // Info for market note
    struct UserTerms {
        uint256 payout; // REQ remaining to be paid
        uint48 created; // time market was created
        uint48 matured; // timestamp when market is matured
        uint48 redeemed; // time market was redeemed
        uint48 marketID; // market ID of deposit. uint48 to avoid adding a slot.
    }

    function redeem(
        address _user,
        uint256[] memory _indexes
    ) external returns (uint256);

    function redeemAll(address _user) external returns (uint256);
 
    function pushTerms(address to, uint256 index) external;

    function pullTerms(address from, uint256 index) external returns (uint256 newIndex_);

    function indexesFor(address _user) external view returns (uint256[] memory);

    function pendingFor(address _user, uint256 _index) external view returns (uint256 payout_, bool matured_);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.8.14;

import "./IAuthority.sol";

interface ITreasuryAuth is IAuthority {
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