// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

import "./IERC20.sol";

interface IBentoBoxV1 {
    function toAmount(
        address _token,
        uint256 _share,
        bool _roundUp
    ) external view returns (uint256);

    function withdraw(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);

    function deposit(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);

    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) external payable returns (address cloneAddress);

    function setMasterContractApproval(
        address user,
        address masterContract,
        bool approved,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function balanceOf(IERC20, address) external view returns (uint256);

    function totals(IERC20) external view returns (uint128 elastic, uint128 base);

    function flashLoan(
        address borrower,
        address receiver,
        IERC20 token,
        uint256 amount,
        bytes calldata data
    ) external;

    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;

import "./IERC20.sol";

interface ISwapperGeneric {
    /// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to BentoBox.
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) external returns (uint256 extraShare, uint256 shareReturned);

    /// @notice Calculates the amount of token 'from' needed to complete the swap (amountFrom),
    /// this should be less than or equal to amountFromMax.
    /// Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for exactly 'exactAmountTo' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Transfers allocated, but unused 'from' tokens within the BentoBox to 'refundTo' (amountFromMax - amountFrom).
    /// Returns the amount of 'from' tokens withdrawn from BentoBox (amountFrom).
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) external returns (uint256 shareUsed, uint256 shareReturned);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.12;

interface IPlatypusRouter01 {
    function swapTokensForTokens(
        address[] calldata tokenPath,
        address[] calldata poolPath,
        uint256 fromAmount,
        uint256 minimumToAmount,
        address to,
        uint256 deadline
    ) external returns (uint256 amountOut, uint256 haircut);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.6.12;

interface IStargatePool {
    function totalLiquidity() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint256);

    function localDecimals() external view returns (uint256);

    function token() external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
// solhint-disable contract-name-camelcase

pragma solidity >=0.7.6;
pragma abicoder v2;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "../../interfaces/ISwapperGeneric.sol";
import "../../interfaces/IBentoBoxV1.sol";
import "../../interfaces/IERC20.sol";
import "../../interfaces/platypus/IPlatypusRouter01.sol";
import "../../interfaces/stargate/IStargateRouter.sol";
import "../../interfaces/stargate/IStargatePool.sol";

/// @notice Liquidation Swapper for Stargate LP using Platypus
contract StargatePlatypusSwapper is ISwapperGeneric {
    IBentoBoxV1 public immutable degenBox;
    IStargatePool public immutable pool;
    IStargateRouter public immutable stargateRouter;
    IPlatypusRouter01 public immutable platypusRouter;
    uint16 public immutable poolId;

    address[] public tokenPath;
    address[] public poolPath;

    /// @dev _tokenPath[0] must be Stargate Pool Underlying Token and last one MIM
    constructor(
        IBentoBoxV1 _degenBox,
        IStargatePool _pool,
        uint16 _poolId,
        IStargateRouter _stargateRouter,
        IPlatypusRouter01 _platypusRouter,
        address[] memory _tokenPath,
        address[] memory _poolPath
    ) {
        degenBox = _degenBox;
        pool = _pool;
        poolId = _poolId;
        stargateRouter = _stargateRouter;
        platypusRouter = _platypusRouter;

        for (uint256 i = 0; i < _tokenPath.length; i++) {
            tokenPath.push(_tokenPath[i]);
        }
        for (uint256 i = 0; i < _poolPath.length; i++) {
            poolPath.push(_poolPath[i]);
        }

        IERC20(_tokenPath[0]).approve(address(_platypusRouter), type(uint256).max);
    }

    /// @inheritdoc ISwapperGeneric
    function swap(
        IERC20,
        IERC20,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        degenBox.withdraw(IERC20(address(pool)), address(this), address(this), 0, shareFrom);

        // use the full balance so it's easier to check if everything has been redeemed.
        uint256 amount = IERC20(address(pool)).balanceOf(address(this));

        // Stargate Pool LP -> Underlying Token
        stargateRouter.instantRedeemLocal(poolId, amount, address(this));
        require(IERC20(address(pool)).balanceOf(address(this)) == 0, "Cannot fully redeem");

        amount = IERC20(address(tokenPath[0])).balanceOf(address(this));

        // Stargate Pool Underlying Token -> MIM
        (amount, ) = platypusRouter.swapTokensForTokens(tokenPath, poolPath, amount, 0, address(degenBox), type(uint256).max);

        (, shareReturned) = degenBox.deposit(IERC20(tokenPath[tokenPath.length - 1]), address(degenBox), recipient, amount, 0);
        extraShare = shareReturned - shareToMin;
    }

    /// @inheritdoc ISwapperGeneric
    function swapExact(
        IERC20,
        IERC20,
        address,
        address,
        uint256,
        uint256
    ) public pure override returns (uint256 shareUsed, uint256 shareReturned) {
        return (0, 0);
    }
}