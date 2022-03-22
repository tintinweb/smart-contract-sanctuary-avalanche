/**
 *Submitted for verification at snowtrace.io on 2022-03-22
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0
pragma solidity >= 0.8.4 < 0.9.0;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

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

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}



/** 
 *  SourceUnit: /Users/pedromaia/projects/subgenix/contracts/VaultFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /Users/pedromaia/projects/subgenix/contracts/VaultFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: AGPL-3.0-only
pragma solidity >= 0.8.4 < 0.9.0;

interface IgSGX {
    function deposit(address to, uint256 amount) external;

    function withdraw(uint256 share) external;
}



/** 
 *  SourceUnit: /Users/pedromaia/projects/subgenix/contracts/VaultFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: AGPL-3.0-only
pragma solidity >= 0.8.4 < 0.9.0;

interface ILockupHell {
    
    function lockupRewards(
        address user, 
        uint256 shortLockupRewards, 
        uint256 longLockupRewards
    ) external;

    function claimShortLokcup(address user, uint32 index) external;

    function claimLongLockup(address user, uint32 index) external;

    function getShortLockupTime() external view returns(uint32);

    function getLongLockupTime() external view returns(uint32);

    function getShortPercentage() external view returns(uint256);
 
    function getLongPercentage() external view returns(uint256);
}



/** 
 *  SourceUnit: /Users/pedromaia/projects/subgenix/contracts/VaultFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0
pragma solidity >= 0.8.4 < 0.9.0;

////import {IJoeRouter01} from "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}



/** 
 *  SourceUnit: /Users/pedromaia/projects/subgenix/contracts/VaultFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity >= 0.8.4 < 0.9.0;

/**
 * @dev Interface of the ERC20 standard with mint and burn functions.
 */
interface IERC20Mintable {
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function mint(address to, uint256 amount) external;
    
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
    function burn(address from, uint256 amount) external;


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



/** 
 *  SourceUnit: /Users/pedromaia/projects/subgenix/contracts/VaultFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




/** 
 *  SourceUnit: /Users/pedromaia/projects/subgenix/contracts/VaultFactory.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private reentrancyStatus = 1;

    modifier nonReentrant() {
        require(reentrancyStatus == 1, "REENTRANCY");

        reentrancyStatus = 2;

        _;

        reentrancyStatus = 1;
    }
}


/** 
 *  SourceUnit: /Users/pedromaia/projects/subgenix/contracts/VaultFactory.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: AGPL-3.0-only
pragma solidity >= 0.8.4 < 0.9.0;

////import {ReentrancyGuard} from "@rari-capital/solmate/src/utils/ReentrancyGuard.sol";
////import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
////import {IERC20Mintable} from "./interfaces/IERC20Mintable.sol";
////import {IJoeRouter02} from "./interfaces/IJoeRouter02.sol";
////import {ILockupHell} from "./interfaces/ILockupHell.sol";
////import {IgSGX} from "./interfaces/IgSGX.sol";

error Unauthorized();
error AlreadyHasVault();
error DoenstHaveVault();
error TooEarlyToClaim();
error AmountTooSmall();
error AmountTooBig();
error TransferFrom();
error Transfer();
error Approve();

/// @title Subgenix Vault Factory.
/// @author Subgenix Research.
/// @notice The VaultFactory contract creates and manages user's vaults.
contract VaultFactory is Ownable, ReentrancyGuard {
    
    // <--------------------------------------------------------> //
    // <----------------------- METADATA -----------------------> //
    // <--------------------------------------------------------> // 

    // Trader Joe Router.
    IJoeRouter02 internal constant JOE_ROUTER = IJoeRouter02(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    // WAVAX token address.
    address internal constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    IERC20Mintable internal immutable sgx; // Official Subgenix Network token.
    IgSGX internal immutable gSGX;         // Subgenix Governance token.
    address internal immutable lockup;     // LockUpHell contract.
    address public immutable treasury;     // Subgenix Treasury.
    address public immutable research;     // Subgenix Research.

    constructor(
        address _sgx,
        address _gSGX,
        address _treasury,
        address _research,
        address _lockup
    ) {
        sgx = IERC20Mintable(_sgx);
        gSGX = IgSGX(_gSGX);
        treasury = _treasury;
        research = _research;
        lockup = _lockup;
    }

    // <--------------------------------------------------------> //
    // <----------------- VAULTS CONFIGURATION -----------------> //
    // <--------------------------------------------------------> // 

    // If a circuit break happens, all functions with this modifier
    // will stop working.
    modifier stopInEmergency { if (!stopped) _; }

    // Vault Leagues.
    enum VaultLeague {
        league0, // Avalanche Defender
        league1, // Subnet Soldier
        league2, // Network Warrior
        league3, // Consensus Master
        league4  // Royal Validator
    }

    // Maximum amount to be part of leagues
    struct LeagueAmount {
        // Maximum amount to be part of league 0.
        uint256 league0Amount;
        // Maximum amount to be part of league 1.
        uint256 league1Amount;
        // Maximum amount to be part of league 2.
        uint256 league2Amount;
        // Maximum amount to be part of league 3.
        uint256 league3Amount;
    }

    // Internal configs
    struct InternalConfig {
        // Time you have to wait to colect rewards again.
        uint256 rewardsWaitTime;
        // Indicates if swaps are happening or not.
        bool allowTreasurySwap;
    }

    // Vault's info.
    struct Vault {
        bool exists;                // vault exists.
        uint256 lastClaimTime;      // Last claim.
        uint256 uncollectedRewards; // All pending rewards.
        uint256 balance;            // Total Deposited in the vault.
        uint256 interestLength;     // Last interestRates length.
        VaultLeague league;         // Vault league.
    }
    
    /// @notice mapping of all users vaults.
    mapping(address => Vault) public usersVault;
    
    /// @notice Emitted when a vault is created.
    /// @param user address, owner of the vault.
    /// @param amount uint256, amount deposited in the vault.
    /// @param timeWhenCreated uint256, time when vault was created.
    event VaultCreated(address indexed user, uint256 amount, uint256 timeWhenCreated);

    /// @notice Emitted when user successfully deposit in his vault.
    /// @param user address, user that initiated the deposit.
    /// @param amount uint256, amount that was deposited in the vault.
    event SuccessfullyDeposited(address indexed user, uint256 amount);

    /// @notice Emitted when a vault is liquidated.
    /// @param user address, owner of the vault that was liquidated.
    event VaultLiquidated(address indexed user);
    
    /// @notice Emitted when the burn percentage is updated.
    /// @param percentage uint256, the new burn percentage.
    event BurnPercentUpdated(uint256 percentage);
    
    /// @notice Emitted when the minimum deposit required is updated.
    /// @param minDeposit uint256, the new minimum deposit.
    event MinVaultDepositUpdated(uint256 minDeposit);

    /// @notice Emitted when the network boost is updated.
    /// @param newBoost uint256, the new network boost.
    event NetworkBoostUpdated(uint256 newBoost);

    /// @notice Emitted when the gSGXPercent is updated.
    /// @param percentage uint256, the new gSGXPercent.
    event GSGXPercentUpdated(uint256 percentage);

    /// @notice Emitted when the liquidateVaultPercent is updated.
    /// @param percentage uint256, the new liquidateVaultPercent.
    event LiquidateVaultPercentUpdated(uint256 percentage);

    /// @notice Emitted when the gSGXDistributed is updated.
    /// @param percentage uint256, the new gSGXDistributed.
    event GSGXDistributedUpdated(uint256 percentage);

    /// @notice Emmited when the rewardsWaitTime is updated.
    /// @param time uint256, the re rewardsWaitTime.
    event RewardsWaitTimeUpdated(uint256 time);

    /// @notice Emitted when the treasurySwap is updated.
    /// @param allow bool, the new treasurySwap.
    event TreasurySwapUpdated(bool allow);

    /// @notice Emitted when the circuit breaker is activated.
    /// @param stop bool, true if activated, false otherwise.
    event CircuitBreakerUpdated(bool stop);

    /// @notice Emitted when the minimum amount to be part of a 
    ///         certain league is changed.
    /// @param index uint256, the index of the league.
    /// @param amount uint256, the new amount.
    event LeagueAmountUpdated(uint256 index, uint256 amount);
    
    /// @notice The minimum amount to deposit in the vault.
    uint256 public minVaultDeposit;
    
    /// @notice Percentage burned when claiming rewards.
    uint256 public burnPercent;

    /// @notice Percetage of SGX balance user will have after when liquidating vault.
    uint256 public liquidateVaultPercent;

    /// @notice Percentage of the reward converted to gSGX.
    uint256 public gSGXPercent;

    /// @notice Percentage of the reward sent to the gSGX contract.
    uint256 public gSGXDistributed;

    /// @notice Used to boost users SGX.
    /// @dev Multiplies users SGX (amount * networkBoost) when
    ///      depositing/creating a vault.
    uint256 public networkBoost;

    // Used as a circuit breaker
    bool private stopped; // init as false

    // Where all league amounts are stored.
    LeagueAmount internal leagueAmounts;

    // Internal configs
    InternalConfig internal internalConfigs;


    /// @notice Updates the burn percentage.
    /// @param percentage uint256, the new burn percentage.
    function setBurnPercent(uint256 percentage) external onlyOwner {
        burnPercent = percentage;
        emit BurnPercentUpdated(percentage);
    }

    /// @notice Updates the minimum required to deposit in the vault.
    /// @param minDeposit uint256, the new minimum deposit required.
    function setMinVaultDeposit(uint256 minDeposit) external onlyOwner {
        minVaultDeposit = minDeposit;
        emit MinVaultDepositUpdated(minDeposit);
    }

    /// @notice Updates the network boost.
    /// @param boost uint256, the new network boost.
    function setNetworkBoost(uint256 boost) external onlyOwner {
        // Should be >= 1e18.
        networkBoost = boost;
        emit NetworkBoostUpdated(boost);
    }

    /// @notice Updates the percentage of rewards coverted to gSGX
    ///         when claiming rewards.
    /// @param percentage uint256, the new percentage.
    function setgSGXPercent(uint256 percentage) external onlyOwner {
        gSGXPercent = percentage;
        emit GSGXPercentUpdated(percentage);
    }

    /// @notice Updates the percentage of the total amount in the vault 
    ///         user will receive in SGX when liquidating the vualt.
    /// @param  percentage uint256, the new percentage.
    function setLiquidateVaultPercent(uint256 percentage) external onlyOwner {
        liquidateVaultPercent = percentage;
        emit LiquidateVaultPercentUpdated(percentage);
    }

    /// @notice Updates the percentage of the rewards that will be 
    ///         converted to gSGX and sent to the gSGX contract.
    /// @param percentage uint256, the new percentage.
    function setgSGXDistributed(uint256 percentage) external onlyOwner {
        gSGXDistributed = percentage;
        emit GSGXDistributedUpdated(percentage);
    }

    /// @notice Updates the time user will have to wait to claim rewards
    ///         again.
    /// @param time uint256, the new wait time.
    function setRewardsWaitTime(uint256 time) external onlyOwner {
        internalConfigs.rewardsWaitTime = time;
        emit RewardsWaitTimeUpdated(time);
    }

    /// @notice Updates the treasury swap status.
    /// @param allow bool, true to activate swap, false otherwise.
    function setTreasurySwap(bool allow) external onlyOwner {
        internalConfigs.allowTreasurySwap = allow;
        emit TreasurySwapUpdated(allow);
    }

    /// @notice Used to pause specific contract functions.
    /// @param stop bool, true to pause function, false otherwise.
    function activateCircuitBreaker(bool stop) external onlyOwner {
        stopped = stop;
        emit CircuitBreakerUpdated(stop);
    }

    /// @notice Used to set maximum required to be part of a league.
    /// @param index uint256, the league we are modifing the maximum.
    /// @param amount uint256, the new maximum to be part of league `index`.
    function setLeagueAmount(uint256 index, uint256 amount) external onlyOwner {
        if (index == 0) {
            leagueAmounts.league0Amount = amount;
        } else if (index == 1) {
            leagueAmounts.league1Amount = amount;
        } else if (index == 2) {
            leagueAmounts.league2Amount = amount;
        } else if (index == 3) {
            leagueAmounts.league3Amount = amount;
        }

        emit LeagueAmountUpdated(index, amount);
    }

    // <--------------------------------------------------------> //
    // <----------------- VAULTS FUNCTIONALITY -----------------> //
    // <--------------------------------------------------------> // 

    /// @notice Creates a vault for the user.
    /// @param amount uint256, amount that will be deposited in the vault.
    function createVault(uint256 amount) external nonReentrant stopInEmergency {
        if (usersVault[msg.sender].exists) { revert AlreadyHasVault(); }
        if (amount < minVaultDeposit) { revert AmountTooSmall(); }

        uint256 amountBoosted = mulDivDown(amount, networkBoost, SCALE);

        VaultLeague tempLeague = getVaultLeague(amountBoosted);

        usersVault[msg.sender] = Vault({
            exists: true,
            lastClaimTime: block.timestamp,
            uncollectedRewards: 0,
            balance: amountBoosted,
            interestLength: pastInterestRates.length,
            league: tempLeague
        });

        totalNetworkVaults += 1;

        uint256 swapAmount;

        bool success = sgx.transferFrom(msg.sender, address(this), amount);
        if (!success) { revert TransferFrom(); }

        if (internalConfigs.allowTreasurySwap) {
            // Swaps 66% of the amount deposit to AVAX.
            swapAmount = mulDivDown(amount, 66e16, SCALE);
            swapSGXforAVAX(swapAmount);
        }

        success = sgx.approve(treasury, amount - swapAmount);
        if (!success) {revert Approve(); }
        success = sgx.transfer(treasury, amount - swapAmount);
        if (!success) {revert Transfer(); }

        emit VaultCreated(msg.sender, amount, block.timestamp);
    }

    /// @notice Deposits `amount` of SGX in the vault.
    /// @param amount uint256, amount that will be deposited in the vault.
    function depositInVault(uint256 amount) external nonReentrant stopInEmergency {
        Vault memory userVault = usersVault[msg.sender];
        
        if (!userVault.exists) { revert DoenstHaveVault(); }

        uint256 amountBoosted = mulDivDown(amount, networkBoost, SCALE);

        uint256 totalBalance = userVault.balance + amountBoosted;

        VaultLeague tempLeague = getVaultLeague(totalBalance);

        uint256 interest;

        // Make the check if interest rate length is still the same.
        if (pastInterestRates.length != userVault.interestLength) {
            (interest, 
             userVault.interestLength, 
             userVault.lastClaimTime
            ) = getPastInterestRates(
                userVault.interestLength, 
                userVault.lastClaimTime, 
                userVault.balance
            );
        }

        uint256 timeElapsed = block.timestamp - userVault.lastClaimTime;

        uint256 rewardsPercent = mulDivDown(timeElapsed, interestRate, BASETIME);

        interest += mulDivDown(userVault.balance, rewardsPercent, SCALE);

        // Update user's vault info
        userVault.lastClaimTime = block.timestamp;
        userVault.uncollectedRewards += interest;
        userVault.balance = totalBalance;
        userVault.league = tempLeague;

        usersVault[msg.sender] = userVault;

        emit SuccessfullyDeposited(msg.sender, amountBoosted); 

        // User needs to approve this contract to spend `token`.
        bool success = sgx.transferFrom(msg.sender, address(this), amount);
        if (!success) { revert TransferFrom(); }

        uint256 swapAmount;

        if (internalConfigs.allowTreasurySwap) {
            // Swaps 16% of the amount deposit to AVAX.
            swapAmount = mulDivDown(amount, 16e16, SCALE);
            swapSGXforAVAX(swapAmount);
        }

        success = sgx.approve(treasury, amount - swapAmount);
        if (!success) {revert Approve(); }
        success = sgx.transfer(treasury, amount - swapAmount);
        if (!success) {revert Transfer(); }
    }

    /// @notice Deletes user's vault.
    /// @param user address, the user we are deliting the vault.
    function liquidateVault(address user) external nonReentrant {
        Vault memory userVault = usersVault[msg.sender];
        
        if (msg.sender != user) { revert Unauthorized(); }
        if (!userVault.exists) { revert DoenstHaveVault(); }

        // 1. Claim all available rewards.
        uint256 timeElapsed = block.timestamp - userVault.lastClaimTime;

        uint256 rewardsPercent = mulDivDown(timeElapsed, interestRate, BASETIME);

        uint256 claimableRewards = mulDivDown(userVault.balance, rewardsPercent, SCALE) + userVault.uncollectedRewards;

        // Calculate liquidateVaultPercent of user's vault balance.
        uint256 sgxPercent = mulDivDown(userVault.balance, liquidateVaultPercent, SCALE);

        // Delete user vault.
        delete usersVault[user];

        protocolDebt += sgxPercent;
        totalNetworkVaults -= 1;

        emit VaultLiquidated(user);

        distributeRewards(claimableRewards,  user);

        sgx.mint(user, sgxPercent);
    }

    /// @notice Allows owner to create a vault for a specific user.
    /// @param user address, the user the owner is creating the vault for.
    /// @param amount uint256, the amount being deposited in the vault.
    function createOwnerVault(address user, uint256 amount) external onlyOwner {
        
        if (usersVault[msg.sender].exists) { revert AlreadyHasVault(); }
        if (amount < minVaultDeposit) { revert AmountTooSmall(); }

        uint256 amountBoosted = mulDivDown(amount, networkBoost, SCALE);

        VaultLeague tempLeague = getVaultLeague(amountBoosted);

        usersVault[user] = Vault({
            exists: true,
            lastClaimTime: block.timestamp,
            uncollectedRewards: 0,
            balance: amountBoosted,
            interestLength: pastInterestRates.length,
            league: tempLeague
        });

        totalNetworkVaults += 1;

        bool success = sgx.transferFrom(msg.sender, address(this), amount);
        if (!success) {revert TransferFrom(); }

        success = sgx.approve(treasury, amount);
        if (!success) {revert Approve(); }
        success = sgx.transfer(treasury, amount);
        if (!success) {revert Transfer(); }

        emit VaultCreated(user, amount, block.timestamp);
    }

    /// @notice Calculates the total interest generated based on past interest rates.
    /// @param userInterestLength uint256, the last interest length updated in users vault.
    /// @param userLastClaimTime uint256,  the last time user claimed his rewards.
    /// @param userBalance uint256,        user balance in the vault.
    /// @return interest uint256,           the total interest accumalted.
    /// @return interestLength uint256,     the updated version of users interest length.
    /// @return lastClaimTime uint256,      the updated version of users last claim time.
    function getPastInterestRates(
        uint256 userInterestLength, 
        uint256 userLastClaimTime,
        uint256 userBalance
        ) internal view returns(uint256 interest, uint256 interestLength, uint256 lastClaimTime) {
        
        interestLength = userInterestLength;
        lastClaimTime = userLastClaimTime;
        uint256 timeElapsed;
        uint256 rewardsPercent;
        uint256 pastInterestLength = pastInterestRates.length;

        for (interestLength; interestLength < pastInterestLength; interestLength+=1) {
            
            timeElapsed = timeWhenChanged[interestLength] - lastClaimTime;
            rewardsPercent = mulDivDown(timeElapsed, pastInterestRates[interestLength], BASETIME);

            interest += mulDivDown(userBalance, rewardsPercent, SCALE);
            
            lastClaimTime = timeWhenChanged[interestLength];
        }
    }

    /// @notice Gets the league user is part of depending on the balance in his vault.
    /// @param balance uint256, the balance in user's vault.
    /// @return tempLeague VaultLeague, the league user is part of.
    function getVaultLeague(uint256 balance) internal view returns(VaultLeague tempLeague) {
        LeagueAmount memory localLeagueAmounts = leagueAmounts;
        
        if (balance <= localLeagueAmounts.league0Amount) {
            tempLeague = VaultLeague.league0;
        } else if (balance > localLeagueAmounts.league0Amount &&  balance <= localLeagueAmounts.league1Amount) {
            tempLeague = VaultLeague.league1;
        } else if (balance > localLeagueAmounts.league1Amount &&  balance <= localLeagueAmounts.league2Amount) {
            tempLeague = VaultLeague.league2;
        } else if (balance > localLeagueAmounts.league2Amount &&  balance <= localLeagueAmounts.league3Amount) {
            tempLeague = VaultLeague.league3;
        } else {
            tempLeague = VaultLeague.league4;
        }
    }

    /// @notice swaps SGX for AVAX on traderJoe. The Subgenix Network will use the SGX
    ///         in the treasury to make investments in subnets, and at a certain point the
    ///         team would have to sell its SGX tokens to make this happen. To avoid
    ///         big dumps in the price, we decided to make a partial sell of the
    ///         SGX everytime some SGX goes to the treasury, this will help the team have
    ///         AVAX ready to make the investments and will save the community from seeing
    ///         massive dumps in the price.
    /// @param swapAmount uint256, the amount of SGX we are making the swap.
    function swapSGXforAVAX(uint256 swapAmount) private {

        bool success = sgx.approve(address(JOE_ROUTER), swapAmount);
        if (!success) {revert Approve(); }

        address[] memory path;
        path = new address[](2);
        path[0] = address(sgx);
        path[1] = WAVAX;

        uint256 toTreasury = mulDivDown(swapAmount, 75e16, SCALE);
        uint256 toResearch = swapAmount - toTreasury;
        
        JOE_ROUTER.swapExactTokensForAVAX(toTreasury, 0, path, treasury, block.timestamp);
        JOE_ROUTER.swapExactTokensForAVAX(toResearch, 0, path, research, block.timestamp);
    }

    // <--------------------------------------------------------> //
    // <---------------- REWARDS  CONFIGURATION ----------------> //
    // <--------------------------------------------------------> // 

    /// @notice Emmited when the reward percentage is updated.
    /// @param reward uint256, the new reward percentage.
    event InterestRateUpdated(uint256 reward);

    // The interestRate is represented as following:
    //   - 100% = 1e18
    //   -  10% = 1e17
    //   -   1% = 1e16
    //   - 0.1% = 1e15
    //   and so on..
    //
    // This allow us to have a really high level of granulatity,
    // and distributed really small amount of rewards with high
    // precision.
    
    /// @notice Interest rate (per `BASETIME`) i.e. 1e17 = 10% / `BASETIME`
    uint256 public interestRate;

    uint256[] internal pastInterestRates; // Past interest rates.
    uint256[] internal timeWhenChanged;   // Last time the interest rate was valid.

    // The level of reward granularity, WAD
    uint256 internal constant SCALE = 1e18;

    // Base time used to calculate rewards.
    uint256 internal constant BASETIME = 365 days;

    /// @notice Updates the reward percentage distributed per `BASETIME`
    /// @param reward uint256, the new reward percentage.
    function setInterestRate(uint256 reward) external onlyOwner {

        if (interestRate != 0) {
            pastInterestRates.push(interestRate);
            timeWhenChanged.push(block.timestamp);
        }
        interestRate = reward;

        emit InterestRateUpdated(reward);
    }

    // <--------------------------------------------------------> //
    // <---------------- REWARDS  FUNCTIONALITY ----------------> //
    // <--------------------------------------------------------> // 

    /// @notice Claims the available rewards from user's vault.
    /// @param user address, who we are claiming rewards of.
    function claimRewards(address user) public nonReentrant {
        Vault memory userVault = usersVault[user];
        
        uint256 localLastClaimTime = userVault.lastClaimTime;

        if (msg.sender != user) { revert Unauthorized(); }
        if (!userVault.exists) { revert DoenstHaveVault(); }
        if ((block.timestamp - localLastClaimTime) < internalConfigs.rewardsWaitTime) { 
            revert TooEarlyToClaim(); 
        }

        uint256 claimableRewards;

        // Make the check if interest rate length is still the same.
        if (pastInterestRates.length != userVault.interestLength) {
            (claimableRewards, 
             userVault.interestLength, 
             localLastClaimTime
            ) = getPastInterestRates(
                userVault.interestLength, 
                localLastClaimTime, 
                userVault.balance
            );
        }

        uint256 timeElapsed = block.timestamp - localLastClaimTime;

        uint256 rewardsPercent = mulDivDown(timeElapsed, interestRate, BASETIME);

        claimableRewards += mulDivDown(userVault.balance, rewardsPercent, SCALE) + userVault.uncollectedRewards;

        // Update user's vault info
        userVault.lastClaimTime = block.timestamp;
        userVault.uncollectedRewards = 0;
        usersVault[msg.sender] = userVault;

        distributeRewards(claimableRewards, user);
    }
    
    /// @notice Distributes the claimable rewards to the user, obeying
    ///         protocol rules.
    /// @param claimableRewards uint256, the total amount of rewards the user is claiming.
    /// @param user address, who we are distributing rewards to.
    function distributeRewards(uint256 claimableRewards, address user) private {

        uint256 mintAmount = claimableRewards;

        (uint256 burnAmount, 
         uint256 shortLockup, 
         uint256 longLockup,
         uint256 curGSGXPercent,
         uint256 gSGXToContract) = calculateDistribution(claimableRewards); 
        
        claimableRewards -= (burnAmount + curGSGXPercent + gSGXToContract);

        sgx.mint(address(this), mintAmount);

        sgx.burn(address(this), burnAmount); // Burn token

        // Convert to gSGX and send to user.
        bool success = sgx.approve(address(gSGX), curGSGXPercent);
        if (!success) { revert Approve(); }
        gSGX.deposit(user, curGSGXPercent);

        // send to gSGX Contracts
        success = sgx.transfer(address(gSGX), gSGXToContract);
        if (!success) { revert Transfer(); }

        success = sgx.transfer(user, claimableRewards); // Transfer token to users.
        if (!success) { revert Transfer(); }
        
        ILockupHell(lockup).lockupRewards(user, shortLockup, longLockup); // Lockup tokens
    }

    /// @notice Calculate the final value of the percentage based on the rewards amount.
    ///         eg. If rewards = 100 then 10% of it = 10.
    /// @param rewards uint256, the amount all the percentages are being calculated on top off.
    /// @return burnAmount uint256,     the amount being burned.
    /// @return shortLockup uint256,    the amount being locked for a shorter period of time.
    /// @return longLockup uint256,     the amount being locked for a longer period of time.
    /// @return curGSGXPercent uint256, the amount being converted to gSGX.
    /// @return gSGXToContract uint256, the amount being sent to the gSGX contract.
    function calculateDistribution(uint256 rewards) internal view returns (
    uint256 burnAmount, 
    uint256 shortLockup, 
    uint256 longLockup,
    uint256 curGSGXPercent,
    uint256 gSGXToContract
    ) {

        burnAmount = mulDivDown(rewards, burnPercent, SCALE);
        shortLockup = mulDivDown(rewards, ILockupHell(lockup).getShortPercentage(), SCALE);
        longLockup = mulDivDown(rewards, ILockupHell(lockup).getLongPercentage(), SCALE);
        curGSGXPercent = mulDivDown(rewards, gSGXPercent, SCALE);
        gSGXToContract = mulDivDown(rewards, gSGXDistributed, SCALE);
    } 


    /// @notice Checks how much reward the User can get if he claim rewards.
    /// @param user address, who we are checking the pending rewards.
    /// @return pendingRewards uint256, rewards that user can claim at any time.
    /// @return shortLockup uint256, the rewards being locked for a shorter period of time.
    /// @return longLockup uint256, the rewards being locked for a longer period of time.
    function viewPendingRewards(address user) external view returns(uint256, uint256, uint256) {
        if (!usersVault[user].exists) { revert DoenstHaveVault(); }

        uint256 interestLength = usersVault[user].interestLength;

        uint256 balance = usersVault[user].balance;

        uint256 lastClaimTime = usersVault[user].lastClaimTime;

        uint256 pendingRewards;

        // Make the check if interest rate length is still the same.
        if (pastInterestRates.length != interestLength) {
            (pendingRewards, 
              , 
             lastClaimTime) = getPastInterestRates(interestLength, lastClaimTime, balance);
        }

        uint256 timeElapsed = block.timestamp - lastClaimTime;

        uint256 rewardsPercent = mulDivDown(timeElapsed, interestRate, BASETIME);

        pendingRewards += mulDivDown(balance, rewardsPercent, SCALE) + usersVault[user].uncollectedRewards;

        (uint256 burnAmount,
         uint256 shortLockup,
         uint256 longLockup,
         uint256 curGSGXPercent,
         uint256 gSGXToContract) = calculateDistribution(pendingRewards);

        pendingRewards -= (burnAmount + curGSGXPercent + gSGXToContract + shortLockup + longLockup);

        return (pendingRewards, shortLockup, longLockup);
    }

    // <--------------------------------------------------------> //
    // <---------------- PROTOCOL FUNCTIONALITY ----------------> //
    // <--------------------------------------------------------> // 

    /// @notice Total vaults created.
    uint256 public totalNetworkVaults;
    
    /// @notice Total protocol debt from vaults liquidated.
    uint256 public protocolDebt;

    /// @notice Emitted when protocol debt is repaid.
    /// @param amount uint256, amount of debt that was repaid.
    event DebtReaid(uint256 amount);

    /// @notice Repay the debt created by liquidated vauts.
    /// @param amount uint256, the amount of debt being repaid.
    function repayDebt(uint256 amount) external onlyOwner {
        if(amount >= protocolDebt) { revert AmountTooBig(); }

        protocolDebt -= amount;

        emit DebtReaid(amount);

        // Treasury needs to give permission to this contract.
        sgx.burn(address(msg.sender), amount);
    }

    /// @notice mulDiv rounding down - (x*y)/denominator.
    /// @dev    from Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/FixedPointMathLib.sol)
    /// @param x uint256, the first operand.
    /// @param y uint256, the second operand.
    /// @param denominator uint256, the SCALE number.
    /// @return z uint256, the result of the mulDiv operation.
    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        // solhint-disable-next-line
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    // <--------------------------------------------------------> //
    // <------------------ VIEW FUNCTIONALITY ------------------> //
    // <--------------------------------------------------------> // 

    /// @notice Get user's vault info.
    /// @param user address, user we are checking the vault.
    /// @param lastClaimTime uint256,      last time user claimed rewards.
    /// @param uncollectedRewards uint256, rewards user didn't collected yet.
    /// @param balance uint256,            user's vault balance.
    /// @param league VaultLeague,         league user's vault is part of.
    function getVaultInfo(address user) external view returns(
        uint256 lastClaimTime, 
        uint256 uncollectedRewards, 
        uint256 balance, 
        VaultLeague league
        ) {
        if (!usersVault[user].exists) { revert DoenstHaveVault(); }

        lastClaimTime      = usersVault[user].lastClaimTime;
        uncollectedRewards = usersVault[user].uncollectedRewards;
        balance            = usersVault[user].balance;
        league             = usersVault[user].league;
    }

    /// @notice Gets the balance in user's vault.
    /// @param user address, the user we are checking the balance of.
    /// @return The balance of the user.
    function getUserBalance(address user) external view returns (uint256) {
        return usersVault[user].balance;
    }

    /// @notice Gets the league user's vault is part of.
    /// @param user address, the user we are checking the league of.
    /// @return The user's vault league.
    function getUserLeague(address user) external view returns (VaultLeague) {
        return usersVault[user].league;
    }

    /// @notice Check if vault exists.
    /// @param user address, User we are checking the vault.
    /// @return True if vault exists, false otherwise.
    function vaultExists(address user) external view returns(bool) {
        return usersVault[user].exists;
    }

    /// @notice Checks if user can claim rewards or not.
    /// @param user address, the user we are checking if he can claim rewards or not.
    /// @return True if user can claim rewards, false otherwise.
    function canClaimRewards(address user) external view returns(bool) {
        if (!usersVault[user].exists) { revert DoenstHaveVault(); }

        uint256 lastClaimTime = usersVault[user].lastClaimTime;

        if ((block.timestamp - lastClaimTime) >= internalConfigs.rewardsWaitTime) { return true; }

        return false;
    }

    /// @notice Gets the percentage of SGX being hold in the gSGX contract.
    /// @return The percentage of SGX being hold in the gSGX contract.
    function getGSGXDominance() external view returns (uint256) {
        return mulDivDown(sgx.balanceOf(address(gSGX)), SCALE, sgx.totalSupply());
    }
}