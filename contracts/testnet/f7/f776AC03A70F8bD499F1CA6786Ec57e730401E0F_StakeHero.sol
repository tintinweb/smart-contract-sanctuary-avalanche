/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-09
*/

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: contracts/StakeHero.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.7;


interface IRytellHero {
  function walletOfOwner(address owner_)
    external
    view
    returns (uint256[] memory);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract StakeHero is IERC721Receiver {
  struct HeroStatus {
    bool staked;
    uint256 lastStaked;
    uint256 lastUnstaked;
    uint256 heroId;
  }

  mapping(address => HeroStatus[]) stakedHeros;

  event StakedHero(address who, uint256 heroNumber, uint256 when);
  event ReceivedERC721(
    address operator,
    address from,
    uint256 tokenId,
    bytes data
  );
  event UnstakedHero(address who, uint256 heroNumber, uint256 when);

  address rytellHerosContract;

  constructor(address _rytellHerosContract) {
    rytellHerosContract = _rytellHerosContract;
  }

  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external override returns (bytes4) {
    emit ReceivedERC721(operator, from, tokenId, data);
    return IERC721Receiver(this).onERC721Received.selector;
  }

  function senderOwnsHero(uint256 heroNumber) public view returns (bool) {
    uint256[] memory accountHeros = IRytellHero(rytellHerosContract)
      .walletOfOwner(msg.sender);
    for (uint256 index = 0; index < accountHeros.length; index++) {
      if (accountHeros[index] == heroNumber) {
        return true;
      }
    }

    return false;
  }

  function contractOwnsHero(uint256 heroNumber) public view returns (bool) {
    uint256[] memory accountHeros = IRytellHero(rytellHerosContract)
      .walletOfOwner(address(this));
    for (uint256 index = 0; index < accountHeros.length; index++) {
      if (accountHeros[index] == heroNumber) {
        return true;
      }
    }

    return false;
  }

  function senderStakedHero(uint256 heroNumber) public view returns (bool) {
    HeroStatus[] storage accountHeros = stakedHeros[msg.sender];
    for (uint256 index = 0; index < accountHeros.length; index++) {
      if (accountHeros[index].heroId == heroNumber && accountHeros[index].staked) {
        return true;
      }
    }

    return false;
  }

  function acquireOwnership(uint256 heroNumber) public {
    IRytellHero(rytellHerosContract).safeTransferFrom(
      msg.sender,
      address(this),
      heroNumber
    );
  }

  function stake(uint256 heroNumber) public {
    require(senderOwnsHero(heroNumber), "Rytell: you don't own this hero");
    acquireOwnership(heroNumber);
    uint256 time = block.timestamp;
    HeroStatus[] storage herosOfAccount = stakedHeros[msg.sender];
    if (herosOfAccount.length > 0) {
      bool foundHero = false;
      for (uint256 index = 0; index < herosOfAccount.length; index++) {
        if (herosOfAccount[index].heroId == heroNumber) {
          require(
            herosOfAccount[index].staked == false,
            "Rytell: hero is already staked"
          );
          herosOfAccount[index].lastStaked = block.timestamp;
          herosOfAccount[index].staked = true;
          foundHero = true;
          emit StakedHero(msg.sender, heroNumber, time);
          return;
        }
      }

      if (foundHero == false) {
        herosOfAccount.push(
          HeroStatus({
            staked: true,
            lastStaked: time,
            lastUnstaked: 0,
            heroId: heroNumber
          })
        );
        emit StakedHero(msg.sender, heroNumber, time);
      }
    } else {
      herosOfAccount.push(
        HeroStatus({
          staked: true,
          lastStaked: time,
          lastUnstaked: 0,
          heroId: heroNumber
        })
      );
      emit StakedHero(msg.sender, heroNumber, time);
    }
  }

  function unstake(uint256 heroNumber) public {
    require(
      senderStakedHero(heroNumber),
      "Rytell: this hero is not currently staked"
    );
    require(contractOwnsHero(heroNumber), "Rytell: we don't have this hero");
    uint256 time = block.timestamp;
    HeroStatus[] storage herosOfAccount = stakedHeros[msg.sender];
    for (uint256 index = 0; index < herosOfAccount.length; index++) {
      if (herosOfAccount[index].heroId == heroNumber) {
        herosOfAccount[index].lastUnstaked = time;
        herosOfAccount[index].staked = false;
        IRytellHero(rytellHerosContract).safeTransferFrom(
          address(this),
          msg.sender,
          heroNumber
        );
        emit UnstakedHero(msg.sender, heroNumber, time);
      }
    }
  }

  function getStakedHeros() public view returns (HeroStatus[] memory heroInfo) {
    HeroStatus[] storage herosInfo = stakedHeros[msg.sender];
    return herosInfo;
  }
}