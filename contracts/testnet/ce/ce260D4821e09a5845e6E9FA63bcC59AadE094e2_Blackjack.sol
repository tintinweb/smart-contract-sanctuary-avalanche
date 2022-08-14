/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Blackjack {

	// 0-51 Cards, Non Shuffled
	string[52] cardNames = [unicode"Ace♣", unicode"Two♣", unicode"Three♣", unicode"Four♣", unicode"Five♣", unicode"Six♣", unicode"Seven♣", unicode"Eight♣", unicode"Nine♣", unicode"Ten♣", unicode"Jack♣", unicode"Queen♣", unicode"King♣", unicode"Ace♦", unicode"Two♦", unicode"Three♦", unicode"Four♦", unicode"Five♦", unicode"Six♦", unicode"Seven♦", unicode"Eight♦", unicode"Nine♦", unicode"Ten♦", unicode"Jack♦", unicode"Queen♦", unicode"King♦", unicode"Ace♥", unicode"Two♥", unicode"Three♥", unicode"Four♥", unicode"Five♥", unicode"Six♥", unicode"Seven♥", unicode"Eight♥", unicode"Nine♥", unicode"Ten♥", unicode"Jack♥", unicode"Queen♥", unicode"King♥", unicode"Ace♠", unicode"Two♠", unicode"Three♠", unicode"Four♠", unicode"Five♠", unicode"Six♠", unicode"Seven♠", unicode"Eight♠", unicode"Nine♠", unicode"Ten♠", unicode"Jack♠", unicode"Queen♠", unicode"King♠"];
    uint8[52] shuffledDeck;
	string[] shuffledDeckEnglish;


	// Figure out Proper RNG Logic
	function getSeed() internal view returns (uint) {
		return uint(keccak256(abi.encodePacked(block.timestamp)));
	}

	function returnShuffledDeckEnglish() public view returns (string[] memory) {
  		return shuffledDeckEnglish;
	}

	function returnShuffledDeck() public view returns (uint8[52] memory) {
		return shuffledDeck;
	}

	function buildShuffledDeck() public {
		delete shuffledDeck;
		delete shuffledDeckEnglish;
		uint8[52] memory notShuffled;
		for(uint8 i=0; i < 52; i++) {
			notShuffled[i] = i;
		}
		uint cardIndex;
		for(uint i=0; i < 52; i++) {
			cardIndex = getSeed() % (52 - i);
			shuffledDeck[i] = notShuffled[cardIndex];
			shuffledDeckEnglish.push(cardNames[notShuffled[cardIndex]]);
			notShuffled[cardIndex] = notShuffled[52 - i - 1];
		}
	}
}