/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-24
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.9;

contract Todos {
    struct Todo {
        string text;
        bool completed;
    }

    mapping(address => Todo[]) public todos;

    function create(string calldata _text) public {
        todos[msg.sender].push(Todo(_text, false));
    }

    function get(uint _index) public view returns (string memory text, bool completed) {
        Todo storage todo = todos[msg.sender][_index];
        return (todo.text, todo.completed);
    }
    
    function get_all() public view returns (Todo[] memory _todos) {
        return todos[msg.sender];
    }

    function updateText(uint _index, string calldata _text) public {
        Todo storage todo = todos[msg.sender][_index];
        todo.text = _text;
    }

    function toggleCompleted(uint _index) public {
        Todo storage todo = todos[msg.sender][_index];
        todo.completed = !todo.completed;
    }
}