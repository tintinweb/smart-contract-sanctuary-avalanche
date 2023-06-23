// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

import "../interfaces/IACLManager.sol";

contract PoolAddressesProvider {
    mapping(uint64=>address) public liquidationProtocolAddresses;
	address public wethAddress;
	address public aclManagerAddress;
	address public infinityTokenAddress;
	address[] public infinitySupportedTokens;

    event LiquidationProtocolRegistered(
		address indexed protocolAddress
	);

	modifier onlyDefaultAdminRole(address _account) {
		IACLManager(aclManagerAddress).checkDefaultAdminRole(_account);
		_;
	}

	modifier onlyBookkeeperRole(address _account) {
		IACLManager(aclManagerAddress).checkBookkeeperRole(_account);
		_;
	}

	constructor(address _addrWETH, address _aclManagerAddress, address _infinityTokenAddress, address[] memory _infinitySupportedTokens) {
		wethAddress = _addrWETH;
		aclManagerAddress = _aclManagerAddress;
		infinityTokenAddress = _infinityTokenAddress;
		infinitySupportedTokens = _infinitySupportedTokens;
	}

    function registerLiquidationProtocol(
		uint64 protocolId, address protocolAddress
	) onlyDefaultAdminRole(msg.sender) external {
		require(protocolAddress!=address(0x0),"protocol cannot be 0");
		// require(liquidationProtocolAddresses[protocolId]==address(0x0),"protocol ID dupl."); 
		liquidationProtocolAddresses[protocolId] = protocolAddress;
		emit LiquidationProtocolRegistered(protocolAddress);
	} 

	function setWETH(address _addrWETH) public onlyDefaultAdminRole(msg.sender) {
		// require(_addrWETH != address(0), "addrWETH 0");
		wethAddress = _addrWETH;
	}

	function setAclManager(address _aclManagerAddress) public onlyDefaultAdminRole(msg.sender) {
		aclManagerAddress = _aclManagerAddress;
	}

	function setInfinityToken(address _infinityTokenAddress) public onlyDefaultAdminRole(msg.sender) {
		infinityTokenAddress = _infinityTokenAddress;
	}

	function setInfinitySupportedTokens(address[] calldata _infinitySupportedTokens) public onlyBookkeeperRole(msg.sender)
	{
		infinitySupportedTokens = _infinitySupportedTokens;
	}

	function getInfinitySupportedTokens() public view returns (address[] memory)
	{
		return infinitySupportedTokens;
	}


}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12;

interface IACLManager {

    function checkDefaultAdminRole(address _account) external view;
    function checkBookkeeperRole(address _account) external view;
    function checkTreasurerRole(address _account) external view;
    function checkLiquidatorRole(address _account) external view;
    function checkTimelockRole(address _account) external view;

}