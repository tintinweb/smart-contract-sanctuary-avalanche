// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./HelperOwnable.sol";
import "./storage/LibHelperFeatureStorage.sol";


contract AggTraderHelper is HelperOwnable {

    event FeatureFunctionUpdated(bytes4 indexed selector, address oldFeature, address newFeature);

    function registerFeature(address feature, bytes4[] calldata methodIDs) external onlyOwner {
        unchecked {
            LibHelperFeatureStorage.Storage storage stor = LibHelperFeatureStorage.getStorage();
            for (uint256 i = 0; i < methodIDs.length; ++i) {
                bytes4 selector = methodIDs[i];
                address oldFeature = stor.impls[selector];
                stor.impls[selector] = feature;
                emit FeatureFunctionUpdated(selector, oldFeature, feature);
            }
        }
    }

    function registerFeatures(address[] calldata features, bytes4[][] calldata methodIDs) external onlyOwner {
        require(features.length == methodIDs.length, "registerFeatures: mismatched inputs.");
        unchecked {
            LibHelperFeatureStorage.Storage storage stor = LibHelperFeatureStorage.getStorage();
            for (uint256 i = 0; i < methodIDs.length; ++i) {
                // register feature
                address feature = features[i];
                bytes4[] calldata featureMethodIDs = methodIDs[i];
                for (uint256 j = 0; j < featureMethodIDs.length; ++j) {
                    bytes4 selector = featureMethodIDs[j];
                    address oldFeature = stor.impls[selector];
                    stor.impls[selector] = feature;
                    emit FeatureFunctionUpdated(selector, oldFeature, feature);
                }
            }
        }
    }

    function getFeature(bytes4 methodID) external view returns (address feature) {
        return LibHelperFeatureStorage.getStorage().impls[methodID];
    }

    /// @dev Fallback for just receiving ether.
    receive() external payable {}

    /// @dev Forwards calls to the appropriate implementation contract.
    fallback() external payable {
        bytes memory data = msg.data;
        bytes4 selector;
        assembly {
            selector := mload(add(data, 32))
            // Solidity does not require us to clean the trailing bytes.
            // We do it anyway
            selector := and(selector, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }

        address feature = LibHelperFeatureStorage.getStorage().impls[selector];
        require(feature != address(0), "Not implemented method.");

        (bool success, ) = feature.delegatecall(data);
        if (success) {
            assembly {
                returndatacopy(0, 0, returndatasize())
                return(0, returndatasize())
            }
        } else {
            assembly {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function rescueETH(address recipient) external onlyOwner {
        if (address(this).balance > 0) {
            (bool success,) = payable(recipient).call{value: address(this).balance}("");
            require(success, "_transferEth/TRANSFER_FAILED");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./storage/LibHelperFeatureStorage.sol";


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
abstract contract HelperOwnable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        if (owner() == address(0)) {
            _transferOwnership(msg.sender);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return LibHelperFeatureStorage.getStorage().owner;
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) private {
        LibHelperFeatureStorage.Storage storage stor = LibHelperFeatureStorage.getStorage();
        address oldOwner = stor.owner;
        stor.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./LibHelperStorage.sol";


library LibHelperFeatureStorage {

    struct Storage {
        address owner;
        // Mapping of function selector -> function implementation
        mapping(bytes4 => address) impls;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        // uint256 storageSlot = LibStorage.STORAGE_ID_FEATURE;
        assembly { stor.slot := 0 }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library LibHelperStorage {
    uint256 constant STORAGE_ID_FEATURE = 0 << 128;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../libs/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


contract RescueFeature is Ownable {

    function rescueERC1155(IERC1155 asset, uint256 id, uint256 amount, address recipient) external onlyOwner {
        if (recipient != address(0)) {
            asset.safeTransferFrom(address(this), recipient, id, amount, "");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../storage/LibOwnableStorage.sol";


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
abstract contract Ownable {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        if (owner() == address(0)) {
            _transferOwnership(msg.sender);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return LibOwnableStorage.getStorage().owner;
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) private {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        address oldOwner = stor.owner;
        stor.owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library LibOwnableStorage {

    uint256 constant STORAGE_ID_OWNABLE = 2 << 128;

    struct Storage {
        uint256 reentrancyStatus;
        address owner;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_OWNABLE }
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../../libs/FixinTokenSpender.sol";
import "../../libs/FixinERC721Spender.sol";
import "../../storage/LibAggregatorStorage.sol";
import "../../storage/LibMultiAssetSwapStorage.sol";
import "../../libs/Ownable.sol";
import "../../libs/ReentrancyGuard.sol";
import "./punk/IPunk.sol";
import "./punk/IPunkWrapper.sol";
import "./mooncat/IMoonCatRescue.sol";


contract MultiAssetFeature is Ownable, ReentrancyGuard, FixinTokenSpender, FixinERC721Spender {

//    struct ERC721Details {
//        address token;
//        address[] to;
//        uint256[] ids;
//    }
//
//    struct ERC1155Details {
//        address token;
//        uint256[] ids;
//        uint256[] amounts;
//    }
//
//    modifier isOpenForTrades() {
//        require(LibMultiAssetSwapStorage.getStorage().openForTrades, "trades not allowed");
//        _;
//    }
//
//    function setOpenForTrades(bool openForTrades) external onlyOwner {
//        LibMultiAssetSwapStorage.getStorage().openForTrades = openForTrades;
//    }
//
//    function getOpenForTrades() external view returns (bool) {
//        return LibMultiAssetSwapStorage.getStorage().openForTrades;
//    }
//
//    function getPunkProxy() external view returns (address) {
//        return LibMultiAssetSwapStorage.getStorage().punkProxy;
//    }
//
//    function setUp() external onlyOwner {
//        // Create CryptoPunk Proxy
//        IPunkWrapper(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).registerProxy();
//        LibMultiAssetSwapStorage.getStorage().punkProxy = IPunkWrapper(0xb7F7F6C52F2e2fdb1963Eab30438024864c313F6).proxyInfo(address(this));
//
//        // approve wrapped mooncat rescue to Acclimated​MoonCats contract
//        IERC721(0x7C40c393DC0f283F318791d746d894DdD3693572).setApprovalForAll(0xc3f733ca98E0daD0386979Eb96fb1722A1A05E69, true);
//    }
//
//    // swaps any combination of ERC-20/721/1155
//    // User needs to approve assets before invoking swap
//    // WARNING: DO NOT SEND TOKENS TO THIS FUNCTION DIRECTLY!!!
//    function multiAssetSwap(
//        Structs.ERC20Pair[] calldata erc20Pairs,
//        ERC721Details[] calldata erc721Details,
//        ERC1155Details[] calldata erc1155Details,
//        Structs.ConversionDetails[] calldata conversionDetails,
//        Structs.TradeDetails[] calldata tradeDetails,
//        address[] calldata dustTokens
//    ) payable external isOpenForTrades nonReentrant {
//        // transfer all tokens
//        _transferFromHelper(
//            erc20Pairs,
//            erc721Details,
//            erc1155Details
//        );
//
//        // Convert any assets if needed
//        _convertAssets(conversionDetails);
//
//        // execute trades
//        _trade(tradeDetails);
//
//        // return remaining ETH (if any)
//        assembly {
//            if gt(selfbalance(), 0) {
//                let success := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
//            }
//        }
//        // return remaining tokens (if any)
//        unchecked {
//            for (uint256 i = 0; i < dustTokens.length; ++i) {
//                uint256 balance = IERC20(dustTokens[i]).balanceOf(address(this));
//                if (balance > 0) {
//                    _transferERC20TokensWithoutCheckResult(dustTokens[i], msg.sender, balance);
//                }
//            }
//        }
//    }
//
//    function _transferFromHelper(
//        Structs.ERC20Pair[] calldata erc20Pairs,
//        ERC721Details[] calldata erc721Details,
//        ERC1155Details[] calldata erc1155Details
//    ) internal {
//        unchecked {
//            address msgSender = msg.sender;
//
//            // transfer ERC20 tokens from the sender to this contract
//            for (uint256 i = 0; i < erc20Pairs.length; ++i) {
//                _transferERC20TokensFromWithoutCheckResult(erc20Pairs[i].token, msgSender, address(this), erc20Pairs[i].amount);
//            }
//
//            // transfer ERC721 tokens from the sender to this contract
//            for (uint256 i = 0; i < erc721Details.length; ++i) {
//                if (erc721Details[i].token == 0xb47e3cd837dDF8e4c57F05d70Ab865de6e193BBB) { // accept Cryptopunk
//                    _acceptCryptoPunk(erc721Details[i]);
//                } else if (erc721Details[i].token == 0x60cd862c9C687A9dE49aecdC3A99b74A4fc54aB6) { // accept Mooncat
//                    _acceptMoonCat(erc721Details[i]);
//                } else {
//                    for (uint256 j = 0; j < erc721Details[i].ids.length; ++j) {
//                        _transferERC721AssetFrom(erc721Details[i].token, msgSender, address(this), erc721Details[i].ids[j]);
//                    }
//                }
//            }
//
//            // transfer ERC1155 tokens from the sender to this contract
//            for (uint256 i = 0; i < erc1155Details.length; ++i) {
//                IERC1155(erc1155Details[i].token).safeBatchTransferFrom(
//                    msgSender,
//                    address(this),
//                    erc1155Details[i].ids,
//                    erc1155Details[i].amounts,
//                    ""
//                );
//            }
//        }
//    }
//
//    function _convertAssets(Structs.ConversionDetails[] calldata conversions) internal {
//        if (conversions.length > 0) {
//            address converter = LibAggregatorStorage.getStorage().converter;
//            require(converter != address(0), "Converter is not set.");
//
//            for (uint256 i = 0; i < conversions.length; ) {
//                (bool success, ) = converter.delegatecall(conversions[i].conversionData);
//                if (!success) {
//                    assembly {
//                        returndatacopy(0, 0, returndatasize())
//                        revert(0, returndatasize())
//                    }
//                }
//                unchecked { ++i; }
//            }
//        }
//    }
//
//    function _trade(Structs.TradeDetails[] calldata tradeDetails) internal {
//        unchecked {
//            LibAggregatorStorage.Storage storage stor = LibAggregatorStorage.getStorage();
//            for (uint256 i = 0; i < tradeDetails.length; ++i) {
//                Structs.TradeDetails calldata item = tradeDetails[i];
//                // get market details
//                Structs.Market memory market = stor.markets[item.marketId];
//
//                // market should be active
//                require(market.isActive, "_trade: market inactive");
//
//                // execute trade
//                (bool success, ) = market.isLibrary ?
//                    market.proxy.delegatecall(item.tradeData) :
//                    market.proxy.call{value: item.value}(item.tradeData);
//            }
//        }
//    }
//
//    function _revertCallResult() internal pure {
//        // Copy revert reason from call
//        assembly {
//            returndatacopy(0, 0, returndatasize())
//            revert(0, returndatasize())
//        }
//    }
//
//    function _acceptMoonCat(ERC721Details calldata erc721Details) internal {
//        unchecked {
//            for (uint256 i = 0; i < erc721Details.ids.length; ++i) {
//                bytes5 catId = _toBytes5(erc721Details.ids[i]);
//                address owner = IMoonCatRescue(erc721Details.token).catOwners(catId);
//                require(owner == msg.sender, "_acceptMoonCat: invalid mooncat owner");
//                IMoonCatRescue(erc721Details.token).acceptAdoptionOffer(catId);
//            }
//        }
//    }
//
//    function _transferMoonCat(ERC721Details calldata erc721Details) internal {
//        unchecked {
//            for (uint256 i = 0; i < erc721Details.ids.length; ++i) {
//                IMoonCatRescue(erc721Details.token).giveCat(_toBytes5(erc721Details.ids[i]), erc721Details.to[i]);
//            }
//        }
//    }
//
//    function _acceptCryptoPunk(ERC721Details calldata erc721Details) internal {
//        unchecked {
//            for (uint256 i = 0; i < erc721Details.ids.length; ++i) {
//                address owner = IPunk(erc721Details.token).punkIndexToAddress(erc721Details.ids[i]);
//                require(owner == msg.sender, "_acceptCryptoPunk: invalid punk owner");
//                IPunk(erc721Details.token).buyPunk(erc721Details.ids[i]);
//            }
//        }
//    }
//
//    function _transferCryptoPunk(ERC721Details calldata erc721Details) internal {
//        unchecked {
//            for (uint256 i = 0; i < erc721Details.ids.length; ++i) {
//                IPunk(erc721Details.token).transferPunk(erc721Details.to[i], erc721Details.ids[i]);
//            }
//        }
//    }
//
//    function _toBytes5(uint256 id) internal pure returns (bytes5 slicedDataBytes5) {
//        bytes memory _bytes = new bytes(32);
//        assembly {
//            mstore(add(_bytes, 32), id)
//        }
//
//        bytes memory tempBytes;
//        assembly {
//            // Get a location of some free memory and store it in tempBytes as
//            // Solidity does for memory variables.
//            tempBytes := mload(0x40)
//
//            // The first word of the slice result is potentially a partial
//            // word read from the original array. To read it, we calculate
//            // the length of that partial word and start copying that many
//            // bytes into the array. The first word we copy will start with
//            // data we don't care about, but the last `lengthmod` bytes will
//            // land at the beginning of the contents of the new array. When
//            // we're done copying, we overwrite the full first word with
//            // the actual length of the slice.
//            let lengthmod := and(5, 31)
//
//            // The multiplication in the next line is necessary
//            // because when slicing multiples of 32 bytes (lengthmod == 0)
//            // the following copy loop was copying the origin's length
//            // and then ending prematurely not copying everything it should.
//            let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
//            let end := add(mc, 5)
//
//            for {
//                // The multiplication in the next line has the same exact purpose
//                // as the one above.
//                let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), 27)
//            } lt(mc, end) {
//                mc := add(mc, 0x20)
//                cc := add(cc, 0x20)
//            } {
//                mstore(mc, mload(cc))
//            }
//
//            mstore(tempBytes, 5)
//
//            // update free-memory pointer
//            // allocating the array padded to 32 bytes like the compiler does now
//            mstore(0x40, and(add(mc, 31), not(31)))
//        }
//
//        assembly {
//            slicedDataBytes5 := mload(add(tempBytes, 32))
//        }
//    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


/// @dev Helpers for moving tokens around.
abstract contract FixinTokenSpender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = (1 << 160) - 1;

    /// @dev Transfers ERC20 tokens from `owner` to `to`.
    /// @param token The token to spend.
    /// @param owner The owner of the tokens.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20From(address token, address owner, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }

    /// @dev Transfers ERC20 tokens from ourselves to `to`.
    /// @param token The token to spend.
    /// @param to The recipient of the tokens.
    /// @param amount The amount of `token` to transfer.
    function _transferERC20(address token, address to, uint256 amount) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transfer(address,uint256)
            mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x24), amount)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x44, ptr, 32)

            let rdsize := returndatasize()

            // Check for ERC20 success. ERC20 tokens should return a boolean,
            // but some don't. We accept 0-length return data as success, or at
            // least 32 bytes that starts with a 32-byte boolean true.
            success := and(
                success,                             // call itself succeeded
                or(
                    iszero(rdsize),                  // no return data, or
                    and(
                        iszero(lt(rdsize, 32)),      // at least 32 bytes
                        eq(mload(ptr), 1)            // starts with uint256(1)
                    )
                )
            )
        }
        require(success != 0, "_transferERC20/TRANSFER_FAILED");
    }

    function _transferERC20FromWithoutCheck(address token, address owner, address to, uint256 amount) internal {
        assembly {
            if gt(amount, 0) {
                let ptr := mload(0x40) // free memory pointer

                // selector for transferFrom(address,address,uint256)
                mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
                mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
                mstore(add(ptr, 0x44), amount)

                let success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, 0, 0)
            }
        }
    }

    function _transferERC20WithoutCheck(address token, address to, uint256 amount) internal {
        assembly {
            if gt(amount, 0) {
                let ptr := mload(0x40) // free memory pointer

                // selector for transfer(address,uint256)
                mstore(ptr, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), and(to, ADDRESS_MASK))
                mstore(add(ptr, 0x24), amount)

                let success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x44, 0, 0)
            }
        }
    }

    /// @dev Transfers some amount of ETH to the given recipient and
    ///      reverts if the transfer fails.
    /// @param recipient The recipient of the ETH.
    /// @param amount The amount of ETH to transfer.
    function _transferEth(address recipient, uint256 amount) internal {
        assembly {
            if gt(amount, 0) {
                if iszero(call(gas(), recipient, amount, 0, 0, 0, 0)) {
                    // revert("_transferEth/TRANSFER_FAILED")
                    mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                    mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                    mstore(0x40, 0x0000001c5f7472616e736665724574682f5452414e534645525f4641494c4544)
                    mstore(0x60, 0)
                    revert(0, 0x64)
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


/// @dev Helpers for moving ERC721 assets around.
abstract contract FixinERC721Spender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = (1 << 160) - 1;

    /// @dev Transfer an ERC721 asset from `owner` to `to`.
    /// @param token The address of the ERC721 token contract.
    /// @param owner The owner of the asset.
    /// @param to The recipient of the asset.
    /// @param tokenId The token ID of the asset to transfer.
    function _transferERC721AssetFrom(address token, address owner, address to, uint256 tokenId) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for transferFrom(address,address,uint256)
            mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), tokenId)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, 0, 0)
        }
        require(success != 0, "_transferERC721/TRANSFER_FAILED");
    }

    /// @dev Safe transfer an ERC721 asset from `owner` to `to`.
    /// @param token The address of the ERC721 token contract.
    /// @param owner The owner of the asset.
    /// @param to The recipient of the asset.
    /// @param tokenId The token ID of the asset to transfer.
    function _safeTransferERC721AssetFrom(address token, address owner, address to, uint256 tokenId) internal {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for safeTransferFrom(address,address,uint256)
            mstore(ptr, 0x42842e0e00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), tokenId)

            success := call(gas(), and(token, ADDRESS_MASK), 0, ptr, 0x64, 0, 0)
        }
        require(success != 0, "_safeTransferERC721/TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library LibAggregatorStorage {

    uint256 constant STORAGE_ID_AGGREGATOR = 0;

    struct Market {
        address proxy;
        bool isLibrary;
        bool isActive;
    }

    struct Storage {
        Market[] markets;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        assembly { stor.slot := STORAGE_ID_AGGREGATOR }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library LibMultiAssetSwapStorage {

    uint256 constant STORAGE_ID_MULTI_ASSET_SWAP = 3 << 128;

    struct Storage {
        address punkProxy;
        bool openForTrades;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor.slot := STORAGE_ID_MULTI_ASSET_SWAP }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../storage/LibOwnableStorage.sol";


abstract contract ReentrancyGuard {

    constructor() {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        if (stor.reentrancyStatus == 0) {
            stor.reentrancyStatus = 1;
        }
    }

    modifier nonReentrant() {
        LibOwnableStorage.Storage storage stor = LibOwnableStorage.getStorage();
        require(stor.reentrancyStatus == 1, "ReentrancyGuard: reentrant call");
        stor.reentrancyStatus = 2;
        _;
        stor.reentrancyStatus = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IPunk {
    function punkIndexToAddress(uint index) external view returns(address owner);
    function offerPunkForSaleToAddress(uint punkIndex, uint minSalePriceInWei, address toAddress) external;
    function buyPunk(uint punkIndex) external payable;
    function transferPunk(address to, uint punkIndex) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IPunkWrapper {
    /**
     * @dev Mints a wrapped punk
     */
    function mint(uint256 punkIndex) external;

    /**
     * @dev Burns a specific wrapped punk
     */
    function burn(uint256 punkIndex) external;

    /**
     * @dev Registers proxy
     */
    function registerProxy() external;

    /**
     * @dev Gets proxy address
     */
    function proxyInfo(address user) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IMoonCatRescue {
    function acceptAdoptionOffer(bytes5 catId) payable external;
    function makeAdoptionOfferToAddress(bytes5 catId, uint price, address to) external;
    function giveCat(bytes5 catId, address to) external;
    function catOwners(bytes5 catId) external view returns(address);
    function rescueOrder(uint256 rescueIndex) external view returns(bytes5 catId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../storage/LibAggregatorStorage.sol";
import "../../storage/LibFeatureStorage.sol";
import "../../storage/LibOwnableStorage.sol";


contract MasterFeature {

    struct Method {
        bytes4 methodID;
        string methodName;
    }

    struct Feature {
        address feature;
        string name;
        Method[] methods;
    }

    modifier onlyOwner() {
        require(LibOwnableStorage.getStorage().owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function getMethodIDs() external view returns (uint256 count, bytes4[] memory methodIDs) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        return (stor.methodIDs.length, stor.methodIDs);
    }

    function getFeatureImpl(bytes4 methodID) external view returns (address impl) {
        return LibFeatureStorage.getStorage().featureImpls[methodID];
    }

    function getFeature(address featureAddr) public view returns (Feature memory feature) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();

        // Calculate feature.methods.length
        uint256 methodsLength = 0;
        for (uint256 i = 0; i < stor.methodIDs.length; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            if (featureAddr == stor.featureImpls[methodID]) {
                ++methodsLength;
            }
        }

        // Set methodIs
        uint256 j = 0;
        Method[] memory methods = new Method[](methodsLength);
        for (uint256 i = 0; i < stor.methodIDs.length && j < methodsLength; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            if (featureAddr == stor.featureImpls[methodID]) {
                methods[j] = Method(methodID, stor.methodNames[methodID]);
                ++j;
            }
        }

        feature.feature = featureAddr;
        feature.name = stor.featureNames[featureAddr];
        feature.methods = methods;
        return feature;
    }

    function getFeatureByMethodID(bytes4 methodID) external view returns (Feature memory feature) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        address featureAddr = stor.featureImpls[methodID];
        return getFeature(featureAddr);
    }

    function getFeatures() external view returns (
        uint256 featuresCount,
        address[] memory features,
        string[] memory names,
        uint256[] memory featureMethodsCount
    ) {
        LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
        uint256[] memory methodsCount = new uint256[](stor.methodIDs.length);
        address[] memory addrs = new address[](stor.methodIDs.length);

        for (uint256 i = 0; i < stor.methodIDs.length; ++i) {
            bytes4 methodID = stor.methodIDs[i];
            address impl = stor.featureImpls[methodID];

            uint256 j = 0;
            while (j < featuresCount && impl != addrs[j]) {
                ++j;
            }
            if (j == featuresCount) {
                addrs[j] = impl;
                ++featuresCount;
            }

            ++methodsCount[j];
        }

        features = new address[](featuresCount);
        names = new string[](featuresCount);
        featureMethodsCount = new uint256[](featuresCount);
        for (uint256 i = 0; i < featuresCount; ++i) {
            features[i] = addrs[i];
            names[i] = stor.featureNames[addrs[i]];
            featureMethodsCount[i] = methodsCount[i];
        }
        return (featuresCount, features, names, featureMethodsCount);
    }

    function getMarket(uint256 marketId) external view returns (LibAggregatorStorage.Market memory) {
        return LibAggregatorStorage.getStorage().markets[marketId];
    }

    function getMarkets() external view returns (
        uint256 marketsCount,
        address[] memory proxies,
        bool[] memory isLibrary,
        bool[] memory isActive
    ) {
        LibAggregatorStorage.Market[] storage markets = LibAggregatorStorage.getStorage().markets;
        proxies = new address[](markets.length);
        isLibrary = new bool[](markets.length);
        isActive = new bool[](markets.length);
        for (uint256 i = 0; i < markets.length; i++) {
            proxies[i] = markets[i].proxy;
            isLibrary[i] = markets[i].isLibrary;
            isActive[i] = markets[i].isActive;
        }
        return (markets.length, proxies, isLibrary, isActive);
    }

    function addMarket(address proxy, bool isLibrary) external onlyOwner {
        LibAggregatorStorage.getStorage().markets.push(
            LibAggregatorStorage.Market(proxy, isLibrary, true)
        );
    }

    function setMarketProxy(uint256 marketId, address newProxy, bool isLibrary) external onlyOwner {
        LibAggregatorStorage.Market storage market = LibAggregatorStorage.getStorage().markets[marketId];
        market.proxy = newProxy;
        market.isLibrary = isLibrary;
    }

    function setMarketActive(uint256 marketId, bool isActive) external onlyOwner {
        LibAggregatorStorage.Market storage market = LibAggregatorStorage.getStorage().markets[marketId];
        market.isActive = isActive;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


library LibFeatureStorage {

    uint256 constant STORAGE_ID_FEATURE = 1 << 128;

    struct Storage {
        // Mapping of methodID -> feature implementation
        mapping(bytes4 => address) featureImpls;
        // Mapping of feature implementation -> feature name
        mapping(address => string) featureNames;
        // Record methodIDs
        bytes4[] methodIDs;
        // Mapping of methodID -> method name
        mapping(bytes4 => string) methodNames;
    }

    /// @dev Get the storage bucket for this contract.
    function getStorage() internal pure returns (Storage storage stor) {
        // Dip into assembly to change the slot pointed to by the local
        // variable `stor`.
        // See https://solidity.readthedocs.io/en/v0.6.8/assembly.html?highlight=slot#access-to-external-variables-functions-and-libraries
        assembly { stor.slot := STORAGE_ID_FEATURE }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./storage/LibFeatureStorage.sol";
import "./Aggregator.sol";
import "./libs/Ownable.sol";


contract ElementExSwapV2 is Aggregator, Ownable {

    struct Method {
        bytes4 methodID;
        string methodName;
    }

    struct Feature {
        address feature;
        string name;
        Method[] methods;
    }

    event FeatureFunctionUpdated(
        bytes4 indexed methodID,
        address oldFeature,
        address newFeature
    );

    function registerFeatures(Feature[] calldata features) external onlyOwner {
        unchecked {
            for (uint256 i = 0; i < features.length; ++i) {
                registerFeature(features[i]);
            }
        }
    }

    function registerFeature(Feature calldata feature) public onlyOwner {
        unchecked {
            address impl = feature.feature;
            require(impl != address(0), "registerFeature: invalid feature address.");

            LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();
            stor.featureNames[impl] = feature.name;

            Method[] calldata methods = feature.methods;
            for (uint256 i = 0; i < methods.length; ++i) {
                bytes4 methodID = methods[i].methodID;
                address oldFeature = stor.featureImpls[methodID];
                if (oldFeature == address(0)) {
                    stor.methodIDs.push(methodID);
                }
                stor.featureImpls[methodID] = impl;
                stor.methodNames[methodID] = methods[i].methodName;
                emit FeatureFunctionUpdated(methodID, oldFeature, impl);
            }
        }
    }

    function unregister(bytes4[] calldata methodIDs) external onlyOwner {
        unchecked {
            uint256 removedFeatureCount;
            LibFeatureStorage.Storage storage stor = LibFeatureStorage.getStorage();

            // Update storage.featureImpls
            for (uint256 i = 0; i < methodIDs.length; ++i) {
                bytes4 methodID = methodIDs[i];
                address impl = stor.featureImpls[methodID];
                if (impl != address(0)) {
                    removedFeatureCount++;
                    stor.featureImpls[methodID] = address(0);
                }
                emit FeatureFunctionUpdated(methodID, impl, address(0));
            }
            if (removedFeatureCount == 0) {
                return;
            }

            // Remove methodIDs from storage.methodIDs
            bytes4[] storage storMethodIDs = stor.methodIDs;
            for (uint256 i = storMethodIDs.length; i > 0; --i) {
                bytes4 methodID = storMethodIDs[i - 1];
                if (stor.featureImpls[methodID] == address(0)) {
                    if (i != storMethodIDs.length) {
                        storMethodIDs[i - 1] = storMethodIDs[storMethodIDs.length - 1];
                    }
                    delete storMethodIDs[storMethodIDs.length - 1];
                    storMethodIDs.pop();

                    if (removedFeatureCount == 1) { // Finished
                        return;
                    }
                    --removedFeatureCount;
                }
            }
        }
    }

    /// @dev Fallback for just receiving ether.
    receive() external payable {}

    /// @dev Forwards calls to the appropriate implementation contract.
    uint256 private constant STORAGE_ID_FEATURE = 1 << 128;
    fallback() external payable {
        assembly {
            // Copy methodID to memory 0x00~0x04
            calldatacopy(0, 0, 4)

            // Store LibFeatureStorage.slot to memory 0x20~0x3F
            mstore(0x20, STORAGE_ID_FEATURE)

            // Calculate impl.slot and load impl from storage
            let impl := sload(keccak256(0, 0x40))
            if iszero(impl) {
                // revert("Not implemented method.")
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(0x40, 0x000000174e6f7420696d706c656d656e746564206d6574686f642e0000000000)
                mstore(0x60, 0)
                revert(0, 0x64)
            }

            calldatacopy(0, 0, calldatasize())
            if iszero(delegatecall(gas(), impl, 0, calldatasize(), 0, 0)) {
                // Failed, copy the returned data and revert.
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // Success, copy the returned data and return.
            returndatacopy(0, 0, returndatasize())
            return(0, returndatasize())
        }
    }

    function approveERC20(IERC20 token, address operator, uint256 amount) external onlyOwner {
        token.approve(operator, amount);
    }

    function rescueETH(address recipient) external onlyOwner {
        address to = (recipient != address(0)) ? recipient : msg.sender;
        _transferEth(to, address(this).balance);
    }

    function rescueERC20(address asset, address recipient) external onlyOwner {
        address to = (recipient != address(0)) ? recipient : msg.sender;
        _transferERC20(asset, to, IERC20(asset).balanceOf(address(this)));
    }

    function rescueERC721(address asset, uint256[] calldata ids , address recipient) external onlyOwner {
        assembly {
            // selector for transferFrom(address,address,uint256)
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())

            switch recipient
            case 0 { mstore(0x24, caller()) }
            default { mstore(0x24, recipient) }

            for { let offset := ids.offset } lt(offset, calldatasize()) { offset := add(offset, 0x20) } {
                // tokenID
                mstore(0x44, calldataload(offset))
                if iszero(call(gas(), asset, 0, 0, 0x64, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    function onERC1155Received(address, address, uint256, uint256, bytes calldata) external virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] calldata, uint256[] calldata, bytes calldata) external virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC721Received(address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }

    function supportsInterface(bytes4 interfaceId) external virtual returns (bool) {
        return interfaceId == this.supportsInterface.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IAggregator.sol";
import "./libs/FixinTokenSpender.sol";
import "./libs/ReentrancyGuard.sol";


abstract contract Aggregator is IAggregator, ReentrancyGuard, FixinTokenSpender {

    uint256 private constant SEAPORT_MARKET_ID = 1;
    address private constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;

    uint256 private constant ELEMENT_MARKET_ID = 2;
    address private constant ELEMENT = 0x20F780A973856B93f63670377900C1d2a50a77c4;

    uint256 private constant WETH_MARKET_ID = 999;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    // markets.slot == 0
    // markets.data.slot == keccak256(markets.slot) == 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563
    uint256 private constant MARKETS_DATA_SLOT = 0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563;

    // 168 bits(ethValue)
    uint256 private constant ETH_VALUE_MASK = (1 << 168) - 1;
    // 160 bits(proxy)
    uint256 private constant PROXY_MASK = (1 << 160) - 1;

    function batchBuyWithETH(bytes calldata tradeBytes) external override payable {
        uint256 ethBalanceBefore;
        assembly { ethBalanceBefore := sub(selfbalance(), callvalue()) }

        // trade
        _trade(tradeBytes);

        // return remaining ETH (if any)
        assembly {
            if eq(selfbalance(), ethBalanceBefore) {
                return(0, 0)
            }
            if gt(selfbalance(), ethBalanceBefore) {
                let success := call(gas(), caller(), sub(selfbalance(), ethBalanceBefore), 0, 0, 0, 0)
                return(0, 0)
            }
        }
        revert("Failed to return ETH.");
    }

    function batchBuyWithERC20s(
        ERC20Pair[] calldata erc20Pairs,
        bytes calldata tradeBytes,
        address[] calldata dustTokens
    ) external override payable nonReentrant {
        // transfer ERC20 tokens from the sender to this contract
        _transferERC20Pairs(erc20Pairs);

        // trade
        _trade(tradeBytes);

        // return dust tokens (if any)
        _returnDust(dustTokens);

        // return remaining ETH (if any)
        assembly {
            if gt(selfbalance(), 0) {
                let success := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
            }
        }
    }

    function _trade(bytes calldata tradeBytes) internal {
        assembly {
            let anySuccess
            let itemLength
            let end := add(tradeBytes.offset, tradeBytes.length)
            let ptr := mload(0x40) // free memory pointer

            // nextOffset == offset + 28bytes[2 + 1 + 21 + 4] + itemLength
            for { let offset := tradeBytes.offset } lt(offset, end) { offset := add(add(offset, 28), itemLength) } {
                // head == [2 bytes(marketId) + 1 bytes(continueIfFailed) + 21 bytes(ethValue) + 4 bytes(itemLength) + 4 bytes(item)]
                // head == [16 bits(marketId) + 8 bits(continueIfFailed) + 168 bits(ethValue) + 32 bits(itemLength) + 32 bits(item)]
                let head := calldataload(offset)

                // itemLength = (head >> 32) & 0xffffffff
                itemLength := and(shr(32, head), 0xffffffff)

                // itemOffset == offset + 28
                // copy item.data to memory ptr
                calldatacopy(ptr, add(offset, 28), itemLength)

                // marketId = head >> (8 + 168 + 32 + 32) = head >> 240
                let marketId := shr(240, head)

                // Seaport
                if eq(marketId, SEAPORT_MARKET_ID) {
                    // ethValue = (head >> 64) & ETH_VALUE_MASK
                    // SEAPORT.call{value: ethValue}(item)
                    if iszero(call(gas(), SEAPORT, and(shr(64, head), ETH_VALUE_MASK), ptr, itemLength, 0, 0)) {
                        _revertOrContinue(head)
                        continue
                    }
                    anySuccess := 1
                    continue
                }

                // ElementEx
                if eq(marketId, ELEMENT_MARKET_ID) {
                    // ethValue = (head >> 64) & ETH_VALUE_MASK
                    // ELEMENT.call{value: ethValue}(item)
                    if iszero(call(gas(), ELEMENT, and(shr(64, head), ETH_VALUE_MASK), ptr, itemLength, 0, 0)) {
                        _revertOrContinue(head)
                        continue
                    }
                    anySuccess := 1
                    continue
                }

                // WETH
                if eq(marketId, WETH_MARKET_ID) {
                    let methodId := and(head, 0xffffffff)

                    // WETH.deposit();
                    if eq(methodId, 0xd0e30db0) {
                        if iszero(call(gas(), WETH, and(shr(64, head), ETH_VALUE_MASK), ptr, itemLength, 0, 0)) {
                            _revertOrContinue(head)
                            continue
                        }
                        anySuccess := 1
                        continue
                    }

                    // WETH.withdraw();
                    if eq(methodId, 0x2e1a7d4d) {
                        if iszero(call(gas(), WETH, 0, ptr, itemLength, 0, 0)) {
                            _revertOrContinue(head)
                            continue
                        }
                        anySuccess := 1
                        continue
                    }

                    // Do not support other methods.
                    _revertOrContinue(head)
                    continue
                }

                // Others
                // struct Market {
                //        address proxy;
                //        bool isLibrary;
                //        bool isActive;
                //  }
                // [80 bits(unused) + 8 bits(isActive) + 8 bits(isLibrary) + 160 bits(proxy)]
                // [10 bytes(unused) + 1 bytes(isActive) + 1 bytes(isLibrary) + 20 bytes(proxy)]

                // market.slot = markets.data.slot + marketId
                // market = sload(market.slot)
                let market := sload(add(MARKETS_DATA_SLOT, marketId))

                // if (!market.isActive)
                if iszero(byte(10, market)) {
                    // if (!continueIfFailed)
                    if iszero(byte(2, head)) {
                         // revert("Inactive market.")
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(0x40, 0x00000010496e616374697665206d61726b65742e000000000000000000000000)
                        mstore(0x60, 0)
                        revert(0, 0x64)
                    }
                    continue
                }

                // if (!market.isLibrary)
                if iszero(byte(11, market)) {
                    // ethValue = (head >> 64) & ETH_VALUE_MASK
                    // market.proxy.call{value: ethValue}(item)
                    if iszero(call(gas(), and(market, PROXY_MASK), and(shr(64, head), ETH_VALUE_MASK), ptr, itemLength, 0, 0)) {
                        _revertOrContinue(head)
                        continue
                    }
                    anySuccess := 1
                    continue
                }

                // market.proxy.delegatecall(item)
                if iszero(delegatecall(gas(), and(market, PROXY_MASK), ptr, itemLength, 0, 0)) {
                    _revertOrContinue(head)
                    continue
                }
                anySuccess := 1
            }

            // if (!anySuccess)
            if iszero(anySuccess) {
                if gt(tradeBytes.length, 0) {
                    if iszero(returndatasize()) {
                        // revert("No order succeeded.")
                        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                        mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
                        mstore(0x40, 0x000000134e6f206f72646572207375636365656465642e000000000000000000)
                        mstore(0x60, 0)
                        revert(0, 0x64)
                    }
                    // revert(returnData)
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }

            function _revertOrContinue(head) {
                // head == [2 bytes(marketId) + 1 bytes(continueIfFailed) + 21 bytes(ethValue) + 4 bytes(itemLength) + 4 bytes(item)]
                // if (!continueIfFailed)
                if iszero(byte(2, head)) {
                    if iszero(returndatasize()) {
                        mstore(0, head)
                        revert(0, 0x20)
                    }
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    function _transferERC20Pairs(ERC20Pair[] calldata erc20Pairs) internal {
        // transfer ERC20 tokens from the sender to this contract
        if (erc20Pairs.length > 0) {
            assembly {
                let ptr := mload(0x40)
                let end := add(erc20Pairs.offset, mul(erc20Pairs.length, 0x40))

                // selector for transferFrom(address,address,uint256)
                mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), address())
                for { let offset := erc20Pairs.offset } lt(offset, end) { offset := add(offset, 0x40) } {
                    let amount := calldataload(add(offset, 0x20))
                    if gt(amount, 0) {
                        mstore(add(ptr, 0x44), amount)
                        let success := call(gas(), calldataload(offset), 0, ptr, 0x64, 0, 0)
                    }
                }
            }
        }
    }

    function _returnDust(address[] calldata tokens) internal {
        // return remaining tokens (if any)
        for (uint256 i; i < tokens.length; ) {
            _transferERC20WithoutCheck(tokens[i], msg.sender, IERC20(tokens[i]).balanceOf(address(this)));
            unchecked { ++i; }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IAggregator {

    struct ERC20Pair {
        address token;
        uint256 amount;
    }

    function batchBuyWithETH(bytes calldata tradeBytes) external payable;

    function batchBuyWithERC20s(
        ERC20Pair[] calldata erc20Pairs,
        bytes calldata tradeBytes,
        address[] calldata dustTokens
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../storage/LibAggregatorStorage.sol";
import "../../libs/FixinTokenSpender.sol";
import "./ISimulator.sol";


contract SimulatorFeature is ISimulator, FixinTokenSpender {

    uint256 public constant WETH_MARKET_ID = 999;
    address public immutable WETH;

    constructor(address weth) {
        WETH = weth;
    }

    function batchBuyWithETHSimulate(TradeDetails[] calldata tradeDetails) external payable override {
        // simulate trade and revert
        bytes memory error = abi.encodePacked(_simulateTrade(tradeDetails));
        assembly {
            revert(add(error, 0x20), mload(error))
        }
    }

    function batchBuyWithERC20sSimulate(
        IAggregator.ERC20Pair[] calldata erc20Pairs,
        TradeDetails[] calldata tradeDetails,
        address[] calldata dustTokens
    ) external payable override {
        // transfer ERC20 tokens from the sender to this contract
        _transferERC20Pairs(erc20Pairs);

        uint256 result = _simulateTrade(tradeDetails);

        // return dust tokens (if any)
        _returnDust(dustTokens);

        bytes memory error = abi.encodePacked(result);
        assembly {
            revert(add(error, 0x20), mload(error))
        }
    }

    function _simulateTrade(TradeDetails[] calldata tradeDetails) internal returns (uint256 result) {
        unchecked {
            LibAggregatorStorage.Storage storage stor = LibAggregatorStorage.getStorage();
            for (uint256 i = 0; i < tradeDetails.length; ++i) {
                bool success;
                TradeDetails calldata item = tradeDetails[i];

                if (item.marketId == WETH_MARKET_ID) {
                    (success, ) = WETH.call{value: item.value}(item.tradeData);
                } else {
                    LibAggregatorStorage.Market memory market = stor.markets[item.marketId];
                    if (market.isActive) {
                        (success,) = market.isLibrary ?
                            market.proxy.delegatecall(item.tradeData) :
                            market.proxy.call{value: item.value}(item.tradeData);
                    }
                }

                if (success) {
                    result |= 1 << i;
                }
            }
            return result;
        }
    }

    function _transferERC20Pairs(IAggregator.ERC20Pair[] calldata erc20Pairs) internal {
        // transfer ERC20 tokens from the sender to this contract
        if (erc20Pairs.length > 0) {
            assembly {
                let ptr := mload(0x40)
                let end := add(erc20Pairs.offset, mul(erc20Pairs.length, 0x40))

                // selector for transferFrom(address,address,uint256)
                mstore(ptr, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
                mstore(add(ptr, 0x04), caller())
                mstore(add(ptr, 0x24), address())
                for { let offset := erc20Pairs.offset } lt(offset, end) { offset := add(offset, 0x40) } {
                    let amount := calldataload(add(offset, 0x20))
                    if gt(amount, 0) {
                        mstore(add(ptr, 0x44), amount)
                        let success := call(gas(), calldataload(offset), 0, ptr, 0x64, 0, 0)
                    }
                }
            }
        }
    }

    function _returnDust(address[] calldata tokens) internal {
        // return remaining tokens (if any)
        for (uint256 i; i < tokens.length; ) {
            _transferERC20WithoutCheck(tokens[i], msg.sender, IERC20(tokens[i]).balanceOf(address(this)));
            unchecked { ++i; }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "../../interfaces/IAggregator.sol";


interface ISimulator {

    struct TradeDetails {
        uint256 marketId;
        uint256 value;
        bytes tradeData;
    }

    function batchBuyWithETHSimulate(TradeDetails[] calldata tradeDetails) external payable;

    function batchBuyWithERC20sSimulate(
        IAggregator.ERC20Pair[] calldata erc20Pairs,
        TradeDetails[] calldata tradeDetails,
        address[] calldata dustTokens
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./interfaces/IAggregator.sol";
import "./features/simulator/ISimulator.sol";
import "./features/estimateGas/IEstimateGasFeature.sol";


interface IElementExSwapV2 is IAggregator, ISimulator, IEstimateGasFeature {
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "../../interfaces/IAggregator.sol";


interface IEstimateGasFeature {

    function estimateGasBatchBuyWithETH(bytes calldata tradeBytes) external payable returns(uint256);

    function estimateGasBatchBuyWithERC20s(
        IAggregator.ERC20Pair[] calldata erc20Pairs,
        bytes calldata tradeBytes,
        address[] calldata dustTokens
    ) external payable returns(uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721A {
    using Address for address;
    using Strings for uint256;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr) if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner) if(!isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        _transfer(from, to, tokenId);
        if (to.isContract()) if(!_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract TestERC1155 is ERC1155("https://meebits.larvalabs.com/meebit/") {
    using Strings for uint256;

    // function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
    function mint(address to, uint256 tokenId, uint256 amount) public returns (bool) {
        _mint(to, tokenId, amount, "0x");
        return true;
    }

    function uri(uint256 tokenId) override public view returns (string memory) {
        string memory uri = "https://meebits.larvalabs.com/meebit/";// super.uri();
        return bytes(uri).length > 0
        ? string(abi.encodePacked(uri, tokenId.toString()))
        : '';
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

library Market {
    uint256 constant INTENT_SELL = 1;
    uint256 constant INTENT_AUCTION = 2;
    uint256 constant INTENT_BUY = 3;

    uint8 constant SIGN_V1 = 1;
    uint8 constant SIGN_V3 = 3;

    struct OrderItem {
        uint256 price;
        bytes data;
    }

    struct Order {
        uint256 salt;
        address user;
        uint256 network;
        uint256 intent;
        uint256 delegateType;
        uint256 deadline;
        address currency;
        bytes dataMask;
        OrderItem[] items;
        // signature
        bytes32 r;
        bytes32 s;
        uint8 v;
        uint8 signVersion;
    }

    struct Fee {
        uint256 percentage;
        address to;
    }

    struct SettleDetail {
        Market.Op op;
        uint256 orderIdx;
        uint256 itemIdx;
        uint256 price;
        bytes32 itemHash;
        address executionDelegate;
        bytes dataReplacement;
        uint256 bidIncentivePct;
        uint256 aucMinIncrementPct;
        uint256 aucIncDurationSecs;
        Fee[] fees;
    }

    struct SettleShared {
        uint256 salt;
        uint256 deadline;
        uint256 amountToEth;
        uint256 amountToWeth;
        address user;
        bool canFail;
    }

    struct RunInput {
        Order[] orders;
        SettleDetail[] details;
        SettleShared shared;
        // signature
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct OngoingAuction {
        uint256 price;
        uint256 netPrice;
        uint256 endAt;
        address bidder;
    }

    enum InvStatus {
        NEW,
        AUCTION,
        COMPLETE,
        CANCELLED,
        REFUNDED
    }

    enum Op {
        INVALID,
        // off-chain
        COMPLETE_SELL_OFFER,
        COMPLETE_BUY_OFFER,
        CANCEL_OFFER,
        // auction
        BID,
        COMPLETE_AUCTION,
        REFUND_AUCTION,
        REFUND_AUCTION_STUCK_ITEM
    }

    enum DelegationType {
        INVALID,
        ERC721,
        ERC1155
    }

    struct Pair {
        IERC721 token;
        uint256 tokenId;
    }
}


interface IX2Y2Market {
    function run(Market.RunInput calldata input) external payable;
}

contract X2Y2MarketProxy {

    // ERC721 interfaceID
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    // ERC1155 interfaceID
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    // X2Y2 exchange address
    address public constant X2Y2_EXCHANGE = 0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3;

    function run(Market.RunInput calldata input) public payable {
        uint256 ethValue;
        for (uint256 i = 0; i < input.details.length; i++) {
            ethValue += input.details[i].price;
        }

        require(!input.shared.canFail, "X2Y2Proxy: unsupported partly fail.");
        IX2Y2Market(X2Y2_EXCHANGE).run{value: ethValue}(input);

        address from = address(this);
        address to = msg.sender;
        for (uint256 i = 0; i < input.details.length; i++) {
            Market.SettleDetail memory detail = input.details[i];
            Market.Order memory order = input.orders[detail.orderIdx];
            bytes memory data = order.items[detail.itemIdx].data;
            {
                if (order.dataMask.length > 0 && detail.dataReplacement.length > 0) {
                    _arrayReplace(data, detail.dataReplacement, order.dataMask);
                }
            }

            Market.Pair[] memory pairs = abi.decode(data, (Market.Pair[]));
            for (uint256 j = 0; j < pairs.length; j++) {
                Market.Pair memory p = pairs[j];
                p.token.safeTransferFrom(from, to, p.tokenId);
            }
        }
    }

    function _arrayReplace(bytes memory src, bytes memory replacement, bytes memory mask) internal pure {
        for (uint256 i = 0; i < src.length; i++) {
            if (mask[i] != 0) {
                src[i] = replacement[i];
            }
        }
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IConduitController.sol";
import "./interfaces/ISeaport.sol";
import "./interfaces/ITransferSelectorNFT.sol";
import "./interfaces/ILooksRare.sol";
import "./interfaces/IX2y2.sol";
import "./IThirdExchangeCheckerFeature.sol";


contract ThirdExchangeCheckerFeature is IThirdExchangeCheckerFeature {

    address public constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address public immutable LOOKS_RARE;
    address public immutable X2Y2;
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    constructor(address looksRare, address x2y2) {
        LOOKS_RARE = looksRare;
        X2Y2 = x2y2;
    }

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getSeaportCheckInfoV2(
        address account,
        uint8 itemType,
        address nft,
        uint256 tokenId,
        bytes32 conduitKey,
        bytes32 orderHash,
        uint256 counter
    )
        external
        override
        view
        returns (SeaportCheckInfo memory info)
    {
        (info.conduit, info.conduitExists) = getConduit(conduitKey);
        if (itemType == 0) {
            info.erc721Owner = ownerOf(nft, tokenId);
            info.erc721ApprovedAccount = getApproved(nft, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        } else if (itemType == 1) {
            info.erc1155Balance = balanceOf(nft, account, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        }

        try ISeaport(SEAPORT).getOrderStatus(orderHash) returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        ) {
            info.isValidated = isValidated;
            info.isCancelled = isCancelled;
            info.totalFilled = totalFilled;
            info.totalSize = totalSize;

            if (totalFilled > 0 && totalFilled == totalSize) {
                info.isCancelled = true;
            }
        } catch {}

        try ISeaport(SEAPORT).getCounter(account) returns(uint256 _counter) {
            if (counter != _counter) {
                info.isCancelled = true;
            }
        } catch {}
        return info;
    }

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getSeaportCheckInfoEx(address account, uint8 itemType, address nft, uint256 tokenId, bytes32 conduitKey, bytes32 orderHash)
        public
        override
        view
        returns (SeaportCheckInfo memory info)
    {
        (info.conduit, info.conduitExists) = getConduit(conduitKey);
        if (itemType == 0) {
            info.erc721Owner = ownerOf(nft, tokenId);
            info.erc721ApprovedAccount = getApproved(nft, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        } else if (itemType == 1) {
            info.erc1155Balance = balanceOf(nft, account, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        }

        try ISeaport(SEAPORT).getOrderStatus(orderHash) returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        ) {
            info.isValidated = isValidated;
            info.isCancelled = isCancelled;
            info.totalFilled = totalFilled;
            info.totalSize = totalSize;

            if (totalFilled > 0 && totalFilled == totalSize) {
                info.isCancelled = true;
            }
        } catch {}
        return info;
    }

    function getSeaportCheckInfo(address account, address nft, uint256 tokenId, bytes32 conduitKey, bytes32 orderHash)
        external
        override
        view
        returns (SeaportCheckInfo memory info)
    {
        uint8 itemType = 255;
        if (supportsERC721(nft)) {
            itemType = 0;
        } else if (supportsERC1155(nft)) {
            itemType = 1;
        }
        return getSeaportCheckInfoEx(account, itemType, nft, tokenId, conduitKey, orderHash);
    }

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getLooksRareCheckInfoEx(address account, uint8 itemType, address nft, uint256 tokenId, uint256 accountNonce)
        public
        override
        view
        returns (LooksRareCheckInfo memory info)
    {
        try ILooksRare(LOOKS_RARE).transferSelectorNFT() returns (ITransferSelectorNFT transferSelector) {
            try transferSelector.checkTransferManagerForToken(nft) returns (address transferManager) {
                info.transferManager = transferManager;
            } catch {}
        } catch {}

        try ILooksRare(LOOKS_RARE).isUserOrderNonceExecutedOrCancelled(account, accountNonce) returns (bool isExecutedOrCancelled) {
            info.isExecutedOrCancelled = isExecutedOrCancelled;
        } catch {}

        try ILooksRare(LOOKS_RARE).userMinOrderNonce(account) returns (uint256 minNonce) {
            if (accountNonce < minNonce) {
                info.isExecutedOrCancelled = true;
            }
        } catch {}

        if (itemType == 0) {
            info.erc721Owner = ownerOf(nft, tokenId);
            info.erc721ApprovedAccount = getApproved(nft, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.transferManager);
        } else if (itemType == 1) {
            info.erc1155Balance = balanceOf(nft, account, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.transferManager);
        }
        return info;
    }

    function getLooksRareCheckInfo(address account, address nft, uint256 tokenId, uint256 accountNonce)
        external
        override
        view
        returns (LooksRareCheckInfo memory info)
    {
        uint8 itemType = 255;
        if (supportsERC721(nft)) {
            itemType = 0;
        } else if (supportsERC721(nft)) {
            itemType = 1;
        }
        return getLooksRareCheckInfoEx(account, itemType, nft, tokenId, accountNonce);
    }

    function getX2y2CheckInfo(address account, address nft, uint256 tokenId, bytes32 orderHash, address executionDelegate)
        external
        override
        view
        returns (X2y2CheckInfo memory info)
    {
        if (X2Y2 == address(0)) {
            return info;
        }

        try IX2y2(X2Y2).inventoryStatus(orderHash) returns (IX2y2.InvStatus status) {
            info.status = status;
        } catch {}

        info.erc721Owner = ownerOf(nft, tokenId);
        info.erc721ApprovedAccount = getApproved(nft, tokenId);
        info.isApprovedForAll = isApprovedForAll(nft, account, executionDelegate);
        return info;
    }

    function getConduit(bytes32 conduitKey) public view returns (address conduit, bool exists) {
        try ISeaport(SEAPORT).information() returns (string memory, bytes32, address conduitController) {
            try IConduitController(conduitController).getConduit(conduitKey) returns (address _conduit, bool _exists) {
                conduit = _conduit;
                exists = _exists;
            } catch {
            }
        } catch {
        }
        return (conduit, exists);
    }

    function supportsERC721(address nft) internal view returns (bool) {
        try IERC165(nft).supportsInterface(INTERFACE_ID_ERC721) returns (bool support) {
            return support;
        } catch {
        }
        return false;
    }

    function supportsERC1155(address nft) internal view returns (bool) {
        try IERC165(nft).supportsInterface(INTERFACE_ID_ERC1155) returns (bool support) {
            return support;
        } catch {
        }
        return false;
    }

    function ownerOf(address nft, uint256 tokenId) internal view returns (address owner) {
        try IERC721(nft).ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {
        }
        return owner;
    }

    function getApproved(address nft, uint256 tokenId) internal view returns (address operator) {
        try IERC721(nft).getApproved(tokenId) returns (address approvedAccount) {
            operator = approvedAccount;
        } catch {
        }
        return operator;
    }

    function isApprovedForAll(address nft, address owner, address operator) internal view returns (bool isApproved) {
        if (operator != address(0)) {
            try IERC721(nft).isApprovedForAll(owner, operator) returns (bool _isApprovedForAll) {
                isApproved = _isApprovedForAll;
            } catch {
            }
        }
        return isApproved;
    }

    function balanceOf(address nft, address account, uint256 id) internal view returns (uint256 balance) {
        try IERC1155(nft).balanceOf(account, id) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

interface IConduitController {

    /**
     * @notice Retrieve the current owner of a deployed conduit.
     *
     * @param conduit The conduit for which to retrieve the associated owner.
     *
     * @return owner The owner of the supplied conduit.
     */
    function ownerOf(address conduit) external view returns (address owner);

    /**
     * @notice Retrieve the conduit key for a deployed conduit via reverse
     *         lookup.
     *
     * @param conduit The conduit for which to retrieve the associated conduit
     *                key.
     *
     * @return conduitKey The conduit key used to deploy the supplied conduit.
     */
    function getKey(address conduit) external view returns (bytes32 conduitKey);

    /**
     * @notice Derive the conduit associated with a given conduit key and
     *         determine whether that conduit exists (i.e. whether it has been
     *         deployed).
     *
     * @param conduitKey The conduit key used to derive the conduit.
     *
     * @return conduit The derived address of the conduit.
     * @return exists  A boolean indicating whether the derived conduit has been
     *                 deployed or not.
     */
    function getConduit(bytes32 conduitKey)
        external
        view
        returns (address conduit, bool exists);

    /**
     * @notice Retrieve the potential owner, if any, for a given conduit. The
     *         current owner may set a new potential owner via
     *         `transferOwnership` and that owner may then accept ownership of
     *         the conduit in question via `acceptOwnership`.
     *
     * @param conduit The conduit for which to retrieve the potential owner.
     *
     * @return potentialOwner The potential owner, if any, for the conduit.
     */
    function getPotentialOwner(address conduit)
        external
        view
        returns (address potentialOwner);

    /**
     * @notice Retrieve the status (either open or closed) of a given channel on
     *         a conduit.
     *
     * @param conduit The conduit for which to retrieve the channel status.
     * @param channel The channel for which to retrieve the status.
     *
     * @return isOpen The status of the channel on the given conduit.
     */
    function getChannelStatus(address conduit, address channel)
        external
        view
        returns (bool isOpen);

    /**
     * @notice Retrieve the total number of open channels for a given conduit.
     *
     * @param conduit The conduit for which to retrieve the total channel count.
     *
     * @return totalChannels The total number of open channels for the conduit.
     */
    function getTotalChannels(address conduit)
        external
        view
        returns (uint256 totalChannels);

    /**
     * @notice Retrieve an open channel at a specific index for a given conduit.
     *         Note that the index of a channel can change as a result of other
     *         channels being closed on the conduit.
     *
     * @param conduit      The conduit for which to retrieve the open channel.
     * @param channelIndex The index of the channel in question.
     *
     * @return channel The open channel, if any, at the specified channel index.
     */
    function getChannel(address conduit, uint256 channelIndex)
        external
        view
        returns (address channel);

    /**
     * @notice Retrieve all open channels for a given conduit. Note that calling
     *         this function for a conduit with many channels will revert with
     *         an out-of-gas error.
     *
     * @param conduit The conduit for which to retrieve open channels.
     *
     * @return channels An array of open channels on the given conduit.
     */
    function getChannels(address conduit)
        external
        view
        returns (address[] memory channels);

    /**
     * @dev Retrieve the conduit creation code and runtime code hashes.
     */
    function getConduitCodeHashes()
        external
        view
        returns (bytes32 creationCodeHash, bytes32 runtimeCodeHash);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

interface ISeaport {
    /**
     * @notice Retrieve the status of a given order by hash, including whether
     *         the order has been cancelled or validated and the fraction of the
     *         order that has been filled.
     *
     * @param orderHash The order hash in question.
     *
     * @return isValidated A boolean indicating whether the order in question
     *                     has been validated (i.e. previously approved or
     *                     partially filled).
     * @return isCancelled A boolean indicating whether the order in question
     *                     has been cancelled.
     * @return totalFilled The total portion of the order that has been filled
     *                     (i.e. the "numerator").
     * @return totalSize   The total size of the order that is either filled or
     *                     unfilled (i.e. the "denominator").
     */
    function getOrderStatus(bytes32 orderHash)
        external
        view
        returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        );

    /**
     * @notice Retrieve the current counter for a given offerer.
     *
     * @param offerer The offerer in question.
     *
     * @return counter The current counter.
     */
    function getCounter(address offerer) external view returns (uint256 counter);

    /**
     * @notice Retrieve configuration information for this contract.
     *
     * @return version           The contract version.
     * @return domainSeparator   The domain separator for this contract.
     * @return conduitController The conduit Controller set for this contract.
     */
    function information()
        external
        view
        returns (
            string memory version,
            bytes32 domainSeparator,
            address conduitController
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

interface ITransferSelectorNFT {
    function checkTransferManagerForToken(address collection) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import "./ITransferSelectorNFT.sol";

interface ILooksRare {
    /**
    * @notice Check whether user order nonce is executed or cancelled
     * @param user address of user
     * @param orderNonce nonce of the order
     */
    function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool);

    function transferSelectorNFT() external view returns (ITransferSelectorNFT);

    function userMinOrderNonce(address user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

interface IX2y2 {

    enum InvStatus {
        NEW,
        AUCTION,
        COMPLETE,
        CANCELLED,
        REFUNDED
    }

    function inventoryStatus(bytes32) external view returns (InvStatus status);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interfaces/IConduitController.sol";
import "./interfaces/ISeaport.sol";
import "./interfaces/ITransferSelectorNFT.sol";
import "./interfaces/ILooksRare.sol";
import "./interfaces/IX2y2.sol";


interface IThirdExchangeCheckerFeature {

    struct SeaportCheckInfo {
        address conduit;
        bool conduitExists;
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll or erc1155.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        uint256 erc1155Balance;
        bool isValidated;
        bool isCancelled;
        uint256 totalFilled;
        uint256 totalSize;
    }

    struct LooksRareCheckInfo {
        address transferManager;
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll or erc1155.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        uint256 erc1155Balance;
        bool isExecutedOrCancelled;
    }

    struct X2y2CheckInfo {
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        IX2y2.InvStatus status;
    }

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getSeaportCheckInfoV2(
        address account,
        uint8 itemType,
        address nft,
        uint256 tokenId,
        bytes32 conduitKey,
        bytes32 orderHash,
        uint256 counter
    ) external view returns (SeaportCheckInfo memory info);

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getSeaportCheckInfoEx(address account, uint8 itemType, address nft, uint256 tokenId, bytes32 conduitKey, bytes32 orderHash)
        external
        view
        returns (SeaportCheckInfo memory info);

    function getSeaportCheckInfo(address account, address nft, uint256 tokenId, bytes32 conduitKey, bytes32 orderHash)
        external
        view
        returns (SeaportCheckInfo memory info);

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getLooksRareCheckInfoEx(address account, uint8 itemType, address nft, uint256 tokenId, uint256 accountNonce)
        external
        view
        returns (LooksRareCheckInfo memory info);

    function getLooksRareCheckInfo(address account, address nft, uint256 tokenId, uint256 accountNonce)
        external
        view
        returns (LooksRareCheckInfo memory info);

    function getX2y2CheckInfo(address account, address nft, uint256 tokenId, bytes32 orderHash, address executionDelegate)
        external
        view
        returns (X2y2CheckInfo memory info);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./features/asset_checker/IAssetCheckerFeature.sol";
import "./features/space_id/ISpaceIdHelperFeature.sol";
import "./features/ens/IENSHelperFeature.sol";
import "./features/batch_signed_erc721_orders_checker/IBatchSignedERC721OrdersCheckerFeature.sol";
import "./features/third_exchange_checker/IThirdExchangeCheckerFeature.sol";
import "./features/element_exchange_checker/IElementExCheckerFeature.sol";
import "./features/element_exchange_checker/IElementExCheckerFeatureV2.sol";
import "./features/sdk_approve_checker/ISDKApproveCheckerFeature.sol";
import "./features/sweep/ISweepHelperFeature.sol";

interface IAggTraderHelper is
    ISpaceIdHelperFeature,
    IAssetCheckerFeature,
    IENSHelperFeature,
    IBatchSignedERC721OrdersCheckerFeature,
    IThirdExchangeCheckerFeature,
    IElementExCheckerFeature,
    IElementExCheckerFeatureV2,
    ISDKApproveCheckerFeature,
    ISweepHelperFeature
{
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IAssetCheckerFeature {

    struct AssetCheckResultInfo {
        uint8 itemType; // 0: ERC721, 1: ERC1155, 2: ERC20, 255: other
        uint256 allowance;
        uint256 balance;
        address erc721Owner;
        address erc721ApprovedAccount;
    }

    function checkAssetsEx(
        address account,
        address operator,
        uint8[] calldata itemTypes,
        address[] calldata tokens,
        uint256[] calldata tokenIds
    )
        external
        view
        returns (AssetCheckResultInfo[] memory infos);

    function checkAssets(
        address account,
        address operator,
        address[] calldata tokens,
        uint256[] calldata tokenIds
    )
        external
        view
        returns (AssetCheckResultInfo[] memory infos);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.15;


interface ISpaceIdHelperFeature {

    struct SpaceIdItem {
        uint256 base;
        uint256 premium;
        bool available;
        bytes32 commitHash;
        uint256 commitTimestamp;
    }

    struct SpaceIdInfos {
        uint256 minCommitAge;
        uint256 maxCommitAge;
        SpaceIdItem[] items;
    }

    function querySpaceIdInfos(
        address owner,
        address resolver,
        string[] calldata names,
        bytes32[] calldata secrets,
        uint256[] calldata durations
    ) external view returns (SpaceIdInfos memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IENSHelperFeature {

    struct ENSQueryResult {
        address resolver;
        address domainAddr;
        address owner;
        bool available;
    }

    struct ENSReverseResult {
        address resolver;
        bytes domain;
        address verifyResolver;
        address verifyAddr;
    }

    function queryENSInfosByNode(address ens, bytes32[] calldata nodes) external view returns (ENSQueryResult[] memory);

    function queryENSInfosByToken(address token, address ens, uint256[] calldata tokenIds) external view returns (ENSQueryResult[] memory);

    function queryENSReverseInfos(address ens, address[] calldata addresses) external view returns (ENSReverseResult[] memory);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IBatchSignedERC721OrdersCheckerFeature {

    struct BSOrderItem {
        uint256 erc20TokenAmount;
        uint256 nftId;
    }

    struct BSCollection {
        address nftAddress;
        uint256 platformFee;
        uint256 royaltyFee;
        address royaltyFeeRecipient;
        BSOrderItem[] items;
    }

    struct BSERC721Orders {
        address maker;
        uint256 listingTime;
        uint256 expirationTime;
        uint256 startNonce;
        address paymentToken;
        address platformFeeRecipient;
        BSCollection[] basicCollections;
        BSCollection[] collections;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct BSOrderItemCheckResult {
        bool isNonceValid;
        bool isERC20AmountValid;
        address ownerOfNftId;
        address approvedAccountOfNftId;
    }

    struct BSCollectionCheckResult {
        bool isApprovedForAll;
        BSOrderItemCheckResult[] items;
    }

    struct BSERC721OrdersCheckResult {
        bytes32 orderHash;
        uint256 hashNonce;
        bool validSignature;
        BSCollectionCheckResult[] basicCollections;
        BSCollectionCheckResult[] collections;
    }

    function checkBSERC721Orders(BSERC721Orders calldata order) external view returns (BSERC721OrdersCheckResult memory r);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LibStructure.sol";

interface IElementExCheckerFeature {

    struct ERC20CheckInfo {
        uint256 balance;            // 买家ERC20余额或ETH余额
        uint256 allowance;          // erc20.allowance(taker, elementEx)。erc20若为ETH，固定返回true
        bool balanceCheck;          // check `balance >= erc20TotalAmount`
        bool allowanceCheck;        // check `allowance >= erc20TotalAmount`，如果是NATIVE_ADDRESS默认返回true
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    struct ERC721CheckInfo {
        bool ecr721TokenIdCheck;    // 检查买家与卖家的的`ecr721TokenId`是否匹配. ecr721TokenId相等，或者满足properties条件.
        bool erc721OwnerCheck;      // 检查卖家是否是该ecr721TokenId的拥有者
        bool erc721ApprovedCheck;   // 721授权检查
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    struct ERC721SellOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool extraCheck;            // 荷兰拍模式下，extra必须小于等于100000000
        bool nonceCheck;            // 检查订单nonce，通过检查返回true(即：订单未成交也未取消)，未通过检查返回false
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool erc20AddressCheck;     // erc20地址检查。不能为address(0)，且该地址为NATIVE_ADDRESS，或者为一个合约地址
        bool erc721AddressCheck;    // erc721地址检查，erc721合约需要实现IERC721标准
        bool erc721OwnerCheck;      // 检查maker是否是该nftId的拥有者
        bool erc721ApprovedCheck;   // 721授权检查
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
    }

    struct ERC721BuyOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool nonceCheck;            // 检查订单nonce，通过检查返回true(即：订单未成交也未取消)，未通过检查返回false
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool propertiesCheck;       // 属性检查。若`order.nftProperties`不为空,则`nftId`必须为0，并且property地址必须是address(0)或合约地址
        bool erc20AddressCheck;     // erc20地址检查。该地址必须为一个合约地址，不能是NATIVE_ADDRESS，不能为address(0)
        bool erc721AddressCheck;    // erc721地址检查。erc721合约需要实现IERC721标准
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
        uint256 erc20Balance;       // 买家ERC20余额
        uint256 erc20Allowance;     // 买家ERC20授权额度
        bool erc20BalanceCheck;     // check `erc20Balance >= erc20TotalAmount`
        bool erc20AllowanceCheck;   // check `erc20Allowance >= erc20TotalAmount`
    }

    struct ERC1155SellOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        uint256 erc1155RemainingAmount; // 1155支持部分成交，remainingAmount返回订单剩余的数量
        uint256 erc1155Balance;     // erc1155.balanceOf(order.maker, order.erc1155TokenId)
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool extraCheck;            // 荷兰拍模式下，extra必须小于等于100000000
        bool nonceCheck;            // 检查订单nonce
        bool remainingAmountCheck;  // check `erc1155RemainingAmount > 0`
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool erc20AddressCheck;     // erc20地址检查。不能为address(0)，且该地址为NATIVE_ADDRESS，或者为一个合约地址
        bool erc1155AddressCheck;   // erc1155地址检查，erc1155合约需要实现IERC1155标准
        bool erc1155BalanceCheck;   // check `erc1155Balance >= order.erc1155TokenAmount`
        bool erc1155ApprovedCheck;  // check `erc1155.isApprovedForAll(order.maker, elementEx)`
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
    }

    struct ERC1155SellOrderTakerCheckInfo {
        uint256 erc20Balance;       // 买家ERC20余额或ETH余额
        uint256 erc20Allowance;     // erc20.allowance(taker, elementEx)。erc20若为ETH，固定返回true
        uint256 erc20WillPayAmount; // 1155支持部分成交，`erc20WillPayAmount`为部分成交所需的总费用
        bool balanceCheck;          // check `erc20Balance >= erc20WillPayAmount
        bool allowanceCheck;        // check `erc20Allowance >= erc20WillPayAmount
        bool buyAmountCheck;        // 1155支持部分成交，购买的数量不能大于订单剩余的数量，即：`erc1155BuyAmount <= erc1155RemainingAmount`
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    struct ERC1155BuyOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        uint256 erc1155RemainingAmount; // 1155支持部分成交，remainingAmount返回剩余未成交的数量
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool nonceCheck;            // 检查订单nonce
        bool remainingAmountCheck;  // check `erc1155RemainingAmount > 0`
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool propertiesCheck;       // 属性检查。若order.erc1155Properties不为空,则`order.erc1155TokenId`必须为0，并且property地址必须是address(0)或合约地址
        bool erc20AddressCheck;     // erc20地址检查。该地址必须为一个合约地址，不能是NATIVE_ADDRESS，不能为address(0)
        bool erc1155AddressCheck;   // erc1155地址检查，erc1155合约需要实现IERC1155标准
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
        uint256 erc20Balance;       // 买家ERC20余额
        uint256 erc20Allowance;     // 买家ERC20授权额度
        bool erc20BalanceCheck;     // check `erc20Balance >= erc20TotalAmount`
        bool erc20AllowanceCheck;   // check `erc20AllowanceCheck >= erc20TotalAmount`
    }

    struct ERC1155BuyOrderTakerCheckInfo {
        uint256 erc1155Balance;     // erc1155.balanceOf(taker, erc1155TokenId)
        bool ecr1155TokenIdCheck;   // 检查买家与卖家的的`ecr1155TokenId`是否匹配. ecr1155TokenId，或者满足properties条件.
        bool erc1155BalanceCheck;   // check `erc1155SellAmount <= erc1155Balance`
        bool erc1155ApprovedCheck;  // check `erc1155.isApprovedForAll(taker, elementEx)`
        bool sellAmountCheck;       // check `erc1155SellAmount <= erc1155RemainingAmount`，即：卖出的数量不能大于订单剩余的数量
        bool listingTimeCheck;      // check `block.timestamp >= listingTime`
        bool takerCheck;            // check `order.taker == taker || order.taker == address(0)`
    }

    /// 注意：taker在这里指买家，当taker为address(0)时，忽略`takerCheckInfo`，
    ///      当买家不为address(0)时，takerCheckInfo返回taker相关检查信息.
    function checkERC721SellOrder(LibNFTOrder.NFTSellOrder calldata order, address taker)
        external
        view
        returns (ERC721SellOrderCheckInfo memory info, ERC20CheckInfo memory takerCheckInfo);

    /// 注意：taker在这里指买家，当taker为address(0)时，忽略`takerCheckInfo`，
    ///      当taker不为address(0)时，takerCheckInfo返回taker相关检查信息.
    function checkERC721SellOrderEx(
        LibNFTOrder.NFTSellOrder calldata order,
        address taker,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (ERC721SellOrderCheckInfo memory info, ERC20CheckInfo memory takerCheckInfo, bool validSignature);

    /// 注意：taker在这里指卖家，当taker为address(0)时，忽略`takerCheckInfo`，
    ///      当taker不为address(0)时，takerCheckInfo返回ERC721相关检查信息.
    function checkERC721BuyOrder(LibNFTOrder.NFTBuyOrder calldata order, address taker, uint256 erc721TokenId)
        external
        view
        returns (ERC721BuyOrderCheckInfo memory info, ERC721CheckInfo memory takerCheckInfo);

    /// 注意：taker在这里指卖家，当taker为address(0)时，忽略`takerCheckInfo`，
    ///      当taker不为address(0)时，takerCheckInfo返回ERC721相关检查信息.
    function checkERC721BuyOrderEx(
        LibNFTOrder.NFTBuyOrder calldata order,
        address taker,
        uint256 erc721TokenId,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (ERC721BuyOrderCheckInfo memory info, ERC721CheckInfo memory takerCheckInfo, bool validSignature);

    /// 注意：
    ///     1.taker在这里指买家，当taker为address(0)时，忽略`takerCheckInfo`，当taker不为address(0)时，takerCheckInfo返回taker相关检查信息.
    ///     2.1155支持部分成交，erc1155BuyAmount指taker购买的数量，taker为address(0)时，该字段忽略
    function checkERC1155SellOrder(LibNFTOrder.ERC1155SellOrder calldata order, address taker, uint128 erc1155BuyAmount)
        external
        view
        returns (ERC1155SellOrderCheckInfo memory info, ERC1155SellOrderTakerCheckInfo memory takerCheckInfo);

    /// 注意：
    ///     1.taker在这里指买家，当taker为address(0)时，忽略`takerCheckInfo`，当taker不为address(0)时，takerCheckInfo返回taker相关检查信息.
    ///     2.1155支持部分成交，erc1155BuyAmount指taker购买的数量，taker为address(0)时，该字段忽略
    function checkERC1155SellOrderEx(
        LibNFTOrder.ERC1155SellOrder calldata order,
        address taker,
        uint128 erc1155BuyAmount,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (ERC1155SellOrderCheckInfo memory info, ERC1155SellOrderTakerCheckInfo memory takerCheckInfo, bool validSignature);

    /// 注意：
    ///     1.taker在这里指卖家，当taker为address(0)时，忽略`takerCheckInfo`，当taker不为address(0)时，takerCheckInfo返回ERC1155相关检查信息.
    ///     2.1155支持部分成交，erc1155SellAmount指taker卖出的数量，taker为address(0)时，该字段忽略
    function checkERC1155BuyOrder(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount
    )
        external
        view
        returns (ERC1155BuyOrderCheckInfo memory info, ERC1155BuyOrderTakerCheckInfo memory takerCheckInfo);

    /// 注意：
    ///     1.taker在这里指卖家，当taker为address(0)时，忽略`takerCheckInfo`，当taker不为address(0)时，takerCheckInfo返回ERC1155相关检查信息.
    ///     2.1155支持部分成交，erc1155SellAmount指taker卖出的数量，taker为address(0)时，该字段忽略
    function checkERC1155BuyOrderEx(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        LibSignature.Signature calldata signature
    )
        external
        view
        returns (ERC1155BuyOrderCheckInfo memory info, ERC1155BuyOrderTakerCheckInfo memory takerCheckInfo, bool validSignature);

    function validateERC721SellOrderSignature(LibNFTOrder.NFTSellOrder calldata order, LibSignature.Signature calldata signature)
        external
        view
        returns (bool valid);

    function validateERC721BuyOrderSignature(LibNFTOrder.NFTBuyOrder calldata order, LibSignature.Signature calldata signature)
        external
        view
        returns (bool valid);

    function getERC721SellOrderHash(LibNFTOrder.NFTSellOrder calldata order) external view returns (bytes32);

    function getERC721BuyOrderHash(LibNFTOrder.NFTBuyOrder calldata order) external view returns (bytes32);

    function isERC721OrderNonceFilled(address account, uint256 nonce) external view returns (bool filled);

    function isERC1155OrderNonceCancelled(address account, uint256 nonce) external view returns (bool filled);

    function getHashNonce(address maker) external view returns (uint256);

    function getERC1155SellOrderInfo(LibNFTOrder.ERC1155SellOrder calldata order)
        external
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo);

    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder calldata order)
        external
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo);

    function validateERC1155SellOrderSignature(LibNFTOrder.ERC1155SellOrder calldata order, LibSignature.Signature calldata signature)
        external
        view
        returns (bool valid);

    function validateERC1155BuyOrderSignature(LibNFTOrder.ERC1155BuyOrder calldata order, LibSignature.Signature calldata signature)
        external
        view
        returns (bool valid);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./LibStructure.sol";

interface IElementExCheckerFeatureV2 {

    struct BuyOrderCheckInfo {
        bool success;               // 所有的检查通过时为true，只要有一项检查未通过时为false
        uint256 hashNonce;
        bytes32 orderHash;
        bool makerCheck;            // check `maker != address(0)`
        bool takerCheck;            // check `taker != ElementEx`
        bool listingTimeCheck;      // check `listingTime < expireTime`
        bool expireTimeCheck;       // check `expireTime > block.timestamp`
        bool nonceCheck;            // 检查订单nonce
        uint256 orderAmount;        // offer的Nft资产总量
        uint256 remainingAmount;    // remainingAmount返回剩余未成交的数量
        bool remainingAmountCheck;  // check `remainingAmount > 0`
        bool feesCheck;             // fee地址不能是0x地址，并且如果有回调，fee地址必须是合约地址
        bool propertiesCheck;       // 属性检查。若order.erc1155Properties不为空,则`order.erc1155TokenId`必须为0，并且property地址必须是address(0)或合约地址
        bool erc20AddressCheck;     // erc20地址检查。该地址必须为一个合约地址，不能是NATIVE_ADDRESS，不能为address(0)
        uint256 erc20TotalAmount;   // erc20TotalAmount = `order.erc20TokenAmount` + totalFeesAmount
        uint256 erc20Balance;       // 买家ERC20余额
        uint256 erc20Allowance;     // 买家ERC20授权额度
        bool erc20BalanceCheck;     // check `erc20Balance >= erc20TotalAmount`
        bool erc20AllowanceCheck;   // check `erc20AllowanceCheck >= erc20TotalAmount`
    }

    function checkERC721BuyOrderV2(
        LibNFTOrder.NFTBuyOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata data
    ) external view returns (
        BuyOrderCheckInfo memory info,
        bool validSignature
    );

    function checkERC1155BuyOrderV2(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata data
    ) external view returns (
        BuyOrderCheckInfo memory info,
        bool validSignature
    );

    function getERC721BuyOrderInfo(
        LibNFTOrder.NFTBuyOrder calldata order
    ) external view returns (
        LibNFTOrder.OrderInfo memory orderInfo
    );

    function validateERC721BuyOrderSignatureV2(
        LibNFTOrder.NFTBuyOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata data
    ) external view returns (bool valid);

    function validateERC1155BuyOrderSignatureV2(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        LibSignature.Signature calldata signature,
        bytes calldata data
    ) external view returns (bool valid);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface ISDKApproveCheckerFeature {

    struct SDKApproveInfo {
        uint8 tokenType; // 0: ERC721, 1: ERC1155, 2: ERC20, 255: other
        address tokenAddress;
        address operator;
    }

    function getSDKApprovalsAndCounter(
        address account,
        SDKApproveInfo[] calldata list
    )
        external
        view
        returns (uint256[] memory approvals, uint256 elementCounter, uint256 seaportCounter);

    function getSDKApprovalsAndCounterV2(
        address seaport,
        address account,
        SDKApproveInfo[] calldata list
    )
        external
        view
        returns (uint256[] memory approvals, uint256 elementCounter, uint256 seaportCounter);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface ISweepHelperFeature {

    struct SwpHelpParam {
        address erc20Token;
        uint256 amountIn;
        uint24 fee;
    }

    struct SwpRateInfo {
        address token;
        uint256 tokenOutAmount;
    }

    struct SwpHelpInfo {
        address erc20Token;
        uint256 balance;
        uint256 allowance;
        uint8 decimals;
        SwpRateInfo[] rates;
    }

    function getSwpHelpInfos(
        address account,
        address operator,
        SwpHelpParam[] calldata params
    ) external returns (SwpHelpInfo[] memory infos);

    struct SwpHelpInfoEx {
        address erc20Token;
        uint256 balance;
        uint8 decimals;
        uint256[] allowances;
        SwpRateInfo[] rates;
    }

    function getSwpHelpInfosEx(
        address account,
        address[] calldata operators,
        SwpHelpParam[] calldata params
    ) external returns (SwpHelpInfoEx[] memory infos);

    struct SwpAssetInfo {
        address account;
        uint8 itemType;
        address token;
        uint256 tokenId;
    }

    function getAssetsBalance(SwpAssetInfo[] calldata assets) external view returns (uint256[] memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IPropertyValidator {
    function validateProperty(
        address tokenAddress,
        uint256 tokenId,
        bytes32 orderHash,
        bytes calldata propertyData,
        bytes calldata takerData
    ) external view returns(bytes4);
}

library LibSignature {

    enum SignatureType {
        EIP712,
        PRESIGNED,
        EIP712_BULK
    }

    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }
}

library LibNFTOrder {

    enum OrderStatus {
        INVALID,
        FILLABLE,
        UNFILLABLE,
        EXPIRED
    }

    struct Property {
        IPropertyValidator propertyValidator;
        bytes propertyData;
    }

    struct Fee {
        address recipient;
        uint256 amount;
        bytes feeData;
    }

    struct NFTSellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
    }

    // All fields except `nftProperties` align
    // with those of NFTSellOrder
    struct NFTBuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
        Property[] nftProperties;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTSellOrder
    struct ERC1155SellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    // All fields except `erc1155TokenAmount` align
    // with those of NFTBuyOrder
    struct ERC1155BuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address erc1155Token;
        uint256 erc1155TokenId;
        Property[] erc1155TokenProperties;
        // End of fields shared with NFTOrder
        uint128 erc1155TokenAmount;
    }

    struct OrderInfo {
        bytes32 orderHash;
        OrderStatus status;
        // `orderAmount` is 1 for all ERC721Orders, and
        // `erc1155TokenAmount` for ERC1155Orders.
        uint128 orderAmount;
        // The remaining amount of the ERC721/ERC1155 asset
        // that can be filled for the order.
        uint128 remainingAmount;
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ISweepHelperFeature.sol";
import "./IPancakeRouter.sol";
import "./IUniswapQuoter.sol";


contract SweepHelperFeature is ISweepHelperFeature {

    address public immutable WETH;
    IPancakeRouter public immutable PancakeRouter;
    IUniswapQuoter public immutable UniswapQuoter;

    constructor(address weth, IPancakeRouter pancakeRouter, IUniswapQuoter uniswapQuoter) {
        WETH = weth;
        PancakeRouter = pancakeRouter;
        UniswapQuoter = uniswapQuoter;
    }

    function getSwpHelpInfos(
        address account,
        address operator,
        SwpHelpParam[] calldata params
    ) external override returns (SwpHelpInfo[] memory infos) {
        address[] memory path = new address[](2);

        infos = new SwpHelpInfo[](params.length);
        for (uint256 i; i < params.length; i++) {
            address erc20Token = params[i].erc20Token;

            infos[i].erc20Token = erc20Token;
            if (erc20Token == address(0)) {
                infos[i].balance = account.balance;
                infos[i].allowance = type(uint256).max;
            } else {
                infos[i].balance = balanceOf(erc20Token, account);
                infos[i].allowance = allowanceOf(erc20Token, account, operator);
            }
            infos[i].decimals = decimals(erc20Token);
            uint256 amountIn = 10 ** infos[i].decimals;

            SwpRateInfo[] memory rates = new SwpRateInfo[](params.length);
            for (uint256 j; j < params.length; j++) {
                address token = params[j].erc20Token;
                rates[j].token = token;
                if (
                    token == erc20Token ||
                    token == address(0) && erc20Token == WETH ||
                    token == WETH && erc20Token == address(0)
                ) {
                    rates[j].tokenOutAmount = amountIn;
                    continue;
                }

                address tokenA = erc20Token == address(0) ? WETH : erc20Token;
                address tokenB = token == address(0) ? WETH : token;
                if (address(PancakeRouter) != address(0)) {
                    path[0] = tokenA;
                    path[1] = tokenB;
                    rates[j].tokenOutAmount = getAmountsOut(amountIn, path);
                } else if (address(UniswapQuoter) != address(0)) {
                    rates[j].tokenOutAmount = quoteExactInputSingle(tokenA, tokenB, params[i].fee, amountIn);
                }
            }
            infos[i].rates = rates;
        }
        return infos;
    }

    function getSwpHelpInfosEx(
        address account,
        address[] calldata operators,
        SwpHelpParam[] calldata params
    ) external override returns (SwpHelpInfoEx[] memory infos) {
        address[] memory path = new address[](2);
        infos = new SwpHelpInfoEx[](params.length);
        for (uint256 i; i < params.length; i++) {
            address erc20Token = params[i].erc20Token;

            infos[i].erc20Token = erc20Token;
            if (erc20Token == address(0)) {
                infos[i].balance = account.balance;
            } else {
                infos[i].balance = balanceOf(erc20Token, account);
            }

            uint256[] memory allowances = new uint256[](operators.length);
            for (uint256 j; j < operators.length; j++) {
                if (erc20Token == address(0)) {
                    allowances[j] = type(uint256).max;
                } else {
                    allowances[j] = allowanceOf(erc20Token, account, operators[j]);
                }
            }

            infos[i].allowances = allowances;
            infos[i].decimals = decimals(erc20Token);
            uint256 amountIn = 10 ** infos[i].decimals;

            SwpRateInfo[] memory rates = new SwpRateInfo[](params.length);
            for (uint256 j; j < params.length; j++) {
                address token = params[j].erc20Token;
                rates[j].token = token;
                if (
                    token == erc20Token ||
                    token == address(0) && erc20Token == WETH ||
                    token == WETH && erc20Token == address(0)
                ) {
                    rates[j].tokenOutAmount = amountIn;
                    continue;
                }

                address tokenA = erc20Token == address(0) ? WETH : erc20Token;
                address tokenB = token == address(0) ? WETH : token;
                if (address(PancakeRouter) != address(0)) {
                    path[0] = tokenA;
                    path[1] = tokenB;
                    rates[j].tokenOutAmount = getAmountsOut(amountIn, path);
                } else if (address(UniswapQuoter) != address(0)) {
                    rates[j].tokenOutAmount = quoteExactInputSingle(tokenA, tokenB, params[i].fee, amountIn);
                }
            }
            infos[i].rates = rates;
        }
        return infos;
    }

    function getAssetsBalance(SwpAssetInfo[] calldata assets) external view override returns (uint256[] memory) {
        uint256[] memory infos = new uint256[](assets.length);
        for (uint256 i; i < assets.length; i++) {
            address account = assets[i].account;
            address token = assets[i].token;
            uint256 tokenId = assets[i].tokenId;
            uint8 itemType = assets[i].itemType;

            if (itemType == 0) {
                infos[i] = (ownerOf(token, tokenId) == account) ? 1 : 0;
                continue;
            }

            if (itemType == 1) {
                infos[i] = balanceOf(token, account, tokenId);
                continue;
            }

            if (itemType == 2) {
                if (token == address(0)) {
                    infos[i] = account.balance;
                } else {
                    infos[i] = balanceOf(token, account);
                }
            }
        }
        return infos;
    }

    function ownerOf(address nft, uint256 tokenId) internal view returns (address owner) {
        try IERC721(nft).ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {
        }
        return owner;
    }

    function balanceOf(address nft, address account, uint256 id) internal view returns (uint256 balance) {
        try IERC1155(nft).balanceOf(account, id) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }

    function balanceOf(address erc20, address account) internal view returns (uint256 balance) {
        try IERC20(erc20).balanceOf(account) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }

    function decimals(address erc20) internal view returns (uint8) {
        if (erc20 == address(0) || erc20 == WETH) {
            return 18;
        }
        try IERC20Metadata(erc20).decimals() returns (uint8 _decimals) {
            return _decimals;
        } catch {
        }
        return 18;
    }

    function allowanceOf(address erc20, address owner, address spender) internal view returns (uint256 allowance) {
        if (spender != address(0)) {
            try IERC20(erc20).allowance(owner, spender) returns (uint256 _allowance) {
                allowance = _allowance;
            } catch {
            }
        }
        return allowance;
    }

    function getAmountsOut(uint256 amountIn, address[] memory path) internal view returns (uint256 amount) {
        try PancakeRouter.getAmountsOut(amountIn, path) returns (uint256[] memory _amounts) {
            amount = _amounts[1];
        } catch {
        }
        return amount;
    }

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn
    ) internal returns (uint256 amountOut) {
        try UniswapQuoter.quoteExactInputSingle(
            tokenIn,
            tokenOut,
            fee,
            amountIn,
            0
        ) returns (uint256 _amountOut) {
            amountOut = _amountOut;
        } catch {
        }
        return amountOut;
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IPancakeRouter {

    function factory() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IUniswapQuoter {

    function quoteExactInputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountIn,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountOut);

    function quoteExactOutputSingle(
        address tokenIn,
        address tokenOut,
        uint24 fee,
        uint256 amountOut,
        uint160 sqrtPriceLimitX96
    ) external returns (uint256 amountIn);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IElementExCheckerFeature.sol";

interface IERC721OrdersFeature {
    function validateERC721SellOrderSignature(LibNFTOrder.NFTSellOrder calldata order, LibSignature.Signature calldata signature) external view;
    function validateERC721BuyOrderSignature(LibNFTOrder.NFTBuyOrder calldata order, LibSignature.Signature calldata signature) external view;
    function getERC721SellOrderHash(LibNFTOrder.NFTSellOrder calldata order) external view returns (bytes32);
    function getERC721BuyOrderHash(LibNFTOrder.NFTBuyOrder calldata order) external view returns (bytes32);
    function getERC721OrderStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
    function getHashNonce(address maker) external view returns (uint256);
}

interface IERC1155OrdersFeature {
    function validateERC1155SellOrderSignature(LibNFTOrder.ERC1155SellOrder calldata order, LibSignature.Signature calldata signature) external view;
    function validateERC1155BuyOrderSignature(LibNFTOrder.ERC1155BuyOrder calldata order, LibSignature.Signature calldata signature) external view;
    function getERC1155SellOrderInfo(LibNFTOrder.ERC1155SellOrder calldata order) external view returns (LibNFTOrder.OrderInfo memory orderInfo);
    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder calldata order) external view returns (LibNFTOrder.OrderInfo memory orderInfo);
    function getERC1155OrderNonceStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
}

contract ElementExCheckerFeature is IElementExCheckerFeature {

    using Address for address;

    address constant internal NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable ELEMENT_EX;

    constructor(address elementEx) {
        ELEMENT_EX = elementEx;
    }

    function checkERC721SellOrder(LibNFTOrder.NFTSellOrder calldata order, address taker)
        public
        override
        view
        returns (ERC721SellOrderCheckInfo memory info, ERC20CheckInfo memory takerCheckInfo)
    {
        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = getERC721SellOrderHash(order);
        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.extraCheck = checkExtra(order.expiry);
        info.nonceCheck = !isERC721OrderNonceFilled(order.maker, order.nonce);
        info.feesCheck = checkFees(order.fees);
        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);
        info.erc721OwnerCheck = checkERC721Owner(order.nft, order.nftId, order.maker);
        info.erc721ApprovedCheck = checkERC721Approved(order.nft, order.nftId, order.maker);
        info.erc20AddressCheck = checkERC20Address(true, address(order.erc20Token));
        info.erc721AddressCheck = checkERC721Address(order.nft);
        info.success = _isERC721SellOrderSuccess(info);

        if (taker != address(0)) {
            takerCheckInfo.listingTimeCheck = (block.timestamp >= ((order.expiry >> 32) & 0xffffffff));
            takerCheckInfo.takerCheck = (order.taker == taker || order.taker == address(0));
            (takerCheckInfo.balanceCheck, takerCheckInfo.balance) =
                checkERC20Balance(true, taker, address(order.erc20Token), info.erc20TotalAmount);
            (takerCheckInfo.allowanceCheck, takerCheckInfo.allowance) =
                checkERC20Allowance(true, taker, address(order.erc20Token), info.erc20TotalAmount);
        }
        return (info, takerCheckInfo);
    }

    function checkERC721SellOrderEx(
        LibNFTOrder.NFTSellOrder calldata order,
        address taker,
        LibSignature.Signature calldata signature
    )
        public
        override
        view
        returns (ERC721SellOrderCheckInfo memory info, ERC20CheckInfo memory takerCheckInfo, bool validSignature)
    {
        (info, takerCheckInfo) = checkERC721SellOrder(order, taker);
        validSignature = validateERC721SellOrderSignature(order, signature);
        return (info, takerCheckInfo, validSignature);
    }

    function checkERC721BuyOrder(LibNFTOrder.NFTBuyOrder calldata order, address taker, uint256 erc721TokenId)
        public
        view
        returns (ERC721BuyOrderCheckInfo memory info, ERC721CheckInfo memory takerCheckInfo)
    {
        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = getERC721BuyOrderHash(order);
        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.nonceCheck = !isERC721OrderNonceFilled(order.maker, order.nonce);
        info.feesCheck = checkFees(order.fees);
        info.propertiesCheck = checkProperties(order.nftProperties, order.nftId);
        info.erc20AddressCheck = checkERC20Address(false, address(order.erc20Token));
        info.erc721AddressCheck = checkERC721Address(order.nft);

        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);
        (info.erc20BalanceCheck, info.erc20Balance) =
            checkERC20Balance(false, order.maker, address(order.erc20Token), info.erc20TotalAmount);
        (info.erc20AllowanceCheck, info.erc20Allowance) =
            checkERC20Allowance(false, order.maker, address(order.erc20Token), info.erc20TotalAmount);
        info.success = _isERC721BuyOrderSuccess(info);

        if (taker != address(0)) {
            takerCheckInfo.listingTimeCheck = (block.timestamp >= ((order.expiry >> 32) & 0xffffffff));
            takerCheckInfo.takerCheck = (order.taker == taker || order.taker == address(0));
            takerCheckInfo.ecr721TokenIdCheck = checkNftIdIsMatched(order.nftProperties, order.nft, order.nftId, erc721TokenId);
            takerCheckInfo.erc721OwnerCheck = checkERC721Owner(order.nft, erc721TokenId, taker);
            takerCheckInfo.erc721ApprovedCheck = checkERC721Approved(order.nft, erc721TokenId, taker);
        }
        return (info, takerCheckInfo);
    }

    function checkERC721BuyOrderEx(
        LibNFTOrder.NFTBuyOrder calldata order,
        address taker,
        uint256 erc721TokenId,
        LibSignature.Signature calldata signature
    )
        public
        override
        view
        returns (ERC721BuyOrderCheckInfo memory info, ERC721CheckInfo memory takerCheckInfo, bool validSignature)
    {
        (info, takerCheckInfo) = checkERC721BuyOrder(order, taker, erc721TokenId);
        validSignature = validateERC721BuyOrderSignature(order, signature);
        return (info, takerCheckInfo, validSignature);
    }

    function checkERC1155SellOrder(LibNFTOrder.ERC1155SellOrder calldata order, address taker, uint128 erc1155BuyAmount)
        public
        override
        view
        returns (ERC1155SellOrderCheckInfo memory info, ERC1155SellOrderTakerCheckInfo memory takerCheckInfo)
    {
        LibNFTOrder.OrderInfo memory orderInfo = getERC1155SellOrderInfo(order);
        (uint256 balance, bool isApprovedForAll) = getERC1155Info(order.erc1155Token, order.erc1155TokenId, order.maker, ELEMENT_EX);

        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = orderInfo.orderHash;
        info.erc1155RemainingAmount = orderInfo.remainingAmount;
        info.erc1155Balance = balance;
        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.extraCheck = checkExtra(order.expiry);
        info.nonceCheck = !isERC1155OrderNonceCancelled(order.maker, order.nonce);
        info.remainingAmountCheck = (info.erc1155RemainingAmount > 0);
        info.feesCheck = checkFees(order.fees);
        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);
        info.erc1155BalanceCheck = (balance >= order.erc1155TokenAmount);
        info.erc1155ApprovedCheck = isApprovedForAll;
        info.erc20AddressCheck = checkERC20Address(true, address(order.erc20Token));
        info.erc1155AddressCheck = checkERC1155Address(order.erc1155Token);
        info.success = _isERC1155SellOrderSuccess(info);

        if (taker != address(0)) {
            if (order.erc1155TokenAmount > 0) {
                takerCheckInfo.erc20WillPayAmount = _ceilDiv(order.erc20TokenAmount * erc1155BuyAmount, order.erc1155TokenAmount);
                for (uint256 i = 0; i < order.fees.length; i++) {
                    takerCheckInfo.erc20WillPayAmount += order.fees[i].amount * erc1155BuyAmount / order.erc1155TokenAmount;
                }
            } else {
                takerCheckInfo.erc20WillPayAmount = type(uint128).max;
            }
            (takerCheckInfo.balanceCheck, takerCheckInfo.erc20Balance) = checkERC20Balance(true, taker, address(order.erc20Token), takerCheckInfo.erc20WillPayAmount);
            (takerCheckInfo.allowanceCheck, takerCheckInfo.erc20Allowance) = checkERC20Allowance(true, taker, address(order.erc20Token), takerCheckInfo.erc20WillPayAmount);
            takerCheckInfo.buyAmountCheck = (erc1155BuyAmount <= info.erc1155RemainingAmount);
            takerCheckInfo.listingTimeCheck = (block.timestamp >= ((order.expiry >> 32) & 0xffffffff));
            takerCheckInfo.takerCheck = (order.taker == taker || order.taker == address(0));
        }
        return (info, takerCheckInfo);
    }

    function checkERC1155SellOrderEx(
        LibNFTOrder.ERC1155SellOrder calldata order,
        address taker,
        uint128 erc1155BuyAmount,
        LibSignature.Signature calldata signature
    )
        public
        override
        view
        returns (ERC1155SellOrderCheckInfo memory info, ERC1155SellOrderTakerCheckInfo memory takerCheckInfo, bool validSignature)
    {
        (info, takerCheckInfo) = checkERC1155SellOrder(order, taker, erc1155BuyAmount);
        validSignature = validateERC1155SellOrderSignature(order, signature);
        return (info, takerCheckInfo, validSignature);
    }

    function checkERC1155BuyOrder(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount
    )
        public
        override
        view
        returns (ERC1155BuyOrderCheckInfo memory info, ERC1155BuyOrderTakerCheckInfo memory takerCheckInfo)
    {
        LibNFTOrder.OrderInfo memory orderInfo = getERC1155BuyOrderInfo(order);
        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = orderInfo.orderHash;
        info.erc1155RemainingAmount = orderInfo.remainingAmount;
        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.nonceCheck = !isERC1155OrderNonceCancelled(order.maker, order.nonce);
        info.remainingAmountCheck = (info.erc1155RemainingAmount > 0);
        info.feesCheck = checkFees(order.fees);
        info.propertiesCheck = checkProperties(order.erc1155TokenProperties, order.erc1155TokenId);
        info.erc20AddressCheck = checkERC20Address(false, address(order.erc20Token));
        info.erc1155AddressCheck = checkERC1155Address(order.erc1155Token);
        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);
        (info.erc20BalanceCheck, info.erc20Balance) = checkERC20Balance(false, order.maker, address(order.erc20Token), info.erc20TotalAmount);
        (info.erc20AllowanceCheck, info.erc20Allowance) = checkERC20Allowance(false, order.maker, address(order.erc20Token), info.erc20TotalAmount);
        info.success = _isERC1155BuyOrderSuccess(info);

        if (taker != address(0)) {
            takerCheckInfo.ecr1155TokenIdCheck = checkNftIdIsMatched(order.erc1155TokenProperties, order.erc1155Token, order.erc1155TokenId, erc1155TokenId);
            (takerCheckInfo.erc1155Balance, takerCheckInfo.erc1155ApprovedCheck) = getERC1155Info(order.erc1155Token, erc1155TokenId, taker, ELEMENT_EX);
            takerCheckInfo.erc1155BalanceCheck = (erc1155SellAmount <= takerCheckInfo.erc1155Balance);
            takerCheckInfo.sellAmountCheck = (erc1155SellAmount <= info.erc1155RemainingAmount);
            takerCheckInfo.listingTimeCheck = (block.timestamp >= ((order.expiry >> 32) & 0xffffffff));
            takerCheckInfo.takerCheck = (order.taker == taker || order.taker == address(0));
        }
        return (info, takerCheckInfo);
    }

    function checkERC1155BuyOrderEx(
        LibNFTOrder.ERC1155BuyOrder calldata order,
        address taker,
        uint256 erc1155TokenId,
        uint128 erc1155SellAmount,
        LibSignature.Signature calldata signature
    )
        public
        override
        view
        returns (ERC1155BuyOrderCheckInfo memory info, ERC1155BuyOrderTakerCheckInfo memory takerCheckInfo, bool validSignature)
    {
        (info, takerCheckInfo) = checkERC1155BuyOrder(order, taker, erc1155TokenId, erc1155SellAmount);
        validSignature = validateERC1155BuyOrderSignature(order, signature);
        return (info, takerCheckInfo, validSignature);
    }

    function getERC20Info(address erc20, address account, address allowanceAddress)
        internal
        view
        returns (uint256 balance, uint256 allowance)
    {
        if (erc20 == address(0) || erc20 == NATIVE_TOKEN_ADDRESS) {
            balance = address(account).balance;
        } else {
            try IERC20(erc20).balanceOf(account) returns (uint256 _balance) {
                balance = _balance;
            } catch {}
            try IERC20(erc20).allowance(account, allowanceAddress) returns (uint256 _allowance) {
                allowance = _allowance;
            } catch {}
        }
        return (balance, allowance);
    }

    function getERC721Info(address erc721, uint256 tokenId, address account, address approvedAddress)
        internal
        view
        returns (address owner, bool isApprovedForAll, address approvedAccount)
    {
        try IERC721(erc721).ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {}
        try IERC721(erc721).isApprovedForAll(account, approvedAddress) returns (bool _isApprovedForAll) {
            isApprovedForAll = _isApprovedForAll;
        } catch {}
        try IERC721(erc721).getApproved(tokenId) returns (address _account) {
            approvedAccount = _account;
        } catch {}
        return (owner, isApprovedForAll, approvedAccount);
    }

    function getERC1155Info(address erc1155, uint256 tokenId, address account, address approvedAddress)
        internal
        view
        returns (uint256 balance, bool isApprovedForAll)
    {
        try IERC1155(erc1155).balanceOf(account, tokenId) returns (uint256 _balance) {
            balance = _balance;
        } catch {}
        try IERC1155(erc1155).isApprovedForAll(account, approvedAddress) returns (bool _isApprovedForAll) {
            isApprovedForAll = _isApprovedForAll;
        } catch {}
        return (balance, isApprovedForAll);
    }

    function validateERC721SellOrderSignature(LibNFTOrder.NFTSellOrder calldata order, LibSignature.Signature calldata signature)
        public
        override
        view
        returns (bool valid)
    {
        try IERC721OrdersFeature(ELEMENT_EX).validateERC721SellOrderSignature(order, signature) {
            return true;
        } catch {}
        return false;
    }

    function validateERC721BuyOrderSignature(LibNFTOrder.NFTBuyOrder calldata order, LibSignature.Signature calldata signature)
        public
        override
        view
        returns (bool valid)
    {
        try IERC721OrdersFeature(ELEMENT_EX).validateERC721BuyOrderSignature(order, signature) {
            return true;
        } catch {}
        return false;
    }

    function getERC721SellOrderHash(LibNFTOrder.NFTSellOrder calldata order) public override view returns (bytes32) {
        try IERC721OrdersFeature(ELEMENT_EX).getERC721SellOrderHash(order) returns (bytes32 orderHash) {
            return orderHash;
        } catch {}
        return bytes32("");
    }

    function getERC721BuyOrderHash(LibNFTOrder.NFTBuyOrder calldata order) public override view returns (bytes32) {
        try IERC721OrdersFeature(ELEMENT_EX).getERC721BuyOrderHash(order) returns (bytes32 orderHash) {
            return orderHash;
        } catch {}
        return bytes32("");
    }

    function isERC721OrderNonceFilled(address account, uint256 nonce) public override view returns (bool filled) {
        uint256 bitVector = IERC721OrdersFeature(ELEMENT_EX).getERC721OrderStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) != 0;
    }

    function isERC1155OrderNonceCancelled(address account, uint256 nonce) public override view returns (bool filled) {
        uint256 bitVector = IERC1155OrdersFeature(ELEMENT_EX).getERC1155OrderNonceStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) != 0;
    }

    function getHashNonce(address maker) public override view returns (uint256) {
        return IERC721OrdersFeature(ELEMENT_EX).getHashNonce(maker);
    }

    function getERC1155SellOrderInfo(LibNFTOrder.ERC1155SellOrder calldata order)
        public
        override
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo)
    {
        try IERC1155OrdersFeature(ELEMENT_EX).getERC1155SellOrderInfo(order) returns (LibNFTOrder.OrderInfo memory _orderInfo) {
            orderInfo = _orderInfo;
        } catch {}
        return orderInfo;
    }

    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder calldata order)
        public
        override
        view
        returns (LibNFTOrder.OrderInfo memory orderInfo)
    {
        try IERC1155OrdersFeature(ELEMENT_EX).getERC1155BuyOrderInfo(order) returns (LibNFTOrder.OrderInfo memory _orderInfo) {
            orderInfo = _orderInfo;
        } catch {}
        return orderInfo;
    }

    function validateERC1155SellOrderSignature(LibNFTOrder.ERC1155SellOrder calldata order, LibSignature.Signature calldata signature)
        public
        override
        view
        returns (bool valid)
    {
        try IERC1155OrdersFeature(ELEMENT_EX).validateERC1155SellOrderSignature(order, signature) {
            return true;
        } catch {}
        return false;
    }

    function validateERC1155BuyOrderSignature(LibNFTOrder.ERC1155BuyOrder calldata order, LibSignature.Signature calldata signature)
        public
        override
        view
        returns (bool valid)
    {
        try IERC1155OrdersFeature(ELEMENT_EX).validateERC1155BuyOrderSignature(order, signature) {
            return true;
        } catch {}
        return false;
    }

    function _isERC721SellOrderSuccess(ERC721SellOrderCheckInfo memory info) private pure returns (bool successAll) {
        return info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.extraCheck &&
            info.nonceCheck &&
            info.feesCheck &&
            info.erc721OwnerCheck &&
            info.erc721ApprovedCheck &&
            info.erc20AddressCheck;
    }

    function _isERC721BuyOrderSuccess(ERC721BuyOrderCheckInfo memory info) private pure returns (bool successAll) {
        return info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.nonceCheck &&
            info.feesCheck &&
            info.propertiesCheck &&
            info.erc20BalanceCheck &&
            info.erc20AllowanceCheck &&
            info.erc20AddressCheck;
    }

    function _isERC1155SellOrderSuccess(ERC1155SellOrderCheckInfo memory info) private pure returns (bool successAll) {
        return info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.extraCheck &&
            info.nonceCheck &&
            info.remainingAmountCheck &&
            info.feesCheck &&
            info.erc20AddressCheck &&
            info.erc1155BalanceCheck &&
            info.erc1155ApprovedCheck;
    }

    function _isERC1155BuyOrderSuccess(ERC1155BuyOrderCheckInfo memory info) private pure returns (bool successAll) {
        return info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.nonceCheck &&
            info.remainingAmountCheck &&
            info.feesCheck &&
            info.propertiesCheck &&
            info.erc20AddressCheck &&
            info.erc20BalanceCheck &&
            info.erc20AllowanceCheck;
    }

    function checkListingTime(uint256 expiry) internal pure returns (bool success) {
        uint256 listingTime = (expiry >> 32) & 0xffffffff;
        uint256 expiryTime = expiry & 0xffffffff;
        return listingTime < expiryTime;
    }

    function checkExpiryTime(uint256 expiry) internal view returns (bool success) {
        uint256 expiryTime = expiry & 0xffffffff;
        return expiryTime > block.timestamp;
    }

    function checkExtra(uint256 expiry) internal pure returns (bool success) {
        if (expiry >> 252 == 1) {
            uint256 extra = (expiry >> 64) & 0xffffffff;
            return (extra <= 100000000);
        }
        return true;
    }

    function checkERC721Owner(address nft, uint256 nftId, address owner) internal view returns (bool success) {
        try IERC721(nft).ownerOf(nftId) returns (address _owner) {
            success = (owner == _owner);
        } catch {
            success = false;
        }
        return success;
    }

    function checkERC721Approved(address nft, uint256 nftId, address owner) internal view returns (bool) {
        try IERC721(nft).isApprovedForAll(owner, ELEMENT_EX) returns (bool approved) {
            if (approved) {
                return true;
            }
        } catch {
        }
        try IERC721(nft).getApproved(nftId) returns (address account) {
            return (account == ELEMENT_EX);
        } catch {
        }
        return false;
    }

    function checkERC20Balance(bool buyNft, address buyer, address erc20, uint256 erc20TotalAmount)
        internal
        view
        returns
        (bool success, uint256 balance)
    {
        if (erc20 == address(0)) {
            return (false, 0);
        }
        if (erc20 == NATIVE_TOKEN_ADDRESS) {
            if (buyNft) {
                balance = buyer.balance;
                success = (balance >= erc20TotalAmount);
                return (success, balance);
            } else {
                return (false, 0);
            }
        }

        try IERC20(erc20).balanceOf(buyer) returns (uint256 _balance) {
            balance = _balance;
            success = (balance >= erc20TotalAmount);
        } catch {
            success = false;
            balance = 0;
        }
        return (success, balance);
    }

    function checkERC20Allowance(bool buyNft, address buyer, address erc20, uint256 erc20TotalAmount)
        internal
        view
        returns
        (bool success, uint256 allowance)
    {
        if (erc20 == address(0)) {
            return (false, 0);
        }
        if (erc20 == NATIVE_TOKEN_ADDRESS) {
            return (buyNft, 0);
        }

        try IERC20(erc20).allowance(buyer, ELEMENT_EX) returns (uint256 _allowance) {
            allowance = _allowance;
            success = (allowance >= erc20TotalAmount);
        } catch {
            success = false;
            allowance = 0;
        }
        return (success, allowance);
    }

    function checkERC20Address(bool sellOrder, address erc20) internal view returns (bool) {
        if (erc20 == address(0)) {
            return false;
        }
        if (erc20 == NATIVE_TOKEN_ADDRESS) {
            return sellOrder;
        }
        return erc20.isContract();
    }

    function checkERC721Address(address erc721) internal view returns (bool) {
        if (erc721 == address(0) || erc721 == NATIVE_TOKEN_ADDRESS) {
            return false;
        }

        try IERC165(erc721).supportsInterface(type(IERC721).interfaceId) returns (bool support) {
            return support;
        } catch {}
        return false;
    }

    function checkERC1155Address(address erc1155) internal view returns (bool) {
        if (erc1155 == address(0) || erc1155 == NATIVE_TOKEN_ADDRESS) {
            return false;
        }

        try IERC165(erc1155).supportsInterface(type(IERC1155).interfaceId) returns (bool support) {
            return support;
        } catch {}
        return false;
    }

    function checkFees(LibNFTOrder.Fee[] calldata fees) internal view returns (bool success) {
        for (uint256 i = 0; i < fees.length; i++) {
            if (fees[i].recipient == ELEMENT_EX) {
                return false;
            }
            if (fees[i].feeData.length > 0 && !fees[i].recipient.isContract()) {
                return false;
            }
        }
        return true;
    }

    function checkProperties(LibNFTOrder.Property[] calldata properties, uint256 nftId) internal view returns (bool success) {
        if (properties.length > 0) {
            if (nftId != 0) {
                return false;
            }
            for (uint256 i = 0; i < properties.length; i++) {
                address propertyValidator = address(properties[i].propertyValidator);
                if (propertyValidator != address(0) && !propertyValidator.isContract()) {
                    return false;
                }
            }
        }
        return true;
    }

    function checkNftIdIsMatched(LibNFTOrder.Property[] calldata properties, address nft, uint256 orderNftId, uint256 nftId)
        internal
        view
        returns (bool isMatched)
    {
        if (properties.length == 0) {
            return orderNftId == nftId;
        }
        return true;
    }

    function calcERC20TotalAmount(uint256 erc20TokenAmount, LibNFTOrder.Fee[] calldata fees) internal pure returns (uint256) {
        uint256 sum = erc20TokenAmount;
        for (uint256 i = 0; i < fees.length; i++) {
            sum += fees[i].amount;
        }
        return sum;
    }

    function _ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // ceil(a / b) = floor((a + b - 1) / b)
        return (a + b - 1) / b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IElementExCheckerFeatureV2.sol";

interface IERC721OrdersFeature {
    function validateERC721BuyOrderSignature(LibNFTOrder.NFTBuyOrder calldata order, LibSignature.Signature calldata signature, bytes calldata takerData) external view;
    function getERC721BuyOrderInfo(LibNFTOrder.NFTBuyOrder calldata order) external view returns (LibNFTOrder.OrderInfo memory);
    function getERC721OrderStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
    function getHashNonce(address maker) external view returns (uint256);
}

interface IERC1155OrdersFeature {
    function validateERC1155BuyOrderSignature(LibNFTOrder.ERC1155BuyOrder calldata order, LibSignature.Signature calldata signature, bytes calldata takerData) external view;
    function getERC1155BuyOrderInfo(LibNFTOrder.ERC1155BuyOrder calldata order) external view returns (LibNFTOrder.OrderInfo memory orderInfo);
    function getERC1155OrderNonceStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
}

contract ElementExCheckerFeatureV2 is IElementExCheckerFeatureV2 {

    using Address for address;

    address constant internal NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public immutable ELEMENT_EX;

    constructor(address elementEx) {
        ELEMENT_EX = elementEx;
    }

    function checkERC721BuyOrderV2(
        LibNFTOrder.NFTBuyOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory data
    ) external override view returns (
        BuyOrderCheckInfo memory info,
        bool validSignature
    ) {
        info.nonceCheck = !isERC721OrderNonceFilled(order.maker, order.nonce);
        info.propertiesCheck = checkProperties(order.expiry >> 252 == 8, order.nftProperties, order.nftId);
        _checkBuyOrder(order, getERC721BuyOrderInfo(order), info);

        validSignature = validateERC721BuyOrderSignatureV2(order, signature, data);
        return (info, validSignature);
    }

    function checkERC1155BuyOrderV2(
        LibNFTOrder.ERC1155BuyOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory data
    ) external override view returns (
        BuyOrderCheckInfo memory info,
        bool validSignature
    ) {
        info.nonceCheck = !isERC1155OrderNonceCancelled(order.maker, order.nonce);
        info.propertiesCheck = checkProperties(false, order.erc1155TokenProperties, order.erc1155TokenId);

        LibNFTOrder.NFTBuyOrder memory nftOrder;
        assembly { nftOrder := order }
        _checkBuyOrder(nftOrder, getERC1155BuyOrderInfo(order), info);

        validSignature = validateERC1155BuyOrderSignatureV2(order, signature, data);
        return (info, validSignature);
    }

    function _checkBuyOrder(
        LibNFTOrder.NFTBuyOrder memory order,
        LibNFTOrder.OrderInfo memory orderInfo,
        BuyOrderCheckInfo memory info
    ) internal view {
        info.hashNonce = getHashNonce(order.maker);
        info.orderHash = orderInfo.orderHash;
        info.orderAmount = orderInfo.orderAmount;
        info.remainingAmount = orderInfo.remainingAmount;
        info.remainingAmountCheck = (info.remainingAmount > 0);

        info.makerCheck = (order.maker != address(0));
        info.takerCheck = (order.taker != ELEMENT_EX);
        info.listingTimeCheck = checkListingTime(order.expiry);
        info.expireTimeCheck = checkExpiryTime(order.expiry);
        info.feesCheck = checkFees(order.fees);

        info.erc20AddressCheck = checkERC20Address(address(order.erc20Token));
        info.erc20TotalAmount = calcERC20TotalAmount(order.erc20TokenAmount, order.fees);

        (
            info.erc20BalanceCheck,
            info.erc20Balance
        ) = checkERC20Balance(order.maker, address(order.erc20Token), info.erc20TotalAmount);

        (
            info.erc20AllowanceCheck,
            info.erc20Allowance
        ) = checkERC20Allowance(order.maker, address(order.erc20Token), info.erc20TotalAmount);

        info.success = (
            info.makerCheck &&
            info.takerCheck &&
            info.listingTimeCheck &&
            info.expireTimeCheck &&
            info.nonceCheck &&
            info.remainingAmountCheck &&
            info.feesCheck &&
            info.propertiesCheck &&
            info.erc20AddressCheck &&
            info.erc20BalanceCheck &&
            info.erc20AllowanceCheck
        );
    }

    function validateERC721BuyOrderSignatureV2(
        LibNFTOrder.NFTBuyOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory data
    ) public override view returns (bool valid) {
        try IERC721OrdersFeature(ELEMENT_EX).validateERC721BuyOrderSignature(order, signature, data) {
            return true;
        } catch {}
        return false;
    }

    function validateERC1155BuyOrderSignatureV2(
        LibNFTOrder.ERC1155BuyOrder memory order,
        LibSignature.Signature memory signature,
        bytes memory data
    ) public override view returns (bool valid) {
        try IERC1155OrdersFeature(ELEMENT_EX).validateERC1155BuyOrderSignature(order, signature, data) {
            return true;
        } catch {}
        return false;
    }

    function getERC721BuyOrderInfo(
        LibNFTOrder.NFTBuyOrder memory order
    ) public override view returns (
        LibNFTOrder.OrderInfo memory orderInfo
    ) {
        try IERC721OrdersFeature(ELEMENT_EX).getERC721BuyOrderInfo(order) returns (LibNFTOrder.OrderInfo memory _orderInfo) {
            orderInfo = _orderInfo;
        } catch {}
        return orderInfo;
    }

    function getERC1155BuyOrderInfo(
        LibNFTOrder.ERC1155BuyOrder memory order
    ) internal view returns (
        LibNFTOrder.OrderInfo memory orderInfo
    ) {
        try IERC1155OrdersFeature(ELEMENT_EX).getERC1155BuyOrderInfo(order) returns (LibNFTOrder.OrderInfo memory _orderInfo) {
            orderInfo = _orderInfo;
        } catch {}
        return orderInfo;
    }

    function isERC721OrderNonceFilled(address account, uint256 nonce) internal view returns (bool filled) {
        uint256 bitVector = IERC721OrdersFeature(ELEMENT_EX).getERC721OrderStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) != 0;
    }

    function isERC1155OrderNonceCancelled(address account, uint256 nonce) internal view returns (bool filled) {
        uint256 bitVector = IERC1155OrdersFeature(ELEMENT_EX).getERC1155OrderNonceStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) != 0;
    }

    function getHashNonce(address maker) internal view returns (uint256) {
        return IERC721OrdersFeature(ELEMENT_EX).getHashNonce(maker);
    }

    function checkListingTime(uint256 expiry) internal pure returns (bool success) {
        uint256 listingTime = (expiry >> 32) & 0xffffffff;
        uint256 expiryTime = expiry & 0xffffffff;
        return listingTime < expiryTime;
    }

    function checkExpiryTime(uint256 expiry) internal view returns (bool success) {
        uint256 expiryTime = expiry & 0xffffffff;
        return expiryTime > block.timestamp;
    }

    function checkERC20Balance(address buyer, address erc20, uint256 erc20TotalAmount)
        internal
        view
        returns
        (bool success, uint256 balance)
    {
        if (erc20 == address(0) || erc20 == NATIVE_TOKEN_ADDRESS) {
            return (false, 0);
        }

        try IERC20(erc20).balanceOf(buyer) returns (uint256 _balance) {
            balance = _balance;
            success = (balance >= erc20TotalAmount);
        } catch {
            success = false;
            balance = 0;
        }
        return (success, balance);
    }

    function checkERC20Allowance(address buyer, address erc20, uint256 erc20TotalAmount)
        internal
        view
        returns
        (bool success, uint256 allowance)
    {
        if (erc20 == address(0) || erc20 == NATIVE_TOKEN_ADDRESS) {
            return (false, 0);
        }

        try IERC20(erc20).allowance(buyer, ELEMENT_EX) returns (uint256 _allowance) {
            allowance = _allowance;
            success = (allowance >= erc20TotalAmount);
        } catch {
            success = false;
            allowance = 0;
        }
        return (success, allowance);
    }

    function checkERC20Address(address erc20) internal view returns (bool) {
        if (erc20 != address(0) && erc20 != NATIVE_TOKEN_ADDRESS) {
            return erc20.isContract();
        }
        return false;
    }

    function checkFees(LibNFTOrder.Fee[] memory fees) internal view returns (bool success) {
        for (uint256 i = 0; i < fees.length; i++) {
            if (fees[i].recipient == ELEMENT_EX) {
                return false;
            }
            if (fees[i].feeData.length > 0 && !fees[i].recipient.isContract()) {
                return false;
            }
        }
        return true;
    }

    function checkProperties(bool isOfferMultiERC721s, LibNFTOrder.Property[] memory properties, uint256 nftId) internal view returns (bool success) {
        if (isOfferMultiERC721s) {
            if (properties.length == 0) {
                return false;
            }
        }
        if (properties.length > 0) {
            if (nftId != 0) {
                return false;
            }
            for (uint256 i = 0; i < properties.length; i++) {
                address propertyValidator = address(properties[i].propertyValidator);
                if (propertyValidator != address(0) && !propertyValidator.isContract()) {
                    return false;
                }
            }
        }
        return true;
    }

    function calcERC20TotalAmount(uint256 erc20TokenAmount, LibNFTOrder.Fee[] memory fees) internal pure returns (uint256) {
        uint256 sum = erc20TokenAmount;
        for (uint256 i = 0; i < fees.length; i++) {
            sum += fees[i].amount;
        }
        return sum;
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IBatchSignedERC721OrdersCheckerFeature.sol";


interface IElement {
    function getERC721OrderStatusBitVector(address maker, uint248 nonceRange) external view returns (uint256);
    function getHashNonce(address maker) external view returns (uint256);
}

contract BatchSignedERC721OrdersCheckerFeature is IBatchSignedERC721OrdersCheckerFeature {

    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    uint256 internal constant MASK_96 = (1 << 96) - 1;
    uint256 internal constant MASK_160 = (1 << 160) - 1;
    uint256 internal constant MASK_224 = (1 << 224) - 1;

    bytes32 public immutable EIP712_DOMAIN_SEPARATOR;
    address public immutable ELEMENT;

    constructor(address element) {
        ELEMENT = element;
        EIP712_DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("ElementEx"),
            keccak256("1.0.0"),
            block.chainid,
            element
        ));
    }

    function checkBSERC721Orders(BSERC721Orders calldata order) external view override returns (BSERC721OrdersCheckResult memory r) {
        uint256 nonce;
        (r.basicCollections, nonce) = _checkBasicCollections(order);
        r.collections = _checkCollections(order, nonce);
        r.hashNonce = _getHashNonce(order.maker);
        r.orderHash = _getOrderHash(order, r.hashNonce);
        r.validSignature = _validateSignature(order, r.orderHash);
        return r;
    }

    function _checkBasicCollections(BSERC721Orders calldata order) internal view returns (BSCollectionCheckResult[] memory basicCollections, uint256 nonce) {
        nonce = order.startNonce;
        basicCollections = new BSCollectionCheckResult[](order.basicCollections.length);

        for (uint256 i; i < basicCollections.length; ) {
            address nftAddress = order.basicCollections[i].nftAddress;
            basicCollections[i].isApprovedForAll = _isApprovedForAll(nftAddress, order.maker);

            BSOrderItemCheckResult[] memory items = new BSOrderItemCheckResult[](order.basicCollections[i].items.length);
            basicCollections[i].items = items;

            for (uint256 j; j < items.length; ) {
                items[j].isNonceValid = _isNonceValid(order.maker, nonce);
                unchecked { ++nonce; }

                items[j].isERC20AmountValid = order.basicCollections[i].items[j].erc20TokenAmount <= MASK_96;
                uint256 nftId = order.basicCollections[i].items[j].nftId;
                if (nftId <= MASK_160) {
                    items[j].ownerOfNftId = _ownerOf(nftAddress, nftId);
                    items[j].approvedAccountOfNftId = _getApproved(nftAddress, nftId);
                } else {
                    items[j].ownerOfNftId = address(0);
                    items[j].approvedAccountOfNftId = address(0);
                }
                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    function _checkCollections(BSERC721Orders calldata order, uint256 nonce) internal view returns (BSCollectionCheckResult[] memory collections) {
        collections = new BSCollectionCheckResult[](order.collections.length);
        for (uint256 i; i < collections.length; ) {
            address nftAddress = order.collections[i].nftAddress;
            collections[i].isApprovedForAll = _isApprovedForAll(nftAddress, order.maker);

            BSOrderItemCheckResult[] memory items = new BSOrderItemCheckResult[](order.collections[i].items.length);
            collections[i].items = items;

            for (uint256 j; j < items.length; ) {
                items[j].isNonceValid = _isNonceValid(order.maker, nonce);
                unchecked { ++nonce; }

                items[j].isERC20AmountValid = order.collections[i].items[j].erc20TokenAmount <= MASK_224;

                uint256 nftId = order.collections[i].items[j].nftId;
                items[j].ownerOfNftId = _ownerOf(nftAddress, nftId);
                items[j].approvedAccountOfNftId = _getApproved(nftAddress, nftId);

                unchecked { ++j; }
            }
            unchecked { ++i; }
        }
    }

    function _validateSignature(BSERC721Orders calldata order, bytes32 orderHash) internal view returns (bool) {
        if (order.maker != address(0)) {
            return (order.maker == ecrecover(orderHash, order.v, order.r, order.s));
        }
        return false;
    }

    function _isApprovedForAll(address nft, address owner) internal view returns (bool isApproved) {
        try IERC721(nft).isApprovedForAll(owner, ELEMENT) returns (bool _isApproved) {
            isApproved = _isApproved;
        } catch {
        }
        return isApproved;
    }

    function _ownerOf(address nft, uint256 tokenId) internal view returns (address owner) {
        try IERC721(nft).ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {
        }
        return owner;
    }

    function _getApproved(address nft, uint256 tokenId) internal view returns (address approvedAccount) {
        try IERC721(nft).getApproved(tokenId) returns (address _approvedAccount) {
            approvedAccount = _approvedAccount;
        } catch {
        }
        return approvedAccount;
    }

    function _isNonceValid(address account, uint256 nonce) internal view returns (bool filled) {
        uint256 bitVector = IElement(ELEMENT).getERC721OrderStatusBitVector(account, uint248(nonce >> 8));
        uint256 flag = 1 << (nonce & 0xff);
        return (bitVector & flag) == 0;
    }

    function _getHashNonce(address maker) internal view returns (uint256) {
        return IElement(ELEMENT).getHashNonce(maker);
    }

    // keccak256(""));
    bytes32 internal constant _EMPTY_ARRAY_KECCAK256 = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    // keccak256(abi.encodePacked(
    //    "BatchSignedERC721Orders(address maker,uint256 listingTime,uint256 expiryTime,uint256 startNonce,address erc20Token,address platformFeeRecipient,BasicCollection[] basicCollections,Collection[] collections,uint256 hashNonce)",
    //    "BasicCollection(address nftAddress,bytes32 fee,bytes32[] items)",
    //    "Collection(address nftAddress,bytes32 fee,OrderItem[] items)",
    //    "OrderItem(uint256 erc20TokenAmount,uint256 nftId)"
    // ))
    bytes32 internal constant _BATCH_SIGNED_ERC721_ORDERS_TYPE_HASH = 0x2d8cbbbc696e7292c3b5beb38e1363d34ff11beb8c3456c14cb938854597b9ed;
    // keccak256("BasicCollection(address nftAddress,bytes32 fee,bytes32[] items)")
    bytes32 internal constant _BASIC_COLLECTION_TYPE_HASH = 0x12ad29288fd70022f26997a9958d9eceb6e840ceaa79b72ea5945ba87e4d33b0;
    // keccak256(abi.encodePacked(
    //    "Collection(address nftAddress,bytes32 fee,OrderItem[] items)",
    //    "OrderItem(uint256 erc20TokenAmount,uint256 nftId)"
    // ))
    bytes32 internal constant _COLLECTION_TYPE_HASH = 0xb9f488d48cec782be9ecdb74330c9c6a33c236a8022d8a91a4e4df4e81b51620;
    // keccak256("OrderItem(uint256 erc20TokenAmount,uint256 nftId)")
    bytes32 internal constant _ORDER_ITEM_TYPE_HASH = 0x5f93394997caa49a9382d44a75e3ce6a460f32b39870464866ac994f8be97afe;

    function _getOrderHash(BSERC721Orders calldata order, uint256 hashNonce) internal view returns (bytes32) {
        bytes32 basicCollectionsHash = _getBasicCollectionsHash(order.basicCollections);
        bytes32 collectionsHash = _getCollectionsHash(order.collections);
        address paymentToken = order.paymentToken;
        if (paymentToken == address(0)) {
            paymentToken = NATIVE_TOKEN_ADDRESS;
        }
        bytes32 structHash = keccak256(abi.encode(
            _BATCH_SIGNED_ERC721_ORDERS_TYPE_HASH,
            order.maker,
            order.listingTime,
            order.expirationTime,
            order.startNonce,
            paymentToken,
            order.platformFeeRecipient,
            basicCollectionsHash,
            collectionsHash,
            hashNonce
        ));
        return keccak256(abi.encodePacked(hex"1901", EIP712_DOMAIN_SEPARATOR, structHash));
    }

    function _getBasicCollectionsHash(BSCollection[] calldata basicCollections) internal pure returns (bytes32 hash) {
        if (basicCollections.length == 0) {
            hash = _EMPTY_ARRAY_KECCAK256;
        } else {
            uint256 num = basicCollections.length;
            bytes32[] memory structHashArray = new bytes32[](num);
            for (uint256 i = 0; i < num; ) {
                structHashArray[i] = _getBasicCollectionHash(basicCollections[i]);
                unchecked { i++; }
            }
            assembly {
                hash := keccak256(add(structHashArray, 0x20), mul(num, 0x20))
            }
        }
    }

    function _getBasicCollectionHash(BSCollection calldata basicCollection) internal pure returns (bytes32) {
        bytes32 itemsHash;
        if (basicCollection.items.length == 0) {
            itemsHash = _EMPTY_ARRAY_KECCAK256;
        } else {
            uint256 num = basicCollection.items.length;
            uint256[] memory structHashArray = new uint256[](num);
            for (uint256 i = 0; i < num; ) {
                uint256 erc20TokenAmount = basicCollection.items[i].erc20TokenAmount;
                uint256 nftId = basicCollection.items[i].nftId;
                if (erc20TokenAmount > MASK_96 || nftId > MASK_160) {
                    structHashArray[i] = 0;
                } else {
                    structHashArray[i] = (erc20TokenAmount << 160) | nftId;
                }
                unchecked { i++; }
            }
            assembly {
                itemsHash := keccak256(add(structHashArray, 0x20), mul(num, 0x20))
            }
        }

        uint256 fee = (basicCollection.platformFee << 176) | (basicCollection.royaltyFee << 160) | uint256(uint160(basicCollection.royaltyFeeRecipient));
        return keccak256(abi.encode(
            _BASIC_COLLECTION_TYPE_HASH,
            basicCollection.nftAddress,
            fee,
            itemsHash
        ));
    }

    function _getCollectionsHash(BSCollection[] calldata collections) internal pure returns (bytes32 hash) {
        if (collections.length == 0) {
            hash = _EMPTY_ARRAY_KECCAK256;
        } else {
            uint256 num = collections.length;
            bytes32[] memory structHashArray = new bytes32[](num);
            for (uint256 i = 0; i < num; ) {
                structHashArray[i] = _getCollectionHash(collections[i]);
                unchecked { i++; }
            }
            assembly {
                hash := keccak256(add(structHashArray, 0x20), mul(num, 0x20))
            }
        }
    }

    function _getCollectionHash(BSCollection calldata collection) internal pure returns (bytes32) {
        bytes32 itemsHash;
        if (collection.items.length == 0) {
            itemsHash = _EMPTY_ARRAY_KECCAK256;
        } else {
            uint256 num = collection.items.length;
            bytes32[] memory structHashArray = new bytes32[](num);
            for (uint256 i = 0; i < num; ) {
                uint256 erc20TokenAmount = collection.items[i].erc20TokenAmount;
                uint256 nftId = collection.items[i].nftId;
                if (erc20TokenAmount > MASK_224) {
                    structHashArray[i] = 0;
                } else {
                    structHashArray[i] = keccak256(abi.encode(_ORDER_ITEM_TYPE_HASH, erc20TokenAmount, nftId));
                }
                unchecked { i++; }
            }
            assembly {
                itemsHash := keccak256(add(structHashArray, 0x20), mul(num, 0x20))
            }
        }

        uint256 fee = (collection.platformFee << 176) | (collection.royaltyFee << 160) | uint256(uint160(collection.royaltyFeeRecipient));
        return keccak256(abi.encode(
            _COLLECTION_TYPE_HASH,
            collection.nftAddress,
            fee,
            itemsHash
        ));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./IENSHelperFeature.sol";
import "./IENSInterface.sol";


contract ENSHelperFeature is IENSHelperFeature {

    function queryENSInfosByNode(address ens, bytes32[] calldata nodes) external override view returns (ENSQueryResult[] memory) {
        ENSQueryResult[] memory results = new ENSQueryResult[](nodes.length);
        for (uint256 i; i < nodes.length; ++i) {
            try IENS(ens).resolver(nodes[i]) returns (address _resolver) {
                results[i].resolver = _resolver;
            } catch {
            }

            if (results[i].resolver != address(0)) {
                try IENSResolver(results[i].resolver).addr(nodes[i]) returns (address _address) {
                    results[i].domainAddr = _address;
                } catch {
                }
            }
        }
        return results;
    }

    function queryENSInfosByToken(address token, address ens, uint256[] calldata tokenIds) external override view returns (ENSQueryResult[] memory) {
        ENSQueryResult[] memory results = new ENSQueryResult[](tokenIds.length);
        bytes32 baseNode = IENSToken(token).baseNode();
        for (uint i; i < tokenIds.length; ++i) {
            try IENSToken(token).ownerOf(tokenIds[i]) returns (address _owner) {
                results[i].owner = _owner;
            } catch {
            }

            try IENSToken(token).available(tokenIds[i]) returns (bool _available) {
                results[i].available = _available;
            } catch {
            }

            bytes32 node = keccak256(abi.encodePacked(baseNode, tokenIds[i]));
            try IENS(ens).resolver(node) returns (address _resolver) {
                results[i].resolver = _resolver;
            } catch {
            }

            if (results[i].resolver != address(0)) {
                try IENSResolver(results[i].resolver).addr(node) returns (address _address) {
                    results[i].domainAddr = _address;
                } catch {
                }
            }
        }
        return results;
    }

    function queryENSReverseInfos(address ens, address[] calldata addresses) external override view returns (ENSReverseResult[] memory) {
        ENSReverseResult[] memory reverses = _queryENSReverses(ens, addresses);
        for (uint i; i < reverses.length; ++i) {
            if (reverses[i].domain.length == 0) {
                continue;
            }

            bytes32 node = _namehash(reverses[i].domain);

            try IENS(ens).resolver(node) returns (address _resolver) {
                reverses[i].verifyResolver = _resolver;
            } catch {
            }

            if (reverses[i].verifyResolver != address(0)) {
                try IENSResolver(reverses[i].verifyResolver).addr(node) returns (address _address) {
                    reverses[i].verifyAddr = _address;
                } catch {
                }
            }
        }
        return reverses;
    }

    // BASE_REVERSE_HASH = namehash("addr.reverse")
    bytes32 constant BASE_REVERSE_HASH = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;

    function _queryENSReverses(address ens, address[] calldata addresses) internal view returns (ENSReverseResult[] memory) {
        ENSReverseResult[] memory results = new ENSReverseResult[](addresses.length);
        for (uint256 i; i < addresses.length; ++i) {
            if (addresses[i] == address(0)) {
                continue;
            }

            bytes32 label = keccak256(_toHexString(addresses[i]));
            bytes32 node = keccak256(abi.encodePacked(BASE_REVERSE_HASH, label));

            try IENS(ens).resolver(node) returns (address _resolver) {
                results[i].resolver = _resolver;
            } catch {
            }

            if (results[i].resolver != address(0)) {
                try IENSResolver(results[i].resolver).name(node) returns (bytes memory _name) {
                    results[i].domain = _name;
                } catch {
                }
            }
        }
        return results;
    }

    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    function _toHexString(address addr) internal pure returns (bytes memory) {
    unchecked {
        uint256 value = uint160(addr);
        bytes memory buffer = new bytes(40);
        for (uint256 i = 0; i < 40; ++i) {
            buffer[39 - i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        return buffer;
    }
    }

    function _namehash(bytes memory domain) internal pure returns (bytes32 hash) {
        uint256 total = bytes(domain).length;
        assembly {
            let ptrFree := mload(0x40)
            mstore(ptrFree, 0)

            let i
            let start := add(domain, 0x20)
            let ptrEnd := add(start, total)

            let length := _getLabelLength(ptrEnd, total, i)
            for {} length {} {
                let labelHash := keccak256(sub(ptrEnd, add(i, length)), length)
                mstore(add(ptrFree, 0x20), labelHash)
                mstore(ptrFree, keccak256(ptrFree, 0x40))

                i := add(i, length)
                if lt(i, total) {
                    i := add(i, 1)
                }
                length := _getLabelLength(ptrEnd, total, i)
            }

            hash := mload(ptrFree)

            function _getLabelLength(endPtr, t, offset) -> len {
                for {let ptr := sub(endPtr, add(offset, 1))} and(lt(add(offset, len), t), iszero(eq(byte(0, mload(ptr)), 0x2e))) {} {
                    ptr := sub(ptr, 1)
                    len := add(len, 1)
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IENSToken {
    function baseNode() external view returns (bytes32);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function available(uint256 id) external view returns (bool);
}

interface IENS {
    function resolver(bytes32 node) external view returns (address);
}

interface IENSResolver {
    function addr(bytes32 node) external view returns (address);

    function name(bytes32 node) external view returns (bytes memory);
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.15;

import "./ISpaceIdHelperFeature.sol";
import "./ISpaceIdRegistrar.sol";

contract SpaceIdHelperFeature is ISpaceIdHelperFeature {

    function querySpaceIdInfos(
        address owner,
        address resolver,
        string[] calldata names,
        bytes32[] calldata secrets,
        uint256[] calldata durations
    ) external override view returns (SpaceIdInfos memory) {
        require(
            names.length == secrets.length &&
            names.length == durations.length,
            "querySpaceIdInfos: mismatch items."
        );

        ISpaceIdRegistrar registrar = ISpaceIdRegistrar(0x6D910eDFED06d7FA12Df252693622920fEf7eaA6);

        SpaceIdItem[] memory items = new SpaceIdItem[](durations.length);
        for (uint256 i; i < items.length; i++) {
            try registrar.rentPrice(names[i], durations[i]) returns (ISpaceIdRegistrar.Price memory price) {
                items[i].base = price.base;
                items[i].premium = price.premium;
                items[i].available = registrar.available(names[i]);
            } catch {
            }

            bytes32 label = keccak256(bytes(names[i]));
            if (resolver == address(0)) {
                items[i].commitHash = keccak256(abi.encodePacked(label, owner, secrets[i]));
            } else {
                items[i].commitHash = keccak256(abi.encodePacked(label, owner, resolver, owner, secrets[i]));
            }

            items[i].commitTimestamp = registrar.commitments(items[i].commitHash);
        }

        uint256 minCommitAge = registrar.minCommitmentAge();
        uint256 maxCommitAge = registrar.maxCommitmentAge();
        return SpaceIdInfos(minCommitAge, maxCommitAge, items);
    }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2022 Element.Market

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.8.15;


interface ISpaceIdRegistrar {

    struct Price {
        uint256 base;
        uint256 premium;
    }

    function valid(string calldata name) external pure returns (bool);
    function available(string calldata name) external view returns(bool);
    function rentPrice(string calldata name, uint256 duration) external view returns (Price memory price);

    function minCommitmentAge() external view returns(uint256);
    function maxCommitmentAge() external view returns(uint256);

    function commitments(bytes32) external view returns(uint256);
    function commit(bytes32 commitHash) external;

    function registerWithConfig(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) external payable;
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./IAssetCheckerFeature.sol";


contract AssetCheckerFeature is IAssetCheckerFeature {

    bytes4 public constant INTERFACE_ID_ERC20 = 0x36372b07;
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;
    address internal constant NATIVE_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function checkAssetsEx(
        address account,
        address operator,
        uint8[] calldata itemTypes,
        address[] calldata tokens,
        uint256[] calldata tokenIds
    )
        external
        override
        view
        returns (AssetCheckResultInfo[] memory infos)
    {
        require(itemTypes.length == tokens.length, "require(itemTypes.length == tokens.length)");
        require(itemTypes.length == tokenIds.length, "require(itemTypes.length == tokenIds.length)");

        infos = new AssetCheckResultInfo[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenId = tokenIds[i];

            infos[i].itemType = itemTypes[i];
            if (itemTypes[i] == 0) {
                infos[i].allowance = isApprovedForAll(token, account, operator) ? 1 : 0;
                infos[i].erc721Owner = ownerOf(token, tokenId);
                infos[i].erc721ApprovedAccount = getApproved(token, tokenId);
                infos[i].balance = (infos[i].erc721Owner == account) ? 1 : 0;
                continue;
            }

            if (itemTypes[i] == 1) {
                infos[i].allowance = isApprovedForAll(token, account, operator) ? 1 : 0;
                infos[i].balance = balanceOf(token, account, tokenId);
                continue;
            }

            if (itemTypes[i] == 2) {
                if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
                    infos[i].balance = account.balance;
                    infos[i].allowance = type(uint256).max;
                } else {
                    infos[i].balance = balanceOf(token, account);
                    infos[i].allowance = allowanceOf(token, account, operator);
                }
            }
        }
        return infos;
    }

    function checkAssets(address account, address operator, address[] calldata tokens, uint256[] calldata tokenIds)
        external
        override
        view
        returns (AssetCheckResultInfo[] memory infos)
    {
        require(tokens.length == tokenIds.length, "require(tokens.length == tokenIds.length)");

        infos = new AssetCheckResultInfo[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            uint256 tokenId = tokenIds[i];

            if (supportsInterface(token, INTERFACE_ID_ERC721)) {
                infos[i].itemType = 0;
                infos[i].allowance = isApprovedForAll(token, account, operator) ? 1 : 0;
                infos[i].erc721Owner = ownerOf(token, tokenId);
                infos[i].erc721ApprovedAccount = getApproved(token, tokenId);
                infos[i].balance = (infos[i].erc721Owner == account) ? 1 : 0;
                continue;
            }

            if (supportsInterface(token, INTERFACE_ID_ERC1155)) {
                infos[i].itemType = 1;
                infos[i].allowance = isApprovedForAll(token, account, operator) ? 1 : 0;
                infos[i].balance = balanceOf(token, account, tokenId);
                continue;
            }

            if (supportsInterface(token, INTERFACE_ID_ERC20)) {
                infos[i].itemType = 2;
                if (token == address(0) || token == NATIVE_TOKEN_ADDRESS) {
                    infos[i].balance = account.balance;
                    infos[i].allowance = type(uint256).max;
                } else {
                    infos[i].balance = balanceOf(token, account);
                    infos[i].allowance = allowanceOf(token, account, operator);
                }
            } else {
                infos[i].itemType = 255;
            }
        }
        return infos;
    }

    function supportsInterface(address nft, bytes4 interfaceId) internal view returns (bool) {
        try IERC165(nft).supportsInterface(interfaceId) returns (bool support) {
            return support;
        } catch {
        }
        return false;
    }

    function ownerOf(address nft, uint256 tokenId) internal view returns (address owner) {
        try IERC721(nft).ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {
        }
        return owner;
    }

    function getApproved(address nft, uint256 tokenId) internal view returns (address operator) {
        try IERC721(nft).getApproved(tokenId) returns (address approvedAccount) {
            operator = approvedAccount;
        } catch {
        }
        return operator;
    }

    function isApprovedForAll(address nft, address owner, address operator) internal view returns (bool isApproved) {
        if (operator != address(0)) {
            try IERC721(nft).isApprovedForAll(owner, operator) returns (bool _isApprovedForAll) {
                isApproved = _isApprovedForAll;
            } catch {
            }
        }
        return isApproved;
    }

    function balanceOf(address erc20, address account) internal view returns (uint256 balance) {
        try IERC20(erc20).balanceOf(account) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }

    function allowanceOf(address erc20, address owner, address spender) internal view returns (uint256 allowance) {
        try IERC20(erc20).allowance(owner, spender) returns (uint256 _allowance) {
            allowance = _allowance;
        } catch {
        }
        return allowance;
    }

    function balanceOf(address nft, address account, uint256 id) internal view returns (uint256 balance) {
        try IERC1155(nft).balanceOf(account, id) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IConduitController.sol";
import "./interfaces/ISeaport.sol";
import "./interfaces/ILooksRare.sol";
import "./IThirdExchangeOfferCheckerFeature.sol";


contract ThirdExchangeOfferCheckerFeature is IThirdExchangeOfferCheckerFeature {

    address public constant SEAPORT = 0x00000000006c3852cbEf3e08E8dF289169EdE581;
    address public immutable LOOKS_RARE;

    constructor(address looksRare) {
        LOOKS_RARE = looksRare;
    }

    function getSeaportOfferCheckInfo(
        address account,
        address erc20Token,
        bytes32 conduitKey,
        bytes32 orderHash,
        uint256 counter
    )
        external
        override
        view
        returns (SeaportOfferCheckInfo memory info)
    {
        (info.conduit, info.conduitExists) = getConduit(conduitKey);
        if (erc20Token == address(0)) {
            info.balance = 0;
            info.allowance = 0;
        } else {
            info.balance = balanceOf(erc20Token, account);
            info.allowance = allowanceOf(erc20Token, account, info.conduit);
        }

        try ISeaport(SEAPORT).getOrderStatus(orderHash) returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        ) {
            info.isValidated = isValidated;
            info.isCancelled = isCancelled;
            info.totalFilled = totalFilled;
            info.totalSize = totalSize;

            if (totalFilled > 0 && totalFilled == totalSize) {
                info.isCancelled = true;
            }
        } catch {}

        try ISeaport(SEAPORT).getCounter(account) returns(uint256 _counter) {
            if (counter != _counter) {
                info.isCancelled = true;
            }
        } catch {}
        return info;
    }

    function getLooksRareOfferCheckInfo(address account, address erc20Token, uint256 accountNonce)
        external
        override
        view
        returns (LooksRareOfferCheckInfo memory info)
    {
        try ILooksRare(LOOKS_RARE).isUserOrderNonceExecutedOrCancelled(account, accountNonce) returns (bool isExecutedOrCancelled) {
            info.isExecutedOrCancelled = isExecutedOrCancelled;
        } catch {}

        try ILooksRare(LOOKS_RARE).userMinOrderNonce(account) returns (uint256 minNonce) {
            if (accountNonce < minNonce) {
                info.isExecutedOrCancelled = true;
            }
        } catch {}

        if (erc20Token == address(0)) {
            info.balance = 0;
            info.allowance = 0;
        } else {
            info.balance = balanceOf(erc20Token, account);
            info.allowance = allowanceOf(erc20Token, account, LOOKS_RARE);
        }
        return info;
    }

    function getConduit(bytes32 conduitKey) public view returns (address conduit, bool exists) {
        if (conduitKey == 0x0000000000000000000000000000000000000000000000000000000000000000) {
            conduit = SEAPORT;
            exists = true;
        } else {
            try ISeaport(SEAPORT).information() returns (string memory, bytes32, address conduitController) {
                try IConduitController(conduitController).getConduit(conduitKey) returns (address _conduit, bool _exists) {
                    conduit = _conduit;
                    exists = _exists;
                } catch {
                }
            } catch {
            }
        }
        return (conduit, exists);
    }

    function balanceOf(address erc20, address account) internal view returns (uint256 balance) {
        try IERC20(erc20).balanceOf(account) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }

    function allowanceOf(address erc20, address owner, address spender) internal view returns (uint256 allowance) {
        try IERC20(erc20).allowance(owner, spender) returns (uint256 _allowance) {
            allowance = _allowance;
        } catch {
        }
        return allowance;
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

interface IThirdExchangeOfferCheckerFeature {

    struct SeaportOfferCheckInfo {
        address conduit;
        bool conduitExists;
        uint256 balance;
        uint256 allowance;
        bool isValidated;
        bool isCancelled;
        uint256 totalFilled;
        uint256 totalSize;
    }

    struct LooksRareOfferCheckInfo {
        uint256 balance;
        uint256 allowance;
        bool isExecutedOrCancelled;
    }

    function getSeaportOfferCheckInfo(
        address account,
        address erc20Token,
        bytes32 conduitKey,
        bytes32 orderHash,
        uint256 counter
    ) external view returns (SeaportOfferCheckInfo memory info);

    function getLooksRareOfferCheckInfo(
        address account,
        address erc20Token,
        uint256 accountNonce
    ) external view returns (LooksRareOfferCheckInfo memory info);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "./interfaces/ISeaport.sol";

interface IAsset {
    function balanceOf(address owner) external view returns (uint256 balance);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IConduitController {
    function getConduit(bytes32 conduitKey) external view returns (address conduit, bool exists);
}

contract SeaportCheckerFeature {

    struct SeaportOfferCheckInfo {
        address conduit;
        bool conduitExists;
        uint256 balance;
        uint256 allowance;
        bool isValidated;
        bool isCancelled;
        uint256 totalFilled;
        uint256 totalSize;
    }

    struct SeaportCheckInfo {
        address conduit;
        bool conduitExists;
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll or erc1155.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        uint256 erc1155Balance;
        bool isValidated;
        bool isCancelled;
        uint256 totalFilled;
        uint256 totalSize;
    }

    function getSeaportOfferCheckInfoV3(
        address seaport,
        address account,
        address erc20Token,
        bytes32 conduitKey,
        bytes32 orderHash,
        uint256 counter
    ) external view returns (SeaportOfferCheckInfo memory info) {
        (info.conduit, info.conduitExists) = getConduit(seaport, conduitKey);
        if (erc20Token == address(0)) {
            info.balance = 0;
            info.allowance = 0;
        } else {
            info.balance = balanceOf(erc20Token, account);
            info.allowance = allowanceOf(erc20Token, account, info.conduit);
        }

        try ISeaport(seaport).getOrderStatus(orderHash) returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        ) {
            info.isValidated = isValidated;
            info.isCancelled = isCancelled;
            info.totalFilled = totalFilled;
            info.totalSize = totalSize;

            if (totalFilled > 0 && totalFilled == totalSize) {
                info.isCancelled = true;
            }
        } catch {}

        try ISeaport(seaport).getCounter(account) returns(uint256 _counter) {
            if (counter != _counter) {
                info.isCancelled = true;
            }
        } catch {}
        return info;
    }

    function getSeaportCheckInfoV3(
        address seaport,
        address account,
        uint8 itemType,
        address nft,
        uint256 tokenId,
        bytes32 conduitKey,
        bytes32 orderHash,
        uint256 counter
    ) external view returns (SeaportCheckInfo memory info) {
        (info.conduit, info.conduitExists) = getConduit(seaport, conduitKey);
        if (itemType == 0) {
            info.erc721Owner = ownerOf(nft, tokenId);
            info.erc721ApprovedAccount = getApproved(nft, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        } else if (itemType == 1) {
            info.erc1155Balance = balanceOf(nft, account, tokenId);
            info.isApprovedForAll = isApprovedForAll(nft, account, info.conduit);
        }

        try ISeaport(seaport).getOrderStatus(orderHash) returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        ) {
            info.isValidated = isValidated;
            info.isCancelled = isCancelled;
            info.totalFilled = totalFilled;
            info.totalSize = totalSize;

            if (totalFilled > 0 && totalFilled == totalSize) {
                info.isCancelled = true;
            }
        } catch {}

        try ISeaport(seaport).getCounter(account) returns(uint256 _counter) {
            if (counter != _counter) {
                info.isCancelled = true;
            }
        } catch {}
        return info;
    }

    function getConduit(address seaport, bytes32 conduitKey) public view returns (address conduit, bool exists) {
        if (conduitKey == 0x0000000000000000000000000000000000000000000000000000000000000000) {
            conduit = seaport;
            exists = true;
        } else {
            try ISeaport(seaport).information() returns (string memory, bytes32, address conduitController) {
                try IConduitController(conduitController).getConduit(conduitKey) returns (address _conduit, bool _exists) {
                    conduit = _conduit;
                    exists = _exists;
                } catch {
                }
            } catch {
            }
        }
        return (conduit, exists);
    }

    function balanceOf(address erc20, address account) internal view returns (uint256 balance) {
        try IAsset(erc20).balanceOf(account) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }

    function allowanceOf(address erc20, address owner, address spender) internal view returns (uint256 allowance) {
        try IAsset(erc20).allowance(owner, spender) returns (uint256 _allowance) {
            allowance = _allowance;
        } catch {
        }
        return allowance;
    }

    function ownerOf(address nft, uint256 tokenId) internal view returns (address owner) {
        try IAsset(nft).ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {
        }
        return owner;
    }

    function getApproved(address nft, uint256 tokenId) internal view returns (address operator) {
        try IAsset(nft).getApproved(tokenId) returns (address approvedAccount) {
            operator = approvedAccount;
        } catch {
        }
        return operator;
    }

    function isApprovedForAll(address nft, address owner, address operator) internal view returns (bool isApproved) {
        if (operator != address(0)) {
            try IAsset(nft).isApprovedForAll(owner, operator) returns (bool _isApprovedForAll) {
                isApproved = _isApprovedForAll;
            } catch {
            }
        }
        return isApproved;
    }

    function balanceOf(address nft, address account, uint256 id) internal view returns (uint256 balance) {
        try IAsset(nft).balanceOf(account, id) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./interfaces/ISeaport.sol";

interface IConduitController {
    function getConduit(bytes32 conduitKey) external view returns (address conduit, bool exists);
}

interface INFT {
    function balanceOf(address owner) external view returns (uint256 balance);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract OkxExchangeCheckerFeature {

    address public immutable OKX;
    bytes4 public constant INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 public constant INTERFACE_ID_ERC1155 = 0xd9b67a26;

    constructor(address okx) {
        OKX = okx;
    }

    struct OkxCheckInfo {
        address conduit;
        bool conduitExists;
        address erc721Owner;
        bool isApprovedForAll; // erc721.isApprovedForAll or erc1155.isApprovedForAll
        address erc721ApprovedAccount; // erc721.getApproved(tokenId)
        uint256 erc1155Balance;
        bool isValidated;
        bool isCancelled;
        uint256 totalFilled;
        uint256 totalSize;
    }

    /// @param itemType itemType 0: ERC721, 1: ERC1155
    function getOkxCheckInfo(
        address account,
        uint8 itemType,
        address token,
        uint256 tokenId,
        bytes32 conduitKey,
        bytes32 orderHash,
        uint256 counter
    ) external view returns (OkxCheckInfo memory info) {
        (info.conduit, info.conduitExists) = getConduit(conduitKey);
        if (itemType == 0) {
            info.erc721Owner = ownerOf(token, tokenId);
            info.erc721ApprovedAccount = getApproved(token, tokenId);
            info.isApprovedForAll = isApprovedForAll(token, account, info.conduit);
        } else if (itemType == 1) {
            info.erc1155Balance = balanceOf(token, account, tokenId);
            info.isApprovedForAll = isApprovedForAll(token, account, info.conduit);
        }

        try ISeaport(OKX).getOrderStatus(orderHash) returns (
            bool isValidated,
            bool isCancelled,
            uint256 totalFilled,
            uint256 totalSize
        ) {
            info.isValidated = isValidated;
            info.isCancelled = isCancelled;
            info.totalFilled = totalFilled;
            info.totalSize = totalSize;

            if (totalFilled > 0 && totalFilled == totalSize) {
                info.isCancelled = true;
            }
        } catch {}

        try ISeaport(OKX).getCounter(account) returns(uint256 _counter) {
            if (counter != _counter) {
                info.isCancelled = true;
            }
        } catch {}
        return info;
    }

    function getConduit(bytes32 conduitKey) public view returns (address conduit, bool exists) {
        if (conduitKey == 0x0000000000000000000000000000000000000000000000000000000000000000) {
            conduit = OKX;
            exists = true;
        } else {
            try ISeaport(OKX).information() returns (string memory, bytes32, address conduitController) {
                try IConduitController(conduitController).getConduit(conduitKey) returns (address _conduit, bool _exists) {
                    conduit = _conduit;
                    exists = _exists;
                } catch {
                }
            } catch {
            }
        }
        return (conduit, exists);
    }

    function ownerOf(address nft, uint256 tokenId) internal view returns (address owner) {
        try INFT(nft).ownerOf(tokenId) returns (address _owner) {
            owner = _owner;
        } catch {
        }
        return owner;
    }

    function getApproved(address nft, uint256 tokenId) internal view returns (address operator) {
        try INFT(nft).getApproved(tokenId) returns (address approvedAccount) {
            operator = approvedAccount;
        } catch {
        }
        return operator;
    }

    function isApprovedForAll(address nft, address owner, address operator) internal view returns (bool isApproved) {
        if (operator != address(0)) {
            try INFT(nft).isApprovedForAll(owner, operator) returns (bool _isApprovedForAll) {
                isApproved = _isApprovedForAll;
            } catch {
            }
        }
        return isApproved;
    }

    function balanceOf(address nft, address account, uint256 id) internal view returns (uint256 balance) {
        try INFT(nft).balanceOf(account, id) returns (uint256 _balance) {
            balance = _balance;
        } catch {
        }
        return balance;
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./ITokenUriHelperFeature.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";


contract TokenUriHelperFeature is ITokenUriHelperFeature {

    uint256 constant MASK_ADDRESS = (1 << 160) - 1;

    function tokenURIs(TokenUriParam[] calldata params) external view override returns (string[] memory uris) {
        uris = new string[](params.length);
        for (uint256 i; i < params.length;) {
            address erc721 = address(uint160(params[i].methodIdAndAddress & MASK_ADDRESS));
            bytes4 methodId = bytes4(uint32(params[i].methodIdAndAddress >> 224));
            if (methodId == 0) {
                methodId = IERC721Metadata.tokenURI.selector;
            }

            (bool success, bytes memory uri) = erc721.staticcall(abi.encodeWithSelector(methodId, params[i].tokenId));
            if (success) {
                uris[i] = string(uri);
            }
            unchecked {++i;}
        }
        return uris;
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ITokenUriHelperFeature {

    struct TokenUriParam {
        // 32bits(methodId) + 64bits(unused) + 160bits(tokenAddress)
        uint256 methodIdAndAddress;
        uint256 tokenId;
    }
    function tokenURIs(TokenUriParam[] calldata params) external view returns(string[] memory uris);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "operator-filter-registry/src/DefaultOperatorFilterer.sol";


contract PowerWeb3Hongkong is ERC721("Power Web3 Hongkong", "PowerWeb3"), Ownable, DefaultOperatorFilterer {
    using Strings for uint256;

    uint256 public totalSupply;
    string private baseURI_ = "ipfs://Qmc2aY3xVGLsPMfv6bvibP5tfw7xgAdEvkaqK9A1HFv8oQ/";
    uint256 private constant MASK_160 = ((1 << 160) - 1);

    function mint(address to, uint256 tokenId) external onlyOwner {
        unchecked {
            _mint(to, tokenId);
            totalSupply++;
        }
    }

    function batchMint(uint256[] calldata infos) external onlyOwner {
        unchecked {
            uint256 l = infos.length;
            for (uint256 i; i < l; i++) {
                _mint(address(uint160(infos[i] & MASK_160)), (infos[i] >> 160));
            }
            totalSupply += l;
        }
    }

    function tokenURI(uint256 tokenId) public override view virtual returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory uri = _baseURI();
        if (bytes(uri).length > 0) {
            if (tokenId > 99) {
                return string(abi.encodePacked(uri, tokenId.toString(), ".json"));
            }
            if (tokenId > 9) {
                return string(abi.encodePacked(uri, "0", tokenId.toString(), ".json"));
            }
            return string(abi.encodePacked(uri, "00", tokenId.toString(), ".json"));
        } else {
            return "";
        }
    }

    function setBaseURI(string memory uri) external onlyOwner {
        baseURI_ = uri;
    }

    function _baseURI() internal override view virtual returns (string memory) {
        return baseURI_;
    }

    function setApprovalForAll(address operator, bool approved)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
pragma solidity ^0.8.13;

import {OperatorFilterer} from "./OperatorFilterer.sol";

/**
 * @title  DefaultOperatorFilterer
 * @notice Inherits from OperatorFilterer and automatically subscribes to the default OpenSea subscription.
 */
abstract contract DefaultOperatorFilterer is OperatorFilterer {
    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);

    constructor() OperatorFilterer(DEFAULT_SUBSCRIPTION, true) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IOperatorFilterRegistry} from "./IOperatorFilterRegistry.sol";

/**
 * @title  OperatorFilterer
 * @notice Abstract contract whose constructor automatically registers and optionally subscribes to or copies another
 *         registrant's entries in the OperatorFilterRegistry.
 * @dev    This smart contract is meant to be inherited by token contracts so they can use the following:
 *         - `onlyAllowedOperator` modifier for `transferFrom` and `safeTransferFrom` methods.
 *         - `onlyAllowedOperatorApproval` modifier for `approve` and `setApprovalForAll` methods.
 */
abstract contract OperatorFilterer {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry public constant OPERATOR_FILTER_REGISTRY =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (subscribe) {
                OPERATOR_FILTER_REGISTRY.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    OPERATOR_FILTER_REGISTRY.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    OPERATOR_FILTER_REGISTRY.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Allow spending tokens from addresses with balance
        // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
        // from an EOA.
        if (from != msg.sender) {
            _checkFilterOperator(msg.sender);
        }
        _;
    }

    modifier onlyAllowedOperatorApproval(address operator) virtual {
        _checkFilterOperator(operator);
        _;
    }

    function _checkFilterOperator(address operator) internal view virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(OPERATOR_FILTER_REGISTRY).code.length > 0) {
            if (!OPERATOR_FILTER_REGISTRY.isOperatorAllowed(address(this), operator)) {
                revert OperatorNotAllowed(operator);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function unregister(address addr) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "erc721a/contracts/ERC721A.sol";

contract TestERC721 is ERC721A("EEE721", "EEEE721") {
    constructor () public {
    }

    string public baseURI = "https://api.pudgypenguins.io/penguin/";

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function _startTokenId() internal view override virtual returns (uint256) {
        return 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestERC20 is ERC20("Test20", "TST20") {
    constructor () public {
    }

    function mint(address to, uint256 value) public returns (bool) {
        _mint(to, value);
        return true;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


interface IPropertyValidator {

    /// @dev Checks that the given ERC721/ERC1155 asset satisfies the properties encoded in `propertyData`.
    ///      Should revert if the asset does not satisfy the specified properties.
    /// @param tokenAddress The ERC721/ERC1155 token contract address.
    /// @param tokenId The ERC721/ERC1155 tokenId of the asset to check.
    /// @param propertyData Encoded properties or auxiliary data needed to perform the check.
    function validateProperty(address tokenAddress, uint256 tokenId, bytes calldata propertyData) external view;
}

interface IElementEx {

    /// @dev Allowed signature types.
    enum SignatureType {
        EIP712,
        PRESIGNED
    }

    /// @dev Encoded EC signature.
    struct Signature {
        // How to validate the signature.
        SignatureType signatureType;
        // EC Signature data.
        uint8 v;
        // EC Signature data.
        bytes32 r;
        // EC Signature data.
        bytes32 s;
    }

    enum OrderStatus {
        INVALID,
        FILLABLE,
        UNFILLABLE,
        EXPIRED
    }

    struct Property {
        IPropertyValidator propertyValidator;
        bytes propertyData;
    }

    struct Fee {
        address recipient;
        uint256 amount;
        bytes feeData;
    }

    struct NFTSellOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
    }

    // All fields except `nftProperties` align
    // with those of NFTSellOrder
    struct NFTBuyOrder {
        address maker;
        address taker;
        uint256 expiry;
        uint256 nonce;
        IERC20 erc20Token;
        uint256 erc20TokenAmount;
        Fee[] fees;
        address nft;
        uint256 nftId;
        Property[] nftProperties;
    }

    /// @dev Sells an ERC721 asset to fill the given order.
    /// @param buyOrder The ERC721 buy order.
    /// @param signature The order signature from the maker.
    /// @param erc721TokenId The ID of the ERC721 asset being
    ///        sold. If the given order specifies properties,
    ///        the asset must satisfy those properties. Otherwise,
    ///        it must equal the tokenId in the order.
    /// @param unwrapNativeToken If this parameter is true and the
    ///        ERC20 token of the order is e.g. WETH, unwraps the
    ///        token before transferring it to the taker.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC721OrderCallback` on `msg.sender` after
    ///        the ERC20 tokens have been transferred to `msg.sender`
    ///        but before transferring the ERC721 asset to the buyer.
    function sellERC721(NFTBuyOrder calldata buyOrder, Signature calldata signature, uint256 erc721TokenId, bool unwrapNativeToken, bytes calldata callbackData) external;

    /// @dev Buys an ERC721 asset by filling the given order.
    /// @param sellOrder The ERC721 sell order.
    /// @param signature The order signature.
    function buyERC721(NFTSellOrder calldata sellOrder, Signature calldata signature) external payable;

    /// @dev Buys an ERC721 asset by filling the given order.
    /// @param sellOrder The ERC721 sell order.
    /// @param signature The order signature.
    /// @param taker The address to receive ERC721. If this parameter
    ///         is zero, transfer ERC721 to `msg.sender`.
    /// @param callbackData If this parameter is non-zero, invokes
    ///        `zeroExERC721OrderCallback` on `msg.sender` after
    ///        the ERC721 asset has been transferred to `msg.sender`
    ///        but before transferring the ERC20 tokens to the seller.
    ///        Native tokens acquired during the callback can be used
    ///        to fill the order.
    function buyERC721Ex(NFTSellOrder calldata sellOrder, Signature calldata signature, address taker, bytes calldata callbackData) external payable;

    /// @dev Get the EIP-712 hash of an ERC721 sell order.
    /// @param order The ERC721 sell order.
    /// @return orderHash The order hash.
    function getERC721SellOrderHash(NFTSellOrder calldata order) external view returns (bytes32);

    /// @dev Get the EIP-712 hash of an ERC721 buy order.
    /// @param order The ERC721 buy order.
    /// @return orderHash The order hash.
    function getERC721BuyOrderHash(NFTBuyOrder calldata order) external view returns (bytes32);

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC721 sell order. Reverts if not.
    /// @param order The ERC721 sell order.
    /// @param signature The signature to validate.
    function validateERC721SellOrderSignature(NFTSellOrder calldata order, Signature calldata signature) external view;

    /// @dev Checks whether the given signature is valid for the
    ///      the given ERC721 buy order. Reverts if not.
    /// @param order The ERC721 buy order.
    /// @param signature The signature to validate.
    function validateERC721BuyOrderSignature(NFTBuyOrder calldata order, Signature calldata signature) external view;
    function getHashNonce(address) external view returns(uint256);
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


interface IElement {
    function getHashNonce(address maker) external view returns (uint256);
}

interface ISeaport {
    function getCounter(address maker) external view returns (uint256);
}

interface IAsset {
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
}

contract SDKApproveCheckerFeature {

    IElement public immutable ELEMENT;

    constructor(IElement element) {
        ELEMENT = element;
    }

    struct SDKApproveInfo {
        uint8 tokenType; // 0: ERC721, 1: ERC1155, 2: ERC20, 255: other
        address tokenAddress;
        address operator;
    }

    function getSDKApprovalsAndCounter(
        address account,
        SDKApproveInfo[] calldata list
    )
        external
        view
        returns (uint256[] memory approvals, uint256 elementCounter, uint256 seaportCounter)
    {
        return getSDKApprovalsAndCounterV2(ISeaport(0x00000000006c3852cbEf3e08E8dF289169EdE581), account, list);
    }

    function getSDKApprovalsAndCounterV2(
        ISeaport seaport,
        address account,
        SDKApproveInfo[] calldata list
    )
        public
        view
        returns (uint256[] memory approvals, uint256 elementCounter, uint256 seaportCounter)
    {
        approvals = new uint256[](list.length);
        for (uint256 i; i < list.length; i++) {
            uint8 tokenType = list[i].tokenType;
            if (tokenType == 0 || tokenType == 1) {
                if (isApprovedForAll(list[i].tokenAddress, account, list[i].operator)) {
                    approvals[i] = 1;
                }
            } else if (tokenType == 2) {
                approvals[i] = allowanceOf(list[i].tokenAddress, account, list[i].operator);
            }
        }

        elementCounter = ELEMENT.getHashNonce(account);
        if (address(seaport) != address(0)) {
            try seaport.getCounter(account) returns (uint256 _counter) {
                seaportCounter = _counter;
            } catch (bytes memory /* reason */) {
            }
        }
        return (approvals, elementCounter, seaportCounter);
    }

    function isApprovedForAll(address nft, address owner, address operator) internal view returns (bool isApproved) {
        if (nft != address(0) && operator != address(0)) {
            try IAsset(nft).isApprovedForAll(owner, operator) returns (bool _isApprovedForAll) {
                isApproved = _isApprovedForAll;
            } catch {
            }
        }
        return isApproved;
    }

    function allowanceOf(address erc20, address owner, address spender) internal view returns (uint256 allowance) {
        if (erc20 != address(0)) {
            try IAsset(erc20).allowance(owner, spender) returns (uint256 _allowance) {
                allowance = _allowance;
            } catch {
            }
        }
        return allowance;
    }
}

/// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract SeaportOrderHashFeature {

    bytes32 public constant SEAPORT11_DOMAIN_SEPARATOR = 0xb50c8913581289bd2e066aeef89fceb9615d490d673131fd1a7047436706834e;

    function isSeaport14Order(address maker, bytes32 hash, bytes calldata signature) external pure returns(bool) {
        if (_isValidBulkOrderSize(signature)) {
            return true;
        }

        bytes32 r;
        bytes32 s;
        uint8 v;
        if (signature.length == 64) {
            bytes32 vs;
            (r, vs) = abi.decode(signature, (bytes32, bytes32));
            s = vs & 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
            v = uint8(uint256(vs >> 255)) + 27;
        } else if (signature.length == 65) {
            (r, s) = abi.decode(signature, (bytes32, bytes32));
            v = uint8(signature[64]);
        } else {
            return true;
        }

        bytes32 orderHash = keccak256(
            abi.encodePacked(uint16(0x1901), SEAPORT11_DOMAIN_SEPARATOR, hash)
        );

        address recoveredSigner = ecrecover(orderHash, v, r, s);
        return recoveredSigner != maker;
    }

    function _isValidBulkOrderSize(bytes calldata signature) internal pure returns (bool validLength) {
        return signature.length < 837 && signature.length > 98 && ((signature.length - 67) % 32) < 2;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IRoyaltyFeeRegistry {
    function royaltyFeeInfoCollection(address collection) external view returns (address, address, uint256);
}

contract LooksRareRoyaltyFeeHelper {

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    address private _owner;
    IRoyaltyFeeRegistry public royaltyFeeRegistry;

    constructor(IRoyaltyFeeRegistry _royaltyFeeRegistry) {
        _transferOwnership(msg.sender);
        royaltyFeeRegistry = _royaltyFeeRegistry;
    }

    function updateRoyaltyFeeRegistry(IRoyaltyFeeRegistry _royaltyFeeRegistry) external onlyOwner {
        royaltyFeeRegistry = _royaltyFeeRegistry;
    }

    function royaltyFeeInfos(address[] calldata collections) external view returns (
        address[] memory setters,
        address[] memory receivers,
        uint256[] memory fees
    ) {
        setters = new address[](collections.length);
        receivers = new address[](collections.length);
        fees = new uint256[](collections.length);
        for (uint256 i = 0; i < collections.length; i++) {
            (setters[i], receivers[i], fees[i]) = royaltyFeeRegistry.royaltyFeeInfoCollection(collections[i]);
        }
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
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
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

enum Side { Buy, Sell }
enum SignatureVersion { Single, Bulk }
enum AssetType { ERC721, ERC1155 }

struct Fee {
    uint16 rate;
    address payable recipient;
}

struct Order {
    address trader;
    Side side;
    address matchingPolicy;
    address collection;
    uint256 tokenId;
    uint256 amount;
    address paymentToken;
    uint256 price;
    uint256 listingTime;
    /* Order expiration timestamp - 0 for oracle cancellations. */
    uint256 expirationTime;
    Fee[] fees;
    uint256 salt;
    bytes extraParams;
}

struct Input {
    Order order;
    uint8 v;
    bytes32 r;
    bytes32 s;
    bytes extraSignature;
    SignatureVersion signatureVersion;
    uint256 blockNumber;
}

struct Execution {
    Input sell;
    Input buy;
}

interface IBlurExchange {

    function isPolicyWhitelisted(address policy) external view returns (bool);

    function viewWhitelistedPolicies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountWhitelistedPolicies() external view returns (uint256);

    function execute(Input calldata sell, Input calldata buy) external payable;

    function bulkExecute(Execution[] calldata executions) external payable;
}

// SPDX-License-Identifier: MIT

// Copyright (C) 2015, 2016, 2017 Dapphub

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

// solhint-disable
pragma solidity ^0.8.15;


contract WETH9Mock {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8  public decimals = 18;

    event  Approval(address indexed _owner, address indexed _spender, uint _value);
    event  Transfer(address indexed _from, address indexed _to, uint _value);
    event  Deposit(address indexed _owner, uint _value);
    event  Withdrawal(address indexed _owner, uint _value);

    mapping(address => uint)                       public  balanceOf;
    mapping(address => mapping(address => uint))  public  allowance;
    //    //0.5.9
    //    function() external payable {
    //        deposit();
    //    }
    receive() external payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    //    //0.5.9
    //    function withdraw(uint wad) public {
    //        require(balanceOf[msg.sender] >= wad);
    //        balanceOf[msg.sender] -= wad;
    //        msg.sender.transfer(wad);
    //        emit Withdrawal(msg.sender, wad);
    //    }

    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad);
        balanceOf[msg.sender] -= wad;
        payable(msg.sender).transfer(wad);
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint) {
        return address(this).balance;
    }

    function approve(address guy, uint wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(address src, address dst, uint256 wad)
    public
    returns (bool)
    {
        require(balanceOf[src] >= wad);

        //  if (src != msg.sender && allowance[src][msg.sender] != uint(- 1)) {  //0.5.9
        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad);
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}


/*
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.

*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;


contract EstimateGasFeature {

    address public immutable ElementExSwapV2;
    constructor(address swap) {
        ElementExSwapV2 = swap;
    }

    struct ERC20Pair {
        address token;
        uint256 amount;
    }

    function estimateGasBatchBuyWithETH(bytes calldata tradeBytes) external payable returns(uint256) {
        address target = ElementExSwapV2;
        assembly {
            mstore(0, 0x4c674c2d)
            calldatacopy(0x20, 0x4, sub(calldatasize(), 0x4))
            if delegatecall(gas(), target, 0x4, calldatasize(), 0, 0) {
                mstore(0, gas())
                return(0, 0x20)
            }
            returndatacopy(0, 0, returndatasize())
            revert(0, returndatasize())
        }
    }

    function estimateGasBatchBuyWithERC20s(
        ERC20Pair[] calldata erc20Pairs,
        bytes calldata tradeBytes,
        address[] calldata dustTokens
    ) external payable returns(uint256) {
        address target = ElementExSwapV2;
        assembly {
            mstore(0, 0x5d578816)
            calldatacopy(0x20, 0x4, sub(calldatasize(), 0x4))
            if delegatecall(gas(), target, 0x4, calldatasize(), 0, 0) {
                mstore(0, gas())
                return(0, 0x20)
            }
            returndatacopy(0, 0, returndatasize())
            revert(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IMoonCatWrapper {
    function wrap(bytes5 catId) external;
    function batchWrap(uint256[] memory rescueOrders) external;
    function batchReWrap(uint256[] memory rescueOrders, int256[] memory oldTokenIds) external;
    function batchUnwrap(uint256[] memory rescueOrders) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


/// @dev Helpers for moving ERC1155 assets around.
abstract contract FixinERC1155Spender {

    // Mask of the lower 20 bytes of a bytes32.
    uint256 constant private ADDRESS_MASK = (1 << 160) - 1;

    /// @dev Transfers an ERC1155 asset from `owner` to `to`.
    /// @param token The address of the ERC1155 token contract.
    /// @param owner The owner of the asset.
    /// @param to The recipient of the asset.
    /// @param tokenId The token ID of the asset to transfer.
    /// @param amount The amount of the asset to transfer.
    function _transferERC1155AssetFrom(
        address token,
        address owner,
        address to,
        uint256 tokenId,
        uint256 amount
    )
        internal
    {
        uint256 success;
        assembly {
            let ptr := mload(0x40) // free memory pointer

            // selector for safeTransferFrom(address,address,uint256,uint256,bytes)
            mstore(ptr, 0xf242432a00000000000000000000000000000000000000000000000000000000)
            mstore(add(ptr, 0x04), and(owner, ADDRESS_MASK))
            mstore(add(ptr, 0x24), and(to, ADDRESS_MASK))
            mstore(add(ptr, 0x44), tokenId)
            mstore(add(ptr, 0x64), amount)
            mstore(add(ptr, 0x84), 0xa0)
            mstore(add(ptr, 0xa4), 0)

            success := call(
                gas(),
                and(token, ADDRESS_MASK),
                0,
                ptr,
                0xc4,
                0,
                0
            )
        }
        require(success != 0, "_transferERC1155/TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract ElementMarketProxy {

    address public constant ELEMENT_EXCHANGE = 0x7Fed7eD540c0731088190fed191FCF854ed65Efa;

    struct Pair721 {
        uint256 token;
        uint256 tokenId;
    }

    function callElement(uint256 ethAmount, Pair721[] calldata pairs, bytes calldata data) external payable {
        assembly {
            // 0x4(selector) + 0x20(ethAmount) + 0x20(pairs.offset) + 0x20(data.offset) + 0x20(pairs.length) + ?(pairs.data) + 0x20(data.length) + ?(data.data)
            calldatacopy(0, data.offset, data.length)
            if iszero(call(gas(), ELEMENT_EXCHANGE, ethAmount, 0, data.length, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // selector for transferFrom(address,address,uint256)
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())
            mstore(0x24, caller())

            let pairsEndOffset := sub(data.offset, 0x20)
            for { let offset := pairs.offset } lt(offset, pairsEndOffset) { offset := add(offset, 0x40) } {
                mstore(0x44, calldataload(add(offset, 0x20))) // tokenID
                if iszero(call(gas(), calldataload(offset), 0, 0, 0x64, 0, 0)) {
                    returndatacopy(0, 0, returndatasize())
                    revert(0, returndatasize())
                }
            }
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC721Received(address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract GemMarketProxy {

    address public constant GEM_EXCHANGE = 0x83C8F28c26bF6aaca652Df1DbBE0e1b56F8baBa2;

    struct Pair721 {
        uint256 token;
        uint256 tokenId;
    }

    function callGem(uint256 ethAmount, Pair721[] calldata pairs, bytes calldata data) external payable {
        assembly {
            // 0x4(selector) + 0x20(ethAmount) + 0x20(pairs.offset) + 0x20(data.offset) + 0x20(pairs.length) + ?(pairs.data) + 0x20(data.length) + ?(data.data)
            calldatacopy(0, data.offset, data.length)
            if iszero(call(gas(), GEM_EXCHANGE, ethAmount, 0, data.length, 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // selector for transferFrom(address,address,uint256)
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())
            mstore(0x24, caller())

            let anySuccess
            let pairsEndOffset := sub(data.offset, 0x20)
            for { let offset := pairs.offset } lt(offset, pairsEndOffset) { offset := add(offset, 0x40) } {
                mstore(0x44, calldataload(add(offset, 0x20))) // tokenID
                if call(gas(), calldataload(offset), 0, 0, 0x64, 0, 0) {
                    anySuccess := 1
                }
            }

            if iszero(anySuccess) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0x150b7a02;
    }

    function onERC721Received(address, uint256, bytes calldata) external virtual returns (bytes4) {
        return 0xf0b9e5ba;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract LooksRareMarketProxy {

    // LooksRare exchange address
    address private constant looks_rare_exchange = 0x59728544B08AB483533076417FbBB2fD0B17CE3a;
    // 0x64 = 0x4(selector) + 0x20(offset(takerBid)) + 0x20(offset(makerAsk)) + 0x20(takerBid.isOrderAsk)
    uint256 private constant offset_takerBid_taker = 0x64;

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }

    function matchAskWithTakerBidUsingETHAndWETH(TakerOrder calldata takerBid, MakerOrder calldata makerAsk) external payable {
        address recipient = takerBid.taker != address(0) ? takerBid.taker : msg.sender;
        uint256 tokenId = makerAsk.tokenId;
        uint256 payableAmount = makerAsk.price;
        address collection = makerAsk.collection;
        uint256 amount = makerAsk.amount;
        assembly {
            calldatacopy(0, 0, calldatasize())
            mstore(offset_takerBid_taker, address())

            if iszero(call(gas(), looks_rare_exchange, payableAmount, 0, calldatasize(), 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // selector for transferFrom(address,address,uint256)
            mstore(0, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())
            mstore(0x24, recipient)
            mstore(0x44, tokenId)
            if call(gas(), collection, 0, 0, 0x64, 0, 0) {
                return(0, 0)
            }

            // selector for safeTransferFrom(address,address,uint256,uint256,bytes)
            mstore(0, 0xf242432a00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())
            mstore(0x64, amount)
            mstore(0x84, 0xa0)
            mstore(0xa4, 0)
            if call(gas(), collection, 0, 0, 0xc4, 0, 0) {
                return(0, 0)
            }

            // revert("LooksRareProxy: transfer nft to taker failed.")
            mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
            mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
            mstore(0x40, 0x0000002d4c6f6f6b735261726550726f78793a207472616e73666572206e6674)
            mstore(0x60, 0x20746f2074616b6572206661696c65642e000000000000000000000000000000)
            mstore(0x80, 0)
            revert(0, 0x84)
        }
    }

    function matchAskWithTakerBidUsingETHAndWETHFor1155(TakerOrder calldata takerBid, MakerOrder calldata makerAsk) external payable {
        address recipient = takerBid.taker != address(0) ? takerBid.taker : msg.sender;
        uint256 tokenId = makerAsk.tokenId;
        uint256 payableAmount = makerAsk.price;
        address collection = makerAsk.collection;
        uint256 amount = makerAsk.amount;
        assembly {
            // selector for matchAskWithTakerBidUsingETHAndWETH
            mstore(0, 0xb4e4b29600000000000000000000000000000000000000000000000000000000)
            calldatacopy(0x4, 0x4, sub(calldatasize(), 4))
            mstore(offset_takerBid_taker, address())

            if iszero(call(gas(), looks_rare_exchange, payableAmount, 0, calldatasize(), 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }

            // selector for safeTransferFrom(address,address,uint256,uint256,bytes)
            mstore(0, 0xf242432a00000000000000000000000000000000000000000000000000000000)
            mstore(0x4, address())
            mstore(0x24, recipient)
            mstore(0x44, tokenId)
            mstore(0x64, amount)
            mstore(0x84, 0xa0)
            mstore(0xa4, 0)
            if call(gas(), collection, 0, 0, 0xc4, 0, 0) {
                return(0, 0)
            }

            // revert("LooksRareProxy: transfer nft to taker failed.")
            mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
            mstore(0x20, 0x0000002000000000000000000000000000000000000000000000000000000000)
            mstore(0x40, 0x0000002d4c6f6f6b735261726550726f78793a207472616e73666572206e6674)
            mstore(0x60, 0x20746f2074616b6572206661696c65642e000000000000000000000000000000)
            mstore(0x80, 0)
            revert(0, 0x84)
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface ISeaport {

    enum Side {
        // 0: Items that can be spent
        OFFER,

        // 1: Items that must be received
        CONSIDERATION
    }

    // prettier-ignore
    enum OrderType {
        // 0: no partial fills, anyone can execute
        FULL_OPEN,

        // 1: partial fills supported, anyone can execute
        PARTIAL_OPEN,

        // 2: no partial fills, only offerer or zone can execute
        FULL_RESTRICTED,

        // 3: partial fills supported, only offerer or zone can execute
        PARTIAL_RESTRICTED
    }

    // prettier-ignore
    enum ItemType {
        // 0: ETH on mainnet, MATIC on polygon, etc.
        NATIVE,

        // 1: ERC20 items (ERC777 and ERC20 analogues could also technically work)
        ERC20,

        // 2: ERC721 items
        ERC721,

        // 3: ERC1155 items
        ERC1155,

        // 4: ERC721 items where a number of tokenIds are supported
        ERC721_WITH_CRITERIA,

        // 5: ERC1155 items where a number of ids are supported
        ERC1155_WITH_CRITERIA
    }

    struct OrderComponents {
        address offerer;
        address zone;
        OfferItem[] offer;
        ConsiderationItem[] consideration;
        OrderType orderType;
        uint256 startTime;
        uint256 endTime;
        bytes32 zoneHash;
        uint256 salt;
        bytes32 conduitKey;
        uint256 counter;
    }

    struct OfferItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
    }

    struct ConsiderationItem {
        ItemType itemType;
        address token;
        uint256 identifierOrCriteria;
        uint256 startAmount;
        uint256 endAmount;
        address payable recipient;
    }

    struct OrderParameters {
        address offerer; // 0x00
        address zone; // 0x20
        OfferItem[] offer; // 0x40
        ConsiderationItem[] consideration; // 0x60
        OrderType orderType; // 0x80
        uint256 startTime; // 0xa0
        uint256 endTime; // 0xc0
        bytes32 zoneHash; // 0xe0
        uint256 salt; // 0x100
        bytes32 conduitKey; // 0x120
        uint256 totalOriginalConsiderationItems; // 0x140
        // offer.length                          // 0x160
    }

    struct AdvancedOrder {
        OrderParameters parameters;
        uint120 numerator;
        uint120 denominator;
        bytes signature;
        bytes extraData;
    }

    struct CriteriaResolver {
        uint256 orderIndex;
        Side side;
        uint256 index;
        uint256 identifier;
        bytes32[] criteriaProof;
    }

    function fulfillAdvancedOrder(
        AdvancedOrder calldata advancedOrder,
        CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        address recipient
    ) external returns (bool fulfilled);

    function information() external view returns (
        string memory version,
        bytes32 domainSeparator,
        address conduitController
    );
}

interface IConduitController {
    function getConduit(bytes32 conduitKey) external view returns (address conduit, bool exists);
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract OkxMarketProxy {
    uint256 public constant MASK_128 = ((1 << 128) - 1);
    ISeaport public immutable OKX;

    constructor(ISeaport okx) {
        OKX = okx;
    }

    function fulfillAdvancedOrder(
        ISeaport.AdvancedOrder calldata advancedOrder,
        ISeaport.CriteriaResolver[] calldata criteriaResolvers,
        bytes32 fulfillerConduitKey,
        uint256 payableAmount
    ) external payable {
        if (advancedOrder.parameters.consideration[0].itemType == ISeaport.ItemType.ERC20) {
            IERC20 token = IERC20(advancedOrder.parameters.consideration[0].token);
            address conduit = _getConduit(fulfillerConduitKey);

            token.approve(conduit, MASK_128);
            try OKX.fulfillAdvancedOrder(advancedOrder, criteriaResolvers, fulfillerConduitKey, msg.sender) {
                token.approve(conduit, 0);
            } catch (bytes memory reason) {
                token.approve(conduit, 0);

                uint256 reasonLength = reason.length;
                if (reasonLength == 0) {
                    revert("OKX.fulfillAdvancedOrder failed");
                } else {
                    assembly {
                        revert(add(reason, 0x20), reasonLength)
                    }
                }
            }
        } else {
            ISeaport okx = OKX;
            assembly {
                // selector for ISeaport.fulfillAdvancedOrder
                mstore(0x0, 0xe7acab24)

                // copy data
                calldatacopy(0x20, 0x4, sub(calldatasize(), 4))

                // modify recipient
                // 0x80 = 0x20(selector) + 0x20(advancedOrder.offset) + 0x20(criteriaResolvers.offset) + 0x20(fulfillerConduitKey)
                mstore(0x80, caller())

                if call(gas(), okx, payableAmount, 0x1c, calldatasize(), 0, 0) {
                    return(0, 0)
                }
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    function _getConduit(bytes32 conduitKey) internal view returns (address conduit) {
        conduit = address(OKX);
        if (conduitKey != 0x0000000000000000000000000000000000000000000000000000000000000000) {
            (, , address conduitController) = OKX.information();
            (address _conduit, bool _exists) = IConduitController(conduitController).getConduit(conduitKey);
            if (_exists) {
                conduit = _conduit;
            }
        }
        return conduit;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract SpaceIDProxy {

    address public constant SpaceID_Registrar = 0x6D910eDFED06d7FA12Df252693622920fEf7eaA6;

    function commit(bytes32 /* commitHash */) external {
        assembly {
            calldatacopy(0, 0, calldatasize())
            if iszero(call(gas(), SpaceID_Registrar, 0, 0, calldatasize(), 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    uint256 private constant MASK_128 = (1 << 128) - 1;

    function registerWithConfig(
        string memory /* name */,
        address /* owner */,
        uint256 duration,
        bytes32 /* secret */,
        address /* resolver*/,
        address /* addr */
    ) external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())
            mstore(0x44, and(duration, MASK_128))
            if iszero(call(gas(), SpaceID_Registrar, shr(128, duration), 0, calldatasize(), 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


contract UniSwapProxy {

    // Uniswap SwapRouter02
    // Ethereum: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    // Rinkeby: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    // Goerli: 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45
    address public constant SwapRouter02 = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;

    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address payableAmount;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    function exactInputSingle(ExactInputSingleParams calldata /* params */) external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())
            mstore(0x64, address())
            if iszero(call(gas(), SwapRouter02, calldataload(0x64), 0, calldatasize(), 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    struct ExactInputParams {
        bytes path;
        address payableAmount;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @dev Setting `amountIn` to 0 will cause the contract to look up its own balance,
    /// and swap the entire amount, enabling contracts to send tokens before calling this function.
    function exactInput(ExactInputParams calldata /* params */) external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())
            mstore(0x24, address())
            if iszero(call(gas(), SwapRouter02, calldataload(0x24), 0, calldatasize(), 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address payableAmount;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// that may remain in the router after the swap.
    function exactOutputSingle(ExactOutputSingleParams calldata /* params */) external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())
            mstore(0x64, address())
            if iszero(call(gas(), SwapRouter02, calldataload(0x64), 0, calldatasize(), 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }

    struct ExactOutputParams {
        bytes path;
        address payableAmount;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// that may remain in the router after the swap.
    function exactOutput(ExactOutputParams calldata /* params */) external payable {
        assembly {
            calldatacopy(0, 0, calldatasize())
            mstore(0x24, address())
            if iszero(call(gas(), SwapRouter02, calldataload(0x24), 0, calldatasize(), 0, 0)) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;


interface IZeroExV3Market {

    struct Order {
        address makerAddress;           // Address that created the order.
        address takerAddress;           // Address that is allowed to fill the order. If set to 0, any address is allowed to fill the order.
        address feeRecipientAddress;    // Address that will recieve fees when order is filled.
        address senderAddress;          // Address that is allowed to call Exchange contract methods that affect this order. If set to 0, any address is allowed to call these methods.
        uint256 makerAssetAmount;       // Amount of makerAsset being offered by maker. Must be greater than 0.
        uint256 takerAssetAmount;       // Amount of takerAsset being bid on by maker. Must be greater than 0.
        uint256 makerFee;               // Fee paid to feeRecipient by maker when order is filled.
        uint256 takerFee;               // Fee paid to feeRecipient by taker when order is filled.
        uint256 expirationTimeSeconds;  // Timestamp in seconds at which order expires.
        uint256 salt;                   // Arbitrary number to facilitate uniqueness of the order's hash.
        bytes makerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring makerAsset. The leading bytes4 references the id of the asset proxy.
        bytes takerAssetData;           // Encoded data that can be decoded by a specified proxy contract when transferring takerAsset. The leading bytes4 references the id of the asset proxy.
        bytes makerFeeAssetData;        // Encoded data that can be decoded by a specified proxy contract when transferring makerFeeAsset. The leading bytes4 references the id of the asset proxy.
        bytes takerFeeAssetData;        // Encoded data that can be decoded by a specified proxy contract when transferring takerFeeAsset. The leading bytes4 references the id of the asset proxy.
    }

    function marketBuyOrdersWithEth(
        Order[] memory orders,
        uint256 makerAssetBuyAmount,
        bytes[] memory signatures,
        uint256[] memory ethFeeAmounts,
        address payable[] memory feeRecipients,
        address taker
    ) external payable;
}

contract ZeroExV3MarketProxy {

    address public constant EXCHANGE = 0x5ff68FEE57dE2f1750E32da900b10002E3A5992D;

    /// @dev Attempt to buy makerAssetBuyAmount of makerAsset by selling ETH provided with transaction.
    ///      The Forwarder may *fill* more than makerAssetBuyAmount of the makerAsset so that it can
    ///      pay takerFees where takerFeeAssetData == makerAssetData (i.e. percentage fees).
    ///      Any ETH not spent will be refunded to sender.
    /// @param orders Array of order specifications used containing desired makerAsset and WETH as takerAsset.
    /// @param makerAssetBuyAmount Desired amount of makerAsset to purchase.
    /// @param signatures Proofs that orders have been created by makers.
    /// @param ethFeeAmounts Amounts of ETH, denominated in Wei, that are paid to corresponding feeRecipients.
    /// @param feeRecipients Addresses that will receive ETH when orders are filled.
    /// @return wethSpentAmount Amount of WETH spent on the given set of orders.
    /// @return makerAssetAcquiredAmount Amount of maker asset acquired from the given set of orders.
    function marketBuyOrdersWithEth(
        IZeroExV3Market.Order[] memory orders,
        uint256 makerAssetBuyAmount,
        bytes[] memory signatures,
        uint256[] memory ethFeeAmounts,
        address payable[] memory feeRecipients
    ) public payable returns (
        uint256 wethSpentAmount,
        uint256 makerAssetAcquiredAmount
    ) {
        uint256 ethValue;
        for (uint256 i = 0; i < orders.length; i++) {
            ethValue += (orders[i].takerAssetAmount + orders[i].takerFee);
        }
        IZeroExV3Market(EXCHANGE).marketBuyOrdersWithEth{value : ethValue}
        (orders, makerAssetBuyAmount, signatures, ethFeeAmounts, feeRecipients, msg.sender);
    }
}