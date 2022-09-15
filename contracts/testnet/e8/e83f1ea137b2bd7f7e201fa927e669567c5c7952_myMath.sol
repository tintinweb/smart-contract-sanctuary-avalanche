/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-15
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-15
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
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
contract myMath{
	using SafeMath for uint256;
		function EXTaddressInList(address[] memory _list, address _account) external view returns (bool){
			return addressInList(_list,_account);
			}
		function addressInList(address[] memory _list, address _account) internal pure returns (bool){
			for(uint i=0;i<_list.length;i++){
				if(_account == _list[i]){
					return true;
				}
			}
			return false;
		}
		function EXTisInList(address[] memory _list, address _account) external view returns (uint256){
			return isInList(_list,_account);
			}
		function isInList(address[] memory _list, address _account) internal pure returns (uint256){
			for(uint i=0;i<_list.length;i++){
				if(_account == _list[i]){
					return i;
				}
			}
		}
		function EXTsafeDiv(uint256 _x,uint256 _y) external view returns(uint256){
			return safeDiv(_x,_y);
			}
		function safeDiv(uint256 _x,uint256 _y) internal view returns(uint256){
			uint256 Zero = 0;
			if(_y == Zero || _x == Zero || _x > _y){
				return (Zero);
			}
			uint i;
			while(_y >_x){
				i++;
				_y -= _x;
				
			}
			return i;
		}
		function EXTgetAllMultiple(uint256 _x,uint256 _y)external view returns (uint256,uint256){
			return getAllMultiple(_x,_y);
			}
		
		function getAllMultiple(uint256 _x,uint256 _y)internal pure returns(uint256,uint256){
			uint256 Zero = 0;
			if (_y == Zero || _x == Zero || _x > _y){
				return (Zero,_y);
			}
			uint256 z = _y;
			uint256 i = 0;
			while(z >= _x){
				i++;
				z -=_x;
							
			}
			return (i,z);
		}
		function EXTgetRemainder(uint256 _x,uint256 _y)external view returns(uint256){
			return getRemainder(_x,_y);
			}
		
		function getRemainder(uint256 _x,uint256 _y)internal pure returns(uint256){
			(uint256 mult,uint256 rem) =  getAllMultiple(_x,_y);
			return rem;
		}
		function EXTgetMultiple(uint256 _x,uint256 _y)external view returns (uint256){
			return getMultiple(_x,_y);
			}
		function getMultiple(uint256 _x,uint256 _y)internal pure returns(uint256){
			(uint256 mult,uint256 rem) = getAllMultiple(_x,_y);
			return mult;
		}
		function EXTdoMultiple(uint256 _x,uint256 _y)external view returns (uint256){
			return doMultiple(_x,_y);
			}
		function doMultiple(uint256 _x,uint256 _y)internal pure returns(uint256){
			uint256 Zero = 0;
			if (_y == Zero || _x == Zero || _x > _y){
				return Zero;
			}
			uint256 _z = _y;
			uint256 One = 1;
			while(_x > One){
				_z += _y;
				_x.sub(One); 		
			}
			return _z;
		}
		function EXTdoAllMultiple2(uint256 _x,uint256 x_2,uint256 _y,uint256 _z) external view returns (uint256,uint256,uint256,uint256){
			return doAllMultiple2(_x,x_2,_y,_z);
			}
		function doAllMultiple2(uint256 _x,uint256 x_2,uint256 _y,uint256 _z) internal pure returns(uint256,uint256,uint256,uint256){
		//doAllMultiple(uint256 _x,uint256 _y,uint256 _z) (MAXinterval,total,fee)
			uint256 Zero = 0;
			if (_y == Zero || _x == Zero || _x > _y){
				return (_x,Zero,Zero,_y);
			}
			uint256 i = 0;
			uint256 _k = _y;
			uint256 One = 1;
			uint256 _w = 0;
			while(_y > _z && _x!=0){
				i++;
				_k -= _z;
				_w += _y;
				_x-=x_2;	
			}
			return (_x,i,_w,_k);//(multiplierRemainder,multiplier,newtotal,remainder)
		}
		function EXTdoAllMultiple(uint256 _x,uint256 _y,uint256 _z) external view returns (uint256,uint256,uint256,uint256){
			return doAllMultiple(_x,_y,_z);
			}
		function doAllMultiple(uint256 _x,uint256 _y,uint256 _z) internal pure returns(uint256,uint256,uint256,uint256){
		//doAllMultiple(uint256 _x,uint256 _y,uint256 _z) (MAXinterval,total,fee)
			uint256 Zero = 0;
			if (_y == Zero || _x == Zero || _x > _y){
				return (_x,Zero,Zero,_y);
			}
			uint256 i = 0;
			uint256 _k = _y;
			uint256 One = 1;
			uint256 _w = 0;
			while(_y > _z && _x!=0){
				i++;
				_k -= _z;
				_w += _y;
				_x-=One;	
			}
			return (_x,i,_w,_k);//(multiplierRemainder,multiplier,newtotal,remainder)
		}
		function EXTgetDecimals(uint256 _x) external view returns (uint256){
			return getDecimals(_x);
			}
		function getDecimals(uint256 _x) internal view returns(uint256){
				uint256 i;
			while(_x >0){
				_x = _x/(10);
				i++;
			}
			return i;
		}
		function EXTsafeMuls(uint256 _x,uint256 _y)external view returns (uint256){
			return safeMuls(_x,_y);
			}
		function safeMuls(uint256 _x,uint256 _y) internal view returns (uint256){
			uint256 dec1 = getDecimals(_x);
			uint256 dec2 = getDecimals(_y);
			if(dec1 > dec2){
				return (_x*_y)/(10**dec1);
			}
			return (_x*_y)/(10**dec2);
		}
		function EXTfindInList(address[] memory _ls,address _account)external view returns (uint){
			return findInList(_ls,_account);
			}
		function findInList(address[] memory _ls,address _account) internal pure returns(uint){
			for(uint i = 0;i<_ls.length;i++){
				if(_ls[i] == _account){
					return i;
				}
			}
		}
		function EXTisLower(uint256 _x,uint256 _y)external view returns (bool){
			return isLower(_x,_y);
			}
		function isLower(uint256 _x,uint256 _y) internal pure returns(bool){
			if(_x<_y){
				return true;
			}
			return false;
		}
		function EXTisHigher(uint256 _x,uint256 _y)external view returns (bool){
			return isHigher(_x,_y);
			}
		function isHigher(uint256 _x,uint256 _y) internal pure returns(bool){
			if(_x>_y){
				return true;
			}
			return false;
		}
		
		function EXTisEqual(uint256 _x,uint256 _y)external view returns (bool){
			return isEqual(_x,_y);
			}
		function isEqual(uint256 _x,uint256 _y) internal pure returns(bool){
			if(isLower(_x,_y)==false && isHigher(_x,_y) ==false){
				return true;
			}
			return false;
		}
		function EXTgetLower(uint256 _x,uint256 _y)external view returns (uint256){
			return getLower(_x,_y);
			}
		function getLower(uint256 _x,uint256 _y) internal pure returns(uint256){
			if(isEqual(_x,_y)==true || isLower(_x,_y) == true){
				return _x;
			}
			return _y;
		}
		function EXTgetHigher(uint256 _x,uint256 _y)external view returns (uint256){
			return getHigher(_x,_y);
			}
		function getHigher(uint256 _x,uint256 _y) internal pure returns(uint256){
			if(isEqual(_x,_y)==true || isHigher(_x,_y) == true){
				return _x;
			}
			return _y;
		}
		
}