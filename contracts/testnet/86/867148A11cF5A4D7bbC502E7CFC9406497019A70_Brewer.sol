//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

///////////////////////////////
// Show support - buy a brew //
///////////////////////////////

// Example Contract Address on Fuji: 0x8029Fa22bc25029d92D4891E2fAd0D391F71453c

contract Brewer {
    // Event to emit when a Brew is created.
    event NewBrew(
        address indexed from,
        uint256 timestamp,
        string name,
        string message
    );
    
    // Brew struct.
    struct Brew {
        address from;
        uint256 timestamp;
        string name;
        string message;
    }
    
    // Address of contract deployer. Marked payable so that
    // we can withdraw to this address later.
    address payable owner;

    // List of all brews received from coffee purchases.
    Brew[] brews;

    constructor() {
        // Store the address of the deployer as a payable address.
        // When we withdraw funds, we'll withdraw here.
        owner = payable(msg.sender);
    }

    /**
     * @dev fetches all stored brews
     */
    function get_memos() public view returns (Brew[] memory) {
        return brews;
    }

    /**
     * @dev buy a brew for the owner (sends an ETH tip and leaves a message)
     * @param _name name of the brew purchaser
     * @param _message a nice message from the purchaser
     */
    function buy_brew(string memory _name, string memory _message) public payable {
        require(msg.value > 0, "value must be greater than 0");

        // Add the memo to storage!
        brews.push(Brew(
            msg.sender,
            block.timestamp,
            _name,
            _message
        ));

        // Emit a NewBrew event with details about the memo.
        emit NewBrew(
            msg.sender,
            block.timestamp,
            _name,
            _message
        );
    }

    /**
     * @dev send the entire balance stored in this contract to the owner
     */
    function withdraw() public {
        require(msg.sender == owner, "only the owner can withdraw funds");
        uint256 balance = address(this).balance;
        require(balance > 0, "balance must be greater than 0");
        (bool success,) = owner.call{value: balance}("");
        require(success, "transfer failed");
    }
}