/**
 *Submitted for verification at snowtrace.io on 2022-08-03
*/

pragma solidity 0.8.14;

contract TraderJoeRouterAccessControl {
    address public safeAddress;
    address public safeModule;

    bytes32 private _checkedRole;
    uint256 private _checkedValue;

    constructor(address _safeAddress, address _safeModule) {
        require(_safeAddress != address(0), "invalid safe address");
        require(_safeModule != address(0), "invalid module address");
        safeAddress = _safeAddress;
        safeModule = _safeModule;
    }

    modifier onlySelf() {
        // 下方的 ACL mAVAXods 只可以内部调用
        require(address(this) == msg.sender, "Caller is not inner");
        _;
    }

    modifier onlyModule() {
        // 只有 Cobo Safe Module 才可以调用 check 方法
        require(safeModule == msg.sender, "Caller is not the module");
        _;
    }

    fallback() external {
        // 出于安全考虑，当调用到本合约中没有出现的 ACL MAVAXod 都会被拒绝
        revert("Unauthorized access");
    }

    function check(
        bytes32 _role,
        uint256 _value,
        bytes calldata data
    ) external onlyModule returns (bool) {
        // 记录下当前 Member 的 Role
        _checkedRole = _role;
        // 记录下当前 Transaction 的 value
        _checkedValue = _value;
        // 调用 ACL mAVAXods
        (bool success, ) = address(this).staticcall(data);
        return success;
    }

    function onlySafeAddress(address to) internal view {
        require(to == safeAddress, "to is not allowed");
    }

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

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
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external view onlySelf {
        onlySafeAddress(to);
    }
}