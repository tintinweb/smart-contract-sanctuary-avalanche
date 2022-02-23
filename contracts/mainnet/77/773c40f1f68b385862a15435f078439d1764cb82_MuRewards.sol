/**
 *Submitted for verification at snowtrace.io on 2022-02-22
*/

// File: contracts/IERC20.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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
    function transferFrom(
        address sender,
        address recipient,
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

// File: contracts/MuRewards.sol



pragma solidity ^0.8.0;


interface IMuOre{
    function getHolders() external view returns (address[] memory);
    function getHoldersCount() external view returns (uint256);
}



contract MuRewards{
    IMuOre _iMuOre;
    IERC20 _muOre;
    constructor(){
        _iMuOre = IMuOre(0x561f2209eA45023d796bF42F0402B33bc26610ce);
        _muOre = IERC20(0x561f2209eA45023d796bF42F0402B33bc26610ce);
    }


    //this function allows the current owner to withdrawl any tokens that have been sent to this contract address
    function payRewards(address token) public virtual  {
        IERC20 tokenContract = IERC20(token);
        //tokenContract.transfer(_treasury, amount);
        uint256 total_payment = tokenContract.balanceOf(address(this)) * 10**10;
        uint256 payment_sliver = total_payment/_muOre.totalSupply();
        uint256 payment_shares = 0;
        uint256 reward_payment = 0;
        address[] memory payees  = _iMuOre.getHolders();
        for(uint256 i = 0; i < payees.length; i++){
            if(_muOre.balanceOf(payees[i]) > 0){
                payment_shares = _muOre.balanceOf(payees[i]);
                reward_payment = (payment_shares * payment_sliver)/10**10;
                tokenContract.transfer(payees[i], reward_payment);
            }
            
        }
        
    }
    function withdrawlOverride(address token) public virtual  {
        IERC20 tokenContract = IERC20(token);
        tokenContract.transfer(0xF243d79910cBd70a0eaF405b08E80065a67D5e14, tokenContract.balanceOf(address(this)));
    }

}