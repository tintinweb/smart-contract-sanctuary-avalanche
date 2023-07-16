/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-15
*/

pragma solidity >=0.8.2 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
// SPDX-License-Identifier: MIT
pragma solidity >=0.4.15 <0.9.0;

contract VideoPokerLogic {
  uint private constant COUNT2 = 2 ** 16 - 1;
  uint private constant COUNT3 = 2 ** 32 - 1;
  uint private constant COUNT4 = 2 ** 48 - 1;

  uint private constant MASK_STRAIGHT_A = 4111; // 0b1000000001111
  uint private constant MASK_STRAIGHT_2 = 31; // 0b0000000011111
  uint private constant MASK_STRAIGHT_3 = 62; // 0b0000000111110
  uint private constant MASK_STRAIGHT_4 = 124; // 0b0000001111100
  uint private constant MASK_STRAIGHT_5 = 248; // 0b0000011111000
  uint private constant MASK_STRAIGHT_6 = 496; // 0b0000111110000
  uint private constant MASK_STRAIGHT_7 = 992; // 0b0001111100000
  uint private constant MASK_STRAIGHT_8 = 1984; // 0b0011111000000
  uint private constant MASK_STRAIGHT_9 = 3968; // 0b0111110000000
  uint private constant MASK_STRAIGHT_HIGH = 7936; // 0b1111100000000
  uint private constant MASK_JACKS_OR_BETTER = 503316480; // 0b1111000000000_0000000000000000

  uint private constant MASK_CARD_0 = ~uint(63);
  uint private constant MASK_CARD_1 = ~uint(63 << 6);
  uint private constant MASK_CARD_2 = ~uint(63 << 12);
  uint private constant MASK_CARD_3 = ~uint(63 << 18);
  uint private constant MASK_CARD_4 = ~uint(63 << 24);

  uint private constant JACKS_OR_BETTER = 1;
  uint private constant TWO_PAIR = 2;
  uint private constant THREE_OF_A_KIND = 3;
  uint private constant STRAIGHT = 4;
  uint private constant FLUSH = 5;
  uint private constant FULL_HOUSE = 6;
  uint private constant FOUR_OF_A_KIND = 7;
  uint private constant STRAIGHT_FLUSH = 8;
  uint private constant ROYAL_FLUSH = 9;

  struct DeckBuilder {
    uint256 random;
    uint deck;
  }

  function nextCard(DeckBuilder memory builder) internal pure returns (uint) {
    do {
      uint card = builder.random & 63;

      // Create a mask with a single bit set at the card index
      uint mask = 1 << card;

      // Shift the random number right by 6 bits to discard the used card
      builder.random >>= 6;

      // Check whether the card has already been dealt
      if ((builder.deck & mask) == 0) {
        // Mark the card as dealt in the deck
        builder.deck |= mask;

        // Return the card index
        return card;
      }
    } while (builder.random > 0);

    // very low chance of happening
    revert("Invalid random number");
  }

  function reverseCards(uint256 cards) public pure returns (uint8[5] memory) {
    uint8[5] memory cardValues;

    for (uint i = 0; i < 5; i++) {
      uint8 card = uint8(cards & 63);
      cardValues[i] = card;
      cards >>= 6;
    }

    return cardValues;
  }

  function reverseCardsB(uint256 cards) public pure returns (uint8[5] memory) {
    uint8[5] memory cardValues;

    for (uint i = 0; i < 5; i++) {
      uint8 card = uint8((cards >> (6 * i)) & 63);
      cardValues[i] = card;
    }

    return cardValues;
  }

  function dealt(uint256 _randomness) public pure returns (uint, uint256, uint[5] memory) {
    // Create a new DeckBuilder struct with the provided random number and a fixed initial deck state
    DeckBuilder memory builder_ = DeckBuilder(_randomness, 16141147358858633216);

    // Create an array to store the card values
    uint[5] memory cardValues;

    for (uint i = 0; i < 5; i++) {
      // Get the next card index using the nextCard function
      uint cardIndex = nextCard(builder_);

      // Convert the card index to its corresponding value
      cardValues[i] = cardIndex;

    }

    // Generate five cards by calling the nextCard function and combining the results
    uint cards_ = cardValues[0] |
      (cardValues[1] << 6) |
      (cardValues[2] << 12) |
      (cardValues[3] << 18) |
      (cardValues[4] << 24);

    return (win(cards_), cards_, cardValues);

  }

  function replace(uint256 cards_, uint change_, uint256 _oldRandomness, uint256 _newRandomness) public pure returns (uint256, uint256, uint[5] memory) {
    // Rebuild the deck from the current cards
    (,, uint[5] memory oldCards_) = dealt(_oldRandomness);
    
    uint[5] memory cardValues = oldCards_;
    // Calculate the deck with the selected cards marked as dealt
    uint deck_ = 16141147358858633216 | // Initialize deck with the initial state
      (1 << (cards_ & 63)) | // Mark the first card as dealt
      (1 << ((cards_ & 4032) >> 6)) | // Mark the second card as dealt
      (1 << ((cards_ & 258048) >> 12)) | // Mark the third card as dealt
      (1 << ((cards_ & 16515072) >> 18)) | // Mark the fourth card as dealt
      (1 << ((cards_ & 1056964608) >> 24)); // Mark the fifth card as dealt

    // Update the required cards

    DeckBuilder memory builder_ = DeckBuilder(_newRandomness, deck_);

    // Check each bit in the change_ variable and replace the corresponding card if set
    if ((change_ & 1) != 0) {
      cardValues[0] = nextCard(builder_);
      cards_ = (cards_ & MASK_CARD_0) | cardValues[0];
    }
    if ((change_ & 2) != 0) {
      cardValues[1] = nextCard(builder_);
      cards_ = (cards_ & MASK_CARD_1) | (cardValues[1] << 6);
    }
    if ((change_ & 4) != 0) {
      cardValues[2] = nextCard(builder_);
      cards_ = (cards_ & MASK_CARD_2) | (cardValues[2] << 12);
    }
    if ((change_ & 8) != 0) {
      cardValues[3] = nextCard(builder_);
      cards_ = (cards_ & MASK_CARD_3) | (cardValues[3] << 18);
    }
    if ((change_ & 16) != 0) {
      cardValues[4] = nextCard(builder_);
      cards_ = (cards_ & MASK_CARD_4) | (cardValues[4] << 24);
    }

    // Update the game state with the new set of cards
    return (win(cards_), cards_, cardValues);
  }

  function getCardDetails(uint[] memory _card) public pure returns (uint[5] memory, uint[5] memory) {
  uint[5] memory values;
  uint[5] memory colors;
  for (uint i = 0; i < 5; i++) {
    uint value;
    uint color;
    if(_card[i] < 13){
      color = 1;
    }
    else if(_card[i] < 29){
      color = 2;
    }
    else if(_card[i] < 45){
      color = 3;

    }
    else{
      color = 4;
    }
    colors[i] = color;

    uint cardValue = _card[i];
    if (cardValue % 16 < 12) {
        value = (cardValue % 16) + 2;
    } else if (cardValue % 16 == 12) {
        value = 1; // Ace
    }

    values[i] = value;

  }
  return (values, colors);
}

  function win(uint cards) public pure returns (uint) {
    // count cards
    // count is initialized using the first card without doing the `while` check
    uint count = 1 << (cards & 15);
    // other cards need to perform the offset check
    count |= offset(count, 1 << ((cards & 960) >> 6));
    count |= offset(count, 1 << ((cards & 61440) >> 12));
    count |= offset(count, 1 << ((cards & 3932160) >> 18));
    count |= offset(count, 1 << ((cards & 251658240) >> 24));
    if (count <= COUNT2) {
      // all cards have different values, no need to count unique values
      if (
        count == MASK_STRAIGHT_A ||
        count == MASK_STRAIGHT_2 ||
        count == MASK_STRAIGHT_3 ||
        count == MASK_STRAIGHT_4 ||
        count == MASK_STRAIGHT_5 ||
        count == MASK_STRAIGHT_6 ||
        count == MASK_STRAIGHT_7 ||
        count == MASK_STRAIGHT_8 ||
        count == MASK_STRAIGHT_9
      ) {
        if (isFlush(cards)) {
          return STRAIGHT_FLUSH;
        } else {
          return STRAIGHT;
        }
      } else if (count == MASK_STRAIGHT_HIGH) {
        // treat royal as a special case
        if (isFlush(cards)) {
          return ROYAL_FLUSH;
        } else {
          return STRAIGHT;
        }
      } else if (isFlush(cards)) {
        // can only be a flush if a.length is 5
        return FLUSH;
      }
    } else {
      // count how many different combinations of numbers there are
      // counting the number of 1s in the first 13 bits
      uint uniqueNumbers = countUniqueNumbers(count); // must be between 2 and 4
      if (uniqueNumbers == 2) {
        // there are only two unique numbers
        // must be whether a four of a kind or a full house
        if (count > COUNT4) {
          return FOUR_OF_A_KIND;
        } else {
          return FULL_HOUSE;
        }
      } else if (count > COUNT3) {
        // three of a kind
        return THREE_OF_A_KIND;
      } else if (uniqueNumbers == 3) {
        // two pair
        return TWO_PAIR;
      } else if ((count & MASK_JACKS_OR_BETTER) != 0) {
        // jacks or better
        return JACKS_OR_BETTER;
      }
    }
    return 0;
  }

  function offset(uint count, uint ioffset) public pure returns (uint) {
    while ((count & ioffset) != 0) {
      ioffset <<= 16;
    }
    return ioffset;
  }

  function countUniqueNumbers(uint count) public pure returns (uint) {
    uint ret = 0;
    if ((count & 1) != 0) ret++;
    if ((count & 2) != 0) ret++;
    if ((count & 4) != 0) ret++;
    if ((count & 8) != 0) ret++;
    if ((count & 16) != 0) ret++;
    if ((count & 32) != 0) ret++;
    if ((count & 64) != 0) ret++;
    if ((count & 128) != 0) ret++;
    if ((count & 256) != 0) ret++;
    if ((count & 512) != 0) ret++;
    if ((count & 1024) != 0) ret++;
    if ((count & 2048) != 0) ret++;
    if ((count & 4096) != 0) ret++;
    return ret;
  }

  /**
   * Indicates whether all the cards have the same suit.
   */
  function isFlush(uint cards) public pure returns (bool) {
    uint t = cards & 48; // 0b110000 (12 in decimal)
    return
      (cards & 3072) >> 6 == t && // 0b110000 shifted 6 bits to the right
      (cards & 196608) >> 12 == t && // 0b110000 shifted 12 bits to the right
      (cards & 12582912) >> 18 == t && // 0b110000 shifted 18 bits to the right
      (cards & 805306368) >> 24 == t; // 0b0110000 shifted 24 bits to the right
  }
}