// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./interfaces/IModules/IWhitelist.sol";
// import "./interfaces/IModules/IGuardian.sol";

// import "./interfaces/IModules/IMultisig.sol";
import "./ModulesManager.sol";
import "./utils/Helper.sol";

// import "./CallManager.sol";

contract Implementation is ModulesManager {
    /// @return flag return true means guardian approval is required , false => approval not required
    function isGuardianApprovalRequired(
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal returns (bool) {
        // cheking if 24 hours passed so that dailyWithdrawal limit can be reset
        if (block.timestamp > timeToTodayLimit) {
            updateTimeAndRestartLimit();
        }
        // checking if whitelist module is enabled and receiver is whitelisted OR
        // withdrawal exceeds daily limit
        if (whitlistModule != address(0x00)) {
            // checking if this call contain a value transfer and to whitelisted address
            bool flag = valueTransferAndWhitelistCheck(_to, _value, _data);
            // means address is not whitelisted and tx requires guardian approval
            if (!flag) {
                // guardian module should be enabled as the transaction requires guardian approval
                require(
                    isGuardianModuleEnabled() != address(0x00),
                    "Enable Guardian Module to perform this transaction"
                );
                submitForGuardianApproval(_to, _value, _data);
                return true;
            }
        }

        if (withdrawedToday + _value > dailyWithdrawLimit) {
            require(
                guardianModule != address(0x00),
                "Enable Guardian Module to perform this transaction"
            );
            submitForGuardianApproval(_to, _value, _data);
            return true;
        }
    }

    // updates time, and reset withdrawal limit when a day passed
    function updateTimeAndRestartLimit() internal {
        timeToTodayLimit = block.timestamp + 24 hours;
        withdrawedToday = 0;
    }

    /// @notice this sumits the transaction to Guardian module for any of the guardian to approve and execute
    function submitForGuardianApproval(
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "submitForGuardianApproval(address,uint256,bytes)",
                _to,
                _value,
                _data
            )
        );
    }

    // checks if a call contains any value transfer or not
    /// @return returns true if address is whitelisted and false when not whitelisted
    function valueTransferAndWhitelistCheck(
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal view returns (bool) {
        // TODO: waiting for Atif bhai reply about check on ETH transfer when
        // smart wallet is interacting with a contract. (need to check data.length)

        // using ternary operator just to skip getToAddress call in case of ether transfer
        address receiver = _value > 0 ? _to : Helper.getToAddress(_to, _data);

        // means there exist token transfer/approval or ETH transfer
        if (_value > 0 || receiver != _to) {
            return isWhitelisted[receiver];
            // require(isWhitelisted[receiver], "Receiver is not whitelisted");
        }
        return true;
    }

    //////////////////////////////////////////////////////////////////////
    /*  Whitelist Module Implmentation */
    ///////////////////////////////////////////////////////////////////////

    /// @notice add tokens/ETH receiver address to whitelist
    /// @dev Calls the standAlone whitelist module and changes state of wallet proxy
    /// @param _newWallet address to whitelist
    function addToWhitelist(address _newWallet) external {
        (bool success, ) = isWhitelistModuleEnabled().delegatecall(
            abi.encodeWithSignature("addToWhitelist(address)", _newWallet)
        );
        // require(success, "Failed to add to whitelist");
    }

    /// @notice removes tokens/ETH receiver address from whitelist
    /// @dev Calls the standAlone whitelist module and changes state of wallet proxy
    /// @param _addressToRemove address to whitelist
    function removeFromWhitelist(address _addressToRemove) external {
        (bool success, ) = isWhitelistModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "removeFromWhitelist(address)",
                _addressToRemove
            )
        );
        // require(success, "Failed to remove from whitelist");
    }

    //////////////////////////////////////////////////////////////////////
    /*  Guardian Module Implmentation */
    ///////////////////////////////////////////////////////////////////////

    function initiateRecovery(address _proposedOwner) external {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature("initiateRecovery(address)", _proposedOwner)
        );
        // require(success, "Failed to initiate recovery");
    }

    function supportRecovery(address _proposedOwner) external {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature("supportRecovery(address)", _proposedOwner)
        );
        // require(success, "Failed to support recovery");
    }

    function cancelRecovery() external {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature("cancelRecovery()")
        );
        // require(success, "Failed to cancel recovery");
    }

    function executeRecovery(
        address _newOwner,
        address[] calldata _guardianList
    ) external {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "executeRecovery(address,address[])",
                _newOwner,
                _guardianList
            )
        );
        // require(success, "Failed to execute recovery");
    }

    function transferGuardianship(address _newGuardianAddress) external {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "transferGuardianship(address)",
                _newGuardianAddress
            )
        );
        // require(success, "Failed to transferGuardianship");
    }

    function initiateGuardianRemoval(address _guardianAddress) external {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "initiateGuardianRemoval(address)",
                _guardianAddress
            )
        );
        // require(success, "Failed to initiateGuardianRemoval");
    }

    function executeGuardianRemoval(
        address _oldGuardianAddress,
        address _newGuardianAddress
    ) external {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "executeGuardianRemoval(address,address)",
                _oldGuardianAddress,
                _newGuardianAddress
            )
        );
        // require(success, "Failed to executeGuardianRemoval");
    }

    function cancelGuardianRemoval(address _guardianAddress) external {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "cancelGuardianRemoval(address)",
                _guardianAddress
            )
        );
        // require(success, "Failed to cancelGuardianRemoval");
    }

    function executeGuardianRequiredTx(uint256 _txId) external {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature("executeGuardianRequiredTx(uint256)", _txId)
        );
    }

    //////////////////////////////////////////////////////////////////////
    /*  Multisig Module Implmentation */
    ///////////////////////////////////////////////////////////////////////
    function addOwner(address _owner) external {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature("addOwner(address)", _owner)
        );
        // require(success, "Failed to addOwner");
    }

    function removeOwner(address _owner) external {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature("removeOwner(address)", _owner)
        );
        // require(success, "Failed to removeOwner");
    }

    function replaceOwner(address _owner, address _newOwner) external {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "replaceOwner(address,address)",
                _owner,
                _newOwner
            )
        );
        // require(success, "Failed to replaceOwner");
    }

    function changeRequirement(uint256 _required) external {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature("changeRequirement(uint256)", _required)
        );
        // require(success, "Failed to changeRequirement");
    }

    function submitTransaction(
        address _destination,
        uint256 _value,
        bytes memory _data
    ) external {
        // checking if transaction requires guardian approval
        // if approval not required, then perform transaction directly
        if (!isGuardianApprovalRequired(_destination, _value, _data)) {
            // valueTransferAndWhitelistCheck(_destination, _value, _data);
            (bool success, ) = isMultisigModuleEnabled().delegatecall(
                abi.encodeWithSignature(
                    "submitTransaction(address,uint256,bytes)",
                    _destination,
                    _value,
                    _data
                )
            );
        }
        // require(success, "Failed to submitTransaction");
    }

    function confirmTransaction(uint256 _transactionId) external {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "confirmTransaction(uint256)",
                _transactionId
            )
        );
        // require(success, "Failed to confirmTransaction");
    }

    function revokeConfirmation(uint256 _transactionId) external {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "revokeConfirmation(uint256)",
                _transactionId
            )
        );
        // require(success, "Failed to revokeConfirmation");
    }

    function executeTransaction(uint256 _transactionId) external {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "executeTransaction(uint256)",
                _transactionId
            )
        );
        // require(success, "Failed to executeTransaction");
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IWhitelist {
    function addToWhitelist(address _newWallet) external;

    function removeFromWhitelist(address _addressToRemove) external;

    function isWhitelisted(address _address) external returns (bool);

    function initWhitelist(address[] memory _whitelistAddresses) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Storage.sol";
import "./Toggle.sol";

contract ModulesManager is Toggle {
    function addOrUpdateWhitelistModule(address _moduleAddress)
        external
        onlyOwner
        whenNotFreezed
    {
        checkForZeroAddress(_moduleAddress);
        // deliberate ignorance to check the module with existing module
        whitlistModule = _moduleAddress;
    }

    function removeWhitelistModule() external onlyOwner whenNotFreezed {
        whitlistModule = address(0x00);
    }

    function initWhitelistModule(address[] memory _whitelistAddresses)
        external
    {
        address wlModule = isWhitelistModuleEnabled();
        (bool success, ) = wlModule.delegatecall(
            abi.encodeWithSignature(
                "initWhitelistModule(address[])",
                _whitelistAddresses
            )
        );
        require(success, "Failed to initWhitelistModule");
    }

    function addOrUpdateMultisigModule(address _moduleAddress)
        external
        onlyOwner
        whenNotFreezed
    {
        checkForZeroAddress(_moduleAddress);
        // deliberate ignorance to check the module with existing module
        multisigModule = _moduleAddress;
    }

    function removeMultisigModule() external onlyOwner whenNotFreezed {
        multisigModule = address(0x00);
    }

    function initMultisigModule(address[] memory _owners, uint256 _required)
        external
    {
        address msModule = isMultisigModuleEnabled();
        (bool success, ) = msModule.delegatecall(
            abi.encodeWithSignature(
                "initMultisigModule(address[],uint256)",
                _owners,
                _required
            )
        );
        require(success, "Failed to MultisigModule");
    }

    function addOrUpdateGuardianModule(address _moduleAddress)
        external
        onlyOwner
        whenNotFreezed
    {
        checkForZeroAddress(_moduleAddress);
        // deliberate ignorance to check the module with existing module
        guardianModule = _moduleAddress;
    }

    function removeGuardianModule() external onlyOwner whenNotFreezed {
        guardianModule = address(0x00);
    }

    function initGuardianModule(
        address[] memory _guardianAddress,
        uint256 _threshold
    ) external {
        address gModule = isGuardianModuleEnabled();
        (bool success, ) = gModule.delegatecall(
            abi.encodeWithSignature(
                "initGuardianModule(address[],uint256)",
                _guardianAddress,
                _threshold
            )
        );
        require(success, "Failed to initGuardian");
    }

    /// TODO : what if multisig module is removed then how we toggle here
    /// @notice to activate or deactivate Multsig support in wallet
    /// @param _flag true: activate multisig, false: deactivate multisig
    function multisigToggle(bool _flag) external onlyOwner whenNotFreezed {
        isMultisigModuleEnabled();
        require(_flag != isMultisigEnabled, "Already in desired State");
        isMultisigEnabled = _flag;
    }

    /// @return returns the address of whitelist module if it was enabled
    function isWhitelistModuleEnabled() public view returns (address) {
        address wlModule = whitlistModule;
        checkForZeroAddress(wlModule);
        // require(wlModule != address(0x00), "Module not enabled");
        return wlModule;
    }

    /// @return returns the address of Guardian module if it was enabled
    function isGuardianModuleEnabled() public view returns (address) {
        address gModule = guardianModule;
        checkForZeroAddress(gModule);
        // require(gModule != address(0x00), "Module not enabled");
        return gModule;
    }

    /// @return returns the address of Multisig module if it was enabled
    function isMultisigModuleEnabled() public view returns (address) {
        address msModule = multisigModule;
        checkForZeroAddress(msModule);
        // require(msModule != address(0x00), "Module not enabled");
        return msModule;
    }

    // TODO: dailywithdrawal limit manage
    function initWallet(address _owner, uint256 _dailyWithdrawLimit) external {
        require(!walletInitialized, "Already initialized");
        walletInitialized = true;
        owner = _owner;
        dailyWithdrawLimit = _dailyWithdrawLimit;
    }

    function checkForZeroAddress(address _addr) internal pure {
        require(_addr != address(0x00), "Zero Address");
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

contract Receiver is IERC721Receiver, IERC1155Receiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
        // return
        //     bytes4(
        //         keccak256("onERC721Received(address,address,uint256,bytes)")
        //     );
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        returns (bool)
    {
        return
            interfaceId == bytes4(keccak256("supportsInterface(bytes4)")) ||
            interfaceId == IERC721Receiver.onERC721Received.selector ||
            interfaceId == IERC1155Receiver.onERC1155Received.selector ||
            interfaceId == IERC1155Receiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Storage {
    /************************************************
     *  Wallet STORAGE
     ***********************************************/

    /// @notice owner of the wallet
    address public owner;

    /// @notice daily withdrawLimit of wallet
    uint256 public dailyWithdrawLimit;
    /// @notice amountWithdrawed in 24 hours
    uint256 public withdrawedToday;
    /// // when 24 hours will be completed (for withdrawal limit)
    uint256 public timeToTodayLimit;

    ///@notice bool to make sure contract is initialized only once
    bool internal walletInitialized;

    /************************************************
     *  Toggle STORAGE
     ***********************************************/

    bool public isAccountFreezed;

    /************************************************
     *  ModuleManager STORAGE
     ***********************************************/

    bool public isMultisigEnabled; // true: multisig is on , false: multisig is off
    address public whitlistModule; // address of whitelistmodule implementation
    address public guardianModule; // address of guardianModule implementation
    address public multisigModule; // address of multisigModule implementation
    // mapping to keep track if wallet uses a module or not
    // mapping(address => bool) public isUsingModule;
    // // to give an address against a module id
    // mapping(uint8 => address) public idToModule;
    // // array to mapp modules, 0=WhitelistModule, 1=MultisigModule, 2=GuardianModule
    // uint8[3] public moduleIds;
    /************************************************
     *  Guardian STORAGE
     ***********************************************/

    /// @notice true if guardian address, else false
    mapping(address => bool) public isGuardian;
    /// @notice keeps track of transactions that requires Guardian approval
    mapping(uint256 => Transaction) public guardianTransactions;
    /// @notice guardian require transaction count
    uint256 public guardianRequiredTxCount;
    //; // TODO: to be removed, just for testing
    // address[] public guardians;

    /// @notice stores the guardian threshold
    uint256 public threshold;

    /// @notice true iff wallet is in recovery mode
    bool public inRecovery;

    /// @notice round of recovery we're in
    uint256 public currRecoveryRound;

    ///@notice bool to make sure contract is initialized only once
    bool internal guardianInitialized;

    /// @notice mapping for bookkeeping when swapping guardians
    mapping(address => uint256) public guardianAddressToRemovalTimestamp;

    /// @notice struct used for bookkeeping during recovery mode
    /// @dev trival struct but can be extended in future (when building for malicious guardians
    /// or when owner key is compromised)
    struct Recovery {
        address proposedOwner;
        uint256 recoveryRound; // recovery round in which this recovery struct was created
        bool usedInExecuteRecovery; // set to true when we see this struct in RecoveryExecute
    }

    /// @notice mapping from guardian address to most recent Recovery struct created by them
    mapping(address => Recovery) public guardianToRecovery;

    /************************************************
     *  Multisig STORAGE
     ***********************************************/

    uint256 public MAX_OWNER_COUNT = 10; // max multisigners

    ///@notice bool to make sure contract is initialized only once
    bool internal multisigInitialized;

    /*
     *  Storage
     */
    mapping(uint256 => Transaction) public transactions;
    mapping(uint256 => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    /************************************************
     *  Whitelist STORAGE
     ***********************************************/

    mapping(address => bool) public isWhitelisted;

    ///@notice bool to make sure contract is initialized only once
    bool internal whitelistInitialized;

    /*************************************************
     ******MODIFIERS******
     **********************************************/

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
    modifier whenNotFreezed() {
        require(!isAccountFreezed, "Account Already Freezed");
        _;
    }
    modifier whenFreezed() {
        require(isAccountFreezed, "Account not Freezed");
        _;
    }

    modifier whenMultisigDisabled() {
        require(
            !isMultisigEnabled,
            "Multisig is enabled, Please use Multisig Module for transactions"
        );
        _;
    }

    modifier whenMultisigEnabled() {
        require(isMultisigEnabled, "Multisig is disabled");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./Storage.sol";

contract Toggle is Storage {
    function freezeAccount() external onlyOwner whenNotFreezed {
        isAccountFreezed = true;
    }

    function unFreezeAccount() external onlyOwner whenFreezed {
        isAccountFreezed = false;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

library Helper {
    // ERC20, ERC721 & ERC1155 transfers & approvals
    bytes4 private constant ERC20_TRANSFER =
        bytes4(keccak256("transfer(address,uint256)"));
    bytes4 private constant ERC20_APPROVE =
        bytes4(keccak256("approve(address,uint256)"));
    bytes4 private constant ERC721_SET_APPROVAL_FOR_ALL =
        bytes4(keccak256("setApprovalForAll(address,bool)"));
    bytes4 private constant ERC721_TRANSFER_FROM =
        bytes4(keccak256("transferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM =
        bytes4(keccak256("safeTransferFrom(address,address,uint256)"));
    bytes4 private constant ERC721_SAFE_TRANSFER_FROM_BYTES =
        bytes4(keccak256("safeTransferFrom(address,address,uint256,bytes)"));
    bytes4 private constant ERC1155_SAFE_TRANSFER_FROM =
        bytes4(
            keccak256("safeTransferFrom(address,address,uint256,uint256,bytes)")
        );

    /**
     * @notice Helper method to recover the spender from a contract call.
     * The method returns the contract unless the call is to a standard method of a ERC20/ERC721/ERC1155 token
     * in which case the spender is recovered from the data.
     * @param _to The target contract.
     * @param _data The data payload.
     */
    function recoverSpender(address _to, bytes memory _data)
        internal
        pure
        returns (address spender)
    {
        if (_data.length >= 68) {
            bytes4 methodId;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                methodId := mload(add(_data, 0x20))
            }
            if (
                methodId == ERC20_TRANSFER ||
                methodId == ERC20_APPROVE ||
                methodId == ERC721_SET_APPROVAL_FOR_ALL
            ) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    spender := mload(add(_data, 0x24))
                }
                return spender;
            }
            if (
                methodId == ERC721_TRANSFER_FROM ||
                methodId == ERC721_SAFE_TRANSFER_FROM ||
                methodId == ERC721_SAFE_TRANSFER_FROM_BYTES ||
                methodId == ERC1155_SAFE_TRANSFER_FROM
            ) {
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    spender := mload(add(_data, 0x44))
                }
                return spender;
            }
        }
        spender = _to;
    }

    /**
     * @notice Helper method to parse data and extract the method signature.
     */
    function functionPrefix(bytes memory _data)
        internal
        pure
        returns (bytes4 prefix)
    {
        require(_data.length >= 4, "Utils: Invalid functionPrefix");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            prefix := mload(add(_data, 0x20))
        }
    }

    /**
     * @notice Checks if an address is a contract.
     * @param _addr The address.
     */
    function isContract(address _addr) internal view returns (bool) {
        uint32 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0) || (msg.sender != tx.origin);
    }

    /**
     * @notice Checks if call leads to any token transfer/approval
     * @param data The data bytes.
     */
    function isTokenTransferInvolved(bytes memory data)
        internal
        pure
        returns (bool)
    {
        bytes4 funcSelector = functionPrefix(data);
        return
            funcSelector == ERC20_TRANSFER ||
            funcSelector == ERC20_APPROVE ||
            funcSelector == ERC721_SET_APPROVAL_FOR_ALL ||
            funcSelector == ERC721_TRANSFER_FROM ||
            funcSelector == ERC721_SAFE_TRANSFER_FROM ||
            funcSelector == ERC721_SAFE_TRANSFER_FROM_BYTES ||
            funcSelector == ERC1155_SAFE_TRANSFER_FROM;
    }

    /**
     * @notice Checks and returns spender address if any token transfer/approval involved
     * @param _data The data bytes.
     * @return address of spender, zero address in case of no token transfer/approval
     */
    function getToAddress(address _to, bytes memory _data)
        internal
        pure
        returns (address)
    {
        if (isTokenTransferInvolved(_data)) {
            return recoverSpender(_to, _data);
        }
        return _to;
    }

    /// @return returns revert message
    function _getRevertMsg(bytes memory returnData)
        internal
        pure
        returns (string memory)
    {
        if (returnData.length < 68)
            return "Wallet: Transaction reverted silently";
        assembly {
            returnData := add(returnData, 0x04)
        }
        return abi.decode(returnData, (string));
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;
import "./Receiver.sol";
// import "./interfaces/IModules/IWhitelist.sol";
import "./Implementation.sol";

contract SmartWallet is Implementation, Receiver {
    // constructor() {}
    receive() external payable {}

    /// @notice to execute a transaction when multisig is disabled
    /// @param _to target address
    /// @param _value amount to transfer if any
    /// @param _data calldata to execute call on target address if any
    function executeTx(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external whenMultisigDisabled whenNotFreezed returns (bytes memory) {
        // checking if transaction requires guardian approval
        // if approval not required, then perform transaction directly
        if (!isGuardianApprovalRequired(_to, _value, _data)) {
            // checking if whitelist module is enabled and user wants to verify receiver in case of value transfer
            // performing the call
            (bool success, bytes memory res) = _to.call{value: _value}(_data);
            if (!success) {
                revert(Helper._getRevertMsg(res));
            }
            return res;
        }
    }
}