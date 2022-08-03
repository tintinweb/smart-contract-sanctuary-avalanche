//adsasd
library SafeMath {
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
pragma solidity ^0.8.0;
contract test_nums  {
    using SafeMath for uint;
    //Fees will be .div(100)
    uint8 public swapTokensAmount= 10;
    uint8 public rewardsFee= 10;
    uint8 public liquidityPoolFee= 10;
    uint8 public teamPoolFee= 10;
    uint8 public cashoutFee= 10;
    uint8 public treasuryFee= 10;
    uint8 public supply= 10;
    uint8 public dec = 18;
    uint8 public dec_c= 10^18;
    uint8 public denom = 100;
    uint8 private rwSwap;
    uint8 public nodeAmount = 10;
    uint256 public dec_c2= 10**18;
    uint256 public swapTokensAmount2= 10*dec_c2;
    uint256 public rewardsFee2= 10*dec_c2;
    uint256 public liquidityPoolFee2= 10*dec_c2;
    uint256 public teamPoolFee2 = 10*dec_c2;
    uint256 public cashoutFee2= 10*dec_c2;
    uint256 public treasuryFee2= 10*dec_c2;
    uint256 public supply2= 10*dec_c2;
    uint256 public denom2 = 100*dec_c2;
    uint256 private rwSwap2= 10*dec_c2;
    uint256 public nodeAmount2 = 10;//amount of toekns needed for node purchase
    uint256 public totalClaimed = 0;
    uint8 public new_amt = nodeAmount*(teamPoolFee/(denom))+(nodeAmount*(rewardsFee/(denom)))+(nodeAmount*(treasuryFee/(denom)));
    uint256 public new_amt2 = nodeAmount2.mul(teamPoolFee2.div(denom2)).add(nodeAmount2.mul(rewardsFee2.div(denom2))).add(nodeAmount2.mul(treasuryFee2.div(denom2)));
    }