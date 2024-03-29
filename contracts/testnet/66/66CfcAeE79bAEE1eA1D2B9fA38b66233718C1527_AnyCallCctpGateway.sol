// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { IActionDataStructures } from './interfaces/IActionDataStructures.sol';
import { IGateway } from './crosschain/interfaces/IGateway.sol';
import { IGatewayClient } from './crosschain/interfaces/IGatewayClient.sol';
import { IRegistry } from './interfaces/IRegistry.sol';
import { ISettings } from './interfaces/ISettings.sol';
import { ITokenMint } from './interfaces/ITokenMint.sol';
import { IVariableBalanceRecords } from './interfaces/IVariableBalanceRecords.sol';
import { IVault } from './interfaces/IVault.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { CallerGuard } from './CallerGuard.sol';
import { Pausable } from './Pausable.sol';
import { SystemVersionId } from './SystemVersionId.sol';
import { TokenMintError, ZeroAddressError } from './Errors.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './helpers/DecimalsHelper.sol' as DecimalsHelper;
import './helpers/GasReserveHelper.sol' as GasReserveHelper;
import './helpers/RefundHelper.sol' as RefundHelper;
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

/**
 * @title ActionExecutor
 * @notice The main contract for cross-chain swaps
 */
contract ActionExecutor is
    SystemVersionId,
    Pausable,
    ReentrancyGuard,
    CallerGuard,
    BalanceManagement,
    IGatewayClient,
    ISettings,
    IActionDataStructures
{
    /**
     * @dev The contract for action settings
     */
    IRegistry public registry;

    /**
     * @dev The contract for variable balance storage
     */
    IVariableBalanceRecords public variableBalanceRecords;

    uint256 private lastActionId = block.chainid * 1e7 + 555 ** 2;

    /**
     * @notice Emitted when source chain action is performed
     * @param actionId The ID of the action
     * @param targetChainId The ID of the target chain
     * @param sourceSender The address of the user on the source chain
     * @param targetRecipient The address of the recipient on the target chain
     * @param gatewayType The type of cross-chain gateway
     * @param sourceToken The address of the input token on the source chain
     * @param targetToken The address of the output token on the target chain
     * @param amount The amount of the vault asset used for the action, with decimals set to 18
     * @param fee The fee amount, measured in vault asset with decimals set to 18
     * @param timestamp The timestamp of the action (in seconds)
     */
    event ActionSource(
        uint256 indexed actionId,
        uint256 indexed targetChainId,
        address indexed sourceSender,
        address targetRecipient,
        uint256 gatewayType,
        address sourceToken,
        address targetToken,
        uint256 amount,
        uint256 fee,
        uint256 timestamp
    );

    /**
     * @notice Emitted when target chain action is performed
     * @param actionId The ID of the action
     * @param sourceChainId The ID of the source chain
     * @param isSuccess The status of the action execution
     * @param timestamp The timestamp of the action (in seconds)
     */
    event ActionTarget(
        uint256 indexed actionId,
        uint256 indexed sourceChainId,
        bool indexed isSuccess,
        uint256 timestamp
    );

    /**
     * @notice Emitted when single-chain action is performed
     * @param actionId The ID of the action
     * @param sender The address of the user
     * @param recipient The address of the recipient
     * @param fromToken The address of the input token
     * @param toToken The address of the output token
     * @param fromAmount The input token amount
     * @param toAmount The output token amount
     * @param toTokenFee The fee amount, measured in the output token
     * @param timestamp The timestamp of the action (in seconds)
     */
    event ActionLocal(
        uint256 indexed actionId,
        address indexed sender,
        address recipient,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 toTokenFee,
        uint256 timestamp
    );

    /**
     * @notice Emitted for source chain and single-chain actions when user's funds processing is completed
     * @param actionId The ID of the action
     * @param isLocal The action type flag, is true for single-chain actions
     * @param sender The address of the user
     * @param routerType The type of the swap router
     * @param fromTokenAddress The address of the swap input token
     * @param toTokenAddress The address of the swap output token
     * @param fromAmount The input token amount
     * @param resultAmount The swap result token amount
     */
    event SourceProcessed(
        uint256 indexed actionId,
        bool indexed isLocal,
        address indexed sender,
        uint256 routerType,
        address fromTokenAddress,
        address toTokenAddress,
        uint256 fromAmount,
        uint256 resultAmount
    );

    /**
     * @notice Emitted for target chain actions when the user's funds processing is completed
     * @param actionId The ID of the action
     * @param recipient The address of the recipient
     * @param routerType The type of the swap router
     * @param fromTokenAddress The address of the swap input token
     * @param toTokenAddress The address of the swap output token
     * @param fromAmount The input token amount
     * @param resultAmount The swap result token amount
     */
    event TargetProcessed(
        uint256 indexed actionId,
        address indexed recipient,
        uint256 routerType,
        address fromTokenAddress,
        address toTokenAddress,
        uint256 fromAmount,
        uint256 resultAmount
    );

    /**
     * @notice Emitted when the variable balance is allocated on the target chain
     * @param actionId The ID of the action
     * @param recipient The address of the variable balance recipient
     * @param vaultType The type of the corresponding vault
     * @param amount The allocated variable balance amount
     */
    event VariableBalanceAllocated(
        uint256 indexed actionId,
        address indexed recipient,
        uint256 vaultType,
        uint256 amount
    );

    /**
     * @notice Emitted when the Registry contract address is updated
     * @param registryAddress The address of the Registry contract
     */
    event SetRegistry(address indexed registryAddress);

    /**
     * @notice Emitted when the VariableBalanceRecords contract address is updated
     * @param recordsAddress The address of the VariableBalanceRecords contract
     */
    event SetVariableBalanceRecords(address indexed recordsAddress);

    /**
     * @notice Emitted when the caller is not a registered cross-chain gateway
     */
    error OnlyGatewayError();

    /**
     * @notice Emitted when the call is not from the current contract
     */
    error OnlySelfError();

    /**
     * @notice Emitted when a cross-chain swap is attempted with the target chain ID matching the current chain
     */
    error SameChainIdError();

    /**
     * @notice Emitted when a single-chain swap is attempted with the same token as input and output
     */
    error SameTokenError();

    /**
     * @notice Emitted when the native token value of the transaction does not correspond to the swap amount
     */
    error NativeTokenValueError();

    /**
     * @notice Emitted when the requested cross-chain gateway type is not set
     */
    error GatewayNotSetError();

    /**
     * @notice Emitted when the requested swap router type is not set
     */
    error RouterNotSetError();

    /**
     * @notice Emitted when the requested vault type is not set
     */
    error VaultNotSetError();

    /**
     * @notice Emitted when the provided call value is not sufficient for the cross-chain message sending
     */
    error MessageFeeError();

    /**
     * @notice Emitted when the swap amount is greater than the allowed maximum
     */
    error SwapAmountMaxError();

    /**
     * @notice Emitted when the swap amount is less than the allowed minimum
     */
    error SwapAmountMinError();

    /**
     * @notice Emitted when the swap process results in an error
     */
    error SwapError();

    /**
     * @notice Emitted when there is no matching target swap info option
     */
    error TargetSwapInfoError();

    /**
     * @dev Modifier to check if the caller is a registered cross-chain gateway
     */
    modifier onlyGateway() {
        if (!registry.isGatewayAddress(msg.sender)) {
            revert OnlyGatewayError();
        }

        _;
    }

    /**
     * @dev Modifier to check if the caller is the current contract
     */
    modifier onlySelf() {
        if (msg.sender != address(this)) {
            revert OnlySelfError();
        }

        _;
    }

    /**
     * @notice Deploys the ActionExecutor contract
     * @param _registry The address of the action settings registry contract
     * @param _variableBalanceRecords The address of the variable balance records contract
     * @param _actionIdOffset The initial offset of the action ID value
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        IRegistry _registry,
        IVariableBalanceRecords _variableBalanceRecords,
        uint256 _actionIdOffset,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        _setRegistry(_registry);
        _setVariableBalanceRecords(_variableBalanceRecords);

        lastActionId += _actionIdOffset;

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice The standard "receive" function
     * @dev Is payable to allow receiving native token funds from a target swap router
     */
    receive() external payable {}

    /**
     * @notice Sets the address of the action settings registry contract
     * @param _registry The address of the action settings registry contract
     */
    function setRegistry(IRegistry _registry) external onlyManager {
        _setRegistry(_registry);
    }

    /**
     * @notice Executes a single-chain action
     * @param _localAction The parameters of the action
     */
    function executeLocal(
        LocalAction calldata _localAction
    ) external payable whenNotPaused nonReentrant checkCaller returns (uint256 actionId) {
        if (_localAction.fromTokenAddress == _localAction.toTokenAddress) {
            revert SameTokenError();
        }

        // For single-chain swaps of the native token,
        // the value of the transaction should be equal to the swap amount
        if (
            _localAction.fromTokenAddress == Constants.NATIVE_TOKEN_ADDRESS &&
            msg.value != _localAction.swapInfo.fromAmount
        ) {
            revert NativeTokenValueError();
        }

        uint256 initialBalance = address(this).balance - msg.value;

        lastActionId++;
        actionId = lastActionId;

        LocalSettings memory settings = registry.localSettings(
            msg.sender,
            _localAction.swapInfo.routerType
        );

        (uint256 processedAmount, ) = _processSource(
            actionId,
            true,
            _localAction.fromTokenAddress,
            _localAction.toTokenAddress,
            _localAction.swapInfo,
            settings.router,
            settings.routerTransfer
        );

        address recipient = _localAction.recipient == address(0)
            ? msg.sender
            : _localAction.recipient;

        uint256 recipientAmount = _calculateLocalAmount(
            processedAmount,
            true,
            settings.systemFeeLocal,
            settings.isWhitelist
        );

        if (_localAction.toTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(recipient, recipientAmount);
        } else {
            TransferHelper.safeTransfer(_localAction.toTokenAddress, recipient, recipientAmount);
        }

        // - - - System fee transfer - - -

        uint256 systemFeeAmount = processedAmount - recipientAmount;

        if (systemFeeAmount > 0) {
            address feeCollector = settings.feeCollectorLocal;

            if (feeCollector != address(0)) {
                if (_localAction.toTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
                    TransferHelper.safeTransferNative(feeCollector, systemFeeAmount);
                } else {
                    TransferHelper.safeTransfer(
                        _localAction.toTokenAddress,
                        feeCollector,
                        systemFeeAmount
                    );
                }
            } else if (_localAction.toTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
                initialBalance += systemFeeAmount; // Keep at the contract address
            }
        }

        // - - -

        // - - - Extra balance transfer - - -

        RefundHelper.refundExtraBalance(address(this), initialBalance, payable(msg.sender));

        // - - -

        emit ActionLocal(
            actionId,
            msg.sender,
            recipient,
            _localAction.fromTokenAddress,
            _localAction.toTokenAddress,
            _localAction.swapInfo.fromAmount,
            recipientAmount,
            systemFeeAmount,
            block.timestamp
        );
    }

    /**
     * @notice Executes a cross-chain action
     * @param _action The parameters of the action
     */
    function execute(
        Action calldata _action
    ) external payable whenNotPaused nonReentrant checkCaller returns (uint256 actionId) {
        if (_action.targetChainId == block.chainid) {
            revert SameChainIdError();
        }

        // For cross-chain swaps of the native token,
        // the value of the transaction should be greater or equal to the swap amount
        if (
            _action.sourceTokenAddress == Constants.NATIVE_TOKEN_ADDRESS &&
            msg.value < _action.sourceSwapInfo.fromAmount
        ) {
            revert NativeTokenValueError();
        }

        uint256 initialBalance = address(this).balance - msg.value;

        lastActionId++;
        actionId = lastActionId;

        SourceSettings memory settings = registry.sourceSettings(
            msg.sender,
            _action.targetChainId,
            _action.gatewayType,
            _action.sourceSwapInfo.routerType,
            _action.vaultType
        );

        if (settings.vault == address(0)) {
            revert VaultNotSetError();
        }

        address vaultAsset = IVault(settings.vault).asset();

        (uint256 processedAmount, uint256 nativeTokenSpent) = _processSource(
            actionId,
            false,
            _action.sourceTokenAddress,
            vaultAsset,
            _action.sourceSwapInfo,
            settings.router,
            settings.routerTransfer
        );

        uint256 targetVaultAmountMax = _calculateVaultAmount(
            settings.sourceVaultDecimals,
            settings.targetVaultDecimals,
            processedAmount,
            true,
            settings.systemFee,
            settings.isWhitelist
        );

        SwapInfo memory targetSwapInfo;

        uint256 targetOptionsLength = _action.targetSwapInfoOptions.length;

        if (targetOptionsLength == 0) {
            targetSwapInfo = SwapInfo({
                fromAmount: targetVaultAmountMax,
                routerType: uint256(0),
                routerData: new bytes(0)
            });
        } else {
            for (uint256 index; index < targetOptionsLength; index++) {
                SwapInfo memory targetSwapInfoOption = _action.targetSwapInfoOptions[index];

                if (targetSwapInfoOption.fromAmount <= targetVaultAmountMax) {
                    targetSwapInfo = targetSwapInfoOption;

                    break;
                }
            }

            if (targetSwapInfo.fromAmount == 0) {
                revert TargetSwapInfoError();
            }
        }

        uint256 sourceVaultAmount = DecimalsHelper.convertDecimals(
            settings.targetVaultDecimals,
            settings.sourceVaultDecimals,
            targetSwapInfo.fromAmount
        );

        uint256 normalizedAmount = DecimalsHelper.convertDecimals(
            settings.sourceVaultDecimals,
            Constants.DECIMALS_DEFAULT,
            sourceVaultAmount
        );

        if (!settings.isWhitelist) {
            _checkSwapAmountLimits(
                normalizedAmount,
                settings.swapAmountMin,
                settings.swapAmountMax
            );
        }

        // - - - Transfer to vault - - -

        TransferHelper.safeTransfer(vaultAsset, settings.vault, sourceVaultAmount);

        // - - -

        bytes memory targetMessageData = abi.encode(
            TargetMessage({
                actionId: actionId,
                sourceSender: msg.sender,
                vaultType: _action.vaultType,
                targetTokenAddress: _action.targetTokenAddress,
                targetSwapInfo: targetSwapInfo,
                targetRecipient: _action.targetRecipient == address(0)
                    ? msg.sender
                    : _action.targetRecipient
            })
        );

        _sendMessage(settings, _action, targetMessageData, msg.value - nativeTokenSpent);

        // - - - System fee transfer - - -

        uint256 systemFeeAmount = processedAmount - sourceVaultAmount;

        if (systemFeeAmount > 0 && settings.feeCollector != address(0)) {
            TransferHelper.safeTransfer(vaultAsset, settings.feeCollector, systemFeeAmount);
        }

        // - - -

        // - - - Extra balance transfer - - -

        RefundHelper.refundExtraBalance(address(this), initialBalance, payable(msg.sender));

        // - - -

        _emitActionSourceEvent(
            actionId,
            _action,
            normalizedAmount,
            DecimalsHelper.convertDecimals(
                settings.sourceVaultDecimals,
                Constants.DECIMALS_DEFAULT,
                systemFeeAmount
            )
        );
    }

    /**
     * @notice Variable token claim by user's variable balance
     * @param _vaultType The type of the variable balance vault
     */
    function claimVariableToken(
        uint256 _vaultType
    ) external whenNotPaused nonReentrant checkCaller {
        _processVariableBalanceRepayment(_vaultType, false);
    }

    /**
     * @notice Vault asset claim by user's variable balance
     * @param _vaultType The type of the variable balance vault
     */
    function convertVariableBalanceToVaultAsset(
        uint256 _vaultType
    ) external whenNotPaused nonReentrant checkCaller {
        _processVariableBalanceRepayment(_vaultType, true);
    }

    /**
     * @notice Cross-chain message fee estimation
     * @param _gatewayType The type of the cross-chain gateway
     * @param _targetChainId The ID of the target chain
     * @param _targetRouterDataOptions The array of transaction data options for the target chain
     * @param _gatewaySettings The settings specific to the selected cross-chain gateway
     */
    function messageFeeEstimate(
        uint256 _gatewayType,
        uint256 _targetChainId,
        bytes[] calldata _targetRouterDataOptions,
        bytes calldata _gatewaySettings
    ) external view returns (uint256) {
        if (_targetChainId == block.chainid) {
            return 0;
        }

        MessageFeeEstimateSettings memory settings = registry.messageFeeEstimateSettings(
            _gatewayType
        );

        if (settings.gateway == address(0)) {
            revert GatewayNotSetError();
        }

        uint256 result = 0;

        if (_targetRouterDataOptions.length == 0) {
            result = IGateway(settings.gateway).messageFee(
                _targetChainId,
                _blankMessage(new bytes(0)),
                _gatewaySettings
            );
        } else {
            for (uint256 index; index < _targetRouterDataOptions.length; index++) {
                bytes memory messageData = _blankMessage(_targetRouterDataOptions[index]);

                uint256 value = IGateway(settings.gateway).messageFee(
                    _targetChainId,
                    messageData,
                    _gatewaySettings
                );

                if (value > result) {
                    result = value;
                }
            }
        }

        return result;
    }

    /**
     * @notice Swap result amount for single-chain actions, taking the system fee into account
     * @param _fromAmount The amount before the calculation
     * @param _isForward The direction of the calculation
     */
    function calculateLocalAmount(
        uint256 _fromAmount,
        bool _isForward
    ) external view returns (uint256 result) {
        LocalAmountCalculationSettings memory settings = registry.localAmountCalculationSettings(
            msg.sender
        );

        return
            _calculateLocalAmount(
                _fromAmount,
                _isForward,
                settings.systemFeeLocal,
                settings.isWhitelist
            );
    }

    /**
     * @notice Swap result amount for cross-chain actions, taking the system fee into account
     * @param _vaultType The type of the vault
     * @param _fromChainId The ID of the source chain
     * @param _toChainId The ID of the target chain
     * @param _fromAmount The amount before the calculation
     * @param _isForward The direction of the calculation
     */
    function calculateVaultAmount(
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId,
        uint256 _fromAmount,
        bool _isForward
    ) external view returns (uint256 result) {
        VaultAmountCalculationSettings memory settings = registry.vaultAmountCalculationSettings(
            msg.sender,
            _vaultType,
            _fromChainId,
            _toChainId
        );

        return
            _calculateVaultAmount(
                settings.fromDecimals,
                settings.toDecimals,
                _fromAmount,
                _isForward,
                settings.systemFee,
                settings.isWhitelist
            );
    }

    /**
     * @notice The variable balance of the account
     * @param _account The address of the variable balance owner
     * @param _vaultType The type of the vault
     */
    function variableBalance(address _account, uint256 _vaultType) external view returns (uint256) {
        return variableBalanceRecords.getAccountBalance(_account, _vaultType);
    }

    /**
     * @notice Cross-chain message handler on the target chain
     * @dev The function is called by cross-chain gateways
     * @param _messageSourceChainId The ID of the message source chain
     * @param _payloadData The content of the cross-chain message
     */
    function handleExecutionPayload(
        uint256 _messageSourceChainId,
        bytes calldata _payloadData
    ) external whenNotPaused onlyGateway {
        TargetMessage memory targetMessage = abi.decode(_payloadData, (TargetMessage));

        TargetSettings memory settings = registry.targetSettings(
            targetMessage.vaultType,
            targetMessage.targetSwapInfo.routerType
        );

        bool selfCallSuccess;

        (bool hasGasReserve, uint256 gasAllowed) = GasReserveHelper.checkGasReserve(
            settings.gasReserve
        );

        if (hasGasReserve) {
            try this.selfCallTarget{ gas: gasAllowed }(settings, targetMessage) {
                selfCallSuccess = true;
            } catch {}
        }

        if (!selfCallSuccess) {
            _targetAllocateVariableBalance(targetMessage);
        }

        emit ActionTarget(
            targetMessage.actionId,
            _messageSourceChainId,
            selfCallSuccess,
            block.timestamp
        );
    }

    /**
     * @notice Controllable processing of the target chain logic
     * @dev Is called by the current contract to enable error handling
     * @param _settings Target action settings
     * @param _targetMessage The content of the cross-chain message
     */
    function selfCallTarget(
        TargetSettings calldata _settings,
        TargetMessage calldata _targetMessage
    ) external onlySelf {
        if (_settings.vault == address(0)) {
            revert VaultNotSetError();
        }

        // - - - Transfer from vault - - -

        address assetAddress = IVault(_settings.vault).requestAsset(
            _targetMessage.targetSwapInfo.fromAmount,
            address(this),
            false
        );

        // - - -

        _processTarget(
            _settings,
            _targetMessage.actionId,
            assetAddress,
            _targetMessage.targetTokenAddress,
            _targetMessage.targetSwapInfo,
            _targetMessage.targetRecipient
        );
    }

    function _processSource(
        uint256 _actionId,
        bool _isLocal,
        address _fromTokenAddress,
        address _toTokenAddress,
        SwapInfo memory _sourceSwapInfo,
        address _routerAddress,
        address _routerTransferAddress
    ) private returns (uint256 resultAmount, uint256 nativeTokenSpent) {
        uint256 toTokenBalanceBefore = tokenBalance(_toTokenAddress);

        if (_fromTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            if (_routerAddress == address(0)) {
                revert RouterNotSetError();
            }

            // - - - Source swap (native token) - - -

            (bool routerCallSuccess, ) = payable(_routerAddress).call{
                value: _sourceSwapInfo.fromAmount
            }(_sourceSwapInfo.routerData);

            if (!routerCallSuccess) {
                revert SwapError();
            }

            // - - -

            nativeTokenSpent = _sourceSwapInfo.fromAmount;
        } else {
            TransferHelper.safeTransferFrom(
                _fromTokenAddress,
                msg.sender,
                address(this),
                _sourceSwapInfo.fromAmount
            );

            if (_fromTokenAddress != _toTokenAddress) {
                if (_routerAddress == address(0)) {
                    revert RouterNotSetError();
                }

                // - - - Source swap (non-native token) - - -

                TransferHelper.safeApprove(
                    _fromTokenAddress,
                    _routerTransferAddress,
                    _sourceSwapInfo.fromAmount
                );

                (bool routerCallSuccess, ) = _routerAddress.call(_sourceSwapInfo.routerData);

                if (!routerCallSuccess) {
                    revert SwapError();
                }

                TransferHelper.safeApprove(_fromTokenAddress, _routerTransferAddress, 0);

                // - - -
            }

            nativeTokenSpent = 0;
        }

        resultAmount = tokenBalance(_toTokenAddress) - toTokenBalanceBefore;

        emit SourceProcessed(
            _actionId,
            _isLocal,
            msg.sender,
            _sourceSwapInfo.routerType,
            _fromTokenAddress,
            _toTokenAddress,
            _sourceSwapInfo.fromAmount,
            resultAmount
        );
    }

    function _processTarget(
        TargetSettings memory settings,
        uint256 _actionId,
        address _fromTokenAddress,
        address _toTokenAddress,
        SwapInfo memory _targetSwapInfo,
        address _targetRecipient
    ) private {
        uint256 resultAmount;

        if (_toTokenAddress == _fromTokenAddress) {
            resultAmount = _targetSwapInfo.fromAmount;
        } else {
            if (settings.router == address(0)) {
                revert RouterNotSetError();
            }

            uint256 toTokenBalanceBefore = tokenBalance(_toTokenAddress);

            // - - - Target swap - - -

            TransferHelper.safeApprove(
                _fromTokenAddress,
                settings.routerTransfer,
                _targetSwapInfo.fromAmount
            );

            (bool success, ) = settings.router.call(_targetSwapInfo.routerData);

            if (!success) {
                revert SwapError();
            }

            TransferHelper.safeApprove(_fromTokenAddress, settings.routerTransfer, 0);

            // - - -

            resultAmount = tokenBalance(_toTokenAddress) - toTokenBalanceBefore;
        }

        if (_toTokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(_targetRecipient, resultAmount);
        } else {
            TransferHelper.safeTransfer(_toTokenAddress, _targetRecipient, resultAmount);
        }

        emit TargetProcessed(
            _actionId,
            _targetRecipient,
            _targetSwapInfo.routerType,
            _fromTokenAddress,
            _toTokenAddress,
            _targetSwapInfo.fromAmount,
            resultAmount
        );
    }

    function _targetAllocateVariableBalance(TargetMessage memory _targetMessage) private {
        address tokenRecipient = _targetMessage.targetRecipient;
        uint256 vaultType = _targetMessage.vaultType;
        uint256 tokenAmount = _targetMessage.targetSwapInfo.fromAmount;

        variableBalanceRecords.increaseBalance(tokenRecipient, vaultType, tokenAmount);

        emit VariableBalanceAllocated(
            _targetMessage.actionId,
            tokenRecipient,
            vaultType,
            tokenAmount
        );
    }

    function _processVariableBalanceRepayment(
        uint256 _vaultType,
        bool _convertToVaultAsset
    ) private {
        VariableBalanceRepaymentSettings memory settings = registry
            .variableBalanceRepaymentSettings(_vaultType);

        if (settings.vault == address(0)) {
            revert VaultNotSetError();
        }

        uint256 tokenAmount = variableBalanceRecords.getAccountBalance(msg.sender, _vaultType);

        variableBalanceRecords.clearBalance(msg.sender, _vaultType);

        if (tokenAmount > 0) {
            if (_convertToVaultAsset) {
                IVault(settings.vault).requestAsset(tokenAmount, msg.sender, true);
            } else {
                address variableTokenAddress = IVault(settings.vault).checkVariableTokenState();

                bool mintSuccess = ITokenMint(variableTokenAddress).mint(msg.sender, tokenAmount);

                if (!mintSuccess) {
                    revert TokenMintError();
                }
            }
        }
    }

    function _setRegistry(IRegistry _registry) private {
        AddressHelper.requireContract(address(_registry));

        registry = _registry;

        emit SetRegistry(address(_registry));
    }

    function _setVariableBalanceRecords(IVariableBalanceRecords _variableBalanceRecords) private {
        AddressHelper.requireContract(address(_variableBalanceRecords));

        variableBalanceRecords = _variableBalanceRecords;

        emit SetVariableBalanceRecords(address(_variableBalanceRecords));
    }

    function _sendMessage(
        SourceSettings memory settings,
        Action calldata _action,
        bytes memory _messageData,
        uint256 _availableValue
    ) private {
        if (settings.gateway == address(0)) {
            revert GatewayNotSetError();
        }

        uint256 messageFee = IGateway(settings.gateway).messageFee(
            _action.targetChainId,
            _messageData,
            _action.gatewaySettings
        );

        if (_availableValue < messageFee) {
            revert MessageFeeError();
        }

        IGateway(settings.gateway).sendMessage{ value: messageFee }(
            _action.targetChainId,
            _messageData,
            _action.gatewaySettings
        );
    }

    function _emitActionSourceEvent(
        uint256 _actionId,
        Action calldata _action,
        uint256 _amount,
        uint256 _fee
    ) private {
        emit ActionSource(
            _actionId,
            _action.targetChainId,
            msg.sender,
            _action.targetRecipient,
            _action.gatewayType,
            _action.sourceTokenAddress,
            _action.targetTokenAddress,
            _amount,
            _fee,
            block.timestamp
        );
    }

    function _checkSwapAmountLimits(
        uint256 _normalizedAmount,
        uint256 _swapAmountMin,
        uint256 _swapAmountMax
    ) private pure {
        if (_normalizedAmount < _swapAmountMin) {
            revert SwapAmountMinError();
        }

        if (_normalizedAmount > _swapAmountMax) {
            revert SwapAmountMaxError();
        }
    }

    function _calculateLocalAmount(
        uint256 _fromAmount,
        bool _isForward,
        uint256 _systemFeeLocal,
        bool _isWhitelist
    ) private pure returns (uint256 result) {
        if (_isWhitelist || _systemFeeLocal == 0) {
            return _fromAmount;
        }

        return
            _isForward
                ? (_fromAmount * (Constants.MILLIPERCENT_FACTOR - _systemFeeLocal)) /
                    Constants.MILLIPERCENT_FACTOR
                : (_fromAmount * Constants.MILLIPERCENT_FACTOR) /
                    (Constants.MILLIPERCENT_FACTOR - _systemFeeLocal);
    }

    function _calculateVaultAmount(
        uint256 _fromDecimals,
        uint256 _toDecimals,
        uint256 _fromAmount,
        bool _isForward,
        uint256 _systemFee,
        bool _isWhitelist
    ) private pure returns (uint256 result) {
        bool isZeroFee = _isWhitelist || _systemFee == 0;

        uint256 amountToConvert = (!_isForward || isZeroFee)
            ? _fromAmount
            : (_fromAmount * (Constants.MILLIPERCENT_FACTOR - _systemFee)) /
                Constants.MILLIPERCENT_FACTOR;

        uint256 convertedAmount = DecimalsHelper.convertDecimals(
            _fromDecimals,
            _toDecimals,
            amountToConvert
        );

        result = (_isForward || isZeroFee)
            ? convertedAmount
            : (convertedAmount * Constants.MILLIPERCENT_FACTOR) /
                (Constants.MILLIPERCENT_FACTOR - _systemFee);
    }

    function _blankMessage(bytes memory _targetRouterData) private pure returns (bytes memory) {
        bytes memory messageData = abi.encode(
            TargetMessage({
                actionId: uint256(0),
                sourceSender: address(0),
                vaultType: uint256(0),
                targetTokenAddress: address(0),
                targetSwapInfo: SwapInfo({
                    fromAmount: uint256(0),
                    routerType: uint256(0),
                    routerData: _targetRouterData
                }),
                targetRecipient: address(0)
            })
        );

        return messageData;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { IRegistry } from './interfaces/IRegistry.sol';
import { IVault } from './interfaces/IVault.sol';
import { BalanceManagement } from './BalanceManagement.sol';
import { SystemVersionId } from './SystemVersionId.sol';
import { TargetGasReserve } from './crosschain/TargetGasReserve.sol';
import { ZeroAddressError } from './Errors.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './helpers/DecimalsHelper.sol' as DecimalsHelper;
import './Constants.sol' as Constants;
import './DataStructures.sol' as DataStructures;

/**
 * @title ActionExecutorRegistry
 * @notice The contract for action settings
 */
contract ActionExecutorRegistry is SystemVersionId, TargetGasReserve, BalanceManagement, IRegistry {
    /**
     * @dev Registered cross-chain gateway addresses by type
     */
    mapping(uint256 /*gatewayType*/ => address /*gatewayAddress*/) public gatewayMap;

    /**
     * @dev Registered cross-chain gateway types
     */
    uint256[] public gatewayTypeList;

    /**
     * @dev Registered cross-chain gateway type indices
     */
    mapping(uint256 /*gatewayType*/ => DataStructures.OptionalValue /*gatewayTypeIndex*/)
        public gatewayTypeIndexMap;

    /**
     * @dev Registered cross-chain gateway flags by address
     */
    mapping(address /*account*/ => bool /*isGateway*/) public isGatewayAddress;

    /**
     * @dev Registered swap router addresses by type
     */
    mapping(uint256 /*routerType*/ => address /*routerAddress*/) public routerMap;

    /**
     * @dev Registered swap router types
     */
    uint256[] public routerTypeList;

    /**
     * @dev Registered swap router type indices
     */
    mapping(uint256 /*routerType*/ => DataStructures.OptionalValue /*routerTypeIndex*/)
        public routerTypeIndexMap;

    /**
     * @dev Registered swap router transfer addresses by router type
     */
    mapping(uint256 /*routerType*/ => address /*routerTransferAddress*/) public routerTransferMap;

    /**
     * @dev Registered vault addresses by type
     */
    mapping(uint256 /*vaultType*/ => address /*vaultAddress*/) public vaultMap;

    /**
     * @dev Registered vault types
     */
    uint256[] public vaultTypeList;

    /**
     * @dev Registered vault-type indices
     */
    mapping(uint256 /*vaultType*/ => DataStructures.OptionalValue /*vaultTypeIndex*/)
        public vaultTypeIndexMap;

    /**
     * @dev Registered non-default decimal values by vault type
     */
    mapping(uint256 /*vaultType*/ => mapping(uint256 /*chainId*/ => DataStructures.OptionalValue /*vaultDecimals*/))
        public vaultDecimalsTable;

    /**
     * @dev Chain IDs of registered vault decimal values
     */
    uint256[] public vaultDecimalsChainIdList;

    /**
     * @dev Chain ID indices of registered vault decimal values
     */
    mapping(uint256 /*chainId*/ => DataStructures.OptionalValue /*chainIdIndex*/)
        public vaultDecimalsChainIdIndexMap;

    /**
     * @dev The system fee value (cross-chain swaps) in milli-percent, e.g., 100 is 0.1%
     */
    uint256 public systemFee;

    /**
     * @dev The system fee value (single-chain swaps) in milli-percent, e.g., 100 is 0.1%
     */
    uint256 public systemFeeLocal;

    /**
     * @dev The address of the cross-chain action fee collector
     */
    address public feeCollector;

    /**
     * @dev The address of the single-chain action fee collector
     */
    address public feeCollectorLocal;

    /**
     * @dev The list of accounts that can perform actions without fees and amount restrictions
     */
    address[] public whitelist;

    /**
     * @dev The whitelist account indices
     */
    mapping(address /*account*/ => DataStructures.OptionalValue /*whitelistIndex*/)
        public whitelistIndexMap;

    /**
     * @dev The minimum cross-chain swap amount in USD, with decimals = 18
     */
    uint256 public swapAmountMin = 0;

    /**
     * @dev The maximum cross-chain swap amount in USD, with decimals = 18. Is type(uint256).max for unlimited amount
     */
    uint256 public swapAmountMax = Constants.INFINITY;

    uint256 private constant VAULT_DECIMALS_CHAIN_ID_WILDCARD = 0;
    uint256 private constant SYSTEM_FEE_LIMIT = 10_000; // Maximum system fee in milli-percent = 10%
    uint256 private constant SYSTEM_FEE_INITIAL = 100; // Initial system fee in milli-percent = 0.1%

    /**
     * @notice Emitted when a registered cross-chain gateway contract address is added or updated
     * @param gatewayType The type of the registered cross-chain gateway
     * @param gatewayAddress The address of the registered cross-chain gateway contract
     */
    event SetGateway(uint256 indexed gatewayType, address indexed gatewayAddress);

    /**
     * @notice Emitted when a registered cross-chain gateway contract address is removed
     * @param gatewayType The type of the removed cross-chain gateway
     */
    event RemoveGateway(uint256 indexed gatewayType);

    /**
     * @notice Emitted when a registered vault contract address is added or updated
     * @param vaultType The type of the registered vault
     * @param vaultAddress The address of the registered vault contract
     */
    event SetVault(uint256 indexed vaultType, address indexed vaultAddress);

    /**
     * @notice Emitted when a registered vault contract address is removed
     * @param vaultType The type of the removed vault
     */
    event RemoveVault(uint256 indexed vaultType);

    /**
     * @notice Emitted when vault decimal values are set
     * @param vaultType The type of the vault
     * @param decimalsData The vault decimal values
     */
    event SetVaultDecimals(uint256 indexed vaultType, DataStructures.KeyToValue[] decimalsData);

    /**
     * @notice Emitted when vault decimal values are unset
     * @param vaultType The type of the vault
     */
    event UnsetVaultDecimals(uint256 indexed vaultType, uint256[] chainIds);

    /**
     * @notice Emitted when a registered swap router contract address is added or updated
     * @param routerType The type of the registered swap router
     * @param routerAddress The address of the registered swap router contract
     */
    event SetRouter(uint256 indexed routerType, address indexed routerAddress);

    /**
     * @notice Emitted when a registered swap router contract address is removed
     * @param routerType The type of the removed swap router
     */
    event RemoveRouter(uint256 indexed routerType);

    /**
     * @notice Emitted when a registered swap router transfer contract address is set
     * @param routerType The type of the swap router
     * @param routerTransfer The address of the swap router transfer contract
     */
    event SetRouterTransfer(uint256 indexed routerType, address indexed routerTransfer);

    /**
     * @notice Emitted when the system fee value (cross-chain swaps) is set
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     */
    event SetSystemFee(uint256 systemFee);

    /**
     * @notice Emitted when the system fee value (single-chain swaps) is set
     * @param systemFeeLocal The system fee value in milli-percent, e.g., 100 is 0.1%
     */
    event SetSystemFeeLocal(uint256 systemFeeLocal);

    /**
     * @notice Emitted when the address of the cross-chain action fee collector is set
     * @param feeCollector The address of the cross-chain action fee collector
     */
    event SetFeeCollector(address indexed feeCollector);

    /**
     * @notice Emitted when the address of the single-chain action fee collector is set
     * @param feeCollector The address of the single-chain action fee collector
     */
    event SetFeeCollectorLocal(address indexed feeCollector);

    /**
     * @notice Emitted when the whitelist is updated
     * @param whitelistAddress The added or removed account address
     * @param value The flag of account inclusion
     */
    event SetWhitelist(address indexed whitelistAddress, bool indexed value);

    /**
     * @notice Emitted when the minimum cross-chain swap amount is set
     * @param value The minimum swap amount in USD, with decimals = 18
     */
    event SetSwapAmountMin(uint256 value);

    /**
     * @notice Emitted when the maximum cross-chain swap amount is set
     * @dev Is type(uint256).max for unlimited amount
     * @param value The maximum swap amount in USD, with decimals = 18
     */
    event SetSwapAmountMax(uint256 value);

    /**
     * @notice Emitted when the specified cross-chain gateway address is duplicate
     */
    error DuplicateGatewayAddressError();

    /**
     * @notice Emitted when the requested cross-chain gateway type is not set
     */
    error GatewayNotSetError();

    /**
     * @notice Emitted when the requested swap router type is not set
     */
    error RouterNotSetError();

    /**
     * @notice Emitted when the specified swap amount maximum is less than the current minimum
     */
    error SwapAmountMaxLessThanMinError();

    /**
     * @notice Emitted when the specified swap amount minimum is greater than the current maximum
     */
    error SwapAmountMinGreaterThanMaxError();

    /**
     * @notice Emitted when the specified system fee percentage value is greater than the allowed maximum
     */
    error SystemFeeValueError();

    /**
     * @notice Emitted when the requested vault type is not set
     */
    error VaultNotSetError();

    /**
     * @notice Deploys the ActionExecutorRegistry contract
     * @param _gateways Initial values of cross-chain gateway types and addresses
     * @param _feeCollector The initial address of the cross-chain action fee collector
     * @param _feeCollectorLocal The initial address of the single-chain action fee collector
     * @param _targetGasReserve The initial gas reserve value for target chain action processing
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        DataStructures.KeyToAddressValue[] memory _gateways,
        address _feeCollector,
        address _feeCollectorLocal,
        uint256 _targetGasReserve,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        for (uint256 index; index < _gateways.length; index++) {
            DataStructures.KeyToAddressValue memory item = _gateways[index];

            _setGateway(item.key, item.value);
        }

        _setSystemFee(SYSTEM_FEE_INITIAL);
        _setSystemFeeLocal(SYSTEM_FEE_INITIAL);

        _setFeeCollector(_feeCollector);
        _setFeeCollectorLocal(_feeCollectorLocal);

        _setTargetGasReserve(_targetGasReserve);

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice Adds or updates a registered cross-chain gateway contract address
     * @param _gatewayType The type of the registered cross-chain gateway
     * @param _gatewayAddress The address of the registered cross-chain gateway contract
     */
    function setGateway(uint256 _gatewayType, address _gatewayAddress) external onlyManager {
        _setGateway(_gatewayType, _gatewayAddress);
    }

    /**
     * @notice Removes a registered cross-chain gateway contract address
     * @param _gatewayType The type of the removed cross-chain gateway
     */
    function removeGateway(uint256 _gatewayType) external onlyManager {
        address gatewayAddress = gatewayMap[_gatewayType];

        if (gatewayAddress == address(0)) {
            revert GatewayNotSetError();
        }

        DataStructures.combinedMapRemove(
            gatewayMap,
            gatewayTypeList,
            gatewayTypeIndexMap,
            _gatewayType
        );

        delete isGatewayAddress[gatewayAddress];

        emit RemoveGateway(_gatewayType);
    }

    /**
     * @notice Adds or updates registered swap router contract addresses
     * @param _routers Types and addresses of swap routers
     */
    function setRouters(DataStructures.KeyToAddressValue[] calldata _routers) external onlyManager {
        for (uint256 index; index < _routers.length; index++) {
            DataStructures.KeyToAddressValue calldata item = _routers[index];

            _setRouter(item.key, item.value);
        }
    }

    /**
     * @notice Removes registered swap router contract addresses
     * @param _routerTypes Types of swap routers
     */
    function removeRouters(uint256[] calldata _routerTypes) external onlyManager {
        for (uint256 index; index < _routerTypes.length; index++) {
            uint256 routerType = _routerTypes[index];

            _removeRouter(routerType);
        }
    }

    /**
     * @notice Adds or updates a registered swap router transfer contract address
     * @dev Zero address can be used to remove a router transfer contract
     * @param _routerType The type of the swap router
     * @param _routerTransfer The address of the swap router transfer contract
     */
    function setRouterTransfer(uint256 _routerType, address _routerTransfer) external onlyManager {
        if (routerMap[_routerType] == address(0)) {
            revert RouterNotSetError();
        }

        AddressHelper.requireContractOrZeroAddress(_routerTransfer);

        routerTransferMap[_routerType] = _routerTransfer;

        emit SetRouterTransfer(_routerType, _routerTransfer);
    }

    /**
     * @notice Adds or updates a registered vault contract address
     * @param _vaultType The type of the registered vault
     * @param _vaultAddress The address of the registered vault contract
     */
    function setVault(uint256 _vaultType, address _vaultAddress) external onlyManager {
        AddressHelper.requireContract(_vaultAddress);

        DataStructures.combinedMapSet(
            vaultMap,
            vaultTypeList,
            vaultTypeIndexMap,
            _vaultType,
            _vaultAddress,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );

        emit SetVault(_vaultType, _vaultAddress);
    }

    /**
     * @notice Removes a registered vault contract address
     * @param _vaultType The type of the registered vault
     */
    function removeVault(uint256 _vaultType) external onlyManager {
        DataStructures.combinedMapRemove(vaultMap, vaultTypeList, vaultTypeIndexMap, _vaultType);

        // - - - Vault decimals table cleanup - - -

        delete vaultDecimalsTable[_vaultType][VAULT_DECIMALS_CHAIN_ID_WILDCARD];

        uint256 chainIdListLength = vaultDecimalsChainIdList.length;

        for (uint256 index; index < chainIdListLength; index++) {
            uint256 chainId = vaultDecimalsChainIdList[index];

            delete vaultDecimalsTable[_vaultType][chainId];
        }

        // - - -

        emit RemoveVault(_vaultType);
    }

    /**
     * @notice Sets vault decimal values
     * @param _vaultType The type of the vault
     * @param _decimalsData The vault decimal values
     */
    function setVaultDecimals(
        uint256 _vaultType,
        DataStructures.KeyToValue[] calldata _decimalsData
    ) external onlyManager {
        if (vaultMap[_vaultType] == address(0)) {
            revert VaultNotSetError();
        }

        for (uint256 index; index < _decimalsData.length; index++) {
            DataStructures.KeyToValue calldata decimalsDataItem = _decimalsData[index];

            uint256 chainId = decimalsDataItem.key;

            if (chainId != VAULT_DECIMALS_CHAIN_ID_WILDCARD) {
                DataStructures.uniqueListAdd(
                    vaultDecimalsChainIdList,
                    vaultDecimalsChainIdIndexMap,
                    chainId,
                    Constants.LIST_SIZE_LIMIT_DEFAULT
                );
            }

            vaultDecimalsTable[_vaultType][chainId] = DataStructures.OptionalValue(
                true,
                decimalsDataItem.value
            );
        }

        emit SetVaultDecimals(_vaultType, _decimalsData);
    }

    /**
     * @notice Unsets vault decimal values
     * @param _vaultType The type of the vault
     * @param _chainIds Chain IDs of registered vault decimal values
     */
    function unsetVaultDecimals(
        uint256 _vaultType,
        uint256[] calldata _chainIds
    ) external onlyManager {
        if (vaultMap[_vaultType] == address(0)) {
            revert VaultNotSetError();
        }

        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];
            delete vaultDecimalsTable[_vaultType][chainId];
        }

        emit UnsetVaultDecimals(_vaultType, _chainIds);
    }

    /**
     * @notice Sets the system fee value (cross-chain swaps)
     * @param _systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     */
    function setSystemFee(uint256 _systemFee) external onlyManager {
        _setSystemFee(_systemFee);
    }

    /**
     * @notice Sets the system fee value (single-chain swaps)
     * @param _systemFeeLocal The system fee value in milli-percent, e.g., 100 is 0.1%
     */
    function setSystemFeeLocal(uint256 _systemFeeLocal) external onlyManager {
        _setSystemFeeLocal(_systemFeeLocal);
    }

    /**
     * @notice Sets the address of the cross-chain action fee collector
     * @param _feeCollector The address of the cross-chain action fee collector
     */
    function setFeeCollector(address _feeCollector) external onlyManager {
        _setFeeCollector(_feeCollector);
    }

    /**
     * @notice Sets the address of the single-chain action fee collector
     * @param _feeCollector The address of the single-chain action fee collector
     */
    function setFeeCollectorLocal(address _feeCollector) external onlyManager {
        _setFeeCollectorLocal(_feeCollector);
    }

    /**
     * @notice Updates the whitelist
     * @param _whitelistAddress The added or removed account address
     * @param _value The flag of account inclusion
     */
    function setWhitelist(address _whitelistAddress, bool _value) external onlyManager {
        DataStructures.uniqueAddressListUpdate(
            whitelist,
            whitelistIndexMap,
            _whitelistAddress,
            _value,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );

        emit SetWhitelist(_whitelistAddress, _value);
    }

    /**
     * @notice Sets the minimum cross-chain swap amount
     * @param _value The minimum swap amount in USD, with decimals = 18
     */
    function setSwapAmountMin(uint256 _value) external onlyManager {
        if (_value > swapAmountMax) {
            revert SwapAmountMinGreaterThanMaxError();
        }

        swapAmountMin = _value;

        emit SetSwapAmountMin(_value);
    }

    /**
     * @notice Sets the maximum cross-chain swap amount
     * @dev Use type(uint256).max value for unlimited amount
     * @param _value The maximum swap amount in USD, with decimals = 18
     */
    function setSwapAmountMax(uint256 _value) external onlyManager {
        if (_value < swapAmountMin) {
            revert SwapAmountMaxLessThanMinError();
        }

        swapAmountMax = _value;

        emit SetSwapAmountMax(_value);
    }

    /**
     * @notice Settings for a single-chain swap
     * @param _caller The user's account address
     * @param _routerType The type of the swap router
     * @return Settings for a single-chain swap
     */
    function localSettings(
        address _caller,
        uint256 _routerType
    ) external view returns (LocalSettings memory) {
        (address router, address routerTransfer) = _routerAddresses(_routerType);

        return
            LocalSettings({
                router: router,
                routerTransfer: routerTransfer,
                systemFeeLocal: systemFeeLocal,
                feeCollectorLocal: feeCollectorLocal,
                isWhitelist: isWhitelist(_caller)
            });
    }

    /**
     * @notice Getter of source chain settings for a cross-chain swap
     * @param _caller The user's account address
     * @param _targetChainId The target chain ID
     * @param _gatewayType The type of the cross-chain gateway
     * @param _routerType The type of the swap router
     * @param _vaultType The type of the vault
     * @return Source chain settings for a cross-chain swap
     */
    function sourceSettings(
        address _caller,
        uint256 _targetChainId,
        uint256 _gatewayType,
        uint256 _routerType,
        uint256 _vaultType
    ) external view returns (SourceSettings memory) {
        (address router, address routerTransfer) = _routerAddresses(_routerType);

        return
            SourceSettings({
                gateway: gatewayMap[_gatewayType],
                router: router,
                routerTransfer: routerTransfer,
                vault: vaultMap[_vaultType],
                sourceVaultDecimals: vaultDecimals(_vaultType, block.chainid),
                targetVaultDecimals: vaultDecimals(_vaultType, _targetChainId),
                systemFee: systemFee,
                feeCollector: feeCollector,
                isWhitelist: isWhitelist(_caller),
                swapAmountMin: swapAmountMin,
                swapAmountMax: swapAmountMax
            });
    }

    /**
     * @notice Getter of target chain settings for a cross-chain swap
     * @param _vaultType The type of the vault
     * @param _routerType The type of the swap router
     * @return Target chain settings for a cross-chain swap
     */
    function targetSettings(
        uint256 _vaultType,
        uint256 _routerType
    ) external view returns (TargetSettings memory) {
        (address router, address routerTransfer) = _routerAddresses(_routerType);

        return
            TargetSettings({
                router: router,
                routerTransfer: routerTransfer,
                vault: vaultMap[_vaultType],
                gasReserve: targetGasReserve
            });
    }

    /**
     * @notice Getter of variable balance repayment settings
     * @param _vaultType The type of the vault
     * @return Variable balance repayment settings
     */
    function variableBalanceRepaymentSettings(
        uint256 _vaultType
    ) external view returns (VariableBalanceRepaymentSettings memory) {
        return VariableBalanceRepaymentSettings({ vault: vaultMap[_vaultType] });
    }

    /**
     * @notice Getter of cross-chain message fee estimation settings
     * @param _gatewayType The type of the cross-chain gateway
     * @return Cross-chain message fee estimation settings
     */
    function messageFeeEstimateSettings(
        uint256 _gatewayType
    ) external view returns (MessageFeeEstimateSettings memory) {
        return MessageFeeEstimateSettings({ gateway: gatewayMap[_gatewayType] });
    }

    /**
     * @notice Getter of swap result calculation settings for a single-chain swap
     * @param _caller The user's account address
     * @return Swap result calculation settings for a single-chain swap
     */
    function localAmountCalculationSettings(
        address _caller
    ) external view returns (LocalAmountCalculationSettings memory) {
        return
            LocalAmountCalculationSettings({
                systemFeeLocal: systemFeeLocal,
                isWhitelist: isWhitelist(_caller)
            });
    }

    /**
     * @notice Getter of swap result calculation settings for a cross-chain swap
     * @param _caller The user's account address
     * @param _vaultType The type of the vault
     * @param _fromChainId The ID of the swap source chain
     * @param _toChainId The ID of the swap target chain
     * @return Swap result calculation settings for a cross-chain swap
     */
    function vaultAmountCalculationSettings(
        address _caller,
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId
    ) external view returns (VaultAmountCalculationSettings memory) {
        return
            VaultAmountCalculationSettings({
                fromDecimals: vaultDecimals(_vaultType, _fromChainId),
                toDecimals: vaultDecimals(_vaultType, _toChainId),
                systemFee: systemFee,
                isWhitelist: isWhitelist(_caller)
            });
    }

    /**
     * @notice Getter of amount limits in USD for cross-chain swaps
     * @param _vaultType The type of the vault
     * @return min Minimum cross-chain swap amount in USD, with decimals = 18
     * @return max Maximum cross-chain swap amount in USD, with decimals = 18
     */
    function swapAmountLimits(uint256 _vaultType) external view returns (uint256 min, uint256 max) {
        if (swapAmountMin == 0 && swapAmountMax == Constants.INFINITY) {
            min = 0;
            max = Constants.INFINITY;
        } else {
            uint256 toDecimals = vaultDecimals(_vaultType, block.chainid);

            min = (swapAmountMin == 0)
                ? 0
                : DecimalsHelper.convertDecimals(
                    Constants.DECIMALS_DEFAULT,
                    toDecimals,
                    swapAmountMin
                );

            max = (swapAmountMax == Constants.INFINITY)
                ? Constants.INFINITY
                : DecimalsHelper.convertDecimals(
                    Constants.DECIMALS_DEFAULT,
                    toDecimals,
                    swapAmountMax
                );
        }
    }

    /**
     * @notice Getter of registered cross-chain gateway type count
     * @return Registered cross-chain gateway type count
     */
    function gatewayTypeCount() external view returns (uint256) {
        return gatewayTypeList.length;
    }

    /**
     * @notice Getter of the complete list of registered cross-chain gateway types
     * @return The complete list of registered cross-chain gateway types
     */
    function fullGatewayTypeList() external view returns (uint256[] memory) {
        return gatewayTypeList;
    }

    /**
     * @notice Getter of registered swap router type count
     * @return Registered swap router type count
     */
    function routerTypeCount() external view returns (uint256) {
        return routerTypeList.length;
    }

    /**
     * @notice Getter of the complete list of registered swap router types
     * @return The complete list of registered swap router types
     */
    function fullRouterTypeList() external view returns (uint256[] memory) {
        return routerTypeList;
    }

    /**
     * @notice Getter of registered vault type count
     * @return Registered vault type count
     */
    function vaultTypeCount() external view returns (uint256) {
        return vaultTypeList.length;
    }

    /**
     * @notice Getter of the complete list of registered vault types
     * @return The complete list of registered vault types
     */
    function fullVaultTypeList() external view returns (uint256[] memory) {
        return vaultTypeList;
    }

    /**
     * @notice Getter of registered vault decimals chain ID count
     * @return Registered vault decimals chain ID count
     */
    function vaultDecimalsChainIdCount() external view returns (uint256) {
        return vaultDecimalsChainIdList.length;
    }

    /**
     * @notice Getter of the complete list of registered vault decimals chain IDs
     * @return The complete list of registered vault decimals chain IDs
     */
    function fullVaultDecimalsChainIdList() external view returns (uint256[] memory) {
        return vaultDecimalsChainIdList;
    }

    /**
     * @notice Getter of registered whitelist entry count
     * @return Registered whitelist entry count
     */
    function whitelistCount() external view returns (uint256) {
        return whitelist.length;
    }

    /**
     * @notice Getter of the full whitelist content
     * @return Full whitelist content
     */
    function fullWhitelist() external view returns (address[] memory) {
        return whitelist;
    }

    /**
     * @notice Getter of a whitelist flag
     * @param _account The account address
     * @return The whitelist flag
     */
    function isWhitelist(address _account) public view returns (bool) {
        return whitelistIndexMap[_account].isSet;
    }

    /**
     * @notice Getter of vault decimals value
     * @param _vaultType The type of the vault
     * @param _chainId The vault chain ID
     * @return Vault decimals value
     */
    function vaultDecimals(uint256 _vaultType, uint256 _chainId) public view returns (uint256) {
        DataStructures.OptionalValue storage optionalValue = vaultDecimalsTable[_vaultType][
            _chainId
        ];

        if (optionalValue.isSet) {
            return optionalValue.value;
        }

        DataStructures.OptionalValue storage wildcardOptionalValue = vaultDecimalsTable[_vaultType][
            VAULT_DECIMALS_CHAIN_ID_WILDCARD
        ];

        if (wildcardOptionalValue.isSet) {
            return wildcardOptionalValue.value;
        }

        return Constants.DECIMALS_DEFAULT;
    }

    function _setGateway(uint256 _gatewayType, address _gatewayAddress) private {
        AddressHelper.requireContract(_gatewayAddress);

        if (isGatewayAddress[_gatewayAddress] && gatewayMap[_gatewayType] != _gatewayAddress) {
            revert DuplicateGatewayAddressError();
        }

        DataStructures.combinedMapSet(
            gatewayMap,
            gatewayTypeList,
            gatewayTypeIndexMap,
            _gatewayType,
            _gatewayAddress,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );

        isGatewayAddress[_gatewayAddress] = true;

        emit SetGateway(_gatewayType, _gatewayAddress);
    }

    function _setRouter(uint256 _routerType, address _routerAddress) private {
        AddressHelper.requireContract(_routerAddress);

        DataStructures.combinedMapSet(
            routerMap,
            routerTypeList,
            routerTypeIndexMap,
            _routerType,
            _routerAddress,
            Constants.LIST_SIZE_LIMIT_ROUTERS
        );

        emit SetRouter(_routerType, _routerAddress);
    }

    function _removeRouter(uint256 _routerType) private {
        DataStructures.combinedMapRemove(
            routerMap,
            routerTypeList,
            routerTypeIndexMap,
            _routerType
        );

        delete routerTransferMap[_routerType];

        emit RemoveRouter(_routerType);
    }

    function _setSystemFee(uint256 _systemFee) private {
        if (_systemFee > SYSTEM_FEE_LIMIT) {
            revert SystemFeeValueError();
        }

        systemFee = _systemFee;

        emit SetSystemFee(_systemFee);
    }

    function _setSystemFeeLocal(uint256 _systemFeeLocal) private {
        if (_systemFeeLocal > SYSTEM_FEE_LIMIT) {
            revert SystemFeeValueError();
        }

        systemFeeLocal = _systemFeeLocal;

        emit SetSystemFeeLocal(_systemFeeLocal);
    }

    function _setFeeCollector(address _feeCollector) private {
        feeCollector = _feeCollector;

        emit SetFeeCollector(_feeCollector);
    }

    function _setFeeCollectorLocal(address _feeCollector) private {
        feeCollectorLocal = _feeCollector;

        emit SetFeeCollectorLocal(_feeCollector);
    }

    function _routerAddresses(
        uint256 _routerType
    ) private view returns (address router, address routerTransfer) {
        router = routerMap[_routerType];
        routerTransfer = routerTransferMap[_routerType];

        if (routerTransfer == address(0)) {
            routerTransfer = router;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ITokenBalance } from './interfaces/ITokenBalance.sol';
import { ManagerRole } from './roles/ManagerRole.sol';
import './helpers/TransferHelper.sol' as TransferHelper;
import './Constants.sol' as Constants;

/**
 * @title BalanceManagement
 * @notice Base contract for the withdrawal of tokens, except for reserved ones
 */
abstract contract BalanceManagement is ManagerRole {
    /**
     * @notice Emitted when the specified token is reserved
     */
    error ReservedTokenError();

    /**
     * @notice Performs the withdrawal of tokens, except for reserved ones
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @param _tokenAmount The amount of the token
     */
    function cleanup(address _tokenAddress, uint256 _tokenAmount) external onlyManager {
        if (isReservedToken(_tokenAddress)) {
            revert ReservedTokenError();
        }

        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            TransferHelper.safeTransferNative(msg.sender, _tokenAmount);
        } else {
            TransferHelper.safeTransfer(_tokenAddress, msg.sender, _tokenAmount);
        }
    }

    /**
     * @notice Getter of the token balance of the current contract
     * @dev Use the "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE" address for the native token
     * @param _tokenAddress The address of the token
     * @return The token balance of the current contract
     */
    function tokenBalance(address _tokenAddress) public view returns (uint256) {
        if (_tokenAddress == Constants.NATIVE_TOKEN_ADDRESS) {
            return address(this).balance;
        } else {
            return ITokenBalance(_tokenAddress).balanceOf(address(this));
        }
    }

    /**
     * @notice Getter of the reserved token flag
     * @dev Override to add reserved token addresses
     * @param _tokenAddress The address of the token
     * @return The reserved token flag
     */
    function isReservedToken(address _tokenAddress) public view virtual returns (bool) {
        // The function returns false by default.
        // The explicit return statement is omitted to avoid the unused parameter warning.
        // See https://github.com/ethereum/solidity/issues/5295
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ManagerRole } from './roles/ManagerRole.sol';
import './helpers/AddressHelper.sol' as AddressHelper;
import './Constants.sol' as Constants;
import './DataStructures.sol' as DataStructures;

/**
 * @title CallerGuard
 * @notice Base contract to control access from other contracts
 */
abstract contract CallerGuard is ManagerRole {
    /**
     * @dev Caller guard mode enumeration
     */
    enum CallerGuardMode {
        ContractForbidden,
        ContractList,
        ContractAllowed
    }

    /**
     * @dev Caller guard mode value
     */
    CallerGuardMode public callerGuardMode = CallerGuardMode.ContractForbidden;

    /**
     * @dev Registered contract list for "ContractList" mode
     */
    address[] public listedCallerGuardContractList;

    /**
     * @dev Registered contract list indices for "ContractList" mode
     */
    mapping(address /*account*/ => DataStructures.OptionalValue /*index*/)
        public listedCallerGuardContractIndexMap;

    /**
     * @notice Emitted when the caller guard mode is set
     * @param callerGuardMode The caller guard mode
     */
    event SetCallerGuardMode(CallerGuardMode indexed callerGuardMode);

    /**
     * @notice Emitted when a registered contract for "ContractList" mode is added or removed
     * @param contractAddress The contract address
     * @param isListed The registered contract list inclusion flag
     */
    event SetListedCallerGuardContract(address indexed contractAddress, bool indexed isListed);

    /**
     * @notice Emitted when the caller is not allowed to perform the intended action
     */
    error CallerGuardError(address caller);

    /**
     * @dev Modifier to check if the caller is allowed to perform the intended action
     */
    modifier checkCaller() {
        if (msg.sender != tx.origin) {
            bool condition = (callerGuardMode == CallerGuardMode.ContractAllowed ||
                (callerGuardMode == CallerGuardMode.ContractList &&
                    isListedCallerGuardContract(msg.sender)));

            if (!condition) {
                revert CallerGuardError(msg.sender);
            }
        }

        _;
    }

    /**
     * @notice Sets the caller guard mode
     * @param _callerGuardMode The caller guard mode
     */
    function setCallerGuardMode(CallerGuardMode _callerGuardMode) external onlyManager {
        callerGuardMode = _callerGuardMode;

        emit SetCallerGuardMode(_callerGuardMode);
    }

    /**
     * @notice Updates the list of registered contracts for the "ContractList" mode
     * @param _items The addresses and flags for the contracts
     */
    function setListedCallerGuardContracts(
        DataStructures.AccountToFlag[] calldata _items
    ) external onlyManager {
        for (uint256 index; index < _items.length; index++) {
            DataStructures.AccountToFlag calldata item = _items[index];

            if (item.flag) {
                AddressHelper.requireContract(item.account);
            }

            DataStructures.uniqueAddressListUpdate(
                listedCallerGuardContractList,
                listedCallerGuardContractIndexMap,
                item.account,
                item.flag,
                Constants.LIST_SIZE_LIMIT_DEFAULT
            );

            emit SetListedCallerGuardContract(item.account, item.flag);
        }
    }

    /**
     * @notice Getter of the registered contract count
     * @return The registered contract count
     */
    function listedCallerGuardContractCount() external view returns (uint256) {
        return listedCallerGuardContractList.length;
    }

    /**
     * @notice Getter of the complete list of registered contracts
     * @return The complete list of registered contracts
     */
    function fullListedCallerGuardContractList() external view returns (address[] memory) {
        return listedCallerGuardContractList;
    }

    /**
     * @notice Getter of a listed contract flag
     * @param _account The contract address
     * @return The listed contract flag
     */
    function isListedCallerGuardContract(address _account) public view returns (bool) {
        return listedCallerGuardContractIndexMap[_account].isSet;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @dev The default token decimals value
 */
uint256 constant DECIMALS_DEFAULT = 18;

/**
 * @dev The maximum uint256 value for swap amount limit settings
 */
uint256 constant INFINITY = type(uint256).max;

/**
 * @dev The default limit of account list size
 */
uint256 constant LIST_SIZE_LIMIT_DEFAULT = 100;

/**
 * @dev The limit of swap router list size
 */
uint256 constant LIST_SIZE_LIMIT_ROUTERS = 200;

/**
 * @dev The factor for percentage settings. Example: 100 is 0.1%
 */
uint256 constant MILLIPERCENT_FACTOR = 100_000;

/**
 * @dev The de facto standard address to denote the native token
 */
address constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { IActionDataStructures } from '../../interfaces/IActionDataStructures.sol';
import { IAnyCallV7Endpoint } from '../anycall-v7/interfaces/IAnyCallV7Endpoint.sol';
import { IAnyCallV7Executor } from '../anycall-v7/interfaces/IAnyCallV7Executor.sol';
import { IMessageTransmitter } from './interfaces/IMessageTransmitter.sol';
import { ITokenBalance } from '../../interfaces/ITokenBalance.sol';
import { ITokenMessenger } from './interfaces/ITokenMessenger.sol';
import { IVault } from '../../interfaces/IVault.sol';
import { ActionExecutor } from '../../ActionExecutor.sol';
import { ActionExecutorRegistry } from '../../ActionExecutorRegistry.sol';
import { AssetSpenderRole } from '../../roles/AssetSpenderRole.sol';
import { GatewayBase } from '../GatewayBase.sol';
import { SystemVersionId } from '../../SystemVersionId.sol';
import '../../helpers/AddressHelper.sol' as AddressHelper;
import '../../helpers/DecimalsHelper.sol' as DecimalsHelper;
import '../../helpers/GasReserveHelper.sol' as GasReserveHelper;
import '../../helpers/RefundHelper.sol' as RefundHelper;
import '../../helpers/TransferHelper.sol' as TransferHelper;
import '../../DataStructures.sol' as DataStructures;

/**
 * @title AnyCallCctpGateway
 * @notice The contract implementing the cross-chain messaging logic specific to AnyCall CCTP
 */
contract AnyCallCctpGateway is
    SystemVersionId,
    GatewayBase,
    AssetSpenderRole,
    IActionDataStructures,
    IVault
{
    /**
     * @dev AnyCall endpoint contract reference
     */
    IAnyCallV7Endpoint public endpoint;

    /**
     * @dev AnyCall executor contract reference
     */
    IAnyCallV7Executor public executor;

    /**
     * @dev cctpTokenMessenger The CCTP token messenger address
     */
    ITokenMessenger public cctpTokenMessenger;

    /**
     * @dev cctpMessageTransmitter The CCTP message transmitter address
     */
    IMessageTransmitter public cctpMessageTransmitter;

    /**
     * @dev asset The USDC token address
     */
    address public asset;

    /**
     * @dev CCTP destination domains
     */
    mapping(uint256 /*chainId*/ => DataStructures.OptionalValue /*destinationDomain*/)
        public cctpDestinationDomainMap;

    /**
     * @dev Custom asset decimals by chain ids
     */
    mapping(uint256 /*chainId*/ => DataStructures.OptionalValue /*assetDecimals*/)
        public chainAssetDecimalsMap;

    /**
     * @dev The state of variable token and balance actions
     */
    bool public variableRepaymentEnabled;

    uint256 private constant PAY_FEE_ON_SOURCE_CHAIN_NO_FALLBACK = 0;

    /**
     * @notice Emitted when the cross-chain endpoint contract reference is set
     * @param endpointAddress The address of the cross-chain endpoint contract
     * @param executorAddress The address of the cross-chain executor contract
     */
    event SetEndpoint(address indexed endpointAddress, address indexed executorAddress);

    /**
     * @notice Emitted when the state of variable token and balance actions is updated
     * @param variableRepaymentEnabled The state of variable token and balance actions
     */
    event SetVariableRepaymentEnabled(bool indexed variableRepaymentEnabled);

    /**
     * @notice Emitted when the call to the CCTP receiveMessage fails
     * @param sourceChainId The ID of the message source chain
     */
    event TargetCctpMessageFailure(uint256 indexed sourceChainId);

    /**
     * @notice Emitted when a variable token or balance action is not allowed
     */
    error VariableRepaymentNotEnabledError();

    /**
     * @notice Emitted when the caller is not the AnyCall executor contract
     */
    error OnlyExecutorError();

    /**
     * @notice Emitted when a variable token action is attempted while the token address is not set
     */
    error VariableTokenNotSetError();

    /**
     * @notice Emitted when the destination domain for the specified chain is not set
     */
    error DestinationDomainNotSetError();

    /**
     * @notice Emitted when the vault type from the message does not match the current vault
     */
    error VaultTypeMismatchError();

    /**
     * @dev Modifier to check if the caller is the AnyCall executor contract
     */
    modifier onlyExecutor() {
        if (msg.sender != address(executor)) {
            revert OnlyExecutorError();
        }

        _;
    }

    /**
     * @notice Deploys the AnyCallV7Gateway contract
     * @param _endpointAddress The cross-chain endpoint address
     * @param _cctpTokenMessenger The CCTP token messenger address
     * @param _cctpMessageTransmitter The CCTP message transmitter address
     * @param _asset The USDC token address
     * @param _targetGasReserve The initial gas reserve value for target chain action processing
     * @param _owner The address of the initial owner of the contract
     * @param _managers The addresses of initial managers of the contract
     * @param _addOwnerToManagers The flag to optionally add the owner to the list of managers
     */
    constructor(
        address _endpointAddress,
        ITokenMessenger _cctpTokenMessenger,
        IMessageTransmitter _cctpMessageTransmitter,
        address _asset,
        bool _variableRepaymentEnabled,
        uint256 _targetGasReserve,
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) {
        _setEndpoint(_endpointAddress);

        cctpTokenMessenger = _cctpTokenMessenger;
        cctpMessageTransmitter = _cctpMessageTransmitter;
        asset = _asset;

        _setVariableRepaymentEnabled(_variableRepaymentEnabled);

        _setTargetGasReserve(_targetGasReserve);

        _initRoles(_owner, _managers, _addOwnerToManagers);
    }

    /**
     * @notice The standard "receive" function
     * @dev Is payable to allow receiving native token funds from the cross-chain endpoint
     */
    receive() external payable {}

    /**
     * @notice Sets the cross-chain endpoint contract reference
     * @param _endpointAddress The address of the cross-chain endpoint contract
     */
    function setEndpoint(address _endpointAddress) external onlyManager {
        _setEndpoint(_endpointAddress);
    }

    /**
     * @notice Updates the Asset Spender role status for the account
     * @param _account The account address
     * @param _value The Asset Spender role status flag
     */
    function setAssetSpender(address _account, bool _value) external onlyManager {
        _setAssetSpender(_account, _value);
    }

    /**
     * @notice Sets a destination domain
     * @param _chainId The id of the chain
     * @param _value The value of the destination domain
     */
    function setDestinationDomain(uint256 _chainId, uint256 _value) external onlyManager {
        cctpDestinationDomainMap[_chainId] = DataStructures.OptionalValue({
            isSet: true,
            value: _value
        });
    }

    /**
     * @notice Unsets a destination domain
     * @param _chainId The id of the chain
     */
    function unsetDestinationDomain(uint256 _chainId) external onlyManager {
        delete cctpDestinationDomainMap[_chainId];
    }

    /**
     * @notice Sets a chain asset decimals value
     * @param _chainId The id of the chain
     * @param _value The value of the chain asset decimals
     */
    function setChainAssetDecimals(uint256 _chainId, uint256 _value) external onlyManager {
        chainAssetDecimalsMap[_chainId] = DataStructures.OptionalValue({
            isSet: true,
            value: _value
        });
    }

    /**
     * @notice Unsets a chain asset decimals value
     * @param _chainId The id of the chain
     */
    function unsetChainAssetDecimals(uint256 _chainId) external onlyManager {
        delete chainAssetDecimalsMap[_chainId];
    }

    /**
     * @notice Send a cross-chain message
     * @param _targetChainId The message target chain ID
     * @param _message The message content
     */
    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata /*_settings*/
    ) external payable onlyClient whenNotPaused {
        address peerAddress = _checkPeerAddress(_targetChainId);

        DataStructures.OptionalValue storage destinationDomain = cctpDestinationDomainMap[
            _targetChainId
        ];

        if (!destinationDomain.isSet) {
            revert DestinationDomainNotSetError();
        }

        TargetMessage memory targetMessage = abi.decode(_message, (TargetMessage));

        _checkVaultType(targetMessage);

        uint256 amount = _sourceAmount(targetMessage, _targetChainId);

        TransferHelper.safeApprove(asset, address(cctpTokenMessenger), amount);

        // CCTP interaction on the source chain
        cctpTokenMessenger.depositForBurnWithCaller(
            amount,
            uint32(destinationDomain.value),
            _toBytes32(peerAddress), // _mintRecipient
            asset,
            _toBytes32(peerAddress) // _clientPeer
        );

        TransferHelper.safeApprove(asset, address(cctpTokenMessenger), 0);

        uint256 initialBalance = address(this).balance - msg.value;

        endpoint.anyCall{ value: msg.value }(
            peerAddress,
            _message,
            _targetChainId,
            PAY_FEE_ON_SOURCE_CHAIN_NO_FALLBACK,
            'usdc' // CCTP-specific value
        );

        // - - - Extra balance transfer - - -

        RefundHelper.refundExtraBalance(address(this), initialBalance, payable(client));

        // - - -
    }

    /**
     * @notice Receives cross-chain messages
     * @dev The function is called by the cross-chain executor
     * @param _data The cross-chain message data
     */
    function anyExecute(
        bytes calldata _data
    ) external nonReentrant onlyExecutor returns (bool success, bytes memory result) {
        if (paused()) {
            emit TargetPausedFailure();

            return (true, '');
        }

        if (address(client) == address(0)) {
            emit TargetClientNotSetFailure();

            return (true, '');
        }

        (address from, uint256 fromChainID, ) = executor.context();

        bool condition = fromChainID != 0 && from != address(0) && from == peerMap[fromChainID];

        if (!condition) {
            emit TargetFromAddressFailure(fromChainID, from);

            return (true, '');
        }

        (bytes memory payloadData, , bytes memory cctpMessage, bytes memory cctpAttestation) = abi
            .decode(_data, (bytes, string, bytes, bytes));

        // CCTP interaction on the target chain
        try cctpMessageTransmitter.receiveMessage(cctpMessage, cctpAttestation) {} catch {
            emit TargetCctpMessageFailure(fromChainID);

            return (true, '');
        }

        (bool hasGasReserve, uint256 gasAllowed) = GasReserveHelper.checkGasReserve(
            targetGasReserve
        );

        if (!hasGasReserve) {
            emit TargetGasReserveFailure(fromChainID);

            return (true, '');
        }

        try client.handleExecutionPayload{ gas: gasAllowed }(fromChainID, payloadData) {} catch {
            emit TargetExecutionFailure();
        }

        return (true, '');
    }

    /**
     * @notice Receives the asset tokens from CCTP and transfers them to the specified account
     * @param _cctpMessage The CCTP message
     * @param _cctpAttestation The CCTP attestation
     * @param _to The address of the asset tokens receiver
     */
    function receiveCctpAsset(
        bytes calldata _cctpMessage,
        bytes calldata _cctpAttestation,
        address _to
    ) external onlyManager {
        uint256 tokenBalanceBefore = ITokenBalance(asset).balanceOf(address(this));

        cctpMessageTransmitter.receiveMessage(_cctpMessage, _cctpAttestation);

        uint256 tokenAmount = ITokenBalance(asset).balanceOf(address(this)) - tokenBalanceBefore;

        if (tokenAmount > 0 && _to != address(this)) {
            TransferHelper.safeTransfer(asset, _to, tokenAmount);
        }
    }

    /**
     * @notice Requests the vault asset tokens
     * @param _amount The amount of the vault asset tokens
     * @param _to The address of the vault asset tokens receiver
     * @param _forVariableBalance True if the request is made for a variable balance repayment, otherwise false
     * @return assetAddress The address of the vault asset token
     */
    function requestAsset(
        uint256 _amount,
        address _to,
        bool _forVariableBalance
    ) external whenNotPaused onlyAssetSpender returns (address assetAddress) {
        if (_forVariableBalance && !variableRepaymentEnabled) {
            revert VariableRepaymentNotEnabledError();
        }

        TransferHelper.safeTransfer(asset, _to, _amount);

        return asset;
    }

    /**
     * @notice Cross-chain message fee estimation
     * @param _targetChainId The ID of the target chain
     * @param _message The message content
     */
    function messageFee(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata /*_settings*/
    ) external view returns (uint256) {
        return endpoint.config().calcSrcFees(address(this), _targetChainId, _message.length);
    }

    /**
     * @notice Checks the status of the variable token and balance actions and the variable token address
     * @return The address of the variable token
     */
    function checkVariableTokenState() external view returns (address) {
        if (!variableRepaymentEnabled) {
            revert VariableRepaymentNotEnabledError();
        }

        revert VariableTokenNotSetError();
    }

    function _setEndpoint(address _endpointAddress) private {
        AddressHelper.requireContract(_endpointAddress);

        endpoint = IAnyCallV7Endpoint(_endpointAddress);
        executor = endpoint.executor();

        emit SetEndpoint(_endpointAddress, address(executor));
    }

    function _setVariableRepaymentEnabled(bool _variableRepaymentEnabled) private {
        variableRepaymentEnabled = _variableRepaymentEnabled;

        emit SetVariableRepaymentEnabled(_variableRepaymentEnabled);
    }

    function _checkVaultType(TargetMessage memory _targetMessage) private view {
        ActionExecutor actionExecutor = ActionExecutor(payable(client));

        ActionExecutorRegistry registry = ActionExecutorRegistry(
            address(actionExecutor.registry())
        );

        address vaultAddress = registry.vaultMap(_targetMessage.vaultType);

        if (vaultAddress != address(this)) {
            revert VaultTypeMismatchError();
        }
    }

    function _sourceAmount(
        TargetMessage memory _targetMessage,
        uint256 _targetChainId
    ) private view returns (uint256) {
        uint256 targetAmount = _targetMessage.targetSwapInfo.fromAmount;

        uint256 targetDecimals = _chainAssetDecimals(_targetChainId);
        uint256 sourceDecimals = _chainAssetDecimals(block.chainid);

        return DecimalsHelper.convertDecimals(targetDecimals, sourceDecimals, targetAmount);
    }

    function _chainAssetDecimals(uint256 _chainId) private view returns (uint256) {
        DataStructures.OptionalValue storage optionalValue = chainAssetDecimalsMap[_chainId];

        if (optionalValue.isSet) {
            return optionalValue.value;
        }

        return 6; // default asset decimals
    }

    function _toBytes32(address _address) private pure returns (bytes32) {
        return bytes32(uint256(uint160(_address)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

interface IMessageTransmitter {
    function receiveMessage(
        bytes calldata _message,
        bytes calldata _attestation
    ) external returns (uint64 _nonce);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

interface ITokenMessenger {
    function depositForBurnWithCaller(
        uint256 _amount,
        uint32 _destinationDomain,
        bytes32 _mintRecipient,
        address _burnToken,
        bytes32 _destinationCaller
    ) external returns (uint64 _nonce);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IAnyCallV7Config
 * @notice AnyCall v7 configuration interface
 */
interface IAnyCallV7Config {
    /**
     * @notice Cross-chain message fee estimation
     * @param _app The address of the application
     * @param _toChainID The ID of the target chain
     * @param _dataLength The length of the message data (in bytes)
     * @return The fee for the message
     */
    function calcSrcFees(
        address _app,
        uint256 _toChainID,
        uint256 _dataLength
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { IAnyCallV7Config } from './IAnyCallV7Config.sol';
import { IAnyCallV7Executor } from './IAnyCallV7Executor.sol';

/**
 * @title IAnyCallV7Endpoint
 * @notice AnyCall v7 endpoint interface
 */
interface IAnyCallV7Endpoint {
    /**
     * @notice Send a cross-chain message
     * @param _to The address of the message receiver on the target chain
     * @param _data The message content
     * @param _toChainID The ID of the target chain
     * @param _flags The parameters of the call
     * @param _extdata Extra data for advanced use cases
     */
    function anyCall(
        address _to,
        bytes calldata _data,
        uint256 _toChainID,
        uint256 _flags,
        bytes calldata _extdata
    ) external payable;

    /**
     * @notice Getter of the cross-chain executor contract reference
     * @return The cross-chain executor contract reference
     */
    function executor() external view returns (IAnyCallV7Executor);

    /**
     * @notice Getter of the cross-chain configuration contract reference
     * @return The cross-chain configuration contract reference
     */
    function config() external view returns (IAnyCallV7Config);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IAnyCallV7Executor
 * @notice AnyCall v7 executor interface
 */
interface IAnyCallV7Executor {
    /**
     * @notice Getter of the cross-chain call context data
     * @return from The address of the message source
     * @return fromChainID The chain ID of the message source
     * @return nonce The unique identifier of the message call
     */
    function context() external view returns (address from, uint256 fromChainID, uint256 nonce);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ReentrancyGuard } from '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import { IGateway } from './interfaces/IGateway.sol';
import { IGatewayClient } from './interfaces/IGatewayClient.sol';
import { BalanceManagement } from '../BalanceManagement.sol';
import { Pausable } from '../Pausable.sol';
import { TargetGasReserve } from './TargetGasReserve.sol';
import { ZeroAddressError } from '../Errors.sol';
import '../helpers/AddressHelper.sol' as AddressHelper;
import '../Constants.sol' as Constants;
import '../DataStructures.sol' as DataStructures;

/**
 * @title GatewayBase
 * @notice Base contract that implements the cross-chain gateway logic
 */
abstract contract GatewayBase is
    Pausable,
    ReentrancyGuard,
    TargetGasReserve,
    BalanceManagement,
    IGateway
{
    /**
     * @dev Gateway client contract reference
     */
    IGatewayClient public client;

    /**
     * @dev Registered peer gateway addresses by the chain ID
     */
    mapping(uint256 /*peerChainId*/ => address /*peerAddress*/) public peerMap;

    /**
     * @dev Registered peer gateway chain IDs
     */
    uint256[] public peerChainIdList;

    /**
     * @dev Registered peer gateway chain ID indices
     */
    mapping(uint256 /*peerChainId*/ => DataStructures.OptionalValue /*peerChainIdIndex*/)
        public peerChainIdIndexMap;

    /**
     * @notice Emitted when the gateway client contract reference is set
     * @param clientAddress The gateway client contract address
     */
    event SetClient(address indexed clientAddress);

    /**
     * @notice Emitted when a registered peer gateway contract address is added or updated
     * @param chainId The chain ID of the registered peer gateway
     * @param peerAddress The address of the registered peer gateway contract
     */
    event SetPeer(uint256 indexed chainId, address indexed peerAddress);

    /**
     * @notice Emitted when a registered peer gateway contract address is removed
     * @param chainId The chain ID of the registered peer gateway
     */
    event RemovePeer(uint256 indexed chainId);

    /**
     * @notice Emitted when the target chain gateway is paused
     */
    event TargetPausedFailure();

    /**
     * @notice Emitted when the target chain gateway client contract is not set
     */
    event TargetClientNotSetFailure();

    /**
     * @notice Emitted when the message source address does not match the registered peer gateway on the target chain
     * @param sourceChainId The ID of the message source chain
     * @param fromAddress The address of the message source
     */
    event TargetFromAddressFailure(uint256 indexed sourceChainId, address indexed fromAddress);

    /**
     * @notice Emitted when the gas reserve on the target chain does not allow further action processing
     * @param sourceChainId The ID of the message source chain
     */
    event TargetGasReserveFailure(uint256 indexed sourceChainId);

    /**
     * @notice Emitted when the gateway client execution on the target chain fails
     */
    event TargetExecutionFailure();

    /**
     * @notice Emitted when the caller is not the gateway client contract
     */
    error OnlyClientError();

    /**
     * @notice Emitted when the peer config address for the current chain does not match the current contract
     */
    error PeerAddressMismatchError();

    /**
     * @notice Emitted when the peer gateway address for the specified chain is not set
     */
    error PeerNotSetError();

    /**
     * @notice Emitted when the chain ID is not set
     */
    error ZeroChainIdError();

    /**
     * @dev Modifier to check if the caller is the gateway client contract
     */
    modifier onlyClient() {
        if (msg.sender != address(client)) {
            revert OnlyClientError();
        }

        _;
    }

    /**
     * @notice Sets the gateway client contract reference
     * @param _clientAddress The gateway client contract address
     */
    function setClient(address payable _clientAddress) external virtual onlyManager {
        AddressHelper.requireContract(_clientAddress);

        client = IGatewayClient(_clientAddress);

        emit SetClient(_clientAddress);
    }

    /**
     * @notice Adds or updates registered peer gateways
     * @param _peers Chain IDs and addresses of peer gateways
     */
    function setPeers(
        DataStructures.KeyToAddressValue[] calldata _peers
    ) external virtual onlyManager {
        for (uint256 index; index < _peers.length; index++) {
            DataStructures.KeyToAddressValue calldata item = _peers[index];

            uint256 chainId = item.key;
            address peerAddress = item.value;

            // Allow the same configuration on multiple chains
            if (chainId == block.chainid) {
                if (peerAddress != address(this)) {
                    revert PeerAddressMismatchError();
                }
            } else {
                _setPeer(chainId, peerAddress);
            }
        }
    }

    /**
     * @notice Removes registered peer gateways
     * @param _chainIds Peer gateway chain IDs
     */
    function removePeers(uint256[] calldata _chainIds) external virtual onlyManager {
        for (uint256 index; index < _chainIds.length; index++) {
            uint256 chainId = _chainIds[index];

            // Allow the same configuration on multiple chains
            if (chainId != block.chainid) {
                _removePeer(chainId);
            }
        }
    }

    /**
     * @notice Getter of the peer gateway count
     * @return The peer gateway count
     */
    function peerCount() external view virtual returns (uint256) {
        return peerChainIdList.length;
    }

    /**
     * @notice Getter of the complete list of the peer gateway chain IDs
     * @return The complete list of the peer gateway chain IDs
     */
    function fullPeerChainIdList() external view virtual returns (uint256[] memory) {
        return peerChainIdList;
    }

    function _setPeer(uint256 _chainId, address _peerAddress) internal virtual {
        if (_chainId == 0) {
            revert ZeroChainIdError();
        }

        if (_peerAddress == address(0)) {
            revert ZeroAddressError();
        }

        DataStructures.combinedMapSet(
            peerMap,
            peerChainIdList,
            peerChainIdIndexMap,
            _chainId,
            _peerAddress,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );

        emit SetPeer(_chainId, _peerAddress);
    }

    function _removePeer(uint256 _chainId) internal virtual {
        if (_chainId == 0) {
            revert ZeroChainIdError();
        }

        DataStructures.combinedMapRemove(peerMap, peerChainIdList, peerChainIdIndexMap, _chainId);

        emit RemovePeer(_chainId);
    }

    function _checkPeerAddress(uint256 _chainId) internal virtual returns (address) {
        address peerAddress = peerMap[_chainId];

        if (peerAddress == address(0)) {
            revert PeerNotSetError();
        }

        return peerAddress;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IGateway
 * @notice Cross-chain gateway interface
 */
interface IGateway {
    /**
     * @notice Send a cross-chain message
     * @param _targetChainId The message target chain ID
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function sendMessage(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external payable;

    /**
     * @notice Cross-chain message fee estimation
     * @param _targetChainId The ID of the target chain
     * @param _message The message content
     * @param _settings The gateway-specific settings
     */
    function messageFee(
        uint256 _targetChainId,
        bytes calldata _message,
        bytes calldata _settings
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IGatewayClient
 * @notice Cross-chain gateway client interface
 */
interface IGatewayClient {
    /**
     * @notice Cross-chain message handler on the target chain
     * @dev The function is called by cross-chain gateways
     * @param _messageSourceChainId The ID of the message source chain
     * @param _payloadData The content of the cross-chain message
     */
    function handleExecutionPayload(
        uint256 _messageSourceChainId,
        bytes calldata _payloadData
    ) external;

    /**
     * @notice The standard "receive" function
     */
    receive() external payable;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ManagerRole } from '../roles/ManagerRole.sol';

/**
 * @title TargetGasReserve
 * @notice Base contract that implements the gas reserve logic for the target chain actions
 */
abstract contract TargetGasReserve is ManagerRole {
    /**
     * @dev The target chain gas reserve value
     */
    uint256 public targetGasReserve;

    /**
     * @notice Emitted when the target chain gas reserve value is set
     * @param gasReserve The target chain gas reserve value
     */
    event SetTargetGasReserve(uint256 gasReserve);

    /**
     * @notice Sets the target chain gas reserve value
     * @param _gasReserve The target chain gas reserve value
     */
    function setTargetGasReserve(uint256 _gasReserve) external onlyManager {
        _setTargetGasReserve(_gasReserve);
    }

    function _setTargetGasReserve(uint256 _gasReserve) internal virtual {
        targetGasReserve = _gasReserve;

        emit SetTargetGasReserve(_gasReserve);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Optional value structure
 * @dev Is used in mappings to allow zero values
 * @param isSet Value presence flag
 * @param value Numeric value
 */
struct OptionalValue {
    bool isSet;
    uint256 value;
}

/**
 * @notice Key-to-value structure
 * @dev Is used as an array parameter item to perform multiple key-value settings
 * @param key Numeric key
 * @param value Numeric value
 */
struct KeyToValue {
    uint256 key;
    uint256 value;
}

/**
 * @notice Key-to-value structure for address values
 * @dev Is used as an array parameter item to perform multiple key-value settings with address values
 * @param key Numeric key
 * @param value Address value
 */
struct KeyToAddressValue {
    uint256 key;
    address value;
}

/**
 * @notice Address-to-flag structure
 * @dev Is used as an array parameter item to perform multiple settings
 * @param account Account address
 * @param flag Flag value
 */
struct AccountToFlag {
    address account;
    bool flag;
}

/**
 * @notice Emitted when a list exceeds the size limit
 */
error ListSizeLimitError();

/**
 * @notice Sets or updates a value in a combined map (a mapping with a key list and key index mapping)
 * @param _map The mapping reference
 * @param _keyList The key list reference
 * @param _keyIndexMap The key list index mapping reference
 * @param _key The numeric key
 * @param _value The address value
 * @param _sizeLimit The map and list size limit
 * @return isNewKey True if the key was just added, otherwise false
 */
function combinedMapSet(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key,
    address _value,
    uint256 _sizeLimit
) returns (bool isNewKey) {
    isNewKey = !_keyIndexMap[_key].isSet;

    if (isNewKey) {
        uniqueListAdd(_keyList, _keyIndexMap, _key, _sizeLimit);
    }

    _map[_key] = _value;
}

/**
 * @notice Removes a value from a combined map (a mapping with a key list and key index mapping)
 * @param _map The mapping reference
 * @param _keyList The key list reference
 * @param _keyIndexMap The key list index mapping reference
 * @param _key The numeric key
 * @return isChanged True if the combined map was changed, otherwise false
 */
function combinedMapRemove(
    mapping(uint256 => address) storage _map,
    uint256[] storage _keyList,
    mapping(uint256 => OptionalValue) storage _keyIndexMap,
    uint256 _key
) returns (bool isChanged) {
    isChanged = _keyIndexMap[_key].isSet;

    if (isChanged) {
        delete _map[_key];
        uniqueListRemove(_keyList, _keyIndexMap, _key);
    }
}

/**
 * @notice Adds a value to a unique value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The numeric value
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueListAdd(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value,
    uint256 _sizeLimit
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        if (_list.length >= _sizeLimit) {
            revert ListSizeLimitError();
        }

        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

/**
 * @notice Removes a value from a unique value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The numeric value
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueListRemove(
    uint256[] storage _list,
    mapping(uint256 => OptionalValue) storage _indexMap,
    uint256 _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            uint256 lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

/**
 * @notice Adds a value to a unique address value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListAdd(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value,
    uint256 _sizeLimit
) returns (bool isChanged) {
    isChanged = !_indexMap[_value].isSet;

    if (isChanged) {
        if (_list.length >= _sizeLimit) {
            revert ListSizeLimitError();
        }

        _indexMap[_value] = OptionalValue(true, _list.length);
        _list.push(_value);
    }
}

/**
 * @notice Removes a value from a unique address value list (a list with value index mapping)
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListRemove(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value
) returns (bool isChanged) {
    OptionalValue storage indexItem = _indexMap[_value];

    isChanged = indexItem.isSet;

    if (isChanged) {
        uint256 itemIndex = indexItem.value;
        uint256 lastIndex = _list.length - 1;

        if (itemIndex != lastIndex) {
            address lastValue = _list[lastIndex];
            _list[itemIndex] = lastValue;
            _indexMap[lastValue].value = itemIndex;
        }

        _list.pop();
        delete _indexMap[_value];
    }
}

/**
 * @notice Adds or removes a value to/from a unique address value list (a list with value index mapping)
 * @dev The list size limit is checked on items adding only
 * @param _list The list reference
 * @param _indexMap The value index mapping reference
 * @param _value The address value
 * @param _flag The value inclusion flag
 * @param _sizeLimit The list size limit
 * @return isChanged True if the list was changed, otherwise false
 */
function uniqueAddressListUpdate(
    address[] storage _list,
    mapping(address => OptionalValue) storage _indexMap,
    address _value,
    bool _flag,
    uint256 _sizeLimit
) returns (bool isChanged) {
    return
        _flag
            ? uniqueAddressListAdd(_list, _indexMap, _value, _sizeLimit)
            : uniqueAddressListRemove(_list, _indexMap, _value);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when an attempt to burn a token fails
 */
error TokenBurnError();

/**
 * @notice Emitted when an attempt to mint a token fails
 */
error TokenMintError();

/**
 * @notice Emitted when a zero address is specified where it is not allowed
 */
error ZeroAddressError();

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when the account is not a contract
 * @param account The account address
 */
error NonContractAddressError(address account);

/**
 * @notice Function to check if the account is a contract
 * @return The account contract status flag
 */
function isContract(address _account) view returns (bool) {
    return _account.code.length > 0;
}

/**
 * @notice Function to require an account to be a contract
 */
function requireContract(address _account) view {
    if (!isContract(_account)) {
        revert NonContractAddressError(_account);
    }
}

/**
 * @notice Function to require an account to be a contract or a zero address
 */
function requireContractOrZeroAddress(address _account) view {
    if (_account != address(0)) {
        requireContract(_account);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Function to perform decimals conversion
 * @param _fromDecimals Source value decimals
 * @param _toDecimals Target value decimals
 * @param _fromAmount Source value
 * @return Target value
 */
function convertDecimals(
    uint256 _fromDecimals,
    uint256 _toDecimals,
    uint256 _fromAmount
) pure returns (uint256) {
    if (_toDecimals == _fromDecimals) {
        return _fromAmount;
    } else if (_toDecimals > _fromDecimals) {
        return _fromAmount * 10 ** (_toDecimals - _fromDecimals);
    } else {
        return _fromAmount / 10 ** (_fromDecimals - _toDecimals);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Function to check if the available gas matches the specified gas reserve value
 * @param _gasReserve Gas reserve value
 * @return hasGasReserve Flag of gas reserve availability
 * @return gasAllowed The remaining gas quantity taking the reserve into account
 */
function checkGasReserve(
    uint256 _gasReserve
) view returns (bool hasGasReserve, uint256 gasAllowed) {
    uint256 gasLeft = gasleft();

    hasGasReserve = gasLeft >= _gasReserve;
    gasAllowed = hasGasReserve ? gasLeft - _gasReserve : 0;
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import './TransferHelper.sol' as TransferHelper;

/**
 * @notice Refunds the extra balance of the native token
 * @dev Reverts on subtraction if the actual balance is less than expected
 * @param _self The address of the executing contract
 * @param _expectedBalance The expected native token balance value
 * @param _to The refund receiver's address
 */
function refundExtraBalance(address _self, uint256 _expectedBalance, address payable _to) {
    uint256 extraBalance = _self.balance - _expectedBalance;

    if (extraBalance > 0) {
        TransferHelper.safeTransferNative(_to, extraBalance);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @notice Emitted when an approval action fails
 */
error SafeApproveError();

/**
 * @notice Emitted when a transfer action fails
 */
error SafeTransferError();

/**
 * @notice Emitted when a transferFrom action fails
 */
error SafeTransferFromError();

/**
 * @notice Emitted when a transfer of the native token fails
 */
error SafeTransferNativeError();

/**
 * @notice Safely approve the token to the account
 * @param _token The token address
 * @param _to The token approval recipient address
 * @param _value The token approval amount
 */
function safeApprove(address _token, address _to, uint256 _value) {
    // 0x095ea7b3 is the selector for "approve(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x095ea7b3, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeApproveError();
    }
}

/**
 * @notice Safely transfer the token to the account
 * @param _token The token address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransfer(address _token, address _to, uint256 _value) {
    // 0xa9059cbb is the selector for "transfer(address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0xa9059cbb, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferError();
    }
}

/**
 * @notice Safely transfer the token between the accounts
 * @param _token The token address
 * @param _from The token transfer source address
 * @param _to The token transfer recipient address
 * @param _value The token transfer amount
 */
function safeTransferFrom(address _token, address _from, address _to, uint256 _value) {
    // 0x23b872dd is the selector for "transferFrom(address,address,uint256)"
    (bool success, bytes memory data) = _token.call(
        abi.encodeWithSelector(0x23b872dd, _from, _to, _value)
    );

    bool condition = success && (data.length == 0 || abi.decode(data, (bool)));

    if (!condition) {
        revert SafeTransferFromError();
    }
}

/**
 * @notice Safely transfer the native token to the account
 * @param _to The native token transfer recipient address
 * @param _value The native token transfer amount
 */
function safeTransferNative(address _to, uint256 _value) {
    (bool success, ) = _to.call{ value: _value }(new bytes(0));

    if (!success) {
        revert SafeTransferNativeError();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IActionDataStructures
 * @notice Action data structure declarations
 */
interface IActionDataStructures {
    /**
     * @notice Single-chain action data structure
     * @param fromTokenAddress The address of the input token
     * @param toTokenAddress The address of the output token
     * @param swapInfo The data for the single-chain swap
     * @param recipient The address of the recipient
     */
    struct LocalAction {
        address fromTokenAddress;
        address toTokenAddress;
        SwapInfo swapInfo;
        address recipient;
    }

    /**
     * @notice Cross-chain action data structure
     * @param gatewayType The numeric type of the cross-chain gateway
     * @param vaultType The numeric type of the vault
     * @param sourceTokenAddress The address of the input token on the source chain
     * @param sourceSwapInfo The data for the source chain swap
     * @param targetChainId The action target chain ID
     * @param targetTokenAddress The address of the output token on the destination chain
     * @param targetSwapInfoOptions The list of data options for the target chain swap
     * @param targetRecipient The address of the recipient on the target chain
     * @param gatewaySettings The gateway-specific settings data
     */
    struct Action {
        uint256 gatewayType;
        uint256 vaultType;
        address sourceTokenAddress;
        SwapInfo sourceSwapInfo;
        uint256 targetChainId;
        address targetTokenAddress;
        SwapInfo[] targetSwapInfoOptions;
        address targetRecipient;
        bytes gatewaySettings;
    }

    /**
     * @notice Token swap data structure
     * @param fromAmount The quantity of the token
     * @param routerType The numeric type of the swap router
     * @param routerData The data for the swap router call
     */
    struct SwapInfo {
        uint256 fromAmount;
        uint256 routerType;
        bytes routerData;
    }

    /**
     * @notice Cross-chain message data structure
     * @param actionId The unique identifier of the cross-chain action
     * @param sourceSender The address of the sender on the source chain
     * @param vaultType The numeric type of the vault
     * @param targetTokenAddress The address of the output token on the target chain
     * @param targetSwapInfo The data for the target chain swap
     * @param targetRecipient The address of the recipient on the target chain
     */
    struct TargetMessage {
        uint256 actionId;
        address sourceSender;
        uint256 vaultType;
        address targetTokenAddress;
        SwapInfo targetSwapInfo;
        address targetRecipient;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { ISettings } from './ISettings.sol';

interface IRegistry is ISettings {
    /**
     * @notice Getter of the registered gateway flag by the account address
     * @param _account The account address
     * @return The registered gateway flag
     */
    function isGatewayAddress(address _account) external view returns (bool);

    /**
     * @notice Settings for a single-chain swap
     * @param _caller The user's account address
     * @param _routerType The type of the swap router
     * @return Settings for a single-chain swap
     */
    function localSettings(
        address _caller,
        uint256 _routerType
    ) external view returns (LocalSettings memory);

    /**
     * @notice Getter of source chain settings for a cross-chain swap
     * @param _caller The user's account address
     * @param _targetChainId The target chain ID
     * @param _gatewayType The type of the cross-chain gateway
     * @param _routerType The type of the swap router
     * @param _vaultType The type of the vault
     * @return Source chain settings for a cross-chain swap
     */
    function sourceSettings(
        address _caller,
        uint256 _targetChainId,
        uint256 _gatewayType,
        uint256 _routerType,
        uint256 _vaultType
    ) external view returns (SourceSettings memory);

    /**
     * @notice Getter of target chain settings for a cross-chain swap
     * @param _vaultType The type of the vault
     * @param _routerType The type of the swap router
     * @return Target chain settings for a cross-chain swap
     */
    function targetSettings(
        uint256 _vaultType,
        uint256 _routerType
    ) external view returns (TargetSettings memory);

    /**
     * @notice Getter of variable balance repayment settings
     * @param _vaultType The type of the vault
     * @return Variable balance repayment settings
     */
    function variableBalanceRepaymentSettings(
        uint256 _vaultType
    ) external view returns (VariableBalanceRepaymentSettings memory);

    /**
     * @notice Getter of cross-chain message fee estimation settings
     * @param _gatewayType The type of the cross-chain gateway
     * @return Cross-chain message fee estimation settings
     */
    function messageFeeEstimateSettings(
        uint256 _gatewayType
    ) external view returns (MessageFeeEstimateSettings memory);

    /**
     * @notice Getter of swap result calculation settings for a single-chain swap
     * @param _caller The user's account address
     * @return Swap result calculation settings for a single-chain swap
     */
    function localAmountCalculationSettings(
        address _caller
    ) external view returns (LocalAmountCalculationSettings memory);

    /**
     * @notice Getter of swap result calculation settings for a cross-chain swap
     * @param _caller The user's account address
     * @param _vaultType The type of the vault
     * @param _fromChainId The ID of the swap source chain
     * @param _toChainId The ID of the swap target chain
     * @return Swap result calculation settings for a cross-chain swap
     */
    function vaultAmountCalculationSettings(
        address _caller,
        uint256 _vaultType,
        uint256 _fromChainId,
        uint256 _toChainId
    ) external view returns (VaultAmountCalculationSettings memory);

    /**
     * @notice Getter of amount limits in USD for cross-chain swaps
     * @param _vaultType The type of the vault
     * @return min Minimum cross-chain swap amount in USD, with decimals = 18
     * @return max Maximum cross-chain swap amount in USD, with decimals = 18
     */
    function swapAmountLimits(uint256 _vaultType) external view returns (uint256 min, uint256 max);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ISettings
 * @notice Settings data structure declarations
 */
interface ISettings {
    /**
     * @notice Settings for a single-chain swap
     * @param router The swap router contract address
     * @param routerTransfer The swap router transfer contract address
     * @param systemFeeLocal The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param feeCollectorLocal The address of the single-chain action fee collector
     * @param isWhitelist The whitelist flag
     */
    struct LocalSettings {
        address router;
        address routerTransfer;
        uint256 systemFeeLocal;
        address feeCollectorLocal;
        bool isWhitelist;
    }

    /**
     * @notice Source chain settings for a cross-chain swap
     * @param gateway The cross-chain gateway contract address
     * @param router The swap router contract address
     * @param routerTransfer The swap router transfer contract address
     * @param vault The vault contract address
     * @param sourceVaultDecimals The value of the vault decimals on the source chain
     * @param targetVaultDecimals The value of the vault decimals on the target chain
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param feeCollector The address of the cross-chain action fee collector
     * @param isWhitelist The whitelist flag
     * @param swapAmountMin The minimum cross-chain swap amount in USD, with decimals = 18
     * @param swapAmountMax The maximum cross-chain swap amount in USD, with decimals = 18
     */
    struct SourceSettings {
        address gateway;
        address router;
        address routerTransfer;
        address vault;
        uint256 sourceVaultDecimals;
        uint256 targetVaultDecimals;
        uint256 systemFee;
        address feeCollector;
        bool isWhitelist;
        uint256 swapAmountMin;
        uint256 swapAmountMax;
    }

    /**
     * @notice Target chain settings for a cross-chain swap
     * @param router The swap router contract address
     * @param routerTransfer The swap router transfer contract address
     * @param vault The vault contract address
     * @param gasReserve The target chain gas reserve value
     */
    struct TargetSettings {
        address router;
        address routerTransfer;
        address vault;
        uint256 gasReserve;
    }

    /**
     * @notice Variable balance repayment settings
     * @param vault The vault contract address
     */
    struct VariableBalanceRepaymentSettings {
        address vault;
    }

    /**
     * @notice Cross-chain message fee estimation settings
     * @param gateway The cross-chain gateway contract address
     */
    struct MessageFeeEstimateSettings {
        address gateway;
    }

    /**
     * @notice Swap result calculation settings for a single-chain swap
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param isWhitelist The whitelist flag
     */
    struct LocalAmountCalculationSettings {
        uint256 systemFeeLocal;
        bool isWhitelist;
    }

    /**
     * @notice Swap result calculation settings for a cross-chain swap
     * @param fromDecimals The value of the vault decimals on the source chain
     * @param toDecimals The value of the vault decimals on the target chain
     * @param systemFee The system fee value in milli-percent, e.g., 100 is 0.1%
     * @param isWhitelist The whitelist flag
     */
    struct VaultAmountCalculationSettings {
        uint256 fromDecimals;
        uint256 toDecimals;
        uint256 systemFee;
        bool isWhitelist;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ITokenBalance
 * @notice Token balance interface
 */
interface ITokenBalance {
    /**
     * @notice Getter of the token balance by the account
     * @param _account The account address
     * @return Token balance
     */
    function balanceOf(address _account) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title ITokenMint
 * @notice Token minting interface
 */
interface ITokenMint {
    /**
     * @notice Mints tokens to the account, increasing the total supply
     * @param _to The token receiver account address
     * @param _amount The number of tokens to mint
     * @return Token burning success status
     */
    function mint(address _to, uint256 _amount) external returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IVariableBalanceRecords
 * @notice Variable balance records interface
 */
interface IVariableBalanceRecords {
    /**
     * @notice Increases the variable balance for the account
     * @param _account The account address
     * @param _vaultType The vault type
     * @param _amount The amount by which to increase the variable balance
     */
    function increaseBalance(address _account, uint256 _vaultType, uint256 _amount) external;

    /**
     * @notice Clears the variable balance for the account
     * @param _account The account address
     * @param _vaultType The vault type
     */
    function clearBalance(address _account, uint256 _vaultType) external;

    /**
     * @notice Getter of the variable balance by the account
     * @param _account The account address
     * @param _vaultType The vault type
     */
    function getAccountBalance(
        address _account,
        uint256 _vaultType
    ) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title IVault
 * @notice Vault interface
 */
interface IVault {
    /**
     * @notice The getter of the vault asset address
     */
    function asset() external view returns (address);

    /**
     * @notice Checks the status of the variable token and balance actions and the variable token address
     * @return The address of the variable token
     */
    function checkVariableTokenState() external view returns (address);

    /**
     * @notice Requests the vault asset tokens
     * @param _amount The amount of the vault asset tokens
     * @param _to The address of the vault asset tokens receiver
     * @param _forVariableBalance True if the request is made for a variable balance repayment, otherwise false
     * @return assetAddress The address of the vault asset token
     */
    function requestAsset(
        uint256 _amount,
        address _to,
        bool _forVariableBalance
    ) external returns (address assetAddress);
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { Pausable as PausableBase } from '@openzeppelin/contracts/security/Pausable.sol';
import { ManagerRole } from './roles/ManagerRole.sol';

/**
 * @title Pausable
 * @notice Base contract that implements the emergency pause mechanism
 */
abstract contract Pausable is PausableBase, ManagerRole {
    /**
     * @notice Enter pause state
     */
    function pause() external onlyManager whenNotPaused {
        _pause();
    }

    /**
     * @notice Exit pause state
     */
    function unpause() external onlyManager whenPaused {
        _unpause();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { RoleBearers } from './RoleBearers.sol';

/**
 * @title AssetSpenderRole
 * @notice Base contract that implements the Asset Spender role
 */
abstract contract AssetSpenderRole is RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('AssetSpender');

    /**
     * @notice Emitted when the Asset Spender role status for the account is updated
     * @param account The account address
     * @param value The Asset Spender role status flag
     */
    event SetAssetSpender(address indexed account, bool indexed value);

    /**
     * @notice Emitted when the caller is not an Asset Spender role bearer
     */
    error OnlyAssetSpenderError();

    /**
     * @dev Modifier to check if the caller is an Asset Spender role bearer
     */
    modifier onlyAssetSpender() {
        if (!isAssetSpender(msg.sender)) {
            revert OnlyAssetSpenderError();
        }

        _;
    }

    /**
     * @notice Getter of the Asset Spender role bearer count
     * @return The Asset Spender role bearer count
     */
    function assetSpenderCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Asset Spender role bearers
     * @return The complete list of the Asset Spender role bearers
     */
    function fullAssetSpenderList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Asset Spender role bearer status
     * @param _account The account address
     */
    function isAssetSpender(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _setAssetSpender(address _account, bool _value) internal {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetAssetSpender(_account, _value);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';
import { RoleBearers } from './RoleBearers.sol';

/**
 * @title ManagerRole
 * @notice Base contract that implements the Manager role.
 * The manager role is a high-permission role for core team members only.
 * Managers can set vaults and routers addresses, fees, cross-chain protocols,
 * and other parameters for Interchain (cross-chain) swaps and single-network swaps.
 * Please note, the manager role is unique for every contract,
 * hence different addresses may be assigned as managers for different contracts.
 */
abstract contract ManagerRole is Ownable, RoleBearers {
    bytes32 private constant ROLE_KEY = keccak256('Manager');

    /**
     * @notice Emitted when the Manager role status for the account is updated
     * @param account The account address
     * @param value The Manager role status flag
     */
    event SetManager(address indexed account, bool indexed value);

    /**
     * @notice Emitted when the Manager role status for the account is renounced
     * @param account The account address
     */
    event RenounceManagerRole(address indexed account);

    /**
     * @notice Emitted when the caller is not a Manager role bearer
     */
    error OnlyManagerError();

    /**
     * @dev Modifier to check if the caller is a Manager role bearer
     */
    modifier onlyManager() {
        if (!isManager(msg.sender)) {
            revert OnlyManagerError();
        }

        _;
    }

    /**
     * @notice Updates the Manager role status for the account
     * @param _account The account address
     * @param _value The Manager role status flag
     */
    function setManager(address _account, bool _value) public onlyOwner {
        _setRoleBearer(ROLE_KEY, _account, _value);

        emit SetManager(_account, _value);
    }

    /**
     * @notice Renounces the Manager role
     */
    function renounceManagerRole() external onlyManager {
        _setRoleBearer(ROLE_KEY, msg.sender, false);

        emit RenounceManagerRole(msg.sender);
    }

    /**
     * @notice Getter of the Manager role bearer count
     * @return The Manager role bearer count
     */
    function managerCount() external view returns (uint256) {
        return _roleBearerCount(ROLE_KEY);
    }

    /**
     * @notice Getter of the complete list of the Manager role bearers
     * @return The complete list of the Manager role bearers
     */
    function fullManagerList() external view returns (address[] memory) {
        return _fullRoleBearerList(ROLE_KEY);
    }

    /**
     * @notice Getter of the Manager role bearer status
     * @param _account The account address
     */
    function isManager(address _account) public view returns (bool) {
        return _isRoleBearer(ROLE_KEY, _account);
    }

    function _initRoles(
        address _owner,
        address[] memory _managers,
        bool _addOwnerToManagers
    ) internal {
        address ownerAddress = _owner == address(0) ? msg.sender : _owner;

        for (uint256 index; index < _managers.length; index++) {
            setManager(_managers[index], true);
        }

        if (_addOwnerToManagers && !isManager(ownerAddress)) {
            setManager(ownerAddress, true);
        }

        if (ownerAddress != msg.sender) {
            transferOwnership(ownerAddress);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

import '../Constants.sol' as Constants;
import '../DataStructures.sol' as DataStructures;

/**
 * @title RoleBearers
 * @notice Base contract that implements role-based access control
 * @dev A custom implementation providing full role bearer lists
 */
abstract contract RoleBearers {
    mapping(bytes32 /*roleKey*/ => address[] /*roleBearers*/) private roleBearerTable;
    mapping(bytes32 /*roleKey*/ => mapping(address /*account*/ => DataStructures.OptionalValue /*status*/))
        private roleBearerIndexTable;

    function _setRoleBearer(bytes32 _roleKey, address _account, bool _value) internal {
        DataStructures.uniqueAddressListUpdate(
            roleBearerTable[_roleKey],
            roleBearerIndexTable[_roleKey],
            _account,
            _value,
            Constants.LIST_SIZE_LIMIT_DEFAULT
        );
    }

    function _isRoleBearer(bytes32 _roleKey, address _account) internal view returns (bool) {
        return roleBearerIndexTable[_roleKey][_account].isSet;
    }

    function _roleBearerCount(bytes32 _roleKey) internal view returns (uint256) {
        return roleBearerTable[_roleKey].length;
    }

    function _fullRoleBearerList(bytes32 _roleKey) internal view returns (address[] memory) {
        return roleBearerTable[_roleKey];
    }
}

// SPDX-License-Identifier: AGPL-3.0-only

pragma solidity 0.8.19;

/**
 * @title SystemVersionId
 * @notice Base contract providing the system version identifier
 */
abstract contract SystemVersionId {
    /**
     * @dev The system version identifier
     */
    uint256 public constant SYSTEM_VERSION_ID = uint256(keccak256('CCTP - Initial'));
}