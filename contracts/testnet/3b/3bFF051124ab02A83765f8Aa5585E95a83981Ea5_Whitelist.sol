// SPDX-License-Identifier: GPL-3.0

pragma solidity  >=0.4.24 <0.9.0;
pragma experimental ABIEncoderV2;

contract Whitelist {

    struct WhitelistUser {
        address whitelistAddress;
        uint tier;
    }

    mapping(address => bool) adminAddresses;

    mapping(address => uint) whitelistedAddresses;

    constructor() {
        adminAddresses[0xCeaf7780c54bc6815A8d5c3E10fdc965d0F26762] = true;
        adminAddresses[0x9CB52e780db0Ce66B2c4d8193C3986B5E7114336] = true;
        adminAddresses[0xbDe951E26aae4F39e20628724f58293A4E6457D4] = true;
    }

    modifier onlyOwner() {
      require(adminAddresses[msg.sender], "Ownable: caller is not the owner");
      _;
    }

    function addAdmin(address _address) public onlyOwner {
      adminAddresses[_address] = true;
    }

    modifier isWhitelisted(address _address) {
      require(whitelistedAddresses[_address] > 0, "Whitelist: You need to be whitelisted");
      _;
    }

    function addAddressesToWhitelist(WhitelistUser[] memory _users) public onlyOwner {
      for (uint256 i = 0; i < _users.length; i++) {
        addAddressToWhitelist(_users[i]);
      }
    }

    function removeAddressesToWhitelist(address[] memory _addresses) public onlyOwner {
      for (uint256 i = 0; i < _addresses.length; i++) {
        removeAddressFromWhitelist(_addresses[i]);
      }
    }

    function addAddressToWhitelist(WhitelistUser memory _user) public onlyOwner {
      whitelistedAddresses[_user.whitelistAddress] = _user.tier;
    }

    function removeAddressFromWhitelist(address _address) public onlyOwner {
      whitelistedAddresses[_address] = 0;
    }

    function verifyUser(address _whitelistedAddress) public view returns(uint) {
      uint userIsWhitelisted = whitelistedAddresses[_whitelistedAddress];
      return userIsWhitelisted;
    }
}