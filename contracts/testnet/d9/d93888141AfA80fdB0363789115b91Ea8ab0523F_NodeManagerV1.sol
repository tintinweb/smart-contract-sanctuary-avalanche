// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "../Uniswap/IUniswapV2Factory.sol";
import "../Uniswap/IUniswapV2Pair.sol";
import "../Uniswap/IJoeRouter02.sol";
import "../common/Address.sol";
import "../common/SafeMath.sol";
import "../common/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "../common/IBoostNFT.sol";

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
  string title;
  address owner;
  uint32 createdTime;
  uint32 claimedTime;
  uint32 limitedTime;
  uint256 multiplier;
}

contract NodeManagerV1 {
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
  Node[] public nodesInactive;
  //change to private
  mapping(address => uint256[]) public nodesOfUser;
  uint32 public countTotal;
  mapping(address => uint32) public countOfUser;
  mapping(string => uint32) public countOfTier;
  uint256 public rewardsTotal;
  //sumatory of user claimed rewards
  mapping(address => uint256) public rewardsOfUser;
  mapping(string => bool) public availableFunctions;
  mapping(address => bool) public _isBlacklisted;

  uint32 public discountPer10; // 0.1%
  uint32 public withdrawRate; // 0.00%
  uint32 public transferFee; // 0%
  uint32 public rewardsPoolFee; // 70%
  uint32 public operationsPoolFee; // 70%
  uint32 public maxCountOfUser; // 0-Infinite

  uint32 public sellPricePercentage;


  IJoeRouter02 public uniswapV2Router;

  address public owner;
  
  modifier onlyOwner() {
    require(owner == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  event NodeCreated(address, string, uint32, uint32, uint32, uint32);
  event NodeUpdated(address, string, string, uint32);
  event NodeTransfered(address, address, uint32);

  constructor(address[] memory addresses) {
    tokenAddress = addresses[0];
    rewardsPoolAddress = addresses[1];
    operationsPoolAddress = addresses[2];
    owner = msg.sender;

    addTier("basic", 10 ether, 0.13 ether, 300, 0.0001 ether);
    addTier("light", 50 ether, 0.80 ether, 1 days, 0.0005 ether);
    addTier("pro", 100 ether, 2 ether, 1 days, 0.001 ether);

    discountPer10 = 10; // 0.1%
    withdrawRate = 0; // 0.00%
    transferFee = 0; // 0%
    rewardsPoolFee = 8000; // 80%
    operationsPoolFee = 2000; // 20%
    maxCountOfUser = 100; // 0-Infinite
    sellPricePercentage = 25; // 25%
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

  /**
    * @dev Update available functions.
    * Can only be called by the current owner.
    */
  function setFunctionAvailable(string memory functionName, bool value) public onlyOwner() {
      require(keccak256(abi.encodePacked(functionName)) != keccak256(abi.encodePacked("setFunctionAvailable")), "Cant disabled this function.");
      require(availableFunctions[functionName] == value, "Same value!");
      availableFunctions[functionName] = value;
  }

  function setSellPricePercentage(uint32 value) public onlyOwner {
    require(sellPricePercentage != value,"Same value!");
    sellPricePercentage = value;
  }

  function setRewardsPoolFee(uint32 value) public onlyOwner {
    require(rewardsPoolFee != value,"Same value!");
    require(operationsPoolFee + value == 10000, "Total fee must be 100%");
    rewardsPoolFee = value;
  }

  function setRewardsPoolAddress(address account) public onlyOwner {
    require(rewardsPoolAddress != account, "Same account!");
    rewardsPoolAddress = account;
  }

  function setOperationsPoolFee(uint32 value) public onlyOwner {
    require(operationsPoolFee != value,"Same value!");
    require(rewardsPoolFee + value == 10000, "Total fee must be 100%");
    operationsPoolFee = value;
  }

  function setOperationsPoolAddress(address account) public onlyOwner {
    require(operationsPoolAddress != account, "Same account!");
    operationsPoolAddress = account;
  }
  
  function setRouter(address router) public onlyOwner {
    require(address(uniswapV2Router) != router, "Same address!");
    uniswapV2Router = IJoeRouter02(router);
  }

  function setDiscountPer10(uint32 value) public onlyOwner {
    require(discountPer10 != value,"Same value!");
    discountPer10 = value;
  }
  
  function setTransferFee(uint32 value) public onlyOwner {
    require(transferFee != value,"Same value!");
    transferFee = value;
  }

  function setAddressInBlacklist(address walletAddress, bool value) public onlyOwner() {
      require(!availableFunctions["setAddressInBlacklist"], "Disabled");
      _isBlacklisted[walletAddress] = value;
  }

  function setTokenAddress(address token) public onlyOwner {
    tokenAddress = token;
  }
  
  function tiers() public view returns (Tier[] memory) {
    require(!availableFunctions["tiers"], "Disabled");
    Tier[] memory tiersActive = new Tier[](tierTotal);
    uint8 j = 0;
    for (uint8 i = 0; i < tierArr.length; i++) {
      Tier storage tier = tierArr[i];
      if (tierMap[tier.name] > 0) tiersActive[j++] = tier;
    }
    return tiersActive;
  }

  function getTierByName(string memory tierName) public view returns (Tier memory) {
    require(!availableFunctions["getTierByName"], "Disabled");
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
    require(price > 0, "Tier's price has to be positive.");
    require(rewardsPerTime > 0, "Tier's rewards has to be positive.");
    require(claimInterval > 0, "Tier's claim interval has to be positive.");
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
    require(tierId > 0, "Tier's name is incorrect.");
    require(price > 0, "Tier's price has to be positive.");
    require(rewardsPerTime > 0, "Tier's rewards has to be positive.");
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
    require(tierMap[tierName] > 0, "Tier was already removed.");
    tierMap[tierName] = 0;
    tierTotal--;
  }

  function nodes(address account) public view returns (Node[] memory) {
    require(!availableFunctions["nodes"], "Disabled");
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
    string memory title,
    uint32 count
  ) private returns (uint256) {
    require(msg.sender==owner || countOfUser[account] < maxCountOfUser, "Cannot create more nodes.");
    uint8 tierId = tierMap[tierName];
    Tier storage tier = tierArr[tierId - 1];
    for (uint32 i = 0; i < count; i++) {
      nodesTotal.push(
        Node({
          id: uint32(nodesTotal.length),
          tierIndex: tierId - 1,
          title: title,
          owner: account,
          multiplier: 0,
          createdTime: uint32(block.timestamp),
          claimedTime: uint32(block.timestamp),
          limitedTime: uint32(block.timestamp) + 300
        })
      );
      uint256[] storage nodeIndice = nodesOfUser[account];
      nodeIndice.push(nodesTotal.length);
    }
    countOfUser[account] += count;
    countOfTier[tierName] += count;
    countTotal += count;
    uint256 amount = tier.price.mul(count);
    if (count >= 10) amount = amount.mul(10000 - discountPer10).div(10000);
    return amount;
  }

  function _transferFee(uint256 amount) private {
    require(amount != 0,"Transfer token amount can't zero!");
    require(rewardsPoolAddress != address(0),"Rewards pool can't Zero!");

    uint256 feeRewardPool = amount.mul(rewardsPoolFee).div(10000);
    IERC20(tokenAddress).transferFrom(address(msg.sender), address(rewardsPoolAddress), feeRewardPool);
    uint256 feeOperationsPool = amount.mul(operationsPoolFee).div(10000);
    IERC20(tokenAddress).transferFrom(address(msg.sender), address(operationsPoolAddress), feeOperationsPool);
  }

  function mint(
    address[] memory accounts,
    string memory tierName,
    string memory title,
    uint32 count
  ) public onlyOwner {
    require(!availableFunctions["mint"], "Disabled");
    require(accounts.length>0, "Empty account list.");
    for(uint256 i = 0;i<accounts.length;i++) {
      _create(accounts[i], tierName, title, count);
    }
  }

  function create(
    string memory tierName,
    string memory title,
    uint32 count
  ) public {
    require(!_isBlacklisted[msg.sender],"Blacklisted");
    require(!availableFunctions["create"], "Disabled");
    uint256 amount = _create(msg.sender, tierName, title, count);
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
    require(!availableFunctions["claimable"], "Disabled");
    uint256 amount = 0;
    uint256[] storage nodeIndice = nodesOfUser[msg.sender];
    
    for (uint32 i = 0; i < nodeIndice.length; i++) {
      uint256 nodeIndex = nodeIndice[i];
      if (nodeIndex > 0) {
        Node storage node = nodesTotal[nodeIndex - 1];
        if (node.owner == msg.sender) {
          uint256 multiplier = getBoostRate(msg.sender, node.claimedTime, block.timestamp);
          Tier storage tier = tierArr[node.tierIndex];
          amount = uint256(block.timestamp - node.claimedTime)
            .mul(tier.rewardsPerTime)
            .mul(multiplier)
            .div(1 ether)
            .div(tier.claimInterval)
            .add(amount);
        }
      }
    }
    return amount;
  }

  function _claim(uint256 exceptAmount) private {
    require(!availableFunctions["_claim"], "Disabled");
    require(!_isBlacklisted[msg.sender],"Blacklisted");
    uint256 claimableAmount = 0;
    uint256[] storage nodeIndice = nodesOfUser[msg.sender];
    for (uint32 i = 0; i < nodeIndice.length; i++) {
      uint256 nodeIndex = nodeIndice[i];
      if (nodeIndex > 0) {
        Node storage node = nodesTotal[nodeIndex - 1];
        if (node.owner == msg.sender && node.limitedTime > uint32(block.timestamp)) {
          uint256 multiplier = getBoostRate(msg.sender, node.claimedTime, block.timestamp);
          
          Tier storage tier = tierArr[node.tierIndex];
          claimableAmount = uint256(block.timestamp - node.claimedTime)
            .mul(tier.rewardsPerTime)
            .mul(multiplier)
            .div(1 ether)
            .div(tier.claimInterval)
            .add(claimableAmount);
          node.claimedTime = uint32(block.timestamp);
        }
      }
    }
    require(claimableAmount > 0, "No claimable tokens.");
    if (exceptAmount > 0)
      require(claimableAmount >= exceptAmount, "Insufficient claimable tokens to compound.");
    rewardsOfUser[msg.sender] = rewardsOfUser[msg.sender].add(claimableAmount);
    rewardsTotal = rewardsTotal.add(claimableAmount);
    IERC20(tokenAddress).transferFrom(address(rewardsPoolAddress),address(msg.sender), claimableAmount.sub(exceptAmount));
  }

  // function compound(
  //   string memory tierName,
  //   string memory title,
  //   uint32 count
  // ) public {
  //   require(!availableFunctions["compound"], "Disabled");
  //   uint256 amount = _create(msg.sender, tierName, title, count);
  //   _claim(amount);
  //   emit NodeCreated(
  //     msg.sender,
  //     tierName,
  //     count,
  //     countTotal,
  //     countOfUser[msg.sender],
  //     countOfTier[tierName]
  //   );
  // }

  function claim() public {
    require(!availableFunctions["claim"], "Disabled");
    _claim(0);
  }

  function upgrade(
    string memory tierNameFrom,
    string memory tierNameTo,
    uint32 count
  ) public {
    require(!availableFunctions["upgrade"], "Disabled");
    uint8 tierIndexFrom = tierMap[tierNameFrom];
    uint8 tierIndexTo = tierMap[tierNameTo];
    require(tierIndexFrom > 0, "Invalid tier to upgrade from.");
    require(tierIndexTo > 0, "Invalid tier to upgrade to.");
    Tier storage tierFrom = tierArr[tierIndexFrom - 1];
    Tier storage tierTo = tierArr[tierIndexTo - 1];
    require(tierTo.price > tierFrom.price, "Unable to downgrade.");
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
          uint256 claimed = uint256(block.timestamp - node.claimedTime)
            .mul(tierFrom.rewardsPerTime)
            .div(tierFrom.claimInterval);
          claimableAmount = claimed.mul(multiplier).div(10**18).add(claimableAmount);
          node.claimedTime = uint32(block.timestamp);
          countUpgrade++;
          if (countUpgrade == count) break;
        }
      }
    }
    require(countUpgrade == count, "Not enough nodes.");
    countOfTier[tierNameFrom] -= count;
    countOfTier[tierNameTo] += count;
    if (claimableAmount > 0) {
      rewardsOfUser[msg.sender] = rewardsOfUser[msg.sender].add(claimableAmount);
      rewardsTotal = rewardsTotal.add(claimableAmount);
      IERC20(tokenAddress).transferFrom(address(rewardsPoolAddress),address(msg.sender), claimableAmount);
    }
    uint256 price = tierTo.price.sub(tierFrom.price).mul(count);
    if (count >= 10) price = price.mul(10000 - discountPer10).div(10000);
    _transferFee(price);
    emit NodeUpdated(msg.sender, tierNameFrom, tierNameTo, count);
  }

  // function transfer(
  //   string memory tierName,
  //   uint32 count,
  //   address recipient
  // ) public {
  //   require(!availableFunctions["transfer"], "Disabled");
  //   require(!_isBlacklisted[msg.sender],"Blacklisted");
  //   require(!_isBlacklisted[recipient],"Blacklisted recipient");
  //   uint8 tierIndex = tierMap[tierName];
  //   require(tierIndex > 0, "Invalid tier to transfer.");
  //   Tier storage tier = tierArr[tierIndex - 1];
  //   uint256[] storage nodeIndiceFrom = nodesOfUser[msg.sender];
  //   uint256[] storage nodeIndiceTo = nodesOfUser[recipient];
  //   uint32 countTransfer = 0;
  //   uint256 claimableAmount = 0;
  //   for (uint32 i = 0; i < nodeIndiceFrom.length; i++) {
  //     uint256 nodeIndex = nodeIndiceFrom[i];
  //     if (nodeIndex > 0) {
  //       Node storage node = nodesTotal[nodeIndex - 1];
  //       if (node.owner == msg.sender && tierIndex - 1 == node.tierIndex) {
  //         node.owner = recipient;
  //         uint256 multiplier = getBoostRate(msg.sender, node.claimedTime, block.timestamp);
  //         uint256 claimed = uint256(block.timestamp - node.claimedTime)
  //           .mul(tier.rewardsPerTime)
  //           .div(tier.claimInterval);
  //         claimableAmount = claimed.mul(multiplier).div(10**18).add(claimableAmount);
  //         node.claimedTime = uint32(block.timestamp);
  //         countTransfer++;
  //         nodeIndiceTo.push(nodeIndex);
  //         nodeIndiceFrom[i] = 0;
  //         if (countTransfer == count) break;
  //       }
  //     }
  //   }
  //   require(countTransfer == count, "Not enough nodes.");
  //   countOfUser[msg.sender] -= count;
  //   countOfUser[recipient] += count;
  //   if (claimableAmount > 0) {
  //     rewardsOfUser[msg.sender] = rewardsOfUser[msg.sender].add(claimableAmount);
  //     rewardsTotal = rewardsTotal.add(claimableAmount);
  //   }
  //   uint256 fee = tier.price.mul(count).mul(transferFee).div(10000);
  //   if (count >= 10) fee = fee.mul(10000 - discountPer10).div(10000);
  //   if (fee > claimableAmount)
  //     IERC20(tokenAddress).transferFrom(
  //       address(msg.sender),
  //       address(this),
  //       fee.sub(claimableAmount)
  //     );
  //   else if (fee < claimableAmount)
  //     IERC20(tokenAddress).transferFrom(address(rewardsPoolAddress), address(msg.sender), claimableAmount.sub(fee));
  //   emit NodeTransfered(msg.sender, recipient, count);
  // }

  function burnUser(address account) public onlyOwner {
    require(!availableFunctions["burnUser"], "Disabled");
    uint256[] storage nodeIndice = nodesOfUser[account];
    for (uint32 i = 0; i < nodeIndice.length; i++) {
      uint256 nodeIndex = nodeIndice[i];
      if (nodeIndex > 0) {
        Node storage node = nodesTotal[nodeIndex - 1];
        if (node.owner == account) {
          node.owner = address(0);
          node.claimedTime = uint32(block.timestamp);
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
    require(!availableFunctions["burnNodes"], "Disabled");
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
          node.claimedTime = uint32(block.timestamp);
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
    require(!availableFunctions["sellNode"], "Disabled");
    require(!_isBlacklisted[msg.sender],"Blacklisted");
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
      node.claimedTime = uint32(block.timestamp);
      Tier storage tier = tierArr[node.tierIndex];
      countOfTier[tier.name]--;
      countTotal--;
      IERC20(tokenAddress).transferFrom(address(rewardsPoolAddress), address(node.owner), tier.price.div(100).mul(sellPricePercentage));
    }
  }

  function withdraw(uint256 amount) public onlyOwner {
    require(
      IERC20(tokenAddress).balanceOf(address(this)) >= amount,
      "Withdraw: Insufficent balance."
    );
    IERC20(tokenAddress).transfer(address(msg.sender), amount);
  }

  function withdrawAllAvax() public onlyOwner {
    // get the amount of Ether stored in this contract
    uint256 amount = address(this).balance;

    // send all Ether to owner
    // Owner can receive Ether since the address of owner is payable
    (bool success, ) = payable(msg.sender).call{value: amount}("");
    require(success, "Failed to send Ether");
  }

  function pay(uint8 count, uint256[] memory selected) public payable {
    require(!availableFunctions["pay"], "Disabled");
    require(count > 0 && count <= 12, "Invalid number of months.");
    uint256 fee = 0;
    if(selected.length==0) {
      uint256[] storage nodeIndice = nodesOfUser[msg.sender];
      for (uint32 i = 0; i < nodeIndice.length; i++) {
        uint256 nodeIndex = nodeIndice[i];
        if (nodeIndex > 0) {
          Node storage node = nodesTotal[nodeIndex - 1];
          if (node.owner == msg.sender) {
            Tier storage tier = tierArr[node.tierIndex];
            node.limitedTime += count * uint32(300);
            fee = tier.maintenanceFee.mul(count).add(fee);
          }
        }
      }
    } else {
      for (uint32 i = 0; i < selected.length; i++) {
        uint256 nodeIndex = selected[i];
        Node storage node = nodesTotal[nodeIndex];
        if (node.owner == msg.sender) {
          Tier storage tier = tierArr[node.tierIndex];
          node.limitedTime += count * uint32(300);
          fee = tier.maintenanceFee.mul(count).add(fee);
        }
      }
    }
  }

  function _unpaidNodes() public {
    uint32 count = 0;
    for (uint32 i = 0; i < nodesTotal.length; i++) {
      Node storage node = nodesTotal[i];
      if (node.owner != address(0) && node.limitedTime < uint32(block.timestamp)) {
        count++;
      }
    }
    //Node[] memory nodesInactive = new Node[](count);
    uint32 j = 0;
    for (uint32 i = 0; i < nodesTotal.length; i++) {
      Node storage node = nodesTotal[i];
      if (node.owner != address(0) && node.limitedTime < uint32(block.timestamp)) {
        countOfUser[node.owner]--;
        node.owner = address(0);
        node.claimedTime = uint32(block.timestamp);
        Tier storage tier = tierArr[node.tierIndex];
        countOfTier[tier.name]--;
        countTotal--;
        nodesInactive.push(node);
      }
    }
  }
  
  function unpaidNodes() public view returns (Node[] memory) {
    return nodesInactive;
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

pragma solidity ^0.8.12;

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

        (bool success,) = recipient.call{value : amount}("");
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

        (bool success, bytes memory returndata) = target.call{value : value}(data);
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

pragma solidity ^0.8.12;

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
pragma solidity ^0.8.12;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
   */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
   */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
   */
    function symbol() external view returns (string memory);

    /**
    * @dev Returns the token name.
  */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
   */
    function getOwner() external view returns (address);

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
    function allowance(address _owner, address spender) external view returns (uint256);

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
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IBoostNFT is IERC1155 {
   function getMultiplier(address account, uint256 timeFrom, uint256 timeTo ) external view returns (uint256);
   function getLastMultiplier(address account, uint256 timeTo) external view returns (uint256);
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