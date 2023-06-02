/**
 *Submitted for verification at snowtrace.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}



pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}



contract TokenSale {
    address private owner;
    uint private tokenPrice;
    uint private tokenDecimal;
    uint private tokenSupply;
    IERC20 private usdc;
    IERC20Metadata private token;
    address private walletAddress;  // Wallet address to receive USDC
    
    event TokensPurchased(address indexed _buyer, uint _amount, uint _price);
    
    constructor(address _usdcAddress, address _tokenAddress, uint _price, address _walletAddress) {
        owner = msg.sender;
        usdc = IERC20(_usdcAddress);
        token = IERC20Metadata(_tokenAddress);
        tokenPrice = _price;
        tokenDecimal = token.decimals();
        tokenSupply = token.totalSupply();
        walletAddress = _walletAddress;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }
    
    function buyTokens(uint _amount) public {
        uint totalPrice = _amount * tokenPrice / (10 *10000000000000);
        require(totalPrice > 0, "You must purchase at least one token.");
        require(usdc.balanceOf(msg.sender) >= totalPrice, "Insufficient USDC balance.");
        usdc.transferFrom(msg.sender, address(this), totalPrice);
        token.transfer(msg.sender, _amount);
        usdc.transfer(walletAddress, totalPrice);  // Transfer USDC to wallet address
        
        emit TokensPurchased(msg.sender, _amount, totalPrice);
    }
    
    function updateTokenPrice(uint _newPrice) public onlyOwner {
        tokenPrice = _newPrice;
    }

    function getTokenPrice() public view returns (uint256) {
        return tokenPrice;
    }
    
    function withdrawUSDC() public onlyOwner {
        uint usdcBalance = usdc.balanceOf(address(this));
        require(usdcBalance > 0, "No USDC balance to withdraw.");
        
        usdc.transfer(owner, usdcBalance);
    }
    
    function withdrawTokens() public onlyOwner {
        uint tokenBalance = token.balanceOf(address(this));
        require(tokenBalance > 0, "No token balance to withdraw.");
        
        token.transfer(owner, tokenBalance);
    }

    function getUSDCAddress() public view returns (address) {
        return address(usdc);
    }

    function getTokenAddress() public view returns (address) {
        return address(token);
    }

    function getUSDCBalance() public view returns (uint256) {
        return usdc.balanceOf(address(this));
    }

    function getTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function getWalletAddress() public view returns (address) {
        return walletAddress;
    }
    
    function setWalletAddress(address _walletAddress) public onlyOwner {
        walletAddress = _walletAddress;
    }
}