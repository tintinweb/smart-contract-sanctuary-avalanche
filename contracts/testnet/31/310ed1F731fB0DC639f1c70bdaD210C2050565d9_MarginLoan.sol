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
    // function getMarginLoan(address _user, uint256 id)
    //     external
    //     view
    //     returns (
    //         uint256,
    //         address,
    //         address,
    //         uint256,
    //         uint256,
    //         LoanStatus,
    //         address,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256
    //     );

    /**
     * get t0tal of margin loan array of address
     */
    function getTotalLoans(address _user) external view returns (uint256);

    /**
     * get total number of  loan on a signle erc1400 token
     */

    function getTotalLoanOfToken(address _user, address _token)
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
        returns (uint256[] memory ids, uint256[] memory loans);
        
    function updateLoan(
        address user,
        uint256 id,
        uint256 AmountPayed,
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./IMarginLoan.sol";
import "../whitelist/ITokenismWhitelist.sol";
import "../token/ERC20/IERC1400RawERC20.sol";
import "../IStableCoin.sol";

contract MarginLoan is IMarginLoan {
    using SafeMath for uint256;
    ITokenismWhitelist _whitelist;
    IStableCoin public stableCoin; // Stable coin TKUSD used on Tokenism

    /**
    @dev LoanStatus : it will have only follwoing three values.
    @dev enum LoanStatus {NOTFOUND , PENDING , ACTIVE   , COMPLETE , REJECT , CANCEL}
     */
    
    /**
    @dev marginLoan: this mapping will store all the marginloan
         struct against its user
    @dev blockedUser maping will hold the all user blocked for loan application.
     */
    mapping(address => MarginLoan[]) public marginLoan;
    mapping (address => bool) public blockedUser;
    
    /**
     *@dev constructor :
     */
    constructor(ITokenismWhitelist _whiteListing, IStableCoin _StableCoin)
        
    {
        _whitelist = _whiteListing;
        stableCoin = _StableCoin;
    }

    modifier onlyBank() {
        require(_whitelist.isBank(msg.sender), "Only Bank is allowed");
        _;
    }

    modifier onlyAdmin() {
        require(_whitelist.isAdmin(msg.sender), "Only Admin is allowed");
        _;
    }

    ///@notice user loan amount limit is calculated based on on current token balance and loan percentage
    ///@param _bank to apply loan.
    ///@param _loanAmount amount of loan
    ///@param _interestRate rate of intrest on loan by bank
    ///@param _tokenAddress security token address of property.
    ///@param createdAt time of application of loan
    ///@param installmentAmount monthly of qurtarly amount of loan payment.
    ///@param loanPercentage Percentage of token value allowed for loan
    ///@param noOfTokens token balance of owner at the time of loan application

    function requestLoan(
        address _bank,
        uint256 _loanAmount,
        uint256 _interestRate,
        address _tokenAddress,
        uint256 createdAt,
        uint256 installmentAmount,
        uint256 loanPercentage,
        uint256 noOfTokens
    ) public override {
        MarginLoan memory newMarginLoan;
        IERC1400RawERC20 IERCtoken = IERC1400RawERC20(_tokenAddress);
        uint256 whitelistStatus = _whitelist.isWhitelistedUser(msg.sender);
        require(whitelistStatus < 399, "you are not whitelisted user");
        require(_whitelist.isBank(_bank), "Bank is not whitelisted");
        require(
            Address.isContract(_tokenAddress),
            "required erc1400 token address"
        );
        require(
            isBlockedUser(msg.sender) == false, 
            "You are blocked from applying for a loan"
        );
         (uint256 previousLoan,) =  getLoan(msg.sender,_tokenAddress);
         uint256 newLoan = previousLoan.add(_loanAmount);
         require(
            newLoan <= getRemainingLoanLimit(msg.sender,_tokenAddress,loanPercentage),
            "Loan amount exceeds loan limit"
        );
         require(
            newLoan <= getLoanLimit(msg.sender,_tokenAddress, loanPercentage),
            "Loan amounts should not exceed the loan limit"
        );
         require(
            stableCoin.allowance(_bank, address(this)) >=
                newMarginLoan.loanAmount,
            "Bank should allow contract to spend Token"
        );
        newMarginLoan.bank = _bank;
        newMarginLoan.loanAmount = _loanAmount;
        newMarginLoan.interestRate = _interestRate;
        newMarginLoan.status = LoanStatus.ACTIVE;
        newMarginLoan.user = msg.sender;
        newMarginLoan.tokenAddress = _tokenAddress;
        newMarginLoan.createdAt = createdAt;
        newMarginLoan.installmentAmount = installmentAmount;
        newMarginLoan.noOfTokens = noOfTokens;
        newMarginLoan.loanLimit = getLoanLimit(msg.sender, _tokenAddress, loanPercentage);
        newMarginLoan.loanPercentage = loanPercentage;
        
        marginLoan[msg.sender].push(newMarginLoan);
         
        stableCoin.transferFrom(
             newMarginLoan.bank,
            newMarginLoan.user,
            newMarginLoan.loanAmount
        );
        emit LoanRequest(
            msg.sender,
            newMarginLoan.bank,
            newMarginLoan.loanAmount,
            newMarginLoan.interestRate,
            newMarginLoan.status,
            newMarginLoan.tokenAddress,
            newMarginLoan.createdAt,
            newMarginLoan.installmentAmount,
            marginLoan[msg.sender].length - 1,
            newMarginLoan.loanPercentage,
            newMarginLoan.noOfTokens
        );
    }

    /**
    @notice it complete the current loan.
    @param _user address of borrower
    @param _id active loan id 
    @dev only admin can call this fucntion
     */

    function completeLoan(address _user, uint256 _id)
        public
        override
        onlyAdmin
        returns (bool)
    {
        MarginLoan storage newMarginLoan = marginLoan[_user][_id];

        newMarginLoan.status = LoanStatus.COMPLETE;
        emit UpdateLoan(_user, _id, newMarginLoan.status);
        return true;
    }

    /**
    @notice if user fail to pay back loan it transfer use token to bank and set status to pledge.
    @param _user address of borrower
    @param _bank address of lender bank
    @param _tokenAddress property token adddress
    @dev only admin can call this fucntion
     */

    function pledgeLoanToken(address _user,address _tokenAddress, address _bank)
        public
        override
        onlyAdmin
        returns (bool)
    {
        MarginLoan storage newMarginLoan;
        uint256 loanLength = marginLoan[_user].length;
        IERC1400RawERC20 IERCtoken = IERC1400RawERC20(_tokenAddress);
        uint256 balanceOfuser = IERCtoken.balanceOf(_user); 

        for (uint256 i = 0; i < loanLength;) {
             newMarginLoan = marginLoan[_user][i];
            if (
                newMarginLoan.tokenAddress == _tokenAddress &&
                newMarginLoan.bank == _bank &&
                newMarginLoan.status == LoanStatus.ACTIVE
            ) {
                newMarginLoan.status = LoanStatus.PLEDGE;
                newMarginLoan.noOfTokens = balanceOfuser;
            }
            unchecked {
                i++ ;
            }
        }
        IERCtoken.transferFrom(_user, _bank, balanceOfuser);
        emit PledgeToken(_user, _tokenAddress,balanceOfuser, LoanStatus.PLEDGE);
        return true;
        
    }
    /**
    @notice it retun the total amount of all loan and number of loan n pledged token amount of laon.
    it also return the total amount of interest on loan
    @param _user address of borrower
    @param _bank address of lender bank
    @param tokenAddress property token adddress
    @return returns the plaedge details of specific bank user and property.
     */

    function getPledgedLoan(address _user,address tokenAddress, address _bank)
        public
        view
        override
        returns (uint256, uint256, uint256, uint256)
    {
        uint256 loanLength = marginLoan[_user].length;
        uint256 loans = 0;
        uint256 loanAmount = 0;
        uint256 tokensAmount = 0;
        uint256 interestAmount = 0;
        for (uint256 i = 0; i < loanLength; i++) {
            MarginLoan storage newMarginLoan = marginLoan[_user][i];
            if (
                newMarginLoan.tokenAddress == tokenAddress &&
                newMarginLoan.bank == _bank &&
                newMarginLoan.status == LoanStatus.PLEDGE
            ) {
                loanAmount += newMarginLoan.loanAmount;
                tokensAmount = newMarginLoan.noOfTokens;
                uint256 annualInterest = (newMarginLoan.loanAmount.mul(newMarginLoan.interestRate)).div(100);
                interestAmount += annualInterest.mul(90).div(360);
                loans++;  
            }
        }
            return (loans,loanAmount,tokensAmount, interestAmount);
    }

    /**
    @return it return the active loan amount and total tokens of loan of specific user..
    @param _user address of borrower
    @param tokenAddress property token adddress
     */

    function getLoan(address _user,address tokenAddress)
        public
        view
        override
        returns (uint256, uint256)
    {
        uint256 loanLength = marginLoan[_user].length;
        uint256 activeLoans = 0;
        uint256 loanAmount = 0;
        for (uint256 i = 0; i < loanLength; i++) {
            MarginLoan storage newMarginLoan = marginLoan[_user][i];
            if (
                newMarginLoan.tokenAddress == tokenAddress &&
                newMarginLoan.status == LoanStatus.ACTIVE
            ) {
                loanAmount += newMarginLoan.loanAmount;
                activeLoans++;   

            }
        }
            return (activeLoans,loanAmount);
    }

    /**
    @notice it return the loan current status of given user.
    @param _user address of borrower
    @param _id address of lender bank
     */

    function getLoanStatus(address _user, uint256 _id)
        public
        override
        view
        returns (uint256)
    {
        MarginLoan storage newMarginLoan = marginLoan[_user][_id];
        if (newMarginLoan.status == LoanStatus.NOTFOUND) return 0;
        if (newMarginLoan.status == LoanStatus.PENDING) return 1;
        if (newMarginLoan.status == LoanStatus.ACTIVE) return 2;
        if (newMarginLoan.status == LoanStatus.COMPLETE) return 3;
        if (newMarginLoan.status == LoanStatus.REJECT) return 4;
        if (newMarginLoan.status == LoanStatus.CANCEL) return 5;
    }

    /**
    @notice it cancel the current active loan and update status
    @param _id address of borrower
     */

    function cancelLoan(uint256 _id) public override returns (bool) {
        MarginLoan storage newMarginLoan = marginLoan[msg.sender][_id];
        require(
            newMarginLoan.user == msg.sender,
            "you are not allowed to update status of loan"
        );
        newMarginLoan.status = LoanStatus.CANCEL;
        emit UpdateLoan(msg.sender, _id, newMarginLoan.status);
        return true;
    }

    /**
    @return it return the compelete details of given loan ofr user.
    @param _user address of borrower
    @param _id address of lender bank
     */

    // function getMarginLoan(address _user, uint256 id)
    //     external
    //     override
    //     view
    //     returns (            
    //         uint256,
    //         address,
    //         address,
    //         uint256,
    //         uint256,
    //         LoanStatus,
    //         address,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256,
    //         uint256    )
    // {
    //     MarginLoan storage newMarginLoan = marginLoan[_user][id];
    //     return (
    //         id,
    //         newMarginLoan.user,
    //         newMarginLoan.bank,
    //         newMarginLoan.loanAmount,
    //         newMarginLoan.interestRate,
    //         newMarginLoan.status,
    //         newMarginLoan.tokenAddress,
    //         newMarginLoan.createdAt,
    //         newMarginLoan.loanLimit,
    //         newMarginLoan.installmentAmount,
    //         newMarginLoan.loanPercentage,
    //         newMarginLoan.noOfTokens
    //     );
    // }

    /**
    @notice it retun the total number of loans of given user.
    @param _user address of borrower
     */

    function getTotalLoans(address _user) override public view returns (uint256) {
        return marginLoan[_user].length;
    }

    /**
    @notice it return the loan details of user gainsgt specific property.
    @return banks of lender banks
    @return loanAmounts of loan amounts 
    @return interestRates of interest rate against each loan
    @return createdAts of dates at which is loan received.
    @param _user address of borrower
    @param _token property token adddress
     */

    function getTotalLoanOfToken(address _user, address _token)
        external
        override
        view
        returns (
            address[] memory banks,
            uint256[] memory loanAmounts,
            uint256[] memory interestRates,
            uint256[] memory createdAts
        )
    {
        uint8 newLoanLength = getLoansLength(_user, _token);
        address[] memory banks = new address[](newLoanLength);
        uint256[] memory loanAmounts = new uint256[](newLoanLength);
        uint256[] memory interestRates = new uint256[](newLoanLength);
        uint256[] memory createdAts = new uint256[](newLoanLength);
        uint8 count = 0;
        for (uint8 i = 0; i < marginLoan[_user].length; i++) {
            MarginLoan memory newMarginLoan = marginLoan[_user][i];
            if (
                newMarginLoan.tokenAddress == _token &&
                newMarginLoan.status == LoanStatus.ACTIVE
            ) {
                banks[count] = newMarginLoan.bank;
                loanAmounts[count] = newMarginLoan.loanAmount;
                interestRates[count] = newMarginLoan.interestRate;
                createdAts[count] = newMarginLoan.createdAt;
                count += 1;
            }
        }
        return (banks, loanAmounts, interestRates, createdAts);
    }

    function getTotalLoanOfPledgedToken(address _user, address _token, address _bank)
        external
        override
        view
        returns (
            address[] memory banks,
            uint256[] memory loanAmounts,
            uint256[] memory interestRates
        )
    {
        uint8 newLoanLength = getPledgeLoansLength(_user, _token, _bank);
        address[] memory banks = new address[](newLoanLength);
        uint256[] memory loanAmounts = new uint256[](newLoanLength);
        uint256[] memory interestRates = new uint256[](newLoanLength);
        uint8 count = 0;
        for (uint8 i = 0; i < marginLoan[_user].length; i++) {
            MarginLoan memory newMarginLoan = marginLoan[_user][i];
            if (
                newMarginLoan.tokenAddress == _token &&
                newMarginLoan.status == LoanStatus.PLEDGE &&
                newMarginLoan.bank == _bank 
            ) {
                banks[count] = newMarginLoan.bank;
                loanAmounts[count] = newMarginLoan.loanAmount;
                interestRates[count] = newMarginLoan.interestRate;
                count += 1;
            }
        }
        return (banks, loanAmounts, interestRates);
    }

    /**
    @notice return active loans and its ids;
    @param _user address of borrower
    @param _token address property token
     */

    function getTotalNoOfTokens(address _user, address _token)
        external
        override
        view
        returns (uint256[] memory ids, uint256[] memory loans)
    {
        uint256[] memory loans = new uint256[](getLoansLength(_user, _token));
        uint256[] memory ids = new uint256[](getLoansLength(_user, _token));

        uint8 count = 0;
        for (uint8 i = 0; i < marginLoan[_user].length; i++) {
            MarginLoan memory newMarginLoan = marginLoan[_user][i];
            if (
                newMarginLoan.tokenAddress == _token &&
                newMarginLoan.status == LoanStatus.ACTIVE
            ) {
                loans[count] = newMarginLoan.loanAmount;
                ids[count] = i;
                count += 1;
            }
        }
        return (ids, loans);
    }
    function getTotalNoOfPledgeTokens(address _user, address _token, address _bank)
        external
        override
        view
        returns (uint256[] memory ids, uint256[] memory loans)
    {
        uint256[] memory loans = new uint256[](getPledgeLoansLength(_user, _token, _bank));
        uint256[] memory ids = new uint256[](getPledgeLoansLength(_user, _token, _bank));

        uint8 count = 0;
        for (uint8 i = 0; i < marginLoan[_user].length; i++) {
            MarginLoan memory newMarginLoan = marginLoan[_user][i];
            if (
                newMarginLoan.tokenAddress == _token &&
                newMarginLoan.status == LoanStatus.PLEDGE &&
                newMarginLoan.bank == _bank
            ) {
                loans[count] = newMarginLoan.loanAmount;
                ids[count] = i;
                count += 1;
            }
        }
        return (ids, loans);
    }

    /**
    @notice it return the active loans length
    @param _user address of borrower
    @param _token address of lender bank
     */

    function getLoansLength(address _user, address _token)
        internal
        view
        returns (uint8)
    {
        uint8 loanLength = uint8(marginLoan[_user].length);
        uint8 count = 0;
        for (uint8 i = 0; i < loanLength; i++) {
            MarginLoan storage newMarginLoan = marginLoan[_user][i];
            if (
                newMarginLoan.tokenAddress == _token &&
                newMarginLoan.status == LoanStatus.ACTIVE
            ) {
                count += 1;
            }
        }
        return count;
    }
     function getPledgeLoansLength(address _user, address _token, address _bank)
        internal
        view
        returns (uint8)
    {
        uint8 loanLength = uint8(marginLoan[_user].length);
        uint8 count = 0;
        for (uint8 i = 0; i < loanLength; i++) {
            MarginLoan storage newMarginLoan = marginLoan[_user][i];
            if (
                newMarginLoan.tokenAddress == _token &&
                newMarginLoan.status == LoanStatus.PLEDGE &&
                newMarginLoan.bank == _bank
            ) {
                count += 1;
            }
        }
        return count;
    }

     /**
    @notice it update the loan status after call of pay loan function in exchange
    @param user address of borrower
    @param id of the loan
    @param AmountPayed amount of the loan that is paid in pay loan method
    @param caller it will be 2 if the amount received is less than loan amount.
    @dev 1 if the loan amount is less tah amount received. 2 if loan greater than amount received
     */

    function updateLoan(
        address user,
        uint256 id,
        uint256 AmountPayed,
        uint256 caller
    ) external override onlyAdmin {
        MarginLoan storage newMarginLoan = marginLoan[user][id];
        if (caller == 2) {
            newMarginLoan.loanAmount = AmountPayed;

        } else if (caller == 1) {
            newMarginLoan.loanAmount = 0;
            newMarginLoan.status = LoanStatus.COMPLETE;
        }
    }

    ///@notice Destruct  MArgin Loan Contract Address

    function closeMarginLoan() public {
        //onlyOwner is custom modifier
        require(
            _whitelist.isSuperAdmin(msg.sender),
            "Only SuperAdmin can destroy Contract"
        );
        selfdestruct(payable(msg.sender)); // `admin` is the admin address
    }

    /**
    @notice it will block the user from applying loan.
    @param _user user that  will be blocked.
     */

    function addBlockedUser(address _user) external override onlyAdmin {

        uint256 whitelistStatus = _whitelist.isWhitelistedUser(_user);
        require(whitelistStatus < 399, "you are not whitelisted user");

        blockedUser[_user] = true;
    }

        /**
    @notice it will remove the blocked user from applying loan.
    @param _user user that  will be removed from block list
     */

    function removeBlockedUser(address _user) external override onlyAdmin {

        uint256 whitelistStatus = _whitelist.isWhitelistedUser(msg.sender);
        require(whitelistStatus < 399, "you are not whitelisted user");

        blockedUser[_user] = false;
    }
    
     /**
    @notice check the block status of user from apply loan.
    @param _user status of user.
     */

    function isBlockedUser(address _user) public override view  returns(bool) {

       bool blocked = blockedUser[_user];
       return blocked;
    }

     /**
    @notice A user's loan limit is determined by the number of property tokens he holds.
    @param _user user of of loan limit check.
    @param _tokenAddress .property token address of user.
    @param _loanPercentage  Percentage of token value allowed for loan
    @return loanLimit of user.
     */

    function getLoanLimit(address _user, address _tokenAddress, uint256 _loanPercentage) view public override returns (uint256){
        require(
            Address.isContract(_tokenAddress),
            "required erc1400 token address"
        );
        IERC1400RawERC20 IERCtoken = IERC1400RawERC20(_tokenAddress);
         
        uint256 balanceOfuser = IERCtoken.balanceOf(_user); 

        uint256 loanLimit = (balanceOfuser.mul(1000 ether)).mul(_loanPercentage).div(100);
        return loanLimit;   
    }

    /**
    @notice it will return the remaining loan limit if user has previously taken out a loan.
    @param _user user of of loan limit check.
    @param _tokenAddress .property token address of user.
    @param _loanPercentage  Percentage of token value allowed for loan
    @return remainingLoanLimit of user.
     */

    function getRemainingLoanLimit( address _user,address _tokenAddress, uint256 _loanPercentage) view public override returns ( uint256){
        require(
            Address.isContract(_tokenAddress),
            "required erc1400 token address"
        );
        uint256 whitelistStatus = _whitelist.isWhitelistedUser(_user);
        require(whitelistStatus < 399, "you are not whitelisted user");
        
        uint256 loanLimit = getLoanLimit(_user, _tokenAddress, _loanPercentage);
        ( , uint256 currentLoan) = getLoan(_user, _tokenAddress);

        uint256 remianingLimit = loanLimit.sub(currentLoan);

        return (remianingLimit);    
    }


    function payPledgeLoan(address _user,address _tokenAddress, address _bank)
        public
        override
        returns (bool)
    {
        MarginLoan storage newMarginLoan;
        uint256 loanLength = marginLoan[_user].length;
        for (uint256 i = 0; i < loanLength;) {
             newMarginLoan = marginLoan[_user][i];
            if (
                newMarginLoan.tokenAddress == _tokenAddress &&
                newMarginLoan.bank == _bank &&
                newMarginLoan.status == LoanStatus.PLEDGE
            ) {
                newMarginLoan.status = LoanStatus.COMPLETE;
                // newMarginLoan.noOfTokens = 0;
                // newMarginLoan.loanAmount = 0;
            }
            unchecked {
                i++ ;
            }
        }
        return true;
        
    }
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