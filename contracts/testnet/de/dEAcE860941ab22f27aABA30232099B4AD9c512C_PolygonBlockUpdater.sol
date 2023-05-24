// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interface/IBlockUpdater.sol";
import "./PolygonBlockVerifier.sol";
import "./PolygonValidatorVerifier.sol";

contract PolygonBlockUpdater is IBlockUpdater, PolygonBlockVerifier, PolygonValidatorVerifier, Initializable, OwnableUpgradeable {
    event ImportSyncCommitteeRoot(uint256 indexed period, bytes32 indexed syncCommitteeRoot);
    event ModBlockConfirmation(uint256 oldBlockConfirmation, uint256 newBlockConfirmation);

    struct ValidatorInput {
        uint256 blockNumber;
        uint256 blockConfirmation;
        bytes32 blockHash;
        bytes32 receiptHash;
        bytes32 validatorSetHash;
        bytes32 nextValidatorSetHash;
    }

    struct BlockInput {
        uint256 blockNumber;
        uint256 blockConfirmation;
        bytes32 validatorSetHash;
        bytes32 receiptHash;
        bytes32 blockHash;
    }

    struct ValidatorProof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[8] inputs;
    }

    struct BlockProof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[7] inputs;
    }

    // period => validatorHash
    mapping(uint256 => bytes32) public validatorHashes;

    // blockHash=>receiptsRoot =>BlockConfirmation
    mapping(bytes32 => mapping(bytes32 => uint256)) public blockInfos;

    uint256 public minBlockConfirmation;

    uint256 public currentPeriod;

    function initialize(uint64 period, bytes32 validatorSetHash, uint256 _minBlockConfirmation) public initializer {
        __Ownable_init();
        currentPeriod = period;
        validatorHashes[period] = validatorSetHash;
        minBlockConfirmation = _minBlockConfirmation;
    }

    function importNextValidatorSet(bytes calldata _proof) external {
        _importNextValidatorSet(_proof);
    }

    function batchImportNextValidatorSet(bytes[] calldata _proof) external {
        for (uint256 i = 0; i < _proof.length; i++) {
            _importNextValidatorSet(_proof[i]);
        }
    }

    function importBlock(bytes calldata _proof) external {
        _importBlock(_proof);
    }

    function batchImportBlock(bytes[] calldata _proof) external {
        for (uint256 i = 0; i < _proof.length; i++) {
            _importBlock(_proof[i]);
        }
    }

    function checkBlock(bytes32 _blockHash, bytes32 _receiptHash) external view returns (bool) {
        (bool exist,) = _checkBlock(_blockHash, _receiptHash);
        return exist;
    }

    function checkBlockConfirmation(bytes32 _blockHash, bytes32 _receiptHash) external view returns (bool, uint256) {
        return _checkBlock(_blockHash, _receiptHash);
    }

    function _importNextValidatorSet(bytes calldata _proof) internal {
        ValidatorProof memory proofData;
        (proofData.a, proofData.b, proofData.c, proofData.inputs) = abi.decode(_proof, (uint256[2], uint256[2][2], uint256[2], uint256[8]));
        ValidatorInput memory parsedInput = _parseValidatorInput(proofData.inputs);

        uint256 period = _computePeriod(parsedInput.blockNumber);
        uint256 nextPeriod = period + 1;
        //        require(validatorHashes[period] == parsedInput.validatorSetHash, "invalid validatorSetHash");
        //        require(validatorHashes[nextPeriod] == bytes32(0), "nextValidatorSetHash already exist");

        uint256[1] memory compressInput;
        compressInput[0] = _hashValidatorInput(proofData.inputs);
        require(verifyValidatorProof(proofData.a, proofData.b, proofData.c, compressInput), "invalid proof");
        validatorHashes[nextPeriod] = parsedInput.nextValidatorSetHash;
        currentPeriod = nextPeriod;
        blockInfos[parsedInput.blockHash][parsedInput.receiptHash] = parsedInput.blockConfirmation;
        emit ImportSyncCommitteeRoot(nextPeriod, parsedInput.nextValidatorSetHash);
        emit ImportBlock(parsedInput.blockNumber, parsedInput.blockHash, parsedInput.receiptHash);
    }

    function _importBlock(bytes calldata _proof) internal {
        BlockProof memory proofData;
        (proofData.a, proofData.b, proofData.c, proofData.inputs) = abi.decode(_proof, (uint256[2], uint256[2][2], uint256[2], uint256[7]));
        BlockInput memory parsedInput = _parseBlockInput(proofData.inputs);

        require(parsedInput.blockConfirmation >= minBlockConfirmation, "Not enough block confirmations");
        (bool exist,uint256 blockConfirmation) = _checkBlock(parsedInput.blockHash, parsedInput.receiptHash);
        if (exist && parsedInput.blockConfirmation <= blockConfirmation) {
            revert("already exist");
        }
        //        uint256 period = _computePeriod(parsedInput.blockNumber);
        //        require(validatorHashes[period] == parsedInput.validatorSetHash, "invalid validatorSetHash");

        uint256[1] memory compressInput;
        compressInput[0] = _hashBlockInput(proofData.inputs);
        require(verifyBlockProof(proofData.a, proofData.b, proofData.c, compressInput), "invalid proof");

        blockInfos[parsedInput.blockHash][parsedInput.receiptHash] = parsedInput.blockConfirmation;
        emit ImportBlock(parsedInput.blockNumber, parsedInput.blockHash, parsedInput.receiptHash);
    }

    function _checkBlock(bytes32 _blockHash, bytes32 _receiptHash) internal view returns (bool, uint256) {
        uint256 blockConfirmation = blockInfos[_blockHash][_receiptHash];
        if (blockConfirmation > 0) {
            return (true, blockConfirmation);
        }
        return (false, blockConfirmation);
    }

    function _parseValidatorInput(uint256[8] memory _inputs) internal pure returns (ValidatorInput memory) {
        ValidatorInput memory result;
        result.blockHash = bytes32((_inputs[1] << 128) | _inputs[0]);
        result.receiptHash = bytes32((_inputs[3] << 128) | _inputs[2]);
        result.validatorSetHash = bytes32(_inputs[4]);
        result.nextValidatorSetHash = bytes32(_inputs[5]);
        result.blockNumber = _inputs[6];
        result.blockConfirmation = _inputs[7];
        return result;
    }

    function _parseBlockInput(uint256[7] memory _inputs) internal pure returns (BlockInput memory) {
        BlockInput memory result;
        result.blockHash = bytes32((_inputs[1] << 128) | _inputs[0]);
        result.receiptHash = bytes32((_inputs[3] << 128) | _inputs[2]);
        result.validatorSetHash = bytes32(_inputs[4]);
        result.blockNumber = _inputs[5];
        result.blockConfirmation = _inputs[6];
        return result;
    }

    function _hashValidatorInput(uint256[8] memory _inputs) internal pure returns (uint256) {
        uint256 computedHash = uint256(keccak256(abi.encodePacked(_inputs[0], _inputs[1], _inputs[2], _inputs[3], _inputs[4], _inputs[5], _inputs[6], _inputs[7])));
        return computedHash / 256;
    }

    function _hashBlockInput(uint256[7] memory _inputs) internal pure returns (uint256) {
        uint256 computedHash = uint256(keccak256(abi.encodePacked(_inputs[0], _inputs[1], _inputs[2], _inputs[3], _inputs[4], _inputs[5], _inputs[6])));
        return computedHash / 256;
    }

    function _computePeriod(uint256 blockNumber) internal pure returns (uint256) {
        return blockNumber / 16;
    }

    //----------------------------------------------------------------------------------
    // onlyOwner
    function setBlockConfirmation(uint256 _minBlockConfirmation) external onlyOwner {
        emit ModBlockConfirmation(minBlockConfirmation, _minBlockConfirmation);
        minBlockConfirmation = _minBlockConfirmation;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBlockUpdater {
    event ImportBlock(uint256 identifier, bytes32 blockHash, bytes32 receiptHash);

    function importBlock(bytes calldata _proof) external;

    function checkBlock(bytes32 _blockHash, bytes32 _receiptsRoot) external view returns (bool);

    function checkBlockConfirmation(bytes32 _blockHash, bytes32 _receiptsRoot) external view returns (bool, uint256);
}

// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library PairingBlock {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingBlock-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"PairingBlock-mul-failed");
    }

    /* @return The result of computing the PairingBlock check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         PairingBlock([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingBlock-opcode-failed");

        return out[0] != 0;
    }
}

contract PolygonBlockVerifier {

    using PairingBlock for *;

    uint256 constant SNARK_SCALAR_FIELD_BLOCK = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q_BLOCK = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKeyBlock {
        PairingBlock.G1Point alfa1;
        PairingBlock.G2Point beta2;
        PairingBlock.G2Point gamma2;
        PairingBlock.G2Point delta2;
        PairingBlock.G1Point[2] IC;
    }

    struct ProofBlock {
        PairingBlock.G1Point A;
        PairingBlock.G2Point B;
        PairingBlock.G1Point C;
    }

    function verifyingKeyBlock() internal pure returns (VerifyingKeyBlock memory vk) {
        vk.alfa1 = PairingBlock.G1Point(uint256(16914126314853638934677383206158281734975056096016653676952867423775080460121), uint256(19489562295020205652191676674144424444889006687528433538582981351905540432025));
        vk.beta2 = PairingBlock.G2Point([uint256(7037702935073232453337429028812765062114263274577368696684724085953228093045), uint256(18614902008817369155144583811588041523077024370211097460608432326520439767664)], [uint256(20196228748806467367320164011203068040874833380648927130230657467386833458620), uint256(3097913914884507911481040513431051726096333131784570113900633181530204799812)]);
        vk.gamma2 = PairingBlock.G2Point([uint256(16723894103758002909548623503246715261858767292608230672595088192558057690115), uint256(8578137723186834379094906874659770783440950405587231507076648787317016519407)], [uint256(4169016059978790864820775052243243087407633627426396218182100399381009741768), uint256(2929887537274671413487396601568343836862531387738272309287405382767465431963)]);
        vk.delta2 = PairingBlock.G2Point([uint256(18049558240589696867643338475770526927292508330664272217357937543837645681782), uint256(12444541726454712771297836273474986600482726893299845468234497622971568713709)], [uint256(12075704328028575706364428233227675318960232884401860003892267892075200679342), uint256(20204283696820129944183177354288156054151286992634719437883270960529507883885)]);
        vk.IC[0] = PairingBlock.G1Point(uint256(15954014980564452919032342226264993320328790099144446644830814568455644996564), uint256(5774783795765237787535054678624549646438621956485775382427382388366115293699));
        vk.IC[1] = PairingBlock.G1Point(uint256(722628038454494710432551147375644991337846183563087113177777768792581667372), uint256(9406280800360709716747777236076935227537711463232236658697002437850947840880));
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyBlockProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool r) {

        ProofBlock memory proof;
        proof.A = PairingBlock.G1Point(a[0], a[1]);
        proof.B = PairingBlock.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = PairingBlock.G1Point(c[0], c[1]);

        VerifyingKeyBlock memory vk = verifyingKeyBlock();

        // Compute the linear combination vk_x
        PairingBlock.G1Point memory vk_x = PairingBlock.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q_BLOCK, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q_BLOCK, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q_BLOCK, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q_BLOCK, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q_BLOCK, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q_BLOCK, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q_BLOCK, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q_BLOCK, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD_BLOCK,"verifier-gte-snark-scalar-field");
            vk_x = PairingBlock.plus(vk_x, PairingBlock.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = PairingBlock.plus(vk_x, vk.IC[0]);

        return PairingBlock.pairing(
            PairingBlock.negate(proof.A),
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}

// SPDX-License-Identifier: AML
//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to
// deal in the Software without restriction, including without limitation the
// rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
// sell copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
// IN THE SOFTWARE.

// 2019 OKIMS

pragma solidity ^0.8.0;

library PairingValidator {

    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct G1Point {
        uint256 X;
        uint256 Y;
    }

    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint256[2] X;
        uint256[2] Y;
    }

    /*
     * @return The negation of p, i.e. p.plus(p.negate()) should be zero.
     */
    function negate(G1Point memory p) internal pure returns (G1Point memory) {

        // The prime q in the base field F_q for G1
        if (p.X == 0 && p.Y == 0) {
            return G1Point(0, 0);
        } else {
            return G1Point(p.X, PRIME_Q - (p.Y % PRIME_Q));
        }
    }

    /*
     * @return The sum of two points of G1
     */
    function plus(
        G1Point memory p1,
        G1Point memory p2
    ) internal view returns (G1Point memory r) {

        uint256[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingValidator-add-failed");
    }

    /*
     * @return The product of a point on G1 and a scalar, i.e.
     *         p == p.scalar_mul(1) and p.plus(p) == p.scalar_mul(2) for all
     *         points p.
     */
    function scalar_mul(G1Point memory p, uint256 s) internal view returns (G1Point memory r) {

        uint256[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"PairingValidator-mul-failed");
    }

    /* @return The result of computing the PairingValidator check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         PairingValidator([P1(), P1().negate()], [P2(), P2()]) should return true.
     */
    function pairing(
        G1Point memory a1,
        G2Point memory a2,
        G1Point memory b1,
        G2Point memory b2,
        G1Point memory c1,
        G2Point memory c2,
        G1Point memory d1,
        G2Point memory d2
    ) internal view returns (bool) {

        G1Point[4] memory p1 = [a1, b1, c1, d1];
        G2Point[4] memory p2 = [a2, b2, c2, d2];
        uint256 inputSize = 24;
        uint256[] memory input = new uint256[](inputSize);

        for (uint256 i = 0; i < 4; i++) {
            uint256 j = i * 6;
            input[j + 0] = p1[i].X;
            input[j + 1] = p1[i].Y;
            input[j + 2] = p2[i].X[0];
            input[j + 3] = p2[i].X[1];
            input[j + 4] = p2[i].Y[0];
            input[j + 5] = p2[i].Y[1];
        }

        uint256[1] memory out;
        bool success;

        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
        // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }

        require(success,"PairingValidator-opcode-failed");

        return out[0] != 0;
    }
}

contract PolygonValidatorVerifier {

    using PairingValidator for *;

    uint256 constant SNARK_SCALAR_FIELD_VALIDATOR = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q_VALIDATOR = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKeyValidator {
        PairingValidator.G1Point alfa1;
        PairingValidator.G2Point beta2;
        PairingValidator.G2Point gamma2;
        PairingValidator.G2Point delta2;
        PairingValidator.G1Point[2] IC;
    }

    struct ProofValidator {
        PairingValidator.G1Point A;
        PairingValidator.G2Point B;
        PairingValidator.G1Point C;
    }

    function verifyingKeyValidator() internal pure returns (VerifyingKeyValidator memory vk) {
        vk.alfa1 = PairingValidator.G1Point(uint256(1940827040684442819134790646298130616991922379639781104158227959302260641800), uint256(15282609232528849192126147967190592204044644531389932892648527062913698082585));
        vk.beta2 = PairingValidator.G2Point([uint256(18933507340453557167146678880026954215060995350256696664983214758419584743895), uint256(12562995961897409102742390684572821512224318926688096698920058370344535487513)], [uint256(15463874269889136414177963139177352573484935339007214030556428932703785910641), uint256(16458537682939694407572674143972231288556828620198760318528649747162133900425)]);
        vk.gamma2 = PairingValidator.G2Point([uint256(21216272698632234401696898689775877689632744769394929563054486091550695551881), uint256(9301160401519511982824212686154664309809741835792746598360450650323269219711)], [uint256(801896760773963169293961563717503055454283739301065239476518592133878085923), uint256(3849484680808104261692788298090602586708190000000880463299752650795041360759)]);
        vk.delta2 = PairingValidator.G2Point([uint256(9390627644861133846233598178579201982245485188845794727403586574500238305226), uint256(9907786413667655682300975027594913997391951770364556551854153226518492034394)], [uint256(8596945730451562203318656977727949102998176827935469381884618751682307298549), uint256(8210131618021772066302427003915461428064224888415400069083950963454475862691)]);
        vk.IC[0] = PairingValidator.G1Point(uint256(9937261501580685822898332350853002710685695085361632067686443440672581858644), uint256(7761679466966022235542040911500503320984414811669673391475619160306032800252));
        vk.IC[1] = PairingValidator.G1Point(uint256(7346111556018621867395800701628187286791248828168987020294277362366696670720), uint256(8760836480978121422214146344362796784407268995839116090457009813610029463079));
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyValidatorProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[1] memory input
    ) public view returns (bool r) {

        ProofValidator memory proof;
        proof.A = PairingValidator.G1Point(a[0], a[1]);
        proof.B = PairingValidator.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = PairingValidator.G1Point(c[0], c[1]);

        VerifyingKeyValidator memory vk = verifyingKeyValidator();

        // Compute the linear combination vk_x
        PairingValidator.G1Point memory vk_x = PairingValidator.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q_VALIDATOR, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q_VALIDATOR, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q_VALIDATOR, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q_VALIDATOR, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q_VALIDATOR, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q_VALIDATOR, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q_VALIDATOR, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q_VALIDATOR, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD_VALIDATOR,"verifier-gte-snark-scalar-field");
            vk_x = PairingValidator.plus(vk_x, PairingValidator.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = PairingValidator.plus(vk_x, vk.IC[0]);

        return PairingValidator.pairing(
            PairingValidator.negate(proof.A),
            proof.B,
            vk.alfa1,
            vk.beta2,
            vk_x,
            vk.gamma2,
            proof.C,
            vk.delta2
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}