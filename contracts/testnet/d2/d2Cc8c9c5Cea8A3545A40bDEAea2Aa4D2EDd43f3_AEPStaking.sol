// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC721.sol";
import "IERC20.sol";
import "SafeMath.sol";
import "Ownable.sol";
import "ERC721Holder.sol";

interface IRewardToken is IERC20 {
    function mint(address to, uint256 amount) external;
    enum TIER { 
        HUMAN,
        ZOMBIE, 
        VAMPIRE
    }

    // struct TokenTierIndex {
    //     uint256 index;
    //     TIER tier; 
    // }
    // mapping(uint256 => TokenTierIndex) public tokenTierIndex;

    function tokenTierIndex(uint256 id) external view returns ( uint256 , TIER);


}

contract AEPStaking is Ownable, ERC721Holder {
    IRewardToken public preyContract;
    IERC721 public nft;

    uint256 public stakedTotal;
    uint256 public stakingStartTime;
    uint256 public constant stakingTime = 180 seconds; // 1 day
    uint256[] public rewards = [10e18, 1025e16, 1050e16]; // human , zombie, vampire rewards
    
    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenStakingCoolDown;
        uint256 balance;
        uint256 rewardsReleased;
    }
    // enum TIER { 
    //     HUMAN,
    //     ZOMBIE, 
    //     VAMPIRE
    // }

    // struct TokenTierIndex {
    //     uint256 index;
    //     TIER tier; 
    // }

    constructor(IERC721 _nft, IRewardToken _preyContract) {
        nft = _nft;
        preyContract = _preyContract;
    }

    /// @notice mapping of a staker to its wallet
    mapping(address => Staker) public stakers;

    /// @notice Mapping from token ID to owner address

    mapping(uint256 => address) public tokenOwner;
    bool public tokensClaimable;
    bool initialised;

    /// @notice event emitted when a user has staked a nft

    event Staked(address owner, uint256 amount);

    /// @notice event emitted when a user has unstaked a nft
    event Unstaked(address owner, uint256 amount);

    /// @notice event emitted when a user claims reward
    event RewardPaid(address indexed user, uint256 reward);

    /// @notice Allows reward tokens to be claimed
    event ClaimableStatusUpdated(bool status);

    /// @notice Emergency unstake tokens without rewards
    event EmergencyUnstake(address indexed user, uint256 tokenId);

    function initStaking() public onlyOwner {
        //needs access control
        require(!initialised, "Already initialised");
        stakingStartTime = block.timestamp;
        initialised = true;
    }

    function setTokensClaimable(bool _enabled) public onlyOwner {
        //needs access control
        tokensClaimable = _enabled;
        emit ClaimableStatusUpdated(_enabled);
    }

    function getStakedTokens(address _user)
        public
        view
        returns (uint256[] memory tokenIds)
    {
        return stakers[_user].tokenIds;
    }

    function stake(uint256 tokenId) public {
        _stake(msg.sender, tokenId);
    }

    function stakeBatch(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i]);
        }
    }

    function _stake(address _user, uint256 _tokenId) internal {
        require(initialised, "Staking System: the staking has not started");
        require(
            nft.ownerOf(_tokenId) == _user,
            "user must be the owner of the token"
        );
        Staker storage staker = stakers[_user];

        staker.tokenIds.push(_tokenId);
        staker.tokenStakingCoolDown[_tokenId] = block.timestamp;
        tokenOwner[_tokenId] = _user;
        nft.approve(address(this), _tokenId);
        nft.safeTransferFrom(_user, address(this), _tokenId);

        emit Staked(_user, _tokenId);
        stakedTotal++;
    }

    function unstake(uint256 _tokenId) public {
        claimReward(msg.sender);
        _unstake(msg.sender, _tokenId);
    }

    function unstakeBatch(uint256[] memory tokenIds) public {
        claimReward(msg.sender);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenOwner[tokenIds[i]] == msg.sender) {
                _unstake(msg.sender, tokenIds[i]);
            }
        }
    }

    // Unstake without caring about rewards. EMERGENCY ONLY.
    function emergencyUnstake(uint256 _tokenId) public {
        require(
            tokenOwner[_tokenId] == msg.sender,
            "nft._unstake: Sender must have staked tokenID"
        );
        _unstake(msg.sender, _tokenId);
        emit EmergencyUnstake(msg.sender, _tokenId);
    }

    function _unstake(address _user, uint256 _tokenId) internal {
        require(
            tokenOwner[_tokenId] == _user,
            "Nft Staking System: user must be the owner of the staked nft"
        );
        Staker storage staker = stakers[_user];
        
        if (staker.tokenIds.length > 0) {
            staker.tokenIds.pop();
        }
        staker.tokenStakingCoolDown[_tokenId] = 0;
        delete tokenOwner[_tokenId];

        nft.safeTransferFrom(address(this), _user, _tokenId);

        emit Unstaked(_user, _tokenId);
        stakedTotal--;
    }

    function getTokenTierIndex(uint256 _id) public view returns(uint256 tokenIndex,IRewardToken.TIER tokenTier) {
        return(preyContract.tokenTierIndex(_id));
    }

    function calculateReward(address _user) public view returns(uint256){
        
        Staker storage staker = stakers[_user];
        uint256[] storage ids = staker.tokenIds;
        uint256 reward = staker.balance;
        for (uint256 i = 0; i < ids.length; i++) {
            if (
                staker.tokenStakingCoolDown[ids[i]] <
                block.timestamp + stakingTime &&
                staker.tokenStakingCoolDown[ids[i]] > 0
            ) {
                ( ,IRewardToken.TIER tokenTier) = getTokenTierIndex(ids[i]);
                uint256 tierReward = rewards[uint(tokenTier)];
                uint256 stakedDays = ((block.timestamp - uint(staker.tokenStakingCoolDown[ids[i]]))) / stakingTime;
                
                reward +=  tierReward * stakedDays;
            }
        }
        return reward;
    }

    function _updateReward(address _user) internal {
        
        Staker storage staker = stakers[_user];
        uint256[] storage ids = staker.tokenIds;
        for (uint256 i = 0; i < ids.length; i++) {
            if (
                staker.tokenStakingCoolDown[ids[i]] <
                block.timestamp + stakingTime &&
                staker.tokenStakingCoolDown[ids[i]] > 0
            ) {
                ( ,IRewardToken.TIER tokenTier) = preyContract.tokenTierIndex(ids[i]);
                uint256 tierReward = rewards[uint(tokenTier)];
                uint256 stakedDays = ((block.timestamp - uint(staker.tokenStakingCoolDown[ids[i]]))) / stakingTime;
                uint256 partialTime = ((block.timestamp - uint(staker.tokenStakingCoolDown[ids[i]]))) % stakingTime;
                
                staker.balance +=  tierReward * stakedDays;

                staker.tokenStakingCoolDown[ids[i]] = block.timestamp + partialTime;
            }
        }
    }

    function claimReward(address _user) public {
        require(tokensClaimable == true, "Tokens cannnot be claimed yet");
        _updateReward(_user);
        require(stakers[_user].balance > 0 , "0 rewards yet");

        Staker storage staker = stakers[_user];
        
        staker.rewardsReleased += staker.balance;
        staker.balance = 0;
   
        preyContract.mint(_user, staker.balance);

        emit RewardPaid(_user, staker.balance);
    }
}