/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-20
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


contract Storage {
    mapping(uint32 => uint32[]) public multipliers;
    constructor() {


    }
    uint256 PRECISION = 1000000000000000000;
    uint32 minMultiplier = 100;
    uint32 maxMultiplier = 10000;
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

    function getResultNumbers(uint256[] calldata _randoms) public view returns (uint256[] memory numbers_) {
    uint256[] memory H = modNumbers(_randoms, (maxMultiplier - minMultiplier + 1));
    uint256 E = maxMultiplier / 100;

    uint256[] memory randoms_ = new uint256[](_randoms.length);
    for (uint256 i = 0; i < _randoms.length; i++) {
      uint256 _multiplier = (E * maxMultiplier - H[i]) / (E * 100 - H[i]);

      if (modNumber(_randoms[i], 66) == 0) {
        _multiplier = 1;
      }

      if (_multiplier == 0) {
        _multiplier = minMultiplier;
      }
      randoms_[i] = _multiplier;
    }
    numbers_ = randoms_;
  }
  
    function isWon(uint256 _choice, uint256 _result) public pure returns (bool won_) {
      if (_choice <= _result) return true;
    }
    
    function calcReward(uint256 _wager, uint256 _multiplier) public view returns (uint256 reward_) {
      reward_ = (_wager * (_multiplier * 1e16)) / PRECISION;
    }
    
    function play(uint256 choice_, uint32 gameCount, uint32 gameWager, uint256[] memory _resultNumbers) public view returns (uint256 payout_, uint32 playedGameCount_, uint256[] memory payouts_)
  {
    payouts_ = new uint[](gameCount);
    playedGameCount_ = gameCount;

    
    uint256 reward_ = calcReward(gameWager, choice_);

    for (uint8 i = 0; i < gameCount; ++i) {
      if (isWon(choice_, _resultNumbers[i])) {
        payouts_[i] = reward_ - gameWager;
        payout_ += reward_;
      }

      
    }
  }

    function getPayoutFromRandoms(uint32 _gameCount, uint32 choice_, uint32 _gameWager, uint256[] calldata _randoms) public view returns (uint256 payout_){
      uint256[] memory _resultNumbers = getResultNumbers(_randoms);


      uint256 reward_ = calcReward(_gameWager, choice_);

      for (uint8 i = 0; i < _gameCount; ++i) {
        if (isWon(choice_, _resultNumbers[i])) {

          payout_ += reward_;
        }
      }
      return payout_;
    }
}