pragma solidity ^0.5.16;

import "../interfaces/ICustodian.sol";
import "../interfaces/IProxy.sol";
import "../third/IToken.sol";

contract TestEntry {
    ICustodian public entry;
    IProxy public proxy;
    IToken public token;

    function setCustodian(ICustodian _entry, IProxy _proxy, IToken _token) external {
        entry = _entry;
        proxy = _proxy;
        token = _token;
    }

    function add(address tokenAddress) external {
        entry.add(1, "velo", tokenAddress, "GBQYX7PQC2INRCKPNPVWXHZSAAEYC3ZSJJ75BXOYBRQNKVHZLEZY3O3M");
    }

    function transfer(address _to, uint256 _value) external {
        token.transfer(_to, _value);
    }

    function getData(uint256 _typeid) external view returns (uint256, bytes32, address, string memory) {
        return entry.getAsset(_typeid);
    }

    function lock(address user, uint256 value, bytes32 memo) external {
        entry.lock(1, user, value, memo);
    }

    function unlock(address user, uint256 value) external {
        entry.unlock(1, user, value);
    }

    function transferOwnership(address _newOwner) external {
        proxy.transferOwnership(_newOwner);
    }

    function upgrade(string memory _version, address _impl) public {
        proxy.upgradeTo(_version, _impl);
    }
}

pragma solidity ^0.5.16;

interface IToken {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function getCallAddress() external view returns (address);
    function allowance(address owner, address spender) external view returns (uint256);
}

pragma solidity ^0.5.16;

interface IProxy {
    function implementation() external view returns (address);
    function upgradeTo(string calldata _newVersion, address _newImplementation) external;
    function getImplFromVersion(string calldata _version) external view returns(address);
    function transferOwnership(address newOwner) external;
    event Upgraded(string indexed newVersion, address indexed newImplementation, string version);
}

pragma solidity ^0.5.16;

interface ICustodian {
    function lock(uint256 _typeid, address _from, uint256 _value, bytes32 _memo) external;
    function unlock(uint256 _typeid, address _to, uint256 _value) external;
    function add(uint256 _typeid, bytes32 _name, address _tokenAddress, string calldata _partnerIssuer) external;
    function remove(uint256 _typeid) external;
    function getAsset(uint256 _typeid) external view returns (uint256, bytes32, address, string memory);
    function getAssetIds() external view returns (uint256[] memory assetIds);
    function getLockedFunds(address _tokenAddress) external view returns (uint256);
    event Locked(uint256 indexed typeid, address indexed from, uint256 value, bytes32 memo);
    event UnLocked(uint256 indexed typeid, address indexed sender, uint256 value);
    event AddedAsset(uint256 indexed typeid, bytes32 indexed name);
    event RemovedAsset(uint256 indexed typeid);
}