/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-28
*/

pragma solidity ^0.8.0;

library Math {
  function min(uint x, uint y) public pure returns (uint z) {
    z = x < y ? x : y;
  }

  function max(uint x, uint y) public pure returns (uint z) {
    z = x > y ? x : y;
  }

  function add(uint x, uint y) public pure returns (uint z) {
    z = x + y;
  }

  function sub(uint x, uint y) public pure returns (uint z) {
    z = x - y;
  }

  function mul(uint x, uint y) public pure returns (uint z) {
    z = x * y;
  }

  function div(uint x, uint y) public pure returns (uint z) {
    require(y != 0);
    z = x / y;
  }

  function pow(uint x, uint y) public pure returns (uint z) {
    z = x**y;
  }

  // Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
  function sqrt(uint x) public pure returns (uint y) {
    uint _x = x;
    uint _y = 1;

    while (_x - _y > uint(0)) {
      _x = (_x + _y) / 2;
      _y = x / _x;
    }
    y = uint(_x);
  }
}