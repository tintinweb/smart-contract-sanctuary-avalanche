/**
 *Submitted for verification at snowtrace.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
   
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

   
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

   
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

   
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

   
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

  
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

  
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

 
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

   
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

  
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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function decimals() external returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ReentrancyGuard {
   
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }
}

interface tokenVesting {
    function vest(
        address _to,
        uint256 _value
    ) external;

    function startTheVesting(uint256) external;
}

contract CarbonCrowdsale is Ownable , ReentrancyGuard {

    using SafeMath for uint256;

    tokenVesting public vestcont;

    IERC20 public Carbon12;
    uint256 Tokendecimals;

    bool public paused;
    uint256 public _raised;

    address public treasury;
    address public vesting;

    IERC20 WBTC;
    IERC20 WETH;
    IERC20 USDC;
    IERC20 USDT;

    AggregatorV3Interface internal AvaxFeed;
    AggregatorV3Interface internal BtcFeed;
    AggregatorV3Interface internal EthFeed;
    AggregatorV3Interface internal UsdtFeed;
    AggregatorV3Interface internal UsdcFeed;
    
    constructor() {

        Carbon12 = IERC20(0xe7198115BDa1AdC31d79088A77cB476D8AD0a766);

        Tokendecimals = 18;
        paused = true;

        treasury = address(0x3d5cD1A843dECC34bba1e57919A4D52690d845A4);  //Presale Funds Receiver
        
        AvaxFeed = AggregatorV3Interface(0x0A77230d17318075983913bC2145DB16C7366156);
        BtcFeed = AggregatorV3Interface(0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743);
        EthFeed = AggregatorV3Interface(0x976B3D034E162d8bD72D6b9C989d545b839003b0);
        UsdtFeed = AggregatorV3Interface(0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a);
        UsdcFeed = AggregatorV3Interface(0xF096872672F44d6EBA71458D74fe67F9a77a23B9);

        WBTC = IERC20(0x408D4cD0ADb7ceBd1F1A1C33A0Ba2098E1295bAB);
        WETH = IERC20(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB);
        USDC = IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E);
        USDT = IERC20(0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7);

    }

    //1. Avax, 
    function BuyTokenNative() public nonReentrant payable {
        address beneficiary = msg.sender;
        uint256 _amount = msg.value;
        _preValidatePurchase(beneficiary,_amount);
        uint tokenAmount = _getTokenAmount(_amount,1,18);
          
        _raised += tokenAmount.div(28);

        Carbon12.transfer(address(vestcont),tokenAmount);
        vestcont.vest(beneficiary, tokenAmount);

        (bool os,) = payable(treasury).call{value: _amount}("");
        require(os,"Transaction Failed");
    }

    //2. Btc, 3. ETH, 4. Usdt, 5.Usdc
    function BuyToken(uint _pid, uint _amount) public nonReentrant {
        address beneficiary = msg.sender;
        uint decimal;
        uint tokenAmount;
        _preValidatePurchase(beneficiary,_amount);
        if(_pid == 2) {
            decimal = WBTC.decimals();
            tokenAmount = _getTokenAmount(_amount,_pid,decimal);
            WBTC.transferFrom(beneficiary,treasury, _amount);
        }
        else if (_pid == 3) {
            decimal = WETH.decimals();
            tokenAmount = _getTokenAmount(_amount,_pid,decimal);
            WETH.transferFrom(beneficiary,treasury, _amount);
        }
        else if (_pid == 4) {
            decimal = USDT.decimals();
            tokenAmount = _getTokenAmount(_amount,_pid,decimal);
            USDT.transferFrom(beneficiary,treasury, _amount);
        }
        else if (_pid == 5) {
            decimal = USDC.decimals();
            tokenAmount = _getTokenAmount(_amount,_pid,decimal);
            USDC.transferFrom(beneficiary,treasury, _amount);
        }
        else {
            revert("Wrong ID Selected!!");
        }
        _raised += tokenAmount.div(28);
           
        Carbon12.transfer(address(vestcont),tokenAmount);
        vestcont.vest(beneficiary, tokenAmount);
    }

    function _getTokenAmount(uint256 weiAmount,uint _pid,uint _cDecimal) public view returns (uint256) {
        uint256 CurrencyDecimal = 10 ** _cDecimal;
        uint256 usd = uint256(getLatestPrice(_pid));
        usd = usd.mul(28).div(10 ** 8);  
        uint256 oneCent = CurrencyDecimal.div(usd);
        return (weiAmount.mul(10 ** Tokendecimals).div(oneCent));
    }

    //@Param to get live price,
    //1. Avax, 2. Btc, 3. ETH, 4. Usdt, 5.Usdc
    function getLatestPrice(uint _pid) public view returns (int) {
        int price;
        if(_pid == 1) (,price,,,) = AvaxFeed.latestRoundData();   
        if(_pid == 2) (,price,,,) = BtcFeed.latestRoundData();   
        if(_pid == 3) (,price,,,) = EthFeed.latestRoundData();   
        if(_pid == 4) (,price,,,) = UsdtFeed.latestRoundData();  
        if(_pid == 5) (,price,,,) = UsdcFeed.latestRoundData(); 
        return price;
    }

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(!paused,"Crowdsale: Paused!!");
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
    }

    function setPauser(bool _status) public onlyOwner {
        require(paused != _status,"Status Not Changed!!");
        paused = _status;
    }

    function getAvailableBalance() public view returns (uint) {
        return Carbon12.balanceOf(address(this));
    }

    function setVestingCont(address _adr) public onlyOwner {
        vestcont = tokenVesting(_adr);
    }

    function rescueFunds() public onlyOwner {
        (bool os,) = payable(owner()).call{value: address(this).balance}("");
        require(os,"Transaction Failed");
    }

    function rescueTokens(IERC20 _token, uint _amount) public onlyOwner {
        _token.transfer(owner(), _amount);
    }

    function setTreasuryWallet(address _adr) public onlyOwner {
        treasury = _adr;
    }

}