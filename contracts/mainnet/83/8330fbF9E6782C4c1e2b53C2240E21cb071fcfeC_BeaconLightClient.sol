// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./BeaconLightClientUpdate.sol";
import "./LightClientVerifier.sol";
import "./BLS12381.sol";

contract BeaconLightClient is LightClientVerifier, BeaconLightClientUpdate, BLS12381,Initializable {
    // Beacon block header that is finalized
    BeaconBlockHeader public finalizedHeader;

    // slot=>BeaconBlockHeader
    mapping(uint64 => BeaconBlockHeader) public headers;

    // Sync committees corresponding to the header
    // sync_committee_perid => sync_committee_root
    mapping(uint64 => bytes32) public syncCommitteeRoots;

    bytes32 public GENESIS_VALIDATORS_ROOT;

    uint64 constant private NEXT_SYNC_COMMITTEE_INDEX = 55;
    uint64 constant private NEXT_SYNC_COMMITTEE_DEPTH = 5;
    uint64 constant private FINALIZED_CHECKPOINT_ROOT_INDEX = 105;
    uint64 constant private FINALIZED_CHECKPOINT_ROOT_DEPTH = 6;
    uint64 constant private SLOTS_PER_EPOCH = 32;
    uint64 constant private EPOCHS_PER_SYNC_COMMITTEE_PERIOD = 256;
    bytes4 constant private DOMAIN_SYNC_COMMITTEE = 0x07000000;

    event FinalizedHeaderImported(BeaconBlockHeader finalized_header);
    event NextSyncCommitteeImported(uint64 indexed period, bytes32 indexed next_sync_committee_root);

    function initialize(
        uint64 slot,
        uint64 proposerIndex,
        bytes32 parentRoot,
        bytes32 stateRoot,
        bytes32 bodyRoot,
        bytes32 currentSyncCommitteeHash,
        bytes32 nextSyncCommitteeHash,
        bytes32 genesisValidatorsRoot) public initializer {
        finalizedHeader = BeaconBlockHeader(slot, proposerIndex, parentRoot, stateRoot, bodyRoot);
        syncCommitteeRoots[computeSyncCommitteePeriod(slot)] = currentSyncCommitteeHash;
        syncCommitteeRoots[computeSyncCommitteePeriod(slot) + 1] = nextSyncCommitteeHash;
        GENESIS_VALIDATORS_ROOT = genesisValidatorsRoot;
    }

    function getCurrentPeriod() public view returns (uint64) {
        return computeSyncCommitteePeriod(finalizedHeader.slot);
    }

    function getCommitteeRoot(uint64 slot) public view returns (bytes32) {
        return syncCommitteeRoots[computeSyncCommitteePeriod(slot)];
    }

    // follow beacon api: /beacon/light_client/updates/?start_period={period}&count={count}
    function importNextSyncCommittee(
        FinalizedHeaderUpdate calldata headerUpdate,
        SyncCommitteePeriodUpdate calldata scUpdate
    ) external {
        require(isSuperMajority(headerUpdate.syncAggregate.participation), "!supermajor");

        require(headerUpdate.signatureSlot > headerUpdate.attestedHeader.slot &&
            headerUpdate.attestedHeader.slot >= headerUpdate.finalizedHeader.slot,
            "!skip");

        require(verifyFinalizedHeader(
                headerUpdate.finalizedHeader,
                headerUpdate.finalityBranch,
                headerUpdate.attestedHeader.stateRoot),
            "!finalized header"
        );

        uint64 finalizedPeriod = computeSyncCommitteePeriod(headerUpdate.finalizedHeader.slot);
        uint64 signaturePeriod = computeSyncCommitteePeriod(headerUpdate.signatureSlot);
        require(signaturePeriod == finalizedPeriod, "!period");

        bytes32 signatureSyncCommitteeRoot = syncCommitteeRoots[signaturePeriod];
        require(signatureSyncCommitteeRoot != bytes32(0), "!missing");
        require(signatureSyncCommitteeRoot == headerUpdate.syncCommitteeRoot, "!sync_committee");


        bytes32 domain = computeDomain(DOMAIN_SYNC_COMMITTEE, headerUpdate.forkVersion, GENESIS_VALIDATORS_ROOT);
        bytes32 signingRoot = computeSigningRoot(headerUpdate.attestedHeader, domain);

        uint256[28] memory fieldElement = hashToField(signingRoot);
        uint256[31] memory verifyInputs;
        for (uint256 i = 0; i < fieldElement.length; i++) {
            verifyInputs[i] = fieldElement[i];
        }
        verifyInputs[28] = headerUpdate.syncAggregate.proof.input[0];
        verifyInputs[29] = headerUpdate.syncAggregate.proof.input[1];
        verifyInputs[30] = headerUpdate.syncAggregate.proof.input[2];

        require(verifyProof(
                headerUpdate.syncAggregate.proof.a,
                headerUpdate.syncAggregate.proof.b,
                headerUpdate.syncAggregate.proof.c,
                verifyInputs), "invalid proof");

        bytes32 syncCommitteeRoot = bytes32((headerUpdate.syncAggregate.proof.input[1] << 128) | headerUpdate.syncAggregate.proof.input[0]);
        uint64 slot = uint64(headerUpdate.syncAggregate.proof.input[2]);
        require(syncCommitteeRoot == signatureSyncCommitteeRoot, "invalid syncCommitteeRoot");
//        require(slot == headerUpdate.signatureSlot, "invalid slot");

        if (headerUpdate.finalizedHeader.slot > finalizedHeader.slot) {
            finalizedHeader = headerUpdate.finalizedHeader;
            headers[finalizedHeader.slot] = finalizedHeader;
            emit FinalizedHeaderImported(headerUpdate.finalizedHeader);
        }

        require(verifyNextSyncCommittee(
                scUpdate.nextSyncCommitteeRoot,
                scUpdate.nextSyncCommitteeBranch,
                headerUpdate.attestedHeader.stateRoot),
            "!next_sync_committee"
        );

        uint64 nextPeriod = signaturePeriod + 1;
        require(syncCommitteeRoots[nextPeriod] == bytes32(0), "imported");
        bytes32 nextSyncCommitteeRoot = scUpdate.nextSyncCommitteeRoot;
        syncCommitteeRoots[nextPeriod] = nextSyncCommitteeRoot;
        emit NextSyncCommitteeImported(nextPeriod, nextSyncCommitteeRoot);
    }

    function verifyFinalizedHeader(
        BeaconBlockHeader calldata header,
        bytes32[] calldata finalityBranch,
        bytes32 attestedHeaderRoot
    ) internal pure returns (bool) {
        require(finalityBranch.length == FINALIZED_CHECKPOINT_ROOT_DEPTH, "!finality_branch");
        bytes32 headerRoot = hashTreeRoot(header);
        return isValidMerkleBranch(
            headerRoot,
            finalityBranch,
            FINALIZED_CHECKPOINT_ROOT_DEPTH,
            FINALIZED_CHECKPOINT_ROOT_INDEX,
            attestedHeaderRoot
        );
    }

    function verifyNextSyncCommittee(
        bytes32 nextSyncCommitteeRoot,
        bytes32[] calldata nextSyncCommitteeBranch,
        bytes32 headerStateRoot
    ) internal pure returns (bool) {
        require(nextSyncCommitteeBranch.length == NEXT_SYNC_COMMITTEE_DEPTH, "!next_sync_committee_branch");
        return isValidMerkleBranch(
            nextSyncCommitteeRoot,
            nextSyncCommitteeBranch,
            NEXT_SYNC_COMMITTEE_DEPTH,
            NEXT_SYNC_COMMITTEE_INDEX,
            headerStateRoot
        );
    }

    function isSuperMajority(uint256 participation) internal pure returns (bool) {
        return participation * 3 >= SYNC_COMMITTEE_SIZE * 2;
    }

    function computeSyncCommitteePeriod(uint64 slot) internal pure returns (uint64) {
        return slot / SLOTS_PER_EPOCH / EPOCHS_PER_SYNC_COMMITTEE_PERIOD;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (proxy/utils/Initializable.sol)

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
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./BeaconChain.sol";

contract BeaconLightClientUpdate is BeaconChain {

    struct SyncAggregate {
        uint64 participation;
        Groth16Proof proof;
    }

    struct Groth16Proof {
        uint256[2] a;
        uint256[2][2] b;
        uint256[2] c;
        uint256[3] input;
    }

    struct FinalizedHeaderUpdate {
        // The beacon block header that is attested to by the sync committee
        BeaconBlockHeader attestedHeader;

        // Sync committee corresponding to sign attested header
        bytes32 syncCommitteeRoot;

        // The finalized beacon block header attested to by Merkle branch
        BeaconBlockHeader finalizedHeader;
        bytes32[] finalityBranch;

        // Fork version for the aggregate signature
        bytes4 forkVersion;

        // Slot at which the aggregate signature was created (untrusted)
        uint64 signatureSlot;

        // Sync committee aggregate signature
        SyncAggregate syncAggregate;
    }

    struct SyncCommitteePeriodUpdate {
        // Next sync committee corresponding to the finalized header
        bytes32 nextSyncCommitteeRoot;
        bytes32[] nextSyncCommitteeBranch;
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

library Pairing {

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

        require(success,"pairing-add-failed");
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
        require (success,"pairing-mul-failed");
    }

    /* @return The result of computing the pairing check
     *         e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
     *         For example,
     *         pairing([P1(), P1().negate()], [P2(), P2()]) should return true.
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

        require(success,"pairing-opcode-failed");

        return out[0] != 0;
    }
}

contract LightClientVerifier {

    using Pairing for *;

    uint256 constant SNARK_SCALAR_FIELD = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    uint256 constant PRIME_Q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;

    struct VerifyingKey {
        Pairing.G1Point alfa1;
        Pairing.G2Point beta2;
        Pairing.G2Point gamma2;
        Pairing.G2Point delta2;
        Pairing.G1Point[32] IC;
    }

    struct Proof {
        Pairing.G1Point A;
        Pairing.G2Point B;
        Pairing.G1Point C;
    }

    function verifyingKey() internal pure returns (VerifyingKey memory vk) {
        vk.alfa1 = Pairing.G1Point(uint256(12136067877651207517560692428929061251727030439667088063356004262286813462364), uint256(9152395427201470744837421906441307306280289252003021742300681400823175737905));
        vk.beta2 = Pairing.G2Point([uint256(2807151715644014126603406928922499966871041507063689855767645663383202439718), uint256(16988940781736750332422892111905643355484089732291907484063479730202364673277)], [uint256(261198546057439780833005544945143550638738857046930311784060721018904941475), uint256(9301213547161341192100742767448214346655947529033841191280835787664434021581)]);
        vk.gamma2 = Pairing.G2Point([uint256(444592058338888741843295796580424895506150225113821898091691605939407182624), uint256(7929729796787020277934304335368755255208423867770381662393873763828078079171)], [uint256(14941053955169893989079753741445597751405967117556041794173597639164058124455), uint256(1138577613276899210214656462923814199343937516733654303128686339349182038886)]);
        vk.delta2 = Pairing.G2Point([uint256(21167274731262625073086770224547997705619642850178397081279756427722858363631), uint256(2935353078344175373919666649280264649406646872318804516518245282068617035795)], [uint256(850488230025003934006252948515698741259933311756700739916718839581764996454), uint256(1696519814340372977005901803551677347316064463369850798505700874551940833315)]);
        vk.IC[0] = Pairing.G1Point(uint256(2761359277744332180183494326299792502176823477325665742706255669644038316344), uint256(18670815533197051371570665056042526590161694615327494841304912314623827586715));
        vk.IC[1] = Pairing.G1Point(uint256(4926163066126633728747080065109889190959522632749409835626345663557746060827), uint256(17973114295206320424480100468740560193003151176929532085777363654873237275740));
        vk.IC[2] = Pairing.G1Point(uint256(15425347981356759845243448152568840562270839807895114752008405600465513888178), uint256(16530136376400072504139112907773400237781268554004188113453529540713498728720));
        vk.IC[3] = Pairing.G1Point(uint256(5106095898879375215620409098327368893062203373010983692284900916693257920124), uint256(20966109731330126367160820773064654441344975400776067163265735000223413265410));
        vk.IC[4] = Pairing.G1Point(uint256(18404282631597833545559259545546319303837121014372065431537587805715287074810), uint256(10846045653727501188920868894778180086341254165614679489592978439728585411139));
        vk.IC[5] = Pairing.G1Point(uint256(8994755490460014264171593573485250730776484335786872952367346889187782226548), uint256(12310416004964677207953179313550743959500578333909345282356293739506943471475));
        vk.IC[6] = Pairing.G1Point(uint256(20460923777455473985462922027555533336335235163029295591227344579312360712648), uint256(14991060387230992072599794432985891567558454809504371386058854043137417396893));
        vk.IC[7] = Pairing.G1Point(uint256(9783501522881628522255582213200563538358516981067477228490003533151024612625), uint256(9003569929021053129210607804002017827052275555172361563798088508421817233979));
        vk.IC[8] = Pairing.G1Point(uint256(20532847807243475885151757309588180536527214079968013445611084540667817722983), uint256(10860522171497487980915749253055510977565545583805069257785699060062340783257));
        vk.IC[9] = Pairing.G1Point(uint256(6549527167959123415815091432908538892665395578827798828751252191511843530253), uint256(11204803492851083443236356318482517701097611867695436027192927198566393299939));
        vk.IC[10] = Pairing.G1Point(uint256(176371034152518309602054350757537222159482433069457972127942611088942751750), uint256(8048213597353429199782881844053706329313427400355877245834047681420128331942));
        vk.IC[11] = Pairing.G1Point(uint256(8148162694007774219944981198684560984856591980346524369332893153919340871442), uint256(9388998466536736294896189348777088759752736187572531110576656245164212284416));
        vk.IC[12] = Pairing.G1Point(uint256(17058512488113992946780509543955888305698655491807274800278954586725524988120), uint256(21021843327851772172927520314916586499058971259265848570888547791015649668109));
        vk.IC[13] = Pairing.G1Point(uint256(5239544579925943427793301801182103535102204512951083138880133530735547386627), uint256(19032391042631013949263414286890864159053318214251976688629488673272870767480));
        vk.IC[14] = Pairing.G1Point(uint256(10514878784208731976225237547153250361055470593826044255883835849726303614222), uint256(9154796104015155470267361332386150392098132416220118182488630708791988510994));
        vk.IC[15] = Pairing.G1Point(uint256(5656143925201060128927531292652589841865636439792530809977211589912455523299), uint256(17963769103616873259155670756780183983599509370811177819767852056518133420087));
        vk.IC[16] = Pairing.G1Point(uint256(18287756749551135501802732396145760864951173089832471956132102601465147953879), uint256(4313459855794286841764363967095687680302603333143831684195674038564338936575));
        vk.IC[17] = Pairing.G1Point(uint256(11852387825752536055006913236755757273324565433087838782506360830661591694793), uint256(3267728197930949676843038406825714779031388613526935036123559101282179797494));
        vk.IC[18] = Pairing.G1Point(uint256(19911781750312815074116011967928005574063484537810784659803298946764878965438), uint256(9237142560299522639335078983243848921244273793807111739544552000611279244293));
        vk.IC[19] = Pairing.G1Point(uint256(20067438311972094495871568406731607810122897312052080846841171437866278576014), uint256(7188106576414909859968265244481161413004528499341197744479506985575242148982));
        vk.IC[20] = Pairing.G1Point(uint256(5160039430689621681158338839425712921878203318176424301569546429535037834608), uint256(2707859762058630411406377778295751061912419469753307739083318799866294757441));
        vk.IC[21] = Pairing.G1Point(uint256(14660538248676455432997650171050324472414463607779952970515682987127396335829), uint256(10364726129441198657067276076223678797713735492899181520795845008448020250046));
        vk.IC[22] = Pairing.G1Point(uint256(14671470602756472601929044361733318623315079978143535379393542725925154421567), uint256(3912940355392174722450370077108637115435853092880247067373965898530498347399));
        vk.IC[23] = Pairing.G1Point(uint256(7131293111651333617082995772956843209408347371744340228640476170425764408040), uint256(15999824188826889997002122285120194719456651439519640745535206007372201632068));
        vk.IC[24] = Pairing.G1Point(uint256(12004717484178870065125617469513022817308824132176022156380136295141235786003), uint256(21376710971398415252509858520182983449989667137707141085039107298383420001607));
        vk.IC[25] = Pairing.G1Point(uint256(4856803391611152164221185989760258450640575200077203806738634282740267778623), uint256(87910675755079400640414496473391743232976607934355281771145783486639300455));
        vk.IC[26] = Pairing.G1Point(uint256(1965786569612591618836077870155558485512770947564895614955799428122679791845), uint256(8878140346071964323715975217452045946083100224403022752233562124818843382062));
        vk.IC[27] = Pairing.G1Point(uint256(378253791266448693824253143648575106654868322397238161589100716468335935055), uint256(14355443344973156811149431998657571038981224057918990468298444409723473409307));
        vk.IC[28] = Pairing.G1Point(uint256(8235725890245262242027778983518722884243665600204823878516495353711441122036), uint256(12130359003544918668986474058128145445774026039283634268976043901656347746034));
        vk.IC[29] = Pairing.G1Point(uint256(15482465721615720526519192675969821885947104754768320137906880946784886167235), uint256(1000866373291893850563905990958428640363670443204976791085124334812287367861));
        vk.IC[30] = Pairing.G1Point(uint256(21855987954476919238218998809740905274416570116861871350265189116242507745211), uint256(9430772068032460333039840146358890154183520562244118275892745905935531123998));
        vk.IC[31] = Pairing.G1Point(uint256(4341312120477270125089706043797599623735338569134277482137051424850911385053), uint256(2459628029830933476052102451579028040930434398429040675058465520567030420983));
    }

    /*
     * @returns Whether the proof is valid given the hardcoded verifying key
     *          above and the public inputs
     */
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[31] memory input
    ) public view returns (bool r) {

        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);

        VerifyingKey memory vk = verifyingKey();

        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);

        // Make sure that proof.A, B, and C are each less than the prime q
        require(proof.A.X < PRIME_Q, "verifier-aX-gte-prime-q");
        require(proof.A.Y < PRIME_Q, "verifier-aY-gte-prime-q");

        require(proof.B.X[0] < PRIME_Q, "verifier-bX0-gte-prime-q");
        require(proof.B.Y[0] < PRIME_Q, "verifier-bY0-gte-prime-q");

        require(proof.B.X[1] < PRIME_Q, "verifier-bX1-gte-prime-q");
        require(proof.B.Y[1] < PRIME_Q, "verifier-bY1-gte-prime-q");

        require(proof.C.X < PRIME_Q, "verifier-cX-gte-prime-q");
        require(proof.C.Y < PRIME_Q, "verifier-cY-gte-prime-q");

        // Make sure that every input is less than the snark scalar field
        for (uint256 i = 0; i < input.length; i++) {
            require(input[i] < SNARK_SCALAR_FIELD,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.plus(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }

        vk_x = Pairing.plus(vk_x, vk.IC[0]);

        return Pairing.pairing(
            Pairing.negate(proof.A),
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

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

contract BLS12381 {
    struct Fp {
        uint256 a;
        uint256 b;
    }

    uint8 constant MOD_EXP_PRECOMPILE_ADDRESS = 0x5;
    string constant BLS_SIG_DST = 'BLS_SIG_BLS12381G2_XMD:SHA-256_SSWU_RO_POP_+';

    // Reduce the number encoded as the big-endian slice of data[start:end] modulo the BLS12-381 field modulus.
    // Copying of the base is cribbed from the following:
    // https://github.com/ethereum/solidity-examples/blob/f44fe3b3b4cca94afe9c2a2d5b7840ff0fafb72e/src/unsafe/Memory.sol#L57-L74
    function reduceModulo(
        bytes memory data,
        uint256 start,
        uint256 end
    ) private view returns (bytes memory) {
        uint256 length = end - start;
        assert(length <= data.length);

        bytes memory result = new bytes(48);

        bool success;
        assembly {
            let p := mload(0x40)
        // length of base
            mstore(p, length)
        // length of exponent
            mstore(add(p, 0x20), 0x20)
        // length of modulus
            mstore(add(p, 0x40), 48)
        // base
        // first, copy slice by chunks of EVM words
            let ctr := length
            let src := add(add(data, 0x20), start)
            let dst := add(p, 0x60)
            for {

            } or(gt(ctr, 0x20), eq(ctr, 0x20)) {
                ctr := sub(ctr, 0x20)
            } {
                mstore(dst, mload(src))
                dst := add(dst, 0x20)
                src := add(src, 0x20)
            }
        // next, copy remaining bytes in last partial word
            let mask := sub(exp(256, sub(0x20, ctr)), 1)
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dst), mask)
            mstore(dst, or(destpart, srcpart))
        // exponent
            mstore(add(p, add(0x60, length)), 1)
        // modulus
            let modulusAddr := add(p, add(0x60, add(0x10, length)))
            mstore(
            modulusAddr,
            or(mload(modulusAddr), 0x1a0111ea397fe69a4b1ba7b6434bacd7)
            ) // pt 1
            mstore(
            add(p, add(0x90, length)),
            0x64774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaab
            ) // pt 2
            success := staticcall(
            sub(gas(), 2000),
            MOD_EXP_PRECOMPILE_ADDRESS,
            p,
            add(0xB0, length),
            add(result, 0x20),
            48
            )
        // Use "invalid" to make gas estimation work
            switch success
            case 0 {
                invalid()
            }
        }
        require(success, 'call to modular exponentiation precompile failed');
        return result;
    }

    function sliceToUint(
        bytes memory data,
        uint256 start,
        uint256 end
    ) private pure returns (uint256 result) {
        uint256 length = end - start;
        assert(length <= 32);

        for (uint256 i; i < length; ) {
            bytes1 b = data[start + i];
            result = result + (uint8(b) * 2**(8 * (length - i - 1)));
        unchecked {
            ++i;
        }
        }
    }

    function convertSliceToFp(
        bytes memory data,
        uint256 start,
        uint256 end
    ) private view returns (Fp memory) {
        bytes memory fieldElement = reduceModulo(data, start, end);
        uint256 a = sliceToUint(fieldElement, 0, 16);
        uint256 b = sliceToUint(fieldElement, 16, 48);
        return Fp(a, b);
    }

    function expandMessage(bytes32 message) private pure returns (bytes memory) {
        bytes memory b0Input = new bytes(143);
        for (uint256 i; i < 32; ) {
            b0Input[i + 64] = message[i];
        unchecked {
            ++i;
        }
        }
        b0Input[96] = 0x01;
        for (uint256 i; i < 44; ) {
            b0Input[i + 99] = bytes(BLS_SIG_DST)[i];
        unchecked {
            ++i;
        }
        }

        bytes32 b0 = sha256(abi.encodePacked(b0Input));

        bytes memory output = new bytes(256);
        bytes32 chunk = sha256(
            abi.encodePacked(b0, bytes1(0x01), bytes(BLS_SIG_DST))
        );
        assembly {
            mstore(add(output, 0x20), chunk)
        }

        for (uint256 i = 2; i < 9; ) {
            bytes32 input;
            assembly {
                input := xor(b0, mload(add(output, add(0x20, mul(0x20, sub(i, 2))))))
            }
            chunk = sha256(
                abi.encodePacked(input, bytes1(uint8(i)), bytes(BLS_SIG_DST))
            );
            assembly {
                mstore(add(output, add(0x20, mul(0x20, sub(i, 1)))), chunk)
            }
        unchecked {
            ++i;
        }
        }

        return output;
    }

    function FpToArray55_7(Fp memory fp) private pure returns (uint256[7] memory) {
        uint256[7] memory result;
        uint256 mask = ((1 << 55) - 1);
        result[0] = (fp.b & (mask << (55 * 0))) >> (55 * 0);
        result[1] = (fp.b & (mask << (55 * 1))) >> (55 * 1);
        result[2] = (fp.b & (mask << (55 * 2))) >> (55 * 2);
        result[3] = (fp.b & (mask << (55 * 3))) >> (55 * 3);
        result[4] = (fp.b & (mask << (55 * 4))) >> (55 * 4);
        uint256 newMask = (1 << 19) - 1;
        result[4] = result[4] | ((fp.a & newMask) << 36);
        result[5] = (fp.a & (mask << 19)) >> 19;
        result[6] = (fp.a & (mask << (55 + 19))) >> (55 + 19);

        return result;
    }

    function hashToField(bytes32 message)
    internal
    view
    returns (uint256[28] memory input)
    {
        bytes memory some_bytes = expandMessage(message);
        uint256[7][2][2] memory result;
        result[0][0] = FpToArray55_7(convertSliceToFp(some_bytes, 0, 64));
        result[0][1] = FpToArray55_7(convertSliceToFp(some_bytes, 64, 128));
        result[1][0] = FpToArray55_7(convertSliceToFp(some_bytes, 128, 192));
        result[1][1] = FpToArray55_7(convertSliceToFp(some_bytes, 192, 256));
        for (uint256 i = 0; i < 2; i++) {
            for (uint256 j = 0; j < 2; j++) {
                for (uint256 k = 0; k < 7; k++) {
                    input[i * 14 + j * 7 + k] = result[i][j][k];
                }
            }
        }
        return input;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0-rc.1) (utils/Address.sol)

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

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./MerkleProof.sol";
import "./ScaleCodec.sol";

contract BeaconChain is MerkleProof {
    uint64 constant internal SYNC_COMMITTEE_SIZE = 512;

    struct ForkData {
        bytes4 currentVersion;
        bytes32 genesisValidatorsRoot;
    }

    struct SigningData {
        bytes32 objectRoot;
        bytes32 domain;
    }

    struct BeaconBlockHeader {
        uint64 slot;
        uint64 proposerIndex;
        bytes32 parentRoot;
        bytes32 stateRoot;
        bytes32 bodyRoot;
    }

    // Return the signing root for the corresponding signing data.
    function computeSigningRoot(BeaconBlockHeader memory beaconHeader, bytes32 domain) internal pure returns (bytes32){
        return hashTreeRoot(SigningData({
                objectRoot: hashTreeRoot(beaconHeader),
                domain: domain
            })
        );
    }

    // Return the 32-byte fork data root for the ``current_version`` and ``genesis_validators_root``.
    // This is used primarily in signature domains to avoid collisions across forks/chains.
    function computeForkDataRoot(bytes4 currentVersion, bytes32 genesisValidatorsRoot) internal pure returns (bytes32){
        return hashTreeRoot(ForkData({
                currentVersion: currentVersion,
                genesisValidatorsRoot: genesisValidatorsRoot
            })
        );
    }

    //  Return the domain for the ``domain_type`` and ``fork_version``.
    function computeDomain(bytes4 domainType, bytes4 forkVersion, bytes32 genesisValidatorsRoot) internal pure returns (bytes32){
        bytes32 forkDataRoot = computeForkDataRoot(forkVersion, genesisValidatorsRoot);
        return bytes32(domainType) | forkDataRoot >> 32;
    }

    function hashTreeRoot(ForkData memory fork_data) internal pure returns (bytes32) {
        return hashNode(bytes32(fork_data.currentVersion), fork_data.genesisValidatorsRoot);
    }

    function hashTreeRoot(SigningData memory signingData) internal pure returns (bytes32) {
        return hashNode(signingData.objectRoot, signingData.domain);
    }

    function hashTreeRoot(BeaconBlockHeader memory beaconHeader) internal pure returns (bytes32) {
        bytes32[] memory leaves = new bytes32[](5);
        leaves[0] = bytes32(toLittleEndian64(beaconHeader.slot));
        leaves[1] = bytes32(toLittleEndian64(beaconHeader.proposerIndex));
        leaves[2] = beaconHeader.parentRoot;
        leaves[3] = beaconHeader.stateRoot;
        leaves[4] = beaconHeader.bodyRoot;
        return merkleRoot(leaves);
    }

    function toLittleEndian64(uint64 value) internal pure returns (bytes8) {
        return ScaleCodec.encode64(value);
    }

    function toLittleEndian256(uint256 value) internal pure returns (bytes32) {
        return ScaleCodec.encode256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Math.sol";

contract MerkleProof is Math {
    // Check if ``leaf`` at ``index`` verifies against the Merkle ``root`` and ``branch``.
    function isValidMerkleBranch(
        bytes32 leaf,
        bytes32[] memory branch,
        uint64 depth,
        uint64 index,
        bytes32 root
    ) internal pure returns (bool) {
        bytes32 value = leaf;
        for (uint i = 0; i < depth; ++i) {
            if ((index / (2**i)) % 2 == 1) {
                value = hashNode(branch[i], value);
            } else {
                value = hashNode(value, branch[i]);
            }
        }
        return value == root;
    }

    function merkleRoot(bytes32[] memory leaves) internal pure returns (bytes32) {
        uint len = leaves.length;
        if (len == 0) return bytes32(0);
        else if (len == 1) return hash(abi.encodePacked(leaves[0]));
        else if (len == 2) return hashNode(leaves[0], leaves[1]);
        uint bottomLength = getPowerOfTwoCeil(len);
        bytes32[] memory o = new bytes32[](bottomLength * 2);
        for (uint i = 0; i < len; ++i) {
            o[bottomLength + i] = leaves[i];
        }
        for (uint i = bottomLength - 1; i > 0; --i) {
            o[i] = hashNode(o[i * 2], o[i * 2 + 1]);
        }
        return o[1];
    }


    function hashNode(bytes32 left, bytes32 right)
        internal
        pure
        returns (bytes32)
    {
        return hash(abi.encodePacked(left, right));
    }

    function hash(bytes memory value) internal pure returns (bytes32) {
        return sha256(value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library ScaleCodec {
    // Decodes a SCALE encoded uint256 by converting bytes (bid endian) to little endian format
    function decodeUint256(bytes memory data) internal pure returns (uint256) {
        uint256 number;
        for (uint256 i = data.length; i > 0; i--) {
            number = number + uint256(uint8(data[i - 1])) * (2**(8 * (i - 1)));
        }
        return number;
    }

    // Decodes a SCALE encoded compact unsigned integer
    function decodeUintCompact(bytes memory data)
        internal
        pure
        returns (uint256 v)
    {
        uint8 b = readByteAtIndex(data, 0); // read the first byte
        uint8 mode = b & 3; // bitwise operation

        if (mode == 0) {
            // [0, 63]
            return b >> 2; // right shift to remove mode bits
        } else if (mode == 1) {
            // [64, 16383]
            uint8 bb = readByteAtIndex(data, 1); // read the second byte
            uint64 r = bb; // convert to uint64
            r <<= 6; // multiply by * 2^6
            r += b >> 2; // right shift to remove mode bits
            return r;
        } else if (mode == 2) {
            // [16384, 1073741823]
            uint8 b2 = readByteAtIndex(data, 1); // read the next 3 bytes
            uint8 b3 = readByteAtIndex(data, 2);
            uint8 b4 = readByteAtIndex(data, 3);

            uint32 x1 = uint32(b) | (uint32(b2) << 8); // convert to little endian
            uint32 x2 = x1 | (uint32(b3) << 16);
            uint32 x3 = x2 | (uint32(b4) << 24);

            x3 >>= 2; // remove the last 2 mode bits
            return uint256(x3);
        } else if (mode == 3) {
            // [1073741824, 4503599627370496]
            // solhint-disable-next-line
            uint8 l = b >> 2; // remove mode bits
            require(
                l > 32,
                "Not supported: number cannot be greater than 32 bytes"
            );
        } else {
            revert("Code should be unreachable");
        }
    }

    // Read a byte at a specific index and return it as type uint8
    function readByteAtIndex(bytes memory data, uint8 index)
        internal
        pure
        returns (uint8)
    {
        return uint8(data[index]);
    }

    // Sources:
    //   * https://ethereum.stackexchange.com/questions/15350/how-to-convert-an-bytes-to-address-in-solidity/50528
    //   * https://graphics.stanford.edu/~seander/bithacks.html#ReverseParallel

    function reverse256(uint256 input) internal pure returns (uint256 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = ((v & 0xFFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF0000000000000000) >> 64) |
            ((v & 0x0000000000000000FFFFFFFFFFFFFFFF0000000000000000FFFFFFFFFFFFFFFF) << 64);

        // swap 16-byte long pairs
        v = (v >> 128) | (v << 128);
    }

    function reverse128(uint128 input) internal pure returns (uint128 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00FF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000FFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = ((v & 0xFFFFFFFF00000000FFFFFFFF00000000) >> 32) |
            ((v & 0x00000000FFFFFFFF00000000FFFFFFFF) << 32);

        // swap 8-byte long pairs
        v = (v >> 64) | (v << 64);
    }

    function reverse64(uint64 input) internal pure returns (uint64 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00FF00FF00) >> 8) |
            ((v & 0x00FF00FF00FF00FF) << 8);

        // swap 2-byte long pairs
        v = ((v & 0xFFFF0000FFFF0000) >> 16) |
            ((v & 0x0000FFFF0000FFFF) << 16);

        // swap 4-byte long pairs
        v = (v >> 32) | (v << 32);
    }

    function reverse32(uint32 input) internal pure returns (uint32 v) {
        v = input;

        // swap bytes
        v = ((v & 0xFF00FF00) >> 8) |
            ((v & 0x00FF00FF) << 8);

        // swap 2-byte long pairs
        v = (v >> 16) | (v << 16);
    }

    function reverse16(uint16 input) internal pure returns (uint16 v) {
        v = input;

        // swap bytes
        v = (v >> 8) | (v << 8);
    }

    function encode256(uint256 input) internal pure returns (bytes32) {
        return bytes32(reverse256(input));
    }

    function encode128(uint128 input) internal pure returns (bytes16) {
        return bytes16(reverse128(input));
    }

    function encode64(uint64 input) internal pure returns (bytes8) {
        return bytes8(reverse64(input));
    }

    function encode32(uint32 input) internal pure returns (bytes4) {
        return bytes4(reverse32(input));
    }

    function encode16(uint16 input) internal pure returns (bytes2) {
        return bytes2(reverse16(input));
    }

    function encode8(uint8 input) internal pure returns (bytes1) {
        return bytes1(input);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Math {
    /// Get the power of 2 for given input, or the closest higher power of 2 if the input is not a power of 2.
    /// Commonly used for "how many nodes do I need for a bottom tree layer fitting x elements?"
    /// Example: 0->1, 1->1, 2->2, 3->4, 4->4, 5->8, 6->8, 7->8, 8->8, 9->16.
    function getPowerOfTwoCeil(uint256 x) internal pure returns (uint256) {
        if (x <= 1) return 1;
        else if (x == 2) return 2;
        else return 2 * getPowerOfTwoCeil((x + 1) >> 1);
    }

    function log_2(uint256 x) internal pure returns (uint256 pow) {
        require(0 < x && x < 0x8000000000000000000000000000000000000000000000000000000000000001, "invalid");
        uint256 a = 1;
        while (a < x) {
            a <<= 1;
            pow++;
        }
    }

    function _max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
}