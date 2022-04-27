// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

contract Deployer {
    function deploy(
        bytes memory code,
        bytes32 salt
    ) public returns (
        address addr
    ) {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {revert(0, 0)}
        }
    }

    function deploy(
        bytes memory code,
        bytes32 salt,
        bytes memory initdata
    ) public returns (
        address addr
    ) {
        assembly {
            addr := create2(0, add(code, 0x20), mload(code), salt)
            if iszero(extcodesize(addr)) {revert(0, 0)}
        }

        (bool success,) = addr.call(initdata);

        require(success);
    }
}