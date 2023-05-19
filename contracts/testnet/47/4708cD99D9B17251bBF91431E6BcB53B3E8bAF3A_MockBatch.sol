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

interface IGCrossChainHelper {
    function handleDirectWithdraw(bytes calldata data) external;

    function updateBatchHandleMessage(bytes calldata data) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../../interfaces/IBatch.sol";
import "../../interfaces/IBridgeMessage.sol";
import "../../interfaces/IGCrossChainHelper.sol";
import "../../Error.sol";

contract MockBatch {
    address public messageBridgeHelper;

    event BatchDataBack(
        uint256 batchId,
        uint256 returnShares,
        uint256 withdrawCoins
    );
    event CrossBatchInfo(
        uint256 batchId,
        uint256 investAmount,
        uint256 withdrawAmount
    );
    event UpdateMessageBridgeHelper(address helper);

    modifier onlyMessageBridger() {
        if (msg.sender != messageBridgeHelper) revert InvalidCaller();
        _;
    }

    function updateMessageBridgeHelper(address helper) external {
        if (helper == address(0)) revert InvalidAddress();
        messageBridgeHelper = helper;
        emit UpdateMessageBridgeHelper(helper);
    }

    function bridgeBatchMessage(
        uint256 batchId,
        uint256 withdrawAmount,
        uint256 investAmount
    ) external payable {
        bytes memory data = abi.encodeWithSelector(
            IGCrossChainHelper.updateBatchHandleMessage.selector,
            batchId,
            withdrawAmount,
            investAmount
        );
        IBridgeMessage(messageBridgeHelper).bridgeMessage{value: msg.value}(
            batchId,
            data
        );
        emit CrossBatchInfo(batchId, investAmount, withdrawAmount);
    }

    function writeBridgeMessageBack(
        bytes calldata data
    ) external onlyMessageBridger {
        (uint256 batchId, uint256 returnShares, uint256 withdrawCoins) = abi
            .decode(data, (uint256, uint256, uint256));
        emit BatchDataBack(batchId, returnShares, withdrawCoins);
    }
}