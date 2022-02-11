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
pragma solidity ^0.8.0;

import {IERC20 as _IERC20} from "@openzeppelin/contracts-solc8/token/ERC20/IERC20.sol";

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 is _IERC20 {
    function nonces(address) external view returns (uint256); // Only tokens that support permit

    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external; // Only tokens that support permit

    function mint(address to, uint256 amount) external; // only tokens that support minting
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import {IERC20} from "./IERC20.sol";
import {Address} from "@openzeppelin/contracts-solc8/utils/Address.sol";

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
pragma solidity >=0.4.0;
pragma experimental ABIEncoderV2;

interface IWETH9 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function allowance(address, address) external view returns (uint256);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function totalSupply() external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

library Bytes {
    function toBytes(address x)
        internal
        pure
        returns (bytes memory b)
    {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function toAddress(uint _offst, bytes memory _input)
        internal
        pure
        returns (address _output)
    {
        assembly { _output := mload(add(_input, _offst)) }
    }

    function toBytes(uint256 x)
        internal
        pure
        returns (bytes memory b)
    {
        b = new bytes(32);
        assembly { mstore(add(b, 32), x) }
    }

    function toUint256(uint _offst, bytes memory _input)
        internal
        pure
        returns (uint256 _output)
    {
        assembly { _output := mload(add(_input, _offst)) }
    }

    function mergeBytes(bytes memory a, bytes memory b)
        internal
        pure
        returns (bytes memory c)
    {
        // From https://ethereum.stackexchange.com/a/40456
        uint alen = a.length;
        uint totallen = alen + b.length;
        uint loopsa = (a.length + 31) / 32;
        uint loopsb = (b.length + 31) / 32;
        assembly {
            let m := mload(0x40)
            mstore(m, totallen)
            for {  let i := 0 } lt(i, loopsa) { i := add(1, i) } { mstore(add(m, mul(32, add(1, i))), mload(add(a, mul(32, add(1, i))))) }
            for {  let i := 0 } lt(i, loopsb) { i := add(1, i) } { mstore(add(m, add(mul(32, add(1, i)), alen)), mload(add(b, mul(32, add(1, i))))) }
            mstore(0x40, add(m, add(32, totallen)))
            c := m
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IRouter} from "./interface/IRouter.sol";
import {IAdapter} from "./interface/IAdapter.sol";

import {ISynapseBridge} from "./interface/ISynapseBridge.sol";

import {IERC20} from "@synapseprotocol/sol-lib/contracts/solc8/erc20/IERC20.sol";
import {Bytes} from "@synapseprotocol/sol-lib/contracts/universal/lib/LibBytes.sol";
import {IWETH9} from "@synapseprotocol/sol-lib/contracts/universal/interfaces/IWETH9.sol";
import {SafeERC20} from "@synapseprotocol/sol-lib/contracts/solc8/erc20/SafeERC20.sol";

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Router is Ownable, IRouter {
    using SafeERC20 for IERC20;

    address public BRIDGE;
    address public FEE_CLAIMER;
    address payable public WGAS;

    address[] public ADAPTERS;
    address[] public TRUSTED_TOKENS;

    uint256 public MIN_FEE = 0;
    address public constant GAS = address(0);
    uint256 public constant FEE_DENOMINATOR = 1e4;

    bytes32 constant REDEEM = keccak256("REDEEM");
    bytes32 constant DEPOSIT = keccak256("DEPOSIT");

    struct Query {
        address adapter;
        address tokenIn;
        address tokenOut;
        uint256 amountOut;
    }

    struct OfferWithGas {
        bytes amounts;
        bytes adapters;
        bytes path;
        uint256 gasEstimate;
    }

    struct FormattedOfferWithGas {
        uint256[] amounts;
        address[] adapters;
        address[] path;
        uint256 gasEstimate;
    }

    struct Trade {
        uint256 amountIn;
        uint256 amountOut;
        address[] path;
        address[] adapters;
    }

    constructor(
        address[] memory _adapters,
        address[] memory _trustedTokens,
        address _feeClaimer,
        address payable _weth,
        address _bridge
    ) {
        WGAS = _weth;
        BRIDGE = _bridge;
        
        setTrustedTokens(_trustedTokens);
        setFeeClaimer(_feeClaimer);
        setAdapters(_adapters);
        
        _setAllowances();
    }

    // -- SETTERS --

    function _setAllowances() internal {
        IERC20(WGAS).safeApprove(WGAS, type(uint256).max);
    }

    function setTrustedTokens(address[] memory _trustedTokens)
        public
        onlyOwner
    {
        emit UpdatedTrustedTokens(_trustedTokens);
        TRUSTED_TOKENS = _trustedTokens;
        for (uint256 i = 0; i < _trustedTokens.length; i++) {
            IERC20(_trustedTokens[i]).safeApprove(BRIDGE, type(uint256).max);
        }
    }

    function setAdapters(address[] memory _adapters)
        public
        onlyOwner
    {
        emit UpdatedAdapters(_adapters);
        ADAPTERS = _adapters;
    }

    function setMinFee(uint256 _fee)
        external
        onlyOwner
    {
        emit UpdatedMinFee(MIN_FEE, _fee);
        MIN_FEE = _fee;
    }

    function setFeeClaimer(address _claimer)
        public
        onlyOwner
    {
        emit UpdatedFeeClaimer(FEE_CLAIMER, _claimer);
        FEE_CLAIMER = _claimer;
    }

    //  -- GENERAL --

    function trustedTokensCount() external view returns (uint256) {
        return TRUSTED_TOKENS.length;
    }

    function adaptersCount() external view returns (uint256) {
        return ADAPTERS.length;
    }

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount)
        external
        onlyOwner
    {
        require(_tokenAmount > 0, "Router: Nothing to recover");
        IERC20(_tokenAddress).safeTransfer(msg.sender, _tokenAmount);
        emit Recovered(_tokenAddress, _tokenAmount);
    }

    function recoverGAS(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Router: Nothing to recover");
        payable(msg.sender).transfer(_amount);
        emit Recovered(address(0), _amount);
    }

    // Fallback
    receive() external payable {}

    // -- HELPERS --

    function _applyFee(uint256 _amountIn, uint256 _fee)
        internal
        view
        returns (uint256)
    {
        require(_fee >= MIN_FEE, "Router: Insufficient fee");
        return (_amountIn * (FEE_DENOMINATOR - _fee)) / FEE_DENOMINATOR;
    }

    function _wrap(uint256 _amount) internal {
        IWETH9(WGAS).deposit{value: _amount}();
    }

    function _unwrap(uint256 _amount) internal {
        IWETH9(WGAS).withdraw(_amount);
    }

    /**
     * @notice Return tokens to user
     * @dev Pass address(0) for GAS
     * @param _token address
     * @param _amount tokens to return
     * @param _to address where funds should be sent to
     */
    function _returnTokensTo(
        address _token,
        uint256 _amount,
        address _to
    ) internal {
        if (address(this) != _to) {
            if (_token == GAS) {
                payable(_to).transfer(_amount);
            } else {
                IERC20(_token).safeTransfer(_to, _amount);
            }
        }
    }

    /**
     * Makes a deep copy of OfferWithGas struct
     */
    function _cloneOfferWithGas(OfferWithGas memory _queries)
        internal
        pure
        returns (OfferWithGas memory)
    {
        return
            OfferWithGas(
                _queries.amounts,
                _queries.adapters,
                _queries.path,
                _queries.gasEstimate
            );
    }

    /**
     * Appends Query elements to Offer struct
     */
    function _addQueryWithGas(
        OfferWithGas memory _queries,
        uint256 _amount,
        address _adapter,
        address _tokenOut,
        uint256 _gasEstimate
    ) internal pure {
        _queries.path = Bytes.mergeBytes(
            _queries.path,
            Bytes.toBytes(_tokenOut)
        );
        _queries.amounts = Bytes.mergeBytes(
            _queries.amounts,
            Bytes.toBytes(_amount)
        );
        _queries.adapters = Bytes.mergeBytes(
            _queries.adapters,
            Bytes.toBytes(_adapter)
        );
        _queries.gasEstimate += _gasEstimate;
    }

    /**
     * Converts byte-arrays to an array of integers
     */
    function _formatAmounts(bytes memory _amounts)
        internal
        pure
        returns (uint256[] memory)
    {
        // Format amounts
        uint256 chunks = _amounts.length / 32;
        uint256[] memory amountsFormatted = new uint256[](chunks);
        for (uint256 i = 0; i < chunks; i++) {
            amountsFormatted[i] = Bytes.toUint256(
                i * 32 + 32,
                _amounts
            );
        }
        return amountsFormatted;
    }

    /**
     * Converts byte-array to an array of addresses
     */
    function _formatAddresses(bytes memory _addresses)
        internal
        pure
        returns (address[] memory)
    {
        uint256 chunks = _addresses.length / 32;
        address[] memory addressesFormatted = new address[](chunks);
        for (uint256 i = 0; i < chunks; i++) {
            addressesFormatted[i] = Bytes.toAddress(
                i * 32 + 32,
                _addresses
            );
        }
        return addressesFormatted;
    }

    /**
     * Formats elements in the Offer object from byte-arrays to integers and addresses
     */
    function _formatOfferWithGas(OfferWithGas memory _queries)
        internal
        pure
        returns (FormattedOfferWithGas memory)
    {
        return
            FormattedOfferWithGas(
                _formatAmounts(_queries.amounts),
                _formatAddresses(_queries.adapters),
                _formatAddresses(_queries.path),
                _queries.gasEstimate
            );
    }

    // -- QUERIES --

    /**
     * Query single adapter
     */
    function queryAdapter(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8 _index
    ) external view returns (uint256) {
        IAdapter _adapter = IAdapter(ADAPTERS[_index]);
        uint256 amountOut = _adapter.query(_amountIn, _tokenIn, _tokenOut);
        return amountOut;
    }

    /**
     * Query specified adapters
     */
    function query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8[] calldata _options
    ) public view returns (Query memory) {
        Query memory bestQuery;
        for (uint8 i; i < _options.length; i++) {
            address _adapter = ADAPTERS[_options[i]];
            uint256 amountOut = IAdapter(_adapter).query(
                _amountIn,
                _tokenIn,
                _tokenOut
            );
            if (i == 0 || amountOut > bestQuery.amountOut) {
                bestQuery = Query(_adapter, _tokenIn, _tokenOut, amountOut);
            }
        }
        return bestQuery;
    }

    /**
     * Query all adapters
     */
    function query(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut
    ) public view returns (Query memory) {
        Query memory bestQuery;
        for (uint8 i; i < ADAPTERS.length; i++) {
            address _adapter = ADAPTERS[i];
            uint256 amountOut = IAdapter(_adapter).query(
                _amountIn,
                _tokenIn,
                _tokenOut
            );
            if (i == 0 || amountOut > bestQuery.amountOut) {
                bestQuery = Query(_adapter, _tokenIn, _tokenOut, amountOut);
            }
        }
        return bestQuery;
    }

    /**
     * Return path with best returns between two tokens
     * Takes gas-cost into account
     */
    function findBestPathWithGas(
        uint256 _amountIn, 
        address _tokenIn, 
        address _tokenOut, 
        uint _maxSteps,
        uint _gasPrice
    ) external view returns (FormattedOfferWithGas memory) {
        require(_maxSteps>0 && _maxSteps<5, 'YakRouter: Invalid max-steps');
        OfferWithGas memory queries;
        uint tknOutPriceNwei = 0;
        queries.amounts = Bytes.toBytes(_amountIn);
        queries.path = Bytes.toBytes(_tokenIn);
        // Find the market price between AVAX and token-out and express gas price in token-out currency
        if(_gasPrice == 0){
            OfferWithGas memory gasQueries;
            gasQueries.amounts = Bytes.toBytes(1e18);
            gasQueries.path = Bytes.toBytes(WGAS);
            OfferWithGas memory gasQuery = _findBestPathWithGas(
                1e18, 
                WGAS, 
                _tokenOut, 
                2,
                gasQueries, 
                tknOutPriceNwei
            );  // Avoid low-liquidity price appreciation
            uint[] memory tokenOutAmounts = _formatAmounts(gasQuery.amounts);
            // Leave result nWei to preserve digits for assets with low decimal places
            tknOutPriceNwei = tokenOutAmounts[tokenOutAmounts.length-1] * (_gasPrice/1e9);
        }
        queries = _findBestPathWithGas(
            _amountIn, 
            _tokenIn, 
            _tokenOut, 
            _maxSteps,
            queries, 
            tknOutPriceNwei
        );
        
        // If no paths are found return empty struct
        if (queries.adapters.length==0) {
            queries.amounts = '';
            queries.path = '';
        }
        return _formatOfferWithGas(queries);
    } 

    function _findBestPathWithGas(
        uint256 _amountIn, 
        address _tokenIn, 
        address _tokenOut, 
        uint _maxSteps,
        OfferWithGas memory _queries, 
        uint _tknOutPriceNwei
    ) internal view returns (OfferWithGas memory) {
        OfferWithGas memory bestOption = _cloneOfferWithGas(_queries);
        uint256 bestAmountOut;
        bool isGasIncluded = (_tknOutPriceNwei == 0);
        // First check if there is a path directly from tokenIn to tokenOut
        Query memory queryDirect = query(_amountIn, _tokenIn, _tokenOut);
        if (queryDirect.amountOut!=0) {
            uint gasEstimate = 0;
            if(isGasIncluded){
                gasEstimate = IAdapter(queryDirect.adapter).SWAP_GAS_ESTIMATE();
            }
            _addQueryWithGas(
                bestOption, 
                queryDirect.amountOut, 
                queryDirect.adapter, 
                queryDirect.tokenOut, 
                gasEstimate
            );
            bestAmountOut = queryDirect.amountOut;
        }
        // Only check the rest if they would go beyond step limit (Need at least 2 more steps)
        if (_maxSteps>1 && _queries.adapters.length/32<=_maxSteps-2) {
            // Check for paths that pass through trusted tokens
            for (uint256 i=0; i<TRUSTED_TOKENS.length; i++) {
                if (_tokenIn == TRUSTED_TOKENS[i]) {
                    continue;
                }
                // Loop through all adapters to find the best one for swapping tokenIn for one of the trusted tokens
                Query memory bestSwap = query(_amountIn, _tokenIn, TRUSTED_TOKENS[i]);
                if (bestSwap.amountOut==0) {
                    continue;
                }
                // Explore options that connect the current path to the tokenOut
                OfferWithGas memory newOffer = _cloneOfferWithGas(_queries);
                uint gasEstimate = 0;
                if(isGasIncluded){
                    gasEstimate = IAdapter(queryDirect.adapter).SWAP_GAS_ESTIMATE();
                }
                _addQueryWithGas(newOffer, bestSwap.amountOut, bestSwap.adapter, bestSwap.tokenOut, gasEstimate);
                newOffer = _findBestPathWithGas(
                    bestSwap.amountOut, 
                    TRUSTED_TOKENS[i], 
                    _tokenOut, 
                    _maxSteps, 
                    newOffer, 
                    _tknOutPriceNwei
                );
                address tokenOut = Bytes.toAddress(newOffer.path.length, newOffer.path);
                uint256 amountOut = Bytes.toUint256(newOffer.amounts.length, newOffer.amounts);
                // Check that the last token in the path is the tokenOut and update the new best option if neccesary
                if (_tokenOut == tokenOut && amountOut > bestAmountOut) {
                    if (isGasIncluded && newOffer.gasEstimate > bestOption.gasEstimate) {
                        uint gasCostDiff = (_tknOutPriceNwei * (newOffer.gasEstimate-bestOption.gasEstimate)) / 1e9;
                        uint priceDiff = amountOut - bestAmountOut;
                        if (gasCostDiff > priceDiff) { continue; }
                    }
                    bestAmountOut = amountOut;
                    bestOption = newOffer;
                }
            }
        }
        return bestOption;   
    }

    // -- SWAPPERS --

    function _swap(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _from,
        address _to,
        uint256 _fee
    ) internal returns (uint256) {
        uint256[] memory amounts = new uint256[](path.length);
        if (_fee > 0 || MIN_FEE > 0) {
            // Transfer fees to the claimer account and decrease initial amount
            amounts[0] = _applyFee(amountIn, _fee);
            IERC20(path[0]).safeTransferFrom(
                _from,
                FEE_CLAIMER,
                amountIn - amounts[0]
            );
        } else {
            amounts[0] = amountIn;
        }
        IERC20(path[0]).safeTransferFrom(
            _from,
            adapters[0],
            amounts[0]
        );
        // Get amounts that will be swapped
        for (uint256 i = 0; i < adapters.length; i++) {
            amounts[i + 1] = IAdapter(adapters[i]).query(
                amounts[i],
                path[i],
                path[i + 1]
            );
        }
        require(
            amounts[amounts.length - 1] >= amountOut,
            "Router: Insufficient output amount"
        );
        for (uint256 i = 0; i < adapters.length; i++) {
            // All adapters should transfer output token to the following target
            // All targets are the adapters, expect for the last swap where tokens are sent out
            address targetAddress = i < adapters.length - 1
                ? adapters[i + 1]
                : _to;
            IAdapter(adapters[i]).swap(
                amounts[i],
                amounts[i + 1],
                path[i],
                path[i + 1],
                targetAddress
            );
        }
        emit Swap(
            path[0],
            path[path.length - 1],
            amountIn,
            amounts[amounts.length - 1]
        );
        return amounts[amounts.length - 1];
    }

    function swap(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee
    ) public {
        _swap(amountIn, amountOut, path, adapters, msg.sender, _to, _fee);
    }

    function swapFromGAS(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee
    ) external payable {
        require(
            path[0] == WGAS,
            "Router: Path needs to begin with WGAS"
        );
        _wrap(amountIn);
        _swap(amountIn, amountOut, path, adapters, msg.sender, _to, _fee);
    }

    function swapToGAS(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee
    ) public {
        require(
            path[path.length - 1] == WGAS,
            "Router: Path needs to end with WGAS"
        );
        uint256 returnAmount = _swap(amountIn, amountOut, path, adapters, msg.sender, _to, _fee);
        _unwrap(returnAmount);
        _returnTokensTo(GAS, returnAmount, _to);
    }

    /**
     * Swap token to token without the need to approve the first token
     */
    function swapWithPermit(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        IERC20(path[0]).permit(
            msg.sender,
            address(this),
            amountIn,
            _deadline,
            _v,
            _r,
            _s
        );
        _swap(amountIn, amountOut, path, adapters, msg.sender, _to, _fee);
    }

    /**
     * Swap token to GAS without the need to approve the first token
     */
    function swapToGASWithPermit(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        IERC20(path[0]).permit(
            msg.sender,
            address(this),
            amountIn,
            _deadline,
            _v,
            _r,
            _s
        );
        swapToGAS(amountIn, amountOut, path, adapters, _to, _fee);
    }



    // -- SWAPPERS --

    function _selfswap(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _from,
        address _to,
        uint256 _fee
    ) internal returns (uint256) {
        uint256[] memory amounts = new uint256[](path.length);
        if (_fee > 0 || MIN_FEE > 0) {
            // Transfer fees to the claimer account and decrease initial amount
            amounts[0] = _applyFee(amountIn, _fee);
            IERC20(path[0]).safeTransferFrom(
                _from,
                FEE_CLAIMER,
                amountIn - amounts[0]
            );
        } else {
            amounts[0] = amountIn;
        }
        // TO DO: REMOVE THIS
        IERC20(path[0]).safeTransfer(
            adapters[0],
            amounts[0]
        );

        // Get amounts that will be swapped
        for (uint256 i = 0; i < adapters.length; i++) {
            amounts[i + 1] = IAdapter(adapters[i]).query(
                amounts[i],
                path[i],
                path[i + 1]
            );
        }
        require(
            amounts[amounts.length - 1] >= amountOut,
            "Router: Insufficient output amount"
        );
        for (uint256 i = 0; i < adapters.length; i++) {
            // All adapters should transfer output token to the following target
            // All targets are the adapters, expect for the last swap where tokens are sent out
            address targetAddress = i < adapters.length - 1
                ? adapters[i + 1]
                : _to;
            IAdapter(adapters[i]).swap(
                amounts[i],
                amounts[i + 1],
                path[i],
                path[i + 1],
                targetAddress
            );
        }
        emit Swap(
            path[0],
            path[path.length - 1],
            amountIn,
            amounts[amounts.length - 1]
        );
        return amounts[amounts.length - 1];
    }

    function selfSwap(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee
    ) public {
        require(msg.sender == BRIDGE, "Invalid caller");
        _selfswap(amountIn, amountOut, path, adapters, msg.sender, _to, _fee);
    }

    function selfSwapFromGAS(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee
    ) external payable {
        require(msg.sender == BRIDGE, "Invalid caller");
        require(
            path[0] == WGAS,
            "Router: Path needs to begin with WGAS"
        );
        _wrap(amountIn);
        _swap(amountIn, amountOut, path, adapters, msg.sender, _to, _fee);
    }

    function selfSwapToGAS(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee
    ) public {
        require(msg.sender == BRIDGE, "Invalid caller");
        require(
            path[path.length - 1] == WGAS,
            "Router: Path needs to end with WGAS"
        );
        uint256 returnAmount = _swap(amountIn, amountOut, path, adapters, msg.sender, _to, _fee);
        _unwrap(returnAmount);
        _returnTokensTo(GAS, returnAmount, _to);
    }


    // **************************************************************** 
    // BRIDGE DEPOSIT FUNCTIONS
    // **************************************************************** 

    function swap(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee,
        bytes calldata bridgeaction
    ) external {
        uint256 swapAmount = _swap(amountIn, amountOut, path, adapters, msg.sender, address(this), _fee);
        address lastToken = path[path.length - 1];
        IERC20(lastToken).approve(BRIDGE, swapAmount);
        (bool success, bytes memory result) = BRIDGE.call(bridgeaction);
        require(success);
    }

    // function swapFromGASIntoBridge(
    //     Trade calldata _trade,
    //     address _to,
    //     uint256 _fee,
    //     bytes calldata bridgeaction
    // ) external payable {
    //     require(
    //         _trade.path[0] == WGAS,
    //         "Router: Path needs to begin with WGAS"
    //     );
    //     _wrap(_trade.amountIn);
    //     _swap(_trade, address(this), _to, _fee);
    // }

    // function swapToGASBridgeDeposit(
    //     Trade calldata _trade,
    //     address _to,
    //     uint256 _fee,
    //     bytes calldata bridgeaction
    // ) public {
    //     require(
    //         _trade.path[_trade.path.length - 1] == WGAS,
    //         "Router: Path needs to end with WGAS"
    //     );
    //     uint256 returnAmount = _swap(
    //         _trade,
    //         msg.sender,
    //         address(this),
    //         _fee
    //     );
    //     _unwrap(returnAmount);
    //     _returnTokensTo(GAS, returnAmount, _to);
    // }

    // /**
    //  * Swap token to token without the need to approve the first token
    //  */
    // function swapWithPermitBridgeDeposit(
    //     Trade calldata _trade,
    //     address _to,
    //     uint256 _fee,
    //     uint256 _deadline,
    //     uint8 _v,
    //     bytes32 _r,
    //     bytes32 _s,
    //     bytes calldata bridgeaction
    // ) external {
    //     IERC20(_trade.path[0]).permit(
    //         msg.sender,
    //         address(this),
    //         _trade.amountIn,
    //         _deadline,
    //         _v,
    //         _r,
    //         _s
    //     );
    //     swap(_trade, _to, _fee);
    // }

    // /**
    //  * Swap token to GAS without the need to approve the first token
    //  */
    // function swapToGASWithPermit(
    //     Trade calldata _trade,
    //     address _to,
    //     uint256 _fee,
    //     uint256 _deadline,
    //     uint8 _v,
    //     bytes32 _r,
    //     bytes32 _s,
    //     bytes calldata bridgeaction
    // ) external {
    //     IERC20(_trade.path[0]).permit(
    //         msg.sender,
    //         address(this),
    //         _trade.amountIn,
    //         _deadline,
    //         _v,
    //         _r,
    //         _s
    //     );
    //     swapToGAS(_trade, _to, _fee);
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6;

interface IAdapter {
    event AdapterSwap(
        address indexed _tokenFrom,
        address indexed _tokenTo,
        uint256 _amountIn,
        uint256 _amountOut
    );

    event UpdatedGasEstimate(address indexed _adapter, uint256 _newEstimate);

    event Recovered(address indexed _asset, uint256 amount);

    function NAME() external view returns (string memory);
    function SWAP_GAS_ESTIMATE() external view returns (uint);
    function swap(uint256, uint256, address, address, address) external;
    function query(uint256, address, address) external view returns (uint);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {
    event Recovered(address indexed _asset, uint256 amount);

    event UpdatedTrustedTokens(address[] _newTrustedTokens);

    event UpdatedAdapters(address[] _newAdapters);

    event UpdatedMinFee(uint256 _oldMinFee, uint256 _newMinFee);

    event UpdatedFeeClaimer(address _oldFeeClaimer, address _newFeeClaimer);

    event Swap(
        address indexed _tokenIn,
        address indexed _tokenOut,
        uint256 _amountIn,
        uint256 _amountOut
    );

    function trustedTokensCount() external view returns (uint256);
    function adaptersCount() external view returns (uint256);

    function queryAdapter(
        uint256 _amountIn,
        address _tokenIn,
        address _tokenOut,
        uint8 _index
    ) external view returns (uint256);

    function swap(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee
    ) external;

    function swapFromGAS(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee
    ) external payable;

    function swapToGAS(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee
    ) external;

    function swapWithPermit(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function swapToGASWithPermit(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function selfSwap(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee
    ) external;

    function selfSwapFromGAS(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee
    ) external payable;

    function selfSwapToGAS(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee
    ) external;

    function swap(
        uint256 amountIn,
        uint256 amountOut,
        address[] calldata path,
        address[] calldata adapters,
        address _to,
        uint256 _fee,
        bytes calldata bridgeaction
    ) external;

    function setTrustedTokens(address[] memory _trustedTokens) external;
    function setAdapters(address[] memory _adapters) external;
    function setMinFee(uint256 _fee) external;
    function setFeeClaimer(address _claimer) external;

    function recoverERC20(address _tokenAddress, uint256 _tokenAmount) external;
    function recoverGAS(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@synapseprotocol/sol-lib/contracts/solc8/erc20/IERC20.sol";

interface ISynapseBridge {

  function deposit(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256 amount
  ) external;

  function depositAndSwap(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256 amount,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 minDy,
    uint256 deadline
  ) external;

  function redeem(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256 amount
  ) external;

  function redeemAndSwap(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256 amount,
    uint8 tokenIndexFrom,
    uint8 tokenIndexTo,
    uint256 minDy,
    uint256 deadline
  ) external;

  function redeemAndRemove(
    address to,
    uint256 chainId,
    IERC20 token,
    uint256 amount,
    uint8 liqTokenIndex,
    uint256 liqMinAmount,
    uint256 liqDeadline
  ) external;
}