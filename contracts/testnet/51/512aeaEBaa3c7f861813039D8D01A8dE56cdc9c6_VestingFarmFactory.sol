/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-13
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File contracts/governance/ICongressMembersRegistry.sol

pragma solidity 0.6.12;

/**
 * ICongressMembersRegistry contract.
 * @author Nikola Madjarevic
 * Date created: 13.9.21.
 * Github: madjarevicn
 */

interface ICongressMembersRegistry {
    function isMember(address _address) external view returns (bool);
    function getMinimalQuorum() external view returns (uint256);
}


// File contracts/governance/IMaintainersRegistry.sol

pragma solidity 0.6.12;

interface IMaintainersRegistry {
    function isMaintainer(address _address) external view returns (bool);
}


// File contracts/system/TokensFarmUpgradable.sol

pragma solidity 0.6.12;


//to be fixed
contract TokensFarmUpgradable {

    // Address of tokens congress
    address public tokensFarmCongress;
    // Instance of maintainers registry object
    IMaintainersRegistry public maintainersRegistry;

    // Only maintainer modifier
    modifier onlyMaintainer {
        require(
            maintainersRegistry.isMaintainer(msg.sender),
            "TokensFarmUpgradable: Restricted only to Maintainer"
        );
        _;
    }

    // Only tokens farm congress modifier
    modifier onlyTokensFarmCongress {
        require(
            msg.sender == tokensFarmCongress,
            "TokensFarmUpgradable: Restricted only to TokensFarmCongress"
        );
        _;
    }

    /**
     * @notice function to set congress and maintainers registry address
     *
     * @param _tokensFarmCongress - address of tokens farm congress
     * @param _maintainersRegistry - address of maintainers registry
     */
    function setCongressAndMaintainersRegistry(
        address _tokensFarmCongress,
        address _maintainersRegistry
    )
        internal
    {
        require(
            _tokensFarmCongress != address(0x0),
            "tokensFarmCongress can not be 0x0 address"
        );
        require(
            _maintainersRegistry != address(0x0),
            "_maintainersRegistry can not be 0x0 address"
        );

        tokensFarmCongress = _tokensFarmCongress;
        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);
    }

    /**
     * @notice function to set new maintainers registry address
     *
     * @param _maintainersRegistry - address of new maintainers registry
     */
    function setMaintainersRegistry(
        address _maintainersRegistry
    )
        external
        onlyTokensFarmCongress
    {
        require(
            _maintainersRegistry != address(0x0),
            "_maintainersRegistry can not be 0x0 address"
        );

        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);
    }

    /**
    * @notice function to set new congress registry address
    *
    * @param _tokensFarmCongress - address of new tokens farm congress
    */
    function setTokensFarmCongress(
        address _tokensFarmCongress
    )
        external
        onlyTokensFarmCongress
    {
        require(
            _tokensFarmCongress != address(0x0),
            "_maintainersRegistry can not be 0x0 address"
        );

        tokensFarmCongress = _tokensFarmCongress;
    }
}


// File contracts/interfaces/vesting/ILinearMerkleVestingFarm.sol

pragma solidity 0.6.12;

interface ILinearMerkleVestingFarm {
    function setEndTime(uint256 _endTime) external ;
}


// File contracts/interfaces/vesting/IVestingFarm.sol

pragma solidity 0.6.12;

interface IVestingFarm {
    function setStartTime(uint256 _startTime) external ;
    function fundAndOrActivate(uint256 _amount) external ;
    function pauseFarm() external;
    function removeLeftOverRewards(address collector) external ;
    function emergencyAssetsWithdrawal(address asset, address collector) external ;
}


// File contracts/interfaces/vesting/IRegularVesting.sol

pragma solidity 0.6.12;

interface IRegularVesting {
    //function addUsersRewards(Reward[] calldata _rewards) external;
    function removeUser(address user) external;
}


// File contracts/interfaces/vesting/IMerkleFarm.sol

pragma solidity 0.6.12;

interface IMerkleFarm {
    function setMerkleRoot(bytes32 root, uint256 additionalFunds) external ;
    function removeUser(bytes32[] memory proof, address user, uint256 amount) external ;
}


// File contracts/interfaces/vesting/ILinearVestingFarm.sol

pragma solidity 0.6.12;

interface ILinearVestingFarm {
    function setEndTime(uint256 _periodFinish) external;
}


// File @openzeppelin/contracts/math/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]


pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


// File @openzeppelin/contracts-upgradeable/proxy/[email protected]


// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts/utils/[email protected]


pragma solidity >=0.6.2 <0.8.0;

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


// File @openzeppelin/contracts/proxy/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /**
     * @dev This is a virtual function that should be overriden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internall call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback () external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive () external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overriden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {
    }
}


// File @openzeppelin/contracts/proxy/[email protected]


pragma solidity >=0.6.0 <0.8.0;


/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 *
 * Upgradeability is only provided internally through {_upgradeTo}. For an externally upgradeable proxy see
 * {TransparentUpgradeableProxy}.
 */
contract UpgradeableProxy is Proxy {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializating the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) public payable {
        assert(_IMPLEMENTATION_SLOT == bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1));
        _setImplementation(_logic);
        if(_data.length > 0) {
            Address.functionDelegateCall(_logic, _data);
        }
    }

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        bytes32 slot = _IMPLEMENTATION_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            impl := sload(slot)
        }
    }

    /**
     * @dev Upgrades the proxy to a new implementation.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal virtual {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "UpgradeableProxy: new implementation is not a contract");

        bytes32 slot = _IMPLEMENTATION_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newImplementation)
        }
    }
}


// File @openzeppelin/contracts/proxy/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev This contract implements a proxy that is upgradeable by an admin.
 *
 * To avoid https://medium.com/nomic-labs-blog/malicious-backdoors-in-ethereum-proxies-62629adf3357[proxy selector
 * clashing], which can potentially be used in an attack, this contract uses the
 * https://blog.openzeppelin.com/the-transparent-proxy-pattern/[transparent proxy pattern]. This pattern implies two
 * things that go hand in hand:
 *
 * 1. If any account other than the admin calls the proxy, the call will be forwarded to the implementation, even if
 * that call matches one of the admin functions exposed by the proxy itself.
 * 2. If the admin calls the proxy, it can access the admin functions, but its calls will never be forwarded to the
 * implementation. If the admin tries to call a function on the implementation it will fail with an error that says
 * "admin cannot fallback to proxy target".
 *
 * These properties mean that the admin account can only be used for admin actions like upgrading the proxy or changing
 * the admin, so it's best if it's a dedicated account that is not used for anything else. This will avoid headaches due
 * to sudden errors when trying to call a function from the proxy implementation.
 *
 * Our recommendation is for the dedicated account to be an instance of the {ProxyAdmin} contract. If set up this way,
 * you should think of the `ProxyAdmin` instance as the real administrative interface of your proxy.
 */
contract TransparentUpgradeableProxy is UpgradeableProxy {
    /**
     * @dev Initializes an upgradeable proxy managed by `_admin`, backed by the implementation at `_logic`, and
     * optionally initialized with `_data` as explained in {UpgradeableProxy-constructor}.
     */
    constructor(address _logic, address admin_, bytes memory _data) public payable UpgradeableProxy(_logic, _data) {
        assert(_ADMIN_SLOT == bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1));
        _setAdmin(admin_);
    }

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 private constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Modifier used internally that will delegate the call to the implementation unless the sender is the admin.
     */
    modifier ifAdmin() {
        if (msg.sender == _admin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current admin.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyAdmin}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103`
     */
    function admin() external ifAdmin returns (address admin_) {
        admin_ = _admin();
    }

    /**
     * @dev Returns the current implementation.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-getProxyImplementation}.
     *
     * TIP: To get this value clients can read directly from the storage slot shown below (specified by EIP1967) using the
     * https://eth.wiki/json-rpc/API#eth_getstorageat[`eth_getStorageAt`] RPC call.
     * `0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc`
     */
    function implementation() external ifAdmin returns (address implementation_) {
        implementation_ = _implementation();
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-changeProxyAdmin}.
     */
    function changeAdmin(address newAdmin) external virtual ifAdmin {
        require(newAdmin != address(0), "TransparentUpgradeableProxy: new admin is the zero address");
        emit AdminChanged(_admin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev Upgrade the implementation of the proxy.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgrade}.
     */
    function upgradeTo(address newImplementation) external virtual ifAdmin {
        _upgradeTo(newImplementation);
    }

    /**
     * @dev Upgrade the implementation of the proxy, and then call a function from the new implementation as specified
     * by `data`, which should be an encoded function call. This is useful to initialize new storage variables in the
     * proxied contract.
     *
     * NOTE: Only the admin can call this function. See {ProxyAdmin-upgradeAndCall}.
     */
    function upgradeToAndCall(address newImplementation, bytes calldata data) external payable virtual ifAdmin {
        _upgradeTo(newImplementation);
        Address.functionDelegateCall(newImplementation, data);
    }

    /**
     * @dev Returns the current admin.
     */
    function _admin() internal view virtual returns (address adm) {
        bytes32 slot = _ADMIN_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            adm := sload(slot)
        }
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        bytes32 slot = _ADMIN_SLOT;

        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, newAdmin)
        }
    }

    /**
     * @dev Makes sure the admin cannot access the fallback function. See {Proxy-_beforeFallback}.
     */
    function _beforeFallback() internal virtual override {
        require(msg.sender != _admin(), "TransparentUpgradeableProxy: admin cannot fallback to proxy target");
        super._beforeFallback();
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File @openzeppelin/contracts/token/ERC20/[email protected]


pragma solidity >=0.6.0 <0.8.0;



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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}


// File @openzeppelin/contracts/proxy/[email protected]


pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address master) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `master`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `master` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address master, bytes32 salt) internal returns (address instance) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt, address deployer) internal pure returns (address predicted) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, master))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address master, bytes32 salt) internal view returns (address predicted) {
        return predictDeterministicAddress(master, salt, address(this));
    }
}


// File contracts/Factories/VestingFarmFactory.sol

pragma solidity 0.6.12;
//pragma experimental ABIEncoderV2;












contract VestingFarmFactory is TokensFarmUpgradable, Initializable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Clones for *;

    //Enum of farm types
    enum FarmTypes {
        LINEAR,
        ITERATIVE,
        MERKLE_LINEAR,
        MERKLE_ITERATIVE
    }

    //Mapping of farm implementations
    mapping(FarmTypes => address) public farmImplementations;
    //Mapping of farm by types
    mapping(FarmTypes => address[]) public allDeployedFarmsByTypes;
    // FeeCollector + CongressAddress
    address payable public feeCollector;
    // Address of proxy admin
    address public proxyAdmin;

    // Events
    event DeployedFarm(
        uint256 indexed typeOfFarm,
        address indexed farmAddress
    );
    event FarmImplementationSet(
        uint256 indexed typeOfFarm,
        address indexed farmImplementation
    );
    event AllImplementationSet(
        address indexed linearVestingFarm,
        address indexed iterativeVestingFarm,
        address indexed merkleLinearVestingFarm,
        address merkleIterativeVestingFarm
    );
    event SetProxyAdmin(
        address indexed proxyAddress
    );
    event FeeCollectorSet(address indexed feeCollector);

    modifier onlyCongressOrMaintainer(){
        if(msg.sender != tokensFarmCongress){
            require(
                maintainersRegistry.isMaintainer(msg.sender),
                "Caller is not maintainer nor congress"
            );
        }
        _;
    }

    /**
     * @notice function sets initial state of contract
     *
     * @param _iterativeVestingFarmImplementation -
     * address of deployed farm
     * @param _linearVestingFarmImplementation -
     * address of deployed farm
     * @param _merkleLinearVestingFarmImplementation -
     * address of deployed farm
     * @param _merkleIterativeVestingFarmImplementation -
     * address of deployed farm
     * @param _tokensFarmCongress - address of farm congress
     * @param _maintainersRegistry - address of maintainers registry
     * @param _feeCollector - address of feeCollector
     * @param _proxyAdmin - address of proxy admin
     */
    function initialize(
        address _iterativeVestingFarmImplementation,
        address _linearVestingFarmImplementation,
        address _merkleLinearVestingFarmImplementation,
        address _merkleIterativeVestingFarmImplementation,
        address _tokensFarmCongress,
        address _maintainersRegistry,
        address _proxyAdmin,
        address payable _feeCollector
    )
        external
        initializer
    {
        require(
            _iterativeVestingFarmImplementation != address(0),
            "iterativeFarmImplementation can not be 0x0 address"
        );
        require(
            _linearVestingFarmImplementation != address(0),
            "linearFarmImplementation can not be 0x0 address"
        );
        require(
            _merkleLinearVestingFarmImplementation != address(0),
            "merkleLinearFarmImplementation can not be 0x0 address"
        );
        require(
            _merkleIterativeVestingFarmImplementation != address(0),
            "merkleLinearFarmImplementation can not be 0x0 address"
        );
        require(
            _feeCollector != address(0),
            "_feeCollector can not be 0x0 address"
        );
        require(
            _proxyAdmin != address(0),
            "Proxy admin can not be 0x0 address"
        );

        // set congress and maintainers registry address
        setCongressAndMaintainersRegistry(
            _tokensFarmCongress,
            _maintainersRegistry
        );

        //add farms implementations to mapping
        farmImplementations[FarmTypes.LINEAR] = _linearVestingFarmImplementation;
        farmImplementations[FarmTypes.ITERATIVE] = _iterativeVestingFarmImplementation;
        farmImplementations[FarmTypes.MERKLE_LINEAR] = _merkleLinearVestingFarmImplementation;
        farmImplementations[FarmTypes.MERKLE_ITERATIVE] = _merkleIterativeVestingFarmImplementation;
        // address of fee collector
        feeCollector = _feeCollector;
        // address of proxyAdmin
        proxyAdmin = _proxyAdmin;
    }

    /**
     * @notice function to check does factory has enough funds
     *
     * @param _rewardToken - address of reward token
     * @param _totalBudget - funding the farm
     * with this amount of tokens
     */
    function _sufficientFunds(
        address _rewardToken,
        uint256 _totalBudget
    )
        internal
        view
        returns(bool)
    {
        // instance of erc20 contract
        IERC20 rewardToken = IERC20(_rewardToken);
        return rewardToken.balanceOf(address(this)) >= _totalBudget;
    }

    /**
     * @notice function is giving back length of enum
     *
     * @param _farmIndex - index of type
     *
     * @return boolean if it is in range or not
     */
    function isEnumInRange(
        uint256 _farmIndex
    )
        internal
        pure
        returns (bool)
    {
        return (
            _farmIndex >= 0 &&
            _farmIndex <= uint8(FarmTypes.MERKLE_ITERATIVE)
        );
    }

    /**
     * @notice function returns the deployed farms address[] by the farm type
     *
     * @param _farmIndex - the enum index of the farm type
     *
     * @return address array of specific type of deployed farm
     */
    function _getFarmArray(
        uint256 _farmIndex
    )
        internal
        view
        returns(address[] memory)
    {
        require(
            isEnumInRange(_farmIndex),
            "Farm index is out of range"
        );

        FarmTypes farmType = FarmTypes(_farmIndex);
        return allDeployedFarmsByTypes[farmType];
    }

    /**
     * @notice function returns the farm implementation address by the farm type
     *
     * @param _farmIndex - the enum index of the farm type
     *
     * @return address of farm implementation
     */
    function _getFarmImplementation(
        uint256 _farmIndex
    )
        internal
        view
        returns(address)
    {
        require(
            isEnumInRange(_farmIndex),
            "Farm index is out of range"
        );

        FarmTypes farmType = FarmTypes(_farmIndex);
        return farmImplementations[farmType];
    }

    /**
     * @notice function fund a vesting farm
     *
     * @param _farmAddress - function will operate on
     * farm with this address
     * @param _rewardToken - address of reward token
     * @param _amount - funding the farm with this amount of tokens
     */
    function _fundInternalVestingFarm(
        address _farmAddress,
        address _rewardToken,
        uint256 _amount
    )
        internal
    {
        require(
            _farmAddress != address(0x0),
            "Farm's address can't be 0x0 address"
        );
        require(
            _rewardToken != address(0x0),
            "RewardToken address can't be 0x0 address"
        );
        require(
            _amount >= 0,
            "Amount must be over or equal to 0"
        );

        // instance of erc20 contract
        IERC20 rewardToken = IERC20(_rewardToken);
        // approval of transaction
        rewardToken.approve(_farmAddress, _amount);

        IVestingFarm farm = IVestingFarm(_farmAddress);
        farm.fundAndOrActivate(_amount);
    }

    /************************************ Linear vesting farm related functions ***************************************/

    /**
     * @notice function deploys linear vesting farms
     *
     * @dev store their addresses in array
     * @dev deploys tokens farm proxy contract
     * @dev initialization of contract
     *
     * @param _vestedToken - address of vesting token
     * @param _startTime - time when vesting start
     * @param _endTime - time when vesting is finished
     * @param _claimPercent - claim portion after start
     * @param _beforeStartClaimPercent - claim portion before start
     * @param _initialFundPercent - initial percent that needs to be funded
     */
    function deployLinearVestingFarm(
        address _vestedToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _claimPercent,
        uint256 _beforeStartClaimPercent,
        uint256 _initialFundPercent
    )
        external
        onlyMaintainer
    {
        address proxy;

        // Deploy linear vesting farm
        uint256 startTime = _startTime;
        if(startTime == 0){
            startTime = block.timestamp + 10;
        }
        bytes memory data = abi.encodeWithSignature(
            "initialize(address,uint256,uint256,uint256,uint256,uint256,address)",
            _vestedToken,
            startTime,
            _endTime,
            _claimPercent,
            _beforeStartClaimPercent,
            _initialFundPercent,
            farmImplementations[FarmTypes.LINEAR]
        );

        proxy = address(
            new TransparentUpgradeableProxy(
                farmImplementations[FarmTypes.LINEAR],
                proxyAdmin,
                data
            )
        );
        // Add deployed farm to array of deployed farms
        allDeployedFarmsByTypes[FarmTypes.LINEAR].push(proxy);
        // Emits event with farms address
        emit DeployedFarm(uint8(FarmTypes.LINEAR), proxy);
    }

//    /**
//     * @notice function add more users on farm
//     *
//     * @param farmAddress - function will operate on
//     * farm with this address
//     * @param _rewards - array of users
//     */
//    function addMoreUsersOnSpecificLinearFarm(
//        address farmAddress,
//        Reward[] calldata _rewards
//    )
//        external
//        onlyMaintainer
//    {
//        require(
//            farmAddress != address(0x0),
//            "Farm address can not be 0x0 address"
//        );
//
//        IRegularVesting linearVestingFarm;
//        linearVestingFarm = IRegularVesting(farmAddress);
//        linearVestingFarm.addUsersRewards(_rewards);
//    }

    /**
     * @notice function removing users from farm
     *
     * @param farmAddress - function will operate on
     * farm with this address
     * @param user - address of user,
     * that is getting removed
     */
    function removeUserOnSpecificLinearFarm(
        address farmAddress,
        address user
    )
        external
        onlyTokensFarmCongress
    {
        require(
            farmAddress != address(0x0),
            "Farm address can not be 0x0 address"
        );
        require(
            user != address(0x0),
            "Farm address can not be 0x0 address"
        );

        IRegularVesting linearVestingFarm;
        linearVestingFarm = IRegularVesting(farmAddress);
        linearVestingFarm.removeUser(user);
    }

    /********************************** Iterative vesting farm related functions **************************************/

    /**
     * @notice function deploys iterative vesting farms
     *
     * @dev store their addresses in array
     * @dev deploys tokens farm proxy contract
     * @dev initialization of contract
     *
     * @param _vestedToken - address of vesting token
     * @param _startTime - time when vesting start
     * @param _vestingPortion - how much is given to user,
     * per vesting
     * @param _distributionPeriod - how much time will pass,
     * before another vesting
     * @param _claimPercent - claim portion before start
     * @param _beforeStartClaimPercent - claim portion after start
     * @param _initialFundPercent - initial percent that needs to be funded
     */
    function deployIterativeVestingFarm(
        address _vestedToken,
        uint256 _startTime,
        uint256 _vestingPortion,
        uint256 _distributionPeriod,
        uint256 _claimPercent,
        uint256 _beforeStartClaimPercent,
        uint256 _initialFundPercent
    )
        external
        onlyMaintainer
    {
        address proxy;

        // Deploy iterative vesting farm
        uint256 startTime = _startTime;
        if(startTime == 0){
            startTime = block.timestamp + 10;
        }

        bytes memory data = abi.encodeWithSignature(
            "initialize(address,uint256,uint256,uint256,uint256,uint256,uint256,address)",
            _vestedToken,
            startTime,
            _vestingPortion,
            _distributionPeriod,
            _claimPercent,
            _beforeStartClaimPercent,
            _initialFundPercent,
            farmImplementations[FarmTypes.ITERATIVE]
        );

        proxy = address(
            new TransparentUpgradeableProxy(
                farmImplementations[FarmTypes.ITERATIVE],
                proxyAdmin,
                data
            )
        );
        // Add deployed farm to array of deployed farms
        allDeployedFarmsByTypes[FarmTypes.ITERATIVE].push(proxy);
        // Emits event with farms address
        emit DeployedFarm(uint8(FarmTypes.ITERATIVE), proxy);
    }

//    /**
//     * @notice function add more users on farm
//     *
//     * @param farmAddress - function will operate on
//     * farm with this address
//     * @param _rewards - array of users
//     */
//    function addMoreUsersOnSpecificIterativeFarm(
//        address farmAddress,
//        Reward[] calldata _rewards
//    )
//        external
//        onlyMaintainer
//    {
//        require(
//            farmAddress != address(0x0),
//            "Farm address can not be 0x0 address"
//        );
//
//        IRegularVesting iterativeVestingFarm;
//        iterativeVestingFarm = IRegularVesting(farmAddress);
//        iterativeVestingFarm.addUsersRewards(_rewards);
//    }

    /**
     * @notice function removes user from farm
     *
     * @param farmAddress - function will operate on
     * farm with this address
     * @param user - address of user,
     * that is getting removed
     */
    function removeUserOnSpecificIterativeFarm(
        address farmAddress,
        address user
    )
        external
        onlyTokensFarmCongress
    {
        require(
            farmAddress != address(0x0),
            "Farm address can not be 0x0 address"
        );
        require(
            user != address(0x0),
            "Farm address can not be 0x0 address"
        );

        IRegularVesting iterativeVestingFarm;
        iterativeVestingFarm = IRegularVesting(farmAddress);
        iterativeVestingFarm.removeUser(user);
    }

    /******************************** Linear Merkle vesting farm related functions ************************************/

    /**
     * @notice function to deploy and fund a merkle linear vesting farm
     *
     * @param _root - the merkle root
     * @param _vestedToken - address of the reward token
     * @param _startTime - the farm start time
     * @param _endTime - the farm end time
     * @param _earlyClaimAvailablePer - early claim after start
     * @param _beforeStartClaimPercent - early claim before start
     * @param _initialFundPercent - initial percent that needs to be funded
     * @param _totalRewards - the farm total rewards amount
     * @param _fundingAmount - amount to fund with
     */
    function deployAndFundMerkleLinearVestingFarm(
        bytes32 _root,
        address _vestedToken,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _earlyClaimAvailablePer,
        uint256 _beforeStartClaimPercent,
        uint256 _initialFundPercent,
        uint256 _totalRewards,
        uint256 _fundingAmount
    )
        external
        onlyMaintainer
    {
        require(
            _sufficientFunds(_vestedToken, _fundingAmount),
            "There is not enough tokens left in factory to fund"
        );

        uint256 startTime = _startTime;
        if(startTime == 0){
            startTime = block.timestamp + 10;
        }

        address proxy;
        // Deploy merkle linear vesting farm
        bytes memory data = abi.encodeWithSignature(
            "initialize(bytes32,address,uint256,uint256,uint256,uint256,uint256,uint256,address)",
            _root,
            _vestedToken,
            startTime,
            _endTime,
            _earlyClaimAvailablePer,
            _beforeStartClaimPercent,
            _initialFundPercent,
            _totalRewards,
            farmImplementations[FarmTypes.MERKLE_LINEAR]
        );

        proxy = address(
            new TransparentUpgradeableProxy(
                farmImplementations[FarmTypes.MERKLE_LINEAR],
                proxyAdmin,
                data
            )
        );

        // Add deployed farm to array of deployed farms
        allDeployedFarmsByTypes[FarmTypes.MERKLE_LINEAR].push(proxy);
        // Funding the farm
        _fundInternalVestingFarm(proxy, _vestedToken, _fundingAmount);
        // Emits event with farms address
        emit DeployedFarm(uint8(FarmTypes.MERKLE_LINEAR), proxy);
    }

    /**
     * @notice function is setting new end time to merkle linear
     *
     * @param farmAddress - the merkle linear farm address
     * @param _endTime - unix timestamp
     */
    function setEndTimeMerkleLinear(
        address farmAddress,
        uint256 _endTime
    )
        external
        onlyMaintainer
    {
        require(
            farmAddress != address(0),
            "farmAddress address can not be 0x0"
        );

        ILinearMerkleVestingFarm merkleLinearVestingFarm;
        merkleLinearVestingFarm = ILinearMerkleVestingFarm(farmAddress);
        merkleLinearVestingFarm.setEndTime(_endTime);
    }

    /******************************** Iterative Merkle vesting farm related functions *********************************/

    /**
     * @notice function to deploy and fund a merkle iterative vesting farm
     *
     * @param _root - hash of top node in tree
     * @param _vestedToken - address of vested token
     * @param _startTime - time when farm starts
     * @param _nVestingPortions - amount that is distributed of whole amount
     * @param _distributionIntervalDays - on how many days,
     * reward is distributed to users
     * @param _earlyClaimAvailablePer - claim percentage after start
     * @param _beforeStartClaimPercent - claim percentage before start
     * @param _totalRewards - total sum of everybody's rewards
     * @param _fundingAmount - amount to fund with
     */
    function deployAndFundMerkleIterativeVestingFarm(
        bytes32 _root,
        address _vestedToken,
        uint256 _startTime,
        uint256 _nVestingPortions,
        uint256 _distributionIntervalDays,
        uint256 _earlyClaimAvailablePer,
        uint256 _beforeStartClaimPercent,
        uint256 _initialFundPercent,
        uint256 _totalRewards,
        uint256 _fundingAmount
    )
        external
        onlyMaintainer
    {
        require(
            _sufficientFunds(_vestedToken, _fundingAmount),
            "There is not enough tokens left in factory to fund"
        );

        uint256 startTime = _startTime;
        if(startTime == 0){
            startTime = block.timestamp + 10;
        }

        address proxy;
        // Deploy merkle linear vesting farm
        bytes memory data = abi.encodeWithSignature(
            "initialize(bytes32,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256,address)",
            _root,
            _vestedToken,
            startTime,
            _nVestingPortions,
            _distributionIntervalDays,
            _earlyClaimAvailablePer,
            _beforeStartClaimPercent,
            _initialFundPercent,
            _totalRewards,
            farmImplementations[FarmTypes.MERKLE_ITERATIVE]
        );

        proxy = address(
            new TransparentUpgradeableProxy(
                farmImplementations[FarmTypes.MERKLE_ITERATIVE],
                proxyAdmin,
                data
            )
        );
        // Add deployed farm to array of deployed farms
        allDeployedFarmsByTypes[FarmTypes.MERKLE_ITERATIVE].push(proxy);
        // Funding the farm
        _fundInternalVestingFarm(proxy, _vestedToken, _fundingAmount);
        // Emits event with farms address
        emit DeployedFarm(uint8(FarmTypes.MERKLE_ITERATIVE), proxy);
    }

    /******************************** Merkle farm related functions ************************************/

    /**
     * @notice function is setting merkle root for the farm
     *
     * @param farmAddress - the merkle farm address
     * @param root - hash of top node
     * @param additionalFunds - sum of new amount of rewards
     */
    function setMerkleRootForFarm(
        address farmAddress,
        bytes32 root,
        uint256 additionalFunds
    )
        external
        onlyMaintainer
    {
        require(
            farmAddress != address(0),
            "farmAddress address can not be 0x0"
        );

        IMerkleFarm farm;
        farm = IMerkleFarm(farmAddress);
        farm.setMerkleRoot(root, additionalFunds);
    }

    /**
     * @notice function is removing user from farm
     *
     * @param farmAddress - the merkle farm address
     * @param proof - array of hashes
     * @param user - address of user,
     * that needs to be removed
     * @param amount - amount of user
     */
    function removeUserFromMerkleFarm(
        address farmAddress,
        bytes32[] memory proof,
        address user,
        uint256 amount
    )
        external
        onlyMaintainer
    {
        require(
            farmAddress != address(0),
            "farmAddress address can not be 0x0"
        );

        IMerkleFarm farm;
        farm = IMerkleFarm(farmAddress);
        farm.removeUser(proof, user, amount);
    }

    /******************************************** General functions *******************************************/

    /**
     * @notice function deActivate farm
     *
     * @param farmAddress - function will operate on
     * farm with this address
     *
     * @param farmAddress - address of farm
     */
    function pauseSpecificFarm(
        address farmAddress
    )
        external
        onlyMaintainer
    {
        require(
            farmAddress != address(0x0),
            "Farm address can not be 0x0 address"
        );

        IVestingFarm farm;
        farm = IVestingFarm(farmAddress);
        farm.pauseFarm();
    }

    /**
     * @notice function set new start time for a vesting farm
     *
     * @param farmAddress - function will operate on
     * farm with this address
     * @param startTime - the new start time
     */
    function setStartTimeOnSpecificFarm(
        address farmAddress,
        uint256 startTime
    )
        external
        onlyMaintainer
    {
        require(
            farmAddress != address(0x0),
            "Farm address can not be 0x0 address"
        );

        IVestingFarm farm;
        farm = IVestingFarm(farmAddress);
        farm.setStartTime(startTime);
    }

    /**
     * @notice function funds again the farm if necessary
     *
     * @param farmAddress - function will operate
     * on farm with this address
     * @param rewardToken - address of reward token
     * @param amount - funding the farm with this amount of tokens
     */
    function fundAndOrActivateSpecificVestingFarm(
        address farmAddress,
        address rewardToken,
        uint256 amount
    )
        external
        onlyTokensFarmCongress
    {
        require(
            _sufficientFunds(rewardToken, amount),
            "There is not enough tokens left in factory to fund"
        );

        _fundInternalVestingFarm(farmAddress, rewardToken, amount);
    }

    /**
     * @notice function withdraws remaining funds left on farm
     *
     * @param farmAddress - function will operate on
     * farm with this address
     * @param collector - address of beneficiary
     */
    function withdrawLeftOverTokensOnSpecificVestingFarm(
        address farmAddress,
        address collector
    )
        external
        onlyTokensFarmCongress
    {
        require(
            farmAddress != address(0x0),
            "Farm's address can't be 0x0 address"
        );
        require(
            collector != address(0x0),
            "Collectors address can't be 0x0 address"
        );

        IVestingFarm farm;
        farm = IVestingFarm(farmAddress);
        farm.removeLeftOverRewards(collector);
    }

    /**
     * @notice function withdraws vesting farm,
     * whole balance of farm on factory
     *
     * @param farmAddress - function will operate on
     * farm with this address
     * @param _vestedToken - address of vesting token
     */
    function emergencyAssetsWithdrawalOnSpecificVestingFarm(
        address farmAddress,
        address _vestedToken
    )
        external
        onlyTokensFarmCongress
    {
        require(
            farmAddress != address(0x0),
            "Farm's address can't be 0x0 address"
        );
        require(
            _vestedToken != address(0x0),
            "Tokens address can't be 0x0 address"
        );

        IVestingFarm farm;
        farm = IVestingFarm(farmAddress);
        farm.emergencyAssetsWithdrawal(_vestedToken, feeCollector);
    }

    /***************************************** Factory related functions **********************************************/

    /**
     * @notice function is withdrawing tokens if they are stuck
     *
     * @param erc20 - address of token
     * @param amount - amount that needs to be withdrawn
     * @param beneficiary - address where all of the tokens should go
     */
    function withdrawStuckTokensFromFactory(
        address erc20,
        uint256 amount,
        address beneficiary
    )
        external
        onlyTokensFarmCongress
    {
        require(
            erc20 != address(0x0),
            "Token address can not be 0x0 address"
        );
        require(
            amount >= 0,
            "Amount needs to be over or equal to 0"
        );
        require(
            beneficiary != address(0x0),
            "Beneficiary address can not be 0x0 address"
        );

        IERC20 token = IERC20(erc20);
        token.safeTransfer(beneficiary, amount);
    }

    /**
     * @notice function is setting all implementations at once
     *
     * @param _linearFarmImplementation - address linear implementation
     * @param _iterativeFarmImplementation - address iterative implementation
     * @param _merkleLinearFarmImplementation - address merkle linear implementation
     * @param _merkleIterativeFarmImplementation - address merkle iterative implementation
     */
    function setAllImplementationAtOnce(
        address _linearFarmImplementation,
        address _iterativeFarmImplementation,
        address _merkleLinearFarmImplementation,
        address _merkleIterativeFarmImplementation
    )
        external
        onlyTokensFarmCongress
    {
        require(
            _linearFarmImplementation != address(0x0),
            "Linear implementation can not be 0x0 address"
        );
        require(
            _iterativeFarmImplementation != address(0x0),
            "Iterative implementation can not be 0x0 address"
        );
        require(
            _merkleLinearFarmImplementation != address(0x0),
            "Merkle Linear implementation can not be 0x0 address"
        );
        require(
            _merkleIterativeFarmImplementation != address(0x0),
            "Merkle Iterative implementation can not be 0x0 address"
        );

        //add farms implementations to mapping
        farmImplementations[FarmTypes.LINEAR] = _linearFarmImplementation;
        farmImplementations[FarmTypes.ITERATIVE] = _iterativeFarmImplementation;
        farmImplementations[FarmTypes.MERKLE_LINEAR] = _merkleLinearFarmImplementation;
        farmImplementations[FarmTypes.MERKLE_ITERATIVE] = _merkleIterativeFarmImplementation;

        emit AllImplementationSet(
            farmImplementations[FarmTypes.LINEAR],
            farmImplementations[FarmTypes.ITERATIVE],
            farmImplementations[FarmTypes.MERKLE_LINEAR],
            farmImplementations[FarmTypes.MERKLE_ITERATIVE]
        );
    }

    /**
     * @notice function is setting address of deployed
     * farm contract
     *
     * @param  _farmIndex - index of the enum type of the farm
     * @param  _farmAddress - farm address
     * address of new farm contract
     */
    function setFarmImplementation(
        uint256 _farmIndex,
        address _farmAddress
    )
        external
        onlyTokensFarmCongress
    {
        require(
            _farmAddress != address(0),
            "farmImplementation can not be 0x0 address"
        );
        require(
            isEnumInRange(_farmIndex),
            "Farm index is out of range"
        );

        FarmTypes farmType = FarmTypes(_farmIndex);
        farmImplementations[farmType] = _farmAddress;

        emit FarmImplementationSet(
            _farmIndex,
            _farmAddress
        );
    }

    /**
     * @notice function is changing address to new proxy admin
     *
     * @param _proxyAdmin - the new proxyAdmin address
     */
    function setProxyAdmin(
        address _proxyAdmin
    )
        external
        onlyTokensFarmCongress
    {
        require(
            _proxyAdmin != address(0),
            "Admin address can not be 0x0"
        );

        proxyAdmin = _proxyAdmin;
        emit SetProxyAdmin(proxyAdmin);
    }

    /**
     * @notice function is setting new address of fee collector
     *
     * @param  _feeCollector - address of new fee collector
     */
    function setFeeCollector(
        address payable _feeCollector
    )
        external
        onlyTokensFarmCongress
    {
        require(
            _feeCollector != address(0),
            "Fee Collector can not be 0x0 address"
        );

        feeCollector = _feeCollector;
        emit FeeCollectorSet(feeCollector);
    }

    /**
     * @notice function returns address of last deployed farm
     *
     * @dev can be used on BE as additional checksum next to event emitted in tx
     *
     * @param _farmIndex - enum index of type
     *
     * @return address of last deployed farm
     */
    function getLastDeployedFarm(
        uint256 _farmIndex
    )
        external
        view
        returns (address)
    {
        require(
            isEnumInRange(_farmIndex),
            "Farm index is out of range"
        );

        address[] memory deployedFarms = _getFarmArray(_farmIndex);
        if (deployedFarms.length == 0) {
            // Means no farms deployed yet.
            return address(0);
        }
        // Deployed last deployed farm.
        return
            deployedFarms[deployedFarms.length - 1];
    }

    /**
     * @notice function returns array,
     * of deployed farms(from start to end)
     *
     * @param farmIndex - enum index of type
     * @param start - beginning index of array
     * @param end - ending index of array
     *
     * @return array made of address of deployed tokens farm
     */
    function getDeployedFarms(
        uint256 farmIndex,
        uint256 start,
        uint256 end
    )
        external
        view
        returns (address[] memory)
    {
        require(start < end, "Start should be less than end");
        require(
            isEnumInRange(farmIndex),
            "Farm index is out of range"
        );

        address[] memory deployedFarms = _getFarmArray(farmIndex);

        require(
            start >= 0 && end <= deployedFarms.length,
            "One of the index is out of range"
        );

        address[] memory tokensFarms = new address[](end - start);
        uint256 counter;

        for (uint256 i = start; i < end; i++) {
            tokensFarms[counter] = deployedFarms[i];
            counter++;
        }

        return tokensFarms;
    }
}