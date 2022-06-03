// SPDX-License-Identifier: MIT

pragma solidity >0.4.9 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

/*
  Disclaimer: Adopted from Opensea opensea-creatures repository
*/

// This is simply the IERC1155Factory interface
abstract contract Factory {
    function mint(
        uint256 _optionId,
        address _toAddress,
        uint256 _amount,
        bytes calldata _data
    ) external virtual;
}

/**
 * @title LootBoxRandomness
 * LootBoxRandomness- support for a randomized and openable lootbox.
 */
library LootBoxRandomness {
    using SafeMath for uint256;

    // Event for logging lootbox opens
    event LootBoxOpened(
        uint256 indexed optionId,
        address indexed buyer,
        uint256 boxesPurchased,
        uint256 itemsMinted
    );
    event Warning(string message, address account);

    uint256 constant INVERSE_BASIS_POINT = 10000;

    struct LootBoxRandomnessState {
        uint256 numOptions;
        mapping(uint256 => uint16[]) classProbabilities;
        mapping(uint256 => address) classToFactory;
        uint256 seed;
    }

    //////
    // INITIALIZATION FUNCTIONS FOR OWNER
    //////

    /**
     * @dev Set up the fields of the state that should have initial values.
     */
    function initState(
        LootBoxRandomnessState storage _state,
        uint256 _numOptions,
        uint256 _seed
    ) public {
        _state.numOptions = _numOptions;
        _state.seed = _seed;
    }

    /**
     * @dev set Factory for the box
     */
    function setFactoryForOption(
        LootBoxRandomnessState storage _state,
        uint256 _optionId,
        address factory
    ) public {
        require(
            _optionId < _state.numOptions,
            "LootBoxRandomness: _option out of range"
        );
        _state.classToFactory[_optionId] = factory;
    }

    /**
     * @dev add new box option
     */
    function addNewOption(
        LootBoxRandomnessState storage _state,
        address _factoryAddress,
        uint16[] memory _probabilities
    ) public {
        _state.classToFactory[_state.numOptions] = _factoryAddress;
        _state.classProbabilities[_state.numOptions] = _probabilities;
        _state.numOptions++;
    }

    /**
     * Set probilities per class
     */
    function setProbabilitiesForOption(
        LootBoxRandomnessState storage _state,
        uint256 _optionId,
        uint16[] memory probabilities
    ) public {
        require(
            _optionId < _state.numOptions,
            "LootBoxRandomness: _option out of range"
        );
        _state.classProbabilities[_optionId] = probabilities;
    }

    /**
     * @dev Improve pseudorandom number generator by letting the owner set the seed manually,
     * making attacks more difficult
     * @param _newSeed The new seed to use for the next transaction
     */
    function setSeed(LootBoxRandomnessState storage _state, uint256 _newSeed)
        public
    {
        _state.seed = _newSeed;
    }

    /**
     * @notice Query current number of options
     */
    function numOptions(LootBoxRandomnessState storage _state)
        public
        view
        returns (uint256)
    {
        return _state.numOptions;
    }

    /**
     * @notice Query class probabilities for the given option
     */
    function classProbabilities(
        LootBoxRandomnessState storage _state,
        uint256 opitonId
    ) public view returns (uint16[] memory) {
        return _state.classProbabilities[opitonId];
    }

    /**
     * @notice Query factory address for the given option
     */
    function classFactoryAddress(
        LootBoxRandomnessState storage _state,
        uint256 optionId
    ) public view returns (address) {
        return _state.classToFactory[optionId];
    }

    ///////
    // MAIN FUNCTIONS
    //////

    /**
     * @dev Main minting logic for lootboxes
     */
    function _mint(
        LootBoxRandomnessState storage _state,
        uint256 _optionId,
        address _toAddress,
        uint256 _amount,
        bytes memory, /* _data */
        address _owner
    ) internal {
        require(_optionId < _state.numOptions, "_option out of range");
        uint256 quantityOfRandomized = 1;
        for (uint256 i = 0; i < _amount; i++) {
            // step 1. pick a class
            uint256 classId = _pickRandomClass(
                _state,
                _state.classProbabilities[_optionId]
            );
            // step 2. invoke mint from the corresponding factory to the class
            _sendTokenWithClass(
                _state,
                _optionId,
                classId,
                _toAddress,
                quantityOfRandomized,
                _owner
            );
        }

        // Event emissions
        emit LootBoxOpened(_optionId, _toAddress, _amount, 1);
    }

    /////
    // HELPER FUNCTIONS
    /////

    // Returns the tokenId sent to _toAddress
    function _sendTokenWithClass(
        LootBoxRandomnessState storage _state,
        uint256 _tokenId,
        uint256 _classId,
        address _toAddress,
        uint256 _amount,
        address
    ) internal returns (uint256) {
        Factory factory = Factory(_state.classToFactory[_tokenId]);
        factory.mint(_classId, _toAddress, _amount, "");
        return _tokenId;
    }

    // The core of the random picking algorithm, google "weighted random"
    function _pickRandomClass(
        LootBoxRandomnessState storage _state,
        uint16[] memory _classProbabilities
    ) internal returns (uint256) {
        uint16 value = uint16(_random(_state).mod(INVERSE_BASIS_POINT));
        // Start at top class (length - 1)
        // skip common (0), we default to it
        for (uint256 i = _classProbabilities.length - 1; i > 0; i--) {
            uint16 probability = _classProbabilities[i];
            if (value < probability) {
                return i;
            } else {
                value = value - probability;
            }
        }
        // Note: assumes zero is common!
        return 0;
    }

    /**
     * @dev Pseudo-random number generator
     * NOTE: to improve randomness, generate it with an oracle
     */
    function _random(LootBoxRandomnessState storage _state)
        internal
        returns (uint256)
    {
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    blockhash(block.number - 1),
                    msg.sender,
                    _state.seed
                )
            )
        );
        _state.seed = randomNumber;
        return randomNumber;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}