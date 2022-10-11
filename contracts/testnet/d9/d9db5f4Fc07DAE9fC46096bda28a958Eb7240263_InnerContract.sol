pragma solidity 0.5.15;

contract TestContract1 {

    uint amount;

    string message = "0x9793294419F9e5d3Cc326191673a76d783c67376";

    constructor(uint _amount) public {
        amount = _amount;
    }
}

contract InnerContract {

  function foo() public payable {
    msg.sender.transfer(msg.value);
  }
}