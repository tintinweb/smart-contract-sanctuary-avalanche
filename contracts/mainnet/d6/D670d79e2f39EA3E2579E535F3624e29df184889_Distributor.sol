// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Distributor is Context, Ownable {
    using SafeERC20 for IERC20;
    uint256 public totalETHShares;
    uint256 public totalETHDistributed;


     /*///////////////////////////////////////////////////////////////
                            Mappings
    //////////////////////////////////////////////////////////////*/
   
    // Specification of total share for ETHER per wallet
    mapping(address => uint256) public sharesForETH;
    // Amount of ETH paid out to the account
    mapping(address => uint256) public distributedETH;

    mapping(IERC20 => uint256) public totalTokenShares;
    mapping(IERC20 => uint256) public totalTokenDistributed;
    // Specification of total shares tagged to the ERC20 Token Contract Address per wallet
    mapping(IERC20 => mapping(address => uint256)) public sharesForTokens; // IERC20 token -> account -> share
    // Amount of Token specified paid out to the account
    mapping(IERC20 => mapping(address => uint256)) public distributedTokens; // IERC20 token -> account -> distributed Tokens

    constructor () payable {
        
    }


         /*///////////////////////////////////////////////////////////////
                            Modifiers
    //////////////////////////////////////////////////////////////*/

    modifier nonZeroAddress(address account_) {
        require(account_ != address(0), "Distributor: Null address not allowed.");
        _;
    }

    modifier validShares(uint256 shares_) {
         require(shares_ > 0, "Distributor: Invalid shares specified.");
         _;
    }

    modifier registrationChecker(address[] memory accounts_, uint256[] memory shares_) {
        require(accounts_.length == shares_.length, "Distributor: Mismatch of addresses and shares.");
        _;
    }

        /*///////////////////////////////////////////////////////////////
                            Events
    //////////////////////////////////////////////////////////////*/
    event RegisterPayeeForETH(address account, uint256 shares);
    event RegisterPayeeForToken(address account, IERC20 token, uint256 shares );

    event AmendETHShares(address account, uint256 newShares);
    event AmendTokenShares(address account, IERC20 token, uint256 newShares);
 
    event ETHFundClaimed(address account,uint256 shares);
    event TokenFundClaimed(address account, IERC20 token, uint256 shares);

    event ETHReceived(address from, uint256 amount);
    event TokenReceived(address from, IERC20 token, uint256 amount);

  

     /*///////////////////////////////////////////////////////////////
                            External/Public Functions
    //////////////////////////////////////////////////////////////*/

   function registerPayeesForETH(address[] memory accounts_, uint256[] memory shares_) external registrationChecker(accounts_, shares_) onlyOwner {
        for(uint256 i = 0; i < accounts_.length; i++ ){
            _registerPayeesForETH(accounts_[i], shares_[i]);
        }
    }

    // @Desc: To batch register accounts with a specified share for a new ERC20 Token
    function registerPayeesForToken(address[] memory accounts_, IERC20 token_, uint256[] memory shares_) external registrationChecker(accounts_, shares_)  onlyOwner {
        require(accounts_.length == shares_.length, "Distributor: Mismatch of addresses and shares.");
        for(uint256 i = 0; i < accounts_.length; i++ ){
            _registerPayeesForTokens(accounts_[i], token_, shares_[i]);
        }
    }

    // @Desc: Amend a registered Payee's share for ETH distribution
    function amendPayeeETHShares(address account_, uint256 newShares_) external onlyOwner {
        require(sharesForETH[account_] > 0, "Distributor: Unregistered payee.");
        uint256 oldShares = sharesForETH[account_];
        sharesForETH[account_] = newShares_;
        totalETHShares = totalETHShares - oldShares + newShares_;

        emit AmendETHShares(account_, newShares_);
    }

     // @Desc: Amend a registered Payee's share for ERC20 Token distribution
     function amendPayeeTokenShares(address account_, IERC20 token_, uint256 newShares_) external onlyOwner {
        require(sharesForTokens[token_][account_] > 0, "Distributor: Unregistered payee.");
        uint256 oldShares = sharesForTokens[token_][account_];
        sharesForTokens[token_][account_] = newShares_;
        totalTokenShares[token_] = totalTokenShares[token_] - oldShares + newShares_;

        emit AmendTokenShares(account_, token_, newShares_);
     }
    
    // @Desc: Payout/Claim eligible amount of ether from contract based on shares
    function payoutETH(address payable account_) public {
        address payable account = account_;
        require(sharesForETH[account_] > 0, "Distributor: Not registered to claim ETH.");

        uint256 ethClaimable = claimableETH(account);

        //Send ether to receipient via a low-level call function
        require(address(this).balance >= ethClaimable, "Distributor: Insufficient ETH balance in contract.");
        
        totalETHDistributed += ethClaimable;
        distributedETH[account] = ethClaimable;
        account.transfer(ethClaimable);

        emit ETHFundClaimed(account, ethClaimable);
    }

    function payoutToken(address account_, IERC20 token_) public {
  
        require(sharesForTokens[token_][account_] > 0, "Distributor: Not registered to claim ERC20 token.");

        uint256 tokenAmountClaimable = claimableToken(account_, token_);

        // Transfer ERC20 via transfer function from SafeERC20
        require(token_.balanceOf(address(this)) >= tokenAmountClaimable, "Distributor: Insufficient ERC20 token balance.");
        
        totalTokenDistributed[token_] += tokenAmountClaimable;
        distributedTokens[token_][account_] += tokenAmountClaimable;
        token_.safeTransfer( account_, tokenAmountClaimable);

        emit TokenFundClaimed(account_, token_, tokenAmountClaimable);
    }

    function withdrawETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawToken(IERC20 token_) external onlyOwner {
        uint256 curTokenBalance = token_.balanceOf(address(this));
        require( curTokenBalance > 0, "Distributor: No Token Funds.");
        token_.transfer(msg.sender,curTokenBalance );
    }


      /*///////////////////////////////////////////////////////////////
                            Internal/Private Functions
    //////////////////////////////////////////////////////////////*/

    // @Desc: To register accounts as payees for token distribution.
    // @Note: tokenAddress_ to specify as Null Address to register a payee with shares for Ether.
    function _registerPayeesForETH(address account_, uint256 share_) private nonZeroAddress(account_) validShares(share_) {

        require(sharesForETH[account_] == 0, "Distributor: Account registered for ETH distribution.");


        sharesForETH[account_] = share_;
         totalETHShares += share_;
         
        emit RegisterPayeeForETH(account_, share_);
    }

    function _registerPayeesForTokens(address account_, IERC20 token_, uint256 share_) private nonZeroAddress(account_) validShares(share_) {
        require(sharesForTokens[token_][account_] == 0, "Distributor: Account already registered for token distribution,");
      

        sharesForTokens[token_][account_] = share_;
        totalTokenShares[token_] += share_;

        emit RegisterPayeeForToken(account_, token_, share_);
    }

    // @Desc: To calculate the outstanding amount for an account to claim from the contract based on how much total ether this contract received since its inception
    function outstandingETHClaim(address account_, uint256 totalReceived_, uint256 accountDistributed_) private view returns(uint256){
        return (totalReceived_ * sharesForETH[account_]) / totalETHShares - accountDistributed_;
    }

    // @Desc: To calculate outstanding amount of an ERC20 for an account to claim from the contract based on how much it has received since inception
    function outstandingTokenClaim(address account_, IERC20 tokenAddress_, uint totalTokenReceived_, uint256 accountTokenDistributed_) private view returns(uint256){
        return (totalTokenReceived_ * sharesForTokens[tokenAddress_][account_]) / totalTokenShares[tokenAddress_] - accountTokenDistributed_;
    }

    
      /*///////////////////////////////////////////////////////////////
                            Pure/View Functions
    //////////////////////////////////////////////////////////////*/

    // @Desc: To check how much ether an account is still eligible to claim
    function claimableETH(address account_) public view returns(uint256){
        uint256 totalReceived = address(this).balance + totalETHDistributed;

        return outstandingETHClaim(account_, totalReceived, distributedETH[account_]);
    }

    // @Desc: To check how much an ERC20 token an account is still eligible to claim
    function claimableToken(address account_, IERC20 tokenAddress_) public view returns(uint256){
        uint totalTokenReceived = tokenAddress_.balanceOf(address(this)) + totalTokenDistributed[tokenAddress_];

        return outstandingTokenClaim(account_, tokenAddress_, totalTokenReceived, distributedTokens[tokenAddress_][account_]);
    
    }

    

    // Fallback Function for contract to receive ETH
      receive() external payable virtual {
        emit ETHReceived(_msgSender(), msg.value);
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