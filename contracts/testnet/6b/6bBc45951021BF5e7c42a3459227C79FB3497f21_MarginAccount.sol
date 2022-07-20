// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";
import { SafeCast } from "@openzeppelin/contracts/utils/math/SafeCast.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { HubbleBase } from "./legos/HubbleBase.sol";
import {
    ERC20Detailed,
    IClearingHouse,
    IInsuranceFund,
    IOracle,
    IRegistry,
    IMarginAccount,
    IERC20FlexibleSupply,
    IWAVAX
} from "./Interfaces.sol";

/**
* @title This contract is used for posting margin (collateral), realizing PnL etc.
* @notice Most notable operations include addMargin, removeMargin and liquidations
*/
contract MarginAccount is IMarginAccount, HubbleBase, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeCast for uint256;
    using SafeCast for int256;

    // Hubble vUSD is necessitated to be the first whitelisted collateral
    uint constant VUSD_IDX = 0;
    uint constant WAVAX_IDX = 1; // assumes wavax index = 1

    // used for all usd based values
    uint constant PRECISION = 1e6;

    error NOT_LIQUIDATABLE(IMarginAccount.LiquidationStatus);

    /**
    * @dev This is only used to group variables to avoid a solidity stack too deep error
    *   incentivePerDollar How many $ liquidator gets for each $ they repay e.g. they might get $1.05 for every $1 liquidation. >= PRECISION
    *   repayAble The maximum debt that can be settled for an account undergoing a liquidation
    *   priceCollateral Most recent oracle price (chainlink) of the collateral that is being seized for an account undergoing a liquidation
    *   decimals Decimals for the collateral being seized
    */
    struct LiquidationBuffer {
        LiquidationStatus status;
        uint8 decimals;
        uint incentivePerDollar;
        uint repayAble;
        uint priceCollateral;
    }

    /* ****************** */
    /*       Storage      */
    /* ****************** */

    IClearingHouse public clearingHouse;
    IOracle public oracle;
    IInsuranceFund public insuranceFund;
    IERC20FlexibleSupply public vusd;
    uint public credit;

    /// @notice Array of supported collateral
    Collateral[] public supportedCollateral;

    /**
    * @notice How many $ liquidator gets for each $ they repay e.g. they might get $1.05 for every $1 liquidation
    * @dev In the above scenario, this value will be %0.05 i.e. 5 cents incentive per dollar repayed
    */
    uint public liquidationIncentive;

    /**
    * @notice Maps index in supportedCollateral => trader => balance
    * @dev equivalent to margin(uint idx, address user)
    */
    mapping(uint => mapping(address => int)) override public margin;

    uint256[50] private __gap;

    /* ****************** */
    /*       Events       */
    /* ****************** */

    /// @notice Emitted when user adds margin for any of the supported collaterals
    event MarginAdded(address indexed trader, uint256 indexed idx, uint amount, uint256 timestamp);

    /// @notice Emitted when user removes margin for any of the supported collaterals
    event MarginRemoved(address indexed trader, uint256 indexed idx, uint256 amount, uint256 timestamp);

    /**
    * @notice Mutates trader's vUSD balance
    * @param trader Account who is realizing PnL
    * @param realizedPnl Increase or decrease trader's vUSD balace by. +ve/-ve value means vUSD is added/removed respectively from trader's margin
    */
    event PnLRealized(address indexed trader, int256 realizedPnl, uint256 timestamp);

    /**
    * @notice Emitted when a trader's margin account is liquidated i.e. their vUSD debt is repayed in exchange for their collateral
    * @param trader Trader whose margin account was liquidated
    * @param idx Index of the collateral that was seized during the liquidation
    * @param seizeAmount Amount of the collateral that was seized during the liquidation
    * @param repayAmount The debt that was repayed
    */
    event MarginAccountLiquidated(address indexed trader, uint indexed idx, uint seizeAmount, uint repayAmount, uint256 timestamp);

    /**
    * @notice Emitted when funds from insurance fund are tasked to settle system's bad debt
    * @param trader Account for which the bad debt was settled
    * @param seized Collateral amounts that were seized
    * @param repayAmount Debt that was settled. it's exactly equal to -vUSD when vUSD < 0
    */
    event SettledBadDebt(address indexed trader, uint[] seized, uint repayAmount, uint256 timestamp);

    modifier onlyClearingHouse() {
        require(_msgSender() == address(clearingHouse), "Only clearingHouse");
        _;
    }

    constructor(address _trustedForwarder) HubbleBase(_trustedForwarder) {}

    function initialize(
        address _governance,
        address _vusd
    ) external initializer {
        _setGovernace(_governance);
        _addCollateral(_vusd, PRECISION); // weight = 1 * PRECISION
        vusd = IERC20FlexibleSupply(_vusd);
    }

    receive() external payable {
        // only accept AVAX via fallback from the WAVAX contract
        assert(_msgSender() == address(supportedCollateral[WAVAX_IDX].token));
    }

    /* ****************** */
    /*       Margin       */
    /* ****************** */

    /**
    * @notice Post margin
    * @param idx Index of the supported collateral
    * @param amount Amount to deposit (scaled same as the asset)
    */
    function addMargin(uint idx, uint amount) override external whenNotPaused {
        addMarginFor(idx, amount, _msgSender());
    }

    /**
    * @notice Post margin for another account
    * @param idx Index of the supported collateral
    * @param amount Amount to deposit (scaled same as the asset)
    * @param to Account to post margin for
    */
    function addMarginFor(uint idx, uint amount, address to) override public whenNotPaused {
        require(amount > 0, "Add non-zero margin");
        // will revert for idx >= supportedCollateral.length
        if (idx == VUSD_IDX) {
            _transferInVusd(_msgSender(), amount);
        } else {
            supportedCollateral[idx].token.safeTransferFrom(_msgSender(), address(this), amount);
        }
        margin[idx][to] += amount.toInt256();
        emit MarginAdded(to, idx, amount, _blockTimestamp());
    }

    /**
    * @notice Withdraw margin.
    *   Collateral can not be withdrawn if vUSD balance is < 0.
    * @dev If the contract has insufficient vUSD balance, a loan is taken from the vUSD contract.
    * @param idx Index of the supported collateral
    * @param amount Amount to withdraw (scaled same as the asset)
    */
    function removeMargin(uint idx, uint256 amount) override external whenNotPaused {
        address trader = _msgSender();
        _validateRemoveMargin(idx, amount, trader);

        if (idx == VUSD_IDX) {
            _transferOutVusd(trader, amount);
        } else {
            supportedCollateral[idx].token.safeTransfer(trader, amount);
        }
        emit MarginRemoved(trader, idx, amount, _blockTimestamp());
    }

    /**
    * @notice remove margin in Avax
    * @param amount Amount to withdraw
    */
    function removeAvaxMargin(uint amount) external whenNotPaused {
        address trader = _msgSender();
        _validateRemoveMargin(WAVAX_IDX, amount, trader);

        IWAVAX(address(supportedCollateral[WAVAX_IDX].token)).withdraw(amount);
        safeTransferAVAX(trader, amount);

        emit MarginRemoved(trader, WAVAX_IDX, amount, _blockTimestamp());
    }

    /**
    * @notice Invoked to realize PnL, credit/debit funding payments, pay trade and liquidation fee
    * @dev Will only make a change to VUSD balance.
    *   only clearingHouse is authorized to call.
    * @param trader Account to realize PnL for
    * @param realizedPnl Amount to credit/debit
    */
    function realizePnL(address trader, int256 realizedPnl)
        override
        external
        onlyClearingHouse
    {
        // -ve PnL will reduce balance
        if (realizedPnl != 0) {
            margin[VUSD_IDX][trader] += realizedPnl;
            emit PnLRealized(trader, realizedPnl, _blockTimestamp());
        }
    }

    function transferOutVusd(address recipient, uint amount)
        override
        external
        onlyClearingHouse
    {
        _transferOutVusd(recipient, amount);
    }

    /* ****************** */
    /*    Liquidations    */
    /* ****************** */

    /**
    * @notice Determines if a trader's margin account can be liquidated now
    * @param trader Account to check liquidation status for
    * @param includeFunding whether to include funding payments before checking liquidation status
    * @return _isLiquidatable Whether the account can be liquidated; reason if not
    * @return repayAmount Trader's debt i.e. the max amount that they can be liquidated for
    * @return incentivePerDollar How many $ liquidator gets for each $ they repay
    *   e.g. they might get $1.05 for every $1 that is repayed.
    */
    function isLiquidatable(address trader, bool includeFunding)
        override
        public
        view
        returns(IMarginAccount.LiquidationStatus _isLiquidatable, uint repayAmount, uint incentivePerDollar)
    {
        int vusdBal = margin[VUSD_IDX][trader];
        if (includeFunding) {
            vusdBal -= clearingHouse.getTotalFunding(trader);
        }
        if (vusdBal >= 0) { // nothing to liquidate
            return (IMarginAccount.LiquidationStatus.NO_DEBT, 0, 0);
        }

        (uint256 notionalPosition,) = clearingHouse.getTotalNotionalPositionAndUnrealizedPnl(trader, 0, IClearingHouse.Mode.Min_Allowable_Margin); // last two arguments are irrelevent as we are checking only for zero/non-zero notional position in next step
        if (notionalPosition != 0) { // Liquidate positions before liquidating margin account
            return (IMarginAccount.LiquidationStatus.OPEN_POSITIONS, 0, 0);
        }

        (int256 weighted, int256 spot) = weightedAndSpotCollateral(trader);
        if (weighted >= 0) {
            return (IMarginAccount.LiquidationStatus.ABOVE_THRESHOLD, 0, 0);
        }

        // _isLiquidatable = IMarginAccount.LiquidationStatus.IS_LIQUIDATABLE;
        repayAmount = (-vusdBal).toUint256();
        incentivePerDollar = PRECISION; // get atleast $1 worth of collateral for every $1 paid

        if (spot > 0) {
            /**
                Liquidation scenario B, where Cw < |vUSD| < Cusd
                => Cw - |vUSD| < 0
                => Cw + vUSD (=weighted) < 0; since vUSD < 0
                Max possible liquidationIncentive (for repaying |vUSD|) is Cusd
            */
            incentivePerDollar += _min(
                liquidationIncentive, // incentivePerDollar = PRECISION + liquidationIncentive <= 1.1
                // divide up all the extra dollars in proportion to repay amount
                // note that spot value here is inclusive of the -ve vUSD value
                spot.toUint256() * PRECISION / repayAmount
            );
        } /* else {
            Since the protocol is already in deficit we don't have any money to give out as liquidationIncentive
            Liquidation scenario C, where Cusd <= |vUSD|
            => Cusd - |vUSD| <= 0
            => Cusd + vUSD (=spot) <= 0; since vUSD < 0

            @todo consider providing some incentive from insurance fund to execute a liquidation in this scenario.
            That fee is basically provided so that insurance fund has to settle a lower bad debt and seize lesser amount of assets.
            (because seized assets then need to sold/auctioned off, so that's extra work)
        } */
    }

    /**
    * @notice Liquidate a trader while mentioning the exact repay amount while capping "slippage" on the seized collateral
    *   This maybe be considered as a "swapExactInput" operation.
    *   It's required that trader has no open positions.
    * @param trader Account to liquidate
    * @param repay Amount to repay
    * @param idx Index of the collateral to seize
    * @param minSeizeAmount Min collateral output amount
    */
    function liquidateExactRepay(address trader, uint repay, uint idx, uint minSeizeAmount) external whenNotPaused {
        clearingHouse.updatePositions(trader); // credits/debits funding
        LiquidationBuffer memory buffer = _getLiquidationInfo(trader, idx);
        if (buffer.status != IMarginAccount.LiquidationStatus.IS_LIQUIDATABLE) {
            revert NOT_LIQUIDATABLE(buffer.status);
        }
        _liquidateExactRepay(buffer, trader, repay, idx, minSeizeAmount);
    }

    /**
    * @notice Liquidate a trader while mentioning the exact collateral amount to be seized while capping "slippage" on the repay amount.
    *   This maybe be considered as a "swapExactOutput" operation.
    *   It's required that trader has no open positions.
    * @param trader Account to liquidate
    * @param maxRepay Max vUSD input amount
    * @param idx Index of the collateral to seize
    * @param seize Exact collateral amount desired to be seized
    */
    function liquidateExactSeize(address trader, uint maxRepay, uint idx, uint seize) external whenNotPaused {
        clearingHouse.updatePositions(trader); // credits/debits funding
        LiquidationBuffer memory buffer = _getLiquidationInfo(trader, idx);
        if (buffer.status != IMarginAccount.LiquidationStatus.IS_LIQUIDATABLE) {
            revert NOT_LIQUIDATABLE(buffer.status);
        }
        _liquidateExactSeize(buffer, trader, maxRepay, idx, seize);
    }

    /**
    * @notice Either seize all available collateral
    *   OR settle debt completely with (most likely) left over collateral.
    *   It's required that trader has no open positions.
    *   Seized collateral at it's current oracle price should be acceptable to the liquidator.
    * @param trader Account to liquidate
    * @param maxRepay Max vUSD input amount
    * @param idxs Indices of the collateral to seize
    */
    function liquidateFlexible(address trader, uint maxRepay, uint[] calldata idxs) external whenNotPaused {
        clearingHouse.updatePositions(trader); // credits/debits funding
        uint repayed;
        for (uint i; i < idxs.length; i++) {
            LiquidationBuffer memory buffer = _getLiquidationInfo(trader, idxs[i]);
            // revert only if trader has open positions, otherwise fail silently
            if (buffer.status == IMarginAccount.LiquidationStatus.OPEN_POSITIONS) {
                revert NOT_LIQUIDATABLE(buffer.status);
            }
            if (buffer.status != IMarginAccount.LiquidationStatus.IS_LIQUIDATABLE) {
                break;
            }
            repayed = _liquidateFlexible(trader, maxRepay, idxs[i]);
            maxRepay -= repayed;
        }
    }

    /**
    * @notice Invoke a bad debt settlement using the insurance fund.
    *   It's required that trader has no open positions when settling bad debt.
    * @dev Debt is said to be bad when the spot value of user's collateral is not enough to cover their -ve vUSD balance
    *   Since there are no open positions, debit/credit funding payments is not required.
    * @param trader Account for which the bad debt needs to be settled
    */
    function settleBadDebt(address trader) external whenNotPaused {
        (uint256 notionalPosition,) = clearingHouse.getTotalNotionalPositionAndUnrealizedPnl(trader, 0, IClearingHouse.Mode.Min_Allowable_Margin); // last two arguments are irrelevent as we are checking only for zero/non-zero notional position in next step
        require(notionalPosition == 0, "Liquidate positions before settling bad debt");

        // The spot value of their collateral minus their vUSD obligation is a negative value
        require(getSpotCollateralValue(trader) < 0, "Above bad debt threshold");

        int vusdBal = margin[VUSD_IDX][trader];

        // this check is not strictly required because getSpotCollateralValue(trader) < 0 is a stronger assertion
        require(vusdBal < 0, "Nothing to repay");

        uint badDebt = (-vusdBal).toUint256();
        Collateral[] memory assets = supportedCollateral;

        // This pulls the obligation
        insuranceFund.seizeBadDebt(badDebt);
        margin[VUSD_IDX][trader] = 0;

        // Insurance fund gets all the available collateral
        uint[] memory seized = new uint[](assets.length);
        for (uint i = 1 /* skip vusd */; i < assets.length; i++) {
            int amount = margin[i][trader];
            if (amount > 0) {
                margin[i][trader] = 0;
                assets[i].token.safeTransfer(address(insuranceFund), amount.toUint256());
                seized[i] = amount.toUint256();
                insuranceFund.startAuction(address(assets[i].token));
            }
        }
        emit SettledBadDebt(trader, seized, badDebt, _blockTimestamp());
    }

    /* ********************* */
    /* Liquidations Internal */
    /* ********************* */

    /**
    * @dev This function wil either seize all available collateral of type idx
    * OR settle debt completely with (most likely) left over collateral
    * @return Debt repayed <= repayble i.e. user's max debt
    */
    function _liquidateFlexible(address trader, uint maxRepay, uint idx) internal whenNotPaused returns(uint /* repayed */) {
        LiquidationBuffer memory buffer = _getLiquidationInfo(trader, idx);

        // Q. Can user's margin cover the entire debt?
        uint repay = _seizeToRepay(buffer, margin[idx][trader].toUint256());

        // A.1 Yes, it can cover the entire debt. Settle repayAble
        if (repay >= buffer.repayAble) {
            _liquidateExactRepay(
                buffer,
                trader,
                buffer.repayAble, // exact repay amount
                idx,
                0 // minSeizeAmount=0 implies accept whatever the oracle price is
            );
            return buffer.repayAble; // repayed exactly repayAble and 0 is left to repay now
        }

        // A.2 No, collateral can not cover the entire debt. Seize all of it.
        return _liquidateExactSeize(
            buffer,
            trader,
            maxRepay,
            idx,
            margin[idx][trader].toUint256()
        );
    }

    function _liquidateExactRepay(
        LiquidationBuffer memory buffer,
        address trader,
        uint repay,
        uint idx,
        uint minSeizeAmount
    )
        internal
        returns (uint seized)
    {
        // determine the seizable collateral amount on the basis of the most recent chainlink price feed
        seized = _min(
            _scaleDecimals(repay * buffer.incentivePerDollar, buffer.decimals - 6) / buffer.priceCollateral,
            // can't seize more than available
            // this also protects the liquidator in the scenario that they were front-run and only a small seize isn't worth it for them
            margin[idx][trader].toUint256()
        );
        require(seized >= minSeizeAmount, "Not seizing enough");
        _executeLiquidation(trader, repay, idx, seized, buffer.repayAble);
    }

    function _liquidateExactSeize(
        LiquidationBuffer memory buffer,
        address trader,
        uint maxRepay,
        uint idx,
        uint seize
    )
        internal
        returns (uint repay)
    {
        repay = _seizeToRepay(buffer, seize);
        require(repay <= maxRepay, "Need to repay more to seize that much");
        _executeLiquidation(trader, repay, idx, seize, buffer.repayAble);
    }

    /**
    * @dev reverts if margin account is not liquidatable
    */
    function _getLiquidationInfo(address trader, uint idx) internal view returns (LiquidationBuffer memory buffer) {
        require(idx > VUSD_IDX && idx < supportedCollateral.length, "collateral not seizable");
        (buffer.status, buffer.repayAble, buffer.incentivePerDollar) = isLiquidatable(trader, false);
        if (buffer.status == IMarginAccount.LiquidationStatus.IS_LIQUIDATABLE) {
            Collateral memory coll = supportedCollateral[idx];
            buffer.priceCollateral = oracle.getUnderlyingPrice(address(coll.token)).toUint256();
            buffer.decimals = coll.decimals;
        }
    }

    /**
    * @dev Peform the actual liquidation.
    *   1. Pull the repay amount from liquidator's account and credit trader's VUSD margin
    *   2. Debit the seize amount and transfer to liquidator
    * @return The debt that is leftover to be paid
    */
    function _executeLiquidation(address trader, uint repay, uint idx, uint seize, uint repayAble)
        internal
        returns (uint /* left over repayable */)
    {
        if (repay == 0 || seize == 0) { // provides more flexibility, so prefer not reverting
            return repayAble;
        }

        _transferInVusd(_msgSender(), repay);
        margin[VUSD_IDX][trader] += repay.toInt256();

        margin[idx][trader] -= seize.toInt256();
        supportedCollateral[idx].token.safeTransfer(_msgSender(), seize);

        emit MarginAccountLiquidated(trader, idx, seize, repay, _blockTimestamp());
        return repayAble - repay; // will ensure that the liquidator isn't repaying more than user's debt (and seizing a bigger amount of their collateral)
    }

    function _seizeToRepay(LiquidationBuffer memory buffer, uint seize) internal pure returns (uint repay) {
        repay = seize * buffer.priceCollateral / (10 ** buffer.decimals);
        if (buffer.incentivePerDollar > 0) {
            repay = repay * PRECISION / buffer.incentivePerDollar;
        }
    }

    /* ****************** */
    /*        View        */
    /* ****************** */

    function getSpotCollateralValue(address trader) override public view returns(int256 spot) {
        (,spot) = weightedAndSpotCollateral(trader);
    }

    function getNormalizedMargin(address trader) override public view returns(int256 weighted) {
        (weighted,) = weightedAndSpotCollateral(trader);
    }

    function weightedAndSpotCollateral(address trader)
        public
        view
        returns (int256 weighted, int256 spot)
    {
        Collateral[] memory assets = supportedCollateral;
        Collateral memory _collateral;

        for (uint i; i < assets.length; i++) {
            if (margin[i][trader] == 0) continue;
            _collateral = assets[i];

            int numerator = margin[i][trader] * oracle.getUnderlyingPrice(address(assets[i].token));
            uint denomDecimals = _collateral.decimals;

            spot += (numerator / int(10 ** denomDecimals));
            weighted += (numerator * _collateral.weight.toInt256() / int(10 ** (denomDecimals + 6)));
        }
    }

    /* ****************** */
    /*     UI Helpers     */
    /* ****************** */

    function supportedAssets() external view override returns (Collateral[] memory) {
        return supportedCollateral;
    }

    function supportedAssetsLen() override external view returns (uint) {
        return supportedCollateral.length;
    }

    /* ****************** */
    /*    Misc Internal   */
    /* ****************** */

    function _addCollateral(address _coin, uint _weight) internal {
        require(_weight <= PRECISION, "weight > 1e6");

        Collateral[] memory _collaterals = supportedCollateral;
        for (uint i; i < _collaterals.length; i++) {
            require(address(_collaterals[i].token) != _coin, "collateral exists");
        }
        supportedCollateral.push(
            Collateral({
                token: IERC20(_coin),
                weight: _weight,
                decimals: ERC20Detailed(_coin).decimals() // will fail if .decimals() is not defined on the contract
            })
        );
    }

    function _scaleDecimals(uint256 amount, uint8 decimals) internal pure returns(uint256) {
        return amount * (10 ** decimals);
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    function _transferInVusd(address from, uint amount) internal {
        IERC20(address(vusd)).safeTransferFrom(from, address(this), amount);
        if (credit > 0) {
            uint toBurn = Math.min(vusd.balanceOf(address(this)), credit);
            credit -= toBurn;
            vusd.burn(toBurn);
        }
    }

    function _transferOutVusd(address recipient, uint amount) internal {
        uint bal = vusd.balanceOf(address(this));
        if (bal < amount) {
            // Say there are 2 traders, Alice and Bob.
            // Alice has a profitable position and realizes their PnL in form of vusd margin.
            // But bob has not yet realized their -ve PnL.
            // In that case we'll take a credit from vusd contract, which will eventually be returned when Bob pays their debt back.
            uint _credit = amount - bal;
            credit += _credit;
            vusd.mint(address(this), _credit);
        }
        IERC20(address(vusd)).safeTransfer(recipient, amount);
    }

    function _validateRemoveMargin(uint idx, uint256 amount, address trader) internal {
        require(amount != 0, 'Remove non-zero margin');

        // credit funding payments
        clearingHouse.updatePositions(trader);

        require(margin[VUSD_IDX][trader] >= 0, "Cannot remove margin when vusd balance is negative");
        require(margin[idx][trader] >= amount.toInt256(), "Insufficient balance");

        margin[idx][trader] -= amount.toInt256();

        // Check minimum margin requirement after withdrawal
        clearingHouse.assertMarginRequirement(trader);
    }

    function safeTransferAVAX(address to, uint256 value) internal nonReentrant {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "MA: AVAX_TRANSFER_FAILED");
    }
    /* ****************** */
    /*     Governance     */
    /* ****************** */

    function syncDeps(address _registry, uint _liquidationIncentive) public onlyGovernance {
        // protecting against setting a very high liquidation incentive. Max 10%
        require(_liquidationIncentive <= PRECISION / 10, "MA.syncDeps.LI_GT_10_percent");
        IRegistry registry = IRegistry(_registry);
        require(registry.marginAccount() == address(this), "Incorrect setup");

        clearingHouse = IClearingHouse(registry.clearingHouse());
        oracle = IOracle(registry.oracle());
        insuranceFund = IInsuranceFund(registry.insuranceFund());
        liquidationIncentive = _liquidationIncentive;
    }

    function whitelistCollateral(address _coin, uint _weight) external onlyGovernance {
        _addCollateral(_coin, _weight);
    }

    // function to change weight of an asset
    function changeCollateralWeight(uint idx, uint _weight) external onlyGovernance {
        require(_weight <= PRECISION, "weight > 1e6");
        require(idx < supportedCollateral.length, "Collateral not supported");
        supportedCollateral[idx].weight = _weight;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeCast.sol)

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128) {
        require(value >= type(int128).min && value <= type(int128).max, "SafeCast: value doesn't fit in 128 bits");
        return int128(value);
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64) {
        require(value >= type(int64).min && value <= type(int64).max, "SafeCast: value doesn't fit in 64 bits");
        return int64(value);
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32) {
        require(value >= type(int32).min && value <= type(int32).max, "SafeCast: value doesn't fit in 32 bits");
        return int32(value);
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16) {
        require(value >= type(int16).min && value <= type(int16).max, "SafeCast: value doesn't fit in 16 bits");
        return int16(value);
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits.
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8) {
        require(value >= type(int8).min && value <= type(int8).max, "SafeCast: value doesn't fit in 8 bits");
        return int8(value);
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import { ERC2771Context } from "@openzeppelin/contracts/metatx/ERC2771Context.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Context } from "@openzeppelin/contracts/utils/Context.sol";

import { Governable } from "./Governable.sol";

/**
* @title This contract is used for posting margin (collateral), realizing PnL etc.
* @notice Most notable operations include addMargin, removeMargin and liquidations
*/
contract HubbleBase is Governable, Pausable, ERC2771Context {

    /**
    * @dev _trustedForwarder is a private immutable var in ERC2771Context
    */
    constructor(address _trustedForwarder) ERC2771Context(_trustedForwarder) {}

    /* ****************** */
    /*   Internal View    */
    /* ****************** */

    function _msgSender()
        internal
        view
        override(Context, ERC2771Context)
        returns (address)
    {
        return super._msgSender();
    }

    function _msgData()
        internal
        view
        override(Context, ERC2771Context)
        returns (bytes memory)
    {
        return super._msgData();
    }

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

    /* ****************** */
    /*     Governance     */
    /* ****************** */

    function pause() external onlyGovernance {
        _pause();
    }

    function unpause() external onlyGovernance {
        _unpause();
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRegistry {
    function oracle() external view returns(address);
    function clearingHouse() external view returns(address);
    function vusd() external view returns(address);
    function insuranceFund() external view returns(address);
    function marginAccount() external view returns(address);
}

interface IOracle {
    function getUnderlyingPrice(address asset) external view returns(int256);
    function getUnderlyingTwapPrice(address asset, uint256 intervalInSeconds) external view returns (int256);
}

interface IClearingHouse {
    enum Mode { Maintenance_Margin, Min_Allowable_Margin }
    function openPosition(uint idx, int256 baseAssetQuantity, uint quoteAssetLimit) external;
    function closePosition(uint idx, uint quoteAssetLimit) external;
    function addLiquidity(uint idx, uint256 baseAssetQuantity, uint minDToken) external returns (uint dToken);
    function removeLiquidity(uint idx, uint256 dToken, uint minQuoteValue, uint minBaseValue) external;
    function settleFunding() external;
    function getTotalNotionalPositionAndUnrealizedPnl(address trader, int256 margin, Mode mode)
        external
        view
        returns(uint256 notionalPosition, int256 unrealizedPnl);
    function isAboveMaintenanceMargin(address trader) external view returns(bool);
    function assertMarginRequirement(address trader) external view;
    function updatePositions(address trader) external;
    function getMarginFraction(address trader) external view returns(int256);
    function getTotalFunding(address trader) external view returns(int256 totalFunding);
    function getAmmsLength() external view returns(uint);
    function amms(uint idx) external view returns(IAMM);
    function maintenanceMargin() external view returns(int256);
    function minAllowableMargin() external view returns(int256);
    function tradeFee() external view returns(uint256);
    function liquidationPenalty() external view returns(uint256);
    function getNotionalPositionAndMargin(address trader, bool includeFundingPayments, Mode mode)
        external
        view
        returns(uint256 notionalPosition, int256 margin);
    function isMaker(address trader) external view returns(bool);
    function liquidate(address trader) external;
    function liquidateMaker(address trader) external;
    function liquidateTaker(address trader) external;
    function commitLiquidity(uint idx, uint quoteAsset) external;
    function insuranceFund() external view returns(IInsuranceFund);
    function calcMarginFraction(address trader, bool includeFundingPayments, Mode mode) external view returns(int256);
}

interface ERC20Detailed {
    function decimals() external view returns (uint8);
}

interface IInsuranceFund {
    function seizeBadDebt(uint amount) external;
    function startAuction(address token) external;
    function calcVusdAmountForAuction(address token, uint amount) external view returns(uint);
    function buyCollateralFromAuction(address token, uint amount) external;
}

interface IAMM {
    struct Maker {
        uint vUSD;
        uint vAsset;
        uint dToken;
        int pos; // position
        int posAccumulator; // value of global.posAccumulator until which pos has been updated
        int lastPremiumFraction;
        int lastPremiumPerDtoken;
        uint unbondTime;
        uint unbondAmount;
        uint ignition;
    }

    struct Ignition {
        uint quoteAsset;
        uint baseAsset;
        uint dToken;
    }

    /**
    * @dev We do not deliberately have a Pause state. There is only a master-level pause at clearingHouse level
    */
    enum AMMState { Inactive, Ignition, Active }
    function ammState() external view returns(AMMState);
    function ignition() external view returns(uint quoteAsset, uint baseAsset, uint dToken);
    function getIgnitionShare(uint vUSD) external view returns (uint vAsset, uint dToken);

    function openPosition(address trader, int256 baseAssetQuantity, uint quoteAssetLimit)
        external
        returns (int realizedPnl, uint quoteAsset, bool isPositionIncreased);
    function addLiquidity(address trader, uint baseAssetQuantity, uint minDToken) external returns (uint dToken);
    function removeLiquidity(address maker, uint amount, uint minQuote, uint minBase) external returns (int /* realizedPnl */, uint /* makerOpenNotional */, int /* makerPosition */);
    function forceRemoveLiquidity(address maker) external returns (int realizedPnl, uint makerOpenNotional, int makerPosition);
    function getNotionalPositionAndUnrealizedPnl(address trader)
        external
        view
        returns(uint256 notionalPosition, int256 unrealizedPnl, int256 size, uint256 openNotional);
    function updatePosition(address trader) external returns(int256 fundingPayment);
    function liquidatePosition(address trader) external returns (int realizedPnl, uint quoteAsset);
    function settleFunding() external;
    function underlyingAsset() external view returns (address);
    function positions(address trader) external view returns (int256,uint256,int256,uint256);
    function getCloseQuote(int256 baseAssetQuantity) external view returns(uint256 quoteAssetQuantity);
    function getTakerNotionalPositionAndUnrealizedPnl(address trader) external view returns(uint takerNotionalPosition, int256 unrealizedPnl);
    function getPendingFundingPayment(address trader)
        external
        view
        returns(
            int256 takerFundingPayment,
            int256 makerFundingPayment,
            int256 latestCumulativePremiumFraction,
            int256 latestPremiumPerDtoken
        );
    function getOpenNotionalWhileReducingPosition(int256 positionSize, uint256 notionalPosition, int256 unrealizedPnl, int256 baseAssetQuantity)
        external
        pure
        returns(uint256 remainOpenNotional, int realizedPnl);
    function makers(address maker) external view returns(Maker memory);
    function vamm() external view returns(IVAMM);
    function commitLiquidity(address maker, uint quoteAsset) external;
    function putAmmInIgnition() external;
    function isOverSpreadLimit() external view returns (bool);
    function getOracleBasedPnl(address trader, int256 margin, IClearingHouse.Mode mode) external view returns (uint, int256);
}

interface IMarginAccount {
    struct Collateral {
        IERC20 token;
        uint weight;
        uint8 decimals;
    }

    enum LiquidationStatus {
        IS_LIQUIDATABLE,
        OPEN_POSITIONS,
        NO_DEBT,
        ABOVE_THRESHOLD
    }

    function addMargin(uint idx, uint amount) external;
    function addMarginFor(uint idx, uint amount, address to) external;
    function removeMargin(uint idx, uint256 amount) external;
    function getSpotCollateralValue(address trader) external view returns(int256 spot);
    function weightedAndSpotCollateral(address trader) external view returns(int256, int256);
    function getNormalizedMargin(address trader) external view returns(int256);
    function realizePnL(address trader, int256 realizedPnl) external;
    function isLiquidatable(address trader, bool includeFunding) external view returns(LiquidationStatus, uint, uint);
    function supportedAssetsLen() external view returns(uint);
    function supportedAssets() external view returns (Collateral[] memory);
    function margin(uint idx, address trader) external view returns(int256);
    function transferOutVusd(address recipient, uint amount) external;
    function liquidateExactRepay(address trader, uint repay, uint idx, uint minSeizeAmount) external;
}

interface IVAMM {
    function balances(uint256) external view returns (uint256);

    function get_dy(
        uint256 i,
        uint256 j,
        uint256 dx
    ) external view returns (uint256);

    function get_dx(
        uint256 i,
        uint256 j,
        uint256 dy
    ) external view returns (uint256);

    function exchange(
        uint256 i,
        uint256 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256 dy, uint256 last_price);

    function exchangeExactOut(
        uint256 i,
        uint256 j,
        uint256 dy,
        uint256 max_dx
    ) external returns (uint256 dx, uint256 last_price);

    function get_notional(uint256 makerDToken, uint256 vUSD, uint256 vAsset, int256 takerPosSize, uint256 takerOpenNotional) external view returns (uint256, int256, int256, uint256);
    function last_prices() external view returns(uint256);
    function mark_price() external view returns(uint256);
    function price_oracle() external view returns(uint256);
    function price_scale() external view returns(uint256);
    function add_liquidity(uint256[2] calldata amounts, uint256 min_mint_amount) external returns (uint256);
    function calc_token_amount(uint256[2] calldata amounts, bool deposit) external view returns (uint256);
    function remove_liquidity(
        uint256 amount,
        uint256[2] calldata minAmounts,
        uint256 vUSD,
        uint256 vAsset,
        uint256 makerDToken,
        int256 takerPosSize,
        uint256 takerOpenNotional
    ) external returns (int256, uint256, uint256, int256, uint[2] calldata);
    function get_maker_position(uint256 amount, uint256 vUSD, uint256 vAsset, uint256 makerDToken) external view returns (int256, uint256, int256);
    function totalSupply() external view returns (uint256);
    function setinitialPrice(uint) external;
}

interface AggregatorV3Interface {

    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

interface IERC20FlexibleSupply is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

interface IVUSD is IERC20 {
     function mintWithReserve(address to, uint amount) external;
}

interface IUSDC is IERC20FlexibleSupply {
    function masterMinter() external view returns(address);
    function configureMinter(address minter, uint256 minterAllowedAmount) external;
}

interface IHubbleViewer {
    function getMakerPositionAndUnrealizedPnl(address _maker, uint idx)
        external
        view
        returns (int256 position, uint openNotional, int256 unrealizedPnl);
    function clearingHouse() external returns(IClearingHouse);
    function marginAccount() external returns(IMarginAccount);
}

interface IHubbleReferral {
    function getTraderRefereeInfo(address trader) external view returns (address referrer);
}

interface IJoeRouter02 {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
    function factory() external returns(address);
    function getAmountsIn(uint256 amountOut, address[] calldata path) external returns (uint256[] memory amounts);
    function getAmountsOut(uint256 amountOut, address[] calldata path) external returns (uint256[] memory amounts);
}

interface IJoePair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;
}

interface IJoeFactory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IWAVAX is IERC20 {
    function deposit() external payable;
    function withdraw(uint256) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.9;

import { Initializable } from "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract VanillaGovernable {
    address public governance;

    modifier onlyGovernance() {
        require(msg.sender == governance, "ONLY_GOVERNANCE");
        _;
    }

    function setGovernace(address _governance) external onlyGovernance {
        _setGovernace(_governance);
    }

    function _setGovernace(address _governance) internal {
        governance = _governance;
    }
}

contract Governable is VanillaGovernable, Initializable {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}