// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";

contract MonsterBattle {
    uint256 public constant POINTS_MULTIPLIER = 1000000000000000000;
    uint256 public constant ENERGY_RECHARGE_TIME = 1 minutes;

    struct Monster {
        uint256 battlePoints;
        uint256 battlesCount;
        uint256 lastBattleTimestamp;
        uint256 energyTimestamp;
    }

    mapping(uint256 => Monster) public monsters;
    mapping(uint256 => uint256) public battleEnergy;
    IERC721 public monsterNFT;
    IERC20 public customToken;
    mapping(uint256 => bool) public hasReceivedFreeEnergy;
    mapping(address => uint256[]) public ownedTokens;

    constructor(address _nftAddress, address _tokenAddress) {
        monsterNFT = IERC721(_nftAddress);
        customToken = IERC20(_tokenAddress);
    }

    function battleMonster(uint256 tokenId) external {
        Monster storage monster = monsters[tokenId];
        address owner = monsterNFT.ownerOf(tokenId); // Get the current owner of the monster

        if (!hasReceivedFreeEnergy[tokenId]) {
            battleEnergy[tokenId] = 1;
            hasReceivedFreeEnergy[tokenId] = true;
            monster.energyTimestamp = block.timestamp;
        }

        require(battleEnergy[tokenId] > 0, "Not enough battle energy");

        monsterNFT.transferFrom(owner, address(this), tokenId);

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, tokenId))) % 100;

        if (randomNumber < 50) {
            monster.battlePoints = 5;
        } else if (randomNumber < 75) {
            monster.battlePoints = 8;
        } else if (randomNumber < 90) {
            monster.battlePoints = 10;
        } else if (randomNumber < 99) {
            monster.battlePoints = 15;
        } else {
            monster.battlePoints = 25;
        }

        monster.battlesCount++;
        battleEnergy[tokenId]--;
        monster.lastBattleTimestamp = block.timestamp;

        // Reward the player with custom tokens
        uint256 rewardAmount = monster.battlePoints * POINTS_MULTIPLIER;
        customToken.transfer(msg.sender, rewardAmount);

        // Return the monster to its owner
        monsterNFT.transferFrom(address(this), owner, tokenId);
    }

    function getMonsterBattlePoints(uint256 tokenId) external view returns (uint256) {
        require(monsters[tokenId].battlesCount > 0, "Monster hasn't battled yet");
        return monsters[tokenId].battlePoints;
    }

    function setBattleEnergy(uint256 tokenId, uint256 energy) external {
        require(monsterNFT.ownerOf(tokenId) == msg.sender, "You are not the owner of this monster");
        require(energy > 0, "Invalid battle energy");

        Monster storage monster = monsters[tokenId];
        monster.energyTimestamp = block.timestamp;
        battleEnergy[tokenId] = energy;
    }

    function getBattleEnergy(uint256 tokenId) external view returns (uint256) {
        require(monsterNFT.ownerOf(tokenId) == msg.sender, "You are not the owner of this monster");

        Monster storage monster = monsters[tokenId];
        uint256 elapsedTime = block.timestamp - monster.energyTimestamp;
        uint256 rechargeCount = elapsedTime / ENERGY_RECHARGE_TIME;
        uint256 currentEnergy = battleEnergy[tokenId] + rechargeCount;

        if (currentEnergy > 1) {
            return 1;
        }

        return currentEnergy;
    }

    function isBattleAvailable(uint256 tokenId) external view returns (bool) {
        Monster storage monster = monsters[tokenId];
        uint256 elapsedTime = block.timestamp - monster.energyTimestamp;
        uint256 rechargeCount = elapsedTime / ENERGY_RECHARGE_TIME;
        uint256 currentEnergy = battleEnergy[tokenId] + rechargeCount;

        return currentEnergy > 0;
    }

    function getMonsterBattlePointsHistory(uint256 tokenId) external view returns (uint256) {
        require(monsters[tokenId].battlesCount > 0, "Monster hasn't battled yet");

        uint256 totalBattlePoints = monsters[tokenId].battlePoints * monsters[tokenId].battlesCount;

        return totalBattlePoints;
    }

}