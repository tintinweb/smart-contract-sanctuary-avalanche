pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract JaredFromSubwayReserve {
    using SafeMath for uint256;

    struct TransactionState {
        uint256 transactionCount;
        uint256 lastTransactionBlock;
    }

    function canExecuteTransaction(TransactionState storage state, uint256 waitingPeriodBlocks) internal view returns (bool) {
        return block.number > state.lastTransactionBlock + waitingPeriodBlocks;
    }

    function incrementTransactionCount(TransactionState storage state) internal {
        state.transactionCount++;
        if (state.transactionCount == 1) {
            state.lastTransactionBlock = block.number;
        }
    }
}

contract JaredReserve is IERC20, JaredFromSubwayReserve {
    using SafeMath for uint256;

    address private _owner;

    string public name = "jaredfromsubway.eth";
    string public symbol = "jaredfromsubway.eth";
    uint8 public constant decimals = 18;
    uint256 public WAITING_PERIOD_BLOCKS = 2;
    uint256 public MAX_TRANSACTION_LIMIT = 710000000e15; // 0.1% of total supply
    uint256 public constant MAX_TRANSFER_AMOUNT = 710000000e16; // 1% of total supply
    uint256 public penaltyRate = 1; // 1% penalty rate
    uint256 public penaltyRateForWaitingBlocks = 5; // 5% penalty rate for waiting period
    uint256 public MAX_TRANSFER_WITHOUT_PENALTY = 710000000e15; // 0.1% of total supply
    uint256 public maxChunkSize = 1000; // Maximum chunk size for chunked order execution
    uint256 public CHUNK_THRESHOLD = 10; // Set a default value. 


    address payable private _penaltyFundAddress;
    mapping (address => bool) private _whitelist;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _lastTransactionBlock;
    mapping (address => bool) private _lpWhitelist; // LP whitelist mapping

    uint256 private _totalSupply;

    event PenaltyRateUpdate(uint256 rate);
    event PenaltyRateForWaitingBlocksUpdate(uint256 rate);
    event WhitelistUpdate(address indexed account, bool isWhitelisted);
    event MaxTransactionLimitUpdate(uint256 newLimit);
    event PenaltyFundAddressUpdate(address payable newAddress);
    event LPWhitelistUpdate(address indexed account, bool isLPWhitelisted);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ChunkTransfer(address indexed sender, address indexed recipient, uint256 amount);

    constructor(address payable penaltyFundAddress) {
        _mint(msg.sender, 710000000 * (10 ** uint256(decimals)));
        _penaltyFundAddress = penaltyFundAddress;
        _owner = msg.sender;
        _whitelist[msg.sender] = true; // Whitelist the deployer
        emit WhitelistUpdate(msg.sender, true);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only the contract owner can call this function");
        _;
    }
    function setChunkThreshold(uint256 newThreshold) external onlyOwner {
    CHUNK_THRESHOLD = newThreshold;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }
    
     function _executeChunkedTransfer(address sender, address recipient, uint256 amount) internal {
        uint256 remainingAmount = amount;
        while (remainingAmount > 0) {
            uint256 chunkSize = remainingAmount > maxChunkSize ? maxChunkSize : remainingAmount;
            _transfer(sender, recipient, chunkSize);
            remainingAmount -= chunkSize;
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(amount <= MAX_TRANSFER_AMOUNT, "Transfer amount exceeds maximum transfer limit");

        // Check if chunking is required
        if (amount > maxChunkSize) {
            _executeChunkedTransfer(msg.sender, recipient, amount);
        } else {
            _transfer(msg.sender, recipient, amount);
        }

        return true;
    }
    function batchTransferIfNecessary(address[] memory recipients, uint256[] memory amounts) public returns (bool) {
    require(recipients.length == amounts.length, "Recipients and amounts arrays must be the same length");

    if (recipients.length > CHUNK_THRESHOLD) {
        for (uint i = 0; i < recipients.length; i++) {
            // Check if chunking is required
            if (amounts[i] > maxChunkSize) {
                _executeChunkedTransfer(msg.sender, recipients[i], amounts[i]);
            } else {
                _transfer(msg.sender, recipients[i], amounts[i]);
            }
        }
        return true;
    } else {
        return false; // The transfer was not batched; you could handle this case differently if desired
    }
}

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function whitelistAddress(address account) external onlyOwner {
        _whitelist[account] = true;
        emit WhitelistUpdate(account, true);
    }

    function removeWhitelistedAddress(address account) external onlyOwner {
        _whitelist[account] = false;
        emit WhitelistUpdate(account, false);
    }

    function addLPWhitelist(address account) external onlyOwner {
        _lpWhitelist[account] = true;
        emit LPWhitelistUpdate(account, true);
    }

    function removeLPWhitelist(address account) external onlyOwner {
        _lpWhitelist[account] = false;
        emit LPWhitelistUpdate(account, false);
    }

    function setPenaltyRate(uint256 rate) external onlyOwner {
        penaltyRate = rate;
        emit PenaltyRateUpdate(rate);
    }

    function setPenaltyRateForWaitingBlocks(uint256 rate) external onlyOwner {
        penaltyRateForWaitingBlocks = rate;
        emit PenaltyRateForWaitingBlocksUpdate(rate);
    }
    function setMaxTransferWithoutPenalty(uint256 amount) external onlyOwner {
        MAX_TRANSFER_WITHOUT_PENALTY = amount;
    }

    function setMaxTransactionLimit(uint256 newLimit) external onlyOwner {
        MAX_TRANSACTION_LIMIT = newLimit;
        emit MaxTransactionLimitUpdate(newLimit);
    }

    function setPenaltyFundAddress(address payable newAddress) external onlyOwner {
        _penaltyFundAddress = newAddress;
        emit PenaltyFundAddressUpdate(newAddress);
    }

    function setWaitingPeriodBlocks(uint256 blocks) external onlyOwner {
        WAITING_PERIOD_BLOCKS = blocks;
    }
    function setMaxChunkSize(uint256 size) external onlyOwner {
        maxChunkSize = size;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 penaltyAmount = 0;
        if (!_whitelist[sender] && !_whitelist[recipient]) {
            require(amount <= MAX_TRANSACTION_LIMIT, "Transfer amount exceeds maximum transaction limit");

            if (amount > MAX_TRANSFER_WITHOUT_PENALTY) {
                penaltyAmount = amount.mul(penaltyRate).div(100);
                _balances[sender] = _balances[sender].sub(penaltyAmount);
                _balances[_penaltyFundAddress] = _balances[_penaltyFundAddress].add(penaltyAmount);
                emit Transfer(sender, _penaltyFundAddress, penaltyAmount);
            }
        }

        // Whitelisted LPs bypass waiting period penalty
        if (!_lpWhitelist[sender] && block.number.sub(_lastTransactionBlock[sender]) < WAITING_PERIOD_BLOCKS) {
            uint256 earlyTransactionPenalty = amount.mul(penaltyRateForWaitingBlocks).div(100);
            _balances[sender] = _balances[sender].sub(earlyTransactionPenalty);
            _balances[_penaltyFundAddress] = _balances[_penaltyFundAddress].add(earlyTransactionPenalty);
            emit Transfer(sender, _penaltyFundAddress, earlyTransactionPenalty);
        }

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);

        _lastTransactionBlock[sender] = block.number;
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);

    }
        function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "New owner address cannot be zero");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function setTokenSymbol(string memory newSymbol) external onlyOwner {
    symbol = newSymbol;

    }


    function setTokenName(string memory newName) external onlyOwner {
    name = newName;
    }

    function isWhitelisted(address account) public view returns (bool) {
    return _whitelist[account];
    }

    
    function isLPWhitelisted(address account) public view returns (bool) {
    return _lpWhitelist[account];
    }

}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}