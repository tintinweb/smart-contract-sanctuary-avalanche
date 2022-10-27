// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IAggregatorV3 } from "./interfaces/IAggregatorV3.sol";

contract FiatContract is Ownable {
    struct Asset {
        string symbol;
        address asset;
        IAggregatorV3 priceFeed;
    }

    mapping(string => Asset) private _assets;

    constructor() {
        _setAsset("AVAX", address(0), 0x0A77230d17318075983913bC2145DB16C7366156);
    }

    function setAssets(
        string[] calldata symbols_,
        address[] calldata assets_,
        address[] calldata priceFeeds_
    ) external onlyOwner {
        uint256 length = priceFeeds_.length;
        require(symbols_.length == length && assets_.length == length, "Length mismatch!");
        for (uint256 i = 0; i < length; i++) {
            _setAsset(symbols_[i], assets_[i], priceFeeds_[i]);
        }
    }

    function _setAsset(
        string memory symbol_,
        address asset_,
        address priceFeed_
    ) private {
        _assets[symbol_] = Asset(symbol_, asset_, IAggregatorV3(priceFeed_));
    }

    function getLatestPrice(string memory symbol) public view returns (int256) {
        (, int256 _price, , , ) = _assets[symbol].priceFeed.latestRoundData();
        return _price * 10**10;
    }

    function usd2Asset(string memory symbol, uint256 amountUSD) public view returns (uint256 _amountAsset) {
        return (amountUSD * 1 ether) / (uint256(getLatestPrice(symbol)));
    }

    function getToken2USD(string memory symbol) public view returns (string memory _symbolToken, uint256 _token2USD) {
        uint256 token2USD;

        if (_assets[symbol].priceFeed != IAggregatorV3(address(0))) {
            token2USD = usd2Asset(symbol, 1 ether);
        }

        return (symbol, token2USD);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IAggregatorV3 {
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

// SPDX-License-Identifier: MIT
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