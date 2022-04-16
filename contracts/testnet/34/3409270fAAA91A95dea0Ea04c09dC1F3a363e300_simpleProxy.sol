/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

contract storageSoln {
    address payable public impl;
    address public owner;
}

contract simpleProxy is storageSoln {
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _owner) {
        owner = _owner;
    }

    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
    }

    function upgradeImpl(address payable _newImpl) external onlyOwner {
        impl = _newImpl;
     }


    function _delegate(address imp) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), imp, 0, calldatasize(), 0, 0)

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
    receive() external payable {
        _delegate(impl);
    }

    fallback() external payable {
        address payable addr = impl;
        _delegate(addr);
    }
}