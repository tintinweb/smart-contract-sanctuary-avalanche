/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-02
*/

pragma solidity ^0.8;

// SPDX-License-Identifier: UNLICENSED


interface IERC721 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract BulkTransferer {
    IERC721 collection;

    constructor (address _collection) {
        collection = IERC721(_collection);
    }

    function bulkTransfer(address _from, address _to, uint256[] memory _tokenIds) external {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            collection.transferFrom(_from, _to, _tokenIds[i]);
        }
    }
}