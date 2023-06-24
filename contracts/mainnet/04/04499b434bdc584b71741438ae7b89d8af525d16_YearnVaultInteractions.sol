// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;
import {IERC20} from "../../src/interfaces/IERC20.sol";
import {ISettlement} from "../../src/interfaces/ISettlement.sol";
import {IVault} from "../../test/interfaces/IVault.sol";
import {IVaultRegistry} from "../../test/interfaces/IVaultRegistry.sol";

/// @notice Sample contract to demonstrate usage of pre-swap and post-swap hooks
/// to allow users to zap in and out of vaults.
/// @dev Problem: If a user requests a swap between ERC20 tokenA and yvTokenA
/// only one or two solvers may support this type of swap innately (Portals supports this).
/// This is an issue because it's critically important for solvers to be able to compete
/// for the best swap rate regardless of token wrapping.
/// @dev Solution: By allowing users to specify pre-swap and post-swap hooks a user
/// can perform the token wrapping and unwrapping (deposit/withdraw) themselves which opens up
/// the actual underlying token swap to the complete pool of solvers vs a small subset of solvers.
/// This will result in the user getting access to a much larger pool of competitive swap rate quotes.
contract YearnVaultInteractions {
    IVaultRegistry public registry;
    address public settlement;
    address public executionProxy;

    constructor(address _settlement) {
        settlement = _settlement;
        executionProxy = ISettlement(settlement).executionProxy();
    }

    /// @notice Allow ont time initialization
    /// @param _registry Yearn vault registry address
    function initialize(address _registry) external {
        require(address(registry) == address(0), "Already initialized.");
        registry = IVaultRegistry(_registry);
    }

    /// @notice Deposit swapped tokens on behalf of a user (zap in)
    /// @dev Steps for zap in:
    /// - As per normal swap user approves the Settlement contract to spend their fromToken
    /// - During the initial payload generation user sets recipient to vault interactions (this contract)
    /// - A swap occurs and `toToken` is sent to this contract
    /// - In a user signed post-swap hook the user instructs the solver to call out to this contract
    /// and initiate a deposit where recipient is the user
    /// - This contract initiates a deposit on behalf of the user
    function deposit(address token, address recipient) external {
        require(msg.sender == executionProxy, "Only execution proxy");
        IVault vault = IVault(registry.latestVault(token));
        uint256 balance = IERC20(token).balanceOf(address(this));
        IERC20(token).approve(address(vault), type(uint256).max); // This contract should never hold tokens
        vault.deposit(balance, recipient);
    }

    /// @notice Withdraw from a vault before swapping (zap out)
    /// @dev Steps for zap out:
    /// - User approves vault interactions (this contract) to spend their yvToken
    /// - User constructs signed a pre-swap hook instructing the solver to call withdraw
    /// - Settlement authenticates payload.sender (signatory) as per normal swap flow
    /// - Pre-swap hook is called from execution proxy where authenticated signatory is
    /// appended to calldata
    /// - User's tokens are withdrawn and sent to Settlement
    /// - Settlement continues and performs the swap
    /// - Settlement makes sure the user receives the agreed upon `toToken` and `toAmount`
    function withdraw(address yvToken) external {
        require(msg.sender == executionProxy, "Only execution proxy");
        address signatory;
        assembly {
            signatory := shr(96, calldataload(sub(calldatasize(), 20)))
        }
        IVault vault = IVault(yvToken);
        uint256 amount = vault.balanceOf(signatory);
        vault.transferFrom(signatory, address(this), amount);
        vault.withdraw(type(uint256).max, address(settlement));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function approve(address, uint256) external;

    function transferFrom(address from, address to, uint256 amount) external;

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISettlement {
    enum Scheme {
        Eip712,
        EthSign,
        Eip1271,
        PreSign
    }

    struct Order {
        bytes signature;
        bytes multisigSignature;
        bytes data;
        Payload payload;
    }

    struct Payload {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        address sender;
        address recipient;
        uint32 validFrom;
        uint32 validTo;
        address driver;
        Scheme scheme;
    }

    struct Interaction {
        address target;
        bytes data;
        uint256 value;
    }

    struct Hooks {
        Interaction[] preHooks;
        Interaction[] postHooks;
    }

    struct Condition {
        address target;
        bytes data;
    }

    function checkNSignatures(
        address driver,
        bytes32 digest,
        bytes memory signatures,
        uint256 requiredSignatures
    ) external view;

    function executeOrder(Order memory) external;

    function buildDigest(Payload memory) external view returns (bytes32 digest);

    function recoverSigner(
        Scheme scheme,
        bytes32 digest,
        bytes memory signature
    ) external view returns (address signatory);

    function executionProxy() external view returns (address executionProxy);

    function defaultDriver() external view returns (address driver);

    function defaultOracle() external view returns (address driver);

    function digestApproved(
        address signatory,
        bytes32 digest
    ) external view returns (bool approved);

    function submitOrder(
        ISettlement.Payload memory payload
    ) external returns (bytes memory orderUid);

    function invalidateOrder(bytes memory orderUid) external;

    function invalidateAllOrders() external;
}

interface ISolver {
    function hook(bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IVault {
    function deposit(uint256 amount, address recipient) external;

    function withdraw(uint256 amount, address recipient) external;

    function token() external view returns (address token);

    function balanceOf(address user) external view returns (uint256 amount);

    function approve(address spender, uint256 amount) external;

    function pricePerShare() external view returns (uint256 pricePerShare);

    function transferFrom(
        address owner,
        address recipient,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IVaultRegistry {
    function latestVault(address token) external view returns (address vault);
}