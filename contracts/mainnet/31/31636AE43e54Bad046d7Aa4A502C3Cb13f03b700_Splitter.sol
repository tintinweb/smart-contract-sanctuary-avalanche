/**
 *Submitted for verification at snowtrace.io on 2022-03-22
*/

// File: Splitter.sol

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract Splitter {
    address public address1 = 0x7C5249Bd963f0fF8B74185f404F9D1f6DAB6da97; // 0.225 
    address public address2 = 0x10062FA66405279440149554841C85E7Ef0dd45F; // 0.225
    address public address3 = 0xA7342DA95c913E8B3EA22e3940ddbD6Dc4f4d54b; // 0.05
    address public address4 = 0xA3Ea4Adb969967D98501b5D36496119EFAf79228; // 0.07
    address public address5 = 0x2c9aB6A3d672A31c02A3DAa2C59F349ddde7a04c; // 0.025
    address public address6 = 0x39E204f46655fF8b5B780B5fe53eF5A14b8a81a6; // 0.025
    address public address7 = 0x3c959D2e047a32e938D1f31d5f79b37205E90d96; // 0.380

    receive() external payable {}
    function split(uint256 value) external payable {
        uint256 oneMilli = value * 100 / 100000;
        payable(address1).transfer(oneMilli * 225);
        payable(address2).transfer(oneMilli * 225);
        payable(address3).transfer(oneMilli * 50);
        payable(address4).transfer(oneMilli * 70);
        payable(address5).transfer(oneMilli * 25);
        payable(address6).transfer(oneMilli * 25);
        payable(address7).transfer(oneMilli * 380);
    }
}