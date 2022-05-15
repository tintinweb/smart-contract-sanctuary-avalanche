//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";

// ..................................................
// ..................................................
// ...NNNN....NNNN....FFFFFFFFFFFF....TTTTTTTTTTTT...
// ...NNNNN...NNNN....FFFFFFFFFFFF....TTTTTTTTTTTT...
// ...NNNNNNN.NNNN....FFFF................TTTT.......
// ...NNNN.NNNNNNN....FFFFFFFFFF..........TTTT.......
// ...NNNN...NNNNN....FFFFFFFFFF..........TTTT.......
// ...NNNN....NNNN....FFFF................TTTT.......
// ...NNNN....NNNN....FFFF................TTTT.......
// ..................................................
// ..................................................

// @creator: No Fucking Time - nofuckingtime.io

contract NoFuckingTime is Ownable {
    
    bool paintState = true;
    uint256 paintPrice = 0.001 ether; // 0.001 Avax

    uint256 canvasSizeWidth = 1000;
    uint256 canvasSizeHeight = 1000;
    
    mapping(uint256 => string) colorPalette;
    mapping(uint256 => address) preRegisteredArtists;
    mapping(address => uint256) addressPaintCount;

    mapping(uint256 => mapping(uint256 => address)) coordinateAddress;
    mapping(uint256 => mapping(uint256 => string)) coordinateColor;

    address founder1 = 0xD099723478bDc2AF9c3C34f89C246A8194BD5d49;
    address founder2 = 0x34134A4E31850d56783fC2ea45E4Fc6c474E0342;

    constructor() {
        colorPalette[0] = '#FFD635'; // Yellow
        colorPalette[1] = '#FFA800'; // Light Orange
        colorPalette[2] = '#FF4500'; // Orange
        colorPalette[3] = '#BE0039'; // Red
        colorPalette[4] = '#B44AC0'; // Light Purple
        colorPalette[5] = '#811E9F'; // Purple
        colorPalette[6] = '#493AC1'; // Dark Blue
        colorPalette[7] = '#3690EA'; // Blue
        colorPalette[8] = '#00A368'; // Green
        colorPalette[9] = '#00CC78'; // Light Green
        colorPalette[10] = '#FFFFFF'; // White
        colorPalette[11] = '#D4D7D9'; // Light Gray
        colorPalette[12] = '#898D90'; // Gray
        colorPalette[13] = '#000000'; // Black

        preRegisteredArtists[0] = 0x0000000000000000000000000000000000000000;
        preRegisteredArtists[1] = 0x0000000000000000000000000000000000000000;
        preRegisteredArtists[2] = 0x0000000000000000000000000000000000000000;
        preRegisteredArtists[3] = 0xcD49c32608173AD2DAF45471e2f8661655e237A5;
        preRegisteredArtists[4] = 0x0000000000000000000000000000000000000000;
        preRegisteredArtists[5] = 0x0000000000000000000000000000000000000000;
        preRegisteredArtists[6] = 0x0000000000000000000000000000000000000000;
        preRegisteredArtists[7] = 0x0000000000000000000000000000000000000000;
        preRegisteredArtists[8] = 0x0000000000000000000000000000000000000000;
        preRegisteredArtists[9] = 0x0000000000000000000000000000000000000000;
        preRegisteredArtists[10] = 0x0000000000000000000000000000000000000000;
    }

    function clearCoordinate(uint256 x, uint256 y) public onlyOwner {
        require(x >= 0 && x < canvasSizeWidth && y >= 0 && y < canvasSizeHeight, "Coordinate doesn't exist.");
        coordinateAddress[x][y] = 0x0000000000000000000000000000000000000000;
        coordinateColor[x][y] = '#000000';
    }

    function ownerPaintCoordinate(uint256 x, uint256 y, address _address, string memory color) public onlyOwner {
        require(x >= 0 && x < canvasSizeWidth && y >= 0 && y < canvasSizeHeight, "Coordinate doesn't exist.");
        
        require(checkColorInColorPalette(color) == true, "Color is not in the color palette.");

        addressPaintCount[msg.sender]++;
        coordinateAddress[x][y] = _address;
        coordinateColor[x][y] = color;
    }

    function paintCoordinate(uint256 x, uint256 y, address _address, string calldata color) public payable {
        require(paintState == true, "Painting is not active now.");
        
        require(x >= 0 && x < canvasSizeWidth && y >= 0 && y < canvasSizeHeight, "Coordinate doesn't exist.");

        require(msg.value >= paintPrice, "Insufficient funds.");

        require(checkColorInColorPalette(color) == true, "Color is not in the color palette.");
        require(checkCoordinateAddressAndColor(x, y, _address, color) == false, "Same address already painted same color into this coordinate.");

        addressPaintCount[msg.sender]++;
        coordinateAddress[x][y] = _address;
        coordinateColor[x][y] = color;
    }

    function paintPRACoordinate(uint256 x, uint256 y, address _address, string calldata color) public {
        require(paintState == true, "Painting is not active now.");
        
        require(x >= 0 && x < canvasSizeWidth && y >= 0 && y < canvasSizeHeight, "Coordinate doesn't exist.");

        require(checkAddressInPreRegisteredArtists(_address) == true , "Address is not a pre-registered artist.");
        require(checkColorInColorPalette(color) == true, "Color is not in the color palette.");
        require(checkCoordinateAddressAndColor(x, y, _address, color) == false, "Same address already painted same color into this coordinate.");

        addressPaintCount[msg.sender]++;
        coordinateAddress[x][y] = _address;
        coordinateColor[x][y] = color;
    }

    function checkColorInColorPalette(string memory color) public view returns (bool) {
        for(uint256 i=0; i < 14; i++) {
            if (keccak256(abi.encodePacked(colorPalette[i])) == keccak256(abi.encodePacked(color))) {
                return true;
            }
        }
        return false;
    }

    function checkAddressInPreRegisteredArtists(address _address) public view returns (bool) {
        for(uint256 i=0; i < 10; i++) {
            if (keccak256(abi.encodePacked(preRegisteredArtists[i])) == keccak256(abi.encodePacked(_address))) {
                return true;
            }
        }
        return false;
    }

    function checkCoordinateAddressAndColor(uint256 x, uint256 y, address _address, string memory color) internal view returns (bool) {
        if (keccak256(abi.encodePacked(coordinateAddress[x][y])) == keccak256(abi.encodePacked(_address)) && keccak256(abi.encodePacked(coordinateColor[x][y])) == keccak256(abi.encodePacked(color))) {
            return true;
        } else {
            return false;
        }
    }

    function getCoordinateAddress(uint256 x, uint256 y) public view returns (address) {
        require(x >= 0 && x < canvasSizeWidth && y >= 0 && y < canvasSizeHeight, "Coordinate doesn't exist.");
        return coordinateAddress[x][y];
    }

    function getCoordinateColor(uint256 x, uint256 y) public view returns (string memory) {
        require(x >= 0 && x < canvasSizeWidth && y >= 0 && y < canvasSizeHeight, "Coordinate doesn't exist.");

        if (keccak256(abi.encodePacked(coordinateColor[x][y])) == keccak256(abi.encodePacked(''))) {
            return '#000000';
        } else {
            return coordinateColor[x][y];
        }
    }

    function updatePaintPrice(uint256 price) public onlyOwner {
        paintPrice = price;
    }

    function updatePaintState(bool state) public onlyOwner {
        paintState = state;
    }

    function getPaintPrice() public view returns(uint256) {
        return paintPrice;
    }

    function getPaintState() public view returns(bool) {
        return paintState;
    }

    function getCanvasSizeWidth() public view returns(uint256) {
        return canvasSizeWidth;
    }

    function getCanvasSizeHeight() public view returns(uint256) {
        return canvasSizeHeight;
    }    

    function getColorPalette(uint256 index) public view returns(string memory) {
        return colorPalette[index];
    }

    function getAddressPaintCount(address _address) public view returns(uint256) {
        return addressPaintCount[_address];
    }
    
    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "Not enough balance.");

        (bool successFounder1, ) = payable(founder1).call{value: ((balance * 500) / 1000)}("");
        require(successFounder1, "Transfer failed.");

        (bool successFounder2, ) = payable(founder2).call{value: ((balance * 500) / 1000)}("");
        require(successFounder2, "Transfer failed.");

        (bool successOwner, ) = payable(msg.sender).call{value: (address(this).balance)}("");
        require(successOwner, "Transfer failed.");
    }
}