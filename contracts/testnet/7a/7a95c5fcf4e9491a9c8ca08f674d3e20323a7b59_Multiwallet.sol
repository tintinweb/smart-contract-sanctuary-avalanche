/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)
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

contract Multiwallet {
    address private _owner;
    string public _version = "v2022.10-1";

    enum ResultEnum {
        Success,
        OtherReason,
        NotEnoughBalance,
        NotEnoughAllowence
    }
    event ChargeResult(ResultEnum result, address indexed customer, uint256 amount, string indexed subId);

    constructor() {
        _owner = msg.sender;
    }

    /**
    * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
    * @dev Returns versions of contract.
     */
    function version() public view virtual returns (string memory) {
        return _version;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
    * @dev Check is address can be charged for exact amount of tokens.
    * Checks are: allowence is more than amount; allowence is more than balance
     */
    function canBeCharged(
        address tokenAddress,
        address customerAddress,
        uint amount
    ) public view virtual returns (ResultEnum) {
        IERC20 erc20Contract = IERC20(tokenAddress);

        if (erc20Contract.allowance(customerAddress, address(this)) <= amount) {
            return ResultEnum.NotEnoughAllowence;
        } else if (erc20Contract.balanceOf(customerAddress) <= amount) {
            return ResultEnum.NotEnoughBalance;
        }
        return ResultEnum.Success;
    }

    function charge(
        address tokenAddress,
        address customerAddress,
        address merchantAddress,
        uint amount,
        string memory subId
    ) public onlyOwner {
        IERC20 erc20Contract = IERC20(tokenAddress);
        ResultEnum canBeChargedResult = canBeCharged(tokenAddress, customerAddress, amount);

        if (canBeChargedResult == ResultEnum.Success) {
            erc20Contract.transferFrom(customerAddress, merchantAddress, amount);
        }

        emit ChargeResult(canBeChargedResult, customerAddress, amount, subId);
    }

    function chargeMany(
        address[] memory tokenAddresses,
        address[] memory customerAddresses,
        address[] memory merchantAddresses,
        uint[] memory amounts,
        string[] memory subIds
    ) public onlyOwner {
        uint len = tokenAddresses.length;
        require(
            (customerAddresses.length == len) ==
            (merchantAddresses.length == len) ==
            (amounts.length == len) ==
            (subIds.length == len), "invalid length"
        );
        uint i = 0;

        for (i; i < len; i++) {
            charge(tokenAddresses[i], customerAddresses[i], merchantAddresses[i], amounts[i], subIds[i]);
        }
    }
}