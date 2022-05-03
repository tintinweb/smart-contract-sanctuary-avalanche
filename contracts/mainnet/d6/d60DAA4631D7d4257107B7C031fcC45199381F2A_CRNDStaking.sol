// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CRNDStaking {

    IERC20 private tokenContract;
    address private Owner;

    uint256 public maxLimit;
    uint256 public stakingTime = 86400;
    bool lockedInput = false;
    uint256 lockTimestamp;

    
    mapping(address => uint256) public stakingAmount;
    mapping(address => uint256) public stakingTimestamp;

    event Blacklist(
        address indexed owner,
        address indexed blacklisted,
        bool indexed added
    );
    event Ownership(
        address indexed owner,
        address indexed newOwner,
        bool indexed added
    );
    event Staking(
        address indexed user,
        uint256 indexed amount
    );
    event Withdraw(
        address indexed user,
        uint256 indexed amountDeposited,
        uint256 indexed amountWithdrawn
    );

    constructor(IERC20 _tokenContract, address _owner) {
        tokenContract = _tokenContract;
        Owner = _owner;
    }

    modifier OnlyOwners() {
        require(
            (msg.sender == Owner),
            "You are not the owner of the token"
        );
        _;
    }

    function transferOwner(address _who) public OnlyOwners returns (bool) {
        Owner = _who;
        emit Ownership(msg.sender, _who, true);
        return true;
    }

    function lock(bool _status) public OnlyOwners {
        lockedInput = _status;
        lockTimestamp = block.timestamp;
    }

    function checkLock() public view returns (bool){
        return lockedInput;
    }

    function depositMoney(uint256 _amount) public {
        require(maxLimit + _amount <= 50000 ether, "You cannot go over the contract limit (50 000 CRND)");
        tokenContract.transferFrom(msg.sender, address(this), _amount);
        stakingAmount[msg.sender] += _amount;
        stakingTimestamp[msg.sender] = block.timestamp;
        maxLimit += _amount;
        emit Staking(msg.sender, _amount);
    }

    function calculateCycles(address _who) public view returns (uint256) {
        if (stakingAmount[_who] == 0) {
            return 0;
        } else {
            if (lockedInput == true) {
            return ((lockTimestamp - stakingTimestamp[_who]) / stakingTime);
            } else {
                return ((block.timestamp - stakingTimestamp[_who]) / stakingTime);
        }
        }
        
    }

    function checkValues(address _who) public view returns (uint256, uint256) {
        uint256 percentage;
        if (calculateCycles(_who) <= 5) {
            percentage = 40;
        } else if (calculateCycles(_who) <= 10) {
            percentage = 50;
        } else if (calculateCycles(_who) <= 20) {
            percentage = 60;
        } else if (calculateCycles(_who) <= 30) {
            percentage = 70;
        } else if (calculateCycles(_who) <= 40) {
            percentage = 85;
        } else {
            percentage = 100;
        }
        if (calculateCycles(_who) == 0) {
            return (percentage, stakingAmount[_who]);
        } else {
            return (percentage, stakingAmount[_who] + ((stakingAmount[_who] * percentage / 10000) * calculateCycles(_who)));
        }
    }

    function checkDeposit(address _who) public view returns (uint256) {
        return(stakingAmount[_who]);
    }

    function claimMoney(address _who) public returns (bool){
        require(stakingAmount[_who] != 0);
        (, uint256 rewardAmount) = checkValues(_who);
        require(rewardAmount <= tokenContract.balanceOf(address(this)), "This contract does not have enough CRND");
        tokenContract.transfer(_who, rewardAmount);
        maxLimit -= stakingAmount[_who];
        stakingAmount[_who] = 0;
        stakingTimestamp[_who] = 0;
        emit Withdraw(_who, stakingAmount[_who], rewardAmount);
        return true;
    }

    function withdrawTokens() public OnlyOwners {
        require(tokenContract.balanceOf(address(this)) > 0);
        tokenContract.transfer(Owner, tokenContract.balanceOf(address(this)));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}