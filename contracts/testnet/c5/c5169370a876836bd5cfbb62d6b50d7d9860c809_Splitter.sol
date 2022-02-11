/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-01
*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

contract Splitter {

    address[] public wallet ;
    uint16[] public sharePercentage ;

    constructor(
    address[] memory _wallet,
    uint16[] memory _sharePercentage
    ) {
        require(_wallet.length == _sharePercentage.length, "Not the same number of wallet and sharePercentage");
        wallet = _wallet;
        sharePercentage = _sharePercentage;
    }


function withdraw() external {
    uint256 startingBalance = address(this).balance;
    uint256 share;
    for (uint256 i = 0; i < wallet.length; i++) {
        share = startingBalance * sharePercentage[i] /100;
        payable(wallet[i]).transfer(share);
    }
  }
}