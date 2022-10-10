pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0xB7bF3424cDb273C6a15c7CDca4bc2c1F877235C9";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}