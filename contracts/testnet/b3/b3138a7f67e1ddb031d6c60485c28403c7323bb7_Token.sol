/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-31
*/

pragma solidity ^0.8.0;

contract Token {
    string public name;
    string public symbol;
    uint256 public totalSupply;
    uint256 public constant maxSupply = 1000000000 * (10**18);
    uint256 public startTime;
    uint256 public constant decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public lastMine;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mine(address indexed miner, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply * (10**decimals);
        balanceOf[msg.sender] = _totalSupply * (10**decimals);
        startTime = block.timestamp;
    }

    function transfer(address _to, uint256 _value) external {
        uint256 decimalValue = _value * (10**decimals);
        require(balanceOf[msg.sender] >= decimalValue, "Insufficient balance");

        balanceOf[msg.sender] -= decimalValue;
        balanceOf[_to] += decimalValue;

        emit Transfer(msg.sender, _to, decimalValue);
    }

    function mine() external {
        require(lastMine[msg.sender] + 1 days <= block.timestamp, "You can only mine once per day");
        require(totalSupply < maxSupply, "Max supply reached");
        require(block.timestamp <= startTime + 31536000 * 1, "Mining period has ended");

        uint256 minedAmount = 100 * (10**decimals);
        balanceOf[msg.sender] += minedAmount;
        totalSupply += minedAmount;
        lastMine[msg.sender] = block.timestamp;

        emit Mine(msg.sender, minedAmount);
        emit Transfer(address(0), msg.sender, minedAmount);
    }
}