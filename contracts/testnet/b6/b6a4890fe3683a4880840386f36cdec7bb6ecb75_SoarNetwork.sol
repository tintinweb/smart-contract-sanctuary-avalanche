/**
 *Submitted for verification at testnet.snowtrace.io on 2022-10-13
*/

// File: contracts/SoarNetwork.sol

// Sources flattened with hardhat v2.12.0 https://hardhat.org
// SPDX-License-Identifier: MIT
// File @openzeppelin/contracts/utils/[email protected]


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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

 
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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


// File @openzeppelin/contracts/token/ERC20/[email protected]

 
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;



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
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
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


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]

 
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
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


// File contracts/SoarNetwork.sol

 

pragma solidity ^0.8.9;



// Tasks:
// 1. Register client
// 2. Register challenger
// 3. Keep scores
// 4. Reward/punish transactions
// 5. Store signatures from bulk data
// 6. Unregister client/challenger

contract SoarNetwork is ERC20, ERC20Burnable, Ownable {
    // Tokenomics:
    uint256 public MAX_SUPPLY = 1_700_000_000 * 10**decimals();
    uint256 public CLIENT_OPERATIONS_FEE = 25 * 10**decimals();
    uint256 public MIN_STAKE_REQ_CHALLENGER = 2000 * 10**decimals();
    uint256 public CLIENT_REWARD_BASE = 3;
    uint256 public CHALLENGER_REWARD_BASE = 1;

    // State Vars
    uint256 public totalClients;
    uint256 public totalChallengers;

    uint256 public totalMintedSoar;

    struct Client {
        address clientAddress;
        bool isRegistered;
        uint256 score;
        uint256 timeRegistered;
    }

    mapping(address => Client) public registeredClients;

    struct Challenger {
        address challengerAddress;
        bool isRegistered;
        uint256 stakeAmount;
        uint256 score;
        uint256 timeRegistered;
    }

    mapping(address => Challenger) public registeredChallengers;

    // STORAGE ELEMENTS:
    // RxClaim
    mapping(bytes32 => bytes) public RxClaimStorage; // hash => signature
    // RxChallenge
    mapping(bytes32 => bytes) public RxChallengeStorage; // hash => signature
    // RxChallengeResponse
    mapping(bytes32 => bytes) public RxChallengeResponseStorage; // hash => signature
    // BxChallenge
    mapping(bytes32 => bytes) public BxChallengeStorage; // hash => signature
    // BxChallengeResponsePacket
    mapping(bytes32 => bytes) public BxChallengeResponseStorage; // hash => signature

    // CONSTRUCTOR:
    constructor() ERC20("SoarToken", "SOAR") {
        mintSoar(msg.sender, 5000); // initial token allocation to deployer
    }

    function registerClient(address clientAddr) external {
        require(
            registeredClients[clientAddr].isRegistered == false,
            "Client is already registered!"
        );
        require(
            balanceOf(msg.sender) >= CLIENT_OPERATIONS_FEE,
            "Insufficient funds for registration!"
        );

        // BURN REGISTRATION FEE
        _burn(msg.sender, CLIENT_OPERATIONS_FEE);

        // SAVE THE CLIENT
        registeredClients[clientAddr] = Client(
            clientAddr,
            true,
            25,
            block.timestamp
        );

        totalClients++;
    }

    function registerChallenger(address challengerAddr, uint256 stakeAmount)
        external
    {
        require(
            registeredChallengers[challengerAddr].isRegistered == false,
            "Challenger is already registered"
        );
        require(
            stakeAmount >= MIN_STAKE_REQ_CHALLENGER,
            "Min 2000 Soar required for staking!"
        );
        require(
            balanceOf(msg.sender) >= stakeAmount,
            "Sender doesn't have the stakeAmount!"
        );

        // SEND TOKENS TO CONTRACT
        transfer(address(this), stakeAmount);

        registeredChallengers[challengerAddr] = Challenger(
            challengerAddr,
            true,
            stakeAmount,
            25,
            block.timestamp
        );

        totalChallengers++;
    }

    function unregisterClient() external {
        // onlyOwner or client address can unregister
        require(
            registeredChallengers[msg.sender].isRegistered == true,
            "Client is not registered!"
        );
        require(
            balanceOf(msg.sender) >= CLIENT_OPERATIONS_FEE,
            "Insufficient funds for unregistration!"
        );

        // BURN THE UNREGISTRATION FEE
        _burn(msg.sender, CLIENT_OPERATIONS_FEE);

        // REMOVE THE CLIENT
        registeredClients[msg.sender] = Client(address(0), false, 0, 0);
    }

    function unregisterChallenger() external {
        // onlyOwner or client address can unregister
        require(
            registeredChallengers[msg.sender].isRegistered == true,
            "Challenger is not registered!"
        );

        uint256 stakedAmount = registeredChallengers[msg.sender].stakeAmount;
        require(
            balanceOf(address(this)) >= stakedAmount,
            "Insufficient funds in the contract!"
        );

        // REFUND STAKING AMOUNT WITH 20% PENALTY
        uint256 stakeRefund = (stakedAmount * 8) / 10; // 20% slashing
        transfer(msg.sender, stakeRefund);

        // REMOVE THE CHALLENGER
        registeredChallengers[msg.sender] = Challenger(
            address(0),
            false,
            0,
            0,
            0
        );
    }

    function mintSoar(address _to, uint256 amount) public onlyOwner {
        require(totalMintedSoar <= MAX_SUPPLY, "Max Soar supply is reached!");
        _mint(_to, amount * 10**decimals());
        totalMintedSoar += amount * 10**decimals();
    }

    // Getters
    function getClientScore(address clientAddr) public view returns (uint256) {
        return registeredClients[clientAddr].score;
    }

    function getChallengerScore(address challengerAddr)
        public
        view
        returns (uint256)
    {
        return registeredChallengers[challengerAddr].score;
    }

    function getSoarBalance(address addr) public view returns (uint256) {
        return balanceOf(addr);
    }

    // CHALLENGE SERVICE FUNCTIONS
    function verifyMerkleProof(
        bytes32 root,
        bytes32 leaf,
        bytes32[] memory proof,
        uint256 index
    ) public pure returns (bool) {
        bytes32 hash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (index % 2 == 0) {
                hash = keccak256(abi.encodePacked(hash, proofElement));
            } else {
                hash = keccak256(abi.encodePacked(proofElement, hash));
            }

            index = index / 2;
        }

        return hash == root;
    }

    // 1. message to sign
    // 2. hash(message)
    // 3. sign(hash(message), private key) -> this is offchain (done by the wallet)
    // 4. ecrecover(hash(message), signature) == signer
    function verifySignature(
        address signer,
        string memory message,
        bytes memory signature
    ) public pure returns (bool) {
        bytes32 messageHash = getMessageHash(message);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recover(ethSignedMessageHash, signature) == signer;
    }

    function getMessageHash(string memory message)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(message));
    }

    function getEthSignedMessageHash(bytes32 messageHash)
        public
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    messageHash
                )
            );
    }

    function recover(bytes32 ethSignMessageHash, bytes memory signature)
        public
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _split(signature);
        return ecrecover(ethSignMessageHash, v, r, s);
    }

    function _split(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "Invalid signature length!");
        // signature is dynamic data
        // first 32 bytes stores length of data
        // this sig here is not the real pointer but it's a pointer to memory location of the stored real signature
        assembly {
            r := mload(add(sig, 32)) // skip the first 32-bytes which holds length of the data
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96))) // just get the first byte (from the 32bytes returned from mload) at index 0
        }
    }

    // 1. Whole challenge process must be completed in a single transaction
    // 2. Packets should be parsed in client side and each data field should be sent as a separate input
    // 3. For each packet, signature verification must be completed
    // 4. Merkle Tree Proof should be done for RxChallengeResponsePacket and BxChallengeResponsePacket
    // 5. Punish or Reward transactions for Bx, Rx and Challenger must be done
    // 6. Only registered challengers are allowed to send this transaction, only registered clients can be challenged
    // function challengeService(
    //     address RxClaimSigner,
    //     string memory RxClaimData,
    //     bytes memory RxClaimSig,
    //     address RxChallengeSigner,
    //     string memory RxChallengeData,
    //     bytes memory RxChallengeSig,
    //     address RxChallengeResponseSigner,
    //     string memory RxChallengeResponseData,
    //     bytes memory RxChallengeResponseSig,
    //     address BxChallengeSigner,
    //     string memory BxChallengeData,
    //     bytes memory BxChallengeSig,
    //     address BxChallengeResponseSigner1,
    //     string memory BxChallengeResponseData1,
    //     bytes memory BxChallengeResponseSig1,
    //     address BxChallengeResponseSigner2,
    //     string memory BxChallengeResponseData2,
    //     bytes memory BxChallengeResponseSig2,
    //     address BxChallengeResponseSigner3,
    //     string memory BxChallengeResponseData3,
    //     bytes memory BxChallengeResponseSig3,
    //     bytes32 rxResponseRoot1,
    //     bytes32 rxResponseLeaf1,
    //     bytes32[] memory rxResponseProof1,
    //     bytes32 rxResponseRoot2,
    //     bytes32 rxResponseLeaf2,
    //     bytes32[] memory rxResponseProof2,
    //     bytes32 rxResponseRoot3,
    //     bytes32 rxResponseLeaf3,
    //     bytes32[] memory rxResponseProof3,
    //     bytes32 bxResponseRoot1,
    //     bytes32 bxResponseLeaf1,
    //     bytes32[] memory bxResponseProof1,
    //     bytes32 bxResponseRoot2,
    //     bytes32 bxResponseLeaf2,
    //     bytes32[] memory bxResponseProof2,
    //     bytes32 bxResponseRoot3,
    //     bytes32 bxResponseLeaf3,
    //     bytes32[] memory bxResponseProof3
    // ) public returns (bool) {
    //     require(
    //         registeredChallengers[msg.sender].isRegistered == true,
    //         "Only challengers can initiate challenge transactions!"
    //     );
    //     require(registeredClients[RxClaimSigner].isRegistered == true, "Only registered clients can be challenged!");
    //     require(registeredClients[BxChallengeResponseSigner1].isRegistered == true, "Only registered clients can be challenged!");
    //     require(registeredClients[BxChallengeResponseSigner2].isRegistered == true, "Only registered clients can be challenged!");
    //     require(registeredClients[BxChallengeResponseSigner3].isRegistered == true, "Only registered clients can be challenged!");

    //     require(verifySignature(RxClaimSigner, RxClaimData, RxClaimSig) == true, "RxClaim signature couldn't be verified!");
    //     require(verifySignature(RxChallengeSigner, RxChallengeData, RxChallengeSig) == true, "RxChallenge signature couldn't be verified!");
    //     require(verifySignature(RxChallengeResponseSigner, RxChallengeResponseData, RxChallengeResponseSig) == true, "RxChallengeResponse signature couldn't be verified!");
    //     require(verifySignature(BxChallengeSigner, BxChallengeData, BxChallengeSig) == true, "BxChallenge signature couldn't be verified!");
    //     require(verifySignature(BxChallengeResponseSigner1, BxChallengeResponseData1, BxChallengeResponseSig1) == true, "BxChallengeResponse signature-1 couldn't be verified!");
    //     require(verifySignature(BxChallengeResponseSigner2, BxChallengeResponseData2, BxChallengeResponseSig2) == true, "BxChallengeResponse signature-2 couldn't be verified!");
    //     require(verifySignature(BxChallengeResponseSigner3, BxChallengeResponseData3, BxChallengeResponseSig3) == true, "BxChallengeResponse signature-3 couldn't be verified!");
    //     // require(verifyMerkleProof(rxResponseRoot1, rxResponseLeaf1, rxResponseProof1) == true , "RxChallengeResponse leaf-1 Merkle Tree proof error!");
    //     // require(verifyMerkleProof(rxResponseRoot2, rxResponseLeaf2, rxResponseProof2) == true , "RxChallengeResponse leaf-2 Merkle Tree proof error!");
    //     // require(verifyMerkleProof(rxResponseRoot3, rxResponseLeaf3, rxResponseProof3) == true , "RxChallengeResponse leaf-3 Merkle Tree proof error!");
    //     // require(verifyMerkleProof(bxResponseRoot1, bxResponseLeaf1, bxResponseProof1) == true , "BxChallengeResponse leaf-1 Merkle Tree proof error!");
    //     // require(verifyMerkleProof(bxResponseRoot2, bxResponseLeaf2, bxResponseProof2) == true , "BxChallengeResponse leaf-2 Merkle Tree proof error!");
    //     // require(verifyMerkleProof(bxResponseRoot3, bxResponseLeaf3, bxResponseProof3) == true , "BxChallengeResponse leaf-3 Merkle Tree proof error!");

    //     bool rxSuccess;
    //     bool bxSuccess;

    //     // RX Merkle Proof Check
    //     if( verifyMerkleProof(rxResponseRoot1, rxResponseLeaf1, rxResponseProof1, 0) &&
    //         verifyMerkleProof(rxResponseRoot2, rxResponseLeaf2, rxResponseProof2, 0) &&
    //         verifyMerkleProof(rxResponseRoot3, rxResponseLeaf3, rxResponseProof3, 0)) {
    //         rxSuccess = true;
    //         mintSoar(RxClaimSigner, CLIENT_REWARD_BASE);    // reward client
    //         registeredClients[RxClaimSigner].score++;
    //     } else {
    //         rxSuccess = false;
    //         registeredClients[RxClaimSigner].score--;
    //         return false;
    //     }

    //     // BX Merkle Proof Check
    //     if( verifyMerkleProof(bxResponseRoot1, bxResponseLeaf1, bxResponseProof1, 0) &&
    //         verifyMerkleProof(bxResponseRoot2, bxResponseLeaf2, bxResponseProof2, 0) &&
    //         verifyMerkleProof(bxResponseRoot3, bxResponseLeaf3, bxResponseProof3, 0)) {
    //         bxSuccess = true;
    //         mintSoar(BxChallengeResponseSigner1, CLIENT_REWARD_BASE);    // reward client
    //         registeredClients[BxChallengeResponseSigner1].score++;
    //     } else {
    //         bxSuccess = false;
    //         registeredClients[BxChallengeResponseSigner1].score--;
    //         return false;
    //     }

    //     // Reward Challenger
    //     mintSoar(msg.sender, CHALLENGER_REWARD_BASE);
    //     registeredChallengers[msg.sender].score++;

    //     return true;
    // }
}