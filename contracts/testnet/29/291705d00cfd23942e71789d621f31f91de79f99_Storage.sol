/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-20
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


contract Storage {
    mapping(uint256 => uint256) public multipliers;
    uint256 PRECISION = 1000000000000000000;
    uint32 combinationCount = 343;
    constructor() {
    multipliers[0] = 5;
	  multipliers[1] = 3;
	  multipliers[2] = 3;
	  multipliers[3] = 3;
	  multipliers[4] = 3;
	  multipliers[5] = 3;
	  multipliers[6] = 3;
	  multipliers[7] = 2;
	  multipliers[8] = 2;
	  multipliers[9] = 2;
	  multipliers[10] = 2;
	  multipliers[11] = 2;
	  multipliers[12] = 2;
	  multipliers[13] = 2;
	  multipliers[14] = 2;
	  multipliers[15] = 2;
	  multipliers[16] = 2;
	  multipliers[17] = 2;
	  multipliers[18] = 2;
	  multipliers[19] = 2;
	  multipliers[20] = 2;
	  multipliers[21] = 2;
	  multipliers[22] = 2;
	  multipliers[23] = 2;
	  multipliers[24] = 2;
	  multipliers[25] = 2;
	  multipliers[26] = 2;
	  multipliers[27] = 2;
	  multipliers[28] = 2;
	  multipliers[29] = 2;
	  multipliers[30] = 2;
	  multipliers[31] = 2;
	  multipliers[32] = 2;
	  multipliers[33] = 2;
	  multipliers[34] = 2;
	  multipliers[35] = 2;
	  multipliers[36] = 2;
	  multipliers[37] = 2;
	  multipliers[38] = 2;
	  multipliers[39] = 2;
	  multipliers[40] = 2;
	  multipliers[41] = 2;
	  multipliers[42] = 2;
	  multipliers[43] = 2;
	  multipliers[44] = 2;
	  multipliers[45] = 2;
	  multipliers[46] = 2;
	  multipliers[47] = 2;
	  multipliers[48] = 2;
	  multipliers[114] = 10;
	  multipliers[117] = 10;
	  multipliers[171] = 12;
	  multipliers[173] = 12;
	  multipliers[228] = 20;
	  multipliers[229] = 20;
	  multipliers[285] = 45;
	  multipliers[342] = 100;

    }

    function modNumber(uint256 _number, uint32 _mod) internal pure returns (uint256) {
      return _mod > 0 ? _number % _mod : _number;
    }

    function modNumbers(uint256[] memory _numbers, uint32 _mod) internal pure returns (uint256[] memory) {
      uint256[] memory modNumbers_ = new uint[](_numbers.length);

      for (uint256 i = 0; i < _numbers.length; i++) {
        modNumbers_[i] = modNumber(_numbers[i], _mod);
      }

      return modNumbers_;
    }

    function getMultiplier(uint256 _result) public view returns (uint256 multiplier_) {
      multiplier_ = multipliers[_result] * PRECISION;
    }

    /// @notice calculates reward results
    /// @param _result random number that modded with combinationCount
    /// @param _wager players wager for a game
    function calcReward(uint256 _result, uint256 _wager) public view returns (uint256 reward_) {
      reward_ = (_wager * getMultiplier(_result)) / PRECISION;
    }

    function getResultNumbers(uint256[] calldata _randoms) public view returns (uint256[] memory numbers_) {
      numbers_ = modNumbers(_randoms, combinationCount);
    }


  function play(uint32 _gameWager, uint32 _gameCount, uint256[] memory _resultNumbers) public view returns (uint256 payout_, uint32 playedGameCount_, uint256[] memory payouts_)
  {
    payouts_ = new uint[](_gameCount);
    playedGameCount_ = _gameCount;

    for (uint8 i = 0; i < _gameCount; ++i) {
      uint256 reward_ = calcReward(_resultNumbers[i], _gameWager);

      payouts_[i] = reward_ > _gameWager ? reward_ - _gameWager : 0;
      payout_ += reward_;

      
    }
  }

    function getPayoutFromRandoms(uint32 _gameCount, uint32 _gameWager, uint256[] calldata _randoms) public view returns (uint256 payout_){
      uint256[] memory _resultNumbers = getResultNumbers(_randoms);

      uint256[] memory payouts_;
      

      for (uint8 i = 0; i < _gameCount; ++i) {
        uint256 reward_ = calcReward(_resultNumbers[i], _gameWager);

        payouts_[i] = reward_ > _gameWager ? reward_ - _gameWager : 0;
        payout_ += reward_;

      
      }
      return payout_;
    }
}