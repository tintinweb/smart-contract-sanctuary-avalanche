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

contract DigitFactoryV2 is Ownable, ERC721Holder {

    bool public contractActive = false;

    uint256 public nftStakedCount;
    uint256 public stakingPeriod; // in secs
    uint256 public stakingFees;

    struct stakedNFTs{
        uint256 projectNFTIDMapping;
        uint256 tokenId;
        uint256 expiryTime;
    }

    //Mapping of Partner NFT contracts
    mapping(uint256 => address) public partnerNFTAddr;

    //Mapping of a staker to its wallet
    mapping(address => stakedNFTs[]) public stakerNFTs;

    //Array of stakers
    address[] public stakerAddresses;

    constructor() {
        partnerNFTAddr[1] = 0x8D01C8ee82E581E55C02117a676B5Bbd4734FABB; //Rock
        partnerNFTAddr[2] = 0xEaB33F781aDA4ee7E91fD63ad87C5Bb47FFb8a83; //Yield Hunt Chap 1
        partnerNFTAddr[3] = 0x0c2485d08C7611cEAfdbB370DAd4fa86B5935fF4; //P&T Wolf
        partnerNFTAddr[4] = 0x89323f00a621D4eD6A56a93295C5f10f4df57FFa; //UNIV
        partnerNFTAddr[5] = 0xe17b99Ba5cacEf17a6ad0d7D57de7945BbddeC52; //Yield Hunt Chap 2
        partnerNFTAddr[6] = 0x15e6C37CDb635ACc1fF82A8E6f1D25a757949BEC; //P&T Game
        partnerNFTAddr[7] = 0x0484aF164675A98A8c02047CFFcb36dEAa710B56; //SoldierArmies

        stakingPeriod = 60*60*24*20; //start with 20 days
        stakingFees = 2*10**17;
        contractActive = true;
    }

    /// @notice event emitted when a user has staked a nft
    event Staked(address owner, uint256 _projID, uint256 _tokenID);

    /// @notice event emitted when a user has unstaked a nft
    event Unstaked(address owner, uint256 _projID, uint256 _tokenID);

    function getStakersCount() public view returns (uint256){
        return stakerAddresses.length;
    }

    function getNumStakedNFTsbyUser(address _addr) public view returns (uint256){
        return stakerNFTs[_addr].length;
    }

    function stake(uint256 _partnerSelector, uint256 _tokenId) public payable{
        (bool success,) = owner().call{value: stakingFees}("");
        require(success, "Failed to send Avax");
        require(contractActive, "Project not active, Please check discord.");

       IERC721 partnerNFT = IERC721(partnerNFTAddr[_partnerSelector]);
       require(partnerNFT.ownerOf(_tokenId) == msg.sender, "user must be the owner of the token");


        if (stakerNFTs[msg.sender].length==0) // new staker
            {
             stakerAddresses.push(msg.sender);
            }

        stakerNFTs[msg.sender].push(stakedNFTs(_partnerSelector,_tokenId,block.timestamp + stakingPeriod));
        partnerNFT.safeTransferFrom(msg.sender, address(this), _tokenId);
        nftStakedCount++;
        emit Staked(msg.sender,_partnerSelector, _tokenId);
        
    }

    function unstake(uint256 partnerNFTSelector, uint256 _tokenId) public {
        require(stakerNFTs[msg.sender].length > 0, "Nft Staking System: No staked NFTs");
        _unstake(partnerNFTSelector, msg.sender, _tokenId);

    }

    function _unstake(uint256 _partnerSelector, address _user, uint256 _tokenId) internal {

        IERC721 partnerNFT = IERC721(partnerNFTAddr[_partnerSelector]);
        
        for (uint i = 0; i < stakerNFTs[_user].length; i++) //need to check which index in staker[user][] the nft is 
        {
            if (stakerNFTs[_user][i].tokenId == _tokenId && stakerNFTs[_user][i].projectNFTIDMapping == _partnerSelector)
            {
                
                stakerNFTs[_user][i].projectNFTIDMapping= stakerNFTs[_user][stakerNFTs[_user].length -1].projectNFTIDMapping;
                stakerNFTs[_user][i].tokenId = stakerNFTs[_user][stakerNFTs[_user].length -1].tokenId;
                stakerNFTs[_user][i].expiryTime = stakerNFTs[_user][stakerNFTs[_user].length -1].expiryTime;

                stakerNFTs[_user].pop();

                partnerNFT.safeTransferFrom(address(this), _user, _tokenId);
                emit Unstaked(_user, _partnerSelector, _tokenId);
                nftStakedCount--;
            }

        }//end of for loop

            if (stakerNFTs[msg.sender].length==0) // staker unstaked last nft
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
        uint256 numberStaked = stakerNFTs[msg.sender].length;
        require(numberStaked > 0, "Nft Staking System: No staked NFTs");
       
            for (uint i = 0; i <numberStaked; i++) 
            {
                IERC721 partnerNFT = IERC721(partnerNFTAddr[stakerNFTs[msg.sender][i].projectNFTIDMapping]);
                partnerNFT.safeTransferFrom(address(this), msg.sender, stakerNFTs[msg.sender][i].tokenId);
                emit Unstaked(msg.sender, stakerNFTs[msg.sender][i].projectNFTIDMapping, stakerNFTs[msg.sender][i].tokenId);
               
                nftStakedCount--;
            }
            for (uint i = 0; i <numberStaked; i++) 
            {
            stakerNFTs[msg.sender].pop();
            }

            for (uint i = 0; i < stakerAddresses.length; i++) //find the staker and remove 
            {
                if (stakerAddresses[i] == msg.sender)
                { //found the staker. Now swop and delete.
                    stakerAddresses[i] = stakerAddresses[stakerAddresses.length -1];
                    stakerAddresses.pop();
                }
            }
               
    }

    function reStakeAll() public payable{
        uint256 numberStaked = stakerNFTs[msg.sender].length;
        require(numberStaked > 0, "Nft Staking System: No staked NFTs");
        require(contractActive, "Project Not Active, Please check discord.");
        (bool success,) = owner().call{value: numberStaked * stakingFees }("");
        require(success, "Failed to send Avax");
       
            for (uint i = 0; i <numberStaked; i++) 
            {
                 if (stakerNFTs[msg.sender][i].expiryTime > block.timestamp) //if not, add on.
                    {
                        stakerNFTs[msg.sender][i].expiryTime += stakingPeriod;
                    }
                else        //if so, start from now.
                    {
                        stakerNFTs[msg.sender][i].expiryTime = block.timestamp + stakingPeriod; 
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

    function setContractActive(bool _active) public onlyOwner {
        contractActive = _active;
    }

    function setStakingPeriod(uint256 _stakingFees, uint256 _numDaysExtension) public onlyOwner {
       stakingPeriod = _numDaysExtension * (24*60*60);
       stakingFees = _stakingFees;
    }



}