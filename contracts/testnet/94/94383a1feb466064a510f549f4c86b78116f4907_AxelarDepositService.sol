/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-28
*/

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File contracts/interfaces/IUpgradable.sol
// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;


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

    function contractId() external view returns (bytes32);

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;

    function setup(bytes calldata data) external;
}


// File contracts/interfaces/IAxelarDepositService.sol


// This should be owned by the microservice that is paying for gas.
interface IAxelarDepositService is IUpgradable {
    error InvalidAddress();
    error InvalidSymbol();
    error NothingDeposited();
    error ApproveFailed();
    error WrapFailed();
    error UnwrapFailed();
    error TokenSendFailed();

    function depositAddressForSendToken(
        bytes32 salt,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata tokenSymbol
    ) external view returns (address);

    function depositAddressForSendNative(
        bytes32 salt,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external view returns (address);

    function depositAddressForWithdrawNative(bytes32 salt, address recipient) external view returns (address);

    function sendToken(
        bytes32 salt,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata tokenSymbol
    ) external;

    function sendNative(
        bytes32 salt,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external;

    function withdrawNative(bytes32 salt, address payable recipient) external;
}


// File contracts/interfaces/IAxelarGateway.sol


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
    error InvalidSetDailyMintLimitsParams();
    error ExceedDailyMintLimit(string symbol);

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

    event TokenDailyMintLimitUpdated(string symbol, uint256 limit);

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

    function tokenDailyMintLimit(string memory symbol) external view returns (uint256);

    function tokenDailyMintAmount(string memory symbol) external view returns (uint256);

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

    function setTokenDailyMintLimits(string[] calldata symbols, uint256[] calldata limits) external;

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


// File contracts/interfaces/IERC20.sol


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


// File contracts/interfaces/IWETH9.sol


// WETH9 specific interface
interface IWETH9 {
    function deposit() external payable;

    function withdraw(uint256 amount) external;
}


// File contracts/util/Upgradable.sol


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
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
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
        if (IUpgradable(newImplementation).contractId() != IUpgradable(this).contractId()) revert InvalidImplementation();
        if (newImplementationCodeHash != newImplementation.codehash) revert InvalidCodeHash();

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = newImplementation.delegatecall(abi.encodeWithSelector(this.setup.selector, params));

        if (!success) revert SetupFailed();

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


// File contracts/deposit-service/DepositReceiver.sol


contract DepositReceiver {
    error NotOwner();
    error NotContract();

    address internal _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) revert NotOwner();
        _;
    }

    function execute(
        address callee,
        uint256 value,
        bytes calldata data
    ) external onlyOwner returns (bool success, bytes memory returnData) {
        if (callee.code.length == 0) revert NotContract();

        // solhint-disable-next-line avoid-low-level-calls
        (success, returnData) = callee.call{ value: value }(data);
    }

    // NOTE: The gateway should always destroy the `DepositHandler` in the same runtime context that deploys it.
    function destroy(address etherDestination) external onlyOwner {
        selfdestruct(payable(etherDestination));
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}
}


// File contracts/deposit-service/AxelarDepositService.sol







// This should be owned by the microservice that is paying for gas.
contract AxelarDepositService is Upgradable, IAxelarDepositService {
    // keccak256('gateway-address')
    bytes32 internal constant _GATEWAY_SLOT = 0xf8e5d679403ca38329d1356aeb2f53b4e3a6e4b021834581c8be7443db16066f;
    // keccak256('wrapped-token-symbol')
    bytes32 internal constant _WRAPPED_TOKEN_SYMBOL_SLOT = 0x91d2f5305ae2a8f5b319f6c3a690eff002c3e572220774ba5f7e957f079e55df;

    bytes32 internal constant PREFIX_DEPOSIT_SEND_TOKEN = keccak256('deposit-send-token');
    bytes32 internal constant PREFIX_DEPOSIT_SEND_NATIVE = keccak256('deposit-send-native');
    bytes32 internal constant PREFIX_DEPOSIT_WITHDRAW_NATIVE = keccak256('deposit-withdraw-native');

    function depositAddressForSendToken(
        bytes32 salt,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata tokenSymbol
    ) external view returns (address) {
        return _depositAddress(keccak256(abi.encode(PREFIX_DEPOSIT_SEND_TOKEN, salt, destinationChain, destinationAddress, tokenSymbol)));
    }

    function depositAddressForSendNative(
        bytes32 salt,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external view returns (address) {
        return _depositAddress(keccak256(abi.encode(PREFIX_DEPOSIT_SEND_NATIVE, salt, destinationChain, destinationAddress)));
    }

    function depositAddressForWithdrawNative(bytes32 nonce, address recipient) external view returns (address) {
        return _depositAddress(keccak256(abi.encode(PREFIX_DEPOSIT_WITHDRAW_NATIVE, nonce, recipient)));
    }

    function sendToken(
        bytes32 salt,
        string calldata destinationChain,
        string calldata destinationAddress,
        string calldata tokenSymbol
    ) external {
        address gatewayAddress = gateway();
        address tokenAddress = IAxelarGateway(gatewayAddress).tokenAddresses(tokenSymbol);

        DepositReceiver depositReceiver = new DepositReceiver{
            salt: keccak256(abi.encode(PREFIX_DEPOSIT_SEND_TOKEN, salt, destinationChain, destinationAddress, tokenSymbol))
        }();

        uint256 amount = IERC20(tokenAddress).balanceOf(address(depositReceiver));

        if (amount == 0) revert NothingDeposited();

        if (!_execute(depositReceiver, tokenAddress, 0, abi.encodeWithSelector(IERC20.approve.selector, gatewayAddress, amount)))
            revert ApproveFailed();

        bytes memory sendPayload = abi.encodeWithSelector(
            IAxelarGateway.sendToken.selector,
            destinationChain,
            destinationAddress,
            tokenSymbol,
            amount
        );

        if (!_execute(depositReceiver, gatewayAddress, 0, sendPayload)) revert TokenSendFailed();

        // NOTE: `depositReceiver` must always be destroyed in the same runtime context that it is deployed.
        depositReceiver.destroy(address(this));
    }

    function sendNative(
        bytes32 salt,
        string calldata destinationChain,
        string calldata destinationAddress
    ) external {
        DepositReceiver depositReceiver = new DepositReceiver{
            salt: keccak256(abi.encode(PREFIX_DEPOSIT_SEND_NATIVE, salt, destinationChain, destinationAddress))
        }();

        uint256 amount = address(depositReceiver).balance;

        if (amount == 0) revert NothingDeposited();

        address gatewayAddress = gateway();
        string memory symbol = wrappedSymbol();
        address wrappedTokenAddress = IAxelarGateway(gatewayAddress).tokenAddresses(symbol);

        if (!_execute(depositReceiver, wrappedTokenAddress, amount, abi.encodeWithSelector(IWETH9.deposit.selector))) revert WrapFailed();

        if (!_execute(depositReceiver, wrappedTokenAddress, 0, abi.encodeWithSelector(IERC20.approve.selector, gatewayAddress, amount)))
            revert ApproveFailed();

        bytes memory sendPayload = abi.encodeWithSelector(
            IAxelarGateway.sendToken.selector,
            destinationChain,
            destinationAddress,
            symbol,
            amount
        );

        if (!_execute(depositReceiver, gatewayAddress, 0, sendPayload)) revert TokenSendFailed();

        // NOTE: `depositReceiver` must always be destroyed in the same runtime context that it is deployed.
        depositReceiver.destroy(address(this));
    }

    function withdrawNative(bytes32 salt, address payable recipient) external {
        address token = wrappedToken();

        DepositReceiver depositReceiver = new DepositReceiver{
            salt: keccak256(abi.encode(PREFIX_DEPOSIT_WITHDRAW_NATIVE, salt, recipient))
        }();
        uint256 amount = IERC20(token).balanceOf(address(depositReceiver));

        if (amount == 0) revert NothingDeposited();

        if (!_execute(depositReceiver, token, 0, abi.encodeWithSelector(IWETH9.withdraw.selector, amount))) revert UnwrapFailed();

        // NOTE: `depositReceiver` must always be destroyed in the same runtime context that it is deployed.
        depositReceiver.destroy(recipient);
    }

    function gateway() public view returns (address gatewayAddress) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            gatewayAddress := sload(_GATEWAY_SLOT)
        }
    }

    function wrappedToken() public view returns (address) {
        return IAxelarGateway(gateway()).tokenAddresses(wrappedSymbol());
    }

    function wrappedSymbol() public view returns (string memory symbol) {
        bytes32 symbolData;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            symbolData := sload(_WRAPPED_TOKEN_SYMBOL_SLOT)
        }

        // recovering string length as the last 2 bytes of the data
        uint256 length = 0xff & uint256(symbolData);

        // restoring the string with the correct length
        // solhint-disable-next-line no-inline-assembly
        assembly {
            symbol := mload(0x40)
            // new "memory end" including padding (the string isn't larger than 32 bytes)
            mstore(0x40, add(symbol, 0x40))
            // store length in memory
            mstore(symbol, length)
            // write actual data
            mstore(add(symbol, 0x20), symbolData)
        }
    }

    function _depositAddress(bytes32 create2Salt) internal view returns (address) {
        /* Convert a hash which is bytes32 to an address which is 20-byte long
        according to https://docs.soliditylang.org/en/v0.8.1/control-structures.html?highlight=create2#salted-contract-creations-create2 */
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                bytes1(0xff),
                                address(this),
                                create2Salt,
                                keccak256(abi.encodePacked(type(DepositReceiver).creationCode))
                            )
                        )
                    )
                )
            );
    }

    function _execute(
        DepositReceiver depositReceiver,
        address callee,
        uint256 nativeValue,
        bytes memory payload
    ) internal returns (bool) {
        (bool success, bytes memory returnData) = depositReceiver.execute(callee, nativeValue, payload);
        return success && (returnData.length == uint256(0) || abi.decode(returnData, (bool)));
    }

    function contractId() public pure returns (bytes32) {
        return keccak256('axelar-deposit-service');
    }

    function _setup(bytes calldata data) internal override {
        (address gatewayAddress, string memory symbol) = abi.decode(data, (address, string));

        if (gatewayAddress == address(0)) revert InvalidAddress();

        if (IAxelarGateway(gatewayAddress).tokenAddresses(symbol) == address(0)) revert InvalidSymbol();

        bytes memory symbolBytes = bytes(symbol);

        if (symbolBytes.length == 0 || symbolBytes.length > 30) revert InvalidSymbol();

        uint256 symbolNumber = uint256(bytes32(symbolBytes));

        // storing string length as last 2 bytes of the data
        symbolNumber |= 0xff & symbolBytes.length;
        bytes32 symbolData = bytes32(abi.encodePacked(symbolNumber));

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(_GATEWAY_SLOT, gatewayAddress)
            sstore(_WRAPPED_TOKEN_SYMBOL_SLOT, symbolData)
        }
    }
}