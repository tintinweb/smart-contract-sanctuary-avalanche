/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-03
*/

// SPDX-License-Identifier: GPL-3.0
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

contract GiveawayTrackerTest is Ownable {

  struct GiveawayWinners {
    uint256 id;
    string drawNumber;
    string drawDate;
    string tokenId;
    string winningAddress;
    string giveawayDescription;
  }


  GiveawayWinners[] public winners;

  uint256 public giveawayCount = 0;


  function getGiveawayWinnerTest() public view returns (GiveawayWinners[] memory) {
      GiveawayWinners[] memory trrips = new GiveawayWinners[](giveawayCount);
      for (uint i = 0; i < giveawayCount; i++) {
          GiveawayWinners storage trrip = winners[i];
          trrips[i] = trrip;
      }
      return trrips;
  }


  function enterGiveawayWinner(string memory drawNumber, string memory drawDate, string memory tokenId, string memory winningAddress, string memory giveawayDescription) public onlyOwner {
    winners.push(GiveawayWinners(giveawayCount, drawNumber, drawDate, tokenId, winningAddress, giveawayDescription));
    giveawayCount++;
  }
  

  function getGiveawayWinner(uint256 id) view  public onlyOwner returns(uint256, string memory, string memory, string memory, string memory, string memory) {
    uint256 i = find(id);
    return(winners[i].id, winners[i].drawNumber, winners[i].drawDate, winners[i].tokenId, winners[i].winningAddress, winners[i].giveawayDescription);
  }

  function updateGiveawayWinners(uint256 id, string memory drawNumber, string memory drawDate, string memory tokenId, string memory winningAddress, string memory giveawayDescription) public onlyOwner {
    uint256 i = find(id);
    winners[i].drawNumber = drawNumber;
    winners[i].drawDate = drawDate;
    winners[i].tokenId = tokenId;
    winners[i].winningAddress = winningAddress;
    winners[i].giveawayDescription = giveawayDescription;
  }

// function removeGiveawayWinner(uint256 id) public {
//     if (id == winners[id].id) {
//     delete winners[id];
//     giveawayCount--;
//     }
//   }
  
  function find(uint256 id) view internal returns(uint256) {
    for(uint256 i = 0; i < winners.length; i++) {
      if(winners[i].id == id) {
        return i;
      }
    }
    revert('Giveaway winner does not exist!');
  }
}