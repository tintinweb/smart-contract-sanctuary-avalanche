// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/// @title Hex Cartel Library
/// @author cd33
library HexCartelLibrary {
    struct Card {
        uint8 cardId;
        string cardDescription;
    }

    // NORMAL CARDS
    uint8 constant NORMAL1 = 1;
    uint8 constant NORMAL2 = 2;
    uint8 constant NORMAL3 = 3;
    uint8 constant NORMAL4 = 4;
    uint8 constant NORMAL5 = 5;
    uint8 constant NORMAL6 = 6;
    uint8 constant NORMAL7 = 7;
    uint8 constant NORMAL8 = 8;
    uint8 constant NORMAL9 = 9;
    uint8 constant NORMAL10 = 10;
    uint8 constant NORMAL11 = 11;
    uint8 constant NORMAL12 = 12;
    uint8 constant NORMAL13 = 13;

    // MUTANT CARDS
    uint8 constant MUTANT1 = 14;
    uint8 constant MUTANT2 = 15;
    uint8 constant MUTANT3 = 16;
    uint8 constant MUTANT4 = 17;
    uint8 constant MUTANT5 = 18;
    uint8 constant MUTANT6 = 19;
    uint8 constant MUTANT7 = 20;
    uint8 constant MUTANT8 = 21;
    uint8 constant MUTANT9 = 22;
    uint8 constant MUTANT10 = 23;
    uint8 constant MUTANT11 = 24;
    uint8 constant MUTANT12 = 25;
    uint8 constant MUTANT13 = 26;

    // CYBORG CARDS
    uint8 constant CYBORG1 = 27;
    uint8 constant CYBORG2 = 28;
    uint8 constant CYBORG3 = 29;
    uint8 constant CYBORG4 = 30;
    uint8 constant CYBORG5 = 31;
    uint8 constant CYBORG6 = 32;
    uint8 constant CYBORG7 = 33;
    uint8 constant CYBORG8 = 34;
    uint8 constant CYBORG9 = 35;
    uint8 constant CYBORG10 = 36;
    uint8 constant CYBORG11 = 37;
    uint8 constant CYBORG12 = 38;
    uint8 constant CYBORG13 = 39;

    /**
     * @notice Generates a random number.
     * @param _mod Maximum value returned.
     * @param _num Value used to add randomness.
     */
    function _generateRandomNumber(uint256 _mod, uint8 _num)
        private
        view
        returns (uint16)
    {
        return
            uint16(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            _num,
                            block.timestamp,
                            block.difficulty,
                            msg.sender
                        )
                    )
                ) % _mod
            );
    }

    /**
     * @notice Designates a card and returns the necessary information to the mint.
     * @param _num Value used to add randomness.
     * @param _dataNormal Necessary information about the normal cards.
     * @param _dataMutant Necessary information about the mutant cards.
     * @param _dataCyborg Necessary information about the cyborg cards.
     */
    function _getRandomCard(
        uint8 _num,
        uint16[14] memory _dataNormal,
        uint16[13] memory _dataMutant,
        uint16[13] memory _dataCyborg
    ) public view returns (Card memory) {
        uint16 randomNumber = _generateRandomNumber(_dataNormal[0], _num);
        if (randomNumber < _dataNormal[1]) {
            if (randomNumber < _dataNormal[2]) {
                return Card(NORMAL2, "HexCartel Type Normal #2");
            } else if (
                randomNumber >= _dataNormal[2] &&
                randomNumber < _dataNormal[2] + _dataNormal[3]
            ) {
                return Card(NORMAL3, "HexCartel Type Normal #3");
            } else if (
                randomNumber >= _dataNormal[2] + _dataNormal[3] &&
                randomNumber < _dataNormal[2] + _dataNormal[3] + _dataNormal[4]
            ) {
                return Card(NORMAL4, "HexCartel Type Normal #4");
            } else if (
                randomNumber >=
                _dataNormal[2] + _dataNormal[3] + _dataNormal[4] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5]
            ) {
                return Card(NORMAL5, "HexCartel Type Normal #5");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6]
            ) {
                return Card(NORMAL6, "HexCartel Type Normal #6");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7]
            ) {
                return Card(NORMAL7, "HexCartel Type Normal #7");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8]
            ) {
                return Card(NORMAL8, "HexCartel Type Normal #8");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9]
            ) {
                return Card(NORMAL9, "HexCartel Type Normal #9");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10]
            ) {
                return Card(NORMAL10, "HexCartel Type Normal #10");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10] +
                    _dataNormal[11]
            ) {
                return Card(NORMAL11, "HexCartel Type Normal #11");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10] +
                    _dataNormal[11] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10] +
                    _dataNormal[11] +
                    _dataNormal[12]
            ) {
                return Card(NORMAL12, "HexCartel Type Normal #12");
            } else if (
                randomNumber >=
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10] +
                    _dataNormal[11] +
                    _dataNormal[12] &&
                randomNumber <
                _dataNormal[2] +
                    _dataNormal[3] +
                    _dataNormal[4] +
                    _dataNormal[5] +
                    _dataNormal[6] +
                    _dataNormal[7] +
                    _dataNormal[8] +
                    _dataNormal[9] +
                    _dataNormal[10] +
                    _dataNormal[11] +
                    _dataNormal[12] +
                    _dataNormal[13]
            ) {
                return Card(NORMAL13, "HexCartel Type Normal #13");
            } else {
                return Card(NORMAL1, "HexCartel Type Normal #1");
            }
        } else if (
            randomNumber >= _dataNormal[1] &&
            randomNumber < _dataNormal[1] + _dataMutant[0]
        ) {
            return _getMutantCard(randomNumber, 0, _dataNormal[1], _dataMutant);
        } else {
            return
                _getCyborgCard(
                    randomNumber,
                    0,
                    _dataNormal[1],
                    _dataMutant[0],
                    _dataCyborg
                );
        }
    }

    /**
     * @notice Designates a mutant card and returns the necessary information to the mint.
     * @param _randomNumber Random number already generated.
     * @param _num Value used to add randomness.
     * @param normalTotalCards Total number of normal cards.
     * @param _dataMutant Necessary information about the mutant cards.
     */
    function _getMutantCard(
        uint16 _randomNumber,
        uint8 _num,
        uint16 normalTotalCards,
        uint16[13] memory _dataMutant
    ) public view returns (Card memory) {
        uint16 randomNumber;
        if (_randomNumber != 22222) {
            randomNumber = _randomNumber - normalTotalCards;
        } else {
            randomNumber = _generateRandomNumber(_dataMutant[0] + 1, _num);
        }
        if (randomNumber < _dataMutant[1]) {
            return Card(MUTANT2, "HexCartel Type Mutant #2");
        } else if (
            randomNumber >= _dataMutant[1] &&
            randomNumber < _dataMutant[1] + _dataMutant[2]
        ) {
            return Card(MUTANT3, "HexCartel Type Mutant #3");
        } else if (
            randomNumber >= _dataMutant[1] + _dataMutant[2] &&
            randomNumber < _dataMutant[1] + _dataMutant[2] + _dataMutant[3]
        ) {
            return Card(MUTANT4, "HexCartel Type Mutant #4");
        } else if (
            randomNumber >= _dataMutant[1] + _dataMutant[2] + _dataMutant[3] &&
            randomNumber <
            _dataMutant[1] + _dataMutant[2] + _dataMutant[3] + _dataMutant[4]
        ) {
            return Card(MUTANT5, "HexCartel Type Mutant #5");
        } else if (
            randomNumber >=
            _dataMutant[1] + _dataMutant[2] + _dataMutant[3] + _dataMutant[4] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5]
        ) {
            return Card(MUTANT6, "HexCartel Type Mutant #6");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6]
        ) {
            return Card(MUTANT7, "HexCartel Type Mutant #7");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7]
        ) {
            return Card(MUTANT8, "HexCartel Type Mutant #8");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8]
        ) {
            return Card(MUTANT9, "HexCartel Type Mutant #9");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9]
        ) {
            return Card(MUTANT10, "HexCartel Type Mutant #10");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9] +
                _dataMutant[10]
        ) {
            return Card(MUTANT11, "HexCartel Type Mutant #11");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9] +
                _dataMutant[10] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9] +
                _dataMutant[10] +
                _dataMutant[11]
        ) {
            return Card(MUTANT12, "HexCartel Type Mutant #12");
        } else if (
            randomNumber >=
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9] +
                _dataMutant[10] +
                _dataMutant[11] &&
            randomNumber <
            _dataMutant[1] +
                _dataMutant[2] +
                _dataMutant[3] +
                _dataMutant[4] +
                _dataMutant[5] +
                _dataMutant[6] +
                _dataMutant[7] +
                _dataMutant[8] +
                _dataMutant[9] +
                _dataMutant[10] +
                _dataMutant[11] +
                _dataMutant[12]
        ) {
            return Card(MUTANT13, "HexCartel Type Mutant #13");
        } else {
            return Card(MUTANT1, "HexCartel Type Mutant #1");
        }
    }

    /**
     * @notice Designates a cyborg card and returns the necessary information to the mint.
     * @param _randomNumber Random number already generated.
     * @param _num Value used to add randomness.
     * @param normalTotalCards Total number of normal cards.
     * @param mutantTotalCards Total number of mutant cards.
     * @param _dataCyborg Necessary information about the cyborg cards.
     */
    function _getCyborgCard(
        uint16 _randomNumber,
        uint8 _num,
        uint16 normalTotalCards,
        uint16 mutantTotalCards,
        uint16[13] memory _dataCyborg
    ) public view returns (Card memory) {
        uint16 randomNumber;
        if (_randomNumber != 22222) {
            randomNumber = _randomNumber - normalTotalCards - mutantTotalCards;
        } else {
            randomNumber = _generateRandomNumber(_dataCyborg[0] + 1, _num);
        }
        if (randomNumber < _dataCyborg[1]) {
            return Card(CYBORG2, "HexCartel Type Cyborg #2");
        } else if (
            randomNumber >= _dataCyborg[1] &&
            randomNumber < _dataCyborg[1] + _dataCyborg[2]
        ) {
            return Card(CYBORG3, "HexCartel Type Cyborg #3");
        } else if (
            randomNumber >= _dataCyborg[1] + _dataCyborg[2] &&
            randomNumber < _dataCyborg[1] + _dataCyborg[2] + _dataCyborg[3]
        ) {
            return Card(CYBORG4, "HexCartel Type Cyborg #4");
        } else if (
            randomNumber >= _dataCyborg[1] + _dataCyborg[2] + _dataCyborg[3] &&
            randomNumber <
            _dataCyborg[1] + _dataCyborg[2] + _dataCyborg[3] + _dataCyborg[4]
        ) {
            return Card(CYBORG5, "HexCartel Type Cyborg #5");
        } else if (
            randomNumber >=
            _dataCyborg[1] + _dataCyborg[2] + _dataCyborg[3] + _dataCyborg[4] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5]
        ) {
            return Card(CYBORG6, "HexCartel Type Cyborg #6");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6]
        ) {
            return Card(CYBORG7, "HexCartel Type Cyborg #7");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7]
        ) {
            return Card(CYBORG8, "HexCartel Type Cyborg #8");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8]
        ) {
            return Card(CYBORG9, "HexCartel Type Cyborg #9");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9]
        ) {
            return Card(CYBORG10, "HexCartel Type Cyborg #10");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9] +
                _dataCyborg[10]
        ) {
            return Card(CYBORG11, "HexCartel Type Cyborg #11");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9] +
                _dataCyborg[10] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9] +
                _dataCyborg[10] +
                _dataCyborg[11]
        ) {
            return Card(CYBORG12, "HexCartel Type Cyborg #12");
        } else if (
            randomNumber >=
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9] +
                _dataCyborg[10] +
                _dataCyborg[11] &&
            randomNumber <
            _dataCyborg[1] +
                _dataCyborg[2] +
                _dataCyborg[3] +
                _dataCyborg[4] +
                _dataCyborg[5] +
                _dataCyborg[6] +
                _dataCyborg[7] +
                _dataCyborg[8] +
                _dataCyborg[9] +
                _dataCyborg[10] +
                _dataCyborg[11] +
                _dataCyborg[12]
        ) {
            return Card(CYBORG13, "HexCartel Type Cyborg #13");
        } else {
            return Card(CYBORG1, "HexCartel Type Cyborg #1");
        }
    }
}