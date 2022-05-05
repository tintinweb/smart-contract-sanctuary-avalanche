//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IUniswapRouter.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import "./GatewayCaller.sol";

contract SwapBridge {
    IWETH wrappedToken;
    GatewayCaller gatewayCaller;

    constructor(address _wrappedTokenAddress, address _gatewayCaller) {
        wrappedToken = IWETH(_wrappedTokenAddress);
        gatewayCaller = GatewayCaller(_gatewayCaller);
    }

    function wrapThenBridge(
        address gatewayCallerAddress,
        uint256 gasAmount,
        string memory destinationChain,
        string memory destinationContractAddress,
        bytes memory payload,
        address refundAddress
    ) external payable {
        // Deduct gas amount from total sent amount. The remaining amount will be wrapped.
        uint256 wrapAmount = msg.value - gasAmount;

        // Wrap native token
        wrappedToken.deposit{value: wrapAmount}();

        // Approve wrapped native token to the gateway caller contract
        _approve(address(wrappedToken), gatewayCallerAddress, wrapAmount);

        // Bridge wrapped native token to the gateway caller contract
        gatewayCaller.payGasAndCallContractWithToken{value: msg.value}(
            destinationChain,
            destinationContractAddress,
            payload,
            wrappedToken.symbol(),
            wrapAmount,
            refundAddress
        );
    }

    function swapThenBridge(
        address routerAddress,
        uint256 amountIn,
        uint256 amountOutMin,
        address[] memory swapPath,
        string memory destinationChain,
        string memory destinationContractAddress,
        bytes memory payload,
        address refundAddress
    ) external payable {
        // Transfer given token to this contract.
        IERC20(swapPath[0]).transferFrom(msg.sender, address(this), amountIn);

        // Approve token to router before swap
        _approve(swapPath[0], routerAddress, amountIn);

        // Swap by using the given router contract.
        IUniswapRouter router = IUniswapRouter(routerAddress);
        uint256[] memory amountOuts = router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            swapPath,
            address(this),
            block.timestamp
        );

        // Approve an output token to the gateway caller contract
        uint256 sendAmount = amountOuts[amountOuts.length - 1];
        _approve(
            swapPath[swapPath.length - 1],
            address(gatewayCaller),
            sendAmount
        );

        // Send an output token to the AxelarGateway contract
        gatewayCaller.payGasAndCallContractWithToken{value: msg.value}(
            destinationChain,
            destinationContractAddress,
            payload,
            IERC20(swapPath[swapPath.length - 1]).symbol(),
            sendAmount,
            refundAddress
        );
    }

    function _approve(
        address tokenAddress,
        address spender,
        uint256 requiredAmount
    ) private {
        (bool approveSuccessful, ) = address(tokenAddress).call(
            abi.encodeWithSignature(
                "approve(address,uint256)",
                spender,
                requiredAmount
            )
        );
        require(approveSuccessful, "Fail to approve");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IUniswapRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
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

pragma solidity 0.8.9;

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

    function symbol() external view returns (string memory);

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

pragma solidity ^0.8.9;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;

    function symbol() external view returns (string memory);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IAxelarGateway.sol";
import "./interfaces/IAxelarGasReceiver.sol";
import "./interfaces/IERC20.sol";

contract GatewayCaller {
    IAxelarGateway gateway;
    IAxelarGasReceiver gasReceiver;

    constructor(address _gateway, address _gasReceiver) {
        gateway = IAxelarGateway(_gateway);
        gasReceiver = IAxelarGasReceiver(_gasReceiver);
    }

    function payGasAndCallContract(
        string memory destinationChain,
        string memory destinationAddress,
        bytes calldata payload,
        address refundAddress
    ) external payable {
        gasReceiver.payNativeGasForContractCall{value: msg.value}(
            msg.sender,
            destinationChain,
            destinationAddress,
            payload,
            refundAddress
        );
        gateway.callContract(destinationChain, destinationAddress, payload);
    }

    function payGasAndCallContractWithToken(
        string memory destinationChain,
        string memory destinationAddress,
        bytes calldata payload,
        string memory symbol,
        uint256 amount,
        address refundAddress
    ) external payable {
        address tokenAddress = gateway.tokenAddresses(symbol);
        IERC20(tokenAddress).transferFrom(msg.sender, address(this), amount);
        IERC20(tokenAddress).approve(address(gateway), amount);
        gasReceiver.payNativeGasForContractCallWithToken{value: msg.value}(
            msg.sender,
            destinationChain,
            destinationAddress,
            payload,
            symbol,
            amount,
            refundAddress
        );
        gateway.callContractWithToken(
            destinationChain,
            destinationAddress,
            payload,
            symbol,
            amount
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IAxelarGateway {
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
        bytes32 indexed payloadHash
    );

    event ContractCallApprovedWithMint(
        bytes32 indexed commandId,
        string sourceChain,
        string sourceAddress,
        address indexed contractAddress,
        bytes32 indexed payloadHash,
        string symbol,
        uint256 amount
    );

    event TokenFrozen(string symbol);

    event TokenUnfrozen(string symbol);

    event AllTokensFrozen();

    event AllTokensUnfrozen();

    event AccountBlacklisted(address indexed account);

    event AccountWhitelisted(address indexed account);

    event Upgraded(address indexed implementation);

    /******************\
    |* Public Methods *|
    \******************/

    function sendToken(
        string memory destinationChain,
        string memory destinationAddress,
        string memory symbol,
        uint256 amount
    ) external;

    function callContract(
        string memory destinationChain,
        string memory contractAddress,
        bytes memory payload
    ) external;

    function callContractWithToken(
        string memory destinationChain,
        string memory contractAddress,
        bytes memory payload,
        string memory symbol,
        uint256 amount
    ) external;

    function validateContractCall(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        bytes32 payloadHash
    ) external returns (bool);

    function validateContractCallAndMint(
        bytes32 commandId,
        string memory sourceChain,
        string memory sourceAddress,
        bytes32 payloadHash,
        string memory symbol,
        uint256 amount
    ) external returns (bool);

    /***********\
    |* Getters *|
    \***********/

    function allTokensFrozen() external view returns (bool);

    function implementation() external view returns (address);

    function tokenAddresses(string memory symbol)
        external
        view
        returns (address);

    function tokenFrozen(string memory symbol) external view returns (bool);

    function isCommandExecuted(bytes32 commandId) external view returns (bool);

    /*******************\
    |* Admin Functions *|
    \*******************/

    function freezeToken(string memory symbol) external;

    function unfreezeToken(string memory symbol) external;

    function freezeAllTokens() external;

    function unfreezeAllTokens() external;

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

pragma solidity 0.8.9;

// This should be owned by the microservice that is paying for gas.
interface IAxelarGasReceiver {
    error NotOwner();
    error TransferFailed();
    error NothingReceived();
    error InvalidCodeHash();
    error SetupFailed();
    error NotProxy();

    event Upgraded(address indexed newImplementation);
    event OwnershipTransferred(address indexed newOwner);

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

    // Get current owner
    function owner() external view returns (address);

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

    function collectFees(address payable receiver, address[] calldata tokens)
        external;

    function setup(bytes calldata data) external;

    function upgrade(
        address newImplementation,
        bytes32 newImplementationCodeHash,
        bytes calldata params
    ) external;
}