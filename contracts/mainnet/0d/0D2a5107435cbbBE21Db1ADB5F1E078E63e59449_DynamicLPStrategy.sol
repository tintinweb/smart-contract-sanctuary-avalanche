// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                           EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

/// @notice Minimal interface for BentoBox token vault interactions - `token` is aliased as `address` from `IERC20` for code simplicity.
interface IBentoBoxMinimal {

    struct Rebase {
        uint128 elastic;
        uint128 base;
    }

    struct StrategyData {
        uint64 strategyStartDate;
        uint64 targetPercentage;
        uint128 balance; // the balance of the strategy that BentoBox thinks is in there
    }

    function strategyData(address token) external view returns (StrategyData memory);

    /// @notice Balance per ERC-20 token per account in shares.
    function balanceOf(address, address) external view returns (uint256);

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param token_ The ERC-20 token to deposit.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function deposit(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external payable returns (uint256 amountOut, uint256 shareOut);

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param token_ The ERC-20 token to withdraw.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        address token_,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    /// @notice Transfer shares from a user account to another one.
    /// @param token The ERC-20 token to transfer.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param share The amount of `token` in shares.
    function transfer(
        address token,
        address from,
        address to,
        uint256 share
    ) external;

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param token The ERC-20 token.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        address token,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    /// @dev Helper function to represent shares back into the `token` amount.
    /// @param token The ERC-20 token.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        address token,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);

    /// @notice Registers this contract so that users can approve it for the BentoBox.
    function registerProtocol() external;

    function totals(address token) external view returns (Rebase memory);

    function harvest(
        address token,
        bool balance,
        uint256 maxChangeAmount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

import "./IOracle.sol";

interface IDynamicSubLPStrategy {
    function dynamicStrategy() external view returns (address);

    function skim(uint256 amount) external;

    function harvest() external returns (uint256 amountAdded);

    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    function exit() external returns (uint256 actualAmount);

    function strategyTokenIn() external view returns (address);

    function strategyTokenOut() external view returns (address);

    function wrapAndDeposit(uint256 minDustAmount0, uint256 minDustAmount1) external returns (uint256 amount, uint256 amountPrice);

    function withdrawAndUnwrapTo(IDynamicSubLPStrategy recipient) external returns (uint256 amount, uint256 amountPrice);

    function swapToLP(
        uint256 amountOutMin,
        uint256 feePercent,
        address feeTo
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.7;

interface IMasterChef {
    function deposit(uint256 _pid, uint256 _amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
    function userInfo(uint256 _pid, address user) external view returns (uint256 amount, uint256 rewardDebt);
    function emergencyWithdraw(uint256 _pid) external;
}

interface ICakeChef is IMasterChef {
    function enterStaking(uint256 _amount) external;
    function leaveStaking(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.12;

interface IOracle {
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

interface IStrategy {
    /// @notice Send the assets to the Strategy and call skim to invest them.
    /// @param amount The amount of tokens to invest.
    function skim(uint256 amount) external;

    /// @notice Harvest any profits made converted to the asset and pass them to the caller.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @param sender The address of the initiator of this transaction. Can be used for reimbursements, etc.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    /// @notice Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    /// @dev The `actualAmount` should be very close to the amount.
    /// The difference should NOT be used to report a loss. That's what harvest is for.
    /// @param amount The requested amount the caller wants to withdraw.
    /// @return actualAmount The real amount that is withdrawn.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    /// @notice Withdraw all assets in the safest way possible. This shouldn't fail.
    /// @param balance The amount of tokens the caller thinks it has invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    function exit(uint256 balance) external returns (int256 amountAdded);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;
pragma experimental ABIEncoderV2;

/// @notice Interface for SushiSwap.
interface ISushiSwap {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function token0() external pure returns (address);
    function token1() external pure returns (address);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    
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

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    )
        external
        returns (
            uint amountA,
            uint amountB
        );

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;

/// @notice Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method).
library Babylonian {
    // computes square roots using the babylonian method
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
        uint256 xx = x;
        uint256 r = 1;
        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }
        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.7;
import "@rari-capital/solmate/src/tokens/ERC20.sol";
import "@rari-capital/solmate/src/utils/SafeTransferLib.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../../libraries/Babylonian.sol";
import "../../interfaces/IStrategy.sol";
import "../../interfaces/ISushiSwap.sol";
import "../../interfaces/IMasterChef.sol";
import "../../interfaces/IDynamicSubLPStrategy.sol";
import "../../interfaces/IBentoBoxMinimal.sol";

/// @notice Dynamic strategy that can have different farming strategy
/// For example, farming on Trader Joe then unwrap the jLP to
/// mint pLP and farm on Pengolin.
contract DynamicLPStrategy is IStrategy, Ownable {
    using SafeTransferLib for ERC20;

    address public immutable strategyToken;
    address public immutable token0;
    address public immutable token1;

    address public immutable bentoBox;

    address public feeCollector;
    uint8 public feePercent;

    uint256 public maxBentoBoxBalance; /// @dev Slippage protection when calling harvest
    mapping(address => bool) public strategyExecutors; /// @dev EOAs that can execute safeHarvest

    IDynamicSubLPStrategy[] public subStrategies;
    IDynamicSubLPStrategy public currentSubStrategy;

    bool public exited; /// @dev After bentobox 'exits' the strategy harvest, skim and withdraw functions can no loner be called

    event LogSubStrategyAdded(address indexed subStrategy);
    event LogSubStrategyChanged(
        address indexed fromStrategy,
        address indexed toStrategy,
        uint256 amountOut,
        uint256 amountOutPrice,
        uint256 amountIn,
        uint256 amountInPrice
    );
    event LogSetStrategyExecutor(address indexed executor, bool allowed);

    /** @param _strategyToken Address of the underlying LP token the strategy invests.
        @param _bentoBox BentoBox address.
        @param _strategyExecutor an EOA that will execute the safeHarvest function.
    */
    constructor(
        address _strategyToken,
        address _bentoBox,
        address _strategyExecutor
    ) {
        strategyToken = _strategyToken;
        token0 = ISushiSwap(_strategyToken).token0();
        token1 = ISushiSwap(_strategyToken).token1();

        bentoBox = _bentoBox;

        if (_strategyExecutor != address(0)) {
            strategyExecutors[_strategyExecutor] = true;
            emit LogSetStrategyExecutor(_strategyExecutor, true);
        }
    }

    modifier isActive() {
        require(!exited, "BentoBox Strategy: exited");
        _;
    }

    modifier onlyBentoBox() {
        require(msg.sender == bentoBox, "BentoBox Strategy: only BentoBox");
        _;
    }

    /// @notice Ensure the current strategy is handling _strategyToken token so that skim,
    /// withdraw and exit can report correctly back to bentobox.
    modifier onlyValidStrategy() {
        require(address(currentSubStrategy) != address(0), "zero address");
        require(currentSubStrategy.strategyTokenIn() == strategyToken, "not handling strategyToken");
        _;
    }

    modifier onlyExecutor() {
        require(strategyExecutors[msg.sender], "BentoBox Strategy: only Executors");
        _;
    }

    function addSubStrategy(IDynamicSubLPStrategy subStrategy) public onlyOwner {
        require(address(subStrategy) != address(0), "zero address");
        require(subStrategy.dynamicStrategy() == address(this), "dynamicStrategy mismatch");

        /// @dev make sure the strategy pair token is using the same token0 and token1
        ISushiSwap sushiPair = ISushiSwap(subStrategy.strategyTokenIn());
        require(sushiPair.token0() == token0 && sushiPair.token1() == token1, "incompatible tokens");

        subStrategies.push(subStrategy);
        emit LogSubStrategyAdded(address(subStrategy));

        if (address(currentSubStrategy) == address(0)) {
            currentSubStrategy = subStrategy;

            emit LogSubStrategyChanged(address(0), address(currentSubStrategy), 0, 0, 0, 0);
        }
    }

    /// @param index the index of the next strategy to use
    /// @param maxSlippageBps maximum tolerated amount of basis points of the total migrated
    ///                   5 = 0.05%
    ///                   10_000 = 100%
    /// @param minDustAmount0 when the new strategy needs to wrap the token0 and token1 from previousSubStrategy
    ///                     unwrapped token0 and token1, after initial addLiquidity, what minimum remaining
    ///                     amount left in the contract (from new pair imbalance),
    ///                     should be considered to swap again for more liquidity. Set to 0 to ignore.
    /// @param minDustAmount1 same as minDustAmount0 but for token1
    function changeStrategy(
        uint256 index,
        uint256 maxSlippageBps,
        uint256 minDustAmount0,
        uint256 minDustAmount1
    ) public onlyExecutor {
        require(index < subStrategies.length, "invalid index");

        IDynamicSubLPStrategy previousSubStrategy = currentSubStrategy;
        currentSubStrategy = subStrategies[index];
        require(previousSubStrategy != currentSubStrategy, "already current");

        /// @dev the next sub strategy is not using the same strategy token
        /// and requires a convertion
        if (previousSubStrategy.strategyTokenIn() != currentSubStrategy.strategyTokenIn()) {
            /// @dev unwrap needs send the token0 and token1 to the next strategy directly
            (uint256 amountFrom, uint256 priceAmountFrom) = previousSubStrategy.withdrawAndUnwrapTo(currentSubStrategy);

            /// @dev wrap from the tokens sent from the previous strategy
            (uint256 amountTo, uint256 priceAmountTo) = currentSubStrategy.wrapAndDeposit(minDustAmount0, minDustAmount1);

            uint256 minToteraledPrice = priceAmountFrom - ((priceAmountFrom * maxSlippageBps) / 10_000);

            require(priceAmountTo >= minToteraledPrice, "maximumBps exceeded");

            emit LogSubStrategyChanged(
                address(previousSubStrategy),
                address(currentSubStrategy),
                amountFrom,
                priceAmountFrom,
                amountTo,
                priceAmountTo
            );
        }
    }

    /// @inheritdoc IStrategy
    function skim(uint256 amount) external override onlyValidStrategy {
        /// @dev bentobox transfers the token in this strategy so we need to
        /// forward them to the sub strategy so that the specific skim can work.
        ERC20(strategyToken).transfer(address(currentSubStrategy), amount);
        currentSubStrategy.skim(amount);
    }

    /// @inheritdoc IStrategy
    function withdraw(uint256 amount) external override isActive onlyBentoBox onlyValidStrategy returns (uint256 actualAmount) {
        return currentSubStrategy.withdraw(amount);
    }

    /// @notice Harvest profits while preventing a sandwich attack exploit.
    /// @param maxBalance The maximum balance of the underlying token that is allowed to be in BentoBox.
    /// @param rebalance Whether BentoBox should rebalance the strategy assets to acheive it's target allocation.
    /// @param maxChangeAmount When rebalancing - the maximum amount that will be deposited to or withdrawn from a strategy to BentoBox.
    /// @dev maxBalance can be set to 0 to keep the previous value.
    /// @dev maxChangeAmount can be set to 0 to allow for full rebalancing.
    function safeHarvest(
        uint256 maxBalance,
        bool rebalance,
        uint256 maxChangeAmount
    ) external onlyExecutor {
        if (maxBalance > 0) {
            maxBentoBoxBalance = maxBalance;
        }

        IBentoBoxMinimal(bentoBox).harvest(strategyToken, rebalance, maxChangeAmount);
    }

    /// @inheritdoc IStrategy
    /// @dev Only BentoBox can call harvest on this strategy.
    /// @dev Ensures that (1) the caller was this contract (called through the safeHarvest function)
    /// and (2) that we are not being frontrun by a large BentoBox deposit when harvesting profits.
    /// @dev Beware that calling harvest can result in a subsequent skim or withdraw call if it's rebalancing.
    function harvest(uint256 balance, address sender) external override isActive onlyBentoBox returns (int256) {
        require(address(currentSubStrategy) != address(0), "zero address");

        /// @dev Don't revert if conditions aren't met in order to allow
        /// BentoBox to continue execution as it might need to do a rebalance.
        if (sender == address(this) && IBentoBoxMinimal(bentoBox).totals(strategyToken).elastic <= maxBentoBoxBalance && balance > 0) {
            return int256(currentSubStrategy.harvest());
        }

        return int256(0);
    }

    /// @inheritdoc IStrategy
    /// @dev do not use isActive modifier here; allow bentobox to call strategy.exit() multiple times
    function exit(uint256 balance) external override onlyBentoBox onlyValidStrategy returns (int256 amountAdded) {
        uint256 actualBalance = currentSubStrategy.exit();

        /// @dev Calculate tokens added (or lost).
        amountAdded = int256(actualBalance) - int256(balance);
        exited = true;
    }

    function swapToLP(uint256 amountOutMin) external onlyExecutor returns (uint256) {
        return currentSubStrategy.swapToLP(amountOutMin, feePercent, feeCollector);
    }

    function setStrategyExecutor(address executor, bool value) external onlyOwner {
        strategyExecutors[executor] = value;
        emit LogSetStrategyExecutor(executor, value);
    }

    function setFeeParameters(address _feeCollector, uint8 _feePercent) external onlyOwner {
        require(feePercent <= 100, "invalid feePercent");
        feeCollector = _feeCollector;
        feePercent = _feePercent;
    }
}