pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0xbe34c9E4910034DF2C90460284d9B2FbC7afA930";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}