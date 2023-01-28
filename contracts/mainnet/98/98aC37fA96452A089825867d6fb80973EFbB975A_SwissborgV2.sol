/**
 *Submitted for verification at snowtrace.io on 2023-01-28
*/

pragma solidity ^0.8.0;

contract TriggeringRuleBase {
  // Error message for when contract is called from a non-simulated backend
  error OnlyD23E();

  /**
   * @notice Method that prevents exection by a non-D23E simulated backend.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0xd23e003FB0eef30D32D09EB95df035dCBF7b79A8)) {
      revert OnlyD23E();
    }
  }

  /** 
   * @notice Modifier that prevents exection by a non-D23E simulated backend.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

interface TriggeringRules {
  /**
   * @notice Method that is simulated by d23e to see if any work actually needs to 
   * be performed. Although it is only simulated, we recommend consuming as few gas 
   * as possible.
   * @dev To ensure that it is never called, we recommend to add the `cannotExecute` 
   * modifier from `TriggeringRuleBase` to your implementation of this method.
   * @param checkData Specified in the upkeep registration so it is always the 
   * same for a registered triggering rule. This can easily be broken down into 
   * specific arguments using `abi.decode`, so multiple triggering rules can be 
   * registered on the same contract and easily differentiated by the contract.
   * @return upkeepNeeded Boolean to indicate whether to trigger actions.
   */
  function checkTriggeringRule(
      bytes calldata checkData
  ) external view returns (
      bool upkeepNeeded
  );
}

abstract contract TriggeringRule is TriggeringRuleBase, TriggeringRules {}

interface SwissborgV1 {
    function flip() external view returns (bool);
}

contract SwissborgV2 is TriggeringRule {
      function checkTriggeringRule(
      bytes calldata checkData
  ) external view override returns (
      bool upkeepNeeded
  ) {
      SwissborgV1 targetAddress = SwissborgV1(0x8AE4c11b24748A8D900BB5839812A1e71E96215f);
      return !targetAddress.flip();
  }
}