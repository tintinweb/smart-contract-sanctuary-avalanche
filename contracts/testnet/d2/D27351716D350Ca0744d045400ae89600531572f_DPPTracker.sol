/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Contract DPP 

contract DPPTracker {

        struct DPP {
        string name;
        string definition;
        address[] ingredients;
        address[] shipmentAddresses;
    }

    DPP public myDpp;
    address private owner;

    constructor(string memory _name, string memory _definition, address[] memory _ingredients, address[] memory _shipmentAddresses) {

        for (uint i = 0; i < _ingredients.length; i++) {
            bool toggle = false;

            DPPTracker ingredientContract = DPPTracker(_ingredients[i]);
            DPPTracker.DPP memory dpp = ingredientContract.getDpp();

            for (uint j = 0; j < dpp.shipmentAddresses.length; j++) {

                if(dpp.shipmentAddresses[j] == msg.sender){
                    toggle = true;
                    break;
                }
            }

            require(toggle, "Invalid contract address.");

        }

        myDpp.name = _name;
        myDpp.definition = _definition;
        myDpp.ingredients = _ingredients;
        myDpp.shipmentAddresses = _shipmentAddresses;
        owner = msg.sender;
    } 


    function AddToShipment(address  _walletAddress) public onlyOwner{
        myDpp.shipmentAddresses.push(_walletAddress);
    } 

    function getDpp() public view returns (DPP memory) {
        return myDpp ;
    }


        modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }

}