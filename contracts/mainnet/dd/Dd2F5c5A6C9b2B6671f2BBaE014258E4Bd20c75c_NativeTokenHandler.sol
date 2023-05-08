// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface INativeTokenHandler {
    function withdraw(address nativeWrap, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;

    function transfer(address dst, uint wad) external returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../interfaces/IWETH.sol";
import "../interfaces/INativeTokenHandler.sol";

contract NativeTokenHandler is INativeTokenHandler {
    receive() external payable {}

    function withdraw(address nativeWrap, uint256 amount) external override {
        IWETH(nativeWrap).withdraw(amount);
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "native token handler failed");
    }
}