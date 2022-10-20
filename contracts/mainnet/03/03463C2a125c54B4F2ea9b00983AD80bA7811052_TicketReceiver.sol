//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import "./IERC20.sol";

interface IBurnable {
    function burn(uint amount) external;
}

interface IXWalrus {
    function mint(uint amount) external;
}

interface IOwned {
    function getOwner() external view returns (address);
}

contract TicketReceiver {

    // Constant Contracts
    address public constant xGrape = 0x95CED7c63eA990588F3fd01cdDe25247D04b8D98;
    
    // prize pool contract
    address public prizePool;

    // treasury address
    address public treasury = 0xf29fD03Df2Cb7F81d8Ae4d10A76f8b1C898786BD;

    modifier onlyOwner() {
        require(
            msg.sender == IOwned(prizePool).getOwner(),
            'Only Owner'
        );
        _;
    }

    constructor(address prizePool_) {
        prizePool = prizePool_;
    }

    function withdraw(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function setPrizePool(address newPool) external onlyOwner {
        prizePool = newPool;
    }

    function setTreasury(address newTreasury) external onlyOwner {
        treasury = newTreasury;
    }

    function trigger() external {

        // get balance of xGrape
        uint256 xBal = IERC20(xGrape).balanceOf(address(this));
        if (xBal <= 100000) {
            return;
        }

        // burn 10%, send 10% to treasury
        uint256 tenth = xBal / 10;
        IBurnable(xGrape).burn(tenth);
        IERC20(xGrape).transfer(treasury, tenth);
        
        // send remaining to the prize pool
        uint remaining = IERC20(xGrape).balanceOf(address(this));
        if (remaining > 0) {
            IERC20(xGrape).transfer(prizePool, remaining);
        }
    }
}