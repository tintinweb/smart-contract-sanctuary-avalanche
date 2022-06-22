// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./FractBaseStrategy.sol";
import "./lib/openzeppelin/ReentrancyGuard.sol";
import "./lib/openzeppelin/SafeERC20.sol";
import "./interfaces/multichain/IAnyswapV5ERC20.sol";
import "./interfaces/multichain/IAnyswapV5Router.sol";

contract FractVaultV2 is Ownable, ReentrancyGuard {

    using SafeERC20 for IERC20;

    // Array of addresses of supported strategies.
    address[] public supportedStrategies;

    // Constant used as a bips divisor.       
    uint256 internal constant BIPS_DIVISOR = 10000;

    // Total capital deployed across strategies.
    uint256 public deployedCapital;

    // Deposit token that the vault manages.
    IERC20 public depositToken;

    //multichain router
    IAnyswapV5Router public anySwapRouter;

    // Mapping to check supportedStrategies array.
    mapping(address => bool) public supportedStrategiesMapping;

    //Mapping for strategy balance
    mapping(address => uint256) public strategyBalanceMapping;

    /**
     * @notice This event is fired when the vault receives a deposit.
     * @param account Specifies the depositor address.
     * @param amount Specifies the deposit amount.
     */
    event Deposit(address indexed account, uint256 amount);

    /**
     * @notice This event is fired when the vault receives a withdrawal.
     * @param account Specifies the withdrawer address.
     * @param amount Specifies the withdrawal amount,
     */
    event Withdraw(address indexed account, uint256 amount);

    /**
     * @notice This event is fired when the vault withdraws to a layer one address.
     * @param account Specifies the withdrawer address.
     * @param amount Specifies the withdrawal amount,
     */
    event WithdrawToLayerOne(address indexed account, uint256 amount);

    /**
     * @notice This event is fired when a strategy is added to supportedStrategies.
     * @param strategy The address of the strategy.
     */
    event AddStrategy(address indexed strategy);

    /**
     * @notice This event is fired when a strategy is removed from supportedStrategies.
     * @param strategy The address of the strategy.
     */
    event RemoveStrategy(address indexed strategy);

    /**
     * @notice This event is fired when funds are deployed to a strategy.
     * @param strategy The address of the strategy.
     * @param amount The amount deployed to the strategy.
     */
    event DeployToStrategy(address indexed strategy, uint256 amount);

     /**
     * @notice This event is fired when funds are withdrawn from a strategy.
     * @param strategy The address of the strategy.
     * @param amount The amount withdrawn from the strategy.
     */
    event WithdrawFromStrategy(address indexed strategy, uint256 amount);

    /**
     * @notice This event is fired when tokens are recovered from the strategy contract.
     * @param token Specifies the token that was recovered.
     * @param amount Specifies the amount that was recovered.
     */
    event WithdrawToEoa(address token, uint256 amount);

    /**
     * @notice This event is fired when the anyswap router address is set.
     * @param router Specifies the anyswap router address.
     */
    event SetRouterAddress(address router);

    /**
     * @notice This event is fired when the deployedCapital for a strategy is adjusted.
     * @param strategy The strategy to adjust deployedCapital on.
     * @param amount Specifies the new amount of deployedCapital.
     */
    event AdjustDeployedCapital(address strategy, uint256 amount);
    
    /**
     * @notice Constructor
     * @param _depositToken The address of the deposit token that the vault accepts. Uses the IERC20 Interface
     */
    constructor (address _depositToken) {
        depositToken = IERC20(_depositToken);
    }

    /**
     * @notice Owner method for setting the anyswap router address for crosschain withdrawals.
     * @param routerAddress The address of the anyswap router.
     */
    function setAnySwapRouter(address routerAddress) external onlyOwner {
        require(routerAddress != address(0), "Router address cannot be a 0 address");
        anySwapRouter = IAnyswapV5Router(routerAddress);
        emit SetRouterAddress(routerAddress);
    }

    /**
     * @notice Owner method for depositing to the vault, without deploying to a strategy.
     * @notice In order to deploy deposit amount to strategy, you must call deployToStrategy()
     * @notice Add the nonReentrant modifer to mitigate re-entry attacks.
     * @param amount amount
     */
    function depositToVault(uint256 amount) public onlyOwner nonReentrant {
        require(amount > 0, "Amount must be greater than 0");

        uint256 currentBalance = getCurrentBalance();
        uint256 expectedBalance = currentBalance + amount;

        emit Deposit(msg.sender, amount);

        depositToken.safeTransferFrom(msg.sender, address(this), amount);

        uint256 updatedBalance = getCurrentBalance();
        require(updatedBalance >= expectedBalance, "Balance verification failed");

    }

    /**
     * @notice Owner method for withdrawing from the vault.
     * @notice Add the nonReentrant modifer to mitigate re-entry attacks.
     * @param amount receipt tokens held by msg.sender. 
     */
    function withdraw(uint256 amount) public onlyOwner nonReentrant {
        require(amount > 0, "Must withdraw more than 0");

        emit Withdraw(msg.sender, amount);

        depositToken.safeTransfer(msg.sender, amount);
    }

    /**
     * @notice Owner method for withdrawing from the vault to layer one.
     * @param token address of token
     * @param toAddress address of toAddress on destination chain.
     * @param amount amount to withdraw to layer one via anyswap router.
     * @param chainId destination chain id to withdraw to.
     */
    function withdrawToLayerOne(
        address token, 
        address toAddress, 
        uint256 amount, 
        uint256 chainId) public onlyOwner {
        require(token != address(0), "token cannot be a 0 address");
        require(toAddress != address(0), "toAddress cannot be a 0 address");
        require(amount > 0, "Must withdraw more than 0");
        //add approval for anyswaprouter to spend anytoken
        IERC20(token).approve(address(anySwapRouter), amount);

        emit WithdrawToLayerOne(msg.sender, amount);

        anySwapRouter.anySwapOutUnderlying(token, toAddress, amount, chainId);
    }


    /**
     * @notice Owner method for adding supported strategy.
     * @param strategy address for new strategy
     */
    function addStrategy(address strategy) external onlyOwner {
        require(strategy != address(0), "Strategy is a 0 address");
        supportedStrategiesMapping[strategy] = true;
        supportedStrategies.push(strategy);
        
        emit AddStrategy(strategy);
    }

    /**
     * @notice Owner method for removing strategy. 
     * @param strategy address for new strategy
     */
    function removeStrategy(address strategy) external onlyOwner {
        address[] storage strategiesToRemove = supportedStrategies;
        require(strategy != address(0), "Strategy is a 0 address");
        require(supportedStrategiesMapping[strategy], "Strategy is not supported, cannot remove.");
        for (uint256 i = 0; i < strategiesToRemove.length; i++) {
            if (strategy == strategiesToRemove[i]) {
                strategiesToRemove[i] = strategiesToRemove[strategiesToRemove.length - 1];
                strategiesToRemove.pop();
                delete strategyBalanceMapping[strategy];
                break;
            }
        }
        supportedStrategies = strategiesToRemove;
        emit RemoveStrategy(strategy);
    }

        /**
     * @notice Owner method for deploying entire deposit token amount to a single strategy.
     * @param amount amount to deploy.
     * @param strategy strategy address.
     */
    function deployToStrategy(uint256 amount, address strategy) external onlyOwner {
        require(strategy != address(0), "no active strategy");
        require(supportedStrategiesMapping[strategy], "strategy not supported.");
        require(amount > 0, "0 amount");

        strategyBalanceMapping[strategy] = strategyBalanceMapping[strategy] + amount;

        deployedCapital += amount;

        emit DeployToStrategy(strategy, amount);

        depositToken.approve(strategy, amount);
        FractBaseStrategy(strategy).deposit(address(depositToken), amount);
        require(depositToken.approve(strategy, 0), "deployment Failed");
    }

    /**
     * @notice Owner method for removing funds from strategy.
     * @param strategy address of strategy to withdraw from. 
     */
    function withdrawFromStrategy(uint256 amount, address strategy) external onlyOwner {
        require(strategy != address(0), "0 address");
        require(supportedStrategiesMapping[strategy], "Strategy not supported");
        require(amount > 0, "0 amount");

        emit WithdrawFromStrategy(strategy, amount);

        FractBaseStrategy(strategy).withdraw(address(depositToken), amount);
    }


    /**
     * @notice Withdraw ERC20 from contract to EOA
     * @param tokenAddress token address
     * @param tokenAmount amount to recover
     */
    function withdrawToEoa(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "0 amount");
        emit WithdrawToEoa(tokenAddress, tokenAmount);
        require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount), "Withdraw Failed"); 
    }

    function adjustDeployedCapital(address strategy, uint256 amount) external onlyOwner {

        strategyBalanceMapping[strategy] = amount;

        emit AdjustDeployedCapital(strategy, amount);
    }


    function getStrategyBalance(address strategy) external view onlyOwner returns(uint256) {
        require(supportedStrategiesMapping[strategy]);
        return strategyBalanceMapping[strategy];
    }

    /**
     * @notice Returns current balance of deposit tokens in the vault. 
     */
    function getCurrentBalance() public view returns (uint256) {
        return depositToken.balanceOf(address(this));
    }

    /**
     * @notice Checks if strategy is a supported strategy.
     * @param strategy Address of strategy.
     */
    function checkStrategy(address strategy) external view returns (bool) {
        return supportedStrategiesMapping[strategy];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./lib/openzeppelin/Ownable.sol";
import "./lib/openzeppelin/IERC20.sol";
import "./lib/solmate/ERC20.sol";

/**
 * @notice FractBaseStrategy should be inherited by new strategies.
 */

abstract contract FractBaseStrategy is ERC20, Ownable {

    // Fractal Vault address;
    address public fractVault;
    
    // Constant used as a bips divisor. 
    uint256 constant internal BIPS_DIVISOR = 10000;

    // Constant for scaling values.
    uint256 public constant ONE_ETHER = 10**18;

    /**
     * @notice This event is fired when the strategy receives a deposit.
     * @param account Specifies the depositor address.
     * @param amount Specifies the deposit amount.
     */
    event Deposit(address indexed account, uint amount);

    /**
     * @notice This event is fired when the strategy receives a withdrawal.
     * @param account Specifies the withdrawer address.
     * @param amount Specifies the withdrawal amount,
     */
    event Withdraw(address indexed account, uint amount);

    /**
     * @notice This event is fired when tokens are withdrawn to an EOA.
     * @param token Specifies the token that was recovered.
     * @param amount Specifies the amount that was recovered.
     */
    event WithdrawToEoa(address token, uint amount);

    /**
     * @notice This event is fired when the vault contract address is set. 
     * @param vaultAddress Specifies the address of the fractVault. 
     */
    event SetVault(address indexed vaultAddress);
    
    /**
     * @notice Only called by vault
     */
    modifier onlyVault() {
        require(msg.sender == fractVault, "Only the fractVault can call this function.");
        _;
    }

    /**
     * @notice Sets the vault address the strategy will receive deposits from. 
     * @param vaultAddress Specifies the address of the poolContract. 
     */
    function setVaultAddress(address vaultAddress) external onlyOwner {
        require(vaultAddress != address(0), "Address cannot be a 0 address");
        fractVault = vaultAddress;

        emit SetVault(fractVault);

    }
    
    /**
     * @notice Revoke token allowance
     * @param token address
     * @param spender address
     */
    function revokeAllowance(address token, address spender) external onlyOwner {
        require(IERC20(token).approve(spender, 0), "Revoke Failed");
    }

    /**
     * @notice Deposit and deploy deposits tokens to the strategy
     * @dev Must mint receipt tokens to `msg.sender`
     * @param amount deposit tokens
     */
    function deposit(address depositToken, uint256 amount) external virtual;

    /**
     * @notice Redeem receipt tokens for deposit tokens
     * @param amount receipt tokens
     */
    function withdraw(address depositToken, uint256 amount) external virtual;
    
    /**
     * @notice Withdraw ERC20 from contract to EOA
     * @param tokenAddress token address
     * @param tokenAmount amount to recover
     */
    function withdrawToEoa(address tokenAddress, uint256 tokenAmount) external onlyOwner {
        require(tokenAmount > 0, "0 amount");
        emit WithdrawToEoa(tokenAddress, tokenAmount);
        require(IERC20(tokenAddress).transfer(msg.sender, tokenAmount), "Withdraw Failed"); 
    }
    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity 0.8.10;

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.8.10;

import "./IERC20.sol";
import "./Address.sol";

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
pragma solidity ^0.8.0;

interface IAnyswapV5ERC20 {
  function DOMAIN_SEPARATOR() external view returns (bytes32);
  function PERMIT_TYPEHASH() external view returns (bytes32);
  function Swapin(bytes32 txhash, address account, uint256 amount) external returns (bool);
  function Swapout(uint256 amount, address bindaddr) external returns (bool);
  function TRANSFER_TYPEHASH() external view returns (bytes32);
  function allowance(address, address) external view returns (uint256);
  function applyMinter() external;
  function applyVault() external;
  function approve(address spender, uint256 value) external returns (bool);
  function approveAndCall(address spender, uint256 value, bytes calldata data) external returns (bool);
  function balanceOf(address) external view returns (uint256);
  function burn(address from, uint256 amount) external returns (bool);
  function changeMPCOwner(address newVault) external returns (bool);
  function changeVault(address newVault) external returns (bool);
  function decimals() external view returns (uint8);
  function delay() external view returns (uint256);
  function delayDelay() external view returns (uint256);
  function delayMinter() external view returns (uint256);
  function delayVault() external view returns (uint256);
  function deposit(uint256 amount, address to) external returns (uint256);
  function deposit(uint256 amount) external returns (uint256);
  function deposit() external returns (uint256);
  function depositVault(uint256 amount, address to) external returns (uint256);
  function depositWithPermit(address target, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s, address to) external returns (uint256);
  function depositWithTransferPermit(address target, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s, address to) external returns (uint256);
  function getAllMinters() external view returns (address[] memory);
  function initVault(address _vault) external;
  function isMinter(address) external view returns (bool);
  function mint(address to, uint256 amount) external returns (bool);
  function minters(uint256) external view returns (address);
  function mpc() external view returns (address);
  function name() external view returns (string memory);
  function nonces(address) external view returns (uint256);
  function owner() external view returns (address);
  function pendingDelay() external view returns (uint256);
  function pendingMinter() external view returns (address);
  function pendingVault() external view returns (address);
  function permit(address target, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
  function revokeMinter(address _auth) external;
  function setMinter(address _auth) external;
  function setVault(address _vault) external;
  function setVaultOnly(bool enabled) external;
  function symbol() external view returns (string memory);
  function totalSupply() external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function transferAndCall(address to, uint256 value, bytes calldata data) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
  function underlying() external view returns (address);
  function vault() external view returns (address);
  function withdraw(uint256 amount, address to) external returns (uint256);
  function withdraw(uint256 amount) external returns (uint256);
  function withdraw() external returns (uint256);
  function withdrawVault(address from, uint256 amount, address to) external returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IAnyswapV5Router {
    function anySwapOutUnderlying(address token, address to, uint amount, uint toChainID) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity 0.8.10;

import "./Context.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.10;

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

    function decimals() external view returns (uint8);

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                             EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity 0.8.10;

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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.10;

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