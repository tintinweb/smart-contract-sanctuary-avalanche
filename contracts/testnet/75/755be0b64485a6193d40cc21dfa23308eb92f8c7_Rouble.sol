//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./ERC20.sol";
import "./Ownable.sol";

contract Rouble is Ownable, ERC20 {

    constructor() ERC20("Rouble", "RBL") { }

    // SECTION MAPPINGS  _______________________________________________________________________________________________

    mapping(address => bool) controllers;

    //!SECTION MAPPINGS  -----------------------------------------------------------------------------------------------

    // SECTION VIEW FUNCTIONS __________________________________________________________________________________________

    function isController(address _address) external view returns (bool){
        if (controllers[_address]){return true;}
        else {return false;}
    }
    //!SECTION VIEW FUNCTIONS ------------------------------------------------------------------------------------------

    // SECTION EXTERNAL FUNCTIONS ______________________________________________________________________________________

    function addController(address controller) external onlyOwner {
        controllers[controller] = true;
    }

    function removeController(address controller) external onlyOwner {
        controllers[controller] = false;
    }

    function mint(address to, uint amount) external {
        require(controllers[msg.sender],"Only controllers can execute this function!!");
        _mint(to, amount);
    }

    function burn (address account, uint amount) external {
        require(controllers[msg.sender],"Only controllers can execute this function!!");
        _burn(account, amount);
    }

    //!SECTION EXTERNAL FUNCTIONS --------------------------------------------------------------------------------------

}