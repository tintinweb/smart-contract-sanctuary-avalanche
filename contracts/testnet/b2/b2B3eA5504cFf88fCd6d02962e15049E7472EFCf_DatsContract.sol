/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2;

contract DatsContract{

    struct DDos {
        uint256 id;
        address user;
        bool isApprove;
        uint8 trafficScale;
    }

    address public owner;

    mapping(address => DDos) public ddoses;
    DDos[] public ddosArray;

    constructor(){
        owner = msg.sender;
    }

    function getAllUserDDosSettings() public view returns(DDos[] memory){
        require(owner == msg.sender, "You are not authorized.");
        return ddosArray;
    }

    function saveDDos(bool _isApprove, uint8 _trafficScale) external {

        DDos memory ddos = DDos({
            id: ddosArray.length + 1,
            user: msg.sender,
            isApprove: _isApprove,
            trafficScale: _trafficScale
        });

        if(ddoses[msg.sender].id == 0)
            ddosArray.push(ddos);

        ddoses[msg.sender] = ddos;  
        
    }

    function getDDos() external view returns (DDos memory) {
        return ddoses[msg.sender];
    }

    function getDDosByUser(address _user) external view returns (DDos memory){
        return ddoses[_user];
    }

    function getDDosCount() external view returns(uint256) {
        return ddosArray.length;
    }

}