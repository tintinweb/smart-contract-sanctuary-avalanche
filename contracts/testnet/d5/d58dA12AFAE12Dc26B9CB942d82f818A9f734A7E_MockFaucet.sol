// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IToken.sol";

contract MockFaucet {
  uint256 public constant LOCK_PERIOD = 7200;

  struct Faucet {
    address token;
    uint256 limit;
  }

  address public owner;

  IToken public holding;

  Faucet[] public faucets;
  mapping(address => uint256) public faucetAt;

  constructor() {
    owner = msg.sender;
  }

  modifier onlyHolder() {
    require(holding.balanceOf(msg.sender) > 0);
    _;
  }

  function faucet() external onlyHolder {
    address user = msg.sender;
    require(faucetAt[user] < block.timestamp);
    faucetAt[user] = block.timestamp + LOCK_PERIOD;
    for (uint256 i = 0; i < faucets.length; i++) {
      if (faucets[i].token == address(0)) {
        payable(user).transfer(faucets[i].limit);
      } else {
        IToken(faucets[i].token).transfer(user, faucets[i].limit);
      }
    }
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function setHolding(IToken newHolding) external onlyOwner {
    holding = newHolding;
  }

  function totalFaucets() external view returns (uint256) {
    return faucets.length;
  }

  function addFaucets(address[] memory tokens, uint256[] memory limits) external onlyOwner {
    for (uint256 i = 0; i < tokens.length; i++) {
      faucets.push(Faucet(tokens[i], limits[i]));
    }
  }

  function withdraw() external onlyOwner {
    for (uint256 i = 0; i < faucets.length; i++) {
      if (faucets[i].token == address(0)) {
        payable(owner).transfer(address(this).balance);
      } else {
        IToken token = IToken(faucets[i].token);
        token.transfer(owner, token.balanceOf(address(this)));
      }
    }
  }

  receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
  function balanceOf(address account) external view returns (uint256);

  function transfer(address to, uint256 amount) external returns (bool);

  function transferFrom(
    address from,
    address to,
    uint256 amount
  ) external returns (bool);

  function burn(address account, uint256 amount) external;
}