// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import {ICLEmergencyOracle} from '../interfaces/ICLEmergencyOracle.sol';

contract EmergencyConsumerMock {
  ICLEmergencyOracle public CL_EMERGENCY_ORACLE;

  int256 public emergencyCount;
  bool public inEmergencyState;

  event NewEmergency(int256 emergency);

  function updateCLEmergencyOracle(address clEmergencyOracle) external {
    CL_EMERGENCY_ORACLE = ICLEmergencyOracle(clEmergencyOracle);
  }

  function getEmergencyState() external returns (int256) {
    require(address(CL_EMERGENCY_ORACLE) != address(0), 'CL_EMERGENCY_ORACLE_NOT_SET');

    (,int256 answer,,,) = CL_EMERGENCY_ORACLE.latestRoundData();

    if (answer > emergencyCount && !inEmergencyState) {
      inEmergencyState = true;
      emit NewEmergency(answer);
    }

    return answer;
  }

  function solveEmergency() external onlyInEmergency {
    emergencyCount++;
    inEmergencyState = false;
  }

  modifier onlyInEmergency {
    require(inEmergencyState == true, 'NOT_IN_EMERGENCY');
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICLEmergencyOracle {
  function latestRoundData() external view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}