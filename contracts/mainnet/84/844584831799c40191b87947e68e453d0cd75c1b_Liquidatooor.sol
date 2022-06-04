/**
 *Submitted for verification at snowtrace.io on 2022-06-04
*/

pragma solidity ^0.8.12;

interface ERC3156FlashBorrowerInterface {
    /**
     * @dev Receive a flash loan.
     * @param initiator The initiator of the loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param fee The additional amount of tokens to repay.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     * @return The keccak256 hash of "ERC3156FlashBorrower.onFlashLoan"
     */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns (bytes32);
}

interface IJToken {
    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address JTokenCollateral
    ) external returns (uint256);

    function underlying() external view returns (address);

    function redeem(uint256 redeemTokens) external returns (uint256);

}

interface Joetroller {
    function isMarketListed(address jTokenAddress) external view returns (bool);
}

interface IJoeRouter02 {

        function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


interface ERC3156FlashLenderInterface {
    /**
     * @dev The amount of currency available to be lent.
     * @param token The loan currency.
     * @return The amount of `token` that can be borrowed.
     */
    function maxFlashLoan(address token) external view returns (uint256);

    /**
     * @dev The fee to be charged for a given loan.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @return The amount of `token` to be charged for the loan, on top of the returned principal.
     */
    function flashFee(address token, uint256 amount) external view returns (uint256);

    /**
     * @dev Initiate a flash loan.
     * @param receiver The receiver of the tokens in the loan, and the receiver of the callback.
     * @param token The loan currency.
     * @param amount The amount of tokens lent.
     * @param data Arbitrary data structure, intended to contain user-defined parameters.
     */
    function flashLoan(
        ERC3156FlashBorrowerInterface receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external;
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint256 amount) external returns (bool);
}


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

/* 
Contract provides ability for the owner to liquidate underwater accounts by calling liquidateWithFlashLoan
*/
contract Liquidatooor is ERC3156FlashBorrowerInterface, Ownable{

    address public joetroller;
    address public joeRouter;
 
    constructor (address _joetroller, address _joeRouter)
    {
        //TJ contracts to interact with
        joetroller = _joetroller;
        joeRouter = _joeRouter;
    }

    struct TokenPair{
        address jToken;
        address underlying;
    } //Helps with stack to deep issues

    function withdrawToken(address _tokenContract) external onlyOwner
    {
        IERC20 tokenContract = IERC20(_tokenContract);
        uint256 amount = tokenContract.balanceOf(address(this));
        bool success = tokenContract.transfer(address(msg.sender), amount);
        require(success, "Failed to send Token");
    } //To withdraw tokens from contract

    function setJoeRouter(address _joeRouter) external onlyOwner
    {
        joeRouter = _joeRouter;
    } //Incase the JoeRouter changes

    /*
    Liquidates an underwater account, using TJ implementation of ERC3156 flash loans
    */
    function liquidateWithFlashLoan(
        address flashLoanLender,
        uint256 repayAmount, //Amount of underlying token to repay
        address repayJToken,
        address accountToLiquidate,
        address collateralJToken
    ) external onlyOwner {
        TokenPair memory  repayPair = TokenPair(repayJToken, IJToken(repayJToken).underlying());  //repay jToken and underlying
        TokenPair memory collateralPair = TokenPair(collateralJToken, IJToken(collateralJToken).underlying()); //collateral jToken and underlying
        TokenPair memory flashPair = TokenPair(flashLoanLender, IJToken(flashLoanLender).underlying()); //flash loaned jToken and underlying 
        address[] memory path = new address[](2); //For JoeRouter
        path[0] = flashPair.underlying;
        path[1] = repayPair.underlying;

        //Work out how much needed to borrow in flashloan (Borrowed token must be swapped to other tokens in order to prevent re-entrancy)
        uint256 borrowAmount = IJoeRouter02(joeRouter).getAmountsIn(
            repayAmount,
            path
            )[0];

        // console.log("Need ",borrowAmount,IERC20(flashPair.underlying).symbol());
        // console.log("to repay ",repayAmount, IERC20(repayPair.underlying).symbol());
        
        //Perform flashloan
        bytes memory data = abi.encode(repayAmount, repayPair, accountToLiquidate, collateralPair); //Encode params to pass to flashloan callback
        ERC3156FlashLenderInterface(flashLoanLender).flashLoan(this, address(this), borrowAmount, data); //Initiator address used as second argument for TJ flash loans. On calling this the onFlashLoan function is called, where the liquidation is performed using the flash loaned funds.

        //log balance/profit
        // console.log("Remaining token balance ",IERC20(flashPair.underlying).balanceOf(address(this)),IERC20(flashPair.underlying).symbol());
    }

    /*
    Callback function called after flashloan borrowed. Performs the following steps: 
    - Swaps flashloaned token to repay token,
    - Performs liquidation using repay token, seizing collateral as a jToken
    - Redeems underlying token for the seized jToken collateral
    - Swaps this underlying token back to flashloaned token so that the flashloan can be repayed
    */
    function onFlashLoan(
        address initiator,
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external returns(bytes32){
        //Checks
        require(Joetroller(joetroller).isMarketListed(msg.sender), "untrusted message sender");
        require(initiator == address(this), "FlashBorrower: Untrusted loan initiator");

        address[] memory path = new address[](2); //Used for JoeRouter swaps
        uint256[] memory amounts; //Used for JoeRouter swaps
        (uint256 repayAmount, TokenPair memory repayPair, address accountToLiquidate, TokenPair memory collateralPair) = 
            abi.decode(data, (uint256,TokenPair,address,TokenPair)); //Params from liquidate fcn

        IERC20(token).approve(joeRouter, amount); //Approve borrowed token for swap
        IERC20(token).approve(msg.sender, amount + fee); //Approve borrowed token for repaying to flashloanlender
        IERC20(repayPair.underlying).approve(repayPair.jToken, repayAmount); //Approve the repay token to repay debt to the lender 

        //Useful debug output
        // console.log("Borrowed ",amount , IERC20(token).symbol());
        // console.log("to liquidate",accountToLiquidate); 
        // console.log("using ", IERC20(repayPair.underlying).symbol());
        // console.log("seizing ", IERC20(collateralPair.jToken).symbol());

        //Swap flashloan token to account debt underlying token
        path[0] = token;
        path[1] = repayPair.underlying;
        IJoeRouter02(joeRouter).swapTokensForExactTokens(
            repayAmount,
            amount,
            path,    
            address(this),
            block.timestamp);
        // console.log("After swap ready to repay ", IERC20(IJToken(repayPair.jToken).underlying()).balanceOf(address(this)),IERC20(repayPair.underlying).symbol());

        //Liquidate the account, seizing the jToken as collateral
        uint256 returnCode_liq = IJToken(repayPair.jToken).liquidateBorrow(
            accountToLiquidate,
            repayAmount,
            collateralPair.jToken);
        // console.log("Seized_JToken ",IERC20(collateralPair.jToken).balanceOf(address(this)));
        require(returnCode_liq == 0,"Bad return code from liquidation"); //Check liquidation was successfil

        //Redeem the seized jTokens for the underlying tokens
        uint256 returnCode_redeem = IJToken(collateralPair.jToken).redeem(
            IERC20(collateralPair.jToken).balanceOf(address(this))
            );
        require(returnCode_redeem == 0,"Bad return code from redeem"); //Check redeem was successful

        uint256 seizedBalance = IERC20(collateralPair.underlying).balanceOf(address(this)); //Find how much underlying we recieved
        // console.log("Redeemed ",seizedBalance);   

        //Swap the underlying token back to the flashloaned token so we can repay
        path[0] = collateralPair.underlying;
        path[1] = token;
        amounts = IJoeRouter02(joeRouter).getAmountsOut(
            seizedBalance,
            path
            ); 
        // console.log("Borrowed token after swap",amounts[1]);
        IERC20(collateralPair.underlying).approve(joeRouter,seizedBalance); 
        IJoeRouter02(joeRouter).swapExactTokensForTokens(
            seizedBalance,
            amounts[1],//*(99*10^18)/(100*10^18), //slip 1% -doesn't work w/o this sometimes
            path,
            address(this),
            block.timestamp);
        //No need to check if we have made profit, if not flash loan repay will fail!
        return keccak256("ERC3156FlashBorrowerInterface.onFlashLoan");
    }

}