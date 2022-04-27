/**
 *Submitted for verification at snowtrace.io on 2022-04-27
*/

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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

abstract contract Pausable is Context {

    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor() {
        _paused = false;
    }

    function paused() public view virtual returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Lottery is Ownable, Pausable {
    uint32 public numWords = 3;
    uint256 public ticketPrice = 1 ether;

    uint256 public lotteryID = 1;
    mapping(uint256 => address[]) lotteryWinners;
    mapping(uint256 => uint256) potSizes;
    mapping(uint256 => uint256) endTimes;

    address[] public players;

    address public tokenAddress = 0xE06Fc0f559B9a8E61943898b6099220C8210725e;
    IERC20 token;

    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    mapping(uint256 => mapping(address => uint256)) public numTicketsBought;

    uint256 public winnerShare = 750;
    uint256 public shareDenominator = 1000;

    constructor() {
        token = IERC20(tokenAddress);
        _pause();
    }

    function totalEntries() external view returns (uint256) {
        return players.length;
    }

    function pastEntries(uint256 _id) external view returns (uint256) {
        return potSizes[_id];
    }

    function userEntries(address user) external view returns (uint256) {
        return numTicketsBought[lotteryID][user];
    }

    function previousWinner() external view returns(address[] memory) {
        require(lotteryID > 1, "No winners yet");
        return lotteryWinners[lotteryID - 1];
    }

    function pastWinner(uint256 _id) external view returns(address[] memory) {
        require(_id < lotteryID, "No winners yet");
        return lotteryWinners[_id];
    }

    function endTime(uint256 _id) external view returns (uint256) {
        return endTimes[_id];
    }

    function isActive() external view returns (bool) {
        return (endTimes[lotteryID] > block.timestamp) && !paused();
    }

    function enter(uint256 tickets) external whenNotPaused {
        require(tickets > 0, "Must make at least one entry");
        require(endTimes[lotteryID] > block.timestamp, "Lottery is over");

        numTicketsBought[lotteryID][msg.sender] += tickets;

        for (uint256 i = 0; i < tickets; i++) {
            players.push(msg.sender);
        }

        token.transferFrom(msg.sender, address(this), tickets * ticketPrice);
    }

    function start(uint256 _endTime) external onlyOwner {
        require(_endTime > block.timestamp, "End time must be in the future");
        endTimes[lotteryID] = _endTime;
        _unpause();
    }

    function closeLottery() external onlyOwner {
        require(players.length > 0);
        require(block.timestamp >= endTimes[lotteryID], "Lottery is not over");

        _pause();
        potSizes[lotteryID] = players.length;
    }

    function drawLottery(uint256[] memory _randomWords) public onlyOwner {
        for (uint256 index; index < numWords; index++) {
            require(_randomWords[index] > 0, "Randomness not set");
        }

        if (players.length > 0) {
            uint256 totalAmount = players.length * ticketPrice;
            uint256 winnerAmount = (totalAmount * winnerShare) / shareDenominator / numWords;
            uint256 burnAmount = totalAmount - winnerAmount * numWords;
            
            for (uint256 index; index < numWords; index++) {
                uint256 i = _randomWords[index] % players.length;
                lotteryWinners[lotteryID].push(players[i]);
                token.transfer(players[i], winnerAmount);
            }

            token.transfer(burnAddress, burnAmount);
        }

        lotteryID++;
        players = new address[](0);
    }

    function setTicketPrice(uint256 _ticketPrice) public onlyOwner {
        ticketPrice = _ticketPrice;
    }
}