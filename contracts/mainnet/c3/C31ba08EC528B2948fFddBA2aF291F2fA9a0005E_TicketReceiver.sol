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
    address public constant xWalrus = 0x2dc3Bb328000553D1D64ec1BEF00572F62B5Ec7C;
    address public constant walrus = 0x395908aeb53d33A9B8ac35e148E9805D34A555D3;
    address public constant wbond = 0xa8cFe8b4e8632cF551692Ddf78B97Ff4784dF14a;

    address public prizePool;

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

    function trigger() external {

        // burn all wbond in contract
        uint256 wbondbal = IERC20(wbond).balanceOf(address(this));
        if (wbondbal > 0) {
            IBurnable(wbond).burn(wbondbal);
        }
        
        // convert walrus into xWalrus and add to the prize pool
        uint256 walrusbal = IERC20(walrus).balanceOf(address(this));
        if (walrusbal > 0) {
            IERC20(walrus).approve(xWalrus, walrusbal);
            IXWalrus(xWalrus).mint(walrusbal);
            IERC20(xWalrus).transfer(prizePool, IERC20(xWalrus).balanceOf(address(this)));
        }
    }
}