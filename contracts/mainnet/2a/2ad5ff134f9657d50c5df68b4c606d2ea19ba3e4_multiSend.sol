/**
 *Submitted for verification at snowtrace.io on 2022-03-30
*/

pragma solidity ^0.8.13;

interface IERC20 {
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

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

contract multiSend{

    constructor(){}

    function sum(uint[] memory amounts) pure private returns (uint retVal) {
        // the value of message should be exact of total amounts
        uint totalAmnt = 0;
        
        for (uint i=0; i < amounts.length; i++) {
            totalAmnt += amounts[i];
        }
        
        return totalAmnt;
    }

    function multisendAVAX(address payable[] memory addresses, uint[] memory amounts) payable external {
        require(addresses.length == amounts.length, "The length of two array should be the same");
        require(sum(amounts) == msg.value, "AVAX to be distributed not the same as AVAX sent");

        for(uint i=0; i<addresses.length; i++){
            addresses[i].transfer(amounts[i]);
        }

    }

    function multisend(address token, address payable[] memory addresses, uint[] memory amounts) external {
        require(addresses.length == amounts.length, "The length of two array should be the same");

        IERC20 erc20 = IERC20(token);

        for(uint i=0; i<addresses.length; i++){
            erc20.transferFrom(msg.sender, addresses[i], amounts[i]);
        }
    }
}