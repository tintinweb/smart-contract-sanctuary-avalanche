// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "./interface/ICosmosCircuitVerifier.sol";

// this a test
contract CosmosUpdater {

    event ModCircuitVerifier(
        address oldCircuitVerifier,
        address newCircuitVerifier
    );

    struct MerkleRootInfo {
        uint256 blockNumber;
        bytes32 parentHeaderRoot;
        bytes32 currentHeaderRoot;
    }

    struct BlockInfo {
        uint256 height;
        uint256 validID;
        uint256 validVP;
        uint256 totalVP;
        bytes32 parentHeaderRoot;
        bytes32 currentHeaderRoot;
    }

    uint256 public currentHeight;
    bytes32 public lastHeaderRoot;
    ICosmosCircuitVerifier public circuitVerifier;
    mapping(bytes32 => MerkleRootInfo) public blockInfos;


    constructor(address circuitVerifierAddress) {
        circuitVerifier = ICosmosCircuitVerifier(circuitVerifierAddress);
    }

    function updateBlock(
        uint256[2][] calldata a,
        uint256[2][2][] calldata b,
        uint256[2][] calldata c,
        uint256[6][] calldata inputs
    ) external {
        //        for (uint256 i = 0; i < a.length; i++) {
        //            require(
        //                circuitVerifier.verifyProof(a[i], b[i], c[i], inputs[i]),
        //                "verifyProof failed"
        //            );
        //        }
        BlockInfo memory blockInfo = _parseAndVerifyInput(inputs);
        if (currentHeight != 0) {
            require(blockInfo.parentHeaderRoot == lastHeaderRoot, "1");
        }
        lastHeaderRoot = blockInfo.currentHeaderRoot;
        currentHeight = blockInfo.height;
        MerkleRootInfo memory tempInfo = MerkleRootInfo(
            blockInfo.height,
            blockInfo.parentHeaderRoot,
            blockInfo.currentHeaderRoot
        );
        blockInfos[blockInfo.currentHeaderRoot] = tempInfo;
    }

    function _parseAndVerifyInput(uint256[6][] memory inputs)
    public
    pure
    returns (BlockInfo memory)
    {
        uint256 validID = inputs[0][1];
        uint256 validVP = inputs[0][2];
        uint256 totalVP = inputs[0][3];
        if (inputs.length > 1) {
            for (uint256 i = 1; i < inputs.length; i++) {
                validID = validID ^ inputs[i][1];
                validVP = validVP + inputs[i][2];
            }
        }
        uint256 count = 0;
        for (; validID > 0; validID /= 2) {
            uint256 bit = validID % 2;
            if (bit > 0) {
                count++;
            }
        }
        require(count >= 36 * inputs.length, "2");
        require(validVP >= totalVP * 66666 / 100000, "3");

        BlockInfo memory result;
        result.height = inputs[0][0] + 1;
        result.validID = validID;
        result.validVP = validVP;
        result.totalVP = totalVP;
        result.parentHeaderRoot = bytes32(inputs[0][4]);
        result.currentHeaderRoot = bytes32(inputs[0][5]);
        return result;
    }

    function setCircuitVerifier(address circuitVerifierAddress) external {
        require(address(circuitVerifier) != circuitVerifierAddress, "Incorrect circuitVerifierAddress");
        emit ModCircuitVerifier(address(circuitVerifier), circuitVerifierAddress);
        circuitVerifier = ICosmosCircuitVerifier(circuitVerifierAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ICosmosCircuitVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[35] memory input
    ) external view returns (bool);
}