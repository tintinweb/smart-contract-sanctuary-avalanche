// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
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

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ICallProxy.sol";
import "../interfaces/IAnycallExecutor.sol";
import "../Error.sol";

abstract contract MutichainBase is Ownable {
    address public immutable anyCallContract;
    uint32 public immutable sourceChainId;
    address public source;

    event UpdateSource(address newSource);

    receive() external payable {}

    fallback() external payable {}

    modifier onlyExecutor() {
        if (msg.sender != ICallProxy(anyCallContract).executor())
            revert CallerNotExecutor();
        _;
    }

    constructor(address anyCallContract_, uint32 sourceChainId_) Ownable() {
        anyCallContract = anyCallContract_;
        sourceChainId = sourceChainId_;
    }

    function updateSource(address newSource) external onlyOwner {
        if (newSource == address(0)) revert InvalidAddress();
        source = newSource;
        emit UpdateSource(newSource);
    }

    function checkContext() internal {
        address executor = ICallProxy(anyCallContract).executor();
        (address from, uint256 fromChainId, ) = IAnycallExecutor(executor)
            .context();
        if (from != source) revert InvalidFromSource();
        if (fromChainId != sourceChainId) revert InvalidFromChain();
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "./MutichainBase.sol";
import "../interfaces/ICallProxy.sol";
import "../interfaces/IBridgeMessage.sol";
import "../interfaces/IGCrossChainHelper.sol";
import "../interfaces/IBatch.sol";
import "../interfaces/IClientHelper.sol";
import "../Error.sol";

contract MultichainL2MessageBridgeHelperV2 is IBridgeMessage, MutichainBase {
    address public batch;
    address public clientHelper;

    event BridgeMessage(uint256 indexed batchId, bytes data);
    event HandleBatchBack(bytes data, bool success);
    event HandleFallbackBack(bytes data, bool success);

    modifier onlyBatchOrClientHelper() {
        if (msg.sender != batch || msg.sender != clientHelper)
            revert InvalidCaller();
        _;
    }

    constructor(
        address anyCall_,
        address batch_,
        address clientHelper_,
        uint32 sourceChainId_
    ) MutichainBase(anyCall_, sourceChainId_) {
        batch = batch_;
        clientHelper = clientHelper_;
    }

    /**
     * batchId: uint256, 0 mean direct withdraw
     */
    function bridgeMessage(
        uint256 batchId,
        bytes calldata data
    ) external payable onlyBatchOrClientHelper {
        ICallProxy(anyCallContract).anyCall{value: msg.value}(
            source,
            data,
            sourceChainId,
            4,
            ""
        );
        emit BridgeMessage(batchId, data);
    }

    function anyExecute(
        bytes memory data
    ) external onlyExecutor returns (bool success, bytes memory result) {
        checkContext();

        try IBatch(batch).writeBridgeMessageBack(data) {
            emit HandleBatchBack(data, true);
        } catch {
            emit HandleBatchBack(data, false);
        }
        return (true, "");
    }

    function anyFallback(
        bytes calldata data
    ) external onlyExecutor returns (bool, bytes memory) {
        checkContext();
        bytes4 selector = bytes4(data[:4]);
        if (selector == IGCrossChainHelper.handleDirectWithdraw.selector) {
            try IClientHelper(clientHelper).fallBackWithdrawShare(data[4:]) {
                emit HandleFallbackBack(data, true);
            } catch {
                emit HandleFallbackBack(data, false);
            }
        }
        return (true, "");
    }

    function getRelayerFee() external view returns (uint256 fees) {
        address configAddr = ICallProxy(anyCallContract).config();
        uint256 data;
        uint256 dataLendth = abi
            .encodeWithSelector(this.getRelayerFee.selector, data, data, data)
            .length;
        fees = ICallProxy(configAddr).calcSrcFees(
            "0",
            sourceChainId,
            dataLendth
        );
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library DataTypes {
    enum BatchStatus {
        Pending,
        OnGoing,
        CrossChainHandling,
        Claimable
    }

    struct InvestBatchParams {
        uint256 investCoinAmount;
        uint256 returnShareAmount;
    }

    struct WithdrawBatchParams {
        uint256 withdrawShareAmount;
        uint256 withdrawCoinAmount;
        uint256 returnCoinAmount;
    }

    struct BatchInfo {
        uint256 startTime;
        uint256 endTime;
        uint256 maxInvestCoinAmount;
        uint256 statusUpdateTime;
        BatchStatus status;
    }

    struct UserBasicInfo {
        uint256 batchId; // the last batch id user participated
        uint256 shareBalance; // the gvt share balance of user
        uint256 claimableCoinAmount; // the claimable usdc coin amount of user
    }

    struct InvestParams {
        uint256 batchId;
        uint256 investAmount;
        bool isClaimed;
        bool isCancelled;
    }

    struct WithdrawParams {
        uint256 batchId;
        uint256 withdrawShareAmount;
        bool isClaimed;
        bool isCancelled;
    }

    struct HelperParams {
        uint256 batchId;
        uint256 withdrawAmount;
        uint256 investAmount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

error InvalidAddress();
error InvalidAmount();
error InvalidParam();
error InvalidCaller();
error InvalidFromSource();
error InvalidFromChain();
error InsufficientBalance();
error CallerNotExecutor();
error CallerNotRelayer();
error SenderNotL2MessageBridgeHelper(); // ??
error SenderNotFromBatchHandlerChain(); //
error SenderNotL1MessageBridgeHelper(); //
error SenderNotL1Chain();
error BatchDataNotReady();
error BatchStatusError();
error NotInWhiteList();
error AlreadyHasCrossChainBatch();
error InvestIsCancelled();
error WithdrawIsCancelled();

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IAnycallExecutor {
    function context()
        external
        returns (address from, uint256 fromChainID, uint256 nonce);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../DataTypes.sol";

interface IBatch {
    function updateBatchInvestAmount(
        uint256 batchId,
        bool isAdd,
        uint256 amount
    ) external;

    function updateBatchWithdrawAmount(
        uint256 batchId,
        bool isAdd,
        uint256 amount
    ) external;

    function writeBridgeMessageBack(bytes calldata data) external;

    function checkBatchStatus(
        uint256 batchId,
        DataTypes.BatchStatus status
    ) external view returns (bool);

    function getLastBatchId() external view returns (uint256);

    function batchInvestInfos(
        uint256 batchId
    ) external view returns (DataTypes.InvestBatchParams memory);

    function batchWithdrawInfos(
        uint256 batchId
    ) external view returns (DataTypes.WithdrawBatchParams memory);

    function getBatchStatus(
        uint256 batchId
    ) external view returns (DataTypes.BatchStatus);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IBridgeMessage {
    function bridgeMessage(
        uint256 batchId,
        bytes calldata data
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ICallProxy {
    function anyCall(
        address to,
        bytes calldata data,
        uint256 toChainID,
        uint256 flags,
        bytes calldata extdata
    ) external payable;

    function context()
        external
        view
        returns (address from, uint256 fromChainID, uint256 nonce);

    function executor() external view returns (address executor);

    function config() external view returns (address config);

    function calcSrcFees(
        string calldata app,
        uint256 toChainID,
        uint256 dataLength
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IClientHelper {
    function fallBackWithdrawShare(bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IGCrossChainHelper {
    function handleDirectWithdraw(bytes calldata data) external;

    function updateBatchHandleMessage(bytes calldata data) external;
}