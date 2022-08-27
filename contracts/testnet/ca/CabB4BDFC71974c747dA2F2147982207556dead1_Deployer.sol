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

    mapping(uint8 => mapping(address => ContractData[]))
        private _addressToContracts;

    mapping(uint8 => mapping(address => uint256)) private _userTotalContract;

    mapping(uint8 => mapping(address => mapping(uint256 => ContractData)))
        private _indexToContract;

    constructor(uint256 chainId) {
        _chainId = chainId;
    }

    function getUserContracts(address user)
        external
        view
        returns (
            ContractData[] memory,
            ContractData[] memory,
            ContractData[] memory,
            ContractData[] memory
        )
    {
        return (
            _addressToContracts[1][user],
            _addressToContracts[2][user],
            _addressToContracts[3][user],
            _addressToContracts[4][user]
        );
    }

    //

    function getContractByUserAndIndex(
        address user,
        uint256 index,
        uint8 contractType,
        bool[4] memory conditions
    )
        external
        view
        returns (
            ContractData memory,
            string memory,
            string memory,
            uint8,
            uint256,
            uint256[] memory
        )
    {
        uint256[] memory amounts = new uint256[](3);

        address contractAddress = _indexToContract[contractType][user][index]
            .contractAddress;
        GeneralInterface token = GeneralInterface(contractAddress);
        if (conditions[0]) {
            amounts[0] = token.cap();
        }

        if (conditions[2]) {
            amounts[1] = token.getDeflection();
        }

        if (conditions[3]) {
            amounts[2] = token.getReflection();
        }
        return (
            _indexToContract[contractType][user][index],
            token.name(),
            token.symbol(),
            token.decimals(),
            token.totalSupply(),
            amounts
        );
    }

    function deploy(
        bytes memory _bytecode,
        bytes memory constructorArgs,
        address deployer,
        string memory contractName,
        uint8 contractType,
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

        uint256 index = _userTotalContract[contractType][deployer];
        ContractData memory contractData = ContractData(
            deployer,
            addr,
            _chainId,
            index,
            contractName,
            mintable,
            burnable,
            capped,
            role
        );
        _addressToContracts[contractType][deployer].push(contractData);
        _indexToContract[contractType][deployer][index] = contractData;
        _userTotalContract[contractType][deployer]++;
    }
}

// Simple contract : 500 BUSD
// taxable : 1000 BUSD

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

    function cap() external view returns (uint256);

    function getTaxesAndAddress()
        external
        view
        returns (uint256[] memory, address[] memory);

    function getDeflection() external view returns (uint256);

    function getReflection() external view returns (uint256);
}