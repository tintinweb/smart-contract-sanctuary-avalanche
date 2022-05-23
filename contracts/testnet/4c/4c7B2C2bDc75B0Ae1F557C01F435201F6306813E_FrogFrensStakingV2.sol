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

pragma solidity 0.8.3;

import "./IERC721.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Receiver.sol";
import "./IERC20.sol";

contract FrogFrensStakingV2 is IERC721Receiver, ReentrancyGuard {
    IERC721 public _fren;
    IERC20 public _spawn;
    address public _admin;
    uint256 public rewardsPerSecond = 555555555555555;
    
    mapping(uint256 => uint256) private rewards;
    mapping(address => uint256) public rewardsClaimed;

    struct userStakeNft {
        uint256[] id;
        mapping(uint256 => uint256) tokenIndex;
    }
    mapping(address => userStakeNft) private userNFTs;

    struct Stake {
        uint256 startTime;
        address owner;
    }

    // TokenID => Stake
    mapping(uint256 => Stake) public receipt;

    event NftStaked(address indexed staker, uint256 tokenId, uint256 time);
    event NftUnStaked(address indexed staker, uint256 tokenId, uint256 time);
    event StakePayout(
        address indexed staker,
        uint256 tokenId,
        uint256 stakeAmount,
        uint256 startTime,
        uint256 endTime
    );
    //event StakeRewardUpdated(uint256 traitType, uint256 rewardPerSecond);

    modifier onlyStaker(uint256 tokenId) {
        // require that msg.sender is the owner of this nft
        require(
            receipt[tokenId].owner == msg.sender, "onlyStaker: Caller is not NFT stake owner");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "reclaimTokens: Caller is not the ADMIN");
        _;
    }

    constructor(
        address admin_,
        IERC20 spawn_,
        IERC721 fren_
    ) {
        _admin = admin_;
        _spawn = spawn_;
        _fren = fren_;
    }

    /**
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

    //User must give this contract permission to take ownership of it.
    function stakeToken(uint256[] memory tokenId) public nonReentrant {
        // allow for staking multiple NFTS at one time.
        for (uint256 i = 0; i < tokenId.length; i++) {
            _stakeToken(tokenId[i]);
        }
    }

    function getStakeContractBalance() public view returns (uint256) {
        return _spawn.balanceOf(address(this));
    }

    function getPendingStakeRewards(uint256 tokenId) public view returns (uint256) {
        // do not return if NFT not staked
        uint256 timePassed = block.timestamp - receipt[tokenId].startTime;
        return (rewardsPerSecond * timePassed);
    }

    function unStakeToken(uint256[] memory tokenId) public nonReentrant {
        for (uint256 indx = 0; indx < tokenId.length; indx++) {
            _unStakeToken(tokenId[indx]);
        }
    }

    function _unStakeToken(uint256 tokenId) internal onlyStaker(tokenId) {
        // payout stake, this should be safe as the function is non-reentrant
        _payoutStake(tokenId);

        userStakeNft storage nftStaked = userNFTs[msg.sender];
        uint256 lastIndex = nftStaked.id.length - 1;
        uint256 lastIndexKey = nftStaked.id[lastIndex];
        nftStaked.id[nftStaked.tokenIndex[tokenId]] = lastIndexKey;
        nftStaked.tokenIndex[lastIndexKey] = nftStaked.tokenIndex[tokenId];
        if (nftStaked.id.length > 0) {
            nftStaked.id.pop();
            delete nftStaked.tokenIndex[tokenId];
        }

        // delete stake record, effectively unstaking it
        delete receipt[tokenId];

        // return token
        _fren.safeTransferFrom(address(this), msg.sender, tokenId);

        emit NftUnStaked(msg.sender, tokenId, block.timestamp);
    }

    function claimSpawn(uint256[] memory tokenId) external {
        for (uint256 indx = 0; indx < tokenId.length; indx++) {
            _claimSpawn(tokenId[indx]);
        }
    }

    function _claimSpawn(uint256 tokenId)
        internal
        nonReentrant
        onlyStaker(tokenId)
    {
        // This 'payout first' should be safe as the function is nonReentrant
        _payoutStake(tokenId);

        // // update receipt with a new time
        receipt[tokenId].startTime = block.timestamp;
    }

    function reclaimTokens() external onlyAdmin {
        _spawn.transfer(_admin, _spawn.balanceOf(address(this)));
    }

    function _stakeToken(uint256 tokenId) internal {
        // take possession of the NFT
        _fren.safeTransferFrom(msg.sender, address(this), tokenId);

        userStakeNft storage user = userNFTs[msg.sender];
        user.id.push(tokenId);
        user.tokenIndex[tokenId] = user.id.length - 1;

        receipt[tokenId] = Stake({
            startTime: block.timestamp,
            owner: msg.sender
        });

        emit NftStaked(msg.sender, tokenId, block.timestamp);
    }

    function _payoutStake(uint256 tokenId) internal {
        /* NOTE : Must be called from non-reentrant function to be safe!*/

        // double check that the receipt exists and we're not staking from time 0
        require( receipt[tokenId].startTime > 0, "_payoutStake: Can not stake from time 0");

        // earned amount is difference between the stake start time, current time multiplied by reward amount
        uint256 timeStaked = block.timestamp - receipt[tokenId].startTime;
        uint256 payout = timeStaked * rewardsPerSecond;

        // If contract does not have enough tokens to pay out, return the NFT without payment
        // This prevent a NFT being locked in the contract when empty
        if (_spawn.balanceOf(address(this)) < payout) {
            emit StakePayout(
                msg.sender,
                tokenId,
                0,
                receipt[tokenId].startTime,
                block.timestamp
            );
            return;
        }

        // payout stake
        _handlePayout(receipt[tokenId].owner, payout);

        emit StakePayout(
            msg.sender,
            tokenId,
            payout,
            receipt[tokenId].startTime,
            block.timestamp
        );
    }

    function _handlePayout(address to, uint256 payout) private {
        _transferToken(to, payout);
        rewardsClaimed[to] += payout;
    }

    function _transferToken(address to, uint256 amount) private {
        _spawn.transfer(to, amount);
    }

    function setRewardsPerSecond(uint256 _newRewardsPerSecond) public onlyAdmin {
        rewardsPerSecond = _newRewardsPerSecond;
    }

    function getTokensStaked(address staker) public view returns (uint256[] memory) {
        return userNFTs[staker].id;
    }

    function balanceOf(address owner) public view returns (uint256) {
        return getTokensStaked(owner).length;
    }
}