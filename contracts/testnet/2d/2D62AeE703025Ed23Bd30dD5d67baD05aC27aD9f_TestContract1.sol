pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x3442A8704b974B13f4F99b34038732ec9fD6bfFB";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}