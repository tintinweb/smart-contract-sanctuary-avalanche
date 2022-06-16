/**
 *Submitted for verification at snowtrace.io on 2022-06-16
*/

/**
 *Submitted for verification at snowtrace.io on 2022-06-14
*/

pragma solidity ^0.8.9;

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IStrategy {
    function harvest() external;

    function getHarvestable() external view returns (uint256);
}

contract Harvester is Ownable {

    uint32 hour = 3600;
    uint32 day = 86400;

    enum TimingWindow { 
        hour,
        day,
        custom
    }

    struct TimeWindow { 
        TimingWindow timingWindow;
        uint256 value;
    }

    struct Strategy {
        //check for default values
        bool initialized;
        // The last time(timestamp) this strategy was harvested 
        uint256  lastHarvest;
        // The time window in which this strategy can be call in
        TimeWindow timeWindow;
    }
    
    // Current strategies that have been called at least once.
    mapping (address => Strategy) strategies; 
   
    // Event to emit on each call to harvest
    event harvested(address strategy, uint256 timestamp);

    function harvest(address _strategyAddress) public {
        require(_strategyAddress == address(_strategyAddress), "Harvester:!address");

	(bool _canCall,Strategy storage _strat) = validateHarvest(strategies[_strategyAddress]);
        require(_canCall,'Harvester:!harvest');

        if (!_strat.initialized) { 
            _strat.timeWindow.timingWindow = TimingWindow.hour;
            _strat.timeWindow.value = hour;
            _strat.initialized = true;
        }

	IStrategy(_strategyAddress).harvest();
        strategies[_strategyAddress] = _strat;

        emit harvested(_strategyAddress,_strat.lastHarvest);
    }

    // Get the timestamp when this strategy was last harvested 
    function lastHarvested(address _strategyAddress) public view returns (uint256) { 
        return strategies[_strategyAddress].lastHarvest;
    }

    // Get the current harvest window for strategy
    function harvestWindow(address _strategyAddress) public view returns (uint256) { 
        return strategies[_strategyAddress].timeWindow.value;
    }

    // Get the current harvestable for strategy
    function harvestable(address _strategyAddress) public view returns (uint256) { 
        return IStrategy(_strategyAddress).getHarvestable();
    }

    // Check if we can call harvest and sets the last harvested time on the strategy if needed
    function validateHarvest(Strategy storage _strat) private returns (bool,Strategy storage) {
        uint256 timeWindow = block.timestamp - _strat.timeWindow.value;

        if (_strat.lastHarvest == 0 || _strat.lastHarvest >= timeWindow) {
            _strat.lastHarvest = block.timestamp; 
            return (true, _strat);
        }

        return (false, _strat);
    }

    function setTimeWindowFor(address _strategyAddress,TimingWindow _timingWindow, uint256 _value) public onlyOwner {
        Strategy storage _strat = strategies[_strategyAddress];
        if (_timingWindow == TimingWindow.custom) { 
            require(_value > 0);
            _strat.timeWindow.timingWindow = TimingWindow.custom;
            _strat.timeWindow.value = _value;
        }

        if (_timingWindow == TimingWindow.hour) { 
            _strat.timeWindow.timingWindow = TimingWindow.hour;
            _strat.timeWindow.value = hour;
        }

        if (_timingWindow == TimingWindow.day) { 
            _strat.timeWindow.timingWindow = TimingWindow.day;
            _strat.timeWindow.value = day;
        }
	strategies[_strategyAddress] = _strat;
    }
}