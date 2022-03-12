//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
import "./Ownable.sol";

import "./ISafeNumberGenerator.sol";

/// @title Xoshiro256** pRNG contract based on Blackman/Marsaglia's solution
/// @notice This contract serves as a pRNG provider to generate deterministic random values based on a 256 bit seed
/// @dev Seed is extracted from a 256 bit variable into 4 64 bit states used for xorshifting
contract Xoshiro256ss is ISafeNumberGenerator, Ownable {
    uint64 private _s1;
    uint64 private _s2;
    uint64 private _s3;
    uint64 private _s4;

    uint64 public  _nMax;

    constructor() {
        _nMax = type(uint64).max;
    }

    /// @notice Sets the seed for the generator from a 256 bit value
    /// @param seed The 256 bit seed used to initialize the 4 states
    function setSeed(uint256 seed) override onlyOwner public {
        _s1 = uint64(seed >> 192);
        _s2 = uint64(seed >> 128);
        _s3 = uint64(seed >> 64);
        _s4 = uint64(seed);
    }

    /// @notice Gets a reconstructed 256 bit seed based on the current states
    /// @return Value of the 4 states packed into a 256 bit variable 
    function getCurrentSeed() override public view returns(uint256) {
        return  uint256(_s1) << 192 |
                uint256(_s2) << 128 |
                uint256(_s3) << 64 |
                uint256(_s4);
    }

    /// @notice Generates the next 64 bit random number
    /// @return A random number
    function next() internal returns(uint64) {
        uint256 x = uint256(_s2) * 5;
        uint64 result = uint64((x << 7 | x >> 57) * 9);
        uint64 t = _s2 << 17;

        _s3 ^= _s1;
        _s4 ^= _s2;
        _s2 ^= _s3;
        _s1 ^= _s4;

        _s3 ^= t;

        _s4 = _s4 << 45 | _s4 >> 19;

        return result;
    }

    /// @notice Generates the next 64 bit random number without clamping
    /// @return A random number
    function unsafeNext() override public onlyOwner returns(uint64) {
        return next();
    }

    /// @notice Sets the max number to limit with for safeNext()
    /// @param nMax Max number to set to
    function setNumberMax(uint64 nMax) override onlyOwner public {
       _nMax = nMax;
    }

    /// @notice Limits the output of a random number to [0; _nMax] with unbiased filtering
    /// @return A random number between [0; _nMax]
    function safeNext() override onlyOwner public returns(uint64) {
        require(_nMax != 0, "Xoshiro256ss : max number isn't initialized yet.");

        uint64 result;

        do {
            result = next();
        } while (result >= type(uint64).max - type(uint64).max % _nMax);

        result %= _nMax;

        return result;
    }
}