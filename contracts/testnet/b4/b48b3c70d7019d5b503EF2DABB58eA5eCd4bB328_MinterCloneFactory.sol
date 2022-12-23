/**
 *Submitted for verification at testnet.snowtrace.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external returns (bool);
    function mint() external;
}

contract Minter {

    function mint(address Sol, address owner) external {
        IERC20(Sol).mint();
        uint balances = IERC20(Sol).balanceOf(address(this));
        IERC20(Sol).transfer(owner, balances);
        selfdestruct(payable(owner));
    }
}

contract CloneFactory {
    function createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }

    function isClone(address target, address query) internal view returns (bool result) {
        bytes20 targetBytes = bytes20(target);
        
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
            mstore(add(clone, 0xa), targetBytes)
            mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

            let other := add(clone, 0x40)
            extcodecopy(query, other, 0, 0x2d)
            result := and(
                eq(mload(clone), mload(other)),
                eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
            )
        }
    }

}

contract MinterCloneFactory is CloneFactory {
    address public Sol;
    address public owner;
    address public minter;
    
    constructor(address _Sol) {
        Sol = _Sol;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setMinter(address _minter) external onlyOwner {
        minter = _minter;
    }

    function Mint(uint count) external onlyOwner {
        for (uint i=0; i<count; ++i) {
            Minter _Minter = Minter(createClone(minter));
            _Minter.mint(Sol, owner);
        }
    }
}