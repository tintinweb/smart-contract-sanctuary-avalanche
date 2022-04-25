// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./w-ERC20.sol";
import "./Ownable.sol";

contract Scepter is ERC20, Ownable {

    // a mapping from an address to whether or not it can mint / burn
    mapping(address => bool) controllers;


    constructor() ERC20("Wand-Scepter", "SPTR") {
        
    }

    /**
     * mints $Scepter to a recipient
     * @param to the recipient of the $Scepter
     * @param amount the amount of $Scepter to mint
     TODO: Each time a call is sent to mint $Scepter, the same call is sent to mint $Wand
  
    function mint(address to, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can mint");
        _mint(to, amount);
    } */

    /**

     * @param from the holder of the $Scepter
   * @param amount the amount of $Scepter to burn

  
    function burn(address from, uint256 amount) external {
        require(controllers[msg.sender], "Only controllers can burn");
        _burn(from, amount);
    } */

    /**
     * enables an address to mint / burn
     * @param controller the address to enable
   */
    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
        _setApprovedTokenTransferor(controller);
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
   */
    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }


    
           
}