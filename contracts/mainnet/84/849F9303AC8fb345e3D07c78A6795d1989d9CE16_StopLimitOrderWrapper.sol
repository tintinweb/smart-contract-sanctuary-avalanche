//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "../interfaces/IStopLimitOrder.sol";
import "../interfaces/IBentoBoxV1.sol";

contract StopLimitOrderWrapper{
    IBentoBoxV1 public immutable bentoBox;
    address payable public immutable registry;
    address public immutable gasFeeForwarder;
    IStopLimitOrder public immutable stopLimitOrderContract;
    address public immutable WETH;

    constructor(
        address payable registry_,
        address gasFeeForwarder_,
        address bentoBox_,
        address stopLimitOrderContract_,
        address WETH_
    ) {
        require(registry_ != address(0), "Invalid registry");
        require(gasFeeForwarder_ != address(0), "Invalid gasForwarder");
        require(bentoBox_ != address(0), "Invalid BentoBox");
        require(stopLimitOrderContract_ != address(0), "Invalid stopLimitOrder");
        require(WETH_ != address(0), "Invalid WETH");

        registry = registry_;
        gasFeeForwarder = gasFeeForwarder_;
        bentoBox = IBentoBoxV1(bentoBox_);

        stopLimitOrderContract = IStopLimitOrder(stopLimitOrderContract_);
        WETH = WETH_;
    }

    function fillOrder(
        uint256 feeAmount,
        OrderArgs memory order,
        address tokenIn,
        address tokenOut, 
        address receiver, 
        bytes calldata data
    ) external gasFeeForwarderVerified {
        stopLimitOrderContract.fillOrder(
            order,
            tokenIn,
            tokenOut,
            receiver,
            data
        );

        uint256 _feeReceivedAsShare = bentoBox.balanceOf(WETH, address(this));
        uint256 _feeReceivedAmount = bentoBox.toAmount(WETH, _feeReceivedAsShare, false);
        require(_feeReceivedAmount >= feeAmount, "Invalid Fee");

        bentoBox.withdraw(
            address(0), // USE_ETHEREUM
            address(this),
            registry,   // transfer to registry
            0,
            _feeReceivedAsShare
        );
    }

    modifier gasFeeForwarderVerified() {
        require(msg.sender == gasFeeForwarder, "StopLimitOrderWrapper: no gasFF");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IChainLinkPriceOracle.sol";

struct OrderArgs {
    address maker; 
    uint256 amountIn; 
    uint256 amountOut; 
    address recipient; 
    uint256 startTime;
    uint256 endTime;
    uint256 stopPrice;
    IChainLinkPriceOracle oracleAddress;
    bytes oracleData;
    uint256 amountToFill;
    uint8 v; 
    bytes32 r;
    bytes32 s;
}
interface IStopLimitOrder {
    function fillOrder(
            OrderArgs memory order,
            address tokenIn,
            address tokenOut, 
            address receiver, 
            bytes calldata data) 
    external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.6;

interface IBentoBoxV1 {
    struct Rebase {
        uint128 elastic;
        uint128 base;
    }

    function balanceOf(address, address) external view returns (uint256);

    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function totals(address) external view returns (Rebase memory totals_);

    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChainLinkPriceOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}