/**
 *Submitted for verification at snowtrace.io on 2023-01-23
*/

// SPDX-License-Identifier: MIT
// DTSR by xrpant - theorized by minerminer

// File: @openzeppelin/contracts/utils/Context.sol
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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

interface IPangolinRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);
    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

interface ILP {
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256);
    function getReserves() external view returns (uint112, uint112, uint32);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
}

contract DSTR is ReentrancyGuard, Ownable {

    uint256 constant MAX_INT = 2**256 - 1;

    bool public paused = false;

    struct LPToken {
        address tokenA;
        address tokenB;
        uint256 tokenASlippage;
        uint256 tokenBSlippage;
        bool allowDeposit;
        bool allowWithdraw;
        bool isPangolin; 
    }

    mapping(address => LPToken) public acceptedTokens;

    event LPDusted(address indexed swapper, address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);
    event TokenSwap(address indexed tokenIn, address indexed tokenOut, uint256 amountIn, uint256 amountOut);

    address _routerP; // Pangolin
    address _routerT; // Trader Joe

    constructor() {
        _routerP = 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106; // Pangolin
        _routerT = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4; // Trader Joe
    }

    function dust(address tokenContractIn, address tokenContractOut, uint256 amount) public nonReentrant {
        require(!paused, "Contract is paused!");

        LPToken memory _lpIn = acceptedTokens[tokenContractIn];
        require(_lpIn.allowDeposit, "Token deposit not accepted!");

        LPToken memory _lpOut = acceptedTokens[tokenContractOut];
        require(_lpOut.allowWithdraw, "Token withdrawal not accepted!");

        require(_lpIn.tokenB == _lpOut.tokenB, "Pools are not compatible.");

        IERC20 _tokenB = IERC20(_lpIn.tokenB); 

        IERC20 _tokenOut = IERC20(tokenContractOut);
        
        require(IERC20(tokenContractIn).transferFrom(msg.sender, address(this), amount), "Failed to transfer tokenIn!");

        uint _amountReceivedTokenA;
        uint _amountReceivedTokenB;

        // remove liquidity
        if (_lpIn.isPangolin) {
            (_amountReceivedTokenA, _amountReceivedTokenB) = removeLiquidity(tokenContractIn, _routerP, _lpIn, amount);
        } else {
            (_amountReceivedTokenA, _amountReceivedTokenB) = removeLiquidity(tokenContractIn, _routerT, _lpIn, amount);
        }

        // get amount tokenA needed for new LP
        uint256 _outTokenANeeded = getTokenANeeded(tokenContractOut, _amountReceivedTokenB);

        require(IERC20(_lpOut.tokenA).balanceOf(address(this)) >= _outTokenANeeded, "Not enough outTokenA for swap");

        uint256 _newLP;
        uint _amountTokenAOut;
        uint _amountTokenBOut;

        // add liquidity
        if (_lpOut.isPangolin) {
            (_amountTokenAOut, _amountTokenBOut, _newLP) = addLiquidity(_routerP, _lpOut, _outTokenANeeded, _amountReceivedTokenB);
        } else {
            (_amountTokenAOut, _amountTokenBOut, _newLP) = addLiquidity(_routerT, _lpOut, _outTokenANeeded, _amountReceivedTokenB);
        }

        uint _excessTokenB = _amountReceivedTokenB - _amountTokenBOut;

        // return excessTokenB and new LP tokens
        if (_excessTokenB > 0) {
            _tokenB.transfer(msg.sender, _excessTokenB);
        } 

        if (_newLP > 0) {
            _tokenOut.transfer(msg.sender, _newLP);
        } 

        emit TokenSwap(_lpIn.tokenA, _lpOut.tokenA, _amountReceivedTokenA, _amountTokenAOut);
        emit LPDusted(msg.sender, tokenContractIn, tokenContractOut, amount, _newLP);
    }

    function tokenAView(address _pool, uint256 _amount) internal view returns(uint) {
        ILP _lp = ILP(_pool);
        uint _lpSupply = _lp.totalSupply();

        (uint _reserveTokenA,,) = _lp.getReserves();

        uint _tokenAmount = _amount * _reserveTokenA / _lpSupply;

        return _tokenAmount;
    }
    
    function tokenBView(address _pool, uint256 _amount) internal view returns(uint) {
        ILP _lp = ILP(_pool);
        uint _lpSupply = _lp.totalSupply();

        (,uint _reserveTokenB,) = _lp.getReserves();

        uint _tokenAmount = _amount * _reserveTokenB / _lpSupply;

        return _tokenAmount;
    }

    function getTokenANeeded(address _tokenContractOut, uint _amountReceivedTokenB) internal view returns (uint) {
        // get LP reserves and find the required tokenOut amount to add liquidity
        (uint256 _outTokenAReserves, uint256 _outTokenBReserves,) = ILP(_tokenContractOut).getReserves();

        return ((_outTokenAReserves / _outTokenBReserves) * 10**18) * _amountReceivedTokenB / 10**18;
    }

    function removeLiquidity(address tokenIn_, address router_, LPToken memory _lpIn, uint amount) internal returns (uint, uint) {
        // get LP reserves to estimate tokenIn backing
        uint _tokenAIn = tokenAView(tokenIn_, amount);
        uint _tokenBIn = tokenBView(tokenIn_, amount);

        IPangolinRouter _router = IPangolinRouter(router_);

        return _router.removeLiquidity(
            _lpIn.tokenA, //address tokenA,
            _lpIn.tokenB, //address tokenB,
            amount, //uint liquidity,
            applySlippage(_tokenAIn, _lpIn.tokenASlippage), //uint amountAMin, percent
            applySlippage(_tokenBIn, _lpIn.tokenBSlippage), //uint amountBMin,
            address(this), //address to,
            block.timestamp + 1800 //uint deadline - give time buffer
        );
    }

    function addLiquidity(address router_, LPToken memory _lpOut, uint _outTokenANeeded, uint _amountReceivedTokenB) internal returns (uint, uint, uint) {
        IERC20 _outTokenA = IERC20(_lpOut.tokenA);
        IERC20 _tokenB = IERC20(_lpOut.tokenB);

        uint amountAMin = applySlippage(_outTokenANeeded, _lpOut.tokenASlippage);
        uint amountBMin = applySlippage(_amountReceivedTokenB, _lpOut.tokenBSlippage);

        // approve token transfers to cover all possible scenarios
        _outTokenA.approve(router_, _outTokenANeeded);
        _tokenB.approve(router_, _amountReceivedTokenB);

        IPangolinRouter _router = IPangolinRouter(router_);

        // add the liquidity
        return _router.addLiquidity(
            _lpOut.tokenA, //address tokenA,
            _lpOut.tokenB, //address tokenB,
           _outTokenANeeded, //uint amountADesired,
            _amountReceivedTokenB, //uint amountBDesired,
            amountAMin, // uint amountAMin,
            amountBMin, // uint amountBMin,
            address(this), // address to,
            block.timestamp + 1800 // uint deadline - need to give time buffer
            );     
    }

    function editAcceptedToken(
        address lpContract,
        address tokenA,
        address tokenB,
        uint256 tokenASlippage,
        uint256 tokenBSlippage,
        bool allowDeposit,
        bool allowWithdraw,
        bool isPangolin) public onlyOwner {

        acceptedTokens[lpContract] = LPToken(
            tokenA,
            tokenB,
            tokenASlippage,
            tokenBSlippage,
            allowDeposit,
            allowWithdraw,
            isPangolin); 

        address _router;
        IERC20 _lp = IERC20(lpContract);

        if (isPangolin) {
            _router = _routerP;
        } else {
            _router = _routerT;
        }
        
        if (allowDeposit) {
            _lp.approve(_router, MAX_INT);
        } else {
            _lp.approve(_router, 0);
        }
    }   

    function applySlippage(uint amount, uint slippage) internal pure returns(uint) {
        return amount * (10000 - slippage) / 10000;
    }

    function flipPaused() public onlyOwner {
        paused = !paused;
    }

    function emergencyWithdraw() public onlyOwner {
        (bool success, ) = payable(owner()).call{ value: address(this).balance }("");
		require(success, "AVAX Transaction: Failed to transfer funds");
    }

    function emergencyWithdrawERC20(address _contract) public onlyOwner {
        IERC20 _token = IERC20(_contract);
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    function withdrawERC20(address _contract, address _to, uint256 _amount) public onlyOwner {
        IERC20 _token = IERC20(_contract);
        _token.transfer(_to, _amount);
    }

    receive() external payable {

	}

}