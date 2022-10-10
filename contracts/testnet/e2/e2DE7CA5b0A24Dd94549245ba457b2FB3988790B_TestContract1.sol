pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0xcf08ca5Bfb0237578C4c8711806286398EDC9d98";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}