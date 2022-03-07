// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC20.sol";
import "./ERC20Snapshot.sol";
import "./Ownable.sol";
import "./draft-ERC20Permit.sol";
import "./ERC20Votes.sol";

contract TestGovernanceToken is ERC20, ERC20Snapshot, Ownable, ERC20Permit, ERC20Votes {
    bool public minted;

    constructor() ERC20("Test Token", "TT") ERC20Permit("Test Token") {
        minted = false;
    }

    function initialMint(address[] memory receivers, uint256[] memory values)
    external
    onlyOwner
    {
        require(!minted, "Tokens have already been minted!");
        require(receivers.length == values.length, "Receivers-Values mismatch!");

        minted = true;

        for (uint i = 0; i < receivers.length; i++) {
            _mint(receivers[i], values[i]);
        }

        emit TestTokenMinted();
    }

    function snapshot() public onlyOwner {
        _snapshot();
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    override(ERC20, ERC20Snapshot)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function _afterTokenTransfer(address from, address to, uint256 amount)
    internal
    override(ERC20, ERC20Votes)
    {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount)
    internal
    override(ERC20, ERC20Votes)
    {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount)
    internal
    override(ERC20, ERC20Votes)
    {
        super._burn(account, amount);
    }

    event TestTokenMinted();
}