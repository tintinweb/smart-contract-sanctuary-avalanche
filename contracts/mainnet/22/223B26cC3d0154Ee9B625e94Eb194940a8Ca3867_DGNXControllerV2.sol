// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

import './../interfaces/IDGNXController.sol';
import './../interfaces/IDGNXDisburser.sol';
import './../interfaces/IFactory.sol';
import './../interfaces/IPair.sol';
import './../interfaces/IERC20.sol';
import './DGNXLibrary.sol';

contract DGNXControllerV2 is IDGNXController, ReentrancyGuard, Ownable {
    bool public inFee = false;
    bool public applyFee = true;

    // taxation
    uint256 public burnTax = 100;
    uint256 public backingTax = 200;
    uint256 public liquidityTax = 300;
    uint256 public marketingTax = 100;
    uint256 public platformTax = 200;
    uint256 public investmentFundTax = 200;

    // threshold for liquidity boosting
    uint256 public liquidityThreshold = 20 * 10**18; // 20 AVAX for now

    // track liquidity for boosting
    uint256 public liquidityWAVAX;

    // Some basic stuff we need
    address public constant DEV = 0xdF090f6675034Fde637031c6590FD1bBeBc4fa45;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public constant MARKETING =
        0x16eF18E42A7d72E52E9B213D7eABA269B90A4643;
    address public constant BACKING =
        0x31CE1540414361cFf99e83a05e4ad6d35D425202;
    address public constant PLATFORM =
        0xcA01A9d36F47561F03226B6b697B14B9274b1B10;
    address public constant INVESTMENT_FUND =
        0x829619513F202e1bFD8929f656EF96bac73BDAe8;
    address public constant DISBURSER =
        0x8a0E3264Da08bf999AfF5a50AabF5d2dc89fab79;
    address public constant LOCKER = 0x2c7D8bB6aBA4FFf56cDDBF9ea47ed270A10098F7;

    // needs to be set
    address public previousController;
    address public dgnx;
    address public wavax;
    address public mainPair;

    // track all pairs
    address[] private allPairs;

    mapping(address => address[]) private pairsPath;
    mapping(address => bool) private pairs;
    mapping(address => bool) private factories;
    mapping(address => bool) private allowedContracts;

    event PairAdded(address pair, address[] pathToWAVAX, address sender);
    event PairRemoved(address pair, address sender);
    event FactoryAdded(address factory, address sender);
    event FactoryRemoved(address factory, address sender);
    event TurnFeesOn(address sender);
    event TurnFeesOff(address sender);
    event MigratingController(address originalSender);
    event RecoverToken(address sender, address asset, uint256 amount);
    event AllowContract(address sender, address target);
    event RemoveContract(address sender, address target);
    event SetBurnTax(address sender, uint256 tax);
    event SetBackingTax(address sender, uint256 tax);
    event SetLiquidityTax(address sender, uint256 tax);
    event SetMarketingTax(address sender, uint256 tax);
    event SetPlatformTax(address sender, uint256 tax);
    event SetInvestmentFundTax(address sender, uint256 tax);
    event SetLiquidityThreshold(address sender, uint256 threshold);
    event BoostLiquidity(
        address token0,
        uint256 amount0,
        address token1,
        uint256 amount1,
        address sender
    );

    constructor(
        address _dgnx,
        address _wavax,
        address[] memory _factories,
        address[] memory _pairs,
        address _mainPair
    ) {
        require(_dgnx != address(0), 'DGNXController::constructor wrong dgnx');
        require(
            _wavax != address(0),
            'DGNXController::constructor wrong wavax'
        );
        require(
            _dgnx != _wavax,
            'DGNXController::constructor dgnx and wavax same token'
        );
        require(
            _factories.length >= 2 &&
                _pairs.length >= 2 &&
                _factories.length == _pairs.length,
            'DGNXController::constructor mismatching factories and pairs'
        );

        dgnx = _dgnx;
        wavax = _wavax;

        address[] memory path;
        bool hasMainPair = false;
        for (uint256 i = 0; i < _factories.length; i++) {
            require(
                _factories[i] == IPair(_pairs[i]).factory(),
                'DGNXController::constructor pair factory and factory mismatch'
            );
            addFactory(_factories[i]);
            addPair(_pairs[i], path);
            if (_mainPair == _pairs[i]) {
                hasMainPair = true;
            }
        }

        require(
            hasMainPair,
            'DGNXController::constructor main pair is not available in pairs'
        );

        setMainPair(_mainPair);
        allowContract(_dgnx);
    }

    modifier onlyAllowed() {
        _onlyAllowed();
        _;
    }

    function _onlyAllowed() private view {
        require(
            allowedContracts[msg.sender] || msg.sender == owner(),
            'DGNXController::_onlyAllowed not allowed'
        );
    }

    function transferFees(
        address from,
        address to,
        uint256 amount
    ) external virtual onlyAllowed returns (uint256 newAmount) {
        require(amount > 0, 'DGNXController::transferFees no amount set');

        bool isSell = isPair(to);
        bool isBuy = isPair(from);

        // Disburser Wallet Transfer Tax
        if (isDisburserWallet(to) && !isSell && !isBuy && from != DISBURSER) {
            uint256 leftover = amount % 10000;
            uint256 tax = (((amount - leftover) * 500) / 10000) + leftover;
            safeTransfer(dgnx, LOCKER, tax);
            return amount - tax;
        }

        if (
            isAllowed(from) ||
            isAllowed(to) ||
            (!isSell && !isBuy) ||
            !applyFee ||
            inFee
        ) return amount;

        (
            uint256 _newAmount,
            uint256 _liquidityAmount,
            uint256 _backingAmount,
            uint256 _burnAmount,
            uint256 _marketingAmount,
            uint256 _platformAmount,
            uint256 _investmentFundAmount
        ) = estimateTransferFees(from, to, amount);

        uint256 swapAmount = amount - _newAmount - _burnAmount;

        newAmount = _newAmount;

        // enter fee
        inFee = true;

        if (_burnAmount > 0) {
            safeTransfer(dgnx, DEAD, _burnAmount);
        }

        if (allPairs.length > 1) {
            address currentPair = isSell ? to : from;
            uint256 wavaxBefore = IERC20(wavax).balanceOf(address(this));

            (, address swapPair) = bestWAVAXValue(swapAmount, currentPair);

            address _factory = IPair(swapPair).factory();

            // swap start >> dgnx > wavax
            address[] memory path = getPathForPair(swapPair, dgnx);
            uint256[] memory amounts = getAmountsOut(
                _factory,
                swapAmount,
                path
            );
            safeTransfer(path[0], swapPair, amounts[0]);
            _swap(_factory, amounts, path, address(this));
            // swap end

            uint256 receivedWavax = IERC20(wavax).balanceOf(address(this)) -
                wavaxBefore;

            uint256 _backing = (receivedWavax * _backingAmount) / swapAmount;
            uint256 _platform = (receivedWavax * _platformAmount) / swapAmount;
            uint256 _investment = (receivedWavax * _investmentFundAmount) /
                swapAmount;

            if (_backing > 0) {
                safeTransfer(wavax, BACKING, _backing);
            }

            if (_platform > 0) {
                uint256 _devAmount = (_platform * 40) / 100; // 40%
                _platform -= _devAmount; // 60%
                safeTransfer(wavax, DEV, _devAmount);
                safeTransfer(wavax, PLATFORM, _platform);
            }

            if (_investment > 0) {
                safeTransfer(wavax, INVESTMENT_FUND, _investment);
            }

            if (_marketingAmount > 0) {
                uint256 _amount = (receivedWavax * _marketingAmount) /
                    swapAmount;
                safeTransfer(wavax, MARKETING, _amount);
            }

            // rest of wavax on contract will be used for liquidity boosting
            liquidityWAVAX = IERC20(wavax).balanceOf(address(this));

            if (
                mainPair != currentPair && liquidityWAVAX >= liquidityThreshold
            ) {
                boostLiquidity();
            }
        } else {
            // return amount to sender
            newAmount += _liquidityAmount;

            if (_backingAmount > 0) {
                safeTransfer(dgnx, BACKING, _backingAmount);
            }

            if (_platformAmount > 0) {
                uint256 _devAmount = (_platformAmount * 40) / 100; // 40%
                _platformAmount -= _devAmount; // 60%
                safeTransfer(dgnx, DEV, _devAmount);
                safeTransfer(dgnx, PLATFORM, _platformAmount);
            }

            if (_investmentFundAmount > 0) {
                safeTransfer(dgnx, INVESTMENT_FUND, _investmentFundAmount);
            }

            if (_marketingAmount > 0) {
                safeTransfer(dgnx, MARKETING, _marketingAmount);
            }
        }

        // leave fee
        inFee = false;
    }

    function estimateTransferFees(
        address from,
        address to,
        uint256 amount
    )
        public
        view
        returns (
            uint256 newAmount,
            uint256 _liquidityAmount,
            uint256 _backingAmount,
            uint256 _burnAmount,
            uint256 _marketingAmount,
            uint256 _platformAmount,
            uint256 _investmentFundAmount
        )
    {
        require(
            amount > 0,
            'DGNXController::estimateTransferFees no amount set'
        );

        bool isSell = isPair(to);
        bool isBuy = isPair(from);

        // Disburser Wallet Transfer Tax
        if (isDisburserWallet(to) && !isSell && !isBuy && from != DISBURSER) {
            uint256 leftover = amount % 10000;
            uint256 tax = (((amount - leftover) * 500) / 10000) + leftover;
            return (amount - tax, 0, 0, 0, 0, 0, 0);
        }

        if (
            isAllowed(from) ||
            isAllowed(to) ||
            (!isSell && !isBuy) ||
            !applyFee ||
            inFee
        ) return (amount, 0, 0, 0, 0, 0, 0);

        _liquidityAmount = (amount * liquidityTax) / 10000;
        _backingAmount = (amount * backingTax) / 10000;
        _platformAmount = (amount * platformTax) / 10000;
        _investmentFundAmount = (amount * investmentFundTax) / 10000;
        newAmount =
            amount -
            (_backingAmount +
                _liquidityAmount +
                _platformAmount +
                _investmentFundAmount);

        if (isSell) {
            _burnAmount = (amount * burnTax) / 10000;
            newAmount -= _burnAmount;
        } else {
            _marketingAmount = (amount * marketingTax) / 10000;
            newAmount -= _marketingAmount;
        }
    }

    function boostLiquidity() public onlyAllowed nonReentrant {
        uint256 forSwap = liquidityWAVAX / 2;
        uint256 forLiquidity = liquidityWAVAX - forSwap;

        address _factory = IPair(mainPair).factory();
        address _t0 = IPair(mainPair).token0();
        address _t1 = IPair(mainPair).token1();

        // swap start >> wavax > dgnx
        address[] memory path = getPathForPair(mainPair, wavax);
        uint256[] memory amounts = getAmountsOut(_factory, forSwap, path);
        safeTransfer(path[0], mainPair, amounts[0]);
        _swap(_factory, amounts, path, address(this));
        // swap end

        (uint256 amountA, uint256 amountB, ) = addLiquidity(
            _factory,
            _t0,
            _t1,
            amounts[amounts.length - 1],
            forLiquidity,
            PLATFORM
        );

        // update current wavax with leftovers
        liquidityWAVAX = IERC20(wavax).balanceOf(address(this));

        emit BoostLiquidity(_t0, amountA, _t1, amountB, msg.sender);
    }

    function addLiquidity(
        address factory,
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        address to
    )
        internal
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        )
    {
        (uint256 reserveA, uint256 reserveB) = DGNXLibrary.getReserves(
            factory,
            tokenA,
            tokenB
        );
        if (reserveA == 0 && reserveB == 0) {
            (amountA, amountB) = (amountADesired, amountBDesired);
        } else {
            uint256 amountBOptimal = DGNXLibrary.quote(
                amountADesired,
                reserveA,
                reserveB
            );
            if (amountBOptimal <= amountBDesired) {
                (amountA, amountB) = (amountADesired, amountBOptimal);
            } else {
                uint256 amountAOptimal = DGNXLibrary.quote(
                    amountBDesired,
                    reserveB,
                    reserveA
                );
                assert(amountAOptimal <= amountADesired);
                (amountA, amountB) = (amountAOptimal, amountBDesired);
            }
        }
        address pair = IFactory(factory).getPair(tokenA, tokenB);
        safeTransfer(tokenA, pair, amountA);
        safeTransfer(tokenB, pair, amountB);
        liquidity = IPair(pair).mint(to);
    }

    function _swap(
        address factory,
        uint256[] memory amounts,
        address[] memory path,
        address _to
    ) internal {
        for (uint256 i; i < path.length - 1; i++) {
            (address input, address output) = (path[i], path[i + 1]);
            (address token0, ) = DGNXLibrary.sortTokens(input, output);
            uint256 amountOut = amounts[i + 1];
            (uint256 amount0Out, uint256 amount1Out) = input == token0
                ? (uint256(0), amountOut)
                : (amountOut, uint256(0));
            address to = i < path.length - 2
                ? IFactory(factory).getPair(output, path[i + 2])
                : _to;
            IPair(IFactory(factory).getPair(input, output)).swap(
                amount0Out,
                amount1Out,
                to,
                new bytes(0)
            );
        }
    }

    function bestWAVAXValue(uint256 tokenAmount, address ignorePair)
        internal
        view
        returns (uint256 value, address usePair)
    {
        if (allPairs.length > 0 && tokenAmount > 0) {
            uint256 currentValue;
            for (uint256 i; i < allPairs.length; i++) {
                address pair = allPairs[i];
                if (ignorePair != pair) {
                    address[] memory path = getPathForPair(pair, dgnx);
                    uint256[] memory amounts = getAmountsOut(
                        IPair(pair).factory(),
                        tokenAmount,
                        path
                    );
                    currentValue = amounts[amounts.length - 1];
                    if (currentValue > value) {
                        value = currentValue;
                        usePair = pair;
                    }
                }
            }
        }
    }

    /**
     * Add example:
     *   addr => DGNX/BNB
     *   pathToWAVAX => BNB => WAVAX
     */
    function addPair(address addr, address[] memory pathToWAVAX)
        public
        onlyAllowed
    {
        require(addr != address(0), 'DGNXController::addPair no pair');
        require(
            IPair(addr).factory() != address(0),
            'DGNXController::addPair no factory'
        );
        require(
            factories[IPair(addr).factory()],
            'DGNXController::addPair wrong factory'
        );
        require(!pairs[addr], 'DGNXController::addPair pair already exists');
        address t0 = IPair(addr).token0();
        address t1 = IPair(addr).token1();
        require(t0 == dgnx || t1 == dgnx, 'DGNXController::addPair no dgnx');
        (t0, t1) = t0 == dgnx ? (t0, t1) : (t1, t0);
        if (pathToWAVAX.length == 1)
            revert('DGNXController::addPair swap path needs 2 addresses');
        if (pathToWAVAX.length > 1) {
            require(
                pathToWAVAX[0] == t1,
                'DGNXController::addPair wrong paired token path'
            );
            require(
                pathToWAVAX[pathToWAVAX.length - 1] == wavax,
                'DGNXController::addPair wrong wavax path'
            );
            for (uint256 i; i < pathToWAVAX.length - 1; i++) {
                require(
                    IFactory(IPair(addr).factory()).getPair(
                        pathToWAVAX[i],
                        pathToWAVAX[i + 1]
                    ) != address(0),
                    'DGNXController::addPair invalid pair'
                );
            }
            pairsPath[addr] = pathToWAVAX;
        } else {
            require(
                t0 == wavax || t1 == wavax,
                'DGNXController::addPair no busd token'
            );
        }

        pairs[addr] = true;
        allPairs.push(addr);

        emit PairAdded(addr, pathToWAVAX, msg.sender);
    }

    function removePair(address addr) external onlyOwner {
        require(pairs[addr], 'DGNXController::removePair no pair');
        pairs[addr] = false;
        emit PairRemoved(addr, msg.sender);
    }

    function isPair(address addr) private view returns (bool) {
        return pairs[addr];
    }

    function addFactory(address addr) public onlyOwner {
        require(addr != address(0), 'DGNXController::addFactory wrong address');
        require(
            !factories[addr],
            'DGNXController::addFactory already existing'
        );
        factories[addr] = true;
        emit FactoryAdded(addr, msg.sender);
    }

    function removeFactory(address addr) external onlyOwner {
        require(factories[addr], 'DGNXController::removeFactory not existing');
        factories[addr] = false;
        emit FactoryRemoved(addr, msg.sender);
    }

    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) public view returns (uint256[] memory amounts) {
        return DGNXLibrary.getAmountsOut(factory, amountIn, path);
    }

    function getPathForPair(address addr, address from)
        internal
        view
        returns (address[] memory path)
    {
        (address t0, address t1) = IPair(addr).token0() == from
            ? (IPair(addr).token0(), IPair(addr).token1())
            : (IPair(addr).token1(), IPair(addr).token0());

        if (pairsPath[addr].length == 0) {
            path = new address[](2);
            (path[0], path[1]) = (t0, t1);
        } else {
            path = new address[](pairsPath[addr].length + 1);
            path[0] = t0;
            for (uint256 j; j < pairsPath[addr].length; j++) {
                path[j + 1] = pairsPath[addr][j];
            }
        }
    }

    function feeOff() external onlyAllowed {
        applyFee = false;
        emit TurnFeesOff(msg.sender);
    }

    function feeOn() external onlyAllowed {
        applyFee = true;
        emit TurnFeesOn(msg.sender);
    }

    // if we update controller, we need to transfer funds to new controller. This will be called by new controller and add all factories and pairs
    function migrate() external onlyAllowed nonReentrant {
        uint256 balanceDgnx = IERC20(dgnx).balanceOf(address(this));
        uint256 balanceWavax = IERC20(wavax).balanceOf(address(this));
        if (balanceDgnx > 0) {
            safeTransfer(dgnx, msg.sender, balanceDgnx);
        }
        if (balanceWavax > 0) {
            safeTransfer(wavax, msg.sender, balanceWavax);
        }
        for (uint256 i; i < allPairs.length; i++) {
            uint256 lpTokens = IERC20(allPairs[i]).balanceOf(address(this));
            if (lpTokens > 0) {
                safeTransfer(allPairs[i], msg.sender, lpTokens);
            }
            address _t0 = IPair(allPairs[i]).token0();
            address _t1 = IPair(allPairs[i]).token1();
            uint256 _t0Balance = IERC20(_t0).balanceOf(address(this));
            uint256 _t1Balance = IERC20(_t1).balanceOf(address(this));
            if (_t0Balance > 0) {
                safeTransfer(_t0, msg.sender, _t0Balance);
            }
            if (_t1Balance > 0) {
                safeTransfer(_t1, msg.sender, _t1Balance);
            }
        }
    }

    // this is called by the token to initiate the migration from the new controller
    function migration(address _previousController)
        external
        onlyAllowed
        nonReentrant
    {
        require(
            _previousController != address(this) &&
                _previousController != address(0),
            'DGNXController::migration wrong controller address'
        );
        previousController = _previousController;
        IDGNXController(previousController).migrate();

        // move migrated pool tokens to platform multisig
        safeTransfer(
            mainPair,
            PLATFORM,
            IERC20(mainPair).balanceOf(address(this))
        );

        // burn migrated dgnx
        safeTransfer(dgnx, DEAD, IERC20(dgnx).balanceOf(address(this)));

        // move wavax to marketing
        safeTransfer(wavax, MARKETING, IERC20(wavax).balanceOf(address(this)));

        emit MigratingController(tx.origin);
    }

    // if there are any tokens send by accident, we can revover it
    function recoverToken(address token, address to)
        external
        onlyAllowed
        nonReentrant
    {
        require(dgnx != token, 'DGNXController::recoverToken No drain allowed');
        require(
            wavax != token,
            'DGNXController::recoverToken No drain allowed'
        );
        for (uint256 i; i < allPairs.length; i++) {
            require(
                allPairs[i] != token,
                'DGNXController::recoverToken No drain allowed'
            );
        }
        uint256 amount = IERC20(token).balanceOf(address(this));
        safeTransfer(token, to, amount);
        emit RecoverToken(msg.sender, token, amount);
    }

    function allowContract(address addr) public onlyAllowed nonReentrant {
        require(
            addr != address(0),
            'DGNXController::allowContract zero address'
        );
        require(addr != DEAD, 'DGNXController::allowContract 0xdead address');
        require(
            addr.code.length > 0,
            'DGNXController::allowContract no contract'
        );
        allowedContracts[addr] = true;
        emit AllowContract(msg.sender, addr);
    }

    function removeContract(address addr) external onlyAllowed {
        require(
            allowedContracts[addr],
            'DGNXController::removeContract no contract'
        );
        delete allowedContracts[addr];
        emit RemoveContract(msg.sender, addr);
    }

    function isAllowed(address addr) public view returns (bool) {
        return allowedContracts[addr];
    }

    function isDisburserWallet(address addr) private view returns (bool) {
        return IDGNXDisburser(DISBURSER).legacyAmounts(addr) > 0;
    }

    function setMainPair(address pair) public onlyOwner {
        require(pair != address(0), 'DGNXController::setMainPair zero address');
        require(
            pair != mainPair,
            'DGNXController::setMainPair pair already set'
        );
        mainPair = pair;
    }

    function getAllPairs() external view returns (address[] memory addr) {
        addr = allPairs;
    }

    function setBurnTax(uint256 _tax) external onlyOwner {
        require(_tax <= 500, 'DGNXController::setBurnTax max tax is 5');
        burnTax = _tax;
        emit SetBurnTax(msg.sender, _tax);
    }

    function setBackingTax(uint256 _tax) external onlyOwner {
        require(_tax <= 500, 'DGNXController::setBackingTax max tax is 5');
        backingTax = _tax;
        emit SetBackingTax(msg.sender, _tax);
    }

    function setLiquidityTax(uint256 _tax) external onlyOwner {
        require(_tax <= 500, 'DGNXController::setLiquidityTax max tax is 5');
        liquidityTax = _tax;
        emit SetLiquidityTax(msg.sender, _tax);
    }

    function setMarketingTax(uint256 _tax) external onlyOwner {
        require(_tax <= 500, 'DGNXController::setMarketingTax max tax is 5');
        marketingTax = _tax;
        emit SetMarketingTax(msg.sender, _tax);
    }

    function setPlatformTax(uint256 _tax) external onlyOwner {
        require(_tax <= 500, 'DGNXController::setPlatformTax max tax is 5');
        platformTax = _tax;
        emit SetPlatformTax(msg.sender, _tax);
    }

    function setInvestmentFundTax(uint256 _tax) external onlyOwner {
        require(
            _tax <= 500,
            'DGNXController::setInvestmentFundTax max tax is 5'
        );
        investmentFundTax = _tax;
        emit SetInvestmentFundTax(msg.sender, _tax);
    }

    function setLiquidityThreshold(uint256 _threshold) external onlyOwner {
        liquidityThreshold = _threshold;
        emit SetLiquidityThreshold(msg.sender, _threshold);
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'DGNXController::safeTransfer TRANSFER_FAILED'
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDGNXController {
    function transferFees(
        address from,
        address to,
        uint256 amount
    ) external returns (uint256 newAmount);

    function estimateTransferFees(
        address from,
        address to,
        uint256 amount
    )
        external
        returns (
            uint256 newAmount,
            uint256 _liquidityAmount,
            uint256 _backingAmount,
            uint256 _burnAmount,
            uint256 _marketingAmount,
            uint256 _platformAmount,
            uint256 _launchpadAmount
        );

    function migration(address _previousController) external;

    function migrate() external;

    function allowContract(address addr) external;

    function removeContract(address addr) external;

    function recoverToken(address token, address to) external;

    function isAllowed(address addr) external view returns (bool);

    function feeOff() external;

    function feeOn() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IDGNXDisburser {
    function legacyAmounts(address addr) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IFactory {
    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IPair {
    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function mint(address to) external returns (uint256 liquidity);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import './../interfaces/IFactory.sol';
import './../interfaces/IPair.sol';

library DGNXLibrary {
    using SafeMath for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB)
        internal
        pure
        returns (address token0, address token1)
    {
        require(tokenA != tokenB, 'DGNXLibrary: IDENTICAL_ADDRESSES');
        (token0, token1) = tokenA < tokenB
            ? (tokenA, tokenB)
            : (tokenB, tokenA);
        require(token0 != address(0), 'DGNXLibrary: ZERO_ADDRESS');
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IPair(
            IFactory(factory).getPair(tokenA, tokenB)
        ).getReserves();
        (reserveA, reserveB) = tokenA == token0
            ? (reserve0, reserve1)
            : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, 'DGNXLibrary: INSUFFICIENT_AMOUNT');
        require(
            reserveA > 0 && reserveB > 0,
            'DGNXLibrary: INSUFFICIENT_LIQUIDITY'
        );
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, 'DGNXLibrary: INSUFFICIENT_INPUT_AMOUNT');
        require(
            reserveIn > 0 && reserveOut > 0,
            'DGNXLibrary: INSUFFICIENT_LIQUIDITY'
        );
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, 'DGNXLibrary: INVALID_PATH');
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(
                factory,
                path[i],
                path[i + 1]
            );
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}