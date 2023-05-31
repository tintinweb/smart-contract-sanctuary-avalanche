pragma solidity >=0.8.0;

contract EventTest {
    event TestingEvent();

    uint256 public state;

    function test() external {
        ++state;
        emit TestingEvent();
        ++state;
        emit TestingEvent();
        ++state;
        emit TestingEvent();
    }
}