// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./../interfaces/ILickHitter.sol";
import "./../interfaces/ILendingPair.sol";
import "./../interfaces/IRadarUSD.sol";
import "./../interfaces/IOracle.sol";
import "./../interfaces/ILiquidator.sol";
import "./../interfaces/ISwapper.sol";

/// @title LendingPair
/// @author Radar Global ([email protected])
/// @notice Single collateral asset lending pair, used for
/// USDR (stablecoin) lending
contract LendingPair is ReentrancyGuard {
    using SafeERC20 for IERC20;

    bool public initialized = false;

    address private owner;
    address private pendingOwner;

    address private collateral;
    uint8 private collateralDecimals;
    address private lendAsset;

    address private yieldVault;
    address private oracle;
    address private swapper;

    uint256 private exchangeRate;

    uint256 public ENTRY_FEE;
    uint256 public EXIT_FEE;
    uint256 public LIQUIDATION_INCENTIVE;
    uint256 public RADAR_LIQUIDATION_FEE;
    uint256 public constant GENERAL_DIVISOR = 10000;
    address public FEE_RECEIVER;
    uint256 private accumulatedFees;

    uint256 public MAX_LTV;

    mapping(address => uint256) private shareBalances;
    mapping(address => uint256) private borrows;
    uint256 private totalShares;
    uint256 private totalBorrowed;

    event CollateralAdded(address indexed owner, uint256 amount, uint256 shares);
    event CollateralRemoved(address indexed owner, uint256 amount, uint256 shares);
    event FeesClaimed(uint256 amount, uint256 shares);
    event AssetBorrowed(address indexed owner, uint256 borrowAmount, address indexed receiver);
    event LoanRepaid(address indexed owner, uint256 repayAmount, address indexed receiver);
    event Liquidated(address indexed user, address indexed liquidator, uint256 repayAmount, uint256 collateralLiquidated);

    /// @notice Manages access control. Only allows master (non-proxy) contract owner to call specific functions.
    /// @dev If the EIP-1967 storage address is empty, then this is the non-proxy contract
    /// and fetches the owner address from the storage variable. If it is not empty, it will
    /// fetch the owner address from the non-proxy contract
    modifier onlyOwner {
        address impl;
        address _ownerAddr;
        assembly {
            impl := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
        if (impl == address(0)) {
            // Means this is not a proxy, and it's the implementation contract
            _ownerAddr = owner;
        } else {
            // This is a proxy, get owner of the implementation contract
            _ownerAddr = ILendingPair(impl).getOwner();
        }
        require(msg.sender == _ownerAddr, "Unauthorized");
        _;
    }

    /// @notice These functions can only be called on the non-proxy contract
    /// @dev Just fetches the EIP-1967 storage address and checks it is empty
    modifier onlyNotProxy {
        address impl;
        assembly {
            impl := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
        require(impl == address(0), "Cannot call this on proxy");
        _;
    }

    /// @notice Updates `exchangeRate` variable from the oracle
    /// @dev This modifier is applied to functions which need an updated
    /// exchange rate to ensure the calculations are safe. This includes
    /// any function that will check if a user is or is not 'safe' a.k.a flagged
    /// for loan liquidation. The liquidation functions also implements this modifier.
    /// This is made as a modifier so no extra oracle calls (which are expensive) are made
    /// per transaction.
    modifier updateExchangeRate {
        exchangeRate = IOracle(oracle).getUSDPrice(collateral);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /// @notice Proxy initialization function
    /// @param _collateral The ERC20 address of the collateral used for lending
    /// @param _lendAsset The ERC20 address of the asset which will be lended (USDR)
    /// @param _entryFee The entry fee percentage when borrowing assets (times GENERAL_DIVISOR)
    /// @param _exitFee The exit fee percentage when repaying loans (times GENERAL_DIVISOR)
    /// @param _liquidationIncentive The percentage of liquidated collateral which will be added on top of the
    /// total liquidated collateral that is released, as an incentive/reward for the liquidator
    /// @param _radarLiqFee The percentage of the earned liquidation incentive (see `_liquidationIncentive`)
    /// that the liquidator must pay over the flat repayAmount, as a fee. This splits x% of the
    /// liquidator reward to the Radar ecosystem.
    /// @param _yieldVault The address of the yield farming vault, which is the `LickHitter` farming contract
    /// @param _feeReceiver The address which will receive accumulated fees
    /// @param _maxLTV The maximum Loan-To-Value (LTV) ratio a user can have before
    /// being flagged for liquidation (times GENERAL_DIVISOR)
    /// @param _oracle Price oracle which implements the `IOracle` interface
    /// @param _swapper Assets swapper which implements the `ISwapper` interface
    /// that will be used for hooked functions.
    function init(
        address _collateral,
        address _lendAsset,
        uint256 _entryFee,
        uint256 _exitFee,
        uint256 _liquidationIncentive,
        uint256 _radarLiqFee,
        address _yieldVault,
        address _feeReceiver,
        uint256 _maxLTV,
        address _oracle,
        address _swapper
    ) external {
        require(!initialized, "Already initialized");
        initialized = true;

        // Don't allow on non-proxy contract
        address impl;
        assembly {
            impl := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
        require(impl != address(0), "Initializing master contract");

        collateral = _collateral;
        collateralDecimals = IERC20Metadata(collateral).decimals();
        lendAsset = _lendAsset;
        ENTRY_FEE = _entryFee;
        EXIT_FEE = _exitFee;
        LIQUIDATION_INCENTIVE = _liquidationIncentive;
        RADAR_LIQUIDATION_FEE = _radarLiqFee;
        yieldVault = _yieldVault;
        FEE_RECEIVER = _feeReceiver;
        MAX_LTV = _maxLTV;
        oracle = _oracle;
        swapper = _swapper;
    }

    // Owner functions

    function transferOwnership(address _newOwner) external onlyOwner onlyNotProxy {
        pendingOwner = _newOwner;
    }

    function claimOwnership() external onlyNotProxy {
        require(msg.sender == pendingOwner, "Unauthorized");

        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function changeFeeReceiver(address _newReceiver) external onlyOwner {
        FEE_RECEIVER = _newReceiver;
    }

    function changeOracle(address _newOracle) external onlyOwner {
        oracle = _newOracle;
    }

    /// @dev Be careful when calling this function, since it can "over-burn"
    /// from the stablecoin reserve and actually burn accumulated fees.
    function burnStablecoin(uint256 _amount) external onlyOwner {
        uint256 _sharesAmount = ILickHitter(yieldVault).convertShares(lendAsset, 0, _amount);
        ILickHitter(yieldVault).withdraw(lendAsset, address(this), _sharesAmount);
        IRadarUSD(lendAsset).burn(_amount);
    }

    /// @dev Gives owner power to liquidate everyone (by setting a low MAX_LTV),
    /// but the owner will be a trusted multisig
    function changeMaxLtv(uint256 _newMax) external onlyOwner {
        MAX_LTV = _newMax;
    }

    function changeFees(uint256 _entryFee, uint256 _exitFee, uint256 _liquidationIncentive, uint256 _radarLiqFee) external onlyOwner {
        ENTRY_FEE = _entryFee;
        EXIT_FEE = _exitFee;
        LIQUIDATION_INCENTIVE = _liquidationIncentive;
        RADAR_LIQUIDATION_FEE = _radarLiqFee;
    }

    function changeSwapper(address _newSwapper) external onlyOwner {
        swapper = _newSwapper;
    }

    // User functions

    /// @notice This will withdraw accumulated fees to the `FEE_RECEIVER` address
    /// @dev This doesn't require access control since `FEE_RECEIVER` is a set address,
    /// and there are no "arbitrage" opportunities by withdrawing fees.
    function claimFees() external {
        require(accumulatedFees > 0, "No fees accumulated");
        uint256 _sharesValue = ILickHitter(yieldVault).convertShares(lendAsset, 0, accumulatedFees);
        ILickHitter(yieldVault).withdraw(lendAsset, FEE_RECEIVER, _sharesValue);
        emit FeesClaimed(accumulatedFees, _sharesValue);
        accumulatedFees = 0;
    }

    /// @notice Deposit collateral. Just specify amount. Must have allowance for this contract (collateral)
    /// @param _amount Collateral amount (not `LickHitter` shares, direct collateral)
    /// @param _receiver Address which will receive collateral shares
    function deposit(uint256 _amount, address _receiver) external {
        _deposit(_amount, _receiver);
    }

    /// @notice Withdraw collateral.
    /// @dev Must update exchange rate to calculate if the user can do this
    /// without being flagged for liquidation, since he is withdrawing collateral.
    /// @param _amount Amount of collateral to withdraw
    /// @param _receiver Address where the collateral will be sent to.
    function withdraw(uint256 _amount, address _receiver) updateExchangeRate external {
        _withdraw(_amount, _receiver);
        require(_userSafe(msg.sender), "User not safe");
    }

    /// @notice Borrow assets (USDR)
    /// @dev Must update exchange rate to calculate if the user can do this
    /// without being flagged for liquidation, since he is borrowing assets.
    /// @param _receivingAddress Address where the borrowed assets will be sent to.
    /// @param _amount Amount (of USDR) to borrow.
    function borrow(address _receivingAddress, uint256 _amount) updateExchangeRate external {
        _borrow(_receivingAddress, _amount);
        require(_userSafe(msg.sender), "User not safe");
    }

    /// @notice Repay a part of or the full loan
    /// @dev Here we don't need to update the exchange rate, since
    /// the user is repaying collateral, making them "safer", and since
    /// we don't check if the user will be flagged for liquidation, we
    /// don't need to update the exchange rate to save gas costs.
    /// @param _repaymentReceiver The address to which the repayment is made: a user
    /// could repay the loan of another user.
    /// @param _amount Repay amount. Must have allowance for this contract (USDR)
    /// @param _permitData optional. Use for permit() on USDR.
    function repay(address _repaymentReceiver, uint256 _amount, bytes calldata _permitData) external {
        if (_permitData.length > 0) {
            _permitApprove(_permitData);
        }
        _repay(_repaymentReceiver, _amount);
    }

    /// @notice Deposit collateral and borrow assets in a single transaction.
    /// @dev Just calls both the `_deposit` and `_borrow` internal functions. Must update
    /// exchange rate since a borrow operation takes place here and we must verify the user
    /// borrows an amount that will not flag him for liquidation.
    /// @param _depositAmount Amount of collateral to deposit, must have allowance.
    /// @param _borrowAmount Amount of assets (USDR) to borrow
    /// @param _receivingAddress Address where borrowed assets will be sent to.
    function depositAndBorrow(
        uint256 _depositAmount,
        uint256 _borrowAmount,
        address _receivingAddress
    ) external updateExchangeRate {
        _deposit(_depositAmount, msg.sender);
        _borrow(_receivingAddress, _borrowAmount);
        require(_userSafe(msg.sender), "User not safe");
    }

    /// @notice Repay a loan and withdraw collateral in a single transaction
    /// @dev Just calls both the `_repay` and `_withdraw` internal functions. Must update
    /// exchange rate since a withdraw operation takes place here and we must verify the user
    /// will not have too little collateral, a.k.a. being flagged for liquidation.
    /// @param _repayAmount Amount of assets (USDR) to repay, must have allowance.
    /// @param _repaymentReceiver What address receives the repayment.
    /// @param _withdrawAmount How much collateral to withdraw.
    /// @param _withdrawReceiver The address which will receive the collateral.
    /// @param _permitData optional. Use for permit() on USDR.
    function repayAndWithdraw(
        uint256 _repayAmount,
        address _repaymentReceiver,
        uint256 _withdrawAmount,
        address _withdrawReceiver,
        bytes calldata _permitData
    ) external updateExchangeRate {
        if (_permitData.length > 0) {
            _permitApprove(_permitData);
        }
        _repay(_repaymentReceiver, _repayAmount);
        _withdraw(_withdrawAmount, _withdrawReceiver);
        require(_userSafe(msg.sender), "User not safe");
    }

    /// @notice Deposits collateral, takes out a loan which is then swapped
    /// for the collateral and deposited again. This allows users to "borrow" collateral
    /// and receive a higher yield, while remaining "safe" (not flagged for liquidation)
    /// This also allows the user to "open a long position on the collateral",
    /// while also earning more yield than with just a simple deposit.
    /// @dev We update the exchange rate and check if the user is not flagged for liquidation
    /// at the end of the function. Since the amount of collateral received from the swap
    /// should not have to be calculated exactly, the function records its `LickHitter` share
    /// balances (of collateral) before and after the swap in order to record how much collateral the user gained.
    /// The initial deposit (`_depositAmount`) is also sent directly to the swapper in order to save gas costs, since
    /// the swapper will deposit that collateral to the `LickHitter` as well (the swapper
    /// will deposit all collateral balance to the `LickHitter` after the swap, including the
    /// initial deposit).
    /// The loan is sent directly to the swapper and then called to swap it for collateral.
    /// The swapper is a different contract for each `LendingPair` since collaterals will be
    /// different assets and there are different ways to swap them (more efficiently).
    /// @param _depositAmount How much collateral to deposit (initially). Must have allowance.
    /// @param _borrowAmount How much USDR to borrow that will be swapped to collateral.
    /// @param _swapData Data containing slippage, swap routes, etc. This is different for each
    /// swapper contract. It is the caller's responsability to check this `_swapData` will not
    /// partially fill an order, or leave any remaining USDR in the swapper,
    /// since those assets will be lost if not transffered during this transaction.
    function hookedDepositAndBorrow(
        uint256 _depositAmount,
        uint256 _borrowAmount,
        bytes calldata _swapData
    ) external updateExchangeRate {
        uint256 _before = ILickHitter(yieldVault).balanceOf(collateral, address(this));
        // 1. Borrow and send direct deposit
        _borrow(swapper, _borrowAmount);
        if (_depositAmount > 0) {
            IERC20(collateral).safeTransferFrom(msg.sender, swapper, _depositAmount);
        }

        // 2. Swap for collateral
        ISwapper(swapper).depositHook(
            collateral,
            _swapData
        );

        // 3. Deposit collateral (use before/after calculation)
        uint256 _after = ILickHitter(yieldVault).balanceOf(collateral, address(this));
        uint256 _userDeposit = _after - _before;
        require(_userDeposit > 0, "Invalid deposit");

        uint256 _collateralDeposited = ILickHitter(yieldVault).convertShares(collateral, _userDeposit, 0);

        shareBalances[msg.sender] = shareBalances[msg.sender] + _userDeposit;
        totalShares = totalShares + _userDeposit;
        emit CollateralAdded(msg.sender, _collateralDeposited, _userDeposit);

        require(_userSafe(msg.sender), "User not safe");
    }

    /// @notice Uses collateral to repay an outstanding loan. This can be called by a user
    /// to reduce his LTV (and his risk), or he could also repay his entire loan using his collateral.
    /// If too much USDR is received from the swapped collateral to cover both the user's loan
    /// and the repayment fee, the rest will be transferred to the user's `LickHitter` account.
    /// @dev This function withdraws collateral from the user's account and transfers it to the
    /// swapper contract. The user can also send an optional direct USDR repayment which will also be
    /// transferred to the swapper contract. The swapper then swaps the user's collateral for
    /// USDR and deposits all its USDR balance to the LendingPair's `LickHitter` account (including
    /// the optional direct repayment amount). This function then calculates how many USDR shares
    /// were added to its balance and considers them a repayment for the user's loan. We also need
    /// to update the exchange rate and check if the user is safe at the end since a withdraw
    /// operation takes place.
    /// @param _directRepayAmount An optional amount of USDR that will be used for this loan
    /// repayment. If the user doesn't want to directly repay a part of his loan from his USDR balance,
    /// he will set this to 0. If it is not 0, the user must have USDR allowance towards this contract.
    /// @param _withdrawAmount How much collateral to withdraw that will be swapped and used for
    /// repaying the user's loan.
    /// @param _swapData Data containing slippage, swap routes, etc. This is different for each
    /// swapper contract. It is the caller's responsability to check this `_swapData` will not
    /// partially fill an order, or leave any remaining collateral assets in the swapper,
    /// since those assets will be lost if not transffered during this transaction.
    /// @param _permitData optional. Use for permit() on USDR.
    function hookedRepayAndWithdraw(
        uint256 _directRepayAmount,
        uint256 _withdrawAmount,
        bytes calldata _swapData,
        bytes calldata _permitData
    ) external updateExchangeRate {
        // 1. Withdraw and send direct repay
        if (_permitData.length > 0) {
            _permitApprove(_permitData);
        }
        if (_directRepayAmount != 0) {
            IERC20(lendAsset).safeTransferFrom(msg.sender, swapper, _directRepayAmount);
        }

        uint256 _before = ILickHitter(yieldVault).balanceOf(lendAsset, address(this));
        _withdraw(_withdrawAmount, swapper);

        // 2. Swap for lendAsset
        ISwapper(swapper).repayHook(
            collateral,
            _swapData
        );

        // 3. Repay loan (use before/after calculation)
        uint256 _after = ILickHitter(yieldVault).balanceOf(lendAsset, address(this));
        uint256 _repayAmount = ILickHitter(yieldVault).convertShares(lendAsset, (_after - _before), 0);
        require( _repayAmount > 0, "Repay 0");

        uint256 _maxRepay = borrows[msg.sender] + ((borrows[msg.sender] * EXIT_FEE) / GENERAL_DIVISOR);
        
        uint256 _userRepayAmount;
        uint256 _fee;
        if (_repayAmount > _maxRepay) {
            // Dust will be left, beucase we are
            // trying to repay more than the
            // actual loan itself (+ exit fee), so we will
            // be sending the leftover borrowed
            // assets to the user's LickHitter
            // account
            _fee = (borrows[msg.sender] * EXIT_FEE) / GENERAL_DIVISOR;
            uint256 _dustLeft;
            unchecked {
                _dustLeft = _repayAmount - _maxRepay;
            }
            _userRepayAmount = borrows[msg.sender];
            totalBorrowed = totalBorrowed - _userRepayAmount;
            borrows[msg.sender] = 0;

            // Convert to shares and send
            _dustLeft = ILickHitter(yieldVault).convertShares(lendAsset, 0, _dustLeft);
            ILickHitter(yieldVault).transferShares(lendAsset, msg.sender, _dustLeft);
        } else {
            _fee = (_repayAmount * EXIT_FEE) / GENERAL_DIVISOR;
            _userRepayAmount = _repayAmount - _fee;
            totalBorrowed = totalBorrowed - _userRepayAmount;
            borrows[msg.sender] = borrows[msg.sender] - _userRepayAmount;
        }
        accumulatedFees = accumulatedFees + _fee;
        emit LoanRepaid(msg.sender, _userRepayAmount, msg.sender);

        require(_userSafe(msg.sender), "User not safe");
    }

    /// @notice Liquidates one or multiple users which are flagged for liquidation
    /// (a.k.a. "not safe"). The user calling this function must have the address
    /// of a special liquidator contract which will receive liquidated collateral
    /// and has the responsability to swap it for USDR and deposit it into
    /// the `LendingPair`'s `LickHitter` account.
    /// @dev This function is non-reentrant for extra protection. It just
    /// loops through the given users, checks if they are flagged for liquidation and
    /// calculates the repayment required (including the ecosystem liquidation fee)
    /// and collateral (plus collateral reward/incentive) which will be sent out (for swapping).
    /// It then checks that the liquidator contract repaid the needed assets.
    /// @param _users List of users to liquidate.
    /// @param _repayAmounts For each user, how much of their loan to repay.
    /// You can just use a number bigger than their entire loan to repay their
    /// whole loan.
    /// @param _liquidator Address of the liquidator contract which will manage the
    /// swapping and repayment. Must implement the `ILiquidator` interface.
    /// @param _swapData Liquidator swap data including slippage, routes etc.
    function liquidate(
        address[] calldata _users,
        uint256[] calldata _repayAmounts,
        address _liquidator,
        bytes calldata _swapData
    ) external updateExchangeRate nonReentrant {
        require(_users.length == _repayAmounts.length, "Invalid data");

        uint256 _totalCollateralLiquidated;
        uint256 _totalRepayRequired;

        for(uint256 i = 0; i < _users.length; i++) {
            address _user = _users[i];
            if(!_userSafe(_user)) {
                uint256 _repayAmount = borrows[_user] < _repayAmounts[i] ? borrows[_user] : _repayAmounts[i];
                totalBorrowed = totalBorrowed - _repayAmount;
                unchecked {
                    borrows[_user] = borrows[_user] - _repayAmount;   
                }
                
                // Collateral removed is collateral of _repayAmount value + liquidation/finder fee
                // Calculate total collateral to be removed in stablecoin
                uint256 _collateralRemoved = (_repayAmount + ((LIQUIDATION_INCENTIVE * _repayAmount) / GENERAL_DIVISOR));
                // Convert to actual collateral
                _collateralRemoved = (_collateralRemoved * 10**collateralDecimals) / exchangeRate;
                uint256 _collateralShares = ILickHitter(yieldVault).convertShares(collateral, 0, _collateralRemoved);
                if (shareBalances[_user] >= _collateralShares) {
                    unchecked {
                        shareBalances[_user] = shareBalances[_user] - _collateralShares;
                    }
                    totalShares = totalShares - _collateralShares;
                } else {
                    // In this case, the liquidation will most likely not be profitable
                    // But this condition is kept to re-pegg the token in extreme
                    // collateral value drop situations
                    _collateralRemoved = ILickHitter(yieldVault).convertShares(collateral, shareBalances[_user], 0);
                    totalShares = totalShares - shareBalances[_user];
                    shareBalances[_user] = 0;
                }

                _totalCollateralLiquidated = _totalCollateralLiquidated + _collateralRemoved;
                _totalRepayRequired = _totalRepayRequired + _repayAmount;

                emit Liquidated(
                    _user,
                    msg.sender,
                    _repayAmount,
                    _collateralRemoved
                );
            }
        }
        require(_totalCollateralLiquidated > 0 && _totalRepayRequired > 0, "Liquidate none");
        uint256 _radarFee = (_totalRepayRequired * LIQUIDATION_INCENTIVE * RADAR_LIQUIDATION_FEE) / (GENERAL_DIVISOR ** 2);
        accumulatedFees = accumulatedFees + _radarFee;
        _totalRepayRequired = _totalRepayRequired + _radarFee;

        // Send liquidator his collateral
        uint256 _collShares = ILickHitter(yieldVault).convertShares(collateral, 0, _totalCollateralLiquidated);
        ILickHitter(yieldVault).withdraw(collateral, _liquidator, _collShares);

        // Perform Liquidation
        uint256 _before = ILickHitter(yieldVault).balanceOf(lendAsset, address(this));
        ILiquidator(_liquidator).liquidateHook(
            collateral,
            msg.sender,
            _totalRepayRequired,
            _totalCollateralLiquidated,
            _swapData
        );
        uint256 _after = ILickHitter(yieldVault).balanceOf(lendAsset, address(this));
        uint256 _repaidAmount = ILickHitter(yieldVault).convertShares(lendAsset, (_after - _before), 0);

        // Check the repayment was made
        require(_repaidAmount >= _totalRepayRequired, "Repayment not made");
        
    }

    // Internal functions

    function _permitApprove(bytes calldata _permitData) internal {
        (address _owner, address _spender, uint _value, uint _deadline, uint8 _v, bytes32 _r, bytes32 _s) = abi.decode(_permitData, (address,address,uint,uint,uint8,bytes32,bytes32));
        IRadarUSD(lendAsset).permit(_owner, _spender, _value, _deadline, _v, _r, _s);
    }

    /// @dev Returns true if user is safe and doesn't need to be liquidated
    function _userSafe(address _user) internal view returns (bool) {
        uint256 _borrowed = borrows[_user];
        uint256 _collateral = _userCollateral(_user);
        if (_borrowed == 0) {
            return true;
        }
        if (_collateral == 0) {
            return false;
        }

        // Price has 18 decimals and stablecoin has 18 decimals
        return ((_collateral * exchangeRate * MAX_LTV) / (10**collateralDecimals * GENERAL_DIVISOR)) >= _borrowed;
    }

    function _deposit(uint256 _amount, address _receiver) internal {
        IERC20(collateral).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(collateral).safeApprove(yieldVault, _amount);
        uint256 _sharesMinted = ILickHitter(yieldVault).deposit(collateral, address(this), _amount);
        shareBalances[_receiver] = shareBalances[_receiver] + _sharesMinted;
        totalShares = totalShares + _sharesMinted;
        emit CollateralAdded(_receiver, _amount, _sharesMinted);
    }

    function _withdraw(uint256 _amount, address _receiver) internal {
        uint256 _shares = ILickHitter(yieldVault).convertShares(collateral, 0, _amount);
        require(shareBalances[msg.sender] >= _shares, "Insufficient funds");
        unchecked {
            shareBalances[msg.sender] = shareBalances[msg.sender] - _shares;   
        }
        totalShares = totalShares - _shares;
        ILickHitter(yieldVault).withdraw(collateral, _receiver, _shares);
        emit CollateralRemoved(msg.sender, _amount, _shares);
    }

    function _borrow(address _receiver, uint256 _amount) internal {
        uint256 _fee = (_amount * ENTRY_FEE) / GENERAL_DIVISOR;
        accumulatedFees = accumulatedFees + _fee;
        uint256 _borrowAmount = _amount + _fee;

        require(_amount <= _availableToBorrow(), "Not enough coins");

        borrows[msg.sender] = borrows[msg.sender] + _borrowAmount;
        totalBorrowed = totalBorrowed + _borrowAmount;

        uint256 _sharesWithdraw = ILickHitter(yieldVault).convertShares(lendAsset, 0, _amount);
        ILickHitter(yieldVault).withdraw(lendAsset, _receiver, _sharesWithdraw);

        emit AssetBorrowed(msg.sender, _borrowAmount, _receiver);
    }

    /// @notice You will have to pay a little more than `_amount` because of the exit fee
    function _repay(address _receiver, uint256 _amount) internal {
        uint256 _fee = (_amount * EXIT_FEE) / GENERAL_DIVISOR;
        accumulatedFees = accumulatedFees + _fee;
        uint256 _repayAmount = _amount + _fee;

        IERC20(lendAsset).safeTransferFrom(msg.sender, address(this), _repayAmount);
        IERC20(lendAsset).safeApprove(yieldVault, _repayAmount);
        ILickHitter(yieldVault).deposit(lendAsset, address(this), _repayAmount);

        borrows[_receiver] = borrows[_receiver] - _amount;
        totalBorrowed = totalBorrowed - _amount;

        emit LoanRepaid(msg.sender, _amount, _receiver);
    }

    function _userCollateral(address _user) internal view returns (uint256) {
        return ILickHitter(yieldVault).convertShares(collateral, shareBalances[_user], 0);
    }

    function _availableToBorrow() internal view returns (uint256) {
        uint256 _myShares = ILickHitter(yieldVault).balanceOf(lendAsset, address(this));
        return ILickHitter(yieldVault).convertShares(lendAsset, _myShares, 0) - accumulatedFees;
    }

    // State Getters

    /// @return Returns the owner of this contract
    /// @notice Returns address(0) if this is a proxy,
    /// since the actual owner is the owner of the
    /// non-proxy contract
    function getOwner() external view returns (address) {
        return owner;
    }

    /// @return impl_ Returns the non-proxy/master contract
    /// @notice if this is a proxy. Otherwise, returns address(0)
    function getImplementation() external view returns (address impl_) {
        assembly {
            impl_ := sload(0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc)
        }
    }

    /// @return The pending owner of the contract before accepting ownership
    /// @notice Always returns address(0) if this is a proxy contract.
    function getPendingOwner() external view returns (address) {
        return pendingOwner;
    }

    /// @return Address of collateral
    function getCollateral() external view returns (address) {
        return collateral;
    }

    /// @return Address of the lend asset (USDR)
    function getLendAsset() external view returns (address) {
        return lendAsset;
    }

    /// @return Address of the oracle.
    function getOracle() external view returns (address) {
        return oracle;
    }

    /// @return Address of the swapper.
    function getSwapper() external view returns (address) {
        return swapper;
    }

    /// @return Returns how much collateral a user has deposited in the `LendingPair`
    /// @param _user Address of the user
    function getCollateralBalance(address _user) external view returns (uint256) {
        return _userCollateral(_user);
    }

    /// @return Returns how much USDR a user has currently borrowed.
    /// @param _user Address of the user
    function getUserBorrow(address _user) external view returns (uint256) {
        return borrows[_user];
    }

    /// @return How much collateral is deposited in this `LendingPair`
    function getTotalCollateralDeposited() external view returns (uint256) {
        return ILickHitter(yieldVault).convertShares(collateral, totalShares, 0);
    }

    /// @return Total amount of borrowed USDR from this `LendingPair`
    function getTotalBorrowed() external view returns (uint256) {
        return totalBorrowed;
    }

    /// @return Amount of unclaimed fees in USDR
    function unclaimedFees() external view returns (uint256) {
        return ILickHitter(yieldVault).convertShares(lendAsset, 0, accumulatedFees);
    }

    /// @return Amount of USDR available to borrow
    /// @dev This is just the amount of stablecoin this contract owns
    /// in the `LickHitter` minus any unclaimed fees.
    function availableToBorrow() external view returns (uint256) {
        return _availableToBorrow();
    }

    /// @notice This is view only and exchange rate will not
    /// be updated (until an actual important call happens)
    /// so the result of this function may not be accurate.
    /// @param _user Address of the user.
    /// @return If a user is or not safe a.k.a. flagged for liquidation.
    /// If this returns false, the user is not safe and flagged for liquidation.
    function isUserSafe(address _user) external view returns (bool) {
        return _userSafe(_user);
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

/*
 Copyright (c) 2022 Radar Global

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ILickHitter {

    // Owner Functions

    function changePokeMe(address _newPokeMe) external;

    function changeBufferAmount(address _token, uint256 _newBuf) external;

    function transferOwnership(address _newOwner) external;

    function claimOwnership() external;

    function addStrategy(address _token, address _strategy) external;

    function removeStrategy(address _token) external;

    function emptyStrategy(address _token) external;

    function addSupportedToken(address _token, uint256 _bufferSize) external;

    function removeSupportedToken(address _token) external;

    // User functions

    function transferShares(address _token, address _to, uint256 _amount) external;

    // Deposits get called with token amount and
    // Withdrawals get called with shares amount.
    // If this is not what the user/contract interacting
    // with the IYV wants, the convertShares
    // function can be used

    function deposit(address _token, address _destination, uint256 _amount) external returns (uint256);

    function withdraw(address _token, address _destination, uint256 _shares) external returns (uint256);

    // Bot functions (Gelato)

    function executeStrategy(address _token) external;

    // State Getters

    function balanceOf(address _token, address _owner) external view returns (uint256);

    function getOwner() external view returns (address);

    function getPendingOwner() external view returns (address);

    function getTokenStrategy(address _token) external view returns (address);

    function getTotalShareSupply(address _token) external view returns (uint256);

    function getTotalInvested(address _token) external view returns (uint256);

    function getIsSupportedToken(address _token) external view returns (bool);

    function convertShares(address _token, uint256 _shares, uint256 _amount) external view returns (uint256);
}

/*
 Copyright (c) 2022 Radar Global

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ILendingPair {
    function getOwner() external view returns (address);
    function deposit(uint256 _amount, address _receiver) external;
}

/*
 Copyright (c) 2022 Radar Global

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IRadarUSD {

    function owner() external view returns (address);
    function pendingOwner() external view returns (address);

    function minter(address) external view returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address) external view returns (uint);

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    // User functions

    // EIP-2612: permit() https://eips.ethereum.org/EIPS/eip-2612
    function permit(address _owner, address _spender, uint _value, uint _deadline, uint8 _v, bytes32 _r, bytes32 _s) external;

    function burn(uint256 _amount) external;

    // Minter functions

    function mint(address _to, uint256 _amount) external;

    // Owner Functions

    function addMinter(address _minter) external;

    function removeMinter(address _minter) external;

    function transferOwnership(address _newOwner) external;

    function claimOwnership() external;
}

/*
 Copyright (c) 2022 Radar Global

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IOracle {
    // Returns USD price with 18 decimals
    function getUSDPrice(address _token) external view returns (uint256);
}

/*
 Copyright (c) 2022 Radar Global

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ILiquidator {
    function liquidateHook(
        address _token,
        address _initiator,
        uint256 _repayAmount,
        uint256 _collateralLiquidated,
        bytes calldata data
    ) external;
}

/*
 Copyright (c) 2022 Radar Global

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface ISwapper {
    // Because of the permissions,
    // there should never be collateral or
    // stablecoin in this contract,
    // ONLY during contract execution

    // The contract will swap the received stablecoin
    // (everything it has) to collateral,
    // and then deposit everything
    // into the LendingPair
    function depositHook(
        address _collateral,
        bytes calldata data
    ) external;

    // The contract will swap the received collateral
    // (everything it has) to stablecoin,
    // and then deposit everything
    // into the LendingPair
    function repayHook(
        address _collateral,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../interfaces/ISwapper.sol";
import "./../interfaces/ILiquidator.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "./../interfaces/curve/ICurvePool.sol";
import "./../interfaces/yearn/IYearnVaultV2.sol";
import "./../interfaces/ILickHitter.sol";

contract YVWETHV2Swapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private immutable USDR;
    address private immutable WETH;
    address private immutable USDC;
    address private immutable yvWETHV2;

    address private immutable CURVE_USDR_3POOL;
    address private immutable UNISWAPV3_ROUTER;

    address private immutable yieldVault;

    constructor(
        address _usdr,
        address _weth,
        address _usdc,
        address _yvweth,
        address _curveUsdr,
        address _uniswapv3router,
        address _yv
    ) {
        USDR = _usdr;
        WETH = _weth;
        USDC = _usdc;
        yvWETHV2 = _yvweth;

        CURVE_USDR_3POOL = _curveUsdr;
        UNISWAPV3_ROUTER = _uniswapv3router;

        yieldVault = _yv;
    }

    modifier checkAllowance {
        uint256 _randomAllowance = IERC20(USDR).allowance(address(this), CURVE_USDR_3POOL);
        if (_randomAllowance <= 10**18) {
            _approveAll();
        }
        _;
    }

    function reApprove() external {
        _approveAll();
    }

    function _approveAll() internal {
        IERC20(USDR).approve(CURVE_USDR_3POOL, MAX_UINT);
        IERC20(USDC).approve(UNISWAPV3_ROUTER, MAX_UINT);
        IERC20(WETH).approve(yvWETHV2, MAX_UINT);
        IERC20(yvWETHV2).approve(yieldVault, MAX_UINT);

        IERC20(WETH).approve(UNISWAPV3_ROUTER, MAX_UINT);
        IERC20(USDC).approve(CURVE_USDR_3POOL, MAX_UINT);
        IERC20(USDR).approve(yieldVault, MAX_UINT);
    }

    // Swap USDR to yvWETHV2
    function depositHook(
        address,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _minUSDCReceive, uint256 _minWETHReceive) = abi.decode(data, (uint256, uint256));

        // Swap USDR to USDC
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_3POOL).exchange_underlying(0, 2, _usdrBal, _minUSDCReceive, address(this));

        // Swap USDC to WETH
        uint256 _receivedUSDC = IERC20(USDC).balanceOf(address(this));
        ISwapRouter.ExactInputParams memory _uniswapParams = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(
                USDC,
                uint24(500),
                WETH,
                uint24(500)
            ),
            recipient: address(this),
            deadline: block.timestamp + 1,
            amountIn: _receivedUSDC,
            amountOutMinimum: _minWETHReceive
        });
        uint256 _receivedWETH = ISwapRouter(UNISWAPV3_ROUTER).exactInput(_uniswapParams);

        // Swap WETH to yvWETHV2
        IYearnVaultV2(yvWETHV2).deposit(_receivedWETH);

        // Deposit to LickHitter
        uint256 _myBal = IERC20(yvWETHV2).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(yvWETHV2, msg.sender, _myBal);
    }

    // Swap yvWETHV2 to USDR
    function repayHook(
        address,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _minUSDCReceive, uint256 _minUSDRReceive) = abi.decode(data, (uint256, uint256));

        _swapyvWETHV22USDR(_minUSDCReceive, _minUSDRReceive);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    // Swap yvWETHV2 to USDR
    function liquidateHook(
        address,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _minUSDCReceive, uint256 _minUSDRReceive) = abi.decode(data, (uint256, uint256));

        _swapyvWETHV22USDR(_minUSDCReceive, _minUSDRReceive);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapyvWETHV22USDR(uint256 _minUSDC, uint256 _minUSDR) internal {
        // Swap yvWETHV2 to WETH
        uint256 _receivedWETH = IYearnVaultV2(yvWETHV2).withdraw();

        // Swap WETH to USDC
        ISwapRouter.ExactInputParams memory _uniswapParams = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(
                WETH,
                uint24(500),
                USDC,
                uint24(500)
            ),
            recipient: address(this),
            deadline: block.timestamp + 1,
            amountIn: _receivedWETH,
            amountOutMinimum: _minUSDC
        });
        uint256 _receivedUSDC = ISwapRouter(UNISWAPV3_ROUTER).exactInput(_uniswapParams);

        // Swap USDC to USDR
        ICurvePool(CURVE_USDR_3POOL).exchange_underlying(2, 0, _receivedUSDC, _minUSDR, address(this));
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface ICurvePool {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool);
    function add_liquidity(uint256[2] memory amounts, uint256 _min_mint_amount) external payable;
    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount, bool _use_underlying) external;
    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;
    function add_liquidity(uint256[5] memory amounts, uint256 _min_mint_amount) external;
    function remove_liquidity_one_coin(uint256 _ta, int128 i, uint256 _minAM) external;
    function remove_liquidity_one_coin(uint256 _ta, int128 i, uint256 _minAM, bool _use_underlying) external;
    function remove_liquidity(uint256 _amount, uint256[3] memory min_amounts) external;
    function get_virtual_price() external view returns (uint256);
}

interface IPayableCurvePool {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external payable returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external payable returns (uint256);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver, bool use_eth) external payable;
    function approve(address _spender, uint256 _value) external returns (bool);
    function add_liquidity(uint256[2] memory amounts, uint256 _min_mint_amount) external payable;
    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount, bool _use_underlying) external;
    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;
    function remove_liquidity_one_coin(uint256 _ta, int128 i, uint256 _minAM) external;
    function remove_liquidity_one_coin(uint256 _ta, int128 i, uint256 _minAM, bool _use_underlying) external;
    function get_virtual_price() external view returns (uint256);
}

interface ICurveCrvCvxEthPool {
    function exchange_underlying(uint256 i, uint256 j, uint256 dx, uint256 min_dy) external payable returns (uint256);
}

interface ICurveTricryptoPool {
    function exchange(uint256 i, uint256 j, uint256 dx, uint256 min_dy, bool use_eth) external payable;
}

interface IAvalancheCurvePool {
    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount) external;
    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount, bool _use_underlying) external returns (uint256);
}

interface IAvaxAv3CrvPool {
    function remove_liquidity_one_coin(uint256 _ta, int128 i, uint256 _minAM, bool _use_underlying) external returns (uint256);
    function add_liquidity(uint256[3] memory amounts, uint256 _min_mint_amount, bool _use_underlying) external returns (uint256);
}

interface IAvaxV2Pool {
    function remove_liquidity_one_coin(uint256 _ta, uint256 i, uint256 _minAM) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IYearnVaultV2 {
    function pricePerShare() external view returns (uint256);
    function token() external view returns (address);
    function decimals() external view returns (uint8);
    function deposit(uint256) external returns (uint256);
    function withdraw() external returns (uint256);
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../interfaces/ISwapper.sol";
import "./../interfaces/ILiquidator.sol";
import "./../interfaces/curve/ICurvePool.sol";
import "./../interfaces/yearn/IYearnVaultV2.sol";
import "./../interfaces/ILickHitter.sol";

contract Yearn3PoolUnderlyingSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private immutable USDR;

    address private immutable DAI;
    address private immutable USDC;
    address private immutable USDT;

    address private immutable CURVE_USDR_3POOL;

    address private immutable yieldVault;

    mapping(address => int128) private CURVE_TOKEN_IDS;

    constructor(
        address _usdr,
        address _dai,
        address _usdc,
        address _usdt,
        address _curveUsdr,
        address _yv
    ) {
        USDR = _usdr;

        DAI = _dai;
        USDC = _usdc;
        USDT = _usdt;

        CURVE_USDR_3POOL = _curveUsdr;

        yieldVault = _yv;

        CURVE_TOKEN_IDS[_dai] = 1;
        CURVE_TOKEN_IDS[_usdc] = 2;
        CURVE_TOKEN_IDS[_usdt] = 3;
    }

    modifier checkAllowance {
        uint256 _randomAllowance = IERC20(USDR).allowance(address(this), CURVE_USDR_3POOL);
        if (_randomAllowance <= 10**18) {
            _approveAll();
        }
        _;
    }

    function reApprove() external {
        _approveAll();
    }

    function _approveAll() internal {
        IERC20(USDR).safeApprove(CURVE_USDR_3POOL, MAX_UINT);

        IERC20(DAI).safeApprove(CURVE_USDR_3POOL, MAX_UINT);
        IERC20(USDC).safeApprove(CURVE_USDR_3POOL, MAX_UINT);
        IERC20(USDT).safeApprove(CURVE_USDR_3POOL, MAX_UINT);
        IERC20(USDR).safeApprove(yieldVault, MAX_UINT);
    }

    // Swap USDR to yv token
    function depositHook(
        address _collateral,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _minUnderlyingReceive) = abi.decode(data, (uint256));

        address _underlying = IYearnVaultV2(_collateral).token();
        int128 _tokenID = CURVE_TOKEN_IDS[_underlying];

        require(_tokenID > 0, "Invalid Asset");

        // Swap USDR to underlying
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_3POOL).exchange_underlying(0, _tokenID, _usdrBal, _minUnderlyingReceive, address(this));

        // Swap underlying to yvTOKEN

        // Save on SSTORE opcode, so approve is not called everytime
        uint256 _receivedUnderlying = IERC20(_underlying).balanceOf(address(this));
        uint256 _allowance = IERC20(_underlying).allowance(address(this), _collateral);
        if (_allowance < _receivedUnderlying) {
            if (_allowance != 0) {
                IERC20(_underlying).safeApprove(_collateral, 0);
            }
            IERC20(_underlying).safeApprove(_collateral, MAX_UINT);
        }
        IYearnVaultV2(_collateral).deposit(_receivedUnderlying);

        // Deposit to LickHitter
        uint256 _myBal = IERC20(_collateral).balanceOf(address(this));
        uint256 _allowance2 = IERC20(_collateral).allowance(address(this), yieldVault);
        if (_allowance2 < _myBal) {
            if (_allowance2 != 0) {
                IERC20(_collateral).safeApprove(yieldVault, 0);
            }
            IERC20(_collateral).safeApprove(yieldVault, MAX_UINT);
        }
        ILickHitter(yieldVault).deposit(_collateral, msg.sender, _myBal);
    }

    // Swap yv token to USDR
    function repayHook(
        address _collateral,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _minUSDRReceive) = abi.decode(data, (uint256));

        _swapyv2USDR(_collateral, _minUSDRReceive);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    // Swap yv token to USDR
    function liquidateHook(
        address _collateral,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _minUSDRReceive) = abi.decode(data, (uint256));

        _swapyv2USDR(_collateral, _minUSDRReceive);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapyv2USDR(address _collateral, uint256 _minUSDR) internal {
        // Swap yv token to underlying
        uint256 _receivedUnderlying = IYearnVaultV2(_collateral).withdraw();

        address _underlying = IYearnVaultV2(_collateral).token();
        int128 _tokenID = CURVE_TOKEN_IDS[_underlying];

        require(_tokenID > 0, "Invalid Asset");

        // Swap underlying to USDR
        ICurvePool(CURVE_USDR_3POOL).exchange_underlying(_tokenID, 0, _receivedUnderlying, _minUSDR, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../../interfaces/yearn/IYearnVaultV2.sol";
import "./../../interfaces/ILendingPair.sol";
import "./../../interfaces/IWETH.sol";

contract YearnDepositor {
    using SafeERC20 for IERC20;

    uint256 private constant MAX_UINT = 2**256 - 1;
    address payable private immutable WETH;

    constructor(address payable _weth) {
        WETH = _weth;
    }

    function depositYearnUnderlying(
        address _receiver,
        address _yearnAsset,
        address _yearnUnderlying,
        address _lendingPair,
        uint256 _amount,
        bool _useEth
    ) external payable {
        // Transfer underlying from user
        if (!_useEth) {
            IERC20(_yearnUnderlying).safeTransferFrom(msg.sender, address(this), _amount);
        } else {
            require(msg.value >= _amount && _yearnUnderlying == WETH, "Invalid ETH");
            IWETH9(WETH).deposit{value: msg.value}();
        }

        // Deposit to yearn
        _checkAllowanceAndApprove(_yearnUnderlying, _yearnAsset, _amount);
        IYearnVaultV2(_yearnAsset).deposit(_amount);

        // Deposit to lending pair
        uint256 _yAmount = IERC20(_yearnAsset).balanceOf(address(this));
        require(_yAmount > 0, "Safety fail");
        _checkAllowanceAndApprove(_yearnAsset, _lendingPair, _yAmount);
        ILendingPair(_lendingPair).deposit(_yAmount, _receiver);
    }

    function _checkAllowanceAndApprove(
        address _asset,
        address _spender,
        uint256 _amt
    ) internal {
        uint256 _allowance = IERC20(_asset).allowance(address(this), _spender);
        if (_allowance < _amt) {
            if (_allowance != 0) {
                IERC20(_asset).safeApprove(_spender, 0);
            }
            IERC20(_asset).safeApprove(_spender, MAX_UINT);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IWETH9 {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint);

    function allowance(address, address) external view returns (uint);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint wad) external;

    function totalSupply() external view returns (uint);

    function approve(address guy, uint wad) external returns (bool);

    function transfer(address dst, uint wad) external returns (bool);

    function transferFrom(address src, address dst, uint wad)
    external
    returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../../interfaces/yearn/IYearnVaultV2.sol";
import "./../../interfaces/ILendingPair.sol";
import "./../../interfaces/IWETH.sol";

contract CurveDepositor {
    using SafeERC20 for IERC20;

    uint256 private constant MAX_UINT = 2**256 - 1;

    function depositCurveAddLiquidity(
        address _receiver,
        address _crvLpAsset,
        address _crvPool,
        bytes calldata _curveAddLiquidityTx,
        address _underlying,
        address _lendingPair,
        uint256 _amount,
        bool _useEth
    ) external payable {
        // Transfer underlying from user
        if (!_useEth) {
            IERC20(_underlying).safeTransferFrom(msg.sender, address(this), _amount);
            _checkAllowanceAndApprove(_underlying, _crvPool, _amount);
        } else {
            require(msg.value >= _amount, "Invalid ETH");
        }

        // Deposit to curve
        (bool success,) = _crvPool.call{value: _useEth ? msg.value : 0}(_curveAddLiquidityTx);
        require(success, "Invalid LP Deposit");

        // Deposit to lending pair
        uint256 _lpAmount = IERC20(_crvLpAsset).balanceOf(address(this));
        require(_lpAmount > 0, "Safety fail");
        _checkAllowanceAndApprove(_crvLpAsset, _lendingPair, _lpAmount);
        ILendingPair(_lendingPair).deposit(_lpAmount, _receiver);
    }

    function _checkAllowanceAndApprove(
        address _asset,
        address _spender,
        uint256 _amt
    ) internal {
        uint256 _allowance = IERC20(_asset).allowance(address(this), _spender);
        if (_allowance < _amt) {
            if (_allowance != 0) {
                IERC20(_asset).safeApprove(_spender, 0);
            }
            IERC20(_asset).safeApprove(_spender, MAX_UINT);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "./../../../interfaces/benqi/IBenqiToken.sol";
import "./../../../interfaces/ILendingPair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract BenqiDepositor {
    using SafeERC20 for IERC20;

    uint256 private constant MAX_UINT = 2**256 - 1;

    address payable private constant qiAVAX = payable(0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c);

    function deposit(
        address _underlying,
        address _qiAsset,
        address _lendingPair,
        address _receiver,
        uint256 _amount
    ) external payable {
        if (_qiAsset == qiAVAX) {
            // Deposit AVAX directly
            IBenqiAvax(qiAVAX).mint{value: msg.value}();
        } else {
            IERC20(_underlying).safeTransferFrom(msg.sender, address(this), _amount);

            _checkAllowanceAndApprove(_underlying, _qiAsset, _amount);

            IBenqiToken(_qiAsset).mint(_amount);
        }

        uint256 _bal = IERC20(_qiAsset).balanceOf(address(this));
        _checkAllowanceAndApprove(_qiAsset, _lendingPair, _bal);
        ILendingPair(_lendingPair).deposit(_bal, _receiver);
    }

    function _checkAllowanceAndApprove(
        address _asset,
        address _spender,
        uint256 _amt
    ) internal {
        uint256 _allowance = IERC20(_asset).allowance(address(this), _spender);
        if (_allowance < _amt) {
            if (_allowance != 0) {
                IERC20(_asset).safeApprove(_spender, 0);
            }
            IERC20(_asset).safeApprove(_spender, MAX_UINT);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IBenqiToken {
    function mint(uint mintAmount) external returns (uint);

    function redeem(uint redeemTokens) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);

    function exchangeRateStored() external view returns (uint);
}

interface IBenqiAvax {
    function mint() external payable;

    function redeem(uint redeemTokens) external returns (uint);

    function redeemUnderlying(uint redeemAmount) external returns (uint);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../interfaces/ISwapper.sol";
import "./../interfaces/ILiquidator.sol";
import "./../interfaces/curve/ICurvePool.sol";
import "./../interfaces/ILickHitter.sol";

contract UST3PoolSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private immutable UST;
    address private immutable USDR;

    address private immutable CURVE_3POOL_TOKEN;
    address private immutable CURVE_USDR_3POOL;
    address private immutable CURVE_UST_3POOL;

    address private immutable yieldVault;

    constructor(
        address _ust,
        address _usdr,
        address _c3p,
        address _cusdr3p,
        address _cust3p,
        address _yv
    ) {
        UST = _ust;
        USDR = _usdr;

        CURVE_3POOL_TOKEN = _c3p;
        CURVE_USDR_3POOL = _cusdr3p;
        CURVE_UST_3POOL = _cust3p;

        yieldVault = _yv;
    }

    modifier checkAllowance {
        uint256 _randomAllowance = IERC20(USDR).allowance(address(this), CURVE_USDR_3POOL);
        if (_randomAllowance <= 10**18) {
            _approveAll();
        }
        _;
    }

    function reApprove() external {
        _approveAll();
    }

    function _approveAll() internal {
        IERC20(USDR).approve(CURVE_USDR_3POOL, MAX_UINT);
        IERC20(CURVE_3POOL_TOKEN).approve(CURVE_UST_3POOL, MAX_UINT);
        IERC20(UST).approve(yieldVault, MAX_UINT);

        IERC20(UST).approve(CURVE_UST_3POOL, MAX_UINT);
        IERC20(CURVE_3POOL_TOKEN).approve(CURVE_USDR_3POOL, MAX_UINT);
        IERC20(USDR).approve(yieldVault, MAX_UINT);
    }

    // Swap USDR to UST
    function depositHook(
        address,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _min3PoolReceive, uint256 _minUSTReceive) = abi.decode(data, (uint256, uint256));

        // Swap USDR to 3pool
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_3POOL).exchange(0, 1, _usdrBal, _min3PoolReceive, address(this));

        // Swap 3pool to UST
        uint256 _received3Pool = IERC20(CURVE_3POOL_TOKEN).balanceOf(address(this));
        ICurvePool(CURVE_UST_3POOL).exchange(1, 0, _received3Pool, _minUSTReceive, address(this));

        // Deposit to LickHitter
        uint256 _ustBal = IERC20(UST).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(UST, msg.sender, _ustBal);
    }

    // Swap UST to USDR
    function repayHook(
        address,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _min3PoolReceive, uint256 _minUSDRReceive) = abi.decode(data, (uint256, uint256));

        _swapUST2USDR(_min3PoolReceive, _minUSDRReceive);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    // Swap UST to USDR
    function liquidateHook(
        address,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _min3PoolReceive, uint256 _minUSDRReceive) = abi.decode(data, (uint256, uint256));

        _swapUST2USDR(_min3PoolReceive, _minUSDRReceive);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapUST2USDR(uint256 _min3Pool, uint256 _minUSDR) internal {
        // Swap UST to 3Pool
        uint256 _ustBal = IERC20(UST).balanceOf(address(this));
        ICurvePool(CURVE_UST_3POOL).exchange(0, 1, _ustBal, _min3Pool, address(this));

        // Swap 3Pool to USDR
        uint256 _received3Pool = IERC20(CURVE_3POOL_TOKEN).balanceOf(address(this));
        ICurvePool(CURVE_USDR_3POOL).exchange(1, 0, _received3Pool, _minUSDR, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../interfaces/ISwapper.sol";
import "./../interfaces/ILiquidator.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import "./../interfaces/IWETH.sol";
import "./../interfaces/curve/ICurvePool.sol";
import "./../interfaces/ILickHitter.sol";

contract CurvestETHSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address payable private immutable WETH;
    address private immutable crvstETH;
    address private immutable USDR;
    address private immutable USDC;

    address private immutable CURVE_USDR_3POOL;
    address private immutable CURVE_STETH_POOL;
    address private immutable UNISWAPV3_ROUTER;

    address private immutable yieldVault;

    constructor(
        address payable _weth,
        address _crvsteth,
        address _usdr,
        address _usdc,
        address _curveusdr,
        address _curvestheth,
        address _uniswapV3,
        address _yv
    ) {
        WETH = _weth;
        crvstETH = _crvsteth;
        USDR = _usdr;
        USDC = _usdc;

        CURVE_USDR_3POOL = _curveusdr;
        CURVE_STETH_POOL = _curvestheth;
        UNISWAPV3_ROUTER = _uniswapV3;

        yieldVault = _yv;
    }

    modifier checkAllowance {
        uint256 _randomAllowance = IERC20(USDR).allowance(address(this), CURVE_USDR_3POOL);
        if (_randomAllowance <= 10**18) {
            _approveAll();
        }
        _;
    }

    function reApprove() external {
        _approveAll();
    }

    function _approveAll() internal {
        IERC20(USDR).safeApprove(CURVE_USDR_3POOL, MAX_UINT);
        IERC20(USDC).safeApprove(UNISWAPV3_ROUTER, MAX_UINT);
        IERC20(crvstETH).safeApprove(yieldVault, MAX_UINT);

        IERC20(crvstETH).safeApprove(CURVE_STETH_POOL, MAX_UINT);
        IERC20(WETH).safeApprove(UNISWAPV3_ROUTER, MAX_UINT);
        IERC20(USDC).safeApprove(CURVE_USDR_3POOL, MAX_UINT);
        IERC20(USDR).safeApprove(yieldVault, MAX_UINT);
    }

    // Swap USDR to crvstETH
    function depositHook(
        address,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _minUSDC, uint256 _minWETH, uint256 _mincrvstETH) = abi.decode(data, (uint256,uint256,uint256));

        // Swap USDR to USDC
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_3POOL).exchange_underlying(0, 2, _usdrBal, _minUSDC, address(this));

        // Swap USDC to WETH
        uint256 _receivedUSDC = IERC20(USDC).balanceOf(address(this));
        ISwapRouter.ExactInputParams memory _uniswapParams = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(
                USDC,
                uint24(500),
                WETH,
                uint24(500)
            ),
            recipient: address(this),
            deadline: block.timestamp + 1,
            amountIn: _receivedUSDC,
            amountOutMinimum: _minWETH
        });
        ISwapRouter(UNISWAPV3_ROUTER).exactInput(_uniswapParams);

        // Swap WETH to ETH
        uint256 _receivedWETH = IERC20(WETH).balanceOf(address(this));
        IWETH9(WETH).withdraw(_receivedWETH);

        // Swap ETH to crvstETH
        ICurvePool(CURVE_STETH_POOL).add_liquidity{value: _receivedWETH}([_receivedWETH, 0], _mincrvstETH);

        // Deposit to LickHitter
        uint256 _crvstETHBal = IERC20(crvstETH).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(crvstETH, msg.sender, _crvstETHBal);
    }

    // Swap crvstETH to USDR
    function repayHook(
        address,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _minETH, uint256 _minUSDC, uint256 _minUSDR) = abi.decode(data, (uint256, uint256, uint256));

        _swapcrvstETH2USDR(_minETH, _minUSDC, _minUSDR);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    // Swap yvWETHV2 to USDR
    function liquidateHook(
        address,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _minETH, uint256 _minUSDC, uint256 _minUSDR) = abi.decode(data, (uint256, uint256, uint256));

        _swapcrvstETH2USDR(_minETH, _minUSDC, _minUSDR);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapcrvstETH2USDR(uint256 _minETH, uint256 _minUSDC, uint256 _minUSDR) internal {

        // Swap crvstETH to ETH
        uint256 _crvstETHBal = IERC20(crvstETH).balanceOf(address(this));
        ICurvePool(CURVE_STETH_POOL).remove_liquidity_one_coin(_crvstETHBal, 0, _minETH);

        // Swap ETH to WETH
        IWETH9(WETH).deposit{value: address(this).balance}();

        // Swap WETH to USDC
        uint256 _wethBal = IERC20(WETH).balanceOf(address(this));
        ISwapRouter.ExactInputParams memory _uniswapParams = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(
                WETH,
                uint24(500),
                USDC,
                uint24(500)
            ),
            recipient: address(this),
            deadline: block.timestamp + 1,
            amountIn: _wethBal,
            amountOutMinimum: _minUSDC
        });
        ISwapRouter(UNISWAPV3_ROUTER).exactInput(_uniswapParams);

        // Swap USDC to USDR
        uint256 _receivedUSDC = IERC20(USDC).balanceOf(address(this));
        ICurvePool(CURVE_USDR_3POOL).exchange_underlying(2, 0, _receivedUSDC, _minUSDR, address(this));
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../interfaces/ISwapper.sol";
import "./../interfaces/ILiquidator.sol";
import "./../interfaces/curve/ICurvePool.sol";
import "./../interfaces/ILickHitter.sol";

contract CurveIronbankSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private immutable crvIB;
    address private immutable USDC;
    address private immutable USDR;

    address private immutable CURVE_USDR_3POOL;
    address private immutable CURVE_IRONBANK_3POOL;

    address private immutable yieldVault;

    constructor(
        address _crvIB,
        address _usdc,
        address _usdr,
        address _cusdr3p,
        address _cib3p,
        address _yv
    ) {
        crvIB = _crvIB;
        USDC = _usdc;
        USDR = _usdr;

        CURVE_USDR_3POOL = _cusdr3p;
        CURVE_IRONBANK_3POOL = _cib3p;

        yieldVault = _yv;
    }

    modifier checkAllowance {
        uint256 _randomAllowance = IERC20(USDR).allowance(address(this), CURVE_USDR_3POOL);
        if (_randomAllowance <= 10**18) {
            _approveAll();
        }
        _;
    }

    function reApprove() external {
        _approveAll();
    }

    function _approveAll() internal {
        IERC20(USDR).safeApprove(CURVE_USDR_3POOL, MAX_UINT);
        IERC20(USDC).safeApprove(CURVE_IRONBANK_3POOL, MAX_UINT);
        IERC20(crvIB).safeApprove(yieldVault, MAX_UINT);

        IERC20(crvIB).safeApprove(CURVE_IRONBANK_3POOL, MAX_UINT);
        IERC20(USDC).safeApprove(CURVE_USDR_3POOL, MAX_UINT);
        IERC20(USDR).safeApprove(yieldVault, MAX_UINT);
    }

    // Swap USDR to crvIB
    function depositHook(
        address,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _minUSDC, uint256 _mincrvIB) = abi.decode(data, (uint256, uint256));

        // Swap USDR to USDC
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_3POOL).exchange_underlying(0, 2, _usdrBal, _minUSDC, address(this));

        // Swap USDC to crvIB
        uint256 _receivedUSDC = IERC20(USDC).balanceOf(address(this));
        ICurvePool(CURVE_IRONBANK_3POOL).add_liquidity([0, _receivedUSDC, 0], _mincrvIB, true);

        // Deposit to LickHitter
        uint256 _crvIBBal = IERC20(crvIB).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(crvIB, msg.sender, _crvIBBal);
    }

    // Swap crvIB to USDR
    function repayHook(
        address,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _minUSDC, uint256 _minUSDR) = abi.decode(data, (uint256, uint256));

        _swapcrvIB2USDR(_minUSDC, _minUSDR);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    // Swap crvIB to USDR
    function liquidateHook(
        address,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _minUSDC, uint256 _minUSDR) = abi.decode(data, (uint256, uint256));

        _swapcrvIB2USDR(_minUSDC, _minUSDR);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapcrvIB2USDR(uint256 _minUSDC, uint256 _minUSDR) internal {
        // Swap crvIB to USDC
        uint256 _crvIBBal = IERC20(crvIB).balanceOf(address(this));
        ICurvePool(CURVE_IRONBANK_3POOL).remove_liquidity_one_coin(_crvIBBal, 1, _minUSDC, true);

        // Swap USDC to USDR
        uint256 _usdcBal = IERC20(USDC).balanceOf(address(this));
        ICurvePool(CURVE_USDR_3POOL).exchange_underlying(2, 0, _usdcBal, _minUSDR, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "./../../../interfaces/IWETH.sol";
import "./../../../interfaces/ILendingPair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AvaxWrapperDepositor {
    using SafeERC20 for IERC20;

    uint256 private constant MAX_UINT = 2**256 - 1;

    address payable private constant WAVAX = payable(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    function deposit(
        address _lendingPair,
        address _receiver
    ) external payable {
        uint256 _amount = msg.value;

        IWETH9(WAVAX).deposit{value: _amount}();

        _checkAllowanceAndApprove(WAVAX, _lendingPair, _amount);
        ILendingPair(_lendingPair).deposit(_amount, _receiver);
    }

    function _checkAllowanceAndApprove(
        address _asset,
        address _spender,
        uint256 _amt
    ) internal {
        uint256 _allowance = IERC20(_asset).allowance(address(this), _spender);
        if (_allowance < _amt) {
            if (_allowance != 0) {
                IERC20(_asset).safeApprove(_spender, 0);
            }
            IERC20(_asset).safeApprove(_spender, MAX_UINT);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../interfaces/ISwapper.sol";
import "./../interfaces/ILiquidator.sol";
import "./../interfaces/curve/ICurvePool.sol";
import "./../interfaces/ILickHitter.sol";

contract CurveFRAXSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private immutable crvFRAX;
    address private immutable USDR;

    address private immutable CURVE_3POOL_TOKEN;
    address private immutable CURVE_USDR_3POOL;
    address private immutable CURVE_FRAX_3POOL;

    address private immutable yieldVault;

    constructor(
        address _crvFRAX,
        address _usdr,
        address _c3p,
        address _cusdr3p,
        address _cfrax3p,
        address _yv
    ) {
        crvFRAX = _crvFRAX;
        USDR = _usdr;

        CURVE_3POOL_TOKEN = _c3p;
        CURVE_USDR_3POOL = _cusdr3p;
        CURVE_FRAX_3POOL = _cfrax3p;

        yieldVault = _yv;
    }

    modifier checkAllowance {
        uint256 _randomAllowance = IERC20(USDR).allowance(address(this), CURVE_USDR_3POOL);
        if (_randomAllowance <= 10**18) {
            _approveAll();
        }
        _;
    }

    function reApprove() external {
        _approveAll();
    }

    function _approveAll() internal {
        IERC20(USDR).safeApprove(CURVE_USDR_3POOL, MAX_UINT);
        IERC20(CURVE_3POOL_TOKEN).safeApprove(CURVE_FRAX_3POOL, MAX_UINT);
        IERC20(crvFRAX).safeApprove(yieldVault, MAX_UINT);

        IERC20(CURVE_3POOL_TOKEN).safeApprove(CURVE_USDR_3POOL, MAX_UINT);
        IERC20(USDR).safeApprove(yieldVault, MAX_UINT);
    }

    // Swap USDR to crvFRAX
    function depositHook(
        address,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _min3Pool, uint256 _mincrvFRAX) = abi.decode(data, (uint256, uint256));

        // Swap USDR to 3pool
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_3POOL).exchange(0, 1, _usdrBal, _min3Pool, address(this));

        // Swap 3pool to crvFRAX
        uint256 _received3Pool = IERC20(CURVE_3POOL_TOKEN).balanceOf(address(this));
        ICurvePool(CURVE_FRAX_3POOL).add_liquidity([0, _received3Pool], _mincrvFRAX);

        // Deposit to LickHitter
        uint256 _crvFRAXBal = IERC20(crvFRAX).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(crvFRAX, msg.sender, _crvFRAXBal);
    }

    // Swap crvFRAX to USDR
    function repayHook(
        address,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _min3Pool, uint256 _minUSDR) = abi.decode(data, (uint256, uint256));

        _swapcrvFRAX2USDR(_min3Pool, _minUSDR);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    // Swap crvFRAX to USDR
    function liquidateHook(
        address,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override checkAllowance {
        (uint256 _min3Pool, uint256 _minUSDR) = abi.decode(data, (uint256, uint256));

        _swapcrvFRAX2USDR(_min3Pool, _minUSDR);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapcrvFRAX2USDR(uint256 _min3Pool, uint256 _minUSDR) internal {
        // Swap crvFRAX to 3Pool
        uint256 _crvFRAXBal = IERC20(crvFRAX).balanceOf(address(this));
        ICurvePool(CURVE_FRAX_3POOL).remove_liquidity_one_coin(_crvFRAXBal, 1, _min3Pool);

        // Swap 3Pool to USDR
        uint256 _3poolBal = IERC20(CURVE_3POOL_TOKEN).balanceOf(address(this));
        ICurvePool(CURVE_USDR_3POOL).exchange(1, 0, _3poolBal, _minUSDR, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../../interfaces/ISwapper.sol";
import "./../../interfaces/ILiquidator.sol";
import "./../../interfaces/curve/ICurvePool.sol";
import "./../../interfaces/ILickHitter.sol";
import "./../../interfaces/aave/ILendingPool.sol";

contract CurveTricryptoUnderlyingSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private immutable yieldVault;

    address private immutable USDR;
    address private immutable CURVE_USDR_av3Crv_POOL;

    address private constant tricryptoPOOL = 0xB755B949C126C04e0348DD881a5cF55d424742B2;
    address private constant AAVE_LENDING_POOL = 0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C;

    address private constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
    address private constant wETH = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
    address private constant wBTC = 0x50b7545627a5162F82A992c33b87aDc75187B218;
    address private constant avwETH = 0x53f7c5869a859F0AeC3D334ee8B4Cf01E3492f21;
    address private constant avwBTC = 0x686bEF2417b6Dc32C50a3cBfbCC3bb60E1e9a15D;

    constructor(
        address _yv,
        address _usdr,
        address _usdrPool
    ) {
        yieldVault = _yv;
        USDR = _usdr;
        CURVE_USDR_av3Crv_POOL = _usdrPool;

        IERC20(_usdr).safeApprove(_usdrPool, MAX_UINT);
        IERC20(av3Crv).safeApprove(tricryptoPOOL, MAX_UINT);
        IERC20(wETH).safeApprove(_yv, MAX_UINT);
        IERC20(wBTC).safeApprove(_yv, MAX_UINT);

        IERC20(wETH).safeApprove(AAVE_LENDING_POOL, MAX_UINT);
        IERC20(wBTC).safeApprove(AAVE_LENDING_POOL, MAX_UINT);
        IERC20(avwETH).safeApprove(tricryptoPOOL, MAX_UINT);
        IERC20(avwBTC).safeApprove(tricryptoPOOL, MAX_UINT);
        IERC20(av3Crv).safeApprove(_usdrPool, MAX_UINT);
        IERC20(_usdr).safeApprove(_yv, MAX_UINT);
    }

    function depositHook(
        address _collateral,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minAsset) = abi.decode(data, (uint256,uint256));

        // Swap USDR to av3Crv
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(0, 1, _usdrBal, _minav3Crv, address(this));

        // Swap av3Crv to avAsset
        uint256 _avBal = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(tricryptoPOOL).exchange(0, _getTokenId(_collateral), _avBal, _minAsset);

        // Swap avAsset to Asset
        ILendingPool(AAVE_LENDING_POOL).withdraw(_collateral, MAX_UINT, address(this));

        // Deposit to LickHitter
        uint256 _colBal = IERC20(_collateral).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(_collateral, msg.sender, _colBal);
    }

    function repayHook(
        address _collateral,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256));

        _swapAsset2USDR(_collateral, _minav3Crv, _minUSDR);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    function liquidateHook(
        address _collateral,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256));

        _swapAsset2USDR(_collateral, _minav3Crv, _minUSDR);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapAsset2USDR(address _collateral, uint256 _minav3Crv, uint256 _minUSDR) internal {
        // Swap asset to avAsset
        uint256 _colBal = IERC20(_collateral).balanceOf(address(this));
        ILendingPool(AAVE_LENDING_POOL).deposit(_collateral, _colBal, address(this), 0);

        // Swap avAsset to av3Crv
        uint256 _avBal = IERC20(_toggleAaveUnderlyingAsset(_collateral)).balanceOf(address(this));
        ICurvePool(tricryptoPOOL).exchange(_getTokenId(_collateral), 0, _avBal, _minav3Crv);

        // Swap av3Crv to USDR
        uint256 _av3Bal = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(1, 0, _av3Bal, _minUSDR, address(this));
    }

    function _getTokenId(address _token) internal pure returns (uint256) {
        if (_token == wETH) {
            return 2;
        } else if (_token == wBTC) {
            return 1;
        } else {
            return 100; // error
        }
    }

    function _toggleAaveUnderlyingAsset(address _asset) internal pure returns (address) {
        if (_asset == avwETH) {
            return wETH;
        } else if(_asset == avwBTC) {
            return wBTC;
        } else if (_asset == wETH) {
            return avwETH;
        } else if(_asset == wBTC) {
            return avwBTC;
        } else {
            return address(0); // error
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.2;

interface ILendingPool {
  /**
   * @dev Deposits an `amount` of underlying asset into the reserve, receiving in return overlying aTokens.
   * - E.g. User deposits 100 USDC and gets in return 100 aUSDC
   * @param asset The address of the underlying asset to deposit
   * @param amount The amount to be deposited
   * @param onBehalfOf The address that will receive the aTokens, same as msg.sender if the user
   *   wants to receive them on his own wallet, or a different address if the beneficiary of aTokens
   *   is a different wallet
   * @param referralCode Code used to register the integrator originating the operation, for potential rewards.
   *   0 if the action is executed directly by the user, without any middle-man
   **/
  function deposit(
    address asset,
    uint256 amount,
    address onBehalfOf,
    uint16 referralCode
  ) external;

  /**
   * @dev Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned
   * E.g. User has 100 aUSDC, calls withdraw() and receives 100 USDC, burning the 100 aUSDC
   * @param asset The address of the underlying asset to withdraw
   * @param amount The underlying amount to be withdrawn
   *   - Send the value type(uint256).max in order to withdraw the whole aToken balance
   * @param to Address that will receive the underlying, same as msg.sender if the user
   *   wants to receive it on his own wallet, or a different address if the beneficiary is a
   *   different wallet
   * @return The final amount withdrawn
   **/
  function withdraw(
    address asset,
    uint256 amount,
    address to
  ) external returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../../interfaces/ISwapper.sol";
import "./../../interfaces/ILiquidator.sol";
import "./../../interfaces/curve/ICurvePool.sol";
import "./../../interfaces/ILickHitter.sol";
import "./../../interfaces/aave/ILendingPool.sol";
import "./../../interfaces/benqi/IBenqiToken.sol";

contract BenqiCurveTricryptoUnderlyingSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private immutable yieldVault;

    address private immutable USDR;
    address private immutable CURVE_USDR_av3Crv_POOL;

    address private constant tricryptoPOOL = 0xB755B949C126C04e0348DD881a5cF55d424742B2;
    address private constant AAVE_LENDING_POOL = 0x4F01AeD16D97E3aB5ab2B501154DC9bb0F1A5A2C;

    address private constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
    address private constant wETH = 0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB;
    address private constant wBTC = 0x50b7545627a5162F82A992c33b87aDc75187B218;
    address private constant avwETH = 0x53f7c5869a859F0AeC3D334ee8B4Cf01E3492f21;
    address private constant avwBTC = 0x686bEF2417b6Dc32C50a3cBfbCC3bb60E1e9a15D;

    address private constant qiBTC = 0xe194c4c5aC32a3C9ffDb358d9Bfd523a0B6d1568;
    address private constant qiETH = 0x334AD834Cd4481BB02d09615E7c11a00579A7909;

    constructor(
        address _yv,
        address _usdr,
        address _usdrPool
    ) {
        yieldVault = _yv;
        USDR = _usdr;
        CURVE_USDR_av3Crv_POOL = _usdrPool;

        IERC20(_usdr).safeApprove(_usdrPool, MAX_UINT);
        IERC20(av3Crv).safeApprove(tricryptoPOOL, MAX_UINT);
        IERC20(wETH).safeApprove(qiETH, MAX_UINT);
        IERC20(wBTC).safeApprove(qiBTC, MAX_UINT);
        IERC20(qiETH).safeApprove(_yv, MAX_UINT);
        IERC20(qiBTC).safeApprove(_yv, MAX_UINT);

        IERC20(wETH).safeApprove(AAVE_LENDING_POOL, MAX_UINT);
        IERC20(wBTC).safeApprove(AAVE_LENDING_POOL, MAX_UINT);
        IERC20(avwETH).safeApprove(tricryptoPOOL, MAX_UINT);
        IERC20(avwBTC).safeApprove(tricryptoPOOL, MAX_UINT);
        IERC20(av3Crv).safeApprove(_usdrPool, MAX_UINT);
        IERC20(_usdr).safeApprove(_yv, MAX_UINT);
    }

    function depositHook(
        address _collateral,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minAsset) = abi.decode(data, (uint256,uint256));

        // Swap USDR to av3Crv
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(0, 1, _usdrBal, _minav3Crv, address(this));

        // Swap av3Crv to avAsset
        uint256 _avBal = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(tricryptoPOOL).exchange(0, _getTokenId(_collateral), _avBal, _minAsset);

        // Swap avAsset to Asset
        ILendingPool(AAVE_LENDING_POOL).withdraw(_toggleQiUnderlyingAsset(_collateral), MAX_UINT, address(this));

        // Swap Asset to qiAsset
        uint256 _assetBal = IERC20(_toggleQiUnderlyingAsset(_collateral)).balanceOf(address(this));
        IBenqiToken(_collateral).mint(_assetBal);

        // Deposit to LickHitter
        uint256 _colBal = IERC20(_collateral).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(_collateral, msg.sender, _colBal);
    }

    function repayHook(
        address _collateral,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256));

        _swapAsset2USDR(_collateral, _minav3Crv, _minUSDR);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    function liquidateHook(
        address _collateral,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256));

        _swapAsset2USDR(_collateral, _minav3Crv, _minUSDR);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapAsset2USDR(address _collateral, uint256 _minav3Crv, uint256 _minUSDR) internal {
        // Swap qiAsset to asset
        uint256 _qiBal = IERC20(_collateral).balanceOf(address(this));
        IBenqiToken(_collateral).redeem(_qiBal);
        
        // Swap asset to avAsset
        uint256 _colBal = IERC20(_toggleQiUnderlyingAsset(_collateral)).balanceOf(address(this));
        ILendingPool(AAVE_LENDING_POOL).deposit(_toggleQiUnderlyingAsset(_collateral), _colBal, address(this), 0);

        // Swap avAsset to av3Crv
        uint256 _avBal = IERC20(_toggleAaveUnderlyingAsset(_collateral)).balanceOf(address(this));
        ICurvePool(tricryptoPOOL).exchange(_getTokenId(_collateral), 0, _avBal, _minav3Crv);

        // Swap av3Crv to USDR
        uint256 _av3Bal = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(1, 0, _av3Bal, _minUSDR, address(this));
    }

    function _getTokenId(address _token) internal pure returns (uint256) {
        if (_token == qiETH) {
            return 2;
        } else if (_token == qiBTC) {
            return 1;
        } else {
            return 100; // error
        }
    }

    function _toggleQiUnderlyingAsset(address _asset) internal pure returns (address) {
        if (_asset == qiETH) {
            return wETH;
        } else if(_asset == qiBTC) {
            return wBTC;
        } else if (_asset == wETH) {
            return qiETH;
        } else if(_asset == wBTC) {
            return qiBTC;
        } else {
            return address(0); // error
        }
    }

    function _toggleAaveUnderlyingAsset(address _asset) internal pure returns (address) {
        if (_asset == avwETH) {
            return wETH;
        } else if(_asset == avwBTC) {
            return wBTC;
        } else if (_asset == qiETH) {
            return avwETH;
        } else if(_asset == qiBTC) {
            return avwBTC;
        } else {
            return address(0); // error
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../../interfaces/ISwapper.sol";
import "./../../interfaces/ILiquidator.sol";
import "./../../interfaces/curve/ICurvePool.sol";
import "./../../interfaces/ILickHitter.sol";
import "./../../interfaces/benqi/IBenqiToken.sol";

contract BenqiCurveAaveUnderlyingSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private immutable yieldVault;

    address private immutable USDR;
    address private immutable CURVE_USDR_av3Crv_POOL;

    address private constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
    address private constant av3Crv_POOL = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;

    address private constant DAI = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address private constant USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address private constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    address private constant qiDAI = 0x835866d37AFB8CB8F8334dCCdaf66cf01832Ff5D;
    address private constant qiUSDC = 0xBEb5d47A3f720Ec0a390d04b4d41ED7d9688bC7F;
    address private constant qiUSDT = 0xc9e5999b8e75C3fEB117F6f73E664b9f3C8ca65C;

    constructor(
        address _yv,
        address _usdr,
        address _usdrPool
    ) {
        yieldVault = _yv;
        USDR = _usdr;
        CURVE_USDR_av3Crv_POOL = _usdrPool;

        IERC20(_usdr).safeApprove(_usdrPool, MAX_UINT);
        IERC20(DAI).safeApprove(qiDAI, MAX_UINT);
        IERC20(USDC).safeApprove(qiUSDC, MAX_UINT);
        IERC20(USDT).safeApprove(qiUSDT, MAX_UINT);
        IERC20(qiDAI).safeApprove(_yv, MAX_UINT);
        IERC20(qiUSDC).safeApprove(_yv, MAX_UINT);
        IERC20(qiUSDT).safeApprove(_yv, MAX_UINT);

        IERC20(DAI).safeApprove(av3Crv_POOL, MAX_UINT);
        IERC20(USDC).safeApprove(av3Crv_POOL, MAX_UINT);
        IERC20(USDT).safeApprove(av3Crv_POOL, MAX_UINT);
        IERC20(av3Crv).safeApprove(_usdrPool, MAX_UINT);
        IERC20(_usdr).safeApprove(_yv, MAX_UINT);
    }

    function depositHook(
        address _collateral,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minAsset) = abi.decode(data, (uint256,uint256));

        // Swap USDR to av3Crv
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(0, 1, _usdrBal, _minav3Crv, address(this));

        // Swap av3Crv to asset
        uint256 _av3CrvBal = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(av3Crv_POOL).remove_liquidity_one_coin(_av3CrvBal, _getTokenId(_collateral), _minAsset, true);

        // Swap asset to qiAsset
        uint256 _assetBal = IERC20(_toggleQIUnderlying(_collateral)).balanceOf(address(this));
        IBenqiToken(_collateral).mint(_assetBal);

        // Deposit to LickHitter
        uint256 _colBal = IERC20(_collateral).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(_collateral, msg.sender, _colBal);
    }

    function repayHook(
        address _collateral,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256));

        _swapAsset2USDR(_collateral, _minav3Crv, _minUSDR);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    function liquidateHook(
        address _collateral,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256));

        _swapAsset2USDR(_collateral, _minav3Crv, _minUSDR);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapAsset2USDR(address _token, uint256 _minav3Crv, uint256 _minUSDR) internal {
        uint256 _qiAssetBal = IERC20(_token).balanceOf(address(this));
        IBenqiToken(_token).redeem(_qiAssetBal);

        uint256 _assetBal = IERC20(_toggleQIUnderlying(_token)).balanceOf(address(this));
        ICurvePool(av3Crv_POOL).add_liquidity(_getAmounts(_token, _assetBal), _minav3Crv, true);

        uint256 _avBal = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(1, 0, _avBal, _minUSDR, address(this));
    }

    function _getTokenId(address _token) internal pure returns (int128) {
        if  (_token == qiDAI) {
            return 0;
        } else if (_token == qiUSDC) {
            return 1;
        } else if (_token == qiUSDT) {
            return 2;
        } else {
            return 100; // Invalid
        }
    }

    function _toggleQIUnderlying(address _token) internal pure returns (address) {
        if  (_token == qiDAI) {
            return DAI;
        } else if (_token == qiUSDC) {
            return USDC;
        } else if (_token == qiUSDT) {
            return USDT;
        } else {
            return address(0); // Invalid
        }
    }

    function _getAmounts(address _token, uint256 _bal) internal pure returns (uint256[3] memory) {
        if  (_token == qiDAI) {
            return [_bal, 0, 0];
        } else if (_token == qiUSDC) {
            return [0, _bal, 0];
        } else if (_token == qiUSDT) {
            return [0, 0, _bal];
        } else {
            return [_bal, _bal, _bal]; // Invalid
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../../interfaces/ISwapper.sol";
import "./../../interfaces/ILiquidator.sol";
import "./../../interfaces/curve/ICurvePool.sol";
import "./../../interfaces/ILickHitter.sol";
import "./../../interfaces/traderjoe/IJoeRouter02.sol";
import "./../../interfaces/benqi/IBenqiToken.sol";

contract BenqiAvaxSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private yieldVault;

    address private immutable USDR;
    address private immutable CURVE_USDR_av3Crv_POOL;

    address payable private constant JOE_ROUTER = payable(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    address private constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address private constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address private constant av3Crv_POOL = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
    address private constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
    address payable private constant qiAVAX = payable(0x5C0401e81Bc07Ca70fAD469b451682c0d747Ef1c);

    constructor(
        address _yv,
        address _usdr,
        address _curveUsdrPool
    ) {
        yieldVault = _yv;
        USDR = _usdr;
        CURVE_USDR_av3Crv_POOL = _curveUsdrPool;

        IERC20(_usdr).safeApprove(_curveUsdrPool, MAX_UINT);
        IERC20(av3Crv).safeApprove(av3Crv_POOL, MAX_UINT);
        IERC20(USDT).safeApprove(JOE_ROUTER, MAX_UINT);
        IERC20(qiAVAX).safeApprove(_yv, MAX_UINT);

        IERC20(USDT).safeApprove(av3Crv_POOL, MAX_UINT);
        IERC20(av3Crv).safeApprove(_curveUsdrPool, MAX_UINT);
        IERC20(_usdr).safeApprove(_yv, MAX_UINT);
    }

    // Swap USDR to wAVAX
    function depositHook(
        address,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minUSDT, uint256 _minwAVAX) = abi.decode(data, (uint256,uint256,uint256));

        // Swap USDR to av3Crv
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(0, 1, _usdrBal, _minav3Crv, address(this));

        // Swap av3Crv to USDT
        uint256 _receivedav3Crv = IERC20(av3Crv).balanceOf(address(this));
        uint256 _receivedUSDT = IAvaxAv3CrvPool(av3Crv_POOL).remove_liquidity_one_coin(_receivedav3Crv, 2, _minUSDT, true);

        // Swap USDT to AVAX
        address[] memory _path = new address[](2);
        _path[0] = USDT;
        _path[1] = WAVAX;
        
        IJoeRouter02(JOE_ROUTER).swapExactTokensForAVAX(
            _receivedUSDT,
            _minwAVAX,
            _path,
            address(this),
            block.timestamp + 1
        );

        // Swap AVAX to qiAVAX
        IBenqiAvax(qiAVAX).mint{value: address(this).balance}();

        // Deposit to LickHitter
        uint256 _qiAVAXBal = IERC20(qiAVAX).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(qiAVAX, msg.sender, _qiAVAXBal);
    }

    function repayHook(
        address,
         bytes calldata data
    ) external override {
        (uint256 _minUSDT, uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256,uint256));

        _swapwAVAX2USDR(_minUSDT, _minav3Crv, _minUSDR);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    function liquidateHook(
        address,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override {
         (uint256 _minUSDT, uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256,uint256));

        _swapwAVAX2USDR(_minUSDT, _minav3Crv, _minUSDR);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapwAVAX2USDR(uint256 _minUSDT, uint256 _minav3Crv, uint256 _minUSDR) internal {
        // Swap qiAVAX to AVAX
        uint256 _qiAvaxBal = IERC20(qiAVAX).balanceOf(address(this));
        IBenqiAvax(qiAVAX).redeem(_qiAvaxBal);

        // Swap AVAX to USDT
        address[] memory _path = new address[](2);
        _path[0] = WAVAX;
        _path[1] = USDT;
        
        IJoeRouter02(JOE_ROUTER).swapExactAVAXForTokens{value: address(this).balance}(
            _minUSDT,
            _path,
            address(this),
            block.timestamp + 1
        );

        // Swap USDT to av3Crv
        uint256 _usdtBal = IERC20(USDT).balanceOf(address(this));
        IAvaxAv3CrvPool(av3Crv_POOL).add_liquidity([0, 0, _usdtBal], _minav3Crv, true);

        // Swap av3Crv to USDT
        uint256 _receivedav3Crv = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(1, 0, _receivedav3Crv, _minUSDR, address(this));
    }

    receive() external payable {}
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

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

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../../interfaces/ISwapper.sol";
import "./../../interfaces/ILiquidator.sol";
import "./../../interfaces/curve/ICurvePool.sol";
import "./../../interfaces/ILickHitter.sol";
import "./../../interfaces/traderjoe/IJoeRouter02.sol";

contract BenqiStakedAvaxSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private yieldVault;

    address private immutable USDR;
    address private immutable CURVE_USDR_av3Crv_POOL;

    address private constant SAVAX = 0x2b2C81e08f1Af8835a78Bb2A90AE924ACE0eA4bE;
    address private constant JOE_ROUTER = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    address private constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address private constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address private constant av3Crv_POOL = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
    address private constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;

    constructor(
        address _yv,
        address _usdr,
        address _curveUsdrPool
    ) {
        yieldVault = _yv;
        USDR = _usdr;
        CURVE_USDR_av3Crv_POOL = _curveUsdrPool;

        IERC20(_usdr).safeApprove(_curveUsdrPool, MAX_UINT);
        IERC20(av3Crv).safeApprove(av3Crv_POOL, MAX_UINT);
        IERC20(USDT).safeApprove(JOE_ROUTER, MAX_UINT);
        IERC20(SAVAX).safeApprove(_yv, MAX_UINT);

        IERC20(SAVAX).safeApprove(JOE_ROUTER, MAX_UINT);
        IERC20(USDT).safeApprove(av3Crv_POOL, MAX_UINT);
        IERC20(av3Crv).safeApprove(_curveUsdrPool, MAX_UINT);
        IERC20(_usdr).safeApprove(_yv, MAX_UINT);
    }

    function depositHook(
        address,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minUSDT, uint256 _minsAVAX) = abi.decode(data, (uint256,uint256,uint256));

        // Swap USDR to av3Crv
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(0, 1, _usdrBal, _minav3Crv, address(this));

        // Swap av3Crv to USDT
        uint256 _receivedav3Crv = IERC20(av3Crv).balanceOf(address(this));
        IAvaxAv3CrvPool(av3Crv_POOL).remove_liquidity_one_coin(_receivedav3Crv, 2, _minUSDT, true);

        // Swap USDT to SAVAX
        uint256 _receivedUSDT = IERC20(USDT).balanceOf(address(this));
        address[] memory _path = new address[](3);
        _path[0] = USDT;
        _path[1] = WAVAX;
        _path[2] = SAVAX;
        
        IJoeRouter02(JOE_ROUTER).swapExactTokensForTokens(
            _receivedUSDT,
            _minsAVAX,
            _path,
            address(this),
            block.timestamp + 1
        );

        // Deposit to LickHitter
        uint256 _sAVAXBal = IERC20(SAVAX).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(SAVAX, msg.sender, _sAVAXBal);
    }

    function repayHook(
        address,
         bytes calldata data
    ) external override {
        (uint256 _minUSDT, uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256,uint256));

        _swapsAVAX2USDR(_minUSDT, _minav3Crv, _minUSDR);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    function liquidateHook(
        address,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override {
        (uint256 _minUSDT, uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256,uint256));

        _swapsAVAX2USDR(_minUSDT, _minav3Crv, _minUSDR);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapsAVAX2USDR(uint256 _minUSDT, uint256 _minav3Crv, uint256 _minUSDR) internal {
        // Swap sAVAX to USDT
        uint256 _sAVAXBal = IERC20(SAVAX).balanceOf(address(this));
        address[] memory _path = new address[](3);
        _path[0] = SAVAX;
        _path[1] = WAVAX;
        _path[2] = USDT;
        
        IJoeRouter02(JOE_ROUTER).swapExactTokensForTokens(
            _sAVAXBal,
            _minUSDT,
            _path,
            address(this),
            block.timestamp + 1
        );

        // Swap USDT to av3Crv
        uint256 _usdtBal = IERC20(USDT).balanceOf(address(this));
        IAvaxAv3CrvPool(av3Crv_POOL).add_liquidity([0, 0, _usdtBal], _minav3Crv, true);

        // Swap av3Crv to USDR
        uint256 _receivedav3Crv = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(1, 0, _receivedav3Crv, _minUSDR, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../../interfaces/ISwapper.sol";
import "./../../interfaces/ILiquidator.sol";
import "./../../interfaces/curve/ICurvePool.sol";
import "./../../interfaces/ILickHitter.sol";
import "./../../interfaces/traderjoe/IJoeRouter02.sol";

contract AvaxSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private yieldVault;

    address private immutable USDR;
    address private immutable CURVE_USDR_av3Crv_POOL;

    address private constant JOE_ROUTER = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    address private constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address private constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address private constant av3Crv_POOL = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
    address private constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;

    constructor(
        address _yv,
        address _usdr,
        address _curveUsdrPool
    ) {
        yieldVault = _yv;
        USDR = _usdr;
        CURVE_USDR_av3Crv_POOL = _curveUsdrPool;

        IERC20(_usdr).safeApprove(_curveUsdrPool, MAX_UINT);
        IERC20(av3Crv).safeApprove(av3Crv_POOL, MAX_UINT);
        IERC20(USDT).safeApprove(JOE_ROUTER, MAX_UINT);
        IERC20(WAVAX).safeApprove(_yv, MAX_UINT);

        IERC20(WAVAX).safeApprove(JOE_ROUTER, MAX_UINT);
        IERC20(USDT).safeApprove(av3Crv_POOL, MAX_UINT);
        IERC20(av3Crv).safeApprove(_curveUsdrPool, MAX_UINT);
        IERC20(_usdr).safeApprove(_yv, MAX_UINT);
    }

    // Swap USDR to wAVAX
    function depositHook(
        address,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minUSDT, uint256 _minwAVAX) = abi.decode(data, (uint256,uint256,uint256));

        // Swap USDR to av3Crv
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(0, 1, _usdrBal, _minav3Crv, address(this));

        // Swap av3Crv to USDT
        uint256 _receivedav3Crv = IERC20(av3Crv).balanceOf(address(this));
        uint256 _receivedUSDT = IAvaxAv3CrvPool(av3Crv_POOL).remove_liquidity_one_coin(_receivedav3Crv, 2, _minUSDT, true);

        // Swap USDT to WAVAX
        address[] memory _path = new address[](2);
        _path[0] = USDT;
        _path[1] = WAVAX;
        
        IJoeRouter02(JOE_ROUTER).swapExactTokensForTokens(
            _receivedUSDT,
            _minwAVAX,
            _path,
            address(this),
            block.timestamp + 1
        );

        // Deposit to LickHitter
        uint256 _wAVAXBal = IERC20(WAVAX).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(WAVAX, msg.sender, _wAVAXBal);
    }

    function repayHook(
        address,
         bytes calldata data
    ) external override {
        (uint256 _minUSDT, uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256,uint256));

        _swapwAVAX2USDR(_minUSDT, _minav3Crv, _minUSDR);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    function liquidateHook(
        address,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override {
         (uint256 _minUSDT, uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256,uint256));

        _swapwAVAX2USDR(_minUSDT, _minav3Crv, _minUSDR);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapwAVAX2USDR(uint256 _minUSDT, uint256 _minav3Crv, uint256 _minUSDR) internal {
        // Swap wAVAX to USDT
        uint256 _wAVAXBal = IERC20(WAVAX).balanceOf(address(this));
        address[] memory _path = new address[](2);
        _path[0] = WAVAX;
        _path[1] = USDT;
        
        IJoeRouter02(JOE_ROUTER).swapExactTokensForTokens(
            _wAVAXBal,
            _minUSDT,
            _path,
            address(this),
            block.timestamp + 1
        );

        // Swap USDT to av3Crv
        uint256 _usdtBal = IERC20(USDT).balanceOf(address(this));
        IAvaxAv3CrvPool(av3Crv_POOL).add_liquidity([0, 0, _usdtBal], _minav3Crv, true);

        // Swap av3Crv to USDT
        uint256 _receivedav3Crv = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(1, 0, _receivedav3Crv, _minUSDR, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "./../../interfaces/IStrategy.sol";
import "./../../interfaces/ILickHitter.sol";
import "./../../interfaces/curve/ICurveGauge.sol";
import "./../../interfaces/curve/ICurvePool.sol";
import "./../../interfaces/traderjoe/IJoeRouter02.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract CurveLPAvalancheStrategy is IStrategy {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private yieldVault;

    address private constant CRV = 0x47536F17F4fF30e64A96a7555826b8f9e66ec468;
    address private constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address private constant DAI = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address private constant JOE_ROUTER = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;

    address private constant av3CRV = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
    address private constant av3CRV_GAUGE = 0x5B5CFE992AdAC0C9D48E05854B2d91C73a003858;
    address private constant av3CRV_POOL = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
    address private constant crvUSDBTCETH = 0x1daB6560494B04473A0BE3E7D83CF3Fdf3a51828;
    address private constant crvUSDBTCETH_GAUGE = 0x445FE580eF8d70FF569aB36e80c647af338db351;
    address private constant crvUSDBTCETH_POOL = 0xB755B949C126C04e0348DD881a5cF55d424742B2;

    mapping(address => address) private minHarvestRewardToken;
    mapping(address => uint256) private minHarvestRewardAmount;

    modifier onlyLickHitter {
        require(msg.sender == yieldVault, "Unauthorized");
        _;
    }

    modifier onlyOwner {
        address _owner = ILickHitter(yieldVault).getOwner();
        require(msg.sender == _owner, "Unauthorized");
        _;
    }

    modifier requireSupportedToken(address _token) {
        require(_stoken(_token), "Unsupported token");
        _;
    }

    constructor(
        address _yv,
        address[2] memory _minHarvestRewardTokens,
        uint256[2] memory _minHarvestRewardAmounts
    ) {
        yieldVault = _yv;

        minHarvestRewardToken[av3CRV] = _minHarvestRewardTokens[0];
        minHarvestRewardToken[crvUSDBTCETH] = _minHarvestRewardTokens[1];

        minHarvestRewardAmount[av3CRV] = _minHarvestRewardAmounts[0];
        minHarvestRewardAmount[crvUSDBTCETH] = _minHarvestRewardAmounts[1];
        
        IERC20(CRV).safeApprove(JOE_ROUTER, MAX_UINT);
        IERC20(WAVAX).safeApprove(JOE_ROUTER, MAX_UINT);
        _doApprove(av3CRV, av3CRV_GAUGE, false);
        _doApprove(crvUSDBTCETH, crvUSDBTCETH_GAUGE, false);
        IERC20(DAI).safeApprove(av3CRV_POOL, MAX_UINT);
        IERC20(av3CRV).safeApprove(crvUSDBTCETH_POOL, MAX_UINT);
    }

    // Owner functions

    function updateMinHarvest(
        address _token,
        address _rewardToken,
        uint256 _amount
    ) external onlyOwner {
        minHarvestRewardToken[_token] = _rewardToken;
        minHarvestRewardAmount[_token] = _amount;
    }

    // Withdraw any other blocked assets
    function withdrawBlockedAssets(address _asset, address _to, uint256 _amt) external onlyOwner {
        require(_asset != CRV && _asset != WAVAX && _asset != av3CRV && _asset != crvUSDBTCETH, "Illegal Asset");
        IERC20(_asset).transfer(_to, _amt);
    }

    // Strategy functions

    function depositToStrategy(
        address _token,
        uint256 _amount
    ) external override onlyLickHitter requireSupportedToken(_token) {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_token);
    }

    function withdrawFromStrategy(
        address _token,
        uint256 _amount
    ) external override onlyLickHitter requireSupportedToken(_token) {
        ICurveFi_Gauge(_getGauge(_token)).withdraw(_amount);
        IERC20(_token).safeTransfer(yieldVault, _amount);
    }

    function exit(address _token) external override onlyLickHitter requireSupportedToken(_token) {
        uint256 _tBal = ICurveFi_Gauge(_getGauge(_token)).balanceOf(address(this));
        ICurveFi_Gauge(_getGauge(_token)).withdraw(_tBal);

        uint256 _myBal = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(yieldVault, _myBal);
    }

    function harvest(address _token) external override onlyLickHitter requireSupportedToken(_token) {
        ICurveFi_Gauge(_getGauge(_token)).claim_rewards(address(this), address(this));
        _CRV2WAVAX();
        _WAVAX2DAI();
        uint256 _daiBal = IERC20(DAI).balanceOf(address(this));
        if (_daiBal > 0) {
            IAvalancheCurvePool(av3CRV_POOL).add_liquidity([_daiBal, 0, 0], 0, true);
        }

        if (_token == crvUSDBTCETH) {
            uint256 _lpBal = IERC20(av3CRV).balanceOf(address(this));
            if (_lpBal > 0) {
                IAvalancheCurvePool(crvUSDBTCETH_POOL).add_liquidity([_lpBal, 0, 0], 0);
            }
        }


        _deposit(_token);
    }

    // Internal functions

    function _CRV2WAVAX() internal {
        uint256 _crvBal = IERC20(CRV).balanceOf(address(this));

        if (_crvBal > 0) {
            address[] memory _path = new address[](2);
            _path[0] = CRV;
            _path[1] = WAVAX;

            IJoeRouter02(JOE_ROUTER).swapExactTokensForTokens(
                _crvBal,
                0,
                _path,
                address(this),
                block.timestamp+1
            );
        }
    }

    function _WAVAX2DAI() internal {
        uint256 _avaxBal = IERC20(WAVAX).balanceOf(address(this));

        if(_avaxBal > 0) {
            address[] memory _path = new address[](2);
            _path[0] = WAVAX;
            _path[1] = DAI;
            
            IJoeRouter02(JOE_ROUTER).swapExactTokensForTokens(
                _avaxBal,
                0,
                _path,
                address(this),
                block.timestamp+1
            );
        }
    }

    function _deposit(address _token) internal {
        uint256 _bal = IERC20(_token).balanceOf(address(this));
        if (_bal > 0) {
            ICurveFi_Gauge(_getGauge(_token)).deposit(_bal);
        }
    }

    function _getGauge(address _token) internal pure returns (address) {
        if (_token == av3CRV) {
            return av3CRV_GAUGE;
        } else if (_token == crvUSDBTCETH) {
            return crvUSDBTCETH_GAUGE;
        } else {
            return address(0);
        }
    }

    function _doApprove(address _token, address _gauge, bool _0ApproveFirst) internal {
        if(_0ApproveFirst) {
            IERC20(_token).safeApprove(_gauge, 0);
        }
        IERC20(_token).safeApprove(_gauge, MAX_UINT);
    }

    function _stoken(address _token) internal pure returns (bool) {
        return (_getGauge(_token) != address(0));
    }

    // State Getters

    function getInvestor() external view override returns (address) {
        return yieldVault;
    }

    function getIsSupportedToken(address _token) external pure override returns (bool) {
        return _stoken(_token);
    }

    function isLiquid(address, uint256) external pure override returns (bool) {
        // This strategy is always liquid
        return true;
    }

    function invested(address _token) external view override requireSupportedToken(_token) returns (uint256) {
        uint256 _myBal = IERC20(_token).balanceOf(address(this));
        uint256 _invested = ICurveFi_Gauge(_getGauge(_token)).balanceOf(address(this));

        return _myBal + _invested;
    }

    function shouldHarvest(address _token) external view override requireSupportedToken(_token) returns (bool) {
        uint256 _claimableRewards = ICurveFi_Gauge(_getGauge(_token)).claimable_reward(address(this), minHarvestRewardToken[_token]);

        return (_claimableRewards >= minHarvestRewardAmount[_token]);
    }
}

/*
 Copyright (c) 2022 Radar Global

 Permission is hereby granted, free of charge, to any person obtaining a copy of
 this software and associated documentation files (the "Software"), to deal in
 the Software without restriction, including without limitation the rights to
 use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 the Software, and to permit persons to whom the Software is furnished to do so,
 subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface IStrategy {
    function invested(address _token) external view returns (uint256);

    function getIsSupportedToken(address _token) external view returns (bool);

    function exit(address _token) external;

    function depositToStrategy(address _token, uint256 _amount) external;

    function withdrawFromStrategy(address _token, uint256 _amount) external;

    function isLiquid(address _token, uint256 _amount) external view returns (bool);

    function harvest(address _token) external;

    function getInvestor() external view returns (address);

    function shouldHarvest(address _token) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface ICurveFi_Gauge {
    function lp_token() external view returns (address);

    function crv_token() external view returns (address);

    function balanceOf(address addr) external view returns (uint);

    function deposit(uint _value) external;

    function withdraw(uint _value) external;

    function claimable_tokens(address addr) external returns (uint);

    function claimable_reward(address _addr, address _token) external view returns (uint256);

    function minter() external view returns (address); //use minter().mint(gauge_addr) to claim CRV

    function integrate_fraction(address _for) external view returns (uint);

    function user_checkpoint(address _for) external returns (bool);

    function claim_rewards(address,address) external;
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "./../interfaces/IStrategy.sol";
import "./../interfaces/ILickHitter.sol";
import "./../interfaces/convex/IConvex.sol";
import "./../interfaces/convex/IConvexRewards.sol";
import "./../interfaces/curve/ICurvePool.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract ConvexCurveLPStrategy is IStrategy {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private immutable yieldVault;
    address private constant CONVEX = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;

    address private constant CRV = 0xD533a949740bb3306d119CC777fa900bA034cd52;
    address private constant CVX = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant CRV3 = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address payable private constant CRV_ETH_POOL = payable(0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511);
    address payable private constant CVX_ETH_POOL = payable(0xB576491F1E6e5E62f1d8F26062Ee822B40B0E0d4);
    address payable private constant TRICRYPTO_POOL = payable(0xD51a44d3FaE010294C616388b506AcdA1bfAAE46);
    address private constant CRV3_POOL = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    mapping(address => uint256) private cvxPoolIds;
    mapping(address => CurvePoolType) private poolTypes;
    mapping(address => address) private curvePools;

    uint256 private minHarvestCRVAmount;

    enum CurvePoolType {
        USDMetapool,
        ETH,
        USDDirectUnderlying
    }

    modifier onlyLickHitter {
        require(msg.sender == yieldVault, "Unauthorized");
        _;
    }

    modifier onlyOwner {
        address _owner = ILickHitter(yieldVault).getOwner();
        require(msg.sender == _owner, "Unauthorized");
        _;
    }

    modifier requireSupportedToken(address _token) {
        require(_stoken(_token), "Unsupported token");
        _;
    }

    constructor(
        address _yieldVault,
        address[] memory _tokens,
        uint256[] memory _pids,
        CurvePoolType[] memory _poolTypes,
        address[] memory _crvPools,
        uint256 _minHarvestCRVAmount
    ) {
        yieldVault = _yieldVault;
        require(_tokens.length == _pids.length && _pids.length == _poolTypes.length && _poolTypes.length == _crvPools.length, "Invalid data");
        for(uint8 i = 0; i < _tokens.length; i++) {
            cvxPoolIds[_tokens[i]] = _pids[i];
            poolTypes[_tokens[i]] = _poolTypes[i];
            curvePools[_tokens[i]] = _crvPools[i];
            IERC20(_tokens[i]).safeApprove(CONVEX, MAX_UINT);
            _swappersPoolApprove(_poolTypes[i], _crvPools[i], false);
        }
        minHarvestCRVAmount = _minHarvestCRVAmount;

        IERC20(CRV).safeApprove(CRV_ETH_POOL, MAX_UINT);
        IERC20(CVX).safeApprove(CVX_ETH_POOL, MAX_UINT);
        IERC20(USDT).safeApprove(CRV3_POOL, MAX_UINT);
    }

    // Owner functions

    function updatePid(address _token, uint256 _pid, CurvePoolType _pt, address _crvPool) external onlyOwner {
        cvxPoolIds[_token] = _pid;
        poolTypes[_token] = _pt;
        curvePools[_token] = _crvPool;
        _swappersPoolApprove(_pt, _crvPool, true);
        IERC20(_token).safeApprove(CONVEX, 0);
        IERC20(_token).safeApprove(CONVEX, MAX_UINT);
    }

    function updateMinCRVHarvestAmount(uint256 _newAmt) external onlyOwner {
        minHarvestCRVAmount = _newAmt;
    }

    // Withdraw any other blocked assets
    function withdrawBlockedAssets(address _asset, address _to, uint256 _amt) external onlyOwner {
        require(_asset != CRV && _asset != CVX, "Illegal Asset");
        IERC20(_asset).transfer(_to, _amt);
    }

    // Strategy functions

    function depositToStrategy(
        address _token,
        uint256 _amount
    ) external override onlyLickHitter requireSupportedToken(_token) {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        _deposit(_token);
    }

    function withdrawFromStrategy(
        address _token,
        uint256 _amount
    ) external override onlyLickHitter requireSupportedToken(_token) {
        IConvex.PoolInfo memory _pi = _getPoolInfo(_token);

        IConvexRewards(_pi.crvRewards).withdrawAndUnwrap(_amount, false);
        IERC20(_token).safeTransfer(yieldVault, _amount);
    }

    function exit(
        address _token
    ) external override onlyLickHitter requireSupportedToken(_token) {
        IConvex.PoolInfo memory _pi = _getPoolInfo(_token);
        address _rewards = _pi.crvRewards;

        uint256 _bal = IConvexRewards(_rewards).balanceOf(address(this));
        IConvexRewards(_rewards).withdrawAndUnwrap(_bal, false); // exit, don't claim rewards

        uint256 _tBal = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(yieldVault, _tBal);
    }

    function harvest(
        address _token
    ) external override onlyLickHitter requireSupportedToken(_token) {
        // Claim Rewards
        IConvex.PoolInfo memory _pi = _getPoolInfo(_token);
        CurvePoolType _pt = poolTypes[_token];
        IConvexRewards(_pi.crvRewards).getReward();

        if (_pt == CurvePoolType.USDMetapool) {

            // Rewards to ETH
            _rewards2ETH();

            // ETH to USDT
            _eth2USDT();

            // Deposit USDT to get 3Crv
            uint256 _usdtBal = IERC20(USDT).balanceOf(address(this));
            ICurvePool(CRV3_POOL).add_liquidity([0, 0, _usdtBal], 0);

            // Deposit 3Crv to get Curve LP Token
            uint256 _crv3Bal = IERC20(CRV3).balanceOf(address(this));
            ICurvePool(curvePools[_token]).add_liquidity([0, _crv3Bal], 0);

        } else if (_pt == CurvePoolType.ETH) {

            // Rewards to ETH
            _rewards2ETH();

            // Deposit ETH to get Curve LP Token
            ICurvePool(curvePools[_token]).add_liquidity{value: address(this).balance}([address(this).balance, 0], 0); // All ETH pools have ETH as coin0
        } else if(_pt == CurvePoolType.USDDirectUnderlying) {
            // Rewards to ETH
            _rewards2ETH();

            // ETH to USDT
            _eth2USDT();

            uint256 _usdtBal = IERC20(USDT).balanceOf(address(this));
            ICurvePool(curvePools[_token]).add_liquidity([0, 0, _usdtBal], 0, true);
        } else {
            revert("Invalid PT");
        }

        _deposit(_token);
    }

    // Internal functions

    function _swappersPoolApprove(CurvePoolType _pt, address _curvePool, bool _0ApproveFirst) internal {
        if (_pt == CurvePoolType.USDMetapool) {
            if (_0ApproveFirst) {
                IERC20(CRV3).safeApprove(_curvePool, 0);
            }
            IERC20(CRV3).safeApprove(_curvePool, MAX_UINT);
        } else if(_pt == CurvePoolType.USDDirectUnderlying) {
            if (_0ApproveFirst) {
                IERC20(USDT).safeApprove(_curvePool, 0);
            }
            IERC20(USDT).safeApprove(_curvePool, MAX_UINT);
        }
    }

    function _deposit(address _token) internal {
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IConvex(CONVEX).deposit(cvxPoolIds[_token], _balance, true);
    }

    function _eth2USDT() internal {
        ICurveTricryptoPool(TRICRYPTO_POOL).exchange{value: address(this).balance}(2, 0, address(this).balance, 0, true);
    }

    function _rewards2ETH() internal {
        uint256 _crvBal = IERC20(CRV).balanceOf(address(this));
        uint256 _cvxBal = IERC20(CVX).balanceOf(address(this));

        if (_crvBal != 0) {
            ICurveCrvCvxEthPool(CRV_ETH_POOL).exchange_underlying(1, 0, _crvBal, 0);
        }
        if (_cvxBal != 0) {
            ICurveCrvCvxEthPool(CVX_ETH_POOL).exchange_underlying(1, 0, _cvxBal, 0);
        }
    }

    function _getPoolInfo(address _token) internal view returns (IConvex.PoolInfo memory) {
        IConvex.PoolInfo memory _pi = IConvex(CONVEX).poolInfo(cvxPoolIds[_token]);
        return _pi;
    }

    function _stoken(address _token) internal view returns (bool) {
        IConvex.PoolInfo memory _pi = _getPoolInfo(_token);

        return (_pi.lptoken == _token);
    }

    // State Getters

    function invested(address _token) external view override requireSupportedToken(_token) returns (uint256) {
        // Get staked LP CRV token balance
        IConvex.PoolInfo memory _pid = _getPoolInfo(_token);
        uint256 _stakedLP = IConvexRewards(_pid.crvRewards).balanceOf(address(this));
        uint256 _cBal = IERC20(_token).balanceOf(address(this));

        return _stakedLP + _cBal;
    }

    function isLiquid(address, uint256) external pure override returns (bool) {
        // This strategy is always liquid
        return true;
    }

    function shouldHarvest(address _token) external view override requireSupportedToken(_token) returns (bool) {
        IConvex.PoolInfo memory _pid = _getPoolInfo(_token);
        uint256 _r = IConvexRewards(_pid.crvRewards).earned(address(this));

        return (_r >= minHarvestCRVAmount);
    }

    function getInvestor() external view override returns (address) {
        return yieldVault;
    }

    function getIsSupportedToken(address _token) external view override returns (bool) {
        return _stoken(_token);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

//main Convex contract(booster.sol) basic interface
interface IConvex{
    struct PoolInfo {
        address lptoken;
        address token;
        address gauge;
        address crvRewards;
        address stash;
        bool shutdown;
    }

    //deposit into convex, receive a tokenized deposit.  parameter to stake immediately
    function deposit(uint256 _pid, uint256 _amount, bool _stake) external returns(bool);
    function depositAll(uint256 _pid, bool _stake) external returns(bool);
    //burn a tokenized deposit to receive curve lp tokens back
    function withdraw(uint256 _pid, uint256 _amount) external returns(bool);

    function poolInfo(uint256 _pid) external view returns (PoolInfo memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

//sample convex reward contracts interface
interface IConvexRewards{
    //get balance of an address
    function balanceOf(address _account) external view returns(uint256);
    //withdraw to a convex tokenized deposit
    function withdraw(uint256 _amount, bool _claim) external returns(bool);
    //withdraw directly to curve LP token
    function withdrawAndUnwrap(uint256 _amount, bool _claim) external returns(bool);
    //claim rewards
    function getReward() external returns(bool);
    //stake a convex tokenized deposit
    function stake(uint256 _amount) external returns(bool);
    //stake a convex tokenized deposit for another address(transfering ownership)
    function stakeFor(address _account,uint256 _amount) external returns(bool);
    function earned(address _account) external view returns(uint256);
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "./../../interfaces/IStrategy.sol";
import "./../../interfaces/ILickHitter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../../interfaces/traderjoe/IJoeRouter02.sol";
import "./../../interfaces/benqi/IBenqiToken.sol";
import "./../../interfaces/benqi/IBenqiComptroller.sol";
import "./../../interfaces/IWETH.sol";

contract BENQIStrategy is IStrategy {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;
    uint256 constant DUST = 10**15;

    mapping(address => address) private benqiTokens;
    address private yieldVault;

    address payable private constant JOE_ROUTER = payable(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    address payable private constant PANGOLIN_ROUTER = payable(0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106);
    address private constant QI = 0x8729438EB15e2C8B576fCc6AeCdA6A148776C0F5;
    address private constant BENQI_COMPTROLLER = 0x486Af39519B4Dc9a7fCcd318217352830E8AD9b4;
    address payable private constant WAVAX = payable(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);

    modifier onlyLickHitter {
        require(msg.sender == yieldVault, "Unauthorized");
        _;
    }

    modifier onlyOwner {
        address _owner = ILickHitter(yieldVault).getOwner();
        require(msg.sender == _owner, "Unauthorized");
        _;
    }

    modifier requireSupportedToken(address _token) {
        require(_stoken(_token), "Unsupported token");
        _;
    }

    constructor(
        address _yv,
        address[] memory _tokens,
        address[] memory _bTokens
    ) {
        require(_tokens.length == _bTokens.length, "Invalid Data");
        yieldVault = _yv;
        for(uint8 i = 0; i < _tokens.length; i++) {
            benqiTokens[_tokens[i]] = _bTokens[i];
            _doApprove(_tokens[i], _bTokens[i], false);
        }

        _doApprove(QI, PANGOLIN_ROUTER, false);
    }

    // Owner functions

    function editToken(address _token, address _bToken) external onlyOwner {
        benqiTokens[_token] = _bToken;
        if (_bToken != address(0)) {
            _doApprove(_token, _bToken, true);
        }
    }

    function withdrawBlockedAssets(address _asset, address _to, uint256 _amt) external onlyOwner {
        require(benqiTokens[_asset] == address(0), "Illegal Asset");
        IERC20(_asset).transfer(_to, _amt);
    }

    // Strategy functions

    function depositToStrategy(
        address _token,
        uint256 _amount
    ) external override onlyLickHitter requireSupportedToken(_token) {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);
        if (_token == WAVAX) {
            uint256 _bal = IERC20(WAVAX).balanceOf(address(this));
            _unwrapAvax(_bal);
        }

        _deposit(_token);
    }

    function withdrawFromStrategy(
        address _token,
        uint256 _amount
    ) external override onlyLickHitter requireSupportedToken(_token) {
        IBenqiToken(benqiTokens[_token]).redeemUnderlying(_amount);
        if (_token == WAVAX) {
            _wrapAvax(_amount);
        }

        IERC20(_token).safeTransfer(yieldVault, _amount);
    }

    function exit(
        address _token
    ) external override onlyLickHitter requireSupportedToken(_token) {
        uint256 _bal = IERC20(benqiTokens[_token]).balanceOf(address(this));
        IBenqiToken(benqiTokens[_token]).redeem(_bal);
        
        if (_token == WAVAX) {
            _wrapAvax(address(this).balance);
        }
        uint256 _underlyingBal = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(yieldVault, _underlyingBal);
    }

    function harvest(
        address _token
    ) external override onlyLickHitter requireSupportedToken(_token) {
        address[] memory _claim = new address[](1);
        _claim[0] = benqiTokens[_token];

        IBenqiComptroller(BENQI_COMPTROLLER).claimReward(0, payable(address(this)), _claim);
        IBenqiComptroller(BENQI_COMPTROLLER).claimReward(1, payable(address(this)), _claim);

        _QI2AVAX();

        if (_token != WAVAX) {
            _AVAX2TOKEN(_token);
        }
        _deposit(_token);
    }

    // Internal functions

    function _QI2AVAX() internal {
        uint256 _qiBal = IERC20(QI).balanceOf(address(this));
        if (_qiBal > DUST) {
            address[] memory _path = new address[](2);
            _path[0] = QI;
            _path[1] = WAVAX;
            
            IJoeRouter02(PANGOLIN_ROUTER).swapExactTokensForAVAX(
                _qiBal,
                0,
                _path,
                address(this),
                block.timestamp + 1
            );
        }
    }

    function _AVAX2TOKEN(address _token) internal {
        if (address(this).balance > DUST) {
            address[] memory _path = new address[](2);
            _path[0] = WAVAX;
            _path[1] = _token;
            
            IJoeRouter02(PANGOLIN_ROUTER).swapExactAVAXForTokens{value: address(this).balance}(
                0,
                _path,
                address(this),
                block.timestamp + 1
            );
        }
    }

    function _doApprove(address _token, address _bToken, bool _0ApproveFirst) internal {
        if (_token != WAVAX) {
            if(_0ApproveFirst) {
                IERC20(_token).safeApprove(_bToken, 0);
            }
            IERC20(_token).safeApprove(_bToken, MAX_UINT);
        }
    }

    function _deposit(address _token) internal {
        if (_token == WAVAX) {
            IBenqiAvax(benqiTokens[_token]).mint{value: address(this).balance}();
        } else {
            uint256 _bal = IERC20(_token).balanceOf(address(this));
            IBenqiToken(benqiTokens[_token]).mint(_bal);
        }
    }

    function _unwrapAvax(uint256 _amt) internal {
        IWETH9(WAVAX).withdraw(_amt);
    }

    function _wrapAvax(uint256 _amt) internal {
        IWETH9(WAVAX).deposit{value: _amt}();
    }

    function _stoken(address _token) internal view returns (bool) {
        return (benqiTokens[_token] != address(0));
    }

    // State Getters

    function getInvestor() external view override returns (address) {
        return yieldVault;
    }

    function getIsSupportedToken(address _token) external view override returns (bool) {
        return _stoken(_token);
    }

    function isLiquid(address, uint256) external pure override returns (bool) {
        // This strategy is always liquid
        return true;
    }

    function invested(address _token) external view override requireSupportedToken(_token) returns (uint256) {
        uint256 _myBal = IERC20(_token).balanceOf(address(this));
        uint256 _bBal = IERC20(benqiTokens[_token]).balanceOf(address(this));
        uint256 _ers = IBenqiToken(benqiTokens[_token]).exchangeRateStored();

        return (_myBal + ((_bBal * _ers) / 10**18));
    }

    function shouldHarvest(address) external pure override returns (bool) {
        // always harvest, will save gas if reward is 0
        return true;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IBenqiComptroller {
    function claimReward(uint8 rewardType, address payable holder, address[] memory qiTokens) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./../interfaces/IStrategy.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract MockStrategy is IStrategy {
    using SafeERC20 for IERC20;

    address private investor;
    mapping(address => bool) private supportedTokens;

    modifier onlyInvestor {
        require(msg.sender == investor, "Unauthorized");
        _;
    }

    constructor(address _investor, address[] memory _supportedTokens) {
        investor = _investor;
        for(uint i = 0; i < _supportedTokens.length; i++) {
            supportedTokens[_supportedTokens[i]] = true;
        }
    }

    function invested(address _token) external view override returns (uint256) {
        return IERC20(_token).balanceOf(address(this));
    }

    function getIsSupportedToken(address _token) external view override returns (bool) {
        return supportedTokens[_token];
    }

    function exit(address _token) external override onlyInvestor {
        // Check token supported
        if (IERC20(_token).balanceOf(address(this)) != 0) {
            IERC20(_token).safeTransfer(investor, IERC20(_token).balanceOf(address(this)));
        }
    }

    function depositToStrategy(address _token, uint256 _amount) external override onlyInvestor {
        IERC20(_token).safeTransferFrom(investor, address(this), _amount);
    }

    function withdrawFromStrategy(address _token, uint256 _amount) external override onlyInvestor {
        IERC20(_token).safeTransfer(investor, _amount);
    }

    function isLiquid(address _token, uint256 _amount) external view override returns (bool) {
        return IERC20(_token).balanceOf(address(this)) >= _amount;
    }

    function harvest(address) external override onlyInvestor {
        // Do nothing
    }

    function getInvestor() external view override returns (address) {
        return investor;
    }

    function shouldHarvest(address) external pure override returns (bool) {
        return true;
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../interfaces/IStrategy.sol";

/// @title LickHitter
/// @author Radar Global ([email protected])
/// @notice This acts as a yield farming vault
/// which supports multiple assets and a yield farming
/// strategy for each asset. It keeps collateral from
/// `LendingPair`s to earn yield.
contract LickHitter {
    using SafeERC20 for IERC20;

    // Share balances (for each token)
    mapping(address => mapping(address => uint256)) private balances;
    // Total share supply for each token
    mapping(address => uint256) private totalShareSupply;

    // Token to yield strategy
    mapping(address => address) private strategies;

    // Supported tokens
    mapping(address => bool) private supportedTokens;

    uint256 private constant DUST = 10**10;
    
    // How many tokens should stay inside the Yield Vault at any time
    mapping(address => uint256) private bufferSize;

    address private owner;
    address private pendingOwner;
    address private pokeMe;


    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);
    event StrategyAdded(address indexed token, address indexed strategy);
    event StrategyRemoved(address indexed token);

    event ShareTransfer(address indexed token, address indexed from, address indexed to, uint256 amount);

    event TokenAdded(address indexed token, uint256 bufferSize);
    event TokenRemoved(address indexed token);

    event Deposit(address indexed token, address indexed payer, address indexed receiver, uint256 amount, uint256 sharesMinted);
    event Withdraw(address indexed token, address indexed payer, address indexed receiver, uint256 amount, uint256 sharesBurned);

    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    modifier onlyPokeMe {
        require(msg.sender == owner || msg.sender == pokeMe, "Unauthorized");
        _;
    }

    constructor(address _pokeMe) {
        owner = msg.sender;
        pokeMe = _pokeMe;

        emit OwnershipTransferred(address(0), msg.sender);
    }

    // Owner Functions

    function changePokeMe(address _newPokeMe) external onlyOwner {
        pokeMe = _newPokeMe;
    }

    function changeBufferAmount(address _token, uint256 _newBuf) external onlyOwner {
        require(supportedTokens[_token], "Token not supported");
        bufferSize[_token] = _newBuf;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        pendingOwner = _newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == pendingOwner, "Unauthorized");

        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    function addStrategy(address _token, address _strategy) external onlyOwner {
        require(IStrategy(_strategy).getIsSupportedToken(_token) && supportedTokens[_token], "Token not supported");

        strategies[_token] = _strategy;
        emit StrategyAdded(_token, _strategy);
    }

    function removeStrategy(address _token) external onlyOwner {
        strategies[_token] = address(0);
        emit StrategyRemoved(_token);
    }

    function emptyStrategy(address _token) external onlyOwner {
        // Withdraw all funds from strategy (optional before strategy removal)
        address _strategy = strategies[_token];
        require(_strategy != address(0), "Strategy doesn't exist");
        IStrategy(_strategy).exit(_token);
    }

    function addSupportedToken(address _token, uint256 _bufferSize) external onlyOwner {
        _addSupportedToken(_token, _bufferSize);
    }

    function addSupportedTokens(address[] calldata _tokens, uint256[] calldata _bufferSizes) external onlyOwner {
        require(_tokens.length == _bufferSizes.length, "Invalid data");

        for(uint8 i = 0; i < _tokens.length; i++) {
            _addSupportedToken(_tokens[i], _bufferSizes[i]);
        }
    }

    function removeSupportedToken(address _token) external onlyOwner {
        require(supportedTokens[_token], "Token not supported");

        // Check there are no balances
        require(_tokenTotalBalance(_token) <= DUST, "Token is active");

        supportedTokens[_token] = false;
        bufferSize[_token] = 0;

        emit TokenRemoved(_token);
    }

    // User functions

    /// @notice Transfers shares from the caller to another user
    /// @param _token Which token shares to transfer
    /// @param _to The address which will receive the shares
    /// @param _amount Amount of shares
    function transferShares(address _token, address _to, uint256 _amount) external {
        require(balances[_token][msg.sender] >= _amount, "Not enough shares");

        unchecked {
            balances[_token][msg.sender] = balances[_token][msg.sender] - _amount;
        }
        balances[_token][_to] = balances[_token][_to] + _amount;

        emit ShareTransfer(_token, msg.sender, _to, _amount);
    }

    // Deposits get called with token amount and
    // Withdrawals get called with shares amount.
    // If this is not what the user/contract interacting
    // with the IYV wants, the convertShares
    // function can be used

    /// @notice Deposit assets to the `LickHitter`. Caller must have `_token` allowance
    /// @param _token Token to deposit
    /// @param _destination Address which will receive the shares
    /// @param _amount Amount of `_token` to deposit
    /// @return The number of shares minted
    function deposit(address _token, address _destination, uint256 _amount) external returns (uint256) {
        return _deposit(_token, msg.sender, _destination, _amount);
    }

    /// @notice Withdraws assets from the `LickHitter`
    /// @param _token Token to withdraw
    /// @param _destination Address which will receive the `_token` assets
    /// @param _shares Amount of shares to withdraw
    /// @return The amount of `_token` that was withdrawn
    function withdraw(address _token, address _destination, uint256 _shares) external returns (uint256) {
        return _withdraw(_token, msg.sender, _destination, _shares);
    }

    // Bot functions (Gelato)

    /// @notice Deposits tokens to a yield strategy and harvests profits
    /// @dev Only the Gelato Network agent can call this.
    /// @param _token Which token to execute the strategy for
    function executeStrategy(address _token) external onlyPokeMe {
        address _strategy = strategies[_token];
        require(_strategy != address(0) && supportedTokens[_token], "Strategy doesn't exist");

        // Harvest strategy
        if (IStrategy(_strategy).shouldHarvest(_token)) {
            IStrategy(_strategy).harvest(_token);
        }

        // Deposit to strategy
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        uint256 _bufferSize = bufferSize[_token];
        if (_contractBalance > _bufferSize && _contractBalance != 0) {
            uint256 _depositAmount;
            unchecked {
                _depositAmount = _contractBalance - _bufferSize;
            }
            IERC20(_token).safeApprove(_strategy, _depositAmount);
            IStrategy(_strategy).depositToStrategy(_token, _depositAmount);
        }
    }

    // Internal Functions

    function _addSupportedToken(address _token, uint256 _bufferSize) internal {
        if (!supportedTokens[_token]) {
            supportedTokens[_token] = true;
            bufferSize[_token] = _bufferSize;

            emit TokenAdded(_token, _bufferSize);
        }
    }

    function _deposit(address _token, address _payer, address _destination, uint256 _amount) internal returns (uint256) {
        require(supportedTokens[_token], "Token not supported");

        uint256 _sharesToMint = _convertShares(_token, 0, _amount);

        require(_sharesToMint != 0 && _amount != 0, "0 deposit invalid");

        IERC20(_token).safeTransferFrom(_payer, address(this), _amount);

        totalShareSupply[_token] = totalShareSupply[_token] + _sharesToMint;
        balances[_token][_destination] = balances[_token][_destination] + _sharesToMint;

        // Event
        emit Deposit(
            _token,
            _payer,
            _destination,
            _amount,
            _sharesToMint
        );

        return _sharesToMint;
    }

    function _withdraw(address _token, address _payer, address _destination, uint256 _shares) internal returns (uint256) {
        require(supportedTokens[_token], "Token not supported");

        uint256 _amount = _convertShares(_token, _shares, 0);

        require(_shares != 0 && _amount != 0, "0 withdraw invalid");
        require(balances[_token][_payer] >= _shares, "Not enough funds");

        totalShareSupply[_token] = totalShareSupply[_token] - _shares;
        unchecked {
            balances[_token][_payer] = balances[_token][_payer] - _shares;
        }

        uint256 _amountInVault = IERC20(_token).balanceOf(address(this));
        address _strategy = strategies[_token];
        if (_strategy != address(0)) {
            if (_amountInVault < _amount) {
                uint256 _amountToWithdraw = _amount - _amountInVault;

                // If we need to withdraw from the strategy, make sure it is liquid
                require(IStrategy(_strategy).isLiquid(_token, _amountToWithdraw), "Strategy not Liquid. Try again later.");
                IStrategy(_strategy).withdrawFromStrategy(_token, _amountToWithdraw);
            }
        }

        IERC20(_token).safeTransfer(_destination, _amount);

        // Event
        emit Withdraw(
            _token,
            _payer,
            _destination,
            _amount,
            _shares
        );

        return _amount;
    }

    function _tokenTotalBalance(address _token) internal view returns (uint256) {
        address _strategy = strategies[_token];
        uint256 _strategyBal = _strategy == address(0) ? 0 : IStrategy(_strategy).invested(_token);
        return IERC20(_token).balanceOf(address(this)) + _strategyBal;
    }

    function _convertShares(address _token, uint256 _shares, uint256 _amount) internal view returns (uint256) {
        if (_amount == 0 && _shares == 0) {
            return 0;
        } else if (_amount == 0) {
            // Convert shares to amount
            return totalShareSupply[_token] != 0 ? (_shares * _tokenTotalBalance(_token)) / totalShareSupply[_token] : _shares;
        } else if (_shares == 0) {
            // Convert amount to shares
            return totalShareSupply[_token] != 0 ? (_amount * totalShareSupply[_token]) / _tokenTotalBalance(_token) : _amount;
        } else {
            revert("Should never happen: dangerous");
        }
    }

    // State Getters

    /// @return The share balance of a certain token of a user
    /// @param _token Address of the token
    /// @param _owner Address of the user
    function balanceOf(address _token, address _owner) external view returns (uint256) {
        return balances[_token][_owner];
    }

    /// @return The balance of a certain token of a user (in `_token`, not shares)
    /// @param _token Address of the token
    /// @param _owner Address of the user
    function tokenBalanceOf(address _token, address _owner) external view returns (uint256) {
        return _convertShares(_token, balances[_token][_owner], 0);
    }

    /// @return The owner of this contract
    function getOwner() external view returns (address) {
        return owner;
    }

    /// @return The pending owner of this contract before accepting ownership
    function getPendingOwner() external view returns (address) {
        return pendingOwner;
    }

    /// @return The address of the strategy for a specific token
    /// @param _token Address of the token
    function getTokenStrategy(address _token) external view returns (address) {
        return strategies[_token];
    }

    /// @return Total share supply for a certain token
    /// @param _token Address of the token
    function getTotalShareSupply(address _token) external view returns (uint256) {
        return totalShareSupply[_token];
    }

    /// @return Total token amount deposited of a certain token
    /// @param _token Address of the token
    function getTotalInvested(address _token) external view returns (uint256) {
        return _tokenTotalBalance(_token);
    }

    /// @return Returns true/false if a certain token is supported
    /// @param _token Address of the token
    function getIsSupportedToken(address _token) external view returns (bool) {
        return supportedTokens[_token];
    }

    /// @notice Function to convert shares to how many tokens they are worth and vice-versa.
    /// @dev _shares and _amount should never both be bigger than `0` or both be equal to `0`
    /// @return Either shares or actual token amount, depending on how the user called this function
    /// @param _token Address of the token
    /// @param _shares Amount of shares to be converted to token amount. Should be `0` if caller wants to convert amount -> shares
    /// @param _amount Amount of actual token to be converted to shares. Should be `0` if caller wants to convert shares -> amount
    function convertShares(address _token, uint256 _shares, uint256 _amount) external view returns (uint256) {
        return _convertShares(_token, _shares, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title RadarUSD
/// @author Radar Global ([email protected])
/// @notice ERC-20 Stablecoin with
/// whitelisted minters
contract RadarUSD is ERC20 {
    address public owner;
    address public pendingOwner;

    mapping(address => bool) public minter;

    bytes32 immutable public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event MinterAdded(address indexed minter);
    event MinterRemoved(address indexed minter);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    modifier onlyMinter {
        require(minter[msg.sender] == true, "Unauthorized");
        _;
    }

    constructor() ERC20("Radar USD", "USDR") {
        owner = msg.sender;
        minter[msg.sender] = true;

        // Build DOMAIN_SEPARATOR
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes("Radar USD")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );

        emit MinterAdded(msg.sender);
        emit OwnershipTransferred(address(0), msg.sender);
    }

    // User functions

    /// @notice EIP-2612: permit() https://eips.ethereum.org/EIPS/eip-2612
    function permit(address _owner, address _spender, uint _value, uint _deadline, uint8 _v, bytes32 _r, bytes32 _s) external {
        require(_deadline >= block.timestamp, "Permit: EXPIRED");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, _owner, _spender, _value, nonces[_owner]++, _deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, _v, _r, _s);
        require(recoveredAddress != address(0) && recoveredAddress == _owner, "Permit: INVALID_SIGNATURE");
        _approve(_owner, _spender, _value);
    }

    /// @notice Burns USDR from the caller's account
    /// @param _amount Amount of stablecoin to burn
    function burn(uint256 _amount) external {
        _burn(msg.sender, _amount);
    }

    // Minter functions

    /// @notice Mints stablecoin to a certain address. Only minters can call this.
    /// Minters will only be added/removed by the owner, which will be a trusted
    /// multisig.
    /// @param _to Address where tokens will be minted
    /// @param _amount Amount of tokens to mint
    function mint(address _to, uint256 _amount) external onlyMinter {
        _mint(_to, _amount);
    }

    // Owner Functions

    function addMinter(address _minter) external onlyOwner {
        minter[_minter] = true;
        emit MinterAdded(_minter);
    }

    function removeMinter(address _minter) external onlyOwner {
        minter[_minter] = false;
        emit MinterRemoved(_minter);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        pendingOwner = _newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == pendingOwner, "Unauthorized");
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "./../interfaces/IRadarUSD.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../interfaces/ILickHitter.sol";

contract Stabilizer {
    using SafeERC20 for IERC20;

    uint256 private constant MAX_UINT = 2**256 - 1;

    address public pokeMe;
    address private immutable USDR;

    uint256 private constant GENERAL_DIVISOR = 10000;
    uint256 public MINT_FEE;
    uint256 public BURN_FEE;

    address public FEE_RECEIVER;
    address public yieldVault;

    mapping(address => bool) private supportedTokens;
    mapping(address => uint8) private tokenDecimals;
    mapping(address => uint256) private accumulatedFees;

    event USDRMinted(address indexed user, uint256 amount);
    event USDRBurned(address indexed user, uint256 amount);

    modifier onlyOwner {
        address _owner = IRadarUSD(USDR).owner();
        require(msg.sender == _owner, "Unauthorized");
        _;
    }

    modifier onlyPokeMe {
        address _owner = IRadarUSD(USDR).owner();
        require(msg.sender == _owner || msg.sender == pokeMe, "Unauthorized");
        _;
    }

    modifier requireSupportedToken(address _t) {
        require(supportedTokens[_t], "Token not supported");
        _;
    }

    constructor(
        address _usdr,
        address _pokeMe,
        address[] memory _tokens,
        uint256 _mf,
        uint256 _bf,
        address _fr,
        address _yv
    ) {
        USDR = _usdr;
        pokeMe = _pokeMe;
        MINT_FEE = _mf;
        BURN_FEE = _bf;
        FEE_RECEIVER = _fr;
        yieldVault = _yv;
        for(uint8 i = 0; i < _tokens.length; i++) {
            supportedTokens[_tokens[i]] = true;
            tokenDecimals[_tokens[i]] = IERC20Metadata(_tokens[i]).decimals();
            IERC20(_tokens[i]).safeApprove(_yv, MAX_UINT);
        }
    }

    // Owner functions

    function changePokeMe(address _newPM) external onlyOwner {
        pokeMe = _newPM;
    }

    function backupReApprove(address _token) external onlyOwner {
        IERC20(_token).safeApprove(yieldVault, 0);
        IERC20(_token).safeApprove(yieldVault, MAX_UINT);
    }

    function addSupportedToken(address _token) external onlyOwner {
        supportedTokens[_token] = true;
        tokenDecimals[_token] = IERC20Metadata(_token).decimals();
        if (IERC20(_token).allowance(address(this), yieldVault) == 0) {
            IERC20(_token).safeApprove(yieldVault, MAX_UINT);
        }
    }

    function removeSupportedToken(address _token) external onlyOwner {
        supportedTokens[_token] = false;
    }

    function changeFees(uint256 _mf, uint256 _bf, address _fr) external onlyOwner {
        MINT_FEE = _mf;
        BURN_FEE = _bf;
        FEE_RECEIVER = _fr;
    }

    function changeYieldVault(address _newYV) external onlyOwner {
        yieldVault = _newYV;
    }

    function withdrawFromYieldFarming(address _token, uint256 _shares) external onlyOwner {
        ILickHitter(yieldVault).withdraw(_token, address(this), _shares);
    }

    // PokeMe functions

    function depositToYieldFarming(address _token, uint256 _tokenAmount) external onlyPokeMe requireSupportedToken(_token) {
        ILickHitter(yieldVault).deposit(_token, address(this), _tokenAmount);
    }

    function claimFees(address _token) external onlyPokeMe requireSupportedToken(_token) {
        _withdrawIfNeeded(_token, accumulatedFees[_token]);
        IERC20(_token).safeTransfer(FEE_RECEIVER, accumulatedFees[_token]);
        accumulatedFees[_token] = 0;
    }

    // User functions

    function mint(
        address _token,
        uint256 _amount
    ) external requireSupportedToken(_token) {
        IERC20(_token).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 _fee = (_amount * MINT_FEE) / GENERAL_DIVISOR;
        if (_fee > 0) {
            accumulatedFees[_token] = accumulatedFees[_token] + _fee;
        }
        uint256 _scaledAmount = (_amount - _fee) * (10**(18-tokenDecimals[_token]));

        IRadarUSD(USDR).mint(msg.sender, _scaledAmount);

        emit USDRMinted(msg.sender, _scaledAmount);
    }

    function burn(
        address _token,
        uint256 _amount,
        bytes calldata _permitData
    ) external requireSupportedToken(_token) {
        // Scale amount
        uint256 _scaledAmount = _amount / 10**(18-tokenDecimals[_token]);
        uint256 _fee = (_scaledAmount * BURN_FEE) / GENERAL_DIVISOR;
        uint256 _sendAmount = _scaledAmount - _fee;

        if (_fee > 0) {
            accumulatedFees[_token] = accumulatedFees[_token] + _fee;
        }
        require(_sendAmount <= _availableForBurning(_token), "Not enough tokens");

        if (_permitData.length > 0) {
            _permitApprove(_permitData);
        }
        IERC20(USDR).safeTransferFrom(msg.sender, address(this), _amount);
        IRadarUSD(USDR).burn(_amount);

        _withdrawIfNeeded(_token, _sendAmount);
        IERC20(_token).safeTransfer(msg.sender, _sendAmount);

        emit USDRBurned(msg.sender, _amount);
    }

    // Internal functions

    function _withdrawIfNeeded(address _token, uint256 _sendAmount) internal {
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        if (_sendAmount > _contractBalance) {
            uint256 _withdrawAmt;
            unchecked {
                _withdrawAmt = _sendAmount - _contractBalance;
            }
            uint256 _shares = ILickHitter(yieldVault).convertShares(_token, 0, _withdrawAmt);
            ILickHitter(yieldVault).withdraw(_token, address(this), _shares);
        }
    }

    function _permitApprove(bytes calldata _permitData) internal {
        (address _owner, address _spender, uint _value, uint _deadline, uint8 _v, bytes32 _r, bytes32 _s) = abi.decode(_permitData, (address,address,uint,uint,uint8,bytes32,bytes32));
        IRadarUSD(USDR).permit(_owner, _spender, _value, _deadline, _v, _r, _s);
    }

    function _yfInvested(address _t) internal view returns (uint256) {
        uint256 _myS = ILickHitter(yieldVault).balanceOf(_t, address(this));
        return ILickHitter(yieldVault).convertShares(_t, _myS, 0);
    }

    function _availableForBurning(address _token) internal view returns (uint256) {
        uint256 _myBal = IERC20(_token).balanceOf(address(this));
        return _myBal + _yfInvested(_token) - accumulatedFees[_token];
    }

    // State Getters

    function availableForBurning(address _token) external view requireSupportedToken(_token) returns (uint256) {
        return _availableForBurning(_token);
    }

    function getAccumulatedFees(address _token) external view returns (uint256) {
        return accumulatedFees[_token];
    }

    function isSupportedToken(address _token) external view returns (bool) {
        return supportedTokens[_token];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./../interfaces/ISwapper.sol";
import "./../interfaces/ILickHitter.sol";
import "./../interfaces/IRadarUSD.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockSwapper is ISwapper {

    address private yieldVault;
    address private stablecoin;

    constructor(address _yv, address _sb) {
        yieldVault = _yv;
        stablecoin = _sb;
    }

    function depositHook(
        address _collateral,
        bytes calldata
    ) external override {
        // Since this is a mock swapper and it will already have collateral
        // Just receive stablecoin, burn it, and deposit collateral that it has

        uint256 _sbBal = IERC20(stablecoin).balanceOf(address(this));
        uint256 _clBal = IERC20(_collateral).balanceOf(address(this));

        IRadarUSD(stablecoin).burn(_sbBal);

        IERC20(_collateral).approve(yieldVault, _clBal);
        ILickHitter(yieldVault).deposit(_collateral, msg.sender, _clBal);
    }

    function repayHook(
        address _collateral,
        bytes calldata
    ) external override {
        // Since this is a mock swapper and it will already have stablecoin
        // Just receive collateral, burn it, and deposit stablecoin that it has

        uint256 _sbBal = IERC20(stablecoin).balanceOf(address(this));
        uint256 _clBal = IERC20(_collateral).balanceOf(address(this));

        IRadarUSD(_collateral).burn(_clBal);

        IERC20(stablecoin).approve(yieldVault, _sbBal);
        ILickHitter(yieldVault).deposit(stablecoin, msg.sender, _sbBal);
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "./../interfaces/IOracle.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./../interfaces/yearn/IYearnVaultV2.sol";
import "./../interfaces/curve/ICurvePool.sol";
import "./../interfaces/benqi/IBenqiStakedAvax.sol";
import "./../interfaces/benqi/IBenqiToken.sol";

/// @title LendingOracleAggregator
/// @author Radar Global ([email protected])
/// @notice Oracle aggregator supporting multiple
/// oracle types. Used in `LendingPair`
contract LendingOracleAggregator is IOracle {

    enum FeedType {
        ChainlinkDirect,
        ChainlinkETH,
        ChainlinkYearnUnderlying,
        CurveLPVirtualPricePeggedAssets,
        AvalancheBENQIsAvax,
        AvalancheBENQIAsset
    }

    mapping(address => address) private feeds;
    mapping(address => uint8) private feedDecimals;
    mapping(address => FeedType) private feedTypes;
    address private chainlinkETHFeed;

    mapping(address => bytes) private oracle_metadata;

    address private owner;
    address private pendingOwner;

    event FeedModified(
        address indexed token,
        address indexed feed,
        FeedType feedType,
        uint8 decimals
    );

    modifier onlyOwner {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    constructor(
        address[] memory _tokens,
        FeedType[] memory _feedTypes,
        address[] memory _feeds,
        uint8[] memory _feedDecimals,
        bytes[] memory _oracleMetadata,
        address _chainlinkETHFeed
    ) {
        owner = msg.sender;
        chainlinkETHFeed = _chainlinkETHFeed;
        require(_tokens.length == _feedTypes.length && _feedTypes.length == _feeds.length && _feeds.length == _feedDecimals.length && _feedDecimals.length == _oracleMetadata.length, "Invalid Data");
        for(uint256 i = 0; i < _tokens.length; i++) {
            address _token = _tokens[i];
            feeds[_token] = _feeds[i];
            feedTypes[_token] = _feedTypes[i];
            feedDecimals[_token] = _feedDecimals[i];
            oracle_metadata[_token] = _oracleMetadata[i];
            emit FeedModified(_token, _feeds[i], _feedTypes[i], _feedDecimals[i]);
        }
    }

    // Owner functions

    function editFeed(address _token, address _feed, FeedType _ft, uint8 _decs, bytes calldata _metadata) external onlyOwner {
        feedTypes[_token] = _ft;
        feeds[_token] = _feed;
        feedDecimals[_token] = _decs;
        oracle_metadata[_token] = _metadata;
        emit FeedModified(_token, _feed, _ft, _decs);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        pendingOwner = _newOwner;
    }

    function claimOwnership() external {
        require(msg.sender == pendingOwner, "Unauthorized");
        owner = pendingOwner;
        pendingOwner = address(0);
    }

    // Oracle Aggregator

    /// @notice Returns USD price of a token with 18 decimals
    /// @param _token Address of token
    /// @return USD Price with 18 decimals
    function getUSDPrice(address _token) external view override returns (uint256) {
        return _getUSDPrice(_token);
    }

    function _getUSDPrice(address _token) internal view returns (uint256) {
        address _feed = feeds[_token];
        FeedType _ft = feedTypes[_token];
        require(_feed != address(0), "Invalid Feed");

        if (_ft == FeedType.ChainlinkDirect) {
            uint256 price = _chainlinkPrice(_feed);

            // Convert to 18 decimals
            return price * (10**(18 - feedDecimals[_token]));
        } else if (_ft == FeedType.ChainlinkETH) {
            uint256 _ethPrice = _chainlinkPrice(chainlinkETHFeed);
            uint256 _ethValue = _chainlinkPrice(_feed);

            return (_ethPrice * _ethValue) / (10**8);
        } else if(_ft == FeedType.ChainlinkYearnUnderlying) {
            uint256 _underlyingValue = _chainlinkPrice(_feed);

            uint256 _sharePrice = IYearnVaultV2(_token).pricePerShare();
            uint8 _assetDecimals = IYearnVaultV2(_token).decimals();

            uint256 _tokenPrice = (_underlyingValue * _sharePrice) / (10**_assetDecimals);

            // Convert to 18 decimals
            return _tokenPrice * (10**(18 - feedDecimals[_token]));
        } else if(_ft == FeedType.CurveLPVirtualPricePeggedAssets) {
            uint256 _virtualPrice = ICurvePool(_feed).get_virtual_price();

            // Get price of underlying asset
            (address _underlyingAsset) = abi.decode(oracle_metadata[_token], (address));
            uint256 _underlyingPrice = _getUSDPrice(_underlyingAsset);

            return (_underlyingPrice * _virtualPrice) / (10**18);
        } else if(_ft == FeedType.AvalancheBENQIsAvax) {
            (address _avax) = abi.decode(oracle_metadata[_token], (address));
            uint256 _avaxPrice = _getUSDPrice(_avax);

            uint256 _totalSupply = IBenqiStakedAvax(_feed).totalSupply();
            uint256 _totalPooledAvax = IBenqiStakedAvax(_feed).totalPooledAvax();

            return (_avaxPrice * _totalPooledAvax) / _totalSupply;
        } else if(_ft == FeedType.AvalancheBENQIAsset) {
            (address _underlying, uint256 _underlyingDecimals) = abi.decode(oracle_metadata[_token], (address,uint256));
            uint256 _underlyingPrice = _getUSDPrice(_underlying);

            uint256 _benqiExchangeRate = IBenqiToken(_feed).exchangeRateStored();

            uint256 _unscaledPrice = (_underlyingPrice * _benqiExchangeRate) / (10**18);

            // All Benqi assets have 8 decimals
            if (_underlyingDecimals < 8) {
                return _unscaledPrice * (10**(8-_underlyingDecimals));
            } else {
                return _unscaledPrice / (10**(_underlyingDecimals-8));
            }
        } else {
            revert("Dangerous Call");
        }
    }

    function _chainlinkPrice(address _feed) internal view returns (uint256) {
        (
                /*uint80 roundID*/,
                int _p,
                /*uint startedAt*/,
                /*uint timeStamp*/,
                /*uint80 answeredInRound*/
            ) = AggregatorV3Interface(_feed).latestRoundData();

            require(_p > 0, "Oracle failure");

            return uint256(_p);
    }

    // State Getters
    
    /// @return Owner of the contract
    function getOwner() external view returns (address) {
        return owner;
    }

    /// @return Pending owner of the contract before accepting ownership
    function getPendingOwner() external view returns (address) {
        return pendingOwner;
    }

    /// @return Feed, feed type and feed decimals of a token
    /// @param _token Address of the token
    function getFeed(address _token) external view returns (address, FeedType, uint8) {
        return (feeds[_token], feedTypes[_token], feedDecimals[_token]);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

interface IBenqiStakedAvax {
    function totalSupply() external view returns (uint256);

    function totalPooledAvax() external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./../interfaces/IOracle.sol";

contract MockOracle is IOracle {
    uint256 private price;
    address private mockToken;

    constructor(address _token, uint256 _price) {
        mockToken = _token;
        price = _price;
    }

    function changePrice(uint256 _newPrice) external {
        price = _newPrice;
    }

    function getUSDPrice(address _token) external view override returns (uint256) {
        if (_token != mockToken) {
            return 0;
        }

        return price;
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../../interfaces/ISwapper.sol";
import "./../../interfaces/ILiquidator.sol";
import "./../../interfaces/curve/ICurvePool.sol";
import "./../../interfaces/ILickHitter.sol";

contract CurveTricryptoLPSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private immutable yieldVault;

    address private immutable USDR;
    address private immutable CURVE_USDR_av3Crv_POOL;

    address private constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
    address private constant tricryptoPool = 0xB755B949C126C04e0348DD881a5cF55d424742B2;
    address private constant tricryptoLp = 0x1daB6560494B04473A0BE3E7D83CF3Fdf3a51828;

    constructor(
        address _yv,
        address _usdr,
        address _usdrPool
    ) {
        yieldVault = _yv;
        USDR = _usdr;
        CURVE_USDR_av3Crv_POOL = _usdrPool;

        IERC20(_usdr).safeApprove(_usdrPool, MAX_UINT);
        IERC20(av3Crv).safeApprove(tricryptoPool, MAX_UINT);
        IERC20(tricryptoLp).safeApprove(_yv, MAX_UINT);

        IERC20(tricryptoLp).safeApprove(tricryptoPool, MAX_UINT);
        IERC20(av3Crv).safeApprove(_usdrPool,  MAX_UINT);
        IERC20(_usdr).safeApprove(_yv, MAX_UINT);
    }

    function depositHook(
        address,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minTricryptoLP) = abi.decode(data, (uint256,uint256));

        // Swap USDR to av3Crv
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(0, 1, _usdrBal, _minav3Crv, address(this));

        // Swap av3Crv to TriCryptoLP
        uint256 _avBal = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(tricryptoPool).add_liquidity([_avBal, 0, 0], _minTricryptoLP);

        // Deposit to LickHitter
        uint256 _lpBal = IERC20(tricryptoLp).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(tricryptoLp, msg.sender, _lpBal);
    }

    function repayHook(
        address,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256));

        _swapTricryptoLP2USDR(_minav3Crv, _minUSDR);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    function liquidateHook(
        address,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256));

        _swapTricryptoLP2USDR(_minav3Crv, _minUSDR);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapTricryptoLP2USDR(uint256 _minav3Crv, uint256 _minUSDR) internal {
        uint256 _lpBal = IERC20(tricryptoLp).balanceOf(address(this));
        IAvaxV2Pool(tricryptoPool).remove_liquidity_one_coin(_lpBal, 0, _minav3Crv);

        uint256 _avBal = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(1, 0, _avBal, _minUSDR, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../../interfaces/ISwapper.sol";
import "./../../interfaces/ILiquidator.sol";
import "./../../interfaces/curve/ICurvePool.sol";
import "./../../interfaces/ILickHitter.sol";

contract CurveAaveUnderlyingSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private immutable yieldVault;

    address private immutable USDR;
    address private immutable CURVE_USDR_av3Crv_POOL;

    address private constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;
    address private constant av3Crv_POOL = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;

    address private constant DAI = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;
    address private constant USDC = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address private constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    constructor(
        address _yv,
        address _usdr,
        address _usdrPool
    ) {
        yieldVault = _yv;
        USDR = _usdr;
        CURVE_USDR_av3Crv_POOL = _usdrPool;

        IERC20(_usdr).safeApprove(_usdrPool, MAX_UINT);
        IERC20(DAI).safeApprove(_yv, MAX_UINT);
        IERC20(USDC).safeApprove(_yv, MAX_UINT);
        IERC20(USDT).safeApprove(_yv, MAX_UINT);

        IERC20(DAI).safeApprove(av3Crv_POOL, MAX_UINT);
        IERC20(USDC).safeApprove(av3Crv_POOL, MAX_UINT);
        IERC20(USDT).safeApprove(av3Crv_POOL, MAX_UINT);
        IERC20(av3Crv).safeApprove(_usdrPool, MAX_UINT);
        IERC20(_usdr).safeApprove(_yv, MAX_UINT);
    }

    function depositHook(
        address _collateral,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minAsset) = abi.decode(data, (uint256,uint256));

        // Swap USDR to av3Crv
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(0, 1, _usdrBal, _minav3Crv, address(this));

        // Swap av3Crv to asset
        uint256 _av3CrvBal = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(av3Crv_POOL).remove_liquidity_one_coin(_av3CrvBal, _getTokenId(_collateral), _minAsset, true);

        // Deposit to LickHitter
        uint256 _colBal = IERC20(_collateral).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(_collateral, msg.sender, _colBal);
    }

    function repayHook(
        address _collateral,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256));

        _swapAsset2USDR(_collateral, _minav3Crv, _minUSDR);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    function liquidateHook(
        address _collateral,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv, uint256 _minUSDR) = abi.decode(data, (uint256,uint256));

        _swapAsset2USDR(_collateral, _minav3Crv, _minUSDR);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapAsset2USDR(address _token, uint256 _minav3Crv, uint256 _minUSDR) internal {
        uint256 _assetBal = IERC20(_token).balanceOf(address(this));
        ICurvePool(av3Crv_POOL).add_liquidity(_getAmounts(_token, _assetBal), _minav3Crv, true);

        uint256 _avBal = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(1, 0, _avBal, _minUSDR, address(this));
    }

    function _getTokenId(address _token) internal pure returns (int128) {
        if  (_token == DAI) {
            return 0;
        } else if (_token == USDC) {
            return 1;
        } else if (_token == USDT) {
            return 2;
        } else {
            return 100; // Invalid
        }
    }

    function _getAmounts(address _token, uint256 _bal) internal pure returns (uint256[3] memory) {
        if  (_token == DAI) {
            return [_bal, 0, 0];
        } else if (_token == USDC) {
            return [0, _bal, 0];
        } else if (_token == USDT) {
            return [0, 0, _bal];
        } else {
            return [_bal, _bal, _bal]; // Invalid
        }
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../../interfaces/ISwapper.sol";
import "./../../interfaces/ILiquidator.sol";
import "./../../interfaces/curve/ICurvePool.sol";
import "./../../interfaces/ILickHitter.sol";

contract CurveAaveLPSwapper is ISwapper, ILiquidator {
    using SafeERC20 for IERC20;

    uint256 constant MAX_UINT = 2**256 - 1;

    address private immutable yieldVault;

    address private immutable USDR;
    address private immutable CURVE_USDR_av3Crv_POOL;

    address private constant av3Crv_POOL = 0x7f90122BF0700F9E7e1F688fe926940E8839F353;
    address private constant av3Crv = 0x1337BedC9D22ecbe766dF105c9623922A27963EC;

    constructor(
        address _yv,
        address _usdr,
        address _usdrPool
    ) {
        yieldVault = _yv;
        USDR = _usdr;
        CURVE_USDR_av3Crv_POOL = _usdrPool;

        IERC20(_usdr).safeApprove(_usdrPool, MAX_UINT);
        IERC20(av3Crv).safeApprove(_yv, MAX_UINT);

        IERC20(av3Crv).safeApprove(_usdrPool, MAX_UINT);
        IERC20(_usdr).safeApprove(_yv,  MAX_UINT);
    }

    function depositHook(
        address,
        bytes calldata data
    ) external override {
        (uint256 _minav3Crv) = abi.decode(data, (uint256));

        // Swap USDR to av3Crv
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(0, 1, _usdrBal, _minav3Crv, address(this));

        // Deposit to LickHitter
        uint256 _avBal = IERC20(av3Crv).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(av3Crv, msg.sender, _avBal);
    }

    function repayHook(
        address,
         bytes calldata data
    ) external override {
        (uint256 _minUSDR) = abi.decode(data, (uint256));

        _swapav3Crv2USDR(_minUSDR);

        // Deposit to LickHitter
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        ILickHitter(yieldVault).deposit(USDR, msg.sender, _usdrBal);
    }

    function liquidateHook(
        address,
        address _initiator,
        uint256 _repayAmount,
        uint256,
        bytes calldata data
    ) external override {
        (uint256 _minUSDR) = abi.decode(data, (uint256));

        _swapav3Crv2USDR(_minUSDR);

        ILickHitter(yieldVault).deposit(USDR, msg.sender, _repayAmount);

        // Profit goes to initiator
        uint256 _usdrBal = IERC20(USDR).balanceOf(address(this));
        IERC20(USDR).transfer(_initiator, _usdrBal);
    }

    function _swapav3Crv2USDR(uint256 _minUSDR) internal {
        // Swap av3Crv to USDR
        uint256 _av3CrvBal = IERC20(av3Crv).balanceOf(address(this));
        ICurvePool(CURVE_USDR_av3Crv_POOL).exchange(1, 0, _av3CrvBal, _minUSDR, address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.2;

import "./../interfaces/ILiquidator.sol";
import "./../interfaces/ILickHitter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockLiquidator is ILiquidator {

    address private stablecoin;
    address private lp;
    address private yv;

    event LiqDebugEvent(
        address token,
        address initiator,
        uint256 totalRepayAmount,
        uint256 totalCollateralReceived
    );

    constructor(address _sb, address _lp, address _yv) {
        stablecoin = _sb;
        lp = _lp;
        yv = _yv;
    }

    function liquidateHook(
        address _token,
        address _initiator,
        uint256 _repayAmount,
        uint256 _collateralLiquidated,
        bytes calldata
    ) external override {
        require(msg.sender == lp);
        // Just receive collateral and deposit for repay amount
        IERC20(stablecoin).approve(yv, _repayAmount);
        ILickHitter(yv).deposit(stablecoin, lp, _repayAmount);
        emit LiqDebugEvent(_token, _initiator, _repayAmount, _collateralLiquidated);
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2022 RedaOps - All rights reserved
// Telegram: @tudorog

// Version: 19-May-2022
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract DurationFixedRewardsFarmPool {
    using Address for address;
    using SafeERC20 for IERC20;

    uint256 public duration;
    address public rewardToken;
    address public depositToken;

    uint256 public finishTimestamp = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTimestamp;
    uint256 public cacheRewardPerToken;
    mapping(address => uint256) public userReward;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    address private owner;

    event RewardAdded(uint256 rewardAmount);
    event Staked(address indexed who, uint256 amount);
    event Withdraw(address indexed who, uint256 amount);
    event GotReward(address indexed who, uint256 rewardAmount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Unauthorized");
        _;
    }

    modifier updateReward(address account) {
        cacheRewardPerToken = rewardPerToken();
        lastUpdateTimestamp = lastTimeRewardApplicable();
        if(account != address(0)) {
            rewards[account] = earned(account);
            userReward[account] = cacheRewardPerToken;
        }
        _;
    }

    constructor(
        address _rewardToken,
        address _depositToken,
        uint256 _stakingDurationRewardPay
    ) {
        rewardToken = _rewardToken;
        depositToken = _depositToken;
        duration = _stakingDurationRewardPay;

        owner = msg.sender;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        if (block.timestamp <= finishTimestamp) {
            return block.timestamp;
        } else {
            return finishTimestamp;
        }
    }

    function rewardPerToken() public view returns (uint256) {
        if (totalSupply() == 0) {
            return cacheRewardPerToken;
        }
        return
            cacheRewardPerToken + ((lastTimeRewardApplicable() - lastUpdateTimestamp) * rewardRate * 1e18 / totalSupply());
    }

    function earned(address account) public view returns (uint256) {
        return (balanceOf(account) * (rewardPerToken() - userReward[account]) / 1e18) + rewards[account];
    }

    function stake(uint256 amount, address target) external updateReward(target) {
        require(amount > 0, "Amount cannot be 0");
        require(target != address(0), "Staking to 0x0");
        IERC20(depositToken).safeTransferFrom(msg.sender, address(this), amount);
        _totalSupply = _totalSupply + amount;
        _balances[target] = _balances[target] + amount;
        emit Staked(target, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Amount cannot be 0");
        require(_balances[msg.sender] >= amount, "Withdraw overflow");
        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = _balances[msg.sender] - amount;
        IERC20(depositToken).safeTransfer(msg.sender, amount);
        emit Withdraw(msg.sender, amount);
    }

    function exit() external {
        withdraw(balanceOf(msg.sender));
        getReward();
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = earned(msg.sender);
        if (address(depositToken) == address(rewardToken)) {
            uint256 _tokenBal = IERC20(depositToken).balanceOf(address(this));
            require(_tokenBal - reward >= _totalSupply, "Extra security check failed.");
        }
        if (reward > 0) {
            rewards[msg.sender] = 0;
            IERC20(rewardToken).safeTransfer(msg.sender, reward);
            emit GotReward(msg.sender, reward);
        }
    }

    function pushReward(address recipient) external updateReward(recipient) onlyOwner {
        uint256 reward = earned(recipient);
        if (reward > 0) {
            rewards[recipient] = 0;
            IERC20(rewardToken).safeTransfer(recipient, reward);
            emit GotReward(recipient, reward);
        }
    }

    function addedReward(uint256 reward) external onlyOwner updateReward(address(0)) {
        if (block.timestamp >= finishTimestamp) {
            rewardRate = reward / duration;
        } else {
            uint256 remaining = finishTimestamp - block.timestamp;
            uint256 leftover = remaining * rewardRate;
            rewardRate = (reward + leftover) / duration;
        }
        lastUpdateTimestamp = block.timestamp;
        finishTimestamp = block.timestamp + duration;
        emit RewardAdded(reward);
    }
}