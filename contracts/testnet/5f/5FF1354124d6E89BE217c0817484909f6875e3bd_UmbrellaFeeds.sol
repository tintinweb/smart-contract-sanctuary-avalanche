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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IRegistry.sol";
import "../interfaces/IStakingBank.sol";

contract UmbrellaFeeds {
    uint8 public constant DECIMALS = 8;

    struct PriceData {
        uint8 data;
        uint24 heartbeat;
        uint32 timestamp;
        uint128 price;
    }

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    mapping (bytes32 => PriceData) public prices;

    constructor(
        IRegistry,
        uint16,
        uint8
    ) {}

    function update(
        bytes32[] calldata _priceKeys,
        PriceData[] calldata _priceDatas,
        Signature[] calldata _signatures
    ) external {
        for (uint256 i; i < _priceDatas.length;) {
            PriceData storage priceData = prices[_priceKeys[i]];

            if (priceData.timestamp < _priceDatas[i].timestamp) {
                prices[_priceKeys[i]] = _priceDatas[i];
            }

            unchecked { i++; }
        }
    }

    function getPriceData(string calldata _key) external view returns (PriceData memory data) {
        data = prices[keccak256(abi.encodePacked(_key))];
    }

    /// @dev to follow Registrable interface
    function getName() external pure returns (bytes32) {
        return "UmbrellaFeeds";
    }

    /// @dev to follow Registrable interface
    function register() external pure {
        // there are no requirements atm
    }

    /// @dev to follow Registrable interface
    function unregister() external pure {
        // there are no requirements atm
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;


interface IRegistry {
    event LogRegistered(address indexed destination, bytes32 name);

    /// @dev imports new contract addresses and override old addresses, if they exist under provided name
    /// This method can be used for contracts that for some reason do not have `getName` method
    /// @param  _names array of contract names that we want to register
    /// @param  _destinations array of contract addresses
    function importAddresses(bytes32[] calldata _names, address[] calldata _destinations) external;

    /// @dev imports new contracts and override old addresses, if they exist.
    /// Names of contracts are fetched directly from each contract by calling `getName`
    /// @param  _destinations array of contract addresses
    function importContracts(address[] calldata _destinations) external;

    /// @dev this method ensure, that old and new contract is aware of it state in registry
    /// Note: BSC registry does not have this method. This method was introduced in later stage.
    /// @param _newContract address of contract that will replace old one
    function atomicUpdate(address _newContract) external;

    /// @dev similar to `getAddress` but throws when contract name not exists
    /// @param name contract name
    /// @return contract address registered under provided name or throws, if does not exists
    function requireAndGetAddress(bytes32 name) external view returns (address);

    /// @param name contract name in a form of bytes32
    /// @return contract address registered under provided name
    function getAddress(bytes32 name) external view returns (address);

    /// @param _name contract name
    /// @return contract address assigned to the name or address(0) if not exists
    function getAddressByString(string memory _name) external view returns (address);

    /// @dev helper method that converts string to bytes32,
    /// you can use to to generate contract name
    function stringToBytes32(string memory _string) external pure returns (bytes32 result);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IStakingBank is IERC20 {
    /// @param id address of validator wallet
    /// @param location URL of the validator API
    struct Validator {
        address id;
        string location;
    }

    event LogValidatorRegistered(address indexed id);
    event LogValidatorUpdated(address indexed id);
    event LogValidatorRemoved(address indexed id);
    event LogMinAmountForStake(uint256 minAmountForStake);

    /// @dev setter for `minAmountForStake`
    function setMinAmountForStake(uint256 _minAmountForStake) external;

    /// @dev allows to stake `token` by validators
    /// Validator needs to approve StakingBank beforehand
    /// @param _value amount of tokens to stake
    function stake(uint256 _value) external;

    /// @dev notification about approval from `_from` address on UMB token
    /// Staking bank will stake max approved amount from `_from` address
    /// @param _from address which approved token spend for IStakingBank
    function receiveApproval(address _from) external returns (bool success);

    /// @dev withdraws stake tokens
    /// it throws, when balance will be less than required minimum for stake
    /// to withdraw all use `exit`
    function withdraw(uint256 _value) external returns (bool success);

    /// @dev unstake and withdraw all tokens
    function exit() external returns (bool success);

    /// @dev creates (register) new validator
    /// @param _id validator address
    /// @param _location location URL of the validator API
    function create(address _id, string calldata _location) external;

    /// @dev removes validator
    /// @param _id validator wallet
    function remove(address _id) external;

    /// @dev updates validator location
    /// @param _id validator wallet
    /// @param _location new validator URL
    function update(address _id, string calldata _location) external;

    /// @return total number of registered validators (with and without balance)
    function getNumberOfValidators() external view returns (uint256);

    /// @dev gets validator address for provided index
    /// @param _ix index in array of list of all validators wallets
    function addresses(uint256 _ix) external view returns (address);

    /// @param _id address of validator
    /// @return id address of validator
    /// @return location URL of validator
    function validators(address _id) external view returns (address id, string memory location);
}