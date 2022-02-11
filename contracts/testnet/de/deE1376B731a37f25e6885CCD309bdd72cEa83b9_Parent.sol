pragma solidity ^0.4.6;

import "./Child.sol";

contract Parent {

  address owner;
  address[] public children; // public, list, get a child address at row #
  event LogChildCreated(address child); // maybe listen for events

  constructor(){
    owner = msg.sender;
  }

  function createChild() {
    Child child = new Child();
    LogChildCreated(child); // emit an event - another way to monitor this
    children.push(child); // you can use the getter to fetch child addresses
  }
}