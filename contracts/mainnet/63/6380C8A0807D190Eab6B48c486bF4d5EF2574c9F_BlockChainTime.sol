// SPDX-License-Identifier: MIT
pragma solidity ^0.8.14;


/*

╭━━╮╭╮╱╱╱╱╱╱╭╮
┃╭╮┃┃┃╱╱╱╱╱╱┃┃
┃╰╯╰┫┃╭━━┳━━┫┃╭╮
┃╭━╮┃┃┃╭╮┃╭━┫╰╯╯
┃╰━╯┃╰┫╰╯┃╰━┫╭╮╮
╰━━━┻━┻━━┻━━┻╯╰╯
╭━━━┳╮
┃╭━╮┃┃
┃┃╱╰┫╰━┳━━┳┳━╮
┃┃╱╭┫╭╮┃╭╮┣┫╭╮╮
┃╰━╯┃┃┃┃╭╮┃┃┃┃┃
╰━━━┻╯╰┻╯╰┻┻╯╰╯
╭━━━━╮
┃╭╮╭╮┃
╰╯┃┃┣╋╮╭┳━━╮
╱╱┃┃┣┫╰╯┃┃━┫
╱╱┃┃┃┃┃┃┃┃━┫
╱╱╰╯╰┻┻┻┻━━╯
*/


/*
we are trying help and support the devs and community
free to use :) 
https://twitter.com/Maho_Dev
*/


contract BlockChainTime {
    struct DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint256 public DAY_IN_SECONDS = 86400;
    uint256 public YEAR_IN_SECONDS = 31536000;
    uint256 public LEAP_YEAR_IN_SECONDS = 31622400;

    uint256 public HOUR_IN_SECONDS = 3600;
    uint256 public MINUTE_IN_SECONDS = 60;

    uint16 public ORIGIN_YEAR = 1970;
    

    function getTimeSeconds() public view returns (uint256) {
        return block.timestamp;
    }

    function getTimeMinutes() public view returns (uint256) {
        return block.timestamp / 60;
    }

    function getTimeHours() public view returns (uint256) {
        return block.timestamp / 60 / 60;
    }

    function getTimeDays() public view returns (uint256) {
        return block.timestamp / 60 / 60 / 24;
    }

    function isLeapYear(uint16 year) internal pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }

    function parseTimestamp(uint256 timestamp)
        private
        view
        returns (DateTime memory dt)
    {
        uint256 secondsAccountedFor = 0;
        uint256 buf;
        uint8 i;

        dt.year = ORIGIN_YEAR;

        // Year
        while (true) {
            if (isLeapYear(dt.year)) {
                buf = LEAP_YEAR_IN_SECONDS;
            } else {
                buf = YEAR_IN_SECONDS;
            }

            if (secondsAccountedFor + buf > timestamp) {
                break;
            }
            dt.year += 1;
            secondsAccountedFor += buf;
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(dt.year)) {
            monthDayCounts[1] = 29;
        } else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        uint256 secondsInMonth;
        for (i = 0; i < monthDayCounts.length; i++) {
            secondsInMonth = DAY_IN_SECONDS * monthDayCounts[i];
            if (secondsInMonth + secondsAccountedFor > timestamp) {
                dt.month = i + 1;
                break;
            }
            secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 0; i < monthDayCounts[dt.month - 1]; i++) {
            if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.day = i + 1;
                break;
            }
            secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        for (i = 0; i < 24; i++) {
            if (HOUR_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.hour = i;
                break;
            }
            secondsAccountedFor += HOUR_IN_SECONDS;
        }

        // Minute
        for (i = 0; i < 60; i++) {
            if (MINUTE_IN_SECONDS + secondsAccountedFor > timestamp) {
                dt.minute = i;
                break;
            }
            secondsAccountedFor += MINUTE_IN_SECONDS;
        }

        if (timestamp - secondsAccountedFor > 60) {
            __throw();
        }

        // Second
        dt.second = uint8(timestamp - secondsAccountedFor);

        // Day of week.
        buf = timestamp / DAY_IN_SECONDS;
        dt.weekday = uint8((buf + 3) % 7);
    }

    function getYear(uint256 timestamp) public view returns (uint16) {
        return parseTimestamp(timestamp).year;
    }

    function getMonth(uint256 timestamp) public view returns (uint16) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint256 timestamp) public view returns (uint16) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint256 timestamp) public view returns (uint16) {
        return parseTimestamp(timestamp).hour;
    }

    function getMinute(uint256 timestamp) public view returns (uint16) {
        return parseTimestamp(timestamp).minute;
    }

    function getSecond(uint256 timestamp) public view returns (uint16) {
        return parseTimestamp(timestamp).second;
    }

    function getWeekday(uint256 timestamp) public view returns (uint8) {
        return parseTimestamp(timestamp).weekday;
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day
    ) public view returns (uint256 timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour
    ) public view returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute
    ) public view returns (uint256 timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(
        uint16 year,
        uint8 month,
        uint8 day,
        uint8 hour,
        uint8 minute,
        uint8 second
    ) public view returns (uint256 timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
            if (isLeapYear(i)) {
                timestamp += LEAP_YEAR_IN_SECONDS;
            } else {
                timestamp += YEAR_IN_SECONDS;
            }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        } else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
    }

    function __throw() internal pure {
        uint256[] memory arst;
        arst[1];
    }
}