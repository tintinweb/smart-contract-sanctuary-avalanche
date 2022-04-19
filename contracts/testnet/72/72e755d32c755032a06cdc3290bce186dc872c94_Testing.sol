/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-18
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

contract Testing {


    event DoSthEvent(uint a, uint b, uint c);

    function doSomething(uint a, uint b) public returns (uint) {
        require(msg.sender == address(this), "Caller is wrong!");
        emit DoSthEvent(a, b, a / b);
        return a / b;
    }  

    // function executeDelegatecall(
    //     address calculator,  
    //     uint256 gasPrice,
    //     uint256 txGas,
    //     uint256 a, 
    //     uint256 b
    // ) public returns (bool success) { 
    //     bytes memory data = abi.encodeWithSignature("doSomething(uint256,uint256)", a, b);
    //     uint256 safeTxGas = gasPrice == 0 ? (gasleft() - 2500) : txGas;
    //     assembly {
    //         success := delegatecall(safeTxGas, to, add(data, 0x20), mload(data), 0, 0)
    //     } 
    // }

    function executeCall( 
        address calculator,
        uint256 a, 
        uint256 b
    ) public {  
        (bool success, bytes memory result) = calculator.delegatecall(abi.encodeWithSignature("doSomething(uint256,uint256)", a, b));
        require(success, "Failed hahha");
        require(abi.decode(result, (uint256)) >= 0, "Heheheheheheh");
    }

}