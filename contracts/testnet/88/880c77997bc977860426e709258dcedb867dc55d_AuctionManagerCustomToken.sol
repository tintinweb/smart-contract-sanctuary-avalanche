/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-03
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

    function ownerOf(uint256 tokenId) external view returns (address owner);

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

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

contract AuctionManagerCustomToken is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint;
    using SafeERC20 for IERC20;
    uint _auctionIdCounter; // auction Id counter

    enum AuctionState { 
        OPEN,
        CANCELLED,
        ENDED,
        DIRECT_BUY
    }

    struct Bid { // A bid on an auction
        address sender;
        uint256 bid;
    }

    struct Auction {
        address creator; // The address of the auction creator
        uint256 startPrice; // The starting price of the auction
        uint256 maxBid; // The highest bid of the auction
        address maxBidder; // The address of the highest bidder
        uint256 directBuyPrice; // The direct buy price of the auction
        uint256 minIncrement; // The minimum increment of the auction
        bool isDirectBuy; // Whether the auction is ended by a direct buy
        bool isCancelled; // Whether the auction is cancelled
        uint256 endTime; // The end time of the auction
        address nftAddress; // The address of the NFT contract
        uint256 tokenId; // The token id of the auction
        uint256 feeRatio; // The fee ratio of the auction
        uint256 auctionId;
    }

    mapping(uint => Auction) public auctions; // auctions
    mapping(uint => bool) public isClaimed;
    mapping(address => bool) public nftContracts; // Allowed NFT addresses
    address[] public nftContractsList; // Allowed NFT addresses
    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions; // NFT contract tokenId to Auction mapping
    mapping(uint256 => Bid[]) private bids; // NFT contract auctionId to Bid mapping
    uint256 private feeRatio;
    mapping(address => uint256) private userClaimableBids;
    mapping(address => uint256) private userClaimableNfts;

    constructor(uint256 _feeRatio) {
        feeRatio = _feeRatio;
    }

    function addNewContract(address _newNFTAddress) external onlyOwner {
        nftContracts[_newNFTAddress] = true;
        nftContractsList.push(_newNFTAddress);
    }

    function setFeeRatio(uint256 newFeeRatio) public onlyOwner {
        feeRatio = newFeeRatio;
    }

    function getFeeRatio() public view returns(uint256) {
        return feeRatio;
    }

    function getNFTList() external view returns(address[] memory) {
        return nftContractsList;
    }

    function getUserTokenIds(address _nftContract, uint256 _start, uint256 _end) external view returns(uint256[] memory) {
        IERC721 _nft = IERC721(_nftContract);
        uint256 _balance = _nft.balanceOf(msg.sender);
        uint256[] memory _tokenIds = new uint256[](_balance);
        uint256 _index = 0;

        for(uint i = _start; i < _end; i++) {
            if(_nft.ownerOf(i) == msg.sender) {
                _tokenIds[_index] = i;
                _index++;
            }
        }
        return _tokenIds;
    }
    
    // create an auction
    function createAuction(uint _endTime, uint _minIncrement, uint _directBuyPrice,uint _startPrice,address _nftAddress,uint _tokenId) external returns (bool) {
        //require(_directBuyPrice > 0, "Direct buy price must be greater than 0!"); // direct buy price must be greater than 0
        if(_directBuyPrice > 0) {
            require(_startPrice < _directBuyPrice,"Start price is smaller than direct buy price!"); // start price is smaller than direct buy price
        }
        require(_minIncrement >= 10 ** 16, "Minimum increment must be greater or equal to 0.01!"); // minimum increment must be greater than 0
        require(_endTime > 1 minutes, "End time must be greater than 1 minutes!"); // end time must be greater than 5 minutes (setting it to 5 minutes for testing you can set it to 1 days or anything you would like)
        require(nftContracts[_nftAddress], "NFT is not a part of the Collections."); // the nft contract must be added to the auction manager

        uint auctionId = _auctionIdCounter; // get the current value of the counter
        _auctionIdCounter++; // increment the counter
        
        Auction memory _auction = Auction(
            msg.sender, 
            _startPrice, 
            0, 
            payable(msg.sender), 
            _directBuyPrice, 
            _minIncrement, 
            false, 
            false, 
            block.timestamp +  _endTime, 
            _nftAddress, 
            _tokenId, 
            feeRatio,
            auctionId); // create the auction
        
        IERC721 _nftToken = IERC721(_nftAddress); // get the nft token
        _nftToken.transferFrom(msg.sender, address(this), _tokenId); // transfer the token to the auction
        userClaimableBids[msg.sender] += 1; // add one to the user's claimable bid count
        userClaimableNfts[msg.sender] += 1; // Check the case for no bidders
        auctions[auctionId] = _auction; // add the auction to the map
        nftContractAuctions[_nftAddress][_tokenId] = _auction; // add the auction to the nft contract auction map
        return true;
    }

    function getAuctionNumber() public view returns(uint) {
        return _auctionIdCounter;
    }

    // Return the information of each auction address
    function getAuctionInfo(uint256 _lastNumber)
        external
        view
        returns (
            uint256[] memory directBuy,
            address[] memory owner,
            uint256[] memory highestBid,
            address[] memory highestBidder,
            uint256[] memory tokenIds,
            uint256[] memory endTime,
            uint256[] memory startPrice,
            uint256[] memory auctionStates,
            address[] memory auctionNFTAddress,
            uint256[] memory auctionIds
        )
    {
        if(_lastNumber > _auctionIdCounter) {
            _lastNumber = _auctionIdCounter;
        }
        directBuy = new uint256[](_lastNumber); // create an array of size equal to the length of the passed array
        owner = new address[](_lastNumber); // create an array of size equal to the length of the passed array
        highestBid = new uint256[](_lastNumber);
        highestBidder = new address[](_lastNumber);
        tokenIds = new uint256[](_lastNumber);
        endTime = new uint256[](_lastNumber);
        startPrice = new uint256[](_lastNumber);
        auctionStates = new uint256[](_lastNumber);
        auctionNFTAddress = new address[](_lastNumber);
        auctionIds = new uint256[](_lastNumber);


        for (uint256 i = 0; i < _lastNumber; i++) { // for each auction
            directBuy[i] = auctions[_auctionIdCounter - i - 1].directBuyPrice; // get the direct buy price
            owner[i] = auctions[_auctionIdCounter - i - 1].creator; // get the owner of the auction
            highestBid[i] = auctions[_auctionIdCounter - i - 1].maxBid; // get the highest bid
            highestBidder[i] = auctions[_auctionIdCounter - i - 1].maxBidder;
            tokenIds[i] = auctions[_auctionIdCounter - i - 1].tokenId; // get the token id
            endTime[i] = auctions[_auctionIdCounter - i - 1].endTime; // get the end time
            startPrice[i] = auctions[_auctionIdCounter - i - 1].startPrice; // get the start price
            auctionStates[i] = uint256(getAuctionState(auctions[_auctionIdCounter - i - 1].auctionId)); // get the auction state
            auctionNFTAddress[i] = auctions[_auctionIdCounter - i - 1].nftAddress;
            auctionIds[i] = auctions[_auctionIdCounter - i - 1].auctionId;
        }
        
        return ( // return the arrays
            directBuy,
            owner,
            highestBid,
            highestBidder,
            tokenIds,
            endTime,
            startPrice,
            auctionStates,
            auctionNFTAddress,
            auctionIds
        );
    }

    function getClaimableBids(uint256 _lastNumber)
        external
        view
        returns (
            uint256[] memory highestBid,
            uint256[] memory tokenIds,
            address[] memory auctionNFTAddress,
            uint256[] memory auctionIds
        )
    {
        if(_lastNumber > _auctionIdCounter) {
            _lastNumber = _auctionIdCounter;
        }
        address _auctionOwner;
        uint256 _auctionState;
        address _highestBidder;
        uint256 _highestBid;
        uint256 _index = 0;

        highestBid = new uint256[](userClaimableBids[msg.sender]);
        tokenIds = new uint256[](userClaimableBids[msg.sender]);
        auctionNFTAddress = new address[](userClaimableBids[msg.sender]);
        auctionIds = new uint256[](userClaimableBids[msg.sender]);

        for (uint256 i = 0; i < _lastNumber; i++) { // for each auction
            _auctionState = uint256(getAuctionState(auctions[_auctionIdCounter - i - 1].auctionId));
            if(_auctionState == 2 || _auctionState == 3) {
                _auctionOwner = auctions[_auctionIdCounter - i - 1].creator; // get the owner of the auction
                _highestBidder = auctions[_auctionIdCounter - i - 1].maxBidder;
                _highestBid = auctions[_auctionIdCounter - i - 1].maxBid;
                if(msg.sender == _auctionOwner && !isClaimed[auctions[_auctionIdCounter - i - 1].auctionId]) {
                    highestBid[_index] = _highestBid;
                    tokenIds[_index] = auctions[_auctionIdCounter - i - 1].tokenId; // get the token id
                    auctionNFTAddress[_index] = auctions[_auctionIdCounter - i - 1].nftAddress;
                    auctionIds[_index] = auctions[_auctionIdCounter - i - 1].auctionId;
                    _index++;
                }
            }
        }
        
        return ( // return the arrays
            highestBid,
            tokenIds,
            auctionNFTAddress,
            auctionIds
        );
    }

    // Return the information of each auction address
    function getClaimableNFTs(uint256 _lastNumber)
        external
        view
        returns (
            uint256[] memory tokenIds,
            address[] memory auctionNFTAddress,
            uint256[] memory auctionIds
        )
    {
        if(_lastNumber > _auctionIdCounter) {
            _lastNumber = _auctionIdCounter;
        }
        address _auctionOwner;
        uint256 _auctionState;
        address _highestBidder;
        uint256 _highestBid;
        uint256 _index = 0;

        tokenIds = new uint256[](userClaimableNfts[msg.sender]);
        auctionNFTAddress = new address[](userClaimableNfts[msg.sender]);
        auctionIds = new uint256[](userClaimableNfts[msg.sender]);

        for (uint256 i = 0; i < _lastNumber; i++) { // for each auction
            _auctionState = uint256(getAuctionState(auctions[_auctionIdCounter - i - 1].auctionId));
            if(_auctionState == 2 || _auctionState == 3) {
                _auctionOwner = auctions[_auctionIdCounter - i - 1].creator; // get the owner of the auction
                _highestBidder = auctions[_auctionIdCounter - i - 1].maxBidder;
                _highestBid = auctions[_auctionIdCounter - i - 1].maxBid;
                if(msg.sender == _highestBidder && !isClaimed[auctions[_auctionIdCounter - i - 1].auctionId]) {
                    tokenIds[_index] = auctions[_auctionIdCounter - i - 1].tokenId; // get the token id
                    auctionNFTAddress[_index] = auctions[_auctionIdCounter - i - 1].nftAddress;
                    auctionIds[_index] = auctions[_auctionIdCounter - i - 1].auctionId;
                    _index++;
                }
            }
        }
        
        return ( // return the arrays
            tokenIds,
            auctionNFTAddress,
            auctionIds
        );
    }

    function getUserAuctions(uint256 _lastNumber)
        external
        view
        returns (
            uint256[] memory tokenIds,
            address[] memory auctionNFTAddress,
            uint256[] memory auctionIds
        )
    {
        if(_lastNumber > _auctionIdCounter) {
            _lastNumber = _auctionIdCounter;
        }
        address _auctionOwner;
        uint256 _auctionState;
        uint256 _index = 0;

        tokenIds = new uint256[](userClaimableBids[msg.sender]);
        auctionNFTAddress = new address[](userClaimableBids[msg.sender]);
        auctionIds = new uint256[](userClaimableBids[msg.sender]);

        for (uint256 i = 0; i < _lastNumber; i++) { // for each auction
            _auctionState = uint256(getAuctionState(auctions[_auctionIdCounter - i - 1].auctionId));
            if(_auctionState == 0) {
                _auctionOwner = auctions[_auctionIdCounter - i - 1].creator; // get the owner of the auction
                if(msg.sender == _auctionOwner && !isClaimed[auctions[_auctionIdCounter - i - 1].auctionId]) {
                    tokenIds[_index] = auctions[_auctionIdCounter - i - 1].tokenId; // get the token id
                    auctionNFTAddress[_index] = auctions[_auctionIdCounter - i - 1].nftAddress;
                    auctionIds[_index] = auctions[_auctionIdCounter - i - 1].auctionId;
                    _index++;
                }
            }
        }
        
        return ( // return the arrays
            tokenIds,
            auctionNFTAddress,
            auctionIds
        );
    }

    // Returns a list of all bids and addresses
    function allBids(uint256 _auctionId)
        external
        view
        returns (address[] memory, uint256[] memory)
    {
        uint256 _maxReturn = 10;
        Bid[] memory _bids = bids[_auctionId]; // get the bids of the auction
        if(_bids.length < _maxReturn) {
            _maxReturn = _bids.length;
        }
        address[] memory addrs = new address[](_maxReturn);
        uint256[] memory bidPrice = new uint256[](_maxReturn);
        for (uint256 i = 0; i < _maxReturn; i++) {
            addrs[i] = _bids[_bids.length - 1 - i].sender;
            bidPrice[i] = _bids[_bids.length - 1 - i].bid;
        }
        return (addrs, bidPrice);
    }


    // Place a bid on the auction
    function placeBid(address _nftContract, uint256 _tokenId) payable external returns(bool) {
        require(nftContracts[_nftContract], "NFT is not a part of the Collections."); // the nft contract must be added to the auction manager
        Auction storage _auction = nftContractAuctions[_nftContract][_tokenId]; // get the auction


        require(msg.sender != _auction.creator, "You cannot bid on your own auction. Consider cancelling."); // The auction creator can not place a bid
        require(getAuctionState(_auction.auctionId) == AuctionState.OPEN, "Auction is closed."); // The auction must be open
        require(msg.value >= _auction.startPrice, "The bid must be higher than the starting price"); // The bid must be higher than the starting price
        require(msg.value >= _auction.maxBid + _auction.minIncrement || msg.value == _auction.directBuyPrice, "The bid must be higher or equal to the current bid + the minimum increment"); // The bid must be higher than the current bid + the minimum increment
        
        if(_auction.directBuyPrice > 0) { // If the bid is higher than the direct buy price
            require(msg.value <= _auction.directBuyPrice); // The bid must be lower or equal to the direct buy price
        }
        userClaimableNfts[msg.sender] += 1;

        address payable lastHightestBidder = payable(_auction.maxBidder); // The address of the last highest bidder
        uint256 lastHighestBid = _auction.maxBid; // The last highest bid
        _auction.maxBid = msg.value; // The new highest bid
        _auction.maxBidder = payable(msg.sender); // The address of the new highest bidder

        nftContractAuctions[_nftContract][_tokenId] = _auction; // update the auction
        auctions[_auction.auctionId] = _auction;

        if(msg.value >= _auction.directBuyPrice && _auction.directBuyPrice > 0) { // If the bid is higher than the direct buy price
            _auction.isDirectBuy = true; // The auction has ended
            nftContractAuctions[_nftContract][_tokenId] = _auction; // update the auction
            auctions[_auction.auctionId] = _auction;
            exchangeAssets(_nftContract, _tokenId); // Withdraw the token
        }
        bids[_auction.auctionId].push(Bid(msg.sender, msg.value)); // Add the new bid to the list of bids

        if(lastHighestBid != 0){ // if there is a bid
            lastHightestBidder.transfer(lastHighestBid); // refund the previous bid to the previous highest bidder
        }
        userClaimableNfts[lastHightestBidder] -= 1; // remove the claimable nft from the user

        emit NewBid(msg.sender, msg.value, _nftContract, _tokenId); // emit a new bid event
        return true; // The bid was placed successfully
    }

    function exchangeAssets(address _nftContract, uint256 _tokenId) public returns(bool) {
        require(nftContracts[_nftContract], "NFT is not a part of HeC Collections."); // the nft contract must be added to the auction manager
        Auction memory _auction = nftContractAuctions[_nftContract][_tokenId]; // get the auction
        IERC721 _nft = IERC721(_nftContract); // get the nft contract

        require(getAuctionState(_auction.auctionId) == AuctionState.ENDED || getAuctionState(_auction.auctionId) == AuctionState.DIRECT_BUY, "The auction must be ended by either a direct buy or timeout");
        require(msg.sender == _auction.creator || msg.sender == _auction.maxBidder, "You do not have the right to claim the funds.");
        require(!isClaimed[_auction.auctionId], "Rewards already claimed.");

        _nft.transferFrom(address(this), _auction.maxBidder, _tokenId); // Transfer the token to the highest bidder
        emit WithdrawToken(_auction.maxBidder, _nftContract, _tokenId); // Emit a withdraw token event

        uint256 fee = (_auction.maxBid * _auction.feeRatio) / 100;
        payable(owner()).transfer(fee); // sends fee to marketplace 
        payable(_auction.creator).transfer(_auction.maxBid - fee); // Transfers funds to the creator
        emit WithdrawFunds(msg.sender, _auction.maxBid, _nftContract, _tokenId); // Emit a withdraw funds event

        isClaimed[_auction.auctionId] = true;
        auctions[_auction.auctionId] = _auction;
        nftContractAuctions[_nftContract][_tokenId] = _auction;

        userClaimableBids[_auction.creator] -= 1;
        userClaimableNfts[_auction.maxBidder] -= 1;
        return true;
    }

    function cancelAuction(address _nftContract, uint256 _tokenId) external returns(bool){ // Cancel the auction
        require(nftContracts[_nftContract], "NFT is not a part of HeC Collections."); // the nft contract must be added to the auction manager
        Auction memory _auction = nftContractAuctions[_nftContract][_tokenId]; // get the auction
        IERC721 _nft = IERC721(_nftContract); // get the nft contract

        require(msg.sender == _auction.creator, "You must be the owner of the auction to cancel."); // Only the auction creator can cancel the auction
        require(getAuctionState(_auction.auctionId) == AuctionState.OPEN, "Auction is already closed."); // The auction must be open
        require(_auction.maxBid == 0, "There is already a bid, cannot cancel auction."); // The auction must not be cancelled if there is a bid
        _auction.isCancelled = true; // The auction has been cancelled
        _nft.transferFrom(address(this), _auction.creator, _auction.tokenId); // Transfer the NFT token to the auction creator

        nftContractAuctions[_nftContract][_tokenId] = _auction; // update the auction
        auctions[_auction.auctionId] = _auction;
        userClaimableBids[msg.sender] -= 1;
        emit AuctionCanceled(_nftContract, _tokenId); // Emit Auction Canceled event
        return true;
    } 

    // Get the auction state
    function getAuctionState(uint256 _auctionId) public view returns(AuctionState) {
        Auction memory _auction = auctions[_auctionId]; // get the auction

        if(_auction.isCancelled) return AuctionState.CANCELLED; // If the auction is cancelled return CANCELLED
        if(_auction.isDirectBuy) return AuctionState.DIRECT_BUY; // If the auction is ended by a direct buy return DIRECT_BUY
        if(block.timestamp >= _auction.endTime) return AuctionState.ENDED; // The auction is over if the block timestamp is greater than the end timestamp, return ENDED
        return AuctionState.OPEN; // Otherwise return OPEN
    } 

    event NewBid(address bidder, uint bid, address nftContract, uint256 tokenId); // A new bid was placed
    event WithdrawToken(address withdrawer, address nftContract, uint256 tokenId); // The auction winner withdrawed the token
    event WithdrawFunds(address withdrawer, uint256 amount, address nftContract, uint256 tokenId); // The auction owner withdrawed the funds
    event AuctionCanceled(address nftContract, uint256 tokenId); // The auction was cancelled
}