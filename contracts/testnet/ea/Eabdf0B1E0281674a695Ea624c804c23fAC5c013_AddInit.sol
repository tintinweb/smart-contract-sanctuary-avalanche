pragma solidity 0.8.15;

contract AddInit {
    int256  public a = 1080000000000000000;
    function add(int256 _a) public {
        a = _a;
    }
}