/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-05
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transferFrom(address from, address to, uint amount) external returns (bool);
}

contract BatchTransfer {
    function batchTransfer(address tokenAddr, address[] calldata recipients, uint amount) external {
        require(tokenAddr != address(0), "Invalid token address");
        require(recipients.length > 0, "Invalid recipient list");

        IERC20 token = IERC20(tokenAddr);
        uint totalAmount = amount * recipients.length;

        require(token.balanceOf(msg.sender) >= totalAmount, "Insufficient balance");

        for (uint i = 0; i < recipients.length; i++) {
            require(token.transferFrom(msg.sender, recipients[i], amount), "Transfer failed");
        }
    }
}