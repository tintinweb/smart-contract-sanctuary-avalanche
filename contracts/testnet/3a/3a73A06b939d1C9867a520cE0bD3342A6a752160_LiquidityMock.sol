// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

import "../interfaces/ILiquidity.sol";

contract LiquidityMock {
    function totalLiquidity() public view returns (uint256) {
        return 10000;
    }

    function initSwap(uint256 _amount, address payable _receiver)
        public
        view
        returns (bool)
    {
        return true;
    }

    function completeSwap(uint256 _amount, address payable _receiver)
        external
        view
        returns (bool)
    {
        return true;
    }

    function unSwap(uint256 _amount, address payable _receiver)
        external
        view
        returns (bool)
    {
        return true;
    }

    function dco2InUSDC() external pure returns (uint256 _value) {
        return (_value = 1 ether);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILiquidity {
    function totalLiquidity() external view returns (uint256);

    function initSwap(uint256 _amount, address payable _receiver)
        external
        view
        returns (bool);

    function completeSwap(uint256 _amount, address payable _receiver)
        external
        view
        returns (bool);

    function unSwap(uint256 _amount, address payable _receiver)
        external
        view
        returns (bool);

    function dco2InUSDC() external pure returns (uint256);
}