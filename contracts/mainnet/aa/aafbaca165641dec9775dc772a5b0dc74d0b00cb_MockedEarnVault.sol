// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

contract MockedEarnVault {

    /** earn vault */
    uint256 public constant DEFAULT_LAST_STRATEGY_BALANCE = 1e8;
    uint256 public constant DEFAULT_MAX_WITHDRAWABLE_BALANCE = 5 * 1e8;
    enum Status { RUNNING, STOPPING, STOPPED }

    uint256 public vaultBalance = 0;
    uint256 public lastStrategyBalance = 0;
    uint256 public maxWithdrawableAmount = 0;
    Status public status = Status.RUNNING;

    /** want token */
    uint80 public constant ROUND_ID = 0;
    int256 public constant PRICE = 1;
    uint256 public constant STARTED_AT = 0;
    uint256 public constant UPDATED_AT = 1;
    uint80 public constant ANSWERED_IN_ROUND = 1;
    uint8 public constant DECIMALS = 0;

    /** guardian */

    function stopActivity() external {
        // Revert if in STOPPED state
        if (status == Status.STOPPED) {
            revert("Stopped");
        }
        // Revert if in STOPPING state and no liquidity available
        if (status == Status.STOPPING && maxWithdrawableAmount == 0) {
            revert("No liquidity available");
        }
        // Transition to STOPPING state if currently in RUNNING state
        if (status == Status.RUNNING) {
            status = Status.STOPPING;
        }
        // Withdraw all the funds from the protocol if there is enough liquidity else withdraw all the available liquidity
        if (lastStrategyBalance < maxWithdrawableAmount) {
            maxWithdrawableAmount -= lastStrategyBalance;
            vaultBalance += lastStrategyBalance;
            lastStrategyBalance = 0;
        } else {
            lastStrategyBalance -= maxWithdrawableAmount;
            vaultBalance += maxWithdrawableAmount;
            maxWithdrawableAmount = 0;
        }
        // Transistion to STOPPED state if all the funds have been withdrawn
        if (lastStrategyBalance == 0) {
            status = Status.STOPPED;
        }
    }

    function resumeActivity() external {
        // Revert if not in STOPPED state
        if (status != Status.STOPPED) {
            revert("Not stopped");
        }
        // Transition to RUNNING state
        status = Status.RUNNING;
        // Deposit all the funds in the protocol
        lastStrategyBalance = vaultBalance;
        maxWithdrawableAmount += vaultBalance;
        vaultBalance = 0;
    }

    /** earn vault setter */

    function reset() external {
        vaultBalance = 0;
        lastStrategyBalance = 0;
        maxWithdrawableAmount = 0;
        status = Status.RUNNING;
    }

    function init() external {
        vaultBalance = 0;
        lastStrategyBalance = DEFAULT_LAST_STRATEGY_BALANCE;
        maxWithdrawableAmount = DEFAULT_MAX_WITHDRAWABLE_BALANCE;
        status = Status.RUNNING;
    }

    function setStatus(Status _status) external {
        status = _status;
    }

    function setMaxWithdrawableAmount(uint256 _maxWithdrawableAmount) external {
        maxWithdrawableAmount = _maxWithdrawableAmount;
    }

    /** earn vault view */

    function getStatus() external view returns (uint256) {
        return uint256(status);
    }

    /** want token view */

    function latestRoundData() external pure returns (
            uint80,
            int256,
            uint256,
            uint256,
            uint80) {
        return (ROUND_ID, PRICE, STARTED_AT, UPDATED_AT, ANSWERED_IN_ROUND);
    }

    function decimals() external pure returns (uint8) {
        return DECIMALS;
    }
}