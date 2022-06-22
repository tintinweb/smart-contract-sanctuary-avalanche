/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-22
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.9;


interface IWhitelistMinimal {

    // wl sale has ended
    function wlEnded() external view returns (bool);
    // glad sale has ended
    function gladEnded() external view returns (bool);
  
    // get the amount of pglad purchased by user (wl buys included)
    function pGlad(address _a) external view returns (uint256);
 
    // check if an address is whitelisted
    function isWhitelisted(address _a) external view returns (bool);
}

contract TestWhitelist is IWhitelistMinimal {
    mapping(address => bool) public wl;
    mapping(address => uint256) public pglad;
    mapping(address => uint256) public pgladwl;
    bool public wlEnded;
    bool public gladEnded;
    bool public started = true;
    uint256 public spotCount = 111;
    uint256 public spotPrice = 3 ether;
    uint256 public maxSpots = 150;
    uint256 public maxWlAmount = 1000 ether;
    uint256 public pGladPrice = 30;
    uint256 public pGladWlPrice = 20;

    function setWl(address a, bool b) public {
        wl[a] = b;
    }

    function addPglad(address a, uint256 am) public {
        pglad[a] = am;
    }

    function addPgladWl(address a, uint256 am) public {
        pgladwl[a] = am;
    }

    // wl sale has ended
    function endWl(bool b) external {
        wlEnded = b;
    }
    // glad sale has ended
    function endGlad(bool b) external {
        gladEnded = b;
    }
 
    // get the amount of pglad wl purchased by user
    function pGladWl(address _a) external view returns (uint256) {
        return pgladwl[_a];
    }
  
    // get the amount of pglad purchased by user (wl buys included)
    function pGlad(address _a) external view returns (uint256) {
        return pglad[_a];
    }
 
    // check if an address is whitelisted
    function isWhitelisted(address _a) external view returns (bool) {
        return wl[_a];
    }

    /// @dev set mock spotPrice
    function setSpotPrice(uint256 _spotPrice) external {
        spotPrice = _spotPrice;
    }

    /// @dev set mock maxSpots
    function setMaxSpots(uint256 _maxSpots) external {
        maxSpots = _maxSpots;
    }

    /// @dev set mock maxWlAmount
    function setMaxWlAmount(uint256 _maxWlAmount) external {
        maxWlAmount = _maxWlAmount;
    }

    /// @dev set mock pGladPrice
    function setPGladPrice(uint256 _pGladPrice) external {
        pGladPrice = _pGladPrice;
    }

    /// @dev set mock pGladWlPrice
    function setPGladWlPrice(uint256 _pGladWlPrice) external {
        pGladWlPrice = _pGladWlPrice;
    }

}