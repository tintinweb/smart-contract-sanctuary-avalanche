pragma solidity ^0.8.17;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./deps/IToken.sol";

contract Dao is ReentrancyGuard, Ownable {

    IToken public Token;
    address payable multiSigWallet;

    // Constant variable that holds the number of days a proposal can be voted on in seconds.
    // `weeks` is a suffix provided by solidity. It translates to the total seconds in a week.
    uint32 public minimumVotingPeriod = 1 weeks;
    //// Minimum funds for execute a Proposal
    uint256 public minimumFunds = 5 ether;
    // This variable is incremented everytime a new charity proposal is added.
    // It is needed to iterate through the charty proposals as solidity doesn't provide a way to step through mappings.
    uint256 numOfProposals;

    /// @notice Holds all the charity proposals made in the DAO.
    mapping(uint256 => ChaosProposal) private ChaosProposals;
    /// @notice Holds all the stakeholders' address and their total contributions.
    mapping(address => uint256[]) private stakeholderVotes;
    /// @notice Holds all the contributors' address and their total contributions.
    mapping(address => uint256) private contributors;
    /// Holds all the stakeholders' address and their total contributions.
    mapping(address => uint256) private stakeholders;
    /// % of reward for a proposer when proposal is executed
    uint256 public ethRewardForProposer = 10;

    /// @notice A new type definition that holds the necessary variables that makes up a charity proposal.
    struct ChaosProposal {
        uint256 id;
        uint256 livePeriod;
        uint256 votesFor;
        uint256 votesAgainst;
        string description;
        bool votingPassed;
        bool executed; /// true if proposition has been accepted 
        address payable proposer;
        address paidBy;
        uint256 minimumVotes;
    }

    
    event NewChaosProposal(address indexed proposer, uint256 proposalId);
    event ProposalExecuted(uint256 proposalId, uint256 amountToInvest);

    constructor(address tokenAddr, address _multiSigWallet){
        Token = IToken(tokenAddr);
        multiSigWallet = payable(_multiSigWallet);
    }

    modifier onlyHighestStakers() {
        require(Token.isHighestStaker(msg.sender), "Only Highest CHAOS stakers");
        _;
    }

    modifier onlyContributor() {
        require(Token.balanceOf(msg.sender) > 0, "Only CHAOS stakers");
        require(!Token.isHighestStaker(msg.sender), "Highest Stakers can't vote");
        _;
    }

    function createProposal(
        string calldata description
    )
        external
        onlyHighestStakers()
    {
        uint256 proposalId = numOfProposals++;
        ChaosProposal storage proposal = ChaosProposals[proposalId];
        proposal.id = proposalId;
        proposal.proposer = payable(msg.sender);
        proposal.description = description;
        proposal.livePeriod = block.timestamp + minimumVotingPeriod;
        proposal.minimumVotes = Token.totalSupply() / 2;

        emit NewChaosProposal(msg.sender, proposal.id);
    }

    function vote(uint256 proposalId, bool supportProposal)
        external
        onlyContributor()
    {
        ChaosProposal storage chaosProposal = ChaosProposals[proposalId];

        votable(proposalId);

        if (supportProposal) chaosProposal.votesFor += Token.balanceOf(msg.sender);
        else chaosProposal.votesAgainst++;

        stakeholderVotes[msg.sender].push(chaosProposal.id);
    }


    function votable(uint256 proposalId) private {
        ChaosProposal storage chaosProposal = ChaosProposals[proposalId];
        if (
            chaosProposal.votingPassed ||
            chaosProposal.livePeriod <= block.timestamp
        ) {
            chaosProposal.votingPassed = true;
            revert("Voting period has passed on this proposal");
        }

        uint256[] memory tempVotes = stakeholderVotes[msg.sender];
        for (uint256 votes = 0; votes < tempVotes.length; votes++) {
            if (chaosProposal.id == tempVotes[votes])
                revert("This stakeholder already voted on this proposal");
        }
    }


    function executeProposal(uint256 proposalId) external {

        ChaosProposal storage chaosProposal = ChaosProposals[proposalId];
        require(msg.sender == owner() || Token.isHighestStaker(msg.sender), "Only Highest Staker or Owner can execute Proposal");
        require(chaosProposal.livePeriod >= block.timestamp, "Proposal still in voting period");
        require(address(this).balance >= minimumFunds, "Not enough funds to execute");

        if (chaosProposal.votesFor >= chaosProposal.minimumVotes) {
            chaosProposal.executed = true;
            chaosProposal.votingPassed = true;
            uint256 etherBalance = address(this).balance;
            uint256 ethForProposer = (etherBalance * ethRewardForProposer) / 100;
            uint256 etherForInvesting = etherBalance - ethForProposer;
            chaosProposal.proposer.transfer(ethForProposer);
            multiSigWallet.transfer(etherForInvesting);

            emit ProposalExecuted(chaosProposal.id, etherForInvesting);
        }
        else {
            revert("Proposal refused by the DAO");
        }

        
    }

    function getProposals()
        public
        view
        returns (ChaosProposal[] memory props)
    {
        props = new ChaosProposal[](numOfProposals);

        for (uint256 index = 0; index < numOfProposals; index++) {
            props[index] = ChaosProposals[index];
        }
    }

    function getProposal(uint256 proposalId)
        public
        view
        returns (ChaosProposal memory)
    {
        return ChaosProposals[proposalId];
    }


    function setMinimumFunds(uint256 amount) onlyOwner external {
        require(amount>0, "Amount equal zero");
        minimumFunds = amount*10**18;
    }

    function setMinimumVotingPeriod(uint32 time) external onlyOwner{
            minimumVotingPeriod = time;
    }

    function setOrderToken(address newAddr) external onlyOwner {
        Token = IToken(newAddr);
    }

    function getWaitingProposals() public view returns (uint256[] memory) {
        uint256 y;  
        uint256[] memory waitingProposals;
        for (uint i; i<numOfProposals;i++){
            ChaosProposal storage chaosProposal = ChaosProposals[i];
            if ((chaosProposal.livePeriod > block.timestamp)
            && (chaosProposal.minimumVotes < chaosProposal.votesFor) 
            && (chaosProposal.executed == false)){
                waitingProposals[y] = chaosProposal.id;
                y++;
            }
        }
        return waitingProposals;
    }

    function getExecutedProposals() public view returns (uint256[] memory) {
        uint256 y;  
        uint256[] memory executedProposals;
        for (uint i; i<numOfProposals;i++){
            ChaosProposal storage chaosProposal = ChaosProposals[i];
            if (chaosProposal.executed == true){
                executedProposals[y] = chaosProposal.id;
                y++;
            }
        }
        return executedProposals;
    }

    function getRejectedProposals() public view returns (uint256[] memory) {
        uint256 y;  
        uint256[] memory rejectedProposals;
        for (uint i; i<numOfProposals;i++){
            ChaosProposal storage chaosProposal = ChaosProposals[i];
            if ((chaosProposal.livePeriod > block.timestamp) 
            && (chaosProposal.minimumVotes < chaosProposal.votesFor)){
                rejectedProposals[y] = chaosProposal.id;
                y++;
            }
        }
        return rejectedProposals;
    }

    function getActiveProposals() public view returns (uint256[] memory){ 
        uint256 y;  
        uint256[] memory openProposals;
        for (uint i; i<numOfProposals;i++){
            ChaosProposal storage chaosProposal = ChaosProposals[i];
            if (chaosProposal.livePeriod < block.timestamp){
                openProposals[y] = chaosProposal.id;
                y++;
            }
        }
        return openProposals;
    }

    receive() external payable {}
}

pragma solidity <=8.0.17;

interface IToken {
    function isHighestStaker(address user) external view returns (bool);
    function balanceOf(address account) external view returns (uint256);
     function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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