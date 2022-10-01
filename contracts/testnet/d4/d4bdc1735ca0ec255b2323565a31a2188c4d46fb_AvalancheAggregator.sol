/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-30
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

library Roles {
    struct Role {
        mapping(address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account)
        internal
        view
        returns (bool)
    {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract AvalancheAggregator is AggregatorV3Interface {
    using Roles for Roles.Role;

    // Constants
    string private constant feedName = "AVAX:USD";
    uint256 private constant priceMaxLifetimeSeconds = 1800; // 30 minutes

    // Price
    uint8 private lastDecimals = 0;
    int256 private lastAnswer = 0;
    uint256 private lastUpdateReportedTime = 0;
    uint256 private lastUpdateBlockTime = 0;
    uint80 private lastRoundNumber = 0;

    // Updaters
    Roles.Role private allowedUpdaters;

    // Events
    event AnswerSubmitted(uint8 decimals, int256 answer, uint256 reportedTimestamp, uint256 blockTimestamp);

    constructor() {
        allowedUpdaters.add(msg.sender);
    }

    function decimals() external view override returns (uint8) {
        require(block.timestamp - lastUpdateReportedTime <= priceMaxLifetimeSeconds, "No recent answers.");
        require(block.timestamp - lastUpdateBlockTime <= priceMaxLifetimeSeconds, "No recent answers.");
        return lastDecimals;
    }

    function description() external pure override returns (string memory) {
        return string.concat("SGX powered price feed for ", feedName);
    }

    function version() external pure override returns (uint256) {
        return 1;
    }

    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
        require((block.timestamp < lastUpdateReportedTime) || (block.timestamp - lastUpdateReportedTime <= priceMaxLifetimeSeconds), "No recent answers.");
        require(block.timestamp - lastUpdateBlockTime <= priceMaxLifetimeSeconds, "No recent answers.");
        return (
            lastRoundNumber,
            lastAnswer,
            lastUpdateReportedTime,
            lastUpdateReportedTime,
            lastRoundNumber
        );
    }

    function getRoundData(uint80 _roundId)
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        ) {
        require(_roundId == lastRoundNumber, "Sorry, can only get the latest round data.");
        require((block.timestamp < lastUpdateReportedTime) || (block.timestamp - lastUpdateReportedTime <= priceMaxLifetimeSeconds), "No recent answers.");
        require(block.timestamp - lastUpdateBlockTime <= priceMaxLifetimeSeconds, "No recent answers.");
        return (
            lastRoundNumber,
            lastAnswer,
            lastUpdateReportedTime,
            lastUpdateReportedTime,
            lastRoundNumber
        );
    }

    function setAnswer(uint8 decimalsAnswer, int256 answer, uint256 reportedTimestamp) external {
        require(allowedUpdaters.has(msg.sender), "Unauthorized.");
        require(reportedTimestamp > lastUpdateReportedTime, "Stale reported timestamp.");
        require((block.timestamp < reportedTimestamp) || (block.timestamp - reportedTimestamp <= priceMaxLifetimeSeconds), "Answer already stale.");
        lastDecimals = decimalsAnswer;
        lastAnswer = answer;
        lastUpdateReportedTime = reportedTimestamp;
        lastUpdateBlockTime = block.timestamp;
        lastRoundNumber += 1;
    }
}