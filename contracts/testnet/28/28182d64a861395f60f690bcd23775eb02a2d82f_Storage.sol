/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


contract Storage {
    mapping(uint32 => uint32[]) public multipliers;
    constructor() {
      // Pre defined multipliers
      multipliers[6] = [1000, 100, 70, 40, 70, 100, 1000];
      multipliers[7] = [1500, 250, 70, 40, 40, 70, 250, 1500];
      multipliers[8] = [2050, 400, 90, 60, 40, 60, 90, 400, 2050];
      multipliers[9] = [4500, 800, 90, 60, 40, 40, 60, 90, 800, 4500];
      multipliers[10] = [4700, 800, 200, 90, 60, 40, 60, 90, 200, 800, 4700];
      multipliers[11] = [6500, 1700, 400, 90, 60, 40, 40, 60, 90, 400, 1700, 6500];
      multipliers[12] = [7000, 1600, 300, 200, 90, 60, 40, 60, 90, 200, 300, 1600, 7000];

    }

    function getResultNumbers(uint32 rows_, uint256[] calldata _randoms, uint32 _gameCount) public pure returns (uint256[] memory numbers_) {
      
      numbers_ = new uint256[](_gameCount * rows_);
      uint256 random_;
      uint32 randomIndex_;

      /// @notice generates count * row number random numbers
      for (uint8 i = 0; i < _randoms.length; ++i) {
        random_ = _randoms[i];
        randomIndex_ = i * rows_;

        for (uint8 s = 0; s < rows_; ++s) {
          numbers_[randomIndex_] = random_ & (1 << s);
          randomIndex_ += 1;
        }
      }
    }
    
    function getMultiplier(uint32 _rows, uint32 _index) public view returns (uint32 multiplier_) {
      multiplier_ = multipliers[_rows][_index];
    }
    function getMultipliers(uint32 _rows) public view returns (uint32[] memory multipliers_) {
      multipliers_ = multipliers[_rows];
    }
    
    function calcReward(uint32 _rows, uint32 _index, uint256 _wager) public view returns (uint256 reward_) {
      reward_ = (_wager * getMultiplier(_rows, _index)) / 1e2;
    }
    
    function play(uint32 rows_, uint32 _gameCount, uint32 _gameWager, uint256[] memory _resultNumbers) public view returns (uint256 payout_, uint32 playedGameCount_, uint256[] memory payouts_){
      payouts_ = new uint256[](_gameCount);
      playedGameCount_ = _gameCount;
      uint32 index_ = rows_;
      uint32 gameIndex_;

      for (uint32 i = 0; i < _resultNumbers.length; i++) {
        /// @notice calculates the final index by moving the ball movements sequentially on the index
        if (_resultNumbers[i] == 0) {
          index_--;
        } else {
          index_++;
        }

        if ((i + 1) % rows_ == 0) {
          gameIndex_ = i / rows_;

          payouts_[gameIndex_] = calcReward(rows_, index_ / 2, _gameWager);
          payout_ += payouts_[gameIndex_];

          index_ = rows_;
        }
      }
    }

    function getPayoutFromRandoms(uint32 rows_, uint32 _gameCount, uint32 _gameWager, uint256[] calldata _randoms) public view returns (uint256 payout_, uint32 playedGameCount_, uint256[] memory payouts_){
      uint256[] memory _resultNumbers = getResultNumbers(rows_, _randoms, _gameCount);
      payouts_ = new uint256[](_gameCount);
      playedGameCount_ = _gameCount;
      uint32 index_ = rows_;
      uint32 gameIndex_;

      for (uint32 i = 0; i < _resultNumbers.length; i++) {
        /// @notice calculates the final index by moving the ball movements sequentially on the index
        if (_resultNumbers[i] == 0) {
          index_--;
        } else {
          index_++;
        }

        if ((i + 1) % rows_ == 0) {
          gameIndex_ = i / rows_;

          payouts_[gameIndex_] = calcReward(rows_, index_ / 2, _gameWager);
          payout_ += payouts_[gameIndex_];

          index_ = rows_;
        }
      }
    }
}