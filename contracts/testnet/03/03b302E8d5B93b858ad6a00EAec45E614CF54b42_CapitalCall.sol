// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IStableCoin.sol";
import "./token/ERC20/IERC1400RawERC20.sol";
import "./whitelist/ITokenismWhitelist.sol";

interface ICapitalCall {
    function initiateCapitalCall(
        IERC1400RawERC20 _stAddress,
        string calldata _proposal,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _goal,
        uint256 _rate
    ) external;

    function investorDeposite(uint256 _id, uint256 _amount) external;

    function refundInvestment(uint256 _id) external;

    function setAkUsdAddress(IStableCoin _akusd) external;

    function distribution(uint256 _id, bytes[] calldata certificate) external;

    function withdrawRaisedAmount(uint256 _id) external;

    function setWhiteListAddress(ITokenismWhitelist _whitelist) external;
    
    function isGoalReached(uint256 _id) external view returns(bool);
}

contract CapitalCall is Context, Ownable, ICapitalCall {
    using Counters for Counters.Counter;

    Counters.Counter private count;
    IStableCoin private akusd;
    ITokenismWhitelist private whitelist;

    struct CapitalCallStr {
        string proposal;
        uint256 startDate;
        uint256 endDate;
        uint256 goal;
        IERC1400RawERC20 stAddress;
        uint256 amountRaised;
        uint256 rate; // in wei
        address[] investors;
        mapping(address => uint256) addrToAmount; // invester address to amount invested
    }

    mapping(uint256 => CapitalCallStr) public idToCapitalCall;

    constructor(IStableCoin _akusd, ITokenismWhitelist _whitelist) {
        require(address(_akusd) != address(0), "akusd address cannot be zero");
        require(
            address(_whitelist) != address(0),
            "whitelisting address cannot be zero"
        );
        require(
            _whitelist.isAdmin(_msgSender()) ||
                _whitelist.isSuperAdmin(_msgSender()),
            "UnAuthorized Operation"
        );

        akusd = _akusd;
        whitelist = _whitelist;
    }

    // ----------------------------events-----------------------

    event CapitalCallInitiated(
        uint256 indexed id,
        string proposal,
        uint256 startDate,
        uint256 endDate,
        uint256 goal,
        IERC1400RawERC20 stAddress
    );
    event Deposited(uint256 indexed id, address invester, uint256 amount);
    event Claimed(uint256 indexed id, address invester, uint256 amount);
    event Distributed(uint256 indexed id, address invester, uint256 amount);
    event RaisedAmountWithdrawn(uint256 amount);

    // --------------------private view functions-------------

    function _onlyPropertyInvestor(uint256 _id) private view {
        CapitalCallStr storage cc = idToCapitalCall[_id];
        // todo: if ST is listed in exchange, handle that scenario
        require(
            cc.stAddress.balanceOf(_msgSender()) > 0,
            "you are not a property investor"
        );
    }

    function _onlyPropertyAccount(IERC1400RawERC20 _stAddress) private view {
        require(
            _stAddress.propertAccount() == _msgSender(),
            "only property account"
        );
    }

    function _preDeposit(uint256 _id, uint256 _amount) private view {
        CapitalCallStr storage cc = idToCapitalCall[_id];

        require(
            akusd.allowance(_msgSender(), address(this)) >= _amount,
            "you have not approved Capital Call Contract"
        );

        require(block.timestamp < cc.endDate, "capital call duration ended");
        require(
            cc.amountRaised + _amount <= cc.goal,
            "goal reached or enter small amount"
        );
        require(
            _amount % cc.rate == 0,
            "Property value must be divisble by Rate"
        );
    }

    function _inc(uint256 i) private pure returns (uint256) {
        unchecked {
            i = i + 1;
        }
        return i;
    }

    function _checkGoalReachedAndDuration(uint256 _id) private view {
        CapitalCallStr storage cc = idToCapitalCall[_id];

        require(
            block.timestamp > cc.endDate,
            "capital call duration not ended yet"
        );

        require(cc.amountRaised == cc.goal, "goal not reached");
    }

    function _preInitiateCapitalCall(
        IERC1400RawERC20 _stAddress,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _goal,
        uint256 _rate
    ) private view {
        require(address(_stAddress) != address(0), "ST address cannot be zero");
        require(
            _startDate > block.timestamp,
            "Start date is before current time"
        );
        require(
            _startDate < _endDate,
            "start date cannot be after the end date"
        );
        require(_goal % _rate == 0, "Goal amount must be multiple of rate");
    }

    // -----------------------modifiers--------------------

    modifier checkGoalReachedAndDuration(uint256 _id) {
        _checkGoalReachedAndDuration(_id);
        _;
    }

    modifier onlyPropertyInvestor(uint256 _id) {
        _onlyPropertyInvestor(_id);
        _;
    }


    // ---------------------external functions----------------------
    function initiateCapitalCall(
        IERC1400RawERC20 _stAddress,
        string calldata _proposal,
        uint256 _startDate,
        uint256 _endDate,
        uint256 _goal,
        uint256 _rate
    ) 
        external
        override 
    {
        _onlyPropertyAccount(_stAddress);

        _preInitiateCapitalCall(_stAddress, _startDate, _endDate, _goal, _rate);

        uint256 currentCount = count.current();
        CapitalCallStr storage cc = idToCapitalCall[currentCount];

        cc.proposal = _proposal;
        cc.startDate = _startDate;
        cc.endDate = _endDate;
        cc.goal = _goal;
        cc.stAddress = _stAddress;
        cc.amountRaised = 0;
        cc.rate = _rate;

        emit CapitalCallInitiated(
            currentCount,
            _proposal,
            _startDate,
            _endDate,
            _goal,
            _stAddress
        );

        count.increment();
    }

    function investorDeposite(uint256 _id, uint256 _amount)
        external
        override
        onlyPropertyInvestor(_id)
    {
        CapitalCallStr storage cc = idToCapitalCall[_id];

        _preDeposit(_id, _amount);

        akusd.transferFrom(_msgSender(), address(this), _amount);

        if (cc.addrToAmount[_msgSender()] == 0) {
            cc.investors.push(_msgSender());
        }

        cc.amountRaised += _amount;
        cc.addrToAmount[_msgSender()] += _amount;

        emit Deposited(_id, _msgSender(), _amount);
    }

    function isGoalReached(uint256 _id) external view override returns(bool) {
        CapitalCallStr storage cc = idToCapitalCall[_id];
        return cc.amountRaised == cc.goal;
    }

    function refundInvestment(uint256 _id) 
    external 
    override
    {
        CapitalCallStr storage cc = idToCapitalCall[_id];
        _onlyPropertyAccount(cc.stAddress);

        require(
            block.timestamp > cc.endDate,
            "capital call duration not ended yet"
        );
        require(cc.amountRaised < cc.goal, "capital call went successful");

        uint256 len = cc.investors.length;

        for (uint256 i = 0; i < len; i = _inc(i)) {
            uint256 invested = cc.addrToAmount[cc.investors[i]];
            cc.amountRaised -= invested;
            cc.addrToAmount[cc.investors[i]] = 0;
            akusd.transfer(cc.investors[i], invested);
            emit Claimed(_id, cc.investors[i], invested);
        }
    }

    function distribution(uint256 _id, bytes[] calldata certificate)
        external
        override
        checkGoalReachedAndDuration(_id)
    {
        CapitalCallStr storage cc = idToCapitalCall[_id];

        _onlyPropertyAccount(cc.stAddress);

        uint256 len = cc.investors.length;

        for (uint256 i = 0; i < len; i = _inc(i)) {
            uint256 invested = cc.addrToAmount[cc.investors[i]];
            uint256 token = invested / cc.rate;
            cc.stAddress.issue(
                cc.investors[i],
                token,
                certificate[i]
            );
            emit Distributed(_id, cc.investors[i], token);
        }
    }

    function withdrawRaisedAmount(uint256 _id)
        external
        override
        checkGoalReachedAndDuration(_id)
    {
        CapitalCallStr storage cc = idToCapitalCall[_id];

        _onlyPropertyAccount(cc.stAddress);

        akusd.transfer(
            _msgSender(),
            cc.amountRaised
        );
        

        emit RaisedAmountWithdrawn(cc.amountRaised);
    }

    function setWhiteListAddress(ITokenismWhitelist _whitelist)
        external
        override
        onlyOwner
    {
        whitelist = _whitelist;
    }

    function setAkUsdAddress(IStableCoin _akusd) 
    external 
    override 
    onlyOwner 
    {
        akusd = _akusd;
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
  function isPropertyAccount(address _owner) external view returns (bool);
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
function propertOwner() external view returns (address);
function propertAccount() external view returns (address);
function propertyOwnerReserveDevTokenPercentage() external view returns (uint256);
function devToken() external view returns (uint256) ;
function setDevTokens() external ;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IStableCoin{
    function transferWithData(address _account,uint256 _amount, bytes calldata _data ) external returns (bool success) ;
    function transfer(address _account, uint256 _amount) external returns (bool success);
    function burn(uint256 _amount) external;
    function burnFrom(address _account, uint256 _amount) external;
    function mint(address _account, uint256 _amount) external returns (bool);
    function transferOwnership(address payable _newOwner) external returns (bool);
    
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);


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