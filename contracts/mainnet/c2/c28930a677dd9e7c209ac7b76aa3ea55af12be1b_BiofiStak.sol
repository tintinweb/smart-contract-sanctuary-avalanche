/**
 *Submitted for verification at snowtrace.io on 2022-04-12
*/

// SPDX-License-Identifier: none
pragma solidity 0.8.11;

//ERC Token Standard #20 Interface

abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract MintableNFT {
    function mint(address _to, string calldata _uri) virtual external;
}

contract BiofiStak {
    address owner;

    address utilityTokenAddress;
    address nftTokenAddress;

    event CreateStake(address staker, uint256 stakeAmount, uint256 aprNumerator, uint256 aprDenominator, uint256 completionDate);
    event RedeemInterest(address staker, uint256 interestAmount);
    event CloseStake(address staker, uint256 principal, uint256 interest);
    event RedeemStake(address staker);

    struct Timebox {
        uint256 secs;
        uint256 mins;
        uint256 hourz;
        uint256 dayz;
        uint256 weekz;
    }

    struct Fraction {
        uint256 numerator;
        uint256 denominator;
    }

    struct InvestmentRange {
        uint256 min;
        uint256 max;
        uint256 total;
        uint256 requiredActivities;
    }

    struct Stake {
        bool exists;
        string name;
        uint256 secs;
        uint256 mins;
        uint256 hourz;
        uint256 dayz;
        uint256 weekz;
        uint256 requiredActivities;
        uint256 requiredPenaltyNumerator;
        uint256 requiredPenaltyDenominator;
        uint256 aprNumerator;
        uint256 aprDenominator;
        uint256 minimumUtilInvestment;
        uint256 maximumUtilInvestment;
        uint256 totalUtilInvestment;
        string [] beginNfts;
        string [] endNfts;
        bool   isActive;
        uint256 utilityTokenAmount;
        uint256 startTimestamp;
        uint256 duration;
        uint256 completionTimestamp;
        uint256 completedActivities;
        uint256 totalInterestWithdrawan;
        uint256 closedTimestamp;
    }

    Stake [] templates;
    //templateIndex => totalInvestment
    mapping(uint256 => uint256) totalInvestment;

    mapping(address => Stake) addressMap;
    address [] stakedAddresses;

    //when mapping is true, the address is whitelisted
    mapping(address => bool) whitelistMap;

    string contractName;
    uint256 guardCounter;

    constructor() {
        contractName = "Biofi Staking Test";
        owner = msg.sender;
        guardCounter = 1;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function setUtilityToken(address token) external {
        require(msg.sender == owner, "Not the Owner");
        require(utilityTokenAddress == address(0), "Utility Token Set");
        utilityTokenAddress = token; //ERC20Interface(token);
    }

    function setNftToken(address token) external {
        require(msg.sender == owner, "Not the Owner");
        require(nftTokenAddress == address(0), "NFT Token Already Set");
        nftTokenAddress = token;
    }

    function getNftTokenAddress() public view returns (address) {
        return nftTokenAddress;
    }

    function getUtilityTokenAddress() public view returns (address) {
        return utilityTokenAddress;
    }

    function getTemplateCount() external view returns (uint256 count) {
        count = templates.length;
    }

    function getTotalStaked(uint256 stakeIndex) external view returns(uint256 totalStaked) {
        require(stakeIndex < templates.length, "Illegal Index");
        totalStaked = totalInvestment[stakeIndex];
    }

    function createTemplate(
        string calldata name, Timebox calldata timebox,
        Fraction calldata requiredPenalty, Fraction calldata apr,
        InvestmentRange calldata utilityInvestmentRange,
        string [] calldata beginNfts, string [] calldata endNfts)
    external returns (uint256 index) {
        require(msg.sender == owner, "Must be the owner");
        require(requiredPenalty.denominator > 0, "requiredPenalty.denominator is not > 0");
        require(apr.denominator > 0, "apr.denominator is not > 0");
        Stake memory template = Stake(
            true, name,
            timebox.secs, timebox.mins, timebox.hourz, timebox.dayz, timebox.weekz,
            utilityInvestmentRange.requiredActivities,
            requiredPenalty.numerator, requiredPenalty.denominator,
            apr.numerator, apr.denominator,
            utilityInvestmentRange.min, utilityInvestmentRange.max, utilityInvestmentRange.total,
            beginNfts, endNfts,
            false, 0,0,0,0,0,0,0
        );
        index = templates.length;
        totalInvestment[index] = 0;
        templates.push(template);
    }

    function readTemplate(uint256 templateIndex) external view returns (Stake memory template) {
        template = templates[templateIndex];
    }

    function getUtilityTokenBalance() public view returns (uint256 availableTokenBalance) {
        require(utilityTokenAddress != address(0), "No utility token defined");
        ERC20Interface utilityToken = ERC20Interface(utilityTokenAddress);
        availableTokenBalance =  utilityToken.balanceOf(msg.sender);
    }

    function stakeTemplate(uint256 stakeIndex, uint256 utilityTokenAmount) external returns (uint256 completionTimestamp) {
        completionTimestamp = 0;
        require(utilityTokenAddress != address(0), "Utility Token is Not Defined");
        require(nftTokenAddress != address(0), "Utility Token is Not Defined");
        require(stakeIndex < templates.length, "Illegal stakeIndex");
        require(whitelistMap[msg.sender], "Staker not whitelisted");
        Stake memory template = templates[stakeIndex];
        require(template.isActive, "Template is not active");
        Stake memory existingStake = addressMap[msg.sender];
        require(!existingStake.exists, "Stake Already Defined for The Caller's Address");
        require(utilityTokenAmount >= template.minimumUtilInvestment, "Investment below minimum threshold");
        require(utilityTokenAmount <= template.maximumUtilInvestment, "Investment above maximum threshold");
        ERC20Interface utilityToken = ERC20Interface(utilityTokenAddress);
        uint256 availableTokenBalance =  utilityToken.balanceOf(msg.sender);
        require(availableTokenBalance >= utilityTokenAmount, "Insufficient Token Balance");
        require(utilityToken.transferFrom(msg.sender, address(this), utilityTokenAmount), "register failed, stable token transfer in");
        require(utilityToken.transfer(owner, utilityTokenAmount), "register failed, stable token transfer out");
        require(template.totalUtilInvestment >= totalInvestment[stakeIndex] + utilityTokenAmount, "Investment Would Exceed Limit");
        uint duration =
        template.secs +
        template.mins * 60 +
        template.hourz * 3600 +
        template.dayz * 24 * 3600 +
        template.weekz * 7 * 24 * 3600;
        require(duration > 0, "Duration cannot be 0");
        completionTimestamp = block.timestamp + duration;

        Stake memory stake = Stake(
            true, template.name,
            template.secs, template.mins, template.hourz, template.dayz, template.weekz,
            template.requiredActivities, template.requiredPenaltyNumerator, template.requiredPenaltyDenominator,
            template.aprNumerator, template.aprDenominator, template.minimumUtilInvestment,
            template.maximumUtilInvestment, template.totalUtilInvestment,
            template.beginNfts, template.endNfts,
            template.isActive,
            utilityTokenAmount, block.timestamp, duration,
            completionTimestamp,
            0,  //completedActivities
            0,  //totalInterestWithdrawan
            0  //closeTimestamp
        );
        addressMap[msg.sender] = stake;
        stakedAddresses.push(msg.sender);
        MintableNFT nftToken = MintableNFT(nftTokenAddress);
        for(uint i = 0; i < stake.beginNfts.length; i++)
            nftToken.mint(msg.sender, stake.beginNfts[i]);
        totalInvestment[stakeIndex] = totalInvestment[stakeIndex] + utilityTokenAmount;
        emit CreateStake(msg.sender, utilityTokenAmount, template.aprNumerator, template.aprDenominator, completionTimestamp);
    }

    function readStake(address staker) external view returns (Stake memory stake) {
        stake = addressMap[staker];
        require(stake.exists, "No stake found");
    }

    function calculateInterest(address staker) private view returns (uint256 interestPayable) {
        interestPayable = 0;
        Stake memory stake = addressMap[staker];
        require(stake.exists, "No staker contract found");
        require(stake.closedTimestamp == 0, "Contract is Already Closed");
        require(block.timestamp >= stake.completionTimestamp, "Contract is Not Over Yet");
        uint256 periodEnd = block.timestamp > stake.completionTimestamp ?  stake.completionTimestamp : block.timestamp;
        uint256 annualSeconds = 3600 * 24 * 365;
        uint256 totalInterestEarned =
        (periodEnd - stake.startTimestamp) * stake.utilityTokenAmount *
        (stake.aprNumerator - stake.aprDenominator) / stake.aprDenominator / annualSeconds;
        interestPayable = totalInterestEarned - stake.totalInterestWithdrawan;
        uint256 penalty = 0;
        if(stake.completedActivities < stake.requiredActivities)
            penalty = interestPayable * stake.requiredPenaltyNumerator / stake.requiredPenaltyDenominator;
        if(penalty > interestPayable)
            penalty = interestPayable;
        interestPayable -= penalty;
        require(interestPayable > 0, "No interest due now");
        return interestPayable;
    }

    function readPrincipalInterest(address staker) external view returns (uint256 principal, uint256 interest) {
        require(msg.sender == owner, 'Not the owner');
        Stake memory stake = addressMap[staker];
        principal = stake.utilityTokenAmount;
        interest = calculateInterest(staker);
    }

    function setCompletedActivities(address staker, uint256 completedActivities) external {
        require(msg.sender == owner, "Not the owner");
        Stake storage stake = addressMap[staker];
        require(stake.exists, "No stake found");
        stake.completedActivities = completedActivities;
    }

    //reentrancy from a malicious contract should not be an issue, because we control
    //the nftToken address.
    //As an extra step, we implement the nonreentrant modifier anyways.
    function closeContract(address staker) external nonReentrant {
        require(msg.sender == owner, "Not the Owner");
        Stake storage stake = addressMap[staker];
        require(stake.exists, "No staker contract found");
        require(stake.closedTimestamp == 0, "Contract is Already Closed");
        require(block.timestamp >= stake.completionTimestamp, "Contract Completion Timestamp Not Reached Yet");
        uint256 interestPayable = calculateInterest(staker);
        uint256 totalPayable = stake.utilityTokenAmount + interestPayable;
        stake.closedTimestamp = block.timestamp;
        stake.totalInterestWithdrawan += interestPayable;
        stake.exists = false;
        ERC20Interface utilityToken = ERC20Interface(utilityTokenAddress);
        require(utilityToken.transferFrom(owner, address(this), totalPayable), "Close Contract Transfer In Failed");
        require(utilityToken.transfer(staker, totalPayable), "Close Contract Transfer Out Failed");
        MintableNFT nftToken = MintableNFT(nftTokenAddress);
        for(uint i = 0; i < stake.endNfts.length; i++)
            nftToken.mint(staker, stake.endNfts[i]);
        emit CloseStake(staker, stake.utilityTokenAmount, interestPayable);
    }

    function setActive(uint256 templateIndex, bool willBeActive) external {
        require(msg.sender == owner, "Not the owner");
        require(templateIndex < templates.length, "templateIndex out of range");
        Stake storage template = templates[templateIndex];
        template.isActive = willBeActive;
    }

    function isWhitelisted(address addr) external view returns (bool) {
        require(msg.sender == owner, "Not the owner");
        return whitelistMap[addr];
    }

    function setWhitelisted(address addr, bool whitelistArg) external {
        require(msg.sender == owner, "Not the owner");
        whitelistMap[addr] = whitelistArg;
    }

    /**
    * @dev Prevents a contract from calling itself, directly or indirectly.
    * Calling a `nonReentrant` function from another `nonReentrant`
    * function is not supported. It is possible to prevent this from happening
    * by making the `nonReentrant` function external, and make it call a
    * `private` function that does the actual work.
    */
    modifier nonReentrant() {
        guardCounter += 1;
        uint256 localCounter = guardCounter;
        _;
        require(localCounter == guardCounter);
    }

}