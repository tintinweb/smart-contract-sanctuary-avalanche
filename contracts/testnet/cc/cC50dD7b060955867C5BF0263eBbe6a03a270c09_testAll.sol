//SPDX-Licence-Identifier:unlicense
pragma solidity ^0.8.4;
contract testAll{
    bool public boolIt = true;
    string public stringIt = "hi";
    uint256 public uint256It = 1*10^18;
    uint8 public uint8It = 1*10^8;
    address public addressIt = 0x0000000000000000000000000000000000000000;
    function changeBoolIt(bool newBool) public returns (bool) {
        boolIt = newBool;
    }
    function changeUint256It(uint256 uinteight) public returns(uint256){
        uint256It = uinteight;
    } 
    function changeUint8It(uint8 uinteight) public returns(uint8) {
        uint8It = uinteight;
    } 
    function updateAddressIt(address newToken) public returns(address){
        addressIt = newToken;
    }
    function updateStringIt(string memory newStr) public returns(string memory){
        stringIt = newStr;
    }
    function changeBoolItEXT(bool newBool) external returns (bool) {
        boolIt = newBool;
    }
    function changeUint256ItEXT(uint256 uinteight) external returns(uint256){
        uint256It = uinteight;
    } 
    function changeUint8ItEXT(uint8 uinteight) external returns(uint8){
        uint8It = uinteight;
    } 
    function updateAddressItEXT(address newToken) external returns(address){
        addressIt = newToken;
    }
    function updateStringItEXT(string memory newStr) external returns(string memory){
        stringIt = newStr;
    }
}