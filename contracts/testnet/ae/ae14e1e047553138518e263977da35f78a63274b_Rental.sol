/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT

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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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
    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function metadata(uint256 tokenId) external view returns (address creator);
}

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
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

contract Withdrawable is Ownable {
    string internal constant REVERT_TRANSFER_FAILED = "Withdrawable: AVAX_TRANSFER_FAILED";

    function withdrawToken(address _token, uint256 _amount) external onlyOwner {
        address account = _msgSender();
        if (_token == address(0)) {
            (bool success, ) = account.call{value: _amount}(new bytes(0));
            require(success, REVERT_TRANSFER_FAILED);
        } else {
            IERC20(_token).transfer(account, _amount);
        }
    }
}

contract Rental is Withdrawable {
    event SetListRental(uint256 orderId, address game, uint256 tokenId, address owner, address paymentToken, uint256 price, uint256 ownerRewardRate, uint256 period);
    event Rent(address account, uint256 orderId);
    event ResetPrice(uint256 orderId);
    
    using SafeMath for uint256;

    uint256 private commission;
    address private taker;

    string private constant REVERT_NOT_A_OWNER_NFTS = "Rental: caller is not the owner of NFTs";
    string private constant REVERT_NOT_A_MAKER = "Rental: caller is not a maker";
    string private constant REVERT_ALREADY_RENTING = "Rental: already renting";
    string private constant REVERT_APPROVE_NFTS = "Rental: owner is not approve this NFT";
    string private constant REVERT_INVALID_PERIOD = "Rental: Invalid renting period";
    string private constant REVERT_INVALID_RENTING_NFT = "Rental: NFT has been rented by other user!";
    string private constant REVERT_INVALID_ADDRESS = "Rental: Invalid Address";
    string private constant REVERT_INVALID_RATE = "Rental: Invalid commission or reward rate";
    string private constant REVERT_INSUFFICIENT_BALANCE = "Rental: Insufficient balance";


    struct RentalInfo {
        address nftAddress;
        uint256 nftId;
        address owner;
        address renter;
        address paymentToken;
        uint256 price;
        uint256 ownerRewardRate;
        uint256 period;
        uint64 endTime;
    }

    mapping(uint256 => RentalInfo) private _rentalInfo;

    constructor(uint256 _commission, address _taker) {
        commission = _commission;
        taker = _taker;
    }

    modifier onlyMaker(uint256 orderId) {
        require(_msgSender() == _rentalInfo[orderId].owner, REVERT_NOT_A_MAKER);
        _;
    }

    modifier isOwnerOf(address nftAddress, uint256 tokenId) {
        require(_isOwnerOf(nftAddress, tokenId), REVERT_NOT_A_OWNER_NFTS);
        _;
    }

    modifier isValidAddress(address addr) {
        require(addr == address(addr), REVERT_INVALID_ADDRESS);
        _;
    }

    modifier isNotRenting(uint256 orderId) {
        require(_rentalInfo[orderId].renter == address(0), REVERT_ALREADY_RENTING);
        _;
    }

    modifier isValidRentingNFT(address nftAddress, uint256 tokenId) {
        require(IERC4907(nftAddress).userExpires(tokenId) < block.timestamp, REVERT_INVALID_RENTING_NFT);
        _;
    }

    modifier isValidPeriod(uint256 period) {
        require(period > 0, REVERT_INVALID_PERIOD);
        _;
    }

     modifier isValidRate(uint256 rate) {
        require(rate >= 0 && rate < 100, REVERT_INVALID_RATE);
        _;
    }

    function getCommission() public view returns(uint256){
        return commission;
    }

    function getTaker() public view returns(address) {
        return taker;
    }

    function setCommission(uint256 _commission) public onlyOwner isValidRate(_commission){
        commission = _commission;
    }

    // notes: is taker can be address(0)?
     function setTaker(address _taker) public onlyOwner isValidAddress(_taker){
        taker = _taker;
    }

    function _isOwnerOf(address nftAdress, uint256 tokenId) private view returns (bool) {
        return (IERC721(nftAdress).ownerOf(tokenId) == _msgSender());
    }

    function getRentalInfo(uint256 orderId) external view returns(RentalInfo memory) {
        return _rentalInfo[orderId];
    }

    function rent(uint256 orderId) external isNotRenting(orderId) {
        address account = _msgSender();
        RentalInfo storage rental = _rentalInfo[orderId];
        require(rental.period > 0, REVERT_INVALID_PERIOD);
        if(rental.paymentToken == address(0))
            rental.paymentToken = 0x2F7265b97F6655F78AbBf13168e1FB4749A03bd0;

        uint256 commissionFee = rental.price * commission / 100;
        uint256 netRevenue = rental.price * (100 - commissionFee) / 100;
        require(IERC20(rental.paymentToken).transferFrom(account, rental.owner, netRevenue),REVERT_INSUFFICIENT_BALANCE);
        require(IERC20(rental.paymentToken).transferFrom(account, taker, commissionFee),REVERT_INSUFFICIENT_BALANCE);

        uint64 endTime = uint64(block.timestamp + rental.period);
        rental.renter = account;
        rental.endTime = endTime;
        IERC4907(rental.nftAddress).setUser(rental.nftId, account, endTime);
        emit Rent(account, orderId);
    }

    function _setListRental(
        uint256 orderId,
        address nftAddress,
        uint256 tokenId,
        address paymentToken,
        uint256 price,
        uint256 ownerRewardRate,
        uint256 period
    ) private {
        require(_rentalInfo[orderId].owner == address(0) || _rentalInfo[orderId].owner == _msgSender(), REVERT_NOT_A_OWNER_NFTS);
        require(_rentalInfo[orderId].renter == address(0) , REVERT_ALREADY_RENTING);
        
        _rentalInfo[orderId] = RentalInfo(nftAddress, tokenId, _msgSender(), address(0), paymentToken, price, ownerRewardRate, period, 0);
        emit SetListRental(orderId, nftAddress, tokenId, _msgSender(), paymentToken, ownerRewardRate, price, period);
    }

    function listRental(
        uint256 orderId,
        address nftAddress,
        uint256 tokenId,
        address paymentToken,
        uint256 price,
        uint256 ownerRewardRate,
        uint256 period
    ) external isOwnerOf(nftAddress, tokenId) isValidRentingNFT(nftAddress, tokenId) isValidPeriod(period) isValidAddress(paymentToken) isValidRate(ownerRewardRate){
        // notes: Có thể chỉ check approve một NFT được không?      
        require(IERC721(nftAddress).isApprovedForAll(_msgSender(), address(this)), REVERT_APPROVE_NFTS);
        _setListRental(orderId, nftAddress, tokenId, paymentToken, price, ownerRewardRate, period);
    }

    function _resetRental(uint256 orderId) private {
        RentalInfo storage rental = _rentalInfo[orderId];
        rental.nftAddress = address(0);
        rental.nftId = 0;
        rental.paymentToken = address(0);
        rental.price = 0;
        rental.ownerRewardRate = 0;
        emit ResetPrice(orderId);
    }

    function removeRental(uint256 orderId) external onlyMaker(orderId) isNotRenting(orderId) {
        _resetRental(orderId);
    }

    function writeReviewByRentedNFTAndGetRewardImediately(address storeAddress, uint256 orderId) public{
        // require nft's renter
        // write review
        // Each review, user can get 10 tokens -> transfer to owner & renter by percentage
        RentalInfo storage rental = _rentalInfo[orderId];
        uint256 storeReward = 10;
        uint256 ownerReward = storeReward * rental.ownerRewardRate / 100;
        uint256 renterReward = storeReward * (100 - rental.ownerRewardRate) / 100;
        
        require(IERC20(rental.paymentToken).transferFrom(storeAddress, rental.owner, ownerReward),REVERT_INSUFFICIENT_BALANCE);
        require(IERC20(rental.paymentToken).transferFrom(storeAddress, rental.renter, renterReward),REVERT_INSUFFICIENT_BALANCE);
        // emit UserReviewAndGetRewardImmediately
    }

}