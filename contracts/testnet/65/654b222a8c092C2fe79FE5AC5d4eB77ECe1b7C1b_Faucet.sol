/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-11
*/

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

// File: libraries/TokenHelper.sol



pragma solidity ^0.8.0;


error TokenHelper__TransferFailed(IERC20 token, address recipient, uint256 amount);

/// @title Safe Transfer
/// @author Trader Joe
/// @notice Wrappers around ERC20 operations that throw on failure (when the token
/// contract returns false). Tokens that return no value (and instead revert or
/// throw on failure) are also supported, non-reverting calls are assumed to be
/// successful.
/// To use this library you can add a `using TokenHelper for IERC20;` statement to your contract,
/// which allows you to call the safe operation as `token.safeTransfer(...)`
library TokenHelper {
    /// @notice Transfers token only if the amount is greater than zero
    /// @param token The address of the token
    /// @param owner The owner of the tokens
    /// @param recipient The address of the recipient
    /// @param amount The amount to send
    function safeTransferFrom(
        IERC20 token,
        address owner,
        address recipient,
        uint256 amount
    ) internal {
        if (amount != 0) {
            (bool success, bytes memory result) = address(token).call(
                abi.encodeWithSelector(token.transferFrom.selector, owner, recipient, amount)
            );

            _catchTransferError(success, result);
        }
    }

    /// @notice Transfers token only if the amount is greater than zero
    /// @param token The address of the token
    /// @param recipient The address of the recipient
    /// @param amount The amount to send
    function safeTransfer(
        IERC20 token,
        address recipient,
        uint256 amount
    ) internal {
        if (amount != 0) {
            (bool success, bytes memory result) = address(token).call(
                abi.encodeWithSelector(token.transfer.selector, recipient, amount)
            );

            _catchTransferError(success, result);
        }
    }

    /// @notice Returns the amount of token received by the pair
    /// @param token The address of the token
    /// @param reserve The total reserve of token
    /// @param fees The total fees of token
    /// @return The amount received by the pair
    function received(
        IERC20 token,
        uint256 reserve,
        uint256 fees
    ) internal view returns (uint256) {
        uint256 _internalBalance;
        unchecked {
            _internalBalance = reserve + fees;
        }
        return token.balanceOf(address(this)) - _internalBalance;
    }

    /// @notice Private view function to catch the error and bubble it up if present
    /// @param success Whether the transaction succeeded or not
    /// @param result The result of the transaction
    function _catchTransferError(bool success, bytes memory result) private pure {
        // Look for revert reason and bubble it up if present
        if (!(success && (result.length == 0 || abi.decode(result, (bool))))) {
            assembly {
                revert(add(32, result), mload(result))
            }
        }
    }
}

// File: libraries/PendingOwnable.sol



pragma solidity ^0.8.0;

error PendingOwnable__NotOwner();
error PendingOwnable__NotPendingOwner();
error PendingOwnable__PendingOwnerAlreadySet();
error PendingOwnable__NoPendingOwner();
error PendingOwnable__AddressZero();

interface IPendingOwnable {
    event PendingOwnerSet(address indexed pendingOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function setPendingOwner(address pendingOwner) external;

    function revokePendingOwner() external;

    function becomeOwner() external;

    function renounceOwnership() external;
}

/// @title Pending Ownable
/// @author Trader Joe
/// @notice Contract module which provides a basic access control mechanism, where
/// there is an account (an owner) that can be granted exclusive access to
/// specific functions. The ownership of this contract is transferred using the
/// push and pull pattern, the current owner set a `pendingOwner` using
/// {setPendingOwner} and that address can then call {becomeOwner} to become the
/// owner of that contract. The main logic and comments comes from OpenZeppelin's
/// Ownable contract.
///
/// By default, the owner account will be the one that deploys the contract. This
/// can later be changed with {setPendingOwner} and {becomeOwner}.
///
/// This module is used through inheritance. It will make available the modifier
/// `onlyOwner`, which can be applied to your functions to restrict their use to
/// the owner
contract PendingOwnable is IPendingOwnable {
    address private _owner;
    address private _pendingOwner;

    /// @notice Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (msg.sender != _owner) revert PendingOwnable__NotOwner();
        _;
    }

    /// @notice Throws if called by any account other than the pending owner.
    modifier onlyPendingOwner() {
        if (msg.sender != _pendingOwner || msg.sender == address(0)) revert PendingOwnable__NotPendingOwner();
        _;
    }

    /// @notice Initializes the contract setting the deployer as the initial owner
    constructor() {
        _transferOwnership(msg.sender);
    }

    /// @notice Returns the address of the current owner
    /// @return The address of the current owner
    function owner() public view override returns (address) {
        return _owner;
    }

    /// @notice Returns the address of the current pending owner
    /// @return The address of the current pending owner
    function pendingOwner() public view override returns (address) {
        return _pendingOwner;
    }

    /// @notice Sets the pending owner address. This address will be able to become
    /// the owner of this contract by calling {becomeOwner}
    function setPendingOwner(address pendingOwner_) public override onlyOwner {
        if (pendingOwner_ == address(0)) revert PendingOwnable__AddressZero();
        if (_pendingOwner != address(0)) revert PendingOwnable__PendingOwnerAlreadySet();
        _setPendingOwner(pendingOwner_);
    }

    /// @notice Revoke the pending owner address. This address will not be able to
    /// call {becomeOwner} to become the owner anymore.
    /// Can only be called by the owner
    function revokePendingOwner() public override onlyOwner {
        if (_pendingOwner == address(0)) revert PendingOwnable__NoPendingOwner();
        _setPendingOwner(address(0));
    }

    /// @notice Transfers the ownership to the new owner (`pendingOwner).
    /// Can only be called by the pending owner
    function becomeOwner() public override onlyPendingOwner {
        _transferOwnership(msg.sender);
    }

    /// @notice Leaves the contract without owner. It will not be possible to call
    /// `onlyOwner` functions anymore. Can only be called by the current owner.
    ///
    /// NOTE: Renouncing ownership will leave the contract without an owner,
    /// thereby removing any functionality that is only available to the owner.
    function renounceOwnership() public override onlyOwner {
        _transferOwnership(address(0));
    }

    /// @notice Transfers ownership of the contract to a new account (`newOwner`).
    /// Internal function without access restriction.
    /// @param _newOwner The address of the new owner
    function _transferOwnership(address _newOwner) internal virtual {
        address _oldOwner = _owner;
        _owner = _newOwner;
        _pendingOwner = address(0);
        emit OwnershipTransferred(_oldOwner, _newOwner);
    }

    /// @notice Push the new owner, it needs to be pulled to be effective.
    /// Internal function without access restriction.
    /// @param pendingOwner_ The address of the new pending owner
    function _setPendingOwner(address pendingOwner_) internal virtual {
        _pendingOwner = pendingOwner_;
        emit PendingOwnerSet(pendingOwner_);
    }
}

// File: Faucet.sol



pragma solidity ^0.8.0;



/// @title Faucet contract
/// @author Trader Joe
/// @dev This contract should only be used for testnet
/// @notice Create a faucet contract that create test tokens and allow user to request for tokens.
/// This faucet will also provide AVAX if avax were sent to the contract (either during the construction or after).
/// This contract will not fail if its avax balance becomes too low, it will just not send AVAX but will mint the different tokens.
contract Faucet is PendingOwnable {
    using TokenHelper for IERC20;

    /// @dev Structure for faucet token, use only 1 storage slot
    struct FaucetToken {
        IERC20 ERC20;
        uint96 amountPerRequest;
    }

    /// @notice The address of the operator that can call request for other address
    address public operator;

    /// @notice The minimum time needed between 2 requests
    uint256 public requestCooldown;

    /// @notice last time a user has requested tokens
    mapping(address => uint256) public lastRequest;

    /// @notice faucet tokens set, custom to be able to use structures
    FaucetToken[] public faucetTokens;
    mapping(IERC20 => uint256) tokenToIndices;

    modifier onlyOperator() {
        require(msg.sender == operator, "Only operator");
        _;
    }

    modifier verifyRequest(address user) {
        require(block.timestamp >= lastRequest[user] + requestCooldown, "Too many requests");
        _;
    }

    /// @notice Constructor of the faucet, set the request cooldown and add avax to the faucet
    /// @param _avaxPerRequest The avax received per request
    /// @param _requestCooldown The request cooldown
    constructor(uint96 _avaxPerRequest, uint256 _requestCooldown) payable {
        _setRequestCooldown(_requestCooldown);
        _addFaucetToken(FaucetToken({ERC20: IERC20(address(0)), amountPerRequest: _avaxPerRequest}));
    }

    /// @notice Allows to receive AVAX directly
    receive() external payable {}

    /// @notice Returns the number of tokens given by the faucet
    function numberOfFaucetTokens() external view returns (uint256) {
        return faucetTokens.length;
    }

    /// @notice User needs to call this function in order to receive test tokens and avax
    /// @dev Can be called only once per `requestCooldown` seconds
    function request() external verifyRequest(msg.sender) {
        lastRequest[msg.sender] = block.timestamp;

        _request(msg.sender);
    }

    /// @notice User needs to call this function in order to receive test tokens and avax
    /// @dev Can be called only once per `requestCooldown` seconds for every address
    /// Can only be called by the operator
    /// @param _to The address that will receive the tokens
    function request(address _to) external onlyOperator verifyRequest(_to) {
        lastRequest[_to] = block.timestamp;

        _request(_to);
    }

    /// @notice Add a token to the faucet
    /// @dev Tokens need to be owned by the faucet, and only mintable by the owner
    /// @param _token The address of the token
    /// @param _amountPerRequest The amount per request
    function addFaucetToken(IERC20 _token, uint96 _amountPerRequest) external onlyOwner {
        _addFaucetToken(FaucetToken({ERC20: _token, amountPerRequest: _amountPerRequest}));
    }

    /// @notice Remove a token from the faucet
    /// @dev Token needs to be in the set, and AVAX can't be removed
    /// @param _token The address of the token
    function removeFaucetToken(IERC20 _token) external onlyOwner {
        uint256 index = tokenToIndices[_token];

        require(index >= 2, "Not a faucet token");

        uint256 lastIndex = faucetTokens.length - 1;
        if (--index != lastIndex) faucetTokens[index] = faucetTokens[lastIndex];

        delete faucetTokens[lastIndex];
        delete tokenToIndices[_token];
    }

    /// @notice Set the request cooldown for every users
    /// @dev This function needs to be called by the owner
    /// @param _requestCooldown The new cooldown
    function setRequestCooldown(uint256 _requestCooldown) external onlyOwner {
        _setRequestCooldown(_requestCooldown);
    }

    /// @notice Set the amount per request of a specific token, designated by its symbol
    /// @dev This function needs to be called by the owner
    /// @param _token The address of the token
    /// @param _amountPerRequest The new amount per request
    function setAmountPerRequest(IERC20 _token, uint96 _amountPerRequest) external onlyOwner {
        _setAmountPerRequest(_token, _amountPerRequest);
    }

    /// @notice Withdraw `amount` of token `token` to `to`
    /// @dev This function needs to be called by the owner
    /// @param _token The address of the token to withdraw
    /// @param _to The recipient address
    /// @param _amount The token amount to send
    function withdrawToken(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        if (address(_token) == address(0)) _sendAvax(_to, _amount);
        else _token.safeTransfer(_to, _amount);
    }

    /// @notice Set the address of the operator
    /// @param _newOperator The address of the new operator
    function setOperator(address _newOperator) external onlyOwner {
        operator = _newOperator;
    }

    /// @notice Private function to send faucet tokens to the user
    /// @dev Will only send tokens if the faucet has a sufficient balance
    /// @param _to The address that will receive the tokens
    function _request(address _to) private {
        uint256 len = faucetTokens.length;

        FaucetToken memory token = faucetTokens[0];

        if (token.amountPerRequest > 0 && address(this).balance >= token.amountPerRequest) {
            _sendAvax(_to, token.amountPerRequest);
        }

        for (uint256 i = 1; i < len; ++i) {
            token = faucetTokens[i];

            if (token.amountPerRequest > 0 && token.ERC20.balanceOf(address(this)) >= token.amountPerRequest)
                token.ERC20.safeTransfer(_to, token.amountPerRequest);
        }
    }

    /// @notice Private function to add a token to the faucet
    /// @dev Token needs to be not added to the set yet
    /// @param _token The token to add, using the FaucetToken structure
    function _addFaucetToken(FaucetToken memory _token) private {
        require(tokenToIndices[_token.ERC20] == 0, "Already a faucet token");

        faucetTokens.push(_token);
        tokenToIndices[_token.ERC20] = faucetTokens.length;
    }

    /// @notice Private function to set the request cooldown for every users
    /// @dev The new cooldown needs to be greater than 1 hour
    /// @param _requestCooldown The new cooldown
    function _setRequestCooldown(uint256 _requestCooldown) private {
        require(_requestCooldown >= 1 hours, "Unsafe request cooldown");

        requestCooldown = _requestCooldown;
    }

    /// @notice Private function to set the amount per request of a specific token, designated by its symbol
    /// @param _token The address of the token
    /// @param _amountPerRequest The new amount per request
    function _setAmountPerRequest(IERC20 _token, uint96 _amountPerRequest) private {
        uint256 index = tokenToIndices[_token];

        require(index != 0, "Not a faucet token");

        faucetTokens[index - 1].amountPerRequest = _amountPerRequest;
    }

    /// @notice Private function to send `amount` AVAX to `to`
    /// @param _to The recipient address
    /// @param _amount The AVAX amount to send
    function _sendAvax(address _to, uint256 _amount) private {
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "AVAX transfer failed");
    }
}