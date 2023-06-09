/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Test{
    
    Test test;
    using SafeMath for uint256;
    function Claim (uint256 _val) external {
        test = Test(address(this));
        test.set(_val);
        // set(_val);
    }

    function calimed(uint _val) external {
        test = Test(address(this));
        test.Claim(_val);
        // Claim(_val);
    }
    enum Gender 
    {
      male,
      female,
      other
    }
    Gender g;
    function getValue () public view returns (Gender)
    {   
        return g;
    }

    function set(uint256 _val) external  {
        require(_val >=1 && _val <=3, "invalid value");
        if(_val == 1){
            g = Gender.male;
        }
        else if(_val == 2){
            g = Gender.female;
        }
        else if(_val == 3){
            g = Gender.other;
        }
    }
}