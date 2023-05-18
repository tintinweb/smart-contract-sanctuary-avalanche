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
pragma solidity 0.8.19;
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
pragma solidity 0.8.19;

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
        uint256 amountPayed,
        uint256 caller
    ) external;

    function updatePledgeLoan(
        address user,
        uint256 id,
        uint256 amountPayed,
        uint256 tokensSold,
        uint256 caller
    ) external;
   function getLoanLimit(address user, address tokenAddress, uint256 loanPercentage) view external returns (uint256) ;
   function getRemainingLoanLimit( address user,address tokenAddress, uint256 loanPercentage) view external returns ( uint256);

    function addBlockedUser(address user) external ;
    
    function removeBlockedUser(address user) external;

    function isBlockedUser(address user) external view  returns(bool);

    function payPledgeLoan(address user,address tokenAddress, address bank)
        external
        returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

// import "./IAkruNFTAdminWhitelist.sol";

/**
 * @title IAkruNFTAdminWhitelist
 */
interface IAkruNFTWhitelist {
    /**
     * @dev enum of different roles
     */
    enum ROLES {
        unRegister,//0
        superAdmin,//1
        subSuperAdmin,//2
        admin,//3
        manager,//4
        mediaManager,//5
        propertyOwner,//6
        propertyAccount,//7
        propertyManager,//8
        serviceProvider,//9
        subServiceProvider,//10
        bank,//11
        user_USA,//12
        user_Foreign,//13
        user_USAPremium//14
    }

    function addWhitelistRole(address user, uint256 NFTId, ROLES role) external;

    function removeWhitelistedRole(address user, ROLES role) external;

    function addSuperAdmin() external;

    function updateAccreditationCheck(bool status) external;

    function isMediadManager(address _wallet) external view returns (bool);

    function addFeeAddress(address _feeAddress) external;

    function getFeeAddress() external view returns (address);

    function isAdmin(address _calle) external view returns (bool);

    function isSuperAdmin(address _calle) external view returns (bool);

    function isSubSuperAdmin(address _calle) external view returns (bool);

    function isBank(address _calle) external view returns (bool);

    function isOwner(address _calle) external view returns (bool);

    function isManager(address _calle) external view returns (bool);

    function getRoleInfo(
        uint256 id
    )
        external
        view
        returns (
            uint256 roleId,
            ROLES roleName,
            uint256 NFTID,
            address userAddress,
            uint256 idPrefix,
            bool valid
        );

    function checkUserRole(
        address userAddress,
        ROLES role
    ) external view returns (bool);

    function setRoleIdPrefix(ROLES role, uint256 IdPrefix) external;

    function getRoleIdPrefix(ROLES role) external view returns (uint256);

    function addWhitelistUser(
        address _wallet,
        bool _kycVerified,
        bool _accredationVerified,
        uint256 _accredationExpiry,
        ROLES role,
        uint256 NFTId
    ) external;

    function getWhitelistedUser(
        address _wallet
    )
        external
        view
        returns (address, bool, bool, uint256, ROLES, uint256, uint256, bool);

    function removeWhitelistedUser(address user, ROLES role) external;

    function updateKycWhitelistedUser(
        address _wallet,
        bool _kycVerified
    ) external;

    function updateUserAccredationStatus(
        address _wallet,
        bool AccredationStatus
    ) external;

    function updateAccredationWhitelistedUser(
        address _wallet,
        uint256 _accredationExpiry
    ) external;

    function updateTaxWhitelistedUser(
        address _wallet,
        uint256 _taxWithholding
    ) external;

    function addSymbols(string calldata _symbols) external returns (bool);

    function removeSymbols(string calldata _symbols) external returns (bool);

    function isKYCverfied(address user) external view returns (bool);

    function isAccreditationVerfied(address user) external view returns (bool);

    function isAccredatitationExpired(
        address user
    ) external view returns (bool);

    function getAllUserStoredData()
        external
        view
        returns (
            address[] memory _userList,
            bool[] memory _validity,
            bool[] memory _kycVery,
            bool[] memory _accredationVery,
            uint256[] memory _accredationExpir,
            uint256[] memory _taxWithHold
        );

    function isUserUSA(address user) external view returns (bool);

    function isUserForeign(address user) external view returns (bool);

    function userType(address _caller) external view returns (bool);

    function getWhitelistInfo(
        address user
    )
        external
        view
        returns (
            bool valid,
            address wallet,
            bool kycVerified,
            bool accredationVerified,
            uint256 accredationExpiry,
            uint256 taxWithholding,
            ROLES role,
            uint256 userRoleId
        );
    function getUserRole(
        address _userAddress
    ) external view returns (string memory, ROLES);

    function closeTokenismWhitelist() external;

    function isWhitelistedUser(address _userAddress) external view returns (uint256);
    // function ownerOf(uint256 tokenId) external returns (address);
    // function transferOwnerShip(address from,address to, uint256 tokenId) external;
    

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

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
        string memory interfaceLabel,
        address implementation
    ) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(
            address(this),
            interfaceHash,
            implementation
        );
    }

    function interfaceAddr(
        address addr,
        string memory interfaceLabel
    ) internal view returns (address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address newManager) internal {
        ERC1820REGISTRY.setManager(address(this), newManager);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

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
    function reserveWallet() external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../token/SecurityToken-US/ERC20/IERC1400RawERC20.sol";
// import "../whitelist/ITokenismWhitelist.sol";
import "./../NFTwhitelist/IAkruNFTWhitelist.sol";
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
     *  E15: Insufficient AKUSD balance or Not Allowed Balance
     *  E16: Insufficient AKUSD allowance
     *  E17: Seller cannot place Offer
     *  E18: Price set by Buyer must be less than seller price
     *  E19: Buyer already offered
     *  E20: Wait for buyer counter
     *  E21: No offers found
     *  E22: Offer expired
     *  E23: Price must be greater than buyer offer price
     *  E24: Price must be smaller than listing price and Price must be greater than buyer offer price and Price must be lesser than previous offer price
     *  E25: Price must be lesser than previous offer price
     *  E26: Seller counter exceeded
     *  E27: Remaing Quantity is must be greater or equal to offering quantity
     *  E28: Wait for seller counter
     *  E29: Price must be smaller than seller offer price and Greater than Buyer Offer Priced and Price must be smaller than listing price and  Price must be greater than previous offer price
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
     *  E40: Invalid Signer or Incorrect Nonce
     *  E41: Unable to transfer token(s)
     *  E42 : Token is Not Accepting on this Exchange
     */

    enum Status {
        Default, // default value
        Listed, //for listings
        UnListed, //for Un listings
        Sold, // for offers and listings
        Created, // for offers Create
        Countered, // for on Counter
        Canceled, // for Cancelled Offer
        Rejected, //for Rejected
        Null, // for Not Exist more
        Expired // Expired Offer
    }

    struct Offers {
        uint128 buyerPrice;
        uint128 sellerPrice;
        uint256 expiryTime;
        uint128 quantity;
        uint256 buyerFeeAmount;
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
        bool isUsUSer;
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
        IERC1400RawERC20 token,
        address feeAddress,
        uint256 feeAmount
    );

    event Counter(
        uint256 indexed id,
        uint128 quantity,
        uint128 price,
        address indexed seller,
        address indexed buyer, 
        IERC1400RawERC20 token,
        uint256 buyerFee
        
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
        uint256 totalAmount,
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
    event UpdateStableCoin(address caller, address newStableCoin);
    event UpdateMarginLoan(address caller, address newMarginLoan);
    event UpdateWhiteListing(address caller, address whitelist);
    event SetFeeAddress(address caller, address newFeeAddress);
    event SetFeePercentage(address caller, uint128 newFeePercentage, string area);
    event ToggleMarginLoan(address caller, bool marginLoanStatus);
    event ToggleFee(address caller, bool feeStatus, string area);
    event SetExpiryDuration(address caller,uint256 expiryDuration);
    event IsExchangeForBoth(bool status, address sender);
    event TokenStatus(address caller, address token1, address token2,bool status);



    function sellTokens(
        uint128 price,
        uint128 quantity,
        IERC1400RawERC20 token
    ) external;

    function buyTokens(uint256 id, uint128 quantity) external;

    function buyerOffer(
        uint256 id,
        uint128 quantity,
        uint128 price
    ) external;

    function setFeeAddress(address newFeeAddress) external;

    function setFeePercentageUS(uint128 newFeePercentage) external;
    function setFeePercentageNonUS(uint128 newFeePercentage) external;


    function counterSeller(
        uint256 id, 
        uint128 price, 
        address buyer
    ) external;

    function counterBuyer(
        uint256 id,
        uint128 price,
        address buyer
    ) external;

    function cancelListing(
        uint256 id
    ) external;

    function rejectCounter(
        uint256 id,
        address buyer
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
        address buyer
    ) external;

    function cancelBuyer(
        uint256 id
    ) external;

    function cancelSeller(
        uint256 id, 
        address buyer
    ) external;

    function updateWhiteListing(IAkruNFTWhitelist newWhitelist) external;

    function updateStableCoin(IStableCoin newStableCoin) external;

    function updateMarginLoan(IMarginLoan newMarginLoan) external;

    // function updateInterfaceHash(string calldata interfaceHash) external;

    function toggleMarginLoan() external;

    function toggleFeeUS() external;
    function toggleFeeNonUS() external;

    function setExpiryDuration(uint256 newExpiryDuration) external;
    
    function expireOffer(uint256 id, address _wallet) external;
    function tokenStatus(address token, bool status) external;

    function tokenStatus(address token1,address token2, bool status) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "./IUniversalExchange.sol";
import "../token/SecurityToken-US/ERC1820/ERC1820Client.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";
/**
 * @title Universal Exchange
 * @author Umer Mubeen & Asadullah Khan
 * @notice Singleton Exchange Instance
 * @dev AKRU Exchange Smart Contract for Secondary Market
 */

contract UniversalExchange is
    IUniversalExchange,
    ERC1820Client,
    ReentrancyGuard
{
    using Counters for Counters.Counter;
    Counters.Counter public count;
    IStableCoin public stableCoin;
    IAkruNFTWhitelist public whitelist;
    IMarginLoan public marginLoan;
    address public feeAddress;
    // uint256 public feePercentage; // in wei
//Set Percentage of US and Non US fee Address
    uint256 public feePercentageUS; // in wei
    uint256 public feePercentageNonUS; // in wei

    // string public erc1400InterfaceId = "ERC20Token";
    bool public marginLoanStatus = false;
    // bool public feeStatus = false;
// Add for seperation of US and Non US Fee Status
    bool public feeStatusUS = false;
    bool public feeStatusNonUS = false;

    uint256 public expiryDuration = 10 minutes; // for production set 2 days

    ///@dev listing id to listing detail
    mapping(uint256 => ListTokens) private listedTokens;

    ///@dev offeror address to listing id to offer detail
    mapping(address => mapping(uint256 => Offers)) private listingOffers;

    ///@dev listing id to array of offeror address
    mapping(uint256 => address[]) public counterAddresses;
    ///@dev Tokens accepting for sale.
    mapping(address => bool) public isTokenAccepted;
    bool public isOpenForBoth;
    constructor(
        IStableCoin stableCoinAddress,
        IAkruNFTWhitelist whitelistingAddress,
        IMarginLoan marginLoanAddress
    ) {
        stableCoin = stableCoinAddress;
        whitelist = whitelistingAddress;
        marginLoan = marginLoanAddress;
    }

    function _onlyAdmin() private view {
        require(whitelist.isAdmin(msg.sender), "E1");
    }

    function _onlyAdminAndUser() private view {
        require(
            whitelist.isAdmin(msg.sender) ||
                whitelist.isWhitelistedUser(msg.sender) <= 200,
            "E2"
        );
    }

    function _onlyAdminAndSeller(uint256 id) private view {
        ListTokens memory listing = listedTokens[id];

        require(
            whitelist.isAdmin(msg.sender) || listing.seller == msg.sender,
            "E3"
        );
    }

    function _onlyAdminAndBuyer(uint id) private view {
        require(
            whitelist.isAdmin(msg.sender) ||
            listingOffers[msg.sender][id].buyer == msg.sender,
            "E4"
        );
    }

    function _onlyAdminAndSellerAndBuyer(uint id) private view {
        ListTokens memory listing = listedTokens[id];

        Offers memory listingOffer = listingOffers[msg.sender][id];

        require(
            whitelist.isAdmin(msg.sender) ||
                listing.seller == msg.sender ||
                listingOffer.buyer == msg.sender,
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
         * @param token: Address of ERC1400/Security token
     */

    function sellTokens(
        uint128 price,
        uint128 quantity,
        IERC1400RawERC20 token
    ) external override nonReentrant onlyAdminAndUser {
        // require(
        //     interfaceAddr(address(token), erc1400InterfaceId) != address(0),
        //     "E6"
        // );
        require(isTokenAccepted[address(token)], "E42");

        require(price > 0 && quantity > 0 , "E7");
        require(quantity <= token.balanceOf(msg.sender), "E9");
        require(quantity <= token.allowance(msg.sender, address(this)), "E10");
        uint256 currentCount = count.current();
        bool usUser;
        if(whitelist.isUserForeign(msg.sender)){
            usUser = false;
        }else{
            usUser = true;
        }
        listedTokens[currentCount] = ListTokens({
            seller: msg.sender,
            token: token,
            price: price,
            quantity: quantity,
            remainingQty: quantity,
            tokenInHold: 0,
            status: Status.Listed,
            isUsUSer: usUser
        });
        count.increment();
        token.addFromExchange(msg.sender, quantity);
        require(token.transferFrom(msg.sender, address(this), quantity),"E41");
        emit TokensListed(currentCount, price, quantity, msg.sender, token);
    }

    /**
         * @dev Buyer Direct Buy Token on that price.
         * @param quantity : number of tokens.
         * @param id:  listed tokens id.
     */

    function buyTokens(
        uint256 id,
        uint128 quantity
    ) external override onlyAdminAndUser nonReentrant {
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");
        require(listing.seller != msg.sender, "E12");
        require(quantity > 0, "E13");
        require(quantity <= listing.remainingQty, "E14");

        if(!isOpenForBoth){
            require(whitelist.isUserForeign(msg.sender) != listing.isUsUSer,"Only Related User Purchase Token");
        }
        uint256 totalAmount = quantity * listing.price;
        uint256 feeAmount = 0 ;

        if(whitelist.isUserUSA(msg.sender) == listing.isUsUSer && feeStatusUS ){
            feeAmount = (totalAmount * feePercentageUS) / 100 ether;
            totalAmount = totalAmount +feeAmount;
        }else if(whitelist.isUserForeign(msg.sender) != listing.isUsUSer && feeStatusNonUS){
            feeAmount = (totalAmount * feePercentageNonUS) / 100 ether;
            totalAmount = totalAmount + feeAmount;
        }
        listing.remainingQty -= quantity;
        IERC1400RawERC20 token = listing.token;
        uint128 price = listing.price;
        if (listing.remainingQty == 0 && listing.tokenInHold == 0) {
            listing.status = Status.Sold;
        }
        

        if(whitelist.isUserUSA(msg.sender) == listing.isUsUSer && feeStatusUS ){
            feeAmount = (totalAmount * feePercentageUS) / 1000 ether;
            totalAmount +=  feeAmount;
            
        }else if(whitelist.isUserForeign(msg.sender) != listing.isUsUSer && feeStatusNonUS){
            feeAmount = (totalAmount * feePercentageNonUS) / 100 ether;
            totalAmount = totalAmount + feeAmount;
        }
        require(stableCoin.balanceOf(msg.sender) >= totalAmount && stableCoin.allowance(msg.sender, address(this)) >= totalAmount, "E15");
        require(stableCoin.transferFrom(msg.sender, address(this), totalAmount),"E41");
        if (feeStatusUS || feeStatusNonUS) { // If fee Status is on then transfer fee to fee address
            require(stableCoin.transfer(feeAddress, feeAmount *2),"E41");
            totalAmount -=  feeAmount * 2;
        }

        if (marginLoanStatus) {
            uint256 payToSeller = adjustLoan(
                address(listing.token),
                listing.seller,
                totalAmount
            );
            totalAmount = payToSeller;
        }
        if (totalAmount != 0) {
            require(stableCoin.transfer(listing.seller, totalAmount),"E41");
        }
        require(token.transfer(msg.sender, quantity),"E41");
        token.updateFromExchange(listing.seller, quantity);
        ///@dev null all offers made on this listing.
        nullOffer(id);
        emit TokensPurchased(id, quantity, price, listing.seller,msg.sender, token, feeAddress, feeAmount*2);

    }

    /**
     * @dev Send Offer for Purchase Token
     * @param id: listing id or order id of that token
     * @param quantity: Quantity of token that want to purchase
     * @param price: price that want to offer
     */

    function buyerOffer(
        uint256 id,
        uint128 quantity,
        uint128 price
    ) external override onlyAdminAndUser {
        require(quantity > 0, "E8");
        ListTokens storage listing = listedTokens[id];

        require(listing.status == Status.Listed, "E11");
        require(listing.seller != msg.sender, "E17");

        require(price < listing.price, "E18");

        require(!listingOffers[msg.sender][id].isOffered, "E19");

        require(quantity <= listing.remainingQty, "E14");
        if(!isOpenForBoth){
            require(whitelist.isUserForeign(msg.sender) != listing.isUsUSer,"Only Related User Purchase Token");
        }

        uint256 totalAmount = quantity * price;
        uint256 feeAmount;
        if(whitelist.isUserUSA(msg.sender) == listing.isUsUSer && feeStatusUS ){
            feeAmount = (totalAmount * feePercentageUS) / 100 ether;
            totalAmount = totalAmount +feeAmount;
        }else if(whitelist.isUserForeign(msg.sender) != listing.isUsUSer && feeStatusNonUS){
            feeAmount = (totalAmount * feePercentageNonUS) / 100 ether;
            totalAmount = totalAmount + feeAmount;
        }

        require(stableCoin.balanceOf(msg.sender) >= totalAmount && totalAmount <= stableCoin.allowance(msg.sender, address(this)), "E15");
        listingOffers[msg.sender][id] = Offers({
            buyerPrice: price,
            sellerPrice: listing.price,
            quantity: quantity,
            buyerFeeAmount:feeAmount,
            expiryTime: block.timestamp + expiryDuration,
            isOffered: true,
            buyerCount: 1,
            sellerCount: 0,
            isCallable: true,
            status: Status.Created,
            buyer: msg.sender
        });

        counterAddresses[id].push(msg.sender);

        require(stableCoin.transferFrom(msg.sender, address(this), totalAmount),"E41");
        emit Counter(id, quantity, price, listing.seller,msg.sender,listing.token, feeAmount);
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
        Offers storage listingOffer = listingOffers[buyer][id];

        require(listing.status == Status.Listed && 
            (listingOffer.status == Status.Created || 
             listingOffer.status == Status.Countered), "E11/E21");

        require(listingOffer.isCallable, "E20");

        require(msg.sender == listing.seller, "E40");

        require(block.timestamp < listingOffer.expiryTime, "E22");
        require(price > listingOffer.buyerPrice && price < listing.price && price < listingOffer.sellerPrice, "E23");
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
        emit Counter(id, listingOffer.quantity, price, listing.seller,buyer,listing.token, 0);
    }

    /**
     * @dev Counter on seller offer by Buyer
     * @param id: listing id or order id of that token
     * @param price: price that want to offer
     */

    function counterBuyer(
        uint256 id,
        uint128 price,
        address seller
    ) external override onlyAdminAndBuyer(id) {
        ListTokens memory listing = listedTokens[id];
        require(listing.status == Status.Listed, "E11");
        Offers storage listingOffer = listingOffers[seller][id];
        require(!listingOffer.isCallable, "E28");
        require(
                listingOffer.status == Status.Created ||
                listingOffer.status == Status.Countered,
            "E21"
        );
        require(block.timestamp < listingOffer.expiryTime, "E22");
        require(price < listing.price && price < listingOffer.sellerPrice && price > listingOffer.buyerPrice, "E29");
        require(listingOffer.buyerCount < 2, "E31");
        uint256 priceDiff = price - listingOffer.buyerPrice;
        priceDiff *= listingOffer.quantity;
        uint256 feeAmount;

        if(whitelist.isUserUSA(msg.sender) == listing.isUsUSer && feeStatusUS ){
            feeAmount = (priceDiff * feePercentageUS) / 100 ether;
            priceDiff = priceDiff +feeAmount;
        }else if(whitelist.isUserForeign(msg.sender) != listing.isUsUSer && feeStatusNonUS){
            feeAmount = (priceDiff * feePercentageNonUS) / 100 ether;
            priceDiff = priceDiff + feeAmount;
        }
        require(stableCoin.allowance(msg.sender, address(this)) >= priceDiff, "E16");
        listingOffer.status = Status.Countered;
        listingOffer.buyerPrice = price;
        listingOffer.buyerCount++;
        listingOffer.isCallable = true;
        listingOffer.expiryTime = block.timestamp + expiryDuration;
        listingOffer.buyerFeeAmount += feeAmount; 

        require(stableCoin.transferFrom(msg.sender, address(this), priceDiff),"E41");
        emit Counter(id, listingOffer.quantity, price,listing.seller, msg.sender,listing.token, feeAmount);
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
        require(msg.sender == listing.seller, "E40");
        listing.status = Status.UnListed;
        listing.token.updateFromExchange(listing.seller, listing.remainingQty+listing.tokenInHold);
        require(listing.token.transfer(listing.seller, listing.remainingQty + listing.tokenInHold),"E41");
        listing.remainingQty = 0;
        listing.tokenInHold =0;
        nullOffer(id);
        emit ListingCanceled(id, listing.price, listing.remainingQty, listing.seller, listing.token);
    }
    /**
         * @dev null all the open offers and return the akusd to owners.
         * @param id: it is the listing tokens id.
     */

    function nullOffer(uint256 id) private {
        uint256 len = counterAddresses[id].length;
        for (uint256 i = 0; i < len; ) {
            Offers storage counteroffers = listingOffers[counterAddresses[id][i]][id];
            ListTokens memory listing = listedTokens[id];
            if( counteroffers.quantity  > listing.remainingQty + listing.tokenInHold && counteroffers.status == Status.Created)
             {
                address buyer = counterAddresses[id][i];
                uint256 price = counteroffers.buyerPrice;
                uint256 quantity = counteroffers.quantity;

                uint256 totalAmount = (quantity * price) + counteroffers.buyerFeeAmount;

                counteroffers.status = Status.Null;

                delete counterAddresses[id][i];

                require(stableCoin.transfer(buyer, totalAmount),"E41");
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
    /**
     * 
     * @dev Check offer by sending address of buyer and Id on which they send offer
     * @param buyerWallet address of buyer wallet
     * @param id Id on which buyer put offer
     * @return buyerPrice Price that offer by buyer
     * @return sellerPrice Price of seller
     * @return expiryTime Expiry time of that offer
     * @return quantity  Quantity of Token on which they offered
     * @return buyer  address of buyer
     * @return buyerCount number of counter buyer did
     * @return sellerCount  number of counter seller did
     * @return isOffered  check isOffered or not
     * @return isCallable  is callable by the buyer
     * @return status  status of this offer
     */
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
        address buyer
    ) external override onlyAdminAndSellerAndBuyer(id) {
        ListTokens storage listing = listedTokens[id];
        Offers storage listingOffer = listingOffers[buyer][id];
        require(listing.status == Status.Listed, "E11");
            require(listingOffer.status == Status.Created || 
             listingOffer.status == Status.Countered, "E21");
        if (msg.sender == listing.seller) {
            require(listingOffer.isCallable, "E35");
        } 
        else if(msg.sender == buyer) {
            require(!listingOffer.isCallable, "E34");
        } else {
            revert("E36");
        }
        uint128 price = listingOffer.buyerPrice;
        uint128 quantity = listingOffer.quantity;
        uint256 totalAmount = (quantity * (price)) + listingOffer.buyerFeeAmount;
        if (listingOffer.sellerCount >= 1) {
            listing.remainingQty += listingOffer.quantity;
            listing.tokenInHold -= listingOffer.quantity;
        }       
        listingOffer.status = Status.Rejected;
       require(stableCoin.transfer(buyer, totalAmount),"E41");
        emit RejectCounter(id, quantity, price, listing.seller,buyer,listing.token);
    }
    /**
     * @dev Buyer or Seller Accept Counter
     * @param id: listing id or order id of that token
     */

    function acceptCounter(
        uint256 id,
        address buyer
    ) external override onlyAdminAndSellerAndBuyer(id) nonReentrant {
        ListTokens storage listing = listedTokens[id];
        require(listing.status == Status.Listed, "E11");
        Offers storage listingOffer = listingOffers[buyer][id];
        require(
            listingOffer.status == Status.Created ||
                listingOffer.status == Status.Countered,
            "E21"
        );
        uint128 price = 0;
        uint128 quantity = listingOffer.quantity;
        uint256 feeAmount = 0;
        
        if (msg.sender == buyer) {
            require(!listingOffer.isCallable, "E37");
            uint256 priceDiff = listingOffer.sellerPrice -
                listingOffer.buyerPrice;
            priceDiff *= quantity;
            if(whitelist.isUserUSA(msg.sender) == listing.isUsUSer && feeStatusUS ){
                feeAmount = (priceDiff *feePercentageUS)/100 ether;
                priceDiff = priceDiff + feeAmount;   
            }else if(whitelist.isUserForeign(msg.sender) != listing.isUsUSer && feeStatusNonUS){
                feeAmount = (priceDiff *feePercentageNonUS)/100 ether;
                priceDiff = priceDiff + feeAmount;
            }
            require(stableCoin.allowance(buyer, address(this)) >= priceDiff, "E16");
            price = listingOffer.sellerPrice;
            require(stableCoin.transferFrom(buyer, address(this), priceDiff),"E41");
        } else if (msg.sender == listing.seller) {
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
        listingOffer.status = Status.Sold;
        if (listing.remainingQty < 1 && listing.tokenInHold < 1) {
            listing.status = Status.Sold;
        }
        uint256 finalAmount = totalAmount;
        console.log("Final amount before Fee deduction", finalAmount);

      
        if(whitelist.isUserUSA(msg.sender) == listing.isUsUSer && feeStatusUS ){
             feeAmount = ((totalAmount * feePercentageUS) / 100 ether)*2;
             console.log("Fee Amount",feeAmount);
            require(stableCoin.transfer(feeAddress, feeAmount),"E41");
            finalAmount -= feeAmount;   
        }else if(whitelist.isUserForeign(msg.sender) != listing.isUsUSer && feeStatusNonUS){
             feeAmount = ((totalAmount * feePercentageNonUS) / 100 ether)*2;
            require(stableCoin.transfer(feeAddress, feeAmount),"E41");
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
        console.log("Final amount", finalAmount);
        if (finalAmount != 0) {
            require(stableCoin.transfer(listing.seller, finalAmount),"E41");
        }
        require(listing.token.transfer(buyer, quantity),"E41");
        listing.token.updateFromExchange(listing.seller, quantity);
        ///@dev null all offers made on this listing.
        nullOffer(id);
        emit TokensPurchased(id,listingOffer.quantity,price,listing.seller,buyer, listing.token, feeAddress, feeAmount *2 );
    }
    /**
     * @dev buyer cancel the given offer
     * @param id: id of offers mapping
     */

    function cancelBuyer(
        uint256 id
    ) public override onlyAdminAndBuyer(id) nonReentrant {
        ListTokens storage listing = listedTokens[id];
        require(listing.status == Status.Listed, "E11");
        Offers storage listingOffer = listingOffers[msg.sender][id];
        require(msg.sender == listingOffer.buyer, "E40");
        require(
            listingOffer.status != Status.Default &&
                listingOffer.status != Status.Canceled,
            "E21"
        );
        uint128 price = listingOffer.buyerPrice;
        uint128 quantity = listingOffer.quantity;
        uint256 totalAmount = (quantity * price) + listingOffer.buyerFeeAmount;
        if (listingOffer.sellerCount >= 1) {
            listing.tokenInHold -= quantity;
            listing.remainingQty += quantity;
        }
        listingOffer.status = Status.Canceled;
        require(stableCoin.transfer(msg.sender, totalAmount),"E41");    
        emit BuyerOfferCanceled(id,quantity, price, listing.token, listing.seller,msg.sender);
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
        require(msg.sender == listing.seller, "E40");
        Offers storage listingOffer = listingOffers[buyer][id];
        require(
            listingOffer.status != Status.Default &&
                listingOffer.status != Status.Canceled,
            "E21"
        );
        uint128 price = listingOffer.buyerPrice;
        uint128 quantity = listingOffer.quantity;
        uint256 buyerOfferFee = listingOffer.buyerFeeAmount;
        uint256 totalAmount = (quantity * price) + buyerOfferFee;
        if (listingOffer.sellerCount >= 1) {
            listing.tokenInHold -= quantity;
            listing.remainingQty += quantity;
        }
        listingOffer.status = Status.Canceled;
        require(stableCoin.transfer(buyer, totalAmount),"E41");    
        emit SellerOfferCanceled(
            id,
            quantity,
            totalAmount,
            price,
            listing.token,
            msg.sender,
            buyer
        );
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

                    require(stableCoin.transfer(banks[i], loanAmounts[i]),"E41");
                   
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

                    bool isLoanTransfer = stableCoin.transfer(banks[i], payableLoan);
                    require(isLoanTransfer,"E41");
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
        IAkruNFTWhitelist newWhitelist
    ) external override onlyAdmin {
        whitelist = newWhitelist;
        emit UpdateWhiteListing(msg.sender, address(whitelist));
    }
    /**
     * @dev update StableCoin address
     * @param newStableCoin: address or security token
     */

    function updateStableCoin(
        IStableCoin newStableCoin
    ) external override onlyAdmin {
        stableCoin = newStableCoin;
        emit UpdateStableCoin(msg.sender, address(newStableCoin));
    }
    /**
     * @dev update MarginLoan
     * @param newMarginLoan: address or security token
     */

    function updateMarginLoan(
        IMarginLoan newMarginLoan
    ) external override onlyAdmin {
        marginLoan = newMarginLoan;
        emit UpdateMarginLoan(msg.sender, address(newMarginLoan));
    }
    /**
     * @dev updateInterfaceHash
     * @param interfaceHash: address or security token
     */

    // function updateInterfaceHash(
    //     string calldata interfaceHash
    // ) external override onlyAdmin {
    //     erc1400InterfaceId = interfaceHash;

    // }
    /**
     * @dev setFeeAddress
     * @param newFeeAddress: set fee address
     */

    function setFeeAddress(address newFeeAddress) external override onlyAdmin {
        require(newFeeAddress != address(0), "E32");
        feeAddress = newFeeAddress;
        emit SetFeeAddress(msg.sender, newFeeAddress);
    }
    /**
     * @dev set Fee Percentage for US user
     * @param newFeePercentage: set fee percentage
     */
    function setFeePercentageUS(
        uint128 newFeePercentage // in wei
    ) external override onlyAdmin {
        feePercentageUS = newFeePercentage;
        emit SetFeePercentage(msg.sender, newFeePercentage, "US");
    }
      /**
     * @dev set Fee Percentage for US user
     * @param newFeePercentage: set fee percentage
     */
    function setFeePercentageNonUS(
                uint128 newFeePercentage // in wei
            ) external override onlyAdmin {
                feePercentageNonUS = newFeePercentage;
                emit SetFeePercentage(msg.sender, newFeePercentage, "Non-US");
            }
    /**
     * @dev toggleMarginLoan
     */

    function toggleMarginLoan() external override onlyAdmin {
        marginLoanStatus = !marginLoanStatus;
        emit ToggleMarginLoan(msg.sender, marginLoanStatus);
    }
    /**
     * @dev Toggle Fee US side
     */
    function toggleFeeUS() external override onlyAdmin {
        feeStatusUS = !feeStatusUS;
        emit ToggleFee(msg.sender, feeStatusUS, "US");
    }
    /**
     * @dev Toggle Fee on Non US
     */
        function toggleFeeNonUS() external override onlyAdmin {
            feeStatusNonUS = !feeStatusNonUS;
            emit ToggleFee(msg.sender, feeStatusNonUS, "Non-US");
        }
    /**
     * @dev set expiry duration
     */
    function setExpiryDuration(uint256 newExpiryDuration) external override onlyAdmin {
        expiryDuration = newExpiryDuration;
        emit SetExpiryDuration(msg.sender,newExpiryDuration);
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
        uint256 totalAmount = (quantity * price) + listingOffer.buyerFeeAmount;
        if (listingOffer.sellerCount >= 1) {
            listing.tokenInHold -= quantity;
            listing.remainingQty += quantity;
        }
        listingOffer.status = Status.Expired;
        require(stableCoin.transfer(buyer, totalAmount),"E41");
        emit OfferExpire(id,buyer,totalAmount);
    }
    /**
     * 
     * @param token address of token
     * @param status status of token
     */
    function tokenStatus(address token, bool status)public onlyAdmin{
        isTokenAccepted[token] = status;
        emit TokenStatus(msg.sender, token,address(0), status);
    }
    /**
     * @dev Add 2 tokens or remove 2 tokens at a time on exchange
     * @param token1  token1 address that want to give permision on exchnage
     * @param token2  token2 address that want to give permision on exchnage
     * @param status Status of Tokens it will be true for active false for deactivate
     */
    function tokenStatus(address token1, address token2, bool status) public onlyAdmin{
        isTokenAccepted[token1] = status;
        isTokenAccepted[token2] = status;
        emit TokenStatus(msg.sender, token1, token2, status);

    }
/**
 * @dev Its changing status is US and NON US user purchase and sell in between them
 * @param status status of Exchange Excepting for both
 */
    function isExchangeForBoth(bool status)public onlyAdmin{
        isOpenForBoth = status;
        emit IsExchangeForBoth(status, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.4.22 <0.9.0;

library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function _sendLogPayload(bytes memory payload) private view {
		uint256 payloadLength = payload.length;
		address consoleAddress = CONSOLE_ADDRESS;
		assembly {
			let payloadStart := add(payload, 32)
			let r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)
		}
	}

	function log() internal view {
		_sendLogPayload(abi.encodeWithSignature("log()"));
	}

	function logInt(int256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(int256)", p0));
	}

	function logUint(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function logString(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function logBool(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function logAddress(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function logBytes(bytes memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes)", p0));
	}

	function logBytes1(bytes1 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes1)", p0));
	}

	function logBytes2(bytes2 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes2)", p0));
	}

	function logBytes3(bytes3 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes3)", p0));
	}

	function logBytes4(bytes4 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes4)", p0));
	}

	function logBytes5(bytes5 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes5)", p0));
	}

	function logBytes6(bytes6 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes6)", p0));
	}

	function logBytes7(bytes7 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes7)", p0));
	}

	function logBytes8(bytes8 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes8)", p0));
	}

	function logBytes9(bytes9 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes9)", p0));
	}

	function logBytes10(bytes10 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes10)", p0));
	}

	function logBytes11(bytes11 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes11)", p0));
	}

	function logBytes12(bytes12 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes12)", p0));
	}

	function logBytes13(bytes13 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes13)", p0));
	}

	function logBytes14(bytes14 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes14)", p0));
	}

	function logBytes15(bytes15 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes15)", p0));
	}

	function logBytes16(bytes16 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes16)", p0));
	}

	function logBytes17(bytes17 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes17)", p0));
	}

	function logBytes18(bytes18 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes18)", p0));
	}

	function logBytes19(bytes19 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes19)", p0));
	}

	function logBytes20(bytes20 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes20)", p0));
	}

	function logBytes21(bytes21 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes21)", p0));
	}

	function logBytes22(bytes22 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes22)", p0));
	}

	function logBytes23(bytes23 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes23)", p0));
	}

	function logBytes24(bytes24 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes24)", p0));
	}

	function logBytes25(bytes25 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes25)", p0));
	}

	function logBytes26(bytes26 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes26)", p0));
	}

	function logBytes27(bytes27 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes27)", p0));
	}

	function logBytes28(bytes28 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes28)", p0));
	}

	function logBytes29(bytes29 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes29)", p0));
	}

	function logBytes30(bytes30 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes30)", p0));
	}

	function logBytes31(bytes31 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes31)", p0));
	}

	function logBytes32(bytes32 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bytes32)", p0));
	}

	function log(uint256 p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256)", p0));
	}

	function log(string memory p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string)", p0));
	}

	function log(bool p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool)", p0));
	}

	function log(address p0) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address)", p0));
	}

	function log(uint256 p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256)", p0, p1));
	}

	function log(uint256 p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string)", p0, p1));
	}

	function log(uint256 p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool)", p0, p1));
	}

	function log(uint256 p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address)", p0, p1));
	}

	function log(string memory p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256)", p0, p1));
	}

	function log(string memory p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string)", p0, p1));
	}

	function log(string memory p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool)", p0, p1));
	}

	function log(string memory p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address)", p0, p1));
	}

	function log(bool p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256)", p0, p1));
	}

	function log(bool p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string)", p0, p1));
	}

	function log(bool p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool)", p0, p1));
	}

	function log(bool p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address)", p0, p1));
	}

	function log(address p0, uint256 p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256)", p0, p1));
	}

	function log(address p0, string memory p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string)", p0, p1));
	}

	function log(address p0, bool p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool)", p0, p1));
	}

	function log(address p0, address p1) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address)", p0, p1));
	}

	function log(uint256 p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool)", p0, p1, p2));
	}

	function log(uint256 p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool)", p0, p1, p2));
	}

	function log(uint256 p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool)", p0, p1, p2));
	}

	function log(uint256 p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool)", p0, p1, p2));
	}

	function log(string memory p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
	}

	function log(string memory p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
	}

	function log(string memory p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256)", p0, p1, p2));
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
	}

	function log(string memory p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
	}

	function log(string memory p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool)", p0, p1, p2));
	}

	function log(bool p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
	}

	function log(bool p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
	}

	function log(bool p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256)", p0, p1, p2));
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
	}

	function log(bool p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
	}

	function log(bool p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
	}

	function log(bool p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256)", p0, p1, p2));
	}

	function log(bool p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
	}

	function log(bool p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
	}

	function log(bool p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool)", p0, p1, p2));
	}

	function log(address p0, uint256 p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address)", p0, p1, p2));
	}

	function log(address p0, string memory p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256)", p0, p1, p2));
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
	}

	function log(address p0, string memory p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
	}

	function log(address p0, string memory p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
	}

	function log(address p0, bool p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256)", p0, p1, p2));
	}

	function log(address p0, bool p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
	}

	function log(address p0, bool p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
	}

	function log(address p0, bool p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
	}

	function log(address p0, address p1, uint256 p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256)", p0, p1, p2));
	}

	function log(address p0, address p1, string memory p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
	}

	function log(address p0, address p1, bool p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
	}

	function log(address p0, address p1, address p2) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,string,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,bool,address,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,string,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,bool,address)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,string)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,bool)", p0, p1, p2, p3));
	}

	function log(uint256 p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(uint256,address,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, uint256 p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,uint256,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, uint256 p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,uint256,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, uint256 p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,uint256)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		_sendLogPayload(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
	}

}