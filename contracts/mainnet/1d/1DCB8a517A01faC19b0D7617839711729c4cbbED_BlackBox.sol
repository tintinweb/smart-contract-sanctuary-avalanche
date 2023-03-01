// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPhoenix.sol";
import "./interfaces/IWormholeCore.sol";
import "./interfaces/IAlpha.sol";
import "./lib/LibAsset.sol";
import "./lib/LibBytes.sol";
import "./lib/LibSwap.sol";
import "./lib/LibUint256Array.sol";

contract BlackBox is Ownable {
    using LibAsset for address;
    using LibBytes for bytes;
    using LibUint256Array for uint256[];
    using LibSwap for IAlpha.SwapArgs;

    address public phoenixAddress;
    address public AlphaAddress;
    address public coreAddress;
    uint8 public consistencyLevel;
    mapping(string => address) public mappedSymbol;
    mapping(address => uint256) public totalAmountPerToken;
    mapping(string => bool) public isListed;

    constructor(
        address _phoenixAddress,
        address _AlphaAddress,
        address _coreAddress,
        uint8 _consistencyLevel
    ) {
        phoenixAddress = _phoenixAddress;
        AlphaAddress = _AlphaAddress;
        coreAddress = _coreAddress;
        consistencyLevel = _consistencyLevel;
    }

    function mapSymbol(string memory symbol, address assetAddress)
        external
        onlyOwner
    {
        require(!isListed[symbol], "BlackBox: Symbol already listed");
        mappedSymbol[symbol] = assetAddress;
        // suppose this blackbox is deployed on matic. mappedSymbol["USDC"]=0x...

        isListed[symbol] = true;
    }

    function getPayload(bytes memory encodedVm)
        public
        view
        returns (
            address senderAddress,
            address destinationAssetAddress,
            uint256 swappingChain,
            uint256 amountIn,
            uint256 amountOutMin,
            string memory symbol,
            uint64 sequence
        )
    {
        IWormholeCore.VM memory vm = getVM(encodedVm);

        sequence = vm.sequence;
        (
            senderAddress,
            destinationAssetAddress,
            swappingChain,
            amountIn,
            amountOutMin,
            symbol
        ) = vm.payload.parseSwapInfo();
    }

    function getVM(bytes memory encodedVm)
        private
        view
        returns (IWormholeCore.VM memory)
    {
        (
            IWormholeCore.VM memory vm,
            bool valid,
            string memory reason
        ) = IWormholeCore(coreAddress).parseAndVerifyVM(encodedVm);
        require(valid, reason);

        return vm;
    }

    function depositAsset(string memory symbol, uint256 amount)
        public
        returns (uint64 coreSequence)
    {
        address assetAddress = mappedSymbol[symbol];

        assetAddress.deposit(amount);

        bytes memory payload = abi.encodePacked(
            bytes32(uint256(uint160(address(msg.sender)))),
            block.chainid,
            amount,
            getDecimals(assetAddress),
            bytes32(bytes(symbol))
        );

        coreSequence = IWormholeCore(coreAddress).publishMessage(
            uint32(block.timestamp % 2**32),
            payload,
            consistencyLevel
        );

        totalAmountPerToken[assetAddress] += amount;
    }

    function getDecimals(address tokenAddress)
        private
        view
        returns (uint8 tokenDecimals)
    {
        tokenDecimals = 18;

        if (!tokenAddress.isNative()) {
            (, bytes memory queriedDecimals) = tokenAddress.staticcall(
                abi.encodeWithSignature("decimals()")
            );
            tokenDecimals = abi.decode(queriedDecimals, (uint8));
        }
    }

    function normalize(
        uint8 fromDecimals,
        uint8 toDecimals,
        uint256 amount
    ) private pure returns (uint256 amountOut) {
        uint256 exponent;

        exponent = fromDecimals - toDecimals;
        amountOut = amount / 10**exponent;
    }

    function denormalize(
        uint8 fromDecimals,
        uint8 toDecimals,
        uint256 amount
    ) private pure returns (uint256 amountOut) {
        uint256 exponent;

        exponent = toDecimals - fromDecimals;
        amountOut = amount * 10**exponent;
    }

    function adjustAssetDecimals(
        address assetAddress,
        uint8 fromDecimals,
        uint256 amountIn
    ) public view returns (uint256 amount) {
        uint8 receiverIntermediaryDecimals = getDecimals(assetAddress);
        if (fromDecimals > receiverIntermediaryDecimals) {
            amount = normalize(
                fromDecimals,
                receiverIntermediaryDecimals,
                amountIn
            );
        } else {
            amount = denormalize(
                fromDecimals,
                receiverIntermediaryDecimals,
                amountIn
            );
        }
    }

    function swap(IAlpha.SwapArgs calldata args, bytes memory data)
        external
        returns (uint64 swapCoreSequence)
    {
        (
            address senderAddress,
            address destinationAssetAddress,
            uint256 swappingChain,
            uint256 amountIn,
            uint256 amountOutMin,
            string memory symbol,
            uint64 sequence
        ) = getPayload(data);

        address fromAddress = args.getFromAssetAddress();
        address toAddress = args.getToAssetAddress();

        require(isListed[symbol], "BlackBox: sourceAsset Symbol not listed");

        address sourceAssetAddress = mappedSymbol[symbol];

        require(
            fromAddress == sourceAssetAddress,
            "Blackbox: invalid fromAssetAddress"
        );

        require(swappingChain == block.chainid, "BlackBox: Invalid ChainId");

        require(
            amountIn <= totalAmountPerToken[sourceAssetAddress],
            "BlackBox: Insufficient Amount"
        );

        require(args.to == address(this), "BlackBox: Invalid to address");

        require(
            toAddress == destinationAssetAddress,
            "BlackBox: Invalid toAddress"
        );

        sourceAssetAddress.transfer(payable(AlphaAddress), amountIn);
        uint256[] memory amountOuts = IAlpha(AlphaAddress).swap(args);
        uint256 amountOut = amountOuts.sum();

        totalAmountPerToken[sourceAssetAddress] -= amountIn;
        totalAmountPerToken[destinationAssetAddress] += amountOut;

        bytes memory payload = abi.encodePacked(
            bytes32(uint256(uint160(address(senderAddress)))),
            swappingChain,
            amountIn,
            bytes32(uint256(uint160(address(destinationAssetAddress)))),
            amountOut,
            bytes32(bytes(symbol))
        );
        swapCoreSequence = IWormholeCore(coreAddress).publishMessage(
            uint32(block.timestamp % 2**32),
            payload,
            consistencyLevel
        );
    }

    function withdrawFunds(address tokenAddress, uint256 amount)
        external
        onlyOwner
    {
        tokenAddress.withdraw(owner(), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IAlpha {
    struct Amm {
        address id;
        uint16 index;
        uint8 protocolIndex;
    }

    struct Hop {
        uint16 ammIndex;
        uint8[] path;
        bytes poolData;
    }

    struct Route {
        uint256 amountIn;
        Hop[] hops;
    }

    struct SwapArgs {
        Route[] routes;
        address[] assets;
        address payable to;
        uint256 amountOutMin;
        uint256 deadline;
    }

    function updateAmms(Amm[] calldata amms) external;

    function swap(SwapArgs memory swapArgs)
        external
        returns (uint256[] memory amountOuts);

    function updateblackBoxAddress(address _blackBoxAddress) external;

    function withdraw(address weth, uint256 amount) external;

    event AmmsUpdated(Amm[] amms, address caller);
}

/* {"swapArgs":{"routes":[{"amountIn":154907000000000000000,"hops":[{"ammIndex":0,"path":[0],"poolData":"0x"}]}],"assets":["0x55d398326f99059ff775485246999027b3197955"],"to":"0x8633be9e9a5c7c39e9dc9d7ffef0979ce1026e71","amountOutMin":153357930000000000000,"deadline":16745916030},"bridgeArgs":{"encodedVmBridge":"0x","encodedVmCore":"0x01000000030d00a456608c53f96bb9cf0700530de893d513981dd8a0af27da66c967bee0f04c69601f2a5eb1d59e699f1eddb09ba94c3a966eb7ba9e7bd8b243e8218cab0fdc5400021d9a4b98f4d56c3113529203e56a67c22327079541de8df6cc12cf6a61129b9e09b73430af85eff64e9d77b27cb30be6f92a11873826e638a40559ce4235201e0103bd9bd96a07f89429a452bbe7a69a579991d74516c7132f08d10870dda7038d153ddebcf6dc7870956b1288be7719e5f6f02a3f02bd6d2a87175bf6b0857990df0004e592524632145d304dd566a7bf7cd75ad7c9c02d22b6581052284c42f71918c3419c7a09457370e4bdce6ca6e6a1d6e104f0c192b12a4283f01334b4d26fc7bc01050d953f39344f2c26f45f4870e50c63e5ba697f45376f3867c6e68944344bda0829d735e0458244445fce3c343644fd3e631887ea29580feaf5753ed3b7304b1f010623f0bf1682a7c0e256e11534a3e1013c28449b528ee6d59d900effc90e1e878f3b85065925185e0b0fe893fd69e715c5db5b4b4aad53fa039b2adebb06296d3901084718f3386702a3d21f497362612b75030fc769bf3c1ef0066b2c5430c0b276fa781ea266953b1861edc624c21cec288b2ec8bdcda44e842b21ebc44885e10788000a74fb4f95e41f8d4ae383f301d8d58a79a497de69271f8d33e0eb9eb359bab14404905d15b5042c31cbf1ce1968640f4fa54c3575563952d2fdeb7ce859a497db010be6945018e5b554d4d35883aeb4bc62b17afdd8b6f12d9b9794c9ed43911f23ca526930c411245f39c3851bf7d978be42bc2a63ee53f7c370813ecd57c9108b48000d3c1c234ff44882110147ba16f16491b9e6fcd234b8adb4355dd66f450899be6c65bd1e02632f33a170f84fe03091b0d33439320810c08b656a3524784407d829000e3a2e2c0453c35951e27df14ce6a4f31c2fe6f3c7e430a1e0764cefccb090056e2e41d6644235fd7a5ff1cc0e10b049aab17d535203826cd70115c4f3b2b11ca900111f2316733c2f3ef94d93a03188db0cb41f547ad2ef4efc98970cf04b3a7eaa2f183f960b49d782212b7892ef2b01f9ca74df2d257bd4d37bcdd341604d11cccc0112090ca3a4d330d0f54267e8c25f23e417c1657e3344a3666580da48f84111f1775fee167f5237cf79cbcb892be02563f31f5eb8109896954fc6bfc89c0312410b006389fcfa6389fcfa000500000000000000000000000063235f7c32c5d68311c6624013b52295aa75ecfa000000000000018f0500000000000000000000000055d398326f99059ff775485246999027b319795500000000000000000000000055d398326f99059ff775485246999027b31979550000000000000000000000008633be9e9a5c7c39e9dc9d7ffef0979ce1026e71000000000000000000000000b08f1e48933ad072155086a50318b9517cd8858600000000000000000000000063235f7c32c5d68311c6624013b52295aa75ecfa000000000000000000000000000000000000000000000008192ee52e48011dea0000000000000000000000000000000000000000000000000c171db6b6c9c21600000000000000000000000000000000000000000000000000000000093d1cc0000000000000000006020301","senderStargateBridgeAddress":"0x9d1b1669c73b033dfe47ae5a0164ab96df25b9446694340fc020c5e6b96567843da2df01b2ce1eb6","nonce":7051,"senderStargateChainId":109}} */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IPhoenix {
    function listedToken(address tokenAddress) external view returns (bool);
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

interface IWeth {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IWormholeCore {
    function publishMessage(
        uint32 nonce,
        bytes memory payload,
        uint8 consistencyLevel
    ) external payable returns (uint64 sequence);

    function parseAndVerifyVM(bytes calldata encodedVM)
        external
        view
        returns (
            IWormholeCore.VM memory vm,
            bool valid,
            string memory reason
        );

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 guardianIndex;
    }

    struct VM {
        uint8 version;
        uint32 timestamp;
        uint32 nonce;
        uint16 emitterChainId;
        bytes32 emitterAddress;
        uint64 sequence;
        uint8 consistencyLevel;
        bytes payload;
        uint32 guardianSetIndex;
        Signature[] signatures;
        bytes32 hash;
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IWeth.sol";

error AssetNotReceived();
error TransferFromFailed();
error TransferFailed();
error ApprovalFailed();

library LibAsset {
    using LibAsset for address;

    address constant NATIVE_ASSETID = address(0);

    function isNative(address self) internal pure returns (bool) {
        return self == NATIVE_ASSETID;
    }

    function getBalance(address self) internal view returns (uint256) {
        return
            self.isNative()
                ? address(this).balance
                : IERC20(self).balanceOf(address(this));
    }

    function transferFrom(
        address self,
        address from,
        address to,
        uint256 amount
    ) internal {
        IERC20 token = IERC20(self);
        bytes4 selector = token.transferFrom.selector;
        bool isSuccessful;
        assembly {
            let data := mload(0x40)

            mstore(data, selector)
            mstore(add(data, 0x04), from)
            mstore(add(data, 0x24), to)
            mstore(add(data, 0x44), amount)
            isSuccessful := call(gas(), token, 0, data, 100, 0x0, 0x20)
            if isSuccessful {
                switch returndatasize()
                case 0 {
                    isSuccessful := gt(extcodesize(token), 0)
                }
                default {
                    isSuccessful := and(
                        gt(returndatasize(), 31),
                        eq(mload(0), 1)
                    )
                }
            }
        }
        if (!isSuccessful) {
            revert TransferFromFailed();
        }
    }

    function transfer(
        address self,
        address payable recipient,
        uint256 amount
    ) internal {
        bool isSuccessful;
        if (self.isNative()) {
            (isSuccessful, ) = recipient.call{value: amount}("");
        } else {
            IERC20 token = IERC20(self);
            bytes4 selector = token.transfer.selector;
            assembly {
                let data := mload(0x40)

                mstore(data, selector)
                mstore(add(data, 0x04), recipient)
                mstore(add(data, 0x24), amount)
                isSuccessful := call(gas(), token, 0, data, 0x44, 0x0, 0x20)
                if isSuccessful {
                    switch returndatasize()
                    case 0 {
                        isSuccessful := gt(extcodesize(token), 0)
                    }
                    default {
                        isSuccessful := and(
                            gt(returndatasize(), 31),
                            eq(mload(0), 1)
                        )
                    }
                }
            }
        }

        if (!isSuccessful) {
            revert TransferFailed();
        }
    }

    function approve(
        address self,
        address spender,
        uint256 amount
    ) internal {
        bool isSuccessful = IERC20(self).approve(spender, amount);
        if (!isSuccessful) {
            revert ApprovalFailed();
        }
    }

    function getAllowance(
        address self,
        address owner,
        address spender
    ) internal view returns (uint256) {
        return IERC20(self).allowance(owner, spender);
    }

    function deposit(address self, uint256 amount) internal {
        self.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(
        address self,
        address to,
        uint256 amount
    ) internal {
        self.transfer(payable(to), amount);
    }

    function getDecimals(address self)
        internal
        view
        returns (uint8 tokenDecimals)
    {
        tokenDecimals = 18;

        if (!self.isNative()) {
            (, bytes memory queriedDecimals) = self.staticcall(
                abi.encodeWithSignature("decimals()")
            );
            tokenDecimals = abi.decode(queriedDecimals, (uint8));
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library LibBytes {
    using LibBytes for bytes;

    function toAddress(bytes memory self, uint256 start)
        internal
        pure
        returns (address)
    {
        return address(uint160(uint256(self.toBytes32(start))));
    }

    function toBool(bytes memory self, uint256 start)
        internal
        pure
        returns (bool)
    {
        return self.toUint8(start) == 1 ? true : false;
    }

    function toUint8(bytes memory self, uint256 start)
        internal
        pure
        returns (uint8)
    {
        require(self.length >= start + 1, "LibBytes: toUint8 outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x1), start))
        }

        return tempUint;
    }

    function toUint16(bytes memory self, uint256 start)
        internal
        pure
        returns (uint16)
    {
        require(self.length >= start + 2, "LibBytes: toUint16 outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x2), start))
        }

        return tempUint;
    }

    function toUint24(bytes memory self, uint256 start)
        internal
        pure
        returns (uint24)
    {
        require(self.length >= start + 3, "LibBytes: toUint24 outOfBounds");
        uint24 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x3), start))
        }

        return tempUint;
    }

    function toUint64(bytes memory self, uint256 start)
        internal
        pure
        returns (uint64)
    {
        require(self.length >= start + 8, "LibBytes: toUint64 outOfBounds");
        uint64 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x8), start))
        }

        return tempUint;
    }

    function toUint256(bytes memory self, uint256 start)
        internal
        pure
        returns (uint256)
    {
        require(self.length >= start + 32, "LibBytes: toUint256 outOfBounds");
        uint256 tempUint;

        assembly {
            tempUint := mload(add(add(self, 0x20), start))
        }

        return tempUint;
    }

    function toBytes32(bytes memory self, uint256 start)
        internal
        pure
        returns (bytes32)
    {
        require(self.length >= start + 32, "LibBytes: toBytes32 outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(self, 0x20), start))
        }

        return tempBytes32;
    }

    function toString(bytes memory self, uint256 start)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encode(self.toBytes32(start)));
    }

    function parseDepositInfo(bytes memory self)
        internal
        pure
        returns (
            address senderAddress,
            uint256 chainId,
            uint256 amount,
            string memory symbol
        )
    {
        uint256 i = 0;

        senderAddress = self.toAddress(i);
        i += 32;
        chainId = self.toUint256(i);
        i += 32;
        amount = self.toUint256(i);
        i += 32;
        symbol = self.toString(i);
        i += 32;
    }

    function parseSwapInfo(bytes memory self)
        internal
        pure
        returns (
            address senderAddress,
            address destinationAssetAddress,
            uint256 swappingChain,
            uint256 amountIn,
            uint256 amountOutMin,
            string memory symbol
        )
    {
        uint256 i = 0;

        senderAddress = self.toAddress(i);
        i += 32;

        destinationAssetAddress = self.toAddress(i);
        i += 32;

        swappingChain = self.toUint256(i);
        i += 32;

        amountIn = self.toUint256(i);
        i += 32;

        amountOutMin = self.toUint256(i);
        i += 32;

        symbol = self.toString(i);
        i += 32;
    }

    function parseSwappedInfo(bytes memory self)
        internal
        pure
        returns (
            address senderAddress,
            uint256 swappingChain,
            uint256 amountIn,
            address destinationAssetAddress,
            uint256 amountOut,
            string memory symbol
        )
    {
        uint256 i = 0;
        senderAddress = self.toAddress(i);
        i += 32;
        swappingChain = self.toUint256(i);
        i += 32;
        amountIn = self.toUint256(i);
        i += 32;
        destinationAssetAddress = self.toAddress(i);
        i += 32;
        amountOut = self.toUint256(i);
        i += 32;
        symbol = self.toString(i);
        i += 32;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../interfaces/IAlpha.sol";
import "../interfaces/IWeth.sol";
import "./LibAsset.sol";

library LibSwap {
    using LibAsset for address;
    using LibSwap for IAlpha.SwapArgs;

    function getFromAssetAddress(IAlpha.SwapArgs memory self)
        internal
        pure
        returns (address)
    {
        return self.assets[self.routes[0].hops[0].path[0]];
    }

    function getToAssetAddress(IAlpha.SwapArgs memory self)
        internal
        pure
        returns (address)
    {
        IAlpha.Hop memory hop = self.routes[0].hops[
            self.routes[0].hops.length - 1
        ];
        return self.assets[hop.path[hop.path.length - 1]];
    }

    function getAmountIn(IAlpha.SwapArgs memory self)
        internal
        pure
        returns (uint256)
    {
        uint256 amountIn = 0;

        for (uint256 i = 0; i < self.routes.length; i++) {
            amountIn += self.routes[i].amountIn;
        }

        return amountIn;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library LibUint256Array {
    function sum(uint256[] memory self) internal pure returns (uint256) {
        uint256 amountOut = 0;

        for (uint256 i = 0; i < self.length; i++) {
            amountOut += self[i];
        }

        return amountOut;
    }
}