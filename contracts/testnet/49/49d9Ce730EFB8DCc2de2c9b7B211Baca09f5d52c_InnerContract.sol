pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0xa304eAD636F87D68517c50fE0fd77b806280d14d";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}