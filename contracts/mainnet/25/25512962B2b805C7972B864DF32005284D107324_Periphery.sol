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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
pragma solidity ^0.8.9;

interface IPriceGetter {
    /**
     * @notice this struct will be saved at {mapping(bytes32 => priceFeedData)}, where the name of each price feed will be represented as bytes32
     * @param priceFeedAddress :  the address of the chainlink AggregatorV3Interface instance for that pair
     * @param isEntity : made to check if a struct is initialized
     */
    struct priceFeedData {
        address priceFeedAddress;
        bool isEntity;
    }

    event addedPriceFeed(bytes32, address);
    event updatedPriceFeed(bytes32, address);
    event deletedPriceFeed(bytes32);

    /**
     * @notice add a new price oracle instance
     * @param _priceFeedName : the name of the price pair casted to bytes32 . For example : bytes32("AVAX/USD")
     * @param _priceOracleAddress : the address of the chainlink AggregatorV3Interface instance for that pair
     */

    function addPriceFeed(bytes32 _priceFeedName, address _priceOracleAddress) external returns (bool success);

    /// @notice updates an existing price feed
    function updatePriceFeed(bytes32 _priceFeedName, address _priceOracleAddress) external returns (bool success);

    /// @notice delete an existing price feed
    function deletePriceFeed(bytes32 _priceFeedName) external returns (bool success);

    /// @notice check if a price feed exists, necessat for the contract logic
    function isPriceFeedExists(bytes32 _priceFeedName) external view returns (bool);

    /// @notice returns the price of a pair with 8 decimals precision
    function getPrice(bytes32 _priceFeedName) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./main/IRadxuCFADistributions.sol";
import "./main/IRadxuCFAERC721Soulbound.sol";
import "./main/IRadxuCFAEvents.sol";
import "./main/IRadxuCFAFees.sol";
import "./main/IRadxuCFAUnits.sol";
import "./main/IRadxuCFASettings.sol";

/**
 * @notice RadxuCFA is the core contract of the CFA protocol . Learn more here : https://docs.radxu.org/
 */
interface IRadxuCFA is
    IRadxuCFADistributions,
    IRadxuCFAERC721Soulbound,
    IRadxuCFAEvents,
    IRadxuCFAFees,
    IRadxuCFAUnits,
    IRadxuCFASettings
{}

pragma solidity ^0.8.19;

interface IRadxuCFABase {
    /**
     * @notice packed CFA related data
     * @notice in case CFAs the user wont be able to claim any distributions
     * @param units : number of CFA units owner by the address
     * @param lastClaimTimestamp : last time user (claimed distributions)/(purchased CFA units)
     * @param operationalUntilTimestamp : timestamp when mantainance fees payed by user expire
     * @param isClaimAll : checks wether the last time {lastClaimTimestamp} was updated  because of adding tokens in {distributionStorage}, necessary for the contract logic
     * @param isEntity : address is a protocol user or not
     * @dev the struct has been purposely storage-optimized to take <=32 bytes of space == 1 slot
     * and reduce gas use when reading/writing to it
     */
    struct CFAInfo {
        // 4 bytes + 8 bytes + 8 bytes + 2 bytes + 2 bytes = 24 bytes
        uint32 units;
        uint64 lastClaimTimestamp;
        uint64 operationalUntilTimestamp;
        bool isClaimAll;
        bool isEntity;
    }
    /**
     * @notice struct containing specific metadata about ERC721 Soulbound token owners
     * @param isPredistribution : true for those who participed in CFA predistribution
     * @dev this will be used to dynamically generate a Base64 encoded custom uri for each token
     */

    struct NFTStorage {
        bool isPredistribution;
    }
}

pragma solidity ^0.8.19;

import "./IRadxuCFABase.sol";

interface IRadxuCFADistributions is IRadxuCFABase {
    /// @notice claim all distributions generated by all CFA units owned by {msg.sender}
    function claimAllDistributions() external returns (uint256 distribution);

    /// @notice function that uses the users distributions to create new units, without the need to claim and purchase again
    function compoundDistributions(uint256 _unitAmount) external;

    /// @notice get the accumulated distributions by a user
    /// @param lastClaimTimestamp : timestamp last time user purchased or claimed
    /// @param isClaimAll : true if {lastClaimTimestamp} was updated because of {claimAllDistributions}
    /// @param user : address of user

    function getCFADistribution(uint256 lastClaimTimestamp, bool isClaimAll, address user)
        external
        view
        returns (uint256 distribution, bool isPaid);
}

pragma solidity ^0.8.19;

import "./IRadxuCFABase.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IRadxuCFAERC721Soulbound is IRadxuCFABase, IERC721Metadata {
    /// @notice set the metadata uri(stored in IPFS) for both predistribution users' tokens and normal users's tokens
    function setTokenURI(string calldata predistURI, string calldata defaultURI) external;

    /// @notice overriden version of {ERC721UriStorage}'s tokenURI function
    /// @return dynamic base64 format uri
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

pragma solidity ^0.8.19;

interface IRadxuCFAEvents {
    event purchasedUnit(uint256 indexed);
    event createdUnits(uint256 indexed);
    event paidFees(uint256 indexed);
    event claimedAllDistributions(uint256 indexed);
    event compoundedDistributions(uint256 indexed);
    event issuedUnits(uint256 indexed);
    event removedUnits(uint256 indexed);
    event executedHalving();
}

pragma solidity ^0.8.19;

import "./IRadxuCFABase.sol";

interface IRadxuCFAFees is IRadxuCFABase {
    /// @notice admin can set the fees at any time
    function setFeeValue(uint32 _feeValue) external;

    /// @notice returns the latest index of the feeDiscounts mapped array
    function getFeeDiscountsLength() external view returns (uint256);

    function feeDiscounts(uint256 i) external view returns (uint8[2] memory);

    /// @notice admin sets fee discounts for users who purchase for the first time
    function setFeeDiscounts(uint8[2][] memory feeDiscountsData) external;

    /// @notice pay mantainance fees for all CFA units
    /// @param _months : the amount of months to pay in advance
    function payCFAFee(uint32 _months) external payable;

    /*  /**
     * @notice returns full information about a CFA user's fee payment state, given a amount of months willing to pay
     * @param _user : the address of the user
     * @param _months : mount of months willing to pay
     * @return totalUsdPayAmount : USD payment quantity without discounts
     * @return totalDiscountedMonthsPackUsdPayAmount : USD payment quantity with possible discounts applied
     * @return totalAvaxPayAmount : {totalUsdPayAmount} but value in AVAX
     * @return totalDiscountedMonthsPackAvaxPayAmount : {totalDiscountedMonthsPackUsdPayAmount} but value in AVAX
     * @return maxAmountMonths : the max amount months that can be paid in advance given the units user owns
     * @return ownershipUnitPercentage : to percentage of the total unit amount owned by the user
     * @return existingPaidMonths : the fee months already paid by the user
     * @return newAvailableMonths : {maxAmountMonths} - {existingPaidMonths} = the max amount months that can be paid in advance given
      the units user owns substracting the fee months already paid by the user
     * @return totalPaymentMonths : {_months} * {units of _user} = total quantity of months the user would be paying
     */
    function getCFAPayFeeData(address _user, uint32 _months)
        external
        view
        returns (
            uint256 totalUsdPayAmount,
            uint256 totalDiscountedMonthsPackUsdPayAmount,
            uint256 totalAdditionalUnPaidFee,
            uint256 totalDiscountedMonthsPackAvaxPayAmount,
            uint8 maxAmountMonths,
            uint8 existingPaidMonths,
            uint8 newAvailableMonths,
            uint32 totalPaymentMonths
        );
}

pragma solidity ^0.8.19;

interface IRadxuCFASettings {
    /// @return minimum time needed from last claim to claim having that the needed fees have been paid
    function CFAClaimLimit() external view returns (uint256);

    /// @return the number of fee months user can pay in advance depending on the number of owned units
    function CFAFeeMonthPack() external view returns (uint256);

    /// @return the distribution per day/unit of the CFAs : 0.1 AVAX by default
    function unitDistribution() external view returns (uint256);

    /// @return the cost of mantaining CFA units monthly
    function unitCost() external view returns (uint256);

    /// @return a fixed number of units, necessary for the halving logic, it will increase over time
    function unitActiveCap() external view returns (uint256);

    /// @return the monthly fee to mantain CFA units active
    function unitUsdMonthlyFee() external view returns (uint256);

    /// @return the number of CFA units needed to achieve next halving
    function halvingUnitAmount() external view returns (uint256);

    /// @return the amount of halvings performed
    function halvingCounter() external view returns (uint256);

    /// @return the address of the treasuty contract
    function treasuryAddress() external view returns (address payable);
}

pragma solidity ^0.8.19;

import "./IRadxuCFABase.sol";

interface IRadxuCFAUnits is IRadxuCFABase {
    function getTotalUnitInfo() external view returns (uint256 totalActive, uint256 totalInactive);

    /// @return the {CFAInfo} of user @param account
    function CFAs(address account) external view returns (CFAInfo memory);

    /**
     * @notice purchase CFA units
     * @param _amount : the amount of units to buy
     * @notice : If first time buying a soulbound token is minted to the users
     */
    function purchaseUnit(uint256 _amount) external;

    /// @notice : add units to a certain user(Admin function)
    function addUnitsToAddress(address _userAddress, uint256 _unitAmount) external;

    /// @notice : remove from a certain user(Admin function)
    function removeUnitsFromAddress(address _userAddress, uint256 _unitAmount) external;

    function getTotalUsers() external view returns (uint256 totalUsers);
}

pragma solidity ^0.8.19;

import "../interfaces/IPriceGetter.sol";
import "../interfaces/IRadxuCFA.sol";
import "../TraderJoe/interfaces/IJoePair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Decimals is IERC20 {
    function decimals() external view returns (uint8);
}

contract Periphery {
    uint256 public constant AVAX_DECIMALS = 18;
    uint256 public immutable USDC_DECIMALS;
    IRadxuCFA public immutable cfaProxy;
    IPriceGetter public immutable oracle;
    address public immutable treasury;
    address public immutable philantrophy;
    address public immutable radx;
    IERC20Decimals public immutable usdc;
    IJoePair public immutable radxWavaxPair;

    constructor(
        address _IRadxuCFA,
        address _IPriceGetter,
        address _treasury,
        address _philantrophy,
        address _usdc,
        address _radx,
        address _radxWavaxPair
    ) {
        cfaProxy = IRadxuCFA(_IRadxuCFA);
        oracle = IPriceGetter(_IPriceGetter);
        treasury = _treasury;
        philantrophy = _philantrophy;
        usdc = IERC20Decimals(_usdc);
        USDC_DECIMALS = usdc.decimals();
        radx = _radx;
        radxWavaxPair = IJoePair(_radxWavaxPair);
    }

    function getCFASpecs()
        public
        view
        returns (
            uint256 unitCost,
            uint256 unitDistribution,
            uint256 unitUsdMonthlyFee,
            uint256 unitActiveCap
        )
    {
        unitCost = cfaProxy.unitCost();
        unitDistribution = cfaProxy.unitDistribution();
        unitUsdMonthlyFee = cfaProxy.unitUsdMonthlyFee();
        unitActiveCap = cfaProxy.unitActiveCap();
    }

    function getTreasuryAndPhilantrophyBalanceInUSD()
        public
        view
        returns (uint256 treasuryBalance, uint256 philantrophyBalance)
    {
        treasuryBalance = _getTreasuryBalanceInUSD();
        philantrophyBalance = _getPhilantrophyBalanceInUSD();
    }

    function _getTreasuryBalanceInUSD() private view returns (uint256) {
        uint256 avaxBalance = treasury.balance;
        uint256 usdcBalance = usdc.balanceOf(treasury) *
            (10**(18 - AVAX_DECIMALS));

        uint256 avaxBalanceUSD = (avaxBalance * oracle.getPrice("AVAX/USD")) /
            (10**8);
        return avaxBalanceUSD + usdcBalance;
    }

    function _getPhilantrophyBalanceInUSD() private view returns (uint256) {
        uint256 avaxBalance = philantrophy.balance;
        uint256 usdcBalance = usdc.balanceOf(philantrophy) *
            (10**(18 - AVAX_DECIMALS));
        uint256 avaxBalanceUSD = (avaxBalance * oracle.getPrice("AVAX/USD")) /
            (10**8);
        return avaxBalanceUSD + usdcBalance;
    }

    function getAvaxPrice() public view returns (uint256 price) {
        return oracle.getPrice("AVAX/USD") * 10**10;
    }

    function getRadxPrice() public view returns (uint256 price) {
        (uint112 r0, uint112 r1, ) = radxWavaxPair.getReserves();
        uint256 quote;
        if (radxWavaxPair.token0() == radx) {
            quote = getAmountOut(1e18, r0, r1);
        } else {
            quote = getAmountOut(1e18, r1, r0);
        }
        price = (quote * oracle.getPrice("AVAX/USD")) / (10**8);
    }

    // credit : JoeLibrary from TraderJoe
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) private pure returns (uint256 amountOut) {
        require(amountIn > 0, "PERIPHERY : INSUFFICIENT_INPUT_AMOUNT");
        require(
            reserveIn > 0 && reserveOut > 0,
            "PERIPHERY : INSUFFICIENT_LIQUIDITY"
        );
        uint256 amountInWithFee = amountIn * 1000; // noo fees included
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        amountOut = numerator / denominator;
    }

    function getGeneralUnitInfo()
        public
        view
        returns (
            uint256 totalActive,
            uint256 totalInactive,
            uint256 total,
            uint256 halvingUnitAmount
        )
    {
        uint256 l = cfaProxy.getTotalUsers();
        uint256 unitActiveCap = cfaProxy.unitActiveCap();
        for (uint256 i = 1; i <= l; ) {
            uint256 userUnits = cfaProxy.CFAs(cfaProxy.ownerOf(i)).units;
            if (userUnits > unitActiveCap) {
                totalActive += unitActiveCap;
                totalInactive += userUnits - unitActiveCap;
            } else {
                totalActive += userUnits;
            }
            unchecked {
                ++i;
            }
        }
        total = totalActive + totalInactive;
        halvingUnitAmount = cfaProxy.halvingUnitAmount();
    }

    function calcDistributions(address user)
        external
        view
        returns (uint256 distributions, bool isPaid)
    {
        IRadxuCFA.CFAInfo memory info = cfaProxy.CFAs(user);
        (distributions, isPaid) = cfaProxy.getCFADistribution(
            info.lastClaimTimestamp,
            info.isClaimAll,
            user
        );
    }

    function getCFADataFromUser(address user)
        public
        view
        returns (
            uint256 distributions,
            uint256 totalUnits,
            uint256 activeUnits,
            uint256 inactiveUnits,
            bool isPaid,
            uint256 operationalUntilTimestamp,
            uint256 lastClaimTimestamp,
            bool isClaimable
        )
    {
        uint256 cap = cfaProxy.unitActiveCap();
        IRadxuCFA.CFAInfo memory userInfo = cfaProxy.CFAs(user);
        totalUnits = userInfo.units;
        activeUnits = totalUnits < cap ? totalUnits : cap;
        inactiveUnits = totalUnits <= cap ? 0 : totalUnits - cap;
        operationalUntilTimestamp = userInfo.operationalUntilTimestamp;
        lastClaimTimestamp = userInfo.lastClaimTimestamp;
        (distributions, isPaid) = cfaProxy.getCFADistribution(
            lastClaimTimestamp,
            userInfo.isClaimAll,
            user
        );
        isClaimable = _isClaimable(
            isPaid,
            userInfo.isClaimAll,
            userInfo.lastClaimTimestamp + cfaProxy.CFAClaimLimit()
        );
    }

    function getPayFeeDataFromUser(address user, uint32 months)
        public
        view
        returns (
            uint256 totalUsdPayAmount,
            uint256 totalDiscountedMonthsPackUsdPayAmount,
            uint256 totalDiscountedMonthsPackAvaxPayAmount,
            uint32 totalPaymentMonths
        )
    {
        (
            totalUsdPayAmount,
            totalDiscountedMonthsPackUsdPayAmount,
            ,
            totalDiscountedMonthsPackAvaxPayAmount,
            ,
            ,
            ,
            totalPaymentMonths
        ) = cfaProxy.getCFAPayFeeData(user, months);
    }

    function getFeeDataFromUser(address user)
        public
        view
        returns (
            uint256 totalAdditionalUnPaidFee,
            uint8 maxAmountMonths,
            uint8 existingPaidMonths,
            uint8 newAvailableMonths
        )
    {
        (
            ,
            ,
            totalAdditionalUnPaidFee,
            ,
            maxAmountMonths,
            existingPaidMonths,
            newAvailableMonths,

        ) = cfaProxy.getCFAPayFeeData(user, 0);
    }

    function getFeeDiscounts() public view returns (uint8[2][] memory) {
        uint256 l = cfaProxy.getFeeDiscountsLength();
        uint8[2][] memory discounts = new uint8[2][](l);
        for (uint256 i = 0; i < l; ) {
            discounts[i] = cfaProxy.feeDiscounts(i);
            unchecked {
                ++i;
            }
        }
        return discounts;
    }

    function _isClaimable(
        bool _isPaid,
        bool _isClaimAll,
        uint256 _time
    ) private view returns (bool) {
        if (!_isPaid) return false;
        if (_isClaimAll && block.timestamp < _time) {
            return false;
        }
        return true;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}