// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/IBorrowerOperations.sol";
import "../Interfaces/IStabilityPool.sol";
import "../Interfaces/IBorrowerOperations.sol";
import "../Interfaces/ITroveManager.sol";
import "../Interfaces/IYUSDToken.sol";
import "../Interfaces/ISortedTroves.sol";
import "../Interfaces/ICommunityIssuance.sol";
import "../Interfaces/IYetiController.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IYetiVaultToken.sol";
import "../Interfaces/IYetiLever.sol";
import "../Dependencies/PoolBase.sol";
import "../Dependencies/SafeMath.sol";
import "../Dependencies/YetiSafeMath128.sol";
import "../Dependencies/SafeERC20.sol";
import "../Dependencies/ReentrancyGuardUpgradeable.sol";

// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&   ,[email protected]@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@&&&.,,      ,,**.&&&&&@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@,               ..,,,,,,,,,&@@@@@@@@@@
// @@@@@@,,,,,,&@@@@@@@@&                       ,,,,,&@@@@@@@@@
// @@@&,,,,,,,,@@@@@@@@@                        ,,,,,*@@@/@@@@@
// @@,*,*,*,*#,,*,&@@@@@   $$          $$       *,,,  ***&@@@@@
// @&***********(@@@@@@&   $$          $$       ,,,%&. & %@@@@@
// @(*****&**     &@@@@#                        *,,%  ,#%@*&@@@
// @... &             &                         **,,*&,(@*,*,&@
// @&,,.              &                         *,*       **,,@
// @@@,,,.            *                         **         ,*,,
// @@@@@,,,...   .,,,,&                        .,%          *,*
// @@@@@@@&/,,,,,,,,,,,,&,,,,,.         .,,,,,,,,.           *,
// @@@@@@@@@@@@&&@(,,,,,(@&&@@&&&&&%&&&&&%%%&,,,&            .(
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&,,,,,,,,,,,,,,&             &
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/,,,,,,,,,,,,&             &
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/            &             &
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&              &             &
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&      ,,,@@@&  &  &&  .&( &#%
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&&&&&%#**@@@&*&*******,,,,,**
//
//  $$\     $$\          $$\     $$\       $$$$$$$$\ $$\                                                   
//  \$$\   $$  |         $$ |    \__|      $$  _____|\__|                                                  
//   \$$\ $$  /$$$$$$\ $$$$$$\   $$\       $$ |      $$\ $$$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$$\  $$$$$$\  
//    \$$$$  /$$  __$$\\_$$  _|  $$ |      $$$$$\    $$ |$$  __$$\  \____$$\ $$  __$$\ $$  _____|$$  __$$\ 
//     \$$  / $$$$$$$$ | $$ |    $$ |      $$  __|   $$ |$$ |  $$ | $$$$$$$ |$$ |  $$ |$$ /      $$$$$$$$ |
//      $$ |  $$   ____| $$ |$$\ $$ |      $$ |      $$ |$$ |  $$ |$$  __$$ |$$ |  $$ |$$ |      $$   ____|
//      $$ |  \$$$$$$$\  \$$$$  |$$ |      $$ |      $$ |$$ |  $$ |\$$$$$$$ |$$ |  $$ |\$$$$$$$\ \$$$$$$$\ 
//      \__|   \_______|  \____/ \__|      \__|      \__|\__|  \__| \_______|\__|  \__| \_______| \_______|

/**
 * @title The Stability Pool holds YUSD tokens deposited by Stability Pool depositors.
 * @dev When a trove is liquidated, then depending on system conditions, some of its YUSD debt gets offset with
 * YUSD in the Stability Pool: that is, the offset debt evaporates, and an equal amount of YUSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a YUSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive an Collateral gain, as the amount of collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total YUSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 *
 * --- IMPLEMENTATION ---
 *
 * We use a highly scalable method of tracking deposits and Collateral gains that has O(1) complexity.
 *
 * When a liquidation occurs, rather than updating each depositor's deposit and Collateral gain, we simply update two state variables:
 * a product P, and a sum S. These are kept track for each type of collateral.
 *
 * A mathematical manipulation allows us to factor out the initial deposit, and accurately track all depositors' compounded deposits
 * and accumulated Collateral amount gains over time, as liquidations occur, using just these two variables P and S. When depositors join the
 * Stability Pool, they get a snapshot of the latest P and S: P_t and S_t, respectively.
 *
 * The formula for a depositor's accumulated Collateral amount gain is derived here:
 * https://github.com/liquity/dev/blob/main/packages/contracts/mathProofs/Scalable%20Compounding%20Stability%20Pool%20Deposits.pdf
 *
 * For a given deposit d_t, the ratio P/P_t tells us the factor by which a deposit has decreased since it joined the Stability Pool,
 * and the term d_t * (S - S_t)/P_t gives us the deposit's total accumulated Collateral amount gain.
 *
 * Each liquidation updates the product P and sum S. After a series of liquidations, a compounded deposit and corresponding Collateral amount gain
 * can be calculated using the initial deposit, the depositor’s snapshots of P and S, and the latest values of P and S.
 *
 * Any time a depositor updates their deposit (withdrawal, top-up) their accumulated Collateral amount gain is paid out, their new deposit is recorded
 * (based on their latest compounded deposit and modified by the withdrawal/top-up), and they receive new snapshots of the latest P and S.
 * Essentially, they make a fresh deposit that overwrites the old one.
 *
 *
 * --- SCALE FACTOR ---
 *
 * Since P is a running product in range ]0,1] that is always-decreasing, it should never reach 0 when multiplied by a number in range ]0,1[.
 * Unfortunately, Solidity floor division always reaches 0, sooner or later.
 *
 * A series of liquidations that nearly empty the Pool (and thus each multiply P by a very small number in range ]0,1[ ) may push P
 * to its 18 digit decimal limit, and round it to 0, when in fact the Pool hasn't been emptied: this would break deposit tracking.
 *
 * So, to track P accurately, we use a scale factor: if a liquidation would cause P to decrease to <1e-9 (and be rounded to 0 by Solidity),
 * we first multiply P by 1e9, and increment a currentScale factor by 1.
 *
 * The added benefit of using 1e9 for the scale factor (rather than 1e18) is that it ensures negligible precision loss close to the
 * scale boundary: when P is at its minimum value of 1e9, the relative precision loss in P due to floor division is only on the
 * order of 1e-9.
 *
 * --- EPOCHS ---
 *
 * Whenever a liquidation fully empties the Stability Pool, all deposits should become 0. However, setting P to 0 would make P be 0
 * forever, and break all future reward calculations.
 *
 * So, every time the Stability Pool is emptied by a liquidation, we reset P = 1 and currentScale = 0, and increment the currentEpoch by 1.
 *
 * --- TRACKING DEPOSIT OVER SCALE CHANGES AND EPOCHS ---
 *
 * When a deposit is made, it gets snapshots of the currentEpoch and the currentScale.
 *
 * When calculating a compounded deposit, we compare the current epoch to the deposit's epoch snapshot. If the current epoch is newer,
 * then the deposit was present during a pool-emptying liquidation, and necessarily has been depleted to 0.
 *
 * Otherwise, we then compare the current scale to the deposit's scale snapshot. If they're equal, the compounded deposit is given by d_t * P/P_t.
 * If it spans one scale change, it is given by d_t * P/(P_t * 1e9). If it spans more than one scale change, we define the compounded deposit
 * as 0, since it is now less than 1e-9'th of its initial value (e.g. a deposit of 1 billion YUSD has depleted to < 1 YUSD).
 *
 *
 *  --- TRACKING DEPOSITOR'S COLLATERAL AMOUNT GAIN OVER SCALE CHANGES AND EPOCHS ---
 *
 * In the current epoch, the latest value of S is stored upon each scale change, and the mapping (scale -> S) is stored for each epoch.
 *
 * This allows us to calculate a deposit's accumulated Collateral amount gain, during the epoch in which the deposit was non-zero and earned Collateral amount.
 *
 * We calculate the depositor's accumulated Collateral amount gain for the scale at which they made the deposit, using the Collateral amount gain formula:
 * e_1 = d_t * (S - S_t) / P_t
 *
 * and also for scale after, taking care to divide the latter by a factor of 1e9:
 * e_2 = d_t * S / (P_t * 1e9)
 *
 * The gain in the second scale will be full, as the starting point was in the previous scale, thus no need to subtract anything.
 * The deposit therefore was present for reward events from the beginning of that second scale.
 *
 *        S_i-S_t + S_{i+1}
 *      .<--------.------------>
 *      .         .
 *      . S_i     .   S_{i+1}
 *   <--.-------->.<----------->
 *   S_t.         .
 *   <->.         .
 *      t         .
 *  |---+---------|-------------|-----...
 *         i            i+1
 *
 * The sum of (e_1 + e_2) captures the depositor's total accumulated Collateral amount gain, handling the case where their
 * deposit spanned one scale change. We only care about gains across one scale change, since the compounded
 * deposit is defined as being 0 once it has spanned more than one scale change.
 *
 *
 * --- UPDATING P WHEN A LIQUIDATION OCCURS ---
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / Collateral amount gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 *
 * --- YETI ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An YETI issuance event occurs at every deposit operation, and every liquidation.
 *
 * All deposits earn a share of the issued YETI in proportion to the deposit as a share of total deposits.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#yeti-issuance-to-stability-providers
 *
 * We use the same mathematical product-sum approach to track YETI gains for depositors, where 'G' is the sum corresponding to YETI gains.
 * The product P (and snapshot P_t) is re-used, as the ratio P/P_t tracks a deposit's depletion due to liquidations.
 *
 */
contract StabilityPool is PoolBase, ReentrancyGuardUpgradeable, IStabilityPool {
    using YetiSafeMath128 for uint128;
    using SafeERC20 for IERC20;

    string public constant NAME = "StabilityPool";

    address internal troveManagerLiquidationsAddress;

    IBorrowerOperations internal borrowerOperations;
    ITroveManager internal troveManager;
    IYUSDToken internal yusdToken;
    ICommunityIssuance internal communityIssuance;
    // Needed to check if there are pending liquidations
    ISortedTroves internal sortedTroves;

    // Tracker for YUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
    uint256 internal totalYUSDDeposits;

    // totalColl.tokens and totalColl.amounts should be the same length and
    // always be the same length as controller.validCollaterals().
    // Anytime a new collateral is added to controller, both lists are lengthened
    newColls internal totalColl;

    // --- Data structures ---

    struct Snapshots {
        mapping(address => uint256) S;
        uint256 P;
        uint256 G;
        uint128 scale;
        uint128 epoch;
    }

    mapping(address => uint256) public deposits; // depositor address -> deposit amount

    /*
     * depositSnapshots maintains an entry for each depositor
     * that tracks P, S, G, scale, and epoch.
     * depositor's snapshot is updated only when they
     * deposit or withdraw from stability pool
     * depositSnapshots are used to allocate YETI rewards, calculate compoundedYUSDDepositAmount
     * and to calculate how much Collateral amount the depositor is entitled to
     */
    mapping(address => Snapshots) public depositSnapshots; // depositor address -> snapshots struct


    /*  Product 'P': Running product by which to multiply an initial deposit, in order to find the current compounded deposit,
     * after a series of liquidations have occurred, each of which cancel some YUSD debt with the deposit.
     *
     * During its lifetime, a deposit's value evolves from d_t to d_t * P / P_t , where P_t
     * is the snapshot of P taken at the instant the deposit was made. 18-digit decimal.
     */
    uint256 public P;

    uint256 public constant SCALE_FACTOR = 1e9;

    // Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
    uint128 public currentScale;

    // With each offset that fully empties the Pool, the epoch is incremented by 1
    uint128 public currentEpoch;

    /* Collateral amount Gain sum 'S': During its lifetime, each deposit d_t earns an Collateral amount gain of ( d_t * [S - S_t] )/P_t,
     * where S_t is the depositor's snapshot of S taken at the time t when the deposit was made.
     *
     * The 'S' sums are stored in a nested mapping (epoch => scale => sum):
     *
     * - The inner mapping records the (scale => sum)
     * - The middle mapping records (epoch => (scale => sum))
     * - The outer mapping records (collateralType => (epoch => (scale => sum)))
     */
    mapping(address => mapping(uint128 => mapping(uint128 => uint256))) public epochToScaleToSum;

    /*
     * Similarly, the sum 'G' is used to calculate YETI gains. During it's lifetime, each deposit d_t earns a YETI gain of
     *  ( d_t * [G - G_t] )/P_t, where G_t is the depositor's snapshot of G taken at time t when  the deposit was made.
     *
     *  YETI reward events occur are triggered by depositor operations (new deposit, topup, withdrawal), and liquidations.
     *  In each case, the YETI reward is issued (i.e. G is updated), before other state changes are made.
     */
    mapping(uint128 => mapping(uint128 => uint256)) public epochToScaleToG;

    // Error tracker for the error correction in the YETI issuance calculation
    uint256 public lastYETIError;
    // Error trackers for the error correction in the offset calculation
    uint256[] public lastAssetError_Offset;
    uint256 public lastYUSDLossError_Offset;

    // --- Events ---

    event StabilityPoolBalanceUpdated(address[] assets, uint256[] amounts);
    event StabilityPoolBalancesUpdated(address[] assets, uint256[] amounts);
    event StabilityPoolYUSDBalanceUpdated(uint256 _newBalance);

    event P_Updated(uint256 _P);
    event S_Updated(address _asset, uint256 _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint256 _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);


    event DepositSnapshotUpdated(address indexed _depositor, uint256 _P, uint256 _G);
    event UserDepositChanged(address indexed _depositor, uint256 _newDeposit);

    event GainsWithdrawn(
        address indexed _depositor,
        address[] _collaterals,
        uint256[] _amounts,
        uint256 _YUSDLoss
    );
    event YETIPaidToDepositor(address indexed _depositor, uint256 _YETI);
    event CollateralSent(address _to, address[] _collaterals, uint256[] _amounts);

    // --- Contract setters ---
    bool private addressSet;
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _yusdTokenAddress,
        address _sortedTrovesAddress,
        address _communityIssuanceAddress,
        address _controllerAddress,
        address _troveManagerLiquidationsAddress
    ) external override {
        require(addressSet == false, "Addresses already set");
        addressSet = true;
        __ReentrancyGuard_init();
        
        borrowerOperations = IBorrowerOperations(_borrowerOperationsAddress);
        troveManager = ITroveManager(_troveManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        yusdToken = IYUSDToken(_yusdTokenAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        communityIssuance = ICommunityIssuance(_communityIssuanceAddress);
        controller = IYetiController(_controllerAddress);
        P = DECIMAL_PRECISION;
        troveManagerLiquidationsAddress = _troveManagerLiquidationsAddress;
    }

    // --- Getters for public variables. Required by IPool interface ---

    /**
     * @notice Get total VC value of collateral in SP
     * @dev calls getVCColls which handles everything
     * @return VC of collateral in stability pool
     */
    function getVC() external view override returns (uint256) {
        return _getVCColls(totalColl);
    }

    /**
     * @notice get collateral balance in the SP for a given collateral type
     * @dev Not necessarily this contract's actual collateral balance;
     * just what is stored in state
     * @param _collateral address of the collateral to get amount of
     * @return amount of this specific collateral
     */
    function getCollateral(address _collateral) external view override returns (uint256) {
        uint256 collateralIndex = controller.getIndex(_collateral);
        return totalColl.amounts[collateralIndex];
    }

    /**
     * @notice getter function
     * @dev gets collateral from totalColl
     * This is not necessarily the contract's actual collateral balance;
     * just what is stored in state
     * @return tokens and amounts
     */
    function getAllCollateral() external view override returns (address[] memory, uint256[] memory) {
        return (totalColl.tokens, totalColl.amounts);
    }

    /**
     * @notice getter function
     * @dev gets total yusd from deposits
     * @return totalYUSDDeposits
     */
    function getTotalYUSDDeposits() external view override returns (uint256) {
        return totalYUSDDeposits;
    }

    // --- External Depositor Functions ---

    /**
     * @notice Used to provide YUSD to a stability Pool
     * @dev Triggers a YETI issuance, based on time passed since the last issuance.
     * The YETI issuance is shared between *all* depositors
     * - Sends depositor's accumulated gains (YETI, collateral assets) to depositor
     * - Increases deposit stake, and takes new snapshots for each.
     * @param _amount amount of asset provided
     */
    function provideToSP(uint256 _amount) external override nonReentrant {
        _requireNonZeroAmount(_amount);

        uint256 initialDeposit = deposits[msg.sender];

        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerYETIIssuance(communityIssuanceCached);

        (address[] memory assets, uint256[] memory amounts) = getDepositorGains(msg.sender);
        uint256 compoundedYUSDDeposit = getCompoundedYUSDDeposit(msg.sender);
        uint256 YUSDLoss = initialDeposit.sub(compoundedYUSDDeposit); // Needed only for event log

        // First pay out any YETI gains
        _payOutYETIGains(communityIssuanceCached, msg.sender);

        // just pulls YUSD into the pool, updates totalYUSDDeposits variable for the stability pool
        // and throws an event
        _sendYUSDtoStabilityPool(msg.sender, _amount);

        uint256 newDeposit = compoundedYUSDDeposit.add(_amount);
        _updateDepositAndSnapshots(msg.sender, newDeposit);
        emit UserDepositChanged(msg.sender, newDeposit);

        emit GainsWithdrawn(msg.sender, assets, amounts, YUSDLoss); // YUSD Loss required for event log

        // send any collateral gains accrued to the depositor
        _sendGainsToDepositor(msg.sender, assets, amounts);
    }

    /**
     * @notice withdraw your position from a stability Pool
     * @dev Triggers a YETI issuance, based on time passed since the last issuance. The YETI issuance is shared between *all* depositors
     * - Sends all depositor's accumulated gains (YETI, collateral assets) to depositor
     * - Decreases deposit and takes new snapshots.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     * Users can execute a withdrawal with _amount = 0 to simply acquire
     * any pending Collateral Gains and YETI gains from your SP deposit.
     * @param _amount Amount to withdraw
     */
    function withdrawFromSP(uint256 _amount) external override nonReentrant {
        (address[] memory assets, uint256[] memory amounts) = _withdrawFromSP(_amount);
        _sendGainsToDepositor(msg.sender, assets, amounts);
    }

    /**
     * @notice withdraw from a stability pool
     * @dev see withdrawFromSPAndSwap
     * @param _amount amount to withdraw
     * @return assets , amounts address of assets withdrawn, amount of asset withdrawn
     */
    function _withdrawFromSP(uint256 _amount)
        internal
        returns (address[] memory assets, uint256[] memory amounts)
    {
        if (_amount != 0) {
            _requireNoUnderCollateralizedTroves();
        }
        uint256 initialDeposit = deposits[msg.sender];
        _requireUserHasDeposit(initialDeposit);

        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerYETIIssuance(communityIssuanceCached);

        (assets, amounts) = getDepositorGains(msg.sender);

        uint256 compoundedYUSDDeposit = getCompoundedYUSDDeposit(msg.sender);

        uint256 YUSDtoWithdraw = YetiMath._min(_amount, compoundedYUSDDeposit);
        uint256 YUSDLoss = initialDeposit.sub(compoundedYUSDDeposit); // Needed only for event log

        // First pay out any YETI gains
        _payOutYETIGains(communityIssuanceCached, msg.sender);

        _sendYUSDToDepositor(msg.sender, YUSDtoWithdraw);

        // Update deposit
        uint256 newDeposit = compoundedYUSDDeposit.sub(YUSDtoWithdraw);
        _updateDepositAndSnapshots(msg.sender, newDeposit);
        emit UserDepositChanged(msg.sender, newDeposit);

        emit GainsWithdrawn(msg.sender, assets, amounts, YUSDLoss); // YUSD Loss required for event log
    }

    /**
     * @notice Claim rewards and swap to YUSD. Does not swap YETI rewards to YUSD.
     * @dev Triggers a YETI issuance, based on time passed since the last issuance. The YETI issuance is shared between *all* depositors
     * - Sends all depositor's accumulated gains (YETI, collateral assets) to depositor
     * - For these collateral asset rewards, they are first swapped to YUSD first
     *   and then sent back to the user
     * @param _yusdMinAmountTotal YUSD min amount from all swaps to receive
     */
    function claimRewardsSwap(uint256 _yusdMinAmountTotal)
        external
        override
        nonReentrant
        returns (uint256 amountFromSwap)
    {
        // issues YETI and gets asset rewards for the msg.sender's SP deposit
        (address[] memory assets, uint256[] memory amounts) = _withdrawFromSP(0);
        // swaps all collateral rewards to YUSD and sends back to msg.sender
        amountFromSwap = _sendGainsToDepositorSwap(assets, amounts);
        require(amountFromSwap >= _yusdMinAmountTotal, "SP:Insufficient YUSD Transferred");
    }

    // --- YETI issuance functions ---
    /**
     * @notice triggers Yeti issuance
     * @dev Updates G and issues Yeti
     * @param _communityIssuance is the contract to issue Yeti
     */
    function _triggerYETIIssuance(ICommunityIssuance _communityIssuance) internal {
        uint256 YETIIssuance = _communityIssuance.issueYETI();
        _updateG(YETIIssuance);
    }

    /**
     * @notice Updates for yeti issuance
     * @dev When total deposits is 0, G is not updated. In this case, the YETI issued can not be obtained by later
     * depositors - it is missed out on, and remains in the balanceof the CommunityIssuance contract.
     * @param _YETIIssuance amount of yeti to issue
     */
    function _updateG(uint256 _YETIIssuance) internal {
        uint256 totalYUSD = totalYUSDDeposits; // cached to save an SLOAD
        if (totalYUSD == 0 || _YETIIssuance == 0) {
            return;
        }

        uint256 YETIPerUnitStaked = _computeYETIPerUnitStaked(_YETIIssuance, totalYUSD);

        uint256 marginalYETIGain = YETIPerUnitStaked.mul(P);
        epochToScaleToG[currentEpoch][currentScale] = epochToScaleToG[currentEpoch][currentScale]
            .add(marginalYETIGain);

        emit G_Updated(epochToScaleToG[currentEpoch][currentScale], currentEpoch, currentScale);
    }

    /**
     * @notice computeYETIPerUnitStaked
     * @dev Calculate the YETI-per-unit staked.  Division uses a "feedback" error correction, to keep the
     * cumulative error low in the running total G:
     *
     * 1) Form a numerator which compensates for the floor division error that occurred the last time this
     * function was called.
     * 2) Calculate "per-unit-staked" ratio.
     * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
     * 4) Store this error for use in the next correction when this function is called.
     * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
     * @param _YETIIssuance amount of yeti to issue
     * @param _totalYUSDDeposits Amount of YUSD to deposit
     * @return Yeti per unit staked
     */
    function _computeYETIPerUnitStaked(uint256 _YETIIssuance, uint256 _totalYUSDDeposits)
        internal
        returns (uint256)
    {
        uint256 YETINumerator = _YETIIssuance.mul(DECIMAL_PRECISION).add(lastYETIError);

        uint256 YETIPerUnitStaked = YETINumerator.div(_totalYUSDDeposits);
        lastYETIError = YETINumerator.sub(YETIPerUnitStaked.mul(_totalYUSDDeposits));

        return YETIPerUnitStaked;
    }

    // --- Liquidation functions ---

    /**
     * @notice sets the offset for liquidation
     * @dev Cancels out the specified debt against the YUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     * @param _debtToOffset how much debt to offset
     * @param _tokens array of token addresses
     * @param _amountsAdded array of amounts as uint256
     */
    function offset(
        uint256 _debtToOffset,
        address[] memory _tokens,
        uint256[] memory _amountsAdded
    ) external override {
        _requireCallerIsTML();
        uint256 totalYUSD = totalYUSDDeposits; // cached to save an SLOAD
        if (totalYUSD == 0 || _debtToOffset == 0) {
            return;
        }

        _triggerYETIIssuance(communityIssuance);

        (
            uint256[] memory AssetGainPerUnitStaked,
            uint256 YUSDLossPerUnitStaked
        ) = _computeRewardsPerUnitStaked(_tokens, _amountsAdded, _debtToOffset, totalYUSD);

        _updateRewardSumAndProduct(_tokens, AssetGainPerUnitStaked, YUSDLossPerUnitStaked); // updates S and P
        _moveOffsetCollAndDebt(_tokens, _amountsAdded, _debtToOffset);
    }

    // --- Offset helper functions ---

    /**
     * @notice Compute the YUSD and Collateral amount rewards. Uses a "feedback" error correction, to keep
     * the cumulative error in the P and S state variables low:
     *
     * @dev 1) Form numerators which compensate for the floor division errors that occurred the last time this
     * function was called.
     * 2) Calculate "per-unit-staked" ratios.
     * 3) Multiply each ratio back by its denominator, to reveal the current floor division error.
     * 4) Store these errors for use in the next correction when this function is called.
     * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
     * @param _tokens Address of tokens
     * @param _amountsAdded array of amounts as uint256
     * @param _debtToOffset amount of debt to offset
     * @param _totalYUSDDeposits How much user has deposited
     */
    function _computeRewardsPerUnitStaked(
        address[] memory _tokens,
        uint256[] memory _amountsAdded,
        uint256 _debtToOffset,
        uint256 _totalYUSDDeposits
    ) internal returns (uint256[] memory AssetGainPerUnitStaked, uint256 YUSDLossPerUnitStaked) {
        uint256 amountsLen = _amountsAdded.length;
        uint256[] memory CollateralNumerators = new uint256[](amountsLen);
        uint256 currentP = P;

        uint256[] memory indices = controller.getIndices(_tokens);
        for (uint256 i; i < amountsLen; ++i) {
            CollateralNumerators[i] = _amountsAdded[i].mul(DECIMAL_PRECISION).add(
                lastAssetError_Offset[indices[i]]
            );
        }

        require(_debtToOffset <= _totalYUSDDeposits, "SP:This debt less than totalYUSD");
        if (_debtToOffset == _totalYUSDDeposits) {
            YUSDLossPerUnitStaked = DECIMAL_PRECISION; // When the Pool depletes to 0, so does each deposit
            lastYUSDLossError_Offset = 0;
        } else {
            uint256 YUSDLossNumerator = _debtToOffset.mul(DECIMAL_PRECISION).sub(
                lastYUSDLossError_Offset
            );
            /*
             * Add 1 to make error in quotient positive. We want "slightly too much" YUSD loss,
             * which ensures the error in any given compoundedYUSDDeposit favors the Stability Pool.
             */
            YUSDLossPerUnitStaked = (YUSDLossNumerator.div(_totalYUSDDeposits)).add(1);
            lastYUSDLossError_Offset = (YUSDLossPerUnitStaked.mul(_totalYUSDDeposits)).sub(
                YUSDLossNumerator
            );
        }

        AssetGainPerUnitStaked = new uint256[](_amountsAdded.length);
        for (uint256 i; i < amountsLen; ++i) {
            AssetGainPerUnitStaked[i] = CollateralNumerators[i].mul(currentP).div(
                _totalYUSDDeposits
            );
        }

        for (uint256 i; i < amountsLen; ++i) {
            lastAssetError_Offset[indices[i]] = CollateralNumerators[i].sub(
                AssetGainPerUnitStaked[i].mul(_totalYUSDDeposits).div(currentP)
            );
        }
    }

    /**
     * @notice Update the Stability Pool reward sum S and product P
     * @dev The newProductFactor is the factor by which to change all deposits
     * due to the depletion of Stability Pool YUSD in the liquidation.
     * We make the product factor 0 if there was a pool-emptying. Otherwise, it is (1 - YUSDLossPerUnitStaked)
     * @param _assets array of addresses
     * @param _AssetGainPerUnitStaked array of uint256 gains per staked YUSD
     * @param _YUSDLossPerUnitStaked amount of loss per unit
     */
    function _updateRewardSumAndProduct(
        address[] memory _assets,
        uint256[] memory _AssetGainPerUnitStaked,
        uint256 _YUSDLossPerUnitStaked
    ) internal {
        uint256 currentP = P;
        uint256 newP;

        require(_YUSDLossPerUnitStaked <= DECIMAL_PRECISION, "SP: YUSDLoss < 1");
        /*
         *
         */
        uint256 newProductFactor = uint256(DECIMAL_PRECISION).sub(_YUSDLossPerUnitStaked);

        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;

        /*
         * Calculate the new S first, before we update P.
         * The Collateral amount gain for any given depositor from a liquidation depends on the value of their deposit
         * (and the value of totalDeposits) prior to the Stability being depleted by the debt in the liquidation.
         *
         * Since S corresponds to Collateral amount gain, and P to deposit loss, we update S first.
         */
        uint256 assetsLen = _assets.length;
        for (uint256 i; i < assetsLen; ++i) {
            address asset = _assets[i];

            uint256 currentAssetS = epochToScaleToSum[asset][currentEpochCached][currentScaleCached];
            uint256 newAssetS = currentAssetS.add(_AssetGainPerUnitStaked[i]);

            epochToScaleToSum[asset][currentEpochCached][currentScaleCached] = newAssetS;
            emit S_Updated(asset, newAssetS, currentEpochCached, currentScaleCached);
        }

        // If the Stability Pool was emptied, increment the epoch, and reset the scale and product P
        if (newProductFactor == 0) {
            currentEpoch = currentEpochCached.add(1);
            emit EpochUpdated(currentEpoch);
            currentScale = 0;
            emit ScaleUpdated(currentScale);
            newP = DECIMAL_PRECISION;

            // If multiplying P by a non-zero product factor would reduce P below the scale boundary, increment the scale
        } else if (currentP.mul(newProductFactor).div(DECIMAL_PRECISION) < SCALE_FACTOR) {
            newP = currentP.mul(newProductFactor).mul(SCALE_FACTOR).div(DECIMAL_PRECISION);
            currentScale = currentScaleCached.add(1);
            emit ScaleUpdated(currentScale);
        } else {
            newP = currentP.mul(newProductFactor).div(DECIMAL_PRECISION);
        }

        require(newP != 0, "SP: P = 0");
        P = newP;
        emit P_Updated(newP);
    }

    /**
     * @notice Internal function to move offset collateral and debt between pools.
     * @dev Cancel the liquidated YUSD debt with the YUSD in the stability pool,
     * Burn the debt that was successfully offset. Collateral is moved from
     * the ActivePool to this contract.
     * @param _collsToAdd array of addresses
     * @param _amountsToAdd array of uint256
     * @param _debtToOffset uint256
     */
    function _moveOffsetCollAndDebt(
        address[] memory _collsToAdd,
        uint256[] memory _amountsToAdd,
        uint256 _debtToOffset
    ) internal {
        IActivePool activePoolCached = activePool;
        activePoolCached.decreaseYUSDDebt(_debtToOffset);
        _decreaseYUSD(_debtToOffset);

        yusdToken.burn(address(this), _debtToOffset);

        activePoolCached.sendCollaterals(address(this), _collsToAdd, _amountsToAdd);
    }

    /**
     * @notice Decreases YUSD Stability pool balance.
     * @dev Used on offset and on withdraw; Also throws an event.
     * @param _amount uint256 of YUSD to decrease totalYUSDDeposits by.
     */
    function _decreaseYUSD(uint256 _amount) internal {
        uint256 newTotalYUSDDeposits = totalYUSDDeposits.sub(_amount);
        totalYUSDDeposits = newTotalYUSDDeposits;
        emit StabilityPoolYUSDBalanceUpdated(newTotalYUSDDeposits);
    }

    // --- Reward calculator functions for depositor ---

    /**
     * @notice Calculates the gains earned by the deposit since its last snapshots were taken.
     * @dev Given by the formula:  E = d0 * (S - S(0))/P(0)
     * where S(0) and P(0) are the depositor's snapshots of the sum S and product P, respectively.
     * d0 is the last recorded deposit value.
     * @param _depositor address of depositor in question
     * @return assets, amounts
     */
    function getDepositorGains(address _depositor)
        public
        view
        override
        returns (address[] memory, uint256[] memory)
    {
        uint256 initialDeposit = deposits[_depositor];

        if (initialDeposit == 0) {
            address[] memory emptyAddress = new address[](0);
            uint256[] memory emptyUint = new uint256[](0);
            return (emptyAddress, emptyUint);
        }

        Snapshots storage snapshots = depositSnapshots[_depositor];

        return _calculateGains(initialDeposit, snapshots);
    }

    /**
     * @notice get gains on each possible asset by looping through
     * @dev assets with _getGainFromSnapshots function
     * @param initialDeposit Amount of initial deposit
     * @param snapshots struct snapshots
     */
    function _calculateGains(uint256 initialDeposit, Snapshots storage snapshots)
        internal
        view
        returns (address[] memory assets, uint256[] memory amounts)
    {
        assets = controller.getValidCollateral();
        uint256 assetsLen = assets.length;
        amounts = new uint256[](assetsLen);
        for (uint256 i; i < assetsLen; ++i) {
            amounts[i] = _getGainFromSnapshots(initialDeposit, snapshots, assets[i]);
        }
    }

    /**
     * @notice gets the gain in S for a given asset
     * @dev for a user who deposited initialDeposit
     * @param initialDeposit Amount of initialDeposit
     * @param snapshots struct snapshots
     * @param asset asset to gain snapshot
     * @return uint256 the gain
     */
    function _getGainFromSnapshots(
        uint256 initialDeposit,
        Snapshots storage snapshots,
        address asset
    ) internal view returns (uint256) {
        /*
         * Grab the sum 'S' from the epoch at which the stake was made. The Collateral amount gain may span up to one scale change.
         * If it does, the second portion of the Collateral amount gain is scaled by 1e9.
         * If the gain spans no scale change, the second portion will be 0.
         */
        uint256 S_Snapshot = snapshots.S[asset];
        uint256 P_Snapshot = snapshots.P;

        uint256 firstPortion = epochToScaleToSum[asset][snapshots.epoch][snapshots.scale].sub(
            S_Snapshot
        );
        uint256 secondPortion = epochToScaleToSum[asset][snapshots.epoch][snapshots.scale.add(1)]
            .div(SCALE_FACTOR);

        uint256 assetGain = initialDeposit.mul(firstPortion.add(secondPortion)).div(P_Snapshot).div(
            DECIMAL_PRECISION
        );

        return assetGain;
    }

    /**
     * @notice Calculate the YETI gain earned by a deposit since its last snapshots were taken.
     * @dev Given by the formula:  YETI = d0 * (G - G(0))/P(0)
     * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
     * d0 is the last recorded deposit value.
     * @param _depositor Address
     * @return uint256
     */
    function getDepositorYETIGain(address _depositor) public view override returns (uint256) {
        uint256 initialDeposit = deposits[_depositor];
        if (initialDeposit == 0) {
            return 0;
        }
        Snapshots storage snapshots = depositSnapshots[_depositor];

        return _getYETIGainFromSnapshots(initialDeposit, snapshots);
    }


    /**
     * @notice Grab the sum 'G' from the epoch at which the stake was made. The YETI gain may span up to one scale change.
     * @dev If it does, the second portion of the YETI gain is scaled by 1e9.
     * If the gain spans no scale change, the second portion will be 0.
     * @param initialStake uint256
     * @param snapshots struct Snapshots
     * @return uint256
     */
    function _getYETIGainFromSnapshots(uint256 initialStake, Snapshots storage snapshots)
        internal
        view
        returns (uint256)
    {
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint256 G_Snapshot = snapshots.G;
        uint256 P_Snapshot = snapshots.P;

        uint256 firstPortion = epochToScaleToG[epochSnapshot][scaleSnapshot].sub(G_Snapshot);
        uint256 secondPortion = epochToScaleToG[epochSnapshot][scaleSnapshot.add(1)].div(
            SCALE_FACTOR
        );

        uint256 YETIGain = initialStake.mul(firstPortion.add(secondPortion)).div(P_Snapshot).div(
            DECIMAL_PRECISION
        );

        return YETIGain;
    }

    // --- Compounded deposit stake ---

    /**
     * @notice Return the user's compounded deposit. Given by the formula:  d = d0 * P/P(0)
     * where P(0) is the depositor's snapshot of the product P, taken when they last updated their deposit.
     * @dev see notice
     * @param _depositor address
     * @return uint256
     */
    function getCompoundedYUSDDeposit(address _depositor) public view override returns (uint256) {
        uint256 initialDeposit = deposits[_depositor];
        if (initialDeposit == 0) {
            return 0;
        }

        Snapshots storage snapshots = depositSnapshots[_depositor];

        uint256 compoundedDeposit = _getCompoundedStakeFromSnapshots(initialDeposit, snapshots);
        return compoundedDeposit;
    }


    /**
     * @notice Internal function, used to calculate compounded deposit stakes.
     * @dev returns 0 if the snapshots were taken prior to a a pool-emptying event
     * also returns zero if scaleDiff (currentScale.sub(scaleSnapshot)) is more than 2 or
     * If the scaleDiff is 0 or 1,
     * then adjust for changes in P and scale changes to calculate a compoundedStake.
     * IF the final compoundedStake isn't less than a billionth of the initial stake, return it.this
     * otherwise, just return 0.
     * @param initialStake uint256
     * @param snapshots Struct snapshots
     * @return uint256
     */
    function _getCompoundedStakeFromSnapshots(uint256 initialStake, Snapshots storage snapshots)
        internal
        view
        returns (uint256)
    {
        uint256 snapshot_P = snapshots.P;
        uint128 scaleSnapshot = snapshots.scale;
        uint128 epochSnapshot = snapshots.epoch;

        // If stake was made before a pool-emptying event, then it has been fully cancelled with debt -- so, return 0
        if (epochSnapshot < currentEpoch) {
            return 0;
        }

        uint256 compoundedStake;
        uint128 scaleDiff = currentScale.sub(scaleSnapshot);

        /* Compute the compounded stake. If a scale change in P was made during the stake's lifetime,
         * account for it. If more than one scale change was made, then the stake has decreased by a factor of
         * at least 1e-9 -- so return 0.
         */
        if (scaleDiff == 0) {
            compoundedStake = initialStake.mul(P).div(snapshot_P);
        } else if (scaleDiff == 1) {
            compoundedStake = initialStake.mul(P).div(snapshot_P).div(SCALE_FACTOR);
        } else {
            // if scaleDiff >= 2
            compoundedStake = 0;
        }

        /*
         * If compounded deposit is less than a billionth of the initial deposit, return 0.
         *
         * NOTE: originally, this line was in place to stop rounding errors making the deposit too large. However, the error
         * corrections should ensure the error in P "favors the Pool", i.e. any given compounded deposit should slightly less
         * than it's theoretical value.
         *
         * Thus it's unclear whether this line is still really needed.
         */
        if (compoundedStake < initialStake.div(1e9)) {
            return 0;
        }

        return compoundedStake;
    }

    // --- Sender functions for YUSD deposit, Collateral gains and YETI gains ---

    /**
     * @notice Transfer the YUSD tokens from the user to the Stability Pool's address, and update its recorded YUSD
     * @dev see notice
     * @param _address Sender of YUSD
     * @param _amount uint256
     */
    function _sendYUSDtoStabilityPool(address _address, uint256 _amount) internal {
        yusdToken.sendToPool(_address, address(this), _amount);
        uint256 newTotalYUSDDeposits = totalYUSDDeposits.add(_amount);
        totalYUSDDeposits = newTotalYUSDDeposits;
        emit StabilityPoolYUSDBalanceUpdated(newTotalYUSDDeposits);
    }

    /**
     * @notice transfer collateral gains to the depositor
     * @dev this function also unwraps wrapped assets
     * before sending to depositor
     * @param _to address
     * @param assets array of address
     * @param amounts array of uint256
     */
    function _sendGainsToDepositor(
        address _to,
        address[] memory assets,
        uint256[] memory amounts
    ) internal {
        uint256 assetsLen = assets.length;
        require(assetsLen == amounts.length, "SP:Length mismatch");
        IYetiController controllerCached = controller;
        for (uint256 i; i < assetsLen; ++i) {
            uint256 amount = amounts[i];
            if (amount == 0) {
                continue;
            }
            address asset = assets[i];
            if (controllerCached.isWrapped(asset)) {
                // Unwraps wrapped tokens and sends back underlying tokens to depositor
                // for vault tokens, _amounts[i] is in terms of the vault token, and
                // the user will receive back the underlying based on the current exchange rate
                IYetiVaultToken(asset).redeem(_to, amount);
            } else {
                IERC20(asset).safeTransfer(_to, amount);
            }
        }
        totalColl.amounts = _leftSubColls(totalColl, assets, amounts);
    }

    /**
     * @notice Sends gains to depositor after swapping to YUSD.
     * @dev Intended for SP withdraw and swap function, to use default router to perform swap and withdraw.
     * @param assets array of address
     * @param amounts array of uint256
     */
    function _sendGainsToDepositorSwap(address[] memory assets, uint256[] memory amounts)
        internal
        returns (uint256 totalYUSD)
    {
        uint256 assetsLen = assets.length;
        require(assetsLen == amounts.length, "SP:Length mismatch");
        IYUSDToken yusdTokenCached = yusdToken;
        uint256 balanceBefore = yusdTokenCached.balanceOf(msg.sender);
        for (uint256 i; i < assetsLen; ++i) {
            uint256 amount = amounts[i];
            if (amount == 0) {
                continue;
            }
            address asset = assets[i];
            address router = controller.getDefaultRouterAddress(asset);
            // Whether or not it is wrapped, the router will handle the potential unwrapping. The 
            // Final unwrapped token will be sent back to this contract to handle that situation. 
            IERC20(asset).safeTransfer(router, amount);
            totalYUSD = totalYUSD.add(
                IYetiLever(router).unRoute(
                    msg.sender,
                    asset,
                    address(yusdTokenCached),
                    amount,
                    1
                )
            );
        }
        require(
            yusdTokenCached.balanceOf(msg.sender) == balanceBefore.add(totalYUSD),
            "SP:unRoute Failed"
        );
        totalColl.amounts = _leftSubColls(totalColl, assets, amounts);
    }

    /**
     * @notice Send YUSD to user and decrease YUSD in Pool
     * @dev see notice
     * @param _depositor address
     * @param YUSDWithdrawal uint256
     */
    function _sendYUSDToDepositor(address _depositor, uint256 YUSDWithdrawal) internal {
        if (YUSDWithdrawal == 0) {
            return;
        }

        yusdToken.returnFromPool(address(this), _depositor, YUSDWithdrawal);
        _decreaseYUSD(YUSDWithdrawal);
    }


    // --- Stability Pool Deposit Functionality ---


    /**
     * @notice updates deposit and snapshots internally
     * @dev if _newValue is zero, delete snapshot for given _depositor and emit event
     * otherwise, add an entry or update existing entry for _depositor in the depositSnapshots
     * with current values for P, S, G, scale and epoch and then emit event.
     * @param _depositor address
     * @param _newValue uint256
     */
    function _updateDepositAndSnapshots(address _depositor, uint256 _newValue) internal {
        deposits[_depositor] = _newValue;

        if (_newValue == 0) {
            address[] memory colls = controller.getValidCollateral();
            uint256 collsLen = colls.length;
            for (uint256 i; i < collsLen; ++i) {
                depositSnapshots[_depositor].S[colls[i]] = 0;
            }
            depositSnapshots[_depositor].P = 0;
            depositSnapshots[_depositor].G = 0;
            depositSnapshots[_depositor].epoch = 0;
            depositSnapshots[_depositor].scale = 0;
            emit DepositSnapshotUpdated(_depositor, 0, 0);
            return;
        }
        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint256 currentP = P;

        address[] memory allColls = controller.getValidCollateral();

        // Get S and G for the current epoch and current scale
        uint256 allCollsLen = allColls.length;
        for (uint256 i; i < allCollsLen; ++i) {
            address token = allColls[i];
            uint256 currentSForToken = epochToScaleToSum[token][currentEpochCached][
                currentScaleCached
            ];
            depositSnapshots[_depositor].S[token] = currentSForToken;
        }

        uint256 currentG = epochToScaleToG[currentEpochCached][currentScaleCached];

        // Record new snapshots of the latest running product P, sum S, and sum G, for the depositor
        depositSnapshots[_depositor].P = currentP;
        depositSnapshots[_depositor].G = currentG;
        depositSnapshots[_depositor].scale = currentScaleCached;
        depositSnapshots[_depositor].epoch = currentEpochCached;

        emit DepositSnapshotUpdated(_depositor, currentP, currentG);
    }


    /**
     * @notice pays yeti gains out to depositors
     * @dev see notice
     * @param _communityIssuance Interface
     * @param _depositor address
     */
    function _payOutYETIGains(
        ICommunityIssuance _communityIssuance,
        address _depositor
    ) internal {

        // Pay out depositor's YETI gain
        uint256 depositorYETIGain = getDepositorYETIGain(_depositor);
        _communityIssuance.sendYETI(_depositor, depositorYETIGain);
        emit YETIPaidToDepositor(_depositor, depositorYETIGain);
    }

    // --- 'require' functions ---
    /**
     * @notice check ICR of bottom trove in SortedTroves
     * as well as the under-collateralized troves list
     */
    function _requireNoUnderCollateralizedTroves() internal view {
        ISortedTroves sortedTrovesCached = sortedTroves;
        address lowestTrove = sortedTrovesCached.getLast();
        uint256 ICR = troveManager.getCurrentICR(lowestTrove);
        require(
            ICR >= MCR && sortedTrovesCached.getUnderCollateralizedTrovesSize() == 0,
            "SP: No Withdraw when there are under-collateralized troves"
        );
    }

    /**
     * @notice require nonzero deposit
     * @dev could be a modifier
     * @param _initialDeposit uint256
     */
    function _requireUserHasDeposit(uint256 _initialDeposit) internal pure {
        require(_initialDeposit != 0, "SP: require nonzero deposit");
    }

    /**
     * @notice make sure amount is nonzero
     * @dev see notice
     * @param _amount make sure amount is nonzero
     */
    function _requireNonZeroAmount(uint256 _amount) internal pure {
        require(_amount != 0, "SP: Amount must be non-zero");
    }

    /**
     * @notice Make sure caller is ActivePool
     * @dev see notice
     */
    function _requireCallerIsActivePool() internal view {
        if (msg.sender != address(activePool)) {
            _revertWrongFuncCaller();
        }
    }

    /**
     * @notice Make sure msg.sender is TroveManagerLiquidations Contract
     * @dev see notice
     */
    function _requireCallerIsTML() internal view {
        if (msg.sender != address(troveManagerLiquidationsAddress)) {
            _revertWrongFuncCaller();
        }
    }

    /**
     * @notice Should be called by ActivePool
     * @dev __after__ collateral is transferred to this contract from Active Pool
     * @param _tokens array of addresses
     * @param _amounts array of amounts
     */
    function receiveCollateral(address[] memory _tokens, uint256[] memory _amounts)
        external
        override
    {
        _requireCallerIsActivePool();
        totalColl.amounts = _leftSumColls(totalColl, _tokens, _amounts);
        emit StabilityPoolBalancesUpdated(_tokens, _amounts);
    }

    /**
     * @notice add a collateral
     * @dev should be called anytime a collateral is added to controller
     * keeps all arrays the correct length
     * @param _collateral address of collateral to add
     */
    function addCollateralType(address _collateral) external override {
        _requireCallerIsYetiController();
        lastAssetError_Offset.push(0);
        totalColl.tokens.push(_collateral);
        totalColl.amounts.push(0);
    }

    /**
     * @notice get deposit snapshot
     * @dev Gets reward snapshot S for certain collateral and depositor.
     * @param _depositor address of depositor
     * @param _collateral address of collateral
     * @return uint256
     */
    function getDepositSnapshotS(address _depositor, address _collateral)
        external
        view
        override
        returns (uint256)
    {
        return depositSnapshots[_depositor].S[_collateral];
    }


    /**
     * @notice get how much Yeti you would earn depositing _amount for _time
     * @dev this calculation is based on the rewardRate from CommunityIssuance
     * @param _amount amount of YUSD deposited
     * @param _time time in seconds it is deposited
     * @return uint256
     */
    function getEstimatedYETIPoolRewards(uint _amount, uint _time)
        external
        view
        override
        returns (uint256)
    {
        uint rewardRate = communityIssuance.getRewardRate();
        if (totalYUSDDeposits == 0) {
            return rewardRate.mul(_time);
        }
        return rewardRate.mul(_time).mul(_amount).div(totalYUSDDeposits);
    }


}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

// Common interface for the Trove Manager.
interface IBorrowerOperations {

    // --- Functions ---

    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _sortedTrovesAddress,
        address _yusdTokenAddress,
        address _controllerAddress
    ) external;

    function openTrove(uint _maxFeePercentage, uint _YUSDAmount, address _upperHint,
        address _lowerHint,
        address[] calldata _colls,
        uint[] calldata _amounts) external;

        function openTroveLeverUp(
        uint256 _maxFeePercentage,
        uint256 _YUSDAmount,
        address _upperHint,
        address _lowerHint,
        address[] memory _colls,
        uint256[] memory _amounts, 
        uint256[] memory _leverages,
        uint256[] memory _maxSlippages
    ) external;

    function closeTroveUnlever(
        address[] memory _collsOut,
        uint256[] memory _amountsOut,
        uint256[] memory _maxSlippages
    ) external;

    function closeTrove() external;

    function adjustTrove(
        address[] calldata _collsIn,
        uint[] calldata _amountsIn,
        address[] calldata _collsOut,
        uint[] calldata _amountsOut,
        uint _YUSDChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint,
        uint _maxFeePercentage) external;

    // function addColl(address[] memory _collsIn, uint[] memory _amountsIn, address _upperHint, address _lowerHint, uint _maxFeePercentage) external;

    function addCollLeverUp(
        address[] memory _collsIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256[] memory _maxSlippages,
        uint256 _YUSDAmount,
        address _upperHint,
        address _lowerHint, 
        uint256 _maxFeePercentage
    ) external;

    function withdrawCollUnleverUp(
        address[] memory _collsOut,
        uint256[] memory _amountsOut,
        uint256[] memory _maxSlippages,
        uint256 _YUSDAmount,
        address _upperHint,
        address _lowerHint
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./ICollateralReceiver.sol";

/*
 * The Stability Pool holds YUSD tokens deposited by Stability Pool depositors.
 *
 * When a trove is liquidated, then depending on system conditions, some of its YUSD debt gets offset with
 * YUSD in the Stability Pool:  that is, the offset debt evaporates, and an equal amount of YUSD tokens in the Stability Pool is burned.
 *
 * Thus, a liquidation causes each depositor to receive a YUSD loss, in proportion to their deposit as a share of total deposits.
 * They also receive an ETH gain, as the ETH collateral of the liquidated trove is distributed among Stability depositors,
 * in the same proportion.
 *
 * When a liquidation occurs, it depletes every deposit by the same fraction: for example, a liquidation that depletes 40%
 * of the total YUSD in the Stability Pool, depletes 40% of each deposit.
 *
 * A deposit that has experienced a series of liquidations is termed a "compounded deposit": each liquidation depletes the deposit,
 * multiplying it by some factor in range ]0,1[
 *
 * Please see the implementation spec in the proof document, which closely follows on from the compounded deposit / ETH gain derivations:
 * https://github.com/liquity/liquity/blob/master/papers/Scalable_Reward_Distribution_with_Compounding_Stakes.pdf
 *
 * --- YETI ISSUANCE TO STABILITY POOL DEPOSITORS ---
 *
 * An YETI issuance event occurs at every deposit operation, and every liquidation.
 *
 * Each deposit is tagged with the address of the front end through which it was made.
 *
 * All deposits earn a share of the issued YETI in proportion to the deposit as a share of total deposits. The YETI earned
 * by a given deposit, is split between the depositor and the front end through which the deposit was made, based on the front end's kickbackRate.
 *
 * Please see the system Readme for an overview:
 * https://github.com/liquity/dev/blob/main/README.md#yeti-issuance-to-stability-providers
 */
interface IStabilityPool is ICollateralReceiver {

    // --- Events ---
    
    event StabilityPoolETHBalanceUpdated(uint _newBalance);
    event StabilityPoolYUSDBalanceUpdated(uint _newBalance);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);


    event DepositSnapshotUpdated(address indexed _depositor, uint _P, uint _S, uint _G);
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);

    event ETHGainWithdrawn(address indexed _depositor, uint _ETH, uint _YUSDLoss);
    event YETIPaidToDepositor(address indexed _depositor, uint _YETI);
    event EtherSent(address _to, uint _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Yeti contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _yusdTokenAddress,
        address _sortedTrovesAddress,
        address _communityIssuanceAddress,
        address _controllerAddress,
        address _troveManagerLiquidationsAddress
    )
        external;

    /*
     * Initial checks:
     * - _amount is not zero
     * ---
     * - Triggers a YETI issuance, based on time passed since the last issuance. The YETI issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (YETI, ETH) to depositor
     * - Sends the tagged front end's accumulated YETI gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint _amount) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a YETI issuance, based on time passed since the last issuance. The YETI issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (YETI, ETH) to depositor
     * - Sends the tagged front end's accumulated YETI gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint _amount) external;

    function claimRewardsSwap(uint256 _yusdMinAmountTotal) external returns (uint256 amountFromSwap);


    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the YUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint _debt, address[] memory _assets, uint[] memory _amountsAdded) external;

//    /*
//     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
//     * to exclude edge cases like ETH received from a self-destruct.
//     */
//    function getETH() external view returns (uint);
    
     //*
//     * Calculates and returns the total gains a depositor has accumulated 
//     */
    function getDepositorGains(address _depositor) external view returns (address[] memory assets, uint[] memory amounts);


    /*
     * Returns the total amount of VC held by the pool, accounted for by multipliying the
     * internal balances of collaterals by the price that is found at the time getVC() is called.
     */
    function getVC() external view returns (uint);

    /*
     * Returns YUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalYUSDDeposits() external view returns (uint);

    /*
     * Calculate the YETI gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorYETIGain(address _depositor) external view returns (uint);


    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedYUSDDeposit(address _depositor) external view returns (uint);

    /*
     * Add collateral type to totalColl 
     */
    function addCollateralType(address _collateral) external;

    function getDepositSnapshotS(address depositor, address collateral) external view returns (uint);

    function getCollateral(address _collateral) external view returns (uint);

    function getAllCollateral() external view returns (address[] memory, uint256[] memory);

    function getEstimatedYETIPoolRewards(uint _amount, uint _time) external view returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./ILiquityBase.sol";
import "./IStabilityPool.sol";
import "./IYUSDToken.sol";
import "./IYETIToken.sol";
import "./IActivePool.sol";
import "./IDefaultPool.sol";


// Common interface for the Trove Manager.
interface ITroveManager is ILiquityBase {

    // --- Events ---

    event Redemption(uint _attemptedYUSDAmount, uint _actualYUSDAmount, uint YUSDfee, address[] tokens, uint[] amounts);
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(address token, uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_ETH, uint _L_YUSDDebt);
    event TroveSnapshotsUpdated(uint _L_ETH, uint _L_YUSDDebt);
    event TroveIndexUpdated(address _borrower, uint _newIndex);

    // --- Functions ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _sortedTrovesAddress,
        address _controllerAddress,
        address _troveManagerRedemptionsAddress,
        address _troveManagerLiquidationsAddress
    )
    external;

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index) external view returns (address);

    function getCurrentICR(address _borrower) external view returns (uint);

    function getCurrentAICR(address _borrower) external view returns (uint);

    function liquidate(address _borrower) external;

    function batchLiquidateTroves(address[] calldata _troveArray, address _liquidator) external;

    function redeemCollateral(
        uint _YUSDAmount,
        uint _YUSDMaxFee,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations
    ) external;

    function redeemCollateralSingle(
        uint256 _YUSDamount,
        uint256 _YUSDMaxFee,
        address _target, 
        address _upperHint, 
        address _lowerHint, 
        uint256 _hintAICR,
        address _collToRedeem
    ) external;

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower) external returns (uint index);

    function applyPendingRewards(address _borrower) external;

    function getPendingCollRewards(address _borrower) external view returns (address[] memory, uint[] memory);

    function getPendingYUSDDebtReward(address _borrower) external view returns (uint);

     function hasPendingRewards(address _borrower) external view returns (bool);

    function removeStakeAndCloseTrove(address _borrower) external;

    function updateTroveDebt(address _borrower, uint debt) external;

    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ETHDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint YUSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _YUSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowingAndCalculateFee(uint256 _YUSDDebt) external returns (uint);

    function getTroveStatus(address _borrower) external view returns (uint);

    function isTroveActive(address _borrower) external view returns (bool);

    function getTroveStake(address _borrower, address _token) external view returns (uint);

    function getTotalStake(address _token) external view returns (uint);

    function getTroveDebt(address _borrower) external view returns (uint);

    function getL_Coll(address _token) external view returns (uint);

    function getL_YUSD(address _token) external view returns (uint);

    function getRewardSnapshotColl(address _borrower, address _token) external view returns (uint);

    function getRewardSnapshotYUSD(address _borrower, address _token) external view returns (uint);

    function getTroveVC(address _borrower) external view returns (uint);

    function getTroveColls(address _borrower) external view returns (address[] memory, uint[] memory);

    function getCurrentTroveState(address _borrower) external view returns (address[] memory, uint[] memory, uint);

    function setTroveStatus(address _borrower, uint num) external;

    function updateTroveCollAndStakeAndTotalStakes(address _borrower, address[] memory _tokens, uint[] memory _amounts) external;

    function increaseTroveDebt(address _borrower, uint _debtIncrease) external returns (uint);

    function decreaseTroveDebt(address _borrower, uint _collDecrease) external returns (uint);

    function getTCR() external view returns (uint);

    function checkRecoveryMode() external view returns (bool);

    function closeTroveRedemption(address _borrower) external;

    function closeTroveLiquidation(address _borrower) external;

    function removeStake(address _borrower) external;

    function updateBaseRate(uint newBaseRate) external;

    function calcDecayedBaseRate() external view returns (uint);

    function redistributeDebtAndColl(IActivePool _activePool, IDefaultPool _defaultPool, uint _debt, address[] memory _tokens, uint[] memory _amounts) external;

    function updateSystemSnapshots_excludeCollRemainder(IActivePool _activePool, address[] memory _tokens, uint[] memory _amounts) external;

    function getEntireDebtAndColls(address _borrower) external view
    returns (uint, address[] memory, uint[] memory, uint, address[] memory, uint[] memory);

    function updateTroves(address[] calldata _borrowers, address[] calldata _lowerHints, address[] calldata _upperHints) external;

    function updateUnderCollateralizedTroves(address[] memory _ids) external;

    function getMCR() external view returns (uint256);

    function getCCR() external view returns (uint256);
    
    function getYUSD_GAS_COMPENSATION() external view returns (uint256);
    
    function getMIN_NET_DEBT() external view returns (uint256);
    
    function getBORROWING_FEE_FLOOR() external view returns (uint256);

    function getREDEMPTION_FEE_FLOOR() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/IERC20.sol";
import "../Interfaces/IERC2612.sol";

interface IYUSDToken is IERC20, IERC2612 {
    
    // --- Events ---

    event YUSDTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;

    function updateMinting(bool _canMint) external;

    function addValidMinter(address _newMinter) external;

    function removeValidMinter(address _minter) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

// Common interface for the SortedTroves Doubly Linked List.
interface ISortedTroves {

    // --- Functions ---
    
    function setParams(uint256 _size, address _TroveManagerAddress, address _borrowerOperationsAddress, address _troveManagerRedemptionsAddress, address _yetiControllerAddress) external;

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId, uint256 _feeAsPercentOfTotal) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function reInsertWithNewBoost(
        address _id,
        uint256 _newAICR,
        address _prevId,
        address _nextId,
        uint256 _feeAsPercentOfAddedVC, 
        uint256 _addedVCIn, 
        uint256 _VCBeforeAdjustment
    ) external ;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNode(address _id) external view returns (bool, address, address, uint256, uint256, uint256);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function getOldBoostedAICR(address _id) external view returns (uint256);

    function getTimeSinceBoostUpdated(address _id) external view returns (uint256);

    function getBoost(address _id) external view returns (uint256);

    function getDecayedBoost(address _id) external view returns (uint256);

    function getUnderCollateralizedTrovesSize() external view returns (uint256);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);

    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor) external;

    function changeGlobalBoostMultiplier(uint256 _newGlobalBoostMultiplier) external;

    function updateUnderCollateralizedTrove(address _id, bool _isUnderCollateralized) external;

    function reInsertMany(address[] memory _ids, uint256[] memory _newAICRs, address[] memory _prevIds, address[] memory _nextIds) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

interface ICommunityIssuance {

    // --- Events ---

    event NewYetiIssued(uint256 _amountIssued);
    event TotalYETIIssuedUpdated(uint256 _totalYetiIssued);
    event NewRewardRate(uint256 _newRewardRate, uint256 _time);
    event RewardPaid(address _user, uint256 _reward);

    // --- Functions ---

    function setAddresses(address _yetiTokenAddress, address _stabilityPoolAddress) external;

    function setRate(uint256 _newRewardRate) external;

    function issueYETI() external returns (uint256);

    function sendYETI(address _account, uint256 _YETIamount) external;

    function getRewardRate() external view returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;


interface IYetiController {

    // ======== Mutable Only Owner-Instantaneous ========
    function setAddresses(
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress,
        address _borrowerOperationsAddress,
        address _yusdTokenAddress,
        address _YUSDFeeRecipientAddress,
        address _yetiFinanceTreasury,
        address _sortedTrovesAddress,
        address _veYETIAddress,
        address _troveManagerRedemptionsAddress,
        address _claimAddress,
        address _threeDayTimelock,
        address _twoWeekTimelock
    ) external;
    function endBootstrap() external;
    function deprecateAllCollateral() external;
    function deprecateCollateral(address _collateral) external;
    function setLeverUp(bool _enabled) external;
    function setFeeBootstrapPeriodEnabled(bool _enabled) external;
    function updateGlobalYUSDMinting(bool _canMint) external;
    function removeValidYUSDMinter(address _minter) external;
    function removeVeYetiCaller(address _contractAddress) external;
    function updateRedemptionsEnabled(bool _enabled) external;
    function changeFeeCurve(address _collateral, address _feeCurve) external;


    // ======== Mutable Only Owner-3 Day TimeLock ========
    function addCollateral(
        address _collateral,
        uint256 _safetyRatio,
        uint256 _recoveryRatio,
        address _oracle,
        uint256 _decimals,
        address _feeCurve,
        bool _isWrapped,
        address _routerAddress
    ) external;
    function unDeprecateCollateral(address _collateral) external;
    function updateMaxCollsInTrove(uint _newMax) external;
    function changeRatios(address _collateral, uint256 _newSafetyRatio, uint256 _newRecoveryRatio) external;
    function setDefaultRouter(address _collateral, address _router) external;
    function changeYetiFinanceTreasury(address _newTreasury) external;
    function changeClaimAddress(address _newClaimAddress) external;
    function changeYUSDFeeRecipient(address _newFeeRecipient) external;
    function changeYetiFinanceTreasurySplit(uint256 _newSplit) external;
    function changeRedemptionBorrowerFeeSplit(uint256 _newSplit) external;
    function updateAbsorptionColls(address[] memory _colls, uint[] memory _weights) external;
    function changeOracle(address _collateral, address _oracle) external;


    // ======== Mutable Only Owner-2 Week TimeLock ========
    function addValidYUSDMinter(address _minter) external;
    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor) external;
    function changeGlobalBoostMultiplier(uint256 _newBoostMinuteDecayFactor) external;
    function addVeYetiCaller(address _contractAddress) external;
    function updateMaxSystemColls(uint _newMax) external;


    // ======= VIEW FUNCTIONS FOR COLLATERAL PARAMS =======
    function getValidCollateral() view external returns (address[] memory);
    function getOracle(address _collateral) view external returns (address);
    function getSafetyRatio(address _collateral) view external returns (uint256);
    function getRecoveryRatio(address _collateral) view external returns (uint256);
    function getIsActive(address _collateral) view external returns (bool);
    function getFeeCurve(address _collateral) external view returns (address);
    function getDecimals(address _collateral) external view returns (uint256);
    function getIndex(address _collateral) external view returns (uint256);
    function getIndices(address[] memory _colls) external view returns (uint256[] memory indices);
    function checkCollateralListSingle(address[] memory _colls, bool _deposit) external view;
    function checkCollateralListDouble(address[] memory _depositColls, address[] memory _withdrawColls) external view;
    function isWrapped(address _collateral) external view returns (bool);
    function isWrappedMany(address[] memory _collaterals) external view returns (bool[] memory wrapped);
    function getDefaultRouterAddress(address _collateral) external view returns (address);


    // ======= VIEW FUNCTIONS FOR VC / USD VALUE =======
    function getPrice(address _collateral) external view returns (uint256);
    function getValuesVC(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint);
    function getValuesRVC(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint);
    function getValuesVCAndRVC(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint VC, uint256 RVC);
    function getValuesUSD(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint256);
    function getValueVC(address _collateral, uint _amount) view external returns (uint);
    function getValueRVC(address _collateral, uint _amount) view external returns (uint);
    function getValueUSD(address _collateral, uint _amount) view external returns (uint256);
    function getValuesVCIndividual(address[] memory _collaterals, uint256[] memory _amounts) external view returns (uint256[] memory);


    // ======= VIEW FUNCTIONS FOR CONTRACT FUNCTIONALITY =======
    function getYetiFinanceTreasury() external view returns (address);
    function getYetiFinanceTreasurySplit() external view returns (uint256);
    function getRedemptionBorrowerFeeSplit() external view returns (uint256);
    function getYUSDFeeRecipient() external view returns (address);
    function leverUpEnabled() external view returns (bool);
    function getMaxCollsInTrove() external view returns (uint);
    function getFeeSplitInformation() external view returns (uint256, address, address);
    function getClaimAddress() external view returns (address);
    function getAbsorptionCollParams() external view returns (address[] memory, uint[] memory);
    function getVariableDepositFee(address _collateral, uint _collateralVCInput, uint256 _collateralVCBalancePost, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external view returns (uint256 fee);



    // ======== Mutable Function For Fees ========
    function getTotalVariableDepositFeeAndUpdate(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256 _entireSystemCollVC,
        uint256 _VCin,
        uint256 _VCout
    ) external returns (uint256 YUSDFee, uint256 boostFactor);

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
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
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/** 
 * @notice Interface for use of wrapping and unwrapping vault tokens in the Yeti Finance borrowing 
 * protocol. 
 */
interface IYetiVaultToken {
    function deposit(uint256 _amt) external returns (uint256 receiptTokens);
    function depositFor(address _borrower, address _recipient, uint256 _amt) external returns (uint256 receiptTokens);
    function redeem(address _to, uint256 _amt) external returns (uint256 underlyingTokens);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/** 
 * @notice IYetiLever is an interface intended for use in the Yeti Finance Lever Up feature. It routes from 
 * YUSD to some various token out which has to be compatible with the underlying router in the route 
 * function, and unRoutes backwards to get YUSD out. Sends to the active pool address by intention and 
 * route is called in functions openTroveLeverUp and addCollLeverUp in BorrowerOperations.sol. unRoute
 * is called in functions closeTroveUnleverUp and withdrawCollUnleverUp in BorrowerOperations.sol.
 */

interface IYetiLever {

    // Goes from some token (YUSD likely) and gives a certain amount of token out.
    // Auto transfers to active pool from call in BorrowerOperations.sol, aka _toUser is always activePool
    // Goes from _startingTokenAddress to _endingTokenAddress, given it has tokens of _amount, and gets _minSwapAmount out _endingTokenAddress
    // Sends it to _toUser
    function route(
        address _toUser,
        address _startingTokenAddress,
        address _endingTokenAddress,
        uint256 _amount,
        uint256 _minSwapAmount
    ) external returns (uint256 amountOut);

    // Takes the address of the token required in, and gives a certain amount of any token (YUSD likely) out
    // User first withdraws that collateral from the active pool, then performs this swap. Unwraps tokens
    // for the user in that case.
    // Goes from _startingTokenAddress to _endingTokenAddress, given it has tokens of _amount, of _amount, and gets _minSwapAmount out _endingTokenAddress.
    // Sends it to _toUser
    // Use case: Takes token from trove debt which has been transfered to the owner and then swaps it for YUSD, intended to repay debt.
    function unRoute(
        address _toUser,
        address _startingTokenAddress,
        address _endingTokenAddress,
        uint256 _amount,
        uint256 _minSwapAmount
    ) external returns (uint256 amountOut);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "./LiquityBase.sol";


/**
 * @notice Base contract for CollSurplusPool and StabilityPool. Inherits from LiquityBase
 * and contains additional array operation functions and _requireCallerIsYetiController()
 */
contract PoolBase is LiquityBase {

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;

    /** 
     * @notice More efficient version of sumColls when dealing with all whitelisted tokens. 
     *    Used by pool accounting of tokens inside that pool. 
     * @dev Inspired by left join in relational databases, _coll1 is always taken while 
     *    _tokens and _amounts are just added to that side. _coll1 index is actually equal
     *    always to the index in YetiController of that token. Time complexity depends
     *    here on the number of whitelisted tokens = L since that it equals pool coll length. 
     *    Time complexity is therefore O(L)
     */
    function _leftSumColls(
        newColls memory _coll1,
        address[] memory _tokens,
        uint256[] memory _amounts
    ) internal pure returns (uint[] memory) {
        // If nothing on the right side then return the original. 
        if (_amounts.length == 0) {
            return _coll1.amounts;
        }

        uint256 coll1Len = _coll1.amounts.length;
        uint256 tokensLen = _tokens.length;
        // Result will always be coll1 len size. 
        uint[] memory sumAmounts = new uint[](coll1Len);

        uint256 i = 0;
        uint256 j = 0;
        
        // Sum through all tokens until either left or right side reaches end. 
        while (i < tokensLen && j < coll1Len) {
            // If tokens match up then sum them together. 
            if (_tokens[i] == _coll1.tokens[j]) {
                sumAmounts[j] = _coll1.amounts[j].add(_amounts[i]);
                ++i;
            } 
            // Otherwise just take the left side. 
            else {
                sumAmounts[j] = _coll1.amounts[j];
            }
            ++j;
        }
        // If right side ran out add the remaining amounts in the left side. 
        while (j < coll1Len) {
            sumAmounts[j] = _coll1.amounts[j];
            ++j;
        }

        return sumAmounts;
    }

    /** 
     * @notice More efficient version of subColls when dealing with all whitelisted tokens. 
     *    Used by pool accounting of tokens inside that pool. 
     * @dev Inspired by left join in relational databases, _coll1 is always taken while 
     *    _tokens and _amounts are just subbed from that side. _coll1 index is actually equal
     *    always to the index in YetiController of that token. Time complexity depends
     *    here on the number of whitelisted tokens = L since that it equals pool coll length. 
     *    Time complexity is therefore O(L)
     */    
    function _leftSubColls(newColls memory _coll1, address[] memory _subTokens, uint[] memory _subAmounts)
    internal
    pure
    returns (uint[] memory)
    {
        // If nothing on the right side then return the original. 
        if (_subTokens.length == 0) {
            return _coll1.amounts;
        }

        uint256 coll1Len = _coll1.amounts.length;
        uint256 tokensLen = _subTokens.length;
        // Result will always be coll1 len size. 
        uint[] memory diffAmounts = new uint[](coll1Len);

        uint256 i = 0;
        uint256 j = 0;

        // Sub through all tokens until either left or right side reaches end. 
        while (i < tokensLen && j < coll1Len) {
            // If tokens match up then subtract them
            if (_subTokens[i] == _coll1.tokens[j]) {
                diffAmounts[j] = _coll1.amounts[j].sub(_subAmounts[i]);
                ++i;
            } 
            // Otherwise just take the left side. 
            else {
                diffAmounts[j] = _coll1.amounts[j];
            }
            ++j;
        }
        // If right side ran out add the remaining amounts in the left side. 
        while (j < coll1Len) {
            diffAmounts[j] = _coll1.amounts[j];
            ++j;
        }

        return diffAmounts;
    }

    function _requireCallerIsYetiController() internal view {
        if (msg.sender != address(controller)) {
            _revertWrongFuncCaller();
        }
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "add overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "sub overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "mul overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "div by 0");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b != 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "mod by 0");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

// uint128 addition and subtraction, with overflow protection.

library YetiSafeMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128) {
        uint128 c = a + b;
        require(c >= a, "YetiSafeMath128: addition overflow");

        return c;
    }
   
    function sub(uint128 a, uint128 b) internal pure returns (uint128) {
        require(b <= a, "YetiSafeMath128: subtraction overflow");
        uint128 c = a - b;

        return c;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity 0.6.11;

import "../Interfaces/IERC20.sol";
import "./Address.sol";

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
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length != 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity 0.6.11;

abstract contract ReentrancyGuardUpgradeable {
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
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal {
        require(_status == 0, "ReentrancyGuardUpgradeable: contract is already initialized");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface ICollateralReceiver {
    function receiveCollateral(address[] memory _tokens, uint[] memory _amounts) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IPriceFeed.sol";


interface ILiquityBase {

    function getEntireSystemDebt() external view returns (uint entireSystemDebt);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IERC20.sol";
import "./IERC2612.sol";

interface IYETIToken is IERC20, IERC2612 {

    function sendToSYETI(address _sender, uint256 _amount) external;

    function getDeploymentStartTime() external view returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IPool.sol";

    
interface IActivePool is IPool {
    // --- Events ---
    event ActivePoolYUSDDebtUpdated(uint _YUSDDebt);
    event ActivePoolCollateralBalanceUpdated(address _collateral, uint _amount);

    // --- Functions ---
    
    function sendCollaterals(address _to, address[] memory _tokens, uint[] memory _amounts) external;

    function sendCollateralsUnwrap(address _to, address[] memory _tokens, uint[] memory _amounts) external;

    function sendSingleCollateral(address _to, address _token, uint256 _amount) external;

    function sendSingleCollateralUnwrap(address _to, address _token, uint256 _amount) external;

    function getCollateralVC(address collateralAddress) external view returns (uint);
    
    function addCollateralType(address _collateral) external;

    function getAmountsSubsetSystem(address[] memory _collaterals) external view returns (uint256[] memory);

    function getVCSystem() external view returns (uint256 totalVCSystem);

    function getVCAndRVCSystem() external view returns (uint256 totalVC, uint256 totalRVC);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IPool.sol";

interface IDefaultPool is IPool {
    // --- Events ---
    event DefaultPoolYUSDDebtUpdated(uint256 _YUSDDebt);
    event DefaultPoolETHBalanceUpdated(uint256 _ETH);

    // --- Functions ---
    
    function sendCollsToActivePool(address[] memory _collaterals, uint256[] memory _amounts) external;

    function addCollateralType(address _collateral) external;

    function getCollateralVC(address collateralAddress) external view returns (uint256);

    function getAmountsSubset(address[] memory _collaterals) external view returns (uint256[] memory amounts, uint256[] memory controllerIndices);

    function getAllAmounts() external view returns (uint256[] memory);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IPriceFeed {

    event LastGoodPriceUpdated(uint256 _lastGoodPrice);

    function fetchPrice_v() view external returns (uint);
    function fetchPrice() external returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./ICollateralReceiver.sol";

// Common interface for the Pools.
interface IPool is ICollateralReceiver {
    
    // --- Events ---
    
    event ETHBalanceUpdated(uint _newBalance);
    event YUSDBalanceUpdated(uint _newBalance);
    event EtherSent(address _to, uint _amount);
    event CollateralSent(address _collateral, address _to, uint _amount);

    // --- Functions ---

    function getVC() external view returns (uint totalVC);

    function getVCAndRVC() external view returns (uint totalVC, uint totalRVC);

    function getCollateral(address collateralAddress) external view returns (uint);

    function getAllCollateral() external view returns (address[] memory, uint256[] memory);

    function getYUSDDebt() external view returns (uint);

    function increaseYUSDDebt(uint _amount) external;

    function decreaseYUSDDebt(uint _amount) external;

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./YetiMath.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/ILiquityBase.sol";
import "./YetiCustomBase.sol";

/** 
 * Base contract for TroveManager, TroveManagerLiquidations, TroveManagerRedemptions,
 * and BorrowerOperations.
 * Contains global system constants and common functions.
 */
contract LiquityBase is ILiquityBase, YetiCustomBase {

    // Minimum collateral ratio for individual troves
    uint constant internal MCR = 11e17; // 110%

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint constant internal CCR = 15e17; // 150%

    // Amount of YUSD to be locked in gas pool on opening troves
    // This YUSD goes to the liquidator in the event the trove is liquidated.
    uint constant internal YUSD_GAS_COMPENSATION = 200e18;

    // Minimum amount of net YUSD debt a must have
    uint constant internal MIN_NET_DEBT = 1800e18;

    // Minimum fee on issuing new debt, paid in YUSD
    uint constant internal BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%

    // Minimum fee paid on redemption, paid in YUSD
    uint constant internal REDEMPTION_FEE_FLOOR = DECIMAL_PRECISION / 1000 * 5; // 0.5%

    IActivePool internal activePool;

    IDefaultPool internal defaultPool;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;

    // --- Gas compensation functions ---

    /**
     * @notice Returns the total debt of a trove (net debt + gas compensation)
     * @dev The net debt is how much YUSD the user can actually withdraw from the system.
     * The composite debt is the trove's total debt and is used for ICR calculations
     * @return Trove withdrawable debt (net debt) plus YUSD_GAS_COMPENSATION
    */
    function _getCompositeDebt(uint _debt) internal pure returns (uint) {
        return _debt.add(YUSD_GAS_COMPENSATION);
    }

    /**
     * @notice Returns the net debt, which is total (composite) debt of a trove minus gas compensation
     * @dev The net debt is how much YUSD the user can actually withdraw from the system.
     * @return Trove total debt minus the gas compensation
    */
    function _getNetDebt(uint _debt) internal pure returns (uint) {
        return _debt.sub(YUSD_GAS_COMPENSATION);
    }

    /**
     * @notice Return the system's Total Virtual Coin Balance
     * @dev Virtual Coins are a way to keep track of the system collateralization given
     * the collateral ratios of each collateral type
     * @return System's Total Virtual Coin Balance
     */
    function getEntireSystemColl() public view returns (uint) {
        return activePool.getVCSystem();
    }

    /**
     * @notice Calculate and return the System's Total Debt
     * @dev Includes debt held by active troves (activePool.getYUSDDebt())
     * as well as debt from liquidated troves that has yet to be redistributed
     * (defaultPool.getYUSDDebt())
     * @return Return the System's Total Debt
     */
    function getEntireSystemDebt() public override view returns (uint) {
        uint activeDebt = activePool.getYUSDDebt();
        uint closedDebt = defaultPool.getYUSDDebt();
        return activeDebt.add(closedDebt);
    }

    /**
     * @notice Calculate ICR given collaterals and debt
     * @dev ICR = VC(colls) / debt
     * @return ICR Return ICR of the given _colls and _debt
     */
    function _getICRColls(newColls memory _colls, uint _debt) internal view returns (uint ICR) {
        uint totalVC = _getVCColls(_colls);
        ICR = _computeCR(totalVC, _debt);
    }

    /**
     * @notice Calculate and AICR of the colls
     * @dev AICR = RVC(colls) / debt. Calculation is the same as
     * ICR except the collateral weights are different
     * @return AICR Return AICR of the given _colls and _debt
     */
    function _getAICRColls(newColls memory _colls, uint _debt) internal view returns (uint AICR) {
        uint totalRVC = _getRVCColls(_colls);
        AICR = _computeCR(totalRVC, _debt);
    }

    /**
     * @notice Calculate ICR given collaterals and debt
     * @dev ICR = VC(colls) / debt
     * @return ICR Return ICR of the given _colls and _debt
     */
    function _getICR(address[] memory _tokens, uint[] memory _amounts, uint _debt) internal view returns (uint ICR) {
        uint totalVC = _getVC(_tokens, _amounts);
        ICR = _computeCR(totalVC, _debt);
    }

    /**
     * @notice Calculate and AICR of the colls
     * @dev AICR = RVC(colls) / debt. Calculation is the same as
     * ICR except the collateral weights are different
     * @return AICR Return AICR of the given _colls and _debt
     */
    function _getAICR(address[] memory _tokens, uint[] memory _amounts, uint _debt) internal view returns (uint AICR) {
        uint totalRVC = _getRVC(_tokens, _amounts);
        AICR = _computeCR(totalRVC, _debt);
    }

    function _getVC(address[] memory _tokens, uint[] memory _amounts) internal view returns (uint totalVC) {
        totalVC = controller.getValuesVC(_tokens, _amounts);
    }

    function _getRVC(address[] memory _tokens, uint[] memory _amounts) internal view returns (uint totalRVC) {
        totalRVC = controller.getValuesRVC(_tokens, _amounts);
    }

    function _getVCColls(newColls memory _colls) internal view returns (uint totalVC) {
        totalVC = controller.getValuesVC(_colls.tokens, _colls.amounts);
    }

    function _getRVCColls(newColls memory _colls) internal view returns (uint totalRVC) {
        totalRVC = controller.getValuesRVC(_colls.tokens, _colls.amounts);
    }

    function _getUSDColls(newColls memory _colls) internal view returns (uint totalUSDValue) {
        totalUSDValue = controller.getValuesUSD(_colls.tokens, _colls.amounts);
    }

    function _getTCR() internal view returns (uint TCR) {
        (,uint256 entireSystemRVC) = activePool.getVCAndRVCSystem();
        uint256 entireSystemDebt = getEntireSystemDebt(); 
        TCR = _computeCR(entireSystemRVC, entireSystemDebt);
    }

    /**
     * @notice Returns recovery mode bool as well as entire system coll
     * @dev Do these together to avoid looping.
     * @return recMode Recovery mode bool
     * @return entireSystemCollVC System's Total Virtual Coin Balance
     * @return entireSystemCollRVC System's total Recovery ratio adjusted VC balance
     * @return entireSystemDebt System's total debt
     */
    function _checkRecoveryModeAndSystem() internal view returns (bool recMode, uint256 entireSystemCollVC, uint256 entireSystemCollRVC, uint256 entireSystemDebt) {
        (entireSystemCollVC, entireSystemCollRVC) = activePool.getVCAndRVCSystem();
        entireSystemDebt = getEntireSystemDebt();
        // Check TCR < CCR
        recMode = _computeCR(entireSystemCollRVC, entireSystemDebt) < CCR;
    }

    function _checkRecoveryMode() internal view returns (bool) {
        return _getTCR() < CCR;
    }

    // fee and amount are denominated in dollar
    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = _fee.mul(DECIMAL_PRECISION).div(_amount);
        require(feePercentage <= _maxFeePercentage, "Fee > max");
    }

    // checks coll has a nonzero balance of at least one token in coll.tokens
    function _collsIsNonZero(newColls memory _colls) internal pure returns (bool) {
        uint256 tokensLen = _colls.tokens.length;
        for (uint256 i; i < tokensLen; ++i) {
            if (_colls.amounts[i] != 0) {
                return true;
            }
        }
        return false;
    }

    /**
     * @notice Calculates a new collateral ratio if debt is not 0 or the max uint256 value if it is 0
     * @dev Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
     * @param _coll Collateral
     * @param _debt Debt of Trove
     * @return The new collateral ratio if debt is greater than 0, max value of uint256 if debt is 0
     */
    function _computeCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt != 0) {
            uint newCollRatio = _coll.mul(1e18).div(_debt);
            return newCollRatio;
        }
        else { 
            return 2**256 - 1; 
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./SafeMath.sol";

library YetiMath {
    using SafeMath for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;
    uint internal constant HALF_DECIMAL_PRECISION = 5e17;


    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /**
     * @notice Multiply two decimal numbers 
     * @dev Use normal rounding rules: 
        -round product up if 19'th mantissa digit >= 5
        -round product down if 19'th mantissa digit < 5
     */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);

        decProd = prod_xy.add(HALF_DECIMAL_PRECISION).div(DECIMAL_PRECISION);
    }

    /* 
    * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
    * 
    * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity. 
    * 
    * Called by two functions that represent time in units of minutes:
    * 1) TroveManager._calcDecayedBaseRate
    * 2) CommunityIssuance._getCumulativeIssuanceFraction 
    * 
    * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
    * "minutes in 1000 years": 60 * 24 * 365 * 1000
    * 
    * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
    * negligibly different from just passing the cap, since: 
    *
    * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
    * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
    */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
       
        if (_minutes > 5256e5) {_minutes = 5256e5;}  // cap to avoid overflow
    
        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else { // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
  }

    function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./SafeMath.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IYetiController.sol";

/**
 * Contains shared functionality for many of the system files
 * YetiCustomBase is inherited by PoolBase2 and LiquityBase
 */

contract YetiCustomBase {
    using SafeMath for uint256;

    IYetiController internal controller;

    struct newColls {
        // tokens and amounts should be the same length
        address[] tokens;
        uint256[] amounts;
    }

    uint256 public constant DECIMAL_PRECISION = 1e18;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;

    /**
     * @notice Returns _coll1.amounts plus _coll2.amounts
     * @dev Invariant that _coll1.tokens and _coll2.tokens are sorted by whitelist order of token indices from the YetiController.
     *    So, if WAVAX is whitelisted first, then WETH, then USDC, then [WAVAX, USDC] is a valid input order but [USDC, WAVAX] is not.
     *    This is done for gas efficiency. We use a sliding window approach to increment the indices of the tokens we are adding together
     *    from _coll1 and from _coll2. We will start at tokenIndex1 and tokenIndex2. To keep the invariant of ordered collateral in 
     *    each trove, we need to merge coll1 and coll2 in order based on the YetiController whitelist order. If the token indices 
     *    line up, then they are the same and we add the sum. Otherwise we add the smaller index to keep them in order and move on. 
     *    Once we reach the end of either tokens1 or tokens2, we add the remaining ones to the sum individually without summing. 
     *    n is the number of tokens in the coll1, and m is the number of tokens in the coll2. k is defined as the number of tokens 
     *    in the summed version. k = n + m - (overlap). The time complexity here depends on O(n + m) in the first loop and tail calls, 
     *    and O(k) in the last loop. The total time complexity is O(n + m + k). If we assume that n is bigger than m(arbitrary between 
     *    n and m), then since k is bounded by n we can say the time complexity is O(3n). This does not depend on all whitelisted tokens. 
     */
    function _sumColls(newColls memory _coll1, newColls memory _coll2)
        internal
        view
        returns (newColls memory finalColls)
    {
        uint256 coll2Len = _coll2.tokens.length;
        uint256 coll1Len = _coll1.tokens.length;
        // If either is 0 then just return the other one. 
        if (coll2Len == 0) {
            return _coll1;
        } else if (coll1Len == 0) {
            return _coll2;
        }
        // Create temporary n + m sized array.
        newColls memory coll3;
        coll3.tokens = new address[](coll1Len + coll2Len);
        coll3.amounts = new uint256[](coll1Len + coll2Len);

        // Tracker for the coll1 array.
        uint256 i = 0;
        // Tracker for the coll2 array.
        uint256 j = 0;
        // Tracker for nonzero entries.
        uint256 k = 0;

        uint256[] memory tokenIndices1 = controller.getIndices(_coll1.tokens);
        uint256[] memory tokenIndices2 = controller.getIndices(_coll2.tokens);

        // Tracker for token whitelist index for all coll1
        uint256 tokenIndex1 = tokenIndices1[i];
        // Tracker for token whitelist index for all coll2
        uint256 tokenIndex2 = tokenIndices2[j];

        // This loop will break out if either token index reaches the end inside the conditions. 
        while (true) {
            if (tokenIndex1 < tokenIndex2) {
                // If tokenIndex1 is less than tokenIndex2 then that means it should be added first by itself.
                coll3.tokens[k] = _coll1.tokens[i];
                coll3.amounts[k] = _coll1.amounts[i];
                ++i;
                // If we reached the end of coll1 then we exit out.
                if (i == coll1Len) {
                    break;
                }
                tokenIndex1 = tokenIndices1[i];
            } else if (tokenIndex2 < tokenIndex1) {
                // If tokenIndex2 is less than tokenIndex1 then that means it should be added first by itself.
                coll3.tokens[k] = _coll2.tokens[j];
                coll3.amounts[k] = _coll2.amounts[j];
                ++j;
                // If we reached the end of coll2 then we exit out.
                if (j == coll2Len) {
                    break;
                }
                tokenIndex2 = tokenIndices2[j];
            } else {
                // If the token indices match up then they are the same token, so we add them together.
                coll3.tokens[k] = _coll1.tokens[i];
                coll3.amounts[k] = _coll1.amounts[i].add(_coll2.amounts[j]);
                ++i;
                ++j;
                // If we reached the end of coll1 or coll2 then we exit out.
                if (i == coll1Len || j == coll2Len) {
                    break;
                }
                tokenIndex1 = tokenIndices1[i];
                tokenIndex2 = tokenIndices2[j];
            }
            ++k;
        }
        ++k;
        // Add remaining tokens from coll1 if we reached the end of coll2 inside the previous loop. 
        while (i < coll1Len) {
            coll3.tokens[k] = _coll1.tokens[i];
            coll3.amounts[k] = _coll1.amounts[i];
            ++i;
            ++k;
        }
        // Add remaining tokens from coll2 if we reached the end of coll1 inside the previous loop. 
        while (j < coll2Len) {
            coll3.tokens[k] = _coll2.tokens[j];
            coll3.amounts[k] = _coll2.amounts[j];
            ++j;
            ++k;
        }

        // K is the resulting amount of nonzero entries that are in coll3, so we add them to finalTokens and return. 
        address[] memory sumTokens = new address[](k);
        uint256[] memory sumAmounts = new uint256[](k);
        for (i = 0; i < k; ++i) {
            sumTokens[i] = coll3.tokens[i];
            sumAmounts[i] = coll3.amounts[i];
        }

        finalColls.tokens = sumTokens;
        finalColls.amounts = sumAmounts;
    }

    function _revertWrongFuncCaller() internal pure {
        revert("WFC");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.11;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
     /**
     * @notice Checks if 'account' is a contract
     * @dev It is unsafe to assume that an address for which this function returns
        false is an externally-owned account (EOA) and not a contract.
        Among others, `isContract` will return false for the following
        types of addresses:
        - an externally-owned account
        - a contract in construction
        - an address where a contract will be created
        - an address where a contract lived, but was destroyed
     * @param account The address of an account
     * @return true if account is a contract, false if account is not a contract
    */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size != 0;
    }

     /**
     * @notice sends `amount` wei to `recipient`, forwarding all available gas and reverting on errors.
     * @dev Replacement for Solidity's `transfer`
        https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
        of certain opcodes, possibly making contracts go over the 2300 gas limit
        imposed by `transfer`, making them unable to receive funds via
        `transfer`. {sendValue} removes this limitation.
        
        https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
        
        IMPORTANT: because control is transferred to `recipient`, care must be
        taken to not create reentrancy vulnerabilities. Consider using
        {ReentrancyGuard} or the
        https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     * @param recipient The address of where the wei 'amount' is sent to 
     * @param amount the 'amount' of wei to be transfered to 'recipient'
      */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

     /**
     * @notice Performs a Solidity function call using a low level `call`.
     * @dev A plain`call` is an unsafe replacement for a function call: use this function instead.
        If `target` reverts with a revert reason, it is bubbled up by this
        function (like regular Solidity function calls).
        
        Returns the raw returned data. To convert to the expected return value,
        use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
        
        Requirements:
        
        - `target` must be a contract.
        - calling `target` with `data` must not revert.
        
        _Available since v3.1._
     * @param target The address of a contract
     * @param data In bytes 
     * @return Solidity's functionCall 
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    // function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
    //     return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    // }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    // function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
    //     require(isContract(target), "Address: delegate call to non-contract");

    //     // solhint-disable-next-line avoid-low-level-calls
    //     (bool success, bytes memory returndata) = target.delegatecall(data);
    //     return _verifyCallResult(success, returndata, errorMessage);
    // }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length != 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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