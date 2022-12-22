//SPDX-License-Identifier:MIT
pragma solidity >=0.4.0 <0.9.0;
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
contract UniPayV1 is ReentrancyGuard{
    struct Payee {
        string Name; //Name of the Payee
        uint256 Amount; //Amount wants to send to Payee
        address Address; //address of the Payee
        uint256 Balance; //Balance of Payee to get total amount actually the Payer paid to payee
        uint256 Index;
    }
    
    struct Transaction {
       address Payer;
       uint256 Payees;
       uint256 Balance;
       uint256 Totalpay;
       uint256 nonce;
       mapping(address=>Payee) Payee_details;
    }

    mapping(address=>Transaction) public tx_details; // storing all the Payee details
    mapping(uint256=>address) public keys;
    bool private channel_open; 
   
    event AddedPayee(string Name,uint256 Amount,address Address);
    event DeletedPayee(string Name,uint256 Amount,address Address,uint256 Balance); 
    event ReceivedToContract(uint256 Amount,address sender);
    event TransferLog(address indexed from,address indexed to,uint256 value,uint256 nonce);
    event PayeesCount(uint256 count);

     //modifier declared that msg.sender must be the Payer
    modifier Open() {
        require(channel_open,"Channel not Opened");
        _;
    }
    
    receive() external payable Open{
        tx_details[msg.sender].Balance+=msg.value;
        emit ReceivedToContract(msg.value,msg.sender);
        channel_open=false;
    }

       //function for adding the Payees and it only accessible by Payer
    function AddPayee(string memory _name,uint256 _amount,address _addr) public {
            require(_addr!=address(0),"Zero address entered");
            require(tx_details[msg.sender].Payee_details[_addr].Index == 0,"Payee alrdy exist"); 
            _amount=_amount*1 ether; //converts the value from wei to ether
            tx_details[msg.sender].Payer=msg.sender;
            tx_details[msg.sender].Payees++;
            tx_details[msg.sender].Payee_details[_addr] = Payee(_name,_amount,_addr,0,tx_details[msg.sender].Payees);
            keys[tx_details[msg.sender].Payees]=_addr;
            tx_details[msg.sender].Totalpay+=_amount;
            emit AddedPayee(_name,_amount,_addr);
            emit PayeesCount(tx_details[msg.sender].Payees);
    }
      //function for removing the Payees and it only accessible by Payer
    function RemovePayee(address _payee) public  {
          require(_payee!=address(0),"Zero address entered");
           require(tx_details[msg.sender].Payee_details[_payee].Index > 0,"Payee not existed");
        delete tx_details[msg.sender].Payee_details[_payee];
        tx_details[msg.sender].Payees--;
        tx_details[msg.sender].Totalpay-=tx_details[msg.sender].Payee_details[_payee].Amount;
        emit DeletedPayee(tx_details[msg.sender].Payee_details[_payee].Name, tx_details[msg.sender].Payee_details[_payee].Amount,tx_details[msg.sender].Payee_details[_payee].Address, tx_details[msg.sender].Payee_details[_payee].Balance);
    }
      //function is to transfer the amount of ether to Payees
    function TransferPay() payable public Open nonReentrant{
        require(tx_details[msg.sender].Payees>0 && tx_details[msg.sender].Balance>0,"NO Funds available or No Payees listed");
        require(tx_details[msg.sender].Totalpay<=tx_details[msg.sender].Balance,"Insufficient Funds");
        uint256 count = tx_details[msg.sender].Payees;
        _TransferPay(count);
        channel_open = false;   
    }

    function _TransferPay(uint256 _count) private {
        for(uint256 i=_count;i>0;i--) {
           address _addr = keys[i];
           uint256 Pay = tx_details[msg.sender].Payee_details[_addr].Amount;
           tx_details[msg.sender].Totalpay-=Pay;
           (bool sent,) = payable(_addr).call{value:Pay}(""); //sends ether to Payees
           require(sent,"Failed to send ether");
           tx_details[msg.sender].Balance-=Pay;
           tx_details[msg.sender].nonce++;
           emit TransferLog(tx_details[msg.sender].Payer,_addr, Pay,tx_details[msg.sender].nonce);
           tx_details[msg.sender].Payee_details[_addr].Balance+=Pay;//Balance of Payee be Updated here
        }
    }
   //this function is to withdraw the balance amount from the contract and it can only accessible by Payer
   function WithdrawPayer() payable public Open nonReentrant {
       require(tx_details[msg.sender].Balance>0,"Insufficient Funds");
       uint256 _amount = tx_details[msg.sender].Balance;
       (bool sent,) = payable(tx_details[msg.sender].Payer).call{value:_amount}("");
       require(sent,"Failed to send ether");
       tx_details[msg.sender].Balance-=_amount;
   }
   
   function Info() public view returns(uint256,uint256,uint256){
    return (tx_details[msg.sender].Balance,tx_details[msg.sender].Payees,tx_details[msg.sender].Totalpay);
   }

   function openChannel() public {
    require(!channel_open,"Channel Opened Alrdy");
       channel_open=true;
   }  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}