/**
 *Submitted for verification at testnet.snowtrace.io on 2023-07-14
*/

// SPDX-License-Identifier: AGPL
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

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
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

// File: contracts/MealVoucher.sol



pragma solidity ^0.8.11;



contract MealVoucher {
    using SafeMath for uint256;

    IERC20 public usdcToken;
    address public owner;
    enum VoucherStatus {
        VALID,
        USED,
        INVALID
    }
    enum ActionStatus {
        REDEEM_SUCCESS,
        GENERATE_SUCCESS,
        VOUCHER_EXISTED,
        INVALID_VOUCHER,
        USED_VOUCHER,
        REVOKE_SUCCESS,
        REVOKE_FAILED,
        INSUFFICIENT_PRIVILEGE,
        FEES_BELOW_ZERO,
        FEES_ABOVE_HUNDRED,
        INVALID_DEPOSIT_AMOUNT,
        INSUFFICIENT_USER_FUNDS,
        INVALID_VOUCHER_PRICE,
        INSUFFICIENT_FUNDS,
        DETAIL_RETRIEVAL_SUCCESS
    }
    enum TransferType {
        FEES,
        TRANSFER
    }
    struct VoucherState {
        uint value;
        VoucherStatus status;
    }
    struct Voucher {
        uint value;
        string voucherStatus;
        uint256 id;
        string actionStatus;
        address userAddress;
        address contractAddress;
    }
    struct Transaction {
        address from;
        address to;
        uint value;
        string transferType;
    }
    mapping(address => mapping(uint256 => VoucherState)) public mealVoucher;
    uint256 public totalVoucherIssued;
    uint256 public totalVoucherUsed;
    uint256 public totalAmountRedeemed;
    uint256 public unusedVoucherAmount;
    // timestamp as the key, voucher price as value
    uint256 public mealVoucherPrice;
    uint256 public managementFees;
    mapping(address => uint256[]) userVouchers;

    struct VoucherIds {
        address userAddress;
        uint256[] voucherIds;
    }

    struct VoucherPayable {
        address userAddress;
        uint256 voucherId;
        address merchantAddress;
    }

    constructor(address _usdcToken, uint256 voucherPrice, uint256 fees) {
        owner = payable(msg.sender);
        usdcToken = IERC20(_usdcToken);
        totalVoucherIssued = 0;
        totalVoucherUsed = 0;
        unusedVoucherAmount = 0;
        totalAmountRedeemed = 0;
        mealVoucherPrice = voucherPrice;
        managementFees = fees;
    }

    function getVoucherStatusString(
        VoucherStatus status
    ) private pure returns (string memory) {
        if (status == VoucherStatus.VALID) {
            return "VALID";
        } else if (status == VoucherStatus.USED) {
            return "USED";
        } else {
            return "INVALID";
        }
    }

    function getActionStatusString(
        ActionStatus status
    ) private pure returns (string memory) {
        if (status == ActionStatus.REDEEM_SUCCESS) {
            return "REDEEM_SUCCESS";
        } else if (status == ActionStatus.GENERATE_SUCCESS) {
            return "GENERATE_SUCCESS";
        } else if (status == ActionStatus.VOUCHER_EXISTED) {
            return "VOUCHER_EXISTED";
        } else if (status == ActionStatus.INVALID_VOUCHER) {
            return "INVALID_VOUCHER";
        } else if (status == ActionStatus.USED_VOUCHER) {
            return "USED_VOUCHER";
        } else if (status == ActionStatus.REVOKE_SUCCESS) {
            return "REVOKE_SUCCESS";
        } else if (status == ActionStatus.REVOKE_FAILED) {
            return "REVOKE_FAILED";
        } else if (status == ActionStatus.FEES_BELOW_ZERO) {
            return "FEES_BELOW_ZERO";
        } else if (status == ActionStatus.FEES_ABOVE_HUNDRED) {
            return "FEES_ABOVE_HUNDRED";
        } else if (status == ActionStatus.INVALID_DEPOSIT_AMOUNT) {
            return "INVALID_DEPOSIT_AMOUNT";
        } else if (status == ActionStatus.INSUFFICIENT_USER_FUNDS) {
            return "INSUFFICIENT_USER_FUNDS";
        } else if (status == ActionStatus.INVALID_VOUCHER_PRICE) {
            return "INVALID_VOUCHER_PRICE";
        } else if (status == ActionStatus.INSUFFICIENT_FUNDS) {
            return "INSUFFICIENT_FUNDS";
        } else if (status == ActionStatus.DETAIL_RETRIEVAL_SUCCESS) {
            return "DETAIL_RETRIEVAL_SUCCESS";
        } else {
            return "INSUFFICIENT_PRIVILEGE";
        }
    }

    function getTransferType(
        TransferType transferType
    ) private pure returns (string memory) {
        if (transferType == TransferType.FEES) {
            return "FEES";
        } else {
            return "TRANSFER";
        }
    }

    // get voucher detail
    function retrieveVoucherDetail(
        address _address,
        uint256 voucherId
    ) public view returns (Voucher memory) {
        VoucherState storage voucherState = mealVoucher[_address][voucherId];
        Voucher memory voucher = Voucher(
            voucherState.value,
            getVoucherStatusString(voucherState.status),
            voucherId,
            getActionStatusString(ActionStatus.DETAIL_RETRIEVAL_SUCCESS),
            _address,
            address(this)
        );
        return voucher;
    }

    // Update the usdc address
    function updateUsdcAddress(address _usdcToken) public returns (bool) {
        require(
            msg.sender == owner,
            getActionStatusString(ActionStatus.INSUFFICIENT_PRIVILEGE)
        );
        usdcToken = IERC20(_usdcToken);
        return true;
    }

    // Update the management fees
    function updateManagementFees(uint256 fees) public returns (bool) {
        require(
            msg.sender == owner,
            getActionStatusString(ActionStatus.INSUFFICIENT_PRIVILEGE)
        );
        require(fees >= 0, getActionStatusString(ActionStatus.FEES_BELOW_ZERO));
        require(
            fees <= 100,
            getActionStatusString(ActionStatus.FEES_ABOVE_HUNDRED)
        );
        managementFees = fees;
        return true;
    }

    // Accept usdc deposit
    function depositUSDC(uint256 amount) external payable {
        require(
            amount > 0,
            getActionStatusString(ActionStatus.INVALID_DEPOSIT_AMOUNT)
        );

        // Transfer USDC tokens from sender to this contract
        require(
            IERC20(usdcToken).transferFrom(msg.sender, address(this), amount),
            getActionStatusString(ActionStatus.INSUFFICIENT_USER_FUNDS)
        );

        // Emit an event for tracking the deposit
        emit Received(msg.sender, amount);
    }

    // Accept avax deposit
    function depositAvax() public payable {
        emit Received(msg.sender, msg.value);
    }

    //
    function setVoucherPrice(uint256 voucherPrice) public returns (bool) {
        require(
            msg.sender == owner,
            getActionStatusString(ActionStatus.INSUFFICIENT_PRIVILEGE)
        );
        require(
            voucherPrice > 0,
            getActionStatusString(ActionStatus.INVALID_VOUCHER_PRICE)
        );
        mealVoucherPrice = voucherPrice;
        return true;
    }

    function generateVoucher(
        VoucherIds[] memory listOfIds,
        uint256 numberOfVouchers
    ) public {
        require(
            msg.sender == owner,
            getActionStatusString(ActionStatus.INSUFFICIENT_PRIVILEGE)
        );
        uint256 availableBalance = usdcToken.balanceOf(address(this)).sub(
            unusedVoucherAmount
        );
        uint256 totalVoucherBalance = numberOfVouchers.mul(mealVoucherPrice);
        require(
            availableBalance >= totalVoucherBalance,
            getActionStatusString(ActionStatus.INSUFFICIENT_FUNDS)
        );

        Voucher[] memory voucherReturnState = new Voucher[](numberOfVouchers);

        for (
            uint256 addressIndex = 0;
            addressIndex < listOfIds.length;
            addressIndex++
        ) {
            address currentUserAddress = listOfIds[addressIndex].userAddress;
            uint256[] memory ids = listOfIds[addressIndex].voucherIds;
            for (uint256 idIndex = 0; idIndex < ids.length; idIndex++) {
                if (
                    mealVoucher[currentUserAddress][ids[idIndex]].value > 0 ||
                    mealVoucher[currentUserAddress][ids[idIndex]].status ==
                    VoucherStatus.USED
                ) {
                    Voucher memory returnState = Voucher(
                        mealVoucherPrice,
                        getVoucherStatusString(
                            mealVoucher[currentUserAddress][ids[idIndex]].status
                        ),
                        ids[idIndex],
                        getActionStatusString(ActionStatus.VOUCHER_EXISTED),
                        currentUserAddress,
                        address(this)
                    );

                    voucherReturnState[idIndex] = returnState;
                } else {
                    VoucherState memory voucherState = VoucherState(
                        mealVoucherPrice,
                        VoucherStatus.VALID
                    );
                    Voucher memory returnState = Voucher(
                        mealVoucherPrice,
                        getVoucherStatusString(VoucherStatus.VALID),
                        ids[idIndex],
                        getActionStatusString(ActionStatus.GENERATE_SUCCESS),
                        currentUserAddress,
                        address(this)
                    );
                    mealVoucher[currentUserAddress][
                        ids[idIndex]
                    ] = voucherState;
                    unusedVoucherAmount = unusedVoucherAmount.add(
                        mealVoucherPrice
                    );
                    totalVoucherIssued = totalVoucherIssued.add(1);
                    userVouchers[currentUserAddress].push(ids[idIndex]);
                    voucherReturnState[idIndex] = returnState;
                }
            }
        }

        emit VoucherGenerated(voucherReturnState);
    }

    function redeemVoucher(
        VoucherPayable[] memory vouchers,
        uint256 numberOfVouchers
    ) public {
        require(
            msg.sender == owner,
            getActionStatusString(ActionStatus.INSUFFICIENT_PRIVILEGE)
        );

        Voucher[] memory voucherReturnState = new Voucher[](numberOfVouchers);
        Transaction[] memory transferState = new Transaction[](
            numberOfVouchers * 2
        );

        for (
            uint256 voucherIndex = 0;
            voucherIndex < vouchers.length;
            voucherIndex++
        ) {
            VoucherPayable memory voucherPayable = vouchers[voucherIndex];
            address userAddress = voucherPayable.userAddress;
            uint voucherId = voucherPayable.voucherId;
            address merchantAddress = voucherPayable.merchantAddress;
            VoucherState storage voucher = mealVoucher[userAddress][voucherId];

            if (voucher.value <= 0) {
                Voucher memory returnState = Voucher(
                    voucher.value,
                    getVoucherStatusString(VoucherStatus.INVALID),
                    voucherId,
                    getActionStatusString(ActionStatus.INVALID_VOUCHER),
                    userAddress,
                    address(this)
                );
                voucherReturnState[voucherIndex] = returnState;
            } else if (voucher.status == VoucherStatus.USED) {
                Voucher memory returnState = Voucher(
                    voucher.value,
                    getVoucherStatusString(voucher.status),
                    voucherId,
                    getActionStatusString(ActionStatus.USED_VOUCHER),
                    userAddress,
                    address(this)
                );
                voucherReturnState[voucherIndex] = returnState;
            } else {
                voucher.status = VoucherStatus.USED;
                uint256 voucherValue = voucher.value;
                unusedVoucherAmount = unusedVoucherAmount.sub(voucherValue);
                uint256 managementFeeAmount = voucherValue
                    .mul(managementFees)
                    .div(100);
                usdcToken.transfer(
                    merchantAddress,
                    voucherValue - managementFeeAmount
                );
                Transaction memory firstTransfer = Transaction(
                    address(this),
                    merchantAddress,
                    voucherValue - managementFeeAmount,
                    getTransferType(TransferType.TRANSFER)
                );
                usdcToken.transfer(owner, managementFeeAmount);
                Transaction memory secondTransfer = Transaction(
                    address(this),
                    owner,
                    managementFeeAmount,
                    getTransferType(TransferType.FEES)
                );
                transferState[voucherIndex * 2] = firstTransfer;
                transferState[voucherIndex * 2 + 1] = secondTransfer;
                Voucher memory returnState = Voucher(
                    voucher.value,
                    getVoucherStatusString(voucher.status),
                    voucherId,
                    getActionStatusString(ActionStatus.REDEEM_SUCCESS),
                    userAddress,
                    address(this)
                );
                voucherReturnState[voucherIndex] = returnState;
                totalVoucherUsed = totalVoucherUsed.add(1);
                totalAmountRedeemed = totalAmountRedeemed.add(voucher.value);
            }
        }
        emit VoucherUsed(voucherReturnState);
        emit Transfer(transferState);
    }

    function withdraw() public {
        require(
            msg.sender == owner,
            getActionStatusString(ActionStatus.INSUFFICIENT_PRIVILEGE)
        );
        usdcToken.transfer(owner, usdcToken.balanceOf(address(this)));
    }

    function getUserVouchers(
        address userAddress
    ) public view returns (uint256[] memory) {
        return userVouchers[userAddress];
    }

    function getUsdcBalance() public view returns (uint256) {
        return usdcToken.balanceOf(address(this));
    }

    function getLifeTimeDonation() public view returns (uint256) {
        return totalAmountRedeemed.add(usdcToken.balanceOf(address(this)));
    }

    function revokeVoucher(
        VoucherIds[] memory listOfIds,
        uint256 numberOfVouchers
    ) public {
        require(
            msg.sender == owner,
            getActionStatusString(ActionStatus.INSUFFICIENT_PRIVILEGE)
        );

        Voucher[] memory voucherReturnState = new Voucher[](numberOfVouchers);

        for (uint256 idIndex = 0; idIndex < listOfIds.length; idIndex++) {
            address userAddress = listOfIds[idIndex].userAddress;
            uint256[] memory voucherIds = listOfIds[idIndex].voucherIds;
            for (uint256 i = 0; i < voucherIds.length; i++) {
                VoucherState memory voucher = mealVoucher[userAddress][
                    voucherIds[i]
                ];
                if (voucher.status == VoucherStatus.USED) {
                    Voucher memory returnState = Voucher(
                        voucher.value,
                        getVoucherStatusString(voucher.status),
                        voucherIds[i],
                        getActionStatusString(ActionStatus.REVOKE_FAILED),
                        userAddress,
                        address(this)
                    );
                    voucherReturnState[i] = returnState;
                } else {
                    voucher.status = VoucherStatus.INVALID;
                    unusedVoucherAmount = unusedVoucherAmount.sub(
                        voucher.value
                    );
                    voucher.value = 0;
                    Voucher memory returnState = Voucher(
                        voucher.value,
                        getVoucherStatusString(voucher.status),
                        voucherIds[i],
                        getActionStatusString(ActionStatus.REVOKE_SUCCESS),
                        userAddress,
                        address(this)
                    );

                    voucherReturnState[i] = returnState;
                }
            }
        }

        emit RevokeVoucher(voucherReturnState);
    }

    event Received(address indexed depositor, uint256 amount);
    event VoucherGenerated(Voucher[]);
    event VoucherUsed(Voucher[]);
    event RevokeVoucher(Voucher[]);
    event Transfer(Transaction[]);
}