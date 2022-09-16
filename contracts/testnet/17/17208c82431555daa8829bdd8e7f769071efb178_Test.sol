/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

interface IERC20 {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns(uint8);
}

// USDC -> 0xF7A2D8b4EF1CDd129f332d20f63E360b7c37575d

contract Test {

    function test(
        IERC20 _token,
        address payable [] calldata _to,
        uint _usdc
    ) external payable {
        require(msg.value > 0, "Ether needed.");

        uint share = msg.value / _to.length;

        for (uint i; i < _to.length; ++i) {
            _to[i].transfer(share);

            try _token.transferFrom(msg.sender, _to[i], _usdc * (10**_token.decimals())) returns (bool result) {
                require(result, "error");
            } catch {
                revert("external call failed!");
            }
        }
    }

}