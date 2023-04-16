/**
 *Submitted for verification at snowtrace.io on 2023-04-16
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IPythStructs {
    struct Price {
        int64 price;
        uint64 conf;
        int32 expo;
        uint publishTime;
    }

    struct PriceFeed {
        bytes32 id;
        Price price;
        Price emaPrice;
    }
}

interface IPythPriceFeed {
    function getPriceUnsafe(
        bytes32 id
    ) external view returns (IPythStructs.Price memory price);
}

contract PythPricePusher {
    struct Subscription {
        bytes32 id;
        address owner;
        uint256 balance;
        IPythStructs.Price latestPriceData;
        uint256 latestUpdateTimestamp;
        uint256 timestampThreshold;
        int64 percentChangeThreshold;
        uint256 bountyAmount; // Added bountyAmount field
    }
    Subscription[] public subscriptions;

    IPythPriceFeed public pythContract = IPythPriceFeed(0x4305FB66699C3B2702D4d05CF36551390A4c69C6);

    event SubscriptionUpdated(bytes32 indexed id, IPythStructs.Price priceData);

    function createSubscription(
        bytes32 id,
        uint256 timestampThreshold,
        int64 percentChangeThreshold,
        uint256 bountyAmount // Added bountyAmount parameter
    ) external payable {
        IPythStructs.Price memory priceData = pythContract.getPriceUnsafe(id);

        Subscription memory newSubscription = Subscription({
            id: id,
            owner: msg.sender,
            balance: msg.value,
            latestPriceData: priceData,
            latestUpdateTimestamp: block.timestamp,
            timestampThreshold: timestampThreshold,
            percentChangeThreshold: percentChangeThreshold,
            bountyAmount: bountyAmount // Set bountyAmount upon creation
        });

        subscriptions.push(newSubscription);
    }

    function getMySubscriptions() external view returns (Subscription[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < subscriptions.length; i++) {
            if (subscriptions[i].owner == msg.sender) {
                count++;
            }
        }

        Subscription[] memory mySubscriptions = new Subscription[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < subscriptions.length; i++) {
            if (subscriptions[i].owner == msg.sender) {
                mySubscriptions[index] = subscriptions[i];
                index++;
            }
        }

        return mySubscriptions;
    }

    function cancelSubscription(uint256 index) external {
        Subscription storage subscription = subscriptions[index];
        require(msg.sender == subscription.owner, "Not the owner of the subscription");

        uint256 refundAmount = subscription.balance;
        subscription.balance = 0;

        payable(msg.sender).transfer(refundAmount);
    }

    function updateSubscription(uint256 index) external {
    Subscription storage subscription = subscriptions[index];

    // Fetch the latest price from the Pyth contract
    IPythStructs.Price memory newPriceData = pythContract.getPriceUnsafe(subscription.id);

    // Check if the timestamp threshold has been met
    require(block.timestamp >= subscription.latestUpdateTimestamp + subscription.timestampThreshold, "Timestamp threshold not met");

    // Check if the percent change threshold has been met
    int64 priceDifference = newPriceData.price - subscription.latestPriceData.price;
    int64 absPriceDifference = priceDifference >= 0 ? priceDifference : -priceDifference;
    int64 percentChange = int64(absPriceDifference * 100) / int64(subscription.latestPriceData.price);
    require(percentChange >= subscription.percentChangeThreshold, "Percent change threshold not met");

    // Calculate bounty and update balances
    uint256 bountyAmount = subscription.bountyAmount;
    require(subscription.balance >= bountyAmount, "Insufficient balance");
    subscription.balance -= bountyAmount;
    payable(msg.sender).transfer(bountyAmount);
    
    // Update the subscription
    subscription.latestPriceData = newPriceData;
    subscription.latestUpdateTimestamp = block.timestamp;

    // Emit event
    emit SubscriptionUpdated(
        subscription.id
        , newPriceData);
}

}