pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x15c090Ae0c8D39D077deeEB502af756524c3d464";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}