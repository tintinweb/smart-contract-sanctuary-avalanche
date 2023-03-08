/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract TaskOswaldo {
    
    address owner;
    
    //Task Data
    struct Task {
        string title;
        string description;
        uint creationTime;
        uint deadline;
        uint reward;
        uint status; // 0=active, 1=expired, 2=completed
    }
    
    //task array by address
    mapping(address => Task[]) tasks;
    
    //set owner of contract
    constructor() {
        owner = msg.sender;
    }
    
    /*
        createTask(): Function to create a new task, and put it into the task array

        parameters:
            - _title(string): title of task
            - _description(string): description of tasks
            - _deadline(uint): time limit to complete the task
            - _reward(uint): reward for completing the task
    */
    function setCreateTask(string calldata _title, string calldata _description, uint _deadline, uint _reward) external payable {

        //require the time limit to be greater than the creation time.
        require(_deadline > block.timestamp, "Deadline must be in the future");

        //require the time limit to be greater than the creation time.
        require(msg.value == _reward, "Insert the correct reward");

        tasks[msg.sender].push(Task(_title, _description, block.timestamp, _deadline, _reward, 0));
    }
    
    /*
        getTasks(): returns the values inside the array of objects, using as 
        search index the wallet that makes the query. 
        in this way the user can see all the tasks he has created.

        parameters:
            - Task[]: array of tasks
    */
    function getTasks() external view returns (Task[] memory) {
        return tasks[msg.sender];
    }

    /*
        setCompleted(): mark that the task has been completed

        parameters:
            - index(uint): index of task
    */
    function setCompleted(uint index) external payable {
        //require the task to be active in order to deactivate it
        require(tasks[msg.sender][index].status == 0, "Task is not active");

        //update status to completed (2)
        tasks[msg.sender][index].status = 2;

        //take the value of the reward
        uint reward = tasks[msg.sender][index].reward;

        //verify that the deadline is less than or equal to the time of creation
        if (block.timestamp <= tasks[msg.sender][index].deadline) {

            //pay to the wallet requesting the function
            payable(msg.sender).transfer(reward);

        }
    }

    /*
        checkStatus(): checks the status of the task, to verify if the time has expired.

        parameters:
            - index(uint): index of task
    */
    function getCheckStatus(uint index) external {
        if (tasks[msg.sender][index].status != 2 && block.timestamp > tasks[msg.sender][index].deadline) {

            //f the time limit has expired, the task status is changed to expired (1)
            tasks[msg.sender][index].status = 1;

        }
    }
    
    /*
        withdrawBalance(): the wallet owning the contract can withdraw the funds at any time.

    */
    function getWithdrawBalance() external {
        //verify if the wallet requesting the function, is the owner
        require(msg.sender == owner, "Only owner can withdraw");

        //pay the balance to the requesting wallet
        payable(msg.sender).transfer(address(this).balance);
    }
    
    /*
        getTotalBalance():get the balance into the contract.

    */
    function getTotalBalance() external view returns(uint256){
        return address(this).balance;
    }
    
}