// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
//import "./ImaintenanceToken.sol";
import "../../whitelist/ITokenismWhitelist.sol";
import "../ERC1820/ERC1820Client.sol";
import "@openzeppelin/contracts/utils/Address.sol";
contract maintenanceToken is ERC1820Client{
    string internal constant ERC20_INTERFACE_VALIDATOR = "ERC20Token";
    event mintMT(
            address indexed propertyAddress, 
            address propertyManager
            );
    event transferMT(
            address indexed propertyAddress,
            address newPropertyManager
            );
    event revokeMT(
            address indexed propertyAddress
            );
    mapping(address=>address[]) internal maintenaceTokenOwners;
    ITokenismWhitelist whitelist;
    constructor(ITokenismWhitelist _whitelist){
        whitelist = _whitelist;
    }
     modifier onlyOwner() {
        require(
            whitelist.isOwner(msg.sender),
            "Only owner is allowed"
        );
        _;
    }
    function mintMaintenaceToken(address propertyAddress,address propertyManager) 
      public onlyOwner returns (bool){
        require(Address.isContract(propertyAddress),"Not valid contract address");
        require(interfaceAddr(propertyAddress,ERC20_INTERFACE_VALIDATOR) != address(0),"Not a valid Security Token address");
         for(uint256 i;i<maintenaceTokenOwners[propertyAddress].length;i++){
            require(maintenaceTokenOwners[propertyAddress][i] != propertyManager,"Maintenance token is already minted to the property manager");
         }
        // require(maintenaceTokenOwners[propertyAddress] == address(0),"Token already minted");
        require(whitelist.isWhitelistedUser(propertyManager) == 200,"Property Manager is not whitelisted");
        maintenaceTokenOwners[propertyAddress].push(propertyManager);
        emit mintMT(propertyAddress,propertyManager);
        return true;
    }
    
    function getPropertyManagers(address propertyAddress) public view returns (address[] memory){
        require(Address.isContract(propertyAddress),"Not valid contract address");
        require(interfaceAddr(propertyAddress,ERC20_INTERFACE_VALIDATOR) != address(0),"Not a valid Security Token address");
        //require(maintenaceTokenOwners[propertyAddress] != address(0),"Maintenance token of the property is not minted");
        return maintenaceTokenOwners[propertyAddress];
    }
    function checkPropertyManagerForProperty(address propertyAddress,address propertyManager) public view returns (bool){
        require(Address.isContract(propertyAddress),"Not valid contract address");
        require(interfaceAddr(propertyAddress,ERC20_INTERFACE_VALIDATOR) != address(0),"Not a valid Security Token address");
        for(uint256 i;i<maintenaceTokenOwners[propertyAddress].length;i++){
            if(maintenaceTokenOwners[propertyAddress][i] == propertyManager)
            { 
                return true;
            }
        }
        return false;
    }
    function transferMaintenanceToken(address propertyAddress,address oldPropertyManager,address newPropertyManager) public
     onlyOwner
      returns(bool)
      {
        require(Address.isContract(propertyAddress),"Not valid contract address");
        require(interfaceAddr(propertyAddress,ERC20_INTERFACE_VALIDATOR) != address(0),"Not a valid Security Token address");
        require(checkPropertyManagerForProperty(propertyAddress, newPropertyManager) == false, "Alredy a Property Manager");
        //require(maintenaceTokenOwners[propertyAddress] != address(0),"This Maintenance token of the property is not minted to any Property Manager");
        require(whitelist.isWhitelistedUser(newPropertyManager) == 200,"Property Manager is not whitelisted");
        for(uint256 i;i<maintenaceTokenOwners[propertyAddress].length;i++){
            if(maintenaceTokenOwners[propertyAddress][i] == oldPropertyManager)
            {
                maintenaceTokenOwners[propertyAddress][i] = newPropertyManager;
                emit transferMT(propertyAddress, newPropertyManager);
            return true;
            }
        }
        
        return false;
    }
     function revokeMaintenanceTokenFromPropertyManager(address propertyAddress, address propertyManager) public onlyOwner returns (bool){
        require(Address.isContract(propertyAddress),"Not valid contract address");
        require(interfaceAddr(propertyAddress,ERC20_INTERFACE_VALIDATOR) != address(0),"Not a valid Security Token address");
        require(checkPropertyManagerForProperty(propertyAddress, propertyManager) == true, "No property manager found");
        //require(maintenaceTokenOwners[propertyAddress] != address(0),"This Maintenance token of the property is not minted to any Property Manager");
         for(uint256 i;i<maintenaceTokenOwners[propertyAddress].length;i++){
            if(maintenaceTokenOwners[propertyAddress][i] == propertyManager)
            {   
                maintenaceTokenOwners[propertyAddress][i] = maintenaceTokenOwners[propertyAddress][maintenaceTokenOwners[propertyAddress].length - 1];
                maintenaceTokenOwners[propertyAddress].pop();
                 emit revokeMT(propertyAddress);
            return true;
            }
        }
       
        return false;
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