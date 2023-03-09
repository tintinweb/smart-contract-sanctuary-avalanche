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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;
/**
 * @title StableCoin Interface
 * @dev StableCoin logic
 */
interface IStableCoin{
     /**
     * @dev Transfer the specified _amount of tokens to the specified address.
     *      Invokes the `tokenFallback` function if the recipient is a contract.
     *      The token transfer fails if the recipient is a contract
     *      but does not implement the `tokenFallback` function
     *      or the fallback function to receive funds.
     *
     * @param _account   Receiver address.
     * @param _amount    Amount of tokens that will be transferred.
     * @param _data      Transaction metadata.
     */
    function transferWithData(address _account,uint256 _amount, bytes calldata _data ) external returns (bool success) ;
    /**
     * @dev Transfer the specified amount of tokens to the specified address.
     *      This function works the same with the previous one
     *      but doesn't contain `_data` param.
     *      Added due to backwards compatibility reasons.
     *
     * @param _account    Receiver address.
     * @param _amount     Amount of tokens that will be transferred.
     */
    function transfer(address _account, uint256 _amount) external returns (bool success);
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 _amount) external;
    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address _account, uint256 _amount) external;
    /**
     * @dev mint the specified amount of tokens mint to the specified address.
     * @param _account    Receiver address.
     * @param _amount     Amount of tokens that will be transferred.
     */
    function mint(address _account, uint256 _amount) external returns (bool);
    /**
     * @dev check balance
     * @param who new Address of property owners
     * @return balance of owner
     */
    function balanceOf(address who) external view returns (uint256);
     /**
     * @dev allowance
     * @param owner  Address of property owners
     * @param spender  Address of spender 
     * @return balance of allowance
     */
    function allowance(address owner, address spender) external view returns (uint256);
     /**
     * @dev transferFrom
     * @param from  Address of property owners
     * @param to  Address of spender 
     * @param value token's value
     * @return success
     */
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    // function allowance(
    //     address owner,
    //     address spender
    // ) external view returns (uint256);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMarginLoan {
    /**
     * LoanStatus : it will have only follwoing three values.
     */
    enum LoanStatus {NOTFOUND, PENDING, ACTIVE, COMPLETE, REJECT, CANCEL, PLEDGE}
    /**
     * MarginLoan: This struct will Provide the required field of Loan record
     */
    struct MarginLoan {
        address user;
        address bank;
        uint256 loanAmount;
        uint256 interestRate;
        LoanStatus status;
        address tokenAddress;
        uint256 createdAt;
        uint256 installmentAmount;
        uint256 loanLimit;      //maximum loan limit a user can avail against tokens
        uint256 loanPercentage;
        uint256 noOfTokens;
    }

    /**
     * LoanRequest: This event will triggered when ever their is request for loan
     */
    event LoanRequest(
        address user,
        address bank,
        uint256 loanAmount,
        uint256 interestRate,
        LoanStatus status,
        address tokenAddress,
        uint256 createdAt,
        uint256 installmentAmount,
        uint256 id,
        uint256 loanPercentage,
        uint256 noOfTokens
    );
    event UpdateLoan(address user, uint256 id, LoanStatus status);
    event PledgeToken(address user, address _token,uint256 noOfToekns,  LoanStatus status);

    /**
     * called when user request loan from bank
     *
     */
    function requestLoan(
        address _bank,
        uint256 _loanAmount,
        uint256 _interestRate,
        address _tokenAddress,
        uint256 createdAt,
        uint256 installmentAmount,
        uint256 _loanPercentage,
        uint256 noOfTokens
    ) external;

    /**
     * this function would return user margin with erc1400 address
     */
    function getLoan(address _user, address tokenAddress)
        external
        view
        returns (uint256,uint256);
    function getPledgedLoan(address _user, address tokenAddress, address _bank)
        external
        view
        returns (uint256,uint256, uint256,  uint256);

    /**
     * only user with a rule of bank can approve loan
     */
     function completeLoan(address _user, uint256 _id)
        external
        returns (bool);
     function pledgeLoanToken(address _user,address _tokenAddress, address _bank)
        external
        returns (bool);

    /**
     *getLoanStatus: thsi function return loan status of address provided
     */
    function getLoanStatus(
        address _user,
        uint256 _id
    ) external view returns (uint256);

    /**
     * only user with a rule of bank can reject loan
     */
    function cancelLoan(uint256 _id) external returns (bool);

    /**
     * get t0tal of margin loan array of address
     */
    function getTotalLoans(address _user) external view returns (uint256);

    /**
     * get total number of  loan on a signle erc1400 token
     */

    function getTotalLoanOfToken(
        address _user,
        address _token
    )
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );
    
    function getTotalLoanOfPledgedToken(address _user, address _token, address _bank)
        external 
        view
          returns (
            address[] memory banks,
            uint256[] memory loanAmounts,
            uint256[] memory interestRates
          
        );

   function getTotalNoOfTokens(address _user, address _token)
        external
        view
        returns (uint256[] memory,uint256[] memory);

  function getTotalNoOfPledgeTokens(address _user, address _token, address _bank)
        external
        view
        returns (uint256[] memory ids, uint256[] memory loans, uint256[] memory interest);
        
    function updateLoan(
        address user,
        uint256 id,
        uint256 AmountPayed,
        uint256 caller
    ) external;

    function updatePledgeLoan(
        address user,
        uint256 id,
        uint256 AmountPayed,
        uint256 tokensSold,
        uint256 caller
    ) external;
   function getLoanLimit(address _user, address _tokenAddress, uint256 _loanPercentage) view external returns (uint256) ;
   function getRemainingLoanLimit( address _user,address _tokenAddress, uint256 _loanPercentage) view external returns ( uint256);

    function addBlockedUser(address _user) external ;
    
    function removeBlockedUser(address _user) external;

    function isBlockedUser(address _user) external view  returns(bool);

    function payPledgeLoan(address _user,address _tokenAddress, address _bank)
        external
        returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

interface ERC1820Registry {
    function setInterfaceImplementer(
        address _addr,
        bytes32 _interfaceHash,
        address _implementer
    ) external;

    function getInterfaceImplementer(
        address _addr,
        bytes32 _interfaceHash
    ) external view returns (address);

    function setManager(address _addr, address _newManager) external;

    function getManager(address _addr) external view returns (address);
}

/// Base client to interact with the registry.
contract ERC1820Client {
    ERC1820Registry constant ERC1820REGISTRY =
        ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(
        string memory _interfaceLabel,
        address _implementation
    ) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(
            address(this),
            interfaceHash,
            _implementation
        );
    }

    function interfaceAddr(
        address addr,
        string memory _interfaceLabel
    ) internal view returns (address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/**
 * @title ERC1400RawERC20
 * @dev ERC1400Raw with ERC20 retrocompatibility
 *  @author AKRU's Dev team
 */
interface IERC1400RawERC20  { 
  /**
     * ST0: Only admin is allowed
     * ST1: StableCoin: Cannot send tokens outside Tokenism
     * ST2: Only SuperAdmin is allowed
     * ST3: Invalid shares array provided
     * ST4: Transfer Blocked - Sender balance insufficient
     * ST5: Transfer Blocked - Sender not eligible
     * ST6: Transfer Blocked - Receiver not eligible
     * ST7: Transfer Blocked - Identity restriction
     * ST8: Percentages sum should be 100
     * ST9: Only deployed by admin Or manager of Tokenism
     * ST10: Token Already exist with this Name
     * ST11: Token granularity can not be lower than 1
     * ST12: Security Token: Cannot send tokens outside AKRU
     * ST13: Upgrade Yourself to Premium Account for more Buy
     * ST14: Whitelisting Failed
     * ST15: There is no space to new Investor
     * ST16: Only STO deployer set Cap ERC11400 Value and Once a time
     * ST17: Cap must be greater than 0
     * ST18: Only Owner or Admin is allowed to send
     * ST19: There is no any Investor to distribute dividends
     * ST20: You did not have this much AKUSD
     * ST21: Not a contract address
  
  */
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
  /**
     * [ERC1400Raw INTERFACE (1/13)]
     * @dev Get the name of the token, e.g., "MyToken".
     * @return Name of the token.
     */
  function name() external view returns (string memory); // 1/13
  /**
     * [ERC1400Raw INTERFACE (2/13)]
     * @dev Get the symbol of the token, e.g., "MYT".
     * @return Symbol of the token.
     */
  function symbol() external view returns (string memory); // 2/13
 /**
     * [ERC1400Raw INTERFACE (3/13)]
     * @dev Get the total number of issued tokens.
     * @return Total supply of tokens currently in circulation.
     */
  function totalSupply() external view returns (uint256); // 3/13
   /**
     * [ERC1400Raw INTERFACE (4/13)]
     * @dev Get the balance of the account with address 'tokenHolder'.
     * @param tokenHolder Address for which the balance is returned.
     * @return Amount of token held by 'tokenHolder' in the token contract.
     */
  function balanceOf(address tokenHolder) external view returns (uint256); // 4/13
  /**
     * [ERC1400Raw INTERFACE (5/13)]
     * @dev Get the smallest part of the token that’s not divisible.
     * @return The smallest non-divisible part of the token.
     */
  function granularity() external view returns (uint256); // 5/13
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 value) external returns (bool);
  function transfer(address to, uint256 value) external  returns (bool);
  function transferFrom(address from, address to, uint256 value)external returns (bool);
  /**
     * [ERC1400Raw INTERFACE (6/13)]
     * @dev Get the list of controllers as defined by the token contract.
     * @return List of addresses of all the controllers.
     */
  function controllers() external view returns (address[] memory); // 6/13
  function transferOwnership(address payable newOwner) external; 
   /**
     * [ERC1400Raw INTERFACE (7/13)]
     * @dev Set a third party operator address as an operator of 'msg.sender' to transfer
     * and redeem tokens on its behalf.
     * @param operator Address to set as an operator for 'msg.sender'.
     */
  function authorizeOperator(address operator) external; // 7/13
   /**
     * [ERC1400Raw INTERFACE (8/13)]
     * @dev Remove the right of the operator address to be an operator for 'msg.sender'
     * and to transfer and redeem tokens on its behalf.
     * @param operator Address to rescind as an operator for 'msg.sender'.
     */
  function revokeOperator(address operator) external; // 8/13
  /**
     * [ERC1400Raw INTERFACE (9/13)]
     * @dev Indicate whether the operator address is an operator of the tokenHolder address.
     * @param operator Address which may be an operator of tokenHolder.
     * @param tokenHolder Address of a token holder which may have the operator address as an operator.
     * @return 'true' if operator is an operator of 'tokenHolder' and 'false' otherwise.
     */
  function isOperator(address operator, address tokenHolder) external view returns (bool); // 9/13
  /**
     * [ERC1400Raw INTERFACE (10/13)]
     * @dev Transfer the amount of tokens from the address 'msg.sender' to the address 'to'.
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer, by the token holder.
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
  function transferWithData(address to, uint256 value, bytes calldata data) external; // 10/13
   /**
     * [ERC1400Raw INTERFACE (11/13)]
     * @dev Transfer the amount of tokens on behalf of the address 'from' to the address 'to'.
     * @param from Token holder (or 'address(0)' to set from to 'msg.sender').
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer, and intended for the token holder ('from').
     * @param operatorData Information attached to the transfer by the operator. 
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
  function transferFromWithData(address from, 
                                address to, 
                                uint256 value, 
                                bytes calldata data, 
                                bytes calldata operatorData) external; // 11/13
   /**
     * [ERC1400Raw INTERFACE (12/13)]
     * @dev Redeem the amount of tokens from the address 'msg.sender'.
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption, by the token holder. 
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
  function redeem(uint256 value, bytes calldata data) external; // 12/13
  /**
     * [ERC1400Raw INTERFACE (13/13)]
     * @dev Redeem the amount of tokens on behalf of the address from.
     * @param from Token holder whose tokens will be redeemed (or address(0) to set from to msg.sender).
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption.
     * @param operatorData Information attached to the redemption, by the operator. 
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
  function redeemFrom(address from, uint256 value, bytes calldata data, bytes calldata operatorData) external; // 13/13
   /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev set property cap 
     * @param propertyCap new property Cap.
     */
  function cap(uint256 propertyCap) external;
  /**
     * @dev get basic cap
     * @return calculated cap
     */
  function basicCap() external view returns (uint256);
  /**
     * @dev get all Users with there balance
     * @return  all Users with there balance
     */
  function getStoredAllData(address adminAddress) external view returns (address[] memory, uint256[] memory);

    // function distributeDividends(address _token, uint256 _dividends) external;
 /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Issue the amout of tokens for the recipient 'to'.
     * @param to Token recipient.
     * @param value Number of tokens issued.
     * @param data Information attached to the issuance, by the token holder. 
     * [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     * @return A boolean that indicates if the operation was successful.
     */
function issue(address to, uint256 value, bytes calldata data) external  returns (bool);
/**
     * [NOT MANDATORY FOR ERC1400RawERC20 STANDARD][OVERRIDES ERC1400 METHOD]
     * @dev Migrate contract.
     *
     * ===> CAUTION: DEFINITIVE ACTION
     *
     * This function shall be called once a new version of the smart contract has been created.
     * Once this function is called:
     *  - The address of the new smart contract is set in ERC1820 registry
     *  - If the choice is definitive, the current smart contract is turned off and can never be used again
     *
     * @param newContractAddress Address of the new version of the smart contract.
     * @param definitive If set to 'true' the contract is turned off definitely.
     */
function migrate(address newContractAddress, bool definitive)external;
/**
  * @dev close the ERC1400 smart contract
  */
function closeERC1400() external;
/**
     * [NOT MANDATORY FOR ERC1400RawERC20 STANDARD]USED FOR DISTRIBUTION MODULE]
     *
     * ===> CAUTION: DEFINITIVE ACTION
     *
     * Once this function is called:
     *
     * @param _investor Address of the Investor.
     * @param _balance Balance of token listed on exchange.
     */
function addFromExchange(address _investor , uint256 _balance) external returns(bool);
/**
     * [NOT MANDATORY FOR ERC1400RawERC20 STANDARD]USED FOR DISTRIBUTION MODULE]
     *
     * ===> CAUTION: DEFINITIVE ACTION
     *
     * Once this function is called:
     *
     * @param _investor Address of the Investor.
     * @param _balance Balance of token listed on exchange.
     */
function updateFromExchange(address _investor , uint256 _balance) external returns (bool);
  /**
         * @dev get all property owner of the property
         * @return _propertyOwners
    */
function propertyOwners() external view returns (address[] memory);
 /**
     * @dev get all property owner shares of the property
     * @return _shares
     */
function shares() external view returns (uint256[] memory);
/**
     * @dev check if property owner exist in the property
     * @param _addr address of the user
     */
function isPropertyOwnerExist(address _addr) external view returns(bool isOwnerExist);
 /**
     * @dev toggleCertificateController activate/deactivate Certificate Controller
     * @param _isActive true/false
     */
function toggleCertificateController(bool _isActive) external;
/**
     * @dev bulk mint of tokens to property owners exist in the property
     * @param to array of addresses of the owners
     * @param amount array of amount to be minted
     * @param cert array of certificate
     */
function bulkMint(address[] calldata to,uint256[] calldata amount,bytes calldata cert) external;
   /**
     * @dev  add share percentages to property owners exist in the property
     * @param _shares array of shares of the owners
     * @param _owners array of addresses of the owners
     */
function addPropertyOwnersShares(uint256[] calldata _shares,address[] calldata _owners) external;
 /**
     * @dev to add token for distribution from exchange  
     * @param _investor address of user
     * @param _balance balance of user
     * @return  function call
     */
    function addFromExchangeRaw1400(address _investor , uint256 _balance) external returns (bool);
    /**
     * @dev to update token for distribution from exchange  
     * @param _investor address of user
     * @param _balance balance of user
     * @return  function call
     */
    function updateFromExchangeRaw1400(address _investor , uint256 _balance) external returns (bool);
    /**
     * @dev get whitelisted ERC1400 Address 
     * @return  address of whitlisting
     */
    function getERC1400WhitelistAddress() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "../token/ERC20/IERC1400RawERC20.sol";
import "../whitelist/ITokenismWhitelist.sol";
import "../MarginLoan/IMarginLoan.sol";
import "../IStableCoin.sol";

interface IUniversalExchange {
    /**
     *  E1: Only admin
     *  E2: Only admin or whitelisted user
     *  E3: Only admin or seller
     *  E4: Only admin or buyer
     *  E5: Only admin or seller or buyer
     *  E6: Invalid Security Token address
     *  E7: Price is zero
     *  E8: Quantity is zero
     *  E9: Insufficient Security Token balance
     *  E10: Approve Security Tokens
     *  E11: Invalid id
     *  E12: Seller cannot buy there tokens
     *  E13: Buy Quantity must be greater than zero
     *  E14: Buy Quantity must be greater than Remaining Quantity
     *  E15: Insufficient AKUSD balance
     *  E16: Insufficient AKUSD allowance
     *  E17: Seller cannot place Offer
     *  E18: Price set by Buyer must be less than seller price
     *  E19: Buyer already offered
     *  E20: Wait for buyer counter
     *  E21: No offers found
     *  E22: Offer expired
     *  E23: Price must be greater than buyer offer price
     *  E24: Price must be smaller than listing price
     *  E25: Price must be lesser than previous offer price
     *  E26: Seller counter exceeded
     *  E27: Remaing Quantity is must be greater or equal to offering quantity
     *  E28: Wait for seller counter
     *  E29: Price must be smaller than seller offer price
     *  E30: Price must be greater than previous offer price
     *  E31: Buyer counter exceeded
     *  E32: Zero Address
     *  E33: Incorrect Nonce
     *  E34: Buyer cannot reject his counter
     *  E35: Seller cannot reject his counter
     *  E36: Unauthorized
     *  E37: Buyer can't accept their own offer
     *  E38: Seller can't accept their own offer
     *  E39: Offer not Expire yet
     */

    enum Status {
        Default, // default value
        Listed, //for listings
        UnListed, //for listings
        Sold, // for offers and listings
        Created, // for offers
        Countered, // for offers
        Canceled, // for offers
        Rejected, //for offers
        Null, // for offers
        Expired
    }

    struct Offers {
        uint128 buyerPrice;
        uint128 sellerPrice;
        uint256 expiryTime;
        uint128 quantity;
        address buyer;
        uint8 buyerCount;
        uint8 sellerCount;
        bool isOffered;
        bool isCallable;
        Status status;
    }

    struct ListTokens {
        uint128 price;
        uint128 quantity;
        uint128 remainingQty;
        uint128 tokenInHold;
        address seller;
        IERC1400RawERC20 token;
        Status status;
    }

    event TokensListed(
        uint256 indexed id,
        uint128 price,
        uint128 quantity,
        address indexed seller,
        IERC1400RawERC20 indexed token
    );

    event TokensPurchased(
        uint256 indexed id,
        uint128 quantity,
        uint128 price,
        address indexed seller,
        address indexed buyer,
        IERC1400RawERC20 token
    );

    event OfferPlaced(
        uint256 indexed id,
        uint128 quantity,
        uint128 price,
        address indexed seller,
        address indexed buyer,
        IERC1400RawERC20 token
    );

    event Counter(
        uint256 indexed id,
        uint128 quantity,
        uint128 price,
        address indexed seller,
        address indexed buyer, 
        IERC1400RawERC20 token
        
    );

    event ListingCanceled(
        uint256 indexed id,
        uint128 price,
        uint128 quantity,
        address indexed seller,
        IERC1400RawERC20 indexed token

    );

    event RejectCounter(
        uint256 indexed id,
        uint128 quantity,
        uint128 price,
        address indexed seller, 
        address indexed buyer, 
        IERC1400RawERC20 token
    );

    event BuyerOfferCanceled(
        uint256 indexed id,
        uint128 quantity,
        uint128 price,
        IERC1400RawERC20 token,
        address seller,
        address buyer

    );

    event SellerOfferCanceled(
        uint256 indexed  id,
        uint128 quantity,
        uint128 price,
        IERC1400RawERC20 token,
        address seller,
        address buyer

    );

    event LoanPayed(
        uint256 totalAmount,
        IERC1400RawERC20 token,
        address seller,
        address bankAddress

    );

    event OfferExpire(
        uint256 id,
        address buyer,
        uint256 totalAmount
    );

    function sellTokens(
        uint128 price,
        uint128 quantity,
        address seller,
        IERC1400RawERC20 token
    ) external;

    function buyTokens(uint256 id, uint128 quantity, address buyer) external;

    function buyerOffer(
        uint256 id,
        uint128 quantity,
        uint128 price,
        address buyer
    ) external;

    function setFeeAddress(address newFeeAddress) external;

    function setFeePercentage(uint128 newFeePercentage) external;

    function counterSeller(uint256 id, uint128 price, address buyer) external;

    function counterBuyer(uint256 id, uint128 price, address seller) external;

    function cancelListing(uint256 id) external;

    function rejectCounter(
        uint256 id,
        address buyer,
        bytes calldata signature,
        uint256 nonce
    ) external;

    function getListings(
        uint256 id
    )
        external
        view
        returns (
            uint128 price,
            uint128 quantity,
            uint128 remainingQty,
            uint128 tokenInHold,
            IERC1400RawERC20 token,
            address seller,
            Status status   
        );
         function getOffer(address buyerWallet,uint256 id) 
        external
        view
        returns (
            uint128 buyerPrice,
            uint128 sellerPrice,
            uint256 expiryTime,
            uint128 quantity,
            address buyer,
            uint8 buyerCount,
            uint8 sellerCount,
            bool isOffered,
            bool isCallable,
            Status status
        );

    function acceptCounter(
        uint256 id,
        address buyer,
        bytes calldata signature,
        uint256 nonce
    ) external;

    function cancelBuyer(uint256 id, address buyer) external;

    function cancelSeller(uint256 id, address buyer) external;

    function updateWhiteListing(ITokenismWhitelist newWhitelist) external;

    function updateStableCoin(IStableCoin newStableCoin) external;

    function updateMarginLoan(IMarginLoan newMarginLoan) external;

    function updateInterfaceHash(string calldata interfaceHash) external;

    function toggleMarginLoan() external;

    function toggleFee() external;
    
    function setExpiryDuration(uint256 newExpiryDuration) external;
    
    function expireOffer(uint256 id, address _wallet) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./IUniversalExchange.sol";
import "../token/ERC1820/ERC1820Client.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// import "hardhat/console.sol";
/**
 * @title Universal Exchange
 * @author Umer Mubeen & Asadullah Khan
 * @notice Singleton Exchange Instance
 * @dev AKRU Exchange Smart Contract for Secondary Market
 */
contract UniversalExchange is
    IUniversalExchange,
    Ownable,
    ERC1820Client,
    ReentrancyGuard
{
    using Counters for Counters.Counter;

    Counters.Counter private count;
    IStableCoin public stableCoin;
    ITokenismWhitelist public whitelist;
    IMarginLoan public marginLoan;
    address public feeAddress;
    uint256 public feePercentage; // in wei
    string public erc1400InterfaceId = "ERC20Token";
    bool public marginLoanStatus = false;
    bool public feeStatus = false;
    uint256 public expiryDuration = 10 minutes; // for production set 2 days

    ///@dev listing id to listing detail
    mapping(uint256 => ListTokens) private listedTokens;

    ///@dev offeror address to listing id to offer detail
    mapping(address => mapping(uint256 => Offers)) private listingOffers;

    ///@dev listing id to array of offeror address
    mapping(uint256 => address[]) public counterAddresses;

    ///@dev address to replay nonce
    mapping(address => uint256) public replayNonce;

    constructor(
        IStableCoin stableCoinAddress,
        ITokenismWhitelist whitelistingAddress,
        IMarginLoan marginLoanAddress
    ) {
        stableCoin = stableCoinAddress;
        whitelist = whitelistingAddress;
        marginLoan = marginLoanAddress;
    }

    function _onlyAdmin() private view {
        require(whitelist.isAdmin(_msgSender()), "E1");
    }

    function _onlyAdminAndUser() private view {
        require(
            whitelist.isAdmin(_msgSender()) ||
                whitelist.isWhitelistedUser(_msgSender()) <= 200,
            "E2"
        );
    }

    function _onlyAdminAndSeller(uint256 id) private view {
        ListTokens memory listing = listedTokens[id];

        require(
            whitelist.isAdmin(_msgSender()) || listing.seller == _msgSender(),
            "E3"
        );
    }

    function _onlyAdminAndBuyer(uint256 id) private view {
        Offers memory listingOffer = listingOffers[_msgSender()][id];

        require(
            whitelist.isAdmin(_msgSender()) ||
                listingOffer.buyer == _msgSender(),
            "E4"
        );
    }

    function _onlyAdminAndSellerAndBuyer(uint256 id) private view {
        ListTokens memory listing = listedTokens[id];

        Offers memory listingOffer = listingOffers[_msgSender()][id];

        require(
            whitelist.isAdmin(_msgSender()) ||
                listing.seller == _msgSender() ||
                listingOffer.buyer == _msgSender(),
            "E5"
        );
    }

    modifier onlyAdmin() {
        _onlyAdmin();
        _;
    }

    modifier onlyAdminAndUser() {
        _onlyAdminAndUser();
        _;
    }
    modifier onlyAdminAndSeller(uint256 id) {
        _onlyAdminAndSeller(id);
        _;
    }
    modifier onlyAdminAndBuyer(uint256 id) {
        _onlyAdminAndBuyer(id);
        _;
    }

    modifier onlyAdminAndSellerAndBuyer(uint256 id) {
        _onlyAdminAndSellerAndBuyer(id);
        _;
    }

    /**
     * @dev List Token of any Property on Exchange for Sell
     * @param price: Price of Token that want on sell
     * @param quantity: Quantity of token that want to sell
     * @param seller: address of token that want to sell token
     * @param token: Address of ERC1400/Security token
     */

    function sellTokens(
        uint128 price,
        uint128 quantity,
        address seller,
        IERC1400RawERC20 token
    ) external override onlyAdminAndUser {
        require(
            interfaceAddr(address(token), erc1400InterfaceId) != address(0),
            "E6"
        );
        require(price > 0, "E7");
        require(quantity > 0, "E8");
        require(quantity <= token.balanceOf(seller), "E9");
        require(quantity <= token.allowance(seller, address(this)), "E10");
        uint256 currentCount = count.current();
        listedTokens[currentCount] = ListTokens({
            seller: seller,
            token: token,
            price: price,
            quantity: quantity,
            remainingQty: quantity,
            tokenInHold: 0,
            status: Status.Listed
        });
        count.increment();

        token.addFromExchange(seller, quantity);
        token.transferFrom(seller, address(this), quantity);

        emit TokensListed(currentCount, price, quantity, seller, token);
    }

    /**
     * @dev Buyer Direct Buy Token on that price.
     * @param quantity : number of tokens.
     * @param buyer:  buyer wallet address.
     * @param id:  listed tokens id.
     */

    function buyTokens(
        uint256 id,
        uint128 quantity,
        address buyer
    ) external override onlyAdminAndUser nonReentrant {
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");
        require(listing.seller != buyer, "E12");
        require(quantity > 0, "E13");
        require(quantity <= listing.remainingQty, "E14");

        uint256 totalAmount = quantity * listing.price;

        require(stableCoin.balanceOf(buyer) >= totalAmount, "E15");

        require(
            stableCoin.allowance(buyer, address(this)) >= totalAmount,
            "E16"
        );

        listing.remainingQty -= quantity;

        IERC1400RawERC20 token = listing.token;
        address seller = listing.seller;
        uint128 price = listing.price;

        if (listing.remainingQty < 1 && listing.tokenInHold < 1) {
            listing.status = Status.Sold;
        }
        stableCoin.transferFrom(buyer, address(this), totalAmount);
        
        uint256 finalAmount = totalAmount;
        
        if (feeStatus) {
            uint256 feeAmount = (totalAmount * feePercentage) / 100 ether;
            stableCoin.transfer(feeAddress, feeAmount);
            finalAmount -=  feeAmount;
        }
        if (marginLoanStatus) {
            uint256 payToSeller = adjustLoan(
                address(listing.token),
                listing.seller,
                finalAmount
            );
            finalAmount = payToSeller;
        }
        if (finalAmount != 0) {
            stableCoin.transfer(listing.seller, finalAmount);
        }

        token.transfer(buyer, quantity);

        token.updateFromExchange(seller, quantity);

        ///@dev null all offers made on this listing.
        nullOffer(id);

        emit TokensPurchased(id, quantity, price, seller,buyer, token);
    }

    /**
     * @dev Send Offer for Purchase Token
     * @param id: listing id or order id of that token
     * @param quantity: Quantity of token that want to purchase
     * @param price: price that want to offer
     * @param buyer: Address of buyer whose want to buy token
     */

    function buyerOffer(
        uint256 id,
        uint128 quantity,
        uint128 price,
        address buyer
    ) external override onlyAdminAndUser {
        require(quantity > 0, "E8");
        ListTokens memory listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");
        require(listing.seller != buyer, "E17");

        require(price < listing.price, "E18");

        require(!listingOffers[buyer][id].isOffered, "E19");

        require(quantity <= listing.remainingQty, "E14");

        uint256 totalAmount = quantity * price;

        require(
            totalAmount <= stableCoin.allowance(buyer, address(this)),
            "E16"
        );
        require(stableCoin.balanceOf(buyer) >= totalAmount, "E15");

        listingOffers[buyer][id] = Offers({
            buyerPrice: price,
            sellerPrice: listing.price,
            quantity: quantity,
            expiryTime: block.timestamp + expiryDuration,
            isOffered: true,
            buyerCount: 1,
            sellerCount: 0,
            isCallable: true,
            status: Status.Created,
            buyer: buyer
        });

        counterAddresses[id].push(buyer);

        stableCoin.transferFrom(buyer, address(this), totalAmount);

        emit OfferPlaced(id, quantity, price, listing.seller,buyer,listing.token);
    }

    /**
     * @dev Counter on buyer offer by seller
     * @param id: listing id or order id of that token
     * @param price: price that want to offer
     * @param buyer: Address of buyer whose want to buy token
     */

    function counterSeller(
        uint256 id,
        uint128 price,
        address buyer
    ) external override onlyAdminAndSeller(id) {
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");

        Offers storage listingOffer = listingOffers[buyer][id];

        require(listingOffer.isCallable, "E20");

        require(
            listingOffer.status == Status.Created ||
                listingOffer.status == Status.Countered,
            "E21"
        );

        require(block.timestamp < listingOffer.expiryTime, "E22");
        require(price > listingOffer.buyerPrice, "E23");
        require(price < listing.price, "E24");
        require(price < listingOffer.sellerPrice, "E25");
        require(listingOffer.sellerCount < 2, "E26");

        if (listingOffer.sellerCount < 1) {
            require(listingOffer.quantity <= listing.remainingQty, "E27");
            listing.remainingQty -= listingOffer.quantity;
            listing.tokenInHold += listingOffer.quantity;
        }
        listingOffer.status = Status.Countered;
        listingOffer.sellerPrice = price;
        listingOffer.sellerCount++;
        listingOffer.isCallable = false;
        listingOffer.expiryTime = block.timestamp + expiryDuration;

        emit Counter(id, listingOffer.quantity, price, listing.seller,buyer,listing.token);
    }

    /**
     * @dev Counter on buyer offer by seller
     * @param id: listing id or order id of that token
     * @param price: price that want to offer
     * @param buyer: Address of buyer whose want to buy token
     */

    function counterBuyer(
        uint256 id,
        uint128 price,
        address buyer
    ) external override onlyAdminAndBuyer(id) {
        ListTokens memory listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");

        Offers storage listingOffer = listingOffers[buyer][id];
        require(block.timestamp < listingOffer.expiryTime, "E22");
        require(!listingOffer.isCallable, "E28");

        require(
            listingOffer.status == Status.Created ||
                listingOffer.status == Status.Countered,
            "E21"
        );

        require(price < listing.price, "E24");
        require(price < listingOffer.sellerPrice, "E29");
        require(price > listingOffer.buyerPrice, "E30");
        require(listingOffer.buyerCount < 2, "E31");

        uint256 priceDiff = price - listingOffer.buyerPrice;
        priceDiff *= listingOffer.quantity;
        require(stableCoin.allowance(buyer, address(this)) >= priceDiff, "E16");
        listingOffer.buyerPrice = price;
        listingOffer.buyerCount++;
        listingOffer.isCallable = true;
        listingOffer.expiryTime = block.timestamp + expiryDuration;

        stableCoin.transferFrom(buyer, address(this), priceDiff);

        emit Counter(id, listingOffer.quantity, price,listing.seller, buyer,listing.token);
    }

    /**
     * @dev Cancel the listing on exchange and return tokens to owner account.
     * @param id: it is the listing tokens id.
     */

    function cancelListing(
        uint256 id
    ) external override onlyAdminAndSeller(id) nonReentrant {
        ListTokens storage listing = listedTokens[id];
        require(listing.status == Status.Listed, "E11");

        address seller = listing.seller;
        IERC1400RawERC20 token = listing.token;
        uint128 quantity = listing.remainingQty;
        uint128 price = listing.price;

        listing.status = Status.UnListed;

        token.transfer(seller, quantity);
        token.updateFromExchange(seller, quantity);

        ///@dev null all offers made on this listing.
        nullOffer(id);

        emit ListingCanceled(id, price, quantity, seller, token);
    }

    /**
     * @dev null all the open offers and return the akusd to owners.
     * @param id: it is the listing tokens id.
     */

    function nullOffer(uint256 id) private {
        uint256 len = counterAddresses[id].length;
        for (uint256 i = 0; i < len; ) {
            Offers storage counteroffers = listingOffers[
                counterAddresses[id][i]
            ][id];

            ListTokens memory listing = listedTokens[id];

            if (
                counteroffers.quantity > listing.remainingQty &&
                counteroffers.sellerCount < 1
            ) {
                address buyer = counterAddresses[id][i];

                uint256 price = counteroffers.buyerPrice;
                uint256 quantity = counteroffers.quantity;

                uint256 totalAmount = (quantity * price);

                counteroffers.status = Status.Null;

                delete counterAddresses[id][i];

                stableCoin.transfer(buyer, totalAmount);
            }
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @dev get single listing
     * @param id: listing id
     * @return price ,quantity,remainingQty,tokenInHold,token,seller,status
     */

    function getListings(
        uint256 id
    )
        external
        view
        override
        returns (
           uint128 price,
            uint128 quantity,
            uint128 remainingQty,
            uint128 tokenInHold,
            IERC1400RawERC20 token,
            address seller,
            Status status   
        )
    {
        ListTokens storage listing = listedTokens[id];

        return (
            listing.price,
            listing.quantity,
            listing.remainingQty,
            listing.tokenInHold,
            listing.token,
            listing.seller,
            listing.status
        );
    }
     function getOffer(address buyerWallet,uint256 id) 
        external
        view
        override
        returns (
            uint128 buyerPrice,
            uint128 sellerPrice,
            uint256 expiryTime,
            uint128 quantity,
            address buyer,
            uint8 buyerCount,
            uint8 sellerCount,
            bool isOffered,
            bool isCallable,
            Status status
        )
    {
        Offers storage listingOffer = listingOffers[buyerWallet][id];

        return (
            listingOffer.buyerPrice,
            listingOffer.sellerPrice,
            listingOffer.expiryTime,
            listingOffer.quantity,
            listingOffer.buyer,
            listingOffer.buyerCount,
            listingOffer.sellerCount,
            listingOffer.isOffered,
            listingOffer.isCallable,
            listingOffer.status
        );
    }

    /**
     * @dev Reject Counter By Seller or Buyer.
     * @param buyer: address of buyer of tokens.
     * @param id: offers id of struct maping.
     */

    function rejectCounter(
        uint256 id,
        address buyer,
        bytes calldata signature,
        uint256 nonce
    ) external override onlyAdminAndSellerAndBuyer(id) {
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");

        Offers storage listingOffer = listingOffers[buyer][id];

        require(
            listingOffer.status == Status.Created ||
                listingOffer.status == Status.Countered,
            "E21"
        );

        bytes32 metaHash = makeHash("rejectCounter", nonce);
        address signer = getSigner(metaHash, signature);
        ///@dev Make sure signer doesn't come back as 0x0. ??
        require(signer != address(0), "E32");

        require(nonce == replayNonce[signer], "E33");

        if (signer == buyer) {
            require(!listingOffer.isCallable, "E34");
        } else if (signer == listing.seller) {
            require(listingOffer.isCallable, "E35");
        } else {
            revert("E36");
        }

        address buyerWallet = buyer;

        uint128 price = listingOffer.buyerPrice;
        uint128 quantity = listingOffer.quantity;
        uint128 totalAmount = (quantity * (price));

        listing.remainingQty += listingOffer.quantity;

        replayNonce[signer]++;

        if (listingOffer.sellerCount >= 1) {
            listing.tokenInHold -= quantity;
            listing.remainingQty += quantity;
        }

        listingOffer.status = Status.Rejected;

        stableCoin.transfer(buyerWallet, totalAmount);

        emit RejectCounter(id, quantity, price, listing.seller,buyerWallet,listing.token);
    }

    /**
     * @dev Buyer or Seller Accept Counter
     * @param id: listing id or order id of that token
     * @param signature: Address of buyer whose want to buy token
     * @param nonce: Address of buyer whose want to buy token
     */

    function acceptCounter(
        uint256 id,
        address buyer,
        bytes calldata signature,
        uint256 nonce
    ) external override onlyAdminAndSellerAndBuyer(id) nonReentrant {
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");

        Offers storage listingOffer = listingOffers[buyer][id];

        require(
            listingOffer.status == Status.Created ||
                listingOffer.status == Status.Countered,
            "E21"
        );

        bytes32 metaHash = makeHash("acceptCounter", nonce);
        address signer = getSigner(metaHash, signature);
        ///@dev Make sure signer doesn't come back as 0x0. ??
        require(signer != address(0), "E32");
        require(nonce == replayNonce[signer], "E33");

        uint128 price;
        uint128 quantity = listingOffer.quantity;
        
        if (signer == buyer) {
            require(!listingOffer.isCallable, "E37");
            uint128 priceDiff = listingOffer.sellerPrice -
                listingOffer.buyerPrice;
            priceDiff *= quantity;

            require(
                stableCoin.allowance(buyer, address(this)) >= priceDiff,
                "E16"
            );
            price = listingOffer.sellerPrice;

            stableCoin.transferFrom(buyer, address(this), priceDiff);
        } else if (signer == listing.seller) {
            require(listingOffer.isCallable, "E38");
            price = listingOffer.buyerPrice;

            if (listingOffer.sellerCount < 1) {
                listing.remainingQty -= quantity;
            }
        } else {
            revert("E36");
        }

        if (listingOffer.sellerCount >= 1) {
            listing.tokenInHold -= quantity;
        }

        uint256 totalAmount = quantity * price;
        replayNonce[signer]++;

        listingOffer.status = Status.Sold;

        if (listing.remainingQty < 1 && listing.tokenInHold < 1) {
            listing.status = Status.Sold;
        }
        
        uint256 finalAmount = totalAmount;
        
        if (feeStatus) {
            uint256 feeAmount = (totalAmount * feePercentage) / 100 ether;
            stableCoin.transfer(feeAddress, feeAmount);
            finalAmount -= feeAmount;
        }
        if (marginLoanStatus) {
            uint256 payToSeller = adjustLoan(
                address(listing.token),
                listing.seller,
                finalAmount
            );
            finalAmount = payToSeller;
        }
        if (finalAmount != 0) {
            stableCoin.transfer(listing.seller, finalAmount);
        }
        listing.token.transfer(buyer, quantity);
        listing.token.updateFromExchange(listing.seller, quantity);

        ///@dev null all offers made on this listing.
        nullOffer(id);

        emit TokensPurchased(
            id,
            quantity,
            price,
            listing.seller,
            buyer,
            listing.token
        );
    }

    /**
     * @dev buyer cancel the given offer
     * @param id: id of offers mapping
     * @param buyer: buyer address
     */

    function cancelBuyer(
        uint256 id,
        address buyer
    ) public override onlyAdminAndBuyer(id) {
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");

        Offers storage listingOffer = listingOffers[buyer][id];

        require(
            listingOffer.status != Status.Default &&
                listingOffer.status != Status.Canceled,
            "E21"
        );

        uint128 price = listingOffer.buyerPrice;
        address buyerWallet = buyer;
        uint128 quantity = listingOffer.quantity;

        uint128 totalAmount = quantity * price;

        if (listingOffer.sellerCount >= 1) {
            listing.tokenInHold -= quantity;
            listing.remainingQty += quantity;
        }

        listingOffer.status = Status.Canceled;

        stableCoin.transfer(buyerWallet, totalAmount);

        emit BuyerOfferCanceled(id,quantity, price, listing.token, listing.seller,buyerWallet);
    }

    /**
     * @dev seller: cancel the given offer
     * @param id: id of offers mapping
     * @param buyer: buyer address
     */

    function cancelSeller(
        uint256 id,
        address buyer
    ) public override onlyAdminAndSeller(id) {
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");

        Offers storage listingOffer = listingOffers[buyer][id];

        require(
            listingOffer.status != Status.Default &&
                listingOffer.status != Status.Canceled,
            "E21"
        );

        ///dev Calculate Amount to send Buyer
        uint128 price = listingOffer.buyerPrice;
        address buyerWallet = buyer;
        uint128 quantity = listingOffer.quantity;
        uint128 totalAmount = quantity * price;

        if (listingOffer.sellerCount >= 1) {
            listing.tokenInHold -= quantity;
            listing.remainingQty += quantity;
        }

        listingOffer.status = Status.Canceled;

        stableCoin.transfer(buyerWallet, totalAmount);

        emit SellerOfferCanceled(
            id,
            quantity,
            price,
            listing.token,
            listing.seller,
            buyerWallet
        );
    }

    /**
     * @dev generate hash
     * @param message: information to hash
     * @param nonce: current nonce
     * @return hash
     */

    function makeHash(
        string memory message,
        uint256 nonce
    ) public view returns (bytes32) {
        return keccak256(abi.encodePacked(address(this), message, nonce));
    }

    /**
     * @dev compute signer
     * @param hash: hash
     * @param signature: signed hash
     * @return signer address
     */

    function getSigner(
        bytes32 hash,
        bytes memory signature
    ) private pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        if (signature.length != 65) {
            return address(0);
        }
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        if (v < 27) {
            v += 27;
        }
        if (v != 27 && v != 28) {
            return address(0);
        } else {
            return
                ecrecover(
                    keccak256(
                        abi.encodePacked(
                            "\x19Ethereum Signed Message:\n32",
                            hash
                        )
                    ),
                    v,
                    r,
                    s
                );
        }
    }

    /**
     * @dev pay back the loan of seller if any
     * @param token: address or security token
     * @param seller: seller of token (borrower)
     * @param totalAmount: total selling amount of tokens
     * @return remaining akusd amount to be payed to seller after loan payment
     */

    function adjustLoan(
        address token,
        address seller,
        uint256 totalAmount
    ) private returns (uint256) {
        (address[] memory banks, uint256[] memory loanAmounts, , ) = marginLoan
            .getTotalLoanOfToken(seller, token);

        (uint256[] memory ids, uint256[] memory loans) = marginLoan
            .getTotalNoOfTokens(seller, token);

        uint256 len = banks.length;
        if (len > 0) {
            for (uint128 i = 0; i < len; ) {
                if (totalAmount == 0) {
                    break;
                }
                if (loans[i] <= totalAmount) {
                    uint256 remainingAmount = totalAmount - loanAmounts[i];

                    totalAmount = remainingAmount;

                    stableCoin.transfer(banks[i], loanAmounts[i]);
                    marginLoan.updateLoan(seller, ids[i], 0, 1);

                    emit LoanPayed(
                        loanAmounts[i],
                        IERC1400RawERC20(token),
                        seller,
                        banks[i]
                    );
                } else if (loans[i] > totalAmount) {
                    uint256 remainingLoan = loanAmounts[i] - totalAmount;
                    uint256 payableLoan = totalAmount;
                    totalAmount = 0;

                    stableCoin.transfer(banks[i], payableLoan);
                    marginLoan.updateLoan(seller, ids[i], remainingLoan, 2);

                    emit LoanPayed(
                        payableLoan,
                        IERC1400RawERC20(token),
                        seller,
                        banks[i]
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }

        return totalAmount;
    }

    /**
     * @dev update WhiteListing address
     * @param newWhitelist: address or security token
     */

    function updateWhiteListing(
        ITokenismWhitelist newWhitelist
    ) external override onlyAdmin {
        whitelist = newWhitelist;
    }

    /**
     * @dev update StableCoin address
     * @param newStableCoin: address or security token
     */

    function updateStableCoin(
        IStableCoin newStableCoin
    ) external override onlyAdmin {
        stableCoin = newStableCoin;
    }

    /**
     * @dev update MarginLoan
     * @param newMarginLoan: address or security token
     */

    function updateMarginLoan(
        IMarginLoan newMarginLoan
    ) external override onlyAdmin {
        marginLoan = newMarginLoan;
    }

    /**
     * @dev updateInterfaceHash
     * @param interfaceHash: address or security token
     */

    function updateInterfaceHash(
        string calldata interfaceHash
    ) external override onlyAdmin {
        erc1400InterfaceId = interfaceHash;
    }

    /**
     * @dev setFeeAddress
     * @param newFeeAddress: set fee address
     */

    function setFeeAddress(address newFeeAddress) external override onlyAdmin {
        require(newFeeAddress != address(0), "E32");
        feeAddress = newFeeAddress;
    }

    /**
     * @dev setFeeAmount
     * @param newFeePercentage: set fee percentage
     */

    function setFeePercentage(
        uint128 newFeePercentage // in wei
    ) external override onlyAdmin {
        feePercentage = newFeePercentage;
    }

    /**
     * @dev toggleMarginLoan
     */

    function toggleMarginLoan() external override onlyAdmin {
        marginLoanStatus = !marginLoanStatus;
    }

    /**
     * @dev toggleFee
     */

    function toggleFee() external override onlyAdmin {
        feeStatus = !feeStatus;
    }

    /**
     * @dev set expiry duration
     */

    function setExpiryDuration(uint256 newExpiryDuration) external override onlyAdmin {
        expiryDuration = newExpiryDuration;
    }



    /**
     * @dev Mark offer as expired and transfer akued amount to buyer
     * @notice This function is called from backend in api/exchange/active/ API
     */
    function expireOffer(uint256 id, address buyer) external override onlyAdmin {
        ListTokens storage listing = listedTokens[id];
        require(listing.status == Status.Listed, "E11");

        Offers storage listingOffer = listingOffers[buyer][id];
        require(
            listingOffer.status == Status.Created ||
                listingOffer.status == Status.Countered,
            "E21"
        );
        require(block.timestamp > listingOffer.expiryTime,"E39");
        uint128 price = listingOffer.buyerPrice;
        uint128 quantity = listingOffer.quantity;

        uint128 totalAmount = quantity * price;

        if (listingOffer.sellerCount >= 1) {
            listing.tokenInHold -= quantity;
            listing.remainingQty += quantity;
        }

        listingOffer.status = Status.Expired;

        stableCoin.transfer(buyer, totalAmount);

        emit OfferExpire(id,buyer,totalAmount);

    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/**
 * @title ITokenismWhitelist
 * @dev TokenismWhitelist interface
 */
interface ITokenismWhitelist {
    /**
     * @dev whitelist the user with specfic KYC and accredation verified check and time in AKRU
     * @param _wallet  Address of new user
     * @param _kycVerified is kyc true/false
     * @param _accredationVerified is accredation true/false
     * @param _accredationExpiry accredation expiry date in unix time
     */
    function addWhitelistedUser(
      address _wallet,
      bool _kycVerified,
      bool _accredationVerified,
      uint256 _accredationExpiry
        ) external;
    /**
     * @dev get the user with specfic KYC and accredation verified check and time in AKRU
     * @param _wallet  Address of  user
     * @return _wallet  Address of  user
     * @return _kycVerified is kyc true/false
     * @return _accredationVerified is accredation true/false
     * @return _accredationExpiry accredation expiry date in unix time
     */
    function getWhitelistedUser(address _wallet) external view returns (address, bool, bool, uint256, uint256);
    /**
     * @dev update the user with specfic KYC verified check in AKRU
     * @param _wallet  Address of user
     * @param _kycVerified is kyc true/false
     */
    function updateKycWhitelistedUser(address _wallet, bool _kycVerified) external;
    /**
     * @dev update the user with specfic accredation expiry date in AKRU
     * @param _wallet  Address of user
     * @param  _accredationExpiry accredation expiry date in unix time
     */
    function updateAccredationWhitelistedUser(address _wallet, uint256 _accredationExpiry) external;
    /**
     * @dev update the user with new tax holding in AKRU
     * @param _wallet  Address of user
     * @param  _taxWithholding  new taxWithholding
     */
    function updateTaxWhitelistedUser(address _wallet, uint256 _taxWithholding) external;
    /**
     * @dev suspend the whitlist user in AKRU
     * @param _wallet  Address of user
     */
    function suspendUser(address _wallet) external;
     /**
     * @dev activate the whitlist user in AKRU
     * @param _wallet  Address of user
     */
    function activeUser(address _wallet) external;
     /**
     * @dev update the whitlist user type i.e Basic or Premium in AKRU
     * @param _wallet Address of  user
     * @param _userType  Basic or Premium
     */
    function updateUserType(address _wallet, string calldata _userType) external;
    /**
     * @dev get the whitlist status number in AKRU
     * @param wallet Address of  user
     * @return will return a specific status number that define a whitlisted role in AKRU
     */
    function isWhitelistedUser(address wallet) external view returns (uint);
    /**
     * @dev remove the whitelisted user from AKRU
     * @param _wallet Address of user
     */
    function removeWhitelistedUser(address _wallet) external;
    /**
     * @dev Symbols Deployed Add to Contract
     * @param _symbols string of new symbol added in AKRU
     */
    function addSymbols(string calldata _symbols)external returns(bool);
     /**
     * @dev removed Symbol from Contract
     * @param _symbols string of already added symbol in AKRU
     */
    function removeSymbols(string calldata _symbols) external returns(bool);
     /**
     * @dev destroy the whitelist contract
     */
    function closeTokenismWhitelist() external;
     /**
     * @dev return the type of the user
     * @param _caller address of the user
     * @return _userTypes type of the user i.e Basic or Premium
     */ 
    function userType(address _caller) external view returns(bool);
     /**
     * @dev add the super admin
     * @param _superAdmin new Address of super admin
     */
    function addSuperAdmin(address _superAdmin) external;
     /**
     * @dev add the sub super admin
     * @param _subSuperAdmin new Address of super admin
     */
    function addSubSuperAdmin(address _subSuperAdmin) external;
     /**
     * @dev Update Accredential Status
     * @param status true/false
     */
     /**
     * @dev whitelist the  media manager with specfic role i.e HR,digitalMedia,marketing in AKRU
     * @param _wallet  Address of media manager
     * @param _role define i.e HR,digitalMedia,marketing
     */
    function addWhitelistedMediaRoles(address _wallet, string memory _role) external;
      /**
     * @dev get the  media manager with specfic role i.e HR,digitalMedia,marketing in AKRU
     * @param _wallet  Address of media manager
     * @return role define i.e HR,digitalMedia,marketing
     */
    function getMediaRole(address _wallet) external returns (string memory);
     /**
     * @dev update the  media manager specfic role i.e HR,digitalMedia,marketing in AKRU
     * @param _wallet  Address of media manager
     * @param _role define i.e HR,digitalMedia,marketing
     */
    function updateMediaRole(address _wallet, string memory _role) external;
     /**
     * @dev check for the  media manager with specfic role i.e HR,digitalMedia,marketing in AKRU
     * @param _wallet  Address of media manager
     * @return status
     */
    function isWhitelistedMediaRole(address _wallet) external view returns (bool);
     /**
     * @dev remove the whitelist the  media manager with specfic role i.e HR,digitalMedia,marketing in AKRU
     * @param _wallet  Address of media manager
     */
    function removeWhitelistedMediaRole(address _wallet) external;
     /**
     * @dev whitelist the manager with specfic role i.e finance,signer,assets in AKRU
     * @param _wallet  Address of manager
     * @param _role define i.e finance,signer or assets
     */
    function addWhitelistedManager(address _wallet, string memory _role) external;
     /**
     * @dev get the manager with specfic role i.e finance,signer,assets in AKRU
     * @param _wallet  Address of manager
     * @return role define i.e finance,signer or assets
     */
    function getManagerRole(address _wallet) external view returns (string memory);
      /**
     * @dev update the manager with specfic role i.e finance,signer,assets in AKRU
     * @param _wallet  Address of manager
     * @param _role define i.e finance,signer or assets
     */
    function updateRoleManager(address _wallet, string memory _role) external;
     /**
     * @dev check the manager with specfic role i.e finance,signer,assets in AKRU
     * @param _wallet  Address of manager
     * @return role status
     */
    function isWhitelistedManager(address _wallet) external view returns (bool);
     /**
     * @dev remove the manager with specfic role i.e finance,signer,assets in AKRU
     * @param _wallet  Address of manager
     */
    
    function removeWhitelistedManager(address _wallet) external;
     /**
     * @dev transfer the ownership to new super admin
     * @param _newAdmin  Address of new admin
     * @return status
     */
    function transferOwnership(address _newAdmin) external returns (bool);
     /**
     * @dev whitelist the admin with specfic role i.e dev,fee,admin in AKRU
     * @param _newAdmin  Address of new admin
     * @param _role define i.e dev,fee,admin
     */
    function addAdmin(address _newAdmin, string memory _role) external;
     /**
     * @dev remove the admin with specfic role i.e dev,fee,admin in AKRU
     * @param _adminAddress  Address of new admin
     * @return status
     */
    function removeAdmin(address _adminAddress) external returns (bool);
     /**
     * @dev whitelist the bank in with specfic role i.e bank in AKRU
     * @param _newBank  _newBank of new bank
     * @param _role define i.e bank
     */
    function addBank(address _newBank, string memory _role) external returns (bool);
      /**
     * @dev remove the bank in with specfic role i.e bank in AKRU
     * @param _bank  _newBank of new bank
     * @return status
     */
    function removeBank(address _bank) external returns (bool);
    /**
     * @dev whitelist the property owner in with specfic role i.e owner in AKRU
     * @param _newOwner  _newBank of new property owner
     * @param _role define i.e owner
     */
    function addPropertyOwner(address _newOwner, string memory _role) external returns (bool);
     /**
     * @dev remove the property owner in with specfic role i.e owner in AKRU
     * @param _newOwner address of new property owner
     * @return status
     */
    function removePropertyOwner(address _newOwner) external returns (bool);
        /**
     * @dev whitelist the feeAddress in AKRU
     * @param _feeAddress address of new fee address
     */
    function addFeeAddress(address _feeAddress) external;
    /**
     * @dev return the feeAddress in AKRU
     * @return feeAddress 
     */
    function getFeeAddress() external view returns (address);
    function updateAccreditationCheck(bool status) external;
    /**
     * @dev return the status of admin in AKRU
     * @param _calle address of admin
     * @return true/false 
     */
    function isAdmin(address _calle) external view returns (bool);
    /**
     * @dev return the status of property owner in AKRU
     * @param _calle address of property owner
     * @return true/false 
     */
    function isOwner(address _calle) external view returns (bool);
     /**
     * @dev return the status of bank in AKRU
     * @param _calle address of bank
     * @return true/false 
     */
    function isBank(address _calle) external view returns(bool);
     /**
     * @dev return the status of super admin in AKRU
     * @param _calle address of super admin
     * @return true/false 
     */
    function isSuperAdmin(address _calle) external view returns(bool);
     /**
     * @dev return the status of sub super admin in AKRU
     * @param _calle address of sub super admin
     * @return true/false 
     */
    function isSubSuperAdmin(address _calle) external view returns(bool);
     /**
     * @dev return the status of manager in AKRU
     * @param _calle address of manager
     * @return true/false 
     */
    function isManager(address _calle)external returns(bool);
    

}