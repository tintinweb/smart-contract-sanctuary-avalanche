/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-05
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

contract ReceiveCallBack{
    //real one 0x37414a8662bc1d25be3ee51fb27c2686e2490a89

    //testnet
    address private anycallcontractavax=0x4d5baCfEF33FB9624AF10c2d5658b6cf272BE09F ;
    address private mpcaddress=0xfa7e030d2ac001c2bA147c0b147D468E4609f7CC;
    event NewMsg(string msg);

    function receiveCallback(string calldata _msg) external {
        // if msg.sender == anycallcontractavax{
        emit NewMsg(_msg);

    }


    //ftm testnet step2 contract1 https://testnet.ftmscan.com/address/0xcdbf0b9c39a9ddff4f1508c1c5780f69a447b7de
    function step1_initiateAnyCall(string calldata _msg,address _destcontractaddress) external {
        emit NewMsg(_msg);
        if (msg.sender == mpcaddress){
        CallProxy(anycallcontractavax).anyCall(
            _destcontractaddress,
            abi.encodeWithSignature("step2_createMsgAndCallBack(uint256 rootchain,string calldata _msg)",
            block.chainid,_msg),
            address(0),
            250
            );
            
            
        }

    }

        function step1_initiateAnyCallSimple(string calldata _msg,address _destcontractaddress) external {
        emit NewMsg(_msg);
        if (msg.sender == mpcaddress){
        CallProxy(anycallcontractavax).anyCall(
            _destcontractaddress,
            abi.encodeWithSignature("step2_createMsg(string)"
            ,_msg),
            address(0),
            250
            );
            
            
        }

    }
}