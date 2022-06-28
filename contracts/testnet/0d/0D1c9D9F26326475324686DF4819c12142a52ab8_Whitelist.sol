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

    mapping(uint => uint) public keyTiers;
    
    constructor() {
        adminAddresses[0xCeaf7780c54bc6815A8d5c3E10fdc965d0F26762] = true;
        adminAddresses[0x9CB52e780db0Ce66B2c4d8193C3986B5E7114336] = true;
        adminAddresses[0xbDe951E26aae4F39e20628724f58293A4E6457D4] = true;
        adminAddresses[0xD797d3510e5074891546797f2Ab9105bd0e41bC3] = true;
        adminAddresses[0x44D0b410623a3CF03ae06F782C111F23fADedAdA] = true;
        adminAddresses[0x53c52a7B7Fc72ED24882Aa195A5659DC608cc552] = true;
        adminAddresses[0x77CF5565be42dD8d33e02EAd4B2d164C6368Bfcd] = true;
        adminAddresses[0x7FAA068AEF77bAfE9462910548c6A2C4c10d247f] = true;
        adminAddresses[0x3F682Bdb2f6315C55b6546FD3d2dea14425112Da] = true;
        adminAddresses[0x06025812fDe95F375E3ddAf503e8e25E2724D4e2] = true;
    }

    modifier onlyOwner() {
      require(adminAddresses[msg.sender], "Whitelist Ownable: caller is not the owner");
      _;
    }

    function addAdmin(address _address) public onlyOwner {
      adminAddresses[_address] = true;
    }

    function setKeyTier(uint _tokenId, uint _tier) public onlyOwner {
      keyTiers[_tokenId] = _tier;
    }

    function getKeyTier(uint _tokenId) public view returns (uint) {
      return keyTiers[_tokenId];
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