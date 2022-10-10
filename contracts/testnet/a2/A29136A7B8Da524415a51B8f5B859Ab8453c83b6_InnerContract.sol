pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x62718e5A33DcaD771C97fa89bf467a02172ccd50";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}