// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function transferFrom(
        address sender,
        address recipient,
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../interface/IERC20.sol";

library SafeTransfer {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool s, ) = address(token).call(
            abi.encodeWithSelector(
                IERC20.transferFrom.selector,
                from,
                to,
                value
            )
        );
        require(s, "safeTransferFrom failed");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool s, ) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, value)
        );
        require(s, "safeTransfer failed");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        (bool s, ) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, value)
        );
        require(s, "safeApprove failed");
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool s, ) = to.call{value: value}(new bytes(0));
        require(s, "safeTransferETH failed");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "./lib/SafeTransfer.sol";

interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IJoeCallee {
    function joeCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

library SafeMathJoe {
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}

interface IJoeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

interface IERC20Joe {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
}


interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

contract Sandwich {
    using SafeTransfer for IERC20Joe;
    using SafeMathJoe for uint256;

    // Authorized
    address internal immutable user;

    // transfer(address,uint256)
    bytes4 internal constant ERC20_TRANSFER_ID = 0xa9059cbb;

    // swap(uint256,uint256,address,bytes)
    bytes4 internal constant PAIR_SWAP_ID = 0x022c0d9f;

    constructor() {
        user = msg.sender;
    }

    // *** Receive profits from contract *** //
    function recoverERC20(address token) public {
        require(msg.sender == user, "shoo");
        IERC20Joe(token).transfer(
            msg.sender,
            IERC20Joe(token).balanceOf(address(this))
        );
    }

    function simulate(bytes calldata _buydata, bytes calldata _selldata)
        external
    {
        require(msg.sender == user, "shoo");
        address pair;
        address token;
        uint256 amountIn;
        uint256 amountOut;
        uint8 tokenOutNo;
        // Buy
        (pair, amountIn, amountOut, token, tokenOutNo) = abi.decode(
            _buydata,
            (address, uint256, uint256, address, uint8)
        );

        IERC20Joe(token).transfer(
            pair,
            amountIn
        );
        
        IJoePair(pair).swap(tokenOutNo == 0 ? amountOut: 0, tokenOutNo == 1 ? amountOut: 0, address(this), new bytes(0));

        // Sell
        (pair, amountIn, amountOut, token, tokenOutNo) = abi.decode(
            _selldata,
            (address, uint256, uint256, address, uint8)
        );

        IERC20Joe(token).transfer(
            pair,
            amountIn
        );
        
        IJoePair(pair).swap(tokenOutNo == 0 ? amountOut: 0, tokenOutNo == 1 ? amountOut: 0, address(this), new bytes(0));
    }

    function buy(bytes calldata _buydata)
        external
    {
        require(msg.sender == user, "shoo");
        address pair;
        address token;
        uint256 amountIn;
        uint256 amountOut;
        uint8 tokenOutNo;
        // Buy
        (pair, amountIn, amountOut, token, tokenOutNo) = abi.decode(
            _buydata,
            (address, uint256, uint256, address, uint8)
        );

        IERC20Joe(token).transfer(
            pair,
            amountIn
        );
        
        IJoePair(pair).swap(tokenOutNo == 0 ? amountOut: 0, tokenOutNo == 1 ? amountOut: 0, address(this), new bytes(0));
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) internal pure returns (uint amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function sell(bytes calldata _buydata)
        external
    {
        require(msg.sender == user, "shoo");
        address pair;
        address token;
        uint8 tokenOutNo;
        // Buy
        (pair, token, tokenOutNo) = abi.decode(
            _buydata,
            (address, address, uint8)
        );

        IERC20Joe fromToken = IERC20Joe(token);
        IJoePair pairSandwich = IJoePair(pair);
        uint256 reserveIn;
        uint256 reserveOut;
        uint256 balance = fromToken.balanceOf(address(this));
        (reserveIn, reserveOut, ) = pairSandwich.getReserves();

        fromToken.transfer(
            pair,
            balance
        );

        uint256 amountOut = getAmountOut(balance, tokenOutNo == 0 ? reserveOut : reserveIn, tokenOutNo == 0 ? reserveIn: reserveOut);
        
        IJoePair(pair).swap(tokenOutNo == 0 ? amountOut: 0, tokenOutNo == 1 ? amountOut: 0, address(this), new bytes(0));
    }
    /*
        Fallback function where you do your frontslice and backslice

        NO UNCLE BLOCK PROTECTION IN PLACE, USE AT YOUR OWN RISK

        Payload structure (abi encodePacked)

        - token: address        - Address of the token you're swapping
        - pair: address         - Univ2 pair you're sandwiching on
        - amountIn: uint128     - Amount you're giving via swap
        - amountOut: uint128    - Amount you're receiving via swap
        - tokenOutNo: uint8     - Is the token you're giving token0 or token1? (On univ2 pair)

        Note: This fallback function generates some dangling bits
    */
    fallback() external {
        // Assembly cannot read immutable variables
        address memUser = user;

        assembly {
            // You can only access teh fallback function if you're authorized
            if iszero(eq(caller(), memUser)) {
                // Ohm (3, 3) makes your code more efficient
                // WGMI
                revert(3, 3)
            }

            // Extract out teh variables
            // We don't have function signatures sweet saving EVEN MORE GAS

            // bytes20
            let token := shr(96, calldataload(0x00))
            // bytes20
            let pair := shr(96, calldataload(0x14))
            // uint128
            let amountIn := shr(128, calldataload(0x28))
            // uint128
            let amountOut := shr(128, calldataload(0x38))
            // uint8
            let tokenOutNo := shr(248, calldataload(0x48))

            // **** calls token.transfer(pair, amountIn) ****

            // transfer function signature
            mstore(0x7c, ERC20_TRANSFER_ID)
            // destination
            mstore(0x80, pair)
            // amount
            mstore(0xa0, amountIn)

            let s1 := call(sub(gas(), 5000), token, 0, 0x7c, 0x44, 0, 0)
            if iszero(s1) {
                // WGMI
                revert(3, 3)
            }

            // ************
            /* 
                calls pair.swap(
                    tokenOutNo == 0 ? amountOut : 0,
                    tokenOutNo == 1 ? amountOut : 0,
                    address(this),
                    new bytes(0)
                )
            */

            // swap function signature
            mstore(0x7c, PAIR_SWAP_ID)
            // tokenOutNo == 0 ? ....
            switch tokenOutNo
            case 0 {
                mstore(0x80, amountOut)
                mstore(0xa0, 0)
            }
            case 1 {
                mstore(0x80, 0)
                mstore(0xa0, amountOut)
            }
            // address(this)
            mstore(0xc0, address())
            // empty bytes
            mstore(0xe0, 0x80)

            let s2 := call(sub(gas(), 5000), pair, 0, 0x7c, 0xa4, 0, 0)
            if iszero(s2) {
                revert(3, 3)
            }
        }
    }
}