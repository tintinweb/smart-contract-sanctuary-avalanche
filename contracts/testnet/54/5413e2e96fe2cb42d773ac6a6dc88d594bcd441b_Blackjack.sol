/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract Blackjack {

	// 0-51 Cards, Non Shuffled
	string[52] cardNames = ["Ace_Clubs" , "Two_Clubs" , "Three_Clubs" , "Four_Clubs" , "Five_Clubs" , "Six_Clubs" , "Seven_Clubs" , "Eight_Clubs" , "Nine_Clubs" , "Ten_Clubs" , "Jack_Clubs" , "Queen_Clubs" , "King_Clubs" , "Ace_Diamonds" , "Two_Diamonds" , "Three_Diamonds" , "Four_Diamonds" , "Five_Diamonds" , "Six_Diamonds" , "Seven_Diamonds" , "Eight_Diamonds" , "Nine_Diamonds" , "Ten_Diamonds" , "Jack_Diamonds" , "Queen_Diamonds" , "King_Diamonds" , "Ace_Hearts" , "Two_Hearts" , "Three_Hearts" , "Four_Hearts" , "Five_Hearts" , "Six_Hearts" , "Seven_Hearts" , "Eight_Hearts" , "Nine_Hearts" , "Ten_Hearts" , "Jack_Hearts" , "Queen_Hearts" , "King_Hearts" , "Ace_Spades" , "Two_Spades" , "Three_Spades" , "Four_Spades" , "Five_Spades" , "Six_Spades" , "Seven_Spades" , "Eight_Spades" , "Nine_Spades" , "Ten_Spades" , "Jack_Spades" , "Queen_Spades" , "King_Spades"];
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