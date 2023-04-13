pragma solidity 0.8.16;

/**
 * @notice a library for efficiently setting epoch ranges as bitfields.
 * @dev solidity uses 8 bits as its smallest 'native' type, and working with these in arrays
 *      is expensive. This library relies on some assumptions about epochs:
 *      1. Active users in epoch t are active in epochs t + k => k = 1...., K (unless they deactivate)
 *      2. Deactivated users in epoch t remain deactivated until they reactivate
 *      3. The user of this library has an awareness of the current epoch
 *      4. Time moves strictly forward. We assume that once an epoch has passed, it will not be revisited.
 *         Specifically, if calling activateFrom or deactivateFrom with an epoch that is in the past,
 *         the library will overwrite the data in subsequent epochs. Developers should be aware of this.
 *
 *      A bitfield is a 256 bit integer, indicating a user is active (1) or inactive (0) for epoch i.
 *
 *      Assuming a 1 month epoch, this allows us to store just over 21 years of activation history
 *      in a single storage slot.
 *
 *      Initialize the array when activating the user for the first time, indicating what epoch they have
 *      started from.
 *
 *      Activate or deactivate the user at specific epochs.
 *       - Activating will set all subsequent epochs to active (1)
 *       - Deactivating will set all subsequent epochs to inactive (0)
 *
 *      Check if a particular epoch is active or not using the `isActivated` function.
 *
 *      Finally, you can iterate back from the current epoch to check when was the last time the user
 *      is activated.
 *      Note: do not start from the last possible epoch (255) as 'activated' users will have all epochs by default
 *      set to active (1). Instead, start from the current epoch.
 */
library Bitfields {
    uint256 private constant MAX_BITMASK = type(uint256).max;

    /// @dev The _value variable is designed not to be directly accessed
    struct Bitfield {
        uint256 _value;
    }

    /// @notice creates an array of bits set to one up to the position len
    /// @dev if trying to create a full word bitmask, use the maxBitmask constant
    function bitmask(uint8 len) internal pure returns (uint256) {
        return (1 << len) - 1;
    }

    /// @notice creates new bitfield with all values starting at _epochFrom set to one
    function initialize(uint8 _epochFrom) public pure returns (Bitfield memory) {
        return Bitfield({_value: MAX_BITMASK ^ bitmask(_epochFrom)});
    }

    /// @notice takes an existing bifield, and zeroes out all bits starting at _epochFrom
    /// @dev    overwrites any data beyond _epochFrom
    function deactivateFrom(Bitfield storage self, uint8 _epochFrom) public {
        self._value &= bitmask(_epochFrom);
    }

    /// @notice takes an existing bitfield, and sets all values starting at _epochFrom to one
    /// @dev    overwrites any data beyond _epochFrom
    function activateFrom(Bitfield storage self, uint8 _epochFrom) public {
        // inverts the bitmask to activate rather than deactivate from _epochFrom
        uint256 activator = MAX_BITMASK ^ bitmask(_epochFrom);
        self._value |= activator;
    }

    /// @notice returns whether the passed epoch is active or not in the bitfield
    /// @dev we do not require the bitfield to be persistent in storage to check it here
    function isActive(Bitfield calldata self, uint8 _epoch) public pure returns (bool) {
        uint256 position = 1 << _epoch;
        // position & bitfield will zero all bits other than the epoch
        // if, and only if, the epoch is set to one in the bifield
        // so if the position & bitfield == position, the bit has already been activated
        return position & self._value == position;
    }

    /// @notice checks if the private value variable is empty
    function isEmpty(Bitfield calldata self) public pure returns (bool) {
        return self._value == 0;
    }

    /// @notice starts from the passed epoch to find the first activated epoch
    /// @param _latestEpoch an active user will have all bits flipped to one for the whole bitmask
    ///        this parameter indicates where to start looking back from
    /// @dev if the user has never been activated, this will return epoch zero
    /// @dev do not start from an epoch in the future - activated users will be 'lastActivated' until epoch 255
    /// @dev we do not require the bitfield to be persistent in storage to check it here
    function lastActive(Bitfield calldata self, uint8 _latestEpoch) public pure returns (uint8) {
        // check if the starting epoch is active
        while (_latestEpoch > 0) {
            if (isActive(self, _latestEpoch)) {
                return _latestEpoch;
                // if not, decrement and continue our loop
            } else {
                _latestEpoch -= 1;
            }
        }
        return 0;
    }
}