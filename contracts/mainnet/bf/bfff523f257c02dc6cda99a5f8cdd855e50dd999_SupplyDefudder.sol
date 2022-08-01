/**
 *Submitted for verification at snowtrace.io on 2022-08-01
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity =0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract SupplyDefudder {
    // not selling
    
    address private constant owner = 0xAd0fc281Ac377794FA417e76D68788a56E3040f0;

    constructor() {}

    modifier onlyOwner {
        require(owner == msg.sender);
        _;
    }

    function withdraw(address _address) external onlyOwner {
        IERC20 ERC20 = IERC20(_address);
        ERC20.transfer(owner, ERC20.balanceOf(address(this)));
    }
}