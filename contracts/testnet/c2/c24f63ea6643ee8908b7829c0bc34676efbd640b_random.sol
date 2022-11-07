/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract random {

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function blockHash() public view returns (bytes32){
        return blockhash(block.number-1);
    }

    function baseFee() public view returns (uint){
        //return block.basefee;
    }

    function coinbase() public view returns (address){
        return block.coinbase;
    }

    function difficulty() public view returns (uint){
        return block.difficulty;
    }
    
    function gaslimit() public view returns (uint){
        return block.gaslimit;
    }

    function gasLeft() public view returns (uint256){
        return gasleft();
    }

    function timestamp() public view returns (uint256){
        return block.timestamp;
    }


}