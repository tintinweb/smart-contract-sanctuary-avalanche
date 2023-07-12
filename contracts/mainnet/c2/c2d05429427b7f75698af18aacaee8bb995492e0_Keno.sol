/**
 *Submitted for verification at snowtrace.io on 2023-07-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


// import "../../helpers/InternalRNG.sol";

// import "forge-std/Test.sol";

contract Keno {
  uint256 public constant amountNumbers = 40;
  uint256 public amountUniqueDraws = 10;

  // amount of picks => multiplier of amount numbers correct[0-10]
  mapping(uint256 => uint256[11]) internal multipliers_;
  /// @notice house edges of game
  mapping(uint256 => uint256) internal houseEdges_;

  constructor(){
    // Pre defined multipliers_
    // picks => []amount corect
    //  multipliers_[9][6] -> multiplier for 9 picks and 6 correct
    // multipliers_[0] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    multipliers_[1] = [40, 240, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    multipliers_[2] = [0, 160, 500, 0, 0, 0, 0, 0, 0, 0, 0];
    multipliers_[3] = [0, 0, 220, 5000, 0, 0, 0, 0, 0, 0, 0];
    multipliers_[4] = [0, 0, 150, 900, 1e4, 0, 0, 0, 0, 0, 0];
    multipliers_[5] = [0, 0, 140, 300, 1400, 4 * 1e4, 0, 0, 0, 0, 0];
    multipliers_[6] = [0, 0, 0, 300, 800, 15 * 1e3, 7 * 1e4, 0, 0, 0, 0];
    multipliers_[7] = [0, 0, 0, 200, 600, 2500, 4 * 1e4, 8 * 1e4, 0, 0, 0];
    multipliers_[8] = [0, 0, 0, 200, 300, 1000, 6500, 4 * 1e4, 9 * 1e4, 0, 0];
    multipliers_[9] = [0, 0, 0, 200, 230, 400, 900, 1e4, 5 * 1e4, 1e5, 0];
    multipliers_[10] = [
      0 /** 10 picks, 0 correct */,
      0,
      0,
      130,
      200,
      400,
      700,
      2500,
      1e4,
      5 * 1e4,
      1e5 /** 10 picks, 10 correct */
    ];

    // Pre defined houseEdges_
    // note this still need to be set
    houseEdges_[0] = 0;
    houseEdges_[1] = 97;
    houseEdges_[2] = 97;
    houseEdges_[3] = 97;
    houseEdges_[4] = 97;
    houseEdges_[5] = 97;
    houseEdges_[6] = 97;
    houseEdges_[7] = 97;
    houseEdges_[8] = 97;
    houseEdges_[9] = 97;
    houseEdges_[10] = 97;


  }



  /*==================================================== Functions ===========================================================*/


  function getMultipliersOfPick(
    uint256 _picks
  ) public view returns (uint256[11] memory multiplierArray_) {
    multiplierArray_ = multipliers_[_picks];
  }

  function getMultiplier(
    uint256 _picks,
    uint256 _correct
  ) public view returns (uint256 multiplierOfGame_) {
    multiplierOfGame_ = multipliers_[_picks][_correct];
  }

  function calcReward(
    uint256 _picks,
    uint256 _correct,
    uint256 _wager
  ) internal view returns (uint256 reward_) {
    uint256 multiplier = multipliers_[_picks][_correct];
    unchecked {
      reward_ = (_wager * multiplier) / 1e2;
    }
  }

  function houseEdges(uint32 _picks) external view returns (uint64 houseEdge_) {
    houseEdge_ = uint64(houseEdges_[_picks]);
  }

  /**
   * @notice function that takes the vrf randomness and returns the keno result numbers
   * @dev in keno no drawn number can be repeated, therefor we use Fisher - Yates shuffle of a 40 numbers array
   * @param _randoms the random value of the vrf
   */
  function getResultNumbers(uint256 _randoms) public view returns (uint256[] memory resultNumbers_) {
    uint256[] memory allNumbersArray_ = new uint256[](amountNumbers);
    resultNumbers_ = new uint256[](10);

    // Initialize an array with values from 1 to 40
    for (uint256 i = 0; i < amountNumbers; ++i) {
      allNumbersArray_[i] = i + 1;
    }

    // Perform a Fisher-Yates shuffle to randomize the array
    for (uint256 y = 39; y >= 1; --y) {
      uint256 value_ = uint256(keccak256(abi.encodePacked(_randoms, y))) % (y + 1);
      (allNumbersArray_[y], allNumbersArray_[value_]) = (
        allNumbersArray_[value_],
        allNumbersArray_[y]
      );
    }

    // Select the first 10 numbers from the shuffled array
    for (uint256 x = 0; x < amountUniqueDraws; ++x) {
      resultNumbers_[x] = allNumbersArray_[x];
    }

    return resultNumbers_;
  }

  /**
   *
   * @param _randomNumbers array with random numbers
   * @param _playerChoices array with player number choices
   * @param _wager wager amount of the player
   */
  function _checkHowMuchCorrect(
    uint256[] memory _randomNumbers,
    uint32[] memory _playerChoices,
    uint256 _wager
  ) public view returns (uint256 reward_) {
    require(_randomNumbers.length == amountUniqueDraws, "Keno: _random  must be of length 10");
    require(_playerChoices.length <= amountUniqueDraws, "Keno: _random  must be of length 10");
    // Create a boolean array that can handle up to 100 values
    bool[amountNumbers] memory exists_;
    for (uint i = 0; i < _randomNumbers.length; i++) {
      // Subtract one because array indices are 0-based
      exists_[_randomNumbers[i] - 1] = true;
    }

    // Check overlaps / correct numbers ->  amountCorrect_
    uint256 amountCorrect_ = 0;
    for (uint x = 0; x < _playerChoices.length; x++) {
      if (exists_[_playerChoices[x] - 1]) {
        amountCorrect_++;
      }
    }

    reward_ = calcReward(_playerChoices.length, amountCorrect_, _wager);
  }

  /**

   * @param _randoms array with random values
   * @return payout_ total payout amount of all rounds combined
   * @return playedGameCount_ count of played games_
   * @return payouts_ array with payouts per round
   */
  function play(uint256[] memory _randoms, uint256 count, uint32[] memory choices, uint256 wager) public view returns (uint256 payout_, uint256 playedGameCount_, uint256[] memory payouts_)
  {
    payouts_ = new uint[](count);
    playedGameCount_ = uint256(count);
    uint32[] memory choices_ = new uint32[](choices.length);
    choices_ = choices;

    for (uint256 i = 0; i < playedGameCount_; ++i) {
      // convert the random value to the result numbers (10 picks, between 1-40, no repeats)
      uint256[] memory resultNumbers_ = getResultNumbers(_randoms[i]);
      // check how much correct numbers the player has
      uint256 reward_ = _checkHowMuchCorrect(resultNumbers_, choices_, wager);
      payouts_[i] = reward_;
      unchecked {
        payout_ += reward_;
      }
      
      
    }
  }

  /**
   * @notice function that checks if the players choice is valid
   * @dev in Keno player needs to chose between 1 and 10 numbers
   * @dev player cannot chose the same number multiple times
   * @param _gameData the chosen numbers of the player
   */
  function _processPlayerChoice(uint32[] memory _gameData) internal pure {
    require(_gameData.length != 0, "Keno: Can't choose less than 1 number");
    require(_gameData.length <= 10, "Keno: Can't choose more than 10 numbers");
    bool[40] memory exists;
    uint256 length_ = _gameData.length;
    // can't choose more than 10 numbers
    for (uint256 i = 0; i < length_; ++i) {
      require(_gameData[i] != 0, "Keno: Choice 0 isn't allowed");
      require(_gameData[i] <= 40, "Keno: Choice larger as 40 isn't allowed");
      // Subtract one because array indices are 0-based
      if (exists[_gameData[i] - 1]) {
        // This value is a duplicate
        revert("Keno: Number not available/alreadychosen");
      }
      exists[_gameData[i] - 1] = true;
    }
  }

}