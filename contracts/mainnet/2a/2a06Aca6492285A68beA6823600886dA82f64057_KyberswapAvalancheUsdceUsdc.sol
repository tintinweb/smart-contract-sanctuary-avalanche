// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ERC721Holder} from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

import {DefiiWithParams} from "../DefiiWithParams.sol";

contract KyberswapAvalancheUsdceUsdc is DefiiWithParams, ERC721Holder {
    IAntiSnipAttackPositionManager constant nfpManager =
        IAntiSnipAttackPositionManager(
            0x2B1c7b41f6A8F2b2bc45C3233a5d5FB3cD6dC9A8
        );
    IElasticLiquidityMining constant mining =
        IElasticLiquidityMining(0xBdEc4a045446F583dc564C0A227FFd475b329bf0);
    IERC20 constant USDC = IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
    IERC20 constant USDCe = IERC20(0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664);

    /// @notice Calculate tree age in years, rounded up, for live trees
    /// @param tickLower Lower tick for pool (you can calculate, how many time you need to click - button on frontend to get price from 1.0)
    /// @param tickUpper Upper tick for pool (you can calculate, how many time you need to click - button on frontend to get price from 1.0)
    /// @param fee Fees for pool in bps. 0.001% -> 0.0001 -> 1
    /// @return encodedParams Encoded params for `enterWithParams`. Params also contains mining pool (from list of all available pools)
    function encodeParams(
        int24 tickLower,
        int24 tickUpper,
        uint24 fee
    ) external view returns (bytes memory encodedParams) {
        address pool = nfpManager.factory().getPool(
            address(USDC),
            address(USDCe),
            fee
        );

        uint256 poolLength = mining.poolLength();
        uint256 poolId = poolLength;
        for (uint256 i = 0; i < mining.poolLength(); i++) {
            (
                address poolAddress,
                uint32 startTime,
                uint32 endTime,
                ,
                ,
                ,
                ,
                ,

            ) = mining.getPoolInfo(i);
            if (
                poolAddress == pool &&
                startTime < block.timestamp &&
                endTime > block.timestamp
            ) {
                poolId = i;
                break;
            }
        }
        require(poolId < poolLength, "MINING POOL NOT FOUND");
        encodedParams = abi.encode(tickLower, tickUpper, fee, poolId);
    }

    function _enterWithParams(bytes memory params) internal override {
        require(!hasAllocation(), "DO EXIT FIRST");

        USDC.approve(address(nfpManager), type(uint256).max);
        USDCe.approve(address(nfpManager), type(uint256).max);

        (int24 tickLower, int24 tickUpper, uint24 fee, uint256 poolId) = abi
            .decode(params, (int24, int24, uint24, uint256));

        int24[2] memory ticksPrevious;
        (uint256 tokenId, uint128 liquidity, , ) = nfpManager.mint(
            IAntiSnipAttackPositionManager.MintParams({
                token0: address(USDCe),
                token1: address(USDC),
                fee: fee,
                tickLower: tickLower,
                tickUpper: tickUpper,
                ticksPrevious: ticksPrevious,
                amount0Desired: USDCe.balanceOf(address(this)),
                amount1Desired: USDC.balanceOf(address(this)),
                amount0Min: 0,
                amount1Min: 0,
                recipient: address(this),
                deadline: block.timestamp
            })
        );

        nfpManager.approve(address(mining), tokenId);

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;
        mining.deposit(tokenIds);

        uint256[] memory liqs = new uint256[](1);
        liqs[0] = liquidity;
        mining.join(poolId, tokenIds, liqs);

        USDC.approve(address(nfpManager), 0);
        USDCe.approve(address(nfpManager), 0);
    }

    function _exit() internal override {
        if (!hasAllocation()) {
            return;
        }

        _claim();
        // We don't expect DOS, because we have only 1 joined NFT for 1 pool (restriction in _enter)
        uint256 tokenId = mining.getDepositedNFTs(address(this))[0];
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = tokenId;

        uint256[] memory poolIds = mining.getJoinedPools(tokenId);
        for (uint256 i = 0; i < poolIds.length; i++) {
            uint256[] memory liqs = new uint256[](1);
            (, , liqs[0]) = mining.stakes(tokenId, poolIds[i]);
            mining.exit(poolIds[i], tokenIds, liqs);
        }
        mining.withdraw(tokenIds);

        IAntiSnipAttackPositionManager.Position memory position;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            (position, ) = nfpManager.positions(tokenIds[i]);

            nfpManager.removeLiquidity(
                IAntiSnipAttackPositionManager.RemoveLiquidityParams({
                    tokenId: tokenIds[i],
                    liquidity: position.liquidity,
                    amount0Min: 0,
                    amount1Min: 0,
                    deadline: block.timestamp
                })
            );
        }
        nfpManager.transferAllTokens(address(USDC), 0, address(this));
        nfpManager.transferAllTokens(address(USDCe), 0, address(this));
    }

    function _harvest() internal override {
        _claim();
        _withdrawETH();
    }

    function _withdrawFunds() internal override {
        _withdrawERC20(USDC);
        _withdrawERC20(USDCe);
        _withdrawETH();
    }

    function _claim() internal {
        // We don't expect DOS, because we have only 1 joined NFT (restriction in _enter)
        uint256[] memory tokenIds = mining.getDepositedNFTs(address(this));
        if (tokenIds.length == 0) {
            return;
        }

        bytes[] memory datas = new bytes[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            datas[i] = abi.encode(
                IElasticLiquidityMining.HarvestData({
                    pIds: mining.getJoinedPools(tokenIds[i])
                })
            );
        }
        mining.harvestMultiplePools(tokenIds, datas);
    }

    function hasAllocation() public view override returns (bool) {
        return mining.getDepositedNFTs(address(this)).length > 0;
    }
}

interface IAntiSnipAttackPositionManager {
    struct MintParams {
        address token0;
        address token1;
        uint24 fee;
        int24 tickLower;
        int24 tickUpper;
        int24[2] ticksPrevious;
        uint256 amount0Desired;
        uint256 amount1Desired;
        uint256 amount0Min;
        uint256 amount1Min;
        address recipient;
        uint256 deadline;
    }

    function factory() external view returns (IFactory);

    function mint(MintParams calldata params)
        external
        payable
        returns (
            uint256 tokenId,
            uint128 liquidity,
            uint256 amount0,
            uint256 amount1
        );

    struct RemoveLiquidityParams {
        uint256 tokenId;
        uint128 liquidity;
        uint256 amount0Min;
        uint256 amount1Min;
        uint256 deadline;
    }

    function removeLiquidity(RemoveLiquidityParams calldata params)
        external
        returns (
            uint256 amount0,
            uint256 amount1,
            uint256 additionalRTokenOwed
        );

    struct Position {
        uint96 nonce;
        address operator;
        uint80 poolId;
        int24 tickLower;
        int24 tickUpper;
        uint128 liquidity;
        uint256 rTokenOwed;
        uint256 feeGrowthInsideLast;
    }

    struct PoolInfo {
        address token0;
        uint24 fee;
        address token1;
    }

    function positions(uint256 tokenId)
        external
        view
        returns (Position memory pos, PoolInfo memory info);

    function approve(address to, uint256 tokenId) external;

    function transferAllTokens(
        address token,
        uint256 minAmount,
        address recipient
    ) external;
}

interface IFactory {
    function getPool(
        address tokenA,
        address tokenB,
        uint24 swapFeeUnits
    ) external view returns (address pool);
}

interface IElasticLiquidityMining {
    struct RewardData {
        address rewardToken;
        uint256 rewardUnclaimed;
    }

    struct LMPoolInfo {
        address poolAddress;
        uint32 startTime;
        uint32 endTime;
        uint32 vestingDuration;
        uint256 totalSecondsClaimed; // scaled by (1 << 96)
        RewardData[] rewards;
        uint256 feeTarget;
        uint256 numStakes;
    }

    struct HarvestData {
        uint256[] pIds;
    }

    function deposit(uint256[] calldata nftIds) external;

    function withdraw(uint256[] calldata nftIds) external;

    function getDepositedNFTs(address user)
        external
        view
        returns (uint256[] memory listNFTs);

    function poolLength() external view returns (uint256);

    function getPoolInfo(uint256 pId)
        external
        view
        returns (
            address poolAddress,
            uint32 startTime,
            uint32 endTime,
            uint32 vestingDuration,
            uint256 totalSecondsClaimed,
            uint256 feeTarget,
            uint256 numStakes,
            //index reward => reward data
            address[] memory rewardTokens,
            uint256[] memory rewardUnclaimeds
        );

    function join(
        uint256 pId,
        uint256[] calldata nftIds,
        uint256[] calldata liqs
    ) external;

    function getJoinedPools(uint256 nftId)
        external
        view
        returns (uint256[] memory poolIds);

    function harvestMultiplePools(
        uint256[] calldata nftIds,
        bytes[] calldata datas
    ) external;

    function stakes(uint256 nftId, uint256 pid)
        external
        view
        returns (
            uint128 secondsPerLiquidityLast,
            int256 feeFirst,
            uint256 liquidity
        );

    function exit(
        uint256 pId,
        uint256[] calldata nftIds,
        uint256[] calldata liqs
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./Defii.sol";


abstract contract DefiiWithParams is Defii {
    function enterWithParams(bytes memory params) external onlyOwner {
        _enterWithParams(params);
    }

    function _enterWithParams(bytes memory params) internal virtual;

    function _enter() internal override {
        revert("Run enterWithParams");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "./interfaces/IDefiiFactory.sol";
import "./interfaces/IDefii.sol";


abstract contract Defii is IDefii {
    address public owner;
    address public factory;

    function init(address owner_, address factory_) external {
        require(owner == address(0), "Already initialized");
        owner = owner_;
        factory = factory_;
    }

    // owner functions
    function enter() external onlyOwner {
        _enter();
    }

    function runTx(address target, uint256 value, bytes memory data) external onlyOwner {
        (bool success,) = target.call{value: value}(data);
        require(success, "runTx failed");
    }

    // owner and executor functions
    function exit() external onlyOnwerOrExecutor {
        _exit();
    }
    function exitAndWithdraw() public onlyOnwerOrExecutor {
        _exit();
        _withdrawFunds();
    }

    function harvest() external onlyOnwerOrExecutor {
        _harvest();
    }

    function harvestWithParams(bytes memory params) external onlyOnwerOrExecutor {
        _harvestWithParams(params);
    }

    function withdrawFunds() external onlyOnwerOrExecutor {
        _withdrawFunds();
    }

    function withdrawERC20(IERC20 token) public onlyOnwerOrExecutor {
        _withdrawERC20(token);
    }

    function withdrawETH() public onlyOnwerOrExecutor {
        _withdrawETH();
    }
    receive() external payable {}

    // internal functions - common logic
    function _withdrawERC20(IERC20 token) internal {
        uint256 tokenAmount = token.balanceOf(address(this));
        if (tokenAmount > 0) {
            token.transfer(owner, tokenAmount);
        }
    }

    function _withdrawETH() internal {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            (bool success,) = owner.call{value: balance}("");
            require(success, "Transfer failed");
        }
    }

    function hasAllocation() external view virtual returns (bool);
    // internal functions - defii specific logic
    function _enter() internal virtual;
    function _exit() internal virtual;
    function _harvest() internal virtual {
        revert("Use harvestWithParams");
    }
    function _withdrawFunds() internal virtual;
    function _harvestWithParams(bytes memory params) internal virtual {
        revert("Run harvest");
    }

    // modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlyOnwerOrExecutor() {
        require(msg.sender == owner || msg.sender == IDefiiFactory(factory).executor(), "Only owner or executor");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

interface IDefii {
    function init(address owner_, address factory_) external;

    function enter() external;
    function runTx(address target, uint256 value, bytes memory data) external;

    function exit() external;
    function exitAndWithdraw() external;
    function harvest() external;
    function withdrawERC20(IERC20 token) external;
    function withdrawETH() external;
    function withdrawFunds() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


interface IDefiiFactory {
    function executor() view external returns (address executor);

    function createDefiiFor(address wallet) external;
    function createDefii() external;
    function getDefiiFor(address wallet) external view returns (address defii);
}

// SPDX-License-Identifier: MIT
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
    event Approval(address indexed owner, address indexed spender, uint256 value);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}