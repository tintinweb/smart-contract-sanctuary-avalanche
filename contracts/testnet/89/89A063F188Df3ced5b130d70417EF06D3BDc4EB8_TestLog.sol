pragma solidity >= 0.8.4;

import "./PRBMathUD60x18.sol";

contract TestLog {

  using PRBMathUD60x18 for uint;

  uint public rez;

  constructor() {
  }

  function getLog(uint x) public returns (uint){

    rez = PRBMathUD60x18.log10(x);

    return rez; 
  }

}