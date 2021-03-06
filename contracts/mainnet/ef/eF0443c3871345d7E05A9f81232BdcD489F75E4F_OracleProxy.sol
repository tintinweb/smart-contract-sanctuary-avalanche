/**
 *Submitted for verification at snowtrace.io on 2022-03-11
*/

/**
 *Submitted for verification at snowtrace.io on 2022-03-11
*/

// File: contracts/interfaces/IOracle.sol
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

/**
 * @title BiFi's oracle interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IOracle {
  function latestAnswer() external view returns (int256);
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

interface IBscChainlinkOracle {
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

// File: contracts/interfaces/IOracleProxy.sol
pragma solidity 0.6.12;

/**
 * @title BiFi's oracle proxy interface
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
interface IOracleProxy  {
	function getTokenPrice(uint256 tokenID) external view returns (uint256);

	function getOracleFeed(uint256 tokenID) external view returns (address, uint256);
	function setOracleFeed(uint256 tokenID, address feedAddr, uint256 decimals, bool needPriceConvert, uint256 priceConvertID) external returns (bool);
}

// File: contracts/Errors.sol
pragma solidity 0.6.12;

contract Modifier {
    string internal constant ONLY_OWNER = "O";
    string internal constant ONLY_MANAGER = "M";
    string internal constant CIRCUIT_BREAKER = "emergency";
}

contract ManagerModifier is Modifier {
    string internal constant ONLY_HANDLER = "H";
    string internal constant ONLY_LIQUIDATION_MANAGER = "LM";
    string internal constant ONLY_BREAKER = "B";
}

contract HandlerDataStorageModifier is Modifier {
    string internal constant ONLY_BIFI_CONTRACT = "BF";
}

contract SIDataStorageModifier is Modifier {
    string internal constant ONLY_SI_HANDLER = "SI";
}

contract HandlerErrors is Modifier {
    string internal constant USE_VAULE = "use value";
    string internal constant USE_ARG = "use arg";
    string internal constant EXCEED_LIMIT = "exceed limit";
    string internal constant NO_LIQUIDATION = "no liquidation";
    string internal constant NO_LIQUIDATION_REWARD = "no enough reward";
    string internal constant NO_EFFECTIVE_BALANCE = "not enough balance";
    string internal constant TRANSFER = "err transfer";
}

contract SIErrors is Modifier { }

contract InterestErrors is Modifier { }

contract LiquidationManagerErrors is Modifier {
    string internal constant NO_DELINQUENT = "not delinquent";
}

contract ManagerErrors is ManagerModifier {
    string internal constant REWARD_TRANSFER = "RT";
    string internal constant UNSUPPORTED_TOKEN = "UT";
}

contract OracleProxyErrors is Modifier {
    string internal constant ZERO_PRICE = "price zero";
}

contract RequestProxyErrors is Modifier { }

contract ManagerDataStorageErrors is ManagerModifier {
    string internal constant NULL_ADDRESS = "err addr null";
}

// File: contracts/oracle/OracleProxy.sol
// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.6.12;

/**
 * @title BiFi's OracleProxy Contract
 * @notice Communicate with the contract that
 * provides the price of token
 * @author BiFi(seinmyung25, Miller-kk, tlatkdgus1, dongchangYoo)
 */
contract OracleProxy is IOracleProxy, OracleProxyErrors {
	address payable owner;

	mapping(uint256 => Oracle) oracle;

	struct Oracle {
		IOracle feed;
		uint256 feedUnderlyingPoint;

		bool needPriceConvert;
		uint256 priceConvertID;
	}

	uint256 constant unifiedPoint = 10 ** 18;

	uint256 constant defaultUnderlyingPoint = 8;

	modifier onlyOwner {
		require(msg.sender == owner, ONLY_OWNER);
		_;
	}

	/**
	* @dev Construct a new OracleProxy which manages many oracles
	* @param avaxOracle The address of avax's oracle contract
	* @param etherOracle The address of ether's oracle contract
	* @param usdtOracle The address of usdt's oracle contract
    * @param usdcOracle The address of usdc's oracle contract
	* @param daiOracle The address of dai's oracle contract
	* @param btcOracle The address of btc's oracle contract
	*/
	constructor (address avaxOracle, address etherOracle, address usdtOracle, address usdcOracle, address daiOracle, address btcOracle) public
	{
		owner = msg.sender;
		_setOracleFeed(0, avaxOracle, 8, false, 0);
        _setOracleFeed(1, etherOracle, 8, false, 0);
		_setOracleFeed(2, usdtOracle, 8, false, 0);
		_setOracleFeed(3, usdcOracle, 8, false, 0);
		_setOracleFeed(4, daiOracle, 8, false, 0);
		_setOracleFeed(5, btcOracle, 8, false, 0);
	}

	/**
	* @dev Replace the owner of the handler
	* @param _owner the address of the owner to be replaced
	* @return true (TODO: validate results)
	*/
	function ownershipTransfer(address payable _owner) onlyOwner public returns (bool)
	{
		owner = _owner;
		return true;
	}

	/**
	* @dev Gets information about the linked token Oracle.
	* @param tokenID The ID of get token Oracle information
	* @return the address of the token oracle feed and the decimal of the actual token.
	*/
	function getOracleFeed(uint256 tokenID) external view override returns (address, uint256)
	{
		return _getOracleFeed(tokenID);
	}

	/**
	* @dev Set information about the linked token Oracle.
	* @param tokenID tokenID to set token Oracle information
	* @param feedAddr the address of the feed contract
	* that provides the price of the token
	* @param decimals Decimal of the token
	* @return true (TODO: validate results)
	*/
	function setOracleFeed(uint256 tokenID, address feedAddr, uint256 decimals, bool needPriceConvert, uint256 priceConvertID) onlyOwner external override returns (bool)
	{
		return _setOracleFeed(tokenID, feedAddr, decimals, needPriceConvert, priceConvertID);
	}

	/**
	* @dev Gets information about the linked token Oracle.
	* @param tokenID The ID of get token Oracle information
	* @return the address of the token oracle feed and the decimal of the actual token.
	*/
	function _getOracleFeed(uint256 tokenID) internal view returns (address, uint256)
	{
		Oracle memory _oracle = oracle[tokenID];
		address addr = address(_oracle.feed);
		return (addr, _oracle.feedUnderlyingPoint);
	}

	/**
	* @dev Set information about the linked token Oracle.
	* @param tokenID tokenID to set token Oracle information
	* @param feedAddr the address of the feed contract
	* that provides the price of the token
	* @param decimals Decimal of the token
	* @param needPriceConvert true for this oracle feed is not USD, need convert
	* @param priceConvertID convert price feed id(registered)
	* @return true (TODO: validate results)
	*/
	function _setOracleFeed(uint256 tokenID, address feedAddr, uint256 decimals, bool needPriceConvert, uint256 priceConvertID) internal returns (bool)
	{
		Oracle memory _oracle;
		_oracle.feed = IOracle(feedAddr);
		_oracle.feedUnderlyingPoint = (10 ** decimals);

		_oracle.needPriceConvert = needPriceConvert;
		_oracle.priceConvertID = priceConvertID;
		oracle[tokenID] = _oracle;
		return true;
	}

	/**
	* @dev The price of the token is obtained through the price feed contract.
	* @param tokenID The ID of the token that will take the price.
	* @return The token price of a uniform unit.
	*/
	function getTokenPrice(uint256 tokenID) external view override returns (uint256)
	{

		Oracle memory _oracle = oracle[tokenID];
		(,int256 underlyingPrice,,,) = _oracle.feed.latestRoundData();
        require(underlyingPrice > 0, "underlyingPrice latestRoundData Problem");
		uint256 unifiedPrice = _convertPriceToUnified(uint256(underlyingPrice), _oracle.feedUnderlyingPoint);

		if (_oracle.needPriceConvert)
		{
			_oracle = oracle[_oracle.priceConvertID];
            (,int256 convertFeedUnderlyingPrice,,,) = _oracle.feed.latestRoundData();
            require(convertFeedUnderlyingPrice > 0, "convertFeedUnderlyingPrice latestRoundData Problem");
			uint256 convertPrice = _convertPriceToUnified(uint256(convertFeedUnderlyingPrice), oracle[0].feedUnderlyingPoint);
			unifiedPrice = unifiedMul(unifiedPrice, convertPrice);
		}

		require(unifiedPrice != 0, ZERO_PRICE);
		return unifiedPrice;
	}

	/**
	* @dev Get owner's address in manager contract
	* @return The address of owner
	*/
	function getOwner() public view returns (address)
	{
		return owner;
	}

	/**
	* @dev Unify the decimal value of the token price returned by price feed oracle.
	* @param price token price without unified of decimal
	* @param feedUnderlyingPoint Decimal of the token
	* @return The price of tokens with unified decimal
	*/
	function _convertPriceToUnified(uint256 price, uint256 feedUnderlyingPoint) internal pure returns (uint256)
	{
		return div(mul(price, unifiedPoint), feedUnderlyingPoint);
	}

	/* **************** safeMath **************** */
	function mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _mul(a, b);
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(a, b, "div by zero");
	}

	function _mul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		if (a == 0)
		{
			return 0;
		}

		uint256 c = a * b;
		require((c / a) == b, "mul overflow");
		return c;
	}

	function _div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256)
	{
		require(b > 0, errorMessage);
		return a / b;
	}

	function unifiedMul(uint256 a, uint256 b) internal pure returns (uint256)
	{
		return _div(_mul(a, b), unifiedPoint, "unified mul by zero");
	}
}