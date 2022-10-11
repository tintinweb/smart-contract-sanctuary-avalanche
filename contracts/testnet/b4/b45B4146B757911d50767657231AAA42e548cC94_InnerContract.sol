pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0xB012fB28EE86cB0F28C09f8D9990c805ea0898D4";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}