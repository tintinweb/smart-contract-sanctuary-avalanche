// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./AggregatorV3Interface.sol";
import "./Token.sol";

contract MidasTokenGenerator {
  uint256 public creationPrice = 50000000000000000000; // 50$
  address private aggregatorAddress;
  mapping (string => bool) private avaiblableNetworks;
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
    _bw = addresses[3];
    _cw = addresses[4];
    _dw = addresses[5];

    avaiblableNetworks["bsc"] = true;
    avaiblableNetworks["polygon"] = true;
    avaiblableNetworks["avalanche"] = true;
    owner = msg.sender;
  }

  fallback() external payable {}
  receive() external payable {}

  modifier onlyOwner() {
      require(owner == msg.sender, "onlyOwner");
      _;
  }

  modifier onlyManager() {
    require(_managers[msg.sender] == true, "onlyManager");
    _;
  }

  function updateManagers(address manager, bool newVal) external onlyOwner {
      _managers[manager] = newVal;
  }

  function enableDisableNetwork(string memory name, bool status) public onlyOwner {
      avaiblableNetworks[name] = status;
  }

  function updateCreationPrice(uint256 amount) public onlyOwner {
    creationPrice = uint((amount**uint(priceFeed.decimals())) / uint(getLatestPrice())*1e18);
  }

  function updateCreationPriceV2(uint256 amount) public onlyOwner {
    creationPrice = amount;
  }
  
  function updatePriceDataFeed(address newValue) public onlyOwner {
    priceFeed = AggregatorV3Interface(address(newValue));
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

    if (!_managers[msg.sender]) {

      uint256 transferedAmount = 0;

      // if user pay using other token
      // we need call chainlink api for get how many
      // tokens he need swap for the native cryptocyrrency of network
      // for pay service fee
      if (paymentTokenAddress != pcsV2Router.WETH()) {
        ///uint256 requiredTokenAmount = getEstimatedTokensForETH(paymentTokenAddress, creationTokenPrice);

        // get required token amount for pay service
        uint256 requiredTokenAmount =  getMinimunTokenAmout(paymentTokenAddress);

        // transfer from customer to contract
        require(IERC20(address(paymentTokenAddress)).transferFrom(msg.sender, address(this), requiredTokenAmount));

        // swap to native cryprocurrency | BNB, AVAX, MATIC, ETH ....
        swap(paymentTokenAddress, requiredTokenAmount);
        transferedAmount = address(this).balance;
      } else {
        require(msg.value >= getRequiredEthAmount(), "low value");
        transferedAmount = msg.value;
      }

      // 
      payable(_aw).transfer((_ap * transferedAmount) / divisor );
      payable(_bw).transfer((_bp * transferedAmount) / divisor );
      payable(_cw).transfer((_cp * transferedAmount) / divisor );
      payable(_dw).transfer((_dp * transferedAmount) / divisor );
    }

    Token newToken = new Token(tokenOwner, tokenName, tokenSymbol, decimal, amountOfTokenWei, fees[5], fees[6], _feeWallet, routerAddress);
    newToken.setAllFeePercent(fees[0],fees[1],fees[2],fees[3],fees[4]);
  }

  function getRequiredEthAmount() public view returns (uint256) {
      return creationPrice / uint256(getLatestPrice());
  }

  function getMinimunTokenAmout(address tokenAddress) public view returns (uint256) {
    // creationTokenPrice = X
    // ethPrice = Y
    // requiredEthAmount = X / Y
    //uint256 f = getEstimatedTokensForETH(tokenAddress, 1000000000000000000);
    return estimatedTokensForTokens(tokenAddress, pcsV2Router.WETH(), getRequiredEthAmount());
  }

  // return amount of tokenA needed to buy 1 tokenB
  function estimatedTokensForTokens(address add1, address add2, uint amount) public view returns (uint256) {
      return pcsV2Router.getAmountsOut(amount, pathTokensForTokens(add1, add2))[1];
  }

  // return the route given the busd addresses and the token
  function pathTokensForTokens(address add1, address add2) private pure returns (address[] memory) {
      address[] memory path = new address[](2);
      path[0] = add1;
      path[1] = add2;
      return path;
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

  function swap(address tokenAddress, uint256 tokenAmount) private {
    
    IERC20(tokenAddress).approve(address(pcsV2Router), tokenAmount);
    pcsV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
      tokenAmount,
      0, // accept any amount of ETH
      pathTokensForTokens(tokenAddress, pcsV2Router.WETH()),
      address(this),
      block.timestamp
    );
  }
}