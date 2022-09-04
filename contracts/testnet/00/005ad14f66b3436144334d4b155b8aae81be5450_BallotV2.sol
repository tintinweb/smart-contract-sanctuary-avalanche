// SPDX-License-Identifier: UnlicensedVEFLY
pragma solidity 0.8.12;

import {Fly} from "lib/hoppers/Fly.sol";
import {Zone} from "lib/hoppers/Zone.sol";
import {veFly} from "lib/hoppers/veFly.sol";
import {Ballot} from "lib/hoppers/Ballot.sol";

contract BallotV2 {
    address public owner;

    /*///////////////////////////////////////////////////////////////
                            IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    address public immutable AGGREGATOR;
    address public immutable FLY;
    Ballot public immutable OLD_BALLOT;

    /*///////////////////////////////////////////////////////////////
                              ZONES
    //////////////////////////////////////////////////////////////*/

    address[] public arrZones;
    mapping(address => bool) public zones;
    mapping(address => uint256) public zonesVotes;

    mapping(address => mapping(address => uint256)) public zonesUserVotes;
    mapping(address => uint256) public userVeFlyUsed;

    /*///////////////////////////////////////////////////////////////
                              EMISSIONS
    //////////////////////////////////////////////////////////////*/

    uint256 public bonusEmissionRate;
    uint256 public rewardSnapshot;
    uint256 public countRewardRate;

    /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event UpdatedOwner(address indexed owner);

    /*///////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();
    error TooSoon();
    error NotEnoughVeFly();

    /*///////////////////////////////////////////////////////////////
                            CONTRACT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    constructor(address _flyAddress, address _aggregatorAddress, address _oldBallot) {
        owner = msg.sender;
        rewardSnapshot = type(uint256).max;
        FLY = _flyAddress;
        AGGREGATOR = _aggregatorAddress;
        OLD_BALLOT = Ballot(_oldBallot);
    }

    modifier onlyOwner() {
        if (owner != msg.sender) {
            revert Unauthorized();
        }
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function openBallot(uint256 _countRewardRate, uint256 _bonusEmissionRate) external onlyOwner {
        rewardSnapshot = block.timestamp;
        countRewardRate = _countRewardRate;
        bonusEmissionRate = _bonusEmissionRate;
    }

    function closeBallot() external onlyOwner {
        rewardSnapshot = type(uint256).max;
    }

    function setBonusEmissionRate(uint256 _bonusEmissionRate) external onlyOwner {
        bonusEmissionRate = _bonusEmissionRate;
    }

    function setCountRewardRate(uint256 _countRewardRate) external onlyOwner {
        countRewardRate = _countRewardRate;
    }

    /*///////////////////////////////////////////////////////////////
                            Migration
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) public userUpdated;

    function updateGlobalStorage(address[] calldata _zones) external onlyOwner {
        uint256 length = _zones.length;
        for (uint256 i; i < length;) {
            address zone = _zones[i];
            arrZones.push(zone);
            zones[zone] = true;
            unchecked {
                ++i;
            }
            zonesVotes[zone] = OLD_BALLOT.zonesVotes(zone);
        }
    }

    function migrateUserData(address user) internal {
        for (uint256 i = 0; i < arrZones.length; i++) {
            address zone = arrZones[i];
            zonesUserVotes[zone][user] = OLD_BALLOT.zonesUserVotes(zone, user);
        }
        userVeFlyUsed[user] = OLD_BALLOT.userVeFlyUsed(user);
        userUpdated[user] = true;
    }

    /*///////////////////////////////////////////////////////////////
                                ZONES
    //////////////////////////////////////////////////////////////*/

    modifier onlyZone() {
        if (!zones[msg.sender]) {
            revert Unauthorized();
        }
        _;
    }

    function addZones(address[] calldata _zones) external onlyOwner {
        uint256 length = _zones.length;
        for (uint256 i; i < length;) {
            address zone = _zones[i];
            arrZones.push(zone);
            zones[zone] = true;
            unchecked {
                ++i;
            }
        }
    }

    function removeZone(uint256 index) external onlyOwner {
        address removed = arrZones[index];
        arrZones[index] = arrZones[arrZones.length - 1];
        arrZones.pop();
        delete zones[removed];
    }

    /*///////////////////////////////////////////////////////////////
                            VOTING
    //////////////////////////////////////////////////////////////*/

    //slither-disable-next-line costly-loop
    function forceUnvote(address _user) external {
        if (!(msg.sender == AGGREGATOR)) {
            revert Unauthorized();
        }
        if (!userUpdated[_user]) {
            migrateUserData(_user);
        }
        uint256 length = arrZones.length;

        for (uint256 i; i < length;) {
            address zone = arrZones[i];

            uint256 zoneUserVotes = zonesUserVotes[zone][_user];

            if (zoneUserVotes > 0) {
                zonesVotes[zone] -= zoneUserVotes;
                delete userVeFlyUsed[_user];
                delete zonesUserVotes[zone][_user];
                // Done already by veFly on its _forceUncastAllVotes
                // veFly(AGGREGATOR).unsetHasVoted(user)

                Zone(zone).forceUnvote(_user);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _updateVotes(address user, uint256 vefly) internal {
        zonesVotes[msg.sender] = zonesVotes[msg.sender] + vefly - zonesUserVotes[msg.sender][user];

        zonesUserVotes[msg.sender][user] = vefly;
    }

    function vote(address user, uint256 vefly) external onlyZone {
        // veFly Accounting
        if (!userUpdated[user]) {
            migrateUserData(user);
        }
        uint256 totalVeFly = userVeFlyUsed[user] + vefly;

        if (totalVeFly > veFly(AGGREGATOR).balanceOf(user)) {
            revert NotEnoughVeFly();
        }

        if (vefly > 0) {
            userVeFlyUsed[user] = totalVeFly;

            unchecked {
                _updateVotes(user, zonesUserVotes[msg.sender][user] + vefly);
            }

            // First time he has voted
            if (totalVeFly == vefly) {
                veFly(AGGREGATOR).setHasVoted(user);
            }
        }
    }

    function unvote(address user, uint256 vefly) external onlyZone {
        // veFly Accounting
        if (!userUpdated[user]) {
            migrateUserData(user);
        }
        uint256 _userVeFlyUsed = userVeFlyUsed[user];
        if (_userVeFlyUsed < vefly) {
            revert NotEnoughVeFly();
        }

        uint256 remainingVeFly;
        unchecked {
            remainingVeFly = _userVeFlyUsed - vefly;
        }

        userVeFlyUsed[user] = remainingVeFly;

        uint256 zoneUserVotes = zonesUserVotes[msg.sender][user];

        if (zoneUserVotes < vefly) {
            revert NotEnoughVeFly();
        }

        unchecked {
            _updateVotes(user, zoneUserVotes - vefly);
        }

        if (remainingVeFly == 0) {
            veFly(AGGREGATOR).unsetHasVoted(user);
        }
    }

    /*///////////////////////////////////////////////////////////////
                            COUNTING
    //////////////////////////////////////////////////////////////*/

    function countReward() public view returns (uint256) {
        uint256 _rewardSnapshot = rewardSnapshot;

        if (block.timestamp < _rewardSnapshot) {
            return 0;
        }

        return countRewardRate * (block.timestamp - _rewardSnapshot);
    }

    function count() external {
        uint256 reward = countReward();
        rewardSnapshot = block.timestamp;

        uint256 totalVotes;
        address[] memory _arrZones = arrZones;
        uint256 length = _arrZones.length;

        for (uint256 i; i < length;) {
            unchecked {
                totalVotes += zonesVotes[_arrZones[i]];
                ++i;
            }
        }

        for (uint256 i; i < length;) {
            if (totalVotes == 0) {
                Zone(_arrZones[i]).setBonusEmissionRate(0);
            } else {
                Zone(_arrZones[i]).setBonusEmissionRate((bonusEmissionRate * zonesVotes[_arrZones[i]]) / totalVotes);
            }
            unchecked {
                ++i;
            }
        }

        if (reward > 0) {
            // solhint-disable-next-line avoid-tx-origin
            Fly(FLY).mint(tx.origin, reward);
        }
    }

    function getUserVotes(address zone, address user) external view returns (uint) {
        if(userUpdated[user]) {
            return zonesUserVotes[zone][user];
        }
        else {
            return OLD_BALLOT.zonesUserVotes(zone, user);
        }
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;
import {ERC20} from "@solmate/tokens/ERC20.sol";

contract Fly is ERC20 {
    address public owner;

    // whitelist for minting mechanisms
    mapping(address => bool) public zones;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed newOwner);

    constructor(string memory _NAME, string memory _SYMBOL)
        ERC20(_NAME, _SYMBOL, 18)
    {
        owner = msg.sender;
    }

    /*///////////////////////////////////////////////////////////////
                    CONTRACT MANAGEMENT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    function setOwner(address newOwner) external onlyOwner {
        //slither-disable-next-line missing-zero-check
        owner = newOwner;
        emit OwnerUpdated(newOwner);
    }

    /*///////////////////////////////////////////////////////////////
                            Zones - can mint
    //////////////////////////////////////////////////////////////*/

    modifier onlyZone() {
        if (!zones[msg.sender]) revert Unauthorized();
        _;
    }

    function addZones(address[] calldata _zones) external onlyOwner {
        uint256 length = _zones.length;
        for (uint256 i; i < length; ) {
            zones[_zones[i]] = true;
            unchecked {
                ++i;
            }
        }
    }

    function removeZone(address zone) external onlyOwner {
        delete zones[zone];
    }

    /*///////////////////////////////////////////////////////////////
                                MINT / BURN
    //////////////////////////////////////////////////////////////*/

    function mint(address receiver, uint256 amount) external onlyZone {
        _mint(receiver, amount);
    }

    function burn(address from, uint256 amount) external onlyZone {
        _burn(from, amount);
    }
}

// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.12;

import {veFly} from "./veFly.sol";
import {Fly} from "./Fly.sol";
import {Ballot} from "./Ballot.sol";
import {IHopperNFT, HopperNFT} from "./interfaces/IHopper.sol";
import {FixedPointMathLib} from "@solmate/utils/FixedPointMathLib.sol";

abstract contract Zone {
    /*///////////////////////////////////////////////////////////////
                            IMMUTABLE STORAGE
    //////////////////////////////////////////////////////////////*/
    address public immutable FLY;
    address public immutable VE_FLY;
    address public immutable HOPPER;

    /*///////////////////////////////////////////////////////////////
                                HOPPERS
    //////////////////////////////////////////////////////////////*/
    string public LEVEL_GAUGE_KEY;

    mapping(uint256 => address) public hopperOwners;
    mapping(uint256 => uint256) public hopperBaseShare;
    mapping(address => uint256) public rewards;

    address public owner;
    address public ballot;
    bool public emergency;

    /*///////////////////////////////////////////////////////////////
                        Accounting/Rewards NFT
    //////////////////////////////////////////////////////////////*/
    uint256 public emissionRate;

    uint256 public totalBaseShare;
    uint256 public lastUpdatedTime;
    uint256 public rewardPerShareStored;

    mapping(address => uint256) public baseSharesBalance;
    mapping(address => uint256) public userRewardPerSharePaid;
    mapping(address => uint256) public userMaxFlyGeneration;

    mapping(address => uint256) public generatedPerShareStored;
    mapping(uint256 => uint256) public tokenCapFilledPerShare;

    uint256 public flyLevelCapRatio;

    /*///////////////////////////////////////////////////////////////
                        Accounting/Rewards veFLY
    //////////////////////////////////////////////////////////////*/
    uint256 public bonusEmissionRate;

    uint256 public totalVeShare;
    uint256 public lastBonusUpdatedTime;
    uint256 public bonusRewardPerShareStored;

    mapping(address => uint256) public veSharesBalance;
    mapping(address => uint256) public userBonusRewardPerSharePaid;
    mapping(address => uint256) public veFlyBalance;

    /*///////////////////////////////////////////////////////////////
                                ERRORS
    //////////////////////////////////////////////////////////////*/
    error Unauthorized();
    error UnfitHopper();
    error WrongTokenID();
    error NoHopperStaked();

    /*///////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event UpdatedOwner(address indexed owner);
    event UpdatedBallot(address indexed ballot);
    event UpdatedEmission(uint256 emissionRate);

    /*///////////////////////////////////////////////////////////////
                           CONTRACT MANAGEMENT
    //////////////////////////////////////////////////////////////*/
    constructor(
        address fly,
        address vefly,
        address hopper
    ) {
        owner = msg.sender;

        FLY = fly;
        VE_FLY = vefly;
        HOPPER = hopper;

        flyLevelCapRatio = 3;
        LEVEL_GAUGE_KEY = "LEVEL_GAUGE_KEY";
        lastUpdatedTime = block.timestamp;
        lastBonusUpdatedTime = block.timestamp;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert Unauthorized();
        _;
    }

    modifier onlyBallotOrOwner() {
        if (msg.sender != owner && msg.sender != ballot) revert Unauthorized();
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function enableEmergency() external onlyOwner {
        // no going back
        emergency = true;
    }

    function setBallot(address _ballot) external onlyOwner {
        ballot = _ballot;
        emit UpdatedBallot(_ballot);
    }

    function setEmissionRate(uint256 _emissionRate) external onlyOwner {
        _updateBaseRewardPerShareStored();

        emissionRate = _emissionRate;
        emit UpdatedEmission(_emissionRate);
    }

    function setBonusEmissionRate(uint256 _bonusEmissionRate)
        external
        onlyBallotOrOwner
    {
        _updateBonusRewardPerShareStored();

        bonusEmissionRate = _bonusEmissionRate;
    }

    function setFlyLevelCapRatio(uint256 _flyLevelCapRatio) external onlyOwner {
        flyLevelCapRatio = _flyLevelCapRatio;
    }

    /*///////////////////////////////////////////////////////////////
                        HOPPER GENERATION CAP
    //////////////////////////////////////////////////////////////*/

    function getUserBonusGeneratedFly(
        address account,
        uint256 _totalUserBonusShares
    ) public view returns (uint256, uint256) {
        // userMaxFlyGeneration gets updated at _updateAccountBaseReward which happens before this is called
        uint256 cappedFly = userMaxFlyGeneration[account] / 1e12;
        uint256 generatedFly = ((_totalUserBonusShares *
            (bonusRewardPerShare() - userBonusRewardPerSharePaid[account])) /
            1e18);

        return (
            generatedFly > cappedFly ? cappedFly : generatedFly,
            generatedFly
        );
    }

    function getUserGeneratedFly(address account, uint256 _totalUserBaseShares)
        public
        view
        returns (uint256, uint256)
    {
        uint256 cappedFly = userMaxFlyGeneration[account] / 1e12;
        uint256 generatedFly = ((_totalUserBaseShares *
            (baseRewardPerShare() - userRewardPerSharePaid[account])) / 1e18);

        return (
            generatedFly > cappedFly ? cappedFly : generatedFly,
            generatedFly
        );
    }

    function _updateHopperGenerationData(
        address _account,
        uint256 _totalAccountKindShares,
        bool isBonus
    ) internal returns (uint256) {
        
        uint256 cappedFly;
        uint256 generatedFly;

        if (isBonus) {
            (cappedFly, generatedFly) = getUserBonusGeneratedFly(
                _account,
                _totalAccountKindShares
            );

            // Makes calculations easier, since we don't need to add another
            //    state keeping track of generatedPerVeshare
            generatedPerShareStored[_account] += FixedPointMathLib.mulDivUp(
                generatedFly,
                1e12,
                baseSharesBalance[_account]
            );
        } else {
            (cappedFly, generatedFly) = getUserGeneratedFly(
                _account,
                _totalAccountKindShares
            );
            generatedPerShareStored[_account] += FixedPointMathLib.mulDivUp(
                generatedFly,
                1e12,
                _totalAccountKindShares
            );
        }
        return cappedFly;
    }

    /*///////////////////////////////////////////////////////////////
                           REWARDS ACCOUNTING
    //////////////////////////////////////////////////////////////*/

    function _updateAccountRewards(address _account) internal {
        _updateAccountBaseReward(_account, baseSharesBalance[_account]);
        _updateAccountBonusReward(_account, veSharesBalance[_account]);
    }

    /*///////////////////////////////////////////////////////////////
                           BASE REWARDS
    //////////////////////////////////////////////////////////////*/

    function baseRewardPerShare() public view returns (uint256) {
        uint256 _totalBaseShare = totalBaseShare;
        //slither-disable-next-line incorrect-equality
        if (_totalBaseShare == 0) {
            return rewardPerShareStored;
        }
        return
            rewardPerShareStored +
            (((block.timestamp - lastUpdatedTime) * emissionRate * 1e18) /
                _totalBaseShare);
    }

    function _updateBaseRewardPerShareStored() internal {
        rewardPerShareStored = baseRewardPerShare();
        lastUpdatedTime = block.timestamp;
    }

    function _updateAccountBaseReward(
        address _account,
        uint256 _totalAccountShares
    ) internal {
        _updateBaseRewardPerShareStored();

        if (_totalAccountShares > 0) {
            uint256 cappedFly = _updateHopperGenerationData(
                _account,
                _totalAccountShares,
                false
            );

            unchecked {
                rewards[_account] += cappedFly;
            }
            userMaxFlyGeneration[_account] -= cappedFly * 1e12;
        }

        userRewardPerSharePaid[_account] = rewardPerShareStored;
    }

    /*///////////////////////////////////////////////////////////////
                           BONUS REWARDS
    //////////////////////////////////////////////////////////////*/

    function bonusRewardPerShare() public view returns (uint256) {
        uint256 _totalVeShare = totalVeShare;
        //slither-disable-next-line incorrect-equality
        if (_totalVeShare == 0) {
            return bonusRewardPerShareStored;
        }
        return
            bonusRewardPerShareStored +
            (((block.timestamp - lastBonusUpdatedTime) *
                bonusEmissionRate *
                1e18) / _totalVeShare);
    }

    function _updateBonusRewardPerShareStored() internal {
        bonusRewardPerShareStored = bonusRewardPerShare();
        lastBonusUpdatedTime = block.timestamp;
    }

    function _updateAccountBonusReward(
        address _account,
        uint256 _totalAccountShares
    ) internal {
        _updateBonusRewardPerShareStored();

        if (_totalAccountShares > 0) {
            uint256 cappedFly = _updateHopperGenerationData(
                _account,
                _totalAccountShares,
                true
            );

            unchecked {
                rewards[_account] += cappedFly;
            }
            userMaxFlyGeneration[_account] -= cappedFly * 1e12;
        }
        userBonusRewardPerSharePaid[_account] = bonusRewardPerShareStored;
    }

    /*///////////////////////////////////////////////////////////////
                    NAMES & LEVELING
    //////////////////////////////////////////////////////////////*/

    function payAction(uint256 flyRequired, bool useOwnRewards) internal {
        if (useOwnRewards) {
            uint256 _rewards = rewards[msg.sender];

            // Pays from the pending rewards
            if (_rewards >= flyRequired) {
                unchecked {
                    rewards[msg.sender] -= flyRequired;
                    flyRequired = 0;
                }
            } else if (_rewards > 0) {
                delete rewards[msg.sender];
                unchecked {
                    flyRequired -= _rewards;
                }
            }
        }

        // Sender pays for action. Will revert, if not enough balance
        if (flyRequired > 0) {
            Fly(FLY).burn(msg.sender, flyRequired);
        }
    }

    function changeHopperName(
        uint256 tokenId,
        string calldata name,
        bool useOwnRewards
    ) external {
        if (useOwnRewards) {
            _updateAccountRewards(msg.sender);
        }

        // Check hopper ownership
        address zoneHopperOwner = hopperOwners[tokenId];
        if (zoneHopperOwner != msg.sender) {
            // Saves gas in certain paths
            if (IHopperNFT(HOPPER).ownerOf(tokenId) != msg.sender) {
                revert WrongTokenID();
            }
        }

        payAction(
            IHopperNFT(HOPPER).changeHopperName(tokenId, name), // returns price
            useOwnRewards
        );
    }

    function _getLevelUpCost(uint256 level) internal pure returns (uint256) {
        unchecked {
            ++level;

            if (level == 100) {
                return 598 ether;
            }
            // x**(1.43522) / 7.5 for x >= 21 where x is next level
            // packing costs in 7 bits
            else if (level > 1 && level < 21) {
                return (level * 1e18) >> 1;
            } else if (level >= 21 && level < 51) {
                return
                    ((0x1223448501f3c74e1b3464c172c54a9426488901e3c70d183058a >>
                        (7 * (level - 21))) & 127) * 1e18;
            } else if (level >= 51 && level < 81) {
                return
                    ((0x23c68b0e14180f9ebc76e9c376cd5a3262c17ae5ab15a9509d325 >>
                        (7 * (level - 51))) & 127) * 1e18;
            } else if (level >= 81 && level < 101) {
                return
                    ((0xc58705ebb6ed59af5aad3a5467ce9b2e549 >>
                        (7 * (level - 81))) & 127) * 1e18;
            } else {
                return type(uint256).max;
            }
        }
    }

    //slither-disable-next-line reentrancy-no-eth
    function levelUp(uint256 tokenId, bool useOwnRewards) external {
        IHopperNFT IHOPPER = IHopperNFT(HOPPER);
        if (useOwnRewards) {
            _updateAccountRewards(msg.sender);
        }

        // Check hopper ownership
        address zoneHopperOwner = hopperOwners[tokenId];
        if (zoneHopperOwner != msg.sender) {
            // Saves gas in certain paths
            if (IHOPPER.ownerOf(tokenId) != msg.sender) {
                revert WrongTokenID();
            }
        }

        HopperNFT.Hopper memory hopper = IHOPPER.getHopper(tokenId);

        // Update owners shares if hopper is staked
        if (zoneHopperOwner == msg.sender) {
            // Updated above if true
            if (!useOwnRewards) {
                _updateAccountRewards(msg.sender);
            }

            // Fill hopper gauge so we can find whats the remaining
            (, uint256 remainingGauge, ) = _updateHopperGaugeFill(tokenId);

            // Calculate the baseShare that we need to subtract from the user and total
            uint256 prevHopperShare = _calculateBaseShare(hopper);
            unchecked {
                ++hopper.level;
            }
            // Calculate the baseShare that we need to add to the user and total
            uint256 newHopperShare = _calculateBaseShare(hopper);

            // Calculate new baseShares
            uint256 diff = newHopperShare - prevHopperShare;
            unchecked {
                uint256 newBaseShare = baseSharesBalance[msg.sender] + diff;
                baseSharesBalance[msg.sender] = newBaseShare;

                totalBaseShare += diff;

                // Update new value of veShares
                _updateVeShares(newBaseShare, 0, false);
            }

            uint256 boostFill = 0;
            uint256 userMax = userMaxFlyGeneration[msg.sender];
            if (userMax < remainingGauge) {
                boostFill = remainingGauge - userMax;
            }

            // Update the new cap
            userMaxFlyGeneration[msg.sender] += (_getGaugeLimit(hopper.level) *
                1e12 -
                (remainingGauge - boostFill));

            // Make sure getLevelUpCost is passed its current level
            unchecked {
                --hopper.level;
            }
        }

        payAction(getLevelUpCost(hopper.level), useOwnRewards);

        IHOPPER.levelUp(tokenId);

        // Reset Hopper internal gauge
        IHOPPER.setData(LEVEL_GAUGE_KEY, tokenId, 0);
    }

    /*///////////////////////////////////////////////////////////////
                    STAKE / UNSTAKE NFT && CLAIM FLY
    //////////////////////////////////////////////////////////////*/

    function enter(uint256[] calldata tokenIds) external {
        if (emergency) revert Unauthorized();

        _updateAccountRewards(msg.sender);

        uint256 prevBaseShares = baseSharesBalance[msg.sender];
        uint256 _baseShares = prevBaseShares;
        uint256 numTokens = tokenIds.length;

        uint256 flyCapIncrease;

        uint256 _generatedPerShareStored = generatedPerShareStored[msg.sender];
        for (uint256 i; i < numTokens; ) {
            uint256 tokenId = tokenIds[i];

            // Resets this hopper generation tracking
            tokenCapFilledPerShare[tokenId] = _generatedPerShareStored;

            (
                HopperNFT.Hopper memory hopper,
                uint256 hopperGauge,
                uint256 gaugeLimit
            ) = _getHopperAndGauge(tokenId);

            if (!canEnter(hopper)) revert UnfitHopper();

            unchecked {
                // Increment user shares
                _baseShares += _calculateBaseShare(hopper);
            }

            // Update the maximum FLY this user can generate
            flyCapIncrease += (gaugeLimit - hopperGauge);

            // Hopper Accounting
            hopperOwners[tokenId] = msg.sender;
            IHopperNFT(HOPPER).transferFrom(msg.sender, address(this), tokenId);

            unchecked {
                ++i;
            }
        }

        baseSharesBalance[msg.sender] = _baseShares;
        unchecked {
            userMaxFlyGeneration[msg.sender] += flyCapIncrease;

            totalBaseShare = totalBaseShare + _baseShares - prevBaseShares;
        }

        _updateVeShares(_baseShares, 0, false);
    }

    //slither-disable-next-line reentrancy-no-eth
    function exit(uint256[] calldata tokenIds) external {
        if (emergency) revert Unauthorized();

        _updateAccountRewards(msg.sender);

        uint256 prevBaseShares = baseSharesBalance[msg.sender];
        uint256 _baseShares = prevBaseShares;
        uint256 numTokens = tokenIds.length;

        uint256 flyCapDecrease;
        uint256 userMax = userMaxFlyGeneration[msg.sender];

        uint256[] memory rTokensRemaining = new uint256[](tokenIds.length);
        uint256[] memory rTokensLimit = new uint256[](tokenIds.length);

        for (uint256 i; i < numTokens; ) {
            uint256 tokenId = tokenIds[i];

            // Can the user unstake this hopper
            if (hopperOwners[tokenId] != msg.sender) revert WrongTokenID();

            (
                uint256 _hopperShare,
                uint256 _remainingGauge,
                uint256 _gaugeLimit
            ) = _updateHopperGaugeFill(tokenId);

            // Decrement user shares
            _baseShares -= _hopperShare;

            // Update the maximum FLY this user can generate
            flyCapDecrease += _remainingGauge;

            // To fill gauge later
            rTokensRemaining[i] = _remainingGauge;
            rTokensLimit[i] = _gaugeLimit;

            // Hopper Accounting
            //slither-disable-next-line costly-loop
            delete hopperOwners[tokenId];
            IHopperNFT(HOPPER).transferFrom(address(this), msg.sender, tokenId);

            unchecked {
                ++i;
            }
        }

        baseSharesBalance[msg.sender] = _baseShares;

        if (userMax < flyCapDecrease) {
            // Being boosted, we need to go back and refill uncapped tokens
            refill(
                tokenIds,
                rTokensRemaining,
                rTokensLimit,
                flyCapDecrease - userMax
            );
            delete userMaxFlyGeneration[msg.sender];
        } else if (_baseShares == 0) {
            delete userMaxFlyGeneration[msg.sender];
        } else {
            userMaxFlyGeneration[msg.sender] -= flyCapDecrease;
        }

        unchecked {
            totalBaseShare = totalBaseShare + _baseShares - prevBaseShares;
        }
        _updateVeShares(_baseShares, 0, false);
    }

    function refill(
        uint256[] calldata tokenIds,
        uint256[] memory remaining,
        uint256[] memory limit,
        uint256 leftover
    ) internal {
        uint256 length = tokenIds.length;

        for (uint256 i; i < length; ) {
            if (remaining[i] != 0) {
                if (leftover > remaining[i]) {
                    IHopperNFT(HOPPER).setData(
                        LEVEL_GAUGE_KEY,
                        tokenIds[i],
                        bytes32(limit[i] / 1e12)
                    );
                    leftover -= remaining[i];
                } else {
                    IHopperNFT(HOPPER).setData(
                        LEVEL_GAUGE_KEY,
                        tokenIds[i],
                        bytes32((limit[i] - remaining[i] + leftover) / 1e12)
                    );
                    leftover = 0;
                    break;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function emergencyExit(uint256[] calldata tokenIds, address user) external {
        if (!emergency) revert Unauthorized();

        uint256 numTokens = tokenIds.length;
        for (uint256 i; i < numTokens; ) {
            uint256 tokenId = tokenIds[i];

            // Can the user unstake this hopper
            if (hopperOwners[tokenId] != user) revert WrongTokenID();

            //slither-disable-next-line costly-loop
            delete hopperOwners[tokenId];
            IHopperNFT(HOPPER).transferFrom(address(this), user, tokenId);

            unchecked {
                ++i;
            }
        }
    }

    /*///////////////////////////////////////////////////////////////
                            CLAIMING
    //////////////////////////////////////////////////////////////*/

    function claimable(address _account) external view returns (uint256) {
        uint256 cappedFly = userMaxFlyGeneration[_account] / 1e12;

        (uint256 gen, ) = getUserGeneratedFly(
            _account,
            baseSharesBalance[_account]
        );
        (uint256 bonusGen, ) = getUserBonusGeneratedFly(
            _account,
            veSharesBalance[_account]
        );

        gen += bonusGen;
        cappedFly = gen > cappedFly ? cappedFly : gen;

        unchecked {
            return rewards[_account] + cappedFly;
        }
    }

    function claim() external {
        _updateAccountRewards(msg.sender);

        uint256 _accountRewards = rewards[msg.sender];
        delete rewards[msg.sender];

        Fly(FLY).mint(msg.sender, _accountRewards);
    }

    /*///////////////////////////////////////////////////////////////
                            VOTE veFLY 
    //////////////////////////////////////////////////////////////*/

    function _calcVeShare(uint256 accountTotalBaseShares, uint256 vefly)
        internal
        pure
        returns (uint256)
    {
        return FixedPointMathLib.sqrt(accountTotalBaseShares * vefly);
    }

    //slither-disable-next-line reentrancy-no-eth
    function _updateVeShares(
        uint256 baseShares,
        uint256 veFlyAmount,
        bool incrementVeFlyAmount
    ) internal {
        uint256 beforeVeShare = veSharesBalance[msg.sender];
        if (veFlyAmount > 0) {
            // Ballot checks if the user has the veFly amount necessary, otherwise reverts
            if (incrementVeFlyAmount) {
                //slither-disable-next-line reentrancy-benign
                Ballot(ballot).vote(msg.sender, veFlyAmount);
                unchecked {
                    veFlyBalance[msg.sender] += veFlyAmount;
                }
            } else {
                //slither-disable-next-line reentrancy-benign
                Ballot(ballot).unvote(msg.sender, veFlyAmount);
                veFlyBalance[msg.sender] -= veFlyAmount;
            }
        }

        uint256 currentVeShare = _calcVeShare(
            baseShares,
            veFlyBalance[msg.sender]
        );
        veSharesBalance[msg.sender] = currentVeShare;

        unchecked {
            totalVeShare = totalVeShare + currentVeShare - beforeVeShare;
        }
    }

    function vote(uint256 veFlyAmount, bool recount) external {
        _updateAccountBonusReward(msg.sender, veSharesBalance[msg.sender]);

        _updateVeShares(baseSharesBalance[msg.sender], veFlyAmount, true);

        if (recount) Ballot(ballot).count();
    }

    function unvote(uint256 veFlyAmount, bool recount) external {
        _updateAccountBonusReward(msg.sender, veSharesBalance[msg.sender]);

        _updateVeShares(baseSharesBalance[msg.sender], veFlyAmount, false);

        if (recount) Ballot(ballot).count();
    }

    function forceUnvote(address user) external {
        if (msg.sender != ballot) revert Unauthorized();

        uint256 userVeShares = veSharesBalance[user];
        _updateAccountBonusReward(user, userVeShares);

        totalVeShare -= userVeShares;
        delete veSharesBalance[user];
        delete veFlyBalance[user];
    }

    /*///////////////////////////////////////////////////////////////
                    HELPER GAUGE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // _remaining is scaled with 1e12
    function _updateHopperGaugeFill(uint256 tokenId)
        internal
        returns (
            uint256 _hopperShare,
            uint256 _remaining,
            uint256
        )
    {
        uint256 _generatedPerShareStored = generatedPerShareStored[msg.sender];

        // Resets this hopper generation tracking
        uint256 filledCapPerShare = _generatedPerShareStored -
            tokenCapFilledPerShare[tokenId];

        tokenCapFilledPerShare[tokenId] = _generatedPerShareStored;

        (
            HopperNFT.Hopper memory hopper,
            uint256 prevHopperGauge,
            uint256 gaugeLimit
        ) = _getHopperAndGauge(tokenId);

        _hopperShare = _calculateBaseShare(hopper);

        uint256 flyGeneratedAndBurned = prevHopperGauge +
            filledCapPerShare *
            _hopperShare;

        uint256 currentGauge = flyGeneratedAndBurned > gaugeLimit
            ? gaugeLimit
            : flyGeneratedAndBurned;

        // Update the HOPPER gauge
        IHopperNFT(HOPPER).setData(
            LEVEL_GAUGE_KEY,
            tokenId,
            bytes32(currentGauge / 1e12)
        );

        return (_hopperShare, (gaugeLimit - currentGauge), gaugeLimit);
    }

    function _getGaugeLimit(uint256 level) internal view returns (uint256) {
        if (level == 1) return 1.5 ether;
        if (level == 100) return 294 ether;
        unchecked {
            return flyLevelCapRatio * _getLevelUpCost(level - 1);
        }
    }

    function _getHopperAndGauge(uint256 _tokenId)
        internal
        view
        returns (
            HopperNFT.Hopper memory,
            uint256, // hopperGauge
            uint256 // gaugeLimit
        )
    {
        string[] memory arrData = new string[](1);
        arrData[0] = LEVEL_GAUGE_KEY;
        (HopperNFT.Hopper memory hopper, bytes32[] memory _data) = IHopperNFT(
            HOPPER
        ).getHopperWithData(arrData, _tokenId);

        return (
            hopper,
            uint256(_data[0]) * 1e12,
            _getGaugeLimit(hopper.level) * 1e12
        );
    }

    function getHopperAndGauge(uint256 tokenId)
        external
        view
        returns (
            HopperNFT.Hopper memory hopper,
            uint256 hopperGauge,
            uint256 gaugeLimit
        )
    {
        (hopper, hopperGauge, gaugeLimit) = _getHopperAndGauge(tokenId);
        return (hopper, hopperGauge / 1e12, gaugeLimit / 1e12);
    }

    /*///////////////////////////////////////////////////////////////
                                VIEW
    //////////////////////////////////////////////////////////////*/

    function getLevelUpCost(uint256 currentLevel)
        public
        pure
        returns (uint256)
    {
        return _getLevelUpCost(currentLevel);
    }

    /*///////////////////////////////////////////////////////////////
                    ZONE SPECIFIC FUNCTIONALITY
    //////////////////////////////////////////////////////////////*/

    function canEnter(HopperNFT.Hopper memory hopper)
        public
        pure
        virtual
        returns (bool)
    {} // solhint-disable-line

    function _calculateBaseShare(HopperNFT.Hopper memory hopper)
        internal
        pure
        virtual
        returns (uint256)
    {} // solhint-disable-line
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.12;

import {Fly} from "./Fly.sol";
import {Ballot} from "./Ballot.sol";

// solhint-disable-next-line
contract veFly {
    /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    // solhint-disable-next-line const-name-snakecase
    string public constant name = "veFLY";
    // solhint-disable-next-line const-name-snakecase
    string public constant symbol = "veFLY";

    address public immutable FLY;

    /*///////////////////////////////////////////////////////////////
                           FLY/VEFLY GENERATION
    //////////////////////////////////////////////////////////////*/

    struct GenerationDetails {
        uint128 maxRatio;
        uint64 generationRateNumerator;
        uint64 generationRateDenominator;
    }

    GenerationDetails public genDetails;

    mapping(address => uint256) public flyBalanceOf;
    mapping(address => uint256) private veFlyBalance;
    mapping(address => uint256) private userSnapshot;

    /*///////////////////////////////////////////////////////////////
                              VOTING
    //////////////////////////////////////////////////////////////*/

    address[] public arrValidBallots;
    mapping(address => bool) public validBallots;
    mapping(address => mapping(address => bool)) public hasUserVoted;

    /*///////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/
    error Unauthorized();
    error InvalidAmount();
    error InvalidProposal();

    /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
    event UpdatedOwner(address indexed owner);
    event AddedBallot(address indexed ballot);
    event RemovedBallot(address indexed ballot);

    /*///////////////////////////////////////////////////////////////
                            CONTRACT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    constructor(
        address _flyAddress,
        uint256 _generationRateNumerator,
        uint256 _generationRateDenominator,
        uint256 _maxRatio
    ) {
        owner = msg.sender;

        FLY = _flyAddress;

        genDetails = GenerationDetails({
            maxRatio: uint128(_maxRatio),
            generationRateNumerator: uint64(_generationRateNumerator),
            generationRateDenominator: uint64(_generationRateDenominator)
        });
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert Unauthorized();
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function setGenerationDetails(
        uint256 _maxRatio,
        uint256 _generationRateNumerator,
        uint256 _generationRateDenominator
    ) external onlyOwner {
        GenerationDetails storage gen = genDetails;
        gen.maxRatio = uint128(_maxRatio);
        gen.generationRateNumerator = uint64(_generationRateNumerator);
        gen.generationRateDenominator = uint64(_generationRateDenominator);
    }

    /*///////////////////////////////////////////////////////////////
                               BALLOTS
    //////////////////////////////////////////////////////////////*/

    modifier onlyBallot() {
        if (!validBallots[msg.sender]) revert Unauthorized();
        _;
    }

    function addBallot(address ballot) external onlyOwner {
        if (!validBallots[ballot]) {
            arrValidBallots.push(ballot);
            validBallots[ballot] = true;
            emit AddedBallot(ballot);
        }
    }

    function removeBallot(uint256 index) external onlyOwner {
        address removed = arrValidBallots[index];

        arrValidBallots[index] = arrValidBallots[arrValidBallots.length - 1];
        arrValidBallots.pop();

        delete validBallots[removed];

        emit RemovedBallot(removed);
    }

    function _forceUncastAllVotes() internal {
        uint256 length = arrValidBallots.length;
        for (uint256 i; i < length; ) {
            address ballot = arrValidBallots[i];
            delete hasUserVoted[ballot][msg.sender];

            Ballot(ballot).forceUnvote(msg.sender);
            unchecked {
                ++i;
            }
        }
    }

    function setHasVoted(address user) external onlyBallot {
        hasUserVoted[msg.sender][user] = true;
    }

    function unsetHasVoted(address user) external onlyBallot {
        delete hasUserVoted[msg.sender][user];
    }

    /*///////////////////////////////////////////////////////////////
                               STAKING
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 amount) external {
        //slither-disable-next-line incorrect-equality
        if (genDetails.maxRatio == 0) revert Unauthorized();

        // Reset veFly calculations
        veFlyBalance[msg.sender] = balanceOf(msg.sender);
        userSnapshot[msg.sender] = block.timestamp;

        unchecked {
            flyBalanceOf[msg.sender] += amount;
        }

        // slither-disable-next-line unchecked-transfer
        Fly(FLY).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) external {
        if (flyBalanceOf[msg.sender] < amount) revert InvalidAmount();

        // Reset veFly calculations
        delete veFlyBalance[msg.sender];
        userSnapshot[msg.sender] = block.timestamp;

        unchecked {
            flyBalanceOf[msg.sender] -= amount;
        }

        _forceUncastAllVotes();

        // slither-disable-next-line unchecked-transfer
        Fly(FLY).transfer(msg.sender, amount);
    }

    /*///////////////////////////////////////////////////////////////
                               veFly
    //////////////////////////////////////////////////////////////*/

    function balanceOf(address account) public view returns (uint256) {
        GenerationDetails memory gen = genDetails;

        uint256 flyBalance = flyBalanceOf[account];

        uint256 veBalance = veFlyBalance[account] +
            ((flyBalance * gen.generationRateNumerator) *
                (block.timestamp - userSnapshot[account])) /
            gen.generationRateDenominator;

        uint256 maxVe = gen.maxRatio * flyBalance;
        if (veBalance > maxVe) {
            return maxVe;
        } else {
            return veBalance;
        }
    }

    function hasUserVotedAny(address account) external view returns (bool) {
        uint256 length = arrValidBallots.length;
        for (uint256 i; i < length; ) {
            if (hasUserVoted[arrValidBallots[i]][account]) return false;
            unchecked {
                ++i;
            }
        }
        return true;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.12;

import {Fly} from "./Fly.sol";
import {Zone} from "./Zone.sol";
import {veFly} from "./veFly.sol";

contract Ballot {
    address public owner;

    /*///////////////////////////////////////////////////////////////
                            IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    address public immutable VEFLY;
    address public immutable FLY;

    /*///////////////////////////////////////////////////////////////
                              ZONES
    //////////////////////////////////////////////////////////////*/

    address[] public arrZones;
    mapping(address => bool) public zones;
    mapping(address => uint256) public zonesVotes;

    mapping(address => mapping(address => uint256)) public zonesUserVotes;
    mapping(address => uint256) public userVeFlyUsed;

    /*///////////////////////////////////////////////////////////////
                              EMISSIONS
    //////////////////////////////////////////////////////////////*/

    uint256 public bonusEmissionRate;
    uint256 public rewardSnapshot;
    uint256 public countRewardRate;

    /*///////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/

    event UpdatedOwner(address indexed owner);

    /*///////////////////////////////////////////////////////////////
                              ERRORS
    //////////////////////////////////////////////////////////////*/

    error Unauthorized();
    error TooSoon();
    error NotEnoughVeFly();

    /*///////////////////////////////////////////////////////////////
                            CONTRACT MANAGEMENT
    //////////////////////////////////////////////////////////////*/

    constructor(address _flyAddress, address _veFlyAddress) {
        owner = msg.sender;
        rewardSnapshot = type(uint256).max;
        FLY = _flyAddress;
        VEFLY = _veFlyAddress;
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert Unauthorized();
        _;
    }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
        emit UpdatedOwner(_owner);
    }

    function openBallot(uint256 _countRewardRate, uint256 _bonusEmissionRate)
        external
        onlyOwner
    {
        rewardSnapshot = block.timestamp;
        countRewardRate = _countRewardRate;
        bonusEmissionRate = _bonusEmissionRate;
    }

    function closeBallot() external onlyOwner {
        rewardSnapshot = type(uint256).max;
    }

    function setBonusEmissionRate(uint256 _bonusEmissionRate)
        external
        onlyOwner
    {
        bonusEmissionRate = _bonusEmissionRate;
    }

    function setCountRewardRate(uint256 _countRewardRate) external onlyOwner {
        countRewardRate = _countRewardRate;
    }

    /*///////////////////////////////////////////////////////////////
                                ZONES
    //////////////////////////////////////////////////////////////*/

    modifier onlyZone() {
        if (!zones[msg.sender]) revert Unauthorized();
        _;
    }

    function addZones(address[] calldata _zones) external onlyOwner {
        uint256 length = _zones.length;
        for (uint256 i; i < length; ) {
            address zone = _zones[i];
            arrZones.push(zone);
            zones[zone] = true;
            unchecked {
                ++i;
            }
        }
    }

    function removeZone(uint256 index) external onlyOwner {
        address removed = arrZones[index];
        arrZones[index] = arrZones[arrZones.length - 1];
        arrZones.pop();
        delete zones[removed];
    }

    /*///////////////////////////////////////////////////////////////
                            VOTING
    //////////////////////////////////////////////////////////////*/

    //slither-disable-next-line costly-loop
    function forceUnvote(address _user) external {
        if (msg.sender != VEFLY) revert Unauthorized();

        uint256 length = arrZones.length;

        for (uint256 i; i < length; ) {
            address zone = arrZones[i];

            uint256 zoneUserVotes = zonesUserVotes[zone][_user];

            if (zoneUserVotes > 0) {
                zonesVotes[zone] -= zoneUserVotes;
                delete userVeFlyUsed[_user];
                delete zonesUserVotes[zone][_user];

                // Done already by veFly on its _forceUncastAllVotes
                // veFly(VEFLY).unsetHasVoted(user)

                Zone(zone).forceUnvote(_user);
            }
            unchecked {
                ++i;
            }
        }
    }

    function _updateVotes(address user, uint256 vefly) internal {
        zonesVotes[msg.sender] =
            zonesVotes[msg.sender] +
            vefly -
            zonesUserVotes[msg.sender][user];

        zonesUserVotes[msg.sender][user] = vefly;
    }

    function vote(address user, uint256 vefly) external onlyZone {
        // veFly Accounting
        uint256 totalVeFly = userVeFlyUsed[user] + vefly;

        if (totalVeFly > veFly(VEFLY).balanceOf(user)) revert NotEnoughVeFly();

        if (vefly > 0) {
            userVeFlyUsed[user] = totalVeFly;

            unchecked {
                _updateVotes(user, zonesUserVotes[msg.sender][user] + vefly);
            }

            // First time he has voted
            if (totalVeFly == vefly) {
                veFly(VEFLY).setHasVoted(user);
            }
        }
    }

    function unvote(address user, uint256 vefly) external onlyZone {
        // veFly Accounting
        uint256 _userVeFlyUsed = userVeFlyUsed[user];
        if (_userVeFlyUsed < vefly) revert NotEnoughVeFly();

        uint256 remainingVeFly;
        unchecked {
            remainingVeFly = _userVeFlyUsed - vefly;
        }

        userVeFlyUsed[user] = remainingVeFly;

        uint256 zoneUserVotes = zonesUserVotes[msg.sender][user];

        if (zoneUserVotes < vefly) revert NotEnoughVeFly();

        unchecked {
            _updateVotes(user, zoneUserVotes - vefly);
        }

        if (remainingVeFly == 0) veFly(VEFLY).unsetHasVoted(user);
    }

    /*///////////////////////////////////////////////////////////////
                            COUNTING
    //////////////////////////////////////////////////////////////*/

    function countReward() public view returns (uint256) {
        uint256 _rewardSnapshot = rewardSnapshot;

        if (block.timestamp < _rewardSnapshot) return 0;

        return countRewardRate * (block.timestamp - _rewardSnapshot);
    }

    function count() external {
        uint256 reward = countReward();
        rewardSnapshot = block.timestamp;

        uint256 totalVotes;
        address[] memory _arrZones = arrZones;
        uint256 length = _arrZones.length;

        for (uint256 i; i < length; ) {
            unchecked {
                totalVotes += zonesVotes[_arrZones[i]];
                ++i;
            }
        }

        for (uint256 i; i < length; ) {
            if (totalVotes == 0) {
                Zone(_arrZones[i]).setBonusEmissionRate(0);
            } else {
                Zone(_arrZones[i]).setBonusEmissionRate(
                    (bonusEmissionRate * zonesVotes[_arrZones[i]]) / totalVotes
                );
            }
            unchecked {
                ++i;
            }
        }

        if (reward > 0) {
            // solhint-disable-next-line avoid-tx-origin
            Fly(FLY).mint(tx.origin, reward);
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.4. SEE SOURCE BELOW. !!
pragma solidity ^0.8.4;

interface IHopperNFT {
    error InsufficientAmount();
    error InvalidTokenID();
    error MaxLength25();
    error MintLimit();
    error NameTaken();
    error OnlyAlphanumeric();
    error OnlyEOAAllowed();
    error OnlyLvL100();
    error ReservedAmountInvalid();
    error TooSoon();
    error Unauthorized();
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event LevelUp(uint256 tokenId);
    event NameChange(uint256 tokenId);
    event OwnerUpdated(address indexed newOwner);
    event Rebirth(uint256 tokenId);
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );
    event UnlabeledData(string key, uint256 tokenId);
    event UpdatedNameFee(uint256 namefee);

    function LEGENDARY_ID_START() external view returns (uint256);

    function MAX_PER_ADDRESS() external view returns (uint256);

    function MAX_SUPPLY() external view returns (uint256);

    function MINT_COST() external view returns (uint256);

    function WL_MINT_COST() external view returns (uint256);

    function _jsonString(uint256 tokenId) external view returns (string memory);

    function addZones(address[] memory _zones) external;

    function approve(address spender, uint256 id) external;

    function balanceOf(address) external view returns (uint256);

    function baseURI() external view returns (string memory);

    function changeHopperName(uint256 tokenId, string memory _newName)
        external
        returns (uint256);

    function freeMerkleRoot() external view returns (bytes32);

    function freeMint(
        uint256 numberOfMints,
        uint256 totalGiven,
        bytes32[] memory proof
    ) external;

    function freeRedeemed(address) external view returns (uint256);

    function getApproved(uint256) external view returns (address);

    function getData(string memory _key, uint256 _tokenId)
        external
        view
        returns (bytes32);

    function getGlobalData(string memory _key) external view returns (bytes32);

    function getHopper(uint256 tokenId)
        external
        view
        returns (HopperNFT.Hopper memory);

    function getHopperName(uint256 tokenId)
        external
        view
        returns (string memory name);

    function getHopperWithData(string[] memory _keys, uint256 _tokenId)
        external
        view
        returns (HopperNFT.Hopper memory hopper, bytes32[] memory arrData);

    function hopperMaxAttributeValue() external view returns (uint256);

    function hoppers(uint256)
        external
        view
        returns (
            uint200 level,
            uint16 rebirths,
            uint8 strength,
            uint8 agility,
            uint8 vitality,
            uint8 intelligence,
            uint8 fertility
        );

    function hoppersLength() external view returns (uint256);

    function hoppersNames(uint256) external view returns (string memory);

    function imageURL() external view returns (string memory);

    function indexer(uint256) external view returns (uint256);

    function isApprovedForAll(address, address) external view returns (bool);

    function levelUp(uint256 tokenId) external;

    function name() external view returns (string memory);

    function nameFee() external view returns (uint256);

    function normalMint(uint256 numberOfMints) external payable;

    function owner() external view returns (address);

    function ownerOf(uint256) external view returns (address);

    function preSaleOpenTime() external view returns (uint256);

    function rebirth(uint256 _tokenId) external;

    function removeZone(address _zone) external;

    function reserved() external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setBaseURI(string memory _baseURI) external;

    function setData(
        string memory _key,
        uint256 _tokenId,
        bytes32 _data
    ) external;

    function setGlobalData(string memory _key, bytes32 _data) external;

    function setHopperMaxAttributeValue(uint256 _hopperMaxAttributeValue)
        external;

    function setImageURL(string memory _imageURL) external;

    function setNameChangeFee(uint256 _nameFee) external;

    function setOwner(address newOwner) external;

    function setSaleDetails(
        uint256 _preSaleOpenTime,
        bytes32 _wlMerkleRoot,
        bytes32 _freeMerkleRoot,
        uint256 _reserved
    ) external;

    function supportsInterface(bytes4 interfaceId) external pure returns (bool);

    function symbol() external view returns (string memory);

    function takenNames(bytes32) external view returns (bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function unlabeledData(string memory, uint256)
        external
        view
        returns (bytes32);

    function unlabeledGlobalData(string memory) external view returns (bytes32);

    function unsetData(string memory _key, uint256 _tokenId) external;

    function unsetGlobalData(string memory _key) external;

    function whitelistMint(bytes32[] memory proof) external payable;

    function withdraw() external;

    function wlMerkleRoot() external view returns (bytes32);

    function wlRedeemed(address) external view returns (uint256);

    function zones(address) external view returns (bool);
}

interface HopperNFT {
    struct Hopper {
        uint200 level;
        uint16 rebirths;
        uint8 strength;
        uint8 agility;
        uint8 vitality;
        uint8 intelligence;
        uint8 fertility;
    }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[{"internalType":"string","name":"_NFT_NAME","type":"string"},{"internalType":"string","name":"_NFT_SYMBOL","type":"string"},{"internalType":"uint256","name":"_NAME_FEE","type":"uint256"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"InsufficientAmount","type":"error"},{"inputs":[],"name":"InvalidTokenID","type":"error"},{"inputs":[],"name":"MaxLength25","type":"error"},{"inputs":[],"name":"MintLimit","type":"error"},{"inputs":[],"name":"NameTaken","type":"error"},{"inputs":[],"name":"OnlyAlphanumeric","type":"error"},{"inputs":[],"name":"OnlyEOAAllowed","type":"error"},{"inputs":[],"name":"OnlyLvL100","type":"error"},{"inputs":[],"name":"ReservedAmountInvalid","type":"error"},{"inputs":[],"name":"TooSoon","type":"error"},{"inputs":[],"name":"Unauthorized","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"spender","type":"address"},{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"LevelUp","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"NameChange","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnerUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Rebirth","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":true,"internalType":"uint256","name":"id","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"key","type":"string"},{"indexed":false,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"UnlabeledData","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"namefee","type":"uint256"}],"name":"UpdatedNameFee","type":"event"},{"inputs":[],"name":"LEGENDARY_ID_START","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_PER_ADDRESS","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_SUPPLY","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MINT_COST","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"WL_MINT_COST","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"_jsonString","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_zones","type":"address[]"}],"name":"addZones","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"spender","type":"address"},{"internalType":"uint256","name":"id","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"baseURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"string","name":"_newName","type":"string"}],"name":"changeHopperName","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"freeMerkleRoot","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"numberOfMints","type":"uint256"},{"internalType":"uint256","name":"totalGiven","type":"uint256"},{"internalType":"bytes32[]","name":"proof","type":"bytes32[]"}],"name":"freeMint","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"freeRedeemed","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"getApproved","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"_key","type":"string"},{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"getData","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"_key","type":"string"}],"name":"getGlobalData","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getHopper","outputs":[{"components":[{"internalType":"uint200","name":"level","type":"uint200"},{"internalType":"uint16","name":"rebirths","type":"uint16"},{"internalType":"uint8","name":"strength","type":"uint8"},{"internalType":"uint8","name":"agility","type":"uint8"},{"internalType":"uint8","name":"vitality","type":"uint8"},{"internalType":"uint8","name":"intelligence","type":"uint8"},{"internalType":"uint8","name":"fertility","type":"uint8"}],"internalType":"struct HopperNFT.Hopper","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getHopperName","outputs":[{"internalType":"string","name":"name","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string[]","name":"_keys","type":"string[]"},{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"getHopperWithData","outputs":[{"components":[{"internalType":"uint200","name":"level","type":"uint200"},{"internalType":"uint16","name":"rebirths","type":"uint16"},{"internalType":"uint8","name":"strength","type":"uint8"},{"internalType":"uint8","name":"agility","type":"uint8"},{"internalType":"uint8","name":"vitality","type":"uint8"},{"internalType":"uint8","name":"intelligence","type":"uint8"},{"internalType":"uint8","name":"fertility","type":"uint8"}],"internalType":"struct HopperNFT.Hopper","name":"hopper","type":"tuple"},{"internalType":"bytes32[]","name":"arrData","type":"bytes32[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"hopperMaxAttributeValue","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"hoppers","outputs":[{"internalType":"uint200","name":"level","type":"uint200"},{"internalType":"uint16","name":"rebirths","type":"uint16"},{"internalType":"uint8","name":"strength","type":"uint8"},{"internalType":"uint8","name":"agility","type":"uint8"},{"internalType":"uint8","name":"vitality","type":"uint8"},{"internalType":"uint8","name":"intelligence","type":"uint8"},{"internalType":"uint8","name":"fertility","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"hoppersLength","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"hoppersNames","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"imageURL","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"indexer","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"},{"internalType":"address","name":"","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"levelUp","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"nameFee","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"numberOfMints","type":"uint256"}],"name":"normalMint","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"preSaleOpenTime","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"rebirth","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_zone","type":"address"}],"name":"removeZone","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"reserved","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"id","type":"uint256"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"id","type":"uint256"},{"internalType":"bytes","name":"data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"_baseURI","type":"string"}],"name":"setBaseURI","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"_key","type":"string"},{"internalType":"uint256","name":"_tokenId","type":"uint256"},{"internalType":"bytes32","name":"_data","type":"bytes32"}],"name":"setData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"_key","type":"string"},{"internalType":"bytes32","name":"_data","type":"bytes32"}],"name":"setGlobalData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_hopperMaxAttributeValue","type":"uint256"}],"name":"setHopperMaxAttributeValue","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"_imageURL","type":"string"}],"name":"setImageURL","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_nameFee","type":"uint256"}],"name":"setNameChangeFee","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"setOwner","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_preSaleOpenTime","type":"uint256"},{"internalType":"bytes32","name":"_wlMerkleRoot","type":"bytes32"},{"internalType":"bytes32","name":"_freeMerkleRoot","type":"bytes32"},{"internalType":"uint256","name":"_reserved","type":"uint256"}],"name":"setSaleDetails","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"takenNames","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"id","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"","type":"string"},{"internalType":"uint256","name":"","type":"uint256"}],"name":"unlabeledData","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"","type":"string"}],"name":"unlabeledGlobalData","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"string","name":"_key","type":"string"},{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"unsetData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"_key","type":"string"}],"name":"unsetGlobalData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32[]","name":"proof","type":"bytes32[]"}],"name":"whitelistMint","outputs":[],"stateMutability":"payable","type":"function"},{"inputs":[],"name":"withdraw","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"wlMerkleRoot","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"wlRedeemed","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"zones","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"}]
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }
}