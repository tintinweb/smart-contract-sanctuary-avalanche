//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./interfaces/IERC20Extended.sol";
import "./interfaces/IERC4626.sol";
import "./interfaces/IMembersPool.sol";

// ERC1404

//todo add SafeERC20
//todo add events

contract MembersPool is IMembersPool, ERC20, IERC4626 {
    string public constant RECEIPT_TOKEN_NAME = "Cover Member Pool (receipt)";
    string public constant RECEIPT_TOKEN_SYMBOL = "rCMP";
    uint16 public constant DEPOSIT_FEE_DENOMINATOR = 10000;
    uint16 internal constant _LOCK_PERCENT_PRECISION = 1000;

    uint256 public globalWithdrawTimelock;
    uint256 public withdrawWaitingPeriod;
    uint16 public initialLockPercent;
    uint16 public depositFeeNominator;
    uint256 public totalQSRPDebt;
    uint256 public totalAssetsInQSRP;

    address public treasury;
    address private _asset;
    uint256 private _maxDeposit;

    mapping(address => mapping(uint256 => DepositInfo)) public depositInfos;
    mapping(address => WithdrawRequest) public withdrawRequests;
    mapping(address => EmergencyWithdrawRequest) public emergencyWithdrawRequests;
    mapping(address => uint256) public lastDepositIndex;
    mapping(address => bool) private _registeredQSRPs;
    mapping(address => uint256) private _qsrpDebts;
    mapping(address => uint256) private _qsrpBalances;
    mapping(address => uint256) private _userDeposits;

    constructor(
        address asset_,
        address _treasury,
        uint16 _depositFeeNominator,
        uint256 _globalWithdrawTimelock,
        uint256 _withdrawWaitingPeriod,
        uint16 _initialLockPercent,
        uint256 maxDeposit_
    ) ERC20(RECEIPT_TOKEN_NAME, RECEIPT_TOKEN_SYMBOL) {
        _asset = asset_;
        treasury = _treasury;
        depositFeeNominator = _depositFeeNominator;
        globalWithdrawTimelock = _globalWithdrawTimelock;
        withdrawWaitingPeriod = _withdrawWaitingPeriod;
        initialLockPercent = _initialLockPercent;
        _maxDeposit = maxDeposit_;
    }

    // *************** ERRORS ***************************

    error NoActiveWithdrawRequests();
    error WithdrawLockIsActive();
    error NotEnoughSharesToWithdraw();
    error InsufficientFundsInPool();
    error MaxDepositExceeded();
    error UnknownQSRP();
    error RequestedAmountIsBiggerAvailableToWithdraw();

    // *************** INVESTOR ACTIONS ***************************

    function deposit(uint256 assets, address receiver) external override returns (uint256 shares) {
        return _deposit(assets, receiver);
    }

    function mint(uint256 shares, address receiver) external override returns (uint256 assets) {
        uint256 _assets = _previewMint(shares);
        assets = _convertToAssets(_deposit(_assets, receiver));
    }

    function scheduleRedeem(uint256 shares) external override {
        _scheduleRedeem(shares);
    }

    function scheduleWithdraw(uint256 assets) external override {
        _scheduleRedeem(_previewWithdraw(assets));
    }

    //todo reentrancy protect
    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external override returns (uint256 assets) {
        assets = _redeem(shares, receiver, owner);
    }

    //todo reentrancy protect
    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external override returns (uint256 shares) {
        uint256 sharesToBurn = _previewWithdraw(assets);
        return _convertToShares(_redeem(sharesToBurn, receiver, owner));
    }

    function scheduleEmergencyWithdraw(uint256[] memory depositIds) external override {
        uint256 totalWithdrawShares = 0;
        uint256 totalWithdrawPenaltyShares = 0;
        uint256 i = 0;
        WithdrawInfo[] memory wInfos = _getWithdrawInfo(msg.sender, depositIds);

        for (i; i < wInfos.length; i++) {
            totalWithdrawShares += wInfos[i].availableToWithdrawShares;
            totalWithdrawPenaltyShares += wInfos[i].withdrawPenaltyShares;
        }

        emergencyWithdrawRequests[msg.sender] = EmergencyWithdrawRequest(
            totalWithdrawShares,
            totalWithdrawPenaltyShares,
            block.timestamp,
            block.timestamp + withdrawWaitingPeriod,
            depositIds
        );
    }

    function emergencyWithdraw() external override {
        EmergencyWithdrawRequest memory ewr = emergencyWithdrawRequests[msg.sender];

        if (ewr.createdTimestamp == 0) {
            revert NoActiveWithdrawRequests();
        }

        if (ewr.lockedUntilTimestamp >= block.timestamp) {
            revert WithdrawLockIsActive();
        }

        if (balanceOf(msg.sender) < ewr.withdrawShares + ewr.withdrawPenaltyShares) {
            revert NotEnoughSharesToWithdraw();
        }

        uint256 sharesToBurn = ewr.withdrawShares;
        uint256 sharesToTreasury = ewr.withdrawPenaltyShares;
        uint256 assets = _previewRedeem(sharesToBurn);

        _checkAvailableFunds(assets);

        _burn(msg.sender, sharesToBurn);

        ERC20(_asset).transfer(msg.sender, assets);

        _spendAllowance(msg.sender, address(this), sharesToTreasury);
        _transfer(msg.sender, treasury, sharesToTreasury);
        _updateEmergencyDepositInfos(msg.sender, ewr.depositIds);
        delete emergencyWithdrawRequests[msg.sender];
        // todo add events (burn?, withdraw)
    }

    // *************** MANAGER ACTIONS ***************************

    function updateInvestmentBalance(
        address qsrp,
        uint256 newBalance,
        uint256 realEventTime
    ) external override {
        _checkRegisteredQSRP(qsrp);
        uint256 currentQSRPBalance = _qsrpBalances[qsrp];

        _qsrpBalances[qsrp] = newBalance;
        if (totalAssetsInQSRP + newBalance >= currentQSRPBalance) {
            totalAssetsInQSRP = totalAssetsInQSRP + newBalance - currentQSRPBalance;
        } else {
            // todo need to think if it could be a problem (100 dep and reported -100)
            totalAssetsInQSRP = 0;
        }
    }

    function withdrawInvestmentToQSRP(address qsrp, uint256 amount) external override {
        _checkRegisteredQSRP(qsrp);
        _checkAvailableFunds(amount);
        //todo QSRP capacity check.
        _qsrpDebts[qsrp] += amount;
        _qsrpBalances[qsrp] += amount;
        totalQSRPDebt += amount;
        totalAssetsInQSRP += amount;
        ERC20(_asset).transfer(qsrp, amount);
        //todo add more events
        emit InvestmentWithdrawnToQSRP(msg.sender, qsrp, amount);
    }

    function returnInvestment(address qsrp, uint256 amount) external override {
        _qsrpDebts[qsrp] = _qsrpDebts[qsrp] >= amount ? _qsrpDebts[qsrp] - amount : 0;
        _qsrpBalances[qsrp] = _qsrpBalances[qsrp] >= amount ? _qsrpBalances[qsrp] - amount : 0;
        totalQSRPDebt = totalQSRPDebt >= amount ? totalQSRPDebt - amount : 0;
        totalAssetsInQSRP = totalAssetsInQSRP >= amount ? totalAssetsInQSRP - amount : 0;
        ERC20(_asset).transferFrom(msg.sender, address(this), amount);
        //todo add more events
    }

    // *************** QSRP related actions ***************************
    function registerQSRP(address qsrp, bool status) external override {
        _registeredQSRPs[qsrp] = status;
        emit QSRPRegistrationUpdated(qsrp, status);
    }

    function isQSRPRegistered(address qsrp) external view override returns (bool) {
        return _registeredQSRPs[qsrp];
    }

    // *************** Admin actions ***************************
    function updateWithdrawFee(uint256 newFee) external override {}

    function updateTreasuryAddress(address newTreasuryAddress) external override {
        treasury = newTreasuryAddress;
    }

    function updateDepositFeeNominator(uint16 _depositFeeNominator) external override {
        depositFeeNominator = _depositFeeNominator;
    }

    function updateInvestmentAllowance(bool isInvestmentAllowed) external override {}

    function updateWithdrawWaitingPeriod(uint256 _withdrawWaitingPeriod) external override {
        withdrawWaitingPeriod = _withdrawWaitingPeriod;
    }

    function updateInitialLockPercent(uint16 _initialLockPercent) external override {
        initialLockPercent = _initialLockPercent;
    }

    function updateGlobalWithdrawTimelock(uint256 globalTimelock) external override {
        globalWithdrawTimelock = globalTimelock;
    }

    function updateMaxDeposit(uint256 maxDeposit_) external override {
        _maxDeposit = maxDeposit_;
    }

    // *************** Internal ***************************

    function _deposit(uint256 assets, address receiver) internal returns (uint256 sharesToMint) {
        if (_userDeposits[receiver] > _maxDeposit) {
            revert MaxDepositExceeded();
        }
        _userDeposits[receiver] += assets;

        sharesToMint = _previewDeposit(assets);
        if (sharesToMint != 0) {
            uint256 depositFee = (assets * depositFeeNominator) / DEPOSIT_FEE_DENOMINATOR;
            _mint(receiver, sharesToMint);
            ERC20(_asset).transferFrom(msg.sender, address(this), assets - depositFee);
            ERC20(_asset).transferFrom(msg.sender, treasury, depositFee);

            lastDepositIndex[receiver] += 1;
            depositInfos[receiver][lastDepositIndex[receiver]] = DepositInfo(
                assets,
                sharesToMint,
                0,
                block.timestamp,
                block.timestamp + globalWithdrawTimelock,
                initialLockPercent,
                false
            );

            emit Deposit(msg.sender, assets, block.timestamp + globalWithdrawTimelock);
            emit DepositFeeCollected(treasury, depositFee);
            emit TokensMinted(receiver, sharesToMint);
        }
    }

    function _previewDeposit(uint256 assets) internal view returns (uint256 sharesToMint) {
        sharesToMint = _convertToShares(assets);
        sharesToMint = (sharesToMint * (DEPOSIT_FEE_DENOMINATOR - depositFeeNominator)) / DEPOSIT_FEE_DENOMINATOR;
    }

    function _previewMint(uint256 shares) internal view returns (uint256 assetsToDeposit) {
        assetsToDeposit = _convertToAssets(shares);
        uint256 depositFee = (assetsToDeposit * depositFeeNominator) / DEPOSIT_FEE_DENOMINATOR;
        assetsToDeposit += depositFee;
    }

    function _previewWithdraw(uint256 assets) internal view returns (uint256 shares) {
        shares = _convertToShares(assets);
    }

    function _previewRedeem(uint256 shares) internal view returns (uint256 assets) {
        assets = _convertToAssets(shares);
    }

    function _convertToShares(uint256 assets) internal view returns (uint256 shares) {
        shares = totalSupply() == 0 ? assets : (assets * totalSupply()) / _totalAssets();
    }

    function _convertToAssets(uint256 shares) internal view returns (uint256 assets) {
        assets = totalSupply() == 0 ? shares : (shares * _totalAssets()) / totalSupply();
    }

    function _checkRegisteredQSRP(address qsrp) internal view {
        if (!_registeredQSRPs[qsrp]) {
            revert UnknownQSRP();
        }
    }

    function _checkAvailableFunds(uint256 amount) internal view {
        if (amount > ERC20(_asset).balanceOf(address(this))) {
            revert InsufficientFundsInPool();
        }
    }

    function _totalAssets() internal view returns (uint256) {
        return totalAssetsInQSRP + ERC20(_asset).balanceOf(address(this));
    }

    function _assetsUnit() internal view returns (uint256) {
        return 10**uint256(IERC20Extended(address(_asset)).decimals());
    }

    function _getPricePerFullShare() internal view returns (uint256) {
        return totalSupply() == 0 ? _assetsUnit() : (_assetsUnit() * _totalAssets()) / totalSupply();
    }

    function _checkAvailableSharesToWithdraw(address holder, uint256 numberOfShares) internal view {
        if (_getSharesAvailableToWithdraw(holder) < numberOfShares) {
            revert RequestedAmountIsBiggerAvailableToWithdraw();
        }
    }

    function _getSharesAvailableToWithdraw(address holder) internal view returns (uint256) {
        uint256 availableToWithdraw = 0;
        uint256 _lastDepositIndex = lastDepositIndex[holder];
        if (_lastDepositIndex == 0) {
            return availableToWithdraw;
        }
        uint256 i = 1;
        for (i; i <= _lastDepositIndex; i++) {
            DepositInfo memory info = depositInfos[holder][i];
            if (info.lockedUntilTimestamp < block.timestamp && !info.emergencyWithdrawn) {
                availableToWithdraw += info.sharesReceived - info.sharesWithdrawn;
            }
        }
        return availableToWithdraw;
    }

    function _updateDepositInfos(address holder, uint256 numberOfShares) internal {
        uint256 _lastDepositIndex = lastDepositIndex[holder];
        if (_lastDepositIndex == 0) {
            return;
        }
        uint256 i = 1;
        for (i; i <= _lastDepositIndex; i++) {
            DepositInfo storage info = depositInfos[holder][i];

            uint256 availableToWithdraw = info.sharesReceived - info.sharesWithdrawn;
            if (numberOfShares >= availableToWithdraw) {
                numberOfShares = numberOfShares - availableToWithdraw;
                info.sharesWithdrawn += availableToWithdraw;
            } else {
                info.sharesWithdrawn += numberOfShares;
                return;
            }
        }
    }

    function _updateEmergencyDepositInfos(address holder, uint256[] memory depositIds) internal {
        uint256 i = 0;
        for (i; i < depositIds.length; i++) {
            DepositInfo storage info = depositInfos[holder][depositIds[i]];
            info.sharesWithdrawn = info.sharesReceived;
            info.emergencyWithdrawn = true;
        }
    }

    function _getPendingWithdraw(address holder) internal view returns (WithdrawRequest memory) {
        return withdrawRequests[holder];
    }

    function _getPendingEmergencyWithdraw(address holder) internal view returns (EmergencyWithdrawRequest memory) {
        return emergencyWithdrawRequests[holder];
    }

    function _getWithdrawInfo(address investor, uint256[] memory depositIds)
        internal
        view
        returns (WithdrawInfo[] memory)
    {
        //todo need to check case if deposit was partially withdrawn
        WithdrawInfo[] memory result = new WithdrawInfo[](depositIds.length);
        uint256 i = 0;
        for (i; i < depositIds.length; i++) {
            DepositInfo memory dInfo = depositInfos[investor][depositIds[i]];
            if (!dInfo.emergencyWithdrawn) {
                result[i].amountPaid = dInfo.amountPaid;
                result[i].lockedUntilTimestamp = dInfo.lockedUntilTimestamp;
                result[i].createdTimestamp = dInfo.createdTimestamp;
                result[i].sharesReceived = dInfo.sharesReceived;
                result[i].initialLockPercent = dInfo.initialLockPercent;

                uint256 percentPerMillisecond = ((_LOCK_PERCENT_PRECISION - dInfo.initialLockPercent) * _assetsUnit()) /
                    (dInfo.lockedUntilTimestamp - dInfo.createdTimestamp);
                result[i].currentPercent =
                    percentPerMillisecond *
                    (block.timestamp - dInfo.createdTimestamp) +
                    dInfo.initialLockPercent *
                    _assetsUnit();
                result[i].availableToWithdrawShares =
                    (dInfo.sharesReceived * result[i].currentPercent) /
                    _assetsUnit() /
                    _LOCK_PERCENT_PRECISION;
                result[i].withdrawPenaltyShares = dInfo.sharesReceived - result[i].availableToWithdrawShares;
            } else {
                //todo mb we need another attributes?
                result[i].emergencyWithdrawn = true;
            }
        }
        return result;
    }

    function _scheduleRedeem(uint256 shares) internal {
        WithdrawRequest memory wr = withdrawRequests[msg.sender];
        uint256 totalSharesRequested = shares + wr.withdrawShares;
        _checkAvailableSharesToWithdraw(msg.sender, totalSharesRequested);

        if (wr.createdTimestamp == 0) {
            emit WithdrawScheduled(msg.sender, totalSharesRequested, block.timestamp + withdrawWaitingPeriod);
        } else {
            emit WithdrawRequestUpdated(msg.sender, totalSharesRequested, block.timestamp + withdrawWaitingPeriod);
        }

        withdrawRequests[msg.sender] = WithdrawRequest(
            totalSharesRequested,
            block.timestamp,
            block.timestamp + withdrawWaitingPeriod
        );
    }

    function _redeem(
        uint256 shares,
        address receiver,
        address owner
    ) internal returns (uint256 assets) {
        if (msg.sender != owner) {
            _spendAllowance(owner, msg.sender, shares);
        }
        WithdrawRequest memory wr = withdrawRequests[msg.sender];
        if (wr.createdTimestamp == 0) {
            revert NoActiveWithdrawRequests();
        }

        if (wr.lockedUntilTimestamp >= block.timestamp) {
            revert WithdrawLockIsActive();
        }
        assets = _previewRedeem(shares);
        _checkAvailableFunds(assets);
        _burn(msg.sender, shares);
        ERC20(_asset).transfer(receiver, assets);
        _updateDepositInfos(msg.sender, shares);
        delete withdrawRequests[msg.sender];
        //todo add events (burn?, withdraw)
        return assets;
    }

    // *************** Views ***************************

    function maxDeposit(address receiver) external view override returns (uint256) {
        return _maxDeposit - _userDeposits[receiver];
    }

    function maxMint(address receiver) external view override returns (uint256) {
        return _convertToShares(_maxDeposit - _userDeposits[receiver]);
    }

    function assetsUnit() external view override returns (uint256) {
        return _assetsUnit();
    }

    function decimals() public view override returns (uint8) {
        return IERC20Extended(_asset).decimals();
    }

    function asset() external view override returns (address) {
        return _asset;
    }

    function getPricePerFullShare() external view override returns (uint256) {
        return _getPricePerFullShare();
    }

    function assetsInPool() external view override returns (uint256) {
        return ERC20(_asset).balanceOf(address(this));
    }

    function totalAssets() external view override returns (uint256) {
        return _totalAssets();
    }

    function maxRedeem(address owner) external view override returns (uint256) {
        return _getSharesAvailableToWithdraw(owner);
    }

    function maxWithdraw(address owner) external view override returns (uint256) {
        return _convertToAssets(_getSharesAvailableToWithdraw(owner));
    }

    function getPendingWithdraw(address holder) external view override returns (WithdrawRequest memory) {
        return _getPendingWithdraw(holder);
    }

    function getPendingEmergencyWithdraw(address holder)
        external
        view
        override
        returns (EmergencyWithdrawRequest memory)
    {
        return _getPendingEmergencyWithdraw(holder);
    }

    function underlyingBalanceWithInvestmentForHolder(address holder) external view override returns (uint256) {
        if (totalSupply() == 0) {
            return 0;
        }
        return (_totalAssets() * balanceOf(holder)) / totalSupply();
    }

    function getQSRPInfo(address qsrp) external view override returns (uint256 debt, uint256 balance) {
        return (_qsrpDebts[qsrp], _qsrpBalances[qsrp]);
    }

    function getWithdrawInfo(address investor, uint256[] memory depositIds)
        external
        view
        override
        returns (WithdrawInfo[] memory)
    {
        return _getWithdrawInfo(investor, depositIds);
    }

    function previewDeposit(uint256 assets) external view override returns (uint256) {
        return _previewDeposit(assets);
    }

    function previewMint(uint256 shares) external view override returns (uint256) {
        return _previewMint(shares);
    }

    function previewWithdraw(uint256 assets) external view override returns (uint256) {
        return _previewWithdraw(assets);
    }

    function previewRedeem(uint256 shares) external view override returns (uint256) {
        return _previewRedeem(shares);
    }

    function convertToShares(uint256 assets) external view override returns (uint256) {
        return _convertToShares(assets);
    }

    function convertToAssets(uint256 shares) external view override returns (uint256) {
        return _convertToAssets(shares);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20Extended {
  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function decimals() external view returns (uint8);


  /**
    * @dev Returns the amount of tokens in existence.
    */
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
  function transferFrom(
    address sender,
    address recipient,
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

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IERC4626 {
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);

    function mint(uint256 shares, address receiver) external returns (uint256 assets);

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) external returns (uint256 assets);

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) external returns (uint256 shares);

    function maxDeposit(address receiver) external view returns (uint256);

    function maxMint(address receiver) external view returns (uint256);

    function maxWithdraw(address owner) external view returns (uint256);

    function maxRedeem(address owner) external view returns (uint256);

    function asset() external view returns (address);

    function totalAssets() external view returns (uint256);

    function convertToShares(uint256 assets) external view returns (uint256);

    function convertToAssets(uint256 shares) external view returns (uint256);

    function previewDeposit(uint256 assets) external view returns (uint256);

    function previewMint(uint256 shares) external view returns (uint256);

    function previewWithdraw(uint256 assets) external view returns (uint256);

    function previewRedeem(uint256 shares) external view returns (uint256);
}

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

interface IMembersPool{

    // *************** EVENTS ***************************
    event Deposit(address indexed beneficiary, uint256 amount, uint256 unlockedAt);
    event DepositFeeCollected(address indexed treasury, uint256 amount);
    event TokensMinted(address indexed beneficiary, uint256 amount);
    event WithdrawScheduled(address indexed beneficiary, uint256 numberOfShares, uint256 unlockedAt);
    event WithdrawRequestUpdated(address indexed beneficiary, uint256 numberOfShares, uint256 unlockedAt);
    event Withdraw(address indexed beneficiary, uint256 numberOfShares);
    event InvestmentWithdrawnToQSRP(address indexed requester, address qsrp, uint256 amount);
    event InvestmentBalanceUpdated(address qsrp, uint256 amount);
    event InvestmentReturned(address qsrp, uint256 amount);

    event WithdrawFeeUpdated(uint256 newFee);
    event GlobalWithdrawTimelockUpdated(uint256 timelock);
    event WithdrawTimelockUpdated(uint256 timelock);
    event QSRPRegistrationUpdated(address qsrp, bool status);

    event TreasuryAddressUpdated(address newTreasury);
    event InvestmentAllowanceUpdated(bool isAllowed);

    struct DepositInfo {
        uint256 amountPaid; // In USDC
        uint256 sharesReceived; // In receipt tokens
        uint256 sharesWithdrawn;
        uint256 createdTimestamp;
        uint256 lockedUntilTimestamp;
        uint256 initialLockPercent;
        bool emergencyWithdrawn;
    }

    struct WithdrawInfo {
        uint256 amountPaid; // In USDC
        uint256 sharesReceived; // In receipt tokens
        uint256 createdTimestamp;
        uint256 lockedUntilTimestamp;
        uint256 initialLockPercent;
        uint256 currentPercent; // 1000 base and 10**18 precision
        uint256 availableToWithdrawShares;
        uint256 withdrawPenaltyShares;
        bool emergencyWithdrawn;
    }

    struct WithdrawRequest {
        uint256 withdrawShares;
        uint256 createdTimestamp;
        uint256 lockedUntilTimestamp;
    }

    struct EmergencyWithdrawRequest {
        uint256 withdrawShares;
        uint256 withdrawPenaltyShares;
        uint256 createdTimestamp;
        uint256 lockedUntilTimestamp;
        uint256 [] depositIds;
    }


    // *************** INVESTOR ACTIONS ***************************

    function scheduleWithdraw(uint256 assets) external;

    function scheduleRedeem(uint256 shares) external;

    function emergencyWithdraw() external;

    function scheduleEmergencyWithdraw(uint256[] memory depositIds) external;

    // *************** MANAGER ACTIONS ***************************

    function updateInvestmentBalance(address qsrp, uint256 amount, uint256 realEventTime) external;

    function withdrawInvestmentToQSRP(address qsrp, uint256 amount) external;

    // todo consider fiat transfers.
    function returnInvestment(address qsrp, uint256 amount) external;

    function updateWithdrawFee(uint256 newFee) external;

    // *************** QSRP related actions ***************************
    function registerQSRP(address qsrp, bool status) external;

    // *************** Admin actions ***************************
    function updateDepositFeeNominator(uint16 depositFeeNominator) external;

    function updateTreasuryAddress(address treasuryAddress) external;

    function updateInvestmentAllowance(bool isInvestmentAllowed) external;

    function updateWithdrawWaitingPeriod(uint256 withdrawWaitingPeriod) external;

    function updateInitialLockPercent(uint16 initialLockPercent) external;

    function updateGlobalWithdrawTimelock(uint256 globalTimelock) external;

    function updateMaxDeposit(uint256 maxDeposit) external;

    // *************** Views ***************************

    function assetsUnit() external view returns (uint256);

    function getPricePerFullShare() external view returns (uint256);

    function assetsInPool() external view returns (uint256);

    function getPendingWithdraw(address holder) external view returns (WithdrawRequest memory);

    function getPendingEmergencyWithdraw(address holder) external view returns (EmergencyWithdrawRequest memory);

    function underlyingBalanceWithInvestmentForHolder(address holder) external view returns (uint256);

    function isQSRPRegistered(address qsrp) external view returns (bool);

    function getQSRPInfo(address qsrp) external view returns (uint256 debt, uint256 balance);

    function getWithdrawInfo(address investor, uint256[] memory depositIds) external view returns (WithdrawInfo[] memory);

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