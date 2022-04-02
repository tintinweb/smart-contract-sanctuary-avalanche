// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./whitelist/ITokenismWhitelist.sol";
import "./token/ERC20/IERC1400RawERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract Voting {
    IERC1400RawERC20 propertyToken;
    ITokenismWhitelist whitelist;
    address propertyOwner;

    //do we keep numOfOptions of do we use options.length to get numOfOptions whenever we need it ?
    //adding isFinalized to check if vote results have been already calculated.

    //with the getter functions the check is on isActive == true then return info, but what if we want info on a suspended vote?
    struct _voteInfo {
        string voteTopic;
        uint256 startDate;
        uint256 endDate;
        string[] options;
        uint256 numOfOptions;
        uint256 defaultOption;
        bool isActive;
        bool voteFinalized;
        address[] votedUsers;
        uint256 totalVotes;
    }

    struct _voteCount {
        uint256 option;
        uint256 weight;
        bool hasVoted;
    }

    mapping(uint256 => _voteInfo) public voteInfo;

    mapping(uint256 => mapping(address => _voteCount)) public voteCounts;

    constructor(
        IERC1400RawERC20 _propertyToken,
        ITokenismWhitelist _whitelist,
        address _propertyOwner
    ) {
        propertyToken = _propertyToken;
        whitelist = _whitelist;
        require(
            whitelist.isOwner(_propertyOwner),
            "The provided address is not a property owner"
        );
        propertyOwner = _propertyOwner;
    }

    modifier onlyPropertyOwnerOrAdmin() {
        require(
            ((whitelist.isWhitelistedUser(msg.sender) < 113 || msg.sender == propertyOwner) && !Address.isContract(msg.sender)),
            "You must be the Propertys Owner or an Admin to access this function"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            whitelist.isWhitelistedUser(msg.sender) < 113 && !Address.isContract(msg.sender),
            "You must be an Admin to access this function"
        );
        _;
    }

    // modifier onlyAkru() {
    //     require(
    //         whitelist.isWhitelistedUser(msg.sender) < 202,
    //         "Please verify your KYC status before Voting"
    //     );
    //     _;
    // }
    function getWhitelistAddress() public view onlyAdmin returns (address) {
        return address(whitelist);
    }

    function getPropertyOwner() public view onlyAdmin returns (address) {
        return propertyOwner;
    }

    function createVote(
        uint256 _voteId,
        string memory _voteTopic,
        string[] memory _options,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _defaultOption
    ) public onlyPropertyOwnerOrAdmin {
        require(
            voteInfo[_voteId].isActive == false,
            "This Vote Identifcation Number has already been used"
        );
        // edit time to reflect minimum duration of vote and maximum as well.
        require(
            _startDate < _endDate,
            "Voting start date cannot be after the end date"
        );
        require(_endDate > block.timestamp, "End date is before current time");
        require(
            _startDate > block.timestamp,
            "Start date is before current time"
        );
        require(
            (_defaultOption < _options.length && _defaultOption >= 0),
            "The Default option you are choosing does not exist"
        );
        require(
            _options.length >= 2,
            "Atleast two different voting options are required to launch a vote"
        );

        _voteInfo storage voteInformation = voteInfo[_voteId];
        voteInformation.isActive = true;
        voteInformation.options = _options;
        voteInformation.startDate = _startDate;
        voteInformation.endDate = _endDate;
        voteInformation.voteTopic = _voteTopic;
        voteInformation.numOfOptions = _options.length;
        voteInformation.defaultOption = _defaultOption;
    }

    function castVote(uint256 _voteId, uint256 _option) public {
        _voteInfo storage voteInformation = voteInfo[_voteId];
        _voteCount storage votersInfo = voteCounts[_voteId][msg.sender];
        uint256 voteWeight = propertyToken.balanceOf(msg.sender);

        require(
            whitelist.isWhitelistedUser(msg.sender) < 202,
            "Only Investors within this property are allowed to cast votes"
        );
        require(!Address.isContract(msg.sender),"Contract address cannot cast vote");
        require(voteWeight > 0, "Invester should have inhold token to vote");
        require(
            voteInformation.isActive,
            "This vote has been suspended/does not exist"
        );
        require(
            voteInformation.endDate > block.timestamp,
            "This Vote has closed"
        );
        require(
            voteInformation.startDate < block.timestamp,
            "This Vote has not opened yet"
        );
        require(
            (voteInformation.numOfOptions > _option && _option >= 0),
            "You are voting for an option that does not exist"
        );
        require(
            votersInfo.hasVoted == false,
            "You have already cast your Vote"
        );

        votersInfo.hasVoted = true;
        // votersInfo.weight = voteWeight;
        votersInfo.option = _option;
        voteInformation.votedUsers.push(msg.sender);
        // voteInformation.totalVotes += voteWeight;
    }

    //option to close vote is reserved for only admin or property owner as well.
    function suspendVote(uint256 _voteId) public onlyAdmin {
        require(
            voteInfo[_voteId].isActive == true,
            "No Vote exists against this ID or the vote has been suspended"
        );
        voteInfo[_voteId].isActive = false;
    }

    function getVoteTopic(uint256 _voteId)
        public
        view
        returns (string memory _voteTopic)
    {
        require(
            voteInfo[_voteId].isActive == true,
            "No Vote exists against this ID or the vote has been suspended"
        );
        _voteTopic = voteInfo[_voteId].voteTopic;
    }

    function updateStartDate(uint256 _voteId, uint256 _newStartDate)
        public
        onlyAdmin
    {
        _voteInfo storage voteInformation = voteInfo[_voteId];
        //add is active check here
        require(
            (voteInformation.voteFinalized == false),
            "The vote has already been finalized"
        );
        require(
            (voteInformation.isActive == true),
            "No Vote exists against this ID or the vote has been suspended"
        );
        require(
            (voteInformation.startDate != _newStartDate),
            "New start date cannot be the same as the old one"
        );
        require(
            block.timestamp < voteInformation.startDate,
            "Cannot change start date for a vote that has already begun"
        );
        require(
            voteInformation.endDate > _newStartDate,
            "The new start date for the vote cannot be after the end date"
        );

        voteInformation.startDate = _newStartDate;
    }

    function updateEndDate(uint256 _voteId, uint256 _newEndDate)
        public
        onlyAdmin
    {
        _voteInfo storage voteInformation = voteInfo[_voteId];
        //add is active check here
        require(
            (voteInformation.voteFinalized == false),
            "The vote has already been finalized"
        );
        require(
            (voteInformation.isActive == true),
            "No Vote exists against this ID or the vote has been suspended"
        );
        require(
            (voteInformation.endDate != _newEndDate),
            "New end date cannot be the same as the old one"
        );
        require(
            block.timestamp < voteInformation.endDate,
            "Cannot change end date for a vote that has already ended"
        );
        voteInformation.endDate = _newEndDate;
    }

    function updateWhitelistContract(address _newWhitelistAddress)
        public
        onlyAdmin
    {
        whitelist = ITokenismWhitelist(_newWhitelistAddress);
    }

    function updatePropertyOwner(address _newPropertyOwner) public onlyAdmin {
        require(
            whitelist.isOwner(_newPropertyOwner),
            "New address has not been whitelisted as a Property Owner"
        );
        propertyOwner = _newPropertyOwner;
    }

    //do we change the property owners vote as well when the default option is changed as well
    function updateDefaultOption(uint256 _voteId, uint256 _newDefaultOption)
        public
        onlyPropertyOwnerOrAdmin
    {
        _voteInfo storage voteInformation = voteInfo[_voteId];
        require(
            voteInformation.isActive == true,
            "No Vote exists against this ID or the vote has been suspended"
        );
        require(
            voteInformation.voteFinalized != true,
            "Cannot update default option if vote is finalized"
        );
        require(
            block.timestamp < voteInformation.endDate,
            "Cannot update default option for vote that has ended"
        );

        require(
            voteInformation.defaultOption != _newDefaultOption,
            "New default option is the same as the current one"
        );
        require(
            (voteInformation.numOfOptions > _newDefaultOption &&
                _newDefaultOption >= 0),
            "Selected default option does not exist"
        );

        voteInformation.defaultOption = _newDefaultOption;

        /** ADD SECTION HERE TO UPDATE PROPERTY OWNER VOTE */
    }

    function getVoteCount(uint256 _voteId)
        public
        view
        onlyPropertyOwnerOrAdmin
        returns (uint256 _totalVotes)
    {
        require(
            voteInfo[_voteId].isActive == true,
            "No Vote exists against this ID or the vote has been suspended"
        );
        require(
            voteInfo[_voteId].voteFinalized,
            "Vote has not been finalized yet"
        );
        _totalVotes = voteInfo[_voteId].totalVotes;
    }

    function getCurrentVotersList(uint256 _voteId)
        public
        view
        onlyPropertyOwnerOrAdmin
        returns (address[] memory _votedUsers)
    {
        _voteInfo memory voteInformation = voteInfo[_voteId];
        require(
            voteInformation.isActive == true,
            "No Vote exists against this ID or the vote has been suspended"
        );

        _votedUsers = voteInformation.votedUsers;
    }

    function getVoteTally(uint256 _voteId)
        public
        view
        onlyPropertyOwnerOrAdmin
        returns (
            string memory _voteTopic,
            string[] memory _options,
            uint256[] memory
        )
    {
        _voteInfo memory voteInformation = voteInfo[_voteId];
        require(
            voteInformation.isActive == true,
            "No Vote exists against this ID or the vote has been suspended"
        );
        require(
            voteInformation.voteFinalized,
            "Vote has not been finalized yet"
        );
        //array of addresses for people that have cast their vote
        address[] memory votedUserList = voteInformation.votedUsers;
        _options = voteInformation.options;
        _voteTopic = voteInformation.voteTopic;

        uint256 i;
        uint256[] memory _totaledVoteCounts = new uint256[](_options.length);
        for (i = 0; i < votedUserList.length; i++) {
            _totaledVoteCounts[
                voteCounts[_voteId][votedUserList[i]].option
            ] += voteCounts[_voteId][votedUserList[i]].weight;
        }
        return (_voteTopic, _options, _totaledVoteCounts);
    }

    function finalizeVote(uint256 _voteId) public onlyPropertyOwnerOrAdmin {
        _voteInfo storage voteInformation = voteInfo[_voteId];
        require(
            voteInformation.isActive == true,
            "No Vote exists against this ID or the vote has been suspended"
        );
        require(
            voteInformation.endDate < block.timestamp,
            "The vote has not reached its end date and time yet"
        );

        require(
            voteInformation.voteFinalized == false,
            "Vote has already been Finalized"
        );
        voteInformation.voteFinalized = true;
        address[] memory votedUserList = voteInformation.votedUsers;
        uint256 i;
        uint256 tempTotalVotes;

        for (i = 0; i < votedUserList.length; i++) {
            uint256 userTokens = propertyToken.balanceOf(votedUserList[i]);
            if (userTokens > 0) {
                voteCounts[_voteId][votedUserList[i]].weight = userTokens;
                tempTotalVotes += userTokens;
            }
        }

        voteInformation.totalVotes = tempTotalVotes;

        if (propertyToken.totalSupply() > voteInformation.totalVotes) {
            //potential problem here is that once
            uint256 unAccountedVotes = propertyToken.totalSupply() -
                voteInformation.totalVotes;
            address propertyTokenAddress = address(propertyToken);
            _voteCount storage votersInfo = voteCounts[_voteId][
                propertyTokenAddress
            ];

            votersInfo.hasVoted = true;
            votersInfo.weight = unAccountedVotes;
            votersInfo.option = voteInformation.defaultOption;
            voteInformation.votedUsers.push(propertyTokenAddress);
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface ITokenismWhitelist {
    function addWhitelistedUser(address _wallet, bool _kycVerified, bool _accredationVerified, uint256 _accredationExpiry) external;
    function getWhitelistedUser(address _wallet) external view returns (address, bool, bool, uint256, uint256);
    function updateKycWhitelistedUser(address _wallet, bool _kycVerified) external;
    function updateAccredationWhitelistedUser(address _wallet, uint256 _accredationExpiry) external;
    function updateTaxWhitelistedUser(address _wallet, uint256 _taxWithholding) external;
    function suspendUser(address _wallet) external;

    function activeUser(address _wallet) external;

    function updateUserType(address _wallet, string calldata _userType) external;
    function isWhitelistedUser(address wallet) external view returns (uint);
    function removeWhitelistedUser(address _wallet) external;
    function isWhitelistedManager(address _wallet) external view returns (bool);

 function removeSymbols(string calldata _symbols) external returns(bool);
 function closeTokenismWhitelist() external;
 function addSymbols(string calldata _symbols)external returns(bool);

  function isAdmin(address _admin) external view returns(bool);
  function isOwner(address _owner) external view returns (bool);
  function isBank(address _bank) external view returns(bool);
  function isSuperAdmin(address _calle) external view returns(bool);
  function isSubSuperAdmin(address _calle) external view returns(bool);
  function getFeeStatus() external returns(uint8);
  function getFeePercent() external view returns(uint8);
  function getFeeAddress()external returns(address);

    function isManager(address _calle)external returns(bool);
    function userType(address _caller) external view returns(bool);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// /**
//  * @title Exchange Interface
//  * @dev Exchange logic
//  */
// interface IERC1400RawERC20  {

// /*
//  * This code has not been reviewed.
//  * Do not use or deploy this code before reviewing it personally first.
//  */

//   function name() external view returns (string memory); // 1/13
//   function symbol() external view returns (string memory); // 2/13
//   function totalSupply() external view returns (uint256); // 3/13
//   function balanceOf(address owner) external view returns (uint256); // 4/13
//   function granularity() external view returns (uint256); // 5/13

//   function controllers() external view returns (address[] memory); // 6/13
//   function authorizeOperator(address operator) external; // 7/13
//   function revokeOperator(address operator) external; // 8/13
//   function isOperator(address operator, address tokenHolder) external view returns (bool); // 9/13

//   function transferWithData(address to, uint256 value, bytes calldata data) external; // 10/13
//   function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 11/13

//   function redeem(uint256 value, bytes calldata data) external; // 12/13
//   function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 13/13
//    // Added Latter
//    function cap(uint256 propertyCap) external;
//   function basicCap() external view returns (uint256);
//   function getStoredAllData() external view returns (address[] memory, uint256[] memory);

//     // function distributeDividends(address _token, uint256 _dividends) external;
//   event TransferWithData(
//     address indexed operator,
//     address indexed from,
//     address indexed to,
//     uint256 value,
//     bytes data,
//     bytes operatorData
//   );
//   event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
//   event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);
//   event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
//   event RevokedOperator(address indexed operator, address indexed tokenHolder);

//  function issue(address to, uint256 value, bytes calldata data) external  returns (bool);
// function allowance(address owner, address spender) external view returns (uint256);
// function approve(address spender, uint256 value) external returns (bool);
// function transfer(address to, uint256 value) external  returns (bool);
// function transferFrom(address from, address to, uint256 value)external returns (bool);
// function migrate(address newContractAddress, bool definitive)external;
// function closeERC1400() external;
// function addFromExchange(address investor , uint256 balance) external returns(bool);
// function updateFromExchange(address investor , uint256 balance) external;
// function transferOwnership(address payable newOwner) external; 
// }

interface IERC1400RawERC20  { 
/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */

  function name() external view returns (string memory); // 1/13
  function symbol() external view returns (string memory); // 2/13
  function totalSupply() external view returns (uint256); // 3/13
  function balanceOf(address owner) external view returns (uint256); // 4/13
  function granularity() external view returns (uint256); // 5/13

  function controllers() external view returns (address[] memory); // 6/13
  function authorizeOperator(address operator) external; // 7/13
  function revokeOperator(address operator) external; // 8/13
  function isOperator(address operator, address tokenHolder) external view returns (bool); // 9/13

  function transferWithData(address to, uint256 value, bytes calldata data) external; // 10/13
  function transferFromWithData(address from, address to, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 11/13

  function redeem(uint256 value, bytes calldata data) external; // 12/13
  function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 13/13
   // Added Latter
   function cap(uint256 propertyCap) external;
  function basicCap() external view returns (uint256);
  function getStoredAllData() external view returns (address[] memory, uint256[] memory);

    // function distributeDividends(address _token, uint256 _dividends) external;
  event TransferWithData(
    address indexed operator,
    address indexed from,
    address indexed to,
    uint256 value,
    bytes data,
    bytes operatorData
  );
  event Issued(address indexed operator, address indexed to, uint256 value, bytes data, bytes operatorData);
  event Redeemed(address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);
  event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
  event RevokedOperator(address indexed operator, address indexed tokenHolder);

 function issue(address to, uint256 value, bytes calldata data) external  returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
function approve(address spender, uint256 value) external returns (bool);
function transfer(address to, uint256 value) external  returns (bool);
function transferFrom(address from, address to, uint256 value)external returns (bool);
function migrate(address newContractAddress, bool definitive)external;
function closeERC1400() external;
function addFromExchange(address _investor , uint256 _balance) external returns(bool);
function updateFromExchange(address investor , uint256 balance) external returns (bool);
function transferOwnership(address payable newOwner) external; 
}

// SPDX-License-Identifier: MIT
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