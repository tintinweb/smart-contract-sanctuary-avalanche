// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

import "./Baked.sol";
import "./interfaces/IBotFactory.sol";
import "./interfaces/IBotPool.sol";
import "./interfaces/IBotTrader.sol";
import "./interfaces/IERC20T.sol";

contract BotController is Baked {

    IERC20T public immutable TC;

    IBotFactory public BotFactory;

    uint public constant initTime = 388800; // monday, 12pm GMT/UTC
    uint public constant secPerWeek = 604800;
    uint public constant secPerYear = 31536000;
    uint public constant maxSingleLoopSize = 1500;

    uint public immutable normalizedTC;

    uint public profitFee = 10;
    uint public maxWeeklyProfitFeeIncrease = 5;
    uint public lastProfitFeeIncrease = block.timestamp;

    uint public TCUpkeep = 100;
    uint public normalizedTCUpkeep;
    uint public lastUpkeepIncrease = block.timestamp;

    address[] public contracts;

    uint public numEditors;
    mapping(address => uint) public editorIDs;
    mapping(uint => bool) public isEditor;

    uint public constant numSignableFunctions = 3;
    uint[numSignableFunctions] public numSigs_Array;
    mapping(uint => mapping(uint => bool)) public sigs_Mapping;

    uint public constant arrayID_registerBotPoolContract = 0;
    uint public constant arrayID_removeBotPoolContract = 1;
    uint public constant arrayID_setMinWeeksTCDeposit = 2;

    constructor(address[] memory _tokens) {
        originWallet = msg.sender;

        TC = IERC20T(_tokens[1]);

        normalizedTC = 10 ** TC.decimals();
    }




    // ### VERIFICATION FUNCTIONS ###
    modifier _originOnly() override {
        require(msg.sender == originWallet, "BOT CONTROLLER | AUTH ERROR: Sender is not the Origin Wallet.");
        _;
    }

    modifier _editorLevelAuth() {
        require(
            isEditor[editorIDs[msg.sender]] || msg.sender == originWallet,
            "BOT CONTROLLER | AUTH ERROR: Sender is not an editor or the Origin Wallet."
        );
        _;
    }




    // ### EDITOR FUNCTIONS ###
    function addEditor(address _editor) _originOnly external {
        if (isEditor[editorIDs[_editor]]) {
            return;
        }

        // so we start at index 1
        numEditors++;

        editorIDs[_editor] = numEditors;
        isEditor[numEditors] = true;
    }

    function removeEditor(address _editor) _originOnly external {
        uint editorID = editorIDs[_editor];
        isEditor[editorID] = false;

        for (uint i = 0; i < numSigs_Array.length; i++) {
            _unsignTX(i, editorID);
        }
    }

    function _signTX(uint arrayID, uint editorID) private {
        if (sigs_Mapping[arrayID][editorID]) {
            return;
        }

        numSigs_Array[arrayID]++;
        sigs_Mapping[arrayID][editorID] = true;
    }

    function _unsignTX(uint arrayID, uint editorID) private {
        if (!sigs_Mapping[arrayID][editorID]) {
            return;
        }

        numSigs_Array[arrayID]--;
        sigs_Mapping[arrayID][editorID] = false;
    }

    function _checkRunFunction(uint arrayID, uint editorID, bool isSigningTX) private returns (bool) {
        if (isSigningTX) {
            _signTX(arrayID, editorID);
        }
        else {
            _unsignTX(arrayID, editorID);
        }

        if (numSigs_Array[arrayID] >= (numEditors + 1) / 2) {
            for (uint i = 1; i <= numEditors; i++) {
                sigs_Mapping[arrayID][i] = false;
            }

            numSigs_Array[arrayID] = 0;
            return true;
        }
        else {
            return false;
        }
    }




    // ### GET FUNCTIONS ###
    function getIsEditor(address editor) external view returns (bool _isEditor) {
        return isEditor[editorIDs[editor]];
    }

    function getContracts() external view returns (address[] memory _contracts) {
        return contracts;
    }




    // ### SET FUNCTIONS ###
    function registerBotPoolContract(address BotPoolContract, bool isSigningTX) external _editorLevelAuth {
        uint arrayID = arrayID_registerBotPoolContract;
        uint editorID = editorIDs[msg.sender];

        if (isEditor[editorID] && !_checkRunFunction(arrayID, editorID, isSigningTX)) {
            return;
        }

        contracts.push(BotPoolContract);
    }

    function removeBotPoolContract(uint BotPoolID, bool isSigningTX) external _editorLevelAuth {
        uint arrayID = arrayID_removeBotPoolContract;
        uint editorID = editorIDs[msg.sender];

        if (isEditor[editorID] && !_checkRunFunction(arrayID, editorID, isSigningTX)) {
            return;
        }

        contracts[BotPoolID] = contracts[contracts.length - 1];
        contracts.pop();
    }

    function setAPR(uint _APR, uint _APR_botBonus) external _originOnly {
        for (uint i = 0; i < contracts.length; i++) {
            IBotPool BotPool = IBotPool(contracts[i]);
            BotPool.setAPR(_APR, _APR_botBonus);
        }
    }

    function setUpkeepReductions(uint[] memory _upkeepReductions) external _originOnly {
        for (uint i = 0; i < _upkeepReductions.length; i++) {
            require(_upkeepReductions[i] <= 100, "BOT CONTROLLER | UPKEEP ERROR: Cannot set an NFT level's upkeep reductions >100.");
        }

        for (uint i = 0; i < contracts.length; i++) {
            IBotPool BotPool = IBotPool(contracts[i]);
            BotPool.setUpkeepReductions(_upkeepReductions);
        }
    }

    function setTCUpkeep(uint _TCUpkeep) external _originOnly {
        require(block.timestamp - lastUpkeepIncrease >= secPerWeek, "BOT POOL | UPKEEP ERROR: Cannot change weekly upkeep more than once per week.");
        uint _normalizedTCUpkeep = _TCUpkeep * normalizedTC;
        // + 19 ensures it rounds up
        require(
            _normalizedTCUpkeep <= normalizedTCUpkeep + uint((normalizedTCUpkeep + 19) / 20),
            "BOT POOL | UPKEEP ERROR: Cannot increase weekly upkeep by more than 5%."
        );
        require(_normalizedTCUpkeep >= normalizedTC, "BOT POOL | UPKEEP ERROR: Cannot decrease weekly upkeep below 1 TC.");

        for (uint i = 0; i < contracts.length; i++) {
            IBotPool BotPool = IBotPool(contracts[i]);
            BotPool.setTCUpkeep(_TCUpkeep);
        }
    }

    function setMinWeeksTCDeposit(uint8 _minWeeksTCDeposit, bool isSigningTX) external _editorLevelAuth {
        uint arrayID = arrayID_setMinWeeksTCDeposit;
        uint editorID = editorIDs[msg.sender];

        if (isEditor[editorID] && !_checkRunFunction(arrayID, editorID, isSigningTX)) {
            return;
        }

        for (uint i = 0; i < contracts.length; i++) {
            IBotPool BotPool = IBotPool(contracts[i]);
            BotPool.setMinWeeksTCDeposit(_minWeeksTCDeposit);
        }
    }

    function setProfitFee(uint _profitFee) external _originOnly {
        require(block.timestamp - lastProfitFeeIncrease >= secPerWeek,
            "BOT POOL | NET-PROFIT ERROR: Cannot change net-profit fee more than once per week."
        );
        require(_profitFee <= profitFee + maxWeeklyProfitFeeIncrease,
            "BOT POOL | NET-PROFIT ERROR: Cannot increase net-profit fee by more than 5% in a week."
        );
        require(_profitFee <= 35, "BOT POOL | NET-PROFIT ERROR: Cannot increase net-profit fee above 35%.");

        for (uint i = 0; i < contracts.length; i++) {
            IBotPool BotPool = IBotPool(contracts[i]);
            BotPool.setProfitFee(_profitFee);
        }
    }

    function setBotFactory(address _BotFactory) external _originOnly {
        require(address(BotFactory) == address(0), "BOT CONTROLLER | BOT FACTORY ERROR: The Bot Factory has already been set.");

        for (uint i = 0; i < contracts.length; i++) {
            IBotPool BotPool = IBotPool(contracts[i]);
            BotPool.setBotFactory(_BotFactory);
        }
    }

    // TODO: make it so editor multisig can set BotPools individually?
    function setMinReqCashbal(uint _minReqCashbal) external _originOnly {
        for (uint i = 0; i < contracts.length; i++) {
            IBotPool BotPool = IBotPool(contracts[i]);
            BotPool.setMinReqCashbal(_minReqCashbal);
        }
    }

    function setBotPoolMaxCash(uint _BotPoolMaxCash) external _originOnly {
        for (uint i = 0; i < contracts.length; i++) {
            IBotPool BotPool = IBotPool(contracts[i]);
            BotPool.setBotPoolMaxCash(_BotPoolMaxCash);
        }
    }

    function setPerUserMaxCash(uint _perUserMaxCash) external _originOnly {
        for (uint i = 0; i < contracts.length; i++) {
            IBotPool BotPool = IBotPool(contracts[i]);
            BotPool.setPerUserMaxCash(_perUserMaxCash);
        }
    }

    function setSlippagePercentage(uint numerator, uint denominator) external _originOnly {
        require(numerator / denominator <= 1, "BOT POOL | CALC ERROR: Cannot set slippage percentage above 100%.");

        for (uint i = 0; i < contracts.length; i++) {
            IBotPool BotPool = IBotPool(contracts[i]);
            BotPool.setSlippagePercentage(numerator, denominator);
        }
    }

    function setReservePercentage(uint numerator, uint denominator) external _originOnly {
        require(numerator / denominator <= 1, "BOT POOL | CALC ERROR: Cannot set reserve percentage above 100%.");

        for (uint i = 0; i < contracts.length; i++) {
            IBotPool BotPool = IBotPool(contracts[i]);
            BotPool.setReservePercentage(numerator, denominator);
        }
    }

    function setBorrowPercentage(uint numerator, uint denominator) external _originOnly {
        require(numerator / denominator <= 1, "BOT POOL | CALC ERROR: Cannot set borrow percentage above 100%.");

        for (uint i = 0; i < contracts.length; i++) {
            IBotPool BotPool = IBotPool(contracts[i]);
            BotPool.setBorrowPercentage(numerator, denominator);
        }
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

abstract contract Baked {

    address public originWallet;
    bool public contractIsFrozen;

    modifier _originOnly() virtual {
        require(msg.sender == originWallet, "AUTH ERROR: Sender is not Origin Wallet.");
        _;
    }

    // -> `originWallet` only
    //    Set the `originWallet`.
    //    Known in other smart contracts as the "Owner."
    function setOriginWallet(address newOrigin) external virtual _originOnly {
        originWallet = newOrigin;
    }

    /* -> `originWallet` only
        If `contractIsFrozen` is set to false, all transfers are permitted.
        If `contractIsFrozen` is set to true, prevents all transfers except:
        • Users            -> `treasuryWallet`
        • `treasuryWallet` -> new `treasuryWallet`
        • `originWallet`   -> new `originWallet`

        Why?
        In the case of a hack or desire to migrate, the `originWallet` may
        want to ensure the security of all User tokens and consider potential
        mitigation solutions. In particular the `migrate()` function is explicitly
        permitted even when the `contractIsFrozen`. Despite all our best efforts,
        there will alway exist a non-zero possibility of an exploit being found.
        Having a mitigation strategy in place – such as secure and migrate – is wise.
    */
    function setContractIsFrozen(bool newContractIsFrozen) external _originOnly {
        _setContractIsFrozen(newContractIsFrozen);
    }

    function _setContractIsFrozen(bool newContractIsFrozen) internal {
        contractIsFrozen = newContractIsFrozen;
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

interface IBotFactory {

    function makeNewBotTrader(address[] memory _tokens, address[] memory _coreContracts) external returns (address BotTrader);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "../libraries/GetUser.sol";

interface IBotPool {

    event WeeklyFeeDone(uint256 amount);

    function BotPoolCashBalance() external view returns (uint256);

    function BotPoolMaxCash() external view returns (uint256);

    function BotPoolSetter() external view returns (address);

    function NFTadmin() external view returns (address);

    function TC() external view returns (address);

    function TCC() external view returns (address);

    function TCToAdd() external view returns (uint256);

    function addBotPoolCashBalance(uint256 amountCash) external;

    function asset() external view returns (address);

    function assetSymbol() external view returns (string memory);

    function balanceTC(uint256) external view returns (uint256);

    function balanceTCC(uint256) external view returns (uint256);

    function borrowPercentage() external view returns (uint256);

    function cancelPendingTransfers() external returns (bool success);

    function cash() external view returns (address);

    function cashSymbol() external view returns (string memory);

    function contractIsFrozen() external view returns (bool);

    function contracts(uint256) external view returns (address);

    function convertToAsset(address account, uint256 amountCash)
        external
        view
        returns (uint256 amountAsset);

    function convertToDebt(address account, uint256 amountCash)
        external
        view
        returns (uint256 amountDebt);

    function coreContracts(uint256) external view returns (address);

    function deposit(uint256 amountCash, uint256 amountTC)
        external
        returns (bool success);
    
    function dexFeePercentage() external view returns (uint256);

    function editorLevel(address sender) external view returns (bool);

    function emergencyWithdrawAll() external;

    function getAAVEUserData(address account)
        external
        view
        returns (uint256[6] memory userData);

    function getAssetPrice(address account)
        external
        view
        returns (uint256 assetPrice);

    function getContracts() external view returns (address[] memory _contracts);

    function getCurrentAssetBalance(address account)
        external
        view
        returns (uint256 assetBalance);

    function getLastCashBalance(address account)
        external
        view
        returns (uint256 lastCashBalance);

    function getParameters()
        external
        view
        returns (uint256[3] memory _parameters);

    function getSimulatedCashBalance(address account)
        external
        view
        returns (uint256 balance);

    function getTotalBalance() external view returns (uint256 totalBalance);

    function getTotalDebt() external view returns (uint256 totalDebt);

    function getTradeStatus(address account)
        external
        view
        returns (int256 tradeStatus);

    function getUser(address account)
        external
        view
        returns (GetUser.User memory user);
    
    function immediateWithdrawalPenaltyPct() external view returns (uint256);

    function inContract(uint256) external view returns (address);

    function isBotTraderContract(address) external view returns (bool);

    function isRegistered(uint256) external view returns (bool);

    function lastContractCharged() external view returns (uint256);

    function lastTimeCharged(uint256) external view returns (uint256);

    function lastTimeInterest(uint256) external view returns (uint256);

    function lastUserCharged() external view returns (uint256);

    function maxSingleLoopSize() external view returns (uint256);

    function minDepositCash() external view returns (uint256);

    function nextContract() external view returns (address);

    function normalizedCash() external view returns (uint256);

    function notes() external view returns (string memory);

    function numContracts() external view returns (uint256);

    function numUsers() external view returns (uint256);

    function originLevel(address sender) external view returns (bool);

    function perUserMaxCash() external view returns (uint256);

    function profitFee() external view returns (uint256);

    function repayAllLoans(uint256 amountCash) external returns (bool success);

    function reservePercentage() external view returns (uint256);

    function rewardTCC() external returns (bool success);

    function setAPR(uint _APR, uint _APR_botBonus) external;

    function setBorrowPercentage(uint numerator, uint denominator) external;

    function setBotFactory(address _BotFactory) external;

    function setBotPoolMaxCash(uint256 _maxCash) external;

    function setContractIsFrozen(bool newContractIsFrozen)
        external
        returns (bool success);
    
    function setMinReqCashbal(uint _minReqCashbal) external;
    
    function setMinWeeksTCDeposit(uint8 _minWeeksTCDeposit) external;

    function setNotes(string memory _notes) external;

    function setOrigin(address newOrigin) external returns (bool success);

    function setPerUserMaxCash(uint256 _perUserMaxCash) external;

    function setProfitFee(uint _profitFee) external;

    function setReservePercentage(uint numerator, uint denominator) external;

    function setSlippagePercentage(uint numerator, uint denominator) external;

    function setStrategyInfo(string memory _tf, string memory _stratName)
        external;
    
    function setTCUpkeep(uint _TCUpkeep) external;

    function setUpkeepReductions(uint[] memory _upkeepReductions) external;

    function setWeeklyFeeWallet(address _weeklyFeeWallet) external;

    function slippagePercentage() external view returns (uint256);

    function strategyName() external view returns (string memory);

    function subBotPoolCashBalance(uint256 amountCash) external;

    function timeframe() external view returns (string memory);

    function tokens(uint256) external view returns (address);

    function transferCashFrom(
        address from,
        address to,
        uint256 amountCash
    ) external;

    function userAddress(uint256) external view returns (address);

    function userIDs(address) external view returns (uint256);

    function weeklyFee(bytes memory swapCallData) external returns (bool done);

    function weeklyFeeLevel(address sender) external view returns (bool);

    function weeklyFeeWallet() external view returns (address);

    function withdraw(
        uint256 amountCash,
        uint256 amountTC,
        bool immediately,
        bytes memory swapCallData
    ) external returns (bool success);

    function withdrawAll(
        bool onlyCash,
        bool immediately,
        bytes memory swapCallData
    ) external returns (bool success);

    function withdrawAllTokens(address account) external;

    function getUserWeeklyUpkeep(address account) external view returns (uint);

    function getUserMinReqTCbal(address account) external view returns (uint);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

interface IBotTrader {

    function tradeStatus() external view returns (int tradeStatus);
    function isRepayingLoan() external view returns (bool tradeStatus);
    function lastCashBalance() external view returns (uint lastCashBalance);
    function getSimulatedCashBalance() external view returns (uint cashBalance);
    function getCurrentAssetBalance() external view returns (uint assetBalance);
    function getAAVEUserData() external view returns (uint[6] memory userData);
    function getAssetPrice() external view returns (uint assetPrice);

    function pendingWithdrawAllOf(address account) external view returns (bool _pendingWithdrawAll);
    function pendingWithdrawalOf(address account) external view returns (uint _pendingWithdrawal);
    function pendingDepositOf(address account) external view returns (uint _pendingDeposit);
    function depositedOf(address account) external view returns (uint _depositedCash);
    function balanceCashOf(address account) external view returns (uint _balanceCash);
    function simulatedBalanceCashOf(address account) external view returns (uint _simulatedBalanceCash);
    function balanceTradeStartOf(address account) external view returns (uint _balanceTradeStart);
    function totalChangeOf(address account) external view returns (int _totalChange);
    function convertToAsset(uint amountCash) external view returns (uint _amountAsset);
    function convertToDebt(uint amountCash) external view returns (uint _amountDebt);

    function deposit(address account, uint amountCash) external;
    function addUser(address account) external;
    function withdraw(address account, uint amountCash, bytes calldata swapCallData) external;
    function makePendingWithdrawal(address account, uint amountCash) external;
    function withdrawAll(address account, bytes calldata swapCallData) external;
    function makePendingWithdrawAll(address account, bool onlyCash) external;
    function emergencyWithdrawAllLoop(bool alsoFromBotPool) external;
    function emergencyWithdrawAll(address account) external;
    function cancelPendingTransfers(address account) external;

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

import "./IERC20.sol";

// NOTE: not all IERC20 tokens have these functions
interface IERC20T is IERC20 {

    function treasuryWallet() external returns (address);

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "../interfaces/IBotPool.sol";
import "../interfaces/IBotTrader.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/INFTadmin.sol";

library GetUser {

    // only used for frontend
    struct User {
        address userAddress;        // wallet address of the user
        uint simulatedBalanceCash;  // current cash balance – estimated if the Bot is in a trade
        uint balanceTC;             // current TC balance
        uint balanceTCC;            // current TCC rewards balance
        uint depositedCash;         // total cash deposited – amount withdrawable without a fee
        int totalChange;            // difference in user's cash balance from trade start to present time
        uint balanceCash;           // cash balance at trade start (is this truly true?)
        uint balanceTradeStart;     // cash balance at trade start
        uint nftLevel;              // level of user's NFT 0-4
        uint personalWeeklyUpkeep;  // amount of TC a user needs to pay this week
        uint minimumReqCashBalance; // default is 10 for all users
        uint minimumReqTCBalance;   // 2x User Weekly Upkeep
        uint maxWithdrawTC;         // TC balance less 2x user Weekly Upkeep
        uint maxWithdrawCash;       // cash balance less minimum (currently 10)
        uint lastTimeCharged;       // most recent time user was charged TC upkeep
        uint lastTimeInterest;      // most recent time user received their last TCC rewards
        uint pendingDeposit;        // amount user is requesting to deposit upon trade exit
        uint pendingWithdrawal;     // amount user is requesting to withdraw upon trade exit
        bool pendingWithdrawAll;    // is the user requesting to withdraw all funds upon trade exit?
        uint allowanceCash;         // amount user has permitted this BotPool contract to TransferFrom() – cash
        uint allowanceTC;           // amount user has permitted this BotPool contract to TransferFrom() – TC
        address inContract;         // user is assigned to the given BotTrader contract address
        bool isRegistered;          // user has ever deposited into this BotPool contract
    }

    function getUser(address account) external view returns (User memory user) {
        IBotPool BotPool = IBotPool(msg.sender);

        IERC20 cash = IERC20(BotPool.cash());
        IERC20 TC = IERC20(BotPool.TC());

        INFTadmin NFTadmin = INFTadmin(BotPool.NFTadmin());

        uint userID = BotPool.userIDs(account);

        User memory _user = User(
            BotPool.userAddress(userID),
            0,
            BotPool.balanceTC(userID),
            BotPool.balanceTCC(userID),
            0,
            0,
            0,
            0,
            NFTadmin.getUserLevel(account),
            BotPool.getUserWeeklyUpkeep(account),
            BotPool.minDepositCash() * BotPool.normalizedCash(),
            BotPool.getUserMinReqTCbal(account),
            0,
            0,
            BotPool.lastTimeCharged(userID),
            BotPool.lastTimeInterest(userID),
            0,
            0,
            false,
            cash.allowance(account, address(this)),
            TC.allowance(account, address(this)),
            BotPool.inContract(userID),
            BotPool.isRegistered(userID)
        );

        if (BotPool.isRegistered(userID)) {
            IBotTrader BotTrader = IBotTrader(_user.inContract);

            _user.simulatedBalanceCash = BotTrader.simulatedBalanceCashOf(account);
            _user.depositedCash = BotTrader.depositedOf(account);
            _user.totalChange = BotTrader.totalChangeOf(account);
            _user.balanceCash = BotTrader.balanceCashOf(account);
            _user.balanceTradeStart = BotTrader.balanceTradeStartOf(account);
            _user.maxWithdrawTC = _user.balanceTC >=  _user.minimumReqTCBalance ? _user.balanceTC -  _user.minimumReqTCBalance : 0;
            _user.maxWithdrawCash = _user.balanceCash >= _user.minimumReqCashBalance ? _user.balanceCash - _user.minimumReqCashBalance : 0;
            _user.pendingDeposit = BotTrader.pendingDepositOf(account);
            _user.pendingWithdrawal = BotTrader.pendingWithdrawalOf(account);
            _user.pendingWithdrawAll = BotTrader.pendingWithdrawAllOf(account);
        }

        return _user;
    }

}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

interface IERC20 {

    function name() external returns (string memory name);
    function symbol() external returns (string memory symbol);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.14;

interface INFTadmin {

    function originWallet() external view returns (address originWallet);
    function nftLevels() external view returns (uint8);

    function getUserLevel(address account) external view returns (uint8);

    function addUser(address account) external;
    function updateUserLevel(address _from, address _to) external;

}