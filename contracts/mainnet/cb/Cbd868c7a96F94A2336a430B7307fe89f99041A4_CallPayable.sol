interface ITestPayable {
    function payableFunction() payable external;
}

contract CallPayable {

receive() payable external {
    
}

// This function pays from the caller: msg.value
function callPayable(address contractAddress) external payable {
    require(msg.value >= 1 ether);
    
    ITestPayable (contractAddress).payableFunction{value:  7*(10**15)}();
}

// This function pays from this contract balance
function callPayableFunction(address contractAddress) external {
    ITestPayable (contractAddress).payableFunction{value:  7*(10**15)}();
}

function getBalance() external view returns(uint) {
       return address(this).balance;
}
}