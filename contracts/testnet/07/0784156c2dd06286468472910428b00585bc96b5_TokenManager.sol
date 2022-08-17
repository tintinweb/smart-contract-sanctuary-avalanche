/**
 *Submitted for verification at testnet.snowtrace.io on 2022-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Strings {
    function _indexOf(
        string memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int256(i);
            }
        }
        return -1;
    }

    function length(string memory _base) internal pure returns (uint256) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr)
    {
        bytes memory _baseBytes = bytes(_base);

        uint256 _offset = 0;
        uint256 _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) break;
            else {
                _splitsCount++;
                _offset = uint256(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int256(_baseBytes.length);
            }

            string memory _tmp = new string(uint256(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint256 j = 0;
            for (uint256 i = _offset; i < uint256(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint256(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}


contract TokenManager {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;
    IERC20 public token;
    address public admin;
    address public distributionPool;
    address public collector;
    address public updater;

    struct NodeEntity {
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 rewardAvailable;
        uint256 claimed;
        uint256 total;
    }

    IterableMapping.Map private nodeOwners;
    mapping(address => NodeEntity[]) public _nodesOfUser;
    uint256 size = 4;
    uint256 public bonusRate = 10;
    uint256 public claimTime = 60;
    uint256 public tokenPrice = 54062900;
    uint256 public maxDuration = 300;
    AggregatorV3Interface internal priceFeed;

    event SetAggregator(address _aggregator);
    event BoughtZeus(string nodeId, uint256 dueDate);


    constructor (address tokenAddress) {
            // 0x0A77230d17318075983913bC2145DB16C7366156
        token = IERC20(tokenAddress);
        priceFeed = AggregatorV3Interface(0x5498BB86BC934c8D34FDA08E81D444153d0D06aD);
        admin = msg.sender;
    }

    function updateBonusRate(uint256 rate) public {
        bonusRate = rate;
    }

    modifier onlySentry() {
        require(
                msg.sender == admin,
            "NOT AUTHORIZED"
        );
        _;
    }

    modifier onlyUpdater() {
        require(msg.sender == updater || msg.sender == admin, "NOT AUTHORIZED");
        _;
    }

    function setToken(address tokenAddress) external onlySentry {
        token = IERC20(tokenAddress);
    }

    function setUpdater(address updater_) external onlySentry{
        updater = updater_;
    }

    function updateDistributionPool(address newAddress) external onlySentry {
        distributionPool = newAddress;
    }

    function setAggregator(address _aggregator) external onlySentry {
        priceFeed = AggregatorV3Interface(_aggregator);
        emit SetAggregator(_aggregator);
    }

    function setTokenPrice(uint256 amount) external onlyUpdater {
        tokenPrice = amount;
    }
    
    function setMaxDuration(uint256 duration) external onlySentry {
        maxDuration = duration;
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

    function buyZeus(
        uint256 total
    ) payable external {
        address account = msg.sender;

        uint256 price = (tokenPrice * 10**18) / _getCurrentPrice();
        uint256 priceBonus = price - price.mul(bonusRate).div(100);
        uint256 totalFee = priceBonus * total;
        uint256 feeThreshold = totalFee.sub(100000000000000);
        require(msg.value >= feeThreshold, "Insufficient fee");
           _nodesOfUser[account].push(
                    NodeEntity({
                        creationTime: block.timestamp,
                        lastClaimTime: block.timestamp,
                        rewardAvailable: total,
                        claimed: 0,
                        total: total
                    })
                );
    }

    function getPrice(uint256 total) external view returns(uint256){
        uint256 price = (tokenPrice * 10**18) / _getCurrentPrice();
        uint256 priceBonus = price - price.mul(bonusRate).div(100);
        uint256 totalFee = priceBonus * total;
        return totalFee;
    }

    function _getNodeWithCreatime(
        NodeEntity[] storage nodes,
        uint256 _creationTime
    ) private view returns (NodeEntity storage, uint256) {
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        bool found = false;
        int256 index = binary_search(nodes, 0, numberOfNodes, _creationTime);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        return (nodes[validIndex], validIndex);
    }

    function binary_search(
        NodeEntity[] memory arr,
        uint256 low,
        uint256 high,
        uint256 x
    ) private view returns (int256) {
        if (high >= low) {
            uint256 mid = (high + low).div(2);
            if (arr[mid].creationTime == x) {
                return int256(mid);
            } else if (arr[mid].creationTime > x) {
                return binary_search(arr, low, mid - 1, x);
            } else {
                return binary_search(arr, mid + 1, high, x);
            }
        } else {
            return -1;
        }
    }

    function _calculateReward(NodeEntity memory node)
        private
        view
        returns (uint256)
    {
        uint256 nodeTotal = node.total * 10 ** 18;
        uint256 nodeRewardAvailable = node.rewardAvailable * 10 ** 18;
        uint256 distribution = maxDuration.div(claimTime);
        uint256 toDeposit = nodeTotal.div(distribution); 
        uint256 claims = 0;
        if(node.rewardAvailable > 0) {
            uint256 lastClaim = node.lastClaimTime;
            uint256 currentTime = block.timestamp;
            if (lastClaim == 0) {
                claims = toDeposit;
                lastClaim = node.creationTime;
            }
            uint256 _claims = (currentTime.sub(lastClaim)).div(claimTime).mul(toDeposit);
            claims = claims.add(_claims);
            if(claims > nodeRewardAvailable) {
                claims = nodeRewardAvailable;
            }
        }
        return claims;
    }

    function cashoutNodeReward(uint256 _creationTime)
        public
    {
        address account = msg.sender;
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(numberOfNodes > 0, "Not a node owner");

        (NodeEntity storage node, uint256 index) = _getNodeWithCreatime(
            nodes,
            _creationTime
        );
        uint256 tokenRewards = _calculateReward(node);
        nodes[index].lastClaimTime = block.timestamp;
        nodes[index].rewardAvailable -= tokenRewards;
        nodes[index].claimed += tokenRewards;
        token.transferFrom(distributionPool, account, tokenRewards);
    }

    function cashoutAllNodesReward()
        public
    {
        address account = msg.sender;
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        uint256 tokenTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            uint256 tokenRewards = _calculateReward(nodes[i]);
            tokenTotal += tokenRewards;
            nodes[i].lastClaimTime = block.timestamp;
            nodes[i].rewardAvailable -= tokenRewards;
            nodes[i].claimed += tokenRewards;
        
        }
        token.transferFrom(distributionPool, account, tokenTotal);
    }

 

    function claimable(NodeEntity memory node) private view returns (bool) {
        return node.lastClaimTime + claimTime <= block.timestamp;
    }

    function _getRewardAmountOf(address account) internal view returns (uint256) {
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            rewardCount += _calculateReward(nodes[i]);
        }
        return rewardCount;
    }

    function _getNodeRewardAmountOf(address account, uint256 creationTime)
        internal
        view
        returns (uint256)
    {
        (NodeEntity memory _node, ) = _getNodeWithCreatime(
            _nodesOfUser[account],
            creationTime
        );

        return _calculateReward(_node);
    }

    function getNodesCreationTime(address account)
        external
        view
        returns (string memory)
    {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _creationTimes = uint2str(nodes[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _creationTimes = string(
                abi.encodePacked(
                    _creationTimes,
                    separator,
                    uint2str(_node.creationTime)
                )
            );
        }
        return _creationTimes;
    }

      function getTokensClaimed(address account)
        external
        view
        returns (string memory)
    {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory claims = uint2str(nodes[0].claimed);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            claims = string(
                abi.encodePacked(
                    claims,
                    separator,
                    uint2str(_node.claimed)
                )
            );
        }
        return claims;
    }

    function getNodesRewardAvailable(address account)
        external
        view
        returns (string memory)
    {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _rewardsAvailable = uint2str(
            _getNodeRewardAmountOf(account, nodes[0].creationTime)
        );
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    separator,
                    uint2str(_getNodeRewardAmountOf(account, _node.creationTime))
                )
            );
        }
        return _rewardsAvailable;
    }

    function getTokensBought(address account)
        external
        view
        returns (string memory)
    {
             NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _total = uint2str(nodes[0].total);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _total = string(
                abi.encodePacked(
                    _total,
                    separator,
                    uint2str(_node.total)
                )
            );
        }
        return _total;
    }

    function transferReward() external onlySentry {
        payable(collector).transfer(address(this).balance);
    }

    function updateCollector(address collector_) external onlySentry {
        collector = collector_;
    }

    function getNodesLastClaimTime(address account)
        external
        view
        returns (string memory)
    {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _lastClaimTimes = uint2str(nodes[0].lastClaimTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _lastClaimTimes = string(
                abi.encodePacked(
                    _lastClaimTimes,
                    separator,
                    uint2str(_node.lastClaimTime)
                )
            );
        }
        return _lastClaimTimes;
    }


    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function _changeClaimTime(uint256 newTime) external onlySentry {
        claimTime = newTime;
    }

    function getUserNodes(address account) external view returns (uint256) {
        return _nodesOfUser[account].length;
    }
}