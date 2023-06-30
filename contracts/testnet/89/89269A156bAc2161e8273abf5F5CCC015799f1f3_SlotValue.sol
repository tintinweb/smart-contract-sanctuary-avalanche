// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "../../verifiers/interfaces/ISlotValueVerifier.sol";

contract SlotValue {
    ISlotValueVerifier public slotValueVerifier;

    event VerifiedSlotValueProof(
        uint64 chainId,
        bytes32 addrHash,
        bytes32 slotKey,
        bytes32 slotValue,
        uint32 blkNum,
        bytes32 blkHash
    );

    constructor(ISlotValueVerifier _verifier) {
        slotValueVerifier = _verifier;
    }

    function submitSlotValuePoof(uint64 chainId, bytes calldata proofData, bytes calldata blkVerifyInfo) external {
        ISlotValueVerifier.SlotInfo memory slotInfo = slotValueVerifier.verifySlotValue(
            chainId,
            proofData,
            blkVerifyInfo
        );
        emit VerifiedSlotValueProof(
            slotInfo.chainId,
            slotInfo.addrHash,
            slotInfo.slotKey,
            slotInfo.slotValue,
            slotInfo.blkNum,
            slotInfo.blkHash
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface ISlotValueVerifier {
    struct SlotInfo {
        uint64 chainId;
        bytes32 addrHash;
        bytes32 blkHash;
        bytes32 slotKey;
        bytes32 slotValue;
        uint32 blkNum;
    }

    function verifySlotValue(
        uint64 chainId,
        bytes calldata proofData,
        bytes calldata blkVerifyInfo
    ) external view returns (SlotInfo memory slotInfo);
}