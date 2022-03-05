// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./ERC20.sol";

contract Ride is ERC20 {
  address private owner;
  address private rideDao;
  address private LPContract;
  uint private limit = 100000000 * 10 ** 18;

  constructor() ERC20('RIDE token', 'RIDES') {
    owner = msg.sender;

    _mint(msg.sender, 2000000 * 10 ** 18);
  }

  function setDaoContract(address _rideDao) public{
    require(msg.sender == owner, 'You must be the owner to run this.');
    rideDao = _rideDao;
  }

function setLPContract(address _LPContract) public{
    require(msg.sender == owner, 'You must be the owner to run this.');
    LPContract = _LPContract;
  }

  function setTranferLimit(uint _limit) public{
    require(msg.sender == owner, 'You must be the owner to run this.');
    limit = _limit;
  }

  function transferFrom(address sender, address recipient, uint256 amount) public override(ERC20) returns (bool) {
    require(amount <= limit, 'This transfer exceeds the allowed limit!');
    return super.transferFrom(sender, recipient, amount);
  }

  function transfer(address recipient, uint256 amount) public override(ERC20) returns (bool) {
    require(amount <= limit, 'This transfer exceeds the allowed limit!');
    return super.transfer(recipient, amount);
  }

  function mint(uint256 _amount) public {
    require(msg.sender == rideDao || msg.sender == owner, 'Can only be used by RideDao or owner.');
    _mint(msg.sender, _amount);
  }

  function burn(uint256 _amount) public {
    require(msg.sender == rideDao || msg.sender == owner, 'Can only be used by RideDao or owner.');
    _burn(msg.sender, _amount);
  }
}