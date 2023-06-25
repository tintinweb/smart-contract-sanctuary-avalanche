// SPDX-License-Identifier: MIT OR Apache-2.0

pragma solidity ^0.8.4;

interface IMessageRecipient {
    /**
     * @notice Handle an interchain message
     * @param _origin Domain ID of the chain from which the message came
     * @param _sender Address of the message sender on the origin chain as bytes32
     * @param _body Raw bytes content of message body
     */
    function handle(uint32 _origin, bytes32 _sender, bytes calldata _body) external;
}

/**
 * @title Carbon Credit Receiver
 * @notice Receive users' carbon credit totals from L1, using Hyperlane.
 */
contract CarbonCreditReceiver is IMessageRecipient {
    // The L2 Hyperlane mailbox.
    address private immutable _mailbox;

    mapping(address => uint256) private _carbonCreditBalances;

    event TotalCarbonCreditsReceived(address indexed user, uint256 balance);

    modifier onlyMailbox() {
        require(msg.sender == _mailbox, "Sender not mailbox");
        _;
    }

    constructor(address mailbox) {
        _mailbox = mailbox;
    }

    /**
     * @dev Check the L1 credit balance of the given user. Same interface as on L1
     */
    function getTotalCarbonCredits(address user) external view returns (uint256) {
        return _carbonCreditBalances[user];
    }

    /**
     * @dev This will be called by the relayer.
     */
    function handle(uint32, bytes32, bytes calldata _body) external override onlyMailbox {
        (address user, uint256 balance) = abi.decode(_body, (address, uint256));

        _carbonCreditBalances[user] = balance;

        emit TotalCarbonCreditsReceived(user, balance);
    }
}