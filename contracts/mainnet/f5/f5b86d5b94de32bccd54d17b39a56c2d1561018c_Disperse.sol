/**
 *Submitted for verification at snowtrace.io on 2022-05-28
*/

/**
 *Submitted for verification at Etherscan.io on 2018-10-22
*/

pragma solidity ^0.4.25;


interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
}
 

contract Disperse {
    function disperseEther(address[] recipients, uint256[] values) external payable {
        for (uint256 i = 0; i < recipients.length; i++)
            recipients[i].transfer(values[i]);
        uint256 balance = address(this).balance;
        if (balance > 0)
            msg.sender.transfer(balance);
    }

    function disperseToken(IERC20 token, address[] recipients, uint256[] values) external {
        uint256 total = 0;
        for (uint256 i = 0; i < recipients.length; i++)
            total += values[i];
        require(token.transferFrom(msg.sender, address(this), total));
        for (i = 0; i < recipients.length; i++)
            require(token.transfer(recipients[i], values[i]));
    }

    function disperseTokenSimple(IERC20 token, address[] recipients, uint256[] values) external {
        for (uint256 i = 0; i < recipients.length; i++)
            require(token.transferFrom(msg.sender, recipients[i], values[i]));
    }

    function WithdrawalToken(IERC20 token,uint256 values)external{ //снять весь объем токена с контракта себе на кошелек
//  ERC20(tracker_0x_address).approve(address spender, uint tokens)
    //if(Dec == 0){Dec=18;}
 
    token.transfer(msg.sender, values);
    
    }
}