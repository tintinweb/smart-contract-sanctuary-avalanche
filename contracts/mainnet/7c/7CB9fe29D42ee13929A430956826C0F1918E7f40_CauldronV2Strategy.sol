// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2021 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "./POLE.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ISwapper.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

/// @title Cauldron
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract CauldronV2MultiChain is BoringOwnable, IMasterContract {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    event LogExchangeRate(uint256 rate);
    event LogAccrue(uint128 accruedAmount);
    event LogAddCollateral(address indexed from, address indexed to, uint256 share);
    event LogRemoveCollateral(address indexed from, address indexed to, uint256 share);
    event LogBorrow(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogRepay(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogFeeTo(address indexed newFeeTo);
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);
    event LogsetDistributionPart(uint256 amount);

    // Immutables (for MasterContract and all clones)
    IBentoBoxV1 public immutable bentoBox;
    CauldronV2MultiChain public immutable masterContract;
    IERC20 public immutable POLE;

    // MasterContract variables
    address public feeTo;

    // Per clone variables
    // Clone init settings
    IERC20 public collateral;
    IOracle public oracle;
    bytes public oracleData;

    // Total amounts
    uint256 public totalCollateralShare; // Total collateral supplied
    Rebase public totalBorrow; // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers

    // User balances
    mapping(address => uint256) public userCollateralShare;
    mapping(address => uint256) public userBorrowPart;
    bool public liquidateManagerOpen;
    mapping(address => bool) public liquidateManager;

    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    uint256 public exchangeRate;

    struct AccrueInfo {
        uint64 lastAccrued;
        uint128 feesEarned;
        uint64 INTEREST_PER_SECOND;
    }

    AccrueInfo public accrueInfo;

    // Settings
    uint256 public COLLATERIZATION_RATE;
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)

    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 public LIQUIDATION_MULTIPLIER; 
    uint256 private constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

    uint256 public BORROW_OPENING_FEE;
    uint256 private constant BORROW_OPENING_FEE_PRECISION = 1e5;

    uint256 private DISTRIBUTION_PART = 10;
    uint256 private constant DISTRIBUTION_PRECISION = 100;

    address[] public userList; 
    mapping(address => uint256) public positionId; 
    

    /// @notice The constructor is only used for the initial master contract. Subsequent clones are initialised via `init`.
    constructor(IBentoBoxV1 bentoBox_, IERC20 POLE_) public {
        bentoBox = bentoBox_;
        POLE = POLE_;
        masterContract = this;
    }

    /// @notice Serves as the constructor for clones, as clones can't have a regular constructor
    /// @dev `data` is abi encoded in the format: (IERC20 collateral, IERC20 asset, IOracle oracle, bytes oracleData)
    function init(bytes calldata data) public payable override {
        require(address(collateral) == address(0), "Cauldron: already initialized");
        (collateral, oracle, oracleData, accrueInfo.INTEREST_PER_SECOND, LIQUIDATION_MULTIPLIER, COLLATERIZATION_RATE, BORROW_OPENING_FEE) = abi.decode(data, (IERC20, IOracle, bytes, uint64, uint256, uint256, uint256));
        require(address(collateral) != address(0), "Cauldron: bad pair");
        userList.push(address(0));
        liquidateManagerOpen = true;
    }

    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    function accrue() public {
        AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        _accrueInfo.lastAccrued = uint64(block.timestamp);

        Rebase memory _totalBorrow = totalBorrow;
        if (_totalBorrow.base == 0) {
            accrueInfo = _accrueInfo;
            return;
        }

        // Accrue interest
        uint128 extraAmount = (uint256(_totalBorrow.elastic).mul(_accrueInfo.INTEREST_PER_SECOND).mul(elapsedTime) / 1e18).to128();
        _totalBorrow.elastic = _totalBorrow.elastic.add(extraAmount);

        _accrueInfo.feesEarned = _accrueInfo.feesEarned.add(extraAmount);
        totalBorrow = _totalBorrow;
        accrueInfo = _accrueInfo;

        emit LogAccrue(extraAmount);
    }

    /// @notice Concrete implementation of `isSolvent`. Includes a third parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(address user, uint256 _exchangeRate) internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = userCollateralShare[user];
        if (collateralShare == 0) return false;

        Rebase memory _totalBorrow = totalBorrow;

        return
            bentoBox.toAmount(
                collateral,
                collateralShare.mul(EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION).mul(COLLATERIZATION_RATE),
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            borrowPart.mul(_totalBorrow.elastic).mul(_exchangeRate) / _totalBorrow.base;
    }

    /// @dev Checks if the user is solvent in the closed liquidation case at the end of the function body.
    modifier solvent() {
        _;
        require(_isSolvent(msg.sender, exchangeRate), "Cauldron: user insolvent");
    }

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() public returns (bool updated, uint256 rate) {
        (updated, rate) = oracle.get(oracleData);

        if (updated) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        } else {
            // Return the old rate if fetching wasn't successful
            rate = exchangeRate;
        }
    }

    /// @dev Helper function to move tokens.
    /// @param token The ERC-20 token.
    /// @param share The amount in shares to add.
    /// @param total Grand total amount to deduct from this contract's balance. Only applicable if `skim` is True.
    /// Only used for accounting checks.
    /// @param skim If True, only does a balance check on this contract.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    function _addTokens(
        IERC20 token,
        uint256 share,
        uint256 total,
        bool skim
    ) internal {
        if (skim) {
            require(share <= bentoBox.balanceOf(token, address(this)).sub(total), "Cauldron: Skim too much");
        } else {
            bentoBox.transfer(token, msg.sender, address(this), share);
        }
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.x
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(
        address to,
        bool skim,
        uint256 share
    ) public {
        userCollateralShare[to] = userCollateralShare[to].add(share);
        uint256 oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare = oldTotalCollateralShare.add(share);
        _addTokens(collateral, share, oldTotalCollateralShare, skim);
        emit LogAddCollateral(skim ? address(bentoBox) : msg.sender, to, share);
    }

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(address to, uint256 share) internal {
        userCollateralShare[msg.sender] = userCollateralShare[msg.sender].sub(share);
        totalCollateralShare = totalCollateralShare.sub(share);
        emit LogRemoveCollateral(msg.sender, to, share);
        bentoBox.transfer(collateral, address(this), to, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(address to, uint256 share) public solvent {
        // accrue must be called because we check solvency
        accrue();
        _removeCollateral(to, share);
    }

    /// @dev Concrete implementation of `borrow`.
    function _borrow(address to, uint256 amount) internal returns (uint256 part, uint256 share) {
        uint256 feeAmount = amount.mul(BORROW_OPENING_FEE) / BORROW_OPENING_FEE_PRECISION; // A flat % fee is charged for any borrow
        (totalBorrow, part) = totalBorrow.add(amount.add(feeAmount), true);
        accrueInfo.feesEarned = accrueInfo.feesEarned.add(uint128(feeAmount));
        userBorrowPart[msg.sender] = userBorrowPart[msg.sender].add(part);
        if(userBorrowPart[msg.sender]>0){
            addUserListAndPositionId(msg.sender);
        }
        // As long as there are tokens on this contract you can 'mint'... this enables limiting borrows
        share = bentoBox.toShare(POLE, amount, false);
        bentoBox.transfer(POLE, address(this), to, share);

        emit LogBorrow(msg.sender, to, amount.add(feeAmount), part);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(address to, uint256 amount) public solvent returns (uint256 part, uint256 share) {
        accrue();
        (part, share) = _borrow(to, amount);
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(
        address to,
        bool skim,
        uint256 part
    ) internal returns (uint256 amount) {
        (totalBorrow, amount) = totalBorrow.sub(part, true);
        userBorrowPart[to] = userBorrowPart[to].sub(part);
        if(userBorrowPart[to]==0){
            delUserListAndPositionId(to);
        }
        uint256 share = bentoBox.toShare(POLE, amount, true);
        bentoBox.transfer(POLE, skim ? address(bentoBox) : msg.sender, address(this), share);
        emit LogRepay(skim ? address(bentoBox) : msg.sender, to, amount, part);
    }

    /// @notice Repays a loan.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(
        address to,
        bool skim,
        uint256 part
    ) public returns (uint256 amount) {
        accrue();
        amount = _repay(to, skim, part);
    }

    // Functions that need accrue to be called
    uint8 internal constant ACTION_REPAY = 2;
    uint8 internal constant ACTION_REMOVE_COLLATERAL = 4;
    uint8 internal constant ACTION_BORROW = 5;
    uint8 internal constant ACTION_GET_REPAY_SHARE = 6;
    uint8 internal constant ACTION_GET_REPAY_PART = 7;
    uint8 internal constant ACTION_ACCRUE = 8;

    // Functions that don't need accrue to be called
    uint8 internal constant ACTION_ADD_COLLATERAL = 10;
    uint8 internal constant ACTION_UPDATE_EXCHANGE_RATE = 11;

    // Function on BentoBox
    uint8 internal constant ACTION_BENTO_DEPOSIT = 20;
    uint8 internal constant ACTION_BENTO_WITHDRAW = 21;
    uint8 internal constant ACTION_BENTO_TRANSFER = 22;
    uint8 internal constant ACTION_BENTO_TRANSFER_MULTIPLE = 23;
    uint8 internal constant ACTION_BENTO_SETAPPROVAL = 24;

    // Any external call (except to BentoBox)
    uint8 internal constant ACTION_CALL = 30;

    int256 internal constant USE_VALUE1 = -1;
    int256 internal constant USE_VALUE2 = -2;

    /// @dev Helper function for choosing the correct value (`value1` or `value2`) depending on `inNum`.
    function _num(
        int256 inNum,
        uint256 value1,
        uint256 value2
    ) internal pure returns (uint256 outNum) {
        outNum = inNum >= 0 ? uint256(inNum) : (inNum == USE_VALUE1 ? value1 : value2);
    }

    /// @dev Helper function for depositing into `bentoBox`.
    function _bentoDeposit(
        bytes memory data,
        uint256 value,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        amount = int256(_num(amount, value1, value2)); // Done this way to avoid stack too deep errors
        share = int256(_num(share, value1, value2));
        return bentoBox.deposit{value: value}(token, msg.sender, to, uint256(amount), uint256(share));
    }

    /// @dev Helper function to withdraw from the `bentoBox`.
    function _bentoWithdraw(
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        return bentoBox.withdraw(token, msg.sender, to, _num(amount, value1, value2), _num(share, value1, value2));
    }

    /// @dev Helper function to perform a contract call and eventually extracting revert messages on failure.
    /// Calls to `bentoBox` are not allowed for obvious security reasons.
    /// This also means that calls made from this contract shall *not* be trusted.
    function _call(
        uint256 value,
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (bytes memory, uint8) {
        (address callee, bytes memory callData, bool useValue1, bool useValue2, uint8 returnValues) =
            abi.decode(data, (address, bytes, bool, bool, uint8));

        if (useValue1 && !useValue2) {
            callData = abi.encodePacked(callData, value1);
        } else if (!useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value2);
        } else if (useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value1, value2);
        }

        require(callee != address(bentoBox) && callee != address(this), "Cauldron: can't call");

        (bool success, bytes memory returnData) = callee.call{value: value}(callData);
        require(success, "Cauldron: call failed");
        return (returnData, returnValues);
    }

    struct CookStatus {
        bool needsSolvencyCheck;
        bool hasAccrued;
    }

    /// @notice Executes a set of actions and allows composability (contract calls) to other contracts.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. ETH amounts to send along with the actions.
    /// Only applicable to `ACTION_CALL`, `ACTION_BENTO_DEPOSIT`.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    /// @return value1 May contain the first positioned return value of the last executed action (if applicable).
    /// @return value2 May contain the second positioned return value of the last executed action which returns 2 values (if applicable).
    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2) {
        CookStatus memory status;
        for (uint256 i = 0; i < actions.length; i++) {
            uint8 action = actions[i];
            if (!status.hasAccrued && action < 10) {
                accrue();
                status.hasAccrued = true;
            }
            if (action == ACTION_ADD_COLLATERAL) {
                (int256 share, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                addCollateral(to, skim, _num(share, value1, value2));
            } else if (action == ACTION_REPAY) {
                (int256 part, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                _repay(to, skim, _num(part, value1, value2));
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                (int256 share, address to) = abi.decode(datas[i], (int256, address));
                _removeCollateral(to, _num(share, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_BORROW) {
                (int256 amount, address to) = abi.decode(datas[i], (int256, address));
                (value1, value2) = _borrow(to, _num(amount, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_UPDATE_EXCHANGE_RATE) {
                (bool must_update, uint256 minRate, uint256 maxRate) = abi.decode(datas[i], (bool, uint256, uint256));
                (bool updated, uint256 rate) = updateExchangeRate();
                require((!must_update || updated) && rate > minRate && (maxRate == 0 || rate > maxRate), "Cauldron: rate not ok");
            } else if (action == ACTION_BENTO_SETAPPROVAL) {
                (address user, address _masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) =
                    abi.decode(datas[i], (address, address, bool, uint8, bytes32, bytes32));
                bentoBox.setMasterContractApproval(user, _masterContract, approved, v, r, s);
            } else if (action == ACTION_BENTO_DEPOSIT) {
                (value1, value2) = _bentoDeposit(datas[i], values[i], value1, value2);
            } else if (action == ACTION_BENTO_WITHDRAW) {
                (value1, value2) = _bentoWithdraw(datas[i], value1, value2);
            } else if (action == ACTION_BENTO_TRANSFER) {
                (IERC20 token, address to, int256 share) = abi.decode(datas[i], (IERC20, address, int256));
                bentoBox.transfer(token, msg.sender, to, _num(share, value1, value2));
            } else if (action == ACTION_BENTO_TRANSFER_MULTIPLE) {
                (IERC20 token, address[] memory tos, uint256[] memory shares) = abi.decode(datas[i], (IERC20, address[], uint256[]));
                bentoBox.transferMultiple(token, msg.sender, tos, shares);
            } else if (action == ACTION_CALL) {
                (bytes memory returnData, uint8 returnValues) = _call(values[i], datas[i], value1, value2);
                if (returnValues == 1) {
                    (value1) = abi.decode(returnData, (uint256));
                } else if (returnValues == 2) {
                    (value1, value2) = abi.decode(returnData, (uint256, uint256));
                }
            } else if (action == ACTION_GET_REPAY_SHARE) {
                int256 part = abi.decode(datas[i], (int256));
                value1 = bentoBox.toShare(POLE, totalBorrow.toElastic(_num(part, value1, value2), true), true);
            } else if (action == ACTION_GET_REPAY_PART) {
                int256 amount = abi.decode(datas[i], (int256));
                value1 = totalBorrow.toBase(_num(amount, value1, value2), false);
            }
        }

        if (status.needsSolvencyCheck) {
            require(_isSolvent(msg.sender, exchangeRate), "Cauldron: user insolvent");
        }
    }

    /// @notice Handles the liquidation of users' balances, once the users' amount of collateral is too low.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    /// @param to Address of the receiver in open liquidations if `swapper` is zero.
    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        ISwapper swapper
    ) public {
        if(liquidateManagerOpen){
            require(liquidateManager[msg.sender], "liquidateManager err");
        }
        // Oracle can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = updateExchangeRate();
        accrue();

        uint256 allCollateralShare;
        uint256 allBorrowAmount;
        uint256 allBorrowPart;
        Rebase memory _totalBorrow = totalBorrow;
        Rebase memory bentoBoxTotals = bentoBox.totals(collateral);
        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!_isSolvent(user, _exchangeRate)) {
                uint256 borrowPart;
                {
                    uint256 availableBorrowPart = userBorrowPart[user];
                    borrowPart = maxBorrowParts[i] > availableBorrowPart ? availableBorrowPart : maxBorrowParts[i];
                    userBorrowPart[user] = availableBorrowPart.sub(borrowPart);
                    if(userBorrowPart[user]==0){
                        delUserListAndPositionId(user);
                    }
                }
                uint256 borrowAmount = _totalBorrow.toElastic(borrowPart, false);
                uint256 collateralShare =
                    bentoBoxTotals.toBase(
                        borrowAmount.mul(LIQUIDATION_MULTIPLIER).mul(_exchangeRate) /
                            (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
                        false
                    );

                userCollateralShare[user] = userCollateralShare[user].sub(collateralShare);
                emit LogRemoveCollateral(user, to, collateralShare);
                emit LogRepay(msg.sender, user, borrowAmount, borrowPart);

                // Keep totals
                allCollateralShare = allCollateralShare.add(collateralShare);
                allBorrowAmount = allBorrowAmount.add(borrowAmount);
                allBorrowPart = allBorrowPart.add(borrowPart);
            }
        }
        require(allBorrowAmount != 0, "Cauldron: all are solvent");
        _totalBorrow.elastic = _totalBorrow.elastic.sub(allBorrowAmount.to128());
        _totalBorrow.base = _totalBorrow.base.sub(allBorrowPart.to128());
        totalBorrow = _totalBorrow;
        totalCollateralShare = totalCollateralShare.sub(allCollateralShare);

        // Apply a percentual fee share to sNORTH holders
        
        {
            uint256 distributionAmount = (allBorrowAmount.mul(LIQUIDATION_MULTIPLIER) / LIQUIDATION_MULTIPLIER_PRECISION).sub(allBorrowAmount).mul(DISTRIBUTION_PART) / DISTRIBUTION_PRECISION; // Distribution Amount
            allBorrowAmount = allBorrowAmount.add(distributionAmount);
            accrueInfo.feesEarned = accrueInfo.feesEarned.add(distributionAmount.to128());
        }

        uint256 allBorrowShare = bentoBox.toShare(POLE, allBorrowAmount, true);

        // Swap using a swapper freely chosen by the caller
        // Open (flash) liquidation: get proceeds first and provide the borrow after
        bentoBox.transfer(collateral, address(this), to, allCollateralShare);
        if (swapper != ISwapper(0)) {
            swapper.swap(collateral, POLE, msg.sender, allBorrowShare, allCollateralShare);
        }

        bentoBox.transfer(POLE, msg.sender, address(this), allBorrowShare);
    }

    /// @notice Withdraws the fees accumulated.
    function withdrawFees() public {
        accrue();
        address _feeTo = masterContract.feeTo();
        uint256 _feesEarned = accrueInfo.feesEarned;
        uint256 share = bentoBox.toShare(POLE, _feesEarned, false);
        bentoBox.transfer(POLE, address(this), _feeTo, share);
        accrueInfo.feesEarned = 0;

        emit LogWithdrawFees(_feeTo, _feesEarned);
    }

    /// @notice Sets the beneficiary of interest accrued.
    /// MasterContract Only Admin function.
    /// @param newFeeTo The address of the receiver.
    function setFeeTo(address newFeeTo) public onlyOwner {
        feeTo = newFeeTo;
        emit LogFeeTo(newFeeTo);
    }

    /// @notice reduces the supply of POLE
    /// @param amount amount to reduce supply by
    function reduceSupply(uint256 amount) public {
        require(msg.sender == masterContract.owner(), "Caller is not the owner");
        bentoBox.withdraw(POLE, address(this), masterContract.owner(), amount, 0);
    }

    function setDistributionPart(uint256 amount) public {
        require(msg.sender == masterContract.owner(), "Caller is not the owner");
        DISTRIBUTION_PART = amount;
        emit LogsetDistributionPart(amount);
    }

    function userListLength() public view returns(uint256){
        return userList.length - 1;
    }

    function addUserListAndPositionId(address _user) internal returns(bool){
        require(_user!=address(0),"address cannot be 0");
        if(userList[positionId[_user]] == _user){
            return false;
        }
        positionId[_user]=userList.length;
        userList.push(_user);
        return true;
    }

    function delUserListAndPositionId(address _user) internal returns(bool){
        require(_user!=address(0),"address cannot be 0");

        if(userList[positionId[_user]] != _user){
            return false;
        }
        uint256 usersIndex = userList.length - 1; 
        uint256 delUserID= positionId[_user];

        address lastUserAddr = userList[usersIndex]; 

        userList[delUserID] = lastUserAddr;
        positionId[lastUserAddr] = delUserID;

        delete positionId[_user];
        userList.pop();

        return true;
    }

    //setLiquidateManagerOpen
    function setLiquidateManagerOpen(bool _val) public returns(bool){
        require(msg.sender == masterContract.owner(), "Caller is not the owner");
        liquidateManagerOpen = _val;
        return true;
    }

    //setLiquidateManager
    function setLiquidateManager(address _address,bool _val) public returns(bool){
        require(msg.sender == masterContract.owner(), "Caller is not the owner");
        liquidateManager[_address] = _val;
        return true;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/// @notice A library for performing overflow-/underflow-safe math,
/// updated with awesomeness from of DappHub (https://github.com/dapphub/ds-math).
library BoringMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b == 0 || (c = a * b) / b == a, "BoringMath: Mul Overflow");
    }

    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= uint128(-1), "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= uint64(-1), "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= uint32(-1), "BoringMath: uint32 Overflow");
        c = uint32(a);
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint128.
library BoringMath128 {
    function add(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint128 a, uint128 b) internal pure returns (uint128 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint64.
library BoringMath64 {
    function add(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint64 a, uint64 b) internal pure returns (uint64 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

/// @notice A library for performing overflow-/underflow-safe addition and subtraction on uint32.
library BoringMath32 {
    function add(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a + b) >= b, "BoringMath: Add Overflow");
    }

    function sub(uint32 a, uint32 b) internal pure returns (uint32 c) {
        require((c = a - b) <= a, "BoringMath: Underflow");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

// Audit on 5-Jan-2021 by Keno and BoringCrypto
// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Edited by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() public {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./interfaces/IERC20.sol";
import "./Domain.sol";

// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

// Data part taken out for building of contracts that receive delegate calls
contract ERC20Data {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;
}

abstract contract ERC20 is IERC20, Domain {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public override balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param amount of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 amount) public returns (bool) {
        // If `amount` is 0, or `msg.sender` is `to` nothing happens
        if (amount != 0 || msg.sender == to) {
            uint256 srcBalance = balanceOf[msg.sender];
            require(srcBalance >= amount, "ERC20: balance too low");
            if (msg.sender != to) {
                require(to != address(0), "ERC20: no zero address"); // Moved down so low balance calls safe some gas

                balanceOf[msg.sender] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param amount The token amount to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        // If `amount` is 0, or `from` is `to` nothing happens
        if (amount != 0) {
            uint256 srcBalance = balanceOf[from];
            require(srcBalance >= amount, "ERC20: balance too low");

            if (from != to) {
                uint256 spenderAllowance = allowance[from][msg.sender];
                // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
                if (spenderAllowance != type(uint256).max) {
                    require(spenderAllowance >= amount, "ERC20: allowance too low");
                    allowance[from][msg.sender] = spenderAllowance - amount; // Underflow is checked
                }
                require(to != address(0), "ERC20: no zero address"); // Moved down so other failed calls safe some gas

                balanceOf[from] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(
            ecrecover(_getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))), v, r, s) ==
                owner_,
            "ERC20: Invalid Signature"
        );
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }
}

contract ERC20WithSupply is IERC20, ERC20 {
    uint256 public override totalSupply;

    function _mint(address user, uint256 amount) private {
        uint256 newTotalSupply = totalSupply + amount;
        require(newTotalSupply >= totalSupply, "Mint overflow");
        totalSupply = newTotalSupply;
        balanceOf[user] += amount;
    }

    function _burn(address user, uint256 amount) private {
        require(balanceOf[user] >= amount, "Burn too much");
        totalSupply -= amount;
        balanceOf[user] -= amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "./BoringMath.sol";

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    using BoringMath for uint256;
    using BoringMath128 for uint128;

    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = elastic.mul(total.base) / total.elastic;
            if (roundUp && base.mul(total.elastic) / total.base < elastic) {
                base = base.add(1);
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = base.mul(total.elastic) / total.base;
            if (roundUp && elastic.mul(total.base) / total.elastic < base) {
                elastic = elastic.add(1);
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.add(elastic.to128());
        total.base = total.base.add(base.to128());
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic = total.elastic.sub(elastic.to128());
        total.base = total.base.sub(base.to128());
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic.add(elastic.to128());
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic = total.elastic.sub(elastic.to128());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../interfaces/IERC20.sol";

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while(i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import '@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol';
import '@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol';
import './IBatchFlashBorrower.sol';
import './IFlashBorrower.sol';
import './IStrategy.sol';

interface IBentoBoxV1 {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);
    event LogDeposit(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event LogFlashLoan(address indexed borrower, address indexed token, uint256 amount, uint256 feeAmount, address indexed receiver);
    event LogRegisterProtocol(address indexed protocol);
    event LogSetMasterContractApproval(address indexed masterContract, address indexed user, bool approved);
    event LogStrategyDivest(address indexed token, uint256 amount);
    event LogStrategyInvest(address indexed token, uint256 amount);
    event LogStrategyLoss(address indexed token, uint256 amount);
    event LogStrategyProfit(address indexed token, uint256 amount);
    event LogStrategyQueued(address indexed token, address indexed strategy);
    event LogStrategySet(address indexed token, address indexed strategy);
    event LogStrategyTargetPercentage(address indexed token, uint256 targetPercentage);
    event LogTransfer(address indexed token, address indexed from, address indexed to, uint256 share);
    event LogWhiteListMasterContract(address indexed masterContract, bool approved);
    event LogWithdraw(address indexed token, address indexed from, address indexed to, uint256 amount, uint256 share);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function balanceOf(IERC20, address) external view returns (uint256);
    function batch(bytes[] calldata calls, bool revertOnFail) external payable returns (bool[] memory successes, bytes[] memory results);
    function batchFlashLoan(IBatchFlashBorrower borrower, address[] calldata receivers, IERC20[] calldata tokens, uint256[] calldata amounts, bytes calldata data) external;
    function claimOwnership() external;
    function deploy(address masterContract, bytes calldata data, bool useCreate2) external payable;
    function deposit(IERC20 token_, address from, address to, uint256 amount, uint256 share) external payable returns (uint256 amountOut, uint256 shareOut);
    function flashLoan(IFlashBorrower borrower, address receiver, IERC20 token, uint256 amount, bytes calldata data) external;
    function harvest(IERC20 token, bool balance, uint256 maxChangeAmount) external;
    function masterContractApproved(address, address) external view returns (bool);
    function masterContractOf(address) external view returns (address);
    function nonces(address) external view returns (uint256);
    function owner() external view returns (address);
    function pendingOwner() external view returns (address);
    function pendingStrategy(IERC20) external view returns (IStrategy);
    function permitToken(IERC20 token, address from, address to, uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function registerProtocol() external;
    function setMasterContractApproval(address user, address masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) external;
    function setStrategy(IERC20 token, IStrategy newStrategy) external;
    function setStrategyTargetPercentage(IERC20 token, uint64 targetPercentage_) external;
    function strategy(IERC20) external view returns (IStrategy);
    function strategyData(IERC20) external view returns (uint64 strategyStartDate, uint64 targetPercentage, uint128 balance);
    function toAmount(IERC20 token, uint256 share, bool roundUp) external view returns (uint256 amount);
    function toShare(IERC20 token, uint256 amount, bool roundUp) external view returns (uint256 share);
    function totals(IERC20) external view returns (Rebase memory totals_);
    function transfer(IERC20 token, address from, address to, uint256 share) external;
    function transferMultiple(IERC20 token, address from, address[] calldata tos, uint256[] calldata shares) external;
    function transferOwnership(address newOwner, bool direct, bool renounce) external;
    function whitelistMasterContract(address masterContract, bool approved) external;
    function whitelistedMasterContracts(address) external view returns (bool);
    function withdraw(IERC20 token_, address from, address to, uint256 amount, uint256 share) external returns (uint256 amountOut, uint256 shareOut);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

/// @title Cauldron
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract POLE is ERC20, BoringOwnable {
    using BoringMath for uint256;
    // ERC20 'variables'
    string public constant symbol = "POLE";
    string public constant name = "POLE";
    uint8 public constant decimals = 18;
    uint256 public override totalSupply;

    struct Minting {
        uint128 time;
        uint128 amount;
    }

    Minting public lastMint;
    uint256 private constant MINTING_PERIOD = 24 hours;
    uint256 private constant MINTING_INCREASE = 15000;
    uint256 private constant MINTING_PRECISION = 1e5;

    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "POLE: no mint to zero address");

        // Limits the amount minted per period to a convergence function, with the period duration restarting on every mint
        uint256 totalMintedAmount = uint256(lastMint.time < block.timestamp - MINTING_PERIOD ? 0 : lastMint.amount).add(amount);
        require(totalSupply == 0 || totalSupply.mul(MINTING_INCREASE) / MINTING_PRECISION >= totalMintedAmount);
        
        lastMint.time = block.timestamp.to128();
        lastMint.amount = totalMintedAmount.to128();
        
        totalSupply = totalSupply + amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function mintToBentoBox(address clone, uint256 amount, IBentoBoxV1 bentoBox) public onlyOwner {
        mint(address(bentoBox), amount);
        bentoBox.deposit(IERC20(address(this)), address(bentoBox), clone, amount, 0);
    }

    function burn(uint256 amount) public {
        require(amount <= balanceOf[msg.sender], "POLE: not enough");

        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";

interface ISwapper {
    /// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to BentoBox.
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) external returns (uint256 extraShare, uint256 shareReturned);

    /// @notice Calculates the amount of token 'from' needed to complete the swap (amountFrom),
    /// this should be less than or equal to amountFromMax.
    /// Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for exactly 'exactAmountTo' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Transfers allocated, but unused 'from' tokens within the BentoBox to 'refundTo' (amountFromMax - amountFrom).
    /// Returns the amount of 'from' tokens withdrawn from BentoBox (amountFrom).
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) external returns (uint256 shareUsed, uint256 shareReturned);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity 0.6.12;

// solhint-disable no-inline-assembly

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    // solhint-disable var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;    

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                DOMAIN_SEPARATOR_SIGNATURE_HASH,
                chainId,
                address(this)
            )
        );
    }

    constructor() public {
        uint256 chainId; assembly {chainId := chainid()}
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = chainId);
    }

    /// @dev Return the DOMAIN_SEPARATOR
    // It's named internal to allow making it public from the contract that uses it by creating a simple view function
    // with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
    // solhint-disable-next-line func-name-mixedcase
    function _domainSeparator() internal view returns (bytes32) {
        uint256 chainId; assembly {chainId := chainid()}
        return chainId == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest =
            keccak256(
                abi.encodePacked(
                    EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA,
                    _domainSeparator(),
                    dataHash
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import '@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol';

interface IBatchFlashBorrower {
    function onBatchFlashLoan(
        address sender,
        IERC20[] calldata tokens,
        uint256[] calldata amounts,
        uint256[] calldata fees,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import '@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol';

interface IFlashBorrower {
    function onFlashLoan(
        address sender,
        IERC20 token,
        uint256 amount,
        uint256 fee,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface IStrategy {
    // Send the assets to the Strategy and call skim to invest them
    function skim(uint256 amount) external;

    // Harvest any profits made converted to the asset and pass them to the caller
    function harvest(uint256 balance, address sender) external returns (int256 amountAdded);

    // Withdraw assets. The returned amount can differ from the requested amount due to rounding.
    // The actualAmount should be very close to the amount. The difference should NOT be used to report a loss. That's what harvest is for.
    function withdraw(uint256 amount) external returns (uint256 actualAmount);

    // Withdraw all assets in the safest way possible. This shouldn't fail.
    function exit(uint256 balance) external returns (int256 amountAdded);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../../interfaces/ISwapper.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

interface IWMEMO is IERC20 {
    function wrap( uint _amount ) external returns ( uint );
    function unwrap( uint _amount ) external returns ( uint );
    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface ITIME is IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface IStakingManager {
    function unstake( uint _amount, bool _trigger ) external;
    function stake( uint _amount, address _recipient ) external returns ( bool );
}

contract wMEMOSwapper is ISwapper {
    using BoringMath for uint256;

   // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0xBBe7bF1c422eFBb5B2cB7a91A6f0AA7CdE86C1d3);
    CurvePool public constant POLE3POOL = CurvePool(0xc5536d59D026BE19b4267810f43aC083cD607b64);
    IUniswapV2Pair constant WAVAX_USDT = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IUniswapV2Pair constant TIME_AVAX = IUniswapV2Pair(0xf64e1c5B6E17031f5504481Ac8145F4c3eab4917);
    IERC20 public constant POLE = IERC20(0x65069e550C5526c029DC9135eDD02F6683859Ac1);
    IERC20 public constant MEMO = IERC20(0x136Acd46C134E8269052c62A67042D6bDeDde3C9);
    IWMEMO public constant WMEMO = IWMEMO(0x0da67235dD5787D67955420C84ca1cEcd4E5Bb3b);
    IStakingManager public constant STAKING_MANAGER = IStakingManager(0x4456B87Af11e87E329AB7d7C7A246ed1aC2168B9);
    ITIME public constant TIME = ITIME(0xb54f16fB19478766A268F172C9480f8da1a7c9C3);
    address private constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address private constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    constructor() public {
        POLE.approve(address(POLE3POOL), type(uint256).max);
        MEMO.approve(address(STAKING_MANAGER), type(uint256).max);
    }

    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    /// @inheritdoc ISwapper
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountFinal;
        uint256 amountTo;

        {
            (uint256 amountFirst, ) = BentoBox.withdraw(fromToken, address(this), address(this), 0, shareFrom);

            amountSecond = WMEMO.unwrap(amountFirst);
        }

        STAKING_MANAGER.unstake(amountSecond, false);

        TIME.transfer(address(TIME_AVAX), amountSecond);

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(WAVAX), address(TIME));

            (uint256 reserve0, uint256 reserve1, ) = TIME_AVAX.getReserves();

            (reserve0, reserve1) = address(TIME) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            
            amountThird = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(TIME) == token0
                    ? (uint256(0), amountThird)
                    : (amountThird, uint256(0));

            TIME_AVAX.swap(amount0Out, amount1Out, address(WAVAX_USDT), new bytes(0));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = WAVAX_USDT.getReserves();

            (reserve0, reserve1) = address(WAVAX) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            
            amountFinal = getAmountOut(amountThird, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WAVAX) == token0
                    ? (uint256(0), amountFinal)
                    : (amountFinal, uint256(0));

            WAVAX_USDT.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        {
            amountTo = POLE3POOL.exchange_underlying(3, 0, amountFinal, 0, address(BentoBox));
        }

        (, shareReturned) = BentoBox.deposit(toToken, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }

    // Swaps to an exact amount, from a flexible input amount
    /// @inheritdoc ISwapper
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) public override returns (uint256 shareUsed, uint256 shareReturned) {
        return (0,0);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";

library SafeMathUniswap {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

library UniswapV2Library {
    using SafeMathUniswap for uint256;

    // returns sorted token addresses, used to handle return values from pairs sorted in this order
    function sortTokens(address tokenA, address tokenB) internal pure returns (address token0, address token1) {
        require(tokenA != tokenB, "UniswapV2Library: IDENTICAL_ADDRESSES");
        (token0, token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        require(token0 != address(0), "UniswapV2Library: ZERO_ADDRESS");
    }

    // calculates the CREATE2 address for a pair without making any external calls
    function pairFor(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 pairCodeHash
    ) internal pure returns (address pair) {
        (address token0, address token1) = sortTokens(tokenA, tokenB);

        // Since Solidity 0.8.0 explicit conversions from literals larger than type(uint160).max to address are disallowed.
        // https://docs.soliditylang.org/en/develop/080-breaking-changes.html#new-restrictions
        pair = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            factory,
                            keccak256(abi.encodePacked(token0, token1)),
                            pairCodeHash // init code hash
                        )
                    )
                )
            )
        );
    }

    // fetches and sorts the reserves for a pair
    function getReserves(
        address factory,
        address tokenA,
        address tokenB,
        bytes32 pairCodeHash
    ) internal view returns (uint256 reserveA, uint256 reserveB) {
        (address token0, ) = sortTokens(tokenA, tokenB);
        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(pairFor(factory, tokenA, tokenB, pairCodeHash)).getReserves();
        (reserveA, reserveB) = tokenA == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
    }

    // given some amount of an asset and pair reserves, returns an equivalent amount of the other asset
    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) internal pure returns (uint256 amountB) {
        require(amountA > 0, "UniswapV2Library: INSUFFICIENT_AMOUNT");
        require(reserveA > 0 && reserveB > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        amountB = amountA.mul(reserveB) / reserveA;
    }

    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        require(amountIn > 0, "UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        require(amountOut > 0, "UniswapV2Library: INSUFFICIENT_OUTPUT_AMOUNT");
        require(reserveIn > 0 && reserveOut > 0, "UniswapV2Library: INSUFFICIENT_LIQUIDITY");
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // performs chained getAmountOut calculations on any number of pairs
    function getAmountsOut(
        address factory,
        uint256 amountIn,
        address[] memory path,
        bytes32 pairCodeHash
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[0] = amountIn;
        for (uint256 i; i < path.length - 1; i++) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i], path[i + 1], pairCodeHash);
            amounts[i + 1] = getAmountOut(amounts[i], reserveIn, reserveOut);
        }
    }

    // performs chained getAmountIn calculations on any number of pairs
    function getAmountsIn(
        address factory,
        uint256 amountOut,
        address[] memory path,
        bytes32 pairCodeHash
    ) internal view returns (uint256[] memory amounts) {
        require(path.length >= 2, "UniswapV2Library: INVALID_PATH");
        amounts = new uint256[](path.length);
        amounts[amounts.length - 1] = amountOut;
        for (uint256 i = path.length - 1; i > 0; i--) {
            (uint256 reserveIn, uint256 reserveOut) = getReserves(factory, path[i - 1], path[i], pairCodeHash);
            amounts[i - 1] = getAmountIn(amounts[i], reserveIn, reserveOut);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../../interfaces/ISwapper.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

interface IWGLAZE is IERC20 {
    function wrap( uint _amount ) external returns ( uint );
    function unwrap( uint _amount ) external returns ( uint );
    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface IICY is IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface IStakingManager {
    function unstake(uint256 _amount, bool _trigger) external;
    function stake(uint256 _amount, address _recipient) external returns (bool);
}

contract wGLAZESwapper is ISwapper {
    using BoringMath for uint256;

    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant MIM_USDT = IUniswapV2Pair(0xeaAe66c72513796363181E0d3954a15A0a64CC22);
    IUniswapV2Pair constant ICY_MIM = IUniswapV2Pair(0x453B5415Fe883f15686A5fF2aC6FF35ca6702628);
    IERC20 public constant POLE = IERC20(0x432E264AD545dA68e116D71572BACCd943802aa9);
    IERC20 public constant GLAZE = IERC20(0x95c8c21C261E3855b62F45121197c5a533a8a4A3);
    IWGLAZE public constant WGLAZE = IWGLAZE(0x80277a98bD53AA835Ec4Cb7aEDF04Ac8fBac5E3C);
    IStakingManager public constant STAKING_MANAGER = IStakingManager(0xBDe1c85C9fAA18bC6e8EDa1e2d813E63f86fd145);
    IICY public constant ICY = IICY(0x78bF833AaE77EBF62C21A9a5A6993A691810F2e1);
    IERC20 public constant MIM = IERC20(0x130966628846BFd36ff31a822705796e8cb8C18D);
    IERC20 public constant USDT = IERC20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;

    constructor() public {
        USDT.approve(address(Curve3POOL), type(uint256).max);
        POLE.approve(address(Curve3POOL), type(uint256).max);
        GLAZE.approve(address(STAKING_MANAGER), type(uint256).max);
    }

    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    /// @inheritdoc ISwapper
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountFinal;
        uint256 amountTo;

        {
            (uint256 amountFirst, ) = BentoBox.withdraw(fromToken, address(this), address(this), 0, shareFrom);

            amountSecond = WGLAZE.unwrap(amountFirst);
        }

        STAKING_MANAGER.unstake(amountSecond, false);

        ICY.transfer(address(ICY_MIM), amountSecond);

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(MIM), address(ICY));

            (uint256 reserve0, uint256 reserve1, ) = ICY_MIM.getReserves();

            (reserve0, reserve1) = address(ICY) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountThird = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(ICY) == token0
                ? (uint256(0), amountThird)
                : (amountThird, uint256(0));

            ICY_MIM.swap(amount0Out, amount1Out, address(MIM_USDT), new bytes(0));
        }
        
        {
            (address token0, ) = UniswapV2Library.sortTokens(address(MIM), address(USDT));

            (uint256 reserve0, uint256 reserve1, ) = MIM_USDT.getReserves();

            (reserve0, reserve1) = address(MIM) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountFinal = getAmountOut(amountThird, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(MIM) == token0 
                ? (uint256(0), amountFinal) 
                : (amountFinal, uint256(0));

            MIM_USDT.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        {
            amountTo = Curve3POOL.exchange_underlying(address(POLE3POOL), 3, 0, amountFinal, 0, address(BentoBox));
        }

        (, shareReturned) = BentoBox.deposit(toToken, address(BentoBox), recipient, amountTo, 0);
    }

    // Swaps to an exact amount, from a flexible input amount
    /// @inheritdoc ISwapper
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) public override returns (uint256 shareUsed, uint256 shareReturned) {
        return (0, 0);
    }
}

// License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../../interfaces/ISwapper.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

contract WETHSwapper is ISwapper {
    using BoringMath for uint256;

    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant USDT_WAVAX = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IUniswapV2Pair constant WETH_WAVAX = IUniswapV2Pair(0xFE15c2695F1F920da45C30AAE47d11dE51007AF9);
    IERC20 public constant POLE = IERC20(0x432E264AD545dA68e116D71572BACCd943802aa9);
    IERC20 public constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public constant WETH = IERC20(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB);
    IERC20 public constant USDT = IERC20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;

    constructor() public {
        USDT.approve(address(Curve3POOL), type(uint256).max);
        POLE.approve(address(Curve3POOL), type(uint256).max);
    }
    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    /// @inheritdoc ISwapper
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountTo;

        {
            (uint256 amountFirst,) = BentoBox.withdraw(fromToken, address(this), address(WETH_WAVAX), 0, shareFrom);

            (address token0, ) = UniswapV2Library.sortTokens(address(WETH), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = WETH_WAVAX.getReserves();

            (reserve0, reserve1) = address(WETH) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountSecond = getAmountOut(amountFirst, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WETH) == token0
                ? (uint256(0), amountSecond)
                : (amountSecond, uint256(0));

            WETH_WAVAX.swap(amount0Out, amount1Out, address(USDT_WAVAX), new bytes(0));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = USDT_WAVAX.getReserves();

            (reserve0, reserve1) = address(WAVAX) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountThird = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WAVAX) == token0
                ? (uint256(0), amountThird)
                : (amountThird, uint256(0));

            USDT_WAVAX.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        {
            amountTo = Curve3POOL.exchange_underlying(address(POLE3POOL), 3, 0, amountThird, 0, address(BentoBox));
        }

        (, shareReturned) = BentoBox.deposit(toToken, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }

    // Swaps to an exact amount, from a flexible input amount
    /// @inheritdoc ISwapper
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) public override returns (uint256 shareUsed, uint256 shareReturned) {
        return (0,0);
    }
}

// License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../../interfaces/ISwapper.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

contract WBTCSwapper is ISwapper {
    using BoringMath for uint256;

    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant USDT_WAVAX = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IUniswapV2Pair constant WBTC_WAVAX = IUniswapV2Pair(0xd5a37dC5C9A396A03dd1136Fc76A1a02B1c88Ffa);
    IERC20 public constant POLE = IERC20(0x432E264AD545dA68e116D71572BACCd943802aa9);
    IERC20 public constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public constant WBTC = IERC20(0x50b7545627a5162F82A992c33b87aDc75187B218);
    IERC20 public constant USDT = IERC20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;

    constructor() public {
        USDT.approve(address(Curve3POOL), type(uint256).max);
        POLE.approve(address(Curve3POOL), type(uint256).max);
    }
    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    /// @inheritdoc ISwapper
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountTo;

        {
            (uint256 amountFirst,) = BentoBox.withdraw(fromToken, address(this), address(WBTC_WAVAX), 0, shareFrom);

            (address token0, ) = UniswapV2Library.sortTokens(address(WBTC), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = WBTC_WAVAX.getReserves();

            (reserve0, reserve1) = address(WBTC) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountSecond = getAmountOut(amountFirst, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WBTC) == token0
                ? (uint256(0), amountSecond)
                : (amountSecond, uint256(0));

            WBTC_WAVAX.swap(amount0Out, amount1Out, address(USDT_WAVAX), new bytes(0));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = USDT_WAVAX.getReserves();

            (reserve0, reserve1) = address(WAVAX) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountThird = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WAVAX) == token0
                ? (uint256(0), amountThird)
                : (amountThird, uint256(0));

            USDT_WAVAX.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        {
            amountTo = Curve3POOL.exchange_underlying(address(POLE3POOL), 3, 0, amountThird, 0, address(BentoBox));
        }

        (, shareReturned) = BentoBox.deposit(toToken, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }

    // Swaps to an exact amount, from a flexible input amount
    /// @inheritdoc ISwapper
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) public override returns (uint256 shareUsed, uint256 shareReturned) {
        return (0,0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../../interfaces/ISwapper.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

interface IMELT is IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface IStakingManager {
    function withdraw( uint256 _amount) external;
    function deposit( uint256 _amount) external;
}

contract SMELTSwapper is ISwapper {
    using BoringMath for uint256;

    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant WAVAX_USDT = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IUniswapV2Pair constant MELT_WAVAX = IUniswapV2Pair(0x2923a62b2531EC744ca0C1e61dfFab1Ad9369FeB);
    IERC20 public constant POLE = IERC20(0x432E264AD545dA68e116D71572BACCd943802aa9);
    IERC20 public constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IStakingManager public constant STAKING_MANAGER = IStakingManager(0x1e93b54AC156Ac2FC9714B91Fa10f1b65e2daFD9);
    IMELT public constant MELT = IMELT(0x47EB6F7525C1aA999FBC9ee92715F5231eB1241D);
    IERC20 public constant SMELT = IERC20(0xB2D69B273daa655D1Ac7031615b36e23D5b302f4);
    IERC20 public constant USDT = IERC20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;

    constructor() public {
        USDT.approve(address(Curve3POOL), type(uint256).max);
        POLE.approve(address(Curve3POOL), type(uint256).max);
        SMELT.approve(address(STAKING_MANAGER), type(uint256).max);
    }

    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    /// @inheritdoc ISwapper
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountFinal;
        uint256 amountTo;

        {
            (uint256 amountFirst, ) = BentoBox.withdraw(fromToken, address(this), address(this), 0, shareFrom);

            STAKING_MANAGER.withdraw(amountFirst);

            amountSecond = MELT.balanceOf(address(this));
        }

        MELT.transfer(address(MELT_WAVAX), amountSecond);

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(MELT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = MELT_WAVAX.getReserves();

            (reserve0, reserve1) = address(MELT) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountThird = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(MELT) == token0
                ? (uint256(0), amountThird)
                : (amountThird, uint256(0));

            MELT_WAVAX.swap(amount0Out, amount1Out, address(WAVAX_USDT), new bytes(0));
        }
        
        {
            (address token0, ) = UniswapV2Library.sortTokens(address(WAVAX), address(USDT));

            (uint256 reserve0, uint256 reserve1, ) = WAVAX_USDT.getReserves();

            (reserve0, reserve1) = address(WAVAX) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountFinal = getAmountOut(amountThird, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WAVAX) == token0 
                ? (uint256(0), amountFinal) 
                : (amountFinal, uint256(0));

            WAVAX_USDT.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        {
            amountTo = Curve3POOL.exchange_underlying(address(POLE3POOL), 3, 0, amountFinal, 0, address(BentoBox));
        }

        (, shareReturned) = BentoBox.deposit(toToken, address(BentoBox), recipient, amountTo, 0);
    }

    // Swaps to an exact amount, from a flexible input amount
    /// @inheritdoc ISwapper
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) public override returns (uint256 shareUsed, uint256 shareReturned) {
        return (0, 0);
    }
}

// License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../../libraries/UniswapV2Library.sol";
import "../../interfaces/ISwapperGeneric.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

interface IBentoBoxV1 {
    function withdraw(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);

    function deposit(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);
}

contract PTPWAVAXLPSwapper is ISwapperGeneric {
    using BoringMath for uint256;

    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x7a6F45F490bd5b9EE48E5653C00f96081a1d7Fe9);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant USDT_WAVAX = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IUniswapV2Pair constant WAVAX_PTP = IUniswapV2Pair(0xCDFD91eEa657cc2701117fe9711C9a4F61FEED23);
    IERC20 public constant POLE = IERC20(0x65069e550C5526c029DC9135eDD02F6683859Ac1);
    IERC20 public constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public constant PTP = IERC20(0x22d4002028f537599bE9f666d1c4Fa138522f9c8);
    IERC20 public constant USDT = IERC20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    address public constant POLE3POOL = 0xc5536d59D026BE19b4267810f43aC083cD607b64;

    constructor() public {
        USDT.approve(address(Curve3POOL), type(uint256).max);
        POLE.approve(address(Curve3POOL), type(uint256).max);
        POLE.approve(address(BentoBox), type(uint256).max);
    }
    
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountTo;

        {
            (uint256 amountFirst,) = BentoBox.withdraw(fromToken, address(this), address(this), 0, shareFrom);

            WAVAX_PTP.transfer(address(WAVAX_PTP), amountFirst);

            (uint256 amount0, uint256 amount1) = WAVAX_PTP.burn(address(this));

            (address token0, ) = UniswapV2Library.sortTokens(address(PTP), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = WAVAX_PTP.getReserves();

            (reserve0, reserve1) = address(PTP) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            uint256 amountToken = address(PTP) == token0 ? amount0 : amount1;

            amountSecond = getAmountOut(amountToken, reserve0, reserve1);

            PTP.transfer(address(WAVAX_PTP), amountToken);

            (uint256 amount0Out, uint256 amount1Out) = address(PTP) == token0
                    ? (uint256(0), amountSecond)
                    : (amountSecond, uint256(0));

            WAVAX_PTP.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        {
            uint256 Balance = WAVAX.balanceOf(address(this));

            WAVAX.transfer(address(USDT_WAVAX), Balance);
            
            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = USDT_WAVAX.getReserves();

            (reserve0, reserve1) = address(WAVAX) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountThird = getAmountOut(Balance, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WAVAX) == token0
                ? (uint256(0), amountThird)
                : (amountThird, uint256(0));

            USDT_WAVAX.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        {
            amountTo = Curve3POOL.exchange_underlying(address(POLE3POOL), 3, 0, amountThird, 0, address(BentoBox));
        }

        (, shareReturned) = BentoBox.deposit(toToken, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }

    function swapExact(
        IERC20,
        IERC20,
        address,
        address,
        uint256,
        uint256
    ) public override returns (uint256 shareUsed, uint256 shareReturned) {
        return (0, 0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.6.12;
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
interface ISwapperGeneric {
    /// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to BentoBox.
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) external returns (uint256 extraShare, uint256 shareReturned);

    /// @notice Calculates the amount of token 'from' needed to complete the swap (amountFrom),
    /// this should be less than or equal to amountFromMax.
    /// Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for exactly 'exactAmountTo' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Transfers allocated, but unused 'from' tokens within the BentoBox to 'refundTo' (amountFromMax - amountFrom).
    /// Returns the amount of 'from' tokens withdrawn from BentoBox (amountFrom).
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) external returns (uint256 shareUsed, uint256 shareReturned);
}

// License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "../../interfaces/ISwapper.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);

    function remove_liquidity_one_coin( address _pool, uint256 _burn_amount , int128 i , uint256 _min_amount) external returns (uint256);
}

contract H2OSwapper is ISwapper {
    using BoringMath for uint256;

    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IERC20 public constant USDT = IERC20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;
    address public constant H2O3POOL = 0xF72beaCc6fD334E14a7DDAC25c3ce1Eb8a827E10;

    constructor() public {
        USDT.approve(address(Curve3POOL), type(uint256).max);
        IERC20(H2O3POOL).approve(address(Curve3POOL), type(uint256).max);
    }

    // Swaps to a flexible amount, from an exact input amount
    /// @inheritdoc ISwapper
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountTo;

        {
            (uint256 amountFirst,) = BentoBox.withdraw(fromToken, address(this), address(this), 0, shareFrom);

            Curve3POOL.remove_liquidity_one_coin(address(H2O3POOL), amountFirst, 3, 0);

            amountSecond = USDT.balanceOf(address(this));

            Curve3POOL.exchange_underlying(address(POLE3POOL), 3, 0, amountSecond, 0, address(BentoBox));

        }

        (, shareReturned) = BentoBox.deposit(toToken, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }

    // Swaps to an exact amount, from a flexible input amount
    /// @inheritdoc ISwapper
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) public override returns (uint256 shareUsed, uint256 shareReturned) {
        return (0,0);
    }
}

// License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../../interfaces/ISwapper.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

contract gOHMSwapper is ISwapper {
    using BoringMath for uint256;

    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant USDT_WAVAX = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IUniswapV2Pair constant WAVAX_gOHM = IUniswapV2Pair(0xB674f93952F02F2538214D4572Aa47F262e990Ff);
    IERC20 public constant POLE = IERC20(0x432E264AD545dA68e116D71572BACCd943802aa9);
    IERC20 public constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public constant gOHM = IERC20(0x321E7092a180BB43555132ec53AaA65a5bF84251);
    IERC20 public constant USDT = IERC20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;

    constructor() public {
        USDT.approve(address(Curve3POOL), type(uint256).max);
        POLE.approve(address(Curve3POOL), type(uint256).max);
    }
    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    /// @inheritdoc ISwapper
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountTo;

        {
            (uint256 amountFirst,) = BentoBox.withdraw(fromToken, address(this), address(WAVAX_gOHM), 0, shareFrom);

            (address token0, ) = UniswapV2Library.sortTokens(address(gOHM), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = WAVAX_gOHM.getReserves();

            (reserve0, reserve1) = address(gOHM) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountSecond = getAmountOut(amountFirst, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(gOHM) == token0
                ? (uint256(0), amountSecond)
                : (amountSecond, uint256(0));

            WAVAX_gOHM.swap(amount0Out, amount1Out, address(USDT_WAVAX), new bytes(0));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = USDT_WAVAX.getReserves();

            (reserve0, reserve1) = address(WAVAX) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountThird = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WAVAX) == token0
                ? (uint256(0), amountThird)
                : (amountThird, uint256(0));

            USDT_WAVAX.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        {
            amountTo = Curve3POOL.exchange_underlying(address(POLE3POOL), 3, 0, amountThird, 0, address(BentoBox));
        }

        (, shareReturned) = BentoBox.deposit(toToken, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }

    // Swaps to an exact amount, from a flexible input amount
    /// @inheritdoc ISwapper
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) public override returns (uint256 shareUsed, uint256 shareReturned) {
        return (0,0);
    }
}

// License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../../interfaces/ISwapper.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

contract WAVAXSwapper is ISwapper {
    using BoringMath for uint256;

    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant USDT_WAVAX = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IERC20 public constant POLE = IERC20(0x432E264AD545dA68e116D71572BACCd943802aa9);
    IERC20 public constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public constant USDT = IERC20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;

    constructor() public {
        USDT.approve(address(Curve3POOL), type(uint256).max);
        POLE.approve(address(Curve3POOL), type(uint256).max);
    }
    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    /// @inheritdoc ISwapper
    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public override returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountTo;

        {
            (uint256 amountFirst,) = BentoBox.withdraw(fromToken, address(this), address(USDT_WAVAX), 0, shareFrom);

            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = USDT_WAVAX.getReserves();

            (reserve0, reserve1) = address(WAVAX) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountSecond = getAmountOut(amountFirst, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WAVAX) == token0
                ? (uint256(0), amountSecond)
                : (amountSecond, uint256(0));

            USDT_WAVAX.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        {
            amountTo = Curve3POOL.exchange_underlying(address(POLE3POOL), 3, 0, amountSecond, 0, address(BentoBox));
        }

        (, shareReturned) = BentoBox.deposit(toToken, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }

    // Swaps to an exact amount, from a flexible input amount
    /// @inheritdoc ISwapper
    function swapExact(
        IERC20 fromToken,
        IERC20 toToken,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) public override returns (uint256 shareUsed, uint256 shareReturned) {
        return (0,0);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

interface IWMEMO is IERC20 {
    function wrap(uint256 _amount) external returns (uint256);
    function unwrap(uint256 _amount) external returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface IStakingManager {
    function unstake(uint256 _amount, bool _trigger) external;
    function stake(uint256 _amount, address _recipient) external returns (bool);
    function claim(address _recipient) external;
}

contract wMEMOLevSwapper {
    using BoringMath for uint256;

    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0xBBe7bF1c422eFBb5B2cB7a91A6f0AA7CdE86C1d3);
    CurvePool public constant POLE3POOL = CurvePool(0xc5536d59D026BE19b4267810f43aC083cD607b64);
    IUniswapV2Pair constant WAVAX_USDT = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IUniswapV2Pair constant TIME_AVAX = IUniswapV2Pair(0xf64e1c5B6E17031f5504481Ac8145F4c3eab4917);
    IERC20 public constant POLE = IERC20(0x65069e550C5526c029DC9135eDD02F6683859Ac1);
    IERC20 public constant MEMO = IERC20(0x136Acd46C134E8269052c62A67042D6bDeDde3C9);
    IWMEMO public constant WMEMO = IWMEMO(0x0da67235dD5787D67955420C84ca1cEcd4E5Bb3b);
    IStakingManager public constant STAKING_MANAGER = IStakingManager(0x4456B87Af11e87E329AB7d7C7A246ed1aC2168B9);
    IERC20 public constant TIME = IERC20(0xb54f16fB19478766A268F172C9480f8da1a7c9C3);
    address private constant WAVAX = 0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7;
    address private constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    constructor() public {
        POLE.approve(address(POLE3POOL), type(uint256).max);
        TIME.approve(address(STAKING_MANAGER), type(uint256).max);
        MEMO.approve(address(WMEMO), type(uint256).max);
    }

    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountFinal;
        uint256 amountTo;

        {
            (uint256 amountFirst, ) = BentoBox.withdraw(POLE, address(this), address(this), 0, shareFrom);
            amountSecond = POLE3POOL.exchange_underlying(0, 3, amountFirst, 0, address(WAVAX_USDT));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = WAVAX_USDT.getReserves();

            (reserve0, reserve1) = address(USDT) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            
            amountThird = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(USDT) == token0
                    ? (uint256(0), amountThird)
                    : (amountThird, uint256(0));

            WAVAX_USDT.swap(amount0Out, amount1Out, address(TIME_AVAX), new bytes(0));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(WAVAX), address(TIME));

            (uint256 reserve0, uint256 reserve1, ) = TIME_AVAX.getReserves();

            (reserve0, reserve1) = address(WAVAX) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountFinal = getAmountOut(amountThird, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WAVAX) == token0
                ? (uint256(0), amountFinal)
                : (amountFinal, uint256(0));

            TIME_AVAX.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        STAKING_MANAGER.stake(amountFinal, address(this));

        STAKING_MANAGER.claim(address(this));

        amountTo = WMEMO.wrap(amountFinal);

        WMEMO.transfer(address(BentoBox), amountTo);

        (, shareReturned) = BentoBox.deposit(WMEMO, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

interface IWGLAZE is IERC20 {
    function wrap( uint _amount ) external returns ( uint );
    function unwrap( uint _amount ) external returns ( uint );
    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface IStakingManager {
    function unstake( uint _amount, bool _trigger ) external;
    function stake( uint _amount, address _recipient ) external returns ( bool );
    function claim ( address _recipient ) external;
}

contract wGLAZELevSwapper {
    using BoringMath for uint256;
    
    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant MIM_USDT = IUniswapV2Pair(0xeaAe66c72513796363181E0d3954a15A0a64CC22);
    IUniswapV2Pair constant ICY_MIM = IUniswapV2Pair(0x453B5415Fe883f15686A5fF2aC6FF35ca6702628);
    IERC20 public constant POLE = IERC20(0x432E264AD545dA68e116D71572BACCd943802aa9);
    IERC20 public constant GLAZE = IERC20(0x95c8c21C261E3855b62F45121197c5a533a8a4A3);
    IWGLAZE public constant WGLAZE = IWGLAZE(0x80277a98bD53AA835Ec4Cb7aEDF04Ac8fBac5E3C);
    IStakingManager public constant STAKING_MANAGER = IStakingManager(0xBDe1c85C9fAA18bC6e8EDa1e2d813E63f86fd145);
    IERC20 public constant ICY = IERC20(0x78bF833AaE77EBF62C21A9a5A6993A691810F2e1);
    IERC20 public constant MIM = IERC20(0x130966628846BFd36ff31a822705796e8cb8C18D);
    address public constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;

    constructor() public {
        POLE.approve(address(Curve3POOL), type(uint256).max);
        ICY.approve(address(STAKING_MANAGER), type(uint256).max);
        GLAZE.approve(address(WGLAZE), type(uint256).max);
    }

    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountFinal;
        uint256 amountTo;

        {
            (uint256 amountFirst, ) = BentoBox.withdraw(POLE, address(this), address(this), 0, shareFrom);
            amountSecond = Curve3POOL.exchange_underlying(address(POLE3POOL), 0, 3, amountFirst, 0, address(MIM_USDT));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(MIM));

            (uint256 reserve0, uint256 reserve1, ) = MIM_USDT.getReserves();

            (reserve0, reserve1) = address(USDT) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountThird = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(USDT) == token0
                    ? (uint256(0), amountThird)
                    : (amountThird, uint256(0));

            MIM_USDT.swap(amount0Out, amount1Out, address(ICY_MIM), new bytes(0));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(MIM), address(ICY));

            (uint256 reserve0, uint256 reserve1, ) = ICY_MIM.getReserves();

            (reserve0, reserve1) = address(MIM) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountFinal = getAmountOut(amountThird, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(MIM) == token0
                    ? (uint256(0), amountFinal)
                    : (amountFinal, uint256(0));
            ICY_MIM.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        STAKING_MANAGER.stake(amountFinal, address(this));

        STAKING_MANAGER.claim(address(this));
        
        amountTo = WGLAZE.wrap(amountFinal);

        WGLAZE.transfer(address(BentoBox), amountTo);

        (, shareReturned) = BentoBox.deposit(WGLAZE, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }
}

// License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

contract WETHLevSwapper{
    using BoringMath for uint256;

    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant USDT_WAVAX = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IUniswapV2Pair constant WETH_WAVAX = IUniswapV2Pair(0xFE15c2695F1F920da45C30AAE47d11dE51007AF9);
    IERC20 public constant POLE = IERC20(0x432E264AD545dA68e116D71572BACCd943802aa9);
    IERC20 public constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public constant WETH = IERC20(0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB);
    address public constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;

    constructor() public {
        POLE.approve(address(Curve3POOL), type(uint256).max);
    }
    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountTo;

        {
            (uint256 amountFirst, ) = BentoBox.withdraw(POLE, address(this), address(this), 0, shareFrom);

            amountSecond = Curve3POOL.exchange_underlying(address(POLE3POOL), 0, 3, amountFirst, 0, address(USDT_WAVAX));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = USDT_WAVAX.getReserves();

            (reserve0, reserve1) = address(USDT) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            
            amountThird = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(USDT) == token0
                    ? (uint256(0), amountThird)
                    : (amountThird, uint256(0));

            USDT_WAVAX.swap(amount0Out, amount1Out, address(WETH_WAVAX), new bytes(0));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(WETH), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = WETH_WAVAX.getReserves();

            (reserve0, reserve1) = address(WAVAX) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            
            amountTo = getAmountOut(amountThird, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WAVAX) == token0
                    ? (uint256(0), amountTo)
                    : (amountTo, uint256(0));

            WETH_WAVAX.swap(amount0Out, amount1Out, address(BentoBox), new bytes(0));
        }

        (, shareReturned) = BentoBox.deposit(WETH, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }
}

// License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

contract WBTCLevSwapper{
    using BoringMath for uint256;

    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant USDT_WAVAX = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IUniswapV2Pair constant WBTC_WAVAX = IUniswapV2Pair(0xd5a37dC5C9A396A03dd1136Fc76A1a02B1c88Ffa);
    IERC20 public constant POLE = IERC20(0x432E264AD545dA68e116D71572BACCd943802aa9);
    IERC20 public constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public constant WBTC = IERC20(0x50b7545627a5162F82A992c33b87aDc75187B218);
    address public constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;

    constructor() public {
        POLE.approve(address(Curve3POOL), type(uint256).max);
    }
    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountTo;

        {
            (uint256 amountFirst, ) = BentoBox.withdraw(POLE, address(this), address(this), 0, shareFrom);

            amountSecond = Curve3POOL.exchange_underlying(address(POLE3POOL), 0, 3, amountFirst, 0, address(USDT_WAVAX));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = USDT_WAVAX.getReserves();

            (reserve0, reserve1) = address(USDT) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            
            amountThird = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(USDT) == token0
                    ? (uint256(0), amountThird)
                    : (amountThird, uint256(0));

            USDT_WAVAX.swap(amount0Out, amount1Out, address(WBTC_WAVAX), new bytes(0));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(WBTC), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = WBTC_WAVAX.getReserves();

            (reserve0, reserve1) = address(WAVAX) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            
            amountTo = getAmountOut(amountThird, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WAVAX) == token0
                    ? (uint256(0), amountTo)
                    : (amountTo, uint256(0));

            WBTC_WAVAX.swap(amount0Out, amount1Out, address(BentoBox), new bytes(0));
        }

        (, shareReturned) = BentoBox.deposit(WBTC, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

interface ISMELT is IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool success);
}

interface IStakingManager {
    function withdraw( uint256 _amount) external;
    function deposit( uint256 _amount) external;
}

contract SMELTLevSwapper {
    using BoringMath for uint256;
    
    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant WAVAX_USDT = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IUniswapV2Pair constant MELT_WAVAX = IUniswapV2Pair(0x2923a62b2531EC744ca0C1e61dfFab1Ad9369FeB);
    IERC20 public constant POLE = IERC20(0x432E264AD545dA68e116D71572BACCd943802aa9);
    IERC20 public constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IStakingManager public constant STAKING_MANAGER = IStakingManager(0x1e93b54AC156Ac2FC9714B91Fa10f1b65e2daFD9);
    IERC20 public constant MELT = IERC20(0x47EB6F7525C1aA999FBC9ee92715F5231eB1241D);
    ISMELT public constant SMELT = ISMELT(0xB2D69B273daa655D1Ac7031615b36e23D5b302f4);
    address public constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;

    constructor() public {
        POLE.approve(address(Curve3POOL), type(uint256).max);
        MELT.approve(address(STAKING_MANAGER), type(uint256).max);
    }

    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountFinal;
        uint256 amountTo;

        {
            (uint256 amountFirst, ) = BentoBox.withdraw(POLE, address(this), address(this), 0, shareFrom);
            
            amountSecond = Curve3POOL.exchange_underlying(address(POLE3POOL), 0, 3, amountFirst, 0, address(WAVAX_USDT));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = WAVAX_USDT.getReserves();

            (reserve0, reserve1) = address(USDT) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountThird = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(USDT) == token0
                    ? (uint256(0), amountThird)
                    : (amountThird, uint256(0));

            WAVAX_USDT.swap(amount0Out, amount1Out, address(MELT_WAVAX), new bytes(0));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(MELT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = MELT_WAVAX.getReserves();

            (reserve0, reserve1) = address(WAVAX) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            amountFinal = getAmountOut(amountThird, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WAVAX) == token0
                    ? (uint256(0), amountFinal)
                    : (amountFinal, uint256(0));
            MELT_WAVAX.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        STAKING_MANAGER.deposit(amountFinal);

        amountTo = SMELT.balanceOf(address(this));

        SMELT.transfer(address(BentoBox), amountTo);

        (, shareReturned) = BentoBox.deposit(SMELT, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }
}

// License-Identifier: MIT
pragma solidity >= 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Router01.sol";
import "../../libraries/UniswapV2Library.sol";

// SPDX-License-Identifier: GPL-3.0-or-later
/// @notice Babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method).
library Babylonian {
    // computes square roots using the babylonian method
    // credit for this implementation goes to
    // https://github.com/abdk-consulting/abdk-libraries-solidity/blob/master/ABDKMath64x64.sol#L687
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        // this block is equivalent to r = uint256(1) << (BitMath.mostSignificantBit(x) / 2);
        // however that code costs significantly more gas
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

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

interface IBentoBoxV1 {
    function withdraw(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);

    function deposit(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256, uint256);
}

contract PTPWAVAXLPLevSwapper{
    using BoringMath for uint256;

    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x7a6F45F490bd5b9EE48E5653C00f96081a1d7Fe9);
    IUniswapV2Router01 public constant ROUTER = IUniswapV2Router01(0x60aE616a2155Ee3d9A68541Ba4544862310933d4);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant USDT_WAVAX = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IUniswapV2Pair constant WAVAX_PTP = IUniswapV2Pair(0xCDFD91eEa657cc2701117fe9711C9a4F61FEED23);
    IERC20 public constant POLE = IERC20(0x65069e550C5526c029DC9135eDD02F6683859Ac1);
    IERC20 public constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public constant PTP = IERC20(0x22d4002028f537599bE9f666d1c4Fa138522f9c8);
    IERC20 public constant USDT = IERC20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    address public constant POLE3POOL = 0xc5536d59D026BE19b4267810f43aC083cD607b64;
    uint256 private constant DEADLINE = 0xf000000000000000000000000000000000000000000000000000000000000000;

    constructor() public {
        POLE.approve(address(Curve3POOL), type(uint256).max);
        WAVAX_PTP.approve(address(BentoBox), type(uint256).max);
        PTP.approve(address(ROUTER), type(uint256).max);
        WAVAX.approve(address(ROUTER), type(uint256).max);
    }
    
    function _calculateSwapInAmount(uint256 reserveIn, uint256 userIn) internal pure returns (uint256) {
        return (Babylonian.sqrt(reserveIn * ((userIn * 3988000) + (reserveIn * 3988009))) - (reserveIn * 1997)) / 1994;
    }

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountFourth;
        uint256 amountTo;

        {
            (uint256 amountFirst, ) = BentoBox.withdraw(POLE, address(this), address(this), 0, shareFrom);

            amountSecond = Curve3POOL.exchange_underlying(address(POLE3POOL), 0, 3, amountFirst, 0, address(USDT_WAVAX));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = USDT_WAVAX.getReserves();

            (reserve0, reserve1) = address(USDT) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            
            amountThird = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(USDT) == token0
                    ? (uint256(0), amountThird)
                    : (amountThird, uint256(0));

            USDT_WAVAX.swap(amount0Out, amount1Out, address(this), new bytes(0));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(PTP), address(WAVAX));
            
            (uint256 reserve0, uint256 reserve1, ) = WAVAX_PTP.getReserves();

            (reserve0, reserve1) = address(WAVAX) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);

            uint256 amountFrom =  WAVAX.balanceOf(address(this));

            uint256 mimSwapInAmount = _calculateSwapInAmount(reserve0, amountFrom);
            
            WAVAX.transfer(address(WAVAX_PTP), mimSwapInAmount);

            amountFourth = getAmountOut(mimSwapInAmount, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WAVAX) == token0
                    ? (uint256(0), amountFourth)
                    : (amountFourth, uint256(0));

            WAVAX_PTP.swap(amount0Out, amount1Out, address(this), new bytes(0));

            uint256 oldBalance = WAVAX_PTP.balanceOf(address(this));

            ROUTER.addLiquidity(
                address(PTP),
                address(WAVAX),
                PTP.balanceOf(address(this)),
                WAVAX.balanceOf(address(this)),
                1,
                1,
                address(this),
                DEADLINE
            );
            
            uint256 newBalance = WAVAX_PTP.balanceOf(address(this));

            amountTo = newBalance.sub(oldBalance);
        }

        (, shareReturned) = BentoBox.deposit(IERC20(address(WAVAX_PTP)), address(this), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

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
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);

    function add_liquidity( address _pool, uint256[4] calldata _deposit_amounts, uint256 _min_mint_amount) external returns (uint256);
}

contract H2OLPLevSwapper {
    using BoringMath for uint256;
    
    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IERC20 public constant POLE = IERC20(0x432E264AD545dA68e116D71572BACCd943802aa9);
    IERC20 public constant USDT = IERC20(0xc7198437980c041c805A1EDcbA50c1Ce5db95118);
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;
    address public constant H2O3POOL = 0xF72beaCc6fD334E14a7DDAC25c3ce1Eb8a827E10;

    constructor() public {
        POLE.approve(address(Curve3POOL), type(uint256).max);
        USDT.approve(address(Curve3POOL), type(uint256).max);
    }

    // Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountTo;

        {
            (uint256 amountFirst, ) = BentoBox.withdraw(POLE, address(this), address(this), 0, shareFrom);
            
            amountSecond = Curve3POOL.exchange_underlying(address(POLE3POOL), 0, 3, amountFirst, 0, address(this));

            Curve3POOL.add_liquidity(address(H2O3POOL), [0, 0, 0, amountSecond], 0);

            amountTo = IERC20(H2O3POOL).balanceOf(address(this));

        }

        (, shareReturned) = BentoBox.deposit(IERC20(H2O3POOL), address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }
}

// License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

contract gOHMLevSwapper{
    using BoringMath for uint256;

    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant USDT_WAVAX = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IUniswapV2Pair constant WAVAX_gOHM = IUniswapV2Pair(0xB674f93952F02F2538214D4572Aa47F262e990Ff);
    IERC20 public constant POLE = IERC20(0x432E264AD545dA68e116D71572BACCd943802aa9);
    IERC20 public constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    IERC20 public constant gOHM = IERC20(0x321E7092a180BB43555132ec53AaA65a5bF84251);
    address public constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;

    constructor() public {
        POLE.approve(address(Curve3POOL), type(uint256).max);
    }
    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountThird;
        uint256 amountTo;

        {
            (uint256 amountFirst, ) = BentoBox.withdraw(POLE, address(this), address(this), 0, shareFrom);

            amountSecond = Curve3POOL.exchange_underlying(address(POLE3POOL), 0, 3, amountFirst, 0, address(USDT_WAVAX));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = USDT_WAVAX.getReserves();

            (reserve0, reserve1) = address(USDT) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            
            amountThird = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(USDT) == token0
                    ? (uint256(0), amountThird)
                    : (amountThird, uint256(0));

            USDT_WAVAX.swap(amount0Out, amount1Out, address(WAVAX_gOHM), new bytes(0));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(WAVAX), address(gOHM));

            (uint256 reserve0, uint256 reserve1, ) = WAVAX_gOHM.getReserves();

            (reserve0, reserve1) = address(WAVAX) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            
            amountTo = getAmountOut(amountThird, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(WAVAX) == token0
                    ? (uint256(0), amountTo)
                    : (amountTo, uint256(0));

            WAVAX_gOHM.swap(amount0Out, amount1Out, address(BentoBox), new bytes(0));
        }

        (, shareReturned) = BentoBox.deposit(gOHM, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }
}

// License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "../../libraries/UniswapV2Library.sol";

interface CurvePool {
    function exchange_underlying(address pool, int128 i, int128 j, uint256 dx, uint256 min_dy, address receiver) external returns (uint256);
}

contract WAVAXLevSwapper{
    using BoringMath for uint256;

    // Local variables
    IBentoBoxV1 public constant BentoBox = IBentoBoxV1(0x6C2080fd12bf4F3973ABcAEcF42f057c1c57184d);
    CurvePool public constant Curve3POOL = CurvePool(0x001E3BA199B4FF4B5B6e97aCD96daFC0E2e4156e);
    IUniswapV2Pair constant USDT_WAVAX = IUniswapV2Pair(0xeD8CBD9F0cE3C6986b22002F03c6475CEb7a6256);
    IERC20 public constant POLE = IERC20(0x432E264AD545dA68e116D71572BACCd943802aa9);
    IERC20 public constant WAVAX = IERC20(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7);
    address public constant USDT = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;
    address public constant POLE3POOL = 0x3d49594Ed8c108F817512829C102E4059c76a220;

    constructor() public {
        POLE.approve(address(Curve3POOL), type(uint256).max);
    }
    // Given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountOut) {
        uint256 amountInWithFee = amountIn.mul(997);
        uint256 numerator = amountInWithFee.mul(reserveOut);
        uint256 denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }

    // Given an output amount of an asset and pair reserves, returns a required input amount of the other asset
    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) internal pure returns (uint256 amountIn) {
        uint256 numerator = reserveIn.mul(amountOut).mul(1000);
        uint256 denominator = reserveOut.sub(amountOut).mul(997);
        amountIn = (numerator / denominator).add(1);
    }

    // Swaps to a flexible amount, from an exact input amount
    function swap(
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) public returns (uint256 extraShare, uint256 shareReturned) {
        uint256 amountSecond;
        uint256 amountTo;

        {
            (uint256 amountFirst, ) = BentoBox.withdraw(POLE, address(this), address(this), 0, shareFrom);

            amountSecond = Curve3POOL.exchange_underlying(address(POLE3POOL), 0, 3, amountFirst, 0, address(USDT_WAVAX));
        }

        {
            (address token0, ) = UniswapV2Library.sortTokens(address(USDT), address(WAVAX));

            (uint256 reserve0, uint256 reserve1, ) = USDT_WAVAX.getReserves();

            (reserve0, reserve1) = address(USDT) == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
            
            amountTo = getAmountOut(amountSecond, reserve0, reserve1);

            (uint256 amount0Out, uint256 amount1Out) = address(USDT) == token0
                    ? (uint256(0), amountTo)
                    : (amountTo, uint256(0));

            USDT_WAVAX.swap(amount0Out, amount1Out, address(BentoBox), new bytes(0));
        }

        (, shareReturned) = BentoBox.deposit(WAVAX, address(BentoBox), recipient, amountTo, 0);
        extraShare = shareReturned.sub(shareToMin);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@boringcrypto/boring-solidity/contracts/Domain.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/BoringBatchable.sol";


// Staking in sNorth inspired by Chef Nomi's SushiBar - MIT license (originally WTFPL)
// modified by BoringCrypto for DictatorDAO

contract sNorth is IERC20, Domain {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using BoringERC20 for IERC20;

    string public constant symbol = "sNORTH";
    string public constant name = "Staked North Tokens";
    uint8 public constant decimals = 18;
    uint256 public override totalSupply;
    uint256 private constant LOCK_TIME = 24 hours;

    IERC20 public immutable token;

    constructor(IERC20 _token) public {
        token = _token;
    }

    struct User {
        uint128 balance;
        uint128 lockedUntil;
    }

    /// @notice owner > balance mapping.
    mapping(address => User) public users;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address user) public view override returns (uint256 balance) {
        return users[user].balance;
    }

    function _transfer(
        address from,
        address to,
        uint256 shares
    ) internal {
        User memory fromUser = users[from];
        require(block.timestamp >= fromUser.lockedUntil, "Locked");
        if (shares != 0) {
            require(fromUser.balance >= shares, "Low balance");
            if (from != to) {
                require(to != address(0), "Zero address"); // Moved down so other failed calls safe some gas
                User memory toUser = users[to];
                users[from].balance = fromUser.balance - shares.to128(); // Underflow is checked
                users[to].balance = toUser.balance + shares.to128(); // Can't overflow because totalSupply would be greater than 2^128-1;
            }
        }
        emit Transfer(from, to, shares);
    }

    function _useAllowance(address from, uint256 shares) internal {
        if (msg.sender == from) {
            return;
        }
        uint256 spenderAllowance = allowance[from][msg.sender];
        // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
        if (spenderAllowance != type(uint256).max) {
            require(spenderAllowance >= shares, "Low allowance");
            allowance[from][msg.sender] = spenderAllowance - shares; // Underflow is checked
        }
    }

    /// @notice Transfers `shares` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param shares of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 shares) public returns (bool) {
        _transfer(msg.sender, to, shares);
        return true;
    }

    /// @notice Transfers `shares` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param shares The token shares to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 shares
    ) public returns (bool) {
        _useAllowance(from, shares);
        _transfer(from, to, shares);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "Zero owner");
        require(block.timestamp < deadline, "Expired");
        require(
            ecrecover(_getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))), v, r, s) ==
                owner_,
            "Invalid Sig"
        );
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }

    /// math is ok, because amount, totalSupply and shares is always 0 <= amount <= 100.000.000 * 10^18
    /// theoretically you can grow the amount/share ratio, but it's not practical and useless
    function mint(uint256 amount) public returns (bool) {
        require(msg.sender != address(0), "Zero address");
        User memory user = users[msg.sender];

        uint256 totalTokens = token.balanceOf(address(this));
        uint256 shares = totalSupply == 0 ? amount : (amount * totalSupply) / totalTokens;
        user.balance += shares.to128();
        user.lockedUntil = (block.timestamp + LOCK_TIME).to128();
        users[msg.sender] = user;
        totalSupply += shares;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit Transfer(address(0), msg.sender, shares);
        return true;
    }

    function _burn(
        address from,
        address to,
        uint256 shares
    ) internal {
        require(to != address(0), "Zero address");
        User memory user = users[from];
        require(block.timestamp >= user.lockedUntil, "Locked");
        uint256 amount = (shares * token.balanceOf(address(this))) / totalSupply;
        users[from].balance = user.balance.sub(shares.to128()); // Must check underflow
        totalSupply -= shares;

        token.safeTransfer(to, amount);

        emit Transfer(from, address(0), shares);
    }

    function burn(address to, uint256 shares) public returns (bool) {
        _burn(msg.sender, to, shares);
        return true;
    }

    function burnFrom(
        address from,
        address to,
        uint256 shares
    ) public returns (bool) {
        _useAllowance(from, shares);
        _burn(from, to, shares);
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// Audit on 5-Jan-2021 by Keno and BoringCrypto

import "./interfaces/IERC20.sol";

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "../interfaces/IOracle.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

/// @title ProxyOracle
/// @notice Oracle used for getting the price of xSUSHI based on Chainlink
contract ProxyOracle is IOracle, BoringOwnable {

    IOracle public oracleImplementation;

    event LogOracleImplementationChange(IOracle indexed oldOracle, IOracle indexed newOracle);

    constructor() public {
    }

    function changeOracleImplementation(IOracle newOracle) external onlyOwner {
        IOracle oldOracle = oracleImplementation;
        oracleImplementation = newOracle;
        emit LogOracleImplementationChange(oldOracle, newOracle);
    }

    // Get the latest exchange rate
    /// @inheritdoc IOracle
    function get(bytes calldata data) public override returns (bool, uint256) {
        return oracleImplementation.get(data);
    } 

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata data) public view override returns (bool, uint256) {
        return oracleImplementation.peek(data);
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        return oracleImplementation.peekSpot(data);
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return "Proxy Oracle";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return "Proxy";
    }
}

// SPDX-License-Identifier: MIT

// North

// Special thanks to:
// @BoringCrypto for his great libraries

pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";

/// @title North
/// @author 0xMerlin
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract North is ERC20, BoringOwnable {
    using BoringMath for uint256;
    // ERC20 'variables'
    string public constant symbol = "NORTH";
    string public constant name = "North Token";
    uint8 public constant decimals = 18;
    uint256 public override totalSupply;
    uint256 public constant MAX_SUPPLY = 273150000 * 1e18;

    function mint(address to, uint256 amount) public onlyOwner {
        require(to != address(0), "NORTH: no mint to zero address");
        require(MAX_SUPPLY >= totalSupply.add(amount), "NORTH: Don't go over MAX");

        totalSupply = totalSupply + amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}

// SPDX-License-Identifier: UNLICENSED

// Copyright (c) 2021 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@boringcrypto/boring-solidity/contracts/BoringOwnable.sol";
import "@boringcrypto/boring-solidity/contracts/ERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "./POLE.sol";
import "./interfaces/IOracle.sol";
import "./interfaces/ISwapper.sol";

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

interface BaseStrategy {
    function exit(uint256 balance) external view returns (int256 amountAdded);
    function safeHarvest(uint256 maxBalance, bool rebalance, uint256 maxChangeAmount, bool harvestRewards) external;
}

/// @title Cauldron
/// @dev This contract allows contract calls to any contract (except BentoBox)
/// from arbitrary callers thus, don't trust calls from this contract in any circumstances.
contract CauldronV2Strategy is BoringOwnable, IMasterContract {
    using BoringMath for uint256;
    using BoringMath128 for uint128;
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;

    event LogExchangeRate(uint256 rate);
    event LogAccrue(uint128 accruedAmount);
    event LogAddCollateral(address indexed from, address indexed to, uint256 share);
    event LogRemoveCollateral(address indexed from, address indexed to, uint256 share);
    event LogBorrow(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogRepay(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogFeeTo(address indexed newFeeTo);
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);
    event LogsetDistributionPart(uint256 amount);

    // Immutables (for MasterContract and all clones)
    IBentoBoxV1 public immutable bentoBox;
    CauldronV2Strategy public immutable masterContract;
    IERC20 public immutable POLE;

    // MasterContract variables
    address public feeTo;

    // Per clone variables
    // Clone init settings
    IERC20 public collateral;
    IOracle public oracle;
    bytes public oracleData;

    // Total amounts
    uint256 public totalCollateralShare; // Total collateral supplied
    Rebase public totalBorrow; // elastic = Total token amount to be repayed by borrowers, base = Total parts of the debt held by borrowers

    // User balances
    mapping(address => uint256) public userCollateralShare;
    mapping(address => uint256) public userBorrowPart;
    bool public liquidateManagerOpen;
    mapping(address => bool) public liquidateManager;

    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    uint256 public exchangeRate;

    struct AccrueInfo {
        uint64 lastAccrued;
        uint128 feesEarned;
        uint64 INTEREST_PER_SECOND;
    }

    AccrueInfo public accrueInfo;

    // Settings
    uint256 public COLLATERIZATION_RATE;
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)

    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 public LIQUIDATION_MULTIPLIER; 
    uint256 private constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

    uint256 public BORROW_OPENING_FEE;
    uint256 private constant BORROW_OPENING_FEE_PRECISION = 1e5;

    uint256 private DISTRIBUTION_PART = 10;
    uint256 private constant DISTRIBUTION_PRECISION = 100;

    address[] public userList; 
    mapping(address => uint256) public positionId; 
    

    /// @notice The constructor is only used for the initial master contract. Subsequent clones are initialised via `init`.
    constructor(IBentoBoxV1 bentoBox_, IERC20 POLE_) public {
        bentoBox = bentoBox_;
        POLE = POLE_;
        masterContract = this;
    }

    /// @notice Serves as the constructor for clones, as clones can't have a regular constructor
    /// @dev `data` is abi encoded in the format: (IERC20 collateral, IERC20 asset, IOracle oracle, bytes oracleData)
    function init(bytes calldata data) public payable override {
        require(address(collateral) == address(0), "Cauldron: already initialized");
        (collateral, oracle, oracleData, accrueInfo.INTEREST_PER_SECOND, LIQUIDATION_MULTIPLIER, COLLATERIZATION_RATE, BORROW_OPENING_FEE) = abi.decode(data, (IERC20, IOracle, bytes, uint64, uint256, uint256, uint256));
        require(address(collateral) != address(0), "Cauldron: bad pair");
        userList.push(address(0));
        liquidateManagerOpen = true;
    }

    /// @notice Accrues the interest on the borrowed tokens and handles the accumulation of fees.
    function accrue() public {
        AccrueInfo memory _accrueInfo = accrueInfo;
        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - _accrueInfo.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        _accrueInfo.lastAccrued = uint64(block.timestamp);

        Rebase memory _totalBorrow = totalBorrow;
        if (_totalBorrow.base == 0) {
            accrueInfo = _accrueInfo;
            return;
        }

        // Accrue interest
        uint128 extraAmount = (uint256(_totalBorrow.elastic).mul(_accrueInfo.INTEREST_PER_SECOND).mul(elapsedTime) / 1e18).to128();
        _totalBorrow.elastic = _totalBorrow.elastic.add(extraAmount);

        _accrueInfo.feesEarned = _accrueInfo.feesEarned.add(extraAmount);
        totalBorrow = _totalBorrow;
        accrueInfo = _accrueInfo;

        emit LogAccrue(extraAmount);
    }

    /// @notice Concrete implementation of `isSolvent`. Includes a third parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(address user, uint256 _exchangeRate) internal view returns (bool) {
        // accrue must have already been called!
        uint256 borrowPart = userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = userCollateralShare[user];
        if (collateralShare == 0) return false;

        Rebase memory _totalBorrow = totalBorrow;

        return
            bentoBox.toAmount(
                collateral,
                collateralShare.mul(EXCHANGE_RATE_PRECISION / COLLATERIZATION_RATE_PRECISION).mul(COLLATERIZATION_RATE),
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            borrowPart.mul(_totalBorrow.elastic).mul(_exchangeRate) / _totalBorrow.base;
    }

    /// @dev Checks if the user is solvent in the closed liquidation case at the end of the function body.
    modifier solvent() {
        _;
        require(_isSolvent(msg.sender, exchangeRate), "Cauldron: user insolvent");
    }

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate() public returns (bool updated, uint256 rate) {
        (updated, rate) = oracle.get(oracleData);

        if (updated) {
            exchangeRate = rate;
            emit LogExchangeRate(rate);
        } else {
            // Return the old rate if fetching wasn't successful
            rate = exchangeRate;
        }
    }

    /// @dev Helper function to move tokens.
    /// @param token The ERC-20 token.
    /// @param share The amount in shares to add.
    /// @param total Grand total amount to deduct from this contract's balance. Only applicable if `skim` is True.
    /// Only used for accounting checks.
    /// @param skim If True, only does a balance check on this contract.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    function _addTokens(
        IERC20 token,
        uint256 share,
        uint256 total,
        bool skim
    ) internal {
        if (skim) {
            require(share <= bentoBox.balanceOf(token, address(this)).sub(total), "Cauldron: Skim too much");
        } else {
            bentoBox.transfer(token, msg.sender, address(this), share);
        }
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param to The receiver of the tokens.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.x
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(
        address to,
        bool skim,
        uint256 share
    ) public {
        userCollateralShare[to] = userCollateralShare[to].add(share);
        uint256 oldTotalCollateralShare = totalCollateralShare;
        totalCollateralShare = oldTotalCollateralShare.add(share);
        _addTokens(collateral, share, oldTotalCollateralShare, skim);
        emit LogAddCollateral(skim ? address(bentoBox) : msg.sender, to, share);
    }

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(address to, uint256 share) internal {
        address collateralStrategy;
        uint256 nowBalance= IERC20(collateral).balanceOf(address(bentoBox));
        uint256 amountCollateral = bentoBox.toAmount(collateral, share, false);
        collateralStrategy = address(bentoBox.strategy(collateral));
        if(amountCollateral > nowBalance && collateralStrategy!= address(0)){
            (, , uint256 strategyBalance) = bentoBox.strategyData(collateral);
            BaseStrategy(collateralStrategy).exit(strategyBalance);
        }

        userCollateralShare[msg.sender] = userCollateralShare[msg.sender].sub(share);
        totalCollateralShare = totalCollateralShare.sub(share);
        emit LogRemoveCollateral(msg.sender, to, share);
        bentoBox.transfer(collateral, address(this), to, share);

        if(collateralStrategy!= address(0)){
            uint256 balanceBentoBox = IERC20(collateral).balanceOf(address(collateralStrategy));
            uint256 balanceStrategy = IERC20(collateral).balanceOf(address(bentoBox));
            uint256 maxBalance = balanceBentoBox.add(balanceStrategy);
            uint256 maxChangeAmount = maxBalance.mul(10) / 100;
            BaseStrategy(collateralStrategy).safeHarvest(maxBalance, true, maxChangeAmount, false);
        }
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(address to, uint256 share) public solvent {
        // accrue must be called because we check solvency
        accrue();
        _removeCollateral(to, share);
    }

    /// @dev Concrete implementation of `borrow`.
    function _borrow(address to, uint256 amount) internal returns (uint256 part, uint256 share) {
        uint256 feeAmount = amount.mul(BORROW_OPENING_FEE) / BORROW_OPENING_FEE_PRECISION; // A flat % fee is charged for any borrow
        (totalBorrow, part) = totalBorrow.add(amount.add(feeAmount), true);
        accrueInfo.feesEarned = accrueInfo.feesEarned.add(uint128(feeAmount));
        userBorrowPart[msg.sender] = userBorrowPart[msg.sender].add(part);
        if(userBorrowPart[msg.sender]>0){
            addUserListAndPositionId(msg.sender);
        }
        // As long as there are tokens on this contract you can 'mint'... this enables limiting borrows
        share = bentoBox.toShare(POLE, amount, false);
        bentoBox.transfer(POLE, address(this), to, share);

        emit LogBorrow(msg.sender, to, amount.add(feeAmount), part);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(address to, uint256 amount) public solvent returns (uint256 part, uint256 share) {
        accrue();
        (part, share) = _borrow(to, amount);
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(
        address to,
        bool skim,
        uint256 part
    ) internal returns (uint256 amount) {
        (totalBorrow, amount) = totalBorrow.sub(part, true);
        userBorrowPart[to] = userBorrowPart[to].sub(part);
        if(userBorrowPart[to]==0){
            delUserListAndPositionId(to);
        }
        uint256 share = bentoBox.toShare(POLE, amount, true);
        bentoBox.transfer(POLE, skim ? address(bentoBox) : msg.sender, address(this), share);
        emit LogRepay(skim ? address(bentoBox) : msg.sender, to, amount, part);
    }

    /// @notice Repays a loan.
    /// @param to Address of the user this payment should go.
    /// @param skim True if the amount should be skimmed from the deposit balance of msg.sender.
    /// False if tokens from msg.sender in `bentoBox` should be transferred.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(
        address to,
        bool skim,
        uint256 part
    ) public returns (uint256 amount) {
        accrue();
        amount = _repay(to, skim, part);
    }

    // Functions that need accrue to be called
    uint8 internal constant ACTION_REPAY = 2;
    uint8 internal constant ACTION_REMOVE_COLLATERAL = 4;
    uint8 internal constant ACTION_BORROW = 5;
    uint8 internal constant ACTION_GET_REPAY_SHARE = 6;
    uint8 internal constant ACTION_GET_REPAY_PART = 7;
    uint8 internal constant ACTION_ACCRUE = 8;

    // Functions that don't need accrue to be called
    uint8 internal constant ACTION_ADD_COLLATERAL = 10;
    uint8 internal constant ACTION_UPDATE_EXCHANGE_RATE = 11;

    // Function on BentoBox
    uint8 internal constant ACTION_BENTO_DEPOSIT = 20;
    uint8 internal constant ACTION_BENTO_WITHDRAW = 21;
    uint8 internal constant ACTION_BENTO_TRANSFER = 22;
    uint8 internal constant ACTION_BENTO_TRANSFER_MULTIPLE = 23;
    uint8 internal constant ACTION_BENTO_SETAPPROVAL = 24;

    // Any external call (except to BentoBox)
    uint8 internal constant ACTION_CALL = 30;

    int256 internal constant USE_VALUE1 = -1;
    int256 internal constant USE_VALUE2 = -2;

    /// @dev Helper function for choosing the correct value (`value1` or `value2`) depending on `inNum`.
    function _num(
        int256 inNum,
        uint256 value1,
        uint256 value2
    ) internal pure returns (uint256 outNum) {
        outNum = inNum >= 0 ? uint256(inNum) : (inNum == USE_VALUE1 ? value1 : value2);
    }

    /// @dev Helper function for depositing into `bentoBox`.
    function _bentoDeposit(
        bytes memory data,
        uint256 value,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        amount = int256(_num(amount, value1, value2)); // Done this way to avoid stack too deep errors
        share = int256(_num(share, value1, value2));
        return bentoBox.deposit{value: value}(token, msg.sender, to, uint256(amount), uint256(share));
    }

    /// @dev Helper function to withdraw from the `bentoBox`.
    function _bentoWithdraw(
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (uint256, uint256) {
        (IERC20 token, address to, int256 amount, int256 share) = abi.decode(data, (IERC20, address, int256, int256));
        return bentoBox.withdraw(token, msg.sender, to, _num(amount, value1, value2), _num(share, value1, value2));
    }

    /// @dev Helper function to perform a contract call and eventually extracting revert messages on failure.
    /// Calls to `bentoBox` are not allowed for obvious security reasons.
    /// This also means that calls made from this contract shall *not* be trusted.
    function _call(
        uint256 value,
        bytes memory data,
        uint256 value1,
        uint256 value2
    ) internal returns (bytes memory, uint8) {
        (address callee, bytes memory callData, bool useValue1, bool useValue2, uint8 returnValues) =
            abi.decode(data, (address, bytes, bool, bool, uint8));

        if (useValue1 && !useValue2) {
            callData = abi.encodePacked(callData, value1);
        } else if (!useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value2);
        } else if (useValue1 && useValue2) {
            callData = abi.encodePacked(callData, value1, value2);
        }

        require(callee != address(bentoBox) && callee != address(this), "Cauldron: can't call");

        (bool success, bytes memory returnData) = callee.call{value: value}(callData);
        require(success, "Cauldron: call failed");
        return (returnData, returnValues);
    }

    struct CookStatus {
        bool needsSolvencyCheck;
        bool hasAccrued;
    }

    /// @notice Executes a set of actions and allows composability (contract calls) to other contracts.
    /// @param actions An array with a sequence of actions to execute (see ACTION_ declarations).
    /// @param values A one-to-one mapped array to `actions`. ETH amounts to send along with the actions.
    /// Only applicable to `ACTION_CALL`, `ACTION_BENTO_DEPOSIT`.
    /// @param datas A one-to-one mapped array to `actions`. Contains abi encoded data of function arguments.
    /// @return value1 May contain the first positioned return value of the last executed action (if applicable).
    /// @return value2 May contain the second positioned return value of the last executed action which returns 2 values (if applicable).
    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2) {
        CookStatus memory status;
        for (uint256 i = 0; i < actions.length; i++) {
            uint8 action = actions[i];
            if (!status.hasAccrued && action < 10) {
                accrue();
                status.hasAccrued = true;
            }
            if (action == ACTION_ADD_COLLATERAL) {
                (int256 share, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                addCollateral(to, skim, _num(share, value1, value2));
            } else if (action == ACTION_REPAY) {
                (int256 part, address to, bool skim) = abi.decode(datas[i], (int256, address, bool));
                _repay(to, skim, _num(part, value1, value2));
            } else if (action == ACTION_REMOVE_COLLATERAL) {
                (int256 share, address to) = abi.decode(datas[i], (int256, address));
                _removeCollateral(to, _num(share, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_BORROW) {
                (int256 amount, address to) = abi.decode(datas[i], (int256, address));
                (value1, value2) = _borrow(to, _num(amount, value1, value2));
                status.needsSolvencyCheck = true;
            } else if (action == ACTION_UPDATE_EXCHANGE_RATE) {
                (bool must_update, uint256 minRate, uint256 maxRate) = abi.decode(datas[i], (bool, uint256, uint256));
                (bool updated, uint256 rate) = updateExchangeRate();
                require((!must_update || updated) && rate > minRate && (maxRate == 0 || rate > maxRate), "Cauldron: rate not ok");
            } else if (action == ACTION_BENTO_SETAPPROVAL) {
                (address user, address _masterContract, bool approved, uint8 v, bytes32 r, bytes32 s) =
                    abi.decode(datas[i], (address, address, bool, uint8, bytes32, bytes32));
                bentoBox.setMasterContractApproval(user, _masterContract, approved, v, r, s);
            } else if (action == ACTION_BENTO_DEPOSIT) {
                (value1, value2) = _bentoDeposit(datas[i], values[i], value1, value2);
            } else if (action == ACTION_BENTO_WITHDRAW) {
                (value1, value2) = _bentoWithdraw(datas[i], value1, value2);
            } else if (action == ACTION_BENTO_TRANSFER) {
                (IERC20 token, address to, int256 share) = abi.decode(datas[i], (IERC20, address, int256));
                bentoBox.transfer(token, msg.sender, to, _num(share, value1, value2));
            } else if (action == ACTION_BENTO_TRANSFER_MULTIPLE) {
                (IERC20 token, address[] memory tos, uint256[] memory shares) = abi.decode(datas[i], (IERC20, address[], uint256[]));
                bentoBox.transferMultiple(token, msg.sender, tos, shares);
            } else if (action == ACTION_CALL) {
                (bytes memory returnData, uint8 returnValues) = _call(values[i], datas[i], value1, value2);
                if (returnValues == 1) {
                    (value1) = abi.decode(returnData, (uint256));
                } else if (returnValues == 2) {
                    (value1, value2) = abi.decode(returnData, (uint256, uint256));
                }
            } else if (action == ACTION_GET_REPAY_SHARE) {
                int256 part = abi.decode(datas[i], (int256));
                value1 = bentoBox.toShare(POLE, totalBorrow.toElastic(_num(part, value1, value2), true), true);
            } else if (action == ACTION_GET_REPAY_PART) {
                int256 amount = abi.decode(datas[i], (int256));
                value1 = totalBorrow.toBase(_num(amount, value1, value2), false);
            }
        }

        if (status.needsSolvencyCheck) {
            require(_isSolvent(msg.sender, exchangeRate), "Cauldron: user insolvent");
        }
    }

    /// @notice Handles the liquidation of users' balances, once the users' amount of collateral is too low.
    /// @param users An array of user addresses.
    /// @param maxBorrowParts A one-to-one mapping to `users`, contains maximum (partial) borrow amounts (to liquidate) of the respective user.
    /// @param to Address of the receiver in open liquidations if `swapper` is zero.
    function liquidate(
        address[] calldata users,
        uint256[] calldata maxBorrowParts,
        address to,
        ISwapper swapper
    ) public {
        if(liquidateManagerOpen){
            require(liquidateManager[msg.sender], "liquidateManager err");
        }
        // Oracle can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = updateExchangeRate();
        accrue();

        uint256 allCollateralShare;
        uint256 allBorrowAmount;
        uint256 allBorrowPart;
        address collateralStrategy;
        Rebase memory _totalBorrow = totalBorrow;
        Rebase memory bentoBoxTotals = bentoBox.totals(collateral);
        
        collateralStrategy = address(bentoBox.strategy(collateral));
        if(collateralStrategy!= address(0)){
            (, , uint256 strategyBalance) = bentoBox.strategyData(collateral);
            BaseStrategy(collateralStrategy).exit(strategyBalance);
        }

        for (uint256 i = 0; i < users.length; i++) {
            address user = users[i];
            if (!_isSolvent(user, _exchangeRate)) {
                uint256 borrowPart;
                {
                    uint256 availableBorrowPart = userBorrowPart[user];
                    borrowPart = maxBorrowParts[i] > availableBorrowPart ? availableBorrowPart : maxBorrowParts[i];
                    userBorrowPart[user] = availableBorrowPart.sub(borrowPart);
                    if(userBorrowPart[user]==0){
                        delUserListAndPositionId(user);
                    }
                }
                uint256 borrowAmount = _totalBorrow.toElastic(borrowPart, false);
                uint256 collateralShare =
                    bentoBoxTotals.toBase(
                        borrowAmount.mul(LIQUIDATION_MULTIPLIER).mul(_exchangeRate) /
                            (LIQUIDATION_MULTIPLIER_PRECISION * EXCHANGE_RATE_PRECISION),
                        false
                    );

                userCollateralShare[user] = userCollateralShare[user].sub(collateralShare);
                emit LogRemoveCollateral(user, to, collateralShare);
                emit LogRepay(msg.sender, user, borrowAmount, borrowPart);

                // Keep totals
                allCollateralShare = allCollateralShare.add(collateralShare);
                allBorrowAmount = allBorrowAmount.add(borrowAmount);
                allBorrowPart = allBorrowPart.add(borrowPart);
            }
        }
        require(allBorrowAmount != 0, "Cauldron: all are solvent");
        _totalBorrow.elastic = _totalBorrow.elastic.sub(allBorrowAmount.to128());
        _totalBorrow.base = _totalBorrow.base.sub(allBorrowPart.to128());
        totalBorrow = _totalBorrow;
        totalCollateralShare = totalCollateralShare.sub(allCollateralShare);

        // Apply a percentual fee share to sNORTH holders
        
        {
            uint256 distributionAmount = (allBorrowAmount.mul(LIQUIDATION_MULTIPLIER) / LIQUIDATION_MULTIPLIER_PRECISION).sub(allBorrowAmount).mul(DISTRIBUTION_PART) / DISTRIBUTION_PRECISION; // Distribution Amount
            allBorrowAmount = allBorrowAmount.add(distributionAmount);
            accrueInfo.feesEarned = accrueInfo.feesEarned.add(distributionAmount.to128());
        }

        uint256 allBorrowShare = bentoBox.toShare(POLE, allBorrowAmount, true);

        // Swap using a swapper freely chosen by the caller
        // Open (flash) liquidation: get proceeds first and provide the borrow after
        bentoBox.transfer(collateral, address(this), to, allCollateralShare);
        if (swapper != ISwapper(0)) {
            swapper.swap(collateral, POLE, msg.sender, allBorrowShare, allCollateralShare);
        }

        bentoBox.transfer(POLE, msg.sender, address(this), allBorrowShare);

        if(collateralStrategy!= address(0)){
            uint256 balanceBentoBox = IERC20(collateral).balanceOf(address(collateralStrategy));
            uint256 balanceStrategy = IERC20(collateral).balanceOf(address(bentoBox));
            uint256 maxBalance = balanceBentoBox.add(balanceStrategy);
            uint256 maxChangeAmount = maxBalance.mul(10) / 100;
            BaseStrategy(collateralStrategy).safeHarvest(maxBalance, true, maxChangeAmount, false);
        }
    }

    /// @notice Withdraws the fees accumulated.
    function withdrawFees() public {
        accrue();
        address _feeTo = masterContract.feeTo();
        uint256 _feesEarned = accrueInfo.feesEarned;
        uint256 share = bentoBox.toShare(POLE, _feesEarned, false);
        bentoBox.transfer(POLE, address(this), _feeTo, share);
        accrueInfo.feesEarned = 0;

        emit LogWithdrawFees(_feeTo, _feesEarned);
    }

    /// @notice Sets the beneficiary of interest accrued.
    /// MasterContract Only Admin function.
    /// @param newFeeTo The address of the receiver.
    function setFeeTo(address newFeeTo) public onlyOwner {
        feeTo = newFeeTo;
        emit LogFeeTo(newFeeTo);
    }

    /// @notice reduces the supply of POLE
    /// @param amount amount to reduce supply by
    function reduceSupply(uint256 amount) public {
        require(msg.sender == masterContract.owner(), "Caller is not the owner");
        bentoBox.withdraw(POLE, address(this), masterContract.owner(), amount, 0);
    }

    function setDistributionPart(uint256 amount) public {
        require(msg.sender == masterContract.owner(), "Caller is not the owner");
        DISTRIBUTION_PART = amount;
        emit LogsetDistributionPart(amount);
    }

    function userListLength() public view returns(uint256){
        return userList.length - 1;
    }

    function addUserListAndPositionId(address _user) internal returns(bool){
        require(_user!=address(0),"address cannot be 0");
        if(userList[positionId[_user]] == _user){
            return false;
        }
        positionId[_user]=userList.length;
        userList.push(_user);
        return true;
    }

    function delUserListAndPositionId(address _user) internal returns(bool){
        require(_user!=address(0),"address cannot be 0");

        if(userList[positionId[_user]] != _user){
            return false;
        }
        uint256 usersIndex = userList.length - 1; 
        uint256 delUserID= positionId[_user];

        address lastUserAddr = userList[usersIndex]; 

        userList[delUserID] = lastUserAddr;
        positionId[lastUserAddr] = delUserID;

        delete positionId[_user];
        userList.pop();

        return true;
    }

    //setLiquidateManagerOpen
    function setLiquidateManagerOpen(bool _val) public returns(bool){
        require(msg.sender == masterContract.owner(), "Caller is not the owner");
        liquidateManagerOpen = _val;
        return true;
    }

    //setLiquidateManager
    function setLiquidateManager(address _address,bool _val) public returns(bool){
        require(msg.sender == masterContract.owner(), "Caller is not the owner");
        liquidateManager[_address] = _val;
        return true;
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
// Using the same Copyleft License as in the original Repository
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../interfaces/IOracle.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../libraries/FixedPoint.sol";

// solhint-disable not-rely-on-time

// adapted from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleSlidingWindowOracle.sol
interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

interface IwsFORT {
    function sFORTTowsFORT( uint256 _amount ) external view returns ( uint256 );
}

contract wsFORTOracle is IOracle {
    using FixedPoint for *;
    using BoringMath for uint256;
    uint256 public constant PERIOD = 10 minutes;

    IAggregator public constant MIM_USD = IAggregator(0x54EdAB30a7134A16a54218AE64C73e1DAf48a8Fb);
    IUniswapV2Pair public constant MIM_FORT = IUniswapV2Pair(0x3E5F198B46F3dE52761b02d4aC8ef4cECeAc22D6);
    IwsFORT public constant wsFORT = IwsFORT(0xF3823A2504b5C5907fDd0f708efa0198bE4D837C);

    struct PairInfo {
        uint256 priceCumulativeLast;
        uint32 blockTimestampLast;
        uint144 priceAverage;
    }

    PairInfo public pairInfo;
    function _get(uint256 blockTimestamp) public view returns (uint256) {
        uint256 priceCumulative = MIM_FORT.price1CumulativeLast();

        // if time has elapsed since the last update on the MIM_FORT, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(MIM_FORT).getReserves();
        priceCumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * (blockTimestamp - blockTimestampLast); // overflows ok

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        return priceCumulative;
    }

    // Get the latest exchange rate, if no valid (recent) rate is available, return false
    /// @inheritdoc IOracle
    function get(bytes calldata data) external override returns (bool, uint256) {
        uint32 blockTimestamp = uint32(block.timestamp);
        if (pairInfo.blockTimestampLast == 0) {
            pairInfo.blockTimestampLast = blockTimestamp;
            pairInfo.priceCumulativeLast = _get(blockTimestamp);
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairInfo.priceAverage);
        }

        uint256 priceCumulative = _get(blockTimestamp);
        pairInfo.priceAverage = uint144(1e53 / (uint256(1e18).mul(uint256(FixedPoint
            .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
            .mul(1e18)
            .decode144())).mul(uint256(MIM_USD.latestAnswer())) / wsFORT.sFORTTowsFORT(1e9)));
        pairInfo.blockTimestampLast = blockTimestamp;
        pairInfo.priceCumulativeLast = priceCumulative;

        return (true, pairInfo.priceAverage);
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata data) public view override returns (bool, uint256) {
        uint32 blockTimestamp = uint32(block.timestamp);
        if (pairInfo.blockTimestampLast == 0) {
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairInfo.priceAverage);
        }

        uint256 priceCumulative = _get(blockTimestamp);
        uint144 priceAverage = uint144(1e53 / (uint256(1e18).mul(uint256(FixedPoint
            .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
            .mul(1e18)
            .decode144())).mul(uint256(MIM_USD.latestAnswer())) / wsFORT.sFORTTowsFORT(1e9)));

        return (true, priceAverage);
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (uint256 reserve0, uint256 reserve1, ) = MIM_FORT.getReserves();
        rate = 1e53 / (uint256(1e18).mul(reserve0.mul(1e18) / reserve1).mul(uint256(MIM_USD.latestAnswer())) / wsFORT.sFORTTowsFORT(1e9));
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return "wsFORT TWAP";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return "wsFORT";
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;
import "./FullMath.sol";

// solhint-disable

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 private constant RESOLUTION = 112;
    uint256 private constant Q112 = 0x10000000000000000000000000000;
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000;
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint256, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, "FixedPoint::mul: overflow");
        return uq144x112(z);
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // lossy if either numerator or denominator is greater than 112 bits
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, "FixedPoint::fraction: div by 0");
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= uint144(-1)) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= uint224(-1), "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= uint224(-1), "FixedPoint::fraction: overflow");
            return uq112x112(uint224(result));
        }
    }
}

// SPDX-License-Identifier: CC-BY-4.0
pragma solidity 0.6.12;

// solhint-disable

// taken from https://medium.com/coinmonks/math-in-solidity-part-3-percents-and-proportions-4db014e080b1
// license is CC-BY-4.0
library FullMath {
    function fullMul(uint256 x, uint256 y) private pure returns (uint256 l, uint256 h) {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    function fullDiv(
        uint256 l,
        uint256 h,
        uint256 d
    ) private pure returns (uint256) {
        uint256 pow2 = d & -d;
        d /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        r *= 2 - d * r;
        return l * r;
    }

    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 d
    ) internal pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        uint256 mm = mulmod(x, y, d);
        if (mm > l) h -= 1;
        l -= mm;
        require(h < d, "FullMath::mulDiv: overflow");
        return fullDiv(l, h, d);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
// Using the same Copyleft License as in the original Repository
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../interfaces/IOracle.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../libraries/FixedPoint.sol";

// solhint-disable not-rely-on-time

// adapted from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleSlidingWindowOracle.sol
interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

interface IWMEMO {
    function MEMOTowMEMO( uint256 _amount ) external view returns ( uint256 );
}

contract WMEMOOracle is IOracle {
    using FixedPoint for *;
    using BoringMath for uint256;
    uint256 public constant PERIOD = 10 minutes;

    IAggregator public constant AVAX_USD = IAggregator(0x0A77230d17318075983913bC2145DB16C7366156);
    IUniswapV2Pair public constant WAVAX_TIME = IUniswapV2Pair(0xf64e1c5B6E17031f5504481Ac8145F4c3eab4917);
    IWMEMO public constant WMEMO = IWMEMO(0x0da67235dD5787D67955420C84ca1cEcd4E5Bb3b);

    struct PairInfo {
        uint256 priceCumulativeLast;
        uint32 blockTimestampLast;
        uint144 priceAverage;
    }

    PairInfo public pairInfo;
    function _get(uint32 blockTimestamp) public view returns (uint256) {
        uint256 priceCumulative = WAVAX_TIME.price1CumulativeLast();

        // if time has elapsed since the last update on the WAVAX_TIME, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(WAVAX_TIME).getReserves();
        priceCumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * (blockTimestamp - blockTimestampLast); // overflows ok

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        return priceCumulative;
    }

    // Get the latest exchange rate, if no valid (recent) rate is available, return false
    /// @inheritdoc IOracle
    function get(bytes calldata data) external override returns (bool, uint256) {
        uint32 blockTimestamp = uint32(block.timestamp);
        if (pairInfo.blockTimestampLast == 0) {
            pairInfo.blockTimestampLast = blockTimestamp;
            pairInfo.priceCumulativeLast = _get(blockTimestamp);
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairInfo.priceAverage);
        }

        uint256 priceCumulative = _get(blockTimestamp);
        pairInfo.priceAverage = uint144(1e53 / (uint256(1e18).mul(uint256(FixedPoint
            .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
            .mul(1e18)
            .decode144())).mul(uint256(AVAX_USD.latestAnswer())) / WMEMO.MEMOTowMEMO(1e9)));
        pairInfo.blockTimestampLast = blockTimestamp;
        pairInfo.priceCumulativeLast = priceCumulative;

        return (true, pairInfo.priceAverage);
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata data) public view override returns (bool, uint256) {
        uint32 blockTimestamp = uint32(block.timestamp);
        if (pairInfo.blockTimestampLast == 0) {
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairInfo.priceAverage);
        }

        uint256 priceCumulative = _get(blockTimestamp);
        uint144 priceAverage = uint144(1e53 / (uint256(1e18).mul(uint256(FixedPoint
            .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
            .mul(1e18)
            .decode144())).mul(uint256(AVAX_USD.latestAnswer())) / WMEMO.MEMOTowMEMO(1e9)));

        return (true, priceAverage);
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (uint256 reserve0, uint256 reserve1, ) = WAVAX_TIME.getReserves();
        rate = 1e53 / (uint256(1e18).mul(reserve0.mul(1e18) / reserve1).mul(uint256(AVAX_USD.latestAnswer())) / WMEMO.MEMOTowMEMO(1e9));
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return "wMEMO TWAP";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return "wMEMO";
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
// Using the same Copyleft License as in the original Repository
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../interfaces/IOracle.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../libraries/FixedPoint.sol";

// solhint-disable not-rely-on-time

// adapted from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleSlidingWindowOracle.sol
interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

interface IWGLAZE {
    function GLAZETowGLZAE( uint256 _amount ) external view returns ( uint256 );
}

contract WGLAZEOracle is IOracle {
    using FixedPoint for *;
    using BoringMath for uint256;
    uint256 public constant PERIOD = 10 minutes;

    IAggregator public constant MIM_USD = IAggregator(0x54EdAB30a7134A16a54218AE64C73e1DAf48a8Fb);
    IUniswapV2Pair public constant MIM_ICY = IUniswapV2Pair(0x453B5415Fe883f15686A5fF2aC6FF35ca6702628);
    IWGLAZE public constant WGLAZE = IWGLAZE(0x80277a98bD53AA835Ec4Cb7aEDF04Ac8fBac5E3C);

    struct PairInfo {
        uint256 priceCumulativeLast;
        uint32 blockTimestampLast;
        uint144 priceAverage;
    }

    PairInfo public pairInfo;
    function _get(uint256 blockTimestamp) public view returns (uint256) {
        uint256 priceCumulative = MIM_ICY.price1CumulativeLast();

        // if time has elapsed since the last update on the MIM_ICY, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(MIM_ICY).getReserves();
        priceCumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * (blockTimestamp - blockTimestampLast); // overflows ok

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        return priceCumulative;
    }

    // Get the latest exchange rate, if no valid (recent) rate is available, return false
    /// @inheritdoc IOracle
    function get(bytes calldata data) external override returns (bool, uint256) {
        uint32 blockTimestamp = uint32(block.timestamp);
        if (pairInfo.blockTimestampLast == 0) {
            pairInfo.blockTimestampLast = blockTimestamp;
            pairInfo.priceCumulativeLast = _get(blockTimestamp);
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairInfo.priceAverage);
        }

        uint256 priceCumulative = _get(blockTimestamp);
        pairInfo.priceAverage = uint144(1e53 / (uint256(1e18).mul(uint256(FixedPoint
            .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
            .mul(1e18)
            .decode144())).mul(uint256(MIM_USD.latestAnswer())) / WGLAZE.GLAZETowGLZAE(1e9)));
        pairInfo.blockTimestampLast = blockTimestamp;
        pairInfo.priceCumulativeLast = priceCumulative;

        return (true, pairInfo.priceAverage);
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata data) public view override returns (bool, uint256) {
        uint32 blockTimestamp = uint32(block.timestamp);
        if (pairInfo.blockTimestampLast == 0) {
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairInfo.priceAverage);
        }

        uint256 priceCumulative = _get(blockTimestamp);
        uint144 priceAverage = uint144(1e53 / (uint256(1e18).mul(uint256(FixedPoint
            .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
            .mul(1e18)
            .decode144())).mul(uint256(MIM_USD.latestAnswer())) / WGLAZE.GLAZETowGLZAE(1e9)));

        return (true, priceAverage);
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (uint256 reserve0, uint256 reserve1, ) = MIM_ICY.getReserves();
        rate = 1e53 / (uint256(1e18).mul(reserve0.mul(1e18) / reserve1).mul(uint256(MIM_USD.latestAnswer())) / WGLAZE.GLAZETowGLZAE(1e9));
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return "WGLAZE TWAP";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return "WGLAZE";
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
// Using the same Copyleft License as in the original Repository
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../interfaces/IOracle.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../libraries/FixedPoint.sol";

// solhint-disable not-rely-on-time

// adapted from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleSlidingWindowOracle.sol
interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

interface IMELT {
    function getSmeltAmount( uint256 _amount ) external view returns ( uint256 );
}

contract SMELTOracle is IOracle {
    using FixedPoint for *;
    using BoringMath for uint256;
    uint256 public constant PERIOD = 10 minutes;

    IAggregator public constant AVAX_USD = IAggregator(0x0A77230d17318075983913bC2145DB16C7366156);
    IUniswapV2Pair public constant MELT_WAVAX = IUniswapV2Pair(0x2923a62b2531EC744ca0C1e61dfFab1Ad9369FeB);
    IMELT public constant MELTsaving = IMELT(0x1e93b54AC156Ac2FC9714B91Fa10f1b65e2daFD9);

    struct PairInfo {
        uint256 priceCumulativeLast;
        uint32 blockTimestampLast;
        uint144 priceAverage;
    }

    PairInfo public pairInfo;
    function _get(uint256 blockTimestamp) public view returns (uint256) {
        uint256 priceCumulative = MELT_WAVAX.price0CumulativeLast();

        // if time has elapsed since the last update on the MELT_WAVAX, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(MELT_WAVAX).getReserves();
        priceCumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * (blockTimestamp - blockTimestampLast); // overflows ok

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        return priceCumulative;
    }

    // Get the latest exchange rate, if no valid (recent) rate is available, return false
    /// @inheritdoc IOracle
    function get(bytes calldata data) external override returns (bool, uint256) {
        uint32 blockTimestamp = uint32(block.timestamp);
        if (pairInfo.blockTimestampLast == 0) {
            pairInfo.blockTimestampLast = blockTimestamp;
            pairInfo.priceCumulativeLast = _get(blockTimestamp);
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairInfo.priceAverage);
        }

        uint256 priceCumulative = _get(blockTimestamp);
        pairInfo.priceAverage = uint144(1e53 / (uint256(1e18).mul(uint256(FixedPoint
            .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
            .mul(1e18)
            .decode144())).mul(uint256(AVAX_USD.latestAnswer())) / MELTsaving.getSmeltAmount(1e18)) / 1e9 );
        pairInfo.blockTimestampLast = blockTimestamp;
        pairInfo.priceCumulativeLast = priceCumulative;

        return (true, pairInfo.priceAverage);
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata data) public view override returns (bool, uint256) {
        uint32 blockTimestamp = uint32(block.timestamp);
        if (pairInfo.blockTimestampLast == 0) {
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairInfo.priceAverage);
        }

        uint256 priceCumulative = _get(blockTimestamp);
        uint144 priceAverage = uint144(1e53 / (uint256(1e18).mul(uint256(FixedPoint
            .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
            .mul(1e18)
            .decode144())).mul(uint256(AVAX_USD.latestAnswer())) / MELTsaving.getSmeltAmount(1e18)) / 1e9 );

        return (true, priceAverage);
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (uint256 reserve0, uint256 reserve1, ) = MELT_WAVAX.getReserves();
        rate = 1e53 / (uint256(1e18).mul(reserve1.mul(1e18) / reserve0).mul(uint256(AVAX_USD.latestAnswer())) / MELTsaving.getSmeltAmount(1e18)) / 1e9;
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return "SMELT TWAP";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return "SMELT";
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
// Using the same Copyleft License as in the original Repository
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../interfaces/IOracle.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../libraries/FixedPoint.sol";

// solhint-disable not-rely-on-time

// adapted from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleSlidingWindowOracle.sol
interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

contract PTPOracle is IOracle {
    using FixedPoint for *;
    using BoringMath for uint256;
    uint256 public constant PERIOD = 10 minutes;

    IAggregator public constant AVAX_USD = IAggregator(0x0A77230d17318075983913bC2145DB16C7366156);
    IUniswapV2Pair public constant WAVAX_PTP = IUniswapV2Pair(0xCDFD91eEa657cc2701117fe9711C9a4F61FEED23);
    address public constant PTP = 0x22d4002028f537599bE9f666d1c4Fa138522f9c8;

    struct PairInfo {
        uint256 priceCumulativeLast;
        uint32 blockTimestampLast;
        uint144 priceAverage;
    }

    PairInfo public pairInfo;
    function _get(uint32 blockTimestamp) public view returns (uint256) {
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = WAVAX_PTP.getReserves();

        uint256 priceCumulative = address(PTP) == WAVAX_PTP.token0() ? WAVAX_PTP.price0CumulativeLast() : WAVAX_PTP.price1CumulativeLast();

        (reserve0, reserve1) = address(PTP) == WAVAX_PTP.token0() ? (reserve1, reserve0) : (reserve0, reserve1);

        priceCumulative += uint256(FixedPoint.fraction(reserve0, reserve1)._x) * (blockTimestamp - blockTimestampLast);

        return priceCumulative;
    }

    // Get the latest exchange rate, if no valid (recent) rate is available, return false
    /// @inheritdoc IOracle
    function get(bytes calldata data) external override returns (bool, uint256) {
        uint32 blockTimestamp = uint32(block.timestamp);
        if (pairInfo.blockTimestampLast == 0) {
            pairInfo.blockTimestampLast = blockTimestamp;
            pairInfo.priceCumulativeLast = _get(blockTimestamp);
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairInfo.priceAverage);
        }

        uint256 priceCumulative = _get(blockTimestamp);
        pairInfo.priceAverage = uint144(1e53 / (uint256(1e18).mul(uint256(FixedPoint
            .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
            .mul(1e18)
            .decode144())).mul(uint256(AVAX_USD.latestAnswer())) / 1e9));
        pairInfo.blockTimestampLast = blockTimestamp;
        pairInfo.priceCumulativeLast = priceCumulative;

        return (true, pairInfo.priceAverage);
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata data) public view override returns (bool, uint256) {
        uint32 blockTimestamp = uint32(block.timestamp);
        if (pairInfo.blockTimestampLast == 0) {
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairInfo.priceAverage);
        }

        uint256 priceCumulative = _get(blockTimestamp);
        uint144 priceAverage = uint144(1e53 / (uint256(1e18).mul(uint256(FixedPoint
            .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
            .mul(1e18)
            .decode144())).mul(uint256(AVAX_USD.latestAnswer())) / 1e9));

        return (true, priceAverage);
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (uint256 reserve0, uint256 reserve1, ) = WAVAX_PTP.getReserves();

        (reserve0, reserve1) = address(PTP) == WAVAX_PTP.token0() ? (reserve1, reserve0) : (reserve0, reserve1);

        rate = 1e53 / (uint256(1e18).mul(reserve0.mul(1e18) / reserve1).mul(uint256(AVAX_USD.latestAnswer())) / 1e9);
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return "PTP TWAP";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return "PTP";
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
// Using the same Copyleft License as in the original Repository
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../interfaces/IOracle.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Factory.sol";
import "@sushiswap/core/contracts/uniswapv2/interfaces/IUniswapV2Pair.sol";
import "../libraries/FixedPoint.sol";

// solhint-disable not-rely-on-time

// adapted from https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/examples/ExampleSlidingWindowOracle.sol
interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

contract gOHMOracle is IOracle {
    using FixedPoint for *;
    using BoringMath for uint256;
    uint256 public constant PERIOD = 10 minutes;

    IAggregator public constant AVAX_USD = IAggregator(0x0A77230d17318075983913bC2145DB16C7366156);
    IUniswapV2Pair public constant WAVAX_gOHM = IUniswapV2Pair(0xB674f93952F02F2538214D4572Aa47F262e990Ff);

    struct PairInfo {
        uint256 priceCumulativeLast;
        uint32 blockTimestampLast;
        uint144 priceAverage;
    }

    PairInfo public pairInfo;
    function _get(uint32 blockTimestamp) public view returns (uint256) {
        uint256 priceCumulative = WAVAX_gOHM.price0CumulativeLast();

        // if time has elapsed since the last update on the WAVAX_gOHM, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(WAVAX_gOHM).getReserves();
        priceCumulative += uint256(FixedPoint.fraction(reserve1, reserve0)._x) * (blockTimestamp - blockTimestampLast); // overflows ok

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        return priceCumulative;
    }

    // Get the latest exchange rate, if no valid (recent) rate is available, return false
    /// @inheritdoc IOracle
    function get(bytes calldata data) external override returns (bool, uint256) {
        uint32 blockTimestamp = uint32(block.timestamp);
        if (pairInfo.blockTimestampLast == 0) {
            pairInfo.blockTimestampLast = blockTimestamp;
            pairInfo.priceCumulativeLast = _get(blockTimestamp);
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairInfo.priceAverage);
        }

        uint256 priceCumulative = _get(blockTimestamp);
        pairInfo.priceAverage = uint144(1e53 / (uint256(1e18).mul(uint256(FixedPoint
            .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
            .mul(1e18)
            .decode144())).mul(uint256(AVAX_USD.latestAnswer())) / 1e9));
        pairInfo.blockTimestampLast = blockTimestamp;
        pairInfo.priceCumulativeLast = priceCumulative;

        return (true, pairInfo.priceAverage);
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata data) public view override returns (bool, uint256) {
        uint32 blockTimestamp = uint32(block.timestamp);
        if (pairInfo.blockTimestampLast == 0) {
            return (false, 0);
        }
        uint32 timeElapsed = blockTimestamp - pairInfo.blockTimestampLast; // overflow is desired
        if (timeElapsed < PERIOD) {
            return (true, pairInfo.priceAverage);
        }

        uint256 priceCumulative = _get(blockTimestamp);
        uint144 priceAverage = uint144(1e53 / (uint256(1e18).mul(uint256(FixedPoint
            .uq112x112(uint224((priceCumulative - pairInfo.priceCumulativeLast) / timeElapsed))
            .mul(1e18)
            .decode144())).mul(uint256(AVAX_USD.latestAnswer())) / 1e9));

        return (true, priceAverage);
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (uint256 reserve0, uint256 reserve1, ) = WAVAX_gOHM.getReserves();
        rate = 1e53 / (uint256(1e18).mul(reserve1.mul(1e18) / reserve0).mul(uint256(AVAX_USD.latestAnswer())) / 1e9);
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return "gOHM TWAP";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return "gOHM";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "../interfaces/IOracle.sol";

// Chainlink Aggregator
interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

contract WETHOracle is IOracle {
    using BoringMath for uint256; // Keep everything in uint256

    IAggregator public constant WETH_USD = IAggregator(0x976B3D034E162d8bD72D6b9C989d545b839003b0);
    
    // Calculates the lastest exchange rate
    // Uses both divide and multiply only for tokens not supported directly by Chainlink, for example MKR/USD
    function _get() internal view returns (uint256) {
        return 1e26 / uint256(WETH_USD.latestAnswer());
    }

    // Get the latest exchange rate
    /// @inheritdoc IOracle
    function get(bytes calldata) public override returns (bool, uint256) {
        return (true, _get());
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata ) public view override returns (bool, uint256) {
        return (true, _get());
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return "WETH Chainlink";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return "LINK/WETH";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "../interfaces/IOracle.sol";

// Chainlink Aggregator
interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

contract WBTCOracle is IOracle {
    using BoringMath for uint256; // Keep everything in uint256

    IAggregator public constant WBTC_USD = IAggregator(0x2779D32d5166BAaa2B2b658333bA7e6Ec0C65743);
    
    // Calculates the lastest exchange rate
    // Uses both divide and multiply only for tokens not supported directly by Chainlink, for example MKR/USD
    function _get() internal view returns (uint256) {
        return 1e16 / uint256(WBTC_USD.latestAnswer());
    }

    // Get the latest exchange rate
    /// @inheritdoc IOracle
    function get(bytes calldata) public override returns (bool, uint256) {
        return (true, _get());
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata ) public view override returns (bool, uint256) {
        return (true, _get());
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return "WBTC Chainlink";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return "LINK/WBTC";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "../interfaces/IOracle.sol";

// Chainlink Aggregator
interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

contract WAVAXOracle is IOracle {
    using BoringMath for uint256; // Keep everything in uint256

    IAggregator public constant AVAX_USD = IAggregator(0x0A77230d17318075983913bC2145DB16C7366156);
    
    // Calculates the lastest exchange rate
    // Uses both divide and multiply only for tokens not supported directly by Chainlink, for example MKR/USD
    function _get() internal view returns (uint256) {
        return 1e26 / uint256(AVAX_USD.latestAnswer());
    }

    // Get the latest exchange rate
    /// @inheritdoc IOracle
    function get(bytes calldata) public override returns (bool, uint256) {
        return (true, _get());
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata ) public view override returns (bool, uint256) {
        return (true, _get());
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return "AVAX Chainlink";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return "LINK/AVAX";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "../interfaces/IOracle.sol";

// Chainlink Aggregator

interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

contract ChainlinkOracle is IOracle {
    using BoringMath for uint256; // Keep everything in uint256

    // Calculates the lastest exchange rate
    // Uses both divide and multiply only for tokens not supported directly by Chainlink, for example MKR/USD
    function _get(
        address multiply,
        address divide,
        uint256 decimals
    ) internal view returns (uint256) {
        uint256 price = uint256(1e36);
        if (multiply != address(0)) {
            price = price.mul(uint256(IAggregator(multiply).latestAnswer()));
        } else {
            price = price.mul(1e18);
        }

        if (divide != address(0)) {
            price = price / uint256(IAggregator(divide).latestAnswer());
        }

        return price / decimals;
    }

    function getDataParameter(
        address multiply,
        address divide,
        uint256 decimals
    ) public pure returns (bytes memory) {
        return abi.encode(multiply, divide, decimals);
    }

    // Get the latest exchange rate
    /// @inheritdoc IOracle
    function get(bytes calldata data) public override returns (bool, uint256) {
        (address multiply, address divide, uint256 decimals) = abi.decode(data, (address, address, uint256));
        return (true, _get(multiply, divide, decimals));
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata data) public view override returns (bool, uint256) {
        (address multiply, address divide, uint256 decimals) = abi.decode(data, (address, address, uint256));
        return (true, _get(multiply, divide, decimals));
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return "Chainlink";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return "LINK";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
import "@boringcrypto/boring-solidity/contracts/libraries/BoringMath.sol";
import "../interfaces/IOracle.sol";

// Chainlink Aggregator

interface IAggregator {
    function latestAnswer() external view returns (int256 answer);
}

interface ICurvePool {
    function get_virtual_price() external view returns (uint256 price);
}

contract ThreeCrvH2OOracle is IOracle {
    using BoringMath for uint256; // Keep everything in uint256

    ICurvePool constant public threecrv = ICurvePool(0xF72beaCc6fD334E14a7DDAC25c3ce1Eb8a827E10);
    IAggregator constant public DAI = IAggregator(0x51D7180edA2260cc4F6e4EebB82FEF5c3c2B8300);
    IAggregator constant public USDC = IAggregator(0xF096872672F44d6EBA71458D74fe67F9a77a23B9);
    IAggregator constant public USDT = IAggregator(0xEBE676ee90Fe1112671f19b6B7459bC678B67e8a);

    /**
     * @dev Returns the smallest of two numbers.
     */
    // FROM: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/6d97f0919547df11be9443b54af2d90631eaa733/contracts/utils/math/Math.sol
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    // Calculates the lastest exchange rate
    // Uses both divide and multiply only for tokens not supported directly by Chainlink, for example MKR/USD
    function _get() internal view returns (uint256) {

        // As the price should never be negative, the unchecked conversion is acceptable
        uint256 minStable = min(uint256(DAI.latestAnswer()), min(uint256(USDC.latestAnswer()), uint256(USDT.latestAnswer())));

        uint256 yVCurvePrice = threecrv.get_virtual_price() .mul(minStable);

        return 1e44 / yVCurvePrice;
    }

    // Get the latest exchange rate
    /// @inheritdoc IOracle
    function get(bytes calldata) public override returns (bool, uint256) {
        return (true, _get());
    }

    // Check the last exchange rate without any state changes
    /// @inheritdoc IOracle
    function peek(bytes calldata) public view override returns (bool, uint256) {
        return (true, _get());
    }

    // Check the current spot exchange rate without any state changes
    /// @inheritdoc IOracle
    function peekSpot(bytes calldata data) external view override returns (uint256 rate) {
        (, rate) = peek(data);
    }

    /// @inheritdoc IOracle
    function name(bytes calldata) public view override returns (string memory) {
        return "Chainlink 3Crv";
    }

    /// @inheritdoc IOracle
    function symbol(bytes calldata) public view override returns (string memory) {
        return "LINK/3crv";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";
import "@sushiswap/bentobox-sdk/contracts/IBentoBoxV1.sol";
import "./IOracle.sol";
import "./ISwapper.sol";

interface IKashiPair {
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event LogAccrue(uint256 accruedAmount, uint256 feeFraction, uint64 rate, uint256 utilization);
    event LogAddAsset(address indexed from, address indexed to, uint256 share, uint256 fraction);
    event LogAddCollateral(address indexed from, address indexed to, uint256 share);
    event LogBorrow(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogExchangeRate(uint256 rate);
    event LogFeeTo(address indexed newFeeTo);
    event LogRemoveAsset(address indexed from, address indexed to, uint256 share, uint256 fraction);
    event LogRemoveCollateral(address indexed from, address indexed to, uint256 share);
    event LogRepay(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function accrue() external;

    function accrueInfo()
        external
        view
        returns (
            uint64 interestPerBlock,
            uint64 lastBlockAccrued,
            uint128 feesEarnedFraction
        );

    function addAsset(
        address to,
        bool skim,
        uint256 share
    ) external returns (uint256 fraction);

    function addCollateral(
        address to,
        bool skim,
        uint256 share
    ) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function asset() external view returns (IERC20);

    function balanceOf(address) external view returns (uint256);

    function bentoBox() external view returns (IBentoBoxV1);

    function borrow(address to, uint256 amount) external returns (uint256 part, uint256 share);

    function claimOwnership() external;

    function collateral() external view returns (IERC20);

    function cook(
        uint8[] calldata actions,
        uint256[] calldata values,
        bytes[] calldata datas
    ) external payable returns (uint256 value1, uint256 value2);

    function decimals() external view returns (uint8);

    function exchangeRate() external view returns (uint256);

    function feeTo() external view returns (address);

    function getInitData(
        IERC20 collateral_,
        IERC20 asset_,
        IOracle oracle_,
        bytes calldata oracleData_
    ) external pure returns (bytes memory data);

    function init(bytes calldata data) external payable;

    function isSolvent(address user, bool open) external view returns (bool);

    function liquidate(
        address[] calldata users,
        uint256[] calldata borrowParts,
        address to,
        ISwapper swapper,
        bool open
    ) external;

    function masterContract() external view returns (address);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function removeAsset(address to, uint256 fraction) external returns (uint256 share);

    function removeCollateral(address to, uint256 share) external;

    function repay(
        address to,
        bool skim,
        uint256 part
    ) external returns (uint256 amount);

    function setFeeTo(address newFeeTo) external;

    function setSwapper(ISwapper swapper, bool enable) external;

    function swappers(ISwapper) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalAsset() external view returns (uint128 elastic, uint128 base);

    function totalBorrow() external view returns (uint128 elastic, uint128 base);

    function totalCollateralShare() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function updateExchangeRate() external returns (bool updated, uint256 rate);

    function userBorrowPart(address) external view returns (uint256);

    function userCollateralShare(address) external view returns (uint256);

    function withdrawFees() external;
}