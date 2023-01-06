/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-05
*/

// Sources flattened with hardhat v2.12.3 https://hardhat.org

// File contracts/IPangolinRouter.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

interface IPangolinRouter {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    )
        external
        payable
        returns (uint amountToken, uint amountAVAX, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactAVAXForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactAVAX(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForAVAX(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapAVAXForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File @openzeppelin/contracts/utils/[email protected]

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

// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File hardhat/[email protected]


pragma solidity >=0.4.22 <0.9.0;

library console {
    address constant CONSOLE_ADDRESS =
        address(0x000000000000000000636F6e736F6c652e6c6f67);

    function _sendLogPayload(bytes memory payload) private view {
        uint256 payloadLength = payload.length;
        address consoleAddress = CONSOLE_ADDRESS;
        assembly {
            let payloadStart := add(payload, 32)
            let r := staticcall(
                gas(),
                consoleAddress,
                payloadStart,
                payloadLength,
                0,
                0
            )
        }
    }

    function log() internal view {
        _sendLogPayload(abi.encodeWithSignature("log()"));
    }

    function logInt(int256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
    }

    function logUint(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function logString(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function logBool(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function logAddress(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function logBytes(bytes memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
    }

    function logBytes1(bytes1 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
    }

    function logBytes2(bytes2 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
    }

    function logBytes3(bytes3 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
    }

    function logBytes4(bytes4 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
    }

    function logBytes5(bytes5 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
    }

    function logBytes6(bytes6 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
    }

    function logBytes7(bytes7 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
    }

    function logBytes8(bytes8 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
    }

    function logBytes9(bytes9 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
    }

    function logBytes10(bytes10 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
    }

    function logBytes11(bytes11 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
    }

    function logBytes12(bytes12 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
    }

    function logBytes13(bytes13 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
    }

    function logBytes14(bytes14 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
    }

    function logBytes15(bytes15 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
    }

    function logBytes16(bytes16 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
    }

    function logBytes17(bytes17 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
    }

    function logBytes18(bytes18 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
    }

    function logBytes19(bytes19 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
    }

    function logBytes20(bytes20 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
    }

    function logBytes21(bytes21 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
    }

    function logBytes22(bytes22 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
    }

    function logBytes23(bytes23 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
    }

    function logBytes24(bytes24 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
    }

    function logBytes25(bytes25 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
    }

    function logBytes26(bytes26 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
    }

    function logBytes27(bytes27 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
    }

    function logBytes28(bytes28 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
    }

    function logBytes29(bytes29 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
    }

    function logBytes30(bytes30 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
    }

    function logBytes31(bytes31 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
    }

    function logBytes32(bytes32 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
    }

    function log(uint256 p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
    }

    function log(string memory p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string)", p0));
    }

    function log(bool p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
    }

    function log(address p0) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address)", p0));
    }

    function log(uint256 p0, uint256 p1) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,uint256)", p0, p1)
        );
    }

    function log(uint256 p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
    }

    function log(uint256 p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
    }

    function log(uint256 p0, address p1) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,address)", p0, p1)
        );
    }

    function log(string memory p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
    }

    function log(string memory p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
    }

    function log(string memory p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
    }

    function log(string memory p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
    }

    function log(bool p0, uint256 p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
    }

    function log(bool p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
    }

    function log(bool p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
    }

    function log(bool p0, address p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
    }

    function log(address p0, uint256 p1) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint256)", p0, p1)
        );
    }

    function log(address p0, string memory p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
    }

    function log(address p0, bool p1) internal view {
        _sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
    }

    function log(address p0, address p1) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address)", p0, p1)
        );
    }

    function log(uint256 p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2)
        );
    }

    function log(uint256 p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2)
        );
    }

    function log(uint256 p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2)
        );
    }

    function log(uint256 p0, uint256 p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2)
        );
    }

    function log(uint256 p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2)
        );
    }

    function log(uint256 p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2)
        );
    }

    function log(uint256 p0, string memory p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2)
        );
    }

    function log(uint256 p0, string memory p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2)
        );
    }

    function log(uint256 p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2)
        );
    }

    function log(uint256 p0, bool p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2)
        );
    }

    function log(uint256 p0, bool p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2)
        );
    }

    function log(uint256 p0, bool p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2)
        );
    }

    function log(uint256 p0, address p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2)
        );
    }

    function log(uint256 p0, address p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2)
        );
    }

    function log(uint256 p0, address p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2)
        );
    }

    function log(uint256 p0, address p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2)
        );
    }

    function log(string memory p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2)
        );
    }

    function log(string memory p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2)
        );
    }

    function log(string memory p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2)
        );
    }

    function log(string memory p0, uint256 p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2)
        );
    }

    function log(string memory p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2)
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,string,string)", p0, p1, p2)
        );
    }

    function log(string memory p0, string memory p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2)
        );
    }

    function log(string memory p0, string memory p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,string,address)", p0, p1, p2)
        );
    }

    function log(string memory p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2)
        );
    }

    function log(string memory p0, bool p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2)
        );
    }

    function log(string memory p0, bool p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2)
        );
    }

    function log(string memory p0, bool p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2)
        );
    }

    function log(string memory p0, address p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2)
        );
    }

    function log(string memory p0, address p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,address,string)", p0, p1, p2)
        );
    }

    function log(string memory p0, address p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2)
        );
    }

    function log(string memory p0, address p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(string,address,address)", p0, p1, p2)
        );
    }

    function log(bool p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2)
        );
    }

    function log(bool p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2)
        );
    }

    function log(bool p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2)
        );
    }

    function log(bool p0, uint256 p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2)
        );
    }

    function log(bool p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2)
        );
    }

    function log(bool p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2)
        );
    }

    function log(bool p0, string memory p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2)
        );
    }

    function log(bool p0, string memory p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2)
        );
    }

    function log(bool p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2)
        );
    }

    function log(bool p0, bool p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2)
        );
    }

    function log(bool p0, bool p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2)
        );
    }

    function log(bool p0, bool p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2)
        );
    }

    function log(bool p0, address p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2)
        );
    }

    function log(bool p0, address p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2)
        );
    }

    function log(bool p0, address p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2)
        );
    }

    function log(bool p0, address p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2)
        );
    }

    function log(address p0, uint256 p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2)
        );
    }

    function log(address p0, uint256 p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2)
        );
    }

    function log(address p0, uint256 p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2)
        );
    }

    function log(address p0, uint256 p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2)
        );
    }

    function log(address p0, string memory p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2)
        );
    }

    function log(address p0, string memory p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,string,string)", p0, p1, p2)
        );
    }

    function log(address p0, string memory p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2)
        );
    }

    function log(address p0, string memory p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,string,address)", p0, p1, p2)
        );
    }

    function log(address p0, bool p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2)
        );
    }

    function log(address p0, bool p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2)
        );
    }

    function log(address p0, bool p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2)
        );
    }

    function log(address p0, bool p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2)
        );
    }

    function log(address p0, address p1, uint256 p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2)
        );
    }

    function log(address p0, address p1, string memory p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address,string)", p0, p1, p2)
        );
    }

    function log(address p0, address p1, bool p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2)
        );
    }

    function log(address p0, address p1, address p2) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(address,address,address)", p0, p1, p2)
        );
    }

    function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,uint256,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,string,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,bool,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        uint256 p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(uint256 p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(uint256,address,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        uint256 p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,uint256,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,string,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        bool p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,bool,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(string memory p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        string memory p0,
        address p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(string,address,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,uint256,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, string memory p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, string memory p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,string,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, string memory p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3)
        );
    }

    function log(bool p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, address p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,bool,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, string memory p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, bool p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        bool p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(bool p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(bool,address,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        uint256 p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, uint256 p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,uint256,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        uint256 p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, string memory p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        bool p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        string memory p1,
        address p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,string,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, string memory p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, bool p2, string memory p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        bool p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, bool p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,bool,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,uint256,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        uint256 p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,uint256,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, uint256 p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,uint256,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, uint256 p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,uint256,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        uint256 p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,string,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,string,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        bool p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,string,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        string memory p2,
        address p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,string,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, bool p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,bool,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        bool p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,bool,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, bool p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,bool,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, bool p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,bool,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, address p2, uint256 p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,address,uint256)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(
        address p0,
        address p1,
        address p2,
        string memory p3
    ) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,address,string)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, address p2, bool p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,address,bool)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }

    function log(address p0, address p1, address p2, address p3) internal view {
        _sendLogPayload(
            abi.encodeWithSignature(
                "log(address,address,address,address)",
                p0,
                p1,
                p2,
                p3
            )
        );
    }
}

// File @openzeppelin/contracts/security/[email protected]


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

// File @openzeppelin/contracts/utils/math/[email protected]


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File @openzeppelin/contracts/token/ERC20/[email protected]


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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File contracts/stormUSDC.sol

pragma solidity 0.8.17;

interface IStormRoyalty {
    function getFee() external view returns (uint256);
}

interface IShelter {
    function getUnderlyingAddress() external view returns (address);

    function mintWithBacking(
        uint256 numTokens,
        address recipient
    ) external returns (uint256);
}

contract StormUSDC is IERC20, ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    // token data
    string private constant _name = "Storm.Money USDC";
    string private constant _symbol = "stormUSDC";
    uint8 private constant _decimals = 18;
    uint256 private constant precision = 10 ** 18;

    // 1 initial supply
    uint256 private _totalSupply = 10 ** 18;

    // balances
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // address -> Fee Exemption
    mapping(address => bool) public isFeeExempt;

    // Token Activation
    bool public tokenActivated;

    // Dead Wallet
    address private constant DEAD = address(0xdead);

    //SHELTHER
    IShelter private shelter;

    // PangolinRouter
    IPangolinRouter private router;

    // Royalty Data Fetcher
    IStormRoyalty private stormRoyalty;

    // Holder list
    address[] public holders;
    mapping(address => uint256) holderIndex;
    mapping(address => uint256) public holderEntryTime;

    // Sell Down Exemptions
    mapping(address => bool) public sellDownExempt;

    // Fees
    uint256 public mintFee = 97000; // 3% mint fee
    uint256 public sellFee = 97000; // 3% redeem fee
    uint256 public transferFee = 97000; // 3% transfer fee
    uint256 public cashedOutFee = 96000; // 4% cashed out fee
    uint256 private constant feeDenominator = 10 ** 5;

    // Underlying Asset
    IERC20 public underlying;

    /* ========== INITIALIZER ========== */

    constructor(
        address _stormRoyalty,
        address[] memory _admins,
        address _pangolinRouter,
        address _underlying,
        address _shelter
    ) {
        stormRoyalty = IStormRoyalty(_stormRoyalty);
        router = IPangolinRouter(_pangolinRouter);
        underlying = IERC20(_underlying);
        shelter = IShelter(_shelter);

        // Fee Exempt Pangolin Router And Creator For Initial Distribution
        isFeeExempt[address(router)] = true;
        isFeeExempt[msg.sender] = true;

        for (uint256 i = 0; i < _admins.length; i++) {
            sellDownExempt[_admins[i]] = true;
            isFeeExempt[_admins[i]] = true;
        }

        // allocate initial 1 token
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    /** Returns the total number of tokens in existence */
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    /** Returns the number of tokens owned by `account` */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /** Returns the number of tokens `spender` can transfer from `holder` */
    function allowance(
        address holder,
        address spender
    ) external view override returns (uint256) {
        return _allowances[holder][spender];
    }

    /** Token Name */
    function name() public pure returns (string memory) {
        return _name;
    }

    /** Token Ticker Symbol */
    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    /** Tokens decimals */
    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    /** Approves `spender` to transfer `amount` tokens from caller */
    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /** Transfer Function */
    function transfer(
        address recipient,
        uint256 amount
    ) external override nonReentrant returns (bool) {
        if (recipient == msg.sender) {
            _sell(msg.sender, amount, msg.sender, false);
            return true;
        } else {
            return _transferFrom(msg.sender, recipient, amount);
        }
    }

    /** Transfer Function */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override nonReentrant returns (bool) {
        _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(
            amount,
            "Insufficient Allowance"
        );
        return _transferFrom(sender, recipient, amount);
    }

    /** Internal Transfer */
    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        // make standard checks
        require(
            recipient != address(0) && sender != address(0),
            "Transfer To Zero"
        );
        require(amount > 0, "Transfer Amt Zero");

        if (_balances[recipient] == 0) {
            _addHolder(recipient);
        }

        // track price change
        uint256 oldPrice = _calculatePrice();
        // amount to give recipient
        uint256 tAmount = (isFeeExempt[sender] || isFeeExempt[recipient])
            ? amount
            : amount.mul(transferFee).div(feeDenominator);
        // tax taken from transfer
        uint256 tax = amount.sub(tAmount);
        // subtract from sender
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        // give reduced amount to receiver
        _balances[recipient] = _balances[recipient].add(tAmount);

        // burn the tax
        if (tax > 0) {
            // Take Fee
            _takeFee(tax);
            _totalSupply = _totalSupply.sub(tax);
            emit Transfer(sender, address(0), tax);
        }

        if (_balances[sender] == 0) {
            _removeHolder(sender);
        }

        // require price rises
        _requirePriceRises(oldPrice);
        // Transfer Event
        emit Transfer(sender, recipient, tAmount);
        return true;
    }

    /**
        Mint Tokens With The Native Token
        This will purchase Underlying with Native received
        It will then mint tokens to `recipient` based on the number of stable coins received
        `slippage` should be set to avoid the Transaction being front runned

        @param recipient Account to receive minted Tokens
        @param slippage slippage allowed
        @return received number of tokens received
     */
    function mintWithNative(
        address recipient,
        uint8 slippage
    ) external payable returns (uint256) {
        _checkGarbageCollector(address(this));
        _checkGarbageCollector(DEAD);
        return _mintWithNative(recipient, slippage, msg.value);
    }

    /** 
        Mint Tokens For `recipient` By Depositing Underlying Into The Contract
            Requirements:
                Approval from the Underlying prior to purchase
        
        @param numTokens number of Underlying tokens to mint with
        @param recipient Account to receive minted tokens
        @return tokensMinted number of tokens minted
    */
    function mintWithBacking(
        uint256 numTokens,
        address recipient
    ) external nonReentrant returns (uint256) {
        _checkGarbageCollector(address(this));
        _checkGarbageCollector(DEAD);
        return _mintWithBacking(numTokens, recipient);
    }

    /** 
        Burns Sender's Tokens and redeems their value in Underlying
        @param tokenAmount Number of Tokens To Redeem, Must be greater than 0
    */
    function sell(uint256 tokenAmount) external nonReentrant returns (uint256) {
        return _sell(msg.sender, tokenAmount, msg.sender, false);
    }

    /** 
        Burns Sender's Tokens and redeems their value in Underlying for `recipient`
        @param tokenAmount Number of Tokens To Redeem, Must be greater than 0
        @param recipient Recipient Of Underlying transfer, Must not be address(0)
    */
    function sell(
        uint256 tokenAmount,
        address recipient
    ) external nonReentrant returns (uint256) {
        return _sell(msg.sender, tokenAmount, recipient, false);
    }

    /** 
        Allows A User To Erase Their Holdings From Supply 
        DOES NOT REDEEM UNDERLYING ASSET FOR USER
        @param amount Number of Tokens To Burn
    */
    function burn(uint256 amount) external nonReentrant {
        // get balance of caller
        uint256 bal = _balances[msg.sender];
        require(bal >= amount && bal > 0, "Zero Holdings");
        // Track Change In Price
        uint256 oldPrice = _calculatePrice();
        // take fee
        _takeFee(amount);
        // burn tokens from sender + supply
        _burn(msg.sender, amount);
        // require price rises
        _requirePriceRises(oldPrice);
        // Emit Call
        emit Burn(msg.sender, amount);
    }

    ///////////////////////////////////
    //////  INTERNAL FUNCTIONS  ///////
    ///////////////////////////////////

    /** Purchases Token and Deposits Them in Recipient's Address */
    function _mintWithNative(
        address recipient,
        uint8 slippage,
        uint256 nativeAmount
    ) internal nonReentrant returns (uint256) {
        require(msg.value > 0, "Zero Value");
        require(recipient != address(0), "Zero Address");
        require(tokenActivated || msg.sender == owner(), "Token Not Activated");

        // calculate price change
        uint256 oldPrice = _calculatePrice();

        // previous backing
        uint256 previousBacking = underlying.balanceOf(address(this));
        // swap Native for Underlying
        uint256 received = _purchaseUnderlyingWithNative(
            slippage,
            nativeAmount
        );
        // if this is the first purchase, use new amount
        uint256 relevantBacking = previousBacking == 0
            ? underlying.balanceOf(address(this))
            : previousBacking;

        // mint to recipient
        return _mintTo(recipient, received, relevantBacking, oldPrice);
    }

    /** Stake Underlying and Deposits tokens in Sender's Address, Must Have Prior Approval For Underlying */
    function _mintWithBacking(
        uint256 numUnderlying,
        address recipient
    ) internal returns (uint256) {
        require(tokenActivated || msg.sender == owner(), "Token Not Activated");
        // users token balance
        uint256 userTokenBalance = underlying.balanceOf(msg.sender);

        // ensure user has enough to send
        require(
            userTokenBalance > 0 && numUnderlying <= userTokenBalance,
            "Insufficient Balance"
        );

        // calculate price change
        uint256 oldPrice = _calculatePrice();

        // previous backing
        uint256 previousBacking = underlying.balanceOf(address(this));

        // transfer in token
        uint256 received = _transferIn(address(underlying), numUnderlying);

        // if this is the first purchase, use new amount
        uint256 relevantBacking = previousBacking == 0
            ? underlying.balanceOf(address(this))
            : previousBacking;

        // Handle Minting
        return _mintTo(recipient, received, relevantBacking, oldPrice);
    }

    /** Burns Tokens And Deposits Underlying Tokens into Recipients's Address */
    function _sell(
        address seller,
        uint256 tokenAmount,
        address recipient,
        bool cashedOut
    ) internal returns (uint256) {
        require(tokenAmount > 0 && _balances[seller] >= tokenAmount);
        require(seller != address(0) && recipient != address(0));

        // calculate price change
        uint256 oldPrice = _calculatePrice();

        // fee for selling
        uint256 _sellFee = cashedOut ? cashedOutFee : sellFee;

        // tokens post fee to swap for underlying asset
        uint256 tokensToSwap = isFeeExempt[seller]
            ? tokenAmount.sub(10, "Minimum Exemption")
            : tokenAmount.mul(_sellFee).div(feeDenominator);

        // value of taxed tokens
        uint256 amountUnderlyingAsset = amountOut(tokensToSwap);

        // Take Fee
        if (!isFeeExempt[msg.sender]) {
            uint fee = tokenAmount.sub(tokensToSwap);
            _takeFee(fee);
        }

        // burn from sender + supply
        _burn(seller, tokenAmount);

        // send Tokens to Seller
        if (cashedOut) {
            uint256 shelterUnderlyingAmount = _purchaseShelterUnderlyingWithUnderlying(
                    13,
                    amountUnderlyingAsset
                );
            IERC20(shelter.getUnderlyingAddress()).approve(
                address(shelter),
                shelterUnderlyingAmount
            );
            shelter.mintWithBacking(shelterUnderlyingAmount, recipient);
        } else {
            require(
                underlying.transfer(recipient, amountUnderlyingAsset),
                "Underlying Transfer Failure"
            );
        }

        // require price rises
        _requirePriceRises(oldPrice);
        // Differentiate Sell
        emit Redeemed(seller, tokenAmount, amountUnderlyingAsset);
        // return token redeemed and amount underlying
        return amountUnderlyingAsset;
    }

    /** Handles Minting Logic To Create New Tokens */
    function _mintTo(
        address recipient,
        uint256 received,
        uint256 totalBacking,
        uint256 oldPrice
    ) private returns (uint256) {
        // find the number of tokens we should mint to keep up with the current price
        uint256 calculatedSupply = _totalSupply == 0 ? 10 ** 18 : _totalSupply;
        uint256 tokensToMintNoTax = calculatedSupply.mul(received).div(
            totalBacking
        );

        // apply fee to minted tokens to inflate price relative to total supply
        uint256 tokensToMint = isFeeExempt[msg.sender]
            ? tokensToMintNoTax.sub(10, "Minimum Exemption")
            : tokensToMintNoTax.mul(mintFee).div(feeDenominator);

        require(tokensToMint > 0, "Zero Amount");

        // mint to Buyer
        _mint(recipient, tokensToMint);

        // apply fee to tax taken
        if (!isFeeExempt[msg.sender]) {
            uint fee = tokensToMintNoTax.sub(tokensToMint);
            _takeFee(fee);
        }

        // require price rises
        _requirePriceRises(oldPrice);
        // differentiate purchase
        emit Minted(recipient, tokensToMint);
        return tokensToMint;
    }

    /** Takes Fee */
    function _takeFee(uint mFee) internal {
        uint fee = getFee();
        if (fee > 0) {
            uint fFee = mFee.mul(fee).div(100);
            uint bFee = amountOut(fFee);
            if (bFee > 0) {
                underlying.transfer(address(stormRoyalty), bFee);
            }
        }
    }

    /** Swaps Native for Underlying, must get at least `minOut` Underlying back from swap to be successful */
    function _purchaseUnderlyingWithNative(
        uint8 slippage,
        uint256 nativeAmount
    ) internal returns (uint256) {
        // previous amount of Tokens before we received any
        uint256 prevTokenAmount = underlying.balanceOf(address(this));

        // setting the path
        address[] memory path = new address[](2);
        path[0] = router.WAVAX();
        path[1] = address(underlying);

        // get the amount of Underlying tokens for the nativeAmount
        uint[] memory getAmountsOut = router.getAmountsOut(nativeAmount, path);

        // set the slippage
        uint256 minOut = getAmountsOut[1].mul(uint(100).sub(slippage)).div(100);

        // swap Native For Underlying
        router.swapExactAVAXForTokens{value: nativeAmount}(
            minOut,
            path,
            address(this),
            block.timestamp + 300
        );

        // amount after swap
        uint256 currentTokenAmount = underlying.balanceOf(address(this));
        require(currentTokenAmount > prevTokenAmount);
        return currentTokenAmount - prevTokenAmount;
    }

    /** Swaps Underlying for Shelter's underlying, must get at least `minOut` Underlying back from swap to be successful */
    function _purchaseShelterUnderlyingWithUnderlying(
        uint8 slippage,
        uint256 underlyingAmount
    ) internal returns (uint256) {
        // get Shelter's underlying token
        IERC20 shelterUnderlying = IERC20(shelter.getUnderlyingAddress());
        console.log("shelterUnderlying", shelter.getUnderlyingAddress());
        // previous amount of Tokens before we received any
        uint256 prevTokenAmount = shelterUnderlying.balanceOf(address(this));

        // approve underlying for Pangolin's router
        underlying.approve(address(router), underlyingAmount);
        address[] memory path = new address[](3);
        path[0] = address(underlying);
        path[1] = router.WAVAX();
        path[2] = address(shelterUnderlying);

        // get the amount of Underlying tokens for the nativeAmount
        uint[] memory getAmountsOut = router.getAmountsOut(
            underlyingAmount,
            path
        );

        // set the slippage
        uint256 minOut = getAmountsOut[2].mul(uint(100).sub(slippage)).div(100);
        console.log("prevTokenAmount", prevTokenAmount);
        console.log("minOut", minOut);
        console.log("underlyingAmount", underlyingAmount);
        // swap Underlying For Shelter's underlying
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            underlyingAmount,
            minOut,
            path,
            address(this),
            block.timestamp + 300
        );

        // amount after swap
        uint256 currentTokenAmount = shelterUnderlying.balanceOf(address(this));
        require(currentTokenAmount > prevTokenAmount);
        return currentTokenAmount - prevTokenAmount;
    }

    /** Requires The Price Of Tokens To Rise For The Transaction To Conclude */
    function _requirePriceRises(uint256 oldPrice) internal {
        // Calculate Price After Transaction
        uint256 newPrice = _calculatePrice();
        // Require Current Price >= Last Price
        require(newPrice >= oldPrice, "Price Cannot Fall");
        // Emit The Price Change
        emit PriceChange(oldPrice, newPrice, _totalSupply);
    }

    /** Transfers `desiredAmount` of `token` in and verifies the transaction success */
    function _transferIn(
        address token,
        uint256 desiredAmount
    ) internal returns (uint256) {
        uint256 balBefore = IERC20(token).balanceOf(address(this));
        bool s = IERC20(token).transferFrom(
            msg.sender,
            address(this),
            desiredAmount
        );
        uint256 received = IERC20(token).balanceOf(address(this)) - balBefore;
        require(s && received > 0 && received <= desiredAmount);
        return received;
    }

    /** Mints Tokens to the Receivers Address */
    function _mint(address receiver, uint amount) private {
        if (_balances[receiver] == 0) {
            _addHolder(receiver);
        }

        _balances[receiver] = _balances[receiver].add(amount);
        _totalSupply = _totalSupply.add(amount);
        emit Transfer(address(0), receiver, amount);
    }

    /** Burns `amount` of tokens from `account` */
    function _burn(address account, uint amount) private {
        _balances[account] = _balances[account].sub(
            amount,
            "Insufficient Balance"
        );
        _totalSupply = _totalSupply.sub(amount, "Negative Supply");
        emit Transfer(account, address(0), amount);

        if (_balances[account] == 0) {
            _removeHolder(account);
        }
    }

    /** Make Sure there's no Tokens in contract */
    function _checkGarbageCollector(address burnLocation) internal {
        uint256 bal = _balances[burnLocation];
        if (bal > 10 ** 3) {
            // Track Change In Price
            uint256 oldPrice = _calculatePrice();
            // take fee
            _takeFee(bal);
            // burn amount
            _burn(burnLocation, bal);
            // Emit Collection
            emit GarbageCollected(bal);
            // Emit Price Difference
            emit PriceChange(oldPrice, _calculatePrice(), _totalSupply);
        }
    }

    function _addHolder(address holder) internal {
        holderIndex[holder] = holders.length;
        holderEntryTime[holder] = block.timestamp;
        holders.push(holder);
    }

    function _removeHolder(address holder) internal {
        uint256 rmIndex = holderIndex[holder];
        address lastHolder = holders[holders.length - 1];

        if (holders[holderIndex[holder]] != holder) {
            return;
        }

        holderIndex[lastHolder] = rmIndex;
        holders[rmIndex] = lastHolder;
        holders.pop();
        delete holderIndex[holder];
        delete holderEntryTime[holder];
    }

    ///////////////////////////////////
    //////    READ FUNCTIONS    ///////
    ///////////////////////////////////

    /** Price Of Tokens in Underlying With 18 Points Of Precision */
    function calculatePrice() external view returns (uint256) {
        return _calculatePrice();
    }

    /** Returns the Current Price of 1 Token */
    function _calculatePrice() internal view returns (uint256) {
        uint256 totalShares = _totalSupply == 0 ? 1 : _totalSupply;
        uint256 backingValue = underlying.balanceOf(address(this));
        return (backingValue.mul(precision)).div(totalShares);
    }

    /**
        Amount Of Underlying To Receive For `numTokens` of Tokens
     */
    function amountOut(uint256 numTokens) public view returns (uint256) {
        return _calculatePrice().mul(numTokens).div(precision);
    }

    /** Returns the value of `holder`'s holdings */
    function getValueOfHoldings(address holder) public view returns (uint256) {
        return amountOut(_balances[holder]);
    }

    /** Returns Royalty Fee For Taxes */
    function getFee() public view returns (uint256) {
        uint fee = stormRoyalty.getFee();
        return fee;
    }

    /** Returns mintFee and fee Demominator*/
    function getMintFee() public view returns (uint256, uint256) {
        return (mintFee, feeDenominator);
    }

    /** Returns sellFee */
    function getSellFee() public view returns (uint256, uint256) {
        return (sellFee, feeDenominator);
    }

    /** Returns transferFee */
    function getTransferFee() public view returns (uint256, uint256) {
        return (transferFee, feeDenominator);
    }

    /** Returns UnderlyingAddress */
    function getUnderlyingAddress() public view returns (address) {
        return address(underlying);
    }

    /** Returns Holders */
    function getHolders() public view returns (address[] memory) {
        return holders;
    }

    ///////////////////////////////////
    //////   OWNER FUNCTIONS    ///////
    ///////////////////////////////////

    function setSellDownExempt(
        address account,
        bool isExempt
    ) external onlyOwner {
        sellDownExempt[account] = isExempt;
    }

    /** Activates Token, Enabling Trading For All */
    function activateToken() external onlyOwner {
        tokenActivated = true;
        emit TokenActivated(block.number);
    }

    /** Updates The Address Of The Resource Collector */
    function upgradeRouter(address newRouter) external onlyOwner {
        require(newRouter != address(0));
        isFeeExempt[newRouter] = true;
        router = IPangolinRouter(newRouter);
        emit SetRouter(newRouter);
    }

    /** Withdraws Tokens Incorrectly Sent To Token Contract */
    function withdrawNonStableToken(IERC20 token) external onlyOwner {
        require(
            address(token) != address(underlying),
            "Cannot Withdraw Underlying Asset"
        );
        require(address(token) != address(0), "Zero Address");
        token.transfer(msg.sender, token.balanceOf(address(this)));
    }

    /** 
        Sells Tokens On Behalf Of List Of Users
     */
    function sellDownAllAccounts() external nonReentrant onlyOwner {
        uint len = holders.length;
        for (uint i = 0; i < len; ) {
            _sellDownAccount(holders[i]);
            unchecked {
                ++i;
            }
        }
    }

    /** 
        Sells Tokens On Behalf Of List Of Users
     */
    function sellDownAccounts(
        address[] calldata accounts
    ) external nonReentrant onlyOwner {
        uint len = accounts.length;
        for (uint i = 0; i < len; ) {
            _sellDownAccount(accounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function _sellDownAccount(address account) internal {
        require(account != address(0), "Zero Address");
        if (_balances[account] == 0 || sellDownExempt[account]) {
            return;
        }

        _sell(account, _balances[account], account, true);
    }

    /** 
        Sets Mint, Transfer, Sell Fee
        Must Be Within Bounds ( Between 0% - 10% ) 
    */
    function setFees(
        uint256 _mintFee,
        uint256 _transferFee,
        uint256 _sellFee,
        uint256 _cashedOutFee
    ) external onlyOwner {
        require(_mintFee >= 90000); // capped at 10% fee
        require(_transferFee >= 90000); // capped at 10% fee
        require(_sellFee >= 90000); // capped at 10% fee
        require(_cashedOutFee >= 90000); // capped at 10% fee

        mintFee = _mintFee;
        transferFee = _transferFee;
        sellFee = _sellFee;
        cashedOutFee = _cashedOutFee;
        emit SetFees(_mintFee, _transferFee, _sellFee, _cashedOutFee);
    }

    /** Excludes Contract From Transfer Fees */
    function setPermissions(
        address Contract,
        bool feeExempt
    ) external onlyOwner {
        require(Contract != address(0), "Zero Address");
        isFeeExempt[Contract] = feeExempt;
        emit SetPermissions(Contract, feeExempt);
    }

    /** Mint Tokens to Buyer */
    receive() external payable {
        _mintWithNative(msg.sender, 1, msg.value);
        _checkGarbageCollector(address(this));
        _checkGarbageCollector(DEAD);
    }

    ///////////////////////////////////
    //////        EVENTS        ///////
    ///////////////////////////////////

    // Data Tracking
    event TokenActivated(uint blockNo);
    event PriceChange(
        uint256 previousPrice,
        uint256 currentPrice,
        uint256 totalSupply
    );

    // Balance Tracking
    event Minted(address recipient, uint256 numTokens);
    event GarbageCollected(uint256 amountTokensErased);
    event Burn(address from, uint256 amountTokensErased);
    event Redeemed(
        address seller,
        uint256 amountTokens,
        uint256 amountUnderlying
    );

    // Upgradable Contract Tracking
    event SetRouter(address newRouter);

    // Governance Tracking
    event SetPermissions(address Contract, bool feeExempt);
    event SetFees(
        uint mintFee,
        uint transferFee,
        uint sellFee,
        uint256 cashedOutFee
    );
}