pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x79eed67Ac4AC3772e31e055927c13BD5520e3939";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}