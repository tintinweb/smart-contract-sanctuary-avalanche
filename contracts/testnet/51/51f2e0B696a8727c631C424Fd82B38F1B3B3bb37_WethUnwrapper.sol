// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
pragma abicoder v1;

import "../interfaces/NotificationReceiver.sol";
import "../interfaces/IWithdrawable.sol";

contract WethUnwrapper is PostInteractionNotificationReceiver {
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

    function fillOrderPostInteraction(
        address /* taker */,
        address /* makerAsset */,
        address takerAsset,
        uint256 /* makingAmount */,
        uint256 takingAmount,
        bytes calldata interactiveData
    ) external override {
        address payable makerAddress;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            makerAddress := shr(96, calldataload(interactiveData.offset))
        }
        IWithdrawable(takerAsset).withdraw(takingAmount);
        makerAddress.transfer(takingAmount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
pragma abicoder v1;

// TODO: pass order hash, remaining amount, etc to the arguments

/// @title Interface for interactor which acts between `maker => taker` and `taker => maker` transfers.
interface PreInteractionNotificationReceiver {
    function fillOrderPreInteraction(
        address taker,
        address makerAsset,
        address takerAsset,
        uint256 makingAmount,
        uint256 takingAmount,
        bytes memory interactiveData
    ) external;
}

interface PostInteractionNotificationReceiver {
    /// @notice Callback method that gets called after taker transferred funds to maker but before
    /// the opposite transfer happened
    function fillOrderPostInteraction(
        address taker,
        address makerAsset,
        address takerAsset,
        uint256 makingAmount,
        uint256 takingAmount,
        bytes memory interactiveData
    ) external;
}

interface InteractionNotificationReceiver {
    function fillOrderInteraction(
        address taker,
        address makerAsset,
        address takerAsset,
        uint256 makingAmount,
        uint256 takingAmount,
        bytes memory interactiveData
    ) external returns(uint256 offeredTakingAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;
pragma abicoder v1;

interface IWithdrawable {
    function withdraw(uint wad) external;
}