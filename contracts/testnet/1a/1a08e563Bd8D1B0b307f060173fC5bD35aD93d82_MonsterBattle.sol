// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC20.sol";

contract MonsterBattle {
    uint256 public POINTS_MULTIPLIER = 1000000000000000000;
    uint256 public constant MAX_BATTLES = 5;
    uint256 public constant BATTLE_COOLDOWN = 24 hours;

    struct Monster {
        uint256 battlePoints;
        uint256 battlesCount;
        uint256 lastBattleTimestamp;
    }

    mapping(uint256 => Monster) public monsters;
    mapping(uint256 => uint256) public battleEnergy;
    IERC721 public monsterNFT;
    IERC20 public customToken;

    constructor(address _nftAddress, address _tokenAddress) {
        monsterNFT = IERC721(_nftAddress);
        customToken = IERC20(_tokenAddress);
    }

    function battleMonster(uint256 tokenId) external {
        require(monsterNFT.ownerOf(tokenId) == msg.sender, "You are not the owner of this monster");
        require(monsters[tokenId].battlesCount < MAX_BATTLES, "Maximum battles reached for this monster");
        require(battleEnergy[tokenId] > 0, "Not enough battle energy");
        require(monsters[tokenId].battlePoints == 0, "Monster has already battled");

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId))) % 100;

        if (randomNumber < 50) {
            monsters[tokenId].battlePoints = 5;
        } else if (randomNumber < 75) {
            monsters[tokenId].battlePoints = 8;
        } else if (randomNumber < 90) {
            monsters[tokenId].battlePoints = 10;
        } else if (randomNumber < 99) {
            monsters[tokenId].battlePoints = 15;
        } else {
            monsters[tokenId].battlePoints = 25;
        }

        monsters[tokenId].battlesCount--;
        battleEnergy[tokenId]--;
        if (monsters[tokenId].battlesCount == 0) {
            monsters[tokenId].lastBattleTimestamp = block.timestamp;
        }

        // Reward the player with custom tokens
        uint256 rewardAmount = monsters[tokenId].battlePoints * POINTS_MULTIPLIER;
        customToken.transfer(msg.sender, rewardAmount);
    }

    function isBattleAvailable(uint256 tokenId) external view returns (bool) {
        Monster storage monster = monsters[tokenId];
        if (monster.battlesCount < MAX_BATTLES && battleEnergy[tokenId] > 0) {
            if (monster.battlesCount == 0) {
                return true;
            }
            uint256 cooldownEndTimestamp = monster.lastBattleTimestamp + BATTLE_COOLDOWN;
            return block.timestamp >= cooldownEndTimestamp;
        }
        return false;
    }

    function setPointsMultiplier(uint256 newMultiplier) external {
        POINTS_MULTIPLIER = newMultiplier;
    }

    function getMonsterBattlePoints(uint256 tokenId) external view returns (uint256) {
        require(monsters[tokenId].battlesCount > 0, "Monster hasn't battled yet");
        return monsters[tokenId].battlePoints;
    }
    
    function getBattleEnergy(uint256 tokenId) external view returns (uint256) {
        require(monsterNFT.ownerOf(tokenId) == msg.sender, "You are not the owner of this monster");
        return battleEnergy[tokenId];
    }

    function getBattleResult(uint256 tokenId) external view returns (uint256, uint256) {
        require(monsters[tokenId].battlesCount > 0, "Monster hasn't battled yet");
        return (monsters[tokenId].battlePoints, battleEnergy[tokenId]);
    }
}