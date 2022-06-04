/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-03
*/

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

interface IFly {
    function burn(address from, uint256 amount) external;
}

interface IFatTadpoleNFT {
    function mint(address _receiver) external;
}

interface ITadPoleNFT {
    function transferFrom(address from,address to,uint256 id)  external;
    function tadpoles(uint x) external returns (uint128,uint64,uint56,uint8);
}

contract FattestTadpole {
    // Addresses
    address public immutable FLY;
    address public immutable TADPOLE;
    address public immutable FAT_TADPOLE;
    uint256 public immutable period = 5 minutes;
    uint256 public startTs = 0;
    uint256 public cycle = 0;
    address public owner;
    Winner public currentWinner;

    struct Winner {
        address adr;
        uint256 points;
    }

    struct TadpoleOwner {
        uint256 tokenId;
        bool staked;
    }

    // Mappings
    mapping(address => TadpoleOwner) public tadpoleOwners;
    mapping(uint256 => mapping(address => uint256)) public cyclePoints;
    mapping(address => uint256) public historicalWinners;

    // Events
    event UpdatedOwner(address indexed owner);
    event WinnerChanged(Winner winner);
    event CycleFinished(uint256 cycle, Winner winner);
    event FlyAdded(uint amount, uint tokenId);
    event Entered(uint tokenId);
    event Exited(uint tokenId);

    // Errors
    error Unauthorized();
    error WrongTokenID();
    error NotStarted();
    error AlreadyStarted();
    error NothingToClaim();
    error AlreadyStaked();

    constructor(address fly, address tadpole, address fatTadpole) {
        owner = msg.sender;
        FLY = fly;
        TADPOLE = tadpole;
        FAT_TADPOLE = fatTadpole;
    }

    // Methods
    function isStarted() external view returns (bool) {
        unchecked {
            return (startTs + period) > block.timestamp;
        }
    }

    function _isStarted() private view returns (bool) {
        unchecked {
            return (startTs + period) > block.timestamp;
        }
    }

    function start() external {
        if (_isStarted()) {
            revert AlreadyStarted();
        }
        if (currentWinner.points > 0) {
            unchecked {
                historicalWinners[currentWinner.adr]++;
            }
            tadpoleOwners[currentWinner.adr].staked = false; // tadpole locked
            emit CycleFinished(cycle, currentWinner);
        }
        currentWinner = Winner({
            adr: address(0),
            points: 0
        });
        unchecked {
            cycle++;
        }
        startTs = block.timestamp;
    }

    function canClaim() external view returns (bool) {
        return historicalWinners[msg.sender] > 0;
    }

    function claim() external {
        if (historicalWinners[msg.sender] == 0) {
            revert NothingToClaim();
        }
        uint256 claimAmount = historicalWinners[msg.sender];
        for (uint256 i = 0; i < claimAmount; i++) {
            IFatTadpoleNFT(FAT_TADPOLE).mint(msg.sender);
            unchecked {
                historicalWinners[msg.sender]--;
            }
        }
    }

    function enter(uint256 tokenId) external {
        if (!_isStarted()) {
            revert NotStarted();
        }
        if (tadpoleOwners[msg.sender].staked) {
            revert AlreadyStaked();
        }
        tadpoleOwners[msg.sender] = TadpoleOwner({
            tokenId: tokenId,
            staked: true
        });
        ITadPoleNFT(TADPOLE).transferFrom(msg.sender, address(this), tokenId);
        cyclePoints[cycle][msg.sender] = 0;
        emit Entered(tokenId);
    }

    function exit() external {
        if (!tadpoleOwners[msg.sender].staked) {
            revert WrongTokenID();
        }
        uint256 tokenId = tadpoleOwners[msg.sender].tokenId;
        ITadPoleNFT(TADPOLE).transferFrom(address(this), msg.sender, tokenId);
        cyclePoints[cycle][msg.sender] = 0;
        delete tadpoleOwners[msg.sender];
        emit Exited(tokenId);
    }

    function getUserPoints() external view returns (uint256) {
        return cyclePoints[cycle][msg.sender];
    }

    function getUserPoints(address user) external view returns (uint256) {
        return cyclePoints[cycle][user];
    }

    function addFlies(uint256 flies) external {
        if (!_isStarted()) {
            revert NotStarted();
        }
        if (!tadpoleOwners[msg.sender].staked) {
            revert WrongTokenID();
        }
        uint256 tokenId = tadpoleOwners[msg.sender].tokenId;
        IFly(FLY).burn(msg.sender, flies);
        (uint128 rarity, , ,) = ITadPoleNFT(TADPOLE).tadpoles(tokenId);
        unchecked {
            uint256 points = flies + ((flies * rarity) / 10);
            cyclePoints[cycle][msg.sender] += points;
        }
        if (cyclePoints[cycle][msg.sender] > currentWinner.points) {
            currentWinner.adr = msg.sender;
            currentWinner.points = cyclePoints[cycle][msg.sender];
            emit WinnerChanged(currentWinner);
        }
        emit FlyAdded(flies,tokenId);
    }
}