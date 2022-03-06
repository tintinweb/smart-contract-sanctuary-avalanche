//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

    struct SmallNode {
        uint256 lastClaim;
        uint256 createdAt;
        bool burned;
        bool active;
        uint256 id;
        uint256 rewards;
    }

    struct MiddleNode {
        uint256 lastClaim;
        uint256 createdAt;
        bool burned;
        bool active;
        uint256 id;
        uint256 rewards;
    }

    struct BigNode {
        uint256 lastClaim;
        uint256 createdAt;
        bool burned;
        bool active;
        uint256 id;
        uint256 rewards;
    }

contract BlackSharkNodesTrades {
    event Claimed(address indexed _address, uint256 _reward);

    using SafeMath for uint256;
    using Counters for Counters.Counter;

    address private _contractOwner;
    address private _safeWallet;
    address private _transitWallet;

    IERC20 private _coinContract;
    IERC721 private _verySimpleNftContract;
    IERC721 private _simpleNftContract;
    IERC721 private _superiorNftContract;

    uint256 private _smallNodePrice = 2000000000;

    uint256 private _smallNodeForUpgradeNeeded = 15;
    uint256 private _middleNodeForUpgradeNeeded = 10;

    uint256 private _feeForMiddleUpgrade = 10000000000;
    uint256 private _feeForBigUpgrade = 150000000000;

    uint256 private _smallNodeBaseRate = 69444;
    uint256 private _middleNodeBaseRate = 1562500;
    uint256 private _bigNodeBaseRate = 23437500;

    uint256 private _secondsOneDay = 86400;

    bool public middleUpgradeAvailable = false;
    bool public bigUpgradeAvailable = false;

    Counters.Counter private _smallNodesIndex;
    Counters.Counter private _middleNodesIndex;
    Counters.Counter private _bigNodesIndex;

    mapping(address => mapping(uint256 => SmallNode)) private _smallNodes;
    mapping(address => uint256) private _smallNodesCount;
    mapping(address => uint256) private _activeSmallNodesCount;

    mapping(address => mapping(uint256 => MiddleNode)) private _middleNodes;
    mapping(address => uint256) private _middleNodesCount;
    mapping(address => uint256) private _activeMiddleNodesCount;

    mapping(address => mapping(uint256 => BigNode)) private _bigNodes;
    mapping(address => uint256) private _bigNodesCount;
    mapping(address => uint256) private _activeBigNodesCount;

    modifier onlyOwner(){
        require(msg.sender == _contractOwner, "Access denied");
        _;
    }

    constructor(
        IERC20 coinContract,
        IERC721 verySimpleNftContract,
        IERC721 simpleNftContract,
        IERC721 superiorNftContract
    ) {
        _contractOwner = msg.sender;
        _coinContract = coinContract;
        _verySimpleNftContract = verySimpleNftContract;
        _simpleNftContract = simpleNftContract;
        _superiorNftContract = superiorNftContract;
    }

    function smallNodePrice() public view returns (uint256){
        return _smallNodePrice;
    }

    function changeMiddleUpgradeAvailabilityStatus(bool status) public onlyOwner {
        middleUpgradeAvailable = status;
    }

    function changeBigUpgradeAvailabilityStatus(bool status) public onlyOwner {
        bigUpgradeAvailable = status;
    }

    function setSafeWallet(address address_) public onlyOwner {
        _safeWallet = address_;
    }

    function safeWallet() public view returns (address){
        return _safeWallet;
    }

    function setTransitWallet(address address_) public onlyOwner {
        _transitWallet = address_;
    }

    function transitWallet() public view returns (address) {
        return _transitWallet;
    }

    function smallNodeBaseRate() public view returns (uint256){
        return _smallNodeBaseRate;
    }

    function middleNodeBaseRate() public view returns (uint256){
        return _middleNodeBaseRate;
    }

    function bigNodeBaseRate() public view returns (uint256){
        return _bigNodeBaseRate;
    }

    function createSmallNode(uint count_) public {
        uint256 userBSNBalance = _coinContract.balanceOf(msg.sender);

        uint256 amount = count_ * smallNodePrice();

        require(userBSNBalance >= amount, "Not enough BSN for this type of node");

        uint256 currentAllowance = _coinContract.allowance(msg.sender, address(this));
        require(currentAllowance >= amount, "ERC20: Please approve BSN for this contract");

        _coinContract.transferFrom(msg.sender, transitWallet(), amount);

        uint i = 0;

        for (; i < count_; i += 1) {
            _smallNodesIndex.increment();
            uint256 nextIndex = _smallNodesIndex.current();

            uint length = _userSmallNodesCount(msg.sender);
            SmallNode storage smallNode = _smallNodes[msg.sender][length];
            smallNode.createdAt = block.timestamp;
            smallNode.burned = false;
            smallNode.active = true;
            smallNode.id = nextIndex;
            smallNode.rewards = 0;
            _smallNodesCount[msg.sender] += 1;
            _activeSmallNodesCount[msg.sender] += 1;
        }
    }

    function _userSmallNodesCount(address address_) private view returns (uint) {
        return _smallNodesCount[address_];
    }

    function _userMiddleNodesCount(address address_) private view returns (uint) {
        return _middleNodesCount[address_];
    }

    function _userBigNodesCount(address address_) private view returns (uint) {
        return _bigNodesCount[address_];
    }

    function smallNodeBalanceOf(address address_) public view returns (uint256) {
        return _smallNodesCount[address_];
    }

    function activeSmallNodeBalanceOf(address address_) public view returns (uint256) {
        return _activeSmallNodesCount[address_];
    }

    function middleNodeBalanceOf(address address_) public view returns (uint256) {
        return _middleNodesCount[address_];
    }

    function activeMiddleNodeBalanceOf(address address_) public view returns (uint256) {
        return _activeMiddleNodesCount[address_];
    }

    function bigNodeBalanceOf(address address_) public view returns (uint256) {
        return _bigNodesCount[address_];
    }

    function activeBigNodeBalanceOf(address address_) public view returns (uint256) {
        return _activeBigNodesCount[address_];
    }

    function getSmallNodeInfo(uint256 id) public view returns (uint256, uint256, bool, bool, uint256) {
        SmallNode storage node = _smallNodes[msg.sender][id];
        return (node.lastClaim, node.createdAt, node.burned, node.active, node.id);
    }

    function getMiddleNodeInfo(uint256 id) public view returns (uint256, uint256, bool, bool, uint256) {
        MiddleNode storage node = _middleNodes[msg.sender][id];
        return (node.lastClaim, node.createdAt, node.burned, node.active, node.id);
    }

    function getBigNodeInfo(uint256 id) public view returns (uint256, uint256, bool, bool, uint256) {
        BigNode storage node = _bigNodes[msg.sender][id];
        return (node.lastClaim, node.createdAt, node.burned, node.active, node.id);
    }

    function middleUpgrade() public {
        uint256 BSNBalance = _coinContract.balanceOf(msg.sender);
        require(BSNBalance >= _feeForMiddleUpgrade, "Not enough BSN for upgrade");

        uint256 smallNodesBalance = activeSmallNodeBalanceOf(msg.sender);
        require(smallNodesBalance >= _smallNodeForUpgradeNeeded, "Not enough small nodes for upgrade");

        require(middleUpgradeAvailable == true, "Upgrade to Middle Node not available now.");

        _coinContract.transferFrom(msg.sender, safeWallet(), _feeForMiddleUpgrade);

        uint counter = 0;
        uint index = 0;

        while (counter < _smallNodeForUpgradeNeeded) {
            SmallNode storage smallNode = _smallNodes[msg.sender][index];

            if (!smallNode.burned) {
                smallNode.burned = true;
                smallNode.active = false;
                counter++;
            }

            index++;
        }

        _activeSmallNodesCount[msg.sender] -= _smallNodeForUpgradeNeeded;

        _middleNodesIndex.increment();
        uint256 nextIndex = _middleNodesIndex.current();

        uint length = _userMiddleNodesCount(msg.sender);
        MiddleNode storage middleNode = _middleNodes[msg.sender][length];
        middleNode.createdAt = block.timestamp;
        middleNode.burned = false;
        middleNode.active = true;
        middleNode.id = nextIndex;
        middleNode.rewards = 0;
        _middleNodesCount[msg.sender] += 1;
        _activeMiddleNodesCount[msg.sender] += 1;
    }

    function bigUpgrade() public {
        uint256 BSNBalance = _coinContract.balanceOf(msg.sender);
        require(BSNBalance >= _feeForBigUpgrade, "Not enough BSN for upgrade");

        uint256 middleNodesBalance = activeMiddleNodeBalanceOf(msg.sender);
        require(middleNodesBalance >= _middleNodeForUpgradeNeeded, "Not enough middle nodes for upgrade");

        require(bigUpgradeAvailable == true, "Upgrade to Big Node not available now.");

        _coinContract.transferFrom(msg.sender, safeWallet(), _feeForBigUpgrade);

        uint counter = 0;
        uint index = 0;

        while (counter < _middleNodeForUpgradeNeeded) {
            MiddleNode storage middleNode = _middleNodes[msg.sender][index];

            if (!middleNode.burned) {
                middleNode.burned = true;
                middleNode.active = false;
                counter++;
            }

            index++;
        }

        _activeMiddleNodesCount[msg.sender] -= _middleNodeForUpgradeNeeded;

        _bigNodesIndex.increment();
        uint256 nextIndex = _bigNodesIndex.current();

        uint length = _userBigNodesCount(msg.sender);
        BigNode storage bigNode = _bigNodes[msg.sender][length];
        bigNode.createdAt = block.timestamp;
        bigNode.burned = false;
        bigNode.active = true;
        bigNode.id = nextIndex;
        bigNode.rewards = 0;
        _bigNodesCount[msg.sender] += 1;
        _activeBigNodesCount[msg.sender] += 1;
    }

    function verySimpleNFTBalanceOf(address address_) public view returns (uint256){
        return _verySimpleNftContract.balanceOf(address_);
    }

    function simpleNFTBalanceOf(address address_) public view returns (uint256){
        return _simpleNftContract.balanceOf(address_);
    }

    function superiorNFTBalanceOf(address address_) public view returns (uint256){
        return _superiorNftContract.balanceOf(address_);
    }

    function _nftBooster(address address_) private view returns (uint256) {
        bool VSNFTExist = verySimpleNFTBalanceOf(address_) > 0;
        bool SINFTExist = simpleNFTBalanceOf(address_) > 0;
        bool SUNFTExist = superiorNFTBalanceOf(address_) > 0;

        uint256 booster = 100;

        if (VSNFTExist && SINFTExist && SUNFTExist) {
            booster = 151;
        } else if (!VSNFTExist && SINFTExist && SUNFTExist) {
            booster = 150;
        } else if (VSNFTExist && !SINFTExist && SUNFTExist) {
            booster = 142;
        } else if (VSNFTExist && SINFTExist && !SUNFTExist) {
            booster = 123;
        } else if (!VSNFTExist && !SINFTExist && SUNFTExist) {
            booster = 140;
        } else if (!VSNFTExist && SINFTExist && !SUNFTExist) {
            booster = 120;
        } else if (VSNFTExist && !SINFTExist && !SUNFTExist) {
            booster = 110;
        }

        return booster;
    }

    function _smallNodeWorkTime(address address_, uint256 i) private view returns (uint256) {
        SmallNode storage node = _smallNodes[address_][i];

        uint256 lastClaimTime;

        if (node.lastClaim == 0) {
            lastClaimTime = node.createdAt;
        } else {
            lastClaimTime = node.lastClaim;
        }

        uint256 workTime = block.timestamp.sub(lastClaimTime);

        uint256 twoDays = _secondsOneDay.mul(2);

        if (workTime > twoDays) {
            workTime = twoDays;
        }

        return workTime;
    }

    function _middleNodeWorkTime(address address_, uint256 i) private view returns (uint256) {
        MiddleNode storage node = _middleNodes[address_][i];

        uint256 lastClaimTime;

        if (node.lastClaim == 0) {
            lastClaimTime = node.createdAt;
        } else {
            lastClaimTime = node.lastClaim;
        }

        uint256 workTime = block.timestamp.sub(lastClaimTime);

        uint256 twoDays = _secondsOneDay.mul(2);

        if (workTime > twoDays) {
            workTime = twoDays;
        }

        return workTime;
    }

    function _bigNodeWorkTime(address address_, uint256 i) private view returns (uint256) {
        BigNode storage node = _bigNodes[address_][i];

        uint256 lastClaimTime;

        if (node.lastClaim == 0) {
            lastClaimTime = node.createdAt;
        } else {
            lastClaimTime = node.lastClaim;
        }

        uint256 workTime = block.timestamp.sub(lastClaimTime);

        uint256 twoDays = _secondsOneDay.mul(2);

        if (workTime > twoDays) {
            workTime = twoDays;
        }

        return workTime;
    }

    function calculateSmallNodeClaim(address address_, uint256 i, uint256 booster_) public view returns (uint256) {
        uint256 localReward = smallNodeBaseRate();

        uint256 workTime = _smallNodeWorkTime(address_, i);

        localReward = localReward.mul(workTime);

        return localReward.mul(booster_);
    }

    function calculateMiddleNodeClaim(address address_, uint256 i, uint256 booster_) public view returns (uint256) {
        uint256 localReward = middleNodeBaseRate();

        uint256 workTime = _middleNodeWorkTime(address_, i);

        localReward = localReward.mul(workTime);

        return localReward.mul(booster_);
    }

    function calculateBigNodeClaim(address address_, uint256 i, uint256 booster_) public view returns (uint256) {
        uint256 localReward = bigNodeBaseRate();

        uint256 workTime = _bigNodeWorkTime(address_, i);

        localReward = localReward.mul(workTime);

        return localReward.mul(booster_);
    }

    function myRewards(address address_) public view returns (uint256) {
        uint256 reward = 0;
        uint256 smallNodesBalance = smallNodeBalanceOf(address_);
        uint256 middleNodesBalance = middleNodeBalanceOf(address_);
        uint256 bigNodesBalance = bigNodeBalanceOf(address_);
        uint256 nftBooster = _nftBooster(address_);

        uint256 i = 0;
        for (; i < smallNodesBalance; i++) {
            SmallNode storage smallNode = _smallNodes[address_][i];

            if (smallNode.active) {
                uint256 localReward = calculateSmallNodeClaim(address_, i, nftBooster);
                reward += localReward;
            }
        }

        i = 0;
        for (; i < middleNodesBalance; i++) {
            MiddleNode storage middleNode = _middleNodes[address_][i];

            if (middleNode.active) {
                uint256 localReward = calculateMiddleNodeClaim(address_, i, nftBooster);
                reward += localReward;
            }
        }

        i = 0;
        for (; i < bigNodesBalance; i++) {
            BigNode storage bigNode = _bigNodes[address_][i];

            if (bigNode.active) {
                uint256 localReward = calculateBigNodeClaim(address_, i, nftBooster);
                reward += localReward;
            }
        }

        return reward;
    }

    function calculateReward(address address_) public returns (uint256){
        uint256 reward = 0;
        uint256 smallNodesBalance = smallNodeBalanceOf(address_);
        uint256 middleNodesBalance = middleNodeBalanceOf(address_);
        uint256 bigNodesBalance = bigNodeBalanceOf(address_);
        uint256 nftBooster = _nftBooster(address_);

        uint256 i = 0;
        for (; i < smallNodesBalance; i++) {
            SmallNode storage smallNode = _smallNodes[address_][i];

            if (smallNode.active) {
                uint256 localReward = calculateSmallNodeClaim(address_, i, nftBooster);
                smallNode.lastClaim = block.timestamp;
                smallNode.rewards += localReward;
                reward += localReward;
            }
        }

        i = 0;
        for (; i < middleNodesBalance; i++) {
            MiddleNode storage middleNode = _middleNodes[address_][i];

            if (middleNode.active) {
                uint256 localReward = calculateMiddleNodeClaim(address_, i, nftBooster);
                middleNode.lastClaim = block.timestamp;
                middleNode.rewards += localReward;
                reward += localReward;
            }
        }

        i = 0;
        for (; i < bigNodesBalance; i++) {
            BigNode storage bigNode = _bigNodes[address_][i];

            if (bigNode.active) {
                uint256 localReward = calculateBigNodeClaim(address_, i, nftBooster);
                bigNode.lastClaim = block.timestamp;
                bigNode.rewards += localReward;
                reward += localReward;
            }
        }

        return reward;
    }

    function claim() public {
        uint256 poolBalance = _coinContract.balanceOf(address(this));
        require(poolBalance != 0, "Game pool is empty.");

        uint256 reward = calculateReward(msg.sender);

        require(reward > 0, "Not enough BSN for claim");
        require(poolBalance >= reward, "Not enough BSN in game pool.");
        _coinContract.transfer(msg.sender, reward.div(10000));

        emit Claimed(msg.sender, reward);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
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

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
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