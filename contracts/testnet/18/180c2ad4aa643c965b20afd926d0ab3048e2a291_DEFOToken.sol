/**
 *Submitted for verification at testnet.snowtrace.io on 2022-09-09
*/

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


// File @openzeppelin/contracts/security/[email protected]

 
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
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
    constructor() {
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
}


// File contracts/interfaces/ITransferLimiter.sol

 

pragma solidity 0.8.15;

/** @title  ILimiter, limiter for DEFO token transfer
  * @author Decentralized Foundation Team
*/

interface ITransferLimiter {
    function yieldGemTransferLimit(
        address to,
        address from,
        uint256 tokenId
    ) external;

    function DEFOTokenTransferLimit(
        address to,
        address from,
        uint256 amount
    ) external;
}


// File contracts/token/DEFOToken.sol

//SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;




/** @title  DEFO Token
  * @author Decentralized Foundation Team
  * @notice ERC20 with Dai-like gas-less approvals with EIP712 signatures, admin access, black lists, burnable, pausable, and recoverable if tokens are mistakely sent
*/

contract DEFOToken is Pausable, IERC20, IERC20Metadata {
    ITransferLimiter transferLimiter;

    mapping(address => uint256) private _balances;

    // @notice Admins list
    mapping(address => uint256) public wards;

    // @notice Blacklist
    mapping(address => bool) public blacklist;

    // --- ERC20 Data ---
    string public constant name = "DEFO Token";
    string public constant symbol = "DEFO";
    string public constant version = "1";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;
    bool public initialized;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;


    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    /* ============ External and Public Functions ============ */

    modifier auth() {
        require(wards[_msgSender()] == 1, "DEFOToken:not-authorized");
        _;
    }

    constructor(uint256 chainId_) {
    }

    function initialize(uint256 chainId_) external {
        if (!initialized) {
            initialized = true;
            wards[_msgSender()] = 1;
            DOMAIN_SEPARATOR = keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256(bytes(version)),
                    chainId_,
                    address(this)
                )
            );
        }
    }


    // --- Token ---

    function transfer(address dst, uint256 wad) external returns (bool) {
        return transferFrom(_msgSender(), dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(!paused(), "DEFOToken:paused");
        require(balanceOf[src] >= wad, "DEFOToken:insufficient-balance");
        require(!blacklist[src] && !blacklist[dst], "DEFOToken:blacklisted");
        if (wards[_msgSender()] != 1 && wards[src] != 1 && address(transferLimiter) != address(0))
            transferLimiter.DEFOTokenTransferLimit(src, dst, wad);
        if (src != _msgSender() && allowance[src][_msgSender()] != type(uint256).max) {
            require(allowance[src][_msgSender()] >= wad, "DEFOToken:insufficient-allowance");
            allowance[src][_msgSender()] = sub(allowance[src][_msgSender()], wad);
        }
        balanceOf[src] = sub(balanceOf[src], wad);
        balanceOf[dst] = add(balanceOf[dst], wad);
        emit Transfer(src, dst, wad);
        return true;
    }


    function burn(address usr, uint256 wad) external {
        require(balanceOf[usr] >= wad, "DEFOToken:insufficient-balance");
        if (usr != _msgSender() && allowance[usr][_msgSender()] != type(uint256).max) {
            require(allowance[usr][_msgSender()] >= wad, "DEFOToken:insufficient-allowance");
            allowance[usr][_msgSender()] = sub(allowance[usr][_msgSender()], wad);
        }
        balanceOf[usr] = sub(balanceOf[usr], wad);
        totalSupply = sub(totalSupply, wad);
        emit Transfer(usr, address(0), wad);
    }

    function approve(address usr, uint256 wad) external returns (bool) {
        allowance[_msgSender()][usr] = wad;
        emit Approval(_msgSender(), usr, wad);
        return true;
    }

    // --- Approve by signature ---
    function permit(
        address holder,
        address spender,
        uint256 nonce,
        uint256 expiry,
        bool allowed,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, holder, spender, nonce, expiry, allowed))
            )
        );

        require(holder != address(0), "DEFOToken:invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "DEFOToken:invalid-permit");
        require(expiry == 0 || block.timestamp <= expiry, "DEFOToken:permit-expired");
        require(nonce == nonces[holder]++, "DEFOToken:invalid-nonce");
        uint256 wad = allowed ? type(uint256).max : 0;
        allowance[holder][spender] = wad;
        emit Approval(holder, spender, wad);
    }

    /* ============ External and Public Admin Functions ============ */

    function linkDiamond(ITransferLimiter _transferLimiter) external auth {
        transferLimiter = _transferLimiter;
    }

    function mint(address usr, uint256 wad) external auth {
        balanceOf[usr] = add(balanceOf[usr], wad);
        totalSupply = add(totalSupply, wad);
        emit Transfer(address(0), usr, wad);
    }

    // @notice Grant access
    // @param guy admin to grant auth
    function rely(address guy) external auth {
        wards[guy] = 1;
    }

    // @notice Deny access
    // @param guy deny auth for
    function deny(address guy) external auth {
        wards[guy] = 0;
    }


    // Recovering lost tokens and avax
    function recoverLostDEFO(
        address _token,
        address _to,
        uint256 _amount
    ) external auth {
        IERC20(_token).transfer(_to, _amount);
    }

    function recoverLostAVAX(address _to) external auth {
        payable(_to).transfer(address(this).balance);
    }

    function updateBlacklist(address _address, bool _allow) external auth {
        blacklist[_address] = _allow;
    }

    function pause() external auth {
        _pause();
    }

    function unpause() external auth {
        _unpause();
    }

    function getLinkedDiamond() external view returns (ITransferLimiter) {
        return transferLimiter;
    }

    function authorized(address guy) external view returns (bool) {
        return wards[guy] == 1;
    }
    /* ============ Internal Functions ============ */

    // --- Math ---
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

}