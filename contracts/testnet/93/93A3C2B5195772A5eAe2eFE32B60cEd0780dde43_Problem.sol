// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Create2.sol)

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {IProblemV2} from "../interfaces/IProblemV2.sol";
import {ISolution} from "../interfaces/ISolution.sol";
import {IChecker} from "../interfaces/IChecker.sol";
import {IUserGateFactory} from "../interfaces/IUserGateFactory.sol";
import {IGate} from "../interfaces/IGate.sol";
import {TestManager, TestCase, Verdict} from "./TestManager.sol";
import {ExcessivelySafeCall} from "../libraries/ExcessivelySafeCall.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Create2.sol";

contract Problem is IProblemV2, TestManager {
    uint16 public constant MAX_OUTPUT_SIZE = 1500;

    uint256 public id;
    address public checker;
    address public gateFactory;

    uint256 public deadline;

    mapping(address => ContestantData) public contestants;

    uint256 nonce;

    modifier ensureDeadline(bool isBeforeDeadline) {
        if (isBeforeDeadline) {
            require(block.timestamp <= deadline, "only before deadline");
        } else {
            require(block.timestamp > deadline, "only after deadline");
        }
        _;
    }

    function initialize(
        uint256 _id,
        address _author,
        address _checker,
        address _gateFactory
    ) external initializer {
        id = _id;
        checker = _checker;
        gateFactory = _gateFactory;
        _TestManagerInit(_author);
    }

    function setDeadline(uint256 _deadline) external onlyAuthor {
        deadline = _deadline;
        emit DeadlineUpdated(deadline);
    }

    function getContestantInfo(
        address contestant
    )
        public
        view
        returns (
            bytes32 solutionHash,
            address solutionPreDeadline,
            address solutionPosDeadline,
            uint24 pointPreDeadline,
            uint24 pointPosDeadline
        )
    {
        ContestantData memory data = contestants[contestant];
        solutionHash = data.solutionHash;
        solutionPreDeadline = data.solutionPreDeadline;
        solutionPosDeadline = data.solutionPosDeadline;
        pointPreDeadline = data.pointPreDeadline;
        pointPosDeadline = data.pointPosDeadline;
    }

    function declareSolutionHash(
        bytes32 solutionHash
    ) external ensureDeadline(true) {
        address user = msg.sender;
        contestants[user].solutionHash = solutionHash;
        emit DeclareSolutionHash(user, solutionHash);
    }

    function submit(
        address user,
        bool isPreDeadlineSolution,
        bytes memory solutionBytecode
    ) public {
        nonce++;
        address solutionAddr = Create2.deploy(
            0,
            keccak256(abi.encode(user)) ^ keccak256(abi.encode(nonce)),
            solutionBytecode
        );

        if (isPreDeadlineSolution) {
            contestants[user].solutionPreDeadline = solutionAddr;
            bytes32 solutionHash = keccak256(solutionBytecode);
            require(
                solutionHash == contestants[user].solutionHash,
                "invalid solution hash"
            );
        } else {
            contestants[user].solutionPosDeadline = solutionAddr;
        }

        emit UpdateSolution(user, isPreDeadlineSolution, solutionAddr);
    }

    function runSolution(address contestant, bool isBeforeDeadline) public {
        if (isBeforeDeadline) {
            _runSolution(
                contestant,
                true,
                contestants[contestant].solutionPreDeadline
            );
        } else {
            _runSolution(
                contestant,
                false,
                contestants[contestant].solutionPosDeadline
            );
        }
    }

    function submitAndRunSolution(
        address user,
        bool isPreDeadlineSolution,
        bytes memory solutionBytecode
    ) external {
        submit(user, isPreDeadlineSolution, solutionBytecode);
        runSolution(user, isPreDeadlineSolution);
    }

    function _runSolution(
        address contestant,
        bool isPreDeadlineSolution,
        address solutionAddr
    ) internal {
        uint256 cntCorrect = 0;
        uint256 nTest = testLength;
        Verdict[] memory allVerdicts = new Verdict[](nTest);

        for (uint256 i = 0; i < nTest; ++i) {
            TestCase memory test = tests[i];
            (bool success, bytes memory output) = _runTest(solutionAddr, test);

            if (success) {
                allVerdicts[i] = IChecker(checker).checkOutput(test, output);
            } else {
                allVerdicts[i] = Verdict.REVERTED;
            }

            if (allVerdicts[i] == Verdict.ACCEPTED) {
                ++cntCorrect;
            }
        }

        ContestantData storage data = contestants[contestant];

        uint24 point = uint24((cntCorrect * 10000) / nTest);

        if (isPreDeadlineSolution) {
            data.pointPreDeadline = point;
        } else {
            data.pointPosDeadline = point;
        }

        emit RunSolution(contestant, point, isPreDeadlineSolution, allVerdicts);
    }

    function _runTest(
        address solution,
        TestCase memory test
    ) internal returns (bool success, bytes memory result) {
        (success, result) = ExcessivelySafeCall.excessivelySafeCall(
            solution,
            (test.gasLimit * 101) / 100, // 1% buffer
            MAX_OUTPUT_SIZE,
            abi.encodeWithSelector(ISolution.execute.selector, test.input)
        );

        if (success) {
            result = abi.decode(result, (bytes));
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;
import {TestCase, Verdict} from "../libraries/Tests.sol";
import {ITestManager} from "../interfaces/ITestManager.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

abstract contract TestManager is Initializable, ITestManager {
    address public author;
    uint256 public testLength;
    uint256 public testVersion;
    mapping(uint256 => TestCase) public tests;

    modifier onlyAuthor() {
        require(msg.sender == author, "msg.sender not author");
        _;
    }

    modifier modifyTest() {
        ++testVersion;
        _;
        emit NewTestVersion(testVersion, _getTestArray());
    }

    function _TestManagerInit(address _author) internal onlyInitializing {
        author = _author;
    }

    function replaceTests(
        TestCase[] calldata newTests
    ) external onlyAuthor modifyTest {
        for (uint256 i = 0; i < newTests.length; ++i) {
            tests[i] = newTests[i];
        }
        testLength = newTests.length;
    }

    function addTest(TestCase calldata test) external onlyAuthor modifyTest {
        tests[testLength++] = test;
    }

    function _getTestArray()
        private
        view
        returns (TestCase[] memory testArray)
    {
        testArray = new TestCase[](testLength);
        for (uint256 i = 0; i < testArray.length; ++i) {
            testArray[i] = tests[i];
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {TestCase, Verdict} from "../libraries/Tests.sol";

interface IChecker {
    function checkOutput(
        TestCase memory test,
        bytes memory contestantOutput
    ) external pure returns (Verdict);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

interface IGate {
    event Deployment(uint256 id, address solution);

    function user() external view returns (address);

    function username() external view returns (string memory username);

    function deployAndRun(
        bytes memory bytecode,
        bytes memory input
    ) external returns (bytes memory output, uint256 gasUsed);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Verdict} from "../libraries/Tests.sol";

interface IProblemV2 {
    struct ContestantData {
        bytes32 solutionHash;
        address solutionPreDeadline;
        address solutionPosDeadline;
        uint24 pointPreDeadline;
        uint24 pointPosDeadline;
    }

    event RunSolution(
        address contestant,
        uint256 point,
        bool isPreDeadlineSolution,
        Verdict[] verdicts
    );

    event UpdateSolution(
        address contestant,
        bool isPreDeadlineSolution,
        address solution
    );

    event DeclareSolutionHash(address contestant, bytes32 solutionHash);

    event DeadlineUpdated(uint256 deadline);

    function getContestantInfo(
        address contestant
    )
        external
        view
        returns (
            bytes32 solutionHash,
            address solutionPreDeadline,
            address solutionPosDeadline,
            uint24 pointPreDeadline,
            uint24 pointPosDeadline
        );

    function declareSolutionHash(bytes32 solutionHash) external;

    function submit(
        address user,
        bool isPreDeadlineSolution,
        bytes memory solutionBytecode
    ) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

interface ISolution {
    function execute(bytes memory input) external returns (bytes memory output);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {TestCase} from "../libraries/Tests.sol";

interface ITestManager {
    event NewTestVersion(uint256 version, TestCase[] tests);

    function replaceTests(TestCase[] calldata newTests) external;

    function addTest(TestCase calldata test) external;
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

interface IUserGateFactory {
    event CreateGate(address user, string username, address gate);

    function gates(address user) external view returns (address);

    function createGate(string memory username) external returns (address gate);
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

library ExcessivelySafeCall {
    uint256 constant LOW_28_MASK =
        0x00000000ffffffffffffffffffffffffffffffffffffffffffffffffffffffff;

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := call(
                _gas, // gas
                _target, // recipient
                0, // ether value
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /// @notice Use when you _really_ really _really_ don't trust the called
    /// contract. This prevents the called contract from causing reversion of
    /// the caller in as many ways as we can.
    /// @dev The main difference between this and a solidity low-level call is
    /// that we limit the number of bytes that the callee can cause to be
    /// copied to caller memory. This prevents stupid things like malicious
    /// contracts returning 10,000,000 bytes causing a local OOG when copying
    /// to memory.
    /// @param _target The address to call
    /// @param _gas The amount of gas to forward to the remote contract
    /// @param _maxCopy The maximum number of bytes of returndata to copy
    /// to memory.
    /// @param _calldata The data to send to the remote contract
    /// @return success and returndata, as `.call()`. Returndata is capped to
    /// `_maxCopy` bytes.
    function excessivelySafeStaticCall(
        address _target,
        uint256 _gas,
        uint16 _maxCopy,
        bytes memory _calldata
    ) internal view returns (bool, bytes memory) {
        // set up for assembly call
        uint256 _toCopy;
        bool _success;
        bytes memory _returnData = new bytes(_maxCopy);
        // dispatch message to recipient
        // by assembly calling "handle" function
        // we call via assembly to avoid memcopying a very large returndata
        // returned by a malicious contract
        assembly {
            _success := staticcall(
                _gas, // gas
                _target, // recipient
                add(_calldata, 0x20), // inloc
                mload(_calldata), // inlen
                0, // outloc
                0 // outlen
            )
            // limit our copy to 256 bytes
            _toCopy := returndatasize()
            if gt(_toCopy, _maxCopy) {
                _toCopy := _maxCopy
            }
            // Store the length of the copied bytes
            mstore(_returnData, _toCopy)
            // copy the bytes from returndata[0:_toCopy]
            returndatacopy(add(_returnData, 0x20), 0, _toCopy)
        }
        return (_success, _returnData);
    }

    /**
     * @notice Swaps function selectors in encoded contract calls
     * @dev Allows reuse of encoded calldata for functions with identical
     * argument types but different names. It simply swaps out the first 4 bytes
     * for the new selector. This function modifies memory in place, and should
     * only be used with caution.
     * @param _newSelector The new 4-byte selector
     * @param _buf The encoded contract args
     */
    function swapSelector(
        bytes4 _newSelector,
        bytes memory _buf
    ) internal pure {
        require(_buf.length >= 4);
        uint256 _mask = LOW_28_MASK;
        assembly {
            // load the first word of
            let _word := mload(add(_buf, 0x20))
            // mask out the top 4 bytes
            // /x
            _word := and(_word, _mask)
            _word := or(_newSelector, _word)
            mstore(add(_buf, 0x20), _word)
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

enum Verdict {
    ACCEPTED,
    WRONG_ANSWER,
    REVERTED
}

struct TestCase {
    bytes input;
    bytes32 output;
    uint224 gasLimit;
}