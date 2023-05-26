/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-25
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;


/**
 * @title TradingBoat
 * @notice Contract which manages cross-chain logic.
 * Facilitates cross-chain calls by relaying them to and from
 * other TradingBoat contracts in different chains.
 */
contract ProxyCaller {

    address private _tradingBoat;

    event BridgeHash(bool status, bytes hash);

    constructor()
    {
        _tradingBoat = 0x4f78f2b0dae962E3246e1D9b8018bB9C2c88b59C;
    }

    function setBoat(address _newboat) external {
        _tradingBoat = _newboat;
    }

    function callShipment(string calldata _method,
        bytes32[] calldata _args,
        uint64 _toChainId,
        address _toContract
        ) external {

        bytes memory functionSig = abi.encodePacked("sendShipment", "(string,bytes32[],uint64,address)");
        bytes4 selector = bytes4(keccak256(functionSig));

        (bool success, bytes memory data) = _tradingBoat.call(
            abi.encodeWithSelector(selector, _method, _args, _toChainId, _toContract)
        );

        emit BridgeHash(success, data);
        
    }
}