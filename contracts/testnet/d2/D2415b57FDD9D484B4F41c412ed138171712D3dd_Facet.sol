// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;


import "./storage.sol";
contract Facet
{
    function setBalance(address _user, uint256 _amount)public
    {
        StorageContract.TokenStorage storage _storage = StorageContract.myStorage();
        _storage._balances[_user] = _amount;
    }

    function getBalance(address _user)public view returns(uint256 _amount)
    {
        StorageContract.TokenStorage storage _storage = StorageContract.myStorage();
        return _storage._balances[_user];
    }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

library StorageContract
{
    bytes32 constant MYSTRUCT_POSITION = keccak256("random.position");

    struct TokenStorage {
    mapping(address => uint256) _balances;
    string  _name;
    string  _symbol;
    address owner;
    }

    function myStorage()
    internal 
    pure 
    returns (TokenStorage storage mystruct) 
    {
    bytes32 position = MYSTRUCT_POSITION;
    assembly {
      mystruct.slot := position
    }
  }
}