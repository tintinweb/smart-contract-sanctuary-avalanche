/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;


contract UnsafeV1 {

    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address payable immutable ownerAddress;
    
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address payable _owner) {
        ownerAddress = _owner;
    }
    event avaxForwarded(address sender, address ownerAddress, uint256 value);

    function transfer(uint256 _value) external {
        ownerAddress.transfer(_value);

        emit avaxForwarded(msg.sender, address(this), _value);
    }

    receive() external payable {
        ownerAddress.transfer(msg.value);
    }

}