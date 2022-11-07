// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "../owner/Operator.sol";
import "../utils/ContractGuard.sol";
import "../interfaces/IBasisAsset.sol";
import "../interfaces/IOracle.sol";
import "../interfaces/IBoardroom.sol";
import "../interfaces/IMainTokenV2.sol";
import "../interfaces/IChamETF.sol";
import "../interfaces/IETFZap.sol";
import "../interfaces/IJoeRouter.sol";
import "../lib/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

contract EtfTreasury is ContractGuard, Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMath for uint256;

    struct BoardroomInfo {
        address boardroom;
        uint256 allocPoint;
    }

    BoardroomInfo[] public boardroomInfo;
    uint256 public totalAllocPoint;

    uint256 public constant PERIOD = 10 minutes;

    // governance
    address public operator;
    // flags
    bool public initialized;
    // epoch
    uint256 public startTime;
    uint256 public epoch;
    uint256 public previousEpoch;

    IJoeRouter public ROUTER;
    address public WAVAX;
    address public mainToken;
    IChamETF public etfToken;
    address public etfZap;
    address[] public intermediariesZap;
    address public oracle;

    // price
    uint256 public mainTokenPriceOne;
    uint256 public mainTokenPriceCeiling;
    uint256 public mainTokenPriceRebase;
    uint256 public consecutiveEpochHasPriceBelowOne;
    uint256 public consecutiveEpochToRebase;

    uint256 public totalEpochAbovePeg;
    uint256 public totalEpochUnderPeg;
    uint256[] public epochRebases;

    uint256[] public expansionTiersTwaps;
    uint256[] public expansionTiersRates;

    /*===== Rebase ====*/
    uint256 private constant DECIMALS = 18;
    uint256 private constant ONE = uint256(10**DECIMALS);
    uint256 private STABLE_DECIMALS;
    uint256 private MAX_SUPPLY;
    
    bool public rebaseStarted;
    bool public enabledRebase;

    uint256 private constant midpointRounding = 10**(DECIMALS - 7);

    uint256 public previousEpochMainPrice;

    uint256 public maxEtfAllocate;
    uint256 public minEtfAllocate;

    /*===== End Rebase ====*/
    uint256 public devFundPercent;

    address public devFund;
    address public daoFund;
    address public polWallet;
    address public sellingWallet;

    bool public enabledEmergencyWithdrawTax;

    // Additional reward
    address public aoeaToken;
    uint256 public additionalRewardTotalAllocPoint;
    uint256 public additionalRewardPoolStartTime;
    uint256 public additionalRewardPoolEndTime;

    uint256 public constant additionalRewardRunningTime = 270 days;
    uint256 public constant TOTAL_USER_REWARD_AOEA = 25000 ether;
    uint256 public aoeaTokenPerSecondForUser;
        
    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    event TreasuryFunded(uint256 timestamp, uint256 seigniorage);
    event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event PolFundFunded(uint256 timestamp, uint256 seigniorage);
    event LogRebase(
        uint256 indexed epoch,
        uint256 supplyDelta,
        uint256 newPrice,
        uint256 oldPrice,
        uint256 newTotalSupply,
        uint256 oldTotalSupply,
        uint256 timestampSec
    );
    event EnableRebase();
    event DisableRebase();
    event SetOperator(address indexed account, address newOperator);
    event AddBoardroom(address indexed account, address newBoardroom, uint256 allocPoint);
    event SetBoardroomAllocPoint(uint256 _pid, uint256 oldValue, uint256 newValue);
    event SetMainTokenPriceCeiling(uint256 newValue);
    event SetExpansionTiersTwaps(uint8 _index, uint256 _value);
    event SetExpansionTiersRates(uint8 _index, uint256 _value);
    event SetDevFundPercent(uint256 oldValue, uint256 newValue);
    event SetMainTokenPriceRebase(uint256 oldValue, uint256 newValue);
    event SetConsecutiveEpochToRebase(uint256 oldValue, uint256 newValue);
    event SetDevFund(address oldWallet, address newWallet);
    event SetDaoFund(address oldWallet, address newWallet);
    event SetSellingWallet(address oldWallet, address newWallet);
    event SetPolWallet(address oldWallet, address newWallet);
    event AdminWithdraw(address _tokenAddress, uint256 _amount);
    event EnableEmergencyWithdrawTax();
	event DisableEmergencyWithdrawTax();
    event SetEtfZap(address oldValue, address newValue);
    event SetMinEtfAllocate(uint256 oldValue, uint256 newValue);
    event SetMaxEtfAllocate(uint256 oldValue, uint256 newValue);
    event SetAdditionalRewardAllocPoint(uint256 _pid, uint256 oldValue, uint256 newValue);

    function __Upgradeable_Init() external initializer {
        initialized = false;
        epoch = 0;
        previousEpoch = 0;
        consecutiveEpochHasPriceBelowOne = 0;
        rebaseStarted = false;
        previousEpochMainPrice = 0;

        consecutiveEpochToRebase = 10;
        totalEpochAbovePeg = 0;
        totalEpochUnderPeg = 0;

        enabledRebase = true;

        devFundPercent = 1000; // 10%

        enabledEmergencyWithdrawTax = true;

        maxEtfAllocate = 5 ether;
        minEtfAllocate = 1 ether;
    }

    /* =================== Modifier =================== */

    modifier onlyOperator() {
        require(operator == msg.sender, "Treasury: caller is not the operator");
        _;
    }

    modifier checkCondition() {
        require(block.timestamp >= startTime, "Treasury: not started yet");

        _;
    }

    modifier checkEpoch() {
        require(block.timestamp >= nextEpochPoint(), "Treasury: not opened yet");

        _;

        epoch = epoch.add(1);
    }

    modifier checkOperator() {
        require(IBasisAsset(mainToken).operator() == address(this), "Treasury: need more permission");
        uint256 length = boardroomInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(Operator(boardroomInfo[pid].boardroom).operator() == address(this), "Treasury: need more permission");
        }

        _;
    }

    modifier notInitialized() {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() external view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    // oracle
    function getMainTokenPrice() public view returns (uint256) {
        try IOracle(oracle).consult(mainToken, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult MainToken price from the oracle");
        }
    }

    function getTwapPrice() public view returns (uint256) {
        try IOracle(oracle).twap(mainToken, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to twap MainToken price from the oracle");
        }
    }

    function initialize(
        address _mainToken,
        address _etfToken,
        address _router,
        address _sellingWallet,
        address _polWallet,
        address _daoFund,
        address _devFund,
        address _oracle,
        uint256 _stableDecimals,
        address _aoeaToken,
        uint256 _startTime
    ) external notInitialized {
        require(_mainToken != address(0), "!_mainToken");
        require(_etfToken != address(0), "!_etfToken");
        require(_router != address(0), "!_router");
        require(_sellingWallet != address(0), "!_sellingWallet");
        require(_polWallet != address(0), "!_polWallet");
        require(_daoFund != address(0), "!_daoFund");
        require(_devFund != address(0), "!_devFund");
        require(_oracle != address(0), "!_oracle");
        require(_aoeaToken != address(0), "!_aoeaToken");

        mainToken = _mainToken;
        etfToken = IChamETF(_etfToken);
        ROUTER = IJoeRouter(_router);
        WAVAX = ROUTER.WAVAX();
        oracle = _oracle;
        startTime = _startTime;

        sellingWallet = _sellingWallet;
        polWallet = _polWallet;
        devFund = _devFund;
        daoFund = _daoFund;

        aoeaToken = _aoeaToken;

        STABLE_DECIMALS = _stableDecimals;
        uint256 MAX_RATE = 10**STABLE_DECIMALS * 10**DECIMALS;
        MAX_SUPPLY = uint256(type(int256).max) / MAX_RATE;

        mainTokenPriceOne = 10**STABLE_DECIMALS; // This is to allow a PEG of 1 MainToken per STABLE
        mainTokenPriceRebase = 8*10**(STABLE_DECIMALS - 1); // 0.8 STABLE
        mainTokenPriceCeiling = mainTokenPriceOne.mul(101).div(100);

        expansionTiersTwaps = [0, mainTokenPriceOne.mul(150).div(100), mainTokenPriceOne.mul(200).div(100)];
        expansionTiersRates = [4000, 7000, 10000];

        IMainTokenV2(mainToken).grantRebaseExclusion(address(this)); // excluded rebase

        // additional reward
        additionalRewardPoolStartTime = _startTime;
        additionalRewardPoolEndTime = additionalRewardPoolStartTime + additionalRewardRunningTime;

        aoeaTokenPerSecondForUser = TOTAL_USER_REWARD_AOEA.div(additionalRewardRunningTime);
        initialized = true;
        operator = msg.sender;

        emit Initialized(msg.sender, block.number);
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
        emit SetOperator(msg.sender, _operator);
    }

    function checkBoardroomDuplicate(address _boardroom) internal view {
        uint256 length = boardroomInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            require(boardroomInfo[pid].boardroom != _boardroom, "Treasury: existing boardroom?");
        }
    }

    function addBoardroom(address _boardroom, uint256 _allocPoint, uint256 _additionalRewardAllocPoint) external onlyOperator {
        require(_boardroom != address(0), "!_boardroom");
        checkBoardroomDuplicate(_boardroom);
        massUpdatePools();
        boardroomInfo.push(BoardroomInfo({
            boardroom: _boardroom, 
            allocPoint: _allocPoint
        }));
        additionalRewardTotalAllocPoint = additionalRewardTotalAllocPoint.add(_additionalRewardAllocPoint);
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        IBoardroom boardRoom = IBoardroom(_boardroom);
        boardRoom.setAdditionalRewardAllocPoint(_additionalRewardAllocPoint);
        IMainTokenV2(mainToken).grantRebaseExclusion(_boardroom);
        IERC20Upgradeable(aoeaToken).safeApprove(_boardroom, TOTAL_USER_REWARD_AOEA);
        emit AddBoardroom(msg.sender, _boardroom, _allocPoint);
    }

    function setBoardroomAllocPoint(uint256 _pid, uint256 _allocPoint) public onlyOperator {
        BoardroomInfo storage boardroom = boardroomInfo[_pid];
        emit SetBoardroomAllocPoint(_pid, boardroom.allocPoint, _allocPoint);
        totalAllocPoint = totalAllocPoint.sub(boardroom.allocPoint).add(_allocPoint);
        boardroom.allocPoint = _allocPoint;
    }

    function massUpdatePools() public onlyOperator {
        uint256 length = boardroomInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            BoardroomInfo storage pool = boardroomInfo[pid];
            IBoardroom boardRoom = IBoardroom(pool.boardroom);
            boardRoom.massUpdatePools();
        }
    }

    function setAdditionalRewardAllocPoint(uint256 _pid, uint256 _allocPoint) public onlyOperator {
        massUpdatePools();
        BoardroomInfo storage pool = boardroomInfo[_pid];
        IBoardroom boardRoom = IBoardroom(pool.boardroom);
        additionalRewardTotalAllocPoint = additionalRewardTotalAllocPoint.sub(boardRoom.additionalRewardAllocPoint()).add(_allocPoint);
        emit SetAdditionalRewardAllocPoint(_pid, boardRoom.additionalRewardAllocPoint(), _allocPoint);
        boardRoom.setAdditionalRewardAllocPoint(_allocPoint);
    }

    function grantRebaseExclusion(address who) external onlyOperator {
        IMainTokenV2(mainToken).grantRebaseExclusion(who);
    }

    function revokeRebaseExclusion(address who) external onlyOperator {
        IMainTokenV2(mainToken).revokeRebaseExclusion(who);
    }

    function setMainTokenPriceCeiling(uint256 _mainTokenPriceCeiling) external onlyOperator {
        require(_mainTokenPriceCeiling >= mainTokenPriceOne.mul(70).div(100) && _mainTokenPriceCeiling <= mainTokenPriceOne.mul(110).div(100), "out of range (0.7, 1.1)"); // [0.7, 1.1]
        mainTokenPriceCeiling = _mainTokenPriceCeiling;
        emit SetMainTokenPriceCeiling(_mainTokenPriceCeiling);
    }

    function _syncPrice() internal {
        try IOracle(oracle).sync() {} catch {
            revert("Treasury: failed to sync price from the oracle");
        }
    }

    function _updatePrice() internal {
        try IOracle(oracle).update() {} catch {
            revert("Treasury: failed to update price from the oracle");
        }
    }

    function getMainTokenCirculatingSupply() public view returns (uint256) {
        return IMainTokenV2(mainToken).rebaseSupply();
    }

    function getEstimatedReward(uint256 _pid) external view returns (uint256) {
         uint256 wavaxBalanceOf = IERC20(WAVAX).balanceOf(address(this));
        if (wavaxBalanceOf > 0) {
            BoardroomInfo storage boardroomPool = boardroomInfo[_pid];
            if (boardroomPool.allocPoint > 0) {
                uint256 etfToMint = calculateEtfToMint(wavaxBalanceOf);
                uint256 etfBalanceOf = IERC20Upgradeable(address(etfToken)).balanceOf(address(this));
                uint256 totalEtf = etfToMint.add(etfBalanceOf);
                uint256 estimatedReward = calculateEtfToAllocate(totalEtf);
                if (estimatedReward > 0) {
                    estimatedReward = estimatedReward.mul(10000 - devFundPercent).div(10000);
                    return estimatedReward.mul(boardroomPool.allocPoint).div(totalAllocPoint);
                }
            }
        }

        return 0;
    }

    function calculateEtfToMint(uint256 _wavaxBalance) public view returns (uint256) {
        uint256 priceEtfByWavax = IETFZap(etfZap).getMaxAmountForJoinSingle(WAVAX, intermediariesZap, maxEtfAllocate);
        if (priceEtfByWavax > 0) {
            uint256 etfToMint = _wavaxBalance.mul(maxEtfAllocate).div(priceEtfByWavax);
            if (etfToMint > maxEtfAllocate) {
                return maxEtfAllocate;
            }
            return etfToMint;
        }

        return 0;
    }

    function calculateEtfToAllocate(uint256 _totalEtf) public view returns (uint256) {
        if (_totalEtf >= maxEtfAllocate) {
            return maxEtfAllocate;
        }

        if (_totalEtf >= minEtfAllocate) {
            return minEtfAllocate;
        }

        return 0;
    }

    function _sendEtfToBoardroom() internal {
        // mint ETF
        mintEtf();

        // send reward to boardroom
        uint256 etfBalanceOf = IERC20Upgradeable(address(etfToken)).balanceOf(address(this));
        if (etfBalanceOf > 0) {
            uint256 etfToAllocate = calculateEtfToAllocate(etfBalanceOf);
            if (etfToAllocate > 0) {
                uint256 devFundAmount = etfToAllocate.mul(devFundPercent).div(10000);
                if (devFundAmount > 0) {
                    IERC20Upgradeable(address(etfToken)).safeTransfer(devFund, devFundAmount);
                    etfToAllocate = etfToAllocate.sub(devFundAmount);
                }

                uint256 length = boardroomInfo.length;
                for (uint256 pid = 0; pid < length; ++pid) {
                    BoardroomInfo storage boardroomPool = boardroomInfo[pid];
                    if (boardroomPool.allocPoint > 0) {
                        uint256 boardroomReward = etfToAllocate.mul(boardroomPool.allocPoint).div(totalAllocPoint);
                        uint256 boardRoomAmount = IBoardroom(boardroomPool.boardroom).totalSupply();
                        if (boardroomReward > 0) {
                            if (boardRoomAmount > 0) {             
                                IERC20Upgradeable(address(etfToken)).safeApprove(boardroomPool.boardroom, 0);
                                IERC20Upgradeable(address(etfToken)).safeApprove(boardroomPool.boardroom, boardroomReward);
                                IBoardroom(boardroomPool.boardroom).allocateSeigniorage(boardroomReward);
                            }
                        }
                    }
                }
            }
        }
    }

    function calculateExpansionRate(uint256 _tokenPrice) public view returns (uint256) {
        uint256 expansionRate;
        uint256 expansionTiersTwapsLength = expansionTiersTwaps.length;
        uint256 expansionTiersRatesLength = expansionTiersRates.length;
        require(expansionTiersTwapsLength == expansionTiersRatesLength, "ExpansionTiers data invalid");

        for (uint256 tierId = expansionTiersTwapsLength - 1; tierId >= 0; --tierId) {
            if (_tokenPrice >= expansionTiersTwaps[tierId]) {
                expansionRate = expansionTiersRates[tierId];
                break;
            }
        }
        
        return expansionRate;
    }

    function allocateSeigniorage() external onlyOneBlock checkCondition checkEpoch checkOperator {
        _updatePrice();
        previousEpochMainPrice = getMainTokenPrice();
        if (epoch > 0) {
            if (previousEpochMainPrice > mainTokenPriceCeiling) {
                totalEpochAbovePeg = totalEpochAbovePeg.add(1);
                // Expansion
                uint256 mainTokenCirculatingSupply = IMainTokenV2(mainToken).rebaseSupply();
                uint256 percentage = previousEpochMainPrice;
                uint256 totalTokenExpansion = mainTokenCirculatingSupply.mul(percentage).div(100).div(10**STABLE_DECIMALS);

                if (totalTokenExpansion > 0) {
                    uint256 expansionRate = calculateExpansionRate(previousEpochMainPrice);
                    totalTokenExpansion = totalTokenExpansion.mul(expansionRate).div(10000);
                    if (totalTokenExpansion > 0) {
                        IMainTokenV2(mainToken).mint(sellingWallet, totalTokenExpansion);
                    }
                }

                _sendEtfToBoardroom();
            }

            if (previousEpochMainPrice < mainTokenPriceCeiling) {
                totalEpochUnderPeg = totalEpochUnderPeg.add(1);
            }

            // Rebase
            if (enabledRebase) {
                if (previousEpochMainPrice < mainTokenPriceOne) {
                    consecutiveEpochHasPriceBelowOne = consecutiveEpochHasPriceBelowOne.add(1);
                } else {
                    consecutiveEpochHasPriceBelowOne = 0;
                }
                
                if (rebaseStarted && previousEpochMainPrice < mainTokenPriceOne) {
                    _rebase(previousEpochMainPrice);
                    consecutiveEpochHasPriceBelowOne = 0;
                } else {
                    rebaseStarted = false;
                    if (previousEpochMainPrice <= mainTokenPriceRebase || consecutiveEpochHasPriceBelowOne >= consecutiveEpochToRebase) {
                        _rebase(previousEpochMainPrice);
                        consecutiveEpochHasPriceBelowOne = 0;
                    }
                }
            }
        }
    }

    function mintEtf() public {
        uint256 wavaxBalanceOf = IERC20(WAVAX).balanceOf(address(this));
        uint256 mintEtfAmount = calculateEtfToMint(wavaxBalanceOf);
        if (mintEtfAmount > 0) {
            IERC20Upgradeable(WAVAX).safeApprove(etfZap, 0);
            IERC20Upgradeable(WAVAX).safeApprove(etfZap, wavaxBalanceOf);
            IETFZap(etfZap).joinSingle(WAVAX, wavaxBalanceOf, intermediariesZap, mintEtfAmount);
        }
    }

    function computeSupplyDelta() public view returns (bool negative, uint256 supplyDelta, uint256 targetRate) {
        require(previousEpochMainPrice > 0, "previousEpochMainPrice invalid");
        targetRate = 10**DECIMALS;
        uint256 rate = previousEpochMainPrice.mul(10**DECIMALS).div(10**STABLE_DECIMALS);
        negative = rate < targetRate;
        uint256 rebasePercentage = ONE;
        if (negative) {
            rebasePercentage = targetRate.sub(rate).mul(ONE).div(targetRate);
        } else {
            rebasePercentage = rate.sub(targetRate).mul(ONE).div(targetRate);
        }

        supplyDelta = mathRound(getMainTokenCirculatingSupply().mul(rebasePercentage).div(ONE));
    }

    function mathRound(uint256 _value) internal pure returns (uint256) {
        uint256 valueFloor = _value.div(midpointRounding).mul(midpointRounding);
        uint256 delta = _value.sub(valueFloor);
        if (delta >= midpointRounding.div(2)) {
            return valueFloor.add(midpointRounding);
        } else {
            return valueFloor;
        }
    }

    function _rebase(uint256 _oldPrice) internal {
        require(epoch >= previousEpoch, "cannot rebase");
        (bool negative, uint256 supplyDelta, uint256 targetRate) = computeSupplyDelta();

        uint256 oldTotalSupply = IERC20(mainToken).totalSupply();
        uint256 newTotalSupply = oldTotalSupply;
        if (supplyDelta > 0) {
            rebaseStarted = true;
            if (oldTotalSupply.add(uint256(supplyDelta)) > MAX_SUPPLY) {
                supplyDelta = MAX_SUPPLY.sub(oldTotalSupply);
            }

            newTotalSupply = IMainTokenV2(mainToken).rebase(epoch, supplyDelta, negative);
            require(newTotalSupply <= MAX_SUPPLY, "newTotalSupply <= MAX_SUPPLY");
            previousEpoch = epoch;
            epochRebases.push(epoch);
            _syncPrice();
            _updatePrice();
        }

        emit LogRebase(epoch, supplyDelta, targetRate, _oldPrice, newTotalSupply, oldTotalSupply, block.timestamp);
    }

    function setExpansionTiersTwaps(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        uint256 expansionTiersTwapsLength = expansionTiersTwaps.length;
        require(_index < expansionTiersTwapsLength, "Index has to be lower than count of tiers");
        if (_index > 0) {
            require(_value > expansionTiersTwaps[_index - 1], "expansionTiersTwaps[i] has to be lower than expansionTiersTwaps[i + 1]");
        }
        if (_index < expansionTiersTwapsLength - 1) {
            require(_value < expansionTiersTwaps[_index + 1], "expansionTiersTwaps[i] has to be lower than expansionTiersTwaps[i + 1]");
        }
        expansionTiersTwaps[_index] = _value;
        emit SetExpansionTiersTwaps(_index, _value);
        return true;
    }

    function setExpansionTiersRates(uint8 _index, uint256 _value) external onlyOperator returns (bool) {
        require(_index < expansionTiersRates.length, "Index has to be lower than count of tiers");
        require(_value <= 10000, "_value: out of range"); // [_value < 100%]
        expansionTiersRates[_index] = _value;
        emit SetExpansionTiersRates(_index, _value);
        return true;
    }

    function enableRebase() external onlyOperator {
        enabledRebase = true;
		emit EnableRebase();
    }

    function disableRebase() external onlyOperator {
        enabledRebase = false;
		emit DisableRebase();
    }

    function setDevFundPercent(uint256 _value) external onlyOperator {
        require(_value <= 1000, 'Treasury: Max percent is 10%');
        emit SetDevFundPercent(devFundPercent, _value);
        devFundPercent = _value;
    }

    function setMainTokenPriceRebase(uint256 _value) external onlyOperator {
        uint256 maxMainTokenPriceRebase = 8*10**(STABLE_DECIMALS - 1); // 0.8 STABLE
        uint256 minMainTokenPriceRebase = 6*10**(STABLE_DECIMALS - 1); // 0.6 STABLE
        require(_value <= maxMainTokenPriceRebase && _value >= minMainTokenPriceRebase, 'Treasury: value out of range (0.6 - 0.8)');
        emit SetMainTokenPriceRebase(mainTokenPriceRebase, _value);
        mainTokenPriceRebase = _value;
    }

    function setConsecutiveEpochToRebase(uint256 _value) external onlyOperator {
        require(_value <= 15 && _value >= 10, 'Treasury: value out of range (10 - 15)');
        emit SetConsecutiveEpochToRebase(consecutiveEpochToRebase, _value);
        consecutiveEpochToRebase = _value;
    }

    function setSellingWallet(address _sellingWallet) external onlyOperator {
        require(_sellingWallet != address(0), "_sellingWallet address cannot be 0 address");
		emit SetSellingWallet(sellingWallet, _sellingWallet);
        sellingWallet = _sellingWallet;
    }

    function setPolWallet(address _polWallet) external onlyOperator {
        require(_polWallet != address(0), "_polWallet address cannot be 0 address");
		emit SetPolWallet(polWallet, _polWallet);
        polWallet = _polWallet;
    }

    function setDevFund(address _devFund) external onlyOperator {
        require(_devFund != address(0), "_devFund address cannot be 0 address");
		emit SetDevFund(devFund, _devFund);
        devFund = _devFund;
    }

    function setDaoFund(address _daoFund) external onlyOperator {
        require(_daoFund != address(0), "_daoFund address cannot be 0 address");
		emit SetDaoFund(daoFund, _daoFund);
        daoFund = _daoFund;
    }

    function getEpochRebases() external view returns (uint256[] memory) {
		return epochRebases;
	}

    function enableEmergencyWithdrawTax() external onlyOperator {
        enabledEmergencyWithdrawTax = true;
		emit EnableEmergencyWithdrawTax();
    }

    function disableEmergencyWithdrawTax() external onlyOperator {
        enabledEmergencyWithdrawTax = false;
		emit DisableEmergencyWithdrawTax();
    }

    function setIntermediariesZap(address[] memory _intermediariesZap) external onlyOperator {
        require(_intermediariesZap.length == etfToken.getCurrentTokens().length, "_intermediariesZap is invalid");
        intermediariesZap = _intermediariesZap;
    }

    function setEtfZap(address _etfZap) external onlyOperator {
        require(_etfZap != address(0), "_etfZap address cannot be 0 address");
		emit SetEtfZap(etfZap, _etfZap);
        etfZap = _etfZap;
    }

    function setMaxEtfAllocate(uint256 _maxEtfAllocate) external onlyOperator {
		emit SetMaxEtfAllocate(maxEtfAllocate, _maxEtfAllocate);
        maxEtfAllocate = _maxEtfAllocate;
    }

    function setMinEtfAllocate(uint256 _minEtfAllocate) external onlyOperator {
		emit SetMinEtfAllocate(minEtfAllocate, _minEtfAllocate);
        minEtfAllocate = _minEtfAllocate;
    }

    function adminWithdraw(address _tokenAddress, uint256 _amount) external onlyOperator {
        uint256 tokenBalance = IERC20(_tokenAddress).balanceOf(address(this));
        if (tokenBalance >= _amount) {
            IERC20Upgradeable(_tokenAddress).safeTransfer(polWallet, _amount);
        } else {
            IERC20Upgradeable(_tokenAddress).safeTransfer(polWallet, tokenBalance);
        }

        emit AdminWithdraw(_tokenAddress, _amount);
    }

    function isDevWallet(address _user) external view returns (bool) {
        return _user == devFund; 
    }

    function isDaoWallet(address _user) external view returns (bool) {
        return _user == daoFund; 
    }

    // todo: only for test
    function setWavax(address _tokenAddress) external onlyOperator {
        WAVAX = _tokenAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract ContractGuard {
    mapping(uint256 => mapping(address => bool)) private _status;

    function checkSameOriginReentranted() internal view returns (bool) {
        return _status[block.number][tx.origin];
    }

    function checkSameSenderReentranted() internal view returns (bool) {
        return _status[block.number][msg.sender];
    }

    modifier onlyOneBlock() {
        require(!checkSameOriginReentranted(), "ContractGuard: one block, one function");
        require(!checkSameSenderReentranted(), "ContractGuard: one block, one function");

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;

        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Operator is Context, Ownable {
    address private _operator;

    event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

    constructor() {
        _operator = _msgSender();
        emit OperatorTransferred(address(0), _operator);
    }

    function operator() public view returns (address) {
        return _operator;
    }

    modifier onlyOperator() {
        require(_operator == msg.sender, "operator: caller is not the operator");
        _;
    }

    function isOperator() public view returns (bool) {
        return _msgSender() == _operator;
    }

    function transferOperator(address newOperator_) public onlyOwner {
        _transferOperator(newOperator_);
    }

    function _transferOperator(address newOperator_) internal {
        require(newOperator_ != address(0), "operator: zero address given for new operator");
        emit OperatorTransferred(address(0), newOperator_);
        _operator = newOperator_;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity 0.8.13;

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IOracle {
    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);

    function sync() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IMainTokenV2 is IERC20 {
    function grantRebaseExclusion(address account) external;
    function revokeRebaseExclusion(address account) external;
    function getExcluded() external view returns (address[] memory);
    function rebase(uint256 epoch, uint256 supplyDelta, bool negative) external returns (uint256);
    function rebaseSupply() external view returns (uint256);
    function isDaoFund(address _address) external view returns (bool);
    function isPolWallet(address _address) external view returns (bool);
    function getDaoFund() external view returns (address);
    function getPolWallet() external view returns (address);
    function mint(address recipient, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IJoeRouter {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IETFZap {
    function getMaxAmountForJoinSingle(
        address tokenIn,
        address[] memory intermediaries,
        uint256 poolAmountOut
    ) external view returns (uint256 amountInMax);

    function joinSingle(
        address tokenIn,
        uint256 amountInMax,
        address[] memory intermediaries,
        uint256 poolAmountOut
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IChamETF {
    /**
     * @dev Token record data structure
     * @param bound is token bound to pool
     * @param ready has token been initialized
     * @param index index of address in tokens array
     * @param balance token balance
     */
    struct Record {
        bool bound;
        bool ready;
        uint8 index;
        uint256 balance;
    }

    function exitFee() external view returns (uint256);

    function INIT_POOL_SUPPLY() external view returns (uint256);

    function maxBoundTokens() external view returns (uint256);

    function MIN_BALANCE() external view returns (uint256);

    function minBoundTokens() external view returns (uint256);

    function addTokenAsset(address token, uint256 minimumBalance, uint256 balance) external;

    function exitFeeRecipient() external view returns (address);

    function exitPool(uint256 poolAmountIn, uint256[] memory minAmountsOut)
        external;

    function getUsedBalance(address token) external view returns (uint256);

    function getCurrentTokens()
        external
        view
        returns (address[] memory currentTokens);

    function initialize(
        address[] memory tokens,
        uint256[] memory balances,
        address tokenProvider
    ) external;

    function joinPool(uint256 poolAmountOut, uint256[] memory maxAmountsIn)
        external;

    function maxPoolTokens() external view returns (uint256);

    function removeTokenAsset(address token) external;

    function setExitFee(uint256 _exitFee) external;

    function setMinBoundTokens(uint256 _minBoundTokens) external;

    function setMaxBoundTokens(uint256 _maxBoundTokens) external;

    function setMaxPoolTokens(uint256 _maxPoolTokens) external;

    function setMinimumBalance(address token, uint256 minimumBalance) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IBoardroom {
    function balanceOf(address _member) external view returns (uint256);

    function earned(address _member) external view returns (uint256);

    function canWithdraw(address _member) external view returns (bool);

    function canClaimReward(address _member) external view returns (bool);

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getMainTokenPrice() external view returns (uint256);

    function setOperator(address _operator) external;

    function setRewardLockupEpoch(uint256 _value) external;

    function setWithdrawLockupEpoch(uint256 _value) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function claimReward() external;

    function allocateSeigniorage(uint256 _amount) external;
    
    function totalSupply() external view returns (uint256);

    function governanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external;

    function enableCalculateTax() external;

    function disableCalculateTax() external;

    function additionalRewardAllocPoint() external view returns (uint256);

    function setAdditionalRewardAllocPoint(uint256 _value) external;

    function massUpdatePools() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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
        return !AddressUpgradeable.isContract(address(this));
    }
}