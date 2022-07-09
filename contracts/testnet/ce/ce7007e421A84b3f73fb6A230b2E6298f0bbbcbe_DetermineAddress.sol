/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-08
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract SimpleContract {

    uint public savedNumber;
    
    constructor(uint _number) payable {
        savedNumber = _number;
    }

    
    function updateNumber(uint _newNumber) public {
        savedNumber = _newNumber;
    }

    function deleteNumber() public {
        savedNumber = 0;
    }
}

contract DetermineAddress {

    address public predictedAddress;

    function predictAddress(bytes32 salt, uint arg) public {
        predictedAddress = address(uint160(uint(keccak256(abi.encodePacked(
            bytes1(0xff),
            address(this),
            salt,
            keccak256(abi.encodePacked(
                type(SimpleContract).creationCode,
                abi.encode(arg)
            ))
        )))));
    }

    function createSalted(bytes32 salt, uint arg) public {     
        SimpleContract d = new SimpleContract{salt: salt}(arg);
        require(address(d) == predictedAddress);
    }
}

//0x190751C89eDeDDDe7A0aE42DA6AdcCc940e92bC5