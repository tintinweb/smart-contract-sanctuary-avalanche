// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

/// @author Memepanze
/// @notice Contract for the Plague Game developped on Unity.
contract Plague is Ownable {

    /// @notice Minimum number of potions to be checked when cook() is called
    uint public minimumPotions;

    /// @notice The number of medicine for each address
    mapping(address => uint) public medicine;

    /// @notice Emitted on cook() when the function is called
    event NewMedicine(string _msg);

    /// @notice Revert cook() if not enough cooked potions
    error Plague__NotEnoughCookedPotions();

    constructor(uint _numberMinimumOfPotions){
        minimumPotions = _numberMinimumOfPotions;
    }

    /// @notice initialize the session
    function startGame() external {
        medicine[msg.sender] = 0;
    }

    /// @notice If the number of Potions cooked is equal to 4, a player get one medicine
    function cook(uint _numberOfPotions) external {
        if(_numberOfPotions >= minimumPotions){
            medicine[msg.sender]++;
            emit NewMedicine("New Medicine!");
        } else {
            revert Plague__NotEnoughCookedPotions();
        }
    }

    /// @notice Owner of the contract sets the minimum number of potions required to trigger cook.
    /// @param _number The number of minimum potions to set
    function setMinimumOfPotions(uint _number) external onlyOwner {
        minimumPotions = _number;
    }
}