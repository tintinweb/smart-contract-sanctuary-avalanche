pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0




import "./SafeMath.sol";
import "./Events.sol";
import "./Ownable.sol";
import "./Upgradeable.sol";
import "./UpgradeableMaster.sol";

/// @title Upgrade Gatekeeper Contract
/// @author Matter Labs
contract UpgradeGatekeeper is UpgradeEvents, Ownable {
    using SafeMath for uint256;

    /// @notice Array of addresses of upgradeable contracts managed by the gatekeeper
    Upgradeable[] public managedContracts;

    /// @notice Upgrade mode statuses
    enum UpgradeStatus {Idle, NoticePeriod, Preparation}

    UpgradeStatus public upgradeStatus;

    /// @notice Notice period finish timestamp (as seconds since unix epoch)
    /// @dev Will be equal to zero in case of not active upgrade mode
    uint256 public noticePeriodFinishTimestamp;

    /// @notice Addresses of the next versions of the contracts to be upgraded (if element of this array is equal to zero address it means that appropriate upgradeable contract wouldn't be upgraded this time)
    /// @dev Will be empty in case of not active upgrade mode
    address[] public nextTargets;

    /// @notice Version id of contracts
    uint256 public versionId;

    /// @notice Contract which defines notice period duration and allows finish upgrade during preparation of it
    UpgradeableMaster public mainContract;

    /// @notice Contract constructor
    /// @param _mainContract Contract which defines notice period duration and allows finish upgrade during preparation of it
    /// @dev Calls Ownable contract constructor
    constructor(UpgradeableMaster _mainContract) Ownable(msg.sender) {
        mainContract = _mainContract;
        versionId = 0;
    }

    /// @notice Adds a new upgradeable contract to the list of contracts managed by the gatekeeper
    /// @param addr Address of upgradeable contract to add
    function addUpgradeable(address addr) external {
        requireMaster(msg.sender);
        require(upgradeStatus == UpgradeStatus.Idle, "apc11"); /// apc11 - upgradeable contract can't be added during upgrade

        managedContracts.push(Upgradeable(addr));
        emit NewUpgradable(versionId, addr);
    }

    /// @notice Starts upgrade (activates notice period)
    /// @param newTargets New managed contracts targets (if element of this array is equal to zero address it means that appropriate upgradeable contract wouldn't be upgraded this time)
    function startUpgrade(address[] calldata newTargets) external {
        requireMaster(msg.sender);
        require(upgradeStatus == UpgradeStatus.Idle, "spu11"); // spu11 - unable to activate active upgrade mode
        require(newTargets.length == managedContracts.length, "spu12"); // spu12 - number of new targets must be equal to the number of managed contracts

        uint256 noticePeriod = mainContract.getNoticePeriod();
        upgradeStatus = UpgradeStatus.NoticePeriod;
        noticePeriodFinishTimestamp = block.timestamp.add(noticePeriod);
        nextTargets = newTargets;
        emit NoticePeriodStart(versionId, newTargets, noticePeriod);
    }

    /// @notice Cancels upgrade
    function cancelUpgrade() external {
        requireMaster(msg.sender);
        require(upgradeStatus != UpgradeStatus.Idle, "cpu11"); // cpu11 - unable to cancel not active upgrade mode

        upgradeStatus = UpgradeStatus.Idle;
        noticePeriodFinishTimestamp = 0;
        delete nextTargets;
        emit UpgradeCancel(versionId);
    }

    /// @notice Activates preparation status
    /// @return Bool flag indicating that preparation status has been successfully activated
    function startPreparation() external returns (bool) {
        requireMaster(msg.sender);
        require(upgradeStatus == UpgradeStatus.NoticePeriod, "ugp11"); // ugp11 - unable to activate preparation status in case of not active notice period status

        if (block.timestamp >= noticePeriodFinishTimestamp) {
            upgradeStatus = UpgradeStatus.Preparation;
            emit PreparationStart(versionId);
            return true;
        } else {
            return false;
        }
    }

    /// @notice Finishes upgrade
    /// @param targetsUpgradeParameters New targets upgrade parameters per each upgradeable contract
    function finishUpgrade(bytes[] calldata targetsUpgradeParameters) external {
        requireMaster(msg.sender);
        require(upgradeStatus == UpgradeStatus.Preparation, "fpu11"); // fpu11 - unable to finish upgrade without preparation status active
        require(targetsUpgradeParameters.length == managedContracts.length, "fpu12"); // fpu12 - number of new targets upgrade parameters must be equal to the number of managed contracts
        require(mainContract.isReadyForUpgrade(), "fpu13"); // fpu13 - main contract is not ready for upgrade

        for (uint64 i = 0; i < managedContracts.length; i++) {
            address newTarget = nextTargets[i];
            if (newTarget != address(0)) {
                managedContracts[i].upgradeTarget(newTarget, targetsUpgradeParameters[i]);
            }
        }
        versionId++;
        emit UpgradeComplete(versionId, nextTargets);

        upgradeStatus = UpgradeStatus.Idle;
        noticePeriodFinishTimestamp = 0;
        delete nextTargets;
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



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
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "14");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "v");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
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
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "15");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "x");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "y");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
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

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./Upgradeable.sol";
import "./Operations.sol";

/// @title zkSync events
/// @author Matter Labs
interface Events {
    /// @notice Event emitted when a block is committed
    event BlockCommit(uint32 indexed blockNumber);

    /// @notice Event emitted when a block is verified
    event BlockVerification(uint32 indexed blockNumber);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state and contract
    event Withdrawal(uint16 indexed tokenId, uint128 amount);

    /// @notice Event emitted when user funds are withdrawn from the zkLink state but not from contract
    event WithdrawalPending(uint16 indexed tokenId, address indexed recepient, uint128 amount);

    /// @notice Event emitted when user sends a authentication fact (e.g. pub-key hash)
    event FactAuth(address indexed sender, uint32 nonce, bytes fact);

    /// @notice Event emitted when blocks are reverted
    event BlocksRevert(uint32 totalBlocksVerified, uint32 totalBlocksCommitted);

    /// @notice Exodus mode entered event
    event ExodusMode();

    /// @notice New priority request event. Emitted when a request is placed into mapping
    event NewPriorityRequest(
        address sender,
        uint64 serialId,
        Operations.OpType opType,
        bytes pubData,
        uint256 expirationBlock
    );
}

/// @title Upgrade events
/// @author Matter Labs
interface UpgradeEvents {
    /// @notice Event emitted when new upgradeable contract is added to upgrade gatekeeper's list of managed contracts
    event NewUpgradable(uint256 indexed versionId, address indexed upgradeable);

    /// @notice Upgrade mode enter event
    event NoticePeriodStart(
        uint256 indexed versionId,
        address[] newTargets,
        uint256 noticePeriod // notice period (in seconds)
    );

    /// @notice Upgrade mode cancel event
    event UpgradeCancel(uint256 indexed versionId);

    /// @notice Upgrade mode preparation status event
    event PreparationStart(uint256 indexed versionId);

    /// @notice Upgrade mode complete event
    event UpgradeComplete(uint256 indexed versionId, address[] newTargets);
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Ownable Contract
/// @author Matter Labs
contract Ownable {
    /// @dev Storage position of the masters address (keccak256('eip1967.proxy.admin') - 1)
    bytes32 private constant masterPosition = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /// @notice Contract constructor
    /// @dev Sets msg sender address as masters address
    /// @param masterAddress Master address
    constructor(address masterAddress) {
        setMaster(masterAddress);
    }

    /// @notice Check if specified address is master
    /// @param _address Address to check
    function requireMaster(address _address) internal view {
        require(_address == getMaster(), "1c"); // oro11 - only by master
    }

    /// @notice Returns contract masters address
    /// @return master Master's address
    function getMaster() public view returns (address master) {
        bytes32 position = masterPosition;
        assembly {
            master := sload(position)
        }
    }

    /// @dev Sets new masters address
    /// @param _newMaster New master's address
    function setMaster(address _newMaster) internal {
        bytes32 position = masterPosition;
        assembly {
            sstore(position, _newMaster)
        }
    }

    /// @notice Transfer mastership of the contract to new master
    /// @param _newMaster New masters address
    function transferMastership(address _newMaster) external {
        requireMaster(msg.sender);
        require(_newMaster != address(0), "1d"); // otp11 - new masters address can't be zero address
        setMaster(_newMaster);
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Interface of the upgradeable contract
/// @author Matter Labs
interface Upgradeable {
    /// @notice Upgrades target of upgradeable contract
    /// @param newTarget New target
    /// @param newTargetInitializationParameters New target initialization parameters
    function upgradeTarget(address newTarget, bytes calldata newTargetInitializationParameters) external;
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



/// @title Interface of the upgradeable master contract (defines notice period duration and allows finish upgrade during preparation of it)
/// @author Matter Labs
interface UpgradeableMaster {
    /// @notice Notice period before activation preparation status of upgrade mode
    function getNoticePeriod() external returns (uint256);

    /// @notice Checks that contract is ready for upgrade
    /// @return bool flag indicating that contract is ready for upgrade
    function isReadyForUpgrade() external returns (bool);
}

pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;

// SPDX-License-Identifier: MIT OR Apache-2.0





import "./Bytes.sol";
import "./Utils.sol";

/// @title zkSync operations tools
/// @dev Circuit ops and their pubdata (chunks * bytes)
library Operations {
    /// @dev zkSync circuit operation type
    enum OpType {
        Noop, // 0
        Deposit, // 1 L1 Op
        TransferToNew, // 2 L2 Op
        Withdraw, // 3 L2 Op
        Transfer, // 4 L2 Op
        FullExit, // 5 L1 Op
        ChangePubKey, // 6 L2 Op
        ForcedExit, // 7 L2 Op
        L2CurveAddLiq, // 8 L2 Op
        L2CurveSwap, // 9 L2 Op
        L2CurveRemoveLiquidity, // 10 Op
        OrderMatching // 11 L2 Op
    }

    // Byte lengths

    /// @dev op is uint8
    uint8 constant OP_TYPE_BYTES = 1;

    /// @dev chainId is uint8
    uint8 constant CHAIN_BYTES = 1;

    /// @dev token is uint16
    uint8 constant TOKEN_BYTES = 2;

    /// @dev nonce is uint32
    uint8 constant NONCE_BYTES = 4;

    /// @dev address is 20 bytes length
    uint8 constant ADDRESS_BYTES = 20;

    /// @dev fee is uint16
    uint8 constant FEE_BYTES = 2;

    /// @dev accountId is uint32
    uint8 constant ACCOUNT_ID_BYTES = 4;

    /// @dev subAccountId is uint8
    uint8 constant SUB_ACCOUNT_ID_BYTES = 1;

    /// @dev amount is uint128
    uint8 constant AMOUNT_BYTES = 16;

    // Priority operations: Deposit, FullExit
    struct PriorityOperation {
        bytes20 hashedPubData; // hashed priority operation public data
        uint64 expirationBlock; // expiration block number (ETH block) for this request (must be satisfied before)
        OpType opType; // priority operation type
    }

    struct Deposit {
        // uint8 opType
        uint8 chainId; // deposit from which chain that identified by l2 chain id
        uint32 accountId; // the account id bound to the owner address, ignored at serialization and will be set when the block is submitted
        uint8 subAccountId; // the sub account is bound to account, default value is 0(the global public sub account)
        uint16 tokenId; // the token that registered to l2
        uint128 amount; // the token amount deposited to l2
        address owner; // the address that receive deposited token at l2
    }

    uint256 public constant PACKED_DEPOSIT_PUBDATA_BYTES =
        OP_TYPE_BYTES + CHAIN_BYTES + ACCOUNT_ID_BYTES + SUB_ACCOUNT_ID_BYTES + TOKEN_BYTES + AMOUNT_BYTES + ADDRESS_BYTES; // 45

    /// @dev Deserialize deposit pubdata
    function readDepositPubdata(bytes memory _data) internal pure returns (Deposit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        (offset, parsed.subAccountId) = Bytes.readUint8(_data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);

        require(offset == PACKED_DEPOSIT_PUBDATA_BYTES, "OP: invalid deposit");
    }

    /// @dev Serialize deposit pubdata
    function writeDepositPubdataForPriorityQueue(Deposit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(OpType.Deposit),
            op.chainId,
            uint32(0), // accountId (ignored during hash calculation)
            op.subAccountId,
            op.tokenId,
            op.amount,
            op.owner
        );
    }

    /// @dev Checks that deposit is same as operation in priority queue
    function checkPriorityOperation(Deposit memory _deposit, PriorityOperation memory _priorityOperation) internal pure {
        require(_priorityOperation.opType == Operations.OpType.Deposit, "OP: not deposit");
        require(Utils.hashBytesToBytes20(writeDepositPubdataForPriorityQueue(_deposit)) == _priorityOperation.hashedPubData, "OP: invalid deposit hash");
    }

    struct FullExit {
        // uint8 opType
        uint8 chainId; // withdraw to which chain that identified by l2 chain id
        uint32 accountId; // the account id to withdraw from
        uint8 subAccountId; // the sub account is bound to account, default value is 0(the global public sub account)
        address owner; // the address that own the account at l2
        uint16 tokenId; // the token that registered to l2
        uint128 amount; // the token amount that fully withdrawn to owner, ignored at serialization and will be set when the block is submitted
    }

    uint256 public constant PACKED_FULL_EXIT_PUBDATA_BYTES =
        OP_TYPE_BYTES + CHAIN_BYTES + ACCOUNT_ID_BYTES + SUB_ACCOUNT_ID_BYTES + ADDRESS_BYTES + TOKEN_BYTES + AMOUNT_BYTES; // 45

    /// @dev Deserialize fullExit pubdata
    function readFullExitPubdata(bytes memory _data) internal pure returns (FullExit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        (offset, parsed.subAccountId) = Bytes.readUint8(_data, offset);
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);

        require(offset == PACKED_FULL_EXIT_PUBDATA_BYTES, "OP: invalid fullExit");
    }

    /// @dev Serialize fullExit pubdata
    function writeFullExitPubdataForPriorityQueue(FullExit memory op) internal pure returns (bytes memory buf) {
        buf = abi.encodePacked(
            uint8(OpType.FullExit),
            op.chainId,
            op.accountId,
            op.subAccountId,
            op.owner,
            op.tokenId,
            uint128(0) // amount(ignored during hash calculation)
        );
    }

    /// @dev Checks that FullExit is same as operation in priority queue
    function checkPriorityOperation(FullExit memory _fullExit, PriorityOperation memory _priorityOperation) internal pure {
        require(_priorityOperation.opType == Operations.OpType.FullExit, "OP: not fullExit");
        require(Utils.hashBytesToBytes20(writeFullExitPubdataForPriorityQueue(_fullExit)) == _priorityOperation.hashedPubData, "OP: invalid fullExit hash");
    }

    struct Withdraw {
        //uint8 opType; -- present in pubdata, ignored at serialization
        uint8 chainId; // which chain the withdraw happened
        uint32 accountId; // the account id to withdraw from
        //uint8 subAccountId; -- present in pubdata, ignored at serialization
        uint16 tokenId; // the token that to withdraw
        uint128 amount; // the token amount to withdraw
        //uint16 fee; -- present in pubdata, ignored at serialization
        address owner; // the address to receive token
        uint32 nonce; // zero means normal withdraw, not zero means fast withdraw and the value is the account nonce
        uint16 fastWithdrawFeeRate; // fast withdraw fee rate taken by accepter
    } // 53

    function readWithdrawPubdata(bytes memory _data) internal pure returns (Withdraw memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        offset += SUB_ACCOUNT_ID_BYTES;
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
        offset += FEE_BYTES;
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);
        (offset, parsed.nonce) = Bytes.readUInt32(_data, offset);
        (offset, parsed.fastWithdrawFeeRate) = Bytes.readUInt16(_data, offset);
    }

    struct ForcedExit {
        //uint8 opType; -- present in pubdata, ignored at serialization
        uint8 chainId; // which chain the force exit happened
        //uint32 initiatorAccountId; -- present in pubdata, ignored at serialization
        //uint32 targetAccountId; -- present in pubdata, ignored at serialization
        //uint8 targetSubAccountId; -- present in pubdata, ignored at serialization
        uint16 tokenId; // the token that to withdraw
        uint128 amount; // the token amount to withdraw
        //uint16 fee; -- present in pubdata, ignored at serialization
        address target; // the address to receive token
    } // 51 bytes

    function readForcedExitPubdata(bytes memory _data) internal pure returns (ForcedExit memory parsed) {
        // NOTE: there is no check that variable sizes are same as constants (i.e. TOKEN_BYTES), fix if possible.
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        offset += ACCOUNT_ID_BYTES + ACCOUNT_ID_BYTES + SUB_ACCOUNT_ID_BYTES;
        (offset, parsed.tokenId) = Bytes.readUInt16(_data, offset);
        (offset, parsed.amount) = Bytes.readUInt128(_data, offset);
        offset += FEE_BYTES;
        (offset, parsed.target) = Bytes.readAddress(_data, offset);
    }

    // ChangePubKey
    struct ChangePubKey {
        // uint8 opType; -- present in pubdata, ignored at serialization
        uint8 chainId; // which chain to verify(only one chain need to verify for gas saving)
        uint32 accountId; // the account that to change pubkey
        bytes20 pubKeyHash; // hash of the new rollup pubkey
        address owner; // the owner that own this account
        uint32 nonce; // the account nonce
        //uint16 tokenId; -- present in pubdata, ignored at serialization
        //uint16 fee; -- present in pubdata, ignored at serialization
    } // 54 bytes

    function readChangePubKeyPubdata(bytes memory _data) internal pure returns (ChangePubKey memory parsed) {
        uint256 offset = OP_TYPE_BYTES;
        (offset, parsed.chainId) = Bytes.readUint8(_data, offset);
        (offset, parsed.accountId) = Bytes.readUInt32(_data, offset);
        (offset, parsed.pubKeyHash) = Bytes.readBytes20(_data, offset);
        (offset, parsed.owner) = Bytes.readAddress(_data, offset);
        (offset, parsed.nonce) = Bytes.readUInt32(_data, offset);
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



// Functions named bytesToX, except bytesToBytes20, where X is some type of size N < 32 (size of one word)
// implements the following algorithm:
// f(bytes memory input, uint offset) -> X out
// where byte representation of out is N bytes from input at the given offset
// 1) We compute memory location of the word W such that last N bytes of W is input[offset..offset+N]
// W_address = input + 32 (skip stored length of bytes) + offset - (32 - N) == input + offset + N
// 2) We load W from memory into out, last N bytes of W are placed into out

library Bytes {
    function toBytesFromUInt16(uint16 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 2);
    }

    function toBytesFromUInt24(uint24 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 3);
    }

    function toBytesFromUInt32(uint32 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 4);
    }

    function toBytesFromUInt128(uint128 self) internal pure returns (bytes memory _bts) {
        return toBytesFromUIntTruncated(uint256(self), 16);
    }

    // Copies 'len' lower bytes from 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length 'len'.
    function toBytesFromUIntTruncated(uint256 self, uint8 byteLength) private pure returns (bytes memory bts) {
        require(byteLength <= 32, "Q");
        bts = new bytes(byteLength);
        // Even though the bytes will allocate a full word, we don't want
        // any potential garbage bytes in there.
        uint256 data = self << ((32 - byteLength) * 8);
        assembly {
            mstore(
                add(bts, 32), // BYTES_HEADER_SIZE
                data
            )
        }
    }

    // Copies 'self' into a new 'bytes memory'.
    // Returns the newly created 'bytes memory'. The returned bytes will be of length '20'.
    function toBytesFromAddress(address self) internal pure returns (bytes memory bts) {
        bts = toBytesFromUIntTruncated(uint256(self), 20);
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToAddress(bytes memory self, uint256 _start) internal pure returns (address addr) {
        uint256 offset = _start + 20;
        require(self.length >= offset, "R");
        assembly {
            addr := mload(add(self, offset))
        }
    }

    // Reasoning about why this function works is similar to that of other similar functions, except NOTE below.
    // NOTE: that bytes1..32 is stored in the beginning of the word unlike other primitive types
    // NOTE: theoretically possible overflow of (_start + 20)
    function bytesToBytes20(bytes memory self, uint256 _start) internal pure returns (bytes20 r) {
        require(self.length >= (_start + 20), "S");
        assembly {
            r := mload(add(add(self, 0x20), _start))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x2)
    function bytesToUInt16(bytes memory _bytes, uint256 _start) internal pure returns (uint16 r) {
        uint256 offset = _start + 0x2;
        require(_bytes.length >= offset, "T");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x3)
    function bytesToUInt24(bytes memory _bytes, uint256 _start) internal pure returns (uint24 r) {
        uint256 offset = _start + 0x3;
        require(_bytes.length >= offset, "U");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x4)
    function bytesToUInt32(bytes memory _bytes, uint256 _start) internal pure returns (uint32 r) {
        uint256 offset = _start + 0x4;
        require(_bytes.length >= offset, "V");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x10)
    function bytesToUInt128(bytes memory _bytes, uint256 _start) internal pure returns (uint128 r) {
        uint256 offset = _start + 0x10;
        require(_bytes.length >= offset, "W");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // See comment at the top of this file for explanation of how this function works.
    // NOTE: theoretically possible overflow of (_start + 0x14)
    function bytesToUInt160(bytes memory _bytes, uint256 _start) internal pure returns (uint160 r) {
        uint256 offset = _start + 0x14;
        require(_bytes.length >= offset, "X");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // NOTE: theoretically possible overflow of (_start + 0x20)
    function bytesToBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32 r) {
        uint256 offset = _start + 0x20;
        require(_bytes.length >= offset, "Y");
        assembly {
            r := mload(add(_bytes, offset))
        }
    }

    // Original source code: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol#L228
    // Get slice from bytes arrays
    // Returns the newly created 'bytes memory'
    // NOTE: theoretically possible overflow of (_start + _length)
    function slice(
        bytes memory _bytes,
        uint256 _start,
        uint256 _length
    ) internal pure returns (bytes memory) {
        require(_bytes.length >= (_start + _length), "Z"); // bytes length is less then start byte + length bytes

        bytes memory tempBytes = new bytes(_length);

        if (_length != 0) {
            assembly {
                let slice_curr := add(tempBytes, 0x20)
                let slice_end := add(slice_curr, _length)

                for {
                    let array_current := add(_bytes, add(_start, 0x20))
                } lt(slice_curr, slice_end) {
                    slice_curr := add(slice_curr, 0x20)
                    array_current := add(array_current, 0x20)
                } {
                    mstore(slice_curr, mload(array_current))
                }
            }
        }

        return tempBytes;
    }

    /// Reads byte stream
    /// @return new_offset - offset + amount of bytes read
    /// @return data - actually read data
    // NOTE: theoretically possible overflow of (_offset + _length)
    function read(
        bytes memory _data,
        uint256 _offset,
        uint256 _length
    ) internal pure returns (uint256 new_offset, bytes memory data) {
        data = slice(_data, _offset, _length);
        new_offset = _offset + _length;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readBool(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, bool r) {
        new_offset = _offset + 1;
        r = uint8(_data[_offset]) != 0;
    }

    // NOTE: theoretically possible overflow of (_offset + 1)
    function readUint8(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint8 r) {
        new_offset = _offset + 1;
        r = uint8(_data[_offset]);
    }

    // NOTE: theoretically possible overflow of (_offset + 2)
    function readUInt16(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint16 r) {
        new_offset = _offset + 2;
        r = bytesToUInt16(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 3)
    function readUInt24(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint24 r) {
        new_offset = _offset + 3;
        r = bytesToUInt24(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 4)
    function readUInt32(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint32 r) {
        new_offset = _offset + 4;
        r = bytesToUInt32(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 16)
    function readUInt128(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint128 r) {
        new_offset = _offset + 16;
        r = bytesToUInt128(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readUInt160(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, uint160 r) {
        new_offset = _offset + 20;
        r = bytesToUInt160(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readAddress(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, address r) {
        new_offset = _offset + 20;
        r = bytesToAddress(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 20)
    function readBytes20(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, bytes20 r) {
        new_offset = _offset + 20;
        r = bytesToBytes20(_data, _offset);
    }

    // NOTE: theoretically possible overflow of (_offset + 32)
    function readBytes32(bytes memory _data, uint256 _offset) internal pure returns (uint256 new_offset, bytes32 r) {
        new_offset = _offset + 32;
        r = bytesToBytes32(_data, _offset);
    }

    /// Trim bytes into single word
    function trim(bytes memory _data, uint256 _new_length) internal pure returns (uint256 r) {
        require(_new_length <= 0x20, "10"); // new_length is longer than word
        require(_data.length >= _new_length, "11"); // data is to short

        uint256 a;
        assembly {
            a := mload(add(_data, 0x20)) // load bytes into uint256
        }

        return a >> ((0x20 - _new_length) * 8);
    }

    // Helper function for hex conversion.
    function halfByteToHex(bytes1 _byte) internal pure returns (bytes1 _hexByte) {
        require(uint8(_byte) < 0x10, "hbh11"); // half byte's value is out of 0..15 range.

        // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
        return bytes1(uint8(0x66656463626139383736353433323130 >> (uint8(_byte) * 8)));
    }

    // Convert bytes to ASCII hex representation
    function bytesToHexASCIIBytes(bytes memory _input) internal pure returns (bytes memory _output) {
        bytes memory outStringBytes = new bytes(_input.length * 2);

        // code in `assembly` construction is equivalent of the next code:
        // for (uint i = 0; i < _input.length; ++i) {
        //     outStringBytes[i*2] = halfByteToHex(_input[i] >> 4);
        //     outStringBytes[i*2+1] = halfByteToHex(_input[i] & 0x0f);
        // }
        assembly {
            let input_curr := add(_input, 0x20)
            let input_end := add(input_curr, mload(_input))

            for {
                let out_curr := add(outStringBytes, 0x20)
            } lt(input_curr, input_end) {
                input_curr := add(input_curr, 0x01)
                out_curr := add(out_curr, 0x02)
            } {
                let curr_input_byte := shr(0xf8, mload(input_curr))
                // here outStringByte from each half of input byte calculates by the next:
                //
                // "FEDCBA9876543210" ASCII-encoded, shifted and automatically truncated.
                // outStringByte = byte (uint8 (0x66656463626139383736353433323130 >> (uint8 (_byteHalf) * 8)))
                mstore(
                    out_curr,
                    shl(0xf8, shr(mul(shr(0x04, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
                mstore(
                    add(out_curr, 0x01),
                    shl(0xf8, shr(mul(and(0x0f, curr_input_byte), 0x08), 0x66656463626139383736353433323130))
                )
            }
        }
        return outStringBytes;
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: MIT OR Apache-2.0



import "./IERC20.sol";
import "./Bytes.sol";

library Utils {
    /// @notice Returns lesser of two values
    function minU32(uint32 a, uint32 b) internal pure returns (uint32) {
        return a < b ? a : b;
    }

    /// @notice Returns lesser of two values
    function minU64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    /// @notice Returns lesser of two values
    function minU128(uint128 a, uint128 b) internal pure returns (uint128) {
        return a < b ? a : b;
    }

    /// @notice Recovers signer's address from ethereum signature for given message
    /// @param _signature 65 bytes concatenated. R (32) + S (32) + V (1)
    /// @param _messageHash signed message hash.
    /// @return address of the signer
    function recoverAddressFromEthSignature(bytes memory _signature, bytes32 _messageHash)
        internal
        pure
        returns (address)
    {
        require(_signature.length == 65, "P"); // incorrect signature length

        bytes32 signR;
        bytes32 signS;
        uint8 signV;
        assembly {
            signR := mload(add(_signature, 32))
            signS := mload(add(_signature, 64))
            signV := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(_messageHash, signV, signR, signS);
    }

    /// @notice Returns new_hash = hash(old_hash + bytes)
    function concatHash(bytes32 _hash, bytes memory _bytes) internal pure returns (bytes32) {
        bytes32 result;
        assembly {
            let bytesLen := add(mload(_bytes), 32)
            mstore(_bytes, _hash)
            result := keccak256(_bytes, bytesLen)
        }
        return result;
    }

    function hashBytesToBytes20(bytes memory _bytes) internal pure returns (bytes20) {
        return bytes20(uint160(uint256(keccak256(_bytes))));
    }
}

pragma solidity ^0.7.0;

// SPDX-License-Identifier: UNLICENSED


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
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external;

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
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

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