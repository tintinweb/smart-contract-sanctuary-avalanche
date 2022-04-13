// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Uniswap/IUniswapV2Factory.sol";
import "./Uniswap/IUniswapV2Pair.sol";
import "./Uniswap/IJoeRouter02.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./common/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
//import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./common/IBoostNFT.sol";
import "./NODERewardManagement.sol";

struct Tier {
  uint8 id;
  string name;
  uint256 price;
  uint256 rewardsPerTime;
  uint32 claimInterval;
  uint256 maintenanceFee;
}

struct Node {
  uint32 id;
  uint8 tierIndex;
  address owner;
  uint32 createdTime;
  uint32 claimedTime;
  uint32 limitedTime;
  uint256 multiplier;
  uint256 leftover;
}

contract NodeManagerV1 is Initializable {
  using SafeMath for uint256;
  address public tokenAddress;
  address public nftAddress;
  address public rewardsPoolAddress;
  address public operationsPoolAddress;

  Tier[] private tierArr;
  mapping(string => uint8) public tierMap;
  uint8 public tierTotal;
  //change to private
  Node[] public nodesTotal;
  //change to private
  mapping(address => uint256[]) public nodesOfUser;
  uint32 public countTotal;
  mapping(address => uint32) public countOfUser;
  mapping(string => uint32) public countOfTier;
  uint256 public rewardsTotal;
  //sumatory of user claimed rewards
  mapping(address => uint256) public rewardsOfUser;
  mapping(address => bool) public _isBlacklisted;
  mapping(address => bool) public userMigrated;

  uint32 public discountPer10; // 0.1%
  uint32 public withdrawRate; // 0.00%
  uint32 public transferFee; // 0%
  uint32 public rewardsPoolFee; // 70%
  uint32 public claimFee; // 10%
  uint32 public operationsPoolFee; // 70%
  uint32 public maxCountOfUser; // 0-Infinite
  uint32 public payInterval; // 1 Month

  uint32 public sellPricePercent;


  IJoeRouter02 public uniswapV2Router;
  IBoostNFT public boostNFT;
  NODERewardManagement public oldNodeManager;

  address public owner;
  
  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  event NodeCreated(address, string, uint32, uint32, uint32, uint32);
  event NodeUpdated(address, string, string, uint32);
  event NodeTransfered(address, address, uint32);

  function initialize(address[] memory addresses) public initializer {
    tokenAddress = addresses[0];
    rewardsPoolAddress = addresses[1];
    operationsPoolAddress = addresses[2];
    owner = msg.sender;

    addTier("basic", 10 ether, 1 ether, 30, 0.001 ether);
    addTier("light", 50 ether, 0.80 ether, 1 days, 0.0005 ether);
    addTier("pro", 100 ether, 2 ether, 1 days, 0.0001 ether);

    discountPer10 = 10; // 0.1%
    withdrawRate = 0; // 0.00%
    transferFee = 0; // 0%
    rewardsPoolFee = 8000; // 80%
    operationsPoolFee = 2000; // 20%
    claimFee = 1000;
    maxCountOfUser = 100; // 0-Infinite
    sellPricePercent = 25; // 25%
    payInterval = 30 days; // todo in mainnet 30 days
    oldNodeManager = NODERewardManagement(0xbC545AfBEf1829e20eBcb4B11ECa2d8f7c811B33);
    //bindBoostNFT(addresses[3]);
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(
        newOwner != address(0),
        "Ownable: new owner is the zero address"
    );
    owner = newOwner;
  }

  function setNFTAddress(address _nftAddress) public onlyOwner {
    nftAddress = _nftAddress;
  }

  function bindBoostNFT(address _nftAddress) public onlyOwner {
    boostNFT = IBoostNFT(_nftAddress);
  }

  function setsellPricePercent(uint32 value) public onlyOwner {
    sellPricePercent = value;
  }

  function setPayInterval(uint32 value) public onlyOwner {
    payInterval = value;
  }

  function setClaimFee(uint32 value) public onlyOwner {
    claimFee = value;
  }

  function setRewardsPoolFee(uint32 value) public onlyOwner {
    rewardsPoolFee = value;
  }

  function setRewardsPoolAddress(address account) public onlyOwner {
    rewardsPoolAddress = account;
  }

  function setOperationsPoolFee(uint32 value) public onlyOwner {
    operationsPoolFee = value;
  }

  function setOperationsPoolAddress(address account) public onlyOwner {
    operationsPoolAddress = account;
  }
  
  function setRouter(address router) public onlyOwner {
    uniswapV2Router = IJoeRouter02(router);
  }

  function setDiscountPer10(uint32 value) public onlyOwner {
    discountPer10 = value;
  }
  
  function setTransferFee(uint32 value) public onlyOwner {
    transferFee = value;
  }

  function setAddressInBlacklist(address walletAddress, bool value) public onlyOwner() {
    _isBlacklisted[walletAddress] = value;
  }

  function setTokenAddress(address token) public onlyOwner {
    tokenAddress = token;
  }

  function getTierByName(string memory tierName) public view returns (Tier memory) {
    Tier memory tierSearched;
    for (uint8 i = 0; i < tierArr.length; i++) {
      Tier storage tier = tierArr[i];
      if (keccak256(abi.encodePacked(tier.name)) == keccak256(abi.encodePacked(tierName))) tierSearched = tier;
    }
    return tierSearched;
  }

  function addTier(
    string memory name,
    uint256 price,
    uint256 rewardsPerTime,
    uint32 claimInterval,
    uint256 maintenanceFee
  ) public onlyOwner {
    require(price > 0, "Tier's price has to be positive");
    require(rewardsPerTime > 0, "Tier's rewards has to be positive");
    require(claimInterval > 0, "Tier's claim interval has to be positive");
    tierArr.push(
      Tier({
	      id: uint8(tierArr.length),
        name: name,
        price: price,
        rewardsPerTime: rewardsPerTime,
        claimInterval: claimInterval,
        maintenanceFee: maintenanceFee
      })
    );
    tierMap[name] = uint8(tierArr.length);
    tierTotal++;
  }

  function updateTier(
    string memory tierName,
    string memory name,
    uint256 price,
    uint256 rewardsPerTime,
    uint32 claimInterval,
    uint256 maintenanceFee
  ) public onlyOwner {
    uint8 tierId = tierMap[tierName];
    require(tierId > 0, "Tier's name is incorrect");
    require(price > 0, "Tier's price has to be positive");
    require(rewardsPerTime > 0, "Tier's rewards has to be positive");
    Tier storage tier = tierArr[tierId - 1];
    tier.name = name;
    tier.price = price;
    tier.rewardsPerTime = rewardsPerTime;
    tier.claimInterval = claimInterval;
    tier.maintenanceFee = maintenanceFee;
    tierMap[name] = tierId;
    tierMap[tierName] = 0;
  }

  function removeTier(string memory tierName) public onlyOwner {
    require(tierMap[tierName] > 0, "Tier was already removed");
    tierMap[tierName] = 0;
    tierTotal--;
  }

  function nodes(address account) public view returns (Node[] memory) {
    Node[] memory nodesActive = new Node[](countOfUser[account]);
    uint256[] storage nodeIndice = nodesOfUser[account];
    uint32 j = 0;
    for (uint32 i = 0; i < nodeIndice.length; i++) {
      uint256 nodeIndex = nodeIndice[i];
      if (nodeIndex > 0) {
        Node storage node = nodesTotal[nodeIndex - 1];
        if (node.owner == account) {
          nodesActive[j] = node;
          nodesActive[j++].multiplier = getBoostRate(account, node.claimedTime, block.timestamp);          
        }
      }
    }
    return nodesActive;
  }

  function _create(
    address account,
    string memory tierName,
    uint32 count
  ) private returns (uint256) {
    require(!_isBlacklisted[msg.sender],"Blacklisted");
    require(msg.sender==owner || (countOfUser[account] + count) <= maxCountOfUser, "Cannot create more nodes");
    uint8 tierId = tierMap[tierName];
    Tier storage tier = tierArr[tierId - 1];
    for (uint32 i = 0; i < count; i++) {
      nodesTotal.push(
        Node({
          id: uint32(nodesTotal.length),
          tierIndex: tierId - 1,
          owner: account,
          multiplier: 0,
          createdTime: uint32(block.timestamp),
          claimedTime: uint32(block.timestamp),
          limitedTime: uint32(block.timestamp) + payInterval,
          leftover: 0
        })
      );
      uint256[] storage nodeIndice = nodesOfUser[account];
      nodeIndice.push(nodesTotal.length);
    }
    countOfUser[account] += count;
    countOfTier[tierName] += count;
    countTotal += count;
    uint256 amount = tier.price *count;
    if (count >= 10) amount = (amount * (10000 - discountPer10)) / 10000;
    return amount;
  }

  function _transferFee(uint256 amount) private {
    require(amount != 0,"Transfer token amount can't zero!");
    require(rewardsPoolAddress != address(0),"Rewards pool can't Zero!");

    IERC20Upgradeable(tokenAddress).transferFrom(address(msg.sender), address(rewardsPoolAddress), (amount * rewardsPoolFee) / 10000);
    IERC20Upgradeable(tokenAddress).transferFrom(address(msg.sender), address(operationsPoolAddress), (amount * operationsPoolFee) / 10000);
  }

  function mint(
    address[] memory accounts,
    string memory tierName,
    uint32 count
  ) public onlyOwner {
    require(accounts.length>0, "Empty account list");
    for(uint256 i = 0;i<accounts.length;i++) {
      _create(accounts[i], tierName, count);
    }
  }

  function create(
    string memory tierName,
    uint32 count
  ) public {
    uint256 amount = _create(msg.sender, tierName, count);
    _transferFee(amount);
    emit NodeCreated(
      msg.sender,
      tierName,
      count,
      countTotal,
      countOfUser[msg.sender],
      countOfTier[tierName]
    );
  }

  function getBoostRate(address account, uint256 timeFrom, uint256 timeTo) public view returns (uint256) {
    uint256 multiplier = 1 ether;
    if(nftAddress == address(0)){
      return multiplier;
    }
    IBoostNFT nft = IBoostNFT(nftAddress);
    multiplier = nft.getMultiplier(account, timeFrom, timeTo);
    
    return multiplier;
  }

  function claimable() public view returns (uint256) {
    uint256 amount = 0;
    uint256[] storage nodeIndice = nodesOfUser[msg.sender];
    
    for (uint32 i = 0; i < nodeIndice.length; i++) {
      uint256 nodeIndex = nodeIndice[i];
      if (nodeIndex > 0) {
        Node storage node = nodesTotal[nodeIndex - 1];
        if (node.owner == msg.sender) {
          uint256 multiplier = getBoostRate(msg.sender, node.claimedTime, block.timestamp);
          Tier storage tier = tierArr[node.tierIndex];
          amount += ((((uint256(block.timestamp - node.claimedTime) * tier.rewardsPerTime) * multiplier) / 1 ether) / tier.claimInterval);
        }
      }
    }
    return amount;
  }

  function _claim(uint256 exceptAmount) private {
    // check if user is blacklisted
    require(!_isBlacklisted[msg.sender],"Blacklisted");
    //unpaidNodes();

    // get all nodes from user
    uint256[] storage nodeIndice = nodesOfUser[msg.sender];

    uint256 claimableAmount = 0;
    // loop node list
    for (uint32 i = 0; i < nodeIndice.length; i++) {
      // get current node index on list
      uint256 nodeIndex = nodeIndice[i];

      // check if we have valid index
      if (nodeIndex > 0) {
        // get node at this index
        Node storage node = nodesTotal[nodeIndex - 1];

        // if msg sender are this node owner
        // and he pay mantainces fees checking limitedTime from node
        if (node.owner == msg.sender && (node.limitedTime + payInterval) > uint32(block.timestamp)) {

          // get nft multiplier
          uint256 multiplier = getBoostRate(msg.sender, node.claimedTime, block.timestamp);
            
          // get tier from this node
          Tier storage tier = tierArr[node.tierIndex];
          // calc claimable amount
          claimableAmount += ((((uint256(block.timestamp - node.claimedTime) * tier.rewardsPerTime) * multiplier) / 1 ether) / tier.claimInterval) + node.leftover;
          // update last claimed date from this node
          node.claimedTime = uint32(block.timestamp);

          // if claimableAmount is more than compountAmount return leftover to the node
          if (exceptAmount > 0 && claimableAmount > exceptAmount) {
            node.leftover = claimableAmount - exceptAmount;
            i = uint32(nodeIndice.length);
          }
        }
      }
    }

   // claimable amount should be greater than zero
   require(claimableAmount > 0, "No claimable tokens");

   // if is compounding we create node, dont charge fee and keep remaining amount in rewards
    if (exceptAmount > 0) {
      require(claimableAmount >= exceptAmount, "Insufficient claimable tokens to compound");
    } else {
      // update user claimed amount
      rewardsOfUser[msg.sender] += claimableAmount;
      // update total rewards 
      rewardsTotal += claimableAmount;
      //uint256 claimedAmount = claimableAmount - exceptAmount;
      // if have claim fee
      if (claimFee > 0) {
        // calc claim fee amunt and send to operation pool
        uint256 feeAmount = (claimableAmount * claimFee) / 10000;
        claimableAmount = claimableAmount - feeAmount;
        IERC20(tokenAddress).transferFrom(address(rewardsPoolAddress), address(operationsPoolAddress), feeAmount);
      } 

      // send claimed amout
      IERC20(tokenAddress).transferFrom(address(rewardsPoolAddress), address(msg.sender), claimableAmount);
    }
  }

  function compound(
    string memory tierName,
    uint32 count
  ) public {
    uint256 amount = _create(msg.sender, tierName, count);
    _claim(amount);
    emit NodeCreated(
      msg.sender,
      tierName,
      count,
      countTotal,
      countOfUser[msg.sender],
      countOfTier[tierName]
    );
  }

  function claim() public {
    _claim(0);
  }

  function upgrade(
    string memory tierNameFrom,
    string memory tierNameTo,
    uint32 count
  ) public {
    unpaidNodes();
    uint8 tierIndexFrom = tierMap[tierNameFrom];
    uint8 tierIndexTo = tierMap[tierNameTo];
    require(tierIndexFrom > 0, "Invalid tier to upgrade from");
    require(!_isBlacklisted[msg.sender],"Blacklisted");
    Tier storage tierFrom = tierArr[tierIndexFrom - 1];
    Tier storage tierTo = tierArr[tierIndexTo - 1];
    require(tierTo.price > tierFrom.price, "Unable to downgrade");
    uint256[] storage nodeIndice = nodesOfUser[msg.sender];
    uint32 countUpgrade = 0;
    uint256 claimableAmount = 0;
    for (uint32 i = 0; i < nodeIndice.length; i++) {
      uint256 nodeIndex = nodeIndice[i];
      if (nodeIndex > 0) {
        Node storage node = nodesTotal[nodeIndex - 1];
        if (node.owner == msg.sender && tierIndexFrom - 1 == node.tierIndex) {
          node.tierIndex = tierIndexTo - 1;
          uint256 multiplier = getBoostRate(msg.sender, node.claimedTime, block.timestamp);
          uint256 claimed = ((uint256(block.timestamp - node.claimedTime) * tierFrom.rewardsPerTime) / tierFrom.claimInterval);
          claimableAmount += (claimed * multiplier) / (10**18);
          node.claimedTime = uint32(block.timestamp);
          countUpgrade++;
          if (countUpgrade == count) break;
        }
      }
    }
    require(countUpgrade == count, "Not enough nodes");
    countOfTier[tierNameFrom] -= count;
    countOfTier[tierNameTo] += count;
    if (claimableAmount > 0) {
      rewardsOfUser[msg.sender] += claimableAmount;
      rewardsTotal += claimableAmount;
      IERC20Upgradeable(tokenAddress).transferFrom(address(rewardsPoolAddress),address(msg.sender), claimableAmount);
    }
    uint256 price = (tierTo.price - tierFrom.price) * count;
    if (count >= 10) price = (price * (10000 - discountPer10)) / 10000;
    _transferFee(price);
    emit NodeUpdated(msg.sender, tierNameFrom, tierNameTo, count);
  }

  function transfer(
    string memory tierName,
    uint32 count,
    address from,
    address to
  ) public onlyOwner {
    require(!_isBlacklisted[from],"Blacklisted origin");
    require(!_isBlacklisted[to],"Blacklisted recipient");
    require(!_isBlacklisted[to],"Blacklisted recipient");
    uint8 tierIndex = tierMap[tierName];
    require((countOfUser[to] + count) <= maxCountOfUser, "Cannot create more nodes");
    unpaidNodes();
    Tier storage tier = tierArr[tierIndex - 1];
    uint256[] storage nodeIndiceFrom = nodesOfUser[from];
    uint256[] storage nodeIndiceTo = nodesOfUser[to];
    uint32 countTransfer = 0;
    uint256 claimableAmount = 0;
    for (uint32 i = 0; i < nodeIndiceFrom.length; i++) {
      uint256 nodeIndex = nodeIndiceFrom[i];
      if (nodeIndex > 0) {
        Node storage node = nodesTotal[nodeIndex - 1];
        if (node.owner == from && tierIndex - 1 == node.tierIndex) {
          node.owner = to;
          uint256 multiplier = getBoostRate(from, node.claimedTime, block.timestamp);
          uint256 claimed = ((uint256(block.timestamp - node.claimedTime) * tier.rewardsPerTime) / tier.claimInterval);
          claimableAmount += (claimed * multiplier) / (10**18);
          node.claimedTime = uint32(block.timestamp);
          countTransfer++;
          nodeIndiceTo.push(nodeIndex);
          nodeIndiceFrom[i] = 0;
          if (countTransfer == count) break;
        }
      }
    }
    require(countTransfer == count, "Not enough nodes");
    countOfUser[from] -= count;
    countOfUser[to] += count;
    if (claimableAmount > 0) {
      rewardsOfUser[from] += claimableAmount;
      rewardsTotal += claimableAmount;
      IERC20Upgradeable(tokenAddress).transferFrom(address(rewardsPoolAddress), address(from), claimableAmount);
    }
    emit NodeTransfered(from, to, count);
  }

  function burnUser(address account) public onlyOwner {
    uint256[] storage nodeIndice = nodesOfUser[account];
    for (uint32 i = 0; i < nodeIndice.length; i++) {
      uint256 nodeIndex = nodeIndice[i];
      if (nodeIndex > 0) {
        Node storage node = nodesTotal[nodeIndex - 1];
        if (node.owner == account) {
          node.owner = address(0);
          node.claimedTime = uint32(0);
          Tier storage tier = tierArr[node.tierIndex];
          countOfTier[tier.name]--;
        }
      }
    }
    nodesOfUser[account] = new uint256[](0);
    countTotal -= countOfUser[account];
    countOfUser[account] = 0;
  }

  function burnNodes(uint32[] memory indice) public onlyOwner {
    uint32 count = 0;
    for (uint32 i = 0; i < indice.length; i++) {
      uint256 nodeIndex = indice[i];
      if (nodeIndex > 0) {
        Node storage node = nodesTotal[nodeIndex - 1];
        if (node.owner != address(0)) {
          uint256[] storage nodeIndice = nodesOfUser[node.owner];
          for (uint32 j = 0; j < nodeIndice.length; j++) {
            if (nodeIndex == nodeIndice[j]) {
              nodeIndice[j] = 0;
              break;
            }
          }
          countOfUser[node.owner]--;
          node.owner = address(0);
          node.claimedTime = uint32(0);
          Tier storage tier = tierArr[node.tierIndex];
          countOfTier[tier.name]--;
          count++;
        }
        // return a percentage of price to the owner
      }
    }
    countTotal -= count;
  }

  function sellNode(uint32 indice) public {
    require(!_isBlacklisted[msg.sender],"Blacklisted");
    unpaidNodes();
    Node storage node = nodesTotal[indice - 1];
    if (node.owner != address(0)) {
      uint256[] storage nodeIndice = nodesOfUser[node.owner];
      for (uint32 j = 0; j < nodeIndice.length; j++) {
        if (indice == nodeIndice[j]) {
          nodeIndice[j] = 0;
          break;
        }
      }
      countOfUser[node.owner]--;
      node.owner = address(0);
      node.claimedTime = uint32(0);
      Tier storage tier = tierArr[node.tierIndex];
      countOfTier[tier.name]--;
      countTotal--;
      IERC20Upgradeable(tokenAddress).transferFrom(address(rewardsPoolAddress), address(node.owner), (tier.price / 100) * sellPricePercent);
    }
  }

  function withdraw(address anyToken, address recipient) external onlyOwner() {
    IERC20Upgradeable(anyToken).transfer(recipient, IERC20Upgradeable(anyToken).balanceOf(address(this)));
  }

  function pay(uint8 count, uint256[] memory selected) public payable {
    require(count > 0 && count <= 12, "Invalid number of months");
    uint256 fee = 0;
    for (uint32 i = 0; i < selected.length; i++) {
      uint256 nodeIndex = selected[i];
      Node storage node = nodesTotal[nodeIndex];
      if (node.owner == msg.sender) {
        Tier storage tier = tierArr[node.tierIndex];
        node.limitedTime += count * uint32(payInterval);
        fee += (tier.maintenanceFee * count);
      }
    }
    require(fee == msg.value,"Invalid Fee amount");
    payable(address(operationsPoolAddress)).transfer(fee);
  }

  function checkNodes(address ownerAddress) public view returns (Node[] memory) {
    uint32 count = 0;
    for (uint32 i = 0; i < nodesTotal.length; i++) {
      Node storage node = nodesTotal[i];
      if (node.owner != address(0) && node.owner == ownerAddress && node.limitedTime < uint32(block.timestamp)) {
        count++;
      }
    }
    Node[] memory nodesToPay = new Node[](count);
    uint32 j = 0;
    for (uint32 i = 0; i < nodesTotal.length; i++) {
      Node storage node = nodesTotal[i];
      if (node.owner != address(0) && node.owner == ownerAddress && node.limitedTime < uint32(block.timestamp)) {
        nodesToPay[j++] = node;
      }
    }
    return nodesToPay;
  }

  function unpaidNodes() public {
    for (uint32 i = 0; i < nodesTotal.length; i++) {
      Node storage node = nodesTotal[i];
      if (node.owner != address(0) && (node.limitedTime + payInterval) < uint32(block.timestamp)) {
        countOfUser[node.owner]--;
        node.owner = address(0);
        node.claimedTime = uint32(0);
        Tier storage tier = tierArr[node.tierIndex];
        countOfTier[tier.name]--;
        countTotal--;
      }
    }
  }

  function migrateFromOldVersion() public {
    require(userMigrated[msg.sender], "Wallet have been migrated");
    uint32 nodeNumber = uint32(oldNodeManager._getNodeNumberOf(msg.sender));
    if (nodeNumber != 0 && !userMigrated[msg.sender]) {
      userMigrated[msg.sender] = true;
      _create(msg.sender,"basic",nodeNumber);
    }
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
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
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
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

pragma solidity ^0.8.13;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
interface IBoostNFT is IERC1155 {
    function getMultiplier(address account, uint256 timeFrom, uint256 timeTo ) external view returns (uint256);
    function getLastMultiplier(address account, uint256 timeTo) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./common/SafeMath.sol";
import "./common/IterableMapping.sol";

contract NODERewardManagement {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    modifier onlyManager() {
        require(_managers[msg.sender] == true, "Only managers can call this function");
        _;
    }

    struct NodeEntity {
        uint256 nodeId;
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardNotClaimed;
    }

    IterableMapping.Map private nodeOwners;
    mapping(address => NodeEntity[]) private _nodesOfUser;
    mapping(address => bool) public _managers;

    uint256 public nodePrice = 0; // 10
    uint256 public rewardsPerMinute = 0; // 1
    uint256 public claimInterval = 0; // 5 min

    uint256 public lastIndexProcessed = 0;
    uint256 public totalNodesCreated = 0;
    uint256 public totalRewardStaked = 0;

    bool public createSingleNodeEnabled = false;
    bool public createMultiNodeEnabled = false;
    bool public cashoutEnabled = false;

    uint256 public gasForDistribution = 30000;

    event NodeCreated(address indexed from, uint256 nodeId, uint256 index, uint256 totalNodesCreated);

    constructor(
    ) {
        _managers[msg.sender] = true;
    }

    function updateManagers(address manager, bool newVal) external onlyManager {
        require(manager != address(0),"new manager is the zero address");
        _managers[manager] = newVal;
    }

    // string memory nodeName, uint256 expireTime ignored, just for match with old contract
    function createNode(address account, string memory nodeName, uint256 expireTime) external onlyManager {

        require(createSingleNodeEnabled,"createSingleNodeEnabled disabled");

        _nodesOfUser[account].push(
            NodeEntity({
        nodeId : totalNodesCreated + 1,
        creationTime : block.timestamp,
        lastClaimTime : block.timestamp,
        rewardNotClaimed : 0
        })
        );

        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;
        emit NodeCreated(account, totalNodesCreated, _nodesOfUser[account].length, totalNodesCreated);
    }

    function createNodesWithRewardsAndClaimDates(address account, uint256 numberOfNodes, uint256[] memory rewards, uint256[] memory claimsTimes) external onlyManager {

        require(createMultiNodeEnabled,"createcreateMultiNodeEnabledSingleNodeEnabled disabled");
        require(numberOfNodes > 0,"createNodes numberOfNodes cant be zero");
        require(rewards.length > 0 ? rewards.length == numberOfNodes: true,"rewards length not equal numberOfNodes");
        require(claimsTimes.length > 0 ? claimsTimes.length == numberOfNodes: true,"claimsTimes length not equal numberOfNodes");
        require(rewards.length > 0 && claimsTimes.length > 0 ? rewards.length == numberOfNodes && claimsTimes.length == numberOfNodes: true,"rewards and claimsTimes length not equal numberOfNodes");

        for (uint256 i = 0; i < numberOfNodes; i++) {
            _nodesOfUser[account].push(
                NodeEntity({
            nodeId : totalNodesCreated + 1,
            creationTime : block.timestamp + i,
            lastClaimTime : claimsTimes.length > 0 ? claimsTimes[i] : 0,
            rewardNotClaimed : rewards.length > 0 ? rewards[i] : 0
            })
            );

            nodeOwners.set(account, _nodesOfUser[account].length);
            totalNodesCreated++;
            emit NodeCreated(account, totalNodesCreated, _nodesOfUser[account].length, totalNodesCreated);
        }
    }

    function createNodes(address account, uint256 numberOfNodes) external onlyManager {

        require(createMultiNodeEnabled,"createcreateMultiNodeEnabledSingleNodeEnabled disabled");
        require(numberOfNodes > 0,"createNodes numberOfNodes cant be zero");

        for (uint256 i = 0; i < numberOfNodes; i++) {
            _nodesOfUser[account].push(
                NodeEntity({
            nodeId : totalNodesCreated + 1,
            creationTime : block.timestamp + i,
            lastClaimTime : block.timestamp + i,
            rewardNotClaimed : 0
            })
            );

            nodeOwners.set(account, _nodesOfUser[account].length);
            totalNodesCreated++;
            emit NodeCreated(account, totalNodesCreated, _nodesOfUser[account].length, totalNodesCreated);
        }
    }

    function burn(address account, uint256 _creationTime) external onlyManager {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");

        int256 nodeIndex = getNodeIndexByCreationTime(_nodesOfUser[account], _creationTime);

        require(uint256(nodeIndex) < _nodesOfUser[account].length, "NODE: CREATIME must be higher than zero");
        nodeOwners.remove(nodeOwners.getKeyAtIndex(uint256(nodeIndex)));
    }

    function getNodeIndexByCreationTime(
        NodeEntity[] storage nodes,
        uint256 _creationTime
    ) private view returns (int256) {
        bool found = false;
        int256 index = binary_search(nodes, 0, nodes.length, _creationTime);
        int256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = int256(index);
        }
        return validIndex;
    }

    function getNodeInfo(
        address account,
        uint256 _creationTime
    ) public view returns (NodeEntity memory) {

        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");

        int256 nodeIndex = getNodeIndexByCreationTime(_nodesOfUser[account], _creationTime);

        require(nodeIndex != -1, "NODE SEARCH: No NODE Found with this blocktime");
        return _nodesOfUser[account][uint256(nodeIndex)];
    }

    function _getNodeWithCreatime(
        NodeEntity[] storage nodes,
        uint256 _creationTime
    ) private view returns (NodeEntity storage) {

        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        int256 nodeIndex = getNodeIndexByCreationTime(nodes, _creationTime);

        require(nodeIndex != -1, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[uint256(nodeIndex)];
    }

    function updateRewardsToNode(address account, uint256 _creationTime, uint256 amount, bool increaseOrDecrease)
    external onlyManager
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        require(amount > 0, "amount must be higher than zero");

        int256 nodeIndex = getNodeIndexByCreationTime(_nodesOfUser[account], _creationTime);
        require(nodeIndex != -1, "NODE SEARCH: No NODE Found with this blocktime");

        increaseOrDecrease ? _nodesOfUser[account][uint256(nodeIndex)].rewardNotClaimed += amount : _nodesOfUser[account][uint256(nodeIndex)].rewardNotClaimed -= amount;
    }

    function _cashoutNodeReward(address account, uint256 _creationTime)
    external
    returns (uint256)
    {
        require(cashoutEnabled, "cashoutEnabled disabled");
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        NodeEntity storage node = _getNodeWithCreatime(_nodesOfUser[account], _creationTime);
        require(isNodeClaimable(node), "too early to claim from this node");

        int256 nodeIndex = getNodeIndexByCreationTime(_nodesOfUser[account], _creationTime);
        uint256 rewardNode = availableClaimableAmount(node.lastClaimTime) + node.rewardNotClaimed;

        _nodesOfUser[account][uint256(nodeIndex)].rewardNotClaimed = 0;
        _nodesOfUser[account][uint256(nodeIndex)].lastClaimTime = block.timestamp;

        return rewardNode;
    }

    function _cashoutAllNodesReward(address account)
    external onlyManager
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(cashoutEnabled, "cashoutEnabled disabled");

        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < _nodesOfUser[account].length; i++) {
            rewardsTotal += availableClaimableAmount(_nodesOfUser[account][i].lastClaimTime) + _nodesOfUser[account][i].rewardNotClaimed;
            _nodesOfUser[account][i].rewardNotClaimed = 0;
            _nodesOfUser[account][i].lastClaimTime = block.timestamp;
        }
        return rewardsTotal;
    }

    function isNodeClaimable(NodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + claimInterval <= block.timestamp;
    }

    function _getRewardAmountOf(address account)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        uint256 rewardCount = 0;

        for (uint256 i = 0; i < _nodesOfUser[account].length; i++) {
            rewardCount += availableClaimableAmount(_nodesOfUser[account][i].lastClaimTime) + _nodesOfUser[account][i].rewardNotClaimed;
        }

        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 _creationTime)
    external
    view
    returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");

        NodeEntity storage node = _getNodeWithCreatime(_nodesOfUser[account], _creationTime);
        return availableClaimableAmount(node.lastClaimTime) + node.rewardNotClaimed;
    }

    function _pendingClaimableAmount(uint256 nodeLastClaimTime) private view returns (uint256 availableRewards) {
        uint256 currentTime = block.timestamp;
        uint256 timePassed = (currentTime).sub(nodeLastClaimTime);
        uint256 intervalsPassed = timePassed.div(claimInterval);

        if (intervalsPassed < 1) {
            return timePassed.mul(rewardsPerMinute).div(claimInterval);
        }

        return 0;
    }

    function availableClaimableAmount(uint256 nodeLastClaimTime) private view returns (uint256 availableRewards) {
        uint256 currentTime = block.timestamp;
        uint256 intervalsPassed = (currentTime).sub(nodeLastClaimTime).div(claimInterval);
        return intervalsPassed.mul(rewardsPerMinute);
    }

    function _getNodesPendingClaimableAmount(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");

        string memory pendingClaimableAmount = uint2str(_pendingClaimableAmount(_nodesOfUser[account][0].lastClaimTime));

        for (uint256 i = 1; i < _nodesOfUser[account].length; i++) {
            pendingClaimableAmount = string(abi.encodePacked(pendingClaimableAmount,"#", uint2str(_pendingClaimableAmount(_nodesOfUser[account][i].lastClaimTime))));
        }

        return pendingClaimableAmount;
    }

    function _getNodesCreationTime(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");

        string memory _creationTimes = uint2str(_nodesOfUser[account][0].creationTime);

        for (uint256 i = 1; i < _nodesOfUser[account].length; i++) {
            _creationTimes = string(abi.encodePacked(_creationTimes,"#",uint2str(_nodesOfUser[account][i].creationTime)));
        }

        return _creationTimes;
    }

    function _getNodesRewardAvailable(address account)
    external
    view
    returns (string memory)
    {
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");

        string memory _rewardsAvailable = uint2str(availableClaimableAmount(_nodesOfUser[account][0].lastClaimTime) + _nodesOfUser[account][0].rewardNotClaimed);

        for (uint256 i = 1; i < _nodesOfUser[account].length; i++) {
            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    "#",
                    uint2str(availableClaimableAmount(_nodesOfUser[account][i].lastClaimTime) + _nodesOfUser[account][i].rewardNotClaimed)
                )
            );
        }
        return _rewardsAvailable;
    }
    // not used, just for be compatible, with old contract
    function _getNodesExpireTime(address account)
    external
    view
    returns (string memory)
    {
        return "";
    }

    function _getNodesLastClaimTime(address account)
    external
    view
    returns (string memory)
    {

        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");

        string memory _lastClaimTimes = uint2str(_nodesOfUser[account][0].lastClaimTime);

        for (uint256 i = 1; i < _nodesOfUser[account].length; i++) {
            _lastClaimTimes = string(abi.encodePacked(_lastClaimTimes,"#",uint2str(_nodesOfUser[account][i].lastClaimTime)));
        }
        return _lastClaimTimes;
    }

    function _refreshNodeRewards(uint256 gas) private
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        uint256 numberOfnodeOwners = nodeOwners.keys.length;
        require(numberOfnodeOwners > 0, "DISTRI REWARDS: NO NODE OWNERS");
        if (numberOfnodeOwners == 0) {
            return (0, 0, lastIndexProcessed);
        }

        uint256 iterations = 0;
        uint256 claims = 0;
        uint256 localLastIndex = lastIndexProcessed;

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 newGasLeft;

        while (gasUsed < gas && iterations < numberOfnodeOwners) {

            localLastIndex++;
            if (localLastIndex >= nodeOwners.keys.length) {
                localLastIndex = 0;
            }

            address account = nodeOwners.keys[localLastIndex];
            for (uint256 i = 0; i < _nodesOfUser[account].length; i++) {

                int256 nodeIndex = getNodeIndexByCreationTime(_nodesOfUser[account], _nodesOfUser[account][i].creationTime);
                require(nodeIndex != -1, "NODE SEARCH: No NODE Found with this blocktime");

                uint256 rewardNotClaimed = availableClaimableAmount(_nodesOfUser[account][i].lastClaimTime) + _pendingClaimableAmount(_nodesOfUser[account][i].lastClaimTime);
                _nodesOfUser[account][uint256(nodeIndex)].rewardNotClaimed += rewardNotClaimed;
                _nodesOfUser[account][uint256(nodeIndex)].lastClaimTime = block.timestamp;
                totalRewardStaked += rewardNotClaimed;
                claims++;
            }
            iterations++;

            newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }
        lastIndexProcessed = localLastIndex;
        return (iterations, claims, lastIndexProcessed);
    }

    function _updateRewardsToAllNodes(uint256 gas, uint256 rewardAmount, bool increaseOrDecrease) private
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        uint256 numberOfnodeOwners = nodeOwners.keys.length;
        require(numberOfnodeOwners > 0, "DISTRI REWARDS: NO NODE OWNERS");
        if (numberOfnodeOwners == 0) {
            return (0, 0, lastIndexProcessed);
        }

        uint256 iterations = 0;
        uint256 claims = 0;
        uint256 localLastIndex = lastIndexProcessed;

        uint256 gasUsed = 0;
        uint256 gasLeft = gasleft();
        uint256 newGasLeft;

        while (gasUsed < gas && iterations < numberOfnodeOwners) {

            localLastIndex++;
            if (localLastIndex >= nodeOwners.keys.length) {
                localLastIndex = 0;
            }

            address account = nodeOwners.keys[localLastIndex];

            for (uint256 i = 0; i < _nodesOfUser[account].length; i++) {

                int256 nodeIndex = getNodeIndexByCreationTime(_nodesOfUser[account], _nodesOfUser[account][i].creationTime);

                increaseOrDecrease ? _nodesOfUser[account][uint256(nodeIndex)].rewardNotClaimed += rewardAmount : _nodesOfUser[account][uint256(nodeIndex)].rewardNotClaimed -= rewardAmount;
                _nodesOfUser[account][uint256(nodeIndex)].lastClaimTime = block.timestamp;
                totalRewardStaked += rewardAmount;
                claims++;
            }
            iterations++;

            newGasLeft = gasleft();

            if (gasLeft > newGasLeft) {
                gasUsed = gasUsed.add(gasLeft.sub(newGasLeft));
            }

            gasLeft = newGasLeft;
        }
        lastIndexProcessed = localLastIndex;
        return (iterations, claims, lastIndexProcessed);
    }

    function updateRewardsToAllNodes(uint256 gas, uint256 amount, bool increaseOrDecrease) external onlyManager
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        return _updateRewardsToAllNodes(gas, amount, increaseOrDecrease);
    }

    function refreshNodeRewards(uint256 gas) external onlyManager
    returns (
        uint256,
        uint256,
        uint256
    )
    {
        return _refreshNodeRewards(gas);
    }

    function _changeNodePrice(uint256 newNodePrice) external onlyManager {
        nodePrice = newNodePrice;
    }

    function _changeRewardsPerMinute(uint256 newPrice) external onlyManager {
        if (nodeOwners.keys.length > 0) {
            _refreshNodeRewards(gasForDistribution);
        }
        rewardsPerMinute = newPrice;
    }

    function _changeGasDistri(uint256 newGasDistri) external onlyManager {
        gasForDistribution = newGasDistri;
    }

    function _changeClaimInterval(uint256 newTime) external onlyManager {
        if (nodeOwners.keys.length > 0) {
            _refreshNodeRewards(gasForDistribution);
        }
        claimInterval = newTime;
    }

    function _changeCreateSingleNodeEnabled(bool newVal) external onlyManager {
        createSingleNodeEnabled = newVal;
    }

    function _changeCashoutEnabled(bool newVal) external onlyManager {
        cashoutEnabled = newVal;
    }

    function _changeCreateMultiNodeEnabled(bool newVal) external onlyManager {
        createMultiNodeEnabled = newVal;
    }

    function _getNodeNumberOf(address account) public view returns (uint256) {
        return nodeOwners.get(account);
    }

    function isNodeOwner(address account) private view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }

    function uint2str(uint256 _i)
    internal
    pure
    returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function binary_search(
        NodeEntity[] memory arr,
        uint256 low,
        uint256 high,
        uint256 x
    ) private view returns (int256) {
        if (high >= low) {
            uint256 mid = (high + low).div(2);
            if (arr[mid].creationTime == x) {
                return int256(mid);
            } else if (arr[mid].creationTime > x) {
                return binary_search(arr, low, mid - 1, x);
            } else {
                return binary_search(arr, mid + 1, high, x);
            }
        } else {
            return -1;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IJoeRouter01 {
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
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
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
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

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
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

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

    function getAmountsOut(uint256 amountIn, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
    external
    view
    returns (uint256[] memory amounts);
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
pragma solidity ^0.8.13;

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
    public
    view
    returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
    public
    view
    returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}