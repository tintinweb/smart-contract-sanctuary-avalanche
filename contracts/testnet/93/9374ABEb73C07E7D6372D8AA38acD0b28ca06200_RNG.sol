// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract RNG {
    struct eventsStruct {
        mapping(uint256 => bool) numbers;
        mapping(uint256 => bool) checkNumberExcluded;
        uint256[] numbersArray;
        uint256[] excludedNumbers;
        uint256 startTimeStamp;
        uint256 endTimeStamp;
        uint256 range;
        uint256 offSet;
        uint256 numberOfWinners;
        bool status;
        bool existStatus;
    }

    mapping(uint256 => eventsStruct) public events;

    uint8 eventId = 0;

    event eventAdded(uint256 eventId, bool status);
    event randomWinnerNumber(uint256 eventId, uint256[] randomNumber);
    event dataReset(uint256 eventId, bool status);
    event removeAndReset(uint256 eventId, bool status);

    // Add event
    function addEvent(
        uint256 _startTimeStamp,
        uint256 _endTimeStamp,
        uint256 _range,
        uint256 _offSet,
        uint256 _numberOfWinners,
        uint256[] memory _numbersToExclude
    ) public returns (bool) {
        require(events[eventId].existStatus == false, "Event: Already exist");
        require(
            _range > _numbersToExclude.length,
            "Event: Range must be greater then numbers to exclude"
        );
        require(
            _range >= _numberOfWinners,
            "Event: Range must be greater or equal then number of winners"
        );
        require(_range >= (_numbersToExclude.length + _numberOfWinners), "Event: Range must be greater or equal");

        eventsStruct storage eventObject = events[eventId];
        eventObject.startTimeStamp = _startTimeStamp;
        eventObject.endTimeStamp = _endTimeStamp;
        eventObject.range = _range;
        eventObject.offSet = _offSet;
        eventObject.numberOfWinners = _numberOfWinners;
        eventObject.existStatus = true;
        eventObject.excludedNumbers = _numbersToExclude;

        for (uint8 i = 0; i < _numbersToExclude.length; i++) {
            eventObject.checkNumberExcluded[_numbersToExclude[i]] = true;
        }

        emit eventAdded(eventId, true);
        eventId++;
        return true;
    }

    // find random number
    function randomWinner(uint256 _eventId) public returns (uint256[] memory) {
        eventsStruct storage choosedEvent = events[_eventId];
        require(
            choosedEvent.existStatus == true,
            "Event with this Id not Exist"
        );
        require(choosedEvent.status == false, "Lottery: Already Dised");
        require(
            (choosedEvent.startTimeStamp <= block.timestamp) &&
                (block.timestamp <= choosedEvent.endTimeStamp),
            "TimeStamp: Shoud be in timestamp"
        );

        uint256 numbersLength = choosedEvent.numberOfWinners;

        uint256 randomNumber;
        uint256 count = 0;
        do {
            randomNumber =
                uint256(
                    keccak256(
                        abi.encodePacked(block.timestamp, msg.sender, count)
                    )
                ) %
                choosedEvent.range;
            randomNumber = randomNumber + choosedEvent.offSet;

            if (
                choosedEvent.numbers[randomNumber] == false &&
                choosedEvent.checkNumberExcluded[randomNumber] != true
            ) {
                choosedEvent.numbers[randomNumber] = true;
                choosedEvent.numbersArray.push(randomNumber);
                numbersLength--;
            }

            count++;
        } while (numbersLength > 0);

        choosedEvent.status = true;
        emit randomWinnerNumber(_eventId, choosedEvent.numbersArray);
        return (choosedEvent.numbersArray);
    }

    // Get winners
    function getAllWinners(uint256 _eventId)
        public
        view
        returns (uint256[] memory)
    {
        require(
            events[_eventId].existStatus == true,
            "Event: Event with this id not exist"
        );

        return events[_eventId].numbersArray;
    }

    // Check winner
    function checkWinner(uint256 _eventId, uint256 _number)
        public
        view
        returns (bool)
    {
        require(
            events[_eventId].existStatus == true,
            "Event: Event with this id not exist"
        );
        bool check = false;

        if (events[_eventId].numbers[_number] == true) {
            check = true;
        }

        return check;
    }

    // Reset the winners
    function resetData(uint256 _eventId) public returns (bool) {
        eventsStruct storage choosedEvent = events[_eventId];
        require(
            choosedEvent.existStatus == true,
            "Event with this Id not Exist"
        );

        uint256[] memory tempArray;
        for (uint8 i = 0; i < choosedEvent.numbersArray.length; i++) {
            choosedEvent.numbers[choosedEvent.numbersArray[i]] = false;
        }
        choosedEvent.numbersArray = tempArray;
        choosedEvent.status = false;

        emit dataReset(_eventId, true);
        return true;
    }

    // Remove and reset event data
    function removeAndResetEvent(uint256 _eventId) public returns (bool) {
        eventsStruct storage choosedEvent = events[_eventId];
        require(
            choosedEvent.existStatus == true,
            "Event with this Id not exist"
        );

        uint256[] memory tempArray;
        choosedEvent.existStatus = false;
        choosedEvent.startTimeStamp = 0;
        choosedEvent.endTimeStamp = 0;
        choosedEvent.range = 0;
        choosedEvent.offSet = 0;
        choosedEvent.status = false;

        for (uint8 i = 0; i < choosedEvent.numbersArray.length; i++) {
            choosedEvent.numbers[choosedEvent.numbersArray[i]] = false;
        }

        choosedEvent.numbersArray = tempArray;
        emit removeAndReset(_eventId, true);
        return true;
    }

    // Get current time stamp
    function getTimeStamp() public view returns (uint256) {
        return block.timestamp;
    }
}