/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract goth_v2_exchange {

    IERC20 public _oldGoth;
    IERC20 public _newGoth;
    address public _treasury;
    address public _burnAddress;

    constructor (IERC20 oldGoth_, IERC20 newGoth_, address treasury_, address burnAddress_)
    {
        _oldGoth = oldGoth_;
        _newGoth = newGoth_;
        _treasury = treasury_;
        _burnAddress = burnAddress_;
    }

    function oldGothAddress () external view returns (address)
    {
        return address(_oldGoth);
    }

    function newGothAddress () external view returns (address)
    {
        return address(_newGoth);
    }

    function treasuryAddress () external view returns (address)
    {
        return _treasury;
    }

    function burnAddress () external view returns (address)
    {
        return _burnAddress;
    }

    function _swapForNewGoth (address sender, uint256 amount) private
    {
        _oldGoth.transferFrom(sender, _burnAddress, amount);
        _newGoth.transferFrom(_treasury, sender, amount);
    }

    function swapForNewGoth (uint256 amount) external returns (bool)
    {
        require(_oldGoth.balanceOf(msg.sender) >= amount, "old goth balance too low");
        require(_oldGoth.allowance(msg.sender, address(this)) >= amount, "allowance too low");
        _swapForNewGoth(msg.sender, amount);
        return true;
    }
}