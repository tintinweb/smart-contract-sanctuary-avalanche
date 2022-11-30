//SPDX-License-Identifier:MIT
pragma solidity >=0.4.0 <0.9.0;
contract UniPay{

    struct Payee {
        string Name; //Name of the Payee
        uint256 Amount; //Amount wants to send to Payee
        address Payee; //address of the Payee
        uint256 Balance; //Balance of Payee to get total amount actually the Payer paid to payee
        uint256 Index;
    }
    
    struct Payer {
       address Payer;
       uint256 Payees;
       uint256 Balance;
       uint256 Totalpay;
       address[] Payee_list;
    }
    mapping(address=>mapping(address=>Payee)) public Payee_details; // storing all the Payee details
    mapping(address=>mapping(string=>mapping(address=>bool))) private PayeeValidator;
    mapping(address=>Payer) public Payer_details; 
    bool private Entered;

    event ReceivedToContractLog(address from,uint amount); 
    event NewPayerLog(address owner);
    event TransferLog(address indexed from,address indexed to,uint value);


    //modifier declared that prevents the reentrancy attacks
    modifier AvoidReentrancy(){
        require(!Entered,"Reentrancy Detected");
        Entered = true;
        _;
    }
      //recieve function is to get the ether from Payer 
     receive() payable external {
         Payer_details[msg.sender].Balance+=msg.value; 
         emit ReceivedToContractLog(msg.sender,msg.value);
         //emits the information about Payer and How much he sends to contract
     }
      //whenever this function calls by Payer it shows the current balance of the smartcontract
    function Balance() public view returns(uint256){
        return Payer_details[msg.sender].Balance; //returns the balance of contract
    }
       //function for adding the Payees and it only accessible by Payer
    function AddPayee(string memory _name,uint256 _amount,address _addr) public {
            require(_addr!=address(0),"Zero address entered");
            require(PayeeValidator[msg.sender][_name][_addr]==false,"Already Payee Added");
            _amount=_amount*1 ether; //converts the value from wei to ether
            Payer_details[msg.sender].Payee_list.push(_addr); 
            Payer_details[msg.sender].Payees=Payer_details[msg.sender].Payee_list.length; 
            Payee_details[msg.sender][_addr] = Payee(_name,_amount,_addr,0,Payer_details[msg.sender].Payees);
            Payer_details[msg.sender].Totalpay+=_amount;
            PayeeValidator[msg.sender][_name][_addr]=true;
    }
      //function for removing the Payees and it only accessible by Payer
    function RemovePayee(address _payee) public {
       require(Payee_details[msg.sender][_payee].Payee!=address(0) && _payee!=address(0) ,"Payee doesnt exist or Zero address entered");
        uint256 Payees = Payer_details[msg.sender].Payees;
        uint256 id = Payee_details[msg.sender][_payee].Index;
        address temp = Payer_details[msg.sender].Payee_list[Payees-1];
        Payer_details[msg.sender].Payee_list[Payees-1] = Payer_details[msg.sender].Payee_list[id-1];
        Payer_details[msg.sender].Payee_list[id-1] = temp;
        Payer_details[msg.sender].Totalpay-=Payee_details[msg.sender][_payee].Amount;
        delete Payee_details[msg.sender][_payee];
    }
      //function is to transfer the amount of ether to Payees
    function TransferPay() payable public AvoidReentrancy{
        require(Payer_details[msg.sender].Payees>0 && Payer_details[msg.sender].Balance>0,"NO Funds available or No Payees listed");
        require(Payer_details[msg.sender].Totalpay<=Payer_details[msg.sender].Balance,"Insufficient Funds");
        for(uint256 i=0;i<Payer_details[msg.sender].Payees;i++) {
           address temp = Payer_details[msg.sender].Payee_list[i];
           uint256 Pay = Payee_details[msg.sender][temp].Amount;
           (bool sent,) = payable(temp).call{value:Pay}(""); //sends ether to Payees
           require(sent,"Failed to send ether");
           emit TransferLog(msg.sender, temp, Pay);
           Payee_details[msg.sender][temp].Balance+=Pay;//Balance of Payee be Updated here
        }
        Payer_details[msg.sender].Balance-=Payer_details[msg.sender].Totalpay;   
    }
   //this function is to withdraw the balance amount from the contract and it can only accessible by Payer
   function WithdrawPayer() payable public  {      
       require(Payer_details[msg.sender].Balance>0,"No Funds Available");
       (bool sent,) = payable(msg.sender).call{value:Payer_details[msg.sender].Balance}("");
       require(sent,"Failed to send ether");
   }
     function GetPayees() public view returns(address[] memory){
        return Payer_details[msg.sender].Payee_list;
    } 
}