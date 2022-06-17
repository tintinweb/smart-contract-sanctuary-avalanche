// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20Metadata.sol";
import "./ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract TokenDistribute {
    address public contractOwner;
    address public grantedContractOwner;

    mapping(address=>mapping(address=>uint)) public erc20Balance;  // erc20Balance[tokenAddress][owner]
    mapping(address=>uint) public nativeBalance;
    mapping(address=>uint) public distributedErc20;  // Amount of erc20Token distributed in this contract but haven't withdrew by the interns
    uint internal _distributedNative;  // Amount of eth distributed in this contract but haven't withdrew by the interns
    mapping(address=>bool) internal _registered;  

    address [] public erc20Tokens;

    modifier onlyOwner() {
      if (msg.sender != contractOwner) {
        revert("not the owner of the contract");
      }    
      _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        contractOwner = newOwner;
    }

    function grantOwnership(address newOwner) public onlyOwner {
        grantedContractOwner = newOwner;
    }

    function receiveOwnership() public {
        require(msg.sender == grantedContractOwner, "not granted the Ownership yet");
        contractOwner = msg.sender;
    }

    modifier nonZeroAddress(address address_) {
        if (address_ == address(0)) {
            revert("invalid receiver");
        }
        _;
    }

    constructor () {
        contractOwner = msg.sender;
    }

    // Anton approves Token to the contract first, then call this function to deposit Token to the contract
    function depositErc20(address tokenAddress, uint amount) public onlyOwner
    {
        ERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        if (!_registered[tokenAddress])
        {
            erc20Tokens.push(tokenAddress);
        }
    }

    function distributeErc20(address tokenAddress, address to, uint amount) public onlyOwner nonZeroAddress(to)
    {
        require(IERC20Metadata(tokenAddress).balanceOf(address(this)) >= distributedErc20[tokenAddress] + amount, "not enough token to distribute");

        distributedErc20[tokenAddress] += amount;
        erc20Balance[tokenAddress][to] += amount;
    }

    // Alternative method, should be amount array

    function batchdistributeErc20(address tokenAddress, address[] calldata to, uint[] calldata amount) public onlyOwner{        
        uint length = to.length;
        
        for (uint i=0; i<length; i++) 
        {
            distributeErc20(tokenAddress, to[i], amount[i]);
        }
    }

    // Anton transfers ETH directly to the contract first
    function distributeNative(address to, uint amount) public onlyOwner nonZeroAddress(to)
    {
        require(address(this).balance >= _distributedNative + amount, "not enough eth to distribute");
        
        _distributedNative += amount;
        nativeBalance[to] += amount;
    }

    // Alternative method 
    function batchDistributeNative(address[] calldata to, uint[] calldata amount) public onlyOwner{    
        uint length = to.length;

        for (uint i=0; i<length; i++) 
        {
            distributeNative(to[i], amount[i]);
        }
    }

    function withdrawNative(address to) public nonZeroAddress(to) 
    {        
        require(nativeBalance[to]>0, "no balance to withdraw");
        
        uint amount = nativeBalance[to];
        _distributedNative -= amount;
        nativeBalance[to] = 0;
        payable(to).transfer(amount);
    }

    function withdrawErc20(address tokenAddress, address to) public nonZeroAddress(to) 
    {                
        require(to!=address(0), "invalid receiver");
        uint amount = erc20Balance[tokenAddress][to];
        require(amount>0, "no balance to withdraw"); 

        erc20Balance[tokenAddress][to] = 0;
        distributedErc20[tokenAddress] -= amount;
        IERC20Metadata(tokenAddress).transfer(to, amount);
    }

    function withdrawAll(address to) external nonZeroAddress(to) 
    {
        uint length = erc20Tokens.length;

        for (uint i=0; i<length; i++) 
        {
            if (erc20Balance[erc20Tokens[i]][to]>0) withdrawErc20(erc20Tokens[i], to);
        } 
        if (nativeBalance[to]>0) withdrawNative(to); 
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20.sol";

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./IERC20Metadata.sol";

contract ERC20 is IERC20Metadata {
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  uint private _totalSupply;
  address public contractOwner;
  mapping(address=>uint) private balance;
  mapping(address=>mapping(address=>uint)) private _allowance;  // _allowance[owner][spender] = amount possible

  constructor (string memory name, string memory symbol, uint8 decimals, uint totalSupply) 
  {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
    _totalSupply = totalSupply;  
    contractOwner = msg.sender;  
    balance[contractOwner] = totalSupply;
  }

  function name() external view returns (string memory)
  {
    return _name;
  }

  function symbol() external view returns (string memory)
  {
    return _symbol;
  }

  function decimals() external view returns (uint8){
    return _decimals;
  }

  function totalSupply() external view returns (uint256) {
    return _totalSupply;
  }

  function balanceOf(address account) external view returns (uint256) {
    return balance[account];
  }

  function transfer(address to, uint256 amount) external returns (bool) {
    _transfer(msg.sender, to, amount);
    return true;
  }

  function allowance(address owner, address spender) external view returns (uint256) {    
    require(owner!=address(0), "invalid owner");
    require(spender!=address(0), "invalid spender");
    return _allowance[owner][spender];
  }

  function approve(address spender, uint256 amount) external returns (bool) {
    require(spender!=address(0), "invalid spender");
    _allowance[msg.sender][spender] = amount;

    emit Approval(msg.sender, spender, amount);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool) {
    
    require(_allowance[from][msg.sender] >= amount, "exceed the amount allowed");
    _transfer(from, to, amount);
    _allowance[from][msg.sender] -= amount;   

    return true;
  }

  function _transfer(address from, address to, uint amount) internal 
  {
    require(from!=address(0), "invalid sender");
    require(to!=address(0), "invalid receiver");
    require(balance[from] >= amount, "not enough money from the owner");

    balance[from] -= amount;
    balance[to] += amount;  // Hope no overflow here! Should depend on the designer

    emit Transfer(from, to, amount);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.11;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}