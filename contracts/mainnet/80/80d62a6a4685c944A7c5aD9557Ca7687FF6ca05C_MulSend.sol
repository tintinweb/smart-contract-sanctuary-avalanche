/**
 *Submitted for verification at snowtrace.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
interface IERC20{
    function balanceOf(address) external view returns(uint);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MulSend{

    address constant private wavax = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;//wavax
    
    function send(address _tkn, uint256 _amount, address payable [] memory _addrArr) payable public{
        
        if(_tkn == wavax){
            require(msg.value >= _addrArr.length * _amount, 'not enough money');
        }else{
            require(IERC20(_tkn).balanceOf(msg.sender) >= _addrArr.length * _amount);
        }
        
        for(uint8 i=0;i<_addrArr.length;i++){
            if(_tkn == wavax){
                _addrArr[i].transfer(_amount);
            }else{
                IERC20(_tkn).transferFrom(msg.sender, _addrArr[i], _amount);
            }
        }
    }
}