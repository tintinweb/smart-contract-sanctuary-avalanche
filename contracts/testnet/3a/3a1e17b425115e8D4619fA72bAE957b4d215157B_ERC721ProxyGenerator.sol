/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-03
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.5;

contract ERC721Proxy {

    string public tokenName;
    string public tokenSymbol;
    string public tokenDesc;

    address private immutable owner;

    uint public totalUpdates;

    event Update(address indexed operator, address indexed contractAddr, uint time);

    constructor(address _addr) {
        owner = _addr;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
        totalUpdates++;
    }

    function updateData(
        string calldata _name,
        string calldata _symbol,
        string calldata _desc,
        address _contract
    ) external onlyOwner {
        require(
            bytes(_name).length > 0 &&
            bytes(_symbol).length > 0 &&
            bytes(_desc).length > 0 &&
            _contract != address(0) &&
            _contract.code.length > 0,
            "invalid data"
        );

        tokenName = _name;
        tokenSymbol = _symbol;
        tokenDesc = _desc;

        emit Update({
            operator: msg.sender,
            contractAddr: _contract,
            time: block.timestamp
        });
    }

    function total() external view returns(uint) {
        return totalUpdates;
    }

}
////////////////////////////////////////////////////
contract ERC721ProxyGenerator {

    event ProxyContractCreation(address indexed creator);

    function generate(
        address _owner
    ) external returns(bytes memory byteCode) {
        byteCode = abi.encodePacked(type(ERC721Proxy).creationCode, abi.encode(_owner));

        emit ProxyContractCreation({
            creator: _owner
        });
    }

}