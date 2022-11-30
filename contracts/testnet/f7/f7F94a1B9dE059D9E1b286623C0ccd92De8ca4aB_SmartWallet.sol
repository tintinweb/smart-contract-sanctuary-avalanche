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
import "./owner.sol";

contract CallManager is Owner {
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "./interfaces/IModules/IWhitelist.sol";
import "./interfaces/IModules/IGuardian.sol";

import "./interfaces/IModules/IMultisig.sol";
import "./ModulesManager.sol";
import "./utils/Helper.sol";
import "./CallManager.sol";

contract Implementation is ModulesManager, CallManager {
    // checks if a call contains any value transfer or not
    function valueTransferAndWhitelistCheck(
        address _to,
        uint256 _value,
        bytes memory _data
    ) internal {
        // TODO: waiting for Atif bhai reply about check on ETH transfer when
        // smart wallet is interacting with a contract. (need to check data.length)

        // using ternary operator just to skip getToAddress call in case of ether transfer
        address receiver = _value > 0 ? _to : Helper.getToAddress(_to, _data);

        // means there exist token transfer/approval or ETH transfer
        if (_value > 0 || receiver != _to) {
            require(
                IWhitelist(isWhitelistModuleEnabled()).isWhitelisted(receiver),
                "Receiver is not whitelisted"
            );
        }
    }

    function checkModule(bytes32 _name) internal view returns (address) {
        address moduleAddress = nameToModule[_name];
        require(isUsingModule[moduleAddress], "Module not enabled");
        return moduleAddress;
    }

    //////////////////////////////////////////////////////////////////////
    /*  Whitelist Module Implmentation */
    ///////////////////////////////////////////////////////////////////////

    /// @notice add tokens/ETH receiver address to whitelist
    /// @dev Calls the standAlone whitelist module and changes state of wallet proxy
    /// @param _newWallet address to whitelist
    function addToWhitelist(address _newWallet) external onlyOwner {
        (bool success, ) = isWhitelistModuleEnabled().delegatecall(
            abi.encodeWithSignature("addToWhitelist(address)", _newWallet)
        );
        require(success, "Failed to add to whitelist");
    }

    /// @notice removes tokens/ETH receiver address from whitelist
    /// @dev Calls the standAlone whitelist module and changes state of wallet proxy
    /// @param _addressToRemove address to whitelist
    function removeFromWhitelist(address _addressToRemove) external onlyOwner {
        (bool success, ) = isWhitelistModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "removeFromWhitelist(address)",
                _addressToRemove
            )
        );
        require(success, "Failed to remove from whitelist");
    }

    function initWhitelist(address[] memory _whitelistAddresses) external {
        (bool success, ) = isWhitelistModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "initWhitelist(address[])",
                _whitelistAddresses
            )
        );
        require(success, "Failed to init whitelist");
    }

    /// @return returns the address of whitelist module if it was enabled
    function isWhitelistModuleEnabled() public view returns (address) {
        bytes32 name = keccak256("WhitelistModule");
        return checkModule(name);
    }

    //////////////////////////////////////////////////////////////////////
    /*  Guardian Module Implmentation */
    ///////////////////////////////////////////////////////////////////////

    function initGuardian(
        address[] memory _guardianAddresses,
        uint256 _threshold
    ) external {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "initGuardian(address[],uint256)",
                _guardianAddresses,
                _threshold
            )
        );
        require(success, "Failed to Init the Guardian module");
    }

    function initiateRecovery(address _proposedOwner) external {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature("initiateRecovery(address)", _proposedOwner)
        );
        require(success, "Failed to initiate recovery");
    }

    function supportRecovery(address _proposedOwner) external {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature("supportRecovery(address)", _proposedOwner)
        );
        require(success, "Failed to support recovery");
    }

    function cancelRecovery() external onlyOwner {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature("cancelRecovery()")
        );
        require(success, "Failed to cancel recovery");
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
        require(success, "Failed to execute recovery");
    }

    function transferGuardianship(address _newGuardianAddress) external {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "transferGuardianship(address)",
                _newGuardianAddress
            )
        );
        require(success, "Failed to transferGuardianship");
    }

    function initiateGuardianRemoval(address _guardianAddress)
        external
        onlyOwner
    {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "initiateGuardianRemoval(address)",
                _guardianAddress
            )
        );
        require(success, "Failed to initiateGuardianRemoval");
    }

    function executeGuardianRemoval(
        address _oldGuardianAddress,
        address _newGuardianAddress
    ) external onlyOwner {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "executeGuardianRemoval(address,address)",
                _oldGuardianAddress,
                _newGuardianAddress
            )
        );
        require(success, "Failed to executeGuardianRemoval");
    }

    function cancelGuardianRemoval(address _guardianAddress)
        external
        onlyOwner
    {
        (bool success, ) = isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "cancelGuardianRemoval(address)",
                _guardianAddress
            )
        );
        require(success, "Failed to cancelGuardianRemoval");
    }

    /// @return returns the address of Guardian module if it was enabled
    function isGuardianModuleEnabled() public view returns (address) {
        bytes32 name = keccak256("GuardianModule");
        return checkModule(name);
    }

    function getGuardians() public {
        isGuardianModuleEnabled().delegatecall(
            abi.encodeWithSignature("guardians()")
        );
    }

    //////////////////////////////////////////////////////////////////////
    /*  Multisig Module Implmentation */
    ///////////////////////////////////////////////////////////////////////
    function addOwner(address _owner) external whenMultisigEnabled {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature("addOwner(address)", _owner)
        );
        require(success, "Failed to addOwner");
    }

    function removeOwner(address _owner) external whenMultisigEnabled {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature("removeOwner(address)", _owner)
        );
        require(success, "Failed to removeOwner");
    }

    function replaceOwner(address _owner, address _newOwner)
        external
        whenMultisigEnabled
    {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "replaceOwner(address,address)",
                _owner,
                _newOwner
            )
        );
        require(success, "Failed to replaceOwner");
    }

    function changeRequirement(uint256 _required) external whenMultisigEnabled {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature("changeRequirement(uint256)", _required)
        );
        require(success, "Failed to changeRequirement");
    }

    function submitTransaction(
        address _destination,
        uint256 _value,
        bytes memory _data
    ) external whenMultisigEnabled {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "submitTransaction(address,uint256,bytes)",
                _destination,
                _value,
                _data
            )
        );
        require(success, "Failed to submitTransaction");
    }

    function confirmTransaction(uint256 _transactionId)
        external
        whenMultisigEnabled
    {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "confirmTransaction(uint256)",
                _transactionId
            )
        );
        require(success, "Failed to confirmTransaction");
    }

    function revokeConfirmation(uint256 _transactionId)
        external
        whenMultisigEnabled
    {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "revokeConfirmation(uint256)",
                _transactionId
            )
        );
        require(success, "Failed to revokeConfirmation");
    }

    function executeTransaction(uint256 _transactionId)
        external
        whenMultisigEnabled
    {
        (bool success, ) = isMultisigModuleEnabled().delegatecall(
            abi.encodeWithSignature(
                "executeTransaction(uint256)",
                _transactionId
            )
        );
        require(success, "Failed to executeTransaction");
    }

    /// @return returns the address of Multisig module if it was enabled
    function isMultisigModuleEnabled() public view returns (address) {
        bytes32 name = keccak256("MultisigModule");
        return checkModule(name);
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IGuardian {
    function initiateRecovery(address _proposedOwner) external;

    function supportRecovery(address _proposedOwner) external;

    function cancelRecovery() external;

    function executeRecovery(address newOwner, address[] calldata guardianList)
        external;

    function transferGuardianship(address newGuardianAddress) external;

    function initiateGuardianRemoval(address guardianAddress) external;

    function executeGuardianRemoval(
        address oldGuardianAddress,
        address newGuardianAddress
    ) external;

    function cancelGuardianRemoval(address guardianAddress) external;

    function initGuardian(
        address[] memory _guardianAddresses,
        uint256 _threshold
    ) external;

    function isWListed(address _addr) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

interface IMultisig {
    function addOwner(address owner) external;

    function removeOwner(address owner) external;

    function replaceOwner(address owner, address newOwner) external;

    function changeRequirement(uint256 _required) external;

    function submitTransaction(
        address destination,
        uint256 value,
        bytes memory data
    ) external;

    function confirmTransaction(uint256 transactionId) external;

    function revokeConfirmation(uint256 transactionId) external;

    function executeTransaction(uint256 transactionId) external;

    function isMultisigEnabled() external view returns (bool);
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

contract ModulesManager {
    bool public isMultisigEnabled; // true: multisig is on , false: multisig is off
    // mapping to keep track if wallet uses a module or not
    mapping(address => bool) public isUsingModule;
    // to give an address against a module name
    mapping(bytes32 => address) public nameToModule;

    /// @notice adds a module that wallet is going to use
    /// @param _moduleAddress module to add
    function addModule(address _moduleAddress, bytes32 _moduleName) external {
        require(!isUsingModule[_moduleAddress], "Module already in use");
        isUsingModule[_moduleAddress] = true;
        nameToModule[_moduleName] = _moduleAddress;
    }

    function addGuardianModule(
        address _moduleAddress,
        bytes32 _moduleName,
        address[] memory _guardianAddress,
        uint256 _threshold
    ) external {
        require(!isUsingModule[_moduleAddress], "Module already in use");
        isUsingModule[_moduleAddress] = true;
        nameToModule[_moduleName] = _moduleAddress;
        (bool success, ) = _moduleAddress.delegatecall(
            abi.encodeWithSignature(
                "initGuardian(address[],uint256)",
                _guardianAddress,
                _threshold
            )
        );
        require(success, "Failed to initGuardian");
    }

    /// @notice removes a module that wallet is using
    /// @param _moduleName module to remove
    function removeModule(bytes32 _moduleName) external {
        address _moduleAddress = nameToModule[_moduleName];
        require(isUsingModule[_moduleAddress], "Module not in use");
        isUsingModule[_moduleAddress] = false;
        delete nameToModule[_moduleName];
    }

    function multisigToggle(bool _flag) external {
        require(_flag != isMultisigEnabled, "Already in desired State");
        isMultisigEnabled = _flag;
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

contract Owner {
    ///@notice bool to make sure contract is initialized only once
    bool private initialized;
    // owner of the wallet
    address public owner;

    function initWallet(address _owner) external {
        require(!initialized, "Contract already initialized");
        owner = _owner;
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
import "./interfaces/IModules/IWhitelist.sol";
import "./Implementation.sol";

contract SmartWallet is Implementation, Receiver {
    // constructor() {}
    receive() external payable {}

    fallback() external payable {}

    /// @notice to execute a transaction when multisig is disabled
    /// @param _to target address
    /// @param _value amount to transfer if any
    /// @param _data calldata to execute call on target address if any
    function executeTx(
        address _to,
        uint256 _value,
        bytes memory _data
    ) external whenMultisigDisabled returns (bytes memory) {
        // checking if this call contain a value transfer
        valueTransferAndWhitelistCheck(_to, _value, _data);
        // performing the call
        (bool success, bytes memory res) = _to.call{value: _value}(_data);
        if (!success) {
            revert(Helper._getRevertMsg(res));
        }
        return res;
    }
}