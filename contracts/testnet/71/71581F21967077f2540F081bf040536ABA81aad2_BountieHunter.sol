// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "ERC20.sol";
import "Ownable.sol";

contract BountieHunter is ERC20, Ownable {

    constructor() public ERC20 ("Bountie", "BNT")
    {
        _mint(msg.sender, 500000000000000000000000000);
        emit Transfer(address(0), msg.sender, 1000000000000000000000);
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function balanceInEth() public view returns(uint256) {
        return balanceOf(msg.sender) / 1e18;
    }

    function balanceInEthC(address a) public view returns(uint256) {
        return balanceOf(a) / 1e18;
    }

}