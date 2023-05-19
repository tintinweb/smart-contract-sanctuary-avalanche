// SPDX-License-Identifier: MIT

// Ballot Box Contract
// This contract will keep all ballot boxes and permission
// It will accept vote results from permissioned users
// There will be responsible users to give permissions and make others responsible too

// District system

// Here districts could be cities or counties or event the country itself
// District are identified with an id (1 XX YY)
// The "1" on the beginning is default
// (XX) on the id identifies the city
// (YY) on the id identifies the county
// If (XX) or (YY) values are (00) it means the collective of all of them
// For example
// Id (1 01 00) refers for the district city no 01
// If a user is admin for (1 01 00) that means user have all the authority over city (01)
// If a user is admin for (1 01 01) that means user have only authority over county (1 01 01)

// Ballot Box System

// Here we have a ballot box Id (1 XX YY ZZZZ)
// First part of the code is for district
// (ZZZZ) if for ballot box id

/// TODOS FOR NEXT VERSION

// Change error mesages to optimize
// Users should be able to change their vote results
// Admins can add admins now, also they should be improve admin status of others (county admin -> city admin)

// Next Version Add MVResults too

//

pragma solidity ^0.8.0;

contract BallotSystem {
  struct CBResult {
    uint256 KEMAL_KILICDAROGLU;
    uint256 MUHARREM_INCE;
    uint256 RECEP_TAYYIP_ERDOGAN;
    string url;
  }

  uint256 public constant ADMIN_VALUE = 10000;
  mapping(address => uint256) public admins;
  mapping(uint256 => mapping(address => CBResult)) public results;
  mapping(uint256 => mapping(address => bool)) public permissions;

  event AdminAdded(
    address indexed admin,
    address indexed newAdmin,
    uint256 indexed districtKey
  );

  event UserPermitted(
    address indexed admin,
    address indexed user,
    uint256 indexed districtKey,
    uint256 boxKey
  );

  event VoteResultAddded(
    address indexed user,
    uint256 indexed boxKey,
    uint256 KEMAL_KILICDAROGLU,
    uint256 MUHARREM_INCE,
    uint256 RECEP_TAYYIP_ERDOGAN,
    string _url
  );

  event VoteResultOverriden(
    address indexed user,
    uint256 indexed boxKey,
    uint256 KEMAL_KILICDAROGLU,
    uint256 MUHARREM_INCE,
    uint256 RECEP_TAYYIP_ERDOGAN,
    string _url
  );

  constructor(address[] memory _admins, uint256 adminCount) {
    for (uint i = 0; i < adminCount; i++) {
      admins[_admins[i]] = ADMIN_VALUE;
      emit AdminAdded(address(this), _admins[i], ADMIN_VALUE);
    }
  }

  // Function modifiers to check eligibility of msg senders to use functions

  // Checks districtkey if valid continue

  modifier isValidDistrict(uint256 _districtKey) {
    require(_districtKey >= ADMIN_VALUE, "Wrong District Key");
    require(_districtKey < 20000, "Wrong District Key");
    uint256 cityKey = (_districtKey / 100) % 100;
    require(cityKey <= 81, "Wrong District Key");
    _;
  }

  // Get district Key and checks the authority of the sender if it is the admin of the district

  modifier isAdmin(uint256 _districtKey) {
    require(admins[msg.sender] >= ADMIN_VALUE, "No admin roles");

    uint256 cityKey = (_districtKey / 100) % 100;
    uint256 countyKey = _districtKey % 100;

    uint256 cityAdmin = (100 + cityKey) * 100;
    uint256 countyAdmin = cityAdmin + countyKey;

    require(
      admins[msg.sender] == ADMIN_VALUE ||
        admins[msg.sender] == cityAdmin ||
        admins[msg.sender] == countyAdmin,
      "Admin roles do not match"
    );

    _;
  }

  modifier isPermissioned(uint256 _boxId) {
    require(_boxId > 10 ** 8 && _boxId < 2 * (10 ** 8), "Invalid Box Key");
    uint256 _districtKey = _boxId / 10000;
    uint256 _boxKey = _boxId % 10000;

    if (!permissions[_boxId][msg.sender]) {
      require(admins[msg.sender] >= ADMIN_VALUE);

      uint256 cityKey = (_districtKey / 100) % 100;
      uint256 countyKey = _districtKey % 100;

      uint256 cityAdmin = (100 + cityKey) * 100;
      uint256 countyAdmin = cityAdmin + countyKey;

      require(
        admins[msg.sender] == ADMIN_VALUE ||
          admins[msg.sender] == cityAdmin ||
          admins[msg.sender] == countyAdmin,
        "Admin roles do not match"
      );
    }

    _;
  }

  /// function to add others as admin
  function addAdmin(
    uint256 _districtKey,
    address _newAdmin
  ) public isValidDistrict(_districtKey) isAdmin(_districtKey) {
    require(admins[_newAdmin] == 0, "Already an admin");
    admins[_newAdmin] = _districtKey;

    emit AdminAdded(msg.sender, _newAdmin, _districtKey);
  }

  /// function to give permission
  // Possible bugg different counties could be generated
  // Admins should be ruled well if one loses keys admin roles should be dropped
  // Implement an admin drop protocol
  function givePermission(
    uint256 _districtKey,
    uint256 _boxKey,
    address _newPermission
  ) public isValidDistrict(_districtKey) isAdmin(_districtKey) {
    uint256 boxId = _districtKey * 10000 + _boxKey;
    permissions[boxId][_newPermission] = true;

    emit UserPermitted(msg.sender, _newPermission, _districtKey, _boxKey);
  }

  /// function to add vote result
  function addVoteResult(
    uint256 _boxKey,
    uint256 _kilicdar,
    uint256 _muharrem,
    uint256 _rte,
    string memory _url
  ) public isPermissioned(_boxKey) {
    require(
      results[_boxKey][msg.sender].KEMAL_KILICDAROGLU == 0 &&
        results[_boxKey][msg.sender].RECEP_TAYYIP_ERDOGAN == 0,
      "Already added a result"
    );
    CBResult memory newResult;
    newResult.KEMAL_KILICDAROGLU = _kilicdar;
    newResult.MUHARREM_INCE = _muharrem;
    newResult.RECEP_TAYYIP_ERDOGAN = _rte;
    newResult.url = _url;
    results[_boxKey][msg.sender] = newResult;

    emit VoteResultAddded(
      msg.sender,
      _boxKey,
      _kilicdar,
      _muharrem,
      _rte,
      _url
    );
  }

  // override vote result and emit event
  function overrideVoteResult(
    uint256 _boxKey,
    uint256 _kilicdar,
    uint256 _muharrem,
    uint256 _rte,
    string memory _url
  ) public isPermissioned(_boxKey) {
    require(
      results[_boxKey][msg.sender].KEMAL_KILICDAROGLU > 0 ||
        results[_boxKey][msg.sender].RECEP_TAYYIP_ERDOGAN > 0,
      "Already added a result"
    );

    CBResult memory newResult;
    newResult.KEMAL_KILICDAROGLU = _kilicdar;
    newResult.MUHARREM_INCE = _muharrem;
    newResult.RECEP_TAYYIP_ERDOGAN = _rte;
    newResult.url = _url;
    results[_boxKey][msg.sender] = newResult;

    emit VoteResultOverriden(
      msg.sender,
      _boxKey,
      _kilicdar,
      _muharrem,
      _rte,
      _url
    );
  }

  // Get Methods

  function getBoxResult(
    address _user,
    uint256 _boxKey
  ) public view returns (CBResult memory) {
    return results[_boxKey][_user];
  }

  function checkAdmin(address _user) public view returns (uint256) {
    return admins[_user];
  }

  function checkUserPermission(
    address _user,
    uint256 _boxKey
  ) public view returns (bool) {
    return permissions[_boxKey][_user];
  }
}