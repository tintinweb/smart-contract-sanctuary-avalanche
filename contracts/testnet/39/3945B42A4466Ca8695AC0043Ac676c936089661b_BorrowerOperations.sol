// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "../Interfaces/IBorrowerOperations.sol";
import "../Interfaces/ITroveManager.sol";
import "../Interfaces/IYUSDToken.sol";
import "../Interfaces/ICollSurplusPool.sol";
import "../Interfaces/ISortedTroves.sol";
import "../Interfaces/IYetiController.sol";
import "../Interfaces/IYetiLever.sol";
import "../Interfaces/IERC20.sol";
import "../Interfaces/IYetiVaultToken.sol";
import "../Dependencies/LiquityBase.sol";
import "../Dependencies/SafeMath.sol";
import "../Dependencies/ReentrancyGuardUpgradeable.sol";
import "../Dependencies/SafeERC20.sol";

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
 * @title Handles most of external facing trove activities that a user would make with their own trove
 * @notice Trove activities like opening, closing, adjusting, increasing leverage, etc
 *
 *
 * A summary of Lever Up:
 * Takes in a collateral token A, and simulates borrowing of YUSD at a certain collateral ratio and
 * buying more token A, putting back into protocol, buying more A, etc. at a certain leverage amount.
 * So if at 3x leverage and 1000$ token A, it will mint 1000 * 3x * 2/3 = $2000 YUSD, then swap for
 * token A by using some router strategy, returning a little under $2000 token A to put back in the
 * trove. The number here is 2/3 because the math works out to be that collateral ratio is 150% if
 * we have a 3x leverage. They now have a trove with $3000 of token A and a collateral ratio of 150%.
 * Using leverage will not return YUSD debt for the borrower.
 *
 * Unlever is the opposite of this, and will take collateral in a borrower's trove, sell it on the market
 * for YUSD, and attempt to pay back a certain amount of YUSD debt in a user's trove with that amount.
 *
 */

contract BorrowerOperations is LiquityBase, IBorrowerOperations, ReentrancyGuardUpgradeable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    bytes32 public constant NAME = "BorrowerOperations";

    // --- Connected contract declarations ---

    ITroveManager internal troveManager;

    address internal gasPoolAddress;

    ICollSurplusPool internal collSurplusPool;

    IYUSDToken internal yusdToken;

    ISortedTroves internal sortedTroves;

    address internal activePoolAddress;

    /* --- Variable container structs  ---

    Used to hold, return and assign variables inside a function, in order to avoid the error:
    "CompilerError: Stack too deep". */

    struct AdjustTrove_Params {
        uint256[] _leverages;
        address[] _collsIn;
        uint256[] _amountsIn;
        address[] _collsOut;
        uint256[] _amountsOut;
        uint256[] _maxSlippages;
        uint256 _YUSDChange;
        uint256 _totalYUSDDebtFromLever;
        address _upperHint;
        address _lowerHint;
        uint256 _maxFeePercentage;
        bool _isDebtIncrease;
        bool _isUnlever;
    }

    struct LocalVariables_adjustTrove {
        uint256 netDebtChange;
        uint256 collChangeRVC;
        uint256 currVC;
        uint256 currRVC;
        uint256 newVC;
        uint256 newRVC;
        uint256 debt;
        address[] currAssets;
        uint256[] currAmounts;
        address[] newAssets;
        uint256[] newAmounts;
        uint256 oldICR;
        uint256 newICR;
        uint256 YUSDFee;
        uint256 variableYUSDFee;
        uint256 newDebt;
        uint256 VCin;
        uint256 RVCin;
        uint256 VCout;
        uint256 RVCout;
        uint256 maxFeePercentageFactor;
        uint256 entireSystemCollVC;
        uint256 entireSystemCollRVC;
        uint256 entireSystemDebt;
        uint256 boostFactor;
        bool isRVCIncrease;
        bool isRecoveryMode;
    }

    struct OpenTrove_Params {
        uint256[] _leverages;
        uint256 _maxFeePercentage;
        uint256 _YUSDAmount;
        uint256 _totalYUSDDebtFromLever;
        address _upperHint;
        address _lowerHint;
    }

    struct LocalVariables_openTrove {
        uint256 YUSDFee;
        uint256 netDebt;
        uint256 compositeDebt;
        uint256 ICR;
        uint256 VC;
        uint256 RVC;
        uint256 entireSystemCollVC;
        uint256 entireSystemCollRVC;
        uint256 entireSystemDebt;
        uint256 boostFactor;
        bool isRecoveryMode;
    }

    struct LocalVariables_closeTrove {
        uint256 entireSystemCollRVC;
        uint256 entireSystemDebt;
        uint256 debt;
        address[] colls;
        uint256[] amounts;
        uint256 troveRVC;
        bool isRecoveryMode;
    }

    struct ContractsCache {
        ITroveManager troveManager;
        IActivePool activePool;
        IYUSDToken yusdToken;
        IYetiController controller;
    }

    enum BorrowerOperation {
        openTrove,
        closeTrove,
        adjustTrove
    }

    event TroveCreated(address indexed _borrower, uint256 arrayIndex);

    event TroveUpdated(
        address indexed _borrower,
        uint256 _debt,
        address[] _tokens,
        uint256[] _amounts,
        BorrowerOperation operation
    );
    event YUSDBorrowingFeePaid(address indexed _borrower, uint256 _YUSDFee);

    event VariableFeePaid(address indexed _borrower, uint256 _YUSDVariableFee);

    // --- Dependency setters ---
    bool private addressSet;
    /**
     * @notice Sets the addresses of all contracts used. Can only be called once. 
     */
    function setAddresses(
        address _troveManagerAddress,
        address _activePoolAddress,
        address _defaultPoolAddress,
        address _gasPoolAddress,
        address _collSurplusPoolAddress,
        address _sortedTrovesAddress,
        address _yusdTokenAddress,
        address _controllerAddress
    ) external override {
        require(addressSet == false, "Addresses already set");
        addressSet = true;
        __ReentrancyGuard_init();
        
        troveManager = ITroveManager(_troveManagerAddress);
        activePool = IActivePool(_activePoolAddress);
        activePoolAddress = _activePoolAddress;
        defaultPool = IDefaultPool(_defaultPoolAddress);
        controller = IYetiController(_controllerAddress);
        gasPoolAddress = _gasPoolAddress;
        collSurplusPool = ICollSurplusPool(_collSurplusPoolAddress);
        sortedTroves = ISortedTroves(_sortedTrovesAddress);
        yusdToken = IYUSDToken(_yusdTokenAddress);
    }

    // --- Borrower Trove Operations ---

    /**
     * @notice Main function to open a new trove. Takes in collateral and adds it to a trove, resulting in
     *  a collateralized debt position. The resulting ICR (individual collateral ratio) of the trove is indicative
     *  of the safety of the trove.
     * @param _maxFeePercentage The maximum percentage of the Collateral VC in that can be taken as fee.
     * @param _YUSDAmount Amount of YUSD to open the trove with. The resulting YUSD Amount + 200 YUSD Gas compensation
     *  plus any YUSD fees that occur must be > 2000. This min debt amount is intended to reduce the amount of small troves
     *  that are opened, since liquidating small troves may clog the network and we want to prioritize liquidations of larger
     *  troves in turbulant gas conditions.
     * @param _upperHint The address of the trove above this one in the sorted troves list.
     * @param _lowerHint The address of the trove below this one in the sorted troves list.
     * @param _colls The addresses of collaterals to be used in the trove. Must be passed in, in order of the whitelisted collateral.
     * @param _amounts The amounts of each collateral to be used in the trove. If passing in a vault token, the amount must be the 
     *  amount of the underlying asset, but the address passed in must be the vault token address. So, for example, if trying to
     *  open a trove with Benqi USDC (qiUSDC), then the address passed in must be Yeti Vault qiUSDC, but the amount must be of 
     *  qiUSDC in your wallet. The resulting amount in your trove will be of the vault token, so to see how much actual qiUSDC you have
     *  you must use the conversion ratio on the vault contract. 
     */
    function openTrove(
        uint256 _maxFeePercentage,
        uint256 _YUSDAmount,
        address _upperHint,
        address _lowerHint,
        address[] calldata _colls,
        uint256[] memory _amounts
    ) external override nonReentrant {
        ContractsCache memory contractsCache = ContractsCache(
            troveManager,
            activePool,
            yusdToken,
            controller
        );
        _requireInputCorrect(_amounts.length != 0);

        // check that all _colls collateral types are in the controller and in correct order.
        _requireValidCollateral(_colls, _amounts, contractsCache.controller, true);

        // Check that below max colls in trove.
        _requireValidTroveCollsLen(contractsCache.controller, _colls.length);

        // transfer collateral into ActivePool
        _transferCollateralsIntoActivePool(_colls, _amounts);

        OpenTrove_Params memory params = OpenTrove_Params(
            new uint256[](_colls.length),
            _maxFeePercentage,
            _YUSDAmount,
            0,
            _upperHint,
            _lowerHint
        );
        _openTroveInternal(params, _colls, _amounts, contractsCache);
    }

    /**
     * @notice Opens a trove while leveraging up on the collateral passed in.
     * @dev Takes in a leverage amount (11x) and a token, and calculates the amount
     * of that token that would be at the specific collateralization ratio. Mints YUSD
     * according to the price of the token and the amount. Calls internal leverUp
     * function to perform the swap through a route.
     * Then opens a trove with the new collateral from the swap, ensuring that
     * the amount is enough to cover the debt. Reverts if the swap was
     * not able to get the correct amount of collateral according to slippage passed in.
     * _leverage is like 11e18 for 11x.
     * @param _maxFeePercentage The maximum percentage of the Collateral VC in that can be taken as fee.
     * @param _YUSDAmount Amount of YUSD to open the trove with. This is separate from the amount of YUSD taken against the leveraged amounts
     *  for each collateral which is levered up on. The resulting YUSD Amount + 200 YUSD Gas compensation plus any YUSD
     *  fees plus amount from leverages must be > 2000. This min debt amount is intended to reduce the amount of small troves
     *  that are opened, since liquidating small troves may clog the network and we want to prioritize liquidations of larger
     *  troves in turbulant gas conditions.
     * @param _upperHint The address of the trove above this one in the sorted troves list.
     * @param _lowerHint The address of the trove below this one in the sorted troves list.
     * @param _colls The addresses of collaterals to be used in the trove. Must be passed in, in order of the whitelisted collateral.
     * @param _amounts The amounts of each collateral to be used in the trove. If passing in a vault token, the amount must be the 
     *  amount of the underlying asset, but the address passed in must be the vault token address. So, for example, if trying to
     *  open a trove with Benqi USDC (qiUSDC), then the address passed in must be Yeti Vault qiUSDC, but the amount must be of 
     *  qiUSDC in your wallet. The resulting amount in your trove will be of the vault token, so to see how much actual qiUSDC you have
     *  you must use the conversion ratio on the vault contract. 
     * @param _leverages The leverage amounts on each collateral to be used in the lever up function. If 0 there is no leverage on that coll
     * @param _maxSlippages The max slippage amount when swapping YUSD for collateral
     */
    function openTroveLeverUp(
        uint256 _maxFeePercentage,
        uint256 _YUSDAmount,
        address _upperHint,
        address _lowerHint,
        address[] memory _colls,
        uint256[] memory _amounts,
        uint256[] memory _leverages,
        uint256[] calldata _maxSlippages
    ) external override nonReentrant {
        ContractsCache memory contractsCache = ContractsCache(
            troveManager,
            activePool,
            yusdToken,
            controller
        );
        _requireLeverUpEnabled(contractsCache.controller);
        uint256 collsLen = _colls.length;
        _requireInputCorrect(collsLen != 0);
        // check that all _colls collateral types are in the controller and in correct order.
        _requireValidCollateral(_colls, _amounts, contractsCache.controller, true);
        // Check that below max colls in trove.
        _requireValidTroveCollsLen(contractsCache.controller, _colls.length);
        // Must check additional passed in arrays
        _requireInputCorrect(collsLen == _leverages.length && collsLen == _maxSlippages.length);
        // Keep track of total YUSD from lever and pass into internal open trove.
        uint256 totalYUSDDebtFromLever;
        for (uint256 i; i < collsLen; ++i) {
            if (_maxSlippages[i] != 0) {
                (uint256 additionalTokenAmount, uint256 additionalYUSDDebt) = _singleLeverUp(
                    _colls[i],
                    _amounts[i],
                    _leverages[i],
                    _maxSlippages[i],
                    contractsCache
                );
                // Transfer into active pool, non levered amount, and add to additional token amount returned. 
                // additional token amount was set to the original amount * leverage.
                // The amount of receipt tokens received back is the amount which we will use to open the trove.
                _amounts[i] = additionalTokenAmount.add(_singleTransferCollateralIntoActivePool(_colls[i], _amounts[i]));
                totalYUSDDebtFromLever = totalYUSDDebtFromLever.add(additionalYUSDDebt);
            } else {
                // Otherwise skip and do normal transfer that amount into active pool.
                require(_leverages[i] == 0, "2");
                _amounts[i] = _singleTransferCollateralIntoActivePool(_colls[i], _amounts[i]);
            }
        }
        _YUSDAmount = _YUSDAmount.add(totalYUSDDebtFromLever);

        OpenTrove_Params memory params = OpenTrove_Params(
            _leverages,
            _maxFeePercentage,
            _YUSDAmount,
            totalYUSDDebtFromLever,
            _upperHint,
            _lowerHint
        );
        _openTroveInternal(params, _colls, _amounts, contractsCache);
    }

    /**
     * @notice internal function for minting yusd at certain leverage and max slippage, and then performing
     * swap with controller's approved router.
     * @param _token collateral address
     * @param _amount amount of collateral to lever up on
     * @param _leverage amount to leverage. 11e18 = 11x
     * @param _maxSlippage max slippage amount for swap YUSD to collateral
     * @return _finalTokenAmount final amount of the collateral token
     * @return _additionalYUSDDebt Total amount of YUSD Minted to be added to total.
     */
    function _singleLeverUp(
        address _token,
        uint256 _amount,
        uint256 _leverage,
        uint256 _maxSlippage,
        ContractsCache memory contractsCache
    ) internal returns (uint256 _finalTokenAmount, uint256 _additionalYUSDDebt) {
        require(_leverage > DECIMAL_PRECISION && _maxSlippage <= DECIMAL_PRECISION, "2");
        address router = _getDefaultRouterAddress(contractsCache.controller, _token);
        // leverage is 5e18 for 5x leverage. Minus 1 for what the user already has in collateral value.
        uint256 _additionalTokenAmount = _amount.mul(_leverage.sub(DECIMAL_PRECISION)).div(
            DECIMAL_PRECISION
        );
        // Calculate USD value to see how much YUSD to mint.
        _additionalYUSDDebt = _getValueUSD(
            contractsCache.controller,
            _token,
            _additionalTokenAmount
        );

        // 1/(1-1/ICR) = leverage. (1 - 1/ICR) = 1/leverage
        // 1 - 1/leverage = 1/ICR. ICR = 1/(1 - 1/leverage) = (1/((leverage-1)/leverage)) = leverage / (leverage - 1)
        // ICR = leverage / (leverage - 1)

        // ICR = VC value of collateral / debt
        // debt = VC value of collateral / ICR.
        // debt = VC value of collateral * (leverage - 1) / leverage

        uint256 slippageAdjustedValue = _additionalTokenAmount
            .mul(DECIMAL_PRECISION.sub(_maxSlippage))
            .div(DECIMAL_PRECISION);

        // Mint to the router.
        _yusdTokenMint(contractsCache.yusdToken, router, _additionalYUSDDebt);

        // route will swap the tokens and transfer it to the active pool automatically. Router will send to active pool
        IERC20 erc20Token = IERC20(_token);
        uint256 balanceBefore = _IERC20TokenBalanceOf(erc20Token, activePoolAddress);
        _finalTokenAmount = IYetiLever(router).route(
            activePoolAddress,
            address(contractsCache.yusdToken),
            _token,
            _additionalYUSDDebt,
            slippageAdjustedValue
        );
        require(
            _IERC20TokenBalanceOf(erc20Token, activePoolAddress) ==
                balanceBefore.add(_finalTokenAmount),
            "4"
        );
    }

    /**
     * @notice Opens Trove Internal
     * @dev amounts should be a uint array giving the amount of each collateral
     * to be transferred in in order of the current controller
     * Should be called *after* collateral has been already sent to the active pool
     * Should confirm _colls, is valid collateral prior to calling this
     */
    function _openTroveInternal(
        OpenTrove_Params memory params,
        address[] memory _colls,
        uint256[] memory _amounts,
        ContractsCache memory contractsCache
    ) internal {
        LocalVariables_openTrove memory vars;
        (
            vars.isRecoveryMode,
            vars.entireSystemCollVC,
            vars.entireSystemCollRVC,
            vars.entireSystemDebt
        ) = _checkRecoveryModeAndSystem();

        _requireValidMaxFeePercentage(params._maxFeePercentage, vars.isRecoveryMode);
        _requireTroveStatus(contractsCache.troveManager, false);

        // Start with base amount before adding any fees.
        vars.netDebt = params._YUSDAmount;

        // For every collateral type in, calculate the VC, RVC, and get the variable fee
        (vars.VC, vars.RVC) = _getValuesVCAndRVC(contractsCache.controller, _colls, _amounts);

        if (!vars.isRecoveryMode) {
            // when not in recovery mode, add in the 0.5% fee
            vars.YUSDFee = _triggerBorrowingFee(
                contractsCache,
                params._YUSDAmount,
                vars.VC, // here it is just VC in, which is always larger than YUSD amount
                params._maxFeePercentage
            );
            params._maxFeePercentage = params._maxFeePercentage.sub(
                vars.YUSDFee.mul(DECIMAL_PRECISION).div(vars.VC)
            );
        }

        // Add in variable fee. Always present, even in recovery mode.
        {
            uint256 variableFee;
            (variableFee, vars.boostFactor) = _getTotalVariableDepositFeeAndUpdate(
                contractsCache.controller,
                _colls,
                _amounts,
                params._leverages,
                vars.entireSystemCollVC,
                vars.VC,
                0
            );
            _requireUserAcceptsFee(variableFee, vars.VC, params._maxFeePercentage);
            _mintYUSDFeeAndSplit(contractsCache, variableFee);
            vars.YUSDFee = vars.YUSDFee.add(variableFee);
            emit VariableFeePaid(msg.sender, variableFee);
        }

        // Adds total fees to netDebt
        vars.netDebt = vars.netDebt.add(vars.YUSDFee); // The raw debt change includes the fee

        _requireAtLeastMinNetDebt(vars.netDebt);
        // ICR is based on the composite debt,
        // i.e. the requested YUSD amount + YUSD borrowing fee + YUSD deposit fee + YUSD gas comp.
        // _getCompositeDebt returns  vars.netDebt + YUSD gas comp = 200
        vars.compositeDebt = _getCompositeDebt(vars.netDebt);

        vars.ICR = _computeCR(vars.VC, vars.compositeDebt);

        if (vars.isRecoveryMode) {
            _requireICRisAboveCCR(vars.ICR);
        } else {
            _requireICRisAboveMCR(vars.ICR);
            _requireNewTCRisAboveCCR(
                _getNewTCRFromTroveChange(
                    vars.entireSystemCollRVC,
                    vars.entireSystemDebt,
                    vars.RVC,
                    vars.compositeDebt,
                    true,
                    true
                )
            ); // bools: coll increase, debt increase);
        }

        // Set the trove struct's properties (1 = active)
        contractsCache.troveManager.setTroveStatus(msg.sender, 1);

        _increaseTroveDebt(contractsCache.troveManager, vars.compositeDebt);

        _updateTroveCollAndStakeAndTotalStakes(contractsCache.troveManager, _colls, _amounts);

        contractsCache.troveManager.updateTroveRewardSnapshots(msg.sender);

        // Pass in fee as percent of total VC in for boost.
        sortedTroves.insert(
            msg.sender,
            _computeCR(vars.RVC, vars.compositeDebt), // insert with new AICR.
            params._upperHint,
            params._lowerHint,
            vars.boostFactor
        );

        // Emit with trove index calculated once inserted
        emit TroveCreated(msg.sender, contractsCache.troveManager.addTroveOwnerToArray(msg.sender));

        // Receive collateral for tracking by active pool
        _activePoolReceiveCollateral(contractsCache.activePool, _colls, _amounts);

        // Send the user the YUSD debt
        _withdrawYUSD(
            contractsCache.activePool,
            contractsCache.yusdToken,
            msg.sender,
            params._YUSDAmount.sub(params._totalYUSDDebtFromLever),
            vars.netDebt
        );

        // Move the YUSD gas compensation to the Gas Pool
        _withdrawYUSD(
            contractsCache.activePool,
            contractsCache.yusdToken,
            gasPoolAddress,
            YUSD_GAS_COMPENSATION,
            YUSD_GAS_COMPENSATION
        );

        emit TroveUpdated(
            msg.sender,
            vars.compositeDebt,
            _colls,
            _amounts,
            BorrowerOperation.openTrove
        );
        emit YUSDBorrowingFeePaid(msg.sender, vars.YUSDFee);
    }

    /**
     * @notice add collateral to trove. If leverage is provided then it will lever up on those collaterals using single lever up function.
     *  Can also be used to just add collateral to the trove.
     * @dev Calls _adjustTrove with correct params. Can only increase collateral and leverage, and add more debt.
     * @param _collsIn The addresses of collaterals to be added to this trove. Must be passed in, in order of the whitelisted collateral.
     * @param _amountsIn The amounts of each collateral to be used in the trove. If passing in a vault token, the amount must be the 
     *  amount of the underlying asset, but the address passed in must be the vault token address. So, for example, if trying to
     *  open a trove with Benqi USDC (qiUSDC), then the address passed in must be Yeti Vault qiUSDC, but the amount must be of 
     *  qiUSDC in your wallet. The resulting amount in your trove will be of the vault token, so to see how much actual qiUSDC you have
     *  you must use the conversion ratio on the vault contract. 
     * @param _leverages The leverage amounts on each collateral to be used in the lever up function. If 0 there is no leverage on that coll
     * @param _maxSlippages The max slippage amount when swapping YUSD for collateral
     * @param _YUSDAmount Amount of YUSD to add to the trove debt. This is separate from the amount of YUSD taken against the leveraged amounts
     *  for each collateral which is levered up on. isDebtIncrease is automatically true.
     * @param _upperHint The address of the trove above this one in the sorted troves list.
     * @param _lowerHint The address of the trove below this one in the sorted troves list.
     * @param _maxFeePercentage The maximum percentage of the Collateral VC in that can be taken as fee.
     */
    function addCollLeverUp(
        address[] memory _collsIn,
        uint256[] memory _amountsIn,
        uint256[] memory _leverages,
        uint256[] memory _maxSlippages,
        uint256 _YUSDAmount,
        address _upperHint,
        address _lowerHint,
        uint256 _maxFeePercentage
    ) external override nonReentrant {
        ContractsCache memory contractsCache = ContractsCache(
            troveManager,
            activePool,
            yusdToken,
            controller
        );
        _requireLeverUpEnabled(contractsCache.controller);
        uint256 collsLen = _collsIn.length;

        // check that all _collsIn collateral types are in the controller and in correct order.
        _requireValidCollateral(_collsIn, _amountsIn, contractsCache.controller, true);

        // Must check that other passed in arrays are correct length
        _requireInputCorrect(collsLen == _leverages.length && collsLen == _maxSlippages.length);

        // Keep track of total YUSD from levering up to pass into adjustTrove
        uint256 totalYUSDDebtFromLever;
        for (uint256 i; i < collsLen; ++i) {
            if (_maxSlippages[i] != 0) {
                (uint256 additionalTokenAmount, uint256 additionalYUSDDebt) = _singleLeverUp(
                    _collsIn[i],
                    _amountsIn[i],
                    _leverages[i],
                    _maxSlippages[i],
                    contractsCache
                );
                // Transfer into active pool, non levered amount, and add to additional token amount returned. 
                // additional token amount was set to the original amount * leverage.
                _amountsIn[i] = additionalTokenAmount.add(_singleTransferCollateralIntoActivePool(_collsIn[i], _amountsIn[i]));
                totalYUSDDebtFromLever = totalYUSDDebtFromLever.add(additionalYUSDDebt);
            } else {
                require(_leverages[i] == 0, "2");
                // Otherwise skip and do normal transfer that amount into active pool.
                _amountsIn[i] = _singleTransferCollateralIntoActivePool(_collsIn[i], _amountsIn[i]);
            }
        }
        AdjustTrove_Params memory params;
        params._upperHint = _upperHint;
        params._lowerHint = _lowerHint;
        params._maxFeePercentage = _maxFeePercentage;
        params._leverages = _leverages;
        _YUSDAmount = _YUSDAmount.add(totalYUSDDebtFromLever);
        params._totalYUSDDebtFromLever = totalYUSDDebtFromLever;

        params._YUSDChange = _YUSDAmount;
        params._isDebtIncrease = true;

        params._collsIn = _collsIn;
        params._amountsIn = _amountsIn;
        _adjustTrove(params, contractsCache);
    }

    /**
     * @notice Adjusts trove with multiple colls in / out. Can either add or remove collateral. No leverage available with this function.
     *   Can increase or remove debt as well. Cannot do both adding and removing the same collateral at the same time.
     * @dev Calls _adjustTrove with correct params
     * @param _collsIn The addresses of collaterals to be added to this trove. Must be passed in, in order of the whitelisted collateral.
     * @param _amountsIn The amounts of each collateral to be used in the trove. If passing in a vault token, the amount must be the 
     *  amount of the underlying asset, but the address passed in must be the vault token address. So, for example, if trying to
     *  open a trove with Benqi USDC (qiUSDC), then the address passed in must be Yeti Vault qiUSDC, but the amount must be of 
     *  qiUSDC in your wallet. The resulting amount in your trove will be of the vault token, so to see how much actual qiUSDC you have
     *  you must use the conversion ratio on the vault contract. 
     * @param _collsOut The addresses of collaterals to be removed from this trove. Must be passed in, in order of the whitelisted collateral.
     * @param _amountsOut The amounts of each collateral to be removed from this trove. Withdrawing a vault token would require you to have
     *  the amount of the vault token, unlike when depositing. So, for example, if trying to open a trove with Benqi USDC (qiUSDC), then the 
     *  address passed in must be Yeti Vault qiUSDC, and the amount is also Yeti Vault qi
     * @param _YUSDChange Amount of YUSD to either withdraw or pay back. The resulting YUSD Amount + 200 YUSD Gas compensation plus any YUSD
     *  fees plus amount from leverages must be > 2000. This min debt amount is intended to reduce the amount of small troves
     *  that are opened, since liquidating small troves may clog the network and we want to prioritize liquidations of larger
     *  troves in turbulant gas conditions.
     * @param _isDebtIncrease True if more debt is withdrawn, false if it is paid back.
     * @param _upperHint The address of the trove above this one in the sorted troves list.
     * @param _lowerHint The address of the trove below this one in the sorted troves list.
     * @param _maxFeePercentage The maximum percentage of the Collateral VC in that can be taken as fee. There is an edge case here if the
     *   VC in is less than the new debt taken out, then it will be assessed on the debt instead.
     */
    function adjustTrove(
        address[] calldata _collsIn,
        uint256[] memory _amountsIn,
        address[] calldata _collsOut,
        uint256[] calldata _amountsOut,
        uint256 _YUSDChange,
        bool _isDebtIncrease,
        address _upperHint,
        address _lowerHint,
        uint256 _maxFeePercentage
    ) external override nonReentrant {
        ContractsCache memory contractsCache = ContractsCache(
            troveManager,
            activePool,
            yusdToken,
            controller
        );
        // check that all _collsIn collateral types are in the controller
        // Replaces calls to requireValidCollateral and condenses them into one controller call.
        {
            uint256 collsInLen = _collsIn.length;
            uint256 collsOutLen = _collsOut.length;
            _requireInputCorrect(
                collsOutLen == _amountsOut.length && collsInLen == _amountsIn.length
            );
            for (uint256 i; i < collsInLen; ++i) {
                _requireInputCorrect(_amountsIn[i] != 0);
            }
            for (uint256 i; i < collsOutLen; ++i) {
                _requireInputCorrect(_amountsOut[i] != 0);
            }
        }

        // Checks that the collateral list is in order of the whitelisted collateral efficiently in controller.
        contractsCache.controller.checkCollateralListDouble(_collsIn, _collsOut);

        // pull in deposit collateral
        _transferCollateralsIntoActivePool(_collsIn, _amountsIn);

        AdjustTrove_Params memory params;
        params._leverages = new uint256[](_collsIn.length);
        params._collsIn = _collsIn;
        params._amountsIn = _amountsIn;
        params._collsOut = _collsOut;
        params._amountsOut = _amountsOut;
        params._YUSDChange = _YUSDChange;
        params._isDebtIncrease = _isDebtIncrease;
        params._upperHint = _upperHint;
        params._lowerHint = _lowerHint;
        params._maxFeePercentage = _maxFeePercentage;

        _adjustTrove(params, contractsCache);
    }

    /**
     * @notice Alongside a debt change, this function can perform either a collateral top-up or a collateral withdrawal
     * @dev the ith element of _amountsIn and _amountsOut corresponds to the ith element of the addresses _collsIn and _collsOut passed in
     * Should be called after the collsIn has been sent to ActivePool. Adjust trove params are defined in above functions. 
     */
    function _adjustTrove(AdjustTrove_Params memory params, ContractsCache memory contractsCache)
        internal
    {
        LocalVariables_adjustTrove memory vars;

        // Checks if we are in recovery mode, and since that requires calculations of entire system coll and debt, return that here too. 
        (
            vars.isRecoveryMode,
            vars.entireSystemCollVC,
            vars.entireSystemCollRVC,
            vars.entireSystemDebt
        ) = _checkRecoveryModeAndSystem();

        // Require that the max fee percentage is correct (< 100, and if not recovery mode > 0.5)
        _requireValidMaxFeePercentage(params._maxFeePercentage, vars.isRecoveryMode);

        // Checks that at least one array is non-empty, and also that at least one value is 1.
        _requireNonZeroAdjustment(params._amountsIn, params._amountsOut, params._YUSDChange);

        // Require trove is active 
        _requireTroveStatus(contractsCache.troveManager, true);

        // Apply pending rewards so that trove info is up to date
        _applyPendingRewards(contractsCache.troveManager);

        (vars.VCin, vars.RVCin) = _getValuesVCAndRVC(contractsCache.controller, params._collsIn, params._amountsIn);
        (vars.VCout, vars.RVCout) = _getValuesVCAndRVC(contractsCache.controller, params._collsOut, params._amountsOut);

        // If it is a debt increase then we need to take the max of VCin and debt increase and use that number to assess
        // the fee based on the new max fee percentage factor. 
        if (params._isDebtIncrease) {
            vars.maxFeePercentageFactor = (vars.VCin >= params._YUSDChange)
                ? vars.VCin
                : params._YUSDChange;
        } else {
            vars.maxFeePercentageFactor = vars.VCin;
        }
        
        vars.netDebtChange = params._YUSDChange;

        // If the adjustment incorporates a debt increase and system is in Normal Mode, then trigger a borrowing fee
        if (params._isDebtIncrease && !vars.isRecoveryMode) {
            vars.YUSDFee = _triggerBorrowingFee(
                contractsCache,
                params._YUSDChange,
                vars.maxFeePercentageFactor, // max of VC in and YUSD change here to see what the max borrowing fee is triggered on.
                params._maxFeePercentage
            );
            // passed in max fee minus actual fee percent applied so far
            params._maxFeePercentage = params._maxFeePercentage.sub(
                vars.YUSDFee.mul(DECIMAL_PRECISION).div(vars.maxFeePercentageFactor)
            );
            vars.netDebtChange = vars.netDebtChange.add(vars.YUSDFee); // The raw debt change includes the fee
        }

        // get current portfolio in trove
        (vars.currAssets, vars.currAmounts, vars.debt) = _getCurrentTroveState(
            contractsCache.troveManager
        );

        // current VC based on current portfolio and latest prices 
        (vars.currVC, vars.currRVC) = _getValuesVCAndRVC(contractsCache.controller, vars.currAssets, vars.currAmounts);

        // get new portfolio in trove after changes. Will error if invalid changes, if coll decrease is more
        // than the amount possible. 
        (vars.newAssets, vars.newAmounts) = _subColls(
            _sumColls(
                newColls(vars.currAssets, vars.currAmounts),
                newColls(params._collsIn, params._amountsIn)
            ),
            params._collsOut,
            params._amountsOut
        );

        // If there is an increase in the amount of assets in a trove
        if (vars.currAssets.length < vars.newAssets.length) {
            // Check that the result is less than the maximum amount of assets in a trove
            _requireValidTroveCollsLen(contractsCache.controller, vars.currAssets.length);
        }

        // new RVC based on new portfolio and latest prices.
        vars.newVC = vars.currVC.add(vars.VCin).sub(vars.VCout);
        vars.newRVC = vars.currRVC.add(vars.RVCin).sub(vars.RVCout);

        vars.isRVCIncrease = vars.newRVC > vars.currRVC;

        if (vars.isRVCIncrease) {
            vars.collChangeRVC = (vars.newRVC).sub(vars.currRVC);
        } else {
            vars.collChangeRVC = (vars.currRVC).sub(vars.newRVC);
        }

        // If passing in collateral, then get the total variable deposit fee and boost factor. If fee is 
        // nonzero, then require the user accepts this fee as well. 
        if (params._collsIn.length != 0) {
            (vars.variableYUSDFee, vars.boostFactor) = _getTotalVariableDepositFeeAndUpdate(
                contractsCache.controller,
                params._collsIn,
                params._amountsIn,
                params._leverages,
                vars.entireSystemCollVC,
                vars.VCin,
                vars.VCout
            );
            if (vars.variableYUSDFee != 0) {
                _requireUserAcceptsFee(
                    vars.variableYUSDFee,
                    vars.maxFeePercentageFactor,
                    params._maxFeePercentage
                );
                _mintYUSDFeeAndSplit(contractsCache, vars.variableYUSDFee);
                emit VariableFeePaid(msg.sender, vars.variableYUSDFee);
            }
        }

        // Get the trove's old ICR before the adjustment, and what its new ICR will be after the adjustment
        vars.oldICR = _computeCR(vars.currVC, vars.debt);

        vars.debt = vars.debt.add(vars.variableYUSDFee);
        vars.newICR = _computeCR(
            vars.newVC, // if debt increase, then add net debt change and subtract otherwise.
            params._isDebtIncrease
                ? vars.debt.add(vars.netDebtChange)
                : vars.debt.sub(vars.netDebtChange)
        );

        // Check the adjustment satisfies all conditions for the current system mode
        // In Recovery Mode, only allow:
        // - Pure collateral top-up
        // - Pure debt repayment
        // - Collateral top-up with debt repayment
        // - A debt increase combined with a collateral top-up which makes the ICR >= 150% and improves the ICR (and by extension improves the TCR).
        //
        // In Normal Mode, ensure:
        // - The new ICR is above MCR
        // - The adjustment won't pull the TCR below CCR
        if (vars.isRecoveryMode) {
            // Require no coll withdrawal. Require that there is no coll withdrawal. The condition that _amountOut, if
            // nonzero length, has a nonzero amount in each is already checked previously, so we only need to check length here.
            require(params._amountsOut.length == 0, "3");
            if (params._isDebtIncrease) {
                _requireICRisAboveCCR(vars.newICR);
                require(vars.newICR >= vars.oldICR, "3");
            }
        } else {
            // if Normal Mode
            _requireICRisAboveMCR(vars.newICR);
            _requireNewTCRisAboveCCR(
                _getNewTCRFromTroveChange(
                    vars.entireSystemCollRVC,
                    vars.entireSystemDebt,
                    vars.collChangeRVC,
                    vars.netDebtChange,
                    vars.isRVCIncrease,
                    params._isDebtIncrease
                )
            );
        }

        // If eligible, then active pool receives the collateral for its internal logging. 
        if (params._collsIn.length != 0) {
            _activePoolReceiveCollateral(
                contractsCache.activePool,
                params._collsIn,
                params._amountsIn
            );
        }

        // If debt increase, then add pure debt + fees 
        if (params._isDebtIncrease) {
            // if debt increase, increase by both amounts
            vars.newDebt = _increaseTroveDebt(
                contractsCache.troveManager,
                vars.netDebtChange.add(vars.variableYUSDFee)
            );
        } else {
            if (vars.netDebtChange > vars.variableYUSDFee) {
                // if debt decrease, and greater than variable fee, decrease
                vars.newDebt = contractsCache.troveManager.decreaseTroveDebt(
                    msg.sender,
                    vars.netDebtChange - vars.variableYUSDFee
                ); // already checked no safemath needed
            } else {
                // otherwise increase by opposite subtraction
                vars.newDebt = _increaseTroveDebt(
                    contractsCache.troveManager,
                    vars.variableYUSDFee - vars.netDebtChange
                );
            }
        }

        // Based on new assets, update trove coll and stakes. 
        _updateTroveCollAndStakeAndTotalStakes(
            contractsCache.troveManager,
            vars.newAssets,
            vars.newAmounts
        );

        // Re-insert trove in to the sorted list
        sortedTroves.reInsertWithNewBoost(
            msg.sender,
            _computeCR(vars.newRVC, vars.newDebt), // Insert with new AICR
            params._upperHint,
            params._lowerHint,
            vars.boostFactor,
            vars.VCin,
            vars.currVC
        );

        // in case of unlever up
        if (params._isUnlever) {
            // 1. Withdraw the collateral from active pool and perform swap using single unlever up and corresponding router.
            _unleverColls(
                contractsCache,
                params._collsOut,
                params._amountsOut,
                params._maxSlippages
            );
        }

        // When the adjustment is a debt repayment, check it's a valid amount and that the caller has enough YUSD
        if ((!params._isDebtIncrease && params._YUSDChange != 0) || params._isUnlever) {
            _requireAtLeastMinNetDebt(_getNetDebt(vars.debt).sub(vars.netDebtChange));
            _requireValidYUSDRepayment(vars.debt, vars.netDebtChange);
            _requireSufficientYUSDBalance(contractsCache.yusdToken, vars.netDebtChange);
        }

        if (params._isUnlever) {
            // 2. update the trove with the new collateral and debt, repaying the total amount of YUSD specified.
            // if not enough coll sold for YUSD, must cover from user balance
            _repayYUSD(
                contractsCache.activePool,
                contractsCache.yusdToken,
                msg.sender,
                params._YUSDChange
            );
        } else {
            // Use the unmodified _YUSDChange here, as we don't send the fee to the user
            _moveYUSD(
                contractsCache.activePool,
                contractsCache.yusdToken,
                params._YUSDChange.sub(params._totalYUSDDebtFromLever), // 0 in non lever case
                params._isDebtIncrease,
                vars.netDebtChange
            );

            // Additionally move the variable deposit fee to the active pool manually, as it is always an increase in debt
            _withdrawYUSD(
                contractsCache.activePool,
                contractsCache.yusdToken,
                msg.sender,
                0,
                vars.variableYUSDFee
            );

            // transfer withdrawn collateral to msg.sender from ActivePool
            _sendCollateralsUnwrap(contractsCache.activePool, params._collsOut, params._amountsOut);
        }

        emit TroveUpdated(
            msg.sender,
            vars.newDebt,
            vars.newAssets,
            vars.newAmounts,
            BorrowerOperation.adjustTrove
        );
        
        emit YUSDBorrowingFeePaid(msg.sender, vars.YUSDFee);
    }

    /**
     * @notice internal function for un-levering up. Takes the collateral amount specified passed in, and swaps it using the whitelisted
     * router back into YUSD, so that the debt can be paid back for a certain amount.
     * @param _token The address of the collateral to swap to YUSD 
     * @param _amount The amount of collateral to be swapped
     * @param _maxSlippage The maximum slippage allowed in the swap
     * @return _finalYUSDAmount The amount of YUSD to be paid back to the borrower. 
     */
    function _singleUnleverUp(
        ContractsCache memory contractsCache,
        address _token,
        uint256 _amount,
        uint256 _maxSlippage
    ) internal returns (uint256 _finalYUSDAmount) {
        _requireInputCorrect(_maxSlippage <= DECIMAL_PRECISION);
        // Send collaterals to the whitelisted router from the active pool so it can perform the swap
        address router = _getDefaultRouterAddress(contractsCache.controller, _token);
        contractsCache.activePool.sendSingleCollateral(router, _token, _amount);

        // then calculate value amount of expected YUSD output based on amount of token to sell
        uint256 valueOfCollateral = _getValueUSD(contractsCache.controller, _token, _amount);
        uint256 slippageAdjustedValue = valueOfCollateral
            .mul(DECIMAL_PRECISION.sub(_maxSlippage))
            .div(DECIMAL_PRECISION);

        // Perform swap in the router using router.unRoute, which sends the YUSD back to the msg.sender, guaranteeing at least slippageAdjustedValue out.
        _finalYUSDAmount = IYetiLever(router).unRoute(
            msg.sender,
            _token,
            address(contractsCache.yusdToken),
            _amount,
            slippageAdjustedValue
        );
    }

    /**
     * @notice Takes the colls and amounts, transfer non levered from the active pool to the user, and unlevered to this contract
     * temporarily. Then takes the unlevered ones and calls relevant router to swap them to the user.
     * @dev Not called by close trove due to difference in total amount unlevered, ability to swap back some amount as well as unlevering
     * when closing trove.
     * @param _colls addresses of collaterals to unlever 
     * @param _amounts amounts of collaterals to unlever
     * @param _maxSlippages maximum slippage allowed for each swap. If 0, then just send collateral. 
     */
    function _unleverColls(
        ContractsCache memory contractsCache,
        address[] memory _colls,
        uint256[] memory _amounts,
        uint256[] memory _maxSlippages
    ) internal {
        uint256 balanceBefore = _IERC20TokenBalanceOf(contractsCache.yusdToken, msg.sender);
        uint256 totalYUSDUnlevered;
        for (uint256 i; i < _colls.length; ++i) {
            // If max slippages is 0, then it is a normal withdraw. Otherwise it needs to be unlevered.
            if (_maxSlippages[i] != 0) {
                totalYUSDUnlevered = totalYUSDUnlevered.add(
                    _singleUnleverUp(contractsCache, _colls[i], _amounts[i], _maxSlippages[i])
                );
            } else {
                _sendSingleCollateralUnwrap(contractsCache.activePool, _colls[i], _amounts[i]);
            }
        }
        // Do manual check of if balance increased by correct amount of YUSD 
        require(
            _IERC20TokenBalanceOf(contractsCache.yusdToken, msg.sender) ==
                balanceBefore.add(totalYUSDUnlevered),
            "6"
        );
    }

    /**
     * @notice Withdraw collateral from a trove
     * @dev Calls _adjustTrove with correct params.
     * Specifies amount of collateral to withdraw and how much debt to repay,
     * Can withdraw coll and *only* pay back debt using this function. Will take
     * the collateral given and send YUSD back to user. Then they will pay back debt
     * first transfers amount of collateral from active pool then sells.
     * calls _singleUnleverUp() to perform the swaps using the wrappers. should have no fees.
     * @param _collsOut The addresses of collaterals to be removed from this trove. Must be passed in, in order of the whitelisted collateral.
     * @param _amountsOut The amounts of each collateral to be removed from this trove.
     *   The ith element of this array is the amount of the ith collateral in _collsOut
     * @param _maxSlippages Max slippage for each collateral type. If 0, then just withdraw without unlever
     * @param _YUSDAmount Amount of YUSD to pay back. Pulls from user's balance after doing the unlever swap, so it can be from the swap itself 
     *  or it can be from their existing balance of YUSD. The resulting YUSD Amount + 200 YUSD Gas compensation plus any YUSD
     *  fees plus amount from leverages must be > 2000. This min debt amount is intended to reduce the amount of small troves
     *  that are opened, since liquidating small troves may clog the network and we want to prioritize liquidations of larger
     *  troves in turbulant gas conditions.
     * @param _upperHint The address of the trove above this one in the sorted troves list.
     * @param _lowerHint The address of the trove below this one in the sorted troves list.
     */
    function withdrawCollUnleverUp(
        address[] calldata _collsOut,
        uint256[] calldata _amountsOut,
        uint256[] calldata _maxSlippages,
        uint256 _YUSDAmount,
        address _upperHint,
        address _lowerHint
    ) external override nonReentrant {
        ContractsCache memory contractsCache = ContractsCache(
            troveManager,
            activePool,
            yusdToken,
            controller
        );
        // check that all _collsOut collateral types are in the controller, as well as that it doesn't overlap with itself.
        _requireValidCollateral(_collsOut, _amountsOut, contractsCache.controller, false);
        _requireInputCorrect(_amountsOut.length == _maxSlippages.length);

        AdjustTrove_Params memory params;
        params._collsOut = _collsOut;
        params._amountsOut = _amountsOut;
        params._maxSlippages = _maxSlippages;
        params._YUSDChange = _YUSDAmount;
        params._upperHint = _upperHint;
        params._lowerHint = _lowerHint;
        // Will not be used but set to 100% to pass check for valid percent. 
        params._maxFeePercentage = DECIMAL_PRECISION;
        params._isUnlever = true;

        _adjustTrove(params, contractsCache);
    }

    /**
     * @notice Close trove and unlever a certain amount of collateral. For all amounts in amountsOut, transfer out that amount
     *   of collateral and swap them for YUSD. Use that YUSD and YUSD from borrower's account to pay back remaining debt.
     * @dev Calls _adjustTrove with correct params. nonReentrant
     * @param _collsOut Collateral types to withdraw
     * @param _amountsOut Amounts to withdraw. If 0, then just withdraw without unlever
     * @param _maxSlippages Max slippage for each collateral type
     */
    function closeTroveUnlever(
        address[] calldata _collsOut,
        uint256[] calldata _amountsOut,
        uint256[] calldata _maxSlippages
    ) external override nonReentrant {
        _closeTrove(_collsOut, _amountsOut, _maxSlippages, true);
    }

    /**
     * @notice Close trove and send back collateral to user. Pays back debt from their address.
     * @dev Calls _adjustTrove with correct params. nonReentrant
     */
    function closeTrove() external override nonReentrant {
        _closeTrove(new address[](0), new uint256[](0), new uint256[](0), false);
    }

    /**
     * @notice Closes trove by applying pending rewards, making sure that the YUSD Balance is sufficient, and transferring the
     * collateral to the owner, and repaying the debt.
     * @dev if it is a unlever, then it will transfer the collaterals / sell before. Otherwise it will just do it last.
     */
    function _closeTrove(
        address[] memory _collsOut,
        uint256[] memory _amountsOut,
        uint256[] memory _maxSlippages,
        bool _isUnlever
    ) internal {
        ContractsCache memory contractsCache = ContractsCache(
            troveManager,
            activePool,
            yusdToken,
            controller
        );
        LocalVariables_closeTrove memory vars;

        // Require trove is active 
        _requireTroveStatus(contractsCache.troveManager, true);
        // Check recovery mode + get entire system coll RVC and debt. Can't close trove in recovery mode. 
        (
            vars.isRecoveryMode,
            ,
            vars.entireSystemCollRVC,
            vars.entireSystemDebt
        ) = _checkRecoveryModeAndSystem();
        require(!vars.isRecoveryMode, "7");

        _applyPendingRewards(contractsCache.troveManager);

        // Get current trove colls to send back to user or unlever. 
        (vars.colls, vars.amounts, vars.debt) = _getCurrentTroveState(contractsCache.troveManager);
        (, vars.troveRVC) = _getValuesVCAndRVC(contractsCache.controller, vars.colls, vars.amounts);
        {
            // if unlever, will do extra.
            if (_isUnlever) {
                // Withdraw the collateral from active pool and perform swap using single unlever up and corresponding router.
                // tracks the amount of YUSD that is received from swaps. Will send the _YUSDAmount back to repay debt while keeping remainder.
                // The router itself handles unwrapping
                uint256 j;
                uint256 balanceBefore = _IERC20TokenBalanceOf(contractsCache.yusdToken, msg.sender);
                uint256 totalYUSDUnlevered;
                for (uint256 i; i < vars.colls.length; ++i) {
                    uint256 thisAmount = vars.amounts[i];
                    if (j < _collsOut.length && vars.colls[i] == _collsOut[j]) {
                        totalYUSDUnlevered = totalYUSDUnlevered.add(
                            _singleUnleverUp(
                                contractsCache,
                                _collsOut[j],
                                _amountsOut[j],
                                _maxSlippages[j]
                            )
                        );
                        // In the case of unlever, only unlever the amount passed in, and send back the difference
                        thisAmount = thisAmount.sub(_amountsOut[j]);
                        ++j;
                    }
                    // Send back remaining collateral
                    if (thisAmount > 0) {
                        _sendSingleCollateralUnwrap(
                            contractsCache.activePool,
                            vars.colls[i],
                            thisAmount
                        );
                    }
                }
                // Do manual check of if balance increased by correct amount of YUSD 
                require(
                    _IERC20TokenBalanceOf(contractsCache.yusdToken, msg.sender) ==
                        balanceBefore.add(totalYUSDUnlevered),
                    "6"
                );
            }
        }

        // do check after unlever (if applies)
        _requireSufficientYUSDBalance(
            contractsCache.yusdToken,
            vars.debt.sub(YUSD_GAS_COMPENSATION)
        );
        _requireNewTCRisAboveCCR(
            _getNewTCRFromTroveChange(
                vars.entireSystemCollRVC,
                vars.entireSystemDebt,
                vars.troveRVC,
                vars.debt,
                false,
                false
            )
        );

        contractsCache.troveManager.removeStakeAndCloseTrove(msg.sender);

        // Burn the repaid YUSD from the user's balance and the gas compensation from the Gas Pool
        _repayYUSD(
            contractsCache.activePool,
            contractsCache.yusdToken,
            msg.sender,
            vars.debt.sub(YUSD_GAS_COMPENSATION)
        );
        _repayYUSD(
            contractsCache.activePool,
            contractsCache.yusdToken,
            gasPoolAddress,
            YUSD_GAS_COMPENSATION
        );

        // Send the collateral back to the user
        // Also sends the rewards
        if (!_isUnlever) {
            _sendCollateralsUnwrap(contractsCache.activePool, vars.colls, vars.amounts);
        }

        // Essentially delete trove event. 
        emit TroveUpdated(
            msg.sender,
            0,
            new address[](0),
            new uint256[](0),
            BorrowerOperation.closeTrove
        );
    }

    // --- Helper functions ---

    /**
     * @notice Transfer in collateral and send to ActivePool
     * @dev Active pool is where the collateral is held
     */
    function _transferCollateralsIntoActivePool(address[] memory _colls, uint256[] memory _amounts)
        internal
    {
        uint256 amountsLen = _amounts.length;
        for (uint256 i; i < amountsLen; ++i) {
            // this _amounts array update persists during the code that runs after
            _amounts[i] = _singleTransferCollateralIntoActivePool(_colls[i], _amounts[i]);
        }
    }

    /**
     * @notice does one transfer of collateral into active pool. Checks that it transferred to the active pool correctly
     * In the case that it is wrapped token, it will wrap it on transfer in.
     * @return  the amount of receipt tokens it receives back if it is a vault token or otherwise
     * returns the amount of the collateral token returned
     */
    function _singleTransferCollateralIntoActivePool(address _coll, uint256 _amount) internal returns (uint256) {
        if (controller.isWrapped(_coll)) {
            // If vault asset then it wraps it and sends the wrapped version to the active pool
            // The amount is returned as the amount of receipt tokens that the user has. 
            return IYetiVaultToken(_coll).depositFor(msg.sender, address(activePool), _amount);
        } else {
            IERC20(_coll).safeTransferFrom(msg.sender, activePoolAddress, _amount);
            return _amount;
        }
    }

    /**
     * @notice Triggers normal borrowing fee
     * @dev Calculated from base rate and on YUSD amount.
     * @param _YUSDAmount YUSD amount sent in 
     * @param _maxFeePercentageFactor the factor to assess the max fee on 
     * @param _maxFeePercentage the passed in max fee percentage. 
     * @return YUSDFee The resulting one time borrow fee. 
     */
    function _triggerBorrowingFee(
        ContractsCache memory contractsCache,
        uint256 _YUSDAmount,
        uint256 _maxFeePercentageFactor,
        uint256 _maxFeePercentage
    ) internal returns (uint256 YUSDFee) {
        YUSDFee = contractsCache.troveManager.decayBaseRateFromBorrowingAndCalculateFee(_YUSDAmount); // decay the baseRate state variable

        _requireUserAcceptsFee(YUSDFee, _maxFeePercentageFactor, _maxFeePercentage);

        // Send fee to YUSD Fee recipient (sYETI) contract
        _mintYUSDFeeAndSplit(contractsCache, YUSDFee);
    }

    /** 
     * @notice Function for minting YUSD to the treasury and to the recipient sYETI based on params in yeti controller 
     * @param _YUSDFee total fee to split
     */
    function _mintYUSDFeeAndSplit(ContractsCache memory contractsCache, uint256 _YUSDFee) internal {
        // Get fee splits and treasury address. 
        (uint256 feeSplit, address yetiTreasury, address YUSDFeeRecipient) = contractsCache
            .controller
            .getFeeSplitInformation();
        uint256 treasurySplit = feeSplit.mul(_YUSDFee).div(DECIMAL_PRECISION);
        // Mint a percentage to the treasury
        _yusdTokenMint(contractsCache.yusdToken, yetiTreasury, treasurySplit);
        // And the rest to YUSD Fee recipient
        _yusdTokenMint(contractsCache.yusdToken, YUSDFeeRecipient, _YUSDFee - treasurySplit);
    }

    /**
     * @notice Moves the YUSD around based on whether it is an increase or decrease in debt. Mints to active pool or takes from active pool
     * @param _YUSDChange amount of YUSD to mint or burn 
     * @param _isDebtIncrease if true then withdraw (mint) YUSD, otherwise burn it. 
     */
    function _moveYUSD(
        IActivePool _activePool,
        IYUSDToken _yusdToken,
        uint256 _YUSDChange,
        bool _isDebtIncrease,
        uint256 _netDebtChange
    ) internal {
        if (_isDebtIncrease) {
            _withdrawYUSD(_activePool, _yusdToken, msg.sender, _YUSDChange, _netDebtChange);
        } else {
            _repayYUSD(_activePool, _yusdToken, msg.sender, _YUSDChange);
        }
    }

    /**
     * @notice Issue the specified amount of YUSD to _account and increases the total active debt
     * @dev _netDebtIncrease potentially includes a YUSDFee
     */
    function _withdrawYUSD(
        IActivePool _activePool,
        IYUSDToken _yusdToken,
        address _account,
        uint256 _YUSDAmount,
        uint256 _netDebtIncrease
    ) internal {
        _activePool.increaseYUSDDebt(_netDebtIncrease);
        _yusdTokenMint(_yusdToken, _account, _YUSDAmount);
    }

    /**
     * @notice Burn the specified amount of YUSD from _account and decreases the total active debt
     */
    function _repayYUSD(
        IActivePool _activePool,
        IYUSDToken _yusdToken,
        address _account,
        uint256 _YUSDAmount
    ) internal {
        _activePool.decreaseYUSDDebt(_YUSDAmount);
        _yusdToken.burn(_account, _YUSDAmount);
    }

    /**
     * @notice Returns _coll1.amounts minus _amounts2. Used 
     * @dev Invariant that _coll1.tokens and _tokens2 are sorted by whitelist order of token indices from the YetiController. 
     *    So, if WAVAX is whitelisted first, then WETH, then USDC, then [WAVAX, USDC] is a valid input order but [USDC, WAVAX] is not.
     *    This is done for gas efficiency. It will revert if there is a token existing in _tokens2 that is not in _coll1.tokens.
     *    Each iteration we increase the index for _coll1.tokens, and if the token is next in _tokens2, we perform the subtraction 
     *    which will throw an error if it underflows. Since they are ordered, if that next index in _coll1.tokens is less than the next 
     *    index in _tokens2, that means that next index in _tokens 2 is not in _coll1.tokens. If it reaches the end of _tokens2, then 
     *    we add the remaining collaterals in _coll1 to the result and we are done. If it reaches the end of _coll1, then check that 
     *    _coll2 is also empty. We are not sure how many tokens are nonzero so we also have to keep track of it to make their token
     *    array not keep 0 values. It will fill the first k entries post subtraction, so we can loop through the first k entries in 
     *    coll3.tokens, returning the final result coll4. This gives O(n) time complexity for the first loop where n is the number
     *    of tokens in _coll1.tokens. The second loop is O(k) where k is the number of resulting nonzero values. k is bounded by n 
     *    so the resulting time upper bound is O(2n), not depending on L = number of whitelisted collaterals. Since we are using 
     *    _coll1.tokens as the baseline the result of _subColls will also be sorted, keeping the invariant. 
     */
    function _subColls(
        newColls memory _coll1,
        address[] memory _tokens2,
        uint256[] memory _amounts2
    ) internal view returns (address[] memory, uint256[] memory) {
        // If subtracting nothing just return the _coll1 tokens and amounts. 
        if (_tokens2.length == 0) {
            return (_coll1.tokens, _coll1.amounts);
        }
        uint256 coll1Len = _coll1.tokens.length;

        newColls memory coll3;
        coll3.tokens = new address[](coll1Len);
        coll3.amounts = new uint256[](coll1Len);

        uint256[] memory tokenIndices1 = _getIndices(_coll1.tokens);
        uint256[] memory tokenIndices2 = _getIndices(_tokens2);

        // Tracker for the tokens1 array
        uint256 i;
        // Tracker for the tokens2 array
        uint256 j;
        // number of nonzero entries post subtraction.
        uint256 k;

        // Tracker for token whitelist index for all coll2. 
        uint256 tokenIndex2 = tokenIndices2[j];
        // Loop through all tokens1 in order. 
        for (; i < coll1Len; ++i) {
            uint256 tokenIndex1 = tokenIndices1[i];
            // If skipped past tokenIndex 2, then that means it was not seen in token index 1 array and this is an invalid sub. 
            _requireInputCorrect(tokenIndex2 >= tokenIndex1);
            // If they are equal do the subtraction and increment j / token index 2. 
            if (tokenIndex1 == tokenIndex2) {
                coll3.amounts[k] = _coll1.amounts[i].sub(_amounts2[j]);
                // if nonzero, add to coll3 and increment k
                if (coll3.amounts[k] != 0) {
                    coll3.tokens[k] = _coll1.tokens[i];
                    ++k;
                }
                // If we have reached the end of tokens2, exit out to finish adding the remaining coll1 values.
                if (j == _tokens2.length - 1) {
                    ++i;
                    break;
                }
                ++j;
                tokenIndex2 = tokenIndices2[j];
            } else { // Otherwise just add just add the coll1 value without subtracting. 
                coll3.amounts[k] = _coll1.amounts[i];
                coll3.tokens[k] = _coll1.tokens[i];
                ++k;
            }
        }
        while (i < coll1Len) {
            coll3.tokens[k] = _coll1.tokens[i];
            coll3.amounts[k] = _coll1.amounts[i];
            ++i;
            ++k;
        }
        // Require no additional token2 to be processed.
        _requireInputCorrect(j == _tokens2.length - 1);

        // Copy in all nonzero values from coll3 to coll4. The first k values in coll3 will be nonzero. 
        newColls memory coll4;
        coll4.tokens = new address[](k);
        coll4.amounts = new uint256[](k);
        for (i = 0; i < k; ++i) {
            coll4.tokens[i] = coll3.tokens[i];
            coll4.amounts[i] = coll3.amounts[i];
        }
        return (coll4.tokens, coll4.amounts);
    }

    // --- 'Require' wrapper functions ---

    /**
     * @notice Require that the amount of collateral in the trove is not more than the max
     */
    function _requireValidTroveCollsLen(IYetiController controller, uint256 _n) internal view {
        require(_n <= controller.getMaxCollsInTrove());
    }

    /**
     * @notice Checks that amounts are nonzero, that the the length of colls and amounts are the same, that the coll is active,
     * and that there is no overlap collateral in the list. Calls controller version, which does these checks.
     */
    function _requireValidCollateral(
        address[] memory _colls,
        uint256[] memory _amounts,
        IYetiController controller,
        bool _deposit
    ) internal view {
        uint256 collsLen = _colls.length;
        _requireInputCorrect(collsLen == _amounts.length);
        for (uint256 i; i < collsLen; ++i) {
            _requireInputCorrect(_amounts[i] != 0);
        }
        controller.checkCollateralListSingle(_colls, _deposit);
    }

    /**
     * @notice Whether amountsIn is 0 or amountsOut is 0
     * @dev Condition of whether amountsIn is 0 amounts, or amountsOut is 0 amounts, is checked in previous call
     * to _requireValidCollateral
     */
    function _requireNonZeroAdjustment(
        uint256[] memory _amountsIn,
        uint256[] memory _amountsOut,
        uint256 _YUSDChange
    ) internal pure {
        require(_YUSDChange != 0 || _amountsIn.length != 0 || _amountsOut.length != 0, "1");
    }

    /** 
     * @notice require that lever up is enabled, stored in the Yeti Controller. 
     */
    function _requireLeverUpEnabled(IYetiController _controller) internal view {
        require(_controller.leverUpEnabled(), "13");
    }

    /** 
     * @notice Require trove is active or not, depending on what is passed in. 
     */
    function _requireTroveStatus(ITroveManager _troveManager, bool _active) internal view {
        require(_troveManager.isTroveActive(msg.sender) == _active, "1");
    }

    /**
     * @notice Function require length equal, used to save contract size on revert strings
     */
    function _requireInputCorrect(bool lengthCorrect) internal pure {
        require(lengthCorrect, "19");
    }

    /** 
     * @notice Require that ICR is above the MCR of 110% 
     */
    function _requireICRisAboveMCR(uint256 _newICR) internal pure {
        require(_newICR >= MCR, "20");
    }

    /** 
     * @notice Require that ICR is above CCR of 150%, used in Recovery mode 
     */
    function _requireICRisAboveCCR(uint256 _newICR) internal pure {
        require(_newICR >= CCR, "21");
    }

    /** 
     * @notice Require that new TCR is above CCR of 150%, to prevent drop into Recovery mode
     */
    function _requireNewTCRisAboveCCR(uint256 _newTCR) internal pure {
        require(_newTCR >= CCR, "23");
    }

    /** 
     * @notice Require that the debt is above 2000
     */
    function _requireAtLeastMinNetDebt(uint256 _netDebt) internal pure {
        require(_netDebt >= MIN_NET_DEBT, "8");
    }

    /** 
     * @notice Require that the YUSD repayment is valid at current debt. 
     */
    function _requireValidYUSDRepayment(uint256 _currentDebt, uint256 _debtRepayment) internal pure {
        require(_debtRepayment <= _currentDebt.sub(YUSD_GAS_COMPENSATION), "9");
    }

    /** 
     * @notice Require the borrower has enough YUSD to pay back the debt they are supposed to pay back. 
     */
    function _requireSufficientYUSDBalance(
        IYUSDToken _yusdToken,
        uint256 _debtRepayment
    ) internal view {
        require(_IERC20TokenBalanceOf(_yusdToken, msg.sender) >= _debtRepayment, "26");
    }

    /**
     * @notice requires that the max fee percentage is <= than 100%, and that the fee percentage is >= borrowing floor except in rec mode
     */
    function _requireValidMaxFeePercentage(uint256 _maxFeePercentage, bool _isRecoveryMode)
        internal
        pure
    {
        // Alwawys require max fee to be less than 100%, and if not in recovery mode then max fee must be greater than 0.5%
        if (
            _maxFeePercentage > DECIMAL_PRECISION ||
            (!_isRecoveryMode && _maxFeePercentage < BORROWING_FEE_FLOOR)
        ) {
            revert("27");
        }
    }

    // --- ICR and TCR getters ---

    /**
     * Calculates new TCR from the trove change based on coll increase and debt change.
     */
    function _getNewTCRFromTroveChange(
        uint256 _entireSystemColl,
        uint256 _entireSystemDebt,
        uint256 _collChange,
        uint256 _debtChange,
        bool _isCollIncrease,
        bool _isDebtIncrease
    ) internal pure returns (uint256) {
        _entireSystemColl = _isCollIncrease
            ? _entireSystemColl.add(_collChange)
            : _entireSystemColl.sub(_collChange);
        _entireSystemDebt = _isDebtIncrease
            ? _entireSystemDebt.add(_debtChange)
            : _entireSystemDebt.sub(_debtChange);

        return _computeCR(_entireSystemColl, _entireSystemDebt);
    }

    // --- External call functions included in internal functions to reduce contract size ---

    /** 
     * @notice calls apply pending rewards from trove manager 
     */
    function _applyPendingRewards(ITroveManager _troveManager) internal {
        _troveManager.applyPendingRewards(msg.sender);
    }

    /** 
     * @notice calls yusd token mint function
     */
    function _yusdTokenMint(
        IYUSDToken _yusdToken,
        address _to,
        uint256 _amount
    ) internal {
        _yusdToken.mint(_to, _amount);
    }

    /** 
     * @notice calls send collaterals unwrap function in active pool 
     */
    function _sendCollateralsUnwrap(
        IActivePool _activePool,
        address[] memory _collsOut,
        uint256[] memory _amountsOut
    ) internal {
        _activePool.sendCollateralsUnwrap(msg.sender, _collsOut, _amountsOut);
    }

    /** 
     * @notice calls send single collateral unwrap function in active pool 
     */
    function _sendSingleCollateralUnwrap(
        IActivePool _activePool,
        address _collOut,
        uint256 _amountOut
    ) internal {
        _activePool.sendSingleCollateralUnwrap(msg.sender, _collOut, _amountOut);
    }

    /** 
     * @notice calls increase trove debt from trove manager 
     */
    function _increaseTroveDebt(ITroveManager _troveManager, uint256 _amount)
        internal
        returns (uint256)
    {
        return _troveManager.increaseTroveDebt(msg.sender, _amount);
    }

    /** 
     * @notice calls update trove coll, and updates stake and total stakes for the borrower as well. 
     */
    function _updateTroveCollAndStakeAndTotalStakes(
        ITroveManager _troveManager,
        address[] memory _colls,
        uint256[] memory _amounts
    ) internal {
        _troveManager.updateTroveCollAndStakeAndTotalStakes(msg.sender, _colls, _amounts);
    }

    /** 
     * @notice calls receive collateral from the active pool 
     */
    function _activePoolReceiveCollateral(
        IActivePool _activePool,
        address[] memory _colls,
        uint256[] memory _amounts
    ) internal {
        _activePool.receiveCollateral(_colls, _amounts);
    }

    /** 
     * @notice gets the current trove state (colls, amounts, debt)
     */
    function _getCurrentTroveState(ITroveManager _troveManager)
        internal
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256
        )
    {
        return _troveManager.getCurrentTroveState(msg.sender);
    }

    /** 
     * @notice Gets the default router address from the yeti controller. 
     */
    function _getDefaultRouterAddress(IYetiController _controller, address _token)
        internal
        view
        returns (address)
    {
        return _controller.getDefaultRouterAddress(_token);
    }

    /** 
     * @notice Gets the value in USD of the collateral (no collateral weight)
     */
    function _getValueUSD(
        IYetiController _controller,
        address _token,
        uint256 _amount
    ) internal view returns (uint256) {
        return _controller.getValueUSD(_token, _amount);
    }

    /** 
     * @notice Gets the value in both VC and RVC from Controller at once to prevent additional loops. 
     */
    function _getValuesVCAndRVC(
        IYetiController _controller,
        address[] memory _colls,
        uint256[] memory _amounts
    ) internal view returns (uint256, uint256) {
        return _controller.getValuesVCAndRVC(_colls, _amounts);
    }

    /** 
     * @notice Gets the total variable deposit fee, and updates the last fee seen. See 
     *   YetiController and ThreePieceWiseFeeCurve for implementation details. 
     */
    function _getTotalVariableDepositFeeAndUpdate(
        IYetiController controller,
        address[] memory _colls,
        uint256[] memory _amounts,
        uint256[] memory _leverages,
        uint256 _entireSystemColl,
        uint256 _VCin,
        uint256 _VCout
    ) internal returns (uint256, uint256) {
        return
            controller.getTotalVariableDepositFeeAndUpdate(
                _colls,
                _amounts,
                _leverages,
                _entireSystemColl,
                _VCin,
                _VCout
            );
    }

    /** 
     * @notice Gets YUSD or some other token balance of an account. 
     */
    function _IERC20TokenBalanceOf(IERC20 _token, address _borrower)
        internal
        view
        returns (uint256)
    {
        return _token.balanceOf(_borrower);
    }

    /** 
     * @notice calls multi getter for indices of collaterals passed in. 
     */
    function _getIndices(address[] memory colls) internal view returns (uint256[] memory) {
        return controller.getIndices(colls);
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

import "../Dependencies/YetiCustomBase.sol";
import "./ICollateralReceiver.sol";


interface ICollSurplusPool is ICollateralReceiver {

    // --- Events ---

    event CollBalanceUpdated(address indexed _account);
    event CollateralSent(address _to);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerLiquidationsAddress,
        address _troveManagerRedemptionsAddress,
        address _activePoolAddress,
        address _controllerAddress,
        address _yusdTokenAddress
    ) external;

    function getCollVC() external view returns (uint);

    function getTotalRedemptionBonus() external view returns (uint256);

    function getAmountClaimable(address _account, address _collateral) external view returns (uint);

    function getAmountsClaimable(address _account) 
        external 
        view 
        returns (address[] memory, uint256[] memory);

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

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.11;

import "./IPriceFeed.sol";


interface ILiquityBase {

    function getEntireSystemDebt() external view returns (uint entireSystemDebt);
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

    function claimRewardsSwap(uint256 _yusdMinAmountTotal, address[] calldata _swapAssets, bool _reinvest) external returns (uint256 amountFromSwap);

    /**
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the YUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint _debt, address[] memory _assets, uint[] memory _amountsAdded) external;

    /**
     * Calculates and returns the total gains a depositor has accumulated 
     */
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

interface ICollateralReceiver {
    function receiveCollateral(address[] memory _tokens, uint[] memory _amounts) external;
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