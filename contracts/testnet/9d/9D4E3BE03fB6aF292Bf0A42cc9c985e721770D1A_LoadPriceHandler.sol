/**
 *Submitted for verification at testnet.snowtrace.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT
// File: contracts/libraries/ILoadPriceHandler.sol


// DragonCryptoGaming - Legend of Aurum Draconis Contract Libaries

pragma solidity ^0.8.14;

/**
 * @dev Interfact 
 */
interface ILoadPriceHandler {
    function tokenCostDCARBond(
        address tokenAddress,
        uint256 discount
    ) external view
    returns (uint256);

    function totalCostHeal( uint256 amount ) external view returns (uint256);

    function costToResurrect( uint256 level ) external view returns (uint256);

    function bardSongCost( ) external view returns (uint256);

    function innRestCost( uint256 level ) external view returns (uint256);
}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: contracts/core/LoadPriceHandler.sol


pragma solidity ^0.8.14;




contract LoadPriceHandler is ReentrancyGuard, Ownable, ILoadPriceHandler {
    event TokenPriceUpdated(address indexed sender, address indexed token, uint256 indexed newPrice);
    event HealingDollarsPerHPUpdated(address indexed sender, uint256 indexed newPrice);
    event ResurrectionDollarsUpdated(address indexed sender, uint256 indexed newPrice);
    event BardSongDollarsUpdated(address indexed sender, uint256 indexed newPrice);
    event InnRestDollarsUpdated(address indexed sender, uint256 indexed newPrice);
    event TokenDollarsRewardPerLevelUpdated(address indexed sender, uint256 indexed newPrice);
    event DCARBondPriceUpdated(address indexed sender, uint256 indexed newPrice);

    address public immutable PRICE_ORACLE;

    uint256 public constant DOLLAR_DECIMALS = 10000;

    uint256 public HEALING_DOLLARS_PER_HP = 25;

    uint256 public RESURRECTION_DOLLARS_PER_LEVEL = 2500;

    uint256 public BARD_SONG_DOLLARS = 1 * DOLLAR_DECIMALS;

    uint256 public INN_REST_DOLLARS = 3 * DOLLAR_DECIMALS;

    uint256 public INN_REST_LEVEL_MULTIPLIER_DOLLARS = 25;

    uint256 public TOKEN_DOLLARS_REWARD_PER_LEVEL = 20;

    uint256 public DCAR_BOND_PRICE = 1000000;

    address public immutable DCAR_CONTRACT_ADDRESS;
    address public immutable DCAU_CONTRACT_ADDRESS;

    mapping( address => uint256 ) public TokensPerDollar;

    constructor(
        address priceOracle,
        address dcauContract,
        address dcarContract
    ) {
        require(priceOracle != address(0), "must be valid address");
        require(dcauContract != address(0), "must be valid address");
        require(dcarContract != address(0), "must be valid address");

        PRICE_ORACLE = priceOracle;
        DCAU_CONTRACT_ADDRESS = dcauContract;
        DCAR_CONTRACT_ADDRESS = dcarContract;
    }

    function setHealingPrice(uint256 amount) public onlyOwner {
        require(amount > 0, "CANNOT_BE_ZERO");

        HEALING_DOLLARS_PER_HP = amount;

        emit HealingDollarsPerHPUpdated(msg.sender, amount);
    }

    function setResurrectionPricePerLevel(uint256 amount) public onlyOwner {
        require(amount > 0, "CANNOT_BE_ZERO");

        RESURRECTION_DOLLARS_PER_LEVEL = amount;

        emit ResurrectionDollarsUpdated(msg.sender, amount);
    }

    function setBardSongPrice(uint256 amount) public onlyOwner {
        require(amount > 0, "CANNOT_BE_ZERO");

        BARD_SONG_DOLLARS = amount;

        emit BardSongDollarsUpdated(msg.sender, amount);
    }

    function setInnRestPrice(uint256 amount) public onlyOwner {
        require(amount > 0, "CANNOT_BE_ZERO");

        INN_REST_DOLLARS = amount;

        emit InnRestDollarsUpdated(msg.sender, amount);
    }

    function setRewardPerLevelPrice(uint256 amount) public onlyOwner {
        require(amount > 0, "CANNOT_BE_ZERO");

        TOKEN_DOLLARS_REWARD_PER_LEVEL = amount;

        emit TokenDollarsRewardPerLevelUpdated(msg.sender, amount);
    }

    function setTokenPricePerDollar(address tokenAddress, uint256 amountPerDollar) public {
        require( tokenAddress != address(0), "INVALID_TOKEN_ADDRESS" );
        require( msg.sender == PRICE_ORACLE, "ORACLE_ONLY" );
        
        TokensPerDollar[tokenAddress] = amountPerDollar;


        emit TokenPriceUpdated(msg.sender, tokenAddress, amountPerDollar);
    }

    function setDCARBondPrice(uint256 priceInDollars) public {
        require( msg.sender == PRICE_ORACLE, "ORACLE_ONLY" );
        
        DCAR_BOND_PRICE = priceInDollars;

        emit DCARBondPriceUpdated(msg.sender, priceInDollars);
    }

    function tokensPerDollar( address tokenAddress ) public view returns (uint256) {
        require( tokenAddress != address(0), "INVALID_TOKEN_ADDRESS" );
        require( TokensPerDollar[tokenAddress] > 0, "PRICE_NOT_SET" );
        return TokensPerDollar[tokenAddress];
    }

    function tokenCostDCARBond( address tokenAddress, uint256 discount ) external view returns (uint256) {
        uint256 totalTokenCost = TokensPerDollar[tokenAddress] * DCAR_BOND_PRICE;
        uint256 discountInTokens = ( ( totalTokenCost * ( 1000 + discount ) / 1000 ) - totalTokenCost );
        uint256 discountedTokenPrice = totalTokenCost - discountInTokens;

        return discountedTokenPrice;
    }

    function totalCostHeal( uint256 amount ) external view returns (uint256) {
        uint256 costInDollars = HEALING_DOLLARS_PER_HP * amount;
        return ( costInDollars * TokensPerDollar[DCAU_CONTRACT_ADDRESS] ) / DOLLAR_DECIMALS;
    }

    function costToResurrect( uint256 level ) external view returns (uint256) {
        uint256 costInDollars = RESURRECTION_DOLLARS_PER_LEVEL * level;
        return ( costInDollars * TokensPerDollar[DCAU_CONTRACT_ADDRESS] ) / DOLLAR_DECIMALS;
    }

    function bardSongCost( ) external view returns (uint256) {
        return ( BARD_SONG_DOLLARS * TokensPerDollar[DCAU_CONTRACT_ADDRESS] ) / DOLLAR_DECIMALS;
    }

     function innRestCost( uint256 level ) external view returns (uint256) {
        uint256 levelCostDollars = INN_REST_LEVEL_MULTIPLIER_DOLLARS * level;
        return ( ( INN_REST_DOLLARS + levelCostDollars ) * TokensPerDollar[DCAU_CONTRACT_ADDRESS] ) / DOLLAR_DECIMALS;
    }

    // amount in dollars is 4 decimal digits, 1 dollar is 10000, 50 cents is 5000, 5 cents is 500, 0.5 cents is 50, 0.005 cents is 5
    function costFromStableCost( address tokenAddress, uint256 amountInDollars ) public view returns (uint256) {
        require( tokenAddress != address(0), "INVALID_TOKEN_ADDRESS" );
        require( TokensPerDollar[tokenAddress] > 0, "PRICE_NOT_SET" );

        return ( amountInDollars * TokensPerDollar[tokenAddress] ) / DOLLAR_DECIMALS;
    }
}