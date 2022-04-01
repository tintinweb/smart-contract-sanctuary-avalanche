// SPDX-License-Identifier: GPL-3.0-or-later

/*
 //======================================================================\\
 //======================================================================\\
    *******         **********     ***********     *****     ***********
    *      *        *              *                 *       *
    *        *      *              *                 *       *
    *         *     *              *                 *       *
    *         *     *              *                 *       *
    *         *     **********     *       *****     *       ***********
    *         *     *              *         *       *                 *
    *         *     *              *         *       *                 *
    *        *      *              *         *       *                 *
    *      *        *              *         *       *                 *
    *******         **********     ***********     *****     ***********
 \\======================================================================//
 \\======================================================================//
*/

pragma solidity ^0.8.10;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {Ownable} from "../utils/Ownable.sol";

/**
 * @title  Price Getter
 * @notice This is the contract for getting price feed from chainlink.
 *         The contract will keep a record from tokenName => priceFeed Address.
 *         Got the sponsorship and collaboration with Chainlink.
 * @dev    The price from chainlink priceFeed has different decimals, be careful.
 */
contract PriceGetter is Ownable {
    struct PriceFeedInfo {
        address priceFeedAddress;
        uint256 decimals;
    }
    // Use token name (string) as the mapping key
    // Should set the correct orginal token name
    mapping(string => PriceFeedInfo) public priceFeedInfo;

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Events ***************************************** //
    // ---------------------------------------------------------------------------------------- //
    event PriceFeedChanged(
        string tokenName,
        address feedAddress,
        uint256 decimals
    );

    event LatestPriceGet(
        uint80 roundID,
        int256 price,
        uint256 startedAt,
        uint256 timeStamp,
        uint80 answeredInRound
    );

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Constructor ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Constructor function, initialize some price feed
     */
    constructor() Ownable(msg.sender) {
        // Avalanche data feed addresses and decimals
        priceFeedInfo["AVAX"] = PriceFeedInfo(
            0x0A77230d17318075983913bC2145DB16C7366156,
            8
        );

        priceFeedInfo["ETH"] = PriceFeedInfo(
            0x976B3D034E162d8bD72D6b9C989d545b839003b0,
            8
        );

        priceFeedInfo["BTC"] = PriceFeedInfo(
            0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743,
            8
        );
    }

    // ---------------------------------------------------------------------------------------- //
    // *************************************** Modifiers ************************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Can not give zero address
     */
    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Zero address");
        _;
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************ View Functions ************************************ //
    // ---------------------------------------------------------------------------------------- //

    // ---------------------------------------------------------------------------------------- //
    // ************************************ Set Functions ************************************* //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Set a price feed oracle address for a token
     * @param _tokenName Address of the token
     * @param _feedAddress Price feed oracle address
     * @param _decimals Decimals of this price feed service
     */
    function setPriceFeed(
        string memory _tokenName,
        address _feedAddress,
        uint256 _decimals
    ) public onlyOwner notZeroAddress(_feedAddress) {
        require(_decimals <= 18, "Too many decimals");
        priceFeedInfo[_tokenName] = PriceFeedInfo(_feedAddress, _decimals);

        emit PriceFeedChanged(_tokenName, _feedAddress, _decimals);
    }

    // ---------------------------------------------------------------------------------------- //
    // ************************************* Main Functions *********************************** //
    // ---------------------------------------------------------------------------------------- //

    /**
     * @notice Get latest price of a token
     * @param _tokenName Address of the token
     * @return price The latest price
     */
    function getLatestPrice(string memory _tokenName) public returns (uint256) {
        PriceFeedInfo memory priceFeed = priceFeedInfo[_tokenName];

        (
            uint80 roundID,
            int256 price,
            uint256 startedAt,
            uint256 timeStamp,
            uint80 answeredInRound
        ) = AggregatorV3Interface(priceFeed.priceFeedAddress).latestRoundData();

        // require(price > 0, "Only accept price that > 0");
        if (price < 0) price = 0;

        emit LatestPriceGet(
            roundID,
            price,
            startedAt,
            timeStamp,
            answeredInRound
        );
        // Transfer the result decimals
        uint256 finalPrice = uint256(price) * (10**(18 - priceFeed.decimals));

        return finalPrice;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.10;

import "./Context.sol";

/**
 * @dev The owner can be set during deployment, not default to be msg.sender
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address _initialOwner) {
        _transferOwnership(_initialOwner);
    }

    /**
     * @notice Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @notice Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @notice Leaves the contract without owner. It will not be possible to call
     *         `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * @dev    Renouncing ownership will leave the contract without an owner,
     *         thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev    Can only be called by the current owner.
     * @param  newOwner Address of the new owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    /**
     * @notice Transfers ownership of the contract to a new account (`newOwner`).
     * @dev    Internal function without access restriction.
     * @param  newOwner Address of the new owner
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.10;

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