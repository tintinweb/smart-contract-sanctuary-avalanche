/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-23
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-22
*/
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// Sources flattened with hardhat v2.3.0 https://hardhat.org

// File @uniswap/v2-core/contracts/interfaces/[email protected]

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}


// File contracts/TestReserves_1.sol

pragma solidity ^0.8.0;
interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address account) external view returns (uint256);
    
    function transfer(address recipient, uint256 amount) external returns (bool);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function approve(address spender, uint256 amount) external returns (bool);
    
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: @openzeppelin/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
pragma solidity ^0.8.0;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: @openzeppelin/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
pragma solidity ^0.8.0;
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    constructor() {
        _transferOwnership(_msgSender());
    }
    
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
pragma solidity ^0.8.4;
abstract contract Authorizable {
  mapping(address => bool) private _authorizedAddresses;
  constructor() {
    _authorizedAddresses[msg.sender] = true;
  }
  modifier onlyAuthorized() {
    require(_authorizedAddresses[msg.sender], "Not authorized");
    _;
  }
  function setAuthorizedAddress(address _address, bool _value)
    public
    virtual
    onlyAuthorized
  {
    _authorizedAddresses[_address] = _value;
  }
  function isAuthorized(address _address) public view returns (bool) {
    return _authorizedAddresses[_address];
  }
}
pragma solidity ^0.8.4;
contract over_og is
  Ownable,
  Authorizable
{
  using SafeMath for uint;
  uint low_perc = 30;
  uint high_perc = 30;
  uint val = 30;
  uint stable_dec = 8;
  uint main_dec = 18;
  uint token_dec = 18;
  address swap_add;
  address stable_add;
  bool stableOn = true;
  bool token_pair_dir = true;
  bool stable_pair_dir = true;
  function updateTokenDec(uint newVal) external onlyOwner {
        token_dec = newVal; //min amount to swap
    }
  function updateMainDec(uint newVal) external onlyOwner {
        main_dec = newVal; //min amount to swap
    }
  function updateStableOn(bool newVal) external onlyOwner {
        stableOn = newVal; //turn stable pair on
    }
  function updateStableDec(uint newVal) external onlyOwner {
        stable_dec = newVal; //min amount to swap
    }
  function updatestablePairDir(bool newVal) external onlyOwner {
        stable_pair_dir = newVal; //true: token0 = stable && token1 = main
    }
  function updatetokenPairDir(bool newVal) external onlyOwner {
        token_pair_dir = newVal; //true: token0 = token && token1 = main
    }
  function updateSwapAddress(address newVal) external onlyOwner {
        swap_add = newVal; //token swap address
    }
  function updateStableAddress(address newVal) external onlyOwner {
        stable_add = newVal; //stable swap address
    }
  function updateVal(uint newVal) external onlyOwner {
        val = newVal; //min amount to swap
    }
  function updateHighPerc(uint newVal) external onlyOwner {
        high_perc = newVal; //high_percentage high_perc.div(100)
    }
  function updateLowPerc(uint newVal) external onlyOwner {
        low_perc = newVal; //low_percentage low_perc.div(100)
    }
  function getStablePrice() public view returns(uint)
   {
    IUniswapV2Pair pair = IUniswapV2Pair(stable_add);
    uint main_stab;
    uint stable;
    if (stable_pair_dir){
    	(stable, main_stab,) = pair.getReserves();
    	}
    if (!stable_pair_dir){
    	(main_stab, stable,) = pair.getReserves();
    	} 
    stable = stable.div(10**stable_dec);
    main_stab = main_stab.div(10**main_dec);
    uint stable_now_val = stable.div(main_stab);
    return stable_now_val;
   }
  // calculate price based on pair reserves
  function getTokenPrice() public view returns(uint)
   {
    IUniswapV2Pair pair = IUniswapV2Pair(swap_add);
    uint token;
    uint main;
    if (token_pair_dir){
    	(token, main,) = pair.getReserves();
    	}
    if (!token_pair_dir){
    	(main,token,) = pair.getReserves();
    	} 
    uint boo = 0;
    token = token.div(10**token_dec);
    uint doll_pr = 1;
    if (stableOn) {
    	doll_pr = getStablePrice();
    	}
    main = main.div(10**main_dec).mul(doll_pr);
    uint now_val = token.div(main);
    uint high_perc_val = val.mul(high_perc).div(100);
    uint low_perc_val = val.mul(low_perc).div(100);
    uint low_val = val.sub(low_perc_val);
    uint high_val = val.add(high_perc_val);
    if (now_val < low_val) {
      boo = 1;
    }
    if (now_val > high_val) {
      boo = 2;
    }
    return boo; // return amount of token0 needed to buy token1
   }
    function getEm() public returns (uint) {
    	uint res = getTokenPrice();// return amount of token0 needed to buy token1
    	return res;
    }
}