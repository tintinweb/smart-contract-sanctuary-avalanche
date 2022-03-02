// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.0;

interface AccountInterface {
    function isAuth(address _user) external view returns (bool);
}

contract ControllerLink {
    // Smart Account Count.
    uint64 public accounts;
    mapping(address => uint64) public accountID;
    mapping(uint64 => address) public accountAddr;
    mapping(address => UserLink) public userLink;
    mapping(address => mapping(uint64 => UserList)) public userList;

    event NewAccount(address owner, address account);

    struct UserLink {
        uint64 first;
        uint64 last;
        uint64 count;
    }
    struct UserList {
        uint64 prev;
        uint64 next;
    }

    mapping(uint64 => AccountLink) public accountLink;
    mapping(uint64 => mapping(address => AccountList)) public accountList;

    struct AccountLink {
        address first;
        address last;
        uint64 count;
    }
    struct AccountList {
        address prev;
        address next;
    }

    // function init(address _account) external {
    //     accounts++;
    //     accountID[_account] = accounts;
    //     accountAddr[accounts] = _account;
    // }

    // function addAuth(address _owner, address _account) external {
    //     require(accountID[_account] != 0, "not-account");
    //     addAccount(_owner, accountID[_account]);
    //     addUser(_owner, accountID[_account]);

    //     emit NewAccount(_owner, _account);
    // }

    function addAuth(address _owner, address _account) external {
        accounts++;
        accountID[_account] = accounts;
        accountAddr[accounts] = _account;
        addAccount(_owner, accountID[_account]);
        addUser(_owner, accountID[_account]);

        emit NewAccount(_owner, _account);
    }

    function removeAuth(address _owner, address _account) external {
        require(accountID[_account] != 0, "not-account");
        require(!AccountInterface(msg.sender).isAuth(_owner), "already-owner");
        removeAccount(_owner, accountID[_account]);
        removeUser(_owner, accountID[_account]);
    }

    function addAccount(address _owner, uint64 _account) internal {
        if (userLink[_owner].last != 0) {
            userList[_owner][_account].prev = userLink[_owner].last;
            userList[_owner][userLink[_owner].last].next = _account;
        }
        if (userLink[_owner].first == 0) userLink[_owner].first = _account;
        userLink[_owner].last = _account;
        userLink[_owner].count = add(userLink[_owner].count, 1);
    }

    function addUser(address _owner, uint64 _account) internal {
        if (accountLink[_account].last != address(0)) {
            accountList[_account][_owner].prev = accountLink[_account].last;
            accountList[_account][accountLink[_account].last].next = _owner;
        }
        if (accountLink[_account].first == address(0))
            accountLink[_account].first = _owner;
        accountLink[_account].last = _owner;
        accountLink[_account].count = add(accountLink[_account].count, 1);
    }

    function removeAccount(address _owner, uint64 _account) internal {
        uint64 _prev = userList[_owner][_account].prev;
        uint64 _next = userList[_owner][_account].next;
        if (_prev != 0) userList[_owner][_prev].next = _next;
        if (_next != 0) userList[_owner][_next].prev = _prev;
        if (_prev == 0) userLink[_owner].first = _next;
        if (_next == 0) userLink[_owner].last = _prev;
        userLink[_owner].count = sub(userLink[_owner].count, 1);
        delete userList[_owner][_account];
    }

    function removeUser(address _owner, uint64 _account) internal {
        address _prev = accountList[_account][_owner].prev;
        address _next = accountList[_account][_owner].next;
        if (_prev != address(0)) accountList[_account][_prev].next = _next;
        if (_next != address(0)) accountList[_account][_next].prev = _prev;
        if (_prev == address(0)) accountLink[_account].first = _next;
        if (_next == address(0)) accountLink[_account].last = _prev;
        accountLink[_account].count = sub(accountLink[_account].count, 1);
        delete accountList[_account][_owner];
    }

    function add(uint64 x, uint64 y) internal pure returns (uint64 z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }

    function sub(uint64 x, uint64 y) internal pure returns (uint64 z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }

    function existing(address _account) external view returns (bool) {
        if (accountID[_account] == 0) {
            return false;
        } else {
            return true;
        }
    }
}