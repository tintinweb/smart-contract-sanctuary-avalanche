// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./IERC20.sol";
import "./IPrizeBond.sol";
import "./IPool.sol";

library LMyChance {
    struct SpecialLottery {
        bool valid;
        bool drawn;
        IPrizeBond.Assets assetType;
        uint256 total;
        string description;
        uint256 winner;
    }

    struct PrizeBondPosition {
        uint index;
        uint weight;
    }

    function claimInternal(uint256 total, address token, address charity, uint256 _percentage) internal returns(uint256 withdrawlAmount, uint256 _totalFees, uint256 totalToCharity) {
        totalToCharity = total * 20 / 100;
        _totalFees = total * 45 / 100;
        uint256 totalWinner = total * 35 / 100;
        uint256 extraToCharity = totalWinner * _percentage / 100;
        totalToCharity += extraToCharity;
        // Platform's fees remain in the AAVE pool
        uint256 withdrawalAmount = total - _totalFees;
        require(IERC20(token).transfer(msg.sender, (withdrawalAmount - totalToCharity)), 'Transfer failed');
        require(IERC20(token).transfer(charity, totalToCharity), 'Transfer failed');
        return (withdrawlAmount, _totalFees, totalToCharity);
    }

    function removeTicket(mapping(uint256 => PrizeBondPosition) storage prizeBondPositions, uint256[] storage prizeBonds, uint256 _tokenId) external returns (uint256) {
        PrizeBondPosition memory deletedTicket = prizeBondPositions[_tokenId];
        if (deletedTicket.index != prizeBonds.length-1) {
            uint256 lastTokenId = prizeBonds[prizeBonds.length-1];
            prizeBonds[deletedTicket.index] = lastTokenId;
            prizeBondPositions[lastTokenId].index = deletedTicket.index;
        }
        delete prizeBondPositions[_tokenId];
        prizeBonds.pop();
        return deletedTicket.weight;
    }

    function mint (IPrizeBond prizeBond, IPrizeBond.Assets _assetType, uint weight, mapping(uint256 => uint256) storage mintingDate, uint256[] storage prizeBonds, mapping(uint256 => PrizeBondPosition) storage prizeBondPositions) external {
        uint256 tokenId = prizeBond.safeMint(msg.sender, _assetType);
        mintingDate[tokenId] = block.timestamp;
        prizeBonds.push(tokenId);
        prizeBondPositions[tokenId].weight = weight;
        prizeBondPositions[tokenId].index = prizeBonds.length - 1;
    }

    function addSpecialLottery(address token, uint256 _total, IPrizeBond.Assets _assetType, mapping(uint256=>LMyChance.SpecialLottery) storage specialLotteries, uint256 _drawDate, string memory _description) external {
        require(IERC20(token).transferFrom(msg.sender, address(this), _total), 'Transfer failed');
        SpecialLottery memory specialLottery;
        specialLottery.valid = true;
        specialLottery.assetType = _assetType;
        specialLottery.total = _total;
        specialLottery.description = _description;
        specialLotteries[_drawDate] = specialLottery;
    }

    function winner_index(uint256 _random, uint256[] memory prizeBonds, mapping(uint256 => PrizeBondPosition) storage prizeBondPositions, uint256 sumWeights) external view returns (uint256) {
        uint256 count= _random % sumWeights;
        uint256 i=0;
        while(count>0){
            if(count<prizeBondPositions[prizeBonds[i]].weight)
                break;
            count-=prizeBondPositions[prizeBonds[i]].weight;
            i++;
        }
        return i;
    }
}