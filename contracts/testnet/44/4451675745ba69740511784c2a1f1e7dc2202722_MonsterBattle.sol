// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC20.sol";

contract MonsterBattle {
    uint256 public constant POINTS_MULTIPLIER = 1000000000000000000;
    uint256 public constant MAX_BATTLE_ENERGY = 5;
    uint256 public constant ENERGY_RECHARGE_TIME = 4 hours;

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
        battleEnergy[tokenId] = MAX_BATTLE_ENERGY;
        hasReceivedFreeEnergy[tokenId] = true;
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
    if (monster.battlesCount == 1) {
        monster.lastBattleTimestamp = block.timestamp;
    }

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
        require(energy <= MAX_BATTLE_ENERGY, "Invalid battle energy");
        battleEnergy[tokenId] = energy;
        if (monsters[tokenId].battlesCount == 0) {
            monsters[tokenId].lastBattleTimestamp = block.timestamp;
        }
    }

    function getBattleEnergy(uint256 tokenId) external view returns (uint256) {
        require(monsterNFT.ownerOf(tokenId) == msg.sender, "You are not the owner of this monster");
        return battleEnergy[tokenId];
    }

    function isBattleAvailable(uint256 tokenId) external view returns (bool) {
        Monster storage monster = monsters[tokenId];
        if (monster.battlesCount < MAX_BATTLE_ENERGY && battleEnergy[tokenId] > 0) {
            if (monster.battlesCount == 0) {
                return true;
            }
            uint256 rechargeTimestamp = monster.energyTimestamp + ENERGY_RECHARGE_TIME;
            return block.timestamp >= rechargeTimestamp;
        }
        return false;
    }
}