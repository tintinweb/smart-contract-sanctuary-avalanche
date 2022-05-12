// SPDX-License-Identifier: MIT
/**
* ______              ______                   _____ _        _    _             
* |  ___|             |  ___|                 /  ___| |      | |  (_)            
* | |_ _ __ ___   __ _| |_ _ __ ___ _ __  ___ \ `--.| |_ __ _| | ___ _ __   __ _ 
* |  _| '__/ _ \ / _` |  _| '__/ _ \ '_ \/ __| `--. \ __/ _` | |/ / | '_ \ / _` |
* | | | | | (_) | (_| | | | | |  __/ | | \__ \/\__/ / || (_| |   <| | | | | (_| |
* \_| |_|  \___/ \__, \_| |_|  \___|_| |_|___/\____/ \__\__,_|_|\_\_|_| |_|\__, |
*                 __/ |                                                     __/ |
*                |___/                                                     |___/ 
*/

import "./Context.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC165.sol";
import "./IERC721Receiver.sol";
import "./ERC721Holder.sol";
import "./IERC721.sol";
import "./Pausable.sol";

pragma solidity 0.8.3;

contract FrogFrensStaking is Ownable, Pausable {
    using SafeMath for uint256;
    using SafeMath for uint16;

    struct User {
        uint256 totalNFTDeposited;
        uint256 lastClaimTime;
        uint256 lastDepositTime;
        uint256 totalClaimed;
    }

    struct Pool {
        uint256 rewardPerNFT;
        uint256 rewardInterval;
        uint256 lockPeriodInDays;
        uint256 totalDeposit;
        uint256 totalSpawnDistributed;
        uint256 startDate;
        uint256 endDate;
    }

    IERC20 private token;
    IERC721 private nft;

    mapping(address => User) public users;
    mapping(uint256 => address) public nftDepositor;
    mapping(address => uint256[]) internal stakerToTokenIds;

    Pool public poolInfo;
    uint256[] public nftsDeposited;

    event Stake(address indexed addr, uint256 amount);
    event Claim(address indexed addr, uint256 amount);

    constructor(address _spawnAddress, address _nftAddress) {
        token = IERC20(_spawnAddress);
        nft = IERC721(_nftAddress);

        poolInfo.lockPeriodInDays = 1; //1 day lock
        poolInfo.startDate = block.timestamp;
        poolInfo.endDate = block.timestamp + 3650 days; //Staking ends in ten years
        poolInfo.rewardPerNFT = 2 * 10**18; //2 token per NFT as reward
        poolInfo.rewardInterval = 1 hours; //2 token per hour per NFT

        // Rewards equal 48 tokens per day
        // 75% of 500M is 375M
        // 375M tokens distributed across 5,555 NFTs = 67,506 per NFT 
        // 67,506 / 48 per day allows for upto 1406 days of emissions = 3.8 years
        
    }

    /*
    @function setRewardValues(_rewardPerNFT, _rewardInterval, _lockPeriodInDays, _endDate)
    @description - Update the reward pool values
    @param <uint256> _rewardPerNFT - Reward per NFT 
    @param <uint256> _rewardInterval - Reward interval
    @param <uint256> _lockPeriodInDays - Reward interval
    @param <uint256> _endDate - Staking pool end date in UNIX epoch
  */
    function setRewardValues(uint256 _rewardPerNFT, uint256 _rewardInterval, uint256 _lockPeriodInDays, uint256 _endDate ) public onlyOwner {
        poolInfo.rewardPerNFT = _rewardPerNFT;
        poolInfo.rewardInterval = _rewardInterval;
        poolInfo.lockPeriodInDays = _lockPeriodInDays;
        poolInfo.endDate = _endDate;
    }

    /*
    @function removeTokenId(staker, index)
    @description - Remove tokens from staking contract mapping
    @param <address> staker - Address of users wallet
    @param <uint256> tokindexenId - Token to remove
  */
    function removeTokenId(address staker, uint256 index) internal {
        if (index >= stakerToTokenIds[staker].length) return;

        for (uint256 i = index; i < stakerToTokenIds[staker].length - 1; i++) {
            stakerToTokenIds[staker][i] = stakerToTokenIds[staker][i + 1];
        }
        stakerToTokenIds[staker].pop();
    }

    /*
    @function removeTokenIdFromStaker(staker, tokenId)
    @description - Remove tokens from staking contract mapping
    @param <address> staker - Address of users wallet
    @param <uint256> tokenId - Token to remove
  */
    function removeTokenIdFromStaker(address staker, uint256 tokenId) internal {
        for (uint256 i = 0; i < stakerToTokenIds[staker].length; i++) {
            if (stakerToTokenIds[staker][i] == tokenId) {
                //This is the tokenId to remove;
                removeTokenId(staker, i);
            }
        }
    }

    /*
    @function getTokensStaked(staker)
    @description - Get all the tokens an address has staked
    @param <address> staker - Address of users wallet
  */
    function getTokensStaked(address staker) public view returns (uint256[] memory) {
        return stakerToTokenIds[staker];
    }

    /*
    @function stakeToken(_tokenId)
    @description - Stake token into contract
    @param <uint256> _tokenId - Token to stake
  */
    function stakeToken(uint256 _tokenId) public whenNotPaused returns (bool) {
        require(nft.ownerOf(_tokenId) == msg.sender, "You don't own this NFT");

        nft.transferFrom(msg.sender, address(this), _tokenId);

        _claimSpawn(msg.sender);
        _stakeToken(msg.sender);

        nftDepositor[_tokenId] = msg.sender;
        nftsDeposited.push(_tokenId);
        stakerToTokenIds[msg.sender].push(_tokenId);

        emit Stake(msg.sender, _tokenId);

        return true;
    }

   /*
    @function stakeTokensBatch() 
    @description - Stake tokens and claim pending rewards
    @param <uint256> tokenIDs - Tokens to be staked
  */
    function stakeTokensBatch(uint256[] calldata tokenIDs) external {
        for (uint256 i=0; i<tokenIDs.length; i++) {
            stakeToken(tokenIDs[i]);
        }
    }  

    /*
    @function _stakeToken(_sender) internal
    @description - Update mapping with new token and address
    @param <address> _sender - Address that staked the token
  */
    function _stakeToken(address _sender) internal {
        User storage user = users[_sender];
        Pool storage pool = poolInfo;

        uint256 stopDepo = pool.endDate.sub(pool.lockPeriodInDays.mul(1 days));

        require(block.timestamp <= stopDepo, "Staking is disabled for this pool");

        user.totalNFTDeposited = user.totalNFTDeposited + 1;
        pool.totalDeposit = pool.totalDeposit + 1;
        user.lastDepositTime = block.timestamp;
    }

    /*
    @function claimSpawn() 
    @description - Claim all pending $SPAWN rewards for address
  */
    function claimSpawn() public returns (bool) {
        require(canClaim(msg.sender), "Reward still in locked state");
        _claimSpawn(msg.sender);
        return true;
    }

   /*
    @function canClaim(_addr) 
    @description - Checks when the user last claimed is not within last 24 hours
    @param <address> _addr - Address that staked the token
  */
    function canClaim(address _addr) public view returns (bool) {
        User storage user = users[_addr];
        Pool storage pool = poolInfo;
        return (block.timestamp >= user.lastClaimTime.add(pool.lockPeriodInDays.mul(1 days)));
    }

   /*
    @function canUnstake(_addr) 
    @description - Checks when the user last deposited NFT is not within last 24 hours
    @param <address> _addr - Address that staked the token
  */
    function canUnstake(address _addr) public view returns (bool) {
        User storage user = users[_addr];
        Pool storage pool = poolInfo;
        return (block.timestamp >= user.lastDepositTime.add(pool.lockPeriodInDays.mul(1 days)));
    }

   /*
    @function unStakeToken(_tokenId) 
    @description - Unstake token and claim rewards
    @param <uint256> _tokenId - Token to be unstaked
  */
    function unStakeToken(uint256 _tokenId) public returns (bool) {
        User storage user = users[msg.sender];
        Pool storage pool = poolInfo;

        require(nftDepositor[_tokenId] == msg.sender,"You didn't stake this NFT");
        require(canUnstake(msg.sender),"Stake still in locked state");
        _claimSpawn(msg.sender);

        pool.totalDeposit = pool.totalDeposit - 1;
        user.totalNFTDeposited = user.totalNFTDeposited - 1;

        uint256 len = nftsDeposited.length;

        for(uint256 i = 0; i < len; i++){
            if(nftsDeposited[i] == _tokenId){
                nftsDeposited[i] = nftsDeposited[len - 1];
                nftsDeposited.pop();
                break;
            }
        }

        nft.transferFrom(address(this), msg.sender, _tokenId);
        delete nftDepositor[_tokenId];

        removeTokenIdFromStaker(msg.sender, _tokenId);

        return true;
    }

   /*
    @function unStakeTokensBatch() 
    @description - Unstake tokens and claim rewards in batch
    @param <uint256> tokenIDs - Tokens to be unstaked
  */
    function unStakeTokensBatch(uint256[] calldata tokenIDs) external {
        for (uint256 i=0; i<tokenIDs.length; i++) {
            unStakeToken(tokenIDs[i]);
        }
    }

   /*
    @function emergencyUnstake(_tokenId) 
    @description - Unstake without caring about rewards. EMERGENCY ONLY!
    @param <uint256> _tokenId - Tokens to be emergency unstaked
  */   
    function emergencyUnstake(uint256 _tokenId) public {
        User storage user = users[msg.sender];
        Pool storage pool = poolInfo;
        require(nftDepositor[_tokenId] == msg.sender,"You didn't stake this NFT");
        
        pool.totalDeposit = pool.totalDeposit - 1;
        user.totalNFTDeposited = user.totalNFTDeposited - 1;

        uint256 len = nftsDeposited.length;

        for(uint256 i = 0; i < len; i++){
            if(nftsDeposited[i] == _tokenId){
                nftsDeposited[i] = nftsDeposited[len - 1];
                nftsDeposited.pop();
                break;
            }
        }

        nft.transferFrom(address(this), msg.sender, _tokenId);
        delete nftDepositor[_tokenId];

        removeTokenIdFromStaker(msg.sender, _tokenId);
    }

   /*
    @function _claimSpawn(_addr) internal
    @description - Claim pending rewards for address
    @param <address> _addr - Address to claim rewards
  */
    function _claimSpawn(address _addr) internal {
        User storage user = users[_addr];

        uint256 amount = getPendingRewards(_addr);

        if (amount > 0) {
            safeTransfer(_addr, amount);
            user.lastClaimTime = block.timestamp;
            user.totalClaimed = user.totalClaimed.add(amount);
        }

        poolInfo.totalSpawnDistributed += amount;

        emit Claim(_addr, amount);
    }

   /*
    @function getPendingRewards(_addr) 
    @description - Check pending rewards for an address
    @param <address> _addr - Address to check pending rewards
  */
    function getPendingRewards(address _addr) public view returns (uint256 value) {
        User storage user = users[_addr];
        Pool storage pool = poolInfo;

        uint256 from = user.lastClaimTime > user.lastDepositTime
            ? user.lastClaimTime
            : user.lastDepositTime;
        uint256 to = block.timestamp > pool.endDate
            ? pool.endDate
            : block.timestamp; 

        if (from < to) {
            value = value.add(
                user
                    .totalNFTDeposited
                    .mul(to.sub(from))
                    .mul(pool.rewardPerNFT)
                    .div(pool.rewardInterval)
            );
        }

        return value;
    }

   /*
    @function claimStuckTokens(_token) 
    @description - Claim stuck tokens from contract 
    @param <address> _token - Token address to remove tokens from
  */
    function claimStuckTokens(address _token) external onlyOwner {
        require(_token != address(this),"No rug pulls!");

        if (_token == address(0x0)) {
            payable(owner()).transfer(address(this).balance);
            return;
        }
        IERC20 erc20token = IERC20(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
    }

    /**
     *
     * @dev safe transfer function, require to have enough token to transfer
     *
     */
    function safeTransfer(address _to, uint256 _amount) internal {
        uint256 bal = token.balanceOf(address(this));
        if (_amount > bal) {
            token.transfer(_to, bal);
        } else {
            token.transfer(_to, _amount);
        }
    }
}