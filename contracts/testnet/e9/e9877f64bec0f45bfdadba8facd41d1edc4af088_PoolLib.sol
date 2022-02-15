/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-15
*/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File: contracts/interfaces/ITheNeighbours.sol


pragma solidity ^0.8.0;


// Interface for neighbour contract.
interface ITheNeighbours is IERC20Metadata {
    function specialTransfer(address from, address to, uint amount) external;
}
// File: contracts/interfaces/IJoeRouter01.sol


pragma solidity ^0.8.0;

interface IJoeRouter01 {
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
}

interface IJoeRouter02 is IJoeRouter01 {
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


// File: contracts/PoolLib.sol


pragma solidity ^0.8.0;



library PoolLib {
    using PoolLib for pool;

    struct pool {
        // Treasury pool
        address treasuryPool;
        uint256 treasuryPoolShare;
        uint256 treasuryTaxPoolShare;
        // NEIBR pool
        address NEIBRPool;
        uint256 NEIBRPoolShare;
        uint256 NEIBRTaxPoolShare;
        // Reward pool
        address rewardPool;
        uint256 rewardPoolShare;
        uint256 rewardTaxPoolShare;
        // Router setup.
        IJoeRouter02 uniswapV2Router;
        uint256 precisionValue;
        address neighbour;
    }

    // Method to update pool addresses
    // function setPool(
    //     pool storage self,
    //     // address _treasury,
    //     // address _NEIBR,
    //     // address _reward,
    //     // uint256 _treasuryPoolShare,
    //     // uint256 _NEIBRPoolShare,
    //     // uint256 _rewardPoolShare,
    //     // uint256 _treasuryTaxPoolShare,
    //     // uint256 _NEIBRTaxPoolShare,
    //     // uint256 _rewardTaxPoolShare,
    //     // address _router
    //     pool storage _pool
    // ) public {

    //     require(
    //         _pool.treasuryPoolShare + _pool.NEIBRPoolShare + _pool.rewardPoolShare ==
    //             100 * self.precisionValue,
    //         "TheProperty: Total shares must be 100%"
    //     );
    //     require(
    //         _pool.treasuryTaxPoolShare + _pool.NEIBRTaxPoolShare + _pool.rewardTaxPoolShare ==
    //             100 * self.precisionValue,
    //         "TheProperty: Total Tax shares must be 100%"
    //     );
    //     self = _pool;
    //     // self.treasuryPool = _treasury;
    //     // self.NEIBRPool = _NEIBR;
    //     // self.rewardPool = _reward;
    //     // self.treasuryPoolShare = _treasuryPoolShare;
    //     // self.NEIBRPoolShare = _NEIBRPoolShare;
    //     // self.rewardPoolShare = _rewardPoolShare;
    //     // self.treasuryTaxPoolShare = _treasuryTaxPoolShare;
    //     // self.NEIBRTaxPoolShare = _NEIBRTaxPoolShare;
    //     // self.rewardTaxPoolShare = _rewardTaxPoolShare;
    //     // self.uniswapV2Router = IJoeRouter02(_router);
    // }

    // Method to update precisionValue address
    function setPrecisionValue(pool storage self, uint256 _newValue) public {
        self.precisionValue = _newValue;
    }

    // Private method to swap NEIBR to AVAX and update the share
    function swapAndSendAVAX(
        pool storage self,
        uint256 tokenAmount,
        address to
    ) internal {
        address[] memory path = new address[](2);
        path[0] = self.neighbour;
        path[1] = self.uniswapV2Router.WAVAX();

        ITheNeighbours(self.neighbour).approve(
            address(self.uniswapV2Router),
            tokenAmount
        );

        self
            .uniswapV2Router
            .swapExactTokensForAVAXSupportingFeeOnTransferTokens(
                tokenAmount,
                0, // accept any amount of ETH
                path,
                to,
                block.timestamp
            );
    }

    // Private method to distribute rewrds at porperty purchase.
    function distributeInPoolsAtPurchase(pool storage self, uint256 _amount)
        public
    {
        // Calculate treasuy and NEIBR pool shares.
        uint256 _treasury = (_amount * self.treasuryPoolShare) /
            (100 * self.precisionValue);
        uint256 _NEIBR = (_amount * self.NEIBRPoolShare) /
            (100 * self.precisionValue);

        // Send amount in AVAX to treasury pool
        self.swapAndSendAVAX(_treasury, self.treasuryPool);

        ITheNeighbours _neighbour = ITheNeighbours(self.neighbour);
        // Send amount to _NEIBR pool
        _neighbour.transfer(self.NEIBRPool, _NEIBR);

        // Send remaining fund if rewardPool if isn't same.
        if (address(this) != self.rewardPool) {
            _neighbour.transfer(
                self.rewardPool,
                (_amount - _treasury - _NEIBR)
            );
        }
    }

    // Distribute reward while receiving tax
    function distributeInPoolsAtTax(pool storage self) public {
        uint256 _amount = msg.value;
        // Calculate treasuy and NEIBR pool shares.
        uint256 _treasury = (_amount * self.treasuryTaxPoolShare) /
            (100 * self.precisionValue);
        uint256 _NEIBR = (_amount * self.NEIBRTaxPoolShare) /
            (100 * self.precisionValue);

        // Send amount in AVAX to treasury pool
        payable(self.treasuryPool).transfer(_treasury);

        // Send amount to _NEIBR pool
        payable(self.NEIBRPool).transfer(_NEIBR);

        // Send remaining fund if rewardPool if isn't same.
        if (address(this) != self.rewardPool) {
            payable(self.rewardPool).transfer(_amount - _treasury - _NEIBR);
        }
    }

    // Set neighbour pool
    function setNeighbour(pool storage self, address _newAddress) public {
        self.neighbour = _newAddress;
    }
}