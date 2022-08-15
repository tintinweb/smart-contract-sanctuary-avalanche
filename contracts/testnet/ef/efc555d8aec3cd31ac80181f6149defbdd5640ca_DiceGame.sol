/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-15
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract DiceGame {
    address payable public fee1; 
    address payable public fee2; 
    address payable public dev; 
    uint128 public feeAmount;

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
    function withdraw() external isOwner() {         
        (bool sent,) = dev.call{value: address(this).balance}("");
        require(sent, "Error withdrawing funds");      
    }

    /**
     * Set Wallet Payouts
     */
    function setPayout(bool _win, uint256 _betAmount) private {
        userPayouts.push(UserPayouts(msg.sender, _win, _betAmount));
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
    function roll(uint _minNumber) external payable returns (uint) {
        require(msg.value >= 1000000000000000, "Bet amount to low");
        require(msg.value <= 101000000000000000000, "Bet amount to high");
        require(_minNumber >= 2, "Roll Above Number Too Low");
        require(_minNumber <= 12, "Roll Above Number Too High");

        uint _random = random();
        bool _result = _minNumber > _random;

        uint256 _fees = msg.value / feeAmount; // Figure out fees based on bet.  
        uint256 _betAmount = msg.value - _fees;  

        uint256 _fee1 = _fees - (_fees / 300);
        uint256 _fee2 = _fees - (_fees / 300);
        uint256 _dev = _fees - (_fees / 400);
        
        // Send Fees
        (bool _sentFee1,) = fee1.call{value: _fee1}("");
        (bool _sentFee2,) = fee2.call{value: _fee2}("");
        (bool _sentDev,) = dev.call{value: _dev}("");
        require(_sentFee1, "Error sending Fee 1");
        require(_sentFee2, "Error sending Fee 2");
        require(_sentDev, "Error sending Developer Fee");

        // User won
        if(_result == true) {
            uint256 _userWins = (_betAmount * multiplier(_minNumber)) / 100;
            
            (bool sent,) = msg.sender.call{value: _betAmount}("");
            require(sent, "Error sending User Wins");
            
            setPayout(true, _userWins); 
            return _random;
        } else {
            setPayout(false, _betAmount); 

            return _random;
        }
    }

    /**
    * Generates pseudo random number in the range of 2-12 (inclussive)
    */
	function random() public view returns (uint) {
		uint256 value = uint256(block.timestamp + tx.gasprice + block.number + block.gaslimit);
		return uint(value % 11) + 2;
	}

    /**
     * Calculate multiplier
     */
    function multiplier(uint _minNumber) public payable returns (uint256) {
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