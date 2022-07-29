/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-28
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Oracle is Context {
    string private _name;
    address public owner;

    uint256 public _price;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    constructor(string memory name_, address owner_) {
        _name = name_;
        owner = owner_;
    }

    function getPrice() external view returns (uint256) {
        return _price;
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function setPrice(uint256 price) external onlyOwner {
        _price = price;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}