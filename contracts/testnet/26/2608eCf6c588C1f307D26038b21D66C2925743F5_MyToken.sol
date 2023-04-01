/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract MyToken {
    string public name = "My TOken";

    function balanceOf(address _address) public pure returns(uint) {
		return 1e18;
	}
}