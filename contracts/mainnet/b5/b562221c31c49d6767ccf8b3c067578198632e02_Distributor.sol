// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

interface PTP {
   function transfer(address dst, uint256 rawAmount) external returns (bool);
   function balanceOf(address account) external view returns (uint256);
   function mint(address dst, uint256 rawAmount) external;
   function minimumTimeBetweenMints() external view returns (uint256);
}


contract Distributor is Ownable{
    mapping(address => uint256) public withdrawn;
    mapping(address => uint256) public allocations;
    uint256 totalPTPWithdrawn;
    PTP public PTPContract = PTP(0x22d4002028f537599bE9f666d1c4Fa138522f9c8);

    error Unauthorized();

    constructor(address[5] memory _beneficiaries)
    {
        allocations[_beneficiaries[0]] = 36363;
        allocations[_beneficiaries[1]] = 36363;
        allocations[_beneficiaries[2]] = 10909;
        allocations[_beneficiaries[3]] = 10909;
        allocations[_beneficiaries[4]] = 5456;
    }

    function changeBeneficiary (address _newBeneficiary) external {
        if ( allocations[msg.sender] == 0 ) { revert Unauthorized();}
        uint256 allocation = allocations[msg.sender];
        uint256 withdrawnBalance = withdrawn[msg.sender];

        allocations[_newBeneficiary] = allocation;
        withdrawn[_newBeneficiary] = withdrawnBalance;

        delete allocations[msg.sender];
        delete withdrawn[msg.sender];
    }

    function withdrawBeneficiary() external {
        uint256 ptpBalance = PTPContract.balanceOf(address(this));
        uint256 totalPTPBalance = totalPTPWithdrawn + ptpBalance ;
        uint256 withdrawable = ((totalPTPBalance * allocations[msg.sender]) / 100000) - withdrawn[msg.sender];
        withdrawn[msg.sender] += withdrawable;
        totalPTPWithdrawn += withdrawable;
        PTPContract.transfer(msg.sender,withdrawable);
    }

    function withdrawEmergency() external onlyOwner {
        uint256 ptpBalance = PTPContract.balanceOf(address(this));
        PTPContract.transfer(msg.sender,ptpBalance);
    }

    function claimable(address _beneficiary) view external returns (uint256) {
        uint256 ptpBalance = PTPContract.balanceOf(address(this));
        uint256 totalPTPBalance = totalPTPWithdrawn + ptpBalance ;
        return (((totalPTPBalance * allocations[_beneficiary]) / 100000) - withdrawn[_beneficiary]);
    } 
}