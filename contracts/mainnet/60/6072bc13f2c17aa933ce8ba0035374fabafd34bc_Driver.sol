// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;
import {IERC20} from "../src/interfaces/IERC20.sol";
import {ISettlement} from "../src/interfaces/ISettlement.sol";
import {OrderLib} from "../src/lib/Order.sol";

/// @author Openflow
/// @title Multisig Driver
/// @notice This contract manages the signing logic for Openflow multisig authenticated swap auctions.
contract Driver {
    /// @dev OrderLib is used to generate and decode unique UIDs per order.
    /// A UID consists of digest hash, owner and validTo.
    using OrderLib for bytes;

    /// @dev Settlement contract is used to build a digest hash given a payload.
    address public settlement;

    /// @dev Owner is responsible for signer management (adding/removing signers
    /// and maintaining signature threshold).
    address public owner;

    /// @dev In order for a multisig authenticated order to be executed the order
    /// must be signed by `signatureThreshold` trusted parties. This ensures that the
    /// optimal quote has been selected for a given auction. The main trust component here in multisig
    /// authenticated auctions is that the user is trusting the multisig to only sign quotes that will return
    /// the highest swap value to the end user.
    uint256 public signatureThreshold;

    /// @dev Signers is mapping of authenticated multisig signers.
    mapping(address => bool) public signers;

    /// @dev Initialize owner.
    /// @dev Owner must be a trusted multisig.
    /// @dev Owner can do three things:
    /// - Set signature threshold for multisig swap auctions
    /// - Update trusted signers for multisig swap auctions
    /// - Change owner
    constructor() {
        owner = msg.sender;
    }

    /// @notice Given a digest and encoded signatures, determine if a digest is approved by a
    /// sufficient number of multisig signers.
    /// @dev Reverts if not approved.
    function checkNSignatures(
        bytes32 digest,
        bytes memory signatures
    ) external view {
        ISettlement(settlement).checkNSignatures(
            address(this),
            digest,
            signatures,
            signatureThreshold
        );
    }

    /// @notice Add or remove trusted multisig signers.
    /// @dev Only owner is allowed to perform this action.
    /// @param _signers An array of signer addresses.
    /// @param _status If true, all signers in the array will be approved.
    /// If false all signers in the array will be unapproved.
    function setSigners(address[] memory _signers, bool _status) external {
        require(msg.sender == owner, "Only owner");
        for (uint256 signerIdx; signerIdx < _signers.length; signerIdx++) {
            signers[_signers[signerIdx]] = _status;
        }
    }

    /// @notice Set signature threshold.
    /// @dev Only owner is allowed to perform this action.
    function setSignatureThreshold(uint256 _signatureThreshold) external {
        require(msg.sender == owner, "Only owner");
        signatureThreshold = _signatureThreshold;
    }

    /// @notice Select a new owner.
    /// @dev Only owner is allowed to perform this action.
    function setOwner(address _owner) external {
        require(msg.sender == owner, "Only owner");
        owner = _owner;
    }

    /// @notice Initialize order manager.
    /// @dev Sets settlement.
    /// @dev Can only initialize once.
    /// @param _settlement New settlement address.
    function initialize(address _settlement) external {
        require(settlement == address(0), "Already initialized");
        settlement = _settlement;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function approve(address, uint256) external;

    function transferFrom(address from, address to, uint256 amount) external;

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISettlement {
    enum Scheme {
        Eip712,
        EthSign,
        Eip1271,
        PreSign
    }

    struct Order {
        bytes signature;
        bytes multisigSignature;
        bytes data;
        Payload payload;
    }

    struct Payload {
        address fromToken;
        address toToken;
        uint256 fromAmount;
        uint256 toAmount;
        address sender;
        address recipient;
        uint32 validFrom;
        uint32 validTo;
        address driver;
        Scheme scheme;
    }

    struct Interaction {
        address target;
        bytes data;
        uint256 value;
    }

    struct Hooks {
        Interaction[] preHooks;
        Interaction[] postHooks;
    }

    struct Condition {
        address target;
        bytes data;
    }

    function checkNSignatures(
        address driver,
        bytes32 digest,
        bytes memory signatures,
        uint256 requiredSignatures
    ) external view;

    function executeOrder(Order memory) external;

    function buildDigest(Payload memory) external view returns (bytes32 digest);

    function recoverSigner(
        Scheme scheme,
        bytes32 digest,
        bytes memory signature
    ) external view returns (address signatory);

    function executionProxy() external view returns (address executionProxy);

    function defaultDriver() external view returns (address driver);

    function defaultOracle() external view returns (address driver);

    function digestApproved(
        address signatory,
        bytes32 digest
    ) external view returns (bool approved);

    function submitOrder(
        ISettlement.Payload memory payload
    ) external returns (bytes memory orderUid);

    function invalidateOrder(bytes memory orderUid) external;

    function invalidateAllOrders() external;
}

interface ISolver {
    function hook(bytes calldata data) external;
}

// SPDX-License-Identifier: LGPL-3.0-or-later
pragma solidity 0.8.19;

/// @title Gnosis Protocol v2 Order Library
/// @author Gnosis Developers
library OrderLib {
    /// @dev The byte length of an order unique identifier.
    uint256 internal constant _UID_LENGTH = 56;

    /// @dev Packs order UID parameters into the specified memory location. The
    /// result is equivalent to `abi.encodePacked(...)` with the difference that
    /// it allows re-using the memory for packing the order UID.
    ///
    /// This function reverts if the order UID buffer is not the correct size.
    ///
    /// @param orderUid The buffer pack the order UID parameters into.
    /// @param orderDigest The EIP-712 struct digest derived from the order
    /// parameters.
    /// @param owner The address of the user who owns this order.
    /// @param validTo The epoch time at which the order will stop being valid.
    function packOrderUidParams(
        bytes memory orderUid,
        bytes32 orderDigest,
        address owner,
        uint32 validTo
    ) internal pure {
        require(orderUid.length == _UID_LENGTH, "GPv2: uid buffer overflow");

        // NOTE: Write the order UID to the allocated memory buffer. The order
        // parameters are written to memory in **reverse order** as memory
        // operations write 32-bytes at a time and we want to use a packed
        // encoding. This means, for example, that after writing the value of
        // `owner` to bytes `20:52`, writing the `orderDigest` to bytes `0:32`
        // will **overwrite** bytes `20:32`. This is desirable as addresses are
        // only 20 bytes and `20:32` should be `0`s:
        //
        //        |           1111111111222222222233333333334444444444555555
        //   byte | 01234567890123456789012345678901234567890123456789012345
        // -------+---------------------------------------------------------
        //  field | [.........orderDigest..........][......owner.......][vT]
        // -------+---------------------------------------------------------
        // mstore |                         [000000000000000000000000000.vT]
        //        |                     [00000000000.......owner.......]
        //        | [.........orderDigest..........]
        //
        // Additionally, since Solidity `bytes memory` are length prefixed,
        // 32 needs to be added to all the offsets.
        //
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(add(orderUid, 56), validTo)
            mstore(add(orderUid, 52), owner)
            mstore(add(orderUid, 32), orderDigest)
        }
    }

    /// @dev Extracts specific order information from the standardized unique
    /// order id of the protocol.
    ///
    /// @param orderUid The unique identifier used to represent an order in
    /// the protocol. This uid is the packed concatenation of the order digest,
    /// the validTo order parameter and the address of the user who created the
    /// order. It is used by the user to interface with the contract directly,
    /// and not by calls that are triggered by the solvers.
    /// @return orderDigest The EIP-712 signing digest derived from the order
    /// parameters.
    /// @return owner The address of the user who owns this order.
    /// @return validTo The epoch time at which the order will stop being valid.
    function extractOrderUidParams(
        bytes memory orderUid
    )
        internal
        pure
        returns (bytes32 orderDigest, address owner, uint32 validTo)
    {
        require(orderUid.length == _UID_LENGTH, "GPv2: invalid uid");
        assembly {
            orderDigest := mload(add(orderUid, 32))
            owner := shr(96, mload(add(orderUid, 64)))
            validTo := shr(224, mload(add(orderUid, 84)))
        }
    }
}