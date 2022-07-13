// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "./w-IERC20.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./NewMathFunclib.sol";

contract WandInvestments is ReentrancyGuard, Ownable {
    uint256 public constant SEED_AMOUNT_1 = 9411764706 * 10**12;
    uint256 public constant SEED_AMOUNT_2 = 4470588235 * 10**13;
    uint256 public constant SEED_AMOUNT_3 = 4705882353 * 10**13;
    uint256 public constant SEED_AMOUNT = SEED_AMOUNT_1 + SEED_AMOUNT_2 + SEED_AMOUNT_3;

    uint256 constant DECIMALS = 10**18;
    uint256 constant SECONDS_IN_A_DAY = 60 * 60 * 24;

    // The contract attempts to transfer the stable coins from the SCEPTER_TREASURY_ADDR
    // and the BATON_TREASURY_ADDR address. Therefore, these addresses need to approve
    // this contract spending the stable coins by calling the "approve" function on the
    // stable coins and supplying them with the address of this contract as the "spender",
    // and "115792089237316195423570985008687907853269984665640564039457584007913129639935"
    // as the "amount".
    address public constant SCEPTER_TREASURY_ADDR = 0xb32e3D54f7b60C719537b2A32736eADf382Cc47f;
    address public constant BATON_TREASURY_ADDR = 0x5D8c972231BbA705Bd2148b67C86e7E126B16C74;
    address public constant DEV_WALLET_ADDR = 0x00719601bD4d4755B04992a02bc2809bF2D11F8a;

    // This contract needs to be allowed to mint and burn the Scepter, Wand, and Baton tokens
    // to and from any address.
    IERC20 public constant SPTR = IERC20(0xE9Dc74A35B39100edc50F1551260edbB08Fd0b0C);
    IERC20 public constant WAND = IERC20(0x1EEe04FcE71B93Fdc092Be7A53b42224D3141bDb);
    IERC20 public constant BTON = IERC20(0x397E8D58D63866595390f4d516C1334AcA71Bb9A);

    bool public tradingEnabled = false;

    mapping(address => bool) public whiteListAddresses;

    uint256 public btonTreasuryBal;

    uint256 public timeLaunched = 0;
    uint256 public daysInCalculation;

    // *START TESTING*
    // TODO(KAMA): Remove and replace all timestamp with block.timestamp
    uint256 public timestamp = block.timestamp;

    function setTimestamp(uint256 time) external {
        timestamp = time;
    }

    function advanceTimestamp() external {
        timestamp += SECONDS_IN_A_DAY;
    }
    // *END TESTING*

    struct ScepterData {
        uint256 sptrGrowthFactor;
        uint256 sptrSellFactor;
        uint256 sptrBackingPrice;
        uint256 sptrSellPrice;
        uint256 sptrBuyPrice;
        uint256 sptrTreasuryBal;
    }
    ScepterData public scepterData;

    mapping(uint256 => uint256) public tokensBoughtXDays;
    mapping(uint256 => uint256) public tokensSoldXDays;
    mapping(uint256 => uint256) public circulatingSupplyXDays;
    mapping(uint256 => bool) private setCircSupplyToPreviousDay;

    struct stableTokensParams {
        address contractAddress;
        uint256 tokenDecimals;
    }
    mapping (string => stableTokensParams) public stableERC20Info;

    struct lockedamounts {
        uint256 timeUnlocked;
        uint256 amounts;
    }
    mapping(address => lockedamounts) public withheldWithdrawals;

    mapping(address => uint256) public initialTimeHeld;
    mapping(address => uint256) public timeSold;

    struct btonsLocked {
        uint256 timeInit;
        uint256 amounts;
    }
    mapping(address => btonsLocked) public btonHoldings;

    event SceptersBought(address indexed from, uint256 amount);
    event SceptersSold(address indexed from, uint256 amount);

    constructor() {
        // Multisig address is the contract owner.
        _transferOwnership(0xE9E36a2524b7ea4BE96bB3e11e458704a36d070e);

        stableERC20Info["USDC"].contractAddress = 0x023c245a0CA897C6Bd889df3342922f963E96943;
        stableERC20Info["USDC"].tokenDecimals = 6;

        stableERC20Info["DAI"].contractAddress = 0x5810c71D8c4c83e535686f039Daa4150416182A6;
        stableERC20Info["DAI"].tokenDecimals = 18;

        // *START TESTING*
        // TODO(KAMA): Uncomment these two lines
        // stableERC20Info["FRAX"].contractAddress = 0xDA0bab807633f07f013f94DD0E6A4F96F8742B53;
        // stableERC20Info["FRAX"].tokenDecimals = 18;
        // *END TESTING*
    }

    function setCirculatingSupplyXDaysToPrevious(uint256 dInArray) private returns (uint256) {
        if (setCircSupplyToPreviousDay[dInArray]) {
            return circulatingSupplyXDays[dInArray];
        }
        setCircSupplyToPreviousDay[dInArray] = true;
        circulatingSupplyXDays[dInArray] = setCirculatingSupplyXDaysToPrevious(dInArray - 1);
        return circulatingSupplyXDays[dInArray];
    }

    function cashOutScepter(
        uint256 amountSPTRtoSell,
        uint256 daysChosenLocked,
        string calldata stableChosen
    )
        external nonReentrant
    {
        require(tradingEnabled, "Disabled");
        require(SPTR.balanceOf(msg.sender) >= amountSPTRtoSell, "You dont have that amount!");
        require(daysChosenLocked < 10, "You can only lock for a max of 9 days");

        uint256 usdAmt = mathFuncs.decMul18(
            mathFuncs.decMul18(scepterData.sptrSellPrice, amountSPTRtoSell),
            mathFuncs.decDiv18((daysChosenLocked + 1) * 10, 100)
        );

        require(usdAmt > 0, "Not enough tokens swapped");

        uint256 dInArray = (timestamp - timeLaunched) / SECONDS_IN_A_DAY;
        tokensSoldXDays[dInArray] += amountSPTRtoSell;
        setCirculatingSupplyXDaysToPrevious(dInArray);
        circulatingSupplyXDays[dInArray] -= amountSPTRtoSell;

        scepterData.sptrTreasuryBal -= usdAmt;

        calcSPTRData();

        WAND.burn(SCEPTER_TREASURY_ADDR, amountSPTRtoSell);
        SPTR.burn(msg.sender, amountSPTRtoSell);

        if (daysChosenLocked == 0) {
            require(stableERC20Info[stableChosen].contractAddress != address(0), "Unsupported stable coin");
            IERC20 tokenStable = IERC20(stableERC20Info[stableChosen].contractAddress);

            uint256 usdAmtTrf = usdAmt / 10**(18 - stableERC20Info[stableChosen].tokenDecimals);
            uint256 usdAmtToUser = mathFuncs.decMul18(usdAmtTrf, mathFuncs.decDiv18(95, 100));

            require(usdAmtToUser > 0, "Not enough tokens swapped");

            _safeTransferFrom(tokenStable, SCEPTER_TREASURY_ADDR, msg.sender, usdAmtToUser);
            _safeTransferFrom(tokenStable, SCEPTER_TREASURY_ADDR, DEV_WALLET_ADDR, usdAmtTrf - usdAmtToUser);
        } else {
            withheldWithdrawals[msg.sender].amounts = usdAmt;
            withheldWithdrawals[msg.sender].timeUnlocked =
                timestamp + (daysChosenLocked * SECONDS_IN_A_DAY);
        }

        timeSold[msg.sender] = timestamp;
        if (SPTR.balanceOf(msg.sender) == 0 && BTON.balanceOf(msg.sender) == 0) {
            initialTimeHeld[msg.sender] = 0;
        }

        emit SceptersSold(msg.sender, amountSPTRtoSell);
    }

    function cashOutBaton(uint256 amountBTONtoSell, string calldata stableChosen) external nonReentrant {
        require(tradingEnabled, "Disabled");
        require(BTON.balanceOf(msg.sender) >= amountBTONtoSell, "You dont have that amount!");
        require(stableERC20Info[stableChosen].contractAddress != address(0), "Unsupported stable coin");

        IERC20 tokenStable = IERC20(stableERC20Info[stableChosen].contractAddress);

        uint256 usdAmt = mathFuncs.decMul18(getBTONRedeemingPrice(), amountBTONtoSell);
        uint256 usdAmtTrf = usdAmt / 10**(18 - stableERC20Info[stableChosen].tokenDecimals);

        require(usdAmtTrf > 0, "Not enough tokens swapped");

        btonTreasuryBal -= usdAmt;

        btonHoldings[msg.sender].timeInit = timestamp;
        btonHoldings[msg.sender].amounts -= amountBTONtoSell;

        BTON.burn(msg.sender, amountBTONtoSell);
        _safeTransferFrom(tokenStable, BATON_TREASURY_ADDR, msg.sender, usdAmtTrf);

        timeSold[msg.sender] = timestamp;
        if (SPTR.balanceOf(msg.sender) == 0 && BTON.balanceOf(msg.sender) == 0) {
            initialTimeHeld[msg.sender] = 0;
        }
    }

    function transformScepterToBaton(uint256 amountSPTRtoSwap) external nonReentrant {
        require(tradingEnabled, "Disabled");
        require(SPTR.balanceOf(msg.sender) >= amountSPTRtoSwap, "You dont have that amount!");

        uint256 btonTreaAmtTrf = mathFuncs.decMul18(
            mathFuncs.decMul18(scepterData.sptrBackingPrice, amountSPTRtoSwap),
            mathFuncs.decDiv18(9, 10)
        );
        uint256 toTrf = btonTreaAmtTrf / 10**12;

        require(toTrf > 0, "Not enough tokens swapped");

        IERC20 tokenStable = IERC20(stableERC20Info["USDC"].contractAddress);

        uint256 dInArray = (timestamp - timeLaunched) / SECONDS_IN_A_DAY;
        tokensSoldXDays[dInArray] += amountSPTRtoSwap;
        setCirculatingSupplyXDaysToPrevious(dInArray);
        circulatingSupplyXDays[dInArray] -= amountSPTRtoSwap;

        scepterData.sptrTreasuryBal -= btonTreaAmtTrf;

        calcSPTRData();

        btonTreasuryBal += btonTreaAmtTrf;

        btonHoldings[msg.sender].timeInit = timestamp;
        btonHoldings[msg.sender].amounts += amountSPTRtoSwap;

        WAND.burn(SCEPTER_TREASURY_ADDR, amountSPTRtoSwap);
        SPTR.burn(msg.sender, amountSPTRtoSwap);
        BTON.mint(msg.sender, amountSPTRtoSwap);
        _safeTransferFrom(tokenStable, SCEPTER_TREASURY_ADDR, BATON_TREASURY_ADDR, toTrf);
    }

    function buyScepter(uint256 amountSPTRtoBuy, string calldata stableChosen) external nonReentrant {
        require(tradingEnabled, "Disabled");
        require(amountSPTRtoBuy <= 250000 * DECIMALS , "Per transaction limit");
        require(stableERC20Info[stableChosen].contractAddress != address(0), "Unsupported stable coin");

        IERC20 tokenStable = IERC20(stableERC20Info[stableChosen].contractAddress);

        uint256 usdAmt = mathFuncs.decMul18(amountSPTRtoBuy, scepterData.sptrBuyPrice);
        uint256 usdAmtToPay = usdAmt / 10**(18 - stableERC20Info[stableChosen].tokenDecimals);

        require(tokenStable.balanceOf(msg.sender) >= usdAmtToPay, "You dont have that amount!");

        uint256 dInArray = (timestamp - timeLaunched) / SECONDS_IN_A_DAY;
        tokensBoughtXDays[dInArray] += amountSPTRtoBuy;
        setCirculatingSupplyXDaysToPrevious(dInArray);
        circulatingSupplyXDays[dInArray] += amountSPTRtoBuy;

        scepterData.sptrTreasuryBal += mathFuncs.decMul18(usdAmt, mathFuncs.decDiv18(95, 100));

        calcSPTRData();

        uint256 usdAmtToTreasury = mathFuncs.decMul18(usdAmtToPay, mathFuncs.decDiv18(95, 100));

        require(usdAmtToTreasury > 0, "Not enough tokens swapped");

        _safeTransferFrom(tokenStable, msg.sender, SCEPTER_TREASURY_ADDR, usdAmtToTreasury);
        _safeTransferFrom(tokenStable, msg.sender, DEV_WALLET_ADDR, usdAmtToPay - usdAmtToTreasury);

        SPTR.mint(msg.sender, amountSPTRtoBuy);
        WAND.mint(SCEPTER_TREASURY_ADDR, amountSPTRtoBuy);

        if (initialTimeHeld[msg.sender] == 0) {
            initialTimeHeld[msg.sender] = timestamp;
        }

        emit SceptersBought(msg.sender, amountSPTRtoBuy);
    }

    function wlBuyScepter(uint256 amountSPTRtoBuy, string calldata stableChosen) external nonReentrant {
        require(tradingEnabled, "Disabled");
        require(timestamp > timeLaunched + 129600); // 36hrs
        require(whiteListAddresses[msg.sender], "Not Whitelisted");
        require(stableERC20Info[stableChosen].contractAddress != address(0), "Unsupported stable coin");

        IERC20 tokenStable = IERC20(stableERC20Info[stableChosen].contractAddress);

        uint256 usdAmtFixed = mathFuncs.decMul18(amountSPTRtoBuy, mathFuncs.decDiv18(60, 100));
        uint256 usdAmt =
            usdAmtFixed +
            mathFuncs.decMul18(amountSPTRtoBuy - usdAmtFixed, scepterData.sptrBuyPrice);
        uint256 usdAmtToPay = usdAmt / 10**(18 - stableERC20Info[stableChosen].tokenDecimals);

        require(usdAmt >= 25000 * DECIMALS, "Whale WL purchase has to be larger than 25K USD");
        require(tokenStable.balanceOf(msg.sender) >= usdAmtToPay, "You dont have that amount!");

        uint256 dInArray = (timestamp - timeLaunched) / SECONDS_IN_A_DAY;
        tokensBoughtXDays[dInArray] += amountSPTRtoBuy;
        setCirculatingSupplyXDaysToPrevious(dInArray);
        circulatingSupplyXDays[dInArray] += amountSPTRtoBuy;

        scepterData.sptrTreasuryBal += mathFuncs.decMul18(usdAmt, mathFuncs.decDiv18(95, 100));

        calcSPTRData();

        uint256 usdAmtToTreasury = mathFuncs.decMul18(usdAmtToPay, mathFuncs.decDiv18(95, 100));

        require(usdAmtToTreasury > 0, "Not enough tokens swapped");

        _safeTransferFrom(tokenStable, msg.sender, SCEPTER_TREASURY_ADDR, usdAmtToTreasury);
        _safeTransferFrom(tokenStable, msg.sender, DEV_WALLET_ADDR, usdAmtToPay - usdAmtToTreasury);

        SPTR.mint(msg.sender, amountSPTRtoBuy);
        WAND.mint(SCEPTER_TREASURY_ADDR, amountSPTRtoBuy);

        if (initialTimeHeld[msg.sender] == 0) {
            initialTimeHeld[msg.sender] = timestamp;
        }

        emit SceptersBought(msg.sender, amountSPTRtoBuy);
    }

    function claimLockedUSDC(string calldata stableChosen) external nonReentrant {
        require(tradingEnabled, "Disabled");
        require(withheldWithdrawals[msg.sender].timeUnlocked != 0, "No locked funds to claim");
        require(timestamp >= withheldWithdrawals[msg.sender].timeUnlocked, "Not unlocked");
        require(stableERC20Info[stableChosen].contractAddress != address(0), "Unsupported stable coin");

        IERC20 tokenStable = IERC20(stableERC20Info[stableChosen].contractAddress);

        uint256 claimAmts =
            withheldWithdrawals[msg.sender].amounts /
            10**(18 - stableERC20Info[stableChosen].tokenDecimals);
        uint256 amtToUser = mathFuncs.decMul18(claimAmts, mathFuncs.decDiv18(95, 100));

        delete withheldWithdrawals[msg.sender];
        _safeTransferFrom(tokenStable, SCEPTER_TREASURY_ADDR, msg.sender, amtToUser);
        _safeTransferFrom(tokenStable, SCEPTER_TREASURY_ADDR, DEV_WALLET_ADDR, claimAmts - amtToUser);
    }

    function getCircSupplyXDays() public view returns (uint256) {
        if (timeLaunched == 0) return SEED_AMOUNT;
		uint256 daySinceLaunched = (timestamp - timeLaunched) / SECONDS_IN_A_DAY;
        uint256 numdays = daysInCalculation / SECONDS_IN_A_DAY;
        if (daySinceLaunched < numdays) {
            return SEED_AMOUNT;
        }
        for (uint d = daySinceLaunched - numdays; d > 0; d--) {
            if (setCircSupplyToPreviousDay[d]) {
                return circulatingSupplyXDays[d];
            }
        }
        return circulatingSupplyXDays[0];
    }

    function getBTONBackingPrice() public view returns (uint256) {
        if (BTON.totalSupply() == 0) return DECIMALS;
        return mathFuncs.decDiv18(btonTreasuryBal, BTON.totalSupply());
    }

    function getBTONRedeemingPrice() public view returns (uint256) {
        uint256 btonPrice = mathFuncs.decMul18(getBTONBackingPrice(), mathFuncs.decDiv18(30, 100));
        uint256 sptrPriceHalf = scepterData.sptrBackingPrice / 2;
        if (btonPrice > sptrPriceHalf) {
            return sptrPriceHalf;
        }
        return btonPrice;
    }

    function calcSPTRData() private {
        if (getCircSupplyXDays() == 0) {
            scepterData.sptrGrowthFactor = 3 * 10**17;
        } else {
            scepterData.sptrGrowthFactor =
                2 * (mathFuncs.decDiv18(getTokensBoughtXDays(), getCircSupplyXDays()));
        }
        if (scepterData.sptrGrowthFactor > 3 * 10**17) {
            scepterData.sptrGrowthFactor = 3 * 10**17;
        }

        if (getCircSupplyXDays() == 0) {
            scepterData.sptrSellFactor = 3 * 10**17;
        } else {
            scepterData.sptrSellFactor =
                2 * (mathFuncs.decDiv18(getTokensSoldXDays(), getCircSupplyXDays()));
        }
        if (scepterData.sptrSellFactor > 3 * 10**17) {
           scepterData.sptrSellFactor = 3 * 10**17;
        }

        if (SPTR.totalSupply() == 0) {
            scepterData.sptrBackingPrice = DECIMALS;
        } else {
            scepterData.sptrBackingPrice =
                mathFuncs.decDiv18(scepterData.sptrTreasuryBal, SPTR.totalSupply());
        }

        scepterData.sptrBuyPrice = mathFuncs.decMul18(
            scepterData.sptrBackingPrice,
            12 * 10**17 + scepterData.sptrGrowthFactor
        );
        scepterData.sptrSellPrice = mathFuncs.decMul18(
            scepterData.sptrBackingPrice,
            9 * 10**17 - scepterData.sptrSellFactor
        );
    }

    function getTokensBoughtXDays() public view returns (uint256) {
        if (timeLaunched == 0) return tokensBoughtXDays[0];

        uint256 boughtCount = 0;
        uint d = 0;
        uint256 numdays = daysInCalculation / SECONDS_IN_A_DAY;
        uint256 daySinceLaunched = (timestamp - timeLaunched) / SECONDS_IN_A_DAY;

        if (daySinceLaunched > numdays) {
            d = daySinceLaunched - numdays;
        }
        for (; d <= daySinceLaunched; d++) {
            boughtCount += tokensBoughtXDays[d];
        }
        return boughtCount;
    }

    function getTokensSoldXDays() public view returns (uint256) {
        if (timeLaunched == 0) return tokensSoldXDays[0];

        uint256 soldCount = 0;
        uint256 d;
        uint256 numdays = daysInCalculation / SECONDS_IN_A_DAY;
        uint256 daySinceLaunched = (timestamp - timeLaunched) / SECONDS_IN_A_DAY;

        if (daySinceLaunched > numdays) {
            d = daySinceLaunched - numdays;
        }
        for (; d <= daySinceLaunched; d++) {  
            soldCount += tokensSoldXDays[d];
        }
        return soldCount;
    }

    function turnOnOffTrading(bool value) external onlyOwner {
        tradingEnabled = value;
    }

    function updateSPTRTreasuryBal(uint256 totalAmt) external onlyOwner {
        scepterData.sptrTreasuryBal = totalAmt * DECIMALS;
        calcSPTRData();
    }

    function addOrSubFromSPTRTreasuryBal(int256 amount) external onlyOwner {
        if (amount < 0) {
            scepterData.sptrTreasuryBal -= uint256(-amount) * DECIMALS;
        } else {
            scepterData.sptrTreasuryBal += uint256(amount) * DECIMALS;
        }
        calcSPTRData();
    }

    function updateBTONTreasuryBal(uint256 totalAmt) external onlyOwner {
        btonTreasuryBal = totalAmt * DECIMALS;
    }

    function Launch(uint256 sptrTreasury, uint256 btonTreasury) external onlyOwner {
        require (timeLaunched == 0, "Already Launched");
        timestamp = block.timestamp;
        timeLaunched = timestamp;
        daysInCalculation = 5 days;

        SPTR.mint(0x1f174b307FB42B221454328EDE7bcA7De841a991, SEED_AMOUNT_1); //seed 1
        SPTR.mint(0xEF4503dD3768CB4CE1Be12F56b3ee4c7E6a5E3ec, SEED_AMOUNT_2); //seed 2
        SPTR.mint(0x90C66d0401d75A6d3b4f46cbA5F4230EE00D7f71, SEED_AMOUNT_3); //seed 3

        WAND.mint(SCEPTER_TREASURY_ADDR, SEED_AMOUNT);

        tokensBoughtXDays[0] = SEED_AMOUNT;
        circulatingSupplyXDays[0] = SEED_AMOUNT;
        setCircSupplyToPreviousDay[0] = true;
        scepterData.sptrTreasuryBal = sptrTreasury * DECIMALS;
        btonTreasuryBal = btonTreasury * DECIMALS;
        calcSPTRData();
        tradingEnabled = true;
    }

    function setDaysUsedInFactors(uint256 numDays) external onlyOwner {
        daysInCalculation = numDays * SECONDS_IN_A_DAY;
    }

    function addWhitelistee(address addr) external onlyOwner {
       whiteListAddresses[addr] = true;
    }

    function addStable(string calldata ticker, address addr, uint256 dec) external onlyOwner {
        stableERC20Info[ticker].contractAddress = addr;
        stableERC20Info[ticker].tokenDecimals = dec;
    }

    function _safeTransferFrom(
        IERC20 token,
        address sender,
        address recipient,
        uint256 amount
    )
        private
    {
        require(token.transferFrom(sender, recipient, amount), "Token transfer failed");
    }
}