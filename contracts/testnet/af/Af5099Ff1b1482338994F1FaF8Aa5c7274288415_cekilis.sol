/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-25
*/

// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.0;

contract cekilis {
    event gelenSayi(uint _sayi);
    struct cekilisHakki {
        address _address;
        bool odendimi;
        uint id;
        uint kazanilanPara;
    }
    cekilisHakki[] public katilanlar;
    mapping (address => uint) bakiye;
    uint cekilisBedeli = 100;
    uint katilanKisi = 0;

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
        uint c =katilanlar.length - katilanKisi;
        uint b = a % c;
        uint d = b + katilanKisi;
        
        katilanlar[(d)].kazanilanPara = c * 100;
        require(katilanlar[d].odendimi);
        bakiye[katilanlar[d]._address] = katilanlar[d].kazanilanPara + bakiye[katilanlar[d]._address];
        katilanlar[d].kazanilanPara = 0 ;
        katilanKisi = katilanlar.length ;
        emit gelenSayi(d);



    }
    function paramNe(address _address) public view returns (uint) {
        return bakiye[_address];
    }



}