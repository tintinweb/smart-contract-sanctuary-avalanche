// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import { IWAVAX } from "../../interfaces/IWAVAX.sol";
import { IGReservePool } from "../../interfaces/IGReservePool.sol";
import { IGLendingPool } from "../../interfaces/IGLendingPool.sol";
import { AccessControlManager } from "../../AccessControlManager.sol";
import { GlacierAddressBook } from "../../GlacierAddressBook.sol";

/**
 * @title  Interest bearing ERC-20 token implementation
 * @author Jack Frost
 * @notice Glacial AVAX (glAVAX) is an AVAX derivative ERC-20 token that represents AVAX deposited into the Glacier protocol.
 *         
 * Users can mint glAVAX by depositing AVAX at a 1:1 rate, where the contract will give the user shares of the overall network depending on their
 * proportion of AVAX against the proportion of overall AVAX.
 * 
 * Users can then redeem back their AVAX at a 1:1 rate for the balance of their glAVAX.
 *
 * glAVAX balances are rebased automatically by the network to include all accrued rewards from deposits.
 */
contract glAVAX is Initializable, IERC20Upgradeable, AccessControlManager, PausableUpgradeable, ReentrancyGuardUpgradeable {
    
    /// @notice Token Info
    string private constant NAME     = "Glacial AVAX";
    string private constant SYMBOL   = "glAVAX";
    uint8  private constant DECIMALS = 18;

    /// @notice The underlying share balances for user deposits
    /// @dev These act as a way to calculate how much AVAX a user has a claim to in the network
    mapping(address => uint256) public _shares;
    
    /// @notice The token allowances
    mapping(address => mapping(address => uint256)) public _allowances;

    /// @notice The maximum allowed minted Glacial AVAX
    uint256 public _maxSupply;
    
    /// @notice The total network shares that have a claim by depositors
    uint256 public _totalShares;

    /// @notice The Glacier protocol addresses
    GlacierAddressBook public addresses;

    /// @notice The amount of AVAX that has been sent to the staging wallet 
    uint256 public totalNetworkAVAX;

    /// @notice The percentage of overall funds that are kept onhand for liquid withdraws
    uint256 public reservePercentage;

    /// @notice When enabled, withdraw limits will be put in place to slow down withdraw pressure
    bool public throttleNetwork;

    /// @notice The current amount to be withdrawn from the network
    uint256 public withdrawRequestTotal;

    /// @notice The amount of claimable AVAX inside this contract
    uint256 public claimableAmount;
    
    struct WithdrawRequest {
        address user;
        uint256 amount;
        uint256 timestamp;
        bool fufilled;
        bool claimed;
    }

    /// @notice A mapping of withdraw requests to their IDs
    mapping(uint256 => WithdrawRequest) public withdrawRequests;

    /// @notice A counter for the withdraw requests
    uint256 public totalWithdrawRequests;

    /// @notice A counter for how many withdraw requests have been fufilled
    uint256 public totalWithdrawRequestsFufilled;

    /// @notice A mapping of withdraw request IDs to the owner IDs
    mapping(uint256 => uint256) public withdrawRequestIndex;

    /// @notice A mapping of withdrawers to another mapping of the owner index to the withdraw request ID
    mapping(address => mapping(uint256 => uint256)) public userWithdrawRequests;

    /// @notice A mapping of withdrawers to the total amount of withdraw requests
    mapping(address => uint256) public userWithdrawRequestCount;

    /// @notice Emitted when a user deposits AVAX into Glacier
    /// @param avaxAmount Is in units of AVAX to mark the historical conversion rate
    event Deposit(address indexed user, uint256 avaxAmount, uint64 referralCode);

    /// @notice Emitted when a user withdraws AVAX from Glacier
    /// @param avaxAmount Is in units of AVAX to mark the historical conversion rate
    event Withdraw(address indexed user, uint256 avaxAmount);

    /// @notice Emitted when a user requests to withdraw an amount of AVAX from Glacier
    /// @param avaxAmount Is in units of AVAX to mark the historical conversion rate
    /// @dev This event is only emitted if all other withdrawal methods have been exhausted
    ///      GlacialBot will monitor this event stream and request withdrawals from the network
    ///      before satisfying the requests itself. 
    event UserWithdrawRequest(address indexed user, uint256 avaxAmount);

    /// @notice Emitted automatically by the protocol to release some AVAX from the network
    event ProtocolWithdrawRequest(uint256 avaxAmount);

    /// @notice Emitted when a user cancels their withdraw request, notifying the network to wipe the previous withdraw request
    event CancelWithdrawRequest(address indexed user, uint256 id);

    /// @notice Emitted when a user claims withdrawn AVAX
    /// @param avaxAmount Is in units of AVAX to mark the historical conversion rate
    event Claim(address indexed user, uint256 avaxAmount);

    /// @notice Emitted when a user throttles the network with a large withdrawal
    event NetworkThrottled(address indexed user);

    /// @notice Emitted when AVAX is refilled into this contract
    event RefillAVAX(uint256 amount);

    /// @notice Emitted when the contract fufills a user withdraw request
    event FufilledUserWithdrawal(address indexed user, uint256 requestID, uint256 amount);

    function initialize(GlacierAddressBook _addresses) initializer public {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(NETWORK_MANAGER, msg.sender);

        addresses = _addresses;

        // Approve the spending of WAVAX in this control by the reserve pool and the lending pool
        IERC20Upgradeable(addresses.wavaxAddress()).approve(addresses.reservePoolAddress(), type(uint256).max);
        IERC20Upgradeable(addresses.wavaxAddress()).approve(addresses.lendingPoolAddress(), type(uint256).max);
    }

    /**
     * ===================================================
     *                  ADMIN FUNCTIONS
     * ===================================================
     */

    /**
     * @notice Sets the maximum amount of AVAX we're taking on.
     * @dev Set to 0 to disable
     */
    function setMaxSupply(uint256 amount) external isRole(NETWORK_MANAGER) {
        _maxSupply = amount;
    }

    /**
     * @notice Stops accepting new AVAX deposits into the protocol, while still allowing withdrawals to continue.
     */
    function pauseDeposits() external isRole(NETWORK_MANAGER) {
        _pause();
    }

    /**
     * @notice Resumes accepting new AVAX deposits
     */
    function resumeDeposits() external isRole(NETWORK_MANAGER) {
        _unpause();
    }

    /**
     * @notice Configures the reserve percentage
     */
    function setReservePercentage(uint256 _reservePercentage) external isRole(NETWORK_MANAGER) {
        reservePercentage = _reservePercentage;
    }

    /**
     * @notice Restores the network so that it can continue to run optimally
     */
    function restoreNetwork() external isRole(NETWORK_MANAGER) {
        throttleNetwork = false;
    }

    /**
     * @notice Sets the new network total
     * @dev To be used manually by the development team
     * 
     * Requirements:
     *  - The contract must not be paused
     */
    function setNetworkTotal(uint256 newNetworkTotal) external isRole(NETWORK_MANAGER) whenPaused {
        totalNetworkAVAX = newNetworkTotal;
    }

    /**
     * @notice Increases the network total by `amount`
     * @dev To be called by the network manager
     */
    function increaseNetworkTotal(uint256 amount) external isRole(NETWORK_MANAGER) {
        totalNetworkAVAX += amount;
    }

    /**
     * @notice Rebalances the contracts, distributing any necessary AVAX across the reserve pool and the network
     * @dev Called every 24-hours by the rebalancer
     */
    function rebalance() external payable isRole(NETWORK_MANAGER) {
        uint256 balance = deposits();
        uint256 currentReserves = IGReservePool(addresses.reservePoolAddress()).totalReserves();
        uint256 reserveTarget = totalAVAX() * reservePercentage / 1e4;

        // If we have any deposits in the contract, then we have spillover.
        // Send this to the reserves and to the network.
        if (balance > 0) {
            if (currentReserves < reserveTarget) {
                uint256 toFill = reserveTarget - currentReserves;
                uint256 toReserves = toFill > balance ? balance : toFill;
                IGReservePool(addresses.reservePoolAddress()).deposit(toReserves);
                balance -= toReserves;
            } else {
                // Otherwise withdraw the excess so we can move it into the network
                IGReservePool(addresses.reservePoolAddress()).withdraw(currentReserves - reserveTarget);
                balance += currentReserves - reserveTarget;
            }

            if (balance > 0) {
                totalNetworkAVAX += balance;
                IWAVAX(addresses.wavaxAddress()).withdraw(balance);
                payable(addresses.networkWalletAddress()).transfer(balance);
            }
        }

        // Then if we are still indebted to the protocol, issue a refill request to the network
        uint256 withdrawAmount = 0;
        currentReserves = IGReservePool(addresses.reservePoolAddress()).totalReserves();
        if (currentReserves < reserveTarget) {
            withdrawAmount += reserveTarget - currentReserves;
        }

        uint256 totalOwed = IGLendingPool(addresses.lendingPoolAddress()).totalOwed();
        if (totalOwed > 0) {
            withdrawAmount += totalOwed;
        }

        if (withdrawAmount > 0) {
            emit ProtocolWithdrawRequest(withdrawAmount);
        }
    }

    /**
     * ===================================================
     *                  BASIC FUNCTIONS
     * ===================================================
     */

    /**
     * @notice Deposits AVAX into the Glacier protocol
     */
    receive() external payable {
        if (msg.sender != addresses.wavaxAddress()) {
            deposit(msg.sender, 0);
        }
    }

    /**
     * @notice ERC-20 function to return the total amount of AVAX in the system
     */
    function totalSupply() public view virtual override returns (uint256) {
        return netAVAX();
    }

    /**
     * @notice Returns the total amount of AVAX currently in the protocol (i.e. all of the network AVAX, the reserve pool AVAX, and any onhand deposits)
     */
    function totalAVAX() public view returns (uint256) {
        return totalNetworkAVAX + IGReservePool(addresses.reservePoolAddress()).totalReserves() + IERC20Upgradeable(addresses.wavaxAddress()).balanceOf(address(this));
    }

    /**
     * @notice Returns the amount of AVAX that should be in the protocol (i.e. factoring in loans)
     */
    function netAVAX() public view returns (uint256) {
        return totalAVAX() - IGLendingPool(addresses.lendingPoolAddress()).totalOwed();
    }

    /**
     * @notice Returns the amount of spillover deposits that were collected today
     */
    function deposits() public view returns (uint256) {
        return IERC20Upgradeable(addresses.wavaxAddress()).balanceOf(address(this));
    }

    /**
     * @notice Returns the amount of AVAX that is ready to be claimed by the network
     */
    function claimable() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @notice Returns the total amount of liquidity there is to facilitate withdrawals
     */
    function liquidity() public view returns (uint256) {
        // FUTURE FEATURE: Adding USDC purchaser to help offset delta risk
        return deposits() + IGReservePool(addresses.reservePoolAddress()).totalReserves() + IGLendingPool(addresses.lendingPoolAddress()).totalReserves();
    }

    /**
     * @notice Returns the users balance
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return avaxFromShares(_shares[account]);
    }

    function sharesOf(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @notice Returns the amount of shares correspond to the `avaxAmount`
     */
    function sharesFromAvax(uint256 avaxAmount) public view returns (uint256) {
        uint256 totalAvax = netAVAX();
        if (totalAvax == 0 || _totalShares == 0) {
            return avaxAmount;
        }
        return avaxAmount * _totalShares / totalAvax;
    }

    /**
     * @notice Returns the amount of AVAX that corresponds to the `shareAmount`
     */
    function avaxFromShares(uint256 shareAmount) public view returns (uint256) {
        uint256 totalAvax = netAVAX();
        if (_totalShares == 0) {
            return shareAmount;
        }
        return shareAmount * totalAvax / _totalShares;
    }

    /**
     * @notice Mints shares to a user account
     */
    function _mintShares(address account, uint256 shareAmount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalShares += shareAmount;
        _shares[account] += shareAmount;
    }

    /**
     * @notice Burns shares from a user account
     */
    function _burnShares(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        uint256 accountBalance = _shares[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _shares[account] = accountBalance - amount;
        }
        _totalShares -= amount;
    }

    /**
     * @notice Calculates whether or not a certain amount of AVAX withdrawal will throttle the network
     */
    function willThrottleNetwork(uint256 withdrawalAmount) public view returns (bool) {
        uint256 liq = liquidity();
        if (withdrawalAmount > liq) {
            return true;
        } else {
            return false;
        }
    }

    /**
     * @notice Deposits AVAX into the Glacier protocol
     * @param user The user that is initiating this deposit
     * @param referralCode The referral code of someone
     */
    function deposit(address user, uint64 referralCode) public payable nonReentrant whenNotPaused returns (uint256) {
        require(msg.sender == user, "USER_NOT_SENDER");
        require(msg.value > 0, "ZERO_DEPOSIT");
        if (_maxSupply > 0) {
            require(totalAVAX() + msg.value <= _maxSupply, "MAXIMUM_AVAX_REACHED");
        }

        uint256 avaxAmount = msg.value;

        /// @dev This function is important as it repays back any outstanding loans the protocol took to satisfy withdrawals.
        ///      1. First it checks for user withdrawals.
        ///      2. Then it pays back any atomic buys
        ///      3. Then it pays back any loans
        ///      4. It then leaves the rest which will get picked up as reserves every day
        avaxAmount = _repayLiquidity(avaxAmount);

        // Mint back to the user the total glAVAX amount of their AVAX deposit
        uint256 sharesAmount = sharesFromAvax(msg.value);
        _mintShares(user, sharesAmount);

        // Otherwise leave the AVAX in the contract
        IWAVAX(addresses.wavaxAddress()).deposit{value: avaxAmount}();

        emit Deposit(user, msg.value, referralCode);
        emit Transfer(address(0), user, msg.value);

        return sharesAmount;
    }

    /**
     * @notice Withdraws AVAX from the Glacier protocol
     * @param user The user that is initiating this withdrawal
     * @param amount The amount in glAVAX
     * @dev Withdrawal Sourcing handling:
     *      1. Router AVAX
     *      2. Reserve Pool
     *      3. OTC Lending
     *      4. Atomic Buying
     *      5. Glacier Network
     */
    function withdraw(address user, uint256 amount) external nonReentrant {
        require(msg.sender == user, "USER_NOT_SENDER");
        require(amount > 0, "ZERO_WITHDRAW");
        require(amount <= balanceOf(user), "INSUFFICIENT_BALANCE");

        /// @dev We store the variables ahead of execution as this function can end up changing ratios which can affect implicit nature
        uint256 avaxAmount = amount;
        uint256 totalWithdrawAvaxAmount = avaxAmount;

        // First check the AVAX that is held on hand
        // The pool will hold reserve funds + any extra deposits that happened during the day
        uint256 depositAmount = IERC20Upgradeable(addresses.wavaxAddress()).balanceOf(address(this)) - claimableAmount;
        if (avaxAmount > 0 && depositAmount > 0) {
            uint256 onHandAmount = depositAmount > avaxAmount ? avaxAmount : depositAmount;
            avaxAmount -= onHandAmount;
        }

        // Then check the AVAX that is held in the reserve pool
        uint256 reserveBalance = IGReservePool(addresses.reservePoolAddress()).totalReserves();
        if (avaxAmount > 0 && reserveBalance > 0) {
            uint256 reserveAmount = reserveBalance > avaxAmount ? avaxAmount : reserveBalance;
            IGReservePool(addresses.reservePoolAddress()).withdraw(reserveAmount);
            avaxAmount -= reserveAmount;
        }

        avaxAmount = _borrowLiquidity(avaxAmount);

        // Finally, as a last resort, we want to issue a withdraw request to the network
        // If this logic is hit, then we enable daily limits to throttle the network
        if (avaxAmount > 0) {
            throttleNetwork = true;
            _withdrawRequest(user, avaxAmount);
        }

        /// Withdraw AVAX from WAVAX and burn the related glAVAX tokens
        uint256 toWithdraw = totalWithdrawAvaxAmount - avaxAmount;
        if (toWithdraw > 0) {
            uint256 sharesToBurn = sharesFromAvax(toWithdraw);
            IWAVAX(addresses.wavaxAddress()).withdraw(toWithdraw);
            _burnShares(user, sharesToBurn);
            emit Transfer(user, address(0), amount);
            // Transfer the user with the AVAX
            (bool success, ) = payable(user).call{ value: toWithdraw }("");
            require(success, "TRANSFER_FAILED");
        }

        emit Withdraw(user, totalWithdrawAvaxAmount);
    }

    /**
     * @notice Grants liquidity to the Glacier Pool to facilitate withdrawals
     * @param amount The amount of AVAX we are trying to raise
     */
    function _borrowLiquidity(uint256 amount) internal returns (uint256) {
        // Check if there is any AVAX that we can lend out from the lending pool
        uint256 borrowAmount = _lendAvax(amount);
        amount -= borrowAmount;

        // TODO: Use other methods of borrowing, i.e. purchasing AVAX atomically

        return amount;
    }

    /**
     * @notice This contract takes out a loan of `amount` AVAX from the lending pool
     */
    function _lendAvax(uint256 amount) internal returns (uint256) {
        uint256 lendingBalance = IERC20Upgradeable(addresses.wavaxAddress()).balanceOf(addresses.lendingPoolAddress());
        if (amount > 0 && lendingBalance > 0) {
            uint256 borrowAmount = lendingBalance > amount ? amount : lendingBalance;
            IGLendingPool(addresses.lendingPoolAddress()).borrow(borrowAmount);
            return borrowAmount;
        } else {
            return 0;
        }
    }

    /**
     * @notice Repays liquidity that was borrowed by the Glacier Pool
     */
    function _repayLiquidity(uint256 avaxAmount) internal returns (uint256) {
        require(avaxAmount > 0, "ZERO_DEPOSIT");
        uint256 amount = msg.value;
        uint256 totalWithdrawRequestAmount = allWithdrawRequests();
        if (totalWithdrawRequestAmount > 0) {
            uint256 repayAmount = totalWithdrawRequestAmount > amount ? amount : totalWithdrawRequestAmount;
            _fufillUserWithdrawals(repayAmount);
            amount -= repayAmount;
        }

        // If any AVAX is owed to the lending pool, prioritize paying this back first before the reserves
        if (amount > 0 && IGLendingPool(addresses.lendingPoolAddress()).totalOwed() > 0) {
            // FUTURE FEATURE: Adding USDC purchaser to help offset delta risk
            // uint256 totalBought = IGLendingPool(addresses.lendingPoolAddress()).totalBought();
            // if (totalBought > 0) {
            //     uint256 repayAmount = totalBought > amount ? amount : totalBought;
            //     IGLendingPool(addresses.lendingPoolAddress()).repayBought(address(this), repayAmount);
            //     amount -= repayAmount;
            // }
            
            uint256 totalLoaned = IGLendingPool(addresses.lendingPoolAddress()).totalLoaned();
            if (amount > 0 && totalLoaned > 0) {
                uint256 repayAmount = totalLoaned > amount ? amount : totalLoaned;
                IGLendingPool(addresses.lendingPoolAddress()).repay(address(this), repayAmount);
                amount -= repayAmount;
            }
        }

        return avaxAmount;
    }

    /**
     * @notice Notifies the network that a withdrawal needs to be made.
     */
    function _withdrawRequest(address user, uint256 amount) internal {
        require(msg.sender == user, "USER_NOT_SENDER");
        require(amount <= balanceOf(user), "INSUFFICIENT_BALANCE");

        WithdrawRequest memory request = WithdrawRequest({
            user: user,
            amount: amount,
            timestamp: block.timestamp,
            fufilled: false,
            claimed: false
        });

        // Setup the withdraw request data
        withdrawRequests[totalWithdrawRequests] = request;
        userWithdrawRequests[user][userWithdrawRequestCount[user]] = totalWithdrawRequests;
        withdrawRequestIndex[totalWithdrawRequests] = userWithdrawRequestCount[user];
        ++userWithdrawRequestCount[user];
        ++totalWithdrawRequests;

        // Transfer the glAVAX into the contract to hold it for the interim period
        transferFrom(user, address(this), amount);

        emit UserWithdrawRequest(user, amount);
    }

    /**
     * @notice Returns the withdraw request index from a given user by the user withdraw request index
     */
    function requestIdFromUserIndex(address user, uint256 index) public view virtual returns (uint256) {
        require(index < userWithdrawRequestCount[user], "INDEX_OUT_OF_BOUNDS");
        return userWithdrawRequests[user][index];
    }   

    /**
     * @notice Returns a withdraw request by its index
     */
    function requestById(uint256 id) public view virtual returns (WithdrawRequest memory) {
        require(id < allWithdrawRequests(), "INDEX_OUT_OF_BOUNDS");
        return withdrawRequests[id];
    }

    /**
     * @notice Allows a user to claim the amount of AVAX that is ready from their withdrawal request
     * @dev This function will claim any currently fufilled requests, and ignore non-fufilled requests
     */
    function claimAll(address user) external payable nonReentrant {
        require(msg.sender == user, "USER_NOT_SENDER");
        uint256 requests = userWithdrawRequestCount[user];
        require(requests > 0, "NO_ACTIVE_REQUESTS");
        for (uint256 i = 0; i < requests; ++i) {
            uint256 id = requestIdFromUserIndex(user, i);
            WithdrawRequest memory request = withdrawRequests[userWithdrawRequests[user][id]];
            // Check for fufilled requests that haven't been claimed
            if (request.fufilled && !request.claimed) {
                _claim(user, i);
            }
        }
    }

    /**
     * @notice Allows a user to claim the amount of AVAX that is ready from their withdrawal request
     * @dev This function will revert if the request isn't yet fufilled
     */
    function claim(address user, uint256 id) external payable nonReentrant {
        _claim(user, id);
    }

    /**
     * @notice Internal logic for claiming 
     */
    function _claim(address user, uint256 index) internal {
        require(msg.sender == user, "USER_NOT_SENDER");
        uint256 id = requestIdFromUserIndex(user, index);
        WithdrawRequest storage request = withdrawRequests[id];
        require(request.fufilled, "REQUEST_NOT_FUFILLED");
        require(!request.claimed, "ALREADY_CLAIMED");
        request.claimed = true;
        payable(user).transfer(request.amount);
        emit Claim(user, request.amount);
    }

    /**
     * @notice Cancels all the users withdrawal requests and returns the glAVAX to the user
     */
    function cancelAll(address user) external nonReentrant {
        require(msg.sender == user, "USER_NOT_SENDER");
        uint256 requests = userWithdrawRequestCount[user];
        require(requests > 0, "NO_ACTIVE_REQUESTS");
        for (uint256 i = requests - 1; i != 0; --i) {
            uint256 id = requestIdFromUserIndex(user, i);
            _cancel(user, id);
        }
        
        if (requests > 0) {
            uint256 id = userWithdrawRequests[user][0];
            _cancel(user, id);
        }
    }

    /**
     * @notice Cancels a single user withdrawal request and returns the glAVAX to the user
     */
    function cancel(address user, uint256 index) external nonReentrant {
        require(msg.sender == user, "USER_NOT_SENDER");
        uint256 id = userWithdrawRequests[user][index];
        _cancel(user, id);
    }
    
    /**
     * @notice Internal logic for cancelling requests
     */
    function _cancel(address user, uint256 id) internal {
        require(msg.sender == user, "USER_NOT_SENDER");
        WithdrawRequest storage request = withdrawRequests[id];
        require(request.amount > 0 || request.timestamp > 0, "INVALID_REQUEST");
        require(!request.claimed, "ALREADY_CLAIMED");

        // If the user is cancelling a request that is already fufilled, then wrap the AVAX to be deposited into the network
        if (request.fufilled) {
            IWAVAX(addresses.wavaxAddress()).deposit{value: request.amount}();
        }

        uint256 userTokens = request.amount;
        request.amount = 0;
        request.timestamp = 0;
        request.fufilled = false;
        request.claimed = false;
        _removeRequest(user, id);
        _transfer(address(this), user, userTokens);
        emit CancelWithdrawRequest(user, id);
    }

    /**
     * @notice Removes a request ID from a user
     * @dev `index` referres to the index from the enumerable owner requests which gets the request ID
     *      `id` refers to the actual request ID to get the request data 
     */
    function _removeRequest(address user, uint256 id) internal {
        uint256 backIndex = userWithdrawRequestCount[user] - 1;
        uint256 toDeleteIndex = withdrawRequestIndex[id];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (toDeleteIndex != backIndex) {
            uint256 backId = userWithdrawRequests[user][backIndex];
            
            // Move the request thats at the back of the queue to the index of the token we are deleting
            // This lets us reduce the total withdraw requests and still be able to iterate over the total amount
            userWithdrawRequests[user][toDeleteIndex] = backId;

            // Now move the request we are deleting to the back of the list
            withdrawRequestIndex[backId] = toDeleteIndex;
        }

        // This also deletes the contents at the last position of the array
        delete withdrawRequestIndex[id];
        delete userWithdrawRequests[user][backIndex];
        userWithdrawRequestCount[user]--;
    }

    /**
     * @notice Deposits AVAX directly from a protocol management wallet
     * @dev This is responsible for delegating AVAX to user withdrawals, and other parts of the protocol that are owed AVAX
     */
    function fufillWithdrawal() external payable isRole(NETWORK_MANAGER) {
        uint256 avaxAmount = msg.value;

        // Transfer the balance from the network to the contract
        IWAVAX(addresses.wavaxAddress()).deposit{value: avaxAmount}();
        totalNetworkAVAX -= avaxAmount;

        /// @dev This function is important as it repays back any outstanding loans the protocol took to satisfy withdrawals.
        ///      1. First it checks for user withdrawals.
        ///      2. Then it pays back any atomic buys
        ///      3. Then it pays back any loans
        ///      4. It then leaves the rest which will get picked up as reserves every day
        avaxAmount = _repayLiquidity(avaxAmount);
    }

    /**
     * @notice Fufills a user withdrawal
     * @dev When a user withdrawal is fufilled, the AVAX is held inside the contract (i.e. `address(this).balance`).
     *      The request is marked as fufilled and the contract burns it's shares that it assumes ownership over for the repayment period. 
     */
    function _fufillUserWithdrawals(uint256 amount) internal {
        IWAVAX(addresses.wavaxAddress()).withdraw(amount);
        uint256 totalAvax = address(this).balance;
        for (uint256 i = totalWithdrawRequestsFufilled; i < totalWithdrawRequests; ++i) {
            WithdrawRequest storage request =  withdrawRequests[i];
            if (totalAvax >= request.amount) {
                request.fufilled = true;

                totalAvax -= request.amount;
                ++totalWithdrawRequestsFufilled;

                // Hold the users withdrawal in native AVAX and burn the contract held glAVAX
                _burnShares(address(this), request.amount);

                emit FufilledUserWithdrawal(request.user, i, amount);
            } else {
                break;
            }
        }
    }

    /**
     * @notice Returns the total amount of AVAX that has been requested for withdrawal
     * @dev This is the glAVAX balance of the contract, as it takes custody of the tokens.
     */
    function allWithdrawRequests() public view returns (uint256) {
        return balanceOf(address(this));
    }

     /**
     * ==============================================================
     *             ERC-20 Functions
     * ==============================================================
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 shareAmount = sharesFromAvax(amount);

        _beforeTokenTransfer(from, to, shareAmount);

        uint256 fromBalance = _shares[from];
        require(fromBalance >= shareAmount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _shares[from] = fromBalance - shareAmount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _shares[to] += shareAmount;
        }

        emit Transfer(from, to, shareAmount);

        _afterTokenTransfer(from, to, shareAmount);
    }

    function name() external view virtual returns (string memory) {
        return NAME;
    }

    function symbol() external view virtual returns (string memory) {
        return SYMBOL;
    }

    function decimals() external view virtual returns (uint8) {
        return DECIMALS;
    }

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

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

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalShares += amount;
        _shares[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _shares[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _shares[account] = accountBalance - amount;
        }
        _totalShares -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import { AccessControlManager } from "./AccessControlManager.sol";

/**
 * @title GlacierAddressBook contract
 * @author Jack Frost
 * @notice Holds and manages the addresses for the Glacier protocol
 */
contract GlacierAddressBook is Initializable, AccessControlManager {

    address public wavaxAddress;

    address public usdcAddress;

    address public reservePoolAddress;

    address public lendingPoolAddress;

    address public networkWalletAddress;

    function initialize(
        address _wavaxAddress,
        address _usdcAddress,
        address _reservePoolAddress,
        address _lendingPoolAddress,
        address _networkWalletAddress
    ) initializer public {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        wavaxAddress = _wavaxAddress;
        usdcAddress = _usdcAddress;
        reservePoolAddress = _reservePoolAddress;
        lendingPoolAddress = _lendingPoolAddress;
        networkWalletAddress = _networkWalletAddress;
    }

    function setWAVAXAddress(address _wavaxAddress) external isRole(DEFAULT_ADMIN_ROLE) {
        wavaxAddress = _wavaxAddress;
    }

    function setUSDCAddress(address _usdcAddress) external isRole(DEFAULT_ADMIN_ROLE) {
        usdcAddress = _usdcAddress;
    }

    function setReservePoolAddress(address _reservePoolAddress) external isRole(DEFAULT_ADMIN_ROLE) {
        reservePoolAddress = _reservePoolAddress;
    }

    function setLendingPoolAddress(address _lendingPoolAddress) external isRole(DEFAULT_ADMIN_ROLE) {
        lendingPoolAddress = _lendingPoolAddress;
    }

    function setNetworkWalletAddress(address _networkWalletAddress) external isRole(DEFAULT_ADMIN_ROLE) {
        networkWalletAddress = _networkWalletAddress;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

/**
 * @title AccessControlManager contract
 * @author Jack Frost
 * @notice Manages the roles for the protocol
 */
contract AccessControlManager is AccessControlUpgradeable {

    /// @notice If a wallet or a contract has this role set, they can restore the network and request withdrawals from the Glacier Network
    bytes32 public constant NETWORK_MANAGER = keccak256("NETWORK_MANAGER");

    /// @notice If a wallet or contract has this role set, they can deposit and withdraw from the reserve pool
    bytes32 public constant RESERVE_POOL_MANAGER = keccak256("RESERVE_POOL_MANAGER");

    /// @notice If a wallet or contract has this role set, they can borrow and take loans from the lending pool requiring them to pay back
    bytes32 public constant LENDING_POOL_CLIENT = keccak256("LENDING_POOL_CLIENT");

    /// @notice If a wallet or contract has this role set, they can manage the claim pool
    bytes32 public constant CLAIM_POOL_MANAGER = keccak256("CLAIM_POOL_MANAGER");

    /// @notice If a wallet or contract has this role set, they're able to use certain strategies 
    bytes32 public constant STRATEGY_USER = keccak256("STRATEGY_USER");

    /// @notice Modifier to test that the caller has a specific role (interface to AccessControl)
    modifier isRole(bytes32 role) {
        require(hasRole(role, msg.sender), "INCORRECT_ROLE");
        _;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.6;

interface IGReservePool {
    function totalReserves() external view returns (uint256);
    function deposit(uint256) external;
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity >=0.5.0;

import { IERC20Upgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IWAVAX is IERC20Upgradeable {
    function deposit() external payable;
    function withdraw(uint256) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.6;

interface IGLendingPool {
    function totalReserves() external view returns (uint256);
    function totalLoaned() external view returns (uint256);
    function totalOwed() external view returns(uint256);
    function borrow(uint256) external returns (uint256);
    function repay(address, uint256) external returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}