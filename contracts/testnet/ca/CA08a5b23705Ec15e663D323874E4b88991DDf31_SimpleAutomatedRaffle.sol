/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-16
*/

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol


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

// File: @chainlink/contracts/src/v0.8/KeeperBase.sol


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

// File: @chainlink/contracts/src/v0.8/KeeperCompatible.sol


pragma solidity ^0.8.0;



abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// File: contracts/extensions/RafflePurchaseable.sol


pragma solidity ^0.8.9;

/** 
 * @title RafflePurchaseable
 * @notice Provides utilities to process raffle entry purchases
 */
abstract contract RafflePurchaseable {

    uint256 public balance;

    uint256 public price;

    function _purchase(uint256 quantity_) internal virtual {
        require(msg.value >= quantity_ * price, "amount must be at least quantity times price");
        balance += msg.value;
    }

    /**
    * @notice Sends contract balance to the winner; override for custom logic
    * @param winner The winners address
    */
    function _sendWinnings(address winner) internal virtual {
        _beforeSendWinnings();

        uint256 _toSend = balance;
        balance = 0;
        payable(winner).transfer(_toSend);
        
        _afterSendWinnings();
    }

    function _setPrice(uint256 price_) internal virtual {
        price = price_;
    }

    function _beforeSendWinnings() internal virtual {}

    function _afterSendWinnings() internal virtual {}

}

// File: contracts/Raffle.sol


pragma solidity ^0.8.9;

/**
 * @title Raffle
 * @notice Provides a basic raffle system
 */
abstract contract Raffle {
    // Emits a purchased raffle entry event
    event RaffleEntry(address indexed purchaser, uint256 quantity);

    // Emits a winner event with the winner address
    event RaffleWinner(address indexed winner);

    // an Entry represents a single entry purchase for a raffle
    struct Entry {
        address player;
    }

    // owner is the creator of the contract and is used for permissioned function calls
    address private _owner;

    // winner of the most recent raffle
    address private winner;

    // collection of entries for the current raffle
    Entry[] private _entries;

    /**
     * @notice Returns the total number of entries for the active raffle
     */
    function getEntryCount() public view returns (uint256) {
        return _entries.length;
    }

    /**
     * @notice Returns the most recent raffle winner
     */
    function getWinner() public view returns (address) {
        return winner;
    }

    /**
     * @notice Adds the entries to the private list of entries
     * @param qnty The number of entries to add for sender
     */
    function _enter(uint16 qnty) internal virtual {
        for (uint i = 0; i < qnty; i++) {
            _entries.push(Entry({player: msg.sender}));
        }

        emit RaffleEntry(msg.sender, qnty);
    }

    /**
     * @notice Provides logic to pick a winner from the list of entries
     * @param idx The index of the winner in the list of entries
     */
    function _pickWinner(uint256 idx) internal returns (address) {
        require(idx >= 0 && idx < _entries.length, "winner out of bounds");
        // collect winner info before modifying state
        Entry memory _winner = _entries[idx];

        // modify internal contract state before transfering funds
        delete _entries;

        // allow custom logic for extended cleanup
        _afterPickWinner(_winner.player);

        return _winner.player;
    }

    /**
     * @notice Cleanup function for after winner has been picked
     */
    function _afterPickWinner(address newWinner) internal virtual {
        winner = newWinner;
        emit RaffleWinner(newWinner);
    }
}

// File: contracts/extensions/RaffleRandomPick.sol


pragma solidity ^0.8.9;


/** 
 * @title RaffleRandomPick
 * @notice Provides a random pick from available entries
 */
abstract contract RaffleRandomPick is Raffle {

    function _randomPickWinner() internal virtual {
        uint256 idx = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))%getEntryCount();
        _pickWinner(idx);
    }

}

// File: contracts/extensions/RaffleAutomatable.sol


pragma solidity ^0.8.9;



/** 
 * @title RaffleAutomatable
 * @notice Implements keepers interface for automation
 *
 * Steps to include this extension into a simple Raffle
 *
 * 1. Include RaffleAutomatable and RaffleRandomPick into a simple Raffle contract
 *
 * 2. Implement _runRaffleAutomation to call _randomPickWinner
 *
 * 3. Add _setInterval to the Raffle constructor with an interval value (3000 seconds)
 *
 * 4. Deploy and verify the contract
 *
 * 5. Go to keepers.chain.link
 *
 * 6. Connect Metamask to Ethereum Goerli
 *
 * 7. Register a new custom logic upkeep
 *
 * 8. Play the raffle!
 */
abstract contract RaffleAutomatable is Raffle, KeeperCompatibleInterface {

    uint256 public interval; // the interval at which this contract should run
    
    uint256 public lastRafflePick; // the last time stamp a winner was picked

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
    function checkUpkeep(bytes calldata checkData) external view override returns(bool upkeepNeeded, bytes memory) {
        upkeepNeeded = _upkeepNeeded();
    }

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
    function performUpkeep(bytes calldata performData) external override {
        if (_upkeepNeeded()) {
            _runRaffleAutomation();
        }
    }

    function _setInterval(uint256 interval_) internal virtual {
        interval = interval_;
    }

    /**
    * @notice Override this function for custom automation logic; returns whether automation should run or not
    */
    function _upkeepNeeded() internal view virtual returns(bool) {
        return (block.timestamp - lastRafflePick) > interval;
    }

    function _runRaffleAutomation() internal virtual;

}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/presets/SimpleAutomatedRaffle.sol


pragma solidity ^0.8.9;






/** 
 * @title SimpleAutomatedRaffle
 * @dev Provides a complete raffle system where entries are purchased at the entry
 *      price, the winner is selected externally, and the balance of all entries
 *      is sent to the winner.
 */
contract SimpleAutomatedRaffle is Ownable, Raffle, RafflePurchaseable, RaffleRandomPick, RaffleAutomatable {

    constructor(uint256 entryCost_) {
        price = entryCost_;
        _setInterval(180);
    }

    receive() external payable {
        _enter(1);
    }

    fallback() external payable {
        _enter(1);
    }
    
    /**
    * @notice Adds the sender to the list of raffle entries
    * @param qnty The number of entries to add for sender
    */
    function enter(uint16 qnty) external payable {
        _enter(qnty);
    }

    function pickWinner(uint256 idx) external onlyOwner returns(address) {
        address _winner = _pickWinner(idx);
        _sendWinnings(_winner);
        return _winner;
    }

    function _enter(uint16 qnty) internal override {
        _purchase(qnty);
        super._enter(qnty);
    }

    function _runRaffleAutomation() internal override {
        _randomPickWinner();
        _sendWinnings(getWinner());        
    }

}