/**
 *Submitted for verification at testnet.snowtrace.io on 2022-04-01
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IOldTap {
    struct User {
        //Referral Info
        address upline;
        uint256 referrals;
        uint256 total_structure;
        //Long-term Referral Accounting
        uint256 direct_bonus;
        uint256 match_bonus;
        //Deposit Accounting
        uint256 deposits;
        uint256 deposit_time;
        //Payout and Roll Accounting
        uint256 payouts;
        uint256 rolls;
        //Upline Round Robin tracking
        uint256 ref_claim_pos;
        address entered_address;
    }
    function users(address _addr)
        external
        view
        returns (User memory);
}

contract TheTapV2 {
    address public OldTapAddress;
    mapping(address => IOldTap.User) public users;
    function setTapAddress(address _addr) external {
        OldTapAddress = _addr;
    }
    function transferUser(address[] calldata _addr) external {
        for (uint i = 0; i < _addr.length; i++) {
            IOldTap.User memory _user = IOldTap(OldTapAddress).users(_addr[i]);
            users[_addr[i]] = _user;
        }
    }
}