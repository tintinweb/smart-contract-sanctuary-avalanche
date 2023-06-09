/**
 *Submitted for verification at snowtrace.io on 2023-06-09
*/

// Sources flattened with hardhat v2.14.1 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
}


// File @openzeppelin/contracts/security/[email protected]

// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}


// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/PhaseableSale.sol

pragma solidity ^0.8.17;



/**
 * This smart contract acts as a decentralized sales unit for a specific token.
 * It supports the configuration of different sales phases with different prices
 * and different volumes.
 * Accepted payment options are USDT and USDC.
 */
contract PhaseableSale is Ownable, ReentrancyGuard {

    struct Phase {
        uint256 startTimestamp;
        uint256 endTimestamp;
        uint256 priceUsd;
        uint256 amountTotal;
        uint256 amountSold;
        bool closed;
    }

    uint256 public phaseCounter = 0;
    mapping(uint256 => Phase) private _idToPhase;

    IERC20 immutable token;

    modifier validPhaseId(uint256 id) {
        require(id <= phaseCounter, "Sale: Not a valid phasse id");
        _;
    }

    modifier phaseIsActive() {
       // check if at least 1 phase exits
        require(phaseCounter > 0, "Sale: No phase has been created.");

        // check if latest phase is not closed already
        Phase memory phase = _idToPhase[phaseCounter-1];
        require(!phase.closed, "Sale: Latest phase is already closed.");
        _;
    }

    constructor(address _token) {
        token = IERC20(_token);
    }

    /**
     * Get information on the phase with the specified id.
     * The id of the latest phase is `phaseCounter -1` or `0` for the very first phase.
     */
    function phaseInfo(uint256 id)
        public
        view
        validPhaseId(id)
        returns (Phase memory)
    {
        return _idToPhase[id];
    }

    /**
     * Create a new token sale phase. Make sure, that this contract owns at least
     * the amount of tokens of the specified phase sale amount.
     * @param priceUsd Price in USDT/C for 1 full token unit (10^18). 
     *                 Since USDT and USDC support 6 decimals uint, this needs to be be specified
     *                 with 6 decimals uint, which means a value of 1 USDT/C needs to be specified as `1000000`
     *                 or a value of 0.5 USDT/C needs to be specigied as `500000`.
     * @param amount Phase sale volume in the tokens decimals unit, which is 18 digits. 
     *               For example, a phase sale amount of 1000 full token units needs to be specified as 
     *               `1000 * 10^18`
     */
    function createPhase(
        uint256 priceUsd,
        uint256 amount
    ) external onlyOwner {
        
        // check if current phase is closed
        if (phaseCounter > 0){
            Phase memory prevPhase = phaseInfo(phaseCounter - 1);
            require(prevPhase.closed, "Sale: Current phase is not closed.");
        }

        // check if the sale contract owns enough tokens for the phases amount
        require(token.balanceOf(address(this)) >= amount, "Sale: Sale contract does not own enough tokens.");


        Phase memory phase = Phase(
            block.timestamp,
            0,
            priceUsd,
            amount,
            0,
            false
        );
        _idToPhase[phaseCounter] = phase;
        phaseCounter = phaseCounter + 1;
    }

    /**
     * Close the current phase.
     */
    function closePhase() external onlyOwner phaseIsActive {
        Phase memory phase = _idToPhase[phaseCounter-1];
        phase.endTimestamp = block.timestamp;
        phase.closed = true;

        _idToPhase[phaseCounter-1] = phase;
    }

    /**
     * Withdraw the specified amount of tokens from this sale contract
     * to its owner.
     */
    function withdrawTokens(uint256 amount) external onlyOwner {
        token.transfer(owner(), amount);
    }

    /**
     * Use USDT to purchase tokens according to the token price that is specified
     * by the currently active phase.
     * The customer needs to ensure, that they set the appropriate USDT allowance
     * for this sale contract.
     */
    function purchaseUsdt(uint256 invest) external nonReentrant phaseIsActive {
        IERC20(0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7).transferFrom(msg.sender, owner(), invest);
        _purchase(invest);
    }

    /**
     * Use USDC to purchase tokens according to the token price that is specified
     * by the currently active phase.
     * The customer needs to ensure, that they set the appropriate USDT allowance
     * for this sale contract.
     */
    function purchaseUsdc(uint256 invest) external nonReentrant phaseIsActive {
        IERC20(0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E).transferFrom(msg.sender, owner(), invest);
        _purchase(invest);
    }

    function _purchase(uint256 invest) private {

        // check sale phase balance
        Phase memory phase = _idToPhase[phaseCounter-1];
        uint256 tokenValue = (invest / phase.priceUsd) * 1 ether;
        require(
            tokenValue <= (phase.amountTotal - phase.amountSold),
            "Sale: Purchase amount exceeds phase supply."
        );

        // send tokens to recipient
        token.transfer(msg.sender, tokenValue);

        // update phase
        phase.amountSold = phase.amountSold + tokenValue;
        _idToPhase[phaseCounter-1] = phase;
    }

    /**
     * Send back any native currency that is sent to this contract.
     */
    receive() external payable {
        payable(msg.sender).transfer(msg.value);
    }
}