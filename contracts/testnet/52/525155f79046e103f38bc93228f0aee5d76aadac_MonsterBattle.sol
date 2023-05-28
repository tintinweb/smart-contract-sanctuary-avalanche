// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC20.sol";

contract MonsterBattle {
    uint256 public constant POINTS_MULTIPLIER = 100;
    uint256 public constant MAX_BATTLE_ENERGY = 5;
    uint256 public constant BATTLE_ENERGY_RECHARGE_TIME = 4 hours;

    struct Monster {
        uint256 battlePoints;
        uint256 battlesCount;
        uint256 lastBattleTimestamp;
        uint256 nextRechargeTimestamp;
        bool hasClaimedEnergy;
    }

    mapping(uint256 => Monster) public monsters;
    IERC721 public monsterNFT;
    IERC20 public customToken;

    constructor(address _nftAddress, address _tokenAddress) {
        monsterNFT = IERC721(_nftAddress);
        customToken = IERC20(_tokenAddress);
    }

    function insertNFT(uint256 tokenId) external {
    require(monsterNFT.ownerOf(tokenId) == msg.sender, "You are not the owner of this monster");
    require(!monsters[tokenId].hasClaimedEnergy, "Energy already claimed for this monster");

    monsterNFT.transferFrom(msg.sender, address(this), tokenId);
    monsters[tokenId].hasClaimedEnergy = true;
    monsters[tokenId].nextRechargeTimestamp = block.timestamp + BATTLE_ENERGY_RECHARGE_TIME;
}


    function battleMonster(uint256 tokenId) external {
        require(monsters[tokenId].battlePoints == 0, "Monster has already battled");

        uint256 currentTimestamp = block.timestamp;
        require(currentTimestamp >= monsters[tokenId].nextRechargeTimestamp, "Battle energy needs to recharge");

        uint256 randomNumber = uint256(keccak256(abi.encodePacked(currentTimestamp, msg.sender, tokenId))) % 100;

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

        monsters[tokenId].battlesCount++;
        monsters[tokenId].nextRechargeTimestamp = currentTimestamp + BATTLE_ENERGY_RECHARGE_TIME;

        // Reward the player with custom tokens
        uint256 rewardAmount = monsters[tokenId].battlePoints * POINTS_MULTIPLIER;
        customToken.transfer(msg.sender, rewardAmount);
    }

    function getMonsterBattlePoints(uint256 tokenId) external view returns (uint256) {
        require(monsters[tokenId].battlesCount > 0, "Monster hasn't battled yet");
        return monsters[tokenId].battlePoints;
    }

    function withdrawNFT(uint256 tokenId) external {
        require(monsters[tokenId].battlePoints > 0, "Monster hasn't battled or has already been withdrawn");
        require(monsterNFT.ownerOf(tokenId) == msg.sender, "You are not the owner of this monster");

        monsterNFT.transferFrom(address(this), msg.sender, tokenId);
    }

    function isBattleAvailable(uint256 /* tokenId */) external pure returns (bool) {
    return true;
    }

}