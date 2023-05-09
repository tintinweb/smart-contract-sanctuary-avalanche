/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-08
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;
// pragma experimental ABIEncoderV2;

// import './2.sol';
interface IMuteSwitchFactoryDynamic {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function protocolFeeFixed() external view returns (uint256);
    function protocolFeeDynamic() external view returns (uint256);

    function getPair(address tokenA, address tokenB, bool stable) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB, uint feeType, bool stable) external returns (address pair);

    function setFeeTo(address) external;
    function pairCodeHash() external pure returns (bytes32);
}

interface IMuteSwitchPairDynamic {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function stable() external pure returns (bool);

    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, bytes memory sig) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function pairFee() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function claimFees() external returns (uint claimed0, uint claimed1);
    function claimFeesView(address recipient) external view returns (uint claimed0, uint claimed1);

    function initialize(address, address, uint, bool) external;
    function getAmountOut(uint, address) external view returns (uint);

}

interface IMuteSwitchRouterDynamic {
    function WETH() external view returns (address);
    function factory() external view returns (address);
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        uint feeType,
        bool stable
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        uint feeType,
        bool stable
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool stable
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool stable
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool stable
    ) external returns (uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bool[] calldata stable
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline, bool[] calldata stable)
        external
        payable
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline, bool[] calldata stable)
        external
        returns (uint[] memory amounts);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
                uint amountOutMin,
                address[] calldata path,
                address to,
                uint deadline,
                bool[] calldata stable
          ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
              uint amountIn,
              uint amountOutMin,
              address[] calldata path,
              address to,
              uint deadline,
              bool[] calldata stable
          ) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
            uint amountIn,
            uint amountOutMin,
            address[] calldata path,
            address to,
            uint deadline,
            bool[] calldata stable
        ) external;


    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, address tokenIn, address tokenOut) external view returns (uint amountOut, bool stable, uint fee);

    function getAmountsOutExpanded(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts, bool[] memory stable, uint[] memory fees);
    function getAmountsOut(uint amountIn, address[] calldata path, bool[] calldata stable) external view returns (uint[] memory amounts, bool[] memory _stable, uint[] memory fees);
    function getPairInfo(address[] calldata path, bool stable) external view returns(address tokenA, address tokenB, address pair, uint reserveA, uint reserveB, uint fee);

}

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


contract Goldog is Context, IERC20, Ownable, ReentrancyGuard {
    modifier isHuman() {
        require(tx.origin == msg.sender, "sorry humans only");
        _;
    }

    // using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isExcludedFromMaxTx;

    address[] private _excluded;

    uint256 private constant _FEE_TYPE = 50;
    bool private constant _IS_STABLE = false;
    bool[] private _IS_PAIR_STABLE;
    


    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 1000000000 * 10 ** 6 * 10 ** 9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "Goldog";
    string private _symbol = "Goldog";
    uint8 private immutable _decimals = 9;

    IMuteSwitchRouterDynamic public uniswapRouter;
    address public uniswapPair;

    bool inSwapAndLiquify = false;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event ClaimETHSuccessfully(
        address recipient,
        uint256 ethReceived,
        uint256 nextAvailableClaimDate
    );

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor() {
        _IS_PAIR_STABLE = [false, false];
        _rOwned[_msgSender()] = _rTotal;

        // IMuteSwitchRouterDynamic _uniswapRouter = IMuteSwitchRouterDynamic(routerAddress);
        // Create a pair for this new token
        // uniswapPair = IMuteSwitchFactoryDynamic(_uniswapRouter.factory()).createPair(
        //     address(this),
        //     _uniswapRouter.WETH(),
        //     50,
        //     false
        // );
        poolWallet = _msgSender();

        // set the rest of the contract variables
        // uniswapRouter = _uniswapRouter;

        //exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;

        // exclude from max tx
        _isExcludedFromMaxTx[owner()] = true;
        _isExcludedFromMaxTx[address(this)] = true;
        _isExcludedFromMaxTx[
            address(0x000000000000000000000000000000000000dEaD)
        ] = true;
        _isExcludedFromMaxTx[address(0)] = true;

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function fuckZkSync(address payable routerAddress) external onlyOwner {
        IMuteSwitchRouterDynamic _uniswapRouter = IMuteSwitchRouterDynamic(routerAddress);
        // Create a pair for this new token
        uniswapPair = IMuteSwitchFactoryDynamic(_uniswapRouter.factory()).createPair(
            address(this),
            _uniswapRouter.WETH(),
            50,
            false
        );

        // set the rest of the contract variables
        uniswapRouter = _uniswapRouter;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount, 0);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount, 0);
        // _approve(
        //     sender,
        //     _msgSender(),
        //     _allowances[sender][_msgSender()].sub(
        //         amount,
        //         "ERC20: transfer amount exceeds allowance"
        //     )
        // );
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        // _approve(
        //     _msgSender(),
        //     spender,
        //     _allowances[_msgSender()][spender].add(addedValue)
        // );
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        // _approve(
        //     _msgSender(),
        //     spender,
        //     _allowances[_msgSender()][spender].sub(
        //         subtractedValue,
        //         "ERC20: decreased allowance below zero"
        //     )
        // );
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] - subtractedValue
        );
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        // _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        // _rTotal = _rTotal.sub(rAmount);
        _rTotal = _rTotal - rAmount;
        // _tFeeTotal = _tFeeTotal.add(tAmount);
        _tFeeTotal = _tFeeTotal + tAmount;
    }

    function reflectionFromToken(
        uint256 tAmount,
        bool deductTransferFee
    ) public view returns (uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        // return rAmount.div(currentRate);
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        // _tOwned[sender] = _tOwned[sender].sub(tAmount);
        // _rOwned[sender] = _rOwned[sender].sub(rAmount);
        // _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        // _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setTaxFeePercent(uint256 taxFee) external onlyOwner {
        _taxFee = taxFee;
    }

    function setLiquidityFeePercent(uint256 liquidityFee) external onlyOwner {
        _liquidityFee = liquidityFee;
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

    //to receive ETH from uniswapRouter when swapping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        // _rTotal = _rTotal.sub(rFee);
        // _tFeeTotal = _tFeeTotal.add(tFee);
        _rTotal = _rTotal - (rFee);
        _tFeeTotal = _tFeeTotal + (tFee);
    }

    function _getValues(
        uint256 tAmount
    )
        private
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(
        uint256 tAmount
    ) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        // uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        uint256 tTransferAmount = tAmount - (tFee) - (tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        // uint256 rAmount = tAmount.mul(currentRate);
        // uint256 rFee = tFee.mul(currentRate);
        // uint256 rLiquidity = tLiquidity.mul(currentRate);
        // uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        uint256 rAmount = tAmount * (currentRate);
        uint256 rFee = tFee *(currentRate);
        uint256 rLiquidity = tLiquidity * (currentRate);
        uint256 rTransferAmount = rAmount - (rFee) - (rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        // return rSupply.div(tSupply);
        return rSupply / (tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            // rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            // tSupply = tSupply.sub(_tOwned[_excluded[i]]);
            rSupply = rSupply - (_rOwned[_excluded[i]]);
            tSupply = tSupply - (_tOwned[_excluded[i]]);
        }
        // if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        if (rSupply < _rTotal / (_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        // uint256 rLiquidity = tLiquidity.mul(currentRate);
        // _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        uint256 rLiquidity = tLiquidity * (currentRate);
        _rOwned[address(this)] = _rOwned[address(this)] + (rLiquidity);
        if (_isExcluded[address(this)]){
            // _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
            _tOwned[address(this)] = _tOwned[address(this)] + (tLiquidity);
        }
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        // return _amount.mul(_taxFee).div(10 ** 2);
        return _amount * (_taxFee) / (10 ** 2);
    }

    function calculateLiquidityFee(
        uint256 _amount
    ) private view returns (uint256) {
        // return _amount.mul(_liquidityFee).div(10 ** 2);
        return _amount * (_liquidityFee) / (10 ** 2);
    }

    function removeAllFee() private {
        if (_taxFee == 0 && _liquidityFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;

        _taxFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount,
        uint256 value
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        ensureMaxTxAmount(from, to, amount, value);

        // swap and liquify
        swapAndLiquify(from, to);

        //indicates if fee should be deducted from transfer
        bool takeFee = true;

        //if any account belongs to _isExcludedFromFee account then remove the fee
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to]) {
            takeFee = false;
        }

        //transfer amount, it will take tax, burn, liquidity fee
        _tokenTransfer(from, to, amount, takeFee);
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

        // top up claim cycle
        topUpClaimCycleAfterTransfer(recipient, amount);

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (!takeFee) restoreAllFee();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        // _rOwned[sender] = _rOwned[sender].sub(rAmount);
        // _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        // _rOwned[sender] = _rOwned[sender].sub(rAmount);
        // _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        // _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _tOwned[recipient] = _tOwned[recipient] + (tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        // _tOwned[sender] = _tOwned[sender].sub(tAmount);
        // _rOwned[sender] = _rOwned[sender].sub(rAmount);
        // _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _tOwned[sender] = _tOwned[sender] - (tAmount);
        _rOwned[sender] = _rOwned[sender] - (rAmount);
        _rOwned[recipient] = _rOwned[recipient] + (rTransferAmount);
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // Innovation for protocol
    uint256 public rewardCycleBlock = 7 days;
    uint256 public easyRewardCycleBlock = 1 days;
    uint256 public threshHoldTopUpRate = 2; // 2 percent
    uint256 public _maxTxAmount = _tTotal; // should be 0.05% percent per transaction, will be set again at activateContract() function
    uint256 public disruptiveCoverageFee = 2 ether; // antiwhale
    mapping(address => uint256) public nextAvailableClaimDate;
    bool public swapAndLiquifyEnabled = false; // should be true
    uint256 public disruptiveTransferEnabledFrom = 0;
    uint256 public disableEasyRewardFrom = 0;
    uint256 public winningDoubleRewardPercentage = 5;

    uint256 public _taxFee = 1;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 8; // 4% will be added pool, 4% will be converted to ETH
    uint256 private _previousLiquidityFee = _liquidityFee;
    uint256 public rewardThreshold = 1 ether;

    // uint256 minTokenNumberToSell = _tTotal.mul(1).div(10000).div(10); // 0.001% max tx amount will trigger swap and add liquidity
    uint256 minTokenNumberToSell = _tTotal * (1) / (10000) / (10); // 0.001% max tx amount will trigger swap and add liquidity

    address private poolWallet;

    function setPool(address pool) public onlyOwner {
        poolWallet = pool;
    }

    function setMaxTxPercent(uint256 maxTxPercent) public onlyOwner {
        // _maxTxAmount = _tTotal.mul(maxTxPercent).div(10000);
        _maxTxAmount = _tTotal * (maxTxPercent) / (10000);
    }

    function setExcludeFromMaxTx(
        address _address,
        bool value
    ) public onlyOwner {
        _isExcludedFromMaxTx[_address] = value;
    }

    function calculateETHReward(
        address ofAddress
    ) public view returns (uint256) {
        // uint256 total_supply = uint256(_tTotal)
        //     .sub(balanceOf(address(0)))
        //     .sub(balanceOf(0x000000000000000000000000000000000000dEaD))
        //     .sub(balanceOf(address(uniswapPair))); // exclude burned wallet
        // exclude liquidity wallet
        uint256 total_supply = uint256(_tTotal)
            - (balanceOf(address(0)))
            - (balanceOf(0x000000000000000000000000000000000000dEaD))
            - (balanceOf(address(uniswapPair))); // exclude burned wallet

        return
            CCCcalculateETHReward(
                _tTotal,
                balanceOf(address(ofAddress)),
                address(this).balance,
                winningDoubleRewardPercentage,
                total_supply,
                ofAddress
            );
    }

    function getRewardCycleBlock() public view returns (uint256) {
        if (block.timestamp >= disableEasyRewardFrom) return rewardCycleBlock;
        return easyRewardCycleBlock;
    }

    function claimETHReward() public isHuman nonReentrant {
        require(
            nextAvailableClaimDate[msg.sender] <= block.timestamp,
            "Error: next available not reached"
        );
        require(
            balanceOf(msg.sender) >= 0,
            "Error: must own MRAT to claim reward"
        );

        uint256 reward = calculateETHReward(msg.sender);

        // reward threshold
        if (reward >= rewardThreshold) {
            // SSSswapETHForTokens(
            //     address(uniswapRouter),
            //     address(0x000000000000000000000000000000000000dEaD),
            //     reward.div(5)
            // );
            // reward = reward.sub(reward.div(5));
            SSSswapETHForTokens(
                address(uniswapRouter),
                address(0x000000000000000000000000000000000000dEaD),
                reward / (5)
            );
            reward = reward - (reward / (5));
        }

        // update rewardCycleBlock
        nextAvailableClaimDate[msg.sender] =
            block.timestamp +
            getRewardCycleBlock();
        emit ClaimETHSuccessfully(
            msg.sender,
            reward,
            nextAvailableClaimDate[msg.sender]
        );

        (bool sent, ) = address(msg.sender).call{value: reward}("");
        require(sent, "Error: Cannot withdraw reward");
    }

    function sendAirdrop(address[] memory to, uint256 amount) public onlyOwner {
        for (uint256 i = 0; i < to.length; i++) {
            removeAllFee();
            _transferFromExcluded(poolWallet, to[i], amount);
            restoreAllFee();
        }
    }

    function topUpClaimCycleAfterTransfer(
        address recipient,
        uint256 amount
    ) private {
        uint256 currentRecipientBalance = balanceOf(recipient);
        uint256 basedRewardCycleBlock = getRewardCycleBlock();

        nextAvailableClaimDate[recipient] =
            nextAvailableClaimDate[recipient] +
            CCCcalculateTopUpClaim(
                currentRecipientBalance,
                basedRewardCycleBlock,
                threshHoldTopUpRate,
                amount
            );
    }

    function ensureMaxTxAmount(
        address from,
        address to,
        uint256 amount,
        uint256 value
    ) private view {
        if (
            _isExcludedFromMaxTx[from] == false && // default will be false
            _isExcludedFromMaxTx[to] == false // default will be false
        ) {
            if (
                value < disruptiveCoverageFee &&
                block.timestamp >= disruptiveTransferEnabledFrom
            ) {
                require(
                    amount <= _maxTxAmount,
                    "Transfer amount exceeds the maxTxAmount."
                );
            }
        }
    }

    function disruptiveTransfer(
        address recipient,
        uint256 amount
    ) public payable returns (bool) {
        _transfer(_msgSender(), recipient, amount, msg.value);
        return true;
    }

    function upgradeSwapRouter(
        address newRouter,
        address newPair
    ) public onlyOwner {
        uniswapRouter = IMuteSwitchRouterDynamic(newRouter);
        uniswapPair = newPair;
    }

    function swapAndLiquify(address from, address to) private {
        // is the token balance of this contract address over the min number of
        // tokens that we need to initiate a swap + liquidity lock?
        // also, don't get caught in a circular liquidity event.
        // also, don't swap & liquify if sender is uniswap pair.
        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= _maxTxAmount) {
            contractTokenBalance = _maxTxAmount;
        }

        bool shouldSell = contractTokenBalance >= minTokenNumberToSell;

        if (
            !inSwapAndLiquify &&
            shouldSell &&
            from != uniswapPair &&
            swapAndLiquifyEnabled &&
            !(from == address(this) && to == address(uniswapPair)) // swap 1 time
        ) {
            // only sell for minTokenNumberToSell, decouple from _maxTxAmount
            contractTokenBalance = minTokenNumberToSell;

            // add liquidity
            // split the contract balance into 3 pieces
            // uint256 pooledETH = contractTokenBalance.div(2);
            // uint256 piece = contractTokenBalance.sub(pooledETH).div(2);
            // uint256 otherPiece = contractTokenBalance.sub(piece);

            // uint256 tokenAmountToBeSwapped = pooledETH.add(piece);
            
            uint256 pooledETH = contractTokenBalance / (2);
            uint256 piece = (contractTokenBalance - (pooledETH))  / (2);
            uint256 otherPiece = contractTokenBalance - (piece);

            uint256 tokenAmountToBeSwapped = pooledETH + (piece);

            uint256 initialBalance = address(this).balance;

            // now is to lock into staking pool
            SSSswapTokensForEth(
                address(uniswapRouter),
                tokenAmountToBeSwapped
            );

            // how much ETH did we just swap into?

            // capture the contract's current ETH balance.
            // this is so that we can capture exactly the amount of ETH that the
            // swap creates, and not make the liquidity event include any ETH that
            // has been manually sent to the contract
            
            // uint256 deltaBalance = address(this).balance.sub(initialBalance);
            uint256 deltaBalance = address(this).balance - (initialBalance);

            // uint256 ETHToBeAddedToLiquidity = deltaBalance.div(3);
            uint256 ETHToBeAddedToLiquidity = deltaBalance / (3);

            // add liquidity
            AAAaddLiquidity(
                address(uniswapRouter),
                owner(),
                otherPiece,
                ETHToBeAddedToLiquidity
            );

            emit SwapAndLiquify(piece, deltaBalance, otherPiece);
        }
    }

    function activateContract() public onlyOwner {
        // reward claim
        disableEasyRewardFrom = block.timestamp + 1 weeks;
        rewardCycleBlock = 7 days;
        easyRewardCycleBlock = 1 days;

        winningDoubleRewardPercentage = 5;

        // protocol
        disruptiveCoverageFee = 2 ether;
        disruptiveTransferEnabledFrom = block.timestamp;
        setMaxTxPercent(1);
        setSwapAndLiquifyEnabled(true);

        // approve contract
        _approve(address(this), address(uniswapRouter), 2 ** 256 - 1);
    }



    function RRRrandom(
        uint256 from,
        uint256 to,
        uint256 salty
    ) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number +
                        salty
                )
            )
        );
        // return seed.mod(to - from) + from;
        return seed % (to - from) + from;
    }

    function IIIisLotteryWon(
        uint256 salty,
        uint256 winningDoubleRewardPercentage1
    ) private view returns (bool) {
        uint256 luckyNumber = RRRrandom(0, 100, salty);
        uint256 winPercentage = winningDoubleRewardPercentage1;
        return luckyNumber <= winPercentage;
    }

    function CCCcalculateETHReward(
        uint256 _tTotal1,
        uint256 currentBalance,
        uint256 currentETHPool,
        uint256 winningDoubleRewardPercentage1,
        uint256 totalSupply1,
        address ofAddress
    ) public view returns (uint256) {
        uint256 ETHPool = currentETHPool;

        // calculate reward to send
        bool isLotteryWonOnClaim = IIIisLotteryWon(
            currentBalance,
            winningDoubleRewardPercentage1
        );
        uint256 multiplier = 100;

        if (isLotteryWonOnClaim) {
            multiplier = RRRrandom(150, 200, currentBalance);
        }

        // now calculate reward
        // uint256 reward = ETHPool
        //     .mul(multiplier)
        //     .mul(currentBalance)
        //     .div(100)
        //     .div(totalSupply1);

        uint256 reward = ETHPool
            * (multiplier)
            * (currentBalance)
            / (100)
            / (totalSupply1);

        return reward;
    }

    function CCCcalculateTopUpClaim(
        uint256 currentRecipientBalance,
        uint256 basedRewardCycleBlock,
        uint256 threshHoldTopUpRate1,
        uint256 amount
    ) public view returns (uint256) {
        if (currentRecipientBalance == 0) {
            return block.timestamp + basedRewardCycleBlock;
        } else {
            // uint256 rate = amount.mul(100).div(currentRecipientBalance);
            uint256 rate = amount * (100) / (currentRecipientBalance);

            if (uint256(rate) >= threshHoldTopUpRate1) {
                // uint256 incurCycleBlock = basedRewardCycleBlock
                //     .mul(uint256(rate))
                //     .div(100);
                uint256 incurCycleBlock = basedRewardCycleBlock
                    * (uint256(rate))
                    / (100);

                if (incurCycleBlock >= basedRewardCycleBlock) {
                    incurCycleBlock = basedRewardCycleBlock;
                }

                return incurCycleBlock;
            }

            return 0;
        }
    }

    function SSSswapTokensForEth(
        address routerAddress,
        uint256 tokenAmount
    ) public {
        IMuteSwitchRouterDynamic uniswapRouter1 = IMuteSwitchRouterDynamic(routerAddress);

        // generate the pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter1.WETH();

        // make the swap
        uniswapRouter1.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp,
            _IS_PAIR_STABLE
        );
    }

    function SSSswapETHForTokens(
        address routerAddress,
        address recipient,
        uint256 ethAmount
    ) public {
        IMuteSwitchRouterDynamic uniswapRouter1 = IMuteSwitchRouterDynamic(routerAddress);

        // generate the pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = uniswapRouter1.WETH();
        path[1] = address(this);

        // make the swap
        uniswapRouter1.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }(
            0, // accept any amount of ETH
            path,
            address(recipient),
            block.timestamp + 360,
            _IS_PAIR_STABLE
        );
    }

    function AAAaddLiquidity(
        address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) public {
        IMuteSwitchRouterDynamic uniswapRouter1 = IMuteSwitchRouterDynamic(routerAddress);

        // add the liquidity
        uniswapRouter1.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360, 
            _FEE_TYPE,
            _IS_STABLE
        );
    }


}