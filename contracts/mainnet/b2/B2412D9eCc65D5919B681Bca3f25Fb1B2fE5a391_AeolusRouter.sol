// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

/**
 * @title AeolusRouter
 * @author Pichaya Puttekulangkura
 * @custom:experimental This is an experimental contract.
 */

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IAeolusRouter.sol";
import "./interfaces/IExchangeRouter.sol";

import "../core/AeolusFactory.sol";
import "../core/AeolusPair.sol";

/**
 * @dev need to invest more than 0 USDT.e
 * @param amountInvest sent amount
 */

error InvalidAmount(uint256 amountInvest);
/**
 * @dev currentAmountInvest needs to be more than 0 USDT.e
 * @param currentAmountInvest current amount invest
 */
error NotInvestor(uint256 currentAmountInvest);

/**
 * @dev token addresses sent are identical
 * @param tokenAddress address of token
 */
error IdenticalTokenAddress(address tokenAddress);

contract AeolusRouter is IAeolusRouter, Ownable {
    using SafeERC20 for IERC20;
    /**
     * @dev AeolusFactory for creating and getting pair
     */
    AeolusFactory public FACTORY;

    /**
     * @dev Exchange Router for swapping, addding lp, removing lp
     */
    IExchangeRouter public EXCHANGE_ROUTER;

    address public exchangeFactory;
    address public USDTdotE;
    address public WAVAX;

    constructor(
        address _factory,
        address _router,
        address _USDTdotE,
        address _WAVAX,
        address _exchangeFactory
    ) {
        FACTORY = AeolusFactory(_factory);
        EXCHANGE_ROUTER = IExchangeRouter(_router);
        USDTdotE = _USDTdotE;
        WAVAX = _WAVAX;
        exchangeFactory = _exchangeFactory;
    }

    receive() external payable {}

    /**
     * @dev invest money into selected pair ID
     * @param pairID pair ID in AeolusFactory
     * @param amountInvest amount of money invest in USDT.e (6 decimals)
     * @return amountTokenALP amount of LP from tokenA and its stable pair
     * @return amountTokenBLP amount of LP from tokenB and its stable pair
     */
    function investPair(uint256 pairID, uint256 amountInvest) external returns (uint256 amountTokenALP, uint256 amountTokenBLP) {
        if (amountInvest == 0) revert InvalidAmount(amountInvest);
        IERC20(USDTdotE).safeTransferFrom(msg.sender, address(this), amountInvest);
        _approveTokenIfNeeded(USDTdotE);

        (, address tokenA, address tokenB, address aeolusPairAddress) = FACTORY.getPair(pairID);
        address tokenAStable = FACTORY.getStableAddressOfApprovedToken(tokenA);
        address tokenBStable = FACTORY.getStableAddressOfApprovedToken(tokenB);

        // Cannot use this - STACK TOO DEEP uint256 quarterAmountInvest = amountInvest / 4;
        uint256 amountTokenA = _swap(USDTdotE, amountInvest / 4, tokenA, address(this));
        uint256 amountTokenB = _swap(USDTdotE, amountInvest / 4, tokenB, address(this));

        // amountInvest is USDT.e which has 6 decimals, thus need to convert for AeolusPair LP
        uint256 amountInvest18Decimal = amountInvest * 10**12;

        uint256 amountTokenAStable = amountInvest / 4;
        uint256 amountTokenBStable = amountInvest / 4;
        if (tokenAStable != USDTdotE) {
            amountTokenAStable = _swap(USDTdotE, amountInvest / 4, tokenAStable, address(this));
        }

        if (tokenBStable != USDTdotE) {
            amountTokenBStable = _swap(USDTdotE, amountInvest / 4, tokenBStable, address(this));
        }

        _approveTokenIfNeeded(tokenA);
        _approveTokenIfNeeded(tokenB);
        _approveTokenIfNeeded(tokenAStable);
        _approveTokenIfNeeded(tokenBStable);

        (, , amountTokenALP) = EXCHANGE_ROUTER.addLiquidity(tokenA, tokenAStable, amountTokenA, amountTokenAStable, 0, 0, aeolusPairAddress, block.timestamp);
        (, , amountTokenBLP) = EXCHANGE_ROUTER.addLiquidity(tokenB, tokenBStable, amountTokenB, amountTokenBStable, 0, 0, aeolusPairAddress, block.timestamp);

        address pairALPAddress = _pairFor(exchangeFactory, tokenA, tokenAStable);
        address pairBLPAddress = _pairFor(exchangeFactory, tokenB, tokenBStable);

        // Cannot use amountInvest for quarterAmountInvest - STACK TOO DEEP
        AeolusPair(aeolusPairAddress).addAmountLPInvest(amountTokenALP, amountTokenBLP, pairALPAddress, pairBLPAddress, amountInvest18Decimal, msg.sender);
    }

    /**
     * @dev redeem invested money
     * @param pairID pair ID in AeolusFactory
     */
    function redeemPair(uint256 pairID) external {
        (, address tokenA, address tokenB, address aeolusPairAddress) = FACTORY.getPair(pairID);
        (uint256 pair0LP, uint256 pair1LP, address addressPair0LP, address addressPair1LP, uint256 amountInvest) = AeolusPair(aeolusPairAddress)
            .getAmountLPInvest(msg.sender);

        if (amountInvest == 0) revert NotInvestor({currentAmountInvest: amountInvest});

        address tokenAStable = FACTORY.getStableAddressOfApprovedToken(tokenA);
        address tokenBStable = FACTORY.getStableAddressOfApprovedToken(tokenB);
        IERC20(addressPair0LP).safeTransferFrom(aeolusPairAddress, address(this), pair0LP);
        IERC20(addressPair1LP).safeTransferFrom(aeolusPairAddress, address(this), pair1LP);
        _approveTokenIfNeeded(addressPair0LP);
        _approveTokenIfNeeded(addressPair1LP);

        // Quick solution - STACK TOO DEEP
        (, address tokenA2, address tokenB2, ) = FACTORY.getPair(pairID);

        (uint256 amountTokenA, uint256 amountTokenAStable) = EXCHANGE_ROUTER.removeLiquidity(
            tokenA2,
            tokenAStable,
            pair0LP,
            0,
            0,
            address(this),
            block.timestamp
        );
        (uint256 amountTokenB, uint256 amountTokenBStable) = EXCHANGE_ROUTER.removeLiquidity(
            tokenB2,
            tokenBStable,
            pair1LP,
            0,
            0,
            address(this),
            block.timestamp
        );

        uint256 amountUSDTdoteRedeem = _swap(tokenA2, amountTokenA, USDTdotE, address(this)) + _swap(tokenB2, amountTokenB, USDTdotE, address(this));
        if (tokenAStable == USDTdotE) {
            amountUSDTdoteRedeem = amountUSDTdoteRedeem + amountTokenAStable;
        } else {
            amountUSDTdoteRedeem = amountUSDTdoteRedeem + _swap(tokenAStable, amountTokenAStable, USDTdotE, address(this));
        }

        if (tokenBStable == USDTdotE) {
            amountUSDTdoteRedeem = amountUSDTdoteRedeem + amountTokenAStable;
        } else {
            amountUSDTdoteRedeem = amountUSDTdoteRedeem + _swap(tokenBStable, amountTokenBStable, USDTdotE, address(this));
        }
        AeolusPair(aeolusPairAddress).removeAmountLPInvest(msg.sender);
        IERC20(USDTdotE).safeTransfer(msg.sender, amountUSDTdoteRedeem);
    }

    /**
     * @dev PRIVATE function for sorting token by address
     * @param tokenA address of tokenA
     * @param tokenB address of tokenB
     * @return token0 address of sorted token0
     * @return token1 address of sorted token1
     */
    function sortTokens(address tokenA, address tokenB) private pure returns (address token0, address token1) {
        if (tokenA == tokenB) revert IdenticalTokenAddress(tokenA);
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) revert ZeroAddress(token0);
    }

    /**
     * @dev PRIVATE function for getting address of LP pair
     * @param factory address of exchange factory
     * @param tokenA address of tokenA
     * @param tokenB address of tokenB
     * @return pair LP address of tokenA and tokenB
     */
    function _pairFor(
        address factory,
        address tokenA,
        address tokenB
    ) private pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            hex"0bbca9af0511ad1a1da383135cf3a8d2ac620e549ef9f6ae3a4c33c2fed0af91" // init code fuji
                        )
                    )
                )
            )
        );
    }

    /**
     * @dev PRIVATE function for approving token spending
     * @param token address of token
     */
    function _approveTokenIfNeeded(address token) private {
        if (IERC20(token).allowance(address(this), address(EXCHANGE_ROUTER)) == 0) {
            IERC20(token).approve(address(EXCHANGE_ROUTER), type(uint256).max);
        }
    }

    /**
     * @dev PRIVATE function for swapping
     * @param _from address of token to swap
     * @param amountInvest amount of token to swap
     * @param _to address of token to get
     * @param receiver address to send swapped token to
     * @return amount of token to get
     */
    function _swap(
        address _from,
        uint256 amountInvest,
        address _to,
        address receiver
    ) private returns (uint256) {
        address[] memory path;

        path = new address[](3);
        path[0] = _from;
        path[1] = WAVAX;
        path[2] = _to;

        uint256[] memory amounts = EXCHANGE_ROUTER.swapExactTokensForTokens(amountInvest, 0, path, receiver, block.timestamp);
        return uint256(amounts[amounts.length - 1]);
    }

    /**
     * @dev ADMIN function for updating Exchange Router address
     */
    function updateExchangeRouter(address _router) external onlyOwner {
        EXCHANGE_ROUTER = IExchangeRouter(_router);
    }

    /**
     * @dev ADMIN function for updating Exchange Factory address
     */
    function updateExchangeFactory(address _exchangeFactory) external onlyOwner {
        exchangeFactory = _exchangeFactory;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

interface IAeolusRouter {
    function USDTdotE() external view returns (address);

    function WAVAX() external view returns (address);

    function exchangeFactory() external view returns (address);

    function investPair(uint256 pairID, uint256 amount) external returns (uint256 tokenALP, uint256 tokenBLP);

    function redeemPair(uint256 pairID) external;

    function updateExchangeFactory(address _exchangeFactory) external;

    function updateExchangeRouter(address _router) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

interface IExchangeRouter {
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

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

/**
 * @title AeolusFactory
 * @author Pichaya Puttekulangkura
 * @custom:experimental This is an experimental contract.
 */

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IAeolusFactory.sol";
import "./AeolusPair.sol";

/**
 * @dev token needs to be approved
 * @param tokenSymbol symbol of token
 */
error TokenNotApproved(string tokenSymbol);

/**
 * @dev token is already approved
 * @param tokenSymbol symbol of token
 * @param tokenAddress address of token
 */
error TokenAlreadyApproved(string tokenSymbol, address tokenAddress);

/**
 * @dev token has no stable pair
 * @param tokenSymbol symbol of token
 */
error TokenHasNoStablePair(string tokenSymbol);

/**
 * @dev address sent is address(0)
 * @param tokenAddress sent token address
 */
error ZeroAddress(address tokenAddress);

/**
 * @dev token symbols sent are identical
 * @param tokenSymbol symbol of token
 */
error IdenticalTokenSymbol(string tokenSymbol);

contract AeolusFactory is IAeolusFactory, ReentrancyGuard, Ownable {
    event PairCreated(string indexed pairSymbol, uint256 id);

    struct ApprovedToken {
        string tokenSymbol;
        address tokenAddress;
    }

    ApprovedToken[] public approvedTokens;

    mapping(string => uint256) public symbolToApprovedTokenID;

    struct StableToken {
        string stableSymbol;
        address stableAddress;
    }

    StableToken[] public stableTokens;
    mapping(string => uint256) public symbolToStableTokenID;

    mapping(uint256 => uint256) public approvedTokenIDToStableTokenID;
    mapping(address => address) public addressApprovedTokenToAddressStableToken;

    struct Pair {
        string name;
        address token0;
        address token1;
        address aeolusPairAddress;
    }
    Pair[] public pairs;
    mapping(string => uint256) public nameToPairID;

    /**
     * @dev make the arrays start from index 1 since mapping will always return 0 if DNE
     */
    constructor() {
        approvedTokens.push(ApprovedToken("BaseApprovedToken", address(0)));
        stableTokens.push(StableToken("BaseStableToken", address(0)));
        pairs.push(Pair("BasePair", address(0), address(0), address(0)));
    }

    /**
     * @dev get created AeolusPair by poolID
     * @param poolID poolID of created AeolusPair
     * @return name name of the created AeolusPair
     * @return tokenA address of tokenA
     * @return tokenB address of tokenB
     * @return aeolusPairAddress address of created AeolusPair
     */
    function getPair(uint256 poolID)
        external
        view
        returns (
            string memory name,
            address tokenA,
            address tokenB,
            address aeolusPairAddress
        )
    {
        return (pairs[poolID].name, pairs[poolID].token0, pairs[poolID].token1, pairs[poolID].aeolusPairAddress);
    }

    /**
     * @dev get number of created AeolusPair
     */
    function getNumberOfPools() external view returns (uint256 numberOfPools) {
        return pairs.length - 1;
    }

    /**
     * @dev get number of approved tokens
     */
    function getNumberOfApprovedTokens() external view returns (uint256 numberOfApprovedTokens) {
        return approvedTokens.length - 1;
    }

    /**
     * @dev get number of approved stable tokens
     */
    function getNumberOfStableTokens() external view returns (uint256 numberOfStableTokens) {
        return stableTokens.length - 1;
    }

    /**
     * @dev get stable token's symbol and address of approved token
     * @param _symbolApprovedToken symbol of approved token
     * @return stableSymbol symbol of stable token of the approved token
     * @return stableAddress address of stable token of the approved token
     */
    function getStableTokenOfApprovedToken(string memory _symbolApprovedToken) external view returns (string memory stableSymbol, address stableAddress) {
        uint256 approvedTokenID = symbolToApprovedTokenID[_symbolApprovedToken];
        uint256 stableTokenID = approvedTokenIDToStableTokenID[approvedTokenID];
        StableToken memory stableToken = stableTokens[stableTokenID];
        return (stableToken.stableSymbol, stableToken.stableAddress);
    }

    /**
     * @dev get stable token's address of approved token
     * @param approvedToken address of approved token
     * @return stableAddress address of stable token of approved token
     */
    function getStableAddressOfApprovedToken(address approvedToken) external view returns (address stableAddress) {
        return addressApprovedTokenToAddressStableToken[approvedToken];
    }

    /**
     * @dev ADMIN function for adding approved token
     * @param _symbolApprovedToken symbol of approved token
     * @param _address address of approved token
     */
    function addApprovedToken(string memory _symbolApprovedToken, address _address) external onlyOwner {
        if (symbolToApprovedTokenID[_symbolApprovedToken] != 0) revert TokenAlreadyApproved(_symbolApprovedToken, _address);
        if (_address == address(0)) revert ZeroAddress(_address);

        ApprovedToken memory newApprovedToken = ApprovedToken(_symbolApprovedToken, _address);
        symbolToApprovedTokenID[_symbolApprovedToken] = approvedTokens.length;
        approvedTokens.push(newApprovedToken);
    }

    /**
     * @dev ADMIN function for adding stable token
     * @param _symbolStableToken symbol of stable token
     * @param _address address of stable token
     */
    function addStableToken(string memory _symbolStableToken, address _address) external onlyOwner {
        if (symbolToStableTokenID[_symbolStableToken] != 0) revert TokenAlreadyApproved(_symbolStableToken, _address);
        if (_address == address(0)) revert ZeroAddress(_address);

        StableToken memory newStableToken = StableToken(_symbolStableToken, _address);
        symbolToStableTokenID[_symbolStableToken] = stableTokens.length;
        stableTokens.push(newStableToken);
    }

    /**
     * @dev ADMIN function for linking or updating pair between approved token and stable token
     * @param _symbolApprovedToken symbol of approved token
     * @param _symbolStableToken symbol of stable token
     */
    function linkOrUpdateApprovedTokenToStableToken(string memory _symbolApprovedToken, string memory _symbolStableToken) external onlyOwner {
        if (symbolToApprovedTokenID[_symbolApprovedToken] == 0) revert TokenNotApproved(_symbolApprovedToken);
        if (symbolToStableTokenID[_symbolStableToken] == 0) revert TokenNotApproved(_symbolStableToken);

        uint256 approvedTokenID = symbolToApprovedTokenID[_symbolApprovedToken];
        uint256 stableTokenID = symbolToStableTokenID[_symbolStableToken];

        ApprovedToken memory approvedToken = approvedTokens[approvedTokenID];
        StableToken memory stableToken = stableTokens[stableTokenID];

        addressApprovedTokenToAddressStableToken[approvedToken.tokenAddress] = stableToken.stableAddress;
        approvedTokenIDToStableTokenID[approvedTokenID] = stableTokenID;
    }

    /**
     * @dev ADMIN function for creating AeolusPair
     * @param _symbolTokenA symbol of approved tokenA
     * @param _symbolTokenB symbol of approved tokenB
     * @param _aeolusRouter address of AeolusRouter
     */
    function createPair(
        string memory _symbolTokenA,
        string memory _symbolTokenB,
        address _aeolusRouter
    ) external onlyOwner nonReentrant returns (AeolusPair newAeolusPair) {
        if (keccak256(abi.encodePacked(_symbolTokenA)) == keccak256(abi.encodePacked(_symbolTokenB))) revert IdenticalTokenSymbol(_symbolTokenA);
        // Check whether the token has been approved yet
        uint256 approvedTokenAID = symbolToApprovedTokenID[_symbolTokenA];
        uint256 approvedTokenBID = symbolToApprovedTokenID[_symbolTokenB];

        if (approvedTokenAID == 0) revert TokenNotApproved(_symbolTokenA);
        if (approvedTokenBID == 0) revert TokenNotApproved(_symbolTokenB);

        address approvedTokenAAddress = approvedTokens[approvedTokenAID].tokenAddress;
        address approvedTokenBAddress = approvedTokens[approvedTokenBID].tokenAddress;

        StableToken memory stableTokenOfA = stableTokens[(approvedTokenIDToStableTokenID[approvedTokenAID])];
        StableToken memory stableTokenOfB = stableTokens[(approvedTokenIDToStableTokenID[approvedTokenBID])];

        if (approvedTokenIDToStableTokenID[approvedTokenAID] == 0) revert TokenHasNoStablePair(_symbolTokenA);
        if (approvedTokenIDToStableTokenID[approvedTokenBID] == 0) revert TokenHasNoStablePair(_symbolTokenB);

        address addressOftablePairOfA = stableTokenOfA.stableAddress;
        address addresOfStableTokenOfB = stableTokenOfB.stableAddress;

        uint256 pairID = pairs.length;
        string memory pairName = string(abi.encodePacked(Strings.toString(pairID), "-AEOLUS"));
        string memory pairSymbol = string(abi.encodePacked(_symbolTokenA, "-", _symbolTokenB));

        newAeolusPair = new AeolusPair(_aeolusRouter, pairName, pairSymbol);
        newAeolusPair.initialize(approvedTokenAAddress, approvedTokenBAddress, addressOftablePairOfA, addresOfStableTokenOfB);

        Pair memory newPair = Pair(
            pairSymbol,
            approvedTokens[approvedTokenAID].tokenAddress,
            approvedTokens[approvedTokenBID].tokenAddress,
            address(newAeolusPair)
        );
        nameToPairID[pairSymbol] = pairID;
        pairs.push(newPair);

        emit PairCreated(pairSymbol, pairID);
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

/**
 * @title AeolusPair
 * @author Pichaya Puttekulangkura
 * @custom:experimental This is an experimental contract.
 */

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IAeolusPair.sol";

/**
 * @dev only AeolusFactory is permitted to call this function
 * @param sender tx sender
 */
error NotAeolusFactory(address sender);

/**
 * @dev only AeolusRouter is permitted to call this function
 * @param sender tx sender
 */
error NotAeolusRouter(address sender);

contract AeolusPair is ERC20, IAeolusPair, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public aeolusFactory;
    address public aeolusRouter;

    address public token0;
    address public token1;
    address public stable0;
    address public stable1;

    address public addressPair0LP;
    address public addressPair1LP;

    mapping(address => uint256) public addressToPair0LP;
    mapping(address => uint256) public addressToPair1LP;
    mapping(address => uint256) public addressToAmountInvest;

    constructor(
        address _aeolusRouter,
        string memory _pairName,
        string memory _pairSymbol
    ) ERC20(_pairName, _pairSymbol) {
        aeolusFactory = msg.sender;
        aeolusRouter = _aeolusRouter;
    }

    event Mint(address indexed sender, uint256 amountInvest);
    event Burn(address indexed sender, uint256 currentAmountInvest);

    /**
     * @dev called once by AeolusFactory at time of deployment
     * @param _token0 address of token0
     * @param _token0 address of token1
     * @param _stable0 address of stable pair of token0
     * @param _stable0 address of stable pair of token1
     */
    function initialize(
        address _token0,
        address _token1,
        address _stable0,
        address _stable1
    ) external nonReentrant {
        if (msg.sender != aeolusFactory) revert NotAeolusFactory(msg.sender);
        token0 = _token0;
        token1 = _token1;
        stable0 = _stable0;
        stable1 = _stable1;
    }

    /**
     * @dev called by AeolusRouter to update invest data of msg.sender and mint Aeolus Token
     * @param pair0LP amount of LP from token0 and its stable pair that was added
     * @param pair1LP amount of LP from token1 and its stable pair that was added
     * @param _addressPair0LP address of LP pair 0
     * @param _addressPair1LP address of LP pair 1
     * @param amountInvest amount invested in USDT.e
     * @param investor address of investor
     */
    function addAmountLPInvest(
        uint256 pair0LP,
        uint256 pair1LP,
        address _addressPair0LP,
        address _addressPair1LP,
        uint256 amountInvest,
        address investor
    ) external {
        if (msg.sender != aeolusRouter) revert NotAeolusRouter(msg.sender);
        addressToPair0LP[investor] = pair0LP;
        addressToPair1LP[investor] = pair1LP;
        addressToAmountInvest[investor] = amountInvest;

        IERC20(_addressPair0LP).approve(aeolusRouter, type(uint256).max);
        IERC20(_addressPair1LP).approve(aeolusRouter, type(uint256).max);
        addressPair0LP = _addressPair0LP;
        addressPair1LP = _addressPair1LP;

        mint(investor, amountInvest);
    }

    /**
     * @dev get the amount of invested money and LP
     * @param investor address of the investor
     * @return pair0LP amount of LP from token0 and its stable pair that was added
     * @return pair1LP amount of LP from token1 and its stable pair that was added
     * @return _addressPair0LP address of LP pair 0
     * @return _addressPair1LP address of LP pair 1
     * @return amountInvest amount invested in USDT.e
     */
    function getAmountLPInvest(address investor)
        external
        view
        returns (
            uint256 pair0LP,
            uint256 pair1LP,
            address _addressPair0LP,
            address _addressPair1LP,
            uint256 amountInvest
        )
    {
        return (addressToPair0LP[investor], addressToPair1LP[investor], addressPair0LP, addressPair1LP, addressToAmountInvest[investor]);
    }

    /**
     * @dev called by AeolusRouter to update the amount of invested money and LP of investor to zero
     * @param investor address of the investor
     */
    function removeAmountLPInvest(address investor) external {
        if (msg.sender != aeolusRouter) revert NotAeolusRouter(msg.sender);
        burn(investor, addressToAmountInvest[investor]);
        addressToPair0LP[investor] = 0;
        addressToPair1LP[investor] = 0;
        addressToAmountInvest[investor] = 0;
    }

    /**
     * @dev internal function call for minting Aeolus Token
     * @param to address that Aeolus Token will be sent to
     * @param amountInvest amount of Aeolus Token that will be minted
     */
    function mint(address to, uint256 amountInvest) internal nonReentrant returns (uint256) {
        _mint(to, amountInvest);
        emit Mint(msg.sender, amountInvest);
        return amountInvest;
    }

    /**
     * @dev internal function call for burning Aeolus Token
     * @param to address of Aeolus Token holder
     * @param currentAmountInvest amount of Aeolus Token that will be burned
     */
    function burn(address to, uint256 currentAmountInvest) internal nonReentrant returns (uint256) {
        _burn(to, currentAmountInvest);
        emit Burn(msg.sender, currentAmountInvest);
        return currentAmountInvest;
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

interface IAeolusFactory {
    function getPair(uint256)
        external
        view
        returns (
            string memory,
            address,
            address,
            address
        );

    function getNumberOfPools() external view returns (uint256);

    function getNumberOfApprovedTokens() external view returns (uint256);

    function getNumberOfStableTokens() external view returns (uint256);

    function getStableTokenOfApprovedToken(string memory) external view returns (string memory, address); // function createPair(string memory _tokenSymbolA, string memory _tokenSymbolB) external returns (string memory pairName);

    function getStableAddressOfApprovedToken(address) external view returns (address);

    function addApprovedToken(string memory, address) external;

    function addStableToken(string memory, address) external;

    function linkOrUpdateApprovedTokenToStableToken(string memory, string memory) external;

  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.9;

interface IAeolusPair {
    function aeolusFactory() external view returns (address);

    function aeolusRouter() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function stable0() external view returns (address);

    function stable1() external view returns (address);

    function addressPair0LP() external view returns (address);

    function addressPair1LP() external view returns (address);

    function initialize(
        address,
        address,
        address,
        address
    ) external;

    function addAmountLPInvest(
        uint256 pair0LP,
        uint256 pair1LP,
        address _addressPair0LP,
        address _addressPair1LP,
        uint256 amountInvest,
        address investor
    ) external;

    function getAmountLPInvest(address investor)
        external
        returns (
            uint256 pair0LP,
            uint256 pair1LP,
            address _addressPair0LP,
            address _addressPair1LP,
            uint256 amountInvest
        );

    function removeAmountLPInvest(address investor) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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