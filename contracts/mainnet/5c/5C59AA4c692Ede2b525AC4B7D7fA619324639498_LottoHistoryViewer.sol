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

    ILotto private constant lotto = ILotto(0x30c0328A9b427E7450DBB625f977F914D46AC5b5);

    function getPastWinnersAmountsAndTimes(uint256 numWinners) external view returns (address[] memory, uint256[] memory, uint256[] memory) {
        address[] memory winners = new address[](numWinners);
        uint256[] memory amounts = new uint256[](numWinners);
        uint256[] memory times = new uint256[](numWinners);

        uint currentLottoID = lotto.currentLottoID();
        if (currentLottoID < numWinners || numWinners == 0) {
            return (winners, amounts, times);
        }
        uint count = 0;
        for (uint i = currentLottoID-1; i > currentLottoID - numWinners;) {
            (address winner, uint amount, uint timestamp,) = lotto.lottoHistory(i);
            winners[count] = winner;
            amounts[count] = amount;
            times[count] = timestamp;
            unchecked { --i; count++; }
        }
        return (winners, amounts, times);
    }
}