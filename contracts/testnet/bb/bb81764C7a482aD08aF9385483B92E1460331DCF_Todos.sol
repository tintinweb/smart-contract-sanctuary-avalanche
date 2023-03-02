/**
 *Submitted for verification at testnet.snowtrace.io on 2023-02-24
*/

// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.17;

contract Todos {
    struct Todo {
        string text;
        bool completed;
    }

    mapping(address => Todo[]) public todos;

    constructor() {}

    function create(string calldata _text) public returns (uint) {
        todos[msg.sender].push(Todo(_text, false));
        return todos[msg.sender].length;
    }

    function get(uint _index) public view returns (string memory text, bool completed) {
        Todo storage todo = todos[msg.sender][_index];
        return (todo.text, todo.completed);
    }

    function get_all() public view returns(string[] memory, bool[] memory) {
        Todo[] storage _todos = todos[msg.sender];
        
        string[] memory text = new string[](_todos.length);
        bool[] memory completed = new bool[](_todos.length);

        for(uint i = 0; i < _todos.length; i++) {
            text[i] = _todos[i].text;
            completed[i] = _todos[i].completed;
        }
        
        return (text, completed);

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