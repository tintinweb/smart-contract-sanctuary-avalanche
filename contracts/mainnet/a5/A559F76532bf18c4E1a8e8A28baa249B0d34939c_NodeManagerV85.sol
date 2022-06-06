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
import "./INodeReward.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";

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

interface ICreditNFT {
    function useCredits(
        address,
        uint32,
        uint32
    ) external;
}

contract NodeManagerV85 is Initializable, KeeperCompatibleInterface {
    using SafeMath for uint256;
    address public tokenAddress;
    address public nftAddress;
    address public rewardsPoolAddress;
    address public operationsPoolAddress;

    Tier[] private tierArr;
    mapping(string => uint8) public tierMap;
    uint8 public tierTotal;
    uint8 public maxMonthValue;
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
    mapping(address => uint256) public oldRewardsOfUser;
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
    INodeReward public oldNodeManager;

    address public owner;
    mapping(address => bool) public rewardMigrated;
    uint32 public mantPercent;
    mapping(address => bool) public managers;
    mapping(address => uint32) public lastTimestampClaim;
    bool dynamicClaimFeeEnabled;
    /**
     * Use an interval in seconds and a timestamp to slow execution of Upkeep
     */
    bool keepersEnabled;
    uint256 public keepersInterval;
    uint256 public lastTimeStamp;
    uint256 public updateInterval;

    mapping(address => bool) public buyers;
    ICreditNFT public creditNFT;
    uint8 public compTaxRate;
    modifier onlyOwner() {
        require(owner == msg.sender, "onlyOwner");
        _;
    }
    modifier onlyBuyer() {
        require(buyers[msg.sender] == true, "onlyBuyer");
        _;
    }
    event NodeCreated(address, string, uint32, uint32, uint32, uint32);
    event NodeUpdated(address, string, string, uint32);
    event NodeTransfered(address, address, uint32);
    event GiftCardPayed(address, address, string, uint256);

    function initialize(address[] memory addresses) public initializer {
        tokenAddress = addresses[0];
        rewardsPoolAddress = addresses[1];
        operationsPoolAddress = addresses[2];
        owner = msg.sender;

        addTier("basic", 10 ether, 0.17 ether, 1 days, 0.001 ether);
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
        maxMonthValue = 3;
        oldNodeManager = INodeReward(
            0x05c88F67fa0711b3a76ada2B6f0A2D3a54Fc775c
        ); // mainnet 0x05c88F67fa0711b3a76ada2B6f0A2D3a54Fc775c
        //bindBoostNFT(addresses[3]);

        keepersEnabled = false;
        keepersInterval = 1 days;
        lastTimeStamp = block.timestamp;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "zero");
        owner = newOwner;
    }

    function bindBoostNFT(address _nftAddress) public onlyOwner {
        boostNFT = IBoostNFT(_nftAddress);
    }

    function bindCreditNFT(address _nftAddress) public onlyOwner {
        creditNFT = ICreditNFT(_nftAddress);
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

    function setMaxMonthValue(uint8 value) public onlyOwner {
        maxMonthValue = value;
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

    function setAddressInBlacklist(address walletAddress, bool value)
        public
        onlyOwner
    {
        _isBlacklisted[walletAddress] = value;
    }

    function setTokenAddress(address token) public onlyOwner {
        tokenAddress = token;
    }

    function setMantPercent(uint32 value) public onlyOwner {
        mantPercent = value;
    }

    function setBuyer(address _buyer, bool _active) public onlyOwner {
        buyers[_buyer] = _active;
    }

    function setCompTaxRate(uint8 _rate) public onlyOwner {
        compTaxRate = _rate; // 50: 50%
    }

    function tiers() public view returns (Tier[] memory) {
        Tier[] memory tiersActive = new Tier[](tierTotal);
        uint8 j = 0;
        for (uint8 i = 0; i < tierArr.length; i++) {
            Tier storage tier = tierArr[i];
            if (tierMap[tier.name] > 0) tiersActive[j++] = tier;
        }
        return tiersActive;
    }

    function addTier(
        string memory name,
        uint256 price,
        uint256 rewardsPerTime,
        uint32 claimInterval,
        uint256 maintenanceFee
    ) public onlyOwner {
        require(price > 0, "price");
        require(rewardsPerTime > 0, "rewards");
        require(claimInterval > 0, "claim");
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

    /*
    function updateTier(
        string memory tierName,
        string memory name,
        uint256 price,
        uint256 rewardsPerTime,
        uint32 claimInterval,
        uint256 maintenanceFee
    ) public onlyOwner {
        uint8 tierId = tierMap[tierName];
        require(tierId > 0, "Old");
        require(
            keccak256(bytes(tierName)) != keccak256(bytes(name)),
            "name incorrect"
        );
        require(price > 0, "price");
        require(rewardsPerTime > 0, "rewardsPerTime");
        Tier storage tier = tierArr[tierId - 1];
        tier.name = name;
        tier.price = price;
        tier.rewardsPerTime = rewardsPerTime;
        tier.claimInterval = claimInterval;
        tier.maintenanceFee = maintenanceFee;
        tierMap[tierName] = 0;
        tierMap[name] = tierId;
    }

    function removeTier(string memory tierName) public virtual onlyOwner {
        require(tierMap[tierName] > 0, "removed");
        tierMap[tierName] = 0;
        tierTotal--;
    }*/

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
                    nodesActive[j++].multiplier = getBoostRate(
                        account,
                        node.claimedTime,
                        block.timestamp
                    );
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
        require(!_isBlacklisted[msg.sender], "Blacklisted");
        require(
            msg.sender == owner ||
                (countOfUser[account] + count) <= maxCountOfUser,
            "Max"
        );
        uint8 tierId = tierMap[tierName] - 1;
        uint256 tierPrice = tierArr[tierId].price;
        uint32 createdTime = uint32(block.timestamp);
        for (uint32 i = 0; i < count; i++) {
            nodesTotal.push(
                Node({
                    id: uint32(nodesTotal.length),
                    tierIndex: tierId,
                    owner: account,
                    multiplier: 0,
                    createdTime: createdTime,
                    claimedTime: createdTime,
                    limitedTime: createdTime + payInterval,
                    leftover: 0
                })
            );
            nodesOfUser[account].push(nodesTotal.length);
        }
        countOfUser[account] += count;
        countOfTier[tierName] += count;
        countTotal += count;
        uint256 amount = tierPrice * count;
        if (count >= 10) amount = (amount * (10000 - discountPer10)) / 10000;
        return amount;
    }

    function _transferFee(uint256 amount) private {
        IERC20Upgradeable(tokenAddress).transferFrom(
            address(msg.sender),
            address(rewardsPoolAddress),
            (amount * rewardsPoolFee) / 10000
        );
        IERC20Upgradeable(tokenAddress).transferFrom(
            address(msg.sender),
            address(operationsPoolAddress),
            (amount * operationsPoolFee) / 10000
        );
    }

    function mint(
        address[] memory accounts,
        string memory tierName,
        uint32 count
    ) public onlyOwner {
        require(accounts.length > 0, "Empty");
        for (uint256 i = 0; i < accounts.length; i++) {
            _create(accounts[i], tierName, count);
        }
    }

    function create(string memory tierName, uint32 count) public {
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

    function getBoostRate(
        address, /* account */
        uint256, /* timeFrom */
        uint256 /* timeTo */
    ) public pure returns (uint256) {
        // uint256 multiplier = 1 ether;
        // if (nftAddress == address(0)) {
        //     return multiplier;
        // }
        // IBoostNFT nft = IBoostNFT(nftAddress);
        // multiplier = nft.getMultiplier(account, timeFrom, timeTo);

        // return multiplier;
        return 1 ether;
    }

    function claimable(address _account) external view returns (uint256) {
        (uint256 claimableAmount, , ) = _iterate(_account, 0, 0);
        return claimableAmount + oldRewardsOfUser[msg.sender];
    }

    function _claim(address _account) private {
        (
            uint256 claimableAmount,
            uint32 count,
            uint256[] memory nodeIndice
        ) = _iterate(_account, 0, 0);

        if (claimableAmount > 0) {
            rewardsOfUser[_account] += claimableAmount;
            rewardsTotal = rewardsTotal + claimableAmount;
            oldRewardsOfUser[_account] += claimableAmount;
        }

        for (uint32 i = 0; i < count; i++) {
            uint256 index = nodeIndice[i];
            Node storage node = nodesTotal[index - 1];
            node.claimedTime = uint32(block.timestamp);
        }
    }

    function compound(string memory tierName, uint32 count) public {
        uint256 amount = _create(msg.sender, tierName, count);
        _claim(msg.sender);
        require(oldRewardsOfUser[msg.sender] >= amount, "Insuff");

        oldRewardsOfUser[msg.sender] -= amount;
        emit NodeCreated(
            msg.sender,
            tierName,
            count,
            countTotal,
            countOfUser[msg.sender],
            countOfTier[tierName]
        );
    }

    function transferUnclaimed(
        address _account,
        address _to,
        uint256 _amount
    ) external onlyBuyer {
        _claim(_account);
        uint32 claimFeeRate = dynamicClaimFeeEnabled
            ? (rateClaimFee(msg.sender) * compTaxRate) / 100
            : (claimFee * compTaxRate) / 100;
        uint256 feeAmount = (_amount * claimFeeRate) / 10000;
        if (feeAmount > 0) {
            IERC20(tokenAddress).transferFrom(
                address(rewardsPoolAddress),
                address(operationsPoolAddress),
                feeAmount
            );
        }
        require(oldRewardsOfUser[_account] >= _amount + feeAmount, "Insuff");
        oldRewardsOfUser[_account] -= _amount + feeAmount;
        IERC20(tokenAddress).transferFrom(
            address(rewardsPoolAddress),
            address(_to),
            _amount
        );
    }

    function rateClaimFee(address account) public view returns (uint32) {
        if (lastTimestampClaim[account] == 0) return claimFee;
        uint32 elapsed = uint32(block.timestamp) - lastTimestampClaim[account];
        if (elapsed <= 5 days) return 5000;
        else if (elapsed <= 11 days) return 4000;
        else if (elapsed <= 17 days) return 3000;
        else if (elapsed <= 24 days) return 2000;
        else if (elapsed <= 30 days) return 1000;
        return 100;
    }

    function claim() public {
        _claim(msg.sender);
        //require(oldRewardsOfUser[msg.sender] > 0, "No claimable tokens.");
        uint32 claimFeeRate = dynamicClaimFeeEnabled
            ? rateClaimFee(msg.sender)
            : claimFee;
        if (claimFeeRate > 0) {
            // calc claim fee amunt and send to operation pool
            uint256 feeAmount = (oldRewardsOfUser[msg.sender] * claimFeeRate) /
                10000;
            oldRewardsOfUser[msg.sender] -= feeAmount;
            IERC20(tokenAddress).transferFrom(
                address(rewardsPoolAddress),
                address(operationsPoolAddress),
                feeAmount
            );
        }
        IERC20(tokenAddress).transferFrom(
            address(rewardsPoolAddress),
            address(msg.sender),
            oldRewardsOfUser[msg.sender]
        );
        oldRewardsOfUser[msg.sender] = 0;
        lastTimestampClaim[msg.sender] = uint32(block.timestamp);
    }

    /*
    function upgrade(
        string memory tierNameFrom,
        string memory tierNameTo,
        uint32 count
    ) public {
        uint8 tierIndexFrom = tierMap[tierNameFrom];
        uint8 tierIndexTo = tierMap[tierNameTo];
        require(tierIndexFrom > 0, "Invalid");
        require(!_isBlacklisted[msg.sender], "Black");
        Tier storage tierFrom = tierArr[tierIndexFrom - 1];
        Tier storage tierTo = tierArr[tierIndexTo - 1];
        require(tierTo.price > tierFrom.price, "downgrade");
        uint256[] storage nodeIndice = nodesOfUser[msg.sender];
        uint32 countUpgrade = 0;
        uint256 claimableAmount = 0;
        for (uint32 i = 0; i < nodeIndice.length; i++) {
            uint256 nodeIndex = nodeIndice[i];
            if (nodeIndex > 0) {
                Node storage node = nodesTotal[nodeIndex - 1];
                if (
                    node.owner == msg.sender &&
                    tierIndexFrom - 1 == node.tierIndex
                ) {
                    node.tierIndex = tierIndexTo - 1;
                    uint256 multiplier = getBoostRate(
                        msg.sender,
                        node.claimedTime,
                        block.timestamp
                    );
                    uint256 claimed = (uint256(
                        block.timestamp - node.claimedTime
                    ) * tierFrom.rewardsPerTime) / tierFrom.claimInterval;
                    claimableAmount += (claimed * multiplier) / (10**18);
                    node.claimedTime = uint32(block.timestamp);
                    countUpgrade++;
                    if (countUpgrade == count) break;
                }
            }
        }
        require(countUpgrade == count, "N enough");
        countOfTier[tierNameFrom] -= count;
        countOfTier[tierNameTo] += count;
        if (claimableAmount > 0) {
            rewardsOfUser[msg.sender] += claimableAmount;
            rewardsTotal += claimableAmount;
            IERC20Upgradeable(tokenAddress).transferFrom(
                address(rewardsPoolAddress),
                address(msg.sender),
                claimableAmount
            );
        }
        uint256 price = (tierTo.price - tierFrom.price) * count;
        if (count >= 10) price = (price * (10000 - discountPer10)) / 10000;
        _transferFee(price);
        emit NodeUpdated(msg.sender, tierNameFrom, tierNameTo, count);
    }
    */

    function transfer(
        string memory tierName,
        uint32 count,
        address from,
        address to
    ) public onlyOwner {
        require(!_isBlacklisted[from] || !_isBlacklisted[to], "Black");
        uint8 tierIndex = tierMap[tierName];
        require((countOfUser[to] + count) <= maxCountOfUser, "max");
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
                    uint256 multiplier = getBoostRate(
                        from,
                        node.claimedTime,
                        block.timestamp
                    );
                    uint256 claimed = (uint256(
                        block.timestamp - node.claimedTime
                    ) * tier.rewardsPerTime) / tier.claimInterval;
                    claimableAmount += (claimed * multiplier) / (10**18);
                    node.claimedTime = uint32(block.timestamp);
                    countTransfer++;
                    nodeIndiceTo.push(nodeIndex);
                    nodeIndiceFrom[i] = 0;
                    if (countTransfer == count) break;
                }
            }
        }
        require(countTransfer == count, "N enough");
        countOfUser[from] -= count;
        countOfUser[to] += count;
        if (claimableAmount > 0) {
            rewardsOfUser[from] += claimableAmount;
            rewardsTotal += claimableAmount;
            IERC20Upgradeable(tokenAddress).transferFrom(
                address(rewardsPoolAddress),
                address(from),
                claimableAmount
            );
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

    function withdraw(address anyToken, address recipient) external onlyOwner {
        IERC20Upgradeable(anyToken).transfer(
            recipient,
            IERC20Upgradeable(anyToken).balanceOf(address(this))
        );
    }

    function pay(uint8 count, uint256[] memory selected) public payable {
        payWithNFT(count, selected, false);
    }

    function payWithNFT(
        uint8 count,
        uint256[] memory selected,
        bool useNFT
    ) public payable {
        require(count > 0 && count <= maxMonthValue, "Invalid");
        uint256 fee = 0;

        if (selected.length == 0) {
            if (useNFT)
                creditNFT.useCredits(
                    msg.sender,
                    uint32(countOfUser[msg.sender]),
                    uint32(count)
                );
            uint256[] storage nodeIndice = nodesOfUser[msg.sender];
            for (uint32 i = 0; i < nodeIndice.length; i++) {
                uint256 nodeIndex = nodeIndice[i];
                if (nodeIndex > 0) {
                    Node storage node = nodesTotal[nodeIndex - 1];
                    if (node.owner == msg.sender) {
                        node.limitedTime += count * uint32(payInterval);
                        if (!useNFT) {
                            Tier storage tier = tierArr[node.tierIndex];
                            uint8 pM = uint8(
                                (node.limitedTime - block.timestamp) /
                                    payInterval
                            );
                            require(pM <= 3, "3 m");
                            fee += getAmountOut(
                                ((tier.price * mantPercent) / 10000) * count
                            );
                        }
                    }
                }
            }
        } else {
            if (useNFT)
                creditNFT.useCredits(
                    msg.sender,
                    uint32(selected.length),
                    uint32(count)
                );
            for (uint32 i = 0; i < selected.length; i++) {
                uint256 nodeIndex = selected[i];
                Node storage node = nodesTotal[nodeIndex];
                if (node.owner == msg.sender) {
                    node.limitedTime += count * uint32(payInterval);
                    if (!useNFT) {
                        Tier storage tier = tierArr[node.tierIndex];
                        uint8 pM = uint8(
                            (node.limitedTime - block.timestamp) / payInterval
                        );
                        require(pM <= 3, "3 m");
                        fee += getAmountOut(
                            ((tier.price * mantPercent) / 10000) * count
                        );
                    }
                }
            }
        }
        if (!useNFT) {
            require(fee <= msg.value, "Fee");
            payable(address(operationsPoolAddress)).transfer(fee);
        }
    }

    function checkNodes(address ownerAddress)
        public
        view
        returns (Node[] memory)
    {
        uint32 count = 0;
        for (uint32 i = 0; i < nodesTotal.length; i++) {
            Node storage node = nodesTotal[i];
            if (
                node.owner != address(0) &&
                node.owner == ownerAddress &&
                node.limitedTime < uint32(block.timestamp)
            ) {
                count++;
            }
        }
        Node[] memory nodesToPay = new Node[](count);
        uint32 j = 0;
        for (uint32 i = 0; i < nodesTotal.length; i++) {
            Node storage node = nodesTotal[i];
            if (
                node.owner != address(0) &&
                node.owner == ownerAddress &&
                node.limitedTime < uint32(block.timestamp)
            ) {
                nodesToPay[j++] = node;
            }
        }
        return nodesToPay;
    }

    function getUnpaidNodes() public view onlyOwner returns (uint32[] memory) {
        uint32 count = 0;
        for (uint32 i = 0; i < nodesTotal.length; i++) {
            Node storage node = nodesTotal[i];
            if (
                node.owner != address(0) &&
                (node.limitedTime + payInterval) < uint32(block.timestamp)
            ) {
                count++;
            }
        }
        uint32[] memory nodesInactive = new uint32[](count);
        uint32 j = 0;
        for (uint32 i = 0; i < nodesTotal.length; i++) {
            Node storage node = nodesTotal[i];
            if (
                node.owner != address(0) &&
                (node.limitedTime + payInterval) < uint32(block.timestamp)
            ) {
                nodesInactive[j++] = node.id;
            }
        }
        return nodesInactive;
    }

    /*
    function migrateNodesFromOldVersion() public {
        require(!userMigrated[msg.sender], "migrated");
        uint32 nodeNumber = uint32(oldNodeManager._getNodeNumberOf(msg.sender));

        if (nodeNumber != 0 && !userMigrated[msg.sender]) {
            userMigrated[msg.sender] = true;
            _create(msg.sender, "basic", nodeNumber);
        }
    }

    function migrateRewardsFromOldVersion() public {
        require(userMigrated[msg.sender], "Nodes migrated");
        require(!rewardMigrated[msg.sender], "Reward migrated");
        oldRewardsOfUser[msg.sender] = oldNodeManager._getRewardAmountOf(
            msg.sender
        );
        rewardMigrated[msg.sender] = true;
    }
*/
    function getAmountOut(uint256 _amount) public view returns (uint256) {
        if (address(uniswapV2Router) == address(0)) return 0;
        address[] memory path = new address[](2);
        path[0] = address(tokenAddress);
        path[1] = uniswapV2Router.WAVAX();
        uint256[] memory amountsOut = uniswapV2Router.getAmountsOut(
            _amount,
            path
        );
        return amountsOut[1];
    }

    function _iterate(
        address _account,
        uint8 _tierId,
        uint32 _count
    )
        private
        view
        returns (
            uint256,
            uint32,
            uint256[] memory
        )
    {
        uint32 count = 0;
        uint256 claimableAmount = 0;
        uint256 nodeIndiceLength = nodesOfUser[_account].length;
        uint256[] memory nodeIndiceResult = new uint256[](nodeIndiceLength);

        for (uint32 i = 0; i < nodeIndiceLength; i++) {
            uint256 nodeIndex = nodesOfUser[_account][i];

            if (nodeIndex > 0) {
                address nodeOwner = nodesTotal[nodeIndex - 1].owner;
                uint8 nodeTierIndex = nodesTotal[nodeIndex - 1].tierIndex;
                uint32 nodeClaimedTime = nodesTotal[nodeIndex - 1].claimedTime;

                if (_tierId != 0 && nodeTierIndex != _tierId - 1) continue;

                if (nodeOwner == _account) {
                    uint256 tierRewardsPerTime = tierArr[nodeTierIndex]
                        .rewardsPerTime;
                    uint256 tierClaimInterval = tierArr[nodeTierIndex]
                        .claimInterval;

                    uint256 multiplier = getBoostRate(
                        nodeOwner,
                        nodeClaimedTime,
                        block.timestamp
                    );
                    claimableAmount =
                        (uint256(block.timestamp - nodeClaimedTime) *
                            tierRewardsPerTime *
                            multiplier) /
                        1 ether /
                        tierClaimInterval +
                        claimableAmount;

                    nodeIndiceResult[count] = nodeIndex;
                    count++;
                    if (_count != 0 && count == _count) break;
                }
            }
        }
        return (claimableAmount, count, nodeIndiceResult);
    }

    function setMaxCountOfUser(uint32 _count) public onlyOwner {
        maxCountOfUser = _count;
    }

    function setDynamicClaimFeeEnabled(bool val) public onlyOwner {
        dynamicClaimFeeEnabled = val;
    }

    function buyGiftCard(
        address token,
        string memory orderID,
        uint256 mode,
        uint256 amount
    ) public payable {
        if (
            token != address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7) &&
            mode == 0
        ) {
            IERC20(token).transferFrom(
                address(msg.sender),
                address(operationsPoolAddress),
                amount
            );
        } else if (
            token == address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7)
        ) {
            require(msg.value >= amount, "low value");
            payable(address(operationsPoolAddress)).transfer(msg.value);
        } else {
            _claim(msg.sender);
            require(oldRewardsOfUser[msg.sender] >= amount, "Insuff");
            oldRewardsOfUser[msg.sender] -= amount;
            IERC20(token).transferFrom(
                address(rewardsPoolAddress),
                address(operationsPoolAddress),
                amount
            );
        }

        emit GiftCardPayed(msg.sender, token, orderID, amount);
    }

    function setKeepersInterval(uint256 val) public onlyOwner {
        keepersInterval = val;
    }

    function setUpdateInterval(uint256 val) public onlyOwner {
        updateInterval = val;
    }

    function setkeepersEnabled(bool val) public onlyOwner {
        keepersEnabled = val;
    }

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > keepersInterval;
        // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if (
            keepersEnabled &&
            (block.timestamp - lastTimeStamp) > keepersInterval
        ) {
            lastTimeStamp = block.timestamp;
            uint32[] memory unpaidNodesList = getUnpaidNodes();
            burnNodes(unpaidNodesList);
        }
        // We don't use the performData in this example. The performData is generated by the Keeper's call to your checkUpkeep function
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
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
pragma solidity ^0.8.13;

interface INodeReward {
  function _getNodeNumberOf(address account) external view returns (uint256);
  function _getRewardAmountOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./KeeperBase.sol";
import "./interfaces/KeeperCompatibleInterface.sol";

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

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
pragma solidity ^0.8.0;

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}