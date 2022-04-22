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
   // uint256 public numStakedNFTs;
    uint256 public nftStakedCount;
    uint256 public stakingPeriod; // in secs


    struct stakedNFTs{
        uint256 projectNFTIDMapping;
        uint256 tokenId;
        uint256 expiryTime;
    }

    //Mapping of Partner NFT contracts
    mapping(uint256 => address) public partnerNFTAddr;

    /// @notice mapping of a staker to its wallet
    mapping(address => stakedNFTs[]) public staker;

    // @notice array of stakers
    //apping(uint256 => address) public stakerAddresses;
    address[] public stakerAddresses;

    constructor() {
        partnerNFTAddr[1] = 0xCf9CaC787A7Adf94A9d90Cc0eb98f53A420dC1aF; // testdd
        partnerNFTAddr[2] = 0x8D01C8ee82E581E55C02117a676B5Bbd4734FABB; //Rock
        stakingPeriod = 60*60*24*30; //start with 30 days
    }

    /// @notice event emitted when a user has staked a nft
    event Staked(address owner, uint256 _projID, uint256 _tokenID);

    /// @notice event emitted when a user has unstaked a nft
    event Unstaked(address owner, uint256 _projID, uint256 _tokenID);

    function getStakersCount() public view returns (uint256){
        return stakerAddresses.length;
    }
    function getNumStakedNFTsbyUser(address _addr) public view returns (uint256){
        return staker[_addr].length;
    }

    function stake(uint256 _partnerSelector, uint256 _tokenId) public payable{
        (bool success,) = owner().call{value: 1*(10**17)}("");
        require(success, "Failed admin");

       IERC721 partnerNFT = IERC721(partnerNFTAddr[_partnerSelector]);
       require(partnerNFT.ownerOf(_tokenId) == msg.sender, "user must be the owner of the token");


        if (staker[msg.sender].length==0) // new staker
            {
             stakerAddresses.push(msg.sender);
            }
        //stakedNFTs memory nftTobeStaked;
        //nftTobeStaked = stakedNFTs(_partnerSelector,_tokenId,9999999999);
        //nftTobeStaked.projectNFTIDMapping= _partnerSelector;
        //nftTobeStaked.tokenId = _tokenId;
        //nftTobeStaked.expiryTime = block.timestamp + stakingPeriod;
        //Staker storage staker = stakers[_user];
        staker[msg.sender].push(stakedNFTs(_partnerSelector,_tokenId,block.timestamp + stakingPeriod));
        partnerNFT.safeTransferFrom(msg.sender, address(this), _tokenId);
        nftStakedCount++;
        emit Staked(msg.sender,_partnerSelector, _tokenId);
        
    }

    function unstake(uint256 partnerNFTSelector, uint256 _tokenId) public {
        require(staker[msg.sender].length > 0, "Nft Staking System: No staked NFTs");
        _unstake(partnerNFTSelector, msg.sender, _tokenId);

    }

    function _unstake(uint256 _partnerSelector, address _user, uint256 _tokenId) internal {

        IERC721 partnerNFT = IERC721(partnerNFTAddr[_partnerSelector]);
        
        for (uint i = 0; i < staker[_user].length; i++) //need to check which index in staker[user][] the nft is 
        {
            if (staker[_user][i].tokenId == _tokenId && staker[_user][i].projectNFTIDMapping == _partnerSelector)
            {
                
                staker[_user][i].projectNFTIDMapping= staker[_user][staker[_user].length -1].projectNFTIDMapping;
                staker[_user][i].tokenId = staker[_user][staker[_user].length -1].tokenId;
                staker[_user][i].expiryTime = staker[_user][staker[_user].length -1].expiryTime;

                staker[_user].pop();

                partnerNFT.safeTransferFrom(address(this), _user, _tokenId);
                emit Unstaked(_user, _partnerSelector, _tokenId);
                nftStakedCount--;
            }
            //else{
            //revert("You dont own the NFT in the project.");
            //}
        }//end of for loop

            if (staker[msg.sender].length==0) // staker unstaked last nft
            {
               for (uint i = 0; i < stakerAddresses.length; i++) //find the index 
               {
                   if (stakerAddresses[i] == msg.sender)
                   { //found the item. Now swop and delete.
                    stakerAddresses[i] = stakerAddresses[stakerAddresses.length -1];
                    stakerAddresses.pop();
                   }
               }
               
            }
        
    }

    function unstakeAll() public {
        uint256 numberStaked = staker[msg.sender].length;
        require(numberStaked > 0, "Nft Staking System: No staked NFTs");
       
            for (uint i = 0; i <numberStaked; i++) 
            {
                
                IERC721 partnerNFT = IERC721(partnerNFTAddr[staker[msg.sender][i].projectNFTIDMapping]);
                partnerNFT.safeTransferFrom(address(this), msg.sender, staker[msg.sender][i].tokenId);
                emit Unstaked(msg.sender, staker[msg.sender][i].projectNFTIDMapping, staker[msg.sender][i].tokenId);
               
                nftStakedCount--;
                
            }
            for (uint i = 0; i <numberStaked; i++) 
            {
            staker[msg.sender].pop();
            }

        if (staker[msg.sender].length ==0) {
            for (uint i = 0; i < stakerAddresses.length; i++) //find the staker and remove 
            {
                if (stakerAddresses[i] == msg.sender)
                { //found the item. Now swop and delete.
                    stakerAddresses[i] = stakerAddresses[stakerAddresses.length -1];
                    stakerAddresses.pop();
                }
            }
        }       
    }
    
    /**
    *
    Admin Functions
    *
    **/
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