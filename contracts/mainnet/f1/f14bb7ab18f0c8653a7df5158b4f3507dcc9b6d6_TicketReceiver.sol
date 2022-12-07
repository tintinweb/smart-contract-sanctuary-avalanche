/**
 *Submitted for verification at snowtrace.io on 2022-12-06
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

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
pragma solidity 0.8.14;

interface IBurnable {
    function burn(uint amount) external;
}

interface IXCircle {
    function mint(uint amount) external;
}

interface IOwned {
    function getOwner() external view returns (address);
}

contract TicketReceiver {

    // Constant Contracts
    address public constant xCircle = 0x2dc3Bb328000553D1D64ec1BEF00572F62B5Ec7C;
    address public constant circle = 0xaba658AB5FFA292e3DF464dE5cB141c7de83DB6D;
    address public constant cbond = 0x18C527B5c00F2Eb6a3fa929ae8689769d2ceC943;

    address public prizePool;

    modifier onlyOwner() {
        require(
            msg.sender == IOwned(prizePool).getOwner(),
            'Only Owner'
        );
        _;
    }

    constructor(address prizePool_) {
        prizePool = prizePool_;
    }

    function withdraw(address token) external onlyOwner {
        IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
    }

    function setPrizePool(address newPool) external onlyOwner {
        prizePool = newPool;
    }

    function trigger() external {

        // burn all cbond in contract
        uint256 cbondbal = IERC20(cbond).balanceOf(address(this));
        if (cbondbal > 0) {
            IBurnable(cbond).burn(cbondbal);
        }
        
        // convert circle into xCircle and add to the prize pool
        uint256 circlebal = IERC20(circle).balanceOf(address(this));
        if (circlebal > 0) {
            IERC20(circle).approve(xCircle, circlebal);
            IXCircle(xCircle).mint(circlebal);
            IERC20(xCircle).transfer(prizePool, IERC20(xCircle).balanceOf(address(this)));
        }
    }
}