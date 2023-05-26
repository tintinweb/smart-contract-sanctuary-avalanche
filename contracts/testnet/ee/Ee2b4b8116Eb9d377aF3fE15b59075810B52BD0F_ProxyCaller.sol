/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;


contract ProxyCaller {

    address private _tradingBoat;

    event CalledSender(bool status, bytes hash);
    event CalledRelayer(bool status);

    constructor()
    {
        _tradingBoat = 0x4f78f2b0dae962E3246e1D9b8018bB9C2c88b59C;
    }

    function setBoat(address _newboat) external {
        _tradingBoat = _newboat;
    }

    function callSender(
        address boat, 
        string calldata _method,
        bytes32[] calldata _args,
        uint64 _toChainId,
        address _toContract
        ) external {

        bytes memory functionSig = abi.encodePacked("sendShipment", "(string,bytes32[],uint64,address)");
        bytes4 selector = bytes4(keccak256(functionSig));

        (bool success, bytes memory data) = boat.call(
            abi.encodeWithSelector(selector, _method, _args, _toChainId, _toContract)
        );

        emit CalledSender(success, data);
        
    }

    function callRelayer(
        address boat,
        string calldata _method, 
        bytes32[] calldata _args,
        uint64 _fromChainId,
        address _fromContract,
        address _toContract,
        bytes calldata _signature
        ) external {
            
            bytes memory functionSig = abi.encodePacked(_method, "(bytes32[],uint64,address,address,bytes)");
            bytes4 selector = bytes4(keccak256(functionSig));

            (bool status, ) = boat.call(
                abi.encodeWithSelector(selector, _args, _fromChainId, _fromContract, _toContract, _signature)
            );

            emit CalledRelayer(status);
        }
}