// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../libraries/LibAppStorage.sol";
import "./libraries/HyperlaneFacetLibrary.sol";
import "@hyperlane-xyz/core/contracts/libs/TypeCasts.sol";
import "@hyperlane-xyz/core/interfaces/IMailbox.sol";
import "@hyperlane-xyz/core/interfaces/IInterchainSecurityModule.sol";
import "../../interfaces/IBridgeFacet.sol";
import "../../libraries/LibNexusABI.sol";
import {Call} from "../../Call.sol";

// Hyperlane Facet for non Axon chain //TODO : Should we make this all `internal` ?
contract HyperlaneFacet is IBridgeFacet, Modifiers {

    function initHyperlaneFacet(
        address _hyperlaneMailbox,
        address _ism
    ) external onlyDiamondOwner {
        HyperlaneStorage storage hs = HyperlaneFacetLibrary.hyperlaneStorage();
        hs.hyperlaneMailbox = _hyperlaneMailbox;
        hs.interchainSecurityModule = IInterchainSecurityModule(_ism);
    }

    function interchainSecurityModule() public view returns (IInterchainSecurityModule ism){
        HyperlaneStorage storage hs = HyperlaneFacetLibrary.hyperlaneStorage();
        return hs.interchainSecurityModule;
    }

    function bridgeTokenAndCall(
        LibAppStorage.TokenBridgeAction action,
        address account,
        address token,
        uint256 amount,
        Call[] calldata calls
    ) public payable override validRouter  {
        HyperlaneStorage storage hs = HyperlaneFacetLibrary.hyperlaneStorage();
        bytes memory messageWithAction = LibNexusABI.encodeData1(action,account,token,amount,calls);
        IMailbox(hs.hyperlaneMailbox).dispatch(
            uint32(s.axonChainId),
            TypeCasts.addressToBytes32(s.axonReceiver),
            messageWithAction
        );
    }


    function bridgeMultiTokenAndCall(
        LibAppStorage.TokenBridgeAction action,
        address account,
        address[] memory tokens,
        uint256[] memory amounts,
        Call[] calldata calls
    ) public payable override validRouter {
        HyperlaneStorage storage hs = HyperlaneFacetLibrary.hyperlaneStorage();
        bytes memory messageWithAction = LibNexusABI.encodeData2(action,account,tokens,amounts,calls);
        IMailbox(hs.hyperlaneMailbox).dispatch(
            uint32(s.axonChainId),
            TypeCasts.addressToBytes32(s.axonReceiver),
            messageWithAction
        );
    }

    //function to pass an arbitrary message to axon using hyperlane mailbox
    function sendMultiCall(
        Call[] calldata calls
    ) external payable override  {
        HyperlaneStorage storage hs = HyperlaneFacetLibrary.hyperlaneStorage();
        bytes memory message = LibNexusABI.encodeData3(LibAppStorage.TokenBridgeAction.MultiCall,msg.sender,calls);
        IMailbox(hs.hyperlaneMailbox).dispatch(
            uint32(s.axonChainId),
            TypeCasts.addressToBytes32(s.axonReceiver),
            message
        );
    }

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

// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.8.0;

import {IInterchainSecurityModule} from "./IInterchainSecurityModule.sol";

interface IMailbox {
    function localDomain() external view returns (uint32);

    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        bytes calldata _messageBody
    ) external returns (bytes32);

    function process(bytes calldata _metadata, bytes calldata _message)
        external;

    function count() external view returns (uint32);

    function root() external view returns (bytes32);

    function latestCheckpoint() external view returns (bytes32, uint32);

    function recipientIsm(address _recipient)
        external
        view
        returns (IInterchainSecurityModule);
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

import "../libraries/LibAppStorage.sol";
import {Call} from "../Call.sol";

interface IBridgeFacet {
    function bridgeTokenAndCall(
        LibAppStorage.TokenBridgeAction action,
        address account,
        address token,
        uint256 amount,
        Call[] calldata calls
    ) external payable ;

    function bridgeMultiTokenAndCall(
        LibAppStorage.TokenBridgeAction action,
        address account,
        address[] memory tokens,
        uint256[] memory amounts,
        Call[] calldata calls
    ) external payable ;

    function sendMultiCall(
        Call[] calldata calls
    ) external payable;
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

pragma solidity ^0.8.0;

//Nexus Errors
error InvalidInbox();
error InvalidNexus();
error InvalidRouter();

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