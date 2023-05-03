// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";

contract AirBaggage {
    struct Baggage {
        uint256 bagTag;
        string metadata;
        string date;
        string status;
        string collectedBy;
        string receivedBy;
    }

    using Counters for Counters.Counter;
    Counters.Counter private supply;
    mapping(uint256 => Baggage) public Baggages;

    event BaggageCollected(
        uint256 indexed bagTag,
        address indexed collectedBy,
        uint256 indexed dateTime
    );

    event BaggageCheckedIn(uint256 indexed bagTag, uint256 indexed dateTime);
    event BaggageBoarded(uint256 indexed bagTag, uint256 indexed dateTime);
    event BaggageDeBoarded(uint256 indexed bagTag, uint256 indexed dateTime);

    event BaggageReceived(
        uint256 indexed bagTag,
        uint256 indexed dateTime,
        string indexed receivedBy
    );

    function collectBaggage(
        uint256 _bagTag,
        string memory _metadata,
        string memory _collectedBy
    ) public returns (uint256) {
        supply.increment();

        Baggage storage newBaggage = Baggages[supply.current()];
        newBaggage.bagTag = _bagTag;
        newBaggage.metadata = _metadata;
        newBaggage.status = "collected";
        newBaggage.collectedBy = _collectedBy;
        emit BaggageCollected(_bagTag, msg.sender, block.timestamp);
        return supply.current();
    }

    function checkInBaggage(uint256 identifier) public returns (uint256) {
        require(identifier <= supply.current(), "no bag tag found");
        Baggage storage newBaggage = Baggages[identifier];
        newBaggage.status = "checked in";

        emit BaggageCheckedIn(identifier, block.timestamp);
        return identifier;
    }

    function boardBaggage(uint256 identifier) public returns (uint256) {
        require(identifier <= supply.current(), "no bag tag found");
        Baggage storage newBaggage = Baggages[identifier];
        newBaggage.status = "on boarded to air craft";

        emit BaggageBoarded(newBaggage.bagTag, block.timestamp);
        return identifier;
    }

    function deBoardBaggage(uint256 identifier) public returns (uint256) {
        require(identifier <= supply.current(), "no bag tag found");
        Baggage storage newBaggage = Baggages[identifier];
        newBaggage.status = "de boarded from air craft";

        emit BaggageDeBoarded(newBaggage.bagTag, block.timestamp);
        return identifier;
    }

    function receiveBaggage(
        uint256 identifier,
        string memory _receivedBy
    ) public returns (uint256) {
        require(identifier <= supply.current(), "no bag tag found");
        Baggage storage newBaggage = Baggages[identifier];
        newBaggage.receivedBy = _receivedBy;
        newBaggage.status = "received";

        emit BaggageReceived(newBaggage.bagTag, block.timestamp, _receivedBy);
        return identifier;
    }
}