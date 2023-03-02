// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./support/IERC721A.sol";

interface IEspionage is IERC20 {
    function mint(address _to, uint256 _amount) external;
}

error StakeSpies__AlreadyInitialised();
error StakeSpies__NotStarted();
error StakeSpies__NotTokenOwner();
error StakeSpies__NotTokenStaker();
error StakeSpies__TokenReleaseWithheld();
error StakeSpies__CantStake();

contract StakeSpies is Ownable, Pausable, IERC721Receiver {
    IEspionage public espionageToken;
    IERC721A public avaxSpiesNFT;

    uint256 public totalStaked;
    uint256 public stakeStart;
    uint256 public constant stakingTime = 10 minutes; // PROD_CHANGE to 1 days
    uint256 public rewardPerInterval = 10e18;

    struct SpiesStaked {
        uint256 balance;
        uint256 rewardsReleased;
        uint256 coolDownTimestamp;
        address spyOwner;
    }

    constructor(IERC721A _nftAddress, IEspionage _tokenAddress) {
        avaxSpiesNFT = _nftAddress;
        espionageToken = _tokenAddress;
    }

    mapping(uint256 => SpiesStaked) public stakedSpies;

    bool public releaseTokens;
    bool initialised;

    event Staked(address owner, uint256 tokenId);
    event Unstaked(address owner, uint256 tokenId);
    event RewardPaid(address indexed user, uint256 reward);
    event ReleaseTokens(bool status);

    function initialise() external onlyOwner {
        if (initialised) revert StakeSpies__AlreadyInitialised();
        stakeStart = block.timestamp;
        initialised = true;
    }

    function setReleaseTokens(bool _enabled) external onlyOwner {
        releaseTokens = _enabled;
        emit ReleaseTokens(_enabled);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function setRewardPerInterval(uint256 _newRewardValue) external onlyOwner {
        rewardPerInterval = _newRewardValue;
    }

    function stake(uint256 tokenId) external whenNotPaused {
        _stake(tokenId);
    }

    function stakeMany(uint256[] memory tokenIds) external whenNotPaused {
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(tokenIds[i]);
        }
    }

    function unstake(uint256 _tokenId) external {
        uint256[] memory wrapped = new uint256[](1);
        wrapped[0] = _tokenId;
        releaseReward(wrapped);
        _unstake(_tokenId);
    }

    function unstakeMany(uint256[] memory tokenIds) external {
        releaseReward(tokenIds);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (avaxSpiesNFT.ownerOf(tokenIds[i]) == msg.sender) {
                _unstake(tokenIds[i]);
            }
        }
    }

    function _stake(uint256 _tokenId) internal {
        if (!initialised) revert StakeSpies__NotStarted();
        if (avaxSpiesNFT.ownerOf(_tokenId) != msg.sender) revert StakeSpies__NotTokenOwner();

        avaxSpiesNFT.transferFrom(msg.sender, address(this), _tokenId);
        SpiesStaked storage stakedSpy = stakedSpies[_tokenId];

        stakedSpy.coolDownTimestamp = block.timestamp;
        stakedSpy.spyOwner = msg.sender;

        emit Staked(msg.sender, _tokenId);
        totalStaked++;
    }

    function _unstake(uint256 _tokenId) internal {
        if (!initialised) revert StakeSpies__NotStarted();
        if (stakedSpies[_tokenId].spyOwner != msg.sender) revert StakeSpies__NotTokenStaker();

        if (stakedSpies[_tokenId].coolDownTimestamp > 0) {
            address spyOwner = stakedSpies[_tokenId].spyOwner;
            delete stakedSpies[_tokenId];
            avaxSpiesNFT.transferFrom(address(this), spyOwner, _tokenId);
            emit Unstaked(msg.sender, _tokenId);
            totalStaked--;
        }
    }

    function calculateReward(uint256[] memory _tokenIds) external view returns (uint256) {
        uint256 reward = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            SpiesStaked storage stakedSpy = stakedSpies[_tokenIds[i]];
            if (stakedSpy.coolDownTimestamp < block.timestamp + stakingTime && stakedSpy.coolDownTimestamp > 0) {
                uint256 stakedDays = ((block.timestamp - uint(stakedSpy.coolDownTimestamp))) / stakingTime;

                reward += rewardPerInterval * stakedDays;
            }
        }
        return reward;
    }

    function _updateReward(uint256[] memory _tokenIds) internal {
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            SpiesStaked storage stakedSpy = stakedSpies[_tokenIds[i]];
            if (stakedSpy.coolDownTimestamp < block.timestamp + stakingTime && stakedSpy.coolDownTimestamp > 0) {
                uint256 stakedDays = ((block.timestamp - uint(stakedSpy.coolDownTimestamp))) / stakingTime;
                uint256 partialTime = ((block.timestamp - uint(stakedSpy.coolDownTimestamp))) % stakingTime;

                stakedSpy.balance += rewardPerInterval * stakedDays;

                stakedSpy.coolDownTimestamp = block.timestamp + partialTime;
            }
        }
    }

    function releaseReward(uint256[] memory _tokenIds) public whenNotPaused {
        if (!releaseTokens) revert StakeSpies__TokenReleaseWithheld();

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            if (stakedSpies[_tokenIds[i]].spyOwner != msg.sender) revert StakeSpies__NotTokenStaker();
        }

        _updateReward(_tokenIds);

        uint256 reward = 0;
        for (uint256 i = 0; i < _tokenIds.length; i++) {
            SpiesStaked storage stakedSpy = stakedSpies[_tokenIds[i]];
            reward += stakedSpy.balance;
            stakedSpy.rewardsReleased += stakedSpy.balance;
            stakedSpy.balance = 0;
        }

        if (reward > 0) {
            espionageToken.mint(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function onERC721Received(address, address from, uint256, bytes calldata) external pure override returns (bytes4) {
        if (from != address(0)) revert StakeSpies__CantStake();
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC721A {
    error ApprovalCallerNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error ApproveToCaller();
    error BalanceQueryForZeroAddress();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error OwnerQueryForNonexistentToken();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
    error URIQueryForNonexistentToken();
    error MintERC2309QuantityExceedsLimit();
    error OwnershipNotInitializedForExtraData();

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
        uint24 extraData;
    }

    function totalSupply() external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed from,
        address indexed to
    );
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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