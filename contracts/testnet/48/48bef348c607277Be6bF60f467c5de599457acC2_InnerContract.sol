pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0xcc6A7931e4bE6a06D4945E90A96d5Ca1872357bd";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}