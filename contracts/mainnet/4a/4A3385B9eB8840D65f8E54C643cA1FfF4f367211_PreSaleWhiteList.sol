//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";

contract PreSaleWhiteList {
    address public owner;
    mapping(address => bool) public whiteList;
    IERC20 public tokenAddress;
    IERC20 public stableCoinAddress;
    uint256 public tokenPrice; // 1 token = ? stable coin (6 decimals)
    bool whiteListRestrict = true;
    bool presaleEnable = false;

    constructor(
        address _tokenAddress,
        address _stableCoinAddress,
        uint256 _tokenPrice
    ) {
        owner = msg.sender;
        tokenAddress = IERC20(_tokenAddress);
        stableCoinAddress = IERC20(_stableCoinAddress);
        tokenPrice = _tokenPrice;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    // transfer ownership
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    function addToWhiteList(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteList[_addresses[i]] = true;
        }
    }

    function removeFromWhiteList(address[] memory _addresses) public onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whiteList[_addresses[i]] = false;
        }
    }

    // set the token address
    function setTokenAddress(address _tokenAddress) public onlyOwner {
        tokenAddress = IERC20(_tokenAddress);
    }

    // set the stable coin address
    function setStableCoinAddress(address _stableCoinAddress) public onlyOwner {
        stableCoinAddress = IERC20(_stableCoinAddress);
    }

    // set the token price
    function setTokenPrice(uint256 _tokenPrice) public onlyOwner {
        tokenPrice = _tokenPrice;
    }

    // set pre sale status
    function setPreSaleStatus(bool status) public onlyOwner {
        presaleEnable = status;
    }

    // set whitelist status
    function setWhiteListStatus(bool status) public onlyOwner {
        presaleEnable = status;
    }

    // buy tokens
    function buyTokens(uint256 _amount) public {
        require(
            presaleEnable,
            "Sale is not active. You can not buy currently."
        );
        if (whiteListRestrict)
            require(whiteList[msg.sender], "You are not in the whitelist");
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= _amount,
            "Not enough tokens in the contract"
        );
        // deduct the stable coin from the user
        require(
            stableCoinAddress.transferFrom(msg.sender, address(this),( _amount * tokenPrice) / 1e18),
            "Transfer failed"
        );
        IERC20(tokenAddress).transfer(msg.sender, _amount);
    }

    // withdraw stable coin
    function withdrawStableCoin(uint256 _amount) public onlyOwner {
        require(
            stableCoinAddress.balanceOf(address(this)) >= _amount,
            "Not enough stable coin in the contract"
        );
        stableCoinAddress.transfer(msg.sender, _amount);
    }

    // withdraw tokens
    function withdrawTokens(uint256 _amount) public onlyOwner {
        require(
            IERC20(tokenAddress).balanceOf(address(this)) >= _amount,
            "Not enough tokens in the contract"
        );
        IERC20(tokenAddress).transfer(msg.sender, _amount);
    }

    // withdraw all tokens
    function withdrawAllTokens() public onlyOwner {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(msg.sender, balance);
    }

    // withdraw all stable coin
    function withdrawAllStableCoin() public onlyOwner {
        uint256 balance = stableCoinAddress.balanceOf(address(this));
        stableCoinAddress.transfer(msg.sender, balance);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
}