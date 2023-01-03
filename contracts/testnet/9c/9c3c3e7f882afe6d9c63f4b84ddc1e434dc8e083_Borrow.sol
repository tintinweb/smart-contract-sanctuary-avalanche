/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-02
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IAMM {

  function floorPrice() external view returns (uint256);
  function initialize(uint256 _fsl, uint256 _psl) external;

}

interface IPorridge {
  
  function getStaked(address _user) external view returns (uint256);
  function stake(uint256 _amount) external;
  function unstake(uint256 _amount) external returns (uint256 _yield);
  function claim() external returns (uint256 _yield);
  function realize(uint256 _amount) external;

}

contract Borrow {

  IAMM iamm;
  IPorridge iporridge;
  IERC20 honey;
  address public adminAddress;
  address public ammAddress;
  address public locksAddress;
  address public porridgeAddress;

  mapping(address => uint256) public lockedLocks;
  mapping(address => uint256) public borrowedHoney;

  constructor(address _ammAddress, address _locksAddress, address _adminAddress) {
    iamm = IAMM(_ammAddress);
    adminAddress = _adminAddress;
    locksAddress = _locksAddress;
    ammAddress = _ammAddress;
  }

  modifier onlyAdmin() {
    require(msg.sender == adminAddress, "not admin");
    _;
  }

  function getLocked(address _user) external view returns (uint256) {
    return lockedLocks[_user];
  }

  function getBorrowed(address _user) external view returns (uint256) {
    return borrowedHoney[_user];
  }

  function borrow(uint256 _amount) external returns (uint256) {
    require(_amount > 0, "cannot borrow zero");
    uint256 _floorPrice = iamm.floorPrice();
    uint256 _stakedLocks = iporridge.getStaked(msg.sender);
    require((_floorPrice * _stakedLocks) / (1e18) >= _amount, "insufficient borrow limit");
    lockedLocks[msg.sender] += (_amount * (1e18)) / _floorPrice;
    borrowedHoney[msg.sender] += _amount;
    uint256 _fee = (_amount / 100) * 3;
    IERC20(locksAddress).transferFrom(porridgeAddress, address(this), (_amount * (1e18)) / _floorPrice);
    honey.transferFrom(ammAddress, msg.sender, _amount - _fee);
    honey.transferFrom(ammAddress, adminAddress, _fee);
    return _amount - _fee;
  }

  function repay(uint256 _amount) external {
    require(_amount > 0, "cannot repay zero");
    require(borrowedHoney[msg.sender] >= _amount, "repaying too much");
    uint256 _repaidLocks = (((_amount * 1e18) / borrowedHoney[msg.sender]) * lockedLocks[msg.sender]) / 1e18;
    lockedLocks[msg.sender] -= _repaidLocks;
    borrowedHoney[msg.sender] -= _amount;
    honey.transferFrom(msg.sender, ammAddress, _amount);
    IERC20(locksAddress).transfer(porridgeAddress, _repaidLocks);
  }

  function setPorridge(address _porridgeAddress) public onlyAdmin {
    iporridge = IPorridge(_porridgeAddress);
    porridgeAddress = _porridgeAddress;
  }

  function setHoneyAddress(address _honeyAddress) public onlyAdmin {
    honey = IERC20(_honeyAddress);
  }

}