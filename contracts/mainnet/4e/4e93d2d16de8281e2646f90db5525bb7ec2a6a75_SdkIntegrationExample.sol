/**
 *Submitted for verification at snowtrace.io on 2023-06-29
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function approve(address, uint256) external;

    function transferFrom(address from, address to, uint256 amount) external;

    function decimals() external view returns (uint256);
}

interface IOpenflowSdk {
    struct Options {
        /// @dev Driver is responsible for authenticating quote selection.
        /// If no driver is set anyone with the signature will be allowed
        /// to execute the signed payload. Driver is user-configurable
        /// which means the end user does not have to trust Openflow driver
        /// multisig. If the user desires, the user can run their own
        /// decentralized multisig driver.
        address driver;
        /// @dev Oracle is responsible for determining minimum amount out for an order.
        /// If no oracle is provided the default Openflow oracle will be used.
        address oracle;
        /// @dev If true calls will revert if oracle is not able to find an appropriate price.
        bool requireOracle;
        /// @dev Acceptable slippage threshold denoted in BIPs.
        uint256 slippageBips;
        /// @dev Maximum duration for auction. The order is invalid after the auction ends.
        uint256 auctionDuration;
        /// @dev Manager is responsible for managing SDK options.
        address manager;
        /// @dev If true manager is allowed to perform swaps on behalf of the
        /// instance initiator (sender).
        bool managerCanSwap;
        /// @dev When a swap is executed, transfer funds from sender to Settlement
        /// via SDK instance. Sender must allow the SDK instance to spend fromToken
        address sender;
        /// @dev Funds will be sent to recipient after swap.
        address recipient;
    }

    function swap(
        address fromToken,
        address toToken
    ) external returns (bytes memory orderUid);

    function options() external view returns (Options memory options);

    function setOptions(Options memory options) external;

    function initialize(
        address settlement,
        address manager,
        address sender,
        address recipient
    ) external;

    function updateSdkVersion() external;

    function updateSdkVersion(uint256 version) external;
}

interface IOpenflowFactory {
    function newSdkInstance() external returns (IOpenflowSdk sdkInstance);

    function newSdkInstance(
        address manager
    ) external returns (IOpenflowSdk sdkInstance);

    function newSdkInstance(
        address manager,
        address sender,
        address recipient
    ) external returns (IOpenflowSdk sdkInstance);

    function implementationByVersion(
        uint256 version
    ) external view returns (address implementation);

    function currentVersion() external view returns (uint256 version);
}

contract SdkIntegrationExample {
    /// @notice Initialize SDK instance variable.
    IOpenflowSdk public sdk;
    address owner;

    /// @notice Create a new SDK instance.
    constructor(address _openflowFactory) {
        address sdkInstanceManager = address(this);
        sdk = IOpenflowFactory(_openflowFactory).newSdkInstance(
            sdkInstanceManager
        );
        owner = msg.sender;
    }

    /// @notice Execute a basic swap.
    /// @dev Note: This method has no auth. If your app needs auth make sure to add it.
    function swap(address fromToken, address toToken) external {
        require(msg.sender == owner, "Only owner");
        IERC20(fromToken).approve(address(sdk), type(uint256).max);
        sdk.swap(fromToken, toToken);
    }

    /// @notice Update SDK options.
    /// @dev For a full list of options see: https://github.com/openflow-fi/openflow-contracts/blob/main/src/interfaces/IOpenflow.sol#L5
    function updateOptions() external {
        require(msg.sender == owner, "Only owner");
        IOpenflowSdk.Options memory options = sdk.options(); // Load existing options
        options.auctionDuration = 60 * 5; // Set auction duration to 5 Minutes.
        options.slippageBips = 60; // Update slippage bips to 60.
        options.manager = msg.sender; // Set instance manager to msg.sender.
        options.managerCanSwap = true; // Allow manager to swap.
        sdk.setOptions(options); // Set options
    }
}