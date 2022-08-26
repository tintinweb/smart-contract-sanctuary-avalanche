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
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/AvatrollerInterface.sol";
import "./interfaces/EIP20Interface.sol";
import "./interfaces/UniswapRouterV2Interface.sol";
import "./interfaces/WAVAX.sol";
import "./interfaces/ATokenInterfaces.sol";

contract Liquidator is Ownable {
    /// @notice Avatroller address
    AvatrollerInterface public avatroller;

    /// @notice Stable ERC20 asset
    EIP20Interface public stable;

    /// @notice Uniswap protocol V2 router
    UniswapRouterV2Interface public router;

    /// @notice WAVAX address
    WAVAX public wavax;

    constructor(
        AvatrollerInterface avatroller_,
        EIP20Interface stable_,
        UniswapRouterV2Interface router_,
        WAVAX wavax_ 
    ) {
        require(address(stable_) != address(0x0), "C0");
        require(address(avatroller_) != address(0x0), "C1");
        require(address(router_) != address(0x0), "C2");
        require(address(wavax_) != address(0x0), "C3");

        avatroller = avatroller_;
        stable = stable_;
        router = router_;
        wavax = wavax_;
    }

    function liquidate(
        address borrower_,
        uint repayAmount_,
        ATokenInterface cTokenCollateral_,
        AErc20Interface cTokenBorrow_,
        EIP20Interface token_
    ) external {
        address[] memory path = new address[](3);

        if (address(stable) != address(token_)) {
            path[0] = address(stable);
            path[1] = address(wavax);
            path[2] = address(token_);
    
            uint256[] memory amounts = router.getAmountsIn(repayAmount_, path);
            stable.transferFrom(msg.sender, address(this), amounts[0]);
            router.swapTokensForExactTokens(repayAmount_, amounts[0], path, address(this), block.timestamp + 600);
        }
        
        token_.approve(address(cTokenBorrow_), repayAmount_);

        // liquidate
        require(cTokenBorrow_.liquidateBorrow(borrower_, repayAmount_, cTokenCollateral_) == 0, "liquidation failed");

        AErc20Interface cTokenCollateral__ = AErc20Interface(address(cTokenCollateral_));

        // redeem collateral cToken
        cTokenCollateral__.redeem(cTokenCollateral_.balanceOf(address(this)));

        EIP20Interface underlying = EIP20Interface(cTokenCollateral__.underlying());

        // swap it to stable if necessary
        if (address(underlying) != address(stable)) {
            path[0] = address(underlying);
            path[1] = address(wavax);
            path[2] = address(stable);

            router.swapExactTokensForTokens(underlying.balanceOf(address(this)), underlying.balanceOf(address(this)) - 100, path, msg.sender, block.timestamp + 600);
        } else {
            stable.transfer(msg.sender, stable.balanceOf(address(this)));
        }
    }

    // get amount of collateral to be liquidated
    function getAmountToBeLiquidated(
        address _aTokenBorrowed,
        address _aTokenCollateral,
        uint _actualRepayAmount
    ) external view returns (uint) {
        /*
         * Get the exchange rate and calculate the number of collateral tokens to seize:
         *  seizeAmount = actualRepayAmount * liquidationIncentive * priceBorrowed / priceCollateral
         *  seizeTokens = seizeAmount / exchangeRate
         *   = actualRepayAmount * (liquidationIncentive * priceBorrowed) / (priceCollateral * exchangeRate)
         */
        (uint error, uint cTokenCollateralAmount) = avatroller.liquidateCalculateSeizeTokens(
            _aTokenBorrowed,
            _aTokenCollateral,
        _actualRepayAmount
        );

        require(error == 0, "GATBL0");

        return cTokenCollateralAmount;
    }


    /**
     * ADMIN FUNCTIONS
     */ 

    function _setStable(EIP20Interface stable_) onlyOwner external  {
        require(address(stable_) != address(0x0), "SS0");
        stable = stable_;
    }

    function _setRouter(UniswapRouterV2Interface router_) onlyOwner external  {
        require(address(router_) != address(0x0), "SR0");
        router = router_;
    }

    function _setAvatroller(AvatrollerInterface avatroller_) onlyOwner external  {
        require(address(avatroller_) != address(0x0), "SA0");
        avatroller = avatroller_;
    }
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

import "./AvatrollerInterface.sol";
import "../models/InterestRateModel.sol";
import "./EIP20NonStandardInterface.sol";
import "../library/ErrorReporter.sol";

contract ATokenStorage {
    /**
     * @dev Guard variable for re-entrancy checks
     */
    bool internal _notEntered;

    /**
     * @notice EIP-20 token name for this token
     */
    string public name;

    /**
     * @notice EIP-20 token symbol for this token
     */
    string public symbol;

    /**
     * @notice EIP-20 token decimals for this token
     */
    uint8 public decimals;

    // Maximum borrow rate that can ever be applied (.0005% / block)
    uint256 internal constant borrowRateMaxMantissa = 0.0005e16;

    // Maximum fraction of interest that can be set aside for reserves
    uint256 internal constant reserveFactorMaxMantissa = 1e18;

    /**
     * @notice Administrator for this contract
     */
    address payable public admin;

    /**
     * @notice Pending administrator for this contract
     */
    address payable public pendingAdmin;

    /**
     * @notice Contract which oversees inter-aToken operations
     */
    AvatrollerInterface public avatroller;

    /**
     * @notice Model which tells what the current interest rate should be
     */
    InterestRateModel public interestRateModel;

    // Initial exchange rate used when minting the first CTokens (used when totalSupply = 0)
    uint256 internal initialExchangeRateMantissa;

    /**
     * @notice Fraction of interest currently set aside for reserves
     */
    uint256 public reserveFactorMantissa;

    /**
     * @notice Block number that interest was last accrued at
     */
    uint256 public accrualBlockNumber;

    /**
     * @notice Accumulator of the total earned interest rate since the opening of the market
     */
    uint256 public borrowIndex;

    /**
     * @notice Total amount of outstanding borrows of the underlying in this market
     */
    uint256 public totalBorrows;

    /**
     * @notice Total amount of reserves of the underlying held in this market
     */
    uint256 public totalReserves;

    /**
     * @notice Total number of tokens in circulation
     */
    uint256 public totalSupply;

    // Official record of token balances for each account
    mapping(address => uint256) internal accountTokens;

    // Approved token transfer amounts on behalf of others
    mapping(address => mapping(address => uint256)) internal transferAllowances;

    /**
     * @notice Container for borrow balance information
     * @member principal Total balance (with accrued interest), after applying the most recent balance-changing action
     * @member interestIndex Global borrowIndex as of the most recent balance-changing action
     */
    struct BorrowSnapshot {
        uint256 principal;
        uint256 interestIndex;
    }

    // Mapping of account addresses to outstanding borrow balances
    mapping(address => BorrowSnapshot) internal accountBorrows;

    /**
     * @notice Share of seized collateral that is added to reserves
     */
    uint256 public constant protocolSeizeShareMantissa = 2.8e16; //2.8%
}

abstract contract ATokenInterface is ATokenStorage {
    /**
     * @notice Indicator that this is a AToken contract (for inspection)
     */
    bool public constant isCToken = true;

    /*** Market Events ***/

    /**
     * @notice Event emitted when interest is accrued
     */
    event AccrueInterest(uint256 cashPrior, uint256 interestAccumulated, uint256 borrowIndex, uint256 totalBorrows);

    /**
     * @notice Event emitted when tokens are minted
     */
    event Mint(address minter, uint256 mintAmount, uint256 mintTokens);

    /**
     * @notice Event emitted when tokens are redeemed
     */
    event Redeem(address redeemer, uint256 redeemAmount, uint256 redeemTokens);

    /**
     * @notice Event emitted when underlying is borrowed
     */
    event Borrow(address borrower, uint256 borrowAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when a borrow is repaid
     */
    event RepayBorrow(address payer, address borrower, uint256 repayAmount, uint256 accountBorrows, uint256 totalBorrows);

    /**
     * @notice Event emitted when a borrow is liquidated
     */
    event LiquidateBorrow(address liquidator, address borrower, uint256 repayAmount, address cTokenCollateral, uint256 seizeTokens);

    /*** Admin Events ***/

    /**
     * @notice Event emitted when pendingAdmin is changed
     */
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);

    /**
     * @notice Event emitted when pendingAdmin is accepted, which means admin is updated
     */
    event NewAdmin(address oldAdmin, address newAdmin);

    /**
     * @notice Event emitted when avatroller is changed
     */
    event NewAvatroller(AvatrollerInterface oldAvatroller, AvatrollerInterface newAvatroller);

    /**
     * @notice Event emitted when interestRateModel is changed
     */
    event NewMarketInterestRateModel(InterestRateModel oldInterestRateModel, InterestRateModel newInterestRateModel);

    /**
     * @notice Event emitted when the reserve factor is changed
     */
    event NewReserveFactor(uint256 oldReserveFactorMantissa, uint256 newReserveFactorMantissa);

    /**
     * @notice Event emitted when the reserves are added
     */
    event ReservesAdded(address benefactor, uint256 addAmount, uint256 newTotalReserves);

    /**
     * @notice Event emitted when the reserves are reduced
     */
    event ReservesReduced(address admin, uint256 reduceAmount, uint256 newTotalReserves);

    /**
     * @notice EIP20 Transfer event
     */
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /**
     * @notice EIP20 Approval event
     */
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*** User Interface ***/

    function transfer(address dst, uint256 amount) external virtual returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external virtual returns (bool);

    function approve(address spender, uint256 amount) external virtual returns (bool);

    function allowance(address owner, address spender) external view virtual returns (uint256);

    function balanceOf(address owner) external view virtual returns (uint256);

    function balanceOfUnderlying(address owner) external virtual returns (uint256);

    function getAccountSnapshot(address account)
        external
        view
        virtual
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function borrowRatePerBlock() external view virtual returns (uint256);

    function supplyRatePerBlock() external view virtual returns (uint256);

    function totalBorrowsCurrent() external virtual returns (uint256);

    function borrowBalanceCurrent(address account) external virtual returns (uint256);

    function borrowBalanceStored(address account) external view virtual returns (uint256);

    function exchangeRateCurrent() external virtual returns (uint256);

    function exchangeRateStored() external view virtual returns (uint256);

    function getCash() external view virtual returns (uint256);

    function accrueInterest() external virtual returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual returns (uint256);

    /*** Admin Functions ***/

    function _setPendingAdmin(address payable newPendingAdmin) external virtual returns (uint256);

    function _acceptAdmin() external virtual returns (uint256);

    function _setAvatroller(AvatrollerInterface newAvatroller) external virtual returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa) external virtual returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external virtual returns (uint256);

    function _setInterestRateModel(InterestRateModel newInterestRateModel) external virtual returns (uint256);
}

contract AErc20Storage {
    /**
     * @notice Underlying asset for this AToken
     */
    address public underlying;
}

abstract contract AErc20Interface is AErc20Storage {
    /*** User Interface ***/

    function mint(uint256 mintAmount) external virtual returns (uint256);

    function redeem(uint256 redeemTokens) external virtual returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external virtual returns (uint256);

    function borrow(uint256 borrowAmount) external virtual returns (uint256);

    function repayBorrow(uint256 repayAmount) external virtual returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount) external virtual returns (uint256);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        ATokenInterface cTokenCollateral
    ) external virtual returns (uint256);

    function sweepToken(EIP20NonStandardInterface token) external virtual;

    /*** Admin Functions ***/

    function _addReserves(uint256 addAmount) external virtual returns (uint256);
}

contract ADelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

abstract contract ADelegatorInterface is ADelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(address oldImplementation, address newImplementation);

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) external virtual;
}

abstract contract ADelegateInterface is ADelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) external virtual;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() external virtual;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

abstract contract AvatrollerInterface {
    /// @notice Indicator that this is a Avatroller contract (for inspection)
    bool public constant isAvatroller = true;

    /*** Assets You Are In ***/

    function enterMarkets(address[] calldata cTokens) external virtual returns (uint256[] memory);

    function exitMarket(address aToken) external virtual returns (uint256);

    /*** Policy Hooks ***/

    function mintAllowed(
        address aToken,
        address minter,
        uint256 mintAmount
    ) external virtual returns (uint256);

    function mintVerify(
        address aToken,
        address minter,
        uint256 mintAmount,
        uint256 mintTokens
    ) external virtual;

    function redeemAllowed(
        address aToken,
        address redeemer,
        uint256 redeemTokens
    ) external virtual returns (uint256);

    function redeemVerify(
        address aToken,
        address redeemer,
        uint256 redeemAmount,
        uint256 redeemTokens
    ) external virtual;

    function borrowAllowed(
        address aToken,
        address borrower,
        uint256 borrowAmount
    ) external virtual returns (uint256);

    function borrowVerify(
        address aToken,
        address borrower,
        uint256 borrowAmount
    ) external virtual;

    function repayBorrowAllowed(
        address aToken,
        address payer,
        address borrower,
        uint256 repayAmount
    ) external virtual returns (uint256);

    function repayBorrowVerify(
        address aToken,
        address payer,
        address borrower,
        uint256 repayAmount,
        uint256 borrowerIndex
    ) external virtual;

    function liquidateBorrowAllowed(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount
    ) external virtual returns (uint256);

    function liquidateBorrowVerify(
        address cTokenBorrowed,
        address cTokenCollateral,
        address liquidator,
        address borrower,
        uint256 repayAmount,
        uint256 seizeTokens
    ) external virtual;

    function seizeAllowed(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual returns (uint256);

    function seizeVerify(
        address cTokenCollateral,
        address cTokenBorrowed,
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external virtual;

    function transferAllowed(
        address aToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external virtual returns (uint256);

    function transferVerify(
        address aToken,
        address src,
        address dst,
        uint256 transferTokens
    ) external virtual;

    /*** Liquidity/Liquidation Calculations ***/

    function liquidateCalculateSeizeTokens(
        address cTokenBorrowed,
        address cTokenCollateral,
        uint256 repayAmount
    ) external view virtual returns (uint256, uint256);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return success Whether or not the transfer succeeded
     */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return success Whether or not the transfer succeeded
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool success);

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved (-1 means infinite)
     * @return success Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent (-1 means infinite)
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title EIP20NonStandardInterface
 * @dev Version of ERC20 with no return values for `transfer` and `transferFrom`
 *  See https://medium.com/coinmonks/missing-return-value-bug-at-least-130-tokens-affected-d67bf08521ca
 */
interface EIP20NonStandardInterface {
    /**
     * @notice Get the total number of tokens in circulation
     * @return The supply of tokens
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return balance The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transfer` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transfer(address dst, uint256 amount) external;

    ///
    /// !!!!!!!!!!!!!!
    /// !!! NOTICE !!! `transferFrom` does not return a value, in violation of the ERC-20 specification
    /// !!!!!!!!!!!!!!
    ///

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     */
    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external;

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param amount The number of tokens that are approved
     * @return success Whether or not the approval succeeded
     */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
     * @notice Get the current allowance from `owner` for `spender`
     * @param owner The address of the account which owns the tokens to be spent
     * @param spender The address of the account which may transfer tokens
     * @return remaining The number of tokens allowed to be spent
     */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.11;

interface UniswapRouterV2Interface {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAX(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountAVAX);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityAVAXWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountAVAX);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactAVAXForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactAVAX(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForAVAX(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapAVAXForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

interface WAVAX {
    function deposit() external payable;
    function transfer(address to, uint256 value) external returns (bool);
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

contract AvatrollerErrorReporter {
    enum Error {
        NO_ERROR,
        UNAUTHORIZED,
        COMPTROLLER_MISMATCH,
        INSUFFICIENT_SHORTFALL,
        INSUFFICIENT_LIQUIDITY,
        INVALID_CLOSE_FACTOR,
        INVALID_COLLATERAL_FACTOR,
        INVALID_LIQUIDATION_INCENTIVE,
        MARKET_NOT_ENTERED, // no longer possible
        MARKET_NOT_LISTED,
        MARKET_ALREADY_LISTED,
        MATH_ERROR,
        NONZERO_BORROW_BALANCE,
        PRICE_ERROR,
        REJECTION,
        SNAPSHOT_ERROR,
        TOO_MANY_ASSETS,
        TOO_MUCH_REPAY
    }

    enum FailureInfo {
        ACCEPT_ADMIN_PENDING_ADMIN_CHECK,
        ACCEPT_PENDING_IMPLEMENTATION_ADDRESS_CHECK,
        EXIT_MARKET_BALANCE_OWED,
        EXIT_MARKET_REJECTION,
        SET_CLOSE_FACTOR_OWNER_CHECK,
        SET_CLOSE_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_OWNER_CHECK,
        SET_COLLATERAL_FACTOR_NO_EXISTS,
        SET_COLLATERAL_FACTOR_VALIDATION,
        SET_COLLATERAL_FACTOR_WITHOUT_PRICE,
        SET_IMPLEMENTATION_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_OWNER_CHECK,
        SET_LIQUIDATION_INCENTIVE_VALIDATION,
        SET_MAX_ASSETS_OWNER_CHECK,
        SET_PENDING_ADMIN_OWNER_CHECK,
        SET_PENDING_IMPLEMENTATION_OWNER_CHECK,
        SET_PRICE_ORACLE_OWNER_CHECK,
        SUPPORT_MARKET_EXISTS,
        SUPPORT_MARKET_OWNER_CHECK,
        SET_PAUSE_GUARDIAN_OWNER_CHECK
    }

    /**
     * @dev `error` corresponds to enum Error; `info` corresponds to enum FailureInfo, and `detail` is an arbitrary
     * contract-specific code that enables us to report opaque error codes from upgradeable contracts.
     **/
    event Failure(uint256 error, uint256 info, uint256 detail);

    /**
     * @dev use this when reporting a known error from the money market or a non-upgradeable collaborator
     */
    function fail(Error err, FailureInfo info) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), 0);

        return uint256(err);
    }

    /**
     * @dev use this when reporting an opaque error from an upgradeable collaborator contract
     */
    function failOpaque(
        Error err,
        FailureInfo info,
        uint256 opaqueError
    ) internal returns (uint256) {
        emit Failure(uint256(err), uint256(info), opaqueError);

        return uint256(err);
    }
}

contract TokenErrorReporter {
    uint256 public constant NO_ERROR = 0; // support legacy return codes

    error TransferAvatrollerRejection(uint256 errorCode);
    error TransferNotAllowed();
    error TransferNotEnough();
    error TransferTooMuch();

    error MintAvatrollerRejection(uint256 errorCode);
    error MintFreshnessCheck();

    error RedeemAvatrollerRejection(uint256 errorCode);
    error RedeemFreshnessCheck();
    error RedeemTransferOutNotPossible();

    error BorrowAvatrollerRejection(uint256 errorCode);
    error BorrowFreshnessCheck();
    error BorrowCashNotAvailable();

    error RepayBorrowAvatrollerRejection(uint256 errorCode);
    error RepayBorrowFreshnessCheck();

    error LiquidateAvatrollerRejection(uint256 errorCode);
    error LiquidateFreshnessCheck();
    error LiquidateCollateralFreshnessCheck();
    error LiquidateAccrueBorrowInterestFailed(uint256 errorCode);
    error LiquidateAccrueCollateralInterestFailed(uint256 errorCode);
    error LiquidateLiquidatorIsBorrower();
    error LiquidateCloseAmountIsZero();
    error LiquidateCloseAmountIsUintMax();
    error LiquidateRepayBorrowFreshFailed(uint256 errorCode);

    error LiquidateSeizeAvatrollerRejection(uint256 errorCode);
    error LiquidateSeizeLiquidatorIsBorrower();

    error AcceptAdminPendingAdminCheck();

    error SetAvatrollerOwnerCheck();
    error SetPendingAdminOwnerCheck();

    error SetReserveFactorAdminCheck();
    error SetReserveFactorFreshCheck();
    error SetReserveFactorBoundsCheck();

    error AddReservesFactorFreshCheck(uint256 actualAddAmount);

    error ReduceReservesAdminCheck();
    error ReduceReservesFreshCheck();
    error ReduceReservesCashNotAvailable();
    error ReduceReservesCashValidation();

    error SetInterestRateModelOwnerCheck();
    error SetInterestRateModelFreshCheck();
}

// SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.10;

/**
 * @title Compound's InterestRateModel Interface
 */
abstract contract InterestRateModel {
    /// @notice Indicator that this is an InterestRateModel contract (for inspection)
    bool public constant isInterestRateModel = true;

    /**
     * @notice Calculates the current borrow interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @return The borrow rate per block (as a percentage, and scaled by 1e18)
     */
    function getBorrowRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves
    ) external view virtual returns (uint256);

    /**
     * @notice Calculates the current supply interest rate per block
     * @param cash The total amount of cash the market has
     * @param borrows The total amount of borrows the market has outstanding
     * @param reserves The total amount of reserves the market has
     * @param reserveFactorMantissa The current reserve factor the market has
     * @return The supply rate per block (as a percentage, and scaled by 1e18)
     */
    function getSupplyRate(
        uint256 cash,
        uint256 borrows,
        uint256 reserves,
        uint256 reserveFactorMantissa
    ) external view virtual returns (uint256);
}