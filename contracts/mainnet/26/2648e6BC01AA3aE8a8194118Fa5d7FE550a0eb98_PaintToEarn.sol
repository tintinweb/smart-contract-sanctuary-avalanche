//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./Ownable.sol";

// @creator: Paint To Earn - painttoearn.io

contract PaintToEarn is Ownable {
    
    bool paintState = true;
    uint256 paintPrice = 0.0027 ether;

    uint256 canvasSizeWidth = 1000;
    uint256 canvasSizeHeight = 1000;
    
    mapping(uint256 => string) colorPalette;
    mapping(address => uint256) addressPaintCount;

    mapping(uint256 => mapping(uint256 => address)) coordinateAddress;
    mapping(uint256 => mapping(uint256 => string)) coordinateColor;

    address founder1 = 0x524192ce030D38aD15cfa1b98F19A55AF692feBD;
    address founder2 = 0xBff3A6caec37850f23Db6ebb9E23C884eCBE13BD;

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

    function checkColorInColorPalette(string memory color) public view returns (bool) {
        for(uint256 i=0; i < 14; i++) {
            if (keccak256(abi.encodePacked(colorPalette[i])) == keccak256(abi.encodePacked(color))) {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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