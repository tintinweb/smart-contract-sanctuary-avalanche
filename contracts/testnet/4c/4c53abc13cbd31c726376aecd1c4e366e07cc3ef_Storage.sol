/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.2 <0.9.0;


contract Storage {
    
    function getResultNumbers(uint32 rows_, uint256[] calldata _randoms, uint32 _gameCount) external pure returns (uint256[] memory numbers_) {
      
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
    
}