/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-17
*/

contract WalletImplementation {
    address public implementation;
    address payable public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    receive() external payable {}

    function setImplementation(address _implementation) external {
        implementation = _implementation;
    }

    function withdraw() external onlyOwner {
        owner.transfer(address(this).balance);
    }
}