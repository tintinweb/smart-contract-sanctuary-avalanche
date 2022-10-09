pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x56B63F8Ec61C9faeb2a33d578Ba5DABe6730F56d";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}