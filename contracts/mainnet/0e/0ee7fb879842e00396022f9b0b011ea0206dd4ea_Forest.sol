// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./ERC20Burnable.sol";
import "./Ownable.sol";

import "./SafeMath.sol";
import "./SellTax.sol";

contract Forest is ERC20, ERC20Burnable, Ownable, SellTax {
    using SafeMath for uint256;

    event TransferFromWithTax(uint256 _taxAmount);
    event TransferWithTax(uint256 _taxAmount);

    constructor(uint256 _initialSupply) ERC20("Forest", "FOREST") SellTax(msg.sender) {
        _mint(msg.sender, _initialSupply * 10 ** decimals());
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        bool requiresTax = requiresTax(to);

        if ( requiresTax ) {
            uint256 taxedAmount = calculateTaxAmount(amount);

            _spendAllowance(from, spender, amount);

            _transfer(from, taxReceiver, taxedAmount);
            _transfer(from, to, amount.sub(taxedAmount));

            emit TransferFromWithTax(taxPercentage);
        } else {
            _spendAllowance(from, spender, amount);
            _transfer(from, to, amount);
        }

        return true;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        bool requiresTax = requiresTax(to);

        if ( requiresTax ) {
            uint256 taxedAmount = calculateTaxAmount(amount);

            _transfer(owner, taxReceiver, taxedAmount);
            _transfer(owner, to, amount.sub(taxedAmount));

            emit TransferWithTax(taxPercentage);
        } else {
            _transfer(owner, to, amount);
        }

        return true;
    }
}