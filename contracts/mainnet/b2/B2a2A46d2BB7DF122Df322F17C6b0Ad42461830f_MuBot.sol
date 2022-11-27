// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
	function totalSupply() external view returns (uint);
	function balanceOf(address account) external view returns (uint);
	function transfer(address recipient, uint amount) external returns (bool);
	function allowance(address owner, address spender) external view returns (uint);
	function approve(address spender, uint amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint amount) external returns (bool);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
    function decimals() external view  returns (uint8);
}

interface Router {
    function getAmountsOut(uint256 amountIn, address[] memory path) external view returns (uint256[] memory amounts);
    function getAmountsIn(uint256 amountOut, address[] calldata path)external view returns (uint256[] memory amounts);
    function swapExactTokensForTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external returns (uint256[] memory amounts);  
    function swapTokensForExactTokens(uint256 amountOut,uint256 amountInMax,address[] calldata path,address to,uint256 deadline) external returns (uint256[] memory amounts);
    function addLiquidity(address tokenA,address tokenB,uint256 amountADesired,uint256 amountBDesired,uint256 amountAMin,uint256 amountBMin,address to,uint256 deadline)external returns (uint256 amountA,uint256 amountB,uint256 liquidity);
    function removeLiquidity(address tokenA,address tokenB,uint256 liquidity,uint256 amountAMin,uint256 amountBMin,address to,uint256 deadline) external returns (uint256 amountA, uint256 amountB);
}

interface Pair {
  function token0() external view returns (address);
  function token1() external view returns (address);
  function swap(uint256 amount0Out,	uint256 amount1Out,	address to,	bytes calldata data) external;
  function getReserves()external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}
interface Factory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}


contract MuBot is Ownable{

	constructor(){
		
	}

    

    function removeLiquidityKnowPairAddress(address LP, address router, address token1, address token2) external onlyOwner returns(uint256 amountA, uint256 amountB){
        uint256 deadline = block.timestamp + 300;
        uint256 liquidity = IERC20(LP).balanceOf(address(this));
        IERC20(LP).approve(router, liquidity);
        (uint256 _amountA, uint256 _amountB) = Router(router).removeLiquidity(token1, token2, liquidity, 1, 1, address(this), deadline);
        return (_amountA, _amountB);
    }

    function addLiquidity(address router, address tokenA, address tokenB, uint256 amountADesired,uint256 amountBDesired, uint256 amountAMin,uint256 amountBMin) public onlyOwner returns  ( uint256 amountA, uint256 amountB, uint256 liquidity){
     
        uint256 deadline = block.timestamp + 300;
        (uint256 _amountA, uint256 _amountB, uint256 _liquidity) = Router(router).addLiquidity(tokenA, tokenB, amountADesired, amountBDesired, amountAMin, amountBMin, address(this), deadline);
        return (_amountA, _amountB, _liquidity);
    
    }

    function swap(address router, address _tokenIn, address _tokenOut, uint256 _amount) private {
		address[] memory path;
		path = new address[](2);
		path[0] = _tokenIn;
		path[1] = _tokenOut;
		uint deadline = block.timestamp + 300;
		Router(router).swapExactTokensForTokens(_amount, 1, path, address(this), deadline);
	}


    function airbitrageTrade(address _router1, address _router2, address _token1, address _token2, address _token3, uint256 _amount) external onlyOwner {
    swap(_router1,_token1, _token2, _amount);
    uint token2Balance = IERC20(_token2).balanceOf(address(this));
    swap(_router2, _token2, _token3,token2Balance);
    }

    function getDecimals(address token) external onlyOwner view returns(uint8 decimals){
        return IERC20(token).decimals();
    }

    function getTokenInfo(address token) external onlyOwner view returns(uint8 decimals, string memory name, string memory symbol){
            uint8 _decimals =  IERC20(token).decimals();
            string memory _name = IERC20(token).name();
            string memory _symbol = IERC20(token).symbol();
            return(_decimals, _name, _symbol);
    }

    function getLPreserves(address LP) external onlyOwner view returns(uint112 reserve0, uint112 reserve1, address token0, address token1) {
            uint112 _reserve0;
            uint112 _reserve1;
            uint32 blockTimestampLast;
            address _token0 = Pair(LP).token0();
            address _token1 = Pair(LP).token1();
            (_reserve0, _reserve1,  blockTimestampLast) = Pair(LP).getReserves();
            return (_reserve0, _reserve1, _token0, _token1);
    }
    function getBalance (address _tokenContractAddress) external view  returns (uint256) {
		uint balance = IERC20(_tokenContractAddress).balanceOf(address(this));
		return balance;
	}

    function recoverEth() external onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

	function recoverTokens(address tokenAddress) external onlyOwner {
		IERC20 token = IERC20(tokenAddress);
		token.transfer(msg.sender, token.balanceOf(address(this)));
	}

    function approveRouters(address tokenAddress, uint256 amount) external onlyOwner{
        IERC20(tokenAddress).approve(0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506, amount);//sushiswap router
        IERC20(tokenAddress).approve(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106, amount);//pangolin router
        IERC20(tokenAddress).approve(0x60aE616a2155Ee3d9A68541Ba4544862310933d4, amount);//traderjoes router
    }

}