// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "SafeMath.sol";
import "Pausable.sol";
import "Ownable.sol";
import "Address.sol";
import "Context.sol";
import "Escrow.sol";

    /*                 
    :::::::::  :::            :::     ::::    ::: :::::::::::         :::         ::::::::::: :::::::::  :::::::::: :::::::::: 
    :+:    :+: :+:          :+: :+:   :+:+:   :+:     :+:           :+: :+:           :+:     :+:    :+: :+:        :+:        
    +:+    +:+ +:+         +:+   +:+  :+:+:+  +:+     +:+          +:+   +:+          +:+     +:+    +:+ +:+        +:+        
    +#++:++#+  +#+        +#++:++#++: +#+ +:+ +#+     +#+         +#++:++#++:         +#+     +#++:++#:  +#++:++#   +#++:++#   
    +#+        +#+        +#+     +#+ +#+  +#+#+#     +#+         +#+     +#+         +#+     +#+    +#+ +#+        +#+        
    #+#        #+#        #+#     #+# #+#   #+#+#     #+#         #+#     #+#         #+#     #+#    #+# #+#        #+#        
    ###        ########## ###     ### ###    ####     ###         ###     ###         ###     ###    ### ########## ########## 
    */


contract PlantTrees is Pausable, Ownable {
    
    using SafeMath for uint256;

    bool private initialized = false;
    bool private isCompundingDay = false;
    bool private whiteListCompleted = false;
    uint256 private last48Hours = 2; //2 days

    mapping(address => uint256) private TreesMiners;
    mapping(address => uint256) private claimedTrees;
    mapping(address => uint256) private firstPlantedTrees;
    mapping(address => uint256) private lastPlantedTrees;
    mapping(address => uint256) private lastRePlantedTrees;
    mapping(address => uint256) private totalPlantedValue;
    mapping(address => bool) private lastRefRePlant;
    mapping(address => bool) private whiteList;
    mapping(address => address) private referrals;
    mapping(address => uint256) private referralsUsed;
    mapping(address => uint256) private referralsRewardsTotal;
    uint256 private TreesMarket;

    //Taxes for Harvest action on rePlant days
    //Day 1 90%, Day 2 = 80%, Day 3 = 70%, Day 4 = 50% , Day 5 = 40%, Day 6 = 20% Tax,
    //Day 7 = No extra tax  0%
    //Taxes always goes to Contract
    //Taxes subtract the regulare fees dev 2% , team 1% , Treasury 1%
    uint256[] private EXTRA_TAXES_PERCENTAGES = [90, 80, 70, 50, 40, 20, 0];

    //set a tax if player didnt compound for the last 48 hours on harvest day
    uint256 private Tax_No_RePlant_Last48Hours = 95;

    //to calculate the tree market value
    uint256 private MAX_INVESTMENT = 100000000000000000000 wei; // 100 AVAX
    uint256 private MIN_INVESTMENT = 100000000000000000 wei; // 0.1 AVAX
    uint256 private WL_MIN_INVESTMENT = 1000000000000000000 wei; // 1.0 AVAX
    uint256 private Plant_Trees_1MINERS = 1080000;
    uint256 private TSN = 10000;
    uint256 private TSNH = 5000;

    //regular fees
    //dev 2%, team 1%
    uint256 private Dev_Percentage = 2;
    uint256 private Team_Percentage = 1;
    uint256 private Treasury_Percentage = 1;

    struct FEE {
        uint256 Total;
        uint256 Dev;
        uint256 Team;
        uint256 Treasury;
    }

    address internal PlantATree_CONTRACT_ADDRESS;
    address payable devAddress;
    address payable teamAddress;
    address payable treasuryAddress;

    //pass the fees wallets 
    constructor(
        address payable devAddress_,
        address payable teamAddress_,
        address payable treasuryAddress_
    ) public {
        devAddress = devAddress_;
        teamAddress = teamAddress_;
        treasuryAddress = treasuryAddress_;
    }

    //initialize the contract and set the seed market
    function InitContract() public onlyOwner {
        seedMarket();
        initialized = true;
    }

    function diffTimeSinceFirstPlantTree() public view returns (uint256) {
        return SafeMath.sub(block.timestamp, firstPlantedTrees[msg.sender]);
    }

    function diffTimeSinceLastRePlantTree() public view returns (uint256) {
        return SafeMath.sub(block.timestamp, lastRePlantedTrees[msg.sender]);
    }

    function getMyReferralsUsedCount() public view returns (uint256) {
        return referralsUsed[msg.sender];
    }

    function getMyReferralsRewardsTotal() public view returns (uint256) {
        return referralsRewardsTotal[msg.sender];
    }

    //get the compounding day current tax
    function getCurrentDayExtraTax(bool include48HoursTax)
        public
        view
        returns (uint256)
    {
        //return tax 0 if there no first transaction for the user
        if (firstPlantedTrees[msg.sender] == 0) return 0;

        // diffTime / 60 / 60 / 24; to get the days
        uint256 diffDays = SafeMath.div(
            SafeMath.div(SafeMath.div(diffTimeSinceFirstPlantTree(), 60), 60),
            24
        );
        uint256 dayNumber = SafeMath.mod(diffDays, 7);
        uint256 currentDayTax = EXTRA_TAXES_PERCENTAGES[dayNumber];
        if (include48HoursTax)
            if (hasNoCompoundLast48Hours()) {
                //get higher tax
                if (Tax_No_RePlant_Last48Hours > currentDayTax)
                    currentDayTax = Tax_No_RePlant_Last48Hours;
            }
        return currentDayTax;
    }

    //check last 48 hours if user has one compound atleast
    function hasNoCompoundLast48Hours() public view returns (bool) {
        //return tax 0 if there no last transaction for the user
        if (lastRePlantedTrees[msg.sender] == 0) return false;

        uint256 diffDays = SafeMath.div(
            SafeMath.div(SafeMath.div(diffTimeSinceLastRePlantTree(), 60), 60),
            24
        );

        return (diffDays >= last48Hours);
    }

    //check if the day is for replant or harvest
    function isHarvestDay() public view returns (bool) {
        uint256 tax = getCurrentDayExtraTax(true);
        return (tax == 0);
    }

    //allow everyone to join the contract
    function setWhiteListCompleted() public onlyOwner {
        require(initialized, "Contract not initialized yet");
        require(whiteListCompleted == false, "whiteList is Already Completed");
        //this method only set whiteListCompleted to true forever after whitelist is complete.
        //you can't set it to false forever.
        whiteListCompleted = true;
    }

    //pass array of White List addresses in one function to reduce the gas fee as transaction
    function addWhiteList(address[] memory wls) public onlyOwner {
        require(initialized, "Contract not initialized yet");
        for (uint256 w = 0; w < wls.length; w++) {
            whiteList[wls[w]] = true;
        }
    }

    //remove wrong White List addresses
    function removeWhiteList(address[] memory wls) public onlyOwner {
        require(initialized, "Contract not initialized yet");
        for (uint256 w = 0; w < wls.length; w++) {
            whiteList[wls[w]] = false;
        }
    }

    //Plant A Tree //a deposit value in AVAX
    function PlantATree(address ref) public payable whenNotPaused {
        require(initialized, "Contract not initialized yet");
        require(
            whiteListCompleted == true || whiteList[msg.sender] == true,
            "Your wallet is not White Listed."
        );
        require(
            whiteListCompleted == true ||
                (whiteList[msg.sender] == true &&
                    msg.value >= WL_MIN_INVESTMENT),
            "Minimum investment is 1.0 AVAX for your White List wallet"
        );
        require(msg.value <= MAX_INVESTMENT, "Max investment is 100 AVAX");
        require(msg.value >= MIN_INVESTMENT, "Minimum investment is 0.1 AVAX");

        uint256 treesBought = calculateTreeBuy(
            msg.value,
            SafeMath.sub(address(this).balance, msg.value)
        );

        //total balance value for planted trees
        totalPlantedValue[msg.sender] = SafeMath.add(
            totalPlantedValue[msg.sender],
            msg.value
        );

        //no extra tax on plant A tree
        //always set it to zero
        //because it is a deposit
        FEE memory treeFees = calculateTotalFees(treesBought, 0);
        treesBought = SafeMath.sub(treesBought, treeFees.Total);

        //Dev 2% Team 1% fees and 1% tressuery
        //calculate and transfer fees
        FEE memory fees = calculateTotalFees(msg.value, 0);
        devAddress.transfer(fees.Dev);
        teamAddress.transfer(fees.Team);
        treasuryAddress.transfer(fees.Treasury);

        claimedTrees[msg.sender] = SafeMath.add(
            claimedTrees[msg.sender],
            treesBought
        );

        //set block chain time every time user plant a tree
        firstPlantedTrees[msg.sender] = block.timestamp;

        lastRefRePlant[msg.sender] = false;

        RePlantATree(ref);
    }

    //compound pending rewards
    function RePlantATree(address ref) public {
        require(initialized, "Contract not initialized yet");
        require(
            firstPlantedTrees[msg.sender] > 0,
            "You haven't planted a tree"
        );

        if (ref == msg.sender) {
            ref = address(0);
        }

        if (
            referrals[msg.sender] == address(0) &&
            referrals[msg.sender] != msg.sender
        ) {
            referrals[msg.sender] = ref;
        }

        uint256 treesUsed = getMyTrees();
        uint256 newMiners = SafeMath.div(treesUsed, Plant_Trees_1MINERS);

        TreesMiners[msg.sender] = SafeMath.add(
            TreesMiners[msg.sender],
            newMiners
        );
        claimedTrees[msg.sender] = 0;
        lastPlantedTrees[msg.sender] = block.timestamp;

        //send trees to their referrals only once
        //referral rewards around 12% 
        if (lastRefRePlant[msg.sender] == false) {
            uint256 rewardsCut = SafeMath.div(treesUsed, 8);
            claimedTrees[referrals[msg.sender]] = SafeMath.add(
                claimedTrees[referrals[msg.sender]],
                rewardsCut
            );
            //save referrals used count //save total rewards cut
            if (ref != msg.sender) {
                referralsUsed[referrals[msg.sender]] = SafeMath.add(
                    referralsUsed[referrals[msg.sender]],
                    1
                );
                referralsRewardsTotal[referrals[msg.sender]] = SafeMath.add(
                    referralsRewardsTotal[referrals[msg.sender]],
                    rewardsCut
                );
            }

            lastRefRePlant[msg.sender] = true;
        }

        //boost trees market 20%
        //trees market is the main factor of trees trading math
        TreesMarket = SafeMath.add(TreesMarket, SafeMath.div(treesUsed, 5));

        //save last replanted tree time always
        lastRePlantedTrees[msg.sender] = block.timestamp;
    }

    //claim pending rewards
    function HarvestTrees() public {
        require(initialized, "Contract not initialized yet");

        uint256 hasTrees = getMyTrees();
        require(hasTrees > 0, "You have no trees");

        uint256 treeValue = calculateTreeSell(hasTrees);
        claimedTrees[msg.sender] = 0;
        lastPlantedTrees[msg.sender] = block.timestamp;
        TreesMarket = SafeMath.add(TreesMarket, hasTrees);

        //calculate fees and transfer
        uint256 todayTax = getCurrentDayExtraTax(true);
        FEE memory fees = calculateTotalFees(treeValue, todayTax);

        //transfer fees
        devAddress.transfer(fees.Dev);
        teamAddress.transfer(fees.Team);
        treasuryAddress.transfer(fees.Treasury);

        //reset firstPlantedTrees and lastRePlantedTrees to zero on harvest
        firstPlantedTrees[msg.sender] = block.timestamp;
        lastRePlantedTrees[msg.sender] = block.timestamp;

        payable(msg.sender).transfer(SafeMath.sub(treeValue, fees.Total));
    }

    //get total balance for planted trees
    function totalPlantedBalance() public view returns (uint256) {
        return totalPlantedValue[msg.sender];
    }

    function TreesRewards() public view returns (uint256) {
        uint256 hasTrees = getMyTrees();
        return calculateTreeSell(hasTrees);
    }

    //trade balancing algorithm
    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) public view returns (uint256) {
        return
            SafeMath.div(
                SafeMath.mul(TSN, bs),
                SafeMath.add(
                    TSNH,
                    SafeMath.div(
                        SafeMath.add(
                            SafeMath.mul(TSN, rs),
                            SafeMath.mul(TSNH, rt)
                        ),
                        rt
                    )
                )
            );
    }

    function calculateTreeSell(uint256 trees) public view returns (uint256) {
        return calculateTrade(trees, TreesMarket, address(this).balance);
    }

    function calculateTreeBuy(uint256 eth, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(eth, contractBalance, TreesMarket);
    }

    function calculateTreeBuySimple(uint256 eth) public view returns (uint256) {
        return calculateTreeBuy(eth, address(this).balance);
    }

    function calculateTotalFees(uint256 amount, uint256 extraTaxPercentage)
        private
        view
        returns (FEE memory)
    {
        FEE memory fees;
        //calculate regular fees
        fees.Dev = SafeMath.div(SafeMath.mul(amount, Dev_Percentage), 100);
        fees.Team = SafeMath.div(SafeMath.mul(amount, Team_Percentage), 100);
        fees.Treasury = SafeMath.div(
            SafeMath.mul(amount, Treasury_Percentage),
            100
        );

        //subtract the regular fees from the total fees
        fees.Total = SafeMath.add(
            SafeMath.add(fees.Dev, fees.Team),
            fees.Treasury
        );

        //subtract also the extra taxes from the total fees //they must stay in the contract
        if (extraTaxPercentage > 0) {
            uint256 extraTaxStayValue = SafeMath.div(
                SafeMath.mul(amount, extraTaxPercentage),
                100
            );
            fees.Total = SafeMath.add(fees.Total, extraTaxStayValue);
        }

        return fees;
    }

    function seedMarket() private onlyOwner{
        require(TreesMarket == 0);
        TreesMarket = 108000000000;
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyMiners() public view returns (uint256) {
        return TreesMiners[msg.sender];
    }

    function getMyTrees() public view returns (uint256) {
        return
            SafeMath.add(
                claimedTrees[msg.sender],
                getTreesSinceLastPlant(msg.sender)
            );
    }

    function getTreesSinceLastPlant(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(
            Plant_Trees_1MINERS,
            SafeMath.sub(block.timestamp, lastPlantedTrees[adr])
        );
        return SafeMath.mul(secondsPassed, TreesMiners[adr]);
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }

    //Only used to prevent new deposits (PlantATree function) during an emergency situation.
    //PauseContract only applies to PlantATree deposit function and no other functions.
    function pauseContract() public onlyOwner {
        _pause();
    }

    function resumeContract() public onlyOwner {
        _unpause();
    }
}