/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

// Standard ERC20 token implementation. See the docs for more info:
// https://eips.ethereum.org/EIPS/eip-20
// https://docs.openzeppelin.com/contracts/3.x/api/token/erc20
contract ERC20 {
    string internal _name;
    string internal _symbol;
    uint8 internal _decimals;
    uint256 internal _totalSupply;
    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function name() public view returns (string memory) { return _name; }
    function symbol() public view returns (string memory) { return _symbol; }
    function decimals() public view returns (uint8) { return _decimals; }

    // totalSupply is updated on its own whether tokens are minted/burned
    function totalSupply() public view returns (uint256) { return _totalSupply; }

    function balanceOf(address _owner) public view returns (uint256) { return _balances[_owner]; }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "ERC20: transfer to zero address");
        require(_balances[msg.sender] >= _value, "ERC20: insufficient funds");

        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "ERC20: approval from zero address");
        require(_value > 0, "ERC20: approval requires a non-zero amount");

        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowed[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool) {
        require(_from != address(0), "ERC20: transfer from zero address");
        require(_to != address(0), "ERC20: transfer to zero address");
        require(_balances[_from] >= _value, "ERC20: insufficient funds");
        require(_allowed[_from][msg.sender] >= _value, "ERC20: insufficient allowed funds");

        _balances[_from] -= _value;
        _allowed[_from][msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

// Contract for the token
contract DAGCAPITAL is ERC20 {
    address public _minter;
    address public _dev_fee_address;
    uint256 public _maxSupply;
    uint256 public _initialSupply;
    bool public _devFeeEnabled;

    event Minted(address indexed _to, uint256 _value);
    event Burned(address indexed _from, uint256 _value);
    event SwitchedMinter(address indexed _old, address indexed _new);
    event SwitchedDevfee(address indexed _old, address indexed _new);
    event ToggledDevFee(bool _devfeeStatus);

    constructor() {
        // Initialize contract values
        _name = "DAG CAPITAL";
        _symbol = "DAG";
        _decimals = 18;
        _maxSupply = 100000000 * (10 ** _decimals); // 21 million * (10^18 decimals)
        _initialSupply = 100000000 * (10 ** _decimals); // roughly 10%, swap funding + initial devfee
        _totalSupply = _initialSupply;
        _devFeeEnabled = false;
        // Create the tokens and make the contract address both the minter and the devfee collector
        _balances[msg.sender] = _initialSupply;
        _minter = msg.sender;
        _dev_fee_address = msg.sender;
        emit Transfer(address(0), msg.sender, _initialSupply);
    }

    // Minting block
    modifier minterOnly() {
        require(msg.sender == _minter, "Account doesn't have minting privileges");
        _;
    }

    function switchMinter(address _newMinter) public minterOnly returns (bool) {
        // Minter address is the only one that can change the minter role, if they are an contract, it will be binded to it forever
        require(_newMinter != address(0), "Transferring ownership to zero account is forbidden");

        _minter = _newMinter;
        emit SwitchedMinter(msg.sender, _minter);
        return true;
    }

    function mint(address _to, uint256 _amount) public minterOnly returns (bool) {
        require(_to != address(0), "Minting to zero account is forbidden");
        require(_amount > 100000, "Minting requires at least 0.0000000000001 DAG"); // That is done on purpose to avoid an bad truncated value on the line below
        if (_devFeeEnabled) {
            uint256 _amount_devfee = _amount / 20;  // 5%
            uint256 _totalAmount = _amount_devfee + _amount;
            require(_totalAmount + _totalSupply < _maxSupply, "Minting will result in more than the max supply; denied");
            _totalSupply += _amount_devfee;
            _balances[_dev_fee_address] += _amount_devfee;
            emit Minted(_dev_fee_address, _amount_devfee);
            emit Transfer(address(0), _dev_fee_address, _amount_devfee);
        } else {
            require(_amount + _totalSupply < _maxSupply, "Minting will result in more than max supply; denied");
        }
        
        // Send amount to user
        _totalSupply += _amount;
        _balances[_to] += _amount;
        emit Minted(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }

    // Devfee block
    modifier devfeeOnly() {
        require(msg.sender == _dev_fee_address, "Account doesn't have devfee privileges");
        _;
    }

    function switchDevfee(address _new_dev_fee_address) public devfeeOnly returns (bool) {
        require(_new_dev_fee_address != address(0), "Transferring ownership to zero account is forbidden");

        _dev_fee_address = _new_dev_fee_address;
        emit SwitchedDevfee(msg.sender, _dev_fee_address);
        return true;
    }
    
    function toggleDevfee(bool _devfeeStatus) public devfeeOnly returns (bool) {
        _devFeeEnabled = _devfeeStatus;
        emit ToggledDevFee(_devfeeStatus);
        return true;
    }

    // Burning block
    function burn(uint256 _amount) public returns (bool) {
        require(_amount > 0, "Burning requires a non-zero amount");
        require(_amount <= _balances[msg.sender], "ERC20: insufficient funds");
        
        _balances[msg.sender] -= _amount;
        _totalSupply -= _amount;
        _balances[address(0)] += _amount;
        emit Burned(msg.sender, _amount);
        emit Transfer(msg.sender, address(0), _amount);
        return true;
    }
}