/**
 *Submitted for verification at snowtrace.io on 2022-08-22
*/

interface ITestPayable {
    function payableFunction() payable external;
}

contract CallPayable {

receive() payable external {
    
}

// This function pays from the caller: msg.value
function callPayable(address contractAddress) external payable {
    require(msg.value >= 1 ether);
    
    ITestPayable (contractAddress).payableFunction{value: 1000 wei}();
}

// This function pays from this contract balance
function callPayableFunction(address contractAddress) external {
    ITestPayable (contractAddress).payableFunction{value: 1000 wei}();
}

function getBalance() external view returns(uint) {
       return address(this).balance;
}
}