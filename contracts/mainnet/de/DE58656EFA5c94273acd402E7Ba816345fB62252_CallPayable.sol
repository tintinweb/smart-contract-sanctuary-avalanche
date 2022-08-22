interface ITestPayable {
        function payableFunction() payable external;
    }
    
    contract CallPayable {

    receive() payable external {
        
    }

    function callPayableFunction(address contractAddress) external {
        ITestPayable(contractAddress).payableFunction{value: 7*(10**15)}();
    }

    function getBalance() external view returns(uint) {
           return address(this).balance;
    }
}