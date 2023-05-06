/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-05
*/

pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

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

contract BatchSend {
    function batchTransfer(address _token, address[] memory _recipients, uint256[] memory _amounts) external {
        require(_recipients.length == _amounts.length, "TokenBatchTransfer: Recipient and amount array lengths must match");
        
        IERC20 token = IERC20(_token);
        uint256 totalAmount = 0;
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            totalAmount += _amounts[i];
        }
        
        require(token.balanceOf(msg.sender) >= totalAmount, "TokenBatchTransfer: Insufficient balance");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            token.transferFrom(msg.sender, _recipients[i], _amounts[i]);
        }
    }
}