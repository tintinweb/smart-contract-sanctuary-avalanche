// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;
import "./interfaces.sol";
import "./helpers.sol";

contract Resolver is PangolinHelpers {
    function getBuyAmount(
        address buyAddr,
        address sellAddr,
        uint256 sellAmt,
        uint256 slippage
    ) public view returns (uint256 buyAmt, uint256 unitAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeAVAXAddress(buyAddr, sellAddr);
        buyAmt = getExpectedBuyAmt(address(_buyAddr), address(_sellAddr), sellAmt);
        unitAmt = getBuyUnitAmt(_buyAddr, buyAmt, _sellAddr, sellAmt, slippage);
    }

    function getSellAmount(
        address buyAddr,
        address sellAddr,
        uint256 buyAmt,
        uint256 slippage
    ) public view returns (uint256 sellAmt, uint256 unitAmt) {
        (TokenInterface _buyAddr, TokenInterface _sellAddr) = changeAVAXAddress(buyAddr, sellAddr);
        sellAmt = getExpectedSellAmt(address(_buyAddr), address(_sellAddr), buyAmt);
        unitAmt = getSellUnitAmt(_sellAddr, sellAmt, _buyAddr, buyAmt, slippage);
    }

    function getDepositAmount(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 slippageA,
        uint256 slippageB
    )
        public
        view
        returns (
            uint256 amountB,
            uint256 uniAmount,
            uint256 amountAMin,
            uint256 amountBMin
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeAVAXAddress(tokenA, tokenB);
        IPangolinRouter router = IPangolinRouter(getPangolinAddr());
        IPangolinFactory factory = IPangolinFactory(router.factory());
        IPangolinPair lpToken = IPangolinPair(factory.getPair(address(_tokenA), address(_tokenB)));
        require(address(lpToken) != address(0), "No-exchange-address");

        (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
        (reserveA, reserveB) = lpToken.token0() == address(_tokenA) ? (reserveA, reserveB) : (reserveB, reserveA);

        amountB = router.quote(amountA, reserveA, reserveB);

        uniAmount = mul(amountA, lpToken.totalSupply());
        uniAmount = uniAmount / reserveA;

        amountAMin = wmul(sub(WAD, slippageA), amountA);
        amountBMin = wmul(sub(WAD, slippageB), amountB);
    }

    function getSingleDepositAmount(
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 slippage
    )
        public
        view
        returns (
            uint256 amtA,
            uint256 amtB,
            uint256 uniAmt,
            uint256 minUniAmt
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeAVAXAddress(tokenA, tokenB);
        IPangolinRouter router = IPangolinRouter(getPangolinAddr());
        IPangolinFactory factory = IPangolinFactory(router.factory());
        IPangolinPair lpToken = IPangolinPair(factory.getPair(address(_tokenA), address(_tokenB)));
        require(address(lpToken) != address(0), "No-exchange-address");

        (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
        (reserveA, reserveB) = lpToken.token0() == address(_tokenA) ? (reserveA, reserveB) : (reserveB, reserveA);

        uint256 swapAmtA = calculateSwapInAmount(reserveA, amountA);

        amtB = getExpectedBuyAmt(address(_tokenB), address(_tokenA), swapAmtA);
        amtA = sub(amountA, swapAmtA);

        uniAmt = mul(amtA, lpToken.totalSupply());
        uniAmt = uniAmt / add(reserveA, swapAmtA);

        minUniAmt = wmul(sub(WAD, slippage), uniAmt);
    }

    function getDepositAmountNewPool(
        address tokenA,
        address tokenB,
        uint256 amtA,
        uint256 amtB
    ) public view returns (uint256 unitAmt) {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeAVAXAddress(tokenA, tokenB);
        IPangolinRouter router = IPangolinRouter(getPangolinAddr());
        address exchangeAddr = IPangolinFactory(router.factory()).getPair(address(_tokenA), address(_tokenB));
        require(exchangeAddr == address(0), "pair-found.");
        uint256 _amtA18 = convertTo18(_tokenA.decimals(), amtA);
        uint256 _amtB18 = convertTo18(_tokenB.decimals(), amtB);
        unitAmt = wdiv(_amtB18, _amtA18);
    }

    function getWithdrawAmounts(
        address tokenA,
        address tokenB,
        uint256 uniAmt,
        uint256 slippage
    )
        public
        view
        returns (
            uint256 amtA,
            uint256 amtB,
            uint256 unitAmtA,
            uint256 unitAmtB
        )
    {
        (TokenInterface _tokenA, TokenInterface _tokenB) = changeAVAXAddress(tokenA, tokenB);
        (amtA, amtB) = _getWithdrawAmts(_tokenA, _tokenB, uniAmt);
        (unitAmtA, unitAmtB) = _getWithdrawUnitAmts(_tokenA, _tokenB, amtA, amtB, uniAmt, slippage);
    }

    struct TokenPair {
        address tokenA;
        address tokenB;
    }

    struct PoolData {
        address tokenA;
        address tokenB;
        address lpAddress;
        uint256 reserveA;
        uint256 reserveB;
        uint256 tokenAShareAmt;
        uint256 tokenBShareAmt;
        uint256 tokenABalance;
        uint256 tokenBBalance;
        uint256 lpAmount;
        uint256 totalSupply;
    }

    function getPositionByPair(address owner, TokenPair[] memory tokenPairs) public view returns (PoolData[] memory) {
        IPangolinRouter router = IPangolinRouter(getPangolinAddr());
        uint256 _len = tokenPairs.length;
        PoolData[] memory poolData = new PoolData[](_len);
        for (uint256 i = 0; i < _len; i++) {
            (TokenInterface tokenA, TokenInterface tokenB) = changeAVAXAddress(
                tokenPairs[i].tokenA,
                tokenPairs[i].tokenB
            );
            address exchangeAddr = IPangolinFactory(router.factory()).getPair(address(tokenA), address(tokenB));
            if (exchangeAddr != address(0)) {
                IPangolinPair lpToken = IPangolinPair(exchangeAddr);
                (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
                (reserveA, reserveB) = lpToken.token0() == address(tokenA)
                    ? (reserveA, reserveB)
                    : (reserveB, reserveA);

                uint256 lpAmount = lpToken.balanceOf(owner);
                uint256 totalSupply = lpToken.totalSupply();
                uint256 share = wdiv(lpAmount, totalSupply);
                uint256 amtA = wmul(reserveA, share);
                uint256 amtB = wmul(reserveB, share);
                poolData[i] = PoolData(
                    address(0),
                    address(0),
                    address(lpToken),
                    reserveA,
                    reserveB,
                    amtA,
                    amtB,
                    0,
                    0,
                    lpAmount,
                    totalSupply
                );
            }
            poolData[i].tokenA = tokenPairs[i].tokenA;
            poolData[i].tokenB = tokenPairs[i].tokenB;
            poolData[i].tokenABalance = tokenPairs[i].tokenA == getAVAXAddr() ? owner.balance : tokenA.balanceOf(owner);
            poolData[i].tokenBBalance = tokenPairs[i].tokenB == getAVAXAddr() ? owner.balance : tokenB.balanceOf(owner);
        }
        return poolData;
    }

    function getpooldata(address lpToken_address, address owner) public view returns (PoolData memory) {
        address wavaxAddr = getAddressWAVAX();
        address avaxAddr = getAVAXAddr();
        IPangolinPair lpToken = IPangolinPair(lpToken_address);
        (uint256 reserveA, uint256 reserveB, ) = lpToken.getReserves();
        (address tokenA, address tokenB) = (lpToken.token0(), lpToken.token1());

        uint256 lpAmount = lpToken.balanceOf(owner);
        uint256 totalSupply = lpToken.totalSupply();
        uint256 share = wdiv(lpAmount, totalSupply);
        return
            PoolData(
                tokenA == wavaxAddr ? avaxAddr : tokenA,
                tokenB == wavaxAddr ? avaxAddr : tokenB,
                address(lpToken),
                reserveA,
                reserveB,
                wmul(reserveA, share), // amtA
                wmul(reserveB, share), // amtB
                tokenA == wavaxAddr ? owner.balance : TokenInterface(tokenA).balanceOf(owner),
                tokenB == wavaxAddr ? owner.balance : TokenInterface(tokenB).balanceOf(owner),
                lpAmount,
                totalSupply
            );
    }

    function getPosition(address owner, address[] memory lpTokens) public view returns (PoolData[] memory) {
        uint256 _len = lpTokens.length;
        PoolData[] memory poolData = new PoolData[](_len);
        for (uint256 i = 0; i < _len; i++) {
            poolData[i] = getpooldata(lpTokens[i], owner);
        }
        return poolData;
    }
}

contract InstaPangolinResolver is Resolver {
    string public constant name = "Pangolin-Resolver-v1";
}