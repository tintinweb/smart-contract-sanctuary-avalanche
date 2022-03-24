// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import {SafeERC20Upgradeable} from "./SafeERC20Upgradeable.sol";
import "./IERC20Upgradeable.sol";
import {SafeMathUpgradeable} from "./SafeMathUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./ABDKMath64x64.sol";

contract CYTStakeAPY is Initializable, ReentrancyGuardUpgradeable {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    address private _owner;
    address private _currency; // =token address
    address private _bank;

    bool private _isLocked;

    uint256 private _holdPeriod; // = 2 minutes; // 21 days;
    uint256 private _annualPercent; // = 12; // 12%

    uint256 private constant MIN_DEPOSIT = 10 * 10**6;
    uint256 private constant DAY = 1 days;

    event StakeCreate(address indexed stakeholder, uint256 stake);
    event StakeHold(address indexed stakeholder);
    event StakeWithdraw(address indexed stakeholder, uint256 reward);

    struct Stake {
        uint256 amount;
        uint256 stakedAt;
        uint256 heldAmount;
        uint256 heldAt;
        bool isCanceled;
    }

    /**
     * @dev stakeholders list
     */
    address[] private _stakeholders;

    /**
     * @dev the stakes for each stakeholder.
     */
    mapping(address => Stake) private _stakes;
    mapping(address => uint256) private _holds;

    modifier limitedStake(uint256 amount) {
        require(amount >= MIN_DEPOSIT, "Stake: insufficient deposit");
        _;
    }

    modifier onlyStakeExists(address stakeholder, uint256 value) {
        require(_stakes[stakeholder].amount > 0, "Stake: no stake yet");
        require(rewardOf(stakeholder) >= value, "Stake: insufficient stake");
        require(_stakes[stakeholder].stakedAt < block.timestamp, "Stake: stake just created");
        _;
    }

    modifier onlyNoStakeYet(address stakeholder) {
        require(_stakes[stakeholder].amount == 0, "Stake: stake exists");
        _;
    }

    modifier onlyStakeUnheld(address stakeholder) {
        require(_stakes[stakeholder].isCanceled, "Stake: stake not exists or not canceled");
        require(_stakes[stakeholder].heldAt + _holdPeriod <= block.timestamp, "Stake: stake on hold");
        _;
    }

    function initialize(address currency, address bank, uint256 holdPeriod, uint256 annualPercent) public initializer {
        _stakeParams(currency, bank, holdPeriod, annualPercent);
        __ReentrancyGuard_init();
    }


    function _stakeParams(address currency, address bank, uint256 holdPeriod, uint256 annualPercent) internal {
        _currency = currency;
        _bank = bank;
        _holdPeriod = holdPeriod;
        _annualPercent = annualPercent;
        _owner = msg.sender;
    }

    function stakeHoldPeriod() external view returns (uint256) {
        return _holdPeriod;
    }

    function stakeAnnualPercent() external view returns (uint256) {
        return _annualPercent;
    }

    /**
   * @dev A method for a stakeholder to create a stake
   */
    function deposit(uint256 stake) external nonReentrant() {
        _createStake(msg.sender, stake);
    }

    /**
     * @dev A method for a stakeholder to remove a stake
     */
    function cancelStake(uint256 amount) external nonReentrant() {
        _holdStake(msg.sender, amount);
    }

    /**
    * @dev A method to allow a stakeholder to withdraw his rewards.
    */
    function withdraw() external nonReentrant() {
        _removeStake(msg.sender);
    }

    /**
     * @dev internal method for a stakeholder to create a stake.
     * @param stakeholder Stakeholder address
     * @param stake The size of the stake to be created.
     */
    function _createStake(address stakeholder, uint256 stake) internal limitedStake(stake){
        _stakes[stakeholder] = Stake({
            amount : rewardOf(stakeholder).add(stake),
            stakedAt : block.timestamp,
            heldAmount : _stakes[stakeholder].heldAmount,
            heldAt : _stakes[stakeholder].heldAt,
            isCanceled: _stakes[stakeholder].isCanceled
            });
            
        _addStakeholder(stakeholder);
        IERC20Upgradeable(_currency).transferFrom(msg.sender, _bank, stake);
        emit StakeCreate(stakeholder,  stake);

    }

    /**
     * @dev internal method for a stakeholder to hold a stake.
     * @param stakeholder Stakeholder address
     */
    function _holdStake(address stakeholder, uint256 amount) internal onlyStakeExists(stakeholder, amount) {
        _stakes[stakeholder].heldAt = block.timestamp;

        _stakes[stakeholder] = Stake({
            amount : rewardOf(stakeholder).sub(amount),
            stakedAt : block.timestamp,
            heldAmount : _stakes[stakeholder].heldAmount.add(amount),
            heldAt : block.timestamp,
            isCanceled: true
            });
        
        emit StakeHold(stakeholder);
    }

    /**
     * @dev internal method for a stakeholder to remove a stake.
     * @param stakeholder Stakeholder address
     */
    function _removeStake(address stakeholder) internal onlyStakeUnheld(stakeholder) {
        uint256 balance = _stakes[stakeholder].heldAmount;

        _stakes[stakeholder].heldAmount = 0;
        _stakes[stakeholder].heldAt = 0;
        _stakes[stakeholder].isCanceled = false;
        if ( _stakes[stakeholder].amount == 0 ) {
            delete _stakes[stakeholder];
            _removeStakeholder(stakeholder);
        }
        IERC20Upgradeable(_currency).transferFrom(_bank, stakeholder, balance.div(100).mul(99));
        emit StakeWithdraw(stakeholder, balance);
    }

    /**
     * @dev A method to retrieve the stake for a stakeholder.
     * @param stakeholder The stakeholder to retrieve the stake for.
     * @return uint256 The amount of wei staked.
     */
    function stakeOf(address stakeholder) public view returns (uint256){
        return _stakes[stakeholder].amount;
    }

    function stakeDetails(address stakeholder) public view returns (uint256, uint256, uint256){
        return (_stakes[stakeholder].stakedAt, _stakes[stakeholder].heldAt, _stakes[stakeholder].heldAmount);
    }

    function rewardOf(address stakeholder) public view returns(uint256) {
        if (_stakes[stakeholder].stakedAt == 0) return 0;
        return _reward(stakeholder, block.timestamp);
    }

    function _reward(address stakeholder, uint rewardedAt) internal view returns(uint256) {
        // total stake period in days
        uint256 period = rewardedAt - _stakes[stakeholder].stakedAt;
        uint256 daysCount = period.div(DAY);

        return
            ABDKMath64x64.mulu(
                pow(ABDKMath64x64.add(ABDKMath64x64.fromUInt(1), ABDKMath64x64.divu(_annualPercent, 10**6)), daysCount),
                _stakes[stakeholder].amount
            );
    }

    /**
     * @dev A method to the aggregated stakes from all stakeholders.
     * @return uint256 The aggregated stakes from all stakeholders.
     */
    function totalStakes() public view returns (uint256) {
        uint256 _totalStakes = 0;
        for (uint256 s = 0; s < _stakeholders.length; s++) {
            _totalStakes = _totalStakes.add(_stakes[_stakeholders[s]].amount);
        }
        return _totalStakes;
    }

    /**
     * @dev A method to check if an address is a stakeholder.
     * @param stakeholder The address to verify.
     * @return bool, uint256 Whether the address is a stakeholder,
     * and if so its position in the stakeholders array.
     */
    function isStakeholder(address stakeholder) public view returns (bool, uint256) {
        for (uint256 s = 0; s < _stakeholders.length; s++) {
            if (stakeholder == _stakeholders[s]) return (true, s);
        }
        return (false, 0);
    }

    /**
     * @dev A method to add a stakeholder.
     * @param stakeholder The stakeholder to add.
     */
    function _addStakeholder(address stakeholder) internal {
        (bool _isStakeholder,) = isStakeholder(stakeholder);
        if (!_isStakeholder) _stakeholders.push(stakeholder);
    }

    /**
     * @dev A method to remove a stakeholder.
     * @param stakeholder The stakeholder to remove.
     */
    function _removeStakeholder(address stakeholder) internal {
        (bool _isStakeholder, uint256 s) = isStakeholder(stakeholder);
        if (_isStakeholder) {
            _stakeholders[s] = _stakeholders[_stakeholders.length - 1];
            _stakeholders.pop();
        }
    }

    function pow(int128 _x, uint256 _n) public pure returns (int128 r) {
        r = ABDKMath64x64.fromUInt(1);
        while (_n > 0) {
            if (_n % 2 == 1) {
                r = ABDKMath64x64.mul(r, _x);
                _n -= 1;
            } else {
                _x = ABDKMath64x64.mul(_x, _x);
                _n /= 2;
            }
        }
    }

    uint256[50] private ______gap;
}