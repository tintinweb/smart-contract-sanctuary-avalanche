/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract StoreKeys {

    address public owner;

    struct mega {
        string accountHash;
        string privHash;
    }

    mapping(address => mega[]) private _storeBox;

    constructor() {
        owner = msg.sender;
    }

    event Store(address _from, string _accountHash, uint256 _count);

    // create
    function store(string memory account, string memory priv) external {
        _storeBox[msg.sender].push(mega(account, priv));
        emit Store(msg.sender, account, _storeBox[msg.sender].length);
    }

    // search
    function getUserItems() external view returns(mega[] memory) {
        return _storeBox[msg.sender];
    }

    // update
    function updatePrivByAccount(string memory account, string memory priv) external returns(bool) {
        for (uint256 i; i < _storeBox[msg.sender].length; i++) {
            mega storage userItem = _storeBox[msg.sender][i];
            if (stringsEqual(userItem.accountHash, account)) {
                // require(stringsEqual(userItem.privHash, priv) == false, "private key not same as last");
                _storeBox[msg.sender][i] = mega(account, priv);
                return true;
            }   
        }
        return false;
    }

    // delete
    function deleteItem(string memory account) external returns(bool) {
        for (uint256 i; i < _storeBox[msg.sender].length; i++) {
            mega storage userItem = _storeBox[msg.sender][i];
            if (stringsEqual(userItem.accountHash, account)) {
                // require(stringsEqual(userItem.privHash, priv) == true, "private key not same the storage");
                delete _storeBox[msg.sender][i];
                return true;
            }
        }
        return false;
    }


    function stringsEqual(string storage _a, string memory _b) internal view returns (bool) {
        bytes storage a = bytes(_a);
        bytes memory b = bytes(_b);
        if (a.length != b.length)
            return false;
        // @todo unroll this loop
        for (uint i = 0; i < a.length; i ++)
        {
            if (a[i] != b[i])
                return false;
        }
        return true;
    }

}