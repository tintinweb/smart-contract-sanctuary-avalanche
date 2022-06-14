/**
 *Submitted for verification at snowtrace.io on 2022-06-14
*/

// File: contracts/prize/AAVELending/AAVEInterfaces.sol



pragma solidity 0.7.5;

interface AAVELendingPool {
    // balance is erc20
    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

interface AAVERewards {
  function claimRewards(
    address[] calldata assets,
    uint256 amount,
    address to,
    address reward
  ) external returns (uint256);
}


// File: contracts/prize/AAVELending/AAVELendingBridge.sol



/* *********************************
 * Owned and operated by defiprizes.com
 * ********************************* */

pragma solidity 0.7.5;


contract AAVELendingBridge {

    // must be called with delegated call
    function deposit(address lendingPool, address aaveAsset, uint256 amount) external {
        AAVELendingPool(lendingPool).supply(aaveAsset, amount, address(this), uint16(0));
    }

    function withdraw(address lendingPool, address aaveAsset, uint256 amount) external { 
        AAVELendingPool(lendingPool).withdraw(aaveAsset, amount, address(this));
    }
}