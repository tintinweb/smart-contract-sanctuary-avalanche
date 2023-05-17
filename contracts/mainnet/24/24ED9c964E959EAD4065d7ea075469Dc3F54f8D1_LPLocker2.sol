/**
 *Submitted for verification at snowtrace.io on 2023-05-16
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: lplocker.sol


pragma solidity ^0.8.0;


contract LPLocker2 {
    IERC20 public lpToken;
    address public beneficiary;
    uint256 public lockEndBlock1K;
    uint256 public lockEndBlock1M;
    uint256 public lockEndBlock5M;
    uint256 public lockEndBlock10M;

    function setLPToken(IERC20 _lpToken) external {
        lpToken = _lpToken;
    }

    function setBeneficiary(address _beneficiary) external {
        require(msg.sender == beneficiary, "Only the current beneficiary can change the beneficiary address");
        beneficiary = _beneficiary;
    }



    function deposit1K(uint256 amount) external {
        require(block.number < lockEndBlock1K, "Cannot deposit after lock end block");
        lockEndBlock1K = block.number + 1000;
        lpToken.transferFrom(msg.sender, address(this), amount);
    }

    function deposit1M(uint256 amount) external {
        require(block.number < lockEndBlock1M, "Cannot deposit after lock end block");
        lockEndBlock1M = block.number + 1000000;
        lpToken.transferFrom(msg.sender, address(this), amount);
    }

    function deposit5M(uint256 amount) external {
        require(block.number < lockEndBlock5M, "Cannot deposit after lock end block");
        lockEndBlock5M = block.number + 5000000;
        lpToken.transferFrom(msg.sender, address(this), amount);
    }

    function deposit10M(uint256 amount) external {
        require(block.number < lockEndBlock10M, "Cannot deposit after lock end block");
        lockEndBlock10M = block.number + 10000000;
        lpToken.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw1K() external {
        require(block.number >= lockEndBlock1K, "Cannot withdraw before lock end block");
        require(msg.sender == beneficiary, "Only the beneficiary can withdraw");
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.transfer(beneficiary, balance);
    }

    function withdraw1M() external {
        require(block.number >= lockEndBlock1M, "Cannot withdraw before lock end block");
        require(msg.sender == beneficiary, "Only the beneficiary can withdraw");
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.transfer(beneficiary, balance);
    }

    function withdraw5M() external {
        require(block.number >= lockEndBlock5M, "Cannot withdraw before lock end block");
        require(msg.sender == beneficiary, "Only the beneficiary can withdraw");
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.transfer(beneficiary, balance);
    }

    function withdraw10M() external {
        require(block.number >= lockEndBlock10M, "Canno    function blocksLeft1K() public view returns (uint256) {t withdraw before lock end block");
        require(msg.sender == beneficiary, "Only the beneficiary can withdraw");
        uint256 balance = lpToken.balanceOf(address(this));
        lpToken.transfer(beneficiary, balance);
    }

      function blocksLeft1K() public view returns (uint256) {
        if (block.number >= lockEndBlock1K) {
            return 0;
        } else {
            return lockEndBlock1K - block.number;
        }
    }

    function blocksLeft1M() public view returns (uint256) {
        if (block.number >= lockEndBlock1M) {
            return 0;
        } else {
            return lockEndBlock1M - block.number;
        }
    }

    function blocksLeft5M() public view returns (uint256) {
        if (block.number >= lockEndBlock5M) {
            return 0;
        } else {
            return lockEndBlock5M - block.number;
        }
    }

    function blocksLeft10M() public view returns (uint256) {
        if (block.number >= lockEndBlock10M) {
            return 0;
        } else {
            return lockEndBlock10M - block.number;
        }
    }
}