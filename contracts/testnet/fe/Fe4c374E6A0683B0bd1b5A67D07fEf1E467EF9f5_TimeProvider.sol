// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITimeProvider {
    function getTimestamp() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ITimeProvider.sol";

contract TimeProvider is ITimeProvider {
    bool public debug;
    uint256 private _debugTimestamp;

    constructor(bool debug_) {
        debug = debug_;
    }

    function increaseDebugTimestamp(uint256 by) external {
        require(debug, "not debug");
        _debugTimestamp += by;
    }

    function getTimestamp() external view returns (uint256) {
        return debug ? _debugTimestamp : block.timestamp;
    }
}