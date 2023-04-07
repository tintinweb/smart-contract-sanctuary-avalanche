/**
 *Submitted for verification at snowtrace.io on 2023-04-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract GMXListingsData {
    struct GMXData {
        uint256 StakedGMXBal;
        uint256 esGMXBal;
        uint256 StakedesGMXBal;
        uint256 esGMXMaxVestGMXBal;
        uint256 esGMXMaxVestGLPBal;
        uint256 TokensToVest;
        uint256 GLPToVest;
        uint256 GLPBal;
        uint256 MPsBal;
        uint256 PendingAVAXBal;
        uint256 PendingesGMXBal;
        uint256 PendingMPsBal;
        uint256 SalePrice;
        uint256 EndAt;
    }

    struct GMXAccountData {
        uint256 StakedGMXBal;
        uint256 esGMXBal;
        uint256 StakedesGMXBal;
        uint256 esGMXMaxVestGMXBal;
        uint256 esGMXMaxVestGLPBal;
        uint256 TokensToVest;
        uint256 GLPToVest;
        uint256 GLPBal;
        uint256 MPsBal;
        uint256 PendingAVAXBal;
        uint256 PendingesGMXBal;
        uint256 PendingMPsBal;
    }

    address constant private EsGMX = 0xFf1489227BbAAC61a9209A08929E4c2a526DdD17;
    address constant private WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address constant private GMX = 0x62edc0692BD897D2295872a9FFCac5425011c661;
    address constant private GMXRewardRouter = 0x82147C5A7E850eA4E28155DF107F2590fD4ba327;
    address constant private stakedGmxTracker = 0x2bD10f8E93B3669b6d42E74eEedC65dd1B0a1342;
    address constant private bonusGmxTracker = 0x908C4D94D34924765f1eDc22A1DD098397c59dD4;
    address constant private feeGmxTracker = 0x4d268a7d4C16ceB5a606c173Bd974984343fea13;
    address constant private gmxVester = 0x472361d3cA5F49c8E633FB50385BfaD1e018b445;
    address constant private stakedGlpTracker = 0x9e295B5B976a184B14aD8cd72413aD846C299660;
    address constant private feeGlpTracker = 0xd2D1162512F927a7e282Ef43a362659E4F2a728F;
    address constant private glpVester = 0x62331A7Bd1dfB3A7642B7db50B5509E57CA3154A;

    function GetGMXListingsData(address _Address) external view returns (GMXData memory) {
       GMXData memory GMXDataOut;
       GMXDataOut.StakedGMXBal = IRewardTracker(stakedGmxTracker).depositBalances(_Address, GMX);
       GMXDataOut.esGMXBal = IERC20(EsGMX).balanceOf(_Address);
       GMXDataOut.StakedesGMXBal = IRewardTracker(stakedGmxTracker).depositBalances(_Address, EsGMX);
       GMXDataOut.esGMXMaxVestGMXBal = IVester(gmxVester).getMaxVestableAmount(_Address);
       GMXDataOut.esGMXMaxVestGLPBal = IVester(glpVester).getMaxVestableAmount(_Address);
       GMXDataOut.TokensToVest = IVester(gmxVester).getCombinedAverageStakedAmount(_Address);
       GMXDataOut.GLPToVest = IVester(glpVester).getCombinedAverageStakedAmount(_Address);
       GMXDataOut.GLPBal = IERC20(stakedGlpTracker).balanceOf(_Address);
       GMXDataOut.MPsBal = IRewardTracker(feeGmxTracker).depositBalances(_Address, 0x8087a341D32D445d9aC8aCc9c14F5781E04A26d2);
       GMXDataOut.PendingAVAXBal = IRewardTracker(feeGmxTracker).claimable(_Address);
       GMXDataOut.PendingesGMXBal = IRewardTracker(stakedGmxTracker).claimable(_Address) + IRewardTracker(stakedGlpTracker).claimable(_Address);
       GMXDataOut.PendingMPsBal = IRewardTracker(bonusGmxTracker).claimable(_Address);
       GMXDataOut.SalePrice = IGMXVault(_Address).SalePrice();
       GMXDataOut.EndAt = IGMXVault(_Address).EndAt();
       return (GMXDataOut);
    }

function GetGMXAccountData(address _Address) external view returns (GMXAccountData memory) {
       GMXAccountData memory GMXAccountDataOut;
       GMXAccountDataOut.StakedGMXBal = IRewardTracker(stakedGmxTracker).depositBalances(_Address, GMX);
       GMXAccountDataOut.esGMXBal = IERC20(EsGMX).balanceOf(_Address);
       GMXAccountDataOut.StakedesGMXBal = IRewardTracker(stakedGmxTracker).depositBalances(_Address, EsGMX);
       GMXAccountDataOut.esGMXMaxVestGMXBal = IVester(gmxVester).getMaxVestableAmount(_Address);
       GMXAccountDataOut.esGMXMaxVestGLPBal = IVester(glpVester).getMaxVestableAmount(_Address);
       GMXAccountDataOut.TokensToVest = IVester(gmxVester).getCombinedAverageStakedAmount(_Address);
       GMXAccountDataOut.GLPToVest = IVester(glpVester).getCombinedAverageStakedAmount(_Address);
       GMXAccountDataOut.GLPBal = IERC20(stakedGlpTracker).balanceOf(_Address);
       GMXAccountDataOut.MPsBal = IRewardTracker(feeGmxTracker).depositBalances(_Address, 0x8087a341D32D445d9aC8aCc9c14F5781E04A26d2);
       GMXAccountDataOut.PendingAVAXBal = IRewardTracker(feeGmxTracker).claimable(_Address);
       GMXAccountDataOut.PendingesGMXBal = IRewardTracker(stakedGmxTracker).claimable(_Address) + IRewardTracker(stakedGlpTracker).claimable(_Address);
       GMXAccountDataOut.PendingMPsBal = IRewardTracker(bonusGmxTracker).claimable(_Address);
       return (GMXAccountDataOut);
    }
}

interface IRewardTracker {
    function depositBalances(address _account, address _depositToken) external view returns (uint256);
    function stakedAmounts(address _account) external returns (uint256);
    function updateRewards() external;
    function stake(address _depositToken, uint256 _amount) external;
    function stakeForAccount(address _fundingAccount, address _account, address _depositToken, uint256 _amount) external;
    function unstake(address _depositToken, uint256 _amount) external;
    function unstakeForAccount(address _account, address _depositToken, uint256 _amount, address _receiver) external;
    function tokensPerInterval() external view returns (uint256);
    function claim(address _receiver) external returns (uint256);
    function claimForAccount(address _account, address _receiver) external returns (uint256);
    function claimable(address _account) external view returns (uint256);
    function averageStakedAmounts(address _account) external view returns (uint256);
    function cumulativeRewards(address _account) external view returns (uint256);
}

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

interface IVester {
    function getMaxVestableAmount(address _account) external view returns (uint256);
    function getCombinedAverageStakedAmount(address _account) external view returns (uint256);
}

interface IGMXVault {
    function SalePrice() external view returns (uint256);
    function EndAt() external view returns (uint256);
}