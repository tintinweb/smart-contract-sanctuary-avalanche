// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

library FixedPointMath {
    uint256 public constant DECIMALS = 18;
    uint256 public constant SCALAR = 10**DECIMALS;

    struct FixedDecimal {
        uint256 x;
    }

    function fromU256(uint256 value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        uint256 x;
        require(value == 0 || (x = value * SCALAR) / SCALAR == value);
        return FixedDecimal(x);
    }

    function maximumValue() internal pure returns (FixedDecimal memory) {
        return FixedDecimal(type(uint256).max);
    }

    function add(FixedDecimal memory self, FixedDecimal memory value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        uint256 x;
        require((x = self.x + value.x) >= self.x);
        return FixedDecimal(x);
    }

    function add(FixedDecimal memory self, uint256 value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        return add(self, fromU256(value));
    }

    function sub(FixedDecimal memory self, FixedDecimal memory value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        uint256 x;
        require((x = self.x - value.x) <= self.x);
        return FixedDecimal(x);
    }

    function sub(FixedDecimal memory self, uint256 value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        return sub(self, fromU256(value));
    }

    function mul(FixedDecimal memory self, uint256 value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        uint256 x;
        require(value == 0 || (x = self.x * value) / value == self.x);
        return FixedDecimal(x);
    }

    function div(FixedDecimal memory self, uint256 value)
        internal
        pure
        returns (FixedDecimal memory)
    {
        require(value != 0);
        return FixedDecimal(self.x / value);
    }

    function cmp(FixedDecimal memory self, FixedDecimal memory value)
        internal
        pure
        returns (int256)
    {
        if (self.x < value.x) {
            return -1;
        }

        if (self.x > value.x) {
            return 1;
        }

        return 0;
    }

    function decode(FixedDecimal memory self) internal pure returns (uint256) {
        return self.x / SCALAR;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.4;

import "../FixedPointMath.sol";

/// @title Pool
///
/// @dev A library which provides the Merkle Pool data struct and associated functions.
library MerklePool {
    using FixedPointMath for FixedPointMath.FixedDecimal;
    using MerklePool for MerklePool.Data;
    using MerklePool for MerklePool.List;

    struct Context {
        uint256 rewardRate;
        uint256 totalRewardWeight;
    }

    struct Data {
        address token;
        uint256 totalDeposited;
        uint256 totalUnclaimedTIC;
        uint256 totalUnclaimedTICInLP;
        uint256 rewardWeight;
        FixedPointMath.FixedDecimal accumulatedRewardWeight;
        uint256 lastUpdatedBlockTimestamp;
    }

    struct List {
        Data[] elements;
    }

    /// @dev Updates the pool.
    ///
    /// @param _ctx the pool context.
    function update(Data storage _data, Context storage _ctx) internal {
        _data.accumulatedRewardWeight = _data.getUpdatedAccumulatedRewardWeight(
            _ctx
        );

        // TODO: make this more gas efficient! we calc it twice!
        _data.totalUnclaimedTIC = _data.getUpdatedTotalUnclaimed(_ctx);
        _data.lastUpdatedBlockTimestamp = block.timestamp;
    }

    /// @dev Gets the rate at which the pool will distribute rewards to stakers.
    ///
    /// @param _ctx the pool context.
    ///
    /// @return the reward rate of the pool in tokens per second.
    function getRewardRate(Data storage _data, Context storage _ctx)
        internal
        view
        returns (uint256)
    {
        if (_ctx.totalRewardWeight == 0) {
            return 0;
        }

        return (_ctx.rewardRate * _data.rewardWeight) / _ctx.totalRewardWeight;
    }

    /// @dev Gets the accumulated reward weight of a pool.
    ///
    /// @param _ctx the pool context.
    ///
    /// @return the accumulated reward weight.
    function getUpdatedAccumulatedRewardWeight(
        Data storage _data,
        Context storage _ctx
    ) internal view returns (FixedPointMath.FixedDecimal memory) {
        if (_data.totalDeposited == 0) {
            return _data.accumulatedRewardWeight;
        }
        uint256 amountToDistribute = _data.getUpdatedAmountToDistribute(_ctx);
        if (amountToDistribute == 0) {
            return _data.accumulatedRewardWeight;
        }

        FixedPointMath.FixedDecimal memory rewardWeight =
            FixedPointMath.fromU256(amountToDistribute).div(
                _data.totalDeposited
            );

        return _data.accumulatedRewardWeight.add(rewardWeight);
    }

    /**
     * @dev get's the total amount to distribute in this pool based on the last updated timestamp.
     * @param _data pool's data
     * @param _ctx the pool context
     */
    function getUpdatedAmountToDistribute(
        Data storage _data,
        Context storage _ctx
    ) internal view returns (uint256) {
        uint256 elapsedTime = block.timestamp - _data.lastUpdatedBlockTimestamp;

        if (elapsedTime == 0) {
            return 0;
        }

        uint256 rewardRate = _data.getRewardRate(_ctx);
        return rewardRate * elapsedTime;
    }

    /**
     * @dev get's the total amount unclaimed in this pool based on the last updated timestamp.
     * @param _data pool's data
     * @param _ctx the pool context
     */
    function getUpdatedTotalUnclaimed(Data storage _data, Context storage _ctx)
        internal
        view
        returns (uint256)
    {
        if (_data.totalDeposited == 0) {
            return _data.totalUnclaimedTIC;
        }
        return
            _data.totalUnclaimedTIC + _data.getUpdatedAmountToDistribute(_ctx);
    }

    /// @dev Adds an element to the list.
    ///
    /// @param _element the element to add.
    function push(List storage _self, Data memory _element) internal {
        _self.elements.push(_element);
    }

    /// @dev Gets an element from the list.
    ///
    /// @param _index the index in the list.
    ///
    /// @return the element at the specified index.
    function get(List storage _self, uint256 _index)
        internal
        view
        returns (Data storage)
    {
        require(_index < _self.elements.length, "MerklePool: INVALID_INDEX");
        return _self.elements[_index];
    }

    /// @dev Gets the last element in the list.
    ///
    /// This function will revert if there are no elements in the list.
    ///ck
    /// @return the last element in the list.
    function last(List storage _self) internal view returns (Data storage) {
        return _self.elements[_self.lastIndex()];
    }

    /// @dev Gets the index of the last element in the list.
    ///
    /// This function will revert if there are no elements in the list.
    ///
    /// @return the index of the last element.
    function lastIndex(List storage _self) internal view returns (uint256) {
        return _self.length() - 1;
    }

    /// @dev Gets the number of elements in the list.
    ///
    /// @return the number of elements.
    function length(List storage _self) internal view returns (uint256) {
        return _self.elements.length;
    }
}