// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./ReentrancyGuard.sol";

contract ForwarderV2 is ReentrancyGuard {

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address payable public treasuryAddress;
    IERC20 private token ;
    uint256 private balance;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address payable _owner) {
        treasuryAddress = _owner;
    }

    event TokensFlushed(address owner, uint256 value);

    function flushTokens(address tokenAddress) external payable nonReentrant {
        token = IERC20(tokenAddress);
        balance = token.balanceOf(address(this));
        token.transfer(treasuryAddress, balance); 
        emit TokensFlushed(treasuryAddress, balance);
    }

    receive() external payable {

        treasuryAddress.transfer(msg.value);
    }

}