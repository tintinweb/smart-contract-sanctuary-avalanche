// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.12;

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

interface IMasterOfCoinV1 {
    function getDueDate(string memory nodeId) external view returns (uint256);
}

contract MasterOfCoin {
    using SafeMath for uint256;
    AggregatorV3Interface internal priceFeed;
    IMasterOfCoinV1 internal masterOfCoinV1;

    mapping(string => uint256) public dueDates;
    uint256 public baseDueDate;
    uint256 v1BaseDueDate = 1649118196;

    uint256 public feeCycle = 30 days;

    mapping(string => bool) taxed;

    struct NodeTier {
        string name;
        uint256 fee;
        uint256 restoreFee;
    }

    mapping(string => NodeTier) public tiers;

    address public owner;
    address public bifrost;
    address public collector = 0x8e2ff009Df7D3611efAF1AAE63A05020669fdCF8;

    // Events
    event AddedTier(string name, uint256 fee, uint256 restoreFee);

    event RemovedTier(string name);

    event SetAggregator(address _aggregator);

    event PaidFee(string nodeId, uint256 dueDate);

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
        bifrost = _bifrost;
        priceFeed = AggregatorV3Interface(
            0x0A77230d17318075983913bC2145DB16C7366156
        );
        masterOfCoinV1 = IMasterOfCoinV1(
            0x8748fEb50B6713ae0AA08314567F5bad962e96Ac
        );
        addTier("HEIMDALL", 5, 28);
        addTier("FREYA", 10, 140);
        addTier("THOR", 20, 281);
        addTier("ODIN", 80, 1758);
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

    function setAggregator(address _aggregator) external onlyOwner {
        priceFeed = AggregatorV3Interface(_aggregator);
        emit SetAggregator(_aggregator);
    }

    function blockTime() external view returns (uint256) {
        return block.timestamp;
    }

    function _getDueDate(string memory nodeId) internal view returns (uint256) {
        if (dueDates[nodeId] > 0) {
            return dueDates[nodeId];
        } else {
            uint256 v1DueDate = masterOfCoinV1.getDueDate(nodeId);
            return v1DueDate != v1BaseDueDate ? v1DueDate : baseDueDate;
        }
    }

    function getDueDate(string memory nodeId) external view returns (uint256) {
        return _getDueDate(nodeId);
    }

    function _payFee(string memory nodeId) internal {
        require(!_isDelinquent(nodeId), "Node has expired, pay restore fee");
        uint256 currentDueDate = _getDueDate(nodeId);
        dueDates[nodeId] = currentDueDate.add(feeCycle);
        emit PaidFee(nodeId, dueDates[nodeId]);
    }

    function payFee(string memory nodeId) external onlyBifrost {
        dueDates[nodeId] = block.timestamp + feeCycle;
        emit PaidFee(nodeId, dueDates[nodeId]);
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
        emit PaidFee(nodeId, dueDates[nodeId]);
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

        uint256 dueDate = _getDueDate(nodeId);
        uint256 missedFees = uint256(block.timestamp - dueDate)
            .div(feeCycle)
            .mul((tier.fee * 10**8 * 10**18) / _getCurrentPrice());

        return
            ((tier.restoreFee * 10**8 * 10**18) / _getCurrentPrice()) +
            missedFees;
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
    ) public onlyOwner {
        tiers[name] = NodeTier({name: name, fee: fee, restoreFee: restoreFee});
        emit AddedTier(name, fee, restoreFee);
    }

    function removeTier(string memory name) external onlyOwner {
        delete tiers[name];
        emit RemovedTier(name);
    }

    function _isDelinquent(string memory nodeId) internal view returns (bool) {
        uint256 dueDate = _getDueDate(nodeId);

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

        return (tiers[tierName].fee * 10**8 * 10**18) / _getCurrentPrice();
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