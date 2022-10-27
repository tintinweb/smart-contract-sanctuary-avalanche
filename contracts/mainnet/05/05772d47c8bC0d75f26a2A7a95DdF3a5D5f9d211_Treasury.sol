//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";

contract Treasury {
    // Fate Token
    address public fateToken;
    address public owner;

    constructor(address _fateToken) {
        fateToken = _fateToken;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        owner = newOwner;
    }

    function transferFateToken(address _to, uint256 _amount) public onlyOwner {
        IERC20(fateToken).transfer(_to, _amount);
    }

    function airDrop(address[] memory _to, uint256[] memory _amount) public onlyOwner {
        require(_to.length == _amount.length, "Invalid array length");
        for (uint256 i = 0; i < _to.length; i++) {
            IERC20(fateToken).transfer(_to[i], _amount[i]);
        }
    }

    // set the fate token address
    function setFateToken(address _fateToken) public onlyOwner {
        fateToken = _fateToken;
    }

    // receive ether
    receive() external payable {}

    // withdraw ether
    function withdrawEther(uint256 _amount) public onlyOwner {
        // transfer ether to owner
        payable(owner).transfer(_amount);
    }

    // withdraw token
    function withdrawToken(address _tokenAddress, uint256 _amount)
        public
        onlyOwner
    {
        IERC20(_tokenAddress).transfer(owner, _amount);
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