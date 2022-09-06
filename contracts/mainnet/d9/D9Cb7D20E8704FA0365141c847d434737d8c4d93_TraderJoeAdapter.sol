// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "../base/AdapterBase.sol";
import "../../interfaces/traderJoe/IJoeLens/IJToken.sol";
import "../../interfaces/traderJoe/IMasterChefJoeV2.sol";
import "../../interfaces/traderJoe/IJoeBar.sol";
import "../../interfaces/traderJoe/IJoeFactory.sol";
import "../../interfaces/traderJoe/IJoeRouter02.sol";
import "../../interfaces/traderJoe/IJoePair.sol";
import "../../interfaces/IWAVAX.sol";
import "../../utils/HomoraMath.sol";

interface ITraderJoeAdapter {
    function isTrustMasterChef(address tokenAddr) external view returns (bool);
}

contract TraderJoeAdapter is AdapterBase {
    using SafeERC20 for IERC20;

    address public constant routerAddr =
        0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    IJoeRouter02 internal constant router = IJoeRouter02(routerAddr);

    mapping(address => bool) public isTrustMasterChef;

    constructor(address _adapterManager, address _timelock)
        AdapterBase(_adapterManager, _timelock, "TraderJoe")
    {}

    event TraderJoeInitialize(address[] masterChefs);

    event TraderJoeFarmEvent(
        address farmAddress,
        address account,
        uint256 amount,
        uint256 pid
    );

    event TraderJoeUnFarmEvent(
        address farmAddress,
        address account,
        uint256 amount,
        uint256 pid
    );

    event TraderJoeEmergencyWithdrawEvent(
        address farmAddress,
        address account,
        uint256 pid
    );

    event TraderJoeAddLiquidityEvent(
        uint256 liquidity,
        address token0,
        address token1,
        uint256 amount0,
        uint256 amount1,
        address account
    );

    event TraderJoeRemoveLiquidityEvent(
        address token0,
        address token1,
        uint256 amount,
        uint256 amount0,
        uint256 amount1,
        address account
    );

    function initialize(address[] calldata masterChefs) external onlyTimelock {
        for (uint256 i = 0; i < masterChefs.length; i++) {
            isTrustMasterChef[masterChefs[i]] = true;
        }

        emit TraderJoeInitialize(masterChefs);
    }

    function swapTokensForExactTokens(
        address account,
        bytes calldata encodedData
    ) external onlyAdapterManager {
        (uint256 amountOut, uint256 amountInMax, address[] memory path) = abi
            .decode(encodedData, (uint256, uint256, address[]));
        pullAndApprove(path[0], account, routerAddr, amountInMax);
        uint256[] memory amounts = router.swapTokensForExactTokens(
            amountOut,
            amountInMax,
            path,
            account,
            block.timestamp
        );
        returnAsset(path[0], account, amountInMax - amounts[0]);
    }

    function swapExactTokensForTokens(
        address account,
        bytes calldata encodedData
    ) external onlyAdapterManager {
        (uint256 amountIn, uint256 amountOutMin, address[] memory path) = abi
            .decode(encodedData, (uint256, uint256, address[]));
        pullAndApprove(path[0], account, routerAddr, amountIn);
        router.swapExactTokensForTokens(
            amountIn,
            amountOutMin,
            path,
            account,
            block.timestamp
        );
    }

    struct addLiquidityInfo {
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 minAmountA;
        uint256 minAmountB;
    }

    function addLiquidity(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        addLiquidityInfo memory addInfo = abi.decode(
            encodedData,
            (addLiquidityInfo)
        );
        pullAndApprove(addInfo.tokenA, account, routerAddr, addInfo.amountA);
        pullAndApprove(addInfo.tokenB, account, routerAddr, addInfo.amountB);
        (uint256 _amountA, uint256 _amountB, uint256 _liquidity) = router
            .addLiquidity(
                addInfo.tokenA,
                addInfo.tokenB,
                addInfo.amountA,
                addInfo.amountB,
                addInfo.minAmountA,
                addInfo.minAmountB,
                account,
                block.timestamp
            );
        returnAsset(addInfo.tokenA, account, addInfo.amountA - _amountA);
        returnAsset(addInfo.tokenB, account, addInfo.amountB - _amountB);

        emit TraderJoeAddLiquidityEvent(
            _liquidity,
            addInfo.tokenA,
            addInfo.tokenB,
            _amountA,
            _amountB,
            account
        );
    }

    struct removeLiquidityInfo {
        address tokenA;
        address tokenB;
        uint256 amount;
        uint256 minAmountA;
        uint256 minAmountB;
    }

    function removeLiquidity(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        removeLiquidityInfo memory removeInfo = abi.decode(
            encodedData,
            (removeLiquidityInfo)
        );
        address lpTokenAddr = IJoeFactory(router.factory()).getPair(
            removeInfo.tokenA,
            removeInfo.tokenB
        );
        require(lpTokenAddr != address(0), "pair-not-found.");
        pullAndApprove(lpTokenAddr, account, routerAddr, removeInfo.amount);
        (uint256 _amountA, uint256 _amountB) = router.removeLiquidity(
            removeInfo.tokenA,
            removeInfo.tokenB,
            removeInfo.amount,
            removeInfo.minAmountA,
            removeInfo.minAmountB,
            account,
            block.timestamp
        );
        emit TraderJoeRemoveLiquidityEvent(
            removeInfo.tokenA,
            removeInfo.tokenB,
            removeInfo.amount,
            _amountA,
            _amountB,
            account
        );
    }

    struct addLiquidityAVAXInfo {
        address tokenAddr;
        uint256 amountTokenDesired;
        uint256 amountTokenMin;
        uint256 amountAVAXMin;
    }

    /// @dev using AVAX to add liquidity
    function addLiquidityAVAX(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        addLiquidityAVAXInfo memory addInfo = abi.decode(
            encodedData,
            (addLiquidityAVAXInfo)
        );
        pullAndApprove(
            addInfo.tokenAddr,
            account,
            routerAddr,
            addInfo.amountTokenDesired
        );
        (uint256 _amountToken, uint256 _amountAVAX, uint256 _liquidity) = router
            .addLiquidityAVAX{value: msg.value}(
            addInfo.tokenAddr,
            addInfo.amountTokenDesired,
            addInfo.amountTokenMin,
            addInfo.amountAVAXMin,
            account,
            block.timestamp
        );
        returnAsset(
            addInfo.tokenAddr,
            account,
            addInfo.amountTokenDesired - _amountToken
        );
        returnAsset(avaxAddr, account, msg.value - _amountAVAX);

        emit TraderJoeAddLiquidityEvent(
            _liquidity,
            addInfo.tokenAddr,
            avaxAddr,
            _amountToken,
            _amountAVAX,
            account
        );
    }

    struct removeLiquidityAVAXInfo {
        address tokenA;
        uint256 liquidity;
        uint256 amountTokenMin;
        uint256 amountAVAXMin;
    }

    /// @dev remove liquidity to get AVAX
    function removeLiquidityAVAX(address account, bytes calldata encodedData)
        external
        onlyAdapterManager
    {
        removeLiquidityAVAXInfo memory removeInfo = abi.decode(
            encodedData,
            (removeLiquidityAVAXInfo)
        );
        address lpTokenAddr = IJoeFactory(router.factory()).getPair(
            removeInfo.tokenA,
            wavaxAddr
        );
        pullAndApprove(lpTokenAddr, account, routerAddr, removeInfo.liquidity);
        (uint256 amountToken, uint256 amountAVAX) = router.removeLiquidityAVAX(
            removeInfo.tokenA,
            removeInfo.liquidity,
            removeInfo.amountTokenMin,
            removeInfo.amountAVAXMin,
            account,
            block.timestamp
        );
        emit TraderJoeRemoveLiquidityEvent(
            removeInfo.tokenA,
            avaxAddr,
            removeInfo.liquidity,
            amountToken,
            amountAVAX,
            account
        );
    }

    /// @dev traderJoe uses the same function to deposit and claim rewards, if deposit amount is 0, you will claim your rewards
    function depositLpToken(
        address masterChefAddr,
        uint256 pid,
        uint256 amount
    ) external onlyDelegation {
        require(
            ITraderJoeAdapter(ADAPTER_ADDRESS).isTrustMasterChef(
                masterChefAddr
            ),
            "!trustMasterChef"
        );
        IMasterChefJoeV2(masterChefAddr).deposit(pid, amount);
        emit TraderJoeFarmEvent(masterChefAddr, address(this), amount, pid);
    }

    function emergencyWithdraw(address masterChefAddr, uint256 pid)
        external
        onlyDelegation
    {
        require(
            ITraderJoeAdapter(ADAPTER_ADDRESS).isTrustMasterChef(
                masterChefAddr
            ),
            "!trustMasterChef"
        );
        IMasterChefJoeV2(masterChefAddr).emergencyWithdraw(pid);
        emit TraderJoeEmergencyWithdrawEvent(
            masterChefAddr,
            address(this),
            pid
        );
    }

    function withdrawLpToken(
        address masterChefAddr,
        uint256 pid,
        uint256 amount
    ) external onlyDelegation {
        require(
            ITraderJoeAdapter(ADAPTER_ADDRESS).isTrustMasterChef(
                masterChefAddr
            ),
            "!trustMasterChef"
        );
        IMasterChefJoeV2(masterChefAddr).withdraw(pid, amount);
        emit TraderJoeUnFarmEvent(masterChefAddr, address(this), amount, pid);
    }

    struct LiquidityCustomized {
        address tokenA;
        address tokenB;
        uint256 amtAUser; // Supplied tokenA amount
        uint256 amtBUser; // Supplied tokenB amount
        uint256 amtAMin; // Desired tokenA amount (slippage control)
        uint256 amtBMin; // Desired tokenB amount (slippage control)
    }

    function addLiquidityInternal(
        address account,
        uint256 balA,
        uint256 balB,
        LiquidityCustomized memory liquidity
    ) internal returns (uint256 _amountA, uint256 _amountB) {
        (_amountA, _amountB, ) = router.addLiquidity(
            liquidity.tokenA,
            liquidity.tokenB,
            balA,
            balB,
            liquidity.amtAMin,
            liquidity.amtBMin,
            account,
            block.timestamp
        );
    }

    function addLiquidityCustomized(address account, bytes calldata encodedData)
        external
        payable
        onlyAdapterManager
    {
        LiquidityCustomized memory liquidity = abi.decode(
            encodedData,
            (LiquidityCustomized)
        );
        pullTokensIfNeeded(liquidity.tokenA, account, liquidity.amtAUser);
        pullTokensIfNeeded(liquidity.tokenB, account, liquidity.amtBUser);

        (uint256 swapAmt, uint256 swapAmtGet, bool isReversed) = autoSwap(
            liquidity
        );

        (uint256 balA, uint256 balB) = isReversed
            ? (liquidity.amtAUser + swapAmtGet, liquidity.amtBUser - swapAmt)
            : (liquidity.amtAUser - swapAmt, liquidity.amtBUser + swapAmtGet);

        approveToken(liquidity.tokenA, routerAddr, balA);
        approveToken(liquidity.tokenB, routerAddr, balB);
        (uint256 amountA, uint256 amountB) = addLiquidityInternal(
            account,
            balA,
            balB,
            liquidity
        );
        returnAsset(liquidity.tokenA, account, balA - amountA);
        returnAsset(liquidity.tokenB, account, balB - amountB);
    }

    function autoSwap(LiquidityCustomized memory liquidity)
        internal
        returns (
            uint256 swapAmt,
            uint256 swapAmtGet,
            bool isReversed
        )
    {
        uint256 resA;
        uint256 resB;
        address lp = IJoeFactory(router.factory()).getPair(
            liquidity.tokenA,
            liquidity.tokenB
        );
        if (IJoePair(lp).token0() == liquidity.tokenA) {
            (resA, resB, ) = IJoePair(lp).getReserves();
        } else {
            (resB, resA, ) = IJoePair(lp).getReserves();
        }
        (swapAmt, isReversed) = optimalDeposit(
            liquidity.amtAUser,
            liquidity.amtBUser,
            resA,
            resB
        );

        if (swapAmt > 0) {
            address[] memory path = new address[](2);
            (path[0], path[1]) = isReversed
                ? (liquidity.tokenB, liquidity.tokenA)
                : (liquidity.tokenA, liquidity.tokenB);
            approveToken(path[0], routerAddr, swapAmt);
            uint256[] memory tokenAmounts = router.swapExactTokensForTokens(
                swapAmt,
                0,
                path,
                address(this),
                block.timestamp
            );
            swapAmtGet = tokenAmounts[1];
        }
    }

    /// @dev Compute optimal deposit amount
    /// @param amtA amount of token A desired to deposit
    /// @param amtB amount of token B desired to deposit
    /// @param resA amount of token A in reserve
    /// @param resB amount of token B in reserve
    function optimalDeposit(
        uint256 amtA,
        uint256 amtB,
        uint256 resA,
        uint256 resB
    ) internal pure returns (uint256 swapAmt, bool isReversed) {
        if (amtA * resB >= amtB * resA) {
            swapAmt = _optimalDepositA(amtA, amtB, resA, resB);
            isReversed = false;
        } else {
            swapAmt = _optimalDepositA(amtB, amtA, resB, resA);
            isReversed = true;
        }
    }

    /// @dev Compute optimal deposit amount helper.
    /// @param amtA amount of token A desired to deposit
    /// @param amtB amount of token B desired to deposit
    /// @param resA amount of token A in reserve
    /// @param resB amount of token B in reserve
    /// Formula: https://blog.alphafinance.io/byot/
    function _optimalDepositA(
        uint256 amtA,
        uint256 amtB,
        uint256 resA,
        uint256 resB
    ) internal pure returns (uint256) {
        require(amtA * resB >= amtB * resA, "Reversed");
        uint256 a = 997;
        uint256 b = uint256(1997) * resA;
        uint256 _c = (amtA * resB) - (amtB * resA);
        uint256 c = ((_c * 1000) / (amtB + resB)) * resA;
        uint256 d = a * c * 4;
        uint256 e = HomoraMath.sqrt(b * b + d);
        uint256 numerator = e - b;
        uint256 denominator = a * 2;
        return numerator / denominator;
    }

    struct LiquidityFromOneToken {
        address sourceToken;
        address tokenA;
        address[] pathA;
        address tokenB;
        address[] pathB;
        uint256 amtSource;
        uint256 amtAMin; // Desired tokenA amount (slippage control)
        uint256 amtBMin; // Desired tokenB amount (slippage control)
    }

    function addLiquidityFromOneToken(
        address account,
        bytes calldata encodedData
    ) external payable onlyAdapterManager {
        LiquidityFromOneToken memory liquidity = abi.decode(
            encodedData,
            (LiquidityFromOneToken)
        );
        if (msg.value != 0 && liquidity.sourceToken == wavaxAddr) {
            IWAVAX(wavaxAddr).deposit{value: msg.value}();
            pullTokensIfNeeded(wavaxAddr, account, liquidity.amtSource);
            liquidity.amtSource += msg.value;
            approveToken(wavaxAddr, routerAddr, liquidity.amtSource);
        } else {
            pullAndApprove(
                liquidity.sourceToken,
                account,
                routerAddr,
                liquidity.amtSource
            );
        }

        (uint256 tokenAget, uint256 tokenBget) = autoSwapFromOneToken(
            liquidity
        );

        approveToken(liquidity.tokenA, routerAddr, tokenAget);
        approveToken(liquidity.tokenB, routerAddr, tokenBget);

        if (tokenAget > 0 || tokenBget > 0) {
            (uint256 amountA, uint256 amountB, ) = router.addLiquidity(
                liquidity.tokenA,
                liquidity.tokenB,
                tokenAget,
                tokenBget,
                liquidity.amtAMin,
                liquidity.amtBMin,
                account,
                block.timestamp
            );
            returnAsset(liquidity.tokenA, account, tokenAget - amountA);
            returnAsset(liquidity.tokenB, account, tokenBget - amountB);
        }
    }

    function autoSwapFromOneToken(LiquidityFromOneToken memory liquidity)
        internal
        returns (uint256 tokenAget, uint256 tokenBget)
    {
        uint256 swapAmt = liquidity.amtSource / 2;
        require(
            liquidity.pathA[0] == liquidity.sourceToken &&
                liquidity.pathB[0] == liquidity.sourceToken,
            "sourceToken error!"
        );
        uint256[] memory amountsA = router.swapExactTokensForTokens(
            swapAmt,
            0,
            liquidity.pathA,
            address(this),
            block.timestamp
        );
        tokenAget = amountsA[amountsA.length - 1];

        uint256[] memory amountsB = router.swapExactTokensForTokens(
            swapAmt,
            0,
            liquidity.pathB,
            address(this),
            block.timestamp
        );
        tokenBget = amountsB[amountsB.length - 1];
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../timelock/TimelockCallable.sol";
import "../../common/Basic.sol";

abstract contract AdapterBase is Basic, Ownable, TimelockCallable {
    using SafeERC20 for IERC20;

    address public ADAPTER_MANAGER;
    address public immutable ADAPTER_ADDRESS;
    string public ADAPTER_NAME;
    mapping(address => mapping(address => bool)) private approved;

    fallback() external payable {}

    receive() external payable {}

    modifier onlyAdapterManager() {
        require(
            ADAPTER_MANAGER == msg.sender,
            "Caller is not the adapterManager."
        );
        _;
    }

    modifier onlyDelegation() {
        require(ADAPTER_ADDRESS != address(this), "Only for delegatecall.");
        _;
    }

    constructor(
        address _adapterManager,
        address _timelock,
        string memory _name
    ) TimelockCallable(_timelock) {
        ADAPTER_MANAGER = _adapterManager;
        ADAPTER_ADDRESS = address(this);
        ADAPTER_NAME = _name;
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        require(_token != address(0) && _token != avaxAddr);
        uint256 balance = IERC20(_token).balanceOf(_from);
        uint256 currentAmount = balance < _amount ? balance : _amount;
        IERC20(_token).safeTransferFrom(_from, address(this), currentAmount);
    }

    function approveToken(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        if (_amount == 0) return;
        if (!approved[_token][_spender]) {
            IERC20 token = IERC20(_token);
            token.safeApprove(_spender, 0);
            token.safeApprove(_spender, type(uint256).max);
            approved[_token][_spender] = true;
        }
    }

    /// @dev get the token from sender, and approve to the user in one step
    function pullAndApprove(
        address _token,
        address _from,
        address _spender,
        uint256 _amount
    ) internal {
        pullTokensIfNeeded(_token, _from, _amount);
        approveToken(_token, _spender, _amount);
    }

    function returnAsset(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        if (_amount > 0) {
            if (_token == avaxAddr) {
                safeTransferAVAX(_to, _amount);
            } else {
                require(_token != address(0), "Token error!");
                IERC20(_token).safeTransfer(_to, _amount);
            }
        }
    }

    function toCallback(
        address _target,
        bytes4 _selector,
        bytes memory _callData
    ) internal {
        (bool success, bytes memory returnData) = _target.call(
            abi.encodePacked(_selector, _callData)
        );
        require(success, string(returnData));
    }

    //Handle when someone else accidentally transfers assets to this contract
    function sweep(address[] memory tokens, address receiver)
        external
        onlyTimelock
    {
        require(address(this) == ADAPTER_ADDRESS, "!Invalid call");
        for (uint256 i = 0; i < tokens.length; i++) {
            address token = tokens[i];
            if (token == address(0)) continue;
            uint256 amount = IERC20(token).balanceOf(address(this));
            if (amount > 0) {
                IERC20(token).safeTransfer(receiver, amount);
            }
        }

        uint256 balance = address(this).balance;
        if (balance > 0) {
            safeTransferAVAX(receiver, balance);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IJToken {
    function _acceptAdmin() external returns (uint256);

    function _addReserves(uint256 addAmount) external returns (uint256);

    function _reduceReserves(uint256 reduceAmount) external returns (uint256);

    function _setCollateralCap(uint256 newCollateralCap) external;

    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) external;

    function _setInterestRateModel(address newInterestRateModel)
        external
        returns (uint256);

    function _setJoetroller(address newJoetroller) external returns (uint256);

    function _setPendingAdmin(address newPendingAdmin)
        external
        returns (uint256);

    function _setReserveFactor(uint256 newReserveFactorMantissa)
        external
        returns (uint256);

    function accountCollateralTokens(address) external view returns (uint256);

    function accrualBlockTimestamp() external view returns (uint256);

    function accrueInterest() external returns (uint256);

    function admin() external view returns (address);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function balanceOfUnderlying(address owner) external returns (uint256);

    function borrow(uint256 borrowAmount) external returns (uint256);

    function borrowBalanceCurrent(address account) external returns (uint256);

    function borrowBalanceStored(address account)
        external
        view
        returns (uint256);

    function borrowIndex() external view returns (uint256);

    function borrowRatePerSecond() external view returns (uint256);

    function collateralCap() external view returns (uint256);

    function decimals() external view returns (uint8);

    function delegateToImplementation(bytes memory data)
        external
        returns (bytes memory);

    function delegateToViewImplementation(bytes memory data)
        external
        view
        returns (bytes memory);

    function exchangeRateCurrent() external returns (uint256);

    function exchangeRateStored() external view returns (uint256);

    function flashFee(uint256 amount) external view returns (uint256);

    function flashFeeBips() external view returns (uint256);

    function flashLoan(
        address receiver,
        address initiator,
        uint256 amount,
        bytes memory data
    ) external returns (bool);

    function getAccountSnapshot(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getCash() external view returns (uint256);

    function gulp() external;

    function implementation() external view returns (address);

    function interestRateModel() external view returns (address);

    function internalCash() external view returns (uint256);

    function isCollateralTokenInit(address) external view returns (bool);

    function isJToken() external view returns (bool);

    function joetroller() external view returns (address);

    function liquidateBorrow(
        address borrower,
        uint256 repayAmount,
        address jTokenCollateral
    ) external returns (uint256);

    function maxFlashLoan() external view returns (uint256);

    function mint(uint256 mintAmount) external returns (uint256);

    function name() external view returns (string memory);

    function pendingAdmin() external view returns (address);

    function redeem(uint256 redeemTokens) external returns (uint256);

    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

    function registerCollateral(address account) external returns (uint256);

    function repayBorrow(uint256 repayAmount) external returns (uint256);

    function repayBorrowBehalf(address borrower, uint256 repayAmount)
        external
        returns (uint256);

    function reserveFactorMantissa() external view returns (uint256);

    function seize(
        address liquidator,
        address borrower,
        uint256 seizeTokens
    ) external returns (uint256);

    function supplyRatePerSecond() external view returns (uint256);

    function symbol() external view returns (string memory);

    function totalBorrows() external view returns (uint256);

    function totalBorrowsCurrent() external returns (uint256);

    function totalCollateralTokens() external view returns (uint256);

    function totalReserves() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 amount) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) external returns (bool);

    function underlying() external view returns (address);

    function unregisterCollateral(address account) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IMasterChefJoeV2 {
    function add(
        uint256 _allocPoint,
        address _lpToken,
        address _rewarder
    ) external;

    function deposit(uint256 _pid, uint256 _amount) external;

    function dev(address _devAddr) external;

    function devAddr() external view returns (address);

    function devPercent() external view returns (uint256);

    function emergencyWithdraw(uint256 _pid) external;

    function investorAddr() external view returns (address);

    function investorPercent() external view returns (uint256);

    function joe() external view returns (address);

    function joePerSec() external view returns (uint256);

    function massUpdatePools() external;

    function owner() external view returns (address);

    function pendingTokens(uint256 _pid, address _user)
        external
        view
        returns (
            uint256 pendingJoe,
            address bonusTokenAddress,
            string memory bonusTokenSymbol,
            uint256 pendingBonusToken
        );

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardTimestamp,
            uint256 accJoePerShare,
            address rewarder
        );

    function poolLength() external view returns (uint256);

    function renounceOwnership() external;

    function rewarderBonusTokenInfo(uint256 _pid)
        external
        view
        returns (address bonusTokenAddress, string memory bonusTokenSymbol);

    function set(
        uint256 _pid,
        uint256 _allocPoint,
        address _rewarder,
        bool overwrite
    ) external;

    function setDevPercent(uint256 _newDevPercent) external;

    function setInvestorAddr(address _investorAddr) external;

    function setInvestorPercent(uint256 _newInvestorPercent) external;

    function setTreasuryAddr(address _treasuryAddr) external;

    function setTreasuryPercent(uint256 _newTreasuryPercent) external;

    function startTimestamp() external view returns (uint256);

    function totalAllocPoint() external view returns (uint256);

    function transferOwnership(address newOwner) external;

    function treasuryAddr() external view returns (address);

    function treasuryPercent() external view returns (uint256);

    function updateEmissionRate(uint256 _joePerSec) external;

    function updatePool(uint256 _pid) external;

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IJoeBar {
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external view returns (uint8);

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external
        returns (bool);

    function enter(uint256 _amount) external;

    function increaseAllowance(address spender, uint256 addedValue)
        external
        returns (bool);

    function joe() external view returns (address);

    function leave(uint256 _share) external;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IJoeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IWAVAX {
    function allowance(address, address) external view returns (uint256);

    function approve(address guy, uint256 wad) external returns (bool);

    function balanceOf(address) external view returns (uint256);

    function decimals() external view returns (uint8);

    function deposit() external payable;

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transfer(address dst, uint256 wad) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library HomoraMath {
    using SafeMath for uint256;

    function divCeil(uint256 lhs, uint256 rhs) internal pure returns (uint256) {
        return lhs.add(rhs).sub(1) / rhs;
    }

    function fmul(uint256 lhs, uint256 rhs) internal pure returns (uint256) {
        return lhs.mul(rhs) / (2**112);
    }

    function fdiv(uint256 lhs, uint256 rhs) internal pure returns (uint256) {
        return lhs.mul(2**112) / rhs;
    }

    // implementation from https://github.com/Uniswap/uniswap-lib/commit/99f3f28770640ba1bb1ff460ac7c5292fb8291a0
    // original implementation: https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 xx = x;
        uint256 r = 1;

        if (xx >= 0x100000000000000000000000000000000) {
            xx >>= 128;
            r <<= 64;
        }

        if (xx >= 0x10000000000000000) {
            xx >>= 64;
            r <<= 32;
        }
        if (xx >= 0x100000000) {
            xx >>= 32;
            r <<= 16;
        }
        if (xx >= 0x10000) {
            xx >>= 16;
            r <<= 8;
        }
        if (xx >= 0x100) {
            xx >>= 8;
            r <<= 4;
        }
        if (xx >= 0x10) {
            xx >>= 4;
            r <<= 2;
        }
        if (xx >= 0x8) {
            r <<= 1;
        }

        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1;
        r = (r + x / r) >> 1; // Seven iterations should be enough
        uint256 r1 = x / r;
        return (r < r1 ? r : r1);
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

abstract contract TimelockCallable {
    address public TIMELOCK_ADDRESS;

    event SetTimeLock(address newTimelock);

    constructor(address _timelock) {
        TIMELOCK_ADDRESS = _timelock;
    }

    modifier onlyTimelock() {
        require(TIMELOCK_ADDRESS == msg.sender, "Caller is not the timelock.");
        _;
    }

    function setTimelock(address newTimelock) external onlyTimelock {
        require(newTimelock != address(0));
        TIMELOCK_ADDRESS = newTimelock;
        emit SetTimeLock(newTimelock);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

abstract contract Basic {
    /**
     * @dev Return ethereum address
     */
    address public constant avaxAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    /// @dev Return Wrapped AVAX address
    address public constant wavaxAddr =
        0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;

    function safeTransferAVAX(address to, uint256 value) internal {
        if (value != 0) {
            (bool success, ) = to.call{value: value}(new bytes(0));
            require(success, "helper::safeTransferAVAX: AVAX transfer failed");
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0 <0.9.0;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
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