//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

contract ProxyAdmin {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "ProxyAdmin:: onlyOwner: caller is not owner");
        _;
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    function renounceOwnership() external onlyOwner {
        owner = address(0);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _transferOwnership(newOwner);
    }

    function getProxyImplementation(address proxy) external returns (address) {
        (bool success, bytes memory returndata) = address(proxy).call(abi.encodeWithSignature("implementation()"));
        require(success, "ProxyAdmin:: getProxyImplementation: getProxyImplementation failed");
        return abi.decode(returndata, (address));
    }

    function getProxyAdmin(address proxy) external returns (address) {
        (bool success, bytes memory returndata) = address(proxy).call(abi.encodeWithSignature("admin()"));
        require(success, "ProxyAdmin:: getProxyAdmin: getProxyAdmin failed");
        return abi.decode(returndata, (address));
    }

    function changeProxyAdmin(address proxy, address newAdmin) external onlyOwner {
        (bool success, ) = address(proxy).call(abi.encodeWithSignature("changeAdmin(address)", newAdmin));
        require(success, "ProxyAdmin:: changeProxyAdmin: changeProxyAdmin failed");
    }

    function upgrade(address proxy, address newImplementation) external onlyOwner {
        (bool success, ) = address(proxy).call(abi.encodeWithSignature("upgradeTo(address)", newImplementation));
        require(success, "ProxyAdmin:: upgrade: upgrade failed");
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}