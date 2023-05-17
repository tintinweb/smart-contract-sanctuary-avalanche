/**
 *Submitted for verification at snowtrace.io on 2023-05-14
*/

// File: IERC20.sol


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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}
// File: TransferHelper.sol


pragma solidity >= 0.6.0;


library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}
// File: ReentrancyGuard.sol



pragma solidity 0.8.19;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}
// File: Web3DebitRouter0x.sol


pragma solidity 0.8.19;




interface ERC20 {

    function decimals() external view returns (uint8);

}


interface IStargateRouter {

    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }


    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

}


contract Web3DebitRouter0x is ReentrancyGuard {

IStargateRouter public stargateRouter;
uint public immutable source;
address payable public exchangeProxy;
uint public feeStore;
uint public idPayment;
address public owner;
address public treasury;
bool public locked;


struct DataStargate0x {
    uint16 dstChainId;
    uint256 srcPoolId;
    uint256 dstPoolId;
    uint256 amountLD;
    uint256 minAmountLD;
    uint256 gasfee;
    address receiverAddress;
    address tokenBridge;
}


struct DataSwap0x {
    bytes swapCallData;
    address tokenIn;
    address tokenOut;
    uint amountOut;
    uint amountInMaximum;
    address store;
    uint memo;
    uint amountSold;
    uint amountBought;
}


event Routed(
    uint indexed id,
    address indexed store,
    address indexed sender,
    uint memo,
    address tokenIn,
    address tokenOut,
    uint amountOut,
    uint fee,
    uint soldAmount,
    uint boughtAmount,
    uint destChain,
    uint amountOutFixed,
    address tokenBridge);


event ReceivedFromStargate(
    uint nonce,
    uint indexed id,
    uint srcChain,
    address indexed store,
    address indexed sender,
    address token,                 
    uint256 amountIn,
    uint amountPay,
    uint fee);
        

constructor(
    IStargateRouter _stargateRouter,
    address payable _exchangeProxy, 
    uint _source,
    address _owner,
    address _treasury) {
        
    require(_owner != address(0));
    require(_treasury != address(0));
    require(_source > 0);
    require(_exchangeProxy != address(0));

    source = _source;
    owner = _owner;
    stargateRouter = _stargateRouter;
    exchangeProxy = _exchangeProxy;
    treasury = _treasury;
}


modifier onlyOwner() {

    require(msg.sender == owner);
    _;

}


function transferOwner(address _owner) external onlyOwner {

    require(_owner != address(0));
    owner = _owner;

}


function transferTreasury(address _treasury) external {

    require(msg.sender == treasury);
    require(_treasury != address(0));
    treasury = _treasury;

}


function lockRouter() external onlyOwner {

    if (locked) {
        locked = false;
    }

    if (!locked) {
        locked = true;
    }

}


function changeStargateRouter(IStargateRouter _stargateRouter) external onlyOwner {
    
    stargateRouter = _stargateRouter;

}


function changeExchangeProxy(address payable _exchangeProxy) external onlyOwner {
    
    require(_exchangeProxy != address(0));
    exchangeProxy = _exchangeProxy;

}


function changeFeeStore(uint _feeStore) external onlyOwner {
    
    feeStore = _feeStore;

}


function noSwapPayOnChainSameERC20(
    DataSwap0x calldata _dataSwap) external nonReentrant {

    require(!locked);
    require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.tokenIn == _dataSwap.tokenOut);
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.amountInMaximum > 0);
    require(_dataSwap.amountOut == _dataSwap.amountInMaximum);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);
    require(_dataSwap.amountSold > 0);
    require(_dataSwap.amountBought > 0);
    require(_dataSwap.amountSold == _dataSwap.amountBought);

    idPayment += 1;

    require(IERC20(_dataSwap.tokenIn).balanceOf(msg.sender) >= _dataSwap.amountInMaximum);
    require(IERC20(_dataSwap.tokenIn).allowance(msg.sender, address(this)) >= _dataSwap.amountInMaximum);
        
    TransferHelper.safeTransferFrom(_dataSwap.tokenIn, msg.sender, address(this), _dataSwap.amountInMaximum);
        
    uint fee = _payment(_dataSwap.store, _dataSwap.tokenOut, _dataSwap.amountOut);    

    emit Routed(
        idPayment,
        _dataSwap.store,
        msg.sender,
        _dataSwap.memo,
        _dataSwap.tokenIn,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        fee,
        _dataSwap.amountSold,
        _dataSwap.amountBought,
        0,
        0,
        address(0));

}


function swapAndPayOnChainERC20(
    DataSwap0x calldata _dataSwap) external nonReentrant {

    require(!locked);
    require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.amountInMaximum > 0);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);
 
    idPayment += 1;

    _swapAndPayOnChainERC20(_dataSwap);

}


function _swapAndPayOnChainERC20(
    DataSwap0x calldata _dataSwap) internal {
    
    require(IERC20(_dataSwap.tokenIn).balanceOf(msg.sender) >= _dataSwap.amountInMaximum);
    require(IERC20(_dataSwap.tokenIn).allowance(msg.sender, address(this)) >= _dataSwap.amountInMaximum);
    
    uint balanceStartTokenIn = IERC20(_dataSwap.tokenIn).balanceOf(address(this));
    
    TransferHelper.safeTransferFrom(_dataSwap.tokenIn, msg.sender, address(this), _dataSwap.amountInMaximum);
    TransferHelper.safeApprove(_dataSwap.tokenIn, address(exchangeProxy), _dataSwap.amountInMaximum);
        
    uint balanceStartTokenOut = IERC20(_dataSwap.tokenOut).balanceOf(address(this));
    
    (bool success,) = exchangeProxy.call{value: 0}(_dataSwap.swapCallData);
    require(success, 'SWAP_CALL_FAILED');

    uint boughtAmount = IERC20(_dataSwap.tokenOut).balanceOf(address(this)) - balanceStartTokenOut;
    require(boughtAmount >= _dataSwap.amountOut);

    uint soldAmount = balanceStartTokenIn + _dataSwap.amountInMaximum - IERC20(_dataSwap.tokenIn).balanceOf(address(this));

    TransferHelper.safeApprove(_dataSwap.tokenIn, address(exchangeProxy), 0);
        
    if (soldAmount < _dataSwap.amountInMaximum) {
        TransferHelper.safeTransfer(_dataSwap.tokenIn, msg.sender, _dataSwap.amountInMaximum - soldAmount);
    }

    if (boughtAmount > _dataSwap.amountOut) {
        TransferHelper.safeTransfer(_dataSwap.tokenOut, msg.sender, boughtAmount - _dataSwap.amountOut);
    }

    uint fee = _payment(_dataSwap.store, _dataSwap.tokenOut, _dataSwap.amountOut);

    emit Routed(
        idPayment,
        _dataSwap.store,
        msg.sender,
        _dataSwap.memo,
        _dataSwap.tokenIn,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        fee,
        soldAmount,
        boughtAmount,
        0,
        0,
        address(0));

}


function swapAndPayOnChainNATIVE(
    DataSwap0x calldata _dataSwap) external payable nonReentrant {

    require(!locked);
    require(_dataSwap.amountInMaximum > 0);
    require(msg.value == _dataSwap.amountInMaximum);
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);

    idPayment += 1;

    _swapAndPayOnChainNATIVE(_dataSwap);

}


function _swapAndPayOnChainNATIVE(
    DataSwap0x calldata _dataSwap) internal {

    uint balanceStartTokenOut = IERC20(_dataSwap.tokenOut).balanceOf(address(this));
    uint balanceStartTokenIn = address(this).balance;

    (bool success0x,) = exchangeProxy.call{value: msg.value}(_dataSwap.swapCallData);
    require(success0x, 'SWAP_CALL_FAILED');

    uint boughtAmount = IERC20(_dataSwap.tokenOut).balanceOf(address(this)) - balanceStartTokenOut;
    require(boughtAmount >= _dataSwap.amountOut);

    uint soldAmount = balanceStartTokenIn - address(this).balance;
    
    if (soldAmount < _dataSwap.amountInMaximum) {
        (bool success,) = msg.sender.call{ value: _dataSwap.amountInMaximum - soldAmount }("");
    }

    if (boughtAmount > _dataSwap.amountOut) {
        TransferHelper.safeTransfer(_dataSwap.tokenOut, msg.sender, boughtAmount - _dataSwap.amountOut);
    }
    
    uint fee = _payment(_dataSwap.store, _dataSwap.tokenOut, _dataSwap.amountOut);

    emit Routed(
        idPayment,
        _dataSwap.store,
        msg.sender,
        _dataSwap.memo,
        _dataSwap.tokenIn,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        fee,
        soldAmount,
        boughtAmount,
        0,
        0,
        address(0));

}


function swapToStargate(
    DataSwap0x calldata _dataSwap,
    DataStargate0x calldata _dataStargate) external payable nonReentrant {

    require(!locked);
    require(msg.value > 0);

    require(_dataStargate.dstChainId > 0);
    require(_dataStargate.srcPoolId > 0);
    require(_dataStargate.dstPoolId > 0);
    require(_dataStargate.amountLD > 0);
    require(_dataStargate.minAmountLD > 0);
    require(_dataStargate.gasfee > 0);
    require(_dataStargate.receiverAddress != address(0));
    require(_dataStargate.tokenBridge != address(0));


    require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);

    idPayment += 1;

    _swapToStargate(_dataSwap, _dataStargate);
    
}


function _swapToStargate(
    DataSwap0x calldata _dataSwap,
    DataStargate0x calldata _dataStargate) internal {
    
    require(IERC20(_dataSwap.tokenIn).balanceOf(msg.sender) >= _dataStargate.amountLD);
    require(IERC20(_dataSwap.tokenIn).allowance(msg.sender, address(this)) >= _dataStargate.amountLD);
        
    TransferHelper.safeTransferFrom(_dataSwap.tokenIn, msg.sender, address(this), _dataStargate.amountLD);
    TransferHelper.safeApprove(_dataSwap.tokenIn, address(stargateRouter), _dataStargate.amountLD);
    
    bytes memory payload = abi.encode(
        idPayment,
        source,
        _dataSwap.store,
        _dataSwap.amountOut,
        msg.sender);

     stargateRouter.swap{value: msg.value }(
        _dataStargate.dstChainId,                          
        _dataStargate.srcPoolId,                           
        _dataStargate.dstPoolId,                           
        payable(msg.sender),                      
        _dataStargate.amountLD,                  
        _dataStargate.minAmountLD,               
        IStargateRouter.lzTxObj(_dataStargate.gasfee, 0, "0x"), 
        abi.encodePacked(_dataStargate.receiverAddress),    
        payload);                     

    emit Routed(
        idPayment,
        _dataSwap.store,
        msg.sender,
        _dataSwap.memo,
        _dataSwap.tokenIn,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        0,
        _dataStargate.amountLD,
        _dataStargate.amountLD,
        _dataStargate.dstChainId,
        _dataStargate.minAmountLD,
        _dataStargate.tokenBridge);

}


function swapAndPayCrossChainERC20(
    DataSwap0x calldata _dataSwap,
    DataStargate0x calldata _dataStargate) external payable nonReentrant {   
        
    require(!locked);
    require(msg.value > 0);

    require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.amountInMaximum > 0);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);    
    
    require(_dataStargate.dstChainId > 0);
    require(_dataStargate.srcPoolId > 0);
    require(_dataStargate.dstPoolId > 0);
    require(_dataStargate.amountLD > 0);
    require(_dataStargate.minAmountLD > 0);
    require(_dataStargate.gasfee > 0);
    require(_dataStargate.receiverAddress != address(0));
    require(_dataStargate.tokenBridge != address(0));
    
    idPayment += 1;

    _swapAndPayCrossChainERC20(_dataSwap, _dataStargate);

}


function _swapAndPayCrossChainERC20(
    DataSwap0x memory _dataSwap,
    DataStargate0x calldata _dataStargate) internal {

    require(IERC20(_dataSwap.tokenIn).balanceOf(msg.sender) >= _dataSwap.amountInMaximum);
    require(IERC20(_dataSwap.tokenIn).allowance(msg.sender, address(this)) >= _dataSwap.amountInMaximum);

    uint balanceStartTokenIn = IERC20(_dataSwap.tokenIn).balanceOf(address(this));    
    
    TransferHelper.safeTransferFrom(_dataSwap.tokenIn, msg.sender, address(this), _dataSwap.amountInMaximum);
    TransferHelper.safeApprove(_dataSwap.tokenIn, address(exchangeProxy), _dataSwap.amountInMaximum);
    
    uint balanceStartTokenOut = IERC20(_dataStargate.tokenBridge).balanceOf(address(this));
    
    (bool success,) = exchangeProxy.call{value: 0}(_dataSwap.swapCallData);
    require(success, 'SWAP_CALL_FAILED');

    uint boughtAmount = IERC20(_dataStargate.tokenBridge).balanceOf(address(this)) - balanceStartTokenOut;
    require(boughtAmount >= _dataStargate.amountLD);

    uint soldAmount = balanceStartTokenIn + _dataSwap.amountInMaximum - IERC20(_dataSwap.tokenIn).balanceOf(address(this));

    TransferHelper.safeApprove(_dataSwap.tokenIn, address(exchangeProxy), 0);
        
    if (soldAmount < _dataSwap.amountInMaximum) {
        TransferHelper.safeTransfer(_dataSwap.tokenIn, msg.sender, _dataSwap.amountInMaximum - soldAmount);
    }

    if (boughtAmount > _dataStargate.amountLD) {
        TransferHelper.safeTransfer(_dataStargate.tokenBridge, msg.sender, boughtAmount - _dataStargate.amountLD);
    }

    TransferHelper.safeApprove(_dataStargate.tokenBridge, address(stargateRouter), _dataStargate.amountLD);  
    
    _dataSwap.amountSold = soldAmount;
    _dataSwap.amountBought = boughtAmount;

    _swapToStargateFromERC20(_dataSwap, _dataStargate);

}


function _swapToStargateFromERC20(
    DataSwap0x memory _dataSwap,
    DataStargate0x calldata _dataStargate) internal {

    bytes memory payload = abi.encode(
        idPayment,
        source,
        _dataSwap.store,
        _dataSwap.amountOut,
        msg.sender);

    stargateRouter.swap{value: msg.value }(
        _dataStargate.dstChainId,          
        _dataStargate.srcPoolId,           
        _dataStargate.dstPoolId,           
        payable(msg.sender),                
        _dataStargate.amountLD,            
        _dataStargate.minAmountLD,         
        IStargateRouter.lzTxObj(_dataStargate.gasfee, 0, "0x"), 
        abi.encodePacked(_dataStargate.receiverAddress),    
        payload);                     

    emit Routed(
        idPayment,
        _dataSwap.store,
        msg.sender,
        _dataSwap.memo,
        _dataSwap.tokenIn,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        0,
        _dataSwap.amountSold,
        _dataSwap.amountBought,
        _dataStargate.dstChainId,
        _dataStargate.minAmountLD,
        _dataStargate.tokenBridge);

}


function swapAndPayCrossChainNATIVE(
    DataSwap0x calldata _dataSwap,
    DataStargate0x calldata _dataStargate) external payable nonReentrant {
    
    require(!locked);
    require(msg.value > 0);
  
    require(_dataSwap.tokenIn != address(0));
    require(_dataSwap.tokenOut != address(0));
    require(_dataSwap.amountOut > 0);
    require(_dataSwap.amountInMaximum > 0);
    require(_dataSwap.store != address(0));
    require(_dataSwap.memo > 0);    
    
    require(_dataStargate.dstChainId > 0);
    require(_dataStargate.srcPoolId > 0);
    require(_dataStargate.dstPoolId > 0);
    require(_dataStargate.amountLD > 0);
    require(_dataStargate.minAmountLD > 0);
    require(_dataStargate.gasfee > 0);
    require(_dataStargate.receiverAddress != address(0));
    require(_dataStargate.tokenBridge != address(0));

    idPayment += 1;

    _swapAndPayCrossChainNATIVE(_dataSwap, _dataStargate);

}


function _swapAndPayCrossChainNATIVE(
    DataSwap0x memory _dataSwap,
    DataStargate0x calldata _dataStargate) internal {
      
    uint balanceStartTokenOut = IERC20(_dataStargate.tokenBridge).balanceOf(address(this));
    uint balanceStartTokenIn = address(this).balance;

    (bool success0x,) = exchangeProxy.call{value: _dataSwap.amountInMaximum }(_dataSwap.swapCallData);
    require(success0x, 'SWAP_CALL_FAILED');

    uint boughtAmount = IERC20(_dataStargate.tokenBridge).balanceOf(address(this)) - balanceStartTokenOut;
    require(boughtAmount >= _dataStargate.amountLD);

    uint soldAmount = balanceStartTokenIn - address(this).balance;
        
    if (soldAmount < _dataSwap.amountInMaximum) {
        (bool success,) = msg.sender.call{ value: _dataSwap.amountInMaximum - soldAmount }("");
    }

    if (boughtAmount > _dataStargate.amountLD) {
        TransferHelper.safeTransfer(_dataStargate.tokenBridge, msg.sender, boughtAmount - _dataStargate.amountLD);
    }

    TransferHelper.safeApprove(_dataStargate.tokenBridge, address(stargateRouter), _dataStargate.amountLD);  

    _dataSwap.amountSold = soldAmount;
    _dataSwap.amountBought = boughtAmount;

    _swapToStargateFromNATIVE(_dataSwap, _dataStargate);

}


function _swapToStargateFromNATIVE(
    DataSwap0x memory _dataSwap,
    DataStargate0x calldata _dataStargate) internal {
    
    bytes memory payload = abi.encode(
        idPayment,
        source,
        _dataSwap.store,
        _dataSwap.amountOut,
        msg.sender);

    stargateRouter.swap{value: msg.value - _dataSwap.amountInMaximum }(
        _dataStargate.dstChainId,                         
        _dataStargate.srcPoolId,                          
        _dataStargate.dstPoolId,                          
        payable(msg.sender),                      
        _dataStargate.amountLD,                  
        _dataStargate.minAmountLD,
        IStargateRouter.lzTxObj(_dataStargate.gasfee, 0, "0x"),
        abi.encodePacked(_dataStargate.receiverAddress),   
        payload);                     

   emit Routed(
        idPayment,
        _dataSwap.store,
        msg.sender,
        _dataSwap.memo,
        _dataSwap.tokenIn,
        _dataSwap.tokenOut,
        _dataSwap.amountOut,
        0,
        _dataSwap.amountSold,
        _dataSwap.amountBought,
        _dataStargate.dstChainId,
        _dataStargate.minAmountLD,
        _dataStargate.tokenBridge);

}


function sgReceive(
    uint16 /*_srcChainId*/,            
    bytes memory /*_srcAddress*/,      
    uint256 _nonce,                  
    address _token,                
    uint256 amountLD,              
    bytes memory payload) external nonReentrant {

    require(msg.sender == address(stargateRouter)); 

    (uint id,
     uint sourceId,
     address store,
     uint amountOut,
     address sender) = abi.decode(payload, (uint, uint, address, uint, address));
 
    uint amountToPay;

    if (amountLD > amountOut) {
        TransferHelper.safeTransfer(_token, sender, amountLD - amountOut);
        amountToPay = amountOut;
    }

    if (amountLD <= amountOut) {
        amountToPay = amountLD;
    }

    uint fee = _payment(store, _token, amountToPay);

    emit ReceivedFromStargate(
        _nonce,
        id,
        sourceId,
        store,
        sender,
        _token,
        amountLD,
        amountToPay,
        fee);

}    


function _payment(
    address _store,
    address _tokenOut,
    uint _amountOut) internal returns (uint) {

    uint decimals = ERC20(_tokenOut).decimals();
    
    uint feeAmount = _amountOut * ((feeStore) * 10 ** decimals / 10000);
    feeAmount = feeAmount / 10 ** decimals;

    uint netAmount = _amountOut - feeAmount;
    
    TransferHelper.safeTransfer(_tokenOut, _store, netAmount);

    if (feeAmount > 0) {
        TransferHelper.safeTransfer(_tokenOut, treasury, feeAmount);
    }
 
    return feeAmount;

}


function withdrawEther() external payable nonReentrant {
  
    require(msg.sender == treasury);
    (bool sent,) = treasury.call{value: address(this).balance}("");
    
}


function balanceEther() external view returns (uint) {
 
    return address(this).balance;

}


function balanceERC20(IERC20 _token) external view returns (uint) {
 
    return _token.balanceOf(address(this));

}


function withdrawERC20(IERC20 _token) external nonReentrant {
  
    require(msg.sender == treasury);
    TransferHelper.safeTransfer(address(_token), treasury, _token.balanceOf(address(this)));
    
}


receive() external payable {}


}