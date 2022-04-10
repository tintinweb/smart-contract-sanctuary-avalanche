// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

import "./Ownable.sol";

interface IAttributesPets {
    struct Boost {
        // Ranger Boosts
        uint8 productionSpeed;
        uint8 claimTaxReduction;
        uint8[4] productionSpeedByNFTStaked;
        uint8 unstakeStealReduction;
        uint8 unstakeStealAugmentation;
        uint8 unstakeCooldownAugmentation;
        uint8[4] productionSpeedByTimeWithoutTransfer;

        // Wallet Boosts
        uint8 globalProductionSpeed;
        uint8 skeletonProbabilityAugmentation;
        uint8 skeletonProbabilityReduction;
        uint8 reMintProbabilityAugmentation;
        uint8 stolenProbabilityAugmentation;
        uint8 stolenProbabilityReduction;
        uint8 alphaAugmentation;
        uint8[4] globalProductionSpeedByNFTStaked;
        uint8 globalUnstakeStealAugmentation;
        uint8 globalUnstakeCooldownAugmentation;
    }

    function uploadBoosts(
        uint8[] calldata _petIds,
        Boost[] calldata _uploadedBoosts
    ) external;
}

contract BoostsUploader is Ownable {

    IAttributesPets attributesPets;
    IAttributesPets.Boost[101] private boosts;

    constructor(address _attributesPets) {
        setAttributesPets(_attributesPets);

        // Dogs
        boosts[1].productionSpeed = 2;
        boosts[2].productionSpeed = 2;
        boosts[3].productionSpeed = 5;
        boosts[4].productionSpeed = 10;
        boosts[5].productionSpeed = 5;
        boosts[6].productionSpeed = 2;
        boosts[7].productionSpeed = 2;
        boosts[8].productionSpeed = 2;
        boosts[9].productionSpeed = 5;
        boosts[10].productionSpeed = 10;
        boosts[11].productionSpeed = 15;
        
        // Cats
        boosts[12].claimTaxReduction = 2;
        boosts[13].claimTaxReduction = 2;
        boosts[14].claimTaxReduction = 2;
        boosts[15].claimTaxReduction = 15;
        boosts[16].claimTaxReduction = 2;
        boosts[17].claimTaxReduction = 5;
        boosts[18].claimTaxReduction = 10;
        boosts[19].claimTaxReduction = 2;
        boosts[20].claimTaxReduction = 10;
        boosts[21].claimTaxReduction = 5;

        // Mushrooms
        boosts[22].productionSpeedByNFTStaked = [2, 3, 4, 5];
        boosts[23].productionSpeedByNFTStaked = [5, 7, 8, 10];
        boosts[24].productionSpeedByNFTStaked = [10, 12, 13, 15];
        boosts[25].productionSpeedByNFTStaked = [10, 12, 13, 15];
        boosts[26].productionSpeedByNFTStaked = [15, 17, 18, 20];
        boosts[27].productionSpeedByNFTStaked = [15, 17, 18, 20];
        
        // Guardians
        boosts[28].unstakeStealReduction = 5;
        boosts[29].unstakeStealReduction = 20;
        boosts[30].unstakeStealReduction = 10;
        boosts[31].unstakeStealReduction = 20;
        boosts[32].unstakeStealReduction = 5;
        boosts[33].unstakeStealReduction = 30;

        // Racoons
        boosts[34].productionSpeedByTimeWithoutTransfer = [2, 3, 4, 5];
        boosts[35].productionSpeedByTimeWithoutTransfer = [2, 3, 4, 5];
        boosts[36].productionSpeedByTimeWithoutTransfer = [5, 7, 8, 10];

        // Foxes
        boosts[37].productionSpeedByTimeWithoutTransfer = [2, 3, 4, 5];
        boosts[38].productionSpeedByTimeWithoutTransfer = [2, 3, 4, 5];
        boosts[39].productionSpeedByTimeWithoutTransfer = [5, 7, 8, 10];
        boosts[40].productionSpeedByTimeWithoutTransfer = [10, 13, 17, 20];
        boosts[41].productionSpeedByTimeWithoutTransfer = [10, 13, 17, 20];

        // Wolfs
        boosts[42].productionSpeedByTimeWithoutTransfer = [2, 3, 4, 5];
        boosts[43].productionSpeedByTimeWithoutTransfer = [2, 3, 4, 5];
        boosts[44].productionSpeedByTimeWithoutTransfer = [2, 3, 4, 5];
        boosts[45].productionSpeedByTimeWithoutTransfer = [5, 7, 8, 10];
        boosts[46].productionSpeedByTimeWithoutTransfer = [10, 12, 13, 15];
        boosts[47].productionSpeedByTimeWithoutTransfer = [10, 13, 17, 20];

        // Crows
        boosts[48].productionSpeed = 5;
        boosts[48].unstakeStealAugmentation = 5;
        boosts[49].productionSpeed = 5;
        boosts[49].unstakeStealAugmentation = 5;
        boosts[50].productionSpeed = 15;
        boosts[50].unstakeStealAugmentation = 15;
        boosts[51].productionSpeed = 5;
        boosts[51].unstakeStealAugmentation = 5;
        boosts[52].productionSpeed = 10;
        boosts[52].unstakeStealAugmentation = 10;
        boosts[53].productionSpeed = 15;
        boosts[53].unstakeStealAugmentation = 15;

        // Golems
        boosts[54].productionSpeed = 5;
        boosts[54].unstakeCooldownAugmentation = 100;
        boosts[55].productionSpeed = 10;
        boosts[55].unstakeCooldownAugmentation = 100;
        boosts[56].productionSpeed = 10;
        boosts[56].unstakeCooldownAugmentation = 100;
        boosts[57].productionSpeed = 20;
        boosts[57].unstakeCooldownAugmentation = 100;
        boosts[58].productionSpeed = 15;
        boosts[58].unstakeCooldownAugmentation = 100;
        boosts[59].productionSpeed = 15;
        boosts[59].unstakeCooldownAugmentation = 15;
        boosts[60].productionSpeed = 5;
        boosts[60].unstakeCooldownAugmentation = 100;
        boosts[61].productionSpeed = 10;
        boosts[61].unstakeCooldownAugmentation = 100;
        boosts[62].productionSpeed = 10;
        boosts[62].unstakeCooldownAugmentation = 100;

        // Blue lion
        boosts[63].claimTaxReduction = 15;

        // Ferret
        boosts[64].unstakeStealReduction = 20;
        
        // Squirrels
        boosts[65].productionSpeed = 5;
        boosts[65].unstakeStealAugmentation = 5;
        boosts[66].productionSpeed = 5;
        boosts[66].unstakeStealAugmentation = 5;
        boosts[67].productionSpeed = 5;
        boosts[67].unstakeStealAugmentation = 5;
        boosts[68].productionSpeed = 10;
        boosts[68].unstakeStealAugmentation = 10;

        // Bears
        boosts[69].productionSpeedByNFTStaked = [2, 3, 4, 5];
        boosts[70].productionSpeedByNFTStaked = [5, 7, 8, 10];
        boosts[71].productionSpeedByNFTStaked = [10, 12, 13, 15];
        boosts[72].productionSpeedByNFTStaked = [10, 12, 13, 15];
        boosts[73].productionSpeedByNFTStaked = [15, 17, 18, 20];

        // Boars
        boosts[74].productionSpeed = 2;
        boosts[75].productionSpeed = 2;
        boosts[76].productionSpeed = 2;
        boosts[77].productionSpeed = 5;
        boosts[78].productionSpeed = 10;
        boosts[79].productionSpeed = 15;

        // Owls
        boosts[80].productionSpeed = 5;
        boosts[80].unstakeStealAugmentation = 5;
        boosts[81].productionSpeed = 10;
        boosts[81].unstakeStealAugmentation = 10;
        boosts[82].productionSpeed = 5;
        boosts[82].unstakeStealAugmentation = 5;

        // Frogs
        boosts[83].productionSpeed = 5;
        boosts[83].unstakeStealAugmentation = 5;
        boosts[84].productionSpeed = 10;
        boosts[84].unstakeStealAugmentation = 10;
        boosts[85].productionSpeed = 15;
        boosts[85].unstakeStealAugmentation = 15;
        boosts[86].productionSpeed = 20;
        boosts[86].unstakeStealAugmentation = 20;
        
        // deers
        boosts[87].productionSpeed = 5;
        boosts[87]. unstakeCooldownAugmentation = 100;
        
        boosts[88].productionSpeed = 10;
        boosts[88]. unstakeCooldownAugmentation = 100;

        boosts[89].productionSpeed = 15;
        boosts[89]. unstakeCooldownAugmentation = 100;

        boosts[90].productionSpeed = 20;
        boosts[90]. unstakeCooldownAugmentation = 100;

        // Dragon
        boosts[91].globalProductionSpeed = 20;

        // Underground worm
        boosts[92].skeletonProbabilityAugmentation = 10;

        // Underground beetle
        boosts[93].skeletonProbabilityAugmentation = 20;
        boosts[93].stolenProbabilityAugmentation = 10;

        // Temple phoenix
        boosts[94].stolenProbabilityReduction = 10;

        // Underground Bee 
        boosts[95].skeletonProbabilityReduction = 5;
        boosts[95].stolenProbabilityReduction = 5;

        // Underground Shark
        boosts[96].globalProductionSpeedByNFTStaked = [10, 12, 20, 25];

        // Underground Snake
        boosts[97].globalProductionSpeed = 25;
        boosts[97].globalUnstakeCooldownAugmentation = 200;
        

        // Underground Bull
        boosts[98].globalProductionSpeed = 25;
        boosts[98].globalUnstakeStealAugmentation = 50;

        // Underground T-Rex
        boosts[99].alphaAugmentation = 1;

        // Underground Rabbit
        boosts[100].reMintProbabilityAugmentation = 15;

    }

    function setAttributesPets(address _attributesPets) public onlyOwner {
        attributesPets = IAttributesPets(_attributesPets);
    }

    IAttributesPets.Boost[] boostsToSend;
    uint8[] petIds;

    function uploadBoosts(uint8 start, uint8 end) external onlyOwner {
        delete boostsToSend;
        delete petIds;
        for (uint8 i = start; i < end;) {
            petIds.push(i);
            boostsToSend.push(boosts[i]);
            unchecked{++i;}
        }
        attributesPets.uploadBoosts(petIds, boostsToSend);
    }
}