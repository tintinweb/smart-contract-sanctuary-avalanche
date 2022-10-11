pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x47cea0180Aa4ab5Ca99f2B9C759c83dD413E3108";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}