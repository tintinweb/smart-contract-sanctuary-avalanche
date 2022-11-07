// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.0; 

/**
 * @title OwnedUpgradeabilityProxy
 * @dev This contract combines an upgradeability proxy with basic authorization control functionalities
 */
 
contract ProxyFinal{
    /**
     * @dev Event to show ownership has been transferred
     * @param previousOwner representing the address of the previous owner
     * @param newOwner representing the address of the new owner
     */
    event ProxyOwnershipTransferred(address previousOwner, address newOwner);

    /**
     * @dev This event will be emitted every time the implementation gets upgraded
     * @param implementation representing the address of the upgraded implementation
     */
    event Upgraded(address indexed implementation);

    // Storage position of the address of the maintenance boolean
    bytes32 private constant maintenancePosition = keccak256("com.proxy.maintenance");
    // Storage position of the address of the current implementation
    bytes32 private constant implementationPosition = keccak256("com.proxy.implementation");
    // Storage position of the owner of the contract
    bytes32 private constant proxyOwnerPosition = keccak256("com.proxy.owner");


    /**
     * @dev the constructor sets the original owner of the contract to the sender account.
     */
    constructor() {
        setUpgradeabilityOwner(msg.sender);
    }


    /**
     * @dev Tells if contract is on maintenance
     * @return _maintenance if contract is on maintenance
     */
    function maintenance() public view returns (bool _maintenance) {
        bytes32 position = maintenancePosition;
        assembly {
            _maintenance := sload(position)
        }
    }

    /**
     * @dev Sets if contract is on maintenance
     */
    function setMaintenance(bool _maintenance) external onlyProxyOwner {
        bytes32 position = maintenancePosition;
        assembly {
            sstore(position, _maintenance)
        }
    }

    /**
     * @dev Tells the address of the owner
     * @return owner the address of the owner
     */
    function proxyOwner() public view returns (address owner) {
        bytes32 position = proxyOwnerPosition;
        assembly {
            owner := sload(position)
        }
    }

    /**
     * @dev Sets the address of the owner
     */
    function setUpgradeabilityOwner(address newProxyOwner) internal {
        bytes32 position = proxyOwnerPosition;
        assembly {
            sstore(position, newProxyOwner)
        }
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferProxyOwnership(address newOwner) public onlyProxyOwner {
        require(newOwner != address(0), 'OwnedUpgradeabilityProxy: INVALID');
        emit ProxyOwnershipTransferred(proxyOwner(), newOwner);
        setUpgradeabilityOwner(newOwner);
    }

    /*
     * @dev Allows the proxy owner to upgrade the current version of the proxy.
     * @param implementation representing the address of the new implementation to be set.
     */
    function upgradeTo(address newImplementation) public onlyProxyOwner {
        _upgradeTo(newImplementation);
    }

    /*
     * @dev Allows the proxy owner to upgrade the current version of the proxy and call the new implementation
     * to initialize whatever is needed through a low level call.
     * @param implementation representing the address of the new implementation to be set.
     * @param data represents the msg.data to bet sent in the low level call. This parameter may include the function
     * signature of the implementation to be called with the needed payload
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) payable public onlyProxyOwner {
        upgradeTo(newImplementation);
        (bool success, ) = address(this).call{ value: msg.value }(data);
        require(success, "OwnedUpgradeabilityProxy: INVALID");
    }

    /**
     * @dev Fallback function allowing to perform a delegatecall to the given implementation.
     * This function will return whatever the implementation call returns
     */
    fallback() external payable {
        _fallback();
    }

    receive () external payable {
        _fallback();
    }

    /**
     * @dev Tells the address of the current implementation
     * @return impl address of the current implementation
     */
    function implementation() public view returns (address impl) {
        bytes32 position = implementationPosition;
        assembly {
            impl := sload(position)
        }
    }

    /**
     * @dev Sets the address of the current implementation
     * @param newImplementation address representing the new implementation to be set
     */
    function setImplementation(address newImplementation) internal {
        bytes32 position = implementationPosition;
        assembly {
            sstore(position, newImplementation)
        }
    }

    /**
     * @dev Upgrades the implementation address
     * @param newImplementation representing the address of the new implementation to be set
     */
    function _upgradeTo(address newImplementation) internal {
        address currentImplementation = implementation();
        require(currentImplementation != newImplementation, 'OwnedUpgradeabilityProxy: INVALID');
        setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _fallback() internal {
        if (maintenance()) {
            require(msg.sender == proxyOwner(), 'OwnedUpgradeabilityProxy: FORBIDDEN');
        }
        address _impl = implementation();
        require(_impl != address(0), 'OwnedUpgradeabilityProxy: INVALID');
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyProxyOwner() {
        require(msg.sender == proxyOwner(), 'OwnedUpgradeabilityProxy: FORBIDDEN');
        _;
    }
}

//SPDX-License-Identifier: GPL-3.0

import 'contracts/core/ProxyFinal.sol';

pragma solidity ^0.8.0;

contract TokenFactory {

    address public tokenImpl;
    address public identityRegistryImpl;
    address public claimTopicsRegistryImpl;
    address public trustIssuerRegistryImpl;
    address public identityRegistryStorageImpl;
    address public complianceImpl;
    address public proxyImpl;
    address public identityImpl;

    address public _owner;

    bytes32 salt;
    // bytes32 salt1 = 0x4920616d20546f6b656e20666f7220616e204173736575000000000000000000;

    event tokenCreated(address _tokenProxy, address _tokenImpl, address identityRegistry,address onchainId,
     string mappingValue, uint timestamp);
    
    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner,"Only owner can call");
        _;
    }

    function _clone(address impl, bytes32 _salt) internal returns (address _cloned) {
        require(tx.origin == msg.sender,"Only owner can call");
       assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, impl))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            _cloned := create2(0, ptr, 0x37, _salt)
        }
        return _cloned;
    }

    function setImplementation (address _token, address _identityRegistry, address _claimTopicsRegistry,
         address _trustIssuerRegistry, address _identityRegistryStorage, address _complianceaddress, 
         address _proxy, address _identity) public onlyOwner{
        tokenImpl = _token;
        identityRegistryImpl = _identityRegistry;
        claimTopicsRegistryImpl = _claimTopicsRegistry;
        trustIssuerRegistryImpl = _trustIssuerRegistry;
        identityRegistryStorageImpl = _identityRegistryStorage;
        complianceImpl = _complianceaddress;
        proxyImpl = _proxy;
        identityImpl = _identity;
    }

    function deployIdentity(address _initialManagementKey, bool _isLibrary) public returns (address) {
        address identityProxy = address(new ProxyFinal());

        (bool success,) = identityProxy.call(abi.encodeWithSelector(0x3659cfe6, identityImpl));
        require(success,"upgrade failed");
        success = false;
    
        (success,) = identityProxy.call(abi.encodeWithSelector(0xcb9fa366, _initialManagementKey,_isLibrary));
        require(success, "Identity Intiatialization Failed");
        success = false;
        return identityProxy;
    }


    function createToken(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _cap,
        string memory mappingValue,
        bytes32 _salt) external onlyOwner{

        salt = _salt;
        address identityRegistry = _clone(identityRegistryImpl,salt);
        _initIdentityRegistry(identityRegistry);
        _initProxy(identityRegistry, _name, _symbol, _decimals, _cap, mappingValue);

    }

    function _initProxy(address identityRegistry,string memory _name,string memory _symbol,uint8 _decimals,uint _cap, string memory mappingValue) internal{
        address compliance = _clone(complianceImpl,salt);
        address proxy = address(new ProxyFinal());
        address identity = deployIdentity(proxy,false);
        
        (bool success,) = proxy.call(abi.encodeWithSelector(0x3659cfe6, tokenImpl));
        require(success,"upgrade failed");
        success = false;
        (success,) = proxy.call(abi.encodeWithSelector(0xd44526bc, identityRegistry, compliance, _name, _symbol, _decimals, identity, _cap));
        require(success, "Token Intiatialization Failed");
        success = false;
        (success,) = proxy.call(abi.encodeWithSelector(0xf2fde38b, msg.sender));
        require(success, "token ownership Failed");
        emit tokenCreated(proxy, tokenImpl, identityRegistry, identity, mappingValue, block.timestamp);
    }

    function _initIdentityRegistry(address identityRegistry) internal{
        address claimTopicsRegistry = _clone(claimTopicsRegistryImpl,salt);
        address trustIssuerRegistry = _clone(trustIssuerRegistryImpl,salt);
        address identityRegistryStorage = _clone(identityRegistryStorageImpl,salt);
        (bool success,) = identityRegistry.call(abi.encodeWithSelector(0x184b9559, trustIssuerRegistry, claimTopicsRegistry, identityRegistryStorage));
        require(success, "identity Intiatialization Failed");
        success = false;
        (success,) = identityRegistry.call(abi.encodeWithSelector(0xf2fde38b, _owner));
        require(success, "identityRegistry ownership Failed");
        success = false;
        (success,) = identityRegistryStorage.call(abi.encodeWithSelector(0xe1c7392a));
        require(success == true);
        success = false;
        (success,) = identityRegistryStorage.call(abi.encodeWithSelector(0x690a49f9, identityRegistry));
        require(success, "identityRegistryStorage bind Failed");
        success = false;
        (success,) = identityRegistryStorage.call(abi.encodeWithSelector(0xf2fde38b, _owner));
        require(success, "identityRegistryStorage ownership Failed");
    }

}