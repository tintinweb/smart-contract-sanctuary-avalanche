// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { Address } from "@openzeppelin/utils/Address.sol";

import { FactoryStoreLib } from "src/libraries/FactoryStore.sol";
import { Constants } from "src/Constants.sol";

import { OracleCaller } from "src/oracle/OracleCaller.sol";
import { GenericFactory } from "src/GenericFactory.sol";

contract ReservoirDeployer {
    using FactoryStoreLib for GenericFactory;

    // Steps.
    uint256 public constant TERMINAL_STEP = 4;
    uint256 public step = 0;

    // Bytecode hashes.
    bytes32 public constant FACTORY_HASH = bytes32(0xda6f297f6ce8cf60c5dcf260b6c4178f82c853ae2f16446c064cf6f4e2e4b1ca);
    bytes32 public constant CONSTANT_PRODUCT_HASH =
        bytes32(0xde6d8452b97c785350ce9f82090dfb5962933aa5467827310798925c8725013b);
    bytes32 public constant STABLE_HASH = bytes32(0x1289a8879d4d1992d308d2a4d8457a5ca8d57e07effe092f2a1f21b0b9b10619);
    bytes32 public constant ORACLE_CALLER_HASH =
        bytes32(0x1dcb29ca6399be1a5f8a4b3f168a83ff20697718c3d5434ddeeb4a8050fdc615);

    // Deployment addresses.
    GenericFactory public factory;
    OracleCaller public oracleCaller;

    constructor(address aGuardian1, address aGuardian2, address aGuardian3) {
        require(
            aGuardian1 != address(0) && aGuardian2 != address(0) && aGuardian3 != address(0),
            "DEPLOYER: GUARDIAN_ADDRESS_ZERO"
        );
        guardian1 = aGuardian1;
        guardian2 = aGuardian2;
        guardian3 = aGuardian3;
    }

    function isDone() external view returns (bool) {
        return step == TERMINAL_STEP;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            DEPLOYMENT STEPS
    //////////////////////////////////////////////////////////////////////////*/

    function deployFactory(bytes memory aFactoryBytecode) external returns (GenericFactory) {
        require(step == 0, "FAC_STEP: OUT_OF_ORDER");
        require(keccak256(aFactoryBytecode) == FACTORY_HASH, "DEPLOYER: FACTORY_HASH");

        // Manual deployment from validated bytecode.
        address lFactoryAddress;
        assembly ("memory-safe") {
            lFactoryAddress :=
                create(
                    0, // value
                    add(aFactoryBytecode, 0x20), // offset
                    mload(aFactoryBytecode) // size
                )
        }
        require(lFactoryAddress != address(0), "FAC_STEP: DEPLOYMENT_FAILED");

        // Write the factory address so we can start configuring it.
        factory = GenericFactory(lFactoryAddress);

        // Set global parameters.
        factory.write("Shared::platformFee", Constants.DEFAULT_PLATFORM_FEE);
        factory.write("Shared::platformFeeTo", address(this));
        factory.write("Shared::recoverer", address(this));
        factory.write("Shared::maxChangeRate", Constants.DEFAULT_MAX_CHANGE_RATE);

        // Step complete.
        step += 1;

        return factory;
    }

    function deployConstantProduct(bytes memory aConstantProductBytecode) external {
        require(step == 1, "CP_STEP: OUT_OF_ORDER");
        require(keccak256(aConstantProductBytecode) == CONSTANT_PRODUCT_HASH, "DEPLOYER: CP_HASH");

        // Add curve & curve specific parameters.
        factory.addCurve(aConstantProductBytecode);
        factory.write("CP::swapFee", Constants.DEFAULT_SWAP_FEE_CP);

        // Step complete.
        step += 1;
    }

    function deployStable(bytes memory aStableBytecode) external {
        require(step == 2, "SP_STEP: OUT_OF_ORDER");
        require(keccak256(aStableBytecode) == STABLE_HASH, "DEPLOYER: STABLE_HASH");

        // Add curve & curve specific parameters.
        factory.addCurve(aStableBytecode);
        factory.write("SP::swapFee", Constants.DEFAULT_SWAP_FEE_SP);
        factory.write("SP::amplificationCoefficient", Constants.DEFAULT_AMP_COEFF);

        // Step complete.
        step += 1;
    }

    function deployOracleCaller(bytes memory aOracleCallerBytecode) external returns (OracleCaller) {
        require(step == 3, "OC_STEP: OUT_OF_ORDER");
        require(keccak256(aOracleCallerBytecode) == ORACLE_CALLER_HASH, "DEPLOYER: OC_HASH");

        // Manual deployment from validated bytecode.
        address lOracleCallerAddress;
        assembly ("memory-safe") {
            lOracleCallerAddress :=
                create(
                    0, // value
                    add(aOracleCallerBytecode, 0x20), // offset
                    mload(aOracleCallerBytecode) // size
                )
        }
        require(lOracleCallerAddress != address(0), "OC_STEP: DEPLOYMENT_FAILED");

        factory.write("Shared::oracleCaller", lOracleCallerAddress);

        // Step complete.
        oracleCaller = OracleCaller(lOracleCallerAddress);
        step += 1;

        return oracleCaller;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            OWNERSHIP CLAIM
    //////////////////////////////////////////////////////////////////////////*/

    uint256 public constant GUARDIAN_THRESHOLD = 2;

    address public immutable guardian1;
    address public immutable guardian2;
    address public immutable guardian3;

    mapping(address => mapping(address => uint256)) public proposals;

    function proposeOwner(address aOwner) external {
        proposals[msg.sender][aOwner] = 1;
    }

    function clearProposedOwner(address aOwner) external {
        proposals[msg.sender][aOwner] = 0;
    }

    function claimOwnership() external {
        uint256 lGuardian1Support = proposals[guardian1][msg.sender];
        uint256 lGuardian2Support = proposals[guardian2][msg.sender];
        uint256 lGuardian3Support = proposals[guardian3][msg.sender];

        uint256 lSupport = lGuardian1Support + lGuardian2Support + lGuardian3Support;
        require(lSupport >= GUARDIAN_THRESHOLD, "DEPLOYER: THRESHOLD");

        owner = msg.sender;
    }

    /*//////////////////////////////////////////////////////////////////////////
                            OWNER ACTIONS
    //////////////////////////////////////////////////////////////////////////*/

    address public owner = address(0);

    modifier onlyOwner() {
        require(msg.sender == owner, "DEPLOYER: NOT_OWNER");
        _;
    }

    function claimFactory() external onlyOwner {
        factory.transferOwnership(msg.sender);
    }

    function claimOracleCaller() external onlyOwner {
        oracleCaller.transferOwnership(msg.sender);
    }

    function rawCall(address aTarget, bytes calldata aCalldata, uint256 aValue)
        external
        onlyOwner
        returns (bytes memory)
    {
        return Address.functionCallWithValue(aTarget, aCalldata, aValue, "DEPLOYER: RAW_CALL_REVERTED");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IGenericFactory } from "src/interfaces/IGenericFactory.sol";
import { Bytes32Lib } from "src/libraries/Bytes32.sol";

library FactoryStoreLib {
    using Bytes32Lib for bool;
    using Bytes32Lib for uint256;
    using Bytes32Lib for int256;
    using Bytes32Lib for address;

    function read(IGenericFactory aFactory, string memory aKey) internal view returns (bytes32) {
        return aFactory.get(keccak256(abi.encodePacked(aKey)));
    }

    function write(IGenericFactory aFactory, string memory aKey, bool aValue) internal {
        aFactory.set(keccak256(abi.encodePacked(aKey)), aValue.toBytes32());
    }

    function write(IGenericFactory aFactory, string memory aKey, uint256 aValue) internal {
        aFactory.set(keccak256(abi.encodePacked(aKey)), aValue.toBytes32());
    }

    function write(IGenericFactory aFactory, string memory aKey, int256 aValue) internal {
        aFactory.set(keccak256(abi.encodePacked(aKey)), aValue.toBytes32());
    }

    function write(IGenericFactory aFactory, string memory aKey, address aValue) internal {
        aFactory.set(keccak256(abi.encodePacked(aKey)), aValue.toBytes32());
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library Constants {
    uint256 public constant INITIAL_MINT_AMOUNT = 100e18;
    uint256 public constant DEFAULT_SWAP_FEE_CP = 3000; // 0.3%
    uint256 public constant DEFAULT_SWAP_FEE_SP = 100; // 0.01%
    uint256 public constant DEFAULT_PLATFORM_FEE = 250_000; // 25%
    uint256 public constant DEFAULT_AMP_COEFF = 1000;
    uint256 public constant DEFAULT_MAX_CHANGE_RATE = 0.0005e18;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { Owned } from "solmate/auth/Owned.sol";

import { Observation, ReservoirPair } from "src/ReservoirPair.sol";

contract OracleCaller is Owned(msg.sender) {
    event WhitelistChanged(address caller, bool whitelist);

    mapping(address => bool) public whitelist;

    function observation(ReservoirPair aPair, uint256 aIndex) external view returns (Observation memory rObservation) {
        require(whitelist[msg.sender], "OC: NOT_WHITELISTED");
        rObservation = aPair.observation(aIndex);
    }

    function whitelistAddress(address aCaller, bool aWhitelist) external onlyOwner {
        whitelist[aCaller] = aWhitelist;
        emit WhitelistChanged(aCaller, aWhitelist);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { Math } from "@openzeppelin/utils/math/Math.sol";
import { Address } from "@openzeppelin/utils/Address.sol";
import { SSTORE2 } from "solady/utils/SSTORE2.sol";
import { Owned } from "solmate/auth/Owned.sol";

import { Bytes32Lib } from "src/libraries/Bytes32.sol";

import { IGenericFactory, IERC20 } from "src/interfaces/IGenericFactory.sol";
import { StableMintBurn } from "src/curve/stable/StableMintBurn.sol";

uint256 constant MAX_SSTORE_SIZE = 0x6000 - 1;

contract GenericFactory is IGenericFactory, Owned {
    using Bytes32Lib for address;

    StableMintBurn public immutable stableMintBurn;

    constructor() Owned(msg.sender) {
        stableMintBurn = new StableMintBurn{salt: bytes32(0)}();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CONFIG
    //////////////////////////////////////////////////////////////////////////*/

    mapping(bytes32 => bytes32) public get;

    function set(bytes32 aKey, bytes32 aValue) public onlyOwner {
        get[aKey] = aValue;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    BYTECODES
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Mapping storing the bytecodes (as chunked pointers) this factory
    ///         can deploy.
    mapping(bytes32 => address[]) private _getByteCode;

    function _writeBytecode(bytes32 aCodeKey, bytes calldata aInitCode) internal {
        uint256 lChunk = 0;
        uint256 lInitCodePointer = 0;
        while (lInitCodePointer < aInitCode.length) {
            // Cut the initCode into chunks at most 24kb (EIP-170). The stored
            // data is prefixed with STOP, so we must store 1 less than max.
            uint256 lChunkEnd = Math.min(aInitCode.length, lInitCodePointer + MAX_SSTORE_SIZE);

            _getByteCode[aCodeKey].push(SSTORE2.write(aInitCode[lInitCodePointer:lChunkEnd]));

            lChunk += 1;
            lInitCodePointer = lChunkEnd;
        }
    }

    function getBytecode(bytes32 aCodeKey, IERC20 aToken0, IERC20 aToken1) public view returns (bytes memory) {
        address[] memory lByteCode = _getByteCode[aCodeKey];
        uint256 lByteCodeChunks = lByteCode.length;

        bytes memory lInitCode;
        // SAFETY:
        // This block updates the memory pointer before returning to solidity.
        assembly ("memory-safe") {
            lInitCode := mload(0x40)

            let free_mem := add(lInitCode, 0x20)
            for { let i := 0 } lt(i, lByteCodeChunks) { i := add(i, 1) } {
                // Load lByteCode[i] using yul.
                let offset := mul(i, 0x20)
                let chunk_addr := mload(add(add(lByteCode, offset), 0x20))

                // size = lByteCode[i].code.length - 1;
                let size := sub(extcodesize(chunk_addr), 0x01)

                // Copy the external code (skipping the first byte which is a
                // STOP instruction). Then update the stack free_mem pointer to
                // the new HEAD of memory.
                extcodecopy(chunk_addr, free_mem, 0x01, size)
                free_mem := add(free_mem, size)
            }

            // Store the two tokens as cstr args.
            mstore(free_mem, aToken0)
            mstore(add(free_mem, 0x20), aToken1)

            // Write initCode length and update free mem. Note that we are using
            // the difference between free_mem (stack) and mem pointer (memory)
            // to know how much memory we just wrote and thus the size of the
            // bytecode.
            mstore(lInitCode, add(sub(free_mem, mload(0x40)), 0x40))
            mstore(0x40, add(free_mem, 0x40))
        }

        return lInitCode;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    CURVES
    //////////////////////////////////////////////////////////////////////////*/

    bytes32[] public _curves;

    function curves() external view returns (bytes32[] memory) {
        return _curves;
    }

    function addCurve(bytes calldata aInitCode) external onlyOwner returns (uint256 rCurveId, bytes32 rCodeKey) {
        rCurveId = _curves.length;
        rCodeKey = keccak256(aInitCode);
        _curves.push(rCodeKey);

        _writeBytecode(rCodeKey, aInitCode);
    }

    function _loadCurve(uint256 aCurveId, IERC20 aToken0, IERC20 aToken1) private view returns (bytes memory) {
        bytes32 lCodeKey = _curves[aCurveId];

        return getBytecode(lCodeKey, aToken0, aToken1);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    PAIRS
    //////////////////////////////////////////////////////////////////////////*/

    event Pair(IERC20 indexed token0, IERC20 indexed token1, uint256 curveId, address pair);

    /// @notice maps tokenA, tokenB addresses, and curveId, to pair address, where the order of tokenA and tokenB does not matter
    mapping(IERC20 => mapping(IERC20 => mapping(uint256 => address))) public getPair;
    address[] private _allPairs;

    function allPairs() external view returns (address[] memory) {
        return _allPairs;
    }

    function _sortAddresses(IERC20 a, IERC20 b) private pure returns (IERC20 r0, IERC20 r1) {
        (r0, r1) = a < b ? (a, b) : (b, a);
    }

    function createPair(IERC20 aTokenA, IERC20 aTokenB, uint256 aCurveId) external returns (address rPair) {
        require(aTokenA != aTokenB, "FACTORY: IDENTICAL_ADDRESSES");
        require(address(aTokenA) != address(0), "FACTORY: ZERO_ADDRESS");
        require(getPair[aTokenA][aTokenB][aCurveId] == address(0), "FACTORY: PAIR_EXISTS");

        (IERC20 lToken0, IERC20 lToken1) = _sortAddresses(aTokenA, aTokenB);

        bytes memory lInitCode = _loadCurve(aCurveId, lToken0, lToken1);

        // SAFETY:
        // Does not write to memory
        assembly ("memory-safe") {
            // Create2 the pair, uniqueness guaranteed by args.
            rPair :=
                create2(
                    0, // value
                    add(lInitCode, 0x20), // offset - skip first word, which is just the length
                    mload(lInitCode), // size
                    0 // salt
                )
        }
        require(rPair != address(0), "FACTORY: DEPLOY_FAILED");

        // Double-map the newly created pair for reverse lookup.
        getPair[lToken0][lToken1][aCurveId] = rPair;
        getPair[lToken1][lToken0][aCurveId] = rPair;
        _allPairs.push(rPair);

        emit Pair(lToken0, lToken1, aCurveId, rPair);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                    EXECUTE
    //////////////////////////////////////////////////////////////////////////*/

    function rawCall(address aTarget, bytes calldata aCalldata, uint256 aValue)
        external
        onlyOwner
        returns (bytes memory)
    {
        return Address.functionCallWithValue(aTarget, aCalldata, aValue, "FACTORY: RAW_CALL_REVERTED");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { StableMintBurn } from "src/curve/stable/StableMintBurn.sol";

interface IGenericFactory {
    function stableMintBurn() external view returns (StableMintBurn);

    function get(bytes32 key) external view returns (bytes32 value);
    function set(bytes32 key, bytes32 value) external;

    function addCurve(bytes calldata initCode) external returns (uint256 curveId, bytes32 codeKey);

    function allPairs() external view returns (address[] memory);
    function getPair(IERC20 tokenA, IERC20 tokenB, uint256 curveId) external view returns (address);
    function createPair(IERC20 tokenA, IERC20 tokenB, uint256 curveId) external returns (address);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

library Bytes32Lib {
    function toBytes32(bool aValue) internal pure returns (bytes32) {
        return aValue ? bytes32(uint256(1)) : bytes32(uint256(0));
    }

    function toBytes32(uint256 aValue) internal pure returns (bytes32) {
        return bytes32(aValue);
    }

    function toBytes32(int256 aValue) internal pure returns (bytes32) {
        return bytes32(uint256(aValue));
    }

    function toBytes32(address aValue) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(aValue)));
    }

    function toBool(bytes32 aValue) internal pure returns (bool) {
        return uint256(aValue) % 2 == 1;
    }

    function toUint64(bytes32 aValue) internal pure returns (uint64) {
        return uint64(uint256(aValue));
    }

    function toUint256(bytes32 aValue) internal pure returns (uint256) {
        return uint256(aValue);
    }

    function toInt256(bytes32 aValue) internal pure returns (int256) {
        return int256(uint256(aValue));
    }

    function toAddress(bytes32 aValue) internal pure returns (address) {
        return address(uint160(uint256(aValue)));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { SafeCast } from "@openzeppelin/utils/math/SafeCast.sol";
import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

import { StdMath } from "src/libraries/StdMath.sol";
import { FactoryStoreLib } from "src/libraries/FactoryStore.sol";
import { Bytes32Lib } from "src/libraries/Bytes32.sol";
import { LogCompression } from "src/libraries/LogCompression.sol";

import { IAssetManager, IERC20 } from "src/interfaces/IAssetManager.sol";
import { IAssetManagedPair } from "src/interfaces/IAssetManagedPair.sol";
import { IGenericFactory } from "src/interfaces/IGenericFactory.sol";

import { Observation } from "src/structs/Observation.sol";
import { Slot0 } from "src/structs/Slot0.sol";
import { ReservoirERC20 } from "src/ReservoirERC20.sol";

abstract contract ReservoirPair is IAssetManagedPair, ReservoirERC20 {
    using FactoryStoreLib for IGenericFactory;
    using Bytes32Lib for bytes32;
    using SafeCast for uint256;
    using SafeTransferLib for address;
    using StdMath for uint256;
    using FixedPointMathLib for uint256;

    uint256 public constant MINIMUM_LIQUIDITY = 1e3;
    uint256 public constant FEE_ACCURACY = 1_000_000; // 100%

    IGenericFactory public immutable factory;

    modifier onlyFactory() {
        require(msg.sender == address(factory), "RP: FORBIDDEN");
        _;
    }

    constructor(IERC20 aToken0, IERC20 aToken1, string memory aSwapFeeName, bool aNotStableMintBurn) {
        factory = IGenericFactory(msg.sender);
        _token0 = aToken0;
        _token1 = aToken1;

        _token0PrecisionMultiplier = aNotStableMintBurn ? uint128(10) ** (18 - aToken0.decimals()) : 0;
        _token1PrecisionMultiplier = aNotStableMintBurn ? uint128(10) ** (18 - aToken1.decimals()) : 0;
        swapFeeName = keccak256(bytes(aSwapFeeName));

        if (aNotStableMintBurn) {
            updateSwapFee();
            updatePlatformFee();
            updateOracleCaller();
            setMaxChangeRate(factory.read(MAX_CHANGE_RATE_NAME).toUint256());
        }
    }

    /*//////////////////////////////////////////////////////////////////////////

                                IMMUTABLE GETTERS

    Allows StableMintBurn to override the immutables to instead make a call to
    address(this) so the action is delegatecall safe.

    //////////////////////////////////////////////////////////////////////////*/

    IERC20 internal immutable _token0;
    IERC20 internal immutable _token1;

    // Multipliers for each pooled token's precision to get to POOL_PRECISION_DECIMALS. For example,
    // TBTC has 18 decimals, so the multiplier should be 1. WBTC has 8, so the multiplier should be
    // 10 ** 18 / 10 ** 8 => 10 ** 10.
    uint128 internal immutable _token0PrecisionMultiplier;
    uint128 internal immutable _token1PrecisionMultiplier;

    function token0() public view virtual returns (IERC20) {
        return _token0;
    }

    function token1() public view virtual returns (IERC20) {
        return _token1;
    }

    function token0PrecisionMultiplier() public view virtual returns (uint128) {
        return _token0PrecisionMultiplier;
    }

    function token1PrecisionMultiplier() public view virtual returns (uint128) {
        return _token1PrecisionMultiplier;
    }

    /*//////////////////////////////////////////////////////////////////////////

                                SLOT0 & RESERVES

    //////////////////////////////////////////////////////////////////////////*/

    Slot0 internal _slot0 = Slot0({ reserve0: 0, reserve1: 0, packedTimestamp: 0, index: type(uint16).max });

    function _currentTime() internal view returns (uint32) {
        return uint32(block.timestamp & 0x7FFFFFFF);
    }

    function _splitSlot0Timestamp(uint32 aPackedTimestamp) internal pure returns (uint32 rTimestamp, bool rLocked) {
        rLocked = aPackedTimestamp >> 31 == 1;
        rTimestamp = aPackedTimestamp & 0x7FFFFFFF;
    }

    /// @notice Writes the packed timestamp & re-entrancy guard into slot0.
    /// @dev The timestamp argument must not exceed 2**31.
    function _writeSlot0Timestamp(Slot0 storage sSlot0, uint32 aTimestamp, bool aLocked) internal {
        uint32 lLocked = aLocked ? uint32(1 << 31) : uint32(0);
        sSlot0.packedTimestamp = aTimestamp | lLocked;
    }

    function _lockAndLoad()
        internal
        returns (Slot0 storage, uint104 rReserve0, uint104 rReserve1, uint32 rBlockTimestampLast, uint16 rIndex)
    {
        Slot0 storage sSlot0 = _slot0;

        // Load slot0 values.
        bool lLock;
        rReserve0 = sSlot0.reserve0;
        rReserve1 = sSlot0.reserve1;
        (rBlockTimestampLast, lLock) = _splitSlot0Timestamp(sSlot0.packedTimestamp);
        rIndex = sSlot0.index;

        // Acquire reentrancy lock.
        require(!lLock, "REENTRANCY");
        _writeSlot0Timestamp(sSlot0, rBlockTimestampLast, true);

        return (sSlot0, rReserve0, rReserve1, rBlockTimestampLast, rIndex);
    }

    function _unlock(Slot0 storage sSlot0, uint32 aBlockTimestampLast) internal {
        _writeSlot0Timestamp(sSlot0, aBlockTimestampLast, false);
    }

    // update reserves with new balances
    // on the first call per block, update price and liq oracle using previous reserves
    function _updateAndUnlock(
        Slot0 storage sSlot0,
        uint256 aBalance0,
        uint256 aBalance1,
        uint256 aReserve0,
        uint256 aReserve1,
        uint32 aBlockTimestampLast
    ) internal {
        require(aBalance0 <= type(uint104).max && aBalance1 <= type(uint104).max, "RP: OVERFLOW");
        require(aReserve0 <= type(uint104).max && aReserve1 <= type(uint104).max, "RP: OVERFLOW");

        uint32 lBlockTimestamp = uint32(_currentTime());
        uint32 lTimeElapsed;
        unchecked {
            // underflow is desired
            // however in the case where no swaps happen in ~68 years (2 ** 31 seconds) the timeElapsed would underflow twice
            lTimeElapsed = lBlockTimestamp - aBlockTimestampLast;
        }
        if (lTimeElapsed > 0 && aReserve0 != 0 && aReserve1 != 0) {
            _updateOracle(aReserve0, aReserve1, lTimeElapsed, aBlockTimestampLast);
        }

        // update reserves to match latest balances
        sSlot0.reserve0 = uint104(aBalance0);
        sSlot0.reserve1 = uint104(aBalance1);
        _writeSlot0Timestamp(sSlot0, lBlockTimestamp, false);

        emit Sync(uint104(aBalance0), uint104(aBalance1));
    }

    function getReserves()
        public
        view
        returns (uint104 rReserve0, uint104 rReserve1, uint32 rBlockTimestampLast, uint16 rIndex)
    {
        Slot0 memory lSlot0 = _slot0;

        rReserve0 = lSlot0.reserve0;
        rReserve1 = lSlot0.reserve1;
        (rBlockTimestampLast,) = _splitSlot0Timestamp(lSlot0.packedTimestamp);
        rIndex = lSlot0.index;
    }

    /// @notice Force reserves to match balances.
    function sync() external {
        (Slot0 storage sSlot0, uint256 lReserve0, uint256 lReserve1, uint32 lBlockTimestampLast,) = _lockAndLoad();
        (lReserve0, lReserve1) = _syncManaged(lReserve0, lReserve1);

        _updateAndUnlock(sSlot0, _totalToken0(), _totalToken1(), lReserve0, lReserve1, lBlockTimestampLast);
    }

    /// @notice Force balances to match reserves.
    function skim(address aTo) external {
        (Slot0 storage sSlot0, uint256 lReserve0, uint256 lReserve1, uint32 lBlockTimestampLast,) = _lockAndLoad();

        _checkedTransfer(token0(), aTo, _totalToken0() - lReserve0, lReserve0, lReserve1);
        _checkedTransfer(token1(), aTo, _totalToken1() - lReserve1, lReserve0, lReserve1);
        _unlock(sSlot0, lBlockTimestampLast);
    }

    /*//////////////////////////////////////////////////////////////////////////

                                ADMIN ACTIONS

    //////////////////////////////////////////////////////////////////////////*/

    event SwapFee(uint256 newSwapFee);
    event CustomSwapFee(uint256 newCustomSwapFee);
    event PlatformFee(uint256 newPlatformFee);
    event CustomPlatformFee(uint256 newCustomPlatformFee);

    string internal constant PLATFORM_FEE_TO_NAME = "Shared::platformFeeTo";
    string private constant PLATFORM_FEE_NAME = "Shared::platformFee";
    string private constant RECOVERER_NAME = "Shared::recoverer";
    bytes4 private constant TRANSFER = bytes4(keccak256("transfer(address,uint256)"));
    bytes32 internal immutable swapFeeName;

    /// @notice Maximum allowed swap fee, which is 2%.
    uint256 public constant MAX_SWAP_FEE = 0.02e6;
    /// @notice Current swap fee.
    uint256 public swapFee;
    /// @notice Custom swap fee override for the pair, max uint256 indicates no override.
    uint256 public customSwapFee = type(uint256).max;

    /// @notice Maximum allowed platform fee, which is 100%.
    uint256 public constant MAX_PLATFORM_FEE = 1e6;
    /// @notice Current platformFee.
    uint256 public platformFee;
    /// @notice Custom platformFee override for the pair, max uint256 indicates no override.
    uint256 public customPlatformFee = type(uint256).max;

    function setCustomSwapFee(uint256 aCustomSwapFee) external onlyFactory {
        emit CustomSwapFee(aCustomSwapFee);
        customSwapFee = aCustomSwapFee;

        updateSwapFee();
    }

    function setCustomPlatformFee(uint256 aCustomPlatformFee) external onlyFactory {
        emit CustomPlatformFee(aCustomPlatformFee);
        customPlatformFee = aCustomPlatformFee;

        updatePlatformFee();
    }

    function updateSwapFee() public {
        uint256 _swapFee = customSwapFee != type(uint256).max ? customSwapFee : factory.get(swapFeeName).toUint256();
        if (_swapFee == swapFee) return;

        require(_swapFee <= MAX_SWAP_FEE, "RP: INVALID_SWAP_FEE");

        emit SwapFee(_swapFee);
        swapFee = _swapFee;
    }

    function updatePlatformFee() public {
        uint256 _platformFee =
            customPlatformFee != type(uint256).max ? customPlatformFee : factory.read(PLATFORM_FEE_NAME).toUint256();
        if (_platformFee == platformFee) return;

        require(_platformFee <= MAX_PLATFORM_FEE, "RP: INVALID_PLATFORM_FEE");

        emit PlatformFee(_platformFee);
        platformFee = _platformFee;
    }

    function recoverToken(IERC20 aToken) external {
        require(aToken != token0() && aToken != token1(), "RP: INVALID_TOKEN_TO_RECOVER");
        address _recoverer = factory.read(RECOVERER_NAME).toAddress();
        uint256 _amountToRecover = aToken.balanceOf(address(this));

        address(aToken).safeTransfer(_recoverer, _amountToRecover);
    }

    /*//////////////////////////////////////////////////////////////////////////

                                TRANSFER HELPERS

    //////////////////////////////////////////////////////////////////////////*/

    function _safeTransfer(IERC20 aToken, address aTo, uint256 aValue) internal returns (bool) {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory data) = address(aToken).call(abi.encodeWithSelector(TRANSFER, aTo, aValue));
        return success && (data.length == 0 || abi.decode(data, (bool)));
    }

    // performs a transfer, if it fails, it attempts to retrieve assets from the
    // AssetManager before retrying the transfer
    function _checkedTransfer(
        IERC20 aToken,
        address aDestination,
        uint256 aAmount,
        uint256 aReserve0,
        uint256 aReserve1
    ) internal {
        if (!_safeTransfer(aToken, aDestination, aAmount)) {
            bool lIsToken0 = aToken == token0();
            uint256 lTokenOutManaged = lIsToken0 ? token0Managed : token1Managed;
            uint256 lReserveOut = lIsToken0 ? aReserve0 : aReserve1;

            if (lReserveOut - lTokenOutManaged < aAmount) {
                assetManager.returnAsset(lIsToken0, aAmount - (lReserveOut - lTokenOutManaged));
                require(_safeTransfer(aToken, aDestination, aAmount), "RP: TRANSFER_FAILED");
            } else {
                revert("RP: TRANSFER_FAILED");
            }
        }
    }

    /*//////////////////////////////////////////////////////////////////////////

                                CORE AMM FUNCTIONS

    //////////////////////////////////////////////////////////////////////////*/

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1);
    event Swap(address indexed sender, bool zeroForOne, uint256 amountIn, uint256 amountOut, address indexed to);
    event Sync(uint104 reserve0, uint104 reserve1);

    /// @dev Mints LP tokens using tokens sent to this contract.
    function mint(address aTo) external virtual returns (uint256 liquidity);

    /// @dev Burns LP tokens sent to this contract.
    function burn(address aTo) external virtual returns (uint256 amount0, uint256 amount1);

    /// @notice Swaps one token for another. The router must prefund this contract and ensure there isn't too much
    ///         slippage.
    /// @param aAmount positive to indicate token0, negative to indicate token1
    /// @param aExactIn true to indicate an exact in trade, false to indicate an exact out trade
    /// @param aTo address to send the output token and leftover input tokens, callee for the flash swap
    /// @param aData calls to with this data, in the event of a flash swap
    function swap(int256 aAmount, bool aExactIn, address aTo, bytes calldata aData)
        external
        virtual
        returns (uint256 rAmountOut);

    /*//////////////////////////////////////////////////////////////////////////
                                ASSET MANAGEMENT

    Asset management is supported via a two-way interface. The pool is able to
    ask the current asset manager for the latest view of the balances. In turn
    the asset manager can move assets in/out of the pool. This section
    implements the pool side of the equation. The manager's side is abstracted
    behind the IAssetManager interface.

    //////////////////////////////////////////////////////////////////////////*/

    event Profit(IERC20 token, uint256 amount);
    event Loss(IERC20 token, uint256 amount);

    IAssetManager public assetManager;

    function setManager(IAssetManager manager) external onlyFactory {
        require(token0Managed == 0 && token1Managed == 0, "RP: AM_STILL_ACTIVE");
        assetManager = manager;
        emit AssetManager(manager);
    }

    uint104 public token0Managed;
    uint104 public token1Managed;

    function _totalToken0() internal view returns (uint256) {
        return token0().balanceOf(address(this)) + uint256(token0Managed);
    }

    function _totalToken1() internal view returns (uint256) {
        return token1().balanceOf(address(this)) + uint256(token1Managed);
    }

    function _handleReport(IERC20 aToken, uint256 aReserve, uint256 aPrevBalance, uint256 aNewBalance)
        private
        returns (uint256 rUpdatedReserve)
    {
        if (aNewBalance > aPrevBalance) {
            // report profit
            uint256 lProfit = aNewBalance - aPrevBalance;

            emit Profit(aToken, lProfit);

            rUpdatedReserve = aReserve + lProfit;
        } else if (aNewBalance < aPrevBalance) {
            // report loss
            uint256 lLoss = aPrevBalance - aNewBalance;

            emit Loss(aToken, lLoss);

            rUpdatedReserve = aReserve - lLoss;
        } else {
            // Balances are equal, return the original reserve.
            rUpdatedReserve = aReserve;
        }
    }

    function _syncManaged(uint256 aReserve0, uint256 aReserve1)
        internal
        returns (uint256 rReserve0, uint256 rReserve1)
    {
        if (address(assetManager) == address(0)) {
            return (aReserve0, aReserve1);
        }

        IERC20 lToken0 = token0();
        IERC20 lToken1 = token1();

        uint256 lToken0Managed = assetManager.getBalance(this, lToken0);
        uint256 lToken1Managed = assetManager.getBalance(this, lToken1);

        rReserve0 = _handleReport(lToken0, aReserve0, token0Managed, lToken0Managed);
        rReserve1 = _handleReport(lToken1, aReserve1, token1Managed, lToken1Managed);

        token0Managed = lToken0Managed.toUint104();
        token1Managed = lToken1Managed.toUint104();
    }

    function _managerCallback() internal {
        if (address(assetManager) == address(0)) {
            return;
        }

        assetManager.afterLiquidityEvent();
    }

    function adjustManagement(int256 aToken0Change, int256 aToken1Change) external {
        require(msg.sender == address(assetManager), "RP: AUTH_NOT_MANAGER");

        if (aToken0Change > 0) {
            uint104 lDelta = uint256(aToken0Change).toUint104();

            token0Managed += lDelta;

            address(token0()).safeTransfer(msg.sender, lDelta);
        } else if (aToken0Change < 0) {
            uint104 lDelta = uint256(-aToken0Change).toUint104();

            // solhint-disable-next-line reentrancy
            token0Managed -= lDelta;

            address(token0()).safeTransferFrom(msg.sender, address(this), lDelta);
        }

        if (aToken1Change > 0) {
            uint104 lDelta = uint256(aToken1Change).toUint104();

            // solhint-disable-next-line reentrancy
            token1Managed += lDelta;

            address(token1()).safeTransfer(msg.sender, lDelta);
        } else if (aToken1Change < 0) {
            uint104 lDelta = uint256(-aToken1Change).toUint104();

            // solhint-disable-next-line reentrancy
            token1Managed -= lDelta;

            address(token1()).safeTransferFrom(msg.sender, address(this), lDelta);
        }
    }

    function skimExcessManaged(IERC20 aToken) external returns (uint256 rAmtSkimmed) {
        require(aToken == token0() || aToken == token1(), "RP: INVALID_SKIM_TOKEN");
        uint256 lTokenAmtManaged = assetManager.getBalance(this, aToken);

        if (lTokenAmtManaged > type(uint104).max) {
            address lRecoverer = factory.read(RECOVERER_NAME).toAddress();

            rAmtSkimmed = lTokenAmtManaged - type(uint104).max;

            assetManager.returnAsset(aToken == token0(), rAmtSkimmed);
            address(aToken).safeTransfer(lRecoverer, rAmtSkimmed);
        }
    }

    /*//////////////////////////////////////////////////////////////////////////
                            ORACLE WRITING

    Our oracle implementation records both the raw price and clamped price.
    The clamped price mechanism is introduced by Reservoir to counter the possibility
    of oracle manipulation as ETH transitions to PoS when validators can control
    multiple blocks in a row. See also https://chainsecurity.com/oracle-manipulation-after-merge/

    //////////////////////////////////////////////////////////////////////////*/

    event OracleCallerUpdated(address oldCaller, address newCaller);
    event MaxChangeRateUpdated(uint256 oldMaxChangePerSecond, uint256 newMaxChangePerSecond);

    // 100 basis points per second which is 60% per minute
    uint256 internal constant MAX_CHANGE_PER_SEC = 0.01e18;
    string internal constant MAX_CHANGE_RATE_NAME = "Shared::maxChangeRate";
    string internal constant ORACLE_CALLER_NAME = "Shared::oracleCaller";

    Observation[65_536] internal _observations;

    // maximum allowed rate of change of price per second
    // to mitigate oracle manipulation attacks in the face of post-merge ETH
    uint256 public maxChangeRate;
    uint256 public prevClampedPrice;

    address public oracleCaller;

    function observation(uint256 aIndex) external view returns (Observation memory rObservation) {
        require(msg.sender == oracleCaller, "RP: NOT_ORACLE_CALLER");
        rObservation = _observations[aIndex];
    }

    function updateOracleCaller() public {
        address lNewCaller = factory.read(ORACLE_CALLER_NAME).toAddress();
        if (lNewCaller != oracleCaller) {
            emit OracleCallerUpdated(oracleCaller, lNewCaller);
            oracleCaller = lNewCaller;
        }
    }

    function setMaxChangeRate(uint256 aMaxChangeRate) public onlyFactory {
        require(0 < aMaxChangeRate && aMaxChangeRate <= MAX_CHANGE_PER_SEC, "RP: INVALID_CHANGE_PER_SECOND");
        emit MaxChangeRateUpdated(maxChangeRate, aMaxChangeRate);
        maxChangeRate = aMaxChangeRate;
    }

    function _calcClampedPrice(uint256 aCurrRawPrice, uint256 aPrevClampedPrice, uint256 aTimeElapsed)
        internal
        virtual
        returns (uint256 rClampedPrice, int112 rClampedLogPrice)
    {
        if (aPrevClampedPrice == 0) {
            return (aCurrRawPrice, int112(LogCompression.toLowResLog(aCurrRawPrice)));
        }

        // call to `percentDelta` will revert if the difference between aCurrRawPrice and aPrevClampedPrice is
        // greater than uint196 (1e59). It is extremely unlikely that one trade can change the price by 1e59
        if (aCurrRawPrice.percentDelta(aPrevClampedPrice) > maxChangeRate * aTimeElapsed) {
            // clamp the price
            // multiplication of maxChangeRate and aTimeElapsed would not overflow as
            // maxChangeRate <= 0.01e18 (50 bits)
            // aTimeElapsed <= 32 bits
            if (aCurrRawPrice > aPrevClampedPrice) {
                rClampedPrice = aPrevClampedPrice.fullMulDiv(1e18 + maxChangeRate * aTimeElapsed, 1e18);
            } else {
                assert(aPrevClampedPrice > aCurrRawPrice);
                rClampedPrice = aPrevClampedPrice.fullMulDiv(1e18 - maxChangeRate * aTimeElapsed, 1e18);
            }
            rClampedLogPrice = int112(LogCompression.toLowResLog(rClampedPrice));
        } else {
            rClampedPrice = aCurrRawPrice;
            rClampedLogPrice = int112(LogCompression.toLowResLog(aCurrRawPrice));
        }
    }

    function _updateOracle(uint256 aReserve0, uint256 aReserve1, uint32 aTimeElapsed, uint32 aTimestampLast)
        internal
        virtual;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Read and write to persistent storage at a fraction of the cost.
/// @author Solady (https://github.com/vectorized/solmady/blob/main/src/utils/SSTORE2.sol)
/// @author Saw-mon-and-Natalie (https://github.com/Saw-mon-and-Natalie)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SSTORE2.sol)
/// @author Modified from 0xSequence (https://github.com/0xSequence/sstore2/blob/master/contracts/SSTORE2.sol)
library SSTORE2 {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev We skip the first byte as it's a STOP opcode,
    /// which ensures the contract can't be called.
    uint256 internal constant DATA_OFFSET = 1;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Unable to deploy the storage contract.
    error DeploymentFailed();

    /// @dev The storage contract address is invalid.
    error InvalidPointer();

    /// @dev Attempt to read outside of the storage contract's bytecode bounds.
    error ReadOutOfBounds();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         WRITE LOGIC                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Writes `data` into the bytecode of a storage contract and returns its address.
    function write(bytes memory data) internal returns (address pointer) {
        // Note: The assembly block below does not expand the memory.
        /// @solidity memory-safe-assembly
        assembly {
            let originalDataLength := mload(data)

            // Add 1 to data size since we are prefixing it with a STOP opcode.
            let dataSize := add(originalDataLength, DATA_OFFSET)

            /**
             * ------------------------------------------------------------------------------+
             * Opcode      | Mnemonic        | Stack                   | Memory              |
             * ------------------------------------------------------------------------------|
             * 61 codeSize | PUSH2 codeSize  | codeSize                |                     |
             * 80          | DUP1            | codeSize codeSize       |                     |
             * 60 0xa      | PUSH1 0xa       | 0xa codeSize codeSize   |                     |
             * 3D          | RETURNDATASIZE  | 0 0xa codeSize codeSize |                     |
             * 39          | CODECOPY        | codeSize                | [0..codeSize): code |
             * 3D          | RETURNDATASZIE  | 0 codeSize              | [0..codeSize): code |
             * F3          | RETURN          |                         | [0..codeSize): code |
             * 00          | STOP            |                         |                     |
             * ------------------------------------------------------------------------------+
             * @dev Prefix the bytecode with a STOP opcode to ensure it cannot be called.
             * Also PUSH2 is used since max contract size cap is 24,576 bytes which is less than 2 ** 16.
             */
            mstore(
                data,
                or(
                    0x61000080600a3d393df300,
                    // Left shift `dataSize` by 64 so that it lines up with the 0000 after PUSH2.
                    shl(0x40, dataSize)
                )
            )

            // Deploy a new contract with the generated creation code.
            pointer := create(0, add(data, 0x15), add(dataSize, 0xa))

            // If `pointer` is zero, revert.
            if iszero(pointer) {
                // Store the function selector of `DeploymentFailed()`.
                mstore(0x00, 0x30116425)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Restore original length of the variable size `data`.
            mstore(data, originalDataLength)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         READ LOGIC                         */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns all the `data` from the bytecode of the storage contract at `pointer`.
    function read(address pointer) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Offset all indices by 1 to skip the STOP opcode.
            let size := sub(pointerCodesize, DATA_OFFSET)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), DATA_OFFSET, size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the end of the data stored.
    function read(address pointer, uint256 start) internal view returns (bytes memory data) {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > start)`, reverts.
            // This also handles the case where `start + DATA_OFFSET` overflows.
            if iszero(gt(pointerCodesize, start)) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(pointerCodesize, add(start, DATA_OFFSET))

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, DATA_OFFSET), size)
        }
    }

    /// @dev Returns the `data` from the bytecode of the storage contract at `pointer`,
    /// from the byte at `start`, to the byte at `end` (exclusive) of the data stored.
    function read(address pointer, uint256 start, uint256 end)
        internal
        view
        returns (bytes memory data)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let pointerCodesize := extcodesize(pointer)
            if iszero(pointerCodesize) {
                // Store the function selector of `InvalidPointer()`.
                mstore(0x00, 0x11052bb4)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // If `!(pointer.code.size > end) || (start > end)`, revert.
            // This also handles the cases where
            // `end + DATA_OFFSET` or `start + DATA_OFFSET` overflows.
            if iszero(
                and(
                    gt(pointerCodesize, end), // Within bounds.
                    iszero(gt(start, end)) // Valid range.
                )
            ) {
                // Store the function selector of `ReadOutOfBounds()`.
                mstore(0x00, 0x84eb0dd1)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            let size := sub(end, start)

            // Get the pointer to the free memory and allocate
            // enough 32-byte words for the data and the length of the data,
            // then copy the code to the allocated memory.
            // Masking with 0xffe0 will suffice, since contract size is less than 16 bits.
            data := mload(0x40)
            mstore(0x40, add(data, and(add(size, 0x3f), 0xffe0)))
            mstore(data, size)
            mstore(add(add(data, 0x20), size), 0) // Zeroize the last slot.
            extcodecopy(pointer, add(data, 0x20), add(start, DATA_OFFSET), size)
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";

import {
    IERC20,
    Bytes32Lib,
    FactoryStoreLib,
    StableMath,
    IGenericFactory,
    StablePair,
    Slot0
} from "src/curve/stable/StablePair.sol";

contract StableMintBurn is StablePair {
    using FactoryStoreLib for IGenericFactory;
    using Bytes32Lib for bytes32;
    using FixedPointMathLib for uint256;

    string private constant PAIR_SWAP_FEE_NAME = "SP::swapFee";

    // solhint-disable-next-line no-empty-blocks
    constructor() StablePair(IERC20(address(0)), IERC20(address(0))) {
        // no additional initialization logic is required as all constructor logic is in StablePair
    }

    function token0() public view override returns (IERC20) {
        return this.token0();
    }

    function token1() public view override returns (IERC20) {
        return this.token1();
    }

    function token0PrecisionMultiplier() public view override returns (uint128) {
        return this.token0PrecisionMultiplier();
    }

    function token1PrecisionMultiplier() public view override returns (uint128) {
        return this.token1PrecisionMultiplier();
    }

    /// @dev This fee is charged to cover for `swapFee` when users add unbalanced liquidity.
    /// multiplications will not phantom overflow given the following conditions:
    /// 1. reserves are <= uint104
    /// 2. aAmount0 and aAmount1 <= uint104 as it would revert anyway at _updateAndUnlock if above uint104
    /// 3. swapFee <= 0.02e6
    function _nonOptimalMintFee(uint256 aAmount0, uint256 aAmount1, uint256 aReserve0, uint256 aReserve1)
        internal
        view
        returns (uint256 rToken0Fee, uint256 rToken1Fee)
    {
        if (aReserve0 == 0 || aReserve1 == 0) return (0, 0);
        uint256 amount1Optimal = aAmount0 * aReserve1 / aReserve0;

        if (amount1Optimal <= aAmount1) {
            rToken1Fee = (swapFee * (aAmount1 - amount1Optimal)) / (2 * FEE_ACCURACY);
        } else {
            uint256 amount0Optimal = aAmount1 * aReserve0 / aReserve1;
            rToken0Fee = swapFee * (aAmount0 - amount0Optimal) / (2 * FEE_ACCURACY);
        }
        require(rToken0Fee <= type(uint104).max && rToken1Fee <= type(uint104).max, "SP: NON_OPTIMAL_FEE_TOO_LARGE");
    }

    function mint(address aTo) external override returns (uint256 rLiquidity) {
        // NB: Must sync management PNL before we load reserves.
        (Slot0 storage sSlot0, uint256 lReserve0, uint256 lReserve1, uint32 lBlockTimestampLast,) = _lockAndLoad();
        (lReserve0, lReserve1) = _syncManaged(lReserve0, lReserve1);

        uint256 lBalance0 = _totalToken0();
        uint256 lBalance1 = _totalToken1();

        uint256 lNewLiq = _computeLiquidity(lBalance0, lBalance1);
        uint256 lAmount0 = lBalance0 - lReserve0;
        uint256 lAmount1 = lBalance1 - lReserve1;

        (uint256 lFee0, uint256 lFee1) = _nonOptimalMintFee(lAmount0, lAmount1, lReserve0, lReserve1);
        lReserve0 += uint104(lFee0);
        lReserve1 += uint104(lFee1);

        (uint256 lTotalSupply, uint256 lOldLiq) = _mintFee(lReserve0, lReserve1);

        if (lTotalSupply == 0) {
            require(lAmount0 > 0 && lAmount1 > 0, "SP: INVALID_AMOUNTS");
            rLiquidity = lNewLiq - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            // will only phantom overflow and revert when lTotalSupply and lNewLiq is in the range of uint128 which will only happen if:
            // 1. both tokens have 0 decimals (1e18 is 60 bits) and the amounts are each around 68 bits
            // 2. both tokens have 6 decimals (1e12 is 40 bits) and the amounts are each around 88 bits
            // in which case the mint will fail anyway because it would have reverted at _computeLiquidity
            rLiquidity = (lNewLiq - lOldLiq) * lTotalSupply / lOldLiq;
        }
        require(rLiquidity != 0, "SP: INSUFFICIENT_LIQ_MINTED");
        _mint(aTo, rLiquidity);

        // Casting is safe as the max invariant would be 2 * uint104 * uint60 (in the case of tokens
        // with 0 decimal places).
        // Which results in 112 + 60 + 1 = 173 bits.
        // Which fits into uint192.
        lastInvariant = uint192(lNewLiq);
        lastInvariantAmp = _getCurrentAPrecise();

        emit Mint(msg.sender, lAmount0, lAmount1);

        _updateAndUnlock(sSlot0, lBalance0, lBalance1, lReserve0, lReserve1, lBlockTimestampLast);
        _managerCallback();
    }

    function burn(address aTo) external override returns (uint256 rAmount0, uint256 rAmount1) {
        // NB: Must sync management PNL before we load reserves.
        (Slot0 storage sSlot0, uint256 lReserve0, uint256 lReserve1, uint32 lBlockTimestampLast,) = _lockAndLoad();
        (lReserve0, lReserve1) = _syncManaged(lReserve0, lReserve1);

        uint256 liquidity = balanceOf[address(this)];

        uint256 lTotalSupply;
        // this is a safety feature that prevents revert when removing liquidity
        // i.e. removing liquidity should always succeed under all circumstances
        // so if the iterative functions revert, we just have to forgo the platformFee calculations
        // and use the current totalSupply of LP tokens for calculations since there is no new
        // LP tokens minted for platformFee
        try StablePair(this).mintFee(lReserve0, lReserve1) returns (uint256 rTotalSupply, uint256) {
            lTotalSupply = rTotalSupply;
        } catch {
            lTotalSupply = totalSupply;
        }

        rAmount0 = liquidity.fullMulDiv(lReserve0, lTotalSupply);
        rAmount1 = liquidity.fullMulDiv(lReserve1, lTotalSupply);

        _burn(address(this), liquidity);

        _checkedTransfer(this.token0(), aTo, rAmount0, lReserve0, lReserve1);
        _checkedTransfer(this.token1(), aTo, rAmount1, lReserve0, lReserve1);

        uint256 lBalance0 = _totalToken0();
        uint256 lBalance1 = _totalToken1();
        lastInvariant = uint192(_computeLiquidity(lBalance0, lBalance1));
        lastInvariantAmp = _getCurrentAPrecise();
        emit Burn(msg.sender, rAmount0, rAmount1);

        _updateAndUnlock(sSlot0, lBalance0, lBalance1, lReserve0, lReserve1, lBlockTimestampLast);
        _managerCallback();
    }

    function swap(int256, bool, address, bytes calldata) external pure override returns (uint256) {
        revert("SMB: IMPOSSIBLE");
    }

    function mintFee(uint256 aReserve0, uint256 aReserve1)
        external
        virtual
        override
        returns (uint256 rTotalSupply, uint256 rD)
    {
        require(msg.sender == address(this), "SP: NOT_SELF");
        return _mintFee(aReserve0, aReserve1);
    }

    function _mintFee(uint256 aReserve0, uint256 aReserve1) internal returns (uint256 rTotalSupply, uint256 rD) {
        bool lFeeOn = platformFee > 0;
        rTotalSupply = totalSupply;
        rD = StableMath._computeLiquidityFromAdjustedBalances(
            aReserve0 * token0PrecisionMultiplier(), aReserve1 * token1PrecisionMultiplier(), 2 * lastInvariantAmp
        );
        if (lFeeOn) {
            uint256 lDLast = lastInvariant;
            if (rD > lDLast) {
                // @dev `platformFee` % of increase in liquidity.
                uint256 lPlatformFee = platformFee;
                // will not phantom overflow as rTotalSupply is max 128 bits. and (rD - lDLast) is usually within 70 bits and lPlatformFee is max 1e6 (20 bits)
                uint256 lNumerator = rTotalSupply * (rD - lDLast) * lPlatformFee;
                // will not phantom overflow as FEE_ACCURACY and lPlatformFee are max 1e6 (20 bits), and rD and lDLast are max 128 bits
                uint256 lDenominator = (FEE_ACCURACY - lPlatformFee) * rD + lPlatformFee * lDLast;
                uint256 lPlatformShares = lNumerator / lDenominator;

                if (lPlatformShares != 0) {
                    address lPlatformFeeTo = this.factory().read(PLATFORM_FEE_TO_NAME).toAddress();

                    _mint(lPlatformFeeTo, lPlatformShares);
                    rTotalSupply += lPlatformShares;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2;

/// @dev Interface of the ERC20 standard as defined in the EIP.
/// @dev This includes the optional name, symbol, and decimals metadata.
interface IERC20 {
    /// @dev Emitted when `value` tokens are moved from one account (`from`) to another (`to`).
    event Transfer(address indexed from, address indexed to, uint256 value);

    /// @dev Emitted when the allowance of a `spender` for an `owner` is set, where `value`
    /// is the new allowance.
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice Returns the amount of tokens in existence.
    function totalSupply() external view returns (uint256);

    /// @notice Returns the amount of tokens owned by `account`.
    function balanceOf(address account) external view returns (uint256);

    /// @notice Moves `amount` tokens from the caller's account to `to`.
    function transfer(address to, uint256 amount) external returns (bool);

    /// @notice Returns the remaining number of tokens that `spender` is allowed
    /// to spend on behalf of `owner`
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Sets `amount` as the allowance of `spender` over the caller's tokens.
    /// @dev Be aware of front-running risks: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Moves `amount` tokens from `from` to `to` using the allowance mechanism.
    /// `amount` is then deducted from the caller's allowance.
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    /// @notice Returns the name of the token.
    function name() external view returns (string memory);

    /// @notice Returns the symbol of the token.
    function symbol() external view returns (string memory);

    /// @notice Returns the decimals places of the token.
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.4.1) (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248) {
        require(value >= type(int248).min && value <= type(int248).max, "SafeCast: value doesn't fit in 248 bits");
        return int248(value);
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240) {
        require(value >= type(int240).min && value <= type(int240).max, "SafeCast: value doesn't fit in 240 bits");
        return int240(value);
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232) {
        require(value >= type(int232).min && value <= type(int232).max, "SafeCast: value doesn't fit in 232 bits");
        return int232(value);
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224) {
        require(value >= type(int224).min && value <= type(int224).max, "SafeCast: value doesn't fit in 224 bits");
        return int224(value);
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216) {
        require(value >= type(int216).min && value <= type(int216).max, "SafeCast: value doesn't fit in 216 bits");
        return int216(value);
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208) {
        require(value >= type(int208).min && value <= type(int208).max, "SafeCast: value doesn't fit in 208 bits");
        return int208(value);
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200) {
        require(value >= type(int200).min && value <= type(int200).max, "SafeCast: value doesn't fit in 200 bits");
        return int200(value);
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192) {
        require(value >= type(int192).min && value <= type(int192).max, "SafeCast: value doesn't fit in 192 bits");
        return int192(value);
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184) {
        require(value >= type(int184).min && value <= type(int184).max, "SafeCast: value doesn't fit in 184 bits");
        return int184(value);
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176) {
        require(value >= type(int176).min && value <= type(int176).max, "SafeCast: value doesn't fit in 176 bits");
        return int176(value);
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168) {
        require(value >= type(int168).min && value <= type(int168).max, "SafeCast: value doesn't fit in 168 bits");
        return int168(value);
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160) {
        require(value >= type(int160).min && value <= type(int160).max, "SafeCast: value doesn't fit in 160 bits");
        return int160(value);
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152) {
        require(value >= type(int152).min && value <= type(int152).max, "SafeCast: value doesn't fit in 152 bits");
        return int152(value);
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144) {
        require(value >= type(int144).min && value <= type(int144).max, "SafeCast: value doesn't fit in 144 bits");
        return int144(value);
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136) {
        require(value >= type(int136).min && value <= type(int136).max, "SafeCast: value doesn't fit in 136 bits");
        return int136(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120) {
        require(value >= type(int120).min && value <= type(int120).max, "SafeCast: value doesn't fit in 120 bits");
        return int120(value);
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112) {
        require(value >= type(int112).min && value <= type(int112).max, "SafeCast: value doesn't fit in 112 bits");
        return int112(value);
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104) {
        require(value >= type(int104).min && value <= type(int104).max, "SafeCast: value doesn't fit in 104 bits");
        return int104(value);
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96) {
        require(value >= type(int96).min && value <= type(int96).max, "SafeCast: value doesn't fit in 96 bits");
        return int96(value);
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88) {
        require(value >= type(int88).min && value <= type(int88).max, "SafeCast: value doesn't fit in 88 bits");
        return int88(value);
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80) {
        require(value >= type(int80).min && value <= type(int80).max, "SafeCast: value doesn't fit in 80 bits");
        return int80(value);
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72) {
        require(value >= type(int72).min && value <= type(int72).max, "SafeCast: value doesn't fit in 72 bits");
        return int72(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56) {
        require(value >= type(int56).min && value <= type(int56).max, "SafeCast: value doesn't fit in 56 bits");
        return int56(value);
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48) {
        require(value >= type(int48).min && value <= type(int48).max, "SafeCast: value doesn't fit in 48 bits");
        return int48(value);
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40) {
        require(value >= type(int40).min && value <= type(int40).max, "SafeCast: value doesn't fit in 40 bits");
        return int40(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24) {
        require(value >= type(int24).min && value <= type(int24).max, "SafeCast: value doesn't fit in 24 bits");
        return int24(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
library FixedPointMathLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error ExpOverflow();

    /// @dev The operation failed, as the output exceeds the maximum value of uint256.
    error FactorialOverflow();

    /// @dev The operation failed, due to an multiplication overflow.
    error MulWadFailed();

    /// @dev The operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error DivWadFailed();

    /// @dev The multiply-divide operation failed, either due to a
    /// multiplication overflow, or a division by a zero.
    error MulDivFailed();

    /// @dev The division failed, as the denominator is zero.
    error DivFailed();

    /// @dev The full precision multiply-divide operation failed, either due
    /// to the result being larger than 256 bits, or a division by a zero.
    error FullMulDivFailed();

    /// @dev The output is undefined, as the input is less-than-or-equal to zero.
    error LnWadUndefined();

    /// @dev The output is undefined, as the input is zero.
    error Log2Undefined();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The scalar of ETH and most ERC20s.
    uint256 internal constant WAD = 1e18;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*              SIMPLIFIED FIXED POINT OPERATIONS             */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Equivalent to `(x * y) / WAD` rounded down.
    function mulWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), WAD)
        }
    }

    /// @dev Equivalent to `(x * y) / WAD` rounded up.
    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y == 0 || x <= type(uint256).max / y)`.
            if mul(y, gt(x, div(not(0), y))) {
                // Store the function selector of `MulWadFailed()`.
                mstore(0x00, 0xbac65e5b)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), WAD))), div(mul(x, y), WAD))
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded down.
    function divWad(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, WAD), y)
        }
    }

    /// @dev Equivalent to `(x * WAD) / y` rounded up.
    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to `require(y != 0 && (WAD == 0 || x <= type(uint256).max / WAD))`.
            if iszero(mul(y, iszero(mul(WAD, gt(x, div(not(0), WAD)))))) {
                // Store the function selector of `DivWadFailed()`.
                mstore(0x00, 0x7c5f487d)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, WAD), y))), div(mul(x, WAD), y))
        }
    }

    /// @dev Equivalent to `x` to the power of `y`.
    /// because `x ** y = (e ** ln(x)) ** y = e ** (ln(x) * y)`.
    function powWad(int256 x, int256 y) internal pure returns (int256) {
        // Using `ln(x)` means `x` must be greater than 0.
        return expWad((lnWad(x) * y) / int256(WAD));
    }

    /// @dev Returns `exp(x)`, denominated in `WAD`.
    function expWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            // When the result is < 0.5 we return zero. This happens when
            // x <= floor(log(0.5e18) * 1e18) ~ -42e18
            if (x <= -42139678854452767551) return r;

            /// @solidity memory-safe-assembly
            assembly {
                // When the result is > (2**255 - 1) / 1e18 we can not represent it as an
                // int. This happens when x >= floor(log((2**255 - 1) / 1e18) * 1e18) ~ 135.
                if iszero(slt(x, 135305999368893231589)) {
                    // Store the function selector of `ExpOverflow()`.
                    mstore(0x00, 0xa37bfec9)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // x is now in the range (-42, 136) * 1e18. Convert to (-42, 136) * 2**96
            // for more intermediate precision and a binary basis. This base conversion
            // is a multiplication by 1e18 / 2**96 = 5**18 / 2**78.
            x = (x << 78) / 5 ** 18;

            // Reduce range of x to (-½ ln 2, ½ ln 2) * 2**96 by factoring out powers
            // of two such that exp(x) = exp(x') * 2**k, where k is an integer.
            // Solving this gives k = round(x / log(2)) and x' = x - k * log(2).
            int256 k = ((x << 96) / 54916777467707473351141471128 + 2 ** 95) >> 96;
            x = x - k * 54916777467707473351141471128;

            // k is in the range [-61, 195].

            // Evaluate using a (6, 7)-term rational approximation.
            // p is made monic, we'll multiply by a scale factor later.
            int256 y = x + 1346386616545796478920950773328;
            y = ((y * x) >> 96) + 57155421227552351082224309758442;
            int256 p = y + x - 94201549194550492254356042504812;
            p = ((p * y) >> 96) + 28719021644029726153956944680412240;
            p = p * x + (4385272521454847904659076985693276 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            int256 q = x - 2855989394907223263936484059900;
            q = ((q * x) >> 96) + 50020603652535783019961831881945;
            q = ((q * x) >> 96) - 533845033583426703283633433725380;
            q = ((q * x) >> 96) + 3604857256930695427073651918091429;
            q = ((q * x) >> 96) - 14423608567350463180887372962807573;
            q = ((q * x) >> 96) + 26449188498355588339934803723976023;

            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial won't have zeros in the domain as all its roots are complex.
                // No scaling is necessary because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r should be in the range (0.09, 0.25) * 2**96.

            // We now need to multiply r by:
            // * the scale factor s = ~6.031367120.
            // * the 2**k factor from the range reduction.
            // * the 1e18 / 2**96 factor for base conversion.
            // We do this all at once, with an intermediate result in 2**213
            // basis, so the final right shift is always by a positive amount.
            r = int256(
                (uint256(r) * 3822833074963236453042738258902158003155416615667) >> uint256(195 - k)
            );
        }
    }

    /// @dev Returns `ln(x)`, denominated in `WAD`.
    function lnWad(int256 x) internal pure returns (int256 r) {
        unchecked {
            /// @solidity memory-safe-assembly
            assembly {
                if iszero(sgt(x, 0)) {
                    // Store the function selector of `LnWadUndefined()`.
                    mstore(0x00, 0x1615e638)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
            }

            // We want to convert x from 10**18 fixed point to 2**96 fixed point.
            // We do this by multiplying by 2**96 / 10**18. But since
            // ln(x * C) = ln(x) + ln(C), we can simply do nothing here
            // and add ln(2**96 / 10**18) at the end.

            // Compute k = log2(x) - 96.
            int256 k;
            /// @solidity memory-safe-assembly
            assembly {
                let v := x
                k := shl(7, lt(0xffffffffffffffffffffffffffffffff, v))
                k := or(k, shl(6, lt(0xffffffffffffffff, shr(k, v))))
                k := or(k, shl(5, lt(0xffffffff, shr(k, v))))

                // For the remaining 32 bits, use a De Bruijn lookup.
                // See: https://graphics.stanford.edu/~seander/bithacks.html
                v := shr(k, v)
                v := or(v, shr(1, v))
                v := or(v, shr(2, v))
                v := or(v, shr(4, v))
                v := or(v, shr(8, v))
                v := or(v, shr(16, v))

                // forgefmt: disable-next-item
                k := sub(or(k, byte(shr(251, mul(v, shl(224, 0x07c4acdd))),
                    0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f)), 96)
            }

            // Reduce range of x to (1, 2) * 2**96
            // ln(2^k * x) = k * ln(2) + ln(x)
            x <<= uint256(159 - k);
            x = int256(uint256(x) >> 159);

            // Evaluate using a (8, 8)-term rational approximation.
            // p is made monic, we will multiply by a scale factor later.
            int256 p = x + 3273285459638523848632254066296;
            p = ((p * x) >> 96) + 24828157081833163892658089445524;
            p = ((p * x) >> 96) + 43456485725739037958740375743393;
            p = ((p * x) >> 96) - 11111509109440967052023855526967;
            p = ((p * x) >> 96) - 45023709667254063763336534515857;
            p = ((p * x) >> 96) - 14706773417378608786704636184526;
            p = p * x - (795164235651350426258249787498 << 96);

            // We leave p in 2**192 basis so we don't need to scale it back up for the division.
            // q is monic by convention.
            int256 q = x + 5573035233440673466300451813936;
            q = ((q * x) >> 96) + 71694874799317883764090561454958;
            q = ((q * x) >> 96) + 283447036172924575727196451306956;
            q = ((q * x) >> 96) + 401686690394027663651624208769553;
            q = ((q * x) >> 96) + 204048457590392012362485061816622;
            q = ((q * x) >> 96) + 31853899698501571402653359427138;
            q = ((q * x) >> 96) + 909429971244387300277376558375;
            /// @solidity memory-safe-assembly
            assembly {
                // Div in assembly because solidity adds a zero check despite the unchecked.
                // The q polynomial is known not to have zeros in the domain.
                // No scaling required because p is already 2**96 too large.
                r := sdiv(p, q)
            }

            // r is in the range (0, 0.125) * 2**96

            // Finalization, we need to:
            // * multiply by the scale factor s = 5.549…
            // * add ln(2**96 / 10**18)
            // * add k * ln(2)
            // * multiply by 10**18 / 2**96 = 5**18 >> 78

            // mul s * 5e18 * 2**96, base is now 5**18 * 2**192
            r *= 1677202110996718588342820967067443963516166;
            // add ln(2) * k * 5e18 * 2**192
            r += 16597577552685614221487285958193947469193820559219878177908093499208371 * k;
            // add ln(2**96 / 10**18) * 5e18 * 2**192
            r += 600920179829731861736702779321621459595472258049074101567377883020018308;
            // base conversion: mul 2**18 / 2**192
            r >>= 174;
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                  GENERAL NUMBER UTILITIES                  */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Calculates floor(a × b ÷ denominator) with full precision.
    /// Throws if result overflows a uint256 or when the denominator is zero.
    /// Credit to Remco Bloemen under MIT license: https://xn--2-umb.com/21/muldiv
    function fullMulDiv(uint256 a, uint256 b, uint256 denominator)
        internal
        pure
        returns (uint256 result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for {} 1 {} {
                // 512-bit multiply [prod1 prod0] = a * b
                // Compute the product mod 2**256 and mod 2**256 - 1
                // then use the Chinese Remainder Theorem to reconstruct
                // the 512 bit result. The result is stored in two 256
                // variables such that product = prod1 * 2**256 + prod0

                // Least significant 256 bits of the product
                let prod0 := mul(a, b)
                let mm := mulmod(a, b, not(0))
                // Most significant 256 bits of the product
                let prod1 := sub(mm, add(prod0, lt(mm, prod0)))

                // Handle non-overflow cases, 256 by 256 division.
                if iszero(prod1) {
                    if iszero(denominator) {
                        // Store the function selector of `FullMulDivFailed()`.
                        mstore(0x00, 0xae47f702)
                        // Revert with (offset, size).
                        revert(0x1c, 0x04)
                    }
                    result := div(prod0, denominator)
                    break       
                }

                // Make sure the result is less than 2**256.
                // Also prevents `denominator == 0`.
                if iszero(gt(denominator, prod1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }

                ///////////////////////////////////////////////
                // 512 by 256 division.
                ///////////////////////////////////////////////

                // Make division exact by subtracting the remainder from [prod1 prod0].
                // Compute remainder using mulmod.
                let remainder := mulmod(a, b, denominator)
                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
                // Factor powers of two out of denominator.
                // Compute largest power of two divisor of denominator.
                // Always >= 1.
                let twos := and(denominator, sub(0, denominator))
                // Divide denominator by power of two
                denominator := div(denominator, twos)
                // Divide [prod1 prod0] by the factors of two
                prod0 := div(prod0, twos)
                // Shift in bits from prod1 into prod0. For this we need
                // to flip `twos` such that it is 2**256 / twos.
                // If `twos` is zero, then it becomes one.
                prod0 := or(prod0, mul(prod1, add(div(sub(0, twos), twos), 1)))
                // Invert denominator mod 2**256
                // Now that denominator is an odd number, it has an inverse
                // modulo 2**256 such that denominator * inv = 1 mod 2**256.
                // Compute the inverse by starting with a seed that is correct
                // correct for four bits. That is, denominator * inv = 1 mod 2**4
                let inv := xor(mul(3, denominator), 2)
                // Now use Newton-Raphson iteration to improve the precision.
                // Thanks to Hensel's lifting lemma, this also works in modular
                // arithmetic, doubling the correct bits in each step.
                inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**8
                inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**16
                inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**32
                inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**64
                inv := mul(inv, sub(2, mul(denominator, inv))) // inverse mod 2**128
                result := mul(prod0, mul(inv, sub(2, mul(denominator, inv)))) // inverse mod 2**256
                break
            }
        }
    }

    /// @dev Calculates floor(a × b ÷ denominator) with full precision, rounded up.
    /// Throws if result overflows a uint256 or when the denominator is zero.
    /// Credit to Uniswap-v3-core under MIT license:
    /// https://github.com/Uniswap/v3-core/blob/contracts/libraries/FullMath.sol
    function fullMulDivUp(uint256 a, uint256 b, uint256 denominator)
        internal
        pure
        returns (uint256 result)
    {
        result = fullMulDiv(a, b, denominator);
        /// @solidity memory-safe-assembly
        assembly {
            if mulmod(a, b, denominator) {
                if iszero(add(result, 1)) {
                    // Store the function selector of `FullMulDivFailed()`.
                    mstore(0x00, 0xae47f702)
                    // Revert with (offset, size).
                    revert(0x1c, 0x04)
                }
                result := add(result, 1)
            }
        }
    }

    /// @dev Returns `floor(x * y / denominator)`.
    /// Reverts if `x * y` overflows, or `denominator` is zero.
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := div(mul(x, y), denominator)
        }
    }

    /// @dev Returns `ceil(x * y / denominator)`.
    /// Reverts if `x * y` overflows, or `denominator` is zero.
    function mulDivUp(uint256 x, uint256 y, uint256 denominator)
        internal
        pure
        returns (uint256 z)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Equivalent to require(denominator != 0 && (y == 0 || x <= type(uint256).max / y))
            if iszero(mul(denominator, iszero(mul(y, gt(x, div(not(0), y)))))) {
                // Store the function selector of `MulDivFailed()`.
                mstore(0x00, 0xad251c27)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(mul(x, y), denominator))), div(mul(x, y), denominator))
        }
    }

    /// @dev Returns `ceil(x / denominator)`.
    /// Reverts if `denominator` is zero.
    function divUp(uint256 x, uint256 denominator) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(denominator) {
                // Store the function selector of `DivFailed()`.
                mstore(0x00, 0x65244e4e)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            z := add(iszero(iszero(mod(x, denominator))), div(x, denominator))
        }
    }

    /// @dev Returns `max(0, x - y)`.
    function zeroFloorSub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := mul(gt(x, y), sub(x, y))
        }
    }

    /// @dev Returns the square root of `x`.
    function sqrt(uint256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // `floor(sqrt(2**15)) = 181`. `sqrt(2**15) - 181 = 2.84`.
            z := 181 // The "correct" value is 1, but this saves a multiplication later.

            // This segment is to get a reasonable initial estimate for the Babylonian method. With a bad
            // start, the correct # of bits increases ~linearly each iteration instead of ~quadratically.

            // Let `y = x / 2**r`.
            // We check `y >= 2**(k + 8)` but shift right by `k` bits
            // each branch to ensure that if `x >= 256`, then `y >= 256`.
            let r := shl(7, lt(0xffffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffffff, shr(r, x))))
            r := or(r, shl(4, lt(0xffffff, shr(r, x))))
            z := shl(shr(1, r), z)

            // Goal was to get `z*z*y` within a small factor of `x`. More iterations could
            // get y in a tighter range. Currently, we will have y in `[256, 256*(2**16))`.
            // We ensured `y >= 256` so that the relative difference between `y` and `y+1` is small.
            // That's not possible if `x < 256` but we can just verify those cases exhaustively.

            // Now, `z*z*y <= x < z*z*(y+1)`, and `y <= 2**(16+8)`, and either `y >= 256`, or `x < 256`.
            // Correctness can be checked exhaustively for `x < 256`, so we assume `y >= 256`.
            // Then `z*sqrt(y)` is within `sqrt(257)/sqrt(256)` of `sqrt(x)`, or about 20bps.

            // For `s` in the range `[1/256, 256]`, the estimate `f(s) = (181/1024) * (s+1)`
            // is in the range `(1/2.84 * sqrt(s), 2.84 * sqrt(s))`,
            // with largest error when `s = 1` and when `s = 256` or `1/256`.

            // Since `y` is in `[256, 256*(2**16))`, let `a = y/65536`, so that `a` is in `[1/256, 256)`.
            // Then we can estimate `sqrt(y)` using
            // `sqrt(65536) * 181/1024 * (a + 1) = 181/4 * (y + 65536)/65536 = 181 * (y + 65536)/2**18`.

            // There is no overflow risk here since `y < 2**136` after the first branch above.
            z := shr(18, mul(z, add(shr(r, x), 65536))) // A `mul()` is saved from starting `z` at 181.

            // Given the worst case multiplicative error of 2.84 above, 7 iterations should be enough.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // If `x+1` is a perfect square, the Babylonian method cycles between
            // `floor(sqrt(x))` and `ceil(sqrt(x))`. This statement ensures we return floor.
            // See: https://en.wikipedia.org/wiki/Integer_square_root#Using_only_integer_division
            // Since the ceil is rare, we save gas on the assignment and repeat division in the rare case.
            // If you don't care whether the floor or ceil square root is returned, you can remove this statement.
            z := sub(z, lt(div(x, z), z))
        }
    }

    /// @dev Returns the factorial of `x`.
    function factorial(uint256 x) internal pure returns (uint256 result) {
        /// @solidity memory-safe-assembly
        assembly {
            for {} 1 {} {
                if iszero(lt(10, x)) {
                    // forgefmt: disable-next-item
                    result := and(
                        shr(mul(22, x), 0x375f0016260009d80004ec0002d00001e0000180000180000200000400001),
                        0x3fffff
                    )
                    break
                }
                if iszero(lt(57, x)) {
                    let end := 31
                    result := 8222838654177922817725562880000000
                    if iszero(lt(end, x)) {
                        end := 10
                        result := 3628800
                    }
                    for { let w := not(0) } 1 {} {
                        result := mul(result, x)
                        x := add(x, w)
                        if eq(x, end) { break }
                    }
                    break
                }
                // Store the function selector of `FactorialOverflow()`.
                mstore(0x00, 0xaba0f2a2)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Returns the log2 of `x`.
    /// Equivalent to computing the index of the most significant bit (MSB) of `x`.
    function log2(uint256 x) internal pure returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(x) {
                // Store the function selector of `Log2Undefined()`.
                mstore(0x00, 0x5be3aa5c)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            r := shl(7, lt(0xffffffffffffffffffffffffffffffff, x))
            r := or(r, shl(6, lt(0xffffffffffffffff, shr(r, x))))
            r := or(r, shl(5, lt(0xffffffff, shr(r, x))))

            // For the remaining 32 bits, use a De Bruijn lookup.
            // See: https://graphics.stanford.edu/~seander/bithacks.html
            x := shr(r, x)
            x := or(x, shr(1, x))
            x := or(x, shr(2, x))
            x := or(x, shr(4, x))
            x := or(x, shr(8, x))
            x := or(x, shr(16, x))

            // forgefmt: disable-next-item
            r := or(r, byte(shr(251, mul(x, shl(224, 0x07c4acdd))),
                0x0009010a0d15021d0b0e10121619031e080c141c0f111807131b17061a05041f))
        }
    }

    /// @dev Returns the log2 of `x`, rounded up.
    function log2Up(uint256 x) internal pure returns (uint256 r) {
        unchecked {
            uint256 isNotPo2;
            assembly {
                isNotPo2 := iszero(iszero(and(x, sub(x, 1))))
            }
            return log2(x) + isNotPo2;
        }
    }

    /// @dev Returns the averege of `x` and `y`.
    function avg(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := add(and(x, y), shr(1, xor(x, y)))
        }
    }

    /// @dev Returns the absolute value of `x`.
    function abs(int256 x) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let mask := sub(0, shr(255, x))
            z := xor(mask, add(mask, x))
        }
    }

    /// @dev Returns the absolute distance between `x` and `y`.
    function dist(int256 x, int256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            let a := sub(y, x)
            z := xor(a, mul(xor(a, sub(x, y)), sgt(x, y)))
        }
    }

    /// @dev Returns the minimum of `x` and `y`.
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), lt(y, x)))
        }
    }

    /// @dev Returns the maximum of `x` and `y`.
    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            z := xor(x, mul(xor(x, y), gt(y, x)))
        }
    }

    /// @dev Returns gcd of `x` and `y`.
    function gcd(uint256 x, uint256 y) internal pure returns (uint256 z) {
        /// @solidity memory-safe-assembly
        assembly {
            // forgefmt: disable-next-item
            for { z := x } y {} {
                let t := y
                y := mod(z, y)
                z := t
            }
        }
    }

    /// @dev Returns `x`, bounded to `minValue` and `maxValue`.
    function clamp(uint256 x, uint256 minValue, uint256 maxValue)
        internal
        pure
        returns (uint256 z)
    {
        z = min(max(x, minValue), maxValue);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/SafeTransferLib.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Caution! This library won't check that a token has code, responsibility is delegated to the caller.
library SafeTransferLib {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       CUSTOM ERRORS                        */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The ETH transfer has failed.
    error ETHTransferFailed();

    /// @dev The ERC20 `transferFrom` has failed.
    error TransferFromFailed();

    /// @dev The ERC20 `transfer` has failed.
    error TransferFailed();

    /// @dev The ERC20 `approve` has failed.
    error ApproveFailed();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Suggested gas stipend for contract receiving ETH
    /// that disallows any storage writes.
    uint256 internal constant _GAS_STIPEND_NO_STORAGE_WRITES = 2300;

    /// @dev Suggested gas stipend for contract receiving ETH to perform a few
    /// storage reads and writes, but low enough to prevent griefing.
    /// Multiply by a small constant (e.g. 2), if needed.
    uint256 internal constant _GAS_STIPEND_NO_GRIEF = 100000;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                       ETH OPERATIONS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` (in wei) ETH to `to`.
    /// Reverts upon failure.
    function safeTransferETH(address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gas(), to, amount, 0, 0, 0, 0)) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount, uint256 gasStipend) internal {
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(gasStipend, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Force sends `amount` (in wei) ETH to `to`, with a gas stipend
    /// equal to `_GAS_STIPEND_NO_GRIEF`. This gas stipend is a reasonable default
    /// for 99% of cases and can be overriden with the three-argument version of this
    /// function if necessary.
    ///
    /// If sending via the normal procedure fails, force sends the ETH by
    /// creating a temporary contract which uses `SELFDESTRUCT` to force send the ETH.
    ///
    /// Reverts if the current contract has insufficient balance.
    function forceSafeTransferETH(address to, uint256 amount) internal {
        // Manually inlined because the compiler doesn't inline functions with branches.
        /// @solidity memory-safe-assembly
        assembly {
            // If insufficient balance, revert.
            if lt(selfbalance(), amount) {
                // Store the function selector of `ETHTransferFailed()`.
                mstore(0x00, 0xb12d13eb)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Transfer the ETH and check if it succeeded or not.
            if iszero(call(_GAS_STIPEND_NO_GRIEF, to, amount, 0, 0, 0, 0)) {
                mstore(0x00, to) // Store the address in scratch space.
                mstore8(0x0b, 0x73) // Opcode `PUSH20`.
                mstore8(0x20, 0xff) // Opcode `SELFDESTRUCT`.
                // We can directly use `SELFDESTRUCT` in the contract creation.
                // Compatible with `SENDALL`: https://eips.ethereum.org/EIPS/eip-4758
                pop(create(amount, 0x0b, 0x16))
            }
        }
    }

    /// @dev Sends `amount` (in wei) ETH to `to`, with a `gasStipend`.
    /// The `gasStipend` can be set to a low enough value to prevent
    /// storage writes or gas griefing.
    ///
    /// Simply use `gasleft()` for `gasStipend` if you don't need a gas stipend.
    ///
    /// Note: Does NOT revert upon failure.
    /// Returns whether the transfer of ETH is successful instead.
    function trySafeTransferETH(address to, uint256 amount, uint256 gasStipend)
        internal
        returns (bool success)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Transfer the ETH and check if it succeeded or not.
            success := call(gasStipend, to, amount, 0, 0, 0, 0)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                      ERC20 OPERATIONS                      */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Sends `amount` of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            mstore(0x20, from) // Store the `from` argument.
            mstore(0x40, to) // Store the `to` argument.
            mstore(0x60, amount) // Store the `amount` argument.

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends all of ERC20 `token` from `from` to `to`.
    /// Reverts upon failure.
    ///
    /// The `from` account must have at least `amount` approved for
    /// the current contract to manage.
    function safeTransferAllFrom(address token, address from, address to)
        internal
        returns (uint256 amount)
    {
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.

            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, from) // Store the `from` argument.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x60, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            // Store the function selector of `transferFrom(address,address,uint256)`.
            mstore(0x00, 0x23b872dd)
            mstore(0x40, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x6a.
            amount := mload(0x60)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x1c, 0x64, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFromFailed()`.
                mstore(0x00, 0x7939f424)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x60, 0) // Restore the zero slot to zero.
            mstore(0x40, m) // Restore the free memory pointer.
        }
    }

    /// @dev Sends `amount` of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransfer(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1a, to) // Store the `to` argument.
            mstore(0x3a, amount) // Store the `amount` argument.
            // Store the function selector of `transfer(address,uint256)`,
            // left by 6 bytes (enough for 8tb of memory represented by the free memory pointer).
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xa9059cbb000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x16, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev Sends all of ERC20 `token` from the current contract to `to`.
    /// Reverts upon failure.
    function safeTransferAll(address token, address to) internal returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, address()) // Store the address of the current contract.
            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                    staticcall(gas(), token, 0x1c, 0x24, 0x3a, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }

            mstore(0x1a, to) // Store the `to` argument.
            // The `amount` argument is already written to the memory word at 0x3a.
            amount := mload(0x3a)
            // Store the function selector of `transfer(address,uint256)`,
            // left by 6 bytes (enough for 8tb of memory represented by the free memory pointer).
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0xa9059cbb000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x16, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `TransferFailed()`.
                mstore(0x00, 0x90b8ec18)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev Sets `amount` of ERC20 `token` for `to` to manage on behalf of the current contract.
    /// Reverts upon failure.
    function safeApprove(address token, address to, uint256 amount) internal {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x1a, to) // Store the `to` argument.
            mstore(0x3a, amount) // Store the `amount` argument.
            // Store the function selector of `approve(address,uint256)`,
            // left by 6 bytes (enough for 8tb of memory represented by the free memory pointer).
            // We waste 6-3 = 3 bytes to save on 6 runtime gas (PUSH1 0x224 SHL).
            mstore(0x00, 0x095ea7b3000000000000)

            if iszero(
                and( // The arguments of `and` are evaluated from right to left.
                    // Set success to whether the call reverted, if not we check it either
                    // returned exactly 1 (can't just be non-zero data), or had no return data.
                    or(eq(mload(0x00), 1), iszero(returndatasize())),
                    call(gas(), token, 0, 0x16, 0x44, 0x00, 0x20)
                )
            ) {
                // Store the function selector of `ApproveFailed()`.
                mstore(0x00, 0x3e3f8f73)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the part of the free memory pointer that was overwritten,
            // which is guaranteed to be zero, if less than 8tb of memory is used.
            mstore(0x3a, 0)
        }
    }

    /// @dev Returns the amount of ERC20 `token` owned by `account`.
    /// Returns zero if the `token` does not exist.
    function balanceOf(address token, address account) internal view returns (uint256 amount) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, 0x70a08231) // Store the function selector of `balanceOf(address)`.
            mstore(0x20, account) // Store the `account` argument.
            amount :=
                mul(
                    mload(0x20),
                    and( // The arguments of `and` are evaluated from right to left.
                        gt(returndatasize(), 0x1f), // At least 32 bytes returned.
                        staticcall(gas(), token, 0x1c, 0x24, 0x20, 0x20)
                    )
                )
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

// Our gas-optimized implementation of forge-std's StdMath library
// We should inherit and override the relevant functions in the future when they make them virtual
library StdMath {
    uint256 private constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function delta(uint256 a, uint256 b) internal pure returns (uint256) {
        // SAFETY: The subtraction can never underflow as we explicitly sub the
        // smaller value from the larger.
        unchecked {
            return a > b ? a - b : b - a;
        }
    }

    /// @dev multiplication will not overflow as long as the absolute difference between `a` and `b` is
    /// less than type(uint256).max / WAD, i.e. around uint196
    function percentDelta(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 absDelta = delta(a, b);
        return absDelta * WAD / b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import "src/libraries/LogExpMath.sol";

/**
 * @dev Library for encoding and decoding values stored inside a 256 bit word. Typically used to pack multiple values in
 * a single storage slot, saving gas by performing less storage accesses.
 *
 * Each value is defined by its size and the least significant bit in the word, also known as offset. For example, two
 * 128 bit values may be encoded in a word by assigning one an offset of 0, and the other an offset of 128.
 */
library LogCompression {
    int256 private constant _LOG_COMPRESSION_FACTOR = 1e14;
    int256 private constant _HALF_LOG_COMPRESSION_FACTOR = 0.5e14;

    /**
     * @dev Returns the natural logarithm of `value`, dropping most of the decimal places to arrive at a value that,
     * when passed to `fromLowResLog`, will have a maximum relative error of ~0.05% compared to `value`.
     *
     * Values returned from this function should not be mixed with other fixed-point values (as they have a different
     * number of digits), but can be added or subtracted. Use `fromLowResLog` to undo this process and return to an
     * 18 decimal places fixed point value.
     *
     * Because so much precision is lost, the logarithmic values can be stored using much fewer bits than the original
     * value required.
     */
    function toLowResLog(uint256 value) internal pure returns (int256) {
        unchecked {
            int256 ln = LogExpMath.ln(int256(value));

            // Rounding division for signed numerator
            int256 lnWithError = (ln > 0 ? ln + _HALF_LOG_COMPRESSION_FACTOR : ln - _HALF_LOG_COMPRESSION_FACTOR);
            return lnWithError / _LOG_COMPRESSION_FACTOR;
        }
    }

    /**
     * @dev Restores `value` from logarithmic space. `value` is expected to be the result of a call to `toLowResLog`,
     * any other function that returns 4 decimals fixed point logarithms, or the sum of such values.
     */
    function fromLowResLog(int256 value) internal pure returns (uint256) {
        unchecked {
            return uint256(LogExpMath.exp(value * _LOG_COMPRESSION_FACTOR));
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { IAssetManagedPair } from "src/interfaces/IAssetManagedPair.sol";

interface IAssetManager {
    function getBalance(IAssetManagedPair owner, IERC20 token) external returns (uint256 tokenBalance);

    /// @notice called by the pair after mint/burn events to automatically re-balance the amount managed
    /// according to the lower and upper thresholds
    function afterLiquidityEvent() external;

    /// @notice called by the pair when it requires assets managed by the manager to be returned to the pair
    /// in order to fulfill swap requests or burn requests
    function returnAsset(bool aToken0, uint256 aAmount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IERC20 } from "forge-std/interfaces/IERC20.sol";

import { IAssetManager } from "src/interfaces/IAssetManager.sol";

interface IAssetManagedPair {
    event AssetManager(IAssetManager manager);

    function token0Managed() external view returns (uint104);
    function token1Managed() external view returns (uint104);

    function token0() external view returns (IERC20);
    function token1() external view returns (IERC20);

    function getReserves()
        external
        view
        returns (uint104 rReserve0, uint104 rReserve1, uint32 rBlockTimestampLast, uint16 rIndex);

    function assetManager() external view returns (IAssetManager);
    function setManager(IAssetManager manager) external;

    function adjustManagement(int256 token0Change, int256 token1Change) external;
    function skimExcessManaged(IERC20 aToken) external returns (uint256 rAmtSkimmed);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

struct Observation {
    // natural log (ln) of the raw accumulated price (token1/token0)
    int112 logAccRawPrice;
    // natural log (ln) of the clamped accumulated price (token1/token0)
    // in the case of maximum price supported by the oracle (~2.87e56 == e ** 130.0000)
    // (1300000) 21 bits multiplied by 32 bits of the timestamp gives 53 bits
    // which fits into int56
    int56 logAccClampedPrice;
    // natural log (ln) of the accumulated liquidity (sqrt(x * y))
    // in the case of maximum liq (sqrt(uint104 * uint104) == 5.192e33 == e ** 77.5325)
    // (775325) 20 bits multiplied by 32 bits of the timestamp gives 52 bits
    // which fits into int56
    int56 logAccLiquidity;
    // overflows every 136 years, in the year 2106
    uint32 timestamp;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

struct Slot0 {
    uint104 reserve0;
    uint104 reserve1;
    uint32 packedTimestamp;
    uint16 index;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { ERC20 } from "solmate/tokens/ERC20.sol";

// solhint-disable-next-line no-empty-blocks
contract ReservoirERC20 is ERC20("Reservoir LP Token", "RES-LP", 18) {
// no additional initialization is required as all constructor logic is in ERC20
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { IReservoirCallee } from "src/interfaces/IReservoirCallee.sol";
import { IGenericFactory } from "src/interfaces/IGenericFactory.sol";

import { Bytes32Lib } from "src/libraries/Bytes32.sol";
import { FactoryStoreLib } from "src/libraries/FactoryStore.sol";

import { ReservoirPair, Slot0, Observation, IERC20 } from "src/ReservoirPair.sol";
import { StableMath } from "src/libraries/StableMath.sol";
import { StableOracleMath } from "src/libraries/StableOracleMath.sol";
import { ConstantProductOracleMath } from "src/libraries/ConstantProductOracleMath.sol";

import { AmplificationData } from "src/structs/AmplificationData.sol";

contract StablePair is ReservoirPair {
    using FactoryStoreLib for IGenericFactory;
    using Bytes32Lib for bytes32;

    // solhint-disable-next-line var-name-mixedcase
    address private immutable MINT_BURN_LOGIC;

    string private constant PAIR_SWAP_FEE_NAME = "SP::swapFee";
    string private constant AMPLIFICATION_COEFFICIENT_NAME = "SP::amplificationCoefficient";

    event RampA(uint64 initialAPrecise, uint64 futureAPrecise, uint64 initialTime, uint64 futureTime);
    event StopRampA(uint64 currentAPrecise, uint64 time);

    AmplificationData public ampData;

    // We need the 2 variables below to calculate the growth in liquidity between
    // minting and burning, for the purpose of calculating platformFee.
    uint192 public lastInvariant;
    uint64 public lastInvariantAmp;

    constructor(IERC20 aToken0, IERC20 aToken1)
        ReservoirPair(aToken0, aToken1, PAIR_SWAP_FEE_NAME, _isStableMintBurn(aToken0, aToken1) ? false : true)
    {
        bool lIsStableMintBurn = _isStableMintBurn(aToken0, aToken1);

        MINT_BURN_LOGIC = lIsStableMintBurn ? address(0) : address(factory.stableMintBurn());

        if (!lIsStableMintBurn) {
            require(MINT_BURN_LOGIC.code.length > 0, "SP: MINT_BURN_NOT_DEPLOYED");
            ampData.initialA = factory.read(AMPLIFICATION_COEFFICIENT_NAME).toUint64() * uint64(StableMath.A_PRECISION);
            ampData.futureA = ampData.initialA;
            ampData.initialATime = uint64(block.timestamp);
            ampData.futureATime = uint64(block.timestamp);

            require(
                ampData.initialA >= StableMath.MIN_A * uint64(StableMath.A_PRECISION)
                    && ampData.initialA <= StableMath.MAX_A * uint64(StableMath.A_PRECISION),
                "SP: INVALID_A"
            );
        }
    }

    function _isStableMintBurn(IERC20 aToken0, IERC20 aToken1) private pure returns (bool) {
        return address(aToken0) == address(0) && address(aToken1) == address(0);
    }

    function rampA(uint64 aFutureARaw, uint64 aFutureATime) external onlyFactory {
        require(aFutureARaw >= StableMath.MIN_A && aFutureARaw <= StableMath.MAX_A, "SP: INVALID_A");

        uint64 lFutureAPrecise = aFutureARaw * uint64(StableMath.A_PRECISION);

        uint256 duration = aFutureATime - block.timestamp;
        require(duration >= StableMath.MIN_RAMP_TIME, "SP: INVALID_DURATION");

        uint64 lCurrentAPrecise = _getCurrentAPrecise();

        // Daily rate = (futureA / currentA) / duration * 1 day.
        require(
            lFutureAPrecise > lCurrentAPrecise
                ? lFutureAPrecise * 1 days <= lCurrentAPrecise * duration * StableMath.MAX_AMP_UPDATE_DAILY_RATE
                : lCurrentAPrecise * 1 days <= lFutureAPrecise * duration * StableMath.MAX_AMP_UPDATE_DAILY_RATE,
            "SP: AMP_RATE_TOO_HIGH"
        );

        ampData.initialA = lCurrentAPrecise;
        ampData.futureA = lFutureAPrecise;
        ampData.initialATime = uint64(block.timestamp);
        ampData.futureATime = aFutureATime;

        emit RampA(lCurrentAPrecise, lFutureAPrecise, uint64(block.timestamp), aFutureATime);
    }

    function stopRampA() external onlyFactory {
        uint64 lCurrentAPrecise = _getCurrentAPrecise();

        ampData.initialA = lCurrentAPrecise;
        ampData.futureA = lCurrentAPrecise;
        uint64 lTimestamp = uint64(block.timestamp);
        ampData.initialATime = lTimestamp;
        ampData.futureATime = lTimestamp;

        emit StopRampA(lCurrentAPrecise, lTimestamp);
    }

    function _delegateToMintBurn() internal {
        address lTarget = MINT_BURN_LOGIC;

        // SAFETY:
        // The delegated call has the same signature as the calling function and both the calldata
        // and returndata do not exceed 64 bytes. This is only valid when lTarget == MINT_BURN_LOGIC.
        assembly ("memory-safe") {
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), lTarget, 0, calldatasize(), 0, 0)

            returndatacopy(0, 0, returndatasize())

            if success { return(0, returndatasize()) }
            revert(0, returndatasize())
        }
    }

    function mint(address) external virtual override returns (uint256) {
        _delegateToMintBurn();
    }

    function burn(address) external virtual override returns (uint256, uint256) {
        _delegateToMintBurn();
    }

    function mintFee(uint256, uint256) external virtual returns (uint256, uint256) {
        _delegateToMintBurn();
    }

    function swap(int256 aAmount, bool aExactIn, address aTo, bytes calldata aData)
        external
        virtual
        override
        returns (uint256 rAmountOut)
    {
        (Slot0 storage sSlot0, uint256 lReserve0, uint256 lReserve1, uint32 lBlockTimestampLast,) = _lockAndLoad();
        require(aAmount != 0, "SP: AMOUNT_ZERO");
        uint256 lAmountIn;
        IERC20 lTokenOut;

        if (aExactIn) {
            // swap token0 exact in for token1 variable out
            if (aAmount > 0) {
                lTokenOut = token1();
                lAmountIn = uint256(aAmount);
                rAmountOut = _getAmountOut(lAmountIn, lReserve0, lReserve1, true);
            }
            // swap token1 exact in for token0 variable out
            else {
                lTokenOut = token0();
                unchecked {
                    lAmountIn = uint256(-aAmount);
                }
                rAmountOut = _getAmountOut(lAmountIn, lReserve0, lReserve1, false);
            }
        } else {
            // swap token1 variable in for token0 exact out
            if (aAmount > 0) {
                rAmountOut = uint256(aAmount);
                require(rAmountOut < lReserve0, "SP: NOT_ENOUGH_LIQ");
                lTokenOut = token0();
                lAmountIn = _getAmountIn(rAmountOut, lReserve0, lReserve1, true);
            }
            // swap token0 variable in for token1 exact out
            else {
                unchecked {
                    rAmountOut = uint256(-aAmount);
                }
                require(rAmountOut < lReserve1, "SP: NOT_ENOUGH_LIQ");
                lTokenOut = token1();
                lAmountIn = _getAmountIn(rAmountOut, lReserve0, lReserve1, false);
            }
        }

        _checkedTransfer(lTokenOut, aTo, rAmountOut, lReserve0, lReserve1);

        if (aData.length > 0) {
            IReservoirCallee(aTo).reservoirCall(
                msg.sender,
                lTokenOut == token0() ? int256(rAmountOut) : -int256(lAmountIn),
                lTokenOut == token1() ? int256(rAmountOut) : -int256(lAmountIn),
                aData
            );
        }

        uint256 lBalance0 = _totalToken0();
        uint256 lBalance1 = _totalToken1();

        uint256 lReceived = lTokenOut == token0() ? lBalance1 - lReserve1 : lBalance0 - lReserve0;
        require(lReceived >= lAmountIn, "SP: INSUFFICIENT_AMOUNT_IN");

        _updateAndUnlock(sSlot0, lBalance0, lBalance1, uint104(lReserve0), uint104(lReserve1), lBlockTimestampLast);
        emit Swap(msg.sender, lTokenOut == token1(), lReceived, rAmountOut, aTo);
    }

    function _getAmountOut(uint256 aAmountIn, uint256 aReserve0, uint256 aReserve1, bool aToken0In)
        private
        view
        returns (uint256)
    {
        return StableMath._getAmountOut(
            aAmountIn,
            aReserve0,
            aReserve1,
            token0PrecisionMultiplier(),
            token1PrecisionMultiplier(),
            aToken0In,
            swapFee,
            _getNA()
        );
    }

    function _getAmountIn(uint256 aAmountOut, uint256 aReserve0, uint256 aReserve1, bool aToken0Out)
        private
        view
        returns (uint256)
    {
        return StableMath._getAmountIn(
            aAmountOut,
            aReserve0,
            aReserve1,
            token0PrecisionMultiplier(),
            token1PrecisionMultiplier(),
            aToken0Out,
            swapFee,
            _getNA()
        );
    }

    /// @notice Get D, the StableSwap invariant, based on a set of balances and a particular A.
    /// See the StableSwap paper for details.
    /// @dev Originally
    /// https://github.com/saddle-finance/saddle-contract/blob/0b76f7fb519e34b878aa1d58cffc8d8dc0572c12/contracts/SwapUtils.sol#L319.
    /// @return rLiquidity The invariant, at the precision of the pool.
    function _computeLiquidity(uint256 aReserve0, uint256 aReserve1) internal view returns (uint256 rLiquidity) {
        unchecked {
            uint256 adjustedReserve0 = aReserve0 * token0PrecisionMultiplier();
            uint256 adjustedReserve1 = aReserve1 * token1PrecisionMultiplier();
            rLiquidity = StableMath._computeLiquidityFromAdjustedBalances(adjustedReserve0, adjustedReserve1, _getNA());
        }
    }

    function _getCurrentAPrecise() internal view returns (uint64 rCurrentA) {
        uint64 futureA = ampData.futureA;
        uint64 futureATime = ampData.futureATime;

        if (block.timestamp < futureATime) {
            uint64 initialA = ampData.initialA;
            uint64 initialATime = ampData.initialATime;
            uint64 rampDuration = futureATime - initialATime;
            uint64 rampElapsed = uint64(block.timestamp) - initialATime;

            if (futureA > initialA) {
                uint64 rampDelta = futureA - initialA;
                rCurrentA = initialA + rampElapsed * rampDelta / rampDuration;
            } else {
                uint64 rampDelta = initialA - futureA;
                rCurrentA = initialA - rampElapsed * rampDelta / rampDuration;
            }
        } else {
            rCurrentA = futureA;
        }
    }

    /// @dev number of coins in the pool multiplied by A precise
    function _getNA() internal view returns (uint256) {
        return 2 * _getCurrentAPrecise();
    }

    function getCurrentA() external view returns (uint64) {
        return _getCurrentAPrecise() / uint64(StableMath.A_PRECISION);
    }

    function getCurrentAPrecise() external view returns (uint64) {
        return _getCurrentAPrecise();
    }

    /*//////////////////////////////////////////////////////////////////////////
                                ORACLE METHODS
    //////////////////////////////////////////////////////////////////////////*/

    function _updateOracle(uint256 aReserve0, uint256 aReserve1, uint32 aTimeElapsed, uint32 aTimestampLast)
        internal
        override
    {
        Observation storage previous = _observations[_slot0.index];

        (uint256 currRawPrice, int112 currLogRawPrice) = StableOracleMath.calcLogPrice(
            _getCurrentAPrecise(), aReserve0 * token0PrecisionMultiplier(), aReserve1 * token1PrecisionMultiplier()
        );
        (uint256 currClampedPrice, int112 currLogClampedPrice) =
            _calcClampedPrice(currRawPrice, prevClampedPrice, aTimeElapsed);
        int112 currLogLiq = ConstantProductOracleMath.calcLogLiq(aReserve0, aReserve1);
        prevClampedPrice = currClampedPrice;

        // overflow is desired here as the consumer of the oracle will be reading the difference in those accumulated log values
        // when the index overflows it will overwrite the oldest observation to form a loop
        unchecked {
            int112 logAccRawPrice = previous.logAccRawPrice + currLogRawPrice * int112(int256(uint256(aTimeElapsed)));
            int56 logAccClampedPrice =
                previous.logAccClampedPrice + int56(currLogClampedPrice) * int56(int256(uint256(aTimeElapsed)));
            int56 logAccLiq = previous.logAccLiquidity + int56(currLogLiq) * int56(int256(uint256(aTimeElapsed)));
            _slot0.index += 1;
            _observations[_slot0.index] = Observation(logAccRawPrice, logAccClampedPrice, logAccLiq, aTimestampLast);
        }
    }
}

// SPDX-License-Identifier: MIT
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
// documentation files (the “Software”), to deal in the Software without restriction, including without limitation
// the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to the following conditions:

// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the
// Software.

// THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO
// THE
// WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
// OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.8.0;

/* solhint-disable */

/**
 * @dev Exponentiation and logarithm functions for 18 decimal fixed point numbers (both base and exponent/argument).
 *
 * Exponentiation and logarithm with arbitrary bases (x^y and log_x(y)) are implemented by conversion to natural
 * exponentiation and logarithm (where the base is Euler's number).
 *
 * @author Fernando Martinelli - @fernandomartinelli
 * @author Sergio Yuhjtman - @sergioyuhjtman
 * @author Daniel Fernandez - @dmf7z
 */
library LogExpMath {
    // All fixed point multiplications and divisions are inlined. This means we need to divide by ONE when multiplying
    // two numbers, and multiply by ONE when dividing them.

    // All arguments and return values are 18 decimal fixed point numbers.
    int256 constant ONE_18 = 1e18;

    // Internally, intermediate values are computed with higher precision as 20 decimal fixed point numbers, and in the
    // case of ln36, 36 decimals.
    int256 constant ONE_20 = 1e20;
    int256 constant ONE_36 = 1e36;

    // The domain of natural exponentiation is bound by the word size and number of decimals used.
    //
    // Because internally the result will be stored using 20 decimals, the largest possible result is
    // (2^255 - 1) / 10^20, which makes the largest exponent ln((2^255 - 1) / 10^20) = 130.700829182905140221.
    // The smallest possible result is 10^(-18), which makes largest negative argument
    // ln(10^(-18)) = -41.446531673892822312.
    // We use 130.0 and -41.0 to have some safety margin.
    int256 constant MAX_NATURAL_EXPONENT = 130e18;
    int256 constant MIN_NATURAL_EXPONENT = -41e18;

    // Bounds for ln_36's argument. Both ln(0.9) and ln(1.1) can be represented with 36 decimal places in a fixed point
    // 256 bit integer.
    int256 constant LN_36_LOWER_BOUND = ONE_18 - 1e17;
    int256 constant LN_36_UPPER_BOUND = ONE_18 + 1e17;

    uint256 constant MILD_EXPONENT_BOUND = 2 ** 254 / uint256(ONE_20);

    // 18 decimal constants
    int256 constant x0 = 128_000_000_000_000_000_000; // 2ˆ7
    int256 constant a0 = 38_877_084_059_945_950_922_200_000_000_000_000_000_000_000_000_000_000_000; // eˆ(x0) (no
        // decimals)
    int256 constant x1 = 64_000_000_000_000_000_000; // 2ˆ6
    int256 constant a1 = 6_235_149_080_811_616_882_910_000_000; // eˆ(x1) (no decimals)

    // 20 decimal constants
    int256 constant x2 = 3_200_000_000_000_000_000_000; // 2ˆ5
    int256 constant a2 = 7_896_296_018_268_069_516_100_000_000_000_000; // eˆ(x2)
    int256 constant x3 = 1_600_000_000_000_000_000_000; // 2ˆ4
    int256 constant a3 = 888_611_052_050_787_263_676_000_000; // eˆ(x3)
    int256 constant x4 = 800_000_000_000_000_000_000; // 2ˆ3
    int256 constant a4 = 298_095_798_704_172_827_474_000; // eˆ(x4)
    int256 constant x5 = 400_000_000_000_000_000_000; // 2ˆ2
    int256 constant a5 = 5_459_815_003_314_423_907_810; // eˆ(x5)
    int256 constant x6 = 200_000_000_000_000_000_000; // 2ˆ1
    int256 constant a6 = 738_905_609_893_065_022_723; // eˆ(x6)
    int256 constant x7 = 100_000_000_000_000_000_000; // 2ˆ0
    int256 constant a7 = 271_828_182_845_904_523_536; // eˆ(x7)
    int256 constant x8 = 50_000_000_000_000_000_000; // 2ˆ-1
    int256 constant a8 = 164_872_127_070_012_814_685; // eˆ(x8)
    int256 constant x9 = 25_000_000_000_000_000_000; // 2ˆ-2
    int256 constant a9 = 128_402_541_668_774_148_407; // eˆ(x9)
    int256 constant x10 = 12_500_000_000_000_000_000; // 2ˆ-3
    int256 constant a10 = 113_314_845_306_682_631_683; // eˆ(x10)
    int256 constant x11 = 6_250_000_000_000_000_000; // 2ˆ-4
    int256 constant a11 = 106_449_445_891_785_942_956; // eˆ(x11)

    /**
     * @dev Exponentiation (x^y) with unsigned 18 decimal fixed point base and exponent.
     *
     * Reverts if ln(x) * y is smaller than `MIN_NATURAL_EXPONENT`, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function pow(uint256 x, uint256 y) internal pure returns (uint256) {
        unchecked {
            if (y == 0) {
                // We solve the 0^0 indetermination by making it equal one.
                return uint256(ONE_18);
            }

            if (x == 0) {
                return 0;
            }

            // Instead of computing x^y directly, we instead rely on the properties of logarithms and exponentiation to
            // arrive at that result. In particular, exp(ln(x)) = x, and ln(x^y) = y * ln(x). This means
            // x^y = exp(y * ln(x)).

            // The ln function takes a signed value, so we need to make sure x fits in the signed 256 bit range.
            require(x < 2 ** 255, "EM: X_OUT_OF_BOUNDS");
            int256 x_int256 = int256(x);

            // We will compute y * ln(x) in a single step. Depending on the value of x, we can either use ln or ln_36. In
            // both cases, we leave the division by ONE_18 (due to fixed point multiplication) to the end.

            // This prevents y * ln(x) from overflowing, and at the same time guarantees y fits in the signed 256 bit
            // range.
            require(y < MILD_EXPONENT_BOUND, "EM: Y_OUT_OF_BOUNDS");
            int256 y_int256 = int256(y);

            int256 logx_times_y;
            if (LN_36_LOWER_BOUND < x_int256 && x_int256 < LN_36_UPPER_BOUND) {
                int256 ln_36_x = _ln_36(x_int256);

                // ln_36_x has 36 decimal places, so multiplying by y_int256 isn't as straightforward, since we can't
                // just
                // bring y_int256 to 36 decimal places, as it might overflow. Instead, we perform two 18 decimal
                // multiplications and add the results: one with the first 18 decimals of ln_36_x, and one with the
                // (downscaled) last 18 decimals.
                logx_times_y = ((ln_36_x / ONE_18) * y_int256 + ((ln_36_x % ONE_18) * y_int256) / ONE_18);
            } else {
                logx_times_y = _ln(x_int256) * y_int256;
            }
            logx_times_y /= ONE_18;

            // Finally, we compute exp(y * ln(x)) to arrive at x^y
            require(
                MIN_NATURAL_EXPONENT <= logx_times_y && logx_times_y <= MAX_NATURAL_EXPONENT,
                "EM: PRODUCT_OUT_OF_BOUNDS"
            );

            return uint256(exp(logx_times_y));
        }
    }

    /**
     * @dev Natural exponentiation (e^x) with signed 18 decimal fixed point exponent.
     *
     * Reverts if `x` is smaller than MIN_NATURAL_EXPONENT, or larger than `MAX_NATURAL_EXPONENT`.
     */
    function exp(int256 x) internal pure returns (int256) {
        unchecked {
            require(x >= MIN_NATURAL_EXPONENT && x <= MAX_NATURAL_EXPONENT, "EM: INVALID_EXPONENT");
            if (x < 0) {
                // We only handle positive exponents: e^(-x) is computed as 1 / e^x. We can safely make x positive since
                // it
                // fits in the signed 256 bit range (as it is larger than MIN_NATURAL_EXPONENT).
                // Fixed point division requires multiplying by ONE_18.
                return ((ONE_18 * ONE_18) / exp(-x));
            }

            // First, we use the fact that e^(x+y) = e^x * e^y to decompose x into a sum of powers of two, which we call
            // x_n,
            // where x_n == 2^(7 - n), and e^x_n = a_n has been precomputed. We choose the first x_n, x0, to equal 2^7
            // because all larger powers are larger than MAX_NATURAL_EXPONENT, and therefore not present in the
            // decomposition.
            // At the end of this process we will have the product of all e^x_n = a_n that apply, and the remainder of
            // this
            // decomposition, which will be lower than the smallest x_n.
            // exp(x) = k_0 * a_0 * k_1 * a_1 * ... + k_n * a_n * exp(remainder), where each k_n equals either 0 or 1.
            // We mutate x by subtracting x_n, making it the remainder of the decomposition.

            // The first two a_n (e^(2^7) and e^(2^6)) are too large if stored as 18 decimal numbers, and could cause
            // intermediate overflows. Instead we store them as plain integers, with 0 decimals.
            // Additionally, x0 + x1 is larger than MAX_NATURAL_EXPONENT, which means they will not both be present in
            // the
            // decomposition.

            // For each x_n, we test if that term is present in the decomposition (if x is larger than it), and if so
            // deduct
            // it and compute the accumulated product.

            int256 firstAN;
            if (x >= x0) {
                x -= x0;
                firstAN = a0;
            } else if (x >= x1) {
                x -= x1;
                firstAN = a1;
            } else {
                firstAN = 1; // One with no decimal places
            }

            // We now transform x into a 20 decimal fixed point number, to have enhanced precision when computing the
            // smaller terms.
            x *= 100;

            // `product` is the accumulated product of all a_n (except a0 and a1), which starts at 20 decimal fixed
            // point
            // one. Recall that fixed point multiplication requires dividing by ONE_20.
            int256 product = ONE_20;

            if (x >= x2) {
                x -= x2;
                product = (product * a2) / ONE_20;
            }
            if (x >= x3) {
                x -= x3;
                product = (product * a3) / ONE_20;
            }
            if (x >= x4) {
                x -= x4;
                product = (product * a4) / ONE_20;
            }
            if (x >= x5) {
                x -= x5;
                product = (product * a5) / ONE_20;
            }
            if (x >= x6) {
                x -= x6;
                product = (product * a6) / ONE_20;
            }
            if (x >= x7) {
                x -= x7;
                product = (product * a7) / ONE_20;
            }
            if (x >= x8) {
                x -= x8;
                product = (product * a8) / ONE_20;
            }
            if (x >= x9) {
                x -= x9;
                product = (product * a9) / ONE_20;
            }

            // x10 and x11 are unnecessary here since we have high enough precision already.

            // Now we need to compute e^x, where x is small (in particular, it is smaller than x9). We use the Taylor
            // series
            // expansion for e^x: 1 + x + (x^2 / 2!) + (x^3 / 3!) + ... + (x^n / n!).

            int256 seriesSum = ONE_20; // The initial one in the sum, with 20 decimal places.
            int256 term; // Each term in the sum, where the nth term is (x^n / n!).

            // The first term is simply x.
            term = x;
            seriesSum += term;

            // Each term (x^n / n!) equals the previous one times x, divided by n. Since x is a fixed point number,
            // multiplying by it requires dividing by ONE_20, but dividing by the non-fixed point n values does not.

            term = ((term * x) / ONE_20) / 2;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 3;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 4;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 5;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 6;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 7;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 8;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 9;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 10;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 11;
            seriesSum += term;

            term = ((term * x) / ONE_20) / 12;
            seriesSum += term;

            // 12 Taylor terms are sufficient for 18 decimal precision.

            // We now have the first a_n (with no decimals), and the product of all other a_n present, and the Taylor
            // approximation of the exponentiation of the remainder (both with 20 decimals). All that remains is to
            // multiply
            // all three (one 20 decimal fixed point multiplication, dividing by ONE_20, and one integer
            // multiplication),
            // and then drop two digits to return an 18 decimal value.

            return (((product * seriesSum) / ONE_20) * firstAN) / 100;
        }
    }

    /**
     * @dev Logarithm (log(arg, base), with signed 18 decimal fixed point base and argument.
     */
    function log(int256 arg, int256 base) internal pure returns (int256) {
        unchecked {
            // This performs a simple base change: log(arg, base) = ln(arg) / ln(base).

            // Both logBase and logArg are computed as 36 decimal fixed point numbers, either by using ln_36, or by
            // upscaling.

            int256 logBase;
            if (LN_36_LOWER_BOUND < base && base < LN_36_UPPER_BOUND) {
                logBase = _ln_36(base);
            } else {
                logBase = _ln(base) * ONE_18;
            }

            int256 logArg;
            if (LN_36_LOWER_BOUND < arg && arg < LN_36_UPPER_BOUND) {
                logArg = _ln_36(arg);
            } else {
                logArg = _ln(arg) * ONE_18;
            }

            // When dividing, we multiply by ONE_18 to arrive at a result with 18 decimal places
            return (logArg * ONE_18) / logBase;
        }
    }

    /**
     * @dev Natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function ln(int256 a) internal pure returns (int256) {
        unchecked {
            // The real natural logarithm is not defined for negative numbers or zero.
            require(a > 0, "EM: OUT_OF_BOUNDS");

            if (LN_36_LOWER_BOUND < a && a < LN_36_UPPER_BOUND) {
                return _ln_36(a) / ONE_18;
            } else {
                return _ln(a);
            }
        }
    }

    /**
     * @dev Internal natural logarithm (ln(a)) with signed 18 decimal fixed point argument.
     */
    function _ln(int256 a) private pure returns (int256) {
        unchecked {
            if (a < ONE_18) {
                // Since ln(a^k) = k * ln(a), we can compute ln(a) as ln(a) = ln((1/a)^(-1)) = - ln((1/a)). If a is less
                // than one, 1/a will be greater than one, and this if statement will not be entered in the recursive
                // call.
                // Fixed point division requires multiplying by ONE_18.
                return (-_ln((ONE_18 * ONE_18) / a));
            }

            // First, we use the fact that ln^(a * b) = ln(a) + ln(b) to decompose ln(a) into a sum of powers of two,
            // which
            // we call x_n, where x_n == 2^(7 - n), which are the natural logarithm of precomputed quantities a_n (that
            // is,
            // ln(a_n) = x_n). We choose the first x_n, x0, to equal 2^7 because the exponential of all larger powers
            // cannot
            // be represented as 18 fixed point decimal numbers in 256 bits, and are therefore larger than a.
            // At the end of this process we will have the sum of all x_n = ln(a_n) that apply, and the remainder of
            // this
            // decomposition, which will be lower than the smallest a_n.
            // ln(a) = k_0 * x_0 + k_1 * x_1 + ... + k_n * x_n + ln(remainder), where each k_n equals either 0 or 1.
            // We mutate a by subtracting a_n, making it the remainder of the decomposition.

            // For reasons related to how `exp` works, the first two a_n (e^(2^7) and e^(2^6)) are not stored as fixed
            // point
            // numbers with 18 decimals, but instead as plain integers with 0 decimals, so we need to multiply them by
            // ONE_18 to convert them to fixed point.
            // For each a_n, we test if that term is present in the decomposition (if a is larger than it), and if so
            // divide
            // by it and compute the accumulated sum.

            int256 sum = 0;
            if (a >= a0 * ONE_18) {
                a /= a0; // Integer, not fixed point division
                sum += x0;
            }

            if (a >= a1 * ONE_18) {
                a /= a1; // Integer, not fixed point division
                sum += x1;
            }

            // All other a_n and x_n are stored as 20 digit fixed point numbers, so we convert the sum and a to this
            // format.
            sum *= 100;
            a *= 100;

            // Because further a_n are  20 digit fixed point numbers, we multiply by ONE_20 when dividing by them.

            if (a >= a2) {
                a = (a * ONE_20) / a2;
                sum += x2;
            }

            if (a >= a3) {
                a = (a * ONE_20) / a3;
                sum += x3;
            }

            if (a >= a4) {
                a = (a * ONE_20) / a4;
                sum += x4;
            }

            if (a >= a5) {
                a = (a * ONE_20) / a5;
                sum += x5;
            }

            if (a >= a6) {
                a = (a * ONE_20) / a6;
                sum += x6;
            }

            if (a >= a7) {
                a = (a * ONE_20) / a7;
                sum += x7;
            }

            if (a >= a8) {
                a = (a * ONE_20) / a8;
                sum += x8;
            }

            if (a >= a9) {
                a = (a * ONE_20) / a9;
                sum += x9;
            }

            if (a >= a10) {
                a = (a * ONE_20) / a10;
                sum += x10;
            }

            if (a >= a11) {
                a = (a * ONE_20) / a11;
                sum += x11;
            }

            // a is now a small number (smaller than a_11, which roughly equals 1.06). This means we can use a Taylor
            // series
            // that converges rapidly for values of `a` close to one - the same one used in ln_36.
            // Let z = (a - 1) / (a + 1).
            // ln(a) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 20 digit fixed point division requires multiplying by ONE_20, and multiplication requires
            // division by ONE_20.
            int256 z = ((a - ONE_20) * ONE_20) / (a + ONE_20);
            int256 z_squared = (z * z) / ONE_20;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_20;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_20;
            seriesSum += num / 11;

            // 6 Taylor terms are sufficient for 36 decimal precision.

            // Finally, we multiply by 2 (non fixed point) to compute ln(remainder)
            seriesSum *= 2;

            // We now have the sum of all x_n present, and the Taylor approximation of the logarithm of the remainder
            // (both
            // with 20 decimals). All that remains is to sum these two, and then drop two digits to return a 18 decimal
            // value.

            return (sum + seriesSum) / 100;
        }
    }

    /**
     * @dev Intrnal high precision (36 decimal places) natural logarithm (ln(x)) with signed 18 decimal fixed point
     * argument,
     * for x close to one.
     *
     * Should only be used if x is between LN_36_LOWER_BOUND and LN_36_UPPER_BOUND.
     */
    function _ln_36(int256 x) private pure returns (int256) {
        unchecked {
            // Since ln(1) = 0, a value of x close to one will yield a very small result, which makes using 36 digits
            // worthwhile.

            // First, we transform x to a 36 digit fixed point value.
            x *= ONE_18;

            // We will use the following Taylor expansion, which converges very rapidly. Let z = (x - 1) / (x + 1).
            // ln(x) = 2 * (z + z^3 / 3 + z^5 / 5 + z^7 / 7 + ... + z^(2 * n + 1) / (2 * n + 1))

            // Recall that 36 digit fixed point division requires multiplying by ONE_36, and multiplication requires
            // division by ONE_36.
            int256 z = ((x - ONE_36) * ONE_36) / (x + ONE_36);
            int256 z_squared = (z * z) / ONE_36;

            // num is the numerator of the series: the z^(2 * n + 1) term
            int256 num = z;

            // seriesSum holds the accumulated sum of each term in the series, starting with the initial z
            int256 seriesSum = num;

            // In each step, the numerator is multiplied by z^2
            num = (num * z_squared) / ONE_36;
            seriesSum += num / 3;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 5;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 7;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 9;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 11;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 13;

            num = (num * z_squared) / ONE_36;
            seriesSum += num / 15;

            // 8 Taylor terms are sufficient for 36 decimal precision.

            // All that remains is multiplying by 2 (non fixed point).
            return seriesSum * 2;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

interface IReservoirCallee {
    /// @param sender user that initiated the swap and is triggering the callback
    /// @param amount0 positive indicates the amount out (received by callee), negative indicates the amount in (owed by callee)
    /// @param amount1 positive indicates the amount out (received by callee), negative indicates the amount in (owed by callee)
    /// @param data provided by the user is returned as part of the callback
    function reservoirCall(address sender, int256 amount0, int256 amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { MathUtils } from "src/libraries/MathUtils.sol";
import { StdMath } from "src/libraries/StdMath.sol";

library StableMath {
    using MathUtils for uint256;
    using StdMath for uint256;

    /// @dev Extra precision for intermediate calculations.
    uint256 public constant A_PRECISION = 100;
    /// @dev Minimum time to the ramp A.
    uint256 public constant MIN_RAMP_TIME = 1 days;
    /// @dev Minimum amplification coefficient for the math to work.
    uint256 public constant MIN_A = 1;
    /// @dev Maximum amplification coefficient.
    uint256 public constant MAX_A = 10_000;
    /// @dev Maximum rate of change daily. Note that you can change by the rate each day, so you can
    /// exponentially ramp if you chain days together (e.g. ramp by a factor of 8 over 3 days, 2**3).
    uint256 public constant MAX_AMP_UPDATE_DAILY_RATE = 2;
    /// @dev Required as an upper limit for iterative calculations not guaranteed to converge.
    uint256 private constant MAX_LOOP_LIMIT = 256;
    /// @dev Maximum fee, which is 100%.
    uint256 private constant ONE_HUNDRED_PERCENT = 1_000_000;

    /// @notice Calculates the amount of output tokens for an exact in trade
    /// @param amountIn input amount, assumed to be type(uint104).max or less
    /// @param reserve0 reserves of token0, assumed to be type(uint104).max or less
    /// @param reserve1 reserves of token1, assumed to be type(uint104).max or less
    /// @param token0PrecisionMultiplier, multiplier for token0 to get to 1e18, assumed to be between 1 and 1e18
    /// @param token1PrecisionMultiplier, multiplier for token1 to get to 1e18, assumed to be between 1 and 1e18
    /// @param token0In, true for token0 in token1 out
    /// @param swapFee, assumed to be ReservoirPair::MAX_SWAP_FEE (0.02e6) or less
    /// @param N_A, number of tokens multiplied by the amplification coefficient, assumed to be 2 * MAX_A * A_PRECISION or less
    /// @return dy the amount of output tokens
    function _getAmountOut(
        uint256 amountIn,
        uint256 reserve0,
        uint256 reserve1,
        uint256 token0PrecisionMultiplier,
        uint256 token1PrecisionMultiplier,
        bool token0In,
        uint256 swapFee,
        uint256 N_A // solhint-disable-line var-name-mixedcase
    ) internal pure returns (uint256 dy) {
        // overflow and underflow are not possible as reserves, amountIn <= uint104, precision multipliers are maximum 1e18 (uint60)
        // and swapFee < ONE_HUNDRED_PERCENT
        unchecked {
            uint256 adjustedReserve0 = reserve0 * token0PrecisionMultiplier;
            uint256 adjustedReserve1 = reserve1 * token1PrecisionMultiplier;
            uint256 feeDeductedAmountIn = amountIn - (amountIn * swapFee) / ONE_HUNDRED_PERCENT;
            uint256 d = _computeLiquidityFromAdjustedBalances(adjustedReserve0, adjustedReserve1, N_A);

            if (token0In) {
                uint256 x = adjustedReserve0 + (feeDeductedAmountIn * token0PrecisionMultiplier);
                uint256 y = _getY(x, d, N_A);
                dy = adjustedReserve1 - y - 1;
                dy /= token1PrecisionMultiplier;
            } else {
                uint256 x = adjustedReserve1 + (feeDeductedAmountIn * token1PrecisionMultiplier);
                uint256 y = _getY(x, d, N_A);
                dy = adjustedReserve0 - y - 1;
                dy /= token0PrecisionMultiplier;
            }
        }
    }

    /// @notice Calculates the amount of input tokens for an exact out trade
    /// @param amountOut output amount, assumed to be type(uint104).max or less
    /// @param reserve0 reserves of token0, assumed to be type(uint104).max or less
    /// @param reserve1 reserves of token1, assumed to be type(uint104).max or less
    /// @param token0PrecisionMultiplier, multiplier for token0 to get to 1e18, assumed to be between 1 and 1e18
    /// @param token1PrecisionMultiplier, multiplier for token1 to get to 1e18, assumed to be between 1 and 1e18
    /// @param token0Out, true for token0 out token1 in
    /// @param swapFee, assumed to be ReservoirPair::MAX_SWAP_FEE (0.02e6) or less
    /// @param N_A, number of tokens multiplied by the amplification coefficient, assumed to be 2 * MAX_A * A_PRECISION or less
    /// @return dx the amount of input tokens
    function _getAmountIn(
        uint256 amountOut,
        uint256 reserve0,
        uint256 reserve1,
        uint256 token0PrecisionMultiplier,
        uint256 token1PrecisionMultiplier,
        bool token0Out,
        uint256 swapFee,
        uint256 N_A // solhint-disable-line var-name-mixedcase
    ) internal pure returns (uint256 dx) {
        // overflow and underflow are not possible as reserves, amountIn <= uint104 and precision multipliers are maximum 1e18 (uint60)
        // and swapFee < ONE_HUNDRED_PERCENT
        unchecked {
            uint256 adjustedReserve0 = reserve0 * token0PrecisionMultiplier;
            uint256 adjustedReserve1 = reserve1 * token1PrecisionMultiplier;
            uint256 d = _computeLiquidityFromAdjustedBalances(adjustedReserve0, adjustedReserve1, N_A);

            if (token0Out) {
                uint256 y = adjustedReserve0 - amountOut * token0PrecisionMultiplier;
                uint256 x = _getY(y, d, N_A);
                dx = x - adjustedReserve1 + 1;
                dx /= token1PrecisionMultiplier;
            } else {
                uint256 y = adjustedReserve1 - amountOut * token1PrecisionMultiplier;
                uint256 x = _getY(y, d, N_A);
                dx = x - adjustedReserve0 + 1;
                dx /= token0PrecisionMultiplier;
            }

            // Add the swap fee.
            dx = dx * (ONE_HUNDRED_PERCENT + swapFee) / ONE_HUNDRED_PERCENT;
        }
    }

    function _computeLiquidityFromAdjustedBalances(
        uint256 xp0,
        uint256 xp1,
        uint256 N_A // solhint-disable-line var-name-mixedcase
    ) internal pure returns (uint256) {
        uint256 s = xp0 + xp1;
        if (s == 0) {
            return 0;
        }

        uint256 prevD;
        // solhint-disable-next-line var-name-mixedcase
        uint256 D = s;
        (xp0, xp1) = xp0 < xp1 ? (xp0, xp1) : (xp1, xp0);
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            uint256 dP = (((D * D) / xp0) * D) / xp1 / 4;
            prevD = D;
            D = (((N_A * s) / A_PRECISION + 2 * dP) * D) / ((N_A - A_PRECISION) * D / A_PRECISION + 3 * dP);
            if (D.within1(prevD)) {
                return D;
            }
        }

        revert("SM: COMPUTE_DID_NOT_CONVERGE");
    }

    /// @notice Calculate the new balance of one token given the balance of the other token
    /// @dev This function is used as a helper function to calculate how much TO/FROM token the user
    /// should receive/provide on swap.
    /// @dev Originally
    /// https://github.com/saddle-finance/saddle-contract/blob/0b76f7fb519e34b878aa1d58cffc8d8dc0572c12/contracts/SwapUtils.sol#L432.
    /// @param x The new total amount of FROM/TO token.
    /// @return y The amount of TO/FROM token that should remain in the pool.
    function _getY(
        uint256 x,
        uint256 D, // solhint-disable-line var-name-mixedcase
        uint256 N_A // solhint-disable-line var-name-mixedcase
    ) internal pure returns (uint256 y) {
        uint256 c = (D * D) / (x * 2);
        c = (c * D) * A_PRECISION / (N_A * 2);
        uint256 b = x + ((D * A_PRECISION) / N_A);
        uint256 yPrev;
        y = D;
        // @dev Iterative approximation.
        for (uint256 i = 0; i < MAX_LOOP_LIMIT; i++) {
            yPrev = y;
            y = (y * y + c) / (y * 2 + b - D);
            if (y.within1(yPrev)) {
                return y;
            }
        }
        revert("SM: GETY_DID_NOT_CONVERGE");
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";

import { LogCompression } from "src/libraries/LogCompression.sol";
import { StableMath } from "src/libraries/StableMath.sol";

library StableOracleMath {
    using FixedPointMathLib for uint256;

    /// @dev Calculates the spot price of token1/token0 for the stable pair
    function calcLogPrice(uint256 amplificationParameter, uint256 reserve0, uint256 reserve1)
        internal
        pure
        returns (uint256 spotPrice, int112 logSpotPrice)
    {
        spotPrice = calcSpotPrice(amplificationParameter, reserve0, reserve1);

        int256 rawLogSpotPrice = LogCompression.toLowResLog(spotPrice);
        logSpotPrice = int112(rawLogSpotPrice);
    }

    /// @dev Calculates the spot price of token1 in token0
    function calcSpotPrice(uint256 amplificationParameter, uint256 reserve0, uint256 reserve1)
        internal
        pure
        returns (uint256 spotPrice)
    {
        //                                                                    //
        //                             2.a.x.y + a.y^2 + b.y                  //
        // spot price Y/X = - dx/dy = -----------------------                 //
        //                             2.a.x.y + a.x^2 + b.x                  //
        //                                                                    //
        // n = 2                                                              //
        // a = amp param * n                                                  //
        // b = D + a.(S - D)                                                  //
        // D = invariant                                                      //
        // S = sum of balances but x,y = 0 since x  and y are the only tokens //

        uint256 invariant =
            StableMath._computeLiquidityFromAdjustedBalances(reserve0, reserve1, 2 * amplificationParameter);

        uint256 a = (amplificationParameter * 2) / StableMath.A_PRECISION;
        uint256 b = (invariant * a) - invariant;

        uint256 axy2 = (a * 2 * reserve0).mulWad(reserve1); // n = 2

        // dx = a.x.y.2 + a.y^2 - b.y
        uint256 derivativeX = axy2 + ((a * reserve1).mulWad(reserve1)) - (b.mulWad(reserve1));

        // dy = a.x.y.2 + a.x^2 - b.x
        uint256 derivativeY = axy2 + ((a * reserve0).mulWad(reserve0)) - (b.mulWad(reserve0));

        // The rounding direction is irrelevant as we're about to introduce a much larger error when converting to log
        // space. We use `divWadUp` as it prevents the result from being zero, which would make the logarithm revert. A
        // result of zero is therefore only possible with zero balances, which are prevented via other means.
        spotPrice = derivativeX.divWadUp(derivativeY);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

import { FixedPointMathLib } from "solady/utils/FixedPointMathLib.sol";

import { LogCompression } from "src/libraries/LogCompression.sol";

library ConstantProductOracleMath {
    using FixedPointMathLib for uint256;

    /**
     * @notice Calculates the spot price of token1/token0 for the constant product pair.
     * @dev Minimum price is 1e-18, as we do not round to zero.
     * @param reserve0 Should never be 0, as checked by _updateAndUnlock().
     * @param reserve1 Should never be 0, as checked by _updateAndUnlock().
     */
    function calcLogPrice(uint256 reserve0, uint256 reserve1)
        internal
        pure
        returns (uint256 spotPrice, int112 logSpotPrice)
    {
        // Scaled by 1e18, minimum will be 1 wei as we divUp.
        spotPrice = reserve1.divWadUp(reserve0);

        int256 rawResult = LogCompression.toLowResLog(spotPrice);
        logSpotPrice = int112(rawResult);
    }

    /// @param reserve0 Amount in native precision.
    /// @param reserve1 Amount in native precision.
    function calcLogLiq(uint256 reserve0, uint256 reserve1) internal pure returns (int112 logLiq) {
        uint256 sqrtK = FixedPointMathLib.sqrt(reserve0 * reserve1);

        int256 rawResult = LogCompression.toLowResLog(sqrtK);
        logLiq = int112(rawResult);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

struct AmplificationData {
    /// @dev initialA is stored with A_PRECISION (i.e. multiplied by 100)
    uint64 initialA;
    /// @dev futureA is stored with A_PRECISION (i.e. multiplied by 100)
    uint64 futureA;
    /// @dev initialATime is a unix timestamp and will only overflow every 584 billion years
    uint64 initialATime;
    /// @dev futureATime is a unix timestamp and will only overflow every 584 billion years
    uint64 futureATime;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

/// @notice A library that contains functions for calculating differences between two uint256.
/// @author Adapted from https://github.com/saddle-finance/saddle-contract/blob/master/contracts/MathUtils.sol.
library MathUtils {
    /// @notice Compares a and b and returns 'true' if the difference between a and b
    /// is less than 1 or equal to each other.
    /// @param a uint256 to compare with.
    /// @param b uint256 to compare with.
    function within1(uint256 a, uint256 b) internal pure returns (bool) {
        unchecked {
            if (a > b) {
                return a - b <= 1;
            }
            return b - a <= 1;
        }
    }
}