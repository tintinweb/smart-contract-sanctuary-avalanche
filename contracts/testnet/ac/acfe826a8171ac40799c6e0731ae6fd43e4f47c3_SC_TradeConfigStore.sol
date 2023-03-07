/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-07
*/

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.17;

contract Authorization {
    address public owner;
    address public newOwner;
    mapping(address => bool) public isPermitted;
    event Authorize(address user);
    event Deauthorize(address user);
    event StartOwnershipTransfer(address user);
    event TransferOwnership(address user);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier auth {
        require(isPermitted[msg.sender], "Action performed by unauthorized address.");
        _;
    }
    function transferOwnership(address newOwner_) external onlyOwner {
        newOwner = newOwner_;
        emit StartOwnershipTransfer(newOwner_);
    }
    function takeOwnership() external {
        require(msg.sender == newOwner, "Action performed by unauthorized address.");
        owner = newOwner;
        newOwner = address(0x0000000000000000000000000000000000000000);
        emit TransferOwnership(owner);
    }
    function permit(address user) external onlyOwner {
        isPermitted[user] = true;
        emit Authorize(user);
    }
    function deny(address user) external onlyOwner {
        isPermitted[user] = false;
        emit Deauthorize(user);
    }
}

pragma solidity 0.8.17;


contract SC_TradeConfigStore is Authorization {

    address public router;
    uint256 public fee;
    address public feeTo;
    SC_TradeConfigStore public newConfigStore;

    event SetRouter(address router);
    event SetFee(uint256 fee);
    event SetFeeTo(address feeTo);
    event Upgrade(SC_TradeConfigStore newConfigStore);

    constructor(address _router, uint256 _fee, address _feeTo) {
        router = _router;
        fee = _fee;
        feeTo = _feeTo;
    }
    function setRouter(address _router) external onlyOwner {
        router = _router;
        emit SetRouter(_router);
    }
    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit SetFee(_fee);
    }
    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
        emit SetFeeTo(_feeTo);
    }
    function upgrade(SC_TradeConfigStore _newConfigStore) external onlyOwner {
        newConfigStore = _newConfigStore;
        emit Upgrade(_newConfigStore);
    }

    function getTradeParam() external view returns (address _router, uint256 _fee) {
        _router = router;
        _fee = fee;
    }
}