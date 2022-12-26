/**
 *Submitted for verification at snowtrace.io on 2022-12-26
*/

/**
 *Submitted for verification at snowtrace.io on 2022-12-21
*/

/**
 *Submitted for verification at snowtrace.io on 2022-12-16
*/

/**
 *Submitted for verification at snowtrace.io on 2022-08-31
 */

// File: @chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol

pragma solidity ^0.8.0;

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
    function checkUpkeep(bytes calldata checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

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

// File: @chainlink/contracts/src/v0.8/KeeperBase.sol

pragma solidity ^0.8.0;

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

// File: @chainlink/contracts/src/v0.8/KeeperCompatible.sol

pragma solidity ^0.8.0;

abstract contract KeeperCompatible is KeeperBase, KeeperCompatibleInterface {}

// File: contracts/1_Storage.sol

pragma solidity >=0.7.0 <0.9.0;

contract Storage is KeeperCompatible {
    bool public paused = false;
    bool public flip = true;
    bool public flipChainlink = true;

    event Bravo(address);

    event Pause(address);

    modifier notPaused() {
        require(paused == false, "We are paused sir");
        _;
    }

    //Warzone
    function emergency() public notPaused {
        require(flip == true, "Too slow sir");
        paused = true;
        emit Pause(msg.sender);
    }

    function fight() public notPaused {
        require(flip == false, "Too slow sir");
        flip = true;
        emit Bravo(msg.sender);
    }

    function chainlink() public notPaused {
        require(flipChainlink == false, "Too slow sir");
        flipChainlink = true;
    }

    //Referee
    function reset() public {
        paused = false;
        flip = true;
        flipChainlink = true;
    }

    function setFlips(bool _flip, bool _chainlink) public notPaused {
        flip = _flip;
        flipChainlink = _chainlink;
    }

    //Chainlink
    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        cannotExecute
        returns (bool upkeepNeeded, bytes memory performData)
    {
        if (!flip) return (true, bytes(""));
        if (!flipChainlink) return (true, bytes(""));
        return (false, bytes(""));
    }

    function performUpkeep(bytes calldata performData) external notPaused override {
        if (!flipChainlink) chainlink();
        if (!flip) fight();
    }
}