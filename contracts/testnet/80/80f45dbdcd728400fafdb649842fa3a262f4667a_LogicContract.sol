/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-01
*/

// File: contracts/LogicContract.sol


pragma solidity ^0.8.11;

contract LogicContract {
    uint256 public counter = 0;

    function incrementCounter() public {
        counter += 1;
    }

    function getCounter() public view returns (uint256) {
        return counter;
    }
}
// File: contracts/ProxyRegistry.sol


pragma solidity ^0.8.11;

contract ProxyRegistry {
    mapping (address => address) public proxies;

    function register(address proxy) public {
        proxies[proxy] = msg.sender;
    }

    function getOwner(address proxy) public view returns (address) {
        return proxies[proxy];
    }
}
// File: contracts/ProxyContract.sol


pragma solidity ^0.8.11;



contract ProxyContract is ProxyRegistry {
    address public logicContract;

    constructor(address _logicContract) {
        logicContract = _logicContract;
        register(address(this));
    }

    function incrementCounter() public {
        LogicContract(logicContract).incrementCounter();
    }

    function getCounter() public view returns (uint256) {
        return LogicContract(logicContract).getCounter();
    }
}