/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ERC20 {
    function totalSupply() external view returns (uint256);
    function deposit(uint256 amount) external payable;
    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface Pair {
    function totalSupply() external view returns (uint256);
    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);
}

contract BreedingSeed{
    function getSeed(address user) external view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        // solhint-disable-next-line
                        block.timestamp,
                        user,
                        blockhash(block.number-1)
                    )
                )
            );
    }
    function getSupply(address token) external view returns (uint256) {
        return ERC20(token).totalSupply();
    }

    function getSupplyRouter(address[] memory addresses) external view returns (uint256) {
        uint256 sum = 0;
        for(uint i=0; i<addresses.length; i++){
            Pair p = Pair(addresses[i]);
            (uint112 r0, uint112 r1,) = p.getReserves();
            sum += p.totalSupply();
            sum += r0;
            sum += r1;
        }
        return sum;
    }

}