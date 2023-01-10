// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Initializable.sol";
import "OwnableUpgradeable.sol";
import "SafeERC20.sol";
import "IJoeRouter02.sol";
import "IAvaxHelper.sol";
import "IPlatypusPool.sol";

contract SwapHelper is Initializable, OwnableUpgradeable {
    using SafeERC20 for IERC20;

    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address public constant VTX = 0x5817D4F0b62A59b17f75207DA1848C2cE75e7AF4;
    IJoeRouter02 public constant ROUTER = IJoeRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    IJoeRouter02 public constant PNG_ROUTER =
        IJoeRouter02(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);
    address public avaxHelper;
    mapping(address => address) public routeToAvax;
    mapping(address => address) public routeToAvaxOnPlatypus;
    mapping(address => bool) public usePng;
    // END OF STORAGE V1
    struct customRoute {
        address[] pools;
        address[] inTokens;
        address[] outTokens;
    }
    mapping(address => customRoute) customRoutesToAvax;

    function __SwapHelper_init() public initializer {
        __Ownable_init();
    }

    function setAvaxHelper(address helper) external onlyOwner {
        avaxHelper = helper;
    }

    function setRouteToAvax(address asset, address route) external onlyOwner {
        routeToAvax[asset] = route;
    }

    function setRouteToAvaxOnPlatypus(address asset, address route) external onlyOwner {
        routeToAvaxOnPlatypus[asset] = route;
    }

    function setUsePng(address asset, bool use) external onlyOwner {
        usePng[asset] = use;
    }

    function setCustomRoute(
        address token,
        address[] calldata pools,
        address[] calldata inTokens,
        address[] calldata outTokens
    ) external onlyOwner {
        uint256 length = pools.length;
        require(length == inTokens.length && length == outTokens.length, "Invalid Inputs");
        customRoutesToAvax[token] = customRoute({
            pools: pools,
            inTokens: inTokens,
            outTokens: outTokens
        });
    }

    function getRouter(address token) public view returns (IJoeRouter02 router) {
        router = usePng[token] ? PNG_ROUTER : ROUTER;
    }

    function previewAmountToAvax(address token, uint256 amount)
        public
        view
        returns (uint256 avaxAmount)
    {
        if (token == WAVAX) return amount;
        uint256 customRouteLength = customRoutesToAvax[token].pools.length;
        if (customRouteLength > 0) {
            uint256 _amount = amount;
            for (uint256 i; i < customRouteLength; i++) {
                address poolOrRouter = customRoutesToAvax[token].pools[i];
                address inToken = customRoutesToAvax[token].inTokens[i];
                address targetToken = customRoutesToAvax[token].outTokens[i];
                if (poolOrRouter == address(ROUTER) || poolOrRouter == address(PNG_ROUTER)) {
                    _amount = _previewSwapForAvaxOnAMM(inToken, _amount);
                } else {
                    _amount = _previewSwapOnPlatypus(inToken, targetToken, poolOrRouter, _amount);
                }
            }
            avaxAmount = _amount;
        } else {
            if (routeToAvaxOnPlatypus[token] != address(0)) {
                avaxAmount = _previewSwapOnPlatypus(
                    token,
                    WAVAX,
                    routeToAvaxOnPlatypus[token],
                    amount
                );
            } else {
                avaxAmount = _previewSwapForAvaxOnAMM(token, amount);
            }
        }
    }

    function _previewSwapOnPlatypus(
        address tokenIn,
        address tokenOut,
        address pool,
        uint256 amount
    ) internal view returns (uint256 amountOut) {
        if (amount == 0) {
            return 0;
        }
        (amountOut, ) = IPlatypusPool(pool).quotePotentialSwap(tokenIn, tokenOut, amount);
    }

    function _previewSwapForAvaxOnAMM(address tokenIn, uint256 amount)
        internal
        view
        returns (uint256 amountOut)
    {
        if (tokenIn == WAVAX || amount == 0) {
            return amount;
        }

        address[] memory path = findPathToAvax(tokenIn);
        IJoeRouter02 router = getRouter(tokenIn);
        uint256[] memory amounts = router.getAmountsOut(amount, path);
        amountOut = amounts[amounts.length - 1];
    }

    function previewTotalAmountToAvax(address[] calldata inTokens, uint256[] calldata amounts)
        public
        view
        returns (uint256 avaxAmount)
    {
        uint256 length = inTokens.length;
        for (uint256 i; i < length; i++) {
            if (inTokens[i] != address(0)) {
                avaxAmount += previewAmountToAvax(inTokens[i], amounts[i]);
            }
        }
    }

    function _previewSwapOnAMM(address[] memory path, uint256 amount)
        internal
        view
        returns (uint256 amountOut)
    {
        if (amount == 0) return 0;
        IJoeRouter02 router = getRouter(path[0]);
        uint256[] memory amounts = router.getAmountsOut(amount, path);
        amountOut = amounts[amounts.length - 1];
    }

    function previewAmountFromAvax(address token, uint256 amount) public view returns (uint256) {
        if (token == WAVAX || amount == 0) {
            return amount;
        }
        uint256 customRouteLength = customRoutesToAvax[token].pools.length;
        if (customRouteLength > 0) {
            uint256 _amount = amount;
            for (uint256 i = customRouteLength - 1; i >= 0; i--) {
                address poolOrRouter = customRoutesToAvax[token].pools[i];
                address targetToken = customRoutesToAvax[token].inTokens[i];
                address inToken = customRoutesToAvax[token].outTokens[i];
                if (poolOrRouter == address(ROUTER) || poolOrRouter == address(PNG_ROUTER)) {
                    address[] memory path = new address[](2);
                    path[0] = inToken;
                    path[1] = targetToken;
                    _amount = _previewSwapOnAMM(path, _amount);
                } else {
                    _amount = _previewSwapOnPlatypus(inToken, targetToken, poolOrRouter, _amount);
                }
                if (i == 0) break;
            }
            amount = _amount;
        } else {
            if (routeToAvaxOnPlatypus[token] != address(0)) {
                amount = _previewSwapOnPlatypus(WAVAX, token, routeToAvaxOnPlatypus[token], amount);
            } else {
                address[] memory path = findPathFromAvax(token);
                amount = _previewSwapOnAMM(path, amount);
            }
        }
        return amount;
    }

    function previewTotalAmountFromAvax(address[] calldata inTokens, uint256[] calldata amounts)
        public
        view
        returns (uint256 tokenAmount)
    {
        uint256 length = inTokens.length;
        for (uint256 i; i < length; i++) {
            if (inTokens[i] != address(0)) {
                tokenAmount += previewAmountToAvax(inTokens[i], amounts[i]);
            }
        }
    }

    function previewTotalAmountToToken(
        address[] calldata inTokens,
        uint256[] calldata amounts,
        address to
    ) public view returns (uint256 tokenAmount) {
        uint256 length = inTokens.length;
        uint256 avaxAmount;
        for (uint256 i; i < length; i++) {
            if (inTokens[i] != address(0) && inTokens[i] != to) {
                avaxAmount += previewAmountToAvax(inTokens[i], amounts[i]);
            }
        }
        if (avaxAmount == 0) return 0;
        tokenAmount = previewAmountFromAvax(to, avaxAmount);
    }

    function findPathToAvax(address token) public view returns (address[] memory) {
        address[] memory path;
        if (routeToAvax[token] != address(0)) {
            path = new address[](3);
            path[0] = token;
            path[1] = routeToAvax[token];
            path[2] = WAVAX;
        } else {
            path = new address[](2);
            path[0] = token;
            path[1] = WAVAX;
        }
        return path;
    }

    function findPathFromAvax(address token) public view returns (address[] memory) {
        address[] memory path;
        if (routeToAvax[token] != address(0)) {
            path = new address[](3);
            path[0] = WAVAX;
            path[1] = routeToAvax[token];
            path[2] = token;
        } else {
            path = new address[](2);
            path[0] = WAVAX;
            path[1] = token;
        }
        return path;
    }

    function _approveTokenIfNeeded(address token, address _to) internal {
        if (IERC20(token).allowance(address(this), address(_to)) == 0) {
            IERC20(token).approve(address(_to), type(uint256).max);
        }
    }

    function _swapTokenForAVAX(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) internal returns (uint256 avaxAmount) {
        avaxAmount = _swapTokenForWAVAX(token, amount, address(this), minAmountReceived);
        _approveTokenIfNeeded(WAVAX, avaxHelper);
        IAvaxHelper(avaxHelper).withdrawTo(receiver, avaxAmount);
    }

    function swapTokenForAvax(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount) {
        if (amount > 0) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            avaxAmount = _swapTokenForAVAX(token, amount, receiver, minAmountReceived);
        }
    }

    function safeSwapTokenForAvax(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount) {
        if (amount > 0 && previewAmountToAvax(token, amount) > 0) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            avaxAmount = _swapTokenForAVAX(token, amount, receiver, minAmountReceived);
        }
    }

    function _swapTokenForWAVAX(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) internal returns (uint256 wavaxAmount) {
        if (token == WAVAX) {
            if (receiver != address(this)) {
                IERC20(token).safeTransfer(receiver, amount);
            }
            return amount;
        } else {
            uint256 customRouteLength = customRoutesToAvax[token].pools.length;
            if (customRouteLength > 0) {
                uint256 _amount = amount;
                for (uint256 i; i < customRouteLength; i++) {
                    address poolOrRouter = customRoutesToAvax[token].pools[i];
                    address inToken = customRoutesToAvax[token].inTokens[i];
                    address targetToken = customRoutesToAvax[token].outTokens[i];
                    uint256 _minAmountReceived = i == customRouteLength - 1 ? minAmountReceived : 0;
                    address _receiver = i == customRouteLength - 1 ? receiver : address(this);
                    if (poolOrRouter == address(ROUTER) || poolOrRouter == address(PNG_ROUTER)) {
                        _amount = _swapForAvaxOnAMM(
                            inToken,
                            _amount,
                            _minAmountReceived,
                            _receiver
                        );
                    } else {
                        _amount = _swapOnPlatypus(
                            inToken,
                            targetToken,
                            poolOrRouter,
                            _amount,
                            _minAmountReceived,
                            _receiver
                        );
                    }
                }
                wavaxAmount = _amount;
            } else {
                if (routeToAvaxOnPlatypus[token] != address(0)) {
                    wavaxAmount = _swapOnPlatypus(
                        token,
                        WAVAX,
                        routeToAvaxOnPlatypus[token],
                        amount,
                        minAmountReceived,
                        receiver
                    );
                } else {
                    wavaxAmount = _swapForAvaxOnAMM(token, amount, minAmountReceived, receiver);
                }
            }
        }
    }

    function _swapForAvaxOnAMM(
        address tokenIn,
        uint256 amount,
        uint256 minAmountReceived,
        address receiver
    ) internal returns (uint256 amountOut) {
        address[] memory path = findPathToAvax(tokenIn);
        IJoeRouter02 router = getRouter(tokenIn);
        _approveTokenIfNeeded(tokenIn, address(router));
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amount,
            minAmountReceived,
            path,
            receiver,
            block.timestamp
        );
        amountOut = amounts[amounts.length - 1];
    }

    function _swapOnAMM(
        address[] memory path,
        uint256 amount,
        uint256 minAmountReceived,
        address receiver
    ) internal returns (uint256 amountOut) {
        address tokenIn = path[0];
        IJoeRouter02 router = getRouter(tokenIn);
        _approveTokenIfNeeded(tokenIn, address(router));
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amount,
            minAmountReceived,
            path,
            receiver,
            block.timestamp
        );
        amountOut = amounts[amounts.length - 1];
    }

    function _swapOnPlatypus(
        address inToken,
        address outToken,
        address pool,
        uint256 amount,
        uint256 minAmountReceived,
        address receiver
    ) internal returns (uint256 amountOut) {
        _approveTokenIfNeeded(inToken, pool);
        (amountOut, ) = IPlatypusPool(pool).swap(
            inToken,
            outToken,
            amount,
            minAmountReceived,
            receiver,
            block.timestamp
        );
    }

    function swapTokenForWAVAX(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) public returns (uint256 avaxAmount) {
        if (amount > 0) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            avaxAmount = _swapTokenForWAVAX(token, amount, receiver, minAmountReceived);
        }
    }

    function safeSwapTokenForWAVAX(
        address token,
        uint256 amount,
        address receiver,
        uint256 minAmountReceived
    ) public returns (uint256 avaxAmount) {
        if (amount > 0 && previewAmountToAvax(token, amount) > 0) {
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            avaxAmount = _swapTokenForWAVAX(token, amount, receiver, minAmountReceived);
        }
    }

    function _swapTokensForWAVAX(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        address finalReceiver,
        address tokenToSkip,
        uint256 minAmountReceived,
        bool safeSwap
    ) internal returns (uint256 avaxAmount) {
        uint256 length = tokens.length;
        for (uint256 i; i < length; i++) {
            address token = tokens[i];
            if (token != tokenToSkip) {
                if (safeSwap) {
                    avaxAmount += safeSwapTokenForWAVAX(token, amounts[i], receiver, 0);
                } else {
                    avaxAmount += swapTokenForWAVAX(token, amounts[i], receiver, 0);
                }
            } else {
                if (
                    msg.sender != receiver &&
                    receiver != finalReceiver &&
                    finalReceiver != msg.sender
                ) {
                    IERC20(token).safeTransferFrom(msg.sender, finalReceiver, amounts[i]);
                }
            }
        }
        require(avaxAmount >= minAmountReceived, "Slippage");
    }

    function swapTokensForWAVAX(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount) {
        avaxAmount = _swapTokensForWAVAX(
            tokens,
            amounts,
            receiver,
            receiver,
            address(0),
            minAmountReceived,
            false
        );
    }

    function safeSwapTokensForWAVAX(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount) {
        avaxAmount = _swapTokensForWAVAX(
            tokens,
            amounts,
            receiver,
            receiver,
            address(0),
            minAmountReceived,
            true
        );
    }

    function swapTokensForAvax(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount) {
        avaxAmount = _swapTokensForWAVAX(
            tokens,
            amounts,
            address(this),
            address(this),
            address(0),
            minAmountReceived,
            false
        );
        _approveTokenIfNeeded(WAVAX, avaxHelper);
        IAvaxHelper(avaxHelper).withdrawTo(receiver, avaxAmount);
    }

    function safeSwapTokensForAvax(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 avaxAmount) {
        avaxAmount = _swapTokensForWAVAX(
            tokens,
            amounts,
            address(this),
            address(this),
            address(0),
            minAmountReceived,
            true
        );
        _approveTokenIfNeeded(WAVAX, avaxHelper);
        IAvaxHelper(avaxHelper).withdrawTo(receiver, avaxAmount);
    }

    function _swapWAVAXForToken(
        address token,
        address receiver,
        uint256 amount,
        uint256 minAmountReceived
    ) internal returns (uint256) {
        if (amount == 0) return 0;
        uint256 customRouteLength = customRoutesToAvax[token].pools.length;
        if (customRouteLength > 0) {
            uint256 _amount = amount;
            for (uint256 i = customRouteLength - 1; i >= 0; i--) {
                address poolOrRouter = customRoutesToAvax[token].pools[i];
                address targetToken = customRoutesToAvax[token].inTokens[i];
                address inToken = customRoutesToAvax[token].outTokens[i];
                uint256 _minAmountReceived = i == 0 ? minAmountReceived : 0;
                address _receiver = i == 0 ? receiver : address(this);
                if (poolOrRouter == address(ROUTER) || poolOrRouter == address(PNG_ROUTER)) {
                    address[] memory path = new address[](2);
                    path[0] = inToken;
                    path[1] = targetToken;
                    _amount = _swapOnAMM(path, _amount, _minAmountReceived, _receiver);
                } else {
                    _amount = _swapOnPlatypus(
                        inToken,
                        targetToken,
                        poolOrRouter,
                        _amount,
                        _minAmountReceived,
                        _receiver
                    );
                }
                if (i == 0) break;
            }
            amount = _amount;
        } else {
            if (routeToAvaxOnPlatypus[token] != address(0)) {
                amount = _swapOnPlatypus(
                    WAVAX,
                    token,
                    routeToAvaxOnPlatypus[token],
                    amount,
                    minAmountReceived,
                    receiver
                );
            } else {
                address[] memory path = findPathFromAvax(token);
                amount = _swapOnAMM(path, amount, minAmountReceived, receiver);
            }
        }
        return amount;
    }

    function swapTokensForToken(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address token,
        address receiver,
        uint256 minAmountReceived
    ) public returns (uint256 tokenAmount) {
        uint256 amount = _swapTokensForWAVAX(
            tokens,
            amounts,
            address(this),
            receiver,
            token,
            0,
            false
        );
        tokenAmount = _swapWAVAXForToken(token, receiver, amount, minAmountReceived);
    }

    function safeSwapTokensForToken(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address token,
        address receiver,
        uint256 minAmountReceived
    ) public returns (uint256 tokenAmount) {
        uint256 amount = _swapTokensForWAVAX(
            tokens,
            amounts,
            address(this),
            receiver,
            token,
            0,
            true
        );
        tokenAmount = _swapWAVAXForToken(token, receiver, amount, minAmountReceived);
    }

    function swapTokensForVTX(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 vtxAmount) {
        vtxAmount = swapTokensForToken(tokens, amounts, VTX, receiver, minAmountReceived);
    }

    function safeSwapTokensForVTX(
        address[] calldata tokens,
        uint256[] calldata amounts,
        address receiver,
        uint256 minAmountReceived
    ) external returns (uint256 vtxAmount) {
        vtxAmount = safeSwapTokensForToken(tokens, amounts, VTX, receiver, minAmountReceived);
    }

    function sweep(address[] calldata tokens) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint256 amount = IERC20(token).balanceOf(address(this));
            if (amount > 0) {
                _swapTokenForWAVAX(token, amount, owner(), 0);
            }
        }
        uint256 balance = address(this).balance;
        if (balance > 0) {
            payable(owner()).transfer(balance);
        }
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "ContextUpgradeable.sol";
import "Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "IJoeRouter01.sol";

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

// SPDX-License-Identifier: GPL-3.0

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IAvaxHelper {
    function WAVAX() external view returns (address);

    function withdrawTo(address to, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IPlatypusPool {
    function swap(
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function quotePotentialSwap(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) external view returns (uint256 potentialOutcome, uint256 haircut);

    function swapToETH(
        address fromToken,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address payable to,
        uint256 deadline
    ) external returns (uint256 actualToAmount, uint256 haircut);

    function swapFromETH(
        address toToken,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external payable returns (uint256 actualToAmount, uint256 haircut);
}