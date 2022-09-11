// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./lib/Babylonian.sol";
import "./owner/Operator.sol";
import "./utils/ContractGuard.sol";
import "./utils/MyPausable.sol";
import "./interfaces/IBasisAsset.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/IBoardroom.sol";
import "./glad_core/roman_nft/IPreyPredator.sol";
import "./glad_core/roman_nft/PreyPredator.sol";
import "./glad_core/roman_nft/INFTPool.sol";
import "./glad_core/Glad.sol";

contract TreasuryNGv5 is IERC721Receiver, ContractGuard, MyPausable {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    /* ========= CONSTANT VARIABLES ======== */

    uint256 public constant PERIOD = 4 hours;

    /* ========== STATE VARIABLES ========== */

    // governance
    address public operator;

    // flags
    bool public initialized = false;

    // epoch
    uint256 public startTime;
    uint256 public epoch = 0;

    enum PEG_STATUS {
        UNDERPEG,
        PEGGED,
        OVERPEG
    }

    mapping(uint256 => PEG_STATUS) public epochPegStatus;

    // exclusions from total supply
    address[] public excludedFromTotalSupply;

    // core components
    address public glad;
    address public nft;
    address public gladshare;

    address public boardroom;
    address public gladOracle;

    address public underpegPool;
    address public nftPool;

    uint256 public totalDebt;

    // price
    uint256 public gladPriceOne;
    uint256 public gladPriceCeiling;

    uint256 public seigniorageSaved;

    uint256 public lastExpansion;

    uint256[] public supplyTiers;
    uint256[] public maxExpansionTiers;

    uint256 public maxSupplyExpansionPercent;
    uint256 public bondDepletionFloorPercent;
    uint256 public seigniorageExpansionFloorPercent;
    uint256 public maxDebtRatioPercent;

    /* =================== Added variables =================== */
    uint256 public previousEpochGladPrice;
    uint256 public maxDiscountRate; // when purchasing bond
    uint256 public maxPremiumRate; // when redeeming bond
    uint256 public discountPercent;
    uint256 public premiumThreshold;
    uint256 public premiumPercent;

    uint256 public nftRewardPercent;
    uint256 public treasuryFundPercent;

    address public daoFund;
    uint256 public daoFundSharedPercent;

    address public devFund;
    uint256 public devFundSharedPercent;

    address public teamFund;
    uint256 public teamFundPercent;

    uint256 public priceMultiplier;

    uint256[] public priceTiers;
    uint256[] public multiplierTiers;

    uint256 public underpegMintPrice = 21 * 1e18;

    mapping(uint256 => uint256) public underpegMintedPerEpoch;

    bool public underpegStealing = true;

    bool public underpegMintsEnabled;

    uint256 public underpegGeneration = 23;

    mapping(address => uint256) public mintedPerAddress;

    mapping(address => uint256) public lastMintTime;

    uint256 public BUY_DELAY = 60;

    uint256 public MAX_BATCH_SIZE = 1;

    uint256 public mintPriceMultiplier = 6944;
    /* =================== Events =================== */

    event Initialized(address indexed executor, uint256 at);
    event BurnedBonds(address indexed from, uint256 bondAmount);
    event BoughtBonds(
        address indexed from,
        uint256 gladAmount,
        uint256 bondAmount
    );
    event BoardroomFunded(uint256 timestamp, uint256 seigniorage);
    event DaoFundFunded(uint256 timestamp, uint256 seigniorage);
    event DevFundFunded(uint256 timestamp, uint256 seigniorage);
    event DebtAdded(uint256 debt);

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
        require(
            block.timestamp >= nextEpochPoint(),
            "Treasury: not opened yet"
        );

        _;

        epoch = epoch.add(1);
    }

    modifier checkOperator() {
        require(
            IBasisAsset(glad).operator() == address(this) &&
                IBasisAsset(nft).operator() == address(this) &&
                IBasisAsset(gladshare).operator() == address(this) &&
                Operator(boardroom).operator() == address(this),
            "Treasury: need more permission"
        );

        _;
    }

    modifier notInitialized() {
        require(!initialized, "Treasury: already initialized");

        _;
    }

    /* ========== VIEW FUNCTIONS ========== */

    function isInitialized() public view returns (bool) {
        return initialized;
    }

    // epoch
    function nextEpochPoint() public view returns (uint256) {
        return startTime.add(epoch.mul(PERIOD));
    }

    // oracle
    function getGladPrice() public view returns (uint256 gladPrice) {
        try IOracle(gladOracle).consult(glad, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult glad price from the oracle");
        }
    }

    function getGladUpdatedPrice() public view returns (uint256 _gladPrice) {
        try IOracle(gladOracle).twap(glad, 1e18) returns (uint144 price) {
            return uint256(price);
        } catch {
            revert("Treasury: failed to consult glad price from the oracle");
        }
    }

    // budget
    function getReserve() public view returns (uint256) {
        return seigniorageSaved;
    }

    function getRedeemableBonds()
        public
        view
        returns (uint256 _redeemableBonds)
    {
        uint256 _gladPrice = getGladPrice();
        if (_gladPrice > gladPriceCeiling) {
            uint256 _totalGlad = IERC20(glad).balanceOf(address(this));
            uint256 _rate = getBondPremiumRate();
            if (_rate > 0) {
                _redeemableBonds = _totalGlad.mul(1e18).div(_rate);
            }
        }
    }

    function getBondPremiumRate() public view returns (uint256 _rate) {
        uint256 _gladPrice = getGladPrice();
        if (_gladPrice > gladPriceCeiling) {
            uint256 _gladPricePremiumThreshold = gladPriceOne
                .mul(premiumThreshold)
                .div(100);
            if (_gladPrice >= _gladPricePremiumThreshold) {
                //Price > 1.10
                uint256 _premiumAmount = _gladPrice
                    .sub(gladPriceOne)
                    .mul(premiumPercent)
                    .div(10000);
                _rate = gladPriceOne.add(_premiumAmount);
                if (maxPremiumRate > 0 && _rate > maxPremiumRate) {
                    _rate = maxPremiumRate;
                }
            } else {
                // no premium bonus
                _rate = gladPriceOne;
            }
        }
    }

    /* ========== GOVERNANCE ========== */

    function initialize(
        address _glad,
        address _nft,
        address _gladshare,
        address _gladOracle,
        address _boardroom,
        address _underpegPool,
        address _nftPool,
        uint256 _startTime,
        address _oldTreasury
    ) public notInitialized {
        glad = _glad;
        nft = _nft;
        gladshare = _gladshare;
        gladOracle = _gladOracle;
        boardroom = _boardroom;
        startTime = _startTime;
        underpegPool = _underpegPool;
        IERC20(glad).safeApprove(underpegPool, type(uint256).max);
        nftPool = _nftPool;
        IERC20(glad).safeApprove(nftPool, type(uint256).max);

        gladPriceOne = 10**17; // This is to allow a PEG of 1 GLAD per 0.1 AVAX
        gladPriceCeiling = gladPriceOne.mul(101).div(100);

        priceMultiplier = 80; // 0.8

        // Dynamic max expansion percent
        supplyTiers = [
            0 ether,
            100000 ether,
            200000 ether,
            300000 ether,
            400000 ether,
            500000 ether
        ];
        maxExpansionTiers = [300, 350, 400, 450, 500, 600];

        maxSupplyExpansionPercent = 400; // Upto 4.0% supply for expansion

        bondDepletionFloorPercent = 10000; // 100% of Bond supply for depletion floor
        seigniorageExpansionFloorPercent = 3500; // At least 35% of expansion reserved for boardroom
        maxDebtRatioPercent = 4000; // Upto 40% supply of GBOND to purchase

        nftRewardPercent = 1000; // 10% of expansion reserved for NFTPool
        teamFundPercent = 300; // 3% of expansion reserved for team
        treasuryFundPercent = 700; // 7% of expansion reserved for Treasury

        premiumThreshold = 110;
        premiumPercent = 7000;

        // set seigniorageSaved to it's balance
        seigniorageSaved = IERC20(glad).balanceOf(address(this));

        initialized = true;
        operator = msg.sender;
        _migrate(_oldTreasury);
        _pause();
        emit Initialized(msg.sender, block.number);
    }

    function _migrate(address _oldTreasury) internal {
        TreasuryNGv5 t = TreasuryNGv5(_oldTreasury);
        epoch = t.epoch();
        for (uint256 i = 0; i < epoch; i++)
            epochPegStatus[i] = t.epochPegStatus(i);
        seigniorageSaved = t.seigniorageSaved();
        lastExpansion = t.lastExpansion(); // compensate for the underexpansion of the old treasury
        previousEpochGladPrice = t.previousEpochGladPrice();
    }

    function setOperator(address _operator) external onlyOperator {
        operator = _operator;
    }

    function setBoardroom(address _boardroom) external onlyOperator {
        boardroom = _boardroom;
    }

    function setBuyDelay(uint256 _buydelay) external onlyOperator {
        BUY_DELAY = _buydelay;
    }

    function setMaxBatchSize(uint256 _maxbatchsize) external onlyOperator {
        MAX_BATCH_SIZE = _maxbatchsize;
    }

    function setMintPriceMultiplier(uint256 _mintpricemultiplier) external onlyOperator {
        mintPriceMultiplier = _mintpricemultiplier;
    }

    function setUnderpegPool(address _underpegPool) external onlyOperator {
        if (underpegPool != address(0)) {
            IERC20(glad).safeApprove(underpegPool, 0);
        }
        underpegPool = _underpegPool;
        IERC20(glad).safeApprove(underpegPool, type(uint256).max);
    }

    function setExcludedFromTotalSupply(
        address[] memory _excludedFromTotalSupply
    ) external onlyOperator {
        excludedFromTotalSupply = _excludedFromTotalSupply;
    }

    function setGladOracle(address _gladOracle) external onlyOperator {
        gladOracle = _gladOracle;
    }

    function setGladPriceCeiling(uint256 _gladPriceCeiling)
        external
        onlyOperator
    {
        require(
            _gladPriceCeiling >= gladPriceOne &&
                _gladPriceCeiling <= gladPriceOne.mul(120).div(100),
            "out of range"
        ); // [$1.0, $1.2]
        gladPriceCeiling = _gladPriceCeiling;
    }

    function setPriceMultiplier(uint256 _priceMultiplier)
        external
        onlyOperator
    {
        require(
            _priceMultiplier > 0 && _priceMultiplier <= 100,
            "out of range"
        );
        priceMultiplier = _priceMultiplier;
    }

    function setSupplyExpansionMultiplier(
        uint256[] memory _priceTiers,
        uint256[] memory _multiplierTiers
    ) public onlyOperator {
        require(
            _priceTiers.length == _multiplierTiers.length,
            "tier length mismatch"
        );
        for (uint256 i; i < _priceTiers.length; i++) {
            require(_multiplierTiers[i] < 200, "multiplier out of range");
            if (i > 0) {
                require(
                    _priceTiers[i - 1] < _priceTiers[i],
                    "invalid order"
                );
            }
        }
        priceTiers = _priceTiers;
        multiplierTiers = _multiplierTiers;
    }

    function setMaxSupplyExpansionPercents(uint256 _maxSupplyExpansionPercent)
        external
        onlyOperator
    {
        require(
            _maxSupplyExpansionPercent >= 10 &&
                _maxSupplyExpansionPercent <= 1000,
            "_maxSupplyExpansionPercent: out of range"
        ); // [0.1%, 10%]
        maxSupplyExpansionPercent = _maxSupplyExpansionPercent;
    }

    function setBoardroomPercents(
        uint256 _nftRewardPercent,
        uint256 _teamFundPercent,
        uint256 _treasuryFundPercent
    ) external onlyOperator {
        require(
            _nftRewardPercent + _teamFundPercent + _treasuryFundPercent <=
                10000,
            "setBoardroomPercents: out of range"
        );
        nftRewardPercent = _nftRewardPercent;
        teamFundPercent = _teamFundPercent;
        treasuryFundPercent = _treasuryFundPercent;
    }

    function setSupplyTiersEntry(uint8 _index, uint256 _value)
        external
        onlyOperator
        returns (bool)
    {
        require(_index >= 0, "Index has to be higher than 0");
        require(
            _index < supplyTiers.length,
            "Index has to be lower than count of tiers"
        );
        if (_index > 0) {
            require(_value > supplyTiers[_index - 1]);
        }
        if (_index < supplyTiers.length - 1) {
            require(_value < supplyTiers[_index + 1]);
        }
        supplyTiers[_index] = _value;
        return true;
    }

    function setMaxExpansionTiersEntry(uint8 _index, uint256 _value)
        external
        onlyOperator
        returns (bool)
    {
        require(_index >= 0, "Index has to be higher than 0");
        require(
            _index < maxExpansionTiers.length,
            "Index has to be lower than count of tiers"
        );
        require(_value >= 10 && _value <= 1000, "_value: out of range"); // [0.1%, 10%]
        maxExpansionTiers[_index] = _value;
        return true;
    }

    function setBondDepletionFloorPercent(uint256 _bondDepletionFloorPercent)
        external
        onlyOperator
    {
        require(
            _bondDepletionFloorPercent >= 500 &&
                _bondDepletionFloorPercent <= 10000,
            "out of range"
        ); // [5%, 100%]
        bondDepletionFloorPercent = _bondDepletionFloorPercent;
    }

    function setMaxDebtRatioPercent(uint256 _maxDebtRatioPercent)
        external
        onlyOperator
    {
        require(
            _maxDebtRatioPercent >= 1000 && _maxDebtRatioPercent <= 10000,
            "out of range"
        ); // [10%, 100%]
        maxDebtRatioPercent = _maxDebtRatioPercent;
    }

    function setExtraFunds(
        address _daoFund,
        uint256 _daoFundSharedPercent,
        address _devFund,
        uint256 _devFundSharedPercent
    ) external onlyOperator {
        require(_daoFund != address(0), "zero");
        require(_daoFundSharedPercent <= 2500, "out of range"); // <= 25%
        require(_devFund != address(0), "zero");
        require(_devFundSharedPercent <= 500, "out of range"); // <= 5%
        daoFund = _daoFund;
        daoFundSharedPercent = _daoFundSharedPercent;
        devFund = _devFund;
        devFundSharedPercent = _devFundSharedPercent;
    }

    function setTeamFund(address _teamFund) external onlyOperator {
        require(_teamFund != address(0), "zero");
        teamFund = _teamFund;
    }

    function setMaxDiscountRate(uint256 _maxDiscountRate)
        external
        onlyOperator
    {
        maxDiscountRate = _maxDiscountRate;
    }

    function setMaxPremiumRate(uint256 _maxPremiumRate) external onlyOperator {
        maxPremiumRate = _maxPremiumRate;
    }

    function setUnderpegMintPrice(uint256 _price) external onlyOperator {
        underpegMintPrice = _price;
    }

    function setUnderpegStealing(bool _stealing) external onlyOperator {
        underpegStealing = _stealing;
    }

    function setUnderpegMintsEnabled(bool _e) external onlyOperator {
        underpegMintsEnabled = _e;
    }

    function setUnderpegGeneration(uint256 _gen) external onlyOperator {
        underpegGeneration = _gen;
    }

    function setDiscountPercent(uint256 _discountPercent)
        external
        onlyOperator
    {
        require(_discountPercent <= 20000, "_discountPercent is over 200%");
        discountPercent = _discountPercent;
    }

    function setPremiumThreshold(uint256 _premiumThreshold)
        external
        onlyOperator
    {
        require(
            _premiumThreshold >= gladPriceCeiling,
            "_premiumThreshold exceeds gladPriceCeiling"
        );
        require(
            _premiumThreshold <= 150,
            "_premiumThreshold is higher than 1.5"
        );
        premiumThreshold = _premiumThreshold;
    }

    function setPremiumPercent(uint256 _premiumPercent) external onlyOperator {
        require(_premiumPercent <= 20000, "_premiumPercent is over 200%");
        premiumPercent = _premiumPercent;
    }

    /* ========== MUTABLE FUNCTIONS ========== */

    function _updateGladPrice() internal {
        try IOracle(gladOracle).update() {} catch {}
    }

    function getGladCirculatingSupply() public view returns (uint256) {
        IERC20 gladErc20 = IERC20(glad);
        uint256 totalSupply = gladErc20.totalSupply();
        uint256 balanceExcluded = 0;
        for (
            uint8 entryId = 0;
            entryId < excludedFromTotalSupply.length;
            ++entryId
        ) {
            balanceExcluded = balanceExcluded.add(
                gladErc20.balanceOf(excludedFromTotalSupply[entryId])
            );
        }
        return totalSupply.sub(balanceExcluded);
    }

    function mintUnderpeg(uint256 _amount, uint256 targetPrice)
        external
        onlyOneBlock
        checkCondition
        checkOperator
        whenNotPaused
    {
        require(msg.sender == tx.origin, "Only EOA");
        require(underpegMintsEnabled, "Underpeg mints not enabled yet");
        require(_amount > 0, "Treasury: cannot mint zero nfts");
        require(_amount <= MAX_BATCH_SIZE, "Treasury: cannot mint this much nfts in a batch");
        uint256 maxMint =  PreyPredator(nft).mintedPerAddress(msg.sender);
        if (maxMint > 0) {
            if (maxMint > 1) {
                maxMint *= maxMint;
                maxMint /= 2;
            }
        }
        require(mintedPerAddress[msg.sender] + _amount <= maxMint, "Treasury: maximum amount of Patricians mintable per gen0 NFT reached for this address");
        require(lastMintTime[msg.sender] > lastMintTime[msg.sender] +  BUY_DELAY, "Treasury: Wait until cooldown time between your Patrician mints");

        lastMintTime[msg.sender] = block.timestamp;
        mintedPerAddress[msg.sender] += _amount;

        uint256 gladPrice = getGladPrice();
        require(gladPrice == targetPrice, "Treasury: GLAD price moved");
        require(
            gladPrice < gladPriceOne, // price < 0.1 AVAX
            "Treasury: gladPrice not eligible for underpeg minting"
        );

        uint64 currentGeneration = IPreyPredator(nft).currentGeneration();

        uint256 _mintPrice = underpegMintPrice;
        uint256 maxEpochUnderpegMint = (lastExpansion * priceMultiplier) / 100 / underpegMintPrice;
        if (maxEpochUnderpegMint == 0) maxEpochUnderpegMint = 1;
        require(underpegMintedPerEpoch[epoch] + _amount <= maxEpochUnderpegMint, "Mint less, there are no this many underpeg tokens left for this epoch");
        underpegMintedPerEpoch[epoch] += _amount;
        uint256 _gladAmount = _mintPrice * _amount;

        Glad(glad).burnFrom(msg.sender, _gladAmount);


        IPreyPredator(nft).mintGeneric(msg.sender, _amount, _mintPrice * mintPriceMultiplier / 10000, underpegGeneration, underpegStealing);
        if (underpegStealing) {
            // we need to fwd nfts received by this contract to the owner to compensate for bug in PRerPredator
            uint256 minted = PreyPredator(nft).minted();
            for (uint256 i = 0; i < _amount; i++) {
                if (PreyPredator(nft).ownerOf(minted - i) == address(this)) {
                    // not stolen
                    PreyPredator(nft).transferFrom(address(this), msg.sender, minted - i);
                }
            }
        }

        _updateGladPrice();

        emit BoughtBonds(msg.sender, _gladAmount, _amount);
    }

    function getMaxEpochUnderpegMintCount() public view returns (uint256 cnt) {
        cnt = (lastExpansion * priceMultiplier) / 100 / underpegMintPrice;
        cnt = (cnt == 0 ? 1 : cnt);
    }

    function _sendToBoardroom(uint256 _amount) internal {
        IBasisAsset(glad).mint(address(this), _amount);

        uint256 _daoFundSharedAmount = 0;
        if (daoFundSharedPercent > 0) {
            _daoFundSharedAmount = _amount.mul(daoFundSharedPercent).div(10000);
            IERC20(glad).transfer(daoFund, _daoFundSharedAmount);
            emit DaoFundFunded(block.timestamp, _daoFundSharedAmount);
        }

        uint256 _devFundSharedAmount = 0;
        if (devFundSharedPercent > 0) {
            _devFundSharedAmount = _amount.mul(devFundSharedPercent).div(10000);
            IERC20(glad).transfer(devFund, _devFundSharedAmount);
            emit DevFundFunded(block.timestamp, _devFundSharedAmount);
        }

        _amount = _amount.sub(_daoFundSharedAmount).sub(_devFundSharedAmount);

        IERC20(glad).safeApprove(boardroom, 0);
        IERC20(glad).safeApprove(boardroom, _amount);
        IBoardroom(boardroom).allocateSeigniorage(_amount);
        emit BoardroomFunded(block.timestamp, _amount);
    }

    function _calculateMaxSupplyExpansionPercent(uint256 _gladSupply)
        internal
        returns (uint256)
    {
        for (uint256 tierId = supplyTiers.length - 1; tierId >= 0; --tierId) {
            if (_gladSupply >= supplyTiers[tierId]) {
                maxSupplyExpansionPercent = maxExpansionTiers[tierId];
                break;
            }
        }
        return maxSupplyExpansionPercent;
    }

    function _calculateSupplyExpansionMultiplier(uint256 _price)
        internal
        view
        returns (uint256)
    {
        uint256 length = multiplierTiers.length;
        if (length == 0) return 100;
        if (_price < priceTiers[0]) {
            return multiplierTiers[0];
        }
        if (_price >= priceTiers[length - 1]) {
            return multiplierTiers[length - 1];
        }
        for (uint256 i = 1; i < length; i++) {
            if (_price < priceTiers[i]) {
                return
                    multiplierTiers[i] +
                    ((multiplierTiers[i - 1] - multiplierTiers[i]) *
                        (priceTiers[i] - _price)) /
                    (priceTiers[i] - priceTiers[i - 1]);
            }
        }
    }

    function _getPegStatus(uint256 gladPrice)
        internal
        view
        returns (PEG_STATUS)
    {
        if (gladPrice < gladPriceOne) return PEG_STATUS.UNDERPEG;
        if (gladPrice > gladPriceCeiling) return PEG_STATUS.OVERPEG;
        return PEG_STATUS.PEGGED;
    }

    function addDebt(uint256 debt) external {
        require(msg.sender == underpegPool, "only unerpeg pool can call this");
        totalDebt += debt;
        Glad(glad).mint(address(this), debt);

        emit DebtAdded(debt);
    }

    function allocateSeigniorage()
        external
        onlyOneBlock
        checkCondition
        checkEpoch
        checkOperator
        whenNotPaused
    {
        _updateGladPrice();
        previousEpochGladPrice = getGladPrice();
        uint256 gladSupply = getGladCirculatingSupply().sub(seigniorageSaved);
        if (previousEpochGladPrice > gladPriceCeiling) {
            // Expansion ($GLAD Price > 1 $MIM): there is some seigniorage to be allocated
            uint256 _percentage = previousEpochGladPrice.sub(gladPriceOne).mul(10);
            uint256 _savedForBoardroom;
            uint256 _savedForNFTPool;
            uint256 _savedForTeam;
            uint256 _savedForTreasury;
            uint256 _mse = _calculateMaxSupplyExpansionPercent(gladSupply).mul(
                1e14
            );
            uint256 expantionMultiplier = _calculateSupplyExpansionMultiplier(
                previousEpochGladPrice
            );
            _mse = _mse.mul(expantionMultiplier).div(100);
            if (_percentage > _mse) {
                _percentage = _mse;
            }
            // have not saved enough to pay debt, mint more
            uint256 _seigniorage = gladSupply.mul(_percentage).div(1e18);
            IBasisAsset(glad).mint(address(this), _seigniorage);

            _savedForBoardroom = _seigniorage
                .mul(seigniorageExpansionFloorPercent)
                .div(10000);
            if (totalDebt > 0) {
                if (totalDebt > _seigniorage - _savedForBoardroom) {
                    totalDebt -= _seigniorage - _savedForBoardroom;
                } else {
                    _savedForBoardroom = _seigniorage - totalDebt;

                    totalDebt = 0;
                }
            }

            _savedForNFTPool = _savedForBoardroom.mul(nftRewardPercent).div(
                10000
            );
            if (_savedForNFTPool > 0) {
                INFTPool(nftPool).addGladReward(_savedForNFTPool);
            }
            _savedForTeam = _savedForBoardroom.mul(teamFundPercent).div(10000);
            if (_savedForTeam > 0) {
                IERC20(glad).safeTransfer(teamFund, _savedForTeam);
            }
            _savedForTreasury = _savedForBoardroom.mul(treasuryFundPercent).div(
                10000
            );
            if (_savedForBoardroom > 0) {
                _sendToBoardroom(_savedForBoardroom - _savedForTreasury - _savedForTeam - _savedForNFTPool);
            }

            lastExpansion = _seigniorage;
        }

        epochPegStatus[epoch] = _getPegStatus(previousEpochGladPrice);
        bool underpegMint;
        if (epochPegStatus[epoch] == PEG_STATUS.OVERPEG && epoch >= 2) {
            underpegMint = true;
            for (uint256 i = 1; i < 3; i++) {
                if (epochPegStatus[epoch - i] != PEG_STATUS.OVERPEG) {
                    underpegMint = false;
                    break;
                }
            }
        } else if (epochPegStatus[epoch] == PEG_STATUS.UNDERPEG && epoch >= 5) {
            underpegMint = true;
            for (uint256 i = 1; i < 6; i++) {
                if (epochPegStatus[epoch - i] != PEG_STATUS.UNDERPEG) {
                    underpegMint = false;
                    break;
                }
            }
        }
        // uint8 is too small to continue this
        //if (underpegMint) {
        //    IPreyPredator(nft).increaseGeneration();
        //}
    }

    function governanceRecoverUnsupported(
        IERC20 _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        // do not allow to drain core tokens
        require(address(_token) != address(glad), "glad");
        require(address(_token) != address(gladshare), "share");
        _token.safeTransfer(_to, _amount);
    }

    function boardroomSetOperator(address _operator) external onlyOperator {
        IBoardroom(boardroom).setOperator(_operator);
    }

    function boardroomSetLockUp(
        uint256 _withdrawLockupEpochs,
        uint256 _rewardLockupEpochs
    ) external onlyOperator {
        IBoardroom(boardroom).setLockUp(
            _withdrawLockupEpochs,
            _rewardLockupEpochs
        );
    }

    function boardroomAllocateSeigniorage(uint256 amount)
        external
        onlyOperator
    {
        IBoardroom(boardroom).allocateSeigniorage(amount);
    }

    function setNftPool(address _nftPool) external onlyOperator {
        if (nftPool != address(0)) {
            IERC20(glad).safeApprove(nftPool, 0);
        }
        nftPool = _nftPool;
        IERC20(glad).safeApprove(nftPool, type(uint256).max);
    }

    function burnGlad(uint256 amount) external onlyOperator {
        IBasisAsset(glad).burn(amount);
    }

    function burnGladShare(uint256 amount) external onlyOperator {
        IBasisAsset(gladshare).burn(amount);
    }

    function transferERC20(address tokenAddress, address to, uint256 amount) external onlyOperator {
        IERC20(tokenAddress).transfer(to, amount);
    }

    function approveERC20(address tokenAddress, address spender, uint256 amount) external onlyOperator {
        IERC20(tokenAddress).approve(spender, amount);
    }

    function sendValue(address target, uint256 value) external onlyOperator {
        (bool success, ) = payable(target).call{value: value}("");
        require(success == true);
    }

    function boardroomGovernanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external onlyOperator {
        IBoardroom(boardroom).governanceRecoverUnsupported(
            _token,
            _amount,
            _to
        );
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
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

pragma solidity ^0.8.0;

library Babylonian {
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
        // else z = 0
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

pragma solidity 0.8.9;

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

        _;

        _status[block.number][tx.origin] = true;
        _status[block.number][msg.sender] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyPausable is Pausable, Ownable {
    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IBasisAsset {
    function mint(address recipient, uint256 amount) external returns (bool);

    function burn(uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function isOperator() external returns (bool);

    function operator() external view returns (address);

    function transferOperator(address newOperator_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOracle {
    function update() external;

    function consult(address _token, uint256 _amountIn) external view returns (uint144 amountOut);

    function twap(address _token, uint256 _amountIn) external view returns (uint144 _amountOut);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IBoardroom {
    function balanceOf(address _member) external view returns (uint256);

    function earned(address _member) external view returns (uint256);

    function canWithdraw(address _member) external view returns (bool);

    function canClaimReward(address _member) external view returns (bool);

    function epoch() external view returns (uint256);

    function nextEpochPoint() external view returns (uint256);

    function getGrapePrice() external view returns (uint256);

    function setOperator(address _operator) external;

    function setLockUp(uint256 _withdrawLockupEpochs, uint256 _rewardLockupEpochs) external;

    function stake(uint256 _amount) external;

    function withdraw(uint256 _amount) external;

    function exit() external;

    function claimReward() external;

    function allocateSeigniorage(uint256 _amount) external;

    function governanceRecoverUnsupported(
        address _token,
        uint256 _amount,
        address _to
    ) external;
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IPreyPredator {
    event TokenTraitsUpdated(uint256 tokenId, PreyPredator traits);
    // struct to store each token's traits
    struct PreyPredator {
        bool isPrey;
        uint8 environment;
        uint8 body;
        uint8 armor;
        uint8 helmet;
        uint8 shoes;
        uint8 shield;
        uint8 weapon;
        uint8 item;
        uint8 alphaIndex;
        uint64 generation;
        uint8 agility;
        uint8 charisma;
        uint8 damage;
        uint8 defense;
        uint8 dexterity;
        uint8 health;
        uint8 intelligence;
        uint8 luck;
        uint8 strength;
    }

    function traitsRevealed(uint256 tokenId) external view returns (bool);

    function getTokenTraits(uint256 tokenId)
        external
        view
        returns (PreyPredator memory);

    function mintUnderpeg(
        address to,
        uint256 amount,
        uint256 price
    ) external;

    function mintGeneric (
        address to,
        uint256 amount,
        uint256 price,
        uint256 generation,
        bool stealing
    ) external;

    function increaseGeneration() external;

    function currentGeneration() external view returns (uint8);

    function getGenTokens(uint8 generation) external view returns (uint256);

    function mintedPrice(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity =0.8.9;

import "./IPool.sol";
import "./IEntropy.sol";
import "./ITraits.sol";
import "./IPreyPredator.sol";
import "../../IWhitelist.sol";
import "../../Controllable.sol";
import "../../owner/Operator.sol";
import "../../owner/Blacklistable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";

contract PreyPredator is
    IPreyPredator,
    ERC721Enumerable,
    ERC721Royalty,
    ERC721Burnable,
    Operator,
    Controllable,
    Blacklistable,
    Pausable
{
    using SafeERC20 for IERC20;
    //INFO: Configuration is defined here

    uint256 public constant MAX_PER_MINT = 30;
    uint256 public MAX_MINT_PER_ADDRESS;

    uint8 public PREDATOR_MINT_CHANCE = 10;
    uint8 public MINT_STEAL_CHANCE = 10;

    // gen 0 mint price floor
    uint256 public MINT_PRICE_START;
    uint256 public MINT_PRICE_END;
    // max number of GEN0 tokens that can be minted
    uint256 public GEN0_TOKENS;
    // after how many blocks the traits are revealed
    uint256 public immutable REVEAL_DELAY = 5;
    uint96 public ROYALTY_FEE = 9;
    // number of tokens have been minted so far
    uint64 public minted;
    mapping(uint256 => uint256) public mintedPerGen;
    mapping(address => uint256) public mintedPerAddress;
    // current generation
    uint8 public currentGeneration;
    // index of the last revealed NFT
    uint256 private lastRevealed;
    // start timestamp
    uint256 public mintStartTime;
    // whitelist free nft claim tracker
    mapping(address => bool) public whitelistClaimed;
    // mapping from tokenId to a struct containing the token's traits
    mapping(uint256 => PreyPredator) private tokenTraits;
    // mapping from hashed(tokenTrait) to the tokenId it's associated with
    // used to ensure there are no duplicates
    mapping(uint256 => uint256) private existingCombinations;

    mapping(uint256 => uint256) public mintBlock;

    mapping(uint256 => uint256) public mintedPrice;

    // list of probabilities for each trait type
    // 0 - 9 are associated with Prey, 10 - 18 are associated with Predators
    uint16[][19] public rarities;
    // list of aliases for Walker's Alias algorithm
    // 0 - 9 are associated with Prey, 10 - 18 are associated with Predators
    uint8[][19] public aliases;

    // reference to the Pool for choosing random Predator thieves
    // initial nft pool
    IPool public pool;
    // nft for glad/dgladshare pool
    IPool public pool2;
    // reference to Traits
    ITraits public traits;
    // reference to entropy generation
    IEntropy public entropy;

    // reference to whiteist
    IWhitelist public whitelist;

    address public daoAddress;
    address public teamAddress;

    /**
     * instantiates contract and rarity tables
     */
    constructor(
        address _traits,
        address _wl,
        address _daoAddress,
        address _teamAddress,
        uint256 _mintStartTime,
        uint256 _startprice,
        uint256 _endprice,
        uint256 _gen0Tokens,
        uint256 _maxMintPerAddress
    ) ERC721("Gladiator Finance", "GLADNFT") {
        //TODO:
        traits = ITraits(_traits);
        whitelist = IWhitelist(_wl);
        mintStartTime = _mintStartTime;
        _setDefaultRoyalty(owner(), ROYALTY_FEE);
        MAX_MINT_PER_ADDRESS = _maxMintPerAddress;

        MINT_PRICE_END = _endprice;
        MINT_PRICE_START = _startprice;

        GEN0_TOKENS = _gen0Tokens;

        daoAddress = _daoAddress;
        teamAddress = _teamAddress;
        // I know this looks weird but it saves users gas by making lookup O(1)
        // A.J. Walker's Alias Algorithm
        // prey
        // environment
        rarities[0] = [246, 228, 256, 241, 253, 54, 36];
        aliases[0] = [2, 3, 2, 4, 2, 0, 1];
        // body
        rarities[1] = [102, 179, 256, 51, 26, 51, 26, 51, 26, 26];
        aliases[1] = [1, 2, 2, 0, 1, 2, 0, 1, 2, 0];
        // armor
        rarities[2] = [256, 205, 20, 184, 92, 15];
        aliases[2] = [0, 0, 0, 0, 1, 2];
        // helmet
        rarities[3] = [256, 210, 84, 241, 251, 108, 18];
        aliases[3] = [0, 3, 0, 0, 0, 1, 2];
        // shoes
        rarities[4] = [256, 210, 84, 241, 251, 108, 18];
        aliases[4] = [0, 3, 0, 0, 0, 1, 2];
        // shield
        rarities[5] = [179, 256, 200, 138, 251, 108, 18];
        aliases[5] = [1, 1, 1, 2, 2, 3, 1];
        // weapon
        rarities[6] = [256, 205, 21, 184, 92, 15];
        aliases[6] = [0, 0, 0, 0, 1, 2];
        // item
        rarities[7] = [256, 139, 139, 138, 138, 138, 159, 138, 46];
        aliases[7] = [0, 0, 6, 0, 0, 0, 0, 0, 0];
        // alphaIndex
        rarities[8] = [255];
        aliases[8] = [0];

        // predators
        // environment
        rarities[10] = [256, 154, 184, 154, 154, 246, 246, 0, 0, 0, 0, 31];
        aliases[10] = [0, 0, 0, 2, 0, 2, 0, 2, 0, 0, 0, 0];
        // body
        rarities[11] = [256, 220, 210, 143, 143, 200, 200, 133, 133, 133, 67, 67, 66];
        aliases[11] = [0, 0, 0, 0, 0, 0, 1, 2, 3, 4, 0, 1, 0];
        // armor
        rarities[12] = [255];
        aliases[12] = [0];
        // helmet
        rarities[13] = [255];
        aliases[13] = [0];
        // shoes
        rarities[14] = [255];
        aliases[14] = [0];
        // shield
        rarities[15] = [255];
        aliases[15] = [0];
        // weapon
        rarities[16] = [256, 154, 256, 102, 26];
        aliases[16] = [0, 0, 2, 0, 1];
        // item
        rarities[17] = [256, 141, 166, 77, 166, 166, 154, 154, 154, 154, 153, 115, 77, 39, 38];
        aliases[17] = [0, 0, 0, 0, 0, 0, 1, 2, 4, 5, 0, 1, 0, 0, 0];
        // alphaIndex
        rarities[18] = [256, 154, 256, 102, 26];
        aliases[18] = [0, 0, 2, 0, 1];

        // sanity check
        for (uint256 i = 0; i < 19; i++) {
            require(
                rarities[i].length == aliases[i].length,
                "Rarities' and aliases' length do not match everywhere!"
            );
        }
    }

    /** EXTERNAL */

    // The original contract of Wolf Game is susceptible to an exploit whereby only WOLFs can be minted
    // This is due to the fact that you can check the traits of the minted NFT atomically
    // Problem is solvable by not revealing the batch. Setting the max mint number to 10
    // means that no one can mint more than 10 in a single transaction. And since the current
    // batch is not revealed until the next batch, there is no way to game this setup.
    // This also implies that at least the last 10 NFTs should be minted by admin, to
    // reveal the previous batch.

    /**
     * mint a gen0 token - 90% Prey, 10% Predators
     * Due to buffer considerations, staking is not possible immediately
     * Minter has to wait for 10 mints
     */
    function mintGen0(uint256 amount) external payable whenNotPaused {
        address msgSender = _msgSender();

        require(block.timestamp >= mintStartTime, "Minting not started yet");
        require(tx.origin == msgSender, "Only EOA");
        // - MAX_PER_MINT, because the last MAX_PER_MINT are mintable by an admin
        require(
            mintedPerGen[0] + amount <= GEN0_TOKENS,
            "Mint less, there are no this many gen0 tokens left"
        );
        require(
            mintedPerAddress[msgSender] + amount <= MAX_MINT_PER_ADDRESS,
            "You cant mint that much for this address!"
        );
        uint256 mintCostEther = _getMintPrice(amount);

        if (
            amount >= 10 &&
            whitelist.isWhitelisted(msgSender) &&
            !whitelistClaimed[msgSender]
        ) {
            mintCostEther *= amount - 1;
            mintCostEther /= amount;
        }

        require(
            mintCostEther <= msg.value,
            "Not enough amount sent with transaction"
        );
        _batchmint(msgSender, amount, 0, 0, true);

        // send back excess value
        if (msg.value > mintCostEther) {
            Address.sendValue(payable(msgSender), msg.value - mintCostEther);
        }

        // send 25% to dao address, 75% to team address
        if (address(daoAddress) != address(0) && address(teamAddress) != address(0)) {
            Address.sendValue(payable(daoAddress), address(this).balance * 25 / 100);
            Address.sendValue(payable(teamAddress), address(this).balance);
        }
    }

    function setGen0Mint(uint256 _amount) external whenNotPaused onlyOwner {
        require(_amount >= mintedPerGen[0], "Already minted more");
        GEN0_TOKENS = _amount;
    }

    function mintUnderpeg(
        address to,
        uint256 amount,
        uint256 price
    ) external whenNotPaused {
        require(isOperator(), "no permission");
        require(
            mintedPerGen[currentGeneration] + amount <=
                getGenTokens(currentGeneration),
            "Mint less, there are no this many tokens left"
        );

        _batchmint(to, amount, price, currentGeneration, false);
    }

    function mintGeneric (
        address to,
        uint256 amount,
        uint256 price,
        uint256 generation,
        bool stealing
    ) external whenNotPaused onlyController {
        _batchmint(to, amount, price, generation, stealing);
    }

    function increaseGeneration() external {
        require(isOperator(), "no permission");

        currentGeneration++;
    }

    // TODO: ADD MINT by CONTROLLER

    function _batchmint(
        address msgSender,
        uint256 amount,
        uint256 mintPrice,
        uint256 generation,
        bool stealing
    ) internal whenNotPaused {
        require(amount > 0 && amount <= MAX_PER_MINT, "Invalid mint amount");
        if (
            lastRevealed < minted &&
            mintBlock[minted] + REVEAL_DELAY <= block.number
        ) {
            lastRevealed = minted;
        }

        uint256 seed;
        for (uint256 i = 0; i < amount; i++) {
            minted++;
            seed = entropy.random(minted);
            generate(minted, seed, mintPrice, generation);
            address recipient = msgSender;
            if (stealing) recipient = selectRecipient(seed);
            _safeMint(recipient, minted);
        }
        mintedPerGen[generation] += amount;
    }

    /**
     * update traits of a token (for future use)
     */
    function updateTokenTraits(uint256 _tokenId, PreyPredator memory _newTraits)
        external
        whenNotPaused
        onlyController
    {
        require(
            _tokenId > 0 && _tokenId <= minted,
            "UpdateTraits: token does not exist"
        );
        uint256 traitHash = structToHash(_newTraits);
        uint256 combinationId = existingCombinations[traitHash];
        require(
            combinationId == 0 || combinationId == _tokenId,
            "UpdateTraits: Token with the desired traits already exist"
        );
        // validate that new trait values actually exist by accessing the corresponding alias
        uint256 shift = 0;
        if (!_newTraits.isPrey) {
            shift = 10;
        }
        require(
            aliases[0 + shift].length > _newTraits.environment,
            "UpdateTraits: Invalid environment"
        );
        require(
            aliases[1 + shift].length > _newTraits.body,
            "UpdateTraits: Invalid body"
        );
        require(
            aliases[2 + shift].length > _newTraits.armor,
            "UpdateTraits: Invalid armor"
        );
        require(
            aliases[3 + shift].length > _newTraits.helmet,
            "UpdateTraits: Invalid helmet"
        );
        require(
            aliases[4 + shift].length > _newTraits.shoes,
            "UpdateTraits: Invalid shoes"
        );
        require(
            aliases[5 + shift].length > _newTraits.shield,
            "UpdateTraits: Invalid shield"
        );
        require(
            aliases[6 + shift].length > _newTraits.weapon,
            "UpdateTraits: Invalid weapon"
        );
        require(
            aliases[7 + shift].length > _newTraits.item,
            "UpdateTraits: Invalid item"
        );
        require(
            aliases[8 + shift].length > _newTraits.alphaIndex,
            "UpdateTraits: Invalid alpha"
        );
        require(
            currentGeneration >= _newTraits.generation,
            "UpdateTraits: Invalid generation"
        );
        delete existingCombinations[structToHash(tokenTraits[_tokenId])];
        tokenTraits[_tokenId] = _newTraits;
        existingCombinations[traitHash] = _tokenId;
        emit TokenTraitsUpdated(_tokenId, _newTraits);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        // Hardcode the Pool's approval so that users don't have to waste gas approving
        if (_msgSender() != address(pool)) {
            require(
                _isApprovedOrOwner(_msgSender(), tokenId),
                "ERC721: transfer caller is not owner nor approved"
            );
        }
        _transfer(from, to, tokenId);
    }

    function getMintPrice(uint256 amount) public view returns (uint256) {
        require(
            mintedPerGen[0] + amount <= GEN0_TOKENS,
            "Mint less, there are no this many gen0 tokens left"
        );
        return _getMintPrice(amount);
    }

    function getGenTokens(uint8 generation) public view returns (uint256) {
        return 90 + generation * 10;
    }

    /** INTERNAL */

    function _safeMint(address _ownr, uint256 _tokenId)
        internal
        virtual
        override
    {
        super._safeMint(_ownr, _tokenId);
        mintBlock[_tokenId] = block.number;
    }

    function _getMintPrice(uint256 amount) internal view returns (uint256) {
        return
            (((MINT_PRICE_END *
                mintedPerGen[0] +
                MINT_PRICE_START *
                (GEN0_TOKENS - 1 - mintedPerGen[0])) +
                (MINT_PRICE_END *
                    (mintedPerGen[0] + amount - 1) +
                    MINT_PRICE_START *
                    (GEN0_TOKENS - 1 - mintedPerGen[0] + 1 - amount))) *
                amount) /
            2 /
            (GEN0_TOKENS - 1);
    }

    /**
     * generates traits for a specific token, checking to make sure it's unique
     * @param tokenId the id of the token to generate traits for
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t - a struct of traits for the given token ID
     */
    function generate(
        uint256 tokenId,
        uint256 seed,
        uint256 mintPrice,
        uint256 generation
    ) internal returns (PreyPredator memory t) {
        t = selectTraits(seed);
        mintedPrice[tokenId] = mintPrice;
        t.generation = uint64(generation);
        if (existingCombinations[structToHash(t)] == 0) {
            tokenTraits[tokenId] = t;
            existingCombinations[structToHash(t)] = tokenId;
            return t;
        }
        return generate(tokenId, entropy.random(seed), mintPrice, generation);
    }

    /**
     * uses A.J. Walker's Alias algorithm for O(1) rarity table lookup
     * ensuring O(1) instead of O(n) reduces mint cost by more than 50%
     * probability & alias tables are generated off-chain beforehand
     * @param seed portion of the 256 bit seed to remove trait correlation
     * @param traitType the trait type to select a trait for
     * @return the ID of the randomly selected trait
     */
    function selectTrait(uint16 seed, uint8 traitType)
        internal
        view
        returns (uint8)
    {
        uint8 trait = uint8(seed) % uint8(rarities[traitType].length);
        if (seed >> 8 < rarities[traitType][trait]) return trait;
        return aliases[traitType][trait];
    }

    /**
     * they have a chance to be given to a random staked predator
     * @param seed a random value to select a recipient from
     * @return the address of the recipient (either the minter or the Predator thief's owner)
     */
    function selectRecipient(uint256 seed) internal view returns (address) {
        // 144 bits reserved for trait selection
        address thief;
        if (block.timestamp < mintStartTime + 73 hours && address(pool) != address(0)) thief = pool.getRandomPredatorOwner(seed >> 144);
        else if (block.timestamp >= mintStartTime + 73 hours && address(pool2) != address(0)) thief = pool2.getRandomPredatorOwner(seed >> 144);
        if (((seed >> 240) % 100) >= MINT_STEAL_CHANCE) {
            return _msgSender();
        } // top 16 bits haven't been used
        else {
            if (thief == address(0x0)) return _msgSender();
            return thief;
        }
    }

    /**
     * selects the species and all of its traits based on the seed value
     * @param seed a pseudorandom 256 bit number to derive traits from
     * @return t -  a struct of randomly selected traits
     */
    function selectTraits(uint256 seed)
        internal
        view
        returns (PreyPredator memory t)
    {
        t.isPrey = (seed & 0xFFFF) % 100 >= PREDATOR_MINT_CHANCE;
        uint8 shift = t.isPrey ? 0 : 10;
        seed >>= 16;
        t.environment = selectTrait(uint16(seed & 0xFFFF), 0 + shift);
        seed >>= 16;
        t.body = selectTrait(uint16(seed & 0xFFFF), 1 + shift);
        seed >>= 16;
        t.armor = selectTrait(uint16(seed & 0xFFFF), 2 + shift);
        seed >>= 16;
        t.helmet = selectTrait(uint16(seed & 0xFFFF), 3 + shift);
        seed >>= 16;
        t.shoes = selectTrait(uint16(seed & 0xFFFF), 4 + shift);
        seed >>= 16;
        t.shield = selectTrait(uint16(seed & 0xFFFF), 5 + shift);
        seed >>= 16;
        t.weapon = selectTrait(uint16(seed & 0xFFFF), 6 + shift);
        seed >>= 16;
        t.item = selectTrait(uint16(seed & 0xFFFF), 7 + shift);
        seed >>= 16;
        t.alphaIndex = selectTrait(uint16(seed & 0xFFFF), 8 + shift);
    }

    /**
     * converts a struct to a 256 bit hash to check for uniqueness
     * @param s the struct to pack into a hash
     * @return the 256 bit hash of the struct
     */
    function structToHash(PreyPredator memory s)
        internal
        pure
        returns (uint256)
    {
        return
            uint256(
                bytes32(
                    abi.encodePacked(
                        s.isPrey,
                        s.environment,
                        s.body,
                        s.armor,
                        s.helmet,
                        s.shoes,
                        s.shield,
                        s.weapon,
                        s.item,
                        s.alphaIndex
                    )
                )
            );
    }

    /** READ */

    function traitsRevealed(uint256 tokenId)
        external
        view
        returns (bool revealed)
    {
        if (
            tokenId <= lastRevealed ||
            mintBlock[tokenId] + REVEAL_DELAY <= block.number
        ) return true;
        return false;
    }

    // only used in traits in a couple of places that all boil down to tokenURI
    // so it is safe to buffer the reveal
    function getTokenTraits(uint256 tokenId)
        external
        view
        override
        returns (PreyPredator memory)
    {
        // to prevent people from minting only predators. We reveal the minted batch,
        // after a few blocks.
        if (tokenId <= lastRevealed) {
            return tokenTraits[tokenId];
        } else {
            require(
                mintBlock[tokenId] + REVEAL_DELAY <= block.number,
                "Traits of this token can't be revealed yet"
            );
            //            mintBlock[tokenId] = block.number;
            return tokenTraits[tokenId];
        }
    }

    /** ADMIN */

    /**
     * called after deployment so that the contract can get random predator thieves
     * @param _pool the address of the Pool
     */
     // initial staking pool address
    function setPool(address _pool) external onlyOwner {
        pool = IPool(_pool);
        _addController(_pool);
    }

    // address of pool2
    function setPool2(address _pool) external onlyOwner {
        pool2 = IPool(_pool);
        _addController(_pool);
    }

    function setDaoAddress(address _adr) external onlyOwner {
        daoAddress = _adr;
    }

    function setTeamAddress(address _adr) external onlyOwner {
        teamAddress = _adr;
    }

    function setEntropy(address _entropy) external onlyOwner {
        entropy = IEntropy(_entropy);
    }

    function setRoyalty(address _addr, uint96 _fee) external onlyOwner {
        ROYALTY_FEE = _fee;
        _setDefaultRoyalty(_addr, _fee);
    }

    function setPredatorMintChance(uint8 _mintChance) external onlyOwner {
        PREDATOR_MINT_CHANCE = _mintChance;
    }

    function setMintStealChance(uint8 _mintStealChance) external onlyOwner {
        MINT_STEAL_CHANCE = _mintStealChance;
    }

    /**
     * allows owner to withdraw funds from minting
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * reserve amounts for treasury / marketing
     */
    function reserve(uint256 amount, uint256 generation)
        external
        whenNotPaused
        onlyOwner
    {
        require(amount > 0 && amount <= MAX_PER_MINT, "Invalid mint amount");
        require(block.timestamp >= mintStartTime, "Minting not started yet");
        require(generation <= currentGeneration, "Invalid generation");
        _batchmint(owner(), amount, 0, generation, false);
    }

    /**
     * enables owner to pause / unpause minting
     */
    function setPaused(bool _paused) external onlyOwner {
        if (_paused) _pause();
        else _unpause();
    }

    /** RENDER */

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );
        // to prevent people from minting only predators. We reveal the minted batch,
        // if the next batch has been minted.
        if (tokenId <= lastRevealed) {
            return traits.tokenURI(tokenId);
        } else {
            require(
                mintBlock[tokenId] + REVEAL_DELAY <= block.number,
                "Traits of this token can't be revealed yet"
            );
            //            mintBlock[tokenId] = block.number;
            return traits.tokenURI(tokenId);
        }
    }

    // ** OVERRIDES **//
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override(ERC721, ERC721Enumerable) {
        require(!isBlacklisted(from), "PreyPredator: sender is blacklisted");
        require(!isBlacklisted(to), "PreyPredator: receiver is blacklisted");
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        require(!isBlacklisted(operator), "PreyPredator: operator is blacklisted");
        return controllers[operator] || super.isApprovedForAll(owner, operator);
    }

    function _burn(uint256 tokenId)
        internal
        virtual
        override(ERC721, ERC721Royalty)
    {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface INFTPool {
    function addGladReward(uint256 amount) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "../Controllable.sol";
import "../owner/Operator.sol";
import "../owner/Blacklistable.sol";
import "../interfaces/IOracle.sol";

contract Glad is ERC20Burnable, Operator, Controllable, Blacklistable {
    mapping(address => bool) private _isExcludedFromTransferTax;
    mapping(address => bool) private _isExcludedFromSellTax;

    address public taxRecipient;

    uint256 public transferTax;
    bool public transferTaxEnabled;

    uint256[] public sellTaxPriceTiers;
    uint256[] public sellTaxTiers;
    bool public sellTaxEnabled;

    address public pair1;
    address public pair2;

    address public priceOracle;

    constructor() ERC20("Gladiator Finance", "GLAD") {
        _isExcludedFromTransferTax[msg.sender] = true;
        _isExcludedFromTransferTax[address(this)] = true;

        taxRecipient = msg.sender;
    }

    function mint(address to, uint256 amount) public returns (bool) {
        require(isOperator() || controllers[msg.sender], "no permission");

        _mint(to, amount);
        return true;
    }

    function burn(uint256 amount) public override {
        _burn(msg.sender, amount);
    }

    function burnFrom(address from, uint256 amount) public override {
        require(isOperator() || controllers[msg.sender], "no permission");

        _burn(from, amount);
    }

    function setPriceOracle(address _priceOracle) public onlyOwner {
        require(_priceOracle != address(0));

        priceOracle = _priceOracle;
    }

    function getPrice() public view returns (uint256 gladPrice) {
        try IOracle(priceOracle).consult(address(this), 1e18) returns (
            uint144 price
        ) {
            return uint256(price);
        } catch {
            revert("Glad: failed to consult token price from the oracle");
        }
    }

    function setPair1(address _pair1) public onlyOwner {
        pair1 = _pair1;
    }

    function setPair2(address _pair2) public onlyOwner {
        pair2 = _pair2;
    }

    function isExcludedFromTransferTax(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromTransferTax[account];
    }

    function excludeFromTransferTax(address account) public onlyOwner {
        _isExcludedFromTransferTax[account] = true;
    }

    function includeInTransferTax(address account) public onlyOwner {
        _isExcludedFromTransferTax[account] = false;
    }

    function setTransferTax(uint256 _transferTax) public onlyOwner {
        require(_transferTax <= 10000);
        transferTax = _transferTax;
    }

    function setTransferTaxEnabled(bool _enabled) public onlyOwner {
        transferTaxEnabled = _enabled;
    }

    function isExcludedFromSellTax(address account) public view returns (bool) {
        return _isExcludedFromSellTax[account];
    }

    function excludeFromSellTax(address account) public onlyOwner {
        _isExcludedFromSellTax[account] = true;
    }

    function includeInSellTax(address account) public onlyOwner {
        _isExcludedFromSellTax[account] = false;
    }

    function setSellTax(
        uint256[] memory _sellTaxPriceTiers,
        uint256[] memory _sellTaxTiers
    ) public onlyOwner {
        require(
            _sellTaxPriceTiers.length == _sellTaxTiers.length,
            "tier length mismatch"
        );
        for (uint256 i; i < _sellTaxPriceTiers.length; i++) {
            require(_sellTaxTiers[i] < 10000, "setSellTax: tax out of range");
            if (i > 0) {
                require(
                    _sellTaxPriceTiers[i - 1] < _sellTaxPriceTiers[i],
                    "setSellTax: invalid order"
                );
            }
        }
        sellTaxPriceTiers = _sellTaxPriceTiers;
        sellTaxTiers = _sellTaxTiers;
    }

    function setSellTaxEnabled(bool _enabled) public onlyOwner {
        sellTaxEnabled = _enabled;
    }

    function setTaxRecipient(address _taxRecipient) public onlyOwner {
        require(_taxRecipient != address(0), "zero address provided");
        taxRecipient = _taxRecipient;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(
            !isBlacklisted(from) && !isBlacklisted(to),
            "sender or recipient is blacklisted"
        );

        if (to == pair1 || to == pair2) {
            if (!_isExcludedFromSellTax[from] && sellTaxEnabled) {
                amount = _takeSellTax(from, amount);
            }
        } else {
            if (!_isExcludedFromTransferTax[from] && transferTaxEnabled) {
                amount = _takeTransferTax(from, amount);
            }
        }

        super._transfer(from, to, amount);
    }

    function _takeTransferTax(address sender, uint256 amount)
        private
        returns (uint256)
    {
        uint256 taxAmount = (amount * transferTax) / 10000;
        super._transfer(sender, taxRecipient, taxAmount);
        return amount - taxAmount;
    }

    function _takeSellTax(address sender, uint256 amount)
        private
        returns (uint256)
    {
        uint256 length = sellTaxPriceTiers.length;
        uint256 sellTax;
        uint256 price = getPrice();
        if (price < sellTaxPriceTiers[0]) {
            sellTax = sellTaxTiers[0];
        } else if (price >= sellTaxPriceTiers[length - 1]) {
            sellTax = sellTaxTiers[length - 1];
        } else {
            for (uint256 i = 1; i < length; i++) {
                if (price < sellTaxPriceTiers[i]) {
                    sellTax =
                        sellTaxTiers[i] +
                        ((sellTaxTiers[i - 1] - sellTaxTiers[i]) *
                            (sellTaxPriceTiers[i] - price)) /
                        (sellTaxPriceTiers[i] - sellTaxPriceTiers[i - 1]);
                    break;
                }
            }
        }
        uint256 taxAmount = (amount * sellTax) / 10000;
        super._transfer(sender, taxRecipient, taxAmount);
        return amount - taxAmount;
    }

    function approve(address spender, uint256 amount)
        public
        override
        checkBlacklist(msg.sender)
        returns (bool)
    {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public override checkBlacklist(msg.sender) returns (bool) {
        address spender = _msgSender();
        if (!isOperator() && !controllers[spender]) _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
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

// SPDX-License-Identifier: MIT LICENSE

pragma solidity =0.8.9;

interface IPool {
    // struct to store a stake's token, owner, and earning values
    struct Stake {
        uint64 tokenId;
        address owner;
    }

    struct UserStake {
        uint80 lastTimestamp;
        uint64 preyStaked;
        uint64 predatorsStaked;
        // barn staking
        uint256 lastRewardPerPrey;
        uint256 claimableBarnReward;
        // pack staking
        uint256 claimablePackReward;
        uint256 stakedAlpha;
        uint256 lastRewardPerAlpha;
    }

    function addManyToPool(uint64[] calldata tokenIds) external;

    function claimManyFromPool(uint64[] calldata tokenIds) external;

    function getUserStake(address userid)
        external
        view
        returns (UserStake memory);

    function getRandomPredatorOwner(uint256 seed)
        external
        view
        returns (address);

    function getRandomPreyOwner(uint256 seed) external view returns (address);

    function getRandomPredatorStake(uint256 seed)
        external
        view
        returns (Stake memory);

    function getRandomPreyStake(uint256 seed)
        external
        view
        returns (Stake memory);
}

// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.0;

interface IEntropy {
    function random(uint256 seed) external view returns (uint256);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface ITraits {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.9;

interface IWhitelist {
    // total size of the whitelist
    function wlSize() external view returns (uint256);
    // max number of wl spot sales
    function maxSpots() external view returns (uint256);
    // price of the WL spot
    function spotPrice() external view returns (uint256);
    // number of wl spots sold
    function spotCount() external view returns (uint256);
    // glad/wl sale has started
    function started() external view returns (bool);
    // wl sale has ended
    function wlEnded() external view returns (bool);
    // glad sale has ended
    function gladEnded() external view returns (bool);
    // total glad sold (wl included)
    function totalPGlad() external view returns (uint256);
    // total whitelisted glad sold
    function totalPGladWl() external view returns (uint256);

    // minimum glad amount buyable
    function minGladBuy() external view returns (uint256);
    // max glad that a whitelisted can buy @ discounted price
    function maxWlAmount() external view returns (uint256);

    // pglad sale price (for 100 units, so 30 means 0.3 avax / pglad)
    function pGladPrice() external view returns (uint256);
    // pglad wl sale price (for 100 units, so 20 means 0.2 avax / pglad)
    function pGladWlPrice() external view returns (uint256);

    // get the amount of pglad purchased by user (wl buys included)
    function pGlad(address _a) external view returns (uint256);
    // get the amount of wl plgad purchased
    function pGladWl(address _a) external view returns (uint256);

    // buy whitelist spot, avax value must be sent with transaction
    function buyWhitelistSpot() external payable;

    // buy pglad, avax value must be sent with transaction
    function buyPGlad(uint256 _amount) external payable;

    // check if an address is whitelisted
    function isWhitelisted(address _a) external view returns (bool);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controllable is Ownable {
    mapping (address => bool) controllers;

    event ControllerAdded(address);
    event ControllerRemoved(address);

    modifier onlyController() {
        require(controllers[_msgSender()] || _msgSender() ==  owner(), "Only controllers can do that");
        _;
    }

    /*** ADMIN  ***/
    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
         _addController(controller);
    }

    function _addController(address controller) internal {
        if (!controllers[controller]) {
            controllers[controller] = true;
            emit ControllerAdded(controller);
        }
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        _RemoveController(controller);
    }

    function _RemoveController(address controller) internal {
        if (controllers[controller]) {
            controllers[controller] = false;
            emit ControllerRemoved(controller);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Blacklistable is Context, Ownable {
    mapping(address => bool) private _blacklisted;

    modifier checkBlacklist(address account) {
        require(!_blacklisted[account], "Blacklistable: caller is blacklisted");
        _;
    }

    function isBlacklisted(address account) public view returns (bool) {
        return _blacklisted[account];
    }

    function addToBlacklist(address[] memory accounts) public onlyOwner {
        uint256 length = accounts.length;
        for (uint256 i; i < length; i++) {
            _blacklisted[accounts[i]] = true;
        }
    }

    function removeFromBlacklist(address[] memory accounts) public onlyOwner {
        uint256 length = accounts.length;
        for (uint256 i; i < length; i++) {
            _blacklisted[accounts[i]] = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/ERC721Royalty.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../common/ERC2981.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev Extension of ERC721 with the ERC2981 NFT Royalty Standard, a standardized way to retrieve royalty payment
 * information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC721Royalty is ERC2981, ERC721 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC2981) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally clears the royalty information for the token.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);
        _resetTokenRoyalty(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be irreversibly burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `tokenId` must be already minted.
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

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
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}