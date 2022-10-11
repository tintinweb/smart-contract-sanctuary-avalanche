pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x71dB910Fa830c7Ca647c81C0c14EB1ec9Ed59DCe";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}