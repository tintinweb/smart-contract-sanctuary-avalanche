/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-01
*/

// File: contracts/interfaces/IAuthority.sol


pragma solidity >=0.7.5;

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



pragma solidity >=0.7.5;


abstract contract AccessControlled {
  /* ========== EVENTS ========== */

  event AuthorityUpdated(IAuthority indexed authority);

  string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

  /* ========== STATE VARIABLES ========== */

  IAuthority public authority;

  /* ========== Constructor ========== */

  constructor(IAuthority _authority) {
    authority = _authority;
    emit AuthorityUpdated(_authority);
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

// File: contracts/interfaces/IDistributor.sol


pragma solidity 0.8.11;

interface IDistributor {
    function distribute() external;

    function bounty() external view returns (uint256);

    function retrieveBounty() external returns (uint256);

    function nextRewardAt(uint256 _rate) external view returns (uint256);

    function nextRewardFor(address _recipient) external view returns (uint256);

    function setBounty(uint256 _bounty) external;

    function addRecipient(address _recipient, uint256 _rewardRate) external;

    function removeRecipient(uint256 _index) external;

    function setAdjustment(
        uint256 _index,
        bool _add,
        uint256 _rate,
        uint256 _target
    ) external;
}

// File: contracts/interfaces/ERC20/IERC20.sol


pragma solidity 0.8.11;

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
// File: contracts/interfaces/IgREQ.sol


pragma solidity >=0.7.5;


interface IgREQ is IERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;

    function index() external view returns (uint256);

    function balanceFrom(uint256 _amount) external view returns (uint256);

    function balanceTo(uint256 _amount) external view returns (uint256);

    function migrate(address _staking, address _sREQ) external;
}

// File: contracts/interfaces/IsREQ.sol


pragma solidity >=0.8.5;


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

// File: contracts/libraries/SafeERC20.sol



// Based on the ReentrancyGuard library from OpenZeppelin Contracts, altered to reduce gas costs.
// The `safeTransfer` and `safeTransferFrom` functions assume that `token` is a contract (an account with code), and
// work differently from the OpenZeppelin version if it is not.

pragma solidity ^0.8.11;


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
  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transfer.selector, to, value)
    );
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  ) internal {
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
    );
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  ) internal {
    uint256 newAllowance = token.allowance(address(this), spender) + value;
    _callOptionalReturn(
      address(token),
      abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
    );
  }

  /**
   * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
   * on the return value: the return value is optional (but if data is returned, it must not be false).
   *
   * WARNING: `token` is assumed to be a contract: calls to EOAs will *not* revert.
   */
  function _callOptionalReturn(address token, bytes memory data) private {
    // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
    // we're implementing it ourselves.
    (bool success, bytes memory returndata) = token.call(data);

    // If the low-level call didn't succeed we return whatever was returned from it.
    assembly {
      if eq(success, 0) {
        returndatacopy(0, 0, returndatasize())
        revert(0, returndatasize())
      }
    }

    // Finally we check the returndata size is either zero or true - note that this check will always pass for EOAs
    require(
      returndata.length == 0 || abi.decode(returndata, (bool)),
      "SAFE_ERC20_CALL_FAILED"
    );
  }
}

// File: contracts/Staking.sol


pragma solidity ^0.8.11;







contract Staking is AccessControlled {
    /* ========== DEPENDENCIES ========== */

    using SafeERC20 for IERC20;
    using SafeERC20 for IsREQ;
    using SafeERC20 for IgREQ;

    /* ========== EVENTS ========== */

    event DistributorSet(address distributor);
    event WarmupSet(uint256 warmup);

    /* ========== DATA STRUCTURES ========== */

    struct Epoch {
        uint256 length; // in seconds
        uint256 number; // since inception
        uint256 end; // timestamp
        uint256 distribute; // amount
    }

    struct Claim {
        uint256 deposit; // if forfeiting
        uint256 gons; // staked balance
        uint256 expiry; // end of warmup period
        bool lock; // prevents malicious delays for claim
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable REQ;
    IsREQ public immutable sREQ;
    IgREQ public immutable gREQ;

    Epoch public epoch;

    IDistributor public distributor;

    mapping(address => Claim) public warmupInfo;
    uint256 public warmupPeriod;
    uint256 private gonsInWarmup;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address _req,
        address _sREQ,
        address _gREQ,
        uint256 _epochLength,
        uint256 _firstEpochNumber,
        uint256 _firstEpochTime,
        address _authority
    ) AccessControlled(IAuthority(_authority)) {
        require(_req != address(0), "Zero address: REQ");
        REQ = IERC20(_req);
        require(_sREQ != address(0), "Zero address: sREQ");
        sREQ = IsREQ(_sREQ);
        require(_gREQ != address(0), "Zero address: gREQ");
        gREQ = IgREQ(_gREQ);

        epoch = Epoch({length: _epochLength, number: _firstEpochNumber, end: _firstEpochTime, distribute: 0});
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * @notice stake REQ to enter warmup
     * @param _to address
     * @param _amount uint
     * @param _claim bool
     * @param _rebasing bool
     * @return uint
     */
    function stake(
        address _to,
        uint256 _amount,
        bool _rebasing,
        bool _claim
    ) external returns (uint256) {
        REQ.safeTransferFrom(msg.sender, address(this), _amount);
        _amount += rebase(); // add bounty if rebase occurred
        if (_claim && warmupPeriod == 0) {
            return _send(_to, _amount, _rebasing);
        } else {
            Claim memory info = warmupInfo[_to];
            if (!info.lock) {
                require(_to == msg.sender, "External deposits for account are locked");
            }

            warmupInfo[_to] = Claim({
                deposit: info.deposit + _amount,
                gons: info.gons + sREQ.gonsForBalance(_amount),
                expiry: epoch.number + warmupPeriod,
                lock: info.lock
            });

            gonsInWarmup = gonsInWarmup + sREQ.gonsForBalance(_amount);

            return _amount;
        }
    }

    /**
     * @notice retrieve stake from warmup
     * @param _to address
     * @param _rebasing bool
     * @return uint
     */
    function claim(address _to, bool _rebasing) public returns (uint256) {
        Claim memory info = warmupInfo[_to];

        if (!info.lock) {
            require(_to == msg.sender, "External claims for account are locked");
        }

        if (epoch.number >= info.expiry && info.expiry != 0) {
            delete warmupInfo[_to];

            gonsInWarmup -= info.gons;

            return _send(_to, sREQ.balanceForGons(info.gons), _rebasing);
        }
        return 0;
    }

    /**
     * @notice forfeit stake and retrieve REQ
     * @return uint
     */
    function forfeit() external returns (uint256) {
        Claim memory info = warmupInfo[msg.sender];
        delete warmupInfo[msg.sender];

        gonsInWarmup -= info.gons;

        REQ.safeTransfer(msg.sender, info.deposit);

        return info.deposit;
    }

    /**
     * @notice prevent new deposits or claims from ext. address (protection from malicious activity)
     */
    function toggleLock() external {
        warmupInfo[msg.sender].lock = !warmupInfo[msg.sender].lock;
    }

    /**
     * @notice redeem sREQ for REQs
     * @param _to address
     * @param _amount uint
     * @param _trigger bool
     * @param _rebasing bool
     * @return amount_ uint
     */
    function unstake(
        address _to,
        uint256 _amount,
        bool _trigger,
        bool _rebasing
    ) external returns (uint256 amount_) {
        amount_ = _amount;
        uint256 bounty;
        if (_trigger) {
            bounty = rebase();
        }
        if (_rebasing) {
            sREQ.safeTransferFrom(msg.sender, address(this), _amount);
            amount_ += bounty;
        } else {
            gREQ.burn(msg.sender, _amount); // amount was given in gREQ terms
            amount_ = gREQ.balanceFrom(amount_) + bounty; // convert amount to REQ terms & add bounty
        }

        require(amount_ <= REQ.balanceOf(address(this)), "Insufficient REQ balance in contract");
        REQ.safeTransfer(_to, amount_);
    }

    /**
     * @notice convert _amount sREQ into gBalance_ gREQ
     * @param _to address
     * @param _amount uint
     * @return gBalance_ uint
     */
    function wrap(address _to, uint256 _amount) external returns (uint256 gBalance_) {
        sREQ.safeTransferFrom(msg.sender, address(this), _amount);
        gBalance_ = gREQ.balanceTo(_amount);
        gREQ.mint(_to, gBalance_);
    }

    /**
     * @notice convert _amount gREQ into sBalance_ sREQ
     * @param _to address
     * @param _amount uint
     * @return sBalance_ uint
     */
    function unwrap(address _to, uint256 _amount) external returns (uint256 sBalance_) {
        gREQ.burn(msg.sender, _amount);
        sBalance_ = gREQ.balanceFrom(_amount);
        sREQ.safeTransfer(_to, sBalance_);
    }

    /**
     * @notice trigger rebase if epoch over
     * @return uint256
     */
    function rebase() public returns (uint256) {
        uint256 bounty;
        if (epoch.end <= block.timestamp) {
            sREQ.rebase(epoch.distribute, epoch.number);

            epoch.end += epoch.length;
            epoch.number++;

            if (address(distributor) != address(0)) {
                distributor.distribute();
                bounty = distributor.retrieveBounty(); // Will mint req for this contract if there exists a bounty
            }
            uint256 balance = REQ.balanceOf(address(this));
            uint256 staked = sREQ.circulatingSupply();
            if (balance <= staked + bounty) {
                epoch.distribute = 0;
            } else {
                epoch.distribute = balance - staked - bounty;
            }
        }
        return bounty;
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice send staker their amount as sREQ or gREQ
     * @param _to address
     * @param _amount uint
     * @param _rebasing bool
     */
    function _send(
        address _to,
        uint256 _amount,
        bool _rebasing
    ) internal returns (uint256) {
        if (_rebasing) {
            sREQ.safeTransfer(_to, _amount); // send as sREQ (equal unit as REQ)
            return _amount;
        } else {
            gREQ.mint(_to, gREQ.balanceTo(_amount)); // send as gREQ (convert units from REQ)
            return gREQ.balanceTo(_amount);
        }
    }

    /* ========== VIEW FUNCTIONS ========== */

    /**
     * @notice returns the sREQ index, which tracks rebase growth
     * @return uint
     */
    function index() public view returns (uint256) {
        return sREQ.index();
    }

    /**
     * @notice total supply in warmup
     */
    function supplyInWarmup() public view returns (uint256) {
        return sREQ.balanceForGons(gonsInWarmup);
    }

    /**
     * @notice seconds until the next epoch begins
     */
    function secondsToNextEpoch() external view returns (uint256) {
        return epoch.end - block.timestamp;
    }

    /* ========== MANAGERIAL FUNCTIONS ========== */

    /**
     * @notice sets the contract address for LP staking
     * @param _distributor address
     */
    function setDistributor(address _distributor) external onlyGovernor {
        distributor = IDistributor(_distributor);
        emit DistributorSet(_distributor);
    }

    /**
     * @notice set warmup period for new stakers
     * @param _warmupPeriod uint
     */
    function setWarmupLength(uint256 _warmupPeriod) external onlyGovernor {
        warmupPeriod = _warmupPeriod;
        emit WarmupSet(_warmupPeriod);
    }
}