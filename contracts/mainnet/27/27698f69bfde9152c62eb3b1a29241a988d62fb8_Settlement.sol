// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;
import "./interfaces/ISettlement.sol";
import "./interfaces/IERC20.sol";
import {Signing} from "./Signing.sol";
import {OrderManager} from "./OrderManager.sol";
import {OrderLib} from "./lib/Order.sol";
import {ISettlement} from "./interfaces/ISettlement.sol";
import {IDriver} from "./interfaces/IDriver.sol";

/// @author Openflow
/// @title Settlement
/// @dev Settlement is the primary contract for swap execution. The concept is simple.
/// - User approves Settlement to spend fromToken
/// - User submits a request for quotes (RFQ) and solvers submit quotes
/// - User selects the best quote and user creates a signed order for the swap based on the quote
/// - Once an order is signed anyone with the signature and payload can execute the order
/// - The solver whose quote was selected receives the signature and initiates a signed order execution
/// - Order `fromToken` is transferred from the order signer to the order executor (order executor is solver configurable)
/// - Order executor executes the swap in whatever way they see fit
/// - At the end of the swap the user's `toToken` delta must be greater than or equal to the agreed upon `toAmount`
contract Settlement is OrderManager, Signing {
    /// @dev Use OrderLib for order UID encoding/decoding.
    using OrderLib for bytes;

    /// @dev Prepare constants for building domainSeparator.
    bytes32 private constant _DOMAIN_NAME = keccak256("Openflow");
    bytes32 private constant _DOMAIN_VERSION = keccak256("v0.0.1");
    bytes32 private constant _DOMAIN_TYPE_HASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
    bytes32 public constant TYPE_HASH =
        keccak256(
            "Payload(address fromToken,address toToken,uint256 fromAmount,uint256 toAmount,address sender,address recipient,uint256 validTo,Scheme scheme,Hooks hooks)"
        );
    bytes32 public immutable domainSeparator;

    /// @dev Map each user order by UID to the amount that has been filled.
    mapping(bytes => uint256) public filledAmount;

    /// @dev Contracts are allowed to submit pre-swap and post-swap hooks along with their order.
    /// For security purposes all hooks are executed via a simple execution proxy to disallow sending
    /// arbitrary calls directly from the context of Settlement. This is done because Settlement is the
    /// primary contract upon which token allowances will be set.
    ExecutionProxy public executionProxy;

    /// @dev When an order has been executed successfully emit an event.
    event OrderExecuted(
        address solver,
        address executor,
        address sender,
        address recipient,
        address fromToken,
        address toToken,
        uint256 fromAmount,
        uint256 toAmount
    );

    /// @dev Set domainSeparator and executionProxy.
    constructor(
        address _defaultDriver,
        address _defaultOracle
    ) Signing(_defaultDriver) OrderManager(_defaultOracle) {
        domainSeparator = keccak256(
            abi.encode(
                _DOMAIN_TYPE_HASH,
                _DOMAIN_NAME,
                _DOMAIN_VERSION,
                block.chainid,
                address(this)
            )
        );
        executionProxy = new ExecutionProxy();
    }

    /// @notice Primary method for order execution.
    /// @dev TODO: Analyze whether or not this needs to be non-reentrant
    /// @param order The order to execute.
    function executeOrder(ISettlement.Order calldata order) public {
        ISettlement.Payload memory payload = order.payload;
        address signatory = payload.sender;

        /// @notice Step 1. Verify the integrity of the order.
        /// @dev Verifies that payload.sender signed the order.
        /// @dev Only the order payload is signed.
        /// @dev Once an order is signed anyone who has the signature can fulfil the order.
        /// @dev In the case of smart contracts sender must implement EIP-1271 isVerified method.
        bytes memory orderUid = verify(order);

        /// @notice Step 2. Execute optional contract pre-swap hooks.
        _execute(payload.sender, order.payload.hooks.preHooks);

        /// @notice Step 3. Optimistically transfer funds from payload.sender to msg.sender (order executor).
        /// @dev Payload.sender must approve settlement.
        /// @dev If settlement already has `fromAmount` of `inputToken` send balance from Settlement.
        /// Otherwise send balance from payload.sender. The reason we do this is because the user may specify
        /// pre-swap hooks such as withdrawing from a vault (and sending tokens to Settlement) before executing the swap.
        uint256 inputTokenBalanceSettlement = IERC20(payload.fromToken)
            .balanceOf(address(this));

        if (inputTokenBalanceSettlement >= payload.fromAmount) {
            IERC20(payload.fromToken).transfer(msg.sender, payload.fromAmount);
        } else {
            IERC20(payload.fromToken).transferFrom(
                signatory,
                msg.sender,
                payload.fromAmount
            );
        }

        /// @notice Step 4. Order executor executes the swap and is required to send funds to payload.recipient.
        /// @dev Order executors can be completely custom, or the generic order executor can be used.
        /// @dev Solver configurable metadata about the order is sent to the order executor hook.
        /// @dev Settlement does not care how the solver executes the order, all Settlement cares about is that
        /// the user receives the minimum amount of tokens the signer agreed to.
        /// @dev Record output token balance before so we can ensure recipient
        /// received at least the agreed upon number of output tokens.
        uint256 outputTokenBalanceBefore = IERC20(payload.toToken).balanceOf(
            payload.recipient
        );
        ISolver(msg.sender).hook(order.data);

        /// @notice Step 5. Make sure payload.recipient receives the agreed upon amount of tokens.
        uint256 outputTokenBalanceAfter = IERC20(payload.toToken).balanceOf(
            payload.recipient
        );
        uint256 balanceDelta = outputTokenBalanceAfter -
            outputTokenBalanceBefore;
        require(balanceDelta >= payload.toAmount, "Order not filled");
        filledAmount[orderUid] = balanceDelta;

        /// @notice Step 6. Execute optional contract post-swap hooks.
        /// @dev These are signer authenticated post-swap hooks. These hooks
        /// happen after step 5 because the user may wish to perform an action
        /// (such as deposit into a vault or reinvest/compound) with the swapped funds.
        _execute(signatory, order.payload.hooks.postHooks);

        /// @dev Emit OrderExecuted
        emit OrderExecuted(
            tx.origin,
            msg.sender,
            signatory,
            payload.recipient,
            payload.fromToken,
            payload.toToken,
            payload.fromAmount,
            balanceDelta
        );
    }

    /// @notice Pass hook execution interactions to execution proxy to be executed.
    /// @param interactions The interactions to execute.
    function _execute(
        address signatory,
        ISettlement.Interaction[] memory interactions
    ) internal {
        if (interactions.length > 0) {
            executionProxy.execute(signatory, interactions);
        }
    }

    /// @notice The condition check must pass in order for the swap to succeed.
    /// @dev Always reverts on failure if the condition check fails.
    /// @param condition The condition to check
    function checkCondition(
        ISettlement.Condition memory condition
    ) public view {
        if (condition.target != address(0)) {
            (bool success, bytes memory returnData) = condition
                .target
                .staticcall(condition.data);
            if (!success) {
                string
                    memory conditionNotMetMessage = "Order condition not met";
                uint256 returnDataLength = returnData.length;
                if (returnDataLength > 0) {
                    assembly {
                        mstore(
                            add(returnData, 0x04),
                            sub(returnDataLength, 0x04)
                        )
                        returnData := add(returnData, 0x04)
                    }
                    bytes memory errorMessage = abi.encodePacked(
                        conditionNotMetMessage,
                        ":",
                        returnData
                    );
                    revert(string(errorMessage));
                } else {
                    revert(conditionNotMetMessage);
                }
            }
        }
    }

    /// @notice Order verification.
    /// @dev Verify the order.
    /// @dev Signature type is auto-detected based on signature's v.
    /// see: Gnosis Safe implementation.
    /// @dev Supports:
    /// - EIP-712 (Structured EOA signatures)
    /// - EIP-1271 (Contract based signatures)
    /// - EthSign (Non-structured EOA signatures)
    /// - Presign (Anyone can presign a digest)
    /// @param order Complete signed order.
    /// @return orderUid New order UID.
    function verify(
        ISettlement.Order calldata order
    ) public view returns (bytes memory orderUid) {
        bytes32 digest = buildDigest(order.payload);
        address signatory = recoverSigner(
            order.payload.scheme,
            digest,
            order.signature
        );
        require(signatory == order.payload.sender, "Invalid signer");
        require(block.timestamp >= order.payload.validFrom, "Order not ready");
        require(block.timestamp <= order.payload.validTo, "Deadline expired");

        /// @dev Allow conditional orders.
        ISettlement.Condition memory condition = order.payload.condition;
        checkCondition(condition);

        /// @dev Regardless of authentication type any user/contract can decide
        /// if they would like to delegate quote selection to a decentralized
        /// driver or if they wish to select the best quote themselves. If
        /// driver address is set the order can only be executed once multisig
        /// threshold of the driver is met and signed. Driver selection is left
        /// to the order submitter or alternatively the default driver can be used.
        /// Custom driver selection means the order submitter does not need to trust any
        /// party with quote selection. If desired the user's company can run a decentralized
        /// driver network themselves. This also gives users complete control over how
        /// and when an order is authenticated to swap. If no driver address is selected
        /// the user is either self selecting the driver (and must give their signature only
        /// to the solver who offers the best quote) or the order will be treated like a
        /// limit order, where the order can be executed by anyone so long as the conditions
        /// of the signed payload are met.
        address driver = order.payload.driver;
        if (driver != address(0)) {
            IDriver(driver).checkNSignatures(digest, order.multisigSignature);
        }
        orderUid = new bytes(OrderLib._UID_LENGTH);
        orderUid.packOrderUidParams(digest, signatory, order.payload.validTo);
        require(filledAmount[orderUid] == 0, "Order already filled");
    }

    /// @notice Building the digest hash.
    /// @dev Message digest hash consists of type hash, domain separator and struct hash.
    function buildDigest(
        ISettlement.Payload memory _payload
    ) public view returns (bytes32 orderDigest) {
        bytes32 typeHash = TYPE_HASH;
        bytes32 structHash = keccak256(
            abi.encodePacked(typeHash, abi.encode(_payload))
        );
        orderDigest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
    }
}

/// @title Execution proxy.
/// @notice Simple contract used to execute pre-swap and post-swap hooks.
/// @dev This is necessary because we cannot allow Settlement to execute arbitrary transaction
/// payloads directly since Settlement may have token approvals.
contract ExecutionProxy {
    address public immutable settlement;

    /// @dev Set settlement address.
    constructor() {
        settlement = msg.sender;
    }

    /// @notice Executed user defined interactions signed by sender.
    /// @dev Sender has been authenticated by signature recovery.
    /// @dev Something important to consider here is that we are appending
    /// the authenticated sender (signer) to the end of each interaction calldata.
    /// The reason this is done is to allow the payload signatory to be
    /// authenticated in interaction endpoints. If your interaction endpoint
    /// needs to read signer it can do so by reading the last 20 bytes of calldata.
    /// What this means is that if your interaction endpoint explicitly relies on
    /// calldata length you will need to account for the additional 20 address bytes.
    /// For example: signatory := shr(96, calldataload(sub(calldatasize(), 20))).
    function execute(
        address sender,
        ISettlement.Interaction[] memory interactions
    ) external {
        require(msg.sender == settlement, "Only settlement");
        for (uint256 i; i < interactions.length; i++) {
            ISettlement.Interaction memory interaction = interactions[i];
            (bool success, ) = interaction.target.call{
                value: interaction.value
            }(abi.encodePacked(interaction.data, sender));
            require(success, "Execution proxy interaction failed");
        }
    }
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
        Condition condition;
        Hooks hooks;
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IERC20 {
    function balanceOf(address) external view returns (uint256);

    function transfer(address, uint256) external;

    function approve(address, uint256) external;

    function transferFrom(address from, address to, uint256 amount) external;

    function decimals() external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;
import {ISettlement} from "./interfaces/ISettlement.sol";
import {ISignatureValidator} from "./interfaces/ISignatureValidator.sol";
import {ISettlement} from "./interfaces/ISettlement.sol";
import {IDriver} from "./interfaces/IDriver.sol";

/// @author Openflow
/// @title Signing Library
/// @notice Responsible for all Openflow signature logic.
/// @dev This library is a slightly modified combined version of two battle
/// signing libraries (Gnosis Safe and Cowswap). The intention here is to make an
/// extremely versatile signing lib to handle all major signature types as well as
/// multisig signatures. It handles EIP-712, EIP-1271, EthSign, Presign and Gnosis style
/// multisig signature threshold. Multisig signatures can be comprised of any
/// combination of signature types. Signature type is auto-detected (per Gnosis)
/// based on v value.
contract Signing {
    /// @dev All ECDSA signatures (EIP-712 and EthSign) must be 65 bytes.
    /// @dev Contract signatures (EIP-1271) can be any number of bytes, however
    /// Gnosis-style threshold packed signatures must adhere to the Gnosis contract.
    /// Signature format: {32-bytes owner_1 (r)}{32-bytes signature_offset_1 (s)}{1-byte v_1 (0)}{signature_length_1}{signature_bytes_1}
    uint256 private constant _ECDSA_SIGNATURE_LENGTH = 65;
    bytes4 private constant _EIP1271_MAGICVALUE = 0x1626ba7e;
    address public immutable defaultDriver;

    /// TODO: comments
    constructor(address _defaultDriver) {
        defaultDriver = _defaultDriver;
    }

    /// @notice Primary signature check endpoint.
    /// @param signature Signature bytes (usually 65 bytes) but in the case of packed
    /// contract signatures actual signature data offset and length may vary.
    /// @param digest Hashed payload digest.
    /// @return owner Returns authenticated owner.
    function recoverSigner(
        ISettlement.Scheme scheme,
        bytes32 digest,
        bytes memory signature
    ) public view returns (address owner) {
        /// @dev Extract v from signature
        if (scheme == ISettlement.Scheme.Eip1271) {
            /// @dev Contract signature (EIP-1271).
            owner = _recoverEip1271Signer(digest, signature);
        } else if (scheme == ISettlement.Scheme.PreSign) {
            /// @dev Presigned signature requires order manager as signature storage contract.
            owner = _recoverPresignedOwner(digest, signature);
        } else if (scheme == ISettlement.Scheme.EthSign) {
            /// @dev EthSign signature. If v > 30 then default va (27,28)
            /// has been adjusted for eth_sign flow.
            owner = _recoverEthSignSigner(digest, signature);
        } else {
            /// @dev EIP-712 signature. Default is the ecrecover flow with the provided data hash.
            owner = _recoverEip712Signer(digest, signature);
        }
    }

    /// @notice Recover EIP 712 signer.
    /// @param digest Hashed payload digest.
    /// @param signature Signature bytes.
    /// @return owner Signature owner.
    function _recoverEip712Signer(
        bytes32 digest,
        bytes memory signature
    ) internal pure returns (address owner) {
        owner = _ecdsaRecover(digest, signature);
    }

    /// @notice Extract forward and validate signature for EIP-1271.
    /// @dev See "Contract Signature" section of https://docs.safe.global/learn/safe-core/safe-core-protocol/signatures
    /// @dev Code comes from Gnosis Safe: https://github.com/safe-global/safe-contracts/blob/main/contracts/Safe.sol
    /// @param digest Hashed payload digest.
    /// @param encodedSignature Encoded signature.
    /// @return owner Signature owner.
    function _recoverEip1271Signer(
        bytes32 digest,
        bytes memory encodedSignature
    ) internal view returns (address owner) {
        bytes memory signature;
        uint256 signatureLength = encodedSignature.length - 20;
        assembly {
            owner := mload(add(encodedSignature, 20))
            mstore(add(encodedSignature, 20), signatureLength)
            signature := add(encodedSignature, 20)
        }
        require(
            ISignatureValidator(owner).isValidSignature(digest, signature) ==
                _EIP1271_MAGICVALUE,
            "EIP-1271 signature is invalid"
        );
    }

    /// @notice Recover signature using eth sign.
    /// @dev Uses ecdsaRecover with "Ethereum Signed Message" prefixed.
    /// @param digest Hashed payload digest.
    /// @param signature Signature.
    /// @return owner Signature owner.
    function _recoverEthSignSigner(
        bytes32 digest,
        bytes memory signature
    ) internal pure returns (address owner) {
        // The signed message is encoded as:
        // `"\x19Ethereum Signed Message:\n" || length || data`, where
        // the length is a constant (32 bytes) and the data is defined as:
        // `orderDigest`.
        bytes32 ethSignDigest = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", digest)
        );
        owner = _ecdsaRecover(ethSignDigest, signature);
    }

    /// @notice Verifies the order has been pre-signed. The signature is the
    /// address of the signer of the order.
    /// @param orderDigest The EIP-712 signing digest derived from the order
    /// parameters.
    /// @param encodedSignature The pre-sign signature reprenting the order UID.
    /// @return owner The address of the signer.
    function _recoverPresignedOwner(
        bytes32 orderDigest,
        bytes memory encodedSignature
    ) internal view returns (address owner) {
        require(encodedSignature.length == 20, "Malformed presignature");
        assembly {
            // owner = address(encodedSignature[0:20])
            owner := shr(96, mload(add(encodedSignature, 0x20)))
        }
        bool presigned = ISettlement(address(this)).digestApproved(
            owner,
            orderDigest
        );
        require(presigned, "Order not presigned");
    }

    /// @notice Utility for recovering signature using ecrecover.
    /// @dev Signature length is expected to be exactly 65 bytes.
    /// @param message Signed messed.
    /// @param signature Signature.
    /// @return signer Returns signer (signature owner).
    function _ecdsaRecover(
        bytes32 message,
        bytes memory signature
    ) internal pure returns (address signer) {
        require(
            signature.length == _ECDSA_SIGNATURE_LENGTH,
            "Malformed ECDSA signature"
        );
        (bytes32 r, bytes32 s) = abi.decode(signature, (bytes32, bytes32));
        uint8 v = uint8(signature[64]);

        signer = ecrecover(message, v, r, s);
        require(signer != address(0), "Invalid ECDSA signature");
    }

    /// @notice Gnosis style signature threshold check.
    /// @dev Since the EIP-1271 does an external call, be mindful of reentrancy attacks.
    /// @dev Reverts if signature threshold is not passed.
    /// @dev Signatures must be packed such that the decimal values of the derived signers are in
    /// ascending numerical order.
    /// For instance `0xA0b8...eB48` > `0x6B17....71d0F`, so the signature for `0xA0b8...eB48` must come first.
    /// @dev Code comes from Gnosis Safe: https://github.com/safe-global/safe-contracts/blob/main/contracts/Safe.sol
    /// @dev Use `recoverSigner()` methods wherever possible and use exact Gnosis code when v == 0 (contract signatures)
    /// @param digest The EIP-712 signing digest derived from the order parameters.
    /// @param signatures Packed and encoded multisig signatures payload.
    /// @param requiredSignatures Signature threshold. This is required since we are unable.
    /// to easily determine the number of signatures from the signature payload alone.
    function checkNSignatures(
        address driver,
        bytes32 digest,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public view {
        /// @dev Check that the provided signature data is not too short
        require(
            signatures.length >= requiredSignatures * 65,
            "Not enough signatures provided"
        );

        /// @dev There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint256 signatureIdx;
        bytes32 r;
        bytes32 s;
        uint8 v;
        for (
            signatureIdx = 0;
            signatureIdx < requiredSignatures;
            signatureIdx++
        ) {
            // From Gnosis `signatureSplit` method
            assembly {
                let signaturePos := mul(0x41, signatureIdx)
                r := mload(add(signatures, add(signaturePos, 0x20)))
                s := mload(add(signatures, add(signaturePos, 0x40)))
                v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
            }
            bytes memory signature = abi.encodePacked(r, s, v);
            if (v == 0) {
                /// @dev When handling contract signatures the address of the contract is encoded into r.
                currentOwner = address(uint160(uint256(r)));

                /// @dev Check that signature data pointer (s) is not pointing inside
                /// the static part of the signatures bytes. This check is not completely accurate,
                /// since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the
                /// part that is being processed.
                require(uint256(s) >= 65, "Signature data pointer is invalid");

                /// @dev Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes).
                require(
                    uint256(s) + 32 <= signature.length,
                    "Signature data pointer is out of bounds"
                );

                /// @dev Check if the contract signature is in bounds: start of data is s + 32
                /// and end is start + signature length.
                uint256 contractSignatureLen;
                assembly {
                    contractSignatureLen := mload(add(add(signature, s), 0x20))
                }
                require(
                    uint256(s) + 32 + contractSignatureLen <= signature.length,
                    "Signature is out of bounds"
                );

                /// @dev Check signature.
                bytes memory contractSignature;
                assembly {
                    /// @dev The signature data for contract signatures is
                    /// appended to the concatenated signatures and the offset
                    /// is stored in s.
                    contractSignature := add(add(signature, s), 0x20)
                }

                /// @dev Perform signature validation on the contract here rather than using
                /// `_recoverEip1271Signer()` to save gas since we already have all the data
                /// here and the call is simple.
                /// @dev currentOwner (r) is set above
                require(
                    ISignatureValidator(currentOwner).isValidSignature(
                        digest,
                        contractSignature
                    ) == _EIP1271_MAGICVALUE,
                    "EIP-1271 signature is invalid"
                );
            } else if (v == 1) {
                /// @dev Presigned signature requires order manager as signature storage contract.
                currentOwner = _recoverPresignedOwner(
                    digest,
                    abi.encodePacked(address(uint160(uint256(r))))
                );
            } else if (v > 30) {
                /// @dev EthSign signature. If v > 30 then default va (27,28)
                /// has been adjusted for eth_sign flow.
                uint8 adjustedV = v - 4;
                signature = abi.encodePacked(r, s, adjustedV);
                currentOwner = _recoverEthSignSigner(digest, signature);
            } else {
                /// @dev Default to EDCSA ecrecover flow with the provided data hash.
                currentOwner = _recoverEip712Signer(digest, signature);
            }

            require(
                currentOwner > lastOwner,
                "Invalid signature order or duplicate signature"
            );
            require(
                IDriver(driver).signers(currentOwner),
                "Signer is not approved"
            );
            lastOwner = currentOwner;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.19;
import {IERC20} from "../src/interfaces/IERC20.sol";
import {ISettlement} from "../src/interfaces/ISettlement.sol";
import {OrderLib} from "../src/lib/Order.sol";

/// @author Openflow
/// @title Multisig Driver
/// @notice This contract manages the signing logic for Openflow multisig authenticated swap auctions.
contract OrderManager {
    /// @dev OrderLib is used to generate and decode unique UIDs per order.
    /// A UID consists of digest hash, owner and validTo.
    using OrderLib for bytes;

    address public immutable defaultOracle;

    /// @dev approvedHashes[owner][nonce][hash]
    /// Allows a user to validate and invalidate an order.
    mapping(address => mapping(uint256 => mapping(bytes32 => bool)))
        public approvedHashes;

    /// @dev All orders for a user can be invalidated by incrementing the user's session nonce.
    mapping(address => uint256) public sessionNonceByAddress;

    /// @dev Event emitted when an order is submitted. This event is used off-chain to detect new orders.
    /// When a SubmitOrder event is fired, multisig auction authenticators (signers) will request new quotes from all
    /// solvers, and when the auction period is up, multisig will sign the best quote. The signature will be relayed to
    /// the solver who submitted the quote. When the solver has enough multisig signatures, the solver can construct
    /// the multisig signature (see: https://docs.safe.global/learn/safe-core/safe-core-protocol/signatures) and
    /// execute the order.
    event SubmitOrder(ISettlement.Payload payload, bytes orderUid);

    /// @dev Event emitted when an order is invalidated. Only users who submit an order can invalidate the order.
    /// When an order is invalidated it is no longer able to be executed.
    event InvalidateOrder(bytes orderUid);

    /// @dev Event emitted to indicate a user has invalidated all of their orders. This is accomplished by the
    /// user incrementing their session nonce.
    event InvalidateAllOrders(address account);

    /// @notice Submit an order.
    /// @dev Given an order payload, build and approve the digest hash, and then emit an event
    /// that indicates an auction is ready to begin.
    /// @param payload The payload to sign.
    /// @return orderUid Returns unique order UID.
    function submitOrder(
        ISettlement.Payload memory payload
    ) external returns (bytes memory orderUid) {
        bytes32 digest = ISettlement(address(this)).buildDigest(payload);
        uint256 sessionNonce = sessionNonceByAddress[msg.sender];
        approvedHashes[msg.sender][sessionNonce][digest] = true;
        orderUid = new bytes(OrderLib._UID_LENGTH);
        orderUid.packOrderUidParams(digest, msg.sender, payload.validTo);
        emit SubmitOrder(payload, orderUid);
    }

    constructor(address _defaultOracle) {
        defaultOracle = _defaultOracle;
    }

    /// @notice Invalidate an order.
    /// @dev Only the user who initiated the order can invalidate the order.
    /// @param orderUid The order UID to invalidate.
    function invalidateOrder(bytes memory orderUid) external {
        (bytes32 digest, address ownerOwner, ) = orderUid
            .extractOrderUidParams();
        uint256 sessionNonce = sessionNonceByAddress[msg.sender];
        approvedHashes[msg.sender][sessionNonce][digest] = false;
        require(msg.sender == ownerOwner, "Only owner of order can invalidate");
        emit InvalidateOrder(orderUid);
    }

    /// @notice Invalidate all orders for a user.
    /// @dev Accomplished by incrementing the user's session nonce.
    function invalidateAllOrders() external {
        sessionNonceByAddress[msg.sender]++;
        emit InvalidateAllOrders(msg.sender);
    }

    /// @notice Determine whether or not a user has approved an order digest for the current session.
    /// @param digest The order digest to check.
    /// @return approved True if approved, false if not.
    function digestApproved(
        address signatory,
        bytes32 digest
    ) external view returns (bool approved) {
        uint256 sessionNonce = sessionNonceByAddress[signatory];
        approved = approvedHashes[signatory][sessionNonce][digest];
    }
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

interface IDriver {
    function checkNSignatures(
        bytes32 digest,
        bytes memory signature
    ) external view;

    function signers(address) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface ISignatureValidator {
    function isValidSignature(
        bytes32,
        bytes memory
    ) external view returns (bytes4);
}