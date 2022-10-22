//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IERC20.sol";
import "./IRouter02.sol";

interface IMDB {
    function burn(uint256 amount) external;
}

contract Adjustor {
    // Token Address
    address private immutable token;

    // Address => Can Adjust
    mapping(address => bool) private canAdjust;

    // Liquidity Pool Address
    address private immutable LP;

    // Dead Wallet
    address private constant dead = 0x000000000000000000000000000000000000dEaD;

    // DEX Router
    IRouter02 private router;

    // Path
    address[] path;

    modifier onlyAdjustor() {
        require(canAdjust[msg.sender], "Only Adjustors");
        _;
    }

    constructor(address token_) {
        // token
        token = token_;

        // permission to adjust
        canAdjust[msg.sender] = true;

        address currentRouter = 0xd7f655E3376cE2D7A2b08fF01Eb3B1023191A901;

        // DEX Router
        router = IRouter02(currentRouter);

        // Liquidity Pool Token
        LP = IFactoryV2(router.factory()).getPair(token_, router.WAVAX());

        // swap path
        path = new address[](2);
        path[0] = router.WAVAX();
        path[1] = token_;
    }

    function setAdjustor(address adjustor_, bool canAdjust_)
        external
        onlyAdjustor
    {
        canAdjust[adjustor_] = canAdjust_;
    }

    function adjust(uint256 amount, address destination) external onlyAdjustor {
        _adjust(amount, destination);
    }

    function withdrawLP() external onlyAdjustor {
        IERC20(LP).transfer(msg.sender, lpBalance());
    }

    function withdrawToken() external onlyAdjustor {
        IERC20(token).transfer(
            msg.sender,
            IERC20(token).balanceOf(address(this))
        );
    }

    function withdraw() external onlyAdjustor {
        (bool s, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(s);
    }

    receive() external payable {}

    function _adjust(uint256 amount, address destination) internal {
        // Approve Router For Amount
        IERC20(LP).approve(address(router), amount);

        // Remove `Amount` Liquidity
        router.removeLiquidityAVAXSupportingFeeOnTransferTokens(
            token,
            amount,
            0,
            0,
            address(this),
            block.timestamp + 5000000
        );

        // Swap ETH Received For More Tokens
        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{
            value: address(this).balance
        }(0, path, address(this), block.timestamp + 300);

        // Forward All Tokens Received
        if (destination == dead) {
            IMDB(token).burn(IERC20(token).balanceOf(address(this)));
        } else {
            IERC20(token).transfer(
                destination,
                IERC20(token).balanceOf(address(this))
            );
        }
    }

    function lpBalance() public view returns (uint256) {
        return IERC20(LP).balanceOf(address(this));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    
    function symbol() external view returns(string memory);
    
    function name() external view returns(string memory);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);
    
    /**
     * @dev Returns the number of decimal places
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IFactoryV2 {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address lpPair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address lpPair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address lpPair);
}

interface IV2Pair {
    function factory() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

interface IRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IRouter02 is IRouter01 {
    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);
}