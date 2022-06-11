//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IColosseum.sol";
import "./IERC20.sol";

// Naughty naughty boi 0x99a2...812D
// Don't ruin the fun for everyone else,
// you stupid bot!

/// @title Grape Gladiator
/// Counter-bot against the guy who
/// is botting the colosseum.
/// @author cybertelx
contract GladiatorBotGelato {
    ITournament public colosseum;
    mapping(address => bool) peopleToKillOnSight;
    bool public evilAndKillEveryone;

    address public owner;
    address public dao;
    IERC20 public grape;

    event Obliteration(address noobObliterated, uint256 ticketPrice);

    modifier onlyOwnerOrDAO() {
        require(msg.sender == dao || msg.sender == owner);
        _;
    }

    constructor(
        ITournament _colosseum,
        IERC20 _grape,
        address[] memory _killOnSight,
        address _dao
    ) {
        for (uint256 i = 0; i < _killOnSight.length; i++) {
            peopleToKillOnSight[_killOnSight[i]] = true;
        }
        colosseum = _colosseum;
        grape = _grape;
        owner = msg.sender;
        dao = _dao;
    }

    function killOnSight() public {
        // Check if the current gladiator is a
        // total little shit.
        require(
            isGladiatorALittlePieceOfShit() &&
                colosseum.winner() != address(this),
            "Not a piece of shit"
        );
        // Check if we even have enough cash to do this
        require(
            grape.balanceOf(address(this)) >= colosseum.getTicketPrice(),
            "me need moar funding"
        );
        emit Obliteration(colosseum.winner(), colosseum.getTicketPrice());

        colosseum.buy();

        require(
            colosseum.winner() == address(this),
            "big bug, report to devs plox"
        );
    }

    function isGladiatorALittlePieceOfShit() public view returns (bool) {
        return
            (evilAndKillEveryone && (colosseum.winner() != msg.sender)) ||
            peopleToKillOnSight[colosseum.winner()];
    }

    function setEvilness(bool iamveryevil) external onlyOwnerOrDAO {
        evilAndKillEveryone = iamveryevil;
    }

    function setKillOnSightStatus(address victim, bool shouldikillthem)
        external
        onlyOwnerOrDAO
    {
        peopleToKillOnSight[victim] = shouldikillthem;
    }

    function setDAO(address _newDAO) external onlyOwnerOrDAO {
        dao = _newDAO;
    }

    // idfk what this does
    function claimPglad() external {
        colosseum.claimPglad();
    }

    // Claim prizes!
    function claimWinner() external {
        colosseum.claimWinner();
    }

    function withdraw(IERC20 _token) external onlyOwnerOrDAO {
        _token.transfer(msg.sender, _token.balanceOf(address(this)));
    }

    function withdrawAVAX(uint256 avaxAmount) external onlyOwnerOrDAO {
        payable(msg.sender).transfer(avaxAmount);
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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