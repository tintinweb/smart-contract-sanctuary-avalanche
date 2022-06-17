//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IColosseum.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Grape Gladiator V2
/// @author cybertelx
/// Pour a glass of wine and watch it cut down the competition!
/// - Multiple tournament support: dual/tri/quad/∞-wielding guns
/// - Gelato resolver for efficient sniping
/// - "Asshole mode": Wait until X amount of time from "target enters".
/// This saves on costs (in case a war is occurring) and lulls target into a
/// false sense of security.
contract GrapeGladiatorBotV2 is Ownable {
    mapping(IERC20 => ITournament) public tokenToTournament;

    // if the token has ever been added to `tokens`
    // this does NOT mean it has a tournament now
    mapping(IERC20 => bool) public tokenExists;

    // note: this array may contain old tokens too
    // please check `tokenToTournament`
    IERC20[] public tokens;

    // big long name lol
    uint256 public timeToWaitAfterTargetEnters;

    // admins
    mapping(address => bool) authorized;

    mapping(address => bool) hitList;
    bool public evilAndKillEveryone;

    event Obliteration(
        address indexed noobObliterated,
        ITournament indexed tournament,
        IERC20 indexed token,
        uint256 ticketPrice
    );
    event TokenDataChanged(
        IERC20 indexed token,
        ITournament indexed tournament
    );

    modifier onlyAuthorized() {
        require(
            msg.sender == owner() || authorized[msg.sender],
            "unauthorized"
        );
        _;
    }

    constructor(
        address[] memory _killOnSight,
        address[] memory _authorized,
        IERC20[] memory _tokens,
        ITournament[] memory _tournaments,
        uint256 _timeToWaitAfterTargetEnters,
        bool evilness
    ) {
        for (uint256 i = 0; i < _killOnSight.length; i++) {
            hitList[_killOnSight[i]] = true;
        }

        for (uint256 i = 0; i < _authorized.length; i++) {
            authorized[_authorized[i]] = true;
        }

        require(_tokens.length == _tournaments.length, "array mismatch");

        tokens = _tokens;
        for (uint256 i = 0; i < _tokens.length; i++) {
            tokenToTournament[_tokens[i]] = _tournaments[i];
            tokenExists[tokens[i]] = true;
        }
        timeToWaitAfterTargetEnters = _timeToWaitAfterTargetEnters;
        evilAndKillEveryone = evilness;
    }

    // gelato resolver function
    function gelatoTournamentsResolver()
        public
        view
        returns (bool canExec, bytes memory)
    {
        address[] memory result = tournamentsToPwn();

        if (result[0] == address(0)) {
            return (false, bytes("No tournaments to take."));
        }

        return (
            true,
            abi.encodeWithSelector(this.fireSatelliteCannons.selector, result)
        );
    }

    function tournamentsToPwn() public view returns (address[] memory) {
        address[] memory result = new address[](tokens.length);

        uint256 x = 0;

        for (uint256 i = 0; i < tokens.length; i++) {
            // deprecated token, carry on
            if (address(tokenToTournament[tokens[i]]) == address(0)) {
                continue;
            }
            // not enough funds
            if (
                balance(tokens[i]) <
                tokenToTournament[tokens[i]].getTicketPrice()
            ) {
                continue;
            }
            // gladiator is innocent
            if (
                !isGladiatorALittlePieceOfShit(
                    tokenToTournament[tokens[i]].winner()
                )
            ) {
                continue;
            }
            // asshole mode (time)
            if (
                block.timestamp <=
                tokenToTournament[tokens[i]].lastTs() +
                    timeToWaitAfterTargetEnters
            ) {
                continue;
            }

            result[x] = address(tokens[i]);
            x++;
        }
        return result;
    }

    function balance(IERC20 token) public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function isGladiatorALittlePieceOfShit(address _winner)
        public
        view
        returns (bool)
    {
        return
            (evilAndKillEveryone && (_winner != msg.sender)) ||
            hitList[_winner];
    }

    // --------- ADMIN STUFF

    function setAuthorized(address user, bool authorization) public onlyOwner {
        authorized[user] = authorization;
    }

    function setTokenData(IERC20 token, ITournament tournament)
        public
        onlyAuthorized
    {
        // new non-duplicate token added to list
        if (!tokenExists[token]) {
            tokenExists[token] = true;
            tokens.push(token);
        }

        tokenToTournament[token] = tournament;
        emit TokenDataChanged(token, tournament);
    }

    function setTimeToWaitAfterTargetEnters(uint256 time)
        public
        onlyAuthorized
    {
        timeToWaitAfterTargetEnters = time;
    }

    function setEvilness(bool iamveryevil) external onlyAuthorized {
        evilAndKillEveryone = iamveryevil;
    }

    function setKillOnSightStatus(address victim, bool shouldSnipe)
        external
        onlyAuthorized
    {
        hitList[victim] = shouldSnipe;
    }

    function claimPglad(ITournament colosseum) external {
        colosseum.claimPglad();
    }

    function claimWinner(ITournament colosseum) external {
        colosseum.claimWinner();
    }

    function withdraw(IERC20 _token) external onlyAuthorized {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    function withdrawAVAX(uint256 avaxAmount) external onlyAuthorized {
        payable(msg.sender).transfer(avaxAmount);
    }

    // -------- NUCLEAR WEAPONS

    function fireSatelliteCannons(IERC20[] calldata _tokens) public {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (address(_tokens[i]) == address(0)) continue;
            enterColosseum(_tokens[i]);
        }
    }

    function enterColosseum(IERC20 _token) public {
        ITournament colosseum = tokenToTournament[_token];

        require(
            address(tokenToTournament[_token]) != address(0),
            "<> tournament not configured"
        );

        // Check if the current gladiator is a
        // little shit.
        require(
            isGladiatorALittlePieceOfShit(colosseum.winner()) &&
                colosseum.winner() != address(this),
            "Not a piece of shit"
        );

        // Check for asshole mode
        require(
            block.timestamp >= colosseum.lastTs() + timeToWaitAfterTargetEnters,
            "Wait a little more"
        );

        // Check if we even have enough cash to do this
        require(
            balance(_token) >= colosseum.getTicketPrice(),
            "More funding required"
        );
        _enterColosseum(_token);
    }

    function _enterColosseum(IERC20 _token) internal {
        ITournament colosseum = tokenToTournament[_token];

        emit Obliteration(
            colosseum.winner(),
            colosseum,
            _token,
            colosseum.getTicketPrice()
        );

        _token.approve(address(colosseum), colosseum.getTicketPrice());
        colosseum.buy();

        require(colosseum.winner() == address(this), "SEVERE BUG IN COLOSSEUM");
    }
}

pragma solidity ^0.8.0;

interface ITournament {
    function winner() external view returns (address); // returns address of the last bidder

    function claimed() external view returns (bool); // returns true if the winner has already claimed the prize

    function pgClaimed(address user) external view returns (bool); // returns true if the given user has already claimed his/her share in the prize as a pglad owner

    function lastTs() external view returns (uint256); // last buy time

    function CLAIM_PERIOD() external view returns (uint256); // reward can be claimed for this many time until expiration(latTs)

    function PERIOD() external view returns (uint256); // time to win

    function ROUND() external view returns (uint256); // time until first earning

    function BREAKEVEN() external view returns (uint256); // breakeven time after ROUND

    function TICKET_SIZE() external view returns (uint256); // 10000th of pot

    function POT_SHARE() external view returns (uint256); // 10000th of ticketprice

    function GLAD_SHARE() external view returns (uint256); // 10000th of ticketprice

    event TicketBought(
        uint256 timestamp,
        uint256 ticketPrice,
        address oldWinner,
        address newWinner,
        uint256 reward
    );
    event WinnerClaimed(uint256 timestamp, address winner, uint256 reward);
    event PgladBuyerClaimed(uint256 timestamp, address winner, uint256 reward);

    function getPotSize() external view returns (uint256); // returns actual pot size

    function getGladPotSize() external view returns (uint256); // returns total accumulated pglad pot size

    function getTicketPrice() external view returns (uint256); // return current ticket price

    function buy() external payable; // buy a ticket (token should be approved, if native then exact amount must be sent)

    function claimWinner() external; // winner can claim pot

    function claimPglad() external; // pglad buyers can claim their share (after whitelist pgladsale ended)

    function withdrawUnclaimed() external; // treasury can claim remaining afte CLAIM_PERIOD
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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