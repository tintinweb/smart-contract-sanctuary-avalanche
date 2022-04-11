//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.4;

import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ERC20.sol";

import "./Crop.sol";
import "./FarmV3.sol";


contract LocustGod is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    // constants
    uint256 public LOCUST_GOD_DELAY = 5 days;
    uint256 public LOCUST_GOD_PRICE = 1000 * 1e18;
    uint256 public TOP_LIST_SIZE;
    uint256 public WINNER_SIZE;
    address public FARM_ADDRESS;
    address public CROP_ADDRESS;

    // LocustGod Winners
    struct Winner {
        address who;
        uint256 amount;
    }

    struct LocustGodEvent {
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
        mapping(address=>uint256) userDonations;
        mapping(uint256=>Winner) winners;
    }

    mapping (uint256=>LocustGodEvent) public events; // eventId -> event.

    uint256 public currLocustGodEventID;
    uint256 public lastEndTimestamp;
    bool public isLocustActive;
    bool public AutomaticMode = true;

    // Events

    event eventStarted(uint256 when, uint256 eventID);
    event eventStopped(uint256 when, uint256 eventID);
    event donated(address who, uint256 amount);

    constructor (uint256 timestamp) {
        lastEndTimestamp = timestamp;
        TOP_LIST_SIZE = 5;
        WINNER_SIZE = 5;
    }

    function checkEventDeposits(uint256 eventId, address user) external view returns(uint256) {
        return events[eventId].userDonations[user];
    }

    function startEvent() internal {
        require ((block.timestamp >= (lastEndTimestamp + LOCUST_GOD_DELAY)), "NO DELAY");
        require (!isLocustActive, "LOCUST ACTIVE");
        events[currLocustGodEventID].startTime = block.timestamp;
        isLocustActive = true;
        emit eventStarted(block.timestamp, currLocustGodEventID);
        return;
    }

    function endEvent() internal {
        require(events[currLocustGodEventID].amount >= LOCUST_GOD_PRICE, "SACRIFICE NOT MEET");
        events[currLocustGodEventID].endTime = block.timestamp;
        lastEndTimestamp = block.timestamp;
        isLocustActive = false;
        emit eventStopped(block.timestamp, currLocustGodEventID);
        currLocustGodEventID = currLocustGodEventID + 1;
        return;
    }

    function checkAndStart() external {
        if (AutomaticMode) {
            if ((block.timestamp >= (lastEndTimestamp + LOCUST_GOD_DELAY))) {
                if (!isLocustActive) {
                    startEvent();
                }
            }
        }
    }

    function donateCrop(uint256 amount) external {
        require(isLocustActive, "LOCUST INACTIVE");
        Crop(CROP_ADDRESS).burn(msg.sender, amount);
        events[currLocustGodEventID].amount = events[currLocustGodEventID].amount + amount;
        events[currLocustGodEventID].userDonations[msg.sender] = events[currLocustGodEventID].userDonations[msg.sender] + amount;

        // Insert new winner.
        address tmpAddr;
        uint256 tmpIndex = 0;
        bool breaked;
        for (uint256 i = 0; i < TOP_LIST_SIZE; ++i) {
            if (events[currLocustGodEventID].userDonations[msg.sender] > events[currLocustGodEventID].winners[i].amount) {
                if (events[currLocustGodEventID].winners[i].who != msg.sender) {
                    breaked = true;
                }
                tmpIndex = i + 1;
                tmpAddr = events[currLocustGodEventID].winners[i].who;
                events[currLocustGodEventID].winners[i].amount = events[currLocustGodEventID].userDonations[msg.sender];
                events[currLocustGodEventID].winners[i].who = msg.sender;
                break;
            }
        }
        
        // Sort it again.
        if (breaked) {
            for (; tmpIndex < TOP_LIST_SIZE; ++tmpIndex) {
                address nextAddress = events[currLocustGodEventID].winners[tmpIndex].who;
                events[currLocustGodEventID].winners[tmpIndex].who = tmpAddr;
                events[currLocustGodEventID].winners[tmpIndex].amount = events[currLocustGodEventID].userDonations[tmpAddr];
                tmpAddr = nextAddress;
            }
        }

        if(events[currLocustGodEventID].amount >= LOCUST_GOD_PRICE) {
            endEvent();
        }
        emit donated(msg.sender, amount);
    }

    function eventWinners(uint256 eventID) external view returns(Winner[] memory) {
        Winner[] memory ret = new Winner[](TOP_LIST_SIZE);
        for (uint i = 0; i < TOP_LIST_SIZE; ++i) {
            ret[i] = events[eventID].winners[i];
        }
        return ret;
    }

    function setFarmAddress(address farmAddress) external onlyOwner() {
        FARM_ADDRESS = farmAddress;
    }

    function setCropAddress(address cropAddress) external onlyOwner() {
        CROP_ADDRESS = cropAddress;
    }

    function setLocustGodDelay(uint256 newDelay) external onlyOwner() {
        LOCUST_GOD_DELAY = newDelay;
    }

    function setLocustGodPrice(uint256 newPrice) external onlyOwner() {
        LOCUST_GOD_PRICE = newPrice;
    }

    function setTopListSize(uint256 newSize) external onlyOwner() {
        TOP_LIST_SIZE = newSize;
    }

    function setWinnerListSize(uint256 newSize) external onlyOwner() {
        WINNER_SIZE = newSize;
    }

    function toggleMode(bool newMode) external onlyOwner() {
        AutomaticMode = newMode;
    }

    function adminStartEvent() external onlyOwner() {
        startEvent();
    }
}