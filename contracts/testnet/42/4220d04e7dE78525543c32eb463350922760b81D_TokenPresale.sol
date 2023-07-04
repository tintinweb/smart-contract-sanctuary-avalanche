/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-04
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

interface GDPbonus {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function mintToken(address recipient, uint256 amount) external;
}

contract TokenPresale {
    AggregatorV3Interface internal _avaxPriceFeed; // Chainlink AVAX/USD price feed on Avalanche network
    
    address public _owner;
    bool public _presaleLocked;

    address public _presaleTokenAddress;
    address public _bonusTokenAddress;
    address public _usdtAddress;

    uint256 public _tokenPrice = 0;
    uint256 public _bonusPercent = 0;

    constructor(address tokenAddress, address bonusTokenAddress, address usdtAddress) {
        _owner = msg.sender;
        _presaleTokenAddress = tokenAddress;
        _bonusTokenAddress = bonusTokenAddress;
        _usdtAddress = usdtAddress;
        _avaxPriceFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    modifier notLocked() {
        require(!_presaleLocked, "Presale has been locked");
        _;
    }

    function updateTokenContract(address contractAddress) public onlyOwner {
        _presaleTokenAddress = contractAddress;
    }

    function updateBonusTokenContract(address contractAddress) public onlyOwner {
        _bonusTokenAddress = contractAddress;
    }

    function updateUSDTContract(address contractAddress) public onlyOwner {
        _usdtAddress = contractAddress;
    }

    function lock() public onlyOwner {
        _presaleLocked = true;
    }

    function unlock() public onlyOwner {
        _presaleLocked = false;
    }

    function setTokenPrice(uint256 price) public onlyOwner {
        _tokenPrice = price;
    }

    function setBonusPercent(uint256 percent) public onlyOwner {
        _bonusPercent = percent;
    }

    function buyWithUSDT(uint256 amount) public notLocked {
        require(_tokenPrice != 0, "Price not defined");
        require(_bonusPercent != 0, "Bonus percent not defined");

        IERC20 token = IERC20(_presaleTokenAddress);
        GDPbonus bonusToken = GDPbonus(_bonusTokenAddress);
        IERC20 usdt = IERC20(_usdtAddress);

        uint256 totalPrice = amount * _tokenPrice / (10 ** 8);
        uint256 bonusAmount = amount / 100 * _bonusPercent;
        
        // USDT Decimal is 6, so we need to multiply by 100
        require(usdt.balanceOf(msg.sender) * 100 >= totalPrice, "Insufficient USDC balance");
        require(token.balanceOf(address(this)) >= amount, "Insufficient tokens in contract");
        
        require(usdt.transferFrom(msg.sender, address(this), totalPrice / 100), "USDC transfer failed");
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        bonusToken.mintToken(msg.sender, bonusAmount);
    }

    function buyWithAvax(uint256 amount) external payable notLocked {
        require(_tokenPrice != 0, "Price not defined");
        require(_bonusPercent != 0, "Bonus percent not defined");

        IERC20 token = IERC20(_presaleTokenAddress);
        GDPbonus bonusToken = GDPbonus(_bonusTokenAddress);

        uint256 totalPrice = amount * _tokenPrice / (10 ** 8);
        uint256 bonusAmount = amount / 100 * _bonusPercent;
        uint256 currentAvaxPrice = getLatestAvaxUsdPrice(); // AVAX price is based in decimal 8
        // AVAX Decimal is 18, so we need to multiply by 10 ** 18
        uint256 requiredAvax = totalPrice * 10 ** 18 / currentAvaxPrice;
        
        require(msg.value >= requiredAvax, "Insufficient AVAX balance");
        require(token.balanceOf(address(this)) >= amount, "Insufficient tokens in contract");

        (bool success, ) = payable(address(this)).call{value: requiredAvax}("");
        require(success, "AVAX transfer failed");
        require(token.transfer(msg.sender, amount), "Token transfer failed");
        bonusToken.mintToken(msg.sender, bonusAmount);
    }

    function getLatestAvaxUsdPrice() public view returns (uint256) {
        (, int price,,,) = _avaxPriceFeed.latestRoundData();
        return uint256(price);
    }

    function withdrawUSDT() public onlyOwner {
        IERC20 usdt = IERC20(_usdtAddress);
        require(usdt.transferFrom(address(this), msg.sender, usdt.balanceOf(address(this))), "USDT Withdraw failed");
    }

    function withdrawAvax() public onlyOwner {
        (bool success, ) = _owner.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }
}