/**
 *Submitted for verification at snowtrace.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IBEP20 {
    function symbol() external view returns (string memory);
}

contract RouletteTest {

    address public priceCalc;
    address[] public tokens;        // List of tokens that are allowed to be provided to the bank.rovider withdraws from the Bank. (default: 0.5%)on provider's withdrawals. (hard coded to 4%)
    mapping(address => uint256) public houseTotalRiskable;           // Total amount of a token the house can risk.
    
    // Only callable by the owner. Adds a specific token to the list of tokens that can be provided. (and then gambled)
    function allowToken(address token_) external {
        bool alreadyAdded = false;
        houseTotalRiskable[token_] = 1000000000000000000;

        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == token_) {
                alreadyAdded = true;
                break;
            }
        }

        if (!alreadyAdded) {
            tokens.push(token_);
        }
    }
    
    // Only callable by the owner. Changes the PriceCalculator contract address.
    function setPriceCalcAddress(address newPriceCalcAddress_, uint256[] calldata amount_) public returns (address) {
        require (amount_[0] != 10000, "Roulette::gamble: Max possible winnings higher than max House risk");
        require (amount_[1] != 10000, "Roulette::gamble: stupid ASS");
        require(
            newPriceCalcAddress_ != address(0),
            "Roulette::setPriceCalcAddress: Random number generator address cannot be the zero address"
        );

        priceCalc = newPriceCalcAddress_;
        return (priceCalc);
    }

    // Returns the address of an allowed token from its symbol.
    function getAllowedTokenAddressFromSymbol(string memory symbol_) external view returns (address) {
        for (uint i = 0; i < tokens.length; i++) {
            if (keccak256(bytes(IBEP20(tokens[i]).symbol())) == keccak256(bytes(symbol_))) {
                return tokens[i];
            }
        }
        return address(0);
    }

    function gamble(uint256[] calldata amount_, address token_) external returns (uint[] memory amounts) {
        setPriceCalcAddress(token_, amount_);
        if (token_ == address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7))
            return amount_;
        else {
            uint256[] memory newAmount = amount_;
            for (uint i = 0; i < amount_.length; i++) {
                if (amount_[i] > 2) newAmount[i] = amount_[i]/2;
                else newAmount[i] = 0;
            }
            return newAmount;
        }
    }

    // Returns the allowed token addresses array.
    function getTokens() external view returns (address[] memory) {
        return tokens;
    }
}