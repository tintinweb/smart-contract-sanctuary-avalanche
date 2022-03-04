/**
 *Submitted for verification at snowtrace.io on 2022-03-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract CryptoPuffiesBestFriends {
    struct Stats {
        uint16 bestFriend;
        uint16 nemesis;
    }
    uint256 constant public MAX_TOKENS = 8888;
    uint256 public amountAssigned = 1;
    uint256[] public relationsPrimes = [487, 631, 1163, 1663, 2999, 4549, 5737, 6619, 6779, 7561, 
                                            21767, 23333, 29851, 33023, 39317, 42283, 49417, 51407, 52147, 54437];
    // Mapping from token ID to its stats
    mapping(uint256 => Stats) public puffyStats;
    constructor() {
        //assign best friend and nemesis for token 0
        Stats storage data = puffyStats[0];
        data.bestFriend = 3811;
        data.nemesis = 8255;
        puffyStats[3811].bestFriend = uint16(0);
        puffyStats[8255].nemesis = uint16(0);                
    }
    function bestFriend(uint256 tokenId) public view virtual returns (uint16) {
        return puffyStats[tokenId].bestFriend;
    }
    function nemesis(uint256 tokenId) public view virtual returns (uint16) {
        return puffyStats[tokenId].nemesis;
    }
    function assignBestFriends(uint256 amountToAssign) external {
        require(amountAssigned + amountToAssign <= MAX_TOKENS, "input too high");
        for (uint256 i = 0; i < amountToAssign; i++) {
            _setStats(amountAssigned + i);
        }
        amountAssigned += amountToAssign;
    }
    function _setStats(uint256 tokenId) internal {
        Stats storage data = puffyStats[tokenId];
        uint256 thousandsPlace = tokenId / 1111;
        if (data.bestFriend == uint16(0) && 3811 != tokenId) {
//        if (data.bestFriend == uint16(0) && bestFriend(0) != tokenId) {
            uint16 _bestFriend = uint16(
                    (
                        (
                            ((tokenId + relationsPrimes[thousandsPlace]) * relationsPrimes[thousandsPlace + 10]) % 1111)
                        + 3333 + thousandsPlace * 1111)
                % MAX_TOKENS);
            if (puffyStats[_bestFriend].bestFriend == 0) {
                data.bestFriend = _bestFriend;
                puffyStats[_bestFriend].bestFriend = uint16(tokenId);
            }
        }
        if (data.nemesis == uint16(0) && 8255 != tokenId) {
//        if (data.nemesis == uint16(0) && nemesis(0) != tokenId) {
            uint16 _nemesis = uint16(
                    (
                        (
                            ((tokenId + relationsPrimes[thousandsPlace + 10]) * relationsPrimes[thousandsPlace]) % 1111)
                        + 7777 + thousandsPlace * 1111)
                % MAX_TOKENS);
            if (puffyStats[_nemesis].nemesis == 0) {
                data.nemesis = _nemesis;
                puffyStats[_nemesis].nemesis = uint16(tokenId);                
            }
        }
    }
}