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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IDO {
    IERC20 public usdt;
    IERC20 public btf;
    uint256 public rate = 25;
    // uint256 public constant LOCKUP_PERIOD = 365 days;
    uint256 public constant LOCKUP_PERIOD = 5 * 60; // 5 minutes
    uint256 public constant DEPOSITOR_REWARD_RATE = 25; // Represents 2.5%
    uint256 public constant REFFERAL_REWARD_RATE = 50; //  Represents 5%

    uint256 public usdtDecimals;
    uint256 public btfDecimals;

    struct Deposit {
        uint256 amount;
        uint256 depositTime;
        bool isClaimed;
    }

    mapping(address => Deposit[]) public deposits;
    mapping(address => address) public referral;
    mapping(address => uint256) public commission;
    mapping(address => bool) public hasDeposit;

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