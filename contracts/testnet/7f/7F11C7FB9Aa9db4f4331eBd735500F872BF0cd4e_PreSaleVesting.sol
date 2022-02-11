// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Ownable.sol";
import "./ISaleVesting.sol";

interface DaddyInterface is IERC20 {
    function burn(uint256 amount) external;
}

/// @title Vesting contract 
/// @notice Responsible for Vesting of the daddy token for 12 months
/// @dev Vesting start time depends when exactly a sale would end, so contract takes a manual entry from owner
contract PreSaleVesting is ISaleVesting, Ownable, ReentrancyGuard {
    address public distributor; // Distributor smart contract
    uint256 public totalAllocations; // Total amount of Daddy token allocated
    DaddyInterface public daddyToken;   // Daddy Token
    bool public burnLeftOver;   // Condition to burn leftOver Daddy token
    uint256 public saleAllocatedAmount; // Total daddy token allocated for sale
    uint256 constant month = 60 days;

    mapping(address => UserVestingInfo) public userVestingInfo;
    VestingStage[] public vestingArray;

    event Withdraw(uint256 amount, uint256 timestamp);

    constructor(
        address _daddyToken,
        address _distributor,
        uint256 _saleAllocatedAmount
    ) {
        daddyToken = DaddyInterface(_daddyToken);
        distributor = _distributor;
        saleAllocatedAmount = _saleAllocatedAmount;
    }

    modifier onlyDistributor() {
        require(
            msg.sender == distributor,
            "Allocation Possible only by Distributor Contract"
        );
        _;
    }

    function initVestingBreakdown(
        uint256 _vestingStart,
        uint256[] memory _percentAllocations
    ) external onlyOwner {
        require(
            daddyToken.balanceOf(address(this)) > 0,
            "Simple Sanity Check to ensure contract's DaddyBalance"
        );
        for (uint256 index = 0; index < 12; index++) {
            VestingStage memory stage;
            stage.date = _vestingStart + month * index;
            stage.tokensUnlockedPercentage = _percentAllocations[index];
            vestingArray.push(stage); // Pending
        }
    }

    /**
     * Returns the latest price
     */
    function allocateForVesting(address _user, uint256 _tokens)
        external
        override
        onlyDistributor
        nonReentrant
    {
        require(
            _user != address(0) && _tokens != 0,
            "Cannot Allocate Invalid Details"
        );
        totalAllocations += _tokens;
        _allocateAmount(_user, _tokens);
    }

    function claimToken() external {
        UserVestingInfo storage user = userVestingInfo[msg.sender];
        require(user.allocatedAmount != 0, "User not Allocated For Vesting");
        uint256 tokensToSend = getAvailableTokensToWithdraw(user.wallet);

        require(tokensToSend != 0, "claim amount is unsufficient");

        if (tokensToSend > 0) {
            daddyToken.transfer(msg.sender, tokensToSend);
            require(
                user.claimedAmount + tokensToSend <= user.allocatedAmount,
                "Claimable Balance cannot go over Allocated amount"
            );
            user.claimedAmount += tokensToSend;
            emit Withdraw(tokensToSend, block.timestamp);
        }
    }

    /// @notice Burning LeftOver tokens if not Sold
    /// @dev Preventing burning before allocation, we can burn non allocated tokens atleast after 1st month
    function burnLeftOverDaddy() external onlyOwner {
        require(!burnLeftOver, "LeftOver Daddy Can be burnt only Once");
        require(
            block.timestamp > vestingArray[1].date,
            "LeftOver Tokens Can be burned only at the end of 1st Vesting Period"
        );
        daddyToken.burn(saleAllocatedAmount - totalAllocations);
    }

    /// @notice Emergency token drain 
    function drainToken(address _token, uint256 _amount) external onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }

    function getAvailableTokensToWithdraw(address _user)
        public
        view
        returns (uint256 tokensToSend)
    {
        UserVestingInfo storage user = userVestingInfo[_user];
        uint256 tokensUnlockedPercentage = getTokensUnlockedPercentage();
        uint256 totalTokensAllowedToWithdraw = (user.allocatedAmount *
            tokensUnlockedPercentage) / 100;
        uint256 unsentTokensAmount = totalTokensAllowedToWithdraw -
            user.claimedAmount;

        return unsentTokensAmount;
    }

    function getTokensUnlockedPercentage() public view returns (uint256) {
        uint256 allowedPercent;
        for (uint256 index = 0; index < 12; index++) {
            if (block.timestamp >= vestingArray[index].date) {
                allowedPercent = vestingArray[index].tokensUnlockedPercentage;
            }
        }
        return allowedPercent;
    }

    /// @notice Fetches available daddy left for sale
    function daddyAvailableForSale()
        public
        view
        override
        returns (bool status, uint256 amount)
    {
        if (saleAllocatedAmount >= totalAllocations) {
            status = true;
            amount = saleAllocatedAmount - totalAllocations;
        } else {
            status = false;
            amount = 0;
        }
    }

    /// @notice Contract Daddy Balance 
    function daddyBalance() public view returns (uint256 daddyBal) {
        daddyBal = daddyToken.balanceOf(address(this));
    }

    /// @notice Contract Vesting Info 
    function vestingInfo() view public returns (VestingStage[] memory) {
        return vestingArray;
    }

    /// @notice Allocates daddy token amount to user , 
    /// @dev Since user cannot claim while the sale, his Claimed amount remains zero
    /// @param _user  user address
    /// @param _amount  amount allocated
    function _allocateAmount(address _user, uint256 _amount) private {
        UserVestingInfo storage user = userVestingInfo[_user];

        user.wallet = _user;
        user.allocatedAmount += _amount;
        user.claimedAmount = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

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
pragma solidity ^0.8.0;

interface ISaleVesting {
    struct VestingStage {
        uint256 date;
        uint256 tokensUnlockedPercentage;
    }

    struct UserVestingInfo {
        address wallet;
        uint256 allocatedAmount;
        uint256 claimedAmount;
    }

    function allocateForVesting(address _user, uint256 _tokens) external;
    function daddyAvailableForSale() external view returns(bool, uint256);
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