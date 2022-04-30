// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ForwarderV2 {

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address payable public immutable treasuryAddress;
    IERC20 private token ;
    uint256 private balance;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address payable _owner) {
        treasuryAddress = _owner;
    }

    event TokensFlushed(address owner, uint256 value);

    receive() external payable {

        treasuryAddress.transfer(msg.value);
    }
    
    function flushTokens(address tokenAddress) external payable {
        token = IERC20(tokenAddress);
        balance = token.balanceOf(address(this));
        token.transfer(treasuryAddress, balance); 
        emit TokensFlushed(treasuryAddress, balance);
    }

}