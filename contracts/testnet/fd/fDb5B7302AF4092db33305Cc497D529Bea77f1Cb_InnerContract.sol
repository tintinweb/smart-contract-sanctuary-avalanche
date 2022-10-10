pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x2C841ec54bEc4bFc91AFCcA9a59aD1c90cB48B85";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}