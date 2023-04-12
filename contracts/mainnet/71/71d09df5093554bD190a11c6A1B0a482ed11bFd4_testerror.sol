/**
 *Submitted for verification at snowtrace.io on 2023-04-12
*/

pragma solidity 0.8.7;

/**
 * Library containing utility functions for Verifies a EIP712 signature
 */
contract testerror {
    error E1();
    
    function verify(
        address owner
    ) external {
        if(owner != address(0x0000000000000000000000000000000000000000)) revert E1();
    }

    function verifyaTEST(
        address owner
    ) external {
        require(owner == address(0x0000000000000000000000000000000000000000), "E1");
    }

    function verifyaT(
        address owner
    ) external pure {
        address adr = owner;
        require(adr == address(0x0000000000000000000000000000000000000000), "E1");
    }
}