// SPDX-License-Identifier: MIT
/**
* ______              ______                  ______                           _     
* |  ___|             |  ___|                 | ___ \                         | |    
* | |_ _ __ ___   __ _| |_ _ __ ___ _ __  ___ | |_/ /_____      ____ _ _ __ __| |___ 
* |  _| '__/ _ \ / _` |  _| '__/ _ \ '_ \/ __||    // _ \ \ /\ / / _` | '__/ _` / __|
* | | | | | (_) | (_| | | | | |  __/ | | \__ \| |\ \  __/\ V  V / (_| | | | (_| \__ \
* \_| |_|  \___/ \__, \_| |_|  \___|_| |_|___/\_| \_\___| \_/\_/ \__,_|_|  \__,_|___/
*                 __/ |                                                              
*                |___/                                                                                                                                           
*/

import "./Context.sol";
import "./Ownable.sol";
import "./Address.sol";

pragma solidity 0.8.3;

interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address account, uint256 amount) external;
    function deposit() external payable;
    function withdraw(uint256) external;
}

interface ERC721 {
    function ownerOf(uint256 tokenId) external returns (address);
}

interface StakingInterface {
    function nftDepositor(uint256 tokenId) external returns (address);
}

/// @title Rewards for Non-Fungible Tokens
/// @dev Contract for the split between community rewards and dev rewards
///
contract FrogFrensRewards is Ownable {
    uint256 public communityClaimed = 0;
    uint256 public creatorClaimed = 0;

    uint256 public creatorRewards = 0; // percentage from total NFT price
    uint256 public communityRewards = 100; // percentage from total NFT price

    uint256 public collectionSize = 5555;

    address public wavaxTokenFeesAddress; // WAVAX token address
    address public creatorAddress; // the creator address
    address public collectionAddress; // the collection address
    address public stakingAddress = address(0); // the staking contract address
    
    bool public claimActive = true;
    
    mapping(uint256 => uint256) private communityClaims;
    mapping(address => uint256) private addressClaims;

    event CommunityClaimed(address owner, uint256 amount, uint256 tokenID);
    event CreatorClaimed(uint256 amount);
    event RewardsCreated(address collectionAddress);

    constructor(
        address _wavaxTokenFeesAddress,
        address _creatorAddress,
        address _collectionAddress,
        uint256 _collectionSize
    ) {
        wavaxTokenFeesAddress = _wavaxTokenFeesAddress;
        creatorAddress = _creatorAddress;
        collectionAddress = _collectionAddress;
        collectionSize = _collectionSize;
        emit RewardsCreated(collectionAddress);
    }
    
    /// @dev set rewards address (wavax)
    function setWavaxTokenFeesAddress(address _wavaxTokenFeesAddress) external onlyOwner {
        wavaxTokenFeesAddress = _wavaxTokenFeesAddress;
    }

    /// @dev set creator address, can be another contract
    function setCreatorAddress(address _creatorAddress) external onlyOwner {
        creatorAddress = _creatorAddress;
    }

    /// @dev set new collection size.  Only smaller collection size, can't increase size
    function setCollectionSize(uint256 _collectionSize) external onlyOwner {
        require(_collectionSize < collectionSize, 'Cannot increase collection size');
        collectionSize = _collectionSize;
    }

    /// @dev set creator rewards
    function setCreatorRewards(uint256 _creatorRewards) external onlyOwner {
        creatorRewards = _creatorRewards;
    }

    /// @dev set creator rewards
    function setCommunityRewards(uint256 _communityRewards) external onlyOwner {
        communityRewards = _communityRewards;
    }

    /// @dev set staking address
    function setStakingAddress(address _stakingAddress) external onlyOwner {
        stakingAddress = _stakingAddress;
    }
    /// @dev set claim active
    function setClaimActive(bool value) public onlyOwner {
        claimActive = value;
    }

    /// @dev get total rewards
    /// @return total rewards
    function getTotalRewards() public view returns (uint256) {
        return creatorRewards + communityRewards;
    }

    /// @dev get rewards split
    /// @return creator roylaties
    /// @return community rewards
    function getRewards() public view returns (uint256, uint256) {
        return (creatorRewards, communityRewards);
    }

    /// @dev get total collected
    /// @return total collected
    function getTotalCollected() public view returns (uint256) {
        uint256 balance = ERC20(wavaxTokenFeesAddress).balanceOf(address(this));
        return balance + creatorClaimed + communityClaimed;
    }

    /// @dev get creator balance
    /// @return creator total balance
    function getCreatorBalance() public view returns (uint256) {
        uint256 _creatorRewards = (creatorRewards * 100) / getTotalRewards();
        return (getTotalCollected() * _creatorRewards) / 100 - creatorClaimed;
    }

    /// @dev get single token total rewards
    /// @return single token rewards
    function getTokenTotalRewards() public view returns (uint256) {
        uint256 _communityRewards = (communityRewards * 100) / getTotalRewards();
        return ((getTotalCollected() * _communityRewards) / 100) / collectionSize;
    }

    /// @dev get single token balance
    /// @return single token balance
    function getTokenBalance(uint256 tokenID) public view returns (uint256) {
        return getTokenTotalRewards() - communityClaims[tokenID];
    }

    /// @dev get token balances for each token from an array of tokenIDs
    function getTokensBalance(uint256[] memory tokenIDs) public view returns (uint256) {
        uint256 totalBalance = 0;
        for (uint256 i = 0; i<tokenIDs.length; i++) {
            uint256 balance = getTokenBalance(tokenIDs[i]);
            totalBalance = (totalBalance + balance);
        }
        return totalBalance;
    }

    /// @dev get address tot claims
    /// @return address total claims
    function getAddressClaims(address account) public view returns (uint256) {
        return addressClaims[account];
    }

    /// @dev claim community rewards per token id
    function claimCommunity(uint256 tokenID) public {
        if (claimActive == true) {
            uint256 balance = getTokenBalance(tokenID);
            if (balance > 0) {
                address owner = ERC721(collectionAddress).ownerOf(tokenID);
                if (stakingAddress != address(0)) {
                    address staker = StakingInterface(stakingAddress).nftDepositor(tokenID);
                    if (staker != address(0)) { 
                        ERC20(wavaxTokenFeesAddress).transfer(staker, balance);
                        communityClaims[tokenID] = communityClaims[tokenID] + balance;
                        addressClaims[staker] = addressClaims[staker] + balance;
                        communityClaimed = communityClaimed + balance;
                        emit CommunityClaimed(staker, balance, tokenID);
                    } else if (owner != address(0)) {
                        ERC20(wavaxTokenFeesAddress).transfer(owner, balance);
                        communityClaims[tokenID] = communityClaims[tokenID] + balance;
                        addressClaims[owner] = addressClaims[owner] + balance;
                        communityClaimed = communityClaimed + balance;
                        emit CommunityClaimed(owner, balance, tokenID);
                    }
                } else if (owner != address(0)) {
                        ERC20(wavaxTokenFeesAddress).transfer(owner, balance);
                        communityClaims[tokenID] = communityClaims[tokenID] + balance;
                        addressClaims[owner] = addressClaims[owner] + balance;
                        communityClaimed = communityClaimed + balance;
                        emit CommunityClaimed(owner, balance, tokenID);
                }
            }
        }
    }

    /// @dev claim community from an array of tokenIDs
    function claimCommunityBatch(uint256[] calldata tokenIDs) external {
        for (uint256 i=0; i<tokenIDs.length; i++) {
            claimCommunity(tokenIDs[i]);
        }
    }

    /// @dev claim creator rewards
    function claimCreator() external {
        require(msg.sender == creatorAddress, "Only creator can claim");
        uint256 balance = getCreatorBalance();
        require(balance > 0, "No balance to claim");
        ERC20(wavaxTokenFeesAddress).transfer(creatorAddress, balance);
        creatorClaimed = creatorClaimed + balance;
        emit CreatorClaimed(balance);
    }

    /// @dev transfer a ERC20 token to address
    function withdrawToken(ERC20 token, address recipient, uint256 amount) public onlyOwner {
        token.transfer(recipient, amount);
    }

    /// @dev function to receive AVAX. msg.data must be empty
    receive() external payable {
        uint256 contractBalance = address(this).balance;
        ERC20(wavaxTokenFeesAddress).deposit{ value: contractBalance }();
    }

    /// @dev fallback function is called when msg.data is not empty
    fallback() external payable {}

}