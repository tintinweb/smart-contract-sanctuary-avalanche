/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../ERC1400Raw/ERC1400RawIssuable.sol";
import "../../whitelist/ITokenismWhitelist.sol";
import "../../MarginLoan/IMarginLoan.sol";




/**
 * @title ERC1400RawERC20
 * @dev ERC1400Raw with ERC20 retrocompatibility
 */
contract ERC1400RawERC20 is IERC20, ERC1400RawIssuable {
    string internal constant ERC20_INTERFACE_NAME = "ERC20Token";
    using SafeMath for uint256;
    // ITokenismWhitelist _whitelist;
    uint256 public propertyOwnerReserveDevTokens;
    address[] public propertyOwners;
    address public propertyAccount;
    //uint256 public devToken;
    IMarginLoan _IMarginLoan;
    // Mapping from (tokenHolder, spender) to allowed value.
    mapping(address => mapping(address => uint256)) internal _allowed;

    /**
     * [ERC1400RawERC20 CONSTRUCTOR]
     * @dev Initialize ERC1400RawERC20 and CertificateController parameters + register
     * the contract implementation in ERC1820Registry.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param granularity Granularity of the token.
     * @param controllers Array of initial controllers.
     * @param certificateSigner Address of the off-chain service which signs the
     * conditional ownership certificates required for token transfers, issuance,
     * redemption (Cf. CertificateController.sol).
     * @param certificateActivated If set to 'true', the certificate controller
     * is activated at contract creation.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 granularity,
        address[] memory controllers,
        address certificateSigner,
        bool certificateActivated,
        ITokenismWhitelist whitelist,
        IMarginLoan _IMarginLoan,
        address[] memory _propertyOwners,
        address _propertyAccount,
        uint256 _propertyOwnerReserveDevTokens //in percentage
    )
        
        ERC1400Raw(
            name,
            symbol,
            granularity,
            controllers,
            certificateSigner,
            certificateActivated,
            whitelist,
            _IMarginLoan
        )
    {
        ERC1820Client.setInterfaceImplementation(
            ERC20_INTERFACE_NAME,
            address(this)
        );

        ERC1820Implementer._setInterface(ERC20_INTERFACE_NAME); // For migration
        _whitelist = whitelist;

        //require(_propertOwners != address(0),"property owner address can not be zero");
        uint256 length = _propertyOwners.length;
        for(uint256 i = 0; i < length; ){
             require(_whitelist.isOwner(_propertyOwners[i]),"not a property owner");
              propertyOwners.push(_propertyOwners[i]);
              unchecked {
                i++;
              }
        }
       
        //require(_propertyOwnerReserveDevTokenPercentage > 0 && _propertyOwnerReserveDevTokenPercentage < 100, "Error");
        propertyOwnerReserveDevTokens = _propertyOwnerReserveDevTokens;
       
        propertyAccount = _propertyAccount;
    }

    
    modifier onlyAdmin() override(ERC1400Raw){
        require(
            _whitelist.isAdmin(msg.sender),
            "Only admin is allowed to send"
        );
        _;
    }

    // Only Transfer on Tokenism Plateform
    modifier onlyTokenism(address _sender, address _receiver) override{
        uint256 codeS = _whitelist.isWhitelistedUser(_sender);
        uint256 codeR = _whitelist.isWhitelistedUser(_receiver);
        require(
            (Address.isContract(_sender) && codeS <= 201) ||
                (Address.isContract(_receiver) && codeR <= 201) ||
                codeS < 120 ||
                codeR < 120,
            "StableCoin: Cannot send tokens outside Tokenism"
        );
        _;
    }


    // function setDevTokens(uint256 _devToken) external onlyAdmin{
    //     devToken = _devToken;
    // }

    /**
     * [OVERRIDES ERC1400Raw METHOD]
     * @dev Perform the transfer of tokens.
     * @param operator The address performing the transfer.
     * @param from Token holder.
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer.
     * @param operatorData Information attached to the transfer by the operator (if any).
     */
    function _transferWithData(
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal override{
        ERC1400Raw._transferWithData(
            operator,
            from,
            to,
            value,
            data,
            operatorData
        );
        emit Transfer(from, to, value);
    }

    /**
     * [OVERRIDES ERC1400Raw METHOD]
     * @dev Perform the token redemption.
     * @param operator The address performing the redemption.
     * @param from Token holder whose tokens will be redeemed.
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption.
     * @param operatorData Information attached to the redemption by the operator (if any).
     */
    function _redeem(
        address operator,
        address from,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal override{
        ERC1400Raw._redeem(operator, from, value, data, operatorData);

        emit Transfer(from, address(0), value); // ERC20 backwards compatibility
    }


    /**
    * [OVERRIDES ERC1400Raw totalSupply ] 
     */
     function totalSupply() public override(ERC1400Raw , IERC20) view returns (uint256){
         return ERC1400Raw.totalSupply();
     } 

     /**
    * [OVERRIDES ERC1400Raw totalSupply ] 
     */
     function balanceOf(address account) public override(ERC1400Raw , IERC20) view returns (uint256){
         return ERC1400Raw.balanceOf(account);
     } 

    /**
     * [OVERRIDES ERC1400Raw METHOD]
     * @dev Perform the issuance of tokens.
     * @param operator Address which triggered the issuance.
     * @param to Token recipient.
     * @param value Number of tokens issued.
     * @param data Information attached to the issuance.
     * @param operatorData Information attached to the issued by the operator (if any).
     */
    function _issue(
        address operator,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal override{
        ERC1400Raw._issue(operator, to, value, data, operatorData);

        emit Transfer(address(0), to, value); // ERC20 backwards compatibility
    }

    /**
     * [OVERRIDES ERC1400Raw METHOD]
     * @dev Get the number of decimals of the token.
     * @return The number of decimals of the token. For Backwards compatibility, decimals are forced to 18 in ERC1400Raw.
     */
    function decimals() external pure returns (uint8) {
        return 0;
    }

    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowed[owner][spender];
    }

    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of 'msg.sender'.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     * @return A boolean that indicates if the operation was successful.
     */
    function approve(address spender, uint256 value) external override returns (bool) {
        require(spender != address(0), "A5"); // Approval Blocked - Spender not eligible
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Transfer token for a specified address.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transfer(address to, uint256 value)
        external
        override
        onlyTokenism(msg.sender, to)
        returns (bool)
    {
        _callPreTransferHooks("", msg.sender, msg.sender, to, value, "", "");

        _transferWithData(msg.sender, msg.sender, to, value, "", "");

        _callPostTransferHooks("", msg.sender, msg.sender, to, value, "", "");
        // ERC1400Raw.updateFromExchange(from , value);

        return true;
    }

    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Transfer tokens from one address to another.
     * @param from The address which you want to transfer tokens from.
     * @param to The address which you want to transfer to.
     * @param value The amount of tokens to be transferred.
     * @return A boolean that indicates if the operation was successful.
     */
    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external override onlyTokenism(msg.sender, to) returns (bool) {
        require(
            _isOperator(msg.sender, from) ||
                (value <= _allowed[from][msg.sender]),
            "A7"
        ); // Transfer Blocked - Identity restriction

        if (_allowed[from][msg.sender] >= value) {
            _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        } else {
            _allowed[from][msg.sender] = 0;
        }

        _callPreTransferHooks("", msg.sender, from, to, value, "", "");

        _transferWithData(msg.sender, from, to, value, "", "");

        _callPostTransferHooks("", msg.sender, from, to, value, "", "");
        // addFromExchange(from , value);
        return true;
    }

    /************************** ERC1400RawERC20 OPTIONAL FUNCTIONS *******************************/

    /**
     * [NOT MANDATORY FOR ERC1400RawERC20 STANDARD]
     * @dev Set validator contract address.
     * The validator contract needs to verify "ERC1400TokensValidator" interface.
     * Once setup, the validator will be called everytime a transfer is executed.
     * @param validatorAddress Address of the validator contract.
     * @param interfaceLabel Interface label of hook contract.
     */
    function setHookContract(
        address validatorAddress,
        string calldata interfaceLabel
    ) external onlyAdmin {
        ERC1400Raw._setHookContract(validatorAddress, interfaceLabel);
    }

    /************************** REQUIRED FOR MIGRATION FEATURE *******************************/

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
    function migrate(address newContractAddress, bool definitive)
        external
        onlyAdmin
    {
        ERC1820Client.setInterfaceImplementation(
            ERC20_INTERFACE_NAME,
            newContractAddress
        );
        if (definitive) {
            _migrated = true;
        }
    }

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
   function addFromExchange(address _investor, uint256 _balance) public returns(bool) {
        return ERC1400Raw.addFromExchangeRaw1400(_investor , _balance);
   }
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
   function updateFromExchange(address _investor, uint256 _balance) public onlyAdmin returns(bool) {
        return ERC1400Raw.updateFromExchangeRaw1400(_investor , _balance);
   }


    function closeERC1400() public {
        //onlyOwner is custom modifier
        require(
            _whitelist.isSuperAdmin(msg.sender),
            "Only SuperAdmin can destroy Contract"
        );

        selfdestruct(payable(msg.sender)); // `admin` is the admin address
    }

     function mintDevsTokensToPropertyOwners(uint256[] memory _tokens,address[] memory _propertyOwners,bytes[] calldata certificates) external onlyAdmin{
        uint256 length = propertyOwners.length;
        require(_tokens.length == _propertyOwners.length, "Property owners must have length equal to the no of tokens");
        require(_propertyOwners.length <= length, "Property owners must be less or equal than the existing owners length");
        uint256 poLength = _propertyOwners.length;

        //  for (uint256 i = 0; i < poLength;) {
        // require(_whitelist.isOwner(_propertyOwners[i]),"Property owner is not in the whitelist");
        // require(isPropertyOwnerExist(_propertyOwners[i]),"Not a property owner of this property");
        //     unchecked {
        //          i++;
        //     }
        // }
        for (uint256 i = 0; i < poLength;) {
             issue(
                _propertyOwners[i], 
                _tokens[i], // Add those tokens as well which are left other than cap
                certificates[i]
            );
            unchecked {
                 i++;
            }
        }
    }

    function isPropertyOwnerExist(address _addr) public view returns(bool isOwnerExist){
        uint256 length = propertyOwners.length;
        for(uint256 i = 0; i < length;){
            if(propertyOwners[i] == _addr)
            {
                isOwnerExist = true;
                break;
            }
        }
        isOwnerExist = false;
        return isOwnerExist;
    }
    // function _Owner()
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
  function addAdmin(address _newAdmin, string memory _role) external;
  function isManager(address _calle)external returns(bool);
  function userType(address _caller) external view returns(bool);

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./Context.sol";


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address payable private  _owner;
    uint8 public ownerCounter;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
        address payable msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address payable ) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    /**
     * @dev Throws if ownership changed more than one times.
     */
    modifier ownerCounterMod() {
        require(ownerCounter <= 1, " owner can't changed more than one time");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = payable(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address payable newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
        ownerCounter = ownerCounter + 1;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor ()  { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract ERC1820Implementer {
  bytes32 constant ERC1820_ACCEPT_MAGIC = keccak256(abi.encodePacked("ERC1820_ACCEPT_MAGIC"));

  mapping(bytes32 => bool) internal _interfaceHashes;

  function canImplementInterfaceForAddress(bytes32 interfaceHash, address /*addr*/) // Comments to avoid compilation warnings for unused variables.
    external
    view
    returns(bytes32)
  {
    if(_interfaceHashes[interfaceHash]) {
      return ERC1820_ACCEPT_MAGIC;
    } else {
      return "";
    }
  }

  function _setInterface(string memory interfaceLabel) internal {
    _interfaceHashes[keccak256(abi.encodePacked(interfaceLabel))] = true;
  }

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


interface ERC1820Registry {
    function setInterfaceImplementer(address _addr, bytes32 _interfaceHash, address _implementer) external;
    function getInterfaceImplementer(address _addr, bytes32 _interfaceHash) external view returns (address);
    function setManager(address _addr, address _newManager) external;
    function getManager(address _addr) external view returns (address);
}


/// Base client to interact with the registry.
contract ERC1820Client {
    ERC1820Registry constant ERC1820REGISTRY = ERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24);

    function setInterfaceImplementation(string memory _interfaceLabel, address _implementation) internal {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        ERC1820REGISTRY.setInterfaceImplementer(address(this), interfaceHash, _implementation);
    }

    function interfaceAddr(address addr, string memory _interfaceLabel) internal view returns(address) {
        bytes32 interfaceHash = keccak256(abi.encodePacked(_interfaceLabel));
        return ERC1820REGISTRY.getInterfaceImplementer(addr, interfaceHash);
    }

    function delegateManagement(address _newManager) internal {
        ERC1820REGISTRY.setManager(address(this), _newManager);
    }
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title IERC1400TokensValidator
 * @dev ERC1400TokensValidator interface
 */
interface IERC1400TokensValidator {

  function canValidate(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external view returns(bool);

  function tokensToValidate(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external;

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title IERC1400TokensSender
 * @dev ERC1400TokensSender interface
 */
interface IERC1400TokensSender {

  function canTransfer(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external view returns(bool);

  function tokensToTransfer(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external;

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title IERC1400TokensRecipient
 * @dev ERC1400TokensRecipient interface
 */
interface IERC1400TokensRecipient {

  function canReceive(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external view returns(bool);

  function tokensReceived(
    bytes4 functionSig,
    bytes32 partition,
    address operator,
    address from,
    address to,
    uint value,
    bytes calldata data,
    bytes calldata operatorData
  ) external;

}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/**
 * @title IERC1400Raw token standard
 * @dev ERC1400Raw interface
 */
interface IERC1400Raw {

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
  function addFromExchangeRaw1400(address investor , uint256 balance) external returns(bool);
  function updateFromExchangeRaw1400(address _investor , uint256 _balance) external returns (bool);

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

}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC1400Raw.sol";
import "@openzeppelin/contracts/utils/Address.sol";


library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev give an account access to this role
     */
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

    /**
     * @dev remove an account's access to this role
     */
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

    /**
     * @dev check if an account has this role
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor ()  {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

// import "./../../utils/Ownable.sol";
/**
 * @title ERC1400RawIssuable
 * @dev ERC1400Raw issuance logic
 */
abstract contract ERC1400RawIssuable is ERC1400Raw, MinterRole {
    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Issue the amout of tokens for the recipient 'to'.
     * @param to Token recipient.
     * @param value Number of tokens issued.
     * @param data Information attached to the issuance, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     * @return A boolean that indicates if the operation was successful.
     */
    function issue(
        address to,
        uint256 value,
        bytes calldata data
    ) public isValidCertificate(data) onlyAdmin returns (bool) {
        
        _issue(msg.sender, to, value, data, "");

        _callPostTransferHooks("", msg.sender, address(0), to, value, data, "");

        return true;
    }
}

// /*
//  * This code has not been reviewed.
//  * Do not use or deploy this code before reviewing it personally first.
//  */
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;



import "../../utils/Ownable.sol";
import "../ERC1820/ERC1820Client.sol";
import "../ERC1820/ERC1820Implementer.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

import "../../whitelist/ITokenismWhitelist.sol";
import "../../CertificateController/CertificateController.sol";
import "../../MarginLoan/IMarginLoan.sol";
import "./IERC1400Raw.sol";
import "./IERC1400TokensSender.sol";
import "./IERC1400TokensValidator.sol";
import "./IERC1400TokensRecipient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./ERC1400Dividends.sol";


/**
 * @title ERC1400Raw
 * @dev ERC1400Raw logic
 */
contract ERC1400Raw is
    IERC1400Raw,
    Ownable,
    ERC1820Client,
    ERC1820Implementer,
    CertificateController,
    ERC1400Dividends
{
    using SafeMath for uint256;

    string internal constant ERC1400_TOKENS_SENDER = "ERC1400TokensSender";
    string
        internal constant ERC1400_TOKENS_VALIDATOR = "ERC1400TokensValidator";
    string
        internal constant ERC1400_TOKENS_RECIPIENT = "ERC1400TokensRecipient";

    string internal _name;
    string internal _symbol;
    uint256 internal _granularity;
    uint256 internal _totalSupply;

    uint256 public _cap; // Set for Investor Cap
    uint8 _capCounter; // Set for Cap Counter
    // ITokenismWhitelist _whitelist;

    // address payable public admin;

    bool internal _migrated;

    // Indicate whether the token can still be controlled by operators or not anymore.
    bool internal _isControllable;

    // Mapping from tokenHolder to balance.
    mapping(address => uint256) internal _balances;

    // Maitain list of all stack holder
    address[] public tokenHolders; //changes by maintaingin user list
    mapping(address => uint8) public isAddressExist;

    // Cap for User investment Basic and Premium User
    uint8 basicPercentage = 20;

    /******************** Mappings related to operator **************************/
    // Mapping from (operator, tokenHolder) to authorized status. [TOKEN-HOLDER-SPECIFIC]
    mapping(address => mapping(address => bool)) internal _authorizedOperator;

    // Array of controllers. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
    address[] internal _controllers;

    // Mapping from operator to controller status. [GLOBAL - NOT TOKEN-HOLDER-SPECIFIC]
    mapping(address => bool) internal _isController;
    /****************************************************************************/

    /**
     * @dev Modifier to make a function callable only when the contract is not migrated.
     */
    modifier whenNotMigrated() {
        require(!_migrated, "A8");
        _;
    }

    /**
     * [ERC1400Raw CONSTRUCTOR]
     * @dev Initialize ERC1400Raw and CertificateController parameters + register
     * the contract implementation in ERC1820Registry.
     * @param name Name of the token.
     * @param symbol Symbol of the token.
     * @param granularity Granularity of the token.
     * @param controllers Array of initial controllers.
     * @param certificateSigner Address of the off-chain service which signs the
     * conditional ownership certificates required for token transfers, issuance,
     * redemption (Cf. CertificateController.sol).
     * @param certificateActivated If set to 'true', the certificate controller
     * is activated at contract creation.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 granularity,
        address[] memory controllers,
        address certificateSigner,
        bool certificateActivated,
        ITokenismWhitelist whitelist,
        IMarginLoan _IMarginLoan
    )
        
        CertificateController(certificateSigner, certificateActivated,whitelist)
        ERC1400Dividends(whitelist , _IMarginLoan , IERC1400Raw(address(this)))
    {
        _whitelist = whitelist;
        require(
            _whitelist.isManager(msg.sender) || whitelist.isAdmin(msg.sender),
            "Only deployed by admin Or manager of Tokenism"
        );
        require(
            whitelist.addSymbols(symbol),
            "Token Already exist with this Name"
        );
        require(granularity >= 1, "Token granularity can not be lower than 1"); // Constructor Blocked - Token granularity can not be lower than 1

        _name = name;
        _symbol = symbol;
        _totalSupply = 0;
        _granularity = granularity;
        // admin = _whitelist.admin();
        _setControllers(controllers);
    }

    modifier onlyAdmin() virtual override(ERC1400Dividends){
        require(_whitelist.isAdmin(msg.sender), "Only admin is allowed");
        _;
    }

    // Only Transfer on Tokenism Plateform
    modifier onlyTokenism(address _sender, address _receiver) virtual{
        uint256 codeS = _whitelist.isWhitelistedUser(_sender);
        uint256 codeR = _whitelist.isWhitelistedUser(_receiver);
        require(
            (Address.isContract(_sender) && codeS <= 201) ||
                (Address.isContract(_receiver) && codeR <= 201) ||
                codeS < 120 ||
                codeR < 120,
            "StableCoin: Cannot send tokens outside Tokenism"
        );
        _;
    }

    modifier onlyAKRUAuthorization (address _sender, address _receiver) virtual{
        uint256 codeS = _whitelist.isWhitelistedUser(_sender);
        uint256 codeR = _whitelist.isWhitelistedUser(_receiver);
        require(
                (codeS < 201 && (codeR < 121 || codeR == 140)), 
            "Security Token: Cannot send tokens outside AKRU"
        );
        _;
    }


    /********************** ERC1400Raw EXTERNAL FUNCTIONS ***************************/

    /**
     * [ERC1400Raw INTERFACE (1/13)]
     * @dev Get the name of the token, e.g., "MyToken".
     * @return Name of the token.
     */
    function name() external override view returns (string memory) {
        return _name;
    }

    /**
     * [ERC1400Raw INTERFACE (2/13)]
     * @dev Get the symbol of the token, e.g., "MYT".
     * @return Symbol of the token.
     */
    function symbol() external override view returns (string memory) {
        return _symbol;
    }

    /**
     * [ERC1400Raw INTERFACE (3/13)]
     * @dev Get the total number of issued tokens.
     * @return Total supply of tokens currently in circulation.
     */
    function totalSupply() public  virtual override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * [ERC1400Raw INTERFACE (4/13)]
     * @dev Get the balance of the account with address 'tokenHolder'.
     * @param tokenHolder Address for which the balance is returned.
     * @return Amount of token held by 'tokenHolder' in the token contract.
     */
    function balanceOf(address tokenHolder)  public virtual override  view returns (uint256) {
        return _balances[tokenHolder];
    }

    /**
     * [ERC1400Raw INTERFACE (5/13)]
     * @dev Get the smallest part of the token that’s not divisible.
     * @return The smallest non-divisible part of the token.
     */
    function granularity() external override view returns (uint256) {
        return _granularity;
    }

    /**
     * [ERC1400Raw INTERFACE (6/13)]
     * @dev Get the list of controllers as defined by the token contract.
     * @return List of addresses of all the controllers.
     */
    function controllers() external view override returns (address[] memory) {
        return _controllers;
    }

    /**
     * [ERC1400Raw INTERFACE (7/13)]
     * @dev Set a third party operator address as an operator of 'msg.sender' to transfer
     * and redeem tokens on its behalf.
     * @param operator Address to set as an operator for 'msg.sender'.
     */
    function authorizeOperator(address operator) onlyAKRUAuthorization(msg.sender, operator) external override {
        require(operator != msg.sender);
        _authorizedOperator[operator][msg.sender] = true;
        emit AuthorizedOperator(operator, msg.sender);
    }

    /**
     * [ERC1400Raw INTERFACE (8/13)]
     * @dev Remove the right of the operator address to be an operator for 'msg.sender'
     * and to transfer and redeem tokens on its behalf.
     * @param operator Address to rescind as an operator for 'msg.sender'.
     */
    function revokeOperator(address operator) onlyAKRUAuthorization(msg.sender, operator) external override {
        require(operator != msg.sender);
        _authorizedOperator[operator][msg.sender] = false;
        emit RevokedOperator(operator, msg.sender);
    }

    /**
     * [ERC1400Raw INTERFACE (9/13)]
     * @dev Indicate whether the operator address is an operator of the tokenHolder address.
     * @param operator Address which may be an operator of tokenHolder.
     * @param tokenHolder Address of a token holder which may have the operator address as an operator.
     * @return 'true' if operator is an operator of 'tokenHolder' and 'false' otherwise.
     */
    function isOperator(address operator, address tokenHolder)
        external
        override
        view
        returns (bool)
    {
        return _isOperator(operator, tokenHolder);
    }

    /**
     * [ERC1400Raw INTERFACE (10/13)]
     * @dev Transfer the amount of tokens from the address 'msg.sender' to the address 'to'.
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
    function transferWithData(
        address to,
        uint256 value,
        bytes calldata data
    ) external onlyTokenism(msg.sender, to) override isValidCertificate(data) {
        //  uint256 balance = balanceOf(to);

        // For adding to address to list
        if (_balances[to].add(value) > basicCap()) {
            // Add User investment Cap
            // string memory userType = _whitelist.userType(to);
            require(
                _whitelist.userType(to),
                "Upgrade Yourself to Premium Account for more Buy"
            );
        }

        _callPreTransferHooks("", msg.sender, msg.sender, to, value, data, "");

        _transferWithData(msg.sender, msg.sender, to, value, data, "");

        _callPostTransferHooks("", msg.sender, msg.sender, to, value, data, "");
    }

    /**
     * [ERC1400Raw INTERFACE (11/13)]
     * @dev Transfer the amount of tokens on behalf of the address 'from' to the address 'to'.
     * @param from Token holder (or 'address(0)' to set from to 'msg.sender').
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer, and intended for the token holder ('from').
     * @param operatorData Information attached to the transfer by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
    function transferFromWithData(
        address from,
        address to,
        uint256 value,
        bytes calldata data,
        bytes calldata operatorData
    ) external onlyTokenism(msg.sender, to) isValidCertificate(operatorData)  override{
        require(_isOperator(msg.sender, from), "A7"); // Transfer Blocked - Identity restriction

        _callPreTransferHooks(
            "",
            msg.sender,
            from,
            to,
            value,
            data,
            operatorData
        );

        _transferWithData(msg.sender, from, to, value, data, operatorData);

        _callPostTransferHooks(
            "",
            msg.sender,
            from,
            to,
            value,
            data,
            operatorData
        );
        addInvestor(to);
    }

    /**
     * [ERC1400Raw INTERFACE (12/13)]
     * @dev Redeem the amount of tokens from the address 'msg.sender'.
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption, by the token holder. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
    function redeem(uint256 value, bytes calldata data)
        external
        override
        onlyTokenism(msg.sender, msg.sender)
        isValidCertificate(data)
    {
        _callPreTransferHooks(
            "",
            msg.sender,
            msg.sender,
            address(0),
            value,
            data,
            ""
        );

        _redeem(msg.sender, msg.sender, value, data, "");
    }

    /**
     * [ERC1400Raw INTERFACE (13/13)]
     * @dev Redeem the amount of tokens on behalf of the address from.
     * @param from Token holder whose tokens will be redeemed (or address(0) to set from to msg.sender).
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption.
     * @param operatorData Information attached to the redemption, by the operator. [CONTAINS THE CONDITIONAL OWNERSHIP CERTIFICATE]
     */
    function redeemFrom(
        address from,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) public override onlyTokenism(msg.sender, from) isValidCertificate(operatorData) {
        // changed to bublic from external because we need to call internally
        require((_isOperator(msg.sender, from) || (_whitelist.isWhitelistedUser(msg.sender) < 102)), "A7"); // Transfer Blocked - Identity restriction

        _callPreTransferHooks(
            "",
            msg.sender,
            from,
            address(0),
            value,
            data,
            operatorData
        );

        _redeem(msg.sender, from, value, data, operatorData);
    }

    /********************** ERC1400Raw INTERNAL FUNCTIONS ***************************/

    /**
     * [INTERNAL]
     * @dev Check if 'value' is multiple of the granularity.
     * @param value The quantity that want's to be checked.
     * @return 'true' if 'value' is a multiple of the granularity.
     */
    function _isMultiple(uint256 value) internal view returns (bool) {
        return (value.div(_granularity).mul(_granularity) == value);
    }

    /**
     * [INTERNAL]
     * @dev Indicate whether the operator address is an operator of the tokenHolder address.
     * @param operator Address which may be an operator of 'tokenHolder'.
     * @param tokenHolder Address of a token holder which may have the 'operator' address as an operator.
     * @return 'true' if 'operator' is an operator of 'tokenHolder' and 'false' otherwise.
     */
    function _isOperator(address operator, address tokenHolder)
        internal
        view
        returns (bool)
    {
        return (operator == tokenHolder ||
            _authorizedOperator[operator][tokenHolder] ||
            (_isControllable && _isController[operator]));
    }

    /**
     * [INTERNAL]
     * @dev Perform the transfer of tokens.
     * @param operator The address performing the transfer.
     * @param from Token holder.
     * @param to Token recipient.
     * @param value Number of tokens to transfer.
     * @param data Information attached to the transfer.
     * @param operatorData Information attached to the transfer by the operator (if any)..
     */
    function _transferWithData(
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal onlyTokenism(msg.sender, to) whenNotMigrated virtual{
        require(_isMultiple(value), "A9"); // Transfer Blocked - Token granularity
        require(to != address(0), "A6"); // Transfer Blocked - Receiver not eligible
        require(_balances[from] >= value, "A4"); // Transfer Blocked - Sender balance insufficient
        uint256 whitelistStatus = _whitelist.isWhitelistedUser(to);
        require(whitelistStatus <= 200, "Whitelisting Failed");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        if (isAddressExist[to] != 1 && !Address.isContract(to)) {
            tokenHolders.push(to);
            isAddressExist[to] = 1;
            addInvestor(to);
        }
        // require(msg.sender == address(this), "Its not contract Address");

        emit TransferWithData(operator, from, to, value, data, operatorData);
    }

    /**
     * [INTERNAL]
     * @dev Perform the token redemption.
     * @param operator The address performing the redemption.
     * @param from Token holder whose tokens will be redeemed.
     * @param value Number of tokens to redeem.
     * @param data Information attached to the redemption.
     * @param operatorData Information attached to the redemption, by the operator (if any).
     */
    function _redeem(
        address operator,
        address from,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal whenNotMigrated virtual  {
        require(_isMultiple(value), "A9"); // Transfer Blocked - Token granularity
        require(from != address(0), "A5"); // Transfer Blocked - Sender not eligible
        require(_balances[from] >= value, "A4"); // Transfer Blocked - Sender balance insufficient

        _balances[from] = _balances[from].sub(value);

        _totalSupply = _totalSupply.sub(value);

        emit Redeemed(operator, from, value, data, operatorData);
    }

    /**
     * [INTERNAL]
     * @dev Check for 'ERC1400TokensSender' hook on the sender + check for 'ERC1400TokensValidator' on the token
     * contract address and call them.
     * @param partition Name of the partition (bytes32 to be left empty for ERC1400Raw transfer).
     * @param operator Address which triggered the balance decrease (through transfer or redemption).
     * @param from Token holder.
     * @param to Token recipient for a transfer and 0x for a redemption.
     * @param value Number of tokens the token holder balance is decreased by.
     * @param data Extra information.
     * @param operatorData Extra information, attached by the operator (if any).
     */
    function _callPreTransferHooks(
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal {
        address senderImplementation;

        senderImplementation = interfaceAddr(from, ERC1400_TOKENS_SENDER);
        if (senderImplementation != address(0)) {
            IERC1400TokensSender(senderImplementation).tokensToTransfer(
                msg.sig,
                partition,
                operator,
                from,
                to,
                value,
                data,
                operatorData
            );
        }

        address validatorImplementation;
        validatorImplementation = interfaceAddr(
            address(this),
            ERC1400_TOKENS_VALIDATOR
        );
        if (validatorImplementation != address(0)) {
            IERC1400TokensValidator(validatorImplementation).tokensToValidate(
                msg.sig,
                partition,
                operator,
                from,
                to,
                value,
                data,
                operatorData
            );
        }
    }

    /**
     * [INTERNAL]
     * @dev Check for 'ERC1400TokensRecipient' hook on the recipient and call it.
     * @param partition Name of the partition (bytes32 to be left empty for ERC1400Raw transfer).
     * @param operator Address which triggered the balance increase (through transfer or issuance).
     * @param from Token holder for a transfer and 0x for an issuance.
     * @param to Token recipient.
     * @param value Number of tokens the recipient balance is increased by.
     * @param data Extra information, intended for the token holder ('from').
     * @param operatorData Extra information attached by the operator (if any).
     */
    function _callPostTransferHooks(
        bytes32 partition,
        address operator,
        address from,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal {
        address recipientImplementation;
        recipientImplementation = interfaceAddr(to, ERC1400_TOKENS_RECIPIENT);

        if (recipientImplementation != address(0)) {
            IERC1400TokensRecipient(recipientImplementation).tokensReceived(
                msg.sig,
                partition,
                operator,
                from,
                to,
                value,
                data,
                operatorData
            );
        }
    }

    /**
     * [INTERNAL]
     * @dev Perform the issuance of tokens.
     * @param operator Address which triggered the issuance.
     * @param to Token recipient.
     * @param value Number of tokens issued.
     * @param data Information attached to the issuance, and intended for the recipient (to).
     * @param operatorData Information attached to the issuance by the operator (if any).
     */
    function _issue(
        address operator,
        address to,
        uint256 value,
        bytes memory data,
        bytes memory operatorData
    ) internal whenNotMigrated virtual {
        require(_isMultiple(value), "A9"); // Transfer Blocked - Token granularity
        require(to != address(0), "A6"); // Transfer Blocked - Receiver not eligible
        uint256 whitelistStatus = _whitelist.isWhitelistedUser(to);

        // For adding to address to list
        if (_balances[to].add(value) > basicCap()) {
            // Add User investment Cap
            require(
                _whitelist.userType(to),
                "Upgrade Yourself to Premium Account for more Buy"
            );
        }
        if (isAddressExist[to] != 1) {
            require(
                tokenHolders.length < 1975,
                "There is no space to new Investor"
            );
            tokenHolders.push(to);
            isAddressExist[to] = 1;
        }
        require(whitelistStatus <= 200, "Whitelisting Failed");
        _totalSupply = _totalSupply.add(value);
        _balances[to] = _balances[to].add(value);
        addInvestor(to);
        emit Issued(operator, to, value, data, operatorData);
    }

    /********************** ERC1400Raw OPTIONAL FUNCTIONS ***************************/

    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Set validator contract address.
     * The validator contract needs to verify "ERC1400TokensValidator" interface.
     * Once setup, the validator will be called everytime a transfer is executed.
     * @param validatorAddress Address of the validator contract.
     * @param interfaceLabel Interface label of hook contract.
     */
    function _setHookContract(
        address validatorAddress,
        string memory interfaceLabel
    ) internal {
        ERC1820Client.setInterfaceImplementation(
            interfaceLabel,
            validatorAddress
        );
    }

    /**
     * [NOT MANDATORY FOR ERC1400Raw STANDARD]
     * @dev Set list of token controllers.
     * @param operators Controller addresses.
     */
    function _setControllers(address[] memory operators) internal {
        for (uint256 i = 0; i < _controllers.length; i++) {
            _isController[_controllers[i]] = false;
        }
        for (uint256 j = 0; j < operators.length; j++) {
            _isController[operators[j]] = true;
        }
        _controllers = operators;
    }

    function changeWhitelist(ITokenismWhitelist whitelist)
        public
        onlyAdmin
        returns (bool)
    {
        _whitelist = whitelist;
        return true;
    }

    function getAllTokenHolders()
        public
        view
        onlyAdmin
        returns (address[] memory)
    {
        return tokenHolders;
    }

    function cap(uint256 propertyCap) public {
        require(
            _capCounter == 0,
            "Only STO deployer set Cap ERC11400 Value and Once a time"
        );
        require(propertyCap > 0, "Cap must be greater than 0");
        _cap = propertyCap;
        _capCounter++;
    }

    function basicCap() public view returns (uint256) {
        return (_cap.mul(basicPercentage).div(100));
    }

    // Retrun all Users with there balance
    function getStoredAllData()
        public
        view
        onlyAdmin
        returns (address[] memory, uint256[] memory)
    {
        uint256 size = tokenHolders.length;
        uint256[] memory balanceOfUsers = new uint256[](size);
        uint256 j;
        for (j = 0; j < size; j++) {
            balanceOfUsers[j] = _balances[tokenHolders[j]];
        }
        return (tokenHolders, balanceOfUsers);
    }
    // to add token for distribution from exchange  
    function addFromExchangeRaw1400(address _investor , uint256 _balance) public  override onlyAdmin returns (bool){
       return addFromExchangeDistribution(_investor, _balance);
    }

    // to update token for distribution from exchange  
    function updateFromExchangeRaw1400(address _investor , uint256 _balance) public override onlyAdmin returns (bool){
      return updateFromExchangeDistribution(_investor, _balance);
    }
    // get whitelisted ERC1400 Address 
    function getERC1400WhitelistAddress() public view returns (address){
       return address(_whitelist);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../../whitelist/ITokenismWhitelist.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "../../MarginLoan/IMarginLoan.sol";
import "./IERC1400Raw.sol";

contract ERC1400Dividends {
    using SafeMath for uint256;
    ITokenismWhitelist _whitelist;
    IMarginLoan _marginLoan;
    IERC1400Raw _IERC1400raw;

    struct Investors {
        bool valid;
    }

    address[]  investors;
    // address[] investorExchnage;
    // mapping(address => investors) exchangDividend;
    mapping(address => Investors) dividends; // Check Dividen
    mapping (address => uint256)  exchangeBalance;

    // Constructor
    constructor(ITokenismWhitelist whitelist, IMarginLoan _IMarginLoan , IERC1400Raw _IERC1400Raw) {
        _whitelist = whitelist;
        _marginLoan = _IMarginLoan;
        _IERC1400raw = _IERC1400Raw;
    }

    // Event Emit when Dividend distribute
    event DstributeDividends(
        address _token,
        address from,
        address to,
        uint256 userDividents,
        string message
    );
    // Only Transfer on Tokenism Plateform
    modifier onlyAdmin() virtual {
        require(_whitelist.isAdmin(msg.sender), "Only admin is allowed");
        _;
    }
    modifier onlyPropertyOwner(){
        require(_whitelist.isOwner(msg.sender) ||  _whitelist.isAdmin(msg.sender), "Only Owner or Admin is allowed to send");
        _;
    }

    function addInvestor(address _investor)
        internal
        onlyAdmin
        returns (bool)
    {
        if (!Address.isContract(_investor)) {
            if (!dividends[_investor].valid) {
                dividends[_investor].valid = true;
                investors.push(_investor);
            } 
        }
        return true;
    }

    function addFromExchangeDistribution(address _investor, uint256 _balance)
        public
        onlyAdmin
        returns (bool)
    {
        if (!Address.isContract(_investor)) {
            exchangeBalance[_investor] = exchangeBalance[_investor].add(_balance);
        }
        return true;
    }

    function updateFromExchangeDistribution(address _investor, uint256 _balance)
        public
        onlyAdmin
        returns (bool)
    {
        if (!Address.isContract(_investor)) {
            exchangeBalance[_investor] = exchangeBalance[_investor].sub(_balance);
        }
        return true;
    }

    // Function add for distribution of Dividends that paticipate in that property
    function distributeDividends(
        address _token,
        uint256 _dividends,
        uint256 totalSupply
    ) public onlyPropertyOwner {
        uint8 i;
        uint8 j;
        uint8 count = 0;
        uint256 userValue;
        require(
            investors.length > 0,
            " There is no any Investor to distribute dividends"
        );
        require(IERC20(_token).balanceOf(msg.sender) >= _dividends , "You did not have this much AKUSD");
        for (i = 0; i < investors.length; i++) {
            count++;
            uint256 value = _IERC1400raw.balanceOf(investors[i]);
             value = value.add(exchangeBalance[investors[i]]); 
          if(value>=1){
                userValue = _dividends.mul(value).div(totalSupply);
                if(userValue >= 1){
                    IERC20(_token).transferFrom(msg.sender, investors[i], userValue); //transferDividends
                    emit DstributeDividends(
                        address(_IERC1400raw), //token Address
                        msg.sender, // from
                        investors[i], //To
                        userValue, //No of amounts
                        "Dividends transfered"
                    );
                }
            }
        }
    }

    function getInvestors() public view returns (address[] memory) {
        return investors;
    }


    function newMarginLoanContract(IMarginLoan _ImarginLoan) public onlyAdmin{
      _marginLoan = _ImarginLoan;
    }

// get all data of dividend module 
function getAllData() public view onlyAdmin returns(address[] memory _investors, uint256[] memory _balances){
    require(
            investors.length > 0,
            " There is no any Investor to distribute dividends"
        );
    uint256[] memory balances = new uint256[](investors.length);
    for (uint8 i = 0; i < investors.length; i++) {
    balances[i] = exchangeBalance[investors[i]];
    }  
    return (investors , balances);        
} 
    // function calculateBankInterest(uint256 principalAmount , uint256 interestRate , uint256 )
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMarginLoan {
    /**
     * LoanStatus : it will have only follwoing three values.
     */
    enum LoanStatus {NOTFOUND, PENDING, ACTIVE, COMPLETE, REJECT, CANCEL}
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
        uint256 id
    );
    event UpdateLoan(address user, uint256 id, LoanStatus status);

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
        uint256 noOfTokens
    ) external;

    /**
     * only user with a rule of bank can approve loan
     */
    function approveLoan(address _user, uint256 _id) external returns (bool);

    /**
     * only user with a rule of bank can reject loan
     */
    function rejectLoan(address _user, uint256 _id) external returns (bool);

    /**
     * this function would return user margin with erc1400 address
     */
    function getLoan(address _user, address tokenAddress)
        external
        view
        returns (uint256);

    /**
     * only user with a rule of bank can approve loan
     */
    function completeLoan(address _user, uint256 _id) external returns (bool);

    /**
     *getLoanStatus: thsi function return loan status of address provided
     */
    function getLoanStatus(address _user, uint256 _id)
        external
        view
        returns (uint256);

    /**
     * only user with a rule of bank can reject loan
     */
    function cancelLoan(uint256 _id) external returns (bool);

    /**
     * get Margin loan record of customer
     */
    function getMarginLoan(address _user, uint256 id)
        external
        view
        returns (
            uint256,
            address,
            address,
            uint256,
            uint256,
            LoanStatus,
            address,
            uint256,
            uint256,
            uint256
        );

    /**
     * get t0tal of margin loan array of address
     */
    function getTotalLoans(address _user) external view returns (uint256);

    /**
     * get total number of  loan on a signle erc1400 token
     */
    //  function getTotalLoanOfToken(address _user , address _token) external view returns(MarginLoan[] memory);

    function getTotalLoanOfToken(address _user, address _token)
        external
        view
        returns (
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );

    function getTotalNoOfTokens(address _user, address _token)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    function updateLoan(
        address user,
        uint256 id,
        uint256 AmountPayed,
        uint256 noOfTokens,
        uint256 caller
    ) external;
}

/*
 * This code has not been reviewed.
 * Do not use or deploy this code before reviewing it personally first.
 */
//  SPDX-License-Identifier: un-licence
pragma solidity ^0.8.0;
import "../whitelist/ITokenismWhitelist.sol";

contract CertificateController {
    // If set to 'true', the certificate control is activated
    bool public _certificateControllerActivated;
    ITokenismWhitelist _iwhitelist;

    // Address used by off-chain controller service to sign certificate
    mapping(address => bool) public _certificateSigners;

    // A nonce used to ensure a certificate can be used only once
    mapping(address => uint256) public checkNonce;

    // event Checked(address sender);


    modifier onlyAKRUAdmin()  {
        require(_iwhitelist.isOwner(msg.sender) ||
          _iwhitelist.isAdmin(msg.sender) ||
          _iwhitelist.isSubSuperAdmin(msg.sender)
          , "Only admin is allowed");
        _;
    }

    constructor(address _certificateSigner, bool activated,ITokenismWhitelist whitelist) {
        _certificateSigners[_certificateSigner] = true;
        _certificateControllerActivated = activated;
        _iwhitelist = whitelist;
    }

    /**
     * @dev Modifier to protect methods with certificate control
     */
    modifier isValidCertificate(bytes memory data) {
        if (_certificateControllerActivated) {
            require(_checkCert(data), "54"); // 0x54	transfers halted (contract paused)

            checkNonce[msg.sender] += 1; // Increment sender check nonce
            //   emit Checked(msg.sender);

        }
        _;
    }


    /**
     * @dev Set signer authorization for operator.
     * @param operator Address to add/remove as a certificate signer.
     * @param authorized 'true' if operator shall be accepted as certificate signer, 'false' if not.
     */
    function setCertificateSigner(address operator, bool authorized) public onlyAKRUAdmin{
        require(operator != address(0)); // Action Blocked - Not a valid address
        _certificateSigners[operator] = authorized;
    }


    /**
     * @dev Activate/disactivate certificate controller.
     * @param activated 'true', if the certificate control shall be activated, 'false' if not.
     */
    function setCertificateControllerActivated(bool activated) public onlyAKRUAdmin{
        _certificateControllerActivated = activated;
    }


    /**
     * @dev Checks if a certificate is correct
     * @param data Certificate to control
     */
    function _checkCert(bytes memory data) internal view returns (bool) {
        uint256 nonce = checkNonce[msg.sender];

        uint256 e;
        bytes32 r;
        bytes32 s;
        uint8 v;

        // Certificate should be 97 or 98 bytes long
        if (data.length != 97 || data.length != 98) {
            return false;
        }

        // Extract certificate information and expiration time from payload
        assembly {
            // Retrieve expirationTime & ECDSA elements from certificate which is a 97 or 98 long bytes
            // Certificate encoding format is: <expirationTime (32 bytes)>@<r (32 bytes)>@<s (32 bytes)>@<v (1 byte)>
            e := mload(add(data, 0x20))
            r := mload(add(data, 0x40))
            s := mload(add(data, 0x60))
            v := byte(0, mload(add(data, 0x80)))
        }

        // Certificate should not be expired
        if (uint256(e) < block.timestamp) {
            return false;
        }

        if (v < 27) {
            v += 27;
        }

        // Perform ecrecover to ensure message information corresponds to certificate
        if (v == 27 || v == 28) {
            // Extract functionId, to address and amount from msg.data
            bytes memory msgData = msg.data;
            bytes4 funcId;
            address to;
            bytes32 amount;

            assembly {
              funcId := mload(add(msgData, 32))
              amount := mload(add(msgData, 68))
              to := mload(add(msgData, 36))
            }
            // Pack and hash
            bytes32 _hash = keccak256(
                abi.encodePacked(address(this),funcId, to, uint256(amount), nonce)
            );

            // compute signer
            address _signer = ecrecover(
                keccak256(
                    abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash)
                ),
                v,
                r,
                s
            );
            // Check if certificate match expected transactions parameters
            if (_certificateSigners[_signer]) {
                return true;
            }
        }
        return false;
    }

    function checkCertificate(bytes memory data) public view returns (bool){
       return  _checkCert(data);
    }

  
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.0;

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