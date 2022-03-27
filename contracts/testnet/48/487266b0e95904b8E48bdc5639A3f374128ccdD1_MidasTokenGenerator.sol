// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./AggregatorV3Interface.sol";
import "./Token.sol";

contract MidasTokenGenerator {
  uint256 public creationTokenPrice = 1000000000000000000; // 1 ETH
  address private aggregatorAddress;
  mapping (string => bool) private avaiblableNetworks;
  mapping(string => bool) public availableFunctions;
  mapping(address => bool) public _managers;

  IUniswapV2Router02 public immutable pcsV2Router;
  address public _aw;
  address public _bw;
  address public _cw;
  address public _dw;
  address public owner;

  uint256 _ap = 1000;
  uint256 _bp = 2000;
  uint256 _cp = 3000;
  uint256 _dp = 4000;

  uint256 divisor = 10000;

  AggregatorV3Interface internal priceFeed;

  constructor(address[] memory addresses) {
    pcsV2Router = IUniswapV2Router02(addresses[0]);
    priceFeed = AggregatorV3Interface(addresses[1]);

    _aw = addresses[2];
    _aw = addresses[3];
    _aw = addresses[4];
    _dw = addresses[5];

    avaiblableNetworks["bsc"] = true;
    avaiblableNetworks["polygon"] = true;
  }

  fallback() external payable {}
  receive() external payable {}

  modifier onlyOwner() {
      require(owner == msg.sender, "Ownable: caller is not the owner");
      _;
  }

  modifier onlyManager() {
    require(_managers[msg.sender] == true, "Only managers can call this function");
    _;
  }

  function updateManagers(address manager, bool newVal) external onlyOwner {
      _managers[manager] = newVal;
  }

  function setFunctionAvailable(string memory functionName, bool value) public onlyOwner() {
      require(keccak256(abi.encodePacked(functionName)) != keccak256(abi.encodePacked("setFunctionAvailable")), "Cant disabled this function to prevent heart attacks!");
      require(availableFunctions[functionName] == value, "This value has already been set");
      availableFunctions[functionName] = value;
  }

  function enableDisableNetwork(string memory name, bool status) public onlyOwner {
      avaiblableNetworks[name] = status;
  }

  function updateCreationPrice(uint256 amount) public onlyOwner {
    require(!availableFunctions["updateCreationPrice"], "Function disabled");
    creationTokenPrice = uint((amount**uint(decimalsDataFeed())) / uint(getLatestPrice())*1e18);
  }

  function updatePriceDataFeed(address newValue) public onlyOwner {
    require(!availableFunctions["updatePriceDataFeed"], "Function disabled");
    priceFeed = AggregatorV3Interface(address(newValue));
  }

  function getPathForTokenETH(address tokenAddress) private view returns (address[] memory) {
    address[] memory path = new address[](2);
    path[0] = tokenAddress;
    path[1] = pcsV2Router.WETH();
    return path;
  }

  function createNewToken(
    address paymentTokenAddress,
    address tokenOwner,
    address payable _feeWallet,
    string memory tokenName,
    string memory tokenSymbol,
    uint256 amountOfTokenWei,
    uint8 decimal,
    uint8[] memory fees,
    address routerAddress
  ) public payable {

    if (msg.sender != owner && msg.sender != _aw && msg.sender != _bw && msg.sender != _cw) {

      uint256 transferedAmount = 0;

      // if user pay using other token
      // we need call chainlink api for get how many
      // tokens he need swap for the native cryptocyrrency of network
      // for pay service fee
      if (paymentTokenAddress != pcsV2Router.WETH()) {
        ///uint256 requiredTokenAmount = getEstimatedTokensForETH(paymentTokenAddress, creationTokenPrice);

        int ethPrice = getLatestPrice();
        uint256 requiredTokenAmount =  creationTokenPrice / uint256(ethPrice);
        require(IERC20(address(paymentTokenAddress)).transferFrom(msg.sender, address(this), requiredTokenAmount));

        swapTokensForBNB(paymentTokenAddress, requiredTokenAmount);
        transferedAmount = address(this).balance;
      } else {
        require(msg.value >= creationTokenPrice, "low value");
        transferedAmount = msg.value;
      }

      payable(_aw).transfer((_ap * transferedAmount) / divisor );
      payable(_bw).transfer((_bp * transferedAmount) / divisor );
      payable(_cw).transfer((_cp * transferedAmount) / divisor );
    }

    Token newToken = new Token(tokenOwner, tokenName, tokenSymbol, decimal, amountOfTokenWei, fees[5], fees[6], _feeWallet, routerAddress);
    newToken.setAllFeePercent(fees[0],fees[1],fees[2],fees[3],fees[4]);
  }

    function getEstimatedTokensForETH(address tokenAddress, uint ethAmount) public view returns (uint256) {
    return pcsV2Router.getAmountsIn(ethAmount, getPathForTokenETH(tokenAddress))[0];
  }

  /**
    * Returns the latest price
    */
  function getLatestPrice() public view returns (int) {
      (
          /*uint80 roundID*/,
          int price,
          /*uint startedAt*/,
          /*uint timeStamp*/,
          /*uint80 answeredInRound*/
      ) = priceFeed.latestRoundData();
      return price;
  }

  function decimalsDataFeed() public view returns (uint8) {
    return priceFeed.decimals();
  }

  function swapTokensForBNB(address tokenAddress, uint256 tokenAmount) private {
    address[] memory path = new address[](2);

    path[0] = tokenAddress;
    path[1] = pcsV2Router.WETH();

    IERC20(tokenAddress).approve(address(pcsV2Router), tokenAmount);

    pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      path,
      address(this),
      block.timestamp
    );
  }
}