// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./ISwapper.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Swapper is ISwapper {
    using Counters for Counters.Counter;
    Counters.Counter private _dealId;

    // TODO: refacto this ugly struct
    // deal_id => pair of Offer()
    struct Deal {
        address proposer1;
        address proposer2;
        address account1;
        address account2;
        address token1;
        address token2;
        uint256 amount1;
        uint256 amount2;
        uint256 startDate;
        uint256 vesting;
        uint256 deadline;
        Status status;
    }
    mapping(uint256 => Deal) public _deals;

    mapping(address => mapping(address => uint256)) private _balances;

    function propose(
        address proposer1,
        address token1, 
        uint256 amount1,
        address proposer2, 
        address account2, 
        address token2, 
        uint256 amount2, 
        uint256 vesting,
        uint256 deadline
    ) external override returns(bool, uint256) {
       
        _transfer(msg.sender, token1, amount1);
        
        uint256 id = _dealId.current();
        _deals[id] = Deal({
            proposer1: proposer1,
            proposer2: proposer2,
            account1: msg.sender, 
            account2: account2,
            token1: token1,
            token2: token2,
            amount1: amount1,
            amount2: amount2,
            startDate: block.number,
            vesting: vesting,
            deadline: deadline,
            status: Status.Pending
        });
        _dealId.increment();

        emit DealCreated(
            proposer1, 
            msg.sender, 
            token1, 
            amount1, 
            proposer2, 
            account2, 
            token2, 
            amount2, 
            block.number, 
            vesting, 
            deadline
        );

        return (true, id);
    }

    function approve(uint256 id) external override returns (bool) {
        Deal storage deal = _deals[id];

        require(msg.sender == deal.account2, "Swapper: caller not allowed");

        _transfer(msg.sender, deal.token2, deal.amount2);
        
        deal.status = Status.Approved;

        emit DealApproved(id, msg.sender, deal.proposer1, deal.proposer2);

        return true;
    }

    function claim(uint256 id) external override returns (bool) {
        Deal storage deal = _deals[id];
        
        require(deal.startDate + deal.vesting <= block.number, "Swapper: vesting period is not over");

        IERC20(deal.token1).transfer(deal.account2, deal.amount1);
        IERC20(deal.token2).transfer(deal.account1, deal.amount2);

        deal.status = Status.Claimed;
        
        emit DealClaimed(id, msg.sender, deal.proposer1, deal.proposer2);
        
        return true;
    }

    function cancel(uint256 id) external override returns (bool) {
        Deal storage deal = _deals[id];
        require(deal.account1 == msg.sender, "Swapper: caller is not the deal proposer");
        require(deal.status == Status.Pending, "Swapper: deal is no longer pending");
        require(deal.startDate + deal.deadline >= block.number, "Swapper: acceptance period is not over");
        IERC20(deal.token1).transfer(deal.account1, deal.amount1);
        deal.status = Status.Canceled;
        
        emit DealCanceled(id, msg.sender, deal.proposer1, deal.proposer2);

        return true;
    }

    function _transfer(address account, address token, uint256 amount) private {
        uint256 allowance = IERC20(token).allowance(account, address(this));
        require(allowance >= amount, "Swapper: needs allowance");
        
        bool success = IERC20(token).transferFrom(account, address(this), amount);
        require(success, "Swapper: token transfer has failed");

        _balances[account][token] = amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

interface ISwapper {

    enum Status {
        Pending,
        Approved,
        Claimed,
        Canceled
    }

    event DealCreated(
        address proposer1,
        address executor1,
        address token1, 
        uint256 amount1, 
        address proposer2,
        address executor2, 
        address token2, 
        uint256 amount2,
        uint256 startDate,
        uint256 vesting,
        uint256 deadline
    );

    event DealApproved(uint256 dealId, address executor, address proposer1, address proposer2);

    event DealClaimed(uint256 dealId, address executor, address proposer1, address proposer2);

    event DealCanceled(uint256 dealId, address executor, address proposer1, address proposer2);

    /**
    * @dev Creates a new Deal after Transfer at address `token1` 
    * of `amount1` tokens from the caller's account to Swapper contract.
    * 
    * This requires the caller to have approved Swpper contract for `amount1` 
    * to be transfered
    *
    * Returns a boolean value indicating whether the operation succeeded
    * and the id of the Deal created.
    *
    * Emits a {DealCreated} event.
    */
    function propose(
        address proposer1,
        address token1, 
        uint256 amount1,
        address proposer2, 
        address account2, 
        address token2, 
        uint256 amount2, 
        uint256 vesting,
        uint256 deadline
    ) external returns(bool, uint256);

    /**
    * @dev Update the Deal status to `Approved` after Transfer token of
    * amount set in the Deal for second account.
    *
    * This requires the account2 to have approved Swapper contract for 
    * the amount2 in the Deal at address token2.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {DealApproved} event.
    */
    function approve(uint256 id) external returns (bool);

    /**
    * @dev Send the amount of tokens to the Deal stakeholders. 
    * This requires the vesting period set in the Deal to be over.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {DealClaimed} event.
    */
    function claim(uint256 id) external returns (bool);

    /**
    * @dev Cancel the Deal proposal after the acceptance period is over. 
    * This requires only the proposer to be the function caller and the 
    * deal to be still pending which means not yet accepted by the other 
    * stakeholder.
    *
    * Returns a boolean value indicating whether the operation succeeded.
    *
    * Emits a {DealCanceled} event.
    */
    function cancel(uint256 id) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
library Counters {
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