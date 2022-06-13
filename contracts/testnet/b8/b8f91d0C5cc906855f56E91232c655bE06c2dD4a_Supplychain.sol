/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-12
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0;

contract Supplychain {
  address owner;

  uint256 unit_id = 0;
  uint256 worker_id = 0;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  struct Unit {
    string GLN; // Global Location NUmber (7-9digit)
    string GTIN; /// Global Trade Item Number
    string GSIN; /// Global Shipment Identification Number
    string SSCC; /// Serial Shipping Container Code
    string SN; /// Serial Number
    // extra data
    string name;
    string data;
    uint256 worker_id;
    uint256 id;
    uint256 timestamp;
  }

  struct Worker {
    uint256 id;
    string name;
  }

  mapping(uint256 => Unit) public units;
  mapping(uint256 => Worker) public workers;

  mapping(string => mapping(string => Unit[])) public particularunit;

  Unit public UnitInfo;
  Worker public WorkerInfo;
  Worker[] public workers_list;

  Unit[] public units_list;

  function addUnitInfo(
    string memory GLN,
    string memory GTIN,
    string memory GSIN,
    string memory SSCC,
    string memory SN,
    string memory name,
    string memory data,
    uint256 w_id
    
  ) public {
    UnitInfo = Unit(GLN, GTIN, GSIN, SSCC, SN, name, data, w_id, unit_id, block.timestamp);

    units[unit_id] = UnitInfo;
    particularunit[GTIN][SN].push(UnitInfo);
    units_list.push(UnitInfo);
    unit_id++;
  }

  function get_unit(uint256 id) public view returns (Unit memory) {
    return units[id];
  }

  function historyAll() public view returns (Unit[] memory) {
    return units_list;
  }

  function history(string memory GTIN, string memory SN) public view returns (Unit[] memory) {
    return particularunit[GTIN][SN];
  }

  function Addworker(string memory name) public onlyOwner {
    WorkerInfo = Worker(worker_id, name);
    workers_list.push(WorkerInfo);
    workers[worker_id] = WorkerInfo;
    worker_id++;
  }

  function workersInfo() public view returns (Worker[] memory) {
    return workers_list;
  }


}