// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../helpers/Errors.sol";
import "../../helpers/TransferHelper.sol";
import "../../helpers/Pb.sol";
import "../../helpers/PbPool.sol";
import "../../BridgeBase.sol";

interface ICelerBridgeRouter {
    function send(
        address _receiver,
        address _token,
        uint256 _amount,
        uint64 _dstChinId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external;

    function sendNative(
        address _receiver,
        uint256 _amount,
        uint64 _dstChinId,
        uint64 _nonce,
        uint32 _maxSlippage
    ) external payable;

    function withdraws(bytes32 withdrawId) external view returns (bool);

    function withdraw(
        bytes calldata _wdmsg,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;
}

contract CelerBridgeBaseIpml is BridgeBase, ReentrancyGuard {
    using Pb for Pb.Buffer;
    ICelerBridgeRouter public immutable celerBridgeRouter;
    address immutable wethAddress;
    mapping(bytes32 => address) public transferIdAdrressMap;
    uint64 public immutable chainId;

    constructor(
        ICelerBridgeRouter _celerBridgeRouter,
        address _router,
        address _wethAddress
    ) BridgeBase(_router) {
        celerBridgeRouter = _celerBridgeRouter;
        chainId = uint64(block.chainid);
        wethAddress = _wethAddress;
    }

    event Bridge(uint256 amount, address fromToken, uint256 toChainId, address toAddress, address toToken, string channel, uint256 channelFee);

    struct CelerBridgeData {
        uint64 nonce;
        uint32 maxSlippage;
        address senderAddress;
        address _toTokenAddress;
        string _channel;
        uint256 _channelFee;
    }

    function bridge(
        address _fromAddress,
        address _fromToken,
        uint256 _amount,
        address _receiverAddress,
        uint256 _toChainId,
        bytes memory _extraData,
        address _feeAddress
    ) external payable override onlyRouter nonReentrant {
        (CelerBridgeData memory celerData) = abi.decode(
            _extraData,
            (CelerBridgeData)
        );
        uint256 feeAmount = (_amount * celerData._channelFee) / 1000000;
        if (_fromToken == NATIVE_TOKEN_ADDRESS) {
            require(msg.value == _amount, Errors.VALUE_NOT_EQUAL_TO_AMOUNT);
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    _receiverAddress,
                    wethAddress,
                    _amount,
                    uint64(_toChainId),
                    celerData.nonce,
                    chainId
                )
            );
            require(
                transferIdAdrressMap[transferId] == address(0),
                Errors.UNKNOWN_TRANSFER_ID
            );
            if (celerData._channelFee != 0) {
                payable(_feeAddress).transfer(feeAmount);
                _amount = _amount - feeAmount;
            }
            transferIdAdrressMap[transferId] = celerData.senderAddress;
            celerBridgeRouter.sendNative{value: _amount}(
                _receiverAddress,
                _amount,
                uint64(_toChainId),
                celerData.nonce,
                celerData.maxSlippage
            );
        } else {
            require(msg.value == 0, Errors.VALUE_SHOULD_BE_ZERO);
            TransferHelper.safeTransferFrom(
                _fromToken,
                _fromAddress,
                address(this),
                _amount
            );
            if (celerData._channelFee != 0) {
                TransferHelper.safeTransfer(_fromToken, _feeAddress, feeAmount);
                _amount = _amount - feeAmount;
            }
            TransferHelper.safeApprove(
                _fromToken,
                address(celerBridgeRouter),
                _amount
            );
            bytes32 transferId = keccak256(
                abi.encodePacked(
                    address(this),
                    _receiverAddress,
                    _fromToken,
                    _amount,
                    uint64(_toChainId),
                    celerData.nonce,
                    chainId
                )
            );
            require(
                transferIdAdrressMap[transferId] == address(0),
                Errors.UNKNOWN_TRANSFER_ID
            );
            transferIdAdrressMap[transferId] = celerData.senderAddress;
            celerBridgeRouter.send(
                _receiverAddress,
                _fromToken,
                _amount,
                uint64(_toChainId),
                celerData.nonce,
                celerData.maxSlippage
            );
        }
        emit Bridge(
            _amount,
            _fromToken,
            _toChainId,
            _receiverAddress,
            celerData._toTokenAddress,
            celerData._channel,
            celerData._channelFee
        );
    }

    function refundCelerUser(
        bytes calldata _request,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable nonReentrant {
        PbPool.WithdrawMsg memory request = PbPool.decWithdrawMsg(_request);
        bytes32 transferId = keccak256(
            abi.encodePacked(
                request.chainid,
                request.seqnum,
                request.receiver,
                request.token,
                request.amount
            )
        );
        uint256 _initialBalanceTokenOut = address(this).balance;
        if (!celerBridgeRouter.withdraws(transferId)) {
            celerBridgeRouter.withdraw(_request, _sigs, _signers, _powers);
        }
        require(request.receiver == address(this), Errors.INVALID_ADDRESS);
        address _receiver = transferIdAdrressMap[request.refid];
        delete transferIdAdrressMap[request.refid];
        require(_receiver != address(0), Errors.UNKNOWN_TRANSFER_ID);
        if (address(this).balance > _initialBalanceTokenOut) {
            payable(_receiver).transfer(request.amount);
        } else {
            TransferHelper.safeTransfer(
                request.token,
                _receiver,
                request.amount
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: GPL-3.0-only

// Code generated by protoc-gen-sol. DO NOT EDIT.
// source: contracts/libraries/proto/pool.proto
pragma solidity 0.8.9;
import "./Pb.sol";

library PbPool {
    using Pb for Pb.Buffer; // so we can call Pb funcs on Buffer obj

    struct WithdrawMsg {
        uint64 chainid; // tag: 1
        uint64 seqnum; // tag: 2
        address receiver; // tag: 3
        address token; // tag: 4
        uint256 amount; // tag: 5
        bytes32 refid; // tag: 6
    } // end struct WithdrawMsg

    function decWithdrawMsg(bytes memory raw)
        internal
        pure
        returns (WithdrawMsg memory m)
    {
        Pb.Buffer memory buf = Pb.fromBytes(raw);

        uint256 tag;
        Pb.WireType wire;
        while (buf.hasMore()) {
            (tag, wire) = buf.decKey();
            if (false) {}
            // solidity has no switch/case
            else if (tag == 1) {
                m.chainid = uint64(buf.decVarint());
            } else if (tag == 2) {
                m.seqnum = uint64(buf.decVarint());
            } else if (tag == 3) {
                m.receiver = Pb._address(buf.decBytes());
            } else if (tag == 4) {
                m.token = Pb._address(buf.decBytes());
            } else if (tag == 5) {
                m.amount = Pb._uint256(buf.decBytes());
            } else if (tag == 6) {
                m.refid = Pb._bytes32(buf.decBytes());
            } else {
                buf.skipValue(wire);
            } // skip value of unknown tag
        }
    } // end decoder WithdrawMsg
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.4;

// runtime proto sol library
library Pb {
    enum WireType {
        Varint,
        Fixed64,
        LengthDelim,
        StartGroup,
        EndGroup,
        Fixed32
    }

    struct Buffer {
        uint256 idx; // the start index of next read. when idx=b.length, we're done
        bytes b; // hold serialized proto msg, readonly
    }

    // create a new in-memory Buffer object from raw msg bytes
    function fromBytes(bytes memory raw)
        internal
        pure
        returns (Buffer memory buf)
    {
        buf.b = raw;
        buf.idx = 0;
    }

    // whether there are unread bytes
    function hasMore(Buffer memory buf) internal pure returns (bool) {
        return buf.idx < buf.b.length;
    }

    // decode current field number and wiretype
    function decKey(Buffer memory buf)
        internal
        pure
        returns (uint256 tag, WireType wiretype)
    {
        uint256 v = decVarint(buf);
        tag = v / 8;
        wiretype = WireType(v & 7);
    }

    // count tag occurrences, return an array due to no memory map support
    // have to create array for (maxtag+1) size. cnts[tag] = occurrences
    // should keep buf.idx unchanged because this is only a count function
    function cntTags(Buffer memory buf, uint256 maxtag)
        internal
        pure
        returns (uint256[] memory cnts)
    {
        uint256 originalIdx = buf.idx;
        cnts = new uint256[](maxtag + 1); // protobuf's tags are from 1 rather than 0
        uint256 tag;
        WireType wire;
        while (hasMore(buf)) {
            (tag, wire) = decKey(buf);
            cnts[tag] += 1;
            skipValue(buf, wire);
        }
        buf.idx = originalIdx;
    }

    // read varint from current buf idx, move buf.idx to next read, return the int value
    function decVarint(Buffer memory buf) internal pure returns (uint256 v) {
        bytes10 tmp; // proto int is at most 10 bytes (7 bits can be used per byte)
        bytes memory bb = buf.b; // get buf.b mem addr to use in assembly
        v = buf.idx; // use v to save one additional uint variable
        assembly {
            tmp := mload(add(add(bb, 32), v)) // load 10 bytes from buf.b[buf.idx] to tmp
        }
        uint256 b; // store current byte content
        v = 0; // reset to 0 for return value
        for (uint256 i = 0; i < 10; i++) {
            assembly {
                b := byte(i, tmp) // don't use tmp[i] because it does bound check and costs extra
            }
            v |= (b & 0x7F) << (i * 7);
            if (b & 0x80 == 0) {
                buf.idx += i + 1;
                return v;
            }
        }
        revert(); // i=10, invalid varint stream
    }

    // read length delimited field and return bytes
    function decBytes(Buffer memory buf)
        internal
        pure
        returns (bytes memory b)
    {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        b = new bytes(len);
        bytes memory bufB = buf.b; // get buf.b mem addr to use in assembly
        uint256 bStart;
        uint256 bufBStart = buf.idx;
        assembly {
            bStart := add(b, 32)
            bufBStart := add(add(bufB, 32), bufBStart)
        }
        for (uint256 i = 0; i < len; i += 32) {
            assembly {
                mstore(add(bStart, i), mload(add(bufBStart, i)))
            }
        }
        buf.idx = end;
    }

    // return packed ints
    function decPacked(Buffer memory buf)
        internal
        pure
        returns (uint256[] memory t)
    {
        uint256 len = decVarint(buf);
        uint256 end = buf.idx + len;
        require(end <= buf.b.length); // avoid overflow
        // array in memory must be init w/ known length
        // so we have to create a tmp array w/ max possible len first
        uint256[] memory tmp = new uint256[](len);
        uint256 i = 0; // count how many ints are there
        while (buf.idx < end) {
            tmp[i] = decVarint(buf);
            i++;
        }
        t = new uint256[](i); // init t with correct length
        for (uint256 j = 0; j < i; j++) {
            t[j] = tmp[j];
        }
        return t;
    }

    // move idx pass current value field, to beginning of next tag or msg end
    function skipValue(Buffer memory buf, WireType wire) internal pure {
        if (wire == WireType.Varint) {
            decVarint(buf);
        } else if (wire == WireType.LengthDelim) {
            uint256 len = decVarint(buf);
            buf.idx += len; // skip len bytes value data
            require(buf.idx <= buf.b.length); // avoid overflow
        } else {
            revert();
        } // unsupported wiretype
    }

    // type conversion help utils
    function _bool(uint256 x) internal pure returns (bool v) {
        return x != 0;
    }

    function _uint256(bytes memory b) internal pure returns (uint256 v) {
        require(b.length <= 32); // b's length must be smaller than or equal to 32
        assembly {
            v := mload(add(b, 32))
        } // load all 32bytes to v
        v = v >> (8 * (32 - b.length)); // only first b.length is valid
    }

    function _address(bytes memory b) internal pure returns (address v) {
        v = _addressPayable(b);
    }

    function _addressPayable(bytes memory b)
        internal
        pure
        returns (address payable v)
    {
        require(b.length == 20);
        //load 32bytes then shift right 12 bytes
        assembly {
            v := div(mload(add(b, 32)), 0x1000000000000000000000000)
        }
    }

    function _bytes32(bytes memory b) internal pure returns (bytes32 v) {
        require(b.length == 32);
        assembly {
            v := mload(add(b, 32))
        }
    }

    // uint[] to uint8[]
    function uint8s(uint256[] memory arr)
        internal
        pure
        returns (uint8[] memory t)
    {
        t = new uint8[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint8(arr[i]);
        }
    }

    function uint32s(uint256[] memory arr)
        internal
        pure
        returns (uint32[] memory t)
    {
        t = new uint32[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint32(arr[i]);
        }
    }

    function uint64s(uint256[] memory arr)
        internal
        pure
        returns (uint64[] memory t)
    {
        t = new uint64[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = uint64(arr[i]);
        }
    }

    function bools(uint256[] memory arr)
        internal
        pure
        returns (bool[] memory t)
    {
        t = new bool[](arr.length);
        for (uint256 i = 0; i < t.length; i++) {
            t[i] = arr[i] != 0;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library Errors {
    string internal constant ADDRESS_0_PROVIDED = "ADDRESS_0_PROVIDED";
    string internal constant DEX_NOT_ALLOWED = "DEX_NOT_ALLOWED";
    string internal constant TOKEN_NOT_SUPPORTED = "TOKEN_NOT_SUPPORTED";
    string internal constant SWAP_FAILED = "SWAP_FAILED";
    string internal constant VALUE_SHOULD_BE_ZERO = "VALUE_SHOULD_BE_ZERO";
    string internal constant VALUE_SHOULD_NOT_BE_ZERO = "VALUE_SHOULD_NOT_BE_ZERO";
    string internal constant VALUE_NOT_EQUAL_TO_AMOUNT = "VALUE_NOT_EQUAL_TO_AMOUNT";

    string internal constant INVALID_AMT = "INVALID_AMT";
    string internal constant INVALID_ADDRESS = "INVALID_ADDRESS";
    string internal constant INVALID_SENDER = "INVALID_SENDER";

    string internal constant UNKNOWN_TRANSFER_ID = "UNKNOWN_TRANSFER_ID";
    string internal constant CALL_DATA_MUST_SIGNED_BY_OWNER = "CALL_DATA_MUST_SIGNED_BY_OWNER";

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "./helpers/Errors.sol";
import "./helpers/TransferHelper.sol";


abstract contract BridgeBase is Ownable {
    address public router;
    address public constant NATIVE_TOKEN_ADDRESS = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    

    constructor(address _router) Ownable() {
        router = _router;
    }

    event UpdateRouterAddress(address indexed routerAddress);

    event WithdrawETH(uint256 amount);

    event Withdraw(address token, uint256 amount);

    modifier onlyRouter() {
        require(msg.sender == router, Errors.INVALID_SENDER);
        _;
    }

    function updateRouterAddress(address newRouter) external onlyOwner {
        router = newRouter;
        emit UpdateRouterAddress(newRouter);
    }

    function bridge(
        address _fromAddress,
        address _fromToken,
        uint256 _amount,
        address _receiverAddress,
        uint256 _toChainId,
        bytes memory _extraData,
        address feeAddress
    ) external payable virtual;


    function withdraw(address _token, address _receiverAddress, uint256 _amount) external onlyOwner {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransfer(_token, _receiverAddress, _amount);
        emit Withdraw(_token, _amount);
    }

    function withdrawETH(address _receiverAddress, uint256 _amount) external onlyOwner {
        require(_receiverAddress != address(0), Errors.ADDRESS_0_PROVIDED);
        TransferHelper.safeTransferETH(_receiverAddress, _amount);
        emit WithdrawETH(_amount);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
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