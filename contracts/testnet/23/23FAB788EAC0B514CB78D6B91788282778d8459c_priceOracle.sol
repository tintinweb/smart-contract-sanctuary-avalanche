/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-16
*/

/**
 *Submitted for verification at snowtrace.io on 2022-10-15
*/

/**
 *Submitted for verification at snowtrace.io on 2022-10-08
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

interface IsVintage is IERC20{
    function vintageWineBalance() external view returns (uint256);
}

interface IXGrape is IERC20 {
    function calculatePrice() external view returns (uint256);
}

interface IMagicToken is IERC20 {
    function getPricePerFullShare() external view returns (uint256);
}

contract priceOracle {

    IPriceFeed public constant priceFeed = IPriceFeed(0xae85861C0cb3E34AaCFabb0c2384A5dD939726b3);
    IXGrape public constant xGrape = IXGrape(0x95CED7c63eA990588F3fd01cdDe25247D04b8D98);
    IMagicToken public constant magicToken = IMagicToken(0x0dA1DC567D81925cFf22Df74C6b9e294E9E1c3A5);

    IERC20 public constant LP = IERC20(0x9076C15D7b2297723ecEAC17419D506AE320CbF1); 
    IERC20 public constant tjLP = IERC20(0xb382247667fe8CA5327cA1Fa4835AE77A9907Bc8);

    IERC20 public constant MIM = IERC20(0x130966628846BFd36ff31a822705796e8cb8C18D);
    IERC20 public constant WINE = IERC20(0xC55036B5348CfB45a932481744645985010d3A44);
    IERC20 public constant VINTAGE = IERC20(0x01Af64EF39AEB5612202AA07B3A3829f20c395fd);
    IERC20 public constant Grape = IERC20(0x5541D83EFaD1f281571B343977648B75d95cdAC2);
    IsVintage public constant sVintage = IsVintage(0xf016e69F2c08a0b743a7d815d1059318DCa8Fc0e);

    IERC20 public constant GrapeWlrsLP = IERC20(0xA3F24b18608606079a0317Cbe6Cda54CED931420);
    IERC20 public constant GrapeWineLP = IERC20(0xd3d477Df7f63A2623464Ff5Be6746981FdeD026F);
    IERC20 public constant wineMimLP = IERC20(0x00cB5b42684DA62909665d8151fF80D1567722c3);
    IERC20 public constant winePopsLP = IERC20(0xE9b9FA7f3A047d77655A9Ff8df5055f1d7826A6e);
    IERC20 public constant vintageLP = IERC20(0x1A3b20040dD5C890f247a5fb6C078B9943FfaA40);
    IERC20 public constant sodaLP = IERC20(0xE00b91F35924832D1a7d081d4DCed55f3b80FB5C);

    address public constant wineRewards = 0x28c65dcB3a5f0d456624AFF91ca03E4e315beE49;
    address public constant winery = 0x3ce7bC78a7392197C569504970017B6Eb0d7A972;
    address public constant grapeNode = 0xd77b0756bE406a6a78d47285EDD59234D781D568;
    address public constant lpNode = 0xfCbD88AD9a9f33a227c307EC1478bCDeB0412EdB;
    address public constant wlrsNode = 0x153d78155d1d579F8CC56dD110aBf6343184cA55;
    address public constant winePress = 0x2707ccc10D6C1ce49f72867aB5b85dE11e64979f;
    address public constant sodaPress = 0x369E556F0e7A08E781527D161DaC867bb05fA597;

    function winePrice() public view returns (uint256) {
        uint256 balanceMim = MIM.balanceOf(address(wineMimLP));
        uint256 balanceWine = WINE.balanceOf(address(wineMimLP));
        uint tvlMim   = ( balanceMim   * latestMimPriceFormatted() );

        return tvlMim / balanceWine;
    }

    function vintagePrice() public view returns (uint256) {
        uint256 balanceMim = MIM.balanceOf(address(vintageLP));
        uint256 balanceVintage = VINTAGE.balanceOf(address(vintageLP));
        uint tvlMim   = ( balanceMim   * latestMimPriceFormatted() );

        return tvlMim / balanceVintage;
    }

    function sVintagePrice() public view returns (uint256) {
        uint256 ratio = (sVintage.vintageWineBalance() * 1e18) / (sVintage.totalSupply());
        return (vintagePrice() * ratio) / 1e18;
    }

    function xGrapePrice() public view returns (uint256) {
        return valueOfXGrape(10**18);
    }

    function grapeWlrsLPVal() public view returns (uint256) {
        uint256 balance = Grape.balanceOf(address(GrapeWlrsLP)); 
        uint tvl = ( balance * latestGrapePriceFormatted() );

        return (tvl * 2) / GrapeWlrsLP.totalSupply();
    }

    function grapeWineLPVal() public view returns (uint256) {
        uint256 balance = Grape.balanceOf(address(GrapeWineLP)); 
        uint tvl = ( balance * latestGrapePriceFormatted() );

        return (tvl * 2) / GrapeWineLP.totalSupply();
    }

    function wineMimLPVal() public view returns (uint256) {
        uint256 balance = MIM.balanceOf(address(wineMimLP)); 
        uint tvl = ( balance * latestMimPriceFormatted() );

        return (tvl * 2) / wineMimLP.totalSupply();
    }

    function grapeSwLPVal() public view returns (uint256) {
        uint256 balance = MIM.balanceOf(address(LP)); 
        uint tvl = ( balance * latestMimPriceFormatted() );

        return (tvl * 2) / LP.totalSupply();
    }

    function grapeTjLPVal() public view returns (uint256) {
        uint256 balance = MIM.balanceOf(address(tjLP)); 
        uint tvl = ( balance * latestMimPriceFormatted() );

        return (tvl * 2) / tjLP.totalSupply();
    }

    function vintageLPVal() public view returns (uint256) {
        uint256 balance = MIM.balanceOf(address(vintageLP)); 
        uint tvl = ( balance * latestMimPriceFormatted() );

        return (tvl * 2) / vintageLP.totalSupply();
    }

    function sodaLPVal() public view returns (uint256) {
        uint256 balance = xGrape.balanceOf(address(sodaLP)); 
        uint tvl = ( balance * xGrapePrice() );

        return (tvl * 2) / sodaLP.totalSupply();
    }

    function winePopsLPVal() public view returns (uint256) {
        uint256 balance = WINE.balanceOf(address(winePopsLP)); 
        uint tvl = ( balance * winePrice() );

        return (tvl * 2) / winePopsLP.totalSupply();
    }


    function wineRewardsPoolTVL() public view returns (uint256) {
        uint256 tj = (tjLP.balanceOf(address(wineRewards)) * grapeTjLPVal()) / 1e18;
        uint256 sw = (LP.balanceOf(address(wineRewards)) * grapeSwLPVal()) / 1e18;
        uint256 wineMim = (wineMimLP.balanceOf(address(wineRewards)) * wineMimLPVal()) / 1e18;
        uint256 winePops = (winePopsLP.balanceOf(address(wineRewards)) * winePopsLPVal()) / 1e18;
        uint256 grapeWine = (GrapeWineLP.balanceOf(address(wineRewards)) * grapeWineLPVal()) / 1e18;
        uint256 grape = (Grape.balanceOf(address(wineRewards)) * latestGrapePriceFormatted()) / 1e18;
        uint256 svintage = (sVintage.balanceOf(address(wineRewards)) * sVintagePrice()) / 1e18;

        return tj + sw + wineMim + winePops + grapeWine + grape + svintage;
    }

    function nodesTVL() public view returns (uint256) {
        uint256 sw = (LP.balanceOf(address(lpNode)) * grapeSwLPVal()) / 1e18;
        uint256 grape = (Grape.balanceOf(address(grapeNode)) * latestGrapePriceFormatted()) / 1e18;
        uint256 grapewlrs = (GrapeWlrsLP.balanceOf(address(wlrsNode)) * grapeWlrsLPVal()) / 1e18;

        return sw + grapewlrs + grape;
    }

    function pressesTVL() public view returns (uint256) {
        uint256 soda = (sodaLP.balanceOf(address(sodaPress)) * sodaLPVal()) / 1e18;
        uint256 wineMim = (wineMimLP.balanceOf(address(winePress)) * wineMimLPVal()) / 1e18;

        return soda + wineMim;
    }

    function wineryTVL() public view returns (uint256) {
        uint256 wine = (WINE.balanceOf(address(winery)) * winePrice()) / 1e18;

        return wine;
    }

    function totalTVL() public view returns (uint256) {
        uint256 total = wineryTVL() + pressesTVL() + nodesTVL() + wineRewardsPoolTVL();

        return total;
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
        return latestGrapePrice() / 10**8;
    }

    function latestGrapePrice() public view returns (uint256) {
        return priceFeed.latestPrice();
    }

    function latestMimPriceFormatted() public view returns (uint256) {
        return latestMimPrice() * 10**10;
    }

    function latestMimPrice() public view returns (uint256) {
        int256 val = priceFeed.latestMimPrice();
        require(val > 0, 'MIM Price Error');
        return uint256(val);
    } 

}