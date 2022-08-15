/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-14
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

contract USDCToken {

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    string private tokenName;
    string private tokenSymbol;

    uint8 private tokenDecimals;
    uint256 private tokenTotalSupply;

    address internal ownerAddress;

    event Trasnfer(address indexed from, address indexed to, uint256 indexed value);
    event Approval(address indexed owner, address indexed spender, uint256 indexed value);
    event Mint(address indexed to, uint256 indexed value);
    event Burn(address indexed from, uint256 indexed value);
    event ChangeOwner(address indexed oldOwner, address indexed newOwner);

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0, "Invalid Strings!");
        tokenName = _name;
        tokenSymbol = _symbol;
        tokenDecimals = _decimals; // 18
        tokenTotalSupply = 35000000000 * 10**uint(_decimals);
        ownerAddress = msg.sender;
        mint(ownerAddress, 35000000000 * 10**uint(_decimals));
    }

    modifier onlyOwner() {
        require(msg.sender == ownerAddress, unicode"🚫 Invalid Access");
        _;
    }

    function name() public view returns(string memory) {
        return tokenName;
    }

    function symbol() public view returns(string memory) {
        return tokenSymbol;
    }

    function decimals() public view returns(uint8) {
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

    function getOwnerAddress() public view returns(address) {
        return ownerAddress;
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

    function mint(address _to, uint256 _amount) internal onlyOwner returns(bool) {
        require(_to != address(0), "Invalid Minting To Address Zero!");
        require(_amount > 0, "Invalid Minting Amount 'zero' !");

        balances[_to] += _amount;
        tokenTotalSupply += _amount;

        emit Mint(_to, _amount);

        return true;
    }

    function burn(address _from, uint256 _amount) internal onlyOwner returns(bool) {
        require(_from != address(0), "Invalid Burning From Address Zero!");
        require(balances[_from] >= _amount, "Insufficient Account Balance");

        balances[_from] -= _amount;
        tokenTotalSupply -= _amount;

        emit Burn(_from, _amount);

        return true;
    }

    function changeOwner(address _newOwner) public onlyOwner returns(bool) {
        ownerAddress = _newOwner;

        emit ChangeOwner(msg.sender, _newOwner);

        return true;
    }

    function supportInterface(bytes4 _interfaceId) public view returns(bool) { // ERC165
        return 
        _interfaceId == 0x36372b07 || // IERC20 InterfaceId (bytes4)
        _interfaceId == 0xa219a025    // IERC20Metadata InterfaceId (bytes4)
        ;
    }

}