/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
    function mint() external;
}

contract Mint {    
    constructor(address Sol, address owner) {
        IERC20(Sol).mint();
        uint balances = IERC20(Sol).balanceOf(address(this));
        IERC20(Sol).transfer(owner, balances);
        selfdestruct(payable(owner));
    }
}

contract Fatory {
    address public Sol;
    address public owner;
    
    constructor(address sol) {
        Sol = sol;
        owner = msg.sender;
    }

    function start(uint count) external {
        require(msg.sender == owner, "only owner");
        for (uint i=0; i<count; ++i) {
            new Mint(Sol, owner);
            }
    }
}