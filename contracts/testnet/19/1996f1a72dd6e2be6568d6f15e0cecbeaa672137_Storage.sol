/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


contract Storage {
    enum Color {
        IDLE,
        GREY,
        BLUE,
        GREEN,
        RED
    }

    struct Configuration {
        uint16 duration;
        uint16 cooldown;
        uint64 unitHeight;
        uint64 range;
    }

    Color[] public units;

    Configuration public config = Configuration(20, 30, 1296000, 63504000);
    constructor(){
    units = [
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.GREEN,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.GREEN,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.GREEN,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.GREEN,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.GREEN,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.GREEN,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.GREEN,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.GREEN,
      Color.GREY,
      Color.BLUE,
      Color.GREY,
      Color.BLUE,
      Color.RED
    ];

    }
    function getUnit(uint256 _random) public view returns (uint64 angle_, uint64 index_) {
        Configuration memory config_ = config;

        angle_ = uint64(_random % config_.range);
        index_ = uint64((angle_ - (angle_ % config_.unitHeight)) / config_.unitHeight);
    }


    function randomizerFulfill(uint256 _random) external view returns(Color) {
    /// @notice checks whether the game is finished
    

    /// @notice finds the color
    (uint64 angle_, uint64 index_) = getUnit(_random);
    Color color_ = units[index_];
    

    /// @notice gets currencies which are used to escrow wager
    

    /// @notice closes the game
    return color_;
    
  }
}