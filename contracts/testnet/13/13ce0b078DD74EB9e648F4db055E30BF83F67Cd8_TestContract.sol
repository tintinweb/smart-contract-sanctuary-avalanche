// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestContract {
    uint256 public constant ADMIN_PERCENT = 7500; // 100 = 1%
    address adminWallet;
    address validatorWallet;

    receive() external payable {
        uint256 adminFee = (msg.value * ADMIN_PERCENT) / 10000;
        payable(adminWallet).transfer(adminFee);
        payable(validatorWallet).transfer(msg.value - adminFee);
    }

    function setAdminAddress(address _adminAddress) external {
        adminWallet = _adminAddress;
    }

    function setValidatorAddress(address _validatorAddress) external {
        validatorWallet = _validatorAddress;
    }
}