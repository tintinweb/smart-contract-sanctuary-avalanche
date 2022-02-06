/**
 *Submitted for verification at snowtrace.io on 2022-02-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;


contract RestoreEvent {

    event Transfer(uint256 id, address owner, bool isThief, bool staked);

    struct TokenData {
        uint256 id; 
        address owner; 
        bool isThief;
        bool staked;
    }

    
    function store(TokenData[] calldata data) public {
        require(msg.sender == 0xA1739d2838dB98496210541DC5ABD898d981E27C, "n");
        for (uint256 i = 0; i < data.length; i++) {
            emit Transfer(data[i].id, data[i].owner, data[i].isThief, data[i].staked);
        }
    }
}