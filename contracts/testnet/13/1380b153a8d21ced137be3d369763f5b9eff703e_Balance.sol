/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract Balance {
    struct BalanceTree{
        bytes32 root;
        string ipfsLink;
    }

    mapping(bytes32 => BalanceTree) public balances;

    function setBatchBalances(bytes32[] calldata assets, bytes32[] calldata roots, string[] calldata ipfsLinks) public {
        uint256 aLength = assets.length;
        uint256 rLength = roots.length;
        uint256 iLength = roots.length;

        require(aLength == rLength, "Lenght mismatch!");
        require(rLength == iLength, "Length mismatch1");

        for(uint256 i=0; i<aLength; i++) {
            BalanceTree memory tree = BalanceTree(
                roots[i],
                ipfsLinks[i]
            );
            balances[assets[i]] = tree;
        }
    }
}