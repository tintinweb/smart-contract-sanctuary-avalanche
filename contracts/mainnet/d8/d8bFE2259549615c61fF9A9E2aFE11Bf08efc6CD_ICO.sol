pragma solidity ^0.5.0;

import "./Crowdsale.sol";
import "./CappedCrowdSale/CappedCrowdsale.sol";
import "./CappedCrowdSale/IndividuallyCappedCrowdsale.sol";
import "./Whitelist/WhitelistCrowdsale.sol";
import "./TimedCrowdsale.sol";
import "./Funds/WithdrawFunds.sol";

contract ICO is
    Crowdsale,
    CappedCrowdsale,
    IndividuallyCappedCrowdsale,
    WhitelistCrowdsale,
    WithdrawFunds,
    TimedCrowdsale
{
    /** @param wallet wallet address where funds are to be sent */
    /**@param cap hardcap */
    /**@param individualCap Inidividual Wallet Hard Cap */
    /**@param individualMin Inidividual Wallet Min Contribution */
    constructor(
        address payable wallet,
        uint256 cap,
        uint256 scap,
        uint256 individualMin,
        uint256 closingTime
    )
        public
        Crowdsale(wallet)
        WithdrawFunds()
        TimedCrowdsale(closingTime)
        WhitelistCrowdsale()
        CappedCrowdsale(cap, scap)
        IndividuallyCappedCrowdsale(individualMin)
    {}
}

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

pragma solidity ^0.5.0;

import "../Context.sol";
import "../library/Roles.sol";
import "./WhitelistAdminRole.sol";

/**
 * @title WhitelistedRole
 * @dev Whitelisted accounts have been approved by a WhitelistAdmin to perform certain actions (e.g. participate in a
 * crowdsale). This role is special in that the only accounts that can add it are WhitelistAdmins (who can also remove
 * it), and not Whitelisteds themselves.
 */
contract WhitelistedRole is Context, WhitelistAdminRole {
    using Roles for Roles.Role;

    event WhitelistedAdded(address indexed account);
    event WhitelistedRemoved(address indexed account);

    Roles.Role private _whitelisteds;

    modifier onlyWhitelisted() {
        require(isWhitelisted(_msgSender()), "WhitelistedRole: caller does not have the Whitelisted role");
        _;
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisteds.has(account);
    }

    function addWhitelisted(address account) public onlyWhitelistAdmin {
        _addWhitelisted(account);
    }

    function removeWhitelisted(address account) public onlyWhitelistAdmin {
        _removeWhitelisted(account);
    }

    function renounceWhitelisted() public {
        _removeWhitelisted(_msgSender());
    }

    function _addWhitelisted(address account) internal {
        _whitelisteds.add(account);
        emit WhitelistedAdded(account);
    }

    function _removeWhitelisted(address account) internal {
        _whitelisteds.remove(account);
        emit WhitelistedRemoved(account);
    }
}

pragma solidity ^0.5.0;
import "../Crowdsale.sol";
import "./WhitelistedRole.sol";

/**
 * @title WhitelistCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WhitelistCrowdsale is WhitelistedRole, Crowdsale {
    /**
     * @dev Extend parent behavior requiring beneficiary to be whitelisted. Note that no
     * restriction is imposed on the account sending the transaction.
     * @param _beneficiary Token beneficiary
     * @param _weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        view
    {
        require(
            isWhitelisted(_beneficiary),
            "WhitelistCrowdsale: beneficiary doesn't have the Whitelisted role"
        );
        super._preValidatePurchase(_beneficiary, _weiAmount);
    }
}

pragma solidity ^0.5.0;

import "../Context.sol";
import "../library/Roles.sol";

/**
 * @title WhitelistAdminRole
 * @dev WhitelistAdmins are responsible for assigning and removing Whitelisted accounts.
 */
contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}

pragma solidity ^0.5.0;

import "./library/SafeMath.sol";
import "./Crowdsale.sol";
import "./Context.sol";

/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _closingTime;

    /**
     * Event for crowdsale extending
     * @param newClosingTime new closing time
     * @param prevClosingTime old closing time
     */
    event TimedCrowdsaleExtended(
        uint256 prevClosingTime,
        uint256 newClosingTime
    );

    /**
     * @dev Constructor, takes crowdsale opening and closing times.
     * @param closingTime Crowdsale closing time
     */
    constructor(uint256 closingTime) public {
        // solhint-disable-next-line max-line-length
        require(
            closingTime > block.timestamp,
            "TimedCrowdsale: closing time is before current time"
        );
        _closingTime = closingTime;
    }

    /**
     * @return the crowdsale closing time.
     */
    function closingTime() public view returns (uint256) {
        return _closingTime;
    }

    /**
     * @dev Checks whether the period in which the crowdsale is open has already elapsed.
     * @return Whether crowdsale period has elapsed
     */
    function hasClosed() public view returns (bool) {
        // solhint-disable-next-line not-rely-on-time
        return block.timestamp > _closingTime;
    }

    /**
     * @dev withdraw after crowsale has ended.
     */
    function _preValidateWithdraw() internal view {
        require(hasClosed(), "Please wait for buffer time to complete");
        super._preValidateWithdraw();
    }

    modifier isDev() {
        require(msg.sender == dev());
        _;
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function extendTime(uint256 newClosingTime) external isDev {
        require(!hasClosed(), "TimedCrowdsale: already closed");
        // solhint-disable-next-line max-line-length
        require(
            newClosingTime > _closingTime,
            "TimedCrowdsale: new closing time is before current closing time"
        );

        emit TimedCrowdsaleExtended(_closingTime, newClosingTime);
        _closingTime = newClosingTime;
    }

    /**
     * @dev Extend crowdsale.
     * @param newClosingTime Crowdsale closing time
     */
    function reduceTime(uint256 newClosingTime) external isDev {
        require(!hasClosed(), "TimedCrowdsale: already closed");
        // solhint-disable-next-line max-line-length
        require(
            newClosingTime < _closingTime,
            "TimedCrowdsale: new closing time is before current closing time"
        );
        require(
            newClosingTime > block.timestamp,
            "TimedCrowdsale: new closing time is before current time"
        );

        _closingTime = newClosingTime;
    }
}

pragma solidity ^0.5.0;

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
 *
 * _Since v2.5.0:_ this module is now much more gas efficient, given net gas
 * metering changes introduced in the Istanbul hardfork.
 */
contract ReentrancyGuard {
    bool private _notEntered;

    constructor () internal {
        // Storing an initial non-zero value makes deployment a bit more
        // expensive, but in exchange the refund on every call to nonReentrant
        // will be lower in amount. Since refunds are capped to a percetange of
        // the total transaction's gas, it is best to keep them low in cases
        // like this one, to increase the likelihood of the full refund coming
        // into effect.
        _notEntered = true;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_notEntered, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _notEntered = false;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _notEntered = true;
    }
}

pragma solidity ^0.5.0;

import "../Context.sol";
import "../library/Roles.sol";

contract WithdrawFundsAdmin is Context {
    using Roles for Roles.Role;

    event WithdrawFundsAdminAdded(address indexed account);

    Roles.Role private _withdrawFundsAdmins;

    constructor() internal {
        _addWithdrawFundsAdmin(_msgSender());
    }

    modifier onlyWithdrawFundsAdmin() {
        require(
            isWithdrawFundsAdmin(_msgSender()),
            "WithdrawFundsAdmins: caller does not have the WithdrawFundsAdmins role"
        );
        _;
    }

    function isWithdrawFundsAdmin(address account) public view returns (bool) {
        return _withdrawFundsAdmins.has(account);
    }

    function addWithdrawFundsAdmins(address account)
        public
        onlyWithdrawFundsAdmin
    {
        _addWithdrawFundsAdmin(account);
    }

    function _addWithdrawFundsAdmin(address account) internal {
        _withdrawFundsAdmins.add(account);
        emit WithdrawFundsAdminAdded(account);
    }
}

pragma solidity ^0.5.0;
import "../Crowdsale.sol";
import "./WithdrawFundsAdmin.sol";

/**
 * @title WhitelistCrowdsale
 * @dev Crowdsale in which only whitelisted users can contribute.
 */
contract WithdrawFunds is Crowdsale, WithdrawFundsAdmin {
    /**
     * @dev Extend parent behavior requiring beneficiary to be whitelisted. Note that no
     * restriction is imposed on the account sending the transaction.
     */
    function _preValidateWithdraw() internal view {
        require(
            isWithdrawFundsAdmin(msg.sender),
            "WithdrawFundsAdmin: beneficiary doesn't have the WithdrawFundsAdmin role"
        );
        super._preValidateWithdraw();
    }
}

pragma solidity ^0.5.0;

import "./Context.sol";
// import "../token/ERC20/IERC20.sol";
import "./library/SafeMath.sol";
// import "../token/ERC20/SafeERC20.sol";
import "./ReentrancyGuard.sol";


/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conforms
 * the base architecture for crowdsales. It is *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale is Context, ReentrancyGuard {
    using SafeMath for uint256;
    // using SafeERC20 for IERC20;

    // The token being sold
    // IERC20 private _token;

    // Address where funds are collected
    address payable private _wallet;
    address payable private _dev;

    // How many token units a buyer gets per wei.
    // The rate is the conversion between wei and the smallest and indivisible token unit.
    // So, if you are using a rate of 1 with a ERC20Detailed token with 3 decimals called TOK
    // 1 wei will give you 1 unit, or 0.001 TOK.
    // uint256 private _rate;

    // Amount of wei raised
    uint256 private _weiRaised;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     */
    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value
    );

    /**
     * @dev The rate is the conversion between wei and the smallest and indivisible
     * token unit. So, if you are using a rate of 1 with a ERC20Detailed token
     * with 3 decimals called TOK, 1 wei will give you 1 unit, or 0.001 TOK.
     * @param wallet Address where collected funds will be forwarded to
     */
    constructor(address payable wallet) public {
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        _dev = msg.sender;
        _wallet = wallet;
    }
    
    /**
     * @dev fallback function ***DO NOT OVERRIDE***
     * Note that other contracts will transfer funds with a base gas stipend
     * of 2300, which is not enough to call buyTokens. Consider calling
     * buyTokens directly when purchasing tokens from a contract.
     */
     function dev() public view returns (address payable) {
        return _dev;
    }
    function() external payable {
        buyTokens(_msgSender());
    }

    /**
     * @return the token being sold.
     */
    // function token() public view returns (IERC20) {
    //     return _token;
    // }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    // function rate() public view returns (uint256) {
    //     return _rate;
    // }

    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * This function has a non-reentrancy guard, so it shouldn't be called by
     * another `nonReentrant` function.
     * @param beneficiary Recipient of the token purchase
     */
    function buyTokens(address beneficiary) public payable nonReentrant {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        // uint256 tokens = _getTokenAmount(weiAmount);

        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        // _processPurchase(beneficiary, tokens);
        emit TokensPurchased(_msgSender(), beneficiary, weiAmount);

        _updatePurchasingState(beneficiary, weiAmount);

        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met.
     * Use `super` in contracts that inherit from Crowdsale to extend their validations.
     * Example from CappedCrowdsale.sol's _preValidatePurchase method:
     *     super._preValidatePurchase(beneficiary, weiAmount);
     *     require(weiRaised().add(weiAmount) <= cap);
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
    {
        require(
            beneficiary != address(0),
            "Crowdsale: beneficiary is the zero address"
        );
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    // function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
    //     _token.safeTransfer(beneficiary, tokenAmount);
    // }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    // function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
    //     _deliverTokens(beneficiary, tokenAmount);
    // }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount)
        internal
    {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    // function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    //     return weiAmount.mul(_rate);
    // }

    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function withdrawFunds() external {
        _preValidateWithdraw();
        _dev.transfer((address(this).balance).mul(20).div(100));
         withdrawRem();
    }

    function withdrawRem() internal{
         _wallet.transfer(address(this).balance);
    }
    function _preValidateWithdraw() internal view {

    }
}

pragma solidity ^0.5.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "../library/SafeMath.sol";
import "../Crowdsale.sol";

/**
 * @title IndividuallyCappedCrowdsale
 * @dev Crowdsale with per-beneficiary caps.
 */
contract IndividuallyCappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _individualMin;
    mapping(address => uint256) private _contributions;

    /**
     * @dev Constructor, takes Minimum and Maximum contribution amount of wei per beneficiary
     * @param individualMin Min amount of wei to be contributed per beneficiary
     */
    constructor(uint256 individualMin) public {
        require(
            individualMin > 0,
            "IndividuallyCappedCrowdsale: Minimum contribution is zero"
        );
        _individualMin = individualMin;
    }


    /**
     * @return the cap of the crowdsale.
     */
    function minContribution() public view returns (uint256) {
        return _individualMin;
    }

    /**
     * @dev Returns the amount contributed so far by a specific beneficiary.
     * @param beneficiary Address of contributor
     * @return Beneficiary contribution so far
     */
    function getContribution(address beneficiary)
        public
        view
        returns (uint256)
    {
        return _contributions[beneficiary];
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the beneficiary's funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount)
        internal
        view
    {
        super._preValidatePurchase(beneficiary, weiAmount);
        // solhint-disable-next-line max-line-length
        require(
            weiAmount >= _individualMin,
            "IndividuallyCappedCrowdsale: beneficiary's contribution too low"
        );
    }

    /**
     * @dev Extend parent behavior to update beneficiary contributions.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount)
        internal
    {
        super._updatePurchasingState(beneficiary, weiAmount);
        _contributions[beneficiary] = _contributions[beneficiary].add(
            weiAmount
        );
    }
}

pragma solidity ^0.5.0;

import "../library/SafeMath.sol";
import "../Crowdsale.sol";

/**
 * @title CappedCrowdsale
 * @dev Crowdsale with a limit for total contributions.
 */
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 private _scap;   
    uint256 private _cap;

    /**
        * @dev Constructor, takes maximum amount of wei accepted in the crowdsale.
        * @param cap Max amount of wei to be contributed
        * @param scap is soft cap amount of wei to be contributed
     */
    constructor (uint256 cap, uint256 scap) public {
        require(cap > 0, "CappedCrowdsale: cap is 0");
        require(scap < cap, "CappedCrowdsale: scap is greater than hard cap");
        _cap = cap;
        _scap = scap;
    }

    /**
     * @return the cap of the crowdsale.
     */
    function cap() public view returns (uint256) {
        return _cap;
    }
    /**
     * @return the scap of the crowdsale.
     */
    function scap() public view returns (uint256) {
        return _scap;
    }

    /**
     * @dev Checks whether the cap has been reached.
     * @return Whether the cap was reached
     */
    function capReached() public view returns (bool) {
        return weiRaised() >= _cap;
    }

    /**
     * @dev Extend parent behavior requiring purchase to respect the funding cap.
     * @param beneficiary Token purchaser
     * @param weiAmount Amount of wei contributed
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        super._preValidatePurchase(beneficiary, weiAmount);
        require(weiRaised().add(weiAmount) <= _cap, "CappedCrowdsale: cap exceeded");
    }
}