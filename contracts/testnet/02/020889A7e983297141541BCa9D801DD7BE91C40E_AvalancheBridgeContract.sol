/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-15
*/

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract AvalancheBridgeContract {
    
    event WAVAXDeposited(address deposited_by, uint256 value);
    event WAVAXReleased(address deposited_by, uint256 value);

    function depositAwax(address _receiver) public payable {
        uint256 decimalPart = msg.value % (10**18);
        
        // transfer the decimal points back to user
        payable(msg.sender).transfer(decimalPart);
        // this event will be catched by bridge listener
        emit WAVAXDeposited(_receiver, msg.value);
    }

    function ReleaseAwax(address _receiver, uint256 _amount) public {
        require(
            _amount < totalDepositedAwax(),
            "Amount exceeding total Avax supply"
        );
        payable(_receiver).transfer(_amount);
        emit WAVAXReleased(_receiver, _amount);
    }

    function totalDepositedAwax() public view returns (uint256) {
        return (address(this).balance);
    }
}