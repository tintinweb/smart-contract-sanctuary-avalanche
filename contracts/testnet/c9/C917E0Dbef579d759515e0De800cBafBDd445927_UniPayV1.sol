//SPDX-License-Identifier:MIT
pragma solidity >=0.4.0 <0.9.0;
contract UniPayV1 {
    address payable public Payer;  
    struct Payee {
        string Name; //Name of the Payee
        uint Amount; //Amount wants to send to Payee
        address Address; //address of the Payee
        uint Balance; //Balance of Payee to get total amount actually the Payer paid to payee
        uint Index;
    }
    mapping(address=>Payee) public Payee_details; // storing all the Payee details
    address[] private Payee_list; // storing all the address of Payees
    mapping(address=>mapping(address=>bool)) private PayeeValidator;
    uint public Payees; // represents Number of Payees are there
    uint internal total_pay; //stores information about How much amount is actually pay to Payees
    bool internal Entered=false; 
    event ReceivedToContractLog(address from,uint amount); 
    event NewPayerLog(address owner);
    event TransferLog(address indexed from,address indexed to,uint value);

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
    function AddPayee(string memory _name,uint _amount,address _addr) public OnlyPayer{
            require(_addr!=address(0),"Zero address entered");
           require(PayeeValidator[msg.sender][_addr]==false,"Already Payee Added");
            _amount=_amount*1 ether; //converts the value from wei to ether
            Payee_list.push(_addr); 
            Payees=Payee_list.length; 
            Payee_details[_addr] = Payee(_name,_amount,_addr,0,Payees);
            PayeeValidator[msg.sender][_addr]=true;
            total_pay+=_amount;
    }
      //function for removing the Payees and it only accessible by Payer
    function RemovePayee(address _payee) public OnlyPayer {
        require(PayeeValidator[msg.sender][_payee]==true,"Payee Doesnt exist");
        uint256 id = Payee_details[msg.sender].Index;
        address temp = Payee_list[Payees-1];
        Payee_list[Payees-1] = Payee_list[id-1];
        Payee_list[id-1] = temp;
        total_pay-=Payee_details[_payee].Amount;
        delete Payee_details[_payee];
    }
      //function is to transfer the amount of ether to Payees
    function TransferPay() payable public OnlyPayer AvoidReentrancy{
        require(Payees>0 && address(this).balance>0,"NO Funds available or No Payees listed");
        require(total_pay<=address(this).balance,"Insufficient Funds");
        for(uint i=0;i<Payees;i++) {
           uint Pay = Payee_details[Payee_list[i]].Amount;
           total_pay-=Pay;
           (bool sent,) = payable(Payee_list[i]).call{value:Pay}(""); //sends ether to Payees
           require(sent,"Failed to send ether");
           emit TransferLog(Payer, Payee_list[i], Pay);
           Payee_details[Payee_list[i]].Balance+=Pay;//Balance of Payee be Updated here
        }   
    }
   //this function is to withdraw the balance amount from the contract and it can only accessible by Payer
   function WithdrawPayer(uint _amount) payable public OnlyPayer {
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