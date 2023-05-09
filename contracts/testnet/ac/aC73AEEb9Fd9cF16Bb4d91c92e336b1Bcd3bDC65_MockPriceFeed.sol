/**
 *Submitted for verification at testnet.snowtrace.io on 2023-05-08
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File contracts/externalContract/openzeppelin/non-upgradeable/IERC20.sol

// SPDX-License-Identifier: MIT AND GPL-3.0
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

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
}

// File contracts/externalContract/openzeppelin/non-upgradeable/IERC20Metadata.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// File contracts/externalContract/openzeppelin/non-upgradeable/Context.sol

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File contracts/externalContract/openzeppelin/non-upgradeable/Ownable.sol

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File contracts/externalContract/modify/non-upgradeable/AggregatorV2V3Interface.sol

pragma solidity ^0.8.0;

/**
 * @title The V2 & V3 Aggregator Interface
 * @notice Solidity V0.5 does not allow interfaces to inherit from other
 * interfaces so this contract is a combination of v0.5 AggregatorInterface.sol
 * and v0.5 AggregatorV3Interface.sol.
 */
interface AggregatorV2V3Interface {
    //
    // V2 Interface:
    //
    function latestAnswer() external view returns (int256);

    function latestTimestamp() external view returns (uint256);

    function latestRound() external view returns (uint256);

    function getAnswer(uint256 roundId) external view returns (int256);

    function getTimestamp(uint256 roundId) external view returns (uint256);

    event AnswerUpdated(int256 indexed current, uint256 indexed roundId, uint256 timestamp);
    event NewRound(uint256 indexed roundId, address indexed startedBy, uint256 startedAt);

    //
    // V3 Interface:
    //
    function decimals() external view returns (uint8);

    function description() external view returns (string memory);

    function version() external view returns (uint256);

    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(
        uint80 _roundId
    )
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

// File contracts/mock/src/utils/MockPriceFeed.sol

pragma solidity 0.8.15;

contract MockPriceFeed is Ownable {
    mapping(address => mapping(address => uint256)) public tokenPrice;
    mapping(address => uint256) public tokenPrecision;
    address public busdAddress;

    mapping(address => address) public pricesFeeds; // token => pricefeed
    mapping(address => uint256) public decimals; // decimals of supported tokens

    uint256 WEI_PRECISION = 10 ** 18;

    constructor(address _busdAddress) {
        busdAddress = _busdAddress;
    }

    function setPrice(address src, address dest, uint256 price) public onlyOwner {
        tokenPrice[src][dest] = price;
        tokenPrice[dest][src] = (1e18 * 1e18) / price;
    }

    function setPrecision(address token, uint256 precision) public onlyOwner {
        tokenPrecision[token] = precision;
    }

    function getPrice(address src, address dest) public view returns (uint256) {
        return tokenPrice[src][dest];
    }

    function getPrecision(address src, address dest) public view returns (uint256) {
        if (tokenPrecision[dest] >= tokenPrecision[src]) {
            return 10 ** (18 - (tokenPrecision[dest] - tokenPrecision[src]));
        } else {
            return 10 ** (18 - (tokenPrecision[src] - tokenPrecision[dest]));
        }
    }

    function queryRate(address src, address dest) public view returns (uint256, uint256) {
        return (getPrice(src, dest), getPrecision(src, dest));
    }

    function queryPrecision(address sourceToken, address destToken) public view returns (uint256) {
        return
            sourceToken != destToken ? _getDecimalPrecision(sourceToken, destToken) : WEI_PRECISION;
    }

    function queryReturn(
        address sourceToken,
        address destToken,
        uint256 sourceAmount
    ) public view returns (uint256 destAmount) {
        (uint256 rate, uint256 precision) = queryRate(sourceToken, destToken);

        destAmount = (sourceAmount * rate) / precision;
    }

    function setDecimals(IERC20Metadata[] calldata tokens) external {
        address[] memory tokenAddresses = new address[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            decimals[address(tokens[i])] = tokens[i].decimals();
            tokenAddresses[i] = address(tokens[i]);
        }
    }

    function queryRateUSD(address token) external view returns (uint256 rate, uint256 precision) {
        (rate, precision) = queryRate(token, busdAddress);
        // AggregatorV2V3Interface _Feed = AggregatorV2V3Interface(pricesFeeds[token]);
        // (, int256 answer, , , ) = _Feed.latestRoundData();
        // rate = uint256(answer);
        // uint256 decimal = _Feed.decimals();

        // rate = (rate * WEI_PRECISION) / (10**decimal);
        // precision = WEI_PRECISION;
    }

    function setPriceFeed(address[] calldata tokens, address[] calldata feeds) external {
        require(tokens.length == feeds.length, "PriceFeed/count-mismatch");
        for (uint256 i = 0; i < tokens.length; i++) {
            pricesFeeds[tokens[i]] = feeds[i];
        }
    }

    function _getDecimalPrecision(
        address sourceToken,
        address destToken
    ) internal view returns (uint256) {
        if (sourceToken == destToken) {
            return WEI_PRECISION;
        } else {
            uint256 sourceTokenDecimals = decimals[sourceToken];
            if (sourceTokenDecimals == 0)
                sourceTokenDecimals = IERC20Metadata(sourceToken).decimals();

            uint256 destTokenDecimals = decimals[destToken];
            if (destTokenDecimals == 0) destTokenDecimals = IERC20Metadata(destToken).decimals();

            if (destTokenDecimals >= sourceTokenDecimals) {
                return 10 ** (18 - (destTokenDecimals - sourceTokenDecimals));
            } else {
                return 10 ** (18 + (sourceTokenDecimals - destTokenDecimals));
            }
        }
    }
}