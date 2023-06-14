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

// ERC20 Interface
interface ERC20Interface {
    ////    Standard ERC20    ////

    // transfer
    function transfer(address to_, uint256 amount_) external returns (bool);

    // allowance
    function allowance(address owner_, address spender_)
        external
        view
        returns (uint256);

    // approve
    function approve(address spender_, uint256 amount_) external returns (bool);

    // transferFrom
    function transferFrom(
        address from_,
        address to_,
        uint256 amount_
    ) external returns (bool);

    // increaseAllowance
    function increaseAllowance(address spender_, uint256 addedValue_)
        external
        returns (bool);

    // decreaseAllowance
    function decreaseAllowance(address spender_, uint256 subtractedValue_)
        external
        returns (bool);

    // name
    function name() external view returns (string memory);

    // symbol
    function symbol() external view returns (string memory);

    // decimals
    function decimals() external view returns (uint8);

    // totalSupply
    function totalSupply() external view returns (uint256);

    // balanceOf
    function balanceOf(address account_) external returns (uint256);

    //// Commodity Token Public Functions   ////

    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;

    // update Fee Management Contract Address
    function updateFeeManagementContractAddress(
        address FeeManagementContractAddress_
    ) external;

    // freeze all transactions
    function freezeAllTransactions() external;

    // un-freeze all transactions
    function unFreezeAllTransactions() external;

    // freeze an account
    function freezeAccount(address account_) external;

    // un-freeze and account
    function unFreezeAccount(address account_) external;

    // wipe freezed account
    function wipeFreezedAccount(address account_) external;

    // wipe specific amount freezed account
    function wipeSpecificAmountFreezedAccount(address account_, uint256 amount_)
        external;

    // freeze and wipe an account
    function freezeAndWipeAccount(address account_) external;

    // freeze and wipe specific amount from an account
    function freezeAndWipeSpecificAmountAccount(
        address account_,
        uint256 amount_
    ) external;

    // creation basket
    function creationBasket(
        uint256 amount_,
        address receiverAddress_,
        string memory basketType_
    ) external returns (bool);

    // authorize Supply Management Multi-Sig for redemption
    function authorizeRedemption(uint256 amount_) external;

    // revoke authorized redemption
    function revokeAuthorizedRedemption(uint256 amount_) external;

    // redemption basket
    function redemptionBasket(uint256 amount_, address senderAddress_)
        external
        returns (bool);

    // withdraw tokens from contract to Treasurer account
    function withdrawContractTokens() external;

    ////   Getters    ////

    // get Address Book
    function getAddressBook() external view returns (address);

    // get Admin Multi-Sign
    function getAdmin() external view returns (address);

    // get Asset Protection
    function getAssetProtection() external view returns (address);

    // get Fee Management Contract Address
    function getFeeManagementContractAddress() external view returns (address);

    // get Fee Management Multi-Sign Address
    function getFeeManager() external view returns (address);

    // get token supply manager
    function getTokenSupplyManager() external view returns (address);

    // get redemption approved amount
    function getRedemptionApprovedAmount(address account_)
        external
        view
        returns (uint256);

    // is freeze all transaction
    function isAllTransactionsFreezed() external view returns (bool);

    // is acount freezed
    function isFreezed(address account_) external view returns (bool);

    // get list of freezed accounts
    function getFreezedAccounts() external view returns (address[] memory);

    // get holders
    function getHolders() external view returns (address[] memory);
}

// Fee Management Interface
interface FeeManagementInterface {
    // update Address Book Contract Address
    function updateAddressBookContractAddress(
        address AddressBookContractAddress_
    ) external;

    // authorize for redemption
    function authorizeRedemption(uint256 redemptionAmount_) external;

    // update whitelist manager
    function updateWhitelistManager(address whitelistManagerAddress_) external;

    // update fee manager
    function updateFeeManager(address feeManagerAddress_) external;

    // add account to global whitelist
    function appendToGlobalWhitelist(address account_) external;

    // remove account from global whitelist
    function removeFromGlobalWhitelist(address account_) external;

    // add account to creation/redemption whitelist
    function appendToCRWhitelist(address account_) external;

    // remove account from creation/redemption whitelist
    function removeFromCRWhitelist(address account_) external;

    // add account to transfer whitelist
    function appendToTransferWhitelist(address account_) external;

    // remove account from transfer whitelist
    function removeFromTransferWhitelist(address account_) external;

    // set fee decimals
    function setFeeDecimals(uint256 feeDecimals_) external;

    // set creation fee
    function setCreationFee(uint256 creationFee_) external;

    // set redemption fee
    function setRedemptionFee(uint256 redemptionFee_) external;

    // set transfer fee
    function setTransferFee(uint256 transferFee_) external;

    // set min transfer amount
    function setMinTransferAmount(uint256 amount_) external;

    // set min creation amount
    function setMinCreationAmount(uint256 amount_) external;

    // set min redemption amount
    function setMinRedemptionAmount(uint256 amount_) external;

    // get Admin
    function getAdmin() external view returns (address);

    // get fee manager
    function getFeeManager() external view returns (address);

    // is global whitelisted
    function isGlobalWhitelisted(address account_) external view returns (bool);

    // is creation/redemption whitelisted
    function isCRWhitelisted(address account_) external view returns (bool);

    // is transfer whitelisted
    function isTransferWhitelisted(address account_)
        external
        view
        returns (bool);

    // get list of accounts in global whitelist
    function getGlobalWhitelist() external view returns (address[] memory);

    // get list of accounts in creation/redemption whitelist
    function getCreationRedemptionWhitelist()
        external
        view
        returns (address[] memory);

    // get list of accounts in transfer whitelist
    function getTransferWhitelist() external view returns (address[] memory);

    // get fee decimals
    function getFeeDecimals() external view returns (uint256);

    // get creation fee
    function getCreationFee() external view returns (uint256);

    // get redemption fee
    function getRedemptionFee() external view returns (uint256);

    // get transfer fee
    function getTransferFee() external view returns (uint256);

    // get min transfer amount
    function getGlobalMinTransferAmount() external view returns (uint256);

    // get min creation amount
    function getMinTransferAmount() external view returns (uint256);

    // get global min creation amount
    function getGlobalMinCreationAmount() external view returns (uint256);

    // get min creation amount
    function getMinCreationAmount() external view returns (uint256);

    // get global min redemption amount
    function getGlobalMinRedemptionAmount() external view returns (uint256);

    // get min redemption amount
    function getMinRedemptionAmount() external view returns (uint256);
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

// Fee Management Multi-Sig Interface
interface FeeManagementMultiSigInterface {
    // update ERC20 Contract Address
    function updateERC20ContractAddress(address ERC20ContractAddress_) external;

    // update Admin Multi-Sig Contract Address
    function updateAdminMultiSigContractAddress(
        address AdminMultiSigContractAddress_
    ) external;

    // update Fee Management Contract Address
    function updateFeeManagementContractAddress(
        address FeeManagementContractAddress_
    ) external;

    // create fee update proposal
    function createFeeUpdateProposal(
        string memory feeCategory_,
        uint256 feeAmount_,
        uint256 expiration_
    ) external;

    // approve fee update proposal
    function approveFeeUpdateProposal(uint256 feeManagementProposalIndex_)
        external;

    // revoke fee update proposal
    function revokeFeeUpdateProposal(uint256 feeManagementProposalIndex_)
        external;

    // create fee exemption proposal
    function createFeeExemptionProposal(
        string memory exemptionCategory_,
        string memory updateType_,
        address account_,
        uint256 expiration_
    ) external;

    // approve fee exemption proposal
    function approveFeeExemptionProposal(uint256 feeManagementProposalIndex_)
        external;

    // revoke fee exemption proposal
    function revokeFeeExemptionProposal(uint256 feeManagementProposalIndex_)
        external;

    // get admin multi sig contract address
    function getAdminMultiSigContractAddress() external view returns (address);

    // get max fee management proposal index
    function getMaxFeeManagementProposalIndex() external view returns (uint256);

    // get Fee Manager Proposal Detail
    // function getFeeManagerProposalDetail(uint256 feeManagementProposalIndex_) external view returns (FeeManagerProposal memory);

    // is Fee Manger proposal approver
    function IsFeeMangerProposalApprover(
        uint256 feeManagementProposalIndex_,
        address account_
    ) external view returns (bool);

    // get whitelist manager proposal detail
    // function getWhitelistMangerProposalDetail(uint256 feeManagementProposalIndex_) external view returns (WhitelistManagerProposal memory);

    // is whitelist manager proposal approvers
    function IsWhitelistManagerProposalApprovers(
        uint256 feeManagementProposalIndex_,
        address account_
    ) external view returns (bool);
}

// Fee Management Multi-Sig
contract FeeManagementMultiSig {
    ///////////////////////
    ////   Libraries   ////
    ///////////////////////

    //////////////////////
    ////    Fields    ////
    //////////////////////

    // ERC20 Contract Address
    address private _ERC20ContractAddress;

    // ERC20 Contract Interface
    ERC20Interface private _ERC20;

    // Fee Management Contract Address
    address private _FeeManagementContractAddress;

    // Fee Management Interface
    FeeManagementInterface private _FeeManagement;

    // Admin Multi-Sig Contract Address
    address private _AdminMultiSigContractAddress;

    // Admin Multi-Sig Contract Interface
    AdminMultiSigInterface private _AdminMultiSig;

    // Fee Management proposal counter
    uint256 private _feeManagementProposalIndex = 0;

    // Fee Manager Proposal struct
    struct FeeManagerProposal {
        uint256 ID;
        address PROPOSER;
        string CATEGORY;
        uint256 AMOUNT;
        bool ISEXECUTED;
        uint256 EXPIRATION;
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // list of fee manager proposals info: Fee Management proposal index => proposal detail
    mapping(uint256 => FeeManagerProposal) private _feeManagerProposals;

    // fee manager proposal approvers: Fee Management proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _feeManagerProposalApprovers;

    // Whitelist Manager Proposal struct
    struct WhitelistManagerProposal {
        uint256 ID;
        address PROPOSER;
        string EXEMPTIOMCATEGORY;
        string UPDATETYPE; // ADD or REMOVE
        address ACCOUNT;
        bool ISEXECUTED;
        uint256 EXPIRATION;
        bool ISREVOKED;
        uint256 PROPOSEDTIMESTAMP;
        uint256 EXECUTEDTIMESTAMP;
        uint256 REVOKEDTIMESTAMP;
        uint256 APPROVALCOUNT;
    }

    // list of whitelist manager proposals info: Fee Management proposal index => proposal detail
    mapping(uint256 => WhitelistManagerProposal)
        private _whitelistManagerProposals;

    // whitelist manager proposal approvers: Fee Management proposal index => address => status
    mapping(uint256 => mapping(address => bool))
        private _whitelistManagerProposalApprovers;

    ///////////////////////
    //    constructor    //
    ///////////////////////

    // constructor
    constructor(
        address ERC20ContractAddress_,
        address FeeManagementContractAddress_,
        address AdminMultiSigContractAddress_
    ) {
        // require not null address
        require(ERC20ContractAddress_ != address(0), "Admin Multi-Sig: ERC20 Address should not be zero address!");
        
        // update ERC20 Contract Address
        _ERC20ContractAddress = ERC20ContractAddress_;

        // update ERC20 Contract Interface
        _ERC20 = ERC20Interface(ERC20ContractAddress_);

        // emit event
        emit updateERC20ContractAddressEvent(
            msg.sender,
            address(0),
            ERC20ContractAddress_,
            block.timestamp
        );

        // require not null address
        require(FeeManagementContractAddress_ != address(0), "Admin Multi-Sig: Fee Management Address should not be zero address!");

        // update Fee Management Contract Address
        _FeeManagementContractAddress = FeeManagementContractAddress_;

        // update Fee Management Contract Interface
        _FeeManagement = FeeManagementInterface(FeeManagementContractAddress_);

        // emit event
        emit updateFeeManagementContractAddressEvent(
            msg.sender,
            address(0),
            FeeManagementContractAddress_,
            block.timestamp
        );

        // require not null address
        require(AdminMultiSigContractAddress_ != address(0), "Admin Multi-Sig: Admin Multi-Sig Address should not be zero address!");

        // update Admin Multi-Sig Contract Address
        _AdminMultiSigContractAddress = AdminMultiSigContractAddress_;

        // update Admin Multi-Sig Contract Interface
        _AdminMultiSig = AdminMultiSigInterface(AdminMultiSigContractAddress_);

        // emit event
        emit updateAdminMultiSigContractAddressEvent(
            msg.sender,
            address(0),
            AdminMultiSigContractAddress_,
            block.timestamp
        );
    }

    //////////////////////
    ////    Events    ////
    //////////////////////

    // update ERC20 Contract Address
    event updateERC20ContractAddressEvent(
        address indexed AdminMultiSig,
        address previousERC20ContractAddress,
        address newERC20ContractAddress,
        uint256 indexed timestamp
    );

    // update Admin Multi-Sig Contract Address (only Admin)
    event updateAdminMultiSigContractAddressEvent(
        address indexed AdminMultiSig,
        address previousAdminMultiSigContractAddress,
        address indexed newAdminMultiSigContractAddress,
        uint256 indexed timestamp
    );

    // update Fee Management Contract Address
    event updateFeeManagementContractAddressEvent(
        address indexed AdminMultiSig,
        address previousFeeManagementContractAddress,
        address indexed newFeeManagementContractAddress,
        uint256 indexed timestamp
    );

    // create fee manager proposal
    event FeeManagerProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed feeManagementProposalIndex,
        string feeCategory,
        uint256 feeAmount,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute updating fee proposal
    event FeeManagerProposalExecutedEvent(
        address indexed executor,
        uint256 indexed feeManagementProposalIndex,
        string feeCategory,
        uint256 feeAmount,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // approve Fee Manager proposal
    event ApproveFeeManagerProposalEvent(
        address indexed approver,
        uint256 indexed feeManagementProposalIndex,
        string FEECATEGORY,
        uint256 FEEAMOUNT,
        uint256 EXPIRATION,
        uint256 indexed timestamp
    );

    // revoke fee manager proposal
    event revokeFeeManagerProposalEvent(
        address indexed proposer,
        uint256 indexed feeManagementProposalIndex,
        string FEECATEGORY,
        uint256 FEEAMOUNT,
        uint256 EXPIRATION,
        uint256 indexed timestamp
    );

    // create whitelist manager proposal
    event WhiteListManagerProposalCreatedEvent(
        address indexed proposer,
        uint256 indexed feeManagementProposalIndex,
        string exemptionCategory,
        string updateType,
        address account,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // execute whitelist manager proposal
    event WhitelistManagerProposalExecutedEvent(
        address indexed executor,
        uint256 indexed feeManagementProposalIndex,
        string exemptionCategory,
        string updateType,
        address account,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // Whitelist Manager proposal approved
    event ApproveWhitelistManagerProposalEvent(
        address indexed approver,
        uint256 indexed feeManagementProposalIndex,
        string exemptionCategory,
        string updateType,
        address account,
        uint256 expiration,
        uint256 indexed timestamp
    );

    // revoke whitelist manager proposal
    event revokeWhitelistManagerProposalEvent(
        address indexed proposer,
        uint256 indexed feeManagementProposalIndex,
        string exemptionCategory,
        string updateType,
        address account,
        uint256 expiration,
        uint256 indexed timestamp
    );

    /////////////////////////
    ////    Modifiers    ////
    /////////////////////////

    // only Fee Management signatories
    modifier onlyFeeManagers() {
        // require sender be a fee manager
        require(
            _AdminMultiSig.IsFeeManagementSignatory(msg.sender),
            "Fee Management Multi-Sig: Sender is not a Fee Manager Signatory!"
        );
        _;
    }

    // not Null Address
    modifier notNullAddress(address account_) {
        // require account not be the zero address
        require(
            account_ != address(0),
            "Admin Multi-Sig: Address should not be zero address!"
        );
        _;
    }

    // only Valid Category
    modifier onlyValidCategory(string memory category_) {
        // require valid category
        require(
            keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("TRANSFERFEE")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("CREATIONFEE")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("REDEMPTIONFEE")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("FEEDECIMALS")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("MINTRANSFERAMOUNT")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("MINCREATIONAMOUNT")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("MINREDEMPTIONAMOUNT")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("AUTHORIZEREDEMPTION")) ||
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("WITHDRAWCONTRACTTOKEN")),
            "Fee Management Multi-Sig: Invalid category!"
        );
        _;
    }

    // only valid Exemption Category
    modifier onlyValidExemptionCategory(string memory exemptionCategory_) {
        // require valid exemption category
        require(
            keccak256(abi.encodePacked(exemptionCategory_)) ==
                keccak256(abi.encodePacked("GLOBAL")) ||
                keccak256(abi.encodePacked(exemptionCategory_)) ==
                keccak256(abi.encodePacked("TRANSFER")) ||
                keccak256(abi.encodePacked(exemptionCategory_)) ==
                keccak256(abi.encodePacked("CREATIONREDEMPTION")),
            "Fee Management Multi-Sig: Exemption category is not valid!"
        );
        _;
    }

    // only valid exemption update type
    modifier onlyValidUpdateType(string memory updateType_) {
        // require valid update type
        require(
            keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("ADD")) ||
                keccak256(abi.encodePacked(updateType_)) ==
                keccak256(abi.encodePacked("REMOVE")),
            "Fee Management Multi-Sig: Update type is not valid!"
        );
        _;
    }

    // greater than zero value
    modifier onlyGreaterThanZero(uint256 value_) {
        // require value be greater than zero
        require(
            value_ > 0,
            "Admin Multi-Sig: Value should be greater than zero!"
        );
        _;
    }

    // only Valid Fee Management Index
    modifier onlyValidFeeManagementIndex(uint256 feeManagementProposalIndex_) {
        // require valid index
        require(
            ((feeManagementProposalIndex_ != 0) &&
                (feeManagementProposalIndex_ <= _feeManagementProposalIndex)),
            "Fee Management Multi-Sig: Invalid fee management proposal index!"
        );
        _;
    }

    // only proposer
    modifier onlyProposer(uint256 feeManagementProposalIndex_) {
        // require sender be the proposer of the proposal
        require(
            msg.sender ==
                _feeManagerProposals[feeManagementProposalIndex_].PROPOSER,
            "Fee Management Multi-Sig: Sender is not the proposer!"
        );
        _;
    }

    // only Admin Multi-Sig
    modifier onlyAdmin() {
        // require sender be admin multisig contract address
        require(
            msg.sender == _AdminMultiSigContractAddress,
            "Sender is not admin!"
        );
        _;
    }

    //////////////////////////////
    ////   Public Functions   ////
    //////////////////////////////

    // update ERC20 Contract Address
    function updateERC20ContractAddress(address ERC20ContractAddress_)
        public
        notNullAddress(ERC20ContractAddress_)
        onlyAdmin
    {
        // previous ERC20 Contract Address
        address previousERC20ContractAddress = _ERC20ContractAddress;

        // update ERC20 Contract Address
        _ERC20ContractAddress = ERC20ContractAddress_;

        // update ERC20 Contract Interface
        _ERC20 = ERC20Interface(ERC20ContractAddress_);

        // emit event
        emit updateERC20ContractAddressEvent(
            msg.sender,
            previousERC20ContractAddress,
            ERC20ContractAddress_,
            block.timestamp
        );
    }

    // update Admin Multi-Sig Contract Address
    function updateAdminMultiSigContractAddress(
        address AdminMultiSigContractAddress_
    ) public notNullAddress(AdminMultiSigContractAddress_) onlyAdmin {
        // previous Admin Multi-Sig Contract Address
        address previousAdminMultiSigContractAddress = _AdminMultiSigContractAddress;

        // update Admin Multi-Sig Contract Address
        _AdminMultiSigContractAddress = AdminMultiSigContractAddress_;

        // update Admin Multi-Sig Contract Interface
        _AdminMultiSig = AdminMultiSigInterface(AdminMultiSigContractAddress_);

        // emit event
        emit updateAdminMultiSigContractAddressEvent(
            msg.sender,
            previousAdminMultiSigContractAddress,
            AdminMultiSigContractAddress_,
            block.timestamp
        );
    }

    // update Fee Management Contract Address
    function updateFeeManagementContractAddress(
        address FeeManagementContractAddress_
    ) public notNullAddress(FeeManagementContractAddress_) onlyAdmin {
        // previous Fee Management Contract Address
        address previousFeeManagementContractAddress = _FeeManagementContractAddress;

        // update Fee Management Contract Address
        _FeeManagementContractAddress = FeeManagementContractAddress_;

        // update Fee Management Contract Interface
        _FeeManagement = FeeManagementInterface(FeeManagementContractAddress_);

        // emit event
        emit updateFeeManagementContractAddressEvent(
            msg.sender,
            previousFeeManagementContractAddress,
            FeeManagementContractAddress_,
            block.timestamp
        );
    }

    // create fee update proposal
    function createFeeUpdateProposal(
        string memory category_,
        uint256 amount_,
        uint256 expiration_
    )
        public
        onlyFeeManagers
        onlyValidCategory(category_)
        onlyGreaterThanZero(amount_)
        onlyGreaterThanZero(expiration_)
    {
        // increment fee managment proposal index
        ++_feeManagementProposalIndex;

        // create fee manager proposal
        _feeManagerProposals[_feeManagementProposalIndex] = FeeManagerProposal({
            ID: _feeManagementProposalIndex,
            PROPOSER: msg.sender,
            CATEGORY: category_,
            AMOUNT: amount_,
            ISEXECUTED: false,
            EXPIRATION: block.timestamp + expiration_,
            ISREVOKED: false,
            PROPOSEDTIMESTAMP: block.timestamp,
            EXECUTEDTIMESTAMP: 0,
            REVOKEDTIMESTAMP: 0,
            APPROVALCOUNT: 1
        });

        // approve the porposal by fee manager sender
        _feeManagerProposalApprovers[_feeManagementProposalIndex][
            msg.sender
        ] = true;

        // emit creating fee manager proposal event
        emit FeeManagerProposalCreatedEvent(
            msg.sender,
            _feeManagementProposalIndex,
            category_,
            amount_,
            expiration_,
            block.timestamp
        );

        // execute the proposal if sender is the only supply manager
        address[] memory _feeManagerSignatories = _AdminMultiSig
            .getFeeManagementSignatories();

        if (_feeManagerSignatories.length == 1) {
            // category
            if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("CREATIONFEE"))
            ) {
                // execute update creation fee order
                _FeeManagement.setCreationFee(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating creation fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("REDEMPTIONFEE"))
            ) {
                // execute update redemption fee order
                _FeeManagement.setRedemptionFee(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating redemption fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("TRANSFERFEE"))
            ) {
                // execute update transfer fee order
                _FeeManagement.setTransferFee(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating transfer fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("FEEDECIMALS"))
            ) {
                // execute setting fee decimals
                _FeeManagement.setFeeDecimals(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing setting fee decimals
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("MINTRANSFERAMOUNT"))
            ) {
                // execute set min transfer amount order
                _FeeManagement.setMinTransferAmount(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating transfer fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("MINCREATIONAMOUNT"))
            ) {
                // execute set min creation amount order
                _FeeManagement.setMinCreationAmount(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing set min creation amount proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("MINREDEMPTIONAMOUNT"))
            ) {
                // execute min redemption amount order
                _FeeManagement.setMinRedemptionAmount(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing set min redemption amount proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("AUTHORIZEREDEMPTION"))
            ) {
                // execute AUTHORIZE REDEMPTION
                _FeeManagement.authorizeRedemption(amount_);

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing authorize redemption proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(category_)) ==
                keccak256(abi.encodePacked("WITHDRAWCONTRACTTOKEN"))
            ) {
                // execute WITHDRAW CONTRACT TOKEN
                _ERC20.withdrawContractTokens();

                // update IS EXECUTED
                _feeManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                _feeManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing withdraw contract token proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    category_,
                    amount_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve fee update proposal
    function approveFeeUpdateProposal(uint256 feeManagementProposalIndex_)
        public
        onlyFeeManagers
        onlyValidFeeManagementIndex(feeManagementProposalIndex_)
    {
        // fee manager proposal info
        FeeManagerProposal storage proposal = _feeManagerProposals[
            feeManagementProposalIndex_
        ];

        // require proposal not been EXECUTED, expired, revoked or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION > block.timestamp ||
                _feeManagerProposalApprovers[feeManagementProposalIndex_][
                    msg.sender
                ]),
            "Fee Management Multi-Sig: Proposal should not be executed, expired, revoked, or approved by sender!"
        );

        // update proposal approved by fee manager sender
        _feeManagerProposalApprovers[feeManagementProposalIndex_][
            msg.sender
        ] = true;

        // update fee manager proposal approval count
        proposal.APPROVALCOUNT++;

        // emit Fee Manager proposal approved event
        emit ApproveFeeManagerProposalEvent(
            msg.sender,
            feeManagementProposalIndex_,
            proposal.CATEGORY,
            proposal.AMOUNT,
            proposal.EXPIRATION,
            block.timestamp
        );

        // execute proposal if approval count reached min signature required
        if (
            _feeManagerProposals[feeManagementProposalIndex_].APPROVALCOUNT >=
            _AdminMultiSig.getFeeManagementMinSignatures()
        ) {
            // sender execute the proposal
            // orderType
            if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("CREATION"))
            ) {
                // execute update creation fee order
                _FeeManagement.setCreationFee(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating creation fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("REDEMPTION"))
            ) {
                // execute update redemption fee order
                _FeeManagement.setRedemptionFee(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating redemption fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("TRANSFER"))
            ) {
                // execute update transfer fee order
                _FeeManagement.setTransferFee(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating transfer fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("FEEDECIMALS"))
            ) {
                // execute setting fee decimals
                _FeeManagement.setFeeDecimals(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing setting fee decimals
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("MINTRANSFERAMOUNT"))
            ) {
                // execute set min transfer amount order
                _FeeManagement.setMinTransferAmount(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating transfer fee proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("MINCREATIONAMOUNT"))
            ) {
                // execute set min creation amount order
                _FeeManagement.setMinCreationAmount(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing set min creation amount proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("MINREDEMPTIONAMOUNT"))
            ) {
                // execute min redemption amount order
                _FeeManagement.setMinRedemptionAmount(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing set min redemption amount proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("AUTHORIZEREDEMPTION"))
            ) {
                // execute AUTHORIZE REDEMPTION
                _FeeManagement.authorizeRedemption(proposal.AMOUNT);

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing authorize redemption proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.CATEGORY)) ==
                keccak256(abi.encodePacked("WITHDRAWCONTRACTTOKEN"))
            ) {
                // execute WITHDRAW CONTRACT TOKEN
                _ERC20.withdrawContractTokens();

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // update EXECUTED TIMESTAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing withdraw contract token proposal
                emit FeeManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    proposal.CATEGORY,
                    proposal.AMOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke fee update proposal
    function revokeFeeUpdateProposal(uint256 feeManagementProposalIndex_)
        public
        onlyFeeManagers
        onlyProposer(feeManagementProposalIndex_)
    {
        // fee manager proposal info
        FeeManagerProposal storage proposal = _feeManagerProposals[
            feeManagementProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired, or revoked.
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Fee Management Multi-Sig: Proposal is already executed, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update REVOKED TIMESTAMP
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeFeeManagerProposalEvent(
            msg.sender,
            feeManagementProposalIndex_,
            proposal.CATEGORY,
            proposal.AMOUNT,
            proposal.EXPIRATION,
            block.timestamp
        );
    }

    // create fee exemption proposal
    function createFeeExemptionProposal(
        string memory exemptionCategory_,
        string memory updateType_,
        address account_,
        uint256 expiration_
    )
        public
        onlyFeeManagers
        onlyValidExemptionCategory(exemptionCategory_)
        onlyValidUpdateType(updateType_)
        notNullAddress(account_)
        onlyGreaterThanZero(expiration_)
    {
        // increment fee managment proposal index
        ++_feeManagementProposalIndex;

        // create whitelist manager proposal
        _whitelistManagerProposals[
            _feeManagementProposalIndex
        ] = WhitelistManagerProposal({
            ID: _feeManagementProposalIndex,
            PROPOSER: msg.sender,
            EXEMPTIOMCATEGORY: exemptionCategory_,
            UPDATETYPE: updateType_,
            ACCOUNT: account_,
            ISEXECUTED: false,
            EXPIRATION: block.timestamp + expiration_,
            ISREVOKED: false,
            PROPOSEDTIMESTAMP: block.timestamp,
            EXECUTEDTIMESTAMP: 0,
            REVOKEDTIMESTAMP: 0,
            APPROVALCOUNT: 1
        });

        // approve the porposal by whitelist manager sender
        _whitelistManagerProposalApprovers[_feeManagementProposalIndex][
            msg.sender
        ] = true;

        // emit creating whitelist manager proposal event
        emit WhiteListManagerProposalCreatedEvent(
            msg.sender,
            _feeManagementProposalIndex,
            exemptionCategory_,
            updateType_,
            account_,
            expiration_,
            block.timestamp
        );

        // execute the proposal if sender is the only fee manager
        address[] memory _feeManagementSignatories = _AdminMultiSig
            .getFeeManagementSignatories();

        if (_feeManagementSignatories.length == 1) {
            // exemption category
            if (
                keccak256(abi.encodePacked(exemptionCategory_)) ==
                keccak256(abi.encodePacked("GLOBAL"))
            ) {
                // execute global whitelist
                if (
                    keccak256(abi.encodePacked(updateType_)) ==
                    keccak256(abi.encodePacked("ADD"))
                ) {
                    // send order
                    _FeeManagement.appendToGlobalWhitelist(account_);
                } else if (
                    keccak256(abi.encodePacked(updateType_)) ==
                    keccak256(abi.encodePacked("REMOVE"))
                ) {
                    // send order
                    _FeeManagement.removeFromGlobalWhitelist(account_);
                }

                // update IS EXECUTED
                _whitelistManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                _whitelistManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating creation fee proposal
                emit WhitelistManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    exemptionCategory_,
                    updateType_,
                    account_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(exemptionCategory_)) ==
                keccak256(abi.encodePacked("CREATIONREDEMPTION"))
            ) {
                // execute creation | redemption whitelist
                if (
                    keccak256(abi.encodePacked(updateType_)) ==
                    keccak256(abi.encodePacked("ADD"))
                ) {
                    // send order
                    _FeeManagement.appendToGlobalWhitelist(account_);
                } else if (
                    keccak256(abi.encodePacked(updateType_)) ==
                    keccak256(abi.encodePacked("REMOVE"))
                ) {
                    // send order
                    _FeeManagement.removeFromCRWhitelist(account_);
                }

                // update IS EXECUTED
                _whitelistManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                _whitelistManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating creation fee proposal
                emit WhitelistManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    exemptionCategory_,
                    updateType_,
                    account_,
                    expiration_,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(exemptionCategory_)) ==
                keccak256(abi.encodePacked("TRANSFER"))
            ) {
                // execute transfer whitelist
                if (
                    keccak256(abi.encodePacked(updateType_)) ==
                    keccak256(abi.encodePacked("ADD"))
                ) {
                    // send order
                    _FeeManagement.appendToTransferWhitelist(account_);
                } else if (
                    keccak256(abi.encodePacked(updateType_)) ==
                    keccak256(abi.encodePacked("REMOVE"))
                ) {
                    // send order
                    _FeeManagement.removeFromTransferWhitelist(account_);
                }

                // update IS EXECUTED
                _whitelistManagerProposals[_feeManagementProposalIndex]
                    .ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                _whitelistManagerProposals[_feeManagementProposalIndex]
                    .EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating creation fee proposal
                emit WhitelistManagerProposalExecutedEvent(
                    msg.sender,
                    _feeManagementProposalIndex,
                    exemptionCategory_,
                    updateType_,
                    account_,
                    expiration_,
                    block.timestamp
                );
            }
        }
    }

    // approve fee exemption proposal
    function approveFeeExemptionProposal(uint256 feeManagementProposalIndex_)
        public
        onlyFeeManagers
        onlyValidFeeManagementIndex(feeManagementProposalIndex_)
    {
        // whitelist manager proposal info
        WhitelistManagerProposal storage proposal = _whitelistManagerProposals[
            feeManagementProposalIndex_
        ];

        // require proposal not been EXECUTED, expired, revoked or approved by sender
        require(
            !(proposal.ISEXECUTED ||
                proposal.ISREVOKED ||
                proposal.EXPIRATION > block.timestamp ||
                _whitelistManagerProposalApprovers[feeManagementProposalIndex_][
                    msg.sender
                ]),
            "Fee Management Multi-Sig: Proposal should not be executed, expired, revoked, or approved by sender!"
        );

        // update proposal approved by whitelist manager sender
        _whitelistManagerProposalApprovers[feeManagementProposalIndex_][
            msg.sender
        ] = true;

        // update fee management proposal approval count
        proposal.APPROVALCOUNT++;

        // emit Fee Manager proposal approved event
        emit ApproveWhitelistManagerProposalEvent(
            msg.sender,
            feeManagementProposalIndex_,
            proposal.EXEMPTIOMCATEGORY,
            proposal.UPDATETYPE,
            proposal.ACCOUNT,
            proposal.EXPIRATION,
            block.timestamp
        );

        // execute proposal if approval count reached min signature required
        if (
            _whitelistManagerProposals[feeManagementProposalIndex_]
                .APPROVALCOUNT >= _AdminMultiSig.getFeeManagementMinSignatures()
        ) {
            // sender execute the proposal
            // exemption category
            if (
                keccak256(abi.encodePacked(proposal.EXEMPTIOMCATEGORY)) ==
                keccak256(abi.encodePacked("GLOBAL"))
            ) {
                // execute update creation fee order
                if (
                    keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
                    keccak256(abi.encodePacked("ADD"))
                ) {
                    // send order
                    _FeeManagement.appendToGlobalWhitelist(proposal.ACCOUNT);
                } else if (
                    keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
                    keccak256(abi.encodePacked("REMOVE"))
                ) {
                    // send order
                    _FeeManagement.removeFromGlobalWhitelist(proposal.ACCOUNT);
                }

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating global whitelist proposal
                emit WhitelistManagerProposalExecutedEvent(
                    msg.sender,
                    feeManagementProposalIndex_,
                    proposal.EXEMPTIOMCATEGORY,
                    proposal.UPDATETYPE,
                    proposal.ACCOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.EXEMPTIOMCATEGORY)) ==
                keccak256(abi.encodePacked("CREATIONREDEMPTION"))
            ) {
                // execute update redemption fee order
                if (
                    keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
                    keccak256(abi.encodePacked("ADD"))
                ) {
                    // send order
                    _FeeManagement.appendToCRWhitelist(proposal.ACCOUNT);
                } else if (
                    keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
                    keccak256(abi.encodePacked("REMOVE"))
                ) {
                    // send order
                    _FeeManagement.removeFromCRWhitelist(proposal.ACCOUNT);
                }

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating creation | redemption whitelist proposal
                emit WhitelistManagerProposalExecutedEvent(
                    msg.sender,
                    feeManagementProposalIndex_,
                    proposal.EXEMPTIOMCATEGORY,
                    proposal.UPDATETYPE,
                    proposal.ACCOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            } else if (
                keccak256(abi.encodePacked(proposal.EXEMPTIOMCATEGORY)) ==
                keccak256(abi.encodePacked("TRANSFER"))
            ) {
                // execute update transfer fee order
                if (
                    keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
                    keccak256(abi.encodePacked("ADD"))
                ) {
                    // send order
                    _FeeManagement.appendToTransferWhitelist(proposal.ACCOUNT);
                } else if (
                    keccak256(abi.encodePacked(proposal.UPDATETYPE)) ==
                    keccak256(abi.encodePacked("REMOVE"))
                ) {
                    // send order
                    _FeeManagement.removeFromTransferWhitelist(
                        proposal.ACCOUNT
                    );
                }

                // update IS EXECUTED
                proposal.ISEXECUTED = true;

                // UDPATE EXECUTED TIME STAMP
                proposal.EXECUTEDTIMESTAMP = block.timestamp;

                // emit executing updating transfer whitelist proposal
                emit WhitelistManagerProposalExecutedEvent(
                    msg.sender,
                    feeManagementProposalIndex_,
                    proposal.EXEMPTIOMCATEGORY,
                    proposal.UPDATETYPE,
                    proposal.ACCOUNT,
                    proposal.EXPIRATION,
                    block.timestamp
                );
            }
        }
    }

    // revoke fee exemption proposal
    function revokeFeeExemptionProposal(uint256 feeManagementProposalIndex_)
        public
        onlyFeeManagers
        onlyProposer(feeManagementProposalIndex_)
    {
        // whitelist manager proposal info
        WhitelistManagerProposal storage proposal = _whitelistManagerProposals[
            feeManagementProposalIndex_
        ];

        // require proposal not been EXECUTED already, expired, or revoked.
        require(
            !(proposal.ISEXECUTED ||
                proposal.EXPIRATION > block.timestamp ||
                proposal.ISREVOKED),
            "Fee Management Multi-Sig: Proposal is already executed, expired, or revoked!"
        );

        // revoke the proposal
        proposal.ISREVOKED = true;

        // update revoked timestamp
        proposal.REVOKEDTIMESTAMP = block.timestamp;

        // emit event
        emit revokeWhitelistManagerProposalEvent(
            msg.sender,
            feeManagementProposalIndex_,
            proposal.EXEMPTIOMCATEGORY,
            proposal.UPDATETYPE,
            proposal.ACCOUNT,
            proposal.EXPIRATION,
            block.timestamp
        );
    }

    ///   GETTER FUNCTIONS   ///

    // get admin multi sig contract address
    function getAdminMultiSigContractAddress() public view returns (address) {
        return _AdminMultiSigContractAddress;
    }

    // get max fee management proposal index
    function getMaxFeeManagementProposalIndex() public view returns (uint256) {
        return _feeManagementProposalIndex;
    }

    // get Fee Manager Proposal Detail
    function getFeeManagerProposalDetail(uint256 feeManagementProposalIndex_)
        public
        view
        returns (FeeManagerProposal memory)
    {
        return _feeManagerProposals[feeManagementProposalIndex_];
    }

    // is Fee Manger proposal approver
    function IsFeeMangerProposalApprover(
        uint256 feeManagementProposalIndex_,
        address account_
    ) public view returns (bool) {
        return
            _feeManagerProposalApprovers[feeManagementProposalIndex_][account_];
    }

    // get whitelist manager proposal detail
    function getWhitelistMangerProposalDetail(
        uint256 feeManagementProposalIndex_
    ) public view returns (WhitelistManagerProposal memory) {
        return _whitelistManagerProposals[feeManagementProposalIndex_];
    }

    // is whitelist manager proposal approvers
    function IsWhitelistManagerProposalApprovers(
        uint256 feeManagementProposalIndex_,
        address account_
    ) public view returns (bool) {
        return
            _whitelistManagerProposalApprovers[feeManagementProposalIndex_][
                account_
            ];
    }

    /////////////////////////////////
    ////   Private  Functions    ////
    /////////////////////////////////

    /////////////////////////////////
    ////   Internal Functions    ////
    /////////////////////////////////
}