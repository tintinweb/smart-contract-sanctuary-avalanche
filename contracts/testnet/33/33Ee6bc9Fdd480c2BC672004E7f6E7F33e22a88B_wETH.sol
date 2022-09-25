/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.15;

contract wETH {

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    string constant private tokenName = "Wrapped Ether";
    string constant private tokenSymbol = "WETH";
    uint8 constant private tokenDecimals = 3;

    uint256 private tokenTotalSupply;

    event Trasnfer(address indexed from, address indexed to, uint256 indexed value);
    event Approval(address indexed owner, address indexed spender, uint256 indexed value);
    event Deposite(address indexed depositor, uint256 indexed value);
    event Withdraw(address indexed withdrawer, uint256 indexed value);

    fallback() external payable {
        deposite();
    }

    receive() external payable {
        deposite();
    }

    function name() public pure returns(string memory) {
        return tokenName;
    }

    function symbol() public pure returns(string memory) {
        return tokenSymbol;
    }

    function decimals() public pure returns(uint8) {
        return tokenDecimals;
    }

    function totalSupply() public view returns(uint256) {
        return tokenTotalSupply;
    }

    function balanceOf(address _account) public view returns(uint256) {
        return balances[_account];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }

    function transfer(address _to, uint256 _amount) public returns(bool) {
        require(_to != address(0), "cannot send fund to address(0)");
        require(balances[msg.sender] >= _amount, "insufficient fund");

        balances[msg.sender] -= _amount;
        balances[_to] += _amount;

        emit Trasnfer(msg.sender, _to, _amount);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public returns(bool) {
        require(allowances[_from][msg.sender] >= _amount, "Invalid Allowance");
        require(balances[_from] >= _amount, "Invalid Amount");
        require(_from != address(0) && _to != address(0), "Error: Sending And Receving Fund To Address Zero!");

        balances[_from] -= _amount;
        balances[_to] += _amount;
        allowances[_from][msg.sender] -= _amount;

        emit Trasnfer( _from, _to, _amount);

        return true;
    }

    function approve(address _spender, uint256 _amount) public returns(bool) {
        require(_spender != address(0), "Address Zero!");
        require(balances[msg.sender] >= _amount, "Insufficient Amount");

        allowances[msg.sender][_spender] = _amount;

        emit Approval(msg.sender, _spender, _amount);

        return true;
    }

    function deposite() public payable {
        require(msg.value > 0, "invalid ether amount");

        balances[msg.sender] += (msg.value * 10**tokenDecimals);
        tokenTotalSupply += (msg.value * 10**tokenDecimals);
    
        emit Deposite({
            depositor: msg.sender,
            value: msg.value
        });
    }

    function withdraw(uint _amount) public { // _amount/Wei
        uint amount = (10**tokenDecimals) * _amount;
        require(amount != 0, "zero");
        require(balances[msg.sender] >= amount, "insufficient balance");

        balances[msg.sender] -= amount;
        tokenTotalSupply -= amount;

        (bool result,) = msg.sender.call{value: _amount}("");
        require(result == true, "Error");

        emit Withdraw({
            withdrawer: msg.sender,
            value: _amount
        });
    }

    function supportInterface(bytes4 _interfaceId) public pure returns(bool) { // ERC165
        return 
        _interfaceId == 0x36372b07 || // IERC20 InterfaceId (bytes4)
        _interfaceId == 0xa219a025    // IERC20Metadata InterfaceId (bytes4)
        ;
    }

}