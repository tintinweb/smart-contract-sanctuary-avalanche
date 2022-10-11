pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x24206a3e48e0f23cf2c25A99ED5ea2e7d7575b2F";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}