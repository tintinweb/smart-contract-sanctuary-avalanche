/**
 *Submitted for verification at snowtrace.io on 2022-06-23
*/

/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface KeeperCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

contract KeeperBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

interface IOracle {
    function update() external;
}


abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

contract Counter is KeeperCompatibleInterface {
 
    uint public counter;
    uint public interval;
    uint public lastTimeStamp;
    address public admin;
    IOracle public Oracle = IOracle(0xAe53120b72a8FdB9Dd6f16D86D8e152B6914bEC8);

    modifier OnlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin!");
        _;
    }

    constructor(uint updateInterval, uint _lastTimeStamp) {
      interval = updateInterval;
      lastTimeStamp = _lastTimeStamp;
      counter = 0;
      admin = msg.sender;
    }

    function updateInterval(uint _interval) external OnlyAdmin{
       interval = _interval;
    }

    function updateAdmin(address _admin) external OnlyAdmin{
       admin = _admin;
    }

    function checkUpkeep(bytes calldata /* checkData */) external view override returns (bool upkeepNeeded, bytes memory /* performData */) {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(bytes calldata /* performData */) external override {
      if ((block.timestamp - lastTimeStamp) > interval ) {
            lastTimeStamp = block.timestamp;
            Oracle.update();
            counter = counter + 1; 
        }
    }
}