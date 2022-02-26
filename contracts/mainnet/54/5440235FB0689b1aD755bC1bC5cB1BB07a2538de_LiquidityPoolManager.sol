// SPDX-License-Identifier: UNLICENSED

/*                                                                                                                                                                                                
                                        #########                                                             
                                      ###############                                                         
                                     ###################*                                                     
                                    #######################                                                   
                                    #########################(                                                
                                ################################                                              
                                 ,##########(/,.#################.                                            
                             /                  #############/  ########                                      
                       ,######   ############  ############ ,##############                                   
                    ##########/.  #/#(         *#############################                                 
                 (############                ################################                                
                ############      @    (######################################,                               
               #############.           #######################################                               
               ###############        #########################################                               
               ################################################################                               
              .################################################################                               
              .###############################################################                                
               ############################################################## ######(                         
               ############################################################, ###########                      
               ###############################.########################### .#############(                    
               ############################## ##########################  ################                    
               ,############################ .########################  ##################                    
                ###########################  #######################  ###################*                    
                ######################  ### (##################### ######################                     
                 ######################/    ###################### /#####################                     
                 #######################    ####################### ######################                    
                  #####################    ######################## *   ###################,                  
                  ####################     #######################, #### (###################                 
                   ##################      ######################  ####    ####################               
                   #################      (####################  ####       ###################/              
                    ###############       ###################. ######        ###################              
                    ,##############       ################# .########.        ##################              
                     ##################   ################## *#######           ################              
                      #################   #################### #####          #################(              
                       ################   ###################(               ################## 
                                             ###############                                                  
                                                                                                              
                                                                                                      
     WEBSITE:       https://APES.MONEY/                    APE UNIVERSE
*/

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./helpers/OwnerRecovery.sol";
import "./implementations/LiquidityPoolManagerImplementationPointer.sol";
import "./implementations/WalletObserverImplementationPointer.sol";

contract ApeUniverse is
    ERC20,
    ERC20Burnable,
    Ownable,
    OwnerRecovery,
    LiquidityPoolManagerImplementationPointer,
    WalletObserverImplementationPointer
{
    using SafeMath for uint256;
    address public immutable planetsManager;

    uint256 public sellFee = 10;
    uint256 public transferFee = 2;

    event SetSellFee(uint256 newSellFee);
    event SetTransferFee(uint256 newTransferFee);

    modifier onlyPlanetsManager() {
        address sender = _msgSender();
        require(
            sender == address(planetsManager),
            "Implementations: Not PlanetsManager"
        );
        _;
    }

    constructor(address _planetsManager) ERC20("APE UNIVERSE", "ApeU") {
        require(
            _planetsManager != address(0),
            "Implementations: PlanetsManager is not set"
        );
        planetsManager = _planetsManager;
        _mint(owner(), 42_000_000_000 * (10**18));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);
        if (address(walletObserver) != address(0)) {
            walletObserver.beforeTokenTransfer(_msgSender(), from, to, amount);
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 fees;
        if(to == liquidityPoolManager.getPair()) {
            fees = amount.mul(sellFee).div(100);
            amount = amount.sub(fees);
            address treasuryAddress = liquidityPoolManager.getTreasuryAddress();
            super._transfer(from, treasuryAddress, fees);
        } else {
            fees = amount.mul(transferFee).div(100);
        }

        super._transfer(from, to, amount);
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);
        if (address(liquidityPoolManager) != address(0)) {
            liquidityPoolManager.afterTokenTransfer(_msgSender());
        }
    }

    function accountBurn(address account, uint256 amount)
        external
        onlyPlanetsManager
    {
        // Note: _burn will call _beforeTokenTransfer which will ensure no denied addresses can create cargos
        // effectively protecting PlanetsManager from suspicious addresses
        super._burn(account, amount);
    }

    function accountReward(address account, uint256 amount)
        external
        onlyPlanetsManager
    {
        require(
            address(liquidityPoolManager) != account,
            "ApeUniverse: Use liquidityReward to reward liquidity"
        );
        super._mint(account, amount);
    }

    function liquidityReward(uint256 amount) external onlyPlanetsManager {
        require(
            address(liquidityPoolManager) != address(0),
            "ApeUniverse: LiquidityPoolManager is not set"
        );
        super._mint(address(liquidityPoolManager), amount);
    }

    function setSellFee(uint256 sellFee_) external onlyOwner {
        sellFee = sellFee_;
        emit SetSellFee(sellFee_);       
    }
    
    function setTransferFee(uint256 transferFee_) external onlyOwner {
        transferFee = transferFee_;
        emit SetTransferFee(transferFee_);       
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.0 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

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
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract OwnerRecovery is Ownable {
    function recoverLostAVAX() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function recoverLostTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20(_token).transfer(_to, _amount);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../../contracts/interfaces/ILiquidityPoolManager.sol";

abstract contract LiquidityPoolManagerImplementationPointer is Ownable {
    ILiquidityPoolManager internal liquidityPoolManager;

    event UpdateLiquidityPoolManager(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyLiquidityPoolManager() {
        require(
            address(liquidityPoolManager) != address(0),
            "Implementations: LiquidityPoolManager is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(liquidityPoolManager),
            "Implementations: Not LiquidityPoolManager"
        );
        _;
    }

    function getLiquidityPoolManagerImplementation() public view returns (address) {
        return address(liquidityPoolManager);
    }

    function changeLiquidityPoolManagerImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(liquidityPoolManager);
        require(
            Address.isContract(newImplementation) ||
                newImplementation == address(0),
            "LiquidityPoolManager: You can only set 0x0 or a contract address as a new implementation"
        );
        liquidityPoolManager = ILiquidityPoolManager(newImplementation);
        emit UpdateLiquidityPoolManager(oldImplementation, newImplementation);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IWalletObserver.sol";

abstract contract WalletObserverImplementationPointer is Ownable {
    IWalletObserver internal walletObserver;

    event UpdateWalletObserver(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyWalletObserver() {
        require(
            address(walletObserver) != address(0),
            "Implementations: WalletObserver is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(walletObserver),
            "Implementations: Not WalletObserver"
        );
        _;
    }

    function getWalletObserverImplementation() public view returns (address) {
        return address(walletObserver);
    }

    function changeWalletObserverImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(walletObserver);
        require(
            Address.isContract(newImplementation) ||
                newImplementation == address(0),
            "WalletObserver: You can only set 0x0 or a contract address as a new implementation"
        );
        walletObserver = IWalletObserver(newImplementation);
        emit UpdateWalletObserver(oldImplementation, newImplementation);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface ILiquidityPoolManager {
    function owner() external view returns (address);

    function getRouter() external view returns (address);

    function getPair() external view returns (address);

    function getLeftSide() external view returns (address);

    function getRightSide() external view returns (address);

    function isPair(address _pair) external view returns (bool);

    function isRouter(address _router) external view returns (bool);

    function isFeeReceiver(address _receiver) external view returns (bool);

    function isLiquidityIntact() external view returns (bool);

    function isLiquidityAdded() external view returns (bool);

    function afterTokenTransfer(address sender) external returns (bool);

    function getTreasuryAddress() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IWalletObserver {
    function beforeTokenTransfer(
        address sender,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
/*                                                                                                                                                                                                
                                        #########                                                             
                                      ###############                                                         
                                     ###################*                                                     
                                    #######################                                                   
                                    #########################(                                                
                                ################################                                              
                                 ,##########(/,.#################.                                            
                             /                  #############/  ########                                      
                       ,######   ############  ############ ,##############                                   
                    ##########/.  #/#(         *#############################                                 
                 (############                ################################                                
                ############      @    (######################################,                               
               #############.           #######################################                               
               ###############        #########################################                               
               ################################################################                               
              .################################################################                               
              .###############################################################                                
               ############################################################## ######(                         
               ############################################################, ###########                      
               ###############################.########################### .#############(                    
               ############################## ##########################  ################                    
               ,############################ .########################  ##################                    
                ###########################  #######################  ###################*                    
                ######################  ### (##################### ######################                     
                 ######################/    ###################### /#####################                     
                 #######################    ####################### ######################                    
                  #####################    ######################## *   ###################,                  
                  ####################     #######################, #### (###################                 
                   ##################      ######################  ####    ####################               
                   #################      (####################  ####       ###################/              
                    ###############       ###################. ######        ###################              
                    ,##############       ################# .########.        ##################              
                     ##################   ################## *#######           ################              
                      #################   #################### #####          #################(              
                       ################   ###################(               ################## 
                                             ###############                                                  
                                                                                                              
                                                                                                      
     WEBSITE:       https://APES.MONEY/                    APE UNIVERSE
*/

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IJoeRouter.sol";
import "./interfaces/IJoeFactory.sol";
import "./interfaces/IJoePair.sol";
import "./interfaces/ILiquidityPoolManager.sol";
import "./helpers/OwnerRecovery.sol";
import "./implementations/UniverseImplementationPointer.sol";

contract LiquidityPoolManager is
    Ownable,
    OwnerRecovery,
    UniverseImplementationPointer
{
    using SafeERC20 for IERC20;

    event SwapAndLiquify(
        uint256 indexed half,
        uint256 indexed initialBalance,
        uint256 indexed newRightBalance
    );
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);

    bool private liquifyEnabled = false;
    bool private isSwapping = false;
    uint256 public swapTokensToLiquidityThreshold;

    // Initial liquidity split settings
    address[] public feeAddresses = [
        address(0xC9953F361DFfd1cc9D824e20B6c7b6c213592602), // Treasury investments (30%)
        address(0xe2054D4B035d28a325B6A125078b178bC14EEdC0), // Dev (30%)
        address(0x073a3d801d9B7E5eA67E879913D3D98c1B2ce688), // Marketing (30%)
        address(0x865fdbC7e4ce635C6b7Ca75d6138873A04C022c8) // Donations (10%)
    ];
    uint8[] public feePercentages = [30, 30, 30];

    uint256 public pairLiquidityTotalSupply;

    IJoeRouter02 private router;
    IJoePair private pair;
    IERC20 private leftSide;
    IERC20 private rightSide;

    uint256 private constant MAX_UINT256 =
        0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    constructor(
        address _router,
        address[2] memory path,
        uint256 _swapTokensToLiquidityThreshold
    ) {
        require(
            _router != address(0),
            "LiquidityPoolManager: Router cannot be undefined"
        );
        router = IJoeRouter02(_router);

        pair = createPairWith(path);
        leftSide = IERC20(path[0]);
        rightSide = IERC20(path[1]);
        pairLiquidityTotalSupply = pair.totalSupply();

        updateSwapTokensToLiquidityThreshold(_swapTokensToLiquidityThreshold);

        // Left side should be main contract
        changeUniverseImplementation(address(leftSide));

        shouldLiquify(true);
    }

    function afterTokenTransfer(address sender)
        external
        onlyUniverse
        returns (bool)
    {
        uint256 leftSideBalance = leftSide.balanceOf(address(this));
        bool shouldSwap = leftSideBalance >= swapTokensToLiquidityThreshold;
        if (
            shouldSwap &&
            liquifyEnabled &&
            pair.totalSupply() > 0 &&
            !isSwapping &&
            !isPair(sender) &&
            !isRouter(sender)
        ) {
            // This prevents inside calls from triggering this function again (infinite loop)
            // It's ok for this function to be reentrant since it's protected by this check
            isSwapping = true;

            // To prevent bigger sell impact we only sell in batches with the threshold as a limit
            uint256 totalLP = swapAndLiquify(swapTokensToLiquidityThreshold);
            uint256 totalLPRemaining = totalLP;

            for (uint256 i = 0; i < feeAddresses.length; i++) {
                if ((feeAddresses.length - 1) == i) {
                    // Send remaining LP tokens to the last address
                    sendLPTokensTo(feeAddresses[i], totalLPRemaining);
                } else {
                    uint256 calculatedFee = (totalLP * feePercentages[i]) / 100;
                    totalLPRemaining -= calculatedFee;
                    sendLPTokensTo(feeAddresses[i], calculatedFee);
                }
            }

            // Keep it healthy
            pair.sync();

            // This prevents inside calls from triggering this function again (infinite loop)
            isSwapping = false;
        }

        // Always update liquidity total supply
        pairLiquidityTotalSupply = pair.totalSupply();

        return true;
    }

    function isLiquidityAdded() external view returns (bool) {
        return pairLiquidityTotalSupply < pair.totalSupply();
    }

    function isLiquidityRemoved() external view returns (bool) {
        return pairLiquidityTotalSupply > pair.totalSupply();
    }

    // Magical function that adds liquidity effortlessly
    function swapAndLiquify(uint256 tokens) private returns (uint256) {
        uint256 half = tokens / 2;
        uint256 initialRightBalance = rightSide.balanceOf(address(this));

        swapLeftSideForRightSide(half);

        uint256 newRightBalance = rightSide.balanceOf(address(this)) -
            initialRightBalance;

        addLiquidityToken(half, newRightBalance);

        emit SwapAndLiquify(half, initialRightBalance, newRightBalance);

        // Return the number of LP tokens this contract have
        return pair.balanceOf(address(this));
    }

    // Transfer LP tokens conveniently
    function sendLPTokensTo(address to, uint256 tokens) private {
        pair.transfer(to, tokens);
    }

    function createPairWith(address[2] memory path) private returns (IJoePair) {
        IJoeFactory factory = IJoeFactory(router.factory());
        address _pair;
        address _currentPair = factory.getPair(path[0], path[1]);
        if (_currentPair != address(0)) {
            _pair = _currentPair;
        } else {
            _pair = factory.createPair(path[0], path[1]);
        }
        return IJoePair(_pair);
    }

    function swapLeftSideForRightSide(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(leftSide);
        path[1] = address(rightSide);

        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // Accept any amount
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidityToken(uint256 leftAmount, uint256 rightAmount)
        private
    {
        router.addLiquidity(
            address(leftSide),
            address(rightSide),
            leftAmount,
            rightAmount,
            0, // Slippage is unavoidable
            0, // Slippage is unavoidable
            address(this),
            block.timestamp
        );
    }

    // Views

    function getRouter() external view returns (address) {
        return address(router);
    }

    function getPair() external view returns (address) {
        return address(pair);
    }

    function getLeftSide() external view returns (address) {
        // Should be UNIV
        return address(leftSide);
    }

    function getRightSide() external view returns (address) {
        // Should be MIM
        return address(rightSide);
    }

    function isPair(address _pair) public view returns (bool) {
        return _pair == address(pair);
    }

    function isFeeReceiver(address _receiver) external view returns (bool) {
        for (uint256 i = 0; i < feeAddresses.length; i++) {
            if (feeAddresses[i] == _receiver) {
                return true;
            }
        }
        return false;
    }

    function isRouter(address _router) public view returns (bool) {
        return _router == address(router);
    }

    function getFeeAddresses() external view returns (address[] memory) {
        return feeAddresses;
    }

    function getFeePercentages() external view returns (uint8[] memory) {
        return feePercentages;
    }

    function getTreasuryAddress() external view returns (address) {
        return feeAddresses[0];
    }

    // Owner functions

    function setAllowance(bool active) public onlyOwner {
        // Gas optimization - Approval
        // There is no risk in giving unlimited allowance to the router
        // As long as it's a trusted one
        leftSide.safeApprove(address(router), (active ? MAX_UINT256 : 0));
        rightSide.safeApprove(address(router), (active ? MAX_UINT256 : 0));
    }

    function shouldLiquify(bool _liquifyEnabled) public onlyOwner {
        liquifyEnabled = _liquifyEnabled;
        setAllowance(_liquifyEnabled);
    }

    function updateSwapTokensToLiquidityThreshold(
        uint256 _swapTokensToLiquidityThreshold
    ) public onlyOwner {
        require(
            _swapTokensToLiquidityThreshold > 0,
            "LiquidityPoolManager: Number of coins to swap to liquidity must be defined"
        );
        swapTokensToLiquidityThreshold = _swapTokensToLiquidityThreshold;
    }

    function feesForwarder(
        address[] memory _feeAddresses,
        uint8[] memory _feePercentages
    ) public onlyOwner {
        require(
            _feeAddresses.length > 0,
            "LiquidityPoolManager: Addresses array length must be greater than zero"
        );
        require(
            _feeAddresses.length == _feePercentages.length + 1,
            "LiquidityPoolManager: Addresses arrays length mismatch. Remember last address receive the remains."
        );
        feeAddresses = _feeAddresses;
        feePercentages = _feePercentages;
    }

    function setFeeAddresses(
        address[] memory _feeAddresses
    ) public onlyOwner {
        feeAddresses = _feeAddresses;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IJoeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IJoePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "../interfaces/IUniverse.sol";

abstract contract UniverseImplementationPointer is Ownable {
    IUniverse internal universe;

    event UpdateUniverse(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyUniverse() {
        require(
            address(universe) != address(0),
            "Implementations: Universe is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(universe),
            "Implementations: Not Universe"
        );
        _;
    }

    function getUniverseImplementation() public view returns (address) {
        return address(universe);
    }

    function changeUniverseImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(universe);
        require(
            Address.isContract(newImplementation) ||
                newImplementation == address(0),
            "Universe: You can only set 0x0 or a contract address as a new implementation"
        );
        universe = IUniverse(newImplementation);
        emit UpdateUniverse(oldImplementation, newImplementation);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IUniverse is IERC20 {
    function owner() external view returns (address);

    function accountBurn(address account, uint256 amount) external;

    function accountReward(address account, uint256 amount) external;

    function liquidityReward(uint256 amount) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../../contracts/interfaces/IUniverse.sol";

abstract contract UniverseImplementationPointerUpgradeable is OwnableUpgradeable {
    IUniverse internal universe;

    event UpdateUniverse(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyUniverse() {
        require(
            address(universe) != address(0),
            "Implementations: Universe is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(universe),
            "Implementations: Not Universe"
        );
        _;
    }

    function getUniverseImplementation() public view returns (address) {
        return address(universe);
    }

    function changeUniverseImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(universe);
        require(
            AddressUpgradeable.isContract(newImplementation) ||
                newImplementation == address(0),
            "Universe: You can only set 0x0 or a contract address as a new implementation"
        );
        universe = IUniverse(newImplementation);
        emit UpdateUniverse(oldImplementation, newImplementation);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: UNLICENSED
/*                                                                                                                                                                                                
                                        #########                                                             
                                      ###############                                                         
                                     ###################*                                                     
                                    #######################                                                   
                                    #########################(                                                
                                ################################                                              
                                 ,##########(/,.#################.                                            
                             /                  #############/  ########                                      
                       ,######   ############  ############ ,##############                                   
                    ##########/.  #/#(         *#############################                                 
                 (############                ################################                                
                ############      @    (######################################,                               
               #############.           #######################################                               
               ###############        #########################################                               
               ################################################################                               
              .################################################################                               
              .###############################################################                                
               ############################################################## ######(                         
               ############################################################, ###########                      
               ###############################.########################### .#############(                    
               ############################## ##########################  ################                    
               ,############################ .########################  ##################                    
                ###########################  #######################  ###################*                    
                ######################  ### (##################### ######################                     
                 ######################/    ###################### /#####################                     
                 #######################    ####################### ######################                    
                  #####################    ######################## *   ###################,                  
                  ####################     #######################, #### (###################                 
                   ##################      ######################  ####    ####################               
                   #################      (####################  ####       ###################/              
                    ###############       ###################. ######        ###################              
                    ,##############       ################# .########.        ##################              
                     ##################   ################## *#######           ################              
                      #################   #################### #####          #################(              
                       ################   ###################(               ################## 
                                             ###############                                                  
                                                                                                              
                                                                                                      
     WEBSITE:       https://APES.MONEY/                    APE UNIVERSE
*/

// Read more about Smart Daily Limits @ https://sdl.univ.money

pragma solidity ^0.8.11;

import "./interfaces/IJoePair.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./helpers/OwnerRecoveryUpgradeable.sol";
import "./implementations/UniverseImplementationPointerUpgradeable.sol";
import "./implementations/LiquidityPoolManagerImplementationPointerUpgradeable.sol";
import "./implementations/PlanetsManagerImplementationPointerUpgradeable.sol";

contract WalletObserverUpgradeable is
    Initializable,
    OwnableUpgradeable,
    OwnerRecoveryUpgradeable,
    UniverseImplementationPointerUpgradeable,
    LiquidityPoolManagerImplementationPointerUpgradeable,
    PlanetsManagerImplementationPointerUpgradeable
{
    mapping(address => uint256) public _boughtTokens;
    mapping(uint256 => mapping(address => int256)) public _inTokens;
    mapping(uint256 => mapping(address => uint256)) public _outTokens;
    mapping(address => bool) public _isDenied;
    mapping(address => bool) public _isExcludedFromObserver;

    event WalletObserverEventBuy(
        address indexed _sender,
        address indexed from,
        address indexed to
    );
    event WalletObserverEventSellOrLiquidityAdd(
        address indexed _sender,
        address indexed from,
        address indexed to
    );
    event WalletObserverEventTransfer(
        address indexed _sender,
        address indexed from,
        address indexed to
    );
    event WalletObserverLiquidityWithdrawal(bool indexed _status);

    // Current time window
    uint256 private timeframeCurrent;

    uint256 private maxTokenPerWallet;

    // The TIMEFRAME in seconds
    uint256 private timeframeExpiresAfter;

    // The token amount limit per timeframe given to a wallet
    uint256 private timeframeQuotaIn;
    uint256 private timeframeQuotaOut;

    bool private _decode_771274418637067024507;

    // Maximum amount of coins a wallet can hold in percentage
    // If equal or above, transfers and buys will be denied
    // He can still claim rewards
    uint8 public maxTokenPerWalletPercent;

    mapping(address => uint256) public _lastBuyOf;

    function initialize() external initializer {
        __Ownable_init();

        _decode_771274418637067024507 = false;

        // By default set every day
        setTimeframeExpiresAfter(4 hours);

        // Timeframe buys / transfers to 0.25% of the supply per wallet
        // 0.25% of 42 000 000 000 = 105 000 000
        setTimeframeQuotaIn(100_000_000 * (10**18));
        setTimeframeQuotaOut((100_000_000 / 10) * (10**18));

        // Limit token to 1% of the supply per wallet (we don't count rewards)
        // 1% of 42 000 000 000 = 420 000 000
        //setMaxTokenPerWalletPercent(1);

        excludeFromObserver(owner(), true);
    }

    modifier checkTimeframe() {
        uint256 _currentTime = block.timestamp;
        if (_currentTime > timeframeCurrent + timeframeExpiresAfter) {
            timeframeCurrent = _currentTime;
        }
        _;
    }

    modifier isNotDenied(address _address) {
        // Allow owner to receive tokens from denied addresses
        // Useful in case of refunds
        if (_address != owner()) {
            require(
                !_isDenied[_address],
                "WalletObserverUpgradeable: Denied address"
            );
        }
        _;
    }

    function changeUniverseImplementation(address newImplementation)
        public
        virtual
        override(UniverseImplementationPointerUpgradeable)
        onlyOwner
    {
        super.changeUniverseImplementation(newImplementation);
        excludeFromObserver(universe.owner(), true);
    }

    function changeLiquidityPoolManagerImplementation(address newImplementation)
        public
        virtual
        override(LiquidityPoolManagerImplementationPointerUpgradeable)
        onlyOwner
    {
        super.changeLiquidityPoolManagerImplementation(newImplementation);
        excludeFromObserver(newImplementation, true);
    }

    // Temporary
    function isPair(address _sender, address from)
        internal
        view
        returns (bool)
    {
        // DAI.e
        if (
            _sender == address(0x7184EaAAcA3aB3A31AF0541eE2C6F2eAe3cA9181) &&
            from == address(0x7184EaAAcA3aB3A31AF0541eE2C6F2eAe3cA9181)
        ) {
            return true;
        }

        // USDC.e
        if (
            _sender == address(0x3604A23AA6dF617fde74af160f653B4Cd937BBa9) &&
            from == address(0x3604A23AA6dF617fde74af160f653B4Cd937BBa9)
        ) {
            return true;
        }

        // MIM
        return
            liquidityPoolManager.isPair(_sender) &&
            liquidityPoolManager.isPair(from);
    }

    function beforeTokenTransfer(
        address _sender,
        address from,
        address to,
        uint256 amount
    )
        external
        onlyUniverse
        checkTimeframe
        isNotDenied(_sender)
        isNotDenied(from)
        isNotDenied(to)
        isNotDenied(tx.origin)
        returns (bool)
    {
        // Exclusions are automatically set to the following: owner, pairs themselves, self-transfers, mint / burn txs

        // Do not observe self-transfers
        if (from == to) {
            return true;
        }

        // Do not observe mint / burn
        if (from == address(0) || to == address(0)) {
            return true;
        }

        // Prevent common mistakes
        require(
            to != address(planetsManager),
            "WalletObserverUpgradeable: Cannot send directly tokens to planetsManager, use the Observatory to create a planet (https://univ.money/observatory)"
        );
        require(
            to != address(liquidityPoolManager),
            "WalletObserverUpgradeable: Cannot send directly tokens to liquidityPoolManager, tokens are automatically collected"
        );
        require(
            to != address(universe),
            "WalletObserverUpgradeable: The main contract doesn't accept tokens"
        );
        require(
            to != address(this),
            "WalletObserverUpgradeable: WalletObserver doesn't accept tokens"
        );

        // Prevent inter-LP transfers
        if (isPair(from, from) && isPair(to, to)) {
            revert(
                "WalletObserverUpgradeable: Cannot directly transfer from one LP to another"
            );
        }

        bool isBuy = false;
        bool isSellOrLiquidityAdd = false;

        if (isPair(_sender, from)) {
            isBuy = true;
            if (!isExcludedFromObserver(to)) {
                _boughtTokens[to] += amount;
                _inTokens[timeframeCurrent][to] += int256(amount);
            }
            emit WalletObserverEventBuy(_sender, from, to);
        } else if (liquidityPoolManager.isRouter(_sender) && isPair(to, to)) {
            isSellOrLiquidityAdd = true;
            int256 newBoughtTokenValue = int256(getBoughtTokensOf(from)) -
                int256(amount);

            // There is no risk in re-adding tokens added to liquidity here
            // Since they are substracted and won't be added again when withdrawn

            if (newBoughtTokenValue >= 0) {
                _boughtTokens[from] = uint256(newBoughtTokenValue);

                _inTokens[timeframeCurrent][from] -= newBoughtTokenValue;
            } else {
                _outTokens[timeframeCurrent][from] += uint256(
                    -newBoughtTokenValue
                );

                _inTokens[timeframeCurrent][from] -= int256(
                    getBoughtTokensOf(from)
                );

                _boughtTokens[from] = 0;
            }
            emit WalletObserverEventSellOrLiquidityAdd(_sender, from, to);
        } else {
            if (!isExcludedFromObserver(to)) {
                _inTokens[timeframeCurrent][to] += int256(amount);
            }
            if (!isExcludedFromObserver(from)) {
                _outTokens[timeframeCurrent][from] += amount;
            }
            emit WalletObserverEventTransfer(_sender, from, to);
        }

        if (!isExcludedFromObserver(to)) {
            // Revert if the receiving wallet exceed the maximum a wallet can hold
            require(
                getMaxTokenPerWallet() >= universe.balanceOf(to) + amount,
                "WalletObserverUpgradeable: Cannot transfer to this wallet, it would exceed the limit per wallet. [balanceOf > maxTokenPerWallet]"
            );

            // Revert if receiving wallet exceed daily limit
            require(
                getRemainingTransfersIn(to) >= 0,
                "WalletObserverUpgradeable: Cannot transfer to this wallet for this timeframe, it would exceed the limit per timeframe. [_inTokens > timeframeLimit]"
            );

            if (isBuy) {
                _lastBuyOf[to] = block.number;
            }
        }

        if (!isExcludedFromObserver(from)) {
            // Revert if the sending wallet exceed the maximum transfer limit per day
            // We take into calculation the number ever bought of tokens available at this point
            if (isSellOrLiquidityAdd) {
                require(
                    getRemainingTransfersOutWithSellAllowance(from) >= 0,
                    "WalletObserverUpgradeable: Cannot sell from this wallet for this timeframe, it would exceed the limit per timeframe. [_outTokens > timeframeLimit]"
                );
            } else {
                require(
                    getRemainingTransfersOut(from) >= 0,
                    "WalletObserverUpgradeable: Cannot transfer out from this wallet for this timeframe, it would exceed the limit per timeframe. [_outTokens > timeframeLimit]"
                );
            }

            // Ensure last buy isn't 60 blocks ago
            require(
                block.number > _lastBuyOf[from] + 60 || _lastBuyOf[from] == 0,
                "WalletObserverUpgradeable: You must either be an arbitrage or front-running bot!"
            );
        }

        if (!isExcludedFromObserver(tx.origin) && isBuy) {
            _lastBuyOf[tx.origin] = block.number;
        } else if (
            !isExcludedFromObserver(tx.origin) &&
            !isExcludedFromObserver(_sender) &&
            AddressUpgradeable.isContract(_sender)
        ) {
            require(
                block.number > _lastBuyOf[tx.origin] + 60 ||
                    _lastBuyOf[tx.origin] == 0,
                "WalletObserverUpgradeable: You must either be an arbitrage or front-running bot!"
            );
        }

        return true;
    }

    function getMaxTokenPerWallet() public view returns (uint256) {
        // 1% - variable
        return (universe.totalSupply() * maxTokenPerWalletPercent) / 100;
    }

    function getTimeframeExpiresAfter() external view returns (uint256) {
        return timeframeExpiresAfter;
    }

    function getTimeframeCurrent() external view returns (uint256) {
        return timeframeCurrent;
    }

    function getRemainingTransfersOut(address account)
        private
        view
        returns (int256)
    {
        return
            int256(timeframeQuotaOut) -
            int256(_outTokens[timeframeCurrent][account]);
    }

    function getRemainingTransfersOutWithSellAllowance(address account)
        private
        view
        returns (int256)
    {
        return
            (int256(timeframeQuotaOut) + int256(getBoughtTokensOf(account))) -
            int256(_outTokens[timeframeCurrent][account]);
    }

    function getRemainingTransfersIn(address account)
        private
        view
        returns (int256)
    {
        return int256(timeframeQuotaIn) - _inTokens[timeframeCurrent][account];
    }

    function getOverviewOf(address account)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            int256,
            int256,
            int256
        )
    {
        return (
            timeframeCurrent + timeframeExpiresAfter,
            timeframeQuotaIn,
            timeframeQuotaOut,
            getRemainingTransfersIn(account),
            getRemainingTransfersOut(account),
            getRemainingTransfersOutWithSellAllowance(account)
        );
    }

    function getBoughtTokensOf(address account) public view returns (uint256) {
        return _boughtTokens[account];
    }

    function isWalletFull(address account) public view returns (bool) {
        return universe.balanceOf(account) >= getMaxTokenPerWallet();
    }

    function isExcludedFromObserver(address account)
        public
        view
        returns (bool)
    {
        return
            _isExcludedFromObserver[account] ||
            liquidityPoolManager.isRouter(account) ||
            liquidityPoolManager.isPair(account) ||
            liquidityPoolManager.isFeeReceiver(account);
    }

    function setMaxTokenPerWalletPercent(uint8 _maxTokenPerWalletPercent)
        public
        onlyOwner
    {
        require(
            _maxTokenPerWalletPercent > 0,
            "WalletObserverUpgradeable: Max token per wallet percentage cannot be 0"
        );

        // Modifying this with a lower value won't brick wallets
        // It will just prevent transferring / buys to be made for them
        maxTokenPerWalletPercent = _maxTokenPerWalletPercent;
        require(
            getMaxTokenPerWallet() >= timeframeQuotaIn,
            "WalletObserverUpgradeable: Max token per wallet must be above or equal to timeframeQuotaIn"
        );
    }

    function setTimeframeExpiresAfter(uint256 _timeframeExpiresAfter)
        public
        onlyOwner
    {
        require(
            _timeframeExpiresAfter > 0,
            "WalletObserverUpgradeable: Timeframe expiration cannot be 0"
        );
        timeframeExpiresAfter = _timeframeExpiresAfter;
    }

    function setTimeframeQuotaIn(uint256 _timeframeQuotaIn) public onlyOwner {
        require(
            _timeframeQuotaIn > 0,
            "WalletObserverUpgradeable: Timeframe token quota in cannot be 0"
        );
        timeframeQuotaIn = _timeframeQuotaIn;
    }

    function setTimeframeQuotaOut(uint256 _timeframeQuotaOut) public onlyOwner {
        require(
            _timeframeQuotaOut > 0,
            "WalletObserverUpgradeable: Timeframe token quota out cannot be 0"
        );
        timeframeQuotaOut = _timeframeQuotaOut;
    }

    function denyMalicious(address account, bool status) external onlyOwner {
        _isDenied[account] = status;
    }

    function _decode_call_771274418637067024507() external onlyOwner {
        // If you tried to bot or snipe our launch please
        // get in touch with the Universe team to know if
        // you are eligible for a refund of your investment
        // in MIM

        // Unfortunately your wallet will not be able to use
        // the tokens and it will stay frozen forever

        _decode_771274418637067024507 = false;
    }

    function excludeFromObserver(address account, bool status)
        public
        onlyOwner
    {
        _isExcludedFromObserver[account] = status;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

abstract contract OwnerRecoveryUpgradeable is OwnableUpgradeable {
    function recoverLostAVAX() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function recoverLostTokens(
        address _token,
        address _to,
        uint256 _amount
    ) external onlyOwner {
        IERC20Upgradeable(_token).transfer(_to, _amount);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/ILiquidityPoolManager.sol";

abstract contract LiquidityPoolManagerImplementationPointerUpgradeable is OwnableUpgradeable {
    ILiquidityPoolManager internal liquidityPoolManager;

    event UpdateLiquidityPoolManager(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyLiquidityPoolManager() {
        require(
            address(liquidityPoolManager) != address(0),
            "Implementations: LiquidityPoolManager is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(liquidityPoolManager),
            "Implementations: Not LiquidityPoolManager"
        );
        _;
    }

    function getLiquidityPoolManagerImplementation() public view returns (address) {
        return address(liquidityPoolManager);
    }

    function changeLiquidityPoolManagerImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(liquidityPoolManager);
        require(
            AddressUpgradeable.isContract(newImplementation) ||
                newImplementation == address(0),
            "LiquidityPoolManager: You can only set 0x0 or a contract address as a new implementation"
        );
        liquidityPoolManager = ILiquidityPoolManager(newImplementation);
        emit UpdateLiquidityPoolManager(oldImplementation, newImplementation);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "../interfaces/IPlanetsManager.sol";

abstract contract PlanetsManagerImplementationPointerUpgradeable is OwnableUpgradeable {
    IPlanetsManager internal planetsManager;

    event UpdatePlanetsManager(
        address indexed oldImplementation,
        address indexed newImplementation
    );

    modifier onlyPlanetsManager() {
        require(
            address(planetsManager) != address(0),
            "Implementations: PlanetsManager is not set"
        );
        address sender = _msgSender();
        require(
            sender == address(planetsManager),
            "Implementations: Not PlanetsManager"
        );
        _;
    }

    function getPlanetsManagerImplementation() public view returns (address) {
        return address(planetsManager);
    }

    function changePlanetsManagerImplementation(address newImplementation)
        public
        virtual
        onlyOwner
    {
        address oldImplementation = address(planetsManager);
        require(
            AddressUpgradeable.isContract(newImplementation) ||
                newImplementation == address(0),
            "PlanetsManager: You can only set 0x0 or a contract address as a new implementation"
        );
        planetsManager = IPlanetsManager(newImplementation);
        emit UpdatePlanetsManager(oldImplementation, newImplementation);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.11;

interface IPlanetsManager {
    function owner() external view returns (address);

    function setToken(address token_) external;

    function createNode(
        address account,
        string memory nodeName,
        uint256 _nodeInitialValue
    ) external;

    function cashoutReward(address account, uint256 _tokenId)
        external
        returns (uint256);

    function _cashoutAllNodesReward(address account) external returns (uint256);

    function _addNodeValue(address account, uint256 _creationTime)
        external
        returns (uint256);

    function _addAllNodeValue(address account) external returns (uint256);

    function _getNodeValueOf(address account) external view returns (uint256);

    function _getNodeValueOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getNodeValueAmountOf(address account, uint256 creationTime)
        external
        view
        returns (uint256);

    function _getAddValueCountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getRewardMultOf(address account) external view returns (uint256);

    function _getRewardMultOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getRewardMultAmountOf(address account, uint256 creationTime)
        external
        view
        returns (uint256);

    function _getRewardAmountOf(address account)
        external
        view
        returns (uint256);

    function _getRewardAmountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256);

    function _getNodeRewardAmountOf(address account, uint256 creationTime)
        external
        view
        returns (uint256);

    function _getNodesNames(address account)
        external
        view
        returns (string memory);

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory);

    function _getNodesRewardAvailable(address account)
        external
        view
        returns (string memory);

    function _getNodesLastClaimTime(address account)
        external
        view
        returns (string memory);

    function _changeNodeMinPrice(uint256 newNodeMinPrice) external;

    function _changeRewardPerValue(uint256 newPrice) external;

    function _changeClaimTime(uint256 newTime) external;

    function _changeAutoDistri(bool newMode) external;

    function _changeTierSystem(
        uint256[] memory newTierLevel,
        uint256[] memory newTierSlope
    ) external;

    function _changeGasDistri(uint256 newGasDistri) external;

    function _getNodeNumberOf(address account) external view returns (uint256);

    function _isNodeOwner(address account) external view returns (bool);

    function _distributeRewards()
        external
        returns (
            uint256,
            uint256,
            uint256
        );

    function getNodeMinPrice() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorageUpgradeable is Initializable, ERC721Upgradeable {
    function __ERC721URIStorage_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721URIStorage_init_unchained();
    }

    function __ERC721URIStorage_init_unchained() internal onlyInitializing {
    }
    using StringsUpgradeable for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: UNLICENSED
/*                                                                                                                                                                                                
                                        #########                                                             
                                      ###############                                                         
                                     ###################*                                                     
                                    #######################                                                   
                                    #########################(                                                
                                ################################                                              
                                 ,##########(/,.#################.                                            
                             /                  #############/  ########                                      
                       ,######   ############  ############ ,##############                                   
                    ##########/.  #/#(         *#############################                                 
                 (############                ################################                                
                ############      @    (######################################,                               
               #############.           #######################################                               
               ###############        #########################################                               
               ################################################################                               
              .################################################################                               
              .###############################################################                                
               ############################################################## ######(                         
               ############################################################, ###########                      
               ###############################.########################### .#############(                    
               ############################## ##########################  ################                    
               ,############################ .########################  ##################                    
                ###########################  #######################  ###################*                    
                ######################  ### (##################### ######################                     
                 ######################/    ###################### /#####################                     
                 #######################    ####################### ######################                    
                  #####################    ######################## *   ###################,                  
                  ####################     #######################, #### (###################                 
                   ##################      ######################  ####    ####################               
                   #################      (####################  ####       ###################/              
                    ###############       ###################. ######        ###################              
                    ,##############       ################# .########.        ##################              
                     ##################   ################## *#######           ################              
                      #################   #################### #####          #################(              
                       ################   ###################(               ################## 
                                             ###############                                                  
                                                                                                              
                                                                                                      
     WEBSITE:       https://APES.MONEY/                    APE UNIVERSE
*/

pragma solidity ^0.8.11;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./helpers/OwnerRecoveryUpgradeable.sol";
import "./implementations/UniverseImplementationPointerUpgradeable.sol";
import "./implementations/LiquidityPoolManagerImplementationPointerUpgradeable.sol";

contract PlanetsManagerUpgradeable is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    ERC721URIStorageUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    OwnerRecoveryUpgradeable,
    ReentrancyGuardUpgradeable,
    UniverseImplementationPointerUpgradeable,
    LiquidityPoolManagerImplementationPointerUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;

    struct PlanetInfoEntity {
        PlanetEntity planet;
        uint256 id;
        uint256 pendingRewards;
        uint256 rewardPerDay;
        uint256 compoundDelay;
    }

    struct PlanetEntity {
        uint256 id;
        string name;
        uint256 creationTime;
        uint256 lastProcessingTimestamp;
        uint256 rewardMult;
        uint256 planetValue;
        uint256 totalClaimed;
        bool exists;
    }

    struct TierStorage {
        uint256 rewardMult;
        uint256 amountLockedInTier;
        bool exists;
    }

    CountersUpgradeable.Counter private _planetCounter;
    mapping(uint256 => PlanetEntity) private _planets;
    mapping(uint256 => TierStorage) private _tierTracking;
    uint256[] _tiersTracked;

    uint256 public rewardPerDay;
    uint256 public creationMinPrice;
    uint256 public compoundDelay;
    uint256 public processingFee;

    uint24[6] public tierLevel;
    uint16[6] public tierSlope;

    uint256 private constant ONE_DAY = 86400;
    uint256 public totalValueLocked;

    uint256 public burnedFromRenaming;

    modifier onlyPlanetOwner() {
        address sender = _msgSender();
        require(
            sender != address(0),
            "Planets: Cannot be from the zero address"
        );
        require(
            isOwnerOfPlanets(sender),
            "Planets: No Planet owned by this account"
        );
        require(
            !liquidityPoolManager.isFeeReceiver(sender),
            "Planets: Fee receivers cannot own Planets"
        );
        _;
    }

    modifier checkPermissions(uint256 _planetId) {
        address sender = _msgSender();
        require(planetExists(_planetId), "Planets: This planet doesn't exist");
        require(
            isOwnerOfPlanet(sender, _planetId),
            "Planets: You do not control this Planet"
        );
        _;
    }

    modifier universeSet() {
        require(
            address(universe) != address(0),
            "Planets: Universe is not set"
        );
        _;
    }

    event Compound(
        address indexed account,
        uint256 indexed planetId,
        uint256 amountToCompound
    );
    event Cashout(
        address indexed account,
        uint256 indexed planetId,
        uint256 rewardAmount
    );

    event CompoundAll(
        address indexed account,
        uint256[] indexed affectedPlanets,
        uint256 amountToCompound
    );
    event CashoutAll(
        address indexed account,
        uint256[] indexed affectedPlanets,
        uint256 rewardAmount
    );

    event Create(
        address indexed account,
        uint256 indexed newPlanetId,
        uint256 amount
    );

    event Rename(
        address indexed account,
        string indexed previousName,
        string indexed newName
    );

    function initialize() external initializer {
        __ERC721_init("Ape Universe Ecosystem", "ApeES");
        __Ownable_init();
        __ERC721Enumerable_init();
        __ERC721URIStorage_init();
        __ReentrancyGuard_init();
        __Pausable_init();

        // Initialize contract
        changeNodeMinPrice(52_000 * (10**18)); // 52,000 ApeU
        changeCompoundDelay(43200); // 12h
        changeProcessingFee(30); // 30%
        changeTierSystem(
            [100000, 105000, 110000, 120000, 130000, 140000],
            [1000, 500, 100, 50, 10, 0]
        );
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
        returns (string memory)
    {
        // return Strings.strConcat(
        //     _baseTokenURI(),
        //     Strings.uint2str(tokenId)
        // );

        // ToDo: fix this
        // To fix: https://andyhartnett.medium.com/solidity-tutorial-how-to-store-nft-metadata-and-svgs-on-the-blockchain-6df44314406b
        // Base64 support for names coming: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2884/files
        //string memory tokenURI = "test";
        //_setTokenURI(newPlanetId, tokenURI);

        return ERC721URIStorageUpgradeable.tokenURI(tokenId);
    }

    function renamePlanet(uint256 _planetId, string memory planetName)
        external
        nonReentrant
        onlyPlanetOwner
        checkPermissions(_planetId)
        whenNotPaused
        universeSet
    {
        address account = _msgSender();
        require(
            bytes(planetName).length > 1 && bytes(planetName).length < 32,
            "Planets: Incorrect name length, must be between 2 to 31"
        );
        PlanetEntity storage planet = _planets[_planetId];
        require(planet.planetValue > 0, "Error: Planet is empty");
        (uint256 newPlanetValue, uint256 feeAmount) = getProcessingFee(
            planet.planetValue,
            5
        );
        logTier(planet.rewardMult, -int256(feeAmount));
        burnedFromRenaming += feeAmount;
        planet.planetValue = newPlanetValue;
        string memory previousName = planet.name;
        planet.name = planetName;
        emit Rename(account, previousName, planetName);
    }

    function createPlanetWithTokens(
        string memory planetName,
        uint256 planetValue
    ) external nonReentrant whenNotPaused universeSet returns (uint256) {
        address sender = _msgSender();

        require(
            bytes(planetName).length > 1 && bytes(planetName).length < 32,
            "Planets: Incorrect name length, must be between 2 to 31"
        );
        require(
            planetValue >= creationMinPrice,
            "Planets: Planet value set below minimum"
        );
        require(
            isNameAvailable(sender, planetName),
            "Planets: Name not available"
        );
        require(
            universe.balanceOf(sender) >= creationMinPrice,
            "Planets: Balance too low for creation"
        );

        // Burn the tokens used to mint the NFT
        universe.accountBurn(sender, planetValue);

        // Increment the total number of tokens
        _planetCounter.increment();

        uint256 newPlanetId = _planetCounter.current();
        uint256 currentTime = block.timestamp;

        // Add this to the TVL
        totalValueLocked += planetValue;
        logTier(tierLevel[0], int256(planetValue));

        // Add Planet
        _planets[newPlanetId] = PlanetEntity({
            id: newPlanetId,
            name: planetName,
            creationTime: currentTime,
            lastProcessingTimestamp: currentTime,
            rewardMult: tierLevel[0],
            planetValue: planetValue,
            totalClaimed: 0,
            exists: true
        });

        // Assign the Planet to this account
        _mint(sender, newPlanetId);

        emit Create(sender, newPlanetId, planetValue);

        return newPlanetId;
    }

    function cashoutReward(uint256 _planetId)
        external
        nonReentrant
        onlyPlanetOwner
        checkPermissions(_planetId)
        whenNotPaused
        universeSet
    {
        address account = _msgSender();
        uint256 reward = _getPlanetCashoutRewards(_planetId);
        _cashoutReward(reward);

        emit Cashout(account, _planetId, reward);
    }

    function cashoutAll()
        external
        nonReentrant
        onlyPlanetOwner
        whenNotPaused
        universeSet
    {
        address account = _msgSender();
        uint256 rewardsTotal = 0;

        uint256[] memory planetsOwned = getPlanetIdsOf(account);
        for (uint256 i = 0; i < planetsOwned.length; i++) {
            rewardsTotal += _getPlanetCashoutRewards(planetsOwned[i]);
        }
        _cashoutReward(rewardsTotal);

        emit CashoutAll(account, planetsOwned, rewardsTotal);
    }

    function compoundReward(uint256 _planetId)
        external
        nonReentrant
        onlyPlanetOwner
        checkPermissions(_planetId)
        whenNotPaused
        universeSet
    {
        address account = _msgSender();

        (
            uint256 amountToCompound,
            uint256 feeAmount
        ) = _getPlanetCompoundRewards(_planetId);
        require(
            amountToCompound > 0,
            "Planets: You must wait until you can compound again"
        );
        if (feeAmount > 0) {
            universe.liquidityReward(feeAmount);
        }

        emit Compound(account, _planetId, amountToCompound);
    }

    function compoundAll()
        external
        nonReentrant
        onlyPlanetOwner
        whenNotPaused
        universeSet
    {
        address account = _msgSender();
        uint256 feesAmount = 0;
        uint256 amountsToCompound = 0;
        uint256[] memory planetsOwned = getPlanetIdsOf(account);
        uint256[] memory planetsAffected = new uint256[](planetsOwned.length);

        for (uint256 i = 0; i < planetsOwned.length; i++) {
            (
                uint256 amountToCompound,
                uint256 feeAmount
            ) = _getPlanetCompoundRewards(planetsOwned[i]);
            if (amountToCompound > 0) {
                planetsAffected[i] = planetsOwned[i];
                feesAmount += feeAmount;
                amountsToCompound += amountToCompound;
            } else {
                delete planetsAffected[i];
            }
        }

        require(amountsToCompound > 0, "Planets: No rewards to compound");
        if (feesAmount > 0) {
            universe.liquidityReward(feesAmount);
        }

        emit CompoundAll(account, planetsAffected, amountsToCompound);
    }

    // Private reward functions

    function _getPlanetCashoutRewards(uint256 _planetId)
        private
        returns (uint256)
    {
        PlanetEntity storage planet = _planets[_planetId];

        if (!isProcessable(planet)) {
            return 0;
        }

        uint256 reward = calculateReward(planet);
        planet.totalClaimed += reward;

        if (planet.rewardMult != tierLevel[0]) {
            logTier(planet.rewardMult, -int256(planet.planetValue));
            logTier(tierLevel[0], int256(planet.planetValue));
        }

        planet.rewardMult = tierLevel[0];
        planet.lastProcessingTimestamp = block.timestamp;
        return reward;
    }

    function _getPlanetCompoundRewards(uint256 _planetId)
        private
        returns (uint256, uint256)
    {
        PlanetEntity storage planet = _planets[_planetId];

        if (!isProcessable(planet)) {
            return (0, 0);
        }

        uint256 reward = calculateReward(planet);
        if (reward > 0) {
            (uint256 amountToCompound, uint256 feeAmount) = getProcessingFee(
                reward,
                26
            );
            totalValueLocked += amountToCompound;

            logTier(planet.rewardMult, -int256(planet.planetValue));

            planet.lastProcessingTimestamp = block.timestamp;
            planet.planetValue += amountToCompound;
            planet.rewardMult += increaseMultiplier(planet.rewardMult);

            logTier(planet.rewardMult, int256(planet.planetValue));

            return (amountToCompound, feeAmount);
        }

        return (0, 0);
    }

    function _cashoutReward(uint256 amount) private {
        require(
            amount > 0,
            "Planets: You don't have enough reward to cash out"
        );
        address to = _msgSender();
        (uint256 amountToReward, uint256 feeAmount) = getProcessingFee(
            amount,
            30
        );
        universe.accountReward(to, amountToReward);
        // Send the fee to the contract where liquidity will be added later on
        universe.liquidityReward(feeAmount);
    }

    function logTier(uint256 mult, int256 amount) private {
        TierStorage storage tierStorage = _tierTracking[mult];
        if (tierStorage.exists) {
            require(
                tierStorage.rewardMult == mult,
                "Planets: rewardMult does not match in TierStorage"
            );
            uint256 amountLockedInTier = uint256(
                int256(tierStorage.amountLockedInTier) + amount
            );
            require(
                amountLockedInTier >= 0,
                "Planets: amountLockedInTier cannot underflow"
            );
            tierStorage.amountLockedInTier = amountLockedInTier;
        } else {
            // Tier isn't registered exist, register it
            require(
                amount > 0,
                "Planets: Fatal error while creating new TierStorage. Amount cannot be below zero."
            );
            _tierTracking[mult] = TierStorage({
                rewardMult: mult,
                amountLockedInTier: uint256(amount),
                exists: true
            });
            _tiersTracked.push(mult);
        }
    }

    // Private view functions

    function getProcessingFee(uint256 rewardAmount, uint256 _feeAmount)
        private
        pure
        returns (uint256, uint256)
    {
        uint256 feeAmount = 0;
        if (_feeAmount > 0) {
            feeAmount = (rewardAmount * _feeAmount) / 100;
        }
        return (rewardAmount - feeAmount, feeAmount);
    }

    function increaseMultiplier(uint256 prevMult)
        private
        view
        returns (uint256)
    {
        if (prevMult >= tierLevel[5]) {
            return tierSlope[5];
        } else if (prevMult >= tierLevel[4]) {
            return tierSlope[4];
        } else if (prevMult >= tierLevel[3]) {
            return tierSlope[2];
        } else if (prevMult >= tierLevel[2]) {
            return tierSlope[2];
        } else if (prevMult >= tierLevel[1]) {
            return tierSlope[1];
        } else {
            return tierSlope[0];
        }
    }

    function isProcessable(PlanetEntity memory planet)
        private
        view
        returns (bool)
    {
        return
            block.timestamp >= planet.lastProcessingTimestamp + compoundDelay;
    }

    function calculateReward(PlanetEntity memory planet)
        private
        view
        returns (uint256)
    {
        return
            _calculateRewardsFromValue(
                planet.planetValue,
                planet.rewardMult,
                block.timestamp - planet.lastProcessingTimestamp,
                rewardPerDay
            );
    }

    function rewardPerDayFor(PlanetEntity memory planet)
        private
        view
        returns (uint256)
    {
        return
            _calculateRewardsFromValue(
                planet.planetValue,
                planet.rewardMult,
                ONE_DAY,
                rewardPerDay
            );
    }

    function _calculateRewardsFromValue(
        uint256 _planetValue,
        uint256 _rewardMult,
        uint256 _timeRewards,
        uint256 _rewardPerDay
    ) private pure returns (uint256) {
        uint256 rewards = (_timeRewards * _rewardPerDay) / 1000000;
        uint256 rewardsMultiplicated = (rewards * _rewardMult) / 100000;
        return (rewardsMultiplicated * _planetValue) / 100000;
    }

    function planetExists(uint256 _planetId) private view returns (bool) {
        require(_planetId > 0, "Planets: Id must be higher than zero");
        PlanetEntity memory planet = _planets[_planetId];
        if (planet.exists) {
            return true;
        }
        return false;
    }

    // Public view functions

    function calculateTotalDailyEmission() external view returns (uint256) {
        uint256 dailyEmission = 0;
        for (uint256 i = 0; i < _tiersTracked.length; i++) {
            TierStorage memory tierStorage = _tierTracking[_tiersTracked[i]];
            dailyEmission += _calculateRewardsFromValue(
                tierStorage.amountLockedInTier,
                tierStorage.rewardMult,
                ONE_DAY,
                rewardPerDay
            );
        }
        return dailyEmission;
    }

    function isNameAvailable(address account, string memory planetName)
        public
        view
        returns (bool)
    {
        uint256[] memory planetsOwned = getPlanetIdsOf(account);
        for (uint256 i = 0; i < planetsOwned.length; i++) {
            PlanetEntity memory planet = _planets[planetsOwned[i]];
            if (keccak256(bytes(planet.name)) == keccak256(bytes(planetName))) {
                return false;
            }
        }
        return true;
    }

    function isOwnerOfPlanets(address account) public view returns (bool) {
        return balanceOf(account) > 0;
    }

    function isOwnerOfPlanet(address account, uint256 _planetId)
        public
        view
        returns (bool)
    {
        uint256[] memory planetIdsOf = getPlanetIdsOf(account);
        for (uint256 i = 0; i < planetIdsOf.length; i++) {
            if (planetIdsOf[i] == _planetId) {
                return true;
            }
        }
        return false;
    }

    function getPlanetIdsOf(address account)
        public
        view
        returns (uint256[] memory)
    {
        uint256 numberOfPlanets = balanceOf(account);
        uint256[] memory planetIds = new uint256[](numberOfPlanets);
        for (uint256 i = 0; i < numberOfPlanets; i++) {
            uint256 planetId = tokenOfOwnerByIndex(account, i);
            require(
                planetExists(planetId),
                "Planets: This planet doesn't exist"
            );
            planetIds[i] = planetId;
        }
        return planetIds;
    }

    function getPlanetsByIds(uint256[] memory _planetIds)
        external
        view
        returns (PlanetInfoEntity[] memory)
    {
        PlanetInfoEntity[] memory planetsInfo = new PlanetInfoEntity[](
            _planetIds.length
        );
        for (uint256 i = 0; i < _planetIds.length; i++) {
            uint256 planetId = _planetIds[i];
            PlanetEntity memory planet = _planets[planetId];
            planetsInfo[i] = PlanetInfoEntity(
                planet,
                planetId,
                calculateReward(planet),
                rewardPerDayFor(planet),
                compoundDelay
            );
        }
        return planetsInfo;
    }

    // Owner functions

    function changeNodeMinPrice(uint256 _creationMinPrice) public onlyOwner {
        require(
            _creationMinPrice > 0,
            "Planets: Minimum price to create a Planet must be above 0"
        );
        creationMinPrice = _creationMinPrice;
    }

    function changeCompoundDelay(uint256 _compoundDelay) public onlyOwner {
        require(
            _compoundDelay > 0,
            "Planets: compoundDelay must be greater than 0"
        );
        compoundDelay = _compoundDelay;
    }

    function changeRewardPerDay() public onlyOwner {
        // Change to 3 percent per day
        rewardPerDay = 34724;
    }

    function changeTierSystem(
        uint24[6] memory _tierLevel,
        uint16[6] memory _tierSlope
    ) public onlyOwner {
        require(
            _tierLevel.length == 6,
            "Planets: newTierLevels length has to be 6"
        );
        require(
            _tierSlope.length == 6,
            "Planets: newTierSlopes length has to be 6"
        );
        tierLevel = _tierLevel;
        tierSlope = _tierSlope;
    }

    function changeProcessingFee(uint8 _processingFee) public onlyOwner {
        require(_processingFee <= 30, "Cashout fee can never exceed 30%");
        processingFee = _processingFee;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    // Mandatory overrides

    function _burn(uint256 tokenId)
        internal
        override(ERC721URIStorageUpgradeable, ERC721Upgradeable)
    {
        ERC721Upgradeable._burn(tokenId);
        ERC721URIStorageUpgradeable._burn(tokenId);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    )
        internal
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal onlyInitializing {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}