// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// @dev Solmate's ERC20 is used instead of OZ's ERC20 so we can use safeTransferLib for cheaper safeTransfers for
// ETH and ERC20 tokens
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {PotionPool} from "./PotionPool.sol";
import {PotionPair} from "./PotionPair.sol";
import {PotionRouter} from "./PotionRouter.sol";
import {PotionPairETH} from "./PotionPairETH.sol";
import {IPotionPairRegistry, RegisteredPairParams} from "./IPotionPairRegistry.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";
import {PotionPairERC20} from "./PotionPairERC20.sol";
import {PotionPairCloner} from "./lib/PotionPairCloner.sol";
import {IPotionPairFactoryLike} from "./IPotionPairFactoryLike.sol";
import {PotionPairEnumerableETH} from "./PotionPairEnumerableETH.sol";
import {PotionPairEnumerableERC20} from "./PotionPairEnumerableERC20.sol";
import {PotionPairMissingEnumerableETH} from "./PotionPairMissingEnumerableETH.sol";
import {PotionPairMissingEnumerableERC20} from "./PotionPairMissingEnumerableERC20.sol";

contract PotionPairFactory is Ownable, IPotionPairFactoryLike {
    using PotionPairCloner for address;
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    bytes4 private constant INTERFACE_ID_ERC721_ENUMERABLE =
        type(IERC721Enumerable).interfaceId;

    uint256 internal constant MAX_PROTOCOL_FEE = 0.10e18; // 10%, must <= 1 - MAX_FEE

    PotionPairEnumerableETH public immutable enumerableETHTemplate;
    PotionPairMissingEnumerableETH
        public immutable missingEnumerableETHTemplate;
    PotionPairEnumerableERC20 public immutable enumerableERC20Template;
    PotionPairMissingEnumerableERC20
        public immutable missingEnumerableERC20Template;
    address payable public override protocolFeeRecipient;

    // Units are in base 1e18
    uint256 public override protocolFeeMultiplier;

    mapping(ICurve => bool) public bondingCurveAllowed;
    mapping(address => bool) public override callAllowed;
    struct RouterStatus {
        bool allowed;
        bool wasEverAllowed;
    }
    mapping(PotionRouter => RouterStatus) public override routerStatus;

    IPotionPairRegistry public pairRegistry;

    event NewPair(address pairAddress, address poolAddress);
    event TokenDeposit(address pairAddress);
    event NFTDeposit(address pairAddress);
    event ProtocolFeeRecipientUpdate(address recipientAddress);
    event ProtocolFeeMultiplierUpdate(uint256 newMultiplier);
    event BondingCurveStatusUpdate(ICurve bondingCurve, bool isAllowed);
    event CallTargetStatusUpdate(address target, bool isAllowed);
    event RouterStatusUpdate(PotionRouter router, bool isAllowed);
    event RegistryStatusUpdate(IPotionPairRegistry router);

    constructor(
        PotionPairEnumerableETH _enumerableETHTemplate,
        PotionPairMissingEnumerableETH _missingEnumerableETHTemplate,
        PotionPairEnumerableERC20 _enumerableERC20Template,
        PotionPairMissingEnumerableERC20 _missingEnumerableERC20Template,
        address payable _protocolFeeRecipient,
        uint256 _protocolFeeMultiplier
    ) {
        enumerableETHTemplate = _enumerableETHTemplate;
        missingEnumerableETHTemplate = _missingEnumerableETHTemplate;
        enumerableERC20Template = _enumerableERC20Template;
        missingEnumerableERC20Template = _missingEnumerableERC20Template;
        protocolFeeRecipient = _protocolFeeRecipient;

        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Fee too large");
        protocolFeeMultiplier = _protocolFeeMultiplier;
    }

    /**
     * External functions
     */

    /**
        @notice Creates a pair contract using EIP-1167.
        @param _nft The NFT contract of the collection the pair trades
        @param _bondingCurve The bonding curve for the pair to price NFTs, must be whitelisted
        @param _assetRecipient The address that will receive the assets traders give during trades.
                              If set to address(0), assets will be sent to the pool address.
                              Not available to TRADE pools. 
        @param _fee The fee taken by the LP in each trade.
        @param _initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pair
        @return pair The new pair
     */
    struct CreateETHPairParams {
        string poolName;
        string poolSymbol;
        IERC721 nft;
        ICurve bondingCurve;
        uint96 fee;
        uint96 specificNftFee;
        uint32 reserveRatio;
        bool supportRoyalties;
        uint256[] initialNFTIDs;
        string metadataURI;
    }

    function createPairETH(CreateETHPairParams calldata params)
        external
        payable
        returns (PotionPairETH pair, PotionPool pool)
    {
        require(
            bondingCurveAllowed[params.bondingCurve],
            "Bonding curve not whitelisted"
        );

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try
            IERC165(address(params.nft)).supportsInterface(
                INTERFACE_ID_ERC721_ENUMERABLE
            )
        returns (bool isEnumerable) {
            template = isEnumerable
                ? address(enumerableETHTemplate)
                : address(missingEnumerableETHTemplate);
        } catch {
            template = address(missingEnumerableETHTemplate);
        }

        pair = PotionPairETH(
            payable(
                template.cloneETHPair(this, params.bondingCurve, params.nft)
            )
        );

        pool = new PotionPool(pair, params.poolName, params.poolSymbol);

        _registerPairOrFail(msg.sender, params.nft, pair, pool);

        _initializePairETH(
            pair,
            pool,
            params.nft,
            params.fee,
            params.specificNftFee,
            params.reserveRatio,
            params.supportRoyalties,
            params.initialNFTIDs,
            params.metadataURI
        );

        emit NewPair(address(pair), address(pool));
    }

    /**
        @notice Creates a pair contract using EIP-1167.
        @param _nft The NFT contract of the collection the pair trades
        @param _bondingCurve The bonding curve for the pair to price NFTs, must be whitelisted
        @param _assetRecipient The address that will receive the assets traders give during trades.
                                If set to address(0), assets will be sent to the pool address.
                                Not available to TRADE pools.
        @param _fee The fee taken by the LP in each trade.
        @param _initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pair
        @param _initialTokenBalance The initial token balance sent from the sender to the new pair
        @return pair The new pair
     */
    struct CreateERC20PairParams {
        string poolName;
        string poolSymbol;
        ERC20 token;
        IERC721 nft;
        ICurve bondingCurve;
        uint96 fee;
        uint96 specificNftFee;
        uint32 reserveRatio;
        bool supportRoyalties;
        uint256[] initialNFTIDs;
        uint256 initialTokenBalance;
        string metadataURI;
    }

    function createPairERC20(CreateERC20PairParams calldata params)
        external
        returns (PotionPairERC20 pair, PotionPool pool)
    {
        require(
            bondingCurveAllowed[params.bondingCurve],
            "Bonding curve not whitelisted"
        );

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try
            IERC165(address(params.nft)).supportsInterface(
                INTERFACE_ID_ERC721_ENUMERABLE
            )
        returns (bool isEnumerable) {
            template = isEnumerable
                ? address(enumerableERC20Template)
                : address(missingEnumerableERC20Template);
        } catch {
            template = address(missingEnumerableERC20Template);
        }

        pair = PotionPairERC20(
            payable(
                template.cloneERC20Pair(
                    this,
                    params.bondingCurve,
                    params.nft,
                    params.token
                )
            )
        );

        pool = new PotionPool(pair, params.poolName, params.poolSymbol);

        _registerPairOrFail(msg.sender, params.nft, pair, pool);

        _initializePairERC20(InitializePairERC20Params(
            pair,
            pool,
            params.token,
            params.nft,
            params.fee,
            params.specificNftFee,
            params.reserveRatio,
            params.supportRoyalties,
            params.initialNFTIDs,
            params.initialTokenBalance,
            params.metadataURI
        ));

        emit NewPair(address(pair), address(pool));
    }

    /**
        @notice Checks if an address is a PotionPair. Uses the fact that the pairs are EIP-1167 minimal proxies.
        @param potentialPair The address to check
        @param variant The pair variant (NFT is enumerable or not, pair uses ETH or ERC20)
        @return True if the address is the specified pair variant, false otherwise
     */
    function isPair(address potentialPair, PairVariant variant)
        public
        view
        override
        returns (bool)
    {
        if (variant == PairVariant.ENUMERABLE_ERC20) {
            return
                PotionPairCloner.isERC20PairClone(
                    address(this),
                    address(enumerableERC20Template),
                    potentialPair
                );
        } else if (variant == PairVariant.MISSING_ENUMERABLE_ERC20) {
            return
                PotionPairCloner.isERC20PairClone(
                    address(this),
                    address(missingEnumerableERC20Template),
                    potentialPair
                );
        } else if (variant == PairVariant.ENUMERABLE_ETH) {
            return
                PotionPairCloner.isETHPairClone(
                    address(this),
                    address(enumerableETHTemplate),
                    potentialPair
                );
        } else if (variant == PairVariant.MISSING_ENUMERABLE_ETH) {
            return
                PotionPairCloner.isETHPairClone(
                    address(this),
                    address(missingEnumerableETHTemplate),
                    potentialPair
                );
        } else {
            // invalid input
            return false;
        }
    }

    /**
        @notice Allows receiving ETH in order to receive protocol fees
     */
    receive() external payable {}

    /**
     * Admin functions
     */

    /**
        @notice Withdraws the ETH balance to the protocol fee recipient.
        Only callable by the owner.
     */
    function withdrawETHProtocolFees() external onlyOwner {
        protocolFeeRecipient.safeTransferETH(address(this).balance);
    }

    /**
        @notice Withdraws ERC20 tokens to the protocol fee recipient. Only callable by the owner.
        @param token The token to transfer
        @param amount The amount of tokens to transfer
     */
    function withdrawERC20ProtocolFees(ERC20 token, uint256 amount)
        external
        onlyOwner
    {
        token.safeTransfer(protocolFeeRecipient, amount);
    }

    /**
        @notice Changes the protocol fee recipient address. Only callable by the owner.
        @param _protocolFeeRecipient The new fee recipient
     */
    function changeProtocolFeeRecipient(address payable _protocolFeeRecipient)
        external
        onlyOwner
    {
        require(_protocolFeeRecipient != address(0), "0 address");
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdate(_protocolFeeRecipient);
    }

    /**
        @notice Changes the protocol fee multiplier. Only callable by the owner.
        @param _protocolFeeMultiplier The new fee multiplier, 18 decimals
     */
    function changeProtocolFeeMultiplier(uint256 _protocolFeeMultiplier)
        external
        onlyOwner
    {
        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Fee too large");
        protocolFeeMultiplier = _protocolFeeMultiplier;
        emit ProtocolFeeMultiplierUpdate(_protocolFeeMultiplier);
    }

    /**
        @notice Sets the whitelist status of a bonding curve contract. Only callable by the owner.
        @param bondingCurve The bonding curve contract
        @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setBondingCurveAllowed(ICurve bondingCurve, bool isAllowed)
        external
        onlyOwner
    {
        bondingCurveAllowed[bondingCurve] = isAllowed;
        emit BondingCurveStatusUpdate(bondingCurve, isAllowed);
    }

    /**
        @notice Sets the whitelist status of a contract to be called arbitrarily by a pair.
        Only callable by the owner.
        @param target The target contract
        @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setCallAllowed(address payable target, bool isAllowed)
        external
        onlyOwner
    {
        // ensure target is not / was not ever a router
        if (isAllowed) {
            require(
                !routerStatus[PotionRouter(target)].wasEverAllowed,
                "Can't call router"
            );
        }

        callAllowed[target] = isAllowed;
        emit CallTargetStatusUpdate(target, isAllowed);
    }

    /**
        @notice Updates the router whitelist. Only callable by the owner.
        @param _router The router
        @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setRouterAllowed(PotionRouter _router, bool isAllowed)
        external
        onlyOwner
    {
        // ensure target is not arbitrarily callable by pairs
        if (isAllowed) {
            require(!callAllowed[address(_router)], "Can't call router");
        }
        routerStatus[_router] = RouterStatus({
            allowed: isAllowed,
            wasEverAllowed: true
        });

        emit RouterStatusUpdate(_router, isAllowed);
    }

    /**
        @notice Updates the registry. Only callable by the owner.
        @param _pairRegistry The registry to use. Set to address(0) to disable.
     */
    function setRegistry(IPotionPairRegistry _pairRegistry) external onlyOwner {
        pairRegistry = _pairRegistry;

        emit RegistryStatusUpdate(_pairRegistry);
    }

    /**
     * Internal functions
     */

    function _initializePairETH(
        PotionPairETH _pair,
        PotionPool _pool,
        IERC721 _nft,
        uint96 _fee,
        uint96 _specificNftFee,
        uint32 _reserveRatio,
        bool _supportRoyalties,
        uint256[] calldata _initialNFTIDs,
        string calldata _metadataURI
    ) internal {
        // initialize pair
        _pair.initialize(
            msg.sender,
            address(_pool),
            _fee,
            _specificNftFee,
            _reserveRatio,
            _supportRoyalties,
            _metadataURI
        );

        // transfer initial ETH to pair
        payable(address(_pair)).safeTransferETH(msg.value);

        // transfer initial NFTs from sender to pair
        uint256 numNFTs = _initialNFTIDs.length;
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(
                msg.sender,
                address(_pair),
                _initialNFTIDs[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    struct InitializePairERC20Params{
        PotionPairERC20 pair;
        PotionPool pool;
        ERC20 token;
        IERC721 nft;
        uint96 fee;
        uint96 specificNftFee;
        uint32 reserveRatio;
        bool supportRoyalties;
        uint256[] initialNFTIDs;
        uint256 initialTokenBalance;
        string metadataURI;
    }

    function _initializePairERC20(InitializePairERC20Params memory params) internal {
        // initialize pair
        params.pair.initialize(
            msg.sender,
            address(params.pool),
            params.fee,
            params.specificNftFee,
            params.reserveRatio,
            params.supportRoyalties,
            params.metadataURI
        );

        // transfer initial tokens to pair
        params.token.safeTransferFrom(
            msg.sender,
            address(params.pair),
            params.initialTokenBalance
        );

        // transfer initial NFTs from sender to pair
        uint256 numNFTs = params.initialNFTIDs.length;
        for (uint256 i; i < numNFTs; ) {
            params.nft.safeTransferFrom(
                msg.sender,
                address(params.pair),
                params.initialNFTIDs[i]
            );

            unchecked {
                ++i;
            }
        }
    }

    function _registerPairOrFail(
        address _creator,
        IERC721 _nft,
        PotionPair _pair,
        PotionPool _pool
    ) internal {
        // if pair registry is set, require pair to be registered.
        if (address(pairRegistry) == address(0)) {
            return;
        }

        bool registered = pairRegistry.registerPair(
            RegisteredPairParams({
                nft: address(_nft),
                pair: address(_pair),
                pool: address(_pool),
                creator: _creator
            })
        );
        // register pair
        require(registered, "Pool registration failed");
    }

    /** 
      @dev Used to deposit NFTs into a pair after creation and emit an event for indexing (if recipient is indeed a pair)
    */
    function depositNFTs(
        IERC721 _nft,
        uint256[] calldata ids,
        address recipient
    ) external {
        // transfer NFTs from caller to recipient
        uint256 numNFTs = ids.length;
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(msg.sender, recipient, ids[i]);

            unchecked {
                ++i;
            }
        }
        if (
            isPair(recipient, PairVariant.ENUMERABLE_ERC20) ||
            isPair(recipient, PairVariant.ENUMERABLE_ETH) ||
            isPair(recipient, PairVariant.MISSING_ENUMERABLE_ERC20) ||
            isPair(recipient, PairVariant.MISSING_ENUMERABLE_ETH)
        ) {
            emit NFTDeposit(recipient);
        }
    }

    /**
      @dev Used to deposit ERC20s into a pair after creation and emit an event for indexing (if recipient is indeed an ERC20 pair and the token matches)
     */
    function depositERC20(
        ERC20 token,
        address recipient,
        uint256 amount
    ) external {
        token.safeTransferFrom(msg.sender, recipient, amount);
        if (
            isPair(recipient, PairVariant.ENUMERABLE_ERC20) ||
            isPair(recipient, PairVariant.MISSING_ENUMERABLE_ERC20)
        ) {
            if (token == PotionPairERC20(recipient).token()) {
                emit TokenDeposit(recipient);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
abstract contract ERC20 {
    /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*///////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*///////////////////////////////////////////////////////////////
                           EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*///////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*///////////////////////////////////////////////////////////////
                              ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*///////////////////////////////////////////////////////////////
                              EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            bytes32 digest = keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    DOMAIN_SEPARATOR(),
                    keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
                )
            );

            address recoveredAddress = ecrecover(digest, v, r, s);
            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_PERMIT_SIGNATURE");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256(bytes("1")),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Modified from Gnosis (https://github.com/gnosis/gp-v2-contracts/blob/main/src/contracts/libraries/GPv2SafeERC20.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
library SafeTransferLib {
    /*///////////////////////////////////////////////////////////////
                            ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool callStatus;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(callStatus, "ETH_TRANSFER_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                           ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(from, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "from" argument.
            mstore(add(freeMemoryPointer, 36), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 100 because the calldata length is 4 + 32 * 3.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 100, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool callStatus;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata to memory piece by piece:
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000) // Begin with the function selector.
            mstore(add(freeMemoryPointer, 4), and(to, 0xffffffffffffffffffffffffffffffffffffffff)) // Mask and append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Finally append the "amount" argument. No mask as it's a full 32 byte value.

            // Call the token and store if it succeeded or not.
            // We use 68 because the calldata length is 4 + 32 * 2.
            callStatus := call(gas(), token, 0, freeMemoryPointer, 68, 0, 0)
        }

        require(didLastOptionalReturnCallSucceed(callStatus), "APPROVE_FAILED");
    }

    /*///////////////////////////////////////////////////////////////
                         INTERNAL HELPER LOGIC
    //////////////////////////////////////////////////////////////*/

    function didLastOptionalReturnCallSucceed(bool callStatus) private pure returns (bool success) {
        assembly {
            // Get how many bytes the call returned.
            let returnDataSize := returndatasize()

            // If the call reverted:
            if iszero(callStatus) {
                // Copy the revert message into memory.
                returndatacopy(0, 0, returnDataSize)

                // Revert with the same message.
                revert(0, returnDataSize)
            }

            switch returnDataSize
            case 32 {
                // Copy the return data into memory.
                returndatacopy(0, 0, returnDataSize)

                // Set success to whether it returned true.
                success := iszero(iszero(mload(0)))
            }
            case 0 {
                // There was no return data.
                success := 1
            }
            default {
                // It returned some malformed input.
                success := 0
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/**                                                                                 
          ..........                                                            
          ..........                                                            
          .....*****.....                                                       
          .....*****.....                                                       
          .....**********....................                                   
          .....**********....................                                   
               .....********************(((((..........                         
               .....********************(((((..........                         
          .....***************(((((((((((((((((((((((((.....                    
          .....***************(((((((((((((((((((((((((.....                    
               .....*****((((((((((((((((((((***************.....               
               .....*****((((((((((((((((((((***************.....               
          .....***************(((((((((((((((((((((((((((((((((((.....          
          .....***************(((((((((((((((((((((((((((((((((((.....          
     ......................................................................     
     ......................................................................     
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
               .....(((((((((((((((((((((((((((((((((((.....                    
               .....(((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
     .....**************************************************.....               
     .....**************************************************.....               
     ............................................................               
     ............................................................    
 @@@@@@@             @@   @@                                  
/@@////@@           /@@  //                                   
/@@   /@@  @@@@@@  @@@@@@ @@  @@@@@@  @@@@@@@                 
/@@@@@@@  @@////@@///@@/ /@@ @@////@@//@@///@@                
/@@////  /@@   /@@  /@@  /@@/@@   /@@ /@@  /@@                
/@@      /@@   /@@  /@@  /@@/@@   /@@ /@@  /@@                
/@@      //@@@@@@   //@@ /@@//@@@@@@  @@@  /@@                
//        //////     //  //  //////  ///   //                 
 @@@@@@@                    @@                              @@
/@@////@@                  /@@                             /@@
/@@   /@@ @@@@@@  @@@@@@  @@@@@@  @@@@@@   @@@@@   @@@@@@  /@@
/@@@@@@@ //@@//@ @@////@@///@@/  @@////@@ @@///@@ @@////@@ /@@
/@@////   /@@ / /@@   /@@  /@@  /@@   /@@/@@  // /@@   /@@ /@@
/@@       /@@   /@@   /@@  /@@  /@@   /@@/@@   @@/@@   /@@ /@@
/@@      /@@@   //@@@@@@   //@@ //@@@@@@ //@@@@@ //@@@@@@  @@@
//       ///     //////     //   //////   /////   //////  /// 
*/

import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { FixedPointMathLib } from "./lib/FixedPointMathLibV2.sol";
import { PotionPair } from "./PotionPair.sol";

/**
  @author 10xdegen
  @notice Potion Liquidity Pool implementation.
  @dev Inspired by the ERC4626 tokenized vault adapted for use with Potion (modified sudoswap) trading pairs.
  
  The vault's backing assset is the underlying PotionPair.
  The quanitity of the backing asset is equal to the sum of the quantity of NFTs that have been deposited into the pool.
  When shares of the pools are redeemed, they are conisdered redeemable for a non-determinstic NFT from the pool
  and the amounf of ETH in the pool divided by the quantity of NFTs.
  when a user mints an LP token they deposit 1 NFT and an equal amount of
  ETH/ERC20 in the pool (calculated based on the pricing logic of the pair).
  Each token is can be redeemed for 1 NFT and its ETH/ERC20 equivalent.


  If the pool liquidity is drained of NFTs, the remaining LP tokens will
  be redeemable for the equivalent of the NFTs in fungible tokens.

  This means that impermanent loss can mean loss of your NFTs!
  only deposit floor NFTs you would be comfortable selling.

  There is also no guarantee that the NFTs you deposited will be the ones you
  withdraw when you unstake. You have been warned.

  (Because everybody reads the contract, right?)

  - 10xdegen
*/
contract PotionPool is ERC20 {
  using SafeMath for uint256;
  using FixedPointMathLib for uint256;

  /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

  event Deposit(
    address indexed caller,
    address indexed receiver,
    address indexed owner,
    uint256[] nftIds,
    uint256 fungibleTokens,
    uint256 shares
  );

  event Withdraw(
    address indexed caller,
    address indexed receiver,
    address indexed owner,
    uint256[] nftIds,
    uint256 fungibleTokens,
    uint256 fromFees,
    uint256 shares
  );

  /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

  // The pair this LP is associated with.
  // Swaps are done directly via the pair (or router).
  // The Pool manages deposit/withdrawal
  // logic for the pair like a shared vault.
  PotionPair public immutable pair;

  // The initial number of shares minted per deposited NFT when the pool has accrued no fees.
  uint256 public constant SHARES_PER_NFT = 10**20;

  // The minimum nuber of NFTs a pair must hold to support trading.
  uint256 public constant MIN_NFT_LIQUIDITY = 1;

  // The minimum amount of liquidity that the pool must hold to function.
  uint256 public constant MINIMUM_LIQUIDITY =
    SHARES_PER_NFT * MIN_NFT_LIQUIDITY;

  /*//////////////////////////////////////////////////////////////
                             MUTABLE STATE
        //////////////////////////////////////////////////////////////*/

  /*//////////////////////////////////////////////////////////////
                                    CONSTRUCTOR
        //////////////////////////////////////////////////////////////*/

  constructor(
    PotionPair _pair,
    string memory _name,
    string memory _symbol
  ) ERC20(_name, _symbol, 18) {
    pair = _pair;
  }

  /*//////////////////////////////////////////////////////////////
                        WRITE FUNCS
    //////////////////////////////////////////////////////////////*/

  /**
    @notice Deposits the NFTs and (fungible) Tokens to the vault. The token deposit must equal numNfts * nftSpotPrice(). Returns an LP token which is used to redeem assets from the vault.
    @param nftIds The list of NFT ids to deposit.
    @param tokens The amount of tokens to deposit. After the initial deposit, must be greater than getRequiredDeposit(nftIds.length).
    @param owner The owner of the NFTs and tokens to deposit.
    @param receiver The receiver of newly minted shares.
    @return shares The number of ERC20 vault shares minted.
  */
  function depositNFTsAndTokens(
    uint256[] memory nftIds,
    uint256 tokens,
    address owner,
    address receiver
  ) external payable returns (uint256 shares) {
    uint256 supply = totalSupply;
    uint256 numNfts = nftIds.length;
    shares = getSharesForAssets(numNfts);

    // in order to simplify deposit/withdrawal of fee rewards without staking,
    // we require the fee per share to be included in the deposit..
    if (supply > 0) {
      // require deposit to be 50/50 between NFTs and tokens+fees
      uint256 tokenEquivalent = getRequiredDeposit(numNfts);
      require(
        tokens >= tokenEquivalent,
        "Token deposit should be greater than getRequiredDeposit(numNfts)"
      );
      // calcualte shares
      require(shares != 0, "ZERO_SHARES");
    }

    // deposit NFTs
    pair.depositNfts(owner, nftIds);

    // deposit tokens
    pair.depositFungibleTokens{ value: msg.value }(owner, tokens);

    // burn minimum liquidity on the first deposit.
    if (supply == 0) {
      _mint(address(0), MINIMUM_LIQUIDITY);
    }

    // mint tokens to depositor
    _mint(receiver, shares);
    emit Deposit(msg.sender, owner, receiver, nftIds, tokens, shares);
  }

  // returns the number of NFTs and fungible tokens withdrawn.
  // when the number of shares redeemed is less than the number required to withdraw an NFT,
  //
  // the remaining shares will converted to a sell order for the equivalent in NFTs.
  function redeemShares(
    uint256 shares,
    address receiver,
    address owner
  )
    public
    returns (
      uint256[] memory nftIds,
      uint256 tokens,
      uint256 fromFees
    )
  {
    require(shares <= totalSupply - MINIMUM_LIQUIDITY, "INSUFFICIENT_SHARES");

    // get quantities to redeem
    uint256 numNfts;
    uint256 protocolFee;
    (numNfts, tokens, fromFees, protocolFee) = getAssetsForShares(shares);

    // save gas on limited approvals
    if (msg.sender != owner) {
      uint256 allowed = allowance[owner][msg.sender];
      require(allowed >= shares, "INSUFFICIENT_ALLOWANCE");
      if (allowed != type(uint256).max)
        allowance[owner][msg.sender] = allowed.sub(shares);
    }

    // burn the owner's shares (must happen after calculating fees)
    _burn(owner, shares);

    // redeem the first N nfts
    // TODO randomize, or specify id for fee.
    // rarity sorting?
    if (numNfts > 0) {
      nftIds = pair.getAllHeldIds(numNfts);

      // Need to transfer before minting or ERC777s could reenter.
      pair.withdrawNfts(receiver, nftIds);
    }

    if (protocolFee > 0) {
      // send protocol fee to factory
      pair.withdrawFungibleTokens(address(pair.factory()), protocolFee, 0);
    }

    pair.withdrawFungibleTokens(owner, tokens, fromFees);

    // emit withdraw event
    emit Withdraw(
      msg.sender,
      receiver,
      owner,
      nftIds,
      tokens,
      fromFees,
      shares
    );
  }

  /*//////////////////////////////////////////////////////////////
                            READ FUNCS
    //////////////////////////////////////////////////////////////*/

  // get the equivalent value of NFTs in fungible tokens (for deposits/withdrawals).
  function getRequiredDeposit(uint256 numNfts)
    public
    view
    returns (uint256 total)
  {
    (uint256 nftBalance, uint256 tokenBalance) = pair.getBalances();

    return _getRequiredDeposit(numNfts, nftBalance, tokenBalance);
  }

  // returns the total value of assets held in the pool (in the fungible token).
  function getTotalValue() public view returns (uint256 tokenEquivalent) {
    (, uint256 tokenBalance) = pair.getBalances();
    uint256 feeBalance = pair.accruedFees();
    // we multiply token balance by 2 since the NFT value the is equal to the token balance.
    tokenEquivalent = tokenBalance.mul(2).add(feeBalance);
  }

  // returns the number of shares to mint for a deposit of the given amounts.
  function getSharesForAssets(uint256 numNfts)
    public
    view
    returns (uint256 shares)
  {
    uint256 supply = totalSupply;

    if (numNfts == 0) {
      return 0;
    }

    if (supply == 0) {
      // convert the nft into fractional shares internally.
      // shares can be redeemed for whole NFTs or fungible tokens.
      // the initial supplier determines the initial price / deposit ratio.
      return numNfts.mul(SHARES_PER_NFT).sub(MINIMUM_LIQUIDITY);
    }

    // the shares minted is equal to the ratio between the value of deposit to the total value in the pool
    uint256 totalValue = getTotalValue();

    // depositValue = numNfts * spotPrice * 2
    // shares = depositValue / totalValue
    shares = getRequiredDeposit(numNfts.mul(2)).mul(supply).div(
      getTotalValue()
    );
  }

  // returns the number of nfts and tokens redeemed by the given nuber of shares.
  function getAssetsForShares(uint256 shares)
    public
    view
    returns (
      uint256 numNfts,
      uint256 tokenAmount,
      uint256 fromFees,
      uint256 protocolFee
    )
  {
    if (shares == 0) {
      return (0, 0, 0, 0);
    }

    (uint256 nftBalance, uint256 tokenBalance) = pair.getBalances();
    uint256 feeBalance = pair.accruedFees();
    uint256 supply = totalSupply;
    uint256 totalValue = getTotalValue();

    // calculate the pro-rata share of the pool NFTs.
    // we attempt to withdraw the maximum number of NFTs for the given shares, rounding up.
    numNfts = nftBalance.mulDivUp(shares, supply);

    // when few NFTs exist in the pool, rounding up may result in a value greater than the supplied shares.
    // we will round down in that case, and add the difference to the remainder.
    uint256 minShares = getSharesForAssets(numNfts);
    if (minShares > shares) {
      numNfts = numNfts.sub(1);
      minShares = getSharesForAssets(numNfts);
    }

    // when few NFTs exist in the pool, withdrawals may result in withdrawing the last NFT.
    // in that case, we will withdraw the equivalent value of the last NFT as fungible tokens.
    if (numNfts > nftBalance.sub(MIN_NFT_LIQUIDITY)) {
      numNfts = nftBalance.sub(MIN_NFT_LIQUIDITY);
      minShares = getSharesForAssets(numNfts);
    }

    // catch-all to prevent overflow.
    require(
      shares >= minShares,
      "internal error: share value is less than withdraw value"
    );

    // withdraw tokens equal to the value of the withdrawn NFTs.
    tokenAmount = _getRequiredDeposit(numNfts, nftBalance, tokenBalance);

    // calculate the value of the remainder to be withdrawn (as fungible tokens).
    // this remainder is redeemed as a fractional sale to the pool,
    // and the protocol fee is deducted.
    uint256 remainder;
    (remainder, protocolFee) = _calculateRemainder(
      shares,
      minShares,
      totalValue,
      supply
    );

    // remainders are redeemed first from fees, then from the pool.
    fromFees = FixedPointMathLib.min(remainder, feeBalance);

    tokenAmount = tokenAmount.add(remainder.sub(fromFees));
  }

  /*//////////////////////////////////////////////////////////////
                        INTERNAL READ FUNCS
    //////////////////////////////////////////////////////////////*/

  // get the equivalent value of NFTs in fungible tokens (for deposits).
  // must equal the value of the NFTs in the pool.
  // the returned fee is included in the total, only used for internal calculations.
  function _getRequiredDeposit(
    uint256 numNfts,
    uint256 nftBalance,
    uint256 tokenBalance
  ) internal pure returns (uint256 total) {
    if (nftBalance == 0) {
      // the pool is being initialized, no min deposit required.
      return 0;
    }
    // simply equal to the ratio of assets in the pool.
    total = numNfts.mul(tokenBalance).div(nftBalance);
  }

  function _calculateRemainder(
    uint256 shares,
    uint256 minShares,
    uint256 totalValue,
    uint256 supply
  ) internal view returns (uint256 remainder, uint256 protocolFee) {
    // remainder redeemed from the remaining shares.
    remainder = shares.sub(minShares).mulDivDown(totalValue, supply);
    if (remainder == 0) {
      return (0, 0);
    }

    // there is a remainder, get the sale value & fee
    uint256 sellPrice;
    (sellPrice, , protocolFee) = pair.getSellNFTQuote(2);
    uint256 fungibleEquivalent = getRequiredDeposit(2);
    remainder = remainder.mul(sellPrice).div(fungibleEquivalent);
    protocolFee = protocolFee.mul(sellPrice).div(fungibleEquivalent);
  }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**                                                                                 
          ..........                                                            
          ..........                                                            
          .....*****.....                                                       
          .....*****.....                                                       
          .....**********....................                                   
          .....**********....................                                   
               .....********************(((((..........                         
               .....********************(((((..........                         
          .....***************(((((((((((((((((((((((((.....                    
          .....***************(((((((((((((((((((((((((.....                    
               .....*****((((((((((((((((((((***************.....               
               .....*****((((((((((((((((((((***************.....               
          .....***************(((((((((((((((((((((((((((((((((((.....          
          .....***************(((((((((((((((((((((((((((((((((((.....          
     ......................................................................     
     ......................................................................     
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
               .....(((((((((((((((((((((((((((((((((((.....                    
               .....(((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
     .....**************************************************.....               
     .....**************************************************.....               
     ............................................................               
     ............................................................    
                                                                               
██████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
██████╔╝██║░░██║░░░██║░░░██║██║░░██║██╔██╗██║
██╔═══╝░██║░░██║░░░██║░░░██║██║░░██║██║╚████║
██║░░░░░╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
╚═╝░░░░░░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝

██████╗░██████╗░░█████╗░████████╗░█████╗░░█████╗░░█████╗░██╗░░░░░
██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░
██████╔╝██████╔╝██║░░██║░░░██║░░░██║░░██║██║░░╚═╝██║░░██║██║░░░░░
██╔═══╝░██╔══██╗██║░░██║░░░██║░░░██║░░██║██║░░██╗██║░░██║██║░░░░░
██║░░░░░██║░░██║╚█████╔╝░░░██║░░░╚█████╔╝╚█████╔╝╚█████╔╝███████╗
╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░░╚════╝░░╚════╝░░╚════╝░╚══════╝

@author: @10xdegen
*/

import {ERC20} from "solmate/tokens/ERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {OwnableWithTransferCallback} from "./lib/OwnableWithTransferCallback.sol";
import {ReentrancyGuard} from "./lib/ReentrancyGuard.sol";
import {SimpleAccessControl} from "./lib/SimpleAccessControl.sol";

import {ICurve} from "./bonding-curves/ICurve.sol";
import {CurveErrorCodes} from "./bonding-curves/CurveErrorCodes.sol";

import {PotionRouter} from "./PotionRouter.sol";
import {IPotionPairFactoryLike} from "./IPotionPairFactoryLike.sol";

import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";

/// @title The base contract for an NFT/TOKEN AMM pair
/// @author Original work by boredGenius and 0xmons, modified by 10xdegen.
/// @notice This implements the core swap logic from NFT to TOKEN
abstract contract PotionPair is
    OwnableWithTransferCallback,
    ReentrancyGuard,
    SimpleAccessControl,
    Pausable
{
    using FixedPointMathLib for uint256;

    /**
     Storage
   */

    // role required to withdaw from pairs
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER_ROLE");

    // 90%, must <= 1 - MAX_PROTOCOL_FEE (set in PotionPairFactory)
    uint256 public constant MAX_FEE = 0.90e18;

    // Minium number of fungible tokens to allow trading.
    uint256 public constant MIN_TOKEN_LIQUIDITY = 1e3;

    // Minium number of NFTs to allow trading.
    uint256 public constant MIN_NFT_LIQUIDITY = 1;

    // The fee that is charged when swapping any NFTs for tokens.
    // Units are in base 1e18
    uint96 public fee;

    // The fee that is charged when buying specific NFTs from the pair.
    uint96 public specificNftFee;

    // The reserve ratio of the fungible token to NFTs in the pool.
    // Max value 1000000 (=100%)
    uint32 public reserveRatio;

    // trading fees accrued by the contract.
    // subtracted from token balance of contract when calculating
    // the balance of reserve tokens in the pair.
    uint256 public accruedFees;

    // The minimum spot price. Used if the bonding curve falls below this price.
    uint256 public minSpotPrice;

    // The maximum spot price. Used if the bonding curve moves above this price.
    uint256 public maxSpotPrice;

    // Whether or not to charge royalty on sales. Requires the NFT to implement the EIP-2981 royalty standard.
    bool public supportRoyalties;

    // An optional metadata URI for the pair.
    string public metadataURI;

    /**
     Modifiers
   */

    modifier onlyWithdrawer() {
        require(hasRole(WITHDRAWER_ROLE, msg.sender));
        _;
    }

    /**
     Events
   */

    event BuyNFTs(address indexed caller, uint256 numNfts, uint256 totalCost);

    event SellNFTs(
        address indexed caller,
        uint256[] nftIds,
        uint256 totalRevenue
    );
    event NFTDeposit(address sender, uint256[] ids);
    event TokenDeposit(address sender, uint256 amount);
    event TokenWithdrawal(address receiver, uint256 amount, uint256 asFees);
    event NFTWithdrawal(address receiver, uint256[] ids);
    event FeeUpdate(uint96 newFee, uint96 newSpecificNftFee);

    /**
     Parameterized Errors
   */
    error BondingCurveError(CurveErrorCodes.Error error);

    /**
     initializer
   */

    /**
      @notice Called during pair creation to set initial parameters
      @dev Only called once by factory to initialize.
      We verify this by making sure that the current owner is address(0). 
      The Ownable library we use disallows setting the owner to be address(0), so this condition
      should only be valid before the first initialize call. 
      @param _owner The owner of the pair
      @param _fee The initial % fee taken by the pair
      @param _specificNftFee The fee charged for purchasing specific NFTs from the pair.
      @param _reserveRatio The weight of the fungible token in the pool
      @param _supportRoyalties Whether or not the pool should enforce the EIP-2981 NFT royalty standard on swaps.
     */
    function initialize(
        address _owner,
        address _withdrawer,
        uint96 _fee,
        uint96 _specificNftFee,
        uint32 _reserveRatio,
        bool _supportRoyalties,
        string calldata _metadataURI
    ) external payable {
        require(owner() == address(0), "Initialized");
        __Ownable_init(_owner);
        __ReentrancyGuard_init();
        _setupRole(DEFAULT_ADMIN_ROLE, _owner);
        _setRoleAdmin(WITHDRAWER_ROLE, DEFAULT_ADMIN_ROLE);
        _grantRole(WITHDRAWER_ROLE, _withdrawer);

        require(_fee < MAX_FEE, "Trade fee must be less than 90%");
        fee = _fee;
        specificNftFee = _specificNftFee;
        reserveRatio = _reserveRatio;
        metadataURI = _metadataURI;

        // check if NFT implements EIP-2981 royalty standard
        supportRoyalties =
            _supportRoyalties &&
            nft().supportsInterface(type(IERC2981).interfaceId);
    }

    /**
     * View functions
     */

    /**
        @dev Used as read function to query the bonding curve for buy pricing info
        @param numNFTs The number of NFTs to buy from the pair
        @param specific Whether to buy specific NFTs from the pair (incurs additional fee)
     */
    function getBuyNFTQuote(uint256 numNFTs, bool specific)
        external
        view
        returns (
            uint256 inputAmount,
            uint256 tradeFee,
            uint256 protocolFee
        )
    {
        return _getBuyNFTQuote(numNFTs, MIN_NFT_LIQUIDITY, specific);
    }

    /**
        @dev Used as read function to query the bonding curve for sell pricing info
        @param numNFTs The number of NFTs to sell to the pair
     */
    function getSellNFTQuote(uint256 numNFTs)
        public
        view
        returns (
            uint256 outputAmount,
            uint256 tradeFee,
            uint256 protocolFee
        )
    {
        (outputAmount, tradeFee, protocolFee, , ) = _getSellNFTQuote(
            numNFTs,
            MIN_TOKEN_LIQUIDITY
        );
    }

    /**
        @notice Returns all NFT IDs held by the pool
        @param maxQuantity The maximum number of NFT IDs to return. Ignored if 0.
        @return nftIds list of NFT IDs held by the pool
     */
    function getAllHeldIds(uint256 maxQuantity)
        external
        view
        virtual
        returns (uint256[] memory nftIds);

    /**
        @notice Returns the pair's variant (NFT is enumerable or not, pair uses ETH or ERC20)
     */
    function pairVariant()
        public
        pure
        virtual
        returns (IPotionPairFactoryLike.PairVariant);

    function factory() public pure returns (IPotionPairFactoryLike _factory) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _factory := shr(
                0x60,
                calldataload(sub(calldatasize(), paramsLength))
            )
        }
    }

    /**
        @notice Returns the type of bonding curve that parameterizes the pair
     */
    function bondingCurve() public pure returns (ICurve _bondingCurve) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _bondingCurve := shr(
                0x60,
                calldataload(add(sub(calldatasize(), paramsLength), 20))
            )
        }
    }

    /**
        @notice Returns the NFT collection that parameterizes the pair
     */
    function nft() public pure returns (IERC721 _nft) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _nft := shr(
                0x60,
                calldataload(add(sub(calldatasize(), paramsLength), 40))
            )
        }
    }

    /**
        @notice Returns the pair's total fungible token balance (either ETH or ERC20)
     */
    function fungibleTokenBalance() public view virtual returns (uint256);

    /**
        @notice Returns the balances of each token in the pair.
     */
    function getBalances()
        public
        view
        returns (uint256 nftBalance, uint256 tokenBalance)
    {
        nftBalance = nft().balanceOf(address(this));
        tokenBalance = fungibleTokenBalance();
    }

    /**
     * External state-changing functions
     */

    /**
        @notice Sends token to the pair in exchange for any `numNFTs` NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
        This swap function is meant for users who are ID agnostic
        @param numNFTs The number of NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from PotionRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    )
        external
        payable
        virtual
        nonReentrant
        whenNotPaused
        returns (uint256 inputAmount)
    {
        // Store locally to remove extra calls
        IPotionPairFactoryLike _factory = factory();
        IERC721 _nft = nft();

        // Input validation
        {
            require(
                (numNFTs > 0) && (numNFTs <= _nft.balanceOf(address(this))),
                "Ask for > 0 and <= balanceOf NFTs"
            );
        }

        // Call bonding curve for pricing information
        uint256 tradeFee;
        uint256 protocolFee;

        // get the quote
        (inputAmount, tradeFee, protocolFee) = _getBuyNFTQuote(
            numNFTs,
            MIN_NFT_LIQUIDITY + 1,
            false
        );

        // Revert if input is more than expected
        require(inputAmount <= maxExpectedTokenInput, "In too many tokens");

        _pullTokenInputAndPayProtocolFee(
            inputAmount,
            isRouter,
            routerCaller,
            _factory,
            protocolFee
        );

        _sendAnyNFTsToRecipient(_nft, nftRecipient, numNFTs);

        _refundTokenToSender(inputAmount);

        // increment collected trading fees
        accruedFees += tradeFee;

        emit BuyNFTs(msg.sender, numNFTs, inputAmount);
    }

    /**
        @notice Sends token to the pair in exchange for a specific set of NFTs
        @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
        This swap is meant for users who want specific IDs. Also higher chance of
        reverting if some of the specified IDs leave the pool before the swap goes through.
        @param nftIds The list of IDs of the NFTs to purchase
        @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
        amount is greater than this value, the transaction will be reverted.
        @param nftRecipient The recipient of the NFTs
        @param isRouter True if calling from PotionRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return inputAmount The amount of token used for purchase
     */
    // TODO(10xdegen): Add a fee / option for this.
    function swapTokenForSpecificNFTs(
        uint256[] calldata nftIds,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable virtual nonReentrant whenNotPaused returns (uint256) {
        // Store locally to remove extra calls
        IPotionPairFactoryLike _factory = factory();

        // Input validation
        {
            require((nftIds.length > 0), "Must ask for > 0 NFTs");
        }

        // get the quote
        (
            uint256 inputAmount,
            uint256 tradeFee,
            uint256 protocolFee
        ) = _getBuyNFTQuote(nftIds.length, MIN_NFT_LIQUIDITY + 1, true);
        // Revert if input is more than expected
        require(inputAmount <= maxExpectedTokenInput, "In too many tokens");

        // increment collected trading fees
        accruedFees += tradeFee;

        _pullTokenInputAndPayProtocolFee(
            inputAmount,
            isRouter,
            routerCaller,
            _factory,
            protocolFee
        );

        _sendSpecificNFTsToRecipient(nft(), nftRecipient, nftIds);

        _refundTokenToSender(inputAmount);

        emit BuyNFTs(msg.sender, nftIds.length, inputAmount);

        return inputAmount;
    }

    /**
        @notice Sends a set of NFTs to the pair in exchange for token
        @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
        @param nftIds The list of IDs of the NFTs to sell to the pair
        @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
        amount is less than this value, the transaction will be reverted.
        @param tokenRecipient The recipient of the token output
        @param isRouter True if calling from PotionRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
        @return outputAmount The amount of token received
     */
    function swapNFTsForToken(
        uint256[] calldata nftIds,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    )
        external
        virtual
        nonReentrant
        whenNotPaused
        returns (uint256 outputAmount)
    {
        // Store locally to remove extra calls
        IPotionPairFactoryLike _factory = factory();

        // Input validation
        {
            require(nftIds.length > 0, "Must ask for > 0 NFTs");
        }

        uint256 tradeFee;
        uint256 protocolFee;
        uint256 royalty;
        address royaltyRecipient;
        // always ensure this is 1 more than the token liquidity in the pool, for the curve
        (
            outputAmount,
            tradeFee,
            protocolFee,
            royalty,
            royaltyRecipient
        ) = _getSellNFTQuote(nftIds.length, MIN_TOKEN_LIQUIDITY + 1);

        // Revert if output is too little
        require(
            outputAmount >= minExpectedTokenOutput,
            "Out too little tokens"
        );

        // increment collected trading fees
        accruedFees += tradeFee;

        // send fungible payments
        // 1. output
        _sendTokenOutput(tokenRecipient, outputAmount);
        // 2. protocol.
        _payProtocolFeeFromPair(_factory, protocolFee);
        // 3. royalty
        if (royalty > 0) {
            _sendTokenOutput(payable(royaltyRecipient), royalty);
        }

        _takeNFTsFromSender(
            msg.sender,
            nft(),
            nftIds,
            _factory,
            isRouter,
            routerCaller
        );

        emit SellNFTs(msg.sender, nftIds, outputAmount);
    }

    /**
      Pool Functions
     */

    /**
        @notice Deposits the NFTs to the pair from the specified address. Should only be called by LP contract.
        @param sender The address sending the token to transfer
        @param nftIds The nfts to deposit
     */
    function depositNfts(address sender, uint256[] calldata nftIds)
        public
        whenNotPaused
    {
        IERC721 _nft = nft();
        uint256 balance = _nft.balanceOf(sender);
        // for (uint256 i = 0; i < nftIds.length; i++) {
        //     address owner = _nft.ownerOf(nftIds[i]);
        // }
        require(balance >= nftIds.length, "Not enough NFTs");

        IPotionPairFactoryLike _factory = factory();
        _takeNFTsFromSender(sender, _nft, nftIds, _factory, false, address(0));
    }

    /**
        @notice Withdraws the NFTs from the pair to the specified address. onlyRole(WITHDRAWER) is in the implemented function.
        @param receiver The address to receive the token to transfer
        @param nftIds The nfts to witdraw
     */
    function withdrawNfts(address receiver, uint256[] calldata nftIds)
        external
        virtual;

    /**
        @notice Safely Deposits the Fungible tokens to the pair from the caller.
        @param from The address to pull the token from.
        @param amount The amount of tokens to deposit.
     */
    function depositFungibleTokens(address from, uint256 amount)
        external
        payable
        virtual;

    /**
        @notice Withdraws the Fungible tokens from the pair to the specified address. 
        @dev can only be called by WITHDRAWER.
        @param receiver The address to receive the token to transfer
        @param amount The amount of tokens to witdraw
        @param fromFees Whether the caller is withdrawing fees or not.
     */
    function withdrawFungibleTokens(
        address receiver,
        uint256 amount,
        uint256 fromFees
    ) external onlyWithdrawer {
        require(amount + fromFees > 0, "Amount must be greater than 0");
        if (fromFees > 0) {
            require(
                fromFees <= accruedFees,
                "FromFees Amount must be less than or equal to fees"
            );
            accruedFees -= fromFees;
        }
        require(
            amount <= fungibleTokenBalance(),
            "Amount must be less than or equal to balance + accrued fees"
        );
        _withdrawFungibleTokens(receiver, amount + fromFees);
        emit TokenWithdrawal(receiver, amount, fromFees);
    }

    /**
      Admin Functions
     */

    /**
        @notice Grants or Revokes the WITHDRAWER role to the specified address.
        @param account The new LP fee percentage, 18 decimals
        @param enabled The new LP fee percentage, 18 decimals
     */
    function setWithdrawerRole(address account, bool enabled)
        external
        onlyOwner
    {
        if (enabled) {
            grantRole(WITHDRAWER_ROLE, account);
        } else {
            revokeRole(WITHDRAWER_ROLE, account);
        }
    }

    /**
        @notice Updates the fees taken by the LP. Only callable by the owner.
        Only callable if the pool is a Trade pool. Reverts if the fee is >=
        MAX_FEE.
        @param newFee The new LP fee percentage, 18 decimals
        @param newSpecificNftFee The new LP fee percentage, 18 decimals
     */
    function changeFee(uint96 newFee, uint96 newSpecificNftFee)
        external
        onlyOwner
    {
        require(newFee < MAX_FEE, "Trade fee must be less than 90%");
        if (fee != newFee || specificNftFee != newSpecificNftFee) {
            fee = newFee;
            specificNftFee = newSpecificNftFee;
            emit FeeUpdate(newFee, newSpecificNftFee);
        }
    }

    /**
        @notice Updates the optional Metadata URI associated with the pair.
        @param _metadataURI The new metadata URI
     */
    function setMetadataURI(string memory _metadataURI) external onlyOwner {
        metadataURI = _metadataURI;
    }

    /**
     * Internal functions
     */

    /**
        @notice Pulls the token input of a trade from the trader and pays the protocol fee.
        @param inputAmount The amount of tokens to be sent
        @param isRouter Whether or not the caller is PotionRouter
        @param routerCaller If called from PotionRouter, store the original caller
        @param _factory The PotionPairFactory which stores PotionRouter allowlist info
        @param protocolFee The protocol fee to be paid
     */
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        IPotionPairFactoryLike _factory,
        uint256 protocolFee
    ) internal virtual;

    /**
        @notice Sends excess tokens back to the caller (if applicable)
        @dev We send ETH back to the caller even when called from PotionRouter because we do an aggregate slippage check for certain bulk swaps. (Instead of sending directly back to the router caller) 
        Excess ETH sent for one swap can then be used to help pay for the next swap.
     */
    function _refundTokenToSender(uint256 inputAmount) internal virtual;

    /**
        @notice Sends protocol fee (if it exists) back to the PotionPairFactory from the pair
     */
    function _payProtocolFeeFromPair(
        IPotionPairFactoryLike _factory,
        uint256 protocolFee
    ) internal virtual;

    /**
        @notice Sends tokens to a recipient
        @param tokenRecipient The address receiving the tokens
        @param outputAmount The amount of tokens to send
     */
    function _sendTokenOutput(
        address payable tokenRecipient,
        uint256 outputAmount
    ) internal virtual;

    /**
        @notice Sends some number of NFTs to a recipient address, ID agnostic
        @dev Even though we specify the NFT address here, this internal function is only 
        used to send NFTs associated with this specific pool.
        @param _nft The address of the NFT to send
        @param nftRecipient The receiving address for the NFTs
        @param numNFTs The number of NFTs to send  
     */
    function _sendAnyNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256 numNFTs
    ) internal virtual;

    /**
        @notice Sends specific NFTs to a recipient address
        @dev Even though we specify the NFT address here, this internal function is only 
        used to send NFTs associated with this specific pool.
        @param _nft The address of the NFT to send
        @param nftRecipient The receiving address for the NFTs
        @param nftIds The specific IDs of NFTs to send  
     */
    function _sendSpecificNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256[] calldata nftIds
    ) internal virtual;

    /**
        @notice Takes NFTs from the caller and sends them into the pair's asset recipient
        @dev This is used by the PotionPair's swapNFTForToken function. 
        @param _nft The NFT collection to take from
        @param nftIds The specific NFT IDs to take
        @param isRouter True if calling from PotionRouter, false otherwise. Not used for
        ETH pairs.
        @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
        ETH pairs.
     */
    function _takeNFTsFromSender(
        address sender,
        IERC721 _nft,
        uint256[] calldata nftIds,
        IPotionPairFactoryLike _factory,
        bool isRouter,
        address routerCaller
    ) internal virtual {
        {
            address _assetRecipient = address(this);
            uint256 numNFTs = nftIds.length;

            if (isRouter) {
                // Verify if router is allowed
                PotionRouter router = PotionRouter(payable(sender));
                (bool routerAllowed, ) = _factory.routerStatus(router);
                require(routerAllowed, "Not router");

                // Call router to pull NFTs
                // If more than 1 NFT is being transfered, we can do a balance check instead of an ownership check, as pools are indifferent between NFTs from the same collection
                if (numNFTs > 1) {
                    uint256 beforeBalance = _nft.balanceOf(_assetRecipient);
                    for (uint256 i = 0; i < numNFTs; ) {
                        router.pairTransferNFTFrom(
                            _nft,
                            routerCaller,
                            _assetRecipient,
                            nftIds[i],
                            pairVariant()
                        );

                        unchecked {
                            ++i;
                        }
                    }
                    require(
                        (_nft.balanceOf(_assetRecipient) - beforeBalance) ==
                            numNFTs,
                        "NFTs not transferred"
                    );
                } else {
                    router.pairTransferNFTFrom(
                        _nft,
                        routerCaller,
                        _assetRecipient,
                        nftIds[0],
                        pairVariant()
                    );
                    require(
                        _nft.ownerOf(nftIds[0]) == _assetRecipient,
                        "NFT not transferred"
                    );
                }
            } else {
                // Pull NFTs directly from sender
                for (uint256 i; i < numNFTs; ) {
                    _nft.safeTransferFrom(sender, _assetRecipient, nftIds[i]);

                    unchecked {
                        ++i;
                    }
                }
            }
        }
    }

    /**
     * internal read functions
     */

    /**
        @dev Used internally to handle calling curve. Important edge case to handle
        when we are calling the method while receiving an eth payment.
     */
    function _getBuyNFTQuote(
        uint256 numNFTs,
        uint256 minNftLiquidity,
        bool specific
    )
        internal
        view
        returns (
            uint256 inputAmount,
            uint256 tradeFee,
            uint256 protocolFee
        )
    {
        require(numNFTs > 0, "Must buy at least 1 NFT");
        // get balances
        (uint256 nftBalance, uint256 tokenBalance) = getBalances();
        require(
            numNFTs + minNftLiquidity <= nftBalance,
            "INSUFFICIENT_NFT_LIQUIDITY"
        );

        // need to subtract the msg.value from balance to get the actual balance before payment
        tokenBalance -= msg.value;

        // if token balance > 0 , first check the price with hte bonding curve
        // if bonding curve == 0, we use min price (fallback)
        if (tokenBalance > 0) {
            // if no nft balance this will revert
            CurveErrorCodes.Error error;
            (error, inputAmount) = bondingCurve().getBuyInfo(
                numNFTs,
                nftBalance, // calculate position on the bonding curve based on circulating supply
                tokenBalance,
                reserveRatio
            );
            // Revert if bonding curve had an error
            if (error != CurveErrorCodes.Error.OK) {
                revert BondingCurveError(error);
            }
        }

        // Account for the specific nft fee, if a specific nft is being bought
        if (specific) {
            inputAmount += inputAmount.fmul(
                specificNftFee,
                FixedPointMathLib.WAD
            );
        }

        // Account for the trade fee
        tradeFee = inputAmount.fmul(fee, FixedPointMathLib.WAD);

        // Add the protocol fee to the required input amount
        protocolFee = inputAmount.fmul(
            factory().protocolFeeMultiplier(),
            FixedPointMathLib.WAD
        );

        inputAmount += tradeFee;
        inputAmount += protocolFee;

        return (inputAmount, tradeFee, protocolFee);
    }

    /**
        @dev Used as read function to query the bonding curve for sell pricing info
        @param numNFTs The number of NFTs to sell to the pair
     */
    function _getSellNFTQuote(uint256 numNFTs, uint256 minTokenLiquidity)
        public
        view
        returns (
            uint256 outputAmount,
            uint256 tradeFee,
            uint256 protocolFee,
            uint256 royalty,
            address royaltyRecipient
        )
    {
        require(numNFTs > 0, "Must sell at least 1 NFT");

        // get balances
        (uint256 nftBalance, uint256 tokenBalance) = getBalances();

        CurveErrorCodes.Error error;
        (error, outputAmount) = bondingCurve().getSellInfo(
            numNFTs,
            nftBalance,
            tokenBalance,
            reserveRatio
        );
        // Revert if bonding curve had an error
        if (error != CurveErrorCodes.Error.OK) {
            revert BondingCurveError(error);
        }

        // Account for the trade fee, only for Trade pools
        tradeFee = outputAmount.fmul(fee, FixedPointMathLib.WAD);

        // Add the protocol fee to the required input amount
        protocolFee = outputAmount.fmul(
            factory().protocolFeeMultiplier(),
            FixedPointMathLib.WAD
        );

        outputAmount -= tradeFee;
        outputAmount -= protocolFee;

        if (supportRoyalties) {
            (royaltyRecipient, royalty) = IERC2981(address(nft())).royaltyInfo(
                0,
                outputAmount
            );
            outputAmount -= royalty;
        }

        require(
            outputAmount + minTokenLiquidity < tokenBalance,
            "INSUFFICIENT__TOKEN_LIQUIDITY"
        );
    }

    /**
        @dev Used internally to grab pair parameters from calldata, see PotionPairCloner for technical details
     */
    function _immutableParamsLength() internal pure virtual returns (uint256);

    /**
        @notice Withdraws the Fungible tokens from the pair to the specified address. onlyRole(WITHDRAWER) is in the implemented function.
        @param receiver The address to receive the token to transfer
        @param amount The amount of tokens to witdraw
     */
    function _withdrawFungibleTokens(address receiver, uint256 amount)
        internal
        virtual;

    /**
     * Owner functions
     */

    /**
        @notice Rescues a specified set of NFTs owned by the pair to the specified address. Only callable by the owner.
        @dev If the NFT is the pair's collection, we also remove it from the id tracking (if the NFT is missing enumerable).
        @param receiver The receiver address to rescue the NFTs to
        @param a The NFT to transfer
        @param nftIds The list of IDs of the NFTs to send to the owner
     */
    function rescueERC721(
        address receiver,
        IERC721 a,
        uint256[] calldata nftIds
    ) external virtual;

    /**
        @notice Rescues ERC20 tokens from the pair to the owner. Only callable by the owner.
        @param receiver The receiver to transfer the tokens to
        @param a The token to transfer
        @param amount The amount of tokens to send to the owner
     */
    function rescueERC20(
        address receiver,
        ERC20 a,
        uint256 amount
    ) external virtual;

    /**
        @notice Allows the pair to make arbitrary external calls to contracts
        whitelisted by the protocol. Only callable by the owner.
        @param target The contract to call
        @param data The calldata to pass to the contract
     */
    function call(address payable target, bytes calldata data)
        external
        onlyOwner
    {
        IPotionPairFactoryLike _factory = factory();
        require(_factory.callAllowed(target), "Target must be whitelisted");
        (bool result, ) = target.call{value: 0}(data);
        require(result, "Call failed");
    }

    /**
        @notice Allows owner to batch multiple calls, forked from: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol 
        @dev Intended for withdrawing/altering pool pricing in one tx, only callable by owner, cannot change owner
        @param calls The calldata for each call to make
        @param revertOnFail Whether or not to revert the entire tx if any of the calls fail
     */
    function multicall(bytes[] calldata calls, bool revertOnFail)
        external
        onlyOwner
    {
        for (uint256 i; i < calls.length; ) {
            (bool success, bytes memory result) = address(this).delegatecall(
                calls[i]
            );
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }

            unchecked {
                ++i;
            }
        }

        // Prevent multicall from malicious frontend sneaking in ownership change
        require(
            owner() == msg.sender,
            "Ownership cannot be changed in multicall"
        );
    }

    /**
      @param _returnData The data returned from a multicall result
      @dev Used to grab the revert string from the underlying call
     */
    function _getRevertMsg(bytes memory _returnData)
        internal
        pure
        returns (string memory)
    {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {PotionPair} from "./PotionPair.sol";
import {IPotionPairFactoryLike} from "./IPotionPairFactoryLike.sol";

contract PotionRouter {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    struct PairSwapAny {
        PotionPair pair;
        uint256 numItems;
    }

    struct PairSwapSpecific {
        PotionPair pair;
        uint256[] nftIds;
    }

    struct RobustPairSwapAny {
        PairSwapAny swapInfo;
        uint256 maxCost;
    }

    struct RobustPairSwapSpecific {
        PairSwapSpecific swapInfo;
        uint256 maxCost;
    }

    struct RobustPairSwapSpecificForToken {
        PairSwapSpecific swapInfo;
        uint256 minOutput;
    }

    struct NFTsForAnyNFTsTrade {
        PairSwapSpecific[] nftToTokenTrades;
        PairSwapAny[] tokenToNFTTrades;
    }

    struct NFTsForSpecificNFTsTrade {
        PairSwapSpecific[] nftToTokenTrades;
        PairSwapSpecific[] tokenToNFTTrades;
    }

    struct RobustPairNFTsFoTokenAndTokenforNFTsTrade {
        RobustPairSwapSpecific[] tokenToNFTTrades;
        RobustPairSwapSpecificForToken[] nftToTokenTrades;
        uint256 inputAmount;
        address payable tokenRecipient;
        address nftRecipient;
    }

    modifier checkDeadline(uint256 deadline) {
        _checkDeadline(deadline);
        _;
    }

    IPotionPairFactoryLike public immutable factory;

    constructor(IPotionPairFactoryLike _factory) {
        factory = _factory;
    }

    /**
        ETH swaps
     */

    /**
        @notice Swaps ETH into NFTs using multiple pairs.
        @param swapList The list of pairs to trade with and the number of NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent ETH amount
     */
    function swapETHForAnyNFTs(
        PairSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        return
            _swapETHForAnyNFTs(swapList, msg.value, ethRecipient, nftRecipient);
    }

    /**
        @notice Swaps ETH into specific NFTs using multiple pairs.
        @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent ETH amount
     */
    function swapETHForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        return
            _swapETHForSpecificNFTs(
                swapList,
                msg.value,
                ethRecipient,
                nftRecipient
            );
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pairs, using
        ETH as the intermediary.
        @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
        @param minOutput The minimum acceptable total excess ETH received
        @param ethRecipient The address that will receive the ETH output
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ETH received
     */
    function swapNFTsForAnyNFTsThroughETH(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(address(this))
        );

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for any NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount =
            _swapETHForAnyNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                ethRecipient,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pairs, using
        ETH as the intermediary.
        @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
        @param minOutput The minimum acceptable total excess ETH received
        @param ethRecipient The address that will receive the ETH output
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ETH received
     */
    function swapNFTsForSpecificNFTsThroughETH(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(address(this))
        );

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for specific NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount =
            _swapETHForSpecificNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                ethRecipient,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        ERC20 swaps

        Note: All ERC20 swaps assume that a single ERC20 token is used for all the pairs involved.
        Swapping using multiple tokens in the same transaction is possible, but the slippage checks
        & the return values will be meaningless, and may lead to undefined behavior.

        Note: The sender should ideally grant infinite token approval to the router in order for NFT-to-NFT
        swaps to work smoothly.
     */

    /**
        @notice Swaps ERC20 tokens into NFTs using multiple pairs.
        @param swapList The list of pairs to trade with and the number of NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function swapERC20ForAnyNFTs(
        PairSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForAnyNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
        @notice Swaps ERC20 tokens into specific NFTs using multiple pairs.
        @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function swapERC20ForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForSpecificNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
        @notice Swaps NFTs into ETH/ERC20 using multiple pairs.
        @param swapList The list of pairs to trade with and the IDs of the NFTs to sell to each.
        @param minOutput The minimum acceptable total tokens received
        @param tokenRecipient The address that will receive the token output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total tokens received
     */
    function swapNFTsForToken(
        PairSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        return _swapNFTsForToken(swapList, minOutput, payable(tokenRecipient));
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pairs, using
        an ERC20 token as the intermediary.
        @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param minOutput The minimum acceptable total excess tokens received
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForAnyNFTsThroughERC20(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(msg.sender)
        );

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for any NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount =
            _swapERC20ForAnyNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        @notice Swaps one set of NFTs into another set of specific NFTs using multiple pairs, using
        an ERC20 token as the intermediary.
        @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param minOutput The minimum acceptable total excess tokens received
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForSpecificNFTsThroughERC20(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(
            trade.nftToTokenTrades,
            0,
            payable(msg.sender)
        );

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for specific NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount =
            _swapERC20ForSpecificNFTs(
                trade.tokenToNFTTrades,
                outputAmount - minOutput,
                nftRecipient
            ) +
            minOutput;
    }

    /**
        Robust Swaps
        These are "robust" versions of the NFT<>Token swap functions which will never revert due to slippage
        Instead, users specify a per-swap max cost. If the price changes more than the user specifies, no swap is attempted. This allows users to specify a batch of swaps, and execute as many of them as possible.
     */

    /**
        @dev We assume msg.value >= sum of values in maxCostPerPair
        @notice Swaps as much ETH for any NFTs as possible, respecting the per-swap max cost.
        @param swapList The list of pairs to trade with and the number of NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function robustSwapETHForAnyNFTs(
        RobustPairSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    )
        external
        payable
        checkDeadline(deadline)
        returns (uint256 remainingValue)
    {
        remainingValue = msg.value;

        // Try doing each swap
        uint256 pairCost;
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (pairCost, , ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
                swapList[i].swapInfo.numItems,
                false
            );

            // If within our maxCost and no  proceed
            if (pairCost <= swapList[i].maxCost) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i].swapInfo.pair.swapTokenForAnyNFTs{
                    value: pairCost
                }(
                    swapList[i].swapInfo.numItems,
                    pairCost,
                    nftRecipient,
                    true,
                    msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
        @dev We assume msg.value >= sum of values in maxCostPerPair
        @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
        @param ethRecipient The address that will receive the unspent ETH input
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function robustSwapETHForSpecificNFTs(
        RobustPairSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) public payable checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = msg.value;
        uint256 pairCost;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (pairCost, , ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
                swapList[i].swapInfo.nftIds.length,
                true
            );

            // If within our maxCost and no  proceed
            if (pairCost <= swapList[i].maxCost) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i]
                    .swapInfo
                    .pair
                    .swapTokenForSpecificNFTs{value: pairCost}(
                    swapList[i].swapInfo.nftIds,
                    pairCost,
                    nftRecipient,
                    true,
                    msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
        @notice Swaps as many ERC20 tokens for any NFTs as possible, respecting the per-swap max cost.
        @param swapList The list of pairs to trade with and the number of NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
        
     */
    function robustSwapERC20ForAnyNFTs(
        RobustPairSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 pairCost;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (pairCost, , ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
                swapList[i].swapInfo.numItems,
                false
            );

            // If within our maxCost and no  proceed
            if (pairCost <= swapList[i].maxCost) {
                remainingValue -= swapList[i].swapInfo.pair.swapTokenForAnyNFTs(
                        swapList[i].swapInfo.numItems,
                        pairCost,
                        nftRecipient,
                        true,
                        msg.sender
                    );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Swaps as many ERC20 tokens for specific NFTs as possible, respecting the per-swap max cost.
        @param swapList The list of pairs to trade with and the IDs of the NFTs to buy from each.
        @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps

        @param nftRecipient The address that will receive the NFT output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return remainingValue The unspent token amount
     */
    function robustSwapERC20ForSpecificNFTs(
        RobustPairSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) public checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 pairCost;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate actual cost per swap
            (pairCost, , ) = swapList[i].swapInfo.pair.getBuyNFTQuote(
                swapList[i].swapInfo.nftIds.length,
                true
            );

            // If within our maxCost and no  proceed
            if (pairCost <= swapList[i].maxCost) {
                remainingValue -= swapList[i]
                    .swapInfo
                    .pair
                    .swapTokenForSpecificNFTs(
                        swapList[i].swapInfo.nftIds,
                        pairCost,
                        nftRecipient,
                        true,
                        msg.sender
                    );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Swaps as many NFTs for tokens as possible, respecting the per-swap min output
        @param swapList The list of pairs to trade with and the IDs of the NFTs to sell to each.
        @param tokenRecipient The address that will receive the token output
        @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
        @return outputAmount The total ETH/ERC20 received
     */
    function robustSwapNFTsForToken(
        RobustPairSwapSpecificForToken[] calldata swapList,
        address payable tokenRecipient,
        uint256 deadline
    ) public checkDeadline(deadline) returns (uint256 outputAmount) {
        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            uint256 pairOutput;

            // Locally scoped to avoid stack too deep error
            {
                (pairOutput, , ) = swapList[i].swapInfo.pair.getSellNFTQuote(
                    swapList[i].swapInfo.nftIds.length
                );
            }

            // If at least equal to our minOutput, proceed
            if (pairOutput >= swapList[i].minOutput) {
                // Do the swap and update outputAmount with how many tokens we got
                outputAmount += swapList[i].swapInfo.pair.swapNFTsForToken(
                    swapList[i].swapInfo.nftIds,
                    0,
                    tokenRecipient,
                    true,
                    msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Buys NFTs with ETH and sells them for tokens in one transaction
        @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
        - ethToNFTSwapList The list of NFTs to buy
        - nftToTokenSwapList The list of NFTs to sell
        - inputAmount The max amount of tokens to send (if ERC20)
        - tokenRecipient The address that receives tokens from the NFTs sold
        - nftRecipient The address that receives NFTs
        - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapETHForSpecificNFTsAndNFTsToToken(
        RobustPairNFTsFoTokenAndTokenforNFTsTrade calldata params
    ) external payable returns (uint256 remainingValue, uint256 outputAmount) {
        {
            remainingValue = msg.value;
            uint256 pairCost;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps; ) {
                // Calculate actual cost per swap
                (pairCost, , ) = params
                    .tokenToNFTTrades[i]
                    .swapInfo
                    .pair
                    .getBuyNFTQuote(
                        params.tokenToNFTTrades[i].swapInfo.nftIds.length,
                        true
                    );

                // If within our maxCost and no  proceed
                if (pairCost <= params.tokenToNFTTrades[i].maxCost) {
                    // We know how much ETH to send because we already did the math above
                    // So we just send that much
                    remainingValue -= params
                        .tokenToNFTTrades[i]
                        .swapInfo
                        .pair
                        .swapTokenForSpecificNFTs{value: pairCost}(
                        params.tokenToNFTTrades[i].swapInfo.nftIds,
                        pairCost,
                        params.nftRecipient,
                        true,
                        msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }

            // Return remaining value to sender
            if (remainingValue > 0) {
                params.tokenRecipient.safeTransferETH(remainingValue);
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps; ) {
                uint256 pairOutput;

                // Locally scoped to avoid stack too deep error
                {
                    (pairOutput, , ) = params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .getSellNFTQuote(
                            params.nftToTokenTrades[i].swapInfo.nftIds.length
                        );
                }

                // If at least equal to our minOutput, proceed
                if (pairOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap and update outputAmount with how many tokens we got
                    outputAmount += params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .swapNFTsForToken(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            0,
                            params.tokenRecipient,
                            true,
                            msg.sender
                        );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
        @notice Buys NFTs with ERC20, and sells them for tokens in one transaction
        @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
        - ethToNFTSwapList The list of NFTs to buy
        - nftToTokenSwapList The list of NFTs to sell
        - inputAmount The max amount of tokens to send (if ERC20)
        - tokenRecipient The address that receives tokens from the NFTs sold
        - nftRecipient The address that receives NFTs
        - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapERC20ForSpecificNFTsAndNFTsToToken(
        RobustPairNFTsFoTokenAndTokenforNFTsTrade calldata params
    ) external payable returns (uint256 remainingValue, uint256 outputAmount) {
        {
            remainingValue = params.inputAmount;
            uint256 pairCost;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps; ) {
                // Calculate actual cost per swap
                (pairCost, , ) = params
                    .tokenToNFTTrades[i]
                    .swapInfo
                    .pair
                    .getBuyNFTQuote(
                        params.tokenToNFTTrades[i].swapInfo.nftIds.length,
                        true
                    );

                // If within our maxCost and no  proceed
                if (pairCost <= params.tokenToNFTTrades[i].maxCost) {
                    remainingValue -= params
                        .tokenToNFTTrades[i]
                        .swapInfo
                        .pair
                        .swapTokenForSpecificNFTs(
                            params.tokenToNFTTrades[i].swapInfo.nftIds,
                            pairCost,
                            params.nftRecipient,
                            true,
                            msg.sender
                        );
                }

                unchecked {
                    ++i;
                }
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps; ) {
                uint256 pairOutput;

                // Locally scoped to avoid stack too deep error
                {
                    (pairOutput, , ) = params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .getSellNFTQuote(
                            params.nftToTokenTrades[i].swapInfo.nftIds.length
                        );
                }

                // If at least equal to our minOutput, proceed
                if (pairOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap and update outputAmount with how many tokens we got
                    outputAmount += params
                        .nftToTokenTrades[i]
                        .swapInfo
                        .pair
                        .swapNFTsForToken(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            0,
                            params.tokenRecipient,
                            true,
                            msg.sender
                        );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    receive() external payable {}

    /**
        Restricted functions
     */

    /**
        @dev Allows an ERC20 pair contract to transfer ERC20 tokens directly from
        the sender, in order to minimize the number of token transfers. Only callable by an ERC20 pair.
        @param token The ERC20 token to transfer
        @param from The address to transfer tokens from
        @param to The address to transfer tokens to
        @param amount The amount of tokens to transfer
        @param variant The pair variant of the pair contract
     */
    function pairTransferERC20From(
        ERC20 token,
        address from,
        address to,
        uint256 amount,
        IPotionPairFactoryLike.PairVariant variant
    ) external {
        // verify caller is a trusted pair contract
        require(factory.isPair(msg.sender, variant), "Not pair");

        // verify caller is an ERC20 pair
        require(
            variant == IPotionPairFactoryLike.PairVariant.ENUMERABLE_ERC20 ||
                variant ==
                IPotionPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ERC20,
            "Not ERC20 pair"
        );

        // transfer tokens to pair
        token.safeTransferFrom(from, to, amount);
    }

    /**
        @dev Allows a pair contract to transfer ERC721 NFTs directly from
        the sender, in order to minimize the number of token transfers. Only callable by a pair.
        @param nft The ERC721 NFT to transfer
        @param from The address to transfer tokens from
        @param to The address to transfer tokens to
        @param id The ID of the NFT to transfer
        @param variant The pair variant of the pair contract
     */
    function pairTransferNFTFrom(
        IERC721 nft,
        address from,
        address to,
        uint256 id,
        IPotionPairFactoryLike.PairVariant variant
    ) external {
        // verify caller is a trusted pair contract
        require(factory.isPair(msg.sender, variant), "Not pair");

        // transfer NFTs to pair
        nft.safeTransferFrom(from, to, id);
    }

    /**
        Internal functions
     */

    /**
        @param deadline The last valid time for a swap
     */
    function _checkDeadline(uint256 deadline) internal view {
        require(block.timestamp <= deadline, "Deadline passed");
    }

    /**
        @notice Internal function used to swap ETH for any NFTs
        @param swapList The list of pairs and swap calldata
        @param inputAmount The total amount of ETH to send
        @param ethRecipient The address receiving excess ETH
        @param nftRecipient The address receiving the NFTs from the pairs
        @return remainingValue The unspent token amount
     */
    function _swapETHForAnyNFTs(
        PairSwapAny[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 pairCost;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (pairCost, , ) = swapList[i].pair.getBuyNFTQuote( // todo handle fees correctly here 0xmckenna
                swapList[i].numItems,
                false
            );

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pair.swapTokenForAnyNFTs{
                value: pairCost
            }(
                swapList[i].numItems,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
        @notice Internal function used to swap ETH for a specific set of NFTs
        @param swapList The list of pairs and swap calldata
        @param inputAmount The total amount of ETH to send
        @param ethRecipient The address receiving excess ETH
        @param nftRecipient The address receiving the NFTs from the pairs
        @return remainingValue The unspent token amount
     */
    function _swapETHForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 pairCost;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (pairCost, , ) = swapList[i].pair.getBuyNFTQuote( // todo are fees making sense here? 0xmckenna
                swapList[i].nftIds.length,
                true
            );

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pair.swapTokenForSpecificNFTs{
                value: pairCost
            }(
                swapList[i].nftIds,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
        @notice Internal function used to swap an ERC20 token for any NFTs
        @dev Note that we don't need to query the pair's bonding curve first for pricing data because
        we just calculate and take the required amount from the caller during swap time. 
        However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
        to figure out how much the router should send to the pool.
        @param swapList The list of pairs and swap calldata
        @param inputAmount The total amount of ERC20 tokens to send
        @param nftRecipient The address receiving the NFTs from the pairs
        @return remainingValue The unspent token amount
     */
    function _swapERC20ForAnyNFTs(
        PairSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient
    ) internal returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Tokens are transferred in by the pair calling router.pairTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pair.swapTokenForAnyNFTs(
                swapList[i].numItems,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Internal function used to swap an ERC20 token for specific NFTs
        @dev Note that we don't need to query the pair's bonding curve first for pricing data because
        we just calculate and take the required amount from the caller during swap time. 
        However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
        to figure out how much the router should send to the pool.
        @param swapList The list of pairs and swap calldata
        @param inputAmount The total amount of ERC20 tokens to send
        @param nftRecipient The address receiving the NFTs from the pairs
        @return remainingValue The unspent token amount
     */
    function _swapERC20ForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient
    ) internal returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Tokens are transferred in by the pair calling router.pairTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pair.swapTokenForSpecificNFTs(
                swapList[i].nftIds,
                remainingValue,
                nftRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
        @notice Swaps NFTs for tokens, designed to be used for 1 token at a time
        @dev Calling with multiple tokens is permitted, BUT minOutput will be 
        far from enough of a safety check because different tokens almost certainly have different unit prices.
        @param swapList The list of pairs and swap calldata 
        @param minOutput The minimum number of tokens to be receieved frm the swaps 
        @param tokenRecipient The address that receives the tokens
        @return outputAmount The number of tokens to be received
     */
    function _swapNFTsForToken(
        PairSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address payable tokenRecipient
    ) internal returns (uint256 outputAmount) {
        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps; ) {
            // Do the swap for token and then update outputAmount
            // Note: minExpectedTokenOutput is set to 0 since we're doing an aggregate slippage check below
            outputAmount += swapList[i].pair.swapNFTsForToken(
                swapList[i].nftIds,
                0,
                tokenRecipient,
                true,
                msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Aggregate slippage check
        require(outputAmount >= minOutput, "outputAmount too low");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {PotionPair} from "./PotionPair.sol";
import {IPotionPairFactoryLike} from "./IPotionPairFactoryLike.sol";
import {ICurve} from "./bonding-curves/ICurve.sol";

/**
    @title An NFT/Token pair where the token is ETH
    @author Original work by boredGenius and 0xmons, modified by 10xdegen.
 */
abstract contract PotionPairETH is PotionPair {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 61;

    /// @inheritdoc PotionPair
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool, /*isRouter*/
        address, /*routerCaller*/
        IPotionPairFactoryLike _factory,
        uint256 protocolFee
    ) internal override {
        require(msg.value >= inputAmount, "Sent too little ETH for swap");

        // Take protocol fee
        if (protocolFee > 0) {
            // Round down to the actual ETH balance if there are numerical stability issues with the bonding curve calculations
            if (protocolFee > address(this).balance) {
                protocolFee = address(this).balance;
            }

            if (protocolFee > 0) {
                payable(address(_factory)).safeTransferETH(protocolFee);
            }
        }
    }

    /// @inheritdoc PotionPair
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Give excess ETH back to caller
        if (msg.value > inputAmount) {
            payable(msg.sender).safeTransferETH(msg.value - inputAmount);
        }
    }

    /// @inheritdoc PotionPair
    function _payProtocolFeeFromPair(
        IPotionPairFactoryLike _factory,
        uint256 protocolFee
    ) internal override {
        // Take protocol fee
        if (protocolFee > 0) {
            // Round down to the actual ETH balance if there are numerical stability issues with the bonding curve calculations
            if (protocolFee > address(this).balance) {
                protocolFee = address(this).balance;
            }

            if (protocolFee > 0) {
                payable(address(_factory)).safeTransferETH(protocolFee);
            }
        }
    }

    /// @inheritdoc PotionPair
    function _sendTokenOutput(
        address payable tokenRecipient,
        uint256 outputAmount
    ) internal override {
        // Send ETH to caller
        if (outputAmount > 0) {
            tokenRecipient.safeTransferETH(outputAmount);
        }
    }

    /// @inheritdoc PotionPair
    // @dev see PotionPairCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
        @dev All ETH transfers into the pair are accepted. This is the main method
        for the owner to top up the pair's token reserves.
     */
    receive() external payable {
        emit TokenDeposit(msg.sender, msg.value);
    }

    /**
        @dev All ETH transfers into the pair are accepted. This is the main method
        for the owner to top up the pair's token reserves.
     */
    fallback() external payable {
        // Only allow calls without function selector
        require(msg.data.length == _immutableParamsLength());
        emit TokenDeposit(msg.sender, msg.value);
    }

    // deposit / withdraw funcs

    /// @inheritdoc PotionPair
    function fungibleTokenBalance() public view override returns (uint256) {
        return address(this).balance - accruedFees;
    }

    /// @inheritdoc PotionPair
    function depositFungibleTokens(address from, uint256 amount)
        external
        payable
        override
    {
        require(msg.value >= amount, "Sent too little ETH for deposit");

        // refund excess to depositor
        _refundTokenToSender(amount);

        emit TokenDeposit(from, amount);
    }

    /// @inheritdoc PotionPair
    function _withdrawFungibleTokens(address receiver, uint256 amount)
        internal
        override
    {
        // Transfer ETH directly
        payable(receiver).safeTransferETH(amount);
    }

    // rescue funcs

    /**
        @notice Withdraws a specified amount of token owned by the pair to the owner address.
        @dev Only callable by the owner.
        @param amount The amount of token to send to the owner. If the pair's balance is less than
        this value, the transaction will be reverted.
     */
    function rescueETH(uint256 amount) public onlyOwner {
        payable(owner()).safeTransferETH(amount);

        // emit event since ETH is the pair token
        emit TokenWithdrawal(owner(), amount, 0);
    }

    /// @inheritdoc PotionPair
    function rescueERC20(
        address receiver,
        ERC20 a,
        uint256 amount
    ) external override onlyOwner {
        a.safeTransfer(receiver, amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**                                                                                 
          ..........                                                            
          ..........                                                            
          .....*****.....                                                       
          .....*****.....                                                       
          .....**********....................                                   
          .....**********....................                                   
               .....********************(((((..........                         
               .....********************(((((..........                         
          .....***************(((((((((((((((((((((((((.....                    
          .....***************(((((((((((((((((((((((((.....                    
               .....*****((((((((((((((((((((***************.....               
               .....*****((((((((((((((((((((***************.....               
          .....***************(((((((((((((((((((((((((((((((((((.....          
          .....***************(((((((((((((((((((((((((((((((((((.....          
     ......................................................................     
     ......................................................................     
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
               .....(((((((((((((((((((((((((((((((((((.....                    
               .....(((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
     .....**************************************************.....               
     .....**************************************************.....               
     ............................................................               
     ............................................................    
                                                                               
██████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
██████╔╝██║░░██║░░░██║░░░██║██║░░██║██╔██╗██║
██╔═══╝░██║░░██║░░░██║░░░██║██║░░██║██║╚████║
██║░░░░░╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
╚═╝░░░░░░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝

██████╗░██████╗░░█████╗░████████╗░█████╗░░█████╗░░█████╗░██╗░░░░░
██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░
██████╔╝██████╔╝██║░░██║░░░██║░░░██║░░██║██║░░╚═╝██║░░██║██║░░░░░
██╔═══╝░██╔══██╗██║░░██║░░░██║░░░██║░░██║██║░░██╗██║░░██║██║░░░░░
██║░░░░░██║░░██║╚█████╔╝░░░██║░░░╚█████╔╝╚█████╔╝╚█████╔╝███████╗
╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░░╚════╝░░╚════╝░░╚════╝░╚══════╝

@author: @10xdegen
*/

struct RegisteredPairParams {
    address nft;
    address creator;
    address pair;
    address pool;
}

// @dev Interface for the PotionPairRegistry
interface IPotionPairRegistry {
    // @dev Called when a new pair is registered.
    //
    function registerPair(RegisteredPairParams calldata params)
        external
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**                                                                                 
          ..........                                                            
          ..........                                                            
          .....*****.....                                                       
          .....*****.....                                                       
          .....**********....................                                   
          .....**********....................                                   
               .....********************(((((..........                         
               .....********************(((((..........                         
          .....***************(((((((((((((((((((((((((.....                    
          .....***************(((((((((((((((((((((((((.....                    
               .....*****((((((((((((((((((((***************.....               
               .....*****((((((((((((((((((((***************.....               
          .....***************(((((((((((((((((((((((((((((((((((.....          
          .....***************(((((((((((((((((((((((((((((((((((.....          
     ......................................................................     
     ......................................................................     
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
               .....(((((((((((((((((((((((((((((((((((.....                    
               .....(((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
     .....**************************************************.....               
     .....**************************************************.....               
     ............................................................               
     ............................................................    
                                                                               
██████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
██████╔╝██║░░██║░░░██║░░░██║██║░░██║██╔██╗██║
██╔═══╝░██║░░██║░░░██║░░░██║██║░░██║██║╚████║
██║░░░░░╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
╚═╝░░░░░░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝

██████╗░██████╗░░█████╗░████████╗░█████╗░░█████╗░░█████╗░██╗░░░░░
██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░
██████╔╝██████╔╝██║░░██║░░░██║░░░██║░░██║██║░░╚═╝██║░░██║██║░░░░░
██╔═══╝░██╔══██╗██║░░██║░░░██║░░░██║░░██║██║░░██╗██║░░██║██║░░░░░
██║░░░░░██║░░██║╚█████╔╝░░░██║░░░╚█████╔╝╚█████╔╝╚█████╔╝███████╗
╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░░╚════╝░░╚════╝░░╚════╝░╚══════╝

@author: @10xdegen
*/

import {CurveErrorCodes} from "./CurveErrorCodes.sol";

interface ICurve {
    /**
        @notice Given the current state of the pair and the trade, computes how much the user
        should pay to purchase NFTs from the pair.
        @param numItems The number of items to be purchased
        @param totalNFT Supply The total supply of the pair's NFT token
        @param totalTokenSupply The total liquidity of the pair's Fungible token
        @param reserveRatio An optional reserve ratio that some curves may use as a parameter.
        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return inputValue The amount that the user should pay, in tokens
     */
    function getBuyInfo(
        uint256 numItems,
        uint256 totalNFT,
        uint256 totalTokenSupply,
        uint32 reserveRatio
    ) external view returns (CurveErrorCodes.Error error, uint256 inputValue);

    /**
        @notice Given the current state of the pair and the trade, computes how much the user
        should earn to sell an NFT into the pair.
        @param numItems The number of items to be purchased
        @param totalNFT Supply The total supply of the pair's NFT token
        @param totalTokenSupply The total liquidity of the pair's Fungible token
        @param reserveRatio An optional reserve ratio that some curves may use as a parameter.
        @return error Any math calculation errors, only Error.OK means the returned values are valid
        @return outputValue The amount that the user should get paid, in tokens
     */
    function getSellInfo(
        uint256 numItems,
        uint256 totalNFT,
        uint256 totalTokenSupply,
        uint32 reserveRatio
    ) external view returns (CurveErrorCodes.Error error, uint256 outputValue);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {PotionPair} from "./PotionPair.sol";
import {IPotionPairFactoryLike} from "./IPotionPairFactoryLike.sol";
import {PotionRouter} from "./PotionRouter.sol";

/**
    @title An NFT/Token pair where the token is an ERC20
    @author Original work by boredGenius and 0xmons, modified by 10xdegen.
 */
abstract contract PotionPairERC20 is PotionPair {
    using SafeTransferLib for ERC20;

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 81;

    /**
        @notice Returns the ERC20 token associated with the pair
        @dev See PotionPairCloner for an explanation on how this works
     */
    function token() public pure returns (ERC20 _token) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _token := shr(
                0x60,
                calldataload(add(sub(calldatasize(), paramsLength), 61))
            )
        }
    }

    /// @inheritdoc PotionPair
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        IPotionPairFactoryLike _factory,
        uint256 protocolFee
    ) internal override {
        require(msg.value == 0, "ERC20 pair");

        ERC20 _token = token();

        if (isRouter) {
            // Verify if router is allowed
            PotionRouter router = PotionRouter(payable(msg.sender));

            // Locally scoped to avoid stack too deep
            {
                (bool routerAllowed, ) = _factory.routerStatus(router);
                require(routerAllowed, "Not router");
            }

            // Cache state and then call router to transfer tokens from user
            uint256 beforeBalance = _token.balanceOf(address(this));
            router.pairTransferERC20From(
                _token,
                routerCaller,
                address(this),
                inputAmount - protocolFee,
                pairVariant()
            );

            // Verify token transfer (protect pair against malicious router)
            require(
                _token.balanceOf(address(this)) - beforeBalance ==
                    inputAmount - protocolFee,
                "ERC20 not transferred in"
            );

            router.pairTransferERC20From(
                _token,
                routerCaller,
                address(_factory),
                protocolFee,
                pairVariant()
            );

            // Note: no check for factory balance's because router is assumed to be set by factory owner
            // so there is no incentive to *not* pay protocol fee
        } else {
            // Transfer tokens directly
            _token.safeTransferFrom(
                msg.sender,
                address(this),
                inputAmount - protocolFee
            );

            // Take protocol fee (if it exists)
            if (protocolFee > 0) {
                _token.safeTransferFrom(
                    msg.sender,
                    address(_factory),
                    protocolFee
                );
            }
        }
    }

    /// @inheritdoc PotionPair
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Do nothing since we transferred the exact input amount
    }

    /// @inheritdoc PotionPair
    function _payProtocolFeeFromPair(
        IPotionPairFactoryLike _factory,
        uint256 protocolFee
    ) internal override {
        // Take protocol fee (if it exists)
        if (protocolFee > 0) {
            ERC20 _token = token();

            // Round down to the actual token balance if there are numerical stability issues with the bonding curve calculations
            uint256 pairTokenBalance = _token.balanceOf(address(this));
            if (protocolFee > pairTokenBalance) {
                protocolFee = pairTokenBalance;
            }
            if (protocolFee > 0) {
                _token.safeTransfer(address(_factory), protocolFee);
            }
        }
    }

    /// @inheritdoc PotionPair
    function _sendTokenOutput(
        address payable tokenRecipient,
        uint256 outputAmount
    ) internal override {
        // Send tokens to caller
        if (outputAmount > 0) {
            token().safeTransfer(tokenRecipient, outputAmount);
        }
    }

    /// @inheritdoc PotionPair
    // @dev see PotionPairCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    // deposit / withdraw funcs

    /// @inheritdoc PotionPair
    function fungibleTokenBalance() public view override returns (uint256) {
        return token().balanceOf(address(this)) - accruedFees;
    }

    /// @inheritdoc PotionPair
    function depositFungibleTokens(address from, uint256 amount)
        external
        payable
        override
    {
        token().safeTransferFrom(from, address(this), amount);
        emit TokenDeposit(from, amount);
    }

    /// @inheritdoc PotionPair
    function _withdrawFungibleTokens(address receiver, uint256 amount)
        internal
        override
    {
        // Transfer tokens directly
        token().safeTransfer(receiver, amount);
    }

    // rescue funcs

    /// @inheritdoc PotionPair
    function rescueERC20(
        address receiver,
        ERC20 a,
        uint256 amount
    ) external override onlyOwner {
        a.safeTransfer(receiver, amount);

        if (a == token()) {
            // emit event since it is the pair token
            emit TokenWithdrawal(receiver, amount, 0);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ERC20} from "solmate/tokens/ERC20.sol";

import {ICurve} from "../bonding-curves/ICurve.sol";
import {IPotionPairFactoryLike} from "../IPotionPairFactoryLike.sol";

library PotionPairCloner {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     *
     * During the delegate call, extra data is copied into the calldata which can then be
     * accessed by the implementation contract.
     */
    function cloneETHPair(
        address implementation,
        IPotionPairFactoryLike factory,
        ICurve bondingCurve,
        IERC721 nft
    ) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (9 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // creation size = 09
            // runtime size = 72
            // 60 runtime  | PUSH1 runtime (r)     | r                       | –
            // 3d          | RETURNDATASIZE        | 0 r                     | –
            // 81          | DUP2                  | r 0 r                   | –
            // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
            // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
            // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
            // f3          | RETURN                |                         | [0-runSize): runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (53 bytes of code + 61 bytes of extra data = 114 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // extra data size = 3d
            // 3d          | RETURNDATASIZE        | 0                       | –
            // 3d          | RETURNDATASIZE        | 0 0                     | –
            // 3d          | RETURNDATASIZE        | 0 0 0                   | –
            // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
            // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
            // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
            // 60 extra    | PUSH1 extra           | extra 0 0 0 0           | [0, cds) = calldata
            // 60 0x35     | PUSH1 0x35            | 0x35 extra 0 0 0 0      | [0, cds) = calldata // 0x35 (53) is runtime size - data
            // 36          | CALLDATASIZE          | cds 0x35 extra 0 0 0 0  | [0, cds) = calldata
            // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 60 extra    | PUSH1 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x35) = extraData
            mstore(
                ptr,
                hex"60_72_3d_81_60_09_3d_39_f3_3d_3d_3d_3d_36_3d_3d_37_60_3d_60_35_36_39_36_60_3d_01_3d_73_00_00_00"
            )
            mstore(add(ptr, 0x1d), shl(0x60, implementation))

            // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
            // 60 0x33     | PUSH1 0x33            | 0x33 sucess 0 rds       | [0, rds) = return data
            // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
            // fd          | REVERT                | –                       | [0, rds) = return data
            // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
            // f3          | RETURN                | –                       | [0, rds) = return data
            mstore(
                add(ptr, 0x31),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )

            // -------------------------------------------------------------------------------------------------------------
            // EXTRA DATA (61 bytes)
            // -------------------------------------------------------------------------------------------------------------

            mstore(add(ptr, 0x3e), shl(0x60, factory))
            mstore(add(ptr, 0x52), shl(0x60, bondingCurve))
            mstore(add(ptr, 0x66), shl(0x60, nft))
            mstore8(add(ptr, 0x7a), 0)

            instance := create(0, ptr, 0x7b)
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     *
     * During the delegate call, extra data is copied into the calldata which can then be
     * accessed by the implementation contract.
     */
    function cloneERC20Pair(
        address implementation,
        IPotionPairFactoryLike factory,
        ICurve bondingCurve,
        IERC721 nft,
        ERC20 token
    ) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (9 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // creation size = 09
            // runtime size = 86
            // 60 runtime  | PUSH1 runtime (r)     | r                       | –
            // 3d          | RETURNDATASIZE        | 0 r                     | –
            // 81          | DUP2                  | r 0 r                   | –
            // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
            // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
            // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
            // f3          | RETURN                |                         | [0-runSize): runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (53 bytes of code + 81 bytes of extra data = 134 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // extra data size = 51
            // 3d          | RETURNDATASIZE        | 0                       | –
            // 3d          | RETURNDATASIZE        | 0 0                     | –
            // 3d          | RETURNDATASIZE        | 0 0 0                   | –
            // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
            // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
            // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
            // 60 extra    | PUSH1 extra           | extra 0 0 0 0           | [0, cds) = calldata
            // 60 0x35     | PUSH1 0x35            | 0x35 extra 0 0 0 0      | [0, cds) = calldata // 0x35 (53) is runtime size - data
            // 36          | CALLDATASIZE          | cds 0x35 extra 0 0 0 0  | [0, cds) = calldata
            // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 60 extra    | PUSH1 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x35) = extraData
            mstore(
                ptr,
                hex"60_86_3d_81_60_09_3d_39_f3_3d_3d_3d_3d_36_3d_3d_37_60_51_60_35_36_39_36_60_51_01_3d_73_00_00_00"
            )
            mstore(add(ptr, 0x1d), shl(0x60, implementation))

            // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
            // 60 0x33     | PUSH1 0x33            | 0x33 sucess 0 rds       | [0, rds) = return data
            // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
            // fd          | REVERT                | –                       | [0, rds) = return data
            // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
            // f3          | RETURN                | –                       | [0, rds) = return data
            mstore(
                add(ptr, 0x31),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )

            // -------------------------------------------------------------------------------------------------------------
            // EXTRA DATA (81 bytes)
            // -------------------------------------------------------------------------------------------------------------

            mstore(add(ptr, 0x3e), shl(0x60, factory))
            mstore(add(ptr, 0x52), shl(0x60, bondingCurve))
            mstore(add(ptr, 0x66), shl(0x60, nft))
            mstore8(add(ptr, 0x7a), 0)
            mstore(add(ptr, 0x7b), shl(0x60, token))

            instance := create(0, ptr, 0x8f)
        }
    }

    /**
     * @notice Checks if a contract is a clone of a PotionPairETH.
     * @dev Only checks the runtime bytecode, does not check the extra data.
     * @param factory the factory that deployed the clone
     * @param implementation the PotionPairETH implementation contract
     * @param query the contract to check
     * @return result True if the contract is a clone, false otherwise
     */
    function isETHPairClone(
        address factory,
        address implementation,
        address query
    ) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                hex"3d_3d_3d_3d_36_3d_3d_37_60_3d_60_35_36_39_36_60_3d_01_3d_73_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x35), shl(0x60, factory))

            // compare expected bytecode with that of the queried contract
            let other := add(ptr, 0x49)
            extcodecopy(query, other, 0, 0x49)
            result := and(
                eq(mload(ptr), mload(other)),
                and(
                    eq(mload(add(ptr, 0x20)), mload(add(other, 0x20))),
                    eq(mload(add(ptr, 0x29)), mload(add(other, 0x29)))
                )
            )
        }
    }

    /**
     * @notice Checks if a contract is a clone of a PotionPairERC20.
     * @dev Only checks the runtime bytecode, does not check the extra data.
     * @param implementation the PotionPairERC20 implementation contract
     * @param query the contract to check
     * @return result True if the contract is a clone, false otherwise
     */
    function isERC20PairClone(
        address factory,
        address implementation,
        address query
    ) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                hex"3d_3d_3d_3d_36_3d_3d_37_60_51_60_35_36_39_36_60_51_01_3d_73_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x35), shl(0x60, factory))

            // compare expected bytecode with that of the queried contract
            let other := add(ptr, 0x49)
            extcodecopy(query, other, 0, 0x49)
            result := and(
                eq(mload(ptr), mload(other)),
                and(
                    eq(mload(add(ptr, 0x20)), mload(add(other, 0x20))),
                    eq(mload(add(ptr, 0x29)), mload(add(other, 0x29)))
                )
            )
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**                                                                                 
          ..........                                                            
          ..........                                                            
          .....*****.....                                                       
          .....*****.....                                                       
          .....**********....................                                   
          .....**********....................                                   
               .....********************(((((..........                         
               .....********************(((((..........                         
          .....***************(((((((((((((((((((((((((.....                    
          .....***************(((((((((((((((((((((((((.....                    
               .....*****((((((((((((((((((((***************.....               
               .....*****((((((((((((((((((((***************.....               
          .....***************(((((((((((((((((((((((((((((((((((.....          
          .....***************(((((((((((((((((((((((((((((((((((.....          
     ......................................................................     
     ......................................................................     
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
               .....(((((((((((((((((((((((((((((((((((.....                    
               .....(((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
     .....**************************************************.....               
     .....**************************************************.....               
     ............................................................               
     ............................................................    

██████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
██████╔╝██║░░██║░░░██║░░░██║██║░░██║██╔██╗██║
██╔═══╝░██║░░██║░░░██║░░░██║██║░░██║██║╚████║
██║░░░░░╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
╚═╝░░░░░░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝

██████╗░██████╗░░█████╗░████████╗░█████╗░░█████╗░░█████╗░██╗░░░░░
██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░
██████╔╝██████╔╝██║░░██║░░░██║░░░██║░░██║██║░░╚═╝██║░░██║██║░░░░░
██╔═══╝░██╔══██╗██║░░██║░░░██║░░░██║░░██║██║░░██╗██║░░██║██║░░░░░
██║░░░░░██║░░██║╚█████╔╝░░░██║░░░╚█████╔╝╚█████╔╝╚█████╔╝███████╗
╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░░╚════╝░░╚════╝░░╚════╝░╚══════╝

@author: @10xdegen
*/

import {PotionRouter} from "./PotionRouter.sol";

interface IPotionPairFactoryLike {
    enum PairVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    function protocolFeeMultiplier() external view returns (uint256);

    function protocolFeeRecipient() external view returns (address payable);

    function callAllowed(address target) external view returns (bool);

    function routerStatus(PotionRouter router)
        external
        view
        returns (bool allowed, bool wasEverAllowed);

    function isPair(address potentialPair, PairVariant variant)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {PotionPairETH} from "./PotionPairETH.sol";
import {PotionPairEnumerable} from "./PotionPairEnumerable.sol";
import {IPotionPairFactoryLike} from "./IPotionPairFactoryLike.sol";

/**
    @title An NFT/Token pair where the NFT implements ERC721Enumerable, and the token is ETH
    @author Original work by boredGenius and 0xmons, modified by 10xdegen.
 */
contract PotionPairEnumerableETH is PotionPairEnumerable, PotionPairETH {
    /**
        @notice Returns the PotionPair type
     */
    function pairVariant()
        public
        pure
        override
        returns (IPotionPairFactoryLike.PairVariant)
    {
        return IPotionPairFactoryLike.PairVariant.ENUMERABLE_ETH;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**                                                                                 
          ..........                                                            
          ..........                                                            
          .....*****.....                                                       
          .....*****.....                                                       
          .....**********....................                                   
          .....**********....................                                   
               .....********************(((((..........                         
               .....********************(((((..........                         
          .....***************(((((((((((((((((((((((((.....                    
          .....***************(((((((((((((((((((((((((.....                    
               .....*****((((((((((((((((((((***************.....               
               .....*****((((((((((((((((((((***************.....               
          .....***************(((((((((((((((((((((((((((((((((((.....          
          .....***************(((((((((((((((((((((((((((((((((((.....          
     ......................................................................     
     ......................................................................     
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
               .....(((((((((((((((((((((((((((((((((((.....                    
               .....(((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
     .....**************************************************.....               
     .....**************************************************.....               
     ............................................................               
     ............................................................    
                                                                               
██████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
██████╔╝██║░░██║░░░██║░░░██║██║░░██║██╔██╗██║
██╔═══╝░██║░░██║░░░██║░░░██║██║░░██║██║╚████║
██║░░░░░╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
╚═╝░░░░░░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝

██████╗░██████╗░░█████╗░████████╗░█████╗░░█████╗░░█████╗░██╗░░░░░
██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░
██████╔╝██████╔╝██║░░██║░░░██║░░░██║░░██║██║░░╚═╝██║░░██║██║░░░░░
██╔═══╝░██╔══██╗██║░░██║░░░██║░░░██║░░██║██║░░██╗██║░░██║██║░░░░░
██║░░░░░██║░░██║╚█████╔╝░░░██║░░░╚█████╔╝╚█████╔╝╚█████╔╝███████╗
╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░░╚════╝░░╚════╝░░╚════╝░╚══════╝

@author: @10xdegen
*/

import {PotionPairERC20} from "./PotionPairERC20.sol";
import {PotionPairEnumerable} from "./PotionPairEnumerable.sol";
import {IPotionPairFactoryLike} from "./IPotionPairFactoryLike.sol";

/**
    @title An NFT/Token pair where the NFT implements ERC721Enumerable, and the token is an ERC20
    @author Original work by boredGenius and 0xmons, modified by 10xdegen.
 */
contract PotionPairEnumerableERC20 is PotionPairEnumerable, PotionPairERC20 {
    /**
        @notice Returns the PotionPair type
     */
    function pairVariant()
        public
        pure
        override
        returns (IPotionPairFactoryLike.PairVariant)
    {
        return IPotionPairFactoryLike.PairVariant.ENUMERABLE_ERC20;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {PotionPairETH} from "./PotionPairETH.sol";
import {PotionPairMissingEnumerable} from "./PotionPairMissingEnumerable.sol";
import {IPotionPairFactoryLike} from "./IPotionPairFactoryLike.sol";

contract PotionPairMissingEnumerableETH is
    PotionPairMissingEnumerable,
    PotionPairETH
{
    function pairVariant()
        public
        pure
        override
        returns (IPotionPairFactoryLike.PairVariant)
    {
        return IPotionPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ETH;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {PotionPairERC20} from "./PotionPairERC20.sol";
import {PotionPairMissingEnumerable} from "./PotionPairMissingEnumerable.sol";
import {IPotionPairFactoryLike} from "./IPotionPairFactoryLike.sol";

contract PotionPairMissingEnumerableERC20 is
    PotionPairMissingEnumerable,
    PotionPairERC20
{
    function pairVariant()
        public
        pure
        override
        returns (IPotionPairFactoryLike.PairVariant)
    {
        return IPotionPairFactoryLike.PairVariant.MISSING_ENUMERABLE_ERC20;
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(
                and(
                    iszero(iszero(denominator)),
                    or(iszero(x), eq(div(z, x), y))
                )
            ) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }

    // added by 10xdegen
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IOwnershipTransferCallback} from "./IOwnershipTransferCallback.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

abstract contract OwnableWithTransferCallback {
    using ERC165Checker for address;
    using Address for address;

    bytes4 constant TRANSFER_CALLBACK =
        type(IOwnershipTransferCallback).interfaceId;

    error Ownable_NotOwner();
    error Ownable_NewOwnerZeroAddress();

    address private _owner;

    event OwnershipTransferred(address indexed newOwner);

    /// @dev Initializes the contract setting the deployer as the initial owner.
    function __Ownable_init(address initialOwner) internal {
        _owner = initialOwner;
    }

    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (owner() != msg.sender) revert Ownable_NotOwner();
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Disallows setting to the zero address as a way to more gas-efficiently avoid reinitialization
    /// When ownership is transferred, if the new owner implements IOwnershipTransferCallback, we make a callback
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) revert Ownable_NewOwnerZeroAddress();
        _transferOwnership(newOwner);

        // Call the on ownership transfer callback if it exists
        // @dev try/catch is around 5k gas cheaper than doing ERC165 checking
        if (newOwner.isContract()) {
            try
                IOwnershipTransferCallback(newOwner).onOwnershipTransfer(msg.sender)
            {} catch (bytes memory) {}
        }
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Internal function without access restriction.
    function _transferOwnership(address newOwner) internal virtual {
        _owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }
}

// SPDX-License-Identifier: MIT
// Forked from OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol), 
// removed initializer check as we already do that in our modified Ownable

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

    function __ReentrancyGuard_init() internal {
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

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**                                                                                 
          ..........                                                            
          ..........                                                            
          .....*****.....                                                       
          .....*****.....                                                       
          .....**********....................                                   
          .....**********....................                                   
               .....********************(((((..........                         
               .....********************(((((..........                         
          .....***************(((((((((((((((((((((((((.....                    
          .....***************(((((((((((((((((((((((((.....                    
               .....*****((((((((((((((((((((***************.....               
               .....*****((((((((((((((((((((***************.....               
          .....***************(((((((((((((((((((((((((((((((((((.....          
          .....***************(((((((((((((((((((((((((((((((((((.....          
     ......................................................................     
     ......................................................................     
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
               .....(((((((((((((((((((((((((((((((((((.....                    
               .....(((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
     .....**************************************************.....               
     .....**************************************************.....               
     ............................................................               
     ............................................................    
                                                                               
██████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
██████╔╝██║░░██║░░░██║░░░██║██║░░██║██╔██╗██║
██╔═══╝░██║░░██║░░░██║░░░██║██║░░██║██║╚████║
██║░░░░░╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
╚═╝░░░░░░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝

██████╗░██████╗░░█████╗░████████╗░█████╗░░█████╗░░█████╗░██╗░░░░░
██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░
██████╔╝██████╔╝██║░░██║░░░██║░░░██║░░██║██║░░╚═╝██║░░██║██║░░░░░
██╔═══╝░██╔══██╗██║░░██║░░░██║░░░██║░░██║██║░░██╗██║░░██║██║░░░░░
██║░░░░░██║░░██║╚█████╔╝░░░██║░░░╚█████╔╝╚█████╔╝╚█████╔╝███████╗
╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░░╚════╝░░╚════╝░░╚════╝░╚══════╝

@author: @10xdegen
*/

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

// SimpleAccessControl implements IAccessControl
// for a contract without needing to implement ERC165.
abstract contract SimpleAccessControl is IAccessControl, Context {
    /**
        STORAGE
     */

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
        MODIFIER
     */

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role)
        public
        view
        virtual
        override
        returns (bytes32)
    {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account)
        public
        virtual
        override
        onlyRole(getRoleAdmin(role))
    {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account)
        public
        virtual
        override
    {
        require(
            account == _msgSender(),
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract CurveErrorCodes {
    enum Error {
        OK, // No error
        INVALID_RESERVE_RATIO, // The reserve ratio provided to the curve is invalid.
        INVALID_NUM_ITEMS, // The number of items to be purchased or sold is invalid.
        INVALID_TOTAL_NFT, // The total supply of the pair's NFT token is invalid.
        INVALID_TOTAL_TOKEN_SUPPLY // The total liquidity of the pair's Fungible token is invalid.
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Modified from Dappsys V2 (https://github.com/dapp-org/dappsys-v2/blob/main/src/math.sol)
/// and ABDK (https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol)
library FixedPointMathLib {
    /*///////////////////////////////////////////////////////////////
                            COMMON BASE UNITS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant YAD = 1e8;
    uint256 internal constant WAD = 1e18;
    uint256 internal constant RAY = 1e27;
    uint256 internal constant RAD = 1e45;

    /*///////////////////////////////////////////////////////////////
                         FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function fmul(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(x == 0 || (x * y) / x == y)
            if iszero(or(iszero(x), eq(div(z, x), y))) {
                revert(0, 0)
            }

            // If baseUnit is zero this will return zero instead of reverting.
            z := div(z, baseUnit)
        }
    }

    function fdiv(
        uint256 x,
        uint256 y,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * baseUnit in z for now.
            z := mul(x, baseUnit)

            if or(
                // Revert if y is zero to ensure we don't divide by zero below.
                iszero(y),
                // Equivalent to require(x == 0 || (x * baseUnit) / x == baseUnit)
                iszero(or(iszero(x), eq(div(z, x), baseUnit)))
            ) {
                revert(0, 0)
            }

            // We ensure y is not zero above, so there is never division by zero here.
            z := div(z, y)
        }
    }

    function fpow(
        uint256 x,
        uint256 n,
        uint256 baseUnit
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := baseUnit
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := baseUnit
                }
                default {
                    z := x
                }
                let half := div(baseUnit, 2)
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, baseUnit)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, baseUnit)
                    }
                }
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 result) {
        if (x == 0) return 0;

        result = 1;

        uint256 xAux = x;

        if (xAux >= 0x100000000000000000000000000000000) {
            xAux >>= 128;
            result <<= 64;
        }

        if (xAux >= 0x10000000000000000) {
            xAux >>= 64;
            result <<= 32;
        }

        if (xAux >= 0x100000000) {
            xAux >>= 32;
            result <<= 16;
        }

        if (xAux >= 0x10000) {
            xAux >>= 16;
            result <<= 8;
        }

        if (xAux >= 0x100) {
            xAux >>= 8;
            result <<= 4;
        }

        if (xAux >= 0x10) {
            xAux >>= 4;
            result <<= 2;
        }

        if (xAux >= 0x8) result <<= 1;

        unchecked {
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;
            result = (result + x / result) >> 1;

            uint256 roundedDownResult = x / result;

            if (result > roundedDownResult) result = roundedDownResult;
        }
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x < y ? x : y;
    }

    function max(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x > y ? x : y;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**                                                                                 
          ..........                                                            
          ..........                                                            
          .....*****.....                                                       
          .....*****.....                                                       
          .....**********....................                                   
          .....**********....................                                   
               .....********************(((((..........                         
               .....********************(((((..........                         
          .....***************(((((((((((((((((((((((((.....                    
          .....***************(((((((((((((((((((((((((.....                    
               .....*****((((((((((((((((((((***************.....               
               .....*****((((((((((((((((((((***************.....               
          .....***************(((((((((((((((((((((((((((((((((((.....          
          .....***************(((((((((((((((((((((((((((((((((((.....          
     ......................................................................     
     ......................................................................     
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
     .....%%%%%%%%%%%%%%%*****@@@@@@@@@@(((((((((((((((@@@@@@@@@@.....          
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
          [email protected]@@@@@@@@@*****..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
     [email protected]@@@@@@@@@**********..........(((((((((((((((..........               
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@***************((((((((((((((((((((..........          
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
          [email protected]@@@@@@@@@@@@@@*****(((((((((((((((((((((((((.....               
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
     [email protected]@@@@@@@@@@@@@@@@@@@@@@@@**********(((((**********@@@@@.....          
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
[email protected]@@@@@@@@@@@@@@@@@@@(((((@@@@@(((((((((((((((((((((((((@@@@@@@@@@.....     
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
          [email protected]@@@@.....(((((((((((((((((((((((((((((((((((.....               
               .....(((((((((((((((((((((((((((((((((((.....                    
               .....(((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
          .....((((((((((((((((((((((((((((((((((((((((.....                    
     .....**************************************************.....               
     .....**************************************************.....               
     ............................................................               
     ............................................................    
                                                                               
██████╗░░█████╗░████████╗██╗░█████╗░███╗░░██╗
██╔══██╗██╔══██╗╚══██╔══╝██║██╔══██╗████╗░██║
██████╔╝██║░░██║░░░██║░░░██║██║░░██║██╔██╗██║
██╔═══╝░██║░░██║░░░██║░░░██║██║░░██║██║╚████║
██║░░░░░╚█████╔╝░░░██║░░░██║╚█████╔╝██║░╚███║
╚═╝░░░░░░╚════╝░░░░╚═╝░░░╚═╝░╚════╝░╚═╝░░╚══╝

██████╗░██████╗░░█████╗░████████╗░█████╗░░█████╗░░█████╗░██╗░░░░░
██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░
██████╔╝██████╔╝██║░░██║░░░██║░░░██║░░██║██║░░╚═╝██║░░██║██║░░░░░
██╔═══╝░██╔══██╗██║░░██║░░░██║░░░██║░░██║██║░░██╗██║░░██║██║░░░░░
██║░░░░░██║░░██║╚█████╔╝░░░██║░░░╚█████╔╝╚█████╔╝╚█████╔╝███████╗
╚═╝░░░░░╚═╝░░╚═╝░╚════╝░░░░╚═╝░░░░╚════╝░░╚════╝░░╚════╝░╚══════╝

@author: @10xdegen
*/

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {PotionRouter} from "./PotionRouter.sol";
import {PotionPair} from "./PotionPair.sol";
import {IPotionPairFactoryLike} from "./IPotionPairFactoryLike.sol";

/**
    @title An NFT/Token pair for an NFT that implements ERC721Enumerable
    @author Original work by boredGenius and 0xmons, modified by 10xdegen.
 */
abstract contract PotionPairEnumerable is PotionPair {
    /// @inheritdoc PotionPair
    function _sendAnyNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256 numNFTs
    ) internal override {
        // Send NFTs to recipient
        // (we know NFT implements IERC721Enumerable so we just iterate)
        uint256 lastIndex = _nft.balanceOf(address(this)) - 1;
        for (uint256 i = 0; i < numNFTs; ) {
            uint256 nftId = IERC721Enumerable(address(_nft))
                .tokenOfOwnerByIndex(address(this), lastIndex);
            _nft.safeTransferFrom(address(this), nftRecipient, nftId);

            unchecked {
                --lastIndex;
                ++i;
            }
        }
    }

    /// @inheritdoc PotionPair
    function _sendSpecificNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256[] calldata nftIds
    ) internal override {
        // Send NFTs to recipient
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(address(this), nftRecipient, nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc PotionPair
    function getAllHeldIds(uint256 maxQuantity)
        external
        view
        override
        returns (uint256[] memory nftIds)
    {
        IERC721 _nft = nft();
        uint256 numNFTs = _nft.balanceOf(address(this));
        if (maxQuantity > 0 && numNFTs > maxQuantity) {
            numNFTs = maxQuantity;
        }
        uint256[] memory ids = new uint256[](numNFTs);
        for (uint256 i; i < numNFTs; ) {
            ids[i] = IERC721Enumerable(address(_nft)).tokenOfOwnerByIndex(
                address(this),
                i
            );

            unchecked {
                ++i;
            }
        }
        return ids;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @inheritdoc PotionPair
    function withdrawNfts(address receiver, uint256[] calldata nftIds)
        external
        override
        onlyWithdrawer
    {
        uint256 numNFTs = nftIds.length;
        IERC721 _nft = nft();
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(address(this), receiver, nftIds[i]);

            unchecked {
                ++i;
            }
        }

        emit NFTWithdrawal(receiver, nftIds);
    }

    /// @inheritdoc PotionPair
    function rescueERC721(
        address receiver,
        IERC721 a,
        uint256[] calldata nftIds
    ) external override onlyOwner {
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs; ) {
            a.safeTransferFrom(address(this), receiver, nftIds[i]);

            unchecked {
                ++i;
            }
        }

        emit NFTWithdrawal(receiver, nftIds);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {PotionPair} from "./PotionPair.sol";
import {PotionRouter} from "./PotionRouter.sol";
import {IPotionPairFactoryLike} from "./IPotionPairFactoryLike.sol";

/**
    @title An NFT/Token pair for an NFT that does not implement ERC721Enumerable
    @author Original work by boredGenius and 0xmons, modified by 10xdegen.
 */
abstract contract PotionPairMissingEnumerable is PotionPair {
    using EnumerableSet for EnumerableSet.UintSet;

    // Used for internal ID tracking
    EnumerableSet.UintSet private idSet;

    /// @inheritdoc PotionPair
    function _sendAnyNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256 numNFTs
    ) internal override {
        // Send NFTs to recipient
        // We're missing enumerable, so we also update the pair's own ID set
        // NOTE: We start from last index to first index to save on gas
        uint256 lastIndex = idSet.length() - 1;
        for (uint256 i; i < numNFTs; ) {
            uint256 nftId = idSet.at(lastIndex);
            _nft.safeTransferFrom(address(this), nftRecipient, nftId);
            idSet.remove(nftId);

            unchecked {
                --lastIndex;
                ++i;
            }
        }
    }

    /// @inheritdoc PotionPair
    function _sendSpecificNFTsToRecipient(
        IERC721 _nft,
        address nftRecipient,
        uint256[] calldata nftIds
    ) internal override {
        // Send NFTs to caller
        // If missing enumerable, update pool's own ID set
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs; ) {
            _nft.safeTransferFrom(address(this), nftRecipient, nftIds[i]);
            // Remove from id set
            idSet.remove(nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc PotionPair
    function getAllHeldIds(uint256 maxQuantity)
        external
        view
        override
        returns (uint256[] memory)
    {
        uint256 numNFTs = idSet.length();
        if (maxQuantity > 0 && numNFTs > maxQuantity) {
            numNFTs = maxQuantity;
        }
        uint256[] memory ids = new uint256[](numNFTs);
        for (uint256 i; i < numNFTs; ) {
            ids[i] = idSet.at(i);

            unchecked {
                ++i;
            }
        }
        return ids;
    }

    /**
        @dev When safeTransfering an ERC721 in, we add ID to the idSet
        if it's the same collection used by pool. (As it doesn't auto-track because no ERC721Enumerable)
     */
    function onERC721Received(
        address,
        address,
        uint256 id,
        bytes memory
    ) public virtual returns (bytes4) {
        IERC721 _nft = nft();
        // If it's from the pair's NFT, add the ID to ID set
        if (msg.sender == address(_nft)) {
            idSet.add(id);
        }
        return this.onERC721Received.selector;
    }

    function _withdrawERC721(
        address receiver,
        IERC721 a,
        uint256[] calldata nftIds
    ) internal {
        IERC721 _nft = nft();
        uint256 numNFTs = nftIds.length;

        // If it's not the pair's NFT, just withdraw normally
        if (a != _nft) {
            for (uint256 i; i < numNFTs; ) {
                a.safeTransferFrom(address(this), receiver, nftIds[i]);

                unchecked {
                    ++i;
                }
            }
        }
        // Otherwise, withdraw and also remove the ID from the ID set
        else {
            for (uint256 i; i < numNFTs; ) {
                _nft.safeTransferFrom(address(this), receiver, nftIds[i]);
                idSet.remove(nftIds[i]);

                unchecked {
                    ++i;
                }
            }

            emit NFTWithdrawal(receiver, nftIds);
        }
    }

    /// @inheritdoc PotionPair
    function withdrawNfts(address receiver, uint256[] calldata nftIds)
        external
        override
        onlyWithdrawer
    {
        _withdrawERC721(receiver, nft(), nftIds);
    }

    /// @inheritdoc PotionPair
    function rescueERC721(
        address receiver,
        IERC721 a,
        uint256[] calldata nftIds
    ) external override onlyOwner {
        _withdrawERC721(receiver, a, nftIds);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.4;

interface IOwnershipTransferCallback {
  function onOwnershipTransfer(address oldOwner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}