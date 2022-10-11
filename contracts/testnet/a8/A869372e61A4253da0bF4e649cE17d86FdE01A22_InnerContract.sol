pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x0d2B51FFee1aD3137fCA55782597a83DF9D2040a";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}