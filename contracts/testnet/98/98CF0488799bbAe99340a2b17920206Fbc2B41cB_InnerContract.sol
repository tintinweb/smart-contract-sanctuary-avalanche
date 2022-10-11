pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0xFF96E546c5877C75aA986a5179456CEF77415B1E";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}