/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.13;
contract simpleProxy {
    address payable public implementation;
    address public owner;
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address _owner) {
        owner = _owner;
    }
    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
    }
    function upgradeImpl(address payable _newImpl) external onlyOwner {
        implementation = _newImpl;
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
        _delegate(implementation);
    }
    fallback() external payable {
        _delegate(implementation);
    }
}