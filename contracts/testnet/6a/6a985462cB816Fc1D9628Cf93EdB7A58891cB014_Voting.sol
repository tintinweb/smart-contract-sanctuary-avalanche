// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;
/**
 * @title IAkruNFTAdminWhitelist
 */
interface IAkruNFTWhitelist {
     /**
      * @dev Code of Whitelisting according to there Reverted Reason
      * W1: User is Already Whitelisited
      * W2: Role is not exist or mismatch role that you want to assign with NFTs
      * W3: User-Whitelist: Manager Couldn't Add higher roles
      * W4: Not Specified Role by removing NFT this role is not assign to this user
      * W5: NFT-Whitelist: Accredation Expiry time is before current time
      * W6: Not a Valid User
      * W7: Caller Should be super Admin for renounce Super Admin
      * W8: Admin-Whitelist: Only super admin is allowed
      * W9: Admin-Whitelist: Only super OR Sub-super admins are authorized
      * W10: Admin-Whitelist: Only admin is allowed
      * W11: Admin-Whitelist: Only Manager is allowed
      * W12: Admin-Whitelist: Only Media Manager is allowed
      * W13: Whitelisting: SuperAdmin can not added
      * W14: Length of NFT should be greater than or equal to 2
      * W15: Whitelisting: SuperAdmin Not Removed
      * 
      * superAdmin = 100;
      * subSuperAdmin = 101;
      * admin = 112;
      * manager = 120;
      * mediaManager = 125
      * propertyAccount = 132
      * bank = 130;
      * propertyOwner = 140
      * propertyManager = 135
      * user_USA = 200
      * user_Foreign = 200
      * userWhitelistNumber[ROLES.user_USA] = 200;
      * userWhitelistNumber[ROLES.user_Foreign] = 200;
      * userWhitelistNumber[ROLES.serviceProvider] = 200;
      * userWhitelistNumber[ROLES.subServiceProvider] = 200;
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
        user_Foreign //13
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
    function getRoleInfo(uint256 id)external view returns (uint256 roleId,ROLES roleName,uint256 NFTID,address userAddress,uint256 idPrefix,bool valid);
    function checkUserRole(address userAddress, ROLES role) external view returns (bool);
    function setRoleIdPrefix(ROLES role, uint256 IdPrefix) external;
    function getRoleIdPrefix(ROLES role) external view returns (uint256);
    function addWhitelistUser(address _wallet,bool _kycVerified,bool _accredationVerified,uint256 _accredationExpiry,ROLES role,uint256 NFTId) external;
    function getWhitelistedUser(address _wallet)external view returns (address, bool, bool, uint256, ROLES, uint256, uint256, bool);
    function removeWhitelistedUser(address user, ROLES role) external;
    function updateKycWhitelistedUser(address _wallet,bool _kycVerified) external;
    function updateUserAccredationStatus(address _wallet,bool AccredationStatus) external;
    function updateAccredationWhitelistedUser(address _wallet, uint256 _accredationExpiry) external;
    function updateTaxWhitelistedUser(address _wallet,uint256 _taxWithholding) external;
    function addSymbols(string calldata _symbols) external returns (bool);
    function removeSymbols(string calldata _symbols) external returns (bool);
    function isKYCverfied(address user) external view returns (bool);
    function isAccreditationVerfied(address user) external view returns (bool);
    function isAccredatitationExpired(address user) external view returns (bool);
    function isUserUSA(address user) external view returns (bool);
    function isUserForeign(address user) external view returns (bool);
    function isPremiumUser(address caller) external view returns (bool);
    function getWhitelistInfo(address user)external view returns (bool valid,address wallet,bool kycVerified,bool accredationVerified,uint256 accredationExpiry,uint256 taxWithholding,ROLES role,uint256 userRoleId);
    function getUserRole(address _userAddress) external view returns (string memory, ROLES);
    function closeTokenismWhitelist() external;
    function isWhitelistedUser(address _userAddress) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

/**
 * @title GovernanceToken Interface
 * @dev GovernanceToken logic
 */
interface IGovernanceToken {
    /**
     * GT0: Not valid contract address
     * GT1: Not a valid Security Token address
     * GT2: Only Admin is allowed
     * GT3: Governance Token: Token already minted
     * GT4: Not enough Tokens to burn
  
  */

    /**
     * @dev minting of Governance tokens to the property owner 
     * @param to Address of property owner 
     */
    function mintGovernanceToken(address to) external;
     /**
     * @dev minting of Governance tokens to the property owner 
     * @param _to array of Addressess of property owners
     */
    function bulkMintGovernanceToken(address[] memory _to) external ;
    /**
     * @dev burning of Governance tokens to the property owner 
     * @param account array of Addressess of property owners
     */
    function burnGovernanceToken(address account, uint tokenAmount) external;
    /**
     * @dev transfer of ownership 
     * @param _newOwner new Address of property owners
     * @return success
     */
    function transferOwnership(address payable _newOwner) external returns (bool);
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
     /**
     * @return address of security token
     * @param _owner Address of property owner
     */
    function ownerOfSecuityToken( address _owner) external view returns(address);
    /**
     * @return Governance token Receivers  
     */
    function getTokenReceivers() external view returns(address[] memory);
 
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
     * ST18: Only AKRU user is allowed to send
     * ST19: There is no any Investor to distribute dividends
     * ST20: You did not have this much AKUSD
     * ST21: Not a contract address
     * ST22: Cap is exceeding
  
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
  function setCap(uint256 propertyCap) external;
  /**
     * @dev get basic cap
     * @return calculated cap
     */
  function basicCap() external view returns (uint256);
  /**
     * @dev get all Users with there balance
     * @return  all Users with there balance
     */
//   function getStoredAllData(address adminAddress) external view returns (address[] memory, uint256[] memory);

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

import "@openzeppelin/contracts/utils/Address.sol";
import "./NFTwhitelist/IAkruNFTWhitelist.sol";
import "./token/SecurityToken-US/ERC20/IERC1400RawERC20.sol";
import "./token/GovernanceToken/IGovernanceToken.sol";
/**
 * V01: Not valid contract address
 * V02: You must be an Admin to access this function
 * V03: Only GovernanceToken Holder/Admin is Allowed
 * V04: This Vote Identifcation Number has already been used
 * V05: Voting start date cannot be after the end date
 * V06: End date is before current time
 * V07: Start date is before current time
 * V08: The Default option you are choosing does not exist
 * V09: Atleast two different voting options are required to launch a vote
 * V10: Only Investors within this property are allowed to cast votes
 * V11: Invester KYC is not verified
 * V12: This vote has been suspended/does not exist
 * V13: This Vote has closed
 * V14: This Vote has not opened yet
 * V15: You are voting for an option that does not exist
 * V16: You have already cast your Vote
 * V17: No Vote exists against this ID or the vote has been suspended
 * V18: The vote has already been finalized
 * V19: New end date cannot be the same as the old one
 * V20: New start date cannot be the same as the old one
 * V21: Cannot change start date for a vote that has already begun
 * V22: The new start date for the vote cannot be after the end date
 * V23: Cannot change end date for a vote that has already ended
 * V24: Cannot update default option if vote is finalized
 * V25: Cannot update default option for vote that has ended
 * V26: New default option is the same as the current one
 * V27: Selected default option does not exist
 * V28: Only vote creator or admin can finalize a vote
 * V29: The vote has not reached its end date and time yet
 * V30: Vote has already been Finalized
 */
/**
 * @title Voting
 * @dev Voting logic
 */
contract Voting {
    IERC1400RawERC20 propertyToken;
    // IERC1400RawERC20 propertyTokenNonUs;
    IAkruNFTWhitelist whitelist;
    IGovernanceToken governanceToken;
    struct VoteInfo {
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
        address voteCreator;
    }

    struct VoteCount {
        uint256 option;
        uint256 weight;
        bool hasVoted;
    }

    mapping(uint256 => VoteInfo) public voteInfo;

    mapping(uint256 => mapping(address => VoteCount)) public voteCounts;

    event CastVote(address caller,uint256 voteId, uint256 option,uint256 voteWeight, address propertyToken);
    event CreateVote(address caller, uint256 voteId,string voteTopic,string[] options,uint256 startDate,uint256 endDate,uint256 defaultOption );
    event SuspendVote(address caller, uint256 voteId,bool isActive);
    event UpdateStartDate(address caller, uint256 voteId,uint256 newStartDate);

/**
 * @dev Deploy Contract Constructor
 *  _propertyToken
 */
    constructor(
        IERC1400RawERC20 _propertyToken,
        IAkruNFTWhitelist _whitelist,
        IGovernanceToken _governanceToken
    ) {
        require(
            Address.isContract(address(_propertyToken)),
            "V01"
        );
        require(
            Address.isContract(address(_whitelist)),
            "V01s"
        );
        require(
            Address.isContract(address(_governanceToken)),
            "V01"
        );
        propertyToken = _propertyToken;
        whitelist = _whitelist;
        governanceToken = _governanceToken;
    }
    modifier onlyGovernanceTokenHolderOrAdmin(address _propertyOwner) {
        _onlyGovernanceTokenHolder(_propertyOwner);
        _;
    }
    modifier onlyAdmin() {
        require(
            whitelist.isWhitelistedUser(msg.sender) < 113,
            "V02"
        );
        _;
    }
    function _onlyGovernanceTokenHolder(address _propertyOwner) internal view {
        require(
            governanceToken.balanceOf(_propertyOwner) > 0 ||
                (whitelist.isWhitelistedUser(msg.sender) < 113),
            "V03"
        );
    }
    function getWhitelistAddress() public view onlyAdmin returns (address) {
        return address(whitelist);
    }

    /**
     * @dev to create a proposal of the property
     * @param voteId a unique vote ID to initialize the proposal
     * @param voteTopic a string representing the topic to create the proposal
     * @param options option to vote
     * @param startDate a time when vote process started
     * @param endDate a time when vote process ended
     * @param defaultOption a default option if voter does not cast the vote
     */
    function createVote(
        uint256 voteId,
        string memory voteTopic,
        string[] memory options,
        uint256 startDate,
        uint256 endDate,
        uint256 defaultOption
     ) public onlyGovernanceTokenHolderOrAdmin(msg.sender) {
        require(
            !voteInfo[voteId].isActive,
            "V04"
        );
        require(
            startDate < endDate,
            "V05"
        );
        require(endDate > block.timestamp, "V06");
        require(
            startDate > block.timestamp,
            "V07"
        );
        require(
            (defaultOption < options.length && defaultOption >= 0),
            "V08"
        );
        require(options.length >= 2,"V09");
        VoteInfo storage voteInformation = voteInfo[voteId];
        voteInformation.isActive = true;
        voteInformation.options = options;
        voteInformation.startDate = startDate;
        voteInformation.endDate = endDate;
        voteInformation.voteTopic = voteTopic;
        voteInformation.voteCreator = msg.sender;
        voteInformation.numOfOptions = options.length;
        voteInformation.defaultOption = defaultOption;
        emit CreateVote(msg.sender, voteId,voteTopic,options,startDate,endDate,defaultOption );
    }

    /**
     * @dev to cast the vote in the property
     * @param voteId a unique vote ID to initialize the proposal
     * @param option option to vote
     */
    function castVote(uint256 voteId, uint256 option) public {
        VoteInfo storage voteInformation = voteInfo[voteId];
        VoteCount storage votersInfo = voteCounts[voteId][msg.sender];
        uint256 voteWeight = propertyToken.balanceOf(msg.sender);
        require(
            whitelist.isWhitelistedUser(msg.sender) < 202,
            "V10"
        );
        require(voteWeight > 0, "V11");
        require(
            voteInformation.isActive,
            "V12"
        );
        require(
            voteInformation.endDate > block.timestamp,
            "V13"
        );
        require(
            voteInformation.startDate < block.timestamp,
            "V14"
        );
        require(
            (voteInformation.numOfOptions > option && option >= 0),
            "V15"
        );
        require(!votersInfo.hasVoted, "V16");
        votersInfo.hasVoted = true;
        votersInfo.weight = voteWeight;
        votersInfo.option = option;
        voteInformation.votedUsers.push(msg.sender);
        voteInformation.totalVotes += voteWeight;
        emit CastVote(msg.sender, voteId,option, voteWeight, address(propertyToken));
    }

    /**
     * @dev to suspend a proposal of the property
     * @param voteId a unique vote ID to initialize the proposal
     */
    function suspendVoteToggle(uint256 voteId) public onlyAdmin {
        if(voteInfo[voteId].isActive){
            voteInfo[voteId].isActive = false;  
        }else{
            voteInfo[voteId].isActive = false;  
        }
        emit SuspendVote(msg.sender, voteId,voteInfo[voteId].isActive );
            }
    /**
     * @dev to get the vote topic details
     * @param voteId a unique vote ID to initialize the proposal
     * @return _voteTopic 
     */
    function getVoteTopic(uint256 voteId)
        public
        view
        returns (string memory _voteTopic)
    {
        require(
            voteInfo[voteId].isActive,
            "V17"
        );
        _voteTopic = voteInfo[voteId].voteTopic;
    }

    /**
     * @dev  update Start Date of the vote
     * @param voteId a unique vote ID to initialize the proposal
     * @param newStartDate new start date of the vote
     */
    function updateStartDate(
        uint256 voteId,
        uint256 newStartDate
    ) public onlyAdmin {
        VoteInfo storage voteInformation = voteInfo[voteId];
        require(
            !voteInformation.voteFinalized,
            "V18"
        );
        require(
            voteInformation.isActive,
            "V17"
        );
        require(
            (voteInformation.startDate != newStartDate),
            "V20"
        );
        require(
            block.timestamp < voteInformation.startDate,
            "V21"
        );
        require(
            voteInformation.endDate > newStartDate,
            "V22"
        );

        voteInformation.startDate = newStartDate;
        emit UpdateStartDate(msg.sender, voteId, newStartDate);
    }

    /**
     * @dev  update Start Date of the vote
     * @param voteId a unique vote ID to initialize the proposal
     * @param newEndDate new end date of the vote
     */
    function updateEndDate(
        uint256 voteId,
        uint256 newEndDate
    ) public onlyGovernanceTokenHolderOrAdmin(msg.sender) {
        VoteInfo storage voteInformation = voteInfo[voteId];
        require(
            (voteInformation.voteFinalized == false),
            "V18"
        );
        require(
            (voteInformation.isActive == true),
            "V17"
        );
        require(
            (voteInformation.endDate != newEndDate),
            "V19"
        );
        require(
            block.timestamp < voteInformation.endDate,
            "V23"
        );
        voteInformation.endDate = newEndDate;
    }

    /**
     * @dev update whitelist contract
     * @param newWhitelistAddress new whitelist address
     */
    function updateWhitelistContract(
        address newWhitelistAddress
    ) public onlyAdmin {
        whitelist = IAkruNFTWhitelist(newWhitelistAddress);
    }

    /**
     * @dev update default option of the vote
     * @param voteId a unique vote ID to initialize the proposal
     * @param newDefaultOption new end date of the vote
     */
    function updateDefaultOption(
        uint256 voteId,
        uint256 newDefaultOption
    ) public onlyGovernanceTokenHolderOrAdmin(msg.sender) {
        VoteInfo storage voteInformation = voteInfo[voteId];
        require(
            voteInformation.isActive,
            "V17"
        );
        require(
            !voteInformation.voteFinalized,
            "V24"
        );
        require(
            block.timestamp < voteInformation.endDate,
            "V25"
        );

        require(
            voteInformation.defaultOption != newDefaultOption,
            "V26"
        );
        require(voteInformation.numOfOptions > newDefaultOption,"V27");

        voteInformation.defaultOption = newDefaultOption;
    }
      /**
     * @dev getVoteCount
     * @return _totalVotes total vote count
     * @param voteId a unique vote ID to initialize the proposal
     */
    function getVoteCount(
        uint256 voteId
    )
        public
        view
        onlyGovernanceTokenHolderOrAdmin(msg.sender)
        returns (uint256 _totalVotes)
    {
        require(
            voteInfo[voteId].isActive == true,
            "V17"
        );
        _totalVotes = voteInfo[voteId].totalVotes;
    }
     /**
     * @dev getCurrentVotersList
     * @return _votedUsers total vote count
     * @param voteId a unique vote ID to initialize the proposal
     */
    function getCurrentVotersList(
        uint256 voteId
    )
        public
        view
        onlyGovernanceTokenHolderOrAdmin(msg.sender)
        returns (address[] memory _votedUsers)
    {
        VoteInfo memory voteInformation = voteInfo[voteId];
        require(
            voteInformation.isActive,
            "V17"
        );

        _votedUsers = voteInformation.votedUsers;
    }

    /**
     * @return _voteTopic total vote count
     * @return _options total vote count
     * @return _totaledVoteCounts total vote count
     * @param voteId a unique vote ID to initialize the proposal
     */
    function getVoteTally(
        uint256 voteId
    )
        public
        view
        onlyGovernanceTokenHolderOrAdmin(msg.sender)
        returns (
            string memory _voteTopic,
            string[] memory _options,
            uint256[] memory
        )
    {
        VoteInfo memory voteInformation = voteInfo[voteId];
        require(
            voteInformation.isActive,
            "V17"
        );
        //array of addresses for people that have cast their vote
        address[] memory votedUserList = voteInformation.votedUsers;
        _options = voteInformation.options;
        _voteTopic = voteInformation.voteTopic;

        uint256 i;
        uint256[] memory _totaledVoteCounts = new uint256[](_options.length);
        for (i = 0; i < votedUserList.length; i++) {
            _totaledVoteCounts[
                voteCounts[voteId][votedUserList[i]].option
            ] += voteCounts[voteId][votedUserList[i]].weight;
        }
        return (_voteTopic, _options, _totaledVoteCounts);
    }

    /**
     * @dev finalize the vote
     * @param voteId a unique vote ID to initialize the proposal
     */
    function finalizeVote(uint256 voteId) public {
        VoteInfo storage voteInformation = voteInfo[voteId];
        require(
            voteInformation.voteCreator == msg.sender ||
                whitelist.isWhitelistedUser(msg.sender) < 113,
            "V28"
        );
        require(
            voteInformation.isActive == true,
            "V17"
        );
        require(
            voteInformation.endDate < block.timestamp,
            "V29"
        );

        require(
            voteInformation.voteFinalized == false,
            "V30"
        );
        voteInformation.voteFinalized = true;

        if (propertyToken.totalSupply() > voteInformation.totalVotes) {
            uint256 unAccountedVotes = propertyToken.totalSupply() -
                voteInformation.totalVotes;
            address propertyTokenAddress = address(propertyToken);
            VoteCount storage votersInfo = voteCounts[voteId][
                propertyTokenAddress
            ];

            votersInfo.hasVoted = true;
            votersInfo.weight = unAccountedVotes;
            votersInfo.option = voteInformation.defaultOption;
            voteInformation.votedUsers.push(propertyTokenAddress);
        }
    }
}