// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

contract MasterOfCoin {
    using SafeMath for uint256;
    AggregatorV3Interface internal priceFeed;

    mapping(string => uint256) public dueDates;
    uint256 baseDueDate;
    uint256 public feeCycle = 1 hours;

    mapping(string => bool) taxed;

    struct NodeTier {
        string name;
        uint256 fee;
        uint256 restoreFee;
    }

    mapping(string => NodeTier) public tiers;

    address owner;
    address bifrost;
    address collector = 0x8e2ff009Df7D3611efAF1AAE63A05020669fdCF8;

    // M O D I F I E R S
    modifier onlyOwner() {
        require(msg.sender == owner, "Fuck off");
        _;
    }

    modifier onlyBifrost() {
        require(msg.sender == bifrost, "Fuck off");
        _;
    }

    constructor(address _bifrost) {
        owner = msg.sender;
        baseDueDate = block.timestamp + feeCycle;
        bifrost = _bifrost;
        priceFeed = AggregatorV3Interface(
            // 0x0A77230d17318075983913bC2145DB16C7366156 // mainnet
            0x5498BB86BC934c8D34FDA08E81D444153d0D06aD // testnet
        );
    }

    function _getCurrentPrice() internal view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function blockTime() external view returns (uint256) {
        return block.timestamp;
    }

    function getDueDate(string memory nodeId) external view returns (uint256) {
        return dueDates[nodeId] > 0 ? dueDates[nodeId] : baseDueDate;
    }

    function _payFee(string memory nodeId) internal {
        require(!_isDelinquent(nodeId), "Node has expired, pay restore fee");
        dueDates[nodeId] = dueDates[nodeId] != 0
            ? uint256(dueDates[nodeId]).add(feeCycle)
            : baseDueDate.add(feeCycle);
    }

    function payFee(string memory nodeId) external onlyBifrost {
        dueDates[nodeId] = block.timestamp + feeCycle;
    }

    function payFee(string memory nodeId, string memory tierName)
        external
        payable
    {
        NodeTier memory tier = tiers[tierName];
        require(
            msg.value >= ((tier.fee * 10**8 * 10**18) / _getCurrentPrice()),
            "Amount less than fee"
        );
        _payFee(nodeId);
    }

    function payFees(string[] memory nodeIds, string memory tierName)
        external
        payable
    {
        NodeTier memory tier = tiers[tierName];
        require(
            msg.value >=
                nodeIds.length.mul(
                    (tier.fee * 10**8 * 10**18) / _getCurrentPrice()
                ),
            "Amount less than fee"
        );
        for (uint256 i = 0; i < nodeIds.length; i++) {
            _payFee(nodeIds[i]);
        }
    }

    function _calcRestoreFee(string memory nodeId, string memory tierName)
        internal
        view
        returns (uint256)
    {
        NodeTier memory tier = tiers[tierName];

        uint256 dueDate = dueDates[nodeId] > 0 ? dueDates[nodeId] : baseDueDate;
        uint256 missedFees = uint256(block.timestamp - dueDate)
            .div(feeCycle)
            .mul((tier.fee * 10**8 * 10**18) / _getCurrentPrice());

        return tier.restoreFee + missedFees;
    }

    function restoreNode(string memory nodeId, string memory tierName)
        external
        payable
        onlyBifrost
    {
        uint256 totalFee = _calcRestoreFee(nodeId, tierName);

        require(msg.value >= totalFee, "Amount less than fee");
        dueDates[nodeId] = block.timestamp + feeCycle;
    }

    function addTier(
        string memory name,
        uint256 fee,
        uint256 restoreFee
    ) external onlyOwner {
        tiers[name] = NodeTier({name: name, fee: fee, restoreFee: restoreFee});
    }

    function removeTier(string memory name) external onlyOwner {
        delete tiers[name];
    }

    function _isDelinquent(string memory nodeId) internal view returns (bool) {
        uint256 dueDate = dueDates[nodeId] != 0
            ? dueDates[nodeId]
            : baseDueDate;

        return block.timestamp > dueDate;
    }

    function isDelinquent(string memory nodeId) external view returns (bool) {
        return _isDelinquent(nodeId);
    }

    function getFee(string memory nodeId, string memory tierName)
        public
        view
        returns (uint256)
    {
        if (_isDelinquent(nodeId)) {
            return _calcRestoreFee(nodeId, tierName);
        }

        return tiers[tierName].fee;
    }

    function withdrawFees() external onlyOwner {
        payable(collector).transfer(address(this).balance);
    }

    function updateFeeCycle(uint256 time) external onlyOwner {
        feeCycle = time;
    }

    function updateOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function updateBifrost(address newBifrost) external onlyOwner {
        bifrost = newBifrost;
    }

    function updateCollector(address newCollector) external onlyOwner {
        collector = newCollector;
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