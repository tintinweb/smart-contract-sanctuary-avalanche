// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./interfaces/GeneralInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

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

    mapping(uint8 => uint256) private _contractToPrice;

    address private _collectorAddress;

    IERC20 private _token;

    constructor(
        uint256 chainId,
        address tokenAddress,
        address collectorAddress,
        uint8[] memory contractTypes,
        uint256[] memory prices
    ) {
        _chainId = chainId;
        _token = IERC20(tokenAddress);
        _collectorAddress = collectorAddress;
        uint256 length = contractTypes.length;
        require(length == prices.length);
        for (uint256 i; i < length; i++) {
            _contractToPrice[contractTypes[i]] = prices[i];
        }
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
        uint256 amount,
        bool mintable,
        bool burnable,
        bool capped,
        bool role
    ) external returns (address addr) {
        require(amount == _contractToPrice[contractType], "Invalid price");
        _token.transferFrom(msg.sender, _collectorAddress, amount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}