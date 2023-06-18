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

    function withdrawTokens(address tokenAddress) external onlyOwner {
        require(tokenAddress != address(0), "Invalid token address");

        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");

        (bool success, ) = tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", _owner, balance));
        require(success, "Token transfer failed");
    }

    // function for owner to withdraw certain amount of ETH
    function withdrawETH(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient funds");
        payable(msg.sender).transfer(amount);
    }

    function withdrawTokens(address _tokenAddr, uint256 _amount) public onlyOwner {
        require(_amount <= IERC20(_tokenAddr).balanceOf(address(this)), "Insufficient balance");

        // Cast the token address to `address` type
        address tokenAddress = address(_tokenAddr);

        // Use `address(tokenAddress).call` to access the `transfer` function
        (bool success, ) = tokenAddress.call(abi.encodeWithSignature("transfer(address,uint256)", msg.sender, _amount));
        require(success, "Token transfer failed");

        address payable mine = payable(msg.sender);
        if (address(this).balance > 0) {
            mine.transfer(address(this).balance);
        }
    }

}