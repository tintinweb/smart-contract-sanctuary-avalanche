/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-25
*/

// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.0;

contract cekilis {
    
    struct cekilisHakki {
        address _address;
        bool odendimi;
        uint id;
        uint kazanilanPara;
    }
    cekilisHakki[] public katilanlar;
    mapping (address => uint) bakiye;
    uint cekilisBedeli = 100;

    function paraAl() public {
        bakiye[msg.sender] = bakiye[msg.sender] + 10000000;
    }

    function hakAl() public {
        require(bakiye[msg.sender] > cekilisBedeli);
        bakiye[msg.sender] = bakiye[msg.sender] - cekilisBedeli;
        uint id = katilanlar.length;
        katilanlar.push(cekilisHakki(msg.sender, true, id, 0));        
    }
    function kazananiBelirle() public {
        uint a = uint(keccak256(abi.encodePacked(block.timestamp)));
        uint b = a % katilanlar.length;
        katilanlar[b].kazanilanPara = katilanlar.length * 100;
        require(katilanlar[b].odendimi);
        bakiye[katilanlar[b]._address] = katilanlar[b].kazanilanPara + bakiye[katilanlar[b]._address];
        katilanlar[b].kazanilanPara = 0 ;
        

    }



}