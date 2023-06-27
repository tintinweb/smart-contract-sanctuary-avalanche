/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
}

contract TokenPresale {
    address private constant USDT_ADDRESS = 0x82DCEC6aa3c8BFE2C96d40d8805EE0dA15708643;
    address private constant PRESALE_TOKEN_ADDRESS = 0x2f6693Bb09AcfE6689E8Fd2C3727050d69efA460;
    uint256 public constant PHASE_DURATION = 7 days;
    uint256 public constant TOTAL_PHASES = 22;

    uint256[TOTAL_PHASES] public phasePrices = [
        530000000000000000, 710000000000000000, 950000000000000000, 1240000000000000000, 1580000000000000000, 
        1980000000000000000, 2430000000000000000, 2920000000000000000, 3440000000000000000, 3960000000000000000, 
        4470000000000000000, 4930000000000000000, 5320000000000000000, 6580000000000000000, 7830000000000000000, 
        9090000000000000000, 10340000000000000000, 11600000000000000000, 12850000000000000000, 14110000000000000000, 
        15360000000000000000, 16620000000000000000
    ];

    uint256[TOTAL_PHASES] public phaseAllocations = [
        33000000 * 10**18, 33000000 * 10**18, 33000000 * 10**18, 33000000 * 10**18, 33000000 * 10**18,
        33000000 * 10**18, 33000000 * 10**18, 33000000 * 10**18, 33000000 * 10**18, 33000000 * 10**18,
        33000000 * 10**18, 33000000 * 10**18, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    ];

    uint256[TOTAL_PHASES] public phaseBonuses = [
        30, 26, 23, 21, 19, 17, 15, 13, 11, 9, 7, 5, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    ];

    uint256 public remainAllocation = 0;
    uint256 public stageStartAt = 0;

    mapping(address => uint256) public claimableAmount;

    bool public locked;
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier notLocked() {
        require(!locked, "Presale has been locked");
        _;
    }

    function lock() public onlyOwner {
        locked = true;
    }

    function unlock() public onlyOwner {
        locked = false;
    }

    function start(uint256 timestamp) public onlyOwner {
        stageStartAt = timestamp;
    }

    function buy(uint256 amount) public notLocked {
        uint256 currentTimestamp = block.timestamp;
        require(currentTimestamp < stageStartAt, "Presale not started");
        require(stageStartAt != 0, "Presale not started.0");

        uint256 currentStage = ( currentTimestamp - stageStartAt ) / ( PHASE_DURATION );  // first = 0
        require(currentStage < TOTAL_PHASES, "Presale is ended");

        uint256 price = phasePrices[currentStage];
        uint256 bonus = phaseBonuses[currentStage];
        uint256 allocation = phaseAllocations[currentStage];
        if ( currentStage > 11 ) {
            if ( remainAllocation == 0 ) {
                for (uint256 i=0; i<12; i++) {
                    allocation = phaseAllocations[i];
                }
            } else {
                allocation = remainAllocation;
            }
        }

        uint256 bonusAmount = amount / 100 * bonus;
        uint256 totalAmount = amount + bonusAmount;

        require(allocation > 0, "Phase allocation has been sold");
        require(allocation >= totalAmount, "Phase allocation has been sold");

        
        IERC20 usdt = IERC20(USDT_ADDRESS);
        uint256 contractBalance = usdt.balanceOf(msg.sender);
        require(contractBalance >= totalAmount*price, "User does not have enough USDT");
        require(usdt.transferFrom(msg.sender, address(this), totalAmount*price), "USDT Transfer failed");
        // USDT.transferFrom(msg.sender, this, totalAmount*price);

        claimableAmount[msg.sender] += totalAmount;
        phaseAllocations[currentStage] -= totalAmount / price;
    }

    function claim() public {
        uint256 currentTimestamp = block.timestamp;
        require(currentTimestamp > stageStartAt, "Presale not started");
        require(stageStartAt != 0, "Presale not started.0");

        uint256 currentStage = ( currentTimestamp - stageStartAt ) / ( PHASE_DURATION );  // first = 0
        require(currentStage > TOTAL_PHASES, "Presale is not ended");


        IERC20 presaleToken = IERC20(PRESALE_TOKEN_ADDRESS);
        require(presaleToken.transfer(msg.sender, claimableAmount[msg.sender]), "PresaleToken Transfer failed");
        claimableAmount[msg.sender] = 0;
    }

    function withdraw() public onlyOwner {
        IERC20 usdt = IERC20(USDT_ADDRESS);
        require(usdt.transferFrom(address(this), msg.sender, usdt.balanceOf(address(this))), "USDT Transfer failed");
    }
}