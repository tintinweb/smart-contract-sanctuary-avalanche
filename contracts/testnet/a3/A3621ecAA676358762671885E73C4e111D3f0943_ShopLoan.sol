// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {IBNFT} from "../interfaces/IBNFT.sol";
import {IShopLoan} from "../interfaces/IShopLoan.sol";
import {IShop} from "../interfaces/IShop.sol";
import {IAddressesProvider} from "../interfaces/IAddressesProvider.sol";
import {IBNFTRegistry} from "../interfaces/IBNFTRegistry.sol";
import {Errors} from "../libraries/helpers/Errors.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";
import {Constants} from "../libraries/configuration/Constants.sol";

import {IERC721Upgradeable} from "../openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import {IERC721ReceiverUpgradeable} from "../openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";
import {CountersUpgradeable} from "../openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {Initializable} from "../openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {ContextUpgradeable} from "../openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import {GenericLogic} from "../libraries/logic/GenericLogic.sol";

contract ShopLoan is
    Initializable,
    IShopLoan,
    ContextUpgradeable,
    IERC721ReceiverUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    IAddressesProvider private _provider;

    CountersUpgradeable.Counter private _loanIdTracker;
    mapping(uint256 => DataTypes.LoanData) private _loans;

    // nftAsset + nftTokenId => loanId
    mapping(address => mapping(uint256 => uint256)) private _nftToLoanIds;
    mapping(address => uint256) private _nftTotalCollateral;
    mapping(address => mapping(address => uint256)) private _userNftCollateral;

    /**
     * @dev Only lending pool can call functions marked by this modifier
     **/
    modifier onlyShopFactory() {
        require(
            _msgSender() == address(_getShopFactory()),
            Errors.CT_CALLER_MUST_BE_LEND_POOL
        );
        _;
    }

    // called once by the factory at time of deployment
    function initialize(IAddressesProvider provider) external initializer {
        __Context_init();

        _provider = provider;

        // Avoid having loanId = 0
        _loanIdTracker.increment();

        emit Initialized(address(_getShopFactory()));
    }

    function initNft(address nftAsset) external override onlyShopFactory {
        IBNFTRegistry bnftRegistry = IBNFTRegistry(_provider.bnftRegistry());
        (address bNftAddress, ) = bnftRegistry.getBNFTAddresses(nftAsset);
        IERC721Upgradeable(nftAsset).setApprovalForAll(bNftAddress, true);
    }

    /**
     * @inheritdoc IShopLoan
     */
    function createLoan(
        uint256 shopId,
        address borrower,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount,
        uint256 interestRate
    ) external override onlyShopFactory returns (uint256) {
        require(
            _nftToLoanIds[nftAsset][nftTokenId] == 0,
            Errors.LP_NFT_HAS_USED_AS_COLLATERAL
        );

        uint256 loanId = _loanIdTracker.current();
        _loanIdTracker.increment();

        _nftToLoanIds[nftAsset][nftTokenId] = loanId;

        // transfer underlying NFT asset to pool and mint bNFT to onBehalfOf
        IERC721Upgradeable(nftAsset).safeTransferFrom(
            _msgSender(), // shopFactory
            address(this),
            nftTokenId
        );

        address bNftAddress = GenericLogic.getBNftAddress(_provider, nftAsset);
        IBNFT(bNftAddress).mint(borrower, nftTokenId);

        // Save Info
        DataTypes.LoanData storage loanData = _loans[loanId];
        loanData.shopId = shopId;
        loanData.loanId = loanId;
        loanData.state = DataTypes.LoanState.Active;
        loanData.borrower = borrower;
        loanData.nftAsset = nftAsset;
        loanData.nftTokenId = nftTokenId;
        loanData.reserveAsset = reserveAsset;
        loanData.borrowAmount = amount;

        loanData.createdAt = block.timestamp;
        loanData.updatedAt = block.timestamp;
        loanData.lastRepaidAt = block.timestamp;
        loanData.expiredAt = block.timestamp + _provider.maxLoanDuration();
        loanData.interestRate = interestRate;

        _userNftCollateral[borrower][nftAsset] += 1;

        _nftTotalCollateral[nftAsset] += 1;

        emit LoanCreated(
            borrower,
            loanId,
            nftAsset,
            nftTokenId,
            reserveAsset,
            amount
        );

        return (loanId);
    }

    /**
     * @inheritdoc IShopLoan
     */
    function partialRepayLoan(
        address initiator,
        uint256 loanId,
        uint256 repayAmount
    ) external override onlyShopFactory {
        // Must use storage to change state
        DataTypes.LoanData storage loan = _loans[loanId];
        // Ensure valid loan state
        require(
            loan.state == DataTypes.LoanState.Active,
            Errors.LPL_INVALID_LOAN_STATE
        );
        uint256 currentInterest = 0;
        if (repayAmount > 0) {
            (uint256 repayPrincipal, , ) = GenericLogic.calculateInterestInfo(
                GenericLogic.CalculateInterestInfoVars({
                    lastRepaidAt: loan.lastRepaidAt,
                    borrowAmount: loan.borrowAmount,
                    interestRate: loan.interestRate,
                    repayAmount: repayAmount,
                    platformFee: _provider.platformFeePercentage(),
                    interestDuration: _provider.interestDuration()
                })
            );
            require(
                loan.borrowAmount > repayPrincipal,
                Errors.LPL_INVALID_LOAN_AMOUNT
            );
            loan.borrowAmount = loan.borrowAmount - repayPrincipal;
            loan.lastRepaidAt = block.timestamp;
            require(loan.borrowAmount > 0, Errors.LPL_INVALID_LOAN_AMOUNT);
        }
        emit LoanPartialRepay(
            initiator,
            loanId,
            loan.nftAsset,
            loan.nftTokenId,
            loan.reserveAsset,
            repayAmount,
            currentInterest
        );
    }

    /**
     * @inheritdoc IShopLoan
     */
    function repayLoan(
        address initiator,
        uint256 loanId,
        uint256 amount
    ) external override onlyShopFactory {
        // Must use storage to change state
        DataTypes.LoanData storage loan = _loans[loanId];

        // Ensure valid loan state
        require(
            loan.state == DataTypes.LoanState.Active,
            Errors.LPL_INVALID_LOAN_STATE
        );

        // state changes and cleanup
        // NOTE: these must be performed before assets are released to prevent reentrance
        _loans[loanId].state = DataTypes.LoanState.Repaid;
        _loans[loanId].borrowAmount = 0;
        _loans[loanId].lastRepaidAt = block.timestamp;

        _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

        require(
            _userNftCollateral[loan.borrower][loan.nftAsset] >= 1,
            Errors.LP_INVALIED_USER_NFT_AMOUNT
        );
        _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

        require(
            _nftTotalCollateral[loan.nftAsset] >= 1,
            Errors.LP_INVALIED_NFT_AMOUNT
        );
        _nftTotalCollateral[loan.nftAsset] -= 1;

        address bNftAddress = GenericLogic.getBNftAddress(
            _provider,
            loan.nftAsset
        );
        IBNFT(bNftAddress).burn(loan.nftTokenId);

        IERC721Upgradeable(loan.nftAsset).safeTransferFrom(
            address(this),
            _msgSender(),
            loan.nftTokenId
        );

        emit LoanRepaid(
            initiator,
            loanId,
            loan.nftAsset,
            loan.nftTokenId,
            loan.reserveAsset,
            amount
        );
    }

    /**
     * @inheritdoc IShopLoan
     */
    function auctionLoan(
        address initiator,
        uint256 loanId,
        address onBehalfOf,
        uint256 bidPrice,
        uint256 borrowAmount
    ) external override onlyShopFactory {
        // Must use storage to change state
        DataTypes.LoanData storage loan = _loans[loanId];
        address previousBidder = loan.bidderAddress;
        uint256 previousPrice = loan.bidPrice;
        // Ensure valid loan state
        if (loan.bidStartTimestamp == 0) {
            require(
                loan.state == DataTypes.LoanState.Active,
                Errors.LPL_INVALID_LOAN_STATE
            );
            loan.state = DataTypes.LoanState.Auction;
            loan.bidStartTimestamp = block.timestamp;
            loan.firstBidderAddress = onBehalfOf;
        } else {
            require(
                loan.state == DataTypes.LoanState.Auction,
                Errors.LPL_INVALID_LOAN_STATE
            );
            require(
                bidPrice > loan.bidPrice,
                Errors.LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE
            );
        }
        loan.bidBorrowAmount = borrowAmount;
        loan.bidderAddress = onBehalfOf;
        loan.bidPrice = bidPrice;
        emit LoanAuctioned(
            initiator,
            loanId,
            loan.nftAsset,
            loan.nftTokenId,
            loan.bidBorrowAmount,
            onBehalfOf,
            bidPrice,
            previousBidder,
            previousPrice
        );
    }

    // /**
    //  * @inheritdoc IShopLoan
    //  */
    function redeemLoan(
        address initiator,
        uint256 loanId,
        uint256 amountTaken
    ) external override onlyShopFactory {
        // Must use storage to change state
        DataTypes.LoanData storage loan = _loans[loanId];
        // Ensure valid loan state
        require(
            loan.state == DataTypes.LoanState.Auction,
            Errors.LPL_INVALID_LOAN_STATE
        );
        require(
            loan.borrowAmount >= amountTaken,
            Errors.LPL_INVALID_TAKEN_AMOUNT
        );
        loan.borrowAmount -= amountTaken;
        loan.state = DataTypes.LoanState.Active;
        loan.bidStartTimestamp = 0;
        loan.bidBorrowAmount = 0;
        loan.bidderAddress = address(0);
        loan.bidPrice = 0;
        loan.firstBidderAddress = address(0);
        emit LoanRedeemed(
            initiator,
            loanId,
            loan.nftAsset,
            loan.nftTokenId,
            loan.reserveAsset,
            amountTaken
        );
    }

    /**
     * @inheritdoc IShopLoan
     */
    function liquidateLoan(
        address initiator,
        uint256 loanId,
        uint256 borrowAmount
    ) external override onlyShopFactory {
        // Must use storage to change state
        DataTypes.LoanData storage loan = _loans[loanId];

        // Ensure valid loan state
        require(
            loan.state == DataTypes.LoanState.Auction,
            Errors.LPL_INVALID_LOAN_STATE
        );

        // state changes and cleanup
        // NOTE: these must be performed before assets are released to prevent reentrance
        _loans[loanId].state = DataTypes.LoanState.Defaulted;
        _loans[loanId].bidBorrowAmount = borrowAmount;

        _nftToLoanIds[loan.nftAsset][loan.nftTokenId] = 0;

        require(
            _userNftCollateral[loan.borrower][loan.nftAsset] >= 1,
            Errors.LP_INVALIED_USER_NFT_AMOUNT
        );
        _userNftCollateral[loan.borrower][loan.nftAsset] -= 1;

        require(
            _nftTotalCollateral[loan.nftAsset] >= 1,
            Errors.LP_INVALIED_NFT_AMOUNT
        );
        _nftTotalCollateral[loan.nftAsset] -= 1;

        // burn bNFT and transfer underlying NFT asset to user
        address bNftAddress = GenericLogic.getBNftAddress(
            _provider,
            loan.nftAsset
        );

        IBNFT(bNftAddress).burn(loan.nftTokenId);

        IERC721Upgradeable(loan.nftAsset).safeTransferFrom(
            address(this),
            _msgSender(),
            loan.nftTokenId
        );

        emit LoanLiquidated(
            initiator,
            loanId,
            loan.nftAsset,
            loan.nftTokenId,
            loan.reserveAsset,
            borrowAmount
        );
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        operator;
        from;
        tokenId;
        data;
        return IERC721ReceiverUpgradeable.onERC721Received.selector;
    }

    function borrowerOf(uint256 loanId)
        external
        view
        override
        returns (address)
    {
        return _loans[loanId].borrower;
    }

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId)
        external
        view
        override
        returns (uint256)
    {
        return _nftToLoanIds[nftAsset][nftTokenId];
    }

    function getLoan(uint256 loanId)
        external
        view
        override
        returns (DataTypes.LoanData memory loanData)
    {
        return _loans[loanId];
    }

    function totalDebtInReserve(uint256 loanId, uint256 repayAmount)
        external
        view
        override
        returns (
            address asset,
            uint256 borrowAmount,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 fee
        )
    {
        asset = _loans[loanId].reserveAsset;
        (repayPrincipal, interest, fee) = GenericLogic.calculateInterestInfo(
            GenericLogic.CalculateInterestInfoVars({
                lastRepaidAt: _loans[loanId].lastRepaidAt,
                borrowAmount: _loans[loanId].borrowAmount,
                interestRate: _loans[loanId].interestRate,
                repayAmount: repayAmount,
                platformFee: _provider.platformFeePercentage(),
                interestDuration: _provider.interestDuration()
            })
        );
        return (
            asset,
            _loans[loanId].borrowAmount,
            repayPrincipal,
            interest,
            fee
        );
    }

    function getLoanHighestBid(uint256 loanId)
        external
        view
        override
        returns (address, uint256)
    {
        return (_loans[loanId].bidderAddress, _loans[loanId].bidPrice);
    }

    function _getShopFactory() internal view returns (address) {
        return IAddressesProvider(_provider).shopFactory();
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library DataTypes {
    struct ShopData {
        uint256 id;
        address creator;
    }

    struct ReservesInfo {
        uint8 id;
        address contractAddress;
        bool active;
        string symbol;
        uint256 decimals;
    }
    struct NftsInfo {
        uint8 id;
        bool active;
        address contractAddress;
        string collection;
        uint256 maxSupply;
    }

    enum LoanState {
        // We need a default that is not 'Created' - this is the zero value
        None,
        // The loan data is stored, but not initiated yet.
        Created,
        // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
        Active,
        // The loan is in auction, higest price liquidator will got chance to claim it.
        Auction,
        // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
        Repaid,
        // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
        Defaulted
    }
    struct LoanData {
        uint256 shopId;
        //the id of the nft loan
        uint256 loanId;
        //the current state of the loan
        LoanState state;
        //address of borrower
        address borrower;
        //address of nft asset token
        address nftAsset;
        //the id of nft token
        uint256 nftTokenId;
        //address of reserve asset token
        address reserveAsset;
        //borrow amount
        uint256 borrowAmount;
        //start time of first bid time
        uint256 bidStartTimestamp;
        //bidder address of higest bid
        address bidderAddress;
        //price of higest bid
        uint256 bidPrice;
        //borrow amount of loan
        uint256 bidBorrowAmount;
        //bidder address of first bid
        address firstBidderAddress;
        uint256 createdAt;
        uint256 updatedAt;
        uint256 lastRepaidAt;
        uint256 expiredAt;
        uint256 interestRate;
    }

    struct GlobalConfiguration {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32: Active
        uint256 data;
    }

    struct ShopConfiguration {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32: Active
        uint256 data;
    }

    struct ExecuteLendPoolStates {
        uint256 pauseStartTime;
        uint256 pauseDurationTime;
    }

    struct ExecuteBorrowParams {
        address initiator;
        address asset;
        uint256 amount;
        address nftAsset;
        uint256 nftTokenId;
        address onBehalfOf;
    }
    struct ExecuteBatchBorrowParams {
        address initiator;
        address[] assets;
        uint256[] amounts;
        address[] nftAssets;
        uint256[] nftTokenIds;
        address onBehalfOf;
    }
    struct ExecuteRepayParams {
        address initiator;
        uint256 loanId;
        uint256 amount;
        address shopCreator;
    }

    struct ExecuteBatchRepayParams {
        address initiator;
        uint256[] loanIds;
        uint256[] amounts;
        address shopCreator;
    }
    struct ExecuteAuctionParams {
        address initiator;
        uint256 loanId;
        uint256 bidPrice;
        address onBehalfOf;
    }

    struct ExecuteRedeemParams {
        address initiator;
        uint256 loanId;
        uint256 amount;
        uint256 bidFine;
    }

    struct ExecuteLiquidateParams {
        address initiator;
        uint256 loanId;
        address shopCreator;
    }

    struct ShopConfigParams {
        address reserveAddress;
        address nftAddress;
        uint256 interestRate;
        uint256 ltvRate;
        bool active;
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
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {Errors} from "../helpers/Errors.sol";

/**
 * @title PercentageMath library
 * @author Bend
 * @notice Provides functions to perform percentage calculations
 * @dev Percentages are defined by default with 2 decimals of precision (100.00). The precision is indicated by PERCENTAGE_FACTOR
 * @dev Operations are rounded half up
 **/

library PercentageMath {
    uint256 constant PERCENTAGE_FACTOR = 1e4; //percentage plus two decimals
    uint256 constant HALF_PERCENT = PERCENTAGE_FACTOR / 2;
    uint256 constant ONE_PERCENT = 1e2; //100, 1%
    uint256 constant TEN_PERCENT = 1e3; //1000, 10%
    uint256 constant ONE_THOUSANDTH_PERCENT = 1e1; //10, 0.1%
    uint256 constant ONE_TEN_THOUSANDTH_PERCENT = 1; //1, 0.01%

    /**
     * @dev Executes a percentage multiplication
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The percentage of value
     **/
    function percentMul(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        if (value == 0 || percentage == 0) {
            return 0;
        }

        require(
            value <= (type(uint256).max - HALF_PERCENT) / percentage,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (value * percentage + HALF_PERCENT) / PERCENTAGE_FACTOR;
    }

    /**
     * @dev Executes a percentage division
     * @param value The value of which the percentage needs to be calculated
     * @param percentage The percentage of the value to be calculated
     * @return The value divided the percentage
     **/
    function percentDiv(uint256 value, uint256 percentage)
        internal
        pure
        returns (uint256)
    {
        require(percentage != 0, Errors.MATH_DIVISION_BY_ZERO);
        uint256 halfPercentage = percentage / 2;

        require(
            value <= (type(uint256).max - halfPercentage) / PERCENTAGE_FACTOR,
            Errors.MATH_MULTIPLICATION_OVERFLOW
        );

        return (value * PERCENTAGE_FACTOR + halfPercentage) / percentage;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {IShopLoan} from "../../interfaces/IShopLoan.sol";
import {INFTOracleGetter} from "../../interfaces/INFTOracleGetter.sol";
import {IReserveOracleGetter} from "../../interfaces/IReserveOracleGetter.sol";
import {IBNFTRegistry} from "../../interfaces/IBNFTRegistry.sol";
import {PercentageMath} from "../math/PercentageMath.sol";
import {SafeMath} from "../math/SafeMath.sol";
import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

import {ShopConfiguration} from "../configuration/ShopConfiguration.sol";
import {IAddressesProvider} from "../../interfaces/IAddressesProvider.sol";

/**
 * @title GenericLogic library
 * @author Bend
 * @notice Implements protocol-level logic to calculate and validate the state of a user
 */
library GenericLogic {
    using PercentageMath for uint256;
    using SafeMath for uint256;
    using ShopConfiguration for DataTypes.ShopConfiguration;
    uint256 public constant HEALTH_FACTOR_LIQUIDATION_THRESHOLD = 1 ether;

    struct CalculateLoanDataVars {
        uint256 reserveUnitPrice;
        uint256 reserveUnit;
        uint256 reserveDecimals;
        uint256 healthFactor;
        uint256 totalCollateralInETH;
        uint256 totalCollateralInReserve;
        uint256 totalDebtInETH;
        uint256 totalDebtInReserve;
        uint256 nftLtv;
        uint256 nftLiquidationThreshold;
        address nftAsset;
        uint256 nftTokenId;
        uint256 nftUnitPrice;
    }

    /**
     * @dev Calculates the nft loan data.
     * this includes the total collateral/borrow balances in Reserve,
     * the Loan To Value, the Liquidation Ratio, and the Health factor.
     * @param reserveData Data of the reserve
     * @param reserveOracle The price oracle address of reserve
     * @param nftOracle The price oracle address of nft
     * @return The total collateral and total debt of the loan in Reserve, the ltv, liquidation threshold and the HF
     **/
    function calculateLoanData(
        IAddressesProvider provider,
        DataTypes.ShopConfiguration storage config,
        address reserveAddress,
        DataTypes.ReservesInfo storage reserveData,
        address nftAddress,
        address loanAddress,
        uint256 loanId,
        address reserveOracle,
        address nftOracle
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        CalculateLoanDataVars memory vars;

        vars.nftLtv = config.getLtv();
        vars.nftLiquidationThreshold = provider.liquidationThreshold();

        // calculate total borrow balance for the loan
        if (loanId != 0) {
            (
                vars.totalDebtInETH,
                vars.totalDebtInReserve
            ) = calculateNftDebtData(
                reserveAddress,
                reserveData,
                loanAddress,
                loanId,
                reserveOracle
            );
        }

        // calculate total collateral balance for the nft
        (
            vars.totalCollateralInETH,
            vars.totalCollateralInReserve
        ) = calculateNftCollateralData(
            reserveAddress,
            reserveData,
            nftAddress,
            reserveOracle,
            nftOracle
        );

        // calculate health by borrow and collateral
        vars.healthFactor = calculateHealthFactorFromBalances(
            vars.totalCollateralInReserve,
            vars.totalDebtInReserve,
            vars.nftLiquidationThreshold
        );

        return (
            vars.totalCollateralInReserve,
            vars.totalDebtInReserve,
            vars.healthFactor
        );
    }

    function calculateNftDebtData(
        address reserveAddress,
        DataTypes.ReservesInfo storage reserveData,
        address loanAddress,
        uint256 loanId,
        address reserveOracle
    ) internal view returns (uint256, uint256) {
        CalculateLoanDataVars memory vars;

        // all asset price has converted to ETH based, unit is in WEI (18 decimals)

        vars.reserveDecimals = reserveData.decimals;
        vars.reserveUnit = 10**vars.reserveDecimals;

        vars.reserveUnitPrice = IReserveOracleGetter(reserveOracle)
            .getAssetPrice(reserveAddress);

        (, uint256 borrowAmount, , uint256 interest, uint256 fee) = IShopLoan(
            loanAddress
        ).totalDebtInReserve(loanId, 0);
        vars.totalDebtInReserve = borrowAmount + interest + fee;
        vars.totalDebtInETH =
            (vars.totalDebtInReserve * vars.reserveUnitPrice) /
            vars.reserveUnit;

        return (vars.totalDebtInETH, vars.totalDebtInReserve);
    }

    function calculateNftCollateralData(
        address reserveAddress,
        DataTypes.ReservesInfo storage reserveData,
        address nftAddress,
        address reserveOracle,
        address nftOracle
    ) internal view returns (uint256, uint256) {
        CalculateLoanDataVars memory vars;

        vars.nftUnitPrice = INFTOracleGetter(nftOracle).getAssetPrice(
            nftAddress
        );
        vars.totalCollateralInETH = vars.nftUnitPrice;

        if (reserveAddress != address(0)) {
            vars.reserveDecimals = reserveData.decimals;
            vars.reserveUnit = 10**vars.reserveDecimals;

            vars.reserveUnitPrice = IReserveOracleGetter(reserveOracle)
                .getAssetPrice(reserveAddress);

            vars.totalCollateralInReserve =
                (vars.totalCollateralInETH * vars.reserveUnit) /
                vars.reserveUnitPrice;
        }

        return (vars.totalCollateralInETH, vars.totalCollateralInReserve);
    }

    /**
     * @dev Calculates the health factor from the corresponding balances
     * @param totalCollateral The total collateral
     * @param totalDebt The total debt
     * @param liquidationThreshold The avg liquidation threshold
     * @return The health factor calculated from the balances provided
     **/
    function calculateHealthFactorFromBalances(
        uint256 totalCollateral,
        uint256 totalDebt,
        uint256 liquidationThreshold
    ) internal pure returns (uint256) {
        if (totalDebt == 0) return type(uint256).max;

        return (totalCollateral.percentMul(liquidationThreshold)) / totalDebt;
    }

    struct CalculateInterestInfoVars {
        uint256 lastRepaidAt;
        uint256 borrowAmount;
        uint256 interestRate;
        uint256 repayAmount;
        uint256 platformFee;
        uint256 interestDuration;
    }

    function calculateInterestInfo(CalculateInterestInfoVars memory vars)
        internal
        view
        returns (
            uint256 repayPrincipal,
            uint256 interest,
            uint256 platformFee
        )
    {
        if (vars.interestDuration == 0) {
            vars.interestDuration = 86400; //1day
        }
        uint256 sofarLoanDay = (
            (block.timestamp - vars.lastRepaidAt).div(vars.interestDuration)
        ).add(1);
        interest = vars
            .borrowAmount
            .mul(vars.interestRate)
            .mul(sofarLoanDay)
            .div(uint256(10000))
            .div(uint256(365 * 86400) / vars.interestDuration);

        if (vars.repayAmount > 0) {
            require(
                vars.repayAmount > interest,
                Errors.LP_REPAY_AMOUNT_NOT_ENOUGH
            );
            repayPrincipal = vars.repayAmount - interest;
            repayPrincipal = repayPrincipal.mul(10000).div(
                10000 + vars.platformFee
            );
            platformFee = repayPrincipal.mul(vars.platformFee).div(10000);
        } else {
            platformFee = vars.borrowAmount.mul(vars.platformFee).div(10000);
        }

        return (repayPrincipal, interest, platformFee);
    }

    struct CalcLiquidatePriceLocalVars {
        uint256 ltv;
        uint256 liquidationThreshold;
        uint256 liquidationBonus;
        uint256 nftPriceInETH;
        uint256 nftPriceInReserve;
        uint256 reserveDecimals;
        uint256 reservePriceInETH;
        uint256 thresholdPrice;
        uint256 liquidatePrice;
        uint256 borrowAmount;
        uint256 repayPrincipal;
        uint256 interest;
        uint256 platformFee;
    }

    function calculateLoanLiquidatePrice(
        IAddressesProvider provider,
        uint256 loanId,
        address reserveAsset,
        DataTypes.ReservesInfo storage reserveData,
        address nftAsset,
        address poolLoan,
        address reserveOracle,
        address nftOracle
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        CalcLiquidatePriceLocalVars memory vars;

        /*
         * 0                   CR                  LH                  100
         * |___________________|___________________|___________________|
         *  <       Borrowing with Interest        <
         * CR: Callteral Ratio;
         * LH: Liquidate Threshold;
         * Liquidate Trigger: Borrowing with Interest > thresholdPrice;
         * Liquidate Price: (100% - BonusRatio) * NFT Price;
         */

        vars.reserveDecimals = reserveData.decimals;

        // TODO base theo pawnshop
        DataTypes.LoanData memory loan = IShopLoan(poolLoan).getLoan(loanId);
        (, vars.interest, vars.platformFee) = calculateInterestInfo(
            CalculateInterestInfoVars({
                lastRepaidAt: loan.lastRepaidAt,
                borrowAmount: loan.borrowAmount,
                interestRate: loan.interestRate,
                repayAmount: 0,
                platformFee: provider.platformFeePercentage(),
                interestDuration: provider.interestDuration()
            })
        );

        vars.borrowAmount =
            loan.borrowAmount +
            vars.interest +
            vars.platformFee;

        vars.liquidationThreshold = provider.liquidationThreshold();
        vars.liquidationBonus = provider.liquidationBonus();

        require(
            vars.liquidationThreshold > 0,
            Errors.LP_INVALID_LIQUIDATION_THRESHOLD
        );

        vars.nftPriceInETH = INFTOracleGetter(nftOracle).getAssetPrice(
            nftAsset
        );
        vars.reservePriceInETH = IReserveOracleGetter(reserveOracle)
            .getAssetPrice(reserveAsset);

        vars.nftPriceInReserve =
            ((10**vars.reserveDecimals) * vars.nftPriceInETH) /
            vars.reservePriceInETH;

        vars.thresholdPrice = vars.nftPriceInReserve.percentMul(
            vars.liquidationThreshold
        );

        vars.liquidatePrice = vars.nftPriceInReserve.percentMul(
            PercentageMath.PERCENTAGE_FACTOR - vars.liquidationBonus
        );

        return (vars.borrowAmount, vars.thresholdPrice, vars.liquidatePrice);
    }

    struct CalcLoanBidFineLocalVars {
        uint256 reserveDecimals;
        uint256 reservePriceInETH;
        uint256 baseBidFineInReserve;
        uint256 minBidFinePct;
        uint256 minBidFineInReserve;
        uint256 bidFineInReserve;
        uint256 debtAmount;
    }

    function calculateLoanBidFine(
        IAddressesProvider provider,
        address reserveAsset,
        DataTypes.ReservesInfo storage reserveData,
        address nftAsset,
        DataTypes.LoanData memory loanData,
        address poolLoan,
        address reserveOracle
    ) internal view returns (uint256, uint256) {
        nftAsset;

        if (loanData.bidPrice == 0) {
            return (0, 0);
        }

        CalcLoanBidFineLocalVars memory vars;

        vars.reserveDecimals = reserveData.decimals;
        vars.reservePriceInETH = IReserveOracleGetter(reserveOracle)
            .getAssetPrice(reserveAsset);
        vars.baseBidFineInReserve =
            (1 ether * 10**vars.reserveDecimals) /
            vars.reservePriceInETH;

        vars.minBidFinePct = provider.minBidFine();
        vars.minBidFineInReserve = vars.baseBidFineInReserve.percentMul(
            vars.minBidFinePct
        );

        (, uint256 borrowAmount, , uint256 interest, uint256 fee) = IShopLoan(
            poolLoan
        ).totalDebtInReserve(loanData.loanId, 0);

        vars.debtAmount = borrowAmount + interest + fee;

        vars.bidFineInReserve = vars.debtAmount.percentMul(
            provider.redeemFine()
        );
        if (vars.bidFineInReserve < vars.minBidFineInReserve) {
            vars.bidFineInReserve = vars.minBidFineInReserve;
        }

        return (vars.minBidFineInReserve, vars.bidFineInReserve);
    }

    function calculateLoanAuctionEndTimestamp(
        IAddressesProvider provider,
        uint256 bidStartTimestamp
    )
        internal
        view
        returns (uint256 auctionEndTimestamp, uint256 redeemEndTimestamp)
    {
        auctionEndTimestamp = bidStartTimestamp + provider.auctionDuration();

        redeemEndTimestamp = bidStartTimestamp + provider.redeemDuration();
    }

    /**
     * @dev Calculates the equivalent amount that an user can borrow, depending on the available collateral and the
     * average Loan To Value
     * @param totalCollateral The total collateral
     * @param totalDebt The total borrow balance
     * @param ltv The average loan to value
     * @return the amount available to borrow for the user
     **/

    function calculateAvailableBorrows(
        uint256 totalCollateral,
        uint256 totalDebt,
        uint256 ltv
    ) internal pure returns (uint256) {
        uint256 availableBorrows = totalCollateral.percentMul(ltv);

        if (availableBorrows < totalDebt) {
            return 0;
        }

        availableBorrows = availableBorrows - totalDebt;
        return availableBorrows;
    }

    function getBNftAddress(IAddressesProvider provider, address nftAsset)
        internal
        view
        returns (address bNftAddress)
    {
        IBNFTRegistry bnftRegistry = IBNFTRegistry(provider.bnftRegistry());
        (bNftAddress, ) = bnftRegistry.getBNFTAddresses(nftAsset);
        return bNftAddress;
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title Errors library
 * @author Bend
 * @notice Defines the error messages emitted by the different contracts of the Bend protocol
 */
library Errors {
    enum ReturnCode {
        SUCCESS,
        FAILED
    }

    string public constant SUCCESS = "0";

    //common errors
    string public constant CALLER_NOT_POOL_ADMIN = "100"; // 'The caller must be the pool admin'
    string public constant CALLER_NOT_ADDRESS_PROVIDER = "101";
    string public constant INVALID_FROM_BALANCE_AFTER_TRANSFER = "102";
    string public constant INVALID_TO_BALANCE_AFTER_TRANSFER = "103";
    string public constant CALLER_NOT_ONBEHALFOF_OR_IN_WHITELIST = "104";

    //math library erros
    string public constant MATH_MULTIPLICATION_OVERFLOW = "200";
    string public constant MATH_ADDITION_OVERFLOW = "201";
    string public constant MATH_DIVISION_BY_ZERO = "202";

    //validation & check errors
    string public constant VL_INVALID_AMOUNT = "301"; // 'Amount must be greater than 0'
    string public constant VL_NO_ACTIVE_RESERVE = "302"; // 'Action requires an active reserve'
    string public constant VL_RESERVE_FROZEN = "303"; // 'Action cannot be performed because the reserve is frozen'
    string public constant VL_NOT_ENOUGH_AVAILABLE_USER_BALANCE = "304"; // 'User cannot withdraw more than the available balance'
    string public constant VL_BORROWING_NOT_ENABLED = "305"; // 'Borrowing is not enabled'
    string public constant VL_COLLATERAL_BALANCE_IS_0 = "306"; // 'The collateral balance is 0'
    string public constant VL_HEALTH_FACTOR_LOWER_THAN_LIQUIDATION_THRESHOLD =
        "307"; // 'Health factor is lesser than the liquidation threshold'
    string public constant VL_COLLATERAL_CANNOT_COVER_NEW_BORROW = "308"; // 'There is not enough collateral to cover a new borrow'
    string public constant VL_NO_DEBT_OF_SELECTED_TYPE = "309"; // 'for repayment of stable debt, the user needs to have stable debt, otherwise, he needs to have variable debt'
    string public constant VL_NO_ACTIVE_NFT = "310";
    string public constant VL_NFT_FROZEN = "311";
    string public constant VL_SPECIFIED_CURRENCY_NOT_BORROWED_BY_USER = "312"; // 'User did not borrow the specified currency'
    string public constant VL_INVALID_HEALTH_FACTOR = "313";
    string public constant VL_INVALID_ONBEHALFOF_ADDRESS = "314";
    string public constant VL_INVALID_TARGET_ADDRESS = "315";
    string public constant VL_INVALID_RESERVE_ADDRESS = "316";
    string public constant VL_SPECIFIED_LOAN_NOT_BORROWED_BY_USER = "317";
    string public constant VL_SPECIFIED_RESERVE_NOT_BORROWED_BY_USER = "318";
    string public constant VL_HEALTH_FACTOR_HIGHER_THAN_LIQUIDATION_THRESHOLD =
        "319";

    //lend pool errors
    string public constant LP_CALLER_NOT_LEND_POOL_CONFIGURATOR = "400"; // 'The caller of the function is not the lending pool configurator'
    string public constant LP_IS_PAUSED = "401"; // 'Pool is paused'
    string public constant LP_NO_MORE_RESERVES_ALLOWED = "402";
    string public constant LP_NOT_CONTRACT = "403";
    string
        public constant LP_BORROW_NOT_EXCEED_LIQUIDATION_THRESHOLD_OR_EXPIRED =
        "404";
    string public constant LP_BORROW_IS_EXCEED_LIQUIDATION_PRICE = "405";
    string public constant LP_NO_MORE_NFTS_ALLOWED = "406";
    string public constant LP_INVALIED_USER_NFT_AMOUNT = "407";
    string public constant LP_INCONSISTENT_PARAMS = "408";
    string public constant LP_NFT_IS_NOT_USED_AS_COLLATERAL = "409";
    string public constant LP_CALLER_MUST_BE_AN_BTOKEN = "410";
    string public constant LP_INVALIED_NFT_AMOUNT = "411";
    string public constant LP_NFT_HAS_USED_AS_COLLATERAL = "412";
    string public constant LP_DELEGATE_CALL_FAILED = "413";
    string public constant LP_AMOUNT_LESS_THAN_EXTRA_DEBT = "414";
    string public constant LP_AMOUNT_LESS_THAN_REDEEM_THRESHOLD = "415";
    string public constant LP_AMOUNT_GREATER_THAN_MAX_REPAY = "416";
    string public constant LP_NFT_TOKEN_ID_EXCEED_MAX_LIMIT = "417";
    string public constant LP_NFT_SUPPLY_NUM_EXCEED_MAX_LIMIT = "418";
    string public constant LP_CALLER_NOT_SHOP_CREATOR = "419";
    string public constant LP_INVALID_LIQUIDATION_THRESHOLD = "420";
    string public constant LP_REPAY_AMOUNT_NOT_ENOUGH = "421";
    string public constant LP_NFT_ALREADY_INITIALIZED = "422"; // 'Nft has already been initialized'

    //lend pool loan errors
    string public constant LPL_INVALID_LOAN_STATE = "480";
    string public constant LPL_INVALID_LOAN_AMOUNT = "481";
    string public constant LPL_INVALID_TAKEN_AMOUNT = "482";
    string public constant LPL_AMOUNT_OVERFLOW = "483";
    string public constant LPL_BID_PRICE_LESS_THAN_LIQUIDATION_PRICE = "484";
    string public constant LPL_BID_PRICE_LESS_THAN_HIGHEST_PRICE = "485";
    string public constant LPL_BID_REDEEM_DURATION_HAS_END = "486";
    string public constant LPL_BID_USER_NOT_SAME = "487";
    string public constant LPL_BID_REPAY_AMOUNT_NOT_ENOUGH = "488";
    string public constant LPL_BID_AUCTION_DURATION_HAS_END = "489";
    string public constant LPL_BID_AUCTION_DURATION_NOT_END = "490";
    string public constant LPL_BID_PRICE_LESS_THAN_BORROW = "491";
    string public constant LPL_INVALID_BIDDER_ADDRESS = "492";
    string public constant LPL_AMOUNT_LESS_THAN_BID_FINE = "493";
    string public constant LPL_INVALID_BID_FINE = "494";

    //common token errors
    string public constant CT_CALLER_MUST_BE_LEND_POOL = "500"; // 'The caller of this function must be a lending pool'
    string public constant CT_INVALID_MINT_AMOUNT = "501"; //invalid amount to mint
    string public constant CT_INVALID_BURN_AMOUNT = "502"; //invalid amount to burn
    string public constant CT_BORROW_ALLOWANCE_NOT_ENOUGH = "503";

    //reserve logic errors
    string public constant RL_RESERVE_ALREADY_INITIALIZED = "601"; // 'Reserve has already been initialized'
    string public constant RL_LIQUIDITY_INDEX_OVERFLOW = "602"; //  Liquidity index overflows uint128
    string public constant RL_VARIABLE_BORROW_INDEX_OVERFLOW = "603"; //  Variable borrow index overflows uint128
    string public constant RL_LIQUIDITY_RATE_OVERFLOW = "604"; //  Liquidity rate overflows uint128
    string public constant RL_VARIABLE_BORROW_RATE_OVERFLOW = "605"; //  Variable borrow rate overflows uint128

    //configure errors
    string public constant LPC_RESERVE_LIQUIDITY_NOT_0 = "700"; // 'The liquidity of the reserve needs to be 0'
    string public constant LPC_INVALID_CONFIGURATION = "701"; // 'Invalid risk parameters for the reserve'
    string public constant LPC_CALLER_NOT_EMERGENCY_ADMIN = "702"; // 'The caller must be the emergency admin'
    string public constant LPC_INVALIED_BNFT_ADDRESS = "703";
    string public constant LPC_INVALIED_LOAN_ADDRESS = "704";
    string public constant LPC_NFT_LIQUIDITY_NOT_0 = "705";

    //reserve config errors
    string public constant RC_INVALID_LTV = "730";
    string public constant RC_INVALID_LIQ_THRESHOLD = "731";
    string public constant RC_INVALID_LIQ_BONUS = "732";
    string public constant RC_INVALID_DECIMALS = "733";
    string public constant RC_INVALID_RESERVE_FACTOR = "734";
    string public constant RC_INVALID_REDEEM_DURATION = "735";
    string public constant RC_INVALID_AUCTION_DURATION = "736";
    string public constant RC_INVALID_REDEEM_FINE = "737";
    string public constant RC_INVALID_REDEEM_THRESHOLD = "738";
    string public constant RC_INVALID_MIN_BID_FINE = "739";
    string public constant RC_INVALID_MAX_BID_FINE = "740";
    string public constant RC_NOT_ACTIVE = "741";
    string public constant RC_INVALID_INTEREST_RATE = "742";

    //address provider erros
    string public constant LPAPR_PROVIDER_NOT_REGISTERED = "760"; // 'Provider is not registered'
    string public constant LPAPR_INVALID_ADDRESSES_PROVIDER_ID = "761";
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {Errors} from "../helpers/Errors.sol";
import {DataTypes} from "../types/DataTypes.sol";

library ShopConfiguration {
    uint256 constant LTV_MASK =                   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000; // prettier-ignore
    uint256 constant ACTIVE_MASK =                0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFFFFFFFFFF; // prettier-ignore
    uint256 constant INTEREST_RATE_MASK =         0xFFFFFFFFFFFFFFFFFFFFFFFFFFFF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // prettier-ignore

    /// @dev For the LTV, the start bit is 0 (up to 15), hence no bitshifting is needed
    uint256 constant IS_ACTIVE_START_BIT_POSITION = 56;
    uint256 constant INTEREST_RATE_POSITION = 128;

    uint256 constant MAX_VALID_LTV = 65535;
    uint256 constant MAX_VALID_INTEREST_RATE = 65535;

    /**
     * @dev Sets the Loan to Value of the NFT
     * @param self The NFT configuration
     * @param ltv the new ltv
     **/
    function setLtv(DataTypes.ShopConfiguration memory self, uint256 ltv)
        internal
        pure
    {
        require(ltv <= MAX_VALID_LTV, Errors.RC_INVALID_LTV);

        self.data = (self.data & LTV_MASK) | ltv;
    }

    /**
     * @dev Gets the Loan to Value of the NFT
     * @param self The NFT configuration
     * @return The loan to value
     **/
    function getLtv(DataTypes.ShopConfiguration storage self)
        internal
        view
        returns (uint256)
    {
        return self.data & ~LTV_MASK;
    }

    /**
     * @dev Sets the active state of the NFT
     * @param self The NFT configuration
     * @param active The active state
     **/
    function setActive(DataTypes.ShopConfiguration memory self, bool active)
        internal
        pure
    {
        self.data =
            (self.data & ACTIVE_MASK) |
            (uint256(active ? 1 : 0) << IS_ACTIVE_START_BIT_POSITION);
    }

    /**
     * @dev Gets the active state of the NFT
     * @param self The NFT configuration
     * @return The active state
     **/
    function getActive(DataTypes.ShopConfiguration storage self)
        internal
        view
        returns (bool)
    {
        return (self.data & ~ACTIVE_MASK) != 0;
    }

    /**
     * @dev Sets the min & max threshold of the NFT
     * @param self The NFT configuration
     * @param interestRate The interestRate
     **/
    function setInterestRate(
        DataTypes.ShopConfiguration memory self,
        uint256 interestRate
    ) internal pure {
        require(
            interestRate <= MAX_VALID_INTEREST_RATE,
            Errors.RC_INVALID_INTEREST_RATE
        );

        self.data =
            (self.data & INTEREST_RATE_MASK) |
            (interestRate << INTEREST_RATE_POSITION);
    }

    /**
     * @dev Gets interate of the NFT
     * @param self The NFT configuration
     * @return The interest
     **/
    function getInterestRate(DataTypes.ShopConfiguration storage self)
        internal
        view
        returns (uint256)
    {
        return ((self.data & ~INTEREST_RATE_MASK) >> INTEREST_RATE_POSITION);
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

library Constants {
    // uint256 constant EXPIRE_LOAN = 5 seconds;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IShopLoan {
    /**
     * @dev Emitted on initialization to share location of dependent notes
     * @param pool The address of the associated lend pool
     */
    event Initialized(address indexed pool);

    /**
     * @dev Emitted when a loan is created
     * @param user The address initiating the action
     */
    event LoanCreated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount
    );

    /**
     * @dev Emitted when a loan is updated
     * @param user The address initiating the action
     */
    event LoanPartialRepay(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 repayAmount,
        uint256 currentInterest
    );

    /**
     * @dev Emitted when a loan is repaid by the borrower
     * @param user The address initiating the action
     */
    event LoanRepaid(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount
    );

    /**
     * @dev Emitted when a loan is auction by the liquidator
     * @param user The address initiating the action
     */
    event LoanAuctioned(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        uint256 amount,
        address bidder,
        uint256 price,
        address previousBidder,
        uint256 previousPrice
    );

    /**
     * @dev Emitted when a loan is redeemed
     * @param user The address initiating the action
     */
    event LoanRedeemed(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amountTaken
    );

    /**
     * @dev Emitted when a loan is liquidate by the liquidator
     * @param user The address initiating the action
     */
    event LoanLiquidated(
        address indexed user,
        uint256 indexed loanId,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount
    );

    function initNft(address nftAsset) external;

    /**
     * @dev Create store a loan object with some params
     * @param initiator The address of the user initiating the borrow
     */
    function createLoan(
        uint256 shopId,
        address initiator,
        address nftAsset,
        uint256 nftTokenId,
        address reserveAsset,
        uint256 amount,
        uint256 interestRate
    ) external returns (uint256);

    /**
     * @dev Update the given loan with some params
     *
     * Requirements:
     *  - The caller must be a holder of the loan
     *  - The loan must be in state Active
     * @param initiator The address of the user initiating the borrow
     */
    function partialRepayLoan(
        address initiator,
        uint256 loanId,
        uint256 repayAmount
    ) external;

    /**
     * @dev Repay the given loan
     *
     * Requirements:
     *  - The caller must be a holder of the loan
     *  - The caller must send in principal + interest
     *  - The loan must be in state Active
     *
     * @param initiator The address of the user initiating the repay
     * @param loanId The loan getting burned
     */
    function repayLoan(
        address initiator,
        uint256 loanId,
        uint256 amount
    ) external;

    /**
     * @dev Auction the given loan
     *
     * Requirements:
     *  - The price must be greater than current highest price
     *  - The loan must be in state Active or Auction
     *
     * @param initiator The address of the user initiating the auction
     * @param loanId The loan getting auctioned
     * @param bidPrice The bid price of this auction
     */
    function auctionLoan(
        address initiator,
        uint256 loanId,
        address onBehalfOf,
        uint256 bidPrice,
        uint256 borrowAmount
    ) external;

    // /**
    //  * @dev Redeem the given loan with some params
    //  *
    //  * Requirements:
    //  *  - The caller must be a holder of the loan
    //  *  - The loan must be in state Auction
    //  * @param initiator The address of the user initiating the borrow
    //  */
    function redeemLoan(
        address initiator,
        uint256 loanId,
        uint256 amountTaken
    ) external;

    /**
     * @dev Liquidate the given loan
     *
     * Requirements:
     *  - The caller must send in principal + interest
     *  - The loan must be in state Active
     *
     * @param initiator The address of the user initiating the auction
     * @param loanId The loan getting burned
     */
    function liquidateLoan(
        address initiator,
        uint256 loanId,
        uint256 borrowAmount
    ) external;

    function borrowerOf(uint256 loanId) external view returns (address);

    function getCollateralLoanId(address nftAsset, uint256 nftTokenId)
        external
        view
        returns (uint256);

    function getLoan(uint256 loanId)
        external
        view
        returns (DataTypes.LoanData memory loanData);

    function totalDebtInReserve(uint256 loanId, uint256 repayAmount)
        external
        view
        returns (
            address asset,
            uint256 borrowAmount,
            uint256 repayPrincipal,
            uint256 interest,
            uint256 fee
        );

    function getLoanHighestBid(uint256 loanId)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

import {IAddressesProvider} from "./IAddressesProvider.sol";
import {DataTypes} from "../libraries/types/DataTypes.sol";

interface IShop {
    //
    event Created(address indexed creator, uint256 id);
    /**
     * @dev Emitted on borrow() when loan needs to be opened
     * @param user The address of the user initiating the borrow(), receiving the funds
     * @param reserve The address of the underlying asset being borrowed
     * @param amount The amount borrowed out
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token id of the underlying NFT used as collateral
     * @param onBehalfOf The address that will be getting the loan
     * @param referral The referral code used
     **/
    event Borrow(
        address user,
        address indexed reserve,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address indexed onBehalfOf,
        uint256 borrowRate,
        uint256 loanId,
        uint16 indexed referral
    );

    /**
     * @dev Emitted on repay()
     * @param user The address of the user initiating the repay(), providing the funds
     * @param reserve The address of the underlying asset of the reserve
     * @param amount The amount repaid
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token id of the underlying NFT used as collateral
     * @param borrower The beneficiary of the repayment, getting his debt reduced
     * @param loanId The loan ID of the NFT loans
     **/
    event Repay(
        address user,
        address indexed reserve,
        uint256 amount,
        uint256 interestAmount,
        uint256 feeAmount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    /**
     * @dev Emitted when a borrower's loan is auctioned.
     * @param user The address of the user initiating the auction
     * @param reserve The address of the underlying asset of the reserve
     * @param bidPrice The price of the underlying reserve given by the bidder
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token id of the underlying NFT used as collateral
     * @param onBehalfOf The address that will be getting the NFT
     * @param loanId The loan ID of the NFT loans
     **/
    event Auction(
        address user,
        address indexed reserve,
        uint256 bidPrice,
        address indexed nftAsset,
        uint256 nftTokenId,
        address onBehalfOf,
        address indexed borrower,
        uint256 loanId
    );

    /**
     * @dev Emitted on redeem()
     * @param user The address of the user initiating the redeem(), providing the funds
     * @param reserve The address of the underlying asset of the reserve
     * @param borrowAmount The borrow amount repaid
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token id of the underlying NFT used as collateral
     * @param loanId The loan ID of the NFT loans
     **/
    event Redeem(
        address user,
        address indexed reserve,
        uint256 borrowAmount,
        uint256 fineAmount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    /**
     * @dev Emitted when a borrower's loan is liquidated.
     * @param user The address of the user initiating the auction
     * @param reserve The address of the underlying asset of the reserve
     * @param repayAmount The amount of reserve repaid by the liquidator
     * @param remainAmount The amount of reserve received by the borrower
     * @param loanId The loan ID of the NFT loans
     **/
    event Liquidate(
        address user,
        address indexed reserve,
        uint256 repayAmount,
        uint256 remainAmount,
        address indexed nftAsset,
        uint256 nftTokenId,
        address indexed borrower,
        uint256 loanId
    );

    event ConfigurationUpdated(
        uint256 shopId,
        address reserveAddress,
        address nftAddress,
        uint256 interestRate,
        uint256 ltvRate,
        bool active
    );

    /**
     * @dev Emitted when the pause is triggered.
     */
    event Paused();

    /**
     * @dev Emitted when the pause is lifted.
     */
    event Unpaused();

    /**
     * @dev Emitted when the pause time is updated.
     */
    event PausedTimeUpdated(uint256 startTime, uint256 durationTime);

    /**
     * @dev Emitted when the state of a reserve is updated. NOTE: This event is actually declared
     * in the ReserveLogic library and emitted in the updateInterestRates() function. Since the function is internal,
     * the event will actually be fired by the LendPool contract. The event is therefore replicated here so it
     * gets added to the LendPool ABI
     * @param reserve The address of the underlying asset of the reserve
     * @param liquidityRate The new liquidity rate
     * @param variableBorrowRate The new variable borrow rate
     * @param liquidityIndex The new liquidity index
     * @param variableBorrowIndex The new variable borrow index
     **/
    event ReserveDataUpdated(
        address indexed reserve,
        uint256 liquidityRate,
        uint256 variableBorrowRate,
        uint256 liquidityIndex,
        uint256 variableBorrowIndex
    );

    /**
     * @dev Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower
     * already deposited enough collateral
     * - E.g. User borrows 100 USDC, receiving the 100 USDC in his wallet
     *   and lock collateral asset in contract
     * @param reserveAsset The address of the underlying asset to borrow
     * @param amount The amount to be borrowed
     * @param nftAsset The address of the underlying NFT used as collateral
     * @param nftTokenId The token ID of the underlying NFT used as collateral
     **/
    function borrow(
        uint256 shopId,
        address reserveAsset,
        uint256 amount,
        address nftAsset,
        uint256 nftTokenId,
        address onBehalfOf
    ) external;

    function batchBorrow(
        uint256 shopId,
        address[] calldata assets,
        uint256[] calldata amounts,
        address[] calldata nftAssets,
        uint256[] calldata nftTokenIds,
        address onBehalfOf
    ) external;

    /**
     * @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent loan owned
     * - E.g. User repays 100 USDC, burning loan and receives collateral asset
     * @param amount The amount to repay
     * @return The final amount repaid, loan is burned or not
     **/
    function repay(uint256 loanId, uint256 amount)
        external
        returns (
            uint256,
            uint256,
            bool
        );

    function batchRepay(
        uint256 shopId,
        uint256[] calldata loanIds,
        uint256[] calldata amounts
    )
        external
        returns (
            uint256[] memory,
            uint256[] memory,
            bool[] memory
        );

    /**
     * @dev Function to auction a non-healthy position collateral-wise
     * - The caller (liquidator) want to buy collateral asset of the user getting liquidated
     * @param bidPrice The bid price of the liquidator want to buy the underlying NFT
     **/

    function auction(
        uint256 loanId,
        uint256 bidPrice,
        address onBehalfOf
    ) external;

    /**
     * @notice Redeem a NFT loan which state is in Auction
     * - E.g. User repays 100 USDC, burning loan and receives collateral asset
     * @param amount The amount to repay the debt
     * @param bidFine The amount of bid fine
     **/
    function redeem(
        uint256 loanId,
        uint256 amount,
        uint256 bidFine
    ) external returns (uint256);

    /**
     * @dev Function to liquidate a non-healthy position collateral-wise
     * - The caller (liquidator) buy collateral asset of the user getting liquidated, and receives
     *   the collateral asset
     **/
    function liquidate(uint256 loanId) external;

    function getReservesList() external view returns (address[] memory);

    /**
     * @dev Returns the debt data of the NFT
     * @return nftAsset the address of the NFT
     * @return nftTokenId nft token ID
     * @return reserveAsset the address of the Reserve
     * @return totalCollateral the total power of the NFT
     * @return totalDebt the total debt of the NFT
     * @return availableBorrows the borrowing power left of the NFT
     * @return healthFactor the current health factor of the NFT
     **/
    function getNftDebtData(uint256 loanId)
        external
        view
        returns (
            address nftAsset,
            uint256 nftTokenId,
            address reserveAsset,
            uint256 totalCollateral,
            uint256 totalDebt,
            uint256 availableBorrows,
            uint256 healthFactor
        );

    /**
     * @dev Returns the auction data of the NFT
     * @param loanId the loan id of the NFT
     * @return nftAsset The address of the NFT
     * @return nftTokenId The token id of the NFT
     * @return bidderAddress the highest bidder address of the loan
     * @return bidPrice the highest bid price in Reserve of the loan
     * @return bidBorrowAmount the borrow amount in Reserve of the loan
     * @return bidFine the penalty fine of the loan
     **/
    function getNftAuctionData(uint256 loanId)
        external
        view
        returns (
            address nftAsset,
            uint256 nftTokenId,
            address bidderAddress,
            uint256 bidPrice,
            uint256 bidBorrowAmount,
            uint256 bidFine
        );

    function getNftAuctionEndTime(uint256 loanId)
        external
        view
        returns (
            address nftAsset,
            uint256 nftTokenId,
            uint256 bidStartTimestamp,
            uint256 bidEndTimestamp,
            uint256 redeemEndTimestamp
        );

    function getNftLiquidatePrice(uint256 loanId)
        external
        view
        returns (uint256 liquidatePrice, uint256 paybackAmount);

    function getNftsList() external view returns (address[] memory);

    function setPause(bool val) external;

    function paused() external view returns (bool);

    function getAddressesProvider() external view returns (IAddressesProvider);

    function addReserve(address asset) external;

    function addNftCollection(
        address nftAddress,
        string memory collection,
        uint256 maxSupply
    ) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/************
@title IReserveOracleGetter interface
@notice Interface for getting Reserve price oracle.*/
interface IReserveOracleGetter {
    /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address asset) external view returns (uint256);

    // get twap price depending on _period
    function getTwapPrice(address _priceFeedKey, uint256 _interval)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/************
@title INFTOracleGetter interface
@notice Interface for getting NFT price oracle.*/
interface INFTOracleGetter {
    /* CAUTION: Price uint is ETH based (WEI, 18 decimals) */
    /***********
    @dev returns the asset price in ETH
     */
    function getAssetPrice(address asset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IBNFTRegistry {
  event Initialized(address genericImpl, string namePrefix, string symbolPrefix);
  event GenericImplementationUpdated(address genericImpl);
  event BNFTCreated(address indexed nftAsset, address bNftImpl, address bNftProxy, uint256 totals);
  event BNFTUpgraded(address indexed nftAsset, address bNftImpl, address bNftProxy, uint256 totals);
  event CustomeSymbolsAdded(address[] nftAssets, string[] symbols);
  event ClaimAdminUpdated(address oldAdmin, address newAdmin);

  function getBNFTAddresses(address nftAsset) external view returns (address bNftProxy, address bNftImpl);

  function getBNFTAddressesByIndex(uint16 index) external view returns (address bNftProxy, address bNftImpl);

  function getBNFTAssetList() external view returns (address[] memory);

  function allBNFTAssetLength() external view returns (uint256);

  function initialize(
    address genericImpl,
    string memory namePrefix_,
    string memory symbolPrefix_
  ) external;

  function setBNFTGenericImpl(address genericImpl) external;

  /**
   * @dev Create bNFT proxy and implement, then initialize it
   * @param nftAsset The address of the underlying asset of the BNFT
   **/
  function createBNFT(address nftAsset) external returns (address bNftProxy);

  /**
   * @dev Create bNFT proxy with already deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the BNFT
   * @param bNftImpl The address of the deployed implement of the BNFT
   **/
  function createBNFTWithImpl(address nftAsset, address bNftImpl) external returns (address bNftProxy);

  /**
   * @dev Update bNFT proxy to an new deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the BNFT
   * @param bNftImpl The address of the deployed implement of the BNFT
   * @param encodedCallData The encoded function call.
   **/
  function upgradeBNFTWithImpl(
    address nftAsset,
    address bNftImpl,
    bytes memory encodedCallData
  ) external;

  function batchUpgradeBNFT(address[] calldata nftAssets) external;

  function batchUpgradeAllBNFT() external;

  /**
   * @dev Adding custom symbol for some special NFTs like CryptoPunks
   * @param nftAssets_ The addresses of the NFTs
   * @param symbols_ The custom symbols of the NFTs
   **/
  function addCustomeSymbols(address[] memory nftAssets_, string[] memory symbols_) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

interface IBNFT {
  /**
   * @dev Emitted when an bNFT is initialized
   * @param underlyingAsset_ The address of the underlying asset
   **/
  event Initialized(address indexed underlyingAsset_);

  /**
   * @dev Emitted when the ownership is transferred
   * @param oldOwner The address of the old owner
   * @param newOwner The address of the new owner
   **/
  event OwnershipTransferred(address oldOwner, address newOwner);

  /**
   * @dev Emitted when the claim admin is updated
   * @param oldAdmin The address of the old admin
   * @param newAdmin The address of the new admin
   **/
  event ClaimAdminUpdated(address oldAdmin, address newAdmin);

  /**
   * @dev Emitted on mint
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address receive the bNFT token
   **/
  event Mint(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on burn
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address of the burned bNFT token
   **/
  event Burn(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on flashLoan
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param nftAsset address of the underlying asset of NFT
   * @param tokenId The token id of the asset being flash borrowed
   **/
  event FlashLoan(address indexed target, address indexed initiator, address indexed nftAsset, uint256 tokenId);

  event ClaimERC20Airdrop(address indexed token, address indexed to, uint256 amount);

  event ClaimERC721Airdrop(address indexed token, address indexed to, uint256[] ids);

  event ClaimERC1155Airdrop(address indexed token, address indexed to, uint256[] ids, uint256[] amounts, bytes data);

  event ExecuteAirdrop(address indexed airdropContract);

  /**
   * @dev Initializes the bNFT
   * @param underlyingAsset_ The address of the underlying asset of this bNFT (E.g. PUNK for bPUNK)
   */
  function initialize(
    address underlyingAsset_,
    string calldata bNftName,
    string calldata bNftSymbol,
    address owner_,
    address claimAdmin_
  ) external;

  /**
   * @dev Mints bNFT token to the user address
   *
   * Requirements:
   *  - The caller can be contract address and EOA.
   *  - `nftTokenId` must not exist.
   *
   * @param to The owner address receive the bNFT token
   * @param tokenId token id of the underlying asset of NFT
   **/
  function mint(address to, uint256 tokenId) external;

  /**
   * @dev Burns user bNFT token
   *
   * Requirements:
   *  - The caller can be contract address and EOA.
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   **/
  function burn(uint256 tokenId) external;

  /**
   * @dev Allows smartcontracts to access the tokens within one transaction, as long as the tokens taken is returned.
   *
   * Requirements:
   *  - `nftTokenIds` must exist.
   *
   * @param receiverAddress The address of the contract receiving the tokens, implementing the IFlashLoanReceiver interface
   * @param nftTokenIds token ids of the underlying asset
   * @param params Variadic packed params to pass to the receiver as extra information
   */
  function flashLoan(
    address receiverAddress,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) external;

  function claimERC20Airdrop(
    address token,
    address to,
    uint256 amount
  ) external;

  function claimERC721Airdrop(
    address token,
    address to,
    uint256[] calldata ids
  ) external;

  function claimERC1155Airdrop(
    address token,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;

  function executeAirdrop(address airdropContract, bytes calldata airdropParams) external;

  /**
   * @dev Returns the owner of the `nftTokenId` token.
   *
   * Requirements:
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   */
  function minterOf(uint256 tokenId) external view returns (address);

  /**
   * @dev Returns the address of the underlying asset.
   */
  function underlyingAsset() external view returns (address);

  /**
   * @dev Returns the contract-level metadata.
   */
  function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.4;

/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Bend Governance
 * @author Bend
 **/
interface IAddressesProvider {
    function owner() external view returns (address);

    /// @notice nftOracle
    function nftOracle() external view returns (address);

    /// @notice reserveOracle
    function reserveOracle() external view returns (address);

    function userClaimRegistry() external view returns (address);

    function bnftRegistry() external view returns (address);

    function shopFactory() external view returns (address);

    function loanManager() external view returns (address);

    //tien phat toi thieu theo % reserve price (ex : vay eth, setup 2% => phat 1*2/100 = 0.02 eth, 1 la ty le giua dong vay voi ETH) khi redeem nft bi auction
    function minBidFine() external view returns (uint256);

    //tien phat toi thieu theo % khoan vay khi redeem nft bi auction ex: vay 10 ETH, setup 5% => phat 10*5/100=0.5 ETH
    function redeemFine() external view returns (uint256);

    //thoi gian co the redeem nft sau khi bi auction tinh = hour
    function redeemDuration() external view returns (uint256);

    function auctionDuration() external view returns (uint256);

    function liquidationThreshold() external view returns (uint256);

    //% giam gia khi thanh ly tai san
    function liquidationBonus() external view returns (uint256);

    function redeemThreshold() external view returns (uint256);

    function maxLoanDuration() external view returns (uint256);

    function platformFeeReceiver() external view returns (address);

    //platform fee tinh theo pricipal
    function platformFeePercentage() external view returns (uint256);

    function interestDuration() external view returns (uint256);
}