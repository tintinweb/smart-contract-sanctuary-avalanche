/**
 *Submitted for verification at testnet.snowtrace.io on 2022-02-07
*/

// File: contracts/coinflip.sol


pragma solidity ^0.4.24;

contract coinflip {

    /** Wallets **/
    address constant public wallet_marketing = 0x4d47CB0727e4E1B0982aaa24865283b34ca68368;
    
    /** Transactions **/
    // fees
    // marketing %
    uint256 bet_min = 99999999999999999;
    uint256 bet_max = 5000000000000000000;

    /** Statistics **/
    uint64 public stats_flip;
    // flip
    // win
    // lose

    function incrementStatsFlip() public {
        stats_flip++;
    }

    function balanceOf() public view returns(uint) {
        return address(this).balance;
    }

    function getBackMoney() external {
        uint256 bal = balanceOf();
        msg.sender.transfer(bal);
    }

    function flip() external payable {
        require(msg.value >= bet_min, "Bet is too low");
        require(msg.value <= bet_max, "Bet is too high");
        
        msg.sender.transfer(msg.value / 2);
    }
}