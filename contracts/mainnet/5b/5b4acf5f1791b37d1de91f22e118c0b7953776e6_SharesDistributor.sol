/**
 *Submitted for verification at snowtrace.io on 2022-02-11
*/

// SPDX-License-Identifier: Apache-2.0

pragma solidity ^0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Administrable {

    mapping (address => bool) public admins;

    address public owner;

    modifier onlyAdmin {
        require(admins[msg.sender], "Administrable: caller is not an admin");
        _;
    }

    modifier onlyOwner {
        require(owner == msg.sender, "Administrable: caller is not the deployer");
        _;
    }

    constructor() {
        admins[msg.sender] = true;
        owner = msg.sender;
    }

    function addAdmin(address admin) external onlyOwner {
        admins[admin] = true;
    }

    function removeAdmin(address admin) external onlyOwner {
        delete admins[admin];
    }

}

contract SharesDistributor is Administrable {

    struct Allocation {
        address account;
        uint256 points;
    }

    IERC20 public Share;
    Allocation[] public allocations;
    uint256 public totalPoints = 0;

    constructor(address[] memory accounts, uint256[] memory points) {
        Share = IERC20(0x155dBbB7CE079f7b8EcfFf9688AdF6e6efb69a24);
        for (uint256 a = 0; a < accounts.length; a ++) {
            allocations.push(Allocation({
                account: accounts[a],
                points: points[a]
            }));
            totalPoints += points[a];
        }
    }
  
    function distribute() external onlyAdmin {
        uint256 balance = Share.balanceOf(address(this));
        for (uint256 a = 0; a < allocations.length; a ++) {
            Share.transfer(allocations[a].account, balance * allocations[a].points / totalPoints);
        }
    }

    function setShare(address share) external onlyOwner {
        Share = IERC20(share);
    }

    function addAllocation(address account, uint256 points) external onlyOwner {
        allocations.push(Allocation({
            account: account,
            points: points
        }));
        totalPoints += points;
    }

    function removeAllocation(address account) external onlyOwner {
        for (uint256 a = 0; a < allocations.length; a ++) {
            if (allocations[a].account == account) {
                totalPoints -= allocations[a].points;
                allocations[a] = allocations[allocations.length - 1];
                allocations.pop();
                break;
            }
        }
    }

    function setAllocationPoints(address account, uint256 points) external onlyOwner {
        for (uint256 a = 0; a < allocations.length; a ++) {
            if (allocations[a].account == account) {
                totalPoints = totalPoints - allocations[a].points + points;
                allocations[a].points = points;
            }
        }
    }

    function call(address payable _to, uint256 _value, bytes calldata _data) external payable onlyOwner returns (bytes memory) {
        (bool success, bytes memory result) = _to.call{value: _value}(_data);
        require(success, "external call failed");
        return result;
    }

}