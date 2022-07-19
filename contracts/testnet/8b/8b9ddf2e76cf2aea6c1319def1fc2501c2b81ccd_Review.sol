/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-18
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

interface IRental{
    struct RentalInfo {
        address nftAddress;
        uint256 nftId;
        address owner;
        uint256 ownerRewardRate;
        address renter;
        address paymentToken;
        uint256 price;
        uint256 period;
        uint64 endTime;
    }

    function getRentalInfo(address nftAddress, uint256 nftId) external returns(RentalInfo memory);
}


contract Review is Context{
    event Review(uint256 reviewId, address storeContract, address reviewer, address nftAddress, uint256 nftId);

    using SafeMath for uint256;
    uint256 reward = 100;
    // Contract that use for NFT Renting (renter will get a part of reward when reviewing)
    address private rentalContract;
    string private constant REVERT_INSUFFICIENT_BALANCE = "Review: Insufficient balance";
    string private constant REVERT_NOT_OWNER_OR_RENTER_NFTS = "Rental: caller is not the owner or the current renter of NFTs";

    struct ReviewInfo{
        uint256 reviewId;
        address storeContract;
        address reviewer;
        address nftAddress;
        uint256 nftId;
    }

    mapping(uint256 => ReviewInfo) private _reviewInfo;
    // The NFT was used before at the store
    mapping(address => ReviewInfo) private _reviewNFTExist;

    constructor(address _rentalContract, uint256 _reward){
        rentalContract = _rentalContract;
        reward = _reward;
    }

    function review(uint256 reviewId, address storeContract, address nftAddress, uint256 nftId) public{
        address account = _msgSender();
        
        IRental.RentalInfo memory rentalInfo =  IRental(rentalContract).getRentalInfo(nftAddress, nftId);

        bool isOwner = IERC721(nftAddress).ownerOf(nftId) == account;
        bool isRenter = rentalInfo.renter == account && rentalInfo.endTime > block.timestamp;
        
        require(isOwner || isRenter, REVERT_NOT_OWNER_OR_RENTER_NFTS);

        ReviewInfo memory reviewInfo = ReviewInfo(reviewId, storeContract, account, nftAddress, nftId);
        _reviewInfo[reviewId] = reviewInfo;

        if(isOwner){
            require(IERC20(rentalInfo.paymentToken).transferFrom(storeContract, account, reward), REVERT_INSUFFICIENT_BALANCE);
        }
        if(isRenter){ 
            uint256 ownerReward = reward.mul(rentalInfo.ownerRewardRate).div(100);
            require(IERC20(rentalInfo.paymentToken).transferFrom(storeContract, rentalInfo.owner, ownerReward),REVERT_INSUFFICIENT_BALANCE);
            require(IERC20(rentalInfo.paymentToken).transferFrom(storeContract, account, reward.sub(ownerReward)), REVERT_INSUFFICIENT_BALANCE);
        }   

        _reviewNFTExist[storeContract] = reviewInfo;
        
        emit Review(reviewId, storeContract, account, nftAddress, nftId);
    }

    function getReviewInfo(uint256 reviewId) public view returns(ReviewInfo memory){
        return _reviewInfo[reviewId];
    }

    function IsNFTReviewedAtStore(address storeContract, address nftAddress, uint256 nftId) public view returns(bool){
        ReviewInfo memory review = _reviewNFTExist[storeContract];
        if(review.nftAddress == nftAddress && review.nftId == nftId) return true;
        return false; 
    }

    // Notes: 
    /*
        - store không có tiền sao chuyển
        - nft đó được mang đi review tiép tại store đó thì tính sao?
          + khác user ?

    */
}