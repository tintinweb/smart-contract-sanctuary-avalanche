pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x6944F5355819Ad06E5fe7e551Eb5bEBE56A56A12";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}