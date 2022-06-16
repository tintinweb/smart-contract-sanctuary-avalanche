/**
 *Submitted for verification at snowtrace.io on 2022-06-16
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface ISimpleFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface ISimpleRouter {
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface ISimpleERC20 {
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
}

interface ISimplePair {
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract FlashSwap is Ownable {
    function execute(
        address buyFactoryAddress,
        address buyRouterAddress,
        address sellRouterAddress,
        address tokenPay,
        address tokenSwap,
        uint256 amountTokenPay
    ) external onlyOwner() {
        address pairAddress = ISimpleFactory(buyFactoryAddress).getPair(tokenPay, tokenSwap);
        require(pairAddress != address(0), "This pool does not exist");
        ISimplePair pair = ISimplePair(pairAddress);

        (int256 profit, uint256 _tokenBorrowAmount) = check(tokenPay, tokenSwap, amountTokenPay,  buyRouterAddress, sellRouterAddress);
        require(profit > 0, "Not profitable");
        
        address token0 = pair.token0();
        address token1 = pair.token1();

        ISimplePair(pairAddress).swap(
            tokenSwap == token0 ? _tokenBorrowAmount : 0,
            tokenSwap == token1 ? _tokenBorrowAmount : 0,
            address(this),
            abi.encode(buyRouterAddress, sellRouterAddress)
        );
    }

     function check(
        address _tokenPay, // source currency when we will get; example BNB
        address _tokenSwap, // swapped currency with the source currency; example BUSD
        uint _amountTokenPay, // example: BNB => 10 * 1e18
        address _sourceRouter,
        address _targetRouter
    ) public view returns(int, uint256) {
        address[] memory path = new address[](2);
        address[] memory inversedPath = new address[](2);

        // path represents the forwarding exchange from source currency to swapped currency
        path[0] = inversedPath[1] = _tokenPay;
        // inversedPath represents the backward exchange from swapeed currency to source currency
        path[1] = inversedPath[0] = _tokenSwap;

        uint256 amountOut = ISimpleRouter(_sourceRouter).getAmountsOut(_amountTokenPay, path)[1];
        uint256 amountRepay = ISimpleRouter(_targetRouter).getAmountsOut(amountOut, inversedPath)[1];

        return (
            int(amountRepay - _amountTokenPay), // our profit or loss; example output: BNB
            amountOut // the amount we get from our input "_amountTokenPay"; example: BUSD amount
        );
    }

    function _handleCallback(
        address _sender,
        uint _amount0,
        uint _amount1,
        bytes calldata _data
    ) internal {
        // obtain an amout of token that you exchanged
        uint256 amountToken = _amount0 == 0 ? _amount1 : _amount0;

        ISimplePair pair = ISimplePair(msg.sender);
        address token0 = pair.token0();
        address token1 = pair.token1();

        (
            address buyRouterAddress,
            address sellRouterAddress
        ) = abi.decode(_data, (address, address));
        
        require(buyRouterAddress != address(0) && sellRouterAddress != address(0), "buy/sell router is zero");

        // if _amount0 is zero sell token1 for token0
        // else sell token0 for token1 as a result
        address[] memory path = new address[](2);
        address[] memory inversedPath = new address[](2);

        address forward = _amount0 == 0 ? token1 : token0;
        address backward = _amount0 == 0 ? token0 : token1;

        path[0] = inversedPath[1] = forward;
        path[1] = inversedPath[0] = backward;

        // IERC20 token that we will sell for otherToken
        ISimpleERC20 token = ISimpleERC20(forward);
        ISimpleERC20 otherToken = ISimpleERC20(backward);

        token.approve(sellRouterAddress, amountToken);
  
        // calculate the amount of token how much input token should be reimbursed
        uint256 amountRequired = ISimpleRouter(buyRouterAddress).getAmountsIn(amountToken, inversedPath)[0];

        // swap token and obtain equivalent otherToken amountRequired as a result
        // need to receive amountRequired at minimum amount to pay back
        uint256 amountReceived = ISimpleRouter(sellRouterAddress).swapExactTokensForTokens(
            amountToken,
            amountRequired,
            path,
            address(this),
            block.timestamp + 60
        )[1];
        
        require(amountReceived > amountRequired, "pancakeCall: not enough tokens for buyback");
        
        otherToken.transfer(msg.sender, amountRequired);
        otherToken.transfer(owner(), amountReceived - amountRequired);
    }

    function _calculateAmountReceived(
        address routerAddress,
        uint amount,
        uint amountRequired,
        address[] memory path,
        address targett,
        uint timestamp
    ) internal returns (uint256)
    {
        return ISimpleRouter(routerAddress).swapExactTokensForTokens(
            amount,
            amountRequired,
            path,
            targett,
            timestamp
        )[1];
    }

    receive() external payable {}

    // avax
    function yetiswapCall(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }

    function elkCall(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }

    function lydiaCall(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }

    function oliveCall(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }

    function pangolinCall(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }
    
    function joeCall(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }

    function dmmSwapCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }

    // BSC
    function BiswapCall(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }

    function swapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }

    function waultSwapCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }

    function pantherCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }

    function uniswapV2Call(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }

    function pancakeCall(address _sender, uint _amount0, uint _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }

    function wardenCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }

    function jetswapCall(address _sender, uint256 _amount0, uint256 _amount1, bytes calldata _data) external {
        _handleCallback(_sender, _amount0, _amount1, _data);
    }
}