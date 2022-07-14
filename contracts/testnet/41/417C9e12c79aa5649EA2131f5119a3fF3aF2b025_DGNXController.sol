// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import './DGNXLibrary.sol';

// import 'hardhat/console.sol';

contract DGNXController is ReentrancyGuard, Ownable {
    using SafeERC20 for ERC20;
    using Address for address;
    using SafeMath for uint256;

    bool public inFee = false;
    bool public applyFee = true;

    // track busd
    uint256 public liquidityBUSD;

    // taxation
    uint256 public burnTax = 100;
    uint256 public backingTax = 200;
    uint256 public liquidityTax = 300;
    uint256 public marketingTax = 100;
    uint256 public platformTax = 200;
    uint256 public launchpadTax = 200;

    // collect tokens for purpose
    uint256 public burnAmount;
    uint256 public backingAmount;
    uint256 public liquidityAmount;
    uint256 public marketingAmount;
    uint256 public platformAmount;
    uint256 public launchpadAmount;

    // define thresholds for transfers
    uint256 public backingThreshold = 1000 * 10**18;
    uint256 public liquidityThreshold = 5 * 10**18;
    uint256 public platformThreshold = 1000 * 10**18;
    uint256 public launchpadThreshold = 1000 * 10**18;

    // Some basic stuff we need
    address public constant DEV = 0x1F23DC4dbD0aa957265243E94e131c414ebcaa11;
    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address public constant MARKETING =
        0x1F23DC4dbD0aa957265243E94e131c414ebcaa11;
    address public constant BACKING =
        0x1F23DC4dbD0aa957265243E94e131c414ebcaa11;
    address public constant PLATFORM =
        0x1F23DC4dbD0aa957265243E94e131c414ebcaa11;
    address public constant LAUNCHPAD =
        0x1F23DC4dbD0aa957265243E94e131c414ebcaa11;

    // needs to be set
    address public previousController;
    address public dgnx;
    address public busd;
    address public mainPair;

    // track all pairs
    address[] private allPairs;

    mapping(address => bool) private pairs;
    mapping(address => address[]) private pairsPath;
    mapping(address => bool) private factories;
    mapping(address => bool) private allowedContracts;

    event PairAdded(address pair, address[] pathToBUSD, address sender);
    event PairRemoved(address pair, address sender);
    event FactoryAdded(address factory, address sender);
    event FactoryRemoved(address factory, address sender);

    event DistributeLiquidity(
        address token0,
        uint256 amount0,
        address token1,
        uint256 amount1,
        address sender
    );

    uint256 constant MAX_INT = 2**256 - 1;

    constructor(address _dgnx, address _busd) {
        require(_dgnx != address(0), 'wrong token');
        require(_busd != address(0), 'wrong token');
        require(_dgnx != _busd, 'wrong token');
        dgnx = _dgnx;
        busd = _busd;
        allowedContracts[_dgnx] = true;
    }

    modifier onlyAllowed() {
        _onlyAllowed();
        _;
    }

    function _onlyAllowed() private view {
        require(
            allowedContracts[msg.sender] || msg.sender == owner(),
            'not allowed'
        );
    }

    function transferFees(
        address from,
        address to,
        uint256 amount
    ) external virtual onlyAllowed returns (uint256 newAmount) {
        require(amount > 0, 'no amount set');

        bool isSell = isPair(to);
        bool isBuy = isPair(from);

        if (
            isAllowed(from) ||
            isAllowed(to) ||
            (!isSell && !isBuy) ||
            !applyFee ||
            inFee
        ) return amount;

        address pair = isSell ? to : from;

        newAmount = amount;
        (
            ,
            uint256 _liquidityAmount,
            uint256 _backingAmount,
            uint256 _burnAmount,
            uint256 _marketingAmount,
            uint256 _platformAmount,
            uint256 _launchpadAmount
        ) = estimateTransferFees(from, to, amount);

        if (isSell) {
            backingAmount += _backingAmount;
            liquidityAmount += _liquidityAmount;
            burnAmount += _burnAmount;
            platformAmount += _platformAmount;
            launchpadAmount += _launchpadAmount;
            newAmount -= (_backingAmount +
                _liquidityAmount +
                _burnAmount +
                _platformAmount +
                _launchpadAmount);
        } else if (isBuy) {
            backingAmount += _backingAmount;
            liquidityAmount += _liquidityAmount;
            marketingAmount += _marketingAmount;
            platformAmount += _platformAmount;
            launchpadAmount += _launchpadAmount;
            newAmount -= (_backingAmount +
                _liquidityAmount +
                _marketingAmount +
                _platformAmount +
                _launchpadAmount);
        }

        // flag that you are in fee
        inFee = true;

        // turn fees off
        applyFee = false;

        if (burnAmount > 0) {
            uint256 _amount = burnAmount;
            burnAmount = 0;
            require(ERC20(dgnx).transfer(DEAD, _amount), 'tx failed');
        }

        if (marketingAmount > 0) {
            uint256 _amount = marketingAmount;
            marketingAmount = 0;
            require(ERC20(dgnx).transfer(MARKETING, _amount), 'tx failed');
        }

        if (platformAmount >= platformThreshold) {
            uint256 _amount = platformAmount;
            uint256 __devAmount = (_amount * 40) / 100; // 40%
            uint256 __platformAmount = _amount - __devAmount; // 60%
            platformAmount = 0;
            require(ERC20(dgnx).transfer(DEV, __devAmount), 'tx failed');
            require(
                ERC20(dgnx).transfer(PLATFORM, __platformAmount),
                'tx failed'
            );
        }

        if (launchpadAmount >= launchpadThreshold) {
            uint256 _amount = launchpadAmount;
            launchpadAmount = 0;
            require(ERC20(dgnx).transfer(LAUNCHPAD, _amount), 'tx failed');
        }

        // just when there is more than 1 pair
        if (allPairs.length > 1) {
            uint256 dgnxBefore;
            uint256 liquifyAmount;
            address swapPair;
            uint256 busdBefore;
            (liquifyAmount, swapPair) = bestBUSDValue(liquidityAmount, pair);
            if (liquifyAmount >= liquidityThreshold) {
                dgnxBefore = ERC20(dgnx).balanceOf(address(this));
                busdBefore = ERC20(busd).balanceOf(address(this));
                swapTokensToBUSD(
                    liquidityAmount,
                    IUniswapV2Pair(swapPair),
                    address(this)
                );
                liquidityBUSD +=
                    ERC20(busd).balanceOf(address(this)) -
                    busdBefore;
                liquidityAmount -=
                    dgnxBefore -
                    ERC20(dgnx).balanceOf(address(this));
                dgnxBefore = 0;
                busdBefore = 0;
            }

            // if main pair is not traded, lets kick some ballz here
            if (mainPair != pair) distributeLiquidityToMainPool();

            if (backingAmount > 0) {
                (liquifyAmount, swapPair) = bestBUSDValue(backingAmount, pair);
                if (liquifyAmount > backingThreshold) {
                    dgnxBefore = ERC20(dgnx).balanceOf(address(this));
                    swapTokensToBUSD(
                        backingAmount,
                        IUniswapV2Pair(swapPair),
                        BACKING // currently we are storing it on a wallet until we have a fancy contract for it to handle
                    );
                    backingAmount -=
                        dgnxBefore -
                        ERC20(dgnx).balanceOf(address(this));
                    dgnxBefore = 0;
                }
            }
        }

        // turn fees on again
        applyFee = true;
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
            uint256 _launchpadAmount
        )
    {
        require(amount > 0, 'no amount set');

        bool isSell = isPair(to);
        bool isBuy = isPair(from);

        if (
            isAllowed(from) ||
            isAllowed(to) ||
            (!isSell && !isBuy) ||
            !applyFee ||
            inFee
        ) return (amount, 0, 0, 0, 0, 0, 0);

        newAmount = amount;
        _liquidityAmount = (amount * liquidityTax) / 10000;
        _backingAmount = (amount * backingTax) / 10000;
        _burnAmount = (amount * burnTax) / 10000;
        _marketingAmount = (amount * marketingTax) / 10000;
        _platformAmount = (amount * platformTax) / 10000;
        _launchpadAmount = (amount * launchpadTax) / 10000;

        if (isSell)
            newAmount -= (_backingAmount +
                _liquidityAmount +
                _burnAmount +
                _platformAmount +
                _launchpadAmount);
        else if (isBuy)
            newAmount -= (_backingAmount +
                _liquidityAmount +
                _marketingAmount +
                _platformAmount +
                _launchpadAmount);
    }

    function distributeLiquidityToMainPool() public onlyAllowed nonReentrant {
        uint256 busdBefore = ERC20(busd).balanceOf(address(this));
        uint256 forSwap = liquidityBUSD / 2;
        uint256 forLiquidity = liquidityBUSD - forSwap;
        uint256[] memory amounts = swapBUSDToToken(
            forSwap,
            IUniswapV2Pair(mainPair),
            address(this)
        );
        addLiquidity(
            IUniswapV2Pair(mainPair).factory(),
            IUniswapV2Pair(mainPair).token0(),
            IUniswapV2Pair(mainPair).token1(),
            amounts[1],
            forLiquidity,
            address(this)
        );

        liquidityBUSD -= busdBefore - ERC20(busd).balanceOf(address(this));
        emit DistributeLiquidity(
            IUniswapV2Pair(mainPair).token0(),
            amounts[1],
            IUniswapV2Pair(mainPair).token1(),
            forLiquidity,
            msg.sender
        );
    }

    function swapTokensToBUSD(
        uint256 amountIn,
        IUniswapV2Pair pair,
        address to
    ) internal returns (uint256[] memory amounts) {
        address[] memory path = getPathForPair(address(pair), dgnx);
        amounts = getAmountsOut(pair.factory(), amountIn, path);
        TransferHelper.safeTransfer(path[0], address(pair), amounts[0]);
        _swap(pair.factory(), amounts, path, to);
    }

    function swapBUSDToToken(
        uint256 amountIn,
        IUniswapV2Pair pair,
        address to
    ) internal returns (uint256[] memory amounts) {
        address[] memory path = getPathForPair(address(pair), busd);
        amounts = getAmountsOut(pair.factory(), amountIn, path);
        TransferHelper.safeTransfer(path[0], address(pair), amounts[0]);
        _swap(pair.factory(), amounts, path, to);
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
                ? IUniswapV2Factory(factory).getPair(output, path[i + 2])
                : _to;
            IUniswapV2Pair(IUniswapV2Factory(factory).getPair(input, output))
                .swap(amount0Out, amount1Out, to, new bytes(0));
        }
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
        address pair = IUniswapV2Factory(factory).getPair(tokenA, tokenB);
        TransferHelper.safeTransfer(tokenA, pair, amountA);
        TransferHelper.safeTransfer(tokenB, pair, amountB);
        liquidity = IUniswapV2Pair(pair).mint(to);
    }

    function bestBUSDValue(uint256 tokenAmount, address ignorePair)
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
                        IUniswapV2Pair(pair).factory(),
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
     *   addr => TOKEN/WBTC
     *   pathToBUSD => WBTC => WBNB => busd
     */
    function addPair(address addr, address[] memory pathToBUSD)
        external
        onlyAllowed
    {
        require(addr != address(0), 'no pair');
        require(IUniswapV2Pair(addr).factory() != address(0), 'no factory');
        require(factories[IUniswapV2Pair(addr).factory()], 'wrong factory');
        require(!pairs[addr], 'pair already exists');
        address t0 = IUniswapV2Pair(addr).token0();
        address t1 = IUniswapV2Pair(addr).token1();
        require(t0 == dgnx || t1 == dgnx, 'no dgnx');
        (t0, t1) = t0 == dgnx ? (t0, t1) : (t1, t0);
        if (pathToBUSD.length == 1) revert('swap path needs 2 addresses');
        if (pathToBUSD.length > 1) {
            require(pathToBUSD[0] == t1, 'wrong paired token path');
            require(
                pathToBUSD[pathToBUSD.length - 1] == busd,
                'wrong busd path'
            );
            for (uint256 i; i < pathToBUSD.length - 1; i++) {
                require(
                    IUniswapV2Factory(IUniswapV2Pair(addr).factory()).getPair(
                        pathToBUSD[i],
                        pathToBUSD[i + 1]
                    ) != address(0),
                    'invalid pair'
                );
            }
            pairsPath[addr] = pathToBUSD;
        } else {
            require(t0 == busd || t1 == busd, 'no busd token');
        }

        pairs[addr] = true;
        allPairs.push(addr);

        emit PairAdded(addr, pathToBUSD, msg.sender);
    }

    function removePair(address addr) external onlyOwner {
        require(pairs[addr], 'no pair');
        pairs[addr] = false;
        emit PairRemoved(addr, msg.sender);
    }

    function isPair(address addr) private view returns (bool) {
        return pairs[addr];
    }

    function addFactory(address addr) external onlyOwner {
        require(addr != address(0), 'wrong address');
        require(!factories[addr], 'already existing');
        factories[addr] = true;
        emit FactoryAdded(addr, msg.sender);
    }

    function removeFactory(address addr) external onlyOwner {
        require(factories[addr], 'not existing');
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
        (address t0, address t1) = IUniswapV2Pair(addr).token0() == from
            ? (IUniswapV2Pair(addr).token0(), IUniswapV2Pair(addr).token1())
            : (IUniswapV2Pair(addr).token1(), IUniswapV2Pair(addr).token0());

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
    }

    function feeOn() external onlyAllowed {
        applyFee = true;
    }

    // if we update controller, we need to transfer funds to new controller. This will be called by new controller
    function migrate() external onlyAllowed nonReentrant {
        uint256 lpTokens;
        uint256 balanceDgnx = ERC20(dgnx).balanceOf(address(this));
        uint256 balanceBusd = ERC20(busd).balanceOf(address(this));
        if (balanceDgnx > 0) {
            require(ERC20(dgnx).transfer(msg.sender, balanceDgnx), 'tx failed');
        }
        if (balanceBusd > 0) {
            require(ERC20(busd).transfer(msg.sender, balanceBusd), 'tx failed');
        }
        for (uint256 i; i < allPairs.length; i++) {
            lpTokens = ERC20(allPairs[i]).balanceOf(address(this));
            if (lpTokens > 0) {
                require(
                    ERC20(allPairs[i]).transfer(msg.sender, lpTokens),
                    'tx failed'
                );
            }
            if (
                ERC20(IUniswapV2Pair(allPairs[i]).token0()).balanceOf(
                    address(this)
                ) > 0
            ) {
                require(
                    ERC20(IUniswapV2Pair(allPairs[i]).token0()).transfer(
                        msg.sender,
                        ERC20(IUniswapV2Pair(allPairs[i]).token0()).balanceOf(
                            address(this)
                        )
                    ),
                    'tx failed'
                );
            }
            if (
                ERC20(IUniswapV2Pair(allPairs[i]).token1()).balanceOf(
                    address(this)
                ) > 0
            ) {
                require(
                    ERC20(IUniswapV2Pair(allPairs[i]).token1()).transfer(
                        msg.sender,
                        ERC20(IUniswapV2Pair(allPairs[i]).token1()).balanceOf(
                            address(this)
                        )
                    ),
                    'tx failed'
                );
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
            '!migration'
        );
        previousController = _previousController;
        DGNXController(previousController).migrate();
    }

    // if there are any tokens send by accident, we can revover it
    function recoverToken(address token, address to)
        external
        onlyAllowed
        nonReentrant
    {
        require(dgnx != token, 'No drain allowed');
        require(busd != token, 'No drain allowed');
        for (uint256 i; i < allPairs.length; i++) {
            require(allPairs[i] != token, 'No drain allowed');
        }
        require(
            ERC20(token).transfer(to, ERC20(token).balanceOf(address(this))),
            'tx failed'
        );
    }

    function allowContract(address addr) external onlyAllowed nonReentrant {
        require(addr.isContract(), 'no contract');
        allowedContracts[addr] = true;
    }

    function removeContract(address addr) external onlyAllowed {
        require(allowedContracts[addr], 'no contract');
        delete allowedContracts[addr];
    }

    function isAllowed(address addr) public view returns (bool) {
        return allowedContracts[addr];
    }

    function setMainPair(address pair) external onlyOwner {
        require(pair != address(0), 'zero address');
        require(pair != mainPair, 'pair already set');
        mainPair = pair;
    }

    function getAllPairs() external view returns (address[] memory addr) {
        addr = allPairs;
    }

    function setBurnTax(uint256 _tax) external onlyOwner {
        burnTax = _tax;
    }

    function setBackingTax(uint256 _tax) external onlyOwner {
        backingTax = _tax;
    }

    function setLiquidityTax(uint256 _tax) external onlyOwner {
        liquidityTax = _tax;
    }

    function setMarketingTax(uint256 _tax) external onlyOwner {
        marketingTax = _tax;
    }

    function setPlatformTax(uint256 _tax) external onlyOwner {
        platformTax = _tax;
    }

    function setLaunchpadTax(uint256 _tax) external onlyOwner {
        launchpadTax = _tax;
    }

    function setLiquidityThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold >= 1000 * 10**18, 'bad threshold');
        liquidityThreshold = _threshold;
    }

    function setBackingThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold >= 10 * 10**18, 'bad threshold');
        backingThreshold = _threshold;
    }

    function setPlatformThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold >= 10 * 10**18, 'bad threshold');
        platformThreshold = _threshold;
    }

    function setLaunchpadThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold >= 10 * 10**18, 'bad threshold');
        launchpadThreshold = _threshold;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
pragma solidity ^0.8.13;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

// import 'hardhat/console.sol';

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
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(
            IUniswapV2Factory(factory).getPair(tokenA, tokenB)
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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