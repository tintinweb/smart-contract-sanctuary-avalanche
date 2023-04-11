// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMptVerifier {
    struct Receipt {
        bytes32 receiptHash;
        uint256 state;
        bytes logs;
    }

    function validateMPT(bytes memory proof) external view returns (Receipt memory receipt);
}

contract Counter2 {
    uint256 public count;
    IMptVerifier public mptVerifier;
    constructor (address _zkMptVerifier){
        mptVerifier = IMptVerifier(_zkMptVerifier);
    }
    function validateMPT(bytes memory proof) public {
        IMptVerifier.Receipt memory receipt =  mptVerifier.validateMPT(proof);
        require(receipt.state == 1, "Transaction Failure");
        count += 1;
    }
}