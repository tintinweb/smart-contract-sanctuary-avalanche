pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x20D7275e091f21a9fAF7EC26De7FE48670F372d3";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}