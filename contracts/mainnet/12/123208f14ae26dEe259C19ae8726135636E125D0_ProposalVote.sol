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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "/OpenZeppelin/[email protected]/contracts/access/Ownable.sol";
import "../interfaces/IAlchemyPower.sol";

contract ProposalVote is Ownable {
    struct Proposal {
        uint256 proposalId;
        bool multipleSelection;
        uint256 optionsCount;
        uint256[] votes;
        uint256 startTimestamp;
        uint256 finishTimestamp;
    }

    IAlchemyPower public immutable alchemyPower;

    mapping (address => mapping (uint256 => bool)) private _accountVoted;
    mapping (address => mapping (uint256 => uint256[])) private _accountVoteOptions;
    mapping (address => mapping (uint256 => uint256)) private _accountVotePower;
    Proposal[] public proposals;

    event ProposalCreated(uint256 indexed proposalId);
    event ProposalVoted(uint256 indexed proposalId, address indexed voter, uint256[] optionIds);
    event ProposalVoteRetracted(uint256 indexed proposalId, address indexed voter);

    constructor(IAlchemyPower alchemyPower_) {
        alchemyPower = alchemyPower_;
    }

    function addProposal(uint256 optionsCount, bool multipleSelection, uint256 startTimestamp, uint256 finishTimestamp) external onlyOwner {
        require(startTimestamp < finishTimestamp, "start should be earlier than finish");
        require(optionsCount >= 2, "options count should be 2 or greater");

        uint256 proposalId = proposals.length;
        proposals.push(Proposal({
            proposalId: proposalId,
            multipleSelection: multipleSelection,
            optionsCount: optionsCount,
            votes: new uint256[](optionsCount),
            startTimestamp: startTimestamp,
            finishTimestamp: finishTimestamp
        }));
        emit ProposalCreated(proposalId);
    }

    function vote(uint256 proposalId, uint256[] memory optionIds) external {
        require(proposalId < proposals.length, "invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        uint256 timestamp = block.timestamp;
        require(proposal.startTimestamp <= timestamp, "voting not started yet");
        require(proposal.finishTimestamp > timestamp, "voting finished");
        require(!_accountVoted[msg.sender][proposalId], "you already have voted for this proposal");
        require(proposal.multipleSelection && optionIds.length > 0 || !proposal.multipleSelection && optionIds.length == 1, "invalid option ids count");
        uint256 power = alchemyPower.balanceOf(msg.sender);
        require(power > 0, "zero alchemy power");

        for (uint256 i=0; i < optionIds.length; i++) {
            require(optionIds[i] < proposal.optionsCount, "invalid option id");
            for (uint256 j=0; j < optionIds.length; j++) {
                require(i == j || optionIds[i] != optionIds[j], "option ids are repeated");
            }
            proposal.votes[optionIds[i]] += power;
        }
        _accountVoted[msg.sender][proposalId] = true;
        _accountVoteOptions[msg.sender][proposalId] = optionIds;
        _accountVotePower[msg.sender][proposalId] = power;
        emit ProposalVoted(proposalId, msg.sender, optionIds);
    }

    function retractVote(uint256 proposalId) external {
        require(proposalId < proposals.length, "invalid proposal id");
        Proposal storage proposal = proposals[proposalId];
        uint256 timestamp = block.timestamp;
        require(proposal.startTimestamp <= timestamp, "voting not started yet");
        require(proposal.finishTimestamp > timestamp, "voting finished");
        require(_accountVoted[msg.sender][proposalId], "you did not vote for this proposal");

        uint256 power = _accountVotePower[msg.sender][proposalId];
        for (uint256 i=0; i < _accountVoteOptions[msg.sender][proposalId].length; i++) {
            proposal.votes[_accountVoteOptions[msg.sender][proposalId][i]] -= power;
        }
        _accountVoted[msg.sender][proposalId] = false;
        emit ProposalVoteRetracted(proposalId, msg.sender);
    }

    function getVotes(uint256 proposalId) external view returns (uint256[] memory) {
        return proposals[proposalId].votes;
    }

    function getUserVote(address account, uint256 proposalId) external view returns (uint256[] memory) {
        uint256 optionsCount = proposals[proposalId].optionsCount;
        uint256[] memory weights  = new uint256[](optionsCount);
        if (_accountVoted[account][proposalId]) {
            uint256 votePower = _accountVotePower[account][proposalId];
            for (uint256 i; i < _accountVoteOptions[account][proposalId].length; i++) {
                weights[_accountVoteOptions[account][proposalId][i]] = votePower;
            }
        }
        return weights;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "/OpenZeppelin/[email protected]/contracts/token/ERC20/IERC20.sol";

interface IAlchemyPower is IERC20 {
    function mint(address to, uint256 amount) external;
    function burn(address to, uint256 amount) external;
}