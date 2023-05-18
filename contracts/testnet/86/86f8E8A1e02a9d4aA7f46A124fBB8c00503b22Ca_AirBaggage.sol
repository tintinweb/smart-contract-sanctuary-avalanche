// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AirBaggage {
    uint256 public allowedCheckedInBaggage = 4;
    uint256 public allowedWeightPerBag = 30;
    string public weightUnit = "Kilogram (Kg)";

    struct Baggage {
        string metadata;
        string date;
        string status;
        string collectedBy;
        string receivedBy;
    }

    mapping(string => Baggage) private Baggages;
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
        string memory _checkedInBy
    ) public {
        require(
            _bagTags.length == noOfBags,
            "no of bags and bagtags length mismatch"
        );
        require(noOfBags <= 4, "maximum 4 check in baggage allowed");

        for (uint256 index = 0; index < noOfBags; index++) {
            Baggage storage newBaggage = Baggages[_bagTags[index]];
            newBaggage.metadata = _metadata;
            newBaggage.status = "checked In";
            newBaggage.collectedBy = _checkedInBy;

            BaggageExists[_bagTags[index]] = true;
            emit BaggageCheckedIn(
                _bagTags[index],
                block.timestamp,
                _checkedInBy
            );
        }

        return;
    }

    function boardBaggage(
        string memory _bagTag,
        string memory _handledBy
    ) public {
        require(BaggageExists[_bagTag] == true, "no bag tag found");
        Baggage storage newBaggage = Baggages[_bagTag];
        newBaggage.status = "on boarded to air craft";

        emit BaggageBoarded(_bagTag, block.timestamp, _handledBy);
        return;
    }

    function deBoardBaggage(
        string memory _bagTag,
        string memory _handledBy
    ) public {
        require(BaggageExists[_bagTag] == true, "no bag tag found");
        Baggage storage newBaggage = Baggages[_bagTag];
        newBaggage.status = "de boarded from air craft";

        emit BaggageDeBoarded(_bagTag, block.timestamp, _handledBy);
        return;
    }

    function receiveBaggage(
        string memory _bagTag,
        string memory _receivedBy
    ) public {
        require(BaggageExists[_bagTag] == true, "no bag tag found");
        Baggage storage newBaggage = Baggages[_bagTag];
        newBaggage.receivedBy = _receivedBy;
        newBaggage.status = "received";

        emit BaggageReceived(_bagTag, block.timestamp, _receivedBy);
        return;
    }

    function checkBagageStatus(
        string memory _bagTag
    ) public view returns (Baggage memory) {
        require(BaggageExists[_bagTag] == true, "no bag tag found");
        return Baggages[_bagTag];
    }
}