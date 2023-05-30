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
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

// import 'hardhat/console.sol';

contract Staking is Ownable {
    uint256 private constant MINUTE = 60;
    uint256 private constant HOUR = 60 * MINUTE;
    uint256 private constant DAY = 24 * HOUR;

    uint256 public stakingPeriod;
    uint256 public unstakePeriod;
    uint256 public rewardAmount;
    uint256 public stakeAmount;
    IERC20 public stakeToken;
    IERC20 public rewardToken;

    struct Nodes {
        uint256[] leftIds;
        mapping(uint256 => address) ids;
    }

    struct UserNode {
        uint256 id;
        uint256 start;
        uint256 lastReward;
    }

    mapping(address => UserNode[]) stakes;
    Nodes nodes;

    constructor(
        uint256 _stakeAmount,
        uint256 _rewardAmount,
        address _stakeToken,
        address _rewardToken,
        uint256 _stakingPeriod,
        uint256 _unstakePeriod
    ) {
        stakeAmount = _stakeAmount;
        rewardAmount = _rewardAmount;
        stakeToken = IERC20(_stakeToken);
        rewardToken = IERC20(_rewardToken);
        stakingPeriod = _stakingPeriod;
        unstakePeriod = _unstakePeriod;
    }

    // Function to receive Ether. msg.data must be empty
    receive() external payable {
        (bool sent, ) = payable(msg.sender).call{value: msg.value}('');
        require(sent, 'Failed to send Ether back');
    }

    function stake() external {
        (bool found, uint256 id) = getVacantNodeId();
        require(found, 'No vacant nodes found, please wait.');

        stakes[msg.sender].push(UserNode(id, block.timestamp, block.timestamp));
        takeVacantNode();

        stakeToken.transferFrom(msg.sender, address(this), stakeAmount);
    }

    function unstake(uint256 id) external {
        (bool found, UserNode memory userStake, uint256 index) = searchUserNode(id);
        require(found, 'User node with id not found.');
        require(
            userStake.start + unstakePeriod <= block.timestamp,
            'You can unstake only after 30 days from the start.'
        );

        getRewards(id);
        deleteUserNode(index);
        freeVacantNode(id);

        stakeToken.transfer(msg.sender, stakeAmount);
    }

    function getRewards(uint256 id) public {
        (bool found, UserNode memory userStake, uint256 index) = searchUserNode(id);
        require(found, 'User node with id not found.');

        uint256 timeFactor = (block.timestamp - userStake.lastReward) / stakingPeriod;
        stakes[msg.sender][index].lastReward =
            userStake.lastReward +
            timeFactor *
            stakingPeriod;

        if (rewardAmount * timeFactor > 0)
            rewardToken.transfer(msg.sender, rewardAmount * timeFactor);
    }

    function searchUserNode(uint256 id)
        private
        view
        returns (
            bool,
            UserNode memory,
            uint256
        )
    {
        UserNode[] memory userNodes = stakes[msg.sender];
        for (uint256 i; i < userNodes.length; ++i) {
            if (userNodes[i].id == id) {
                return (true, userNodes[i], i);
            }
        }

        return (false, UserNode(0, 0, 0), 0);
    }

    function deleteUserNode(uint256 index) private {
        UserNode[] storage userNodes = stakes[msg.sender];
        userNodes[index] = userNodes[userNodes.length - 1];
        userNodes.pop();
    }

    function getVacantNodeId() private view returns (bool, uint256) {
        if (nodes.leftIds.length == 0) {
            return (false, 0);
        }
        return (true, nodes.leftIds[nodes.leftIds.length - 1]);
    }

    function freeVacantNode(uint256 id) private {
        nodes.leftIds.push(id);
        nodes.ids[id] = address(0);
    }

    function takeVacantNode() private {
        uint256 id = nodes.leftIds[nodes.leftIds.length - 1];
        nodes.leftIds.pop();

        nodes.ids[id] = msg.sender;
    }

    // -_-_-_-_-_-_-_-_ Getters -_-_-_-_-_-_-_-_

    function getNodeHolderAddr(uint256 id) external view returns (address) {
        return nodes.ids[id];
    }

    function getUserNode(uint256 id) external view returns (UserNode memory userNode) {
        (, userNode, ) = searchUserNode(id);
    }

    function getUserStakes() external view returns (UserNode[] memory) {
        return stakes[msg.sender];
    }

    function getAmountOfLeftIds() external view returns (uint256 leftIdsAmount) {
        leftIdsAmount = nodes.leftIds.length;
    }

    function getLeftIds() external view returns (uint256[] memory) {
        return nodes.leftIds;
    }

    // -_-_-_-_-_-_ Setters for updates -_-_-_-_-_-_

    function setNodes(
        uint256[] memory ids,
        address[] memory users,
        uint256[] memory _leftIds
    ) external onlyOwner {
        nodes.leftIds = _leftIds;

        // set users for all ids
        for (uint256 i; i < ids.length; ++i) {
            nodes.ids[ids[i]] = users[i];
        }
    }

    function setUserStakes(
        address user,
        uint256[] memory id,
        uint256[] memory start,
        uint256[] memory lastReward
    ) external onlyOwner {
        for (uint256 i; i < id.length; ++i) {
            stakes[user].push(UserNode(id[i], start[i], lastReward[i]));
        }
    }

    function setRewardAmount(uint256 _rewardAmount) external onlyOwner {
        rewardAmount = _rewardAmount;
    }

    function setStakeAmount(uint256 _stakeAmount) external onlyOwner {
        stakeAmount = _stakeAmount;
    }

    function setRewardToken(address _rewardToken) external onlyOwner {
        rewardToken = IERC20(_rewardToken);
    }

    function setStakeToken(address _stakeToken) external onlyOwner {
        stakeToken = IERC20(_stakeToken);
    }

    function setNodeIds(uint256[] memory ids) external onlyOwner {
        for (uint256 i; i < ids.length; ++i) {
            nodes.leftIds.push(ids[i]);
        }
    }

    function setStakingPeriod(uint256 _stakingPeriod) external onlyOwner {
        stakingPeriod = _stakingPeriod;
    }

    function setUnstakePeriod(uint256 _unstakePeriod) external onlyOwner {
        unstakePeriod = _unstakePeriod;
    }

    // -_-_-_-_-_-_-_-_ Owner Logic -_-_-_-_-_-_-_-_

    function withdrawOcta() external onlyOwner {
        if (address(this).balance == 0) return;
        (bool sent, ) = payable(owner()).call{value: address(this).balance}('');
        require(sent, 'Failed to send Ether');
    }

    function withdrawERC20() external onlyOwner {
        stakeToken.transfer(owner(), stakeToken.balanceOf(address(this)));
        rewardToken.transfer(owner(), rewardToken.balanceOf(address(this)));
    }
}