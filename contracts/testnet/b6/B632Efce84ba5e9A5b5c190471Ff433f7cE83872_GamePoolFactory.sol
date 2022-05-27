//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./access/Ownable.sol";
import "./token/IERC20.sol";
import "./GamePool.sol";

contract GamePoolFactory is Ownable {
    GamePool[] private gamePoolAddresses;
    string[] gameList;
    uint gameCounter;

    constructor() {
        gameCounter = 0;
    }

    // create gamepool with name and its invest & reward token or native coin
    // if native blockchain coin, use zero address for tokenAddress
    function createGamePool(string memory _gameName, address _tokenAddress, address _nftAddress)
        public
        onlyOwner
    {
        gameCounter += 1;
        GamePool newPool = new GamePool(msg.sender, _gameName, gameCounter, _tokenAddress, _nftAddress);
        gameList.push(_gameName);
        gamePoolAddresses.push(newPool);
    }

    function getGamePools() external view returns (GamePool[] memory) {
        return gamePoolAddresses;
    }

    function getGameList() public view returns (string[] memory){
        return gameList;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./token/IERC20.sol";
import "./token/IERC721Enumerable.sol";

contract GamePool {
    address owner;
    string public gameName;
    uint public gameId;
    uint public totalPool;          // total amount of invested coin/token
    address public tokenAddress;    // invest & reward token address
    address public nftAddress;      // nftAddress address
    uint public poolCounter = 0;
    bool public rewardInToken = false;
    bool public claimable;

    // InvestPool[] private investPools;

    struct RewardLog {
        uint weekNum;
        uint amount;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "No sufficient right");
        _;
    }

    function SetOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }

    mapping(uint256 => RewardLog) public rewardLogs;
    uint256 public rewardCounter = 0;

    constructor(
        address _ownerAddress,
        string memory _gameName,
        uint _gameId,
        address _tokenAddress,
        address _nftAddress
    ) {
        owner = _ownerAddress;
        gameName = _gameName;
        gameId = _gameId;
        nftAddress = _nftAddress;

        if(_tokenAddress != address(0)){
            tokenAddress = _tokenAddress;
            rewardInToken = true;
            // IERC20 tokenReward = IERC20(_tokenAddress);
        }else{
            tokenAddress = address(0);
        }
    }

    function createPool(
        uint _poolStart,
        uint _poolEnd,
        uint _poolHardcap,
        uint _minInvest
    ) public onlyOwner {
        uint _poolID = poolCounter + 1;
        // console.log(_poolID);
        // InvestPool newPool = new InvestPool(
        //     owner,
        //     _poolID,
        //     address(this),
        //     tokenAddress,
        //     gameName,
        //     gameId,
        //     _poolStart,
        //     _poolEnd,
        //     _poolHardcap,
        //     _minInvest
        // );

        // investPools.push(newPool);
    }

    // function returnAllPools() external view returns (InvestPool[] memory) {
    //     return investPools;
    // }

    // function contribute(address _poolAddress, uint _amount) public {
    //     uint256 minContributionAmount = InvestPool(_poolAddress).minInvest();
    //     InvestPool.PoolStatus projectState = InvestPool(_poolAddress).status();
    //     require(projectState == InvestPool.PoolStatus.OPEN, "Invalid state");
    //     require(_amount >= minContributionAmount, "Invest amount is too low !");

    //     // Call function
    //     InvestPool(_poolAddress).invest(_amount);

    //     // Trigger event
    //     // emit ContributionReceived(_poolAddress, msg.value, msg.sender);
    // }

    function poolClosed(uint _investPoolId, uint _investedAmount) public {
        // call from invest pool, with invest amount
        totalPool += _investedAmount;
        // console.log("Closed GamePool:", _investPoolId);
        // console.log("Amount:", _investedAmount);
    }

    function invest(
        uint _poolId,
        address _investor,
        uint _amount
    ) public {
        // insert invest log
    }


    function fillReward(uint weekNum) public payable onlyOwner {
        fillReward(msg.value, weekNum);
    }

    function fillReward(uint amount, uint weekNum) public onlyOwner {
        // insert reward token TUS
        RewardLog storage rewardDetail = rewardLogs[rewardCounter];
        rewardDetail.weekNum = weekNum;
        rewardDetail.amount = amount;
        rewardCounter += 1;

        if (tokenAddress != address(0)) {
            // move investment token to receiverAddress
            IERC20 token = IERC20(tokenAddress);
            // token.approve(address(this), amount);
            token.transferFrom(msg.sender, address(this), amount);
        }
    }

    function claimRewardStatus(bool _claimable) public onlyOwner {
        claimable = _claimable;
    }

    function claimAll() public {
        // claim all pool from user
        require(claimable, "Not Claim Period");

        address investor = msg.sender;
        IERC721Enumerable geekzPass = IERC721Enumerable(nftAddress);
        uint totalNFT = geekzPass.balanceOf(investor);
        for (uint i = 0; i < totalNFT; i++) {
            uint tokenId = geekzPass.tokenOfOwnerByIndex(investor, i);
            // (uint _gameId, uint _poolNum, uint _amount) = geekzPass.getTokenData(tokenId);
            // console.log(tokenId);
        }
        // get all NFT from Investor where gamepool=this gamepool

    }

    function getRewardPool() public {
        // claim all pool from user
    }

    function getRewardAll() public {
        // claim all pool from user
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../utils/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

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