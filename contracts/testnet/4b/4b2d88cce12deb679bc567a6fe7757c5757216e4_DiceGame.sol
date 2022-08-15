/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-14
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract DiceGame {
    address payable public fee1; 
    address payable public fee2; 
    address payable public dev; 
    uint128 public feeAmount;
    uint256 public constant MAX_INT = type(uint128).max;

    struct UserPayouts { 
      address userAddress;
      bool win;
      uint256 payout;
    }
    UserPayouts[] public userPayouts;

    constructor() payable {
        fee1 = payable(msg.sender); 
        fee2 = payable(msg.sender); 
        dev = payable(msg.sender); 
        feeAmount = 350;
    }

    /**
     * Modifiers
     */
    modifier isOwner() {
        require(
            msg.sender == dev,
            "Only the contract owner can use this function."
        );
        _;
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    /**
     * Withdraw contract balance 
     */
    function withdraw() external isOwner() { // Keep in private?  
        dev.transfer(address(this).balance);      
    }

    /**
     * Set Wallet Payouts
     */
    function setPayout(bool _win, uint256 _betAmount) private {
        userPayouts.push(UserPayouts(msg.sender, _win, _betAmount));
    }
    
    /**
     * Get Wallet Payouts
     */
    function getPayouts(uint _index) external view returns(UserPayouts memory) {
        return userPayouts[_index];
    }

    /**
	 * Update the fee wallets. 
	 */
    function setFeeWallets(address _fee1, address _fee2, address _dev) external isOwner() {
        fee1 = payable(_fee1);
        fee2 = payable(_fee2);
        dev = payable(_dev);
    }

    /**
     * Update the fee. 
     *
     * Contract owner only
     */
    function setFee(uint128 _fee) external isOwner() {
        feeAmount = _fee; 
    }

    /**
     * Roll Dice
     */
    function roll(uint _minNumber) external payable returns (bool) {
        require(_minNumber >= 2, "Roll Above Number Too Low"); // If they chose lower than 3 user always wins. 
        require(_minNumber <= 12, "Roll Above Number Too High"); // 2 dice can only go up to 12. 

        bool _result = _minNumber > random();

        uint256 _fees = msg.value / feeAmount; // Figure out fees based on bet.  
        uint256 _betAmount = msg.value - _fees; // Take out fees from total, is this ok? 

        uint256 _fee1 = _fees - (_fees / 300);
        uint256 _fee2 = _fees - (_fees / 300);
        uint256 _dev = _fees - (_fees / 400);
        
        // Send Fees
        fee1.transfer(_fee1);
        fee2.transfer(_fee2);
        dev.transfer(_dev);
       
        // User won
        if(_result == true) {
            // Transfer to the player
            uint256 _userWins = _betAmount * multiplier(_minNumber);
            payable(msg.sender).transfer(_userWins);
            
            setPayout(true, _userWins); 

            return true;
        } else {
            setPayout(false, _betAmount); 

            return false;
        }
    }

    /**
    * Generates pseudo random number in the range of 1-12 (inclussive)
    */
	function random() private view returns (uint8) {
		uint256 blockValue = uint256(blockhash(block.number-1 + block.timestamp));
		return uint8(blockValue % 11) + 1;
	}

    /**
     * Calculate multiplier
     */
    function multiplier(uint _minNumber) private pure returns (uint256) {
        uint256 _multiplier = 0;
        if(_minNumber == 3) _multiplier = 103;
        if(_minNumber == 4) _multiplier = 110;
        if(_minNumber == 5) _multiplier = 130;
        if(_minNumber == 6) _multiplier = 160;
        if(_minNumber == 7) _multiplier = 225;
        if(_minNumber == 8) _multiplier = 340;
        if(_minNumber == 9) _multiplier = 560;
        if(_minNumber == 10) _multiplier = 1130;
        if(_minNumber == 11) _multiplier = 3400;
        return _multiplier;
    }
}