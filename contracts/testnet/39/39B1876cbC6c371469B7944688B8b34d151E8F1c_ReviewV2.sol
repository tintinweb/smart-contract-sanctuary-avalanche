/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-01
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC721 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

interface IERC4907 {

    // Logged when the user of a NFT is changed or expires is changed
    /// @notice Emitted when the `user` of an NFT or the `expires` of the `user` is changed
    /// The zero address for user indicates that there is no user address
    event UpdateUser(uint256 indexed tokenId, address indexed user, uint64 expires);

    /// @notice set the user and expires of a NFT
    /// @dev The zero address indicates there is no user
    /// Throws if `tokenId` is not valid NFT
    /// @param user  The new user of the NFT
    /// @param expires  UNIX timestamp, The new user could use the NFT before expires
    function setUser(uint256 tokenId, address user, uint64 expires) external;

    /// @notice Get the user address of an NFT
    /// @dev The zero address indicates that there is no user or the user is expired
    /// @param tokenId The NFT to get the user address for
    /// @return The user address for this NFT
    function userOf(uint256 tokenId) external view returns(address);

    /// @notice Get the user expires of an NFT
    /// @dev The zero value indicates that there is no user
    /// @param tokenId The NFT to get the user expires for
    /// @return The user expires for this NFT
    function userExpires(uint256 tokenId) external view returns(uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface IStakingFactory {
    struct Meta {
        address storeAddress;
        uint256 storeNFTType;
    }
    function notifyRewardAmount(address stakingContract, uint256 rewards) external;
    function getInstanceMeta(string memory storeId) external view returns(Meta memory);
}

interface IERC20Mintable {
    function mint(address to, uint256 value) external;
}

interface ITestNFT4907{
    struct Meta {
        address creator;
        uint256 typeNFT;
        uint8 nftLevel;
    }

    function getNFTMeta(uint256 tokenId) external view returns(Meta memory);
}

contract ReviewV2 is Context, Ownable{
    event Review(string reviewId, address storeContract, address reviewer, address nftAddress, uint256 nftId);

    using SafeMath for uint256;
    uint256 reward = 100;
    address private factoryContract;
    address private rewardToken;
    string private constant REVERT_INSUFFICIENT_BALANCE = "Review: Insufficient balance";
    string private constant REVERT_INVALID_NFT_OWNER = "Review: caller is not the owner of NFTs";
    string private constant REVERT_REVIEW_EXISTS = "Review: The NFT was used for review at this store";
    string private constant REVERT_INVALID_STARS = "Review: The review star is not valid";
    string private constant REVERT_INVALID_NFTType = "Review: The NFT Type is invalid";

    struct ReviewInfo{
        string reviewId;
        string storeId;
        address reviewer;
        address nftAddress;
        uint256 nftId;
    }

    mapping(string => ReviewInfo) private _reviewInfo;

    constructor(address _factoryContract, address _rewardToken, uint256 _reward){
        factoryContract = _factoryContract;
        rewardToken = _rewardToken;
        reward = _reward;
    }

    function getReward() public view returns(uint256){
        return reward;
    }

    function setReward(uint256 _reward) public onlyOwner{
        reward = _reward;
    }
   
    function getNFTLevel(address nftAddress, uint256 nftId) public view returns(uint8){
        uint8 nftLevel = ITestNFT4907(nftAddress).getNFTMeta(nftId).nftLevel;
        return nftLevel;
    }

    function review(string memory reviewId, string memory storeId, address nftAddress, uint256 nftId, uint stars) public{      
        require(stars >= 1 && stars <= 5, REVERT_INVALID_STARS);
        address account = _msgSender();        
        require(IERC721(nftAddress).ownerOf(nftId) == account, REVERT_INVALID_NFT_OWNER);

        IStakingFactory.Meta memory storeMeta = IStakingFactory(factoryContract).getInstanceMeta(storeId);
        ITestNFT4907.Meta memory nftMeta = ITestNFT4907(nftAddress).getNFTMeta(nftId);

        require(storeMeta.storeNFTType == nftMeta.typeNFT, REVERT_INVALID_NFTType);
      
        ReviewInfo memory reviewInfo = ReviewInfo(reviewId, storeId, account, nftAddress, nftId);
        _reviewInfo[reviewId] = reviewInfo;

        uint256 accountReward = reward.mul(nftMeta.nftLevel);
        uint256 storeReward = stars.mul(1e18);
        
        IERC20Mintable(rewardToken).mint(account, accountReward);
        IERC20Mintable(rewardToken).mint(storeMeta.storeAddress, storeReward);

        IStakingFactory(factoryContract).notifyRewardAmount(storeMeta.storeAddress, storeReward);
        
        emit Review(reviewId, storeMeta.storeAddress, account, nftAddress, nftId);
    }

    function getReview(string memory reviewId) public view returns(ReviewInfo memory){
        return _reviewInfo[reviewId];
    }
}