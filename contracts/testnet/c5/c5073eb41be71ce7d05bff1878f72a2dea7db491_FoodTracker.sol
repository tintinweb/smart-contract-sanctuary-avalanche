// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.13;

// Errors
////////////////////////////////////////////////////////////////////////////////
error InvalidRole();
error InvalidState();
error NotOwner();
error NotCompanyOwner();

// Structs
////////////////////////////////////////////////////////////////////////////////

enum PlantState {
  None,
  FieldAnalysisDone,
  Planted,
  HarvestAnalysisDone,
  Harvested
}

enum TransportState {
  None,
  Loaded,
  ReceiveWarehouseArrived,
  Packaged,
  MainWarehouseArrived,
  Purchased
}

struct FieldAnalysisInfo {
  uint48 timestamp;
  string analysisLink;
}

struct PlantInfo {
  uint48 timestamp;
  uint256 seedNumber;
  string photoLink;
}

struct HarvestAnalysisInfo {
  uint48 timestamp;
  string analysisLink;
}

struct HarvestInfo {
  uint48 timestamp;
  uint208 crateCount;
  string photoLink;
}

struct LoadInfo {
  uint48 timestamp;
  string photoLink;
}

struct ReceiveWarehouseArriveInfo {
  uint48 timestamp;
  string photoLink;
}

struct PackageInfo {
  uint48 timestamp;
  string photoLink;
}

struct MainWarehouseArriveInfo {
  uint48 timestamp;
  string photoLink;
}

struct PurchaseInfo {
  uint48 timestamp;
}

struct LandInfo {
  string landName;
  string landlordName;
  string farmerName;
}

struct ProductPlantInfo {
  LandInfo landInfo;
  PlantState state;
  FieldAnalysisInfo fieldAnalysisInfo;
  PlantInfo plantInfo;
  HarvestAnalysisInfo harvestAnalysisInfo;
  HarvestInfo harvestInfo;
}

struct ProductTransportInfo {
  uint256 plantRecord;
  TransportState state;
  LoadInfo loadInfo;
  ReceiveWarehouseArriveInfo whReceiveInfo;
  PackageInfo packageInfo;
  MainWarehouseArriveInfo mainWhReceiveInfo;
  PurchaseInfo purchaseInfo;
}

// Roles
////////////////////////////////////////////////////////////////////////////////
abstract contract Roles {
  event RoleAdded(bytes32 indexed roleId, address indexed account);
  event RoleRemoved(bytes32 indexed roleId, address indexed account);

  mapping(address => mapping(bytes32 => bool)) internal _roles;

  modifier onlyRole(string memory role) {
    bytes32 roleHash = keccak256(abi.encode(role));
    if (!_roles[msg.sender][roleHash]) revert InvalidRole();
    _;
  }

  /// @param account:
  /// @param role: String repr of the role
  /// @dev @emits RoleAdded
  function _setRole(address account, string memory role) internal {
    bytes32 roleHash = keccak256(abi.encode(role));
    _roles[account][roleHash] = true;

    emit RoleAdded(roleHash, account);
  }

  /// @param account:
  /// @param role:
  /// @dev @emits RoleRemoved
  function _unsetRole(address account, string memory role) internal {
    bytes32 roleHash = keccak256(abi.encode(role));
    _roles[account][roleHash] = false;

    emit RoleRemoved(roleHash, account);
  }
}

// Ownable
////////////////////////////////////////////////////////////////////////////////
abstract contract Ownable {
  event OwnershipTransferred(address indexed from, address indexed to);

  address internal _owner;

  constructor() {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), msg.sender);
  }

  modifier onlyOwner() {
    if (msg.sender != _owner) revert NotOwner();
    _;
  }

  function _setOwner(address newOwner) internal onlyOwner {
    _owner = newOwner;
    emit OwnershipTransferred(msg.sender, newOwner);
  }

  function _revokeOwnership() internal onlyOwner {
    delete _owner;
    emit OwnershipTransferred(msg.sender, address(0));
  }
}

// Food Tracker
////////////////////////////////////////////////////////////////////////////////
contract FoodTracker is Ownable, Roles {
  event RecordAdded(uint256 recordId);

  uint256 private _recordNonce = 0;
  uint256 private _crateNonce = 0;

  mapping(uint256 => ProductPlantInfo) public plantInfos;
  mapping(uint256 => ProductTransportInfo) public transportInfos;

  function setManager(address account) external onlyOwner {
    _setRole(account, "MANAGER");
  }

  function unsetManager(address account) external onlyOwner {
    _unsetRole(account, "MANAGER");
  }

  function setOwner(address newOwner) external onlyOwner {
    _setOwner(newOwner);
  }

  function totalRecords() external view returns(uint256) {
    return _recordNonce;
  }

  function totalCrates() external view returns(uint256) {
    return _crateNonce;
  }

  /// @param landName: Name/Description of the land
  /// @param landlordName: Name of the landlord 
  /// @dev @emits RecordAdded
  function insertRecord(string calldata landName, string calldata landlordName)
    external
    onlyRole("MANAGER")
  {

    emit RecordAdded(_recordNonce);

    plantInfos[_recordNonce].landInfo = LandInfo(landName, landlordName, "");
    _recordNonce++;
  }

  function fieldAnalysisDone(uint256 recordId, FieldAnalysisInfo calldata info)
    external
    onlyRole("MANAGER")
  {
    if (plantInfos[recordId].state != PlantState.None) revert InvalidState();

    plantInfos[recordId].fieldAnalysisInfo = info;
    plantInfos[recordId].state = PlantState.FieldAnalysisDone;
  }

  function productPlanted(uint256 recordId, PlantInfo calldata info)
    external
    onlyRole("MANAGER")
  {
    if (plantInfos[recordId].state != PlantState.FieldAnalysisDone)
      revert InvalidState();
    
    plantInfos[recordId].plantInfo = info;
    plantInfos[recordId].state = PlantState.Planted;
  }

  function harvestAnalysisDone(uint256 recordId, HarvestAnalysisInfo calldata info)
    external
    onlyRole("MANAGER")
  {
    if (plantInfos[recordId].state != PlantState.Planted)
      revert InvalidState();
    
    plantInfos[recordId].harvestAnalysisInfo = info;
    plantInfos[recordId].state = PlantState.HarvestAnalysisDone;
  }

  function productHarvested(
    uint256 recordId,
    HarvestInfo calldata info)
    external
    onlyRole("MANAGER")
  {
    if (plantInfos[recordId].state != PlantState.HarvestAnalysisDone)
      revert InvalidState();
    
    plantInfos[recordId].harvestInfo = info;
    plantInfos[recordId].state = PlantState.Harvested;

    for(uint256 i = 0; i < info.crateCount; i++)
    {
      transportInfos[_crateNonce + i].plantRecord = recordId;
    }
    _crateNonce += info.crateCount;
  }
  
  function productLoaded(uint256 crateId, LoadInfo calldata info)
    external
    onlyRole("MANAGER")
  {
    uint256 plantRecord = transportInfos[crateId].plantRecord;
    if (plantInfos[plantRecord].state != PlantState.Harvested)
      revert InvalidState();

    transportInfos[crateId].loadInfo = info;
    transportInfos[crateId].state = TransportState.Loaded;
  }

  function receiveWarehouseArrived(
    uint256 crateId, 
    ReceiveWarehouseArriveInfo calldata info)
    external
    onlyRole("MANAGER")
  {
    if (transportInfos[crateId].state != TransportState.Loaded)
      revert InvalidState();

    transportInfos[crateId].whReceiveInfo = info;
    transportInfos[crateId].state = TransportState.ReceiveWarehouseArrived;
  }

  function productPackaged(uint256 crateId, PackageInfo calldata info)
    external
    onlyRole("MANAGER")
  {
    if (transportInfos[crateId].state != TransportState.ReceiveWarehouseArrived)
      revert InvalidState();

    transportInfos[crateId].packageInfo = info;
    transportInfos[crateId].state = TransportState.Packaged;
  }

  function mainWarehouseArrived(
    uint256 crateId,
    MainWarehouseArriveInfo calldata info)
    external
    onlyRole("MANAGER")
  {
    if(transportInfos[crateId].state != TransportState.Packaged)
      revert InvalidState();
    
    transportInfos[crateId].mainWhReceiveInfo = info;
    transportInfos[crateId].state = TransportState.MainWarehouseArrived;
  }

  function productPurchased(uint256 crateId, PurchaseInfo calldata info)
    external
    onlyRole("MANAGER")
  {
    if(transportInfos[crateId].state != TransportState.Packaged)
      revert InvalidState();
    
    transportInfos[crateId].purchaseInfo = info;
    transportInfos[crateId].state = TransportState.Purchased;
  }
}