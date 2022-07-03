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
    uint256 public constant period = 3 days;
    uint256 public constant step = 3; // 30 percent
    uint256 public constant reward = 1; // 10 percent
    uint256 public enterAmount = 100 ether;
    uint256 public startTs;
    uint256 public cycle = 0;
    address public owner;
    Winner public currentWinner;
    mapping (uint => King) public oldKings;


    struct Winner {
        address adr;
        uint256 flies;
        string message;
    }

    struct King {
        address adr;
        string message;
        uint cycle;
        uint flies;
        
    }

    // Events
    event UpdatedOwner(address indexed owner);
    event WinnerChanged(Winner winner);
    event NewKing(King king);

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

    function restart() internal {
        if (cycle == 0){
            cycle++;
        }
        else {
            oldKings[cycle].cycle = cycle;
            oldKings[cycle].adr = currentWinner.adr;
            oldKings[cycle].message =  currentWinner.message;
            oldKings[cycle].flies = currentWinner.flies; 
            emit NewKing(oldKings[cycle]); 
            currentWinner = Winner(address(0), 0, '');
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
    // either send an empty string with ethers.js 
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
        currentWinner = Winner(msg.sender, amount, message);
        startTs = block.timestamp;
        emit WinnerChanged(currentWinner);
    }


}