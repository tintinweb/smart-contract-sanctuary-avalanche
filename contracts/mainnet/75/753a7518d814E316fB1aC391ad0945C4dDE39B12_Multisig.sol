/**
 *Submitted for verification at snowtrace.io on 2022-05-10
*/

// SPDX-Licence-Identifier: MIT

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: gladiator-finance-v2/gladiator-finance-contracts/contracts/Controllable.sol



pragma solidity 0.8.9;


contract Controllable is Ownable {
    mapping (address => bool) controllers;
    
    event ControllerAdded(address);
    event ControllerRemoved(address);

    modifier onlyController() {
        require(controllers[_msgSender()] || _msgSender() ==  owner(), "Only controllers can do that");
        _;
    }

    /*** ADMIN  ***/
    /**
     * enables an address to mint / burn
     * @param controller the address to enable
     */
    function addController(address controller) external onlyOwner {
        if (!controllers[controller]) {
            controllers[controller] = true;
            emit ControllerAdded(controller);
        }
    }

    /**
     * disables an address from minting / burning
     * @param controller the address to disbale
     */
    function removeController(address controller) external onlyOwner {
        if (controllers[controller]) {
            controllers[controller] = false;
            emit ControllerRemoved(controller);
        }
    }


}
// File: gladiator-finance-v2/gladiator-finance-contracts/contracts/Multisig.sol



pragma solidity 0.8.9;



interface IMultisig {
    enum ProposalType{ COMMUNITY, TEAM, DEV }
    struct Proposal {
        address proposer;
        uint64 idx;
        uint64 creationTime;
        ProposalType proposalType;
        bool devVeto;
        bool inactive;
        bool executed;
        bool reverted;
        address[] devsFor;
        address[] teamFor;
        address[] communityFor;
        bytes4 signature;
        address target;
        uint256 value;
        string fun;
        bytes data;
        string revertReason;
    }
    event DevAdded(address a);
    event TeamAdded(address a);
    event CommunityAdded(address a);
    event DevRemoved(address a);
    event TeamRemoved(address a);
    event CommunityRemoved(address a);
    event ProposalCreated(uint256 timestamp, uint256 indexed id, ProposalType proposalType, address indexed proposer, address target, string fun, uint256 value);
    event ProposalExecuted(uint256 timestamp, uint256 indexed id);
    event ProposalCanceled(uint256 timestamp, uint256 indexed id);
    event UserApproval(uint256 timestamp, uint256 indexed id);
    event UserDismissal(uint256 timestamp, uint256 indexed id);
}

contract Multisig is IMultisig {

    mapping (uint256 => Proposal) proposals;
    uint64[] activeProposals;
    uint64[] inactiveProposals;
    uint64 proposalCount;

    mapping (address => bool) public devs;
    mapping (address => bool) public team;
    mapping (address => bool) public community;
    address[] public devList;
    address[] public teamList;
    address[] public communityList;

    uint32 public DEV_PROPOSAL_DELAY = 120 seconds;
    uint32 public TEAM_PROPOSAL_DELAY = 3 days;
    uint32 public COMMUNITY_PROPOSAL_DELAY = 7 days;

    uint32 public TYPE1_DELAY = 24 hours;
    uint32 public TYPE2_DELAY = 72 hours;
    uint32 public TYPE3_DELAY = 1 weeks;
    uint32 public TYPE4_DELAY = 4 weeks;
    uint32 public EXPIRATION_DELAY = 5 weeks;

    uint32 public DEV_KICK_GRACE_DELAY = 180 days;
    uint32 public TEAM_KICK_GRACE_DELAY = 120 days;
    uint32 public COMMUNITY_KICK_GRACE_DELAY = 7 days;

    uint256 public PROPOSAL_PRICE = 1 ether / 10;

    mapping (address => uint256) pingTimes;

    modifier onlyWithRole() {
        require(_hasAnyRole(msg.sender), "Only members can do this");
        _;
    }

    modifier onlySelf() {
        require(msg.sender == address(this), "Only self please");
        _;
    }

    constructor(address[] memory _devs, address[] memory _team, address[] memory _community) {
        for (uint256 i = 0; i < _devs.length; i++) {
            _addDev(_devs[i]);
        }
        for (uint256 i = 0; i < _team.length; i++) {
            _addTeam(_team[i]);
        }
        for (uint256 i = 0; i < _community.length; i++) {
            _addCommunity(_community[i]);
        }
    }

    function ping() external {
        _ping(msg.sender);
    }

    function addDevMemberProposal(address _a) external payable onlyWithRole {
        require(!_hasAnyRole(_a), "This address already has a role");
        _ping(msg.sender);
        _addProposal(address(this), "addDev(address)", 0, abi.encode(_a));
    }

    function addTeamMemberProposal(address _a) external payable onlyWithRole {
        require(!_hasAnyRole(_a), "This address already has a role");
        _ping(msg.sender);
        _addProposal(address(this), "addTeam(address)", 0, abi.encode(_a));
    }

    function addCommunityMemberProposal(address _a) external payable onlyWithRole {
        require(!_hasAnyRole(_a), "This address already has a role");
        _ping(msg.sender);
        _addProposal(address(this), "addCommunity(address)", 0, abi.encode(_a));
    }

    function addRemoveDevMemberProposal(address _a) external payable onlyWithRole {
        require(devs[_a], "It is not a dev");
        require(pingTimes[_a] + DEV_KICK_GRACE_DELAY < block.timestamp, "Dev is active");
        _ping(msg.sender);
        _addProposal(address(this), "removeDev(address)", 0, abi.encode(_a));
    }

    function addRemoveTeamMemberProposal(address _a) external payable onlyWithRole {
        require(team[_a], "It is not a team member");
        require(pingTimes[_a] + TEAM_KICK_GRACE_DELAY < block.timestamp, "Team member is active");
        _ping(msg.sender);
        _addProposal(address(this), "removeTeam(address)", 0, abi.encode(_a));
    }

    function addRemoveCommunityMemberProposal(address _a) external payable onlyWithRole {
        require(community[_a], "It is not a community member");
        require(pingTimes[_a] + COMMUNITY_KICK_GRACE_DELAY < block.timestamp, "Community member is active");
        _ping(msg.sender);
        _addProposal(address(this), "removeCommunity(address)", 0, abi.encode(_a));
    }

    function addWithdrawProposal(address _recipient, uint256 _value) external payable onlyWithRole {
        require(_recipient != address(this), "Don't call the multisig like that");
        _ping(msg.sender);
        _addProposal(_recipient, "", _value, bytes(""));
    }

    function addERC20TransferProposal(address _token, address _recipient, uint256 _amount) external payable onlyWithRole {
        require(_token != address(this), "Don't call the multisig like that");
        _ping(msg.sender);
        _addProposal(_token, "transfer(address,uint256)", 0, abi.encode(_recipient, _amount));
    }

    function addGenericProposal(address _target, string memory _fun, uint256 _value, bytes memory _data) external payable onlyWithRole {
        require(_target != address(this), "Don't call the multisig like that");
        for (uint256 i = 0; i < bytes(_fun).length; i++) {
            require(bytes(_fun)[i] != 0x20, "No spaces in fun please");
        }
        _ping(msg.sender);
        _addProposal(_target, _fun, _value, _data);
    }

    function approveProposal(uint256 _id) external onlyWithRole {
        Proposal memory tmp = proposals[_id];
        require(tmp.creationTime != 0, "Proposal does not exist");
        require(!tmp.inactive, "Already inactive");
        _ping(msg.sender);
        if (devs[msg.sender]) {
            require(!_isMemberOf(tmp.devsFor, msg.sender), "Already approved");
            proposals[_id].devsFor.push(msg.sender);
        } else if (team[msg.sender]) {
            require(!_isMemberOf(tmp.teamFor, msg.sender), "Already approved");
            proposals[_id].teamFor.push(msg.sender);
        } else if (community[msg.sender]) {
            require(!_isMemberOf(tmp.communityFor, msg.sender), "Already approved");
            proposals[_id].communityFor.push(msg.sender);
        }
        emit UserApproval(block.timestamp, _id);
        if (_executionAllowed(_id)) {
            _execute(_id);
        }
    }

    function dismissProposal(uint256 _id) external onlyWithRole {
        require(proposals[_id].creationTime != 0, "Proposal does not exist");
        require(!proposals[_id].inactive, "Already inactive");
        _ping(msg.sender);
        if (devs[msg.sender]) {
            proposals[_id].devsFor = _removeMemberFromList(proposals[_id].devsFor, msg.sender);
            proposals[_id].devVeto = true;
        } else if (team[msg.sender]) {
            require(_isMemberOf(proposals[_id].teamFor, msg.sender), "Did not vote for or already dismissed");
            proposals[_id].teamFor = _removeMemberFromList(proposals[_id].teamFor, msg.sender);
        } else if (community[msg.sender]) {
            require(_isMemberOf(proposals[_id].communityFor, msg.sender), "Did not vote for or already dismissed");
            proposals[_id].communityFor = _removeMemberFromList(proposals[_id].communityFor, msg.sender);
        }
        emit UserDismissal(block.timestamp, _id);
        if (_cancellationAllowed(_id)) {
            _cancel(_id);
        }
    }


    function executeProposal(uint256 _id) external onlyWithRole {
        _ping(msg.sender);
        _execute(_id);
    }

    function cancelProposal(uint256 _id) external onlyWithRole {
        _ping(msg.sender);
        _cancel(_id);
    }

    /*** SELF CALLS ***/

    function addDev(address _a) external onlySelf {
        require(!_hasAnyRole(_a), "This address already has a role");
        _addDev(_a);
    }
    function addTeam(address _a) external onlySelf {
        require(!_hasAnyRole(_a), "This address already has a role");
        _addTeam(_a);
    }
    function addCommunity(address _a) external onlySelf {
        require(!_hasAnyRole(_a), "This address already has a role");
        _addCommunity(_a);
    }

    function removeDev(address _a) external onlySelf {
        _removeDev(_a);
    }
    function removeTeam(address _a) external onlySelf {
        _removeTeam(_a);
    }
    function removeCommunity(address _a) external onlySelf {
        _removeCommunity(_a);
    }

    /*** GETTERS ***/

    function getPingTime(address _a) external view returns (uint256) {
        return pingTimes[_a];
    }

    function getDevCount() external view returns (uint256) {
        return devList.length;
    }

    function getTeamCount() external view returns (uint256) {
        return teamList.length;
    }

    function isDev(address _a) external view returns (bool) {
        return devs[_a];
    }

    function isTeam(address _a) external view returns (bool) {
        return team[_a];
    }

    function isCommunity(address _a) external view returns (bool) {
        return community[_a];
    }

    function getCommunityCount() external view returns (uint256) {
        return communityList.length;
    }

    function getProposal(uint256 _id) external view returns (Proposal memory) {
        return proposals[_id];
    }

    function getProposalCount() external view returns (uint256) {
        return proposalCount;
    }

    function getActiveProposal(uint256 _id) external view returns (uint64) {
        return activeProposals[_id];
    }
    function getActiveProposalCount() external view returns (uint256) {
        return activeProposals.length;
    }

    function getInactiveProposal(uint256 _id) external view returns (uint64) {
        return inactiveProposals[_id];
    }
    function getInactiveProposalCount() external view returns (uint256) {
        return inactiveProposals.length;
    }

    function canBeExecuted(uint256 _id) external view returns (bool) {
        return _executionAllowed(_id);
    }

    function canBeCanceled(uint256 _id) external view returns (bool) {
        return _cancellationAllowed(_id);
    }

    /*** INTERNAL ***/

    function _ping(address _a) internal {
        pingTimes[_a] = block.timestamp;
    }

    function _addDev(address _a) internal {
        require(!_hasAnyRole(_a), "This address already has a role");
        if (!devs[_a]) {
            _ping(_a);
            devs[_a] = true;
            devList.push(_a);
            emit DevAdded(_a);
        }
    }

    function _addTeam(address _a) internal {
        require(!_hasAnyRole(_a), "This address already has a role");
        if (!team[_a]) {
            _ping(_a);
            team[_a] = true;
            teamList.push(_a);
            emit TeamAdded(_a);
        }
    }

    function _addCommunity(address _a) internal {
        require(!_hasAnyRole(_a), "This address already has a role");
        if (!community[_a]) {
            _ping(_a);
            community[_a] = true;
            communityList.push(_a);
            emit CommunityAdded(_a);
        }
    }

    function _removeDev(address _a) internal {
        require(devList.length > 1, "At least 1 dev member should remain");
        require(pingTimes[_a] + COMMUNITY_KICK_GRACE_DELAY < block.timestamp, "Dev is active");
        if (devs[_a]) {
            devs[_a] = false;
            for (uint256 i = 0; i < devList.length; i++) {
                if (devList[i] == _a) {
                    devList[i] = devList[devList.length - 1];
                    devList.pop();
                    break;
                }
            }
            emit DevRemoved(_a);
        }
    }

    function _removeTeam(address _a) internal {
        require(teamList.length > 1, "At least 1 team member should remain");
        require(pingTimes[_a] + TEAM_KICK_GRACE_DELAY < block.timestamp, "Team member is active");
        if (team[_a]) {
            team[_a] = false;
            for (uint256 i = 0; i < teamList.length; i++) {
                if (teamList[i] == _a) {
                    teamList[i] = teamList[teamList.length - 1];
                    teamList.pop();
                    break;
                }
            }
            emit TeamRemoved(_a);
        }
    }

    function _removeCommunity(address _a) internal {
        require(communityList.length > 1, "At least 1 community member should remain");
        require(pingTimes[_a] + COMMUNITY_KICK_GRACE_DELAY < block.timestamp, "Community member is active");
        if (community[_a]) {
            community[_a] = false;
            for (uint256 i = 0; i < communityList.length; i++) {
                if (communityList[i] == _a) {
                    communityList[i] = communityList[communityList.length - 1];
                    communityList.pop();
                    break;
                }
            }
            emit CommunityRemoved(_a);
        }
    }

    function _addProposal(address _target, string memory _fun, uint256 _value, bytes memory _data) internal {
        require(devs[msg.sender] || team[msg.sender] || community[msg.sender], "Only members can do this");
        require(bytes(_fun).length == 0 || bytes(_fun).length >=3, "provide a valid function specification");
        proposalCount++;
        Proposal memory tmp;
        tmp.creationTime = uint64(block.timestamp);
        tmp.data = _data;
        tmp.proposalType = ProposalType.COMMUNITY;
        if (team[msg.sender]) tmp.proposalType = ProposalType.TEAM;
        if (devs[msg.sender]) tmp.proposalType = ProposalType.DEV;
        require(tmp.proposalType != ProposalType.COMMUNITY && msg.value == 0 || msg.value == PROPOSAL_PRICE, "Pay exact proposal price");
        tmp.proposer = msg.sender;
        tmp.target = _target;
        tmp.value = _value;
        tmp.fun = _fun;
        if (bytes(_fun).length != 0) {
            tmp.signature =  bytes4(keccak256(bytes(_fun)));
        }
        tmp.idx = uint64(activeProposals.length);
        proposals[proposalCount] = tmp;
        activeProposals.push(proposalCount);
        emit ProposalCreated(uint64(block.timestamp), proposalCount, tmp.proposalType, msg.sender, tmp.target, tmp.fun, tmp.value);
    }

    function _execute(uint256 _id) internal {
        require(proposals[_id].creationTime != 0, "Proposal does not exist");
        require(_executionAllowed(_id), "Execution not allowed");
        _inactivateProposal(_id);
        proposals[_id].executed = true;
        (bool success, bytes memory retData) = proposals[_id].target.call{value: proposals[_id].value}(abi.encodePacked(proposals[_id].signature, proposals[_id].data));
        proposals[_id].reverted = !success;
        if (!success && retData.length >= 68) {
            assembly {
                // Slice the sighash.
                retData := add(retData, 0x04)
            }
            proposals[_id].revertReason = abi.decode(retData, (string));
        }
        emit ProposalExecuted(uint64(block.timestamp), uint64(_id));
    }

    function _cancel(uint256 _id) internal {
        require(proposals[_id].creationTime != 0, "Proposal does not exist");
        require(_cancellationAllowed(_id), "Cancellation not allowed");
        _inactivateProposal(_id);
        emit ProposalCanceled(uint64(block.timestamp), uint64(_id));
    }

    function _inactivateProposal(uint256 _id) internal {
        require(!proposals[_id].inactive, "Already inactive");
        proposals[_id].inactive = true;
        if (proposals[_id].idx != activeProposals.length - 1) {
            proposals[activeProposals[activeProposals.length - 1]].idx = proposals[_id].idx;
            activeProposals[proposals[_id].idx] = activeProposals[activeProposals.length - 1];
        }
        proposals[_id].idx = uint64(inactiveProposals.length);
        inactiveProposals.push(uint64(_id));
        activeProposals.pop();
    }

    function _executionAllowed(uint256 _id) internal view returns (bool) {
        Proposal memory tmp = proposals[_id];
        require(tmp.creationTime > 0, "Proposal does not exist");
        require(!tmp.inactive, "Already inactive");
        if (tmp.devVeto) return false;
        uint256 startTime = tmp.creationTime;

        if (tmp.proposalType == ProposalType.COMMUNITY) {
            startTime += COMMUNITY_PROPOSAL_DELAY;
        } else if (tmp.proposalType == ProposalType.TEAM) {
            startTime += TEAM_PROPOSAL_DELAY;
        } else if (tmp.proposalType == ProposalType.DEV) {
            startTime += DEV_PROPOSAL_DELAY;
        }
        // dont run after expiration
        if (block.timestamp >= startTime + EXPIRATION_DELAY) return false;

        uint256 df = tmp.devsFor.length;

        if (block.timestamp >= tmp.creationTime + DEV_PROPOSAL_DELAY && df >= devList.length) return true;

        // dont allow before start
        if (block.timestamp < startTime) return false;
        uint256 tf = tmp.teamFor.length;
        uint256 cf = tmp.communityFor.length;
        uint256 ct = 1;
        if (communityList.length > ct + 2) ct = communityList.length - 2;
        if (ct > 3) ct = 3;
        if (block.timestamp > startTime && df >= (devList.length <= 2 ? 2 : devList.length - 1)) return true;
        if (block.timestamp > startTime + TYPE1_DELAY && df >= 1 && tf >= 1 && cf >= ct) return true;
        if (block.timestamp > startTime + TYPE2_DELAY && df >= 1 && tf >= 1 && cf >= 1) return true;
        if (block.timestamp > startTime + TYPE2_DELAY && df >= 1 && cf >= ct) return true;
        ct = 1;
        if (communityList.length > ct + 2) ct = communityList.length - 2;
        if (ct > 4) ct = 4;
        if (block.timestamp > startTime + TYPE3_DELAY && tf >= 1 && cf >= ct) return true;
        if (block.timestamp > startTime + TYPE4_DELAY && cf >= communityList.length - 1) return true;
        return false;
    }

    function _cancellationAllowed(uint256 _id) internal view returns (bool) {
        Proposal memory tmp = proposals[_id];
        require(tmp.creationTime > 0, "Proposal does not exist");
        require(!tmp.inactive, "Already inactive");
        if (tmp.devVeto) return true;
        uint256 startTime = tmp.creationTime;
        if (tmp.proposalType == ProposalType.COMMUNITY) {
            startTime += COMMUNITY_PROPOSAL_DELAY;
        } else if (tmp.proposalType == ProposalType.TEAM) {
            startTime += TEAM_PROPOSAL_DELAY;
        } else if (tmp.proposalType == ProposalType.DEV) {
            startTime += DEV_PROPOSAL_DELAY;
        }
        if (block.timestamp >= startTime + EXPIRATION_DELAY) return true;
        return false;
    }

    function _hasAnyRole(address _a) internal view returns (bool) {
        return devs[_a] || team[_a] || community[_a];
    }

    /***  HELPERS ***/

    function _isMemberOf(address[] memory _list, address _a) internal pure returns (bool) {
        for (uint256 i = 0; i < _list.length; i++) {
            if (_list[i] == _a) return true;
        }
        return false;
    }
    function _removeMemberFromList(address[] memory _list, address _a) internal pure returns (address[] memory) {
        if (!_isMemberOf(_list, _a) || _list.length == 0) return _list;
        address[] memory tmp = new address[](_list.length - 1);
        uint256 i = 0;
        uint256 j = 0;
        for (; i < _list.length; i++) {
            if (_list[i] != _a) {
                tmp[j] = _list[i];
                j++;
            }
        }
        return tmp;
    }
}