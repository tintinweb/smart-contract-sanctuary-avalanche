/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-10
*/

contract test{
    string[] private long;
    string public short;

    function testWrite1(
        string memory testinput
    ) public {
        short = testinput;
    }

    function testWrite2(
        string[] memory testinputs
    ) public {
        long = testinputs;
    }

    function getLong() public view returns(string[] memory) {
        return long;
    }
}