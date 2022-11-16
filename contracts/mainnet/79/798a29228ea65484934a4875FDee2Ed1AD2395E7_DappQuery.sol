// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface NODERewardManagement {
    struct NodeEntity {
        address owner;
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardAvailable;
    }

    function _getNodesNames(address) external view returns (string memory);

    function _getNodesCreationTime(address)
        external
        view
        returns (string memory);

    function _getNodesLastClaimTime(address)
        external
        view
        returns (string memory);

    function _getNodesIndex(address) external view returns (uint256[] memory);

    function _getNodeNumberOf(address) external view returns (uint256);

    function getNodeId(uint256) external view returns (string memory);

    function _getNodeTaxFee(
        uint256,
        uint256,
        uint256[] memory,
        uint256[] memory
    ) external view returns (uint256);

    function getRewardAmountOf(uint256) external view returns (uint256);

    function _nodeList(uint256)
        external
        view
        returns (
            address,
            string memory,
            uint256,
            uint256,
            uint256
        );
}

interface MasterOfCoin {
    function getDueDate(string memory) external view returns (uint256);
}

contract DappQuery is Ownable {
    using SafeMath for uint256;

    MasterOfCoin public masterOfCoin;
    mapping(string => NODERewardManagement) public managers;
    string[] public allTiers = ["HEIMDALL", "FREYA", "THOR", "ODIN"];

    struct Node {
        string tier;
        string nodeId;
        string name;
        uint256 idx;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewards;
        uint256 taxPct;
        uint256 dueDate;
    }
    uint256[] private emptyArray = new uint256[](4);

    constructor() {
        masterOfCoin = MasterOfCoin(0x31E36C6DbbACc493f959Ec5944f6ae47049f342D);
        managers["HEIMDALL"] = NODERewardManagement(
            0x7694D6b76D64bB89920b3Cb7156c7dE2b00b0c79
        );
        managers["FREYA"] = NODERewardManagement(
            0x05e946Cc06Cd49b5957Ea2096cb57353313E3F0D
        );
        managers["THOR"] = NODERewardManagement(
            0x349Cb36d6E3de4E9Ce7FbF9949c003974eb556CA
        );
        managers["ODIN"] = NODERewardManagement(
            0x769fc7a85437AdA05dE2C4bDa6220D18ce1F7549
        );
    }

    // Get around Stack too deep
    struct TempStore {
        uint256 globalIdx;
        string tier;
        uint256[] nodesIndexes;
    }

    // Fetches all node information
    function getNodes(address account) public view returns (Node[] memory) {
        Node[] memory nodes = new Node[](getNodeCount(account));
        uint256 globalIdx;

        for (uint256 i = 0; i < allTiers.length; i++) {
            string memory tier = allTiers[i];
            NODERewardManagement manager = managers[tier];

            if (manager._getNodeNumberOf(account) == 0) {
                continue;
            }

            uint256[] memory nodesIndexes = manager._getNodesIndex(account);

            for (uint256 a = 0; a < nodesIndexes.length; a++) {
                uint256 nodeIndex = nodesIndexes[a];
                (
                    ,
                    string memory name,
                    uint256 creationTime,
                    uint256 lastClaimTime,

                ) = manager._nodeList(nodeIndex);
                uint256 taxPct = manager._getNodeTaxFee(
                    nodeIndex,
                    block.timestamp,
                    emptyArray,
                    emptyArray
                );
                uint256 taxedRewards = manager.getRewardAmountOf(nodeIndex);
                string memory nodeId = manager.getNodeId(nodeIndex);

                nodes[globalIdx++] = Node({
                    tier: tier,
                    nodeId: nodeId,
                    name: name,
                    idx: nodeIndex,
                    creationTime: creationTime,
                    lastClaimTime: lastClaimTime,
                    rewards: offSetFee(taxedRewards, taxPct),
                    taxPct: taxPct,
                    dueDate: masterOfCoin.getDueDate(nodeId)
                });
            }
        }

        return nodes;
    }

    function getNodeCount(address account) public view returns (uint256 count) {
        for (uint256 i = 0; i < allTiers.length; i++) {
            count += managers[allTiers[i]]._getNodeNumberOf(account);
        }
    }

    function offSetFee(uint256 rewards, uint256 fee)
        private
        pure
        returns (uint256)
    {
        return rewards.mul(100).div(100 - fee);
    }

    function stringToUint(string memory s)
        private
        pure
        returns (uint256 result)
    {
        bytes memory b = bytes(s);
        for (uint256 i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result *= 10 + (c - 48);
            }
        }
    }

    function updateTierContract(
        string memory tier,
        NODERewardManagement manager
    ) public onlyOwner {
        for (uint256 i = 0; i < allTiers.length; i++) {
            if (keccak256(bytes(allTiers[i])) == keccak256(bytes(tier))) {
                managers[tier] = manager;
                break;
            }
        }
    }

    function updateMasterOfCoin(MasterOfCoin addr) public onlyOwner {
        masterOfCoin = addr;
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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