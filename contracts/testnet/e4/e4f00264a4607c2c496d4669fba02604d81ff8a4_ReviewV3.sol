/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-15
*/

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
    struct Metadata {
        address storeAddress;
        uint256 storeNFTType;
    }
    function notifyRewardAmount(address stakingContract, uint256 rewards) external;
    function getInstanceMeta(bytes32 storeId) external view returns(Metadata memory);
}

interface IERC20Mintable {
    function mint(address to, uint256 value) external;
}

interface ITest4907V2{
    struct Metadata {
        address creator;
        uint256 typeNFT;
        uint256 rarity;
        uint256 nftLevel;
        uint256 basicPerformance;
    }


    function metadata(uint256 tokenId) external view returns(Metadata memory);
    function getBaseCoin() external view returns(uint256);
}


contract Reviewable is Ownable{
    event ConfigLimitReview(address nftAddress, uint256 nftLevel, uint256 maxReview);

    struct ReviewsIn24h{
        address nftAddress;
        uint256 nftId;
        uint256 reviewTimes;
        uint256 lastReviewTime; // second
    }

    mapping(uint256 => uint256[]) private reviewableTypes; 
    mapping(address => mapping(uint256 => ReviewsIn24h)) private _reviewsIn24h;
    mapping(address => mapping(uint256 => uint256)) private _limitReviews;

    function configLimitReviews(address nftAddress, uint256[] memory nftLevels, uint256[] memory maxReviews) external onlyOwner{
        require(nftLevels.length == maxReviews.length, "Reviewable: Array length mismatch");
        for(uint256 i = 0; i < nftLevels.length; i++){
        _configLimitReview(nftAddress, nftLevels[i], maxReviews[i]);
        }
    }

    function _configLimitReview(address nftAddress, uint256 nftLevel, uint256 maxReview) internal{
        _limitReviews[nftAddress][nftLevel] = maxReview;
        emit ConfigLimitReview(nftAddress, nftLevel, maxReview);
    }

    function getLimitReview(address nftAddress, uint256 nftLevel) public view returns(uint256){
        return _limitReviews[nftAddress][nftLevel];
    }

    function getNFTReviewsIn24h(address nftAddress, uint256 nftId) public view returns(ReviewsIn24h memory){
        return _reviewsIn24h[nftAddress][nftId];
    }

    function updateNFTReviewTimesIn24h(address nftAddress, uint256 nftId, uint256 nftLevel) internal returns(bool){
        // nếu thời gian review dưới 1 ngày mà  reviewTimes >= maxReview thì k cho review nữa
        uint256 maxReview = _limitReviews[nftAddress][nftLevel];
        ReviewsIn24h storage reviewIn24h = _reviewsIn24h[nftAddress][nftId];
   
        if(block.timestamp - reviewIn24h.lastReviewTime <= (24*60*60)){
            if(reviewIn24h.reviewTimes >= maxReview) return false;
            else{
                reviewIn24h.reviewTimes += 1;
                reviewIn24h.lastReviewTime = block.timestamp;
            }
        }else{
            reviewIn24h.reviewTimes = 1;
            reviewIn24h.lastReviewTime = block.timestamp;
        }
        
        if(reviewIn24h.nftAddress == address(0)){
            reviewIn24h.nftAddress = nftAddress;
            reviewIn24h.nftId = nftId;
        }

        return true;
    }

    function getReviewableTypes(uint256 storeType) public view returns(uint256[] memory){
        return reviewableTypes[storeType];
    }

    function setReviewableTypes(uint256 storeType, uint256[] memory nftTypes) public onlyOwner{
        reviewableTypes[storeType] = nftTypes;  
    }

    function addReviewableType(uint256 storeType, uint256 nftType) public onlyOwner{
        reviewableTypes[storeType].push(nftType);
    }

    function removeReviewableType(uint256 storeType, uint256 nftType) public onlyOwner{
        uint256[] storage listTypes = reviewableTypes[storeType];
        uint256 length = listTypes.length;
        for(uint256 i = 0; i < length; i++){
            if(listTypes[i] == nftType){
                listTypes[i] = listTypes[length - 1];
                listTypes.pop();
                break;
            }
        }    
    }

    function isReviewable(uint256 storeType, uint256 nftType) public view returns(bool){
        for(uint256 i = 0; i < reviewableTypes[storeType].length; i++){
            if(reviewableTypes[storeType][i] == nftType)
                return true;
        }
        return false;
    }
}

contract ReviewV3 is Context, Reviewable{
    event Review(string reviewId, address storeContract, address reviewer, address nftAddress, uint256 nftId);

    using SafeMath for uint256;

    address private factoryContract;
    address private rewardToken;
    string private constant REVERT_INSUFFICIENT_BALANCE = "Review: Insufficient balance";
    string private constant REVERT_INVALID_NFT_OWNER = "Review: caller is not the owner of NFTs";
    string private constant REVERT_REVIEW_EXISTS = "Review: The NFT was used for review at this store";
    string private constant REVERT_INVALID_STAR = "Review: Invalid review star";
    string private constant REVERT_INVALID_NFTType = "Review: The NFT type to review is invalid";
    string private constant REVERT_INVALID_REVIEW_LIMIT = "Review: Exceeds NFT review limit per day";
    
    struct ReviewInfo{
        string reviewId;
        bytes32 storeId;
        address reviewer;
        address nftAddress;
        uint256 nftId;
    }

    mapping(string => ReviewInfo) private _reviewInfo;
 
    
    constructor(address _factoryContract, address _rewardToken){
        // factoryContract = 0xC473373223eAd3cB67F42445A2d616DeB3aaFadc;
        // rewardToken = 0x2F7265b97F6655F78AbBf13168e1FB4749A03bd0;
        addReviewableType(1,1);
        addReviewableType(2,2);
        addReviewableType(3,3);
        addReviewableType(1,4);
        addReviewableType(2,4);
        addReviewableType(3,4);
        // _configLimitReview(1,1);
        // _configLimitReview(2,2);
        // _configLimitReview(3,3);
        // setReviewableTypes(1, [1,4]); => loi lam
    }


    function getNFTMeta(address nftAddress, uint256 nftId) public view returns(ITest4907V2.Metadata memory){
        ITest4907V2.Metadata memory meta = ITest4907V2(nftAddress).metadata(nftId);
        return meta;
    }


    function getInstanceMetadata(bytes32 storeId) public view returns(IStakingFactory.Metadata memory){
        IStakingFactory.Metadata memory storeMeta = IStakingFactory(factoryContract).getInstanceMeta(storeId); 
        return storeMeta;
    }

    function review(string memory reviewId, bytes32 storeId, address nftAddress, uint256 nftId, uint star) public{ 
        require(star >= 1 && star <= 5, REVERT_INVALID_STAR);
        address account = _msgSender();        
        require(IERC721(nftAddress).ownerOf(nftId) == account, REVERT_INVALID_NFT_OWNER);

        IStakingFactory.Metadata memory storeMeta = IStakingFactory(factoryContract).getInstanceMeta(storeId);
        ITest4907V2.Metadata memory nftMeta = ITest4907V2(nftAddress).metadata(nftId);
        require(isReviewable(storeMeta.storeNFTType, nftMeta.typeNFT), REVERT_INVALID_NFTType);
        require(updateNFTReviewTimesIn24h(nftAddress, nftId, nftMeta.nftLevel), REVERT_INVALID_REVIEW_LIMIT);
        ReviewInfo memory reviewInfo = ReviewInfo(reviewId, storeId, account, nftAddress, nftId);
        _reviewInfo[reviewId] = reviewInfo;

        uint256 baseCoin = 100000000000000000;//ITest4907V2(nftAddress).getBaseCoin(); // in wei
        uint256 accountReward = baseCoin.mul(nftMeta.nftLevel).mul(nftMeta.basicPerformance);
        uint256 storeReward = star.mul(1e18);
        
        IERC20Mintable(rewardToken).mint(account, accountReward);
        IERC20Mintable(rewardToken).mint(storeMeta.storeAddress, storeReward);

        IStakingFactory(factoryContract).notifyRewardAmount(storeMeta.storeAddress, storeReward);
        
        emit Review(reviewId, storeMeta.storeAddress, account, nftAddress, nftId);
    }

    function getReview(string memory reviewId) public view returns(ReviewInfo memory){
        return _reviewInfo[reviewId];
    }
}