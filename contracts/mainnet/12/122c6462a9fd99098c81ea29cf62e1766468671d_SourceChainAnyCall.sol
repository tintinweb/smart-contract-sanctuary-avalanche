/**
 *Submitted for verification at snowtrace.io on 2022-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface CallProxy{
    function anyCall(
        address _to,
        bytes calldata _data,
        address _fallback,
        uint256 _toChainID
    ) external;
}

contract SourceChainAnyCall{
    //real one 0x37414a8662bC1D25be3ee51Fb27C2686e2490A89

    address private anycallcontractavax=0x37414a8662bC1D25be3ee51Fb27C2686e2490A89;
    address private owneraddress=0xfa7e030d2ac001c2bA147c0b147D468E4609f7CC;
    address private ftmsidecontract=0x0Ea8637dd3436e125D1433F62D75dB1E07d97a6d;
    
    event NewMsg(string msg);


    function step1_initiateAnyCallSimple(string calldata _msg) external {
        emit NewMsg(_msg);
        if (msg.sender == owneraddress){
        CallProxy(anycallcontractavax).anyCall(
            ftmsidecontract,
            abi.encodeWithSignature("step2_createMsg(string)"
            ,_msg),
            address(0),
            250
            );
            
        }

    }
}