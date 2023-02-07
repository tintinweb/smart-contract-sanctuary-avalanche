// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract SubnetSafariRegistration is  Ownable {
    uint32 public startTimeStamp;
    uint64 public fee;
    uint32 public endTimeStamp;
    uint16[] public teamSizes;

    error CostNotCovered();
    error TooSoon();
    error TooLate();
    error AlreadyRegistered();
    
    event NewPlayer(address player, uint team);
    event DEBUG(string name, uint value);
    mapping (address => uint256) public teams;
    mapping (string => bytes32) public hiddenLootScores;

    constructor(){
        fee = 0.25 ether;
        teamSizes.push(0); // blank
        teamSizes.push(0); // team1
        teamSizes.push(0); // team2
        teamSizes.push(0); // team3
        teamSizes.push(0); // team4
        teamSizes.push(0); // total size
    }

    function setStartTimeStamp(uint _timeStamp) external onlyOwner {
        startTimeStamp = uint32(_timeStamp);
    }
    function setHiddenLootScores(string[] calldata loots, bytes32[] calldata hashes) external onlyOwner {
        for (uint256 i = 0; i < loots.length; i++) {
            hiddenLootScores[loots[i]] = hashes[i];
        }
    }

    function setFee(uint _fee) external onlyOwner {
        fee = uint64(_fee);
    }
    function setEndTimeStamp(uint _timeStamp) external onlyOwner {
        endTimeStamp = uint32(_timeStamp);
    }


    function register() payable external {
        if(teams[msg.sender] != 0) {
            revert AlreadyRegistered();
        }
        if(block.timestamp < startTimeStamp) {
            revert TooSoon();
        }
        if(block.timestamp > endTimeStamp) {
            revert TooLate();
        }
        if(msg.value < fee ) {
            revert CostNotCovered();
        }
        uint rng = getRandomWord(msg.sender);
        uint team = (rng % 4) + 1;
        team = balanceTeams(team);
        teams[msg.sender] = team;
        emit NewPlayer(msg.sender, team);
    }

    function balanceTeams(uint team) internal returns (uint){
        teamSizes[5]+=1;
        uint size = teamSizes[5];
        uint appropriateSize =  size /4;
        if(teamSizes[team] > appropriateSize)  {
            uint lastTeam = team + 4;
            for (uint256 i = team; i < lastTeam; ++i) {
                uint index = (i % 4) + 1;
                if(teamSizes[index] <= appropriateSize) {
                    teamSizes[index]+=1;
                    return index;
                }
            }
            return team;
        }
        else {
            teamSizes[team]+=1;
            return team;
        }
    }
    function getRandomWord(address user) internal view returns (uint256 randomWord) {
        uint256 rng = uint256(
            keccak256(
                abi.encodePacked(
                    // solhint-disable-next-line
                    block.timestamp,
                    user,
                    blockhash(block.number - 1)
                )
            )
        );
        return rng;
    
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);

    }
}