// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IDO is Ownable {
    IERC20 public usdt;
    IERC20 public btf;
    uint256 public rate = 25;
    uint256 public LOCKUP_PERIOD = 365 days; 
    uint256 public DEPOSITOR_REWARD_RATE = 25; // Represents 2.5%
    uint256 public REFFERAL_REWARD_RATE = 50; //  Represents 5%

    uint256 public usdtDecimals;
    uint256 public btfDecimals;
    mapping(address => bool) public hasDeposit;

    struct Deposit {
        uint256 amount;
        uint256 depositTime;
        bool isClaimed;
    }

    mapping(address => Deposit[]) public deposits;
    mapping(address => address) public referral;
    mapping(address => uint256) public commission;
    

    event DepositEvent(
        address indexed user,
        uint256 amount,
        uint256 depositTime,
        address referral
    );
    event ClaimEvent(address indexed user, uint256 totalClaimable);
    event ReferralClaimEvent(address indexed user, uint256 totalClaimable);

    constructor(address _usdt, address _btf) {
        usdt = IERC20(_usdt);
        btf = IERC20(_btf);
        usdtDecimals = 6;
        btfDecimals = 18;
    }

    function setUSDT(address _usdt) external onlyOwner {
        usdt = IERC20(_usdt);
    }

    function setBTF(address _btf) external onlyOwner {
        btf = IERC20(_btf);
    }
    
    function setRate(uint256 _rate) external onlyOwner {
        rate = _rate;
    }

    function setLockupPeriod(uint256 _lockupPeriod) external onlyOwner {
        LOCKUP_PERIOD = _lockupPeriod;
    }

    function setDepositorRewardRate(uint256 _rewardRate) external onlyOwner {
        DEPOSITOR_REWARD_RATE = _rewardRate;
    }

    function setReferralRewardRate(uint256 _rewardRate) external onlyOwner {
        REFFERAL_REWARD_RATE = _rewardRate;
    }

   
    function deposit(uint256 _amount, address _referral) external {
        require(
            _referral != msg.sender,
            "Referrer cannot be the same as the depositor"
        );
        usdt.transferFrom(msg.sender, address(this), _amount);
        deposits[msg.sender].push(Deposit(_amount, block.timestamp, false));
        if (
            _referral != address(0) &&
            _referral != msg.sender &&
            !hasDeposit[msg.sender]
        ) {
            referral[msg.sender] = _referral;
            uint256 reward = (_amount * REFFERAL_REWARD_RATE) / 1000; // Adjusted to USDT decimals
            commission[_referral] += reward;
        }
        hasDeposit[msg.sender] = true;
        emit DepositEvent(msg.sender, _amount, block.timestamp, _referral);
    }

    function withdrawUSDT(uint256 _amount) external onlyOwner {
        uint256 balance = usdt.balanceOf(address(this));
        require(balance >= _amount, "Not enough USDT in the contract");
        usdt.transfer(owner(), _amount);
    }

    function withdrawWrongToken(address _token, uint256 _amount, address targetAddress) external onlyOwner { 
        IERC20 token = IERC20(_token);
        uint256 balance = token.balanceOf(address(this));
        require(balance >= _amount, "Not enough tokens in the contract");
        token.transfer(targetAddress, _amount);
    }

    function claim(uint256 i) external {
        uint256 totalClaimable = 0;
        Deposit storage depo = deposits[msg.sender][i];
        require(
            !depo.isClaimed &&
                block.timestamp >= depo.depositTime + LOCKUP_PERIOD
        );
        uint256 claimable = ((depo.amount *  (10 ** (btfDecimals - usdtDecimals))) * rate) / 10; // Adjusted to BTF decimals
        uint256 reward = (claimable * DEPOSITOR_REWARD_RATE) / 1000; // Adjusted to BTF decimals
        totalClaimable += claimable + reward;
        depo.isClaimed = true;
        require(totalClaimable > 0, "Nothing to claim");
        btf.transfer(msg.sender, totalClaimable);
        emit ClaimEvent(msg.sender, totalClaimable);
    }

    function claimReferral() external {
        uint256 totalClaimable = commission[msg.sender];
        require(totalClaimable > 0, "Nothing to claim");
        usdt.transfer(msg.sender, totalClaimable);
        commission[msg.sender] = 0;
        emit ReferralClaimEvent(msg.sender, totalClaimable);
    }

    function getDeposit(
        address depositor,
        uint index
    ) external view returns (Deposit memory) {
        return deposits[depositor][index];
    }

    function getDepositSize(address depositor) external view returns (uint256) {
        return deposits[depositor].length;
    }
}