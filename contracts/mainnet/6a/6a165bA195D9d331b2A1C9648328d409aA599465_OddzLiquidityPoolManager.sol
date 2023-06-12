// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

import "./IOddzLiquidityPoolManager.sol";
import "../Libs/DateTimeLibrary.sol";
import "../Swap/IDexManager.sol";
import "../OddzMintToken.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

contract OddzLiquidityPoolManager is AccessControl, IOddzLiquidityPoolManager, OddzMintToken {
    using Math for uint256;
    using Address for address;
    using SafeERC20 for IERC20;

    /**
     * @dev Liquidity specific data definitions
     */
    LockedLiquidity[] public lockedLiquidity;
    IERC20 public token;

    /**
     * @dev Liquidity lock and distribution data definitions
     */
    mapping(uint256 => bool) public allowedMaxExpiration;
    mapping(uint256 => uint256) public periodMapper;
    mapping(bytes32 => IOddzLiquidityPool[]) public poolMapper;
    mapping(bytes32 => bool) public uniquePoolMapper;

    /**
     * @dev Active pool count
     */
    mapping(IOddzLiquidityPool => uint256) public override poolExposure;

    /**
     * @dev Disabled pools
     */
    mapping(IOddzLiquidityPool => bool) public disabledPools;

    // user address -> date of transfer
    mapping(address => uint256) public lastPoolTransfer;

    /**
     * @dev deviation mapping to select a pool
     */
    mapping(uint256 => bool) public allowedDeviation;
    mapping(uint256 => uint256) public deviationMapper;

    /**
     * @dev Premium specific data definitions
     */
    uint256 public premiumLockupDuration = 14 days;
    uint256 public moveLockupDuration = 7 days;

    /**
     * @dev DEX manager
     */
    IDexManager public dexManager;

    address public strategyManager;

    /**
     * @dev Access control specific data definitions
     */
    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");
    bytes32 public constant TIMELOCKER_ROLE = keccak256("TIMELOCKER_ROLE");

    modifier onlyOwner(address _address) {
        require(hasRole(DEFAULT_ADMIN_ROLE, _address), "LP Error: caller has no access to the method");
        _;
    }

    modifier onlyManager(address _address) {
        require(hasRole(MANAGER_ROLE, _address), "LP Error: caller has no access to the method");
        _;
    }

    modifier onlyTimeLocker(address _address) {
        require(hasRole(TIMELOCKER_ROLE, _address), "LP Error: caller has no access to the method");
        _;
    }

    modifier validLiquidty(uint256 _id) {
        LockedLiquidity storage ll = lockedLiquidity[_id];
        require(ll._locked, "LP Error: liquidity has already been unlocked");
        _;
    }

    modifier validMaxExpiration(uint256 _maxExpiration) {
        require(allowedMaxExpiration[_maxExpiration] == true, "LP Error: invalid maximum expiration");
        _;
    }

    modifier validCaller(address _provider) {
        require(msg.sender == _provider || msg.sender == strategyManager, "LP Error: invalid caller");
        _;
    }

    modifier validDeviation(uint256 _deviation) {
        require(allowedDeviation[_deviation] == true, "LP Error: invalid deviation");
        _;
    }

    constructor(
        IERC20 _token,
        IDexManager _dexManager,
        uint8 _decimal
    ) OddzMintToken("Oddz USD LP token", "oUSD", _decimal) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(TIMELOCKER_ROLE, msg.sender);
        _setRoleAdmin(TIMELOCKER_ROLE, TIMELOCKER_ROLE);

        token = _token;
        dexManager = _dexManager;

        addAllowedMaxExpiration(1);
        addAllowedMaxExpiration(7);
        addAllowedMaxExpiration(30);
        mapPeriod(1, 1);
        mapPeriod(2, 7);
        mapPeriod(3, 7);
        mapPeriod(4, 7);
        mapPeriod(5, 7);
        mapPeriod(6, 7);
        mapPeriod(7, 7);
        mapPeriod(8, 30);
        mapPeriod(9, 30);
        mapPeriod(10, 30);
        mapPeriod(11, 30);
        mapPeriod(12, 30);
        mapPeriod(13, 30);
        mapPeriod(14, 30);
        mapPeriod(15, 30);
        mapPeriod(16, 30);
        mapPeriod(17, 30);
        mapPeriod(18, 30);
        mapPeriod(19, 30);
        mapPeriod(20, 30);
        mapPeriod(21, 30);
        mapPeriod(22, 30);
        mapPeriod(23, 30);
        mapPeriod(24, 30);
        mapPeriod(25, 30);
        mapPeriod(26, 30);
        mapPeriod(27, 30);
        mapPeriod(28, 30);
        mapPeriod(29, 30);
        mapPeriod(30, 30);
    }

    function addLiquidity(
        address _provider,
        IOddzLiquidityPool _pool,
        uint256 _amount
    ) external override validCaller(_provider) returns (uint256 mint) {
        require(poolExposure[_pool] > 0, "LP Error: Invalid pool");
        require(_amount > 0, "LP Error: Amount is too small");
        mint = _amount;

        _pool.addLiquidity(_amount, _provider);

        _mint(_provider, mint);
        token.safeTransferFrom(_provider, address(this), _amount);
    }

    function removeLiquidity(
        address _provider,
        IOddzLiquidityPool _pool,
        uint256 _amount
    ) external override validCaller(_provider) {
        require(poolExposure[_pool] > 0, "LP Error: Invalid pool");
        require(_amount <= balanceOf(_provider), "LP Error: Amount exceeds oUSD balance");

        uint256 eligiblePremium = _pool.collectPremium(_provider, premiumLockupDuration);
        token.safeTransfer(
            _provider,
            _pool.removeLiquidity(_amount, _provider, premiumLockupDuration) + eligiblePremium
        );

        _burn(_provider, _amount);
    }

    function lockLiquidity(
        uint256 _id,
        LiquidityParams memory _liquidityParams,
        uint256 _premium
    ) external override onlyManager(msg.sender) {
        require(_id == lockedLiquidity.length, "LP Error: Invalid id");
        (address[] memory pools, uint256[] memory poolBalances) = getSortedEligiblePools(_liquidityParams);
        require(pools.length > 0, "LP Error: No pool balance");

        uint8 count = 0;
        uint256 totalAmount = _liquidityParams._amount;
        uint256 base = totalAmount / pools.length;
        uint256[] memory share = new uint256[](pools.length);
        while (count < pools.length) {
            if (base > poolBalances[count]) share[count] = poolBalances[count];
            else share[count] = base;
            IOddzLiquidityPool(pools[count]).lockLiquidity(share[count]);
            totalAmount -= share[count];
            if (totalAmount > 0) base = totalAmount / (pools.length - (count + 1));
            count++;
        }
        lockedLiquidity.push(LockedLiquidity(_liquidityParams._amount, _premium, true, pools, share));
    }

    function unlockLiquidity(uint256 _id) external override onlyManager(msg.sender) validLiquidty(_id) {
        LockedLiquidity storage ll = lockedLiquidity[_id];
        for (uint8 i = 0; i < ll._pools.length; i++) {
            IOddzLiquidityPool(ll._pools[i]).unlockLiquidity(ll._share[i]);
            IOddzLiquidityPool(ll._pools[i]).unlockPremium(_id, (ll._premium * ll._share[i]) / ll._amount);
        }
        ll._locked = false;
    }

    function send(
        uint256 _id,
        address _account,
        uint256 _amount,
        uint256 _settlementFee
    ) external override onlyManager(msg.sender) validLiquidty(_id) {
        (, uint256 transferAmount) = _updateAndFetchLockedLiquidity(_id, _account, _amount, _settlementFee);
        // Transfer Funds
        token.safeTransfer(_account, transferAmount);
        token.safeTransfer(msg.sender, _settlementFee);
    }

    function sendUA(
        uint256 _id,
        address _account,
        uint256 _amount,
        uint256 _settlementFee,
        bytes32 _underlying,
        bytes32 _strike,
        uint32 _deadline,
        uint256 _minAmountsOut
    ) public override onlyManager(msg.sender) validLiquidty(_id) {
        (, uint256 transferAmount) = _updateAndFetchLockedLiquidity(_id, _account, _amount, _settlementFee);
        // Transfer Funds
        token.safeTransfer(dexManager.getExchange(_underlying, _strike), transferAmount);
        // block.timestamp + deadline --> deadline from the current block
        dexManager.swap(
            _strike,
            _underlying,
            dexManager.getExchange(_underlying, _strike),
            _account,
            transferAmount,
            block.timestamp + _deadline,
            _minAmountsOut
        );
        token.safeTransfer(msg.sender, _settlementFee);
    }

    /**
     * @notice Move liquidity between pools
     * @param _poolTransfer source and destination pools with amount of transfer
     */
    function move(address _provider, PoolTransfer memory _poolTransfer) external override validCaller(_provider) {
        require(
            lastPoolTransfer[_provider] == 0 || (lastPoolTransfer[_provider] + moveLockupDuration) < block.timestamp,
            "LP Error: Pool transfer not allowed"
        );
        lastPoolTransfer[_provider] = block.timestamp;
        uint256 availableBalance = 0;
        uint256 sourceSum = 0;
        uint256 destSum = 0;
        for (uint256 i = 0; i < _poolTransfer._source.length; i++) {
            require(
                (poolExposure[_poolTransfer._source[i]] > 0) || disabledPools[_poolTransfer._source[i]],
                "LP Error: Invalid pool"
            );
            availableBalance += _poolTransfer._source[i].removeLiquidity(
                _poolTransfer._sAmount[i],
                _provider,
                moveLockupDuration
            );
            availableBalance += _poolTransfer._source[i].collectPremium(_provider, premiumLockupDuration);
            sourceSum += _poolTransfer._sAmount[i];
        }
        for (uint256 i = 0; i < _poolTransfer._destination.length; i++) {
            require(poolExposure[_poolTransfer._destination[i]] > 0, "LP Error: Invalid pool");
            uint256 damount = _poolTransfer._dAmount[i];
            if (sourceSum > availableBalance) damount = (damount * availableBalance) / sourceSum;
            _poolTransfer._destination[i].addLiquidity(damount, _provider);
            destSum += _poolTransfer._dAmount[i];
        }
        require(sourceSum == destSum, "LP Error: invalid transfer amount");
        if (availableBalance > destSum) {
            availableBalance = availableBalance - destSum;
            token.safeTransfer(_provider, availableBalance);
        } else {
            availableBalance = destSum - availableBalance;
            if (availableBalance == 0) return;
            // Burn the additional oUSD allocated to the user
            require(availableBalance <= balanceOf(_provider), "LP Error: low on oUSD");
            _burn(_provider, availableBalance);
        }
    }

    /**
     * @notice withdraw porfits from the pool
     * @param _pool liquidity pool address
     */
    function withdrawProfits(IOddzLiquidityPool _pool) external {
        require(poolExposure[_pool] > 0, "LP Error: Invalid pool");

        uint256 premium = _pool.collectPremium(msg.sender, premiumLockupDuration);
        require(premium > 0, "LP Error: No premium allocated");

        token.safeTransfer(msg.sender, premium);
    }

    /**
     * @notice withdraw collective porfit from pools
     * @param _pools liquidity pools addresses
     */
    function withdrawAllProfits(IOddzLiquidityPool[] memory _pools) external {
        uint256 premium;
        for (uint256 i = 0; i < _pools.length; i++) {
            require(poolExposure[_pools[i]] > 0, "LP Error: Invalid pool");
            uint256 poolPremium = _pools[i].collectPremium(msg.sender, premiumLockupDuration);
            if (poolPremium > 0) premium += poolPremium;
        }
        if (premium > 0) token.safeTransfer(msg.sender, premium);
    }

    /**
     * @notice update and returns locked liquidity
     * @param _lid Id of LockedLiquidity that should be unlocked
     * @param _account Provider account address
     * @param _amount Funds to be sent
     * @param _feeAmount Fee amount
     */
    function _updateAndFetchLockedLiquidity(
        uint256 _lid,
        address _account,
        uint256 _amount,
        uint256 _feeAmount
    ) private returns (uint256 lockedPremium, uint256 transferAmount) {
        LockedLiquidity storage ll = lockedLiquidity[_lid];
        require(_account != address(0), "LP Error: Invalid address");
        ll._locked = false;
        lockedPremium = ll._premium;
        transferAmount = _amount;
        if (transferAmount > ll._amount) transferAmount = ll._amount;

        for (uint8 i = 0; i < ll._pools.length; i++) {
            IOddzLiquidityPool(ll._pools[i]).unlockLiquidity(ll._share[i]);
            IOddzLiquidityPool(ll._pools[i]).exercisePremium(
                _lid,
                (lockedPremium * ll._share[i]) / ll._amount,
                ((transferAmount + _feeAmount) * ll._share[i]) / ll._amount
            );
        }
    }

    /**
     * @notice return sorted eligible pools
     * @param _liquidityParams Lock liquidity params
     * @return pools sorted pools based on ascending order of available liquidity
     * @return poolBalance sorted in ascending order of available liquidity
     */
    function getSortedEligiblePools(LiquidityParams memory _liquidityParams)
        public
        view
        returns (address[] memory pools, uint256[] memory poolBalance)
    {
        // if _expiration is 86401 i.e. 1 day 1 second, then max 1 day expiration pool will not be eligible
        IOddzLiquidityPool[] memory allPools =
            poolMapper[
                keccak256(
                    abi.encode(
                        _liquidityParams._pair,
                        _liquidityParams._type,
                        _liquidityParams._model,
                        deviationMapper[(_liquidityParams._strike * 100) / _liquidityParams._cp],
                        periodMapper[getActiveDayTimestamp(_liquidityParams._expiration) / 1 days]
                    )
                )
            ];
        uint256 count = 0;
        for (uint8 i = 0; i < allPools.length; i++) {
            if (allPools[i].availableBalance() > 0) {
                count++;
            }
        }
        poolBalance = new uint256[](count);
        pools = new address[](count);
        uint256 j = 0;
        uint256 balance = 0;
        for (uint256 i = 0; i < allPools.length; i++) {
            if (allPools[i].availableBalance() > 0) {
                pools[j] = address(allPools[i]);
                poolBalance[j] = allPools[i].availableBalance();
                balance += poolBalance[j];
                j++;
            }
        }
        (poolBalance, pools) = _sort(poolBalance, pools);
        require(balance >= _liquidityParams._amount, "LP Error: Amount is too large");
    }

    /**
     * @notice Insertion sort based on pool balance since atmost 6 eligible pools
     * @param balance list of liquidity
     * @param pools list of pools with reference to balance
     * @return sorted balance list in ascending order
     * @return sorted pool list in ascending order of balance list
     */
    function _sort(uint256[] memory balance, address[] memory pools)
        private
        pure
        returns (uint256[] memory, address[] memory)
    {
        // Higher deployment cost but betters execution cost
        int256 j;
        uint256 unsignedJ;
        uint256 unsignedJplus1;
        uint256 key;
        address val;
        for (uint256 i = 1; i < balance.length; i++) {
            key = balance[i];
            val = pools[i];
            j = int256(i - 1);
            unsignedJ = uint256(j);
            while ((j >= 0) && (balance[unsignedJ] > key)) {
                unsignedJplus1 = unsignedJ + 1;
                balance[unsignedJplus1] = balance[unsignedJ];
                pools[unsignedJplus1] = pools[unsignedJ];
                j--;
                unsignedJ = uint256(j);
            }
            unsignedJplus1 = uint256(j + 1);
            balance[unsignedJplus1] = key;
            pools[unsignedJplus1] = val;
        }
        return (balance, pools);
    }

    /**
     * @notice Add/update allowed max expiration
     * @param _maxExpiration maximum expiration time of option
     */
    function addAllowedMaxExpiration(uint256 _maxExpiration) public onlyOwner(msg.sender) {
        allowedMaxExpiration[_maxExpiration] = true;
    }

    /**
     * @notice sets the manager for the liqudity pool contract
     * @param _address manager contract address
     * Note: This can be called only by the owner
     */
    function setManager(address _address) external {
        require(_address != address(0) && _address.isContract(), "LP Error: Invalid manager address");
        grantRole(MANAGER_ROLE, _address);
    }

    /**
     * @notice removes the manager for the liqudity pool contract for valid managers
     * @param _address manager contract address
     * Note: This can be called only by the owner
     */
    function removeManager(address _address) external {
        revokeRole(MANAGER_ROLE, _address);
    }

    /**
     * @notice sets the timelocker for the liqudity pool contract
     * @param _address timelocker address
     * Note: This can be called only by the owner
     */
    function setTimeLocker(address _address) external {
        require(_address != address(0), "LP Error: Invalid timelocker address");
        grantRole(TIMELOCKER_ROLE, _address);
    }

    /**
     * @notice removes the timelocker for the liqudity pool contract
     * @param _address timelocker contract address
     * Note: This can be called only by the owner
     */
    function removeTimeLocker(address _address) external {
        revokeRole(TIMELOCKER_ROLE, _address);
    }

    /**
     * @notice map period
     * @param _source source period
     * @param _dest destimation period
     * Note: This can be called only by the owner
     */
    function mapPeriod(uint256 _source, uint256 _dest) public validMaxExpiration(_dest) onlyTimeLocker(msg.sender) {
        periodMapper[_source] = _dest;
    }

    /**
     * @notice Map pools for an option parameters
     * @param _pair Asset pair address
     * @param _type Option type
     * @param _model Option premium model
     * @param _period option period exposure
     * @param _pools eligible pools based on above params
     * Note: This can be called only by the owner
     */
    function mapPool(
        address _pair,
        IOddzOption.OptionType _type,
        bytes32 _model,
        uint256 _deviation,
        uint256 _period,
        IOddzLiquidityPool[] memory _pools
    ) public onlyTimeLocker(msg.sender) {
        require(_pools.length <= 10, "LP Error: pools length should be <= 10");
        // delete all the existing pool mapping
        IOddzLiquidityPool[] storage aPools =
            poolMapper[keccak256(abi.encode(_pair, _type, _model, deviationMapper[_deviation], _period))];
        for (uint256 i = 0; i < aPools.length; i++) {
            delete uniquePoolMapper[
                keccak256(abi.encode(_pair, _type, _model, deviationMapper[_deviation], _period, aPools[i]))
            ];
            poolExposure[aPools[i]] -= 1;
            if (poolExposure[aPools[i]] == 0) disabledPools[aPools[i]] = true;
        }
        delete poolMapper[keccak256(abi.encode(_pair, _type, _model, deviationMapper[_deviation], _period))];

        // add unique pool mapping
        bytes32 uPool;
        for (uint256 i = 0; i < _pools.length; i++) {
            uPool = keccak256(abi.encode(_pair, _type, _model, deviationMapper[_deviation], _period, _pools[i]));
            if (!uniquePoolMapper[uPool]) {
                poolMapper[keccak256(abi.encode(_pair, _type, _model, deviationMapper[_deviation], _period))].push(
                    _pools[i]
                );
                uniquePoolMapper[uPool] = true;
                poolExposure[_pools[i]] += 1;
                disabledPools[_pools[i]] = false;
            }
        }
    }

    /**
     * @notice get active day based on user input timestamp
     * @param _timestamp epoch time
     */
    function getActiveDayTimestamp(uint256 _timestamp) internal pure returns (uint256 activationDate) {
        // activation date should be next day 00 hours if _timestamp % 86400 is greater than 0
        if ((_timestamp % 1 days) > 0) _timestamp = _timestamp + 1 days;
        (uint256 year, uint256 month, uint256 day) = DateTimeLibrary.timestampToDate(_timestamp);
        activationDate = DateTimeLibrary.timestampFromDate(year, month, day);
    }

    /**
     * @notice updates premium lockup duration
     * @param _premiumLockupDuration premium lockup duration
     */
    function updatePremiumLockupDuration(uint256 _premiumLockupDuration) public onlyTimeLocker(msg.sender) {
        require(
            _premiumLockupDuration >= 1 days && _premiumLockupDuration <= 30 days,
            "LP Error: invalid premium lockup duration"
        );
        premiumLockupDuration = _premiumLockupDuration;
    }

    /**
     * @notice updates move lockup duration
     * @param _moveLockupDuration move lockup duration
     */
    function updateMoveLockupDuration(uint256 _moveLockupDuration) public onlyTimeLocker(msg.sender) {
        require(
            _moveLockupDuration >= 3 days && _moveLockupDuration <= 30 days,
            "LP Error: invalid move lockup duration"
        );
        moveLockupDuration = _moveLockupDuration;
    }

    function setStrategyManager(address _strategyManager) public onlyOwner(msg.sender) {
        require(_strategyManager.isContract(), "LP Error: invalid strategy manager");
        strategyManager = _strategyManager;
    }

    /**
     * @notice Add/update allowed deviation
     * @param _deviation deviation from strike to current price
     */
    function addAllowedDeviation(uint256 _deviation) public onlyTimeLocker(msg.sender) {
        allowedDeviation[_deviation] = true;
    }

    /**
     * @notice map deviation
     * @param _source source deviation
     * @param _dest destination deviation
     */
    function mapDeviation(uint256 _source, uint256 _dest) public validDeviation(_dest) onlyTimeLocker(msg.sender) {
        deviationMapper[_source] = _dest;
    }

    function getLockedLiquidity(uint256 _optionId)
        external
        view
        returns (
            uint256 amount,
            uint256 premium,
            bool locked,
            address[] memory pools,
            uint256[] memory shares
        )
    {
        LockedLiquidity memory ll = lockedLiquidity[_optionId];
        amount = ll._amount;
        premium = ll._premium;
        locked = ll._locked;
        pools = ll._pools;
        shares = ll._share;
    }
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./IOddzLiquidityPool.sol";
import "../Option/IOddzOption.sol";

/**
 * @title Oddz USD Liquidity Pool
 * @notice Accumulates liquidity in USD from LPs
 */
interface IOddzLiquidityPoolManager {
    struct LockedLiquidity {
        uint256 _amount;
        uint256 _premium;
        bool _locked;
        address[] _pools;
        uint256[] _share;
    }

    struct LiquidityParams {
        uint256 _amount;
        uint256 _expiration;
        address _pair;
        bytes32 _model;
        uint256 _strike;
        uint256 _cp;
        IOddzOption.OptionType _type;
    }

    /**
     * @dev Pool transfer
     */
    struct PoolTransfer {
        IOddzLiquidityPool[] _source;
        IOddzLiquidityPool[] _destination;
        uint256[] _sAmount;
        uint256[] _dAmount;
    }

    /**
     * @notice A provider supplies USD pegged stablecoin to the pool and receives oUSD tokens
     * @param _provider Liquidity provider
     * @param _pool Liquidity pool
     * @param _amount Amount in USD
     * @return mint Amount of tokens minted
     */
    function addLiquidity(
        address _provider,
        IOddzLiquidityPool _pool,
        uint256 _amount
    ) external returns (uint256 mint);

    /**
     * @notice Provider burns oUSD and receives USD from the pool
     * @param _provider Liquidity provider
     * @param _pool Remove liquidity from a pool
     * @param _amount Amount of USD to receive
     */
    function removeLiquidity(
        address _provider,
        IOddzLiquidityPool _pool,
        uint256 _amount
    ) external;

    /**
     * @notice called by Oddz call options to lock the funds
     * @param _id Id of the LockedLiquidity same as option Id
     * @param _liquidityParams liquidity related parameters
     * @param _premium Premium that should be locked in an option
     */

    function lockLiquidity(
        uint256 _id,
        LiquidityParams memory _liquidityParams,
        uint256 _premium
    ) external;

    /**
     * @notice called by Oddz option to unlock the funds
     * @param _id Id of LockedLiquidity that should be unlocked
     */
    function unlockLiquidity(uint256 _id) external;

    /**
     * @notice called by Oddz call options to send funds in USD to LPs after an option's expiration
     * @param _id Id of LockedLiquidity that should be unlocked
     * @param _account Provider account address
     * @param _amount Funds that should be sent
     * @param _settlementFee Settlement Fee
     */
    function send(
        uint256 _id,
        address _account,
        uint256 _amount,
        uint256 _settlementFee
    ) external;

    /**
     * @notice called by Oddz call options to send funds in UA to LPs after an option's expiration
     * @param _id Id of LockedLiquidity that should be unlocked
     * @param _account Provider account address
     * @param _amount Funds that should be sent
     * @param _settlementFee Settlement Fee
     * @param _underlying underlying asset name
     * @param _strike strike asset name
     * @param _deadline deadline until which txn does not revert
     * @param _minAmountsOut min output tokens
     */
    function sendUA(
        uint256 _id,
        address _account,
        uint256 _amount,
        uint256 _settlementFee,
        bytes32 _underlying,
        bytes32 _strike,
        uint32 _deadline,
        uint256 _minAmountsOut
    ) external;

    /**
     * @notice Move liquidity between pools
     * @param _provider Liquidity provider
     * @param _poolTransfer source and destination pools with amount of transfer
     */
    function move(address _provider, PoolTransfer memory _poolTransfer) external;

    /**
     * @notice Get validity of pool
     * @param _pool address of pool
     */
    function poolExposure(IOddzLiquidityPool _pool) external view returns (uint256);
}

pragma solidity 0.8.3;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
library DateTimeLibrary {
    uint256 constant SECONDS_PER_DAY = 24 * 60 * 60;
    int256 constant OFFSET19700101 = 2440588;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 _days) {
        require(year >= 1970);
        int256 _year = int256(year);
        int256 _month = int256(month);
        int256 _day = int256(day);

        int256 __days =
            _day -
                32075 +
                (1461 * (_year + 4800 + (_month - 14) / 12)) /
                4 +
                (367 * (_month - 2 - ((_month - 14) / 12) * 12)) /
                12 -
                (3 * ((_year + 4900 + (_month - 14) / 12) / 100)) /
                4 -
                OFFSET19700101;

        _days = uint256(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);

        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }

    function timestampFromDate(
        uint256 year,
        uint256 month,
        uint256 day
    ) internal pure returns (uint256 timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }

    /**
     * @dev get day based on the timestamp
     */
    function getPresentDayTimestamp() internal view returns (uint256 todayTimestamp) {
        (uint256 year, uint256 month, uint256 day) = timestampToDate(block.timestamp);
        todayTimestamp = DateTimeLibrary.timestampFromDate(year, month, day);
    }

    /**
     * @dev get start of the day timestamp for a date
     */
    function getTimestampForDate(uint256 _date) internal pure returns (uint256 dayTimestamp) {
        (uint256 year, uint256 month, uint256 day) = timestampToDate(_date);
        dayTimestamp = DateTimeLibrary.timestampFromDate(year, month, day);
    }

    /**
     * @dev get month for the timestamp
     */
    function getMonth(uint256 timestamp) internal pure returns (uint256 month) {
        (, month, ) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

interface IDexManager {
    function getExchange(bytes32 _underlying, bytes32 _strike) external view returns (address exchangeAddress);

    /**
     * @notice Function to swap Tokens
     * @param _fromToken name of the asset to swap from
     * @param _toToken name of the asset to swap to
     * @param _exchange address of the exchange
     * @param _account account to send the swapped tokens to
     * @param _amountIn amount of fromTokens to swap from
     * @param _deadline deadline timestamp for txn to be valid
     * @param _minAmountsOut min amount tokens
     */
    function swap(
        bytes32 _fromToken,
        bytes32 _toToken,
        address _exchange,
        address _account,
        uint256 _amountIn,
        uint256 _deadline,
        uint256 _minAmountsOut
    ) external;
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title ERC20 Token to mint
 * @dev ERC20 Token to mint
 */
contract OddzMintToken is ERC20 {
    uint8 public decimal;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimal
    ) ERC20(_name, _symbol) {
        decimal = _decimal;
    }

    function decimals() public view virtual override returns (uint8) {
        return decimal;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

/**
 * @title Oddz USD Liquidity Pool
 * @notice Accumulates liquidity in USD from LPs
 */
interface IOddzLiquidityPool {
    event AddLiquidity(address indexed _account, uint256 _amount);
    event RemoveLiquidity(address indexed _account, uint256 _amount, uint256 _burn);
    event LockLiquidity(uint256 _amount);
    event UnlockLiquidity(uint256 _amount);
    event PremiumCollected(address indexed _account, uint256 _amount);
    event PremiumForfeited(address indexed _account, uint256 _amount);
    event Profit(uint256 indexed _id, uint256 _amount);
    event Loss(uint256 indexed _id, uint256 _amount);

    enum TransactionType { ADD, REMOVE }
    struct PoolDetails {
        bytes32 _strike;
        bytes32 _underlying;
        bytes32 _optionType;
        bytes32 _model;
        bytes32 _maxExpiration;
    }

    /**
     * @notice returns pool parameters info
     */
    function poolDetails()
        external
        view
        returns (
            bytes32 _strike,
            bytes32 _underlying,
            bytes32 _optionType,
            bytes32 _model,
            bytes32 _maxExpiration
        );

    /**
     * @notice Add liquidity for the day
     * @param _amount USD value
     * @param _account Address of the Liquidity Provider
     */
    function addLiquidity(uint256 _amount, address _account) external;

    /**
     * @notice Provider burns oUSD and receives USD from the pool
     * @param _amount Amount of oUSD to burn
     * @param _account Address of the Liquidity Provider
     * @param _lockDuration premium lockup days
     * @return transferAmount oUSD corresponding amount to user
     */
    function removeLiquidity(
        uint256 _amount,
        address _account,
        uint256 _lockDuration
    ) external returns (uint256 transferAmount);

    /**
     * @notice called by Oddz call options to lock the funds
     * @param _amount Amount of funds that should be locked in an option
     */
    function lockLiquidity(uint256 _amount) external;

    /**
     * @notice called by Oddz option to unlock the funds
     * @param _amount Amount of funds that should be unlocked in an option
     */
    function unlockLiquidity(uint256 _amount) external;

    /**
     * @notice Returns the amount of USD available for withdrawals
     * @return balance Unlocked balance
     */
    function availableBalance() external view returns (uint256);

    /**
     * @notice Returns the total balance of USD provided to the pool
     * @return balance Pool balance
     */
    function totalBalance() external view returns (uint256);

    /**
     * @notice Allocate premium to pool
     * @param _lid liquidity ID
     * @param _amount Premium amount
     */
    function unlockPremium(uint256 _lid, uint256 _amount) external;

    /**
     * @notice Allocate premium to pool
     * @param _lid liquidity ID
     * @param _amount Premium amount
     * @param _transfer Amount i.e will be transferred to option owner
     */
    function exercisePremium(
        uint256 _lid,
        uint256 _amount,
        uint256 _transfer
    ) external;

    /**
     * @notice fetches user premium
     * @param _provider Address of the Liquidity Provider
     */
    function getPremium(address _provider) external view returns (uint256 rewards, bool isNegative);

    /**
     * @notice helper to convert premium to oUSD and sets the premium to zero
     * @param _provider Address of the Liquidity Provider
     * @param _lockDuration premium lockup days
     * @return premium Premium balance
     */
    function collectPremium(address _provider, uint256 _lockDuration) external returns (uint256 premium);

    function getBalance(address _provider) external view returns (uint256 amount);

    function checkWithdraw(address _provider, uint256 _amount) external view returns (bool);

    function getWithdrawAmount(address _provider, uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;
import "./OddzOptionManagerStorage.sol";

/**
 * @title Oddz Call and Put Options
 * @notice Oddz Options Contract
 */
interface IOddzOption {
    enum State { Active, Exercised, Expired }
    enum OptionType { Call, Put }
    enum ExcerciseType { Cash, Physical }

    event Buy(
        uint256 indexed _optionId,
        address indexed _account,
        bytes32 indexed _model,
        uint256 _transactionFee,
        uint256 _totalFee,
        address _pair
    );
    event Exercise(
        uint256 indexed _optionId,
        uint256 _profit,
        uint256 _settlementFee,
        ExcerciseType _type,
        uint256 _assetPrice
    );
    event Expire(uint256 indexed _optionId, uint256 _premium, uint256 _assetPrice);

    struct Option {
        State state;
        address holder;
        uint256 strike;
        uint256 amount;
        uint256 lockedAmount;
        uint256 premium;
        uint256 expiration;
        address pair;
        OptionType optionType;
    }

    struct OptionDetails {
        bytes32 _optionModel;
        uint256 _expiration;
        address _pair;
        uint256 _amount;
        uint256 _strike;
        OptionType _optionType;
    }

    struct PremiumResult {
        uint256 optionPremium;
        uint256 txnFee;
        uint256 iv;
        uint8 ivDecimal;
    }

    /**
     * @notice Buy a new option
     * @param _option Options details
     * @param _premiumWithSlippage Options details
     * @param _buyer Address of option buyer
     * @return optionId Created option ID
     */
    function buy(
        OptionDetails memory _option,
        uint256 _premiumWithSlippage,
        address _buyer
    ) external returns (uint256 optionId);

    /**
     * @notice getPremium of option
     * @param _option Options details
     * @param _buyer Address of option buyer
     * @return premiumResult premium Result Created option ID
     */
    function getPremium(OptionDetails memory _option, address _buyer)
        external
        view
        returns (PremiumResult memory premiumResult);

    /**
     * @notice Exercises an active option
     * @param _optionId Option ID
     */
    function exercise(uint256 _optionId) external;

    /**
     * @notice Exercises an active option in underlying asset
     * @param _optionId Option ID
     * @param _deadline Deadline until which txn does not revert
     * @param _minAmountOut minimum amount of tokens
     */
    function exerciseUA(
        uint256 _optionId,
        uint32 _deadline,
        uint256 _minAmountOut
    ) external;

    function optionStorage() external view returns (OddzOptionManagerStorage ostorage);

    function minimumPremium() external view returns (uint256 premium);

    function setTransactionFee(uint256 _amount) external;

    function getTransactionFee(uint256 _amount, address _buyer) external view returns (uint256 txnFee);

    function getProfit(uint256 _optionID) external view returns (uint256 profit, uint256 settlementFee);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: BSD-4-Clause
pragma solidity 0.8.3;

import "./IOddzOption.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract OddzOptionManagerStorage is AccessControl {
    using Address for address;

    bytes32 public constant MANAGER_ROLE = keccak256("MANAGER_ROLE");

    IOddzOption.Option[] public options;
    /**
     * @dev option transfer map
     * mapping (optionId => minAmount)
     */
    mapping(uint256 => uint256) public optionTransferMap;

    modifier onlyManager(address _address) {
        require(hasRole(MANAGER_ROLE, _address), "caller has no access to the method");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setManager(address _address) external {
        require(_address != address(0) && _address.isContract(), "Invalid manager address");
        grantRole(MANAGER_ROLE, _address);
    }

    function createOption(IOddzOption.Option memory _option) external onlyManager(msg.sender) {
        options.push(_option);
    }

    function getOption(uint256 _optionId) external view returns (IOddzOption.Option memory option) {
        option = options[_optionId];
    }

    function getOptionsCount() external view returns (uint256 count) {
        count = options.length;
    }

    function setOptionStatus(uint256 _optionId, IOddzOption.State _state) external onlyManager(msg.sender) {
        IOddzOption.Option storage option = options[_optionId];
        option.state = _state;
    }

    function setOptionHolder(uint256 _optionId, address _holder) external onlyManager(msg.sender) {
        IOddzOption.Option storage option = options[_optionId];
        option.holder = _holder;
    }

    function addOptionTransfer(uint256 _optionId, uint256 _minAmount) external onlyManager(msg.sender) {
        optionTransferMap[_optionId] = _minAmount;
    }

    function removeOptionTransfer(uint256 _optionId) external onlyManager(msg.sender) {
        delete optionTransferMap[_optionId];
    }

    function getOptionTransfer(uint256 _optionId) external view returns (uint256 minAmount) {
        minAmount = optionTransferMap[_optionId];
    }
}