//SPDX-License-Identifier:MIT
pragma solidity >=0.4.0 <0.9.0;
contract UniPayV1 {
    address payable public Payer;  
    
    struct Payee {
        string Name; //Name of the Payee
        uint256 Amount; //Amount wants to send to Payee
        address Address; //address of the Payee
        uint256 Balance; //Balance of Payee to get total amount actually the Payer paid to payee
        uint256 Index;
    }
    mapping(address=>Payee) private Payee_details; // storing all the Payee details
    address[] private Payee_list; // storing all the address of Payees
    mapping(address=>mapping(address=>bool)) private PayeeValidator;
    uint256 private Payees; // represents Number of Payees are there
    uint256 private total_pay; //stores information about How much amount is actually pay to Payees
    bool private Entered=false; 
   
    event AddedPayee(string Name,uint256 Amount,address Address);
    event DeletedPayee(string Name,uint256 Amount,address Address,uint256 Balance);
    event ReceivedToContractLog(address from,uint256 amount); 
    event NewPayerLog(address owner);
    event TransferLog(address indexed from,address indexed to,uint256 value);
    event PayeesCount(uint256 count);

    constructor(address _payer) {
        Payer=payable(_payer);
    }
     //modifier declared that msg.sender must be the Payer
    modifier OnlyPayer() {
        require(Payer==msg.sender);
        _;
    }
    //modifier declared that prevents the reentrancy attacks
    modifier AvoidReentrancy(){
        require(!Entered,"Reentrancy Detected");
        Entered = true;
        _;
    }
      //recieve function is to get the ether from Payer 
     receive() payable external { 
         emit ReceivedToContractLog(msg.sender,msg.value);
         //emits the information about Payer and How much he sends to contract
     }
      //whenever this function calls by Payer it shows the current balance of the smartcontract
    function Balance() public OnlyPayer view returns(uint256){
        return address(this).balance; //returns the balance of contract
    }
       //function for adding the Payees and it only accessible by Payer
    function AddPayee(string memory _name,uint256 _amount,address _addr) public OnlyPayer{
            require(_addr!=address(0),"Zero address entered");
           require(PayeeValidator[msg.sender][_addr]==false,"Already Payee Added");
            _amount=_amount*1 ether; //converts the value from wei to ether
            Payee_list.push(_addr); 
            Payees=Payee_list.length; 
            Payee_details[_addr] = Payee(_name,_amount,_addr,0,Payees);
            PayeeValidator[msg.sender][_addr]=true;
            total_pay+=_amount;
            emit AddedPayee(_name,_amount,_addr);
            emit PayeesCount(Payees);
    }
      //function for removing the Payees and it only accessible by Payer
    function RemovePayee(address _payee) public OnlyPayer {
        require(PayeeValidator[msg.sender][_payee]==true,"Payee Doesnt exist");
        uint256 id = Payee_details[_payee].Index;
        address temp = Payee_list[Payees-1];
        Payee_list[Payees-1] = Payee_list[id-1];
        Payee_list[id-1] = temp;
        total_pay-=Payee_details[_payee].Amount;
        delete Payee_details[_payee];
        emit DeletedPayee(Payee_details[_payee].Name, Payee_details[_payee].Amount, Payee_details[_payee].Address, Payee_details[_payee].Balance);
    }
      //function is to transfer the amount of ether to Payees
    function TransferPay() payable public OnlyPayer AvoidReentrancy{
        require(Payees>0 && address(this).balance>0,"NO Funds available or No Payees listed");
        require(total_pay<=address(this).balance,"Insufficient Funds");
        for(uint256 i=0;i<Payees;i++) {
           uint256 Pay = Payee_details[Payee_list[i]].Amount;
           total_pay-=Pay;
           (bool sent,) = payable(Payee_list[i]).call{value:Pay}(""); //sends ether to Payees
           require(sent,"Failed to send ether");
           emit TransferLog(Payer, Payee_list[i], Pay);
           Payee_details[Payee_list[i]].Balance+=Pay;//Balance of Payee be Updated here
        }   
    }
   //this function is to withdraw the balance amount from the contract and it can only accessible by Payer
   function WithdrawPayer(uint256 _amount) payable public OnlyPayer {
       _amount*=1 ether;
       require(address(this).balance>0 && _amount<=address(this).balance,"Insufficient Funds");
       (bool sent,) = Payer.call{value:_amount}("");
       require(sent,"Failed to send ether");
   }
        // this function is to change the payer 
    function RenouncePayer(address _newPayer) public OnlyPayer {
        require(_newPayer!=address(0));
        Payer = payable(_newPayer);
        emit NewPayerLog(Payer);
    }
     
}