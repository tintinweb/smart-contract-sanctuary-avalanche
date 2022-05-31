/**
 *Submitted for verification at snowtrace.io on 2022-05-31
*/

//SPDX-License-Identifier: MIT
//🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿🧿

pragma solidity ^0.8.14;

// bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)
bytes32 constant ERC1967_CODE_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

address constant DAO_KASASI_VO = 0xC7d18E3C9261De4b5e4d630AeBeeBB22587F6f28;

contract DAOKasasiProxy {
    constructor() {
        assembly {
            sstore(ERC1967_CODE_SLOT, DAO_KASASI_VO)
        }
    }

    fallback() external payable {
        assembly {
            let codeAddress := sload(ERC1967_CODE_SLOT)
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), codeAddress, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}