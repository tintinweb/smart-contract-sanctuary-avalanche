pragma solidity ^0.6.9;

import "../Utils/SafeMathPlus.sol";
import "../Utils/Owned.sol";
import "../../interfaces/IERC20.sol";

// SPDX-License-Identifier: GPL-3.0

// ----------------------------------------------------------------------------
// ApproveAndCall Fallback
// NOTE for contracts implementing this interface:
// 1. An error must be thrown if there are errors executing `transferFrom(...)`
// 2. The calling token contract must be checked to prevent malicious behaviour
// ----------------------------------------------------------------------------
interface ApproveAndCallFallback {
  function receiveApproval(
    address from,
    uint256 tokens,
    address token,
    bytes memory data
  ) external;
}

// ----------------------------------------------------------------------------
// Token Interface = ERC20 + symbol + name + decimals + approveAndCall
// ----------------------------------------------------------------------------
interface TokenInterface is IERC20 {
  function approveAndCall(
    address spender,
    uint256 tokens,
    bytes memory data
  ) external returns (bool success);
}

// ----------------------------------------------------------------------------
// FixedSupplyToken 👊 = ERC20 + symbol + name + decimals + approveAndCall
// ----------------------------------------------------------------------------
contract FixedSupplyToken is TokenInterface, Owned {
  using SafeMathPlus for uint256;

  string _symbol;
  string _name;
  uint8 _decimals;
  uint256 _totalSupply;

  mapping(address => uint256) balances;
  mapping(address => mapping(address => uint256)) allowed;

  function init(
    address tokenOwner,
    string memory symbol,
    string memory name,
    uint8 decimals,
    uint256 fixedSupply
  ) public {
    _initOwned(tokenOwner);
    _symbol = symbol;
    _name = name;
    _decimals = decimals;
    _totalSupply = fixedSupply;
    balances[tokenOwner] = _totalSupply;
    emit Transfer(address(0), tokenOwner, _totalSupply);
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function name() public view override returns (string memory) {
    return _name;
  }

  function decimals() public view override returns (uint8) {
    return _decimals;
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply.sub(balances[address(0)]);
  }

  function balanceOf(address tokenOwner)
    public
    view
    override
    returns (uint256 balance)
  {
    return balances[tokenOwner];
  }

  function transfer(address to, uint256 tokens)
    public
    override
    returns (bool success)
  {
    balances[msg.sender] = balances[msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(msg.sender, to, tokens);
    return true;
  }

  function approve(address spender, uint256 tokens)
    public
    override
    returns (bool success)
  {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    return true;
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokens
  ) public override returns (bool success) {
    balances[from] = balances[from].sub(tokens);
    allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
    balances[to] = balances[to].add(tokens);
    emit Transfer(from, to, tokens);
    return true;
  }

  function allowance(address tokenOwner, address spender)
    public
    view
    override
    returns (uint256 remaining)
  {
    return allowed[tokenOwner][spender];
  }

  // NOTE Only use this call with a trusted spender contract
  function approveAndCall(
    address spender,
    uint256 tokens,
    bytes memory data
  ) public override returns (bool success) {
    allowed[msg.sender][spender] = tokens;
    emit Approval(msg.sender, spender, tokens);
    ApproveAndCallFallback(spender).receiveApproval(
      msg.sender,
      tokens,
      address(this),
      data
    );
    return true;
  }

  receive() external payable {
    revert();
  }
}

// ----------------------------------------------------------------------------
// BokkyPooBah's Fixed Supply Token 👊 Factory
//
// Notes:
//   * The `newContractAddress` deprecation is just advisory
//   * A fee equal to or above `minimumFee` must be sent with the
//   `deployTokenContract(...)` call
//
// Execute `deployTokenContract(...)` with the following parameters to deploy
// your very own FixedSupplyToken contract:
//   symbol         symbol
//   name           name
//   decimals       number of decimal places for the token contract
//   totalSupply    the fixed token total supply
//
// For example, deploying a FixedSupplyToken contract with a `totalSupply`
// of 1,000.000000000000000000 tokens:
//   symbol         "ME"
//   name           "My Token"
//   decimals       18
//   initialSupply  10000000000000000000000 = 1,000.000000000000000000 tokens
//
// The TokenDeployed() event is logged with the following parameters:
//   owner          the account that execute this transaction
//   token          the newly deployed FixedSupplyToken address
//   symbol         symbol
//   name           name
//   decimals       number of decimal places for the token contract
//   totalSupply    the fixed token total supply
// ----------------------------------------------------------------------------
contract BokkyPooBahsFixedSupplyTokenFactory is Owned {
  using SafeMathPlus for uint256;

  address public newAddress;
  uint256 public minimumFee = 0.1 ether;
  mapping(address => bool) public isChild;
  address[] public children;

  event FactoryDeprecated(address _newAddress);
  event MinimumFeeUpdated(uint256 oldFee, uint256 newFee);
  event TokenDeployed(
    address indexed owner,
    address indexed token,
    string symbol,
    string name,
    uint8 decimals,
    uint256 totalSupply
  );

  constructor() public {
    _initOwned(msg.sender);
  }

  function numberOfChildren() public view returns (uint256) {
    return children.length;
  }

  function deprecateFactory(address _newAddress) public {
    require(isOwner());
    require(newAddress == address(0));
    emit FactoryDeprecated(_newAddress);
    newAddress = _newAddress;
  }

  function setMinimumFee(uint256 _minimumFee) public {
    require(isOwner());
    emit MinimumFeeUpdated(minimumFee, _minimumFee);
    minimumFee = _minimumFee;
  }

  function deployTokenContract(
    string memory symbol,
    string memory name,
    uint8 decimals,
    uint256 totalSupply
  ) public payable returns (FixedSupplyToken token) {
    require(msg.value >= minimumFee);
    require(decimals <= 27);
    require(totalSupply > 0);
    token = new FixedSupplyToken();
    token.init(msg.sender, symbol, name, decimals, totalSupply);
    isChild[address(token)] = true;
    children.push(address(token));
    emit TokenDeployed(
      owner(),
      address(token),
      symbol,
      name,
      decimals,
      totalSupply
    );
    if (msg.value > 0) {
      payable(owner()).transfer(msg.value);
    }
  }

  receive() external payable {
    revert();
  }
}

pragma solidity ^0.6.9;


import "../../interfaces/IERC20.sol";


contract Owned {

    address private mOwner;   
    bool private initialised;    
    address public newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function _initOwned(address _owner) internal {
        require(!initialised);
        mOwner = address(uint160(_owner));
        initialised = true;
        emit OwnershipTransferred(address(0), mOwner);
    }

    function owner() public view returns (address) {
        return mOwner;
    }
    function isOwner() public view returns (bool) {
        return msg.sender == mOwner;
    }

    function transferOwnership(address _newOwner) public {
        require(isOwner());
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(mOwner, newOwner);
        mOwner = address(uint160(newOwner));
        newOwner = address(0);
    }
    function recoverTokens(address token, uint tokens) public {
        require(isOwner());
        if (token == address(0)) {
            payable(mOwner).transfer((tokens == 0 ? address(this).balance : tokens));
        } else {
            IERC20(token).transfer(mOwner, tokens == 0 ? IERC20(token).balanceOf(address(this)) : tokens);
        }
    }
}

pragma solidity ^0.6.9;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts
 */
library SafeMathPlus {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
    function max(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a >= b ? a : b;
    }
    function min(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a <= b ? a : b;
    }
    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

pragma solidity ^0.6.2;
// SPDX-License-Identifier: UNLICENSED


interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}