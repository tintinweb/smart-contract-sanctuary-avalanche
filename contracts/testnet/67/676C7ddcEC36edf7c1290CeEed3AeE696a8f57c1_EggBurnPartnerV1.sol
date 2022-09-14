// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/** The callback contract interface */
interface CallbackContract {
    function burnNotification(address _owner, uint256 _amount, uint256 _total) external;
}

/** EggContract interface */
interface EggContract {
    function transfer(address to, uint256 value) external returns (bool);
    function burnEggs(address sender, uint256 eggsAmount) external;
    function balanceOf(address) external returns (uint256);
}

/**
 * Contract responsible for tracking EGG burned.
 */
contract EggBurnPartnerV1 {

    // A no-operation subscriber, for those who don't want to implement a contract callback.
    address public NOOP_SUBSCRIBER = address(1);

    // variables
    EggContract public eggContract;
    uint256 public globalBurnTotal = 0;
    mapping(string => uint256) public burnBySubscriber;
    mapping(string => address) public callbackAddressBySubscriber;
    mapping(uint256 => string) public subscriberNamesByIndex;
    uint256 public count = 0;

    // events
    event EggBurned(uint256 ts, string sub, address wallet, uint256 amount);
    event Subscription(uint256 ts, string name, address addr);

    // constructor
    constructor(address _eggContract) {
        eggContract = EggContract(_eggContract);
    }

    // functions

    /**
     * Returns a paginated list of subscribers.
     */
    function getSubscribers(uint256 _pageNum) public view returns (string[] memory){
        uint PAGE_SIZE = 20;
        require(_pageNum >= 0, 'PAGE MUST BE POSITIVE');
        string[] memory names = new string[](PAGE_SIZE);
        uint start = _pageNum * PAGE_SIZE;
        uint end = start + PAGE_SIZE;
        for (uint i = start; i < count && i < end; i++) {
            names[i - start] = subscriberNamesByIndex[i];
        }
        return names;
    }

    /**
     * User calls - Allows a user to burn EGG, against a subscriber's name.
     */
    function burnEgg(string calldata _name, uint256 _amount) external {
        // amount must be a positive number
        require(_amount > 0, 'AMOUNT MUST BE POSITIVE');
        // verify we have a subscriber
        address callback = callbackAddressBySubscriber[_name];
        require(callback != address(0), 'NO SUBSCRIBER FOR NAME');
        // do burn
        eggContract.burnEggs(msg.sender, _amount);
        // update totals
        globalBurnTotal += _amount;
        burnBySubscriber[_name] += _amount;
        // notify subscriber
        if (callback != NOOP_SUBSCRIBER) {
            CallbackContract(callback).burnNotification(msg.sender, _amount, burnBySubscriber[_name]);
        }
        // fire event
        emit EggBurned(block.timestamp, _name, msg.sender, _amount);
    }

    /**
     * Subscriber Developer calls - Registers a single immutable "burnNotification" subscriber.
     */
    function subscribe(string calldata _name, address _callbackContractAddr) external {
        // only allow one subscriber
        require(callbackAddressBySubscriber[_name] == address(0), 'SUBSCRIBER ALREADY REGISTERED');
        // invoke subscriber, to verify the contract signature is callable
        if (_callbackContractAddr != NOOP_SUBSCRIBER) {
            CallbackContract(_callbackContractAddr).burnNotification(msg.sender, 0, 0);
        }
        // store subscriber contract address
        callbackAddressBySubscriber[_name] = _callbackContractAddr;
        // store subscriber names
        subscriberNamesByIndex[count++] = _name;
        // fire event
        emit Subscription(block.timestamp, _name, _callbackContractAddr);
    }

    function getBurnTotalBySubscriber(string calldata _name) public view returns (uint256) {
        return burnBySubscriber[_name];
    }

    function getAddressBySubscriber(string calldata _name) public view returns (address) {
        return callbackAddressBySubscriber[_name];
    }
}