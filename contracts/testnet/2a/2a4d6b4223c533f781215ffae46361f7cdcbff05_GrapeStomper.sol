/**
 *Submitted for verification at testnet.snowtrace.io on 2022-07-28
*/

// SPDX-License-Identifier: UNLICENSED
// File: utils/Context.sol


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

// File: ERC20/IERC20.sol


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

// File: ERC20/extensions/IERC20Metadata.sol


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

// File: ERC20/ERC20.sol


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

// File: main.sol



pragma solidity ^0.8.15;


// Interface for the GrapeRewardsPool
interface GrapeRewardsPool {
    function pendingShare(uint256 pid, address user) external view returns(uint256);
    function deposit(uint256 pid, uint256 amount) external;
    function withdraw(uint256 _pid, uint256 _amount) external;
}

// Interface for the TraderJoeXYZ Router
interface TraderJoe {
    function SwapExactTokensforAVAX(uint256 amountIn, uint256 amountOutMin, address[] memory path, address to, uint256 deadline) external;
}

// Main
contract GrapeStomper {
    
    // Contracts for tokens
    address grapeToken = address(0x5541D83EFaD1f281571B343977648B75d95cdAC2); // Contract address for GRAPE
    address wineToken = address(0xC55036B5348CfB45a932481744645985010d3A44); // Contract address for WINE
    address mimToken = address(0x130966628846BFd36ff31a822705796e8cb8C18D); // Contract address for MIM
    address wavaxToken = address(0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7); // Contract address for WAVAX

    // Contracts for GRAPE rewards and TraderJoe
    address stakeContract = address(0x28c65dcB3a5f0d456624AFF91ca03E4e315beE49); // Contract address of the GRAPE Reward Pools
    address joeRouter = address(0x60aE616a2155Ee3d9A68541Ba4544862310933d4); // TraderJoe XYZ router

    // Contract owner
    address owner;
    address dev;
    bool doStake;
    bool doTrade;

    // Leaderboard and score state variables
    mapping(address=>uint256) highScores;
    mapping(address=>bytes32) activeGames;
    struct scoreEntry {
        address player;
        uint256 score;
    }
    uint256 costToPlay;
    scoreEntry[10] leaderboard;

    // TODO - Remove tokenAddress when deploying to mainnet
    constructor(address tokenAddress, address devAddress) {
        owner = msg.sender;
        dev = devAddress;
        grapeToken = address(tokenAddress);
        costToPlay = 5*1e17;
    }

    modifier ownerOnly {
        require(msg.sender == owner, "[Ownable] Access Denied");
        _;
    }

    function getOwner() public view returns(address) {
        return owner;
    }

    function setOwner(address newOwner) public ownerOnly {
        require(newOwner != address(0), "[Address] Address cannot be 0");
        owner = newOwner;
    }

    modifier devOnly {
        require(msg.sender == dev, "[Ownable] Access Denied");
        _;
    }

    function getDev() public view returns(address) {
        return dev;
    }

    function setDev(address newDev) public ownerOnly devOnly {
        require(newDev != address(0), "[Address] Address cannot be 0");
        dev = newDev;
    }

    /*
        Update the cost to play the game, minimum cost is .01 GRAPE
    */
    function setCost(uint256 newCost) public ownerOnly devOnly {
        require(newCost >= 1e16, "[Cost] Cost to play must be more than 1e16");
        costToPlay = newCost;
    }

    /*
        Toggles whether the contract will deposit the grape
        into the Grape Single Staking Reward Pool
    */
    function toggleStake() public ownerOnly returns(bool) {        
        doStake = !doStake;
        return doStake;
    }

    /*
        Toggles whether the contract will sell the wine
        for AVAX using the TraderJoe router
    */
    function toggleTrade() public ownerOnly returns(bool) {
        doTrade = !doTrade;
        return doTrade;
    }

    // Returns the amount of GRAPE currently in the winnings pot
    function getPot() public view returns(uint256) {
        ERC20 GRAPE = ERC20(grapeToken);
        return GRAPE.balanceOf(address(this));
    }

    /* 
        Deposit grape into the contract to start the game
    */
    function deposit() public returns(bytes32) {                
        ERC20 GRAPE = ERC20(grapeToken);
        require(GRAPE.allowance(msg.sender, address(this)) >= costToPlay, "[Allowance] Please approve the game contract to spend 1 GRAPE");
        GRAPE.transferFrom(msg.sender, address(this), costToPlay);
        activeGames[msg.sender] = keccak256(abi.encode(msg.sender, block.number));
        return activeGames[msg.sender];
    }

    // Record a users score to the global array and leaderboard
    function recordScore(bytes32 hash, uint256 score) public {
        //require(player != address(0), "[Address] Player address cannot be 0");
        require(score >= 1, "[Score] Minimum score must be above 0");
        require(activeGames[msg.sender] == hash, "[Game] User doesn't have any active games...");

        // Clear the hash for this players game
        activeGames[msg.sender] = 0;

        // Update individual player high score
        if(score > highScores[msg.sender])
            highScores[msg.sender] = score;

        // Check to see if the user already has a score on the leaderboard
        // and remove it if his new score is better. 
        for(uint i = 0; i < 10; i++) {
            if(leaderboard[i].player == msg.sender) {
                if(leaderboard[i].score > score)
                    return;
                // Shift existing entries up
                for(uint j = i; j < 9; j++)
                    leaderboard[j] = leaderboard[j+1];
                // Clear the duplicate final entry
                leaderboard[9].player = address(0);
                leaderboard[9].score = 0;                
            }
        }

        // Check player score against the leaderboard scores
        for(uint i = 0; i < 10; i++) {
            // If this entry is blank fill it and break
            if(leaderboard[i].player == address(0)) {
                leaderboard[i].player = msg.sender;
                leaderboard[i].score = score;                
                break;
            }
            // If this entry is greater than another entry
            // shift it down and put this entry in its place
            else if(score > leaderboard[i].score) {
                // Shift
                for(uint j = 9; j > i; j--)
                    leaderboard[j] = leaderboard[j-1];

                leaderboard[i].player = msg.sender;
                leaderboard[i].score = score;
                break;
            }
        }
    }

    /*
        Runs every 7 days via autonomous docker instance

        Takes the winnings pot and distributes it as follows:
        25% - Burned
        10% - Dev
        15% - Staked in GRAPE Single Stake Pool, contract
            sells the wine to help pay for gas
        50% - Distributed amongst the top 3 players
            25% - 1st Place
            15% - 2nd Place
            10% - 3rd Place
    */
    function distributeWinnings() public ownerOnly {
        
        ERC20 GRAPE = ERC20(grapeToken);
        ERC20 WINE = ERC20(wineToken);
        GrapeRewardsPool pool = GrapeRewardsPool(stakeContract);
        TraderJoe router = TraderJoe(joeRouter);

        // Get the balance of the winnings pot
        uint256 grapeBalance = GRAPE.balanceOf(address(this));
        // Calculate dev profit
        uint256 devAmount = (grapeBalance/20)*2;
        // Calculate amount to stake
        uint256 stakeAmount = (grapeBalance/20)*3;
        // Calculate winnings
        uint256[3] memory winnings = [
            (grapeBalance/20)*5,
            (grapeBalance/20)*3,
            (grapeBalance/20)*2
        ];
        // Burn amount is whatever remains
        uint256 burnAmount = grapeBalance - (devAmount + stakeAmount + winnings[0] + winnings[1] + winnings[2]);

        // Transfer winnings to the winners
        GRAPE.transfer(leaderboard[0].player, winnings[0]);
        GRAPE.transfer(leaderboard[1].player, winnings[1]);
        GRAPE.transfer(leaderboard[2].player, winnings[2]);

        // Pay the dev
        GRAPE.transfer(dev, devAmount);

        // Stake
        if(doStake)
            pool.deposit(3, stakeAmount);

        if(doTrade) {
            // Convert wine to AVAX for gas
            uint256 wineBalance = WINE.balanceOf(address(this));
            address[] memory path = new address[](3);
            path[0] = wineToken; path[1] = mimToken; path[2] = wavaxToken;
            router.SwapExactTokensforAVAX(wineBalance, 0, path, address(this), block.timestamp);
        }
        // Finally burn the remainder
        GRAPE.transfer(address(0xdead), burnAmount);
    }

    // Returns the highscore for a given player
    function getHighScore() public view returns(uint256) {
        return highScores[msg.sender];
    }

    // Returns the 10 player leaderboard
    function getLeaderboard(uint256 index) public view returns(address player, uint256 score) {
        return (leaderboard[index].player, leaderboard[index].score);
    }

    function clearLeaderboard() public ownerOnly devOnly {
        for(uint i = 0; i < 10; i++) {
            leaderboard[i].player = address(0);
            leaderboard[i].score = 0;
        }
    }

    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function Nuke() public ownerOnly devOnly {
        address payable addr = payable(address(msg.sender));
        selfdestruct(addr);
    }
}