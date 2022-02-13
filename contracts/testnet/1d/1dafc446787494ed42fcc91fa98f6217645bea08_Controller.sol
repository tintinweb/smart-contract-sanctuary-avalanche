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
        uint256 priizeBlock
    );
    event PoolRoundExited(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex,
        address user,
        uint256 selectIndex,
        uint256 amount,
        uint256 fee
    );
    event PoolRoundPrize(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex,
        address winer,
        uint256 prizeIndex,
        uint256 amount,
        uint256 fee
    );

    struct RoundData {
        uint256 poolPrice;
        uint256 poolMax;
        uint256 finalBlock;
        uint256 prizeBlock;
        uint256 prizeIndex;
        address winer;
        uint256 userNum;
        mapping(uint256 => address) users;
        mapping(uint256 => uint256) enteredTimes;
    }
    struct PoolData {
        uint256 roundIndex;
        mapping(uint256 => RoundData) roundMap;
    }

    mapping(uint256 => mapping(uint256 => PoolData)) private _poolMap;

    IERC20 private _currencyERC20;
    address private _stakerAddr;
    address private _maintainAddr;
    address private _prizeAdmin;

    constructor(
        IERC20 currencyERC20,
        address stakerAddr,
        address maintainAddr
    ) public {
        _currencyERC20 = currencyERC20;
        _stakerAddr = stakerAddr;
        _maintainAddr = maintainAddr;
        _prizeAdmin = _msgSender();
    }

    function prizeAdmin() public view virtual returns (address) {
        return _prizeAdmin;
    }

    modifier onlyPrizeAdmin() {
        require(prizeAdmin() == _msgSender(), "caller is not the prizeAdmin");
        _;
    }

    function setPrizeAdmin(address newAdmin) public virtual onlyOwner {
        require(newAdmin != address(0), "newAdmin is the zero address");
        _prizeAdmin = newAdmin;
    }

    function createPool(uint256 poolPrice, uint256 poolMax) external onlyOwner {
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(pool.roundIndex == 0, "pool is initialized");
        pool.roundIndex += 1;
        emit PoolCreated(poolPrice, poolMax);
        RoundData storage round = pool.roundMap[pool.roundIndex];
        round.poolPrice = poolPrice;
        round.poolMax = poolMax;
        emit PoolRoundCreated(poolPrice, poolMax, pool.roundIndex);
    }

    function getCurrentRoundIndex(uint256 poolPrice, uint256 poolMax)
        public
        view
        returns (uint256)
    {
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(pool.roundIndex > 0, "error for pool.roundIndex is zero");
        return pool.roundIndex;
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
        uint256 feeAmount = 0;
        if (block.timestamp <= (enterTime + (24 * 3600))) {
            feeAmount = totalAmount / 10;
        }
        // update for exit
        round.users[selectIndex] = address(0);
        round.enteredTimes[selectIndex] = 0;
        round.userNum--;
        uint256 returnAmount = totalAmount - feeAmount;
        uint256 stakeAmount = (feeAmount * 9) / 10;
        uint256 maintainAmount = feeAmount - stakeAmount;
        _currencyERC20.transfer(_msgSender(), returnAmount);
        _currencyERC20.transfer(_stakerAddr, stakeAmount);
        _currencyERC20.transfer(_maintainAddr, maintainAmount);
        emit PoolRoundExited(
            poolPrice,
            poolMax,
            roundIndex,
            _msgSender(),
            selectIndex,
            totalAmount,
            feeAmount
        );
    }

    // only prize admin call
    function prizeRound(
        uint256 poolPrice,
        uint256 poolMax,
        uint256 roundIndex,
        uint256 prizeIndex
    ) external onlyPrizeAdmin {
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(pool.roundIndex > 0, "error pool.roundIndex is zero");
        RoundData storage round = pool.roundMap[roundIndex];
        require(round.userNum >= poolMax, "error round.userNum and poolMax");
        require(round.winer == address(0), "error round.winer is not zero");
        bytes32 blockHash = blockhash(round.prizeBlock);
        uint256 hashNum = uint256(blockHash);
        if (hashNum > 0) {
            prizeIndex = hashNum % poolMax;
        }
        address winer = round.users[prizeIndex];
        round.prizeIndex = prizeIndex;
        round.winer = winer;
        // calculate for fee and return
        uint256 totalAmount = poolPrice * poolMax;
        uint256 feeAmount = totalAmount / 10;
        uint256 returnAmount = totalAmount - feeAmount;
        uint256 stakeAmount = (feeAmount * 9) / 10;
        uint256 maintainAmount = feeAmount - stakeAmount;
        _currencyERC20.transfer(winer, returnAmount);
        _currencyERC20.transfer(_stakerAddr, stakeAmount);
        _currencyERC20.transfer(_maintainAddr, maintainAmount);
        emit PoolRoundPrize(
            poolPrice,
            poolMax,
            roundIndex,
            winer,
            prizeIndex,
            totalAmount,
            feeAmount
        );
    }

    function _newPoolRound(uint256 poolPrice, uint256 poolMax) private {
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(pool.roundIndex > 0, "error pool.roundIndex is zero");
        RoundData storage round = pool.roundMap[pool.roundIndex];
        require(
            round.userNum >= round.poolMax,
            "error round.userNum and round.poolMax"
        );
        pool.roundIndex += 1;
        RoundData storage newRound = pool.roundMap[pool.roundIndex];
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
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            address,
            uint256,
            address[] memory users,
            uint256[] memory enteredTimes
        )
    {
        PoolData storage pool = _poolMap[poolPrice][poolMax];
        require(
            pool.roundIndex >= roundIndex,
            "error pool.roundIndex and roundIndex"
        );
        RoundData storage round = pool.roundMap[roundIndex];
        address[] memory _users = new address[](round.poolMax);
        uint256[] memory _enteredTimes = new uint256[](round.poolMax);
        for (uint256 i = 0; i < round.poolMax; i++) {
            _users[i] = round.users[i];
            _enteredTimes[i] = round.enteredTimes[i];
        }
        return (
            round.poolPrice,
            round.poolMax,
            round.finalBlock,
            round.prizeBlock,
            round.prizeIndex,
            round.winer,
            round.userNum,
            _users,
            _enteredTimes
        );
    }
}