/**
 *Submitted for verification at snowtrace.io on 2023-04-22
*/

// SPDX-License-Identifier: WTFPL


// = = = = = = = = = = = = = = = = = //
//                                   //
//   Written by Triple Confirmation  //
//                                   //
//           20 April 2023           //
// = = = = = = = = = = = = = = = = = //


pragma solidity ^0.8.19;


/**
 * @dev OpenZeppelin's IERC20 interface with `value` -> `amount`
 */
interface IERC20 {

    // ### VIEW FUNCTIONS ###
    function name() external view returns (string memory name);

    function symbol() external view returns (string memory symbol);

    function decimals() external view returns (uint8 decimals);

    function totalSupply() external view returns (uint totalSupply);




    // ### CONTRACT INTERACTIONS ###
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint balance);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint amount) external returns (bool success);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint allowance);

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
    function approve(address spender, uint amount) external returns (bool success);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint amount) external returns (bool success);




    // ### EVENTS ###
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `amount` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint amount);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `amount` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint amount);

}




/**
 * @dev
 * File level variables are compiled into the contract as constant uints.
 * This method of variable management helps to reduce bytecode size while
 * reducing the likelihood of mistakes. Rather than writing out the exact
 * index or static numbers, we opt for referencing these file level constants
 * thereby making any adjustments immediate and ubiquitous across the entire
 * contract code. Having a central registry for constant numbers ensures
 * consistency across the codebase and is therefore good code management.
 */

/**
 * @dev Indices related to `allowances` and the `approve()` system.
 */
uint8 constant lenAMem = 4; // needs to include `aTimeRemaining`
uint8 constant lenAStor = 3;
uint8 constant aAllowance = 0;
uint8 constant aTimestamp = 1;
uint8 constant aPerpetual = 2;
uint8 constant aTimeRemaining = 3;

/**
 * @dev
 * All `uint8 constant` variables below at the file level are index identifiers
 * allowing certain variables to be grouped together in arrays for easier
 * storage, recall, mutability, and recursion.
 */
uint8 constant rAmount = 0;
uint8 constant rAccountsToRain = 1;

/**
 * @dev Indices related to the `delegationMem` pseudo-struct mapping.
 */
uint8 constant lenDelegationMem = 4;
uint8 constant encodedDelegation = 0;
uint8 constant startIndex = 1;
uint8 constant total = 2;
uint8 constant excluded = 3;

/**
 * @dev
 * Indices related to recall of `bytes32` encodes of
 * supported Delegation `functionName`s given by a
 * user to identify the function delegated.
 */
uint8 constant lenDelegates = 5;
uint8 constant dFuncSetId = 0;
uint8 constant dFuncTransferMultiple = 1;
uint8 constant dFuncRain = 2;
uint8 constant dFuncRainList = 3;
uint8 constant dFuncRainAll = 4;

/**
 * @dev Indices related to the `errors` array of `string`s.
 */
uint8 constant lenErrors = 34;
uint8 constant errSymbol = 0;
uint8 constant errAdminAuth = 1;
uint8 constant errTreasuryAdminAuth = 2;
uint8 constant errGuardianTreasuryAdminAuth = 3;
uint8 constant errInsufficientBalance = 4;
uint8 constant errTransferContract = 5;
uint8 constant errInsufficientAllowance = 6;
uint8 constant errTransferMultiple = 7;
uint8 constant errList = 8;
uint8 constant errDelegateSetId = 9;
uint8 constant errSetId = 10;
uint8 constant errSetIdProtected = 11;
uint8 constant errSetAdmin0 = 12;
uint8 constant errSetAdmin1 = 13;
uint8 constant errSetTreasury0 = 14;
uint8 constant errSetTreasury1 = 15;
uint8 constant errSetGasPerLoop = 16;
uint8 constant errSetGasValues = 17;
uint8 constant errSetBreakAtGasThres = 18;
uint8 constant errSetRainMinBalance = 19;
uint8 constant errPermit0 = 20;
uint8 constant errPermitDeadline = 21;
uint8 constant errPermitBadSig = 22;
uint8 constant errGasPerLoopHeader = 23;
uint8 constant errGasPerLoop = 24;
uint8 constant errRainAmounts = 25;
uint8 constant errRainNumAccounts = 26;
uint8 constant errRunMyDelegation = 27;
uint8 constant errAuthMyDelegation = 28;
uint8 constant errDelegationDoesntMatch = 29;
uint8 constant errInvalidDelegation = 30;
uint8 constant errClaimERC20 = 31;
uint8 constant errDecreaseAllowance = 32;
uint8 constant errSetAllowanceTimeToLive = 33;

/**
 * @dev 
 * `__denominator` is copied to `denominator` in the TokenBase.
 * We opted to hardcode the `decimals` as 10 ** 6 to allow for
 * use in assembly{} operations.
 */
uint constant __denominator = 1000000;
uint constant __denominatorBy10 = __denominator / 10;
uint constant __maxRainThreshold = 4200690000;
uint constant __minSecsAllowanceTimeToLive = 30;
string constant __strPeriod = ".";
string constant __strZero = "0";

/**
 * @notice
 * Disconnected library for deployment in a Web3xx VM such as in the
 * Remix IDE to allow us to easily harvest a array of error
 * strings to copy into TokenBase via repeated `setError()` executions.
 * This methodology doesn't import bytecode on construction and saves
 * an immense amount of bytecode compared to including the errors in
 * the TokenBase contract itself.
 */
abstract contract TokenBaseUtils {

    // ### UTILITY FUNCTIONS ###
    function _isContract(address _account) internal view returns (bool) {
        /**
         * @dev
         * According to EIP-1052, 0x0 is the value returned
         * for not-yet-created accounts and
         * 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470
         * is returned for accounts without code such as `keccak256('')`.
         */
        bytes32 _codehash;
        bytes32 _accountHash =
            0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { _codehash := extcodehash(_account) }

        /**
         * @dev
         * Return true if the `_account` in question has both:
         *   # Been created, AND
         *   # Is an address with bytecode.
         */
        return _codehash != _accountHash && _codehash != 0x0;
    }

    /**
     * @return -> Raw number without consideration to decimal places.
     */
    function __uintToString(
        uint __value
    ) internal pure returns (
        string memory
    ) {
        // Save gas and return a constant string of "0" if the `_value` == 0.
        if (__value == 0) {
            return __strZero;
        }
        uint __temp = __value;
        uint __digits;
        while (__temp != 0) {
            ++__digits;
            __temp /= 10;
        }
        bytes memory __buffer = new bytes(__digits);
        while (__value != 0) {
            __buffer[--__digits] = bytes1(uint8(48 + uint(__value % 10)));
            __value /= 10;
        }

        return string(__buffer);
    }
    
    /**
     * @notice
     * `_divisor` is safely set to 1 if 0 is given in order to avoid
     * division-by-0 errors. Division by 1 is highly likely to
     * be the desired outcome since that simply returns the same
     * number as before the division operation. `divisor`s other
     * than 0 can be returned as-is without change since we only
     * need to protect against returning a 0 `_divisor`. Less than 0
     * `_divisor`s are impossible to return since `uint`s are
     * by definition always 0 or positive.
     */
    function _safeDivision(uint _divisor) internal pure returns (uint) {
        if (_divisor == 0) {
            return 1;
        }
        return _divisor;
    }

    /**
     * @dev Converts a `uint` to its ASCII `string` decimal representation.
     * @param _value -> Any number which the user desires to convert into `string`.
     * @return -> Nicely formatted string output WITH decimal places.
     */
    function _uintToString(
        uint _value
    ) internal pure returns (
        string memory
    ) {
        // Save gas and return a constant string of "0" if the `_value` == 0.
        if (_value == 0) {
            return __strZero;
        }
        /**
         * @dev
         * We need to use assembly to achieve a proper,
         * non-overflowing modulo.
         */
        uint _decimalToShow;
        assembly { _decimalToShow := mod(_value, __denominator) }

        /**
         * @dev
         * Next generate the decimals string,
         * fixed to the number of `decimalToShow`.
         */
        string memory _strDecimals = __uintToString(_decimalToShow);

        /**
         * @dev
         * Continue adding padded 0's to the beginning of the `strDecimals`
         * until the desired number of `decimalsToShow` is achieved.
         * If we didn't do this, then an expected output of
         * 1234.0056 would be outputted as 1234.56.
         */
        if (_decimalToShow > 0) {
            for (; _decimalToShow < __denominatorBy10; _decimalToShow *= 10) {
                _strDecimals = string.concat(__strZero, _strDecimals);
            }
        }

        // Before returning, assemble the string.
        return string.concat(
            __uintToString(_value / __denominator),
            __strPeriod,
            _strDecimals
        );
    }
}

/**
 * @dev
 * Got a strange error message from Etherscan about this being imported
 * when it's very clearly not. This library definitely isn't included
 * in TokenBase but is derivative and very much related, hence why
 * it's included in this source file. We'll leave uncommented for now
 * and simply re-comment if Snowtrace/Etherscan refuses to compile
 * and verify the bytecode after mainnet deployment.
 */
contract TokenBaseErrors is TokenBaseUtils {
    /**
     * @return _errors -> Formatted for recursively passing into `setError()`.
     * @dev Throw into Remix IDE to copy-paste the generated Errors.
     */
    function generateErrors(
        string calldata _symbol
    ) external pure returns (
        string[lenErrors] memory _errors
    ) {
        string memory __symbol = string.concat(" ", _symbol, ".");
        _errors = [
            "",
            "AUTH: Sender must be the Admin Wallet.",
            "AUTH: Sender must be either the Treasury Wallet or the Admin Wallet.",
            "AUTH: Sender must be the Guardian Wallet, the Treasury Wallet, or the Admin Wallet.",
            "TRANSFER: Insufficient balance: ",
            "TRANSFER: Use `transferFrom()` to transfer tokens to a smart contract.",
            "TRANSFER-FROM: Insufficient `approve()` amount remaining: ",
            "TRANSFER-MULTIPLE: Count of recipients and amounts must be identical.",
            "LIST: First index cannot be greater than the last index.",
            "DELEGATE SET-ID: Count of recipients and amounts must be identical.",
            "SET: `id` disallowed for `account`.",
            "SET: `id` is protected.",
            "SET: New Admin Wallet cannot be set to a null address.",
            "SET: New Admin Wallet cannot be the same as the current one.",
            "SET: New Treasury Wallet cannot be set to a null address.",
            "SET: New Treasury Wallet cannot be the same as the current one.",
            "SET: `gasPerLoop` cannot be greater than 1/20 the `block.gaslimit`.",
            "SET: `breakAtGasThreshold` must be a greater value than `gasPerLoop`.",
            "SET: `breakAtGasThreshold` cannot be greater than 1/4 the `block.gaslimit`.",
            string.concat(
                "SET: Maximum possible value of ",
                _uintToString(__maxRainThreshold),
                __symbol
            ),
            "PERMIT ERROR: The 0 address cannot permit others.",
            "PERMIT ERROR: Expired deadline.",
            "PERMIT ERROR: Invalid signature.",
            "GAS: Submit with ",
            "",
            "RAIN: Invalid `amounts` provided.",
            "RAIN: Must rain on at least 1 account.",
            "DELEGATION: Null address are disallowed from execution.",
            "DELEGATION: You're not the delegate or owner.",
            "DELEGATION: No match found.",
            "DELEGATION: Unsupported function.",
            "CLAIM ERC-20: Failed transfer.",
            "DECREASE ALLOWANCE: Amount to deduct is greater than existing `approve()` amount: ",
            string.concat(
                "APPROVE DEADLINE: Minimum possible value is ",
                __uintToString(__minSecsAllowanceTimeToLive),
                " seconds. ",
                "Maximum possible value is 2^248."
            )
        ];

        for (uint8 i; i < lenErrors; ++i) {
            _errors[i] = string.concat(_symbol, " | ", _errors[i]);
        }

        // Two exceptions in the list.
        _errors[errSymbol] = __symbol;
        delete _errors[errGasPerLoop];
        
        return _errors;
    }
}

/**
 * @notice
 * Everything in this comment box is related to generating the
 * error `string`s for saving during token deployment.
 * 
 * @devnote
 * Outputted `_errors` array ready for use in TokenBase's `constructor()`.
    [
        " TC.",
        "TC | AUTH: Sender must be the Admin Wallet.",
        "TC | AUTH: Sender must be either the Treasury Wallet or the Admin Wallet.",
        "TC | AUTH: Sender must be the Guardian Wallet, the Treasury Wallet, or the Admin Wallet.",
        "TC | TRANSFER: Insufficient balance: ",
        "TC | TRANSFER: Use `transferFrom()` to transfer tokens to a smart contract.",
        "TC | TRANSFER-FROM: Insufficient `approve()` amount remaining: ",
        "TC | TRANSFER-MULTIPLE: Count of recipients and amounts must be identical.",
        "TC | LIST: First index cannot be greater than the last index.",
        "TC | DELEGATE SET-ID: Count of recipients and amounts must be identical.",
        "TC | SET: `id` disallowed for `account`.",
        "TC | SET: `id` is protected.",
        "TC | SET: New Admin Wallet cannot be set to a null address.",
        "TC | SET: New Admin Wallet cannot be the same as the current one.",
        "TC | SET: New Treasury Wallet cannot be set to a null address.",
        "TC | SET: New Treasury Wallet cannot be the same as the current one.",
        "TC | SET: `gasPerLoop` cannot be greater than 1/20 the `block.gaslimit`.",
        "TC | SET: `breakAtGasThreshold` must be a greater value than `gasPerLoop`.",
        "TC | SET: `breakAtGasThreshold` cannot be greater than 1/4 the `block.gaslimit`.",
        "TC | SET: Maximum possible value of 4200.690000 TC.",
        "TC | PERMIT ERROR: The 0 address cannot permit others.",
        "TC | PERMIT ERROR: Expired deadline.",
        "TC | PERMIT ERROR: Invalid signature.",
        "TC | GAS: Submit with ",
        "",
        "TC | RAIN: Invalid `amounts` provided.",
        "TC | RAIN: Must rain on at least 1 account.",
        "TC | DELEGATION: Null address are disallowed from execution.",
        "TC | DELEGATION: You're not the delegate or owner.",
        "TC | DELEGATION: No match found.",
        "TC | DELEGATION: Unsupported function.",
        "TC | CLAIM ERC-20: Failed transfer.",
        "TC | DECREASE ALLOWANCE: Amount to deduct is greater than existing `approve()` amount: ",
        "TC | APPROVE DEADLINE: Minimum possible value is 30 seconds. Maximum possible value is 2^248."
	];
    [
        " TCC.",
        "TCC | AUTH: Sender must be the Admin Wallet.",
        "TCC | AUTH: Sender must be either the Treasury Wallet or the Admin Wallet.",
        "TCC | AUTH: Sender must be the Guardian Wallet, the Treasury Wallet, or the Admin Wallet.",
        "TCC | TRANSFER: Insufficient balance: ",
        "TCC | TRANSFER: Use `transferFrom()` to transfer tokens to a smart contract.",
        "TCC | TRANSFER-FROM: Insufficient `approve()` amount remaining: ",
        "TCC | TRANSFER-MULTIPLE: Count of recipients and amounts must be identical.",
        "TCC | LIST: First index cannot be greater than the last index.",
        "TCC | DELEGATE SET-ID: Count of recipients and amounts must be identical.",
        "TCC | SET: `id` disallowed for `account`.",
        "TCC | SET: `id` is protected.",
        "TCC | SET: New Admin Wallet cannot be set to a null address.",
        "TCC | SET: New Admin Wallet cannot be the same as the current one.",
        "TCC | SET: New Treasury Wallet cannot be set to a null address.",
        "TCC | SET: New Treasury Wallet cannot be the same as the current one.",
        "TCC | SET: `gasPerLoop` cannot be greater than 1/20 the `block.gaslimit`.",
        "TCC | SET: `breakAtGasThreshold` must be a greater value than `gasPerLoop`.",
        "TCC | SET: `breakAtGasThreshold` cannot be greater than 1/4 the `block.gaslimit`.",
        "TCC | SET: Maximum possible value of 4200.690000 TCC.",
        "TCC | PERMIT ERROR: The 0 address cannot permit others.",
        "TCC | PERMIT ERROR: Expired deadline.",
        "TCC | PERMIT ERROR: Invalid signature.",
        "TCC | GAS: Submit with ",
        "",
        "TCC | RAIN: Invalid `amounts` provided.",
        "TCC | RAIN: Must rain on at least 1 account.",
        "TCC | DELEGATION: Null address are disallowed from execution.",
        "TCC | DELEGATION: You're not the delegate or owner.",
        "TCC | DELEGATION: No match found.",
        "TCC | DELEGATION: Unsupported function.",
        "TCC | CLAIM ERC-20: Failed transfer.",
        "TCC | DECREASE ALLOWANCE: Amount to deduct is greater than existing `approve()` amount: ",
        "TCC | APPROVE DEADLINE: Minimum possible value is 30 seconds. Maximum possible value is 2^248."
	];
*/




// ------------------------------------------------------------------------------------ //

/**
 * @title TokenBase for deployment as the "Triple Confirmation" token.
 * @notice This token contract is ERC-20 and EIP-2612 compatible.
 * 
 * @notice
 * The size of this TokenBase contract allows for up to
 * 42,000 optimizsation runs. More runs than this doesn't
 * seem to produce a meaningful difference in the bytecode
 * size and thus likely doesn't help reduce gas costs.
 * The bytecode remains the same at 4.2 billion runs.
 * 
 * @notice
 * When the American spelling of a word may have a 'z'
 * in its suffix, we use 'zs' as a compromise with the
 * British 's' spelling. In other words:
 * "Optimization" + "Optimisation" = "Optimizsation".
 * Our project is based in the UK. Our Solidity devs are American.
 * We find the spelling compromise to be apropos.
 * 
 * @notice
 * Choosing which ERC or EIP standards to support is one of the most
 * research-intensive tasks to perform when writing a token contract.
 * We chose to start with the ubiquitous ERC-20 standard as our base
 * platform and ultimately chose to only augment it with EIP-2612.
 * 
 * @notice
 * We opted not to support ERC-223, ERC-777, EIP-1363, or EIP-3009 for
 * a variety of reasons. Most of all because none of those standards are
 * as widely accepted or expected as ERC-2ying 0 and EIP-2612.
 *   # ERC-223: We were unable to verify the extent of its support amongst
 *              popular DeFi platforms, and it's still in Draft as of 2023.
 *   # ERC-777: Implementation is quite complicated and its verification of
 *              functionality even more so. ERC-777 also has re-entry
 *              complications, most famously with Uniswap.
 *   # EIP-1363: We were unable to verify the extent of its support amongst
 *               popular DeFi platforms.
 *   # EIP-3009: Very similar to EIP-2612 but with the drawback of being
 *               unable to easily burn previously signed `permit()` messages.
 * Considering the adoption of EIP-2612 by Uniswap, USDC, ARB token, and
 * others, we feel the `permit()` gasless approval system is much simpler
 * while largely solving the long-standing concerns regarding `approve()`.
 * 
 * @notice
 * We chose to build on ERC-20 and EIP-2612 with optional automated
 * expiration of `allowance`s. Our automated expiration system is self-built
 * without relying or complying with any particular ERC or EIP standard.
 * Perhaps we will submit our system as an EIP in our attempt to further
 * improve the `approve()` + `transferFrom()` user experience while:
 *   # Complying to the expected ERC-20 standard
 *   # Providing greater security, and
 *   # Offering approachable controls over existing `approve()`s.
 * 
 * @dev
 * Variables are named without any prefix if the function is externally-facing
 * or with appended `_` prefix depending on how many layers deep. For example
 * the `__swapId()` function is itself nested inside the `_swapId()` function
 * but itself also has a nested function inside, thus there also exists
 * a named `___swapId()` function. The only exceptions to this rule are:
 *   # `i` for a counter omits the `_` prefix unless there's multiple counters,
 *   # and when the unprefixed variable name is already exists in global scope
 *     and would thus be shadowed. Example: `account` -> `_account`.
 */
contract TCC is IERC20, TokenBaseUtils {
    // ------------------------------------------------------------------ //
    //  ----------------------  GLOBAL VARIABLES  ----------------------  //

    /**
     * @dev
     * We thought that tightly packing unsigned integers into a single
     * 32-byte storage slot (1 word) would be advantageous for bytecode
     * and/or gas efficiency. In our testing it cost both /more/ gas
     * AND /more/ bytecode to use tightly packed integers versus using
     * standard unsigned `uint` which is a full 256 bits and 32 bytes.
     * Originally we had the following initializsed first to tightly pack:
     * uint8 + uint32 + uint32 + uint40 + uint32 only used 0.5625 of a single
     * uint256's 32 bytes. While – per the Ethereum.org documentation – that
     * should've resulted in them all being tightly packed within a
     * single 32-byte storage slot (1 word) and thus using less bytecode
     * and less gas, the reality is the opposite. Using smaller `uint`s than
     * the standard 256 used /more/ bytecode and /more/ gas in all operations.
     * 
     * @notice ERC-20 required variable -> `decimals`
     */
    uint8 public constant decimals = 6;

    /**
     * @dev
     * Equal to 10 ** `decimals`.
     * Assembly compile error requires hard-coded,
     * real value not a computed value such as
     * `= 10 ** decimals` or even `= 10 ** 6`.
     * 
     * @return denominator -> 1000000
     */
    uint public constant denominator = __denominator;

    /**
     * @dev 4,200 TC upper limit for `rain()` minimum balance eligibility.
     */
    uint public rainMinimumBalance = 1 * denominator;

    /**
     * @dev
     * Default is 200% the gas cost of a standard `transfer()` execution.
     * In our testing that's approximately the cost of each loop
     * transferring to multiple accounts in a single Tx.
     */
    uint public gasPerLoop = 31400;
    
    /**
     * @notice breakAtGasThreshold is used in:
     *   # `addAccounts()`
     *   # `updateErrorMsg_GasPerLoop()`
     *   # `_verifyLoopGas()`
     *   # `eraseAllApprovals()`
     *   # `transferMultiple()`
     *   # `rain()`
     *   # `rainList()`
     *   # `rainAll()`
     */
    uint public breakAtGasThreshold = 50000;
    
    /**
     * @dev
     * Immutable is employed to enforce fixed supply tokenomics.
     * `supply` is whole tokens (no decimals).
     * `totalSupply` is ERC-20 required. Raw total token units.
     * 
     * @notice ERC-20 required variable -> `totalSupply`
     */
    uint public immutable supply; // Whole tokens. 
    uint public immutable totalSupply; // Raw total number.

    /**
     * @dev
     * ERC-20 required variables. Immutable.
     * A commented `immutable` keyword for any `string` variable can be
     * interpreted hereafter to mean the variable is indeed set at
     * construction time and never again edited. As of this contract's
     * writing in 2023, the `immutable` keyword does not support `string`s.
     * 
     * @dev
     * Until clarity is found around EIP-2612 about whether the
     * `version` can be a string other than "1" – which is required
     * by EIP-712 – we opt for two different variables:
     *   # `version` -> "1" as required in EIP-712 on which EIP-2612 relies.
     *   # `versionNotes` -> To give information about this deployment.
     * 
     * @notice ERC-20 required variables -> `name` and `symbol`
     */
    string public /* immutable */ name;
    string public /* immutable */ symbol;
    string public constant version = "1"; // Required per EIP-2612 -> EIP-712
    string public constant versionNotes = "2023-04-20 | Final";
    
    /**
     * @dev
     * Events unique to this token contract.
     * Not part of the ERC-20 standard.
     */
    event Mint(address indexed origin, uint amount);
    event TransferMultiple(address indexed account, uint amount);
    event Rain(address indexed gifter, uint amountThisBlock);
    event RainList(address indexed account, uint total);
    event RainAll(address indexed account, uint total);
    event Claimed(address indexed token, uint amount, address indexed receiver);
    event AdminChange(address indexed from, address indexed to);
    event TreasuryChange(address indexed from, address indexed to);

    /**
     * @dev `string` error messages recalled out of storage via named-index.
     * @notice Can be grabbed as a full list via `getErrors()` `view` function.
     */
    string[lenErrors] errors;
    uint public maxRecipientsPerBlock;

    /**
     * @return Give a list of `string` of all `errors`.
     */
    function getErrors() external view returns (string[lenErrors] memory) {
        return errors;
    }

    /**
     * @dev
     * These addresses are primarily established for the purposes of
     * easily identifying and tracking the `treasuryWallet` across
     * the Triple Confirmation system of contracts. The `adminWallet`
     * and `treasuryWallet` both have the same authority level
     * EXCEPT that the `adminWallet` can change the `treasuryWallet` without
     * the latter's permission. Worth noting that while the `adminWallet`
     * can change the `treasuryWallet` address, the `adminWallet`
     * cannot transfer tokens away from the outgoing `treasuryWallet`
     * without being given permission via sufficient `allowance`.
     * 
     * @notice
     * `guardianWallet` is created to assist `adminWallet` with routine
     * token contract management that are of low consequence. These are
     * parameters relating to highly recursive operations such as adjusting
     * error messages or setting team wallets to lower `id`s for easier
     * access and organizsation from `getAccountsList()` calls.
     * 
     * @notice
     * `guardianWallet` is authorizsed by `adminWallet` to run only:
     *   # `setId()`
     *   # `setError()`
     *   # `addAccounts()`
     *   # `setProtected()`
     *   # `setGasPerLoop()`
     */
    address public adminWallet;
    address public treasuryWallet;
    address public guardianWallet;

    /**
     * @return circulatingSupply -> Raw value unsigned integer (uint)
     * of `totalSupply` not under the control of the `adminWallet`
     * or `treasuryWallet`.
     */
    function getCirculatingSupply() external view returns (uint) {
        uint circulatingSupply = totalSupply - balance[adminWallet];

        /**
         * @notice
         * The `circulatingSupply` is the amount of tokens
         * available to all accounts aside from the `adminWallet`
         * and `treasuryWallet`. To get the `circulatingSupply()`
         * we exclude these tokens from the `totalSupply` variable.
         * The difference is the amount "out in the wild."
         */
        if (adminWallet != treasuryWallet) {
            circulatingSupply -= balance[treasuryWallet];
        }

        return circulatingSupply;
    }

    /**
     * @notice
     * Account information.
     * We found the most efficient storage and execution gas costs to come
     * from utilizsing mappings of various primitive variable types as opposed
     * to packing all variables into a struct. Recalling and writing to a
     * struct appeared to cost significantly more gas – especially during
     * `for` loops – in our testing.
     * 
     * @dev
     * - Unique mappings to our token contract:
     *   # `id`
     *   # `account`
     *   # `protected`
     *   # `rainAllNextId`
     *   # `rainAllRunningTotal`
     *   # `allowanceTimeToLive`
     *   # `approvedSpenders`, and the
     *   # `delegationMem`
     * These are all employed to provide:
     *   # An improved `approve()` experience,
     *   # For the execution of `transferMultiple()`,
     *   # Various `rain()` functions, and
     *   # Delegate certain looping transactions thereby allowing users to
     *     employ scripted wallets via Web3xx on their behalf.
     * 
     * @notice
     * The `protected` mapping allows the `adminWallet`, `treasuryWallet`,
     * or `guardianWallet` to lock a specific account to a specific `id`.
     * This potentially enables easier team management of the TC trading bot
     * and any potential rewards related and given out to promote its use.
     * 
     * @dev
     * Be aware the `public` visibility gobbles up bytecode vs `private`.
     * 
     * @dev
     * Largest handle-able `allowanceTimeToLive` value due to the need
     * to add with `block.timestamp`:
     * 115339776388732929035197660848497720713218148788040405586178452820382218977280
     */
    uint public numAccounts;
    mapping(address => uint) public id;
    mapping(uint => address) public account;

    /**
     * @dev
     * We trialed three different systems to store these account-specific values:
     *   # Single mapping of `uint[]` list,
     *   # Struct containing all values, and
     *   # Primitive type mappings (current).
     * The other two methods – a single `uint[]` per address, and a single
     * struct containing all account values – both cost more in bytecode and
     * gas to use. Thus we settled on employing mappings of primitive types.
     */
    mapping(address => uint) balance;
    mapping(address => bool) protected;
    mapping(address => uint) rainAllNextId;
    mapping(address => uint) rainAllRunningTotal;
    mapping(address => uint248) allowanceTimeToLive;
    mapping(address => address[]) approvedSpenders;
    mapping(address => mapping(address => uint[lenAStor])) allowances;
    mapping(address => uint[lenDelegationMem]) delegationMem;
    



    // ------------------------------------------------------------------ //
    //  ------------------------  GET ACCOUNTS  ------------------------  //

    /**
     * @dev
     * The Delegation struct is intended purely for input. Its execution
     * requires verification against an encoded `uint` stored in a
     * given account's `delegationMem` array.
     */
    struct Delegation {
        address delegate;
        string functionName;
        address[] recipients;
        uint[] amounts;
    }

    /**
     * @dev
     * The following structs below here are intended purely for
     * `view` functions including `getAccountsList()`:
     *   # RainStruct
     *   # Approved
     *   # Account
     */
    struct RainStruct {
        bool excluded;
        uint allNextId;
        uint allRunningTotal;
        uint delegation;
    }

    struct Approved {
        address account;
        uint amount;
        uint timestamp;
        uint timeRemaining;
        uint perpetualSince;
    }

    struct Approves {
        uint248 timeToLive;
        Approved[] list;
    }
    
    struct Account {
        uint id;
        address account;
        uint balance;
        bool protected;
        Approves approvedSpenders;
        RainStruct rain;
    }

    /**
     * @notice
     * Converts an account's `address[]` held via `approvedSpenders`
     * to named-value (easier-to-read) `Approved[]` list.
     */
    function _buildApprovedStructList(
        address _account,
        uint248 _allowanceTimeToLive
    ) private view returns (
        Approved[] memory _approvedList
    ) {
        // Pull the account's list of `address` that have been approved.
        address[] memory _approves = approvedSpenders[_account];

        /**
         * @notice
         * We like lots of info about approvedSpenders. Hence there's a
         * whole struct list dedicated to them. First grab how
         * many approved spenders exist for this account. Then we'll
         * start building the struct list.
         */
        uint _numApproved = _approves.length;

        // Create an empty Approved struct list with the length identified above.
        _approvedList = new Approved[](_numApproved);

        // Loop through the empty Approved struct list and fill in
        // each approved address, including the amount and deadline.
        for (uint i; i < _numApproved; ++i) {

            // Grab the approved account at index `i` of the 
            // address list obtained via the `approvedSpenders` mapping.
            address _spender = _approves[i];

            /**
             * @dev
             * Grab the `allowances` out of storage setting the current
             * `allowance` to the proper index (0 which == `aAllowance`)
             * and then continue building the approve struct.
             */
            uint[lenAMem] memory _allowance =
                _calcAllowance(
                    _account,
                    _spender,
                    _allowanceTimeToLive
                );

            /**
             * @dev
             * If the `_spender` still has an `allowance` of `_account`,
             * then give the actual time remaining to expiration. Otherwise
             * if the `_spender` has been set to perpetual then the
             * time remaining will be 0 but the `allowance` amount
             * will persist.
             * 
             * @dev
             * Save data about this particular account to the
             * appropriate index `i` in the Approved struct list.
             */
            _approvedList[i] = Approved(
                _spender,
                _allowance[aAllowance],
                _allowance[aTimestamp],
                _allowance[aTimeRemaining],
                _allowance[aPerpetual]
            );
        }

        return _approvedList;
    }

    /**
     * @notice
     * Converts an account's mappings related to `rain()` and its two
     * derivative functions – `rainList()` and `rainAll()` – to a more
     * understandable named-value `RainStruct[]` list.
     */
    function _buildRainStruct(
        address _account
    ) private view returns (RainStruct memory) {
        return RainStruct(
            _isContract(_account),
            rainAllNextId[_account],
            rainAllRunningTotal[_account],
            delegationMem[_account][encodedDelegation]
        );
    }

    /**
     * @param _first -> First `id` of which to grab account information.
     * @param _last -> Last `id` of which to grab account information.
     * @return _accounts -> List of all accounts and their associated information.
     */
    function _accountsList(
        uint _first,
        uint _last
    ) private view returns (
        Account[] memory _accounts
    ) {
        _accounts = new Account[](1 + _last - _first);
        uint _i;

        // Loop over each account.
        for (uint i = _first; i <= _last; ++i) {
            /**
             * @dev
             * Build out the Account struct including the Approved[] list
             * and the RainStruct[] list. We use nested structs for easier
             * named-value reading on the Web3xx side.
             * 
             * @notice
             * We employ a separate counter `_i` distinct from `i`
             * to fill in the `accounts` without worrying about
             * underflow, overflow, or out-of-index errors.
             * This `_i` counter is incremented by 1 after retrieval
             * from memory via the `++` suffix. Appending the `++`
             * as a prefix would instead increment by 1 before retrieval
             * which is not what we want, hence we append `++` as a suffix.
             * 
             * @dev
             * Incrementing variables by 1 with the `++` as a prefix uses
             * less gas than incrementing by 1 with the `++` as a suffix.
             * For `view` functions there exists no functional gas limit
             * since we can always spin up our own node with no timeout.
             */
            _accounts[_i++] = getAccount(account[i]);
        }

        return _accounts;
    }

    /**
     * @notice
     * External `view` wrapper to obtain a list of all accounts.
     * Costs around ≈ 20,000 gas per account meaning there's a
     * soft limit of ≈ 395 accounts supported by a gas-limited node.
     * 
     * @notice
     * If there's no accounts, this will revert. We find this to be
     * an acceptable limitation.
     */
    function getAccountsList() external view returns (Account[] memory) {
        return _accountsList(1, numAccounts);
    }

    /**
     * @notice
     * The same as above but with the added option of grabbing accounts only
     * between certain indices/values of `id`.
     * 
     * @param first -> In reference to `id` NOT `getAccountsList()` indices.
     * @param last  -> In reference to `id` NOT `getAccountsList()` indices.
     * 
     * @notice
     * Submitting a larger number than `numAccounts` for `first` will force the
     * list to /start/ at the last account.
     * Submitting a larger number than `numAccounts` for `last` will force the
     * list to /terminate/ at the last account.
     */
    function getAccountsListByIds(
        uint first,
        uint last
    ) external view returns (
        Account[] memory
    ) {
        require(
            first <= last,
            errors[errList]
        );

        /**
         * @dev
         * Purposefully omit the `0` index since that's a null user that
         * should always result in default, unset values.
         */
        if (last > numAccounts) {
            last = numAccounts;
            if (first > numAccounts) {
                first = numAccounts;
            }
        }
        return _accountsList(first, last);
    }

    /**
     * @param _account -> Provide all relevant associated information.
     */
    function getAccount(
        address _account
    ) public view returns (
        Account memory
    ) {
        uint248 _allowanceTimeToLive = allowanceTimeToLive[_account];
        return Account(
            id[_account],
            _account,
            balance[_account],
            protected[_account],
            Approves(
                _allowanceTimeToLive,
                _buildApprovedStructList(_account, _allowanceTimeToLive)
            ),
            _buildRainStruct(_account)
        );
    }

    /**
     * @param _id -> Provide all relevant account info on account at `_id`.
     */
    function getAccountById(
        uint _id
    ) external view returns (
        Account memory
    ) {
        return getAccount(account[_id]);
    }




    // ------------------------------------------------------------------ //
    //  -------------------------  CONSTRUCTOR  ------------------------  //

    /**
     * @dev Constructor.
     * @param _deployer -> Address employed to disburse tokens.
     * @param _guardian -> Address entrusted to be Guardian.
     * @notice ERC-20 required variables -> `_name` and `_symbol` and `_supply`.
     */
    constructor(
        string memory _name,
        string memory _symbol,
        uint _supply,
        address _deployer,
        address _guardian
    ) {
        name                = _name;
        symbol              = _symbol;
        supply              = _supply;
        totalSupply         = _supply * denominator;
        adminWallet         = msg.sender;
        treasuryWallet      = msg.sender;
        balance[_deployer]  = totalSupply;
        guardianWallet      = _guardian;

        /**
         * @dev
         * We purposefully do not add the `msg.sender`
         * or `_deployer` because neither the deploying
         * wallet nor the deployer should be remembered. 
        _addAccount(msg.sender);
         */
        emit Transfer(address(0), _deployer, totalSupply);
        emit Mint(_deployer, totalSupply);
        
        /**
         * @dev
         * Domain creation MUST occur either
         * after the storage of `name` or
         * not during the `constructor()`.
         */
        saveDomainSeparatorAndChainId();
    }




    // ------------------------------------------------------------------ //
    //  -----------------  ADMIN-GUARDIAN HOUSEKEEPING  ----------------  //

    /**
     * @notice
     * `adminWallet`, `treasuryWallet`, and `guardianWallet` are all unique
     * address slots that may be three unique entities. A situation can arise
     * where they do not see eye-to-eye on certain housekeeping duties such as
     * what a specific error message should read. In the case of a dispute, the
     * `adminWallet` is endowed with full credentials to strip the other two
     * of their authority and has the exclusive ability to arbitrate any and
     * all issues.
     */

    /**
     * @dev
     * We tried setting the errors in the `constructor()` but that would cost
     * too much gas to deploy. We then tried to set all the strings in a single
     * function here but that added +0.3Kb to the bytecode. Instead, we've
     * chosen to implement the `guardianWallet` and allow it to loop over the
     * entire `errors` storage array to set each error one-at-a-time.
     *
    function setErrorList(
        string[lenErrors] calldata _errors
    ) external _adminTreasuryOrGuardianAuth {
        assert(id[msg.sender] == 0);
        for (uint8 i; i < lenErrors; ++i) {
            errors[i] = _errors[i];
        }
    }
    */

    /**
     * @notice Accepts a given `string` and sets it to the `index` in `errors`.
     */
    function setError(
        string calldata _error,
        uint index
    ) external _adminTreasuryOrGuardianAuth {
        assert(index < lenErrors);
        errors[index] = _error;
    }

    /**
     * @dev Costs ≈ 85,000 gas per account.
     * @param accounts -> List of address to add as new accounts.
     * @param shouldBeProtected -> Attribute of `protected` for each given address.
     * @notice `accounts` and `shouldBeProtected` must be identical in length
     * and index-matched to each other. Entries should be linked by index.
     * @dev Increases bytecode by +0.1Kb to make a nested private exec function.
     */
    function addAccounts(
        address[] calldata accounts,
        bool[] calldata shouldBeProtected
    ) external _adminTreasuryOrGuardianAuth {

        uint _end = accounts.length;
        assert(_end == shouldBeProtected.length);
        _verifyLoopGas(_end / 2);

        for (uint i; i < _end; ++i) {
            if (_hasInsufficientGasRemaining() && i > 0 && i + 1 < _end) {
                return;
            }
            _addAccount(accounts[i]);
            protected[accounts[i]] = shouldBeProtected[i];
        }
    }

    /**
     * @notice
     * Allows certain wallets to remain at a static `id`.
     * 
     * @notice
     * Set `address(0)` as a protected wallet to disable accounts
     * from being automatically erased during `rain()` functions.
     * 
     * @notice
     * Be aware that setting the account at the current
     * `numAccounts` will also (temporarily) prevent accounts
     * from being erased during `rain()` functions until a
     * new un`protected` account joins.
     */
    function setProtected(
        address wallet,
        bool shouldBeProtected
    ) external _adminTreasuryOrGuardianAuth {
        protected[wallet] = shouldBeProtected;
    }
    
    /**
     * @notice
     * Very minor exploits while running `rainAll()` with a mischievous
     * `adminWallet`, `treasuryWallet`, or `guardianWallet`:
     *   # --> Set an already-rained-on `id` to a not-yet-rained `_id`.
     * 
     * @notice
     * The above could result in a given account getting rained on two or more
     * times during `rainAll()` and disallowing someone else from being rained
     * on at all. This minor exploit can advantage certain accounts while
     * disadvantaging others and can be employed by third-parties who have
     * sway over any of the aforementioned administrative wallets without the
     * need to be one themselves. Ultimately what's most important is being
     * aware of this concern. This is a social issue, not an actual bug.
     * 
     * @dev
     * Swapping the account at `id` == 0 which is expected to be a null account
     * of `address(0)` is intended to be avoided in all scenarios.
     */
    function setId(address _account, uint _id) external _adminTreasuryOrGuardianAuth {
        require(
            !protected[account[_id]],
            errors[errSetIdProtected]
        );
        _setId(_account, _id);
    }

    /**
     * @dev
     * Updating error strings with complex `string.concat()` logic eats up a
     * lot of bytecode. This particular one we find to be important since
     * requiring the `guardianWallet`, `treasuryWallet`, or `adminWallet` to
     * push a separate `setError()` transaction in addition to a
     * `setGasPerLoop()` transaction doesn't seem very well-conceived. This way
     * only the aforementioned `setGasPerLoop()` function need be called and
     * its associated error message will automatically be updated with all the
     * new values as calculated with the new `gasPerLoop` parameter.
     */
    function updateErrorMsg_gasPerLoop() external {
        // Saves a little bytecode using a nested, private execution function.
        _updateErrorMsg_gasPerLoop();
    }




    // ------------------------------------------------------------------ //
    //  --------  INTERNAL ADMIN-GUARDIAN HOUSEKEEPING HELPERS  --------  //

    /**
     * @dev Nested private execution function required for delegation use.
     * @param _account -> Set its `id` to `_id`.
     * @param _id -> Submit `0` to attempt to delete the `_account`.
     */
    function _setId(address _account, uint _id) private {
        /**
         * @dev
         * We want to ensure the `_account` is a current account
         * so we run it through `_addAccount()` to verify its
         * registration or to register it in the case that it's
         * not yet an account of this token contract. If the
         * `_account` wasn't registered then we could accidentally
         * `__swapId()` with an unset entry which would result
         * in `address(0)` being registered. We want to avoid that
         * behaviour and we also want to only `__swapId()`s with
         * registered non-null accounts, hence we run `_account`
         * through `_addAccount()`.
         */
        require(
            /**
             * @dev
             * Only allow the `__swapId()` to take place if the `_account` is
             * registered. If the `_account` has an `id` of 0 after the
             * `_addAccount` – such as if `address(0)` is submitted as the
             * `_account` – then the `require()` below will fail.
             */
            _addAccount(_account) > 0
            &&
            (
                (
                    /**
                     * @dev
                     * Only process a deletion if:
                     *   # The `_account`s `balance` is 0, AND
                     *   # The deletion was requested from `_id` == 0.
                     */
                    balance[_account] == 0
                    && _id == 0
                )
                || // OR
                (   
                    /**
                     * @dev
                     * Otherwise only allow the `__swapId()`
                     * if the `_id` requested is less than
                     * or equal to the `numAccounts` as
                     * swapping outside of that would result
                     * in `address(0)` becoming registered.
                     * We do not want `address(0)` to ever
                     * be registered.
                     */
                    _id > 0
                    && _id <= numAccounts
                )
            ),
            errors[errSetId]
        );

        // Process the `id` swap.
        __swapId(_account, _id);
    }

    /**
     * @dev
     * Execute the actual swap of `_id`.
     * Do NOT call directly without verification
     * and `require()` checks beforehand.
     */
    function ___swapId(address _account, uint _id) private {
        (
            account[_id],
            account[id[_account]],
            id[_account],
            id[account[_id]]
        )
        =
        (
            account[id[_account]],
            account[_id],
            id[account[_id]],
            id[_account]
        );
    }

    /**
     * @dev Call from the `_setId()` private function.
     */
    function __swapId(address _account, uint _id) private {
        /**
         * @dev
         * If the wallet existing in the requested `_id`
         * is `protected` then do nothing. In order to
         * supplant that account, set its `id` to something
         * else or eliminate its `protected` attribute.
         * 
         * @notice
         * To prevent any account from being erased, set
         * `address(0)` to `protected` == true.
         */
        if (protected[account[_id]]) { return; }

        // Delete the account.
        if (_id == 0) {
            /**
             * @dev If the wallet is `protected` then do nothing.
             */
            if (protected[_account]) { return; }

            /**
             * @dev
             * Execute the deletion by swapping the `_account`
             * to the end of the list of `id`s. Then delete
             * the `_account`s `id` link keeping in mind to
             * increment `numAccounts` down by 1 afterwards.
             */
            ___swapId(_account, numAccounts);
            delete account[numAccounts--];
            delete id[_account];

            return;
        }
        /**
         * @dev
         * Note that we don't recursively verify that the account on the
         * receiving end of swap with `_account` is themselves ineligible for
         * deletion; such as having a 0 balance. Our intention is that should
         * the `adminWallet`, `treasuryWallet`, or `guardianWallet` desire to
         * cleanse the `rain()` list of 0 balance wallets, then they will loop
         * over all accounts with `_id` set to 0 and thus over time and many
         * swaps, reach the desired outcome of pruning ineligible accounts.
         * 
         * Performing a simple swap of ID's this way without recursive
         * verification allows MetaMask and other Web3 providers to better
         * estimate the gas cost of the transaction, and ensures the cost of
         * any given `rain()` function isn't overly bloated by the calls to
         * this `_swapId()` function which itself is nested inside the
         * `_hasRainMinimumBalance()` function which is nested inside the
         * `rain()` functions.
         * 
         * Our philosophy is to enable pruning of the accounts list in a
         * cost-effective manner, and to spread out such pruning over multiple
         * transactions by a somewhat random number of balance-holders.
         */
        ___swapId(_account, _id);
    }

    /**
     * @dev Private executable to update the `gasPerLoop` error message.
     */
    function _updateErrorMsg_gasPerLoop() private {
        maxRecipientsPerBlock = 
            (block.gaslimit - breakAtGasThreshold)
            / _safeDivision(gasPerLoop);
        
        errors[errGasPerLoop] =
            string.concat(
                " gas. Required: ",
                __uintToString(gasPerLoop),
                " gas/recipient + ",
                __uintToString(breakAtGasThreshold),
                " gas/Tx. ",
                __uintToString(maxRecipientsPerBlock),
                " max recipients."
            );
    }




    // ------------------------------------------------------------------ //
    //  ------------------  AUTHORIZSATION MODIFIERS  ------------------  //

    /**
     * @notice
     * Authorizsation is inherited such that `adminWallet` has full privileges,
     * `treasuryWallet` has a subset of those privileges, and `guardianWallet`
     * has a subset of `treasuryWallet`s privileges. Thus there is nothing
     * that `guardianWallet` can do that `treasuryWallet` cannot, and nothing
     * that `treasuryWallet` can do that `adminWallet` cannot.
     */

    function _walletIsAdmin(address _wallet) private view returns (bool) {
        return _wallet == adminWallet;
    }

    modifier _adminAuth() {
        require(
            _walletIsAdmin(msg.sender),
            errors[errAdminAuth]
        );
        _;
    }

    function _walletIsTreasury(address _wallet) private view returns (bool) {
        return _wallet == treasuryWallet;
    }
    
    function _walletIsTreasuryOrAdmin(address _wallet) private view returns (bool) {
        return _walletIsTreasury(_wallet) || _walletIsAdmin(_wallet);
    }
    
    modifier _adminOrTreasuryAuth() {
        require(
            _walletIsTreasuryOrAdmin(msg.sender),
            errors[errTreasuryAdminAuth]
        );
        _;
    }

    function _walletIsGuardian(address _wallet) private view returns (bool) {
        return _wallet == guardianWallet;
    }

    function _walletIsGuardianTreasuryOrAdmin(address _wallet) private view returns (bool) {
        return _walletIsGuardian(_wallet) || _walletIsTreasuryOrAdmin(_wallet);
    }

    modifier _adminTreasuryOrGuardianAuth() {
        require(
            _walletIsGuardianTreasuryOrAdmin(msg.sender),
            errors[errGuardianTreasuryAdminAuth]
        );
        _;
    }




    // ------------------------------------------------------------------ //
    //  ----------------------  INTERNAL HELPERS  ----------------------  //

    function _hasInsufficientGasRemaining() private view returns (bool) {
        return breakAtGasThreshold > gasleft();
    }

    /**
     * @notice
     * Accounts who have a `balance` below the `rainMinimumBalance`
     * are deemed ineligible for `rain()` and `rainAll()` functions.
     * Since `rain()` operates on a random basis and `rainAll()`
     * operates on an all-accounts basis, we feel it makes sense to
     * set a low threshold above which an account's `balance` must land
     * in order to qualify. This functionality is invisible to senders.
     * Senders do not specific who they `rain()` or `rainAll()`, thus
     * we feel this functionality is fair to ensure tokens stay in
     * circulation – something very important for fixed supply
     * tokenomics – and to encourage accounts to hold a `balance`
     * thereby putting positive pressure on tokenomics. We also want to
     * keep gas costs reasonable while looping across many accounts. That's
     * only possible if set the threshold at such an amount that account
     * pollution doesn't occur; that is, we want to avoid people making
     * hundreds of accounts each with TC dust for the exclusive purpose of
     * reaping higher `rainAll()` rewards and a higher probability of
     * `rain()` rewards. The `rainMinimumBalance` is adjustable for that
     * very purpose: For the administrative team to discourage account
     * pollution while ensuring the fun execution of `rain()` functions.
     * 
     * @notice
     * `rainList()` is explicitly exempted from the aforementioned `balance`
     * checks because if the sender provides a list to rain on then we can
     * logically assume the sender does intend and want to rain on each
     * address. If we did perform the same check on `rainList()` executions,
     * senders could very well become confused upon realizsing only
     * certain accounts received their rain while others in their list
     * did not. Without the ability to notify the sender of why certain
     * accounts were rained and others weren't, senders will simply
     * become frustrated at this obtuse functionality.
     * 
     * @notice
     * `protected` wallets are excluded from being rained on – except in the
     * case of `rainList()` which bypasses the check – to avoid abuse by the
     * `adminWallet`, `treasuryWallet`, or `guardianWallet` setting their
     * personal wallets earlier in the `id` list and thus being more likely to
     * be hit in `rainAll()` executions than if they had a higher `id`. Should
     * the administrative wallets set their personal wallets to a lower `id`
     * and /not/ set them as `protected`, we feel the requirement to have
     * `rainMinimumBalance` to be sufficiently fair despite the slight
     * advantage gained by being earlier in the `rainAll()` list. Furthermore,
     * this minor advantage is limited to `rainAll()` exclusively.
     */
    function _execRain(
        address _owner,
        address _recipient,
        uint _amount
    ) private returns (
        bool _skip
    ) {

        if (
            /**
             * @dev
             * Don't process the rain if:
             *   # The same account raining is the one chosen to be rained on
             *   # The `_recipient` is protected
             *   # A null address is hit.
             */
            _owner == _recipient
            || protected[_recipient]
            || _isNullAccount(_recipient) // Specifically avoid `_addAccount()`.
        ) {
            return _skip;
        }

        /**
         * @dev
         * Only if the `_recipient`s balance is 0 AND the `rainMinimumBalance`
         * is greater than 0 should accounts be eligible for deletion.
         * The deletion will be skipped if an account is `protected`.
         * Note though the flow of if{} statements prevents `protected`
         * accounts from reaching this logic block.
         */
        uint _recipientBal = balance[_recipient];
        if (_recipientBal == 0 && rainMinimumBalance > 0) {
            __swapId(_recipient, 0); // Delete the account.
            return _skip;
        }

        /**
         * @dev
         * Massively cheaper in gas costs to verify a given address
         * is a contract each time versus saving and recalling
         * a `bool` held in storage.
         */
        if (_isContract(_recipient)) {
            return _skip;
        }

        /**
         * @dev
         * Reaching this logic block means the account is deemed eligible
         * to receive `rain()`ed tokens. Process a direct `_transfer()`.
         */
        if (_recipientBal >= rainMinimumBalance) {
            return _transfer(_owner, _recipient, _amount);
        }
        
        /**
         * @dev For all other conditions, skip the account.
         */
        return _skip;
    }

    /**
     * @dev
     * In order to implement a successful `rain()` function,
     * we need to store a list of all accounts. This list is
     * used and verified in `rain()` and `rainAll()` with
     * 0 balance accounts pruned unless `rainMinimumBalance`
     * is also set to 0.
     * 
     * @return _id -> Lookup of `_newAccount` in the `id` mapping.
     * @dev For null accounts, `_id` should always return 0.
     */
    function _addAccount(address _newAccount) private returns (uint _id) {
        _id = id[_newAccount];
        if (_id > 0 || _isNullAccount(_newAccount)) {
            return _id;
        }

        /**
         * @dev
         * By incrementing `numAccounts` before setting
         * it in the `account` mapping we ensure that
         * `id` == 0 is also address(0). This is the
         * intended output since otherwise address(0)
         * would be eligible for `rain()` and would thus
         * burn tokens. We would much prefer to avoid
         * burning tokens since we have a fixed supply
         * and would rather manage the circulating supply
         * via the trading bot and its associated fees.
         */
        _id = ++numAccounts;
        account[_id] = _newAccount;
        id[_newAccount] = _id;
        return _id;
    }

    /**
     * @return -> String with `_owner`s balance included.
     */
    function _insufficientBalanceError(
        address _owner
    ) private view returns (
        string memory
    ) {
        return string.concat(
            errors[errInsufficientBalance],
            _tokenValueAsString(balance[_owner])
        );
    }

    /**
     * @return -> String of `_value` in decimal form with `symbol` appended.
     */
    function _tokenValueAsString(
        uint _value
    ) private view returns (
        string memory
    ) {
        return string.concat(
            _uintToString(_value),
            errors[errSymbol]
        );
    }

    /**
     * @notice
     * Nested `require()`s that verify the `sender` has a sufficient
     * `balance` to send the `totalRainAmount` tokens. The error
     * message is generated on-demand in a human-readable and
     * intuitively-understandable format with decimals shown.
     * 
     * @notice
     * Named `_rainAndListChecks()` because this check applies
     * only to `rain()` and `rainList()`.
     * 
     * @param _enforceGasRequired -> Should be true if actually executing.
     */
    function _rainAndListChecks(
        address _owner,
        uint _amount,
        uint _accountsToRain,
        bool _enforceGasRequired
    ) private view {
        /**
         * @notice
         * Our intention is that only those who have an insufficient `balance`
         * pay extra gas for the error message to be generated. We feel
         * the need to return an easily understood error message to be
         * important for a good user experience when attempting to `rain()`.
         */
        require(
            balance[_owner] >= _amount * _accountsToRain,
            /**
             * @notice
             * If the `sender` has an insufficient `balance`,
             * tell them how many tokens they must have in
             * order to run the function { `rain()` | `rainList()` }
             * they desire.
             */
            string.concat(
                _insufficientBalanceError(_owner),
                " Required: ",
                _tokenValueAsString(_amount * _accountsToRain)
            )
        );

        /**
         * @dev
         * While raining on 0 accounts would not present any execution
         * issues, we feel the user experience is improved having a
         * revert occur with a clear error message that no `rain()`
         * took place.
         */
        require(
            _accountsToRain > 0,
            errors[errRainNumAccounts]
        );

        /**
         * @notice Parameter to optionally verify the submitted gas.
         */
        if (_enforceGasRequired) {
            _verifyLoopGas(_accountsToRain);
        }
    }

    /**
     * @notice Ensure sufficient gas was given to run at least one loop.
     * 
     * @dev
     * We could limit `_loops` to `maxRecipientsPerBlock` but decide that's
     * not as important or as guaranteed a check as directly limiting the
     * maximum amount of `_gasRequired` to 90% the `block.gaslimit` which
     * will always be possible to submit.
     */
    function _verifyLoopGas(uint _loops) private view {
        /**
         * @dev
         * Ensure the `_gasRequired` isn't greater than 90% the `block.gaslimit`
         * otherwise a user may be unable to submit the given transaction. The
         * safest path to ensure this check doesn't return a value greater than
         * or too close to the `block.gaslimit` is to simply limit it after the
         * calculated `_gasRequired`. We want to ensure the requirement here is
         * some amount of gas that a user can reasonably produce. Thus, limit
         * the upper bound of `_gasRequired` to 90% the `block.gaslimit`. The
         * `++` prefix on `_loops` assists in ensuring sufficient gas is given
         * to run at least one loop before the `breakAtGasThreshold` is hit.
         */
        uint _gasRequired = breakAtGasThreshold + (gasPerLoop * ++_loops);
        if (_gasRequired > 90 * block.gaslimit / 100) {
            _gasRequired = 90 * block.gaslimit / 100;
        }

        /**
         * @dev
         * If there is insufficient `gasleft()` then error with a message
         * explaining how much gas needs to be provided.
         */
        require(
            gasleft() > _gasRequired,
            string.concat(
                errors[errGasPerLoopHeader],
                __uintToString(_gasRequired),
                errors[errGasPerLoop]
            )
        );
    }




    // ------------------------------------------------------------------ //
    //  -------------------  INTERNAL ERC-20 HELPERS  ------------------  //

    /**
     * @return Is the `_account` one of the null wallets, or (this) address?
     * 
     * @notice
     * In order of likelihood to occur.
     * Prevent token burns by silently
     * re-routing to the `treasuryWallet`.
     */
    function _isNullAccount(address _account) private view returns (bool) {
        // These are all eligible via `transferFrom()`.
        return
            _account == address(0)
            || _account == address(0xdead)
            || _account == address(this);
    }

    /**
     * @notice
     * Our assumption is that if someone sends tokens to this token contract
     * or to one of the above listed null accounts, they are intending to burn
     * them or get rid of them forever. Should they have transferred a mistake
     * then there exists the (social) potential for the `treasuryWallet` to
     * send the tokens back to their rightful owner.
     * 
     * @dev Executes the requested balance transfer and emits the {Transfer} event.
     * @notice ERC-20 required execution function.
     */
    function _transfer(
        address _from,
        address _to,
        uint _amount
    ) private returns (
        bool
    ) {
        require(
            balance[_from] >= _amount,
            _insufficientBalanceError(_from)
        );

        /**
         * @notice Redirect lost tokens to the `treasuryWallet`.
         * No reason to spend add'l gas adding `_from` accounts.
         */
        if (_addAccount(_to) == 0 || _isNullAccount(_from)) {
            _to = treasuryWallet;
        }

        /**
         * @dev Execute the `balance` transfer.
         */
        balance[_from] -= _amount;
        balance[_to] += _amount;

        emit Transfer(_from, _to, _amount);
        return true;
    }

    /**
     * @notice
     * By simply setting an `allowance` to a static `_amount`, there exists a
     * race condition exploit native to the ERC-20 standard where a `_spender`
     * can spend both the previous `allowance` AND this new `allowance` amount
     * being set. We attempt to nullify this race condition exploit inherent
     * to the ERC-20 standard by implementing EIP-2612 and its `permit()`
     * function. EIP-2612 adds support for gasless approvals and allows the
     * `allowance` to be set just before `transferFrom()` execution all in the
     * same transaction in the same block. If executed this way, two problems
     * are simultaneously solved:
     *   # Race condition for double `allowance` spend, and
     *   # Need to submit two transactions { `approve()` + `transferFrom()` }
     *     and spend 50% more gas. This has systemic drawbacks as well since
     *     a single, simple transfer costs twice as much blockchain bandwidth,
     *     filling up crucial block space.
     * 
     * @dev
     * Current blockchain technology is inherently throughput-restricted.
     * We feel a better system than the two transaction ERC-20 standard can
     * be implemented to transfer tokens to a dApp or smart contract. While
     * ERC-223, ERC-777, EIP-1363, and EIP-3009 all offer unique proposal,
     * we found EIP-2612 to be the most compelling due to its simplicity
     * and clear support across 1/3 of the top tokens, by market cap, in 2023.
     * 
     * @dev
     * This function is the endpoint of:
     *   # `approve()`
     *   # `increaseAllowance()`
     *   # `decreaseAllowance()`
     *   # `permit()`
     *
     * @notice ERC-20 and EIP-2612 required private execution function.
     */
    function _approve(
        address _owner,
        address _spender,
        uint _amount
    ) private returns (
        bool
    ) {
        /**
         * @dev
         * Standard ERC-20: `approve()` sets the `aAllowance` amount
         * in our `allowances` `uint[3]` mapping.
         */
        allowances[_owner][_spender][aAllowance] = _amount;

        /**
         * @dev
         * Save the `_spender` into the `_owner`s `approvedSpenders` list if
         * they're a new spender. The `approvedSpenders` list and all associated
         * `allowances` can be deleted via `eraseAllApprovals()` with
         * `onlyExpired` set to false.
         * 
         * @dev
         * The same address can be pushed into the `approvedSpenders` list twice
         * if the `aTimestamp` of a given spender's allowance is reset to 0
         * without first erasing the entire `approvedSpenders` list. Each address
         * in the `approvedSpenders` list for a given `_owner` should appear
         * only once. When queried via the `getAccount()` or its derivative
         * functions, each `_spender` in the `approvedSpenders` list should
         * appear with all relevant info including that `_spender`s `allowance`,
         * when it was last updated, and how many seconds it has until expiration.
         * We try to avoid duplicative entries in the `approvedSpenders` list
         * by not erasing the `aTimestamp` except when an `_owner` requests
         * a full `eraseAllApprovals()` with `onlyExpired` set to false.
         */
        if (allowances[_owner][_spender][aTimestamp] == 0) {
            approvedSpenders[_owner].push(_spender);
        }

        // Non-standard ERC-20: Remember when the `allowances` was set.
        allowances[_owner][_spender][aTimestamp] = block.timestamp;
        
        /**
         * @dev
         * Finalizse the `approve()` by emitting the {Approval} event
         * and returning true as required by the ERC-20 standard.
         */
        emit Approval(_owner, _spender, _amount);
        return true;
    }

    /**
     * @notice
     * Give the list of recipients the amount in the `_amounts` list
     * using the index as a link between the two. The lists
     * must be of identical length to avoid unintended transfers.
     * 
     * @notice ERC-20 extended internal execution function.
     */
    function _transferMultiple(
        address _owner,
        bool _delegated,
        address[] calldata _recipients,
        uint[] calldata _amounts
    ) private {
        uint _end = _recipients.length;
        _verifyLoopGas(_end);

        // Local variable setup.
        uint i;
        if (_delegated) { i = delegationMem[_owner][startIndex]; }
        uint _start = i;
        uint _total; // Sum of all transfers.

        // Loop through `_recipients` list.
        for (; i < _end; ++i) {
            if (
                _delegated
                && _hasInsufficientGasRemaining()
                && i > _start
                && i + 1 < _end
            ) {
                break;
            }

            /**
             * @notice
             * No verification of if the `recipient` is a
             * smart contract where tokens may be irreversibly lost.
             */
            _transfer(_owner, _recipients[i], _amounts[i]);

            /**
             * @dev
             * Must sum the individual amounts for an accurate total.
             * Can't multiply by `amount` because each recipient might
             * receive a different amount.
             */
            _total += _amounts[i];
        }

        if (_delegated) {
            delegationMem[_owner][total] += _total;
            delegationMem[_owner][startIndex] = i;
        }

        if (i >= _recipients.length) {
            emit TransferMultiple(
                _owner,
                _delegated
                    ? delegationMem[_owner][total]
                    : _total
            );
        }
    }

    /**
     * @dev
     * Private executable to calculate the `allowance` taking into consideration
     * the `_owner`s set duration until expiration of `_spender`s `allowance`.
     */
    function _calcAllowance(
        address _owner,
        address _spender,
        uint248 _allowanceTimeToLive
    ) private view returns (
        uint[lenAMem] memory _allowances
    ) {
        /**
         * @dev
         * Grab and remember the `allowances` out of storage.
         * This doesn't cost any less gas than individual calls
         * but does help in centralizse the `allowance` calculation
         * logic and to return a fully set array of values for
         * easy parsing and management across the token contract.
         * The array itself is used most heavily in the `getAccount(s)`
         * functions. The first indexed value is the calculated
         * `allowance` taking into consideration the aforementioned
         * spoil/expiration time.
         */
        for (uint8 i; i < lenAStor; ++i) {
            _allowances[i] = allowances[_owner][_spender][i];
        }

        /**
         * @dev
         * 1 second added to allow an `allowance` to be used if the current time
         * and the `_deadline` are the same time. Thus transferring if the
         * current time is exactly `_deadline` is accepted but transferring one
         * second /after/ the `_deadline` is rejected. While we could use `>=`
         * here, when returned via the `getAccount()` or its derivative
         * functions the owner would see 0 seconds remaining when the
         * `allowance` really has 1 second remaining until expiration.
         */
        uint _deadline = 1 + _allowanceTimeToLive + _allowances[aTimestamp];
        if (_deadline > block.timestamp) {
            _allowances[aTimeRemaining] = _deadline - block.timestamp;
        }

        /**
         * @dev
         * If {
         *  the user has set an `allowanceTimeToLive`
         *  AND
         *  the user has NOT set this `_spender` to perpetual
         *  AND
         *  the `allowance` has zero time remaining,
         * }
         * THEN
         * Return a 0 `allowance` by deleting the appropriate entry.
         * Note that `delete` REFUNDS some gas whereas `= 0` COSTS add'l gas.
         */
        if (
            _allowanceTimeToLive > 0
            &&
            _allowances[aPerpetual] == 0
            &&
            _allowances[aTimeRemaining] == 0
        ) {
            delete _allowances[aAllowance];
        }

        return _allowances;
    }

    /**
     * @dev Private executable to loop through revoking approvals.
     */
    function _eraseAllApprovals(
        bool _onlyExpired,
        uint248 _allowanceTimeToLive
    ) private returns (
        bool _completed
    ) {
        address[] memory _approves = approvedSpenders[msg.sender];
        _verifyLoopGas(3 * _approves.length / 2); // 150% the expense of `rain()`
        
        /**
         * @dev `_revokeApproval()` will return false if the Tx ran out of gas.
         */
        for (uint i; i < _approves.length; ++i) {
            if (!_revokeApproval(_approves[i], _onlyExpired, _allowanceTimeToLive)) {
                return _completed; // false
            }
        }

        _completed = true;

        // Full revokes should also delete the `approvedSpenders` list.
        if (!_onlyExpired) {
            delete approvedSpenders[msg.sender];
        }

        return _completed;
    }

    /**
     * @dev Private executable to revoke an approval of one `_spender` only.
     */
    function _revokeApproval(
        address _spender,
        bool _onlyExpired,
        uint248 _allowanceTimeToLive
    ) private returns (
        bool _completed
    ) {
        // Returning to save progress is preferable to reverting.
        if (_hasInsufficientGasRemaining()) {
            return _completed; // false
        }

        _completed = true;

        /**
         * @dev
         * We thought we could save gas by calling the `_allowances[]`
         * array once out of storage rather than calling individual
         * values. Apparently Solidity charges a storage recall
         * /per index/ meaning grabbing a whole array is significantly
         * more expensive than calls of individual values as needed, provided
         * we don't call the same value out of storage more than once.
        uint[lenA] memory _allowances = _calcAllowance(msg.sender, _spender);
         */

        /**
         * @dev
         * If the `allowance` is still active – that is, has not expired –
         * and `onlyExpired` is true, then don't delete this `allowance`.
         */
        if (_onlyExpired) {

            /**
             * @dev
             * If the `allowance` is still active, leave it alone
             * and continue through the list of `approvedSpenders`. This
             * is because the sender desires only to destroy
             * `onlyExpired` approvals.
             * 
             * @dev
             * If the `allowance` is perpetual with the sender having
             * explicitly having set the `_spender` as perpetual (having
             * no expiration date), then `continue` through the list.
             */
            if (
                allowances[msg.sender][_spender][aPerpetual] > 0
                // `calcAllowance()` is higher in gas to calculate, hence second.
                || _calcAllowance(
                    msg.sender,
                    _spender,
                    _allowanceTimeToLive
                )[aAllowance] > 0
            ) {
                return _completed; // true
            }

            /**
             * @dev
             * Otherwise if the `_spender` has 0 allowance AND
             * was not previously registered by the sender as
             * having no expiration date then delete the allowance.
             */
            delete allowances[msg.sender][_spender][aAllowance];
            return _completed; // true
        }

        /**
         * @dev
         * If not `onlyExpired` then the sender desires to destroy
         * all data related to their `allowances`.
         */
        delete allowances[msg.sender][_spender];
        return _completed; // true
    }




    // ------------------------------------------------------------------ //
    //  --------------------------  SETTERS  ---------------------------  //

    /**
     * @dev
     * Private executable for changing the `adminWallet` and/or `treasuryWallet`.
     * Saves bytecode to combine the functionality into a private exec function.
     */
    function _execAdminTreasuryWalletChange(
        address _newWallet,
        address _existingWallet,
        bool _transferTokens,
        string[2] memory _errors
    ) private {
        require(
            _addAccount(_newWallet) > 0,
            _errors[0] // Invalid, null address.
        );

        require(
            _newWallet != _existingWallet,
            _errors[1] // No change in address.
        );

        if (_transferTokens) {
            // Enforces `allowance` if `adminWallet` != `treasuryWallet`.
            transferFrom(
                _existingWallet,
                _newWallet,
                balance[_existingWallet]
            );
        }

        // Safest security measure is to erase stored Delegation.
        delete delegationMem[_existingWallet];
        delete delegationMem[_newWallet];
    }
    
    /**
     * @notice Only the `adminWallet` can replace itself and set a successor.
     */
    function setAdminWallet(
        address newAdminWallet,
        bool transferTokens
    ) external _adminAuth {
        _execAdminTreasuryWalletChange(
            newAdminWallet,
            adminWallet,
            transferTokens,
            [errors[errSetAdmin0], errors[errSetAdmin1]]
        );

        /**
         * @notice
         * Outgoing `adminWallet` can choose to allow the incoming `adminWallet`
         * to inherit its `balance` or not.
         */
        if (adminWallet == treasuryWallet) {
            setTreasuryWallet(newAdminWallet, transferTokens);
        }
        
        emit AdminChange(adminWallet, newAdminWallet);
        adminWallet = newAdminWallet;
    }

    /**
     * @notice By default the `treasuryWallet` is set to the `adminWallet`.
     * 
     * @notice
     * `transferFrom()` is used instead of `_transfer()` because otherwise
     * an exploit exists where the `adminWallet` can `setTreasuryWallet()`
     * to anyone, then `setTreasuryWallet()` again to itself to steal all
     * the tokens from the intermediate account. By requiring an `approve()`
     * function for `adminWallet` to move tokens that do not belong to it,
     * we solve this exploit and require the `treasuryWallet` to `approve()`
     * the `adminWallet` thereby giving authorizsation to move its tokens.
     * 
     * @notice
     * `treasuryWallet` can replace itself and set a new `treasuryWallet`.
     * `adminWallet` can strip any `treasuryWallet` of its privileges at any time.
     */
    function setTreasuryWallet(
        address newTreasuryWallet,
        bool transferTokens
    ) public _adminOrTreasuryAuth {
        _execAdminTreasuryWalletChange(
            newTreasuryWallet,
            treasuryWallet,
            transferTokens && adminWallet != treasuryWallet,
            [errors[errSetTreasury0], errors[errSetTreasury1]]
        );

        /**
         * @notice
         * Requiring the outgoing `treasuryWallet` to `approve()` the
         * `adminWallet` in the case where the `adminWallet` is not also
         * the `treasuryWallet` ensures that `adminWallet` cannot rugpull
         * (steal tokens) by the exploit explained at this function's header.
         */
        emit TreasuryChange(treasuryWallet, newTreasuryWallet);
        treasuryWallet = newTreasuryWallet;
    }

    /**
     * @dev
     * Allows `adminWallet` or `treasuryWallet` to set a `guardianWallet`
     * to execute basic housekeeping tasks on the former's behalf. No
     * verification of `address(0)` or other null addresses since that would
     * prohibit `adminWallet` and `treasuryWallet` from deleting the
     * `guardianWallet` should it choose to do so.
     */
    function setGuardianWallet(
        address newGuardianWallet
    ) external _adminOrTreasuryAuth {
        guardianWallet = newGuardianWallet;
    }
    
    /**
     * @dev
     * EVM in 2023 doesn't easily permit looping across a wide battery of
     * accounts. Our workaround is to loop over the same elements across
     * multiple blocks. To ensure that millions of gas isn't wasted when
     * looping across multiple blocks, we set the minimum `gasPerLoop` and
     * `breakAtGasThreshold` variables. We do not see any exploit possible
     * here other than annoying users by artificially inflating the amount
     * of gas required to submit a looping transaction. Any unspent gas
     * is refunded on transaction completion regardless of the values of
     * `gasPerLoop` and `breakAtGasThreshold`.
     * 
     * @notice
     * These two variables are changeable to allow the `adminWallet`,
     * `treasuryWallet`, or `guardianWallet` to adjust the required gas
     * parameters in the two cases:
     *   # Blockchain parameters change.
     *   # Looping transactions revert or run out of gas
     *     instead of gracefully returning.
     */
    function setGasPerLoop(
        uint newGasPerLoop,
        uint newBreakAtGasThreshold
    ) external _adminTreasuryOrGuardianAuth {
        /**
         * @dev
         * Ensure the new `gasPerLoop` would still allow at least a few
         * accounts to be looped over in the `rainAll()` function.
         */
        require(
            newGasPerLoop <= block.gaslimit / 20,
            errors[errSetGasPerLoop]
        );
        
        /**
         * @dev
         * Setting the `gasPerLoop` to the same as `breakAtGasThreshold`
         * could result in sufficient gas being given to run another loop
         * but insufficient to closing the transaction after breaking the
         * loop. For sure setting `breakAtGasThreshold` /below/ `gasPerLoop`
         * could easily result in reverting loops and millions of gas lost.
         */
        require(
            newGasPerLoop < newBreakAtGasThreshold,
            errors[errSetGasValues]
        );

        /**
         * @dev
         * Reasonable to allow a minimum of 3/4 the `block.gaslimit`
         * to be used for looping only before breaking and closing.
         */
        require(
            newBreakAtGasThreshold <= block.gaslimit / 4,
            errors[errSetBreakAtGasThres]
        );

        /**
         * @dev
         * Save the values into storage and update the relevant error message.
         */
        gasPerLoop = newGasPerLoop;
        breakAtGasThreshold = newBreakAtGasThreshold;
        _updateErrorMsg_gasPerLoop();
    }
    
    /**
     * @notice
     * Set a minimum balance required to qualify for
     * inclusion in `rain()` and `rainAll()` functions.
     * 
     * @notice
     * Default is 1 whole token required.
     * Accounts with a fraction of a token, as in <= 0.999999, are excluded.
     */
    function setRainMinimumBalance(
        uint newRainMinimumBalance
    ) external _adminOrTreasuryAuth {

        // Enforce a maximum required balance of 4200.69 tokens.
        require(
            newRainMinimumBalance <= __maxRainThreshold,
            errors[errSetRainMinBalance]
        );

        rainMinimumBalance = newRainMinimumBalance;
    }




    // ------------------------------------------------------------------ //
    //  ----------------------  ERC-20 FUNCTIONS  ----------------------  //

    /**
     * @notice Section dedicated to externally-facing ERC-20 functions.
     */

    /**
     * @dev
     * Prevent tokens from being irrevocably lost by requiring users to submit
     * `transferFrom()` transactions to transfer to a smart contract. While this
     * is unexpected ERC-20 functionality, it's also only applied when a
     * non-contract wallet – a person – transfers directly to an address at
     * which a contract exists. The only exclusions are the `guardianWallet`,
     * `treasuryWallet`, and `adminWallet` since our intent is for those
     * addresses to always be able to accept and manage any and all tokens
     * such as them being multi-sig wallet contracts.
     * 
     * @notice
     * Be aware that `transferFrom()` transactions made by an account owner
     * themselves will bypass the `approve()` requirement and execute
     * as if they were a standard `transfer()` transaction. We consider this
     * acceptable functionality since account owners should always be free to
     * do with their tokens what they like without needing to authorizse
     * themselves. Furthermore, forcing users to call a different function will
     * almost assuredly prevent unintended transfers directly to contracts.
     * Most EVM contracts in 2023 cannot react to tokens sent directly via
     * ERC-20's standard `transfer()` method. By being forced to call a
     * separate function, users are made aware of the danger but may
     * still proceed should they desire to transfer directly to a contract.
     * 
     * @notice ERC-20 required function.
     */
    function transfer(address to, uint amount) external returns (bool) {
        /**
         * @dev
         * If sent directly to a smart contract, tell the user to use
         * `transferFrom()`. This check adds ≈ 3000 gas to a `transfer()`
         * transaction, increasing the cost from ≈ 37000 to ≈ 40000 total.
         */
        require(
            _isContract(msg.sender)
            || !_isContract(to)
            || _walletIsGuardianTreasuryOrAdmin(to),
            errors[errTransferContract]
        );

        return _transfer(msg.sender, to, amount);
    }
    
    /**
     * @return balance -> Of the provided `owner`.
     * @notice ERC-20 required function.
     */
    function balanceOf(address owner) external view returns (uint) {
        return balance[owner];
    }

    /**
     * @return allowance -> That the `_account` has granted the `_spender`.
     * @notice ERC-20 required function.
     */
    function allowance(
        address owner,
        address spender
    ) public view returns (
        uint
    ) {
        /**
         * @dev
         * If the `allowanceTimeToLive` set by the `_owner` is
         * 0 then the `allowance` is perpetual. Otherwise,
         * any non-zero number should be treated as the
         * number of seconds into the future the user intends
         * for their `_spender`s `allowance` to expire.
         * 
         * @dev
         * If current time is in the future from the `owner`s
         * `allowanceTimeToLive` number of seconds plus when the
         * `approve()` AKA `allowance` was set, then show that the
         * `allowance` is 0 (expired). Otherwise, return the calculated
         * value based on the actual one stored in the `allowances` mapping.
         */
        return _calcAllowance(owner, spender, allowanceTimeToLive[owner])[aAllowance];
    }

    /**
     * @notice
     * IMPORTANT: Beware that changing an `allowance` with this method brings
     * the risk that someone may use both the old and the new `allowance` by
     * unfortunate transaction ordering.
     * 
     * @notice
     * While the Ethereum community states, "One possible solution to mitigate
     * this race condition is to first reduce the spender's `allowance` to 0
     * and set the desired value afterwards" we do not see how unfortunate
     * transaction ordering can't still spend the outgoing `allowance` before
     * it is set to 0.
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM
     * 
     * @notice ERC-20 required function.
     */
    function approve(address spender, uint amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }

    /**
     * @notice
     * Defined with `public` visibility to allow for use in `setTreasuryWallet()`.
     * Pre-requisite to use: Owner gives an `allowance` to the `sender`.
     * `sender` may now `transferFrom()` `owner` to any `recipient` of their
     * choosing for any amount up to `allowance[owner][recipient][aAllowance]`.
     * 
     * @notice
     * Since the transfer may be called with the possibility of
     * `from` != `msg.sender` we opt for the variable name
     * `owner` instead of `from`, and `recipient` instead of `to`.
     * 
     * @notice ERC-20 required function.
     */
    function transferFrom(
        address owner,
        address recipient,
        uint amount
    ) public returns (bool) {
        uint _allowance = allowance(owner, msg.sender);

        /**
         * @notice
         * Always allow a transaction where the `msg.sender` is the `owner`
         * by adjusting `allowances`, essentially giving a token holder unlimited
         * `allowance` for themselves to mirror `transfer()` functionality.
         */
        if (msg.sender == owner && _allowance <= amount) {
            /**
             * @dev
             * Costs less gas to check `if{}` statement than to `delete` if
             * already set to 0. Very likely a `msg.sender` won't ever set
             * their allowance at all meaning it'll be 0 most of the time.
             */
            if (_allowance > 0) {
                delete allowances[msg.sender][msg.sender][aAllowance];
            }
        }
        /**
         * @notice
         * Otherwise if the `msg.sender` is not the `owner` or if they provided
         * themselves with sufficient `allowance`, then continue into the
         * `else{}` statement.
         */
        else {
            /**
             * @dev
             * Nesting the `require()` this way ensures lower gas cost since we
             * allow execution if `msg.sender` == `sender` with the special
             * case of a token holder wanting to directly call `transferFrom()`
             * themselves. That special case exists because of our desire to
             * prevent the extremely common user error of using `transfer()`
             * to send directly to a smart contract. These smart contracts
             * in 2023 EVM won't typically register they've received anything
             * and thus the tokens will be lost forever. The common exception
             * is a multi-sig wallet via smart contract which we have no ability
             * to identify and exempt from our checks.
             */
            require(
                _allowance >= amount,
                string.concat(
                    errors[errInsufficientAllowance],
                    _tokenValueAsString(_allowance)
                )
            );

            /**
             * @dev
             * Disallow the subtraction of `allowance` by `amount`
             * if `_allowance != type(uint).max`. Saves ≈ 2k gas
             * in the case of an `owner` setting `spender`s
             * `allowance` to be effectively unlimited. While this
             * doesn't strictly adhere to the ERC-20 standard, this
             * functionality is quite common and saves gas when there
             * exists no materially significant outcome difference.
             */
            if (_allowance != type(uint).max) {
                allowances[owner][msg.sender][aAllowance] -= amount;
            }

            /**
             * @dev
             * Important to note that we use `msg.sender` NOT `recipient` since
             * the former adheres to the ERC-20 standard whereas requiring
             * `msg.sender` == `recipient` or checking the `recipient`s
             * `allowance` is standard-breaking. Many protocols have a
             * higher-level contract administer – commonly known as a router –
             * to `transferFrom()` a user to a separate contract for actual
             * execution. This means the `msg.sender` will be approved but
             * a `recipient` may not be.
             */
        }

        // Execute the transfer and emit a {Transfer} event.
        return _transfer(owner, recipient, amount);
    }




    // ------------------------------------------------------------------ //
    //  ------------------  ERC-20 EXTENDED FUNCTIONS  -----------------  //

    /**
     * @notice Section dedicated to extended EIP-2612 functionality. 
     * 
     * @notice
     * Function name uses "Approvals" instead of "Allowances" because its
     * purpose is to delete all information related a given spender on sender's
     * behalf. If we were only erasing the amount – as in the value stored at
     * the `aAllowance` index in the `allowances` array – then we would've opted
     * for "eraseAllAllowances()" as a function name. Instead this function
     * destroys all traces of all approvals if run with `_onlyExpired` == false.
     * 
     * @notice EIP-2612 extended function.
     */
    function eraseAllApprovals(
        bool onlyExpired
    ) external returns (
        bool
    ) {
        return _eraseAllApprovals(onlyExpired, allowanceTimeToLive[msg.sender]);
    }

    /**
     * @dev
     * Setting an account's `allowanceTimeToLive` to less than
     * ≈ 30 seconds could very easily result in transfers
     * bricking. Can be set to 0 to remove the limit entirely.
     * 
     * @notice ERC-20 extended function.
     */
    function setAllowanceTimeToLive(uint newAllowanceTimeToLive) external {
        require(
            (
                newAllowanceTimeToLive >= __minSecsAllowanceTimeToLive // 30 seconds
                && newAllowanceTimeToLive <= type(uint248).max
            )
            || newAllowanceTimeToLive == 0,
            // Otherwise, give an error.
            errors[errSetAllowanceTimeToLive]
        );

        /**
         * @dev
         * To ensure lingering `approve()`s don't suddenly appear, the best
         * course of action is to `eraseAllApprovals()` if the user is
         * setting their `allowanceTimeToLive` to:
         *   # A different length of time than their current setting
         *   # AND is either setting it to
         *      # 0 (that being perpetual/indefinite `approve()`s)
         *      # A longer duration of time than their current setting
         * In those scenarios we'd want to `eraseAllApprovals()`s.
         * Setting the `allowanceTimeToLive` to a /stricter/ setting such as
         * going from default 0 to 30 or from 60 to 45 seconds would not
         * need to invoke the `eraseAllApprovals()` since that would see
         * current `approve()`s become invalidated rather than previously
         * invalidated `approve()`s suddenly becoming valid again.
         */
        uint248 _allowanceTimeToLive = allowanceTimeToLive[msg.sender];
        if (
            _allowanceTimeToLive != newAllowanceTimeToLive
            && (
                newAllowanceTimeToLive == 0
                || (
                    _allowanceTimeToLive > 0
                    && newAllowanceTimeToLive > _allowanceTimeToLive
                )
            )
        ) {
            /**
             * @dev
             * Stricter (shorter) time limits needn't
             * access and erase storage values since
             * they still get calculated as 0.
             */
            if (!_eraseAllApprovals(true, _allowanceTimeToLive)) {
                return;
            }
        }

        allowanceTimeToLive[msg.sender] = uint248(newAllowanceTimeToLive);
    }

    /**
     * @dev
     * Allow the `msg.sender` to decide if they want to enable perpetual
     * approvals for the given `spender` or to delete/disable such setting.
     */
    function setAllowancePerpetual(address spender, bool enable) external {
        /**
         * @dev
         * Prevent zombie `approve()`s from being revived.
         * No possible gas savings over accessing `aAllowance`
         * directly and then needing to fallback to
         * `_calcAllowance()` in most scenarios anyway.
         */
        if (allowance(msg.sender, spender) == 0) {
            /**
             * @dev
             * Since we already know the allowance is 0 with the
             * current expiration, delete the `aAllowance` amount
             * to prevent it from being potentially revived after we
             * set the account to perpetual – unending – expiration.
             */
            delete allowances[msg.sender][spender][aAllowance];
        }

        /**
         * @dev Enable perpetual approvals by setting to non-zero.
         */
        allowances[msg.sender][spender][aPerpetual] =
            enable ? block.timestamp : 0;
    }

    /**
     * @notice ERC-20 extended function.
     */
    function increaseAllowance(
        address spender,
        uint amountToAdd
    ) external returns (
        bool
    ) {
        uint _allowance = allowance(msg.sender, spender);
        return _approve(msg.sender, spender, _allowance + amountToAdd);
    }

    /**
     * @notice ERC-20 extended function.
     */
    function decreaseAllowance(
        address spender,
        uint amountToDeduct
    ) external returns (
        bool
    ) {
        uint _allowance = allowance(msg.sender, spender);
        require(
            _allowance >= amountToDeduct,
            string.concat(
                errors[errDecreaseAllowance],
                _tokenValueAsString(_allowance)
            )
        );
        return _approve(msg.sender, spender, _allowance - amountToDeduct);
    }

    /**
     * @notice Batch-transfer a list of index-linked recipients and amounts.
     * 
     * @dev
     * Give the list of recipients the amount in the `amounts` list
     * using the index as a link between the two. The lists
     * must be of identical length to avoid unintended transfers.
     * 
     * @notice ERC-20 extended function.
     */
    function transferMultiple(
        address[] calldata recipients,
        uint[] calldata amounts
    ) external {
        require(
            recipients.length == amounts.length,
            errors[errTransferMultiple]
        );
        _transferMultiple(msg.sender, false, recipients, amounts);
    }




    // ------------------------------------------------------------------ //
    //  ---------------------  EIP-2612 FUNCTIONS  ---------------------  //

    /**
     * @notice Section dedicated to all EIP-2612 logic. 
     */

    /**
     * @dev
     * This packed bytes may NOT be altered in any way
     * without completely breaking compatibility with
     * the EIP-2612 standard. EIP-2612 relies on
     * having a `PERMIT_TYPEHASH` that
     * returns an >> identical << result in Web3xx.
     * 
     * @notice EIP-2612 required variable.
     */
    bytes32 private constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
    ); // == 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9

    /**
     * @notice Estimated gas cost ≈ 250,000.
     * @notice EIP-2612 required function.
     * 
     * @dev Helpful links related to gasless approvals:
     * https://eips.ethereum.org/EIPS/eip-2612
     * https://soliditydeveloper.com/erc20-permit
     * https://github.com/Uniswap/v3-periphery/blob/main/test/shared/permit.ts
     * https://github.com/Uniswap/v2-core/blob/master/contracts/UniswapV2ERC20.sol#L81
     * https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol#L112
     * https://github.com/soliditylabs/ERC20-Permit/blob/main/contracts/ERC20Permit.sol#L33
     * https://anettrolikova.medium.com/permits-as-free-approval-messages-for-signing-transactions-6f9b7c1b7ee0
     * https://github.com/ethereum/EIPs/pull/5987#issuecomment-1351327168
     * https://twitter.com/dmihal/status/1251505379391004672
     * https://eips.ethereum.org/EIPS/eip-777
     * https://www.blockchain-council.org/ethereum/ethereum-tokens-erc-20-vs-erc-223-vs-erc-777/
     * 
     * @dev
     * Executing with the `++` as a suffix on `nonces` will grab the current
     * `nonces` value, then increment by 1 after resolution of the `keccak256()`
     * calculation. We could of course write `++nonces[owner]` on a new line
     * after the function execution. However, writing the logic this way makes
     * it clear the nonce is used then incremented after its use.
     */
    function permit(
        address owner,
        address spender,
        uint value,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(
            deadline >= block.timestamp,
            errors[errPermitDeadline]
        );

        bytes32 _digest = keccak256(
            abi.encodePacked(
                hex"1901", // == "\x19\x01"
                _getAndSaveDomainSeparator(),
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );

        /**
         * @dev
         * Verify the `owner` matches the signature. VERY important.
         * This entire `permit()` and EIP-2612 gasless approval
         * system hinges on the ability to recover the `owner`
         * from the `v`, `r`, and `s` values given, and then for
         * those values to match the `_digest` calculated based
         * on the other arguments provided.
         */
        require(
            owner == ecrecover(_digest, v, r, s),
            errors[errPermitBadSig]
        );

        /**
         * @dev
         * `require()`s placed in order of
         * most likely to least likely to fail
         * to save gas on invalid executions.
         */
        require(
            owner != address(0),
            errors[errPermit0]
        );

        /**
         * @dev Execute the approval.
         */
        _approve(owner, spender, value);
    }

    /**
     * @dev
     * Ideally we'd create a nested mapping to ensure any particular user
     * can create permits across multiple dApps without a nonce collision
     * occurring. Since there is only a single nonce, then each user could
     * only `permit()` one dApp at a time rather than being able to
     * simultaneously interact with multiple. On the plus side, ensuring a
     * user's `nonce` is the same across their entire account does enable the
     * ability to burn previous `permit()`s more easily and allows dApps
     * to more easily create signatures in Web3xx.
     * 
     * @notice EIP-2612 required variable.
     */
    mapping (address => uint) public nonces;

    /**
     * @notice EIP-2612 extended function.
     * 
     * @notice
     * Allows a user to burn the oldest unused and previously-signed message,
     * thereby burning a previous `permit()` --> `approve()` they created.
     */
    function permitBurn() external {
        ++nonces[msg.sender];
    }

    /**
     * @notice EIP-2612 required variable.
     */
    bytes32 private constant EIP712_DOMAIN = 
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /**
     * @notice EIP-2612 required variable.
     */
    bytes32 public DOMAIN_SEPARATOR;

    /**
     * @notice EIP-2612 derivative required variable.
     */
    uint public chainId;

    /**
     * @notice EIP-2612 required function.
     */
    function saveDomainSeparatorAndChainId() public {
        chainId = block.chainid;
        /**
         * @dev
         * From EIP-712.
         * https://eips.ethereum.org/EIPS/eip-712
         * None of these fields can be altered in any way
         * without completely breaking compatibility with
         * the EIP-2612 standard, which itself relies on
         * having a `DOMAIN_SEPARATOR` per EIP-712 that
         * returns an >> identical << result in Web3xx.
         */
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN,             // EIP-712 required: Defined
                keccak256(bytes(name)),    // EIP-712 required: Generated
                keccak256(bytes(version)), // EIP-712 required: Defined
                block.chainid,             // EIP-712 required: Generated
                address(this)              // EIP-712 required: Generated
            )
        );
    }

    /**
     * @dev
     * Grabs the `DOMAIN_SEPARATOR` and updates only
     * if the `block.chainid` changes.
     * 
     * @notice
     * MUST be run during `constructor()` AFTER `name` is saved.
     * 
     * @notice EIP-2612 extended function.
     */
    function _getAndSaveDomainSeparator() private returns (bytes32) {
        if (block.chainid != chainId) { saveDomainSeparatorAndChainId(); }
        return DOMAIN_SEPARATOR;
    }
    // --------- EIP-2612 support ending ---------




    // ------------------------------------------------------------------ //
    //  -----------------------------  RAIN  ---------------------------  //

    /**
     * @notice
     * The operation herein is identical to `rainAll()`. The `_amount`
     * applies to each account rained such that the total spend per `rain()`
     * is equal to { `_accountsToRain` x `_amount` }. If someone `rain()`s
     * 10 on 10 accounts, they will have `_transfer()`d away 100 tokens.
     */
    function _rain(
        address _owner,
        uint _amount,
        uint _accountsToRain
    ) private {
        _rainAndListChecks(_owner, _amount, _accountsToRain, true);

        // Attempted randomness.
        uint _firstId =
            uint(
                keccak256(
                    abi.encodePacked(
                        tx.gasprice,
                        block.timestamp,
                        block.number,
                        _amount,
                        _accountsToRain
                    )
                )
            ) % (numAccounts + 1); // Prevent modulo by 0.
        
        uint _increment =
            uint(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 1),
                        block.timestamp % (_firstId + 1),
                        gasleft(),
                        _accountsToRain
                    )
                )
            ) % (_accountsToRain + 1); // Prevent modulo by 0.
        
        uint _randomNumber =
            uint(
                keccak256(
                    abi.encodePacked(
                        blockhash(block.number - 2),
                        _owner,
                        account[numAccounts],
                        gasleft() / 2,
                        _firstId,
                        _increment
                    )
                )
            );

        // Increase randomness.
        if (_randomNumber % 2 == 0) {
            ++_firstId;
        }
        if (_randomNumber % 6 == 0) {
            ++_increment;
        }
        if (_randomNumber % 7 == 0) {
            ++_firstId;
        }
        if (_randomNumber % 13 == 0) {
            ++_increment;
        }
        if (_firstId > numAccounts) {
            _firstId %= numAccounts;
        }
        if (_increment > numAccounts) {
            _increment %= numAccounts;
        }

        // Ensure no 0 values at the start.
        if (_firstId == 0) {
            ++_firstId;
        }
        if (_increment == 0) {
            ++_increment;
        }

        uint _startId = _firstId;
        uint _randomId = _startId;
        uint i;
        uint _excluded;

        for (; i < _accountsToRain; ++i) {
            // Close the `rain()` if gas is running out.
            if (
                _hasInsufficientGasRemaining()
                && i > 0
                && i + 1 < _accountsToRain
            ) {
                break;
            }

            /**
             * @notice
             * If the end of the accounts list has been reached,
             * wrap around and continue.
             */
            if (_randomId > numAccounts) {
                _randomId -= numAccounts;
            }

            /**
             * @notice
             * If the current user to rain has already been rained,
             * since they were the `_startId` and `i` is no longer 0,
             * then seek forward by increments of 1 until the end of the
             * list is reached. If the rain is still ongoing, reset `_startId`
             * to one account before the `_firstId` and traverse backwards to
             * the 0 index. If the rain is /still/ ongoing after the `_startId`
             * hitting every single member in the accounts list, which will
             * occur when `_startId` == 0, then restart from
             * the original `_firstId`.
             */
            if (_randomId == _startId && i > 0) {
                if (_startId >= _firstId) {
                    ++_startId;
                }
                else {
                    --_startId;
                }

                if (_startId == 0) {
                    _startId = _firstId;
                }

                if (_startId > numAccounts) {
                    _startId = _firstId - 1;
                    /**
                     * @dev
                     * `_firstId` will always start at 1 or greater
                     * since above we evaluate `_firstId == 0`
                     * to result in `++_firstId`.
                     */
                }

                _randomId = _startId; /** This `_startId` should
                 * be different from the one compared at the beginning
                 * of this entire `if{}` flow.
                 */
            }

            /**
             * @dev
             * If this loop results in a skip, whether or not the `_randomId`
             * had their `id` set to 0 doesn't matter since we'll increment
             * `_excluded` even for a delete. Furthermore `_randomId` is
             * verified to be not greater than `numAccounts` at the start
             * of each loop. When compared to `i`, `_excluded` will be
             * an accurate number of loops in which no rain took place.
             */
            if (
                !_execRain(
                    _owner,
                    account[_randomId],
                    _amount
                )
            ) {
                /**
                 * @dev
                 * Make sure to continue for one additional loop
                 * if this one was an unsuccessful rain transfer.
                 * This should ensure that at the end of the
                 * function, `i` - `_excluded` == the `_owner`s
                 * originally intended number of accounts to rain.
                 */
                ++_excluded;
                ++_accountsToRain;
            }

            _randomId += _increment;
        }

        /**
         * @param _delegated -> `false` submitted since this function
         * should never run across multiple blocks and therefore
         * we needn't remember any info into `delegationMem`.
         */
        _rainEnd(_owner, false, 0, 0, _amount * (i - _excluded));
    }

    /**
     * @notice Externally facing for anyone to use on their own behalf.
     */
    function rain(uint amount, uint accountsToRain) external {
       _rain(msg.sender, amount, accountsToRain);
    }

    /**
     * @notice Give `_amount` to each `_recipient` in the list.
     */
    function _rainList(
        address _owner,
        bool _delegated,
        uint _amount,
        address[] calldata _recipients
    ) private {
        uint _end = _recipients.length;
        _rainAndListChecks(_owner, _amount, _end, true);

        uint _firstId;
        uint i;

        if (_delegated) {
            i = delegationMem[_owner][startIndex];
            _firstId = i;
        }

        for (; i < _end; ++i) {
            if (
                _delegated
                && _hasInsufficientGasRemaining()
                && i > _firstId
                && i + 1 < _end
            ) {
                break;
            }

            /**
             * @notice
             * No verification of `rainMinimumBalance`
             * nor if the `recipient` is a smart contract
             * where tokens may be irreversibly lost.
             */
            _transfer(_owner, _recipients[i], _amount);
        }

        _rainEnd(_owner, _delegated, 0, i, _amount * (i - _firstId));

        if (i >= _recipients.length) {
            emit RainList(_owner, _amount * _recipients.length);
        }
    }
    
    /**
     * @notice Give `amount` to each `_recipient` in the list.
     */
    function rainList(uint amount, address[] calldata recipients) external {
        _rainList(msg.sender, false, amount, recipients);
    }

    /**
     * @notice
     * This will revert if there are 0 accounts.
     * This will skip raining on the owner's address.
     * Rains `_amount` to every single `account`
     * that qualifies inside `_execRain()`.
     */
    function _rainAll(
        address _owner,
        bool _delegated,
        uint _amount
    ) private {
        _verifyLoopGas(maxRecipientsPerBlock); // Go for calculated max per block.
        uint _firstId =
            _delegated
            ? delegationMem[_owner][startIndex]
            : rainAllNextId[_owner];

        /**
         * @dev
         * Avoid `rainAll()` on address(0).
         * Ensure this check occurs /after/ the `_delegated` if{} statement
         * above which sets `_firstId` to `delegationMem[startIndex]`.
         */
        if (_firstId == 0) {
            ++_firstId;
        }

        // Slightly more gas efficient to create variables outside a `for` loop.
        uint i = _firstId;
        uint _lastIdToRain = i + (balance[_owner] / _safeDivision(_amount));
        uint _excluded;
        address _recipient;

        // Time to loop until we run out of gas or reach `_lastIdToRain`.
        for (; i <= _lastIdToRain;) {
            /**
             * @dev
             * Don't break unless at least one account has been rained on
             * and also don't break if there's only one account remaining.
             */
            if (
                _hasInsufficientGasRemaining()
                && i < numAccounts
                && i > _firstId
                && i < _lastIdToRain
            ) {
                break;
            }

            /**
             * @dev
             * `numAccounts` can be incremented down
             * by `_execRain()`s `_setId()` function.
             * Thus we need a verification on each
             * loop to ensure we don't start looping
             * across null accounts beyond the ones
             * that exist.
             */
            if (_lastIdToRain > numAccounts) {
                /**
                 * @dev
                 * If `i` has become greater than `numAccounts`
                 * then break to avoid an infinite loop
                 * going up through default values of `address(0)`.
                 */
                if (i > numAccounts) {
                    break;
                }

                _lastIdToRain = numAccounts;
            }

            /**
             * @notice Skips if the `_owner` is the token `_recipient`.
             * @dev If `lastIdToRain` becomes larger than `numAccounts`
             * from this interaction, it'll get fixed on the next loop
             * before hitting any user. In case the `_owner` is the last
             * account registered, the loop will break above( inside the
             * `lastIdToRain` > `numAccounts` if{} flow).
             */
            _recipient = account[i];

            if (
                !_execRain(
                    _owner,
                    _recipient,
                    _amount
                )
            ) {
                /**
                 * @dev
                 * If the account was not deleted (in which case `numAccounts`
                 * would be incremented down), then permit an extra loop.
                 */
                if (id[_recipient] > 0) {
                    ++_excluded;
                    ++i;
                    /**
                     * @dev
                     * Since this rain transfer was unsuccessful and the
                     * account was not deleted (meaning it `_isContract()`),
                     * then increment `lastIdToRain` up by 1 on the condition
                     * that it isn't already a value of `numAccounts` or greater.
                     */
                    if (_lastIdToRain < numAccounts) {
                        ++_lastIdToRain;
                    }
                }

                continue;
            }
            ++i;
        }
        
        /**
         * @dev
         * Prevent a revert if we make a simple math error in how many tokens
         * were rained during this `rainAll()` execution.
         */
        uint _rainedAmount;
        if (i > _excluded + _firstId) {
           _rainedAmount = _amount * (i - _excluded - _firstId);
        }

        _rainEnd(
            _owner,
            _delegated,
            0,
            i,
            _rainedAmount
        );
        
        /**
         * @notice
         * Save the progress of the `rainAll()` if the `_owner` == `msg.sender`
         * where the rained tokens came from the account calling this function.
         */
        if (!_delegated) {
            // Nested if{} with additional variable `rainAllNextId` set to `i`.
            if (_rainedAmount > 0) {
                rainAllRunningTotal[_owner] += _rainedAmount;
            }
            rainAllNextId[_owner] = i;
        }

        /**
         * @dev
         * If not every account was rained on, emit a standard {Rain} event
         * then return to prevent further logic execution and to ensure
         * the `rainAllNextId` and `rainAllRunningTotal` are both
         * properly saved for future completion.
         */
        if (i < numAccounts) {
            return;
        }

        /**
         * @dev
         * If `_delegated` == true and completed – as evidenced by
         * `i` >= `numAccounts` – then emit a {RainAll} event and
         * return to avoid overwriting `msg.sender`s self-made progress
         * of `rainAllNextId` and `rainAllRunningTotal`. The
         * `delegationMem` structure should be deleted in the parent
         * `runMyDelegation()` function if this event is hit.
         */
        if (_delegated) {
            emit RainAll(_owner, delegationMem[_owner][total]);
            return;
        }

        /**
         * @dev
         * All logic below here should only run if the `msg.sender`
         * is the account out of which the rain is paid.
         */
        emit RainAll(_owner, rainAllRunningTotal[_owner]);

        // Reset the _owner's next account to rain variable.
        rainAllNextId[_owner] = 1;

        // Erase the running total number of tokens the `_owner` has rained.
        delete rainAllRunningTotal[_owner];
    }

    /**
     * @dev
     * Costs ≈ 40,000 gas per recipient
     * for a soft cap of 198 recipients per block.
     */
    function rainAll(uint amount) external {
        _rainAll(msg.sender, false, amount);
    }

    /**
     * @dev Saves info if `_delegated` and emits a {Rain} event.
     */
    function _rainEnd(
        address _owner,
        bool _delegated,
        uint _excluded,
        uint _i,
        uint _rainedAmount
    ) private returns (
        uint
    ) {
        if (_delegated) {
            if (_rainedAmount > 0) {
                delegationMem[_owner][total] += _rainedAmount;
            }
            if (_excluded > 0) {
                delegationMem[_owner][excluded] += _excluded;
            }
            
            delegationMem[_owner][startIndex] = _i;

            _excluded = delegationMem[_owner][excluded];
        }
        emit Rain(_owner, _rainedAmount);
        return _excluded;
    }




    // ------------------------------------------------------------------ //
    //  -------------------------  DELEGATION  -------------------------  //
    
    /**
     * @notice
     * Our intent behind delegations is to enable users – most especially the
     * `adminWallet`, `treasuryWallet`, and `guardianWallet` – to execute
     * functions via an external, (likely) scripted wallet that may loop
     * across multiple blocks. This allows all the security that comes with
     * `address`-specific authentication with the flexibility and loop-ability
     * of scriptable software wallets.
     */
    
    /**
     * @notice
     * Might be worthwhile for someone submitting a delegation to see the
     * encoded output to compare with what the `owner` actually set.
     * If the outputs don't match, don't bother sending the transaction.
     * Explain to the `owner` that the provided Delegation `input`
     * is invalid and doesn't match what they set.
     */
    function encodeDelegation(
        address owner,
        Delegation calldata input
    ) public pure returns (
        uint,
        bytes32
    ) {
        return (
            uint(
                keccak256(
                    abi.encode(
                        owner,
                        input
                    )
                )
            ),
            keccak256(
                abi.encodePacked(
                    input.functionName
                )
            )
        );
    }

    /*
        uint8 constant lenDelegates = 5;
        uint8 constant dFuncSetId = 0;
        uint8 constant dFuncTransferMultiple = 1;
        uint8 constant dFuncRain = 2;
        uint8 constant dFuncRainList = 3;
        uint8 constant dFuncRainAll = 4;
    */
    bytes32[lenDelegates] delegateFunctions = [
        keccak256(abi.encodePacked("setId()")),
        keccak256(abi.encodePacked("transferMultiple()")),
        keccak256(abi.encodePacked("rain()")),
        keccak256(abi.encodePacked("rainList()")),
        keccak256(abi.encodePacked("rainAll()"))
    ];

    /**
     * @dev Verification of the Delegation struct being valid is performed
     * before saving the struct's info to storage.
     * 
     * @param input.delegate -> submit `address(0)` to delete your delegation
     */
    function setMyDelegation(
        Delegation calldata input
    ) external {
        
        delete delegationMem[msg.sender];

        /**
         * @dev Return if the user only intends to delete their delegation.
         */
        if (input.delegate == address(0)) {
            return;
        }
        
        /*
        mapping(address => uint[4]) public delegationMem;

        uint8 constant lenDelegationMem = 4;
        uint8 constant encodedDelegation = 0;
        uint8 constant startIndex = 1;
        uint8 constant total = 2;
        uint8 constant excluded = 3;
        
        struct Delegation {
            address delegate;
            string functionName;
            address[] recipients;
            uint[] amounts;
        }
        */

        bytes32 _functionNameEncoded;
        (
            delegationMem[msg.sender][encodedDelegation],
            _functionNameEncoded
        ) = encodeDelegation(msg.sender, input);

        /**
         * @dev
         * An alternative way to verify the delegate function is valid
         * written below. Downside of this one is that it doesn't
         * verify that any of the other arguments inside the provided
         * Delegation are valid for the function chosen.
         *
        for (uint8 i; i < lenDelegates; ++i) {
            if (
                _functionNameEncoded
                ==
                delegateFunctions[i]
            ) { return; }
        }
        revert(error_invalidDelegation);
         *
         */

        // Copied requires from `setId()`
        if (
            _functionNameEncoded
            ==
            delegateFunctions[dFuncSetId]
        ) {
            require(
                _walletIsGuardianTreasuryOrAdmin(msg.sender),
                errors[errGuardianTreasuryAdminAuth]
            );

            require(
                input.recipients.length
                ==
                input.amounts.length,
                errors[errDelegateSetId]
            );
        }

        // Copied requires from `transferMultiple()`
        else if (
            _functionNameEncoded
            ==
            delegateFunctions[dFuncTransferMultiple]
        ) {
            require(
                input.recipients.length
                ==
                input.amounts.length,
                errors[errTransferMultiple]
            );
        }

        // Copied requires from `rainList()`
        else if (
            _functionNameEncoded
            ==
            delegateFunctions[dFuncRainList]
        ) {
            require(
                input.amounts.length == 1,
                errors[errRainAmounts]
            );

            _rainAndListChecks(
                msg.sender,
                input.amounts[rAmount],
                input.recipients.length,
                false
            );
        }

        // Copied requires from `rain()`
        else if (
            _functionNameEncoded
            ==
            delegateFunctions[dFuncRain]
        ) {

            require(
                input.amounts.length == 2,
                errors[errRainAmounts]
            );

            /**
             * @dev
             * In `rain()`:
             * `amounts[0]` --> `amount`         --> `rAmount`
             * `amounts[1]` --> `accountsToRain` --> `rAccountsToRain`
             */

            _rainAndListChecks(
                msg.sender,
                input.amounts[rAmount],
                input.amounts[rAccountsToRain],
                false
            );
        }
        else {

            // Prevent invalid delegations being set if none of the above hit.
            require(
                _functionNameEncoded
                ==
                delegateFunctions[dFuncRainAll],
                errors[errInvalidDelegation]
            );

            // Copied requires from `rainAll()`
            require(
                input.amounts.length == 1,
                errors[errRainAmounts]
            );
        }
    }
    
    /**
     * @notice Must have the exact parameters set by the `owner`.
     * 
     * @dev
     * Run the delegation entrusted to me.
     * `owner` can run their own delegation even if they chose
     * a different delegate at `input.delegate`.
     */
    function runMyDelegation(
        address owner,
        Delegation calldata input
    ) external {
        require(
            msg.sender != address(0),
            errors[errRunMyDelegation]
        );

        /**
         * @dev
         * Only you or the `delegate` you chose can execute your
         * stored Delegation.
         */
        require(
            msg.sender == input.delegate
            || msg.sender == owner,
            errors[errAuthMyDelegation]
        );

        (
            uint _encodedDelegation,
            bytes32 _functionNameEncoded
        ) = encodeDelegation(owner, input);
        
        /**
         * @dev After encoding the delegation, verify it matches what is stored.
         */
        require(
            _encodedDelegation == delegationMem[owner][encodedDelegation],
            errors[errDelegationDoesntMatch]
        );

        // `setId()` delegation
        if (
            _functionNameEncoded
            ==
            delegateFunctions[dFuncSetId]
        ) {
            /**
             * @dev
             * We ran into an issue where neither Remix nor Hardhat
             * would actually push the transaction through the loop
             * with sufficient gas for each account. To get around
             * this limitation of incorrect gas estimation, we simply
             * spoof another few `_accounts` into the gas `require()`
             * to ensure the Tx is pushed with sufficient gas.
             * 
             * @dev
             * Swapping `id`s costs ≈ 50k gas whereas we enforce ≈ 23k per loop.
             * Therefore setting this value to 2x `rain()` ≈ 46k per loop should
             * be sufficient to loop through all the `setId()`s provided.
             * 
             * @dev
             * Should the `gasPerLoop` value increase the worst that happens
             * is users push their Tx with additional gas and are refunded
             * on Tx completion. At least they ensure their gas was
             * spent on actually achieving the action(s) they desired.
             */
            uint _accounts = input.recipients.length;
            
            /**
             * @dev
             * Somewhat more expensive than `rain()` due to our requirement
             * to verify the delegation before running. We estimate that'll
             * cost the same as 2x `rain()` execution loop.
             */
            _verifyLoopGas(_accounts * 2);

            /**
             * @dev
             * Go through the entire list of `_accounts`, starting at
             * the remembered index in the `delegationMem` mapping.
             * By default this index starts at 0.
             */
            uint i = delegationMem[owner][startIndex];
            uint _start = i;
            for (; i < _accounts; ++i) {

                /**
                 * @dev
                 * Insufficient gas remaining?
                 * Remember the current index and return to save progress.
                 */
                if (
                    _hasInsufficientGasRemaining()
                    && i > _start
                    && i + 1 < _accounts
                ) {
                    delegationMem[owner][startIndex] = i;
                    return;
                }
                
                /**
                 * @dev Execute the `setId()` on the given account.
                 */
                _setId(input.recipients[i], input.amounts[i]);
            }
        }

        // `transferMultiple()` delegation
        else if (
            _functionNameEncoded
            ==
            delegateFunctions[dFuncTransferMultiple]
        ) {
            /**
             * @dev
             * Looping occurs inside the `_transferMultiple()`
             * private executable.
             */
            _transferMultiple(owner, true, input.recipients, input.amounts);

            if (delegationMem[owner][startIndex] < input.recipients.length) {
                return;
            }
        }

        // `rainList()` delegation
        else if (
            _functionNameEncoded
            ==
            delegateFunctions[dFuncRainList]
        ) {
            /**
             * @dev
             * Looping occurs inside the `_rainList()`
             * private executable.
             */
            _rainList(
                owner,
                true,
                input.amounts[rAmount],
                input.recipients
            );

            if (delegationMem[owner][startIndex] < input.recipients.length) {
                return;
            }
        }

        // `rain()` delegation
        else if (
            _functionNameEncoded
            ==
            delegateFunctions[dFuncRain]
        ) {

            /**
             * @dev
             * In `_rain()` private executable:
             * `amounts[0]` --> `amount`         --> `rAmount`
             * `amounts[1]` --> `accountsToRain` --> `rAccountsToRain`
             */

            _rain(
                owner,
                input.amounts[rAmount],
                input.amounts[rAccountsToRain]
            );
        }

        // `rainAll()` delegation
        else if (
            _functionNameEncoded
            ==
            delegateFunctions[dFuncRainAll]
        ) {
            /**
             * @dev
             * Looping occurs inside the `_rainAll()`
             * private executable.
             */
            _rainAll(
                owner,
                true,
                input.amounts[rAmount]
            );

            if (delegationMem[owner][startIndex] < numAccounts) {
                return;
            }
        }

        // Invalid or unknown delegation.
        else {
            revert(errors[errInvalidDelegation]);
        }

        /**
         * @dev
         * If delegation is successfully run,
         * delete the delegation to prevent
         * unintended expenditures.
         */
        delete delegationMem[owner];
    }




    // ------------------------------------------------------------------ //
    //  ----------------------  CLAIM LOST ERC-20  ---------------------  //

    /**
     * @notice
     * Our token contract has no way of knowing if it's received tokens.
     * Instead of implementing an ERC-223's `tokenFallback()` functionality
     * or ERC-777's `tokensReceived()` functionality, we opted for a custom
     * and much less complicated approach: Anyone can claim any outside tokens
     * sent to this token contract.
     * 
     * @notice
     * Should tokens be sent to `address(this)` then in `_transfer()`
     * we re-route them to the `treasuryWallet`, thereby ensuring the tokens
     * this contract creates won't ever exist at `address(this)` and thus
     * won't be claimable via the below function.
     */
    function claimERC20(address token) external {
        IERC20 _token = IERC20(token);
        uint tokenBalance = _token.balanceOf(address(this)); // costs 3000 gas
        emit Claimed(token, tokenBalance, msg.sender);

        if (tokenBalance > 0) {
            require(
                _token.transfer(msg.sender, tokenBalance),
                errors[errClaimERC20]
            );
        }
    }




}

// ------------------------------------------------------------------------------------ //



// = = = = = = = = = = = = = = = = = //
//                                   //
//    [email protected]   //
// [email protected] //
//     [email protected]     //
//                                   //
//           20 April 2023           //
// = = = = = = = = = = = = = = = = = //