/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DPPTracker {
    struct DPP {
        string name;
        string definition;
        address[] ingredients;
        address[] shipmentAddresses;
    }

    DPP public myDpp;
    address private owner;

    constructor(
        string memory _name,
        string memory _definition,
        address[] memory _ingredients,
        address[] memory _shipmentAddresses
    ) {

        require(_ingredients.length <= 500, "Exceeded maximum number of ingredients.");
        require(_shipmentAddresses.length <= 500, "Exceeded maximum number of shipment addresses.");
        
        for (uint256 i = 0; i < _ingredients.length; i++) {
            bool toggle = false;

            DPPTracker ingredientContract = DPPTracker(_ingredients[i]);
            (string memory name, string memory definition, address[] memory ingredientAddrs, address[] memory shipmentAddrs) = ingredientContract.getDpp();

            for (uint256 j = 0; j < shipmentAddrs.length; j++) {
                if (shipmentAddrs[j] == msg.sender) {
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

    function AddToShipment(address _walletAddress) public onlyOwner {
        myDpp.shipmentAddresses.push(_walletAddress);
    }

    function getDpp() public view returns (
        string memory name,
        string memory definition,
        address[] memory ingredients,
        address[] memory shipmentAddresses
    ) {
        return (
            myDpp.name,
            myDpp.definition,
            myDpp.ingredients,
            myDpp.shipmentAddresses
        );
    }

       function addressToString(address _address) internal pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(_address)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = "0";
        str[1] = "x";
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }
    function getShipments() public view returns (string memory) {
        string memory result = '{ "shipmentAddresses": [';
        for (uint256 i = 0; i < myDpp.shipmentAddresses.length; i++) {
            result = string(
                abi.encodePacked(
                    result,
                    i > 0 ? "," : "",
                    '"',
                    addressToString(myDpp.shipmentAddresses[i]),
                    '"'
                )
            );
        }
        result = string(abi.encodePacked(result, "] }"));
        return result;
    }

    function getIngredients() public view returns (string memory) {
        string memory result = '{ "ingredients": [';
        for (uint256 i = 0; i < myDpp.ingredients.length; i++) {
            result = string(
                abi.encodePacked(
                    result,
                    i > 0 ? "," : "",
                    '"',
                    addressToString(myDpp.ingredients[i]),
                    '"'
                )
            );
        }
        result = string(abi.encodePacked(result, "] }"));
        return result;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function.");
        _;
    }
}