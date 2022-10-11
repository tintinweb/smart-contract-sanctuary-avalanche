pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x0670eE6f9AD28C0C97743F95E28e915Ced9Fd8Ba";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}