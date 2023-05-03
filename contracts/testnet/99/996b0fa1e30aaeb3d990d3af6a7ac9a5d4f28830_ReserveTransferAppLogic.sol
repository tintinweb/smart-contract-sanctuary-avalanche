// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {StargateInfoLib} from "./libraries/StargateInfoLib.sol";
import {MessageLib} from "./libraries/MessageLib.sol";
import {StargateFunctionType} from "./libraries/StargateFunctionType.sol";

import {BridgingLogicClient} from "./interfaces/BridgingLogicClient.sol";
import {IStargateRouter} from "./interfaces/stargate/IStargateRouter.sol";
import {BridgingLogicErrors} from "./interfaces/BridgingLogicErrors.sol";

import {ReserveTransferApp} from "./ReserveTransferApp.sol";
import {StargatePoolIdViewer} from "./StargatePoolIdViewer.sol";

contract ReserveTransferAppLogic is BridgingLogicErrors, BridgingLogicClient, StargatePoolIdViewer {
    using StargateInfoLib for uint256;

    ReserveTransferApp internal immutable app;

    constructor(address _app) {
        app = ReserveTransferApp(_app);
    }

    function generateTargets(MessageLib.Payload calldata payload, bytes4 functionSelector)
        external
        view
        returns (MessageLib.Target[] memory targets)
    {
        if (payload.action == MessageLib.ACTION_RESERVE_TRANSFER) {
            targets = new MessageLib.Target[](1);
            (
                uint16 srcChainId,
                uint256 reserveAmount,
                address reserveAssetOnDest,
                address reserveAssetOnHome,
                address payable to,
                address receiver
            ) = abi.decode(payload.body, (uint16, uint256, address, address, address, address));
            IStargateRouter.lzTxObj memory lzTxObj = IStargateRouter.lzTxObj(
                0, // extra gas, if calling smart contract, 0 for now
                0, // amount of dust dropped in destination wallet
                "0x" // destination wallet for dust
            );
            IStargateRouter stargateRouter = IStargateRouter(block.chainid.getStargateInfo().stargateRouter);
            (uint256 sgMessageFee,) = stargateRouter.quoteLayerZeroFee(
                srcChainId, // destination chainId
                StargateFunctionType.TYPE_SWAP_REMOTE, // function type: see Bridge.sol for all types
                abi.encodePacked(receiver), // destination of tokens
                "0x", // payload, using abi.encode()
                lzTxObj // extra gas, if calling smart contract
            );

            targets[0] = MessageLib.Target({
                target: address(app),
                value: sgMessageFee,
                data: abi.encodeWithSelector(
                    functionSelector,
                    ReserveTransferApp.ReserveTransferInfo({
                        stargateRouter: address(stargateRouter),
                        srcChainId: srcChainId,
                        sourcePoolId: getStargatePoolId(reserveAssetOnHome),
                        dstPoolId: getStargatePoolId(reserveAssetOnDest),
                        reserveAmount: reserveAmount,
                        lzTxObj: lzTxObj,
                        receiver: receiver,
                        reserveAsset: reserveAssetOnHome,
                        to: to
                    })
                    )
            });
        } else {
            revert BridgingLogicUnsupportedAction(payload.action);
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {ChainID} from "../../constants/ChainID.sol";

library StargateInfoLib {
    struct StargateInfo {
        address layerZeroEndpoint;
        address stargateRouter;
    }

    // Layer zero enpoints addresses
    address internal constant ETHEREUM_LZ_ENDPOINT = 0x66A71Dcef29A0fFBDBE3c6a460a3B5BC225Cd675;
    address internal constant BSC_LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address internal constant AVALANCHE_LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address internal constant POLYGON_LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address internal constant ARBITRUM_LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address internal constant OPTIMISM_LZ_ENDPOINT = 0x3c2269811836af69497E5F486A85D7316753cf62;
    address internal constant FANTOM_LZ_ENDPOINT = 0xb6319cC6c8c27A8F5dAF0dD3DF91EA35C4720dd7;

    address internal constant ETHEREUM_GOERLI_LZ_ENDPOINT = 0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23;
    address internal constant ARBITRUM_GOERLI_LZ_ENDPOINT = 0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab;
    address internal constant AVALANCHE_FUJI_LZ_ENDPOINT = 0x93f54D755A063cE7bB9e6Ac47Eccc8e33411d706;
    address internal constant OPTIMISM_GOERLI_LZ_ENDPOINT = 0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1;
    address internal constant POLYGON_MUMBAI_LZ_ENDPOINT = 0xf69186dfBa60DdB133E91E9A4B5673624293d8F8;

    // Stargate Router addresses
    address internal constant ETHEREUM_STARGATE_ROUTER = 0x8731d54E9D02c286767d56ac03e8037C07e01e98;
    address internal constant BSC_STARGATE_ROUTER = 0x4a364f8c717cAAD9A442737Eb7b8A55cc6cf18D8;
    address internal constant AVALANCHE_STARGATE_ROUTER = 0x45A01E4e04F14f7A4a6702c74187c5F6222033cd;
    address internal constant POLYGON_STARGATE_ROUTER = 0x45A01E4e04F14f7A4a6702c74187c5F6222033cd;
    address internal constant ARBITRUM_STARGATE_ROUTER = 0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614;
    address internal constant OPTIMISM_STARGATE_ROUTER = 0xB0D502E938ed5f4df2E681fE6E419ff29631d62b;
    address internal constant FANTOM_STARGATE_ROUTER = 0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6;

    address internal constant ETHEREUM_GOERLI_STARGATE_ROUTER = 0x7612aE2a34E5A363E137De748801FB4c86499152;
    address internal constant ARBITRUM_GOERLI_STARGATE_ROUTER = 0xb850873f4c993Ac2405A1AdD71F6ca5D4d4d6b4f;
    address internal constant AVALANCHE_FUJI_STARGATE_ROUTER = 0x13093E05Eb890dfA6DacecBdE51d24DabAb2Faa1;
    address internal constant OPTIMISM_GOERLI_STARGATE_ROUTER = 0x95461eF0e0ecabC049a5c4a6B98Ca7B335FAF068;
    address internal constant POLYGON_MUMBAI_STARGATE_ROUTER = 0x817436a076060D158204d955E5403b6Ed0A5fac0;

    function getStargateInfo(uint256 chainId) internal pure returns (StargateInfo memory info) {
        if (chainId == ChainID.ETHEREUM) {
            info = StargateInfo(ETHEREUM_LZ_ENDPOINT, ETHEREUM_STARGATE_ROUTER);
        } else if (chainId == ChainID.BSC) {
            info = StargateInfo(BSC_LZ_ENDPOINT, BSC_STARGATE_ROUTER);
        } else if (chainId == ChainID.AVALANCHE) {
            info = StargateInfo(AVALANCHE_LZ_ENDPOINT, AVALANCHE_STARGATE_ROUTER);
        } else if (chainId == ChainID.POLYGON) {
            info = StargateInfo(POLYGON_LZ_ENDPOINT, POLYGON_STARGATE_ROUTER);
        } else if (chainId == ChainID.ARBITRUM) {
            info = StargateInfo(ARBITRUM_LZ_ENDPOINT, ARBITRUM_STARGATE_ROUTER);
        } else if (chainId == ChainID.OPTIMISM) {
            info = StargateInfo(OPTIMISM_LZ_ENDPOINT, OPTIMISM_STARGATE_ROUTER);
        } else if (chainId == ChainID.FANTOM) {
            info = StargateInfo(FANTOM_LZ_ENDPOINT, FANTOM_STARGATE_ROUTER);
        } else if (chainId == ChainID.ETHEREUM_GOERLI) {
            info = StargateInfo(ETHEREUM_GOERLI_LZ_ENDPOINT, ETHEREUM_GOERLI_STARGATE_ROUTER);
        } else if (chainId == ChainID.ARBITRUM_GOERLI) {
            info = StargateInfo(ARBITRUM_GOERLI_LZ_ENDPOINT, ARBITRUM_GOERLI_STARGATE_ROUTER);
        } else if (chainId == ChainID.AVALANCHE_FUJI) {
            info = StargateInfo(AVALANCHE_FUJI_LZ_ENDPOINT, AVALANCHE_FUJI_STARGATE_ROUTER);
        } else if (chainId == ChainID.OPTIMISM_GOERLI) {
            info = StargateInfo(OPTIMISM_GOERLI_LZ_ENDPOINT, OPTIMISM_GOERLI_STARGATE_ROUTER);
        } else if (chainId == ChainID.POLYGON_MUMBAI) {
            info = StargateInfo(POLYGON_MUMBAI_LZ_ENDPOINT, POLYGON_MUMBAI_STARGATE_ROUTER);
        } else {
            revert("Invalid chainId");
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

library MessageLib {
    struct Message {
        uint8 action;
        bytes messageBody;
    }

    struct Target {
        uint256 value;
        address target;
        bytes data;
    }

    struct Payload {
        bytes body;
        uint8 action;
    }

    struct RemoteAssetBalance {
        uint128 newBalance;
        uint128 delta;
        address asset;
    }

    struct RemoteOrderBookEmptyMessage {
        RemoteAssetBalance[] balances;
    }

    uint8 internal constant ACTION_REMOTE_VAULT_MINT = 0;
    uint8 internal constant ACTION_REMOTE_VAULT_BURN = 1;
    uint8 internal constant ACTION_REMOTE_VAULT_ESCROW = 2;
    uint8 internal constant ACTION_RESERVE_TRANSFER = 3;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

library StargateFunctionType {
    uint8 internal constant TYPE_SWAP_REMOTE = 1;
    uint8 internal constant TYPE_ADD_LIQUIDITY = 2;
    uint8 internal constant TYPE_REDEEM_LOCAL_CALL_BACK = 3;
    uint8 internal constant TYPE_WITHDRAW_REMOTE = 4;
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {MessageLib} from "../libraries/MessageLib.sol";

interface BridgingLogicClient {
    function generateTargets(MessageLib.Payload calldata payload, bytes4 functionSelector)
        external
        view
        returns (MessageLib.Target[] memory targets);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall; // extra gas, if calling smart contract,
        uint256 dstNativeAmount; // amount of dust dropped in destination wallet
        bytes dstNativeAddr; // destination wallet for dust
    }

    function addLiquidity(uint256 _poolId, uint256 _amountLD, address _to) external;

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

    function instantRedeemLocal(uint16 _srcPoolId, uint256 _amountLP, address _to) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(uint16 _dstChainId, uint256 _srcPoolId, uint256 _dstPoolId, address payable _refundAddress)
        external
        payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

interface BridgingLogicErrors {
    error BridgingLogicForbiddenCaller(address caller);
    error BridgingLogicUnsupportedAction(uint8 id);
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {Owned} from "solmate/auth/Owned.sol";
import {ERC20, SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {MessageLib} from "./libraries/MessageLib.sol";

import {BridgingExecutor} from "./interfaces/BridgingExecutor.sol";
import {IStargateRouter} from "./interfaces/stargate/IStargateRouter.sol";
import {BridgingLogicClient} from "./interfaces/BridgingLogicClient.sol";

contract ReserveTransferApp is Owned, BridgingExecutor {
    using SafeTransferLib for ERC20;

    struct ReserveTransferInfo {
        address stargateRouter;
        uint16 srcChainId;
        uint256 sourcePoolId;
        uint256 dstPoolId;
        uint256 reserveAmount;
        IStargateRouter.lzTxObj lzTxObj;
        address receiver;
        address reserveAsset;
        address payable to;
    }

    address internal bridgingLogic;

    constructor() Owned(msg.sender) {}

    function transfer(ReserveTransferInfo calldata info) external payable {
        (bool success,) = address(this).call(abi.encodeWithSelector(this._transfer.selector, info));

        if (!success) {
            // TODO: think on the edge cases here, the safest way would probably be:
            // a) transfer all usdc and eth balance regardless of success status
            ERC20(info.reserveAsset).safeTransfer(info.to, info.reserveAmount);
        }
        info.to.transfer(address(this).balance);
    }

    function setBridgingLogic(address _bridgingLogic) external onlyOwner {
        bridgingLogic = _bridgingLogic;
    }

    function _transfer(ReserveTransferInfo calldata info) external payable {
        if (msg.sender != address(this)) {
            revert();
        }

        // Here we need to swap the usdc from this chain to another chain using stargate
        ERC20(info.reserveAsset).safeApprove(info.stargateRouter, info.reserveAmount);

        IStargateRouter(info.stargateRouter).swap{value: address(this).balance}(
            info.srcChainId,
            info.sourcePoolId, // source pool id
            info.dstPoolId, // dest pool id
            info.to, // refund address. extra gas (if any) is returned to this address
            info.reserveAmount, // amount of asset to swap
            0, // min amount of asset to receive
            info.lzTxObj,
            abi.encodePacked(info.receiver), // destination of tokens
            bytes("") // bytes param, if you wish to send additional payload you can abi.encode() them here
        );

        ERC20(info.reserveAsset).safeApprove(info.stargateRouter, 0);
    }

    function getTargetExecutionData(MessageLib.Payload calldata payload)
        external
        view
        returns (MessageLib.Target[] memory)
    {
        return BridgingLogicClient(bridgingLogic).generateTargets(payload, ReserveTransferApp.transfer.selector);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {Owned} from "solmate/auth/Owned.sol";

contract StargatePoolIdViewer is Owned {
    struct StargatePoolId {
        address[] tokens;
        uint256 poolId;
    }

    mapping(address => uint256) public stargatePoolId;

    constructor() Owned(msg.sender) {}

    function setStargatePoolIds(StargatePoolId[] calldata infos) external onlyOwner {
        for (uint256 i; i < infos.length;) {
            for (uint256 j; j < infos[i].tokens.length;) {
                stargatePoolId[infos[i].tokens[j]] = infos[i].poolId;

                unchecked {
                    j++;
                }
            }
            unchecked {
                i++;
            }
        }
    }

    function getStargatePoolId(address token) public view returns (uint256) {
        uint256 poolId = stargatePoolId[token];
        if (poolId == 0) {
            revert("Token not supported");
        }
        return poolId;
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

library ChainID {
    // Mainnet chainIDs
    uint256 internal constant ETHEREUM = 1;
    uint256 internal constant BSC = 56;
    uint256 internal constant AVALANCHE = 43_114;
    uint256 internal constant POLYGON = 137;
    uint256 internal constant ARBITRUM = 42_161;
    uint256 internal constant OPTIMISM = 10;
    uint256 internal constant FANTOM = 250;

    // Testnet chainIDs
    uint256 internal constant ETHEREUM_GOERLI = 5;
    uint256 internal constant ARBITRUM_GOERLI = 421_613;
    uint256 internal constant POLYGON_MUMBAI = 80_001;
    uint256 internal constant AVALANCHE_FUJI = 43_113;
    uint256 internal constant OPTIMISM_GOERLI = 420;
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        /// @solidity memory-safe-assembly
        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later

pragma solidity ^0.8.17;

import {MessageLib} from "../libraries/MessageLib.sol";

interface BridgingExecutor {
    function getTargetExecutionData(MessageLib.Payload calldata payload)
        external
        view
        returns (MessageLib.Target[] memory targets);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
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

    /*//////////////////////////////////////////////////////////////
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
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
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
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

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
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
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