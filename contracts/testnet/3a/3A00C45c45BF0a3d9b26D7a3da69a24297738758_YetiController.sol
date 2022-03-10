// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/IBaseOracle.sol";
import "../Interfaces/IYetiController.sol";
import "../Interfaces/IPriceFeed.sol";
import "../Interfaces/IFeeCurve.sol";
import "../Interfaces/IActivePool.sol";
import "../Interfaces/IDefaultPool.sol";
import "../Interfaces/IStabilityPool.sol";
import "../Interfaces/ISortedTroves.sol";
import "../Interfaces/ICollSurplusPool.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IYUSDToken.sol";
import "../Dependencies/Ownable.sol";
import "../Dependencies/YetiMath.sol";
import "../Dependencies/CheckContract.sol";

/**
 * YetiController is the contract that controls system parameters.
 * This includes things like enabling leverUp, feeBootstrap, and pausing the system.
 * YetiController also keeps track of all collateral parameters and allos
 * the team to update these. This includes: change the fee
 * curve, price feed, safety ratio, recovery ratio etc. as well
 * as adding or deprecating new collaterals. Some parameter changes
 * can be executed instantly, while others can only be updated by certain
 * Timelock contracts to ensure the communtiy has a fair warning before updates.
 * YetiController also has view functions to get
 * prices and VC, and RVC values.
 */

contract YetiController is Ownable, IYetiController, IBaseOracle, CheckContract {
    using SafeMath for uint256;

    struct CollateralParams {
        // Ratios: 10**18 * the ratio. i.e. ratio = 95E16 for 95%.
        // More risky collateral has a lower ratio
        uint256 safetyRatio;
        uint256 recoveryRatio;
        address oracle;
        uint256 decimals;
        address feeCurve;
        uint256 index;
        address defaultRouter;
        bool active;
        bool isWrapped;
    }

    struct DepositFeeCalc {
        uint256 collateralYUSDFee;
        uint256 systemCollateralVC;
        uint256 collateralInputVC;
        address token;
        uint256 activePoolVCPost;
        IActivePool activePool;
        IDefaultPool defaultPool;
    }

    IActivePool private activePool;
    IDefaultPool private defaultPool;
    IStabilityPool private stabilityPool;
    ICollSurplusPool private collSurplusPool;
    IYUSDToken private yusdToken;
    ISortedTroves private sortedTroves;
    address private YUSDFeeRecipient;
    address private borrowerOperationsAddress;
    address private yetiFinanceTreasury;
    uint256 private yetiFinanceTreasurySplit = 2e17;
    uint256 private redemptionBorrowerFeeSplit = 2e17;
    bool private addressesSet;
    bool private isLeverUpEnabled;
    bool feeBoostrapPeriodEnabled = true;
    uint256 maxCollsInTrove = 50; // TODO: update to a reasonable number

    address oneWeekTimelock;
    address twoWeekTimelock;

    mapping(address => CollateralParams) public collateralParams;
    // list of all collateral types in collateralParams (active and deprecated)
    // Addresses for easy access
    address[] public validCollateral; // index maps to token address.

    event CollateralAdded(address _collateral);
    event CollateralDeprecated(address _collateral);
    event CollateralUndeprecated(address _collateral);
    event OracleChanged(address _collateral, address _newOracle);
    event FeeCurveChanged(address _collateral, address _newFeeCurve);
    event SafetyRatioChanged(address _collateral, uint256 _newSafetyRatio);
    event RecoveryRatioChanged(address _collateral, uint256 _newRecoveryRatio);

    // ======== Events for timelocked functions ========
    event LeverUpChanged(bool _enabled);
    event FeeBootstrapPeriodEnabledChanged(bool _enabled);
    event GlobalYUSDMintOn(bool _canMint);
    event YUSDMinterChanged(address _minter, bool _canMint);
    event DefaultRouterChanged(address _collateral, address _newDefaultRouter);
    event YetiFinanceTreasuryChanged(address _newTreasury);
    event YetiFinanceTreasurySplitChanged(uint256 _newSplit);
    event RedemptionBorrowerFeeSplitChanged(uint256 _newSplit);
    event YUSDFeeRecipientChanged(address _newFeeRecipient);
    event GlobalBoostMultiplierChanged(uint256 _newGlobalBoostMultiplier);
    event BoostMinuteDecayFactorChanged(uint256 _newBoostMinuteDecayFactor);

    // Require that the collateral exists in the controller. If it is not the 0th index, and the
    // index is still 0 then it does not exist in the mapping.
    // no require here for valid collateral 0 index because that means it exists.
    modifier exists(address _collateral) {
        _exists(_collateral);
        _;
    }

    // Calling from here makes it not inline, reducing contract size significantly.
    function _exists(address _collateral) internal view {
        if (validCollateral[0] != _collateral) {
            require(collateralParams[_collateral].index != 0, "collateral does not exist");
        }
    }

    // ======== Timelock modifiers ========

    modifier onlyOneWeekTimelock() {
        require(msg.sender == oneWeekTimelock, "Caller Not One Week Timelock");
        _;
    }

    modifier onlyTwoWeekTimelock() {
        require(msg.sender == twoWeekTimelock, "Caller Not Two Week Timelock");
        _;
    }

    // ======== Mutable Only Owner-Instantaneous ========

    function setAddresses(
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _stabilityPoolAddress,
        address _collSurplusPoolAddress,
        address _borrowerOperationsAddress,
        address _yusdTokenAddress,
        address _sYETITokenAddress,
        address _yetiFinanceTreasury,
        address _sortedTrovesAddress,
        address _oneWeekTimelock,
        address _twoWeekTimelock
    ) external override onlyOwner {
        require(!addressesSet, "addresses already set");
        checkContract(_activePoolAddress);
        checkContract(_defaultPoolAddress);
        checkContract(_stabilityPoolAddress);
        checkContract(_collSurplusPoolAddress);
        checkContract(_borrowerOperationsAddress);
        checkContract(_sortedTrovesAddress);
        checkContract(_yusdTokenAddress);

        activePool = IActivePool(_activePoolAddress);
        defaultPool = IDefaultPool(_defaultPoolAddress);
        stabilityPool = IStabilityPool(_stabilityPoolAddress);
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        yusdToken = IYUSDToken(_yusdTokenAddress);
        YUSDFeeRecipient = _sYETITokenAddress;
        borrowerOperationsAddress = _borrowerOperationsAddress;
        yetiFinanceTreasury = _yetiFinanceTreasury;
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        oneWeekTimelock = _oneWeekTimelock;
        twoWeekTimelock = _twoWeekTimelock;
        addressesSet = true;
    }

    /**
     * Can be used to quickly shut down new collateral from entering
     * Yeti in the event of a potential hack.
     */
    function deprecateAllCollateral() external override onlyOwner {
        uint256 len = validCollateral.length;
        for (uint256 i; i < len; i++) {
            address collateral = validCollateral[i];
            if (collateralParams[collateral].active) {
                _deprecateCollateral(collateral);
            }
        }
    }

    /**
     * Deprecate collateral by not allowing any more collateral to be added of this type.
     * Still can interact with it via validCollateral and CollateralParams
     */
    function deprecateCollateral(address _collateral) public override exists(_collateral) onlyOwner {
        require(collateralParams[_collateral].active, "collateral already deprecated");
        _deprecateCollateral(_collateral);
    }

    function _deprecateCollateral(address _collateral) internal {
        collateralParams[_collateral].active = false;
        // throw event
        emit CollateralDeprecated(_collateral);
    }

    function setFeeBootstrapPeriodEnabled(bool _enabled) external override onlyOwner {
        feeBoostrapPeriodEnabled = _enabled;
        emit FeeBootstrapPeriodEnabledChanged(_enabled);
    }

    function updateGlobalYUSDMinting(bool _canMint) external override onlyOwner {
        yusdToken.updateMinting(_canMint);
        emit GlobalYUSDMintOn(_canMint);
    }

    function removeValidYUSDMinter(address _minter) external override onlyOwner {
        require(_minter != borrowerOperationsAddress);
        yusdToken.removeValidMinter(_minter);
        emit YUSDMinterChanged(_minter, false);
    }

    // ======== Mutable Only Owner-1 Week TimeLock ========

    function addCollateral(
        address _collateral,
        uint256 _safetyRatio,
        uint256 _recoveryRatio,
        address _oracle,
        uint256 _decimals,
        address _feeCurve,
        bool _isWrapped,
        address _routerAddress
    ) external override onlyOneWeekTimelock {
        checkContract(_collateral);
        checkContract(_oracle);
        checkContract(_feeCurve);
        checkContract(_routerAddress);
        // If collateral list is not 0, and if the 0th index is not equal to this collateral,
        // then if index is 0 that means it is not set yet.
        require(_safetyRatio < 11e17, "Safety Ratio must be less than 1.10"); //=> greater than 1.1 would mean taking out more YUSD than collateral VC
        require(_recoveryRatio >= _safetyRatio, "Recovery ratio must be >= safety ratio");

        if (validCollateral.length != 0) {
            require(
                validCollateral[0] != _collateral && collateralParams[_collateral].index == 0,
                "collateral already exists"
            );
        }

        validCollateral.push(_collateral);
        collateralParams[_collateral] = CollateralParams(
            _safetyRatio,
            _recoveryRatio,
            _oracle,
            _decimals,
            _feeCurve,
            validCollateral.length - 1,
            _routerAddress,
            true,
            _isWrapped
        );

        activePool.addCollateralType(_collateral);
        defaultPool.addCollateralType(_collateral);
        stabilityPool.addCollateralType(_collateral);
        collSurplusPool.addCollateralType(_collateral);

        // throw event
        emit CollateralAdded(_collateral);
        emit SafetyRatioChanged(_collateral, _safetyRatio);
        emit RecoveryRatioChanged(_collateral, _recoveryRatio);
    }

    /**
     * @notice Undeprecate collateral by allowing more collateral to be added of this type.
     * Still can interact with it via validCollateral and CollateralParams
     */
    function unDeprecateCollateral(address _collateral)
        external
        override
        exists(_collateral)
        onlyOneWeekTimelock
    {
        checkContract(_collateral);

        require(!collateralParams[_collateral].active, "collateral is already active");

        collateralParams[_collateral].active = true;

        // throw event
        emit CollateralUndeprecated(_collateral);
    }

    function setLeverUp(bool _enabled) external override onlyOneWeekTimelock {
        isLeverUpEnabled = _enabled;
        emit LeverUpChanged(_enabled);
    }

    function updateMaxCollsInTrove(uint256 _newMax) external override onlyOwner {
        maxCollsInTrove = _newMax;
    }

    /**
     * Function to change oracles
     */
    function changeOracle(address _collateral, address _oracle)
        external
        override
        exists(_collateral)
        onlyOneWeekTimelock
    {
        checkContract(_collateral);
        checkContract(_oracle);
        collateralParams[_collateral].oracle = _oracle;

        // throw event
        emit OracleChanged(_collateral, _oracle);
    }

    /**
     * Function to change fee curve
     */
    function changeFeeCurve(address _collateral, address _feeCurve)
        external
        override
        exists(_collateral)
        onlyOneWeekTimelock
    {
        checkContract(_feeCurve);
        require(IFeeCurve(_feeCurve).initialized(), "fee curve not set");
        (uint256 lastFeePercent, uint256 lastFeeTime) = IFeeCurve(
            collateralParams[_collateral].feeCurve
        ).getFeeCapAndTime();
        IFeeCurve(_feeCurve).setFeeCapAndTime(lastFeePercent, lastFeeTime);
        collateralParams[_collateral].feeCurve = _feeCurve;

        // throw event
        emit FeeCurveChanged(_collateral, _feeCurve);
    }

    /**
     * Function to change Safety and Recovery Ratio
     */
    function changeRatios(
        address _collateral,
        uint256 _newSafetyRatio,
        uint256 _newRecoveryRatio
    ) external override exists(_collateral) onlyOneWeekTimelock {
        require(_newSafetyRatio < 11e17, "ratio must be less than 1.10"); //=> greater than 1.1 would mean taking out more YUSD than collateral VC
        require(
            collateralParams[_collateral].safetyRatio <= _newSafetyRatio,
            "New SR must be >= than previous SR"
        );
        require(_newRecoveryRatio >= _newSafetyRatio, "New RR must be greater than or equal to SR");

        collateralParams[_collateral].safetyRatio = _newSafetyRatio;
        collateralParams[_collateral].recoveryRatio = _newRecoveryRatio;

        // throw events
        emit SafetyRatioChanged(_collateral, _newSafetyRatio);
        emit RecoveryRatioChanged(_collateral, _newRecoveryRatio);
    }

    function setDefaultRouter(address _collateral, address _router)
        external
        override
        onlyOneWeekTimelock
        exists(_collateral)
    {
        checkContract(_router);
        collateralParams[_collateral].defaultRouter = _router;
        emit DefaultRouterChanged(_collateral, _router);
    }

    function changeYetiFinanceTreasury(address _newTreasury) external override onlyOneWeekTimelock {
        yetiFinanceTreasury = _newTreasury;
        emit YetiFinanceTreasuryChanged(_newTreasury);
    }

    function changeYetiFinanceTreasurySplit(uint256 _newSplit)
        external
        override
        onlyOneWeekTimelock
    {
        // 20% goes to the borrower for redemptions, taken out of this portion if it is more than 80%
        require(_newSplit <= 1e18, "Treasury fee split can't be more than 100%");
        yetiFinanceTreasurySplit = _newSplit;
        emit YetiFinanceTreasurySplitChanged(_newSplit);
    }

    function changeRedemptionBorrowerFeeSplit(uint256 _newSplit)
        external
        override
        onlyOneWeekTimelock
    {
        require(_newSplit <= 1e18, "Redemption fee split can't be more than 100%");
        redemptionBorrowerFeeSplit = _newSplit;
        emit RedemptionBorrowerFeeSplitChanged(_newSplit);
    }

    /**
     * @notice Change boost minute decay factor which is calculated as a half life of a particular fraction for SortedTroves
     * @dev Half-life of 5d = 120h. 120h = 7200 min
     * (1/2) = d^7200 => d = (1/2)^(1/7200) = 999903734192105837 by default
     * Two week timelocked.
     * @param _newBoostMinuteDecayFactor the new boost decay factor
     */
    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor)
        external
        override
        onlyOneWeekTimelock
    {
        sortedTroves.changeBoostMinuteDecayFactor(_newBoostMinuteDecayFactor);
        emit BoostMinuteDecayFactorChanged(_newBoostMinuteDecayFactor);
    }

    /**
     * @notice Change Boost factor multiplied by new input for SortedTroves
     * @dev If fee is 5% of total, then the boost factor will be 5e16 * boost / 1e18 added to RICR for sorted troves reinsert
     * Default is 0 for boost multiplier at contract deployment. 1e18 would mean 100% of the fee % is added to RICR as a %.
     * @param _newGlobalBoostMultiplier new boost multiplier
     */
    function changeGlobalBoostMultiplier(uint256 _newGlobalBoostMultiplier)
        external
        override
        onlyOneWeekTimelock
    {
        sortedTroves.changeGlobalBoostMultiplier(_newGlobalBoostMultiplier);
        emit GlobalBoostMultiplierChanged(_newGlobalBoostMultiplier);
    }

    // ======== Mutable Only Owner-2 Weeks TimeLock ========

    function addValidYUSDMinter(address _minter) external override onlyTwoWeekTimelock {
        yusdToken.addValidMinter(_minter);
        emit YUSDMinterChanged(_minter, true);
    }

    function changeYUSDFeeRecipient(address _newFeeRecipient) external override onlyTwoWeekTimelock {
        YUSDFeeRecipient = _newFeeRecipient;
        emit YUSDFeeRecipientChanged(_newFeeRecipient);
    }

    // ======= VIEW FUNCTIONS FOR COLLATERAL =======

    function getDefaultRouterAddress(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (address)
    {
        return collateralParams[_collateral].defaultRouter;
    }

    function isWrapped(address _collateral) external view override returns (bool) {
        return collateralParams[_collateral].isWrapped;
    }

    function getValidCollateral() external view override returns (address[] memory) {
        return validCollateral;
    }

    // Get safety ratio used in VC Calculation
    function getSafetyRatio(address _collateral) external view override returns (uint256) {
        return collateralParams[_collateral].safetyRatio;
    }

    // Get safety ratio used in TCR calculation, as well as for redemptions.
    // Often similar to Safety Ratio except for stables.
    function getRecoveryRatio(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        return collateralParams[_collateral].recoveryRatio;
    }

    function getOracle(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (address)
    {
        return collateralParams[_collateral].oracle;
    }

    function getFeeCurve(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (address)
    {
        return collateralParams[_collateral].feeCurve;
    }

    function getIsActive(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (bool)
    {
        return collateralParams[_collateral].active;
    }

    function getDecimals(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        return collateralParams[_collateral].decimals;
    }

    function getIndex(address _collateral)
        external
        view
        override
        exists(_collateral)
        returns (uint256)
    {
        return (collateralParams[_collateral].index);
    }

    function getIndices(address[] memory _colls)
        external
        view
        override
        returns (uint256[] memory indices)
    {
        uint256 len = _colls.length;
        indices = new uint256[](len);

        for (uint256 i; i < len; ++i) {
            _exists(_colls[i]);
            indices[i] = collateralParams[_colls[i]].index;
        }
    }

    /**
     * @notice This function is used to check the deposit and withdraw coll lists of the adjust trove transaction.
     * @dev The coll list must be not overlapping, and strictly increasing. Strictly increasing implies not overlapping,
     * so we just check that. If it is a deposit, the coll also has to be active. The collateral also has to exist. Special
     * case is done for the first collateral, where we don't check the index. Reverts if any case is not met.
     * @param _colls Collateral to check
     * @param _deposit True if deposit, false if withdraw.
     */
    function checkCollateralListSingle(address[] memory _colls, bool _deposit)
        external
        view
        override
    {
        _checkCollateralListSingle(_colls, _deposit);
    }

    function _checkCollateralListSingle(address[] memory _colls, bool _deposit) internal view {
        uint256 len = _colls.length;
        if (len == 0) {
            return;
        }
        // address thisColl = _colls[0];
        // _exists(thisColl);
        uint256 prevIndex; // = collateralParams[thisColl].index;
        // if (_deposit) {
        //     _requireCollateralActive(thisColl);
        // }
        for (uint256 i; i < len; ++i) {
            address thisColl = _colls[i];
            _exists(thisColl);
            require(
                collateralParams[thisColl].index > prevIndex || i == 0,
                "Collateral list must be sorted by index"
            );
            prevIndex = collateralParams[thisColl].index;
            if (_deposit) {
                _requireCollateralActive(thisColl);
            }
        }
    }

    /**
     * @notice This function is used to check the deposit and withdraw coll lists of the adjust trove transaction.
     * @dev The colls must be not overlapping, and each strictly increasing. While looping through both, we check that
     * the indices are not shared, and we then increment by each list whichever is smaller at that time, whie simultaneously
     * checking if the indices of that list are strictly increasing. It also ensures that collaterals exist in the system,
     * and deposited collateral is active. Reverts if any case is not met.
     * @param _depositColls Collateral to check for deposits
     * @param _withdrawColls Collateral to check for withdrawals
     */
    function checkCollateralListDouble(
        address[] memory _depositColls,
        address[] memory _withdrawColls
    ) external view override {
        uint256 _depositLen = _depositColls.length;
        uint256 _withdrawLen = _withdrawColls.length;
        if (_depositLen == 0) {
            if (_withdrawLen == 0) {
                // Both empty, nothing to check
                return;
            } else {
                // Just withdraw check
                _checkCollateralListSingle(_withdrawColls, false);
                return;
            }
        }
        if (_withdrawLen == 0) {
            // Just deposit check
            _checkCollateralListSingle(_depositColls, true);
            return;
        }
        address dColl = _depositColls[0];
        address wColl = _withdrawColls[0];
        uint256 dIndex = collateralParams[dColl].index;
        uint256 wIndex = collateralParams[wColl].index;
        uint256 d_i;
        uint256 w_i;
        while (true) {
            require(dIndex != wIndex, "No overlap in withdraw and deposit");
            if (dIndex < wIndex) {
                // update d coll
                if (d_i == _depositLen) {
                    break;
                }
                dColl = _depositColls[d_i];
                _exists(dColl);
                _requireCollateralActive(dColl);
                uint256 dIndexNew = collateralParams[dColl].index;
                require(dIndexNew > dIndex || d_i == 0, "Collateral list must be sorted by index");
                dIndex = dIndexNew;
                ++d_i;
            } else {
                // update w coll
                if (w_i == _withdrawLen) {
                    break;
                }
                wColl = _withdrawColls[w_i];
                _exists(wColl);
                uint256 wIndexNew = collateralParams[wColl].index;
                require(wIndexNew > wIndex || w_i == 0, "Collateral list must be sorted by index");
                wIndex = wIndexNew;
                ++w_i;
            }
        }
        // No further check of dIndex == wIndex is needed, because to close out of the loop above, we have
        // to have advanced d_i or w_i whichever reached the end. Say d_i reached the end, which means that
        // dIndex was less than wIndex. dIndex has already been updated for the last time, and wIndex is now
        // required to be larger than dIndex. So, no wIndex, unless if it wasn't strictly increasing, can be
        // equal to dIndex. Therefore we only need to check for wIndex to be strictly increasing. Same argument
        // for the vice versa case.
        while (d_i < _depositLen) {
            dColl = _depositColls[d_i];
            _exists(dColl);
            _requireCollateralActive(dColl);
            uint256 dIndexNew = collateralParams[dColl].index;
            require(dIndexNew > dIndex || d_i == 0, "Collateral list must be sorted by index");
            dIndex = dIndexNew;
            ++d_i;
        }
        while (w_i < _withdrawLen) {
            wColl = _withdrawColls[w_i];
            _exists(wColl);
            uint256 wIndexNew = collateralParams[wColl].index;
            require(wIndexNew > wIndex || w_i == 0, "Collateral list must be sorted by index");
            wIndex = wIndexNew;
            ++w_i;
        }
    }

    // ======= VIEW FUNCTIONS FOR VC / USD VALUE =======

    // should return 10**18 times the price in USD of 1 of the given _collateral
    function getPrice(address _collateral) public view override returns (uint256) {
        IPriceFeed collateral_priceFeed = IPriceFeed(collateralParams[_collateral].oracle);
        return collateral_priceFeed.fetchPrice_v();
    }

    // Gets the value of that collateral type, of that amount, in USD terms.
    function getValueUSD(address _collateral, uint256 _amount)
        external
        view
        override
        returns (uint256)
    {
        return _getValueUSD(_collateral, _amount);
    }

    // Aggregates all usd values of passed in collateral / amounts
    function getValuesUSD(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        override
        returns (uint256 USDValue)
    {
        uint256 tokensLen = _collaterals.length;
        for (uint256 i; i < tokensLen; ++i) {
            USDValue = USDValue.add(_getValueUSD(_collaterals[i], _amounts[i]));
        }
    }

    // Gets the value of that collateral type, of that amount, in VC terms.
    function getValueVC(address _collateral, uint256 _amount)
        external
        view
        override
        returns (uint256)
    {
        return _getValueVC(_collateral, _amount);
    }

    function getValuesVC(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        override
        returns (uint256 VCValue)
    {
        uint256 tokensLen = _collaterals.length;
        for (uint256 i; i < tokensLen; ++i) {
            VCValue = VCValue.add(_getValueVC(_collaterals[i], _amounts[i]));
        }
    }

    // Gets the value of that collateral type, of that amount, in Recovery VC terms.
    function getValueRVC(address _collateral, uint256 _amount)
        external
        view
        override
        returns (uint256)
    {
        return _getValueRVC(_collateral, _amount);
    }

    function getValuesRVC(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        override
        returns (uint256 RVCValue)
    {
        uint256 tokensLen = _collaterals.length;
        for (uint256 i; i < tokensLen; ++i) {
            RVCValue = RVCValue.add(_getValueRVC(_collaterals[i], _amounts[i]));
        }
    }

    function _getValueRVC(address _collateral, uint256 _amount) internal view returns (uint256) {
        // Multiply price by amount and recovery ratio to get in Recovery VC terms, as well as dividing by amount of decimals to normalize.
        return (
            (getPrice(_collateral))
                .mul(_amount)
                .mul(collateralParams[_collateral].recoveryRatio)
                .div(10**(18 + collateralParams[_collateral].decimals))
        );
    }

    // Gets the TCR value of that collateral type, of that amount, in TCR VC terms. Also returns the regular Value VC.
    // Used in the active pool and default pool VC calculations.
    function getValueVCforTCR(address _collateral, uint256 _amount)
        external
        view
        override
        returns (uint256, uint256)
    {
        return _getValueVCforTCR(_collateral, _amount);
    }

    function getValuesVCforTCR(address[] memory _collaterals, uint256[] memory _amounts)
        external
        view
        override
        returns (uint256 VCValue, uint256 RVCValue)
    {
        uint256 tokensLen = _collaterals.length;
        for (uint256 i; i < tokensLen; ++i) {
            (uint256 tempVCValue, uint256 tempRVCValue) = _getValueVCforTCR(
                _collaterals[i],
                _amounts[i]
            );
            VCValue = VCValue.add(tempVCValue);
            RVCValue = RVCValue.add(tempRVCValue);
        }
    }

    // ===== VIEW FUNCTIONS FOR CONTRACT FUNCTIONALITY ======

    function getYetiFinanceTreasury() external view override returns (address) {
        return yetiFinanceTreasury;
    }

    function getYetiFinanceTreasurySplit() external view override returns (uint256) {
        return yetiFinanceTreasurySplit;
    }

    function getRedemptionBorrowerFeeSplit() external view override returns (uint256) {
        return redemptionBorrowerFeeSplit;
    }

    function getYUSDFeeRecipient() external view override returns (address) {
        return YUSDFeeRecipient;
    }

    function leverUpEnabled() external view override returns (bool) {
        return isLeverUpEnabled;
    }

    function getMaxCollsInTrove() external view override returns (uint256) {
        return maxCollsInTrove;
    }

    /**
     * Returns the treasury address, treasury split, and the fee recipeint. This is for use of borrower
     * operations when fees are sent, as well as redemption fees.
     */
    function getFeeSplitInformation()
        external
        view
        override
        returns (
            uint256,
            address,
            address
        )
    {
        return (yetiFinanceTreasurySplit, yetiFinanceTreasury, YUSDFeeRecipient);
    }

    // ====== FUNCTIONS FOR FEES ======


    // Returned as fee percentage * 10**18. View function for external callers.
    function getVariableDepositFee(
        address _collateral,
        uint256 _collateralVCInput,
        uint256 _collateralVCSystemBalance,
        uint256 _totalVCBalancePre,
        uint256 _totalVCBalancePost
    ) external view override exists(_collateral) returns (uint256 fee) {
        IFeeCurve feeCurve = IFeeCurve(collateralParams[_collateral].feeCurve);
        return
            feeCurve.getFee(
                _collateralVCInput,
                _collateralVCSystemBalance,
                _totalVCBalancePre,
                _totalVCBalancePost
            );
    }

    /** 
     * @notice Gets total variable fees from all collaterals with entire system collateral,
     * calculates using pre and post balances. For each token, get the active pool and
     * default pool balance of that collateral, and call the correct fee curve function
     * If the fee bootstrap period is on then cap it at a certain percent, otherwise
     * continue looping through all collaterals.
     * To calculate the boost factor, we multiply the fee * leverage amount. Leverage
     * passed in as 0 is actually 1x.
     */
    function getTotalVariableDepositFeeAndUpdate(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256 _entireSystemColl,
        uint256 _VCin,
        uint256 _VCout
    ) external override returns (uint256 YUSDFee, uint256 boostFactor) {
        require(msg.sender == borrowerOperationsAddress, "caller must be BO");
        if (_VCin == 0) {
            return (0, 0);
        }
        DepositFeeCalc memory vars;
        vars.activePool = activePool;
        vars.defaultPool = defaultPool;
        // active pool total VC at current state is passed in as _entireSystemColl
        // active pool total VC post adding and removing all collaterals
        vars.activePoolVCPost = _entireSystemColl.add(_VCin).sub(_VCout);
        uint256 tokensLen = _tokensIn.length;
        for (uint256 i; i < tokensLen; ++i) {
            vars.token = _tokensIn[i];
            // VC value of collateral of this type inputted
            vars.collateralInputVC = _getValueVC(vars.token, _amountsIn[i]);

            // total value in VC of this collateral in active pool (before adding input)
            vars.systemCollateralVC = vars.activePool.getCollateralVC(vars.token).add(
                vars.defaultPool.getCollateralVC(vars.token)
            );
            // (collateral VC In) * (Collateral's Fee Given Yeti Protocol Backed by Given Collateral)
            uint256 controllerFee = _getFeeAndUpdate(
                vars.token,
                vars.collateralInputVC,
                vars.systemCollateralVC,
                _entireSystemColl,
                vars.activePoolVCPost
            );
            if (feeBoostrapPeriodEnabled) {
                controllerFee = YetiMath._min(controllerFee, 1e16); // cap at 1%
            }
            vars.collateralYUSDFee = vars.collateralInputVC.mul(controllerFee).div(1e18);

            // If lower than 1, then it was not leveraged (1x)
            uint256 thisLeverage = YetiMath._max(1e18, _leverages[i]);

            uint256 collBoostFactor = vars.collateralYUSDFee.mul(thisLeverage).div(_VCin);
            boostFactor = boostFactor.add(collBoostFactor);

            YUSDFee = YUSDFee.add(vars.collateralYUSDFee);
        }
    }

    // Returned as fee percentage * 10**18. View function for call to fee originating from BOps callers.
    function _getFeeAndUpdate(
        address _collateral,
        uint256 _collateralVCInput,
        uint256 _collateralVCSystemBalance,
        uint256 _totalVCBalancePre,
        uint256 _totalVCBalancePost
    ) internal exists(_collateral) returns (uint256 fee) {
        IFeeCurve feeCurve = IFeeCurve(collateralParams[_collateral].feeCurve);
        return
            feeCurve.getFeeAndUpdate(
                _collateralVCInput,
                _collateralVCSystemBalance,
                _totalVCBalancePre,
                _totalVCBalancePost
            );
    }

    // ======== INTERNAL VIEW FUNCTIONS ========

    function _getValueVCforTCR(address _collateral, uint256 _amount)
        internal
        view
        returns (uint256 VC, uint256 VCforTCR)
    {
        uint256 price = getPrice(_collateral);
        uint256 decimals = collateralParams[_collateral].decimals;
        uint256 safetyRatio = collateralParams[_collateral].safetyRatio;
        uint256 recoveryRatio = collateralParams[_collateral].recoveryRatio;
        VC = price.mul(_amount).mul(safetyRatio).div(10**(18 + decimals));
        VCforTCR = price.mul(_amount).mul(recoveryRatio).div(10**(18 + decimals));
    }

    function _getValueUSD(address _collateral, uint256 _amount) internal view returns (uint256) {
        uint256 decimals = collateralParams[_collateral].decimals;
        uint256 price = getPrice(_collateral);
        return price.mul(_amount).div(10**decimals);
    }

    function _getValueVC(address _collateral, uint256 _amount) internal view returns (uint256) {
        // Multiply price by amount and safety ratio to get in VC terms, as well as dividing by amount of decimals to normalize.
        return (
            (getPrice(_collateral)).mul(_amount).mul(collateralParams[_collateral].safetyRatio).div(
                10**(18 + collateralParams[_collateral].decimals)
            )
        );
    }

    function _requireCollateralActive(address _collateral) internal view {
        require(collateralParams[_collateral].active, "Collateral must be active");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IBaseOracle {
  /// @dev Return the value of the given input as USD per unit.
  /// @param token The ERC-20 token to check the value.
  function getPrice(address token) external view returns (uint);

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
        address _sortedTrovesAddress,
        address _sYETITokenAddress,
        address _yetiFinanceTreasury,
        address _oneWeekTimelock,
        address _twoWeekTimelock
    ) external; // setAddresses is special as it is only called can be called once
    function deprecateAllCollateral() external;
    function deprecateCollateral(address _collateral) external;
    function setLeverUp(bool _enabled) external;
    function setFeeBootstrapPeriodEnabled(bool _enabled) external;
    function updateGlobalYUSDMinting(bool _canMint) external;
    function removeValidYUSDMinter(address _minter) external;


    // ======== Mutable Only Owner-1 Week TimeLock ========
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
    function changeOracle(address _collateral, address _oracle) external;
    function changeFeeCurve(address _collateral, address _feeCurve) external;
    function changeRatios(address _collateral, uint256 _newSafetyRatio, uint256 _newRecoveryRatio) external;
    function setDefaultRouter(address _collateral, address _router) external;
    function changeYetiFinanceTreasury(address _newTreasury) external;
    function changeYetiFinanceTreasurySplit(uint256 _newSplit) external;
    function changeRedemptionBorrowerFeeSplit(uint256 _newSplit) external;

    // ======== Mutable Only Owner-2 Week TimeLock ========
    function addValidYUSDMinter(address _minter) external;
    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor) external;
    function changeGlobalBoostMultiplier(uint256 _newBoostMinuteDecayFactor) external;
    function changeYUSDFeeRecipient(address _newFeeRecipient) external;


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
    function getDefaultRouterAddress(address _collateral) external view returns (address);

    // ======= MUTABLE FUNCTION FOR FEES =======
    function getTotalVariableDepositFeeAndUpdate(
        address[] memory _tokensIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256 _entireSystemColl,
        uint256 _VCin,
        uint256 _VCout
    ) external returns (uint256 YUSDFee, uint256 boostFactor);

    function getVariableDepositFee(address _collateral, uint _collateralVCInput, uint256 _collateralVCBalancePost, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external view returns (uint256 fee);

    // ======= VIEW FUNCTIONS FOR VC / USD VALUE =======
    function getValuesVC(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint);
    function getValuesRVC(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint);
    function getValuesVCforTCR(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint VC, uint256 VCforTCR);
    function getValuesUSD(address[] memory _collaterals, uint[] memory _amounts) view external returns (uint256);
    function getValueVC(address _collateral, uint _amount) view external returns (uint);
    function getValueRVC(address _collateral, uint _amount) view external returns (uint);
    function getValueVCforTCR(address _collateral, uint _amount) view external returns (uint VC, uint256 VCforTCR);
    function getValueUSD(address _collateral, uint _amount) view external returns (uint256);


    // ======= VIEW FUNCTIONS FOR CONTRACT FUNCTIONALITY =======
    function getYetiFinanceTreasury() external view returns (address);
    function getYetiFinanceTreasurySplit() external view returns (uint256);
    function getRedemptionBorrowerFeeSplit() external view returns (uint256);
    function getYUSDFeeRecipient() external view returns (address);
    function leverUpEnabled() external view returns (bool);
    function getMaxCollsInTrove() external view returns (uint);
    function getFeeSplitInformation() external view returns (uint256, address, address);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IPriceFeed {

    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);

    // --- Function ---
    // function fetchPrice() external returns (uint);

    function fetchPrice_v() view external returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface IFeeCurve {
    function setAddresses(address _controllerAddress) external;

    function setDecayTime(uint _decayTime) external;

    function setDollarCap(uint _dollarCap) external;

    function initialized() external view returns (bool);

    /** 
     * Returns fee based on inputted collateral VC balance and total VC balance of system. 
     * fee is in terms of percentage * 1e18. 
     * If the fee were 1%, this would be 0.01 * 1e18 = 1e16
     */
    function getFee(uint256 _collateralVCInput, uint256 _collateralVCBalancePost, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external view returns (uint256 fee);

    // Same function, updates the fee as well. Called only by controller.
    function getFeeAndUpdate(uint256 _collateralVCInput, uint256 _totalCollateralVCBalance, uint256 _totalVCBalancePre, uint256 _totalVCBalancePost) external returns (uint256 fee);

    // Function for setting the old fee curve's last fee cap / value to the new fee cap / value. 
    // Called only by controller.
    function setFeeCapAndTime(uint256 _lastFeePercent, uint256 _lastFeeTime) external;

    // Gets the fee cap and time currently. Used for setting new values for next fee curve. 
    // returns lastFeePercent, lastFeeTime
    function getFeeCapAndTime() external view returns (uint256 _lastFeePercent, uint256 _lastFeeTime);

    /** 
     * Returns fee based on decay since last fee calculation, which we take to be 
     * a reasonable fee amount. If it has decayed a certain amount since then, we let
     * the new fee amount slide. 
     */
    function calculateDecayedFee() external view returns (uint256 fee);
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
    function sendCollateralsUnwrap(
        address _from,
        address _to,
        address[] memory _tokens,
        uint[] memory _amounts) external;

    function sendSingleCollateral(address _to, address _token, uint256 _amount) external;

    function sendSingleCollateralUnwrap(address _from, address _to, address _token, uint256 _amount) external;

    function getCollateralVC(address collateralAddress) external view returns (uint);
    function addCollateralType(address _collateral) external;

    function getVCSystem() external view returns (uint256 totalVCSystem);

    function getVCforTCRSystem() external view returns (uint256 totalVC, uint256 totalVCforTCR);

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IPool.sol";

interface IDefaultPool is IPool {
    // --- Events ---
    event DefaultPoolYUSDDebtUpdated(uint _YUSDDebt);
    event DefaultPoolETHBalanceUpdated(uint _ETH);

    // --- Functions ---
    
    function sendCollsToActivePool(address[] memory _collaterals, uint[] memory _amounts, address _borrower) external;
    function addCollateralType(address _collateral) external;
    function getCollateralVC(address collateralAddress) external view returns (uint);

    function getAllAmounts() external view returns (uint256[] memory);
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
        uint256 _newRICR,
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

    function getNode(address _id) external view returns (bool, address, address, uint256, uint256, uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function getOldBoostedRICR(address _id) external view returns (uint256);

    function getTimeSinceBoostUpdated(address _id) external view returns (uint256);

    function getBoost(address _id) external view returns (uint256);

    function getDecayedBoost(address _id) external view returns (uint256);

    function getLiquidatableTrovesSize() external view returns (uint256);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);

    function changeBoostMinuteDecayFactor(uint256 _newBoostMinuteDecayFactor) external;

    function changeGlobalBoostMultiplier(uint256 _newGlobalBoostMultiplier) external;

    function updateLiquidatableTrove(address _id, bool _isLiquidatable) external;

    function reInsertMany(address[] memory _ids, uint256[] memory _newRICRs, address[] memory _prevIds, address[] memory _nextIds) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Dependencies/YetiCustomBase.sol";
import "./ICollateralReceiver.sol";


interface ICollSurplusPool is ICollateralReceiver {

    // --- Events ---

    event CollBalanceUpdated(address indexed _account);
    event CollateralSent(address _to);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _troveManagerRedemptionsAddress,
        address _activePoolAddress,
        address _controllerAddress,
        address _yusdTokenAddress
    ) external;

    function getCollVC() external view returns (uint);

    function getTotalRedemptionBonus() external view returns (uint256);

    function getAmountClaimable(address _account, address _collateral) external view returns (uint);

    function hasClaimableCollateral(address _account) external view returns (bool);
    
    function getRedemptionBonus(address _account) external view returns (uint256);

    function getCollateral(address _collateral) external view returns (uint);

    function getAllCollateral() external view returns (address[] memory, uint256[] memory);

    function accountSurplus(address _account, address[] memory _tokens, uint[] memory _amounts) external;

    function accountRedemptionBonus(address _account, uint256 _amount) external;

    function claimCollateral() external;

    function addCollateralType(address _collateral) external;
}

// SPDX-License-Identifier: UNLICENSED

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

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(isOwner(), "CallerNotOwner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
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

contract CheckContract {
    /**
     * @notice Check that the account is an already deployed non-destroyed contract.
     * @dev See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     * @param _account The address of the account to be checked 
    */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size != 0, "Account code size cannot be zero");
    }
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

    function getVCforTCR() external view returns (uint totalVC, uint totalVCforTCR);

    function getCollateral(address collateralAddress) external view returns (uint);

    function getAllCollateral() external view returns (address[] memory, uint256[] memory);

    function getYUSDDebt() external view returns (uint);

    function increaseYUSDDebt(uint _amount) external;

    function decreaseYUSDDebt(uint _amount) external;

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

interface ICollateralReceiver {
    function receiveCollateral(address[] memory _tokens, uint[] memory _amounts) external;
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

    uint constant public DECIMAL_PRECISION = 1e18;

    // Collateral math

    // gets the sum of _coll1 and _coll2
    function _sumColls(newColls memory _coll1, newColls memory _coll2)
        internal
        view
        returns (newColls memory finalColls)
    {
        uint256 coll2Len = _coll2.tokens.length;
        uint256 coll1Len = _coll1.tokens.length;
        if (coll2Len == 0) {
            return _coll1;
        } else if (coll1Len == 0) {
            return _coll2;
        }
        newColls memory coll3;
        coll3.tokens = new address[](coll1Len + coll2Len);
        coll3.amounts = new uint256[](coll1Len + coll2Len);

        uint256 i = 0;
        uint256 j = 0;
        uint256 k = 0;

        uint256[] memory tokenIndices1 = controller.getIndices(_coll1.tokens);
        uint256[] memory tokenIndices2 = controller.getIndices(_coll2.tokens);

        uint256 tokenIndex1 = tokenIndices1[i];
        uint256 tokenIndex2 = tokenIndices2[j];

        while (true) {
            if (tokenIndex1 < tokenIndex2) {
                coll3.tokens[k] = _coll1.tokens[i];
                coll3.amounts[k] = _coll1.amounts[i];
                ++i;
                if (i == coll1Len){
                    break;
                }
                tokenIndex1 = tokenIndices1[i];
            } else if (tokenIndex2 < tokenIndex1){
                coll3.tokens[k] = _coll2.tokens[j];
                coll3.amounts[k] = _coll2.amounts[j];
                ++j;
                 if (j == coll2Len){
                    break;
                }
                tokenIndex2 = tokenIndices2[j];
            } else {
                coll3.tokens[k] = _coll1.tokens[i];
                coll3.amounts[k] = _coll1.amounts[i].add(_coll2.amounts[j]);
                ++i;
                ++j;
                 if (i == coll1Len || j == coll2Len){
                    break;
                }
                tokenIndex1 = tokenIndices1[i];
                tokenIndex2 = tokenIndices2[j];
            }
            ++k;
        }
        ++k;
        while (i < coll1Len) {
            coll3.tokens[k] = _coll1.tokens[i];
            coll3.amounts[k] = _coll1.amounts[i];
            ++i;
            ++k;
        }
        while (j < coll2Len){
            coll3.tokens[k] = _coll2.tokens[j];
            coll3.amounts[k] = _coll2.amounts[j];
            ++j;
            ++k;
        }

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

// SPDX-License-Identifier: UNLICENSED

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