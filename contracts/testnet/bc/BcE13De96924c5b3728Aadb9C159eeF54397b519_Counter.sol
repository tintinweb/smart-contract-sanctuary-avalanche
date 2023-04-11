// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IZKMptVerifier {
    struct Receipt {
        bytes32 receiptHash;
        uint256 state;
        bytes logs;
    }

    function validateMPT(bytes memory proof) external view returns (Receipt memory receipt);
}

contract Counter {
    uint256 public count;
    IZKMptVerifier public zkMptVerifier;
    constructor (address _zkMptVerifier){
        zkMptVerifier = IZKMptVerifier(_zkMptVerifier);
    }
    function validateMPT(bytes memory proof) public {
        IZKMptVerifier.Receipt memory receipt =  zkMptVerifier.validateMPT(proof);
        require(receipt.state == 1, "Transaction Failure");
        count += 1;
    }
}