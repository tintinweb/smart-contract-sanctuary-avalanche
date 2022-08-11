/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-10
*/

// File: contracts/MooStake.sol


pragma solidity ^0.8.15;

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract StakeNFT {

    //State variabble
    uint private _stakingId = 0;
    address private NFTToken = 0x46b933f2B508A9a564eb77731363eD74f61FC409;
    address private REWARDToken = 0xb328E911aE5b6967297DC32133fb5B6e0ACf5891;

    address private admin;
    uint private rate;
    uint256 public stakingStartTime;
    uint256 public numberOfMinutes;
    uint256 public endDate;
    bool initialised;

    //constructor
    constructor(){
        admin = msg.sender;
        numberOfMinutes = 5;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    function initStaking() public onlyAdmin {
        //needs access control
        require(!initialised, "Already initialised");
        stakingStartTime = block.timestamp;
        initialised = true;
        kingdomOnly = true;
        endDate = 0;
    }


    //enumerator
    enum StakingStatus {Active, Claimed, Cancelled}

    //structs
    struct Staking {
        address staker;    
        address token;
        uint tokenId;
        uint emission;
        uint releaseTime;
        StakingStatus status;
        uint StakingId;
    }

    //mapping tokenId => bonus
    mapping(uint => Staking) private _StakedItem; 
    mapping(uint => uint) public bonus;

    bool public kingdomOnly;

    //event
    event tokenStaked(address indexed staker, address indexed token, uint token_id, StakingStatus status, uint StakingId);
    event tokenClaimStatus(address indexed token, uint indexed token_id, StakingStatus indexed status, uint StakingId);
    event tokenClaimComplete(address indexed token, uint indexed token_id, StakingStatus indexed status, uint StakingId);
    event tokenCancelComplete(address indexed token, uint indexed token_id, StakingStatus indexed status, uint StakingId);

    function setNFTToken(address _token) external onlyAdmin {
        NFTToken = _token;
    }

    function setRewardToken(address _token) external onlyAdmin {
        REWARDToken = _token;
    }

    function setNumberOfMinutes(uint256 _numberOfMinutes) external onlyAdmin {
        numberOfMinutes = _numberOfMinutes;
    }

    function setBonus(uint256[] memory tokenId, uint256[] memory x) external onlyAdmin {
        for(uint i = 0; i < tokenId.length; i++) {
            bonus[tokenId[i]] = x[i];
        }
    }

    //function to call another function
    function callStakeToken(address token, uint _tokenID) external {
        require(token == NFTToken, "incorrect NFT to stake");
        require(!kingdomOnly, "only kingdom at this time");
        _stakeToken(token, _tokenID);
    }

    //function to transfer NFT from user to contract
    function _stakeToken(address token, uint tokenId) internal returns(Staking memory) {
        require(initialised, "Staking System: the staking has not started");
        IERC721(token).transferFrom(msg.sender,address(this),tokenId); // User must approve() this contract address via the NFT ERC721 contract before NFT can be transfered
        uint releaseTime = block.timestamp + (numberOfMinutes * 1 minutes);
        
        uint currentStakingId = _stakingId;

        Staking memory staking = Staking(msg.sender,token, tokenId, rate, releaseTime, StakingStatus.Active, currentStakingId);
        

        _StakedItem[_stakingId] = staking;
        _stakingId++;

        emit tokenStaked(msg.sender, staking.token, staking.tokenId, staking.status, currentStakingId);
        
        return _StakedItem[currentStakingId];
    }

    //function to view staked NFT
    function viewStake(uint stakingId)public view returns (Staking memory) {
        return _StakedItem[stakingId];
    }

    //function to check NFT stake duration status 
    // function checkStake(uint stakingId, address staker)public returns (Staking memory) {
    //     Staking storage staking = _StakedItem[stakingId];
        
    //     require(staker == msg.sender,"You cannot check this staking as it is not listed under this address");
    //     require(staking.status == StakingStatus.Active,"Staking is not active or claimed");
    //     if (block.timestamp >= staking.releaseTime) {
    //         staking.status = StakingStatus.Active;
    //     }

    //     emit tokenClaimStatus(staking.token, staking.tokenId, staking.status, staking.StakingId);
    //     return _StakedItem[stakingId];

 
    // }

    function stakeAll(address token, uint[] memory tokenId) external {
        if (kingdomOnly){
            require(tokenId.length >= 7, "You must stake at least 7 NFTs");
        }
        for (uint i = 0; i < tokenId.length; i++) {
            _stakeToken(token, tokenId[i]);
        }
    }

    function claimAll(uint[] memory stakingId) external {
        for (uint i = 0; i < stakingId.length; i++) {
            claimStake(stakingId[i]);
        }
    }

    //function to claim reward token if NFT stake duration is completed
    function claimStake(uint stakingId) public returns(Staking memory){
        Staking storage staking = _StakedItem[stakingId];
        require(block.timestamp >= staking.releaseTime, "Has not passed minimum minutes");
        require(staking.staker == msg.sender, "You cannot claim this staking as it is not listed under this address");
        require(staking.status == StakingStatus.Active,"Your reward is either not active yet or has been claimed");
        uint amount;
        if (endDate != 0) {
            amount = staking.emission * (bonus[staking.tokenId] + 100) / 100 * (endDate - staking.releaseTime) / 1 days;
        } else {
            amount = staking.emission * (bonus[staking.tokenId] + 100) / 100 * (block.timestamp - staking.releaseTime) / 1 days;
        }
        
        IERC20(REWARDToken).transfer(msg.sender, amount);

        staking.status = StakingStatus.Claimed;
        IERC721(staking.token).transferFrom(address(this), msg.sender, staking.tokenId);

        emit tokenClaimComplete(staking.token, staking.tokenId, staking.status, staking.StakingId);
        
        return _StakedItem[stakingId];
    }

    function changeMooKingdom(bool _state) external onlyAdmin {
        kingdomOnly = _state;
    }

    function endStaking() external onlyAdmin {
        endDate = block.timestamp;
    }
    

    //function to cancel NFT stake
    function cancelStake(uint stakingId) public returns (Staking memory) {
        Staking storage staking = _StakedItem[stakingId];
        require(staking.staker == msg.sender, "You cannot cancel this staking as it is not listed under this address");
        require(staking.status == StakingStatus.Active,"Staking is either not active (Cancelled or in claiming process)");
        
        staking.status = StakingStatus.Cancelled;
        IERC721(staking.token).transferFrom(address(this), msg.sender, staking.tokenId);


        emit tokenCancelComplete(staking.token, staking.tokenId, staking.status, staking.StakingId);
        return _StakedItem[stakingId];
    }

    //function to set reward rate per day
    function setRewardRate(uint newRate) external onlyAdmin {
        rate = newRate;
    }

    function getRewardRate() external view returns (uint) {
        return rate;
    }

    function getTotalStaked() external view returns (uint) {
        return _stakingId;
    }

    function setNewAdmin(address newAdd) external onlyAdmin{
        admin = newAdd;
    }

}