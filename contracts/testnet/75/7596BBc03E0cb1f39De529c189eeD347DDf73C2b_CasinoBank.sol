// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract CasinoBank is Ownable, Pausable {
    /// address controlled by the backend service in charge of the users chips balance
    address public validator;

    /** 
     * price of a single chip 
     * @dev should not be un-constant-ed
     */
    uint256 public constant singleChipPrice = 0.05 ether;

    /// how much chips max you can be buy per tx
    uint16 public maxChipsBuyableAtOnce = 200;

    /// tax applied on chips conversion to currency in base points
    uint16 public constant taxInBasePoints = 500;

    /// how much chips bought ever by addresses
    mapping(address => uint32) public totalBoughtChips;

    /// maximum amount of chips we can bet on a single bet
    uint16 public maxChipsPerBet = 20;

    /// how much of the current contract balance is tax revenue
    uint256 public taxRevenue;

    receive() external payable {}

    fallback() external payable {}

    //
    constructor(address validator_) {
        _updateValidator(validator_);
    }

    //
    // PLAYER ONLY
    //

    /**
     * checks whenever withdrawal is possible for a specified amount of coin
     */
    function isWithdrawPossible(uint16 amountOfCoins_)
        external
        view
        returns (bool)
    {
        //
        uint256 balance_ = address(this).balance;
        uint256 taxR_ = taxRevenue;

        // tax revenue should never exceed the balance
        if (taxR_ >= balance_) return false;

        //
        uint256 available_ = balance_ - taxR_;
        uint256 toWithdraw_ = singleChipPrice * amountOfCoins_;

        //
        return available_ >= toWithdraw_;
    }

    /**
     * Returns price components of a single chip
     * @return taxIncluded_ price of a single chip, tax included
     * @return taxPart_ represents tax fraction of the full price
     */
    function singleChipBuyPrice()
        public
        pure
        returns (uint256 taxIncluded_, uint256 taxPart_)
    {
        uint256 singleChipPrice_ = singleChipPrice;
        taxPart_ = (singleChipPrice_ * taxInBasePoints) / 10_000;
        taxIncluded_ = singleChipPrice_ + taxPart_;
    }

    /** @notice thrown when enclosed currency while buying coins does not match exactly a set amount of coins */
    error InvalidPaymentForCoins();

    /** @notice thrown if trying to buy more coins at once than the configured limit */
    error BuyingTooMuchCoinsAtOnce();

    /** */
    event ChipsBought(address indexed buyer, uint32 amount);

    /**
     *
     */
    function buyCasinoChips() external payable whenNotPaused {
        //
        (uint256 taxIncluded_, uint256 taxPart_) = singleChipBuyPrice();

        //
        if (msg.value % taxIncluded_ != 0) revert("InvalidPaymentForCoins");

        //
        uint16 howManyChipsToBuy_ = uint16(msg.value / taxIncluded_);

        //
        if (howManyChipsToBuy_ > maxChipsBuyableAtOnce)
            revert("BuyingTooMuchCoinsAtOnce");

        //
        totalBoughtChips[_msgSender()] += howManyChipsToBuy_;

        //
        taxRevenue += taxPart_ * howManyChipsToBuy_;

        //
        emit ChipsBought(_msgSender(), howManyChipsToBuy_);
    }

    //
    // VALIDATOR ONLY
    //

    /** @notice thrown when anyone but a validator tries to call bound function*/
    error OnlyValidator();

    //
    modifier onlyValidator() {
        if (_msgSender() != validator) revert("OnlyValidator");
        _;
    }

    /** @notice */
    event ChipsConverted(address indexed grantedTo, uint16 coinsAmount, uint256 convertedAmount);

    /**
     * VALIDATOR ONLY
     * Allows the validator, which controls the actual state of any player chips balance, to give back currency in exchange of chips
     */
    function convertChips(address payable withdrawer_, uint16 amountOfCoins_)
        external
        onlyValidator
        whenNotPaused
    {
        //
        uint256 owed_ = singleChipPrice * amountOfCoins_;

        //
        emit ChipsConverted(withdrawer_, amountOfCoins_, owed_);

        //
        (bool success, ) = withdrawer_.call{
            value: owed_
        }("");
        require(success, "convertChips() transfer failed.");
    }

    //
    // OWNER ONLY
    //

    /** @notice */
    event BankBalanceSustained(uint256 amount);

    /**
     * OWNER ONLY
     * Feeds the bank with excedentary funds that backs the sustainability of said contract
     * @dev allows tracking of intent and amount via event emission, instead of using silent fallback() or receive()
     */
    function feedBank() external payable onlyOwner {
        emit BankBalanceSustained(msg.value);
    }

    /** @notice */
    event MaxChipsPetBetChanged(uint16 newMax);

    /**
     * OWNER ONLY
     * self-explainatory
     */
    function setMaxChipsPerBet(uint16 maxChipsPerBet_) external onlyOwner {
        //
        maxChipsPerBet = maxChipsPerBet_;

        //
        emit MaxChipsPetBetChanged(maxChipsPerBet_);
    }

    /** @notice emitted whenever validator changed */
    event ValidatorChanged(address validator);

    /**
     * OWNER ONLY
     * self-explainatory
     */
    function setValidator(address validator_) external onlyOwner {
        //
        _updateValidator(validator_);

        //
        emit ValidatorChanged(validator_);
    }

    /** @notice */
    event MaxChipsBuyableAtOnceChanged(uint16 newMaximum);

    /**
     * OWNER ONLY
     * self-explainatory
     */
    function setMaxChipsBuyableAtOnce(uint16 maxBuyableChips_)
        external
        onlyOwner
    {
        //
        maxChipsBuyableAtOnce = maxBuyableChips_;

        //
        emit MaxChipsBuyableAtOnceChanged(maxBuyableChips_);
    }

    /** @notice */
    event EmergencyTransferToOwner(address owner, uint256 amount);

    /**
     * OWNER ONLY
     * Failsafe withdrawal method
     * @dev most likely to break tax revenue accountability, use with care and extreme caution in extreme cases !
     * @dev no reentracy-guard needed
     */
    function emergencyTransferToOwner(uint256 amount_) external onlyOwner {
        //
        emit EmergencyTransferToOwner(owner(), amount_);

        // https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        (bool success, ) = owner().call{value: amount_}("");
        require(success, "emergencyTransferToOwner() failed.");
    }

    /** @notice */
    event TaxRevenueReleased(uint256 amount);

    /**
     * OWNER ONLY
     * Releases tax revenue accumulated at chips buys, allow it to be usable as player withdrawal counterpart
     * Should be used to alleviate pressure on temporary deficitary trends
     */
    function releaseTaxRevenue(uint256 toRelease_) external onlyOwner {
        //
        _releaseTaxRevenue(toRelease_);

        //
        emit TaxRevenueReleased(toRelease_);
    }

    /** @notice */
    event TaxRevenueTransfered(address receiver, uint256 amount);

    /**
     * OWNER ONLY
     * transfer part of the tax revenue accumulated to another account / contract
     * @param amount_ can be 0, means that we want to transfer all tax revenue
     * @dev no reentracy-guard needed
     */
    function transferTaxGainsTo(address receiver_, uint256 amount_)
        external
        onlyOwner
    {
        // @dev: make sure to update internal state before calling external entities
        amount_ = _releaseTaxRevenue(amount_);

        // emiting before
        emit TaxRevenueTransfered(receiver_, amount_);

        // https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/
        (bool success, ) = receiver_.call{value: amount_}("");
        require(success, "transferTaxGainsTo() failed.");
    }

    /**
     * OWNER ONLY
     */
    function doUnpause() public onlyOwner {
        _unpause();
    }

    /**
     * OWNER ONLY
     */
    function doPause() public onlyOwner {
        _pause();
    }

    //
    // PRIVATE
    //

    /** @notice thrown when trying to release more than tax revenue available */
    error ReleasingTooMuchRevenue();

    /**
     *
     * @param toRelease_ can be 0, means takes whatever can be taken from tax revenue
     */
    function _releaseTaxRevenue(uint256 toRelease_) private returns (uint256) {
        //
        uint256 taxRevenue_ = taxRevenue;
        if (toRelease_ > taxRevenue_) revert("ReleasingTooMuchRevenue");

        // zero means take all available tax revenue
        if (toRelease_ == 0) {
            toRelease_ = taxRevenue_;
        }

        //
        taxRevenue -= toRelease_;

        // ack for zero-means-all
        return toRelease_;
    }

    /**
     *
     */
    function _updateValidator(address validator_) private {
        validator = validator_;
    }
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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