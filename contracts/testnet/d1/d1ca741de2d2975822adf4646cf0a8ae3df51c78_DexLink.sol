/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IRefererralStorage {
    function setTraderReferralCodeByUser(bytes32) external;
}

contract DexLink {
    address public owner;
    bytes32 public constant code = 0x4b544b3030000000000000000000000000000000000000000000000000000000;

    constructor(address owner_, address referralStorage_) {
        owner = owner_;
        IRefererralStorage(referralStorage_).setTraderReferralCodeByUser(code);
    }
}