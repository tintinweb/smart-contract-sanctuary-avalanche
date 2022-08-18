// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/GeneralInterface.sol";

contract Deployer {
    uint256 private _chainId;

    struct ContractData {
        address deployer;
        address contractAddress;
        uint256 chainId;
        uint256 contractIndex;
        string contractType;
        bool mintable;
        bool burnable;
        bool capped;
        bool role;
    }
    mapping(address => ContractData[]) private _addressToContracts;
    mapping(address => uint256) private _userTotalContract;
    mapping(address => mapping(uint256 => ContractData))
        private _indexToContract;

    constructor(uint256 chainId) {
        _chainId = chainId;
    }

    function getUserContracts(address user)
        external
        view
        returns (ContractData[] memory)
    {
        return _addressToContracts[user];
    }

    function getContractByUserAndIndex(address user, uint256 index)
        external
        view
        returns (
            ContractData memory,
            string memory,
            string memory,
            uint8,
            uint256
        )
    {
        GeneralInterface token = GeneralInterface(
            _indexToContract[user][index].contractAddress
        );
        return (
            _indexToContract[user][index],
            token.name(),
            token.symbol(),
            token.decimals(),
            token.totalSupply()
        );
    }

    function deploy(
        bytes memory _bytecode,
        bytes memory constructorArgs,
        address deployer,
        string memory contractType,
        bool mintable,
        bool burnable,
        bool capped,
        bool role
    ) external returns (address addr) {
        bytes memory bytecode = abi.encodePacked(_bytecode, constructorArgs);
        assembly {
            addr := create(0, add(bytecode, 0x20), mload(bytecode))
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }

        uint256 index = _userTotalContract[deployer];
        ContractData memory contractData = ContractData(
            deployer,
            addr,
            _chainId,
            index,
            contractType,
            mintable,
            burnable,
            capped,
            role
        );
        _addressToContracts[deployer].push(contractData);
        _indexToContract[deployer][index] = contractData;
        _userTotalContract[deployer]++;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface GeneralInterface {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function burn(uint256 amount) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}