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
    IERC721 public monsterNFT;
    IERC20 public customToken;
    mapping(uint256 => bool) public hasReceivedFreeEnergy;
    mapping(address => uint256[]) public ownedTokens;
    mapping(uint256 => bool) public blacklistedTokens; // Mapping to track blacklisted NFT IDs

    address public contractOwner;
    uint256 public battlePointsReward1; // Battle points reward for battleMonster1
    uint256 public battlePointsReward2; // Battle points reward for battleMonster2
    uint256 public battlePointsReward3; // Battle points reward for battleMonster3
    uint256 public battlePointsReward4; // Battle points reward for battleMonster4

    uint256[] public allTokens; // Array to store all NFT token IDs owned by the contract

    uint256 public battleEnergyResetInterval = 1 days; // Interval to reset battle energy
    mapping(uint256 => uint256) public lastBattleEnergyReset; // Mapping to track the last battle energy reset timestamp

    constructor(address _nftAddress, address _tokenAddress, uint256 _battlePointsReward1, uint256 _battlePointsReward2, uint256 _battlePointsReward3, uint256 _battlePointsReward4) {
        monsterNFT = IERC721(_nftAddress);
        customToken = IERC20(_tokenAddress);
        contractOwner = msg.sender; // Set the contract deployer as the owner
        battlePointsReward1 = _battlePointsReward1;
        battlePointsReward2 = _battlePointsReward2;
        battlePointsReward3 = _battlePointsReward3;
        battlePointsReward4 = _battlePointsReward4;
    }

    modifier onlyOwner() {
        require(msg.sender == contractOwner, "Only the owner of the contract can use this function");
        _;
    }

    function battleMonster1(uint256 tokenId) external {
        _battleMonster(tokenId, 20, battlePointsReward1);
    }

    function battleMonster2(uint256 tokenId) external {
        _battleMonster(tokenId, 50, battlePointsReward2);
    }

    function battleMonster3(uint256 tokenId) external {
        _battleMonster(tokenId, 70, battlePointsReward3);
    }

    function battleMonster4(uint256 tokenId) external {
        _battleMonster(tokenId, 90, battlePointsReward4);
    }

    function _battleMonster(uint256 tokenId, uint256 randomNumberThreshold, uint256 pointsReward) private {
        require(!blacklistedTokens[tokenId], "This NFT ID is blacklisted");
        Monster storage monster = monsters[tokenId];
        address monsterOwner = monsterNFT.ownerOf(tokenId); // Get the current owner of the monster

        if (!hasReceivedFreeEnergy[tokenId]) {
            battleEnergy[tokenId] = 1; // Each battle consumes 1 unit of battle energy
            hasReceivedFreeEnergy[tokenId] = true;
        }

        require(battleEnergy[tokenId] > 0, "Not enough battle energy");

        monsterNFT.transferFrom(monsterOwner, address(this), tokenId);

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

        // Reward the player with custom tokens
        customToken.transfer(msg.sender, monster.battlePoints);

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
        } else {
            revert("Invalid monster number");
        }
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid new owner");
        contractOwner = newOwner;
    }

    function getAllBattlesCount() external view returns (uint256) {
        return allTokens.length;
    }

    function getBattleCount(uint256 tokenId) external view returns (uint256) {
        return monsters[tokenId].battlesCount;
    }

    function getBattleWins(uint256 tokenId) external view returns (uint256) {
        return monsters[tokenId].battlesWon;
    }

    function getBattlePoints(uint256 tokenId) external view returns (uint256) {
        return monsters[tokenId].battlePoints;
    }

    function getOwnedTokens(address owner) external view returns (uint256[] memory) {
        return ownedTokens[owner];
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

    function resetBattleEnergy(uint256 tokenId) external onlyOwner {
        battleEnergy[tokenId] = 0;
    }

    function resetAllBattleEnergy() external onlyOwner {
        for (uint256 i = 0; i < allTokens.length; i++) {
            battleEnergy[allTokens[i]] = 0;
        }
    }

    function setBattleEnergyResetInterval(uint256 interval) external onlyOwner {
        battleEnergyResetInterval = interval;
    }

    function resetLastBattleEnergyReset(uint256 tokenId) external onlyOwner {
        lastBattleEnergyReset[tokenId] = 0;
    }

    function resetAllLastBattleEnergyReset() external onlyOwner {
        for (uint256 i = 0; i < allTokens.length; i++) {
            lastBattleEnergyReset[allTokens[i]] = 0;
        }
    }
}