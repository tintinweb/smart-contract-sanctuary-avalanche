// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";
import "./SafeMath.sol";

contract MonsterBattle {
    using SafeMath for uint256;

    struct Monster {
        uint256 battlePoints;
        uint256 battlesCount;
        uint256 battlesWon;
        uint256 lastBattleTimestamp;
    }

    mapping(uint256 => Monster) public monsters;
    mapping(uint256 => uint256) public battleEnergy;
    mapping(uint256 => uint256) public battleCounts; // Mapping to track the number of battles for each monster

    IERC721 public monsterNFT;
    IERC20 public customToken;
    mapping(uint256 => bool) public hasReceivedFreeEnergy;
    mapping(address => uint256[]) public ownedTokens;
    mapping(uint256 => bool) public blacklistedTokens; // Mapping to track blacklisted NFT IDs
    mapping(address => uint256) public lastBattleTimestamp;

    address public contractOwner;
    uint256 public battlePointsReward1; // Battle points reward for battleMonster1
    uint256 public battlePointsReward2; // Battle points reward for battleMonster2
    uint256 public battlePointsReward3; // Battle points reward for battleMonster3
    uint256 public battlePointsReward4; // Battle points reward for battleMonster4
    uint256 public battlePointsReward5; // Battle points reward for battleMonster5
    uint256 public battlePointsReward6; // Battle points reward for battleMonster6

    uint256[] public allTokens; // Array to store all NFT token IDs owned by the contract

    mapping(uint256 => uint256) public lastBattleEnergyReset; // Mapping to track the last battle energy reset timestamp

    constructor(
        address _nftAddress,
        address _tokenAddress,
        uint256 _battlePointsReward1,
        uint256 _battlePointsReward2,
        uint256 _battlePointsReward3,
        uint256 _battlePointsReward4,
        uint256 _battlePointsReward5,
        uint256 _battlePointsReward6
    ) {
        monsterNFT = IERC721(_nftAddress);
        customToken = IERC20(_tokenAddress);
        contractOwner = msg.sender; // Set the contract deployer as the owner
        battlePointsReward1 = _battlePointsReward1;
        battlePointsReward2 = _battlePointsReward2;
        battlePointsReward3 = _battlePointsReward3;
        battlePointsReward4 = _battlePointsReward4;
        battlePointsReward5 = _battlePointsReward5;
        battlePointsReward6 = _battlePointsReward6;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the owner of the contract can use this function");
        _;
    }

    function battleMonster1(uint256 tokenId) external {
        _battleMonster(tokenId, 90, battlePointsReward1); // 90% chance to win (randomNumberThreshold: 10)
    }

    function battleMonster2(uint256 tokenId) external {
        _battleMonster(tokenId, 75, battlePointsReward2); // 75% chance to win (randomNumberThreshold: 25)
    }

    function battleMonster3(uint256 tokenId) external {
        _battleMonster(tokenId, 55, battlePointsReward3); // 55% chance to win (randomNumberThreshold: 45)
    }

    function battleMonster4(uint256 tokenId) external {
        _battleMonster(tokenId, 30, battlePointsReward4); // 30% chance to win (randomNumberThreshold: 70)
    }

    function battleMonster5(uint256 tokenId) external {
        _battleMonster(tokenId, 15, battlePointsReward5); // 15% chance to win (randomNumberThreshold: 85)
    }

    function battleMonster6(uint256 tokenId) external {
        _battleMonster(tokenId, 5, battlePointsReward6); // 5% chance to win (randomNumberThreshold: 95)
    }


    function _battleMonster(uint256 tokenId, uint256 randomNumberThreshold, uint256 pointsReward) private {
        require(!blacklistedTokens[tokenId], "This NFT ID is blacklisted");
        Monster storage monster = monsters[tokenId];
        address monsterOwner = monsterNFT.ownerOf(tokenId); // Get the current owner of the monster

        if (lastBattleTimestamp[msg.sender] == 0) {
            lastBattleTimestamp[msg.sender] = block.timestamp; // Set the last battle timestamp for the player
        }

        if (block.timestamp >= lastBattleTimestamp[msg.sender] + 86400) {
            // Eligible for free energy
            battleEnergy[tokenId] = 5; // Set free energy to 5
            lastBattleTimestamp[msg.sender] = block.timestamp; // Update the last battle timestamp
        } else {
            require(battleEnergy[tokenId] > 0, "Not enough battle energy");
            battleEnergy[tokenId]--; // Consume 1 unit of battle energy
        }

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId))) % 100;

        if (randomNumber < randomNumberThreshold) {
            monster.battlePoints = pointsReward; // Set the battle points to the reward value
            monster.battlesWon++;
        }

        monster.battlesCount++;
        battleEnergy[tokenId]--;

        if (monster.battlesCount == 1) {
            monster.lastBattleTimestamp = block.timestamp;
            allTokens.push(tokenId); // Add the token ID to the allTokens array on the first battle
        }

        // Calculate additional token rewards based on the number of battles
        uint256 additionalRewardMultiplier = 100;
        uint256 battles = battleCounts[tokenId];
        if (battles >= 50 && battles < 100) {
            additionalRewardMultiplier = 25;
        } else if (battles >= 100 && battles < 150) {
            additionalRewardMultiplier = 50;
        } else if (battles >= 150 && battles < 200) {
            additionalRewardMultiplier = 75;
        } else if (battles >= 200 && battles < 250) {
            additionalRewardMultiplier = 100;
        } else if (battles >= 250) {
            additionalRewardMultiplier = 150;
        }

        // Calculate the total token reward
        uint256 totalReward = pointsReward * additionalRewardMultiplier;

        // Reward the player with custom tokens
        customToken.transfer(msg.sender, totalReward);

        // Return the monster to its owner
        monsterNFT.transferFrom(address(this), monsterOwner, tokenId);
    }

    function setBattleEnergy(uint256 tokenId, uint256 energy) external onlyOwner {
        require(energy <= 5, "Invalid battle energy"); // Maximum battle energy is 5
        battleEnergy[tokenId] = energy;
        if (monsters[tokenId].battlesCount == 0) {
            monsters[tokenId].lastBattleTimestamp = block.timestamp;
            allTokens.push(tokenId); // Add the token ID to the allTokens array on setting battle energy
        }
    }

    function setBattlePointsReward(uint256 monsterNumber, uint256 reward) external onlyOwner {
        if (monsterNumber == 1) {
            battlePointsReward1 = reward;
        } else if (monsterNumber == 2) {
            battlePointsReward2 = reward;
        } else if (monsterNumber == 3) {
            battlePointsReward3 = reward;
        } else if (monsterNumber == 4) {
            battlePointsReward4 = reward;
        } else if (monsterNumber == 5) {
            battlePointsReward5 = reward;
        } else if (monsterNumber == 6) {
            battlePointsReward6 = reward;
        } else {
            revert("Invalid monster number");
        }
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        contractOwner = newOwner;
    }

    function getBattleCount(uint256 tokenId) external view returns (uint256) {
        return monsters[tokenId].battlesCount;
    }

    function getBattleWins(uint256 tokenId) external view returns (uint256) {
        return monsters[tokenId].battlesWon;
    }

    function getUserNFTIds(address user) external view returns (uint256[] memory) {
    return ownedTokens[user];
    }

    function getNFTStats(uint256 tokenId) external view returns (uint256, uint256) {
        Monster storage monster = monsters[tokenId];
        uint256 battlesCount = monster.battlesCount;
        uint256 battlesWon = monster.battlesWon;
        uint256 winrate = 0;

        if (battlesCount > 0) {
            winrate = battlesWon.mul(100).div(battlesCount);
        }

        return (winrate, battlesCount);
    }

    function blacklistToken(uint256 tokenId) external onlyOwner {
        blacklistedTokens[tokenId] = true;
    }

    function unblacklistToken(uint256 tokenId) external onlyOwner {
        blacklistedTokens[tokenId] = false;
    }

    function resetBattlePointsAndCount(uint256 tokenId) public onlyOwner {
        Monster storage monster = monsters[tokenId];
        monster.battlePoints = 0;
        monster.battlesCount = 0;
        monster.battlesWon = 0;
    }

    function resetAllBattlePointsAndCount() external onlyOwner {
        for (uint256 i = 0; i < allTokens.length; i++) {
            resetBattlePointsAndCount(allTokens[i]);
        }
    }

    function setFreeEnergy(uint256 tokenId, uint256 energy) external onlyOwner {
        require(energy <= 5, "Invalid free energy"); // Maximum free energy is 5
        battleEnergy[tokenId] = energy;
        hasReceivedFreeEnergy[tokenId] = false; // Reset the flag indicating if the player has received free energy
    }

}