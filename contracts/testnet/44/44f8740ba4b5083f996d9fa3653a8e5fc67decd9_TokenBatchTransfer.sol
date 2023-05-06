/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-05
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract TokenBatchTransfer {
    function approve(address token, address spender, uint256 amount) external {
        IERC20 erc20 = IERC20(token);
        erc20.approve(spender, amount);
    }

    function batchTransfer(address token, address[] memory recipients, uint256 amount) external {
        require(recipients.length > 0, "No recipients specified");
        IERC20 erc20 = IERC20(token);
        uint256 totalAmount = amount * recipients.length;
        require(erc20.balanceOf(msg.sender) >= totalAmount, "Insufficient balance");
       
        for (uint256 i = 0; i < recipients.length; i++) {
            erc20.transferFrom(msg.sender, recipients[i], amount);
        }
    }
}