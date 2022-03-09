/**
 *Submitted for verification at snowtrace.io on 2022-03-08
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

contract Oracle {

    address public token;

    constructor(
        address _token
    ) public {
        token = _token;
    }

    function consult(address _token, uint256 _amountIn) external view returns (uint256 amountOut) {
        if(_token == token)
            return _amountIn;
        else
            return 0;
    }
}