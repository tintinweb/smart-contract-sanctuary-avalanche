/**
 *Submitted for verification at testnet.snowtrace.io on 2022-05-09
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract TCv1 {

    // cannot prototype functions in solidity?
    // function currentSupply() external view returns (uint256);
    // function balanceOf(address account) external view returns (uint256);
    // function allowance(address owner, address spender) external view returns (uint256);

    // function transfer(address recipient, uint256 amount) external returns (bool);
    // function approve(address spender, uint256 amount) external returns (bool);
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    // necessary for wallet connection
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    // event Burn(address indexed burner, uint256 value);

    string public constant name = "Triple Confirmation v1 Token";
    string public constant symbol = "TCv1";

    uint8 public constant decimals = 18;
    uint256 public constant minIncrement = 10 ** 8;
    uint256 public constant supply = 142000000;

    uint8 public constant burnPct = 1;
    uint8 public constant redistPct = 1;
    uint8 public constant whtlstPct = 2;

    // TC Incentives Multisig Wallet by default
    address public originWallet;
    bool public isLocked;
    uint256 public redistAmount;

    struct user {
        address userAddress;
        uint256 balance;
        bool registered;
    }

    uint256 public numberOfUsers;
    mapping(address => uint256) userIDs;
    mapping(uint256 => user) public users;
    mapping(address => mapping (address => uint256)) allowed;

    function normalize(uint256 amount) internal pure returns (uint256) {
        return amount * 10 ** decimals;
    }

    function totalSupply() public pure returns (uint256) {
        return normalize(supply);
    }

    // lock or unlock the contract
    function changeLockStatus(bool status) public {
        require(msg.sender == originWallet);

        isLocked = status;
    }

    // origin wallet can select a new origin
    function changeOwner(address newOrigin) public {
        require(msg.sender == originWallet);

        addUser(newOrigin);
        _transfer(originWallet, newOrigin, balanceOf(originWallet));
        originWallet = newOrigin;
    }

    constructor() {
        originWallet = msg.sender;
        _addUser(address(0));
        _addUser(originWallet);
        users[userIDs[address(0)]].balance = 0;
        users[userIDs[originWallet]].balance = normalize(supply);
        // pseudo mint event
        emit Transfer(address(0), originWallet, normalize(supply));
    }

    function _addUser(address newUser) internal {
        users[numberOfUsers].userAddress = newUser;
        users[numberOfUsers].registered = true;
        userIDs[newUser] = numberOfUsers;
        numberOfUsers++;
    }

    // check and add a new user
    function addUser(address newUser) internal {
        if (userIDs[newUser] > 0 || newUser == originWallet) {
            return;
        }
        _addUser(newUser);
    }

    // get balance for a user
    function balanceOf(address user) public view returns (uint256 balance) {
        return users[userIDs[user]].balance;
    }

    // get all users
    function getUsers() public view returns (user[] memory) {
        require(msg.sender == originWallet);

        user[] memory ret = new user[](numberOfUsers);
        for (uint256 i = 0; i < numberOfUsers; i++) {
            ret[i] = users[i];
        }
        return ret;
    }

    // burn tokens
    function _burn(address sender, uint256 amountToBurn) internal {
        require(amountToBurn <= balanceOf(sender));

        users[userIDs[sender]].balance = balanceOf(sender) - amountToBurn;
        users[userIDs[originWallet]].balance = balanceOf(originWallet) + amountToBurn;

        // emit Burn(sender, amountToBurn);
        emit Transfer(sender, originWallet, amountToBurn);
    }

    // manual burn
    function burn(uint256 amount) public {
        require(!isLocked);
        address sender = msg.sender;

        addUser(sender);
        _burn(sender, amount);
    }

    // transfer tokens
    function _transfer(address sender, address receiver, uint256 amount) internal returns (bool success) {
        users[userIDs[sender]].balance = balanceOf(sender) - amount;
        users[userIDs[receiver]].balance = balanceOf(receiver) + amount;

        emit Transfer(sender, receiver, amount);
        return true;
    }

    // burn [burnPct]% and redistribute [redistPct]% of transferred tokens
    function _burnAndRedist(address sender, address receiver, uint256 amount) internal returns (bool success) {
        uint256 amountToBurn = amount * burnPct / 100;
        uint256 amountToRedist = amount * redistPct / 100;
        redistAmount += amountToRedist;

        _burn(sender, amountToBurn + amountToRedist);

        uint256 amountToTransfer = amount - amountToBurn - amountToRedist;
        return _transfer(sender, receiver, amountToTransfer);
    }

    function checkTransferType(address sender, address receiver, uint256 amount) internal returns (bool success) {
        require(!isLocked);
        require(amount >= minIncrement);

        addUser(sender);
        addUser(receiver);

        amount = amount - (amount % minIncrement);
        require(amount <= balanceOf(sender));
    
        // don't burn/redist when xferring to/from origin wallet
        if (sender == originWallet || receiver == originWallet) {
            return _transfer(sender, receiver, amount);
        }
        return _burnAndRedist(sender, receiver, amount);
    }

    function transfer(address receiver, uint256 amount) public returns (bool success) {
        return checkTransferType(msg.sender, receiver, amount);
    }

    function approve(address delegate, uint256 amount) public returns (bool) {
        allowed[msg.sender][delegate] = amount;
        emit Approval(msg.sender, delegate, amount);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 amount) public returns (bool success) {
        require(amount <= allowed[owner][msg.sender]);
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - amount;
        return checkTransferType(owner, buyer, amount);
    }

    function redistribute() public {
        require(msg.sender == originWallet);
        require(redistAmount > 0);

        for (uint256 i = 2; i < numberOfUsers; i++) {
            // TODO: implement some restriction on which accounts can receive redist
            uint256 amountToRedist = redistAmount * users[i].balance / supply;
            _transfer(originWallet, users[i].userAddress, amountToRedist);
        }
        redistAmount = 0;
    }

}