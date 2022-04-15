// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./Ownable.sol";
import "./IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

contract NFTStaking is Ownable, ERC721Holder {
    //IRewardToken public rewardsToken;
    IERC721 public rockGameNFT;
    uint256 public stakedTotal;
    uint256 public stakingStartTime;
    //uint256 constant stakingTime = 180 seconds;
    //uint256 constant token = 10e18;
    
    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenStakingCoolDown;
        uint256 balance;
        uint256 rewardsReleased;
    }

    constructor(IERC721 _address) {
        rockGameNFT = _address;
       // rewardsToken = _rewardsToken;
    }

    /// @notice mapping of a staker to its wallet
    mapping(address => Staker) public stakers;

    /// @notice Mapping from token ID to owner address

    mapping(uint256 => address) public tokenOwner;
    //bool public tokensClaimable;


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


    function getStakedTokens(address _user)
        public
        view
        returns (uint256[] memory tokenIds)
    {
        return stakers[_user].tokenIds;
    }

    function stake(uint256 tokenId) public {
        (bool success,) = owner().call{value: 1*(10**17)}("");
        require(success, "Failed to send money");
        _stake(msg.sender, tokenId);
    }

    function stakeBatch(uint256[] memory tokenIds) public {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(msg.sender, tokenIds[i]);
        }
    }

    function _stake(address _user, uint256 _tokenId) internal {
        //require(initialised, "Staking System: the staking has not started");
        require(
            rockGameNFT.ownerOf(_tokenId) == _user,
            "user must be the owner of the token"
        );
        Staker storage staker = stakers[_user];

        staker.tokenIds.push(_tokenId);
        staker.tokenStakingCoolDown[_tokenId] = block.timestamp;
        tokenOwner[_tokenId] = _user;
        //rockGameNFT.approve(address(this), _tokenId);
        rockGameNFT.safeTransferFrom(_user, address(this), _tokenId);

        emit Staked(_user, _tokenId);
        stakedTotal++;
    }

    function unstake(uint256 _tokenId) public {
       // claimReward(msg.sender);
        _unstake(msg.sender, _tokenId);
    }

    function unstakeBatch(uint256[] memory tokenIds) public {
        //claimReward(msg.sender);
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

        uint256 lastIndex = staker.tokenIds.length - 1;
        uint256 lastIndexKey = staker.tokenIds[lastIndex];
        if (staker.tokenIds.length > 0) {
            staker.tokenIds.pop();
        }
        staker.tokenStakingCoolDown[_tokenId] = 0;
        if (staker.balance == 0) {
            delete stakers[_user];
        }
        delete tokenOwner[_tokenId];

        rockGameNFT.safeTransferFrom(address(this), _user, _tokenId);

        emit Unstaked(_user, _tokenId);
        stakedTotal--;
    }

/*
    function setTokensClaimable(bool _enabled) public onlyOwner {
        //needs access control
        tokensClaimable = _enabled;
        emit ClaimableStatusUpdated(_enabled);
    }

    function updateReward(address _user) public {
        
        Staker storage staker = stakers[_user];
        uint256[] storage ids = staker.tokenIds;
        for (uint256 i = 0; i < ids.length; i++) {
            if (
                staker.tokenStakingCoolDown[ids[i]] <
                block.timestamp + stakingTime &&
                staker.tokenStakingCoolDown[ids[i]] > 0
            ) {
            
                uint256 stakedDays = ((block.timestamp - uint(staker.tokenStakingCoolDown[ids[i]]))) / stakingTime;
                uint256 partialTime = ((block.timestamp - uint(staker.tokenStakingCoolDown[ids[i]]))) % stakingTime;
                
                staker.balance +=  token * stakedDays;

                staker.tokenStakingCoolDown[ids[i]] = block.timestamp + partialTime;

                console.logUint(staker.tokenStakingCoolDown[ids[i]]);
                console.logUint(staker.balance);
            }
        }
    }

    function claimReward(address _user) public {
        require(tokensClaimable == true, "Tokens cannnot be claimed yet");
        require(stakers[_user].balance > 0 , "0 rewards yet");


        stakers[_user].rewardsReleased += stakers[_user].balance;
        stakers[_user].balance = 0;
        rewardsToken.mint(_user, stakers[_user].balance);

        emit RewardPaid(_user, stakers[_user].balance);
    }*/
}