/**
 *Submitted for verification at testnet.snowtrace.io on 2022-03-18
*/

contract test {
    
    mapping (uint => mapping (uint => bool)) public cells;
    mapping (uint => address) public cellsOwned;

    constructor () {
        cells[0][0] = true;
        cellsOwned[0] = msg.sender;
    }

    function computePath(uint[] calldata path) public returns (bool) {
        uint length = path.length;
        address sender = msg.sender;
        for (uint i=1; i < length; i++) {
            if (cells[path[i-1]][path[i]] == false || cellsOwned[i-1] != sender) {
                return false;
            }
        }
        return true;
    }

}