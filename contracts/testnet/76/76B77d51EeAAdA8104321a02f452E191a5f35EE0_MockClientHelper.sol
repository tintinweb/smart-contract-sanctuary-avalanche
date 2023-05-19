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

contract MockClientHelper {
    address public messageBridgeHelper;

    event FallbackUserShare(address indexed account, uint256 share);
    event DirectWithdraw(address indexed account, uint256 share);
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

    function directWithdraw(uint256 share) external payable {
        bytes memory data = abi.encodeWithSelector(
            IGCrossChainHelper.handleDirectWithdraw.selector,
            msg.sender,
            share
        );

        IBridgeMessage(messageBridgeHelper).bridgeMessage{value: msg.value}(
            0,
            data
        );
        emit DirectWithdraw(msg.sender, share);
    }

    function fallBackWithdrawShare(
        bytes calldata data
    ) external onlyMessageBridger {
        (address account, uint256 share) = abi.decode(data, (address, uint256));
        emit FallbackUserShare(account, share);
    }
}