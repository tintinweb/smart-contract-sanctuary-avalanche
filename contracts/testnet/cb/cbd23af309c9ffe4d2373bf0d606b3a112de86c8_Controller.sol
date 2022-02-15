// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Ownable.sol";
import "./IERC20.sol";

contract Controller is Ownable {
    event PoolCreated(uint256 poolPrice, uint256 poolMax);
    event PoolRoundCreated(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex
    );
    event PoolRoundEntered(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex,
        address user,
        uint256 selectIndex,
        uint256 amount
    );
    event PoolRoundFinalized(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex,
        uint256 finalBlock,
        uint256 prizeBlock
    );
    event PoolRoundExited(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex,
        address user,
        uint256 selectIndex,
        uint256 refundAmount,
        uint256 rewardPoolAmount,
        uint256 maintainPoolAmount
    );
    event PoolRoundSpun(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex,
        address winer,
        uint256 prizeIndex,
        uint256 prizeAmount,
        uint256 rewardPoolAmount,
        uint256 maintainPoolAmount
    );
    event PoolRoundClaimed(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex,
        address winer,
        uint256 prizeIndex,
        uint256 prizeAmount
    );

    enum RoundStatus {
        Pending,
        Done,
        Spun,
        Closed
    }

    struct RoundData {
        uint256 poolPrice;
        uint256 poolMax;
        uint256 finalBlock;
        uint256 userNum;
        mapping(uint256 => address) users;
        mapping(uint256 => uint256) enteredTimes;
        uint256 prizeBlock;
        uint256 prizeIndex;
        address winer;
        uint256 prizeAmount;
        RoundStatus status;
    }

    struct PoolData {
        uint256 roundIndex;
        mapping(uint256 => RoundData) roundMap;
    }

    mapping(uint256 => mapping(uint256 => PoolData)) private _poolMap;

    IERC20 private _currencyERC20;
    address private _poolReward;
    uint256 private _poolRewardRate;
    address private _poolMaintain;
    uint256 private _poolMaintainRate;
    address private _prizeAdmin;

    constructor(IERC20 currencyERC20) public {
        _currencyERC20 = currencyERC20;
        _prizeAdmin = _msgSender();
        _poolReward = _msgSender();
        _poolRewardRate = 900;
        _poolMaintain = _msgSender();
        _poolMaintainRate = 100;
    }

    function getCurrencyERC20() public view virtual returns (IERC20) {
        return _currencyERC20;
    }

    modifier onlyPrizeAdmin() {
        require(
            getPrizeAdmin() == _msgSender(),
            "caller is not the prizeAdmin"
        );
        _;
    }

    function getPrizeAdmin() public view virtual returns (address) {
        return _prizeAdmin;
    }

    function setPrizeAdmin(address addr) public virtual onlyOwner {
        require(addr != address(0), "newAdmin is the zero address");
        _prizeAdmin = addr;
    }

    function getPoolMaintain() public view virtual returns (address) {
        return _poolMaintain;
    }

    function setPoolMaintain(address addr) public virtual onlyOwner {
        require(addr != address(0), "new addr is the zero address");
        _poolMaintain = addr;
    }

    function getPoolMaintainRate() public view virtual returns (uint256) {
        return _poolMaintainRate;
    }

    function setPoolMaintainRate(uint256 rate) public virtual onlyOwner {
        require(rate <= (10000 - _poolRewardRate), "rate is invalid");
        _poolMaintainRate = rate;
    }

    function getPoolReward() public view virtual returns (address) {
        return _poolReward;
    }

    function setPoolReward(address addr) public virtual onlyOwner {
        require(addr != address(0), "new addr is the zero address");
        _poolReward = addr;
    }

    function poolRewardRate() public view virtual returns (uint256) {
        return _poolRewardRate;
    }

    function setPoolRewardRate(uint256 rate) public virtual onlyOwner {
        require(rate <= (10000 - _poolMaintainRate), "rate is invalid");
        _poolRewardRate = rate;
    }

    function createPoolBatch(
        uint256[] memory poolPrices,
        uint256[] memory poolMaxs
    ) external onlyOwner {
        for (uint256 m = 0; m < poolPrices.length; m++) {
            uint256 poolPrice = poolPrices[m];
            for (uint256 n = 0; n < poolMaxs.length; n++) {
                uint256 poolMax = poolMaxs[n];
                createPool(poolPrice, poolMax);
            }
        }
    }

    function createPool(uint256 poolPrice, uint256 poolMax)
        public
        virtual
        onlyOwner
    {
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(pool.roundIndex == 0, "pool is initialized");
        pool.roundIndex += 1;
        emit PoolCreated(poolPrice, poolMax);
        RoundData storage round = pool.roundMap[pool.roundIndex];
        round.status = RoundStatus.Pending;
        round.poolPrice = poolPrice;
        round.poolMax = poolMax;
        emit PoolRoundCreated(poolPrice, poolMax, pool.roundIndex);
    }

    function enterRound(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex,
        uint256 selectIndex
    ) public {
        require(poolMax > selectIndex, "error selectIndex and poolMax");
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(pool.roundIndex > 0, "error pool.roundIndex is zero");
        require(pool.roundIndex == roundIndex, "error roundIndex is not valid");
        RoundData storage round = pool.roundMap[pool.roundIndex];
        require(
            round.status == RoundStatus.Pending,
            "error round status is invalid"
        );
        require(
            round.users[selectIndex] == address(0),
            "error invalid selectIndex"
        );
        require(
            round.enteredTimes[selectIndex] == 0,
            "error invalid selectIndex"
        );
        // update for new enter
        round.users[selectIndex] = _msgSender();
        round.enteredTimes[selectIndex] = block.timestamp;
        round.userNum++;
        _currencyERC20.transferFrom(_msgSender(), address(this), poolPrice);
        emit PoolRoundEntered(
            poolPrice,
            poolMax,
            roundIndex,
            _msgSender(),
            selectIndex,
            poolPrice
        );
        // check final enter
        if (round.userNum >= poolMax) {
            // final round
            round.finalBlock = block.number;
            round.prizeBlock = block.number + 10;
            round.status = RoundStatus.Done;
            emit PoolRoundFinalized(
                poolPrice,
                poolMax,
                roundIndex,
                round.finalBlock,
                round.prizeBlock
            );
            // new round
            _newPoolRound(poolPrice, poolMax);
        }
    }

    function exitRound(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex,
        uint256 selectIndex
    ) public {
        require(poolMax > selectIndex, "error selectIndex and poolMax");
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(pool.roundIndex > 0, "error pool.roundIndex is zero");
        require(
            pool.roundIndex == roundIndex,
            "error pool.roundIndex and roundIndex"
        );
        RoundData storage round = pool.roundMap[pool.roundIndex];
        require(
            round.status == RoundStatus.Pending,
            "error round status is not pending"
        );
        require(
            round.users[selectIndex] == _msgSender(),
            "error invalid entered user"
        );
        require(
            round.enteredTimes[selectIndex] > 0,
            "error invalid entered time"
        );
        // calculate for fee and return
        uint256 enterTime = round.enteredTimes[selectIndex];
        require(
            block.timestamp >= enterTime,
            "error block.timestamp and enterTime"
        );
        uint256 totalAmount = poolPrice;
        uint256 rewardPoolAmount = 0;
        uint256 maintainPoolAmount = 0;
        if (block.timestamp <= (enterTime + (24 * 3600))) {
            rewardPoolAmount = (totalAmount * _poolRewardRate) / 10000;
            maintainPoolAmount = (totalAmount * _poolMaintainRate) / 10000;
        }
        // update for exit
        round.users[selectIndex] = address(0);
        round.enteredTimes[selectIndex] = 0;
        round.userNum--;
        uint256 refundAmount = totalAmount -
            (rewardPoolAmount + maintainPoolAmount);
        _currencyERC20.transfer(_msgSender(), refundAmount);
        if (rewardPoolAmount > 0) {
            _currencyERC20.transfer(_poolReward, rewardPoolAmount);
        }
        if (maintainPoolAmount > 0) {
            _currencyERC20.transfer(_poolMaintain, maintainPoolAmount);
        }
        emit PoolRoundExited(
            poolPrice,
            poolMax,
            roundIndex,
            _msgSender(),
            selectIndex,
            refundAmount,
            rewardPoolAmount,
            maintainPoolAmount
        );
    }

    // only prize admin call
    function spinRound(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex,
        uint256 prizeIndex
    ) external onlyPrizeAdmin {
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(pool.roundIndex > 0, "error pool.roundIndex is zero");
        RoundData storage round = pool.roundMap[roundIndex];
        require(
            round.status == RoundStatus.Done,
            "error round status is not done"
        );
        bytes32 blockHash = blockhash(round.prizeBlock);
        uint256 hashNum = uint256(blockHash);
        if (hashNum > 0) {
            prizeIndex = hashNum % poolMax;
        }
        round.prizeIndex = prizeIndex;
        round.winer = round.users[prizeIndex];
        round.status = RoundStatus.Spun;
        // calculate for fee and return
        uint256 totalAmount = poolPrice * poolMax;
        uint256 rewardPoolAmount = (totalAmount * _poolRewardRate) / 10000;
        uint256 maintainPoolAmount = (totalAmount * _poolMaintainRate) / 10000;
        uint256 prizeAmount = totalAmount -
            (rewardPoolAmount + maintainPoolAmount);
        round.prizeAmount = prizeAmount;
        _currencyERC20.transfer(_poolReward, rewardPoolAmount);
        _currencyERC20.transfer(_poolMaintain, maintainPoolAmount);
        emit PoolRoundSpun(
            poolPrice,
            poolMax,
            roundIndex,
            round.winer,
            round.prizeIndex,
            round.prizeAmount,
            rewardPoolAmount,
            maintainPoolAmount
        );
    }

    function claimRound(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex
    ) public {
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(pool.roundIndex > 0, "error pool.roundIndex is zero");
        RoundData storage round = pool.roundMap[roundIndex];
        require(
            round.status == RoundStatus.Spun,
            "error round status is not spun"
        );
        round.status = RoundStatus.Closed;
        _currencyERC20.transfer(round.winer, round.prizeAmount);
        emit PoolRoundClaimed(
            poolPrice,
            poolMax,
            roundIndex,
            round.winer,
            round.prizeIndex,
            round.prizeAmount
        );
    }

    function _newPoolRound(uint256 poolPrice, uint256 poolMax) private {
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(pool.roundIndex > 0, "error pool.roundIndex is zero");
        RoundData storage round = pool.roundMap[pool.roundIndex];
        require(
            round.status == RoundStatus.Done,
            "error round status is not done"
        );
        pool.roundIndex += 1;
        RoundData storage newRound = pool.roundMap[pool.roundIndex];
        newRound.status = RoundStatus.Pending;
        newRound.poolPrice = poolPrice;
        newRound.poolMax = poolMax;
        emit PoolRoundCreated(poolPrice, poolMax, pool.roundIndex);
    }

    function getPoolRound(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex
    )
        public
        view
        returns (
            uint256 _roundIndex,
            uint256 _userNum,
            address[] memory _users,
            uint256[] memory _enteredTimes,
            uint256 _finalBlock,
            uint256 _prizeBlock,
            uint256 _prizeIndex,
            address _winer,
            uint256 _prizeAmount,
            RoundStatus _status
        )
    {
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(
            pool.roundIndex >= roundIndex,
            "error pool.roundIndex and roundIndex"
        );
        RoundData storage round = pool.roundMap[roundIndex];
        _roundIndex = roundIndex;
        _users = new address[](round.poolMax);
        _enteredTimes = new uint256[](round.poolMax);
        for (uint256 i = 0; i < round.poolMax; i++) {
            _users[i] = round.users[i];
            _enteredTimes[i] = round.enteredTimes[i];
        }
        _finalBlock = round.finalBlock;
        _prizeBlock = round.prizeBlock;
        _prizeIndex = round.prizeIndex;
        _winer = round.winer;
        _userNum = round.userNum;
        _prizeAmount = round.prizeAmount;
        _status = round.status;
        return (
            _roundIndex,
            _userNum,
            _users,
            _enteredTimes,
            _finalBlock,
            _prizeBlock,
            _prizeIndex,
            _winer,
            _prizeAmount,
            _status
        );
    }

    function getCurrentPoolRoundIndex(uint256 poolPrice, uint256 poolMax)
        public
        view
        returns (uint256)
    {
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(pool.roundIndex > 0, "error for pool.roundIndex is zero");
        return pool.roundIndex;
    }

    function getCurrentPoolRound(uint256 poolPrice, uint256 poolMax)
        public
        view
        returns (
            uint256 _roundIndex,
            uint256 _userNum,
            address[] memory _users,
            uint256[] memory _enteredTimes,
            uint256 _finalBlock,
            uint256 _prizeBlock,
            uint256 _prizeIndex,
            address _winer,
            uint256 _prizeAmount,
            RoundStatus _status
        )
    {
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(pool.roundIndex > 0, "error for pool.roundIndex is zero");
        return getPoolRound(poolPrice, poolMax, pool.roundIndex);
    }
}