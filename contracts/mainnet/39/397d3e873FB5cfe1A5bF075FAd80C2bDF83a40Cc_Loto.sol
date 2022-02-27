/**
 *Submitted for verification at snowtrace.io on 2022-02-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract Loto is Ownable, Pausable {
    uint256 public TICKET_PRICE = 500000000000000000;
    uint256 public TICKET_PRICE_WL = 40000000000000000;
    uint256 public TICKET_PRICE_UPDATE_COUNT = 10;
    uint256 public oneHundred = 100;
    uint256 public TICKET_WL_NB_TICKET = 1;

    uint256 public ticketCount = 0;
    uint256 public currentAmount = 0;
    uint256 public totalAmountRedistributed = 0;


    bool public ended = false;
    uint256 WLTicket = 0;

    uint256 public winnerCount = 0;
    mapping(uint256 => WinTicket) public winners;
    mapping(uint256 => WinTicket) public winnersWL;
    mapping(uint256 => Ticket) public tickets;

    struct Ticket {
        uint256 id;
        uint256 date;
        uint256 percent;
        address payable owner;
    }

    struct WinTicket {
        uint256 date;
        uint256 percent;
        address payable owner;
        uint256 amount;
    }

    event DrawEvent(uint256 price, address payable winner);
    event TicketCreated(uint256 id, uint256 price, address payable owner);

    constructor() public {}

    function buyTicket() public payable {
        require(ended == false);
        uint256 price = ticketPrice(msg.sender);
        require(msg.value >= price);

        tickets[ticketCount] = Ticket(
            ticketCount,
            block.timestamp,
            percent(),
            payable(msg.sender)
        );
        currentAmount += price;
        ticketCount++;
        if (winnerCount > 0 && lastWLWinner().owner == msg.sender) {
            WLTicket += 1;
        }
        emit TicketCreated(ticketCount, price, payable(msg.sender));
    }

    function reset() public onlyOwner {
        require(ended == true);
        require(msg.sender == owner());
        for (uint32 i = 0; i < ticketCount; i++) {
            delete tickets[i];
        }
        ticketCount = 0;
        currentAmount = 0;
        WLTicket = 0;
        ended = false;
    }

    function draw() public payable onlyOwner {
        require(ended == false);
        require(msg.sender == owner());
        require(ticketCount > 0);

        uint256 randomNum = random(ticketCount);
        uint256 randomWLNum = random(ticketCount);
        ended = true;

        uint256 amountToRedistribute = (currentAmount * tickets[randomNum].percent) / oneHundred;
        uint256 fee = (currentAmount * (oneHundred - tickets[randomNum].percent)) / oneHundred;

        winners[winnerCount] = WinTicket(
            block.timestamp,
            percent(),
            payable(msg.sender),
            amountToRedistribute
        );

        winnersWL[randomWLNum] = WinTicket(
            block.timestamp,
            percent(),
            payable(msg.sender),
            0
        );

        winnerCount += 1;

        totalAmountRedistributed += amountToRedistribute;
        tickets[randomNum].owner.transfer(amountToRedistribute);
        payable(owner()).transfer(fee);

        emit DrawEvent(amountToRedistribute, payable(tickets[randomNum].owner));
    }

    function ticketPrice(address add) public view returns (uint256) {
        if (
            winnerCount > 0 &&
            lastWLWinner().owner == add &&
            WLTicket < TICKET_WL_NB_TICKET
        ) {
            return TICKET_PRICE_WL;
        } else {
            return TICKET_PRICE;
        }
    }

    function percent() public view returns (uint256) {
        if (ticketCount <= (TICKET_PRICE_UPDATE_COUNT * 1) / 5) return 90;
        if (ticketCount <= (TICKET_PRICE_UPDATE_COUNT * 2) / 5) return 85;
        if (ticketCount <= (TICKET_PRICE_UPDATE_COUNT * 4) / 5) return 80;
        return 75;
    }

    function lastWinner() public view returns (WinTicket memory) {
        return winners[winnerCount - 1];
    }

    function lastWLWinner() public view returns (WinTicket memory) {
        return winnersWL[winnerCount - 1];
    }

    function random(uint256 max) private view returns (uint8) {
        return
            uint8(uint256(keccak256(abi.encodePacked(block.timestamp))) % max);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}