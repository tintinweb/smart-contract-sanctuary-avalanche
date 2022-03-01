/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-01
*/

pragma solidity ^0.5.11;


contract DevSample {
    uint256 public myUint;
    bool public myBool;

    function setMyUint (uint _myUint) public {
        myUint = _myUint+1;
    }

    function  setMyBool (bool _myBool) public {
        myBool = _myBool;
    }

    function incCount () public {
        myUint = myUint+1;
    }

    uint8 public myUint8;

    function incrementUint() public {
        myUint8++;
    }

    function decrementUint() public {
        myUint8--;
    }

    address public myAddress;

    function setAddress(address _address) public {
        myAddress = _address;
    }

    function getBalanceOfAddress() public view returns(uint) {
        return myAddress.balance;
    }

    string public myString = 'hello world';

    function setMyString(string memory _myString) public {
        myString = _myString;
    }
}