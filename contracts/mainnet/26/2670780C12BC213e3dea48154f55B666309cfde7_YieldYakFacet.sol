// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: ;
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../../ReentrancyGuardKeccak.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "../../lib/SolvencyMethods.sol";
import "../../interfaces/facets/avalanche/IYieldYak.sol";

import {DiamondStorageLib} from "../../lib/DiamondStorageLib.sol";
import "../../interfaces/IWrappedNativeToken.sol";

// TODO: Check STATUS (tokenManager) of Vault tokens before allowing to stake
//This path is updated during deployment
import "../../lib/avalanche/DeploymentConstants.sol";

contract YieldYakFacet is ReentrancyGuardKeccak, SolvencyMethods {
    using TransferHelper for address payable;
    using TransferHelper for address;

    // Staking Vaults tokens
    address private constant YY_AAVE_AVAX = 0xaAc0F2d0630d1D09ab2B5A400412a4840B866d95;
    address private constant YY_PTP_sAVAX = 0xb8f531c0d3c53B1760bcb7F57d87762Fd25c4977;

    // Staking Vaults LPs
    address private constant YY_PNG_AVAX_USDC_LP = 0xC0cd58661b68e10b49D3Bec4bC5E44e7A7c20656;
    address private constant YY_PNG_AVAX_ETH_LP = 0xFCD2050E213cC54db2c9c99632AC870574FbC261;
    address private constant YY_TJ_AVAX_USDC_LP = 0xDEf94a13fF31FB6363f1e03bF18fe0F59Db83BBC;
    address private constant YY_TJ_AVAX_ETH_LP = 0x5219558ee591b030E075892acc41334A1694fd8A;
    address private constant YY_TJ_AVAX_sAVAX_LP = 0x22EDe03f1115666CF05a4bAfafaEe8F43D42cD56;

    // Tokens
    address private constant SAVAX_TOKEN = 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE;
    address private constant AVAX_TOKEN = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    // LPs
    address private constant PNG_AVAX_USDC_LP = 0x0e0100Ab771E9288e0Aa97e11557E6654C3a9665;
    address private constant PNG_AVAX_ETH_LP = 0x7c05d54fc5CB6e4Ad87c6f5db3b807C94bB89c52;

    address private constant TJ_AVAX_USDC_LP = 0xf4003F4efBE8691B60249E6afbD307aBE7758adb;
    address private constant TJ_AVAX_ETH_LP = 0xFE15c2695F1F920da45C30AAE47d11dE51007AF9;
    address private constant TJ_AVAX_sAVAX_LP = 0x4b946c91C2B1a7d7C40FB3C130CdfBaf8389094d;

    // ----- STAKE -----

    /**
        * Stakes AVAX in Yield Yak protocol
        * @dev This function uses the redstone-evm-connector
        * @param amount amount of AVAX to be staked
    **/
    function stakeAVAXYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        require(amount > 0, "Cannot stake 0 tokens");
        require(IWrappedNativeToken(AVAX_TOKEN).balanceOf(address(this)) >= amount, "Not enough AVAX available");

        IWrappedNativeToken(AVAX_TOKEN).withdraw(amount);
        IYieldYak(YY_AAVE_AVAX).deposit{value: amount}();

        DiamondStorageLib.addOwnedAsset("YY_AAVE_AVAX", YY_AAVE_AVAX);

        emit Staked(msg.sender, "AVAX", YY_AAVE_AVAX, amount, block.timestamp);
    }

    /**
       * Stakes sAVAX in Yield Yak protocol
       * @dev This function uses the redstone-evm-connector
       * @param amount amount of sAVAX to be staked
    **/
    function stakeSAVAXYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        _stakeTokenYY(IYieldYak.YYStakingDetails({
            tokenAddress: SAVAX_TOKEN,
            vaultAddress: YY_PTP_sAVAX,
            tokenSymbol: "sAVAX",
            vaultTokenSymbol: "YY_PTP_sAVAX",
            amount: amount
        }));
    }

    /**
      * Stakes PNG_AVAX_USDC_LP in Yield Yak protocol
      * @dev This function uses the redstone-evm-connector
      * @param amount amount of PNG_AVAX_USDC_LP to be staked
    **/
    function stakePNGAVAXUSDCYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        _stakeTokenYY(IYieldYak.YYStakingDetails({
        tokenAddress: PNG_AVAX_USDC_LP,
        vaultAddress: YY_PNG_AVAX_USDC_LP,
        tokenSymbol: "PNG_AVAX_USDC_LP",
        vaultTokenSymbol: "YY_PNG_AVAX_USDC_LP",
        amount: amount
        }));
    }

    /**
      * Stakes PNG_AVAX_ETH_LP in Yield Yak protocol
      * @dev This function uses the redstone-evm-connector
      * @param amount amount of PNG_AVAX_ETH_LP to be staked
    **/
    function stakePNGAVAXETHYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        _stakeTokenYY(IYieldYak.YYStakingDetails({
        tokenAddress: PNG_AVAX_ETH_LP,
        vaultAddress: YY_PNG_AVAX_ETH_LP,
        tokenSymbol: "PNG_AVAX_ETH_LP",
        vaultTokenSymbol: "YY_PNG_AVAX_ETH_LP",
        amount: amount
        }));
    }

    /**
      * Stakes TJ_AVAX_USDC in Yield Yak protocol
      * @dev This function uses the redstone-evm-connector
      * @param amount amount of TJ_AVAX_USDC to be staked
    **/
    function stakeTJAVAXUSDCYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        _stakeTokenYY(IYieldYak.YYStakingDetails({
        tokenAddress: TJ_AVAX_USDC_LP,
        vaultAddress: YY_TJ_AVAX_USDC_LP,
        tokenSymbol: "TJ_AVAX_USDC_LP",
        vaultTokenSymbol: "YY_TJ_AVAX_USDC_LP",
        amount: amount
        }));
    }

    /**
      * Stakes TJ_AVAX_ETH_LP in Yield Yak protocol
      * @dev This function uses the redstone-evm-connector
      * @param amount amount of TJ_AVAX_ETH_LP to be staked
    **/
    function stakeTJAVAXETHYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        _stakeTokenYY(IYieldYak.YYStakingDetails({
        tokenAddress: TJ_AVAX_ETH_LP,
        vaultAddress: YY_TJ_AVAX_ETH_LP,
        tokenSymbol: "TJ_AVAX_ETH_LP",
        vaultTokenSymbol: "YY_TJ_AVAX_ETH_LP",
        amount: amount
        }));
    }

    /**
      * Stakes TJ_AVAX_sAVAX_LP in Yield Yak protocol
      * @dev This function uses the redstone-evm-connector
      * @param amount amount of TJ_AVAX_sAVAX_LP to be staked
    **/
    function stakeTJAVAXSAVAXYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        _stakeTokenYY(IYieldYak.YYStakingDetails({
        tokenAddress: TJ_AVAX_sAVAX_LP,
        vaultAddress: YY_TJ_AVAX_sAVAX_LP,
        tokenSymbol: "TJ_AVAX_sAVAX_LP",
        vaultTokenSymbol: "YY_TJ_AVAX_sAVAX_LP",
        amount: amount
        }));
    }

    // ----- UNSTAKE -----

    /**
        * Unstakes AVAX from Yield Yak protocol
        * @dev This function uses the redstone-evm-connector
        * @param amount amount of AVAX to be unstaked
    **/
    function unstakeAVAXYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        IYieldYak yakStakingContract = IYieldYak(YY_AAVE_AVAX);
        uint256 initialStakedBalance = yakStakingContract.balanceOf(address(this));

        require(initialStakedBalance >= amount, "Cannot unstake more than was initially staked");

        yakStakingContract.withdraw(amount);

        if(yakStakingContract.balanceOf(address(this)) == 0) {
            DiamondStorageLib.removeOwnedAsset("YY_AAVE_AVAX");
        }

        emit Unstaked(msg.sender, "AVAX", YY_AAVE_AVAX, amount, block.timestamp);

        IWrappedNativeToken(AVAX_TOKEN).deposit{value: amount}();
    }

    /**
    * Unstakes sAVAX from Yield Yak protocol
    * @dev This function uses the redstone-evm-connector
        * @param amount amount of sAVAX to be unstaked
    **/
    function unstakeSAVAXYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        IYieldYak yakStakingContract = IYieldYak(YY_PTP_sAVAX);
        uint256 initialStakedBalance = yakStakingContract.balanceOf(address(this));

        require(initialStakedBalance >= amount, "Cannot unstake more than was initially staked");

        yakStakingContract.withdraw(amount);

        if(yakStakingContract.balanceOf(address(this)) == 0) {
            DiamondStorageLib.removeOwnedAsset("YY_PTP_sAVAX");
        }

        emit Unstaked(msg.sender, "sAVAX", YY_PTP_sAVAX, amount, block.timestamp);
    }

    /**
      * Unstakes PNG_AVAX_USDC_LP in Yield Yak protocol
      * @dev This function uses the redstone-evm-connector
      * @param amount amount of PNG_AVAX_USDC_LP to be staked
    **/
    function unstakePNGAVAXUSDCYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        _unstakeTokenYY(IYieldYak.YYStakingDetails({
        tokenAddress: PNG_AVAX_USDC_LP,
        vaultAddress: YY_PNG_AVAX_USDC_LP,
        tokenSymbol: "PNG_AVAX_USDC_LP",
        vaultTokenSymbol: "YY_PNG_AVAX_USDC_LP",
        amount: amount
        }));
    }

    /**
      * Unstakes PNG_AVAX_ETH_LP in Yield Yak protocol
      * @dev This function uses the redstone-evm-connector
      * @param amount amount of PNG_AVAX_ETH_LP to be unstaked
    **/
    function unstakePNGAVAXETHYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        _unstakeTokenYY(IYieldYak.YYStakingDetails({
        tokenAddress: PNG_AVAX_ETH_LP,
        vaultAddress: YY_PNG_AVAX_ETH_LP,
        tokenSymbol: "PNG_AVAX_ETH_LP",
        vaultTokenSymbol: "YY_PNG_AVAX_ETH_LP",
        amount: amount
        }));
    }

    /**
      * Unstakes TJ_AVAX_USDC in Yield Yak protocol
      * @dev This function uses the redstone-evm-connector
      * @param amount amount of TJ_AVAX_USDC to be unstaked
    **/
    function unstakeTJAVAXUSDCYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        _unstakeTokenYY(IYieldYak.YYStakingDetails({
        tokenAddress: TJ_AVAX_USDC_LP,
        vaultAddress: YY_TJ_AVAX_USDC_LP,
        tokenSymbol: "TJ_AVAX_USDC_LP",
        vaultTokenSymbol: "YY_TJ_AVAX_USDC_LP",
        amount: amount
        }));
    }

    /**
      * Unstakes TJ_AVAX_ETH_LP in Yield Yak protocol
      * @dev This function uses the redstone-evm-connector
      * @param amount amount of TJ_AVAX_ETH_LP to be unstaked
    **/
    function unstakeTJAVAXETHYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        _unstakeTokenYY(IYieldYak.YYStakingDetails({
        tokenAddress: TJ_AVAX_ETH_LP,
        vaultAddress: YY_TJ_AVAX_ETH_LP,
        tokenSymbol: "TJ_AVAX_ETH_LP",
        vaultTokenSymbol: "YY_TJ_AVAX_ETH_LP",
        amount: amount
        }));
    }

    /**
      * Unstakes TJ_AVAX_sAVAX_LP in Yield Yak protocol
      * @dev This function uses the redstone-evm-connector
      * @param amount amount of TJ_AVAX_sAVAX_LP to be unstaked
    **/
    function unstakeTJAVAXSAVAXYak(uint256 amount) public onlyOwner nonReentrant remainsSolvent {
        _unstakeTokenYY(IYieldYak.YYStakingDetails({
        tokenAddress: TJ_AVAX_sAVAX_LP,
        vaultAddress: YY_TJ_AVAX_sAVAX_LP,
        tokenSymbol: "TJ_AVAX_sAVAX_LP",
        vaultTokenSymbol: "YY_TJ_AVAX_sAVAX_LP",
        amount: amount
        }));
    }

    // ----- PRIVATE METHODS -----

    /**
      * Stakes {stakingDetails.tokenAddress} token in the YieldYak protocol
      * @dev This function uses the redstone-evm-connector
      * @param stakingDetails IYieldYak.YYStakingDetails staking details
    **/
    function _stakeTokenYY(IYieldYak.YYStakingDetails memory stakingDetails) private {
        TokenManager tokenManager = DeploymentConstants.getTokenManager();

        require(stakingDetails.amount > 0, "Cannot stake 0 tokens");
        // _ACTIVE = 2
        require(tokenManager.tokenToStatus(stakingDetails.tokenAddress) == 2, "Token not supported");
        require(tokenManager.tokenToStatus(stakingDetails.vaultAddress) == 2, "Vault token not supported");
        require(IERC20Metadata(stakingDetails.tokenAddress).balanceOf(address(this)) >= stakingDetails.amount, "Not enough token available");

        IERC20Metadata(stakingDetails.tokenAddress).approve(stakingDetails.vaultAddress, stakingDetails.amount);
        IYieldYak(stakingDetails.vaultAddress).deposit(stakingDetails.amount);

        // Add/remove owned tokens
        DiamondStorageLib.addOwnedAsset(stakingDetails.vaultTokenSymbol, stakingDetails.vaultAddress);
        if(IERC20(stakingDetails.tokenAddress).balanceOf(address(this)) == 0) {
            DiamondStorageLib.removeOwnedAsset(stakingDetails.tokenSymbol);
        }

        emit Staked(msg.sender, stakingDetails.tokenSymbol, stakingDetails.vaultAddress, stakingDetails.amount, block.timestamp);
    }

    /**
      * Unstakes {stakingDetails.tokenAddress} token in the YieldYak protocol
      * @dev This function uses the redstone-evm-connector
      * @param stakingDetails IYieldYak.YYStakingDetails staking details
    **/
    function _unstakeTokenYY(IYieldYak.YYStakingDetails memory stakingDetails) private {
        IYieldYak vaultContract = IYieldYak(stakingDetails.vaultAddress);
        uint256 initialStakedBalance = vaultContract.balanceOf(address(this));

        require(initialStakedBalance >= stakingDetails.amount, "Cannot unstake more than was initially staked");

        vaultContract.withdraw(stakingDetails.amount);

        // Add/remove owned tokens
        DiamondStorageLib.addOwnedAsset(stakingDetails.tokenSymbol, stakingDetails.tokenAddress);
        if(vaultContract.balanceOf(address(this)) == 0) {
            DiamondStorageLib.removeOwnedAsset(stakingDetails.vaultTokenSymbol);
        }

        emit Unstaked(msg.sender, stakingDetails.tokenSymbol, stakingDetails.vaultAddress, stakingDetails.amount, block.timestamp);
    }


    modifier onlyOwner() {
        DiamondStorageLib.enforceIsContractOwner();
        _;
    }

    /* ========== RECEIVE AVAX FUNCTION ========== */
    receive() external payable {}

    /**
        * @dev emitted when user stakes an asset
        * @param user the address executing staking
        * @param vault address of the vault token
        * @param asset the asset that was staked
        * @param amount of the asset that was staked
        * @param timestamp of staking
    **/
    event Staked(address indexed user, bytes32 indexed asset, address indexed vault, uint256 amount, uint256 timestamp);

    /**
        * @dev emitted when user unstakes an asset
        * @param user the address executing unstaking
        * @param vault address of the vault token
        * @param asset the asset that was unstaked
        * @param amount of the asset that was unstaked
        * @param timestamp of unstaking
    **/
    event Unstaked(address indexed user, bytes32 indexed asset, address indexed vault, uint256 amount, uint256 timestamp);
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

// SPDX-License-Identifier: MIT
// Modified version of Openzeppelin (OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)) ReentrancyGuard
// contract that uses keccak slots instead of the standard storage layout.

import {DiamondStorageLib} from "./lib/DiamondStorageLib.sol";

pragma solidity 0.8.17;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 */
abstract contract ReentrancyGuardKeccak {
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
        DiamondStorageLib.ReentrancyGuardStorage storage rgs = DiamondStorageLib.reentrancyGuardStorage();
        // On the first call to nonReentrant, _notEntered will be true
        require(rgs._status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        rgs._status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        rgs._status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: ;
pragma solidity 0.8.17;

import "@redstone-finance/evm-connector/contracts/core/ProxyConnector.sol";
import "../facets/SolvencyFacetProd.sol";
import "../DiamondHelper.sol";

// TODO Rename to contract instead of lib
contract SolvencyMethods is DiamondHelper, ProxyConnector {
    // This function executes SolvencyFacetProd.getDebt()
    function _getDebt() internal virtual returns (uint256 debt) {
        debt = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.getDebt.selector),
                abi.encodeWithSelector(SolvencyFacetProd.getDebt.selector)
            ),
            (uint256)
        );
    }

    // This function executes SolvencyFacetProd.getDebtWithPrices()
    function _getDebtWithPrices(SolvencyFacetProd.AssetPrice[] memory debtAssetsPrices) internal virtual returns (uint256 debt) {
        debt = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.getDebtWithPrices.selector),
                abi.encodeWithSelector(SolvencyFacetProd.getDebtWithPrices.selector, debtAssetsPrices)
            ),
            (uint256)
        );
    }

    // This function executes SolvencyFacetProd.isSolventWithPrices()
    function _isSolventWithPrices(SolvencyFacetProd.AssetPrice[] memory ownedAssetsPrices, SolvencyFacetProd.AssetPrice[] memory debtAssetsPrices, SolvencyFacetProd.AssetPrice[] memory stakedPositionsPrices) internal virtual returns (bool solvent){
        solvent = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.isSolventWithPrices.selector),
                abi.encodeWithSelector(SolvencyFacetProd.isSolventWithPrices.selector, ownedAssetsPrices, debtAssetsPrices, stakedPositionsPrices)
            ),
            (bool)
        );
    }

    // This function executes SolvencyFacetProd.isSolvent()
    function _isSolvent() internal virtual returns (bool solvent){
        solvent = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.isSolvent.selector),
                abi.encodeWithSelector(SolvencyFacetProd.isSolvent.selector)
            ),
            (bool)
        );
    }

    // This function executes SolvencyFacetProd.getTotalValue()
    function _getTotalValue() internal virtual returns (uint256 totalValue) {
        totalValue = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.getTotalValue.selector),
                abi.encodeWithSelector(SolvencyFacetProd.getTotalValue.selector)
            ),
            (uint256)
        );
    }

    // This function executes SolvencyFacetProd.getTotalAssetsValue()
    function _getTotalAssetsValue() internal virtual returns (uint256 assetsValue) {
        assetsValue = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.getTotalAssetsValue.selector),
                abi.encodeWithSelector(SolvencyFacetProd.getTotalAssetsValue.selector)
            ),
            (uint256)
        );
    }

    // This function executes SolvencyFacetProd.getHealthRatioWithPrices()
    function _getHealthRatioWithPrices(SolvencyFacetProd.AssetPrice[] memory ownedAssetsPrices, SolvencyFacetProd.AssetPrice[] memory debtAssetsPrices, SolvencyFacetProd.AssetPrice[] memory stakedPositionsPrices) public virtual returns (uint256 health) {
        health = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.getHealthRatioWithPrices.selector),
                abi.encodeWithSelector(SolvencyFacetProd.getHealthRatioWithPrices.selector, ownedAssetsPrices, debtAssetsPrices, stakedPositionsPrices)
            ),
            (uint256)
        );
    }

    // This function executes SolvencyFacetProd.getHealthRatio()
    function _getHealthRatio() public virtual returns (uint256 health) {
        health = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.getHealthRatio.selector),
                abi.encodeWithSelector(SolvencyFacetProd.getHealthRatio.selector)
            ),
            (uint256)
        );
    }

    // This function executes SolvencyFacetProd.getPrices()
    function getPrices(bytes32[] memory symbols) public virtual returns (uint256[] memory prices) {
        prices = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.getPrices.selector),
                abi.encodeWithSelector(SolvencyFacetProd.getPrices.selector, symbols)
            ),
            (uint256[])
        );
    }

    // This function executes SolvencyFacetProd.getPrices()
    function _getAllPricesForLiquidation(bytes32[] memory assetsToRepay) public virtual returns (SolvencyFacetProd.CachedPrices memory result) {
        result = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.getAllPricesForLiquidation.selector),
                abi.encodeWithSelector(SolvencyFacetProd.getAllPricesForLiquidation.selector, assetsToRepay)
            ),
            (SolvencyFacetProd.CachedPrices)
        );
    }

    // This function executes SolvencyFacetProd.getOwnedAssetsPrices()
    function _getOwnedAssetsPrices() internal virtual returns (SolvencyFacetProd.AssetPrice[] memory ownedAssetsPrices) {
        ownedAssetsPrices = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.getOwnedAssetsPrices.selector),
                abi.encodeWithSelector(SolvencyFacetProd.getOwnedAssetsPrices.selector)
            ),
            (SolvencyFacetProd.AssetPrice[])
        );
    }

    // This function executes SolvencyFacetProd.getDebtAssetsPrices()
    function _getDebtAssetsPrices() internal virtual returns (SolvencyFacetProd.AssetPrice[] memory debtAssetsPrices) {
        debtAssetsPrices = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.getDebtAssetsPrices.selector),
                abi.encodeWithSelector(SolvencyFacetProd.getDebtAssetsPrices.selector)
            ),
            (SolvencyFacetProd.AssetPrice[])
        );
    }

    // This function executes SolvencyFacetProd.getStakedPositionsPrices()
    function _getStakedPositionsPrices() internal virtual returns (SolvencyFacetProd.AssetPrice[] memory stakedPositionsPrices) {
        stakedPositionsPrices = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.getStakedPositionsPrices.selector),
                abi.encodeWithSelector(SolvencyFacetProd.getStakedPositionsPrices.selector)
            ),
            (SolvencyFacetProd.AssetPrice[])
        );
    }

    // This function executes SolvencyFacetProd.getTotalAssetsValueWithPrices()
    function _getTotalValueWithPrices(SolvencyFacetProd.AssetPrice[] memory ownedAssetsPrices, SolvencyFacetProd.AssetPrice[] memory stakedPositionsPrices) internal virtual returns (uint256 totalValue) {
        totalValue = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.getTotalValueWithPrices.selector),
                abi.encodeWithSelector(SolvencyFacetProd.getTotalValueWithPrices.selector, ownedAssetsPrices, stakedPositionsPrices)
            ),
            (uint256)
        );
    }

    // This function executes SolvencyFacetProd.getPrices()
    function getPrice(bytes32 symbol) public virtual returns (uint256 price) {
        price = abi.decode(
            proxyDelegateCalldata(
                DiamondHelper._getFacetAddress(SolvencyFacetProd.getPrice.selector),
                abi.encodeWithSelector(SolvencyFacetProd.getPrice.selector, symbol)
            ),
            (uint256)
        );
    }

    /**
     * Returns IERC20Metadata instance of a token
     * @param _asset the code of an asset
     **/
    function getERC20TokenInstance(bytes32 _asset, bool allowInactive) internal view returns (IERC20Metadata) {
        return IERC20Metadata(DeploymentConstants.getTokenManager().getAssetAddress(_asset, allowInactive));
    }

    /**
    * Checks whether account is solvent (health higher than 1)
    * @dev This modifier uses the redstone-evm-connector
    **/
    modifier remainsSolvent() {
        _;

        require(_isSolvent(), "The action may cause an account to become insolvent");
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: ;
pragma solidity 0.8.17;

interface IYieldYak {
    function totalDeposits() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function withdraw(uint256 amount) external;

    function depositFor(address account) external payable;

    function depositFor(address account, uint256 amount) external;

    function deposit() external payable;

    function deposit(uint256 amount) external;

    function decimals() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    // ---INTERFACE-----
    struct YYStakingDetails {
        address tokenAddress;
        address vaultAddress;
        bytes32 tokenSymbol;
        bytes32 vaultTokenSymbol;
        uint256 amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import {IDiamondCut} from "../interfaces/IDiamondCut.sol";
import "../lib/Bytes32EnumerableMap.sol";
import "../interfaces/IStakingPositions.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library DiamondStorageLib {
    using EnumerableMap for EnumerableMap.Bytes32ToAddressMap;

    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");
    bytes32 constant SMARTLOAN_STORAGE_POSITION = keccak256("diamond.standard.smartloan.storage");
    bytes32 constant REENTRANCY_GUARD_STORAGE_POSITION = keccak256("diamond.standard.reentrancy.guard.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // ----------- DIAMOND-SPECIFIC VARIABLES --------------
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;

        bool _initialized;
        bool _active;
    }

    struct SmartLoanStorage {
        // Owner of the contract
        address contractOwner;
        // Proposed owner of the contract
        address proposedOwner;
        // Is contract initialized?
        bool _initialized;
        // TODO: mock staking tokens until redstone oracle supports them
        EnumerableMap.Bytes32ToAddressMap ownedAssets;
        // Staked positions of the contract
        IStakingPositions.StakedPosition[] currentStakedPositions;
    }

    struct ReentrancyGuardStorage {
        uint256 _status;
    }

    function reentrancyGuardStorage() internal pure returns (ReentrancyGuardStorage storage rgs) {
        bytes32 position = REENTRANCY_GUARD_STORAGE_POSITION;
        assembly {
            rgs.slot := position
        }
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function smartLoanStorage() internal pure returns (SmartLoanStorage storage sls) {
        bytes32 position = SMARTLOAN_STORAGE_POSITION;
        assembly {
            sls.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        SmartLoanStorage storage sls = smartLoanStorage();
        address previousOwner = sls.contractOwner;
        sls.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = smartLoanStorage().contractOwner;
    }

    function setProposedOwner(address _newOwner) internal {
        SmartLoanStorage storage sls = smartLoanStorage();
        sls.proposedOwner = _newOwner;
    }

    function proposedOwner() internal view returns (address proposedOwner_) {
        proposedOwner_ = smartLoanStorage().proposedOwner;
    }

    function stakedPositions() internal view returns (IStakingPositions.StakedPosition[] storage _positions) {
        _positions = smartLoanStorage().currentStakedPositions;
    }

    function addStakedPosition(IStakingPositions.StakedPosition memory position) internal {
        IStakingPositions.StakedPosition[] storage positions = stakedPositions();

        bool found;

        for (uint256 i; i < positions.length; i++) {
            if (positions[i].balanceSelector == position.balanceSelector) {
                found = true;
                break;
            }
        }

        if (!found) {
            positions.push(position);
        }
    }

    function removeStakedPosition(bytes4 balanceSelector) internal {
        IStakingPositions.StakedPosition[] storage positions = stakedPositions();

        for (uint256 i; i < positions.length; i++) {
            if (positions[i].balanceSelector == balanceSelector) {
                positions[i] = positions[positions.length - 1];
                positions.pop();
            }
        }
    }

    function addOwnedAsset(bytes32 _symbol, address _address) internal {
        require(_symbol != "", "Symbol cannot be empty");
        require(_address != address(0), "Invalid AddressZero");
        SmartLoanStorage storage sls = smartLoanStorage();
        EnumerableMap.set(sls.ownedAssets, _symbol, _address);
    }

    function hasAsset(bytes32 _symbol) internal view returns (bool){
        SmartLoanStorage storage sls = smartLoanStorage();
        return sls.ownedAssets.contains(_symbol);
    }

    function removeOwnedAsset(bytes32 _symbol) internal {
        SmartLoanStorage storage sls = smartLoanStorage();
        EnumerableMap.remove(sls.ownedAssets, _symbol);
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == smartLoanStorage().contractOwner, "DiamondStorageLib: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("DiamondStorageLibCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "DiamondStorageLibCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "DiamondStorageLibCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "DiamondStorageLibCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "DiamondStorageLibCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "DiamondStorageLibCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "DiamondStorageLibCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "DiamondStorageLibCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "DiamondStorageLibCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "DiamondStorageLibCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {
        require(_facetAddress != address(0), "DiamondStorageLibCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "DiamondStorageLibCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "DiamondStorageLibCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "DiamondStorageLibCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "DiamondStorageLibCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("DiamondStorageLibCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity 0.8.17;

interface IWrappedNativeToken {

    function balanceOf(address account) external view returns (uint);

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad) external returns (bool);

}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: f63ef97516096bbd3db42914b6554a461f90ef40;
pragma solidity 0.8.17;

import "../../TokenManager.sol";
import {DiamondStorageLib} from "../../lib/DiamondStorageLib.sol";
import "../../RedstoneConfigManager.sol";

/**
 * DeploymentConstants
 * These constants are updated during test and prod deployments using JS scripts. Defined as constants
 * to decrease gas costs. Not meant to be updated unless really necessary.
 * BE CAREFUL WHEN UPDATING. CONSTANTS CAN BE USED AMONG MANY FACETS.
 **/
library DeploymentConstants {

    // Used for LiquidationBonus calculations
    uint256 private constant _PERCENTAGE_PRECISION = 1000;

    bytes32 private constant _NATIVE_TOKEN_SYMBOL = 'AVAX';

    address private constant _NATIVE_ADDRESS = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    address private constant _DIAMOND_BEACON_ADDRESS = 0x7dBcB7b5019cfD15225E5aDc454B864CA1b7f2d1;

    address private constant _SMART_LOANS_FACTORY_ADDRESS = 0x9FDb3940D8A91E89b4399Fbb0D038DC296A43C42;

    address private constant _TOKEN_MANAGER_ADDRESS = 0x9CD7eCfF2F5A95C1D6ee2ceB3e53909EbE9d57BB;

    address private constant _REDSTONE_CONFIG_MANAGER_ADDRESS = 0x127587D8a188493Cc032A0eC2bd1D559E3A8E275;

    //implementation-specific

    function getPercentagePrecision() internal pure returns (uint256) {
        return _PERCENTAGE_PRECISION;
    }

    //blockchain-specific

    function getNativeTokenSymbol() internal pure returns (bytes32 symbol) {
        return _NATIVE_TOKEN_SYMBOL;
    }

    function getNativeToken() internal pure returns (address payable) {
        return payable(_NATIVE_ADDRESS);
    }

    //deployment-specific

    function getDiamondAddress() internal pure returns (address) {
        return _DIAMOND_BEACON_ADDRESS;
    }

    function getSmartLoansFactoryAddress() internal pure returns (address) {
        return _SMART_LOANS_FACTORY_ADDRESS;
    }

    function getTokenManager() internal pure returns (TokenManager) {
        return TokenManager(_TOKEN_MANAGER_ADDRESS);
    }

    function getRedstoneConfigManager() internal pure returns (RedstoneConfigManager) {
        return RedstoneConfigManager(_REDSTONE_CONFIG_MANAGER_ADDRESS);
    }

    /**
    * Returns all owned assets keys
    **/
    function getAllOwnedAssets() internal view returns (bytes32[] memory result) {
        DiamondStorageLib.SmartLoanStorage storage sls = DiamondStorageLib.smartLoanStorage();
        return sls.ownedAssets._inner._keys._inner._values;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
pragma solidity 0.8.17;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    function pause() external;

    function unpause() external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

//It's Open Zeppelin EnumerableMap library modified to accept bytes32 type as a key

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Bytes32ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;
        mapping(bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(
        Map storage map,
        bytes32 key,
        bytes32 value
    ) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

    /**
     * @dev Returns the key-value pair stored at position `index` in the map. O(1).
     *
     * Note that there are no guarantees on the ordering of entries inside the
     * array, and it may change when more entries are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(
        Map storage map,
        bytes32 key,
        string memory errorMessage
    ) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // Bytes32ToAddressMap

    struct Bytes32ToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(
        Bytes32ToAddressMap storage map,
        bytes32 key,
        address value
    ) internal returns (bool) {
        return _set(map._inner, key, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(Bytes32ToAddressMap storage map, bytes32 key) internal returns (bool) {
        return _remove(map._inner, key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(Bytes32ToAddressMap storage map, bytes32 key) internal view returns (bool) {
        return _contains(map._inner, key);
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(Bytes32ToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

    /**
     * @dev Returns the element stored at position `index` in the set. O(1).
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32ToAddressMap storage map, uint256 index) internal view returns (bytes32, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (key, address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(Bytes32ToAddressMap storage map, bytes32 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, key);
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(Bytes32ToAddressMap storage map, bytes32 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, key))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(
        Bytes32ToAddressMap storage map,
        bytes32 key,
        string memory errorMessage
    ) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, key, errorMessage))));
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: ;
pragma solidity 0.8.17;

/**
 * @title IStakingPositions
 * Types for staking
 */
interface IStakingPositions {
    struct StakedPosition {
        address vault;
        bytes32 symbol;
        bytes4 balanceSelector;
        bytes4 unstakeSelector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./RedstoneConstants.sol";
import "./CalldataExtractor.sol";

/**
 * @title The base contract for forwarding redstone payload to other contracts
 * @author The Redstone Oracles team
 */
contract ProxyConnector is RedstoneConstants, CalldataExtractor {
  error ProxyCalldataFailedWithoutErrMsg();
  error ProxyCalldataFailedWithStringMessage(string message);
  error ProxyCalldataFailedWithCustomError(bytes result);

  function proxyCalldata(
    address contractAddress,
    bytes memory encodedFunction,
    bool forwardValue
  ) internal returns (bytes memory) {
    bytes memory message = _prepareMessage(encodedFunction);

    (bool success, bytes memory result) =
      contractAddress.call{value: forwardValue ? msg.value : 0}(message);

    return _prepareReturnValue(success, result);
  }

  function proxyDelegateCalldata(address contractAddress, bytes memory encodedFunction)
    internal
    returns (bytes memory)
  {
    bytes memory message = _prepareMessage(encodedFunction);
    (bool success, bytes memory result) = contractAddress.delegatecall(message);
    return _prepareReturnValue(success, result);
  }

  function proxyCalldataView(address contractAddress, bytes memory encodedFunction)
    internal
    view
    returns (bytes memory)
  {
    bytes memory message = _prepareMessage(encodedFunction);
    (bool success, bytes memory result) = contractAddress.staticcall(message);
    return _prepareReturnValue(success, result);
  }

  function _prepareMessage(bytes memory encodedFunction) private pure returns (bytes memory) {
    uint256 encodedFunctionBytesCount = encodedFunction.length;
    uint256 redstonePayloadByteSize = _getRedstonePayloadByteSize();
    uint256 resultMessageByteSize = encodedFunctionBytesCount + redstonePayloadByteSize;

    if (redstonePayloadByteSize > msg.data.length) {
      revert CalldataOverOrUnderFlow();
    }

    bytes memory message;

    assembly {
      message := mload(FREE_MEMORY_PTR) // sets message pointer to first free place in memory

      // Saving the byte size of the result message (it's a standard in EVM)
      mstore(message, resultMessageByteSize)

      // Copying function and its arguments
      for {
        let from := add(BYTES_ARR_LEN_VAR_BS, encodedFunction)
        let fromEnd := add(from, encodedFunctionBytesCount)
        let to := add(BYTES_ARR_LEN_VAR_BS, message)
      } lt (from, fromEnd) {
        from := add(from, STANDARD_SLOT_BS)
        to := add(to, STANDARD_SLOT_BS)
      } {
        // Copying data from encodedFunction to message (32 bytes at a time)
        mstore(to, mload(from))
      }

      // Copying redstone payload to the message bytes
      calldatacopy(
        add(message, add(BYTES_ARR_LEN_VAR_BS, encodedFunctionBytesCount)), // address
        sub(calldatasize(), redstonePayloadByteSize), // offset
        redstonePayloadByteSize // bytes length to copy
      )

      // Updating free memory pointer
      mstore(
        FREE_MEMORY_PTR,
        add(
          add(message, add(redstonePayloadByteSize, encodedFunctionBytesCount)),
          BYTES_ARR_LEN_VAR_BS
        )
      )
    }

    return message;
  }

  function _getRedstonePayloadByteSize() private pure returns (uint256) {
    uint256 calldataNegativeOffset = _extractByteSizeOfUnsignedMetadata();
    uint256 dataPackagesCount = _extractDataPackagesCountFromCalldata(calldataNegativeOffset);
    calldataNegativeOffset += DATA_PACKAGES_COUNT_BS;
    for (uint256 dataPackageIndex = 0; dataPackageIndex < dataPackagesCount; dataPackageIndex++) {
      uint256 dataPackageByteSize = _getDataPackageByteSize(calldataNegativeOffset);
      calldataNegativeOffset += dataPackageByteSize;
    }

    return calldataNegativeOffset;
  }

  function _getDataPackageByteSize(uint256 calldataNegativeOffset) private pure returns (uint256) {
    (
      uint256 dataPointsCount,
      uint256 eachDataPointValueByteSize
    ) = _extractDataPointsDetailsForDataPackage(calldataNegativeOffset);

    return
      dataPointsCount *
      (DATA_POINT_SYMBOL_BS + eachDataPointValueByteSize) +
      DATA_PACKAGE_WITHOUT_DATA_POINTS_BS;
  }


  function _prepareReturnValue(bool success, bytes memory result)
    internal
    pure
    returns (bytes memory)
  {
    if (!success) {

      if (result.length == 0) {
        revert ProxyCalldataFailedWithoutErrMsg();
      } else {
        bool isStringErrorMessage;
        assembly {
          let first32BytesOfResult := mload(add(result, BYTES_ARR_LEN_VAR_BS))
          isStringErrorMessage := eq(first32BytesOfResult, STRING_ERR_MESSAGE_MASK)
        }

        if (isStringErrorMessage) {
          string memory receivedErrMsg;
          assembly {
            receivedErrMsg := add(result, REVERT_MSG_OFFSET)
          }
          revert ProxyCalldataFailedWithStringMessage(receivedErrMsg);
        } else {
          revert ProxyCalldataFailedWithCustomError(result);
        }
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: ;
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "redstone-evm-connector/lib/contracts/message-based/PriceAware.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../oracle/RSOracleProd3Signers.sol";
import "../TokenManager.sol";
import "../Pool.sol";
import "../DiamondHelper.sol";
import "../interfaces/IStakingPositions.sol";

//This path is updated during deployment
import "../lib/avalanche/DeploymentConstants.sol";

contract SolvencyFacetProd is RSOracleProd3Signers, DiamondHelper {
    struct AssetPrice {
        bytes32 asset;
        uint256 price;
    }

    // Struct used in the liquidation process to obtain necessary prices only once
    struct CachedPrices {
        AssetPrice[] ownedAssetsPrices;
        AssetPrice[] debtAssetsPrices;
        AssetPrice[] stakedPositionsPrices;
        AssetPrice[] assetsToRepayPrices;
    }

    /**
      * Checks if the loan is solvent.
      * It means that the Health Ratio is greater than 1e18.
      * @dev This function uses the redstone-evm-connector
    **/
    function isSolvent() public view returns (bool) {
        return getHealthRatio() >= 1e18;
    }

    /**
      * Checks if the loan is solvent.
      * It means that the Health Ratio is greater than 1e18.
      * Uses provided AssetPrice struct arrays instead of extracting the pricing data from the calldata again.
      * @param ownedAssetsPrices An array of Asset/Price structs used to calculate weighted value of owned assets
      * @param debtAssetsPrices An array of Asset/Price structs used to calculate value of the debt
      * @param stakedPositionsPrices An array of Asset/Price structs used to calculate value of the staked positions
    **/
    function isSolventWithPrices(AssetPrice[] memory ownedAssetsPrices, AssetPrice[] memory debtAssetsPrices, AssetPrice[] memory stakedPositionsPrices) public view returns (bool) {
        return getHealthRatioWithPrices(ownedAssetsPrices, debtAssetsPrices, stakedPositionsPrices) >= 1e18;
    }

    /**
      * Returns an array of Asset/Price structs of staked positions.
      * @dev This function uses the redstone-evm-connector
    **/
    function getStakedPositionsPrices() public view returns(AssetPrice[] memory result) {
        IStakingPositions.StakedPosition[] storage positions = DiamondStorageLib.stakedPositions();

        bytes32[] memory symbols = new bytes32[](positions.length);
        for(uint256 i=0; i<positions.length; i++) {
            symbols[i] = positions[i].symbol;
        }

        uint256[] memory stakedPositionsPrices = getOracleNumericValuesWithDuplicatesFromTxMsg(symbols);
        result = new AssetPrice[](stakedPositionsPrices.length);

        for(uint i; i<stakedPositionsPrices.length; i++){
            result[i] = AssetPrice({
                asset: symbols[i],
                price: stakedPositionsPrices[i]
            });
        }
    }

    /**
      * Returns an array of bytes32[] symbols of debt (borrowable) assets.
    **/
    function getDebtAssets() public view returns(bytes32[] memory result) {
        TokenManager tokenManager = DeploymentConstants.getTokenManager();
        result = tokenManager.getAllPoolAssets();
    }

    /**
      * Returns an array of Asset/Price structs of debt (borrowable) assets.
      * @dev This function uses the redstone-evm-connector
    **/
    function getDebtAssetsPrices() public view returns(AssetPrice[] memory result) {
        bytes32[] memory debtAssets = getDebtAssets();

        uint256[] memory debtAssetsPrices = getOracleNumericValuesFromTxMsg(debtAssets);
        result = new AssetPrice[](debtAssetsPrices.length);

        for(uint i; i<debtAssetsPrices.length; i++){
            result[i] = AssetPrice({
                asset: debtAssets[i],
                price: debtAssetsPrices[i]
            });
        }
    }

    /**
      * Returns an array of Asset/Price structs of enriched (always containing AVAX at index 0) owned assets.
      * @dev This function uses the redstone-evm-connector
    **/
    function getOwnedAssetsPrices() public view returns(AssetPrice[] memory result) {
        bytes32[] memory assetsEnriched = getOwnedAssetsEnriched();
        uint256[] memory prices = getOracleNumericValuesFromTxMsg(assetsEnriched);

        result = new AssetPrice[](assetsEnriched.length);

        for(uint i; i<assetsEnriched.length; i++){
            result[i] = AssetPrice({
                asset: assetsEnriched[i],
                price: prices[i]
            });
        }
    }

    /**
      * Returns an array of bytes32[] symbols of staked positions.
    **/
    function getStakedAssets() internal view returns (bytes32[] memory result) {
        IStakingPositions.StakedPosition[] storage positions = DiamondStorageLib.stakedPositions();
        result = new bytes32[](positions.length);
        for(uint i; i<positions.length; i++) {
            result[i] = positions[i].symbol;
        }
    }

    /**
      * Returns CachedPrices struct consisting of Asset/Price arrays for ownedAssets, debtAssets, stakedPositions and assetsToRepay.
      * Used during the liquidation process in order to obtain all necessary prices from calldata only once.
      * @dev This function uses the redstone-evm-connector
    **/
    function getAllPricesForLiquidation(bytes32[] calldata assetsToRepay) public view returns (CachedPrices memory result) {
        bytes32[] memory ownedAssetsEnriched = getOwnedAssetsEnriched();
        bytes32[] memory debtAssets = getDebtAssets();
        bytes32[] memory stakedAssets = getStakedAssets();

        bytes32[] memory allAssetsSymbols = new bytes32[](ownedAssetsEnriched.length + debtAssets.length + stakedAssets.length + assetsToRepay.length);
        uint256 offset;

        // Populate allAssetsSymbols with owned assets symbols
        for(uint i; i<ownedAssetsEnriched.length; i++){
            allAssetsSymbols[i] = ownedAssetsEnriched[i];
        }
        offset += ownedAssetsEnriched.length;

        // Populate allAssetsSymbols with debt assets symbols
        for(uint i; i<debtAssets.length; i++){
            allAssetsSymbols[i+offset] = debtAssets[i];
        }
        offset += debtAssets.length;

        // Populate allAssetsSymbols with staked assets symbols
        for(uint i; i<stakedAssets.length; i++){
            allAssetsSymbols[i+offset] = stakedAssets[i];
        }
        offset += stakedAssets.length;

        // Populate allAssetsSymbols with assets to repay symbols
        for(uint i; i<assetsToRepay.length; i++){
            allAssetsSymbols[i+offset] = assetsToRepay[i];
        }

        uint256[] memory allAssetsPrices = getOracleNumericValuesWithDuplicatesFromTxMsg(allAssetsSymbols);

        offset = 0;

        // Populate ownedAssetsPrices struct
        AssetPrice[] memory ownedAssetsPrices = new AssetPrice[](ownedAssetsEnriched.length);
        for(uint i=0; i<ownedAssetsEnriched.length; i++){
            ownedAssetsPrices[i] = AssetPrice({
            asset: allAssetsSymbols[i+offset],
            price: allAssetsPrices[i+offset]
            });
        }
        offset += ownedAssetsEnriched.length;

        // Populate debtAssetsPrices struct
        AssetPrice[] memory debtAssetsPrices = new AssetPrice[](debtAssets.length);
        for(uint i=0; i<debtAssets.length; i++){
            debtAssetsPrices[i] = AssetPrice({
            asset: allAssetsSymbols[i+offset],
            price: allAssetsPrices[i+offset]
            });
        }
        offset += debtAssetsPrices.length;

        // Populate stakedPositionsPrices struct
        AssetPrice[] memory stakedPositionsPrices = new AssetPrice[](stakedAssets.length);
        for(uint i=0; i<stakedAssets.length; i++){
            stakedPositionsPrices[i] = AssetPrice({
            asset: allAssetsSymbols[i+offset],
            price: allAssetsPrices[i+offset]
            });
        }
        offset += stakedAssets.length;

        // Populate assetsToRepayPrices struct
        AssetPrice[] memory assetsToRepayPrices = new AssetPrice[](assetsToRepay.length);
        for(uint i=0; i<assetsToRepay.length; i++){
            assetsToRepayPrices[i] = AssetPrice({
            asset: allAssetsSymbols[i+offset],
            price: allAssetsPrices[i+offset]
            });
        }

        result = CachedPrices({
        ownedAssetsPrices: ownedAssetsPrices,
        debtAssetsPrices: debtAssetsPrices,
        stakedPositionsPrices: stakedPositionsPrices,
        assetsToRepayPrices: assetsToRepayPrices
        });
    }

    /**
      * Helper method exposing the redstone-evm-connector getOracleNumericValuesFromTxMsg() method.
      * @dev This function uses the redstone-evm-connector
    **/
    function getPrices(bytes32[] memory symbols) external view returns (uint256[] memory) {
        return getOracleNumericValuesFromTxMsg(symbols);
    }

    /**
      * Helper method exposing the redstone-evm-connector getOracleNumericValueFromTxMsg() method.
      * @dev This function uses the redstone-evm-connector
    **/
    function getPrice(bytes32 symbol) external view returns (uint256) {
        return getOracleNumericValueFromTxMsg(symbol);
    }

    /**
      * Returns TotalWeightedValue of OwnedAssets in USD based on the supplied array of Asset/Price struct, tokenBalance and maxTokenLeverage
    **/
    function _getTWVOwnedAssets(AssetPrice[] memory ownedAssetsPrices) internal view returns (uint256) {
        bytes32 nativeTokenSymbol = DeploymentConstants.getNativeTokenSymbol();
        TokenManager tokenManager = DeploymentConstants.getTokenManager();

        uint256 weightedValueOfTokens;

        if (ownedAssetsPrices.length > 0) {
            // TODO: double check the decimals
            weightedValueOfTokens = ownedAssetsPrices[0].price * address(this).balance * tokenManager.maxTokenLeverage(tokenManager.getAssetAddress(nativeTokenSymbol, true)) / (10 ** 26);

            for (uint256 i = 0; i < ownedAssetsPrices.length; i++) {
                IERC20Metadata token = IERC20Metadata(tokenManager.getAssetAddress(ownedAssetsPrices[i].asset, true));
                weightedValueOfTokens = weightedValueOfTokens + (ownedAssetsPrices[i].price * 10 ** 10 * token.balanceOf(address(this)) * tokenManager.maxTokenLeverage(address(token)) / (10 ** token.decimals() * 1e18));
            }
        }
        return weightedValueOfTokens;
    }

    /**
      * Returns TotalWeightedValue of StakedPositions in USD based on the supplied array of Asset/Price struct, positionBalance and maxTokenLeverage
    **/
    function _getTWVStakedPositions(AssetPrice[] memory stakedPositionsPrices) internal view returns (uint256) {
        TokenManager tokenManager = DeploymentConstants.getTokenManager();
        IStakingPositions.StakedPosition[] storage positions = DiamondStorageLib.stakedPositions();

        uint256 weightedValueOfStaked;

        for (uint256 i; i < positions.length; i++) {
            require(stakedPositionsPrices[i].asset == positions[i].symbol, "Position-price symbol mismatch.");

            (bool success, bytes memory result) = address(this).staticcall(abi.encodeWithSelector(positions[i].balanceSelector));

            if (success) {
                uint256 balance = abi.decode(result, (uint256));

                IERC20Metadata token = IERC20Metadata(DeploymentConstants.getTokenManager().getAssetAddress(stakedPositionsPrices[i].asset, true));

                weightedValueOfStaked += stakedPositionsPrices[i].price * 10 ** 10 * balance * tokenManager.maxTokenLeverage(positions[i].vault) / (10 ** token.decimals());
            }
        }
        return weightedValueOfStaked;
    }

    function _getThresholdWeightedValueBase(AssetPrice[] memory ownedAssetsPrices, AssetPrice[] memory stakedPositionsPrices) internal view virtual returns (uint256) {
        return _getTWVOwnedAssets(ownedAssetsPrices) + _getTWVStakedPositions(stakedPositionsPrices);
    }

    /**
      * Returns the threshold weighted value of assets in USD including all tokens as well as staking and LP positions
      * @dev This function uses the redstone-evm-connector
    **/
    function getThresholdWeightedValue() public view virtual returns (uint256) {
        AssetPrice[] memory ownedAssetsPrices = getOwnedAssetsPrices();
        AssetPrice[] memory stakedPositionsPrices = getStakedPositionsPrices();
        return _getThresholdWeightedValueBase(ownedAssetsPrices, stakedPositionsPrices);
    }

    /**
      * Returns the threshold weighted value of assets in USD including all tokens as well as staking and LP positions
      * Uses provided AssetPrice struct arrays instead of extracting the pricing data from the calldata again.
    **/
    function getThresholdWeightedValueWithPrices(AssetPrice[] memory ownedAssetsPrices, AssetPrice[] memory stakedPositionsPrices) public view virtual returns (uint256) {
        return _getThresholdWeightedValueBase(ownedAssetsPrices, stakedPositionsPrices);
    }


    /**
     * Returns the current debt from all lending pools
     * Uses provided AssetPrice struct array instead of extracting the pricing data from the calldata again.
    **/
    function getDebtBase(AssetPrice[] memory debtAssetsPrices) internal view returns (uint256){
        TokenManager tokenManager = DeploymentConstants.getTokenManager();
        uint256 debt;

        for (uint256 i; i < debtAssetsPrices.length; i++) {
            IERC20Metadata token = IERC20Metadata(tokenManager.getAssetAddress(debtAssetsPrices[i].asset, true));

            Pool pool = Pool(tokenManager.getPoolAddress(debtAssetsPrices[i].asset));
            //10**18 (wei in eth) / 10**8 (precision of oracle feed) = 10**10
            debt = debt + pool.getBorrowed(address(this)) * debtAssetsPrices[i].price * 10 ** 10
            / 10 ** token.decimals();
        }

        return debt;
    }

    /**
     * Returns the current debt from all lending pools
     * @dev This function uses the redstone-evm-connector
    **/
    function getDebt() public view virtual returns (uint256) {
        AssetPrice[] memory debtAssetsPrices = getDebtAssetsPrices();
        return getDebtBase(debtAssetsPrices);
    }

    /**
     * Returns the current debt from all lending pools
     * Uses provided AssetPrice struct array instead of extracting the pricing data from the calldata again.
    **/
    function getDebtWithPrices(AssetPrice[] memory debtAssetsPrices) public view virtual returns (uint256) {
        return getDebtBase(debtAssetsPrices);
    }


    /**
     * Returns the current value of Prime Account in USD including all tokens as well as staking and LP positions
     * Uses provided AssetPrice struct array instead of extracting the pricing data from the calldata again.
    **/
    function _getTotalAssetsValueBase(AssetPrice[] memory ownedAssetsPrices) public view returns (uint256) {
        if (ownedAssetsPrices.length > 0) {
            TokenManager tokenManager = DeploymentConstants.getTokenManager();

            uint256 total = address(this).balance * ownedAssetsPrices[0].price / 10 ** 8;

            for (uint256 i = 0; i < ownedAssetsPrices.length; i++) {
                IERC20Metadata token = IERC20Metadata(tokenManager.getAssetAddress(ownedAssetsPrices[i].asset, true));
                uint256 assetBalance = token.balanceOf(address(this));

                total = total + (ownedAssetsPrices[i].price * 10 ** 10 * assetBalance / (10 ** token.decimals()));
            }
            return total;
        } else {
            return 0;
        }
    }

    /**
     * Returns the current value of Prime Account in USD including all tokens as well as staking and LP positions
     * @dev This function uses the redstone-evm-connector
     **/
    function getTotalAssetsValue() public view virtual returns (uint256) {
        AssetPrice[] memory ownedAssetsPrices = getOwnedAssetsPrices();
        return _getTotalAssetsValueBase(ownedAssetsPrices);
    }

    /**
     * Returns the current value of Prime Account in USD including all tokens as well as staking and LP positions
     * Uses provided AssetPrice struct array instead of extracting the pricing data from the calldata again.
    **/
    function getTotalAssetsValueWithPrices(AssetPrice[] memory ownedAssetsPrices) public view virtual returns (uint256) {
        return _getTotalAssetsValueBase(ownedAssetsPrices);
    }

    /**
      * Returns list of owned assets that always included NativeToken at index 0
    **/
    function getOwnedAssetsEnriched() public view returns(bytes32[] memory){
        bytes32[] memory ownedAssets = DeploymentConstants.getAllOwnedAssets();
        bytes32 nativeTokenSymbol = DeploymentConstants.getNativeTokenSymbol();

        uint256 numberOfAssets = DiamondStorageLib.hasAsset(nativeTokenSymbol) ? ownedAssets.length : ownedAssets.length + 1;
        bytes32[] memory assetsEnriched = new bytes32[](numberOfAssets);

        uint256 lastUsedIndex;
        assetsEnriched[0] = nativeTokenSymbol; // First asset = NativeToken

        for(uint i=0; i< ownedAssets.length; i++){
            if(ownedAssets[i] != nativeTokenSymbol){
                lastUsedIndex += 1;
                assetsEnriched[lastUsedIndex] = ownedAssets[i];
            }
        }
        return assetsEnriched;
    }

    /**
     * Returns the current value of staked positions in USD.
     * Uses provided AssetPrice struct array instead of extracting the pricing data from the calldata again.
    **/
    function _getStakedValueBase(AssetPrice[] memory stakedPositionsPrices) internal view returns (uint256) {
        IStakingPositions.StakedPosition[] storage positions = DiamondStorageLib.stakedPositions();

        uint256 usdValue;

        for (uint256 i; i < positions.length; i++) {
            require(stakedPositionsPrices[i].asset == positions[i].symbol, "Position-price symbol mismatch.");

            (bool success, bytes memory result) = address(this).staticcall(abi.encodeWithSelector(positions[i].balanceSelector));

            if (success) {
                uint256 balance = abi.decode(result, (uint256));

                IERC20Metadata token = IERC20Metadata(DeploymentConstants.getTokenManager().getAssetAddress(stakedPositionsPrices[i].asset, true));

                usdValue += stakedPositionsPrices[i].price * 10 ** 10 * balance / (10 ** token.decimals());
            }
        }

        return usdValue;
    }

    /**
     * Returns the current value of staked positions in USD.
     * Uses provided AssetPrice struct array instead of extracting the pricing data from the calldata again.
    **/
    function getStakedValueWithPrices(AssetPrice[] memory stakedPositionsPrices) public view returns (uint256) {
        return _getStakedValueBase(stakedPositionsPrices);
    }

    /**
     * Returns the current value of staked positions in USD.
     * @dev This function uses the redstone-evm-connector
    **/
    function getStakedValue() public view virtual returns (uint256) {
        AssetPrice[] memory stakedPositionsPrices = getStakedPositionsPrices();
        return _getStakedValueBase(stakedPositionsPrices);
    }

    /**
     * Returns the current value of Prime Account in USD including all tokens as well as staking and LP positions
     * @dev This function uses the redstone-evm-connector
    **/
    function getTotalValue() public view virtual returns (uint256) {
        return getTotalAssetsValue() + getStakedValue();
    }

    /**
     * Returns the current value of Prime Account in USD including all tokens as well as staking and LP positions
     * Uses provided AssetPrice struct arrays instead of extracting the pricing data from the calldata again.
    **/
    function getTotalValueWithPrices(AssetPrice[] memory ownedAssetsPrices, AssetPrice[] memory stakedPositionsPrices) public view virtual returns (uint256) {
        return getTotalAssetsValueWithPrices(ownedAssetsPrices) + getStakedValueWithPrices(stakedPositionsPrices);
    }

    function getFullLoanStatus() public view returns (uint256[5] memory) {
        return [getTotalValue(), getDebt(), getThresholdWeightedValue(), getHealthRatio(), isSolvent() ? uint256(1) : uint256(0)];
    }

    /**
     * Returns current health ratio (solvency) associated with the loan, defined as threshold weighted value of divided
     * by current debt
     * @dev This function uses the redstone-evm-connector
     **/
    function getHealthRatio() public view virtual returns (uint256) {
        uint256 debt = getDebt();
        uint256 thresholdWeightedValue = getThresholdWeightedValue();

        if (debt == 0) {
            return type(uint256).max;
        } else {
            return thresholdWeightedValue * 1e18 / debt;
        }
    }

    /**
     * Returns current health ratio (solvency) associated with the loan, defined as threshold weighted value of divided
     * by current debt
     * Uses provided AssetPrice struct arrays instead of extracting the pricing data from the calldata again.
     **/
    function getHealthRatioWithPrices(AssetPrice[] memory ownedAssetsPrices, AssetPrice[] memory debtAssetsPrices, AssetPrice[] memory stakedPositionsPrices) public view virtual returns (uint256) {
        uint256 debt = getDebtWithPrices(debtAssetsPrices);
        uint256 thresholdWeightedValue = getThresholdWeightedValueWithPrices(ownedAssetsPrices, stakedPositionsPrices);

        if (debt == 0) {
            return type(uint256).max;
        } else {
            return thresholdWeightedValue * 1e18 / debt;
        }
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: 97d6cc3cb60bfd6feda4ea784b13bf0e7daac710;
pragma solidity 0.8.17;

import "./interfaces/IDiamondBeacon.sol";

//This path is updated during deployment
import "./lib/avalanche/DeploymentConstants.sol";

/**
 * DiamondHelper
 * Helper methods
 **/
contract DiamondHelper {
    function _getFacetAddress(bytes4 methodSelector) internal view returns (address solvencyFacetAddress) {
        solvencyFacetAddress = IDiamondBeacon(payable(DeploymentConstants.getDiamondAddress())).implementation(methodSelector);
    }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

/**
 * @title The base contract with helpful constants
 * @author The Redstone Oracles team
 * @dev It mainly contains redstone-related values, which improve readability
 * of other contracts (e.g. CalldataExtractor and RedstoneConsumerBase)
 */
contract RedstoneConstants {
  // === Abbreviations ===
  // BS - Bytes size
  // PTR - Pointer (memory location)
  // SIG - Signature

  // Solidity and YUL constants
  uint256 internal constant STANDARD_SLOT_BS = 32;
  uint256 internal constant FREE_MEMORY_PTR = 0x40;
  uint256 internal constant BYTES_ARR_LEN_VAR_BS = 32;
  uint256 internal constant FUNCTION_SIGNATURE_BS = 4;
  uint256 internal constant REVERT_MSG_OFFSET = 68; // Revert message structure described here: https://ethereum.stackexchange.com/a/66173/106364
  uint256 internal constant STRING_ERR_MESSAGE_MASK = 0x08c379a000000000000000000000000000000000000000000000000000000000;

  // RedStone protocol consts
  uint256 internal constant SIG_BS = 65;
  uint256 internal constant TIMESTAMP_BS = 6;
  uint256 internal constant DATA_PACKAGES_COUNT_BS = 2;
  uint256 internal constant DATA_POINTS_COUNT_BS = 3;
  uint256 internal constant DATA_POINT_VALUE_BYTE_SIZE_BS = 4;
  uint256 internal constant DATA_POINT_SYMBOL_BS = 32;
  uint256 internal constant DEFAULT_DATA_POINT_VALUE_BS = 32;
  uint256 internal constant UNSGINED_METADATA_BYTE_SIZE_BS = 3;
  uint256 internal constant REDSTONE_MARKER_BS = 9; // byte size of 0x000002ed57011e0000
  uint256 internal constant REDSTONE_MARKER_MASK = 0x0000000000000000000000000000000000000000000000000002ed57011e0000;

  // Derived values (based on consts)
  uint256 internal constant TIMESTAMP_NEGATIVE_OFFSET_IN_DATA_PACKAGE_WITH_STANDARD_SLOT_BS = 104; // SIG_BS + DATA_POINTS_COUNT_BS + DATA_POINT_VALUE_BYTE_SIZE_BS + STANDARD_SLOT_BS
  uint256 internal constant DATA_PACKAGE_WITHOUT_DATA_POINTS_BS = 78; // DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + DATA_POINTS_COUNT_BS + SIG_BS
  uint256 internal constant DATA_PACKAGE_WITHOUT_DATA_POINTS_AND_SIG_BS = 13; // DATA_POINT_VALUE_BYTE_SIZE_BS + TIMESTAMP_BS + DATA_POINTS_COUNT_BS
  uint256 internal constant REDSTONE_MARKER_BS_PLUS_STANDARD_SLOT_BS = 41; // REDSTONE_MARKER_BS + STANDARD_SLOT_BS

  // Error messages
  error CalldataOverOrUnderFlow();
  error IncorrectUnsignedMetadataSize();
  error InsufficientNumberOfUniqueSigners(uint256 receviedSignersCount, uint256 requiredSignersCount);
  error EachSignerMustProvideTheSameValue();
  error EmptyCalldataPointersArr();
  error InvalidCalldataPointer();
  error CalldataMustHaveValidPayload();
  error SignerNotAuthorised(address receivedSigner);
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./RedstoneConstants.sol";

/**
 * @title The base contract with the main logic of data extraction from calldata
 * @author The Redstone Oracles team
 * @dev This contract was created to reuse the same logic in the RedstoneConsumerBase
 * and the ProxyConnector contracts
 */
contract CalldataExtractor is RedstoneConstants {
  using SafeMath for uint256;

  function _extractByteSizeOfUnsignedMetadata() internal pure returns (uint256) {
    // Checking if the calldata ends with the RedStone marker
    bool hasValidRedstoneMarker;
    assembly {
      let calldataLast32Bytes := calldataload(sub(calldatasize(), STANDARD_SLOT_BS))
      hasValidRedstoneMarker := eq(
        REDSTONE_MARKER_MASK,
        and(calldataLast32Bytes, REDSTONE_MARKER_MASK)
      )
    }
    if (!hasValidRedstoneMarker) {
      revert CalldataMustHaveValidPayload();
    }

    // Using uint24, because unsigned metadata byte size number has 3 bytes
    uint24 unsignedMetadataByteSize;
    if (REDSTONE_MARKER_BS_PLUS_STANDARD_SLOT_BS > msg.data.length) {
      revert CalldataOverOrUnderFlow();
    }
    assembly {
      unsignedMetadataByteSize := calldataload(
        sub(calldatasize(), REDSTONE_MARKER_BS_PLUS_STANDARD_SLOT_BS)
      )
    }
    uint256 calldataNegativeOffset = unsignedMetadataByteSize
      + UNSGINED_METADATA_BYTE_SIZE_BS
      + REDSTONE_MARKER_BS;
    if (calldataNegativeOffset + DATA_PACKAGES_COUNT_BS > msg.data.length) {
      revert IncorrectUnsignedMetadataSize();
    }
    return calldataNegativeOffset;
  }

  // We return uint16, because unsigned metadata byte size number has 2 bytes
  function _extractDataPackagesCountFromCalldata(uint256 calldataNegativeOffset)
    internal
    pure
    returns (uint16 dataPackagesCount)
  {
    uint256 calldataNegativeOffsetWithStandardSlot = calldataNegativeOffset + STANDARD_SLOT_BS;
    if (calldataNegativeOffsetWithStandardSlot > msg.data.length) {
      revert CalldataOverOrUnderFlow();
    }
    assembly {
      dataPackagesCount := calldataload(
        sub(calldatasize(), calldataNegativeOffsetWithStandardSlot)
      )
    }
    return dataPackagesCount;
  }

  function _extractDataPointValueAndDataFeedId(
    uint256 calldataNegativeOffsetForDataPackage,
    uint256 defaultDataPointValueByteSize,
    uint256 dataPointIndex
  ) internal pure virtual returns (bytes32 dataPointDataFeedId, uint256 dataPointValue) {
    uint256 negativeOffsetToDataPoints = calldataNegativeOffsetForDataPackage + DATA_PACKAGE_WITHOUT_DATA_POINTS_BS;
    uint256 dataPointNegativeOffset = negativeOffsetToDataPoints.add(
      (1 + dataPointIndex).mul((defaultDataPointValueByteSize + DATA_POINT_SYMBOL_BS))
    );
    uint256 dataPointCalldataOffset = msg.data.length.sub(dataPointNegativeOffset);
    assembly {
      dataPointDataFeedId := calldataload(dataPointCalldataOffset)
      dataPointValue := calldataload(add(dataPointCalldataOffset, DATA_POINT_SYMBOL_BS))
    }
  }

  function _extractDataPointsDetailsForDataPackage(uint256 calldataNegativeOffsetForDataPackage)
    internal
    pure
    returns (uint256 dataPointsCount, uint256 eachDataPointValueByteSize)
  {
    // Using uint24, because data points count byte size number has 3 bytes
    uint24 dataPointsCount_;

    // Using uint32, because data point value byte size has 4 bytes
    uint32 eachDataPointValueByteSize_;

    // Extract data points count
    uint256 negativeCalldataOffset = calldataNegativeOffsetForDataPackage + SIG_BS;
    uint256 calldataOffset = msg.data.length.sub(negativeCalldataOffset + STANDARD_SLOT_BS);
    assembly {
      dataPointsCount_ := calldataload(calldataOffset)
    }

    // Extract each data point value size
    calldataOffset = calldataOffset.sub(DATA_POINTS_COUNT_BS);
    assembly {
      eachDataPointValueByteSize_ := calldataload(calldataOffset)
    }

    // Prepare returned values
    dataPointsCount = dataPointsCount_;
    eachDataPointValueByteSize = eachDataPointValueByteSize_;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract PriceAware {
  using ECDSA for bytes32;

  uint256 constant _MAX_DATA_TIMESTAMP_DELAY = 3 * 60; // 3 minutes
  uint256 constant _MAX_BLOCK_TIMESTAMP_DELAY = 15; // 15 seconds

  /* ========== VIRTUAL FUNCTIONS (MAY BE OVERRIDEN IN CHILD CONTRACTS) ========== */

  function getMaxDataTimestampDelay() public virtual view returns (uint256) {
    return _MAX_DATA_TIMESTAMP_DELAY;
  }

  function getMaxBlockTimestampDelay() public virtual view returns (uint256) {
    return _MAX_BLOCK_TIMESTAMP_DELAY;
  }

  function isSignerAuthorized(address _receviedSigner) public virtual view returns (bool);

  function isTimestampValid(uint256 _receivedTimestamp) public virtual view returns (bool) {
    // Getting data timestamp from future seems quite unlikely
    // But we've already spent too much time with different cases
    // Where block.timestamp was less than dataPackage.timestamp.
    // Some blockchains may case this problem as well.
    // That's why we add MAX_BLOCK_TIMESTAMP_DELAY
    // and allow data "from future" but with a small delay
    require(
      (block.timestamp + getMaxBlockTimestampDelay()) > _receivedTimestamp,
      "Data with future timestamps is not allowed");

    return block.timestamp < _receivedTimestamp
      || block.timestamp - _receivedTimestamp < getMaxDataTimestampDelay();
  }

  /* ========== FUNCTIONS WITH IMPLEMENTATION (CAN NOT BE OVERRIDEN) ========== */

  function getPriceFromMsg(bytes32 symbol) internal view returns (uint256) {bytes32[] memory symbols = new bytes32[](1); symbols[0] = symbol;
    return getPricesFromMsg(symbols)[0];
  }

  function getPricesFromMsg(bytes32[] memory symbols) internal view returns (uint256[] memory) {
    // The structure of calldata witn n - data items:
    // The data that is signed (symbols, values, timestamp) are inside the {} brackets
    // [origina_call_data| ?]{[[symbol | 32][value | 32] | n times][timestamp | 32]}[size | 1][signature | 65]

    // 1. First we extract dataSize - the number of data items (symbol,value pairs) in the message
    uint8 dataSize; //Number of data entries
    assembly {
      // Calldataload loads slots of 32 bytes
      // The last 65 bytes are for signature
      // We load the previous 32 bytes and automatically take the 2 least significant ones (casting to uint16)
      dataSize := calldataload(sub(calldatasize(), 97))
    }

    // 2. We calculate the size of signable message expressed in bytes
    // ((symbolLen(32) + valueLen(32)) * dataSize + timeStamp length
    uint16 messageLength = uint16(dataSize) * 64 + 32; //Length of data message in bytes

    // 3. We extract the signableMessage

    // (That's the high level equivalent 2k gas more expensive)
    // bytes memory rawData = msg.data.slice(msg.data.length - messageLength - 65, messageLength);

    bytes memory signableMessage;
    assembly {
      signableMessage := mload(0x40)
      mstore(signableMessage, messageLength)
      // The starting point is callDataSize minus length of data(messageLength), signature(65) and size(1) = 66
      calldatacopy(
        add(signableMessage, 0x20),
        sub(calldatasize(), add(messageLength, 66)),
        messageLength
      )
      mstore(0x40, add(signableMessage, 0x20))
    }

    // 4. We first hash the raw message and then hash it again with the prefix
    // Following the https://github.com/ethereum/eips/issues/191 standard
    bytes32 hash = keccak256(signableMessage);
    bytes32 hashWithPrefix = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)
    );

    // 5. We extract the off-chain signature from calldata

    // (That's the high level equivalent 2k gas more expensive)
    // bytes memory signature = msg.data.slice(msg.data.length - 65, 65);
    bytes memory signature;
    assembly {
      signature := mload(0x40)
      mstore(signature, 65)
      calldatacopy(add(signature, 0x20), sub(calldatasize(), 65), 65)
      mstore(0x40, add(signature, 0x20))
    }

    // 6. We verify the off-chain signature against on-chain hashed data

    address signer = hashWithPrefix.recover(signature);
    require(isSignerAuthorized(signer), "Signer not authorized");

    // 7. We extract timestamp from callData

    uint256 dataTimestamp;
    assembly {
      // Calldataload loads slots of 32 bytes
      // The last 65 bytes are for signature + 1 for data size
      // We load the previous 32 bytes
      dataTimestamp := calldataload(sub(calldatasize(), 98))
    }

    // 8. We validate timestamp
    require(isTimestampValid(dataTimestamp), "Data timestamp is invalid");

    return _readFromCallData(symbols, uint256(dataSize), messageLength);
  }

  function _readFromCallData(bytes32[] memory symbols, uint256 dataSize, uint16 messageLength) private pure returns (uint256[] memory) {
    uint256[] memory values;
    uint256 i;
    uint256 j;
    uint256 readyAssets;
    bytes32 currentSymbol;

    // We iterate directly through call data to extract the values for symbols
    assembly {
      let start := sub(calldatasize(), add(messageLength, 66))

      values := msize()
      mstore(values, mload(symbols))
      mstore(0x40, add(add(values, 0x20), mul(mload(symbols), 0x20)))

      for { i := 0 } lt(i, mload(symbols)) { i := add(i, 1) } {
        currentSymbol := mload(add(add(symbols, 32), mul(i, 32)))
        for { j := 0 } lt(j, dataSize) { j := add(j, 1) } {
          if eq(calldataload(add(start, mul(j, 64))), currentSymbol) {
            mstore(
              add(add(values, 32), mul(i, 32)),
              calldataload(add(add(start, mul(j, 64)), 32))
            )
            readyAssets := add(readyAssets, 1)
          }

          if eq(readyAssets, mload(symbols)) {
            i := dataSize
          }
        }
      }

    }

    return (values);
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

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: ;
pragma solidity 0.8.17;

import "@redstone-finance/evm-connector/contracts/data-services/AvalancheDataServiceConsumerBase.sol";

contract RSOracleProd3Signers is AvalancheDataServiceConsumerBase {
    function getUniqueSignersThreshold() public view virtual override returns (uint8) {
        return 3;
    }
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: f63ef97516096bbd3db42914b6554a461f90ef40;
pragma solidity 0.8.17;

import "./lib/Bytes32EnumerableMap.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract TokenManager {
    /**
     * For adding supported assets
     **/
    struct Asset {
        bytes32 asset;
        address assetAddress;
        uint256 maxLeverage;
    }

    /**
     * For adding supported lending pools
     **/
    struct poolAsset {
        bytes32 asset;
        address poolAddress;
    }
    using EnumerableMap for EnumerableMap.Bytes32ToAddressMap;

    uint256 private constant _NOT_SUPPORTED = 0;
    uint256 private constant _INACTIVE = 1;
    uint256 private constant _ACTIVE = 2;

    address public admin;
    // Stores an asset's bytes32 symbol representation to pool's address mapping
    EnumerableMap.Bytes32ToAddressMap private assetToPoolAddress;
    // Stores an asset's bytes32 symbol representation to asset's address mapping
    EnumerableMap.Bytes32ToAddressMap private assetToTokenAddress;
    mapping(address => bytes32) public tokenAddressToSymbol;
    mapping(address => uint256) private tokenPositionInList;
    // used for defining different leverage ratios for tokens
    mapping(address => uint256) public maxTokenLeverage;
    address[] public supportedTokensList;

    address public adminTransferProposal;

    mapping(address => uint256) public tokenToStatus;

    constructor(Asset[] memory tokenAssets, poolAsset[] memory poolAssets) {
        admin = msg.sender;
        emit AdminChanged(address(0), msg.sender, block.timestamp);
        addTokenAssets(tokenAssets);
        addPoolAssets(poolAssets);
    }

    // Set to address(0) to reset proposal
    function proposeAdminTransfer(address _newOwner) onlyAdmin public {
        require(_newOwner != msg.sender, "Can't propose oneself as a contract owner");
        adminTransferProposal = _newOwner;
        emit AdminProposed(msg.sender, _newOwner, block.timestamp);
    }

    function executeAdminTransfer() public {
        require(adminTransferProposal != address(0), "There is no active admin transfer proposal");
        require(adminTransferProposal == msg.sender, "Only the proposed new admin can execute admin transfer proposal");
        address oldAdmin = admin;
        admin = adminTransferProposal;
        adminTransferProposal = address(0);
        emit AdminChanged(oldAdmin, msg.sender, block.timestamp);
    }

    function getAllPoolAssets() public view returns (bytes32[] memory result) {
        return assetToPoolAddress._inner._keys._inner._values;
    }

    function getSupportedTokensAddresses() public view returns (address[] memory) {
        return supportedTokensList;
    }

    function getAllTokenAssets() public view returns (bytes32[] memory result) {
        return assetToTokenAddress._inner._keys._inner._values;
    }

    /**
    * Returns address of an asset
    **/
    function getAssetAddress(bytes32 _asset, bool allowInactive) public view returns (address) {
        (, address assetAddress) = assetToTokenAddress.tryGet(_asset);
        require(assetAddress != address(0), "Asset not supported.");
        if (!allowInactive) {
            require(tokenToStatus[assetAddress] == _ACTIVE, "Asset inactive");
        }

        return assetAddress;
    }

    /**
    * Returns address of an asset's lending pool
    **/
    function getPoolAddress(bytes32 _asset) public view returns (address) {
        (, address assetAddress) = assetToPoolAddress.tryGet(_asset);
        require(assetAddress != address(0), "Pool asset not supported.");

        return assetAddress;
    }

    function addPoolAssets(poolAsset[] memory poolAssets) public onlyAdmin {
        for (uint256 i = 0; i < poolAssets.length; i++) {
            _addPoolAsset(poolAssets[i].asset, poolAssets[i].poolAddress);
        }
    }

    function _addPoolAsset(bytes32 _asset, address _poolAddress) internal {
        require(Address.isContract(_poolAddress), "TokenManager: Pool must be a contract");
        require(!assetToPoolAddress.contains(_asset), "Asset's pool already exists");
        assetToPoolAddress.set(_asset, _poolAddress);
        emit PoolAssetAdded(msg.sender, _asset, _poolAddress, block.timestamp);
    }

    function addTokenAssets(Asset[] memory tokenAssets) public onlyAdmin {
        for (uint256 i = 0; i < tokenAssets.length; i++) {
            _addTokenAsset(tokenAssets[i].asset, tokenAssets[i].assetAddress, tokenAssets[i].maxLeverage);
        }
    }

    function activateToken(address token) public onlyAdmin {
        require(tokenToStatus[token] == _INACTIVE, "Must be inactive");
        tokenToStatus[token] = _ACTIVE;
        emit TokenAssetActivated(msg.sender, token, block.timestamp);
    }

    function deactivateToken(address token) public onlyAdmin {
        require(tokenToStatus[token] == _ACTIVE, "Must be active");
        tokenToStatus[token] = _INACTIVE;
        emit TokenAssetDeactivated(msg.sender, token, block.timestamp);
    }

    function _addTokenAsset(bytes32 _asset, address _tokenAddress, uint256 _maxLeverage) internal {
        require(_asset != "", "Cannot set an empty string asset.");
        require(_tokenAddress != address(0), "Cannot set an empty address.");
        require(!assetToTokenAddress.contains(_asset), "Asset's token already exists");
        setMaxTokenLeverage(_tokenAddress, _maxLeverage);

        assetToTokenAddress.set(_asset, _tokenAddress);
        tokenAddressToSymbol[_tokenAddress] = _asset;
        tokenToStatus[_tokenAddress] = _ACTIVE;

        supportedTokensList.push(_tokenAddress);
        tokenPositionInList[_tokenAddress] = supportedTokensList.length - 1;

        emit TokenAssetAdded(msg.sender, _asset, _tokenAddress, block.timestamp);
    }

    function _removeTokenFromList(address tokenToRemove) internal {
        // Move last address token to the `tokenToRemoveIndex` position (index of an asset that is being removed) in the address[] supportedTokensList
        // and update map(address=>uint256) tokenPostitionInList if the token is not already the last element
        uint256 tokenToRemoveIndex = tokenPositionInList[tokenToRemove];
        if (tokenToRemoveIndex != (supportedTokensList.length - 1)) {
            address currentLastToken = supportedTokensList[supportedTokensList.length - 1];
            tokenPositionInList[currentLastToken] = tokenToRemoveIndex;
            supportedTokensList[tokenToRemoveIndex] = currentLastToken;
        }
        // Remove last element - that is either the token that is being removed (if was already at the end)
        // or some other asset that at this point was already copied to the `index` positon
        supportedTokensList.pop();
        tokenPositionInList[tokenToRemove] = 0;
    }

    function removeTokenAssets(bytes32[] memory _tokenAssets) public onlyAdmin {
        for (uint256 i = 0; i < _tokenAssets.length; i++) {
            _removeTokenAsset(_tokenAssets[i]);
        }
    }

    function _removeTokenAsset(bytes32 _tokenAsset) internal {
        address tokenAddress = getAssetAddress(_tokenAsset, true);
        EnumerableMap.remove(assetToTokenAddress, _tokenAsset);
        tokenAddressToSymbol[tokenAddress] = 0;
        tokenToStatus[tokenAddress] = _NOT_SUPPORTED;
        maxTokenLeverage[tokenAddress] = 0;
        _removeTokenFromList(tokenAddress);
        emit TokenAssetRemoved(msg.sender, _tokenAsset, block.timestamp);
    }

    function removePoolAssets(bytes32[] memory _poolAssets) public onlyAdmin {
        for (uint256 i = 0; i < _poolAssets.length; i++) {
            _removePoolAsset(_poolAssets[i]);
        }
    }

    function _removePoolAsset(bytes32 _poolAsset) internal {
        address poolAddress = getPoolAddress(_poolAsset);
        EnumerableMap.remove(assetToPoolAddress, _poolAsset);
        emit PoolAssetRemoved(msg.sender, _poolAsset, poolAddress, block.timestamp);
    }

    function setMaxTokenLeverage(address token, uint256 maxLeverage) public onlyAdmin {
        //LTV must be lower than 5
        require(maxLeverage <= 0.833333333333333333e18, 'Leverage higher than maximum acceptable');
        maxTokenLeverage[token] = maxLeverage;
    }

    modifier onlyAdmin {
        require(msg.sender == admin, "Admin only");
        _;
    }

    /**
     * @dev emitted after proposing a new admin
     * @param oldAdmin current admin
     * @param newAdmin new admin proposed
     * @param timestamp time of proposal
     **/
    event AdminProposed(address indexed oldAdmin, address newAdmin, uint256 timestamp);

    /**
     * @dev emitted after changing an admin
     * @param oldAdmin previous admin
     * @param newAdmin new admin being set
     * @param timestamp time of changing an admin
     **/
    event AdminChanged(address indexed oldAdmin, address newAdmin, uint256 timestamp);

    /**
     * @dev emitted after adding a token asset
     * @param performer an address of the wallet adding a token asset
     * @param tokenAsset token asset
     * @param assetAddress an address of the token asset
     * @param timestamp time of adding a token asset
     **/
    event TokenAssetAdded(address indexed performer, bytes32 indexed tokenAsset, address assetAddress, uint256 timestamp);

    /**
     * @dev emitted after activating a token asset
     * @param performer an address of the wallet activating a token asset
     * @param assetAddress an address of the token asset
     * @param timestamp time of activating a token asset
     **/
    event TokenAssetActivated(address indexed performer, address assetAddress, uint256 timestamp);

    /**
     * @dev emitted after deactivating a token asset
     * @param performer an address of the wallet deactivating a token asset
     * @param assetAddress an address of the token asset
     * @param timestamp time of deactivating a token asset
     **/
    event TokenAssetDeactivated(address indexed performer, address assetAddress, uint256 timestamp);

    /**
     * @dev emitted after removing a token asset
     * @param performer an address of the wallet removing a token asset
     * @param tokenAsset token asset
     * @param timestamp time a token asset removal
     **/
    event TokenAssetRemoved(address indexed performer, bytes32 indexed tokenAsset, uint256 timestamp);

    /**
     * @dev emitted after adding a pool asset
     * @param performer an address of wallet adding the pool asset
     * @param poolAsset pool asset
     * @param poolAddress an address of the pool asset
     * @param timestamp time of the pool asset addition
     **/
    event PoolAssetAdded(address indexed performer, bytes32 indexed poolAsset, address poolAddress, uint256 timestamp);

    /**
     * @dev emitted after removing a pool asset
     * @param performer an address of wallet removing the pool asset
     * @param poolAsset pool asset
     * @param poolAddress an address of the pool asset
     * @param timestamp time of a pool asset removal
     **/
    event PoolAssetRemoved(address indexed performer, bytes32 indexed poolAsset, address poolAddress, uint256 timestamp);
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: 2e9f2aba0ab8e419a7d1bf6e83f967ae0bc9c538;
pragma solidity 0.8.17;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@uniswap/lib/contracts/libraries/TransferHelper.sol";
import "./interfaces/IIndex.sol";
import "./interfaces/IRatesCalculator.sol";
import "./interfaces/IBorrowersRegistry.sol";
import "./interfaces/IPoolRewarder.sol";


/**
 * @title Pool
 * @dev Contract allowing user to deposit to and borrow from a dedicated user account
 * Depositors are rewarded with the interest rates collected from borrowers.
 * The interest rates calculation is delegated to an external calculator contract.
 */
contract Pool is OwnableUpgradeable, ReentrancyGuardUpgradeable, IERC20 {
    using TransferHelper for address payable;

    uint256 public constant MAX_POOL_UTILISATION_FOR_BORROWING = 0.95e18;

    mapping(address => mapping(address => uint256)) private _allowed;
    mapping(address => uint256) internal _deposited;

    mapping(address => uint256) public borrowed;
    mapping(address => bool) public canDeposit;

    IRatesCalculator public ratesCalculator;
    IBorrowersRegistry public borrowersRegistry;
    IPoolRewarder public poolRewarder;

    IIndex public depositIndex;
    IIndex public borrowIndex;

    address payable public tokenAddress;

    function initialize(IRatesCalculator ratesCalculator_, IBorrowersRegistry borrowersRegistry_, IIndex depositIndex_, IIndex borrowIndex_, address payable tokenAddress_, IPoolRewarder poolRewarder_) public initializer {
        require(AddressUpgradeable.isContract(address(ratesCalculator_))
            && AddressUpgradeable.isContract(address(borrowersRegistry_))
            && AddressUpgradeable.isContract(address(depositIndex_))
            && AddressUpgradeable.isContract(address(borrowIndex_))
            && (AddressUpgradeable.isContract(address(poolRewarder_)) || address(poolRewarder_) == address(0)), "Wrong init arguments");

        borrowersRegistry = borrowersRegistry_;
        ratesCalculator = ratesCalculator_;
        depositIndex = depositIndex_;
        borrowIndex = borrowIndex_;
        poolRewarder = poolRewarder_;
        tokenAddress = tokenAddress_;

        __Ownable_init();
        __ReentrancyGuard_init();
        _updateRates();
    }

    /* ========== TEST-DEPLOYMENT ========== */

    /* ========== SETTERS ========== */
    function setAccess(address user, bool allowDeposit) external onlyOwner {
        canDeposit[user] = allowDeposit;
    }

    /**
     * Sets the new Pool Rewarder.
     * The IPoolRewarder that distributes additional token rewards to people having a stake in this pool proportionally to their stake and time of participance.
     * Only the owner of the Contract can execute this function.
     * @dev _poolRewarder the address of PoolRewarder
    **/
    function setPoolRewarder(IPoolRewarder _poolRewarder) external onlyOwner {
        require(AddressUpgradeable.isContract(address(_poolRewarder)) || address(_poolRewarder) == address(0), "Must be a contract");
        poolRewarder = _poolRewarder;

        emit PoolRewarderChanged(address(_poolRewarder), block.timestamp);
    }

    /**
     * Sets the new rate calculator.
     * The calculator is an external contract that contains the logic for calculating deposit and borrowing rates.
     * Only the owner of the Contract can execute this function.
     * @dev ratesCalculator the address of rates calculator
     **/
    function setRatesCalculator(IRatesCalculator ratesCalculator_) external onlyOwner {
        // setting address(0) ratesCalculator_ freezes the pool
        require(AddressUpgradeable.isContract(address(ratesCalculator_)) || address(ratesCalculator_) == address(0), "Must be a contract");
        ratesCalculator = ratesCalculator_;
        if (address(ratesCalculator_) != address(0)) {
            _updateRates();
        }

        emit RatesCalculatorChanged(address(ratesCalculator_), block.timestamp);
    }

    /**
     * Sets the new borrowers registry contract.
     * The borrowers registry decides if an account can borrow funds.
     * Only the owner of the Contract can execute this function.
     * @dev borrowersRegistry the address of borrowers registry
     **/
    function setBorrowersRegistry(IBorrowersRegistry borrowersRegistry_) external onlyOwner {
        require(AddressUpgradeable.isContract(address(borrowersRegistry_)), "Must be a contract");

        borrowersRegistry = borrowersRegistry_;
        emit BorrowersRegistryChanged(address(borrowersRegistry_), block.timestamp);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        require(recipient != address(0), "ERC20: cannot transfer to the zero address");
        require(recipient != address(this), "ERC20: cannot transfer to the pool address");

        _accumulateDepositInterest(msg.sender);

        require(_deposited[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");

        // (this is verified in "require" above)
        unchecked {
            _deposited[msg.sender] -= amount;
        }

        _accumulateDepositInterest(recipient);
        _deposited[recipient] += amount;

        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowed[owner][spender];
    }

//    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
//        require(spender != address(0), "Spender cannot be a zero address");
//        uint256 newAllowance = _allowed[msg.sender][spender] + addedValue;
//        _allowed[msg.sender][spender] = newAllowance;
//
//        emit Approval(msg.sender, spender, newAllowance);
//        return true;
//    }
//
//    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
//        require(spender != address(0), "Spender cannot be a zero address");
//        uint256 currentAllowance = _allowed[msg.sender][spender];
//        require(currentAllowance >= subtractedValue, "Current allowance is too small");
//
//        uint256 newAllowance = currentAllowance - subtractedValue;
//        _allowed[msg.sender][spender] = newAllowance;
//
//        emit Approval(msg.sender, spender, newAllowance);
//        return true;
//    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        require(spender != address(0), "Spender cannot be a zero address");
        _allowed[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        require(_allowed[sender][msg.sender] >= amount, "Not enough tokens allowed");
        require(recipient != address(0), "ERC20: cannot transfer to the zero address");
        require(recipient != address(this), "ERC20: cannot transfer to the pool address");

        _accumulateDepositInterest(sender);

        require(_deposited[sender] >= amount, "ERC20: transfer amount exceeds balance");

        _deposited[sender] -= amount;
        _allowed[sender][msg.sender] -= amount;

        _accumulateDepositInterest(recipient);
        _deposited[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        return true;
    }


    /**
     * Deposits the amount
     * It updates user deposited balance, total deposited and rates
     **/
    function deposit(uint256 _amount) public virtual nonReentrant {
        require(canDeposit[msg.sender], "User not permitted to create a loan");

        require(_amount>0, "Deposit amount must be > 0");
        _accumulateDepositInterest(msg.sender);

        _transferToPool(msg.sender, _amount);

        _mint(msg.sender, _amount);
        _deposited[address(this)] += _amount;
        _updateRates();

        if (address(poolRewarder) != address(0)) {
            poolRewarder.stakeFor(_amount, msg.sender);
        }

        emit Deposit(msg.sender, _amount, block.timestamp);
    }

    function _transferToPool(address from, uint256 amount) internal virtual {
        tokenAddress.safeTransferFrom(from, address(this), amount);
    }

    function _transferFromPool(address to, uint256 amount) internal virtual {
        tokenAddress.safeTransfer(to, amount);
    }

    /**
     * Withdraws selected amount from the user deposits
     * @dev _amount the amount to be withdrawn
     **/
    function withdraw(uint256 _amount) external nonReentrant {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= _amount, "Not enough funds in the pool");

        _accumulateDepositInterest(msg.sender);

        _burn(msg.sender, _amount);

        _transferFromPool(msg.sender, _amount);

        _updateRates();

        if (address(poolRewarder) != address(0)) {
            poolRewarder.withdrawFor(_amount, msg.sender);
        }

        emit Withdrawal(msg.sender, _amount, block.timestamp);
    }

    /**
     * Borrows the specified amount
     * It updates user borrowed balance, total borrowed amount and rates
     * @dev _amount the amount to be borrowed
     * @dev It is only meant to be used by a SmartLoanDiamondProxy
     **/
    function borrow(uint256 _amount) public virtual canBorrow nonReentrant {
        require(IERC20(tokenAddress).balanceOf(address(this)) >= _amount, "Not enough funds in the pool");

        _accumulateBorrowingInterest(msg.sender);

        borrowed[msg.sender] += _amount;
        borrowed[address(this)] += _amount;

        _transferFromPool(msg.sender, _amount);

        _updateRates();

        emit Borrowing(msg.sender, _amount, block.timestamp);
    }

    /**
     * Repays the amount
     * It updates user borrowed balance, total borrowed amount and rates
     * @dev It is only meant to be used by a SmartLoanDiamondProxy
     **/
    function repay(uint256 amount) external nonReentrant {
        _accumulateBorrowingInterest(msg.sender);

        require(borrowed[msg.sender] >= amount, "Trying to repay more than was borrowed");
        _transferToPool(msg.sender, amount);

        borrowed[msg.sender] -= amount;
        borrowed[address(this)] -= amount;

        _updateRates();

        emit Repayment(msg.sender, amount, block.timestamp);
    }

    /* =========


    /**
     * Returns the current borrowed amount for the given user
     * The value includes the interest rates owned at the current moment
     * @dev _user the address of queried borrower
    **/
    function getBorrowed(address _user) public view returns (uint256) {
        return borrowIndex.getIndexedValue(borrowed[_user], _user);
    }

    function totalSupply() public view override returns (uint256) {
        return balanceOf(address(this));
    }

    function totalBorrowed() public view returns (uint256) {
        return getBorrowed(address(this));
    }


    // Calls the IPoolRewarder.getRewardsFor() that sends pending rewards to msg.sender
    function getRewards() external {
        poolRewarder.getRewardsFor(msg.sender);
    }

    // Returns number of pending rewards for msg.sender
    function checkRewards() external view returns (uint256) {
        return poolRewarder.earned(msg.sender);
    }

    /**
     * Returns the current deposited amount for the given user
     * The value includes the interest rates earned at the current moment
     * @dev _user the address of queried depositor
     **/
    function balanceOf(address user) public view override returns (uint256) {
        return depositIndex.getIndexedValue(_deposited[user], user);
    }

    /**
     * Returns the current interest rate for deposits
     **/
    function getDepositRate() public view returns (uint256) {
        return ratesCalculator.calculateDepositRate(totalBorrowed(), totalSupply());
    }

    /**
     * Returns the current interest rate for borrowings
     **/
    function getBorrowingRate() public view returns (uint256) {
        return ratesCalculator.calculateBorrowingRate(totalBorrowed(), totalSupply());
    }

    /**
     * Recovers the surplus funds resultant from difference between deposit and borrowing rates
     **/
    function recoverSurplus(uint256 amount, address account) public onlyOwner nonReentrant {
        uint256 balance = IERC20(tokenAddress).balanceOf(address(this));
        uint256 surplus = balance + totalBorrowed() - totalSupply();

        require(amount <= balance, "Trying to recover more than pool balance");
        require(amount <= surplus, "Trying to recover more than current surplus");

        _transferFromPool(account, amount);
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "ERC20: cannot mint to the zero address");

        _deposited[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(_deposited[account] >= amount, "ERC20: burn amount exceeds user balance");
        require(_deposited[address(this)] >= amount, "ERC20: burn amount exceeds current pool indexed balance");

        // verified in "require" above
        unchecked {
            _deposited[account] -= amount;
            _deposited[address(this)] -= amount;
        }

        emit Transfer(account, address(0), amount);
    }

    function _updateRates() internal {
        uint256 _totalBorrowed = totalBorrowed();
        uint256 _totalSupply = totalSupply();
        require(address(ratesCalculator) != address(0), "Pool is frozen");
        depositIndex.setRate(ratesCalculator.calculateDepositRate(_totalBorrowed, _totalSupply));
        borrowIndex.setRate(ratesCalculator.calculateBorrowingRate(_totalBorrowed, _totalSupply));
    }

    function _accumulateDepositInterest(address user) internal {
        uint256 interest = balanceOf(user) - _deposited[user];

        _mint(user, interest);
        _deposited[address(this)] = balanceOf(address(this));

        emit InterestCollected(user, interest, block.timestamp);

        depositIndex.updateUser(user);
        depositIndex.updateUser(address(this));
    }

    function _accumulateBorrowingInterest(address user) internal {
        borrowed[user] = getBorrowed(user);
        borrowed[address(this)] = getBorrowed(address(this));

        borrowIndex.updateUser(user);
        borrowIndex.updateUser(address(this));
    }

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    function renounceOwnership() public virtual override {}

    /* ========== MODIFIERS ========== */

    modifier canBorrow() {
        require(address(borrowersRegistry) != address(0), "Borrowers registry not configured");
        require(borrowersRegistry.canBorrow(msg.sender), "Only authorized accounts may borrow");
        require(totalSupply() != 0, "Cannot borrow from an empty pool");
        _;
        require((totalBorrowed() * 1e18) / totalSupply() <= MAX_POOL_UTILISATION_FOR_BORROWING, "The pool utilisation cannot be greater than 95%");
    }

    /* ========== EVENTS ========== */

    /**
     * @dev emitted after the user deposits funds
     * @param user the address performing the deposit
     * @param value the amount deposited
     * @param timestamp of the deposit
     **/
    event Deposit(address indexed user, uint256 value, uint256 timestamp);

    /**
     * @dev emitted after the user withdraws funds
     * @param user the address performing the withdrawal
     * @param value the amount withdrawn
     * @param timestamp of the withdrawal
     **/
    event Withdrawal(address indexed user, uint256 value, uint256 timestamp);

    /**
     * @dev emitted after the user borrows funds
     * @param user the address that borrows
     * @param value the amount borrowed
     * @param timestamp time of the borrowing
     **/
    event Borrowing(address indexed user, uint256 value, uint256 timestamp);

    /**
     * @dev emitted after the user repays debt
     * @param user the address that repays debt
     * @param value the amount repaid
     * @param timestamp of the repayment
     **/
    event Repayment(address indexed user, uint256 value, uint256 timestamp);

    /**
     * @dev emitted after accumulating deposit interest
     * @param user the address that the deposit interest is accumulated for
     * @param value the amount that interest is calculated from
     * @param timestamp of the interest accumulation
     **/
    event InterestCollected(address indexed user, uint256 value, uint256 timestamp);

    /**
    * @dev emitted after changing borrowers registry
    * @param registry an address of the newly set borrowers registry
    * @param timestamp of the borrowers registry change
    **/
    event BorrowersRegistryChanged(address indexed registry, uint256 timestamp);

    /**
    * @dev emitted after changing rates calculator
    * @param calculator an address of the newly set rates calculator
    * @param timestamp of the borrowers registry change
    **/
    event RatesCalculatorChanged(address indexed calculator, uint256 timestamp);

    /**
    * @dev emitted after changing pool rewarder
    * @param poolRewarder an address of the newly set pool rewarder
    * @param timestamp of the pool rewarder change
    **/
    event PoolRewarderChanged(address indexed poolRewarder, uint256 timestamp);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "../core/RedstoneConsumerNumericBase.sol";

contract AvalancheDataServiceConsumerBase is RedstoneConsumerNumericBase {
  function getUniqueSignersThreshold() public view virtual override returns (uint8) {
    return 10;
  }

  function getAuthorisedSignerIndex(address signerAddress)
    public
    view
    virtual
    override
    returns (uint8)
  {
    if (signerAddress == 0x981bdA8276ae93F567922497153de7A5683708d3) {
      return 0;
    } else if (signerAddress == 0x3BEFDd935b50F172e696A5187DBaCfEf0D208e48) {
      return 1;
    } else if (signerAddress == 0xc1D5b940659e57b7bDF8870CDfC43f41Ca699460) {
      return 2;
    } else if (signerAddress == 0x1Cd8F9627a2838a7DAE6b98CF71c08B9CbF5174a) {
      return 3;
    } else if (signerAddress == 0xbC5a06815ee80dE7d20071703C1F1B8fC511c7d4) {
      return 4;
    } else if (signerAddress == 0xe9Fa2869C5f6fC3A0933981825564FD90573A86D) {
      return 5;
    } else if (signerAddress == 0xDf6b1cA313beE470D0142279791Fa760ABF5C537) {
      return 6;
    } else if (signerAddress == 0xa50abc5D76dAb99d5fe59FD32f239Bd37d55025f) {
      return 7;
    } else if (signerAddress == 0x496f4E8aC11076350A59b88D2ad62bc20d410EA3) {
      return 8;
    } else if (signerAddress == 0x41FB6b8d0f586E73d575bC57CFD29142B3214A47) {
      return 9;
    } else if (signerAddress == 0xC1068312a6333e6601f937c4773065B70D38A5bF) {
      return 10;
    } else if (signerAddress == 0xAE9D49Ea64DF38B9fcbC238bc7004a1421f7eeE8) {
      return 11;
    } else {
      revert SignerNotAuthorised(signerAddress);
    }
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "./RedstoneConsumerBase.sol";

/**
 * @title The base contract for Redstone consumers' contracts that allows to
 * securely calculate numeric redstone oracle values
 * @author The Redstone Oracles team
 * @dev This contract can extend other contracts to allow them
 * securely fetch Redstone oracle data from transactions calldata
 */
abstract contract RedstoneConsumerNumericBase is RedstoneConsumerBase {
  /**
   * @dev This function can be used in a consumer contract to securely extract an
   * oracle value for a given data feed id. Security is achieved by
   * signatures verification, timestamp validation, and aggregating values
   * from different authorised signers into a single numeric value. If any of the
   * required conditions do not match, the function will revert.
   * Note! This function expects that tx calldata contains redstone payload in the end
   * Learn more about redstone payload here: https://github.com/redstone-finance/redstone-oracles-monorepo/tree/main/packages/evm-connector#readme
   * @param dataFeedId bytes32 value that uniquely identifies the data feed
   * @return Extracted and verified numeric oracle value for the given data feed id
   */
  function getOracleNumericValueFromTxMsg(bytes32 dataFeedId)
    internal
    view
    virtual
    returns (uint256)
  {
    bytes32[] memory dataFeedIds = new bytes32[](1);
    dataFeedIds[0] = dataFeedId;
    return getOracleNumericValuesFromTxMsg(dataFeedIds)[0];
  }

  /**
   * @dev This function can be used in a consumer contract to securely extract several
   * numeric oracle values for a given array of data feed ids. Security is achieved by
   * signatures verification, timestamp validation, and aggregating values
   * from different authorised signers into a single numeric value. If any of the
   * required conditions do not match, the function will revert.
   * Note! This function expects that tx calldata contains redstone payload in the end
   * Learn more about redstone payload here: https://github.com/redstone-finance/redstone-oracles-monorepo/tree/main/packages/evm-connector#readme
   * @param dataFeedIds An array of unique data feed identifiers
   * @return An array of the extracted and verified oracle values in the same order
   * as they are requested in the dataFeedIds array
   */
  function getOracleNumericValuesFromTxMsg(bytes32[] memory dataFeedIds)
    internal
    view
    virtual
    returns (uint256[] memory)
  {
    return _securelyExtractOracleValuesFromTxMsg(dataFeedIds);
  }

  /**
   * @dev This function works similarly to the `getOracleNumericValuesFromTxMsg` with the
   * only difference that it allows to request oracle data for an array of data feeds
   * that may contain duplicates
   * 
   * @param dataFeedIdsWithDuplicates An array of data feed identifiers (duplicates are allowed)
   * @return An array of the extracted and verified oracle values in the same order
   * as they are requested in the dataFeedIdsWithDuplicates array
   */
  function getOracleNumericValuesWithDuplicatesFromTxMsg(bytes32[] memory dataFeedIdsWithDuplicates) internal view returns (uint256[] memory) {
    // Building an array without duplicates
    bytes32[] memory dataFeedIdsWithoutDuplicates = new bytes32[](dataFeedIdsWithDuplicates.length);
    bool alreadyIncluded;
    uint256 uniqueDataFeedIdsCount = 0;

    for (uint256 indexWithDup = 0; indexWithDup < dataFeedIdsWithDuplicates.length; indexWithDup++) {
      // Checking if current element is already included in `dataFeedIdsWithoutDuplicates`
      alreadyIncluded = false;
      for (uint256 indexWithoutDup = 0; indexWithoutDup < dataFeedIdsWithoutDuplicates.length; indexWithoutDup++) {
        if (dataFeedIdsWithoutDuplicates[indexWithoutDup] == dataFeedIdsWithDuplicates[indexWithDup]) {
          alreadyIncluded = true;
          break;
        }
      }

      // Adding if not included
      if (!alreadyIncluded) {
        dataFeedIdsWithoutDuplicates[uniqueDataFeedIdsCount] = dataFeedIdsWithDuplicates[indexWithDup];
        uniqueDataFeedIdsCount++;
      }
    }

    // Overriding dataFeedIdsWithoutDuplicates.length
    // Equivalent to: dataFeedIdsWithoutDuplicates.length = uniqueDataFeedIdsCount;
    assembly {
      mstore(dataFeedIdsWithoutDuplicates, uniqueDataFeedIdsCount)
    }

    // Requesting oracle values (without duplicates)
    uint256[] memory valuesWithoutDuplicates = getOracleNumericValuesFromTxMsg(dataFeedIdsWithoutDuplicates);

    // Preparing result values array
    uint256[] memory valuesWithDuplicates = new uint256[](dataFeedIdsWithDuplicates.length);
    for (uint256 indexWithDup = 0; indexWithDup < dataFeedIdsWithDuplicates.length; indexWithDup++) {
      for (uint256 indexWithoutDup = 0; indexWithoutDup < dataFeedIdsWithoutDuplicates.length; indexWithoutDup++) {
        if (dataFeedIdsWithDuplicates[indexWithDup] == dataFeedIdsWithoutDuplicates[indexWithoutDup]) {
          valuesWithDuplicates[indexWithDup] = valuesWithoutDuplicates[indexWithoutDup];
          break;
        }
      }
    }

    return valuesWithDuplicates;
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "./RedstoneConstants.sol";
import "./RedstoneDefaultsLib.sol";
import "./CalldataExtractor.sol";
import "../libs/BitmapLib.sol";
import "../libs/SignatureLib.sol";

/**
 * @title The base contract with the main Redstone logic
 * @author The Redstone Oracles team
 * @dev Do not use this contract directly in consumer contracts, take a
 * look at `RedstoneConsumerNumericBase` and `RedstoneConsumerBytesBase` instead
 */
abstract contract RedstoneConsumerBase is CalldataExtractor {
  using SafeMath for uint256;

  /* ========== VIRTUAL FUNCTIONS (MAY BE OVERRIDEN IN CHILD CONTRACTS) ========== */

  /**
   * @dev This function must be implemented by the child consumer contract.
   * It should return a unique index for a given signer address if the signer
   * is authorised, otherwise it should revert
   * @param receviedSigner The address of a signer, recovered from ECDSA signature
   * @return Unique index for a signer in the range [0..255]
   */
  function getAuthorisedSignerIndex(address receviedSigner) public view virtual returns (uint8);

  /**
   * @dev This function may be overriden by the child consumer contract.
   * It should validate the timestamp against the current time (block.timestamp)
   * It should revert with a helpful message if the timestamp is not valid
   * @param receivedTimestampMilliseconds Timestamp extracted from calldata
   */
  function validateTimestamp(uint256 receivedTimestampMilliseconds) public view virtual {
    RedstoneDefaultsLib.validateTimestamp(receivedTimestampMilliseconds);
  }

  /**
   * @dev This function should be overriden by the child consumer contract.
   * @return The minimum required value of unique authorised signers
   */
  function getUniqueSignersThreshold() public view virtual returns (uint8) {
    return 1;
  }

  /**
   * @dev This function may be overriden by the child consumer contract.
   * It should aggregate values from different signers to a single uint value.
   * By default, it calculates the median value
   * @param values An array of uint256 values from different signers
   * @return Result of the aggregation in the form of a single number
   */
  function aggregateValues(uint256[] memory values) public view virtual returns (uint256) {
    return RedstoneDefaultsLib.aggregateValues(values);
  }

  /* ========== FUNCTIONS WITH IMPLEMENTATION (CAN NOT BE OVERRIDEN) ========== */

  /**
   * @dev This is an internal helpful function for secure extraction oracle values
   * from the tx calldata. Security is achieved by signatures verification, timestamp
   * validation, and aggregating values from different authorised signers into a
   * single numeric value. If any of the required conditions (e.g. too old timestamp or
   * insufficient number of autorised signers) do not match, the function will revert.
   *
   * Note! You should not call this function in a consumer contract. You can use
   * `getOracleNumericValuesFromTxMsg` or `getOracleNumericValueFromTxMsg` instead.
   *
   * @param dataFeedIds An array of unique data feed identifiers
   * @return An array of the extracted and verified oracle values in the same order
   * as they are requested in dataFeedIds array
   */
  function _securelyExtractOracleValuesFromTxMsg(bytes32[] memory dataFeedIds)
    internal
    view
    returns (uint256[] memory)
  {
    // Initializing helpful variables and allocating memory
    uint256[] memory uniqueSignerCountForDataFeedIds = new uint256[](dataFeedIds.length);
    uint256[] memory signersBitmapForDataFeedIds = new uint256[](dataFeedIds.length);
    uint256[][] memory valuesForDataFeeds = new uint256[][](dataFeedIds.length);
    for (uint256 i = 0; i < dataFeedIds.length; i++) {
      // The line below is commented because newly allocated arrays are filled with zeros
      // But we left it for better readability
      // signersBitmapForDataFeedIds[i] = 0; // <- setting to an empty bitmap
      valuesForDataFeeds[i] = new uint256[](getUniqueSignersThreshold());
    }

    // Extracting the number of data packages from calldata
    uint256 calldataNegativeOffset = _extractByteSizeOfUnsignedMetadata();
    uint256 dataPackagesCount = _extractDataPackagesCountFromCalldata(calldataNegativeOffset);
    calldataNegativeOffset += DATA_PACKAGES_COUNT_BS;

    // Saving current free memory pointer
    uint256 freeMemPtr;
    assembly {
      freeMemPtr := mload(FREE_MEMORY_PTR)
    }

    // Data packages extraction in a loop
    for (uint256 dataPackageIndex = 0; dataPackageIndex < dataPackagesCount; dataPackageIndex++) {
      // Extract data package details and update calldata offset
      uint256 dataPackageByteSize = _extractDataPackage(
        dataFeedIds,
        uniqueSignerCountForDataFeedIds,
        signersBitmapForDataFeedIds,
        valuesForDataFeeds,
        calldataNegativeOffset
      );
      calldataNegativeOffset += dataPackageByteSize;

      // Shifting memory pointer back to the "safe" value
      assembly {
        mstore(FREE_MEMORY_PTR, freeMemPtr)
      }
    }

    // Validating numbers of unique signers and calculating aggregated values for each dataFeedId
    return _getAggregatedValues(valuesForDataFeeds, uniqueSignerCountForDataFeedIds);
  }

  /**
   * @dev This is a private helpful function, which extracts data for a data package based
   * on the given negative calldata offset, verifies them, and in the case of successful
   * verification updates the corresponding data package values in memory
   *
   * @param dataFeedIds an array of unique data feed identifiers
   * @param uniqueSignerCountForDataFeedIds an array with the numbers of unique signers
   * for each data feed
   * @param signersBitmapForDataFeedIds an array of sginers bitmaps for data feeds
   * @param valuesForDataFeeds 2-dimensional array, valuesForDataFeeds[i][j] contains
   * j-th value for the i-th data feed
   * @param calldataNegativeOffset negative calldata offset for the given data package
   *
   * @return An array of the aggregated values
   */
  function _extractDataPackage(
    bytes32[] memory dataFeedIds,
    uint256[] memory uniqueSignerCountForDataFeedIds,
    uint256[] memory signersBitmapForDataFeedIds,
    uint256[][] memory valuesForDataFeeds,
    uint256 calldataNegativeOffset
  ) private view returns (uint256) {
    uint256 signerIndex;

    (
      uint256 dataPointsCount,
      uint256 eachDataPointValueByteSize
    ) = _extractDataPointsDetailsForDataPackage(calldataNegativeOffset);

    // We use scopes to resolve problem with too deep stack
    {
      uint48 extractedTimestamp;
      address signerAddress;
      bytes32 signedHash;
      bytes memory signedMessage;
      uint256 signedMessageBytesCount;

      signedMessageBytesCount = dataPointsCount.mul(eachDataPointValueByteSize + DATA_POINT_SYMBOL_BS)
        + DATA_PACKAGE_WITHOUT_DATA_POINTS_AND_SIG_BS;

      uint256 timestampCalldataOffset = msg.data.length.sub(
        calldataNegativeOffset + TIMESTAMP_NEGATIVE_OFFSET_IN_DATA_PACKAGE_WITH_STANDARD_SLOT_BS);

      uint256 signedMessageCalldataOffset = msg.data.length.sub(
        calldataNegativeOffset + SIG_BS + signedMessageBytesCount);

      assembly {
        // Extracting the signed message
        signedMessage := extractBytesFromCalldata(
          signedMessageCalldataOffset,
          signedMessageBytesCount
        )

        // Hashing the signed message
        signedHash := keccak256(add(signedMessage, BYTES_ARR_LEN_VAR_BS), signedMessageBytesCount)

        // Extracting timestamp
        extractedTimestamp := calldataload(timestampCalldataOffset)

        function initByteArray(bytesCount) -> ptr {
          ptr := mload(FREE_MEMORY_PTR)
          mstore(ptr, bytesCount)
          ptr := add(ptr, BYTES_ARR_LEN_VAR_BS)
          mstore(FREE_MEMORY_PTR, add(ptr, bytesCount))
        }

        function extractBytesFromCalldata(offset, bytesCount) -> extractedBytes {
          let extractedBytesStartPtr := initByteArray(bytesCount)
          calldatacopy(
            extractedBytesStartPtr,
            offset,
            bytesCount
          )
          extractedBytes := sub(extractedBytesStartPtr, BYTES_ARR_LEN_VAR_BS)
        }
      }

      // Validating timestamp
      validateTimestamp(extractedTimestamp);

      // Verifying the off-chain signature against on-chain hashed data
      signerAddress = SignatureLib.recoverSignerAddress(
        signedHash,
        calldataNegativeOffset + SIG_BS
      );
      signerIndex = getAuthorisedSignerIndex(signerAddress);
    }

    // Updating helpful arrays
    {
      bytes32 dataPointDataFeedId;
      uint256 dataPointValue;
      for (uint256 dataPointIndex = 0; dataPointIndex < dataPointsCount; dataPointIndex++) {
        // Extracting data feed id and value for the current data point
        (dataPointDataFeedId, dataPointValue) = _extractDataPointValueAndDataFeedId(
          calldataNegativeOffset,
          eachDataPointValueByteSize,
          dataPointIndex
        );

        for (
          uint256 dataFeedIdIndex = 0;
          dataFeedIdIndex < dataFeedIds.length;
          dataFeedIdIndex++
        ) {
          if (dataPointDataFeedId == dataFeedIds[dataFeedIdIndex]) {
            uint256 bitmapSignersForDataFeedId = signersBitmapForDataFeedIds[dataFeedIdIndex];

            if (
              !BitmapLib.getBitFromBitmap(bitmapSignersForDataFeedId, signerIndex) && /* current signer was not counted for current dataFeedId */
              uniqueSignerCountForDataFeedIds[dataFeedIdIndex] < getUniqueSignersThreshold()
            ) {
              // Increase unique signer counter
              uniqueSignerCountForDataFeedIds[dataFeedIdIndex]++;

              // Add new value
              valuesForDataFeeds[dataFeedIdIndex][
                uniqueSignerCountForDataFeedIds[dataFeedIdIndex] - 1
              ] = dataPointValue;

              // Update signers bitmap
              signersBitmapForDataFeedIds[dataFeedIdIndex] = BitmapLib.setBitInBitmap(
                bitmapSignersForDataFeedId,
                signerIndex
              );
            }

            // Breaking, as there couldn't be several indexes for the same feed ID
            break;
          }
        }
      }
    }

    // Return total data package byte size
    return
      DATA_PACKAGE_WITHOUT_DATA_POINTS_BS +
      (eachDataPointValueByteSize + DATA_POINT_SYMBOL_BS) *
      dataPointsCount;
  }

  /**
   * @dev This is a private helpful function, which aggregates values from different
   * authorised signers for the given arrays of values for each data feed
   *
   * @param valuesForDataFeeds 2-dimensional array, valuesForDataFeeds[i][j] contains
   * j-th value for the i-th data feed
   * @param uniqueSignerCountForDataFeedIds an array with the numbers of unique signers
   * for each data feed
   *
   * @return An array of the aggregated values
   */
  function _getAggregatedValues(
    uint256[][] memory valuesForDataFeeds,
    uint256[] memory uniqueSignerCountForDataFeedIds
  ) private view returns (uint256[] memory) {
    uint256[] memory aggregatedValues = new uint256[](valuesForDataFeeds.length);
    uint256 uniqueSignersThreshold = getUniqueSignersThreshold();

    for (uint256 dataFeedIndex = 0; dataFeedIndex < valuesForDataFeeds.length; dataFeedIndex++) {
      if (uniqueSignerCountForDataFeedIds[dataFeedIndex] < uniqueSignersThreshold) {
        revert InsufficientNumberOfUniqueSigners(
          uniqueSignerCountForDataFeedIds[dataFeedIndex],
          uniqueSignersThreshold);
      }
      uint256 aggregatedValueForDataFeedId = aggregateValues(valuesForDataFeeds[dataFeedIndex]);
      aggregatedValues[dataFeedIndex] = aggregatedValueForDataFeedId;
    }

    return aggregatedValues;
  }
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity ^0.8.4;

import "../libs/NumericArrayLib.sol";

/**
 * @title Default implementations of virtual redstone consumer base functions
 * @author The Redstone Oracles team
 */
library RedstoneDefaultsLib {
  uint256 constant DEFAULT_MAX_DATA_TIMESTAMP_DELAY_SECONDS = 3 minutes;
  uint256 constant DEFAULT_MAX_DATA_TIMESTAMP_AHEAD_SECONDS = 1 minutes;

  error TimestampFromTooLongFuture(uint256 receivedTimestampSeconds, uint256 blockTimestamp);
  error TimestampIsTooOld(uint256 receivedTimestampSeconds, uint256 blockTimestamp);

  function validateTimestamp(uint256 receivedTimestampMilliseconds) internal view {
    // Getting data timestamp from future seems quite unlikely
    // But we've already spent too much time with different cases
    // Where block.timestamp was less than dataPackage.timestamp.
    // Some blockchains may case this problem as well.
    // That's why we add MAX_BLOCK_TIMESTAMP_DELAY
    // and allow data "from future" but with a small delay
//    uint256 receivedTimestampSeconds = receivedTimestampMilliseconds / 1000;
//    bool isFromFuture = block.timestamp < receivedTimestampSeconds;
//
//    if ((block.timestamp + DEFAULT_MAX_DATA_TIMESTAMP_AHEAD_SECONDS) < receivedTimestampSeconds) {
//      revert TimestampFromTooLongFuture(receivedTimestampSeconds, block.timestamp);
//    }
//    if (!isFromFuture && (block.timestamp - receivedTimestampSeconds) > DEFAULT_MAX_DATA_TIMESTAMP_DELAY_SECONDS) {
//      revert TimestampIsTooOld(receivedTimestampSeconds, block.timestamp);
//    }
  }

  function aggregateValues(uint256[] memory values) internal pure returns (uint256) {
    return NumericArrayLib.pickMedian(values);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library BitmapLib {
  function setBitInBitmap(uint256 bitmap, uint256 bitIndex) internal pure returns (uint256) {
    return bitmap | (1 << bitIndex);
  }

  function getBitFromBitmap(uint256 bitmap, uint256 bitIndex) internal pure returns (bool) {
    uint256 bitAtIndex = bitmap & (1 << bitIndex);
    return bitAtIndex > 0;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

library SignatureLib {
  uint256 constant ECDSA_SIG_R_BS = 32;
  uint256 constant ECDSA_SIG_S_BS = 32;

  function recoverSignerAddress(bytes32 signedHash, uint256 signatureCalldataNegativeOffset)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      let signatureCalldataStartPos := sub(calldatasize(), signatureCalldataNegativeOffset)
      r := calldataload(signatureCalldataStartPos)
      signatureCalldataStartPos := add(signatureCalldataStartPos, ECDSA_SIG_R_BS)
      s := calldataload(signatureCalldataStartPos)
      signatureCalldataStartPos := add(signatureCalldataStartPos, ECDSA_SIG_S_BS)
      v := byte(0, calldataload(signatureCalldataStartPos)) // last byte of the signature memory array
    }
    return ecrecover(signedHash, v, r, s);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library NumericArrayLib {
  // This function sort array in memory using bubble sort algorithm,
  // which performs even better than quick sort for small arrays

  uint256 constant BYTES_ARR_LEN_VAR_BS = 32;
  uint256 constant UINT256_VALUE_BS = 32;

  error CanNotPickMedianOfEmptyArray();

  // This function modifies the array
  function pickMedian(uint256[] memory arr) internal pure returns (uint256) {
    if (arr.length == 0) {
      revert CanNotPickMedianOfEmptyArray();
    }
    sort(arr);
    uint256 middleIndex = arr.length / 2;
    if (arr.length % 2 == 0) {
      uint256 sum = SafeMath.add(arr[middleIndex - 1], arr[middleIndex]);
      return sum / 2;
    } else {
      return arr[middleIndex];
    }
  }

  function sort(uint256[] memory arr) internal pure {
    assembly {
      let arrLength := mload(arr)
      let valuesPtr := add(arr, BYTES_ARR_LEN_VAR_BS)
      let endPtr := add(valuesPtr, mul(arrLength, UINT256_VALUE_BS))
      for {
        let arrIPtr := valuesPtr
      } lt(arrIPtr, endPtr) {
        arrIPtr := add(arrIPtr, UINT256_VALUE_BS) // arrIPtr += 32
      } {
        for {
          let arrJPtr := valuesPtr
        } lt(arrJPtr, arrIPtr) {
          arrJPtr := add(arrJPtr, UINT256_VALUE_BS) // arrJPtr += 32
        } {
          let arrI := mload(arrIPtr)
          let arrJ := mload(arrJPtr)
          if lt(arrI, arrJ) {
            mstore(arrIPtr, arrJ)
            mstore(arrJPtr, arrI)
          }
        }
      }
    }
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: c5c938a0524b45376dd482cd5c8fb83fa94c2fcc;
pragma solidity 0.8.17;

interface IIndex {

    function setRate(uint256 _rate) external;

    function updateUser(address user) external;

    function getIndex() external view returns (uint256);

    function getIndexedValue(uint256 value, address user) external view returns (uint256);

}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: ;
pragma solidity 0.8.17;

/**
 * @title IRatesCalculator
 * @dev Interface defining base method for contracts implementing interest rates calculation.
 * The calculated value could be based on the relation between funds borrowed and deposited.
 */
interface IRatesCalculator {
    function calculateBorrowingRate(uint256 totalLoans, uint256 totalDeposits) external view returns (uint256);

    function calculateDepositRate(uint256 totalLoans, uint256 totalDeposits) external view returns (uint256);
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: ;
pragma solidity 0.8.17;

/**
 * @title IBorrowersRegistry
 * Keeps a registry of created trading accounts to verify their borrowing rights
 */
interface IBorrowersRegistry {
    function canBorrow(address _account) external view returns (bool);

    function getLoanForOwner(address _owner) external view returns (address);

    function getOwnerOfLoan(address _loan) external view returns (address);
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: ;
pragma solidity ^0.8.17;

interface IPoolRewarder {

    function stakeFor(uint _amount, address _stakeFor) external;

    function withdrawFor(uint _amount, address _unstakeFor) external;

    function getRewardsFor(address _user) external;

    function earned(address _account) external view returns (uint);

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: BUSL-1.1
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity 0.8.17;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IDiamondBeacon {

    function implementation() external view returns (address);

    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {SmartLoanDiamondProxy} will check that this address is a contract.
     */
    function implementation(bytes4) external view returns (address);

    function getStatus() external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
// Last deployed from commit: f63ef97516096bbd3db42914b6554a461f90ef40;
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract RedstoneConfigManager is Ownable {
    mapping(address => bool) internal signerAuthorized;
    address[] public trustedSigners;

    constructor(address[] memory _trustedSigners) {
        for (uint256 i = 0; i < _trustedSigners.length; i++) {
            require(!signerExists(_trustedSigners[i]), "Signer already exists");
            _addTrustedSigner(_trustedSigners[i]);
        }
    }

    function getTrustedSigners() external view returns (address[] memory) {
        return trustedSigners;
    }

    function signerExists(address signer) public view returns (bool) {
        return signerAuthorized[signer];
    }

    function addTrustedSigners(address[] memory _trustedSigners) public onlyOwner {
        for (uint256 i = 0; i < _trustedSigners.length; i++) {
            require(!signerExists(_trustedSigners[i]), "Signer already exists");
            _addTrustedSigner(_trustedSigners[i]);
            emit SignerAdded(msg.sender, _trustedSigners[i], block.timestamp);
        }
    }

    function _addTrustedSigner(address newSigner) private {
        signerAuthorized[newSigner] = true;
        trustedSigners.push(newSigner);
    }

    function removeTrustedSigners(address[] memory _trustedSigners) public onlyOwner {
        for (uint256 i = 0; i < _trustedSigners.length; i++) {
            require(signerExists(_trustedSigners[i]), "Signer does not exists");
            _removeTrustedSigner(_trustedSigners[i]);
            emit SignerRemoved(msg.sender, _trustedSigners[i], block.timestamp);
        }
    }

    function _removeTrustedSigner(address signerToRemove) private {
        // Signer is no longer authorized
        signerAuthorized[signerToRemove] = false;

        // Remove signerToRemove from the trustedSigners list
        for (uint256 i = 0; i < trustedSigners.length; i++) {
            // Lookup signerToRemove position in the trustedSigners list
            if (trustedSigners[i] == signerToRemove) {
                // If signerToRemove is not at the last place in the list, copy last list's element to it's place
                if (i != trustedSigners.length - 1) {
                    trustedSigners[i] = trustedSigners[trustedSigners.length - 1];
                }
                // Remove last list's element
                trustedSigners.pop();
            }
        }
    }

    /* ========== OVERRIDDEN FUNCTIONS ========== */

    function renounceOwnership() public virtual override {}

    // EVENTS
    /**
    * @dev emitted after adding a signer
    * @param user performing the transaction
    * @param signer address of added signer
    * @param timestamp of change
    **/
    event SignerAdded(address indexed user, address signer, uint256 timestamp);

    /**
    * @dev emitted after removing a signer
    * @param user performing the transaction
    * @param signer address of removed signer
    * @param timestamp of change
    **/
    event SignerRemoved(address indexed user, address signer, uint256 timestamp);
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