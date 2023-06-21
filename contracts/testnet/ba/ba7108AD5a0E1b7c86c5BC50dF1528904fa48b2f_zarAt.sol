/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-20
*/

// SPDX-License-Identifier: unlicenced
pragma solidity 0.8.0;

contract zarAt {
    event kazandi(uint _value);
    event kaybetti(uint _value);
    event gelenZar(uint _gelenZar, address _address, uint kz);
    uint katsayi = 100;
    mapping (address => uint) public kanParasi;
    mapping (address => uint) bekle;
    
    
    function paraAl (uint _value) external {
        require(_value <= 10000);
        require(bekle[msg.sender] < block.timestamp);
        kanParasi[msg.sender] = kanParasi[msg.sender] + _value;
        bekle[msg.sender] = block.timestamp + bekle[msg.sender] + (_value) * 60;


    }
    function zarAtma(uint _value) external {
        uint a = uint(keccak256(abi.encodePacked(block.timestamp)));
        uint b = a % 6;
        kanParasi[msg.sender] = kanParasi[msg.sender] - _value;
        emit gelenZar(b + 1, msg.sender, _value);
        if (b == 5) {
            
            kanParasi[msg.sender] = kanParasi[msg.sender] + (_value) * 2;
            emit kazandi((_value)*2);


        }
        else{
            emit kaybetti((_value));

        }
    }
    function kacParaVar(address _address) public view returns (uint) {
        return kanParasi[_address];
        
    } 






}