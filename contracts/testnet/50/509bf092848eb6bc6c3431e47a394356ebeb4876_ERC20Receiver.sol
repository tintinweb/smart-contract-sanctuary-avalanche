/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-17
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract ERC20Receiver {
    address private _owner;

    event TokensReceived(address indexed token, address indexed sender, uint256 amount);

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Only contract owner can call this function");
        _;
    }

    function transferAnyERC20Token(address tokenAddress, address sender, uint256 amount) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");
        require(amount > 0, "Amount must be greater than zero");

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(sender) >= amount, "Insufficient balance");

        bool success = token.transferFrom(sender, address(this), amount);
        require(success, "Token transfer failed");

        emit TokensReceived(tokenAddress, sender, amount);
    }

    function withdrawTokens(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");

        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");

        (bool success, ) = tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", _owner, balance));
        require(success, "Token transfer failed");
    }


}