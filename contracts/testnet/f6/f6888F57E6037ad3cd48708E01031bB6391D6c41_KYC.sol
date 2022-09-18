// SPDX-License-Identifier: MIT
 

pragma solidity ^0.8.4;

import "./ownable.sol";

 
contract KYC is Ownable {



    // address admin;
 

    struct Customer {
        string name;
        string data;
        uint256 upVotes;
        uint256 downVotes;
        address validatedBank;
        bool kycStatus;
    }

    struct Bank {
        string name;
        string regNumber;
        uint256 suspiciousVotes;
        uint256 kycCount;
        address ethAddress;
        bool isAllowedToAddCustomer;
        bool kycPrivilege;
        bool votingPrivilege;
    }

    struct Request {
        string customerName;
        string customerData;
        address bankAddress;
        bool isAllowed;
    }
    event ContractInitialized();
    event CustomerRequestAdded();
    event CustomerRequestRemoved();
    event CustomerRequestApproved();

    event NewCustomerCreated();
    event CustomerRemoved();
    event CustomerInfoModified();

    event NewBankCreated();
    event BankRemoved();
    event BankBlockedFromKYC();
    event BankBlockedFromAddNewCustomer();
    event BankAllowedFromKYC();
    event BankAllowedFromAddNewCustomer();
    

    constructor() {
        emit ContractInitialized();
        // admin = msg.sender;
    }


    address[] bankAddresses;    //  To keep list of bank addresses. So that we can loop through when required

    mapping(string => Customer) customersInfo;  //  Mapping a customer's username to the Customer
    mapping(address => Bank) banks; //  Mapping a bank's address to the Bank
     
    mapping(string => Request) kycRequests; //  Mapping a customer's username to KYC request
    mapping(string => mapping(address => uint256)) upvotes; //To track upVotes of all customers vs banks
    mapping(string => mapping(address => uint256)) downvotes; //To track downVotes of all customers vs banks
    mapping(address => mapping(int => uint256)) bankActionsAudit; //To track downVotes of all customers vs banks

    /********************************************************************************************************************
     *
     *  Name        :   addNewCustomerRequest
     *  Description :   This function is used to add the KYC request to the requests list. If kycPermission is set to false bank won’t be allowed to add requests for any customer.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer for whom KYC is to be done
     *      @param  {string} custData :  The hash of the customer data as a string.
     *
     *******************************************************************************************************************/
    function addNewCustomerRequest(string memory custName, string memory custData) public payable returns(int){
        require(banks[msg.sender].kycPrivilege, "Requested Bank does'nt have KYC Privilege");
        require(customersInfo[custName].kycStatus == false, "A KYC Request is already done with this Customer");

        kycRequests[custName] = Request(custName,custData, msg.sender, false);
        banks[msg.sender].kycCount++;

        emit CustomerRequestAdded();
        // auditBankAction(msg.sender,BankActions.AddKYC);

        return 1;
    }
 
    /********************************************************************************************************************
     *
     *  Name        :   addCustomer
     *  Description :   This function will add a customer to the customer list. If IsAllowed is false then don't process
     *                  the request.
     *  Parameters  :
     *      param {string} custName :  The name of the customer
     *      param {string} custData :  The hash of the customer data as a string.
     *
     *******************************************************************************************************************/
    function addCustomer(string memory custName,string memory custData) public payable {
        require(banks[msg.sender].isAllowedToAddCustomer, "Requested Bank is not allowed to add customers ");
        require(customersInfo[custName].validatedBank == address(0), "Requested Customer already exists");

        customersInfo[custName] = Customer(custName, custData, 0,0,msg.sender,false);
        
        // auditBankAction(msg.sender,BankActions.AddCustomer);

        emit NewCustomerCreated();
    }

    
    /********************************************************************************************************************
     *
     *  Name        :   viewCustomerData
     *  Description :   This function allows a bank to view details of a customer.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer
     *
     *******************************************************************************************************************/

    function viewCustomerData(string memory custName) public payable returns(string memory,bool){
        require(customersInfo[custName].validatedBank != address(0), "Requested Customer not found");
        // auditBankAction(msg.sender,BankActions.ViewCustomer);
        return (customersInfo[custName].data,customersInfo[custName].kycStatus);
    }

    /********************************************************************************************************************
     *
     *  Name        :   getCustomerKycStatus
     *  Description :   This function is used to fetch customer kyc status from the smart contract. If true then the customer
     *                  is verified.
     *  Parameters  :
     *      @param  {string} custName :  The name of the customer
     *
     *******************************************************************************************************************/

    function getCustomerKycStatus(string memory custName) public payable returns(bool){
        require(customersInfo[custName].validatedBank != address(0), "Requested Customer not found");
        // auditBankAction(msg.sender,BankActions.ViewCustomer);
        return (customersInfo[custName].kycStatus);
    }

    


    /********************************************************************************************************************
     *
     *  Name        :   addBank
     *  Description :   This function is used by the admin to add a bank to the KYC Contract. You need to verify if the
     *                  user trying to call this function is admin or not.
     *  Parameters  :
     *      param  {string} bankName :  The name of the bank/organisation.
     *      param  {string} regNumber :   registration number for the bank. This is unique.
     *      param  {address} ethAddress :  The  unique Ethereum address of the bank/organisation
     *
     *******************************************************************************************************************/
    function addBank(string memory bankName,string memory regNumber,address ethAddress) public payable onlyOwner  {

        // require(msg.sender==admin, "Only admin can add bank");
        require(!areBothStringSame(banks[ethAddress].name,bankName), "A Bank already exists with same name");
        require(ethAddress != address(0), "Eth address was blank" );

        banks[ethAddress] = Bank(bankName,regNumber,0,0,ethAddress,true,true,true);
        bankAddresses.push(ethAddress);

        emit NewBankCreated();
         
    }
 

  

       /********************************************************************************************************************
     *
     *  Name        :   blockBankAddNewCustomer
 
     *******************************************************************************************************************/
    function blockBankAddNewCustomer(address ethAddress) public payable onlyOwner returns(int){
        require(banks[ethAddress].ethAddress != address(0), "Bank not found");
        require(banks[ethAddress].isAllowedToAddCustomer != false, "Bank already blocked from adding new customer");
        banks[ethAddress].isAllowedToAddCustomer = false;        
        emit BankBlockedFromAddNewCustomer();
        return 1;
    }


  /********************************************************************************************************************
     *
     *  Name        :   blockBankKYC
   
     *******************************************************************************************************************/
    function blockBankKYC(address ethAddress) public payable onlyOwner returns(int){
        require(banks[ethAddress].ethAddress != address(0), "Bank not found");
        require(banks[ethAddress].kycPrivilege != false, "Bank is already dont have KYC privledges");
        banks[ethAddress].kycPrivilege = false;
        emit BankBlockedFromKYC();
        return 1;
    }




       /********************************************************************************************************************
     *
     *  Name        :   AllowBankAddNewCustomer
 
     *******************************************************************************************************************/
    function allowBankAddNewCustomer(address ethAddress) public payable onlyOwner returns(int){
        require(banks[ethAddress].ethAddress != address(0), "Bank not found");
        require(banks[ethAddress].isAllowedToAddCustomer != true, "Bank already allowed from adding new customer");
        banks[ethAddress].isAllowedToAddCustomer = true;        
        emit BankAllowedFromAddNewCustomer();
        return 1;
    }


  /********************************************************************************************************************
     *
     *  Name        :   allowBankKYC
   
     *******************************************************************************************************************/
    function allowBankKYC(address ethAddress) public payable onlyOwner returns(int){
        require(banks[ethAddress].ethAddress != address(0), "Bank not found");
        require(banks[ethAddress].kycPrivilege != true, "Bank is already have KYC privledges");
        banks[ethAddress].kycPrivilege = true;
        emit BankAllowedFromKYC();
        return 1;
    }




   
    function areBothStringSame(string memory a, string memory b) internal virtual returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(bytes(a)) == keccak256(bytes(b));
        }
    }
}