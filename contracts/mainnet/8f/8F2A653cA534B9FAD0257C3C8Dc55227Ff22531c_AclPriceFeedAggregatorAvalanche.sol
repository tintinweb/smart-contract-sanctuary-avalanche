// 2a8eaf68ac21df3941127c669e34999f03871082
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "AclPriceFeedAggregatorBASE.sol";



contract AclPriceFeedAggregatorAvalanche is AclPriceFeedAggregatorBASE {
    
    address public constant AVAX = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    constructor() {
        tokenMap[AVAX] = WAVAX;   //nativeToken to wrappedToken
        tokenMap[address(0)] = WAVAX;

        priceFeedAggregator[address(0)] = 0x0A77230d17318075983913bC2145DB16C7366156;
        priceFeedAggregator[AVAX] = 0x0A77230d17318075983913bC2145DB16C7366156;// AVAX
        priceFeedAggregator[WAVAX] = 0x0A77230d17318075983913bC2145DB16C7366156;// WAVAX
        priceFeedAggregator[0x152b9d0FdC40C096757F570A51E494bd4b943E50] = 0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743;// BTC.b
        priceFeedAggregator[0x50b7545627a5162F82A992c33b87aDc75187B218] = 0x86442E3a98558357d46E6182F4b262f76c4fa26F;// WBTC.e
        priceFeedAggregator[0x8eBAf22B6F053dFFeaf46f4Dd9eFA95D89ba8580] = 0x9a1372f9b1B71B3A5a72E092AE67E172dBd7Daaa;// UNI.e
        priceFeedAggregator[0x5947BB275c521040051D82396192181b413227A3] = 0x49ccd9ca821EfEab2b98c60dC60F518E765EDe9a;// LINK.e
        priceFeedAggregator[0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E] = 0xF096872672F44d6EBA71458D74fe67F9a77a23B9;// USDC
        priceFeedAggregator[0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664] = 0xF096872672F44d6EBA71458D74fe67F9a77a23B9;// USDC.e
        priceFeedAggregator[0xd586E7F844cEa2F87f50152665BCbc2C279D8d70] = 0x51D7180edA2260cc4F6e4EebB82FEF5c3c2B8300;// DAI.e
        priceFeedAggregator[0xc7198437980c041c805A1EDcbA50c1Ce5db95118] = 0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a;// USDT.e
        priceFeedAggregator[0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7] = 0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a;// USDT
        priceFeedAggregator[0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64] = 0xbBa56eF1565354217a3353a466edB82E8F25b08e;// FRAX
        priceFeedAggregator[0x2F6F07CDcf3588944Bf4C42aC74ff24bF56e7590] = address(0);// STG
        priceFeedAggregator[0x62edc0692BD897D2295872a9FFCac5425011c661] = 0x3F968A21647d7ca81Fb8A5b69c0A452701d5DCe8;// GMX
    }
}

// 2a8eaf68ac21df3941127c669e34999f03871082
// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "Ownable.sol";

interface AggregatorV3Interface {
    function latestRoundData() external view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );

    function decimals() external view returns (uint8);
}

interface IERC20 {
    function decimals() external view returns (uint8);
}


contract AclPriceFeedAggregatorBASE is TransferOwnable{
    
    uint256 public constant DECIMALS_BASE = 18;
    mapping(address => address) public priceFeedAggregator;
    mapping(address => address) public tokenMap;

    struct PriceFeedAggregator {
        address token; 
        address priceFeed; 
    }

    event PriceFeedUpdated(address indexed token, address indexed priceFeed);
    event TokenMap(address indexed nativeToken, address indexed wrappedToken);

    function getUSDPrice(address _token) public view returns (uint256,uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAggregator[_token]);
        require(address(priceFeed) != address(0), "priceFeed not found");
        (uint80 roundId, int256 price, , uint256 updatedAt, uint80 answeredInRound) = priceFeed.latestRoundData();
        require(price > 0, "Chainlink: price <= 0");
        require(answeredInRound >= roundId, "Chainlink: answeredInRound <= roundId");
        require(updatedAt > 0, "Chainlink: updatedAt <= 0");
        return (uint256(price) , uint256(priceFeed.decimals()));
    }

    function getUSDValue(address _token , uint256 _amount) public view returns (uint256) {
        if (tokenMap[_token] != address(0)) {
            _token = tokenMap[_token];
        } 
        (uint256 price, uint256 priceFeedDecimals) = getUSDPrice(_token);
        uint256 usdValue = (_amount * uint256(price) * (10 ** DECIMALS_BASE)) / ((10 ** IERC20(_token).decimals()) * (10 ** priceFeedDecimals));
        return usdValue;
    }

    function setPriceFeed(address _token, address _priceFeed) public onlyOwner {    
        require(_priceFeed != address(0), "_priceFeed not allowed");
        require(priceFeedAggregator[_token] != _priceFeed, "_token _priceFeed existed");
        priceFeedAggregator[_token] = _priceFeed;
        emit PriceFeedUpdated(_token,_priceFeed);
    }

    function setPriceFeeds(PriceFeedAggregator[] calldata _priceFeedAggregator) public onlyOwner {    
        for (uint i=0; i < _priceFeedAggregator.length; i++) { 
            priceFeedAggregator[_priceFeedAggregator[i].token] = _priceFeedAggregator[i].priceFeed;
        }
    }

    function setTokenMap(address _nativeToken, address _wrappedToken) public onlyOwner {    
        require(_wrappedToken != address(0), "_wrappedToken not allowed");
        require(tokenMap[_nativeToken] != _wrappedToken, "_nativeToken _wrappedToken existed");
        tokenMap[_nativeToken] = _wrappedToken;
        emit TokenMap(_nativeToken,_wrappedToken);
    }


    fallback() external {
        revert("Unauthorized access");
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function _transferOwnership(address newOwner) internal virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract TransferOwnable is Ownable {
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }
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