/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



/**
 * @title VestingContract
 * @notice This is a simple vesting contract that allows to create vesting schedules for a beneficiary with monthly unlocks.
 */
contract VestingContract {
    

    /**
     * @notice The token to be vested
     */
    

    enum DurationUnits {
        Days,
        Weeks,
        Months
    }

    struct VestingSchedule {
        // beneficiary of tokens after they are released
        address beneficiary;
        // start time of the vesting period
        uint256 start;
        // duration of the vesting period in DurationUnits
        uint256 duration;
        // units of the duration
        DurationUnits durationUnits;
        // total amount of tokens to be released at the end of the vesting;
        uint256 amountTotal;
        // amount of tokens released
        uint256 released;
    }

    /**
     * @notice List of vesting schedules for each beneficiary
     */
    mapping(address => VestingSchedule[]) public vestingSchedules;

    /**
     * @notice Emitted when a vesting schedule is created
     * @param beneficiary The address of the beneficiary
     * @param start The start UNIX timestamp of the vesting period
     * @param duration The duration of the vesting period in DurationUnits
     * @param durationUnits The units of the duration(0 = days, 1 = weeks, 2 = months)
     */
    
}