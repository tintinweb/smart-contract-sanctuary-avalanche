/**
 *Submitted for verification at snowtrace.io on 2023-02-10
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/**
 * @title RepayResolver
 * @dev Implements a smart contract that gets the price from an address and has a function that returns whether the price is above or below a certain value
 */
contract Resolver { 

    bytes resolve;
    

    function CheckResolver() public returns(bool) {
        address resolverAddress = 0xA3B6C009C6FCd4F2915c9f13bada44736f0cE919;
        (bool success, bytes memory data) = resolverAddress.call(
            abi.encodeWithSignature("isAboveThreshold()")
        );
        resolve = data;
        return success;
    }

    function viewResolve() public view returns (bool resolved) {
        resolved = abi.decode(resolve, (bool));
        return resolved;
    }
}