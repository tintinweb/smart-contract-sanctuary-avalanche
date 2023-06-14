/**
 *Submitted for verification at testnet.snowtrace.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

/**
 * Strings Library
 *
 * In summary this is a simple library of string functions which make simple
 * string operations less tedious in solidity.
 *
 * Please be aware these functions can be quite gas heavy so use them only when
 * necessary not to clog the blockchain with expensive transactions.
 *
 * @author James Lockhart <[email protected]>
 */
library Strings {
    /**
     * Concat (High gas cost)
     *
     * Appends two strings together and returns a new value
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string which will be the concatenated
     *              prefix
     * @param _value The value to be the concatenated suffix
     * @return string The resulting string from combinging the base and value
     */
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory)
    {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(
            _baseBytes.length + _valueBytes.length
        );
        bytes memory _newValue = bytes(_tmpValue);

        uint256 i;
        uint256 j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int256)
    {
        return _indexOf(_base, _value, 0);
    }

    /**
     * Index Of
     *
     * Locates and returns the position of a character within a string starting
     * from a defined offset
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string acting as the haystack to be
     *              searched
     * @param _value The needle to search for, at present this is currently
     *               limited to one character
     * @param _offset The starting point to start searching from which can start
     *                from 0, but must not exceed the length of the string
     * @return int The position of the needle starting from 0 and returning -1
     *             in the case of no matches found
     */
    function _indexOf(
        string memory _base,
        string memory _value,
        uint256 _offset
    ) internal pure returns (int256) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint256 i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int256(i);
            }
        }

        return -1;
    }

    /**
     * Length
     *
     * Returns the length of the specified string
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string to be measured
     * @return uint The length of the passed string
     */
    function length(string memory _base) internal pure returns (uint256) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    /**
     * Sub String
     *
     * Extracts the beginning part of a string based on the desired length
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @return string The extracted sub string
     */
    function substring(string memory _base, int256 _length)
        internal
        pure
        returns (string memory)
    {
        return _substring(_base, _length, 0);
    }

    /**
     * Sub String
     *
     * Extracts the part of a string based on the desired length and offset. The
     * offset and length must not exceed the lenth of the base string.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string that will be used for
     *              extracting the sub string from
     * @param _length The length of the sub string to be extracted from the base
     * @param _offset The starting point to extract the sub string from
     * @return string The extracted sub string
     */
    function _substring(
        string memory _base,
        int256 _length,
        int256 _offset
    ) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint256(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint256(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint256 j = 0;
        for (
            uint256 i = uint256(_offset);
            i < uint256(_offset + _length);
            i++
        ) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }

    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr)
    {
        bytes memory _baseBytes = bytes(_base);

        uint256 _offset = 0;
        uint256 _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) break;
            else {
                _splitsCount++;
                _offset = uint256(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {
            int256 _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1) {
                _limit = int256(_baseBytes.length);
            }

            string memory _tmp = new string(uint256(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint256 j = 0;
            for (uint256 i = _offset; i < uint256(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint256(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    /**
     * Compare To
     *
     * Compares the characters of two strings, to ensure that they have an
     * identical footprint
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent
     */
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool)
    {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint256 i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    /**
     * Compare To Ignore Case (High gas cost)
     *
     * Compares the characters of two strings, converting them to the same case
     * where applicable to alphabetic characters to distinguish if the values
     * match.
     *
     * @param _base When being used for a data type this is the extended object
     *               otherwise this is the string base to compare against
     * @param _value The string the base is being compared to
     * @return bool Simply notates if the two string have an equivalent value
     *              discarding case
     */
    function compareToIgnoreCase(string memory _base, string memory _value)
        internal
        pure
        returns (bool)
    {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint256 i = 0; i < _baseBytes.length; i++) {
            if (
                _baseBytes[i] != _valueBytes[i] &&
                _upper(_baseBytes[i]) != _upper(_valueBytes[i])
            ) {
                return false;
            }
        }

        return true;
    }

    /**
     * Upper
     *
     * Converts all the values of a string to their corresponding upper case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to upper case
     * @return string
     */
    function upper(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Lower
     *
     * Converts all the values of a string to their corresponding lower case
     * value.
     *
     * @param _base When being used for a data type this is the extended object
     *              otherwise this is the string base to convert to lower case
     * @return string
     */
    function lower(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    /**
     * Upper
     *
     * Convert an alphabetic character to upper case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to upper case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a lower case otherwise returns the original value
     */
    function _upper(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    /**
     * Lower
     *
     * Convert an alphabetic character to lower case and return the original
     * value when not alphabetic
     *
     * @param _b1 The byte to be converted to lower case
     * @return bytes1 The converted value if the passed value was alphabetic
     *                and in a upper case otherwise returns the original value
     */
    function _lower(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCallWithValue(
                target,
                data,
                0,
                "Address: low-level call failed"
            );
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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
        return
            verifyCallResultFromTarget(
                target,
                success,
                returndata,
                errorMessage
            );
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

    function _revert(bytes memory returndata, string memory errorMessage)
        private
        pure
    {
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

// Address Book Interface
interface AddressBookInterface {
    // Update ERC20 Contract Address
    function updateERC20ContractAddress(
        address ERC20ContractAddress_,
        address executor_
    ) external;

    // Get ERC20 Contract Address
    function getERC20ContractAddress() external view returns (address);

    // Update Admin Multi-Sig Contract Address
    function updateAdminMultiSigConractAddress(
        address AdminMultiSigContractAddress_,
        address executor_
    ) external;

    // Get Admin Multi-Sig Contract Address
    function getAdminMultiSigContractAddress() external view returns (address);

    // Update Supply Management Multi-Sig Contract Address
    function updateSupplyManagementMultiSigConractAddress(
        address SupplyManagementMultiSigContractAddress_,
        address executor_
    ) external;

    // Get Supply Management Multi-Sig Contract Address
    function getSupplyManagementMultiSigContractAddress()
        external
        view
        returns (address);

    // Update Fee Management Contract Address
    function updateFeeManagementConractAddress(
        address FeeManagementContractAddress_,
        address executor_
    ) external;

    // Get Fee Management Contract Address
    function getFeeManagementContractAddress() external view returns (address);

    // Update Fee Management Multi-Sig Contract Address
    function updateFeeManagementMultiSigConractAddress(
        address FeeManagementMultiSigContractAddress_,
        address executor_
    ) external;

    // Get Fee Management Multi-Sig Contract Address
    function getFeeManagementMultiSigContractAddress()
        external
        view
        returns (address);

    // Update Asset Protection Multi-Sig Contract Address
    function updateAssetProtectionMultiSigConractAddress(
        address AssetProtectionMultiSigContractAddress_,
        address executor_
    ) external;

    // Get Asset Protection Multi-Sig Contract Address
    function getAssetProtectionMultiSigContractAddress()
        external
        view
        returns (address);

    // Get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);

    // update KYC Contract Address
    function updateKYCContractAddress(address KYCContractAddress_, address executor_) external;

    // get KYC Contract Address
    function getKYCContractAddress() external view returns (address);

    // update KYC Multi-Sig Contract Address
    function updateKYCMultiSigContractAddress(address KYCMultiSigContractAddress_, address executor_) external;

    // get KYC Multi-Sig Contract Address
    function getKYCMultiSigContractAddress() external view returns(address);
}

// Admin Multi-Sig Interface
interface AdminMultiSigInterface {
    // create Signatory proposal
    function createSignatoryProposal(
        address signatoryAddress_,
        string memory signatoryGroup_,
        string memory updateType_,
        uint256 expiration_
    ) external;

    // approve signatory proposal (adding or removing)
    function approveSignatoryProposal(uint256 adminProposalIndex_) external;

    // revoke signatory proposal (by Admin proposer)
    function revokeSignatoryProposal(uint256 adminProposalIndex_) external;

    // create min singatures requirement proposal
    function createMinSignaturesProposal(
        uint256 minSignatures_,
        string memory signatoryGroup_,
        uint256 expiration_
    ) external;

    // approve min signatures requirement proposal
    function approveMinSignaturesProposal(uint256 adminProposalIndex_) external;

    // revoke min signatures requirement proposal (by Admin proposer)
    function revokeMinSignaturesProposal(uint256 adminProposalIndex_) external;

    // create freeze management proposal
    function createFreezeManagementProposal(
        string memory managementGroup_,
        bool updateStatus_,
        uint256 expiration_
    ) external;

    // approve freeze management proposal
    function approveFreezeManagementProposal(uint256 adminProposalIndex_)
        external;

    // revoke freeze management proposal
    function revokeFreezeManagementProposal(uint256 adminProposalIndex_)
        external;

    // get Address Book Contract Address
    function getAddressBookContractAddress() external view returns (address);

    // get signatories
    function getAdminSignatories() external view returns (address[] memory);

    // is admin signatory
    function IsAdminSignatory(address account_) external view returns (bool);

    // get admin proposal index
    function getAdminProposalIndex() external view returns (uint256);

    // get admin proposal detail
    // function getAdminProposalDetail(uint256 adminProposalIndex_)
    //     external
    //     view
    //     returns (SignatoryProposal memory);

    // is admin proposal approver
    function IsAdminProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) external view returns (bool);

    // get min signature
    function getMinAdminSignatures() external view returns (uint256);

    // get min signature proposal detail
    // function getMinSignatureProposalDetail(uint256 adminProposalIndex_)
    //     public
    //     view
    //     returns (MinSignatureProposal memory);

    // is min signature proposal approver?
    function IsMinSignatureProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) external view returns (bool);

    // get number of admin signatories
    function getNumberOfAdminSignatories() external view returns (uint256);

    // get Freeze Management proposal detail
    // function getFreezeManagementProposalDetail(uint256 adminProposalIndex_)
    //     public
    //     view
    //     returns (FreezeManagementProposal memory);

    // is freeze management proposal approver?
    function IsFreezeManagementProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) external view returns (bool);

    // get global freeze management status
    function getGlobalFreezeManagementStatus() external view returns (bool);

    // get Supply Management Freeze status
    function getSupplyManagementFreezeStatus() external view returns (bool);

    // get Fee Management Freeze status
    function getFeeManagementFreezeStatus() external view returns (bool);

    // get Asset Protection Freeze status
    function getAssetProtectionFreezeStatus() external view returns (bool);

    // get Supply Management Signatories
    function getSupplyManagementSignatories()
        external
        view
        returns (address[] memory);

    // Is Supply Management Signatory
    function IsSupplyManagementSignatory(address account_)
        external
        view
        returns (bool);

    // get Min Signature requirement for Supply Management
    function getSupplyManagementMinSignatures() external view returns (uint256);

    // get Fee Management Signatories
    function getFeeManagementSignatories()
        external
        view
        returns (address[] memory);

    // is Fee Managemetn Signatory
    function IsFeeManagementSignatory(address account_)
        external
        view
        returns (bool);

    // get Fee Management Min Singatures
    function getFeeManagementMinSignatures() external view returns (uint256);

    // get kYC Signatories
    function getKYCSignatories()
        external
        view
        returns (address[] memory);

    // is KYC Signatory
    function IsKYCSignatory(address account_)
        external 
        view
        returns (bool);

    // get KYC Min Signatures
    function getKYCMinSignatures() external view returns (uint256);

    // get Asset Protection Signatories
    function getAssetProtectionSignatories()
        external
        view
        returns (address[] memory);

    // Is Asset Protection Signatory
    function IsAssetProtectionSignatory(address account_)
        external
        view
        returns (bool);

    // get Asset Protection Min Signature requirement
    function getAssetProtectionMinSignatures() external view returns (uint256);
}

// Administrative Multi-Sig
contract AdminMultiSig {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // Address Book Contract Address
    address private _AddressBookContractAddress;

    // Address Book Contract Interface
    AddressBookInterface private _AddressBook;

    ///   Administration Signatories   ///

    // list of admin signatories
    address[] private _adminSignatories;

    // check if an address is a signatory: address => status
    mapping(address => bool) private _isAdminSignatory;

    // administration proposal counter
    uint256 private _adminProposalIndex = 0;

    // Signatory Proposal struct for managing signatories
    struct SignatoryProposal {
        uint256 ID;
        address PROPOSER;
        address MODIFIEDSIGNER;
        string UPDATETYPE; // ADD or REMOVE
        string SIGNATORYGROUP; // ADMIN, FEEMANAGEMENT, SUPPLYMANAGEMENT
        bool ISEXECUTED;
        uint256 EXPIRATION; // expiration timestamp
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // list of signatory proposals info: admin proposal index => signatory proposal detail
    mapping(uint256 => SignatoryProposal) private _signatoryProposals;

    // signatory proposal approvers: admin proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _signatoryProposalApprovers;

    ///   Minimum Signatures   ///

    // minimum admin signatures required for a proposal
    uint256 private _minAdminSignatures;

    // Min Signature Proposal to manage minimum signers
    struct MinSignatureProposal {
        uint256 ID;
        address PROPOSER;
        uint256 MINSIGNATURE;
        string SIGNATORYGROUP; // ADMIN, FEEMANAGEMENT, SUPPLYMANAGEMENT
        bool ISEXECUTED;
        uint256 EXPIRATION;
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // list of min signature proposals info: admin proposal index => min signatures proposal detail
    mapping(uint256 => MinSignatureProposal) private _minSingatureProposal;

    // min signature propolsal approvers: admin proposal index => address => status
    mapping(uint256 => mapping(address => bool)) private _minSignatureApprovers;

    ///   Freeze Managements  ///

    // Freeze Management Proposal struct
    struct FreezeManagementProposal {
        uint256 ID;
        address PROPOSER;
        string MANAGEMENTGROUP;
        bool STATUS;
        bool ISEXECUTED;
        uint256 EXPIRATION;
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // list of freeze management proposal info: admin proposal index => freeze management proposal detail
    mapping(uint256 => FreezeManagementProposal)
        private _freezeManagementProposal;

    // freeze management proposal approvers: admin proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _freezeManagementApprovers;

    // Global freeze Management Acitivities
    bool private _globalFreezeManagementActivities;

    // Freeze Supply Managemetn Activities
    bool private _freezeSupplyManagementActivities;

    // Freeze Fee Management Activitive
    bool private _freezeFeeManagementActivities;

    // Freeze Asset Protection Activities
    bool private _freezeAssetProtectionActivities;

    ///   Supply Management Signatories   ///

    // list of Supply Management Signatories
    address[] private _supplyManagementSignatories;

    // is a Supply Management Signatory
    mapping(address => bool) private _isSupplyManagementSignatory;

    // minimum Supply Management signature requirement
    uint256 private _minSupplyManagementSignatures;

    ///   Fee Management Signatories   ///

    // minimum Fee Management signature requirement
    uint256 private _minFeeManagementSignatures;

    // list of Fee Managment signatories
    address[] private _feeManagementSignatories;

    // is a Fee Management Signatory
    mapping(address => bool) private _isFeeManagementSignatory;

    ///   KYC Signatories   ///

    // list of KYC Signatories
    address[] private _KYCSignatories;

    // is a KYC Signatory
    mapping(address => bool) private _isKYCSignatory;

    // minimum KYC signature requirement
    uint256 private _minKYCSignatures;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    // constructor with initialized admin signatories and min admin signatures
    constructor(uint256 minAdminSignatures_, address[] memory adminSignatories_)
    {
        // require valid initialization
        require(
            minAdminSignatures_ <= adminSignatories_.length,
            "Admin Multi-Sig: Invalid initialization!"
        );

        // set min singatures
        _minAdminSignatures = minAdminSignatures_;

        // add signers
        for (uint256 i = 0; i < adminSignatories_.length; i++) {
            // admin signer
            address signatory = adminSignatories_[i];

            // require non-zero address
            require(
                signatory != address(0),
                "Admin Multi-Sig: Invalid admin signatory address!"
            );

            // require no duplicated signatory
            require(
                !_isAdminSignatory[signatory],
                "Admin Multi-Sig: Duplicate admin signatory address!"
            );

            // add admin signatory
            _adminSignatories.push(signatory);

            // update admin signatory status
            _isAdminSignatory[signatory] = true;

            // emit adding admin signatory event with index 0
            emit SingatoryProposalExecutedEvent(
                msg.sender,
                0,
                signatory,
                "ADD",
                "ADMIN",
                0,
                block.timestamp
            );
        }
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // update Address Book contract address
    event updateAddressBookContractAddressEvent(
        address indexed Admin,
        address previousAddressBookContractAddress,
        address indexed newAddressBookContractAddress,
        uint256 indexed timestamp
    );

    // create signatory proposal
    event SignatoryProposalCreatedEvent(
        address indexed proposer,
        uint256 adminProposalIndex,
        address indexed proposedAdminSignatory,
        string updateType,
        string signatoryGroup,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute signatory proposal
    event SingatoryProposalExecutedEvent(
        address indexed executor,
        uint256 adminProposalIndex,
        address indexed AdminSingatoryAdded,
        string updateType,
        string signatoryGroup,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve signatory proposal
    event ApproveSignatoryProposalEvent(
        address indexed approver,
        uint256 adminProposalIndex,
        address indexed AdminSingatoryAdded,
        string UPDATETYPE,
        string SIGNATORYGROUP,
        uint256 indexed timestamp
    );

    // revoke signatory proposal by proposer
    event revokeSignatoryProposalEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        string updateType,
        string signatoryGroup,
        uint256 indexed timestamp
    );

    // creatw min signature proposal
    event MinSignaturesProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        uint256 proposedMinSignatures,
        string signatoryGroup_,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute min signatures proposal
    event MinSignaturesProposalExecutedEvent(
        address indexed executor,
        uint256 indexed adminProposalIndex,
        uint256 previousMinAdminSignatures,
        uint256 newMinSignatures_,
        string signatoryGroup_,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve min signature proposal
    event ApproveMinSignaturesProposalEvent(
        address indexed approver,
        uint256 indexed adminProposalIndex,
        uint256 MINSIGNATURE,
        string SIGNATORYGROUP,
        uint256 indexed timestamp
    );

    // revoke min signatures proposal by proposer
    event revokeMinSignaturesProposalEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        uint256 minSignature,
        string signatoryGroup,
        uint256 indexed timestamp
    );

    // create freeze management proposal
    event FreezeManagementProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        string managementGroup,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute freeze management proposal
    event FreezeManagementProposalExecutedEvent(
        address indexed executor,
        uint256 indexed adminProposalIndex,
        bool previousFreezeStatus,
        bool newFreezeStatus,
        string managementGroup,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve freeze management proposal
    event ApproveFreezeManagementProposalEvent(
        address indexed approver,
        uint256 indexed adminProposalIndex,
        string MANAGEMENTGROUP,
        bool STATUS,
        uint256 indexed timestamp
    );

    // revoke freeze management proposal
    event revokeFreezeManagementProposalEvent(
        address indexed proposer,
        uint256 indexed adminProposalIndex,
        string MANAGEMENTGROUP,
        bool STATUS,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Admin signatories
    modifier onlyAdmins() {
        // require msg.sender be an admin signatory
        _onlyAdmins();
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        _notNullAddress(account_);
        _;
    }

    // only valid adminProposalIndex
    modifier onlyValidAdminProposalIndex(uint256 adminProposalIndex_) {
        // require a valid admin proposal index ( != 0 and not more than max)
        _onlyValidAdminProposalIndex(adminProposalIndex_);
        _;
    }

    // only valid signatory group
    modifier onlyValidGroup(string memory signatoryGroup_) {
        // require valid signatory group
        _onlyValidGroup(signatoryGroup_);
        _;
    }

    // only valid signatory update type
    modifier onlyValidUpdateType(string memory updateType_) {
        // require valid update type
        _onlyValidUpdateType(updateType_);
        _;
    }

    // greater than zero value
    modifier onlyGreaterThanZero(uint256 value_) {
        // require value be greater than zero
        _onlyGreaterThanZero(value_);
        _;
    }

    // only proposer
    modifier onlyProposer(uint256 adminProposalIndex_) {
        // require sender be the proposer of the proposal
        _onlyProposer(adminProposalIndex_);
        _;
    }

    // only valid management groups for freezing
    modifier onlyValidManagementGroups(string memory signatoryGroup_) {
        // require valid signatory group
        _onlyValidManagementGroups(signatoryGroup_);
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) public notNullAddress(AddressBookContractAddress_) {
        // require sender be admin multisig (address(this))
        require(msg.sender == address(this), "Sender is not the admin!");

        // previous Address Book Contract Address
        address previousAddressBookContractAddress = _AddressBookContractAddress;

        // update Address Book Contract Address
        _AddressBookContractAddress = AddressBookContractAddress_;

        // update Address Book Contract Interface
        _AddressBook = AddressBookInterface(AddressBookContractAddress_);

        // emit event
        emit updateAddressBookContractAddressEvent(
            msg.sender,
            previousAddressBookContractAddress,
            AddressBookContractAddress_,
            block.timestamp
        );
    }

    ///   Signatory Proposal   ///

    // create Signatory proposal
    function createSignatoryProposal(
        address signatoryAddress_,
        string memory signatoryGroup_,
        string memory updateType_,
        uint256 expiration_
    )
        public
        onlyAdmins
        notNullAddress(signatoryAddress_)
        onlyValidGroup(signatoryGroup_)
        onlyValidUpdateType(updateType_)
        onlyGreaterThanZero(expiration_)
    {
        // check update type
        if (
            keccak256(abi.encodePacked(updateType_)) ==
            keccak256(abi.encodePacked("ADD"))
        ) {
            // check signatory group
            if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("ADMIN"))
            ) {
                // require account not be an admin signatory
                require(
                    !_isAdminSignatory[signatoryAddress_],
                    "Admin Multi-Sig: Account is already an admin signatory!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(msg.sender, signatoryAddress_, signatoryGroup_, updateType_, expiration_);

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // add the new admin signatory directly: no need to create proposal
                    // add to the admin signatories
                    _adminSignatories.push(signatoryAddress_);

                    // update admin signatory status
                    _isAdminSignatory[signatoryAddress_] = true;

                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // emit admin signatory added event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            } else if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
            ) {
                // require account not be an supply management signatory
                require(
                    !_isSupplyManagementSignatory[signatoryAddress_],
                    "Admin Multi-Sig: Account is already a Supply Management signatory!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(msg.sender, signatoryAddress_, signatoryGroup_, updateType_, expiration_);

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // add the new supply management signatory directly: no need to create proposal
                    // add to the supply management signatories
                    _supplyManagementSignatories.push(signatoryAddress_);

                    // update supply management signatory status
                    _isSupplyManagementSignatory[signatoryAddress_] = true;

                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // emit admin signatory added event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            } else if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT"))
            ) {
                // require account not be an fee management signatory
                require(
                    !_isFeeManagementSignatory[signatoryAddress_],
                    "Admin Multi-Sig: Account is already a Fee Management signatory!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(msg.sender, signatoryAddress_, signatoryGroup_, updateType_, expiration_);

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // add the new Fee Management signatory directly: no need to create proposal
                    // add to the Fee Management signatories
                    _feeManagementSignatories.push(signatoryAddress_);

                    // update Fee Management signatory status
                    _isFeeManagementSignatory[signatoryAddress_] = true;

                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // emit signatory added event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            }  else if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("KYC"))
            ) {
                // require account not be an KYC signatory
                require(
                    !_isKYCSignatory[signatoryAddress_],
                    "Admin Multi-Sig: Account is already a KYC signatory!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(msg.sender, signatoryAddress_, signatoryGroup_, updateType_, expiration_);

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // add the new KYC signatory directly: no need to create proposal
                    // add to the KYC signatories
                    _KYCSignatories.push(signatoryAddress_);

                    // update KYC signatory status
                    _isKYCSignatory[signatoryAddress_] = true;

                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // emit signatory added event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            }

        } else if (
            keccak256(abi.encodePacked(updateType_)) ==
            keccak256(abi.encodePacked("REMOVE"))
        ) {
            // check signatory group
            if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("ADMIN"))
            ) {
                // require address be an admin signatory
                // and min signature not less than new number of signatories
                // and after remove a signatory there should be at least one admin signatory left.
                require(
                    (_isAdminSignatory[signatoryAddress_] &&
                        _minAdminSignatures < _adminSignatories.length &&
                        _adminSignatories.length > 1),
                    "Admin Multi-Sig: Either not admin signatory or violate min signatures!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(msg.sender, signatoryAddress_, signatoryGroup_, updateType_, expiration_);

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // remove admin signatory
                    _isAdminSignatory[signatoryAddress_] = false;

                    for (uint256 i = 0; i < _adminSignatories.length; i++) {
                        if (_adminSignatories[i] == signatoryAddress_) {
                            _adminSignatories[i] = _adminSignatories[
                                _adminSignatories.length - 1
                            ];
                            break;
                        }
                    }
                    _adminSignatories.pop();

                    // emit event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            } else if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
            ) {
                // require address be a Supply Management signatory
                // and min signature not less than new number of signatories
                require(
                    (_isSupplyManagementSignatory[signatoryAddress_] &&
                        _minSupplyManagementSignatures <
                        _supplyManagementSignatories.length),
                    "Admin Multi-Sig: Either not supply manager signatory or violate min signatures!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(msg.sender, signatoryAddress_, signatoryGroup_, updateType_, expiration_);

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // remove Supply Management signatory
                    _isSupplyManagementSignatory[signatoryAddress_] = false;

                    for (
                        uint256 i = 0;
                        i < _supplyManagementSignatories.length;
                        i++
                    ) {
                        if (
                            _supplyManagementSignatories[i] == signatoryAddress_
                        ) {
                            _supplyManagementSignatories[
                                i
                            ] = _supplyManagementSignatories[
                                _supplyManagementSignatories.length - 1
                            ];
                            break;
                        }
                    }
                    _supplyManagementSignatories.pop();

                    // emit event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            } else if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT"))
            ) {
                // require address be a Fee Management signatory
                // and min signature not less than new number of signatories
                require(
                    (_isFeeManagementSignatory[signatoryAddress_] &&
                        _minFeeManagementSignatures <
                        _feeManagementSignatories.length),
                    "Admin Multi-Sig: Either not fee manager signatory or violate min signatures!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(msg.sender, signatoryAddress_, signatoryGroup_, updateType_, expiration_);

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // remove signatory
                    _isFeeManagementSignatory[signatoryAddress_] = false;

                    for (
                        uint256 i = 0;
                        i < _feeManagementSignatories.length;
                        i++
                    ) {
                        if (_feeManagementSignatories[i] == signatoryAddress_) {
                            _feeManagementSignatories[
                                i
                            ] = _feeManagementSignatories[
                                _feeManagementSignatories.length - 1
                            ];
                            break;
                        }
                    }
                    _feeManagementSignatories.pop();

                    // emit event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            } else if (
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("KYC"))
            ) {
                // require address be a KYC signatory
                // and min signature not less than new number of signatories
                require(
                    (_isKYCSignatory[signatoryAddress_] &&
                        _minKYCSignatures <
                        _KYCSignatories.length),
                    "Admin Multi-Sig: Either not KYC signatory or violate min signatures!"
                );

                // create signatory proposal
                _createSignatoryPropolsa(msg.sender, signatoryAddress_, signatoryGroup_, updateType_, expiration_);

                // execute the proposal if sender is the only admin signatory.
                if (_adminSignatories.length == 1) {
                    // update proposal IS EXECUTED
                    _signatoryProposals[_adminProposalIndex].ISEXECUTED = true;

                    // update proposal EXECUTED TIMESTAMP
                    _signatoryProposals[_adminProposalIndex]
                        .EXECUTEDTIMESTAMP = block.timestamp;

                    // remove signatory
                    _isKYCSignatory[signatoryAddress_] = false;

                    for (
                        uint256 i = 0;
                        i < _KYCSignatories.length;
                        i++
                    ) {
                        if (_KYCSignatories[i] == signatoryAddress_) {
                            _KYCSignatories[
                                i
                            ] = _KYCSignatories[
                                _KYCSignatories.length - 1
                            ];
                            break;
                        }
                    }
                    _KYCSignatories.pop();

                    // emit event
                    emit SingatoryProposalExecutedEvent(
                        msg.sender,
                        _adminProposalIndex,
                        signatoryAddress_,
                        updateType_,
                        signatoryGroup_,
                        expiration_,
                        block.timestamp
                    );
                }
            }
        }
    }

    // approve signatory proposal (adding or removing)
    function approveSignatoryProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // admin proposal info
        SignatoryProposal storage proposal = _signatoryProposals[
            adminProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired, revoked or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                _signatoryProposalApprovers[adminProposalIndex_][msg.sender] ||
                proposal.ISREVOKED),
            "Admin Multi-Sig: Proposal should not be executed, expired, revoked or approved by sender!"
        );

        // if Removing a signatory, require min signatures is not violated (minSignatures > signatories.length)
        if (
            keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
            keccak256(abi.encodePacked("REMOVE"))
        ) {
            // check signatory group
            if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("ADMIN"))
            ) {
                // require not violating min signature
                require(
                    (_adminSignatories.length > _minAdminSignatures &&
                        _adminSignatories.length > 1),
                    "Admin Multi-Sig: Minimum admin signatories requirement not met!"
                );
            } else if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
            ) {
                // require not violating min signature
                require(
                    _supplyManagementSignatories.length >
                        _minSupplyManagementSignatures,
                    "Admin Multi-Sig: Minimum Supply Management signatories requirement not met!"
                );
            } else if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT"))
            ) {
                // require not violating min signature
                require(
                    _feeManagementSignatories.length >
                        _minFeeManagementSignatures,
                    "Admin Multi-Sig: Minimum Fee Management signatories requirement not met!"
                );
            } else if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("KYC"))
            ) {
                // require not violating min signature
                require(
                    _KYCSignatories.length >
                        _minKYCSignatures,
                    "Admin Multi-Sig: Minimum KYC signatories requirement not met!"
                );
            }
        }

        // update proposal approved by admin sender status
        _signatoryProposalApprovers[adminProposalIndex_][msg.sender] = true;

        // update proposal approval COUNT
        _signatoryProposals[_adminProposalIndex].APPROVALCOUNT++;

        // emit admin signatory proposal approved event
        emit ApproveSignatoryProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.MODIFIEDSIGNER,
            proposal.UPDATETYPE,
            proposal.SIGNATORYGROUP,
            block.timestamp
        );

        // check if enough admin signatories have approved the proposal
        if (
            _signatoryProposals[_adminProposalIndex].APPROVALCOUNT >=
            _minAdminSignatures
        ) {
            // add the new signatory
            _adminSignatories.push(proposal.MODIFIEDSIGNER);

            // update role
            _isAdminSignatory[proposal.MODIFIEDSIGNER] = true;

            // update is executed proposal
            proposal.ISEXECUTED = true;

            // update proposal EXECUTED TIMESTAMP
            proposal.EXECUTEDTIMESTAMP = block.timestamp;

            // emit executing signatory proposal
            emit SingatoryProposalExecutedEvent(
                msg.sender,
                adminProposalIndex_,
                proposal.MODIFIEDSIGNER,
                proposal.UPDATETYPE,
                proposal.SIGNATORYGROUP,
                proposal.EXPIRATION,
                block.timestamp
            );
        }
    }

    // revoke signatory proposal (by Admin proposer)
    function revokeSignatoryProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyProposer(adminProposalIndex_)
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // admin proposal info
        SignatoryProposal storage proposal = _signatoryProposals[
            adminProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired or revoked
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Admin Multi-Sig: Proposal should not be executed, expired or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update revoked timestamp
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeSignatoryProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.UPDATETYPE,
            proposal.SIGNATORYGROUP,
            block.timestamp
        );
    }

    ///   Min Signatores Proposals   ///

    // create min singatures requirement proposal
    function createMinSignaturesProposal(
        uint256 minSignatures_,
        string memory signatoryGroup_,
        uint256 expiration_
    )
        public
        onlyAdmins
        onlyValidGroup(signatoryGroup_)
        onlyGreaterThanZero(expiration_)
    {
        // check signatory group
        if (
            keccak256(abi.encodePacked(signatoryGroup_)) ==
            keccak256(abi.encodePacked("ADMIN"))
        ) {
            // require valid min signature proposal
            // - minSignatures should be less or equal to the signatories of the specified group
            // - it should be different from current minSignatures
            require(
                ((minSignatures_ <= _adminSignatories.length) &&
                    (minSignatures_ != _minAdminSignatures)),
                "Admin Multi-Sig: Invalid min signature value!"
            );

            // create min signature proposal
            _createMinSignatureProposal(msg.sender, minSignatures_, signatoryGroup_, expiration_);

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous admin min signatures
                uint256 previousMinAdminSignatures = _minAdminSignatures;

                // update is EXECUTED
                _minSingatureProposal[_adminProposalIndex].ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _minSingatureProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update admin min signatures (execute the proposal)
                _minAdminSignatures = minSignatures_;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinAdminSignatures,
                    minSignatures_,
                    signatoryGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(signatoryGroup_)) ==
            keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
        ) {
            // require valid min signature proposal
            // - minSignatures should be less or equal to the signatories of the specified group
            // - it should be different from current minSignatures
            require(
                ((minSignatures_ <= _supplyManagementSignatories.length) &&
                    (minSignatures_ != _minSupplyManagementSignatures)),
                "Admin Multi-Sig: Invalid min signature value!"
            );

            // create min signature proposal
            _createMinSignatureProposal(msg.sender, minSignatures_, signatoryGroup_, expiration_);

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous supply management min signatures
                uint256 previousMinSupplyManagementSignatures = _minSupplyManagementSignatures;

                // update is EXECUTED
                _minSingatureProposal[_adminProposalIndex].ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _minSingatureProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update admin min signatures (execute the proposal)
                _minSupplyManagementSignatures = minSignatures_;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinSupplyManagementSignatures,
                    minSignatures_,
                    signatoryGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(signatoryGroup_)) ==
            keccak256(abi.encodePacked("FEEMANAGEMENT"))
        ) {
            // require valid min signature proposal
            // - minSignatures should be less or equal to the signatories of the specified group
            // - it should be different from current minSignatures
            require(
                ((minSignatures_ <= _feeManagementSignatories.length) &&
                    (minSignatures_ != _minFeeManagementSignatures)),
                "Admin Multi-Sig: Invalid min signature value!"
            );

            // create min signature proposal
            _createMinSignatureProposal(msg.sender, minSignatures_, signatoryGroup_, expiration_);

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous Fee Management min signatures
                uint256 previousMinFeeManagementSignatures = _minFeeManagementSignatures;

                // update is EXECUTED
                _minSingatureProposal[_adminProposalIndex].ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _minSingatureProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update Fee Management min signatures (execute the proposal)
                _minFeeManagementSignatures = minSignatures_;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinFeeManagementSignatures,
                    minSignatures_,
                    signatoryGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(signatoryGroup_)) ==
            keccak256(abi.encodePacked("KYC"))
        ) {
            // require valid min signature proposal
            // - minSignatures should be less or equal to the signatories of the specified group
            // - it should be different from current minSignatures
            require(
                ((minSignatures_ <= _KYCSignatories.length) &&
                    (minSignatures_ != _minKYCSignatures)),
                "Admin Multi-Sig: Invalid min signature value!"
            );

            // create min signature proposal
            _createMinSignatureProposal(msg.sender, minSignatures_, signatoryGroup_, expiration_);

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous KYC min signatures
                uint256 previousMinKYCSignatures = _minKYCSignatures;

                // update is EXECUTED
                _minSingatureProposal[_adminProposalIndex].ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _minSingatureProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update KYC min signatures (execute the proposal)
                _minKYCSignatures = minSignatures_;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinKYCSignatures,
                    minSignatures_,
                    signatoryGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve min signatures requirement proposal
    function approveMinSignaturesProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // min signatures proposal info
        MinSignatureProposal storage proposal = _minSingatureProposal[
            adminProposalIndex_
        ];

        // require proposal not been EXECUTED already, EXPIRED, REVOKED OR APPROVED BY SENDER
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED ||
                _minSignatureApprovers[adminProposalIndex_][msg.sender]),
            "Admin Multi-Sig: Proposal should not be approved, expired, revoked or approved by sender!"
        );

        // update proposal approved by admin sender status
        _minSignatureApprovers[adminProposalIndex_][msg.sender] = true;

        // update proposal approval COUNT
        proposal.APPROVALCOUNT++;

        // emit min signature proposal approved event
        emit ApproveMinSignaturesProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.MINSIGNATURE,
            proposal.SIGNATORYGROUP,
            block.timestamp
        );

        // check if enough admin signatories have approved the proposal
        if (
            _minSingatureProposal[_adminProposalIndex].APPROVALCOUNT >=
            _minAdminSignatures
        ) {
            // check signatory group
            if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("ADMIN"))
            ) {
                // previous admin min signatures
                uint256 previousMinAdminSignatures = _minAdminSignatures;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update admin min signatures
                _minAdminSignatures = proposal.MINSIGNATURE;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinAdminSignatures,
                    proposal.MINSIGNATURE,
                    proposal.SIGNATORYGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
            ) {
                // previous Supply Management min signatures
                uint256 previousMinSupplyManagementSignatures = _minSupplyManagementSignatures;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update Supply Management min signatures
                _minSupplyManagementSignatures = proposal.MINSIGNATURE;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinSupplyManagementSignatures,
                    proposal.MINSIGNATURE,
                    proposal.SIGNATORYGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT"))
            ) {
                // previous Fee Management min signatures
                uint256 previousMinFeeManagementSignatures = _minFeeManagementSignatures;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update Fee Management min signatures
                _minFeeManagementSignatures = proposal.MINSIGNATURE;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinFeeManagementSignatures,
                    proposal.MINSIGNATURE,
                    proposal.SIGNATORYGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.SIGNATORYGROUP)) ==
                keccak256(abi.encodePacked("KYC"))
            ) {
                // previous KYC min signatures
                uint256 previousMinKYCSignatures = _minKYCSignatures;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update KYC min signatures
                _minKYCSignatures = proposal.MINSIGNATURE;

                // emit executing min signatures proposal
                emit MinSignaturesProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousMinKYCSignatures,
                    proposal.MINSIGNATURE,
                    proposal.SIGNATORYGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke min signatures requirement proposal (by Admin proposer)
    function revokeMinSignaturesProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyProposer(adminProposalIndex_)
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // admin proposal info
        MinSignatureProposal storage proposal = _minSingatureProposal[
            adminProposalIndex_
        ];

        // require proposal not been approved already, expired, or revoked
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Admin Multi-Sig: Proposal should not be approved, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // UPDATED REVOKED TIMESTAMP
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeMinSignaturesProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.MINSIGNATURE,
            proposal.SIGNATORYGROUP,
            block.timestamp
        );
    }

    ///   Freeze Management Proposals   ///

    // create freeze management proposal
    function createFreezeManagementProposal(
        string memory managementGroup_,
        bool updateStatus_,
        uint256 expiration_
    )
        public
        onlyAdmins
        onlyValidManagementGroups(managementGroup_)
        onlyGreaterThanZero(expiration_)
    {
        // check signatory group
        if (
            keccak256(abi.encodePacked(managementGroup_)) ==
            keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
        ) {
            // require update status be different from current status
            require(
                _freezeSupplyManagementActivities != updateStatus_,
                "Admin Multi-Sig: New freeze status should be different from current status!"
            );

            // increment administration proposal ID
            ++_adminProposalIndex;

            // add proposal
            _freezeManagementProposal[
                _adminProposalIndex
            ] = FreezeManagementProposal({
                ID: _adminProposalIndex,
                PROPOSER: msg.sender,
                MANAGEMENTGROUP: managementGroup_,
                STATUS: updateStatus_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _freezeManagementApprovers[_adminProposalIndex][msg.sender] = true;

            // emit freeze management proposal event
            emit FreezeManagementProposalCreatedEvent(
                msg.sender,
                _adminProposalIndex,
                managementGroup_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous freeze status
                bool previousFreezeStatus = _freezeSupplyManagementActivities;

                // update is EXECUTED
                _freezeManagementProposal[_adminProposalIndex]
                    .ISEXECUTED = true;

                // UPDATE EXECUTED TIMESTAMP
                _freezeManagementProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update supply management freeze status (execute the proposal)
                _freezeSupplyManagementActivities = updateStatus_;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    updateStatus_,
                    managementGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(managementGroup_)) ==
            keccak256(abi.encodePacked("FEEMANAGEMENT"))
        ) {
            // require update status be different from current status
            require(
                _freezeFeeManagementActivities != updateStatus_,
                "Admin Multi-Sig: New freeze status should be different from current status!"
            );

            // increment administration proposal ID
            ++_adminProposalIndex;

            // add proposal
            _freezeManagementProposal[
                _adminProposalIndex
            ] = FreezeManagementProposal({
                ID: _adminProposalIndex,
                PROPOSER: msg.sender,
                MANAGEMENTGROUP: managementGroup_,
                STATUS: updateStatus_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _freezeManagementApprovers[_adminProposalIndex][msg.sender] = true;

            // emit freeze management proposal event
            emit FreezeManagementProposalCreatedEvent(
                msg.sender,
                _adminProposalIndex,
                managementGroup_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous freeze status
                bool previousFreezeStatus = _freezeFeeManagementActivities;

                // update is EXECUTED
                _freezeManagementProposal[_adminProposalIndex]
                    .ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                _freezeManagementProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update fee management freeze status (execute the proposal)
                _freezeFeeManagementActivities = updateStatus_;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    updateStatus_,
                    managementGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(managementGroup_)) ==
            keccak256(abi.encodePacked("ASSETPROTECTION"))
        ) {
            // require update status be different from current status
            require(
                _freezeAssetProtectionActivities != updateStatus_,
                "Admin Multi-Sig: New freeze status should be different from current status!"
            );

            // increment administration proposal ID
            ++_adminProposalIndex;

            // add proposal
            _freezeManagementProposal[
                _adminProposalIndex
            ] = FreezeManagementProposal({
                ID: _adminProposalIndex,
                PROPOSER: msg.sender,
                MANAGEMENTGROUP: managementGroup_,
                STATUS: updateStatus_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _freezeManagementApprovers[_adminProposalIndex][msg.sender] = true;

            // emit freeze management proposal event
            emit FreezeManagementProposalCreatedEvent(
                msg.sender,
                _adminProposalIndex,
                managementGroup_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous freeze status
                bool previousFreezeStatus = _freezeAssetProtectionActivities;

                // update is EXECUTED
                _freezeManagementProposal[_adminProposalIndex]
                    .ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                _freezeManagementProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update asset protection freeze status (execute the proposal)
                _freezeAssetProtectionActivities = updateStatus_;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    updateStatus_,
                    managementGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        } else if (
            keccak256(abi.encodePacked(managementGroup_)) ==
            keccak256(abi.encodePacked("GLOBAL"))
        ) {
            // require update status be different from current status
            require(
                _globalFreezeManagementActivities != updateStatus_,
                "Admin Multi-Sig: New freeze status should be different from current status!"
            );

            // increment administration proposal ID
            ++_adminProposalIndex;

            // add proposal
            _freezeManagementProposal[
                _adminProposalIndex
            ] = FreezeManagementProposal({
                ID: _adminProposalIndex,
                PROPOSER: msg.sender,
                MANAGEMENTGROUP: managementGroup_,
                STATUS: updateStatus_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _freezeManagementApprovers[_adminProposalIndex][msg.sender] = true;

            // emit freeze management proposal event
            emit FreezeManagementProposalCreatedEvent(
                msg.sender,
                _adminProposalIndex,
                managementGroup_,
                expiration_,
                block.timestamp
            );

            // execute the proposal if sender is the only Admin signatory
            if (_adminSignatories.length == 1) {
                // previous freeze status
                bool previousFreezeStatus = _globalFreezeManagementActivities;

                // update is EXECUTED
                _freezeManagementProposal[_adminProposalIndex]
                    .ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                _freezeManagementProposal[_adminProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                //  update global freeze status (execute the proposal)
                _globalFreezeManagementActivities = updateStatus_;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    updateStatus_,
                    managementGroup_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve freeze management proposal
    function approveFreezeManagementProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // freeze management proposal info
        FreezeManagementProposal storage proposal = _freezeManagementProposal[
            adminProposalIndex_
        ];

        // require proposal not been EXECUTED, expired, revoked, or apprved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED ||
                _freezeManagementApprovers[adminProposalIndex_][msg.sender]),
            "Admin Multi-Sig: Proposal should not be executed, expired, revoked or approved by sender!"
        );

        // update proposal approved by admin sender status
        _freezeManagementApprovers[adminProposalIndex_][msg.sender] = true;

        // update proposal approval COUNT
        proposal.APPROVALCOUNT++;

        // emit approve freeze management proposal event
        emit ApproveFreezeManagementProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.MANAGEMENTGROUP,
            proposal.STATUS,
            block.timestamp
        );

        // check if enough admin signatories have approved the proposal
        if (
            _freezeManagementProposal[_adminProposalIndex].APPROVALCOUNT >=
            _minAdminSignatures
        ) {
            // check signatory group
            if (
                keccak256(abi.encodePacked(proposal.MANAGEMENTGROUP)) ==
                keccak256(abi.encodePacked("GLOBAL"))
            ) {
                // previous freeze status
                bool previousFreezeStatus = _globalFreezeManagementActivities;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update global freeze status (execute the proposal)
                _globalFreezeManagementActivities = proposal.STATUS;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    proposal.STATUS,
                    proposal.MANAGEMENTGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.MANAGEMENTGROUP)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT"))
            ) {
                // previous freeze status
                bool previousFreezeStatus = _freezeSupplyManagementActivities;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update supply management freeze status (execute the proposal)
                _freezeSupplyManagementActivities = proposal.STATUS;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    proposal.STATUS,
                    proposal.MANAGEMENTGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.MANAGEMENTGROUP)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT"))
            ) {
                // previous freeze status
                bool previousFreezeStatus = _freezeFeeManagementActivities;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update fee management freeze status (execute the proposal)
                _freezeFeeManagementActivities = proposal.STATUS;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    proposal.STATUS,
                    proposal.MANAGEMENTGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.MANAGEMENTGROUP)) ==
                keccak256(abi.encodePacked("ASSETPROTECTION"))
            ) {
                // previous freeze status
                bool previousFreezeStatus = _freezeAssetProtectionActivities;

                // update is EXECUTED
                proposal.ISEXECUTED = true;

                // update  EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                //  update asset protection freeze status (execute the proposal)
                _freezeAssetProtectionActivities = proposal.STATUS;

                // emit executing freeze management proposal
                emit FreezeManagementProposalExecutedEvent(
                    msg.sender,
                    _adminProposalIndex,
                    previousFreezeStatus,
                    proposal.STATUS,
                    proposal.MANAGEMENTGROUP,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke freeze management proposal
    function revokeFreezeManagementProposal(uint256 adminProposalIndex_)
        public
        onlyAdmins
        onlyProposer(adminProposalIndex_)
        onlyValidAdminProposalIndex(adminProposalIndex_)
    {
        // admin proposal info
        FreezeManagementProposal storage proposal = _freezeManagementProposal[
            adminProposalIndex_
        ];

        // require proposal not been executed already, expired, or revoked.
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Admin Multi-Sig: Proposal is already executed, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update revoked timestamp
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeFreezeManagementProposalEvent(
            msg.sender,
            adminProposalIndex_,
            proposal.MANAGEMENTGROUP,
            proposal.STATUS,
            block.timestamp
        );
    }

    ///   GETTER FUNCTIONS   ///

    // get Address Book Contract Address
    function getAddressBookContractAddress() public view returns (address) {
        return _AddressBookContractAddress;
    }

    // get admin signatories
    function getAdminSignatories() public view returns (address[] memory) {
        return _adminSignatories;
    }

    // is admin signatory
    function IsAdminSignatory(address account_) public view returns (bool) {
        return _isAdminSignatory[account_];
    }

    // get admin proposal index
    function getAdminProposalIndex() public view returns (uint256) {
        return _adminProposalIndex;
    }

    // get admin proposal detail
    function getAdminProposalDetail(uint256 adminProposalIndex_)
        public
        view
        returns (SignatoryProposal memory)
    {
        return _signatoryProposals[adminProposalIndex_];
    }

    // is admin proposal approver
    function IsAdminProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) public view returns (bool) {
        return _signatoryProposalApprovers[adminProposalIndex_][account_];
    }

    // get number of admin signatories
    function getNumberOfAdminSignatories() public view returns (uint256) {
        return _adminSignatories.length;
    }

    // get min signature
    function getMinAdminSignatures() public view returns (uint256) {
        return _minAdminSignatures;
    }

    // get min signature proposal detail
    function getMinSignatureProposalDetail(uint256 adminProposalIndex_)
        public
        view
        returns (MinSignatureProposal memory)
    {
        return _minSingatureProposal[adminProposalIndex_];
    }

    // is min signature proposal approver?
    function IsMinSignatureProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) public view returns (bool) {
        return _minSignatureApprovers[adminProposalIndex_][account_];
    }

    // get Freeze Management proposal detail
    function getFreezeManagementProposalDetail(uint256 adminProposalIndex_)
        public
        view
        returns (FreezeManagementProposal memory)
    {
        return _freezeManagementProposal[adminProposalIndex_];
    }

    // is freeze management proposal approver?
    function IsFreezeManagementProposalApprover(
        uint256 adminProposalIndex_,
        address account_
    ) public view returns (bool) {
        return _freezeManagementApprovers[adminProposalIndex_][account_];
    }

    // get global freeze management status
    function getGlobalFreezeManagementStatus() public view returns (bool) {
        return _globalFreezeManagementActivities;
    }

    // get Supply Management Freeze status
    function getSupplyManagementFreezeStatus() public view returns (bool) {
        return _freezeSupplyManagementActivities;
    }

    // get Fee Management Freeze status
    function getFeeManagementFreezeStatus() public view returns (bool) {
        return _freezeFeeManagementActivities;
    }

    // get Asset Protection Freeze status
    function getAssetProtectionFreezeStatus() public view returns (bool) {
        return _freezeAssetProtectionActivities;
    }

    // get Supply Management Signatories
    function getSupplyManagementSignatories()
        public
        view
        returns (address[] memory)
    {
        return _supplyManagementSignatories;
    }

    // Is Supply Management Signatory
    function IsSupplyManagementSignatory(address account_)
        public
        view
        returns (bool)
    {
        return _isSupplyManagementSignatory[account_];
    }

    // get Min Signature requirement for Supply Management
    function getSupplyManagementMinSignatures() public view returns (uint256) {
        return _minSupplyManagementSignatures;
    }

    // get Fee Management Signatories
    function getFeeManagementSignatories()
        public
        view
        returns (address[] memory)
    {
        return _feeManagementSignatories;
    }

    // is Fee Managemetn Signatory
    function IsFeeManagementSignatory(address account_)
        public
        view
        returns (bool)
    {
        return _isFeeManagementSignatory[account_];
    }

    // get Fee Management Min Singatures
    function getFeeManagementMinSignatures() public view returns (uint256) {
        return _minFeeManagementSignatures;
    }

    // get KYC Signatories
    function getKYCSignatories()
        public
        view
        returns (address[] memory)
    {
        return _KYCSignatories;
    }

    // is KYC Signatory
    function IsKYCSignatory(address account_)
        public
        view
        returns (bool)
    {
        return _isKYCSignatory[account_];
    }

    // get KYC Min Signatures
    function getKYCMinSignatures() public view returns (uint256) {
        return _minKYCSignatures;
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////

    // only admin
    function _onlyAdmins() internal view virtual {
        require(
            _isAdminSignatory[msg.sender],
            "Admin Multi-Sig: Sender is not an admin signatory!"
        );
    }

    // not null address
    function _notNullAddress(address account_) internal view virtual {
        require(
            account_ != address(0),
            "Admin Multi-Sig: Address should not be zero address!"
        );
    }

    // only valid admin proposal index
    function _onlyValidAdminProposalIndex(uint256 adminProposalIndex_)
        internal
        view
        virtual
    {
        // require a valid admin proposal index ( != 0 and not more than max)
        require(
            (adminProposalIndex_ != 0 &&
                adminProposalIndex_ <= _adminProposalIndex),
            "Admin Multi-Sig: Invalid admin proposal index!"
        );
    }

    // only valid signatory group
    function _onlyValidGroup(string memory signatoryGroup_)
        internal
        view
        virtual
    {
        // require valid signatory group
        require(
            keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("ADMIN")) ||
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT")) ||
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT")) ||
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("KYC")),
            "Admin Multi-Sig: Signatory group is not valid!"
        );
    }

    // only valid signatory update type
    function _onlyValidUpdateType(string memory updateType_)
        internal
        view
        virtual
    {
        // require valid update type
        require(
            keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("ADD")) ||
                keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("REMOVE")),
            "Admin Multi-Sig: Update type is not valid!"
        );
    }

    // greater than zero value
    function _onlyGreaterThanZero(uint256 value_) internal view virtual {
        // require value be greater than zero
        require(
            value_ > 0,
            "Admin Multi-Sig: Value should be greater than zero!"
        );
    }

    // only proposer
    function _onlyProposer(uint256 adminProposalIndex_) internal view virtual {
        // require sender be the proposer of the proposal
        require(
            msg.sender == _signatoryProposals[adminProposalIndex_].PROPOSER,
            "Admin Multi-Sig: Sender is not the proposer!"
        );
    }

    // only valid management groups for freezing
    function _onlyValidManagementGroups(string memory signatoryGroup_)
        internal
        view
        virtual
    {
        // require valid signatory group
        require(
            keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("SUPPLYMANAGEMENT")) ||
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("FEEMANAGEMENT")) ||
                keccak256(abi.encodePacked(signatoryGroup_)) ==
                keccak256(abi.encodePacked("GLOBAL")),
            "Admin Multi-Sig: Signatory group is not valid!"
        );
    }

    // create signatory proposal
    function _createSignatoryPropolsa(
        address sender,
        address signatoryAddress_,
        string memory updateType_,
        string memory signatoryGroup_,
        uint256 expiration_
    ) internal {
            // increment administration proposal ID
            ++_adminProposalIndex;

            // add the admin proposal
            _signatoryProposals[_adminProposalIndex] = SignatoryProposal({
                ID: _adminProposalIndex,
                PROPOSER: sender,
                MODIFIEDSIGNER: signatoryAddress_,
                UPDATETYPE: updateType_,
                SIGNATORYGROUP: signatoryGroup_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve proposal by admin sender
            _signatoryProposalApprovers[_adminProposalIndex][
                sender
            ] = true;

            // emit add admin signatory proposal event
            emit SignatoryProposalCreatedEvent(
                sender,
                _adminProposalIndex,
                signatoryAddress_,
                updateType_,
                signatoryGroup_,
                expiration_,
                block.timestamp
            );
    }

    // create min signature proposal
    function _createMinSignatureProposal(
        address sender,
        uint256 minSignatures_,
        string memory signatoryGroup_,
        uint256 expiration_
    ) internal {

            // increment administration proposal ID
            ++_adminProposalIndex;

            // add proposal
            _minSingatureProposal[_adminProposalIndex] = MinSignatureProposal({
                ID: _adminProposalIndex,
                PROPOSER: sender,
                MINSIGNATURE: minSignatures_,
                SIGNATORYGROUP: signatoryGroup_,
                ISEXECUTED: false,
                EXPIRATION: block.timestamp + expiration_,
                ISREVOKED: false,
                PROPOSEDTIMESTAMP: block.timestamp,
                EXECUTEDTIMESTAMP: 0,
                REVOKEDTIMESTAMP: 0,
                APPROVALCOUNT: 1
            });

            // approve the proposal by admin sender
            _minSignatureApprovers[_adminProposalIndex][sender] = true;

            // emit creating min signature proposal event
            emit MinSignaturesProposalCreatedEvent(
                sender,
                _adminProposalIndex,
                minSignatures_,
                signatoryGroup_,
                expiration_,
                block.timestamp
            );
    }
}