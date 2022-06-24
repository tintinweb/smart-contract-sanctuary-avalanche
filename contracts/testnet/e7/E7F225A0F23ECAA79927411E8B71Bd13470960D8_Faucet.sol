/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-23
*/

pragma solidity >= 0.7.0 <= 0.7.4;

contract Faucet{
    
    address owner;
    mapping (address => uint) timeouts;
    
    event Withdrawal(address indexed to);
    event Deposit(address indexed from, uint amount);
    
    constructor() {
        //Will be called on creation of the smart contract.
        owner = msg.sender;
    }
    
    //  Sends 0.1 ETH to the sender when the faucet has enough funds
    //  Only allows one withdrawal every 30 mintues
    function withdraw() external{
        
        require(address(this).balance >= 0.1 ether, "This faucet is empty. Please check back later.");
        require(timeouts[msg.sender] <= block.timestamp - 30 minutes, "You can only withdraw once every 30 minutes. Please check back later.");
        
        msg.sender.transfer(0.1 ether);
        timeouts[msg.sender] = block.timestamp;
        
        emit Withdrawal(msg.sender);
    }
    
    //  Sending Tokens to this faucet fills it up
    receive() external payable {
        emit Deposit(msg.sender, msg.value); 
    } 
    
    
    //  Destroys this smart contract and sends all remaining funds to the owner
    function destroy() public{
        require(msg.sender == owner, "Only the owner of this faucet can destroy it.");
        selfdestruct(msg.sender);
    }
}