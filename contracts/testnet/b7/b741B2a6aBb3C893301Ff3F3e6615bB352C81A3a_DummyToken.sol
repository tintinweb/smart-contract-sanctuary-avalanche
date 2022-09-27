// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";
import "./Ownable.sol";
import "./Pausable.sol";

contract DummyToken is ERC20, Ownable, Pausable {

    uint constant public TOTALSUPPLY = 10000000E18;
    uint public circulatingSupply = 50000E18;

    constructor() ERC20("Dummy V2", "DY") {
        _mint(msg.sender, circulatingSupply);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 amount) public whenNotPaused onlyOwner {
        require(circulatingSupply + amount <= TOTALSUPPLY, "TOTALSUPPLY exceeds");
        _mint(to, amount);
        circulatingSupply = circulatingSupply + amount;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    )
        internal
        whenNotPaused
        override
    {
        super._transfer(sender, recipient, amount);
    }
}