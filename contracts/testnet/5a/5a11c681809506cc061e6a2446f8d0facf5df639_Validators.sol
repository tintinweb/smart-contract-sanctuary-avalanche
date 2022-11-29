/**
 *Submitted for verification at testnet.snowtrace.io on 2022-11-28
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

contract Params {
    bool public initialized;

    // System contracts
    address public ValidatorContractAddr;
    address public PunishContractAddr;
    address public ProposalAddr;

    // System params
    uint16 public constant MaxValidators = 10;
    // Validator have to wait StakingLockPeriod blocks to withdraw staking 24 hours
    uint64 public constant StakingLockPeriod = 600; //86400;
    // Stakers have to wait UnstakeLockPeriod blocks to withdraw staking
    uint64 public constant UnstakeLockPeriod = 600; //7 days
    // Validator have to wait WithdrawProfitPeriod blocks to withdraw his profits 8 hours
    uint64 public constant WithdrawProfitPeriod = 600; //28800;
    uint256 public constant MinimalStakingCoin = 1 ether;

    modifier onlyMiner() {
        require(msg.sender == block.coinbase, "m 0");
        _;
    }

    modifier onlyNotInitialized() {
        require(!initialized, "m 1");
        _;
    }

    modifier onlyInitialized() {
        require(initialized, "m 2");
        _;
    }

    modifier onlyPunishContract() {
        require(msg.sender == PunishContractAddr, "m 3");
        _;
    }

    modifier onlyBlockEpoch(uint256 epoch) {
        require(block.number % epoch == 0, "m 4");
        _;
    }

    modifier onlyValidatorsContract() {
        require(msg.sender == ValidatorContractAddr, "m 5");
        _;
    }

    modifier onlyProposalContract() {
        require(msg.sender == ProposalAddr, "m 6");
        _;
    }
}

interface IHPN {
    function mint(address _user) external payable;

    function lastTransfer(address _user) external view returns (uint256);
}

interface IPunish {
    function cleanPunishRecord(address _validator) external returns (bool);
}

interface Proxy {
    function owner() external view returns (address);
}

contract Validators is Params {
    enum Status {
        // validator not exist, default status
        NotExist,
        // validator created
        Created,
        // anyone has staked for the validator
        Staked,
        // validator's staked coins < MinimalStakingCoin
        Unstaked,
        // validator is jailed by system(validator have to repropose)
        Jailed
    }

    struct Description {
        string moniker;
        string identity;
        string website;
        string email;
        string details;
    }

    struct Validator {
        address payable feeAddr;
        Status status;
        uint256 coins;
        Description description;
        uint256 hbIncoming;
        uint256 totalJailedHB;
        uint256 lastWithdrawProfitsBlock;
        // Address list of user who has staked for this validator
        address[] stakers;
        address[] masterArray;
        uint256 masterCoins;
        uint256 masterStakerCoins;
    }

    struct StakingInfo {
        uint256 coins;
        // unstakeBlock != 0 means that you are unstaking your stake, so you can't
        // stake or unstake
        uint256 unstakeBlock;
        // index of the staker list in validator
        uint256 index;
        uint256 stakeTime;
    }

    mapping(address => Validator) public validatorInfo;
    //  *************************
    struct MasterVoter {
        address validator;
        address[] stakers;
        uint256 coins;
        uint256 unstakeBlock;
        uint256 stakerCoins;
    }
    mapping(address => MasterVoter) public masterVoterInfo;
    uint256 private constant masterVoterlimit = 2000000 ether; //2% of total supply of 100 million
    // staker => masterVoter => info
    mapping(address => mapping(address => StakingInfo)) public stakedMaster;
    uint256 private constant maxReward = 12000000 ether; // 12 Million HPN
    uint256 private constant rewardhalftime = 15552000; //6 months
    struct RewardInfo {
        uint rewardDuration;
        uint256 rewardAmount; // 1 HPN
        uint256 totalRewardOut;
    }
    RewardInfo public rewardInfo;
    uint256 startingTime;

    // staker => validator => lastRewardTime
    mapping(address => mapping(address => uint)) private stakeTime;
    //validator => LastRewardtime
    mapping(address => uint) private lastRewardTime;
    //validator => lastRewardTime => reflectionMasterPerent
    mapping(address => mapping(uint => uint)) private reflectionMasterPerent;
    uint256 private profitPerShare_;
    mapping(address => uint256) public payoutsTo_;
    //validator of a staker
    mapping(address => address) private stakeValidator;
    //pricepershare of unstaked mastervoter
    mapping(address => uint256) private unstakedMasterperShare;
    //unstaker => bool
    mapping(address => bool) private isUnstaker;
    // *****************************
    // staker => validator => info
    mapping(address => mapping(address => StakingInfo)) public staked;
    // current validator set used by chain
    // only changed at block epoch
    address[] public currentValidatorSet;
    // highest validator set(dynamic changed)
    address[] public highestValidatorsSet;
    // total stake of all validators
    uint256 public totalStake;
    // total jailed hb
    uint256 public totalJailedHB;

    // System contracts
    IPunish private punish;

    enum Operations {
        Distribute,
        UpdateValidators
    }
    // Record the operations is done or not.
    mapping(uint256 => mapping(uint8 => bool)) operationsDone;

    modifier onlyNotRewarded() {
        require(
            operationsDone[block.number][uint8(Operations.Distribute)] == false,
            "m 7"
        );
        _;
    }

    modifier onlyNotUpdated() {
        require(
            operationsDone[block.number][uint8(Operations.UpdateValidators)] ==
                false,
            "m 8"
        );
        _;
    }

    //this sets WHPN contract address. It can be called only once.
    //this should set after the contract is initialized.
    IHPN public WHPN;
    bool check;

    function setWHPN(
        address whpn,
        address val,
        address pro,
        address pu
    ) external {
        require(!check);
        WHPN = IHPN(whpn);
        ValidatorContractAddr = val;
        ProposalAddr = pro;
        PunishContractAddr = pu;
        check = true;
    }

    // this is initialized by the blockchain itself.
    // so no need to initialize separately.
    function initialize(address[] calldata vals) external onlyNotInitialized {
        punish = IPunish(PunishContractAddr);

        for (uint256 i = 0; i < vals.length; i++) {
            require(vals[i] != address(0), "err1");

            lastRewardTime[vals[i]] = block.timestamp;
            reflectionMasterPerent[vals[i]][lastRewardTime[vals[i]]] = 0;

            if (!isActiveValidator(vals[i])) {
                currentValidatorSet.push(vals[i]);
            }
            if (!isTopValidator(vals[i])) {
                highestValidatorsSet.push(vals[i]);
            }
            if (validatorInfo[vals[i]].feeAddr == address(0)) {
                validatorInfo[vals[i]].feeAddr = payable(vals[i]);
            }
            // Important: NotExist validator can't get profits
            if (validatorInfo[vals[i]].status == Status.NotExist) {
                validatorInfo[vals[i]].status = Status.Staked;
            }
        }
        rewardInfo.rewardAmount = 1 * 1e18; //1 HPN
        rewardInfo.rewardDuration = 1;
        initialized = true;
        startingTime = block.timestamp;
    }

    // stake for the validator
    function stake(address validator) public payable onlyInitialized {
        address payable staker = payable(msg.sender);
        require(unstakedMasterperShare[staker] == 0, "m 8");
        uint256 staking = msg.value;

        require(
            validatorInfo[validator].status == Status.Created ||
                validatorInfo[validator].status == Status.Staked,
            "m 9"
        );

        //***************************
        bool isMaster;
        if (
            staking >= masterVoterlimit ||
            masterVoterInfo[staker].validator != address(0)
        ) {
            isMaster = true;
            require(
                masterVoterInfo[staker].validator == address(0) ||
                    masterVoterInfo[staker].validator == validator,
                "m 10"
            );
        } else {
            require(
                stakeValidator[staker] == address(0) ||
                    stakeValidator[staker] == validator,
                "m 11"
            );
        }

        require(staked[staker][validator].unstakeBlock == 0, "m 12");

        Validator storage valInfo = validatorInfo[validator];
        // The staked coins of validator must >= MinimalStakingCoin
        require((valInfo.coins + staking) >= MinimalStakingCoin, "m 13");

        // stake at first time to this valiadtor
        if (staked[staker][validator].coins == 0) {
            // add staker to validator's record list
            staked[staker][validator].index = valInfo.stakers.length;
            valInfo.stakers.push(staker);
            stakeTime[staker][validator] = lastRewardTime[validator];
        }

        valInfo.coins += staking;
        if (valInfo.status != Status.Staked) {
            valInfo.status = Status.Staked;
        }
        tryAddValidatorToHighestSet(validator, valInfo.coins);

        // record staker's info
        staked[staker][validator].coins += staking;

        staked[staker][validator].stakeTime = block.timestamp;
        totalStake += staking;
        //***************************
        if (isMaster) {
            MasterVoter storage masterInfo = masterVoterInfo[staker];
            masterInfo.coins += staking;
            if (masterInfo.validator == address(0)) {
                valInfo.masterArray.push(staker);
                masterInfo.validator = validator;
                stakedMaster[staker][staker].index = masterInfo.stakers.length;
                masterInfo.stakers.push(staker);
            }
            stakedMaster[staker][staker].coins += staking;
            stakedMaster[staker][staker].stakeTime = block.timestamp;
            valInfo.masterCoins += staking;
            payoutsTo_[staker] += profitPerShare_ * 3 * staking;
        } else {
            if (staker != validator) {
                isUnstaker[staker] = true;
                //mint wrapped token to user
                WHPN.mint{value: staking}(staker);
            }
            payoutsTo_[staker] += profitPerShare_ * staking;
            stakeValidator[staker] = validator;
        }
    }

    function withdrawStakingReward(address validatorOrMastervoter) public {
        address payable staker = payable(msg.sender);

        StakingInfo storage stakingInfo = staked[staker][
            validatorOrMastervoter
        ];
        uint256 _lastTransferTime = WHPN.lastTransfer(staker);
        uint256 reward;
        if (stakingInfo.coins == 0) {
            reward = dividendsOf(
                staker,
                stakedMaster[staker][validatorOrMastervoter].coins * 3
            );
        } else if (masterVoterInfo[staker].coins > 0) {
            require(
                stakeTime[staker][validatorOrMastervoter] > 0,
                "nothing staked"
            );
            require(
                stakeTime[staker][validatorOrMastervoter] <
                    lastRewardTime[validatorOrMastervoter],
                "no reward yet"
            );
            uint256 validPercent = reflectionMasterPerent[
                validatorOrMastervoter
            ][lastRewardTime[validatorOrMastervoter]] -
                reflectionMasterPerent[validatorOrMastervoter][
                    stakeTime[staker][validatorOrMastervoter]
                ];
            reward = dividendsOf(
                staker,
                staked[staker][validatorOrMastervoter].coins * 3
            );
            reward += (stakingInfo.coins * validPercent) / 100;
        } else if (
            _lastTransferTime < staked[staker][validatorOrMastervoter].stakeTime
        ) {
            reward = dividendsOf(
                staker,
                staked[staker][validatorOrMastervoter].coins
            );
        }

        require(reward > 0, "still no reward");
        payoutsTo_[staker] += reward;
        stakeTime[staker][validatorOrMastervoter] = lastRewardTime[
            validatorOrMastervoter
        ];
        staker.transfer(reward);
    }

    function withdrawableReward(
        address validator,
        address _user
    ) public view returns (uint256) {
        StakingInfo memory stakingInfo = staked[_user][validator];

        uint256 _lastTransferTime = WHPN.lastTransfer(_user);
        uint256 reward;

        if (stakingInfo.coins == 0) {
            reward = dividendsOf(
                _user,
                stakedMaster[_user][validator].coins * 3
            );
        } else if (masterVoterInfo[_user].coins > 0) {
            uint256 validPercent = reflectionMasterPerent[validator][
                lastRewardTime[validator]
            ] - reflectionMasterPerent[validator][stakeTime[_user][validator]];
            reward = dividendsOf(_user, staked[_user][validator].coins * 3);
            if (validPercent > 0) {
                reward += (stakingInfo.coins * validPercent) / 100;
            }
        } else if (_lastTransferTime < staked[_user][validator].stakeTime) {
            reward = dividendsOf(_user, staked[_user][validator].coins);
        }
        return reward;
    }

    function calculateReflectionPercent(
        uint256 _totalAmount,
        uint256 _rewardAmount
    ) public pure returns (uint) {
        return
            ((_rewardAmount * 100000000000000000000) / _totalAmount) /
            (1000000000000000000);
    }

    // distributeBlockReward distributes block reward to all active validators
    function distributeBlockReward(
        address val,
        uint256 reward
    )
        external
        payable
        //onlyMiner
        onlyNotRewarded
        onlyInitialized
    {
        // never reach this
        if (validatorInfo[val].status == Status.NotExist) {
            return;
        }
        operationsDone[block.number][uint8(Operations.Distribute)] = true;
        if (rewardInfo.totalRewardOut < maxReward) {
            uint256 modDuration = block.timestamp -
                (startingTime % rewardhalftime);
            if (modDuration != rewardInfo.rewardDuration) {
                rewardInfo.rewardDuration = rewardInfo.rewardDuration + 1;
                rewardInfo.rewardAmount = rewardInfo.rewardAmount / 2;
            }
            reward += rewardInfo.rewardAmount;
            rewardInfo.totalRewardOut += rewardInfo.rewardAmount;
        }
        // Jailed validator can't get profits.
        addProfitsToActiveValidatorsByStakePercentExcept(reward, address(0));
    }

    function getActiveValidators() public view returns (address[] memory) {
        return currentValidatorSet;
    }

    function getTotalStakeOfActiveValidators()
        public
        view
        returns (uint256 total, uint256 len)
    {
        uint256 curlen = currentValidatorSet.length;
        for (uint256 i = 0; i < curlen; i++) {
            if (
                validatorInfo[currentValidatorSet[i]].status != Status.Jailed &&
                address(0) != currentValidatorSet[i]
            ) {
                total += validatorInfo[currentValidatorSet[i]].coins;
                len++;
            }
        }

        return (total, len);
    }

    function getTotalStakeOfHighestValidatorsExcept(
        address val
    ) private view returns (uint256 total, uint256 len) {
        for (uint256 i = 0; i < highestValidatorsSet.length; i++) {
            if (
                validatorInfo[highestValidatorsSet[i]].status !=
                Status.Jailed &&
                val != highestValidatorsSet[i]
            ) {
                total += validatorInfo[highestValidatorsSet[i]].coins;
                len++;
            }
        }

        return (total, len);
    }

    function isActiveValidator(address who) public view returns (bool) {
        for (uint256 i = 0; i < currentValidatorSet.length; i++) {
            if (currentValidatorSet[i] == who) {
                return true;
            }
        }

        return false;
    }

    function isTopValidator(address who) public view returns (bool) {
        for (uint256 i = 0; i < highestValidatorsSet.length; i++) {
            if (highestValidatorsSet[i] == who) {
                return true;
            }
        }

        return false;
    }

    function getTopValidators() public view returns (address[] memory) {
        return highestValidatorsSet;
    }

    function tryAddValidatorToHighestSet(
        address val,
        uint256 staking
    ) internal {
        // do nothing if you are already in highestValidatorsSet set
        for (uint256 i = 0; i < highestValidatorsSet.length; i++) {
            if (highestValidatorsSet[i] == val) {
                return;
            }
        }

        if (highestValidatorsSet.length < MaxValidators) {
            highestValidatorsSet.push(val);
            return;
        }

        // find lowest validator index in current validator set
        uint256 lowest = validatorInfo[highestValidatorsSet[0]].coins;
        uint256 lowestIndex = 0;
        for (uint256 i = 1; i < highestValidatorsSet.length; i++) {
            if (validatorInfo[highestValidatorsSet[i]].coins < lowest) {
                lowest = validatorInfo[highestValidatorsSet[i]].coins;
                lowestIndex = i;
            }
        }

        // do nothing if staking amount isn't bigger than current lowest
        if (staking <= lowest) {
            return;
        }

        highestValidatorsSet[lowestIndex] = val;
    }

    // add profits to all validators by stake percent except the punished validator or jailed validator
    function addProfitsToActiveValidatorsByStakePercentExcept(
        uint256 totalReward,
        address punishedVal
    ) private {
        if (totalReward == 0) {
            return;
        }

        uint256 totalRewardStake;
        uint256 rewardValsLen;
        (
            totalRewardStake,
            rewardValsLen
        ) = getTotalStakeOfHighestValidatorsExcept(punishedVal);

        if (rewardValsLen == 0) {
            return;
        }

        uint256 remain;
        address last;

        // no stake(at genesis period)
        if (totalRewardStake == 0) {
            uint256 per = totalReward / rewardValsLen;
            remain = totalReward - (per * rewardValsLen);

            for (uint256 i = 0; i < highestValidatorsSet.length; i++) {
                address val = highestValidatorsSet[i];
                if (
                    validatorInfo[val].status != Status.Jailed &&
                    val != punishedVal
                ) {
                    validatorInfo[val].hbIncoming =
                        validatorInfo[val].hbIncoming +
                        per;

                    last = val;
                }
            }

            if (remain > 0 && last != address(0)) {
                validatorInfo[last].hbIncoming =
                    validatorInfo[last].hbIncoming +
                    remain;
            }
            return;
        }

        uint256 added;
        for (uint256 i = 0; i < highestValidatorsSet.length; i++) {
            address val = highestValidatorsSet[i];
            if (
                validatorInfo[val].status != Status.Jailed &&
                val != punishedVal &&
                validatorInfo[val].coins > 0
            ) {
                uint256 reward = (totalReward * validatorInfo[val].coins) /
                    totalRewardStake;
                added += reward;
                last = val;
                validatorInfo[val].hbIncoming =
                    validatorInfo[val].hbIncoming +
                    ((reward * 15) / 100);

                uint256 lastRewardMasterHold = reflectionMasterPerent[val][
                    lastRewardTime[val]
                ];
                lastRewardTime[val] = block.timestamp;

                uint256 unstakedvotercoins = validatorInfo[val].coins -
                    (validatorInfo[val].masterStakerCoins +
                        validatorInfo[val].masterCoins);
                if (validatorInfo[val].masterCoins > 0) {
                    reflectionMasterPerent[val][lastRewardTime[val]] =
                        lastRewardMasterHold +
                        calculateReflectionPercent(
                            validatorInfo[val].masterCoins,
                            (reward * 15) / 100
                        );
                }
                profitPerShare_ += (((reward * 70) / 100) /
                    (((validatorInfo[val].masterStakerCoins +
                        validatorInfo[val].masterCoins) * 3) +
                        unstakedvotercoins));
            }
        }

        remain = totalReward - added;
        if (remain > 0 && last != address(0)) {
            validatorInfo[last].hbIncoming =
                validatorInfo[last].hbIncoming +
                remain;
        }
    }

    function tryRemoveValidatorInHighestSet(address val) private {
        for (
            uint256 i = 0;
            // ensure at least one validator exist
            i < highestValidatorsSet.length && highestValidatorsSet.length > 1;
            i++
        ) {
            if (val == highestValidatorsSet[i]) {
                // remove it
                if (i != highestValidatorsSet.length - 1) {
                    highestValidatorsSet[i] = highestValidatorsSet[
                        highestValidatorsSet.length - 1
                    ];
                }

                highestValidatorsSet.pop();

                break;
            }
        }
    }

    function dividendsOf(
        address _user,
        uint256 coins
    ) public view returns (uint256) {
        return (uint256)((profitPerShare_ * coins) - (payoutsTo_[_user]));
    }
}