pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x4717B3ba4653083DAcE02B7a78b80FBbCD5b849a";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}