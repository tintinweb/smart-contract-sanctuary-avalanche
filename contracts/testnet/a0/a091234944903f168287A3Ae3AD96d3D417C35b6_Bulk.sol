// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 { 
    function transfer(address to, uint256 amount) external returns (bool);
        //conmntract address 0x86aF33eB1c2a06F30A212304dB2e607F4141E8Ce
    function balanceOf(address account) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Bulk {
    struct MyData {
        uint256 number;
        address addr;
        address sentBy;
        uint256 time;
        bool withdrawn;
        bool paused;
        bool cancelled;
        uint txId;
    }

    event tokenCreated(address indexed token);

    IERC20 public token;
    MyData[] public combinedArray;
    mapping(address => uint) public balances;
    mapping(address => uint) public withdrawals;
    mapping(address => uint256[]) public traverseTx; // This is a mapping where we keep track of all Tx_id created on a particular address

    uint public count;


    constructor(address tokenAddress){
        token = IERC20(tokenAddress);
        emit tokenCreated(tokenAddress);
    }

    function combineArrays(uint256[] memory numbers, address[] memory addresses,uint256[] memory time) public {
        require(numbers.length == addresses.length, "Array lengths must match");
        uint index = combinedArray.length;
        for (uint256 i = 0; i < numbers.length; i++) {
            combinedArray.push(MyData(numbers[i], addresses[i],msg.sender,time[i],false,false,false,count));
            traverseTx[addresses[i]].push(count);
            count++;
        }
        sendBulkPayments(index);
    }

    function sendBulkPayments(uint index) public {
        require(combinedArray.length>0,"Empty Array");
        for(uint256 i = index;i<combinedArray.length;i++){
            // token.transfer(combinedArray[i].addr,combinedArray[i].number * (10**18));
            balances[combinedArray[i].addr]+=combinedArray[i].number;
        }
    }

    function withdraw(uint _txId) external{
        MyData storage mydata = combinedArray[_txId];
        require(!mydata.withdrawn,"Already withdrawn");
        require(block.timestamp>=mydata.time,"Release time not reached");
        require(mydata.number<=balances[msg.sender],"Insufficient Balance Availabe");
        uint amount=mydata.number;
        balances[msg.sender]-=amount;
        withdrawals[msg.sender]+=amount;
        token.transfer(msg.sender,amount * (10**18));
        mydata.withdrawn=true;
    }

    function pauseStream(uint _txId) external {
        MyData storage mydata = combinedArray[_txId];
        require(!mydata.withdrawn,"Already withdrawn");
        require(!mydata.paused,"Already Paused");
        mydata.paused=true;
    }

    function resumeStream(uint _txId) external {
        MyData storage mydata = combinedArray[_txId];
        require(!mydata.withdrawn,"Already withdrawn");
        require(mydata.paused,"Already Resumed");
        mydata.paused=false;
    }

    function cancelStream(uint _txId) external {
        MyData storage mydata = combinedArray[_txId];
        require(!mydata.withdrawn,"Already withdrawn");
        require(!mydata.cancelled,"Already Cancelled");
        uint amount = mydata.number;
        balances[mydata.addr]-=amount;
        mydata.cancelled=true;
    }

    function getAvailableAmount()public returns(uint){ //This will mark the status of all available tx as withdrawn=true
        uint totalamount;
        for(uint i = 0;i<traverseTx[msg.sender].length;i++){
            MyData storage mydata = combinedArray[traverseTx[msg.sender][i]];
            if(!mydata.withdrawn && mydata.time<=block.timestamp ){
                totalamount+=mydata.number;
                mydata.withdrawn=true;
            }
        }
        return totalamount;
    }

    function viewAvailableAmount()public view returns(uint){ // this is only to view Total Amount Available for withdrawal
        uint totalamount;
        for(uint i = 0;i<traverseTx[msg.sender].length;i++){
            MyData storage mydata = combinedArray[traverseTx[msg.sender][i]];
            if(!mydata.withdrawn && mydata.time<=block.timestamp ){
                totalamount+=mydata.number;
            }
        }
        return totalamount;
    }

    function withdrawAll() external{
        uint amount = getAvailableAmount();
        require(amount>0,"Zero Amount available At the Moment");
        balances[msg.sender]-=amount;
        withdrawals[msg.sender]+=amount;
        token.transfer(msg.sender,amount * (10**18));
    }


    function clearArray() public {
        delete combinedArray;
    }

    function getData() public view returns(MyData[] memory){
        return combinedArray;
    }

    function getBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
}