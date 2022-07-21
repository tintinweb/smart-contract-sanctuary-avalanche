// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./libs/Price.sol";

interface IRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);

    function getAmountsOut(uint amountIn, address[] memory path) external view returns (uint[] memory amounts);
}

interface IL2Vault is IERC20Upgradeable {
    function deposit(uint amount) external;
    function withdraw(uint share) external;
    function getAllPoolInUSD() external view returns (uint);
    function getAPR() external view returns (uint);
}

contract MWIStrategy is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IERC20Upgradeable public constant USDT = IERC20Upgradeable(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    IERC20Upgradeable public constant WBTC = IERC20Upgradeable(0x50b7545627a5162F82A992c33b87aDc75187B218);
    IERC20Upgradeable public constant WETH = IERC20Upgradeable(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB);
    IERC20Upgradeable public constant WAVAX = IERC20Upgradeable(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20Upgradeable public constant USDt = IERC20Upgradeable(0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7);

    IRouter public constant JoeRouter = IRouter(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);

    uint constant POOL_COUNT = 4;
    IL2Vault public WBTCVault;
    IL2Vault public WETHVault;
    IL2Vault public WAVAXVault;
    IL2Vault public USDTVault;
    
    uint constant DENOMINATOR = 10000;
    uint[] public targetPercentages;

    address public vault;

    event TargetComposition (uint WBTCTargetPool, uint WETHTargetPool, uint WAVAXTargetPool, uint USDTTargetPool);
    event CurrentComposition (uint WBTCTargetPool, uint WETHTargetPool, uint WAVAXCurrentPool, uint USDTCurrentPool);
    event InvestWBTC(uint USDTAmt, uint WBTCAmt);
    event InvestWETH(uint USDTAmt, uint WETHAmt);
    event InvestWAVAX(uint USDTAmt, uint WAVAXAmt);
    event InvestUSDT(uint USDTAmt, uint USDtAmt);
    event Withdraw(uint sharePerc, uint USDTAmt);
    event WithdrawWBTC(uint WBTCAmt, uint USDTAmt);
    event WithdrawWETH(uint WETHAmt, uint USDTAmt);
    event WithdrawWAVAX(uint WAVAXAmt, uint USDTAmt);
    event WithdrawUSDT(uint USDtAmt, uint USDTAmt);
    event EmergencyWithdraw(uint USDTAmt);

    modifier onlyVault {
        require(msg.sender == vault, "Only vault");
        _;
    }

    function initialize(IL2Vault _WBTCVault, IL2Vault _WETHVault, IL2Vault _WAVAXVault, IL2Vault _USDTVault) external initializer {
        __Ownable_init();

        targetPercentages.push(4500); // WBTC: 45%
        targetPercentages.push(3500); // WETH: 35%
        targetPercentages.push(1500); // WAVAX: 15%
        targetPercentages.push(500); // USDT: 5%

        WBTCVault = _WBTCVault;
        WETHVault = _WETHVault;
        WAVAXVault = _WAVAXVault;
        USDTVault = _USDTVault;

        USDT.safeApprove(address(JoeRouter), type(uint).max);
        WBTC.safeApprove(address(JoeRouter), type(uint).max);
        WETH.safeApprove(address(JoeRouter), type(uint).max);
        WAVAX.safeApprove(address(JoeRouter), type(uint).max);
        USDt.safeApprove(address(JoeRouter), type(uint).max);

        WBTC.safeApprove(address(WBTCVault), type(uint).max);
        WETH.safeApprove(address(WETHVault), type(uint).max);
        WAVAX.safeApprove(address(WAVAXVault), type(uint).max);
        USDt.safeApprove(address(USDTVault), type(uint).max);
    }

    function invest(uint USDTAmt) external onlyVault {
        USDT.safeTransferFrom(vault, address(this), USDTAmt);
        USDTAmt = USDT.balanceOf(address(this));
        uint USDTPriceInUSD = PriceLib.getAssetPrice(address(USDT));

        uint[] memory pools = getEachPoolInUSD();
        uint allPool = pools[0] + pools[1] + pools[2] + pools[3] + (USDTAmt * USDTPriceInUSD * 1e4); // USDT's decimals is 6

        uint totalAllocation;
        uint[] memory allocations = new uint[](POOL_COUNT);
        for (uint i = 0; i < POOL_COUNT; i ++) {
            uint target = allPool * targetPercentages[i] / DENOMINATOR;
            if (pools[i] < target) {
                uint diff = target - pools[i];
                allocations[i] = diff;
                totalAllocation += diff;
            }
        }

        uint[] memory USDTAmts = new uint[](POOL_COUNT);
        for (uint i = 0; i < POOL_COUNT; i ++) {
            USDTAmts[i] = USDTAmt * allocations[i] / totalAllocation;
        }

        if (USDTAmts[0] > 0) {
            _investWBTC(USDTAmts[0], USDTPriceInUSD);
        }
        if (USDTAmts[1] > 0) {
            _investWETH(USDTAmts[1], USDTPriceInUSD);
        }
        if (USDTAmts[2] > 0) {
            _investWAVAX(USDTAmts[2], USDTPriceInUSD);
        }
        if (USDTAmts[3] > 0) {
            _investUSDT(USDTAmts[3]);
        }

        emit CurrentComposition(pools[0], pools[1], pools[2], pools[3]);
        emit TargetComposition(targetPercentages[0], targetPercentages[1], targetPercentages[2], targetPercentages[3]);
    }

    function _investWBTC(uint USDTAmt, uint USDTPriceInUSD) private {
        uint WBTCPriceInUSD = PriceLib.getAssetPrice(address(WBTC));
        uint amountOut = USDTAmt * USDTPriceInUSD * 100 / WBTCPriceInUSD;  // USDT's decimals is 6, WBTC's decimals is 8
        uint WBTCAmt = _swap2(address(USDT), address(WBTC), USDTAmt, amountOut*95/100);
        WBTCVault.deposit(WBTCAmt);
        emit InvestWBTC(USDTAmt, WBTCAmt);
    }

    function _investWETH(uint USDTAmt, uint USDTPriceInUSD) private {
        uint WETHPriceInUSD = PriceLib.getAssetPrice(address(WETH));
        uint amountOut = USDTAmt * USDTPriceInUSD * 1e12 / WETHPriceInUSD;  // USDT's decimals is 6, WETH's decimals is 18
        uint WETHAmt = _swap2(address(USDT), address(WETH), USDTAmt, amountOut*95/100);
        WETHVault.deposit(WETHAmt);
        emit InvestWETH(USDTAmt, WETHAmt);
    }

    function _investWAVAX(uint USDTAmt, uint USDTPriceInUSD) private {
        uint WAVAXPriceInUSD = PriceLib.getAssetPrice(address(WAVAX));
        uint amountOut = USDTAmt * USDTPriceInUSD * 1e12 / WAVAXPriceInUSD;  // USDT's decimals is 6, WAVAX's decimals is 18
        uint WAVAXAmt = _swap(address(USDT), address(WAVAX), USDTAmt, amountOut*95/100);
        WAVAXVault.deposit(WAVAXAmt);
        emit InvestWAVAX(USDTAmt, WAVAXAmt);
    }

    function _investUSDT(uint USDTAmt) private {
        uint USDtAmt = _swap(address(USDT), address(USDt), USDTAmt, USDTAmt*99/100);
        USDTVault.deposit(USDtAmt);
        emit InvestUSDT(USDTAmt, USDtAmt);
    }

    function withdrawPerc(uint sharePerc) external onlyVault returns (uint USDTAmt) {
        require(sharePerc <= 1e18, "Over 100%");
        
        uint USDTAmtBefore = USDT.balanceOf(address(this));
        uint USDTPriceInUSD = PriceLib.getAssetPrice(address(USDT));

        _withdrawWBTC(sharePerc, USDTPriceInUSD);
        _withdrawWETH(sharePerc, USDTPriceInUSD);
        _withdrawWAVAX(sharePerc, USDTPriceInUSD);
        _withdrawUSDT(sharePerc);

        USDTAmt = USDT.balanceOf(address(this)) - USDTAmtBefore;
        USDT.safeTransfer(vault, USDTAmt);
        emit Withdraw(sharePerc, USDTAmt);
    }

    function _withdrawWBTC(uint _sharePerc, uint USDTPriceInUSD) private {
        uint amount = WBTCVault.balanceOf(address(this)) * _sharePerc / 1e18;
        if (0 < amount) {
            WBTCVault.withdraw(amount);

            uint WBTCAmt = WBTC.balanceOf(address(this));
            uint WBTCPriceInUSD = PriceLib.getAssetPrice(address(WBTC));
            uint amountOut = WBTCAmt * WBTCPriceInUSD / (USDTPriceInUSD * 100);  // USDT's decimals is 6, WBTC's decimals is 8
            uint USDTAmt = _swap2(address(WBTC), address(USDT), WBTCAmt, amountOut*95/100);
            emit WithdrawWBTC(WBTCAmt, USDTAmt);
        }
    }

    function _withdrawWETH(uint _sharePerc, uint USDTPriceInUSD) private {
        uint amount = WETHVault.balanceOf(address(this)) * _sharePerc / 1e18;
        if (0 < amount) {
            WETHVault.withdraw(amount);

            uint WETHAmt = WETH.balanceOf(address(this));
            uint WETHPriceInUSD = PriceLib.getAssetPrice(address(WETH));
            uint amountOut = WETHAmt * WETHPriceInUSD / (USDTPriceInUSD * 1e12);  // USDT's decimals is 6, WETH's decimals is 18
            uint USDTAmt = _swap2(address(WETH), address(USDT), WETHAmt, amountOut*95/100);
            emit WithdrawWETH(WETHAmt, USDTAmt);
        }
    }

    function _withdrawWAVAX(uint _sharePerc, uint USDTPriceInUSD) private {
        uint amount = WAVAXVault.balanceOf(address(this)) * _sharePerc / 1e18;
        if (0 < amount) {
            WAVAXVault.withdraw(amount);

            uint WAVAXAmt = WAVAX.balanceOf(address(this));
            uint WAVAXPriceInUSD = PriceLib.getAssetPrice(address(WAVAX));
            uint amountOut = WAVAXAmt * WAVAXPriceInUSD / (USDTPriceInUSD * 1e12);  // USDT's decimals is 6, WAVAX's decimals is 18
            uint USDTAmt = _swap(address(WAVAX), address(USDT), WAVAXAmt, amountOut*95/100);
            emit WithdrawWAVAX(WAVAXAmt, USDTAmt);
        }
    }

    function _withdrawUSDT(uint _sharePerc) private {
        uint amount = USDTVault.balanceOf(address(this)) * _sharePerc / 1e18;
        if (0 < amount) {
            USDTVault.withdraw(amount);

            uint USDtAmt = USDt.balanceOf(address(this));
            uint USDTAmt = _swap(address(USDt), address(USDT), USDtAmt, USDtAmt*99/100);
            emit WithdrawUSDT(USDtAmt, USDTAmt);
        }
    }

    function _swap(address _tokenA, address _tokenB, uint _amt, uint _minAmount) private returns (uint) {
        address[] memory path = new address[](2);
        path[0] = _tokenA;
        path[1] = _tokenB;
        return (JoeRouter.swapExactTokensForTokens(_amt , _minAmount, path, address(this), block.timestamp))[1];
    }

    function _swap2(address _tokenA, address _tokenB, uint _amt, uint _minAmount) private returns (uint) {
        address[] memory path = new address[](3);
        path[0] = _tokenA;
        path[1] = address(WAVAX);
        path[2] = _tokenB;
        return (JoeRouter.swapExactTokensForTokens(_amt , _minAmount, path, address(this), block.timestamp))[2];
    }

    function withdrawFromFarm(uint farmIndex, uint sharePerc) external onlyVault returns (uint USDTAmt) {
        require(sharePerc <= 1e18, "Over 100%");
        uint USDTPriceInUSD = PriceLib.getAssetPrice(address(USDT));

        if (farmIndex == 0) _withdrawWBTC(sharePerc, USDTPriceInUSD);
        else if (farmIndex == 1) _withdrawWETH(sharePerc, USDTPriceInUSD);
        else if (farmIndex == 2) _withdrawWAVAX(sharePerc, USDTPriceInUSD);
        else if (farmIndex == 3) _withdrawUSDT(sharePerc);

        USDTAmt = USDT.balanceOf(address(this));
        USDT.safeTransfer(vault, USDTAmt);
    }

    function emergencyWithdraw() external onlyVault {
        // 1e18 == 100% of share
        uint USDTPriceInUSD = PriceLib.getAssetPrice(address(USDT));

        _withdrawWBTC(1e18, USDTPriceInUSD);
        _withdrawWETH(1e18, USDTPriceInUSD);
        _withdrawWAVAX(1e18, USDTPriceInUSD);
        _withdrawUSDT(1e18);

        uint USDTAmt = USDT.balanceOf(address(this));
        if (0 < USDTAmt) {
            USDT.safeTransfer(vault, USDTAmt);
        }
        emit EmergencyWithdraw(USDTAmt);
    }

    function setVault(address _vault) external onlyOwner {
        require(vault == address(0), "Vault set");
        vault = _vault;
    }

    function setL2Vault(IL2Vault _WBTCVault, IL2Vault _WETHVault, IL2Vault _WAVAXVault, IL2Vault _USDTVault) external onlyOwner {
        WBTCVault = _WBTCVault;
        WETHVault = _WETHVault;
        WAVAXVault = _WAVAXVault;
        USDTVault = _USDTVault;
        WBTC.safeApprove(address(WBTCVault), type(uint).max);
        WETH.safeApprove(address(WETHVault), type(uint).max);
        WAVAX.safeApprove(address(WAVAXVault), type(uint).max);
        USDt.safeApprove(address(USDTVault), type(uint).max);
    }

    function setTokenCompositionTargetPerc(uint[] calldata _targetPerc) external onlyOwner {
        uint targetCnt = _targetPerc.length;
        require(targetCnt == targetPercentages.length, "Invalid count");

        uint sum;
        for (uint i = 0; i < targetCnt; i ++) {
            targetPercentages[i] = _targetPerc[i];
            sum += _targetPerc[i];
        }
        require(sum == DENOMINATOR, "Invalid parameter");
    }

    function getWBTCPoolInUSD() private view  returns (uint) {
        uint amt = WBTCVault.getAllPoolInUSD();
        return amt == 0 ? 0 : amt * WBTCVault.balanceOf(address(this)) / WBTCVault.totalSupply(); //to exclude L1 deposits from other addresses
    }

    function getWETHPoolInUSD() private view  returns (uint) {
        uint amt = WETHVault.getAllPoolInUSD();
        return amt == 0 ? 0 : amt * WETHVault.balanceOf(address(this)) / WETHVault.totalSupply(); //to exclude L1 deposits from other addresses
    }

    function getWAVAXPoolInUSD() private view  returns (uint) {
        uint amt = WAVAXVault.getAllPoolInUSD();
        return amt == 0 ? 0 : amt * WAVAXVault.balanceOf(address(this)) / WAVAXVault.totalSupply(); //to exclude L1 deposits from other addresses
    }

    function getUSDTPoolInUSD() private view  returns (uint) {
        uint amt = USDTVault.getAllPoolInUSD();
        return amt == 0 ? 0 : amt * USDTVault.balanceOf(address(this)) / USDTVault.totalSupply(); //to exclude L1 deposits from other addresses
    }

    function getEachPoolInUSD() private view returns (uint[] memory pools) {
        pools = new uint[](POOL_COUNT);
        pools[0] = getWBTCPoolInUSD();
        pools[1] = getWETHPoolInUSD();
        pools[2] = getWAVAXPoolInUSD();
        pools[3] = getUSDTPoolInUSD();
    }

    function getAllPoolInUSD() public view returns (uint) {
        uint[] memory pools = getEachPoolInUSD();
        return pools[0] + pools[1] + pools[2] + pools[3];
    }

    function getCurrentTokenCompositionPerc() public view returns (address[] memory tokens, uint[] memory percentages) {
        tokens = new address[](POOL_COUNT);
        tokens[0] = address(WBTC);
        tokens[1] = address(WETH);
        tokens[2] = address(WAVAX);
        tokens[3] = address(USDt);

        uint[] memory pools = getEachPoolInUSD();
        uint allPool = pools[0] + pools[1] + pools[2] + pools[3];
        percentages = new uint[](POOL_COUNT);
        for (uint i = 0; i < POOL_COUNT; i ++) {
            percentages[i] = allPool == 0 ? targetPercentages[i] : pools[i] * DENOMINATOR / allPool;
        }
    }

    function getAPR() external view returns (uint) {
        (, uint[] memory perc) = getCurrentTokenCompositionPerc();
        uint allApr = WBTCVault.getAPR() * perc[0]
                    + WETHVault.getAPR() * perc[1]
                    + WAVAXVault.getAPR() * perc[2]
                    + USDTVault.getAPR() * perc[3];
        return (allApr / DENOMINATOR);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

//SPDX-License-Identifier: MIT
pragma solidity  0.8.9;

interface IChainlink {
    function latestAnswer() external view returns (int256);
}

interface IAaveOracle {
    function getAssetPrice(address asset) external view returns (uint256);
}

library PriceLib {
    IAaveOracle internal constant AaveOracle = IAaveOracle(0xEBd36016B3eD09D4693Ed4251c67Bd858c3c7C9C);
    address internal constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    /// @return the price in USD of 8 decimals in precision.
    function getAssetPrice(address asset) internal view returns (uint) {
        if (asset == USDT) {
            return uint(IChainlink(0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a).latestAnswer());
        }
        return AaveOracle.getAssetPrice(asset);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}