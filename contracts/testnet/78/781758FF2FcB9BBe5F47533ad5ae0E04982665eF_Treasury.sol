// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: AGPL-3.0

/**
 * @title Treasury Smart contract
 * @author Lighthouse Team (Aayush Gupta)
 * @notice This is a multi-sig treasury smart contract that can receive and transfer ETH (native network token) and any ERC20 token.
 * @dev Flow: First, a transaction will be created using the submitTransaction() function. Then, signers will sign the transaction using the confirmTransaction() function. Finally, the token will be transferred using the executeTransaction() function.
 */

pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

error AMOUNT_CANT_BE_ZERO();
error TRANSACTION_ALREADY_EXECUTED();
error SIGNER_ALREADY_SIGNED();
error ETHER_TRANSFER_FAILED();
error ERC20_TRANSFER_FAILED();
error NOT_A_VALID_SIGNER();
error INVALID_CONFIRMATIONS_VALUE();
error NOT_ENOUGH_SIGNATURES();
error FUNCTION_LOCKED();
error ZERO_ADDRESS();
error NOT_ENOUGH_ETH_BALANCE();
error NOT_ENOUGH_ERC_BALANCE();

contract Treasury {
    /// @notice number of signatures required to approve the transaction.
    uint256 private confirmationsRequire;

    /// @notice value of current transaction ID
    uint256 private transactionId;

    /// @notice value of total number of signers
    uint256 private signerCount;

    /// @notice value of locked for reentrancy security
    uint256 private locked;

    /**
     * @notice struct to store all the transaction details
     */
    struct Transaction {
        address to;
        uint256 value;
        address token;
        bool executed;
        uint256 confirmations;
    }

    /**
     * @notice mapping to store all the details of transactions
     */
    mapping(uint256 => Transaction) public transactions;

    /**
     * @notice mapping to check that the signer has signed the transaction
     */
    mapping(uint256 => mapping(address => bool)) public confirmations;

    /**
     * @notice mapping to check whether an address is a signer
     */
    mapping(address => bool) public signers;

    /**
     * @notice event emitted when new transaction is submitted
     * @param txId transaction ID
     */
    event TransactionSubmitted(uint256 indexed txId);

    /**
     * @notice event emitted when transaction is confirmed by a signer
     * @param txId transaction ID
     * @param signer address of the signer
     */
    event Confirmation(uint256 indexed txId, address indexed signer);

    /**
     * @notice event emitted when token is transfered to the receiver
     * @param txId transaction ID
     * @param to address of the receiver
     * @param value amount of token transfered
     * @param token address of the token
     * @dev If the token address is zero, then it represents the network's native token address, such as ETH for Ethereum, Matic for Polygon, and Fil for FEVM.
     */
    event Transfered(uint256 indexed txId, address to, uint256 value, address token);

    /**
     * @notice event emitted when ether is received.
     * @param sender address of the sender
     * @param amount amount of ether received
     * @param data The data that was sent with the transaction
     */
    event RecievedEth(address indexed sender, uint amount, bytes data);

    /**
     * @notice modifier to save from the reentrancy attack
     */
    modifier noReentrant() {
        if (locked != 0) {
            revert FUNCTION_LOCKED();
        }

        locked = 1;
        _;
        locked = 0;
    }

    /**
     * @notice modifier to check that only the signers can call the function
     */
    modifier onlySigner() {
        if (!signers[msg.sender]) {
            revert NOT_A_VALID_SIGNER();
        }
        _;
    }

    /**
     * @notice modifier to check that the input amount cannot be zero.
     * @param _amount Amount to check
     */
    modifier notZeroAmount(uint _amount) {
        if (_amount == 0) {
            revert AMOUNT_CANT_BE_ZERO();
        }
        _;
    }

    /**
     * @notice modifier to check that the input address can't be a zero address
     * @param _address Address to check
     */
    modifier notZeroAddress(address _address) {
        if (_address == address(0)) {
            revert ZERO_ADDRESS();
        }
        _;
    }

    /**
     * @notice modifier to check that the balance of native or ERC20 tokens in the contract is greater than or equal to the required amount
     * @param _token address of the token
     * @param _value amout of token
     */
    modifier checkBalance(address _token, uint _value) {
        if (_token == address(0)) {
            if (address(this).balance < _value) {
                revert NOT_ENOUGH_ETH_BALANCE();
            }
        } else {
            if (IERC20(_token).balanceOf(address(this)) < _value) {
                revert NOT_ENOUGH_ERC_BALANCE();
            }
        }
        _;
    }

    /**
     * @notice constructor to set the initail value
     * @param _signers array of signers' addresses who can approve the transaction.
     * @param _confirmationsRequire minumum number of signatures require to approve the transaction
     */
    constructor(address[] memory _signers, uint _confirmationsRequire) {
        uint256 length = _signers.length;
        for (uint256 i = 0; i < length; ) {
            signers[_signers[i]] = true;
            unchecked {
                ++signerCount;
                ++i;
            }
        }
        if (_confirmationsRequire <= signerCount / 2) {
            revert INVALID_CONFIRMATIONS_VALUE();
        }
        confirmationsRequire = _confirmationsRequire;
    }

    /**
     * @notice Function to submit a transaction indicating the amount and type of token to be transferred to a specific address.
     * @dev If you want to transfer Native Token, then set the token address to the zero address.
     * @param _to address of the receiver
     * @param _value amount of token that will be transferred
     * @param _token token address
     */
    function submitTransaction(
        address _to,
        uint256 _value,
        address _token
    ) public onlySigner notZeroAmount(_value) notZeroAddress(_to) checkBalance(_token, _value) {
        unchecked {
            ++transactionId;
        }
        transactions[transactionId] = Transaction(_to, _value, _token, false, 0);
        emit TransactionSubmitted(transactionId);
    }

    /**
     * @notice function to sign the transaction that is created using the submitTransaction function.
     * @param _txId transaction ID
     */
    function confirmTransaction(uint256 _txId) public onlySigner {
        if (transactions[_txId].executed) {
            revert TRANSACTION_ALREADY_EXECUTED();
        }

        if (confirmations[_txId][msg.sender]) {
            revert SIGNER_ALREADY_SIGNED();
        }

        confirmations[_txId][msg.sender] = true;
        unchecked {
            ++transactions[_txId].confirmations;
        }

        emit Confirmation(_txId, msg.sender);
    }

    /**
     * @dev function to transfer tokens to the receiver.
     * @param _txId transaction ID
     */
    function executeTransaction(
        uint256 _txId
    ) public onlySigner noReentrant checkBalance(transactions[_txId].token, transactions[_txId].value) {
        if (transactions[_txId].executed) {
            revert TRANSACTION_ALREADY_EXECUTED();
        }
        if (transactions[_txId].confirmations < confirmationsRequire) {
            revert NOT_ENOUGH_SIGNATURES();
        }

        transactions[_txId].executed = true;
        if (transactions[_txId].token == address(0)) {
            (bool success, ) = transactions[_txId].to.call{ value: transactions[_txId].value }("");
            if (!success) {
                revert ETHER_TRANSFER_FAILED();
            }
        } else {
            IERC20 token = IERC20(transactions[_txId].token);
            if (!token.transfer(transactions[_txId].to, transactions[_txId].value)) {
                revert ERC20_TRANSFER_FAILED();
            }
        }
        emit Transfered(_txId, transactions[_txId].to, transactions[_txId].value, transactions[_txId].token);
    }

    // --------- Getter Functions ----------

    /**
     * @notice function to get the ETH Balance of the treasaury smart contract
     */
    function getEthBalace() public view returns (uint) {
        return address(this).balance;
    }

    /**
     * @notice function to get the ERC20 Balance of the treasaury smart contract
     */
    function getErc20Balance(address _token) public view returns (uint) {
        return IERC20(_token).balanceOf(address(this));
    }

    /**
     * @notice function to get the total number of signatures required to approve a transaction.
     */
    function getConfirmationsRequire() public view returns (uint) {
        return confirmationsRequire;
    }

    /**
     * @notice function to get latest transaction ID
     */
    function getTransactionId() public view returns (uint) {
        return transactionId;
    }

    /**
     * @notice function to get the total number of signer
     */
    function getSignerCount() public view returns (uint) {
        return signerCount;
    }

    /**
     * @notice Function to check that a transaction is approved and can be executed.
     * @param _txId transaction ID
     * @dev 0 represents true, and 1 represents false. Using a boolean is an option, but it is not be the most gas-efficient choice
     */
    function isApproved(uint _txId) public view returns (uint) {
        if (transactions[_txId].confirmations >= confirmationsRequire) {
            return 0;
        }
        return 1;
    }

    /**
     * @notice receive() function is called to receive ETH if msg.data is empty
     */
    receive() external payable {
        emit RecievedEth(msg.sender, msg.value, "");
    }

    /**
     * @notice fallback() function is called to receive ETH if msg.data is NOT empty.
     */
    fallback() external payable {
        emit RecievedEth(msg.sender, msg.value, msg.data);
    }
}