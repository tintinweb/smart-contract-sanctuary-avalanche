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
        string metadata;
        string date;
        string status;
        string collectedBy;
        string receivedBy;
    }

    using Counters for Counters.Counter;
    Counters.Counter private supply;
    mapping(string => Baggage) public Baggages;
    mapping(string => bool) private BaggageExists;

    event BaggageCheckedIn(
        string indexed bagTag,
        uint256 indexed dateTime,
        string indexed checkedInBy
    );
    event BaggageBoarded(
        string indexed bagTag,
        uint256 indexed dateTime,
        string indexed handledBy
    );
    event BaggageDeBoarded(
        string indexed bagTag,
        uint256 indexed dateTime,
        string indexed handledBy
    );

    event BaggageReceived(
        string indexed bagTag,
        uint256 indexed dateTime,
        string indexed receivedBy
    );

    function checkInBaggage(
        uint256 noOfBags,
        string[] memory _bagTags,
        string memory _metadata,
        string memory _collectedBy
    ) public returns (uint256) {
        require(
            _bagTags.length == noOfBags,
            "no of bags and bagtags length mismatch"
        );
        require(noOfBags <= 4, "maximum 4 check in baggage allowed");

        for (uint256 index = 0; index < noOfBags; index++) {
            Baggage storage newBaggage = Baggages[_bagTags[index]];
            newBaggage.metadata = _metadata;
            newBaggage.status = "collected";
            newBaggage.collectedBy = _collectedBy;

            BaggageExists[_bagTags[index]] = true;
            emit BaggageCheckedIn(
                _bagTags[index],
                block.timestamp,
                _collectedBy
            );
        }

        return supply.current();
    }

    function boardBaggage(
        string memory _bagTag,
        string memory _handledBy
    ) public returns (string memory) {
        require(BaggageExists[_bagTag] == true, "no bag tag found");
        Baggage storage newBaggage = Baggages[_bagTag];
        newBaggage.status = "on boarded to air craft";

        emit BaggageBoarded(_bagTag, block.timestamp, _handledBy);
        return _bagTag;
    }

    function deBoardBaggage(
        string memory _bagTag,
        string memory _handledBy
    ) public returns (string memory) {
        require(BaggageExists[_bagTag] == true, "no bag tag found");
        Baggage storage newBaggage = Baggages[_bagTag];
        newBaggage.status = "de boarded from air craft";

        emit BaggageDeBoarded(_bagTag, block.timestamp, _handledBy);
        return _bagTag;
    }

    function receiveBaggage(
        string memory _bagTag,
        string memory _receivedBy
    ) public returns (string memory) {
        require(BaggageExists[_bagTag] == true, "no bag tag found");
        Baggage storage newBaggage = Baggages[_bagTag];
        newBaggage.receivedBy = _receivedBy;
        newBaggage.status = "received";

        emit BaggageReceived(_bagTag, block.timestamp, _receivedBy);
        return _bagTag;
    }
}