/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-20
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.5.0;

interface IERC20 {
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);

  function totalSupply() external view returns (uint256);

  function balanceOf(address owner) external view returns (uint256);

  function allowance(address owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 value) external returns (bool);

  function transfer(address to, uint256 value) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool);
}


// File src/contracts/libraries/BokkyPooBahsDateTimeLibrary.sol


pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.00
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018.
//
// GNU Lesser General Public License 3.0
// https://www.gnu.org/licenses/lgpl-3.0.en.html
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {
  uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
  uint256 constant SECONDS_PER_HOUR = 60 * 60;
  uint256 constant SECONDS_PER_MINUTE = 60;
  int256 constant OFFSET19700101 = 2440588;

  uint256 constant DOW_MON = 1;
  uint256 constant DOW_TUE = 2;
  uint256 constant DOW_WED = 3;
  uint256 constant DOW_THU = 4;
  uint256 constant DOW_FRI = 5;
  uint256 constant DOW_SAT = 6;
  uint256 constant DOW_SUN = 7;

  // ------------------------------------------------------------------------
  // Calculate the number of days from 1970/01/01 to year/month/day using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and subtracting the offset 2440588 so that 1970/01/01 is day 0
  //
  // days = day
  //      - 32075
  //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
  //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
  //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
  //      - offset
  // ------------------------------------------------------------------------
  function _daysFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256 _days) {
    require(year >= 1970);
    int256 _year = int256(year);
    int256 _month = int256(month);
    int256 _day = int256(day);

    int256 __days = _day -
      32075 +
      (1461 * (_year + 4800 + (_month - 14) / 12)) /
      4 +
      (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
      12 -
      (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
      4 -
      OFFSET19700101;

    _days = uint256(__days);
  }

  // ------------------------------------------------------------------------
  // Calculate year/month/day from the number of days since 1970/01/01 using
  // the date conversion algorithm from
  //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
  // and adding the offset 2440588 so that 1970/01/01 is day 0
  //
  // int L = days + 68569 + offset
  // int N = 4 * L / 146097
  // L = L - (146097 * N + 3) / 4
  // year = 4000 * (L + 1) / 1461001
  // L = L - 1461 * year / 4 + 31
  // month = 80 * L / 2447
  // dd = L - 2447 * month / 80
  // L = month / 11
  // month = month + 2 - 12 * L
  // year = 100 * (N - 49) + year + L
  // ------------------------------------------------------------------------
  function _daysToDate(uint256 _days)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    int256 __days = int256(_days);

    int256 L = __days + 68569 + OFFSET19700101;
    int256 N = (4 * L) / 146097;
    L = L - (146097 * N + 3) / 4;
    int256 _year = (4000 * (L + 1)) / 1461001;
    L = L - (1461 * _year) / 4 + 31;
    int256 _month = (80 * L) / 2447;
    int256 _day = L - (2447 * _month) / 80;
    L = _month / 11;
    _month = _month + 2 - 12 * L;
    _year = 100 * (N - 49) + _year + L;

    year = uint256(_year);
    month = uint256(_month);
    day = uint256(_day);
  }

  function timestampFromDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (uint256 timestamp) {
    timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
  }

  function timestampFromDateTime(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
  ) internal pure returns (uint256 timestamp) {
    timestamp =
      _daysFromDate(year, month, day) *
      SECONDS_PER_DAY +
      hour *
      SECONDS_PER_HOUR +
      minute *
      SECONDS_PER_MINUTE +
      second;
  }

  function timestampToDate(uint256 timestamp)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function timestampToDateTime(uint256 timestamp)
    internal
    pure
    returns (
      uint256 year,
      uint256 month,
      uint256 day,
      uint256 hour,
      uint256 minute,
      uint256 second
    )
  {
    (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
    secs = secs % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
    second = secs % SECONDS_PER_MINUTE;
  }

  function isValidDate(
    uint256 year,
    uint256 month,
    uint256 day
  ) internal pure returns (bool valid) {
    if (year >= 1970 && month > 0 && month <= 12) {
      uint256 daysInMonth = _getDaysInMonth(year, month);
      if (day > 0 && day <= daysInMonth) {
        valid = true;
      }
    }
  }

  function isValidDateTime(
    uint256 year,
    uint256 month,
    uint256 day,
    uint256 hour,
    uint256 minute,
    uint256 second
  ) internal pure returns (bool valid) {
    if (isValidDate(year, month, day)) {
      if (hour < 24 && minute < 60 && second < 60) {
        valid = true;
      }
    }
  }

  function isLeapYear(uint256 timestamp) internal pure returns (bool leapYear) {
    (uint256 year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    leapYear = _isLeapYear(year);
  }

  function _isLeapYear(uint256 year) internal pure returns (bool leapYear) {
    leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
  }

  function isWeekDay(uint256 timestamp) internal pure returns (bool weekDay) {
    weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
  }

  function isWeekEnd(uint256 timestamp) internal pure returns (bool weekEnd) {
    weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
  }

  function getDaysInMonth(uint256 timestamp) internal pure returns (uint256 daysInMonth) {
    (uint256 year, uint256 month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    daysInMonth = _getDaysInMonth(year, month);
  }

  function _getDaysInMonth(uint256 year, uint256 month) internal pure returns (uint256 daysInMonth) {
    if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
      daysInMonth = 31;
    } else if (month != 2) {
      daysInMonth = 30;
    } else {
      daysInMonth = _isLeapYear(year) ? 29 : 28;
    }
  }

  // 1 = Monday, 7 = Sunday
  function getDayOfWeek(uint256 timestamp) internal pure returns (uint256 dayOfWeek) {
    uint256 _days = timestamp / SECONDS_PER_DAY;
    dayOfWeek = ((_days + 3) % 7) + 1;
  }

  function getYear(uint256 timestamp) internal pure returns (uint256 year) {
    (year, , ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
    (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getDay(uint256 timestamp) internal pure returns (uint256 day) {
    (, , day) = _daysToDate(timestamp / SECONDS_PER_DAY);
  }

  function getHour(uint256 timestamp) internal pure returns (uint256 hour) {
    uint256 secs = timestamp % SECONDS_PER_DAY;
    hour = secs / SECONDS_PER_HOUR;
  }

  function getMinute(uint256 timestamp) internal pure returns (uint256 minute) {
    uint256 secs = timestamp % SECONDS_PER_HOUR;
    minute = secs / SECONDS_PER_MINUTE;
  }

  function getSecond(uint256 timestamp) internal pure returns (uint256 second) {
    second = timestamp % SECONDS_PER_MINUTE;
  }

  function addYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year += _years;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    month += _months;
    year += (month - 1) / 12;
    month = ((month - 1) % 12) + 1;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp >= timestamp);
  }

  function addDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _days * SECONDS_PER_DAY;
    require(newTimestamp >= timestamp);
  }

  function addHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
    require(newTimestamp >= timestamp);
  }

  function addMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp >= timestamp);
  }

  function addSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp + _seconds;
    require(newTimestamp >= timestamp);
  }

  function subYears(uint256 timestamp, uint256 _years) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    year -= _years;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subMonths(uint256 timestamp, uint256 _months) internal pure returns (uint256 newTimestamp) {
    (uint256 year, uint256 month, uint256 day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    uint256 yearMonth = year * 12 + (month - 1) - _months;
    year = yearMonth / 12;
    month = (yearMonth % 12) + 1;
    uint256 daysInMonth = _getDaysInMonth(year, month);
    if (day > daysInMonth) {
      day = daysInMonth;
    }
    newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + (timestamp % SECONDS_PER_DAY);
    require(newTimestamp <= timestamp);
  }

  function subDays(uint256 timestamp, uint256 _days) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _days * SECONDS_PER_DAY;
    require(newTimestamp <= timestamp);
  }

  function subHours(uint256 timestamp, uint256 _hours) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
    require(newTimestamp <= timestamp);
  }

  function subMinutes(uint256 timestamp, uint256 _minutes) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
    require(newTimestamp <= timestamp);
  }

  function subSeconds(uint256 timestamp, uint256 _seconds) internal pure returns (uint256 newTimestamp) {
    newTimestamp = timestamp - _seconds;
    require(newTimestamp <= timestamp);
  }

  function diffYears(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _years) {
    require(fromTimestamp <= toTimestamp);
    (uint256 fromYear, , ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    (uint256 toYear, , ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _years = toYear - fromYear;
  }

  function diffMonths(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _months) {
    require(fromTimestamp <= toTimestamp);
    (uint256 fromYear, uint256 fromMonth, ) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
    (uint256 toYear, uint256 toMonth, ) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
    _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
  }

  function diffDays(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _days) {
    require(fromTimestamp <= toTimestamp);
    _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
  }

  function diffHours(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _hours) {
    require(fromTimestamp <= toTimestamp);
    _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
  }

  function diffMinutes(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _minutes) {
    require(fromTimestamp <= toTimestamp);
    _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
  }

  function diffSeconds(uint256 fromTimestamp, uint256 toTimestamp) internal pure returns (uint256 _seconds) {
    require(fromTimestamp <= toTimestamp);
    _seconds = toTimestamp - fromTimestamp;
  }
}


// File src/contracts/Presale.sol


pragma solidity >=0.8.6;


contract PresaleFlatten {
  using BokkyPooBahsDateTimeLibrary for uint256;

  address public owner;

  address public presaleToken;
  address public houseToken;

  uint256 public price; // How much Token the address gets for 1 Avax (only 2 decimals included)
  uint256 public minHouseTokenHoldAmount; // How much house token the address needs to own (in wei)

  uint256 public minClaim; // In wei

  uint256 public minBuyAvax; // In wei
  uint256 public maxBuyAvax; // In wei
  uint256 public startDateClaim; // Timestamp
  uint256 public maxPurchase; // In wei (Max amount of Avax he can spend)
  uint256 public maxClaimPercentage; // Max Claim that Account can do in a interval (percentage of bought (Avax))
  uint256 public constant FEE_DENOMINATOR = 10**9; // fee denominator

  uint256 public claimIntervalDay; // Date Interval in integer
  uint256 public claimIntervalHour; // Hour Interval in integer
  uint256 private currentClaimDate;

  bool public isBuyPaused = false; // Buy is avaialable from the start
  bool public isClaimPaused = true; // Claiming is not available, would be started later
  bool public isEnded = false; // This ends both buying and claiming

  bool public isPreSalePhase = false;
  bool public isMainSalePhase = false;
  bool public isClaimPhase = false;

  mapping(address => uint256) public bought; // Avax spent by account
  mapping(address => uint256) public totalClaimToken;

  mapping(address => string) public allocatedBand; // If the address doesn't belong to any band, the value will be ""
  mapping(string => uint256) public bandsPercentages; // Band percentages is added to the initial price, 10^9 is considered 100%
  string public constant DEFAULT_BAND = "default";

  modifier onlyOwner() {
    require(msg.sender == owner, "Only owner can access this function");
    _;
  }

  constructor(
    address[2] memory _tokenSettings, // 0: Presale Token, 1: House Token
    uint256 _price,
    uint256 _minHouseTokenHoldAmount,
    uint256[4] memory _minMaxBuyClaimSettings, // 0: Min Buy Avax, 1: Max Buy Avax, 2: minClaim, 3: maxClaimPercentage
    uint256 _maxPurchase,
    uint256[2] memory _dayHourClaimInterval // 0: Date claim Interval, 1: Hour claim Interval
  ) {
    owner = msg.sender;

    presaleToken = _tokenSettings[0];
    houseToken = _tokenSettings[1];
    price = _price;
    minBuyAvax = _minMaxBuyClaimSettings[0];
    maxBuyAvax = _minMaxBuyClaimSettings[1];
    minClaim = _minMaxBuyClaimSettings[2];
    maxClaimPercentage = _minMaxBuyClaimSettings[3];
    maxPurchase = _maxPurchase;
    if (houseToken != address(0)) {
      minHouseTokenHoldAmount = _minHouseTokenHoldAmount;
    }

    claimIntervalDay = _dayHourClaimInterval[0];
    claimIntervalHour = _dayHourClaimInterval[1];

    bandsPercentages[DEFAULT_BAND] = 0; // Normal price
    bandsPercentages["A"] = 100000000; // +10%
    bandsPercentages["B"] = 75000000; // +7.5%
    bandsPercentages["C"] = 50000000; // +5%
    bandsPercentages["D"] = 25000000; // +2.5%
  }

  //////////
  // Getters
  function calculateAvaxToPresaleToken(address _address, uint256 _amount) public view returns (uint256) {
    require(presaleToken != address(0), "Presale token not set");

    uint256 tokens = ((_amount * price) / 100) / (10**(18 - uint256(IERC20(presaleToken).decimals())));
    uint256 tokensWithBand = tokens + (tokens * bandsPercentages[allocatedBand[_address]]) / FEE_DENOMINATOR;
    return (tokensWithBand);
  }

  function getAvailableTokenToClaim(address _address) public view returns (uint256) {
    uint256 totalToken = calculateAvaxToPresaleToken(_address, bought[_address]);
    return ((totalToken * getTotalClaimPercentage()) / FEE_DENOMINATOR) - totalClaimToken[_address];
  }

  function getTotalClaimPercentage() private view returns (uint256) {
    uint256 _currentClaimDate = getCurrentClaimDate();

    (, , uint256 day, uint256 hour, , ) = BokkyPooBahsDateTimeLibrary.timestampToDateTime(_currentClaimDate);
    uint256 interval = BokkyPooBahsDateTimeLibrary.diffMonths(startDateClaim, _currentClaimDate);
    if (day > claimIntervalDay || (day == claimIntervalDay && hour >= claimIntervalHour) || interval == 0) {
      interval += 1;
    }
    uint256 totalIntervalPercentage = interval * maxClaimPercentage > FEE_DENOMINATOR
      ? FEE_DENOMINATOR
      : interval * maxClaimPercentage;
    return totalIntervalPercentage;
  }

  function getCurrentClaimDate() public view returns (uint256) {
    if (currentClaimDate == 0) {
      return block.timestamp;
    }
    return currentClaimDate;
  }

  /////////////
  // Buy tokens

  receive() external payable {
    buy();
  }

  function buy() public payable {
    require(isPreSalePhase || isMainSalePhase, "Sale is not in the right phase");
    require(!isBuyPaused, "Buying is paused");
    require(!isEnded, "Sale has ended");

    if (isPreSalePhase) {
      require(bytes(allocatedBand[msg.sender]).length > 0, "msg.sender does not belong to any band (not whitelisted)");
    }

    if (houseToken != address(0)) {
      require(
        IERC20(houseToken).balanceOf(msg.sender) >= minHouseTokenHoldAmount,
        "msg.sender doesn't hold enough house token"
      );
    }
    require(bought[msg.sender] + msg.value <= maxPurchase, "Cannot buy more than max purchase amount");
    require(msg.value >= minBuyAvax, "msg.value is less than minBuyAvax");
    require(msg.value <= maxBuyAvax, "msg.value is great than maxBuyAvax");

    bought[msg.sender] = bought[msg.sender] + msg.value;
  }

  function claim(uint256 requestedAmount) public {
    require(block.timestamp > startDateClaim, "Claim hasn't started yet");
    require(!isClaimPaused, "Claiming is paused");
    require(!isEnded, "Sale has ended");
    require(isClaimPhase, "Claim is not in the right phase");
    require(requestedAmount >= minClaim, "msg.value is less than minClaim");
    require(presaleToken != address(0), "Presale token not set");

    uint256 remainingToken = calculateAvaxToPresaleToken(msg.sender, bought[msg.sender]) - totalClaimToken[msg.sender];
    require(remainingToken >= requestedAmount, "msg.sender don't have enough token to claim");

    require(
      IERC20(presaleToken).balanceOf(address(this)) >= requestedAmount,
      "Contract doesn't have enough presale tokens. Please contact owner to add more supply"
    );
    require(
      (requestedAmount <= getAvailableTokenToClaim(msg.sender)),
      "msg.sender claim more than max claim amount in this interval"
    );

    totalClaimToken[msg.sender] += requestedAmount;

    IERC20(presaleToken).transfer(msg.sender, requestedAmount);
  }

  //////////////////
  // Owner functions
  function enterPreSalePhase() external onlyOwner {
    isPreSalePhase = true;
    isMainSalePhase = false;
    isClaimPhase = false;

    isBuyPaused = false;
    isClaimPaused = true;
  }

  function enterMainSalePhase() external onlyOwner {
    isPreSalePhase = false;
    isMainSalePhase = true;
    isClaimPhase = false;

    isBuyPaused = false;
    isClaimPaused = true;
  }

  function enterClaimPhase() external onlyOwner {
    isPreSalePhase = false;
    isMainSalePhase = false;
    isClaimPhase = true;

    isBuyPaused = true;
    isClaimPaused = false;
    startDateClaim = block.timestamp;
  }

  function setOwner(address _owner) external onlyOwner {
    owner = _owner;
  }

  function withdrawAvax(uint256 _amount, address _receiver) external onlyOwner {
    payable(_receiver).transfer(_amount);
  }

  function setPresaleToken(address _presaleToken, address _receiver) external onlyOwner {
    if (presaleToken != address(0)) {
      uint256 contractBal = IERC20(presaleToken).balanceOf(address(this));
      if (contractBal > 0) IERC20(presaleToken).transfer(_receiver, contractBal);
    }

    presaleToken = _presaleToken;
  }

  function setBandPercentage(string calldata _band, uint256 _percentage) external onlyOwner {
    bandsPercentages[_band] = _percentage;
  }

  function setBands(address[] calldata _wallets, string calldata _band) external onlyOwner {
    for (uint256 i = 0; i < _wallets.length; i++) allocatedBand[_wallets[i]] = _band;
  }

  function setBand(address _wallet, string calldata _band) external onlyOwner {
    allocatedBand[_wallet] = _band;
  }

  function setStartDateClaim(uint256 _startDateClaim) external onlyOwner {
    startDateClaim = _startDateClaim;
  }

  function setHouseToken(address _houseToken) external onlyOwner {
    houseToken = _houseToken;
  }

  function setPrice(uint256 _price) external onlyOwner {
    price = _price;
  }

  function setMinHouseTokenHoldAmount(uint256 _minHouseTokenHoldAmount) external onlyOwner {
    minHouseTokenHoldAmount = _minHouseTokenHoldAmount;
  }

  function setMaxPurchase(uint256 _maxPurchase) external onlyOwner {
    maxPurchase = _maxPurchase;
  }

  function setMinBuyAvax(uint256 _minBuyAvax) external onlyOwner {
    minBuyAvax = _minBuyAvax;
  }

  function setMaxBuyAvax(uint256 _maxBuyAvax) external onlyOwner {
    maxBuyAvax = _maxBuyAvax;
  }

  function toggleIsBuyPaused() external onlyOwner {
    isBuyPaused = !isBuyPaused;
  }

  function setMinClaim(uint256 _minClaim) external onlyOwner {
    minClaim = _minClaim;
  }

  function toggleIsClaimPause() external onlyOwner {
    if (isClaimPaused) {
      require(presaleToken != address(0), "Presale token not set");
    }
    isClaimPaused = !isClaimPaused;
  }

  function endSale(address _receiver) external onlyOwner {
    require(presaleToken != address(0), "Presale token not set");

    isEnded = true;
    isBuyPaused = true;
    isClaimPaused = true;
    isPreSalePhase = false;
    isMainSalePhase = false;
    isClaimPhase = false;

    uint256 contractBal = IERC20(presaleToken).balanceOf(address(this));
    if (contractBal > 0) IERC20(presaleToken).transfer(_receiver, contractBal);
  }

  function setCurrentClaimDate(uint256 _currentClaimDate) external onlyOwner {
    currentClaimDate = _currentClaimDate;
  }
}