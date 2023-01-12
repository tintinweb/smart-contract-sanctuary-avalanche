/**
 *Submitted for verification at testnet.snowtrace.io on 2023-01-11
*/

// SPDX-License-Indentifier: MIT
pragma solidity ^0.8.7;

contract TodoList {
    address public immutable owner;

    struct Todo {
        string text;
        bool completed;
    }

    Todo[] public todos;

    constructor() {
        owner = msg.sender;
    }

    function create(string calldata _text) external {
        todos.push(Todo({
            text: _text,
            completed: false
        }));
    }

    function updateText(uint _index, string calldata _text) external {
        Todo storage todo = todos[_index];
        todo.text = _text;
        // todos[_index].text = _text; // same operation but more gas amount
    }

    function get(uint _index) external view returns (string memory, bool) {
        Todo memory todo = todos[_index];
        return (todo.text, todo.completed);
    }

    function toggleCompleted(uint _index) external {
        Todo storage todo = todos[_index];
        todo.completed = !todo.completed;
    }
}