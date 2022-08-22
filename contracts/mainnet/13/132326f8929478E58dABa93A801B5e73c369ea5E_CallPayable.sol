contract CallPayable {

    uint public count;

    function payableFunction() payable external {
        require(msg.value == 1 ether);
        count++;
    }

    function getBalance() external view returns(uint) {
        return address(this).balance;
    }
}