/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-12
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity >=0.8.0 <0.9.0;

contract DatsTest{
    
    uint storedData;

    struct DDos {
        uint256 id;
        bool isApprove;
        uint8 trafficScale;
    }

    address public owner;

    mapping(address => DDos) public ddoses;
    address[] public ddosUsers;

    constructor(){
        owner = msg.sender;
    }


    function saveDDos(bool _isApprove, uint8 _trafficScale) external {

        DDos memory ddos = DDos({
            id: ddosUsers.length + 1,
            isApprove: _isApprove,
            trafficScale: _trafficScale
        });

        ddoses[msg.sender] = ddos; 
        ddosUsers.push(msg.sender);
    }

    function getDDos() external view returns (DDos memory) {
        return ddoses[msg.sender];
    }

    function setMesut(uint x) public {
        storedData = x;
    }

    function getMesut() public view returns (uint) {
        return storedData;
    }

}