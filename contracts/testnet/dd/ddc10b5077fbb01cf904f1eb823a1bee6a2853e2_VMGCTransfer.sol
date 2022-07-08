// SPDX-License-Identifier: MIT

pragma solidity <=0.8.0;

import "./Ownable.sol";
import "./IERC20.sol";

/*
    In the game, we need to transfer 1 token to player's wallet if they get 300 points.
    So we need to create this contract.
 */

contract VMGCTransfer is Ownable {

    IERC20 VMGCAddress;

    constructor(IERC20 _VMGCAddress) public {
        VMGCAddress = _VMGCAddress;
        _transferOwnership(_msgSender());
    }

    function TransferVMGC(address ownerAccount, address playerAccount, uint playerAmount) public {
        require(playerAmount >= 300, "The amount is not enough to claim.");
        VMGCAddress.transferFrom(ownerAccount, playerAccount, 1);
    }

}