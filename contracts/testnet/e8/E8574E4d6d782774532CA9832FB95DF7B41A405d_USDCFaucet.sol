/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-15
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.16;

contract USDCFaucet {

    address private immutable usdc;

    constructor(address _addr) {
        usdc = _addr;
    }

    event Transfer(address indexed to, uint amount, uint time);

    mapping (address => uint) public lastTimeTransfered; // every 1 day user can withdraw 10,000 USDC from Faucet

    function withdraw(address _to) external {
        require(_to != address(0), "invalid address.");
        require((block.timestamp > lastTimeTransfered[_to] + 1 days) || (lastTimeTransfered[_to] == 0), "wait until 1 day expiration.");

        (bool result, bytes memory data) = usdc.call(abi.encodeWithSignature(
            "transfer(address,uint256)", _to, 10000 * 10**18
        ));
        
        bool result_2 = abi.decode(data, (bool));
        require(result && result_2, "something went wrong!");

        lastTimeTransfered[_to] = block.timestamp;

        emit Transfer({
            to: _to,
            amount: 10000,
            time: block.timestamp
        });
    }

}