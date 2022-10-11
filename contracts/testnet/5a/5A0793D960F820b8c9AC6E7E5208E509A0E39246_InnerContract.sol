pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0xd072E4b20e9B083E2ca6A39B22f6c77057Ef2BAC";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}