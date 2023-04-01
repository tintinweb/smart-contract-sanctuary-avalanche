// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract Whitelist {
    string baseURL;

    struct User {
        address user;
        uint256 amount;
        uint256 referrals;
        bool whitelisted;
    }

    mapping(string => User) public whitelisted;

    event Whitelisted(address indexed user, uint256 indexed amount);

    event Referral(address indexed user, uint256 indexed referrals);

    constructor(string memory _baseURL) {
        baseURL = _baseURL;
    }

    function whitelist(string memory ID, uint256 _amount) public  {
        require(!whitelisted[ID].whitelisted, "Already whitelisted");

        User memory user = User({
            user : msg.sender,
            amount : _amount,
            referrals : 0,
            whitelisted : true
        });

        whitelisted[ID] = user;

        emit Whitelisted(msg.sender, _amount);
    }

    function referral(string memory ID) public {
        require(whitelisted[ID].whitelisted, "Not whitelisted");

        whitelisted[ID].referrals += 1;

        emit Referral(msg.sender, whitelisted[ID].referrals);
    }
}