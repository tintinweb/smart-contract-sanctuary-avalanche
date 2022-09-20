/**
 *Submitted for verification at snowtrace.io on 2022-09-20
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address user) external view returns (uint256);
}

interface IPriceFeed {
    function latestPrice() external view returns (uint256);
    function latestMimPrice() external view returns (int256);
}

interface IXGrape is IERC20 {
    function calculatePrice() external view returns (uint256);
}

interface IMagicToken is IERC20 {
    function getPricePerFullShare() external view returns (uint256);
}

contract xGrapeOracle {

    IPriceFeed public constant priceFeed = IPriceFeed(0xae85861C0cb3E34AaCFabb0c2384A5dD939726b3);
    IXGrape public constant xGrape = IXGrape(0x95CED7c63eA990588F3fd01cdDe25247D04b8D98);
    IMagicToken public constant magicToken = IMagicToken(0x0dA1DC567D81925cFf22Df74C6b9e294E9E1c3A5);
    IERC20 public constant LP = IERC20(0x9076C15D7b2297723ecEAC17419D506AE320CbF1);
    IERC20 public constant MIM = IERC20(0x130966628846BFd36ff31a822705796e8cb8C18D);
    IERC20 public constant Grape = IERC20(0x5541D83EFaD1f281571B343977648B75d95cdAC2);

    function xGrapePrice() public view returns (uint256) {
        return valueOfXGrape(10**18);
    }

    function tvlInXGrape() public view returns (uint256) {
        return ( magicToken.balanceOf(address(xGrape)) * tvlInMagicToken() ) / magicToken.totalSupply();
    }

    function tvlInMagicToken() public view returns (uint256) {
        return valueOfLP(( magicToken.getPricePerFullShare() * magicToken.totalSupply() ) / 10**18);
    }

    function valueOfXGrape(uint nTokens) public view returns (uint256) {
        return ( valueOfMagicToken(nTokens) * calculatePrice() ) / 10**18;
    }

    function valueOfMagicToken(uint nTokens) public view returns (uint256) {
        return ( valueOfLP(nTokens) * getPricePerFullShare() ) / 10**18;
    }

    function valueOfLP(uint nTokens) public view returns (uint256) {

        // tvl in LP
        uint tvl = TVLInLP();

        // find out what the TVL is per token, multiply by `nTokens`
        return ( tvl * nTokens ) / LP.totalSupply();
    }

    function TVLInLP() public view returns (uint256) {
        return TVL(address(LP));
    }

    function TVL(address wallet) public view returns (uint256) {

        // balance in LPs
        uint256 balanceGrape = Grape.balanceOf(wallet);
        uint256 balanceMim = MIM.balanceOf(wallet);

        // tvl in LPs
        uint tvlGrape = ( balanceGrape * latestGrapePriceFormatted() ) / 10**18;
        uint tvlMim   = ( balanceMim   * latestMimPriceFormatted() )   / 10**18;
        return tvlGrape + tvlMim;

    }

    function calculatePrice() public view returns (uint256) {
        return xGrape.calculatePrice();
    }

    function getPricePerFullShare() public view returns (uint256) {
        return magicToken.getPricePerFullShare();
    }

    function latestGrapePriceFormatted() public view returns (uint256) {
        return latestPrice() / 10**8;
    }

    function latestMimPriceFormatted() public view returns (uint256) {
        return latestMimPrice() * 10**10;
    }

    function latestPrice() public view returns (uint256) {
        return priceFeed.latestPrice();
    }

    function latestMimPrice() public view returns (uint256) {
        int256 val = priceFeed.latestMimPrice();
        require(val > 0, 'MIM Price Error');
        return uint256(val);
    } 

    function balanceOf(address user) external view returns (uint256) {
        return ( xGrape.balanceOf(user) * xGrapePrice() ) / 10**18;
    }

    function totalSupply() public view returns (uint256) {
        return tvlInXGrape();
    }

    function name() external pure returns (string memory) {
        return 'XGrape Price';
    }

    function symbol() external pure returns (string memory) {
        return 'USD';
    }

    function decimals() external pure returns (uint8) {
        return 18;
    }
}