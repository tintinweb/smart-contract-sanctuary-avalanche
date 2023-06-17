/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public buyFeePercentage;
    uint256 public sellFeePercentage;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event BuyFeeChanged(uint256 newBuyFeePercentage);
    event SellFeeChanged(uint256 newSellFeePercentage);

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _initialSupply,
        uint256 _buyFeePercentage,
        uint256 _sellFeePercentage
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _initialSupply * 10**uint256(_decimals);
        balanceOf[msg.sender] = totalSupply;
        buyFeePercentage = _buyFeePercentage;
        sellFeePercentage = _sellFeePercentage;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function _transfer(
        address _from,
        address _to,
        uint256 _value
    ) internal {
        require(_to != address(0), "Transfer to the zero address");
        require(balanceOf[_from] >= _value, "Insufficient balance");

        uint256 feePercentage;
        if (_from == address(this) || _to == address(this)) {
            // Buy or sell transaction
            feePercentage = _from == address(this) ? sellFeePercentage : buyFeePercentage;
            uint256 feeAmount = (_value * feePercentage) / 100;
            uint256 transferAmount = _value - feeAmount;
            balanceOf[_from] -= _value;
            balanceOf[_to] += transferAmount;
            emit Transfer(_from, _to, transferAmount);
            emit Transfer(_from, address(0), feeAmount); // Burn the fee tokens
        } else {
            // Regular transfer
            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_value <= allowance[_from][msg.sender], "Insufficient allowance");
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function mint(address _to, uint256 _amount) public {
        require(_to != address(0), "Mint to the zero address");

        totalSupply += _amount;
        balanceOf[_to] += _amount;
        emit Transfer(address(0), _to, _amount);
    }

    function setBuyFeePercentage(uint256 _newBuyFeePercentage) public {
        require(_newBuyFeePercentage <= 100, "Buy fee percentage must be <= 100");
        buyFeePercentage = _newBuyFeePercentage;
        emit BuyFeeChanged(_newBuyFeePercentage);
    }

    function setSellFeePercentage(uint256 _newSellFeePercentage) public {
        require(_newSellFeePercentage <= 100, "Sell fee percentage must be <= 100");
        sellFeePercentage = _newSellFeePercentage;
        emit SellFeeChanged(_newSellFeePercentage);
    }
}