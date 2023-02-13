// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract DonationMatching is Ownable{
    struct Pool {
        uint256 currentMatched;
        uint256 maximumMatch;
        address owner;
        uint48 deadline;
        bool closed;
        address donationAddress;
    }

    mapping(uint256 => address) public donationAddresses;
    uint256 public donationAddressCount;
    IERC20 public immutable USDC;

    mapping(bytes32 => Pool) public pools;
    mapping(bytes32 => string) public poolNames;
    mapping(bytes32 => bool) public poolExists;
    mapping(address => string) public donationAddressNames;

    event PoolCreated(bytes32 indexed poolId, address owner, uint256 maximumMatch, uint256 deadline, string name);
    event DonationMade(bytes32 indexed poolId, address donor, uint256 amount);
    event PoolClosedWithDonation(bytes32 indexed poolId, uint256 remaining, address recipient);
    event PoolClosedWithWithdraw(bytes32 indexed poolId, uint256 remaining, address recipient);
    event MaxMatchIncreased(bytes32 indexed poolId, uint256 newMaxMatch);
    event DeadlineIncreased(bytes32 indexed poolId, uint48 newDeadline);
    event DonationAddressAdded(uint256 indexed donationAddressId, address newDonationAddress);

    constructor(address _USDC) {
        USDC = IERC20(_USDC);
    }

    function addDonationAddress(address newDonationAddress, string calldata _name) external onlyOwner{
        donationAddresses[donationAddressCount] = newDonationAddress;
        donationAddressNames[newDonationAddress] = _name;

        emit DonationAddressAdded(donationAddressCount, newDonationAddress);

        unchecked {
            donationAddressCount++;
        }
    }

    function createPool(uint256 _maximumMatch, uint48 _deadline, uint256 donationAddressID, string calldata _name) external {
        bytes32 poolID = keccak256(abi.encodePacked(_name));
        address donationAdress = donationAddresses[donationAddressID];
        require(poolExists[poolID] == false, "Name already registered");
        require(_maximumMatch > 1000, "Match amount must be greater than 1000 usdc");
        require(_deadline > block.timestamp + 24 * 60 * 60, "Deadline must be at least 1 day ahead");
        require(donationAdress != address(0), "Donation to the zero address");
        require(USDC.transferFrom(msg.sender, address(this), _maximumMatch), "Transfer failed");

        pools[poolID] = Pool(0, _maximumMatch, msg.sender, _deadline, false, donationAdress);
        poolNames[poolID] = _name;
        poolExists[poolID] = true;
        
        emit PoolCreated(poolID, msg.sender, _maximumMatch, _deadline, _name);
    }

    function donateWithMatch(bytes32 poolId, uint256 amount) external {
        Pool storage pool = pools[poolId];
        require(pool.deadline > block.timestamp, "Pool has expired");
        require(pool.currentMatched < pool.maximumMatch, "Pool has been fully matched");

        if (pool.maximumMatch < pool.currentMatched + amount) {
            amount = pool.maximumMatch - pool.currentMatched;
        }
        pool.currentMatched += amount;

        bool success1 = USDC.transferFrom(msg.sender, pool.donationAddress, amount);
        bool success2 = USDC.transfer(pool.donationAddress, amount);
        require(success1 && success2, "Donation failed");
        emit DonationMade(poolId, msg.sender, amount);
    }

    function closePoolWithDonation(bytes32 poolId) external {
        Pool storage pool = pools[poolId];
        require(pool.deadline < block.timestamp, "Pool has not expired");
        require(pool.closed == false, "Pool has already been closed");
        require(pool.owner == msg.sender, "Caller is not the pool owner");
        pool.closed = true;
        uint256 remaining = pool.maximumMatch - pool.currentMatched;
        bool success = USDC.transfer(pool.donationAddress, remaining);
        require(success, "Donation failed");
        emit PoolClosedWithDonation(poolId, remaining, pool.donationAddress);
    }

    function closePoolWithWithdraw(bytes32 poolId) external {
        Pool storage pool = pools[poolId];
        require(pool.deadline < block.timestamp, "Pool has not expired");
        require(pool.closed == false, "Pool has already been closed");
        require(pool.owner == msg.sender, "Caller is not the pool owner");
        pool.closed = true;
        uint256 remaining = pool.maximumMatch - pool.currentMatched;
        bool success = USDC.transfer(pool.owner, remaining);
        require(success, "Withdraw failed");
        emit PoolClosedWithWithdraw(poolId, remaining, pool.owner);
    }

    function increaseMaxMatch(bytes32 poolId, uint256 increaseAmount) external {
        Pool storage pool = pools[poolId];
        require(pool.deadline > block.timestamp, "Pool has expired");
        pool.maximumMatch += increaseAmount;
        require(USDC.transferFrom(msg.sender, address(this), increaseAmount), "Transfer failed");
        emit MaxMatchIncreased(poolId, pool.maximumMatch);
    }

    function increaseDeadline(bytes32 poolId, uint48 increaseAmount) external {
        Pool storage pool = pools[poolId];
        require(pool.owner == msg.sender, "Caller is not the pool owner");
        require(pool.closed == false, "Pool has already been closed");
        pool.deadline += increaseAmount;
        emit DeadlineIncreased(poolId, pool.deadline);
    }

    function encode(string memory _name) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_name));
    }
}