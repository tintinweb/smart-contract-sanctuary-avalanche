// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

// Fly 0x6136dc5c7898fad266224b6e4bcc10d5ef79ec59
// KOTH 0x42e875caa1ed80b9c060c4b3ba59a8e7da4ca481

interface IFly {
    function burn(address from, uint256 amount) external;
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract KOTH {
    address public immutable FLY;
    uint256 public constant period = 15 minutes;
    uint256 public constant step = 3; // 30 percent
    uint256 public constant reward = 1; // 10 percent
    uint256 public enterAmount = 100 ether;
    uint256 public startTs;
    uint256 public cycle = 0;
    address public owner;
    Winner public currentWinner;
    mapping (address => OldKing) public oldKings;
    mapping (uint => address) public cycleToKing;

    struct Winner {
        address adr;
        uint256 flies;
        string message;
        bool messageSent;
    }

    struct OldKing {
        string message;
        uint cycle;
        bool messageSent;
    }

    // Events
    event UpdatedOwner(address indexed owner);
    event WinnerChanged(Winner winner);
    event NewKing(uint256 cycle, Winner winner);

    // Errors
    error Unauthorized();
    error NotEligableToWrite();
    

    constructor(address fly) {
        owner = msg.sender;
        FLY = fly;
    }

    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    // Management methods
    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function setEnterAmount(uint256 amount) external onlyOwner {
        enterAmount = amount;
    }

    // Methods
    function isTimeUp() external view returns (bool) {
        unchecked {
            return block.timestamp > (startTs + period);
        }
    }

    function _isTimeUp() private view returns (bool) {
        unchecked {
            return block.timestamp > (startTs + period);
        }
    }

    function writeMessage(string calldata message) external {
        if(currentWinner.adr == msg.sender && !currentWinner.messageSent) { // current winner,
            currentWinner.message = message;
            currentWinner.messageSent = true;
        }
        else if(oldKings[msg.sender].cycle > 0 && !(oldKings[msg.sender].messageSent)) { // king
            oldKings[msg.sender].message = message;
            oldKings[msg.sender].messageSent = true;
        }
        else {
            revert NotEligableToWrite();
        }


    }

    function restart() internal {
        if (cycle == 0){
            cycle++;
        }
        else {
            oldKings[currentWinner.adr].cycle = cycle;
            cycleToKing[cycle] = currentWinner.adr;
            if(currentWinner.messageSent) {
                oldKings[currentWinner.adr].message = currentWinner.message;
                oldKings[currentWinner.adr].messageSent = true;
            }
            currentWinner.adr = address(0);
            currentWinner.flies = 0;
            currentWinner.message = "";
            currentWinner.messageSent = false;
            emit NewKing(cycle, currentWinner);
            cycle++;
        }
    }

    function getEnterAmount() public view returns (uint256) {
        if (_isTimeUp()) {
            return enterAmount;
        }
        unchecked {
            return currentWinner.flies + ((currentWinner.flies * step) / 10);
        }
    }

    function enter(string calldata message) external {
        if(_isTimeUp()){
           restart();
        }
        uint256 amount = getEnterAmount();
        uint256 burnAmount = amount;
        if (currentWinner.flies > 0) {
            // We have a winner
            unchecked {
                uint256 rewardAmount = currentWinner.flies + ((currentWinner.flies * reward) / 10);
                IFly(FLY).transferFrom(msg.sender, currentWinner.adr, rewardAmount);
                burnAmount = amount - rewardAmount;
            }
        }
        IFly(FLY).burn(msg.sender, burnAmount);
        currentWinner.adr = msg.sender;
        currentWinner.flies = amount;
        if(bytes(message).length > 0) {
            currentWinner.message = message;
            currentWinner.messageSent = true;
        }
        startTs = block.timestamp;
        emit WinnerChanged(currentWinner);
    }
}