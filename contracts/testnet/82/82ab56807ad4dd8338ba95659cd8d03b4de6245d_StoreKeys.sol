/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-06
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


contract StoreKeys {

    address public owner;

    mapping(address => uint256) public totalCount;
    mapping(address => mapping(string => string)) private _storeBox;

    constructor() {
        owner = msg.sender;
    }

    // events about state change
    event Store(address _from, string _account);
    event Update(address _from, string _account);
    event Delete(address _from, string _account);

    // check params
    modifier beforeChange(string memory account, string memory priv) {
        require(keccak256(abi.encodePacked(account)) != keccak256(abi.encodePacked("")), "account name do not empty.");
        require(keccak256(abi.encodePacked(priv)) != keccak256(abi.encodePacked("")), "account private do not empty.");
        _;
    }

    // create
    function store(string memory account, string memory priv) external beforeChange(account, priv) {
        _storeBox[msg.sender][account] = priv;
        totalCount[msg.sender] += 1;

        emit Store(msg.sender, account);
    }

    // search
    function getUserItem(string memory _account) external view returns(string memory) {
        return _storeBox[msg.sender][_account];
    }

    // update
    function updatePrivByAccount(string memory account, string memory priv) external beforeChange(account, priv) {
        _storeBox[msg.sender][account] = priv;

        emit Update(msg.sender, account);
    }

    // delete
    function deleteItem(string memory account) external {
        string memory priv = _storeBox[msg.sender][account];
        require(keccak256(abi.encodePacked(priv)) != keccak256(abi.encodePacked("")), "account not exists.");
        require(totalCount[msg.sender] >= 1, "account total count is zero.");
        delete _storeBox[msg.sender][account];
        totalCount[msg.sender] -= 1;

        emit Delete(msg.sender, account);
    }
}