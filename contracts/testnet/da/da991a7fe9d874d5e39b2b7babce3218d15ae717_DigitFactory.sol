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

contract DigitFactory is Ownable, ERC721Holder {

    uint256 public stakedTotal;
    uint256 public stakingPeriod; // in secs
    
    struct Staker {
        uint256[] tokenIds;
        mapping(uint256 => uint256) tokenStakingCoolDown;
        uint256 balance;
        uint256 rewardsReleased;
    }
    //Mapping of Partner NFT contracts
    mapping(uint256 => address) public partnerNFTAddr;

    constructor() {
        partnerNFTAddr[1] = 0xEaB33F781aDA4ee7E91fD63ad87C5Bb47FFb8a83; //chap 1 HGAME 
        partnerNFTAddr[2] = 0x8D01C8ee82E581E55C02117a676B5Bbd4734FABB; //Rock
        partnerNFTAddr[3] = 0x0c2485d08C7611cEAfdbB370DAd4fa86B5935fF4; //PT  10k PFP
        partnerNFTAddr[4] = 0xBAF27bcEf3A6FD907F42F96e926c43Cd124bDc39;
        stakingPeriod = 60*60*24*30; //start with 30 days
    }

    /// @notice mapping of a staker to its wallet
    mapping(address => Staker) public stakers;

    /// @notice Mapping from token ID to owner address
    mapping(uint256 => address) public tokenOwner;
    mapping(uint256 =>uint256) public expiryOfID;

    /// @notice event emitted when a user has staked a nft

    event Staked(address owner, uint256 amount);

    /// @notice event emitted when a user has unstaked a nft
    event Unstaked(address owner, uint256 amount);


    function getStakedTokens(address _user)
        public
        view
        returns (uint256[] memory tokenIds)
    {
        return stakers[_user].tokenIds;
    }

    function stake(uint256 partnerNFTSelector, uint256 tokenId) public payable{
        (bool success,) = owner().call{value: 1*(10**17)}("");
        require(success, "Failed admin");
        _stake(partnerNFTSelector,msg.sender, tokenId);
    }


    function _stake(uint256 _partnerSelector, address _user, uint256 _tokenId) internal {
        //require(initialised, "Staking System: the staking has not started");
        IERC721 partnerNFT = IERC721(partnerNFTAddr[_partnerSelector]);
        require(
            partnerNFT.ownerOf(_tokenId) == _user,
            "user must be the owner of the token"
            );
        
        Staker storage staker = stakers[_user];
        
        staker.tokenIds.push(_tokenId);
        staker.tokenStakingCoolDown[_tokenId] = block.timestamp;
        tokenOwner[_tokenId] = _user;
        //rockGameNFT.approve(address(this), _tokenId);
        partnerNFT.safeTransferFrom(_user, address(this), _tokenId);
        expiryOfID[_tokenId] = block.timestamp + stakingPeriod;
        emit Staked(_user, _tokenId);
        stakedTotal++;
    }

    function unstake(uint256 partnerNFTSelector, uint256 _tokenId) public {
       // claimReward(msg.sender);
        _unstake(partnerNFTSelector, msg.sender, _tokenId);
    }




    function _unstake(uint256 _partnerSelector, address _user, uint256 _tokenId) internal {
        
        require(
            tokenOwner[_tokenId] == _user,
            "Nft Staking System: user must be the owner of the staked nft"
        );
        Staker storage staker = stakers[_user];
        IERC721 partnerNFT = IERC721(partnerNFTAddr[_partnerSelector]);

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
        expiryOfID[_tokenId] = 0;
        partnerNFT.safeTransferFrom(address(this), _user, _tokenId);

        emit Unstaked(_user, _tokenId);
        stakedTotal--;
    }
    
    function addPartner(uint256 index, address addr) public onlyOwner {
         partnerNFTAddr[index] = addr;
    }
    function setStakingPeriod(uint256 timeSecs) public onlyOwner {
       stakingPeriod = timeSecs;
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