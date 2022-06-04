// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/*
      ______      _____            _   _ _____   ____  _      ______ 
     |  ____/\   |  __ \     /\   | \ | |  __ \ / __ \| |    |  ____|
     | |__ /  \  | |__) |   /  \  |  \| | |  | | |  | | |    | |__   
     |  __/ /\ \ |  _  /   / /\ \ | . ` | |  | | |  | | |    |  __|  
     | | / ____ \| | \ \  / ____ \| |\  | |__| | |__| | |____| |____ 
     |_|/_/    \_\_|  \_\/_/    \_\_| \_|_____/ \____/|______|______|
*/ 

import "@openzeppelin/contracts/utils/Context.sol";

abstract contract ISuperAdmin {
    function hasRole(bytes32 role, address account) public view virtual returns (bool);
    function name() external pure virtual returns (string memory); 
}

contract SuperAdminAddress is Context {

    event AddressChanged(address oldSuperAdminAddress, address newSuperAdminAddress);

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    address private _superAdminContract;

    constructor(address superAdminAddress) {
        _checkName(superAdminAddress);
        _superAdminContract = superAdminAddress;
        emit AddressChanged(address(0), superAdminAddress);
    }

    // Only admin of current SuperAdmin contract can change the address
    function setAddress(address newSuperAdminAddress)
    external {
        // check it is the right kind of contract
        _checkName(newSuperAdminAddress);
        // check the sender is the admin of current SuperAdmin contract
        require( ISuperAdmin(_superAdminContract).hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), 'sender is not admin of current SuperAdmin');
        address oldSuperAdminAddress = _superAdminContract;
        _superAdminContract = newSuperAdminAddress;
        emit AddressChanged(oldSuperAdminAddress, newSuperAdminAddress);
    }

    function getAddress()
    external view returns (address) {
        return _superAdminContract;
    }    
    
    // for safety, check the new address is the right kind of contract
    function _checkName(address superAdminAddress)
    internal pure {
        require(keccak256(bytes(ISuperAdmin(superAdminAddress).name())) == keccak256(bytes('Farandole SuperAdmin')), 'Trying to set the wrong contract address');       
    }

    // This function is used for safety purpose when we add the address of this contract somewhere
    function name()
    external pure returns (string memory) {
        return 'Farandole SuperAdminAddress';
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