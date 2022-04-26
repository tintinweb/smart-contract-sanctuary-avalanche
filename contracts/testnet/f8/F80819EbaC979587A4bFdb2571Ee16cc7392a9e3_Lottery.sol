/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-25
*/

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


/**
  * @Lottery.sol
  *
  * The smart contract is about a Lottery Game on blockchain
  * which allows owner of the contract to instantiate the lottery and have
  * the first ticket on his name, as soon as all tickets are sold out, a
  * winner is declared via Event and the winningAmount is transferred to
  * the winner's address.
  * Incase, all tickets doesn't get sold, so owner has the functionality to
  * end the lottery, which would find the winner at that particular point and
  * send the winningAmount to winner's address.
 */


/** Lottery Smart Contract.*/
contract Lottery is Ownable {
    uint internal numTickets;
    uint internal availTickets;
    uint internal ticketPrice;
    uint internal winningAmount;
    bool internal gameStatus;
    uint internal counter;

    // mapping to have counter to address value.
    mapping (uint => address) internal players;
    // mapping to have address to bool value.
    mapping (address => bool) internal playerAddresses;

    address public winnerAddress;

    // Event which would be emmitted once winner is found.
    event Winner(uint indexed counter, address winner, string mesg);

    /** getLotteryStatus function returns the Lotter status.
      * @return numTickets The total # of lottery tickets.
      * @return availTickets The # of available tickets.
      * @return ticketPrice The price for one lottery ticket.
      * @return gameStatus The Status of lottery game.
      * @return contractBalance The total available balance of the contract.
     */
    function getLotteryStatus() public view returns(uint, uint, uint, bool, uint) {
        return (numTickets, availTickets, ticketPrice, gameStatus, winningAmount);
    }

    /** startLottery function inititates the lottery game with #tickets and ticket price.
      * @param tickets - no of max tickets.
      * @param price - price of the ticket.
     */
    function startLottery(uint tickets, uint price) public payable onlyOwner {
        if ((tickets <= 1) || (price == 0) || (msg.value < price)) {
            revert();
        }
        numTickets = tickets;
        ticketPrice = price;
        availTickets = numTickets - 1;
        // players[++counter] = owner;
        // increase the winningAmount
        winningAmount += msg.value;
        // set the gameStatus to True
        gameStatus = true;
        // playerAddresses[owner] = true;
    }

    /** function playLotter allows user to buy tickets and finds the winnner,
      * when all tickets are sold out.
     */
    function playLottery() public payable {
        // revert in case user already has bought a ticket OR,
        // value sent is less than the ticket price OR,
        // gameStatus is false.
        if ((playerAddresses[msg.sender]) || (msg.value < ticketPrice) || (!gameStatus)) {
            revert();
        }
        availTickets = availTickets - 1;
        players[++counter] = msg.sender;
        winningAmount += msg.value;
        playerAddresses[msg.sender] = true;
        // reset the Lotter as soon as availTickets are zero.
        if (availTickets == 0) {
            resetLottery();
        }
    }

    /** getGameStatus function to get value of gameStatus.
      * @return gameStatus - current status of the lottery game.
     */
    function getGameStatus() public view returns(bool) {
        return gameStatus;
    }

    /** endLottery function which would be called only by Owner.
     */
    function endLottery() public onlyOwner {
        resetLottery();
    }

    /** getWinner getter function.
      * this calls getRandomNumber function and
      * finds the winner using players mapping
     */
    function getWinner() internal {
        uint winnerIndex = getRandomNumber();
        winnerAddress = players[winnerIndex];
        emit Winner(winnerIndex, winnerAddress, "Winner Found!");
        payable(winnerAddress).transfer(winningAmount);
    }

    /** getRandomNumber function, which finds the random number using counter.
     */
    function getRandomNumber() internal view returns(uint) {
        uint random = uint(blockhash(block.number-1))%counter + 1;
        return random;
    }

    /** resetLottery function resets lottery and find the Winner.
     */
    function resetLottery() internal {
        gameStatus = false;
        getWinner();
        winningAmount = 0;
        numTickets = 0;
        availTickets = 0;
        ticketPrice = 0;
        counter = 0;
    }
}