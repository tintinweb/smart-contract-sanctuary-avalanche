/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-12
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

contract TodoList {
    event Created(uint id, string content);
    event UpdatedIsCompleted(uint id, bool completed);
    event UpdatedContent(uint id, string content);
    event DeletedTask(uint id);

    struct Task {
        string content;
        bool isCompleted;
        bool isDeleted;
        address ownerAddress;
    }

    uint public taskCount = 0;
    mapping (uint => Task) public tasks;

    constructor() {
        createTask("Initial Data");
    }

    function createTask(string memory _content) public {
        taskCount++;
        tasks[taskCount] = Task(_content, false, false, msg.sender);
        emit Created(taskCount, _content);
    }

    function toggleIsCompleted(uint _id) public ownerOf(_id) {
        Task memory _task = tasks[_id];
        _task.isCompleted = !_task.isCompleted;
        tasks[_id] = _task;
        emit UpdatedIsCompleted(_id, _task.isCompleted);
    }

    function updateContent(uint _id, string memory _content) public ownerOf(_id) {
        Task memory _task = tasks[_id];
        _task.content = _content;
        tasks[_id] = _task;
        emit UpdatedContent(_id, _task.content);
    }

    function deleteTask(uint _id) public ownerOf(_id) {
        Task memory _task = tasks[_id];
        _task.isDeleted = true;
        tasks[_id] = _task;
        emit DeletedTask(_id);
    }

    modifier ownerOf(uint _taskId) {
        require(msg.sender == tasks[_taskId].ownerAddress);
        _;
    }
}