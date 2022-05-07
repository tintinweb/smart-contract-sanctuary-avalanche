/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-07
*/

/**    ZEUS NODE FINANCE - 2022
       Web:      https://linktr.ee/zeusnode
 */

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/**
 * @title SafeMathUint
 * @dev Math operations with safety TKNcks that revert on error
 */
library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0, "toInt256Safe: B LESS THAN ZERO");
        return b;
    }
}

pragma solidity ^0.8.0;

/**
 * @title SafeMathInt
 * @dev Math operations for int256 with overflow safety TKNcks.
 */
library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(
            c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256),
            "mul: A B C combi values invalid with MIN_INT256"
        );
        require((b == 0) || (c / b == a), "mul: A B C combi values invalid");
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256, "div: b == 1 OR A == MIN_INT256");

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require(
            (b >= 0 && c <= a) || (b < 0 && c > a),
            "sub: A B C combi values invalid"
        );
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require(
            (b >= 0 && c >= a) || (b < 0 && c < a),
            "add: A B C combi values invalid"
        );
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256, "abs: A EQUAL MIN INT256");
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0, "toUint256Safe: A LESS THAN ZERO");
        return uint256(a);
    }
}

pragma solidity ^0.8.0;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

// OpenZeppelin Contracts v4.3.2 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
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

pragma solidity ^0.8.0;

/*
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

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
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

interface NODERewardManagement {
    function nodePrice() external view returns (uint256);

    function zeusTotal() external view returns (uint256);

    function rewardPerNode() external view returns (uint256);

    function claimTime() external view returns (uint256);

    function gateKeeper() external returns (address);

    function token() external returns (address);

    function totalNodesCreated() external view returns (uint256);

    function totalRewardStaked() external view returns (uint256);

    function _getNodesNames(address account)
        external
        view
        returns (string memory);

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory);

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory);

    function _getRewardAmountOf(address account)
        external
        view
        returns (uint256);

    function _getNodeNumberOf(address account) external view returns (uint256);

    function _isNodeOwner(address account) external view returns (bool);

    function createNode(
        address account,
        string memory nodeName,
        address referred_by,
        uint32 nodeType,
        uint256 total
    ) external;

    function _cashoutNodeReward(address account, uint256 _creationTime)
        external
        returns (uint256, uint256);

    function _getNodeRewardAmountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _cashoutAllNodesReward(address account)
        external
        returns (uint256, uint256);

    function _getRewardAmountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _cashoutAllNodesByTypeReward(address account, uint32 nodeType)
        external
        returns (uint256, uint256);

    function getReferralBonus(address account) external view returns (uint256);

    function getReferrals(address referred_by)
        external
        view
        returns (address[] memory);

    function withdrawReferralBonus(address account) external returns (uint256);

    function getNodePriceByType(uint32 nodeType)
        external
        view
        returns (uint256);

    function getNodeRewardByType(uint32 nodeType)
        external
        view
        returns (uint256);

    function _getTotalUserNodes(address account)
        external
        view
        returns (uint256);

    function _getUserReferralCount(address account)
        external
        view
        returns (uint256);

    function _changeNodePrice(uint256 amount) external;

    function _changeRewardPerNode(uint256 amount) external;

    function _changeClaimTime(uint256 amount) external;

    function _changeGasDistri(uint256 amount) external;

    function gasForDistribution() external view returns (uint256);
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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.8.0;

library Strings {
    function _indexOf(
        string memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int256(i);
            }
        }
        return -1;
    }

    function length(string memory _base) internal pure returns (uint256) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr)
    {
        bytes memory _baseBytes = bytes(_base);

        uint256 _offset = 0;
        uint256 _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) break;
            else {
                _splitsCount++;
                _offset = uint256(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int256(_baseBytes.length);
            }

            string memory _tmp = new string(uint256(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint256 j = 0;
            for (uint256 i = _offset; i < uint256(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint256(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

interface IZeus {
    function createNodeWithTokens(string memory name) external;
}

contract IZeusV2 {
    mapping(address => uint256) public extraUserBalances;
}

interface IMasterOfCoin {
    function getDueDate(string memory nodeId) external view returns (uint256);

    function getFee(string memory nodeId, string memory tierName)
        external
        view
        returns (uint256);

    function payFee(string memory nodeId) external;

    function isDelinquent(string memory nodeId) external view returns (bool);

    function restoreNode(string memory nodeId, string memory tierName)
        external
        payable;
}

contract ZEUSV4 is Ownable {
    using SafeMath for uint256;
    using Strings for string;
    NODERewardManagement public kronosNodeRewardManager;
    NODERewardManagement public herculesNodeRewardManager;
    NODERewardManagement public heraNodeRewardManager;
    NODERewardManagement public zeusNodeRewardManager;
    IMasterOfCoin public masterOfCoin;
    IZeus public Zeus = IZeus(0x4156F18bF7C1ef04248632C66Aa119De152D8f2E);
    IZeusV2 public ZeusV2 = IZeusV2(0x83Cd939016700abf7e61FD991550f93388e3368b);
    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardAvailable;
        uint32 nodeType;
    }

    address public uniswapV2Pair = 0xA888455491ffDAC9a6E20C5Cf5C06fBAC5124Df6;
    address public futurUsePool = 0xA26d0bdF4b22C4Ee7A14b385289D9667B5E2416d;
    address public distributionPool =
        0x0B26a20f038F657856054dE581457e1F9db4E88e;
    address public creationTaxPool = 0x4156F18bF7C1ef04248632C66Aa119De152D8f2E;
    address tokenAddress = 0x764a4A6f3326559b6Ef5F3F186AD1094FA044c43;
    IERC20 public token = IERC20(tokenAddress);

    address public deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public taxPool = 0x3e9f27368CC457F5A2CBE5B26fa050Be4be05A8E;

    uint256 public rewardsFee = 60;
    uint256 public liquidityPoolFee = 10;
    uint256 public futurFee = 2;
    uint256 public totalFees = 72;
    uint256 public loopAmount = 40;
    uint256[4] public limits = [604800, 1728000, 3456000, 3456000]; //days converted to seconds
    uint256[4] public taxes = [75, 45, 20, 10];

    uint256 public cashoutFee = 10;

    uint256 private rwSwap = 30;
    bool private swapping = false;
    bool private swapLiquify = true;
    uint256 public swapTokensAmount = 30000000000000000000;

    mapping(address => bool) public _isBlacklisted;
    mapping(address => bool) public automatedMarketMakerPairs;
    mapping(address => uint256) public extraUserBalances;
    mapping(address => bool) public isMigratedExtraBalance;

    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    constructor() {
        _setAutomatedMarketMakerPair(
            0xA888455491ffDAC9a6E20C5Cf5C06fBAC5124Df6,
            true
        );
    }

    function setMasterOfCoin(address _master) external onlyOwner {
        masterOfCoin = IMasterOfCoin(_master);
    }

    function migrateExtraBalance() external {
        address sender = _msgSender();
        require(!isMigratedExtraBalance[sender], "Already Migrated balance");
        uint256 oldExtraBalances = ZeusV2.extraUserBalances(sender);
        isMigratedExtraBalance[sender] = true;
        if (oldExtraBalances > 0) {
            extraUserBalances[sender] += oldExtraBalances;
        }
    }

    function payFee(string memory nodeId) external onlyOwner {
        masterOfCoin.payFee(nodeId);
    }

    function getFee(string memory nodeId, string memory tierName)
        external
        view
        returns (uint256)
    {
        return masterOfCoin.getFee(nodeId, tierName);
    }

    function _payFee(string memory nodeId) internal {
        masterOfCoin.payFee(nodeId);
    }

    function restoreNode(
        string memory nodeId,
        string memory tierName,
        uint32 nodeType,
        uint256 blocktime
    ) external payable {
        address sender = _msgSender();
        uint256 fee = masterOfCoin.getFee(nodeId, tierName);
        uint256 avaxFee = fee / 10**18;
        bool isDelinquent = masterOfCoin.isDelinquent(nodeId);
        if (fee > 0) {
            payable(address(this)).transfer(avaxFee);
        }
        if (isDelinquent) {
            masterOfCoin.restoreNode(nodeId, tierName);
            _cashoutNodeReward(sender, blocktime, nodeType);
        } else {
            _payFee(nodeId);
        }
    }

    function updateSwapTokensAmount(uint256 newVal) external onlyOwner {
        swapTokensAmount = newVal;
    }

    function updateFuturWall(address payable wall) external onlyOwner {
        futurUsePool = wall;
    }

    function updateRewardsWall(address payable wall) external onlyOwner {
        distributionPool = wall;
    }

    function updateRewardsFee(uint256 value) external onlyOwner {
        rewardsFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateLoopAmount(uint256 amount) external onlyOwner {
        loopAmount = amount;
    }

    function updateLiquiditFee(uint256 value) external onlyOwner {
        liquidityPoolFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateFuturFee(uint256 value) external onlyOwner {
        futurFee = value;
        totalFees = rewardsFee.add(liquidityPoolFee).add(futurFee);
    }

    function updateCashoutFee(uint256 value) external onlyOwner {
        cashoutFee = value;
    }

    function updateRwSwapFee(uint256 value) external onlyOwner {
        rwSwap = value;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        public
        onlyOwner
    {
        require(
            pair != uniswapV2Pair,
            "TKN: The PancakeSwap pair cannot be removed from automatedMarketMakerPairs"
        );

        _setAutomatedMarketMakerPair(pair, value);
    }

    function blacklistMalicious(address account, bool value)
        external
        onlyOwner
    {
        _isBlacklisted[account] = value;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(
            automatedMarketMakerPairs[pair] != value,
            "TKN: Automated market maker pair is already set to that value"
        );
        automatedMarketMakerPairs[pair] = value;

        emit SetAutomatedMarketMakerPair(pair, value);
    }

    function createNodeWithTokens(
        string memory name,
        address referred_by,
        uint256 total,
        uint32 nodeType
    ) public payable {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(total == 1, "Max: 1");
        require(
            bytes(name).length > 3 && bytes(name).length < 32,
            "NODE CREATION: NAME SIZE INVALID"
        );
        address sender = _msgSender();
        require(
            sender != address(0),
            "NODE CREATION:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "NODE CREATION: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "NODE CREATION: futur and rewardsPool cannot create node"
        );
        uint256 totalUserNodes = nodeRewardManager._getTotalUserNodes(sender);
        require(totalUserNodes < 100, "Maximum node exceeded");
        uint256 nodePrice = 0;
        if (nodeType == 2) {
            nodePrice = nodeRewardManager.getNodePriceByType(nodeType);
        } else {
            nodePrice = nodeRewardManager.nodePrice();
        }

        require(
            token.balanceOf(sender) >= nodePrice,
            "NODE CREATION: Balance too low for creation."
        );
        uint256 contractTokenBalance = token.balanceOf(address(this));
        bool swapAmountOk = contractTokenBalance >= swapTokensAmount;
        if (
            swapAmountOk &&
            swapLiquify &&
            !swapping &&
            sender != owner() &&
            !automatedMarketMakerPairs[sender]
        ) {
            swapping = true;
            // token.transfer(address(creationTaxPool), contractTokenBalance);
            // Zeus.createNodeWithTokens(name);
            swapping = false;
        }
        // uint256 finalPrice = total.mul(nodePrice);
        // token.transferFrom(msg.sender, address(this), finalPrice);
        nodeRewardManager.createNode(
            sender,
            name,
            referred_by,
            nodeType,
            total
        );
        string memory nodeId = _getLastNodeId(sender, nodeType);
        masterOfCoin.payFee(nodeId);
    }

    function _getLastNodeId(address sender, uint32 nodeType)
        public
        view
        returns (string memory)
    {
        string memory lastcreationTime = getLastCreationTime(sender, nodeType);
        string memory userId = getNodeId(sender);
        string memory name = "HERCULES";
        if (nodeType == 1) {
            name = "HERA";
        }
        if (nodeType == 2) {
            name = "ZEUS";
        }
        if (nodeType == 3) {
            name = "KRONOS";
        }
        string memory nodeIdCreationTime = string(
            abi.encodePacked(userId, "_", lastcreationTime)
        );
        return string(abi.encodePacked(name, "_", nodeIdCreationTime));
    }

    function getNodeId(address account) public pure returns (string memory) {
        uint256 acountToNum = uint256(uint160(account));
        string memory nodeId = string(
            abi.encodePacked(Strings.toString(acountToNum))
        );

        return nodeId;
    }

    function getLastCreationTime(address account, uint32 nodeType)
        public
        view
        returns (string memory)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        string[] memory creationTimes = splitWithDelimiter(
            nodeRewardManager._getNodesCreationTime(account)
        );
        return creationTimes[creationTimes.length - 1];
    }

    function splitWithDelimiter(string memory str)
        internal
        pure
        returns (string[] memory)
    {
        string[] memory split = str.split("#");
        return split;
    }

    function createNodeWithExtraBalances(
        string memory name,
        address referred_by,
        uint256 total,
        uint32 nodeType
    ) public payable {
        require(total <= 5 && total >= 1, "Max: 5 nodes Min: 1");
        require(
            bytes(name).length > 3 && bytes(name).length < 32,
            "NODE CREATION: NAME SIZE INVALID"
        );
        address sender = _msgSender();
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        uint256 totalUserNodes = nodeRewardManager._getTotalUserNodes(sender);
        require(totalUserNodes < 100, "Maximum node exceeded");
        require(
            sender != address(0),
            "NODE CREATION:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "NODE CREATION: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "NODE CREATION: futur and rewardsPool cannot create node"
        );
        uint256 nodePrice = 0;
        if (nodeType == 2) {
            nodePrice = nodeRewardManager.getNodePriceByType(nodeType);
        } else {
            nodePrice = nodeRewardManager.nodePrice();
        }
        require(
            extraUserBalances[sender] >= nodePrice,
            "NODE CREATION: Balance too low for creation."
        );
        uint256 finalPrice = total.mul(nodePrice);

        require(
            extraUserBalances[sender] >= finalPrice,
            "NODE CREATION: Balance not enough for number of nodes"
        );
        extraUserBalances[sender] -= finalPrice;
        nodeRewardManager.createNode(
            sender,
            name,
            referred_by,
            nodeType,
            total
        );
        string memory nodeId = _getLastNodeId(sender, nodeType);
        masterOfCoin.payFee(nodeId);
    }

    function updateCreationTaxPool(address newAddress) external onlyOwner {
        creationTaxPool = newAddress;
    }

    function updateTaxPool(address newAddress) external onlyOwner {
        taxPool = newAddress;
    }

    function _cashoutAllNodesReward(address account, uint32 nodeType)
        internal
        returns (uint256, uint256)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        string[] memory creationTimes = splitWithDelimiter(
            nodeRewardManager._getNodesCreationTime(account)
        );
        string[] memory lastClaimTimes = splitWithDelimiter(
            nodeRewardManager._getNodesCreationTime(account)
        );
        uint256 nodesCount = creationTimes.length;
        uint256 fee = 0;
        // bool isDefector = false;
        uint256 rewardsTotal = 0;

        for (uint256 i = 0; i < nodesCount; i++) {
            uint256 nodeReward = _getRewardAmountOf(
                account,
                st2num(creationTimes[i]),
                nodeType
            );
            if (nodeReward > 0) {
                if (block.timestamp - st2num(lastClaimTimes[i]) <= limits[0]) {
                    fee += nodeReward.mul(taxes[0]).div(100);
                }
                if (
                    block.timestamp - st2num(lastClaimTimes[i]) > limits[0] &&
                    block.timestamp - st2num(lastClaimTimes[i]) <= limits[1]
                ) {
                    fee += nodeReward.mul(taxes[1]).div(100);
                }
                if (
                    block.timestamp - st2num(lastClaimTimes[i]) > limits[1] &&
                    block.timestamp - st2num(lastClaimTimes[i]) <= limits[2]
                ) {
                    fee += nodeReward.mul(taxes[2]).div(100);
                }
                if (block.timestamp - st2num(lastClaimTimes[i]) > limits[3]) {
                    fee += nodeReward.mul(taxes[3]).div(100);
                }
                rewardsTotal += nodeReward;
            }
        }
        nodeRewardManager._cashoutAllNodesReward(account);
        return (rewardsTotal, fee);
    }

    function cashoutAll(uint32 nodeType) public {
        address sender = _msgSender();
        require(
            sender != address(0),
            "MANIA CSHT:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "MANIA CSHT: futur and rewardsPool cannot cashout rewards"
        );
        (uint256 rewardAmount, uint256 fee) = _cashoutAllNodesReward(
            sender,
            nodeType
        );

        require(
            rewardAmount > 0,
            "MANIA CSHT: You don't have enough reward to cash out"
        );

        if (swapLiquify) {
            rewardAmount = rewardAmount.sub(fee);
            token.transferFrom(distributionPool, taxPool, fee);
        }
        token.transferFrom(distributionPool, sender, rewardAmount);
    }

    function cashoutReward(uint256 blocktime, uint32 nodeType) public {
        address sender = _msgSender();
        require(sender != address(0), "CSHT:  creation from the zero address");
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "CSHT: futur and rewardsPool cannot cashout rewards"
        );
        (uint256 rewardAmount, uint256 fee) = _cashoutNodeReward(
            sender,
            blocktime,
            nodeType
        );
        require(
            rewardAmount > 0,
            "CSHT: You don't have enough reward to cash out"
        );

        if (swapLiquify) {
            token.transferFrom(distributionPool, taxPool, fee);
        }
        uint256 finalReward = rewardAmount.sub(fee);
        token.transferFrom(distributionPool, sender, finalReward);
    }

    function updateLimit(uint256[4] memory _limits, uint256[4] memory _taxes)
        external
        onlyOwner
    {
        require(_limits.length == _taxes.length, "arrays must be equal");
        require(limits.length == 4, "array length must be equal 4");
        limits = _limits;
        taxes = _taxes;
    }

    function _cashoutNodeReward(
        address account,
        uint256 _creationTime,
        uint32 nodeType
    ) internal returns (uint256, uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        uint256 dueDate = _getNodeDueDate(account, _creationTime, nodeType);
        if (block.timestamp > dueDate) {
            return (0, 0);
        }
        uint256 fee = 0;
        (uint256 nodeReward, ) = nodeRewardManager._cashoutNodeReward(
            account,
            _creationTime
        );

        string[] memory creationTimes = splitWithDelimiter(
            nodeRewardManager._getNodesCreationTime(account)
        );
        string[] memory lastClaimTimes = splitWithDelimiter(
            nodeRewardManager._getNodesCreationTime(account)
        );
        string memory lastClaimTime;
        for (uint256 i = 0; i < creationTimes.length; i++) {
            if (st2num(creationTimes[i]) == _creationTime) {
                lastClaimTime = lastClaimTimes[i];
                break;
            }
        }
        if (block.timestamp - st2num(lastClaimTime) <= limits[0]) {
            fee += nodeReward.mul(taxes[0]).div(100);
        }
        if (
            block.timestamp - st2num(lastClaimTime) > limits[0] &&
            block.timestamp - st2num(lastClaimTime) <= limits[1]
        ) {
            fee += nodeReward.mul(taxes[1]).div(100);
        }
        if (
            block.timestamp - st2num(lastClaimTime) > limits[1] &&
            block.timestamp - st2num(lastClaimTime) <= limits[2]
        ) {
            fee += nodeReward.mul(taxes[2]).div(100);
        }
        if (block.timestamp - st2num(lastClaimTime) > limits[3]) {
            fee += nodeReward.mul(taxes[3]).div(100);
        }

        return (nodeReward, fee);
    }

    function cashoutAllNodesByType(uint256[] memory claimtimes, uint32 nodeType)
        public
    {
        address sender = _msgSender();
        require(sender != address(0), "CSHT:  creation from the zero address");
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "CSHT: futur and rewardsPool cannot cashout rewards"
        );
        uint256[] memory claimtimes_ = claimtimes;
        uint256 total = 0;
        uint256 feeTotal = 0;
        for (uint256 i = 0; i < claimtimes_.length; i++) {
            (uint256 rewardAmount, uint256 fee) = _cashoutNodeReward(sender, claimtimes_[i], nodeType);
            feeTotal += fee;
            total += rewardAmount;
        }
        require(total > 0, "CSHT: You don't have enough reward to cash out");
        if (swapLiquify) {
            token.transferFrom(distributionPool, taxPool, feeTotal);
        }
        uint256 finalReward = total.sub(feeTotal);
        token.transferFrom(distributionPool, sender, finalReward);
    }

    function getTotalNodes(uint32 nodeType) external view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        if (nodeType == 2) {
            return nodeRewardManager.zeusTotal();
        }
        return nodeRewardManager.totalNodesCreated();
    }

    function cashoutAllExtraBalances() public {
        address sender = _msgSender();
        require(
            sender != address(0),
            "MANIA CSHT:  creation from the zero address"
        );
        require(!_isBlacklisted[sender], "MANIA CSHT: Blacklisted address");
        require(
            sender != futurUsePool && sender != distributionPool,
            "MANIA CSHT: futur and rewardsPool cannot cashout rewards"
        );
        uint256 amount = extraUserBalances[sender];
        require(
            amount > 0,
            "MANIA CSHT: You don't have enough reward to cash out"
        );
        extraUserBalances[sender] -= amount;
        uint256 fee = amount.mul(cashoutFee).div(100);
        uint256 finalAmount = amount.sub(fee);
        token.transferFrom(distributionPool, sender, finalAmount);
    }

    function boostReward(uint256 amount) public onlyOwner {
        if (amount > address(this).balance) amount = address(this).balance;
        payable(owner()).transfer(amount);
    }

    function changeSwapLiquify(bool newVal) public onlyOwner {
        swapLiquify = newVal;
    }

    function getNodeNumberOf(address account, uint32 nodeType)
        public
        view
        returns (uint256)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager._getNodeNumberOf(account);
    }

    function getRewardAmountOf(address account, uint32 nodeType)
        public
        view
        onlyOwner
        returns (uint256)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager._getRewardAmountOf(account);
    }

    function getRewardAmount(uint32 nodeType) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return nodeRewardManager._getRewardAmountOf(_msgSender());
    }

    function changeNodePrice(uint256 newNodePrice, uint32 nodeType)
        public
        onlyOwner
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        nodeRewardManager._changeNodePrice(newNodePrice);
    }

    function getNodePrice(uint32 nodeType) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        if (nodeType == 2) {
            return nodeRewardManager.getNodePriceByType(nodeType);
        }
        return nodeRewardManager.nodePrice();
    }

    function changeRewardPerNode(uint256 newPrice, uint32 nodeType)
        public
        onlyOwner
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        nodeRewardManager._changeRewardPerNode(newPrice);
    }

    function getRewardPerNode(uint32 nodeType) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.rewardPerNode();
    }

    function changeClaimTime(uint256 newTime, uint32 nodeType)
        public
        onlyOwner
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        nodeRewardManager._changeClaimTime(newTime);
    }

    function getClaimTime(uint32 nodeType) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.claimTime();
    }

    function changeGasDistri(uint256 newGasDistri, uint32 nodeType)
        public
        onlyOwner
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        nodeRewardManager._changeGasDistri(newGasDistri);
    }

    function getGasDistri(uint32 nodeType) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.gasForDistribution();
    }

    function getNodesNames(uint32 nodeType)
        public
        view
        returns (string memory)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return nodeRewardManager._getNodesNames(_msgSender());
    }

    function getNodesCreatime(uint32 nodeType)
        public
        view
        returns (string memory)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return nodeRewardManager._getNodesCreationTime(_msgSender());
    }

    function getNodesRewards(uint32 nodeType)
        public
        view
        returns (string memory)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return _getNodesRewardAvailable(_msgSender(), nodeType);
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function st2num(string memory numString) internal pure returns (uint256) {
        uint256 val = 0;
        bytes memory stringBytes = bytes(numString);
        for (uint256 i = 0; i < stringBytes.length; i++) {
            uint256 exp = stringBytes.length - i;
            bytes1 ival = stringBytes[i];
            uint8 uval = uint8(ival);
            uint256 jval = uval - uint256(0x30);
            val += (uint256(jval) * (10**(exp - 1)));
        }
        return val;
    }

    function _getRewardAmountOf(
        address account,
        uint256 _creationTime,
        uint32 nodeType
    ) public view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        uint256 dueDate = _getNodeDueDate(account, _creationTime, nodeType);
        if (block.timestamp > dueDate) {
            return 0;
        }
        return nodeRewardManager._getRewardAmountOf(account, _creationTime);
    }

    function _getNodeId(
        address account,
        uint256 creationTime,
        string memory bridgeName
    ) internal pure returns (string memory) {
        uint256 acountToNum = uint256(uint160(account));
        string memory nodeId = string(
            abi.encodePacked(
                Strings.toString(acountToNum),
                "_",
                Strings.toString(creationTime)
            )
        );

        return string(abi.encodePacked(bridgeName, "_", nodeId));
    }

    function _getNodeDueDate(
        address account,
        uint256 creationTime,
        uint32 nodeType
    ) public view returns (uint256) {
        string memory bridgeName = getBridgeName(nodeType);
        string memory nodeId = _getNodeId(account, creationTime, bridgeName);
        return masterOfCoin.getDueDate(nodeId);
    }

    function _getNodesRewardAvailable(address account, uint32 nodeType)
        public
        view
        returns (string memory)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        string[] memory creationTimes = splitWithDelimiter(
            nodeRewardManager._getNodesCreationTime(account)
        );
        uint256 nodesCount = creationTimes.length;
        string memory _rewardsAvailable = uint2str(
            _getRewardAmountOf(account, st2num(creationTimes[0]), nodeType)
        );
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    separator,
                    uint2str(
                        _getRewardAmountOf(
                            account,
                            st2num(creationTimes[i]),
                            nodeType
                        )
                    )
                )
            );
        }
        return _rewardsAvailable;
    }

    function getNodesLastClaims(uint32 nodeType)
        public
        view
        returns (string memory)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        require(_msgSender() != address(0), "SENDER CAN'T BE ZERO");
        require(nodeRewardManager._isNodeOwner(_msgSender()), "NO NODE OWNER");
        return nodeRewardManager._getNodesLastClaimTime(_msgSender());
    }

    function getTotalStakedReward(uint32 nodeType)
        public
        view
        returns (uint256)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.totalRewardStaked();
    }

    function getTotalCreatedNodes(uint32 nodeType)
        public
        view
        returns (uint256)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.totalNodesCreated();
    }

    function cashoutToWallet(uint32 nodeType) external {
        address sender = _msgSender();
        (uint256 rewardAmount, ) = _cashoutAllNodesReward(sender, nodeType);
        require(rewardAmount > 0, "Insufficient fund");
        extraUserBalances[sender] += rewardAmount;
    }

    function withdrawReferralBonus(uint32 nodeType) external {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        uint256 total = nodeRewardManager.withdrawReferralBonus(_msgSender());
        require(total > 0, "Not enough funds to withdraw");
        token.transferFrom(distributionPool, _msgSender(), total);
    }

    function getReferralBonus(uint32 nodeType) external view returns (uint256) {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.getReferralBonus(_msgSender());
    }

    function getReferrals(uint32 nodeType)
        external
        view
        returns (address[] memory)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager.getReferrals(_msgSender());
    }

    function setNodeManagement(address nodeManagement, uint32 nodeType)
        external
        onlyOwner
    {
        if (nodeType == 0) {
            herculesNodeRewardManager = NODERewardManagement(nodeManagement);
        }
        if (nodeType == 1) {
            heraNodeRewardManager = NODERewardManagement(nodeManagement);
        }
        if (nodeType == 2) {
            zeusNodeRewardManager = NODERewardManagement(nodeManagement);
        }
        if (nodeType == 3) {
            kronosNodeRewardManager = NODERewardManagement(nodeManagement);
        }
    }

    function balanceOf(address account) public view returns (uint256) {
        return token.balanceOf(account);
    }

    function getUserReferralCount(address account, uint32 nodeType)
        external
        view
        returns (uint256)
    {
        NODERewardManagement nodeRewardManager = getNodeRewardManager(nodeType);
        return nodeRewardManager._getUserReferralCount(account);
    }

    function getNodeRewardManager(uint32 nodeType)
        private
        view
        returns (NODERewardManagement)
    {
        NODERewardManagement nodeRewardManager;
        if (nodeType == 0) {
            nodeRewardManager = herculesNodeRewardManager;
        }
        if (nodeType == 1) {
            nodeRewardManager = heraNodeRewardManager;
        }
        if (nodeType == 2) {
            nodeRewardManager = zeusNodeRewardManager;
        }
        if (nodeType == 3) {
            nodeRewardManager = kronosNodeRewardManager;
        }
        return nodeRewardManager;
    }

    function getBridgeName(uint32 nodeType)
        private
        pure
        returns (string memory)
    {
        string memory name;
        if (nodeType == 0) {
            name = "HERCULES";
        }
        if (nodeType == 1) {
            name = "HERA";
        }
        if (nodeType == 2) {
            name = "ZEUS";
        }
        if (nodeType == 3) {
            name = "KRONOS";
        }
        return name;
    }
}