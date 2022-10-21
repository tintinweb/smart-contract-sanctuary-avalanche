/**
 *Submitted for verification at snowtrace.io on 2022-10-21
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface ILotto {
    function lottoHistory(uint256 lottoID) external view returns(
        address,// winner;
        uint256,// amountWon;
        uint256,// winningTicket;
        uint256 //timestamp;
    );
    function currentLottoID() external view returns (uint256);
}

contract LottoHistoryViewer {

    ILotto private immutable lotto;

    constructor(address lotto_) {
        lotto = ILotto(lotto_);
    }

    function currentLottoID() public view returns (uint256) {
        return lotto.currentLottoID();
    }

    function getLottoHistory(uint id) public view returns (address, uint, uint, uint) {
        return lotto.lottoHistory(id);
    }

    function getPastWinnersAmountsAndTimesSE(uint start, uint end) external view returns (address[] memory, uint256[] memory, uint256[] memory) {
        address[] memory winners = new address[]( start - end + 1);
        uint256[] memory amounts = new uint256[](start - end + 1);
        uint256[] memory times = new uint256[]( start - end + 1);

        uint count = 0;
        for (uint i = start; i >= end;) {
            (address winner, uint amount, , uint timestamp) = getLottoHistory(i);
            winners[count] = winner;
            amounts[count] = amount;
            times[count] = timestamp;
            count++;
            if (i == 0) {
                break;
            } else {
                unchecked { i--; }
            }
        }
        return (winners, amounts, times);
    }

    function getPastWinnersAmountsAndTimes(uint256 numWinners) external view returns (address[] memory, uint256[] memory, uint256[] memory) {
        address[] memory winners = new address[](numWinners);
        uint256[] memory amounts = new uint256[](numWinners);
        uint256[] memory times = new uint256[](numWinners);

        uint id = lotto.currentLottoID();
        if (id < numWinners || numWinners == 0) {
            return (winners, amounts, times);
        }
        uint count = 0;
        uint start = id - 1;
        uint end = id - numWinners;
        for (uint i = start; i >= end;) {
            (address winner, uint256 amount, ,uint256 timestamp) = getLottoHistory(i);
            winners[count] = winner;
            amounts[count] = amount;
            times[count] = timestamp;
            count++;
            if (i == 0) {
                break;
            } else {
                unchecked { i--; }
            }
        }
        return (winners, amounts, times);
    }
}