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
library Counters {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import {LibDiamond} from "hardhat-deploy/solc_0.8/diamond/libraries/LibDiamond.sol";
import "./Storage.sol";
/**
 * @title  BaseFacet
 * @author Decentralized Foundation Team
 * @notice BaseFacet is a base contract all facets to inherit, includes cross-facet utils and  common reusable functions for DEFO Diamond
 */
contract BaseFacet is Storage {

    /* ====================== Modifiers ====================== */

    modifier exists(uint256 _tokenId) {
        _requireExists(_tokenId);
        _;
    }

    modifier onlyGemHolder(uint256 _tokenId) {
        require(s.nft.owners[_tokenId] == _msgSender(), "You don't own this gem");
        _;
    }

    modifier onlyOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }
    modifier nonZeroAddress(address _owner) {
        require(_owner != address(0), "ERC721: address zero is not a valid owner");
        _;
    }

    /* ============ Internal Functions ============ */

    function _msgSender() internal override view returns (address sender_) {
        if (Context._msgSender() == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
            // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender_ := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender_ = msg.sender;
        }
    }

    function _getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function _requireExists(uint256 _tokenId) internal view {
        require(_exists(_tokenId), "ERC721: tokenId is not valid");
    }

    function _exists(uint256 _tokenId) internal view returns (bool) {
        return (s.nft.owners[_tokenId] != address(0));
    }

    ///todo ensure passing memory array here to the public functions is pretty optimal
    function _getGemIds(address _user) internal view returns (uint256[] memory) {
        uint256 numberOfGems = s.nft.balances[_user];
        uint256[] memory gemIds = new uint256[](numberOfGems);
        for (uint256 i = 0; i < numberOfGems; i++) {
            uint256 gemId = s.nft.ownedTokens[_user][i];
            require(_exists(gemId), "A gem doesn't exists");
            gemIds[i] = gemId;
        }
        return gemIds;
    }

    function _getAllUsers() internal view returns (address[] memory users_) {
        users_ = new address[](s.nft.allTokens.length);
        for (uint256 tokenId = 0; tokenId < s.nft.allTokens.length; tokenId++) {
            users_[tokenId] = s.nft.owners[tokenId];
        }
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/utils/Context.sol";
import {AppStorage} from "../libraries/LibAppStorage.sol";

contract Storage is Context {
    AppStorage internal s;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
/**
*   @dev The only source for all the data structures used in the protocol storage
*   @dev This includes general config, gem type config, and mutable data
*/

/// @dev number of payment tokens to enumerate the error, initially it's Defo and Dai,
/// @dev see PaymentTokens enum
uint256 constant PAYMENT_TOKENS = 2;

/// @dev number of income recievers on yield gem mint
uint256 constant PAYMENT_RECEIVERS = 3;

/// @dev total wallets on the protocol, see Wallets enum
uint256 constant WALLETS = 7;

/// @dev total number of supported tax tiers
uint256 constant TAX_TIERS = 5;

/**
*   @notice a struct for data compliance with erc721 standard
*   @param name Token name
*   @param symbol Token symbol
*   @param owners Mapping from token ID to owner address
*   @param balances Mapping owner address to token count
*   @param tokenApprovals Mapping from token ID to approved address
*   @param operatorApprovals Mapping from owner to operator approvals
*   @param ownedTokens Mapping from owner to list of owned token IDs
*   @param ownedTokensIndex Mapping from token ID to index of the owner tokens list
*   @param allTokens Array with all token ids, used for enumeration
*   @param allTokensIndex Mapping from token id to position in the allTokens array
*/
    struct ERC721Storage {
        string name;
        string symbol;
        Counters.Counter tokenIdTracker;
        mapping(uint256 => address) owners;
        mapping(address => uint256) balances;
        mapping(uint256 => address) tokenApprovals;
        mapping(address => mapping(address => bool)) operatorApprovals;
        string baseURI;
        mapping(address => mapping(uint256 => uint256)) ownedTokens;
        mapping(uint256 => uint256) ownedTokensIndex;
        uint256[] allTokens;
        mapping(uint256 => uint256) allTokensIndex;
        bool init;
    }


/// @notice token enum to index arrays of rates and addresses, the convention is that Dai is at place 0, Defo is at 1
/// @dev the order is extremely important once deployed
    enum PaymentTokens {
        Dai,
        Defo
    }

/// @notice protocol wallets for easy enumeration,
/// @dev the order is extremely important once deployed, see configuration scripts
    enum Wallets {
        Treasury,
        RewardPool,
        LiquidityPair,
        Team,
        Charity,
        Vault,
        RedeemContract
    }


/// @notice these tiers correspond to the configurable percentage from the diamond storage
    enum TaxTiers {
        Tier0NoPayment,
        Tier1HugeTax,
        Tier2MediumTax,
        Tier3SmallTax,
        Tier4NoTax
    }

/**
 * @notice DefoTokenLimitConfig DEFO ERC20 Token transfer limiter, this is for the 1000 DEFO per 24h sale limitation, can be changes with setTransferLimit
 * @param saleLimitPeriod initially 1 day
 * @param saleLimitAmount initially 1000 tokens
*/
    struct DefoTokenLimitConfig {
        uint256 saleLimitPeriod;
        uint256 saleLimitAmount;
        bool limitByReward;
    }

/**
 * @notice Main Protocol Configuration structure
     * @param mintLock no mint for all gems, no minting if set
     * @param transferLock no transfer if set, including no minting
     * @param incomeDistributionOnMint distribution of the payment among tokens in percent rates, all values use percentage multiplier (see percent helper), here addresses are from the Addresses
     * @param maintenancePeriod a period in seconds for maintenance fee accrual, initially one month
     * @param rewardPeriod a period in seconds for generating yield gem rewards, initially one week
     * @param mintCountResetPeriod a period in seconds to wait until last mint to reset mint count for a gem type, initially 12 hrs.
     * @param taxScaleSinceLastClaimPeriod a period in seconds for a tax scale to work out, initially one week
     * @param taxRates tax rates in percent (with percent multiplier, see percent helper contract), initially 30%, 30%, 15%, 0
     * @param charityContributionRate charity rate (w multiplier as all percent values in the project), initially 5%
     * @param vaultWithdrawalRate fee paid to withdraw amount from the vault back to the earned rewards, initially 10%
     * @param taperRate taper rate, initially 20%
     * @param mintLock no mint for all gems, no minting if set
     * @param transferLock no transfer if set
     * @param mintLimitWindow a period in seconds to wait until last mint to reset mint count for a gem type, initially 12 hrs, see GemTypeConfig.maxMintsPerLimitWindow
     */

    struct ProtocolConfig {
        IERC20[PAYMENT_TOKENS] paymentTokens;
        address[WALLETS] wallets;
        uint256[PAYMENT_RECEIVERS][PAYMENT_TOKENS] incomeDistributionOnMint;
        // time periods
        uint32 maintenancePeriod;
        uint32 rewardPeriod;
        uint32 taxScaleSinceLastClaimPeriod;
        // taxes and contributions
        uint256[TAX_TIERS] taxRates;
        uint256 charityContributionRate;
        uint256 vaultWithdrawalTaxRate;
        uint256 taperRate;
        // locks
        bool mintLock;
        bool transferLock;
        // mint limit period for coutner reset
        uint32 mintLimitWindow;
        DefoTokenLimitConfig defoTokenLimitConfig;
    }

/**
 * @notice A struct containing configuration details for gemType
     * @param maintenanceFee Maintenance fee in Dai for the node type, amount in wei per month
     * @param rewardAmountDefo Reward in DEFO for the node type, amount in wei per week
     * @param price Price in DEFO and DAI (in wei), respectively, according to the PaymentTokens enum
     * @param taperRewardsThresholdDefo Taper threshold, in wei, decreasing rate every given amount of rewards in DEFO
     * @param maxMintsPerLimitWindow number of gems, mint limit for a node type, see ProtocolConfig.mintLimitWindow
     */
    struct GemTypeConfig {
        uint256 maintenanceFeeDai;
        uint256 rewardAmountDefo;
        uint256[PAYMENT_TOKENS] price;
        uint256 taperRewardsThresholdDefo;
        uint8 maxMintsPerLimitWindow;
    }

/**
 * @notice A struct containing current mutable status for gemType
     * @param mintCount counter incrementing by one on every mint, during mintCountResetPeriod; after mintCountResetPeriod with no mints, reset to 0
     * @param endOfMintLimitWindow a moment to reset the mintCount counter to zero, set the new endOfMintLimitWindow and start over
     */
    struct GemTypeMintWindow {
        uint256 mintCount;
        uint32 endOfMintLimitWindow;
    }

/**
 * @notice A struct describing current DEFO Token limiter input
 * @param tokensSold DEFO tokens sold per limit window, "sold" = "transferred to liquidity pair except the mint"
 * @param timeOfLastSale time of last sale
     */
    struct DEFOTokenLimitWindow {
        mapping(address => uint256) tokensSold;
        mapping(address => uint256) timeOfLastSale;
    }

    enum Booster {
        None,
        Delta,
        Omega
    }

/**
 * @notice A struct describing financial state, provides the complete state for user, gem, or protocol total.
 * @notice It gives the current exact balance of the Vault, Rewards, and Charity.
 * @param claimedGross rewards amount previously claimed for all time, gross amount - before tax and charity
 * @param claimedNet rewards claimed and to user, net amount after tax and charity
 * @param stakedGross amount removed from rewards to stake, charity not yet deducted
 * @param stakedNet amount put to the vault - charity has been deducted
 * @param unStakedGross  amount removed from the vault, pre withdraw tax and charity
 * @param unStakedGrossUpped  amount removed from the vault gross-upped with charity to equal to the stakedGross amount
 * @param unStakedNet  amount returned to the earned rewards, post withdraw tax and charity
 * @param donated sent to charity
 * @param claimTaxPaid claim tax deducted - 30%, 15%, 15%
 * @param vaultTaxPaid vault withdrawal tax deducted
     */
    struct Fi {
        uint256 claimedGross;
        uint256 claimedNet;
        uint256 stakedGross;
        uint256 stakedNet;
        uint256 unStakedGross;
        uint256 unStakedGrossUp;
        uint256 unStakedNet;
        uint256 donated;
        uint256 claimTaxPaid;
        uint256 vaultTaxPaid;
    }

/**
 * @notice current state of a gem, a gem is an instance with consistent yield and fee rates specified by the pair (gemType, booster)
 * @param gemType node type, initially it's  0 -> Ruby , 1 -> Sapphire, 2 -> Diamond, and boosters
 * @param booster node Booster 0 -> None , 1 -> Delta , 2 -> Omega
 * @param mintTime timestamp of the mint time
 * @param lastRewardWithdrawalTime timestamp of last reward claim OR stake. Same as mintTime if not yet claimed.
 * @param lastMaintenanceTime timestamp of the last maintenance (could be a date in the future in case of the upfront payment)
*/
    struct Gem {
        uint8 gemTypeId;
        Booster booster;
        uint32 mintTime;
        uint32 lastRewardWithdrawalTime;
        uint32 lastMaintenanceTime;
        Fi fi;
    }

/**
*   @notice Main Contract Storage utilizing App Storage pattern for Diamond Proxy data organization
*   @param config main configuration, basically everything except gemType specific
*   @param gemTypes supported gem types with their details, gemTypeId is the index of the array
*   @param gems mapping indexed by tokenId, where tokenId is in the nft.allTokens
*   @param gemTypesMintWindows windows for limiting yield gem mints per gem type
*   @param defoTokenLimitWindow window for limiting DEFO Token sale
*   @param nft ERC721 standard related storage
*   @param total cumulated amounts for all operations
*   @param usersFi financial info per each user
*/
    struct AppStorage {
        // configuration
        ProtocolConfig config;
        GemTypeConfig[] gemTypes;
        // current state
        GemTypeMintWindow[] gemTypesMintWindows;
        DEFOTokenLimitWindow defoTokenLimitWindow;
        mapping(uint256 => Gem) gems;
        ERC721Storage nft;
        // Cumulations
        Fi total;
        // User data, users list is s.nft.owners, size s.nft.allTokens.length (managed by ERC721Enumerable)
        mapping(address => Fi) usersFi;
        mapping(address => uint8) usersNextGemTypeToBoost;
        mapping(address => Booster) usersNextGemBooster;
    }

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "../interfaces/IConfig.sol";
import "../base-facet/BaseFacet.sol";
import "../libraries/LibAppStorage.sol";
import "../libraries/LibPauser.sol";
import "../libraries/LibMintLimiter.sol";
import "../libraries/PercentHelper.sol";

/** @title  ERC721Facet EIP-2535 Diamond Facet
  * @author Decentralized Foundation Team
  * @notice The Contract uses diamond storage providing functionality of ERC721, ERC721Enumerable, ERC721Burnable, ERC721Pausable
*/
contract ConfigFacet is BaseFacet, IConfig {

    /* ============ External and Public Functions ============ */

    function setConfig(ProtocolConfig calldata _config) external onlyOwner {
        ProtocolConfig memory calldataToStorage = _config;
        s.config = calldataToStorage;
        emit ConfigurationChange(_config);
    }

    function setGemTypesConfig(GemTypeConfig[] calldata _gemTypeConfig) external onlyOwner {
        // fill in the storage and reset mint limit window counter for every gem type
        delete s.gemTypes;
        delete s.gemTypesMintWindows;
        for (uint gemTypeId = 0; gemTypeId < _gemTypeConfig.length; gemTypeId++) {
            GemTypeConfig memory cur = _gemTypeConfig[gemTypeId];
            s.gemTypes.push(cur);
            GemTypeMintWindow memory initWindow = GemTypeMintWindow(0, uint32(block.timestamp));
            s.gemTypesMintWindows.push(initWindow);
        }
    }

    function setConfigWallets(address[WALLETS] memory _wallets) external onlyOwner {
        s.config.wallets = _wallets;
    }

    function setConfigIncomeDistributionOnMint(uint256[PAYMENT_RECEIVERS][PAYMENT_TOKENS] memory _incomeDistributionOnMint) external onlyOwner {
        s.config.incomeDistributionOnMint = _incomeDistributionOnMint;
    }

    function setConfigMaintenancePeriod(uint32 _maintenancePeriod) external onlyOwner {
        s.config.maintenancePeriod = _maintenancePeriod;
    }

    function setConfigRewardPeriod(uint32 _rewardPeriod) external onlyOwner {
        s.config.rewardPeriod = _rewardPeriod;
    }

    function setConfigTaxScaleSinceLastClaimPeriod(uint32 _taxScaleSinceLastClaimPeriod) external onlyOwner {
        s.config.taxScaleSinceLastClaimPeriod = _taxScaleSinceLastClaimPeriod;
    }

    function setConfigTaxRates(uint256[TAX_TIERS] memory _taxRates) external onlyOwner {
        s.config.taxRates = _taxRates;
    }

    function setCharityContributionRate(uint256 _charityContributionRate) external onlyOwner {
        s.config.charityContributionRate = _charityContributionRate;
    }

    function setConfigVaultWithdrawalTaxRate(uint256 _vaultWithdrawalTaxRate) external onlyOwner {
        s.config.vaultWithdrawalTaxRate = _vaultWithdrawalTaxRate;
    }

    function setConfigTaperRate(uint256 _taperRate) external onlyOwner {
        s.config.taperRate = _taperRate;
    }

    function setConfigMintLimitWindow(uint32 _mintLimitWindow) external onlyOwner {
        s.config.mintLimitWindow = _mintLimitWindow;
    }

    function setConfigDefoTokenLimitConfig(DefoTokenLimitConfig calldata _defoTokenLimitConfig) external onlyOwner {
        DefoTokenLimitConfig memory temp = _defoTokenLimitConfig;
        s.config.defoTokenLimitConfig = temp;
    }

    function lockMint() public onlyOwner {
        LibMintLimiter.lockMint();
    }

    function unlockMint() public onlyOwner {
        LibMintLimiter.unlockMint();
    }

    function pause() external onlyOwner {
        LibPauser._pause();
    }

    function unpause() external onlyOwner {
        LibPauser._unpause();
    }


    function getConfig() external view returns (ProtocolConfig memory) {
        return s.config;
    }

    function getGemTypesConfig() external view returns (GemTypeConfig[] memory) {
        return s.gemTypes;
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "../data-types/IDataTypes.sol";


/** @title  IConfig EIP-2535 Diamond Facet
  * @author Decentralized Foundation Team
  * @notice The Yield Gem Configuration, setters and getters
*/
interface IConfig {
    event ConfigurationChange(ProtocolConfig config);
    event GemTypeConfigurationChange(GemTypeConfig _gemTypeConfig);

    function setConfig(ProtocolConfig calldata _config) external;

    function getConfig() external view returns (ProtocolConfig memory);

    function setGemTypesConfig(GemTypeConfig[] calldata _gemTypesConfig) external;

    function getGemTypesConfig() external view returns (GemTypeConfig[] memory);

    function lockMint() external;

    function unlockMint() external;

    function pause() external;

    function unpause() external;

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "../data-types/IDataTypes.sol";

/** @title  LibAppStorage EIP-2535 Diamond Facet Storage
  * @author Decentralized Foundation Team
  * @notice This diamond storage library is inherited by all facets and imported in libraries
*/
library LibAppStorage {
    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "./LibAppStorage.sol";

// helper for limit daily mints
library LibMintLimiter {
    event MintLocked();
    event MintUnlocked();

    /**
    *   @notice checks if a gem is mintable
    *   @param _gemTypeId type of a gem, initially it's 0,1,2 for sapphire, ruby, and diamond, respectively
    *   @return true if mint is available, no revert
    *   @dev checks mintLock config and daily mintcount limit
    */
    function isMintAvailableForGem(uint8 _gemTypeId) internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        GemTypeConfig memory gemType = s.gemTypes[_gemTypeId];
        GemTypeMintWindow memory gemTypeMintWindow = s.gemTypesMintWindows[_gemTypeId];

        return !(s.config.mintLock) &&
        //checking if the limit in the current mint window has not been reached yet
        (((gemTypeMintWindow.mintCount < gemType.maxMintsPerLimitWindow) &&
        (block.timestamp <= gemTypeMintWindow.endOfMintLimitWindow)) ||
        //or we're already in another window ahead
        (block.timestamp > gemTypeMintWindow.endOfMintLimitWindow));
    }

    function updateMintCount(uint8 _gemTypeId) internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        GemTypeMintWindow storage windowStorage = s.gemTypesMintWindows[_gemTypeId];
        if (block.timestamp > windowStorage.endOfMintLimitWindow) {
            //setting up new mint window
            do {
                windowStorage.endOfMintLimitWindow += s.config.mintLimitWindow;
            }
            while (block.timestamp > windowStorage.endOfMintLimitWindow);
            windowStorage.mintCount = 0;
        }
        windowStorage.mintCount++;
    }

    function getCurrentMintWindow(uint8 _gemTypeId) internal view returns (GemTypeMintWindow memory) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        GemTypeMintWindow memory window = s.gemTypesMintWindows[_gemTypeId];
        if (block.timestamp > window.endOfMintLimitWindow) {
            //setting up new mint window
            do {
                window.endOfMintLimitWindow += s.config.mintLimitWindow;
            }
            while (block.timestamp > window.endOfMintLimitWindow);
            window.mintCount = 0;
        }
        return window;
    }


    function lockMint() internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.config.mintLock = true;
        emit MintLocked();
    }

    function unlockMint() internal {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.config.mintLock = false;
        emit MintUnlocked();
    }


}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.15;

import "./LibAppStorage.sol";

/**
*   @notice Pausable contract
*   @dev should start with  s.config.transferLock = false which is default
*/

library LibPauser {
    event Paused(address account);
    event Unpaused(address account);

    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    modifier whenPaused() {
        _requirePaused();
        _;
    }

    function _paused() internal view returns (bool) {
        AppStorage storage s = LibAppStorage.diamondStorage();
        return s.config.transferLock;
    }

    function _requireNotPaused() internal view {
        require(!_paused(), "Pausable: paused, transfer is locked");
    }

    function _requirePaused() internal view {
        require(_paused(), "Pausable: not paused");
    }

    function _pause() internal whenNotPaused {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.config.transferLock = true;
        emit Paused(msg.sender);
    }

    function _unpause() internal whenPaused {
        AppStorage storage s = LibAppStorage.diamondStorage();
        s.config.transferLock = false;
        emit Unpaused(msg.sender);
    }


}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "./LibAppStorage.sol";


/**
 * @notice Library for percentage integer math, note PERCENTAGE_PRECISION_MULTIPLIER when configuring the protocol
 * @author Decentralized Foundation Team
 * @dev PERCENTAGE_PRECISION_MULTIPLIER*100 = 10000 greater than real percent, so 20% is represented as 2000, meaning 0.2
 */

library PercentHelper {
    uint256 constant PERCENTAGE_PRECISION_MULTIPLIER = 100;
    uint256 constant HUNDRED_PERCENT = 100 * PERCENTAGE_PRECISION_MULTIPLIER;

    /**
     * @dev simply a ratio of the given value, e.g. if tax is 30% and value if 100 the function gives 30
     * @param value Value to get ratio from
     * @param tax Percent to apply
     */
    ///todo make pure once got rid of the console.log
    function rate(uint256 value, uint256 tax) internal pure returns (uint256) {
        return tax > 0 ? (value * tax) / HUNDRED_PERCENT : 0;
    }

    /**
    * @dev simple gross-up, gives back gross for net value, if charity is 5%, then gross up of 95 gives 100
     * @param netValue Net value to gross up
     * @param tax Percent that was applied
     */
    function grossUp(uint256 netValue, uint256 tax) internal pure returns (uint256) {
        return tax > 0 ? (netValue * HUNDRED_PERCENT) / (HUNDRED_PERCENT - tax) : 0;
    }


    /// @dev received inverted percent for taper calc, if ratio is 20%, then 1/(1-20%) = 25%
    function invertedRate(uint256 value, uint256 ratio) internal pure returns (uint256) {
        return value * HUNDRED_PERCENT / (HUNDRED_PERCENT - ratio);
    }

    function oneHundredLessPercent(uint256 ratio) internal pure returns (uint256) {
        return (HUNDRED_PERCENT - ratio);
    }

    function minusHundredPercent(uint256 ratio) internal pure returns (uint256) {
        return (ratio - HUNDRED_PERCENT);
    }


    function reversePercent(uint256 ratio) internal pure returns (uint256) {
        return PERCENTAGE_PRECISION_MULTIPLIER / ratio;
    }

    function percentPower(uint256 value, uint256 ratio, uint pow) internal pure returns (uint256) {
        return value * PERCENTAGE_PRECISION_MULTIPLIER ** pow / ratio ** pow;
    }


    /// @dev simply value less given percentage, e.g. if tax is 30% the functio gives 70 for 100
    function lessRate(uint256 value, uint256 tax) internal pure returns (uint256) {
        return value - rate(value, tax);
    }

    function plusRate(uint256 value, uint256 tax) internal pure returns (uint256) {
        return value + rate(value, tax);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

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

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
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
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}