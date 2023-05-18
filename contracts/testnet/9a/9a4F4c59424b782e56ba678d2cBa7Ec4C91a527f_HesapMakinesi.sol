pragma solidity ^0.8.0;

contract HesapMakinesi {
    function toplama(uint256 sayi1, uint256 sayi2) public pure returns (uint256) {
        uint256 toplam = sayi1 + sayi2;
        return toplam;
    }
}