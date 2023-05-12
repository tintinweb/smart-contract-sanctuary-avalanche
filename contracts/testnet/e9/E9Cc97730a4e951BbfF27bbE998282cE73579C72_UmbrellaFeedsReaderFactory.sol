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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @dev Main contract for all deviation triggered fees.
/// This contract has build in fallback feature in case it will be replaced by newer version.
/// Fallback is transparent for the user, no additional setup is needed.
///
/// How fallback feature works? If data for provided key is empty, contract will execute following procedure:
/// 1. triggered feeds, that needs to be updated will be updated in new contract and erased from this one
/// 2. if data is empty, check, if new deployment of UmbrellaFeeds is done, if not stop.
/// 3. forward the call to that new contract.
///
/// After new deployment done it is recommended to update address to avoid fallback and reduce gas cost.
/// In long run this is most efficient solution, better than any proxy.
interface IUmbrellaFeeds {
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

    /// @dev method for submitting consensus data
    /// @param _priceKeys array of keys for `_priceDatas`
    /// @param _priceDatas PriceData signed by validators
    /// @param _signatures validators signatures
    // solhint-disable-next-line function-max-lines, code-complexity
    function update(
        bytes32[] calldata _priceKeys,
        PriceData[] calldata _priceDatas,
        Signature[] calldata _signatures
    ) external;

    /// @dev method for resetting data
    /// @param _priceKeys array of keys for `_priceDatas`
    /// @param _signatures validators signatures
    function reset(bytes32[] calldata _priceKeys, Signature[] calldata _signatures) external;

    /// @dev it will return array of price datas for provided `_keys`
    /// In case ony of feeds timestamp is empty, fallback call will be executed for that feed.
    /// If any of feeds fallback calls fail, function will revert.
    /// @param _keys array of feed keys
    /// @return data PriceData array
    function getPricesData(bytes32[] calldata _keys) external view returns (PriceData[] memory data);

    /// @dev same as getPricesData() but does not revert on empty data.
    function getPricesDataRaw(bytes32[] calldata _keys) external view returns (PriceData[] memory data);

    /// @dev this is main endpoint for reading feeds.
    /// In case timestamp is empty (that means there is no data), contract will execute fallback call.
    /// Check contract description for fallback details.
    function getPriceData(bytes32 _key) external view returns (PriceData memory data);

    /// @dev same as `getPriceData` but does not revert when no data
    function getPriceDataRaw(bytes32 _key) external view returns (PriceData memory data);

    function DECIMALS() external view returns (uint8); // solhint-disable-line func-name-mixedcase
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IUmbrellaFeeds.sol";

/// @dev This is optional price reader for just one feed.
/// It comes with chanilink interface that makes migration process easier.
/// For maximum gas optimisation it is recommended to use UmbrellaFeeds directly.
contract UmbrellaFeedsReader {
    /// @dev contract where all the feeds are stored
    IUmbrellaFeeds public immutable UMBRELLA_FEEDS;  // solhint-disable-line var-name-mixedcase

    /// @dev key (hash of string key), under which feed is being stored
    bytes32 public immutable KEY;  // solhint-disable-line var-name-mixedcase

    /// @dev decimals for feed
    uint8 public immutable DECIMALS;  // solhint-disable-line var-name-mixedcase

    /// @dev string representation of feed key
    string public DESCRIPTION;  // solhint-disable-line var-name-mixedcase

    error FeedNotExist();

    /// @param _umbrellaFeeds UmbrellaFeeds address
    /// @param _key price data key (before hashing)
    constructor(IUmbrellaFeeds _umbrellaFeeds, string memory _key) {
        UMBRELLA_FEEDS = _umbrellaFeeds;
        DESCRIPTION = _key;
        DECIMALS = _umbrellaFeeds.DECIMALS();

        bytes32 hash = keccak256(abi.encodePacked(_key));
        KEY = hash;

        // sanity check
        _umbrellaFeeds.getPriceData(hash);
    }

    /// @dev decimals for feed
    function decimals() external view returns (uint8) {
        return DECIMALS;
    }

    /// @dev string representation of feed key
    function description() external view returns (string memory) {
        return DESCRIPTION;
    }

    /// @dev this method follows chainlink interface for easy migration, NOTE: not all returned data are covered!
    /// latestRoundData() raise exception when there is no data, instead of returning unset values,
    /// which could be misinterpreted as actual reported values.
    /// It DOES NOT raise when data is outdated (based on heartbeat and last timestamp).
    /// @notice You can save some gas by doing call directly to `UMBRELLA_FEEDS` contract.
    /// @return uint80 originally `roundId`, not in use, always 0
    /// @return answer price
    /// @return uint256 originally `startedAt`, not in use, always 0
    /// @return updatedAt last timestamp data was updated
    /// @return uint80 originally `answeredInRound` not in use, always 0
    function latestRoundData()
        external
        view
        returns (
            uint80 /* roundId */,
            int256 answer,
            uint256 /* startedAt */,
            uint256 updatedAt,
            uint80 /* answeredInRound */
        )
    {
        IUmbrellaFeeds.PriceData memory data = UMBRELLA_FEEDS.getPriceData(KEY);
        return (0, int256(uint256(data.price)), 0, data.timestamp, 0);
    }

    /// @dev this is main endpoint for reading feed. Feed is read from UmbrellaFeeds contract using hardcoded `KEY`.
    /// In case timestamp is empty (that means there is no data), contract will execute fallback call.
    /// Check UmbrellaFeeds contract description for fallback details.
    function getPriceData() external view returns (IUmbrellaFeeds.PriceData memory) {
        return UMBRELLA_FEEDS.getPriceData(KEY);
    }

    /// @dev same as `getPriceData` but does not revert when no data
    function getPriceDataRaw() external view returns (IUmbrellaFeeds.PriceData memory) {
        return UMBRELLA_FEEDS.getPriceDataRaw(KEY);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "../interfaces/IRegistry.sol";
import "../interfaces/IStakingBank.sol";

import "./UmbrellaFeedsReader.sol";

/// @dev Factory to deploy UmbrellaFeedsReader contract
contract UmbrellaFeedsReaderFactory {
    IRegistry public immutable REGISTRY; // solhint-disable-line var-name-mixedcase

    mapping (bytes32 => UmbrellaFeedsReader) public readers;

    error EmptyAddress();

    constructor(IRegistry _registry) {
        if (address(_registry) == address(0)) revert EmptyAddress();

        REGISTRY = _registry;
    }

    /// @dev Method to deploy new UmbrellaFeedsReader for particular key.
    /// This deployment is optional and it can be done by anyone who needs it.
    /// Reader can be used to simplify migration from Chainlink to Umbrella.
    ///
    /// Check UmbrellaFeedsReader docs for more details.
    ///
    /// We not using minimal proxy because it does not allow for immutable variables.
    /// @param _key string Feed key that is registered in UmbrellaFeeds
    /// @return reader UmbrellaFeedsReader contract address, in case anyone wants to use it from Layer1
    function deploy(string memory _key) external returns (UmbrellaFeedsReader reader) {
        reader = deployed(_key);
        IUmbrellaFeeds umbrellaFeeds = IUmbrellaFeeds(REGISTRY.getAddressByString("UmbrellaFeeds"));

        // if UmbrellaFeeds contract is up to date, there is no need to redeploy
        if (address(reader) != address(0) && address(reader.UMBRELLA_FEEDS()) == address(umbrellaFeeds)) {
            return reader;
        }

        reader = new UmbrellaFeedsReader(umbrellaFeeds, _key);
        readers[hash(_key)] = reader;
    }

    function deployed(string memory _key) public view returns (UmbrellaFeedsReader) {
        return readers[hash(_key)];
    }

    function hash(string memory _key) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_key));
    }

    /// @dev to follow Registrable interface
    function getName() public pure returns (bytes32) {
        return "UmbrellaFeedsReaderFactory";
    }
}