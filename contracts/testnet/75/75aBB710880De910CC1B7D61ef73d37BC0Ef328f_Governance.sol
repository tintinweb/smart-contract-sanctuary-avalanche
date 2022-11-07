// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./dao-voting-lib/utils/TransferHelper.sol";

import "./PowerToken.sol";

contract Governance is Ownable {

    // using Counters
    using Counters for Counters.Counter;
    
    // creating enums
    enum ProposalStatus {
        PENDING,
        ACCEPTED,
        REJECTED,
        FAILED,
        Cancelled
    }

    enum VoteAns {
        YES,
        NO
    }

    // creating structures
    struct Vote {
        address votedBy; // address of the voter
        uint256 votedAt; // unix timeStamp when voted
        VoteAns voteAns; // answer of the vote
    }

    struct Proposal {
        uint256 id; // id of the proposal
        address proposalCreatedBy; // admin who creates the proposal
        uint256 createdAt; // time at which the proposal is created
        uint256 votingEndTime; // unix timeStamp when the voting will end
        address recepient; // user
        uint256 amount; // amount of the vesting (should be with 18 decimals)
        uint256 vestingStartTime; // unix timeStamp when the vesting will start 
        uint256 vestingEndTime; // unix timeStamp when the vesting will end
        uint256 intervalForVesting; // interval after which the next reward will unlock (should be in seconds)
        ProposalStatus status; // status of the proposal
        uint256 threshold; // minimum number of the vote required to validate the voting
        uint256 numberOfVotes; // total number of the votes received
        uint256 yesCount; // total number of the `yes` count
        uint256 amountClaimed;  // total amount claimed by the user.
    }

    struct RemoveVestingProposal {
        uint256 id; // id of the proposal
        address proposalCreatedBy; // admin who creates the proposal
        uint256 createdAt; // time at which the proposal is created
        uint256 votingEndTime; // unix timeStamp when the voting will end
        address recepient; // user
        ProposalStatus status; // status of the proposal
        uint256 threshold; // minimum number of the vote required to validate the voting
        uint256 numberOfVotes; // total number of the votes received
        uint256 yesCount; // total number of the `yes` count
    }

    // creating events
    event ProposalCreated(uint256 id, address proposalCreatedBy, uint256 createdAt, uint256 votingEndTime, address recepient, uint256 amount, uint256 vestingStartTime, uint256 vestingEndTime, uint256 intervalForVesting, uint256 threshold);
    event RemoveVestingProposalCreated(uint256 id, address proposalCreatedBy, uint256 createdAt, uint256 votingEndTime, address recepient, uint256 threshold);
    event ProposalUpdated(uint256 id, uint256 votingEndTime, address recepient, uint256 amount, uint256 vestingStartTime, uint256 vestingEndTime, uint256 intervalForVesting, uint256 threshold);
    event RemoveVestingProposalUpdated(uint256 id, uint256 votingEndTime, address recepient, uint256 threshold);
    event VoteCreated(uint256 id, address votedBy, uint256 voteCreatedAt, VoteAns voteAns);
    event RemoveVestingVoteCreated(uint256 id, address votedBy, uint256 voteCreatedAt, VoteAns voteAns);

    // defining variables
    Counters.Counter public _proposalIds;
    Counters.Counter public _removeVestingProposalIds;
    PowerToken public powerToken;
    mapping(uint256 => mapping(address => bool)) public isVotedForProposalByAddress; // get if the a particular address has voted for any paricular proposal
    mapping(uint256 => mapping(address => bool)) public isVotedForRemoveVestingProposalByAddress; // get if the a particular address has voted for any paricular remove vesting proposal
    Proposal[] public proposals; // array of proposals
    RemoveVestingProposal[] public removeVestingProposals; // array of remove vesting proposals
    mapping(address => bool) public hasVotingPower; // gives if a user has the power to vote;
    mapping(uint256 => Vote[]) public votesForAllProposals; // array of votes for all proposals
    mapping(uint256 => Vote[]) public votesForAllRemoveVestngProposals; // array of votes for all remove vesting proposals
    mapping(address => uint256) public totalPower; // gives the total stake of any user
    mapping(address => uint256) public availablePower; // gives the available token to sale.
    mapping(address => uint256[]) public allVestingOfUser; //gives all the vestings of user.

    

    // modifers
    modifier isCapableToVote { // Allows to proceed if the user has the voting power
        require(hasVotingPower[msg.sender], "You don't have the right to vote!");
        _;
    }

    constructor(PowerToken _powerTokenAddress) {
        hasVotingPower[msg.sender] = true;
        powerToken = _powerTokenAddress;
        Proposal memory _proposal = Proposal({
            id: 0,
            proposalCreatedBy: address(0),
            createdAt: 0,
            votingEndTime: 0,
            recepient: address(0),
            vestingStartTime: 0,
            vestingEndTime: 0,
            intervalForVesting: 0,
            amount: 0,
            threshold: 0,
            numberOfVotes: 0,
            yesCount: 0,
            amountClaimed: 0,
            status: ProposalStatus.PENDING
        });
        proposals.push(_proposal);
        RemoveVestingProposal memory _removeVestingProposal = RemoveVestingProposal({
            id: 0,
            proposalCreatedBy: address(0),
            createdAt: 0,
            votingEndTime: 0,
            recepient: address(0),
            threshold: 0,
            numberOfVotes: 0,
            yesCount: 0,
            status: ProposalStatus.PENDING
        });
        removeVestingProposals.push(_removeVestingProposal);
    }

    // Admin can provide or withdraw voting power to any user
    function setVotingPower(address _user, bool _hasPower) onlyOwner external {
        hasVotingPower[_user] = _hasPower;
    }

    // User can create a proposal if he has the voting power
    function createProposal(uint256 _votingEndTime, address _recepient, uint256 _vestingStartTime, uint256 _vestingEndTime, uint256 _intervalForVesting, uint256 _amount, uint256 _threshold) isCapableToVote external {
        uint256 _currentTime = block.timestamp;
        _proposalIds.increment();
        Proposal memory _proposal = Proposal({
            id: _proposalIds.current(),
            proposalCreatedBy: msg.sender,
            createdAt: _currentTime,
            votingEndTime: _votingEndTime,
            recepient: _recepient,
            vestingStartTime: _vestingStartTime,
            vestingEndTime: _vestingEndTime,
            intervalForVesting: _intervalForVesting,
            amount: _amount,
            threshold: _threshold,
            numberOfVotes: 0,
            yesCount: 0,
            amountClaimed: 0,
            status: ProposalStatus.PENDING
        });
        proposals.push(_proposal);
        emit ProposalCreated(_proposalIds.current(),msg.sender, _currentTime, _proposal.votingEndTime, _proposal.recepient, _proposal.amount, _proposal.vestingStartTime, _proposal.vestingEndTime, _proposal.intervalForVesting, _proposal.threshold);
    }

    // User can create a proposal for removing vesting of a user, if he has the voting power
    function createRemoveVestingProposal(uint256 _votingEndTime, address _recepient, uint256 _threshold) isCapableToVote external {
        uint256 _currentTime = block.timestamp;
        _removeVestingProposalIds.increment();
        RemoveVestingProposal memory _removeVestingProposal = RemoveVestingProposal({
            id: _removeVestingProposalIds.current(),
            proposalCreatedBy: msg.sender,
            createdAt: _currentTime,
            votingEndTime: _votingEndTime,
            recepient: _recepient,
            threshold: _threshold,
            numberOfVotes: 0,
            yesCount: 0,
            status: ProposalStatus.PENDING
        });
        removeVestingProposals.push(_removeVestingProposal);
        emit RemoveVestingProposalCreated(_removeVestingProposalIds.current(),msg.sender, _currentTime, _removeVestingProposal.votingEndTime, _removeVestingProposal.recepient, _removeVestingProposal.threshold);
    }

    // user can provide the vote(only once) for any proposal if he has the voting power
    // _isApproved is `true` if the vote answer is "Yes" and `false` if the vote answer is "No" 
    function voteForProposal(uint256 _id, bool _isApproved) isCapableToVote external {
        require(!isVotedForProposalByAddress[_id][msg.sender], "You have already voted for this proposal");
        require(_id>0 && _id <= proposals.length, "Invalid id");
        uint256 _currentTime = block.timestamp;
        require(_currentTime >= proposals[_id].createdAt, "Voting is not yet started!");
        require(_currentTime <= proposals[_id].votingEndTime, "Voting has been ended!");
        Vote memory _vote = Vote(msg.sender, _currentTime, _isApproved ? VoteAns.YES : VoteAns.NO);
        votesForAllProposals[_id].push(_vote);
        isVotedForProposalByAddress[_id][msg.sender] = true;
        proposals[_id].numberOfVotes++;
        if(_isApproved){
            proposals[_id].yesCount++;
        }
        emit VoteCreated(_id, msg.sender, _currentTime, _isApproved ? VoteAns.YES : VoteAns.NO);
    }

    // user can provide the vote(only once) for any rmeove vesting proposal if he has the voting power
    // _isApproved is `true` if the vote answer is "Yes" and `false` if the vote answer is "No" 
    function voteForRemoveVestingProposal(uint256 _id, bool _isApproved) isCapableToVote external {
        require(!isVotedForRemoveVestingProposalByAddress[_id][msg.sender], "You have already voted for this proposal");
        require(_id>0 && _id <= removeVestingProposals.length, "Invalid id");
        uint256 _currentTime = block.timestamp;
        require(_currentTime >= removeVestingProposals[_id].createdAt, "Voting is not yet started!");
        require(_currentTime <= removeVestingProposals[_id].votingEndTime, "Voting has been ended!");
        Vote memory _vote = Vote(msg.sender, _currentTime, _isApproved ? VoteAns.YES : VoteAns.NO);
        votesForAllRemoveVestngProposals[_id].push(_vote);
        isVotedForRemoveVestingProposalByAddress[_id][msg.sender] = true;
        removeVestingProposals[_id].numberOfVotes++;
        if(_isApproved){
            removeVestingProposals[_id].yesCount++;
        }
        emit RemoveVestingVoteCreated(_id, msg.sender, _currentTime, _isApproved ? VoteAns.YES : VoteAns.NO);
    }

    // Any user with voting power can update the status of proposal if the voting time is ended, and the recepient gets approved for vesting if the votes are in his favour 
    function updateStatusOfProposal(uint256 _id) isCapableToVote external {
        uint256 _currentTime = block.timestamp;
        require(_id>0 && _id <= proposals.length, "Invalid id");
        require(_currentTime > proposals[_id].votingEndTime, "Voting is not ended yet!");
        uint256 _amountToMint = 0;
        if(proposals[_id].status == ProposalStatus.PENDING){
            if(proposals[_id].numberOfVotes != 0 && proposals[_id].threshold <= proposals[_id].numberOfVotes){
                if(proposals[_id].yesCount >= (proposals[_id].numberOfVotes - proposals[_id].yesCount)){
                    proposals[_id].status = ProposalStatus.ACCEPTED;
                    allVestingOfUser[proposals[_id].recepient].push(proposals[_id].id);
                    totalPower[proposals[_id].recepient] += proposals[_id].amount;
                    _amountToMint += proposals[_id].amount;
                }else{
                    proposals[_id].status = ProposalStatus.REJECTED;
                }
            }else{
                proposals[_id].status = ProposalStatus.FAILED;
            }
            if(_amountToMint > 0){
                powerToken.mint(address(this), _amountToMint);
            }
        }
    }

    // Any user with voting power can update the status of remove vesting proposal, if the voting time is ended, and the recepient's all vestings will be removed 
    function updateStatusOfRemoveVestingProposal(uint256 _id) isCapableToVote external {
        uint256 _currentTime = block.timestamp;
        require(_id>0 && _id <= removeVestingProposals.length, "Invalid id");
        require(_currentTime > removeVestingProposals[_id].votingEndTime, "Voting is not ended yet!");
        uint256 _amountToBurn = 0;
        if(removeVestingProposals[_id].status == ProposalStatus.PENDING){
            if(removeVestingProposals[_id].numberOfVotes != 0 && removeVestingProposals[_id].threshold <= removeVestingProposals[_id].numberOfVotes){
                if(removeVestingProposals[_id].yesCount >= (removeVestingProposals[_id].numberOfVotes - removeVestingProposals[_id].yesCount)){
                    removeVestingProposals[_id].status = ProposalStatus.ACCEPTED;
                    for(uint256 i=0;i<allVestingOfUser[removeVestingProposals[_id].recepient].length;i++){
                        proposals[allVestingOfUser[removeVestingProposals[_id].recepient][i]].status = ProposalStatus.Cancelled;
                    }
                    _amountToBurn += totalPower[removeVestingProposals[_id].recepient] - availablePower[removeVestingProposals[_id].recepient];
                    totalPower[removeVestingProposals[_id].recepient] = availablePower[removeVestingProposals[_id].recepient];
                    
                }else{
                    removeVestingProposals[_id].status = ProposalStatus.REJECTED;
                }
            }else{
                removeVestingProposals[_id].status = ProposalStatus.FAILED;
            }
            powerToken.burn(address(this), _amountToBurn);
        }
    }

    // Any user can cliam his applicable amount i.e amount which is ulocked in vesting but remaining to claim
    function claim() payable external {
        address user = msg.sender;
        uint256 _currentTime = block.timestamp;
        uint256 _reward = 0;
        for(uint256 i=0;i<allVestingOfUser[user].length;i++){
            Proposal memory _proposal = proposals[allVestingOfUser[user][i]];
            if(_proposal.amount > _proposal.amountClaimed && _currentTime >= _proposal.vestingStartTime && _proposal.status == ProposalStatus.ACCEPTED){
                if(_currentTime >= _proposal.vestingEndTime){
                    _reward += _proposal.amount - _proposal.amountClaimed;
                    _proposal.amountClaimed = _proposal.amount;
                }else{
                    uint256 _totalVestingTime = _proposal.vestingEndTime - _proposal.vestingStartTime;
                    uint256 _totalMilestones = _totalVestingTime / _proposal.intervalForVesting;
                    uint256 _rewardAtEachMilestone = _proposal.amount / _totalMilestones;
                    uint256 _currentVestingDuration = _currentTime - _proposal.vestingStartTime;
                    uint256 _currentNumberOfMilestones = _currentVestingDuration / _proposal.intervalForVesting;
                    uint256 _currentReward = _rewardAtEachMilestone * _currentNumberOfMilestones;
                    if(_currentReward + _proposal.amountClaimed > _proposal.amount){
                        _reward += _proposal.amount - _proposal.amountClaimed;
                        _proposal.amountClaimed = _proposal.amount;
                    }else{
                        _reward += _currentReward - _proposal.amountClaimed;
                        _proposal.amountClaimed = _currentReward;
                    }
                }
                proposals[allVestingOfUser[user][i]] = _proposal;
            }
        }
        availablePower[user] += _reward;
        uint256 _contractBalance = powerToken.balanceOf(address(this));
        if(_reward <= _contractBalance){
            // powerToken.transfer(user, _reward);
            TransferHelper.safeTransfer(address(powerToken), user, _reward);
        }else{
            uint256 _tokenToMint = _reward - _contractBalance;
            powerToken.mint(user, _tokenToMint);
            if(_contractBalance > 0){
                // powerToken.transfer(user, _contractBalance);
                TransferHelper.safeTransfer(address(powerToken), user, _contractBalance);
            }
        }
    }

    // Any user can get his claimable amount i.e amount which is ulocked in vesting but remaining to claim
    function getClaimableAmount(address user) public view returns(uint256 _reward){
        uint256 _currentTime = block.timestamp;
        _reward = 0;
        for(uint256 i=0;i<allVestingOfUser[user].length;i++){
            Proposal memory _proposal = proposals[allVestingOfUser[user][i]];
            if(_proposal.amount > _proposal.amountClaimed && _currentTime >= _proposal.vestingStartTime && _proposal.status == ProposalStatus.ACCEPTED){
                if(_currentTime >= _proposal.vestingEndTime){
                    _reward += _proposal.amount - _proposal.amountClaimed;
                }else{
                    uint256 _totalVestingTime = _proposal.vestingEndTime - _proposal.vestingStartTime;
                    uint256 _totalMilestones = _totalVestingTime / _proposal.intervalForVesting;
                    uint256 _rewardAtEachMilestone = _proposal.amount / _totalMilestones;
                    uint256 _currentVestingDuration = _currentTime - _proposal.vestingStartTime;
                    uint256 _currentNumberOfMilestones = _currentVestingDuration / _proposal.intervalForVesting;
                    uint256 _currentReward = _rewardAtEachMilestone * _currentNumberOfMilestones;
                    if(_currentReward + _proposal.amountClaimed > _proposal.amount){
                        _reward += _proposal.amount - _proposal.amountClaimed;
                    }else{
                        _reward += _currentReward - _proposal.amountClaimed;
                    }
                }
            }
        }
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

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with BEP20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper: BNB_TRANSFER_FAILED');
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PowerToken is ERC20, AccessControl, Ownable {

    // Create a new role identifier for the minter role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    constructor() ERC20("PowerToken", "PWT") {}

    // For minting new Tokens
    function mint(address to, uint256 amount) public {
        // Check that the calling account has the minter role
        require(hasRole(MINTER_ROLE, msg.sender), "Caller is not a minter");
        _mint(to, amount);
    }

    // For burning the Tokens
    function burn(address from, uint256 amount) public {
        require(hasRole(BURNER_ROLE, msg.sender), "Caller is not a burner");
        _burn(from, amount);
    }

    // Owner of the token can set provide minter role any of the user
    function setMinter(address _minter) public onlyOwner {
        _setupRole(MINTER_ROLE, _minter);
    }

    // Owner of the token can set provide burner role any of the user
    function setBurner(address _burner) public onlyOwner {
        _setupRole(BURNER_ROLE, _burner);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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
interface IERC165 {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

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