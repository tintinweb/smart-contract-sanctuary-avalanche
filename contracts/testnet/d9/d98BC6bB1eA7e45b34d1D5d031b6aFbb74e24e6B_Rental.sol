// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library TransferHelper {
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

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

contract PaymentTokens is Ownable {
    address[] public tokens;
    mapping(address => uint256) private indexOf;
    mapping(address => bool) private existed;

    modifier isValidPaymentToken(address fiat) {
        require(existed[fiat], "PaymentTokens: Invalid token!");
        _;
    }

    function isValidFiat(address fiat) external view returns(bool) {
        return existed[fiat];
    }

    function addPaymentOptions(address[] memory addedTokens) external onlyOwner {
       _addPaymentOptions(addedTokens);
    }

    function _addPaymentOptions(address[] memory addedTokens) internal {
        for (uint256 i = 0; i < addedTokens.length; i++) {

        if (!existed[addedTokens[i]]) {
            existed[addedTokens[i]] = true;
            indexOf[addedTokens[i]] = tokens.length;
            tokens.push(addedTokens[i]);
        }
      }
    }

    function deletePaymentMethod(address[] memory removedTokens) external onlyOwner {
        for (uint256 i = 0; i< removedTokens.length; i++) {
            _deletePaymentMethod(removedTokens[i]);
        }
    }

    function _deletePaymentMethod(address token) internal {
      require(existed[token] == true, "Non existed token!");

      uint256 index = indexOf[token];
      uint256 lastIndex = tokens.length - 1;
      tokens[index] = tokens[lastIndex];
      indexOf[tokens[lastIndex]] = index;            
      delete existed[token];
      delete indexOf[token];
      tokens.pop();
    }

    function getPaymentOptions() public view returns (address[] memory) {
        return tokens;
    }

}

contract Rental is PaymentTokens, Withdrawable {
    event SetListRental(uint256 orderId, address nftAddress, uint256 tokenId, address owner, uint256 ownerRewardRate, address paymentToken, uint256 price, uint256 period);
    event Rent(address account, uint256 orderId);
    event ResetPrice(uint256 orderId);
    
    using SafeMath for uint256;

    string private constant REVERT_NOT_A_OWNER_NFTS = "Rental: caller is not the owner of NFTs";
    string private constant REVERT_NOT_A_MAKER = "Rental: caller is not a maker";
    string private constant REVERT_ALREADY_RENTING = "Rental: already renting";
    string private constant REVERT_APPROVE_NFTS = "Rental: owner is not approve this NFT";
    string private constant REVERT_INVALID_PERIOD = "Rental: Invalid renting period";
    string private constant REVERT_INVALID_RENTING_NFT = "Rental: NFT has been rented by other user!";
    string private constant REVERT_ALREADY_LISTED = "Rental: NFT has been listed";
    string private constant REVERT_INVALID_ADDRESS = "Rental: Can not be address 0";
    string private constant REVERT_INVALID_RATE = "Rental: Invalid commission or reward rate";
    string private constant REVERT_INSUFFICIENT_BALANCE = "Rental: Insufficient balance";


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
        uint256 orderId;
    }

    uint256 public maxPercent = 10000;
    uint256 private commission;
    address private taker;

    mapping(uint256 => RentalInfo) private _rentalInfo; 
    mapping(address => mapping (uint256 => RentalInfo)) private _rentalInfoOf;

    constructor(uint256 _commission, address _taker) {
        commission = _commission;
        taker = _taker;
        address[] memory addrs = new address[](2);
        addrs[0] = address(0);
        addrs[1] = 0x2F7265b97F6655F78AbBf13168e1FB4749A03bd0;
        _addPaymentOptions(addrs);
    }

    modifier onlyMaker(uint256 orderId) {
        require(_msgSender() == _rentalInfo[orderId].owner, REVERT_NOT_A_MAKER);
        _;
    }

    modifier isValidAddress(address addr) {
        require(addr != address(0), REVERT_INVALID_ADDRESS);
        _;
    }

    modifier isNotRenting(uint256 orderId) {
        require(_rentalInfo[orderId].renter == address(0), REVERT_ALREADY_RENTING);
        _;
    }

    modifier isValidRentingNFT(address nftAddress, uint256 tokenId, uint256 orderId) {
        require(_isOwnerOf(nftAddress, tokenId), REVERT_NOT_A_OWNER_NFTS);
        RentalInfo memory info = _rentalInfoOf[nftAddress][tokenId];
        if (info.orderId != 0 && info.orderId != orderId) {
            require(info.renter != address(0), REVERT_ALREADY_LISTED);
        }
        require(IERC4907(nftAddress).userExpires(tokenId) < block.timestamp, REVERT_INVALID_RENTING_NFT);
        _;
    }

    modifier isValidPeriod(uint256 period) {
        require(period > 0, REVERT_INVALID_PERIOD);
        _;
    }

    modifier isValidRate(uint256 rate) {
        require(rate >= 0 && rate < maxPercent, REVERT_INVALID_RATE);
        _;
    }

    function _isOwnerOf(address nftAdress, uint256 tokenId) private view returns (bool) {
        return (IERC721(nftAdress).ownerOf(tokenId) == _msgSender());
    }

    function getCommission() external view returns(uint256){
        return commission;
    }

    function getTaker() external view returns(address) {
        return taker;
    }

    function setCommission(uint256 _commission) external onlyOwner isValidRate(_commission) {
        commission = _commission;
    }

     function setTaker(address _taker) external onlyOwner isValidAddress(_taker) {
        taker = _taker;
    }


    function getRentalInfo(uint256 orderId) external view returns(RentalInfo memory) {
        return _rentalInfo[orderId];
    }

    function getRentalInfo(address nftAddress, uint256 nftId) external view returns(RentalInfo memory) {
        return _rentalInfoOf[nftAddress][nftId];
    }

    function rent(uint256 orderId) external payable isNotRenting(orderId) {
        address account = _msgSender();
        RentalInfo storage rental = _rentalInfo[orderId];
        require(rental.period > 0, REVERT_INVALID_PERIOD);
        uint256 commissionFee = rental.price.mul(commission).div(maxPercent);
        uint256 netRevenue = rental.price.sub(commissionFee);
        
        if (rental.paymentToken == address(0)) {
            require(msg.value >= rental.price, REVERT_INSUFFICIENT_BALANCE);
            TransferHelper.safeTransferETH(rental.owner, netRevenue);
            TransferHelper.safeTransferETH(taker, commissionFee);
        } else {
            require(IERC20(rental.paymentToken).transferFrom(account, rental.owner, netRevenue), REVERT_INSUFFICIENT_BALANCE);
            require(IERC20(rental.paymentToken).transferFrom(account, taker, commissionFee), REVERT_INSUFFICIENT_BALANCE);
        }

        uint64 endTime = uint64(block.timestamp + rental.period);
        rental.renter = account;
        rental.endTime = endTime;
        _rentalInfoOf[rental.nftAddress][rental.nftId] = rental;
        IERC4907(rental.nftAddress).setUser(rental.nftId, account, endTime);
        emit Rent(account, orderId);
    }

    function _setListRental(
        uint256 orderId,
        address nftAddress,
        uint256 tokenId,
        uint256 ownerRewardRate,
        address paymentToken,
        uint256 price,
        uint256 period
    ) private {
        address account = _msgSender();
        require(_rentalInfo[orderId].owner == address(0) || _rentalInfo[orderId].owner == account, REVERT_NOT_A_OWNER_NFTS);
        require(_rentalInfo[orderId].renter == address(0) , REVERT_ALREADY_RENTING);
        _rentalInfo[orderId] = RentalInfo(nftAddress, tokenId, account, ownerRewardRate, address(0), paymentToken, price, period, 0, orderId);
        emit SetListRental(orderId, nftAddress, tokenId, account, ownerRewardRate, paymentToken, price, period);
    }

    function listRental(
        uint256 orderId,
        address nftAddress,
        uint256 tokenId,
        uint256 ownerRewardRate,
        address paymentToken,
        uint256 price,
        uint256 period
    ) external isValidRentingNFT(nftAddress, tokenId, orderId) isValidRate(ownerRewardRate) isValidPeriod(period) isValidPaymentToken(paymentToken) {
        require(IERC721(nftAddress).isApprovedForAll(_msgSender(), address(this)), REVERT_APPROVE_NFTS);
        _setListRental(orderId, nftAddress, tokenId, ownerRewardRate, paymentToken, price, period);
    }

    function _resetRental(uint256 orderId) private {
        RentalInfo storage rental = _rentalInfo[orderId];
        rental.nftAddress = address(0);
        rental.nftId = 0;
        rental.paymentToken = address(0);
        rental.price = 0;
        emit ResetPrice(orderId);
    }

    function removeRental(uint256 orderId) external onlyMaker(orderId) isNotRenting(orderId) {
        _resetRental(orderId);
    }

    function setMaxPercent(uint256 percent) external onlyOwner {
        require(percent >= 1000, REVERT_INVALID_RATE);
        maxPercent = percent;
    }
}