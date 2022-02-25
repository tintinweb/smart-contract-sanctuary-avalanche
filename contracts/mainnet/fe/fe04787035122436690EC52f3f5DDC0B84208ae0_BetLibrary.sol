// Copyright 2021 Binary Cat Ltd.

// SPDX-License-Identifier: Apache-2.0
// Licensed under the Apache License, Version 2.0 (the "License"); you may not use
// this file except in compliance with the License. You may obtain a copy of the
// License at http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software distributed
// under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

pragma solidity ^0.8.0;

library BetLibrary {
    //Structs and enums
    enum BetSide {
        down,
        up
    }
    enum BetResult {
        down,
        up,
        tie
    }
    enum WindowStatus {
        notFinalized,
        waitingPrice,
        failedUpdate,
        finalized
    }

    struct Pool {
        uint256 downValue;
        uint256 upValue;
    }

    struct User {
        mapping(uint256 => Pool) stake;
        uint256[] bets;
    }



    function windowStatus(
        uint256 window,
        uint256 currentWindow,
        uint256 initialPrice,
        uint256 finalPrice
    ) public pure returns (WindowStatus status) {
        if (currentWindow < window + 2) {
            //window not yet settled
            return WindowStatus.notFinalized;
        } else if (currentWindow < window + 3 && finalPrice == 0) {
            //price not updated but update still possible.
            return WindowStatus.waitingPrice;
        } else if (initialPrice == 0 || finalPrice == 0) {
            return WindowStatus.failedUpdate;
        } else {
            return WindowStatus.finalized;
        }
    }

    function betResultBinary(uint256 referencePrice, uint256 settlementPrice)
        public
        pure
        returns (uint8)
    {
        if (settlementPrice < referencePrice) {
            return 0;
        } else if (settlementPrice > referencePrice) {
            return 1;
        }
        return 2;
    }

    function sharePool(
        uint256 value,
        uint256 shares,
        uint256 totalShares
    ) internal pure returns (uint256) {
        return (shares * value) / totalShares;
    }


    function getWindowNumber(
        uint256 currentTimestamp,
        uint256 _windowDuration,
        uint256 _deployTimestamp
    ) public pure returns (uint256 windowNumber) {
        //n = floor((currentTimestamp - deployTimestamp)/windowDuration  + 1)
        windowNumber =
            ((currentTimestamp - _deployTimestamp) / _windowDuration)
            + 1; //integer division => floor
    }

    function getWindowStartingTimestamp(
        uint256 windowNumber,
        uint256 _windowDuration,
        uint256 _currentTimestamp
    ) public pure returns (uint256 startingTimestamp) {
        //deployTimestamp + (n-1 - (offset + 1))*windowDuration
        startingTimestamp =
            _currentTimestamp +
            (windowNumber - 1) *
            _windowDuration;
    }

    function computeFee(uint256 value, uint256 _fee)
        public
        pure
        returns (uint256 betFee)
    {
        betFee = (value * _fee) / 100;
    }

    function computeFeeCapped(uint256 value, uint256 _fee, uint cap)
        public
        pure
        returns (uint256 betFee)
    {
        if ( (value * _fee) / 100 < cap) {
            betFee = (value * _fee) / 100;
        }
        else {
            betFee = cap;
        }
    }
}