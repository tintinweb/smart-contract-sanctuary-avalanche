pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x719570A9138E469adeE852B43004BA9a9bcA575c";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}