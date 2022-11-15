pragma solidity 0.8.15;

contract AddInit {
    int256  public a;
    function add(int256 _a) public {
        a = _a;
    }
}