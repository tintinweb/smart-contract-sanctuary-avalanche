/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-12
*/

pragma solidity ^0.4.26;

// ----------------------------------------------------------------------------
// 'SEANTest' 'Sean Test' token contract
//
// Deployed to : 0x4D61cA45E4C909F79bE951210c34e5D6Ed5f59cC
// Symbol      : SEANTest
// Name        : Sean Test Token
// Total supply: 100,000
// Decimals    : 0
//
// Enjoy.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd for Sean Au 2017. The MIT Licence.
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract NoRibaFinance is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    function NoRibaFinance() public {
        symbol = "NoR";
        name = "NoRiba.Finance TEST";
        decimals = 18;
        _totalSupply = 21000000;
        balances[0xb37E4e951BB9d6f52bbEA30EC5b4A158f4d83287] = _totalSupply;
        Transfer(address(0), 0xb37E4e951BB9d6f52bbEA30EC5b4A158f4d83287, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to `to` account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer `tokens` from the `from` account to the `to` account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner's account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

/**
    uint[] public myArray;

    function addToArray(uint _value) public {
        myArray.push(_value);
    }

    function getArrayLength() public view returns (uint) {
        return myArray.length;
    }

    function getArrayElement(uint _index) public view returns (uint) {
        require(_index < myArray.length, "Invalid index");
        return myArray[_index];
    }
**/


    uint public sayac;

    // Sayıyı 1 artırma işlevi
    function arttir() private {
        sayac += 1;
    }

    string[][] public matrix;

    function addMatrixElement(uint _row, uint _column, string memory _value) private {
        if (_row >= matrix.length) {
            matrix.push(new string[](_column + 1));
        } else if (_column >= matrix[_row].length) {
            string[] storage row = matrix[_row];
            string[] memory newRow = new string[](_column + 1);
            for (uint i = 0; i < row.length; i++) {
                newRow[i] = row[i];
            }
            matrix[_row] = newRow;
        }
        matrix[_row][_column] = _value;
    }

    function getMatrixElement(uint _row, uint _column) public view returns (string) {
        require(_row < matrix.length, "Invalid row");
        require(_column < matrix[_row].length, "Invalid column");
        return matrix[_row][_column];
    }

    function addAciklama(string _uyeNo, string _uyeNo1, string _nor, string memory aciklama) public {
        addMatrixElement(sayac,0,_uyeNo);
        addMatrixElement(sayac,1,_uyeNo1);
        addMatrixElement(sayac,2,_nor);
        addMatrixElement(sayac,3,aciklama);
        //addToArray(sayac);
        arttir();
    }


    mapping(uint => uint) private bakiye;
    mapping(uint => string) private eposta;


    function uintToString(uint v) constant returns (string str) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i++] = byte(48 + remainder);
        }
        bytes memory s = new bytes(i + 1);
        for (uint j = 0; j <= i; j++) {
            s[j] = reversed[i - j];
        }
        str = string(s);
    }


   function norGonder(uint _uyeNo, uint _uyeNo1, uint _nor, string _aciklama) public {
      bakiye[_uyeNo] = bakiye[_uyeNo]-_nor;
      bakiye[_uyeNo1] = bakiye[_uyeNo1]+_nor;
      addAciklama(uintToString(_uyeNo), uintToString(_uyeNo1), uintToString(_nor), _aciklama);
   }

   function bakiyeGuncelle(uint _uyeNo, uint _yeniBakiye) public {
      bakiye[_uyeNo] = _yeniBakiye;
   }

   function bakiyeGoruntule(uint _uyeNo) public view returns (uint uyeBakiye_) {
       return(bakiye[_uyeNo]);
   }

}