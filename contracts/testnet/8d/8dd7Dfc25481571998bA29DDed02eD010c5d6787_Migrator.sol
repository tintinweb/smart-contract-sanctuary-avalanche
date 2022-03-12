// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IToken.sol";

contract Migrator {
  IToken v1 = IToken(0xCF93C4063c0F69eB04853F00733E5564E3addD98);
  IToken v2 = IToken(0xf76022369BeCD25B3cC39F7098C92cD51662033E);
  address owner;

  constructor() {
    owner = msg.sender;
  }

  function migration(address[] calldata users) external {
    require(msg.sender == owner);
    for (uint256 i = 0; i < users.length; i++) {
      uint256 balance = v1.balanceOf(users[i]);
      v2.transfer(users[i], balance);
    }
  }

  function sweep() external {
    v2.transfer(owner, v2.balanceOf(address(this)));
  }
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