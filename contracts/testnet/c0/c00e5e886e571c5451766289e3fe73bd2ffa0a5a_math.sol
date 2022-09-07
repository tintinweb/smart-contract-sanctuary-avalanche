/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-07
*/

/**
 *Submitted for verification at snowtrace.io on 2022-08-29
*/

// SPDX-License-Identifier: (Unlicense)
pragma solidity ^0.8.0;
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
library boostLib {
    using SafeMath for uint256;
    function boostPerDay(uint256 _dailyRewardsPerc) internal pure returns(uint256){
            uint256 _one_ = 1;
            uint256 one = _one_*(10**18)/1440;
	    uint256 _rewardsPerMin = doPercentage(one, _dailyRewardsPerc);
	    return _rewardsPerMin;
    }
	
    function calcReward(uint256 _rewardsPerMin,uint256 _timeStep,uint256 _timestamp, uint256 _lastClaimTime, uint256 _boost_) internal pure returns (uint256){
	    uint256 elapsed = _timestamp - _lastClaimTime;
	    (uint256 _rewardsTMul,uint256 _dayMultiple1) = getMultiple(elapsed,_timeStep,_rewardsPerMin);
	    uint256[2] memory _rewards_ = addFee(_rewardsTMul,_boost_);
	    uint256 _rewards = _rewards_[0];
	    uint256 _boost = _rewards_[1];
    	    uint256 _all  = _rewards+_boost;
    	    return _all;
    	   }
    function doPercentage(uint256 x, uint256 y) internal pure returns (uint256) {
    	uint256 xx = 0;
   	if (y !=0){
   		xx = x.div((10000)/(y)).mul(100);
   	}
    	return xx;
    }
    function addFee(uint256 x,uint256 y) internal pure returns (uint256[2] memory) {
        (uint256 w, uint256 y_2) = getMultiple(y,100,x);
    	return [w,doPercentage(x,y_2)];
    }
    function getMultiple(uint256 x,uint256 y,uint256 z) internal pure returns (uint,uint256) {
    	uint256 Zero = 0;
    	if(x == Zero || y == Zero || z == Zero){
    		return(z,Zero);
    	}
    	uint i = 0;
    	uint256 w = z;
    	while(x > y){
    		i++;
    		x = x - y;
    		z += w;
    	}

    	return (z,x);
    }
    function isInList(address x, address[] memory y) internal pure returns (bool){
    	for (uint i =0; i < y.length; i++) {
            if (y[i] == x){
                return true;
            }
    	}
    	return false;
    }
}
library nebuLib {
	using SafeMath for uint256;
	function doPercentage(uint256 x, uint256 y) internal pure returns (uint256) {
	    	uint256 Zero = 0;
	    	uint256 xx = Zero;
	   	if (y == Zero){
	   		return x;
	   	}else if(x == Zero){
	   		return Zero;
	   	}
	   	xx = x.div((10000)/(y)).mul(100);
	    	return xx;
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
    
    function decimals() external view returns (uint8);
    
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
abstract contract nft_stake is Context {
    function isStaked(address _account) external virtual returns(bool);
    function idAmount(address _account,uint256 i) external virtual returns(uint256);
    function getTimes(address _account,uint256 i,uint256 k) external virtual view returns(uint256);
}
  

pragma solidity ^0.8.4;
contract math is
  Ownable,
  Authorizable
{
  using SafeMath for uint;
   struct GREENSamt {
        uint256 amount;
    }
    struct GREENStime {
        uint256 elapsed;
    }
    struct GREENSboost {
        uint256 boost;
    }
  uint256 low_perc = 30;
  uint256 high_perc = 30;
  uint256 val = 30;
  address swap_add;
  address stable_swap_add;
  address token_add;
  address main_add;
  address stable_add;
  address public _stake;
  uint256 public dailyRewardsPerc;
  uint256 public timeStep;
  uint256 public rewardsPerMin;
  uint256 public cashoutFee;
  uint256 public Zero = 0;
  uint256 public fee = 15*(10**18);
  uint256[3] public nftCost = [300*(10**18),750*(10**18),1500*(10**18)];
  uint256[3] public nftCashoutPercs = [Zero,5,10];
  uint256[3] public boostRewardsPerMin = [121658312447700,104166666666600,86805555555500];
  uint256[3] public boostRewardsPerMin_ = [121658312447700,104166666666600,86805555555500];
  nft_stake public NFT_CONT;
  bool stableOn = true;
  uint256[] public boostMultiplier;
  constructor(address[] memory swaps,uint256[] memory _boosts,uint256[3] memory _nftCost,uint256[] memory _vars,uint256[] memory _fees,uint256[] memory _cashoutRed){
	  swap_add = swaps[0];
	  stable_swap_add = swaps[1];
	  token_add = swaps[2];
	  main_add = swaps[3];
	  stable_add = swaps[4];
	  _stake = swaps[5];
	  NFT_CONT = nft_stake(_stake);
	  boostMultiplier = [_boosts[0],_boosts[1],_boosts[2]];
	  for(uint i=0;i<3;i++){
	  	nftCost[i] = _nftCost[i]*(10**18);
	  }
	  dailyRewardsPerc = _vars[0];
	  timeStep = _vars[1].mul(1 minutes);
	  rewardsPerMin = boostLib.boostPerDay(dailyRewardsPerc);
	  uint256 time = block.timestamp;
	  uint256 lastClaimTime = time - 1 minutes;
	  cashoutFee = _fees[0];
	  for(uint i=0;i<3;i++){
	  	boostRewardsPerMin[i] =boostLib.calcReward(rewardsPerMin,timeStep,time,lastClaimTime,boostMultiplier[i]);
	  	nftCashoutPercs[i] = nebuLib.doPercentage(cashoutFee,_cashoutRed[i]);
	  }
	  
  }
  function getStablePrice() public view returns (uint256)
   {
    uint[4] memory vals = find_dir(stable_swap_add);
    uint256 _stable = vals[0];
    uint256 _main = vals[1].div(10**vals[3]);
    uint256 stable_now_val = _stable.div(_main);
    return stable_now_val*(10**10);
   }
  // calculate price based on pair reserves
  function adds(address pair_add, bool tok) public view returns(address) {
      IUniswapV2Pair pair = IUniswapV2Pair(swap_add);
      if (tok) {
         IERC20 swap_token = IERC20(pair.token0());
         return address(swap_token);
      }
      IERC20 swap_token = IERC20(pair.token1());
      return address(swap_token);
      }
  function decs(address pair_add) public view returns(uint256) {
         IERC20 swap_token = IERC20(pair_add);
         uint256 _dec =  swap_token.decimals();
         return _dec;
     }
  function find_dir(address ad) public view returns(uint[4] memory) {
    IUniswapV2Pair pair = IUniswapV2Pair(ad);
    address ad0 = adds(swap_add, true);
    address ad1 = adds(swap_add, false);
    uint256 dec0 = decs(ad0);
    uint256 dec1 = decs(ad1);
    (uint256 res0, uint256 res1,) = pair.getReserves();
    uint256 t0 = res0;
    uint256 t0_dec = dec0;
    uint256 t1 = res1;
    uint256 t1_dec = dec1;
    if (main_add == ad0) {
    	t1 = res0;
    	t1_dec = dec0;
    	t0 = res1;
    	t0_dec = dec1;
    }
    return [t0,t1,t0_dec,t1_dec];
   }
  function getTokenPrice() public view returns(uint256) {
    uint256[4] memory vals = find_dir(swap_add);
    uint256 _token = vals[0];
    uint256 _main = vals[1];
    uint256 now_val = _token.div(_main);
    if (stableOn) {
    	uint256 doll_pr = getStablePrice();
    	_main = 100*_main.mul(doll_pr);
    	now_val = _main.div(_token);
    	}
    uint256 high_perc_val = val.mul(high_perc).div(100);
    uint256 low_perc_val = val.mul(low_perc).div(100);
    uint256 low_val = val.sub(low_perc_val);
    uint256 high_val = val.add(high_perc_val);
    if (now_val < low_val) {
      return 1;
    }
    if (now_val > high_val) {
      return 2;
    }
    return 0;
    // return amount of token0 needed to buy token1
   }
 function getMultiplier(uint256 _x) external returns(uint256){
 	return boostMultiplier[_x];
 }
 function getBoostPerMin(uint256 _x) external view returns(uint256){
 	return boostRewardsPerMin[_x];
 }
 function getBoostPerMin_(uint256 _x) external view returns(uint256){
 	return boostRewardsPerMin_[_x];
 }
 function getRewardsPerMin() external view returns (uint256){
 	return rewardsPerMin;
 }
 function getCashoutRed(uint256 _x) external view returns (uint256){
 	return nftCashoutPercs[_x];
 }
 function getNftTimes(address _account, uint256 _id,uint256 _x) external view returns(uint256){
 	return NFT_CONT.getTimes(_account,_id,_x);
 }
 function isStaked(address _account) internal returns(bool){
 	return NFT_CONT.isStaked(_account);
 }
 function getNftAmount(address _account, uint256 _id) external returns(uint256){
 	if(isStaked(_account) == false){
 		return Zero;
 	}
 	return NFT_CONT.idAmount(_account,_id);
 }
 function getFee() external view returns(uint256) {
   	 uint256 _fee = (fee*(10**18)).div(getStablePrice()*100);
   	 return _fee;
   }
 function getModFee(uint256 _val) external view returns(uint256) {
   	 uint256 _fee = (uint256(_val)*(10**18)).div(getStablePrice()*100);
   	 return _fee;
 }
 function getNftPrice(uint _val) external view returns(uint256) {
   	 uint256 _fee = (nftCost[_val]*(10**18)).div(getStablePrice()*100);
   	 return _fee;
 }
 function getEm() external view returns (uint256) {
    	uint256 res = getStablePrice()*(100);
    	return res;
    }
 function getNftInfo(address _account,uint256 _id,uint256 _k) external view returns(uint256){
  	return NFT_CONT.getTimes(_account,_id,_k);
  }
 function updateStableOn(bool newVal) external onlyOwner {
        stableOn = newVal; //turn stable pair on
 }
 function updateNftCost(uint256[3] memory _vals) external onlyOwner {
 	for(uint i=0;i<3;i++){
	  	nftCost[i] = _vals[i]*(10**18);
	  }
 }
 function updateStakeAddress(address newVal) external onlyOwner {
          _stake = newVal;
	  NFT_CONT  = nft_stake(_stake);
    }
  function updateStableAddress(address newVal) external onlyOwner {
        stable_add = newVal; //true: token0 = stable && token1 = main
    }
  function updateTokenAddress(address newVal) external onlyOwner {
        token_add = newVal; //true: token0 = token && token1 = main
    }
  function updateMainAddress(address newVal) external onlyOwner {
        main_add = newVal; //true: token0 = token && token1 = main
    }
  function updateSwapAddress(address newVal) external onlyOwner {
        swap_add = newVal; //token swap address
    }
  function updateStableSwapAddress(address newVal) external onlyOwner {
        stable_swap_add = newVal; //stable swap address
    }
  function updateVal(uint256 newVal) external onlyOwner {
        val = newVal; //min amount to swap
    }
  function updateHighPerc(uint256 newVal) external onlyOwner {
        high_perc = newVal; //high_percentage high_perc.div(100)
    }

  function updateLowPerc(uint256 newVal) external onlyOwner {
        low_perc = newVal; //low_percentage low_perc.div(100)
    }    
}