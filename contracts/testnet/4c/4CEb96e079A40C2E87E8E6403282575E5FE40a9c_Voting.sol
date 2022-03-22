// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./whitelist/ITokenismWhitelist.sol";
import "./token/ERC20/IERC1400RawERC20.sol";

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

    constructor(IERC1400RawERC20 _propertyToken, ITokenismWhitelist _whitelist, address _propertyOwner)
    {
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
            (whitelist.isWhitelistedUser(msg.sender) < 113 ||
                msg.sender == propertyOwner),
            "You must be the Propertys Owner or an Admin to access this function"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            whitelist.isWhitelistedUser(msg.sender) < 113,
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
    function getWhitelistAddress() public view onlyAdmin returns(address){
        return address(whitelist);
    }
    function getPropertyOwner() public view onlyAdmin returns(address){
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
        require(
            _endDate > block.timestamp + 30 minutes,
            "End date is before current time"
        );
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

    function castVote(uint256 _voteId, uint256 _option) public{
        _voteInfo storage voteInformation = voteInfo[_voteId];
        _voteCount storage votersInfo = voteCounts[_voteId][msg.sender];
        uint256 voteWeight = propertyToken.balanceOf(msg.sender);

        require(
             whitelist.isWhitelistedUser(msg.sender) < 202 &&  voteWeight > 0 ,
            "Only Investors within this property are allowed to cast votes"
        );
        require(
             voteWeight > 0 ,
            "Invester KYC is not verified"
        );
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
        votersInfo.weight = voteWeight;
        votersInfo.option = _option;
        voteInformation.votedUsers.push(msg.sender);
        voteInformation.totalVotes += voteWeight;
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

    //Do we create a function for updating both start and end date at the same time or seperate for both;
    // function updateVotingDates(
    //     uint256 _voteId,
    //     uint256 _newStartDate,
    //     uint256 _newEndDate
    // ) public onlyPropertyOwnerOrAdmin {
    //     _voteInfo storage voteInformation = voteInfo[_voteId];
    //     //add is active check here
    //     require(
    //         voteInformation.voteFinalized == false,
    //         "The vote has already been finalized"
    //     );
    //     require(
    //         (voteInformation.startDate != _newStartDate ||
    //             voteInformation.endDate != _newEndDate),
    //         "Both new start and end dates cannot be the same as the old ones"
    //     );
    //     require(
    //         block.timestamp < voteInformation.endDate,
    //         "Dates cannot be altered for Votes that have already ended"
    //     );
    //     require(
    //         block.timestamp < voteInformation.startDate,
    //         "Cannot change the start date after the vote has already started"
    //     );
    //     require(
    //         _newEndDate > block.timestamp,
    //         "New end date must be greater than current time"
    //     );
    //     require(
    //         _newStartDate > block.timestamp,
    //         "New start date must be greater than current time"
    //     );

    //     voteInformation.startDate = _newStartDate;
    //     voteInformation.endDate = _newEndDate;
    // }

    function updateStartDate(uint256 _voteId, uint256 _newStartDate)
        public
        onlyPropertyOwnerOrAdmin
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
        onlyPropertyOwnerOrAdmin
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