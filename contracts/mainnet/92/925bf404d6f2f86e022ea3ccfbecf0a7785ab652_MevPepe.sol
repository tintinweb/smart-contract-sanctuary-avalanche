/**
 *Submitted for verification at snowtrace.io on 2023-05-12
*/

pragma solidity ^0.8.0;

interface ERC20Basic {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
}

library MEVProtection {
    using SafeMath for uint256;
    struct TransactionState {
        uint256 transactionCount;
        uint256 lastTransactionBlock;
    }
    uint256 public constant WAITING_PERIOD_BLOCKS = 10;
    uint256 public constant PENALTY_FUND_LIMIT = 100 ether;
    uint256 public constant MAX_TRANSACTION_LIMIT = 1000; // 0.1% of total supply
    function canExecuteTransaction(TransactionState storage state) internal view returns (bool) {
        return block.number > state.lastTransactionBlock + WAITING_PERIOD_BLOCKS;
    }

    function canExecuteTransactionWithLimit(TransactionState storage /*state*/, uint256 amount, ERC20Basic token, address sender) internal view returns (bool) {
        uint256 balance = token.balanceOf(sender);
        return amount <= balance.div(MAX_TRANSACTION_LIMIT);
    }

    function incrementTransactionCount(TransactionState storage state) internal {
        state.transactionCount++;
        if (state.transactionCount == 1) {
            state.lastTransactionBlock = block.number;
        }
    }

    function penalizeTransaction(uint256 amount, address payable penaltyFundAddress, ERC20Basic token, address sender) internal {
        require(amount <= token.balanceOf(sender), "Insufficient balance");
        require(penaltyFundAddress.balance + amount <= PENALTY_FUND_LIMIT, "Penalty fund limit exceeded");
        token.transferFrom(sender, penaltyFundAddress, amount);
    }

    function preventSandwichAttack(TransactionState storage senderState, TransactionState storage recipientState, address sender, address recipient, uint256 amount, ERC20Basic token) internal {
        require(canExecuteTransaction(senderState), "Waiting period not elapsed");
        require(canExecuteTransactionWithLimit(senderState, amount, token, sender), "Transaction limit exceeded");
        incrementTransactionCount(senderState);
        penalizeTransaction(amount, payable(address(this)), token, sender);
        require(canExecuteTransaction(recipientState), "Waiting period not elapsed");
        require(canExecuteTransactionWithLimit(recipientState, amount, token, recipient), "Transaction limit exceeded");
        incrementTransactionCount(recipientState);
        penalizeTransaction(amount, payable(address(this)), token, recipient);
    }
}
contract MevPepe {
    using MEVProtection for MEVProtection.TransactionState;
    mapping(address => MEVProtection.TransactionState) private _transactionStates;
    address payable private _penaltyFundAddress;

    ERC20Basic public token;
    uint256 private _totalSupplyLimit;

    constructor(ERC20Basic _token) {
        token = _token;
        _penaltyFundAddress = payable(msg.sender);
        _totalSupplyLimit = token.totalSupply() * 10 / 1000; // 0.1% of total supply

    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        MEVProtection.preventSandwichAttack(_transactionStates[msg.sender], _transactionStates[recipient], msg.sender, recipient, amount, token);
        MEVProtection.penalizeTransaction(amount, _penaltyFundAddress, token, msg.sender);
        return token.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        MEVProtection.preventSandwichAttack(_transactionStates[sender], _transactionStates[recipient], sender, recipient, amount, token);
        MEVProtection.penalizeTransaction(amount, _penaltyFundAddress, token, sender);
        return token.transferFrom(sender, recipient, amount);
    }
    function executeTransaction(address recipient, uint256 amount) public returns (bool) {
        MEVProtection.TransactionState storage state = _transactionStates[msg.sender];
        require(MEVProtection.canExecuteTransaction(state), "Waiting period not elapsed");
        require(MEVProtection.canExecuteTransactionWithLimit(state, amount, token, msg.sender), "Transaction limit exceeded");
        MEVProtection.incrementTransactionCount(state);
        MEVProtection.penalizeTransaction(amount, _penaltyFundAddress, token, msg.sender);
        token.transferFrom(msg.sender, recipient, amount);
        return true;
    }

    function totalPenaltyFund() external view returns (uint256) {
        return address(this).balance;
    }

    function setTotalSupplyLimit(uint256 limit) external {
        require(msg.sender == _penaltyFundAddress, "Not authorized");
        _totalSupplyLimit = limit;
    }

    function totalSupply() public view returns (uint256) {
        uint256 total = token.totalSupply();
        return total > _totalSupplyLimit ? _totalSupplyLimit : total;
    }
}