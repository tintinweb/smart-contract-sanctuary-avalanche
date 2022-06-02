/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-02
*/

pragma solidity 0.8.6;



contract Escrow {

    address owner;
    string dumbPassword = "";

    function start() public {
        owner = msg.sender;
    }

    function withdraw(string memory password) public {
        require(keccak256(abi.encodePacked(password)) == keccak256(abi.encodePacked(dumbPassword)));
        payable (msg.sender).transfer(address(this).balance);
    }

    function deposit(uint256 amount) public payable {
        require(msg.value >= amount);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setPassword(string memory password) public {
        require(owner == msg.sender);
        dumbPassword = password;
    }


    receive() external payable {}
}