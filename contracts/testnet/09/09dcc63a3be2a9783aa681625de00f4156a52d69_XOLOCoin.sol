/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-18
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract XOLOCoin {

    mapping(address => uint256) public balances;

    function transfer(address receiver, uint256 amount) public {
        require(balances[msg.sender] >= amount, "Not enough balance");

        balances[msg.sender] = balances [msg.sender] - amount;

        balances[receiver] = balances[receiver] + amount;
    }

    function mint() public {
        balances[msg.sender] = 100;

    }

    function name() public pure returns (string memory) {
            return "XOLO Coin";
    }

    function symbol() public pure returns (string memory)  {
            return "XOLO";
    }

    }