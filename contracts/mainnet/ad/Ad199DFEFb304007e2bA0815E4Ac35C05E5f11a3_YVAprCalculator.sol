/**
 *Submitted for verification at snowtrace.io on 2022-02-26
*/

// SPDX-License-Identifier: MIT
// Panicswap.com api
pragma solidity ^0.8.0;

interface YvVault{
    function token() external view returns(address);
    function totalAssets() external view returns(uint);
}

interface LpToken{
    function token0() external view returns(address);
    function token1() external view returns(address);
}

interface IMasterchef{
    function poolInfo(uint) external view returns(address lpt,uint alloc,uint,uint);
    function rewardsPerSecond() external view returns(uint);
    function totalAllocPoint() external view returns(uint);
}

interface IERC20{
    function balanceOf(address) external view returns(uint);
    function totalSupply() external view returns(uint);
}

library SafeToken {
    function balanceOf(address token, address user) internal view returns (uint) {
        return IERC20(token).balanceOf(user);
    }

    function totalSupply(address token) internal view returns(uint){
        return IERC20(token).totalSupply();
    }
}

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

contract YVAprCalculator{
    using SafeToken for address;

    address public masterchef = 0x4A2DFcaBaa8428167301d8BF48B585e983DF6adC;

    address spookyFactory = 0x9Ad6C38BE94206cA50bb0d90783181662f0Cfa10;

    address public panic = 0xA78BC50A084df9D5cc5db93D385263909E3795D8;

    address public wftm = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    function ftmPerToken(address _token) public view returns(uint){
        if(_token == wftm) return 1e18;
        address pair = IUniswapV2Factory(spookyFactory).getPair(_token, wftm);
        uint liqWftm = wftm.balanceOf(pair);
        uint liqTokens = _token.balanceOf(pair);
        return liqWftm*1e18/liqTokens;
    }

    function panicPrice() public view returns(uint){
        return ftmPerToken(panic);
    }

    function yvPpsStandarized(address _token) public view returns(uint){
        return 1e18;
    }

    function yvTokenPrice(address _token) public view returns(uint){
        return 1e18;
    }

    function lpValue(address _token) public view returns(uint){
        address token0 = LpToken(_token).token0();
        address token1 = LpToken(_token).token1();
        uint am0 = token0.balanceOf(_token);
        uint am1 = token1.balanceOf(_token);
        uint price0 = yvTokenPrice(token0);
        uint price1 = yvTokenPrice(token1);
        uint totalValue = (am0*price0+am1*price1)/1e18;
        return totalValue;
    }

    function lpValueDollar(address _token) public view returns(uint){
        address token0 = LpToken(_token).token0();
        address token1 = LpToken(_token).token1();
        uint am0 = token0.balanceOf(_token);
        uint am1 = token1.balanceOf(_token);
        uint price0 = yvTokenPrice(token0);
        uint price1 = yvTokenPrice(token1);
        uint totalValue = (am0*price0+am1*price1)/1e18;
        return totalValue/ftmPerToken(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E)*1e18;//usdc
    }

    function lpValueDollarChef(uint _pid) public view returns(uint){
        (address lpt,,,) = IMasterchef(masterchef).poolInfo(_pid);
        return lpValueDollar(lpt);
    }

    function panicPerYear() public view returns(uint){
        return IMasterchef(masterchef).rewardsPerSecond() * 365 * 24 * 3600;
    }

    function yearlyFantom() public view returns(uint){
        uint _panicPerYear = panicPerYear();
        uint pPrice = panicPrice();
        return _panicPerYear*pPrice/1e18;
    }

    function _yvApr(uint _pid) public view returns(uint){
        (address yvT, uint alloc, , ) = IMasterchef(masterchef).poolInfo(_pid);
        uint totalAlloc = IMasterchef(masterchef).totalAllocPoint();
        uint yieldFantom = yearlyFantom() * alloc / totalAlloc;
        uint ftmValue = lpValue(yvT);
        return yieldFantom*10000/ftmValue;
    }

    function _panicApr() public view returns(uint){
        (, uint alloc, , ) = IMasterchef(masterchef).poolInfo(1);
        uint totalAlloc = IMasterchef(masterchef).totalAllocPoint();
        uint _panicPerYear = panicPerYear() * alloc / totalAlloc;
        uint yvTBal = panic.balanceOf(masterchef);
        return _panicPerYear*10000/yvTBal;
    }

    function _panicLpApr() public view returns(uint){
        address pair = IUniswapV2Factory(spookyFactory).getPair(panic, wftm);
        (, uint alloc, , ) = IMasterchef(masterchef).poolInfo(1);
        uint totalAlloc = IMasterchef(masterchef).totalAllocPoint();
        uint _panicPerYear = panicPerYear() * alloc / totalAlloc;
        uint yvTVal = panic.balanceOf(pair) * 2;
        return _panicPerYear*10000/yvTVal;
    }

    function yvApr(uint _pid) public view returns(uint){
        if(_pid == 7) return _panicLpApr();
        return _yvApr(_pid);
    }
}