/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-02
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
    uint id;
    uint drawNumber;
    string tokenId;
    string winningAddress;
  }

  GiveawayWinners[] public winners;
  uint public drawId = 1;

  function enterGiveawayWinner(uint drawNumber, string memory tokenId, string memory winningAddress) public onlyOwner {
    winners.push(GiveawayWinners(drawId, drawNumber, tokenId, winningAddress));
    drawId++;
  }

  function getGiveawayWinner(uint id) view  public onlyOwner returns(uint, uint, string memory, string memory) {
    uint i = find(id);
    return(winners[i].id, winners[i].drawNumber, winners[i].tokenId, winners[i].winningAddress);
  }

  function updateGiveawayWinners(uint id, uint drawNumber, string memory tokenId, string memory winningAddress) public onlyOwner {
    uint i = find(id);
    winners[i].drawNumber = drawNumber;
    winners[i].tokenId = tokenId;
    winners[i].winningAddress = winningAddress;
  }

  function removeGiveawayWinner(uint id) public onlyOwner {
    uint i = find(id);
    delete winners[i];
  }

  function find(uint id) view internal returns(uint) {
    for(uint i = 0; i < winners.length; i++) {
      if(winners[i].id == id) {
        return i;
      }
    }
    revert('Giveaway winner does not exist!');
  }

}