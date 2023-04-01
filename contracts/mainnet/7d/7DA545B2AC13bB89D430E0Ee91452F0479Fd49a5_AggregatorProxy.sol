// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interface/IAggregator.sol";

contract AggregatorProxy {

    function getAggregatorData(address _asset, IAggregator _aggregator) external returns (uint256, uint8) {
        if ((_aggregator.version()) == uint256(-1))
            return _aggregator.getAssetPrice(_asset);

        (, int256 _answer, , ,) = _aggregator.latestRoundData();
        return (_answer < 0 ? 0 : uint256(_answer), _aggregator.decimals());
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IAggregator {

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);

    function decimals() external view returns (uint8);

    function version() external view returns (uint256);

    function getAssetPrice(address _asset) external returns (uint256, uint8);
}