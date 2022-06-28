//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.12;

contract ERC20Proxy {
    /* int8 constant decimals = 6;
    uint256 totalSupply;
    string name;
    string symbol;
    bool initialized;
    mapping(address => uint256) balanceOf;
    mapping(address => mapping(address => uint256)) allowance; */

    bytes32 private constant implementationPosition = bytes32(uint256(keccak256("erc20.proxy.implementation")) - 1);
    bytes32 private constant adminPosition = bytes32(uint256(keccak256("erc20.proxy.admin")) - 1);


    event Upgraded(address implementation);
    event AdminChanged(address previousAdmin, address newAdmin);

    modifier ifAdmin() {
        if (msg.sender != _admin()) _delegate(_implementation());
        _;
    }

    constructor(address implementation_, address admin_, bytes memory _data) {
        _upgradeToAndCall(implementation_, _data, false);
        _changeAdmin(admin_);
    }

    fallback() external payable {
        _delegate(_implementation());
    }

    receive() external payable {
        _delegate(_implementation());
    }

    function implementation() external view returns (address) {
        return _implementation();
    }

    function admin() external view returns (address) {
        return _admin();
    }

    function changeAdmin(address newAdmin) external ifAdmin {
        address oldAdmin = _admin();
        _changeAdmin(newAdmin);
        emit AdminChanged(oldAdmin, newAdmin);
    }

    function upgradeTo(address newImplementation) public ifAdmin {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _delegate(address implementation_) internal {
        assembly {
            let ptr := mload(0x40)

            calldatacopy(ptr, 0, calldatasize())

            let result := delegatecall(gas(), implementation_, ptr, calldatasize(), 0, 0)
            let size := returndatasize()

            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    function _changeAdmin(address newAdmin) internal {
        bytes32 slot = adminPosition;
        assembly {
            sstore(slot, newAdmin)
        }
    }

    function _implementation() internal view returns (address implAddress) {
        bytes32 slot = implementationPosition;
        assembly {
            implAddress := sload(slot)
        }
    }

    function _admin() internal view returns (address adminAddress) {
        bytes32 slot = adminPosition;
        assembly {
            adminAddress := sload(slot)
        }
    }

    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function _upgradeToAndCall(address newImplementation, bytes memory data, bool forceCall) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            (bool success,) = address(newImplementation).delegatecall(data);
            require(success, "ProxyAdmin:: getProxyImplementation: getProxyImplementation failed");
        }
    }

    function _setImplementation(address newImplementation) private {
        bytes32 slot = implementationPosition;
        assembly {
            sstore(slot, newImplementation)
        }
    }
}