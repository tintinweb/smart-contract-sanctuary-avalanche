//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Escrow.sol";

contract EscrowFactory {
    address[] escrows;

    function createEscrowContract(IERC20 _token, uint _fee) public {
      Escrow newEscrow = new Escrow(_token, _fee);            
      escrows.push(address(newEscrow));   
    }

    function createBatchEscrowContracts(IERC20[] memory _tokens, uint[] memory _fees) public {
        for (uint i=0; i<_tokens.length; i++) {
            Escrow newEscrow = new Escrow(_tokens[i], _fees[i]);            
            escrows.push(address(newEscrow));
        }
    }

    function getDeployedEscrowContracts() public view returns (address[] memory) {
      return escrows;
   }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow {

  address payable public owner;
  uint public fee;
  uint collectedFee;
  IERC20 token;

  event Deposited(address indexed payee, address tokenAddress, uint256 amount);
  event Withdrawn(address indexed payee, address tokenAddress, uint256 amount);

  // payee address => token address => amount
  mapping(address => mapping(address => uint256)) public deposits;

  // payee address => token address => expiration time
  mapping(address => mapping(address => uint256)) public expirations;

  constructor(IERC20 _token, uint _fee) {
      owner = payable(msg.sender);
      token = _token;
      fee = _fee;
  }

  modifier requiresFee() {
      require(msg.value >= fee, "Not enough value.");
        _;
  }

  modifier onlyOwner() {
      require(msg.sender == owner, "Must be an owner.");
        _;
  }

  function transferFee() public onlyOwner {
      token.approve(owner, collectedFee);
      token.transfer(owner, collectedFee);
      collectedFee = 0;
  }

  function deposit(address _payee, uint256 _amount, uint256 _expiration) public requiresFee payable {
      token.transferFrom(msg.sender, address(this), _amount + fee);
      deposits[_payee][address(token)] += _amount;
      expirations[_payee][address(token)] = block.timestamp + _expiration;
      collectedFee += fee;
      emit Deposited(_payee, address(token), _amount);
  }

  function withdraw(address payable _payee) public {
      require(block.timestamp > expirations[_payee][address(token)], "The payment is still in escrow.");
      uint256 payment = deposits[_payee][address(token)];
      deposits[_payee][address(token)] = 0;
      token.approve(_payee, payment);
      require(token.transfer(_payee, payment));
      emit Withdrawn(_payee, address(token), payment);
  }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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