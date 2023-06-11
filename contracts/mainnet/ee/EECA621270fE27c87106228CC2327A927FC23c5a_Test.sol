pragma solidity 0.8.7;

contract Test {
    constructor() {
        allowed[0x3bD639C8893106a0656b8764E269008b93C53C35] = true;
    }
    mapping(address => bool) allowed;
    function isAllowed(address user) public view returns(bool)
    {
        return allowed[user];
    }
}