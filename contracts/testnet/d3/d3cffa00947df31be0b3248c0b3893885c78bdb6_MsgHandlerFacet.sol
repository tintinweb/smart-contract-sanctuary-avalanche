// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@hyperlane-xyz/core/interfaces/IMessageRecipient.sol";
import "../../libraries/LibAppStorage.sol";
import "@sgn-v2-contracts/message/framework/MessageApp.sol";
import "@hyperlane-xyz/core/contracts/libs/Message.sol";
import "@hyperlane-xyz/core/contracts/libs/TypeCasts.sol";
import "../../libraries/LibAppReceiver.sol";
import "../Receiver.sol";
import {HyperlaneStorage} from "./libraries/HyperlaneFacetLibrary.sol";
import "./libraries/HyperlaneFacetLibrary.sol";
import "../../libraries/LibNexusABI.sol";
import {Call} from "../../Call.sol";
import "../../Errors.sol";

contract MsgHandlerFacet is IMessageRecipient, Receiver, MessageApp {

    event CrossChainMsgReceived(
        uint indexed msgOriginChain,
        bytes32 indexed sender,
        bytes message
    );

    constructor(address _celerMessageBus) MessageApp(_celerMessageBus) {

    }

    modifier onlyInbox() {
        HyperlaneStorage storage hs = HyperlaneFacetLibrary.hyperlaneStorage();
        if(msg.sender!=hs.hyperlaneMailbox){
            revert InvalidInbox();
        }
        _;
    }


    function addChainTokenForMirrorToken(address token, address mirrorToken) public onlyDiamondOwner {
        LibAppReceiver._addChainTokenForMirrorToken(mirrorToken,token);
    }

    function _onlyNexus(address _sender) internal {
        if(_sender != s.axonReceiver){
            revert InvalidNexus();
        }
    }

    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes memory _message
    ) external override onlyInbox {
        _onlyNexus(TypeCasts.bytes32ToAddress(_sender)); //keeping as function to avoid deep stack
        emit CrossChainMsgReceived(_origin, _sender, _message);
        (LibAppStorage.TokenBridgeAction action, bytes memory executionMsg) =
        abi.decode(_message, (LibAppStorage.TokenBridgeAction,bytes));

        if(action == LibAppStorage.TokenBridgeAction.WithdrawMulti) {
            (address source, address account, address[] memory tokens, uint256[] memory amounts, Call[] memory calls) = abi.decode(executionMsg,
                (address, address, address[], uint256[], Call[]));
            uint length = tokens.length;
            for(uint i; i<length;){
                tokens[i] = LibAppReceiver._getChainToken(tokens[i]);

                unchecked {
                    ++i;
               }
            }
            withdrawMultiTokenAndCall(source,account,tokens,amounts,calls);
        } else {
            (address source, address account, address token, uint256 amount, Call[] memory calls) = abi.decode(executionMsg,
                (address, address, address, uint256, Call[]));
            token = LibAppReceiver._getChainToken(token);
            if(action == LibAppStorage.TokenBridgeAction.Withdraw) {
                withdrawTokenAndCall(source,account,token,amount,calls);
            }
        }
    }

    function executeMessage(
        address _sender,
        uint64 _origin,
        bytes calldata _message,
        address // executor
    ) external payable override onlyMessageBus returns (ExecutionStatus) {
        _onlyNexus(_sender); //keeping as function to avoid deep stack
        emit CrossChainMsgReceived(_origin, TypeCasts.addressToBytes32(_sender), _message);
        (LibAppStorage.TokenBridgeAction action, bytes memory executionMsg) =
        abi.decode(_message, (LibAppStorage.TokenBridgeAction,bytes));

        if(action == LibAppStorage.TokenBridgeAction.WithdrawMulti) {
            (address source, address account, address[] memory tokens, uint256[] memory amounts, Call[] memory calls) = abi.decode(executionMsg,
                (address, address, address[], uint256[], Call[]));
            uint length = tokens.length;
            for(uint i; i<length;){
                tokens[i] = LibAppReceiver._getChainToken(tokens[i]);
                unchecked{
                    ++i;
                }
            }
            withdrawMultiTokenAndCall(source,account,tokens,amounts,calls);
        } else {
            (address source, address account, address token, uint256 amount, Call[] memory calls) = abi.decode(executionMsg,
                (address, address, address, uint256, Call[]));
            token = LibAppReceiver._getChainToken(token);
            if(action == LibAppStorage.TokenBridgeAction.Withdraw) {
                withdrawTokenAndCall(source,account,token,amount,calls);
            }
        }
        return ExecutionStatus.Success;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IMessageRecipient {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../diamondCommons/libraries/LibDiamond.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../Errors.sol";
struct AppStorage {
   mapping(address => address) mirrorToChainToken; //usdceth -> usdc
   address kai;
   address axonReceiver;
   uint axonChainId;
   uint godwokenChainId;
}

library LibAppStorage {

    enum TokenBridgeAction{
        Deposit,
        DepositMulti,
        Withdraw,
        WithdrawMulti,
        MultiCall
    }

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers is ReentrancyGuard {
    AppStorage internal s;

    modifier onlyDiamondOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier validRouter() {
        if(msg.sender != address(this)){
            revert InvalidRouter();
        }
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "./MessageSenderApp.sol";
import "./MessageReceiverApp.sol";

abstract contract MessageApp is MessageSenderApp, MessageReceiverApp {
    constructor(address _messageBus) {
        messageBus = _messageBus;
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {TypeCasts} from "./TypeCasts.sol";

/**
 * @title Hyperlane Message Library
 * @notice Library for formatted messages used by Mailbox
 **/
library Message {
    using TypeCasts for bytes32;

    uint256 private constant VERSION_OFFSET = 0;
    uint256 private constant NONCE_OFFSET = 1;
    uint256 private constant ORIGIN_OFFSET = 5;
    uint256 private constant SENDER_OFFSET = 9;
    uint256 private constant DESTINATION_OFFSET = 41;
    uint256 private constant RECIPIENT_OFFSET = 45;
    uint256 private constant BODY_OFFSET = 77;

    /**
     * @notice Returns formatted (packed) Hyperlane message with provided fields
     * @dev This function should only be used in memory message construction.
     * @param _version The version of the origin and destination Mailboxes
     * @param _nonce A nonce to uniquely identify the message on its origin chain
     * @param _originDomain Domain of origin chain
     * @param _sender Address of sender as bytes32
     * @param _destinationDomain Domain of destination chain
     * @param _recipient Address of recipient on destination chain as bytes32
     * @param _messageBody Raw bytes of message body
     * @return Formatted message
     */
    function formatMessage(
        uint8 _version,
        uint32 _nonce,
        uint32 _originDomain,
        bytes32 _sender,
        uint32 _destinationDomain,
        bytes32 _recipient,
        bytes calldata _messageBody
    ) internal pure returns (bytes memory) {
        return
            abi.encodePacked(
                _version,
                _nonce,
                _originDomain,
                _sender,
                _destinationDomain,
                _recipient,
                _messageBody
            );
    }

    /**
     * @notice Returns the message ID.
     * @param _message ABI encoded Hyperlane message.
     * @return ID of `_message`
     */
    function id(bytes memory _message) internal pure returns (bytes32) {
        return keccak256(_message);
    }

    /**
     * @notice Returns the message version.
     * @param _message ABI encoded Hyperlane message.
     * @return Version of `_message`
     */
    function version(bytes calldata _message) internal pure returns (uint8) {
        return uint8(bytes1(_message[VERSION_OFFSET:NONCE_OFFSET]));
    }

    /**
     * @notice Returns the message nonce.
     * @param _message ABI encoded Hyperlane message.
     * @return Nonce of `_message`
     */
    function nonce(bytes calldata _message) internal pure returns (uint32) {
        return uint32(bytes4(_message[NONCE_OFFSET:ORIGIN_OFFSET]));
    }

    /**
     * @notice Returns the message origin domain.
     * @param _message ABI encoded Hyperlane message.
     * @return Origin domain of `_message`
     */
    function origin(bytes calldata _message) internal pure returns (uint32) {
        return uint32(bytes4(_message[ORIGIN_OFFSET:SENDER_OFFSET]));
    }

    /**
     * @notice Returns the message sender as bytes32.
     * @param _message ABI encoded Hyperlane message.
     * @return Sender of `_message` as bytes32
     */
    function sender(bytes calldata _message) internal pure returns (bytes32) {
        return bytes32(_message[SENDER_OFFSET:DESTINATION_OFFSET]);
    }

    /**
     * @notice Returns the message sender as address.
     * @param _message ABI encoded Hyperlane message.
     * @return Sender of `_message` as address
     */
    function senderAddress(bytes calldata _message)
        internal
        pure
        returns (address)
    {
        return sender(_message).bytes32ToAddress();
    }

    /**
     * @notice Returns the message destination domain.
     * @param _message ABI encoded Hyperlane message.
     * @return Destination domain of `_message`
     */
    function destination(bytes calldata _message)
        internal
        pure
        returns (uint32)
    {
        return uint32(bytes4(_message[DESTINATION_OFFSET:RECIPIENT_OFFSET]));
    }

    /**
     * @notice Returns the message recipient as bytes32.
     * @param _message ABI encoded Hyperlane message.
     * @return Recipient of `_message` as bytes32
     */
    function recipient(bytes calldata _message)
        internal
        pure
        returns (bytes32)
    {
        return bytes32(_message[RECIPIENT_OFFSET:BODY_OFFSET]);
    }

    /**
     * @notice Returns the message recipient as address.
     * @param _message ABI encoded Hyperlane message.
     * @return Recipient of `_message` as address
     */
    function recipientAddress(bytes calldata _message)
        internal
        pure
        returns (address)
    {
        return recipient(_message).bytes32ToAddress();
    }

    /**
     * @notice Returns the message body.
     * @param _message ABI encoded Hyperlane message.
     * @return Body of `_message`
     */
    function body(bytes calldata _message)
        internal
        pure
        returns (bytes calldata)
    {
        return bytes(_message[BODY_OFFSET:]);
    }
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

library TypeCasts {
    // treat it as a null-terminated string of max 32 bytes
    function coerceString(bytes32 _buf)
        internal
        pure
        returns (string memory _newStr)
    {
        uint8 _slen = 0;
        while (_slen < 32 && _buf[_slen] != 0) {
            _slen++;
        }

        // solhint-disable-next-line no-inline-assembly
        assembly {
            _newStr := mload(0x40)
            mstore(0x40, add(_newStr, 0x40)) // may end up with extra
            mstore(_newStr, _slen)
            mstore(add(_newStr, 0x20), _buf)
        }
    }

    // alignment preserving cast
    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    // alignment preserving cast
    function bytes32ToAddress(bytes32 _buf) internal pure returns (address) {
        return address(uint160(uint256(_buf)));
    }
}

pragma solidity ^0.8.0;

library LibAppReceiver {

    struct AppReceiverStorage {
        address axonNexus;
        mapping(address => address) mirrorChainToken;
    }

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("app.receiver.storage");

    function appReceiverStorage() internal pure returns (AppReceiverStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function _addChainTokenForMirrorToken(address _mirrorToken,address _chainToken) internal {
        AppReceiverStorage storage ds = appReceiverStorage();
        ds.mirrorChainToken[_mirrorToken] = _chainToken;
    }

    function _getChainToken(address _mirrorToken) internal returns (address){
        AppReceiverStorage storage ds = appReceiverStorage();
        return ds.mirrorChainToken[_mirrorToken];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibAppStorage.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20Mintable} from "../../interfaces/IERC20Mintable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../libraries/LibAccountsRegistry.sol";
import {TypeCasts} from "@hyperlane-xyz/core/contracts/libs/TypeCasts.sol";
import "../interfaces/IKhalaInterchainAccount.sol";
import "../interfaces/IMessageReceiver.sol";
import {Call} from "../Call.sol";

contract Receiver is Modifiers {


    event LogWithdrawAndCall(
        address indexed user,
        address indexed token,
        uint256 amount
    );

    event LogWithdrawMultiTokenAndCall(
        address indexed user,
        address[]  tokens,
        uint256[]  amounts
    );

    event LogCrossChainMsg(
        address indexed recipient,
        bytes message,
        uint32 fromChainId
    );

    event LogReleaseToken(
        address indexed user,
        address token,
        uint256 amount
    );


    /**
    * @notice mint mirror token and calls and execute call on `toContract` with `data`
    * @param account - address of account
    * @param token - address of token to deposit
    * @param amount - amount of tokens to deposit
    * @param calls - contract address and calldata to execute crossChain
    **/
    function withdrawTokenAndCall(
        address sender,
        address account,
        address token,
        uint256 amount,
        Call[] memory calls
    ) internal nonReentrant {
        _releaseOrMint(account,token,amount);

        if(calls.length!=0){
            IMessageReceiver(account).collect(sender,calls);
        }

        emit LogWithdrawAndCall(
            account,
            token,
            amount
        );
    }

    /**
    * @notice mint mirror tokens and execute call on `toContract` with `data`
    * @param account - address of account
    * @param tokens - addresses of tokens to deposit
    * @param amounts - amounts of tokens to deposit
    * @param calls - contract address and calldata to execute crossChain
    **/
    function withdrawMultiTokenAndCall(
        address sender,
        address account,
        address[] memory tokens,
        uint256[] memory amounts,
        Call[] memory calls
    ) internal nonReentrant {
        require(tokens.length == amounts.length, "array length do not match");
        for(uint i; i<tokens.length;) {
            _releaseOrMint(account,tokens[i],amounts[i]);
            unchecked {
                ++i;
            }
        }

        if(calls.length!=0){
            IMessageReceiver(account).collect(sender,calls);
        }

    emit LogWithdrawMultiTokenAndCall(
            account,
            tokens,
            amounts
        );
    }

    /**
    * @notice mints if token is kai and unlocks and transfers in case of other tokens
    * @param _user - address of user
    * @param _token - address of token
    * @param _amount - amount of tokens
    **/
    function _releaseOrMint(
        address _user,
        address _token,
        uint256 _amount
    ) internal {
        if(s.kai == _token){
            IERC20Mintable(_token).mint(_user,_amount);
        } else {
            SafeERC20Upgradeable.safeTransfer(
                IERC20Upgradeable(_token),
                _user,
                _amount
            );
        }

        emit LogReleaseToken(
            _user,
            _token,
            _amount
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@hyperlane-xyz/core/interfaces/IInterchainSecurityModule.sol";

struct HyperlaneStorage {
    address hyperlaneMailbox;
    IInterchainSecurityModule interchainSecurityModule;
}

library HyperlaneFacetLibrary {
    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("nexus.bridges.hyperlane.storage");


    function hyperlaneStorage() internal pure returns (HyperlaneStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

pragma solidity ^0.8.0;

import "./LibAppStorage.sol";
import "../Call.sol";
library LibNexusABI{

    //encode the input data using abi.encodePacked
    function encodeData1(LibAppStorage.TokenBridgeAction action, address account, address token, uint256 amount, Call[] memory calls) internal pure returns (bytes memory) {
        bytes memory packed1 = abi.encodePacked(action, account, token, amount);
        return abi.encodePacked(packed1, abi.encode(calls));
    }

    //function to decode the data encoded by encode1 function
    function decodeData1(bytes calldata data) internal pure returns (address account, address token, uint256 amount, Call[] memory calls) {
        account = address(bytes20(data[1:21]));
        token = address(bytes20(data[21:41]));
        amount = abi.decode(data[41:73], (uint256));
        calls = abi.decode(data[73:], (Call[]));
    }

    function encodeData2(LibAppStorage.TokenBridgeAction action, address account, address[] memory tokens, uint256[] memory amounts, Call[] memory calls) internal pure returns (bytes memory) {
        bytes memory packed1 = abi.encodePacked(action, account);
        bytes memory packed2 = abi.encode(tokens, amounts, calls);
        return abi.encodePacked(packed1, packed2);
    }

    //function to decode data encoded by encode2 function
    function decodeData2(bytes calldata data) internal pure returns (address account, address[] memory tokens, uint256[] memory amounts, Call[] memory calls) {
        account = address(bytes20(data[1:21]));
        (tokens, amounts, calls) = abi.decode(data[21:], (address[], uint256[], Call[]));
    }

    //function to encode action and calls for bridgeCall
    function encodeData3(LibAppStorage.TokenBridgeAction action, address account, Call[] memory calls) internal pure returns (bytes memory) {
        bytes memory packed1 = abi.encodePacked(action, account);
        return abi.encodePacked(packed1, abi.encode(calls));
    }

    //function to decode data encoded by encode3 function
    function decodeData3(bytes calldata data) internal pure returns (address account, Call[] memory calls) {
        account = address(bytes20(data[1:21]));
        calls = abi.decode(data[21:], (Call[]));
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;

/**
*@dev Call is used for sending cross-chain execution details through nexus
*@dev to - address on destination chain
*@dev data - calldata
*/
struct Call {
    address to;
    bytes data;
}

pragma solidity ^0.8.0;

//Nexus Errors
error InvalidInbox();
error InvalidNexus();
error InvalidRouter();

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./../interfaces/IDiamondCut.sol";

import {LibDiamondStorage} from "./LibDiamondStorage.sol";
import "./DiamondErrors.sol";
library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        if(msg.sender != diamondStorage().contractOwner) {
            revert NotContractOwner(msg.sender, diamondStorage().contractOwner);
        }
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            bytes4[] memory functionSelectors = _diamondCut[facetIndex].functionSelectors;
            address facetAddress = _diamondCut[facetIndex].facetAddress;
            if(functionSelectors.length == 0) {
                revert NoSelectorsProvidedForFacetForCut(facetAddress);
            }
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamond.FacetCutAction.Add) {
                addFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Replace) {
                replaceFunctions(facetAddress, functionSelectors);
            } else if (action == IDiamond.FacetCutAction.Remove) {
                removeFunctions(facetAddress, functionSelectors);
            } else {
                revert IncorrectFacetCutAction(uint8(action));
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        if(_facetAddress == address(0)) {
            revert CannotAddSelectorsToZeroAddress(_functionSelectors);
        }
        DiamondStorage storage ds = diamondStorage();
        uint16 selectorCount = uint16(ds.selectors.length);
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Add facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            if(oldFacetAddress != address(0)) {
                revert CannotAddFunctionToDiamondThatAlreadyExists(selector);
            }
            ds.facetAddressAndSelectorPosition[selector] = FacetAddressAndSelectorPosition(_facetAddress, selectorCount);
            ds.selectors.push(selector);
            selectorCount++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        if(_facetAddress == address(0)) {
            revert CannotReplaceFunctionsFromFacetWithZeroAddress(_functionSelectors);
        }
        enforceHasContractCode(_facetAddress, "LibDiamondCut: Replace facet has no code");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.facetAddressAndSelectorPosition[selector].facetAddress;
            // can't replace immutable functions -- functions defined directly in the diamond in this case
            if(oldFacetAddress == address(this)) {
                revert CannotReplaceImmutableFunction(selector);
            }
            if(oldFacetAddress == _facetAddress) {
                revert CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(selector);
            }
            if(oldFacetAddress == address(0)) {
                revert CannotReplaceFunctionThatDoesNotExists(selector);
            }
            // replace old facet address
            ds.facetAddressAndSelectorPosition[selector].facetAddress = _facetAddress;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        DiamondStorage storage ds = diamondStorage();
        uint256 selectorCount = ds.selectors.length;
        if(_facetAddress != address(0)) {
            revert RemoveFacetAddressMustBeZeroAddress(_facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            FacetAddressAndSelectorPosition memory oldFacetAddressAndSelectorPosition = ds.facetAddressAndSelectorPosition[selector];
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(0)) {
                revert CannotRemoveFunctionThatDoesNotExist(selector);
            }


            // can't remove immutable functions -- functions defined directly in the diamond
            if(oldFacetAddressAndSelectorPosition.facetAddress == address(this)) {
                revert CannotRemoveImmutableFunction(selector);
            }
            // replace selector with last selector
            selectorCount--;
            if (oldFacetAddressAndSelectorPosition.selectorPosition != selectorCount) {
                bytes4 lastSelector = ds.selectors[selectorCount];
                ds.selectors[oldFacetAddressAndSelectorPosition.selectorPosition] = lastSelector;
                ds.facetAddressAndSelectorPosition[lastSelector].selectorPosition = oldFacetAddressAndSelectorPosition.selectorPosition;
            }
            // delete last selector
            ds.selectors.pop();
            delete ds.facetAddressAndSelectorPosition[selector];
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            return;
        }
        enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
        (bool success, bytes memory error) = _init.delegatecall(_calldata);
        if (!success) {
            if (error.length > 0) {
                // bubble up error
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(error)
                    revert(add(32, error), returndata_size)
                }
            } else {
                revert InitializationFunctionReverted(_init, _calldata);
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        if(contractSize == 0) {
            revert NoBytecodeAtAddress(_contract, _errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "../libraries/MsgDataTypes.sol";
import "../libraries/MessageSenderLib.sol";
import "../messagebus/MessageBus.sol";
import "./MessageBusAddress.sol";

abstract contract MessageSenderApp is MessageBusAddress {
    using SafeERC20 for IERC20;

    // ============== Utility functions called by apps ==============

    /**
     * @notice Sends a message to a contract on another chain.
     * Sender needs to make sure the uniqueness of the message Id, which is computed as
     * hash(type.MessageOnly, sender, receiver, srcChainId, srcTxHash, dstChainId, message).
     * If messages with the same Id are sent, only one of them will succeed at dst chain.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _fee The fee amount to pay to MessageBus.
     */
    function sendMessage(
        address _receiver,
        uint64 _dstChainId,
        bytes memory _message,
        uint256 _fee
    ) internal {
        MessageSenderLib.sendMessage(_receiver, _dstChainId, _message, messageBus, _fee);
    }

    // Send message to non-evm chain with bytes for receiver address,
    // otherwise same as above.
    function sendMessage(
        bytes calldata _receiver,
        uint64 _dstChainId,
        bytes memory _message,
        uint256 _fee
    ) internal {
        MessageSenderLib.sendMessage(_receiver, _dstChainId, _message, messageBus, _fee);
    }

    /**
     * @notice Sends a message associated with a transfer to a contract on another chain.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least
     *        (100% - max slippage percentage) * amount or the transfer can be refunded.
     *        Only applicable to the {MsgDataTypes.BridgeSendType.Liquidity}.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     *        If message is empty, only the token transfer will be sent
     * @param _bridgeSendType One of the {BridgeSendType} enum.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        bytes memory _message,
        MsgDataTypes.BridgeSendType _bridgeSendType,
        uint256 _fee
    ) internal returns (bytes32) {
        return
            MessageSenderLib.sendMessageWithTransfer(
                _receiver,
                _token,
                _amount,
                _dstChainId,
                _nonce,
                _maxSlippage,
                _message,
                _bridgeSendType,
                messageBus,
                _fee
            );
    }

    /**
     * @notice Sends a token transfer via a bridge.
     * @dev sendMessageWithTransfer with empty message
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     *        Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least
     *        (100% - max slippage percentage) * amount or the transfer can be refunded.
     *        Only applicable to the {MsgDataTypes.BridgeSendType.Liquidity}.
     * @param _bridgeSendType One of the {BridgeSendType} enum.
     */
    function sendTokenTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        MsgDataTypes.BridgeSendType _bridgeSendType
    ) internal returns (bytes32) {
        return
            MessageSenderLib.sendMessageWithTransfer(
                _receiver,
                _token,
                _amount,
                _dstChainId,
                _nonce,
                _maxSlippage,
                "", // empty message, which will not trigger sendMessage
                _bridgeSendType,
                messageBus,
                0
            );
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "../interfaces/IMessageReceiverApp.sol";
import "./MessageBusAddress.sol";

abstract contract MessageReceiverApp is IMessageReceiverApp, MessageBusAddress {
    modifier onlyMessageBus() {
        require(msg.sender == messageBus, "caller is not message bus");
        _;
    }

    /**
     * @notice Called by MessageBus to execute a message
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override onlyMessageBus returns (ExecutionStatus) {}

    // execute message from non-evm chain with bytes for sender address,
    // otherwise same as above.
    function executeMessage(
        bytes calldata _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override onlyMessageBus returns (ExecutionStatus) {}

    /**
     * @notice Called by MessageBus to execute a message with an associated token transfer.
     * The contract is guaranteed to have received the right amount of tokens before this function is called.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override onlyMessageBus returns (ExecutionStatus) {}

    /**
     * @notice Only called by MessageBus if
     *         1. executeMessageWithTransfer reverts, or
     *         2. executeMessageWithTransfer returns ExecutionStatus.Fail
     * The contract is guaranteed to have received the right amount of tokens before this function is called.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable virtual override onlyMessageBus returns (ExecutionStatus) {}

    /**
     * @notice Called by MessageBus to process refund of the original transfer from this contract.
     * The contract is guaranteed to have received the refund before this function is called.
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address _executor
    ) external payable virtual override onlyMessageBus returns (ExecutionStatus) {}
}

pragma solidity ^0.8.0;

interface IERC20Mintable {
    function mint(address account, uint256 amount) external;
    function burn (address account, uint256 amount) external;
    function burn (uint256 amount) external;
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(IERC20Upgradeable token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20Upgradeable token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20Upgradeable token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20Upgradeable token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity ^0.8.0;
import {KhalaInterChainAccount} from "../KhalaInterChainAccount.sol";
import {Create2} from "@openzeppelin/contracts/utils/Create2.sol";


library LibAccountsRegistry {

    event InterchainAccountCreated(
        address sender,
        address account
    );

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("axon.accounts.registry.storage");
    bytes constant bytecode = type(KhalaInterChainAccount).creationCode;
    bytes32 constant bytecodeHash = bytes32(keccak256(bytecode));

    function getInterchainAccount(address _sender) internal view returns (address)
    {
        return _getInterchainAccount(_salt(_sender));
    }

    function getDeployedInterchainAccount(address _sender) internal returns (address)
    {
        bytes32 salt = _salt(_sender);
        address interchainAccount = _getInterchainAccount(salt);
        if (!(interchainAccount.code.length>0)) {
            interchainAccount = Create2.deploy(0, salt, bytecode);

            KhalaInterChainAccount(interchainAccount).initialize(_sender);

            emit InterchainAccountCreated(_sender, interchainAccount);
        }
        return interchainAccount;
    }

    function _salt(address _sender) internal pure returns (bytes32)
    {
        return bytes32(abi.encodePacked(_sender));
    }

    function _getInterchainAccount(bytes32 salt) internal view returns (address)
    {
        return Create2.computeAddress(salt, bytecodeHash);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Call} from "../Call.sol";
interface IKhalaInterchainAccount {

    function sendProxyCall(
        address token,
        uint amount,
        uint chainId,
        Call[] calldata calls
    ) external;

    function sendProxyCallForMultiTokens(
        address[] calldata tokens,
        uint[] calldata amounts,
        uint chainId,
        Call[] calldata calls
    ) external;

    function eoa(
    ) external returns (address);
}

pragma solidity ^0.8.0;
import "../Call.sol";

interface IMessageReceiver{
    function collect(
        address sender,
        Call[] calldata calls
    ) external;
}

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

interface IInterchainSecurityModule {
    /**
     * @notice Returns an enum that represents the type of security model
     * encoded by this ISM.
     * @dev Relayers infer how to fetch and format metadata.
     */
    function moduleType() external view returns (uint8);

    /**
     * @notice Defines a security model responsible for verifying interchain
     * messages based on the provided metadata.
     * @param _metadata Off-chain metadata provided by a relayer, specific to
     * the security model encoded by the module (e.g. validator signatures)
     * @param _message Hyperlane encoded interchain message
     * @return True if the message was verified
     */
    function verify(bytes calldata _metadata, bytes calldata _message)
        external
        returns (bool);
}

interface ISpecifiesInterchainSecurityModule {
    function interchainSecurityModule()
        external
        view
        returns (IInterchainSecurityModule);
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
pragma abicoder v2;

import { IDiamond } from "./IDiamond.sol";

interface IDiamondCut is IDiamond {

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;    
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

library LibDiamondStorage {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndSelectorPosition {
        address facetAddress;
        uint16 selectorPosition;
    }

    struct DiamondStorage {
        // function selector => facet address and selector position in selectors array
        mapping(bytes4 => FacetAddressAndSelectorPosition) facetAddressAndSelectorPosition;
        bytes4[] selectors;
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}

pragma solidity ^0.8.0;

//LibDiamond Errors
    error NoSelectorsGivenToAdd();
    error NotContractOwner(address _user, address _contractOwner);
    error NoSelectorsProvidedForFacetForCut(address _facetAddress);
    error CannotAddSelectorsToZeroAddress(bytes4[] _selectors);
    error NoBytecodeAtAddress(address _contractAddress, string _message);
    error IncorrectFacetCutAction(uint8 _action);
    error CannotAddFunctionToDiamondThatAlreadyExists(bytes4 _selector);
    error CannotReplaceFunctionsFromFacetWithZeroAddress(bytes4[] _selectors);
    error CannotReplaceImmutableFunction(bytes4 _selector);
    error CannotReplaceFunctionWithTheSameFunctionFromTheSameFacet(bytes4 _selector);
    error CannotReplaceFunctionThatDoesNotExists(bytes4 _selector);
    error RemoveFacetAddressMustBeZeroAddress(address _facetAddress);
    error CannotRemoveFunctionThatDoesNotExist(bytes4 _selector);
    error CannotRemoveImmutableFunction(bytes4 _selector);
    error InitializationFunctionReverted(address _initializationContractAddress, bytes _calldata);

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

library MsgDataTypes {
    string constant ABORT_PREFIX = "MSG::ABORT:";

    // bridge operation type at the sender side (src chain)
    enum BridgeSendType {
        Null,
        Liquidity,
        PegDeposit,
        PegBurn,
        PegV2Deposit,
        PegV2Burn,
        PegV2BurnFrom
    }

    // bridge operation type at the receiver side (dst chain)
    enum TransferType {
        Null,
        LqRelay, // relay through liquidity bridge
        LqWithdraw, // withdraw from liquidity bridge
        PegMint, // mint through pegged token bridge
        PegWithdraw, // withdraw from original token vault
        PegV2Mint, // mint through pegged token bridge v2
        PegV2Withdraw // withdraw from original token vault v2
    }

    enum MsgType {
        MessageWithTransfer,
        MessageOnly
    }

    enum TxStatus {
        Null,
        Success,
        Fail,
        Fallback,
        Pending // transient state within a transaction
    }

    struct TransferInfo {
        TransferType t;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint64 wdseq; // only needed for LqWithdraw (refund)
        uint64 srcChainId;
        bytes32 refId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    struct RouteInfo {
        address sender;
        address receiver;
        uint64 srcChainId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    // used for msg from non-evm chains with longer-bytes address
    struct RouteInfo2 {
        bytes sender;
        address receiver;
        uint64 srcChainId;
        bytes32 srcTxHash;
    }

    // combination of RouteInfo and RouteInfo2 for easier processing
    struct Route {
        address sender; // from RouteInfo
        bytes senderBytes; // from RouteInfo2
        address receiver;
        uint64 srcChainId;
        bytes32 srcTxHash;
    }

    struct MsgWithTransferExecutionParams {
        bytes message;
        TransferInfo transfer;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }

    struct BridgeTransferParams {
        bytes request;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/IBridge.sol";
import "../../interfaces/IOriginalTokenVault.sol";
import "../../interfaces/IOriginalTokenVaultV2.sol";
import "../../interfaces/IPeggedTokenBridge.sol";
import "../../interfaces/IPeggedTokenBridgeV2.sol";
import "../interfaces/IMessageBus.sol";
import "./MsgDataTypes.sol";

library MessageSenderLib {
    using SafeERC20 for IERC20;

    // ============== Internal library functions called by apps ==============

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     */
    function sendMessage(
        address _receiver,
        uint64 _dstChainId,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal {
        IMessageBus(_messageBus).sendMessage{value: _fee}(_receiver, _dstChainId, _message);
    }

    // Send message to non-evm chain with bytes for receiver address,
    // otherwise same as above.
    function sendMessage(
        bytes calldata _receiver,
        uint64 _dstChainId,
        bytes memory _message,
        address _messageBus,
        uint256 _fee
    ) internal {
        IMessageBus(_messageBus).sendMessage{value: _fee}(_receiver, _dstChainId, _message);
    }

    /**
     * @notice Sends a message to an app on another chain via MessageBus with an associated transfer.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded. Only applicable to the {MsgDataTypes.BridgeSendType.Liquidity}.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     * @param _bridgeSendType One of the {MsgDataTypes.BridgeSendType} enum.
     * @param _messageBus The address of the MessageBus on this chain.
     * @param _fee The fee amount to pay to MessageBus.
     * @return The transfer ID.
     */
    function sendMessageWithTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        bytes memory _message,
        MsgDataTypes.BridgeSendType _bridgeSendType,
        address _messageBus,
        uint256 _fee
    ) internal returns (bytes32) {
        (bytes32 transferId, address bridge) = sendTokenTransfer(
            _receiver,
            _token,
            _amount,
            _dstChainId,
            _nonce,
            _maxSlippage,
            _bridgeSendType,
            _messageBus
        );
        if (_message.length > 0) {
            IMessageBus(_messageBus).sendMessageWithTransfer{value: _fee}(
                _receiver,
                _dstChainId,
                bridge,
                transferId,
                _message
            );
        }
        return transferId;
    }

    /**
     * @notice Sends a token transfer via a bridge.
     * @param _receiver The address of the destination app contract.
     * @param _token The address of the token to be sent.
     * @param _amount The amount of tokens to be sent.
     * @param _dstChainId The destination chain ID.
     * @param _nonce A number input to guarantee uniqueness of transferId. Can be timestamp in practice.
     * @param _maxSlippage The max slippage accepted, given as percentage in point (pip). Eg. 5000 means 0.5%.
     * Must be greater than minimalMaxSlippage. Receiver is guaranteed to receive at least (100% - max slippage percentage) * amount or the
     * transfer can be refunded.
     * @param _bridgeSendType One of the {MsgDataTypes.BridgeSendType} enum.
     */
    function sendTokenTransfer(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage,
        MsgDataTypes.BridgeSendType _bridgeSendType,
        address _messageBus
    ) internal returns (bytes32 transferId, address bridge) {
        if (_bridgeSendType == MsgDataTypes.BridgeSendType.Liquidity) {
            bridge = IMessageBus(_messageBus).liquidityBridge();
            IERC20(_token).safeIncreaseAllowance(bridge, _amount);
            IBridge(bridge).send(_receiver, _token, _amount, _dstChainId, _nonce, _maxSlippage);
            transferId = computeLiqBridgeTransferId(_receiver, _token, _amount, _dstChainId, _nonce);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegDeposit) {
            bridge = IMessageBus(_messageBus).pegVault();
            IERC20(_token).safeIncreaseAllowance(bridge, _amount);
            IOriginalTokenVault(bridge).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
            transferId = computePegV1DepositId(_receiver, _token, _amount, _dstChainId, _nonce);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegBurn) {
            bridge = IMessageBus(_messageBus).pegBridge();
            IERC20(_token).safeIncreaseAllowance(bridge, _amount);
            IPeggedTokenBridge(bridge).burn(_token, _amount, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(bridge, 0);
            transferId = computePegV1BurnId(_receiver, _token, _amount, _nonce);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Deposit) {
            bridge = IMessageBus(_messageBus).pegVaultV2();
            IERC20(_token).safeIncreaseAllowance(bridge, _amount);
            transferId = IOriginalTokenVaultV2(bridge).deposit(_token, _amount, _dstChainId, _receiver, _nonce);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegV2Burn) {
            bridge = IMessageBus(_messageBus).pegBridgeV2();
            IERC20(_token).safeIncreaseAllowance(bridge, _amount);
            transferId = IPeggedTokenBridgeV2(bridge).burn(_token, _amount, _dstChainId, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(bridge, 0);
        } else if (_bridgeSendType == MsgDataTypes.BridgeSendType.PegV2BurnFrom) {
            bridge = IMessageBus(_messageBus).pegBridgeV2();
            IERC20(_token).safeIncreaseAllowance(bridge, _amount);
            transferId = IPeggedTokenBridgeV2(bridge).burnFrom(_token, _amount, _dstChainId, _receiver, _nonce);
            // handle cases where certain tokens do not spend allowance for role-based burn
            IERC20(_token).safeApprove(bridge, 0);
        } else {
            revert("bridge type not supported");
        }
    }

    function computeLiqBridgeTransferId(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(address(this), _receiver, _token, _amount, _dstChainId, _nonce, uint64(block.chainid))
            );
    }

    function computePegV1DepositId(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked(address(this), _token, _amount, _dstChainId, _receiver, _nonce, uint64(block.chainid))
            );
    }

    function computePegV1BurnId(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _nonce
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), _token, _amount, _receiver, _nonce, uint64(block.chainid)));
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

import "./MessageBusSender.sol";
import "./MessageBusReceiver.sol";

contract MessageBus is MessageBusSender, MessageBusReceiver {
    constructor(
        ISigsVerifier _sigsVerifier,
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    )
        MessageBusSender(_sigsVerifier)
        MessageBusReceiver(_liquidityBridge, _pegBridge, _pegVault, _pegBridgeV2, _pegVaultV2)
    {}

    // this is only to be called by Proxy via delegateCall as initOwner will require _owner is 0.
    // so calling init on this contract directly will guarantee to fail
    function init(
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    ) external {
        // MUST manually call ownable init and must only call once
        initOwner();
        // we don't need sender init as _sigsVerifier is immutable so already in the deployed code
        initReceiver(_liquidityBridge, _pegBridge, _pegVault, _pegBridgeV2, _pegVaultV2);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "../../safeguard/Ownable.sol";

abstract contract MessageBusAddress is Ownable {
    event MessageBusUpdated(address messageBus);

    address public messageBus;

    function setMessageBus(address _messageBus) public onlyOwner {
        messageBus = _messageBus;
        emit MessageBusUpdated(messageBus);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IMessageReceiverApp {
    enum ExecutionStatus {
        Fail, // execution failed, finalized
        Success, // execution succeeded, finalized
        Retry // execution rejected, can retry later
    }

    /**
     * @notice Called by MessageBus to execute a message
     * @param _sender The address of the source app contract
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessage(
        address _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    // same as above, except that sender is an non-evm chain address,
    // otherwise same as above.
    function executeMessage(
        bytes calldata _sender,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Called by MessageBus to execute a message with an associated token transfer.
     * The contract is guaranteed to have received the right amount of tokens before this function is called.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransfer(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Only called by MessageBus if
     *         1. executeMessageWithTransfer reverts, or
     *         2. executeMessageWithTransfer returns ExecutionStatus.Fail
     * The contract is guaranteed to have received the right amount of tokens before this function is called.
     * @param _sender The address of the source app contract
     * @param _token The address of the token that comes out of the bridge
     * @param _amount The amount of tokens received at this contract through the cross-chain bridge.
     * @param _srcChainId The source chain ID where the transfer is originated from
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferFallback(
        address _sender,
        address _token,
        uint256 _amount,
        uint64 _srcChainId,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);

    /**
     * @notice Called by MessageBus to process refund of the original transfer from this contract.
     * The contract is guaranteed to have received the refund before this function is called.
     * @param _token The token address of the original transfer
     * @param _amount The amount of the original transfer
     * @param _message The same message associated with the original transfer
     * @param _executor Address who called the MessageBus execution function
     */
    function executeMessageWithTransferRefund(
        address _token,
        uint256 _amount,
        bytes calldata _message,
        address _executor
    ) external payable returns (ExecutionStatus);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./facets/AxonCrossChainRouter.sol";
import "./interfaces/IKhalaInterchainAccount.sol";
import "@hyperlane-xyz/core/contracts/libs/TypeCasts.sol";
import {Call} from "../Nexus/Call.sol";

/*This is not a facet of nexus diamond*/
/*Khala interchain account contract - multi-call support*/
contract KhalaInterChainAccount is IKhalaInterchainAccount, OwnableUpgradeable{

    address public eoa;

    constructor() {
        _transferOwnership(msg.sender);
    }

    function initialize(address _eoa) public initializer {
        eoa = _eoa;
    }

    /**
    *@notice - sends calls to the destination contract with calldata in `Call[]` with ICA as proxy
    *@param token - address of the token bridged (mirror token)
    *@param amount - amount of token
    *@param chainId - source chain-Id
    *@param calls - list of `Call` struct (to, data)
    */
    function sendProxyCall(address token, uint256 amount, uint chainId, Call[] calldata calls) external onlyOwner {

        uint length  = calls.length;
        for(uint i ; i<length;) {

            (bool success, bytes memory returnData) = calls[i].to.call(
                calls[i].data
            );

            if (!success) {
                Call[] memory callBacks;
                AxonCrossChainRouter(owner()).withdrawTokenAndCall(
                    chainId,
                    token,
                    amount,
                    eoa,
                    callBacks
                );
            }

            unchecked{
                ++i;
            }
        }


    }

    /**
    *@notice - sends calls to the destination contract with calldata in `Call[]` with ICA as proxy
    *@param tokens - addresses of the token bridged (mirror tokens)
    *@param amounts - amounts of tokens
    *@param chainId - source chain-Id
    *@param calls - list of `Call` struct (to, data)
    */
    function sendProxyCallForMultiTokens(address[] calldata tokens, uint256[] calldata amounts, uint chainId, Call[] calldata calls) external onlyOwner {
        uint length  = calls.length;
        for(uint i; i<length; ) {
            (bool success, bytes memory returnData) = calls[i].to.call(
                calls[i].data
            );
            if (!success) {
                // pull refund logic from application wrapper
                Call[] memory callBacks;
                AxonCrossChainRouter(owner()).withdrawMultiTokenAndCall(
                    chainId,
                    tokens,
                    amounts,
                    eoa,
                    callBacks
                );
            }
            unchecked{
                ++i;
            }
        }
    }

    function _checkOwner() internal view override {
        require(eoa == _msgSender() || owner() == _msgSender(), "Ownable: caller is not the owner");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Create2.sol)

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
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address addr) {
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
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
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address addr) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40) // Get free memory pointer

            // |                   | ↓ ptr ...  ↓ ptr + 0x0B (start) ...  ↓ ptr + 0x20 ...  ↓ ptr + 0x40 ...   |
            // |-------------------|---------------------------------------------------------------------------|
            // | bytecodeHash      |                                                        CCCCCCCCCCCCC...CC |
            // | salt              |                                      BBBBBBBBBBBBB...BB                   |
            // | deployer          | 000000...0000AAAAAAAAAAAAAAAAAAA...AA                                     |
            // | 0xFF              |            FF                                                             |
            // |-------------------|---------------------------------------------------------------------------|
            // | memory            | 000000...00FFAAAAAAAAAAAAAAAAAAA...AABBBBBBBBBBBBB...BBCCCCCCCCCCCCC...CC |
            // | keccak(start, 85) |            ↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑↑ |

            mstore(add(ptr, 0x40), bytecodeHash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer) // Right-aligned with 12 preceding garbage bytes
            let start := add(ptr, 0x0b) // The hashed data starts at the final garbage byte which we will set to 0xff
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;
pragma abicoder v2;
/******************************************************************************\
* Author: Nick Mudge <[email protected]>, Twitter/Github: @mudgen
* EIP-2535 Diamonds
/******************************************************************************/

interface IDiamond {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IBridge {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function sendNative(
        address _receiver,
        uint256 _amount,
        uint64 _dstChainId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable;

    function relay(
        bytes calldata _relayRequest,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function transfers(bytes32 transferId) external view returns (bool);

    function withdraws(bytes32 withdrawId) external view returns (bool);

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IOriginalTokenVault {
    /**
     * @notice Lock original tokens to trigger mint at a remote chain's PeggedTokenBridge
     * @param _token local token address
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external;

    /**
     * @notice Lock native token as original token to trigger mint at a remote chain's PeggedTokenBridge
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function depositNative(
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external payable;

    /**
     * @notice Withdraw locked original tokens triggered by a burn at a remote chain's PeggedTokenBridge.
     * @param _request The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IOriginalTokenVaultV2 {
    /**
     * @notice Lock original tokens to trigger mint at a remote chain's PeggedTokenBridge
     * @param _token local token address
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function deposit(
        address _token,
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external returns (bytes32);

    /**
     * @notice Lock native token as original token to trigger mint at a remote chain's PeggedTokenBridge
     * @param _amount locked token amount
     * @param _mintChainId destination chainId to mint tokens
     * @param _mintAccount destination account to receive minted tokens
     * @param _nonce user input to guarantee unique depositId
     */
    function depositNative(
        uint256 _amount,
        uint64 _mintChainId,
        address _mintAccount,
        uint64 _nonce
    ) external payable returns (bytes32);

    /**
     * @notice Withdraw locked original tokens triggered by a burn at a remote chain's PeggedTokenBridge.
     * @param _request The serialized Withdraw protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the bridge's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdraw(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external returns (bytes32);

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IPeggedTokenBridge {
    /**
     * @notice Burn tokens to trigger withdrawal at a remote chain's OriginalTokenVault
     * @param _token local token address
     * @param _amount locked token amount
     * @param _withdrawAccount account who withdraw original tokens on the remote chain
     * @param _nonce user input to guarantee unique depositId
     */
    function burn(
        address _token,
        uint256 _amount,
        address _withdrawAccount,
        uint64 _nonce
    ) external;

    /**
     * @notice Mint tokens triggered by deposit at a remote chain's OriginalTokenVault.
     * @param _request The serialized Mint protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IPeggedTokenBridgeV2 {
    /**
     * @notice Burn pegged tokens to trigger a cross-chain withdrawal of the original tokens at a remote chain's
     * OriginalTokenVault, or mint at another remote chain
     * @param _token The pegged token address.
     * @param _amount The amount to burn.
     * @param _toChainId If zero, withdraw from original vault; otherwise, the remote chain to mint tokens.
     * @param _toAccount The account to receive tokens on the remote chain
     * @param _nonce A number to guarantee unique depositId. Can be timestamp in practice.
     */
    function burn(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) external returns (bytes32);

    // same with `burn` above, use openzeppelin ERC20Burnable interface
    function burnFrom(
        address _token,
        uint256 _amount,
        uint64 _toChainId,
        address _toAccount,
        uint64 _nonce
    ) external returns (bytes32);

    /**
     * @notice Mint tokens triggered by deposit at a remote chain's OriginalTokenVault.
     * @param _request The serialized Mint protobuf.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function mint(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external returns (bytes32);

    function records(bytes32 recordId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "../libraries/MsgDataTypes.sol";

interface IMessageBus {
    /**
     * @notice Send a message to a contract on another chain.
     * Sender needs to make sure the uniqueness of the message Id, which is computed as
     * hash(type.MessageOnly, sender, receiver, srcChainId, srcTxHash, dstChainId, message).
     * If messages with the same Id are sent, only one of them will succeed at dst chain..
     * A fee is charged in the native gas token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable;

    // same as above, except that receiver is an non-evm chain address,
    function sendMessage(
        bytes calldata _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Send a message associated with a token transfer to a contract on another chain.
     * If messages with the same srcTransferId are sent, only one of them will succeed at dst chain..
     * A fee is charged in the native token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _srcBridge The bridge contract to send the transfer with.
     * @param _srcTransferId The transfer ID.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessageWithTransfer(
        address _receiver,
        uint256 _dstChainId,
        address _srcBridge,
        bytes32 _srcTransferId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Execute a message not associated with a transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessage(
        bytes calldata _message,
        MsgDataTypes.RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message with a successful transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransfer(
        bytes calldata _message,
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message with a refunded transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransferRefund(
        bytes calldata _message, // the same message associated with the original transfer
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     * @param _cumulativeFee The cumulative fee credited to the account. Tracked by SGN.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A withdrawal must be
     * signed-off by +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdrawFee(
        address _account,
        uint256 _cumulativeFee,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Calculates the required fee for the message.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     @ @return The required fee.
     */
    function calcFee(bytes calldata _message) external view returns (uint256);

    function liquidityBridge() external view returns (address);

    function pegBridge() external view returns (address);

    function pegBridgeV2() external view returns (address);

    function pegVault() external view returns (address);

    function pegVaultV2() external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

import "../../safeguard/Ownable.sol";
import "../../interfaces/ISigsVerifier.sol";

contract MessageBusSender is Ownable {
    ISigsVerifier public immutable sigsVerifier;

    uint256 public feeBase;
    uint256 public feePerByte;
    mapping(address => uint256) public withdrawnFees;

    event Message(address indexed sender, address receiver, uint256 dstChainId, bytes message, uint256 fee);
    // message to non-evm chain with >20 bytes addr
    event Message2(address indexed sender, bytes receiver, uint256 dstChainId, bytes message, uint256 fee);

    event MessageWithTransfer(
        address indexed sender,
        address receiver,
        uint256 dstChainId,
        address bridge,
        bytes32 srcTransferId,
        bytes message,
        uint256 fee
    );

    event FeeWithdrawn(address receiver, uint256 amount);

    event FeeBaseUpdated(uint256 feeBase);
    event FeePerByteUpdated(uint256 feePerByte);

    constructor(ISigsVerifier _sigsVerifier) {
        sigsVerifier = _sigsVerifier;
    }

    /**
     * @notice Sends a message to a contract on another chain.
     * Sender needs to make sure the uniqueness of the message Id, which is computed as
     * hash(type.MessageOnly, sender, receiver, srcChainId, srcTxHash, dstChainId, message).
     * If messages with the same Id are sent, only one of them will succeed at dst chain.
     * A fee is charged in the native gas token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable {
        _sendMessage(_dstChainId, _message);
        emit Message(msg.sender, _receiver, _dstChainId, _message, msg.value);
    }

    // Send message to non-evm chain with bytes for receiver address,
    // otherwise same as above.
    function sendMessage(
        bytes calldata _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable {
        _sendMessage(_dstChainId, _message);
        emit Message2(msg.sender, _receiver, _dstChainId, _message, msg.value);
    }

    function _sendMessage(uint256 _dstChainId, bytes calldata _message) private {
        require(_dstChainId != block.chainid, "Invalid chainId");
        uint256 minFee = calcFee(_message);
        require(msg.value >= minFee, "Insufficient fee");
    }

    /**
     * @notice Sends a message associated with a transfer to a contract on another chain.
     * If messages with the same srcTransferId are sent, only one of them will succeed.
     * A fee is charged in the native token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _srcBridge The bridge contract to send the transfer with.
     * @param _srcTransferId The transfer ID.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessageWithTransfer(
        address _receiver,
        uint256 _dstChainId,
        address _srcBridge,
        bytes32 _srcTransferId,
        bytes calldata _message
    ) external payable {
        require(_dstChainId != block.chainid, "Invalid chainId");
        uint256 minFee = calcFee(_message);
        require(msg.value >= minFee, "Insufficient fee");
        // SGN needs to verify
        // 1. msg.sender matches sender of the src transfer
        // 2. dstChainId matches dstChainId of the src transfer
        // 3. bridge is either liquidity bridge, peg src vault, or peg dst bridge
        emit MessageWithTransfer(msg.sender, _receiver, _dstChainId, _srcBridge, _srcTransferId, _message, msg.value);
    }

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     * @param _cumulativeFee The cumulative fee credited to the account. Tracked by SGN.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A withdrawal must be
     * signed-off by +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdrawFee(
        address _account,
        uint256 _cumulativeFee,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external {
        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "withdrawFee"));
        sigsVerifier.verifySigs(abi.encodePacked(domain, _account, _cumulativeFee), _sigs, _signers, _powers);
        uint256 amount = _cumulativeFee - withdrawnFees[_account];
        require(amount > 0, "No new amount to withdraw");
        withdrawnFees[_account] = _cumulativeFee;
        (bool sent, ) = _account.call{value: amount, gas: 50000}("");
        require(sent, "failed to withdraw fee");
        emit FeeWithdrawn(_account, amount);
    }

    /**
     * @notice Calculates the required fee for the message.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     @ @return The required fee.
     */
    function calcFee(bytes calldata _message) public view returns (uint256) {
        return feeBase + _message.length * feePerByte;
    }

    // -------------------- Admin --------------------

    function setFeePerByte(uint256 _fee) external onlyOwner {
        feePerByte = _fee;
        emit FeePerByteUpdated(feePerByte);
    }

    function setFeeBase(uint256 _fee) external onlyOwner {
        feeBase = _fee;
        emit FeeBaseUpdated(feeBase);
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.9;

import "../libraries/MsgDataTypes.sol";
import "../interfaces/IMessageReceiverApp.sol";
import "../../interfaces/IBridge.sol";
import "../../interfaces/IOriginalTokenVault.sol";
import "../../interfaces/IOriginalTokenVaultV2.sol";
import "../../interfaces/IPeggedTokenBridge.sol";
import "../../interfaces/IPeggedTokenBridgeV2.sol";
import "../../safeguard/Ownable.sol";
import "../../libraries/Utils.sol";

contract MessageBusReceiver is Ownable {
    mapping(bytes32 => MsgDataTypes.TxStatus) public executedMessages;

    address public liquidityBridge; // liquidity bridge address
    address public pegBridge; // peg bridge address
    address public pegVault; // peg original vault address
    address public pegBridgeV2; // peg bridge address
    address public pegVaultV2; // peg original vault address

    // minimum amount of gas needed by this contract before it tries to
    // deliver a message to the target contract.
    uint256 public preExecuteMessageGasUsage;

    event Executed(
        MsgDataTypes.MsgType msgType,
        bytes32 msgId,
        MsgDataTypes.TxStatus status,
        address indexed receiver,
        uint64 srcChainId,
        bytes32 srcTxHash
    );
    event NeedRetry(MsgDataTypes.MsgType msgType, bytes32 msgId, uint64 srcChainId, bytes32 srcTxHash);
    event CallReverted(string reason); // help debug

    event LiquidityBridgeUpdated(address liquidityBridge);
    event PegBridgeUpdated(address pegBridge);
    event PegVaultUpdated(address pegVault);
    event PegBridgeV2Updated(address pegBridgeV2);
    event PegVaultV2Updated(address pegVaultV2);

    constructor(
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    ) {
        liquidityBridge = _liquidityBridge;
        pegBridge = _pegBridge;
        pegVault = _pegVault;
        pegBridgeV2 = _pegBridgeV2;
        pegVaultV2 = _pegVaultV2;
    }

    function initReceiver(
        address _liquidityBridge,
        address _pegBridge,
        address _pegVault,
        address _pegBridgeV2,
        address _pegVaultV2
    ) internal {
        require(liquidityBridge == address(0), "liquidityBridge already set");
        liquidityBridge = _liquidityBridge;
        pegBridge = _pegBridge;
        pegVault = _pegVault;
        pegBridgeV2 = _pegBridgeV2;
        pegVaultV2 = _pegVaultV2;
    }

    // ============== functions called by executor ==============

    /**
     * @notice Execute a message with a successful transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransfer(
        bytes calldata _message,
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) public payable {
        // For message with token transfer, message Id is computed through transfer info
        // in order to guarantee that each transfer can only be used once.
        bytes32 messageId = verifyTransfer(_transfer);
        require(executedMessages[messageId] == MsgDataTypes.TxStatus.Null, "transfer already executed");
        executedMessages[messageId] = MsgDataTypes.TxStatus.Pending;

        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "MessageWithTransfer"));
        IBridge(liquidityBridge).verifySigs(
            abi.encodePacked(domain, messageId, _message, _transfer.srcTxHash),
            _sigs,
            _signers,
            _powers
        );
        MsgDataTypes.TxStatus status;
        IMessageReceiverApp.ExecutionStatus est = executeMessageWithTransfer(_transfer, _message);
        if (est == IMessageReceiverApp.ExecutionStatus.Success) {
            status = MsgDataTypes.TxStatus.Success;
        } else if (est == IMessageReceiverApp.ExecutionStatus.Retry) {
            executedMessages[messageId] = MsgDataTypes.TxStatus.Null;
            emit NeedRetry(
                MsgDataTypes.MsgType.MessageWithTransfer,
                messageId,
                _transfer.srcChainId,
                _transfer.srcTxHash
            );
            return;
        } else {
            est = executeMessageWithTransferFallback(_transfer, _message);
            if (est == IMessageReceiverApp.ExecutionStatus.Success) {
                status = MsgDataTypes.TxStatus.Fallback;
            } else {
                status = MsgDataTypes.TxStatus.Fail;
            }
        }
        executedMessages[messageId] = status;
        emitMessageWithTransferExecutedEvent(messageId, status, _transfer);
    }

    /**
     * @notice Execute a message with a refunded transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransferRefund(
        bytes calldata _message, // the same message associated with the original transfer
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) public payable {
        // similar to executeMessageWithTransfer
        bytes32 messageId = verifyTransfer(_transfer);
        require(executedMessages[messageId] == MsgDataTypes.TxStatus.Null, "transfer already executed");
        executedMessages[messageId] = MsgDataTypes.TxStatus.Pending;

        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), "MessageWithTransferRefund"));
        IBridge(liquidityBridge).verifySigs(
            abi.encodePacked(domain, messageId, _message, _transfer.srcTxHash),
            _sigs,
            _signers,
            _powers
        );
        MsgDataTypes.TxStatus status;
        IMessageReceiverApp.ExecutionStatus est = executeMessageWithTransferRefund(_transfer, _message);
        if (est == IMessageReceiverApp.ExecutionStatus.Success) {
            status = MsgDataTypes.TxStatus.Success;
        } else if (est == IMessageReceiverApp.ExecutionStatus.Retry) {
            executedMessages[messageId] = MsgDataTypes.TxStatus.Null;
            emit NeedRetry(
                MsgDataTypes.MsgType.MessageWithTransfer,
                messageId,
                _transfer.srcChainId,
                _transfer.srcTxHash
            );
            return;
        } else {
            status = MsgDataTypes.TxStatus.Fail;
        }
        executedMessages[messageId] = status;
        emitMessageWithTransferExecutedEvent(messageId, status, _transfer);
    }

    /**
     * @notice Execute a message not associated with a transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _route The info about the sender and the receiver.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessage(
        bytes calldata _message,
        MsgDataTypes.RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable {
        MsgDataTypes.Route memory route = getRouteInfo(_route);
        executeMessage(_message, route, _sigs, _signers, _powers, "Message");
    }

    // execute message from non-evm chain with bytes for sender address,
    // otherwise same as above.
    function executeMessage(
        bytes calldata _message,
        MsgDataTypes.RouteInfo2 calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable {
        MsgDataTypes.Route memory route = getRouteInfo(_route);
        executeMessage(_message, route, _sigs, _signers, _powers, "Message2");
    }

    function executeMessage(
        bytes calldata _message,
        MsgDataTypes.Route memory _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers,
        string memory domainName
    ) private {
        // For message without associated token transfer, message Id is computed through message info,
        // in order to guarantee that each message can only be applied once
        bytes32 messageId = computeMessageOnlyId(_route, _message);
        require(executedMessages[messageId] == MsgDataTypes.TxStatus.Null, "message already executed");
        executedMessages[messageId] = MsgDataTypes.TxStatus.Pending;

        bytes32 domain = keccak256(abi.encodePacked(block.chainid, address(this), domainName));
        IBridge(liquidityBridge).verifySigs(abi.encodePacked(domain, messageId), _sigs, _signers, _powers);
        MsgDataTypes.TxStatus status;
        IMessageReceiverApp.ExecutionStatus est = executeMessage(_route, _message);
        if (est == IMessageReceiverApp.ExecutionStatus.Success) {
            status = MsgDataTypes.TxStatus.Success;
        } else if (est == IMessageReceiverApp.ExecutionStatus.Retry) {
            executedMessages[messageId] = MsgDataTypes.TxStatus.Null;
            emit NeedRetry(MsgDataTypes.MsgType.MessageOnly, messageId, _route.srcChainId, _route.srcTxHash);
            return;
        } else {
            status = MsgDataTypes.TxStatus.Fail;
        }
        executedMessages[messageId] = status;
        emitMessageOnlyExecutedEvent(messageId, status, _route);
    }

    // ================= utils (to avoid stack too deep) =================

    function emitMessageWithTransferExecutedEvent(
        bytes32 _messageId,
        MsgDataTypes.TxStatus _status,
        MsgDataTypes.TransferInfo calldata _transfer
    ) private {
        emit Executed(
            MsgDataTypes.MsgType.MessageWithTransfer,
            _messageId,
            _status,
            _transfer.receiver,
            _transfer.srcChainId,
            _transfer.srcTxHash
        );
    }

    function emitMessageOnlyExecutedEvent(
        bytes32 _messageId,
        MsgDataTypes.TxStatus _status,
        MsgDataTypes.Route memory _route
    ) private {
        emit Executed(
            MsgDataTypes.MsgType.MessageOnly,
            _messageId,
            _status,
            _route.receiver,
            _route.srcChainId,
            _route.srcTxHash
        );
    }

    function executeMessageWithTransfer(MsgDataTypes.TransferInfo calldata _transfer, bytes calldata _message)
        private
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        uint256 gasLeftBeforeExecution = gasleft();
        (bool ok, bytes memory res) = address(_transfer.receiver).call{value: msg.value}(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessageWithTransfer.selector,
                _transfer.sender,
                _transfer.token,
                _transfer.amount,
                _transfer.srcChainId,
                _message,
                msg.sender
            )
        );
        if (ok) {
            return abi.decode((res), (IMessageReceiverApp.ExecutionStatus));
        }
        handleExecutionRevert(gasLeftBeforeExecution, res);
        return IMessageReceiverApp.ExecutionStatus.Fail;
    }

    function executeMessageWithTransferFallback(MsgDataTypes.TransferInfo calldata _transfer, bytes calldata _message)
        private
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        uint256 gasLeftBeforeExecution = gasleft();
        (bool ok, bytes memory res) = address(_transfer.receiver).call{value: msg.value}(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessageWithTransferFallback.selector,
                _transfer.sender,
                _transfer.token,
                _transfer.amount,
                _transfer.srcChainId,
                _message,
                msg.sender
            )
        );
        if (ok) {
            return abi.decode((res), (IMessageReceiverApp.ExecutionStatus));
        }
        handleExecutionRevert(gasLeftBeforeExecution, res);
        return IMessageReceiverApp.ExecutionStatus.Fail;
    }

    function executeMessageWithTransferRefund(MsgDataTypes.TransferInfo calldata _transfer, bytes calldata _message)
        private
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        uint256 gasLeftBeforeExecution = gasleft();
        (bool ok, bytes memory res) = address(_transfer.receiver).call{value: msg.value}(
            abi.encodeWithSelector(
                IMessageReceiverApp.executeMessageWithTransferRefund.selector,
                _transfer.token,
                _transfer.amount,
                _message,
                msg.sender
            )
        );
        if (ok) {
            return abi.decode((res), (IMessageReceiverApp.ExecutionStatus));
        }
        handleExecutionRevert(gasLeftBeforeExecution, res);
        return IMessageReceiverApp.ExecutionStatus.Fail;
    }

    function verifyTransfer(MsgDataTypes.TransferInfo calldata _transfer) private view returns (bytes32) {
        bytes32 transferId;
        address bridgeAddr;
        if (_transfer.t == MsgDataTypes.TransferType.LqRelay) {
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.sender,
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.srcChainId,
                    uint64(block.chainid),
                    _transfer.refId
                )
            );
            bridgeAddr = liquidityBridge;
            require(IBridge(bridgeAddr).transfers(transferId) == true, "bridge relay not exist");
        } else if (_transfer.t == MsgDataTypes.TransferType.LqWithdraw) {
            transferId = keccak256(
                abi.encodePacked(
                    uint64(block.chainid),
                    _transfer.wdseq,
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount
                )
            );
            bridgeAddr = liquidityBridge;
            require(IBridge(bridgeAddr).withdraws(transferId) == true, "bridge withdraw not exist");
        } else if (
            _transfer.t == MsgDataTypes.TransferType.PegMint || _transfer.t == MsgDataTypes.TransferType.PegWithdraw
        ) {
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.sender,
                    _transfer.srcChainId,
                    _transfer.refId
                )
            );
            if (_transfer.t == MsgDataTypes.TransferType.PegMint) {
                bridgeAddr = pegBridge;
                require(IPeggedTokenBridge(bridgeAddr).records(transferId) == true, "mint record not exist");
            } else {
                // _transfer.t == MsgDataTypes.TransferType.PegWithdraw
                bridgeAddr = pegVault;
                require(IOriginalTokenVault(bridgeAddr).records(transferId) == true, "withdraw record not exist");
            }
        } else if (
            _transfer.t == MsgDataTypes.TransferType.PegV2Mint || _transfer.t == MsgDataTypes.TransferType.PegV2Withdraw
        ) {
            if (_transfer.t == MsgDataTypes.TransferType.PegV2Mint) {
                bridgeAddr = pegBridgeV2;
            } else {
                // MsgDataTypes.TransferType.PegV2Withdraw
                bridgeAddr = pegVaultV2;
            }
            transferId = keccak256(
                abi.encodePacked(
                    _transfer.receiver,
                    _transfer.token,
                    _transfer.amount,
                    _transfer.sender,
                    _transfer.srcChainId,
                    _transfer.refId,
                    bridgeAddr
                )
            );
            if (_transfer.t == MsgDataTypes.TransferType.PegV2Mint) {
                require(IPeggedTokenBridgeV2(bridgeAddr).records(transferId) == true, "mint record not exist");
            } else {
                // MsgDataTypes.TransferType.PegV2Withdraw
                require(IOriginalTokenVaultV2(bridgeAddr).records(transferId) == true, "withdraw record not exist");
            }
        }
        return keccak256(abi.encodePacked(MsgDataTypes.MsgType.MessageWithTransfer, bridgeAddr, transferId));
    }

    function computeMessageOnlyId(MsgDataTypes.Route memory _route, bytes calldata _message)
        private
        view
        returns (bytes32)
    {
        bytes memory sender = _route.senderBytes;
        if (sender.length == 0) {
            sender = abi.encodePacked(_route.sender);
        }
        return
            keccak256(
                abi.encodePacked(
                    MsgDataTypes.MsgType.MessageOnly,
                    sender,
                    _route.receiver,
                    _route.srcChainId,
                    _route.srcTxHash,
                    uint64(block.chainid),
                    _message
                )
            );
    }

    function executeMessage(MsgDataTypes.Route memory _route, bytes calldata _message)
        private
        returns (IMessageReceiverApp.ExecutionStatus)
    {
        uint256 gasLeftBeforeExecution = gasleft();
        bool ok;
        bytes memory res;
        if (_route.senderBytes.length == 0) {
            (ok, res) = address(_route.receiver).call{value: msg.value}(
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("executeMessage(address,uint64,bytes,address)"))),
                    _route.sender,
                    _route.srcChainId,
                    _message,
                    msg.sender
                )
            );
        } else {
            (ok, res) = address(_route.receiver).call{value: msg.value}(
                abi.encodeWithSelector(
                    bytes4(keccak256(bytes("executeMessage(bytes,uint64,bytes,address)"))),
                    _route.senderBytes,
                    _route.srcChainId,
                    _message,
                    msg.sender
                )
            );
        }
        if (ok) {
            return abi.decode((res), (IMessageReceiverApp.ExecutionStatus));
        }
        handleExecutionRevert(gasLeftBeforeExecution, res);
        return IMessageReceiverApp.ExecutionStatus.Fail;
    }

    function handleExecutionRevert(uint256 _gasLeftBeforeExecution, bytes memory _returnData) private {
        uint256 gasLeftAfterExecution = gasleft();
        uint256 maxTargetGasLimit = block.gaslimit - preExecuteMessageGasUsage;
        if (_gasLeftBeforeExecution < maxTargetGasLimit && gasLeftAfterExecution <= _gasLeftBeforeExecution / 64) {
            // if this happens, the executor must have not provided sufficient gas limit,
            // then the tx should revert instead of recording a non-retryable failure status
            // https://github.com/wolflo/evm-opcodes/blob/main/gas.md#aa-f-gas-to-send-with-call-operations
            assembly {
                invalid()
            }
        }
        string memory revertMsg = Utils.getRevertMsg(_returnData);
        // revert the execution if the revert message has the ABORT prefix
        checkAbortPrefix(revertMsg);
        // otherwiase, emit revert message, return and mark the execution as failed (non-retryable)
        emit CallReverted(revertMsg);
    }

    function checkAbortPrefix(string memory _revertMsg) private pure {
        bytes memory prefixBytes = bytes(MsgDataTypes.ABORT_PREFIX);
        bytes memory msgBytes = bytes(_revertMsg);
        if (msgBytes.length >= prefixBytes.length) {
            for (uint256 i = 0; i < prefixBytes.length; i++) {
                if (msgBytes[i] != prefixBytes[i]) {
                    return; // prefix not match, return
                }
            }
            revert(_revertMsg); // prefix match, revert
        }
    }

    function getRouteInfo(MsgDataTypes.RouteInfo calldata _route) private pure returns (MsgDataTypes.Route memory) {
        return MsgDataTypes.Route(_route.sender, "", _route.receiver, _route.srcChainId, _route.srcTxHash);
    }

    function getRouteInfo(MsgDataTypes.RouteInfo2 calldata _route) private pure returns (MsgDataTypes.Route memory) {
        return MsgDataTypes.Route(address(0), _route.sender, _route.receiver, _route.srcChainId, _route.srcTxHash);
    }

    // ================= helper functions =====================

    /**
     * @notice combine bridge transfer and msg execution calls into a single tx
     * @dev caller needs to get the required input params from SGN
     * @param _transferParams params to call bridge transfer
     * @param _msgParams params to execute message
     */
    function transferAndExecuteMsg(
        MsgDataTypes.BridgeTransferParams calldata _transferParams,
        MsgDataTypes.MsgWithTransferExecutionParams calldata _msgParams
    ) external {
        _bridgeTransfer(_msgParams.transfer.t, _transferParams);
        executeMessageWithTransfer(
            _msgParams.message,
            _msgParams.transfer,
            _msgParams.sigs,
            _msgParams.signers,
            _msgParams.powers
        );
    }

    /**
     * @notice combine bridge refund and msg execution calls into a single tx
     * @dev caller needs to get the required input params from SGN
     * @param _transferParams params to call bridge transfer for refund
     * @param _msgParams params to execute message for refund
     */
    function refundAndExecuteMsg(
        MsgDataTypes.BridgeTransferParams calldata _transferParams,
        MsgDataTypes.MsgWithTransferExecutionParams calldata _msgParams
    ) external {
        _bridgeTransfer(_msgParams.transfer.t, _transferParams);
        executeMessageWithTransferRefund(
            _msgParams.message,
            _msgParams.transfer,
            _msgParams.sigs,
            _msgParams.signers,
            _msgParams.powers
        );
    }

    function _bridgeTransfer(MsgDataTypes.TransferType t, MsgDataTypes.BridgeTransferParams calldata _transferParams)
        private
    {
        if (t == MsgDataTypes.TransferType.LqRelay) {
            IBridge(liquidityBridge).relay(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.LqWithdraw) {
            IBridge(liquidityBridge).withdraw(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.PegMint) {
            IPeggedTokenBridge(pegBridge).mint(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.PegV2Mint) {
            IPeggedTokenBridgeV2(pegBridgeV2).mint(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.PegWithdraw) {
            IOriginalTokenVault(pegVault).withdraw(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        } else if (t == MsgDataTypes.TransferType.PegV2Withdraw) {
            IOriginalTokenVaultV2(pegVaultV2).withdraw(
                _transferParams.request,
                _transferParams.sigs,
                _transferParams.signers,
                _transferParams.powers
            );
        }
    }

    // ================= contract config =================

    function setLiquidityBridge(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        liquidityBridge = _addr;
        emit LiquidityBridgeUpdated(liquidityBridge);
    }

    function setPegBridge(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegBridge = _addr;
        emit PegBridgeUpdated(pegBridge);
    }

    function setPegVault(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegVault = _addr;
        emit PegVaultUpdated(pegVault);
    }

    function setPegBridgeV2(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegBridgeV2 = _addr;
        emit PegBridgeV2Updated(pegBridgeV2);
    }

    function setPegVaultV2(address _addr) public onlyOwner {
        require(_addr != address(0), "invalid address");
        pegVaultV2 = _addr;
        emit PegVaultV2Updated(pegVaultV2);
    }

    function setPreExecuteMessageGasUsage(uint256 _usage) public onlyOwner {
        preExecuteMessageGasUsage = _usage;
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

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
 *
 * This adds a normal func that setOwner if _owner is address(0). So we can't allow
 * renounceOwnership. So we can support Proxy based upgradable contract
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(msg.sender);
    }

    /**
     * @dev Only to be called by inherit contracts, in their init func called by Proxy
     * we require _owner == address(0), which is only possible when it's a delegateCall
     * because constructor sets _owner in contract state.
     */
    function initOwner() internal {
        require(_owner == address(0), "owner already set");
        _setOwner(msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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

import "../libraries/LibAppStorage.sol";
import {IERC20Mintable} from "../../interfaces/IERC20Mintable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "../interfaces/IMultiBridgeFacet.sol";
import "../interfaces/IKhalaInterchainAccount.sol";

contract AxonCrossChainRouter is Modifiers {

    event LogWithdrawAndCall(
        address indexed user,
        address indexed token,
        uint256 amount,
        Call[] calls
    );

    event LogWithdrawMultiTokenAndCall(
        address indexed user,
        address[] tokens,
        uint256[] amounts,
        Call[] calls
    );

    event LogCrossChainMsg(
        address indexed recipient,
        bytes message
    );

    event LogBurnToken(
        address indexed user,
        address token,
        uint256 amount
    );

    event LogReleaseToken(
        address indexed user,
        address token,
        uint256 amount
    );

    /**
    * @dev This function allows a user to withdraw multiple tokens and make a call to a smart contract.
    *
    * @param chainId Destination chain id
    * @param token  Tokens to be withdrawn.
    * @param amount Amount of token to be withdrawn.
    * @param receiver The address to receive the withdrawn tokens.
    * @param calls An array of calls to be executed after the tokens have been withdrawn.
    */
    function withdrawTokenAndCall(
        uint chainId,
        address token,
        uint256 amount,
        address receiver,
        Call[] calldata calls
    ) external {
        IERC20Mintable(token).burn(msg.sender,amount);
        _bridgeTokenAndSendMessage(chainId,receiver,token,amount,calls);
    }

    /**
    * @dev This function allows a user to withdraw multiple tokens and make a call to a smart contract.
    *
    * @param chainId Destination chain id
    * @param tokens An array of addresses representing the tokens to be withdrawn.
    * @param amounts Amount of each token to be withdrawn.
    * @param receiver The address to receive the withdrawn tokens.
    * @param calls An array of calls to be executed after the tokens have been withdrawn.
    */
    function withdrawMultiTokenAndCall(
        uint chainId,
        address[] memory tokens,
        uint256[] memory amounts,
        address receiver,
        Call[] calldata calls
    ) external {
        require(tokens.length == amounts.length , "array length do not match");

        for(uint i; i<tokens.length;) {
            IERC20Mintable(tokens[i]).burn(msg.sender,amounts[i]);
            unchecked {
                ++i;
            }
        }

        _bridgeTokensAndSendMessage(chainId,receiver,tokens,amounts,calls);
    }

    /*
    * @dev This function bridges a token from axon to  and executes a message call.
    *
    * @param Destination chain id.
    * @param receiver The address to receive the bridged token.
    * @param token The address of the token to be bridged.
    * @param amount The amount of the token to be bridged.
    * @param calls An array of calls to be executed after the token has been bridged.
    */
    function _bridgeTokenAndSendMessage(
        uint chainId,
        address receiver,
        address token,
        uint amount,
        Call[] calldata calls
    ) internal {
        if(s.godwokenChainId == chainId) {

            IMultiBridgeFacet(address(this)).bridgeTokenAndCallbackViaCeler(
                LibAppStorage.TokenBridgeAction.Withdraw,
                uint64(chainId),
                msg.sender,
                receiver,
                token,
                amount,
                calls
            );

        } else {

            IMultiBridgeFacet(address(this)).bridgeTokenAndCallbackViaHyperlane(
                LibAppStorage.TokenBridgeAction.Withdraw,
                uint32(chainId),
                msg.sender,
                receiver,
                token,
                amount,
                calls
            );

        }


        emit LogWithdrawAndCall(
            msg.sender,
            token,
            amount,
            calls
        );
    }

    /**
    * @dev This function bridges multiple tokens from axon to a destination and executes a message call.
    *
    * @param chainId The chain identifier for the blockchain the tokens are being bridged from.
    * @param receiver The address to receive the bridged tokens.
    * @param tokens An array of addresses representing the tokens to be bridged.
    * @param amounts An array of uint values representing the amount of each token to be bridged.
    * @param calls An array of calls to be executed after the tokens have been bridged.
    */
    function _bridgeTokensAndSendMessage(
        uint chainId,
        address receiver,
        address[] memory tokens,
        uint[] memory amounts,
        Call[] calldata calls
    ) internal {
        if(s.godwokenChainId == chainId) {

            IMultiBridgeFacet(address(this)).bridgeMultiTokenAndCallbackViaCeler(
                LibAppStorage.TokenBridgeAction.WithdrawMulti,
                uint64(chainId),
                msg.sender,
                receiver,
                tokens,
                amounts,
                calls
            );

        } else {

            IMultiBridgeFacet(address(this)).bridgeMultiTokenAndCallbackViaHyperlane(
                LibAppStorage.TokenBridgeAction.WithdrawMulti,
                uint32(chainId),
                msg.sender,
                receiver,
                tokens,
                amounts,
                calls
            );

        }

        emit LogWithdrawMultiTokenAndCall (
            msg.sender,
            tokens,
            amounts,
            calls
        );
    }
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface ISigsVerifier {
    /**
     * @notice Verifies that a message is signed by a quorum among the signers.
     * @param _msg signed message
     * @param _sigs list of signatures sorted by signer addresses in ascending order
     * @param _signers sorted list of current signers
     * @param _powers powers of current signers
     */
    function verifySigs(
        bytes memory _msg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external view;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

library Utils {
    // https://ethereum.stackexchange.com/a/83577
    // https://github.com/Uniswap/v3-periphery/blob/v1.0.0/contracts/base/Multicall.sol
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

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
 * ```solidity
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 *
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
        if (_initialized != type(uint8).max) {
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "../libraries/LibAppStorage.sol";
import {Call} from "../Call.sol";

interface IMultiBridgeFacet {

    function bridgeTokenAndCallbackViaHyperlane(
        LibAppStorage.TokenBridgeAction action,
        uint32 chainDomain,
        address sender,
        address account,
        address token,
        uint256 amount,
        Call[] calldata calls
    ) external payable ;

    function bridgeMultiTokenAndCallbackViaHyperlane(
        LibAppStorage.TokenBridgeAction action,
        uint32 chainDomain,
        address sender,
        address account,
        address[] memory tokens,
        uint256[] memory amounts,
        Call[] calldata calls
    ) external payable ;

    function bridgeTokenAndCallbackViaCeler(
        LibAppStorage.TokenBridgeAction action,
        uint64 chainId,
        address sender,
        address account,
        address token,
        uint256 amount,
        Call[] calldata calls
    ) external payable ;

    function bridgeMultiTokenAndCallbackViaCeler(
        LibAppStorage.TokenBridgeAction action,
        uint64 chainId,
        address sender,
        address account,
        address[] memory tokens,
        uint256[] memory amounts,
        Call[] calldata calls
    ) external payable ;

}