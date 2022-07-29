// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TimeLockedWallet.sol";

contract TimeLockedWalletFactory {

    mapping(address => address[]) public ownerToWallets;

    function getWalletsOfAddress(address _walletsToView) 
        public view 
        returns(address[] memory _walletsOfAddress) 
    {
        return ownerToWallets[_walletsToView];
    }

    function getWalletsOfSender() 
        public view 
        returns(address[] memory _walletsOfAddress) 
    {
        return ownerToWallets[msg.sender];
    }

    function newWallet(uint256 _unlockDate) payable public returns(address _a)
    {
        TimeLockedWallet _newWallet = new TimeLockedWallet(_unlockDate, msg.sender);
        address payable _newPayableAddress = payable(address(_newWallet));

        ownerToWallets[msg.sender].push(address(_newWallet));
        _newPayableAddress.transfer(msg.value);

        return address(_newWallet);
    }


    receive() external payable {
        revert();
    }

    fallback() external payable {
        revert();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TimeLockedWallet {

    uint256 public unlockedDate;
    address public user;

    modifier isUnlocked {
        require(block.timestamp > unlockedDate);
        _;
    }

    modifier isUser {
        require(msg.sender == user);
        _;
    }

    event Received(address from, uint256 amount);
    event Withdrawn(address payable to, uint256 balance);

    constructor(uint256 _unlockDate, address _user) {
        unlockedDate = _unlockDate;
        user = _user;
    }

    receive() external payable {
        // React to receiving ether
        emit Received(msg.sender, msg.value);
    }

    function withdraw() isUser public {
        address payable _toSend = payable(user);

        _toSend.transfer(address(this).balance);
        emit Withdrawn(_toSend, address(this).balance);
    }

    function getContractInfo() public view 
        returns( address, uint256, uint256) {
            return (user , unlockedDate, address(this).balance);
    }
}