/**
 *Submitted for verification at testnet.snowtrace.io on 2023-03-02
*/

// Sources flattened with hardhat v2.12.2 https://hardhat.org

// File @openzeppelin/contracts/security/[email protected]

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/utils/[email protected]
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


contract NovusDistribution is ReentrancyGuard{
  // Using counters
  using Counters for Counters.Counter;
  // Types definitions
  struct NovusAddress {
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
    uint distributionTypeId;
    uint sequence;
    NovusAddress from;
    // Addresess information
    uint total;
    string[] names;
    address[] to;
    uint[] amount;
  }

  // distributionTypeId => sequence => address => amount
  mapping(uint => mapping(uint => mapping(address => uint))) distributionsAmountMapping;

  // Variables definitions
  address public deployer;
  address[] validNovusAddress;
  address[] admins;
  mapping(address => bool) public isAdmin;
  mapping(address => bool) public isValidNovusAddress;
  mapping(address => NovusAddress) novusAddresses;
  mapping(address => bool) isDistributionAddress;
  mapping(uint => DistributionType) distributionTypes;
  DistributionType[] distributionTypesList;
  mapping(bytes => DistributionType) _distributionTypes;
  // id=>sequence=>Distribution
  mapping(uint => mapping( uint => Distribution)) public distributions; 
  Counters.Counter public DistributionTypeCounter;
  mapping (uint => uint) public distributionBalance;
  // Constants
  uint public constant PERCENTAGE_SIGNIFICANCE = 10000;

  // contract version info 
  string public version;
  uint public creationDate;

  constructor(string memory _version, uint _creationDate) {
    deployer = msg.sender;
    // Add to novusAddresses (mapping (address => NovusAddress))
    addNovusAddress("Owner", deployer);
    addAdmin(deployer);
    version = _version;
    creationDate = _creationDate;
  }

  function deposit() public payable {}

  function addNovusAddress(string memory name, address newAddress) 
  public onlyAdmin onlyvalidAddress(newAddress)
  {
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

  function addAdmin(address newAdmin) 
  public onlyAdmin onlyValidNovusAddresses(newAdmin)
  returns (bool){
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

  function removeNovusAddress(address oldAddress) public 
  onlyAdmin onlyValidNovusAddresses(oldAddress)
  returns (bool) {
    require(oldAddress != msg.sender, 'You can not remove yourself from the Novus addresses list');
    require(!isAdmin[oldAddress], "Fist remove that address from the admin list");
    require(!isDistributionAddress[oldAddress], "You can not remove a distribution address");
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

  function addDistributionType(string memory name) 
  public onlyAdmin returns (uint) 
  {
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

  function addToDistributionBalance(uint distributionTypeId, uint amount) 
  public onlyAdmin onlyValidDistributionTypes(distributionTypeId) 
  {
    distributionBalance[distributionTypeId] += amount;
  }
  
  function setDistribution(
    uint distributionTypeId
    ,uint sequence
    ,string[] memory names
    ,uint[] memory amount
    ,address from // Must be a valid novus address
    ,address[] memory to  // Must be valid novus addresses
  ) public onlyAdmin onlyValidDistributionTypes(distributionTypeId)
    returns (Distribution memory)
  {
    require(isValidNovusAddress[address(from)], '"address from" parameter is not a valid novus address');
    require(
      names.length != 0 && amount.length != 0 && to.length != 0, 
      'Names, amounts and destination addresses should not be empty arrays'
    );
    require(
      names.length == amount.length && amount.length == to.length, 
      'Names, amounts and destination addresses should have the same length'
    );
    uint totalAmount = 0;
    for (uint i = 0; i < amount.length; i++) {
      require (isValidNovusAddress[to[i]], 'Invalid Novus Address provided within "address[] to" parameter');
      isDistributionAddress[to[i]] = true;
      require( amount[i] > 0 && amount[i] <= PERCENTAGE_SIGNIFICANCE, 'Distribution amount should be greater than zero and less than PERCENTAGE_SIGNIFICANCE');
      totalAmount += amount[i];
      distributionsAmountMapping[distributionTypeId][sequence][to[i]] = amount[i];
    }
    require(totalAmount == PERCENTAGE_SIGNIFICANCE, 'Distribution amount for any sequence should sum 100%. Please check PERCENTAGE_SIGNIFICANCE used in this contract');
    Distribution memory distribution;
    distribution.distributionTypeId = distributionTypeId;
    distribution.from = novusAddresses[from];
    distribution.sequence = sequence;
    // Addresses info
    distribution.total = to.length;
    distribution.names = names;
    distribution.amount = amount;
    distribution.to = to;
    distributions[distributionTypeId][sequence] = distribution;
    return distribution;
  }

  function _transferTo(address to, uint amount) private onlyAdmin returns (bool, bytes memory) {
    require(amount > 0, 'Invalid amount');
    require(address(this).balance >= amount, "There's not enough NOVO to transfer");
    (bool sent, bytes memory data) = to.call{value: amount}("");
    require(sent, "Failed to send Ether");
    return (sent, data);
  }

  function mintNOVO(address to, uint amount) 
  public onlyAdmin
  returns (bool, bytes memory) {
    (bool sent, bytes memory data) = _transferTo(address(to), amount);
    return (sent, data);
  }

  function distributeNOVOInSequence(uint distributionTypeId, uint sequence) 
  private onlyValidDistributionTypes(distributionTypeId) {
    uint _type_amount = distributionBalance[distributionTypeId];
    require(_type_amount > 0, "There\'s no pending balance to distribute");
    Distribution memory dist = distributions[distributionTypeId][sequence];
    uint novo_amount;
    for (uint i = 0; i < dist.total; i++) {
      address to_address = dist.to[i];
      bool sent;
      bytes memory data;
      if (sequence == 1) {
        Distribution memory DistOnNextSequence = distributions[distributionTypeId][sequence + 1];
        if (to_address == DistOnNextSequence.from.theAddress) {
          continue;
        }
        novo_amount =  (_type_amount * dist.amount[i]) / PERCENTAGE_SIGNIFICANCE;

      } else if (sequence == 2) {
        uint previous_sequence_amount = distributionsAmountMapping[distributionTypeId][sequence - 1][dist.from.theAddress];
        novo_amount = (_type_amount * dist.amount[i] * previous_sequence_amount) / (PERCENTAGE_SIGNIFICANCE * PERCENTAGE_SIGNIFICANCE);
      }
      (sent, data) = _transferTo(to_address, novo_amount);
      require(sent);
    }
  }

  function distributeNOVO(uint distributionTypeId) 
  public onlyAdmin onlyValidDistributionTypes(distributionTypeId) {
    distributeNOVOInSequence(distributionTypeId, 1);
    distributeNOVOInSequence(distributionTypeId, 2);
    distributionBalance[distributionTypeId] = 0;
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

  modifier onlyValidDistributionTypes(uint distributionTypeId) {
    require(distributionTypes[distributionTypeId].id != 0, "Distribution type doesn\'t exist"); 
    _;
  }

  modifier onlyValidNovusAddresses(address someAddress) {
    require(isValidNovusAddress[address(someAddress)], 'That wallet is not actually a valid Novus address');
    _;
  }

  modifier onlyvalidAddress(address someAddress) {
    require(someAddress != address(0), 'Novus Address must be a valid address');
    _;
  }

  // Events
}