/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-01
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}


// File contracts/NovusDistribution.sol

// NovusDistribution.sol
pragma solidity ^0.8.19;

contract NovusDistribution {
  // Types definitions
  struct NovusAddress {
    uint id;
    string name;
    address theAddress;
  }

  struct WorldAddress {
    uint id;
    string name;
    address theAddress;
  }
  
  struct ProjectAddress {
    uint id;
    string name;
    address theAddress;
  }

  struct DistributionType {
    uint id;
    string name;
  }

  struct Distribution {
    uint sequence;
    string[] names;
    NovusAddress from;
    address[] to;
    uint[] amount;
  }

  // Variables definitions
  address public deployer;
  address[] validNovusAddress;
  address[] admins;
  mapping(address => bool) public isAdmin;
  mapping(address => bool) public isValidNovusAddress;
  mapping(address => NovusAddress) novusAddresses;
  mapping(uint => DistributionType) distributionTypes;
  DistributionType[] distributionTypesList;
  mapping(bytes => DistributionType) _distributionTypes;
  mapping(uint => mapping( uint => Distribution)) public distributions;
  using Counters for Counters.Counter;
  Counters.Counter public DistributionTypeCounter;
  // Constants
  uint public constant PERCENTAGE_SIGNIFICANCE = 10000;

  // contract version info 
  string public version;
  uint public creationDate;

  constructor(string memory _version, uint _creationDate) {
    deployer = msg.sender;
    // Add to novusAddresses (mapping (address => NovusAddress))
    NovusAddress memory _master;
    _master.name = "Owner";
    _master.theAddress = deployer;
    novusAddresses[deployer] = _master;
    // add deployer to list of valid novus addresses
    validNovusAddress.push(deployer);
    // mark as a valid novus address
    isValidNovusAddress[deployer] = true;
    // Mark as an admin
    isAdmin[deployer] = true;
    // Add to admin list
    admins.push(deployer);
    // Contract versioning information
    version = _version;
    creationDate = _creationDate;
  }

  function addNovusAddress(string memory name, address newAddress) public onlyAdmin {
    require(newAddress != address(0), 'New Novus Address must be a valid address');
    require(!isValidNovusAddress[newAddress], 'That Novus address has already been added to the list');
    NovusAddress memory _newNovusAddress;
    _newNovusAddress.name = name;
    _newNovusAddress.theAddress = newAddress;
    // Add to novus addresses list
    novusAddresses[newAddress] = _newNovusAddress;
    // Mark as a valid Novus address
    validNovusAddress.push(newAddress);
    isValidNovusAddress[address(newAddress)] = true;
  }

  function addAdmin(address newAdmin) public onlyAdmin returns (bool){
    require(isValidNovusAddress[address(newAdmin)], 'That is not a valid Novus address');
    require(!isAdmin[address(newAdmin)], 'Address is already an admin');
    admins.push(newAdmin);
    isAdmin[newAdmin] = true;
    return true;
  }

  function removeAdmin(address oldAdmin) public onlyAdmin returns (bool) {
    require(validNovusAddress.length > 1, 'Admins list should have at least 1 admin. You can not remove them');
    require(isAdmin[address(oldAdmin)], 'That wallet is not actually an admin');
    require(oldAdmin != msg.sender, 'You can not remove yourself from the admin list');
    // Remove from the admin mapping
    delete isAdmin[oldAdmin];
    // TBD: Do we want to loop over the admin list to remove some wallet?
    // This is unefficient because it requires a lot of gas.
    // Good point of this is that surely we won't use this function that much.
    for (uint i = 0; i < admins.length; i++) {
      if (admins[i] == oldAdmin) {
        // Move the last element of the admin list to the current index
        // This overrides the old admin with the last element of the admin list
        admins[i] = admins[admins.length - 1]; 
        // Remove the last element of the admin list, at this point is duplicated
        admins.pop();
        return true;
      }
    }
    return false;
  }

  function removeNovusAddress(address oldAddress) public onlyAdmin returns (bool) {
    require(isValidNovusAddress[address(oldAddress)], 'That wallet is not actually a valid Novus address');
    require(oldAddress != msg.sender, 'You can not remove yourself from the Novus addresses list');
    delete isValidNovusAddress[oldAddress];
    delete novusAddresses[address(oldAddress)];
    // Same case as above (See notes on removeAdmin function)
    for (uint i = 0; i < validNovusAddress.length; i++) {
      if (validNovusAddress[i] == address(oldAddress)) {
        validNovusAddress[i] = validNovusAddress[validNovusAddress.length - 1];
        validNovusAddress.pop();
        return true;
      }
    }
    return false;
  }

  function addDistributionType(string memory name) public onlyAdmin returns (uint) {
    require(_distributionTypes[bytes(name)].id == 0, 'You can not add an existing distribution type');
    DistributionType memory _distributionType;
    DistributionTypeCounter.increment();
    uint newId = DistributionTypeCounter.current();
    _distributionType.id = newId;
    _distributionType.name = name;
    distributionTypes[newId] = _distributionType;
    _distributionTypes[bytes(name)] = _distributionType;
    distributionTypesList.push(_distributionType);
    return newId;
  }

  function getDistributionTypeById (uint id) public view returns (DistributionType memory) {
    return distributionTypes[id];
  }

  function getDistributionTypeByName (string memory name) public view returns (DistributionType memory) {
    return _distributionTypes[bytes(name)];
  }

  function getAllDistributionTypes () public view returns (DistributionType[] memory) {
    return distributionTypesList;
  }
  
  function setDistribution(
    uint distributionTypeId
    ,uint sequence
    ,string[] memory names
    ,uint[] memory amount
    ,address from // Must be a valid novus address
    ,address[] memory to  // Must be valid novus addresses
  ) public onlyAdmin returns (Distribution memory) {
    require(distributionTypes[distributionTypeId].id != 0, 'Distribution type doesn\'t exist');
    
    uint totalAmount = 0;
    for (uint i = 0; i < amount.length; i++) {
      require(amount[i] > 0 && amount[i] <= PERCENTAGE_SIGNIFICANCE, 'Distribution amount should not be greater than zero and less than PERCENTAGE_SIGNIFICANCE');
      totalAmount += amount[i];
    }
    require(totalAmount == PERCENTAGE_SIGNIFICANCE, 'Distribution amount for any sequence should sum 100%. Please check PERCENTAGE_SIGNIFICANCE used in this contract');
    for (uint i = 0; i < to.length; i++) {
      require (isValidNovusAddress[to[i]], 'Invalid Novus Address provided within "address[] to" parameter');
    }
    Distribution memory distribution;
    distribution.from = novusAddresses[from];
    distribution.sequence = sequence;
    distribution.names = names;
    distribution.amount = amount;
    distribution.to = to;
    distributions[distributionTypeId][sequence] = distribution;
    return distribution;
  }

  function mintNOVO(address to, uint amount) public view returns (bool) {

  }

  function distributeNOVO(uint distributionTypeId, uint amount) public view returns (bool) {

  }

  // Access modifiers
  modifier onlyDeployer {
    require(msg.sender == deployer, 'Only deployer is allowed to perform this operation');
    _;
  }

  modifier onlyAdmin {
    require(isAdmin[msg.sender] || msg.sender == deployer, 'Only admins are allowed to perform this operation');
    _;
  }

  // Events
}