// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import './UniswapV2ERC20.sol';
import './libraries/Math.sol';
import './libraries/UQ112x112.sol';
import './interfaces/IERC20Reward.sol';
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Router02.sol';
import './interfaces/IUniswapV2Callee.sol';

interface IMigrator {
    // Return the desired amount of liquidity token that the migrator wants.
    function desiredLiquidity() external view returns (uint256);
}

contract UniswapV2Pair is UniswapV2ERC20 {
    using SafeMathUniswap  for uint;
    using UQ112x112 for uint224;

    uint public constant MINIMUM_LIQUIDITY = 10**3;
    uint public constant A_PRECISION = 100;
    bytes4 private constant SELECTOR = bytes4(keccak256(bytes('transfer(address,uint256)')));
    bytes4 private constant BURN_SELECTOR = bytes4(keccak256(bytes('burn(uint256)')));

    address public factory;
    address public token0;
    address public token1;
    //GAME never changes address.
    bool public isGameLp;
    IERC20UniswapReward GAME;
    bool public burnBuybackToken;
    address[] public buybackRoute0;
    uint256 public buybackTokenIndex;
    address[] public buybackRoute1;

    uint112 private reserve0;           // uses single storage slot, accessible via getReserves
    uint112 private reserve1;           // uses single storage slot, accessible via getReserves
    uint32  private blockTimestampLast; // uses single storage slot, accessible via getReserves

    uint public price0CumulativeLast;
    uint public price1CumulativeLast;
    uint public kLast; // reserve0 * reserve1, as of immediately after the most recent liquidity event

    struct Amounts {
        uint256 reserve0;
        uint256 reserve1;
        uint256 In0;
        uint256 In1;
        uint256 OutTax0;
        uint256 OutTax1;
        address token0;
        address token1;
        bool hookedToken0;
        bool hookedToken1;
    }

    uint private unlocked = 1;
    modifier lock() {
        require(unlocked == 1, 'UniswapV2: LOCKED');
        unlocked = 0;
        _;
        unlocked = 1;
    }

    uint private tempLockCheck = 1;

    function getReserves() public view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast) {
        _reserve0 = reserve0;
        _reserve1 = reserve1;
        _blockTimestampLast = blockTimestampLast;
    }

    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(SELECTOR, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: TRANSFER_FAILED');
    }

    //    function _burnToken(address token, uint value) private {
    //        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(BURN_SELECTOR, value));
    //        require(success && (data.length == 0 || abi.decode(data, (bool))), 'UniswapV2: BURN_FAILED');
    //    }

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

    constructor() public {
        factory = msg.sender;
    }

    // called once by the factory at time of deployment
    function initialize(address _token0, address _token1, bool _burnBuybackToken, address[] memory _buybackRoute0, address[] memory _buybackRoute1) external {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        token0 = _token0;
        token1 = _token1;
        address _GAME = IUniswapV2Factory(factory).GAME();
        GAME = IERC20UniswapReward(_GAME);
        isGameLp = (_token0 == _GAME || _token1 == _GAME);
        //There will always be a buyback route. It defaults to GAME's.
        burnBuybackToken = _burnBuybackToken;
        buybackRoute0 = _buybackRoute0;
        buybackTokenIndex = _buybackRoute0.length-1;
        buybackRoute1 = _buybackRoute1;
    }

    function setBuybackRoute(bool _burnBuybackToken, address[] memory _buybackRoute0, address[] memory _buybackRoute1) external
    {
        require(msg.sender == factory, 'UniswapV2: FORBIDDEN'); // sufficient check
        //There will always be a buyback route. It defaults to GAME's.
        burnBuybackToken = _burnBuybackToken;
        buybackRoute0 = _buybackRoute0;
        buybackTokenIndex = _buybackRoute0.length-1;
        buybackRoute1 = _buybackRoute1;

    }

    // update reserves and, on the first call per block, price accumulators
    function _update(uint balance0, uint balance1, uint112 _reserve0, uint112 _reserve1) private {
        require(balance0 <= uint112(-1) && balance1 <= uint112(-1), 'UniswapV2: OVERFLOW');
        uint32 blockTimestamp = uint32(block.timestamp % 2**32);
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        if (timeElapsed > 0 && _reserve0 != 0 && _reserve1 != 0) {
            // * never overflows, and + overflow is desired
            price0CumulativeLast += uint(UQ112x112.encode(_reserve1).uqdiv(_reserve0)) * timeElapsed;
            price1CumulativeLast += uint(UQ112x112.encode(_reserve0).uqdiv(_reserve1)) * timeElapsed;
        }
        reserve0 = uint112(balance0);
        reserve1 = uint112(balance1);
        blockTimestampLast = blockTimestamp;
        emit Sync(reserve0, reserve1);
    }

    // if fee is on, mint liquidity equivalent to 1/5th of the growth in sqrt(k)
    // Since our fees are 0.25%, this is means LP gets 0.20%, and feeTo gets 0.05%.
    function _mintFee(uint112 _reserve0, uint112 _reserve1) private returns (bool feeOn) {
        address feeTo = IUniswapV2Factory(factory).feeTo();
        address dev = IUniswapV2Factory(factory).devFund();
        feeOn = feeTo != address(0);
        uint _kLast = kLast; // gas savings
        if (feeOn) {
            if (_kLast != 0) {
                uint rootK = Math.sqrt(uint(_reserve0).mul(_reserve1));
                uint rootKLast = Math.sqrt(_kLast);
                if (rootK > rootKLast) {
                    uint numerator = totalSupply.mul(rootK.sub(rootKLast));
                    uint denominator = rootK.mul(4).add(rootKLast);
                    uint liquidity = numerator / denominator;
                    uint buyback = liquidity / 3; // 1/3 goes to buyback
                    uint team = liquidity / 4; // 1/4 goes to dev
                    uint revenue = liquidity.sub(buyback).sub(team); //5/12 goes to revenue
                    //Revenue (Dev)
                    if (team > 0) _mint(dev != address(0) ? dev : feeTo, team);
                    //Revenue (Treasury/Backup)
                    if (revenue > 0) _mint(feeTo, revenue);
                    //Buyback
                    address buybackContract = IUniswapV2Factory(factory).buybackContract();
                    if (buyback > 0) _mint(buybackContract != address(0) ? buybackContract : feeTo, buyback);
                }
            }
        } else if (_kLast != 0) {
            kLast = 0;
        }
    }

    function getBuybackRoute0() external view returns (address[] memory)
    {
        return buybackRoute0;
    }

    function getBuybackRoute1() external view returns (address[] memory)
    {
        return buybackRoute1;
    }

    // this low-level function should be called from a contract which performs important safety checks
    function mint(address to) external lock returns (uint liquidity) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        uint balance0 = IERC20Uniswap(token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(token1).balanceOf(address(this));
        uint amount0 = balance0.sub(_reserve0);
        uint amount1 = balance1.sub(_reserve1);

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        if (_totalSupply == 0) {
            address migrator = IUniswapV2Factory(factory).migrator();
            if (msg.sender == migrator) {
                liquidity = IMigrator(migrator).desiredLiquidity();
                require(liquidity > 0 && liquidity != uint256(-1), "Bad desired liquidity");
            } else {
                require(migrator == address(0), "Must not have migrator");
                require(!IUniswapV2Factory(factory).createPairAdminOnly() || msg.sender == IUniswapV2Factory(factory).createPairAdmin(), 'UniswapV2: FORBIDDEN');
                liquidity = Math.sqrt(amount0.mul(amount1)).sub(MINIMUM_LIQUIDITY);
                _mint(address(0), MINIMUM_LIQUIDITY); // permanently lock the first MINIMUM_LIQUIDITY tokens
            }
        } else {
            liquidity = Math.min(amount0.mul(_totalSupply) / _reserve0, amount1.mul(_totalSupply) / _reserve1);
        }
        require(liquidity > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_MINTED');
        _mint(to, liquidity);

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Mint(msg.sender, amount0, amount1);
        unlocked = 1;
        IUniswapV2Factory(factory).buyback();
    }

    // this low-level function should be called from a contract which performs important safety checks
    function burn(address to) external lock returns (uint amount0, uint amount1) {
        (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
        address _token0 = token0;                                // gas savings
        address _token1 = token1;                                // gas savings
        uint balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        uint balance1 = IERC20Uniswap(_token1).balanceOf(address(this));
        uint liquidity = balanceOf[address(this)];

        bool feeOn = _mintFee(_reserve0, _reserve1);
        uint _totalSupply = totalSupply; // gas savings, must be defined here since totalSupply can update in _mintFee
        amount0 = liquidity.mul(balance0) / _totalSupply; // using balances ensures pro-rata distribution
        amount1 = liquidity.mul(balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(amount0 > 0 && amount1 > 0, 'UniswapV2: INSUFFICIENT_LIQUIDITY_BURNED');
        _burn(address(this), liquidity);
        _safeTransfer(_token0, to, amount0);
        _safeTransfer(_token1, to, amount1);
        balance0 = IERC20Uniswap(_token0).balanceOf(address(this));
        balance1 = IERC20Uniswap(_token1).balanceOf(address(this));

        _update(balance0, balance1, _reserve0, _reserve1);
        if (feeOn) kLast = uint(reserve0).mul(reserve1); // reserve0 and reserve1 are up-to-date
        emit Burn(msg.sender, amount0, amount1, to);
        unlocked = 1;
        IUniswapV2Factory(factory).buyback();
    }

    //NOTE: I don't have time to finish this, and it wasn't in the initial roadmap, but it would be pretty epic to have. I think removing the constant product formula could either aid or completely remove the need for a sell tax.
    //Perhaps a V2 of our swap/V3 of our token using these mechanics is in order if we get big enough. It might also be a better idea to just have it be its own project.
//    function getD(uint256[2] memory xp, uint256 amp) pure internal returns (uint256)
//    {
//        //D invariant calculation in non-overflowing integer operations
//            //iteratively
//        //A * sum(x_i) * n**n + D = A * D * n**n + D**(n+1) / (n**n * prod(x_i))
//        //Converging solution:
//        //D[j+1] = (A * n**n * sum(x_i) - D[j]**(n+1) / (n**n prod(x_i))) / (A * n**n - 1)
//        uint256 S = xp[0] + xp[1];
//
//        if (S == 0) return 0;
//
//        uint256 Dprev = 0;
//        uint256 D = S;
//        uint256 Ann = amp * 2;
//        for(uint _i = 0; i < 255; i += 1)
//        {
//            uint256 D_P = D;
//            D_P = D_P * D / (xp[0] * 2 + 1);  // +1 is to prevent /0
//            D_P = D_P * D / (xp[1] * 2 + 1);  // +1 is to prevent /0
//            Dprev = D;
//            D = (Ann * S / A_PRECISION + D_P * 2) * D / ((Ann - A_PRECISION) * D / A_PRECISION + (2 + 1) * D_P);
//            // Equality with the precision of 1
//            if (D > Dprev)
//            {
//                if (D - Dprev <= 1) return D;
//            }
//            else if (Dprev - D <= 1) return D;
//        }
//        // convergence typically occurs in 4 rounds or less, this should be unreachable!
//        // if it does happen the pool is borked and LPs can withdraw via `remove_liquidity`
//        revert("Pool is borked, please withdraw your liquidity.");
//    }

    // this low-level function should be called from a contract which performs important safety checks
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external lock {
        //This could be gas-optimized a bit, though stack too deep and ordering makes it annoying to.
        require(tempLockCheck == 0 || !IUniswapV2Factory(factory).tempLock(), 'UniswapV2: FORBIDDEN');
        tempLockCheck = 0;
        require(amount0Out > 0 || amount1Out > 0, 'UniswapV2: INSUFFICIENT_OUTPUT_AMOUNT');
        //stack too deep even with these
        Amounts memory amount;
        {
            (uint112 _reserve0, uint112 _reserve1,) = getReserves(); // gas savings
            amount.reserve0 = _reserve0;
            amount.reserve1 = _reserve1;
            amount.token0 = token0;
            amount.token1 = token1;
            amount.hookedToken0 = IUniswapV2Factory(factory).hookedTokens(amount.token0);
            amount.hookedToken1 = IUniswapV2Factory(factory).hookedTokens(amount.token1);
        }
        require(amount0Out < amount.reserve0 && amount1Out < amount.reserve1, 'UniswapV2: INSUFFICIENT_LIQUIDITY');
        //amountOut is always how much is going out, INCLUDING output taxes which take from address to and redirect it to somewhere else.
        //It is the callee's job to calculate output taxes' effects (except in the case of flash swaps, see below).
        //It is the callee's job to send the input and output taxes.
        //It is the caller's job to calculate input taxes' effect on amountOut.
        {
            // scope for _token{0,1}, avoids stack too deep errors
            //_token{0,1} removed, stack too deep now even with changes
            require(to != amount.token0 && to != amount.token1, 'UniswapV2: INVALID_TO');


            //Flash swap is not supported for hooked tokens due to circular dependencies (we might need amountIn to calculate tax, but we also need the tax to calculate amountIn because we need to calculate the tax on amountOut to find amountIn).
            //You should flash swap a different token and swap it for the hooked one.
            if(!amount.hookedToken0 && !amount.hookedToken1)
            {
                if (amount0Out > 0) _safeTransfer(amount.token0, to, amount0Out); // optimistically transfer tokens
                if (amount1Out > 0) _safeTransfer(amount.token1, to, amount1Out); // optimistically transfer tokens
                if (data.length > 0) IUniswapV2Callee(to).uniswapV2Call(msg.sender, amount0Out, amount1Out, data);
            }
            else
            {
                //Needed for stack too deep

                {
                    //We have not yet sent the balance, so no need to subtract amountOut.
                    uint balance0 = IERC20Uniswap(amount.token0).balanceOf(address(this));
                    uint balance1 = IERC20Uniswap(amount.token1).balanceOf(address(this));
                    amount.In0 = balance0 > amount.reserve0  ? balance0 - amount.reserve0 : 0;
                    amount.In1 = balance1 > amount.reserve1  ? balance1 - amount.reserve1 : 0;
                }
                require(amount.In0 > 0 || amount.In1 > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');
                if(amount.In0 > 0)
                {
                    if(amount.hookedToken0)
                    {
                        //NOTE: If needed, one can calculate the expected final amountIn/amountOut by checking if is a hooked token and calling expectedSellTax and/or expectedBuyTax as the router does if so.
                        //Because we have no control due to interactions like transfer being called between this and the router's call, there's no reason to complicate things with a beforeSell and/or forcing a view function.
                        //We recommend developers just use expectedSellTax in their onSell and don't rely on balances or change anything the sell tax is dependent on in the transfer function(s) to avoid errors.
                        (uint256[] memory taxIn, uint256[] memory taxOut, address[] memory taxTo) = IERC20UniswapHooked(amount.token0).onSell(amount.reserve0, amount.In0, to, amount.token1, amount.reserve1, amount1Out);
                        for(uint i; i < taxTo.length; i += 1) //Have to use .length each time due to stack too deep errors.
                        {
                            if(taxIn[i] > 0) _safeTransfer(amount.token0, taxTo[i], taxIn[i]); // optimistically transfer tokens
                            if(taxOut[i] > 0)
                            {
                                _safeTransfer(amount.token1, taxTo[i], taxOut[i]); // optimistically transfer tokens
                                amount.OutTax1 = amount.OutTax1.add(taxOut[i]);
                            }
                        }
                        IERC20UniswapHooked(amount.token0).afterSellTax(amount.reserve0, amount.In0, to, amount.token1, amount.reserve1, amount1Out);
                    }
                }
                if(amount.In1 > 0)
                {
                    if(amount.hookedToken1)
                    {
                        (uint256[] memory taxIn, uint256[] memory taxOut, address[] memory taxTo) = IERC20UniswapHooked(amount.token1).onSell(amount.reserve1, amount.In1, to, amount.token0, amount.reserve0, amount0Out);
                        for(uint i; i < taxTo.length; i += 1) //Have to use .length each time due to stack too deep errors.
                        {
                            if(taxIn[i] > 0) _safeTransfer(amount.token1, taxTo[i], taxIn[i]); // optimistically transfer tokens
                            if(taxOut[i] > 0)
                            {
                                _safeTransfer(amount.token0, taxTo[i], taxOut[i]); // optimistically transfer tokens
                                amount.OutTax0 = amount.OutTax0.add(taxOut[i]);
                            }
                        }
                        IERC20UniswapHooked(amount.token1).afterSellTax(amount.reserve1, amount.In1, to, amount.token0, amount.reserve0, amount0Out);
                    }
                }

                if (amount0Out > 0)
                {
                    if(amount.hookedToken0)
                    {
                        (uint256[] memory taxOut, uint256[] memory taxIn, address[] memory taxTo) = IERC20UniswapHooked(amount.token0).onBuy(amount.reserve0, amount0Out, to, amount.token1, amount.reserve1, amount.In1);
                        for(uint i; i < taxTo.length; i += 1) //Have to use .length each time due to stack too deep errors.
                        {
                            if(taxOut[i] > 0)
                            {
                                _safeTransfer(amount.token0, taxTo[i], taxOut[i]); // optimistically transfer tokens
                                amount.OutTax0 = amount.OutTax0.add(taxOut[i]); //Only need to keep track of taxOut.
                            }

                            if(taxIn[i] > 0) _safeTransfer(amount.token1, taxTo[i], taxIn[i]); // optimistically transfer tokens
                        }

                        IERC20UniswapHooked(amount.token0).afterBuyTax(amount.reserve0, amount0Out, to, amount.token1, amount.reserve1, amount.In1);
                    }
                }
                if (amount1Out > 0)
                {
                    if(amount.hookedToken1)
                    {
                        (uint256[] memory taxOut, uint256[] memory taxIn, address[] memory taxTo) = IERC20UniswapHooked(amount.token1).onBuy(amount.reserve1, amount1Out, to, amount.token0, amount.reserve0, amount.In0);
                        for(uint i; i < taxTo.length; i += 1) //Have to use .length each time due to stack too deep errors.
                        {
                            if(taxOut[i] > 0)
                            {
                                _safeTransfer(amount.token1, taxTo[i], taxOut[i]); // optimistically transfer tokens
                                amount.OutTax1 = amount.OutTax1.add(taxOut[i]); //Only need to keep track of taxOut.
                            }
                            if(taxIn[i] > 0) _safeTransfer(amount.token0, taxTo[i], taxIn[i]); // optimistically transfer tokens
                        }

                        IERC20UniswapHooked(amount.token1).afterBuyTax(amount.reserve1, amount1Out, to, amount.token0, amount.reserve0, amount.In0);
                    }
                }
//
                //Automatically calculate the rest to send to the to address.
                if (amount0Out.sub(amount.OutTax0) > 0) _safeTransfer(amount.token0, to, amount0Out.sub(amount.OutTax0)); // optimistically transfer tokens
                if (amount1Out.sub(amount.OutTax1) > 0) _safeTransfer(amount.token1, to, amount1Out.sub(amount.OutTax1)); // optimistically transfer tokens
            }
        }
        uint256 balance0 = IERC20Uniswap(amount.token0).balanceOf(address(this));
        uint256 balance1 = IERC20Uniswap(amount.token1).balanceOf(address(this));

        //All tax should still add up to amountOut, so no need to subtract from amountOut.
        uint256 amount0In = balance0 > amount.reserve0 - amount0Out ? balance0 - (amount.reserve0 - amount0Out) : 0;
        uint256 amount1In = balance1 > amount.reserve1 - amount1Out ? balance1 - (amount.reserve1 - amount1Out) : 0;
        require(amount0In > 0 || amount1In > 0, 'UniswapV2: INSUFFICIENT_INPUT_AMOUNT');

        { // scope for reserve{0,1}Adjusted, avoids stack too deep errors
            uint balance0Adjusted = balance0.mul(10000).sub(amount0In.mul(25));
            uint balance1Adjusted = balance1.mul(10000).sub(amount1In.mul(25));
            //NOTE: I don't have time to finish this, and it wasn't in the initial roadmap, but it would be pretty epic to have. I think removing the constant product formula could either aid or completely remove the need for a sell tax.
            //Perhaps a V2 of our swap/V3 of our token using these mechanics is in order if we get big enough. It might also be a better idea to just have it be its own project.
            //            D = getD();
            //            A = 400000; //Adjustable
            //            g = 0.000145; //Adjustable
            //            t = (balance0Adjusted*balance1Adjusted*(2**2))/D;
            //            K = A*t*((g**2)/(g+1-t)**2);
            require(
            //NOTE: See above
            //K*D*(balance0Adjusted+balance1Adjusted)+balance0Adjusted*balance1Adjusted >= K*(D**2)+((D/2)**2),
                balance0Adjusted.mul(balance1Adjusted) >= uint(amount.reserve0).mul(amount.reserve1).mul(10000**2),
                'UniswapV2: K');
        }

        _update(balance0, balance1, uint112(amount.reserve0), uint112(amount.reserve1));
        emit Swap(msg.sender, amount0In, amount1In, amount0Out, amount1Out, to);
    }

    // force balances to match reserves
    function skim(address to) external lock {
        require(!IUniswapV2Factory(factory).createPairAdminOnly() || msg.sender == IUniswapV2Factory(factory).createPairAdmin(), 'UniswapV2: FORBIDDEN');
        address _token0 = token0; // gas savings
        address _token1 = token1; // gas savings
        _safeTransfer(_token0, to, IERC20Uniswap(_token0).balanceOf(address(this)).sub(reserve0));
        _safeTransfer(_token1, to, IERC20Uniswap(_token1).balanceOf(address(this)).sub(reserve1));
    }

    // force reserves to match balances
    function sync() external lock {
        require(!IUniswapV2Factory(factory).createPairAdminOnly() || msg.sender == IUniswapV2Factory(factory).createPairAdmin(), 'UniswapV2: FORBIDDEN');
        _update(IERC20Uniswap(token0).balanceOf(address(this)), IERC20Uniswap(token1).balanceOf(address(this)), reserve0, reserve1);
    }

    function _beforeTokenTransfer(address sender, address recipient, uint256 amount) internal override {
        if(isGameLp)
        {
            //Note that even though we update the rewards regardless of whitelist, we have to whitelist the LP token for eligibility.
            //This is to prevent people from making new LP to hog rewards.
            GAME.updateReward(sender);
            GAME.updateReward(recipient);
        }
        super._beforeTokenTransfer(sender, recipient, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import './libraries/SafeMath.sol';

contract UniswapV2ERC20 {
    using SafeMathUniswap for uint;

    string public constant name = 'Theory LP Token';
    string public constant symbol = 'TLP';
    uint8 public constant decimals = 18;
    uint  public totalSupply;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    constructor() public {
        uint chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }

    function _mint(address to, uint value) internal {
        _beforeTokenTransfer(address(0), to, value);
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        _beforeTokenTransfer(from, address(0), value);
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        _beforeTokenTransfer(from, to, value);
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'UniswapV2: EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'UniswapV2: INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

// a library for performing various math operations

library Math {
    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))

// range: [0, 2**112 - 1]
// resolution: 1 / 2**112

library UQ112x112 {
    uint224 constant Q112 = 2**112;

    // encode a uint112 as a UQ112x112
    function encode(uint112 y) internal pure returns (uint224 z) {
        z = uint224(y) * Q112; // never overflows
    }

    // divide a UQ112x112 by a uint112, returning a UQ112x112
    function uqdiv(uint224 x, uint112 y) internal pure returns (uint224 z) {
        z = x / uint224(y);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "./IERC20Hooked.sol";

interface IERC20UniswapReward is IERC20UniswapHooked {
    function updateReward(address user) external;
    function treasury() external view returns (address);
    function mint(address recipient_, uint256 amount_) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function devFund() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);
    function router() external view returns (address);
    function createPairAdmin() external view returns (address);
    function createPairAdminOnly() external view returns (bool);
    function tempLock() external view returns (bool);
    function GAME() external view returns (address);
    function useFee() external view returns (bool);
    function buybackContract() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function hookedTokens(address) external view returns (bool);

    function createPair(address tokenA, address tokenB, bool burnBuybackToken, address[] memory buybackRouteA, address[] memory buybackRouteB) external returns (address pair);

    function setFeeTo(address) external;
    function setDevFund(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
    function setRouter(address) external;
    function setCreatePairAdmin(address) external;
    function setCreatePairAdminOnly(bool) external;
    function changeHookedToken(address,bool) external;
    function setBuybackContract(address) external;
    function buyback() external;
    function setBuybackRoute(address pair, bool _burnBuybackToken, address[] memory _buybackRoute0, address[] memory _buybackRoute1) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Callee {
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

// a library for performing overflow-safe math, courtesy of DappHub (https://github.com/dapphub/ds-math)

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "./IERC20.sol";

interface IERC20UniswapHooked is IERC20Uniswap {
    //To other developers: BE CAREFUL! If you transfer tax on another token, make sure that token cannot do anything malicious, or whitelist specific tokens.
    //IMPORTANT! It is not recommended to add taxes on the other token if you plan on interacting with other tokens that can hook, as their hooks can mess with your calculations.
    function onBuy(uint256 liquidity, uint256 amount, address to, address soldToken, uint256 soldLiquidity, uint256 soldAmount) external returns (uint256[] memory taxOut, uint256[] memory taxIn, address[] memory taxTo);
    function onSell(uint256 liquidity, uint256 amount, address to, address boughtToken, uint256 boughtLiquidity, uint256 boughtAmount) external returns (uint256[] memory taxIn, uint256[] memory taxOut, address[] memory taxTo);
    function afterBuyTax(uint256 liquidity, uint256 amount, address to, address soldToken, uint256 soldLiquidity, uint256 soldAmount) external;
    function afterSellTax(uint256 liquidity, uint256 amount, address to, address boughtToken, uint256 boughtLiquidity, uint256 boughtAmount) external;
    function expectedBuyTax(uint256 liquidity, uint256 amount, address to, address soldToken, uint256 soldLiquidity, uint256 soldAmount) view external returns (uint256 taxOut, uint256 taxIn);
    function expectedSellTax(uint256 liquidity, uint256 amount, address to, address boughtToken, uint256 boughtLiquidity, uint256 boughtAmount) view external returns (uint256 taxIn, uint256 taxOut);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IERC20Uniswap {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;
pragma experimental ABIEncoderV2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline, address[][] memory buybackRoutes
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline, address[][] memory buybackRoutes
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut, bool fee) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path, bool fee) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}