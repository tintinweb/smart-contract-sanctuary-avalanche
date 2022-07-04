// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

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

interface AggregatorV3Interface {
    function latestRoundData() external view returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    );
}

contract FiatContract is Ownable {
    event SetPrice(string[] _symbols, uint256[] _token2USD, address _from);
    using SafeMath for uint256;

    struct Token {
        string symbol;
        uint256 token2USD;
        bool existed;
    }
    
    struct Asset {
        string symbol;
        address asset;
        AggregatorV3Interface priceFeed;
    }

    mapping(string => Token) private tokens;
    mapping(string => Asset) private assets;
    address public manager;

    constructor() {
        manager = _msgSender();
        _setAsset("AVAX", address(0), 0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);        
    }

    string[] public tokenArr;
    uint256 public mulNum = 2;
    uint256 public lastCode = 3;
    uint256 public callTime = 1;
    uint256 public baseTime = 3;
    uint256 public plusNum = 1;
    
    modifier onlyManager() {
        require(_msgSender() == manager || _msgSender() == owner());
        _;
    }

    function getLatestPrice(string memory _symbol) public view returns (int) {
        (, int256 _price, , , ) = assets[_symbol].priceFeed.latestRoundData();
        return _price * 10**10;
    }

    function setPrice(
        string[] memory _symbols,
        uint256[] memory _token2USD,
        uint256 _code
    ) public onlyManager {
        require(_code == findNumber(lastCode));
        for (uint256 i = 0; i < _symbols.length; i++) {
            _setPrice(_symbols[i], _token2USD[i]);
        }
        emit SetPrice(_symbols, _token2USD, _msgSender());
    }

    function _setPrice(string memory _symbol, uint256 _token2USD) private {
        tokens[_symbol].token2USD = _token2USD;
            if (!tokens[_symbol].existed) {
                tokenArr.push(_symbol);
                tokens[_symbol].existed = true;
                tokens[_symbol].symbol = _symbol;
            }
    }

    function getTokenArr() public view returns (string[] memory) {
        return tokenArr;
    }

    function setAssets(string[] memory _symbols, address[] memory _assets, address[] memory _priceFeeds) public onlyOwner {
        require(_symbols.length == _assets.length && _symbols.length == _priceFeeds.length, "Length mismatch!");
        for(uint i = 0; i < _symbols.length; i++) {
            _setAsset(_symbols[i], _assets[i], _priceFeeds[i]);
        }
    }

    function _setAsset(string memory symbol, address asset, address priceFeed) private {
        assets[symbol] = Asset(symbol, asset, AggregatorV3Interface(priceFeed));
    }

    function usd2Asset(string memory _symbol, uint _amountUSD) public view returns(uint _amountAsset) {
        return _amountUSD.mul(1 ether).div(uint(getLatestPrice(_symbol)));
    }

    function getToken2USD(string memory _symbol) public view returns (string memory _symbolToken, uint256 _token2USD) {
        uint256 token2USD;
        if(assets[_symbol].priceFeed != AggregatorV3Interface(address(0))) token2USD = usd2Asset(_symbol, 1 ether);
        else token2USD = tokens[_symbol].token2USD;
        return (tokens[_symbol].symbol, token2USD);
    }

    function setInput(
        uint256 _mulNum,
        uint256 _lastCode,
        uint256 _callTime,
        uint256 _baseTime,
        uint256 _plusNum
    ) public onlyOwner {
        mulNum = _mulNum;
        lastCode = _lastCode;
        callTime = _callTime;
        baseTime = _baseTime;
        plusNum = _plusNum;
    }


    function findNumber(uint256 a) internal returns (uint256) {
        uint256 b = a.mul(mulNum) - plusNum;
        if (callTime % 3 == 0) {
            for (uint256 i = 0; i < baseTime; i++) {
                b += (a + plusNum) / mulNum;
            }
            b = b / baseTime + plusNum;
        }
        if (b > 9293410619286421) {
            mulNum = callTime % 9 == 1 ? 2 : callTime % 9;
            b = 3;
        }
        ++callTime;
        lastCode = b;
        return b;
    }

    function setManager(address _newManager) public onlyOwner {
        manager = _newManager;
    }
}