// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import './IUpgradable.sol';

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasService is IUpgradable {
    error NothingReceived();
    error TransferFailed();
    error InvalidAddress();
    error NotCollector();
    error InvalidAmounts();

    event GasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCall(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event NativeGasPaidForContractCallWithToken(
        address indexed sourceAddress,
        string destinationChain,
        string destinationAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        uint256 gasFeeAmount,
        address refundAddress
    );

    event GasAdded(bytes32 indexed txHash, uint256 indexed logIndex, address gasToken, uint256 gasFeeAmount, address refundAddress);

    event NativeGasAdded(bytes32 indexed txHash, uint256 indexed logIndex, uint256 gasFeeAmount, address refundAddress);

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCall(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable;

    // This is called on the source chain before calling the gateway to execute a remote contract.
    function payNativeGasForContractCallWithToken(
        address sender,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address refundAddress
    ) external payable;

    function addGas(
        bytes32 txHash,
        uint256 txIndex,
        address gasToken,
        uint256 gasFeeAmount,
        address refundAddress
    ) external;

    function addNativeGas(
        bytes32 txHash,
        uint256 logIndex,
        address refundAddress
    ) external payable;

    function collectFees(
        address payable receiver,
        address[] calldata tokens,
        uint256[] calldata amounts
    ) external;

    function refund(
        address payable receiver,
        address token,
        uint256 amount
    ) external;

    function gasCollector() external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(address indexed sender, string destinationChain, string destinationAddress, string symbol, uint256 amount);

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

// General interface for upgradable contracts
interface IUpgradable {
    error NotOwner();
    error InvalidOwner();
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);
    event OwnershipTransferred(address indexed newOwner);

    // Get current owner
    function owner() external view returns (address);

    function contractId() external pure returns (bytes32);

    function implementation() external view returns (address);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';
import { IERC20 } from '../interfaces/IERC20.sol';
import { IAxelarForecallable } from '../interfaces/IAxelarForecallable.sol';

contract AxelarForecallable is IAxelarForecallable {
    IAxelarGateway public immutable gateway;

    //keccak256('forecallers');
    uint256 public constant FORECALLERS_SALT = 0xdb79ee324babd8834c3c1a1a2739c004fce73b812ac9f637241ff47b19e4b71f;

    constructor(address gateway_) {
        if (gateway_ == address(0)) revert InvalidAddress();

        gateway = IAxelarGateway(gateway_);
    }

    function getForecaller(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) public view override returns (address forecaller) {
        bytes32 pos = keccak256(abi.encode(sourceChain, sourceAddress, payload, FORECALLERS_SALT));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            forecaller := sload(pos)
        }
    }

    function _setForecaller(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        address forecaller
    ) internal {
        bytes32 pos = keccak256(abi.encode(sourceChain, sourceAddress, payload, FORECALLERS_SALT));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(pos, forecaller)
        }
    }

    function forecall(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external {
        _checkForecall(sourceChain, sourceAddress, payload, msg.sender);
        if (getForecaller(sourceChain, sourceAddress, payload) != address(0)) revert AlreadyForecalled();
        _setForecaller(sourceChain, sourceAddress, payload, msg.sender);
        _execute(sourceChain, sourceAddress, payload);
    }

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external override {
        bytes32 payloadHash = keccak256(payload);
        if (!gateway.validateContractCall(commandId, sourceChain, sourceAddress, payloadHash))
            revert NotApprovedByGateway();
        address forecaller = getForecaller(sourceChain, sourceAddress, payload);
        if (forecaller != address(0)) {
            _setForecaller(sourceChain, sourceAddress, payload, address(0));
        } else {
            _execute(sourceChain, sourceAddress, payload);
        }
    }

    function getForecallerWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) public view override returns (address forecaller) {
        bytes32 pos = keccak256(abi.encode(sourceChain, sourceAddress, payload, symbol, amount, FORECALLERS_SALT));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            forecaller := sload(pos)
        }
    }

    function _setForecallerWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount,
        address forecaller
    ) internal {
        bytes32 pos = keccak256(abi.encode(sourceChain, sourceAddress, payload, symbol, amount, FORECALLERS_SALT));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(pos, forecaller)
        }
    }

    function forecallWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external override {
        address token = gateway.tokenAddresses(tokenSymbol);
        uint256 amountPost = amountPostFee(amount, payload);
        _safeTransferFrom(token, msg.sender, amountPost);
        _checkForecallWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount, msg.sender);
        if (getForecallerWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount) != address(0))
            revert AlreadyForecalled();
        _setForecallerWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount, msg.sender);
        _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amountPost);
    }

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external override {
        bytes32 payloadHash = keccak256(payload);
        if (
            !gateway.validateContractCallAndMint(
                commandId,
                sourceChain,
                sourceAddress,
                payloadHash,
                tokenSymbol,
                amount
            )
        ) revert NotApprovedByGateway();
        address forecaller = getForecallerWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
        if (forecaller != address(0)) {
            _setForecallerWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount, address(0));
            address token = gateway.tokenAddresses(tokenSymbol);
            _safeTransfer(token, forecaller, amount);
        } else {
            _executeWithToken(sourceChain, sourceAddress, payload, tokenSymbol, amount);
        }
    }

    function _execute(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) internal virtual {}

    function _executeWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) internal virtual {}

    // Override this to keep a fee.
    function amountPostFee(
        uint256 amount,
        bytes calldata /*payload*/
    ) public virtual override returns (uint256) {
        return amount;
    }

    // Override this and revert if you want to only allow certain people/calls to be able to forecall.
    function _checkForecall(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        address forecaller
    ) internal virtual {}

    // Override this and revert if you want to only allow certain people/calls to be able to forecall.
    function _checkForecallWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount,
        address forecaller
    ) internal virtual {}

    function _safeTransfer(
        address tokenAddress,
        address receiver,
        uint256 amount
    ) internal {
        (bool success, bytes memory returnData) = tokenAddress.call(
            abi.encodeWithSelector(IERC20.transfer.selector, receiver, amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || tokenAddress.code.length == 0) revert TransferFailed();
    }

    function _safeTransferFrom(
        address tokenAddress,
        address from,
        uint256 amount
    ) internal {
        (bool success, bytes memory returnData) = tokenAddress.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(this), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));

        if (!transferred || tokenAddress.code.length == 0) revert TransferFailed();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarGateway } from '../interfaces/IAxelarGateway.sol';

interface IAxelarExecutable {
    error InvalidAddress();
    error NotApprovedByGateway();

    function gateway() external view returns (IAxelarGateway);

    function execute(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function executeWithToken(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IAxelarExecutable } from '../interfaces/IAxelarExecutable.sol';

interface IAxelarForecallable is IAxelarExecutable {
    error AlreadyForecalled();
    error TransferFailed();

    function forecall(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external;

    function forecallWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata tokenSymbol,
        uint256 amount
    ) external;

    function getForecaller(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload
    ) external returns (address forecaller);

    function getForecallerWithToken(
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external returns (address forecaller);

    function amountPostFee(uint256 amount, bytes calldata payload) external returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IAxelarGateway {
    /**********\
    |* Errors *|
    \**********/

    error NotSelf();
    error NotProxy();
    error InvalidCodeHash();
    error SetupFailed();
    error InvalidAuthModule();
    error InvalidTokenDeployer();
    error InvalidAmount();
    error InvalidChainId();
    error InvalidCommands();
    error TokenDoesNotExist(string symbol);
    error TokenAlreadyExists(string symbol);
    error TokenDeployFailed(string symbol);
    error TokenContractDoesNotExist(address token);
    error BurnFailed(string symbol);
    error MintFailed(string symbol);
    error InvalidSetMintLimitsParams();
    error ExceedMintLimit(string symbol);

    /**********\
    |* Events *|
    \**********/

    event TokenSent(
        address indexed sender,
        string destinationChain,
        string destinationAddress,
        string symbol,
        uint256 amount
    );

    event ContractCall(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload
    );

    event ContractCallWithToken(
        address indexed sender,
        string destinationChain,
        string destinationContractAddress,
        bytes32 indexed payloadHash,
        bytes payload,
        string symbol,
        uint256 amount
    );

    event Executed(bytes32 indexed commandId);

    event TokenDeployed(string symbol, address tokenAddresses);

    event ContractCallApproved(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount,
        bytes32 sourceTxHash,
        uint256 sourceEventIndex
    );

    event TokenMintLimitUpdated(string symbol, uint256 limit);

    event OperatorshipTransferred(bytes newOperatorsData);

    event Upgraded(address indexed implementation);

    /********************\
    |* Public Functions *|
    \********************/

    function sendToken(
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata symbol,
        uint256 amount
    ) external;

    function callContract(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload
    ) external;

    function callContractWithToken(
        string calldata destinationChain,
        string calldata contractAddress,
        bytes calldata payload,
        string calldata symbol,
        uint256 amount
    ) external;

    function isContractCallApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash
    ) external view returns (bool);

    function isContractCallAndMintApproved(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        address contractAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external view returns (bool);

    function validateContractCall(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string calldata sourceChain,
        string calldata sourceAddress,
        bytes32 payloadHash,
        string calldata symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function authModule() external view returns (address);

    function tokenDeployer() external view returns (address);

    function tokenMintLimit(string memory symbol) external view returns (uint256);

    function tokenMintAmount(string memory symbol) external view returns (uint256);

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol) external view returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    function adminEpoch() external view returns (uint256);

    function adminThreshold(uint256 epoch) external view returns (uint256);

    function admins(uint256 epoch) external view returns (address[] memory);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function setTokenMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata setupParams
    ) external;

    /**********************\
    |* External Functions *|
    \**********************/

    function setup(bytes calldata params) external;

    function execute(bytes calldata input) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error InvalidAccount();

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

pragma solidity ^0.8.0;

// General interface for upgradable contracts
interface IUpgradable {
    error NotOwner();
    error InvalidOwner();
    error InvalidCodeHash();
    error InvalidImplementation();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);
    event OwnershipTransferred(address indexed newOwner);

    // Get current owner
    function owner() external view returns (address);

    function contractId() external pure returns (bytes32);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IUpgradable } from '../interfaces/IUpgradable.sol';

contract Proxy {
    error InvalidImplementation();
    error SetupFailed();
    error EtherNotAccepted();
    error NotOwner();
    error AlreadyInitialized();

    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    // keccak256('owner')
    bytes32 internal constant _OWNER_SLOT = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;

    constructor() {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_OWNER_SLOT, caller())
        }
    }

    function init(
        address implementationAddress,
        address newOwner,
        bytes memory params
    ) external {
        address owner;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            owner := sload(_OWNER_SLOT)
        }
        if (msg.sender != owner) revert NotOwner();
        if (implementation() != address(0)) revert AlreadyInitialized();
        if (IUpgradable(implementationAddress).contractId() != contractId()) revert InvalidImplementation();

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_IMPLEMENTATION_SLOT, implementationAddress)
            sstore(_OWNER_SLOT, newOwner)
        }
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = implementationAddress.delegatecall(
            //0x9ded06df is the setup selector.
            abi.encodeWithSelector(0x9ded06df, params)
        );
        if (!success) revert SetupFailed();
    }

    // solhint-disable-next-line no-empty-blocks
    function contractId() internal pure virtual returns (bytes32) {}

    function implementation() public view returns (address implementation_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    // solhint-disable-next-line no-empty-blocks
    function setup(bytes calldata data) public {}

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address implementaion_ = implementation();
        // solhint-disable-next-line no-inline-assembly
        assembly {
            calldatacopy(0, 0, calldatasize())

            let result := delegatecall(gas(), implementaion_, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    receive() external payable virtual {
        revert EtherNotAccepted();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '../interfaces/IUpgradable.sol';

abstract contract Upgradable is IUpgradable {
    // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    // keccak256('owner')
    bytes32 internal constant _OWNER_SLOT = 0x02016836a56b71f0d02689e69e326f4f4c1b9057164ef592671cf0d37c8040c0;

    modifier onlyOwner() {
        if (owner() != msg.sender) revert NotOwner();
        _;
    }

    function owner() public view returns (address owner_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            owner_ := sload(_OWNER_SLOT)
        }
    }

    function transferOwnership(address newOwner) external virtual onlyOwner {
        if (newOwner == address(0)) revert InvalidOwner();

        emit OwnershipTransferred(newOwner);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_OWNER_SLOT, newOwner)
        }
    }

    function implementation() public view returns (address implementation_) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            implementation_ := sload(_IMPLEMENTATION_SLOT)
        }
    }

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external override onlyOwner {
        if (IUpgradable(newImplementation).contractId() != IUpgradable(this).contractId())
            revert InvalidImplementation();
        if (newImplementationCodeHash != newImplementation.codehash) revert InvalidCodeHash();

        if (params.length > 0) {
            // solhint-disable-next-line avoid-low-level-calls
            (bool success, ) = newImplementation.delegatecall(abi.encodeWithSelector(this.setup.selector, params));

            if (!success) revert SetupFailed();
        }

        emit Upgraded(newImplementation);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_IMPLEMENTATION_SLOT, newImplementation)
        }
    }

    function setup(bytes calldata data) external override {
        // Prevent setup from being called on the implementation
        if (implementation() == address(0)) revert NotProxy();

        _setup(data);
    }

    // solhint-disable-next-line no-empty-blocks
    function _setup(bytes calldata data) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ISquidDepositService} from "../interfaces/ISquidDepositService.sol";

contract DepositReceiver {
    constructor(bytes memory delegateData, address refundRecipient) {
        // Reading the implementation of the AxelarDepositService
        // and delegating the call back to it
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = ISquidDepositService(msg.sender).receiverImplementation().delegatecall(delegateData);

        // if not success revert with the original revert data
        if (!success) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }

        if (refundRecipient == address(0)) refundRecipient = msg.sender;

        selfdestruct(payable(refundRecipient));
    }

    // @dev This function is for receiving Ether from unwrapping WETH9
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IAxelarGateway} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGateway.sol";
import {ISquidRouter} from "../interfaces/ISquidRouter.sol";
import {ISquidMulticall} from "../interfaces/ISquidMulticall.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ISquidDepositService} from "../interfaces/ISquidDepositService.sol";

contract ReceiverImplementation {
    using SafeERC20 for IERC20;

    error ZeroAddressProvided();
    error InvalidSymbol();
    error NothingDeposited();

    address private constant nativeCoin = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address immutable router;
    address immutable gateway;

    constructor(address _router, address _gateway) {
        if (_router == address(0) || _gateway == address(0)) revert ZeroAddressProvided();

        router = _router;
        gateway = _gateway;
    }

    // Context: msg.sender == SquidDepositService, this == DepositReceiver
    function receiveAndBridgeCall(
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external {
        // Checking with AxelarDepositService if need to refund a token
        address tokenToRefund = ISquidDepositService(msg.sender).refundToken();
        if (tokenToRefund != address(0)) {
            _refund(tokenToRefund, refundRecipient);
            return;
        }

        address tokenAddress = IAxelarGateway(gateway).tokenAddresses(bridgedTokenSymbol);
        if (tokenAddress == address(0)) revert InvalidSymbol();
        uint256 amount = IERC20(tokenAddress).balanceOf(address(this));
        if (amount == 0) revert NothingDeposited();

        IERC20(tokenAddress).approve(router, amount);
        ISquidRouter(router).bridgeCall{value: address(this).balance}(
            bridgedTokenSymbol,
            amount,
            destinationChain,
            destinationAddress,
            payload,
            refundRecipient,
            enableExpress
        );
    }

    // Context: msg.sender == SquidDepositService, this == DepositReceiver
    function receiveAndCallBridge(
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external {
        // Checking with AxelarDepositService if need to refund a token
        address tokenToRefund = ISquidDepositService(msg.sender).refundToken();
        if (tokenToRefund != address(0)) {
            _refund(tokenToRefund, refundRecipient);
            return;
        }

        uint256 amount = IERC20(token).balanceOf(address(this));
        if (amount == 0) revert NothingDeposited();

        IERC20(token).approve(router, amount);
        ISquidRouter(router).callBridge{value: address(this).balance}(
            token,
            amount,
            calls,
            bridgedTokenSymbol,
            destinationChain,
            destinationAddress
        );
    }

    function receiveAndCallBridgeCall(
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external {
        // Checking with AxelarDepositService if need to refund a token
        address tokenToRefund = ISquidDepositService(msg.sender).refundToken();
        if (tokenToRefund != address(0)) {
            _refund(tokenToRefund, refundRecipient);
            return;
        }

        uint256 amount = IERC20(token).balanceOf(address(this));
        if (amount == 0) revert NothingDeposited();

        IERC20(token).approve(router, amount);
        ISquidRouter(router).callBridgeCall{value: address(this).balance}(
            token,
            amount,
            calls,
            bridgedTokenSymbol,
            destinationChain,
            destinationAddress,
            payload,
            refundRecipient,
            enableExpress
        );
    }

    function receiveAndFundAndRunMulticall(
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external {
        // Checking with AxelarDepositService if need to refund a token
        address tokenToRefund = ISquidDepositService(msg.sender).refundToken();

        if (tokenToRefund != address(0)) {
            _refund(tokenToRefund, refundRecipient);
            return;
        }

        uint256 amount = IERC20(token).balanceOf(address(this));
        if (amount == 0) revert NothingDeposited();

        IERC20(token).approve(router, amount);
        ISquidRouter(router).fundAndRunMulticall{value: address(this).balance}(token, amount, calls);
    }

    function _refund(address tokenToRefund, address refundRecipient) private {
        if (refundRecipient == address(0)) refundRecipient = msg.sender;

        if (tokenToRefund != nativeCoin) {
            uint256 contractBalance = IERC20(tokenToRefund).balanceOf(address(this));
            IERC20(tokenToRefund).safeTransfer(refundRecipient, contractBalance);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ISquidDepositService} from "../interfaces/ISquidDepositService.sol";
import {ISquidMulticall} from "../interfaces/ISquidMulticall.sol";
import {IAxelarGateway} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGateway.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Upgradable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradables/Upgradable.sol";
import {DepositReceiver} from "./DepositReceiver.sol";
import {ReceiverImplementation} from "./ReceiverImplementation.sol";

/// @dev This should be owned by the microservice that is paying for gas.
contract SquidDepositService is Upgradable, ISquidDepositService {
    using SafeERC20 for IERC20;

    // This public storage is for ERC20 token intended to be refunded.
    // It triggers the DepositReceiver/ReceiverImplementation to switch into a refund mode.
    // Address is stored and deleted withing the same refund transaction.
    address public refundToken;

    address private constant nativeCoin = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address immutable gateway;
    address public immutable refundIssuer;
    address public immutable receiverImplementation;

    constructor(address _router, address _gateway, address _refundIssuer) {
        if (_gateway == address(0) || _refundIssuer == address(0)) revert ZeroAddressProvided();

        gateway = _gateway;
        refundIssuer = _refundIssuer;
        receiverImplementation = address(new ReceiverImplementation(_router, _gateway));
    }

    function addressForBridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndBridgeCall.selector,
                    bridgedTokenSymbol,
                    destinationChain,
                    destinationAddress,
                    payload,
                    refundRecipient,
                    enableExpress
                ),
                refundRecipient
            );
    }

    function addressForCallBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndCallBridge.selector,
                    token,
                    calls,
                    bridgedTokenSymbol,
                    destinationChain,
                    destinationAddress,
                    refundRecipient
                ),
                refundRecipient
            );
    }

    function addressForCallBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndCallBridgeCall.selector,
                    token,
                    calls,
                    bridgedTokenSymbol,
                    destinationChain,
                    destinationAddress,
                    payload,
                    refundRecipient,
                    enableExpress
                ),
                refundRecipient
            );
    }

    function addressForFundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external view returns (address) {
        return
            _depositAddress(
                salt,
                abi.encodeWithSelector(
                    ReceiverImplementation.receiveAndFundAndRunMulticall.selector,
                    token,
                    calls,
                    refundRecipient
                ),
                refundRecipient
            );
    }

    function bridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external {
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndBridgeCall.selector,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                payload,
                refundRecipient,
                enableExpress
            ),
            refundRecipient
        );
    }

    function callBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external {
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndCallBridge.selector,
                token,
                calls,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                refundRecipient
            ),
            refundRecipient
        );
    }

    function callBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express
    ) external {
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndCallBridgeCall.selector,
                token,
                calls,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                payload,
                refundRecipient,
                express
            ),
            refundRecipient
        );
    }

    function fundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external {
        // NOTE: `DepositReceiver` is destroyed in the same runtime context that it is deployed.
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndFundAndRunMulticall.selector,
                token,
                calls,
                refundRecipient
            ),
            refundRecipient
        );
    }

    /// @dev Refunds ERC20 token from the deposit address if it doesn't match the intended token
    // Only refundRecipient can refund the token that was intended to go cross-chain (if not sent yet)
    function refundBridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express,
        address tokenToRefund
    ) external {
        address intendedToken = IAxelarGateway(gateway).tokenAddresses(bridgedTokenSymbol);
        // Allowing only the refundRecipient to refund the intended token
        if (tokenToRefund == intendedToken && msg.sender != refundRecipient) return;

        // Saving to public storage to be accessed by the DepositReceiver
        refundToken = tokenToRefund;

        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndBridgeCall.selector,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                payload,
                refundRecipient,
                express
            ),
            refundRecipient
        );

        refundToken = address(0);
    }

    function refundCallBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient,
        address tokenToRefund
    ) external {
        // Allowing only the refundRecipient to refund the intended token
        if (tokenToRefund == token && msg.sender != refundRecipient) return;

        // Saving to public storage to be accessed by the DepositReceiver
        refundToken = tokenToRefund;
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndCallBridge.selector,
                token,
                calls,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                refundRecipient
            ),
            refundRecipient
        );

        refundToken = address(0);
    }

    function refundCallBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express,
        address tokenToRefund
    ) external {
        // Allowing only the refundRecipient to refund the intended token
        if (tokenToRefund == token && msg.sender != refundRecipient) return;

        // Saving to public storage to be accessed by the DepositReceiver
        refundToken = tokenToRefund;
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndCallBridgeCall.selector,
                token,
                calls,
                bridgedTokenSymbol,
                destinationChain,
                destinationAddress,
                payload,
                refundRecipient,
                express
            ),
            refundRecipient
        );

        refundToken = address(0);
    }

    function refundFundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient,
        address tokenToRefund
    ) external {
        // Allowing only the refundRecipient to refund the intended token
        if (tokenToRefund == token && msg.sender != refundRecipient) return;

        // Saving to public storage to be accessed by the DepositReceiver
        refundToken = tokenToRefund;
        new DepositReceiver{salt: salt}(
            abi.encodeWithSelector(
                ReceiverImplementation.receiveAndFundAndRunMulticall.selector,
                token,
                calls,
                refundRecipient
            ),
            refundRecipient
        );

        refundToken = address(0);
    }

    function refundLockedAsset(address receiver, address token, uint256 amount) external {
        if (msg.sender != refundIssuer) revert NotRefundIssuer();
        if (receiver == address(0)) revert ZeroAddressProvided();

        if (token == nativeCoin) {
            (bool sent, ) = receiver.call{value: amount}("");
            if (!sent) revert NativeTransferFailed();
        } else {
            IERC20(token).safeTransfer(receiver, amount);
        }
    }

    function _depositAddress(
        bytes32 salt,
        bytes memory delegateData,
        address refundRecipient
    ) private view returns (address) {
        /* Convert a hash which is bytes32 to an address which is 20-byte long
        according to https://docs.soliditylang.org/en/v0.8.9/control-structures.html?highlight=create2#salted-contract-creations-create2 */
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                salt,
                                // Encoding delegateData and refundRecipient as constructor params
                                keccak256(
                                    abi.encodePacked(
                                        type(DepositReceiver).creationCode,
                                        abi.encode(delegateData, refundRecipient)
                                    )
                                )
                            )
                        )
                    )
                )
            );
    }

    function contractId() external pure returns (bytes32) {
        return keccak256("squid-deposit-service");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    error InvalidAccount();

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IRoledPausable {
    event PauserProposed(address indexed currentPauser, address indexed pendingPauser);
    event PauserUpdated(address indexed pendingPauser);
    event Paused();
    event Unpaused();

    error ContractIsPaused();
    error NotPauser();
    error NotPendingPauser();

    function updatePauser(address _newPauser) external;

    function acceptPauser() external;

    function pause() external;

    function unpause() external;

    function paused() external view returns (bool value);

    function pauser() external view returns (address value);

    function pendingPauser() external view returns (address value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import {IUpgradable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IUpgradable.sol";
import {ISquidMulticall} from "./ISquidMulticall.sol";

// This should be owned by the microservice that is paying for gas.
interface ISquidDepositService is IUpgradable {
    error ZeroAddressProvided();
    error NotRefundIssuer();
    error NativeTransferFailed();

    function addressForBridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external view returns (address);

    function addressForCallBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external view returns (address);

    function addressForCallBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external view returns (address);

    function addressForFundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external view returns (address);

    function bridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool enableExpress
    ) external;

    function callBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient
    ) external;

    function callBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express
    ) external;

    function fundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient
    ) external;

    function refundBridgeCallDeposit(
        bytes32 salt,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express,
        address tokenToRefund
    ) external;

    function refundCallBridgeDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        address refundRecipient,
        address tokenToRefund
    ) external;

    function refundCallBridgeCallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address refundRecipient,
        bool express,
        address tokenToRefund
    ) external;

    function refundFundAndRunMulticallDeposit(
        bytes32 salt,
        address token,
        ISquidMulticall.Call[] memory calls,
        address refundRecipient,
        address tokenToRefund
    ) external;

    function refundLockedAsset(address receiver, address token, uint256 amount) external;

    function receiverImplementation() external returns (address receiver);

    function refundToken() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISquidFeeCollector {
    event FeeCollected(address token, address integrator, uint256 squidFee, uint256 integratorFee);
    event FeeWithdrawn(address token, address account, uint256 amount);

    error TransferFailed();
    error ExcessiveIntegratorFee();

    function collectFee(address token, uint256 amountToTax, address integratorAddress, uint256 integratorFee) external;

    function withdrawFee(address token) external;

    function getBalance(address token, address account) external view returns (uint256 accountBalance);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ISquidMulticall {
    enum CallType {
        Default,
        FullTokenBalance,
        FullNativeBalance,
        CollectTokenBalance
    }

    struct Call {
        CallType callType;
        address target;
        uint256 value;
        bytes callData;
        bytes payload;
    }

    error AlreadyRunning();
    error CallFailed(uint256 callPosition, bytes reason);

    function run(Call[] calldata calls) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ISquidMulticall} from "./ISquidMulticall.sol";

interface ISquidRouter {
    event CrossMulticallExecuted(bytes32 indexed payloadHash);
    event CrossMulticallFailed(bytes32 indexed payloadHash, bytes reason, address indexed refundRecipient);

    error ZeroAddressProvided();
    error ApprovalFailed();

    function bridgeCall(
        string calldata bridgedTokenSymbol,
        uint256 amount,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) external payable;

    function callBridge(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external payable;

    function callBridgeCall(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) external payable;

    function fundAndRunMulticall(address token, uint256 amount, ISquidMulticall.Call[] memory calls) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IAggregationExecutor {
    function callBytes(bytes calldata data) external payable; // 0xd9c45357

    // callbytes per swap sequence
    function swapSingleSequence(bytes calldata data) external;

    function finalTransactionProcessing(
        address tokenIn,
        address tokenOut,
        address to,
        bytes calldata destTokenFeeData
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IExecutorHelper1 {
    struct UniSwap {
        address pool;
        address tokenIn;
        address tokenOut;
        address recipient;
        uint256 collectAmount; // amount that should be transferred to the pool
        uint256 limitReturnAmount;
        uint32 swapFee;
        uint32 feePrecision;
        uint32 tokenWeightInput;
    }

    struct StableSwap {
        address pool;
        address tokenFrom;
        address tokenTo;
        uint8 tokenIndexFrom;
        uint8 tokenIndexTo;
        uint256 dx;
        uint256 minDy;
        uint256 poolLength;
        address poolLp;
        bool isSaddle; // true: saddle, false: stable
    }

    struct CurveSwap {
        address pool;
        address tokenFrom;
        address tokenTo;
        int128 tokenIndexFrom;
        int128 tokenIndexTo;
        uint256 dx;
        uint256 minDy;
        bool usePoolUnderlying;
        bool useTriCrypto;
    }

    struct UniSwapV3ProMM {
        address recipient;
        address pool;
        address tokenIn;
        address tokenOut;
        uint256 swapAmount;
        uint256 limitReturnAmount;
        uint160 sqrtPriceLimitX96;
        bool isUniV3; // true = UniV3, false = ProMM
    }

    struct SwapCallbackData {
        bytes path;
        address payer;
    }

    struct SwapCallbackDataPath {
        address pool;
        address tokenIn;
        address tokenOut;
    }

    struct BalancerV2 {
        address vault;
        bytes32 poolId;
        address assetIn;
        address assetOut;
        uint256 amount;
        uint256 limit;
    }

    struct KyberRFQ {
        address rfq;
        bytes order;
        bytes signature;
        uint256 amount;
        address payable target;
    }

    struct DODO {
        address recipient;
        address pool;
        address tokenFrom;
        address tokenTo;
        uint256 amount;
        uint256 minReceiveQuote;
        address sellHelper;
        bool isSellBase;
        bool isVersion2;
    }

    struct GMX {
        address vault;
        address tokenIn;
        address tokenOut;
        uint256 amount;
        uint256 minOut;
        address receiver;
    }

    struct Synthetix {
        address synthetixProxy;
        address tokenIn;
        address tokenOut;
        bytes32 sourceCurrencyKey;
        uint256 sourceAmount;
        bytes32 destinationCurrencyKey;
        uint256 minAmount;
        bool useAtomicExchange;
    }

    function executeUniSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeStableSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeCurveSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeKyberDMMSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeUniV3ProMMSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeRfqSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeBalV2Swap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeDODOSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeVelodromeSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeGMXSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeSynthetixSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeHashflowSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);

    function executeCamelotSwap(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IExecutorHelper2 {
    function executeKyberLimitOrder(
        uint256 index,
        bytes memory data,
        uint256 previousAmountOut
    ) external payable returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAggregationExecutor} from "./IAggregationExecutor.sol";

interface IMetaAggregationRouter {
    struct SwapDescription {
        IERC20 srcToken;
        IERC20 dstToken;
        address[] srcReceivers;
        uint256[] srcAmounts;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    function swap(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata executorData,
        bytes calldata clientData
    ) external payable returns (uint256, uint256);

    function swapSimpleMode(
        IAggregationExecutor caller,
        SwapDescription calldata desc,
        bytes calldata executorData,
        bytes calldata clientData
    ) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IAggregationExecutor} from "./IAggregationExecutor.sol";

interface IMetaAggregationRouterV2 {
    struct SwapDescriptionV2 {
        IERC20 srcToken;
        IERC20 dstToken;
        address[] srcReceivers; // transfer src token to these addresses, default
        uint256[] srcAmounts;
        address[] feeReceivers;
        uint256[] feeAmounts;
        address dstReceiver;
        uint256 amount;
        uint256 minReturnAmount;
        uint256 flags;
        bytes permit;
    }

    /// @dev  use for swapGeneric and swap to avoid stack too deep
    struct SwapExecutionParams {
        address callTarget; // call this address
        address approveTarget; // approve this address if _APPROVE_FUND set
        bytes targetData;
        SwapDescriptionV2 desc;
        bytes clientData;
    }

    function swap(SwapExecutionParams calldata execution) external payable returns (uint256, uint256);

    function swapSimpleMode(
        IAggregationExecutor caller,
        SwapDescriptionV2 memory desc,
        bytes calldata executorData,
        bytes calldata clientData
    ) external returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IExecutorHelper1} from "./interfaces/kyberswap/IExecutorHelper1.sol";
import {IExecutorHelper2} from "./interfaces/kyberswap/IExecutorHelper2.sol";
import {IMetaAggregationRouterV2} from "./interfaces/kyberswap/IMetaAggregationRouterV2.sol";
import {IMetaAggregationRouter} from "./interfaces/kyberswap/IMetaAggregationRouter.sol";
import {ScaleDataHelper1} from "./libraries/kyberswap/ScaleDataHelper1.sol";

contract KyberswapPatcher {
    uint256 private constant _PARTIAL_FILL = 0x01;
    uint256 private constant _REQUIRES_EXTRA_ETH = 0x02;
    uint256 private constant _SHOULD_CLAIM = 0x04;
    uint256 private constant _BURN_FROM_MSG_SENDER = 0x08;
    uint256 private constant _BURN_FROM_TX_ORIGIN = 0x10;
    uint256 private constant _SIMPLE_SWAP = 0x20;

    struct Swap {
        bytes data;
        bytes4 functionSelector;
    }

    struct SimpleSwapData {
        address[] firstPools;
        uint256[] firstSwapAmounts;
        bytes[] swapDatas;
        uint256 deadline;
        bytes destTokenFeeData;
    }

    struct SwapExecutorDescription {
        Swap[][] swapSequences;
        address tokenIn;
        address tokenOut;
        uint256 minTotalAmountOut;
        address to;
        uint256 deadline;
        bytes destTokenFeeData;
    }

    struct Data {
        address router;
        bytes inputData;
        uint256 newAmount;
    }

    error CallFailed(string message, bytes reason);

    function safeTransferFrom(address token, address from, address to, uint256 value) internal {
        if (value == 0) return;
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value)
        );
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeTransferFrom: Transfer from fail");
    }

    function safeApprove(address token, address to, uint256 value) internal {
        if (value == 0) return;
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "safeApprove: Approve fail");
    }

    function scaleAndSwap(uint256 newAmount, address router, bytes calldata inputData) external payable {
        bytes4 selector = bytes4(inputData[:4]);
        bytes memory dataToDecode = new bytes(inputData.length - 4);
        bytes memory callData;

        for (uint256 i = 0; i < inputData.length - 4; ++i) {
            dataToDecode[i] = inputData[i + 4];
        }

        if (
            selector == IMetaAggregationRouter.swap.selector ||
            selector == IMetaAggregationRouter.swapSimpleMode.selector
        ) {
            (
                address callTarget,
                IMetaAggregationRouter.SwapDescription memory desc,
                bytes memory targetData,
                bytes memory clientData
            ) = abi.decode(dataToDecode, (address, IMetaAggregationRouter.SwapDescription, bytes, bytes));

            (desc, targetData) = _getScaledInputDataV1(
                desc,
                targetData,
                newAmount,
                selector == IMetaAggregationRouter.swapSimpleMode.selector || _flagsChecked(desc.flags, _SIMPLE_SWAP)
            );
            callData = abi.encodeWithSelector(selector, callTarget, desc, targetData, clientData);

            safeTransferFrom(address(desc.srcToken), msg.sender, address(this), newAmount);
            safeApprove(address(desc.srcToken), router, newAmount);
        } else if (selector == IMetaAggregationRouterV2.swap.selector) {
            IMetaAggregationRouterV2.SwapExecutionParams memory params = abi.decode(
                dataToDecode,
                (IMetaAggregationRouterV2.SwapExecutionParams)
            );

            (params.desc, params.targetData) = _getScaledInputDataV2(
                params.desc,
                params.targetData,
                newAmount,
                _flagsChecked(params.desc.flags, _SIMPLE_SWAP)
            );
            callData = abi.encodeWithSelector(selector, params);

            safeTransferFrom(address(params.desc.srcToken), msg.sender, address(this), newAmount);
            safeApprove(address(params.desc.srcToken), router, newAmount);
        } else if (selector == IMetaAggregationRouterV2.swapSimpleMode.selector) {
            (
                address callTarget,
                IMetaAggregationRouterV2.SwapDescriptionV2 memory desc,
                bytes memory targetData,
                bytes memory clientData
            ) = abi.decode(dataToDecode, (address, IMetaAggregationRouterV2.SwapDescriptionV2, bytes, bytes));

            (desc, targetData) = _getScaledInputDataV2(desc, targetData, newAmount, true);
            callData = abi.encodeWithSelector(selector, callTarget, desc, targetData, clientData);

            safeTransferFrom(address(desc.srcToken), msg.sender, address(this), newAmount);
            safeApprove(address(desc.srcToken), router, newAmount);
        } else revert("KyberswapPatcher: Invalid selector");

        (bool success, bytes memory data) = router.call(callData);
        if (!success) revert CallFailed("KyberswapPatcher: call failed", data);
    }

    function _getScaledInputDataV1(
        IMetaAggregationRouter.SwapDescription memory desc,
        bytes memory executorData,
        uint256 newAmount,
        bool isSimpleMode
    ) internal pure returns (IMetaAggregationRouter.SwapDescription memory, bytes memory) {
        uint256 oldAmount = desc.amount;
        if (oldAmount == newAmount) {
            return (desc, executorData);
        }

        // simple mode swap
        if (isSimpleMode) {
            return (
                _scaledSwapDescriptionV1(desc, oldAmount, newAmount),
                _scaledSimpleSwapData(executorData, oldAmount, newAmount)
            );
        }

        //normal mode swap
        return (
            _scaledSwapDescriptionV1(desc, oldAmount, newAmount),
            _scaledExecutorCallBytesData(executorData, oldAmount, newAmount)
        );
    }

    function _getScaledInputDataV2(
        IMetaAggregationRouterV2.SwapDescriptionV2 memory desc,
        bytes memory executorData,
        uint256 newAmount,
        bool isSimpleMode
    ) internal pure returns (IMetaAggregationRouterV2.SwapDescriptionV2 memory, bytes memory) {
        uint256 oldAmount = desc.amount;
        if (oldAmount == newAmount) {
            return (desc, executorData);
        }

        // simple mode swap
        if (isSimpleMode) {
            return (
                _scaledSwapDescriptionV2(desc, oldAmount, newAmount),
                _scaledSimpleSwapData(executorData, oldAmount, newAmount)
            );
        }

        //normal mode swap
        return (
            _scaledSwapDescriptionV2(desc, oldAmount, newAmount),
            _scaledExecutorCallBytesData(executorData, oldAmount, newAmount)
        );
    }

    function _scaledSwapDescriptionV1(
        IMetaAggregationRouter.SwapDescription memory desc,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (IMetaAggregationRouter.SwapDescription memory) {
        desc.minReturnAmount = (desc.minReturnAmount * newAmount) / oldAmount;
        if (desc.minReturnAmount == 0) desc.minReturnAmount = 1;
        desc.amount = newAmount;
        for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
            desc.srcAmounts[i] = (desc.srcAmounts[i] * newAmount) / oldAmount;
        }
        return desc;
    }

    function _scaledSwapDescriptionV2(
        IMetaAggregationRouterV2.SwapDescriptionV2 memory desc,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (IMetaAggregationRouterV2.SwapDescriptionV2 memory) {
        desc.minReturnAmount = (desc.minReturnAmount * newAmount) / oldAmount;
        if (desc.minReturnAmount == 0) desc.minReturnAmount = 1;
        desc.amount = newAmount;
        for (uint256 i = 0; i < desc.srcReceivers.length; i++) {
            desc.srcAmounts[i] = (desc.srcAmounts[i] * newAmount) / oldAmount;
        }
        return desc;
    }

    function _scaledSimpleSwapData(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        SimpleSwapData memory swapData = abi.decode(data, (SimpleSwapData));
        for (uint256 i = 0; i < swapData.firstPools.length; i++) {
            swapData.firstSwapAmounts[i] = (swapData.firstSwapAmounts[i] * newAmount) / oldAmount;
        }
        return abi.encode(swapData);
    }

    function _scaledExecutorCallBytesData(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        SwapExecutorDescription memory executorDesc = abi.decode(data, (SwapExecutorDescription));
        executorDesc.minTotalAmountOut = (executorDesc.minTotalAmountOut * newAmount) / oldAmount;
        for (uint256 i = 0; i < executorDesc.swapSequences.length; i++) {
            Swap memory swap = executorDesc.swapSequences[i][0];
            bytes4 functionSelector = swap.functionSelector;

            if (functionSelector == IExecutorHelper1.executeUniSwap.selector) {
                swap.data = ScaleDataHelper1.newUniSwap(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeStableSwap.selector) {
                swap.data = ScaleDataHelper1.newStableSwap(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeCurveSwap.selector) {
                swap.data = ScaleDataHelper1.newCurveSwap(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeKyberDMMSwap.selector) {
                swap.data = ScaleDataHelper1.newKyberDMM(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeUniV3ProMMSwap.selector) {
                swap.data = ScaleDataHelper1.newUniV3ProMM(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeRfqSwap.selector) {
                revert("KyberswapPatcher: Can not scale RFQ swap");
            } else if (functionSelector == IExecutorHelper1.executeBalV2Swap.selector) {
                swap.data = ScaleDataHelper1.newBalancerV2(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeDODOSwap.selector) {
                swap.data = ScaleDataHelper1.newDODO(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeVelodromeSwap.selector) {
                swap.data = ScaleDataHelper1.newVelodrome(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeGMXSwap.selector) {
                swap.data = ScaleDataHelper1.newGMX(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeSynthetixSwap.selector) {
                swap.data = ScaleDataHelper1.newSynthetix(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper1.executeHashflowSwap.selector) {
                revert("KyberswapPatcher: Can not scale RFQ swap");
            } else if (functionSelector == IExecutorHelper1.executeCamelotSwap.selector) {
                swap.data = ScaleDataHelper1.newCamelot(swap.data, oldAmount, newAmount);
            } else if (functionSelector == IExecutorHelper2.executeKyberLimitOrder.selector) {
                revert("KyberswapPatcher: Can not scale RFQ swap");
            } else revert("AggregationExecutor: Dex type not supported");
        }
        return abi.encode(executorDesc);
    }

    function _flagsChecked(uint256 number, uint256 flag) internal pure returns (bool) {
        return number & flag != 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IExecutorHelper1} from "../../interfaces/kyberswap/IExecutorHelper1.sol";

library ScaleDataHelper1 {
    function newUniSwap(bytes memory data, uint256 oldAmount, uint256 newAmount) internal pure returns (bytes memory) {
        IExecutorHelper1.UniSwap memory uniSwap = abi.decode(data, (IExecutorHelper1.UniSwap));
        uniSwap.collectAmount = (uniSwap.collectAmount * newAmount) / oldAmount;
        return abi.encode(uniSwap);
    }

    function newStableSwap(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper1.StableSwap memory stableSwap = abi.decode(data, (IExecutorHelper1.StableSwap));
        stableSwap.dx = (stableSwap.dx * newAmount) / oldAmount;
        return abi.encode(stableSwap);
    }

    function newCurveSwap(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper1.CurveSwap memory curveSwap = abi.decode(data, (IExecutorHelper1.CurveSwap));
        curveSwap.dx = (curveSwap.dx * newAmount) / oldAmount;
        return abi.encode(curveSwap);
    }

    function newKyberDMM(bytes memory data, uint256 oldAmount, uint256 newAmount) internal pure returns (bytes memory) {
        IExecutorHelper1.UniSwap memory kyberDMMSwap = abi.decode(data, (IExecutorHelper1.UniSwap));
        kyberDMMSwap.collectAmount = (kyberDMMSwap.collectAmount * newAmount) / oldAmount;
        return abi.encode(kyberDMMSwap);
    }

    function newUniV3ProMM(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper1.UniSwapV3ProMM memory uniSwapV3ProMM = abi.decode(data, (IExecutorHelper1.UniSwapV3ProMM));
        uniSwapV3ProMM.swapAmount = (uniSwapV3ProMM.swapAmount * newAmount) / oldAmount;

        return abi.encode(uniSwapV3ProMM);
    }

    function newBalancerV2(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper1.BalancerV2 memory balancerV2 = abi.decode(data, (IExecutorHelper1.BalancerV2));
        balancerV2.amount = (balancerV2.amount * newAmount) / oldAmount;
        return abi.encode(balancerV2);
    }

    function newDODO(bytes memory data, uint256 oldAmount, uint256 newAmount) internal pure returns (bytes memory) {
        IExecutorHelper1.DODO memory dodo = abi.decode(data, (IExecutorHelper1.DODO));
        dodo.amount = (dodo.amount * newAmount) / oldAmount;
        return abi.encode(dodo);
    }

    function newVelodrome(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper1.UniSwap memory velodrome = abi.decode(data, (IExecutorHelper1.UniSwap));
        velodrome.collectAmount = (velodrome.collectAmount * newAmount) / oldAmount;
        return abi.encode(velodrome);
    }

    function newGMX(bytes memory data, uint256 oldAmount, uint256 newAmount) internal pure returns (bytes memory) {
        IExecutorHelper1.GMX memory gmx = abi.decode(data, (IExecutorHelper1.GMX));
        gmx.amount = (gmx.amount * newAmount) / oldAmount;
        return abi.encode(gmx);
    }

    function newSynthetix(
        bytes memory data,
        uint256 oldAmount,
        uint256 newAmount
    ) internal pure returns (bytes memory) {
        IExecutorHelper1.Synthetix memory synthetix = abi.decode(data, (IExecutorHelper1.Synthetix));
        synthetix.sourceAmount = (synthetix.sourceAmount * newAmount) / oldAmount;
        return abi.encode(synthetix);
    }

    function newCamelot(bytes memory data, uint256 oldAmount, uint256 newAmount) internal pure returns (bytes memory) {
        IExecutorHelper1.UniSwap memory camelot = abi.decode(data, (IExecutorHelper1.UniSwap));
        camelot.collectAmount = (camelot.collectAmount * newAmount) / oldAmount;
        return abi.encode(camelot);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {IRoledPausable} from "../interfaces/IRoledPausable.sol";
import {StorageSlot} from "./StorageSlot.sol";

abstract contract RoledPausable is IRoledPausable {
    using StorageSlot for bytes32;

    bytes32 internal constant PAUSED_SLOT = keccak256("RoledPausable.paused");
    bytes32 internal constant PAUSER_SLOT = keccak256("RoledPausable.pauser");
    bytes32 internal constant PENDING_PAUSER_SLOT = keccak256("RoledPausable.pendingPauser");

    modifier whenNotPaused() {
        if (paused()) revert ContractIsPaused();
        _;
    }

    modifier onlyPauser() {
        if (msg.sender != pauser()) revert NotPauser();
        _;
    }

    constructor() {
        _setPauser(msg.sender);
    }

    function updatePauser(address newPauser) external onlyPauser {
        PENDING_PAUSER_SLOT.setAddress(newPauser);
        emit PauserProposed(msg.sender, newPauser);
    }

    function acceptPauser() external {
        if (msg.sender != pendingPauser()) revert NotPendingPauser();
        _setPauser(msg.sender);
        PENDING_PAUSER_SLOT.setAddress(address(0));
    }

    function pause() external virtual onlyPauser {
        PAUSED_SLOT.setBool(true);
        emit Paused();
    }

    function unpause() external virtual onlyPauser {
        PAUSED_SLOT.setBool(false);
        emit Unpaused();
    }

    function pauser() public view returns (address value) {
        value = PAUSER_SLOT.getAddress();
    }

    function paused() public view returns (bool value) {
        value = PAUSED_SLOT.getBool();
    }

    function pendingPauser() public view returns (address value) {
        value = PENDING_PAUSER_SLOT.getAddress();
    }

    function _setPauser(address _pauser) internal {
        PAUSER_SLOT.setAddress(_pauser);
        emit PauserUpdated(_pauser);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library StorageSlot {
    function setUint256(bytes32 slot, uint256 value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function getUint256(bytes32 slot) internal view returns (uint256 value) {
        assembly {
            value := sload(slot)
        }
    }

    function setAddress(bytes32 slot, address value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function getAddress(bytes32 slot) internal view returns (address value) {
        assembly {
            value := sload(slot)
        }
    }

    function setBool(bytes32 slot, bool value) internal {
        assembly {
            sstore(slot, value)
        }
    }

    function getBool(bytes32 slot) internal view returns (bool value) {
        assembly {
            value := sload(slot)
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Upgradable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradables/Upgradable.sol";
import {ISquidFeeCollector} from "../interfaces/ISquidFeeCollector.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SquidFeeCollector is ISquidFeeCollector, Upgradable {
    bytes32 private constant BALANCES_PREFIX = keccak256("SquidFeeCollector.balances");
    bytes32 private constant SPECIFIC_FEES_PREFIX = keccak256("SquidFeeCollector.specificFees");
    address public immutable squidTeam;
    // Value expected with 2 decimals
    /// eg. 825 is 8.25%
    uint256 public immutable squidDefaultFee;

    error ZeroAddressProvided();

    constructor(address _squidTeam, uint256 _squidDefaultFee) {
        if (_squidTeam == address(0)) revert ZeroAddressProvided();

        squidTeam = _squidTeam;
        squidDefaultFee = _squidDefaultFee;
    }

    /// @param integratorFee Value expected with 2 decimals
    /// eg. 825 is 8.25%
    function collectFee(address token, uint256 amountToTax, address integratorAddress, uint256 integratorFee) external {
        if (integratorFee > 1000) revert ExcessiveIntegratorFee();

        uint256 specificFee = getSpecificFee(integratorAddress);
        uint256 squidFee = specificFee == 0 ? squidDefaultFee : specificFee;

        uint256 baseFeeAmount = (amountToTax * integratorFee) / 10000;
        uint256 squidFeeAmount = (baseFeeAmount * squidFee) / 10000;
        uint256 integratorFeeAmount = baseFeeAmount - squidFeeAmount;

        _safeTransferFrom(token, msg.sender, baseFeeAmount);
        _setBalance(token, squidTeam, getBalance(token, squidTeam) + squidFeeAmount);
        _setBalance(token, integratorAddress, getBalance(token, integratorAddress) + integratorFeeAmount);

        emit FeeCollected(token, integratorAddress, squidFeeAmount, integratorFeeAmount);
    }

    function withdrawFee(address token) external {
        uint256 balance = getBalance(token, msg.sender);
        _setBalance(token, msg.sender, 0);
        _safeTransfer(token, msg.sender, balance);

        emit FeeWithdrawn(token, msg.sender, balance);
    }

    function setSpecificFee(address integrator, uint256 fee) external onlyOwner {
        bytes32 slot = _computeSpecificFeeSlot(integrator);
        assembly {
            sstore(slot, fee)
        }
    }

    function getBalance(address token, address account) public view returns (uint256 value) {
        bytes32 slot = _computeBalanceSlot(token, account);
        assembly {
            value := sload(slot)
        }
    }

    function getSpecificFee(address integrator) public view returns (uint256 value) {
        bytes32 slot = _computeSpecificFeeSlot(integrator);
        assembly {
            value := sload(slot)
        }
    }

    function contractId() external pure returns (bytes32 id) {
        id = keccak256("squid-fee-collector");
    }

    function _setBalance(address token, address account, uint256 amount) private {
        bytes32 slot = _computeBalanceSlot(token, account);
        assembly {
            sstore(slot, amount)
        }
    }

    function _computeBalanceSlot(address token, address account) private pure returns (bytes32 slot) {
        slot = keccak256(abi.encodePacked(BALANCES_PREFIX, token, account));
    }

    function _computeSpecificFeeSlot(address integrator) private pure returns (bytes32 slot) {
        slot = keccak256(abi.encodePacked(SPECIFIC_FEES_PREFIX, integrator));
    }

    function _safeTransferFrom(address token, address from, uint256 amount) internal {
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(this), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
        if (!transferred || token.code.length == 0) revert TransferFailed();
    }

    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
        if (!transferred || token.code.length == 0) revert TransferFailed();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Proxy} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradables/Proxy.sol";

contract SquidFeeCollectorProxy is Proxy {
    function contractId() internal pure override returns (bytes32 id) {
        id = keccak256("squid-fee-collector");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ISquidMulticall} from "../interfaces/ISquidMulticall.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract SquidMulticall is ISquidMulticall, IERC721Receiver, IERC1155Receiver {
    bytes4 private constant ERC165_INTERFACE_ID = 0x01ffc9a7;
    bytes4 private constant ERC721_TOKENRECEIVER_INTERFACE_ID = 0x150b7a02;
    bytes4 private constant ERC1155_TOKENRECEIVER_INTERFACE_ID = 0x4e2312e0;

    bool private isRunning;

    error TransferFailed();

    function run(Call[] calldata calls) external payable {
        // Prevents reentrancy
        if (isRunning) revert AlreadyRunning();
        isRunning = true;

        for (uint256 i = 0; i < calls.length; i++) {
            Call memory call = calls[i];

            if (call.callType == CallType.FullTokenBalance) {
                (address token, uint256 amountParameterPosition) = abi.decode(call.payload, (address, uint256));
                uint256 amount = IERC20(token).balanceOf(address(this));
                _setCallDataParameter(call.callData, amountParameterPosition, amount);
            } else if (call.callType == CallType.FullNativeBalance) {
                call.value = address(this).balance;
            } else if (call.callType == CallType.CollectTokenBalance) {
                address token = abi.decode(call.payload, (address));
                _safeTransferFrom(token, msg.sender, IERC20(token).balanceOf(msg.sender));
                continue;
            }

            (bool success, bytes memory data) = call.target.call{value: call.value}(call.callData);
            if (!success) revert CallFailed(i, data);
        }

        isRunning = false;
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return
            interfaceId == ERC1155_TOKENRECEIVER_INTERFACE_ID ||
            interfaceId == ERC721_TOKENRECEIVER_INTERFACE_ID ||
            interfaceId == ERC165_INTERFACE_ID;
    }

    function _safeTransferFrom(address token, address from, uint256 amount) private {
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, address(this), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
        if (!transferred || token.code.length == 0) revert TransferFailed();
    }

    function _setCallDataParameter(bytes memory callData, uint256 parameterPosition, uint256 value) private pure {
        assembly {
            // 36 bytes shift because 32 for prefix + 4 for selector
            mstore(add(callData, add(36, mul(parameterPosition, 32))), value)
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    // Required to enable ETH reception with .transfer or .send
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ISquidRouter} from "../interfaces/ISquidRouter.sol";
import {ISquidMulticall} from "../interfaces/ISquidMulticall.sol";
import {AxelarForecallable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/executables/AxelarForecallable.sol";
import {IAxelarGasService} from "@axelar-network/axelar-cgp-solidity/contracts/interfaces/IAxelarGasService.sol";
import {IAxelarGateway} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/interfaces/IAxelarGateway.sol";
import {Upgradable} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradables/Upgradable.sol";
import {RoledPausable} from "../libraries/RoledPausable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract SquidRouter is ISquidRouter, AxelarForecallable, Upgradable, RoledPausable {
    IAxelarGasService private immutable gasService;
    IAxelarGasService private immutable forecallGasService;
    ISquidMulticall private immutable squidMulticall;

    constructor(
        address _gateway,
        address _gasService,
        address _forecallGasService,
        address _multicall
    ) AxelarForecallable(_gateway) {
        if (
            _gateway == address(0) ||
            _gasService == address(0) ||
            _forecallGasService == address(0) ||
            _multicall == address(0)
        ) revert ZeroAddressProvided();

        gasService = IAxelarGasService(_gasService);
        forecallGasService = IAxelarGasService(_forecallGasService);
        squidMulticall = ISquidMulticall(_multicall);
    }

    function bridgeCall(
        string calldata bridgedTokenSymbol,
        uint256 amount,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) external payable whenNotPaused {
        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);

        _safeTransferFrom(bridgedTokenAddress, msg.sender, amount);
        _bridgeCall(
            bridgedTokenSymbol,
            bridgedTokenAddress,
            destinationChain,
            destinationAddress,
            payload,
            gasRefundRecipient,
            enableExpress
        );
    }

    function callBridge(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external payable whenNotPaused {
        fundAndRunMulticall(token, amount, calls);

        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        uint256 bridgedTokenAmount = IERC20(bridgedTokenAddress).balanceOf(address(this));

        _approve(bridgedTokenAddress, address(gateway), bridgedTokenAmount);
        gateway.sendToken(destinationChain, destinationAddress, bridgedTokenSymbol, bridgedTokenAmount);
    }

    function callBridgeCall(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] calldata calls,
        string calldata bridgedTokenSymbol,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) external payable whenNotPaused {
        fundAndRunMulticall(token, amount, calls);

        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);

        _bridgeCall(
            bridgedTokenSymbol,
            bridgedTokenAddress,
            destinationChain,
            destinationAddress,
            payload,
            gasRefundRecipient,
            enableExpress
        );
    }

    function contractId() external pure override returns (bytes32 id) {
        id = keccak256("squid-router");
    }

    function fundAndRunMulticall(
        address token,
        uint256 amount,
        ISquidMulticall.Call[] memory calls
    ) public payable whenNotPaused {
        uint256 valueToSend;

        if (token == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            valueToSend = amount;
        } else {
            _transferTokenToMulticall(token, amount);
        }

        squidMulticall.run{value: valueToSend}(calls);
    }

    function _executeWithToken(
        string calldata,
        string calldata,
        bytes calldata payload,
        string calldata bridgedTokenSymbol,
        uint256
    ) internal override {
        (ISquidMulticall.Call[] memory calls, address refundRecipient) = abi.decode(
            payload,
            (ISquidMulticall.Call[], address)
        );

        address bridgedTokenAddress = gateway.tokenAddresses(bridgedTokenSymbol);
        uint256 contractBalance = IERC20(bridgedTokenAddress).balanceOf(address(this));

        _approve(bridgedTokenAddress, address(squidMulticall), contractBalance);

        try squidMulticall.run(calls) {
            emit CrossMulticallExecuted(keccak256(payload));
        } catch (bytes memory reason) {
            // Refund tokens to refund recipient if swap fails
            _safeTransfer(bridgedTokenAddress, refundRecipient, contractBalance);
            emit CrossMulticallFailed(keccak256(payload), reason, refundRecipient);
        }
    }

    function _bridgeCall(
        string calldata bridgedTokenSymbol,
        address bridgedTokenAddress,
        string calldata destinationChain,
        string calldata destinationAddress,
        bytes calldata payload,
        address gasRefundRecipient,
        bool enableExpress
    ) private {
        uint256 bridgedTokenBalance = IERC20(bridgedTokenAddress).balanceOf(address(this));

        if (address(this).balance > 0) {
            IAxelarGasService executionService = enableExpress ? forecallGasService : gasService;
            executionService.payNativeGasForContractCallWithToken{value: address(this).balance}(
                address(this),
                destinationChain,
                destinationAddress,
                payload,
                bridgedTokenSymbol,
                bridgedTokenBalance,
                gasRefundRecipient
            );
        }

        _approve(bridgedTokenAddress, address(gateway), bridgedTokenBalance);
        gateway.callContractWithToken(
            destinationChain,
            destinationAddress,
            payload,
            bridgedTokenSymbol,
            bridgedTokenBalance
        );
    }

    function _approve(address token, address spender, uint256 amount) private {
        uint256 allowance = IERC20(token).allowance(address(this), spender);
        if (allowance < amount) {
            if (allowance > 0) {
                _approveCall(token, spender, 0);
            }
            _approveCall(token, spender, type(uint256).max);
        }
    }

    function _approveCall(address token, address spender, uint256 amount) private {
        // Unlimited approval is not security issue since the contract doesn't store tokens
        (bool success, ) = token.call(abi.encodeWithSelector(IERC20.approve.selector, spender, amount));
        if (!success) revert ApprovalFailed();
    }

    function _transferTokenToMulticall(address token, uint256 amount) private {
        (bool success, bytes memory returnData) = token.call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, msg.sender, address(squidMulticall), amount)
        );
        bool transferred = success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
        if (!transferred || token.code.length == 0) revert TransferFailed();
    }

    function _setup(bytes calldata data) internal override {
        address _pauser = abi.decode(data, (address));
        if (_pauser == address(0)) revert ZeroAddressProvided();
        _setPauser(_pauser);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Proxy} from "@axelar-network/axelar-gmp-sdk-solidity/contracts/upgradables/Proxy.sol";

contract SquidRouterProxy is Proxy {
    function contractId() internal pure override returns (bytes32 id) {
        id = keccak256("squid-router");
    }
}