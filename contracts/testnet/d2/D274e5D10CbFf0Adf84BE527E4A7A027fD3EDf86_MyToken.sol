// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./AccessControl.sol";
import "./ERC20.sol";

contract MyToken is ERC20, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor()  ERC20("MyToken5", "TKN5") {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _mint(msg.sender,1000*(10**18));
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public {
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _burn(from, amount);
    }
}