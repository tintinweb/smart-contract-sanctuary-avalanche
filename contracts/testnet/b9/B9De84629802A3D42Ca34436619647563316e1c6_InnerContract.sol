pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x14d44235F2C94f6BA0DaCf5186C859B16cB574F6";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}