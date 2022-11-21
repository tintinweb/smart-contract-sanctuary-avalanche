// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// AutomationCompatible.sol imports the functions from both ./AutomationBase.sol and
// ./interfaces/AutomationCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

interface IFortuneTeller {
    function seekFortune() external payable;
}

contract FortuneSeeker is AutomationCompatibleInterface {
    event InsufficientFunds(uint256 balance);
    event TargetToppedUp(uint256 amount);
    event ReceivedFunding(uint256 amount);

    address public owner;
    // Target contract that is monitored.
    address public fortuneTeller;

    string public fortune;

    /**
     * Use an interval in seconds and a timestamp to slow execution of Upkeep
     */
    uint256 public immutable interval; // Seconds
    uint256 public lastTimeStamp; // Block timestamp

    modifier OnlyOwner() {
        require(owner == msg.sender, "Caller not owner");
        _;
    }

    constructor(address _fortuneTeller, uint256 updateInterval) {
        fortuneTeller = _fortuneTeller;
        lastTimeStamp = block.timestamp;
        interval = updateInterval;
        owner = msg.sender;
    }

    // We don't use the checkData in this example. The checkData is defined when the Upkeep was registered.
    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool intervalExceeded = (block.timestamp - lastTimeStamp) > interval;
        // bool underFunded = (FortuneTeller.balance <= 1 ether);
        upkeepNeeded == intervalExceeded; // && underFunded;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        /// TODO FIX if else logic

        if (address(this).balance < 1 ether) {
            emit InsufficientFunds(address(this).balance);
            revert("Not enough balance to perform topup");
        }

        //We highly recommend revalidating the upkeep in the performUpkeep function
        bool intervalExceeded = (block.timestamp - lastTimeStamp) > interval;
        // bool underFunded = (FortuneTeller.balance <= 1 ether);
        // bool upkeepNeeded = intervalExceeded && underFunded;

        if (true) {
            lastTimeStamp = block.timestamp;
            uint256 topup = 3 ether;

            // (bool sent, ) = FortuneTeller.call{value: topup}("");
            // require(sent, "Failed to send Ether in upkeep");

            emit TargetToppedUp(topup);
        }
        // We don't use the performData in this example. The performData is generated by the Automation Node's call to your checkUpkeep function
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function withdrawBalance() public payable OnlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether in withdraw");
    }

    function seekFortune() public {
        IFortuneTeller teller = IFortuneTeller(fortuneTeller);
        teller.seekFortune{value: 0.1 ether}();
    }

    function fulfillFortune(string memory _fortune) external {
        fortune = _fortune;
    }

    receive() external payable {
        emit ReceivedFunding(msg.value);
    }
}